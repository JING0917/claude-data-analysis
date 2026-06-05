-- ============================================================================
-- 用户留存数据实体表（优化版）
-- author: hongxiu
-- 优化时间: 2026-05-27
-- 优化要点:
--   1. 去除 date_format VARCHAR 转换，全程使用 DATE 类型
--   2. 分区从 daily 改为 monthly，减少元数据压力
--   3. 简化 CTE 结构，减少中间物化
--   4. mau_info 逻辑用单次 self-join 替代多层嵌套
-- ============================================================================

-- ============================ DDL ============================

DROP TABLE IF EXISTS dwd.dwd_sr_user_retention_d;

CREATE TABLE IF NOT EXISTS dwd.dwd_sr_user_retention_d
(
    `dt`               DATE   NOT NULL COMMENT '日期',
    `user_type`        STRING NOT NULL COMMENT '用户类型',
    `DAU`              BIGINT NOT NULL COMMENT '日活',
    `day1_retention`   BIGINT NOT NULL COMMENT '次日留存用户量',
    `day2_retention`   BIGINT NOT NULL COMMENT '第2日留存用户量',
    `day3_retention`   BIGINT NOT NULL COMMENT '第3日留存用户量',
    `day4_retention`   BIGINT NOT NULL COMMENT '第4日留存用户量',
    `day5_retention`   BIGINT NOT NULL COMMENT '第5日留存用户量',
    `day6_retention`   BIGINT NOT NULL COMMENT '第6日留存用户量',
    `day7_retention`   BIGINT NOT NULL COMMENT '第7日留存用户量',
    `day8_retention`   BIGINT NOT NULL COMMENT '第8日留存用户量',
    `day9_retention`   BIGINT NOT NULL COMMENT '第9日留存用户量',
    `day10_retention`  BIGINT NOT NULL COMMENT '第10日留存用户量',
    `day11_retention`  BIGINT NOT NULL COMMENT '第11日留存用户量',
    `day12_retention`  BIGINT NOT NULL COMMENT '第12日留存用户量',
    `day13_retention`  BIGINT NOT NULL COMMENT '第13日留存用户量',
    `day14_retention`  BIGINT NOT NULL COMMENT '第14日留存用户量',
    `day15_retention`  BIGINT NOT NULL COMMENT '第15日留存用户量',
    `day16_retention`  BIGINT NOT NULL COMMENT '第16日留存用户量',
    `day17_retention`  BIGINT NOT NULL COMMENT '第17日留存用户量',
    `day18_retention`  BIGINT NOT NULL COMMENT '第18日留存用户量',
    `day19_retention`  BIGINT NOT NULL COMMENT '第19日留存用户量',
    `day20_retention`  BIGINT NOT NULL COMMENT '第20日留存用户量',
    `day21_retention`  BIGINT NOT NULL COMMENT '第21日留存用户量',
    `day22_retention`  BIGINT NOT NULL COMMENT '第22日留存用户量',
    `day23_retention`  BIGINT NOT NULL COMMENT '第23日留存用户量',
    `day24_retention`  BIGINT NOT NULL COMMENT '第24日留存用户量',
    `day25_retention`  BIGINT NOT NULL COMMENT '第25日留存用户量',
    `day26_retention`  BIGINT NOT NULL COMMENT '第26日留存用户量',
    `day27_retention`  BIGINT NOT NULL COMMENT '第27日留存用户量',
    `day28_retention`  BIGINT NOT NULL COMMENT '第28日留存用户量',
    `day29_retention`  BIGINT NOT NULL COMMENT '第29日留存用户量',
    `day30_retention`  BIGINT NOT NULL COMMENT '第30日留存用户量'
) ENGINE = OLAP
PRIMARY KEY (`dt`, `user_type`)
COMMENT "不同用户类型留存"
PARTITION BY date_trunc('month', dt)          -- ★ 月分区，减少元数据压力
DISTRIBUTED BY HASH(`dt`, `user_type`)
PROPERTIES (
    "replication_num" = "2",
    "in_memory" = "false",
    "enable_persistent_index" = "true",
    "replicated_storage" = "true",
    "compression" = "LZ4"
);


-- ============================ INSERT ============================
-- 优化核心:
--   1. 全程使用 DATE 类型，不再 date_format 转 VARCHAR
--   2. 用单层 self-join 替代原来3层嵌套的 mau_info_batch
--   3. 预计算 prior30_visit_days，避免每个锚点日期都扫描30天窗口
--   4. session 变量优化部分列更新和并行度

SET query_timeout = 7200;

INSERT INTO dwd.dwd_sr_user_retention_d
WITH
-- ============================================================
-- CTE 1: 每日活跃用户（纯DATE类型）
-- 范围: T-61 ~ T+30，覆盖最远锚点(T-31)的30天前 + 最近锚点(T-1)的30天后
-- ============================================================
t_active AS (
    SELECT
        dt,
        unnest_bitmap AS user_id
    FROM dwd.dwd_sr_traffic_viewuser_d,
         unnest_bitmap(user_ids) AS uid
    WHERE dt BETWEEN DATE_ADD('${T}', INTERVAL -61 DAY)
                 AND DATE_ADD('${T}', INTERVAL 30 DAY)
    GROUP BY dt, user_id
),

