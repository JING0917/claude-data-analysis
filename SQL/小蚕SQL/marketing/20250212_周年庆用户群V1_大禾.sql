维度
用户ID、业务线

指标
近30天活跃天数，近60天活跃天数，近90天活跃天数、近30天下单天数、近60天下单天数、近90天下单天数、
-- 近3天下单量、近7天下单量、近14天下单量、近30天下单量、近60天下单量、近90天下单量、
近3天有效订单量、近7天有效订单量、近14天有效订单量、近30天有效订单量、近60天有效订单量、近90天有效订单量、
近3天有效订单利润、近7天有效订单利润、近14天有效订单利润、近30天有效订单利润、近60天有效订单利润、近90天有效订单利润


event_cname
探店：捡漏、探店
砍价：砍价

剔除'商家端'

探店 status in (5,11,14,17,18,19,22,23,28)算利润 in(4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33)核销单量 in(5,19,20,35)算完单

-- 12月新注册用户
-- 用户量：641,027
with t1 as (
select
	user_id
from dim.dim_silkworm_user
where substr(register_time,1,10) between '2024-12-01' and '2024-12-31'
),

-- 30天内访问
t2 as (
select
	user_id,
	count(if(yw_name='霸王餐',dt,null)) bwc_viewdays,
	count(if(yw_name='探店',dt,null)) exp_viewdays,
	count(if(yw_name='砍价',dt,null)) kj_viewdays
from (
-- 每日访问
select dt,
	case when event_cname regexp '捡漏|探店' then '探店'
		when event_cname regexp '砍价' then '砍价'
	else '霸王餐' end as yw_name,
	unnest_bitmap as user_id 
from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day) -- 最小从11月30日开始
	and event_cname not regexp '商家端'
group by 1,2,3
) a
group by 1
),


-- 30天内霸王餐订单
t3 as (
select
    user_id
    ,count(auto_id) as wm_order_num -- 订单量
    ,count(if(order_status in (2,8),auto_id,null)) as wm_valid_order_num -- 有效订单量
    ,sum(if(order_status in (2,8),profit,0)) as wm_profit -- 有效单利润
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
group by 1
),


-- 30天内探店订单
t4 as (
select
	user_id
	,count(if(promotion_type in (1,4),order_id,null)) as exp_order_num -- 探店订单量
	,count(if(promotion_type in (1,4) and status in (5,19,20,35),order_id,null)) as exp_valid_order_num -- 探店有完成订单量
	,sum(case when promotion_type =1 and status in (5,19) then pay_amt - real_rebate_amt - cost_price
           when promotion_type =1 and status in (11,14,17,18,22,23,28) then pay_amt - net_cost_price 
           when promotion_type =4 and status in (5,19) then cost_price - real_rebate_amt
        else 0 end) as exp_profit -- 探店完单利润
	,count(if(promotion_type=5,order_id,null)) as kj_order_num -- 砍价下单量
	,count(if(promotion_type=5 and status=5,order_id,null)) as kj_valid_order_num -- 砍价完单量
	,sum(if(promotion_type =5 and status=5,pay_amt-bargain_original_price,0)) as kj_profit -- 砍价完单利润
from
-- 订单
(select
	order_id
	,promotion_type
	,user_id
    ,store_promotion_id
    ,status
    ,pay_amt
    ,real_rebate_amt
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
) a
left join
-- 活动
(select promotion_id 
      ,cost_price -- 成本价(含笔记)
      ,net_cost_price  -- 成本价(不含笔记)
      ,bargain_original_price -- 砍价原价
      ,bargain_base_price   -- 砍价底价
from dwd.dwd_sr_silkworm_explore_promotion
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
) b on a.store_promotion_id=b.promotion_id
group by 1
),


-- 最近一笔完单距今天数
t5 as (
select
	user_id
	,date_diff('day',current_date(),str_to_jodatime(max_exp_finish_time,'yyyy-MM-dd HH:mm:ss')) as exp_order_interval_day
    ,date_diff('day',current_date(),str_to_jodatime(max_kj_finish_time,'yyyy-MM-dd HH:mm:ss')) as kj_order_interval_day
from (
	select
		user_id
	    ,max(if(promotion_type in (1,4) and status in (5,19,11,14,17,18,22,23,28),finish_time,null)) as max_exp_finish_time
	    ,max(if(promotion_type=5 and status=5,finish_time,null)) as max_kj_finish_time
	from dwd.dwd_sr_silkworm_explore_order
	where dt between '2024-06-01' and date_sub(current_date(),interval 1 day)
        and substr(finish_time,1,10)<>'1970-01-01'
	group by 1
	) a
),

