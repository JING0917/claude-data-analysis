-- 小蚕首页feed流转化率分析 - 晓晓 vs 小蚕对比
-- 数据来源: dws.dws_sr_traffic_homepage_mix_ascribe_d
-- 时间范围: 最近30天
-- 分析维度: 日期、区县、平台、版本、活动类型

-- ============================================================================
-- 1. 基础日级别汇总查询 (用于平台/版本分布分析)
-- ============================================================================

-- 查询1.1: 整体转化率对比 - UNION ALL方案 (分别统计，合并展示)
-- 方案A: 分别统计小蚕活动和晓晓活动，然后合并
SELECT
    statistics_date AS 统计日期,
    '小蚕活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,
    SUM(baoming_order_num) AS 报名订单量,
    SUM(valid_order_num) AS 有效订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 点击转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
GROUP BY statistics_date

UNION ALL

SELECT
    statistics_date AS 统计日期,
    '晓晓活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,
    SUM(xx_baoming_order_num) AS 报名订单量,
    SUM(xx_valid_order_num) AS 有效订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 点击转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
GROUP BY statistics_date

ORDER BY 统计日期 DESC, 活动类型;

-- 查询1.2: 整体转化率对比 - JOIN方案 (同一行对比差异)
-- 方案B: 通过JOIN在同一行对比小蚕和晓晓的差异
SELECT
    COALESCE(a.statistics_date, b.statistics_date) AS 统计日期,
    COALESCE(a.点击量, 0) AS 小蚕点击量,
    COALESCE(a.报名订单量, 0) AS 小蚕报名订单量,
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 小蚕转化率百分比,
    COALESCE(b.点击量, 0) AS 晓晓点击量,
    COALESCE(b.报名订单量, 0) AS 晓晓报名订单量,
    ROUND(COALESCE(b.报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.点击量, 0), 0), 2) AS 晓晓转化率百分比,
    ROUND(COALESCE(b.报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.点击量, 0), 0), 2) -
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 转化率差异百分比
FROM (
    SELECT
        statistics_date,
        SUM(clc_num) AS 点击量,
        SUM(baoming_order_num) AS 报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
    GROUP BY statistics_date
) a
FULL OUTER JOIN (
    SELECT
        statistics_date,
        SUM(clc_num) AS 点击量,
        SUM(xx_baoming_order_num) AS 报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
    GROUP BY statistics_date
) b ON a.statistics_date = b.statistics_date
ORDER BY COALESCE(a.statistics_date, b.statistics_date) DESC;

-- ============================================================================
-- 2. 平台分布分析
-- ============================================================================

-- 查询2.1: 平台分布分析 - UNION ALL方案 (分别统计，合并展示)
SELECT
    platform_name AS 平台名称,
    '小蚕活动' AS 活动类型,
    COUNT(DISTINCT statistics_date) AS 有效天数,
    SUM(clc_num) AS 总点击量,
    SUM(baoming_order_num) AS 总报名订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 整体转化率百分比,
    ROUND(SUM(clc_num) * 100.0 / SUM(SUM(clc_num)) OVER (PARTITION BY '小蚕活动'), 2) AS 点击量占比百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
GROUP BY platform_name

UNION ALL

SELECT
    platform_name AS 平台名称,
    '晓晓活动' AS 活动类型,
    COUNT(DISTINCT statistics_date) AS 有效天数,
    SUM(clc_num) AS 总点击量,
    SUM(xx_baoming_order_num) AS 总报名订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 整体转化率百分比,
    ROUND(SUM(clc_num) * 100.0 / SUM(SUM(clc_num)) OVER (PARTITION BY '晓晓活动'), 2) AS 点击量占比百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
GROUP BY platform_name

ORDER BY 活动类型, 整体转化率百分比 DESC;

