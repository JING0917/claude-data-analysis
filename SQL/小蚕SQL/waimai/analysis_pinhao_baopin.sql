-- ============================================================
-- 拼好饭 / 爆品团 销单率偏低归因分析 SQL（区分首页 / 搜索场景）
-- 数据源: dws.dws_sr_store_takeawaypro_statis_d
-- 分析周期: 2026.04.17 — 2026.05.11（排除4/16上线首日，共25天）
--
-- 核心约定:
--   首页场景: tot_homepage_activity_expose_num / clc_num / clc_uids
--   搜索场景: tot_search_expose_num / clc_num / clc_uids
--   下游环节按入口拆分: BITMAP_AND(click_bm, downstream_bm)
--     首页入口 → 详情/报名按钮/报名/完单 = BITMAP_AND(hp_click_bm, detail_bm/...)
--     搜索入口 → 详情/报名按钮/报名/完单 = BITMAP_AND(sr_click_bm, detail_bm/...)
--   按天 BITMAP_UNION → 日级 BITMAP_AND → SUM 人天汇总
--
--   danpin_type: NULL=自营普通单品, 1=拼好饭, 2=爆品团
--   promotion_rebate_type: 0=霸王餐("满X返Y"), 1=返利餐("最高返X元")
-- ============================================================


-- ============================================================
-- 主分析 Query 1: 概览（区分首页/搜索场景）
-- ============================================================
SELECT CASE WHEN danpin_type = 1 THEN '拼好饭'
            WHEN danpin_type = 2 THEN '爆品团'
            ELSE '自营普通(含NULL)' END AS 商品类型,
    COUNT(DISTINCT promotion_id) AS 活动数,
    SUM(promotion_quota) AS 总名额,
    SUM(valid_order_num) AS 有效订单量,
    ROUND(SUM(valid_order_num) * 100.0 / NULLIF(SUM(promotion_quota), 0), 2) AS 销单率_pct,
    -- 首页
    SUM(tot_homepage_activity_expose_num) AS 首页曝光,
    SUM(tot_homepage_activity_clc_num) AS 首页点击,
    ROUND(SUM(tot_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(tot_homepage_activity_expose_num), 0), 2) AS 首页CTR_pct,
    -- 搜索
    SUM(tot_search_expose_num) AS 搜索曝光,
    SUM(tot_search_result_clc_num) AS 搜索点击,
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2) AS 搜索CTR_pct,
    -- 搜索曝光占比
    ROUND(SUM(tot_search_expose_num) * 100.0 / NULLIF(SUM(tot_search_expose_num) + SUM(tot_homepage_activity_expose_num), 0), 2) AS 搜索曝光占比_pct
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY CASE WHEN danpin_type = 1 THEN '拼好饭'
              WHEN danpin_type = 2 THEN '爆品团'
              ELSE '自营普通(含NULL)' END
UNION ALL

SELECT '【整体】' AS 商品类型,
    COUNT(DISTINCT promotion_id),
    SUM(promotion_quota),
    SUM(valid_order_num),
    ROUND(SUM(valid_order_num) * 100.0 / NULLIF(SUM(promotion_quota), 0), 2),
    SUM(tot_homepage_activity_expose_num),
    SUM(tot_homepage_activity_clc_num),
    ROUND(SUM(tot_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(tot_homepage_activity_expose_num), 0), 2),
    SUM(tot_search_expose_num),
    SUM(tot_search_result_clc_num),
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2),
    ROUND(SUM(tot_search_expose_num) * 100.0 / NULLIF(SUM(tot_search_expose_num) + SUM(tot_homepage_activity_expose_num), 0), 2)
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0

ORDER BY 销单率_pct DESC;


-- ============================================================
-- 主分析 Query 2: 双场景漏斗（首页漏斗 vs 搜索漏斗）
-- 下游环节按天用 BITMAP_AND 按入口拆分，SUM 人天汇总
-- ============================================================
WITH daily AS (
    SELECT dt,
        CASE WHEN danpin_type = 1 THEN '拼好饭'
             WHEN danpin_type = 2 THEN '爆品团'
             ELSE '自营普通' END AS ptype,
        SUM(tot_homepage_activity_expose_num) AS hp_expose,
        SUM(tot_homepage_activity_clc_num) AS hp_click_events,
        SUM(tot_search_expose_num) AS sr_expose,
        SUM(tot_search_result_clc_num) AS sr_click_events,
        BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(baoming_uids) AS baoming_bm,
        BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY dt, ptype
),
daily_all AS (
    SELECT dt,
        SUM(tot_homepage_activity_expose_num) AS hp_expose,
        SUM(tot_homepage_activity_clc_num) AS hp_click_events,
        SUM(tot_search_expose_num) AS sr_expose,
        SUM(tot_search_result_clc_num) AS sr_click_events,
        BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(baoming_uids) AS baoming_bm,
        BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY dt
)
-- 首页入口漏斗
SELECT ptype AS 类型, '首页' AS 场景,
    SUM(hp_expose) AS 曝光量,
    SUM(hp_click_events) AS 点击次数,
    ROUND(SUM(hp_click_events) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR_pct,
    SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2) AS 点击到详情_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮点击人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2) AS 详情到报名按钮_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))), 0), 2) AS 报名按钮到报名_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 有效订单人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2) AS 报名到完单_pct,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2) AS 点击到完单_pct
FROM daily
GROUP BY ptype

UNION ALL

-- 搜索入口漏斗
SELECT ptype, '搜索',
    SUM(sr_expose),
    SUM(sr_click_events),
    ROUND(SUM(sr_click_events) * 100.0 / NULLIF(SUM(sr_expose), 0), 2),
    SUM(BITMAP_COUNT(sr_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))), 0), 2),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2)
FROM daily
GROUP BY ptype

UNION ALL

SELECT '整体', '首页',
    SUM(hp_expose), SUM(hp_click_events),
    ROUND(SUM(hp_click_events) * 100.0 / NULLIF(SUM(hp_expose), 0), 2),
    SUM(BITMAP_COUNT(hp_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2)
FROM daily_all

UNION ALL

SELECT '整体', '搜索',
    SUM(sr_expose), SUM(sr_click_events),
    ROUND(SUM(sr_click_events) * 100.0 / NULLIF(SUM(sr_expose), 0), 2),
    SUM(BITMAP_COUNT(sr_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))), 0), 2),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2)
FROM daily_all

ORDER BY 类型, 场景;


