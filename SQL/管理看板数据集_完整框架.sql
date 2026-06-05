-- ============================================================================
-- 小蚕管理看板 — 完整数据集SQL框架
-- author: hongxiu & claude
-- 日期: 2026-05-29
--
-- 使用说明:
--   1. 本文件包含 FineBI 所需的全部数据集 SQL（共11个）
--   2. 每个数据集 = 一个独立的 SQL 查询，可直接复制到 FineBI 数据集配置中
--   3. 参数说明:
--      ${startDate} — 起始日期（FineBI 日期控件传入，格式 yyyy-MM-dd）
--      ${endDate}   — 结束日期（同上）
--      ${mode}      — 视图模式：'day'=日视图, 'week'=周视图
--   4. StarRocks 数据集(1-10) + MySQL 数据集(11)
--   5. 晓晓订单数据在 MySQL，其余均在 StarRocks
--
-- 数据集清单:
--   [用户模块] ds_user_kpi / ds_dau_trend / ds_retention_curve / ds_retention_trend / ds_user_segment
--   [流量模块] ds_traffic_trend
--   [订单模块] ds_order_kpi / ds_order_trend / ds_xiaoxiao_order(MySQL)
--   [营销模块] ds_marketing_kpi / ds_marketing_trend
-- ============================================================================


-- ============================================================================
-- 数据集1: ds_user_kpi — 用户KPI卡片
-- 用途: 用户Tab顶部的5个KPI卡片
-- 输出: 1行，包含DAU、新注册、留存率、召回率 + 日环比 + 周同比
-- 参数: ${startDate}（通常为昨日）
-- ============================================================================

WITH
-- 1.1 DAU（当前 + 前1天 + 前7天，用于环比/同比）
t_dau AS (
    SELECT
        dt,
        bitmap_union_count(user_ids) AS dau
    FROM dwd.dwd_sr_traffic_viewuser_d
    WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                 AND '${startDate}'
      AND business_name <> '晓晓霸王餐'
    GROUP BY dt
),

-- 1.2 新注册用户量
t_newuser AS (
    SELECT
        DATE(register_time) AS dt,
        COUNT(*) AS newuser_num,
        COUNT(IF(inviter_user_id <> 0, 1, NULL)) AS tz_newuser_num,
        COUNT(IF(inviter_user_id = 0, 1, NULL)) AS zr_newuser_num
    FROM dim.dim_silkworm_user
    WHERE DATE(register_time) BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                                  AND '${startDate}'
    GROUP BY DATE(register_time)
),

-- 1.3 渠道拉新用户（用于拆分自然新增和渠道拉新）
t_qd_newuser AS (
    SELECT
        statistics_date AS dt,
        COUNT(DISTINCT user_id) AS qd_newuser_num
    FROM dwd.dwd_sr_user_newuser_channel_cost_d
    WHERE statistics_date BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                              AND '${startDate}'
      AND user_type = 2
    GROUP BY statistics_date
),

-- 1.4 用户留存率（全部 + 新用户，次日 + 7日）
t_retention AS (
    SELECT
        dt,
        MAX(IF(user_type = '全部' AND retain_day = 1, retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)) AS all_retain_d1,
        MAX(IF(user_type = '全部' AND retain_day = 7, retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)) AS all_retain_d7,
        MAX(IF(user_type = '注册' AND retain_day = 1, retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)) AS new_retain_d1,
        MAX(IF(user_type = '注册' AND retain_day = 7, retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)) AS new_retain_d7
    FROM dwd.dwd_sr_traffic_user_retention_d
    WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                 AND '${startDate}'
      AND user_type IN ('全部', '注册')
      AND retain_day IN (1, 7)
    GROUP BY dt
),

-- 1.5 沉默用户召回率（近30天无访问用户 / DAU）
t_recall AS (
    SELECT
        dt,
        MAX(IF(user_type = '近30天无访问', DAU, 0)) * 1.0
            / NULLIF(MAX(IF(user_type = '全部', DAU, 0)), 0) AS recall_rate
    FROM dwd.dwd_sr_traffic_user_retention_d
    WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                 AND '${startDate}'
      AND user_type IN ('全部', '近30天无访问')
      AND retain_day = 0
    GROUP BY dt
),

-- 1.6 月日均DAU（本月 vs 上月）
t_monthly_dau AS (
    SELECT
        CASE
            WHEN dt >= DATE_TRUNC('month', '${startDate}') THEN 'current'
            ELSE 'previous'
        END AS month_type,
        AVG(dau) AS avg_dau
    FROM (
        SELECT dt, bitmap_union_count(user_ids) AS dau
        FROM dwd.dwd_sr_traffic_viewuser_d
        WHERE dt >= DATE_TRUNC('month', DATE_SUB('${startDate}', INTERVAL 1 MONTH))
          AND dt <= '${startDate}'
          AND business_name <> '晓晓霸王餐'
        GROUP BY dt
    ) t
    GROUP BY month_type
)

