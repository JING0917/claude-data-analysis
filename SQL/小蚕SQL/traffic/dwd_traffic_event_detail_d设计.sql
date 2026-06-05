-- ============================================================
-- DWD 层：流量事件明细表
-- 表名：dwd.dwd_sr_traffic_event_detail_d
-- 数据源：ods.ods_sr_traffic_sensor_event_log_realtime（每日约4.5亿行）
-- 设计日期：2026-05-25
-- 设计人：dahe
-- ============================================================
-- 设计要点：
-- 1. DUPLICATE KEY 模型，保留明细行（不聚合），一行对应 ODS 一行
-- 2. 一次性解析 properties JSON 为类型化列，DWS 层直接读取列值，无需重复 get_json_string
-- 3. DWD 只做基础提取和类型映射，场景化清洗逻辑留在 DWS 层（不同场景清洗规则不同）
-- 4. 覆盖场景：首页活动（曝光/点击/详情浏览/报名点击）、资源位（全量_Ex/_Click事件）、热区、跨业务线
-- 5. 后续新增 properties 字段只需 ALTER TABLE ADD COLUMN + 更新 ETL，DWD 表持续演进
-- ============================================================

-- ############################################################################
-- 第一部分：DWD 建表 DDL
-- ############################################################################

DROP TABLE IF EXISTS dwd.dwd_sr_traffic_event_detail_d;

CREATE TABLE IF NOT EXISTS dwd.dwd_sr_traffic_event_detail_d (
    -- ======== ODS 透传字段 ========
    dt DATE NOT NULL COMMENT '事件日期（分区键）',
    event_time DATETIME NOT NULL COMMENT '事件时间',
    event_name VARCHAR(100) NOT NULL COMMENT '事件名称',
    distinct_id VARCHAR(50) NOT NULL COMMENT '神策distinct_id',

    -- ======== properties JSON 解析字段 ========
    -- 用户
    uid VARCHAR(20) COMMENT '用户ID(properties.$.user_id)',

    -- 平台（存两列：原始值 + 标准化编码，适配不同场景）
    platform_type_raw VARCHAR(50) COMMENT '平台类型原始值(properties.$.platform_type)',
    platform_type TINYINT COMMENT '平台类型编码(1:H5;2:微信小程序;3:到店微信小程序;4:探店小程序;5:Android;6:iOS)',

    -- 版本 & 位置
    app_version VARCHAR(20) COMMENT '版本号(properties.$.$app_version)',
    county_id VARCHAR(20) COMMENT '区县ID原始值(properties.$.city)',
    distance VARCHAR(20) COMMENT '距离原始值(properties.$.distance)',

    -- 活动
    activity_id VARCHAR(20) COMMENT '活动ID原始值(properties.$.activity_id)',
    activity_type VARCHAR(20) COMMENT '活动类型原始值(properties.$.activity_type)',
    activity_status VARCHAR(20) COMMENT '活动状态原始值(properties.$.activity_status)',

    -- 资源位
    resource_id VARCHAR(50) COMMENT '资源ID原始值(properties.$.resource_id)',
    put_id VARCHAR(50) COMMENT '投放位ID原始值(properties.$.put_id)',
    abtest_id VARCHAR(50) COMMENT 'AB测试ID原始值(properties.$.abtest_id)',

    -- 热区
    hotspots VARCHAR(50) COMMENT '热区ID原始值(properties.$.hotspots)',
    hotarea_id VARCHAR(50) COMMENT '热区区域ID原始值(properties.$.hotarea_id)',

    -- ======== 派生字段 ========
    expflow VARCHAR(10) COMMENT '实验流(distinct_id末位0~3:实验组1, 4~7:实验组2, 其他:对照组)',
    event_type TINYINT COMMENT '事件类型(1:曝光_Ex; 2:点击_Click; 3:页面浏览_View; 0:其他)'
)
ENGINE=OLAP
DUPLICATE KEY (dt, event_type, event_name)
COMMENT "流量事件明细日表"
PARTITION BY RANGE (dt) ()
DISTRIBUTED BY HASH (distinct_id) BUCKETS 64
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
-- 第二部分：DWD ETL（每日从 ODS 解析写入）
-- ############################################################################

