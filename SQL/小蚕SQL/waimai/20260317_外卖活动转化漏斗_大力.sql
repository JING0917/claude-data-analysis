--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2026-03-19 15:49:13

-- modifytime: 2026-03-25 09:45:36, author: dahe, comment: 新增城市ID、城市名称、区县名称字段 activity_type 站内活动转为小蚕活动
--******************************************************************--

drop table if exists dws.dws_sr_traffic_takeawaypro_funnel_d;

CREATE TABLE if not exists dws.dws_sr_traffic_takeawaypro_funnel_d (
  statistics_date date not null comment '统计日期',
  traffic_source varchar(20) comment '流量来源(首页/搜索feed)',
  city_id int comment '城市ID',
  city_name varchar(50) comment '城市名称',
  county_id int not null comment '区县ID',
  county_name varchar(50) comment '区县名称',
  platform_name varchar(20) not null comment '平台名称',
  app_version varchar(20) not null comment '版本',
  activity_type varchar(20) not null comment '活动类型',
  promotion_id int not null comment '活动ID',
  store_platform varchar(20) comment '店铺平台名称',
  is_brand int comment '是否大牌活动',
  hand_price varchar(20) comment '到手价',
  rebate_rate varchar(20) comment '返现比例',
  user_distance varchar(20) comment '用户距离区间(活动曝光时用户距离)',
  user_lifecycle varchar(20) comment '用户生命周期',
  expouse_num bigint comment '曝光量',
  expouse_uids bitmap comment '曝光用户列表',
  clc_num bigint comment '点击量',
  clc_uids bitmap comment '点击用户列表',
  baoming_order_num bigint comment '报名订单量',
  baoming_uids bitmap comment '报名用户列表',
  valid_order_num bigint comment '有效订单量',
  valid_uids bitmap comment '有效用户列表'
)
ENGINE=OLAP
PRIMARY KEY (statistics_date,traffic_source,city_id,city_name,county_id,county_name,platform_name,
                app_version,activity_type,promotion_id,store_platform,is_brand,hand_price,rebate_rate,
                user_distance,user_lifecycle)
COMMENT "外卖活动日转化漏斗"
DISTRIBUTED BY HASH(statistics_date,county_id,promotion_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);


-- 用户生命周期
-- 用户属性
DROP VIEW IF EXISTS regis;


CREATE VIEW IF NOT EXISTS regis (register_time,user_id,first_valid_order_date,bet_firstorder_day,latest_login_time,bet_regis_day) AS
  (SELECT register_time,
          user_id,
          date(first_valid_order_time) AS first_valid_order_date,
          (datediff('${T-1}',date(first_valid_order_time))-1) AS bet_firstorder_day,
          date(latest_login_time) AS latest_login_time,
          (datediff('${T-1}',date(register_time))-1) AS bet_regis_day
   FROM dim.dim_silkworm_user
   WHERE date(register_time)<='${T-1}');

-- 用户完单
DROP VIEW IF EXISTS t_orders;


CREATE VIEW IF NOT EXISTS t_orders (user_id,order_id,order_date) AS
  (SELECT user_id,
          order_id,
          date(order_audit_finish_time) AS order_date
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt<'${T-1}'
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
          count(DISTINCT if(datediff('${T-1}',order_date) BETWEEN 1 AND 7,t.order_id,NULL)) recent7day_orders,
          count(DISTINCT if(datediff('${T-1}',order_date) BETWEEN 8 AND 21,t.order_id,NULL)) recent8_21day_orders,
          count(DISTINCT if(datediff('${T-1}',order_date) BETWEEN 1 AND 21,t.order_id,NULL)) recent21_orders,
          count(DISTINCT if(datediff('${T-1}',order_date) BETWEEN 1 AND 30,t.order_id,NULL)) recent30_orders
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
      WHERE statistics_date = '${T-1}') t,unnest_bitmap(view_uids)
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
   WHERE date(time)='${T-1}'
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
      WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}') b ON a.activity_id=b.promotion_id
     left join t_detail c on a.user_id=c.user_id);


-- 外卖订单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (create_time,store_promotion_id,user_id,auto_id,order_time,order_id,order_status,order_type,profit) AS
  (SELECT create_time,
             store_promotion_id,
             user_id,
             auto_id,
             order_time,
             order_id,
             order_status,
             order_type,
             profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub('${T-1}',interval 1 DAY) AND '${T-1}');