-- 霸王餐有效单
t6 as (
select
    user_id
    ,date_diff('day',current_date(),str_to_jodatime(order_time,'yyyy-MM-dd HH:mm:ss')) as wm_order_interval_day
from (
	select
		user_id,max(order_time) as order_time
	from dwd.dwd_sr_order_promotion_order
where dt between '2024-12-01' and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between '2024-12-01' and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1
	) a
),


-- 结果
t7 as (
select
	t1.user_id
	,coalesce(bwc_viewdays,0) bwc_viewdays
	,coalesce(exp_viewdays,0) exp_viewdays
	,coalesce(kj_viewdays,0) kj_viewdays
	,coalesce(wm_order_num,0) wm_order_num -- 订单量
    ,coalesce(wm_valid_order_num,0) wm_valid_order_num -- 有效订单量
    ,coalesce(wm_profit,0) wm_profit -- 有效单利润
	,coalesce(exp_order_num,0) exp_order_num -- 探店订单量
	,coalesce(exp_valid_order_num,0) exp_valid_order_num -- 探店有完成订单量
	,coalesce(exp_profit,0) exp_profit -- 探店完单利润
	,coalesce(kj_order_num,0) kj_order_num -- 砍价下单量
	,coalesce(kj_valid_order_num,0) kj_valid_order_num -- 砍价完单量
	,coalesce(kj_profit,0) kj_profit -- 砍价完单利润
	,coalesce(wm_order_interval_day,20131) wm_order_interval_day
	,coalesce(exp_order_interval_day,20131) exp_order_interval_day
	,coalesce(kj_order_interval_day,20131) kj_order_interval_day     
from t1 left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
left join t5 on t1.user_id=t5.user_id
left join t6 on t1.user_id=t6.user_id
;












重要价值用户（最近购买、高频、高消费）
重要潜力用户（最近购买、高频、低消费）
重要深耕用户（最近购买、低频、高消费）
新用户（最近购买、低频、低消费）
重要价值流失预警用户（最近未购买、高频、高消费）
一般用户（最近未购买、高频、低消费）
高消费唤回用户（最近未购买、低频、高消费）
流失用户（最近未购买、低频、低消费）



if cluster == 0:
        return '重要价值用户' if (r_score <= np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 25) and 
                                  f_score >= np.percentile(rfm_data['近30天霸王餐有效订单量'], 75) and 
                                  m_score >= np.percentile(rfm_data['近30天霸王餐有效订单利润'], 75)) else '其他'
    elif cluster == 1:
        return '重要潜力用户' if (r_score <= np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 25) and 
                                  f_score >= np.percentile(rfm_data['近30天霸王餐有效订单量'], 75) and 
                                  m_score < np.percentile(rfm_data['近30天霸王餐有效订单利润'], 25)) else '其他'
    elif cluster == 2:
        return '重要深耕用户' if (r_score <= np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 25) and 
                                  f_score < np.percentile(rfm_data['近30天霸王餐有效订单量'], 25) and 
                                  m_score >= np.percentile(rfm_data['近30天霸王餐有效订单利润'], 75)) else '其他'
    elif cluster == 3:
        return '新用户' if (r_score <= np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 25) and 
                            f_score < np.percentile(rfm_data['近30天霸王餐有效订单量'], 25) and 
                            m_score < np.percentile(rfm_data['近30天霸王餐有效订单利润'], 25)) else '其他'
    elif cluster == 4:
        return '重要价值流失预警用户' if (r_score > np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 75) and 
                                        f_score >= np.percentile(rfm_data['近30天霸王餐有效订单量'], 75) and 
                                        m_score >= np.percentile(rfm_data['近30天霸王餐有效订单利润'], 75)) else '其他'
    elif cluster == 5:
        return '一般用户' if (r_score > np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 75) and 
                             f_score >= np.percentile(rfm_data['近30天霸王餐有效订单量'], 75) and 
                             m_score < np.percentile(rfm_data['近30天霸王餐有效订单利润'], 25)) else '其他'
    elif cluster == 6:
        return '高消费唤回用户' if (r_score > np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 75) and 
                                 f_score < np.percentile(rfm_data['近30天霸王餐有效订单量'], 25) and 
                                 m_score >= np.percentile(rfm_data['近30天霸王餐有效订单利润'], 75)) else '其他'
    elif cluster == 7:
        return '流失用户' if (r_score > np.percentile(rfm_data['最近一次霸王餐有效订单距今天数'], 75) and 
                              f_score < np.percentile(rfm_data['近30天霸王餐有效订单量'], 25) and 
                              m_score < np.percentile(rfm_data['近30天霸王餐有效订单利润'], 25)) else '其他'