INSERT INTO dwd.dwd_sr_traffic_event_detail_d
SELECT
    -- 基础字段
    DATE(time) AS dt,
    time AS event_time,
    event AS event_name,
    distinct_id,

    -- 用户
    get_json_string(properties, '$.user_id') AS uid,

    -- 平台（原始值 + 标准化编码）
    get_json_string(properties, '$.platform_type') AS platform_type_raw,
    CASE
        WHEN get_json_string(properties, '$.platform_type') REGEXP '5' THEN 1                           -- H5
        WHEN get_json_string(properties, '$.platform_type') IN ('小程序', '微信小程序') THEN 2           -- 微信小程序
        WHEN get_json_string(properties, '$.platform_type') IN ('到店微信小程序', '到店小程序') THEN 3   -- 到店微信小程序
        WHEN get_json_string(properties, '$.platform_type') = '探店小程序' THEN 4                       -- 探店小程序
        WHEN get_json_string(properties, '$.platform_type') IN ('Android', 'Harmony') THEN 5             -- Android
        WHEN get_json_string(properties, '$.platform_type') = 'iOS' THEN 6                              -- iOS
    END AS platform_type,

    -- 版本 & 位置
    get_json_string(properties, '$.$app_version') AS app_version,
    get_json_string(properties, '$.city') AS county_id,
    get_json_string(properties, '$.distance') AS distance,

    -- 活动
    get_json_string(properties, '$.activity_id') AS activity_id,
    get_json_string(properties, '$.activity_type') AS activity_type,
    get_json_string(properties, '$.activity_status') AS activity_status,

    -- 资源位
    get_json_string(properties, '$.resource_id') AS resource_id,
    get_json_string(properties, '$.put_id') AS put_id,
    get_json_string(properties, '$.abtest_id') AS abtest_id,

    -- 热区
    get_json_string(properties, '$.hotspots') AS hotspots,
    get_json_string(properties, '$.hotarea_id') AS hotarea_id,

    -- 派生：实验流
    CASE
        WHEN RIGHT(distinct_id, 1) BETWEEN 0 AND 3 THEN '实验组1'
        WHEN RIGHT(distinct_id, 1) BETWEEN 4 AND 7 THEN '实验组2'
        ELSE '对照组'
    END AS expflow,

    -- 派生：事件类型
    CASE
        WHEN event LIKE '%_Ex' THEN 1
        WHEN event LIKE '%_Click' THEN 2
        WHEN event LIKE '%_View' THEN 3
        ELSE 0
    END AS event_type

FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE DATE_FORMAT(time, '%Y-%m-%d') = '${T}';


-- ############################################################################
-- 第三部分：DWS 层简化对照
-- ############################################################################
-- 以下展示各 DWS 场景从 DWD 读取时，ETL 如何简化。
-- 核心变化：不再需要 get_json_string 解析 JSON，直接读取 DWD 已解析的列。
-- 聚合逻辑保持不变。
-- ############################################################################


-- ============================================================================
-- 场景1：首页活动融合归因（dws_sr_traffic_homepage_mix_ascribe_d）
-- 原始SQL：traffic_homepage_mix_ascribe_d首页融合归因.sql
-- ============================================================================

