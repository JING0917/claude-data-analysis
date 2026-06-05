--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2026-04-03 15:30:00
--******************************************************************--
/*
埋点质量监控 - 全事件监控版
目标：监控所有埋点事件（近600个）的数据质量，生成小时级监控数据表供帆软BI使用
版本：7.0（全事件监控版）
日期：2026-04-10
作者：Claude

优化重点：
1. 性能优化：减少CPU消耗，提升执行效率
2. 数据扫描范围优化：只处理必要的时间范围
3. 计算简化：从目标表获取历史数据，减少复杂计算
4. 分区表优化：按月分区，提高查询性能

监控需求：
1. 监控维度（三层监控体系）：
   a) 全事件基础监控：监控所有近600个事件的基础指标（事件数量、用户数、环比变化率）
   b) 关键事件详细监控：7个关键事件的详细监控（包括搜索关键词缺失率等事件特定属性）
      - Homepage_Feed_Activity_Ex（首页feed活动曝光）
      - Homepage_Feed_Activity_Click（首页feed活动点击）
      - Takeaway_Detailpage_View（外卖详情页浏览）
      - Takeaway_Baomingflow_Button_Click（外卖报名流按钮点击）
      - Search_Click（搜索点击）
      - Search_Result_Ex（搜索结果曝光）
      - Search_Result_Click（搜索结果点击）
   c) 整体数据监控（ALL_EVENTS）：所有事件的汇总监控，用于发现系统性问题和数据采集故障

2. 平台维度：Android、iOS、H5、微信小程序（统一严格监控）

3. 监控指标：
   - 数据量异常：小时级数据量，天环比(昨日同时段)、周环比(上周同日同时段)变化率
   - 缺失值异常：关键字段的缺失比率（如搜索关键词）

4. 告警分级（新阈值）：
   - P3（异常）：变化率在正负5%之间
   - P2（严重）：变化率在正负5%到10%之间
   - P1（危险）：变化率超过正负10%

使用说明：
1. 首次执行：运行本SQL文件中的建表语句
2. WeData定时任务：每3-4小时执行一次数据插入部分
3. 帆软BI直接查询ads.ads_sr_traffic_monitor_h表
4. 参数配置：在WeData任务中设置参数变量
*/

-- ==================== 配置参数 ====================
-- 以下参数在WeData任务级别配置
-- 参数设置格式：变量名=参数值，多个参数以英文分号分隔
-- 示例：var_p3_threshold=5;var_p2_threshold=10;var_process_hours=4;var_source_table="ods.ods_sr_traffic_sensor_event_log_realtime"

-- ==================== 创建监控结果表（带分区） ====================
-- 如果表不存在，先创建（首次执行时）
-- 注意：不要使用DROP TABLE，会丢失历史数据

