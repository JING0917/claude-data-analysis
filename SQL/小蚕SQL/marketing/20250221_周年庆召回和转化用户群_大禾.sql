
-- 霸王餐最近完单距今天数
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

-- 霸王餐完单
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

-- 霸王餐完单用户群
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

-- 霸王餐召回用户
-- 295,209 人
drop view if exists bwc_zh_user;
create view IF NOT EXISTS bwc_zh_user (
    user_id
) as (
select
    distinct t3.user_id
from t3 left join t4 on t3.user_id=t4.user_id
left join dim.dim_silkworm_user b on t3.user_id=b.user_id and b.is_logoff=1
where wm_order_interval_day>=30 -- 低活跃 中位值
    and wm_order_num>=27 -- 中频次 中位值到70分位值
    and wm_profit>=19.86 -- 高价值 中位值
    and t4.user_id is null 
    and b.user_id is null
);

-- 霸王餐非召回用户
-- 2,622,354 人
drop view if exists un_bwc_zh_user;
create view IF NOT EXISTS un_bwc_zh_user (
    user_id
) as (
select
    distinct t3.user_id
from t3 left join t4 on t3.user_id=t4.user_id
left join bwc_zh_user a on t3.user_id=a.user_id
left join dim.dim_silkworm_user b on t3.user_id=b.user_id and b.is_logoff=1
where t4.user_id is null 
    and a.user_id is null
    and b.user_id is null
);

-- 探店最近一次完单距今天数
drop view if exists t5;
create view IF NOT EXISTS t5 (
    user_id,exp_order_interval_day
) as (
    select
        user_id
        ,date_diff('day',current_date(),str_to_jodatime(max_exp_finish_time,'yyyy-MM-dd HH:mm:ss')) as exp_order_interval_day
    from (
            select
                user_id
                ,max(if(promotion_type in (1,4) and status in (5,19,20,35),finish_time,null)) as max_exp_finish_time
            from dwd.dwd_sr_silkworm_explore_order
            where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
                and status in (5,19,11,14,17,18,22,23,28)
            group by 1
            ) a
);


-- 探店完单量和利润
-- 33,593 人
drop view if exists t6;
create view IF NOT EXISTS t6 (
    user_id,exp_order_num,exp_valid_order_num,exp_profit
) as (
select
    user_id
    ,count(if(promotion_type in (1,4),order_id,null)) as exp_order_num -- 探店订单量
    ,count(if(promotion_type in (1,4) and status in (5,19,20,35),order_id,null)) as exp_valid_order_num -- 探店有完成订单量
    ,sum(case when promotion_type =1 and status in (5,19) then pay_amt - real_rebate_amt - cost_price
           when promotion_type =1 and status in (11,14,17,18,22,23,28) then pay_amt - net_cost_price 
           when promotion_type =4 and status in (5,19) then cost_price - real_rebate_amt
        else 0 end) as exp_profit -- 探店完单利润
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


-- 探店完单用户群
drop view if exists t7;
create view IF NOT EXISTS t7 (
    user_id,
    exp_order_interval_day,
    exp_order_num,
    exp_valid_order_num,
    exp_profit
)
as ( 
select
    t5.user_id,
    exp_order_interval_day,
    exp_order_num,
    exp_valid_order_num,
    exp_profit
from t5 left join t6 on t5.user_id=t6.user_id
);


-- 探店召回用户
-- 6,564 人
drop view if exists exp_zh_user;
create view IF NOT EXISTS exp_zh_user (
    user_id
) as (
select
    distinct t7.user_id
from t7 left join t4 on t7.user_id=t4.user_id
left join dim.dim_silkworm_user b on t7.user_id=b.user_id and b.is_logoff=1
where exp_order_interval_day>=30 -- 低活跃 中位值
    and exp_valid_order_num>=1 -- 中频率 中位值到70分位值
    and exp_profit>=11 -- 高价值 -- 中位值
    and t4.user_id is null 
    and b.user_id is null
);


-- 探店非召回用户
-- 17,515 人
drop view if exists un_exp_zh_user;
create view IF NOT EXISTS un_exp_zh_user (
    user_id
) as (
select
    t7.user_id
from t7 left join t4 on t7.user_id=t4.user_id
left join exp_zh_user a on t7.user_id=a.user_id
left join dim.dim_silkworm_user b on t7.user_id=b.user_id and b.is_logoff=1
where t4.user_id is null 
    and a.user_id is null
    and b.user_id is null
);


-- 砍价访问和点击用户
drop view if exists t11;
create view IF NOT EXISTS t11 (user_id)
    as (
select
    user_id
from dws.dws_sr_traffic_user_d
where statistics_date between '2025-01-01' and date_sub(current_date(),interval 1 day)
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


-- 砍价转化用户
-- 26,310 人
drop view if exists kj_zh_user;
create view IF NOT EXISTS kj_zh_user (
    user_id
) as (
select
    distinct t11.user_id
from t11 left join t21 on t11.user_id=t21.user_id
left join t4 on t11.user_id=t4.user_id
left join dim.dim_silkworm_user b on t11.user_id=b.user_id and b.is_logoff=1
where t21.user_id is null
    and t4.user_id is null 
    and b.user_id is null
);


-- 砍价非转化用户
-- 1,555 人
drop view if exists un_kj_zh_user;
create view IF NOT EXISTS un_kj_zh_user (
    user_id
) as (
select
    distinct t11.user_id
from t11 left join t4 on t11.user_id=t4.user_id
left join kj_zh_user a on t11.user_id=a.user_id
left join dim.dim_silkworm_user b on t11.user_id=b.user_id and b.is_logoff=1
where t4.user_id is null 
    and a.user_id is null
    and b.user_id is null
);


-- 取数
-- 霸王餐召回&探店召回&砍价转化用户
select 
    distinct a.user_id
from bwc_zh_user a inner join exp_zh_user b on a.user_id=b.user_id
inner join kj_zh_user c on a.user_id=c.user_id
;

-- 霸王餐召回&探店召回&砍价非转化用户
select 
    distinct a.user_id
from bwc_zh_user a inner join exp_zh_user b on a.user_id=b.user_id
left join kj_zh_user c on a.user_id=c.user_id
where c.user_id is null
;

-- 霸王餐召回&探店非召回&砍价转化用户
select 
    distinct a.user_id
from bwc_zh_user a left join exp_zh_user b on a.user_id=b.user_id
inner join kj_zh_user c on a.user_id=c.user_id
where b.user_id is null
;


-- 霸王餐召回&探店非召回&砍价非转化用户
select 
    distinct a.user_id
from bwc_zh_user a left join exp_zh_user b on a.user_id=b.user_id
left join kj_zh_user c on a.user_id=c.user_id
where b.user_id is null and c.user_id is null
;

-- 霸王餐非召回&探店召回&砍价转化用户
select 
    distinct a.user_id
from exp_zh_user a
inner join kj_zh_user b on a.user_id=b.user_id
left join bwc_zh_user c on a.user_id=c.user_id
where c.user_id is null
;


-- 霸王餐非召回&探店召回&砍价非转化用户
select 
    distinct a.user_id
from exp_zh_user a
left join kj_zh_user b on a.user_id=b.user_id
left join bwc_zh_user c on a.user_id=c.user_id
where b.user_id is null and c.user_id is null
;

-- 霸王餐非召回&探店非召回&砍价转化用户
select 
    distinct a.user_id
from kj_zh_user a
left join exp_zh_user b on a.user_id=b.user_id
left join bwc_zh_user c on a.user_id=c.user_id
where b.user_id is null and c.user_id is null
;

