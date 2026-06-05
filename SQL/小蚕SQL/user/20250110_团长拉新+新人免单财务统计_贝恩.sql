-- part_1 团长拉新 
select
    a.mon,
    a.unum `团长拉新用户量`,
    a.cost `团长拉新支出`,
    b.finished_cost `完成拉新挑战赛支出`,
    b.extra_cost `完成挑战赛团长奖励支出`
from
    -- 每日注册用户量和团长拉新支出
    (select
        concat(year(register_time),'-',month(register_time)) as mon,
        count(1) as unum,
        sum(case when accu_valid_order_num=1 then 3
                when accu_valid_order_num>=2 then 13
            else 0 end
        ) as cost
    from dim.dim_silkworm_user
    where substr(register_time,1,10) between '2024-01-01' and '2024-12-31'
        and inviter_user_id<>0
    group by 1
    ) a
left join
        -- 拉新挑战赛支出
        (select
            concat(year(dt),'-',month(dt)) as mon,
            sum(reward_value)/100 finished_cost,
            sum(commander_reward)/100 as extra_cost
        from dws.dws_sr_silkworm_challenge_td
        where dt between '2024-01-01' and '2024-12-31'
            and challenge_type=2 -- 1下单 2邀请
        group by 1
        ) b on a.mon=b.mon
;


-- 团长拉新支出
-- 团长拉新用户
with t1 as (
select
    user_id
from dim.dim_silkworm_user
where inviter_user_id<>0
),

-- 用户首单和第二单
t2 as (
select
    user_id,order_time,if(rk=1,3,10) as tz_reward_amt -- 团长拉新奖励
from (
    select
        order_time,
        user_id,
        row_number() over(partition by user_id order by order_time) as rk
    from dwd.dwd_sr_order_promotion_order
    where order_status in (2,8)
    ) a
where rk<=2
)


-- select
--     t2.user_id,t2.order_time,t2.tz_reward_amt
-- from t2
-- left join t1 on t2.user_id=t1.user_id
-- where t1.user_id is not null
-- limit 100
-- ;

-- 统计每月拉新支出
select
    -- t2.user_id,t2.order_time,t2.tz_reward_amt
    substr(t2.order_time,1,7) as mon,
    sum(tz_reward_amt) as tz_reward_amt
from t2
left join t1 on t2.user_id=t1.user_id
where t1.user_id is not null
group by 1
;


-- 验证数据 无问题
select * from dim.dim_silkworm_user where user_id=2115024;

select
        order_time,
        user_id,
        row_number() over(partition by user_id order by order_time) as rk
    from dwd.dwd_sr_order_promotion_order
    where dt between '2023-12-01' and '2024-12-31'
        and substr(order_time,1,10) between '2024-01-01' and '2024-12-31'
        and order_status in (2,8)
        and user_id=2115024
;




-- part_2 打卡挑战赛

-- 下单挑战赛参与用户
select
    mon,
    count(distinct user_id) as unum
from
(select 
    month(dt) as mon,
    unnest as user_id
from dws.dws_sr_silkworm_challenge_td,unnest(par_user_list) as userid
where dt between '2024-01-01' and '2024-12-31'
    and challenge_type=1 -- 1下单 2邀请
) a
group by 1;

-- 下单挑战赛指标
select 
    month(dt) as mon,
    sum(order_num_dt) as order_num, -- 完单量
    sum(reward_value)/100 as finished_cost, -- 成本
    sum(commander_reward)/100 as commander_cost, -- 团长额外奖励
    sum(order_profit_dt)/100 as order_profit
from dws.dws_sr_silkworm_challenge_td
where dt between '2024-01-01' and '2024-12-31'
    and challenge_type=1 -- 1下单 2邀请
group by 1;



-- part_3 新人免单
-- 注册用户量+首单用户量
select
    month(register_time) as mon,
    count(1) as unum,
    sum(if(substr(first_valid_order_time,1,10)<>'1970-01-01',1,0)) as sd_unum
from dim.dim_silkworm_user
where substr(register_time,1,10) between '2024-01-01' and '2024-12-31'
group by 1;


-- 首单用户
with t1 as (
select
    user_id,order_time
from (
    select
        order_time,
        user_id,
        row_number() over(partition by user_id order by order_time) as rk
    from dwd.dwd_sr_order_promotion_order
    where order_status in (2,8)
    ) a
where rk=1
)


select
    substr(order_time,1,7) as mon,
    count(distinct user_id) as cnt
from t1
group by 1;


=========
-- 新人免单红包
with t0 as (
    -- 红包ID
SELECT
cast (redpack_id as int) as redpack_id
FROM
    (
        SELECT
         get_json_string(value, "$.red_pack_id")AS  redpack_id
        FROM
            (
            SELECT
                *
            FROM
                dwd.dwd_sr_user_newuser_reward_record,JSON_EACH(PARSE_JSON(redpack_info)) as unnest
            ) t1 
    ) t2
group by cast (redpack_id as int)
),

-- 数据量 3331538
t2 as (
select 
    dt,
    user_id
    ,order_id
    ,redpacket_use_status
    ,a.redpacket_id
from (select dt
            ,user_id
            ,order_id
            ,redpacket_use_status
            ,redpacket_id
           from dwd.dwd_sr_market_redpack_use_record
           where dt between '2024-01-01' and '2024-12-31'
                    and order_id<>'' -- 20241108 剔除无订单ID数据 修改人：dahe
    ) a
inner join t0 on a.redpacket_id=t0.redpack_id
),

-- 24982424
t3 as (
    select profit 
            ,user_id
            ,order_id
            ,redpacket_amt
            ,left(order_time,10) as order_date
    from dwd.dwd_sr_order_promotion_order
    where dt between '2024-01-01' and '2025-01-13'
    and order_status in (2,8)
    and order_id<>'' -- 20241108 剔除无订单ID数据 修改人：dahe
)



select
    month(t2.dt) mon,
    count(distinct t2.user_id) as cy_user_num,
    sum(if(t2.redpacket_use_status=2 and t3.order_id is not null,t3.redpacket_amt,0)) as redpacket_amt,
    sum(if(t2.redpacket_use_status=2 and t3.order_id is not null,t3.profit,0)) as profit
from t2 left join t3 on t2.order_id=t3.order_id
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
where substr(register_time,1,10) between '2024-01-01' and '2024-12-31'
),

-- 每日完单量
t2 as (
select 
    order_time,
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order 
where cast(dt as string) between '2024-01-01' and '2025-01-14'
    and order_status in (2,8)
group by 1,2
having count(auto_id)>=1
)


select
    month(register_time) as mon,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=0,t1.user_id,null)) as `当日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=1,t1.user_id,null)) as `次日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=7,t1.user_id,null)) as `7日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=14,t1.user_id,null)) as `14日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=30,t1.user_id,null)) as `30日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=60,t1.user_id,null)) as `60日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=90,t1.user_id,null)) as `90日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=180,t1.user_id,null)) as `180日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=270,t1.user_id,null)) as `270日完单用户量`,
    count(distinct if(datediff(cast(t2.order_time as datetime),cast(t1.register_time as datetime))=365,t1.user_id,null)) as `365日完单用户量`
from t1 left join t2 on t1.user_id=t2.user_id
group by 1;




