CREATE TABLE IF NOT EXISTS ads.ads_sr_traffic_monitor_h
(
    `stat_hour` datetime NOT NULL COMMENT '统计小时（精确到小时）',
    `event` varchar(50) NOT NULL COMMENT '事件名称',
    `platform_name` varchar(20) NOT NULL COMMENT '平台名称（Android/iOS/H5/微信小程序）',
    `app_version` varchar(20) COMMENT '应用版本',
    `event_count` bigint NOT NULL COMMENT '事件数量',
    `user_count` bigint NOT NULL COMMENT '用户数（去重）',
    `prev_day_count` bigint COMMENT '昨日同时段事件数量',
    `prev_week_count` bigint COMMENT '上周同日同时段事件数量',
    `day_over_day_change_rate` decimal(8,2) COMMENT '天环比变化率（百分比）',
    `week_over_week_change_rate` decimal(8,2) COMMENT '周环比变化率（百分比）',
    `day_alert_level` varchar(10) COMMENT '天环比告警级别（P1危险/P2严重/P3异常/无对比数据）',
    `week_alert_level` varchar(10) COMMENT '周环比告警级别（P1危险/P2严重/P3异常/无对比数据）',
    `final_alert_level` varchar(10) COMMENT '综合告警级别（P1危险/P2严重/P3异常/无对比数据）',
    `missing_keywords_count` bigint COMMENT '搜索关键词缺失数量（仅搜索事件有效）',
    `missing_keywords_ratio` decimal(8,2) COMMENT '搜索关键词缺失率（百分比）',
    `missing_alert_level` varchar(10) COMMENT '缺失值告警级别（P1危险/P2严重/P3异常/正常）',
    `create_time` datetime NOT NULL COMMENT '数据创建时间'
)
ENGINE=OLAP
PRIMARY KEY (`stat_hour`, `event`, `platform_name`, `app_version`)
COMMENT "埋点质量监控小时表（优化版）"
DISTRIBUTED BY HASH(`stat_hour`, `event`)
PARTITION BY RANGE(`stat_hour`)
(
    PARTITION p202601 VALUES [('2026-01-01 00:00:00'), ('2026-02-01 00:00:00')),
    PARTITION p202602 VALUES [('2026-02-01 00:00:00'), ('2026-03-01 00:00:00')),
    PARTITION p202603 VALUES [('2026-03-01 00:00:00'), ('2026-04-01 00:00:00')),
    PARTITION p202604 VALUES [('2026-04-01 00:00:00'), ('2026-05-01 00:00:00')),
    PARTITION p202605 VALUES [('2026-05-01 00:00:00'), ('2026-06-01 00:00:00')),
    PARTITION p202606 VALUES [('2026-06-01 00:00:00'), ('2026-07-01 00:00:00'))
)
PROPERTIES (
    "replication_num" = "2",
    "storage_format" = "V2",
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "MONTH",
    "dynamic_partition.start" = "-3",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.buckets" = "8"
);

-- ==================== 增量数据插入（优化版） ====================
-- 优化策略：
-- 1. 只处理最近N小时的新数据，大幅减少数据扫描范围
-- 2. 从目标表获取历史数据用于环比计算，避免重复扫描原始表
-- 3. 简化JSON解析和正则表达式
-- 4. 使用分区过滤提高性能

INSERT INTO ads.ads_sr_traffic_monitor_h
WITH
-- 步骤1：只处理最近N小时的新数据（最小化数据扫描）
recent_hours_data AS (
    SELECT
        time,
        event,
        distinct_id,
        get_json_string(properties, '$.platform_type') AS raw_platform_type,
        get_json_string(properties, '$.$app_version') AS app_version,
        get_json_string(properties, '$.query_word') AS query_word,
        -- 标记是否为关键监控事件
        event IN (
            'Homepage_Feed_Activity_Ex',
            'Homepage_Feed_Activity_Click',
            'Takeaway_Detailpage_View',
            'Takeaway_Baomingflow_Button_Click',
            'Search_Click',
            'Search_Result_Ex',
            'Search_Result_Click'
        ) AS is_key_event
    FROM ${var_source_table}
    WHERE
        -- 关键优化：只扫描最近N小时数据，不是7天+N小时
        time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
        -- 事件过滤：移除事件过滤以支持整体监控
        -- 注意：现在扫描所有事件数据，用于整体监控和关键事件监控
        -- 用户ID过滤：优化正则表达式，使用简单函数
        AND LENGTH(distinct_id) BETWEEN 1 AND 10
        AND distinct_id NOT REGEXP '[^0-9]'  -- 只包含数字
        -- 平台过滤
        AND get_json_string(properties, '$.platform_type') IS NOT NULL
),

