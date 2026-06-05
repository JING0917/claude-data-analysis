-- ============================================================================
-- 晓晓数据指标 — 帆软BI 数据集SQL (每日统计优化版)
-- 适用范围：MySQL / 帆软BI (FineBI) 数据集
-- 优化说明：所有数据集新增"统计日期"字段，支持每日粒度统计
--
-- 参数说明：
--   @start_time / @end_time 为时间参数占位符
--   在帆软BI中使用时，请替换为 ${start_time} ${end_time}
--
-- 【重要】时间参数格式要求：
--   由于WHERE条件中使用了 datetime 索引列（bwc_order.create_time、bwc_user.create_time、
--   bwc_red_envelopes.create_time、bwc_task.task_start_time 等），为避免DATE()函数包裹导致
--   索引失效，统一使用 "col >= @start_time AND col < DATE_ADD(@end_time, INTERVAL 1 DAY)"
--   的范围比较方式。
--
--   在帆软BI中设置参数时，请将 start_time / end_time 设置为【日期时间】格式（datetime），而非
--   仅日期格式（date）。参数值示例：
--     start_time = 2026-04-01 00:00:00
--     end_time   = 2026-04-24 23:59:59   （或业务端设定的截止日期时间）
--
--   如果使用 date 格式，end_time = '2026-04-24' 会被MySQL隐式转为 '2026-04-24 00:00:00'，
--   导致24日00:00:00之后的数据被排除，造成数据遗漏。
--
--   visit_day 字段是 date 类型（非datetime），不受此限制，使用 BETWEEN 和 DATE() 均可。
-- ============================================================================

-- ============================================================================
-- 数据集1：订单核心指标（每日统计）
-- ----------------------------------------------------------------------------
-- 包含: 总活动名额数、晓晓报名/有效订单、核销率、美团官方报名/有效订单
-- ============================================================================
WITH
all_dates AS (
    SELECT DISTINCT DATE(o.create_time) AS statistics_date
    FROM bwc_order o
    WHERE o.data_state = 0
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    UNION
    SELECT DISTINCT DATE(t.task_start_time)
    FROM bwc_task t
    WHERE t.data_state = 0
      AND t.task_start_time >= @start_time AND t.task_start_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
      AND t.task_type NOT IN (1, 2)
),
total_quota AS (
    SELECT DATE(t.task_start_time) AS statistics_date,
           COALESCE(SUM(t.task_total_quota), 0) AS quota_value
    FROM bwc_task t
    WHERE t.data_state = 0
      AND t.task_start_time >= @start_time AND t.task_start_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
      AND t.task_type NOT IN (1, 2)
    GROUP BY DATE(t.task_start_time)
),
xx_registered AS (
    SELECT DATE(o.create_time) AS statistics_date,
           COUNT(o.id) AS order_cnt
    FROM bwc_order o
    INNER JOIN bwc_business_platform p ON o.platform_id = p.id AND p.data_state = 0
    WHERE o.data_state = 0
      AND p.platform_abbreviation NOT IN ('mtg', 'elez', 'eleg')
      AND o.order_status = 1
      AND o.user_id > 0
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(o.create_time)
),
xx_valid AS (
    SELECT DATE(o.create_time) AS statistics_date,
           COUNT(o.id) AS order_cnt
    FROM bwc_order o
    INNER JOIN bwc_business_platform p ON o.platform_id = p.id AND p.data_state = 0
    WHERE o.data_state = 0
      AND p.platform_abbreviation NOT IN ('mtg', 'elez', 'eleg')
      AND o.order_status = 4
      AND o.user_id > 0
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(o.create_time)
),
mtg_registered AS (
    SELECT DATE(o.create_time) AS statistics_date,
           COUNT(o.id) AS order_cnt
    FROM bwc_order o
    INNER JOIN bwc_business_platform p ON o.platform_id = p.id AND p.data_state = 0
    WHERE o.data_state = 0
      AND p.platform_abbreviation = 'mtg'
      AND o.order_status = 1
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(o.create_time)
),
mtg_valid AS (
    SELECT DATE(o.create_time) AS statistics_date,
           COUNT(o.id) AS order_cnt
    FROM bwc_order o
    INNER JOIN bwc_business_platform p ON o.platform_id = p.id AND p.data_state = 0
    WHERE o.data_state = 0
      AND p.platform_abbreviation = 'mtg'
      AND o.order_status = 4
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(o.create_time)
)
SELECT
    d.statistics_date                                                   AS '统计日期',
    COALESCE(tq.quota_value, 0)                                         AS '总活动名额数',
    COALESCE(xxr.order_cnt, 0)                                          AS '晓晓平台报名订单数',
    COALESCE(xxv.order_cnt, 0)                                          AS '晓晓平台有效订单量',
    CASE
        WHEN COALESCE(tq.quota_value, 0) = 0 THEN NULL
        ELSE ROUND(COALESCE(xxv.order_cnt, 0) * 100.0 / tq.quota_value, 2)
    END                                                                 AS '晓晓平台活动核销率(%)',
    COALESCE(mtgr.order_cnt, 0)                                         AS '美团官方活动报名订单量',
    COALESCE(mtgv.order_cnt, 0)                                         AS '美团官方活动有效订单量'
