========== part1 访问用户留存和访问用户重合度
-- 小蚕每日访问用户
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (view_date,user_id) AS
  (SELECT date_format(dt,'%Y-%m-%d') view_date,
                                     unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND substr(county_id,1,4)='3301'
     -- AND event_ename not regexp 'StoreDiscovery|Bargain' -- 统计重合度时，需排除到到店访问用户，因到店访问用户，一定会在访问小蚕用户中
   GROUP BY 1,
            2);

-- 用户注册日期
DROP VIEW IF EXISTS user_info;


CREATE VIEW IF NOT EXISTS user_info (user_id,register_date) AS
  (SELECT user_id,
          date_format(register_time,'%Y-%m-%d') register_date
   FROM dim.dim_silkworm_user);


-- 到店每日访问用户
DROP VIEW IF EXISTS view_explore_info;


CREATE VIEW IF NOT EXISTS view_explore_info (view_date,user_id) AS
  (SELECT date_format(dt,'%Y-%m-%d') view_date,
                                     unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND event_ename regexp 'StoreDiscovery|Bargain'
     AND substr(county_id,1,4)='3301'
   GROUP BY 1,
            2);


-- 小蚕访问留存
SELECT a.view_date `访问日期` ,
       count(DISTINCT a.user_id) `访问用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=1,a.user_id,NULL)) `次日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=2,a.user_id,NULL)) `3日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=4,a.user_id,NULL)) `5日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=6,a.user_id,NULL)) `7日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=13,a.user_id,NULL)) `14日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=20,a.user_id,NULL)) `21日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=29,a.user_id,NULL)) `30日访问留存用户量`,
       count(DISTINCT if(a.view_date=c.register_date,a.user_id,NULL)) `新访问用户量`
FROM view_info a
LEFT JOIN view_info b ON a.user_id=b.user_id
AND a.view_date<>b.view_date
LEFT JOIN user_info c ON a.user_id=c.user_id
GROUP BY 1;


-- 到店访问留存
SELECT a.view_date `访问日期` ,
       count(DISTINCT a.user_id) `访问用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=1,a.user_id,NULL)) `次日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=2,a.user_id,NULL)) `3日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=4,a.user_id,NULL)) `5日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=6,a.user_id,NULL)) `7日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=13,a.user_id,NULL)) `14日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=20,a.user_id,NULL)) `21日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=29,a.user_id,NULL)) `30日访问留存用户量`,
       count(DISTINCT if(a.view_date=c.register_date,a.user_id,NULL)) `新访问用户量`
FROM view_explore_info a
LEFT JOIN view_explore_info b ON a.user_id=b.user_id
AND a.view_date<>b.view_date
LEFT JOIN user_info c ON a.user_id=c.user_id
GROUP BY 1;


-- 小蚕访问重合
SELECT a.view_date `访问日期` ,
       count(DISTINCT a.user_id) `访问用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=1,a.user_id,NULL)) `次日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 2,a.user_id,NULL)) `3日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 4,a.user_id,NULL)) `5日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 6,a.user_id,NULL)) `7日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 13,a.user_id,NULL)) `14日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 20,a.user_id,NULL)) `21日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 29,a.user_id,NULL)) `30日访问留存用户量`,
       count(DISTINCT if(a.view_date=c.register_date,a.user_id,NULL)) `新访问用户量`
FROM view_info a
LEFT JOIN view_info b ON a.user_id=b.user_id
AND a.view_date<b.view_date
LEFT JOIN user_info c ON a.user_id=c.user_id
GROUP BY 1;


-- 到店访问重合
SELECT a.view_date `访问日期` ,
       count(DISTINCT a.user_id) `访问用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date)=1,a.user_id,NULL)) `次日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 2,a.user_id,NULL)) `3日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 4,a.user_id,NULL)) `5日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 6,a.user_id,NULL)) `7日访问留存用户量` ,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 13,a.user_id,NULL)) `14日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 20,a.user_id,NULL)) `21日访问留存用户量`,
       count(DISTINCT if(date_diff('day',b.view_date,a.view_date) between 1 and 29,a.user_id,NULL)) `30日访问留存用户量`,
       count(DISTINCT if(a.view_date=c.register_date,a.user_id,NULL)) `新访问用户量`
