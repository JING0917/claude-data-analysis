-- 小蚕首页feed流转化率分析 - 晓晓 vs 小蚕对比
-- 按照用户提供的SQL结构重构：分别统计数据，再关联
-- 数据来源: dws.dws_sr_traffic_homepage_mix_ascribe_d
-- 时间范围: 最近30天
-- 分析维度: 日期、区县、平台、版本、活动类型

-- ============================================================================
-- 1. 基础日级别汇总查询 (整体对比)
-- ============================================================================

-- 查询1: 整体转化率对比 (日级别)
SELECT
    a.statistics_date AS 统计日期,
    -- 小蚕活动指标
    a.点击量 AS 小蚕点击量,
    a.详情页PV AS 小蚕详情页PV,
    a.报名订单量 AS 小蚕报名订单量,
    a.有效订单量 AS 小蚕有效订单量,
    ROUND(a.报名订单量 * 100.0 / NULLIF(a.点击量, 0), 2) AS 小蚕点击转化率百分比,
    -- 小蚕用户量指标（UV）
    a.点击UV AS 小蚕点击UV,
    a.详情页浏览UV AS 小蚕详情页浏览UV,
    ROUND(a.详情页浏览UV * 100.0 / NULLIF(a.点击UV, 0), 2) AS 小蚕UV转化率百分比,

    -- 晓晓活动指标
    b.晓晓点击量 AS 晓晓点击量,
    b.晓晓详情页PV AS 晓晓详情页PV,
    b.晓晓报名订单量 AS 晓晓报名订单量,
    b.晓晓有效订单量 AS 晓晓有效订单量,
    ROUND(b.晓晓报名订单量 * 100.0 / NULLIF(b.晓晓点击量, 0), 2) AS 晓晓点击转化率百分比,
    -- 晓晓用户量指标（UV）
    b.晓晓点击UV AS 晓晓点击UV,
    b.晓晓详情页浏览UV AS 晓晓详情页浏览UV,
    ROUND(b.晓晓详情页浏览UV * 100.0 / NULLIF(b.晓晓点击UV, 0), 2) AS 晓晓UV转化率百分比,

    -- 总体指标
    c.总点击量 AS 总点击量,
    c.总报名订单量 AS 总报名订单量,
    ROUND(c.总报名订单量 * 100.0 / NULLIF(c.总点击量, 0), 2) AS 总点击转化率百分比,
    -- 总体用户量指标（UV）
    c.总点击UV AS 总点击UV,
    c.总详情页浏览UV AS 总详情页浏览UV,
    ROUND(c.总详情页浏览UV * 100.0 / NULLIF(c.总点击UV, 0), 2) AS 总UV转化率百分比,

    -- 差异对比
    ROUND(b.晓晓报名订单量 * 100.0 / NULLIF(b.晓晓点击量, 0), 2) -
    ROUND(a.报名订单量 * 100.0 / NULLIF(a.点击量, 0), 2) AS 转化率差异百分比,
    -- UV转化率差异
    ROUND(b.晓晓详情页浏览UV * 100.0 / NULLIF(b.晓晓点击UV, 0), 2) -
    ROUND(a.详情页浏览UV * 100.0 / NULLIF(a.点击UV, 0), 2) AS UV转化率差异百分比

FROM
    -- 小蚕活动数据
    (SELECT
        statistics_date,
        SUM(clc_num) AS 点击量,
        SUM(detailpage_pv) AS 详情页PV,
        SUM(baoming_order_num) AS 报名订单量,
        SUM(valid_order_num) AS 有效订单量,
        -- 用户量指标（UV）- 使用bitmap函数
        bitmap_union_count(clc_uids) AS 点击UV,
        bitmap_union_count(detailpage_view_uids) AS 详情页浏览UV
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')
     GROUP BY statistics_date) a

LEFT JOIN
    -- 晓晓活动数据
    (SELECT
        statistics_date,
        SUM(clc_num) AS 晓晓点击量,
        SUM(detailpage_pv) AS 晓晓详情页PV,
        SUM(xx_baoming_order_num) AS 晓晓报名订单量,
        SUM(xx_valid_order_num) AS 晓晓有效订单量,
        -- 用户量指标（UV）- 使用bitmap函数
        bitmap_union_count(clc_uids) AS 晓晓点击UV,
        bitmap_union_count(detailpage_view_uids) AS 晓晓详情页浏览UV
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动'
     GROUP BY statistics_date) b ON a.statistics_date = b.statistics_date

