-- 最近7天访问用户
with t as (
select
    silk_id,
    store_id,
    store_name,
    province_name,
    city_name,
    county_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 1 day) and date_sub(current_date(),interval 1 day)
        and city='杭州市'
    ) a
left join
        -- 计算距离经纬度
        (select store_id,store_name,
            province_name,
            city_name,
            county_name,
            longitude as star_lon,
            latitude as star_lat 
from dim.dim_silkworm_explore_store
where city_name='杭州市'
    and status=1
        ) b
    on 1=1
),


select     
    store_id `店铺ID`,
    store_name `店铺名称`,
    province_name `店铺ID`,
    city_name `店铺城市`,
    county_name `店铺区县`
    ,count(distinct if(distance<=3000,silk_id,null)) as `3公里内用户量`
    ,count(distinct if(distance<=5000,silk_id,null)) as `5公里内用户量`
    -- ,count(distinct if(3000<distance<=5000,silk_id,null)) as `3-5公里内用户量`
    ,count(distinct if(distance<=8000,silk_id,null)) as `8公里内用户量`
    ,count(distinct if(distance<=10000,silk_id,null)) as `10公里内用户量`
    ,count(distinct if(distance<=15000,silk_id,null)) as `15公里内用户量`
    ,count(distinct if(distance<=20000,silk_id,null)) as `20公里以内用户量`
from t
group by 1,2,3,4,5
;



================
with t1 as (
select
    silk_id,longitude as end_lon,latitude as end_lat
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 1 day) and date_sub(current_date(),interval 1 day)
        and city='杭州市'
    ),

-- 探店活动
t2 as
(select
    store_id,
    pay_amt,
    ds_price,
    sum(tot_promotion_quota) as promotion_quota,
    sum(used_promotion_quota) as finished_num
from (
select
    store_id,
    promotion_id,
    tot_promotion_quota,
    used_promotion_quota,
    pay_amt,-- 原价
    pay_amt-rebate_price as ds_price
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(begin_time,1,10)='2024-11-15'
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
) a
group by 1,2,3
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
    and promotion_type in (1,4) -- 探店)
group by 1) a
),

-- 店铺属性
t4 as (
select 
    a.store_id,
    a.store_name,
    a.province_name,
    a.city_name,
    a.county_name,
    a.longitude as star_lon,
    a.latitude as star_lat,
    t2.pay_amt,
    t2.ds_price,
    t2.promotion_quota,
    t2.finished_num,
    t3.is_pub
from dim.dim_silkworm_explore_store a 
left join t2 on a.store_id=t2.store_id
left join t3 on a.store_id=t3.store_id
where city_name='杭州市'
    and status=1
),

-- 造出数据集
t5 as (
select
    silk_id,
    store_id,
    store_name,
    province_name,
    city_name,
    county_name,
    pay_amt,
    ds_price,
    promotion_quota,
    finished_num,
    is_pub,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance
from t1
left join t4 on 1=1
)


select     
    store_id `店铺ID`
    ,store_name `店铺名称`
    ,province_name `店铺ID`
    ,city_name `店铺城市`
    ,county_name `店铺区县`
    ,pay_amt `原价`
    ,ds_price `到手价`
    ,promotion_quota `昨日活动名额`
    ,finished_num `昨日完单量`
    ,is_pub `近7天是否发布活动`
    ,count(distinct if(distance<=3000,silk_id,null)) as `3公里内用户量`
    ,count(distinct if(distance<=5000,silk_id,null)) as `5公里内用户量`
    -- ,count(distinct if(3000<distance<=5000,silk_id,null)) as `3-5公里内用户量`
    ,count(distinct if(distance<=8000,silk_id,null)) as `8公里内用户量`
    ,count(distinct if(distance<=10000,silk_id,null)) as `10公里内用户量`
    ,count(distinct if(distance<=15000,silk_id,null)) as `15公里内用户量`
    ,count(distinct if(distance<=20000,silk_id,null)) as `20公里以内用户量`
from t5
group by 1,2,3,4,5,6,7,8,9,10
;



