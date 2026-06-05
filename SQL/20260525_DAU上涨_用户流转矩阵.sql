-- ============================================================
-- DAU上涨归因：W20 → W21 用户流转矩阵
-- 逻辑：同一批用户，看在W20是什么类型 → W21变成了什么类型
-- 分类标准：按每周「首次访问日」前30天的访问天数判定
-- ============================================================

WITH
-- Step 1: 展开bitmap，覆盖 W20前30天 ~ W21结束
user_visit AS (
    SELECT dt, unnest_bitmap AS user_id
    FROM dwd.dwd_sr_traffic_viewuser_d,
         unnest_bitmap(user_ids) AS uid
    WHERE dt BETWEEN '2026-04-11' AND '2026-05-24'
    GROUP BY dt, user_id
),

-- Step 2: 每个用户在 W20 和 W21 的首次访问日
user_week_first AS (
    SELECT
        user_id,
        MIN(CASE WHEN dt BETWEEN '2026-05-11' AND '2026-05-17' THEN dt END) AS w20_first_dt,
        MIN(CASE WHEN dt BETWEEN '2026-05-18' AND '2026-05-24' THEN dt END) AS w21_first_dt
    FROM user_visit
    WHERE dt BETWEEN '2026-05-11' AND '2026-05-24'
    GROUP BY user_id
),

-- Step 3: W20 首访日之前30天的访问天数
user_w20_prev AS (
    SELECT
        f.user_id,
        COUNT(DISTINCT v.dt) AS prev_30d_visits
    FROM user_week_first f
    JOIN user_visit v
        ON f.user_id = v.user_id
        AND v.dt < f.w20_first_dt
        AND v.dt >= DATE_SUB(f.w20_first_dt, INTERVAL 30 DAY)
    WHERE f.w20_first_dt IS NOT NULL
    GROUP BY f.user_id
),

-- Step 4: W21 首访日之前30天的访问天数
user_w21_prev AS (
    SELECT
        f.user_id,
        COUNT(DISTINCT v.dt) AS prev_30d_visits
    FROM user_week_first f
    JOIN user_visit v
        ON f.user_id = v.user_id
        AND v.dt < f.w21_first_dt
        AND v.dt >= DATE_SUB(f.w21_first_dt, INTERVAL 30 DAY)
    WHERE f.w21_first_dt IS NOT NULL
    GROUP BY f.user_id
),

-- Step 5: 注册信息（判断是否注册当天）
user_register AS (
    SELECT user_id, DATE(register_time) AS register_date
    FROM dim.dim_silkworm_user
),

-- Step 6: 分类 W20 类型（按每周首次访问日的状态）
w20_type AS (
    SELECT
        f.user_id,
        CASE
            WHEN r.register_date = f.w20_first_dt THEN '注册用户量'
            WHEN COALESCE(p.prev_30d_visits, 0) = 0 THEN '沉默用户召回量'
            WHEN p.prev_30d_visits BETWEEN 1 AND 6 THEN '近30天访问1-6天'
            WHEN p.prev_30d_visits BETWEEN 7 AND 12 THEN '近30天访问7-12天'
            WHEN p.prev_30d_visits BETWEEN 13 AND 18 THEN '近30天访问13-18天'
            WHEN p.prev_30d_visits BETWEEN 19 AND 24 THEN '近30天访问19-24天'
            WHEN p.prev_30d_visits >= 25 THEN '近30天访问25-30天'
        END AS user_type
    FROM user_week_first f
    LEFT JOIN user_w20_prev p ON f.user_id = p.user_id
    LEFT JOIN user_register r ON f.user_id = r.user_id
    WHERE f.w20_first_dt IS NOT NULL
),

-- Step 7: 分类 W21 类型
w21_type AS (
    SELECT
        f.user_id,
        CASE
            WHEN r.register_date = f.w21_first_dt THEN '注册用户量'
            WHEN COALESCE(p.prev_30d_visits, 0) = 0 THEN '沉默用户召回量'
            WHEN p.prev_30d_visits BETWEEN 1 AND 6 THEN '近30天访问1-6天'
            WHEN p.prev_30d_visits BETWEEN 7 AND 12 THEN '近30天访问7-12天'
            WHEN p.prev_30d_visits BETWEEN 13 AND 18 THEN '近30天访问13-18天'
            WHEN p.prev_30d_visits BETWEEN 19 AND 24 THEN '近30天访问19-24天'
            WHEN p.prev_30d_visits >= 25 THEN '近30天访问25-30天'
        END AS user_type
    FROM user_week_first f
    LEFT JOIN user_w21_prev p ON f.user_id = p.user_id
    LEFT JOIN user_register r ON f.user_id = r.user_id
    WHERE f.w21_first_dt IS NOT NULL
)

-- ============================================================
-- 输出：流转矩阵
-- ============================================================
SELECT
    COALESCE(w20.user_type, '【新增】W20未访问') AS W20_类型,
    COALESCE(w21.user_type, '【流失】W21未访问') AS W21_类型,
    COUNT(DISTINCT COALESCE(w20.user_id, w21.user_id)) AS 用户数
FROM w20_type w20
FULL OUTER JOIN w21_type w21 ON w20.user_id = w21.user_id
GROUP BY 1, 2
ORDER BY
    CASE W20_类型
        WHEN '注册用户量' THEN 1
        WHEN '沉默用户召回量' THEN 2
        WHEN '近30天访问1-6天' THEN 3
        WHEN '近30天访问7-12天' THEN 4
        WHEN '近30天访问13-18天' THEN 5
        WHEN '近30天访问19-24天' THEN 6
        WHEN '近30天访问25-30天' THEN 7
        WHEN '【新增】W20未访问' THEN 8
    END,
    CASE W21_类型
        WHEN '注册用户量' THEN 1
        WHEN '沉默用户召回量' THEN 2
        WHEN '近30天访问1-6天' THEN 3
        WHEN '近30天访问7-12天' THEN 4
        WHEN '近30天访问13-18天' THEN 5
        WHEN '近30天访问19-24天' THEN 6
        WHEN '近30天访问25-30天' THEN 7
        WHEN '【流失】W21未访问' THEN 8
    END;


-- ============================================================
-- 补充查询1：【关键验证】W20未访问→1-6天 的用户，30天窗口内访问天数分布
-- 目的：区分「近沉默用户」(1-2天) vs 「真间歇用户」(3-6天)
-- ============================================================
SELECT
    COALESCE(p.prev_30d_visits, 0) AS 近30天访问天数,
    COUNT(DISTINCT w21.user_id) AS 用户数,
    CASE
        WHEN COALESCE(p.prev_30d_visits, 0) <= 2 THEN '近沉默用户（≤2天，分类边界脆弱）'
        ELSE '真间歇用户（3-6天）'
    END AS 分类
FROM w21_type w21
LEFT JOIN user_w21_prev p ON w21.user_id = p.user_id
WHERE w21.user_type = '近30天访问1-6天'
  AND w21.user_id NOT IN (SELECT user_id FROM w20_type)
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 补充查询2：沉默召回→1-6天 用户的访问天数分布（对照组）
-- ============================================================
-- SELECT
--     COALESCE(p.prev_30d_visits, 0) AS 近30天访问天数,
--     COUNT(DISTINCT w21.user_id) AS 用户数
-- FROM w21_type w21
-- JOIN w20_type w20 ON w21.user_id = w20.user_id
-- LEFT JOIN user_w21_prev p ON w21.user_id = p.user_id
-- WHERE w20.user_type = '沉默用户召回量'
--   AND w21.user_type = '近30天访问1-6天'
-- GROUP BY 1
-- ORDER BY 1;
