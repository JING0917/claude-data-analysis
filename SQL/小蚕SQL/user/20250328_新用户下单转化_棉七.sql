-- 24年11月注册用户
drop view if exists newuser_info;
create view IF NOT EXISTS newuser_info (
    register_date,user_id
) as (
select
    date_format(register_time,'%Y-%m-%d') register_date,
    user_id
from dim.dim_silkworm_user
where date_format(register_time,'%Y-%m-%d') between '2024-11-01' and '2024-11-30'
);

-- 成本：挑战赛支出、红包使用、抽奖蚕豆、抽奖权益（京东E卡、大牌券、打车券）、VIP额外返利、复活券
-- 收益：已审核订单利润

-- 挑战赛支出
drop view IF EXISTS challenge_reward;
create view IF NOT EXISTS challenge_reward as (
    SELECT
        dt,
        -- challenge_id,
        user_id,
        sum(reward_value)/100 as reward_value
    from(
        SELECT
            challenge_id,
            takepart_id,
            stage,
            get_json_int(value,'$.SilkId') as user_id,
            dt,
            ifnull(ROUND(reward_value/sum(get_json_int(value,'$.TaskNum')) over(PARTITION BY takepart_id,stage) * get_json_int(value,'$.TaskNum')),0) as reward_value
        FROM(
            SELECT 
                challenge_id,
                takepart_id,
                group_user_id_list,
                get_json_int(value,'$.ExpectNum'),
                CASE
                    WHEN get_json_int(value,'$.ExpectNum') > current_progress THEN 0
                    WHEN get_json_int(value,'$.RewardType') = 1 THEN get_json_int(value,'$.RewardNum')
                    WHEN get_json_int(value,'$.RewardType') = 2 and get_json_int(value,'$.CardType') = 3 THEN 1000
                    WHEN get_json_int(value,'$.RewardType') = 3 THEN get_json_int(value,'$.RewardNum')
                    WHEN get_json_int(value,'$.RewardType') = 4 THEN 0
                END AS reward_value,
                IF(get_json_int(value,'$.Stage') > 0,get_json_int(value,'$.Stage'),`key`) as stage,
                from_unixtime(get_json_object(stage_finished_reward,concat('$[',IF(get_json_int(value,'$.Stage') > 0,get_json_int(value,'$.Stage'),`key`),']')), 'yyyy-MM-dd') AS dt
            FROM 
                dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(stage_task)) AS t1111
        ) as t111,json_each(parse_json(group_user_id_list)) AS t222
        WHERE
            date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-12-30'
    ) as tt_1
    group BY
        1,2
);


-- 红包使用
drop view if exists rpd_info;
create view IF NOT EXISTS rpd_info (
    order_dt,user_id,redpacket_amt
) as (
select 
    order_dt,
    a.user_id,
    sum(redpacket_amt) as redpacket_amt
from (
    select dt
            ,user_id
            ,order_id
    from dwd.dwd_sr_market_redpack_use_record
    where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-12-30'
        and order_id<>'' -- 20241108 剔除无订单ID数据 修改人：dahe
        and redpacket_use_status=2 -- 已使用
    ) a
inner join 
    -- 订单
    (
        select profit 
                ,user_id
                ,order_id
                ,redpacket_amt
                ,date_format(order_time,'%Y-%m-%d') as order_dt
        from dwd.dwd_sr_order_promotion_order
        where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-12-30'
        and order_status=2
    ) b on a.order_id=b.order_id
group by 1,2
);


-- 抽奖蚕豆
drop view if exists candou_info;
create view IF NOT EXISTS candou_info (
    candou_date,user_id,candou_amt
) as (
select 
    date_format(dt,'%Y-%m-%d') as candou_date,
    user_id,
    sum(gift_num/100) as candou_amt
from dwd.dwd_sr_market_rpd_lottery_winning_record
where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-11-30'
   and gift_name regexp '蚕豆'
group by 1,2
);