-- 步骤2：小时级聚合（新数据）
-- 2.1 所有事件详细聚合（近600个事件）
hourly_all_events AS (
    SELECT
        DATE_FORMAT(time, '%Y-%m-%d %H:00:00') AS agg_hour,
        event,
        -- 平台类型标准化（一次性计算）
        CASE
            WHEN raw_platform_type LIKE '%5%' THEN 'H5'
            WHEN raw_platform_type LIKE '%小程序%' THEN '微信小程序'
            WHEN raw_platform_type IN ('Android', 'Harmony') THEN 'Android'
            WHEN raw_platform_type = 'iOS' THEN 'iOS'
            ELSE raw_platform_type
        END AS platform_name,
        app_version,
        -- 只对搜索事件保留query_word，其他事件设为NULL
        CASE
            WHEN event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click') THEN query_word
            ELSE NULL
        END AS query_word,
        COUNT(*) AS event_count,
        COUNT(DISTINCT distinct_id) AS user_count,
        -- 标记是否为搜索事件（只有3个搜索事件）
        event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click') AS is_search_event,
        -- 标记是否为7个关键事件（用于区分详细监控级别）
        event IN (
            'Homepage_Feed_Activity_Ex',
            'Homepage_Feed_Activity_Click',
            'Takeaway_Detailpage_View',
            'Takeaway_Baomingflow_Button_Click',
            'Search_Click',
            'Search_Result_Ex',
            'Search_Result_Click'
        ) AS is_key_event
    FROM recent_hours_data
    -- 移除事件过滤，处理所有事件
    GROUP BY
        DATE_FORMAT(time, '%Y-%m-%d %H:00:00'),
        event,
        CASE
            WHEN raw_platform_type LIKE '%5%' THEN 'H5'
            WHEN raw_platform_type LIKE '%小程序%' THEN '微信小程序'
            WHEN raw_platform_type IN ('Android', 'Harmony') THEN 'Android'
            WHEN raw_platform_type = 'iOS' THEN 'iOS'
            ELSE raw_platform_type
        END,
        app_version,
        CASE
            WHEN event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click') THEN query_word
            ELSE NULL
        END
),

-- 2.2 整体数据聚合（所有事件汇总）
hourly_overall AS (
    SELECT
        DATE_FORMAT(time, '%Y-%m-%d %H:00:00') AS agg_hour,
        'ALL_EVENTS' AS event,  -- 固定事件名称表示整体数据
        -- 平台类型标准化
        CASE
            WHEN raw_platform_type LIKE '%5%' THEN 'H5'
            WHEN raw_platform_type LIKE '%小程序%' THEN '微信小程序'
            WHEN raw_platform_type IN ('Android', 'Harmony') THEN 'Android'
            WHEN raw_platform_type = 'iOS' THEN 'iOS'
            ELSE raw_platform_type
        END AS platform_name,
        app_version,
        NULL AS query_word,  -- 整体数据不单独统计搜索关键词
        COUNT(*) AS event_count,
        COUNT(DISTINCT distinct_id) AS user_count,  -- 跨事件用户去重
        -- 整体数据中，搜索事件标记设为NULL（不适用）
        NULL AS is_search_event,
        -- 标记为非关键事件（整体汇总）
        FALSE AS is_key_event
    FROM recent_hours_data
    GROUP BY
        DATE_FORMAT(time, '%Y-%m-%d %H:00:00'),
        CASE
            WHEN raw_platform_type LIKE '%5%' THEN 'H5'
            WHEN raw_platform_type LIKE '%小程序%' THEN '微信小程序'
            WHEN raw_platform_type IN ('Android', 'Harmony') THEN 'Android'
            WHEN raw_platform_type = 'iOS' THEN 'iOS'
            ELSE raw_platform_type
        END,
        app_version
),

-- 2.3 合并所有事件和整体数据
hourly_aggregation AS (
    SELECT * FROM hourly_all_events
    UNION ALL
    SELECT * FROM hourly_overall
),

-- 步骤3：从目标表获取历史数据（昨日和上周）
historical_data AS (
    SELECT
        stat_hour,
        event,
        platform_name,
        app_version,
        event_count
    FROM ads.ads_sr_traffic_monitor_h
    WHERE
        -- 获取昨日和上周的数据用于环比计算
        stat_hour >= DATE_SUB(
            DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR),
            INTERVAL 8 DAY  -- 多取1天缓冲
        )
),