-- ============================================================
-- 主分析 Query 3: 每日趋势（区分首页/搜索 CTR 和销单率）
-- ============================================================
SELECT dt,
    CASE WHEN danpin_type = 1 THEN '拼好饭'
         WHEN danpin_type = 2 THEN '爆品团'
         ELSE '自营普通' END AS 类型,
    COUNT(DISTINCT promotion_id) AS 活动数,
    SUM(valid_order_num) AS 有效订单量,
    ROUND(SUM(valid_order_num) * 100.0 / NULLIF(SUM(promotion_quota), 0), 2) AS 销单率_pct,
    ROUND(SUM(tot_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(tot_homepage_activity_expose_num), 0), 2) AS 首页CTR_pct,
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2) AS 搜索CTR_pct
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY dt, CASE WHEN danpin_type = 1 THEN '拼好饭'
                   WHEN danpin_type = 2 THEN '爆品团'
                   ELSE '自营普通' END

UNION ALL

SELECT dt,
    '【整体】' AS 类型,
    COUNT(DISTINCT promotion_id),
    SUM(valid_order_num),
    ROUND(SUM(valid_order_num) * 100.0 / NULLIF(SUM(promotion_quota), 0), 2),
    ROUND(SUM(tot_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(tot_homepage_activity_expose_num), 0), 2),
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2)
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY dt

ORDER BY dt, 类型;


-- ============================================================
-- 主分析 Query 4: 曝光充分性（按首页/搜索分别对比）
-- ============================================================
WITH overall AS (
    SELECT COUNT(DISTINCT promotion_id) AS 总活动数,
        SUM(tot_homepage_activity_expose_num) AS 总首页曝光,
        SUM(tot_search_expose_num) AS 总搜索曝光
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
),
sub AS (
    SELECT CASE danpin_type WHEN 1 THEN '拼好饭' WHEN 2 THEN '爆品团' END AS 类型,
        COUNT(DISTINCT promotion_id) AS 活动数,
        SUM(tot_homepage_activity_expose_num) AS 首页曝光,
        SUM(tot_homepage_activity_clc_num) AS 首页点击,
        SUM(tot_search_expose_num) AS 搜索曝光,
        SUM(tot_search_result_clc_num) AS 搜索点击
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0 AND danpin_type IN (1, 2)
    GROUP BY danpin_type
)
SELECT s.类型,
    s.活动数,
    ROUND(s.活动数 * 100.0 / o.总活动数, 2) AS 活动数占比_pct,
    s.首页曝光,
    ROUND(s.首页曝光 * 100.0 / o.总首页曝光, 2) AS 首页曝光占比_pct,
    ROUND(s.首页曝光 * 1.0 / s.活动数, 0) AS 单活动首页曝光,
    s.搜索曝光,
    ROUND(s.搜索曝光 * 100.0 / o.总搜索曝光, 2) AS 搜索曝光占比_pct,
    ROUND(s.搜索曝光 * 1.0 / s.活动数, 0) AS 单活动搜索曝光,
    ROUND(o.总首页曝光 * 1.0 / o.总活动数, 0) AS 整体单活动首页曝光,
    ROUND(o.总搜索曝光 * 1.0 / o.总活动数, 0) AS 整体单活动搜索曝光
FROM sub s, overall o
ORDER BY s.类型;


-- ============================================================
-- 主分析 Query 5: 供给侧特征（无场景区分，活动属性）
-- ============================================================
SELECT CASE WHEN danpin_type = 1 THEN '拼好饭'
            WHEN danpin_type = 2 THEN '爆品团'
            ELSE '自营普通' END AS 类型,
    COUNT(DISTINCT promotion_id) AS 活动数,
    ROUND(AVG(promotion_quota), 0) AS 平均名额,
    ROUND(AVG(mlabel_threshold_amt), 1) AS 平均门槛金额,
    ROUND(AVG(mlabel_rebate_amt), 1) AS 平均返现金额,
    ROUND(SUM(IF(cate1=1,1,0))*100.0/COUNT(1), 1) AS 早餐占比,
    ROUND(SUM(IF(cate1=2,1,0))*100.0/COUNT(1), 1) AS 正餐占比,
    ROUND(SUM(IF(cate1=4,1,0))*100.0/COUNT(1), 1) AS 晚餐占比,
    ROUND(SUM(IF(cate1=5,1,0))*100.0/COUNT(1), 1) AS 夜宵占比,
    ROUND(SUM(IF(promotion_rebate_type=0,1,0))*100.0/COUNT(1), 1) AS 霸王餐占比,
    ROUND(SUM(IF(promotion_rebate_type=1,1,0))*100.0/COUNT(1), 1) AS 返利餐占比
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY CASE WHEN danpin_type = 1 THEN '拼好饭'
              WHEN danpin_type = 2 THEN '爆品团'
              ELSE '自营普通' END

UNION ALL

SELECT '【整体】' AS 类型,
    COUNT(DISTINCT promotion_id),
    ROUND(AVG(promotion_quota), 0),
    ROUND(AVG(mlabel_threshold_amt), 1),
    ROUND(AVG(mlabel_rebate_amt), 1),
    ROUND(SUM(IF(cate1=1,1,0))*100.0/COUNT(1), 1),
    ROUND(SUM(IF(cate1=2,1,0))*100.0/COUNT(1), 1),
    ROUND(SUM(IF(cate1=4,1,0))*100.0/COUNT(1), 1),
    ROUND(SUM(IF(cate1=5,1,0))*100.0/COUNT(1), 1),
    ROUND(SUM(IF(promotion_rebate_type=0,1,0))*100.0/COUNT(1), 1),
    ROUND(SUM(IF(promotion_rebate_type=1,1,0))*100.0/COUNT(1), 1)
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0

ORDER BY 类型;


-- ============================================================
-- 主分析 Query 6: 分端表现（首页三端: APP/H5/小程序 + 搜索端）
-- ============================================================
SELECT CASE WHEN danpin_type = 1 THEN '拼好饭'
            WHEN danpin_type = 2 THEN '爆品团'
            ELSE '自营普通' END AS 类型,
    SUM(app_homepage_activity_expose_num) AS APP首页曝光,
    SUM(app_homepage_activity_clc_num) AS APP首页点击,
    ROUND(SUM(app_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(app_homepage_activity_expose_num), 0), 2) AS APP_CTR_pct,
    SUM(h5_homepage_activity_expose_num) AS H5首页曝光,
    SUM(h5_homepage_activity_clc_num) AS H5首页点击,
    ROUND(SUM(h5_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(h5_homepage_activity_expose_num), 0), 2) AS H5_CTR_pct,
    SUM(minipro_homepage_activity_expose_num) AS 小程序首页曝光,
    SUM(minipro_homepage_activity_clc_num) AS 小程序首页点击,
    ROUND(SUM(minipro_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(minipro_homepage_activity_expose_num), 0), 2) AS 小程序CTR_pct,
    SUM(tot_search_expose_num) AS 搜索曝光,
    SUM(tot_search_result_clc_num) AS 搜索点击,
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2) AS 搜索CTR_pct
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY CASE WHEN danpin_type = 1 THEN '拼好饭'
              WHEN danpin_type = 2 THEN '爆品团'
              ELSE '自营普通' END