-- 造出首页feed流转化漏斗数据集并统计指标
DROP VIEW IF EXISTS sy_feed_info;


CREATE VIEW IF NOT EXISTS sy_feed_info (statistics_date, county_id, activity_id, platform_name, app_version, activity_type, store_platform, is_brand,hand_price, rebate_rate, user_distance, user_type, expouse_num,expouse_uids,clc_num,clc_uids,baoming_order_num,baoming_uids,valid_order_num,valid_uids) AS
(SELECT 
    a.statistics_date,
    a.county_id,
    a.activity_id,
    a.platform_name,
    a.app_version,
    a.activity_type,
    a.store_platform,
    a.is_brand,
    a.hand_price,
    a.rebate_rate,
    a.user_distance,
    a.user_type,
    a.expouse_num,
    a.expouse_uids,
    COALESCE(b.clc_num, 0) as clc_num,
    COALESCE(b.clc_uids, bitmap_empty()) as clc_uids,
    COALESCE(c.baoming_order_num, 0) as baoming_order_num,
    COALESCE(c.baoming_uids, bitmap_empty()) as baoming_uids,
    COALESCE(c.valid_order_num, 0) as valid_order_num,
    COALESCE(c.valid_uids, bitmap_empty()) as valid_uids
FROM (
    -- 独立曝光统计
    SELECT date(time) as statistics_date,
           county_id,
           activity_id,
           platform_name,
           app_version,
           activity_type,
           store_platform,
           is_brand,
           if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) as hand_price,
           rebate_rate,
           user_distance,
           user_type,
           COUNT(*) as expouse_num,
           bitmap_agg(user_id) as expouse_uids
    FROM traffic_info
    WHERE event = 'Homepage_Feed_Activity_Ex'
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
) a
LEFT JOIN (
    -- 点击统计
    SELECT date(time) as statistics_date,
           county_id,
           activity_id,
           platform_name,
           app_version,
           activity_type,
           store_platform,
           is_brand,
           if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) as hand_price,
           rebate_rate,
           user_distance,
           user_type,
           COUNT(*) as clc_num,
           bitmap_agg(user_id) as clc_uids
    FROM traffic_info
    WHERE event = 'Homepage_Feed_Activity_Click'
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
) b ON a.statistics_date = b.statistics_date
   AND a.county_id = b.county_id
   AND a.activity_id = b.activity_id
   AND a.platform_name = b.platform_name
   AND a.app_version = b.app_version
   AND a.activity_type = b.activity_type
   AND a.store_platform = b.store_platform
   AND a.is_brand = b.is_brand
   AND a.user_distance = b.user_distance
   AND a.user_type = b.user_type
   AND a.hand_price = b.hand_price
   AND a.rebate_rate = b.rebate_rate
LEFT JOIN (
    -- 订单统计（基于点击用户）
    SELECT date(b.time) as statistics_date,
           b.county_id,
           b.activity_id,
           b.platform_name,
           b.app_version,
           b.activity_type,
           b.store_platform,
           b.is_brand,
           b.hand_price,
           b.rebate_rate,
           b.user_distance,
           b.user_type,
           COUNT(DISTINCT c.auto_id) as baoming_order_num,
           bitmap_agg(c.user_id) as baoming_uids,
           COUNT(DISTINCT CASE WHEN c.order_status IN (2,8) THEN c.auto_id END) as valid_order_num,
           bitmap_agg(CASE WHEN c.order_status IN (2,8) THEN c.user_id END) as valid_uids
    FROM (
        SELECT time, county_id, activity_id, platform_name, app_version, 
               activity_type, store_platform, is_brand,if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) as hand_price,
               rebate_rate,user_distance, user_type, user_id
        FROM traffic_info
        WHERE event = 'Homepage_Feed_Activity_Click'
    ) b
    LEFT JOIN order_info c ON b.user_id = c.user_id
        AND date_diff('minute', date_format(c.create_time,'%Y-%m-%d %H:%i:%s'),date_format(b.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 15
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
) c ON b.statistics_date = c.statistics_date
   AND b.county_id = c.county_id
   AND b.activity_id = c.activity_id
   AND b.platform_name = c.platform_name
   AND b.app_version = c.app_version
   AND b.activity_type = c.activity_type
   AND b.store_platform = c.store_platform
   AND b.is_brand = c.is_brand
   AND b.user_distance = c.user_distance
   AND b.user_type = c.user_type
   AND b.hand_price = c.hand_price
   AND b.rebate_rate = c.rebate_rate);