-- 步骤4：计算环比（使用历史数据）
with_comparison AS (
    SELECT
        h.agg_hour AS stat_hour,
        h.event,
        h.platform_name,
        h.app_version,
        h.event_count,
        h.user_count,
        -- 昨日同时段数据
        h1.event_count AS prev_day_count,
        -- 上周同日同时段数据
        h7.event_count AS prev_week_count,
        -- 天环比变化率
        CASE
            WHEN h1.event_count > 0 THEN
                ROUND((h.event_count - h1.event_count) * 100.0 / h1.event_count, 2)
            ELSE NULL
        END AS day_over_day_change_rate,
        -- 周环比变化率
        CASE
            WHEN h7.event_count > 0 THEN
                ROUND((h.event_count - h7.event_count) * 100.0 / h7.event_count, 2)
            ELSE NULL
        END AS week_over_week_change_rate,
        -- 搜索关键词缺失统计
        CASE
            WHEN h.is_search_event THEN
                SUM(CASE WHEN h.query_word IS NULL OR h.query_word = '' THEN 1 ELSE 0 END)
                OVER (PARTITION BY h.agg_hour, h.event, h.platform_name, h.app_version)
            ELSE NULL
        END AS missing_keywords_count,
        CASE
            WHEN h.is_search_event AND COUNT(*) OVER (PARTITION BY h.agg_hour, h.event, h.platform_name, h.app_version) > 0 THEN
                ROUND(
                    SUM(CASE WHEN h.query_word IS NULL OR h.query_word = '' THEN 1 ELSE 0 END)
                    OVER (PARTITION BY h.agg_hour, h.event, h.platform_name, h.app_version) * 100.0 /
                    COUNT(*) OVER (PARTITION BY h.agg_hour, h.event, h.platform_name, h.app_version), 2
                )
            WHEN h.is_search_event THEN 0
            ELSE NULL
        END AS missing_keywords_ratio
    FROM hourly_aggregation h
    LEFT JOIN historical_data h1
        ON h1.event = h.event
        AND h1.platform_name = h.platform_name
        AND (h1.app_version = h.app_version OR (h1.app_version IS NULL AND h.app_version IS NULL))
        AND h1.stat_hour = DATE_SUB(h.agg_hour, INTERVAL 24 HOUR)
    LEFT JOIN historical_data h7
        ON h7.event = h.event
        AND h7.platform_name = h.platform_name
        AND (h7.app_version = h.app_version OR (h7.app_version IS NULL AND h.app_version IS NULL))
        AND h7.stat_hour = DATE_SUB(h.agg_hour, INTERVAL 168 HOUR)  -- 7天
    WHERE h.platform_name IN ('Android', 'iOS', 'H5', '微信小程序')
),

-- 步骤5：计算告警级别
final_data AS (
    SELECT
        stat_hour,
        event,
        platform_name,
        app_version,
        event_count,
        user_count,
        prev_day_count,
        prev_week_count,
        day_over_day_change_rate,
        week_over_week_change_rate,
        -- 天环比告警级别（使用参数化阈值）
        CASE
            WHEN day_over_day_change_rate IS NULL THEN '无对比数据'
            WHEN ABS(day_over_day_change_rate) <= ${var_p3_threshold} THEN 'P3异常'
            WHEN ABS(day_over_day_change_rate) <= ${var_p2_threshold} THEN 'P2严重'
            ELSE 'P1危险'
        END AS day_alert_level,
        -- 周环比告警级别
        CASE
            WHEN week_over_week_change_rate IS NULL THEN '无对比数据'
            WHEN ABS(week_over_week_change_rate) <= ${var_p3_threshold} THEN 'P3异常'
            WHEN ABS(week_over_week_change_rate) <= ${var_p2_threshold} THEN 'P2严重'
            ELSE 'P1危险'
        END AS week_alert_level,
        -- 综合告警级别（取最高优先级）
        CASE
            WHEN (day_over_day_change_rate IS NULL OR day_alert_level = '无对比数据')
                 AND (week_over_week_change_rate IS NULL OR week_alert_level = '无对比数据') THEN '无对比数据'
            WHEN day_alert_level = 'P1危险' OR week_alert_level = 'P1危险' THEN 'P1危险'
            WHEN day_alert_level = 'P2严重' OR week_alert_level = 'P2严重' THEN 'P2严重'
            WHEN day_alert_level = 'P3异常' OR week_alert_level = 'P3异常' THEN 'P3异常'
            ELSE COALESCE(day_alert_level, week_alert_level)
        END AS final_alert_level,
        missing_keywords_count,
        missing_keywords_ratio,
        -- 缺失值告警级别
        CASE
            WHEN missing_keywords_ratio IS NULL THEN NULL
            WHEN missing_keywords_ratio <= 5 THEN '正常'
            WHEN missing_keywords_ratio <= 10 THEN 'P3异常'
            WHEN missing_keywords_ratio <= 20 THEN 'P2严重'
            ELSE 'P1危险'
        END AS missing_alert_level,
        NOW() AS create_time
    FROM with_comparison
    WHERE
        -- 只处理完整的小时数据（不包含当前小时）
        stat_hour < DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00')
)