=== 第二版
-- 用户定位
with t1 as (
select
    silk_id,longitude as end_lon,latitude as end_lat
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
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
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
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
where dt>=date_sub(current_date(),interval 180 day)
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

-- -- 昨日访问探店页面 全站
-- t4 as (
-- select
--     cast(user_id as int) as user_id,count(1) as cnt
-- from ods.ods_sr_traffic_event_log
-- where cast(dt as string) between '2024-11-09' and '2024-11-16'        -- date_sub(current_date(),interval 1 day)
--     -- and event_name in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View','Store_Details_View')
--     and user_id regexp '^[0-9]{1,9}$'
-- group by 1
-- having count(1)>0
-- ),

-- 最近7天访问探店页面
t4 as (
select unnest_bitmap from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_id) as uid
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_ename in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View','Store_Details_View')
group by 1
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




================= 捷西 圈选3公里内用户
店铺id    店铺名称
892 覃覃记螺蛳粉（萧山店）
29  覃覃记螺蛳粉（美瑭广场店）
41  覃覃记螺蛳粉（西溪天街店）
35  覃覃记螺蛳粉（总店）
1409    浙帮人·面馆(龙翔桥店)



-- 用户定位
with t1 as (
select
    user_id as silk_id,longitude as end_lon,latitude as end_lat
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
    ),


-- 最近7天访问探店页面
t2 as (
select unnest_bitmap as uid from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_id) as uid
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_ename in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View','Store_Details_View')
group by 1
),


-- 店铺
t3 as (
select 
    a.store_id,
    a.store_name,
    a.province_name,
    a.city_name,
    a.county_name,
    ST_Distance_Sphere(end_lon, end_lat, a.longitude, a.latitude) as distance,
    t2.uid
from dim.dim_silkworm_explore_store a 
left join t1 on 1=1
left join t2 on t1.silk_id=t2.uid
where a.store_id in (3232)
)


select
    store_id `店铺ID`,
    store_name `店铺名称`,
    province_name `店铺省份`,
    city_name `店铺城市`,
    county_name `店铺区县`,
    count(distinct uid) as `3公里内访问用户量`
from t3
where distance/1000<=3
group by 1,2,3,4,5


===========
2968, 3036, 1952, 1454, 3045, 1956, 1958, 1960, 1954, 1948, 1961, 1962, 1964, 1959, 2891, 3010, 3116

-- 用户定位
with t1 as (
select
    silk_id,longitude as end_lon,latitude as end_lat
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    -- and city='杭州市'
    ),


-- 最近7天访问探店页面
t2 as (
select unnest_bitmap as uid from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_id) as uid
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_ename in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View','Store_Details_View')
group by 1
),


-- 店铺
t3 as (
select 
    a.store_id,
    a.store_name,
    a.province_name,
    a.city_name,
    a.county_name,
    ST_Distance_Sphere(end_lon, end_lat, a.longitude, a.latitude) as distance,
    t2.uid
from dim.dim_silkworm_explore_store a 
left join t1 on 1=1
left join t2 on t1.silk_id=t2.uid
where a.store_id in (2968, 3036, 1952, 1454, 3045, 1956, 1958, 1960, 1954, 1948, 1961, 1962, 1964, 1959, 2891, 3010, 3116)
)


select
    store_id `店铺ID`,
    store_name `店铺名称`,
    province_name `店铺省份`,
    city_name `店铺城市`,
    county_name `店铺区县`,
    -- count(distinct uid) as `3公里内访问用户量`
    uid as `近7天3公里内访问用户ID`
from t3
where distance/1000<=3
group by 1,2,3,4,5,6;




===== 发布过砍价活动店铺
select
    a.store_id `店铺ID`,
    b.store_name `店铺名称`,
    b.province_name `店铺省份`,
    b.city_name `店铺城市`,
    b.county_name `店铺区县`,
    b.business_district `商圈`,
    b.address_detail `店铺地址`,
    b.bd_id `bd_id`
from
-- 发布砍价活动店铺
(select store_id 
from dwd.dwd_sr_silkworm_explore_promotion
where promotion_type=5
group by 1
) a
left join dim.dim_silkworm_explore_store b on a.store_id=b.store_id
;






