LEFT JOIN
    -- 总体数据
    (SELECT
        statistics_date,
        SUM(clc_num) AS 总点击量,
        SUM(CASE WHEN activity_type = '小蚕活动' THEN baoming_order_num
                WHEN activity_type = '晓晓活动' THEN xx_baoming_order_num
                ELSE 0 END) AS 总报名订单量,
        -- 用户量指标（UV）- 使用bitmap函数
        bitmap_union_count(clc_uids) AS 总点击UV,
        bitmap_union_count(detailpage_view_uids) AS 总详情页浏览UV
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
     GROUP BY statistics_date) c ON a.statistics_date = c.statistics_date

ORDER BY a.statistics_date DESC;

-- ============================================================================
-- 2. 平台分布分析
-- ============================================================================

-- 查询2: 按平台分组的转化率对比
SELECT
    COALESCE(a.platform_name, b.platform_name) AS 平台名称,

    -- 小蚕活动指标
    COALESCE(a.点击量, 0) AS 小蚕点击量,
    COALESCE(a.报名订单量, 0) AS 小蚕报名订单量,
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 小蚕转化率百分比,
    -- 小蚕用户量指标（UV）
    COALESCE(a.点击UV, 0) AS 小蚕点击UV,
    COALESCE(a.详情页浏览UV, 0) AS 小蚕详情页浏览UV,
    ROUND(COALESCE(a.详情页浏览UV, 0) * 100.0 / NULLIF(COALESCE(a.点击UV, 0), 0), 2) AS 小蚕UV转化率百分比,

    -- 晓晓活动指标
    COALESCE(b.晓晓点击量, 0) AS 晓晓点击量,
    COALESCE(b.晓晓报名订单量, 0) AS 晓晓报名订单量,
    ROUND(COALESCE(b.晓晓报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击量, 0), 0), 2) AS 晓晓转化率百分比,
    -- 晓晓用户量指标（UV）
    COALESCE(b.晓晓点击UV, 0) AS 晓晓点击UV,
    COALESCE(b.晓晓详情页浏览UV, 0) AS 晓晓详情页浏览UV,
    ROUND(COALESCE(b.晓晓详情页浏览UV, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击UV, 0), 0), 2) AS 晓晓UV转化率百分比,

    -- 差异对比
    ROUND(COALESCE(b.晓晓报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击量, 0), 0), 2) -
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 转化率差异百分比,
    -- UV转化率差异
    ROUND(COALESCE(b.晓晓详情页浏览UV, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击UV, 0), 0), 2) -
    ROUND(COALESCE(a.详情页浏览UV, 0) * 100.0 / NULLIF(COALESCE(a.点击UV, 0), 0), 2) AS UV转化率差异百分比,

    -- 点击量占比
    ROUND(COALESCE(a.点击量, 0) * 100.0 / NULLIF(SUM(COALESCE(a.点击量, 0)) OVER (), 0), 2) AS 小蚕点击量占比百分比,
    ROUND(COALESCE(b.晓晓点击量, 0) * 100.0 / NULLIF(SUM(COALESCE(b.晓晓点击量, 0)) OVER (), 0), 2) AS 晓晓点击量占比百分比

FROM
    -- 小蚕活动平台数据
    (SELECT
        platform_name,
        SUM(clc_num) AS 点击量,
        SUM(baoming_order_num) AS 报名订单量,
        -- 用户量指标（UV）- 使用bitmap函数
        bitmap_union_count(clc_uids) AS 点击UV,
        bitmap_union_count(detailpage_view_uids) AS 详情页浏览UV
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')
         AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
     GROUP BY platform_name) a

FULL OUTER JOIN
    -- 晓晓活动平台数据
    (SELECT
        platform_name,
        SUM(clc_num) AS 晓晓点击量,
        SUM(xx_baoming_order_num) AS 晓晓报名订单量,
        -- 用户量指标（UV）- 使用bitmap函数
        bitmap_union_count(clc_uids) AS 晓晓点击UV,
        bitmap_union_count(detailpage_view_uids) AS 晓晓详情页浏览UV
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动'
         AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
     GROUP BY platform_name) b ON a.platform_name = b.platform_name

ORDER BY COALESCE(a.platform_name, b.platform_name);

-- ============================================================================
-- 3. 版本分布分析
-- ============================================================================

-- 查询3: 按APP版本分组的转化率
SELECT
    COALESCE(a.app_version, b.app_version) AS APP版本,

    -- 小蚕活动指标
    COALESCE(a.点击量, 0) AS 小蚕点击量,
    COALESCE(a.报名订单量, 0) AS 小蚕报名订单量,
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 小蚕转化率百分比,

    -- 晓晓活动指标
    COALESCE(b.晓晓点击量, 0) AS 晓晓点击量,
    COALESCE(b.晓晓报名订单量, 0) AS 晓晓报名订单量,
    ROUND(COALESCE(b.晓晓报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击量, 0), 0), 2) AS 晓晓转化率百分比,

    -- 差异对比
    ROUND(COALESCE(b.晓晓报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击量, 0), 0), 2) -
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 转化率差异百分比