-- 最终输出：1行 KPI
SELECT
    '${startDate}'                                                                     AS statistics_date,

    -- DAU
    MAX(CASE WHEN t1.dt = '${startDate}'                     THEN t1.dau END)          AS dau,
    MAX(CASE WHEN t1.dt = '${startDate}'                     THEN t1.dau END)
        / NULLIF(MAX(CASE WHEN t1.dt = DATE_SUB('${startDate}', INTERVAL 1 DAY) THEN t1.dau END), 0) - 1
                                                                                        AS dau_dod,
    MAX(CASE WHEN t1.dt = '${startDate}'                     THEN t1.dau END)
        / NULLIF(MAX(CASE WHEN t1.dt = DATE_SUB('${startDate}', INTERVAL 7 DAY) THEN t1.dau END), 0) - 1
                                                                                        AS dau_wow,

    -- 月日均DAU
    MAX(CASE WHEN t6.month_type = 'current'  THEN t6.avg_dau END)                      AS cur_month_avg_dau,
    MAX(CASE WHEN t6.month_type = 'previous' THEN t6.avg_dau END)                      AS last_month_avg_dau,
    MAX(CASE WHEN t6.month_type = 'current'  THEN t6.avg_dau END)
        / NULLIF(MAX(CASE WHEN t6.month_type = 'previous' THEN t6.avg_dau END), 0) - 1 AS month_dau_dod,

    -- 新注册用户
    MAX(CASE WHEN t2.dt = '${startDate}'                     THEN t2.newuser_num END)  AS newuser_num,
    MAX(CASE WHEN t2.dt = '${startDate}'                     THEN t2.newuser_num END)
        / NULLIF(MAX(CASE WHEN t2.dt = DATE_SUB('${startDate}', INTERVAL 1 DAY) THEN t2.newuser_num END), 0) - 1
                                                                                        AS newuser_dod,

    -- 新注册用户拆分
    MAX(CASE WHEN t2.dt = '${startDate}'                     THEN t2.tz_newuser_num END)    AS tz_newuser_num,
    MAX(CASE WHEN t2.dt = '${startDate}' AND t3.qd_newuser_num > 0 THEN t3.qd_newuser_num
             ELSE 0 END)                                                                     AS qd_newuser_num,
    MAX(CASE WHEN t2.dt = '${startDate}'                     THEN t2.zr_newuser_num - COALESCE(t3.qd_newuser_num, 0) END) AS zr_newuser_num,

    -- 留存率
    MAX(CASE WHEN t4.dt = '${startDate}' THEN t4.all_retain_d1 END)                    AS all_retain_d1,
    MAX(CASE WHEN t4.dt = '${startDate}' THEN t4.all_retain_d7 END)                    AS all_retain_d7,
    MAX(CASE WHEN t4.dt = '${startDate}' THEN t4.new_retain_d1 END)                    AS new_retain_d1,
    MAX(CASE WHEN t4.dt = '${startDate}' THEN t4.new_retain_d7 END)                    AS new_retain_d7,

    -- 沉默用户召回率
    MAX(CASE WHEN t5.dt = '${startDate}' THEN t5.recall_rate END)                      AS recall_rate

FROM t_dau t1
LEFT JOIN t_newuser t2   ON t1.dt = t2.dt
LEFT JOIN t_qd_newuser t3 ON t1.dt = t3.dt
LEFT JOIN t_retention t4 ON t1.dt = t4.dt
LEFT JOIN t_recall t5    ON t1.dt = t5.dt
CROSS JOIN t_monthly_dau t6
WHERE t1.dt = '${startDate}';


-- ============================================================================
-- 数据集2: ds_dau_trend — DAU趋势图
-- 用途: DAU折线图 + 环比/同比对比线
-- 输出: 日期序列（近30天），含DAU、日环比、周同比
-- 参数: ${endDate}（最新日期）、${mode}（day/week）
-- ============================================================================

SELECT
    dt,
    dau,
    dau / NULLIF(LAG(dau, 1)  OVER (ORDER BY dt), 0) - 1 AS dau_dod,
    dau / NULLIF(LAG(dau, 7)  OVER (ORDER BY dt), 0) - 1 AS dau_wow,
    dau / NULLIF(LAG(dau, 30) OVER (ORDER BY dt), 0) - 1 AS dau_mom
FROM (
    SELECT
        dt,
        bitmap_union_count(user_ids) AS dau
    FROM dwd.dwd_sr_traffic_viewuser_d
    WHERE dt BETWEEN DATE_SUB('${endDate}', INTERVAL 37 DAY)
                 AND '${endDate}'
      AND business_name <> '晓晓霸王餐'
    GROUP BY dt
) t
ORDER BY dt;