我理解的是你拉取12月新注册这部分用户，注册时间较短比较容易召回做促活。我这边还有一个想法就是我想针对10月15-1月15用户访问和下单的分布情况去抓取一部分低活跃度有下单意向的潜在用户去做增单的提升。
就是分为两个人群：一个做促活，一个做潜在用户的下单留存提升

-- 访问
-- 4,337,351 人
drop view if exists t1;
create view IF NOT EXISTS t1 (
    user_id,tot_view_days
)
 as (
select
    user_id,
    count(1) as tot_view_days
from
(select
    statistics_date,
    user_id 
from dws.dws_sr_traffic_user_d 
where statistics_date between '2024-10-15' and '2025-01-15' 
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2
) a
group by 1
);

-- 下单
-- 2,866,795 人
drop view if exists t2;
create view IF NOT EXISTS t2 (
    user_id,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
)
as (
select
    user_id
    ,count(auto_id) as wm_order_num -- 订单量
    ,count(if(order_status in (2,8),auto_id,null)) as wm_valid_order_num -- 有效订单量
    ,sum(if(order_status in (2,8),profit,0)) as wm_profit -- 有效单利润
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 200 day) and date_sub(current_date(),interval 1 day)
    and substr(order_time,1,10) between '2024-10-15' and '2025-01-15'
group by 1
);

drop view if exists t3;
create view IF NOT EXISTS t3 (
    user_id,
    tot_view_days,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
)
as ( 
select
    t1.user_id,
    tot_view_days,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
from t1 left join t2 on t1.user_id=t2.user_id
);


-- select
--     PERCENTILE_CONT(tot_view_days,0.1) as 10_view_days,
--     PERCENTILE_CONT(tot_view_days,0.2) as 20_view_days,
--     PERCENTILE_CONT(tot_view_days,0.3) as 30_view_days,
--     PERCENTILE_CONT(tot_view_days,0.4) as 40_view_days,
--     PERCENTILE_CONT(tot_view_days,0.5) as 50_view_days,
--     PERCENTILE_CONT(tot_view_days,0.6) as 60_view_days,
--     PERCENTILE_CONT(tot_view_days,0.7) as 70_view_days,
--     PERCENTILE_CONT(tot_view_days,0.8) as 80_view_days,
--     PERCENTILE_CONT(tot_view_days,0.9) as 90_view_days,

--     PERCENTILE_CONT(wm_valid_order_num,0.1) as 10_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.2) as 20_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.3) as 30_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.4) as 40_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.5) as 50_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.6) as 60_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.7) as 70_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.8) as 80_valid_order_num,
--     PERCENTILE_CONT(wm_valid_order_num,0.9) as 90_valid_order_num,

--     PERCENTILE_CONT(wm_profit,0.1) as 10_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.2) as 20_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.3) as 30_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.4) as 40_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.5) as 50_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.6) as 60_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.7) as 70_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.8) as 80_wm_profit,
--     PERCENTILE_CONT(wm_profit,0.9) as 90_wm_profit
-- from t3
-- ;


-- 8,559 人
select
    -- count(user_id) cnt
    user_id
from t3
where tot_view_days<=5 -- 低活跃 中位值
    and wm_profit>=11.64 -- 高价值 中位值
;



大禾 明天帮我取几个霸王餐的数据
时间维度是近6个月

我想知道消费频率和最近一次消费时间间隔怎么样算高怎么样算低，你可以按聚类分析等方法看一下，或者看下消费频率的中位数或者最近一次消费时间间隔的中位数

-- 霸王餐下单时间间隔
-- 2,900,872 人
drop view if exists t1;
create view IF NOT EXISTS t1 (
    user_id,wm_order_interval_day
)
 as (
select
    user_id
    ,date_diff('day',current_date(),str_to_jodatime(order_time,'yyyy-MM-dd HH:mm:ss')) as wm_order_interval_day
from (
    select
        user_id,max(order_time) as order_time
    from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 210 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1
    ) a
);

-- 下单
-- 3,585,631 人
-- 有效下单 2,900,874 人
drop view if exists t2;
create view IF NOT EXISTS t2 (
    user_id,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
)
as (
select
    user_id
    ,count(auto_id) as wm_order_num -- 订单量
    ,count(if(order_status in (2,8),auto_id,null)) as wm_valid_order_num -- 有效订单量
    ,sum(if(order_status in (2,8),profit,0)) as wm_profit -- 有效单利润
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 210 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
group by 1
);


