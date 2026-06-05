
-- 用户生命周期
-- 用户属性
DROP VIEW IF EXISTS regis;


CREATE VIEW IF NOT EXISTS regis (register_time,user_id,first_valid_order_date,bet_firstorder_day,latest_login_time,bet_regis_day) AS
  (SELECT register_time,
          user_id,
          date(first_valid_order_time) AS first_valid_order_date,
          (datediff('2026-03-28',date(first_valid_order_time))-1) AS bet_firstorder_day,
          date(latest_login_time) AS latest_login_time,
          (datediff('2026-03-28',date(register_time))-1) AS bet_regis_day
   FROM dim.dim_silkworm_user
   WHERE date(register_time)<='2026-03-28');

-- 用户完单
DROP VIEW IF EXISTS t_orders;


CREATE VIEW IF NOT EXISTS t_orders (user_id,order_id,order_date) AS
  (SELECT user_id,
          order_id,
          date(order_audit_finish_time) AS order_date
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt<'2026-03-28'
     AND order_status IN (2,
                          8));
-- 用户属性+完单
DROP VIEW IF EXISTS t_all;


CREATE VIEW IF NOT EXISTS t_all (user_id,order_user_id,register_time,first_valid_order_date,bet_firstorder_day,bet_regis_day,16day_orders,recent7day_orders,recent8_21day_orders,recent21_orders,recent30_orders) AS
  (SELECT r.user_id,
          t.user_id AS order_user_id,
          register_time,
          first_valid_order_date,
          bet_firstorder_day,
          bet_regis_day,
          count(DISTINCT if(datediff(order_date,first_valid_order_date) BETWEEN 0 AND 15,t.order_id,NULL)) 16day_orders,
          count(DISTINCT if(datediff('2026-03-28',order_date) BETWEEN 1 AND 7,t.order_id,NULL)) recent7day_orders,
          count(DISTINCT if(datediff('2026-03-28',order_date) BETWEEN 8 AND 21,t.order_id,NULL)) recent8_21day_orders,
          count(DISTINCT if(datediff('2026-03-28',order_date) BETWEEN 1 AND 21,t.order_id,NULL)) recent21_orders,
          count(DISTINCT if(datediff('2026-03-28',order_date) BETWEEN 1 AND 30,t.order_id,NULL)) recent30_orders
   FROM regis r
   LEFT JOIN t_orders t ON r.user_id=t.user_id
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6);

-- 用户城市
DROP VIEW IF EXISTS t_city;


CREATE VIEW IF NOT EXISTS t_city (city_name,user_id) AS
  (SELECT city_name,
          user_id
   FROM dwd.dwd_silkworm_user_feature_data
   WHERE city_name<>'未知');


-- 昨日访问用户
DROP VIEW IF EXISTS t_log;


CREATE VIEW IF NOT EXISTS t_log (user_id,event_date) AS
  (SELECT unnest_bitmap AS user_id,
          statistics_date AS event_date
   FROM
     (SELECT statistics_date,
             view_uids
      FROM dws.dws_sr_user_login_d
      WHERE statistics_date = '2026-03-28') t,unnest_bitmap(view_uids)
   GROUP BY 1,
            2);


-- 用户打标 某一个时间点所处的生命周期阶段
DROP VIEW IF EXISTS t_detail;


CREATE VIEW IF NOT EXISTS t_detail (user_id,city_name,if_login,order_user_id,register_time, first_valid_order_date, bet_firstorder_day, bet_regis_day, 16day_orders, recent7day_orders, recent8_21day_orders, recent21_orders,user_type) AS
  (SELECT t1.user_id,
          coalesce(t2.city_name,'未知') AS city_name,
          if(t3.user_id IS NOT NULL,'访问','未访问') AS if_login,
          order_user_id,
          register_time,
          first_valid_order_date,
          bet_firstorder_day,
          bet_regis_day,
          16day_orders,
          recent7day_orders,
          recent8_21day_orders,
          recent21_orders,
          CASE
              WHEN bet_regis_day<9
                   AND order_user_id IS NULL THEN '导入期'
              WHEN bet_regis_day>=9
                   AND order_user_id IS NULL THEN '流失期'
              WHEN bet_firstorder_day<17
                   AND 16day_orders BETWEEN 1 AND 4
                   AND recent7day_orders>0 THEN '成长期'
              WHEN bet_firstorder_day<17
                   AND 16day_orders >4
                   AND recent7day_orders>0 THEN '稳定期'
              WHEN bet_firstorder_day>=17
                   AND recent7day_orders>0 THEN '稳定期'
              WHEN recent7day_orders=0
                   AND recent8_21day_orders>0 THEN '休眠期'
              WHEN (first_valid_order_date>'2000-01-01'
                    OR (first_valid_order_date='1970-01-01'
                        AND order_user_id IS NOT NULL))
                   AND recent21_orders=0 THEN '流失期'
              ELSE '其他'
          END AS user_type
   FROM t_all t1
   LEFT JOIN t_city t2 ON t1.user_id=t2.user_id
   LEFT JOIN t_log t3 ON t1.user_id=t3.user_id);