FROM
    -- 小蚕活动版本数据
    (SELECT
        app_version,
        SUM(clc_num) AS 点击量,
        SUM(baoming_order_num) AS 报名订单量
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')
         AND app_version != '未知'
     GROUP BY app_version
     HAVING SUM(clc_num) >= 100) a

FULL OUTER JOIN
    -- 晓晓活动版本数据
    (SELECT
        app_version,
        SUM(clc_num) AS 晓晓点击量,
        SUM(xx_baoming_order_num) AS 晓晓报名订单量
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动'
         AND app_version != '未知'
     GROUP BY app_version
     HAVING SUM(clc_num) >= 100) b ON a.app_version = b.app_version

WHERE COALESCE(a.点击量, 0) + COALESCE(b.晓晓点击量, 0) > 0
ORDER BY COALESCE(a.app_version, b.app_version);

-- ============================================================================
-- 4. 地域分布分析 (区县级)
-- ============================================================================

-- 查询4: 高转化区县TOP20
SELECT
    COALESCE(a.county_id, b.county_id) AS 区县ID,

    -- 小蚕活动指标
    COALESCE(a.点击量, 0) AS 小蚕点击量,
    COALESCE(a.报名订单量, 0) AS 小蚕报名订单量,
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 小蚕转化率百分比,

    -- 晓晓活动指标
    COALESCE(b.晓晓点击量, 0) AS 晓晓点击量,
    COALESCE(b.晓晓报名订单量, 0) AS 晓晓报名订单量,
    ROUND(COALESCE(b.晓晓报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击量, 0), 0), 2) AS 晓晓转化率百分比,

    -- 差异对比
    ROUND(COALESCE(b.晓晓报名订单量, 0) * 100.0 / NULLIF(COALESCE(b.晓晓点击量, 0), 0), 2) -
    ROUND(COALESCE(a.报名订单量, 0) * 100.0 / NULLIF(COALESCE(a.点击量, 0), 0), 2) AS 转化率差异百分比

FROM
    -- 小蚕活动地域数据
    (SELECT
        county_id,
        SUM(clc_num) AS 点击量,
        SUM(baoming_order_num) AS 报名订单量
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')
     GROUP BY county_id
     HAVING SUM(clc_num) >= 50) a

FULL OUTER JOIN
    -- 晓晓活动地域数据
    (SELECT
        county_id,
        SUM(clc_num) AS 晓晓点击量,
        SUM(xx_baoming_order_num) AS 晓晓报名订单量
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动'
     GROUP BY county_id
     HAVING SUM(clc_num) >= 50) b ON a.county_id = b.county_id

WHERE COALESCE(a.点击量, 0) + COALESCE(b.晓晓点击量, 0) > 0
ORDER BY 转化率差异百分比 DESC
LIMIT 20;

-- ============================================================================
-- 5. 用户重合度分析 (需要bitmap函数支持)
-- ============================================================================

-- 查询5: 用户点击行为分析 (整体)
-- 使用bitmap函数进行用户去重计数，按照用户提供的结构改造

-- 只点击晓晓的用户数
SELECT
    '只点击晓晓' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid as user_id
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) as uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type = '晓晓活动'
        AND clc_num > 0
    GROUP BY user_id
    HAVING SUM(CASE WHEN activity_type IN ('小蚕活动', '站内活动') THEN 1 ELSE 0 END) = 0
) t1

UNION ALL

-- 只点击小蚕的用户数
SELECT
    '只点击小蚕' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid as user_id
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) as uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动')
        AND clc_num > 0
    GROUP BY user_id
    HAVING SUM(CASE WHEN activity_type = '晓晓活动' THEN 1 ELSE 0 END) = 0
) t2

UNION ALL

-- 两者都点击的用户数
SELECT
    '两者都点击' AS 用户类型,
    COUNT(DISTINCT user_id) AS 用户数
FROM (
    SELECT uid as user_id
    FROM dws.dws_sr_traffic_homepage_mix_ascribe_d, unnest_bitmap(clc_uids) as uid
    WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
        AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
        AND clc_num > 0
    GROUP BY user_id
    HAVING COUNT(DISTINCT CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE NULL END) = 2
) t3

UNION ALL