-- ============================================================================
-- 数据集3: ds_retention_curve — 留存曲线
-- 用途: 指定日期的 day1~day30 留存率曲线
-- 输出: 31行（retain_day=0..30），user_type=全部/注册
-- 参数: ${endDate}（要查看的锚点日期）
-- ============================================================================

SELECT
    dt,
    user_type,
    retain_day,
    retain_user_num AS user_count,
    DAU,
    retain_user_num * 1.0 / NULLIF(DAU, 0) AS retention_rate
FROM dwd.dwd_sr_traffic_user_retention_d
WHERE dt = '${endDate}'
  AND user_type IN ('全部', '注册')
ORDER BY user_type, retain_day;


-- ============================================================================
-- 数据集4: ds_retention_trend — 留存率趋势
-- 用途: 指定留存天数（如day7）的留存率随时间变化趋势
-- 输出: 日期序列，含全部/新用户的指定留存率
-- 参数: ${startDate}/${endDate}
-- 注: FineBI中可创建参数 ${retainDay} 让用户选择 day1/day3/day7/day14/day30
-- ============================================================================

SELECT
    dt,
    MAX(IF(user_type = '全部', retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)) AS all_retain_rate,
    MAX(IF(user_type = '注册', retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)) AS new_retain_rate,
    -- 日环比
    MAX(IF(user_type = '全部', retain_user_num * 1.0 / NULLIF(DAU, 0), NULL))
        / NULLIF(LAG(MAX(IF(user_type = '全部', retain_user_num * 1.0 / NULLIF(DAU, 0), NULL)))
                 OVER (ORDER BY dt), 0) - 1 AS all_retain_dod
FROM dwd.dwd_sr_traffic_user_retention_d
WHERE dt BETWEEN '${startDate}' AND '${endDate}'
  AND user_type IN ('全部', '注册')
  AND retain_day = ${retainDay}   -- 如 1/3/7/14/30
GROUP BY dt
ORDER BY dt;


-- ============================================================================
-- 数据集5: ds_user_segment — 用户分层构成
-- 用途: 饼图/堆叠柱状图，展示DAU的用户类型构成
-- 输出: 每个user_type的DAU + 占比
-- 参数: ${endDate}
-- ============================================================================

SELECT
    dt,
    user_type,
    DAU,
    DAU * 1.0 / NULLIF(SUM(DAU) OVER (PARTITION BY dt), 0) AS dau_pct
FROM dwd.dwd_sr_traffic_user_retention_d
WHERE dt = '${endDate}'
  AND retain_day = 0
  AND user_type IN (
      '注册', '近30天无访问',
      '近30天访问1-6天', '近30天访问7-12天', '近30天访问13-18天',
      '近30天访问19-24天', '近30天访问25-30天'
  )
ORDER BY DAU DESC;


-- ============================================================================
-- 数据集6: ds_order_kpi — 订单KPI卡片
-- 用途: 订单Tab顶部的KPI卡片
-- 输出: 1行，含自营/美团专版的有效订单量、利润、完单率、活动名额 + 环比/同比
-- 参数: ${endDate}（通常为昨日）
-- ============================================================================

WITH
-- 6.1 小蚕自营订单（来自店铺统计表，D-1 + D-2 + D-8 用于环比/同比）
t_self AS (
    SELECT
        dt,
        SUM(promotion_quota)                              AS quota,
        SUM(order_num)                                    AS order_num,
        SUM(valid_order_num)                              AS valid_order_num,
        SUM(cancel_order_num)                             AS cancel_order_num,
        SUM(handle_cancel_order_num)                      AS handle_cancel_num,
        SUM(timeout_cancel_order_num)                     AS timeout_cancel_num,
        SUM(profit)                                       AS profit,
        SUM(rebate_amt)                                   AS rebate_amt,
        SUM(redpacket_amt)                                AS redpacket_amt
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN DATE_SUB('${endDate}', INTERVAL 8 DAY)
                 AND '${endDate}'
    GROUP BY dt
),

-- 6.2 美团专版订单（来自订单明细表 order_type=12）
t_mt AS (
    SELECT
        dt,
        COUNT(DISTINCT store_promotion_id)                AS mt_promotion_num,
        COUNT(1)                                          AS mt_order_num,
        COUNT(IF(order_status IN (2, 8), 1, NULL))        AS mt_valid_order_num,
        COUNT(IF(order_status = 5, 1, NULL))              AS mt_cancel_order_num,
        SUM(IF(order_status = 2, profit, 0))              AS mt_profit
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt BETWEEN DATE_SUB('${endDate}', INTERVAL 8 DAY)
                 AND '${endDate}'
      AND order_type = 12   -- 美团专版
    GROUP BY dt
),

