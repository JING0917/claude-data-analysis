--JDBC SQL
--******************************************************************--
--author: hongxiu
--create time: 2025-07-03 14:19:10
--******************************************************************-
-- drop table if EXISTS dws.dws_sr_market_traffic_put_d;

-- CREATE TABLE if not exists dws.dws_sr_market_traffic_put_d (
--     statistics_date DATE COMMENT '统计日期',
--     platform_name varchar(25) COMMENT '平台',
--     resource_id int COMMENT '资源ID',
--     put_id int COMMENT '投放位ID',
--     abtest_scheme varchar(500)  COMMENT 'AB测试方案',
--     abtest_id int  COMMENT 'AB测试ID',
--     resource_name varchar(100) REPLACE COMMENT '资源名称',
--     put_name varchar(100) REPLACE COMMENT '投放位名称',
--     expouse_num BIGINT SUM COMMENT '总曝光次数',
--     expouse_uv BIGINT SUM COMMENT '曝光用户数(去重)',
--     clc_num BIGINT SUM COMMENT '总点击次数',
--     clc_uv BIGINT SUM COMMENT '点击用户数(去重)'
-- ) ENGINE=OLAP
-- AGGREGATE KEY(statistics_date,platform_name,resource_id,put_id,abtest_scheme,abtest_id)
-- COMMENT "分日站内投放流量"
-- PARTITION BY date_trunc('day', statistics_date)
-- DISTRIBUTED BY HASH(platform_name,resource_id) BUCKETS 4
-- PROPERTIES (
--     "replication_num" = "1",
--     "in_memory" = "false",
--     "compression" = "LZ4",
--     -- 可选：Bloom Filter
--     "bloom_filter_columns" = "put_id,abtest_id"
-- ); 