-- 卡券支出
drop view if exists coupon_info;
create view IF NOT EXISTS coupon_info (
    card_type,key_id,card_id,used_date,user_id
) as (
-- 已使用的卡券
select distinct card_type  
               ,key_id     -- 订单id 
               ,card_id    -- 券id 
               ,date_format(used_time,'%Y-%m-%d') used_date  -- 使用时间
               ,user_id
from dwd.dwd_sr_market_rights_card 
where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2025-01-31'
    and card_status = 1      -- 0:未使用 1:已使用 2:已失效 
    and card_type in (3,7,8) -- 3:大牌专享券 7:订单复活券 8:vip额外返利券
);


-- 订单信息
drop view if exists order_info;
create view IF NOT EXISTS order_info (
    auto_id,order_date,is_vip_exclusive_order,profit,service_charge,redpacket_amt,real_rebate_amt,origin_rebate_amt,order_status,user_id
) as (
select 
       auto_id 
      ,date_format(order_time,'%Y-%m-%d') as order_date 
      ,is_vip_exclusive_order                        -- 1:大牌订单 
      ,profit                              -- 利润
      ,service_charge                      -- 服务费
      ,redpacket_amt                       -- 红包金额
      ,real_rebate_amt                     -- 实际返现金额
      ,origin_rebate_amt                   -- 原始返现金额
      ,order_status
      ,user_id
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-12-30'
    and order_status in (2,12)
);

-- vip额外返利金额
drop view if exists vip_cost;
create view IF NOT EXISTS vip_cost (
    order_id_substr,user_id,extra_rebate
) as (
select right(order_id,9) as order_id_substr
    ,user_id
    ,extra_rebate
from dwd.dwd_sr_user_member_task_rebate_log
where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-11-30'
);


-- 卡券支出
drop view if exists coupon_cost;
create view IF NOT EXISTS coupon_cost (
    order_date,user_id,brand_cost,revival_cost,vip_cost
) as (
select order_date
      ,t1.user_id
      ,coalesce(sum(case when is_vip_exclusive_order = 1 then real_rebate_amt end),0) as brand_cost
      ,coalesce(sum(case when order_status = 12 then real_rebate_amt end),0) as revival_cost 
      ,coalesce(sum(case when t3.order_id_substr is not null then extra_rebate end),0) as vip_cost
from coupon_info t1 join order_info t2 on t1.key_id = t2.auto_id and t1.user_id=t2.user_id
left join vip_cost t3 on t1.key_id = t3.order_id_substr and t1.user_id=t3.user_id
group by 1,2
);


-- 霸王餐已审核订单利润
drop view if exists order_profit;
create view IF NOT EXISTS order_profit (
    order_date,user_id,valid_order_num,profit
) as (
select
      date_format(order_time,'%Y-%m-%d') as order_date 
      ,user_id
      ,count(1) as valid_order_num
      ,sum(if(order_status=2,profit,0)) as profit
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between '2024-11-01' and '2024-12-30'
    and order_status in (2,8)
group by 1,2
);