drop view if exists t3;
create view IF NOT EXISTS t3 (
    user_id,
    wm_order_interval_day,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
)
as ( 
select
    t1.user_id,
    wm_order_interval_day,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
from t1 left join t2 on t1.user_id=t2.user_id
);

-- 拉黑用户
drop view if exists t4;
create view IF NOT EXISTS t4 (
    user_id,
    register_time,
    latest_block_time,
    block_release_time
) as (
select user_id,
    register_time,
    latest_block_time,
    block_release_time
from dim.dim_silkworm_user 
where substr(latest_block_time,1,10)<>'1970-01-01'
    and (substr(block_release_time,1,10)='1970-01-01' 
        or str_to_date(block_release_time,'%Y-%m-%d')>date_sub(current_date(),interval 1 day)
        )
);



select
    PERCENTILE_CONT(wm_order_interval_day,0.1) as 10_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.2) as 20_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.3) as 30_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.4) as 40_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.5) as 50_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.6) as 60_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.7) as 70_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.8) as 80_wm_order_interval_day,
    PERCENTILE_CONT(wm_order_interval_day,0.9) as 90_wm_order_interval_day,

    PERCENTILE_CONT(wm_order_num,0.1) as 10_order_num,
    PERCENTILE_CONT(wm_order_num,0.2) as 20_order_num,
    PERCENTILE_CONT(wm_order_num,0.3) as 30_order_num,
    PERCENTILE_CONT(wm_order_num,0.4) as 40_order_num,
    PERCENTILE_CONT(wm_order_num,0.5) as 50_order_num,
    PERCENTILE_CONT(wm_order_num,0.6) as 60_order_num,
    PERCENTILE_CONT(wm_order_num,0.7) as 70_order_num,
    PERCENTILE_CONT(wm_order_num,0.8) as 80_order_num,
    PERCENTILE_CONT(wm_order_num,0.9) as 90_order_num,

    PERCENTILE_CONT(wm_valid_order_num,0.1) as 10_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.2) as 20_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.3) as 30_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.4) as 40_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.5) as 50_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.6) as 60_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.7) as 70_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.8) as 80_valid_order_num,
    PERCENTILE_CONT(wm_valid_order_num,0.9) as 90_valid_order_num,

    PERCENTILE_CONT(wm_profit,0.1) as 10_wm_profit,
    PERCENTILE_CONT(wm_profit,0.2) as 20_wm_profit,
    PERCENTILE_CONT(wm_profit,0.3) as 30_wm_profit,
    PERCENTILE_CONT(wm_profit,0.4) as 40_wm_profit,
    PERCENTILE_CONT(wm_profit,0.5) as 50_wm_profit,
    PERCENTILE_CONT(wm_profit,0.6) as 60_wm_profit,
    PERCENTILE_CONT(wm_profit,0.7) as 70_wm_profit,
    PERCENTILE_CONT(wm_profit,0.8) as 80_wm_profit,
    PERCENTILE_CONT(wm_profit,0.9) as 90_wm_profit
from t3
;



-- 295,209 人
select
    count(distinct if(t4.user_id is null and b.user_Id is null,t3.user_id,null)) cnt
    -- user_id
from t3 left join t4 on t3.user_id=t4.user_id
left join dim.dim_silkworm_user b on t3.user_id=b.user_id and b.is_logoff=1
where wm_order_interval_day>=30 -- 低活跃 中位值
    and wm_order_num>=27 -- 中频次 中位值到70分位值
    and wm_profit>=19.86 -- 高价值 中位值
;




======== 到店
-- 最近一笔完单距今天数
-- 需要限制订单状态，探店和砍价分开取数，现在把代码放一起了
-- 22,708 人
drop view if exists t5;
create view IF NOT EXISTS t5 (
    user_id,exp_order_interval_day --,kj_order_interval_day
) as (
    select
        user_id
        ,date_diff('day',current_date(),str_to_jodatime(max_exp_finish_time,'yyyy-MM-dd HH:mm:ss')) as exp_order_interval_day
        -- ,date_diff('day',current_date(),str_to_jodatime(max_kj_finish_time,'yyyy-MM-dd HH:mm:ss')) as kj_order_interval_day
    from (
            select
                user_id
                ,max(if(promotion_type in (1,4) and status in (5,19,20,35),finish_time,null)) as max_exp_finish_time
                -- ,max(if(promotion_type=5 and status=5,finish_time,null)) as max_kj_finish_time
            from dwd.dwd_sr_silkworm_explore_order
            where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
                and status in (5,19,11,14,17,18,22,23,28)
            group by 1
            ) a
);