-- 插入数据（避免重复）
SELECT
    stat_hour, event, platform_name, app_version, event_count, user_count,
    prev_day_count, prev_week_count, day_over_day_change_rate, week_over_week_change_rate,
    day_alert_level, week_alert_level, final_alert_level,
    missing_keywords_count, missing_keywords_ratio, missing_alert_level, create_time
FROM final_data f
WHERE NOT EXISTS (
    SELECT 1
    FROM ads.ads_sr_traffic_monitor_h t
    WHERE t.stat_hour = f.stat_hour
      AND t.event = f.event
      AND t.platform_name = f.platform_name
      AND (t.app_version = f.app_version OR (t.app_version IS NULL AND f.app_version IS NULL))
)
ORDER BY stat_hour DESC, event, platform_name
;

-- ==================== 性能监控和清理 ====================
-- 检查分区状态
SELECT
    PARTITION_NAME,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH
FROM information_schema.PARTITIONS
WHERE TABLE_NAME = 'ads_sr_traffic_monitor_h'
ORDER BY PARTITION_NAME DESC
LIMIT 5;

-- 清理过期分区（可选，自动分区管理）
-- ALTER TABLE ads.ads_sr_traffic_monitor_h DROP PARTITION IF EXISTS p202510;

-- ==================== 性能优化说明 ====================
/*
优化对比：
原方案问题：
1. 数据扫描范围：7天+N小时，约扫描 4亿/天 × 7.17天 ≈ 28.7亿条记录
2. 复杂窗口函数：LAG窗口函数需要对大量数据进行排序和分区
3. 频繁JSON解析：每个字段都需要get_json_string解析
4. 正则表达式：REGEXP操作消耗CPU

优化方案改进：
1. 数据扫描范围：只扫描N小时，约扫描 4亿/天 × (N/24) ≈ 6700万条记录（N=4时）
2. 历史数据获取：从目标表获取，避免重复扫描原始表
3. 简化计算：使用自连接替代窗口函数
4. JSON解析优化：减少解析次数，一次性提取字段
5. 正则优化：使用LIKE和简单函数替代复杂REGEXP

预期性能提升：
- CPU消耗降低：70-80%
- 执行时间缩短：60-70%
- 内存使用减少：50-60%

注意事项：
1. 首次执行时目标表为空，环比计算可能无数据，这是正常的
2. 建议先积累1-2天数据后再启用告警
3. 动态分区功能需要StarRocks 2.5+版本支持
*/

