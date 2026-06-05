-- -- 示例：按天分区的表结构（已有表可通过ALTER TABLE加分区）
-- CREATE TABLE dwd.dwd_sr_traffic_sensor_event_log_realtime (
--     time DATETIME,
--     user_id STRING,
--     platform_type STRING,
--     app_version STRING,
--     -- 预生成bitmap列（核心优化：避免查询时重复hash，性能提升30%+）
--     user_id_bitmap BITMAP NULL DEFAULT bitmap_hash(user_id)
-- ) ENGINE=OLAP
-- DUPLICATE KEY(time, platform_type)
-- -- 按time字段按天分区（核心：仅扫描当天分区，而非全表）
-- PARTITION BY RANGE(time) (
--     PARTITION p20251225 VALUES [('2025-12-25 00:00:00'), ('2025-12-26 00:00:00')),
--     PARTITION p20251226 VALUES [('2025-12-26 00:00:00'), ('2025-12-27 00:00:00'))
-- )
-- DISTRIBUTED BY HASH(time) BUCKETS 100; -- 分桶数按集群规模调整（建议100-200）





-- SELECT
--     -- 10分钟时间片截断（StarRocks原生优化，简洁高效）
--     DATE_TRUNC('minute', time) - INTERVAL (MINUTE(time) % 10) MINUTE AS ten_minute_slot,
--     -- bitmap去重统计（4亿级数据秒级出结果，远优于count(distinct)）
--     BITMAP_UNION_COUNT(user_id_bitmap) AS dau_ten_minute
-- FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
-- -- 核心：仅过滤当天分区，避免扫描历史4亿数据
-- WHERE time >= CURRENT_DATE() AND time < CURRENT_DATE() + INTERVAL 1 DAY
-- -- 仅按10分钟时间片分组（当天最多144个分组，计算量极小）
-- GROUP BY ten_minute_slot
-- -- 按时间升序，直观查看当天实时递增的UV
-- ORDER BY ten_minute_slot;


-- -- 1. 创建物化视图（预聚合10分钟粒度的bitmap）
-- CREATE MATERIALIZED VIEW mv_ten_minute_uv
-- AS
-- SELECT
--     DATE_TRUNC('minute', time) - INTERVAL (MINUTE(time) % 10) MINUTE AS ten_minute_slot,
--     BITMAP_UNION(user_id_bitmap) AS user_bitmap  -- 预聚合bitmap
-- FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
-- GROUP BY ten_minute_slot;

-- -- 2. 查询物化视图（秒级出结果，无需重复计算）
-- SELECT
--     ten_minute_slot,
--     BITMAP_COUNT(user_bitmap) AS dau_ten_minute
-- FROM mv_ten_minute_uv
-- -- 仅过滤当天的时间片
-- WHERE ten_minute_slot >= CURRENT_DATE() AND ten_minute_slot < CURRENT_DATE() + INTERVAL 1 DAY
-- ORDER BY ten_minute_slot;

========================================================================
drop table if exists dws.dws_sr_traffic_dau_10min;

CREATE TABLE if not exists dws.dws_sr_traffic_dau_10min (
  statistics_time_period datetime not null comment '统计时间区间',
  -- city_name varchar(30) not null comment '城市',
  -- county_name varchar(30) not null comment '区县',
  -- platform_name varchar(20) not null comment '平台名称',
  -- app_version varchar(20) not null comment '版本',
  page_name varchar(10) not null comment '页面名称',
  view_uids bitmap comment '访问用户列表'
)
ENGINE=OLAP
PRIMARY KEY (statistics_time_period,page_name)
COMMENT "每10分钟访问用户量"
DISTRIBUTED BY HASH(statistics_time_period)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);

insert into dws.dws_sr_traffic_dau_10min

SELECT 
    CONCAT(DATE_FORMAT(time, '%Y-%m-%d %H:'), FLOOR(MINUTE(time)/10)*10, ':00') AS statistics_time_period,
    '全站' page_name,
    COUNT(DISTINCT distinct_id) uv
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time)='2025-12-20'
  AND distinct_id regexp '^[0-9]{1,10}$'
GROUP BY 1,2

UNION all
SELECT 
    CONCAT(DATE_FORMAT(time, '%Y-%m-%d %H:'), FLOOR(MINUTE(time)/10)*10, ':00') AS statistics_time_period,
    '首页' page_name,
    COUNT(DISTINCT distinct_id) uv
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time)='2025-12-20'
  AND distinct_id regexp '^[0-9]{1,10}$'
  and event in ('Homepage_View','HomePage_View')
GROUP BY 1,2


================ 以下逻辑，在12月25日处理时，报BE节点tablet错误，规避不开，因此减少维度，使用前述逻辑直接统计

