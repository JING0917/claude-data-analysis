-- ============================================================
-- DWD 层：首页活动事件明细表
-- 表名：dwd.dwd_sr_traffic_homepage_activity_detail_d
-- 数据源：ods.ods_sr_traffic_sensor_event_log_realtime
-- 设计日期：2026-05-25
-- 设计人：dahe
-- ============================================================
-- 设计要点：
-- 1. DUPLICATE KEY 模型，保留明细行，一行对应 ODS 一行
-- 2. DWD 完成所有维度清洗（county_id→INT, activity_id→INT, platform中文映射,
--    distance→INT, activity_status填充, expflow预计算, event_type派生）
-- 3. DWS 层纯聚合（GROUP BY + bitmap_agg），无需任何清洗/JSON解析
-- 4. 仅覆盖首页活动漏斗4个事件 + 实验流维度
-- 5. 参考：tmp_traffic_info 清洗逻辑、dws_sr_traffic_homepage_mix_expflow_d
-- ============================================================

DROP TABLE IF EXISTS dwd.dwd_sr_traffic_homepage_activity_detail_d;

CREATE TABLE IF NOT EXISTS dwd.dwd_sr_traffic_homepage_activity_detail_d (
    -- ======== 基础字段 ========
    dt DATE NOT NULL COMMENT '事件日期（分区键）',
    event_time DATETIME NOT NULL COMMENT '事件时间',
    event_name VARCHAR(50) NOT NULL COMMENT '事件名称',
    event_type TINYINT NOT NULL COMMENT '事件类型(1:曝光_Ex;2:点击_Click;3:页面浏览_View)',

    -- ======== 用户维度 ========
    user_id VARCHAR(50) NOT NULL COMMENT '用户ID(ODS distinct_id)',
    uid VARCHAR(50) COMMENT '用户ID(properties.$.user_id)',

    -- ======== 平台维度 ========
    platform_name VARCHAR(20) COMMENT '平台名称(H5/微信小程序/Android/iOS)',

    -- ======== 位置维度 ========
    county_id INT NOT NULL COMMENT '区县ID(NULL/0/空/null→0)',

    -- ======== 活动维度 ========
    activity_id INT NOT NULL COMMENT '活动ID(非数字→0)',
    activity_type VARCHAR(20) COMMENT '活动类型(NULL/空→小蚕活动)',
    activity_status VARCHAR(25) COMMENT '活动状态(NULL/空→未知)',
    distance INT COMMENT '距离(NULL→-1)',

    -- ======== 版本 ========
    app_version VARCHAR(20) COMMENT '版本号(NULL→未知)',

    -- ======== 实验维度 ========
    expno VARCHAR(20) NOT NULL COMMENT '实验号',
    expflow VARCHAR(20) NOT NULL COMMENT '实验流(distinct_id末位0~3:实验组1;4~7:实验组2;其他:对照组)'
)
ENGINE=OLAP
DUPLICATE KEY (dt, event_type, event_name)
COMMENT "首页活动事件明细日表"
PARTITION BY RANGE (dt) ()
DISTRIBUTED BY HASH (user_id) BUCKETS 48
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4",
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "DAY",
    "dynamic_partition.start" = "-7",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.history_partition_num" = "0"
);


-- ############################################################################
-- DWD ETL（每日从 ODS 解析写入）
-- ############################################################################
-- Session参数
SET parallel_fragment_exec_instance_num = 8;
SET query_timeout = 7200;