-- 【旧方式】origin_traffic_info VIEW — 从 ODS 解析 JSON
-- CREATE VIEW origin_traffic_info (time, event, county_id, activity_id, uid, platform_name, app_version, activity_type, user_id) AS
--   SELECT time, event,
--          get_json_string(properties,'$.city') AS county_id,           -- ★ JSON解析
--          get_json_string(properties,'$.activity_id') AS activity_id,  -- ★ JSON解析
--          get_json_string(properties,'$.user_id') AS uid,              -- ★ JSON解析
--          get_json_string(properties,'$.platform_type') AS platform_name, -- ★ JSON解析
--          get_json_string(properties,'$.$app_version') AS app_version, -- ★ JSON解析
--          get_json_string(properties,'$.activity_type') AS activity_type, -- ★ JSON解析
--          distinct_id AS user_id
--   FROM ods.ods_sr_traffic_sensor_event_log_realtime
--   WHERE date_format(time,'%Y-%m-%d')='${T}'
--     AND event IN ('Homepage_Feed_Activity_Ex','Homepage_Feed_Activity_Click',
--                   'Takeaway_Detailpage_View','Takeaway_Baomingflow_Button_Click')
--     AND distinct_id regexp '^[0-9]{1,10}$';

-- 【旧方式】traffic_info VIEW — 清洗 JSON 解析后的值
-- CREATE VIEW traffic_info (...) AS
--   SELECT time, event,
--          CASE WHEN county_id IS NULL OR county_id='0' OR county_id='' OR county_id='null' THEN 0
--               ELSE cast(county_id AS int) END AS county_id,
--          CASE WHEN activity_id regexp '^[0-9]{1,9}$' THEN cast(activity_id AS int) ELSE 0 END activity_id,
--          ...
--   FROM origin_traffic_info
--   WHERE platform_name IS NOT NULL OR platform_name<>'';

-- 【新方式】traffic_clean CTE — 从 DWD 直接读列，只做场景专用清洗
-- 无需 get_json_string，无需 origin_traffic_info VIEW

WITH traffic_clean AS (
    SELECT
        dt,
        event_time,
        event_name,
        distinct_id,
        uid,
        -- 首页场景专用清洗
        CASE WHEN county_id IS NULL OR county_id = '0' OR county_id = '' OR county_id = 'null' THEN 0
             ELSE CAST(county_id AS INT) END AS county_id,
        CASE WHEN activity_id REGEXP '^[0-9]{1,9}$' THEN CAST(activity_id AS INT) ELSE 0 END AS activity_id,
        CASE WHEN platform_type_raw REGEXP '5' THEN 'H5'
             WHEN platform_type_raw REGEXP '小程序' THEN '微信小程序'
             WHEN platform_type_raw IN ('Android', 'Harmony') THEN 'Android'
             WHEN platform_type_raw = 'iOS' THEN 'iOS'
        END AS platform_name,
        IF(app_version IS NULL, '未知', app_version) AS app_version,
        IF(activity_type IS NULL OR activity_type = '', '小蚕活动', activity_type) AS activity_type,
        expflow,
        IF(distance IS NULL, -1, distance) AS distance,
        IF(activity_status IS NULL OR activity_status = '', '未知', activity_status) AS activity_status
    FROM dwd.dwd_sr_traffic_event_detail_d
    WHERE dt = '${T}'
      AND event_name IN ('Homepage_Feed_Activity_Ex', 'Homepage_Feed_Activity_Click',
                         'Takeaway_Detailpage_View', 'Takeaway_Baomingflow_Button_Click')
      AND distinct_id REGEXP '^[0-9]{1,10}$'
      AND platform_type_raw IS NOT NULL
      AND platform_type_raw <> ''
)
-- 后续 feed_info / feed_clc / detail_view / bm_clc / order_ascribe / agg_funnel 聚合逻辑
-- 与原始 SQL 完全一致，此处省略
SELECT 'traffic_clean 替代了原 origin_traffic_info + traffic_info 两个 VIEW，后续聚合不变';


-- ============================================================================
-- 场景2：首页活动实验流版本（dws_sr_traffic_homepage_mix_expflow_d）
-- 原始SQL：traffic_homepage_mix_ascribe_d首页融合归因.sql (workspace版)
-- ============================================================================

