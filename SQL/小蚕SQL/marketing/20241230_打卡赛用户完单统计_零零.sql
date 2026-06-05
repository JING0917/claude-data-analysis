with t1 as (
select '20241126-1202' as user_type,get_json_int(value,'$.SilkId') AS user_id from dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(group_user_id_list)) AS a
where dt between '2024-11-26' and '2024-12-02'
    and challenge_type=1 -- 打卡
group by 1,2

union all

select '20241203-1209' as user_type,get_json_int(value,'$.SilkId') AS user_id from dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(group_user_id_list)) AS a
where dt between '2024-12-03' and '2024-12-09'
    and challenge_type=1 -- 打卡
group by 1,2

union all

select '20241210-1216' as user_type,get_json_int(value,'$.SilkId') AS user_id from dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(group_user_id_list)) AS a
where dt between '2024-12-10' and '2024-12-16'
    and challenge_type=1 -- 打卡
group by 1,2
),

t2 as (
select 
    '20241126-1202' as user_type,
    user_id,
    count(if(substr(order_time,1,10) between '2024-11-26' and '2024-12-03',auto_id,null)) as `同期完单量`,
    count(if(substr(order_time,1,10) between '2024-12-17' and '2024-12-23',auto_id,null)) as `1217至23完单量`
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2024-12-23'
    and substr(order_time,1,10) between '2024-11-26' and '2024-12-23'
    and order_status in (2,8)
group by 1,2

union all
select 
    '20241203-1209' as user_type,
    user_id,
    count(if(substr(order_time,1,10) between '2024-12-03' and '2024-12-09',auto_id,null)) as `同期完单量`,
    count(if(substr(order_time,1,10) between '2024-12-17' and '2024-12-23',auto_id,null)) as `1217至23完单量`
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2024-12-23'
    and substr(order_time,1,10) between '2024-12-03' and '2024-12-23'
    and order_status in (2,8)
group by 1,2

union all
select 
    '20241210-1216' as user_type,
    user_id,
    count(if(substr(order_time,1,10) between '2024-12-10' and '2024-12-16',auto_id,null)) as `同期完单量`,
    count(if(substr(order_time,1,10) between '2024-12-17' and '2024-12-23',auto_id,null)) as `1217至23完单量`
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2024-12-23'
    and substr(order_time,1,10) between '2024-12-10' and '2024-12-23'
    and order_status in (2,8)
group by 1,2
)

select
    t1.user_type `时间周期`,
    count(t1.user_id) `参与用户量`,
    sum(t2.`同期完单量`) `同期完单量`,
    sum(t2.`1217至23完单量`) `1217至23完单量`
from t1 left join t2 on t1.user_type=t2.user_type and t1.user_id=t2.user_id
group by 1 
;


=====================================================================

12月24-27号报名打卡赛id366/id367的两批用户在参与活动期间的完单数、人均完单数以及这些用户在报名前的近7天的完单量和人均完单数分别是多少

with t1 as (
select 
    get_json_int(value,'$.SilkId') AS user_id
from dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(group_user_id_list)) AS a
where dt between '2024-12-24' and '2024-12-27'
    and challenge_type=1 -- 打卡
    and challenge_id in ('366','367')
group by 1),

t2 as (
select 
    user_id,
    count(if(substr(order_time,1,10) between '2024-12-17' and '2024-12-23',auto_id,null)) as `报名前7天完单量`,
    count(if(substr(order_time,1,10) between '2024-12-24' and '2024-12-27',auto_id,null)) as `1224至27完单量`
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2024-12-27'
    and substr(order_time,1,10) between '2024-12-17' and '2024-12-27'
    and order_status in (2,8)
group by 1
)


select
    count(t1.user_id) as `报名用户量`,
    sum(if(t2.user_id is not null,t2.`报名前7天完单量`,0)) as `报名前7天完单量`,
    sum(if(t2.user_id is not null,t2.`1224至27完单量`,0)) as `1224至27完单量`
from t1 left join t2 on t1.user_id=t2.user_id
;


-- 分活动
with t1 as (
select 
    challenge_id,
    get_json_int(value,'$.SilkId') AS user_id
from dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(group_user_id_list)) AS a
where dt between '2024-12-24' and '2024-12-27'
    and challenge_type=1 -- 打卡
    and challenge_id in ('366','367')
group by 1,2),

t2 as (
select 
    user_id,
    count(if(substr(order_time,1,10) between '2024-12-17' and '2024-12-23',auto_id,null)) as `报名前7天完单量`,
    count(if(substr(order_time,1,10) between '2024-12-24' and '2024-12-27',auto_id,null)) as `1224至27完单量`
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2024-12-27'
    and substr(order_time,1,10) between '2024-12-17' and '2024-12-27'
    and order_status in (2,8)
group by 1
)


select
    challenge_id,
    count(t1.user_id) as `报名用户量`,
    sum(if(t2.user_id is not null,t2.`报名前7天完单量`,0)) as `报名前7天完单量`,
    sum(if(t2.user_id is not null,t2.`1224至27完单量`,0)) as `1224至27完单量`