-- 统计 分别和表bcdef关联统计
select
    a.register_date `注册日期`
    ,count(distinct a.user_id) as `注册用户量`
    ,count(distinct if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 1,a.user_id,null)) `注册1天内下单用户量`
    ,count(distinct if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 3,a.user_id,null)) `注册3天内下单用户量`
    ,count(distinct if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 7,a.user_id,null)) `注册7天内下单用户量`
    ,count(distinct if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 14,a.user_id,null)) `注册14天内下单用户量`
    ,count(distinct if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 30,a.user_id,null)) `注册30天内下单用户量`

    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 1,b.valid_order_num,0)) `注册1天内有效订单量`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 3,b.valid_order_num,0)) `注册3天内有效订单量`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 7,b.valid_order_num,0)) `注册7天内有效订单量`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 14,b.valid_order_num,0)) `注册14天内有效订单量`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 30,b.valid_order_num,0)) `注册30天内有效订单量`

    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 1,b.profit,0)) `注册1天内有效订单利润`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 3,b.profit,0)) `注册3天内有效订单利润`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 7,b.profit,0)) `注册7天内有效订单利润`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 14,b.profit,0)) `注册14天内有效订单利润`
    ,sum(if(b.user_id is not null and date_diff('day',b.order_date,a.register_date) between 0 and 30,b.profit,0)) `注册30天内有效订单利润`

    ,sum(if(c.user_id is not null and date_diff('day',c.dt,a.register_date) between 0 and 1,c.reward_value,0)) `注册1天内挑战赛支出金额`
    ,sum(if(c.user_id is not null and date_diff('day',c.dt,a.register_date) between 0 and 3,c.reward_value,0)) `注册3天内挑战赛支出金额`
    ,sum(if(c.user_id is not null and date_diff('day',c.dt,a.register_date) between 0 and 7,c.reward_value,0)) `注册7天内挑战赛支出金额`
    ,sum(if(c.user_id is not null and date_diff('day',c.dt,a.register_date) between 0 and 14,c.reward_value,0)) `注册14天内挑战赛支出金额`
    ,sum(if(c.user_id is not null and date_diff('day',c.dt,a.register_date) between 0 and 30,c.reward_value,0)) `注册30天内挑战赛支出金额`

    ,sum(if(d.user_id is not null and date_diff('day',d.order_dt,a.register_date) between 0 and 1,d.redpacket_amt,0)) `注册1天内使用红包金额`
    ,sum(if(d.user_id is not null and date_diff('day',d.order_dt,a.register_date) between 0 and 3,d.redpacket_amt,0)) `注册3天内使用红包金额`
    ,sum(if(d.user_id is not null and date_diff('day',d.order_dt,a.register_date) between 0 and 7,d.redpacket_amt,0)) `注册7天内使用红包金额`
    ,sum(if(d.user_id is not null and date_diff('day',d.order_dt,a.register_date) between 0 and 14,d.redpacket_amt,0)) `注册14天内使用红包金额`
    ,sum(if(d.user_id is not null and date_diff('day',d.order_dt,a.register_date) between 0 and 30,d.redpacket_amt,0)) `注册30天内使用红包金额`

    ,sum(if(e.user_id is not null and date_diff('day',e.candou_date,a.register_date) between 0 and 1,e.candou_amt,0)) `注册1天内抽奖蚕豆金额`
    ,sum(if(e.user_id is not null and date_diff('day',e.candou_date,a.register_date) between 0 and 3,e.candou_amt,0)) `注册3天内抽奖蚕豆金额`
    ,sum(if(e.user_id is not null and date_diff('day',e.candou_date,a.register_date) between 0 and 7,e.candou_amt,0)) `注册7天内抽奖蚕豆金额`
    ,sum(if(e.user_id is not null and date_diff('day',e.candou_date,a.register_date) between 0 and 14,e.candou_amt,0)) `注册14天内抽奖蚕豆金额`
    ,sum(if(e.user_id is not null and date_diff('day',e.candou_date,a.register_date) between 0 and 30,e.candou_amt,0)) `注册30天内抽奖蚕豆金额`

    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 1,f.brand_cost,0)) `注册1天内大牌券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 3,f.brand_cost,0)) `注册3天内大牌券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 7,f.brand_cost,0)) `注册7天内大牌券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 14,f.brand_cost,0)) `注册14天内大牌券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 30,f.brand_cost,0)) `注册30天内大牌券支出金额`

    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 1,f.revival_cost,0)) `注册1天内复活券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 3,f.revival_cost,0)) `注册3天内复活券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 7,f.revival_cost,0)) `注册7天内复活券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 14,f.revival_cost,0)) `注册14天内复活券支出金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 30,f.revival_cost,0)) `注册30天内复活券支出金额`

    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 1,f.vip_cost,0)) `注册1天内vip额外返利金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 3,f.vip_cost,0)) `注册3天内vip额外返利金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 7,f.vip_cost,0)) `注册7天内vip额外返利金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 14,f.vip_cost,0)) `注册14天内vip额外返利金额`
    ,sum(if(f.user_id is not null and date_diff('day',f.order_date,a.register_date) between 0 and 30,f.vip_cost,0)) `注册30天内vip额外返利金额`
from newuser_info a 
left join order_profit b on a.user_id=b.user_id
left join challenge_reward c on a.user_id=c.user_id 
left join rpd_info d on a.user_id=d.user_id
left join candou_info e on a.user_id=e.user_id
left join coupon_cost f on a.user_id=f.user_id
group by 1;








-- part4 新用户复购
-- 统计新人注册30日内完单量
with t1 as (
select
    register_time,
    user_id
from dim.dim_silkworm_user
-- where substr(register_time,1,10) between '2024-01-01' and '2024-12-31'
),

-- 每日完单量
t2 as (
select 
    order_time,
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order 
where cast(dt as string) between '2024-01-01' and '2025-01-13'
    and order_status in (2,8)
group by 1,2
)


select
    month(register_time) as mon,
    sum(if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))<=30,1,0)) as order_num
from t1 left join t2 on t1.user_id=t2.user_id
group by 1;




-- 统计首单后完单量
with t1 as (
select
    register_time,
    first_valid_order_time,
    user_id
from dim.dim_silkworm_user
where substr(register_time,1,10) between '2024-01-01' and '2024-12-31'
    and substr(first_valid_order_time,1,10) between '2024-01-01' and '2024-12-31'
),

-- 每日完单量
t2 as (
select 
    order_time,
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order 
where cast(dt as string) between '2024-01-01' and '2025-01-09'
    and order_status in (2,8)
group by 1,2
)


select
    month(register_time) as mon,
    count(if(substr(t1.first_valid_order_time,1,7)=substr(t1.register_time,1,7),t1.user_id,null)) as `注册当月首单量`,
    sum(if(datediff(cast(t2.order_time as datetime),cast(t1.first_valid_order_time as datetime))<=30,1,0)) as `首单后30日内完单量`,
    sum(if(datediff(cast(t2.order_time as datetime),cast(t1.first_valid_order_time as datetime)) between 31 and 60,1,0)) as `首单后31到60日内完单量`,
    sum(if(datediff(cast(t2.order_time as datetime),cast(t1.first_valid_order_time as datetime)) between 61 and 90,1,0)) as `首单后61到90日内完单量`,
    sum(if(datediff(cast(t2.order_time as datetime),cast(t1.first_valid_order_time as datetime))>=91,1,0)) as `首单后91+日内完单量`
from t1 left join t2 on t1.user_id=t2.user_id
group by 1;



-- 注册用户下单留存
with t1 as (
select
    register_time,
    user_id
from dim.dim_silkworm_user
where date_format(register_time,'%Y-%m-%d') between '2024-11-01' and '2024-11-30'
),

-- 每日完单量
t2 as (
select 
    order_time,
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order 
where cast(dt as string) between '2024-11-01' and '2025-03-27'
    and order_status in (2,8)
group by 1,2
having count(auto_id)>=1
)


select
    date_format(register_time,'%Y-%m-%d') `注册日期`,
    count(distinct t1.user_id) `注册用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime)) between 0 and 1,t1.user_id,null)) as `2日内完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime)) between 0 and 3,t1.user_id,null)) as `7日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime)) between 0 and 7,t1.user_id,null)) as `14日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime)) between 0 and 14,t1.user_id,null)) as `30日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime)) between 0 and 30,t1.user_id,null)) as `60日完单用户量`
from t1 left join t2 on t1.user_id=t2.user_id
group by 1;

















