--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2026-04-13
--******************************************************************--
/*
埋点数据监控 - 诊断脚本
目标：诊断搜索事件数据量异常的问题，检查各个过滤条件的影响
*/

-- ==================== 配置参数 ====================
-- 使用与主SQL相同的参数
-- 示例：var_p3_threshold=5;var_p2_threshold=10;var_process_hours=4;var_source_table="ods.ods_sr_traffic_sensor_event_log_realtime"

-- ==================== 诊断查询1：基础数据量检查 ====================
-- 1.1 总数据量（最近N小时）
SELECT
    '总数据量（最近N小时）' AS 检查项,
    COUNT(*) AS 记录数,
    COUNT(DISTINCT distinct_id) AS 用户数,
    COUNT(DISTINCT event) AS 事件类型数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR);

-- 1.2 7个关键事件数据量
SELECT
    '7个关键事件数据量' AS 检查项,
    event AS 事件名称,
    COUNT(*) AS 记录数,
    COUNT(DISTINCT distinct_id) AS 用户数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN (
    'Homepage_Feed_Activity_Ex',
    'Homepage_Feed_Activity_Click',
    'Takeaway_Detailpage_View',
    'Takeaway_Baomingflow_Button_Click',
    'Search_Click',
    'Search_Result_Ex',
    'Search_Result_Click'
  )
GROUP BY event
ORDER BY 记录数 DESC;

-- ==================== 诊断查询2：过滤条件影响分析 ====================
-- 2.1 用户ID过滤影响（distinct_id）
SELECT
    '用户ID过滤影响' AS 检查项,
    '原始数据' AS 过滤状态,
    COUNT(*) AS 总记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

UNION ALL

SELECT
    '用户ID过滤影响',
    '长度1-10位' AS 过滤状态,
    COUNT(*) AS 总记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND LENGTH(distinct_id) BETWEEN 1 AND 10

UNION ALL

SELECT
    '用户ID过滤影响',
    '纯数字ID' AS 过滤状态,
    COUNT(*) AS 总记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND LENGTH(distinct_id) BETWEEN 1 AND 10
  AND distinct_id NOT REGEXP '[^0-9]'

ORDER BY 检查项, 总记录数 DESC;

-- 2.2 平台过滤影响
SELECT
    '平台过滤影响' AS 检查项,
    '原始数据' AS 过滤状态,
    COUNT(*) AS 总记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

UNION ALL

SELECT
    '平台过滤影响',
    '有platform_type字段' AS 过滤状态,
    COUNT(*) AS 总记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND get_json_string(properties, '$.platform_type') IS NOT NULL

UNION ALL

SELECT
    '平台过滤影响',
    '有platform字段' AS 过滤状态,
    COUNT(*) AS 总记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND get_json_string(properties, '$.platform') IS NOT NULL

ORDER BY 检查项, 总记录数 DESC;

-- ==================== 诊断查询3：平台类型分布分析 ====================
-- 3.1 platform_type字段值分布
SELECT
    'platform_type字段值分布' AS 检查项,
    get_json_string(properties, '$.platform_type') AS platform_type原始值,
    COUNT(*) AS 记录数,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS 占比百分比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND get_json_string(properties, '$.platform_type') IS NOT NULL
GROUP BY get_json_string(properties, '$.platform_type')
ORDER BY 记录数 DESC
LIMIT 20;

-- 3.2 platform字段值分布（如果存在）
SELECT
    'platform字段值分布' AS 检查项,
    get_json_string(properties, '$.platform') AS platform原始值,
    COUNT(*) AS 记录数,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS 占比百分比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND get_json_string(properties, '$.platform') IS NOT NULL
GROUP BY get_json_string(properties, '$.platform')
ORDER BY 记录数 DESC
LIMIT 20;