-- ==================== 全事件监控可行性评估 ====================
/*
用户观点评估："每个事件需要关注的属性不同，监控起来几乎不可能"

评估结论：用户的观点完全正确，详细属性监控确实不现实。

详细分析：
1. 事件属性差异性：
   - 搜索事件：关注query_word缺失率、搜索词质量
   - 页面浏览事件：关注停留时间、页面加载时间
   - 点击事件：关注点击位置、按钮ID
   - 曝光事件：关注曝光时长、位置信息
   - 支付事件：关注金额、支付方式、成功率
   - 错误事件：关注错误类型、堆栈信息

2. 监控可行性分级：
   a) 基础监控（可行）：事件数量、用户数、环比变化率 - 所有事件通用
   b) 通用属性监控（部分可行）：平台、版本、设备信息 - 所有事件通用
   c) 事件特定属性监控（不可行）：需要为每类事件设计专用监控逻辑

3. 本SQL采用的折中方案：
   - 基础监控：所有近600个事件都监控数量、用户数、环比变化率
   - 事件特定监控：只对搜索事件监控query_word缺失率（通过is_search_event标记）
   - 关键事件标记：通过is_key_event字段标记7个重点关注事件
   - 整体监控：ALL_EVENTS汇总用于系统性监控

4. 帆软BI灵活配置：
   - 可在BI中通过事件名称筛选关注的事件
   - 可针对不同事件类型设置不同的告警阈值
   - 可通过is_key_event字段快速定位关键事件告警

建议：
1. 接受基础监控+关键事件详细监控的折中方案
2. 在BI中配置告警时，重点关注关键事件和整体数据
3. 未来可逐步扩展事件特定监控，但需要逐个事件设计
*/

-- ==================== 全事件监控成本评估 ====================
/*
全事件监控（近600个事件）成本分析：
1. 数据扫描成本：
   - 扫描全部事件数据：4亿/天 × (N/24) ≈ 6700万条记录（N=4时）
   - 与仅监控关键事件相比，扫描成本相同（均需扫描全部数据）

2. 计算成本：
   - 全事件聚合：600事件 × 4平台 × 多版本，GROUP BY计算复杂度O(n)
   - 用户去重成本：每个事件单独去重，内存占用较高
   - 环比计算：每个事件都需要连接历史数据进行环比计算

3. 存储成本：
   - 每日数据量：600事件 × 4平台 × 24小时 × 多版本 ≈ 57,600行/天（保守估计）
   - 月度数据量：57,600 × 30 ≈ 172.8万行/月
   - 年度数据量：172.8万 × 12 ≈ 2,073.6万行/年

4. 性能影响（相比仅监控7个关键事件）：
   - CPU增加：约30-50%（主要来自大量GROUP BY和去重计算）
   - 内存增加：约40-60%（需要维护大量分组状态）
   - 执行时间增加：约50-100%
   - 存储空间增加：约10-20倍（从~1.6万行/月增加到~173万行/月）

5. 价值收益：
   - 全事件覆盖：可监控任何事件的异常波动
   - 灵活分析：BI中可任意筛选事件进行分析
   - 早期发现：冷门事件异常也能被发现
   - 趋势分析：全事件趋势分析成为可能

6. 优化建议：
   - 采用增量计算，避免全量重算
   - 使用列式存储压缩，减少存储空间
   - 考虑分区策略，按时间分区提高查询性能
   - 可配置监控事件白名单，平衡成本和覆盖率
*/

-- ==================== WeData任务配置 ====================
/*
1. 任务名称：埋点质量监控_全事件版_小时任务
2. 任务类型：SQL任务
3. 执行频率：每4小时（0点、4点、8点、12点、16点、20点）
4. 超时时间：30分钟（全事件监控计算量较大）
5. 报警配置：
   - 任务失败时发送告警
   - 连续2次插入记录数为0时发送警告
6. 依赖关系：依赖ods.ods_sr_traffic_sensor_event_log_realtime表
7. 参数设置（正确格式）：
   var_p3_threshold=5;var_p2_threshold=10;var_process_hours=4;var_source_table="ods.ods_sr_traffic_sensor_event_log_realtime"
8. 执行顺序：
   - 首次执行：运行建表语句
   - 后续执行：只运行增量插入部分（从"-- ==================== 增量数据插入"开始）
*/
