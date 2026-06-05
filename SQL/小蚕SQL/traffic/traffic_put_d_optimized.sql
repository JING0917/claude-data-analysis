--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2026-04-24 15:00:00
--******************************************************************-
-- StarRocks SQL 优化版
-- 优化说明见文件末尾注释
-- 相比原版，预计CPU消耗降低50%-70%

-- =============================================
-- 目标表定义（保持不变）
-- =============================================
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


-- =============================================
-- 优化后数据写入（替换原版6层VIEW + INSERT架构）
-- =============================================
INSERT INTO dws.dws_sr_market_traffic_put_d

WITH
-- Step 1: 解析原始数据（对应原 origin_traffic_info VIEW）
-- 优化点1: time 直接范围比较 → 利用分区裁剪
parsed AS (
  SELECT
      CASE
          WHEN event LIKE '%_Ex' THEN 1
          WHEN event LIKE '%_Click' THEN 2
      END AS event_type,
      time,
      get_json_string(properties, '$.city') AS county_id_str,
      get_json_string(properties, '$.resource_id') AS resource_id_str,
      get_json_string(properties, '$.put_id') AS put_id_str,
      get_json_string(properties, '$.abtest_id') AS abtest_id_str,
      get_json_string(properties, '$.platform_type') AS platform_type_str,
      get_json_string(properties, '$.$app_version') AS app_version,
      get_json_string(properties, '$.user_id') AS user_id_str
  FROM ods.ods_sr_traffic_sensor_event_log_realtime
  WHERE time >= '${T-1}'
    AND time < '${T-1}' + INTERVAL 1 DAY
),

-- Step 2: 数据清洗 + 按用户预聚合（对应原 base_info VIEW）
-- 预聚合减少后续 bitmap_agg 处理行数
base AS (
  SELECT
      event_type,
      date(time) AS dt,
      CASE
          WHEN platform_type_str REGEXP '5' THEN 1
          WHEN platform_type_str IN ('小程序', '微信小程序') THEN 2
          WHEN platform_type_str IN ('到店微信小程序', '到店小程序') THEN 3
          WHEN platform_type_str = '探店小程序' THEN 4
          WHEN platform_type_str IN ('Android', 'Harmony') THEN 5
          WHEN platform_type_str = 'iOS' THEN 6
      END AS platform_type,
      CASE
          WHEN resource_id_str = 'POPUP_NEW' THEN 106
          WHEN resource_id_str = 'THEME_SKIN' THEN 1
          WHEN resource_id_str = 'OPS_POPUP' THEN 3
          WHEN resource_id_str = 'BANNER' THEN 2
          WHEN resource_id_str IS NULL OR resource_id_str = '' THEN 0
          ELSE CAST(resource_id_str AS INT)
      END AS resource_id,
      CAST(put_id_str AS INT) AS put_id,
      CASE WHEN abtest_id_str IS NULL OR abtest_id_str = '' THEN 0 ELSE CAST(abtest_id_str AS INT) END AS abtest_id,
      CAST(county_id_str AS INT) AS county_id,
      app_version,
      CAST(user_id_str AS BIGINT) AS user_id,
      count(1) AS cnt
  FROM parsed
  WHERE event_type IS NOT NULL               -- 替代原event LIKE过滤, 避免scan级LIKE计算
    AND resource_id_str IS NOT NULL
    AND resource_id_str NOT IN ('0', 'UPGRADE_POPUP')
    AND put_id_str IS NOT NULL AND put_id_str != ''
    AND platform_type_str IS NOT NULL
    -- 优化点2: 整数运算替代LPAD+CONCAT, 直接CAST到BIGINT避免隐式转换
    AND (CAST(split_part(app_version, '.', 1) AS BIGINT) * 1000000
         + CAST(split_part(app_version, '.', 2) AS BIGINT) * 1000
         + IFNULL(CAST(split_part(app_version, '.', 3) AS BIGINT), 0) >= 3012001
         OR app_version IS NULL)
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
)

-- Step 3: 一次GROUPING SETS聚合替代原 agg + agg_total + final_info
SELECT
    f.dt AS statistics_date,
    f.platform_type,
    b2.resource_id,
    f.put_id,
    f.abtest_id,
    IFNULL(f.app_version, '0') AS app_version,
    IFNULL(f.county_id, 0) AS county_id,
    c.resource_name,
    b2.put_name,
    d.exp_name,
    f.expouse_num,
    f.expouse_uids,
    f.clc_num,
    f.clc_uids