-- 完单量和利润
-- 33,593 人
drop view if exists t6;
create view IF NOT EXISTS t6 (
    user_id,exp_order_num,exp_valid_order_num,exp_profit --,kj_order_num,kj_valid_order_num,kj_profit
) as (
select
    user_id
    ,count(if(promotion_type in (1,4),order_id,null)) as exp_order_num -- 探店订单量
    ,count(if(promotion_type in (1,4) and status in (5,19,20,35),order_id,null)) as exp_valid_order_num -- 探店有完成订单量
    ,sum(case when promotion_type =1 and status in (5,19) then pay_amt - real_rebate_amt - cost_price
           when promotion_type =1 and status in (11,14,17,18,22,23,28) then pay_amt - net_cost_price 
           when promotion_type =4 and status in (5,19) then cost_price - real_rebate_amt
        else 0 end) as exp_profit -- 探店完单利润
    -- ,count(if(promotion_type=5,order_id,null)) as kj_order_num -- 砍价下单量
    -- ,count(if(promotion_type=5 and status=5,order_id,null)) as kj_valid_order_num -- 砍价完单量
    -- ,sum(if(promotion_type =5 and status=5,pay_amt,0)) as kj_profit -- 砍价完单利润
from
    -- 订单
    (select
        order_id
        ,promotion_type
        ,user_id
        ,store_promotion_id
        ,status
        ,pay_amt
        ,real_rebate_amt
    from dwd.dwd_sr_silkworm_explore_order
    where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
            and status in (5,19,11,14,17,18,22,23,28)
    ) a
left join
        -- 活动
        (select promotion_id 
              ,cost_price -- 成本价(含笔记)
              ,net_cost_price  -- 成本价(不含笔记)
              ,bargain_original_price -- 砍价原价
              ,bargain_base_price   -- 砍价底价
        from dwd.dwd_sr_silkworm_explore_promotion
        where dt between '2024-06-01' and date_sub(current_date(),interval 1 day)
        ) b on a.store_promotion_id=b.promotion_id
    group by 1
);



drop view if exists t7;
create view IF NOT EXISTS t7 (
    user_id,
    exp_order_interval_day,
    exp_order_num,
    exp_valid_order_num,
    exp_profit
    -- kj_order_interval_day,
    -- kj_order_num,
    -- kj_valid_order_num,
    -- kj_profit
)
as ( 
select
    t5.user_id,
    exp_order_interval_day,
    exp_order_num,
    exp_valid_order_num,
    exp_profit
    -- kj_order_interval_day,
    -- kj_order_num,
    -- kj_valid_order_num,
    -- kj_profit
from t5 left join t6 on t5.user_id=t6.user_id
);