-- 【旧方式】origin_traffic_info 包含 expflow/distinct_id 派生 + distance/activity_status JSON解析
--   CASE WHEN right(distinct_id,1) between 0 and 3 then '实验组1' ... END AS expflow  -- ★ 每场景重复派生
--   get_json_string(properties,'$.distance') AS distance                              -- ★ 重复JSON解析
--   get_json_string(properties,'$.activity_status') AS activity_status                -- ★ 重复JSON解析

-- 【新方式】expflow/distance/activity_status 已由 DWD 预计算，直接从列读取
-- 无需在 DWS 中再次 get_json_string 或 CASE WHEN right(distinct_id)

WITH traffic_clean AS (
    SELECT
        dt,
        event_time,
        event_name,
        distinct_id,
        uid,
        -- 清洗（与场景1 一致）
        CASE WHEN county_id IS NULL OR county_id = '0' OR county_id = '' OR county_id = 'null' THEN 0
             ELSE CAST(county_id AS INT) END AS county_id,
        CASE WHEN activity_id REGEXP '^[0-9]{1,9}$' THEN CAST(activity_id AS INT) ELSE 0 END AS activity_id,
        CASE WHEN platform_type_raw REGEXP '5' THEN 'H5'
             WHEN platform_type_raw REGEXP '小程序' THEN '微信小程序'
             WHEN platform_type_raw IN ('Android', 'Harmony') THEN 'Android'
             WHEN platform_type_raw = 'iOS' THEN 'iOS'
        END AS platform_name,
        IF(app_version IS NULL, '未知', app_version) AS app_version,
        IF(activity_type IS NULL OR activity_type = '', '小蚕活动', activity_type) AS activity_type,
        -- ★ 以下字段在旧方式中需要重复解析/派生，现在直接读 DWD 列
        expflow,
        IF(distance IS NULL, -1, distance) AS distance,
        IF(activity_status IS NULL OR activity_status = '', '未知', activity_status) AS activity_status
    FROM dwd.dwd_sr_traffic_event_detail_d
    WHERE dt = '${T}'
      AND event_name IN ('Homepage_Feed_Activity_Ex', 'Homepage_Feed_Activity_Click',
                         'Takeaway_Detailpage_View', 'Takeaway_Baomingflow_Button_Click')
      AND distinct_id REGEXP '^[0-9]{1,10}$'
      AND platform_type_raw IS NOT NULL
      AND platform_type_raw <> ''
)
SELECT 'expflow/distance/activity_status 直接从 DWD 列读取，无需重复派生';


-- ============================================================================
-- 场景3：资源位投放流量（dws_sr_market_traffic_put_d）
-- 原始SQL：traffic_put_d.sql
-- ============================================================================

-- 【旧方式】origin_traffic_info VIEW — 从 ODS 解析 JSON
-- CREATE VIEW origin_traffic_info (time, event, county_id, resource_id, put_id, abtest_id, platform_type, $app_version, user_id) AS
--   SELECT time, event,
--          get_json_string(properties,'$.city') AS county_id,              -- ★ JSON解析
--          get_json_string(properties,'$.resource_id') AS resource_id,     -- ★ JSON解析
--          get_json_string(properties,'$.put_id') AS put_id,               -- ★ JSON解析
--          get_json_string(properties,'$.abtest_id') AS abtest_id,         -- ★ JSON解析
--          get_json_string(properties,'$.platform_type') AS platform_type, -- ★ JSON解析
--          get_json_string(properties,'$.$app_version') AS $app_version,   -- ★ JSON解析
--          get_json_string(properties,'$.user_id') AS user_id              -- ★ JSON解析
--   FROM ods.ods_sr_traffic_sensor_event_log_realtime
--   WHERE date_format(time,'%Y-%m-%d')='${T}'
--     AND event regexp '_Ex$|_Click$';

