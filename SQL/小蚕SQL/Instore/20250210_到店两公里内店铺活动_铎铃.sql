-- 到店店铺
-- 筛选出商圈，人选两家店铺（根据商圈内店铺数量最大，筛选出杭州市'开发区/高教园','高沙商业街'两个店铺）
with t1 as (
select longitude as star_lon,latitude as star_lat from dim.dim_silkworm_explore_store
where status=1
    and store_id=36 -- 198
),

-- 筛选t1半径2公里内店铺
t2 as (
select * from 
(select 
    store_id,
    store_name,
    sub_category_type, -- 二级类目ID
    city_name,
    business_district,
    ST_Distance_Sphere(longitude, latitude, star_lon, star_lat) as distance
from t1
left join dim.dim_silkworm_explore_store b
on 1=1 and b.status=1 and b.city_name='杭州市'
) a
where distance<=2000
),

-- 探店活动
t3 as (
select
    store_id,
    promotion_id,
    sub_category_type,
    group_discount,-- 团购价
    pay_amt,-- 原价
    rebate_price, -- 返利
    pay_amt-rebate_price as ds_price, -- 到手价
    concat('满',cast(pay_amt as string),'返',cast(rebate_price as string)) as fx_condition -- 返现条件
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(begin_time,1,10)>='2025-01-01'
    and promotion_type in (1,4) -- 探店
)


select 
    t3.store_id `店铺ID`,
    t2.store_name `店铺名称`,
    b.cate2_name `店铺二级类目`,
    business_district `商圈`,
    promotion_id `活动ID`,
    group_discount `团购价`,
    pay_amt `原价`,
    rebate_price `返利`,
    ds_price `到手价`,
    fx_condition `返现条件`,
    distance `与标点店铺距离`
from t3 inner join t2 on t3.store_id=t2.store_id
left join dim.dim_explore_cate b on t3.sub_category_type=b.cat2
group by 1,2,3,4,5,6,7,8,9,10,11
;



