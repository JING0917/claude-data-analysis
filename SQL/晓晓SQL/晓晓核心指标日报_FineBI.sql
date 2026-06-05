-- ============================================================
-- 晓晓核心指标日报 — FineBI 数据集
-- 生成日期：2026-05-22
-- 数据连接：晓晓生产-xxh库 (MySQL)
-- 架构：扫最近8天 → 按日汇总 → MAX(CASE WHEN)行转列 → 1行输出(昨日/前日/上周+日环比/周同比)
-- 性能：daily_all只引用一次(MySQL物化一次)；DATE()改列直查利用idx_create_date、idx_create_time、data_state等索引
-- ============================================================

WITH

-- 1. 日期序列（最近8天）
dates AS (
    SELECT DATE_SUB(CURDATE(), INTERVAL n DAY) AS dt
    FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8) t
),

-- 2. 流量明细（DAU、留存共用）
traffic AS (
    SELECT visit_day, user_id
    FROM bwc_client_user_visit_record
    WHERE visit_day BETWEEN DATE_SUB(CURDATE(), INTERVAL 8 DAY)
                        AND DATE_SUB(CURDATE(), INTERVAL 1 DAY)
      AND data_state = 0 AND user_id <> 0
    GROUP BY 1, 2
),

-- 3. 每日活动名额
daily_quota AS (
    SELECT DATE(t.task_start_time) AS dt,
           COUNT(t.id)                                                                      AS `总活动数`,
           COUNT(IF(t.task_type NOT IN (3,4,5,7,8,9,10,14,24,25,26,27,28,29), t.id, NULL)) AS `自营活动数`,
           COUNT(IF(t.task_type IN (24,25,26), t.id, NULL))                                 AS `开放平台活动数`,
           SUM(t.task_total_quota)                                                          AS `总活动名额`,
           SUM(IF(t.task_type NOT IN (3,4,5,7,8,9,10,14,24,25,26,27,28,29),
                  t.task_total_quota, 0))                                                   AS `自营活动名额`,
           SUM(IF(t.task_type IN (24,25,26), t.task_total_quota, 0))                        AS `开放平台活动名额`
    FROM bwc_task t
    WHERE t.task_start_time >= DATE_SUB(CURDATE(), INTERVAL 8 DAY)
      AND t.task_start_time <  CURDATE()
      AND t.data_state = 0
    GROUP BY 1
),

-- 4. 每日报名订单量
daily_baoming AS (
    SELECT a.create_date AS dt,
           COUNT(a.id)                                                                      AS `总报名订单量`,
           COUNT(IF(b.id NOT IN (3,4,5,7,8,9,10,14,24,25,26,27,28,29), a.id, NULL))        AS `自营报名订单量`,
           COUNT(IF(b.id IN (24,25,26), a.id, NULL))                                        AS `开放平台报名订单量`,
           COUNT(IF(b.id IN (3,5,9,14,27), a.id, NULL))                                     AS `美团官方报名订单量`
    FROM bwc_order a
    LEFT JOIN bwc_business_platform b ON a.platform_id = b.id AND b.data_state = 0
    WHERE a.create_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 8 DAY)
                          AND DATE_SUB(CURDATE(), INTERVAL 1 DAY)
      AND a.data_state = 0 AND a.user_id > 0
    GROUP BY 1
),

-- 5. 每日销单量（order_status = 4）
daily_valid AS (
    SELECT a.create_date AS dt,
           COUNT(a.id)                                                                      AS `总有效订单量`,
           COUNT(IF(b.id NOT IN (3,4,5,7,8,9,10,14,24,25,26,27,28,29), a.id, NULL))        AS `自营有效订单量`,
           COUNT(IF(b.id IN (24,25,26), a.id, NULL))                                        AS `开放平台有效订单量`,
           COUNT(IF(b.id IN (3,5,9,14,27), a.id, NULL))                                     AS `美团官方有效订单量`
    FROM bwc_order a
    LEFT JOIN bwc_business_platform b ON a.platform_id = b.id AND b.data_state = 0
    WHERE a.create_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 8 DAY)
                          AND DATE_SUB(CURDATE(), INTERVAL 1 DAY)
      AND a.data_state = 0 AND a.order_status = 4 AND a.user_id > 0
    GROUP BY 1
),