-- 6.3 美团专版名额（来自美团商家快照表）
t_mt_quota AS (
    SELECT
        dt,
        SUM(total_inventory)                              AS mt_quota,
        SUM(inventory)                                    AS mt_remain_quota,
        SUM(total_inventory) - SUM(inventory)             AS mt_used_quota
    FROM dwd.dwd_sr_silkworm_rcs_meituan_shangjin_store_snapshot
    WHERE dt BETWEEN DATE_SUB('${endDate}', INTERVAL 8 DAY)
                 AND '${endDate}'
    GROUP BY dt
)

-- 最终输出：1行
SELECT
    '${endDate}' AS statistics_date,

    -- 小蚕自营
    MAX(IF(t1.dt = '${endDate}', t1.quota, 0))                                                AS self_quota,
    MAX(IF(t1.dt = '${endDate}', t1.order_num, 0))                                            AS self_order_num,
    MAX(IF(t1.dt = '${endDate}', t1.valid_order_num, 0))                                      AS self_valid_order_num,
    MAX(IF(t1.dt = '${endDate}', t1.profit, 0))                                               AS self_profit,
    -- 完单率
    MAX(IF(t1.dt = '${endDate}', t1.valid_order_num, 0)) * 1.0
        / NULLIF(MAX(IF(t1.dt = '${endDate}', t1.order_num, 0)), 0)                           AS self_complete_rate,
    -- 取消率
    MAX(IF(t1.dt = '${endDate}', t1.cancel_order_num, 0)) * 1.0
        / NULLIF(MAX(IF(t1.dt = '${endDate}', t1.order_num, 0)), 0)                           AS self_cancel_rate,

    -- 小蚕自营 日环比
    MAX(IF(t1.dt = '${endDate}', t1.valid_order_num, 0))
        / NULLIF(MAX(IF(t1.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t1.valid_order_num, 0)), 0) - 1
                                                                                                AS self_order_dod,
    -- 小蚕自营 周同比
    MAX(IF(t1.dt = '${endDate}', t1.valid_order_num, 0))
        / NULLIF(MAX(IF(t1.dt = DATE_SUB('${endDate}', INTERVAL 7 DAY), t1.valid_order_num, 0)), 0) - 1
                                                                                                AS self_order_wow,

    -- 美团专版
    MAX(IF(t2.dt = '${endDate}', t2.mt_promotion_num, 0))                                      AS mt_promotion_num,
    MAX(IF(t2.dt = '${endDate}', t2.mt_order_num, 0))                                          AS mt_order_num,
    MAX(IF(t2.dt = '${endDate}', t2.mt_valid_order_num, 0))                                    AS mt_valid_order_num,
    MAX(IF(t2.dt = '${endDate}', t2.mt_profit, 0))                                             AS mt_profit,
    -- 美团活动名额使用率
    MAX(IF(t3.dt = '${endDate}', t3.mt_used_quota, 0)) * 1.0
        / NULLIF(MAX(IF(t3.dt = '${endDate}', t3.mt_quota, 0)), 0)                             AS mt_quota_use_rate,

    -- 美团专版 日环比
    MAX(IF(t2.dt = '${endDate}', t2.mt_valid_order_num, 0))
        / NULLIF(MAX(IF(t2.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t2.mt_valid_order_num, 0)), 0) - 1
                                                                                                AS mt_order_dod,

    -- 合计
    MAX(IF(t1.dt = '${endDate}', t1.valid_order_num, 0))
        + MAX(IF(t2.dt = '${endDate}', t2.mt_valid_order_num, 0))                              AS total_valid_order_num

FROM t_self t1
LEFT JOIN t_mt t2       ON t1.dt = t2.dt
LEFT JOIN t_mt_quota t3 ON t1.dt = t3.dt
WHERE t1.dt = '${endDate}';


-- ============================================================================
-- 数据集7: ds_order_trend — 订单趋势图
-- 用途: 有效订单量 + 利润趋势（分小蚕自营/美团专版两条线）
-- 输出: 日期序列，含各类型订单量、利润、完单率 + 环比/周同比
-- 参数: ${startDate}/${endDate}
-- ============================================================================

WITH
-- 7.1 小蚕自营（日期范围 + 额外7天用于周同比）
t_self AS (
    SELECT
        dt,
        '小蚕自营'                                          AS order_type,
        SUM(valid_order_num)                                AS valid_order_num,
        SUM(order_num)                                      AS order_num,
        SUM(cancel_order_num)                               AS cancel_order_num,
        SUM(profit)                                         AS profit,
        SUM(rebate_amt)                                     AS rebate_amt
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                 AND '${endDate}'
    GROUP BY dt
),