-- 【旧方式】base_info VIEW — 清洗 + 平台映射 + resource_id映射 + 版本过滤
--   CASE WHEN platform_type regexp '5' THEN 1 ... END AS platform_type   -- ★ 重复映射
--   CASE WHEN resource_id='POPUP_NEW' THEN 106 ... END AS resource_id    -- 场景专用清洗
--   版本过滤 CONCAT(LPAD(...)) >= 3.12.1

-- 【新方式】base_info CTE — 从 DWD 读列，只做资源位场景专用清洗
WITH base_info AS (
    SELECT
        CASE WHEN event_name LIKE '%_Ex' THEN 1
             WHEN event_name LIKE '%_Click' THEN 2
        END AS event_type,
        dt,
        -- ★ 平台映射已由 DWD 完成，直接使用 platform_type 列
        platform_type,
        -- 资源位场景专用 resource_id 映射
        CASE WHEN resource_id = 'POPUP_NEW' THEN 106
             WHEN resource_id = 'THEME_SKIN' THEN 1
             WHEN resource_id = 'OPS_POPUP' THEN 3
             WHEN resource_id = 'BANNER' THEN 2
             WHEN resource_id IS NULL OR resource_id = '' THEN 0
             ELSE CAST(resource_id AS INT) END AS resource_id,
        CASE WHEN put_id IS NULL OR put_id = '' THEN 0 ELSE CAST(put_id AS INT) END AS put_id,
        CASE WHEN abtest_id IS NULL OR abtest_id = '' THEN 0 ELSE CAST(abtest_id AS INT) END AS abtest_id,
        app_version,
        uid,
        CAST(IF(county_id IS NULL OR county_id = '', '0', county_id) AS INT) AS county_id,
        1 AS cnt
    FROM dwd.dwd_sr_traffic_event_detail_d
    WHERE dt = '${T}'
      AND event_type IN (1, 2)  -- 所有曝光+点击事件
      AND resource_id IS NOT NULL
      AND resource_id NOT IN ('0', 'UPGRADE_POPUP')
      AND platform_type IS NOT NULL
      AND (CONCAT(LPAD(SPLIT_PART(app_version, '.', 1), 3, '0'),
                  LPAD(SPLIT_PART(app_version, '.', 2), 3, '0'),
                  LPAD(IFNULL(SPLIT_PART(app_version, '.', 3), 0), 3, '0'))
           >= CONCAT(LPAD(3, 3, '0'), LPAD(12, 3, '0'), LPAD(1, 3, '0'))
           OR app_version IS NULL)
)
-- 后续 agg / agg_total / final_info / result_info 聚合逻辑与原始 SQL 完全一致
SELECT 'base_info 替代了原 origin_traffic_info + base_info 两个 VIEW，后续聚合不变';


-- ============================================================================
-- 场景4：热区流量（dws_sr_market_traffic_hotarea_d）
-- 原始SQL：20251215_热区流量统计_大禾.sql
-- ============================================================================