-- 查询2.2: 平台分布分析 - JOIN方案 (同一行对比差异)
SELECT
    COALESCE(a.platform_name, b.platform_name) AS 平台名称,
    COALESCE(a.总点击量, 0) AS 小蚕点击量,
    COALESCE(a.总报名订单量, 0) AS 小蚕订单量,
    ROUND(COALESCE(a.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.总点击量, 0), 0), 2) AS 小蚕转化率百分比,
    COALESCE(b.总点击量, 0) AS 晓晓点击量,
    COALESCE(b.总报名订单量, 0) AS 晓晓订单量,
    ROUND(COALESCE(b.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.总点击量, 0), 0), 2) AS 晓晓转化率百分比,
    ROUND(COALESCE(b.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.总点击量, 0), 0), 2) -
    ROUND(COALESCE(a.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.总点击量, 0), 0), 2) AS 转化率差异百分比,
    ROUND(COALESCE(a.总点击量, 0) * 100.0 / NULLIF(SUM(COALESCE(a.总点击量, 0)) OVER (), 0), 2) AS 小蚕点击量占比,
    ROUND(COALESCE(b.总点击量, 0) * 100.0 / NULLIF(SUM(COALESCE(b.总点击量, 0)) OVER (), 0), 2) AS 晓晓点击量占比
FROM (
    SELECT
        platform_name,
        COUNT(DISTINCT statistics_date) AS 有效天数,
        SUM(clc_num) AS 总点击量,
        SUM(baoming_order_num) AS 总报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
        AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
    GROUP BY platform_name
) a
FULL OUTER JOIN (
    SELECT
        platform_name,
        COUNT(DISTINCT statistics_date) AS 有效天数,
        SUM(clc_num) AS 总点击量,
        SUM(xx_baoming_order_num) AS 总报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
        AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
    GROUP BY platform_name
) b ON a.platform_name = b.platform_name
ORDER BY COALESCE(a.platform_name, b.platform_name);

-- ============================================================================
-- 3. 版本分布分析 (需要先了解版本格式)
-- ============================================================================

-- 查询3.1: 版本分布分析 - UNION ALL方案 (分别统计，合并展示)
SELECT
    app_version AS APP版本,
    '小蚕活动' AS 活动类型,
    COUNT(DISTINCT statistics_date) AS 有效天数,
    SUM(clc_num) AS 总点击量,
    SUM(baoming_order_num) AS 总报名订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比,
    ROUND(SUM(clc_num) * 100.0 / SUM(SUM(clc_num)) OVER (PARTITION BY '小蚕活动'), 2) AS 点击量占比百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
    AND app_version != '未知'  -- 过滤未知版本
GROUP BY app_version
HAVING SUM(clc_num) >= 100  -- 只分析有一定样本量的版本

UNION ALL

SELECT
    app_version AS APP版本,
    '晓晓活动' AS 活动类型,
    COUNT(DISTINCT statistics_date) AS 有效天数,
    SUM(clc_num) AS 总点击量,
    SUM(xx_baoming_order_num) AS 总报名订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比,
    ROUND(SUM(clc_num) * 100.0 / SUM(SUM(clc_num)) OVER (PARTITION BY '晓晓活动'), 2) AS 点击量占比百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
    AND app_version != '未知'  -- 过滤未知版本
GROUP BY app_version
HAVING SUM(clc_num) >= 100  -- 只分析有一定样本量的版本

ORDER BY 活动类型, 转化率百分比 DESC;

-- 查询3.2: 版本分布分析 - JOIN方案 (同一行对比差异)
SELECT
    COALESCE(a.app_version, b.app_version) AS APP版本,
    COALESCE(a.总点击量, 0) AS 小蚕点击量,
    COALESCE(a.总报名订单量, 0) AS 小蚕订单量,
    ROUND(COALESCE(a.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.总点击量, 0), 0), 2) AS 小蚕转化率百分比,
    COALESCE(b.总点击量, 0) AS 晓晓点击量,
    COALESCE(b.总报名订单量, 0) AS 晓晓订单量,
    ROUND(COALESCE(b.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.总点击量, 0), 0), 2) AS 晓晓转化率百分比,
    ROUND(COALESCE(b.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.总点击量, 0), 0), 2) -
    ROUND(COALESCE(a.总报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.总点击量, 0), 0), 2) AS 转化率差异百分比