-- 第一部分 首页流量转化
-- 首页流量解析
DROP VIEW IF EXISTS origin_traffic_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (time,event,county_id,activity_id,uid,platform_name,app_version,distance,activity_type,user_id) AS
  (SELECT time,
          event,
          get_json_string(properties,'$.city') AS county_id,
          get_json_string(properties,'$.activity_id') AS activity_id,
          get_json_string(properties,'$.user_id') AS uid,
          get_json_string(properties,'$.platform_type') AS platform_name,
          get_json_string(properties,'$.$app_version') AS app_version,
          get_json_string(properties,'$.distance') AS distance,
          get_json_string(properties,'$.activity_type') AS activity_type,
          distinct_id AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date(time)='2026-03-28'
     AND event IN ('Homepage_Feed_Activity_Ex',
                   'Homepage_Feed_Activity_Click'
                   )
    AND distinct_id regexp '^[0-9]{1,10}$');

-- 清洗首页流量数据
DROP VIEW IF EXISTS base_traffic_info;


CREATE VIEW IF NOT EXISTS base_traffic_info (time,event,county_id,activity_id,uid,platform_name,app_version,activity_type,user_id,user_distance) AS
  (SELECT time,
          event,
          CASE
              WHEN county_id IS NULL
                   OR county_id='0'
                   OR county_id=''
                   OR county_id='null' THEN 0
              ELSE cast(county_id AS int)
          END AS county_id,
          CASE
              WHEN activity_id regexp '^[0-9]{1,8}$' THEN cast(activity_id AS int)
              ELSE 0
          END activity_id,
              uid,
              CASE
                  WHEN platform_name regexp '5' THEN 'H5'
                  WHEN platform_name regexp '小程序' THEN '微信小程序'
                  WHEN platform_name IN ('Android',
                                         'Harmony') THEN 'Android'
                  WHEN platform_name='iOS' THEN 'iOS'
              END platform_name,
                  if(app_version IS NULL,'未知',app_version) app_version,
                                                           CASE
                                                               WHEN activity_type IS NULL
                                                                    OR activity_type='' THEN '小蚕活动'
                                                               WHEN activity_type='站内活动' THEN '小蚕活动'
                                                               WHEN activity_type regexp '美团专版' THEN '美团专版'
                                                               ELSE activity_type
                                                           END activity_type,
                                                               user_id,
                                                               CASE
                                                                   WHEN distance IS NULL
                                                                        OR distance<=0 THEN '未知'
                                                                   WHEN distance>0
                                                                        AND distance<=1000 THEN '1公里内'
                                                                   WHEN distance>1000
                                                                        AND distance<=3000 THEN '1-3公里内'
                                                                   WHEN distance>3000
                                                                        AND distance<=5000 THEN '3-5公里内'
                                                                   WHEN distance>5000
                                                                        AND distance<=10000 THEN '5-10公里内'
                                                                   WHEN distance>10000
                                                                        AND distance<=15000 THEN '10-15公里内'
                                                                   WHEN distance>15000
                                                                        AND distance<=20000 THEN '15-20公里内'
                                                                   WHEN distance>20000 THEN '20公里以上'
                                                               END AS user_distance             
   FROM origin_traffic_info
   WHERE (platform_name IS NOT NULL
          OR platform_name<>'') );


-- 得到活动信息
DROP VIEW IF EXISTS traffic_info;


CREATE VIEW IF NOT EXISTS traffic_info (time, event, county_id, activity_id, uid, platform_name, app_version, activity_type, user_id,is_brand, mlabel_threshold_amt, mlabel_rebate_amt, mlabel, rebate_rate,store_platform,user_type,user_distance) AS
  (SELECT a.time,
          a.event,
          a.county_id,
          a.activity_id,
          a.uid,
          a.platform_name,
          a.app_version,
          ifnull(a.activity_type,'其他') activity_type,
          a.user_id,
          ifnull(b.store_brand_type,0) is_brand,
          ifnull(b.mlabel_threshold_amt,0) mlabel_threshold_amt,
          ifnull(b.mlabel_rebate_amt,0) mlabel_rebate_amt,
          ifnull(b.mlabel,0) mlabel,
          ifnull(b.rebate_rate,0) rebate_rate,
          ifnull(b.store_platform,'未知') store_platform,
          ifnull(c.user_type,'未知') user_type,
          a.user_distance
   FROM base_traffic_info a
   LEFT JOIN
     (SELECT promotion_id,
             store_brand_type,
             mlabel_threshold_amt,
             mlabel_rebate_amt,
             mlabel,
             if(mlabel_threshold_amt IS NULL
                OR mlabel_threshold_amt=0,0,mlabel_rebate_amt/mlabel_threshold_amt) AS rebate_rate,
             store_platform
      FROM dws.dws_sr_store_takeawaypro_statis_d
      WHERE dt BETWEEN date_sub('2026-03-28',interval 30 DAY) AND '2026-03-28') b ON a.activity_id=b.promotion_id
     left join t_detail c on a.user_id=c.user_id);