from t1 left join t2 on t1.user_id=t2.user_id
group by 1
;

=====================================================================
-- 366 367挑战赛参与用户 参与前7天的完单和利润，参与后完单量、利润、成本
-- 366 7天累计完成5单，完成后奖励5元；367 7天累计完成7单，完成后奖励7元

-- 参与用户
-- 存在同用户同一天多次参与，以及有效期内多次参与
select * from ods.ods_sr_silkworm_challenge_register where challenge_id in ('366','367');

-- 参与用户统计
select challenge_id,
    count(distinct use_id) as unum
from ods.ods_sr_silkworm_challenge_register
where challenge_id in ('366','367')
group by 1;


-- 多次参与，按照首次参与取数，便于之后计算参与前完单量
select challenge_id,use_id,create_time from
(select challenge_id,
    use_id,
    create_time,
    row_number() over(partition by challenge_id,use_id order by create_time) as rk
from ods.ods_sr_silkworm_challenge_register
where challenge_id in ('366','367')
) a
where rk=1;


-- 参与结果统计
-- 最小分区20241224 最大分区20250104
select
    *
from dws.dws_sr_silkworm_challenge_td
where challenge_id in (366,367)
;




-- 参与用户量
with t1 as (
select challenge_id,
    count(distinct use_id) as unum
from ods.ods_sr_silkworm_challenge_register
where challenge_id in ('366','367')
group by 1
),


-- 参与用户参与前7天内完单量
t2 as (select challenge_id,use_id,create_time from
(select challenge_id,
    use_id,
    create_time,
    row_number() over(partition by challenge_id,use_id order by create_time) as rk
from ods.ods_sr_silkworm_challenge_register
where challenge_id in ('366','367')
) a
where rk=1
),


-- 完单量
t3 as (
select 
    user_id,
    substr(order_time,1,10) as order_date,
    count(1) as valid_order_num,
    sum(profit) as profit
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2024-12-27'
    and substr(order_time,1,10) between '2024-12-17' and '2024-12-27'
    and order_status in (2,8)
group by 1,2
),


-- 参与前7天完单量
t4 as (
select
    -- t2.challenge_id,
    -- t2.use_id,
    -- t2.create_time,
    -- t3.order_date,
    -- datediff(t2.create_time,cast(t3.order_date as datetime)) as diff,
    -- t3.valid_order_num
    t2.challenge_id,
    sum(t3.valid_order_num) as valid_order_num,
    sum(t3.profit) as profit
from t2 left join t3 on t2.use_id=t3.user_id and datediff(t2.create_time,cast(t3.order_date as date)) between 1 and 7
group by 1
),

-- 挑战赛完成指标统计
t5 as (
select 
    challenge_id,
    sum(order_num_dt) as order_num, -- 完单量
    sum(reward_value)/100 as finished_cost, -- 成本
    sum(commander_reward)/100 as commander_cost, -- 团长额外奖励
    sum(order_profit_dt)/100 as order_profit
from dws.dws_sr_silkworm_challenge_td
where dt between '2024-12-24' and '2025-01-04'
    and challenge_id in (366,367)
group by 1
)




select
    t1.challenge_id,
    t1.unum as `报名用户量`,
    t4.valid_order_num as `报名前7天完单量`,
    t4.profit as `报名前7天完单利润`,
    t5.order_num as `活动期间完单量`,
    t5.finished_cost,
    t5.commander_cost,
    t5.commander_cost+t5.finished_cost as `活动成本`,
    t5.order_profit `活动利润`
from t1 left join t4 on t1.challenge_id=t4.challenge_id
left join t5 on t1.challenge_id=t5.challenge_id
;



=============================

