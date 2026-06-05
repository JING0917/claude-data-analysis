--JDBC SQL
--******************************************************************--
--author: hongxiu
--create time: 2025-07-03 14:19:10
--******************************************************************-
-- drop table if EXISTS dws.dws_sr_market_traffic_put_d;

CREATE TABLE if not exists dws.dws_sr_market_traffic_put_d (
    statistics_date date not null COMMENT '统计日期',
    platform_type int COMMENT '平台类型(99:全部;1:H5;2:微信小程序;3:到店微信小程序;4:探店微信小程序;5:Android;6:iOS)',
    resource_id int COMMENT '资源ID',
    put_id int COMMENT '投放位ID',
    abtest_id int COMMENT 'AB测试ID,999999999:全部',
    app_version varchar(20) COMMENT '版本号,9999:全部',
    resource_name varchar(150) COMMENT '资源名称',
    put_name varchar(150) COMMENT '投放位名称',
    exp_name varchar(15) COMMENT 'AB测试组名称',
    expouse_num BIGINT COMMENT '总曝光次数',
    expouse_uids bitmap COMMENT '去重曝光用户列表',
    clc_num BIGINT COMMENT '总点击次数',
    clc_uids bitmap COMMENT '去重点击用户列表'
) ENGINE=OLAP
PRIMARY KEY(statistics_date, platform_type, resource_id, put_id,abtest_id,app_version)
COMMENT "分日站内投放流量(按平台聚合)"
DISTRIBUTED BY HASH(resource_id,put_id)
PROPERTIES (
    "replication_num" = "3",
    "enable_persistent_index" = "true",
    "replicated_storage" = "true",
    "in_memory" = "false",
    "compression" = "LZ4"
);


-- 20260424 新增距离 活动状态 修改人：dahe
-- ALTER TABLE dws.dws_sr_market_traffic_put_d
--   ADD COLUMN county_id int comment '区县ID' AFTER app_version;




-- 流量解析
DROP VIEW IF EXISTS origin_traffic_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (time,event,county_id,resource_id,put_id,abtest_id,platform_type,$app_version,user_id) AS
  (SELECT time,
          event,
          get_json_string(properties,'$.city') AS county_id,
          get_json_string(properties,'$.resource_id') AS resource_id,
          get_json_string(properties,'$.put_id') AS put_id,
          get_json_string(properties,'$.abtest_id') AS abtest_id,          
          get_json_string(properties,'$.platform_type') AS platform_type,
          get_json_string(properties,'$.$app_version') AS $app_version,
          get_json_string(properties,'$.user_id') AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='${T}'
     AND event regexp '_Ex$|_Click$');


-- 清洗数据
DROP VIEW IF EXISTS base_info;

CREATE VIEW IF NOT EXISTS base_info (event_type,dt,platform_type,resource_id,put_id,abtest_id,app_version,user_id,county_id,cnt) AS
  (SELECT CASE
              WHEN event regexp '_Ex$' THEN 1
              WHEN event regexp '_Click$' THEN 2
          END event_type,
              date(time) dt,
                         CASE
                             WHEN platform_type regexp '5' THEN 1
                             WHEN platform_type IN ('小程序',
                                                    '微信小程序') THEN 2
                             WHEN platform_type IN ('到店微信小程序',
                                                    '到店小程序') THEN 3
                             WHEN platform_type = '探店小程序' THEN 4
                             WHEN platform_type IN ('Android',
                                                    'Harmony') THEN 5
                             WHEN platform_type = 'iOS' THEN 6
                         END AS platform_type,
                         CASE
                             WHEN resource_id='POPUP_NEW' THEN 106
                             WHEN resource_id='THEME_SKIN' THEN 1
                             WHEN resource_id='OPS_POPUP' THEN 3
                             WHEN resource_id='BANNER' THEN 2
                             WHEN resource_id IS NULL 
                                  OR resource_id='' THEN 0
                             ELSE resource_id
                         END AS resource_id,
                         CASE
                             WHEN put_id IS NULL 
                                  OR put_id='' THEN 0
                             ELSE put_id
                         END AS put_id,
                         CASE
                             WHEN abtest_id IS NULL
                                  OR abtest_id='' THEN 0
                             ELSE abtest_id
                         END AS abtest_id,
                         $app_version,
                         user_id,
                         case when county_id is null or county_id='' then 0 else cast(county_id as int) end as county_id,
                         count(1) cnt
   FROM origin_traffic_info
   WHERE resource_id IS NOT NULL
     AND resource_id NOT IN ('0',
                             'UPGRADE_POPUP')
    --  AND resource_id<>''
    --  AND put_id<>''
    --  AND abtest_id<>'' -- 20251203 注释掉空值过滤 因会丢数据 修改人：dahe
     AND platform_type IS NOT NULL
     AND (CONCAT(LPAD(split_part($app_version, '.', 1), 3, '0'), LPAD(split_part($app_version, '.', 2), 3, '0'), LPAD(IFNULL(split_part($app_version, '.', 3), 0), 3, '0') ) >= CONCAT(LPAD(3, 3, '0'), LPAD(12, 3, '0'), LPAD(1, 3, '0'))
          OR $app_version IS NULL) -- 20260407 限制版本从3.11.9改为3.12.1 因旧版本埋点错误 数据指标异常 重跑26年3月25日及之后数据 修改人：dahe
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9);