-- 7.2 美团专版
t_mt AS (
    SELECT
        dt,
        '美团专版'                                          AS order_type,
        COUNT(IF(order_status IN (2, 8), 1, NULL))         AS valid_order_num,
        COUNT(1)                                            AS order_num,
        COUNT(IF(order_status = 5, 1, NULL))               AS cancel_order_num,
        SUM(IF(order_status = 2, profit, 0))               AS profit,
        0                                                   AS rebate_amt
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                 AND '${endDate}'
      AND order_type = 12
    GROUP BY dt
),

-- 7.3 UNION ALL
t_union AS (
    SELECT * FROM t_self
    UNION ALL
    SELECT * FROM t_mt
)

SELECT
    dt,
    order_type,
    valid_order_num,
    order_num,
    profit,
    cancel_order_num * 1.0 / NULLIF(order_num, 0)          AS cancel_rate,
    valid_order_num * 1.0 / NULLIF(order_num, 0)           AS complete_rate,
    -- 日环比
    valid_order_num / NULLIF(LAG(valid_order_num, 1) OVER (
        PARTITION BY order_type ORDER BY dt), 0) - 1       AS order_dod,
    -- 周同比
    valid_order_num / NULLIF(LAG(valid_order_num, 7) OVER (
        PARTITION BY order_type ORDER BY dt), 0) - 1       AS order_wow
FROM t_union
WHERE dt BETWEEN '${startDate}' AND '${endDate}'
ORDER BY dt, order_type;


-- ============================================================================
-- 数据集8: ds_marketing_kpi — 营销KPI卡片
-- 用途: 营销Tab顶部的KPI卡片
-- 输出: 1行，含营销总费用、ROI、优惠券发放/核销、CAC + 环比
-- 参数: ${endDate}
-- ============================================================================

WITH
-- 8.1 非红包卡券营销支出
t_cost AS (
    SELECT
        statistics_date AS dt,
        SUM(IF(cost_typename = '团长拉新奖励', cost_amt, 0))   AS tz_newuser_cost,
        SUM(IF(cost_typename = '渠道拉新', cost_amt, 0))       AS qd_newuser_cost,
        SUM(IF(cost_typename = '下单挑战赛', cost_amt, 0))     AS ordtz_cost,
        SUM(IF(cost_typename = '邀请挑战赛', cost_amt, 0))     AS invitz_cost,
        SUM(IF(cost_typename = '达人团长拉新', cost_amt, 0))   AS dr_newuser_cost,
        SUM(IF(cost_typename = '用户补偿蚕豆', cost_amt, 0))   AS bc_cost,
        SUM(cost_amt)                                          AS total_marketing_cost
    FROM ads.ads_sr_marketing_cost_d
    WHERE statistics_date BETWEEN DATE_SUB('${endDate}', INTERVAL 8 DAY)
                              AND '${endDate}'
    GROUP BY statistics_date
),

-- 8.2 卡券红包消耗
t_coupon AS (
    SELECT
        statistics_date AS dt,
        SUM(grant_num)                                         AS total_grant_num,
        SUM(used_num)                                          AS total_used_num,
        SUM(cost_amt)                                          AS total_coupon_cost
    FROM dws.dws_sr_marketing_cost_coupon_d
    WHERE statistics_date BETWEEN DATE_SUB('${endDate}', INTERVAL 8 DAY)
                              AND '${endDate}'
      AND (coupon_name NOT REGEXP '测试' OR coupon_desc NOT REGEXP '测试')
    GROUP BY statistics_date
),

-- 8.3 新用户量（用于CAC计算）
t_newuser AS (
    SELECT
        DATE(register_time) AS dt,
        COUNT(*) AS newuser_num
    FROM dim.dim_silkworm_user
    WHERE DATE(register_time) BETWEEN DATE_SUB('${endDate}', INTERVAL 8 DAY)
                                  AND '${endDate}'
    GROUP BY DATE(register_time)
)