UNION ALL

SELECT '【整体】' AS 类型,
    SUM(app_homepage_activity_expose_num),
    SUM(app_homepage_activity_clc_num),
    ROUND(SUM(app_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(app_homepage_activity_expose_num), 0), 2),
    SUM(h5_homepage_activity_expose_num),
    SUM(h5_homepage_activity_clc_num),
    ROUND(SUM(h5_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(h5_homepage_activity_expose_num), 0), 2),
    SUM(minipro_homepage_activity_expose_num),
    SUM(minipro_homepage_activity_clc_num),
    ROUND(SUM(minipro_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(minipro_homepage_activity_expose_num), 0), 2),
    SUM(tot_search_expose_num),
    SUM(tot_search_result_clc_num),
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2)
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0

ORDER BY 类型;


-- ============================================================
-- 验证 Query 7: 整体内返利餐 vs 霸王餐（区分首页/搜索场景，下游按入口拆分）
-- ============================================================
WITH daily AS (
    SELECT dt,
        CASE WHEN promotion_rebate_type = 0 THEN '霸王餐' ELSE '返利餐' END AS rtype,
        SUM(tot_homepage_activity_expose_num) AS hp_expose,
        SUM(tot_homepage_activity_clc_num) AS hp_click_events,
        SUM(tot_search_expose_num) AS sr_expose,
        SUM(tot_search_result_clc_num) AS sr_click_events,
        BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(baoming_uids) AS baoming_bm,
        BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY dt, rtype
)
SELECT rtype AS 返利类型, '首页' AS 场景,
    SUM(hp_expose) AS 曝光量,
    SUM(hp_click_events) AS 点击次数,
    ROUND(SUM(hp_click_events) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR_pct,
    SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2) AS 点击到详情_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮点击人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2) AS 详情到报名按钮_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))), 0), 2) AS 报名按钮到报名_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 有效订单人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2) AS 报名到完单_pct
FROM daily
GROUP BY rtype

UNION ALL

SELECT rtype, '搜索',
    SUM(sr_expose),
    SUM(sr_click_events),
    ROUND(SUM(sr_click_events) * 100.0 / NULLIF(SUM(sr_expose), 0), 2),
    SUM(BITMAP_COUNT(sr_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))), 0), 2)
FROM daily
GROUP BY rtype

ORDER BY 返利类型, 场景;


-- ============================================================
-- 验证 Query 8: 仅自营单品(danpin_type IS NULL)内，返利餐 vs 霸王餐
-- 排除拼好饭/爆品团品牌干扰，纯看返利模式效应（下游按入口拆分）
-- ============================================================
WITH daily AS (
    SELECT dt,
        CASE WHEN promotion_rebate_type = 0 THEN '霸王餐' ELSE '返利餐' END AS rtype,
        SUM(tot_homepage_activity_expose_num) AS hp_expose,
        SUM(tot_homepage_activity_clc_num) AS hp_click_events,
        SUM(tot_search_expose_num) AS sr_expose,
        SUM(tot_search_result_clc_num) AS sr_click_events,
        BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(baoming_uids) AS baoming_bm,
        BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0 AND danpin_type IS NULL
    GROUP BY dt, rtype
)
SELECT rtype AS 返利类型, '首页' AS 场景,
    SUM(hp_expose) AS 曝光量,
    SUM(hp_click_events) AS 点击次数,
    ROUND(SUM(hp_click_events) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR_pct,
    SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2) AS 点击到详情_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮点击人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2) AS 详情到报名按钮_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))), 0), 2) AS 报名按钮到报名_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 有效订单人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2) AS 报名到完单_pct
FROM daily
GROUP BY rtype

UNION ALL

SELECT rtype, '搜索',
    SUM(sr_expose),
    SUM(sr_click_events),
    ROUND(SUM(sr_click_events) * 100.0 / NULLIF(SUM(sr_expose), 0), 2),
    SUM(BITMAP_COUNT(sr_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))), 0), 2)
FROM daily
GROUP BY rtype

ORDER BY 返利类型, 场景;


-- ============================================================
-- 验证 Query 9: 按返现金额分桶，对比返利餐 vs 霸王餐（仅自营单品NULL）
-- 控制返现金额变量（下游按入口拆分）
-- ============================================================
WITH daily AS (
    SELECT dt,
        CASE WHEN mlabel_rebate_amt <= 5 THEN '0-5元'
             WHEN mlabel_rebate_amt <= 10 THEN '5-10元'
             WHEN mlabel_rebate_amt <= 15 THEN '10-15元'
             WHEN mlabel_rebate_amt <= 20 THEN '15-20元'
             ELSE '20元+' END AS rebate_bucket,
        CASE WHEN promotion_rebate_type = 0 THEN '霸王餐' ELSE '返利餐' END AS rtype,
        SUM(tot_homepage_activity_expose_num) AS hp_expose,
        SUM(tot_homepage_activity_clc_num) AS hp_click_events,
        SUM(tot_search_expose_num) AS sr_expose,
        SUM(tot_search_result_clc_num) AS sr_click_events,
        BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(baoming_uids) AS baoming_bm,
        BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0 AND danpin_type IS NULL
    GROUP BY dt, rebate_bucket, rtype
)
SELECT rebate_bucket AS 返现金额桶, rtype AS 返利类型, '首页' AS 场景,
    SUM(hp_expose) AS 曝光量,
    SUM(hp_click_events) AS 点击次数,
    ROUND(SUM(hp_click_events) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR_pct,
    SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2) AS 点击到详情_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮点击人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2) AS 详情到报名按钮_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))), 0), 2) AS 报名按钮到报名_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 有效订单人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2) AS 报名到完单_pct
FROM daily
GROUP BY rebate_bucket, rtype

UNION ALL

SELECT rebate_bucket, rtype, '搜索',
    SUM(sr_expose),
    SUM(sr_click_events),
    ROUND(SUM(sr_click_events) * 100.0 / NULLIF(SUM(sr_expose), 0), 2),
    SUM(BITMAP_COUNT(sr_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))), 0), 2)
FROM daily
GROUP BY rebate_bucket, rtype

ORDER BY 返现金额桶, 返利类型, 场景;