select
toa.*,tob.*
from
(SELECT 
       county_id,
       activity_id,
       platform_name,
       app_version,
       activity_type,
       store_platform,
       is_brand,
       CASE
           WHEN hand_price BETWEEN 0 AND 5 THEN '5元以内'
           WHEN hand_price>5
                AND hand_price<=10 THEN '5-10元'
           WHEN hand_price>10
                AND hand_price<=15 THEN '10-15元'
           WHEN hand_price>15
                AND hand_price<=20 THEN '15-20元'
           WHEN hand_price>20
                AND hand_price<=25 THEN '20-25元'
           WHEN hand_price>25
                AND hand_price<=30 THEN '25-30元'
           WHEN hand_price>30 THEN '30元以上'
           ELSE '未知'
       END '到手价区间',
           CASE
               WHEN rebate_rate>=0
                    AND rebate_rate<=0.1 THEN '10%以内'
               WHEN rebate_rate>0.1
                    AND rebate_rate<=0.3 THEN '10-30%'
               WHEN rebate_rate>0.3
                    AND rebate_rate<=0.5 THEN '30-50%'
               WHEN rebate_rate>0.5
                    AND rebate_rate<=0.6 THEN '50-60%'
               WHEN rebate_rate>0.6
                    AND rebate_rate<=0.7 THEN '60-70%'
               WHEN rebate_rate>0.7
                    AND rebate_rate<=0.8 THEN '70-80%'
               WHEN rebate_rate>0.8 THEN '80%以上'
               ELSE '未知'
           END '返现比例区间',
               user_distance,
               user_type,
               sum(expouse_num) expouse_num,
               bitmap_union_count(expouse_uids) expouse_uv
FROM
  (SELECT date(time) AS statistics_date,
          county_id,
          activity_id,
          platform_name,
          app_version,
          activity_type,
          store_platform,
          is_brand,
          if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
          rebate_rate,
          user_distance,
          user_type,
          COUNT(*) AS expouse_num,
          bitmap_agg(user_id) AS expouse_uids
   FROM traffic_info
   WHERE event = 'Homepage_Feed_Activity_Ex'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12) a
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12) toa
left join
(SELECT 
       county_id,
       activity_id,
       platform_name,
       app_version,
       activity_type,
       store_platform,
       is_brand,
       CASE
           WHEN hand_price BETWEEN 0 AND 5 THEN '5元以内'
           WHEN hand_price>5
                AND hand_price<=10 THEN '5-10元'
           WHEN hand_price>10
                AND hand_price<=15 THEN '10-15元'
           WHEN hand_price>15
                AND hand_price<=20 THEN '15-20元'
           WHEN hand_price>20
                AND hand_price<=25 THEN '20-25元'
           WHEN hand_price>25
                AND hand_price<=30 THEN '25-30元'
           WHEN hand_price>30 THEN '30元以上'
           ELSE '未知'
       END '到手价区间',
           CASE
               WHEN rebate_rate>=0
                    AND rebate_rate<=0.1 THEN '10%以内'
               WHEN rebate_rate>0.1
                    AND rebate_rate<=0.3 THEN '10-30%'
               WHEN rebate_rate>0.3
                    AND rebate_rate<=0.5 THEN '30-50%'
               WHEN rebate_rate>0.5
                    AND rebate_rate<=0.6 THEN '50-60%'
               WHEN rebate_rate>0.6
                    AND rebate_rate<=0.7 THEN '60-70%'
               WHEN rebate_rate>0.7
                    AND rebate_rate<=0.8 THEN '70-80%'
               WHEN rebate_rate>0.8 THEN '80%以上'
               ELSE '未知'
           END '返现比例区间',
               user_distance,
               user_type,
               sum(clc_num) clc_num,
               bitmap_union_count(clc_uids) clc_uv
FROM
  (SELECT date(time) AS statistics_date,
          county_id,
          activity_id,
          platform_name,
          app_version,
          activity_type,
          store_platform,
          is_brand,
          if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
          rebate_rate,
          user_distance,
          user_type,
          COUNT(*) AS clc_num,
          bitmap_agg(user_id) AS clc_uids
   FROM traffic_info
   WHERE event = 'Homepage_Feed_Activity_Click'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12) a
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12) tob ON a.county_id = b.county_id
   AND a.activity_id = b.activity_id
   AND a.platform_name = b.platform_name
   AND a.app_version = b.app_version
   AND a.activity_type = b.activity_type
   AND a.store_platform = b.store_platform
   AND a.is_brand = b.is_brand
   AND a.user_distance = b.user_distance
   AND a.user_type = b.user_type
   AND a.hand_price = b.hand_price;