-- 流量数据
DROP VIEW IF EXISTS origin_traffic_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (time,event,county_id,platform_name,app_version,user_id) AS
  (SELECT time,
          lower(event) AS event,
          get_json_string(properties,'$.city') AS county_id,
          get_json_string(properties,'$.platform_type') AS platform_name,
          get_json_string(properties,'$.$app_version') AS app_version,
          distinct_id AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date(time)=CURRENT_DATE
     AND distinct_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6);

-- 全站DAU
DROP VIEW IF EXISTS all_flow_info;


CREATE VIEW IF NOT EXISTS all_flow_info (statistics_time_period,county_id,platform_name,app_version,page_name,user_id_bitmap) AS
  (SELECT DATE_TRUNC('minute', time) - INTERVAL (MINUTE(time) % 10) MINUTE AS statistics_time_period,
                                                                              CASE
                                                                                  WHEN county_id IS NULL
                                                                                       OR county_id='0'
                                                                                       OR county_id=''
                                                                                       OR county_id='null' THEN 0
                                                                                  ELSE cast(county_id AS int)
                                                                              END AS county_id,
                                                                              CASE
                                                                                  WHEN platform_name regexp '5' THEN 'H5'
                                                                                  WHEN platform_name IN ('小程序',
                                                                                                         '微信小程序') THEN '微信小程序'
                                                                                  WHEN platform_name IN ('到店小程序',
                                                                                                         '到店微信小程序') THEN '到店微信小程序'
                                                                                  WHEN platform_name ='探店小程序' THEN '探店微信小程序'
                                                                                  WHEN platform_name IN ('Android',
                                                                                                         'Harmony') THEN 'Android'
                                                                                  WHEN platform_name='iOS' THEN 'iOS'
                                                                                  ELSE '未知'
                                                                              END platform_name,
                                                                                  IF(app_version IS NULL,
                                                                                                    '未知',
                                                                                                    app_version) app_version,
                                                                                                                 '全站' page_name,
                                                                                                                      bitmap_hash(user_id) user_id_bitmap
   FROM
     (SELECT time,
             county_id,
             platform_name,
             app_version,
             user_id
      FROM origin_traffic_info
      GROUP BY 1,
               2,
               3,
               4,
               5) a );

-- 首页DAU
DROP VIEW IF EXISTS homepage_flow_info;


CREATE VIEW IF NOT EXISTS homepage_flow_info (statistics_time_period,county_id,platform_name,app_version,page_name,user_id_bitmap) AS
  (SELECT DATE_TRUNC('minute', time) - INTERVAL (MINUTE(time) % 10) MINUTE AS statistics_time_period,
                                                                              CASE
                                                                                  WHEN county_id IS NULL
                                                                                       OR county_id='0'
                                                                                       OR county_id=''
                                                                                       OR county_id='null' THEN 0
                                                                                  ELSE cast(county_id AS int)
                                                                              END AS county_id,
                                                                              CASE
                                                                                  WHEN platform_name regexp '5' THEN 'H5'
                                                                                  WHEN platform_name IN ('小程序',
                                                                                                         '微信小程序') THEN '微信小程序'
                                                                                  WHEN platform_name IN ('到店小程序',
                                                                                                         '到店微信小程序') THEN '到店微信小程序'
                                                                                  WHEN platform_name ='探店小程序' THEN '探店微信小程序'
                                                                                  WHEN platform_name IN ('Android',
                                                                                                         'Harmony') THEN 'Android'
                                                                                  WHEN platform_name='iOS' THEN 'iOS'
                                                                                  ELSE '未知'
                                                                              END platform_name,
                                                                                  IF(app_version IS NULL,
                                                                                                    '未知',
                                                                                                    app_version) app_version,
                                                                                                                 '首页' page_name,
                                                                                                                      bitmap_hash(user_id) user_id_bitmap
   FROM
     (SELECT time,
             county_id,
             platform_name,
             app_version,
             user_id
      FROM origin_traffic_info
      WHERE event='homepage_view'
      GROUP BY 1,
               2,
               3,
               4,
               5) a );


insert into dws.dws_sr_traffic_dau_10min

SELECT statistics_time_period,
       ifnull(b.city_name,'未知') city_name,
       ifnull(b.county_name,'未知') county_name,
       platform_name,
       app_version,
       page_name,
       user_id_bitmap
FROM
  (SELECT statistics_time_period,
          county_id,
          platform_name,
          app_version,
          page_name,
          user_id_bitmap
   FROM all_flow_info
   UNION ALL SELECT statistics_time_period,
                    county_id,
                    platform_name,
                    app_version,
                    page_name,
                    user_id_bitmap
   FROM homepage_flow_info) a
LEFT JOIN dim.dim_silkworm_county b ON a.county_id=b.county_id ;





