-- -- 造出首页feed流转化漏斗数据集并统计指标
-- DROP VIEW IF EXISTS sy_feed_info;


-- CREATE VIEW IF NOT EXISTS sy_feed_info (statistics_date, county_id, activity_id, platform_name, app_version, activity_type, store_platform, is_brand,hand_price, rebate_rate, user_distance, user_type, expouse_num,expouse_uids,clc_num,clc_uids,baoming_order_num,baoming_uids,valid_order_num,valid_uids) AS
--   (SELECT date(a.time) statistics_date,
--                        a.county_id,
--                        a.activity_id,
--                        a.platform_name,
--                        a.app_version,
--                        a.activity_type,
--                        a.store_platform,
--                        a.is_brand,
--                        if(a.mlabel_threshold_amt=0,a.mlabel_rebate_amt,a.mlabel_threshold_amt-a.mlabel_rebate_amt) AS hand_price,
--                        a.rebate_rate,
--                        a.user_distance,
--                        a.user_type,
--                        sum(a.bg_num) expouse_num,
--                        bitmap_agg(a.user_id) expouse_uids,
--                        sum(if(b.user_id is not null,b.clc_num,0)) clc_num,
--                        bitmap_agg(if(b.user_id is not null,a.user_id,null)) clc_uids,
--                        count(distinct c.auto_id) baoming_order_num,
--                        bitmap_agg(if(c.user_id is not null,b.user_id,null)) baoming_uids,
--                        count(distinct if(c.order_status in (2,8),c.auto_id,null)) valid_order_num,
--                        bitmap_agg(if(c.order_status in (2,8),b.user_id,null)) valid_uids
--    FROM
--      (SELECT time,
--              county_id,
--              activity_id,
--              platform_name,
--              app_version,
--              activity_type,
--              user_id,
--              is_brand,
--              mlabel_threshold_amt,
--              mlabel_rebate_amt,
--              mlabel,
--              rebate_rate,
--              store_platform,
--              user_type,
--              user_distance,
--              count(1) bg_num
--       FROM traffic_info
--       WHERE event='Homepage_Feed_Activity_Ex'
--       group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15) a
--    LEFT JOIN
--      (SELECT time,
--              county_id,
--              activity_id,
--              platform_name,
--              app_version,
--              activity_type,
--              user_id,
--              count(1) clc_num
--       FROM traffic_info
--       WHERE event='Homepage_Feed_Activity_Click'
--       group by 1,2,3,4,5,6,7) b ON date_diff('second',b.time,a.time) BETWEEN 0 AND 5
--    AND a.county_id=b.county_id
--    AND a.activity_type=b.activity_type
--    AND a.activity_id=b.activity_id
--    AND a.platform_name=b.platform_name
--    AND a.app_version=b.app_version
--    AND a.user_id=b.user_id
--    LEFT JOIN order_info c ON c.user_id=b.user_id
--    AND date_diff('minute',c.create_time,b.time) BETWEEN 0 AND 15
--    GROUP BY 1,
--             2,
--             3,
--             4,
--             5,
--             6,
--             7,
--             8,
--             9,
--             10,
--             11,
--             12);



-- 第二部分 搜索流量转化
-- 搜索数据解析
DROP VIEW IF EXISTS origin_se_traffic_info;


CREATE VIEW IF NOT EXISTS origin_se_traffic_info (time,event,entrance_name, search_method, county_id, location, activity_id, keywords, platform_name, app_version, distance, activity_type,user_id) AS
  (SELECT time,
          event,
          get_json_string(properties,'$.entrance') AS entrance_name,
          get_json_string(properties,'$.search_method') AS search_method,
          get_json_string(properties,'$.city') AS county_id,
          get_json_string(properties,'$.position') AS location,
          get_json_string(properties,'$.activity_id') AS activity_id,
          get_json_string(properties,'$.query_word') AS keywords,
          get_json_string(properties,'$.platform_type') AS platform_name,
          get_json_string(properties,'$.$app_version') AS app_version,
          get_json_string(properties,'$.distance') AS distance,
          get_json_string(properties,'$.activity_type') AS activity_type,
          distinct_id AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='${T-1}'
     AND event IN ( 'Search_Result_Ex',
                    'Search_Result_Click')
     AND distinct_id regexp '^[0-9]{1,10}$');