SELECT
    '${endDate}' AS statistics_date,

    -- 营销总费用
    MAX(IF(t1.dt = '${endDate}', t1.total_marketing_cost, 0))
        + MAX(IF(t2.dt = '${endDate}', t2.total_coupon_cost, 0))                        AS total_cost,

    -- 营销费用日环比
    (MAX(IF(t1.dt = '${endDate}', t1.total_marketing_cost, 0))
        + MAX(IF(t2.dt = '${endDate}', t2.total_coupon_cost, 0)))
        / NULLIF(
            MAX(IF(t1.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t1.total_marketing_cost, 0))
            + MAX(IF(t2.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t2.total_coupon_cost, 0)),
        0) - 1                                                                           AS total_cost_dod,

    -- 各类型费用
    MAX(IF(t1.dt = '${endDate}', t1.tz_newuser_cost, 0))                                 AS tz_newuser_cost,
    MAX(IF(t1.dt = '${endDate}', t1.qd_newuser_cost, 0))                                 AS qd_newuser_cost,
    MAX(IF(t1.dt = '${endDate}', t1.ordtz_cost, 0))                                      AS ordtz_cost,
    MAX(IF(t1.dt = '${endDate}', t1.invitz_cost, 0))                                     AS invitz_cost,
    MAX(IF(t1.dt = '${endDate}', t1.dr_newuser_cost, 0))                                 AS dr_newuser_cost,

    -- 优惠券发放/核销
    MAX(IF(t2.dt = '${endDate}', t2.total_grant_num, 0))                                 AS coupon_grant_num,
    MAX(IF(t2.dt = '${endDate}', t2.total_used_num, 0))                                  AS coupon_used_num,
    MAX(IF(t2.dt = '${endDate}', t2.total_used_num, 0)) * 1.0
        / NULLIF(MAX(IF(t2.dt = '${endDate}', t2.total_grant_num, 0)), 0)                AS coupon_use_rate,

    -- CAC = 营销总费用 / 新用户量（含渠道拉新）
    (MAX(IF(t1.dt = '${endDate}', t1.total_marketing_cost, 0))
        + MAX(IF(t2.dt = '${endDate}', t2.total_coupon_cost, 0)))
        / NULLIF(MAX(IF(t3.dt = '${endDate}', t3.newuser_num, 0)), 0)                    AS cac,

    -- CAC日环比
    ((MAX(IF(t1.dt = '${endDate}', t1.total_marketing_cost, 0))
        + MAX(IF(t2.dt = '${endDate}', t2.total_coupon_cost, 0)))
        / NULLIF(MAX(IF(t3.dt = '${endDate}', t3.newuser_num, 0)), 0))
    / NULLIF(
        (MAX(IF(t1.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t1.total_marketing_cost, 0))
        + MAX(IF(t2.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t2.total_coupon_cost, 0)))
        / NULLIF(MAX(IF(t3.dt = DATE_SUB('${endDate}', INTERVAL 1 DAY), t3.newuser_num, 0)), 0),
    0) - 1                                                                               AS cac_dod

FROM t_cost t1
LEFT JOIN t_coupon t2   ON t1.dt = t2.dt
LEFT JOIN t_newuser t3  ON t1.dt = t3.dt
WHERE t1.dt = '${endDate}';


-- ============================================================================
-- 数据集9: ds_marketing_trend — 营销趋势图
-- 用途: 营销费用日趋势 + ROI趋势
-- 输出: 日期序列，含各类型费用、环比
-- 参数: ${startDate}/${endDate}
-- ============================================================================

WITH
-- 9.1 非红包卡券支出
t_cost AS (
    SELECT
        statistics_date AS dt,
        SUM(IF(cost_typename = '团长拉新奖励', cost_amt, 0))   AS tz_newuser_cost,
        SUM(IF(cost_typename = '渠道拉新', cost_amt, 0))       AS qd_newuser_cost,
        SUM(IF(cost_typename = '下单挑战赛', cost_amt, 0))     AS ordtz_cost,
        SUM(IF(cost_typename = '邀请挑战赛', cost_amt, 0))     AS invitz_cost,
        SUM(IF(cost_typename = '达人团长拉新', cost_amt, 0))   AS dr_newuser_cost,
        SUM(cost_amt)                                          AS non_coupon_cost
    FROM ads.ads_sr_marketing_cost_d
    WHERE statistics_date BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                              AND '${endDate}'
    GROUP BY statistics_date
),

-- 9.2 卡券红包消耗
t_coupon AS (
    SELECT
        statistics_date AS dt,
        SUM(cost_amt)                                          AS coupon_cost
    FROM dws.dws_sr_marketing_cost_coupon_d
    WHERE statistics_date BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                              AND '${endDate}'
      AND (coupon_name NOT REGEXP '测试' OR coupon_desc NOT REGEXP '测试')
    GROUP BY statistics_date
),

-- 9.3 订单利润（用于计算ROI）
t_profit AS (
    SELECT
        dt,
        SUM(profit) AS total_profit
    FROM (
        -- 自营利润
        SELECT dt, SUM(profit) AS profit
        FROM dws.dws_sr_store_takeawaypro_statis_d
        WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY) AND '${endDate}'
        GROUP BY dt
        UNION ALL
        -- 美团专版利润
        SELECT dt, SUM(IF(order_status = 2, profit, 0)) AS profit
        FROM dwd.dwd_sr_order_promotion_order
        WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY) AND '${endDate}'
          AND order_type = 12
        GROUP BY dt
    ) t
    GROUP BY dt
)