FROM all_dates d
LEFT JOIN total_quota tq ON d.statistics_date = tq.statistics_date
LEFT JOIN xx_registered xxr ON d.statistics_date = xxr.statistics_date
LEFT JOIN xx_valid xxv ON d.statistics_date = xxv.statistics_date
LEFT JOIN mtg_registered mtgr ON d.statistics_date = mtgr.statistics_date
LEFT JOIN mtg_valid mtgv ON d.statistics_date = mtgv.statistics_date
ORDER BY d.statistics_date;


-- ============================================================================
-- 数据集2：订单取消分析（每日统计）
-- ----------------------------------------------------------------------------
-- 包含: 手动取消、超时取消、后台取消，按日期+平台区分
-- ============================================================================
SELECT
    DATE(o.create_time)                                                 AS '统计日期',
    p.platform_abbreviation                                              AS '平台编码',
    p.platform_name                                                      AS '平台名称',
    COUNT(o.id)                                                          AS '取消总订单量',
    SUM(CASE WHEN o.cancel_status = 1 THEN 1 ELSE 0 END)                 AS '手动取消订单量(用户主动)',
    SUM(CASE WHEN o.cancel_status IN (2, 3) THEN 1 ELSE 0 END)           AS '超时取消订单量(超时/过期)',
    SUM(CASE WHEN o.cancel_status IN (4, 5, 6) THEN 1 ELSE 0 END)        AS '后台取消订单量(管理员取消/退款/任务失败)'
FROM bwc_order o
INNER JOIN bwc_business_platform p ON o.platform_id = p.id AND p.data_state = 0
WHERE o.data_state = 0
  AND o.order_status = -1
  AND o.cancel_status IN (1, 2, 3, 4, 5, 6)
  AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
GROUP BY DATE(o.create_time), p.platform_abbreviation, p.platform_name
ORDER BY 统计日期, 取消总订单量 DESC;