-- 聚合
DROP VIEW IF EXISTS agg;


CREATE VIEW IF NOT EXISTS agg (dt,platform_type,resource_id,put_id,abtest_id,app_version,county_id,bg_num,bg_uids,clc_num,clc_uids) AS
  (SELECT dt,
          platform_type,
          resource_id,
          put_id,
          abtest_id,
          app_version,
          county_id,
          sum(if(event_type=1,cnt,0)) AS bg_num,
          bitmap_agg(CASE WHEN event_type=1 THEN user_id END) AS bg_uids,
          sum(if(event_type=2,cnt,0)) AS clc_num,
          bitmap_agg(CASE WHEN event_type=2 THEN user_id END) AS clc_uids
   FROM base_info
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7);

-- 全部
DROP VIEW IF EXISTS agg_total;


CREATE VIEW IF NOT EXISTS agg_total (dt,platform_type,resource_id,put_id,abtest_id,app_version,county_id,bg_num,bg_uids,clc_num,clc_uids) AS
  (SELECT dt,
          99 AS platform_type,
          resource_id,
          put_id,
          999999999 abtest_id,
          9999 app_version,
          999999 county_id,
                    sum(if(event_type=1,cnt,0)) AS bg_num,
                    bitmap_agg(CASE WHEN event_type=1 THEN user_id END) AS bg_uids,
                    sum(if(event_type=2,cnt,0)) AS clc_num,
                    bitmap_agg(CASE WHEN event_type=2 THEN user_id END) AS clc_uids
   FROM base_info
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7);

-- 拼接
DROP VIEW IF EXISTS final_info;


CREATE VIEW IF NOT EXISTS final_info (dt,platform_type,resource_id,put_id,abtest_id,app_version,county_id,bg_num,bg_uids,clc_num,clc_uids) AS
  (SELECT dt,
          platform_type,
          resource_id,
          put_id,
          abtest_id,
          app_version,
          county_id,
          bg_num,
          bg_uids,
          clc_num,
          clc_uids
   FROM agg
   UNION ALL SELECT dt,
                    platform_type,
                    resource_id,
                    put_id,
                    abtest_id,
                    app_version,
                    county_id,
                    bg_num,
                    bg_uids,
                    clc_num,
                    clc_uids
   FROM agg_total);

-- 关联维度表
DROP VIEW IF EXISTS result_info;


CREATE VIEW IF NOT EXISTS result_info (statistics_date,platform_type,resource_id,put_id,abtest_id,app_version,county_id,resource_name,put_name,exp_name,expouse_num,expouse_uids,clc_num,clc_uids) AS
  (SELECT f.dt AS statistics_date,
          f.platform_type,
          b.resource_id,
          f.put_id,
          f.abtest_id,
          ifnull(f.app_version,0) app_version,
          ifnull(f.county_id,0) county_id,
          c.resource_name,
          b.put_name,
          d.exp_name,
          f.bg_num AS expouse_num,
          f.bg_uids AS expouse_uids,
          f.clc_num AS clc_num,
          f.clc_uids AS clc_uids
   FROM final_info f
   INNER JOIN dim.dim_res_position_put b ON f.put_id = b.put_id and date(b.end_time)>='${T}'
   INNER JOIN dim.dim_res_position c ON b.resource_id = c.resource_id
   LEFT JOIN dim.dim_ma_experiment d ON f.abtest_id = d.auto_id);

-- 20251127 替换数据源为神策 修改人：dahe
insert into dws.dws_sr_market_traffic_put_d

-- 关联维度表
SELECT 
    statistics_date,
    platform_type,
    resource_id,
    put_id,
    abtest_id,
    app_version,
    county_id,
    resource_name,
    put_name,
    exp_name,
    expouse_num,
    expouse_uids,
    clc_num,
    clc_uids
FROM result_info ;