select
    PERCENTILE_CONT(exp_order_interval_day,0.1) as 10_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.2) as 20_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.3) as 30_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.4) as 40_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.5) as 50_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.6) as 60_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.7) as 70_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.8) as 80_exp_order_interval_day,
    PERCENTILE_CONT(exp_order_interval_day,0.9) as 90_exp_order_interval_day,

    PERCENTILE_CONT(exp_order_num,0.1) as 10_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.2) as 20_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.3) as 30_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.4) as 40_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.5) as 50_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.6) as 60_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.7) as 70_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.8) as 80_exp_order_num,
    PERCENTILE_CONT(exp_order_num,0.9) as 90_exp_order_num,

    PERCENTILE_CONT(exp_valid_order_num,0.1) as 10_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.2) as 20_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.3) as 30_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.4) as 40_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.5) as 50_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.6) as 60_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.7) as 70_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.8) as 80_exp_valid_order_num,
    PERCENTILE_CONT(exp_valid_order_num,0.9) as 90_exp_valid_order_num,

    PERCENTILE_CONT(exp_profit,0.1) as 10_exp_profit,
    PERCENTILE_CONT(exp_profit,0.2) as 20_exp_profit,
    PERCENTILE_CONT(exp_profit,0.3) as 30_exp_profit,
    PERCENTILE_CONT(exp_profit,0.4) as 40_exp_profit,
    PERCENTILE_CONT(exp_profit,0.5) as 50_exp_profit,
    PERCENTILE_CONT(exp_profit,0.6) as 60_exp_profit,
    PERCENTILE_CONT(exp_profit,0.7) as 70_exp_profit,
    PERCENTILE_CONT(exp_profit,0.8) as 80_exp_profit,
    PERCENTILE_CONT(exp_profit,0.9) as 90_exp_profit,

    PERCENTILE_CONT(kj_order_interval_day,0.1) as 10_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.2) as 20_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.3) as 30_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.4) as 40_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.5) as 50_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.6) as 60_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.7) as 70_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.8) as 80_kj_order_interval_day,
    PERCENTILE_CONT(kj_order_interval_day,0.9) as 90_kj_order_interval_day,

    PERCENTILE_CONT(kj_order_num,0.1) as 10_kj_order_num,
    -- PERCENTILE_CONT(kj_order_num,0.2) as 20_kj_order_num,
    -- PERCENTILE_CONT(kj_order_num,0.3) as 30_kj_order_num,
    -- PERCENTILE_CONT(kj_order_num,0.4) as 40_kj_order_num,
    PERCENTILE_CONT(kj_order_num,0.5) as 50_kj_order_num,
    -- PERCENTILE_CONT(kj_order_num,0.6) as 60_kj_order_num,
    PERCENTILE_CONT(kj_order_num,0.7) as 70_kj_order_num,
    -- PERCENTILE_CONT(kj_order_num,0.8) as 80_kj_order_num,
    PERCENTILE_CONT(kj_order_num,0.9) as 90_kj_order_num,
    PERCENTILE_CONT(kj_order_num,0.92) as 92_kj_order_num,
    PERCENTILE_CONT(kj_order_num,0.95) as 95_kj_order_num,
    PERCENTILE_CONT(kj_order_num,0.98) as 98_kj_order_num,

    PERCENTILE_CONT(kj_valid_order_num,0.1) as 10_kj_valid_order_num,
    -- PERCENTILE_CONT(kj_valid_order_num,0.2) as 20_kj_valid_order_num,
    -- PERCENTILE_CONT(kj_valid_order_num,0.3) as 30_kj_valid_order_num,
    -- PERCENTILE_CONT(kj_valid_order_num,0.4) as 40_kj_valid_order_num,
    PERCENTILE_CONT(kj_valid_order_num,0.5) as 50_kj_valid_order_num,
    -- PERCENTILE_CONT(kj_valid_order_num,0.6) as 60_kj_valid_order_num,
    PERCENTILE_CONT(kj_valid_order_num,0.7) as 70_kj_valid_order_num,
    -- PERCENTILE_CONT(kj_valid_order_num,0.8) as 80_kj_valid_order_num,
    PERCENTILE_CONT(kj_valid_order_num,0.9) as 90_kj_valid_order_num,
    PERCENTILE_CONT(kj_valid_order_num,0.92) as 92_kj_valid_order_num,
    PERCENTILE_CONT(kj_valid_order_num,0.95) as 95_kj_valid_order_num,
    PERCENTILE_CONT(kj_valid_order_num,0.98) as 98_kj_valid_order_num,

    PERCENTILE_CONT(kj_profit,0.1) as 10_kj_profit,
    -- PERCENTILE_CONT(kj_profit,0.2) as 20_kj_profit,
    -- PERCENTILE_CONT(kj_profit,0.3) as 30_kj_profit,
    -- PERCENTILE_CONT(kj_profit,0.4) as 40_kj_profit,
    PERCENTILE_CONT(kj_profit,0.5) as 50_kj_profit,
    -- PERCENTILE_CONT(kj_profit,0.6) as 60_kj_profit,
    PERCENTILE_CONT(kj_profit,0.7) as 70_kj_profit,
    -- PERCENTILE_CONT(kj_profit,0.8) as 80_kj_profit,
    PERCENTILE_CONT(kj_profit,0.9) as 90_kj_profit,
    PERCENTILE_CONT(kj_profit,0.92) as 92_kj_profit,
    PERCENTILE_CONT(kj_profit,0.95) as 95_kj_profit,
    PERCENTILE_CONT(kj_profit,0.98) as 98_kj_profit
from t7
where exp_order_num<>0 -- kj_order_num<>0
;


-- 探店
-- 6,568 人
select
    count(distinct if(t4.user_id is null and b.user_Id is null,t7.user_id,null)) cnt
    -- user_id
from t7 left join t4 on t7.user_id=t4.user_id
left join dim.dim_silkworm_user b on t7.user_id=b.user_id and b.is_logoff=1
where exp_order_interval_day>=30 -- 低活跃 中位值
    and exp_valid_order_num>=1 -- 中频率 中位值到70分位值
    and exp_profit>=11 -- 高价值 -- 中位值
;


-- 砍价
-- 下单 1,014人
-- 323 人
select
    count(user_id) as unum
from t3
where kj_order_interval_day>=33 -- 低活跃 70位值
    and kj_valid_order_num=1 -- 中频率 中位值到7分位值
    -- and kj_profit>=3.1 -- 利润是0或负数，不做限制