-- 清洗t数据集 转换null值 剔除空等
DROP VIEW IF EXISTS base_se_traffic_info;


CREATE VIEW IF NOT EXISTS base_se_traffic_info (time, event, entrance_name, search_method, county_id, app_version, platform_name, activity_type, keywords, location, activity_id, user_id, user_distance) AS
  (SELECT time,
          event,
          CASE
              WHEN entrance_name IN ('首页',
                                     '主页') THEN '首页'
              WHEN entrance_name IS NULL THEN '其他'
              ELSE entrance_name
          END AS entrance_name,
          search_method,
          CASE
              WHEN county_id IS NULL
                   OR county_id='0'
                   OR county_id=''
                   OR county_id='null' THEN 0
              ELSE cast(county_id AS int)
          END AS county_id,
          if(app_version IS NULL,'未知',app_version) app_version,
                                                   CASE
                                                       WHEN platform_name regexp '5' THEN 'H5'
                                                       WHEN platform_name regexp '小程序' THEN '微信小程序'
                                                       WHEN platform_name IN ('Android',
                                                                              'Harmony') THEN 'Android'
                                                       WHEN platform_name='iOS' THEN 'iOS'
                                                   END platform_name,
                                                       CASE
                                                           WHEN activity_type IS NULL
                                                                OR activity_type='' THEN '小蚕活动'
                                                           WHEN activity_type='站内活动' THEN '小蚕活动'
                                                           WHEN activity_type regexp '美团专版' THEN '美团专版'
                                                           ELSE activity_type
                                                       END activity_type,
                                                           keywords,
                                                           location,
                                                           CASE
                                                               WHEN activity_id regexp '^[0-9]{1,8}$' THEN cast(activity_id AS int)
                                                               ELSE 0
                                                           END activity_id,
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
   FROM origin_se_traffic_info
   WHERE keywords IS NOT NULL
     AND keywords<>''
     AND (platform_name IS NOT NULL
          OR platform_name<>''));


-- 得到活动信息
DROP VIEW IF EXISTS se_traffic_info;


CREATE VIEW IF NOT EXISTS se_traffic_info (time, event, entrance_name, search_method, county_id, activity_id, platform_name, app_version, activity_type, keywords, location, user_id, is_brand, mlabel_threshold_amt, mlabel_rebate_amt, mlabel, rebate_rate, store_platform, user_type, user_distance) AS
  (SELECT a.time,
          a.event,
          a.entrance_name,
          a.search_method,
          a.county_id,
          a.activity_id,
          a.platform_name,
          a.app_version,
          ifnull(a.activity_type,'其他') activity_type,
          a.keywords,
          a.location,
          a.user_id,
          ifnull(b.store_brand_type,0) is_brand,
          ifnull(b.mlabel_threshold_amt,0) mlabel_threshold_amt,
          ifnull(b.mlabel_rebate_amt,0) mlabel_rebate_amt,
          ifnull(b.mlabel,0) mlabel,
          ifnull(b.rebate_rate,0) rebate_rate,
          ifnull(b.store_platform,'未知') store_platform,
          ifnull(c.user_type,'未知') user_type,
          a.user_distance
   FROM base_se_traffic_info a
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
 WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}') b ON a.activity_id=b.promotion_id
   LEFT JOIN t_detail c ON a.user_id=c.user_id);


-- 最近一次外卖订单
DROP VIEW IF EXISTS latest_order_info;


CREATE VIEW IF NOT EXISTS latest_order_info (store_promotion_id, user_id, auto_id, order_time, order_id, order_type, order_status, profit, redpacket_amt) AS
  (SELECT store_promotion_id,
          user_id,
          auto_id,
          order_time,
          order_id,
          order_type,
          order_status,
          profit,
          redpacket_amt
   FROM
     (SELECT store_promotion_id,
             user_id,
             auto_id,
             order_time,
             order_id,
             order_type,
             order_status,
             profit,
             redpacket_amt,
             row_number() over(partition BY user_id,store_promotion_id
                               ORDER BY order_time DESC) rk
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub('${T-1}',interval 1 DAY) AND '${T-1}' ) a
   WHERE rk=1);



-- 最近一次搜索结果点击
DROP VIEW IF EXISTS latest_clc_info;