-- 3.3 平台标准化结果
SELECT
    '平台标准化结果' AS 检查项,
    get_json_string(properties, '$.platform_type') AS platform_type原始值,
    CASE
        WHEN LOWER(get_json_string(properties, '$.platform_type')) = 'h5' THEN 'H5'
        WHEN get_json_string(properties, '$.platform_type') LIKE '%小程序%' THEN '微信小程序'
        WHEN LOWER(get_json_string(properties, '$.platform_type')) IN ('android', 'harmony') THEN 'Android'
        WHEN LOWER(get_json_string(properties, '$.platform_type')) = 'ios' THEN 'iOS'
        ELSE get_json_string(properties, '$.platform_type')
    END AS 标准化平台,
    COUNT(*) AS 记录数
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
  AND get_json_string(properties, '$.platform_type') IS NOT NULL
GROUP BY
    get_json_string(properties, '$.platform_type'),
    CASE
        WHEN LOWER(get_json_string(properties, '$.platform_type')) = 'h5' THEN 'H5'
        WHEN get_json_string(properties, '$.platform_type') LIKE '%小程序%' THEN '微信小程序'
        WHEN LOWER(get_json_string(properties, '$.platform_type')) IN ('android', 'harmony') THEN 'Android'
        WHEN LOWER(get_json_string(properties, '$.platform_type')) = 'ios' THEN 'iOS'
        ELSE get_json_string(properties, '$.platform_type')
    END
ORDER BY 记录数 DESC
LIMIT 20;

