-- ============================================================
-- DAU上涨归因：W21 1-6天段增量中，有多少是「近日被召回」用户的二次访问？
-- 逻辑：用户被召回当天属于「沉默用户召回量」，次日后再访问就滚入「1-6天」
-- ============================================================

WITH
-- Step 1: W21 (5/18-5/24) 每日的召回用户（沉默用户召回量）
-- 来源：dwd_sr_user_retention_d，user_type = '近30天无访问'
w21_recall_daily AS (
    SELECT
        dt,
        MAX(IF(user_type = '近30天无访问', DAU, 0)) AS recall_num
    FROM dwd.dwd_sr_user_retention_d
    WHERE dt BETWEEN '2026-05-18' AND '2026-05-24'
      AND user_type IN ('近30天无访问', '近30天访问1-6天')
    GROUP BY dt
),

-- Step 2: W20 对比基线
w20_baseline AS (
    SELECT
        AVG(IF(user_type = '近30天访问1-6天', DAU, 0)) AS avg_1_6,
        AVG(IF(user_type = '近30天无访问', DAU, 0)) AS avg_recall
    FROM dwd.dwd_sr_user_retention_d
    WHERE dt BETWEEN '2026-05-11' AND '2026-05-17'
      AND user_type IN ('近30天无访问', '近30天访问1-6天')
),

w21_baseline AS (
    SELECT
        AVG(IF(user_type = '近30天访问1-6天', DAU, 0)) AS avg_1_6,
        AVG(IF(user_type = '近30天无访问', DAU, 0)) AS avg_recall
    FROM dwd.dwd_sr_user_retention_d
    WHERE dt BETWEEN '2026-05-18' AND '2026-05-24'
      AND user_type IN ('近30天无访问', '近30天访问1-6天')
),

-- Step 3: 展开 W20+W21 的 bitmap，拿到用户粒度的每日访问
-- 覆盖 4/18~5/24（W21 往前推 30 天，用于判断是否沉默召回）
user_visit_raw AS (
    SELECT
        dt,
        unnest_bitmap(user_ids) AS user_id
    FROM dwd.dwd_sr_traffic_viewuser_d
    WHERE dt BETWEEN '2026-04-18' AND '2026-05-24'
),

-- 每日每用户去重
user_visit AS (
    SELECT dt, user_id
    FROM user_visit_raw
    GROUP BY dt, user_id
),

-- Step 4: 每个用户在窗口内的首次访问日
user_first_visit AS (
    SELECT
        user_id,
        MIN(dt) AS first_dt
    FROM user_visit
    GROUP BY user_id
),

-- Step 5: 标记「沉默召回用户」：首次访问日之前 30 天无任何访问
-- （如果 first_dt 之前 30 天窗口内没有该用户记录 → 即沉默后回访）
user_prev_visit AS (
    SELECT
        f.user_id,
        f.first_dt,
        MAX(v.dt) AS last_visit_before_window
    FROM user_first_visit f
    LEFT JOIN user_visit v
        ON f.user_id = v.user_id
        AND v.dt < f.first_dt
        AND v.dt >= DATE_SUB(f.first_dt, INTERVAL 30 DAY)
    GROUP BY f.user_id, f.first_dt
),

recall_flag AS (
    SELECT
        user_id,
        first_dt,
        CASE WHEN last_visit_before_window IS NULL THEN 1 ELSE 0 END AS is_recall
    FROM user_prev_visit
),

-- Step 6: 召回用户后续访问天次（W21 内）
recall_user_w21_visits AS (
    SELECT
        r.user_id,
        r.first_dt AS recall_date,
        COUNT(DISTINCT v.dt) AS w21_visit_days
    FROM recall_flag r
    JOIN user_visit v
        ON r.user_id = v.user_id
        AND v.dt BETWEEN '2026-05-18' AND '2026-05-24'
    WHERE r.is_recall = 1
      AND r.first_dt >= '2026-05-11'  -- 召回发生在 W20 或 W21
    GROUP BY r.user_id, r.first_dt
)

-- ============================================================
-- 最终输出
-- ============================================================
SELECT
    'W20-W21 召回用户，在 W21 的访问天次分布' AS 分析项,
    CASE
        WHEN w21_visit_days = recall_diff THEN '仅召回当天访问(W21内无二次访问)'
        WHEN w21_visit_days <= 2 THEN '1-2天'
        WHEN w21_visit_days <= 4 THEN '3-4天'
        WHEN w21_visit_days <= 6 THEN '5-6天'
        ELSE '7天'
    END AS W21访问天次,
    COUNT(DISTINCT user_id) AS 用户数,
    -- 召回日期范围
    MIN(recall_date) AS 最早召回日,
    MAX(recall_date) AS 最晚召回日

FROM recall_user_w21_visits r
LEFT JOIN (
    SELECT user_id, DATEDIFF('2026-05-24', first_dt) + 1 AS recall_diff
    FROM recall_flag
    WHERE is_recall = 1
) g ON r.user_id = g.user_id

GROUP BY 1, 2
ORDER BY 2;


-- ============================================================
-- 汇总：召回用户在 W21 1-6天 段的贡献
-- ============================================================
-- 说明：
-- 上面查出的是「召回用户」在 W21 的访问天次分布。
-- 这些用户在召回当天属于「沉默用户召回量」，
-- 但召回后的第 2~N 次访问就归入「近30天访问1-6天」。
--
-- W20 1-6天日均: ~18.4万 → W21: ~21.1万 (+2.7万)
-- W20 召回日均:  ~2.4万 → W21:  ~3.2万 (+0.8万)
--
-- 如果上面查出的召回用户中，有大量在 W21 访问了 2 天以上，
-- 则说明 1-6天 增量是「召回动作的滞后效应」——用户被召回后次日再访，滚入了 1-6天 段。