INSERT INTO dwd.dwd_sr_traffic_homepage_activity_detail_d
SELECT
    DATE(time) AS dt,
    time AS event_time,
    event AS event_name,

    -- 事件类型
    CASE
        WHEN event LIKE '%_Ex' THEN 1
        WHEN event LIKE '%_Click' THEN 2
        WHEN event LIKE '%_View' THEN 3
        ELSE 0
    END AS event_type,

    -- 用户
    distinct_id AS user_id,
    get_json_string(properties, '$.user_id') AS uid,

    -- 平台（中文映射）
    CASE
        WHEN get_json_string(properties, '$.platform_type') LIKE '%5%' THEN 'H5'
        WHEN get_json_string(properties, '$.platform_type') LIKE '%小程序%' THEN '微信小程序'
        WHEN get_json_string(properties, '$.platform_type') IN ('Android', 'Harmony') THEN 'Android'
        WHEN get_json_string(properties, '$.platform_type') = 'iOS' THEN 'iOS'
    END AS platform_name,

    -- 区县
    CASE
        WHEN county_raw IS NULL OR county_raw = '0' OR county_raw = '' OR county_raw = 'null' THEN 0
        WHEN county_raw REGEXP '^[0-9]{1,9}$' THEN CAST(county_raw AS INT)
        ELSE 0
    END AS county_id,

    -- 活动ID
    CASE
        WHEN activity_raw REGEXP '^[0-9]{1,9}$' THEN CAST(activity_raw AS INT)
        ELSE 0
    END AS activity_id,

    -- 活动类型
    CASE
        WHEN act_type IS NULL OR act_type = '' THEN '小蚕活动'
        ELSE act_type
    END AS activity_type,

    -- 活动状态
    IF(act_status IS NULL OR act_status = '', '未知', act_status) AS activity_status,

    -- 距离
    IF(dist_val IS NULL, -1, CAST(dist_val AS INT)) AS distance,

    -- 版本
    IF(app_ver IS NULL, '未知', app_ver) AS app_version,

    -- 实验号
    '0' AS expno,

    -- 实验流
    CASE
        WHEN CAST(distinct_id AS BIGINT) % 10 BETWEEN 0 AND 3 THEN '实验组1'
        WHEN CAST(distinct_id AS BIGINT) % 10 BETWEEN 4 AND 7 THEN '实验组2'
        ELSE '对照组'
    END AS expflow

FROM (
    SELECT
        time,
        event,
        distinct_id,
        properties,
        get_json_string(properties, '$.city')          AS county_raw,
        get_json_string(properties, '$.activity_id')   AS activity_raw,
        get_json_string(properties, '$.activity_type') AS act_type,
        get_json_string(properties, '$.activity_status') AS act_status,
        get_json_string(properties, '$.distance')      AS dist_val,
        get_json_string(properties, '$.$app_version')  AS app_ver
    FROM ods.ods_sr_traffic_sensor_event_log_realtime
    WHERE time >= '${T} 00:00:00'
      AND time <= '${T} 23:59:59'
      AND event IN ('Homepage_Feed_Activity_Ex',
                    'Homepage_Feed_Activity_Click',
                    'Takeaway_Detailpage_View',
                    'Takeaway_Baomingflow_Button_Click')
      AND distinct_id REGEXP '^[0-9]{1,10}$'
) t
WHERE get_json_string(properties, '$.platform_type') IS NOT NULL
  AND get_json_string(properties, '$.platform_type') <> '';


-- ############################################################################
-- DWS 层简化对照
-- ############################################################################
-- 以下展示 DWS（如 dws_sr_traffic_homepage_mix_expflow_d）从 DWD 读取时，
-- 清洗逻辑完全消失，仅剩 GROUP BY + bitmap_agg。
-- ============================================================================

-- ============================================================================
-- 【旧方式】origin_traffic_info VIEW — 从 ODS 解析 + 清洗 JSON（~65行）
-- ============================================================================
-- CREATE VIEW origin_traffic_info (...) AS
--   SELECT time, event,
--          get_json_string(properties,'$.city') AS county_id,           -- ★ JSON解析
--          get_json_string(properties,'$.activity_id') AS activity_id,  -- ★ JSON解析
--          get_json_string(properties,'$.user_id') AS uid,              -- ★ JSON解析
--          get_json_string(properties,'$.platform_type') AS platform_name, -- ★ JSON解析
--          get_json_string(properties,'$.$app_version') AS app_version, -- ★ JSON解析
--          get_json_string(properties,'$.activity_type') AS activity_type, -- ★ JSON解析
--          get_json_string(properties,'$.distance') AS distance,        -- ★ JSON解析
--          get_json_string(properties,'$.activity_status') AS activity_status, -- ★ JSON解析
--          distinct_id AS user_id,
--          CASE WHEN RIGHT(distinct_id,1) BETWEEN 0 AND 3 THEN '实验组1' ... END AS expflow, -- ★ 重复派生
--          ...
--   FROM ods.ods_sr_traffic_sensor_event_log_realtime
--   WHERE ...
--
-- 【旧方式】traffic_info VIEW — 二次清洗（~40行）
--   CASE WHEN county_id IS NULL OR county_id='0' ... THEN 0 ELSE CAST AS INT END  -- ★ 重复清洗
--   CASE WHEN activity_id REGEXP ... THEN CAST AS INT ELSE 0 END                 -- ★ 重复清洗
--   CASE WHEN platform_name REGEXP '5' THEN 'H5' ... END                         -- ★ 重复映射
--   IF(distance IS NULL, -1, distance)                                            -- ★ 重复清洗
--   ...

-- ============================================================================
-- 【新方式】DWS 直接读 DWD，纯聚合
-- ============================================================================