-- 6. 每日订单利润
daily_profit AS (
    SELECT a.create_date AS dt,
           COALESCE(SUM(t.task_receipt_price - t.cash_back_amount), 0) AS `订单利润`
    FROM bwc_order a
    LEFT JOIN bwc_task t ON a.task_id = t.id AND t.data_state = 0
    WHERE a.create_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 8 DAY)
                          AND DATE_SUB(CURDATE(), INTERVAL 1 DAY)
      AND a.data_state = 0 AND a.order_status IN (3, -2, 4, -3)
      AND a.user_id > 0 AND a.platform_id BETWEEN 1 AND 29
    GROUP BY 1
),

-- 7. 每日新用户：注册量 + 当日完单 + 次日/7日留存（一次扫 bwc_user，关联 traffic）
daily_new_user AS (
    SELECT DATE(u.create_time) AS dt,
           COUNT(DISTINCT u.id)                                                            AS `注册用户量`,
           COUNT(DISTINCT IF(DATEDIFF(DATE(u.first_order_time), DATE(u.create_time)) = 0,
                             u.id, NULL))                                                  AS `当日完单用户量`,
           COUNT(DISTINCT IF(t1.user_id IS NOT NULL, u.id, NULL))                          AS `次日访问留存用户量`,
           COUNT(DISTINCT IF(t7.user_id IS NOT NULL, u.id, NULL))                          AS `7日访问留存用户量`,
           COUNT(DISTINCT IF(t1.user_id IS NOT NULL, u.id, NULL))
               / NULLIF(COUNT(DISTINCT u.id), 0)                                           AS `次日留存率`,
           COUNT(DISTINCT IF(t7.user_id IS NOT NULL, u.id, NULL))
               / NULLIF(COUNT(DISTINCT u.id), 0)                                           AS `7日留存率`
    FROM bwc_user u
    LEFT JOIN traffic t1 ON u.id = t1.user_id
        AND t1.visit_day = DATE_ADD(DATE(u.create_time), INTERVAL 1 DAY)
    LEFT JOIN traffic t7 ON u.id = t7.user_id
        AND t7.visit_day = DATE_ADD(DATE(u.create_time), INTERVAL 7 DAY)
    WHERE u.create_time >= DATE_SUB(CURDATE(), INTERVAL 8 DAY)
      AND u.create_time <  CURDATE()
      AND u.data_state = 0 AND u.first_register = 1
    GROUP BY 1
),

-- 8. 每日DAU
daily_dau AS (
    SELECT visit_day AS dt,
           COUNT(DISTINCT user_id) AS `整体DAU`
    FROM traffic
    GROUP BY 1
),

-- 9. 每日整体留存（自关联 traffic）
daily_retention AS (
    SELECT a.visit_day AS dt,
           COUNT(DISTINCT a.user_id)                                                       AS `整体DAU_base`,
           COUNT(DISTINCT IF(b.user_id IS NOT NULL, a.user_id, NULL))                      AS `整体次日留存用户量`,
           COUNT(DISTINCT IF(c.user_id IS NOT NULL, a.user_id, NULL))                      AS `整体7日留存用户量`,
           COUNT(DISTINCT IF(b.user_id IS NOT NULL, a.user_id, NULL))
               / NULLIF(COUNT(DISTINCT a.user_id), 0)                                      AS `整体次日留存率`,
           COUNT(DISTINCT IF(c.user_id IS NOT NULL, a.user_id, NULL))
               / NULLIF(COUNT(DISTINCT a.user_id), 0)                                      AS `整体7日留存率`
    FROM traffic a
    LEFT JOIN traffic b ON a.user_id = b.user_id
        AND b.visit_day = DATE_ADD(a.visit_day, INTERVAL 1 DAY)
    LEFT JOIN traffic c ON a.user_id = c.user_id
        AND c.visit_day = DATE_ADD(a.visit_day, INTERVAL 7 DAY)
    GROUP BY 1
),