-- ============================================================================
-- 数据集3：晓晓平台订单利润（每日统计）
-- ----------------------------------------------------------------------------
-- 包含: 已支付账单利润、所有账单利润（按日拆分）
-- 服务费 = task_receipt_price(接单价格) - cash_back_amount(返现价格)
-- ============================================================================
WITH
excluded_platform_ids AS (
    SELECT id FROM bwc_business_platform WHERE platform_abbreviation IN ('mtg', 'elez', 'eleg')
),
paid_profit AS (
    SELECT DATE(o.create_time) AS statistics_date,
           COALESCE(SUM(t.task_receipt_price - t.cash_back_amount), 0) AS profit,
           COUNT(DISTINCT o.id) AS order_cnt,
           COUNT(DISTINCT b.id) AS bill_cnt
    FROM bwc_seller_bill b
    INNER JOIN bwc_seller_bill_task bt ON b.id = bt.seller_bill_id AND bt.data_state = 0
    INNER JOIN bwc_order o ON bt.task_id = o.task_id AND o.data_state = 0
    INNER JOIN bwc_task t ON o.task_id = t.id AND t.data_state = 0
    WHERE b.data_state = 0
      AND b.pay_status = 2
      AND o.order_status IN (3, -2, 4, -3)
      AND o.user_id > 0
      AND o.platform_id NOT IN (SELECT id FROM excluded_platform_ids)
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(o.create_time)
),
all_profit AS (
    SELECT DATE(o.create_time) AS statistics_date,
           COALESCE(SUM(t.task_receipt_price - t.cash_back_amount), 0) AS profit,
           COUNT(DISTINCT o.id) AS order_cnt,
           COUNT(DISTINCT o.user_id) AS user_cnt
    FROM bwc_order o
    INNER JOIN bwc_task t ON o.task_id = t.id AND t.data_state = 0
    WHERE o.data_state = 0
      AND o.order_status IN (3, -2, 4, -3)
      AND o.user_id > 0
      AND o.platform_id NOT IN (SELECT id FROM excluded_platform_ids)
      AND o.create_time >= @start_time AND o.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(o.create_time)
)
SELECT
    d.statistics_date                                                    AS '统计日期',
    COALESCE(pp.profit, 0)                                               AS '晓晓订单利润_已支付账单(元)',
    COALESCE(pp.order_cnt, 0)                                            AS '已支付账单_参与订单数',
    COALESCE(pp.bill_cnt, 0)                                             AS '账单数',
    COALESCE(ap.profit, 0)                                               AS '晓晓订单利润_所有账单(元)',
    COALESCE(ap.order_cnt, 0)                                            AS '所有账单_参与订单数',
    COALESCE(ap.user_cnt, 0)                                             AS '所有账单_参与用户数'
FROM (SELECT statistics_date FROM paid_profit UNION SELECT statistics_date FROM all_profit) d
LEFT JOIN paid_profit pp ON d.statistics_date = pp.statistics_date
LEFT JOIN all_profit ap ON d.statistics_date = ap.statistics_date
ORDER BY d.statistics_date;


-- ============================================================================
-- 数据集4：用户核心指标（每日统计）
-- ----------------------------------------------------------------------------
-- 包含: 每日新注册用户数、累计注册用户数、有效用户数
-- ============================================================================
WITH
daily_new_users AS (
    SELECT DATE(create_time) AS statistics_date,
           COUNT(*) AS daily_new_user_cnt
    FROM bwc_user
    WHERE data_state = 0
      AND create_time >= @start_time AND create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(create_time)
),
daily_valid_users AS (
    SELECT DATE(create_time) AS statistics_date,
           COUNT(*) AS daily_valid_user_cnt
    FROM bwc_user
    WHERE data_state = 0
      AND order_num > 0
      AND create_time >= @start_time AND create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(create_time)
),
pre_period_stats AS (
    SELECT COUNT(*) AS pre_total_users,
           SUM(CASE WHEN order_num > 0 THEN 1 ELSE 0 END) AS pre_valid_users
    FROM bwc_user
    WHERE data_state = 0
      AND create_time < @start_time
),
running_total AS (
    SELECT statistics_date,
           daily_new_user_cnt,
           SUM(daily_new_user_cnt) OVER (ORDER BY statistics_date) AS cum_new_users
    FROM daily_new_users
)
SELECT
    rt.statistics_date                                                   AS '统计日期',
    rt.daily_new_user_cnt                                                AS '新注册用户量',
    (rt.cum_new_users + pp.pre_total_users)                              AS '累计注册用户数(截至当日)',
    COALESCE(dvu.daily_valid_user_cnt, 0)                                AS '有效用户数(当日注册且有完单记录)',
    ROUND(
        CASE WHEN dnu_cnt.total_days > 0
             THEN rt.daily_new_user_cnt * 1.0 / dnu_cnt.total_days
             ELSE 0 END, 0
    )                                                                    AS '日均新注册用户数'
FROM running_total rt
CROSS JOIN pre_period_stats pp
LEFT JOIN daily_valid_users dvu ON rt.statistics_date = dvu.statistics_date
CROSS JOIN (SELECT DATEDIFF(@end_time, @start_time) + 1 AS total_days) dnu_cnt
ORDER BY rt.statistics_date;