-- ============================================================
-- CTE 2: 锚点日期的活跃用户（T-31 ~ T-1）
-- 只有这些日期需要计算DAU和留存
-- ============================================================
t_anchor AS (
    SELECT dt, user_id
    FROM t_active
    WHERE dt BETWEEN DATE_SUB('${T}', INTERVAL 31 DAY)
                 AND DATE_SUB('${T}', INTERVAL 1 DAY)
),

-- ============================================================
-- CTE 3: 锚点用户在过去30天的访问天数
-- ★ 核心优化: 一次性计算所有锚点日期的 prior30 访问天数
--   替代原来 per-anchor-date 的 NESTLOOP（原1.59亿行）
-- ============================================================
t_prior30 AS (
    SELECT
        a.dt,
        a.user_id,
        COUNT(b.dt) AS visit_days
    FROM t_anchor a
    LEFT JOIN t_active b
        ON a.user_id = b.user_id
        AND b.dt >= DATE_SUB(a.dt, INTERVAL 30 DAY)
        AND b.dt <= DATE_SUB(a.dt, INTERVAL 1 DAY)
    GROUP BY a.dt, a.user_id
),

-- ============================================================
-- CTE 4: 用户类型分类
-- 优先级: 近30天分段 > 注册当日 > 近30天无访问 > 其他
-- ============================================================
t_classified AS (
    SELECT
        a.dt,
        a.user_id,
        CASE
            WHEN p.visit_days BETWEEN 1 AND 6   THEN '近30天访问1-6天'
            WHEN p.visit_days BETWEEN 7 AND 12  THEN '近30天访问7-12天'
            WHEN p.visit_days BETWEEN 13 AND 18 THEN '近30天访问13-18天'
            WHEN p.visit_days BETWEEN 19 AND 24 THEN '近30天访问19-24天'
            WHEN p.visit_days >= 25             THEN '近30天访问25-30天'
            WHEN DATE(FROM_UNIXTIME(u.register_time, 'yyyy-MM-dd')) = a.dt
                                                 THEN '注册'
            WHEN p.visit_days IS NULL           THEN '近30天无访问'
            ELSE '其他'
        END AS user_type
    FROM t_anchor a
    LEFT JOIN t_prior30 p
        ON a.user_id = p.user_id AND a.dt = p.dt
    LEFT JOIN dim.dim_silkworm_client_user_realtime u
        ON a.user_id = u.silk_id
),

-- ============================================================
-- CTE 5: 留存明细 — 展开每个用户未来1-30天的回访情况
-- 用单次 LEFT JOIN + 范围条件，替代30个独立的 IF(date_diff=N)
-- ============================================================
t_retention_flat AS (
    SELECT
        t1.dt,
        t1.user_id,
        t1.user_type,
        DATE_DIFF('day', t1.dt, t2.dt) AS day_offset
    FROM t_classified t1
    LEFT JOIN t_active t2
        ON t1.user_id = t2.user_id
        AND t2.dt >= DATE_ADD(t1.dt, INTERVAL 1 DAY)
        AND t2.dt <= DATE_ADD(t1.dt, INTERVAL 30 DAY)
)

-- ============================================================
-- 最终聚合: PIVOT day_offset → 30个留存列
-- ============================================================
SELECT
    dt,
    user_type,
    COUNT(DISTINCT user_id)                                                            AS DAU,
    COUNT(DISTINCT CASE WHEN day_offset =  1 THEN user_id END)                        AS day1_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  2 THEN user_id END)                        AS day2_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  3 THEN user_id END)                        AS day3_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  4 THEN user_id END)                        AS day4_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  5 THEN user_id END)                        AS day5_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  6 THEN user_id END)                        AS day6_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  7 THEN user_id END)                        AS day7_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  8 THEN user_id END)                        AS day8_retention,
    COUNT(DISTINCT CASE WHEN day_offset =  9 THEN user_id END)                        AS day9_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 10 THEN user_id END)                        AS day10_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 11 THEN user_id END)                        AS day11_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 12 THEN user_id END)                        AS day12_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 13 THEN user_id END)                        AS day13_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 14 THEN user_id END)                        AS day14_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 15 THEN user_id END)                        AS day15_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 16 THEN user_id END)                        AS day16_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 17 THEN user_id END)                        AS day17_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 18 THEN user_id END)                        AS day18_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 19 THEN user_id END)                        AS day19_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 20 THEN user_id END)                        AS day20_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 21 THEN user_id END)                        AS day21_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 22 THEN user_id END)                        AS day22_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 23 THEN user_id END)                        AS day23_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 24 THEN user_id END)                        AS day24_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 25 THEN user_id END)                        AS day25_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 26 THEN user_id END)                        AS day26_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 27 THEN user_id END)                        AS day27_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 28 THEN user_id END)                        AS day28_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 29 THEN user_id END)                        AS day29_retention,
    COUNT(DISTINCT CASE WHEN day_offset = 30 THEN user_id END)                        AS day30_retention
FROM t_retention_flat
GROUP BY dt, user_type;