-- ============================================================
-- 验证 Query 10: 每日返利餐 vs 霸王餐趋势（仅自营单品NULL，区分首页/搜索CTR）
-- 每日趋势不做下游 BITMAP 拆分（性能考虑），仅做 CTR 分场景
-- ============================================================
SELECT dt,
    CASE WHEN promotion_rebate_type = 0 THEN '霸王餐' ELSE '返利餐' END AS 返利类型,
    COUNT(DISTINCT promotion_id) AS 活动数,
    SUM(valid_order_num) AS 有效订单量,
    ROUND(SUM(valid_order_num) * 100.0 / NULLIF(SUM(promotion_quota), 0), 2) AS 销单率_pct,
    ROUND(SUM(tot_homepage_activity_clc_num) * 100.0 / NULLIF(SUM(tot_homepage_activity_expose_num), 0), 2) AS 首页CTR_pct,
    ROUND(SUM(tot_search_result_clc_num) * 100.0 / NULLIF(SUM(tot_search_expose_num), 0), 2) AS 搜索CTR_pct,
    ROUND(SUM(tot_takeaway_baoming_button_clc_num) * 100.0 / NULLIF(SUM(tot_takeaway_detailpage_pv), 0), 2) AS 详情到报名_pct,
    ROUND(SUM(valid_order_num) * 100.0 / NULLIF(SUM(tot_takeaway_baoming_button_clc_num), 0), 2) AS 报名到完单_pct
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0 AND danpin_type IS NULL
GROUP BY dt, promotion_rebate_type
ORDER BY dt, 返利类型;


-- ============================================================
-- 验证 Query 11: 控制门槛金额 <=15元（仅自营单品NULL，下游按入口拆分）
-- 拼好饭平均门槛15元 vs 整体23.2元，控制门槛后看差异
-- ============================================================
WITH daily AS (
    SELECT dt,
        CASE WHEN promotion_rebate_type = 0 THEN '霸王餐' ELSE '返利餐' END AS rtype,
        SUM(tot_homepage_activity_expose_num) AS hp_expose,
        SUM(tot_homepage_activity_clc_num) AS hp_click_events,
        SUM(tot_search_expose_num) AS sr_expose,
        SUM(tot_search_result_clc_num) AS sr_click_events,
        BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(baoming_uids) AS baoming_bm,
        BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
        AND danpin_type IS NULL AND mlabel_threshold_amt <= 15
    GROUP BY dt, rtype
)
SELECT rtype AS 返利类型, '首页' AS 场景,
    SUM(hp_expose) AS 曝光量,
    SUM(hp_click_events) AS 点击次数,
    ROUND(SUM(hp_click_events) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR_pct,
    SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(hp_click_bm)), 0), 2) AS 点击到详情_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮点击人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2) AS 详情到报名按钮_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))), 0), 2) AS 报名按钮到报名_pct,
    SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 有效订单人天,
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2) AS 报名到完单_pct
FROM daily
GROUP BY rtype

UNION ALL

SELECT rtype, '搜索',
    SUM(sr_expose),
    SUM(sr_click_events),
    ROUND(SUM(sr_click_events) * 100.0 / NULLIF(SUM(sr_expose), 0), 2),
    SUM(BITMAP_COUNT(sr_click_bm)),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(sr_click_bm)), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm))), 0), 2),
    SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))),
    ROUND(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm))) * 100.0 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm))), 0), 2)
FROM daily
GROUP BY rtype

ORDER BY 返利类型, 场景;


-- ============================================================
-- 数据核查 Query 12: 交叉校验（区分首页/搜索曝光口径）
-- ============================================================
SELECT '汇总校验' AS 校验项,
    COUNT(DISTINCT promotion_id) AS 活动数合计,
    SUM(promotion_quota) AS 名额合计,
    SUM(valid_order_num) AS 订单合计,
    SUM(tot_homepage_activity_expose_num) AS 首页曝光合计,
    SUM(tot_search_expose_num) AS 搜索曝光合计,
    SUM(CASE WHEN promotion_rebate_type = 0 THEN promotion_quota ELSE 0 END) AS 霸王餐名额,
    SUM(CASE WHEN promotion_rebate_type = 1 THEN promotion_quota ELSE 0 END) AS 返利餐名额,
    SUM(CASE WHEN promotion_rebate_type = 0 THEN valid_order_num ELSE 0 END) AS 霸王餐订单,
    SUM(CASE WHEN promotion_rebate_type = 1 THEN valid_order_num ELSE 0 END) AS 返利餐订单
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0;


-- ============================================================
-- 数据核查 Query 13: 漏斗自洽性（区分首页/搜索场景）
-- ============================================================
SELECT CASE WHEN danpin_type = 1 THEN '拼好饭'
            WHEN danpin_type = 2 THEN '爆品团'
            ELSE '自营普通' END AS 类型,
    SUM(tot_homepage_activity_expose_num) AS 首页曝光,
    SUM(tot_homepage_activity_clc_num) AS 首页点击,
    CASE WHEN SUM(tot_homepage_activity_clc_num) <= SUM(tot_homepage_activity_expose_num) THEN 'OK' ELSE 'FAIL' END AS 首页检查,
    SUM(tot_search_expose_num) AS 搜索曝光,
    SUM(tot_search_result_clc_num) AS 搜索点击,
    CASE WHEN SUM(tot_search_result_clc_num) <= SUM(tot_search_expose_num) THEN 'OK' ELSE 'FAIL' END AS 搜索检查,
    SUM(tot_takeaway_detailpage_pv) AS 详情PV,
    SUM(tot_takeaway_baoming_button_clc_num) AS 报名点击,
    CASE WHEN SUM(tot_takeaway_baoming_button_clc_num) <= SUM(tot_takeaway_detailpage_pv) THEN 'OK' ELSE 'FAIL' END AS 详情检查,
    SUM(valid_order_num) AS 有效订单,
    CASE WHEN SUM(valid_order_num) <= SUM(tot_takeaway_baoming_button_clc_num) THEN 'OK' ELSE 'FAIL' END AS 完单检查
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY CASE WHEN danpin_type = 1 THEN '拼好饭'
              WHEN danpin_type = 2 THEN '爆品团'
              ELSE '自营普通' END
ORDER BY 类型;


-- ============================================================
-- 数据核查 Query 14: 日期完整性
-- ============================================================
SELECT COUNT(DISTINCT dt) AS 实际天数,
    25 AS 预期天数,
    CASE WHEN COUNT(DISTINCT dt) = 25 THEN 'OK 完整' ELSE 'MISSING 缺失' END AS 日期检查,
    MIN(dt) AS 最早日期,
    MAX(dt) AS 最晚日期
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0;