-- 【新方式】traffic_clean CTE — 从 DWD 直接读 hotspots/hotarea_id
WITH traffic_clean AS (
    SELECT
        dt,
        event_name,
        uid,
        platform_type,  -- ★ DWD 已标准化
        CASE WHEN resource_id = 'POPUP_NEW' THEN 106
             WHEN resource_id = 'THEME_SKIN' THEN 1
             WHEN resource_id = 'OPS_POPUP' THEN 3
             WHEN resource_id = 'BANNER' THEN 2
             WHEN resource_id IS NULL OR resource_id = '' THEN 0
             ELSE CAST(resource_id AS INT) END AS resource_id,
        CASE WHEN put_id IS NULL OR put_id = '' THEN 0 ELSE CAST(put_id AS INT) END AS put_id,
        CASE WHEN abtest_id IS NULL OR abtest_id = '' THEN 0 ELSE CAST(abtest_id AS INT) END AS abtest_id,
        -- 热区场景专用清洗
        CASE WHEN hotspots IN ('1', '热区1') THEN 1
             WHEN hotspots IN ('2', '热区2') THEN 2
             WHEN hotspots IN ('3', '热区3') THEN 3
             WHEN hotspots IN ('4', '热区4') THEN 4
             WHEN hotspots IN ('5', '热区5') THEN 5
             ELSE CAST(hotspots AS INT) END AS hotspots,
        CASE WHEN hotarea_id = '0' THEN 1
             WHEN hotarea_id = '1' THEN 2
             WHEN hotarea_id = '2' THEN 3
             WHEN hotarea_id = '3' THEN 4
             WHEN hotarea_id = '4' THEN 5
             ELSE CAST(hotarea_id AS INT) END AS hotarea_id
    FROM dwd.dwd_sr_traffic_event_detail_d
    WHERE dt = '${T}'
      AND event_name IN ('Homepage_View', 'HomePage_View',
                         'Homepage_Opp_Click',
                         'Homepage_Feed_Banner_Ex', 'Homepage_Feed_Banner_Click',
                         'HomePage_Feed_Placement_Ex', 'HomePage_Feed_Placement_Click',
                         'Homepage_Headpic_Ex', 'Homepage_Headpic_Click')
      AND platform_type IS NOT NULL
)
SELECT '热区场景：hotspots/hotarea_id 直接从 DWD 列读取，无需重复 get_json_string';


-- ############################################################################
-- 附录：properties JSON 字段 → DWD 列映射对照表
-- ############################################################################
--
-- properties JSON路径              → DWD列名             数据类型      备注
-- ──────────────────────────────────────────────────────────────────────────
-- $.user_id                        → uid                 VARCHAR(20)   用户ID
-- $.platform_type                  → platform_type_raw   VARCHAR(50)   平台原始值
-- （platform_type_raw 派生）       → platform_type       TINYINT       标准化编码1~6
-- $.city                           → county_id           VARCHAR(20)   区县ID原始值
-- $.distance                       → distance            VARCHAR(20)   距离原始值
-- $.activity_id                    → activity_id         VARCHAR(20)   活动ID原始值
-- $.activity_type                  → activity_type       VARCHAR(20)   活动类型
-- $.activity_status                → activity_status     VARCHAR(20)   活动状态
-- $.resource_id                    → resource_id         VARCHAR(50)   资源ID原始值
-- $.put_id                         → put_id              VARCHAR(50)   投放位ID原始值
-- $.abtest_id                      → abtest_id           VARCHAR(50)   AB测试ID原始值
-- $.hotspots                       → hotspots            VARCHAR(50)   热区ID原始值
-- $.hotarea_id                     → hotarea_id          VARCHAR(50)   热区区域ID原始值
-- $.button_name                    → （待后续添加）       —            目前被注释，未使用
-- $.position                       → （待后续添加）       —            目前被注释，未使用
-- $.from_source                    → （待后续添加）       —            目前被注释，未使用
-- $.activity_type                  → activity_type       VARCHAR(20)   活动类型
--
-- ODS列 → DWD派生列：
-- distinct_id                      → expflow             VARCHAR(10)   实验流（末位取模）
-- event                            → event_type          TINYINT       事件类型(_Ex=1,_Click=2,_View=3)
--
-- ============================================================
-- 实施注意事项：
-- 1. DWD ETL 首次上线需全量回刷历史分区（数据工程师评估保留周期）
-- 2. DWS 表改为从 DWD 读取后，需对比新旧数据一致性（count + 抽样明细）
-- 3. 后续新增场景（搜索、DAU等）可直接从 DWD 读列，只需在 DWS 层写场景专用清洗
-- 4. 如果后续有新的 properties 字段需要解析，ALTER TABLE DWD 加列 + 更新 ETL 即可
-- ============================================================