-- ★ 全部日指标合并到一张表（按日期 LEFT JOIN）
daily_all AS (
    SELECT d.dt,
           q.`总活动数`,       q.`自营活动数`,       q.`开放平台活动数`,
           q.`总活动名额`,     q.`自营活动名额`,     q.`开放平台活动名额`,
           b.`总报名订单量`,   b.`自营报名订单量`,   b.`开放平台报名订单量`,   b.`美团官方报名订单量`,
           v.`总有效订单量`,   v.`自营有效订单量`,   v.`开放平台有效订单量`,   v.`美团官方有效订单量`,
           v.`自营有效订单量`       / NULLIF(q.`自营活动名额`, 0)     AS `自营销单率`,
           v.`开放平台有效订单量`   / NULLIF(q.`开放平台活动名额`, 0) AS `开放平台销单率`,
           p.`订单利润`,
           nu.`注册用户量`,     nu.`当日完单用户量`,
           nu.`次日访问留存用户量`, nu.`7日访问留存用户量`,
           nu.`次日留存率`,     nu.`7日留存率`,
           dau.`整体DAU`,
           r.`整体次日留存用户量`, r.`整体7日留存用户量`,
           r.`整体次日留存率`,     r.`整体7日留存率`
    FROM dates d
    LEFT JOIN daily_quota    q   ON d.dt = q.dt
    LEFT JOIN daily_baoming  b   ON d.dt = b.dt
    LEFT JOIN daily_valid    v   ON d.dt = v.dt
    LEFT JOIN daily_profit   p   ON d.dt = p.dt
    LEFT JOIN daily_new_user nu  ON d.dt = nu.dt
    LEFT JOIN daily_dau      dau ON d.dt = dau.dt
    LEFT JOIN daily_retention r  ON d.dt = r.dt
),