-- ============================================================
-- 数据核查 Query 15: danpin_type 分布
-- ============================================================
SELECT CASE
        WHEN danpin_type IS NULL THEN 'NULL(自营普通)'
        WHEN danpin_type = 0 THEN '0(自营单品)'
        WHEN danpin_type = 1 THEN '1(拼好饭)'
        WHEN danpin_type = 2 THEN '2(爆品团)'
        ELSE '其他' END AS danpin_type_分组,
    COUNT(DISTINCT promotion_id) AS 活动数,
    SUM(promotion_quota) AS 总名额,
    SUM(valid_order_num) AS 有效订单量
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY CASE
        WHEN danpin_type IS NULL THEN 'NULL(自营普通)'
        WHEN danpin_type = 0 THEN '0(自营单品)'
        WHEN danpin_type = 1 THEN '1(拼好饭)'
        WHEN danpin_type = 2 THEN '2(爆品团)'
        ELSE '其他' END
ORDER BY danpin_type_分组;


-- ============================================================
-- 数据核查 Query 16: promotion_rebate_type 空值检查
-- ============================================================
SELECT CASE
        WHEN promotion_rebate_type IS NULL THEN 'NULL'
        WHEN promotion_rebate_type = 0 THEN '0(霸王餐)'
        WHEN promotion_rebate_type = 1 THEN '1(返利餐)'
        ELSE '其他' END AS rebate_type_分组,
    COUNT(DISTINCT promotion_id) AS 活动数,
    SUM(valid_order_num) AS 有效订单量
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
GROUP BY CASE
        WHEN promotion_rebate_type IS NULL THEN 'NULL'
        WHEN promotion_rebate_type = 0 THEN '0(霸王餐)'
        WHEN promotion_rebate_type = 1 THEN '1(返利餐)'
        ELSE '其他' END
ORDER BY rebate_type_分组;


-- ============================================================
-- 数据核查 Query 17: 每日销单率加权平均
-- ============================================================
SELECT ROUND(SUM(日有效订单) * 100.0 / NULLIF(SUM(日名额), 0), 2) AS 加权销单率
FROM (
    SELECT dt,
        SUM(promotion_quota) AS 日名额,
        SUM(valid_order_num) AS 日有效订单
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY dt
) t;


-- ============================================================
-- 数据核查 Query 18: 分端曝光加总 vs 全站曝光
-- ============================================================
SELECT '曝光加总校验' AS 校验项,
    SUM(tot_homepage_activity_expose_num) AS 全站首页曝光,
    SUM(COALESCE(app_homepage_activity_expose_num,0) +
        COALESCE(h5_homepage_activity_expose_num,0) +
        COALESCE(minipro_homepage_activity_expose_num,0)) AS 三端曝光合计,
    CASE WHEN SUM(tot_homepage_activity_expose_num) =
        SUM(COALESCE(app_homepage_activity_expose_num,0) +
            COALESCE(h5_homepage_activity_expose_num,0) +
            COALESCE(minipro_homepage_activity_expose_num,0))
        THEN 'OK 一致' ELSE 'DIFF 有差异' END AS 首页三端加总校验,
    SUM(tot_search_expose_num) AS 搜索端曝光
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0;


-- ============================================================
-- ============================================================
-- 用户分析（BITMAP 查询，区分首页 / 搜索两个点击入口）
-- ============================================================
-- ============================================================


-- ============================================================
-- 用户分析 Query U1: 注册渠道 x 点击行为（区分首页点击 / 搜索点击）
-- ============================================================
WITH activity_label AS (
    SELECT promotion_id,
        CASE WHEN danpin_type = 1 THEN '拼好饭'
             WHEN danpin_type = 2 THEN '爆品团'
             ELSE '自营普通' END AS ptype
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY promotion_id, danpin_type
),
hp_click_user AS (
    SELECT al.ptype, cu.user_id
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    JOIN activity_label al ON s.promotion_id = al.promotion_id,
    UNNEST(bitmap_to_array(s.tot_homepage_activity_clc_uids)) AS cu(user_id)
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
),
sr_click_user AS (
    SELECT al.ptype, cu.user_id
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    JOIN activity_label al ON s.promotion_id = al.promotion_id,
    UNNEST(bitmap_to_array(s.tot_search_result_clc_uids)) AS cu(user_id)
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
),
click_user AS (
    SELECT ptype, user_id FROM hp_click_user
    UNION
    SELECT ptype, user_id FROM sr_click_user
),
user_channel AS (
    SELECT user_id,
        COALESCE(get_json_string(meituan_auth_user_detail, '$.re_ch'), '未知') AS channel
    FROM dim.dim_silkworm_user
)
SELECT cu.ptype AS 活动类型,
    COALESCE(uc.channel, '未知渠道') AS 注册渠道,
    COUNT(DISTINCT cu.user_id) AS 点击用户数,
    ROUND(COUNT(DISTINCT cu.user_id) * 100.0 / SUM(COUNT(DISTINCT cu.user_id)) OVER (PARTITION BY cu.ptype), 1) AS 类型内占比_pct
FROM click_user cu
LEFT JOIN user_channel uc ON cu.user_id = uc.user_id
GROUP BY cu.ptype, uc.channel
ORDER BY cu.ptype, 点击用户数 DESC;


-- ============================================================
-- 用户分析 Query U2: 注册天数 x 点击行为（区分首页点击 / 搜索点击）
-- ============================================================
WITH activity_label AS (
    SELECT promotion_id,
        CASE WHEN danpin_type = 1 THEN '拼好饭'
             WHEN danpin_type = 2 THEN '爆品团'
             ELSE '自营普通' END AS ptype
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY promotion_id, danpin_type
),
hp_click AS (
    SELECT al.ptype, cu.user_id, s.dt AS click_date
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    JOIN activity_label al ON s.promotion_id = al.promotion_id,
    UNNEST(bitmap_to_array(s.tot_homepage_activity_clc_uids)) AS cu(user_id)
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
),
sr_click AS (
    SELECT al.ptype, cu.user_id, s.dt AS click_date
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    JOIN activity_label al ON s.promotion_id = al.promotion_id,
    UNNEST(bitmap_to_array(s.tot_search_result_clc_uids)) AS cu(user_id)
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
),
click_user AS (
    SELECT ptype, user_id, click_date FROM hp_click
    UNION
    SELECT ptype, user_id, click_date FROM sr_click
),
user_register AS (
    SELECT user_id, date(register_time) AS register_date
    FROM dim.dim_silkworm_user
)
SELECT cu.ptype AS 活动类型,
    CASE WHEN datediff(cu.click_date, ur.register_date) <= 1 THEN '注册当天'
         WHEN datediff(cu.click_date, ur.register_date) <= 7 THEN '注册2-7天'
         WHEN datediff(cu.click_date, ur.register_date) <= 30 THEN '注册8-30天'
         ELSE '注册30天+' END AS 注册天数分段,
    COUNT(DISTINCT cu.user_id) AS 点击用户数,
    ROUND(COUNT(DISTINCT cu.user_id) * 100.0 / SUM(COUNT(DISTINCT cu.user_id)) OVER (PARTITION BY cu.ptype), 1) AS 类型内占比_pct