FROM (
    SELECT
        app_version,
        COUNT(DISTINCT statistics_date) AS 有效天数,
        SUM(clc_num) AS 总点击量,
        SUM(baoming_order_num) AS 总报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
        AND app_version != '未知'
    GROUP BY app_version
    HAVING SUM(clc_num) >= 100
) a
FULL OUTER JOIN (
    SELECT
        app_version,
        COUNT(DISTINCT statistics_date) AS 有效天数,
        SUM(clc_num) AS 总点击量,
        SUM(xx_baoming_order_num) AS 总报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
        AND app_version != '未知'
    GROUP BY app_version
    HAVING SUM(clc_num) >= 100
) b ON a.app_version = b.app_version
WHERE COALESCE(a.总点击量, 0) + COALESCE(b.总点击量, 0) > 0
ORDER BY COALESCE(a.app_version, b.app_version);

-- ============================================================================
-- 4. 地域分布分析 (区县级)
-- ============================================================================

-- 查询4.1: 地域分布分析 - UNION ALL方案 (分别统计，合并展示)
SELECT
    county_id AS 区县ID,
    '小蚕活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(baoming_order_num) AS 报名订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
GROUP BY county_id
HAVING SUM(clc_num) >= 50  -- 只分析有一定点击量的区县

UNION ALL

SELECT
    county_id AS 区县ID,
    '晓晓活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(xx_baoming_order_num) AS 报名订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
GROUP BY county_id
HAVING SUM(clc_num) >= 50  -- 只分析有一定点击量的区县

ORDER BY 转化率百分比 DESC
LIMIT 20;

-- 查询4.2: 地域分布分析 - JOIN方案 (同一行对比差异，TOP20)
SELECT
    COALESCE(a.county_id, b.county_id) AS 区县ID,
    COALESCE(a.点击量, 0) AS 小蚕点击量,
    COALESCE(a.报名订单量, 0) AS 小蚕订单量,
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 小蚕转化率百分比,
    COALESCE(b.点击量, 0) AS 晓晓点击量,
    COALESCE(b.报名订单量, 0) AS 晓晓订单量,
    ROUND(COALESCE(b.报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.点击量, 0), 0), 2) AS 晓晓转化率百分比,
    ROUND(COALESCE(b.报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.点击量, 0), 0), 2) -
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 转化率差异百分比
FROM (
    SELECT
        county_id,
        SUM(clc_num) AS 点击量,
        SUM(baoming_order_num) AS 报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
    GROUP BY county_id
    HAVING SUM(clc_num) >= 50
) a
FULL OUTER JOIN (
    SELECT
        county_id,
        SUM(clc_num) AS 点击量,
        SUM(xx_baoming_order_num) AS 报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
    GROUP BY county_id
    HAVING SUM(clc_num) >= 50
) b ON a.county_id = b.county_id
WHERE COALESCE(a.点击量, 0) + COALESCE(b.点击量, 0) > 0
ORDER BY 转化率差异百分比 DESC
LIMIT 20;

-- ============================================================================
-- 5. 用户重合度分析 (使用bitmap函数)
-- ============================================================================

-- 查询5: 用户点击行为分析 (整体)
-- 使用unnest_bitmap函数展开bitmap字段clc_uids获取用户ID
-- 正确语法: FROM table, unnest_bitmap(clc_uids) AS uid

-- 方案: 使用UNION ALL分别统计各类用户
-- 只点击晓晓的用户数
SELECT
    '只点击晓晓' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid AS user_id, activity_type
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) AS uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
        AND clc_num > 0
    GROUP BY uid, activity_type
    HAVING SUM(CASE WHEN activity_type IN ('小蚕活动', '站内活动') THEN 1 ELSE 0 END) = 0
) t1

UNION ALL

-- 只点击小蚕的用户数
SELECT
    '只点击小蚕' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid AS user_id, activity_type
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) AS uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
        AND clc_num > 0
    GROUP BY uid, activity_type
    HAVING SUM(CASE WHEN activity_type = '晓晓活动' THEN 1 ELSE 0 END) = 0
) t2

UNION ALL

-- 两者都点击的用户数
SELECT
    '两者都点击' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid AS user_id, activity_type
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) AS uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
        AND clc_num > 0
    GROUP BY uid, activity_type
    HAVING COUNT(DISTINCT CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE NULL END) = 2
) t3

UNION ALL

-- 总体用户数 (用于计算比例)
SELECT
    '总体用户' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid AS user_id
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) AS uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
        AND clc_num > 0
) t4