;




== 抽查验证探店订单利润是0的订单
select
    a.user_id
    ,concat('单',order_id) as order_id
    ,promotion_type
    ,store_promotion_id
    ,status
    ,pay_amt
    ,real_rebate_amt
    ,cost_price
    ,net_cost_price
    ,case when promotion_type =1 and status in (5,19) then pay_amt - real_rebate_amt - cost_price
           when promotion_type =1 and status in (11,14,17,18,22,23,28) then pay_amt - net_cost_price 
           when promotion_type =4 and status in (5,19) then cost_price - real_rebate_amt
        else 0 end as exp_profit -- 探店完单利润
from
(select user_id from t2 where exp_order_num<>0 and exp_profit=0) a
left join 
    -- 订单
    (select
        order_id
        ,promotion_type
        ,user_id
        ,store_promotion_id
        ,status
        ,pay_amt
        ,real_rebate_amt
    from dwd.dwd_sr_silkworm_explore_order
    where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
            and dt not between '2025-01-16' and '2025-02-09'
            and promotion_type in (1,4)
    ) b
on a.user_id=b.user_id
left join
        -- 活动
        (select promotion_id 
              ,cost_price -- 成本价(含笔记)
              ,net_cost_price  -- 成本价(不含笔记)
              ,bargain_original_price -- 砍价原价
              ,bargain_base_price   -- 砍价底价
        from dwd.dwd_sr_silkworm_explore_promotion
        where dt between '2024-06-01' and date_sub(current_date(),interval 1 day)
        ) c on b.store_promotion_id=c.promotion_id
;




========== 砍价用户

4401    广州市
3101    上海市
4403    深圳市
3201    南京市
5001    重庆市
3301    杭州市
3401    合肥市
3205    苏州市
4301    长沙市
4201    武汉市
5101    成都市

'4401', '3101', '4403', '3201', '5001', '3301', '3401', '3205', '4301', '4201', '5101'

-- 开通城市
select
    city_id,
    city_name
from dim.dim_silkworm_explore_city
where province_name<>'新疆维吾尔族自治区' -- 剔除测试省份
    and status=1 -- 正常
    and promotion_type in ('101','111') -- 已开通
;


-- 新埋点日志 
-- 25年1月开始有数据，所以用旧的
select
    dt `统计日期`,
    '杭州' as `城市`,
    sum(if(event_name='StoreDiscovery_Homepage_View',1,0)) `探店主页PV`,
    count(distinct if(event_name='StoreDiscovery_Homepage_View',user_id,null)) `探店主页UV`,
    sum(if(event_name='Bargain_Homepage_Ex',1,0)) `砍价主页PV`,
    count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) `砍价主页UV`,
    sum(if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',1,0)) `砍价活动详情页PV`,
    count(distinct if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',user_id,null)) `砍价活动详情页UV`,  
    sum(if(event_name='Store_Details_View',1,0)) `店铺详情页PV`,
    count(distinct if(event_name='Store_Details_View',user_id,null)) `店铺详情页UV`,
    sum(if(event_name='Bargain_Share_Button_Click',1,0)) `砍价分享按钮点击量`,
    count(distinct if(event_name='Bargain_Share_Button_Click',user_id,null)) `砍价分享按钮点击UV`,
    sum(if(event_name='Bargain_Activity_Details_Share_Ex',1,0)) `砍价活动详情页分享弹窗曝光量`,
    count(distinct if(event_name='Bargain_Activity_Details_Share_Ex',user_id,null)) `砍价活动详情页分享弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Ex',1,0)) `邀请砍价弹窗曝光量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Ex',user_id,null)) `邀请砍价弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Click',1,0)) `邀请砍价弹窗点击量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Click',user_id,null)) `邀请砍价弹窗点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.activity_type') as activity_type
ods.ods_sr_event_log
where dt=date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4) in（'4401', '3101', '4403', '3201', '5001', '3301', '3401', '3205', '4301', '4201', '5101')
    and event_name in ('Bargain_Button_Click',
        'StoreDiscovery_Activity_Details_Ex')
    ) a
group by 1,2;



-- 正式跑数
-- 开通砍价城市用户点击砍价按钮或浏览砍价详情页
drop view if exists t11;
create view IF NOT EXISTS t11 (user_id)
    as (
select
    user_id
from dws.dws_sr_traffic_user_d
where statistics_date between '2025-01-01' and '2025-02-19'
    and (bargain_detailpage_expose_num>0 or bargain_button_click_num>0)
    and substr(county_id,1,4) in ('4401', '3101', '4403', '3201', '5001', '3301', '3401', '3205', '4301', '4201', '5101')
    and user_id regexp '^[0-9]{1,9}$'
group by 1
);