FROM click_user cu
LEFT JOIN user_register ur ON cu.user_id = ur.user_id
GROUP BY cu.ptype, 注册天数分段
ORDER BY cu.ptype, 注册天数分段;


-- ============================================================
-- 用户分析 Query U3: 画像对比（区分首页 / 搜索点击来源）
-- ============================================================
WITH activity_label AS (
    SELECT promotion_id,
        CASE WHEN danpin_type = 1 THEN '拼好饭'
             WHEN danpin_type = 2 THEN '爆品团'
             ELSE '自营普通' END AS ptype
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN '2026-04-17' AND '2026-05-11' AND promotion_quota > 0
    GROUP BY promotion_id, danpin_type
),
hp_click AS (
    SELECT al.ptype, cu.user_id
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    JOIN activity_label al ON s.promotion_id = al.promotion_id,
    UNNEST(bitmap_to_array(s.tot_homepage_activity_clc_uids)) AS cu(user_id)
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
),
sr_click AS (
    SELECT al.ptype, cu.user_id
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    JOIN activity_label al ON s.promotion_id = al.promotion_id,
    UNNEST(bitmap_to_array(s.tot_search_result_clc_uids)) AS cu(user_id)
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
),
click_user AS (
    SELECT ptype, user_id FROM hp_click
    UNION
    SELECT ptype, user_id FROM sr_click
),
user_profile AS (
    SELECT user_id,
        datediff('2026-05-11', date(register_time)) AS 注册到分析末天数
    FROM dim.dim_silkworm_user
)
SELECT cu.ptype AS 活动类型,
    COUNT(DISTINCT cu.user_id) AS 点击用户数,
    ROUND(COUNT(DISTINCT cu.user_id) * 1.0 / (SELECT COUNT(DISTINCT user_id) FROM dim.dim_silkworm_user), 6) AS 占全量用户比例,
    ROUND(AVG(up.注册到分析末天数), 0) AS 平均注册天数
FROM click_user cu
LEFT JOIN user_profile up ON cu.user_id = up.user_id
GROUP BY cu.ptype
ORDER BY cu.ptype;


-- ============================================================
-- 用户分析 Query U4: 【黄金标准因果检验】同一用户 返利餐 vs 霸王餐 全链路
--
--  区分首页入口 / 搜索入口。下游环节用 BITMAP_AND(entry_click_bm, downstream_bm)
--  保证下游只统计该入口点击用户的转化，而非全量下游用户。
--
--  首页入口漏斗: hp_click → hp_click&detail → hp_click&baoming_click → ...
--  搜索入口漏斗: sr_click → sr_click&detail → sr_click&baoming_click → ...
-- ============================================================
WITH type_user_bitmaps AS (
    SELECT
        CASE WHEN s.danpin_type IN (1,2) OR s.promotion_rebate_type = 1 THEN '返利餐'
             ELSE '霸王餐' END AS ptype,
        BITMAP_UNION(s.tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(s.tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(s.tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(s.tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(s.baoming_uids) AS baoming_bm,
        BITMAP_UNION(s.valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
    GROUP BY 1
),
rebate AS (SELECT * FROM type_user_bitmaps WHERE ptype = '返利餐'),
bazhang AS (SELECT * FROM type_user_bitmaps WHERE ptype = '霸王餐'),
-- 首页入口重合用户
hp_overlap AS (
    SELECT BITMAP_AND(r.hp_click_bm, b.hp_click_bm) AS overlap_bm
    FROM rebate r, bazhang b
),
-- 搜索入口重合用户
sr_overlap AS (
    SELECT BITMAP_AND(r.sr_click_bm, b.sr_click_bm) AS overlap_bm
    FROM rebate r, bazhang b
)

-- === 首页入口：返利餐侧 ===
SELECT '首页' AS 入口场景, '返利餐' AS 活动类型,
    BITMAP_COUNT(ho.overlap_bm) AS 重合点击用户数,
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, r.hp_click_bm)) AS 点击用户,
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.detail_bm))) AS 详情用户,
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.baoming_click_bm))) AS 报名按钮点击用户,
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.baoming_bm))) AS 报名用户,
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.valid_bm))) AS 有效订单用户,
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.detail_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, r.hp_click_bm)), 0), 2) AS 点击到详情_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.baoming_click_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.detail_bm))), 0), 2) AS 详情到报名按钮_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.baoming_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.baoming_click_bm))), 0), 2) AS 报名按钮到报名_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.baoming_bm))), 0), 2) AS 报名到完单_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(r.hp_click_bm, r.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, r.hp_click_bm)), 0), 2) AS 点击到完单_pct
FROM rebate r, hp_overlap ho

UNION ALL

-- === 首页入口：霸王餐侧 ===
SELECT '首页', '霸王餐',
    BITMAP_COUNT(ho.overlap_bm),
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, b.hp_click_bm)),
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.detail_bm))),
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.baoming_click_bm))),
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.baoming_bm))),
    BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.valid_bm))),
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.detail_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, b.hp_click_bm)), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.baoming_click_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.detail_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.baoming_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.baoming_click_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.baoming_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, BITMAP_AND(b.hp_click_bm, b.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(ho.overlap_bm, b.hp_click_bm)), 0), 2)
FROM bazhang b, hp_overlap ho

UNION ALL

-- === 搜索入口：返利餐侧 ===
SELECT '搜索', '返利餐',
    BITMAP_COUNT(so.overlap_bm),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, r.sr_click_bm)),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.detail_bm))),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.baoming_click_bm))),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.baoming_bm))),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.valid_bm))),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.detail_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, r.sr_click_bm)), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.baoming_click_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.detail_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.baoming_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.baoming_click_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.baoming_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(r.sr_click_bm, r.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, r.sr_click_bm)), 0), 2)
FROM rebate r, sr_overlap so

UNION ALL

-- === 搜索入口：霸王餐侧 ===
SELECT '搜索', '霸王餐',
    BITMAP_COUNT(so.overlap_bm),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, b.sr_click_bm)),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.detail_bm))),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.baoming_click_bm))),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.baoming_bm))),
    BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.valid_bm))),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.detail_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, b.sr_click_bm)), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.baoming_click_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.detail_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.baoming_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.baoming_click_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.baoming_bm))), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, BITMAP_AND(b.sr_click_bm, b.valid_bm))) * 100.0 /
          NULLIF(BITMAP_COUNT(BITMAP_AND(so.overlap_bm, b.sr_click_bm)), 0), 2)
FROM bazhang b, sr_overlap so

ORDER BY 入口场景, 活动类型;