ORDER BY 用户类型;

-- ============================================================================
-- 6. 漏斗转化分析
-- ============================================================================

-- 查询6: 行为漏斗对比 - UNION ALL方案 (最适合此场景)
SELECT
    '小蚕活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,
    SUM(baoming_order_num) AS 报名订单量,
    ROUND(SUM(detailpage_pv) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 点击到详情页转化率百分比,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(detailpage_pv), 0), 2) AS 详情页到报名转化率百分比,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 整体转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')

UNION ALL

SELECT
    '晓晓活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,
    SUM(xx_baoming_order_num) AS 报名订单量,
    ROUND(SUM(detailpage_pv) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 点击到详情页转化率百分比,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(detailpage_pv), 0), 2) AS 详情页到报名转化率百分比,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 整体转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'

ORDER BY 活动类型;

-- ============================================================================
-- 7. 趋势分析 (最近30天每日趋势)
-- ============================================================================

-- 查询7.1: 每日转化率趋势 - UNION ALL方案 (分别统计，合并展示)
SELECT
    statistics_date AS 统计日期,
    '小蚕活动' AS 活动类型,
    SUM(clc_num) AS 日点击量,
    SUM(baoming_order_num) AS 日报名订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 日转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
GROUP BY statistics_date

UNION ALL

SELECT
    statistics_date AS 统计日期,
    '晓晓活动' AS 活动类型,
    SUM(clc_num) AS 日点击量,
    SUM(xx_baoming_order_num) AS 日报名订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 日转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
GROUP BY statistics_date

ORDER BY 统计日期 DESC, 活动类型;

-- 查询7.2: 每日转化率趋势 - JOIN方案 (同一行对比差异)
SELECT
    COALESCE(a.statistics_date, b.statistics_date) AS 统计日期,
    COALESCE(a.日点击量, 0) AS 小蚕日点击量,
    COALESCE(a.日报名订单量, 0) AS 小蚕日订单量,
    ROUND(COALESCE(a.日报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.日点击量, 0), 0), 2) AS 小蚕日转化率百分比,
    COALESCE(b.日点击量, 0) AS 晓晓日点击量,
    COALESCE(b.日报名订单量, 0) AS 晓晓日订单量,
    ROUND(COALESCE(b.日报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.日点击量, 0), 0), 2) AS 晓晓日转化率百分比,
    ROUND(COALESCE(b.日报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.日点击量, 0), 0), 2) -
    ROUND(COALESCE(a.日报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.日点击量, 0), 0), 2) AS 日转化率差异百分比
FROM (
    SELECT
        statistics_date,
        SUM(clc_num) AS 日点击量,
        SUM(baoming_order_num) AS 日报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
    GROUP BY statistics_date
) a
FULL OUTER JOIN (
    SELECT
        statistics_date,
        SUM(clc_num) AS 日点击量,
        SUM(xx_baoming_order_num) AS 日报名订单量
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
    GROUP BY statistics_date
) b ON a.statistics_date = b.statistics_date
ORDER BY COALESCE(a.statistics_date, b.statistics_date) DESC;

-- ============================================================================
-- 8. 用户级别数据提取 (用于用户重合度分析)
-- ============================================================================

-- 注意: 用户ID存储在bitmap字段中，提取需要特殊处理
-- 以下查询需要根据实际的bitmap函数支持情况调整

-- 查询8.1: 聚合用户行为数据 (避免数据爆炸) - UNION ALL方案
-- 按活动类型、日期、平台、区县聚合，排除APP版本维度，添加点击量阈值
SELECT
    statistics_date AS 统计日期,
    county_id AS 区县ID,
    platform_name AS 平台名称,
    '小蚕活动' AS 活动类型,
    COUNT(*) AS 数据单元数,
    SUM(clc_num) AS 总点击量,
    SUM(detailpage_pv) AS 总详情页PV,
    SUM(baoming_order_num) AS 总报名订单量,
    SUM(valid_order_num) AS 总有效订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
    AND clc_num > 0
GROUP BY statistics_date, county_id, platform_name
HAVING SUM(clc_num) >= 10  -- 只保留有一定点击量的组合

UNION ALL