FROM view_explore_info a
LEFT JOIN view_explore_info b ON a.user_id=b.user_id
AND a.view_date<b.view_date
LEFT JOIN user_info c ON a.user_id=c.user_id
GROUP BY 1;


-- 到店日访问用户和小蚕日访问用户重合度
SELECT a.view_date `访问日期` ,
       count(DISTINCT a.user_id) `到店访问用户量`,
       count(if(b.user_id IS NOT NULL,a.user_id,NULL)) `到店和小蚕访问重合用户量`
FROM view_explore_info a
LEFT JOIN view_info b ON a.user_id=b.user_id
AND a.view_date=b.view_date
GROUP BY 1;



================ part2 砍价购买(支付)频次
-- 砍价活动
DROP VIEW IF EXISTS pro_info;


CREATE VIEW IF NOT EXISTS pro_info ( promotion_id,sub_category_type) AS
  ( SELECT promotion_id ,
           CASE
               WHEN sub_category_type = 0 THEN '未知'
               WHEN sub_category_type = 1 THEN '包子粥铺'
               WHEN sub_category_type = 2 THEN '汉堡西餐'
               WHEN sub_category_type = 3 THEN '火锅烧烤'
               WHEN sub_category_type = 4 THEN '快餐简餐'
               WHEN sub_category_type = 5 THEN '理发/男士'
               WHEN sub_category_type = 6 THEN '亲子/乐园'
               WHEN sub_category_type = 7 THEN '水果生鲜'
               WHEN sub_category_type = 8 THEN '甜品饮品'
               WHEN sub_category_type = 9 THEN '休闲/玩乐'
               WHEN sub_category_type = 10 THEN '炸串小吃'
               WHEN sub_category_type = 11 THEN '正餐/多人餐'
           END AS sub_category_type
   FROM dwd.dwd_sr_silkworm_explore_promotion
   WHERE date_format(begin_time,'%Y-%m-%d') BETWEEN '2024-11-01' AND date_sub(current_date(),interval 0 DAY)
     AND promotion_type IN (5,
                            6)
     AND substr(cast(city_code AS string),1,4)='3301'
    );


-- 近30天砍价支付订单量
DROP VIEW IF EXISTS lastm_order_info;


CREATE VIEW IF NOT EXISTS lastm_order_info (user_id,store_promotion_id,payord_num) AS
  (SELECT user_id,
          store_promotion_id,
          count(1) AS payord_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 31 DAY) AND date_sub(current_date(),interval 2 DAY)
     AND date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
     AND promotion_type IN (5,
                            6)
     and substr(cast(city_id as string),1,4)='3301'
   GROUP BY 1,
            2);


-- 近90天砍价支付订单量
DROP VIEW IF EXISTS last90d_order_info;


CREATE VIEW IF NOT EXISTS last90d_order_info (ym,user_id,store_promotion_id,payord_num) AS
  (SELECT date_format(dt,'%Y-%m') ym,
                                  user_id,
                                  store_promotion_id,
                                  count(1) AS payord_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND '2025-03-31'
     AND date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
     AND promotion_type IN (5,
                            6)
     and substr(cast(city_id as string),1,4)='3301'
   GROUP BY 1,
            2,
            3);


-- 用户月均支付订单量
DROP VIEW IF EXISTS user_payore_num;


CREATE VIEW IF NOT EXISTS user_payore_num ( user_id,avg_payord_num) AS
  (SELECT a.user_id,
          b.avg_payord_num -- `近3个月月均支付订单量`
FROM -- 近30天支付用户

     (SELECT user_id,
             sum(payord_num) payord_num
      FROM lastm_order_info
      GROUP BY 1 HAVING sum(payord_num)>=1) a
   LEFT JOIN -- 月均支付订单量

     (SELECT user_id,
             avg(payord_num) avg_payord_num
      FROM
        (SELECT ym,
                user_id,
                sum(payord_num) payord_num
         FROM last90d_order_info
         GROUP BY 1,
                  2) b1
      GROUP BY 1) b ON a.user_id=b.user_id);


-- 用户同品类月均支付订单量
DROP VIEW IF EXISTS user_cate2_payore_num;