SELECT
    COALESCE(t1.dt, t2.dt, t3.dt)                            AS dt,
    COALESCE(t1.non_coupon_cost, 0)                           AS non_coupon_cost,
    COALESCE(t2.coupon_cost, 0)                               AS coupon_cost,
    COALESCE(t1.non_coupon_cost, 0) + COALESCE(t2.coupon_cost, 0) AS total_cost,
    COALESCE(t3.total_profit, 0)                              AS total_profit,
    -- ROI = 利润 / 营销费用
    COALESCE(t3.total_profit, 0)
        / NULLIF(COALESCE(t1.non_coupon_cost, 0) + COALESCE(t2.coupon_cost, 0), 0) AS roi,
    -- 费用日环比
    (COALESCE(t1.non_coupon_cost, 0) + COALESCE(t2.coupon_cost, 0))
        / NULLIF(LAG(COALESCE(t1.non_coupon_cost, 0) + COALESCE(t2.coupon_cost, 0))
                 OVER (ORDER BY COALESCE(t1.dt, t2.dt, t3.dt)), 0) - 1 AS cost_dod,
    -- 分项费用
    COALESCE(t1.tz_newuser_cost, 0)                           AS tz_newuser_cost,
    COALESCE(t1.qd_newuser_cost, 0)                           AS qd_newuser_cost,
    COALESCE(t1.ordtz_cost, 0)                                AS ordtz_cost,
    COALESCE(t1.invitz_cost, 0)                               AS invitz_cost,
    COALESCE(t1.dr_newuser_cost, 0)                           AS dr_newuser_cost
FROM t_cost t1
FULL OUTER JOIN t_coupon t2 ON t1.dt = t2.dt
FULL OUTER JOIN t_profit t3 ON COALESCE(t1.dt, t2.dt) = t3.dt
WHERE COALESCE(t1.dt, t2.dt, t3.dt) BETWEEN '${startDate}' AND '${endDate}'
ORDER BY dt;


-- ============================================================================
-- 数据集10: ds_traffic_trend — 流量趋势图
-- 用途: UV趋势（每日独立访客）+ 日环比 + 周同比
-- 输出: 日期序列
-- 参数: ${startDate}/${endDate}
-- ============================================================================

SELECT
    dt,
    UV,
    UV / NULLIF(LAG(UV, 1) OVER (ORDER BY dt), 0) - 1        AS uv_dod,
    UV / NULLIF(LAG(UV, 7) OVER (ORDER BY dt), 0) - 1        AS uv_wow
FROM (
    SELECT
        dt,
        bitmap_union_count(user_ids) AS UV
    FROM dwd.dwd_sr_traffic_viewuser_d
    WHERE dt BETWEEN DATE_SUB('${startDate}', INTERVAL 7 DAY)
                 AND '${endDate}'
      AND business_name <> '晓晓霸王餐'
    GROUP BY dt
) t
WHERE dt BETWEEN '${startDate}' AND '${endDate}'
ORDER BY dt;


-- ============================================================================
-- 数据集11: ds_xiaoxiao_order — 晓晓订单（MySQL）
-- 用途: 晓晓订单量、服务费利润趋势
-- 输出: 日期序列
-- 参数: ${startDate}/${endDate}
--
-- ★ 注意：此数据集在 MySQL 上执行，需在 FineBI 中配置 MySQL 数据源
--
-- 排除口径:
--   1. 排除开放平台小蚕部分: platform_id NOT IN (24, 25, 26)
--   2. 排除美团/饿了么/京东平台: platform_id NOT IN (mtg, elez, eleg 对应的 id)
--      如果无法关联 platform_abbreviation，则使用 platform_id NOT IN (24,25,26)
--      并额外排除已知的非晓晓 platform_id
--
-- 有效订单: order_status IN (3, -2, 4, -3)
-- 服务费利润: bwc_task.task_receipt_price - bwc_task.cash_back_amount
-- ============================================================================

SELECT
    DATE(o.create_time)                                            AS dt,
    COUNT(DISTINCT o.id)                                           AS xiaoxiao_order_num,
    COUNT(DISTINCT o.task_id)                                      AS xiaoxiao_task_num,
    SUM(t.task_receipt_price)                                      AS total_receipt_price,
    SUM(t.cash_back_amount)                                        AS total_cash_back,
    SUM(t.task_receipt_price - t.cash_back_amount)                 AS total_service_profit,
    -- 环比
    COUNT(DISTINCT o.id) / NULLIF(LAG(COUNT(DISTINCT o.id)) OVER (
        ORDER BY DATE(o.create_time)), 0) - 1                      AS order_dod

FROM bwc_order o
INNER JOIN bwc_task t
    ON o.task_id = t.id
    AND t.data_state = 0