-- 24年春节前5天，用户下单分布
select
    '2024/02/02-2024/02/06' as `统计周期`,
    -- min(valid_order_num) as `有效订单量最小值`,
    -- PERCENTILE_CONT(valid_order_num,0.1) as `有效订单量10分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.2) as `有效订单量20分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.3) as `有效订单量30分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.4) as `有效订单量40分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.5) as `有效订单量50分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.6) as `有效订单量60分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.7) as `有效订单量70分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.8) as `有效订单量80分位值`,
    -- PERCENTILE_CONT(valid_order_num,0.9) as `有效订单量90分位值`,
    -- PERCENTILE_CONT(valid_order_num,1) as `有效订单量最大值`
    valid_order_num,
    count(user_id) as cnt
from
(select
    user_id,count(auto_id) as valid_order_num
from dwd.dwd_sr_order_promotion_order
where dt between '2024-01-01' and '2024-02-06'
    and substr(order_time,1,10) between '2024-02-02' and '2024-02-06'
    and order_status in (2,8)
group by user_id
) a
group by 1,2;



-- 近30天活跃天数
select
    ad_num as `活跃天数`,
    count(user_id) `用户量`
from (
select 
    user_id,
    count(distinct statistics_date) as ad_num -- 活跃天数
from dws.dws_sr_traffic_user_d
where statistics_date between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    -- and user_id regexp '^[0-9]{1,9}$'
group by 1
) a
group by 1
;


-- 近30天活跃用户下单量分布
-- 活跃天数
-- with t1 as (
-- select 
--     user_id,
--     count(distinct statistics_date) as ad_num -- 活跃天数
-- from dws.dws_sr_traffic_user_d
-- where statistics_date between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
--     and user_id regexp '^[0-9]{1,9}$'
-- group by 1
-- ),

-- -- 近30天完单量
-- t2 as (
-- select
--     user_id,count(auto_id) as valid_order_num
-- from dwd.dwd_sr_order_promotion_order
-- where dt between '2024-11-01' and '2025-01-19'
--     and substr(order_time,1,10) between '2024-12-21' and '2025-01-19'
--     and order_status in (2,8)
-- group by user_id
-- )

-- select
--     ad_num  `活跃天数`,
--     valid_order_num  `有效订单量`,
--     count(distinct t1.user_id) as `活跃用户量`,
--     count(distinct if(t2.user_id is not null,t1.user_id,null)) as `完单用户量`
-- from t1 left join t2
-- on t1.user_id=t2.user_id -- and t1.ad_num=1
-- group by 1,2;


-- 验证数据 1555209人完单
select
    valid_order_num,count(user_id) as cnt
from
(select
    user_id,count(auto_id) as valid_order_num
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2025-02-19'
    and substr(order_time,1,10) between '2024-12-21' and '2025-01-19'
    and order_status in (2,8)
group by user_id
) a
group by 1;


-- 验数，直接让活跃用户和完单用户关联，结果不准
select 
    -- platform_name,event_name,def_resource_id,def_put_id,count(1) as cnt,count(distinct user_id) as uv
    *
from ods.ods_sr_traffic_event_log
where dt>=date_sub(current_date(),interval 30 day)
    and user_id=39895035 -- 923592157
    -- and event_name in ('Homepage_Headpic_Ex','Homepage_Headpic_Click')
;

----------- 使用下单方式，替代活跃天数
select
    order_date_cnt `活跃天数`,
    valid_order_num `有效订单量`,
    count(distinct user_id) as `用户量`
from
(
select
    user_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num,
    count(distinct substr(order_time,1,10)) as order_date_cnt
from dwd.dwd_sr_order_promotion_order
where dt between '2024-11-01' and '2025-01-17'
    and substr(order_time,1,10) between '2024-12-19' and '2025-01-17'
group by user_id
) a
group by 1,2;


=============== **天内拉新用户量分布
-- 近*天每天拉新人数分布
select
    '近3天' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
group by 1

union all
-- 近*天每天拉新人数分布
select
    '近5天' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 5 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
group by 1

union all
-- 近*天每天拉新人数分布
select
    '近7天' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
group by 1

union all
-- 近*天每天拉新人数分布
select
    '近10天' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 10 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
group by 1
;



-- 前述取值是>=2 跨度较大，所以取>=2再看
-- 近*天每天拉新人数分布
select
    '近3天拉新2个用户量以上' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
where newuser_num>2
group by 1

union all
-- 近*天每天拉新人数分布
select
    '近5天拉新2个用户量以上' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 5 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
where newuser_num>2
group by 1

union all
-- 近*天每天拉新人数分布
select
    '近7天拉新2个用户量以上' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
where newuser_num>2
group by 1

union all
-- 近*天每天拉新人数分布
select
    '近10天拉新2个用户量以上' `类型`,
    min(newuser_num) as `团长拉新用户量最小值`,
    PERCENTILE_CONT(newuser_num,0.1) as `团长拉新用户量10分位值`,
    PERCENTILE_CONT(newuser_num,0.2) as `团长拉新用户量20分位值`,
    PERCENTILE_CONT(newuser_num,0.3) as `团长拉新用户量30分位值`,
    PERCENTILE_CONT(newuser_num,0.4) as `团长拉新用户量40分位值`,
    PERCENTILE_CONT(newuser_num,0.5) as `团长拉新用户量50分位值`,
    PERCENTILE_CONT(newuser_num,0.6) as `团长拉新用户量60分位值`,
    PERCENTILE_CONT(newuser_num,0.7) as `团长拉新用户量70分位值`,
    PERCENTILE_CONT(newuser_num,0.8) as `团长拉新用户量80分位值`,
    PERCENTILE_CONT(newuser_num,0.9) as `团长拉新用户量90分位值`,
    PERCENTILE_CONT(newuser_num,1) as `团长拉新用户量最大值`
from
-- 近*天每天拉新人数
(select
    inviter_user_id,
    count(user_id) as newuser_num
from dim.dim_silkworm_user
where str_to_date(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 10 day) and date_sub(current_date(),interval 1 day)
    and inviter_user_id<>0
group by 1
) a
where newuser_num>2
group by 1
;



========== 邀请挑战赛拉新用户统计
-- 邀请挑战赛拉新用户数
select
    date_format(dt,'%Y-%m-%d') as `统计日期`,
    sum(new_user_num) as `邀请新用户量`
from dws.dws_sr_silkworm_challenge_td
where date_format(dt,'%Y-%m-%d') between '2024-01-01' and '2024-12-31'
    and challenge_type=2 -- 1:下单,2:邀请
group by 1
;


























