-- 筛选出商圈，人选两家店铺（根据商圈内店铺数量最大，筛选出杭州市'开发区/高教园','高沙商业街'两个店铺）
with t1 as (
select store_id,store_name,longitude as star_lon,latitude as star_lat from dim.dim_silkworm_explore_store
where store_id in (4137, 3581, 4116, 4411, 3646, 192)
),


t2 as (
select
    user_id,province,city,county,address_detail,longitude,latitude
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
)

-- 筛选t1半径5公里内用户
select store_id `店铺ID`,
    store_name `店铺名称`,
    user_id `用户ID`,
    province `用户定位省份`,
    city `用户定位城市`,
    county `用户定位区县`,
    address_detail `用户定位地址`
from 
(select 
    store_id,
    store_name,
    user_id,
    province,
    city,
    county,
    address_detail,
    ST_Distance_Sphere(longitude, latitude, star_lon, star_lat) as distance
from t1 left join t2 on 1=1 
) a
where distance<=5000
group by 1,2,3,4,5,6,7;