WHERE o.data_state = 0
  AND o.order_status IN (3, -2, 4, -3)           -- 有效订单状态
  AND o.platform_id NOT IN (24, 25, 26)            -- ★ 排除开放平台中小蚕部分
  AND o.platform_id NOT IN (                        -- 排除美团/饿了么/京东
      SELECT id FROM bwc_business_platform
      WHERE platform_abbreviation IN ('mtg', 'elez', 'eleg')
  )
  AND o.create_time BETWEEN '${startDate} 00:00:00' AND '${endDate} 23:59:59'

GROUP BY DATE(o.create_time)
ORDER BY dt;


-- ============================================================================
-- 附录A: 卡券红包分类明细数据集（可选，用于营销Tab的费用构成饼图）
-- 数据集名: ds_coupon_breakdown
-- 用途: 按券类型拆分费用构成
-- 参数: ${endDate}
-- ============================================================================

/*
-- 卡券分类
SELECT
    CASE
        WHEN coupon_name REGEXP '大牌'
             OR coupon_name IN ('库迪3选1', '瑞幸3选1', '沪上3选1')
             OR coupon_desc REGEXP '大牌活动'
             OR coupon_name = '社群奶茶福利券' THEN '大牌券'
        WHEN coupon_name REGEXP '复活券' THEN '复活券'
        WHEN coupon_name REGEXP '返利券' THEN '返利券'
        WHEN coupon_name REGEXP '免审券' THEN '免审券'
        WHEN coupon_name REGEXP '免单券' THEN '免单券'
        ELSE '其他'
    END                                 AS coupon_category,
    SUM(grant_num)                      AS grant_num,
    SUM(used_num)                       AS used_num,
    SUM(cost_amt)                       AS cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistics_date = '${endDate}'
  AND coupon_type = 1
  AND (coupon_name NOT REGEXP '测试' OR coupon_desc NOT REGEXP '测试')
GROUP BY coupon_category

UNION ALL

-- 红包分类
SELECT
    CASE
        WHEN business_name = '外卖' AND sub_coupon_type = 18
             AND coupon_name NOT IN ('新人狂欢首单奖励', '新人首单狂欢奖励', '新人狂欢第3单奖励')
             THEN '外卖MA红包'
        WHEN business_name = '砍价' AND sub_coupon_type = 18 THEN '砍价MA红包'
        WHEN business_name = '探店' AND sub_coupon_type = 18
             AND coupon_name NOT IN ('到店新人免单补贴红包', '到店新人完成3单奖励')
             THEN '探店MA红包'
        WHEN coupon_name IN ('新人狂欢首单奖励', '新人首单狂欢奖励') THEN '新用户下单奖励红包'
        WHEN coupon_name = '新人狂欢第3单奖励' THEN '新人狂欢第3单奖励'
        WHEN sub_coupon_type = 3 THEN '红包雨'
        WHEN sub_coupon_type = 9 THEN '抽奖活动'
        WHEN sub_coupon_type = 15 AND coupon_id <> 232 THEN '团长包红包'
        WHEN sub_coupon_type = 22
             OR coupon_name IN ('社群拉新红包', '社群福利红包', '探店优秀笔记奖励',
                                '社群会员红包', '社群活动红包') THEN '社群红包'
        WHEN sub_coupon_type = 6 THEN '会员限时升级礼包'
        WHEN sub_coupon_type = 4 THEN '积分兑换'
        WHEN sub_coupon_type = 28 THEN '免单卡红包'
        WHEN sub_coupon_type = 14 THEN '社群晒图'
        WHEN coupon_name = '美食侦探奖励红包' THEN '美食侦探奖励红包'
        WHEN sub_coupon_type = 7 THEN '会员每日红包活动'
        ELSE coupon_name
    END                                 AS coupon_category,
    SUM(grant_num)                      AS grant_num,
    SUM(used_num)                       AS used_num,
    SUM(cost_amt)                       AS cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistics_date = '${endDate}'
  AND coupon_type = 2
  AND coupon_id <> 339
  AND (coupon_name NOT REGEXP '测试' OR coupon_desc NOT REGEXP '测试')
GROUP BY coupon_category;
*/


-- ============================================================================
-- 附录B: 周视图聚合模板
-- 说明: 当日视图切换到周视图时，在上述趋势数据集外层套一层周聚合即可
--
-- 周聚合模式（以DAU为例）:
--   SELECT
--       DATE_TRUNC('week', dt) AS week_start,
--       AVG(dau) AS weekly_avg_dau,
--       AVG(dau) / NULLIF(LAG(AVG(dau)) OVER (ORDER BY DATE_TRUNC('week', dt)), 0) - 1 AS week_dod
--   FROM (原日趋势数据集)
--   GROUP BY DATE_TRUNC('week', dt)
--   ORDER BY week_start;
--
-- 建议在FineBI中通过 ${mode} 参数控制聚合层级:
--   - ${mode} = 'day':  直接返回日数据
--   - ${mode} = 'week': 外面套一层周聚合
-- ============================================================================