SELECT
    statistics_date AS 统计日期,
    county_id AS 区县ID,
    platform_name AS 平台名称,
    '晓晓活动' AS 活动类型,
    COUNT(*) AS 数据单元数,
    SUM(clc_num) AS 总点击量,
    SUM(detailpage_pv) AS 总详情页PV,
    SUM(xx_baoming_order_num) AS 总报名订单量,
    SUM(xx_valid_order_num) AS 总有效订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
    AND clc_num > 0
GROUP BY statistics_date, county_id, platform_name
HAVING SUM(clc_num) >= 10  -- 只保留有一定点击量的组合

ORDER BY 统计日期 DESC, 区县ID, 平台名称;

-- 查询8.2: 用户重合度基础统计 (使用bitmap函数 - 高级用法)
-- 注意: 以下查询需要数据库支持bitmap_union、bitmap_contains等高级bitmap函数
-- 如果数据库不支持，请使用查询5的unnest_bitmap方法

/*
-- 8.2.1 使用bitmap函数高效计算用户重合度
WITH user_activity_bitmaps AS (
    SELECT
        activity_type,
        bitmap_union(clc_uids) AS user_bitmap
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND clc_num > 0
        AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
    GROUP BY activity_type
),
xiaocan_users AS (
    SELECT user_bitmap FROM user_activity_bitmaps
    WHERE activity_type IN ('小蚕活动', '站内活动')
),
xiaoxiao_users AS (
    SELECT user_bitmap FROM user_activity_bitmaps
    WHERE activity_type = '晓晓活动'
)
SELECT
    '只点击晓晓' AS 用户类型,
    bitmap_count(bitmap_andnot(
        (SELECT user_bitmap FROM xiaoxiao_users),
        (SELECT user_bitmap FROM xiaocan_users)
    )) AS 用户数
UNION ALL
SELECT
    '只点击小蚕' AS 用户类型,
    bitmap_count(bitmap_andnot(
        (SELECT user_bitmap FROM xiaocan_users),
        (SELECT user_bitmap FROM xiaoxiao_users)
    )) AS 用户数
UNION ALL
SELECT
    '两者都点击' AS 用户类型,
    bitmap_count(bitmap_and(
        (SELECT user_bitmap FROM xiaocan_users),
        (SELECT user_bitmap FROM xiaoxiao_users)
    )) AS 用户数
UNION ALL
SELECT
    '总体用户' AS 用户类型,
    bitmap_count(bitmap_or(
        (SELECT user_bitmap FROM xiaocan_users),
        (SELECT user_bitmap FROM xiaoxiao_users)
    )) AS 用户数
ORDER BY 用户类型;
*/

-- 查询8.3: 简化版用户重合度分析 (基于聚合数据) - UNION ALL方案
SELECT
    '小蚕活动' AS 活动类型,
    COUNT(DISTINCT CONCAT(statistics_date, '_', county_id, '_', platform_name, '_', app_version)) AS 数据单元数,
    SUM(clc_num) AS 总点击量,
    SUM(baoming_order_num) AS 总订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
    AND clc_num > 0

UNION ALL

SELECT
    '晓晓活动' AS 活动类型,
    COUNT(DISTINCT CONCAT(statistics_date, '_', county_id, '_', platform_name, '_', app_version)) AS 数据单元数,
    SUM(clc_num) AS 总点击量,
    SUM(xx_baoming_order_num) AS 总订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
    AND clc_num > 0

ORDER BY 活动类型;

-- 查询8.4: 平台维度的用户行为对比 - UNION ALL方案
SELECT
    platform_name AS 平台名称,
    '小蚕活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(baoming_order_num) AS 订单量,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比,
    ROUND(SUM(clc_num) * 100.0 / SUM(SUM(clc_num)) OVER (PARTITION BY '小蚕活动'), 2) AS 点击量占比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动')
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
GROUP BY platform_name

UNION ALL

SELECT
    platform_name AS 平台名称,
    '晓晓活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(xx_baoming_order_num) AS 订单量,
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 转化率百分比,
    ROUND(SUM(clc_num) * 100.0 / SUM(SUM(clc_num)) OVER (PARTITION BY '晓晓活动'), 2) AS 点击量占比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
GROUP BY platform_name

ORDER BY 活动类型, 转化率百分比 DESC;