-- ============================================================
-- 用户分析 Query U5: 各漏斗环节绝对人数（区分首页入口 / 搜索入口）
-- 下游按入口拆分: BITMAP_AND(entry_click_bm, downstream_bm)
-- ============================================================
WITH type_user_bitmaps AS (
    SELECT
        CASE WHEN s.danpin_type IN (1,2) OR s.promotion_rebate_type = 1 THEN '返利餐'
             ELSE '霸王餐' END AS ptype,
        BITMAP_UNION(s.tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(s.tot_search_result_clc_uids) AS sr_click_bm,
        BITMAP_UNION(s.tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(s.tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(s.baoming_uids) AS baoming_bm,
        BITMAP_UNION(s.valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
    GROUP BY 1
)
-- 首页入口漏斗
SELECT ptype AS 活动类型, '首页' AS 入口,
    BITMAP_COUNT(hp_click_bm) AS 点击用户数,
    BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm)) AS 详情用户数,
    BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm)) AS 报名按钮点击用户数,
    BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm)) AS 报名用户数,
    BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm)) AS 有效订单用户数,
    ROUND(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm)) * 100.0 / NULLIF(BITMAP_COUNT(hp_click_bm), 0), 2) AS 点击到详情_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm)) * 100.0 / NULLIF(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm)), 0), 2) AS 详情到报名按钮_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm)) * 100.0 / NULLIF(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm)), 0), 2) AS 报名到完单_pct,
    ROUND(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm)) * 100.0 / NULLIF(BITMAP_COUNT(hp_click_bm), 0), 2) AS 点击到完单_pct
FROM type_user_bitmaps

UNION ALL

-- 搜索入口漏斗
SELECT ptype, '搜索',
    BITMAP_COUNT(sr_click_bm),
    BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm)),
    BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm)),
    BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm)),
    BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm)),
    ROUND(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm)) * 100.0 / NULLIF(BITMAP_COUNT(sr_click_bm), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_click_bm)) * 100.0 / NULLIF(BITMAP_COUNT(BITMAP_AND(sr_click_bm, detail_bm)), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm)) * 100.0 / NULLIF(BITMAP_COUNT(BITMAP_AND(sr_click_bm, baoming_bm)), 0), 2),
    ROUND(BITMAP_COUNT(BITMAP_AND(sr_click_bm, valid_bm)) * 100.0 / NULLIF(BITMAP_COUNT(sr_click_bm), 0), 2)
FROM type_user_bitmaps

ORDER BY 活动类型, 入口;


-- ============================================================
-- 自证方法 Query M1: 双重差分 (DiD) — 每日趋势，4/16上线为自然实验
--
--   处理组: 返利餐(自营) — 4/16前已存在，4/16后拼好饭/爆品团加入
--   对照组: 霸王餐(自营) — 全程存在，供给模式无变化
--   时间窗口: 4/1-5/11，pre=4/1-4/15, post=4/17-5/11
--
--   DiD = (返利_post - 返利_pre) - (霸王_post - 霸王_pre)
--   如果 DiD < 0，说明4/16后返利餐转化相对霸王餐额外恶化 → 返利模式是因果因素
--
--   注意：4/16之前没有拼好饭/爆品团，返利餐仅来自自营(0.8%的promotion_rebate_type=1)
-- ============================================================
WITH daily AS (
    SELECT dt,
           CASE WHEN s.danpin_type IN (1,2) THEN '拼好饭/爆品团'
                WHEN s.promotion_rebate_type = 1 THEN '返利餐(自营)'
                ELSE '霸王餐' END AS supply_type,
           COUNT(DISTINCT promotion_id) AS activity_cnt,
           SUM(promotion_quota) AS total_quota,
           SUM(valid_order_num) AS valid_orders,
           SUM(tot_homepage_activity_expose_num) AS hp_expose,
           SUM(tot_homepage_activity_clc_num) AS hp_clicks,
           BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
           BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
           BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
           BITMAP_UNION(baoming_uids) AS baoming_bm,
           BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    WHERE s.dt BETWEEN '2026-04-01' AND '2026-05-11' AND s.promotion_quota > 0
    GROUP BY dt, supply_type
),
daily_metrics AS (
    SELECT dt, supply_type,
           SUM(activity_cnt) AS activities,
           SUM(valid_orders) AS orders,
           ROUND(SUM(valid_orders) * 100.0 / NULLIF(SUM(total_quota), 0), 2) AS 销单率,
           ROUND(SUM(hp_clicks) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR,
           SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 完单人天,
           ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) * 100.0
                 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))), 0), 2) AS 详情到报名按钮,
           ROUND(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) * 100.0
                 / NULLIF(SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))), 0), 2) AS 报名到完单
    FROM daily
    GROUP BY dt, supply_type
),
-- Pre/Post 汇总
summary AS (
    SELECT supply_type,
           CASE WHEN dt < '2026-04-16' THEN 'Pre(4/1-4/15)' ELSE 'Post(4/17-5/11)' END AS period,
           SUM(orders) AS total_orders,
           ROUND(SUM(orders) * 1.0 / NULLIF(SUM(activities), 0), 2) AS 日均订单,
           ROUND(AVG(销单率), 2) AS avg_销单率,
           ROUND(AVG(CTR), 2) AS avg_CTR,
           ROUND(SUM(报名按钮人天) * 100.0 / NULLIF(SUM(详情人天), 0), 2) AS 详情到报名按钮,
           ROUND(SUM(完单人天) * 100.0 / NULLIF(SUM(报名人天), 0), 2) AS 报名到完单,
           ROUND(SUM(完单人天) * 100.0 / NULLIF(SUM(点击人天), 0), 2) AS 点击到完单
    FROM daily_metrics
    WHERE supply_type != '拼好饭/爆品团'  -- DiD只比较始终存在的两组
    GROUP BY supply_type, period
)
SELECT supply_type, period,
       日均订单, avg_销单率, avg_CTR, 详情到报名按钮, 报名到完单, 点击到完单
FROM summary
ORDER BY supply_type, period;