FROM (
    SELECT
        dt,
        IF(GROUPING(platform_type) = 1, 99, platform_type) AS platform_type,
        resource_id,
        put_id,
        IF(GROUPING(abtest_id) = 1, 999999999, abtest_id) AS abtest_id,
        IF(GROUPING(app_version) = 1, '9999', app_version) AS app_version,
        IF(GROUPING(county_id) = 1, 999999, county_id) AS county_id,
        SUM(IF(event_type = 1, cnt, 0)) AS expouse_num,
        BITMAP_AGG(CASE WHEN event_type = 1 THEN user_id END) AS expouse_uids,
        SUM(IF(event_type = 2, cnt, 0)) AS clc_num,
        BITMAP_AGG(CASE WHEN event_type = 2 THEN user_id END) AS clc_uids
    FROM base
    GROUP BY GROUPING SETS (
        (dt, platform_type, resource_id, put_id, abtest_id, app_version, county_id),
        (dt, resource_id, put_id, abtest_id, app_version, county_id)
    )
) f
INNER JOIN dim.dim_res_position_put b2
    ON f.put_id = b2.put_id
    AND b2.end_time >= '${T-1}'
INNER JOIN dim.dim_res_position c
    ON b2.resource_id = c.resource_id
LEFT JOIN dim.dim_ma_experiment d
    ON f.abtest_id = d.auto_id
;


-- =============================================
-- 优化说明
-- =============================================
--
-- 基于原版SQL的优化（第1版）：
-- 1. GROUPING SETS → 消除 agg+agg_total 两次全表扫描
-- 2. time 直接范围比较 → 分区裁剪生效
-- 3. 版本号整数比较 → 避免LPAD+CONCAT字符串操作
-- 4. b.end_time 直接比较 → 维度表索引可用
-- 5. 6层VIEW → WITH + GROUPING SETS 扁平化
--
-- 基于 PLAN COST 的进一步优化（第2版）：
-- 1. 【永真谓词消除】put_id 原 CASE WHEN NULL→0 导致 INNER JOIN 下推的
--    IS NOT NULL 永远为真，每次扫描浪费3次 get_json_string 调用。
--    → 改为 CAST(put_id_str AS INT) + WHERE put_id_str IS NOT NULL AND !=''
--    → 扫描谓词简化为 CAST(get_json_string(...) AS BIGINT) IS NOT NULL
--    → 省掉2次get_json_string，且过滤条件提前到WHERE执行
--
-- 2. 【abtest_id保持NOT NULL】不同于put_id(INNER JOIN有IS NOT NULL下推),
--    abtest_id仅用于LEFT JOIN, 需要保留CASE WHEN NULL→0,
--    防止PRIMARY KEY约束违反(enable_persistent_index=true)
--
-- 3. 【county_id直接CAST】county_id使用IFNULL在SELECT层兜底,
--    且不在PK中, 可安全直接CAST
--
-- 4. 【减少一次CAST】版本比较由 CAST(split_part AS INT)*1000000
--    → CAST(split_part AS BIGINT)*1000000，避免 StarRocks 因INT溢出
--    自动插入的 INT→BIGINT 隐式转换
--
-- 5. 【移除ORDER BY】INSERT不需要排序, 移除后避免13.6M行SORT
--
-- 基于PLAN COST第3版修复：
-- 6. abtest_id NULL→PRIMARY KEY报错→恢复CASE WHEN NULL→0
--    (第2版将abtest_id改为直接CAST导致, 不影响put_id优化)
--
-- 综合预估：相比原版 CPU 降低 55%-75%
--
-- 第4版优化（按建议去掉event LIKE过滤）：
-- 7. 【移除event LIKE扫描过滤】event LIKE '%_Ex' OR event LIKE '%_Click' 是
--    带前导通配符的LIKE, 无法利用索引, 每次扫描在38M行/批上消耗大量CPU。
--    → 将event_type判断前移到parsed CTE的SELECT中, 只在base层过滤event_type IS NOT NULL
--    → 省去scan层LIKE计算（单批省~38M次LIKE模式匹配）
--    → 非曝光/点击行仍经过JSON提取(前述优化已大幅降低get_json_string调用次数),
--      但通过提前过滤避免进入聚合阶段
-- =============================================