-- ==================== 诊断查询4：app_version字段检查 ====================
-- 4.1 app_version字段提取
SELECT
    'app_version字段提取' AS 检查项,
    '使用$.app_version' AS 提取方式,
    COUNT(CASE WHEN get_json_string(properties, '$.app_version') IS NOT NULL THEN 1 END) AS 非空记录数,
    COUNT(CASE WHEN get_json_string(properties, '$.app_version') IS NULL THEN 1 END) AS 空记录数,
    ROUND(COUNT(CASE WHEN get_json_string(properties, '$.app_version') IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS 非空占比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

UNION ALL

SELECT
    'app_version字段提取',
    '使用$.$app_version' AS 提取方式,
    COUNT(CASE WHEN get_json_string(properties, '$.$app_version') IS NOT NULL THEN 1 END) AS 非空记录数,
    COUNT(CASE WHEN get_json_string(properties, '$.$app_version') IS NULL THEN 1 END) AS 空记录数,
    ROUND(COUNT(CASE WHEN get_json_string(properties, '$.$app_version') IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS 非空占比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

ORDER BY 检查项, 非空记录数 DESC;

-- ==================== 诊断查询5：搜索关键词字段检查 ====================
-- 5.1 query_word字段检查
SELECT
    'query_word字段检查' AS 检查项,
    event AS 事件名称,
    COUNT(*) AS 总记录数,
    COUNT(CASE WHEN get_json_string(properties, '$.query_word') IS NOT NULL AND get_json_string(properties, '$.query_word') != '' THEN 1 END) AS 有搜索关键词记录数,
    COUNT(CASE WHEN get_json_string(properties, '$.query_word') IS NULL OR get_json_string(properties, '$.query_word') = '' THEN 1 END) AS 无搜索关键词记录数,
    ROUND(COUNT(CASE WHEN get_json_string(properties, '$.query_word') IS NULL OR get_json_string(properties, '$.query_word') = '' THEN 1 END) * 100.0 / COUNT(*), 2) AS 缺失率百分比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
GROUP BY event
ORDER BY 总记录数 DESC;

-- 5.2 其他可能的搜索关键词字段
SELECT
    '其他搜索关键词字段' AS 检查项,
    '$.query' AS 字段名,
    COUNT(CASE WHEN get_json_string(properties, '$.query') IS NOT NULL THEN 1 END) AS 非空记录数,
    COUNT(*) AS 总记录数,
    ROUND(COUNT(CASE WHEN get_json_string(properties, '$.query') IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS 非空占比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

UNION ALL

SELECT
    '其他搜索关键词字段',
    '$.keyword' AS 字段名,
    COUNT(CASE WHEN get_json_string(properties, '$.keyword') IS NOT NULL THEN 1 END) AS 非空记录数,
    COUNT(*) AS 总记录数,
    ROUND(COUNT(CASE WHEN get_json_string(properties, '$.keyword') IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS 非空占比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

UNION ALL

SELECT
    '其他搜索关键词字段',
    '$.search_word' AS 字段名,
    COUNT(CASE WHEN get_json_string(properties, '$.search_word') IS NOT NULL THEN 1 END) AS 非空记录数,
    COUNT(*) AS 总记录数,
    ROUND(COUNT(CASE WHEN get_json_string(properties, '$.search_word') IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS 非空占比
FROM ${var_source_table}
WHERE time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
  AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')

ORDER BY 非空记录数 DESC;

-- ==================== 诊断查询6：完整过滤路径模拟 ====================
-- 6.1 模拟主SQL的过滤逻辑
WITH filtered_data AS (
    SELECT
        time,
        event,
        distinct_id,
        get_json_string(properties, '$.platform_type') AS raw_platform_type,
        get_json_string(properties, '$.app_version') AS app_version,
        get_json_string(properties, '$.query_word') AS query_word
    FROM ${var_source_table}
    WHERE
        time >= DATE_SUB(NOW(), INTERVAL ${var_process_hours} HOUR)
        AND event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
        AND LENGTH(distinct_id) BETWEEN 1 AND 10
        AND distinct_id NOT REGEXP '[^0-9]'
        AND get_json_string(properties, '$.platform_type') IS NOT NULL
)
SELECT
    '完整过滤结果' AS 检查项,
    event AS 事件名称,
    DATE_FORMAT(time, '%Y-%m-%d %H:00:00') AS 统计小时,
    CASE
        WHEN LOWER(raw_platform_type) = 'h5' THEN 'H5'
        WHEN raw_platform_type LIKE '%小程序%' THEN '微信小程序'
        WHEN LOWER(raw_platform_type) IN ('android', 'harmony') THEN 'Android'
        WHEN LOWER(raw_platform_type) = 'ios' THEN 'iOS'
        ELSE raw_platform_type
    END AS 标准化平台,
    COUNT(*) AS 事件数量,
    COUNT(DISTINCT distinct_id) AS 用户数
FROM filtered_data
GROUP BY
    event,
    DATE_FORMAT(time, '%Y-%m-%d %H:00:00'),
    CASE
        WHEN LOWER(raw_platform_type) = 'h5' THEN 'H5'
        WHEN raw_platform_type LIKE '%小程序%' THEN '微信小程序'
        WHEN LOWER(raw_platform_type) IN ('android', 'harmony') THEN 'Android'
        WHEN LOWER(raw_platform_type) = 'ios' THEN 'iOS'
        ELSE raw_platform_type
    END
ORDER BY 统计小时 DESC, 事件名称, 标准化平台;

-- ==================== 使用说明 ====================
/*
使用步骤：
1. 在WeData中创建诊断任务，使用与主SQL相同的参数
2. 依次执行各个诊断查询，分析过滤条件的影响
3. 重点关注：
   a) 用户ID过滤：检查纯数字ID是否过滤掉大量数据
   b) 平台过滤：检查platform_type字段是否存在，平台值分布是否合理
   c) app_version字段：检查提取路径是否正确
   d) query_word字段：检查搜索关键词字段名是否正确

常见问题诊断：
1. 如果用户ID过滤后数据量大减：检查distinct_id字段实际格式
2. 如果平台过滤后数据量大减：检查platform_type字段是否存在，或尝试使用其他字段名
3. 如果平台标准化结果异常：检查平台原始值分布，调整CASE逻辑
4. 如果搜索事件数据量仍异常：检查query_word字段名，搜索事件定义是否正确
*/