-- ============================================================
-- 最终输出：1行，MAX(CASE WHEN)行转列，daily_all只引用一次，MySQL物化一次
-- 昨日值/前日值/上周值/日环比/周同比，FineBI直接引用字段名
-- ============================================================
pivot_base AS (
    SELECT
        -- ===== 活动数 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `总活动数` END)       AS `总活动数`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `总活动数` END)       AS `前日总活动数`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `总活动数` END)       AS `上周总活动数`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `自营活动数` END)     AS `自营活动数`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `自营活动数` END)     AS `前日自营活动数`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `自营活动数` END)     AS `上周自营活动数`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `开放平台活动数` END)   AS `开放平台活动数`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `开放平台活动数` END)   AS `前日开放平台活动数`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `开放平台活动数` END)   AS `上周开放平台活动数`,

        -- ===== 活动名额 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `总活动名额` END)     AS `总活动名额`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `总活动名额` END)     AS `前日总活动名额`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `总活动名额` END)     AS `上周总活动名额`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `自营活动名额` END)   AS `自营活动名额`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `自营活动名额` END)   AS `前日自营活动名额`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `自营活动名额` END)   AS `上周自营活动名额`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `开放平台活动名额` END) AS `开放平台活动名额`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `开放平台活动名额` END) AS `前日开放平台活动名额`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `开放平台活动名额` END) AS `上周开放平台活动名额`,

        -- ===== 报名订单量 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `总报名订单量` END)     AS `总报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `总报名订单量` END)     AS `前日总报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `总报名订单量` END)     AS `上周总报名订单量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `自营报名订单量` END)   AS `自营报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `自营报名订单量` END)   AS `前日自营报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `自营报名订单量` END)   AS `上周自营报名订单量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `开放平台报名订单量` END) AS `开放平台报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `开放平台报名订单量` END) AS `前日开放平台报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `开放平台报名订单量` END) AS `上周开放平台报名订单量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `美团官方报名订单量` END) AS `美团官方报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `美团官方报名订单量` END) AS `前日美团官方报名订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `美团官方报名订单量` END) AS `上周美团官方报名订单量`,

        -- ===== 有效订单量 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `总有效订单量` END)     AS `总有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `总有效订单量` END)     AS `前日总有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `总有效订单量` END)     AS `上周总有效订单量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `自营有效订单量` END)   AS `自营有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `自营有效订单量` END)   AS `前日自营有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `自营有效订单量` END)   AS `上周自营有效订单量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `开放平台有效订单量` END) AS `开放平台有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `开放平台有效订单量` END) AS `前日开放平台有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `开放平台有效订单量` END) AS `上周开放平台有效订单量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `美团官方有效订单量` END) AS `美团官方有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `美团官方有效订单量` END) AS `前日美团官方有效订单量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `美团官方有效订单量` END) AS `上周美团官方有效订单量`,

        -- ===== 销单率（比率指标） =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `自营销单率` END)       AS `自营销单率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `自营销单率` END)       AS `前日自营销单率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `自营销单率` END)       AS `上周自营销单率`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `开放平台销单率` END)     AS `开放平台销单率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `开放平台销单率` END)     AS `前日开放平台销单率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `开放平台销单率` END)     AS `上周开放平台销单率`,

        -- ===== 订单利润 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `订单利润` END)         AS `订单利润`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `订单利润` END)         AS `前日订单利润`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `订单利润` END)         AS `上周订单利润`,

        -- ===== 新用户 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `注册用户量` END)       AS `注册用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `注册用户量` END)       AS `前日注册用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `注册用户量` END)       AS `上周注册用户量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `当日完单用户量` END)     AS `当日完单用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `当日完单用户量` END)     AS `前日当日完单用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `当日完单用户量` END)     AS `上周当日完单用户量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `次日访问留存用户量` END) AS `次日访问留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `次日访问留存用户量` END) AS `前日次日访问留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `次日访问留存用户量` END) AS `上周次日访问留存用户量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `7日访问留存用户量` END) AS `7日访问留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `7日访问留存用户量` END) AS `前日7日访问留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `7日访问留存用户量` END) AS `上周7日访问留存用户量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `次日留存率` END)       AS `次日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `次日留存率` END)       AS `前日次日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `次日留存率` END)       AS `上周次日留存率`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `7日留存率` END)       AS `7日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `7日留存率` END)       AS `前日7日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `7日留存率` END)       AS `上周7日留存率`,

        -- ===== DAU =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `整体DAU` END)         AS `整体DAU`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `整体DAU` END)         AS `前日整体DAU`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `整体DAU` END)         AS `上周整体DAU`,

        -- ===== 整体留存 =====
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `整体次日留存用户量` END) AS `整体次日留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `整体次日留存用户量` END) AS `前日整体次日留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `整体次日留存用户量` END) AS `上周整体次日留存用户量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `整体7日留存用户量` END) AS `整体7日留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `整体7日留存用户量` END) AS `前日整体7日留存用户量`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `整体7日留存用户量` END) AS `上周整体7日留存用户量`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `整体次日留存率` END)   AS `整体次日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `整体次日留存率` END)   AS `前日整体次日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `整体次日留存率` END)   AS `上周整体次日留存率`,

        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN `整体7日留存率` END)   AS `整体7日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 2 DAY) THEN `整体7日留存率` END)   AS `前日整体7日留存率`,
        MAX(CASE WHEN dt = DATE_SUB(CURDATE(), INTERVAL 8 DAY) THEN `整体7日留存率` END)   AS `上周整体7日留存率`

    FROM daily_all
    WHERE dt IN (
        DATE_SUB(CURDATE(), INTERVAL 1 DAY),
        DATE_SUB(CURDATE(), INTERVAL 2 DAY),
        DATE_SUB(CURDATE(), INTERVAL 8 DAY)
    )
)

SELECT
    -- ===== 活动数 =====
    `总活动数`, `前日总活动数`, `上周总活动数`,
    `总活动数` / NULLIF(`前日总活动数`, 0) - 1     AS `总活动数日环比`,
    `总活动数` / NULLIF(`上周总活动数`, 0) - 1    AS `总活动数周同比`,

    `自营活动数`, `前日自营活动数`, `上周自营活动数`,
    `自营活动数` / NULLIF(`前日自营活动数`, 0) - 1   AS `自营活动数日环比`,
    `自营活动数` / NULLIF(`上周自营活动数`, 0) - 1  AS `自营活动数周同比`,

    `开放平台活动数`, `前日开放平台活动数`, `上周开放平台活动数`,
    `开放平台活动数` / NULLIF(`前日开放平台活动数`, 0) - 1   AS `开放平台活动数日环比`,
    `开放平台活动数` / NULLIF(`上周开放平台活动数`, 0) - 1  AS `开放平台活动数周同比`,

    -- ===== 活动名额 =====
    `总活动名额`, `前日总活动名额`, `上周总活动名额`,
    `总活动名额` / NULLIF(`前日总活动名额`, 0) - 1   AS `总活动名额日环比`,
    `总活动名额` / NULLIF(`上周总活动名额`, 0) - 1  AS `总活动名额周同比`,

    `自营活动名额`, `前日自营活动名额`, `上周自营活动名额`,
    `自营活动名额` / NULLIF(`前日自营活动名额`, 0) - 1   AS `自营活动名额日环比`,
    `自营活动名额` / NULLIF(`上周自营活动名额`, 0) - 1  AS `自营活动名额周同比`,

    `开放平台活动名额`, `前日开放平台活动名额`, `上周开放平台活动名额`,
    `开放平台活动名额` / NULLIF(`前日开放平台活动名额`, 0) - 1   AS `开放平台活动名额日环比`,
    `开放平台活动名额` / NULLIF(`上周开放平台活动名额`, 0) - 1  AS `开放平台活动名额周同比`,

    -- ===== 报名订单量 =====
    `总报名订单量`, `前日总报名订单量`, `上周总报名订单量`,
    `总报名订单量` / NULLIF(`前日总报名订单量`, 0) - 1   AS `总报名订单量日环比`,
    `总报名订单量` / NULLIF(`上周总报名订单量`, 0) - 1  AS `总报名订单量周同比`,

    `自营报名订单量`, `前日自营报名订单量`, `上周自营报名订单量`,
    `自营报名订单量` / NULLIF(`前日自营报名订单量`, 0) - 1   AS `自营报名订单量日环比`,
    `自营报名订单量` / NULLIF(`上周自营报名订单量`, 0) - 1  AS `自营报名订单量周同比`,

    `开放平台报名订单量`, `前日开放平台报名订单量`, `上周开放平台报名订单量`,
    `开放平台报名订单量` / NULLIF(`前日开放平台报名订单量`, 0) - 1   AS `开放平台报名订单量日环比`,
    `开放平台报名订单量` / NULLIF(`上周开放平台报名订单量`, 0) - 1  AS `开放平台报名订单量周同比`,

    `美团官方报名订单量`, `前日美团官方报名订单量`, `上周美团官方报名订单量`,
    `美团官方报名订单量` / NULLIF(`前日美团官方报名订单量`, 0) - 1   AS `美团官方报名订单量日环比`,
    `美团官方报名订单量` / NULLIF(`上周美团官方报名订单量`, 0) - 1  AS `美团官方报名订单量周同比`,

    -- ===== 有效订单量 =====
    `总有效订单量`, `前日总有效订单量`, `上周总有效订单量`,
    `总有效订单量` / NULLIF(`前日总有效订单量`, 0) - 1   AS `总有效订单量日环比`,
    `总有效订单量` / NULLIF(`上周总有效订单量`, 0) - 1  AS `总有效订单量周同比`,

    `自营有效订单量`, `前日自营有效订单量`, `上周自营有效订单量`,
    `自营有效订单量` / NULLIF(`前日自营有效订单量`, 0) - 1   AS `自营有效订单量日环比`,
    `自营有效订单量` / NULLIF(`上周自营有效订单量`, 0) - 1  AS `自营有效订单量周同比`,

    `开放平台有效订单量`, `前日开放平台有效订单量`, `上周开放平台有效订单量`,
    `开放平台有效订单量` / NULLIF(`前日开放平台有效订单量`, 0) - 1   AS `开放平台有效订单量日环比`,
    `开放平台有效订单量` / NULLIF(`上周开放平台有效订单量`, 0) - 1  AS `开放平台有效订单量周同比`,

    `美团官方有效订单量`, `前日美团官方有效订单量`, `上周美团官方有效订单量`,
    `美团官方有效订单量` / NULLIF(`前日美团官方有效订单量`, 0) - 1   AS `美团官方有效订单量日环比`,
    `美团官方有效订单量` / NULLIF(`上周美团官方有效订单量`, 0) - 1  AS `美团官方有效订单量周同比`,

    -- ===== 销单率（比率指标，仅输出值） =====
    `自营销单率`, `前日自营销单率`, `上周自营销单率`,
    `开放平台销单率`, `前日开放平台销单率`, `上周开放平台销单率`,

    -- ===== 订单利润 =====
    `订单利润`, `前日订单利润`, `上周订单利润`,
    `订单利润` / NULLIF(`前日订单利润`, 0) - 1     AS `订单利润日环比`,
    `订单利润` / NULLIF(`上周订单利润`, 0) - 1    AS `订单利润周同比`,

    -- ===== 新用户 =====
    `注册用户量`, `前日注册用户量`, `上周注册用户量`,
    `注册用户量` / NULLIF(`前日注册用户量`, 0) - 1   AS `注册用户量日环比`,
    `注册用户量` / NULLIF(`上周注册用户量`, 0) - 1  AS `注册用户量周同比`,

    `当日完单用户量`, `前日当日完单用户量`, `上周当日完单用户量`,
    `当日完单用户量` / NULLIF(`前日当日完单用户量`, 0) - 1   AS `当日完单用户量日环比`,
    `当日完单用户量` / NULLIF(`上周当日完单用户量`, 0) - 1  AS `当日完单用户量周同比`,

    `次日访问留存用户量`, `前日次日访问留存用户量`, `上周次日访问留存用户量`,
    `次日访问留存用户量` / NULLIF(`前日次日访问留存用户量`, 0) - 1   AS `次日访问留存用户量日环比`,
    `次日访问留存用户量` / NULLIF(`上周次日访问留存用户量`, 0) - 1  AS `次日访问留存用户量周同比`,

    `7日访问留存用户量`, `前日7日访问留存用户量`, `上周7日访问留存用户量`,
    `7日访问留存用户量` / NULLIF(`前日7日访问留存用户量`, 0) - 1   AS `7日访问留存用户量日环比`,
    `7日访问留存用户量` / NULLIF(`上周7日访问留存用户量`, 0) - 1  AS `7日访问留存用户量周同比`,

    `次日留存率`, `前日次日留存率`, `上周次日留存率`,
    `7日留存率`, `前日7日留存率`, `上周7日留存率`,

    -- ===== DAU =====
    `整体DAU`, `前日整体DAU`, `上周整体DAU`,
    `整体DAU` / NULLIF(`前日整体DAU`, 0) - 1     AS `整体DAU日环比`,
    `整体DAU` / NULLIF(`上周整体DAU`, 0) - 1    AS `整体DAU周同比`,

    -- ===== 整体留存 =====
    `整体次日留存用户量`, `前日整体次日留存用户量`, `上周整体次日留存用户量`,
    `整体次日留存用户量` / NULLIF(`前日整体次日留存用户量`, 0) - 1   AS `整体次日留存用户量日环比`,
    `整体次日留存用户量` / NULLIF(`上周整体次日留存用户量`, 0) - 1  AS `整体次日留存用户量周同比`,

    `整体7日留存用户量`, `前日整体7日留存用户量`, `上周整体7日留存用户量`,
    `整体7日留存用户量` / NULLIF(`前日整体7日留存用户量`, 0) - 1   AS `整体7日留存用户量日环比`,
    `整体7日留存用户量` / NULLIF(`上周整体7日留存用户量`, 0) - 1  AS `整体7日留存用户量周同比`,

    `整体次日留存率`, `前日整体次日留存率`, `上周整体次日留存率`,
    `整体7日留存率`, `前日整体7日留存率`, `上周整体7日留存率`

FROM pivot_base;