CREATE TABLE if not exists dws.dws_sr_market_traffic_put_d (
    statistics_date DATE COMMENT '统计日期',
    platform_name varchar(25) COMMENT '平台',
    resource_id int COMMENT '资源ID',
    put_id int COMMENT '投放位ID',
    abtest_scheme varchar(500) COMMENT 'AB测试方案',
    abtest_id string COMMENT 'AB测试ID',
    resource_name varchar(100) COMMENT '资源名称',
    put_name varchar(100) COMMENT '投放位名称',
    expouse_num BIGINT COMMENT '总曝光次数',
    expouse_uv BIGINT COMMENT '曝光用户数(去重)',
    clc_num BIGINT COMMENT '总点击次数',
    clc_uv BIGINT COMMENT '点击用户数(去重)'
    -- Add update time for primary key table
   -- update_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=OLAP
PRIMARY KEY(statistics_date, platform_name, resource_id, put_id, abtest_scheme,abtest_id)
COMMENT "分日站内投放流量"
PARTITION BY date_trunc('day', statistics_date)
DISTRIBUTED BY HASH(platform_name, resource_id) BUCKETS 4
PROPERTIES (
    "replication_num" = "1",
    "in_memory" = "false",
    "compression" = "LZ4",
    "enable_persistent_index" = "true",  -- Recommended for primary key tables
    "bloom_filter_columns" = "put_id,abtest_id"
);

insert into dws.dws_sr_market_traffic_put_d

-- SELECT a.dt,
--        a.platform_name,
--        a.resource_id,
--        a.put_id,
--        a.abtest_scheme,
--        a.abtest_id,
--        c.resource_name,
--        b.put_name,
--        a.expouse_num,
--        a.expouse_unum,
--        a.clc_num,
--        a.clc_unum
-- FROM
--   (SELECT 
--   	      dt,
--   	      coalesce(platform_name,'全部') as platform_name,
--   	      resource_id,
--   	      put_id,
--           coalesce(abtest_id,'全部') as abtest_id,
--           abtest_scheme,
--           sum(if(event_name regexp '_Ex$|_ex$',1,0)) expouse_num,
--           count(DISTINCT if(event_name regexp '_Ex$|_ex$',user_id,NULL)) expouse_unum,
--           sum(if(event_name regexp '_Click$|_click$',1,0)) clc_num,
--           count(DISTINCT if(event_name regexp '_Click$|_click$',user_id,NULL)) clc_unum
--    from (select dt,
--           CASE
--               WHEN platform_name regexp '5' THEN 'H5'
--               WHEN platform_name regexp '小程序' THEN '小程序'
--               WHEN platform_name='iOS' THEN 'iOS'
--               WHEN platform_name='Android' THEN 'Android'
--               ELSE '其他'
--           END as platform_name,
--         CASE
--         WHEN get_json_object(parse_json(data), "$.resource_id") = 1 THEN 1
--         WHEN get_json_object(parse_json(data), "$.resource_id") = 2 THEN 2
--         WHEN get_json_object(parse_json(data), "$.resource_id") = 3 THEN 3
--       ELSE get_json_object(parse_json(data), "$.resource_id")
--     END AS resource_id,
--     get_json_object(parse_json(data), "$.put_id")  as put_id,
--          if(abtest_id='' or abtest_id is null,'0',abtest_id) as abtest_id,
--           '' AS abtest_scheme,
--           user_id,
--           event_name
--    FROM ods.ods_sr_event_log
--    WHERE dt='${T-1}' and get_json_object(parse_json(data), "$.resource_id")<>0 and get_json_object(parse_json(data), "$.resource_id") is not null and get_json_object(parse_json(data), "$.resource_id")<>'' and get_json_object(parse_json(data), "$.resource_id")<>149
--    and event_name regexp '_Ex$|_ex$'
-- union all
-- select dt,
--           CASE
--               WHEN platform_name regexp '5' THEN 'H5'
--               WHEN platform_name regexp '小程序' THEN '小程序'
--               WHEN platform_name='iOS' THEN 'iOS'
--               WHEN platform_name='Android' THEN 'Android'
--               ELSE '其他'
--           END as platform_name,
--           resource_id,
--           put_id,
--           if(abtest_id='' or abtest_id is null,'0',abtest_id) as abtest_id,
--           '' AS abtest_scheme,
--           user_id,
--           event_name
--    FROM ods.ods_sr_event_log
--    WHERE dt='${T-1}' and resource_id<>0 and resource_id is not null and resource_id<>'' and resource_id<>149
--    and event_name regexp '_Click$|_click$|_Close$'  -- and abtest_id>=0
--    )a
--    group by grouping sets((dt,platform_name,resource_id,put_id,abtest_id,abtest_scheme),
-- 	                   (dt,resource_id,put_id,abtest_scheme)
-- 	                   )
-- )a
-- inner JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
-- inner JOIN dim.dim_res_position c ON a.resource_id=c.resource_id;




-- 资源位本位置曝光、点击
with t as (
SELECT a.statistics_date,
       a.platform_name,
       a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.expouse_num,
       a.expouse_uv,
       a.clc_num,
       a.clc_uv
FROM
  (SELECT date_format(time,'%Y-%m-%d') statistics_date,
       CASE
           WHEN platform_type regexp '5' THEN 'H5'
           WHEN platform_type regexp '小程序' THEN '小程序'
           ELSE platform_type
       END platform_name,
       CASE
           WHEN resource_id='OPS_POPUP' THEN 3
           WHEN resource_id='THEME_SKIN' THEN 1
           WHEN resource_id='POPUP_NEW' THEN 106
           ELSE resource_id
       END resource_id,
       put_id,
       abtest_id,
       sum(if(event regexp '_Ex$|_ex$',1,0)) expouse_num,
       count(DISTINCT if(event regexp '_Ex$|_ex$',user_id,NULL)) expouse_uv,
       sum(if(event regexp '_Click$|_click$|_Close$',1,0)) clc_num,
       count(DISTINCT if(event regexp '_Click$|_click$|_Close$',user_id,NULL)) clc_uv
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-06'
  AND resource_id<>'UPGRADE_POPUP'
  AND resource_id<>'0'
  AND resource_id IS NOT NULL
  AND platform_type IS NOT NULL
  AND platform_type<>'Harmony'
GROUP BY 1,
         2,
         3,
         4,
         5) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id


union all

SELECT a.statistics_date,
       a.platform_name,
       a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.expouse_num,
       a.expouse_uv,
       a.clc_num,
       a.clc_uv
FROM
  (SELECT date_format(time,'%Y-%m-%d') statistics_date,
       '全部' platform_name,
       CASE
           WHEN resource_id='OPS_POPUP' THEN 3
           WHEN resource_id='THEME_SKIN' THEN 1
           WHEN resource_id='POPUP_NEW' THEN 106
           ELSE resource_id
       END resource_id,
       put_id,
       abtest_id,
       sum(if(event regexp '_Ex$|_ex$',1,0)) expouse_num,
       count(DISTINCT if(event regexp '_Ex$|_ex$',user_id,NULL)) expouse_uv,
       sum(if(event regexp '_Click$|_click$|_Close$',1,0)) clc_num,
       count(DISTINCT if(event regexp '_Click$|_click$|_Close$',user_id,NULL)) clc_uv
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-06'
  AND resource_id<>'UPGRADE_POPUP'
  AND resource_id<>'0'
  AND resource_id IS NOT NULL
  AND platform_type IS NOT NULL
  AND platform_type<>'Harmony'
GROUP BY 1,
         2,
         3,
         4,
         5) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id

)

select * from t;



==============================
-- 清洗数据
DROP VIEW IF EXISTS base_info;

CREATE VIEW IF NOT EXISTS base_info (event_type,dt,platform_type,resource_id,put_id,abtest_id,user_id,cnt) AS
  (SELECT CASE
              WHEN event regexp '_Ex$' THEN 1
              WHEN event regexp '_Close$|_Click$' THEN 2
          END event_type,
              date(time) dt,
                         CASE
                             WHEN platform_type regexp '5' THEN 1
                             WHEN platform_type IN ('小程序',
                                                    '微信小程序') THEN 2
                             WHEN platform_type IN ('到店微信小程序',
                                                    '到店小程序') THEN 3
                             WHEN platform_type = '探店小程序' THEN 4
                             WHEN platform_type = 'Android' THEN 5
                             WHEN platform_type = 'iOS' THEN 6
                             WHEN platform_type = 'Harmony' THEN 7
                         END AS platform_type,
                         CASE
                             WHEN resource_id='POPUP_NEW' THEN 106
                             WHEN resource_id='THEME_SKIN' THEN 1
                             WHEN resource_id='OPS_POPUP' THEN 3
                             WHEN resource_id='BANNER' THEN 2
                             WHEN resource_id IS NULL THEN 0
                             ELSE resource_id
                         END AS resource_id,
                         CASE
                             WHEN put_id IS NULL THEN 0
                             ELSE put_id
                         END AS put_id,
                         CASE
                             WHEN abtest_id IS NULL
                                  OR abtest_id='' THEN 0
                             ELSE abtest_id
                         END AS abtest_id,
                         user_id,
                         count(1) cnt
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE time >= '${T-1} 00:00:00'
     AND time < '${T-1} 00:00:00' + INTERVAL 1 DAY
     AND resource_id IS NOT NULL
     AND resource_id NOT IN ('0',
                             'UPGRADE_POPUP')
     AND resource_id<>''
     AND put_id<>''
     AND abtest_id<>''
     AND platform_type IS NOT NULL
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7);



-- 聚合
DROP VIEW IF EXISTS agg;


CREATE VIEW IF NOT EXISTS agg (dt,platform_type,resource_id,put_id,abtest_id,bg_num,bg_uv,clc_num,clc_uv) AS
  (SELECT dt,
          platform_type,
          resource_id,
          put_id,
          abtest_id,
          sum(if(event_type=1,cnt,0)) AS bg_num,
          COUNT(DISTINCT CASE WHEN event_type=1 THEN user_id END) AS bg_uv,
          sum(if(event_type=2,cnt,0)) AS clc_num,
          COUNT(DISTINCT CASE WHEN event_type=2 THEN user_id END) AS clc_uv
   FROM base_info
   GROUP BY 1,
            2,
            3,
            4,
            5);

-- 全部
DROP VIEW IF EXISTS agg_total;


CREATE VIEW IF NOT EXISTS agg_total (dt,platform_type,resource_id,put_id,abtest_id,bg_num,bg_uv,clc_num,clc_uv) AS
  (SELECT dt,
          99 AS platform_type,
          resource_id,
          put_id,
          999999999 abtest_id,
                    sum(if(event_type=1,cnt,0)) AS bg_num,
                    COUNT(DISTINCT CASE WHEN event_type=1 THEN user_id END) AS bg_uv,
                    sum(if(event_type=2,cnt,0)) AS clc_num,
                    COUNT(DISTINCT CASE WHEN event_type=2 THEN user_id END) AS clc_uv
   FROM base_info
   GROUP BY 1,
            2,
            3,
            4,
            5);

-- 拼接
DROP VIEW IF EXISTS final_info;


CREATE VIEW IF NOT EXISTS final_info (dt,platform_type,resource_id,put_id,abtest_id,bg_num,bg_uv,clc_num,clc_uv) AS
  (SELECT dt,
          platform_type,
          resource_id,
          put_id,
          abtest_id,
          bg_num,
          bg_uv,
          clc_num,
          clc_uv
   FROM agg
   UNION ALL SELECT dt,
                    platform_type,
                    resource_id,
                    put_id,
                    abtest_id,
                    bg_num,
                    bg_uv,
                    clc_num,
                    clc_uv
   FROM agg_total);

-- 关联维度表
DROP VIEW IF EXISTS result_info;


CREATE VIEW IF NOT EXISTS result_info (statistics_date,platform_type,resource_id,put_id,abtest_id,resource_name,put_name,expouse_num,expouse_uv,clc_num,clc_uv) AS
  (SELECT f.dt AS statistics_date,
          f.platform_type,
          f.resource_id,
          f.put_id,
          f.abtest_id,
          c.resource_name,
          b.put_name,
          f.bg_num AS expouse_num,
          f.bg_uv AS expouse_uv,
          f.clc_num AS clc_num,
          f.clc_uv AS clc_uv
   FROM final_info f
   INNER JOIN dim.dim_res_position_put b ON f.put_id = b.put_id
   INNER JOIN dim.dim_res_position c ON f.resource_id = c.resource_id);

-- 20251127 替换数据源为神策 修改人：dahe
insert into dws.dws_sr_market_traffic_put_d

-- 关联维度表
SELECT 
    statistics_date,
    platform_type,
    resource_id,
    put_id,
    abtest_id,
    resource_name,
    put_name,
    expouse_num,
    expouse_uv,
    clc_num,
    clc_uv
FROM result_info;




DROP VIEW IF EXISTS base_info;


CREATE VIEW IF NOT EXISTS base_info (event_type,dt,platform_type,resource_id,put_id,abtest_id,user_id,cnt) AS
  (SELECT CASE
              WHEN event regexp '_Ex$' THEN 1
              WHEN event regexp '_Close$|_Click$' THEN 2
          END event_type,
              date(time) dt,
                         CASE
                             WHEN platform_type regexp '5' THEN 1
                             WHEN platform_type IN ('小程序',
                                                    '微信小程序') THEN 2
                             WHEN platform_type IN ('到店微信小程序',
                                                    '到店小程序') THEN 3
                             WHEN platform_type = '探店小程序' THEN 4
                             WHEN platform_type = 'Android' THEN 5
                             WHEN platform_type = 'iOS' THEN 6
                             WHEN platform_type = 'Harmony' THEN 7
                         END AS platform_type,
                         CASE
                             WHEN resource_id='POPUP_NEW' THEN 106
                             WHEN resource_id='THEME_SKIN' THEN 1
                             WHEN resource_id='OPS_POPUP' THEN 3
                             WHEN resource_id='BANNER' THEN 2
                             WHEN resource_id IS NULL THEN 0
                             ELSE resource_id
                         END AS resource_id,
                         CASE
                             WHEN put_id IS NULL THEN 0
                             ELSE put_id
                         END AS put_id,
                         CASE
                             WHEN abtest_id IS NULL
                                  OR abtest_id='' THEN 0
                             ELSE abtest_id
                         END AS abtest_id,
                         user_id,
                         count(1) cnt
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE time >= '${T-1} 00:00:00'
     AND time < '${T-1} 00:00:00' + INTERVAL 1 DAY
     AND resource_id IS NOT NULL
     AND resource_id NOT IN ('0',
                             'UPGRADE_POPUP')
     AND resource_id<>''
     AND put_id<>''
     AND abtest_id<>''
     AND platform_type IS NOT NULL
     AND (CONCAT(LPAD(split_part($app_version, '.', 1), 3, '0'), LPAD(split_part($app_version, '.', 2), 3, '0'), LPAD(IFNULL(split_part($app_version, '.', 3), 0), 3, '0') ) >= CONCAT(LPAD(3, 3, '0'), LPAD(11, 3, '0'), LPAD(7, 3, '0'))
          OR $app_version IS NULL)
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7);












