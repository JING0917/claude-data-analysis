杭州砍价的数据哈，我需要12月杭州砍价每一天的活动下单数，活动名额总数，活动核销数这些~


-- 砍价活动
with t1 as (
select
	dt,
    promotion_id,
    '杭州' as city_name,
    tot_promotion_quota
from dwd.dwd_sr_silkworm_explore_promotion
where dt between '2024-12-01' and date_sub(current_date(),interval 1 day)
    and substr(cast(city_code as string),1,4)='3301' -- 杭州
    and promotion_type=5 -- 砍价 
),

-- 砍价订单 
t2 as (
select
	store_promotion_id,
	count(if(substr(pay_time,1,10)<>'1970-01-01',order_id,null)) as pay_order_num, -- 砍价支付订单量
	count(if(substr(verify_time,1,10)<>'1970-01-01',order_id,null)) as verify_order_num -- 砍价核销订单量
from dwd.dwd_sr_silkworm_explore_order
where dt between '2024-12-01' and date_sub(current_date(),interval 1 day)
    and promotion_type=5 -- 砍价
group by 1
	)


select
	t1.dt as `统计日期`,
	t1.city_name as `城市`,
	sum(tot_promotion_quota) as `活动名额`,
	sum(pay_order_num) as `支付订单量`,
	sum(verify_order_num) as `核销订单量` 
from t1 left join t2 on t1.promotion_id=t2.store_promotion_id
group by 1,2;




============ 砍价参与用户量统计 哆哆
-- 砍价记录
with t1 as (
select
    date(create_time) as dat,
    auto_id,
    promotion_id,
    user_id
from dwd.dwd_sr_silkworm_explore_bargain_record
where date(create_time)='2025-01-04'
    and status=1
),

-- 砍价活动
t2 as (
select
	dt,
    promotion_id,
    '杭州' as city_name,
    tot_promotion_quota
from dwd.dwd_sr_silkworm_explore_promotion
where dt between '2024-12-01' and date_sub(current_date(),interval 1 day)
    and substr(cast(city_code as string),1,4)='3301' -- 杭州
    and promotion_type=5 -- 砍价 
)

select
    -- count(t1.auto_id) as `砍价次数`,
    -- count(distinct t1.user_id) as `砍价人数`
    t1.*
from t2 inner join t1 on t2.promotion_id=t1.promotion_id
;