-- ============================================================
-- 自证方法 Query M2: 用户分层异质性检验
--
--   按用户注册时长分层（新用户/中等/老用户），每层内做 U4 风格同用户对照。
--   如果返利模式是主因 → 即使老用户（转化习惯最强）看到返利餐也应断崖下跌。
--   如果用户自选择是主因 → 老用户层内返利 vs 霸王差距应缩小（老用户更懂挑选）。
--
--   方法: 从 dim_silkworm_user 创建注册时段bitmap，与 U4 的重合用户bitmap相交
-- ============================================================
WITH type_bitmaps AS (
    SELECT
        CASE WHEN s.danpin_type IN (1,2) OR s.promotion_rebate_type = 1 THEN '返利餐'
             ELSE '霸王餐' END AS ptype,
        BITMAP_UNION(s.tot_homepage_activity_clc_uids) AS hp_click_bm,
        BITMAP_UNION(s.tot_takeaway_detailpage_uids) AS detail_bm,
        BITMAP_UNION(s.tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
        BITMAP_UNION(s.baoming_uids) AS baoming_bm,
        BITMAP_UNION(s.valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    WHERE s.dt BETWEEN '2026-04-17' AND '2026-05-11' AND s.promotion_quota > 0
    GROUP BY 1
),
rebate AS (SELECT * FROM type_bitmaps WHERE ptype = '返利餐'),
bazhang AS (SELECT * FROM type_bitmaps WHERE ptype = '霸王餐'),
overlap AS (
    SELECT BITMAP_AND(r.hp_click_bm, b.hp_click_bm) AS overlap_bm
    FROM rebate r, bazhang b
),
-- 用户分层: 按注册时间建bitmap
user_cohorts AS (
    SELECT CASE
               WHEN date(register_time) >= '2026-04-10' THEN '0-7天(新用户)'
               WHEN date(register_time) >= '2026-03-18' THEN '8-30天(中等)'
               ELSE '30天+(老用户)' END AS cohort,
           BITMAP_UNION(TO_BITMAP(user_id)) AS cohort_bm
    FROM dim.dim_silkworm_user
    WHERE date(register_time) >= '2026-03-18'  -- 至少注册8天以上才可能在三组都有分布
    GROUP BY 1
)
-- 对每个cohort，分别计算返利餐和霸王餐的全链路（首页入口）
SELECT c.cohort AS 用户分层,
       BITMAP_COUNT(BITMAP_AND(o.overlap_bm, c.cohort_bm)) AS 层内重合用户数,
       -- 返利餐侧
       BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(r.hp_click_bm, r.valid_bm))) AS 返利完单用户,
       ROUND(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(r.hp_click_bm, r.valid_bm))) * 100.0
             / NULLIF(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), r.hp_click_bm)), 0), 2) AS 返利_点击到完单,
       ROUND(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(r.hp_click_bm, r.baoming_click_bm))) * 100.0
             / NULLIF(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(r.hp_click_bm, r.detail_bm))), 0), 2) AS 返利_详情到报名,
       -- 霸王餐侧
       BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(b.hp_click_bm, b.valid_bm))) AS 霸王完单用户,
       ROUND(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(b.hp_click_bm, b.valid_bm))) * 100.0
             / NULLIF(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), b.hp_click_bm)), 0), 2) AS 霸王_点击到完单,
       ROUND(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(b.hp_click_bm, b.baoming_click_bm))) * 100.0
             / NULLIF(BITMAP_COUNT(BITMAP_AND(BITMAP_AND(o.overlap_bm, c.cohort_bm), BITMAP_AND(b.hp_click_bm, b.detail_bm))), 0), 2) AS 霸王_详情到报名
FROM overlap o, rebate r, bazhang b, user_cohorts c
GROUP BY c.cohort
ORDER BY c.cohort;


-- ============================================================
-- 自证方法 Query M3: 安慰剂检验 (Placebo Test)
--
--   假装 4/1 是拼好饭/爆品团上线日，比较 4/1 前后返利 vs 霸王差距的变化。
--   如果 4/1（伪事件）前后差距稳定 → 说明 4/16（真事件）的断崖是真实的因果效应。
--   如果 4/1 前后差距也变了 → 可能存在周期性或趋势性问题。
--
--   配置:
--     伪事件日: 4/1
--     Pre窗口:  3/15-3/31 (17天)
--     Post窗口: 4/1-4/15  (15天)
--   注意: 伪Post窗口内拼好饭/爆品团还未上线(4/16才上线)，返利餐仅来自自营
-- ============================================================
WITH daily AS (
    SELECT dt,
           CASE WHEN s.promotion_rebate_type = 1 THEN '返利餐(自营)'
                ELSE '霸王餐' END AS supply_type,
           SUM(promotion_quota) AS total_quota,
           SUM(valid_order_num) AS valid_orders,
           SUM(tot_homepage_activity_expose_num) AS hp_expose,
           SUM(tot_homepage_activity_clc_num) AS hp_clicks,
           BITMAP_UNION(tot_homepage_activity_clc_uids) AS hp_click_bm,
           BITMAP_UNION(tot_takeaway_detailpage_uids) AS detail_bm,
           BITMAP_UNION(tot_takeaway_baoming_button_clc_uids) AS baoming_click_bm,
           BITMAP_UNION(baoming_uids) AS baoming_bm,
           BITMAP_UNION(valid_uids) AS valid_bm
    FROM dws.dws_sr_store_takeawaypro_statis_d s
    WHERE s.dt BETWEEN '2026-03-15' AND '2026-04-15'
      AND s.promotion_quota > 0
      AND s.danpin_type IS NULL  -- 排除拼好饭/爆品团(此时不存在)
    GROUP BY dt, supply_type
),
daily_metrics AS (
    SELECT dt, supply_type,
           SUM(valid_orders) AS orders,
           ROUND(SUM(valid_orders) * 100.0 / NULLIF(SUM(total_quota), 0), 2) AS 销单率,
           ROUND(SUM(hp_clicks) * 100.0 / NULLIF(SUM(hp_expose), 0), 2) AS CTR,
           SUM(BITMAP_COUNT(hp_click_bm)) AS 点击人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_click_bm))) AS 报名按钮人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, detail_bm))) AS 详情人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, baoming_bm))) AS 报名人天,
           SUM(BITMAP_COUNT(BITMAP_AND(hp_click_bm, valid_bm))) AS 完单人天
    FROM daily
    GROUP BY dt, supply_type
),
summary AS (
    SELECT supply_type,
           CASE WHEN dt < '2026-04-01' THEN 'Pre(3/15-3/31)' ELSE 'Post(4/1-4/15)' END AS period,
           ROUND(AVG(销单率), 2) AS avg_销单率,
           ROUND(AVG(CTR), 2) AS avg_CTR,
           ROUND(SUM(报名按钮人天) * 100.0 / NULLIF(SUM(详情人天), 0), 2) AS 详情到报名按钮,
           ROUND(SUM(完单人天) * 100.0 / NULLIF(SUM(报名人天), 0), 2) AS 报名到完单,
           ROUND(SUM(完单人天) * 100.0 / NULLIF(SUM(点击人天), 0), 2) AS 点击到完单
    FROM daily_metrics
    GROUP BY supply_type, period
)
SELECT supply_type, period,
       avg_销单率, avg_CTR, 详情到报名按钮, 报名到完单, 点击到完单
FROM summary
ORDER BY supply_type, period;