-- 总体用户数 (用于计算比例)
SELECT
    '总体用户' AS 用户类型,
    bitmap_union_count(clc_uids) AS 用户数
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
    AND clc_num > 0

ORDER BY 用户类型;

-- ============================================================================
-- 6. 漏斗转化分析
-- ============================================================================

-- 查询6: 行为漏斗对比
SELECT
    '小蚕活动' AS 活动类型,
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,
    SUM(baoming_order_num) AS 报名订单量,
    ROUND(SUM(detailpage_pv) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 点击到详情页转化率百分比,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(detailpage_pv), 0), 2) AS 详情页到报名转化率百分比,
    ROUND(SUM(baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 整体转化率百分比,
    -- 用户量指标（UV）- 使用bitmap函数
    bitmap_union_count(clc_uids) AS 点击UV,
    bitmap_union_count(detailpage_view_uids) AS 详情页浏览UV,
    ROUND(bitmap_union_count(detailpage_view_uids) * 100.0 /
          NULLIF(bitmap_union_count(clc_uids), 0), 2) AS 点击到详情页UV转化率百分比
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
    ROUND(SUM(xx_baoming_order_num) * 100.0 / NULLIF(SUM(clc_num), 0), 2) AS 整体转化率百分比,
    -- 用户量指标（UV）- 使用bitmap函数
    bitmap_union_count(clc_uids) AS 点击UV,
    bitmap_union_count(detailpage_view_uids) AS 详情页浏览UV,
    ROUND(bitmap_union_count(detailpage_view_uids) * 100.0 /
          NULLIF(bitmap_union_count(clc_uids), 0), 2) AS 点击到详情页UV转化率百分比
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type = '晓晓活动'

ORDER BY 活动类型;

-- ============================================================================
-- 7. 趋势分析 (最近30天每日趋势)
-- ============================================================================

-- 查询7: 每日转化率趋势
SELECT
    a.statistics_date AS 统计日期,

    -- 小蚕活动指标
    a.点击量 AS 小蚕日点击量,
    a.报名订单量 AS 小蚕日报名订单量,
    ROUND(a.报名订单量 * 100.0 / NULLIF(a.点击量, 0), 2) AS 小蚕日转化率百分比,

    -- 晓晓活动指标
    b.晓晓点击量 AS 晓晓日点击量,
    b.晓晓报名订单量 AS 晓晓日报名订单量,
    ROUND(b.晓晓报名订单量 * 100.0 / NULLIF(b.晓晓点击量, 0), 2) AS 晓晓日转化率百分比,

    -- 差异
    ROUND(b.晓晓报名订单量 * 100.0 / NULLIF(b.晓晓点击量, 0), 2) -
    ROUND(a.报名订单量 * 100.0 / NULLIF(a.点击量, 0), 2) AS 日转化率差异百分比

FROM
    (SELECT
        statistics_date,
        SUM(clc_num) AS 点击量,
        SUM(baoming_order_num) AS 报名订单量
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')
     GROUP BY statistics_date) a

LEFT JOIN
    (SELECT
        statistics_date,
        SUM(clc_num) AS 晓晓点击量,
        SUM(xx_baoming_order_num) AS 晓晓报名订单量
     FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动'
     GROUP BY statistics_date) b ON a.statistics_date = b.statistics_date

ORDER BY a.statistics_date DESC;

-- ============================================================================
-- 8. 用户级别数据提取 (用于用户重合度分析)
-- ============================================================================

-- 查询8.1: 基础用户行为聚合 (日级别) - 优化版：按关键维度聚合，减少数据量
-- 原查询每天80万+行数据，优化后按日期+活动类型聚合，大幅减少数据量
SELECT
    statistics_date AS 统计日期,
    CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE activity_type
    END AS 活动类型,

    -- 点击相关指标
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,

    -- 订单相关指标
    SUM(CASE
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN baoming_order_num
        WHEN activity_type = '晓晓活动' THEN xx_baoming_order_num
        ELSE 0
    END) AS 报名订单量,

    SUM(CASE
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN valid_order_num
        WHEN activity_type = '晓晓活动' THEN xx_valid_order_num
        ELSE 0
    END) AS 有效订单量,

    -- 转化率指标
    ROUND(
        SUM(CASE
            WHEN activity_type IN ('小蚕活动', '站内活动') THEN baoming_order_num
            WHEN activity_type = '晓晓活动' THEN xx_baoming_order_num
            ELSE 0
        END) * 100.0 / NULLIF(SUM(clc_num), 0),
        2
    ) AS 转化率百分比,

    -- 用户量指标（UV）- 使用bitmap函数
    bitmap_union_count(clc_uids) AS 点击UV,
    bitmap_union_count(detailpage_view_uids) AS 详情页浏览UV,
    ROUND(
        bitmap_union_count(detailpage_view_uids) * 100.0 /
        NULLIF(bitmap_union_count(clc_uids), 0),
        2
    ) AS UV转化率百分比

FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
    AND clc_num > 0
GROUP BY statistics_date,
    CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE activity_type
    END
ORDER BY statistics_date DESC, 活动类型;

-- 查询8.2: 平台级别聚合 (如需更详细分析)
SELECT
    statistics_date AS 统计日期,
    platform_name AS 平台名称,
    CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE activity_type
    END AS 活动类型,

    -- 点击相关指标
    SUM(clc_num) AS 点击量,
    SUM(detailpage_pv) AS 详情页PV,

    -- 订单相关指标
    SUM(CASE
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN baoming_order_num
        WHEN activity_type = '晓晓活动' THEN xx_baoming_order_num
        ELSE 0
    END) AS 报名订单量,

    -- 转化率指标
    ROUND(
        SUM(CASE
            WHEN activity_type IN ('小蚕活动', '站内活动') THEN baoming_order_num
            WHEN activity_type = '晓晓活动' THEN xx_baoming_order_num
            ELSE 0
        END) * 100.0 / NULLIF(SUM(clc_num), 0),
        2
    ) AS 转化率百分比

FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
    AND clc_num > 0
    AND platform_name IN ('iOS', 'Android', 'H5', '微信小程序')
GROUP BY statistics_date, platform_name,
    CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE activity_type
    END
ORDER BY statistics_date DESC, platform_name, 活动类型;

-- 查询8.3: 原始详细数据 (按需使用，数据量大)
-- 注释：原查询每天80万+行，Excel无法处理，仅保留供参考
/*
SELECT
    statistics_date AS 统计日期,
    county_id AS 区县ID,
    platform_name AS 平台名称,
    app_version AS APP版本,
    CASE
        WHEN activity_type = '晓晓活动' THEN '晓晓活动'
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN '小蚕活动'
        ELSE activity_type
    END AS 活动类型,

    -- 点击相关指标
    clc_num AS 点击量,
    detailpage_pv AS 详情页PV,

    -- 订单相关指标
    CASE
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN baoming_order_num
        WHEN activity_type = '晓晓活动' THEN xx_baoming_order_num
        ELSE 0
    END AS 报名订单量,

    CASE
        WHEN activity_type IN ('小蚕活动', '站内活动') THEN valid_order_num
        WHEN activity_type = '晓晓活动' THEN xx_valid_order_num
        ELSE 0
    END AS 有效订单量

FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
    AND activity_type IN ('小蚕活动', '站内活动', '晓晓活动')
    AND clc_num > 0
ORDER BY statistics_date, county_id, platform_name;
*/

-- ============================================================================
-- 9. 综合对比分析报表
-- ============================================================================

-- 查询9: 整体汇总对比
SELECT
    -- 小蚕活动整体汇总
    (SELECT SUM(clc_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')) AS 小蚕总点击量,

    (SELECT SUM(baoming_order_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type IN ('小蚕活动', '站内活动')) AS 小蚕总订单量,

    ROUND(
        (SELECT SUM(baoming_order_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type IN ('小蚕活动', '站内活动')) * 100.0 /
        NULLIF((SELECT SUM(clc_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type IN ('小蚕活动', '站内活动')), 0),
        2
    ) AS 小蚕整体转化率百分比,

    -- 晓晓活动整体汇总
    (SELECT SUM(clc_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动') AS 晓晓总点击量,

    (SELECT SUM(xx_baoming_order_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
     WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
         AND activity_type = '晓晓活动') AS 晓晓总订单量,

    ROUND(
        (SELECT SUM(xx_baoming_order_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type = '晓晓活动') * 100.0 /
        NULLIF((SELECT SUM(clc_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type = '晓晓活动'), 0),
        2
    ) AS 晓晓整体转化率百分比,

    -- 差异
    ROUND(
        (SELECT SUM(xx_baoming_order_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type = '晓晓活动') * 100.0 /
        NULLIF((SELECT SUM(clc_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type = '晓晓活动'), 0),
        2
    ) -
    ROUND(
        (SELECT SUM(baoming_order_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type IN ('小蚕活动', '站内活动')) * 100.0 /
        NULLIF((SELECT SUM(clc_num) FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
         WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
             AND activity_type IN ('小蚕活动', '站内活动')), 0),
        2
    ) AS 整体转化率差异百分比;