-- ============================================================================
-- 数据集5：新用户完单率（群组分析）
-- ----------------------------------------------------------------------------
-- 以注册日期为群组(cohort)，统计当日/次日/3日/7日内完单率
-- 完单定义：bwc_order.order_status = 4（已完成）
-- ============================================================================
WITH
reg_cohort AS (
    SELECT
        DATE(u.create_time) AS reg_date,
        COUNT(DISTINCT u.id) AS total_users
    FROM bwc_user u
    WHERE u.data_state = 0
      AND u.create_time >= @start_time AND u.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
    GROUP BY DATE(u.create_time)
),
user_completion AS (
    SELECT DISTINCT
        u.id AS user_id,
        DATE(u.create_time) AS reg_date,
        DATE(o.update_time) AS complete_date
    FROM bwc_user u
    INNER JOIN bwc_order o ON u.id = o.user_id AND o.data_state = 0
    WHERE u.data_state = 0
      AND o.order_status = 4
      AND o.user_id > 0
      AND u.create_time >= @start_time AND u.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
)
SELECT
    rc.reg_date                                                          AS '注册日期',
    rc.total_users                                                       AS '注册用户数',
    ROUND(
        COUNT(DISTINCT CASE WHEN uc.complete_date = rc.reg_date THEN uc.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '当日完单率(%)',
    ROUND(
        COUNT(DISTINCT CASE WHEN uc.complete_date <= DATE_ADD(rc.reg_date, INTERVAL 1 DAY)
                                 AND uc.complete_date >= rc.reg_date
                            THEN uc.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '次日完单率(%)',
    ROUND(
        COUNT(DISTINCT CASE WHEN uc.complete_date <= DATE_ADD(rc.reg_date, INTERVAL 3 DAY)
                                 AND uc.complete_date >= rc.reg_date
                            THEN uc.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '3日完单率(%)',
    ROUND(
        COUNT(DISTINCT CASE WHEN uc.complete_date <= DATE_ADD(rc.reg_date, INTERVAL 7 DAY)
                                 AND uc.complete_date >= rc.reg_date
                            THEN uc.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '7日完单率(%)'
FROM reg_cohort rc
LEFT JOIN user_completion uc ON rc.reg_date = uc.reg_date
GROUP BY rc.reg_date, rc.total_users
ORDER BY rc.reg_date;


-- ============================================================================
-- 数据集6：新用户访问留存率（群组分析）
-- ----------------------------------------------------------------------------
-- 以注册日期为群组，统计第1/2/3/7日访问留存率
-- 使用 visit_day 索引列优化大表查询性能
-- ============================================================================
WITH
reg_users AS (
    SELECT u.id AS user_id, DATE(u.create_time) AS reg_date
    FROM bwc_user u
    WHERE u.data_state = 0
      AND u.create_time >= @start_time AND u.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
),
reg_cohort AS (
    SELECT reg_date, COUNT(DISTINCT user_id) AS total_users
    FROM reg_users
    GROUP BY reg_date
),
user_visits AS (
    SELECT DISTINCT
        ru.reg_date,
        ru.user_id,
        v.visit_day
    FROM reg_users ru
    INNER JOIN bwc_client_user_visit_record v ON ru.user_id = v.user_id AND v.data_state = 0
    WHERE v.visit_day BETWEEN DATE_ADD(ru.reg_date, INTERVAL 1 DAY)
                          AND DATE_ADD(ru.reg_date, INTERVAL 7 DAY)
)
SELECT
    rc.reg_date                                                          AS '注册日期',
    rc.total_users                                                       AS '注册用户数',
    ROUND(
        COUNT(DISTINCT CASE WHEN uv.visit_day = DATE_ADD(rc.reg_date, INTERVAL 1 DAY)
                            THEN uv.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '次日访问留存率(%)',
    ROUND(
        COUNT(DISTINCT CASE WHEN uv.visit_day = DATE_ADD(rc.reg_date, INTERVAL 2 DAY)
                            THEN uv.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '次2日访问留存率(%)',
    ROUND(
        COUNT(DISTINCT CASE WHEN uv.visit_day = DATE_ADD(rc.reg_date, INTERVAL 3 DAY)
                            THEN uv.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '次3日访问留存率(%)',
    ROUND(
        COUNT(DISTINCT CASE WHEN uv.visit_day = DATE_ADD(rc.reg_date, INTERVAL 7 DAY)
                            THEN uv.user_id END) * 100.0
        / NULLIF(rc.total_users, 0), 2
    )                                                                    AS '次7日访问留存率(%)'
FROM reg_cohort rc
LEFT JOIN user_visits uv ON rc.reg_date = uv.reg_date
GROUP BY rc.reg_date, rc.total_users
ORDER BY rc.reg_date;


-- ============================================================================
-- 数据集7：活跃用户留存与DAU趋势
-- ----------------------------------------------------------------------------
-- 包含: DAU、PV、3日/7日活跃留存率（合并原数据集7和8）
-- 使用 visit_day 索引列优化
-- ============================================================================
WITH
base_visits AS (
    SELECT visit_day, user_id
    FROM bwc_client_user_visit_record
    WHERE data_state = 0
      AND visit_day BETWEEN DATE(@start_time) AND DATE_ADD(DATE(@end_time), INTERVAL 7 DAY)
),
dau_stats AS (
    SELECT
        visit_day AS active_date,
        COUNT(DISTINCT user_id) AS dau,
        COUNT(*) AS pv
    FROM base_visits
    WHERE visit_day BETWEEN DATE(@start_time) AND DATE(@end_time)
    GROUP BY visit_day
),
active_users AS (
    SELECT DISTINCT visit_day AS active_date, user_id
    FROM base_visits
),
return_check AS (
    SELECT
        a.active_date,
        COUNT(DISTINCT CASE WHEN r.user_id IS NOT NULL
                                 AND r.active_date <= DATE_ADD(a.active_date, INTERVAL 3 DAY)
                            THEN a.user_id END) AS retention_3d_users,
        COUNT(DISTINCT CASE WHEN r.user_id IS NOT NULL
                                 AND r.active_date <= DATE_ADD(a.active_date, INTERVAL 7 DAY)
                            THEN a.user_id END) AS retention_7d_users
    FROM active_users a
    LEFT JOIN active_users r ON a.user_id = r.user_id
                            AND r.active_date > a.active_date
                            AND r.active_date <= DATE_ADD(a.active_date, INTERVAL 7 DAY)
    WHERE a.active_date BETWEEN DATE(@start_time) AND DATE(@end_time)
    GROUP BY a.active_date
)
SELECT
    d.active_date                                                        AS '日期',
    d.dau                                                                AS 'DAU(活跃用户数)',
    d.pv                                                                 AS '总访问次数(PV)',
    ROUND(r.retention_3d_users * 100.0 / NULLIF(d.dau, 0), 2)           AS '3日活跃留存率(%)',
    ROUND(r.retention_7d_users * 100.0 / NULLIF(d.dau, 0), 2)           AS '7日活跃留存率(%)'
FROM dau_stats d
LEFT JOIN return_check r ON d.active_date = r.active_date
ORDER BY d.active_date;


-- ============================================================================
-- 数据集8：红包综合分析（每日统计）
-- ----------------------------------------------------------------------------
-- 包含: 按日期+来源(send_scene)统计发放、使用、核销率、过期率
-- ============================================================================
SELECT
    DATE(r.create_time)                                                  AS '统计日期',
    r.send_scene                                                         AS '红包来源场景值',
    CASE r.send_scene
        WHEN 1 THEN '扣款补偿'        WHEN 2 THEN '激励核销'
        WHEN 3 THEN '活动赠与'        WHEN 4 THEN '人工发放'
        WHEN 5 THEN '新用户APP首单奖励' WHEN 6 THEN '会员等级礼包'
        WHEN 7 THEN '会员生日权益礼包'   WHEN 8 THEN '能量商城兑换'
        WHEN 9 THEN '首次关注公众号赠送'  WHEN 10 THEN '自动任务赠送'
        WHEN 11 THEN '会员红包天天领活动' WHEN 12 THEN '会员红包天天领活动拉新奖励'
        WHEN 13 THEN '订单取消'        WHEN 14 THEN '助力领现金活动'
        WHEN 15 THEN '餐餐有返小程序抽奖获得' WHEN 16 THEN '首页浏览得红包'
        WHEN 17 THEN '订单助力加返'     WHEN 18 THEN '首单全额返'
        WHEN 19 THEN '暗号绑定赠礼'     WHEN 20 THEN '新人完成3单奖励'
        WHEN 21 THEN 'App见面礼'       WHEN 22 THEN 'App回归礼'
        WHEN 23 THEN '会员红包天天领打开通知奖励'
        ELSE '其他'
    END                                                                  AS '红包来源名称',
    COUNT(*)                                                             AS '发放数量',
    SUM(CASE WHEN r.red_status = 2 THEN 1 ELSE 0 END)                    AS '使用数量',
    ROUND(
        SUM(CASE WHEN r.red_status = 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    )                                                                    AS '核销率(%)',
    SUM(CASE WHEN r.red_status = 2 THEN r.red_amount ELSE 0 END)         AS '使用金额(元)',
    SUM(CASE WHEN r.time_limit = 1 AND r.red_end_time < NOW() AND r.red_status = 1
             THEN 1 ELSE 0 END)                                          AS '过期数量',
    ROUND(
        SUM(CASE WHEN r.time_limit = 1 AND r.red_end_time < NOW() AND r.red_status = 1
                 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    )                                                                    AS '过期率(%)',
    COALESCE(SUM(CASE WHEN r.time_limit = 1 AND r.red_end_time < NOW() AND r.red_status = 1
                      THEN r.red_amount ELSE 0 END), 0)                  AS '过期金额(元)',
    COUNT(DISTINCT r.user_id)                                            AS '持有红包用户数(去重)',
    COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT r.user_id), 0)                AS '人均持有红包数(张)',
    COUNT(DISTINCT CASE WHEN r.red_status = 1
                             AND (r.time_limit = 0 OR r.red_end_time > NOW())
                        THEN r.user_id END)                              AS '持有红包用户数(未使用)'
FROM bwc_red_envelopes r
WHERE r.data_state = 0
  AND r.create_time >= @start_time AND r.create_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
  AND r.red_status != 4
  AND r.user_id > 0
GROUP BY DATE(r.create_time), r.send_scene
ORDER BY 统计日期, r.send_scene;


-- ============================================================================
-- 数据集9：晓晓红包ROI（每日统计）
-- ----------------------------------------------------------------------------
-- ROI = 使用红包的订单服务费总额 / 已使用的红包面值金额
-- 关联路径：bwc_order → bwc_order_info → bwc_red_envelopes → bwc_task
-- ============================================================================
SELECT
    DATE(o.update_time)                                                  AS '统计日期',
    r.send_scene                                                         AS '红包来源场景值',
    COALESCE(SUM(t.task_receipt_price - t.cash_back_amount), 0)          AS '服务费总额(元)',
    COALESCE(SUM(oi.red_envelope_amount), 0)                             AS '红包使用金额(元)',
    CASE
        WHEN COALESCE(SUM(oi.red_envelope_amount), 0) = 0 THEN NULL
        ELSE ROUND(SUM(t.task_receipt_price - t.cash_back_amount) / SUM(oi.red_envelope_amount), 4)
    END                                                                  AS '红包ROI(服务费/红包金额)',
    COUNT(DISTINCT o.id)                                                 AS '使用红包的订单数'
FROM bwc_order o
INNER JOIN bwc_order_info oi ON o.id = oi.id AND oi.data_state = 0 AND oi.red_envelope_id > 0
INNER JOIN bwc_red_envelopes r ON oi.red_envelope_id = r.id AND r.data_state = 0
INNER JOIN bwc_task t ON o.task_id = t.id AND t.data_state = 0
WHERE o.data_state = 0
  AND o.order_status = 4
  AND o.user_id > 0
  AND o.update_time >= @start_time AND o.update_time < DATE_ADD(@end_time, INTERVAL 1 DAY)
GROUP BY DATE(o.update_time), r.send_scene
ORDER BY 统计日期, r.send_scene;