-- 场景1：首页活动曝光&点击（feed_info）
-- 旧方式：traffic_info VIEW → feed_info VIEW（50行）
-- 新方式：直接从 DWD 聚合（10行）
DROP VIEW IF EXISTS feed_info;
CREATE VIEW IF NOT EXISTS feed_info (
    statistics_date, county_id, activity_id, platform_name, app_version,
    activity_type, expno, expflow, distance, activity_status,
    expouse_num, expouse_uids, clc_num, clc_uids
) AS
SELECT dt,
       county_id,
       activity_id,
       platform_name,
       app_version,
       activity_type,
       expno,
       expflow,
       distance,
       activity_status,
       SUM(IF(event_type = 1, 1, 0)) AS expouse_num,
       bitmap_agg(IF(event_type = 1, user_id, NULL)) AS expouse_uids,
       SUM(IF(event_type = 2, 1, 0)) AS clc_num,
       bitmap_agg(IF(event_type = 2, user_id, NULL)) AS clc_uids
FROM dwd.dwd_sr_traffic_homepage_activity_detail_d
WHERE event_name IN ('Homepage_Feed_Activity_Ex', 'Homepage_Feed_Activity_Click')
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;


-- 场景2：首页活动点击明细（feed_clc）
DROP VIEW IF EXISTS feed_clc;
CREATE VIEW IF NOT EXISTS feed_clc (
    statistics_date, county_id, activity_id, platform_name, app_version,
    activity_type, user_id, expno, expflow, clc_num
) AS
SELECT dt,
       county_id,
       activity_id,
       platform_name,
       app_version,
       activity_type,
       user_id,
       expno,
       expflow,
       COUNT(1) AS clc_num
FROM dwd.dwd_sr_traffic_homepage_activity_detail_d
WHERE event_name = 'Homepage_Feed_Activity_Click'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;


-- 场景3：外卖详情页浏览（detail_view）
DROP VIEW IF EXISTS detail_view;
CREATE VIEW IF NOT EXISTS detail_view (
    statistics_date, county_id, activity_id, platform_name, app_version,
    user_id, expno, expflow, pv
) AS
SELECT dt,
       county_id,
       activity_id,
       platform_name,
       app_version,
       user_id,
       expno,
       expflow,
       COUNT(1) AS pv
FROM dwd.dwd_sr_traffic_homepage_activity_detail_d
WHERE event_name = 'Takeaway_Detailpage_View'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;


-- 场景4：报名按钮点击（bm_clc）
DROP VIEW IF EXISTS bm_clc;
CREATE VIEW IF NOT EXISTS bm_clc (
    statistics_date, county_id, activity_id, platform_name, app_version,
    user_id, expno, expflow, bm_clc_num
) AS
SELECT dt,
       county_id,
       activity_id,
       platform_name,
       app_version,
       user_id,
       expno,
       expflow,
       COUNT(1) AS bm_clc_num
FROM dwd.dwd_sr_traffic_homepage_activity_detail_d
WHERE event_name = 'Takeaway_Baomingflow_Button_Click'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;


-- 场景5：用户活动距离&状态归因（user_activity_distance_attr）
-- 取当天该用户对该活动最后一次点击的距离/状态，点击无则取曝光
DROP VIEW IF EXISTS user_activity_distance_attr;
CREATE VIEW IF NOT EXISTS user_activity_distance_attr (
    statistics_date, user_id, activity_id, distance, activity_status
) AS
SELECT dt,
       user_id,
       activity_id,
       distance,
       activity_status
FROM (
    SELECT dt,
           user_id,
           activity_id,
           distance,
           activity_status,
           ROW_NUMBER() OVER (
               PARTITION BY dt, user_id, activity_id
               ORDER BY event_time DESC
           ) AS rn
    FROM dwd.dwd_sr_traffic_homepage_activity_detail_d
    WHERE event_name IN ('Homepage_Feed_Activity_Click', 'Homepage_Feed_Activity_Ex')
      AND distance IS NOT NULL
      AND activity_status IS NOT NULL
) t
WHERE rn = 1;


-- ============================================================================
-- 实施注意事项：
-- 1. DWD ETL 首次上线需全量回刷历史分区（数据工程师评估保留周期）
-- 2. 下游 DWS 改为从 DWD 读取后，需对比新旧数据一致性
-- 3. 新增活动场景属性时：ALTER TABLE DWD 加列 + 更新 ETL + DWS 不改
-- 4. 不同于之前的通用 DWD 设计（dwd_traffic_event_detail_d），本表聚焦活动场景，
--    DWD 做完全部清洗，DWS 零清洗只聚合
-- ============================================================================
