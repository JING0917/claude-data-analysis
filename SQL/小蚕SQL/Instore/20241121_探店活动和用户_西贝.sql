-- 用户定位
with t1 as (
select
    silk_id,longitude as end_lon,latitude as end_lat
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
    ),


-- 探店活动
t2 as
(select
    store_id,
    demand_promotion_type,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    pay_amt,
    ds_price,
    sum(tot_promotion_quota) as promotion_quota,
    sum(used_promotion_quota) as used_promotion_quota,
    sum(wait_verify_order_num) as wait_verify_order_num,
    sum(finished_num) as finished_num
from (
select
    store_id,
    promotion_id,
    demand_promotion_type,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    tot_promotion_quota,
    used_promotion_quota,
    pay_amt,-- 原价
    pay_amt-rebate_price as ds_price
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(begin_time,1,10)='2024-11-16'
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
) a
left join 
-- 已支付待核销订单量 完单量
(select
    store_promotion_id,
    count(if(status=3,order_id,null)) as wait_verify_order_num,
    count(if(status in (5,19,20),order_id,null)) as finished_num
from dwd.dwd_sr_silkworm_explore_order
where dt>=date_sub(current_date(),interval 7 day)
    and promotion_type in (1,4)
    and status in (3,5,19,20) -- 已支付待核销
group by 1) b
on a.promotion_id=b.store_promotion_id
group by 1,2,3,4,5,6
),

-- 最近7天是否发活动
t3 as (
select
    store_id,if(pro_num>0,'是','否') as is_pub
from(
select
    store_id,
    count(1) as pro_num
from dwd.dwd_sr_silkworm_explore_promotion
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
group by 1) a
),

-- 昨日访问探店页面 全站
t4 as (
select
    cast(user_id as int) as user_id,count(1) as cnt
from ods.ods_sr_traffic_event_log
where cast(dt as string)='2024-11-16'        -- date_sub(current_date(),interval 1 day)
    -- and event_name in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View')
    and user_id regexp '^[0-9]{1,9}$'
group by 1
having count(1)>0
),


-- 店铺属性
t5 as (
select 
    a.store_id,
    a.store_name,
    a.province_name,
    a.city_name,
    a.county_name,
    a.longitude as star_lon,
    a.latitude as star_lat,
    t2.demand_promotion_type,
    t2.demand_dp_user_lvl,
    t2.demand_xiaohongshu_fans_num,
    t2.pay_amt,
    t2.ds_price,
    t2.promotion_quota,
    t2.used_promotion_quota,
    t2.wait_verify_order_num,
    t2.finished_num,
    t3.is_pub
from dim.dim_silkworm_explore_store a 
left join t2 on a.store_id=t2.store_id
left join t3 on a.store_id=t3.store_id
where city_name='杭州市'
    and status=1
),

-- daren
daren as (
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 造出数据集
t6 as (
select
    silk_id,
    store_id,
    store_name,
    province_name,
    city_name,
    county_name,
    demand_promotion_type,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    pay_amt,
    ds_price,
    promotion_quota,
    used_promotion_quota,
    wait_verify_order_num,
    finished_num,
    is_pub,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    if(daren.user_id is not null,1,0) is_daren
from t1
inner join t4 on t1.silk_id=t4.user_id
left join daren on t1.silk_id=daren.user_id
left join t5 on 1=1
)



select     
    store_id `店铺ID`
    ,store_name `店铺名称`
    ,province_name `店铺ID`
    ,city_name `店铺城市`
    ,county_name `店铺区县`
    ,demand_promotion_type `活动要求类型`
    ,demand_dp_user_lvl `点评要求用户等级`
    ,demand_xiaohongshu_fans_num `粉丝数要求`
    ,pay_amt `原价`
    ,ds_price `到手价`
    ,promotion_quota `活动名额`
    ,used_promotion_quota `已占用活动名额`
    ,wait_verify_order_num `已支付待核销订单量`
    ,finished_num `完单量`
    ,is_pub `近7天是否发布活动`
    ,count(distinct if(distance<=3000,silk_id,null)) as `3公里内用户量`
    ,count(distinct if(distance<=5000,silk_id,null)) as `5公里内用户量`
    ,count(distinct if(distance<=8000,silk_id,null)) as `8公里内用户量`
    ,count(distinct if(distance<=10000,silk_id,null)) as `10公里内用户量`
    ,count(distinct if(distance<=15000,silk_id,null)) as `15公里内用户量`
    ,count(distinct if(distance<=20000,silk_id,null)) as `20公里以内用户量`

    ,count(distinct if(is_daren=1 and distance<=3000,silk_id,null)) as `3公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=5000,silk_id,null)) as `5公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=8000,silk_id,null)) as `8公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=10000,silk_id,null)) as `10公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=15000,silk_id,null)) as `15公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=20000,silk_id,null)) as `20公里以内达人用户量`


from t6
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;