-- 砍价完单用户
drop view if exists t21;
create view IF NOT EXISTS t21 (user_id)
    as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and promotion_type=5
    and status=5
group by 1
);



select
    count(distinct t11.user_id) as `访问砍价用户量`, -- 28164
    count(distinct if(t21.user_id is null,t11.user_id,null)) as `访问砍价未完单用户量`, -- 26609
    count(distinct t21.user_id) as `砍价完单用户量` --1555
from t11 left join t21 on t11.user_id=t21.user_id
;


====== 剔除霸王餐和砍价后，探店召回用户

-- 剔除霸王餐和砍价的探店待召回用户
-- 4,569人
select
    count(distinct if(b.user_id is null 
    and c.user_id is null 
    and t4.user_id is null
    and d.user_id is null
    ,a.user_id,null)) as net_unum
from
-- 探店待召回用户ID
(select
    user_id
from t7 
where exp_order_interval_day>=30 -- 低活跃 中位值
    and exp_valid_order_num>=1 -- 中频率 中位值到70分位值
    and exp_profit>=11 -- 高价值 -- 中位值
) a
left join
-- 霸王餐待召回用户
(select
    user_id
from t3
where wm_order_interval_day>=30 -- 低活跃 中位值
    and wm_order_num>=27 -- 中频次 中位值到70分位值
    and wm_profit>=19.86 -- 高价值 中位值
) b on a.user_id=b.user_id
left join 
-- 砍价待转化用户
(select
    distinct t11.user_id
from t11 left join t21 on t11.user_id=t21.user_id
where t21.user_id is null
) c on a.user_id=c.user_id
left join t4 on a.user_id=t4.user_id
left join dim.dim_silkworm_user d on a.user_id=d.user_id and d.is_logoff=1
;

============== 分不同类型取用户群


============== 订单金额分位值
-- 近6个月数据
-- 探店订单金额
with t1 as (
select user_id 
      ,sum(pay_amt) order_amt
      ,count(1) order_num
      ,sum(pay_amt)/count(1) as avg_price
from dwd.dwd_sr_silkworm_explore_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4)  -- 探店
    and status in (5,11,14,17,18,19,22,23,28)
group by 1
    ),


-- 砍价订单金额
t2 as (
select user_id 
      ,sum(pay_amt+red_pack_reward_num/100) as order_amt
      ,count(1) as order_num
      ,sum(pay_amt+red_pack_reward_num/100)/count(1) as avg_price
from dwd.dwd_sr_silkworm_explore_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (5,6)
    and status=5
group by 1
    )


select
    '探店订单金额' as `类型`,
    min(avg_price) as `最小值`,
    PERCENTILE_CONT(avg_price,0.1) as `10分位值`,
    PERCENTILE_CONT(avg_price,0.2) as `20分位值`,
    PERCENTILE_CONT(avg_price,0.3) as `30分位值`,
    PERCENTILE_CONT(avg_price,0.4) as `40分位值`,
    PERCENTILE_CONT(avg_price,0.5) as `50分位值`,
    PERCENTILE_CONT(avg_price,0.6) as `60分位值`,
    PERCENTILE_CONT(avg_price,0.7) as `70分位值`,
    PERCENTILE_CONT(avg_price,0.8) as `80分位值`,
    PERCENTILE_CONT(avg_price,0.9) as `90分位值`,
    max(avg_price) as `最大值`,
    count(distinct user_id) as `完单用户量`
from t1
group by 1

union all
select
    '砍价订单金额' as `类型`,
    min(avg_price) as `最小值`,
    PERCENTILE_CONT(avg_price,0.1) as `10分位值`,
    PERCENTILE_CONT(avg_price,0.2) as `20分位值`,
    PERCENTILE_CONT(avg_price,0.3) as `30分位值`,
    PERCENTILE_CONT(avg_price,0.4) as `40分位值`,
    PERCENTILE_CONT(avg_price,0.5) as `50分位值`,
    PERCENTILE_CONT(avg_price,0.6) as `60分位值`,
    PERCENTILE_CONT(avg_price,0.7) as `70分位值`,
    PERCENTILE_CONT(avg_price,0.8) as `80分位值`,
    PERCENTILE_CONT(avg_price,0.9) as `90分位值`,
    max(avg_price) as `最大值`,
    count(distinct user_id) as `完单用户量`
from t2
group by 1
;