CREATE VIEW IF NOT EXISTS latest_clc_info (time, entrance_name, search_method, county_id, user_id, location, activity_id, keywords, platform_name, app_version, activity_type,is_brand,hand_price,rebate_rate,store_platform,user_type,user_distance) AS
  (SELECT time,
          entrance_name,
          search_method,
          county_id,
          user_id,
          location,
          activity_id,
          keywords,
          platform_name,
          app_version,
          activity_type,
          is_brand,
          hand_price,
          rebate_rate,
          store_platform,
          user_type,
          user_distance
   FROM
     (SELECT time,
             entrance_name,
             search_method,
             county_id,
             user_id,
             location,
             activity_id,
             keywords,
             platform_name,
             app_version,
             activity_type,
             is_brand,
             if(mlabel_threshold_amt=0,mlabel_rebate_amt,mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
             rebate_rate,
             store_platform,
             user_type,
             user_distance,
             row_number() over(partition BY entrance_name,search_method,county_id,user_id,activity_type,keywords,store_platform,user_distance
                               ORDER BY time DESC) rk
      FROM se_traffic_info
      WHERE entrance_name IN ('首页',
                              '主页')
        AND event='Search_Result_Click') a
   WHERE rk=1);



-- 搜索订单归因数据集
DROP VIEW IF EXISTS se_order_result;


CREATE VIEW IF NOT EXISTS se_order_result (statistics_date, entrance_name, search_method, county_id, activity_id, platform_name, app_version, activity_type, location, keywords, is_brand,hand_price,rebate_rate,store_platform,user_type,user_distance,baoming_order_num, baoming_uids, valid_order_num, valid_uids) AS
  (SELECT date(a.time) statistics_date,
          a.entrance_name,
          a.search_method,
          a.county_id,
          a.activity_id,
          a.platform_name,
          a.app_version,
          a.activity_type,
          a.location,
          a.keywords,
          a.is_brand,
          a.hand_price,
          a.rebate_rate,
          a.store_platform,
          a.user_type,
          a.user_distance,
          count(DISTINCT b.auto_id) baoming_order_num,
          bitmap_agg(b.user_id) baoming_uids,
          count(DISTINCT if(b.order_status IN (2,8),b.auto_id,NULL)) valid_order_num,
          bitmap_agg(if(b.order_status IN (2,8),b.user_id,null)) valid_uids
   FROM latest_clc_info a
   LEFT JOIN latest_order_info b ON a.user_id=b.user_id
   AND date_diff('second',date_format(b.order_time,'%Y-%m-%d %H:%i:%s'),date_format(a.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 30
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,11,12,13,14,15,16);


-- 造出搜索feed流转化漏斗数据集并统计指标
DROP VIEW IF EXISTS se_feed_info;


CREATE VIEW IF NOT EXISTS se_feed_info (statistics_date, county_id, activity_id, platform_name, app_version, activity_type, store_platform, is_brand, hand_price, rebate_rate, user_distance, user_type, expouse_num, expouse_uids, clc_num, clc_uids, baoming_order_num, baoming_uids, valid_order_num, valid_uids) AS
  (SELECT              a.statistics_date,
                       a.county_id,
                       a.activity_id,
                       a.platform_name,
                       a.app_version,
                       a.activity_type,
                       a.store_platform,
                       a.is_brand,
                       a.hand_price,
                       a.rebate_rate,
                       a.user_distance,
                       a.user_type,
                       sum(a.expouse_num) expouse_num,
                       bitmap_union(a.expouse_uids) expouse_uids,
                       sum(COALESCE(b.clc_num, 0)) as clc_num,
                       bitmap_union(COALESCE(b.clc_uids, bitmap_empty())) as clc_uids,
                       sum(COALESCE(c.baoming_order_num, 0)) as baoming_order_num,
                       bitmap_union(COALESCE(c.baoming_uids, bitmap_empty())) as baoming_uids,
                       sum(COALESCE(c.valid_order_num, 0)) as valid_order_num,
                       bitmap_union(COALESCE(c.valid_uids, bitmap_empty())) as valid_uids
   FROM
     (SELECT date(time) statistics_date,
             county_id,
             activity_id,
             platform_name,
             app_version,
             activity_type,
             is_brand,
             if(mlabel_threshold_amt=0,mlabel_rebate_amt,mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
             rebate_rate,
             store_platform,
             user_type,
             user_distance,
             entrance_name,
             search_method,
             keywords,
             location,
             count(1) expouse_num,
             bitmap_agg(user_id) expouse_uids
      FROM se_traffic_info
      WHERE event='Search_Result_Ex' 
          AND entrance_name IN ('首页',
                                '主页')
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
      ) a 
   LEFT JOIN
     (SELECT date(time) statistics_date,
             county_id,
             activity_id,
             platform_name,
             app_version,
             activity_type,
             is_brand,
             if(mlabel_threshold_amt=0,mlabel_rebate_amt,mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
             rebate_rate,
             store_platform,
             user_type,
             user_distance,
             entrance_name,
             search_method,
             keywords,
             location,
             count(1) clc_num,
             bitmap_agg(user_id) clc_uids
      FROM se_traffic_info
      WHERE event='Search_Result_Click'
          AND entrance_name IN ('首页',
                                '主页')
        group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16) b ON a.entrance_name=b.entrance_name
   AND a.search_method=b.search_method
   AND a.keywords=b.keywords
   AND a.location=b.location   
   AND a.county_id=b.county_id
   AND a.activity_type=b.activity_type
   AND a.activity_id=b.activity_id
   AND a.platform_name=b.platform_name
   AND a.app_version=b.app_version
   AND a.statistics_date=b.statistics_date
   AND a.is_brand=b.is_brand
   AND a.hand_price=b.hand_price
   AND a.rebate_rate=b.rebate_rate
   AND a.store_platform=b.store_platform
   AND a.user_type=b.user_type
   AND a.user_distance=b.user_distance
   LEFT JOIN
     (SELECT statistics_date,
             entrance_name,
             search_method,
             county_id,
             activity_id,
             platform_name,
             app_version,
             activity_type,
             location,
             keywords,
             is_brand,
             hand_price,
             rebate_rate,
             store_platform,
             user_type,
             user_distance,
             baoming_order_num,
             baoming_uids, 
             valid_order_num,
             valid_uids
      FROM se_order_result) c ON c.statistics_date=b.statistics_date
   AND c.entrance_name=b.entrance_name  
   AND c.search_method=b.search_method
   AND c.county_id=b.county_id
   AND c.activity_type=b.activity_type
   AND c.activity_id=b.activity_id  
   AND c.platform_name=b.platform_name
   AND c.keywords=b.keywords
   AND c.location=b.location  
   AND c.app_version=b.app_version
   AND c.is_brand=b.is_brand
   AND c.hand_price=b.hand_price
   AND c.rebate_rate=b.rebate_rate
   AND c.store_platform=b.store_platform
   AND c.user_type=b.user_type
   AND c.user_distance=b.user_distance
group by 1,2,3,4,5,6,7,8,9,10,11,12);


-- -- 造出搜索feed流转化漏斗数据集并统计指标
-- DROP VIEW IF EXISTS se_feed_info;


-- CREATE VIEW IF NOT EXISTS se_feed_info (statistics_date, county_id, activity_id, platform_name, app_version, activity_type, store_platform, is_brand, hand_price, rebate_rate, user_distance, user_type, expouse_num, expouse_uids, clc_num, clc_uids, baoming_order_num, baoming_uids, valid_order_num, valid_uids) AS
--   (SELECT date(a.time) statistics_date,
--                        a.county_id,
--                        a.activity_id,
--                        a.platform_name,
--                        a.app_version,
--                        a.activity_type,
--                        a.store_platform,
--                        a.is_brand,
--                        if(a.mlabel_threshold_amt=0,a.mlabel_rebate_amt,a.mlabel_threshold_amt-a.mlabel_rebate_amt) AS hand_price,
--                        a.rebate_rate,
--                        a.user_distance,
--                        a.user_type,
--                        sum(a.bg_num) expouse_num,
--                        bitmap_agg(a.user_id) expouse_uids,
--                        sum(if(b.user_id is not null,b.clc_num,0)) clc_num,
--                        bitmap_agg(if(b.user_id is not null,a.user_id,null)) clc_uids,
--                        sum(if(c.user_id is not null,c.baoming_order_num,0)) baoming_order_num,
--                        bitmap_agg(if(c.baoming_order_num is not null,a.user_id,null)) baoming_uids,
--                        sum(if(c.user_id is not null,c.valid_order_num,0)) valid_order_num,
--                        bitmap_agg(if(c.valid_order_num is not null,a.user_id,null)) valid_uids
--    FROM
--      (SELECT time,
--              county_id,
--              activity_id,
--              platform_name,
--              app_version,
--              activity_type,
--              user_id,
--              is_brand,
--              mlabel_threshold_amt,
--              mlabel_rebate_amt,
--              mlabel,
--              rebate_rate,
--              store_platform,
--              user_type,
--              user_distance,
--              entrance_name,
--              search_method,
--              keywords,
--              location,
--              count(1) bg_num
--       FROM se_traffic_info
--       WHERE event='Search_Result_Ex' 
--           AND entrance_name IN ('首页',
--                                 '主页')
--     group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
--       ) a 
--    LEFT JOIN
--      (SELECT time,
--              county_id,
--              activity_id,
--              platform_name,
--              app_version,
--              activity_type,
--              user_id,
--              entrance_name,
--              search_method,
--              keywords,
--              location,
--              count(1) clc_num
--       FROM se_traffic_info
--       WHERE event='Search_Result_Click'
--           AND entrance_name IN ('首页',
--                                 '主页')
--         group by 1,2,3,4,5,6,7,8,9,10,11) b ON date_diff('second',b.time,a.time) BETWEEN 0 AND 5
--    AND a.entrance_name=b.entrance_name
--    AND a.search_method=b.search_method
--    AND a.keywords=b.keywords
--    AND a.location=b.location   
--    AND a.county_id=b.county_id
--    AND a.activity_type=b.activity_type
--    AND a.activity_id=b.activity_id
--    AND a.platform_name=b.platform_name
--    AND a.app_version=b.app_version
--    AND a.user_id=b.user_id
--    LEFT JOIN
--      (SELECT time,
--              entrance_name,
--              search_method,
--              county_id,
--              activity_id,
--              platform_name,
--              app_version,
--              activity_type,
--              location,
--              keywords,
--              user_id,
--              baoming_order_num,
--              valid_order_num
--       FROM se_order_result) c ON c.time=b.time
--    AND c.entrance_name=b.entrance_name  
--    AND c.search_method=b.search_method
--    AND c.county_id=b.county_id
--    AND c.activity_type=b.activity_type
--    AND c.activity_id=b.activity_id  
--    AND c.platform_name=b.platform_name
--    AND c.keywords=b.keywords
--    AND c.location=b.location  
--    AND c.app_version=b.app_version
--    AND c.user_id=b.user_id
--    GROUP BY 1,
--             2,
--             3,
--             4,
--             5,
--             6,
--             7,
--             8,
--             9,
--             10,
--             11,
--             12);


INSERT INTO dws.dws_sr_traffic_takeawaypro_funnel_d


SELECT statistics_date,
       traffic_source,
       ifnull(b.city_id,0) city_id,
       ifnull(b.city_name,'未知') city_name,
       a.county_id,
       ifnull(b.county_name,'未知') county_name,
       platform_name,
       app_version,
       activity_type,
       activity_id,
       store_platform,
       is_brand,
       hand_price,
       rebate_rate,
       user_distance,
       user_type,
       expouse_num,
       expouse_uids,
       clc_num,
       clc_uids,
       baoming_order_num,
       baoming_uids,
       valid_order_num,
       valid_uids
FROM
  (SELECT statistics_date,
          '首页' traffic_source,
               county_id,
               platform_name,
               app_version,
               activity_type,
               activity_id,
               store_platform,
               is_brand,
               hand_price,
               rebate_rate,
               user_distance,
               user_type,
               expouse_num,
               expouse_uids,
               clc_num,
               clc_uids,
               baoming_order_num,
               baoming_uids,
               valid_order_num,
               valid_uids
   FROM sy_feed_info
   UNION ALL SELECT statistics_date,
                    '搜索' traffic_source,
                         county_id,
                         platform_name,
                         app_version,
                         activity_type,
                         activity_id,
                         store_platform,
                         is_brand,
                         hand_price,
                         rebate_rate,
                         user_distance,
                         user_type,
                         expouse_num,
                         expouse_uids,
                         clc_num,
                         clc_uids,
                         baoming_order_num,
                         baoming_uids,
                         valid_order_num,
                         valid_uids
   FROM se_feed_info) a
LEFT JOIN dim.dim_silkworm_county b ON a.county_id=b.county_id;