CREATE VIEW IF NOT EXISTS user_cate2_payore_num (user_id,sub_category_type,avg_payord_num) AS
  (SELECT a.user_id,
          a.sub_category_type,
          b.avg_payord_num -- `近3个月月均支付订单量`
FROM -- 近30天支付用户

     (SELECT a.user_id,
             b.sub_category_type,
             sum(a.payord_num) payord_num
      FROM lastm_order_info a
      inner JOIN pro_info b ON a.store_promotion_id=b.promotion_id
      GROUP BY 1,
               2 HAVING sum(payord_num)>=1) a
   LEFT JOIN -- 月均支付订单量

     (SELECT user_id,
             sub_category_type,
             avg(payord_num) avg_payord_num
      FROM
        (SELECT ym,
                user_id,
                b.sub_category_type,
                sum(payord_num) payord_num
         FROM last90d_order_info a
         inner JOIN pro_info b ON a.store_promotion_id=b.promotion_id
         GROUP BY 1,
                  2,
                  3) b1
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   AND a.sub_category_type=b.sub_category_type);


-- 近3个月月均支付订单量分布

SELECT '近3个月月均支付订单量' `类型`,
                     count(DISTINCT user_id) `用户量`,
                     min(avg_payord_num) `最小值`,
                     PERCENTILE_CONT(avg_payord_num,0.1) `10分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.2) `20分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.3) `30分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.4) `40分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.5) `50分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.6) `60分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.7) `70分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.8) `80分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.9) `90分位值`,
                     max(avg_payord_num) `最大值`
FROM user_payore_num
GROUP BY 1;


-- 同品类近3个月月均支付订单量分布

SELECT '近3个月月均支付订单量' `类型`,
                     sub_category_type,
                     count(DISTINCT user_id) `用户量`,
                     min(avg_payord_num) `最小值`,
                     PERCENTILE_CONT(avg_payord_num,0.1) `10分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.2) `20分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.3) `30分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.4) `40分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.5) `50分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.6) `60分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.7) `70分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.8) `80分位值`,
                     PERCENTILE_CONT(avg_payord_num,0.9) `90分位值`,
                     max(avg_payord_num) `最大值`
FROM user_cate2_payore_num
GROUP BY 1,
         2;



============== part3 店铺附近3公里内用户重合度
-- 杭州正餐/多人餐、甜品饮品店铺
-- 近30天访问用户数和重合占比，新用户数
DROP VIEW IF EXISTS store_info;


CREATE VIEW IF NOT EXISTS store_info ( store_id,store_name,province_name,city_name,county_name,business_district,address_detail,longitude,latitude,cate2_name) AS
  (SELECT store_id,
          store_name,
          province_name,
          city_name,
          county_name,
          business_district,
          address_detail,
          longitude,
          latitude,
          IF(sub_category_type=8,
             '甜品饮品',
             '正餐/多人餐') cate2_name
   FROM dim.dim_silkworm_explore_store
   WHERE status=1 --正常
     AND city_name='杭州市'
     AND sub_category_type IN (8,
                               11));

-- 近30天访问
DROP VIEW IF EXISTS location_info;


CREATE VIEW IF NOT EXISTS location_info ( user_id,end_lon,end_lat) AS
  (SELECT user_id,
          longitude AS end_lon,
          latitude AS end_lat
   FROM dim.dim_silkworm_user_location
   WHERE date(update_time) BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND city='杭州市' );



-- 到店每日访问用户
DROP VIEW IF EXISTS view_explore_info;


CREATE VIEW IF NOT EXISTS view_explore_info (user_id,end_lon,end_lat) AS (
SELECT a.user_id,
       end_lon,
       end_lat
FROM
  (SELECT unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND event_ename regexp 'StoreDiscovery|Bargain'
     AND substr(county_id,1,4)='3301'
   GROUP BY 1,
            2) a
INNER JOIN location_info b ON a.user_id=b.user_id;


select
    store_id,store_name,province_name,city_name,county_name,business_district,address_detail,cate2_name,
    user_id,
    ST_Distance_Sphere(end_lon, end_lat, longitude, latitude) as distance
from view_explore_info left join store_info on 1=1





-- 最近7天访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
        -- 计算距离经纬度
--         (select longitude as star_lon,
--             latitude as star_lat 
-- from dim.dim_silkworm_explore_store
--         ) b
(select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
union all
select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
union all
select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
) b
    on 1=1
)









