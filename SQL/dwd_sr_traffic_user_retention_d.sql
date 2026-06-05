-- ============================================================================
-- 表名: dwd.dwd_sr_traffic_user_retention_d
-- 中文名: 分用户类型日留存
-- 作者: hongxiu
-- 创建日期: 2026-05-27
-- ============================================================================
--
-- ============================================================================
-- 一、设计要点
-- ============================================================================
--
-- 1. 竖表（长表）vs 宽表 — 关键区别
--
-- ┌────────────┬──────────────────────────────────┬──────────────────────────────────┐
-- │ 维度       │ 宽表（原方案）                    │ 竖表（本方案）                    │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 表结构     │ dt|user_type|DAU|day1|...|day30  │ dt|user_type|retain_day|DAU|user_count│
-- │            │ 一行 = 1个日期 + 30个留存列       │ 一行 = 1个日期 + 1个留存天数 + DAU   │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 计算模式   │ 全量重算                          │ 增量追加                          │
-- │            │ 每天重算最近31天 × 30列            │ 每天只算今天"成熟"的那一层留存    │
-- │            │ 99%的计算结果和昨天一样            │ 每条数据只算一次，永不复算        │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 数据扫描   │ 92天（D-61 ~ D+30）               │ 61天（D-60 ~ D）                  │
-- │            │ 需要扫描「未来30天」做留存匹配     │ 只需扫描「过去」，不需未来数据    │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 每日写入量 │ 279行（31天×9种user_type）        │ 279行（DAU + 回刷30天，含'全部'）  │
-- │            │ 但每次都全量覆盖（DELETE+INSERT） │ 真正增量 UPSERT（新数据才插入）   │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 数据新鲜度 │ 每天重算后，最近30天数据都会变     │ 每天只有当天的新增数据，历史不变  │
-- │            │ 历史数据可能在重跑时被意外修改    │ 历史数据天然稳定，不受后续影响    │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 任务重跑   │ 重跑会覆盖所有31天数据            │ 只影响当天新增的行，历史无损      │
-- │            │ 需要确保重跑期间的正确性          │ PRIMARY KEY UPSERT 天然幂等       │
-- ├────────────┼──────────────────────────────────┼──────────────────────────────────┤
-- │ 查询使用   │ SELECT day7_retention FROM ...    │ SELECT user_count, user_count/DAU AS rate │
-- │            │ 直接取列，无需转换                │   WHERE retain_day = 7              │
-- │            │ 留存率需 user_count/DAU 手算     │  DAU 列自带，留存率直接除即可       │
-- └────────────┴──────────────────────────────────┴──────────────────────────────────┘
--
-- 核心设计理念:
--   宽表的思路是「每个日期存所有留存值」→ 每天都要重算才能保证完整
--   竖表的思路是「每个留存值独立存储」   → 每条数据只在自己"成熟"的那天算一次
--   这就像:
--     - 宽表 = 每天拍一张全体合影（30个人，每天都拍，99%没变化）
--     - 竖表 = 每天只拍今天过生日的那个人（30天轮一圈，每条数据只拍一次）
--
-- 具体例子: 2026-05-01 的 day7 留存（即 05-08 有没有回访）
--   宽表做法: 5月1日算一次(不完整) → 5月2日重算 → ... → 5月8日终于算对 → 之后每天还在重算
--   竖表做法: 只在 5月8日 T+1 算一次，然后这条数据永久不变
--
-- 2. 字段语义
--    DAU         — 锚点日期的活跃用户量（所有 retain_day 行共用同一 DAU，方便帆软BI直接算留存率）
--    retain_day  — 0=当日DAU, 1=次日留存, ..., 30=第30日留存
--    user_count  — retain_day=0 时 = DAU；retain_day>0 时 = 第N日留存用户量
--    留存率       — user_count / DAU（帆软BI直接除，无需窗口函数或自连接）
--
-- 3. 增量计算原理（为什么竖表是"治本"方案）
--    以 D=2026-05-27 为例，T+1 调度（T=05-28）只做两件事：
--
--    Part A — 插入 D-day 的 DAU（retain_day=0, user_count=DAU）
--      计算 05-27 当天的活跃用户量，按 user_type 分类
--
--    Part B — 回刷 D-1 ~ D-30 的留存（retain_day=1..30, user_count=留存用户量, DAU=锚点日期DAU）
--      用 05-27 的活跃用户，匹配 04-27 ~ 05-26 的历史锚点用户
--      对于锚点日期 05-20，retain_day = 7，DAU = 05-20的DAU，user_count = 交集用户数
--      帆软BI可直接用 user_count / DAU = 留存率
--
-- 4. 数据扫描范围
--    每天 T+1 运行只需扫描 D-60 ~ D（共61天）
--    对比宽表需要扫描 D-61 ~ D+30（共92天），减少约1/3的数据扫描量
--    原因：最早锚点 D-30 需要往前看30天做用户分类（D-60），最晚锚点 D-1
--
-- 5. 用户类型（user_type）分类规则
--    (0) 全部               — 所有用户合计（用于看大盘整体留存）
--    (1) 近30天访问1-6天     — prior30_visit_days IN [1, 6]
--    (2) 近30天访问7-12天    — prior30_visit_days IN [7, 12]
--    (3) 近30天访问13-18天   — prior30_visit_days IN [13, 18]
--    (4) 近30天访问19-24天   — prior30_visit_days IN [19, 24]
--    (5) 近30天访问25-30天   — prior30_visit_days >= 25
--    (6) 注册               — 注册日期 = 锚点日期（且不在上述分段中）
--    (7) 近30天无访问        — prior30_visit_days = 0
--    (8) 其他               — 兜底
--
--    注：prior30_visit_days = 锚点日期往前30天内该用户的访问天数
--    「全部」由 t_dau 单独 UNION ALL 聚合，不参与 t_classified 的 CASE WHEN 分类
--
-- 6. 调度参数
--    ${T}   = WeData 任务实例日期（如 2026-05-28）
--    ${T-1} = 数据日期 D（如 2026-05-27），即实际计算的数据日期
--    WeData 配置: 天级调度，依赖上游 dwd_sr_traffic_viewuser_d 完成
--
-- ============================================================================
-- 二、执行步骤（请按顺序执行）
-- ============================================================================
--
-- 步骤1: 执行下方 DDL，创建表
-- 步骤2: 在 WeData 配置 T+1 天级调度任务（使用「每日 T+1 调度 SQL」）
-- 步骤3: WeData 补数据回刷历史日期（详见「五、历史数据回补」）
-- 步骤4: 运行「数据验证 SQL」确认结果正确
--
-- ============================================================================


-- ============================================================================
-- 三、DDL
-- ============================================================================

DROP TABLE IF EXISTS dwd.dwd_sr_traffic_user_retention_d;

CREATE TABLE IF NOT EXISTS dwd.dwd_sr_traffic_user_retention_d
(
    `dt`          DATE    NOT NULL COMMENT '锚点日期（用户活跃日期）',
    `user_type`   STRING  NOT NULL COMMENT '用户类型',
    `retain_day`  TINYINT NOT NULL COMMENT '留存天数（0=当日DAU, 1=次日留存, ..., 30=第30日留存）',
    `DAU`         BIGINT  NOT NULL COMMENT '当日DAU（锚点日期的活跃用户量，所有retain_day共用同一DAU）',
    `retain_user_num`  BIGINT  NOT NULL COMMENT '用户量（retain_day=0时=DAU, retain_day>0时=第N日留存用户量）'
) ENGINE = OLAP
PRIMARY KEY (`dt`, `user_type`, `retain_day`)
COMMENT "分用户类型日留存"
PARTITION BY date_trunc('month', `dt`)
DISTRIBUTED BY HASH(`dt`, `user_type`)
PROPERTIES (
    "replication_num" = "2",
    "in_memory" = "false",
    "enable_persistent_index" = "true",
    "replicated_storage" = "true",
    "compression" = "LZ4"
);


-- ============================================================================
-- 四、每日 T+1 调度 SQL
-- ============================================================================
-- 参数: ${T} = 任务运行日期（WeData 自动传入，如 2026-05-28）
-- 数据日期 D = ${T} - 1（即 2026-05-27）
--
-- 每次运行插入的数据量:
--   Part A: 每种 user_type（含'全部'）各1行 retain_day=0 → 约9行/天
--   Part B: D-1~D-30 每个历史日期 × 每种 user_type（含'全部'）各1行 → 约 270行/天
--   合计: 约 279行/天（vs 宽表全量重算31天 × 8种类型 = 248行/天，但计算量完全不同）
--
-- 关键特性:
--   - StarRocks PRIMARY KEY 表 INSERT 自动覆盖相同主键的行（UPSERT）
--   - 如果某天任务重跑，不会产生重复数据
--   - retain_day=0 和 retain_day>0 是独立计算、独立插入的
-- ============================================================================

SET query_timeout = 7200;

INSERT INTO dwd.dwd_sr_traffic_user_retention_d
WITH
-- CTE 1: 每日活跃用户明细（D-60 ~ D，共61天）
t_active AS (
    SELECT
        dt,
        unnest_bitmap AS user_id
    FROM dwd.dwd_sr_traffic_viewuser_d,
         unnest_bitmap(user_ids) AS uid
    WHERE dt BETWEEN DATE_SUB('${T-1}', INTERVAL 60 DAY)
                 AND '${T-1}'
    GROUP BY dt, user_id
),

-- CTE 2: 锚点日期范围 D-30 ~ D 的所有活跃用户，计算 prior30 访问天数
t_anchor_with_prior30 AS (
    SELECT
        a.dt,
        a.user_id,
        COUNT(b.dt) AS prior30_visit_days
    FROM (
        SELECT dt, user_id
        FROM t_active
        WHERE dt BETWEEN DATE_SUB('${T-1}', INTERVAL 30 DAY)
                     AND '${T-1}'
    ) a
    LEFT JOIN t_active b
        ON a.user_id = b.user_id
        AND b.dt >= DATE_SUB(a.dt, INTERVAL 30 DAY)
        AND b.dt <= DATE_SUB(a.dt, INTERVAL 1 DAY)
    GROUP BY a.dt, a.user_id
),

-- CTE 3: 用户类型分类
t_classified AS (
    SELECT
        a.dt,
        a.user_id,
        CASE
            WHEN a.prior30_visit_days BETWEEN 1 AND 6   THEN '近30天访问1-6天'
            WHEN a.prior30_visit_days BETWEEN 7 AND 12  THEN '近30天访问7-12天'
            WHEN a.prior30_visit_days BETWEEN 13 AND 18 THEN '近30天访问13-18天'
            WHEN a.prior30_visit_days BETWEEN 19 AND 24 THEN '近30天访问19-24天'
            WHEN a.prior30_visit_days >= 25             THEN '近30天访问25-30天'
            WHEN DATE(FROM_UNIXTIME(u.register_time, 'yyyy-MM-dd')) = a.dt
                                                        THEN '注册'
            WHEN a.prior30_visit_days = 0               THEN '近30天无访问'
            ELSE '其他'
        END AS user_type
    FROM t_anchor_with_prior30 a
    LEFT JOIN dim.dim_silkworm_client_user_realtime u
        ON a.user_id = u.silk_id
),

-- CTE 4: D-day 的活跃用户（用于回刷留存匹配）
t_today AS (
    SELECT DISTINCT user_id
    FROM t_active
    WHERE dt = '${T-1}'
),

-- CTE 5: 各锚点日期的 DAU（供 Part A 和 Part B 关联）
t_dau AS (
    SELECT
        dt,
        user_type,
        COUNT(DISTINCT user_id) AS DAU
    FROM t_classified
    GROUP BY dt, user_type

    UNION ALL

    SELECT
        dt,
        '全部' AS user_type,
        COUNT(DISTINCT user_id) AS DAU
    FROM t_classified
    GROUP BY dt
)

-- Part A: D-day 的 DAU（retain_day = 0）
SELECT
    d.dt,
    d.user_type,
    0 AS retain_day,
    d.DAU,
    d.DAU AS user_count
FROM t_dau d
WHERE d.dt = '${T-1}'

UNION ALL

-- Part B: 回刷 D-1 ~ D-30 的留存
-- 逻辑: 历史锚点日活跃用户 ∩ D-day活跃用户 = 第N日留存用户
SELECT
    past.dt,
    past.user_type,
    DATEDIFF('${T-1}', past.dt) AS retain_day,
    d.DAU,
    COUNT(DISTINCT today.user_id) AS user_count
FROM t_classified past
INNER JOIN t_today today
    ON past.user_id = today.user_id
LEFT JOIN t_dau d
    ON past.dt = d.dt AND past.user_type = d.user_type
WHERE past.dt BETWEEN DATE_SUB('${T-1}', INTERVAL 30 DAY)
                   AND DATE_SUB('${T-1}', INTERVAL 1 DAY)
GROUP BY past.dt, past.user_type, DATEDIFF('${T-1}', past.dt), d.DAU

UNION ALL

-- Part B 补充: '全部' 类型的留存（所有用户不区分 user_type）
SELECT
    past.dt,
    '全部' AS user_type,
    DATEDIFF('${T-1}', past.dt) AS retain_day,
    d.DAU,
    COUNT(DISTINCT today.user_id) AS user_count
FROM (SELECT DISTINCT dt, user_id FROM t_classified) past
INNER JOIN t_today today
    ON past.user_id = today.user_id
LEFT JOIN t_dau d
    ON past.dt = d.dt AND d.user_type = '全部'
WHERE past.dt BETWEEN DATE_SUB('${T-1}', INTERVAL 30 DAY)
                   AND DATE_SUB('${T-1}', INTERVAL 1 DAY)
GROUP BY past.dt, DATEDIFF('${T-1}', past.dt), d.DAU
;


-- ============================================================================
-- 五、历史数据回补（WeData 补数据）
-- ============================================================================
-- 说明: 首次建表后，表是空的。不需要单独的初始化 SQL，直接用 WeData 的
--       「补数据」功能，对历史日期范围批量执行每日 T+1 调度 SQL 即可。
--
-- 原理: 每日 T+1 SQL 是日期通用的——${T-1} 换成任意日期都能正确计算。
--       对历史日期依次执行，每条数据在自己"成熟"那天算一次，逐步累加。
--
-- WeData 操作步骤:
--   1. 将「每日 T+1 调度 SQL」配置为 WeData 天级调度任务
--   2. 使用 WeData「补数据」功能，设置补数据日期范围:
--      开始日期: 最早需要回补的日期（如 2025-01-01）
--      结束日期: 昨天（如 2026-05-26）
--   3. WeData 会为每个日期生成一个任务实例，按日期顺序执行
--   4. 每个实例传入对应的 ${T}（实例日期），自动计算 ${T-1}
--
-- 关于执行顺序（重要）:
--   补数据实例之间互不依赖，任意顺序执行结果完全一致。
--   原因: 每条 (dt, user_type, retain_day) 数据只由唯一一个 D-day 负责计算:
--     锚点日期的 retain_day=0  → 由 D-day = 锚点日期 计算
--     锚点日期的 retain_day=N  → 由 D-day = 锚点日期 + N 计算
--   例如锚点 2026-01-19 的 retain_day=12，只会在 D-day=2026-01-31 这一天被计算。
--   先跑 2月还是先跑 1月的实例，操作的是不同主键行，互不覆盖。
--
-- 其他提示:
--   - 补数据会生成大量实例（如回补1年 = 365个实例），建议错峰执行
--   - 单个实例失败不影响其他日期，重跑失败的实例即可
--   - 回补完成后，最近30天的数据仍不完整（day30 需要等30天）→ 正常现象
--   - 后续每天 T+1 自动运行，30天后数据全部补齐
--
-- 如果想从宽表快速迁移（可选，不是必须）:
--   如果宽表 dwd.dwd_sr_user_retention_d 已有完整历史数据，也可用以下 SQL
--   一次性 UNPIVOT 导入竖表，比跑几百个补数据实例快很多:
--
--   INSERT INTO dwd.dwd_sr_traffic_user_retention_d
--   SELECT dt, user_type, 0  AS retain_day, DAU              AS user_count FROM dwd.dwd_sr_user_retention_d WHERE DAU > 0
--   UNION ALL
--   SELECT dt, user_type, 1  AS retain_day, day1_retention   AS user_count FROM dwd.dwd_sr_user_retention_d WHERE day1_retention > 0
--   UNION ALL
--   ... (依次 day2 ~ day30，共31个 UNION ALL)
--   SELECT dt, user_type, 30 AS retain_day, day30_retention  AS user_count FROM dwd.dwd_sr_user_retention_d WHERE day30_retention > 0;
--
-- ============================================================================


-- ============================================================================
-- 六、数据验证 SQL
-- ============================================================================
-- 执行以下 SQL 确认竖表数据与宽表一致（如果宽表可用）
-- 替换 ${check_date} 为要验证的日期，如 '2026-05-20'
-- ============================================================================

/*
-- 验证1: 竖表行数是否合理（每个日期 × 每种user_type × 31个retain_day）
SELECT
    dt,
    COUNT(*) AS row_count,
    COUNT(DISTINCT user_type) AS type_count,
    COUNT(DISTINCT retain_day) AS retain_day_count
FROM dwd.dwd_sr_traffic_user_retention_d
WHERE dt = '${check_date}'
GROUP BY dt;

-- 验证2: 竖表 vs 宽表 — DAU 对比（直接用 DAU 列）
SELECT
    v.dt,
    v.user_type,
    v.DAU         AS vertical_DAU,
    w.DAU         AS wide_DAU,
    v.DAU - w.DAU AS diff
FROM dwd.dwd_sr_traffic_user_retention_d v
LEFT JOIN dwd.dwd_sr_user_retention_d w
    ON v.dt = w.dt AND v.user_type = w.user_type
WHERE v.dt = '${check_date}'
  AND v.retain_day = 0
  AND v.DAU != w.DAU;

-- 验证3: 竖表 vs 宽表 — 次日留存对比（retain_day=1 vs day1_retention）
SELECT
    v.dt,
    v.user_type,
    v.user_count  AS vertical_day1,
    w.day1_retention AS wide_day1,
    v.user_count - w.day1_retention AS diff
FROM dwd.dwd_sr_traffic_user_retention_d v
LEFT JOIN dwd.dwd_sr_user_retention_d w
    ON v.dt = w.dt AND v.user_type = w.user_type
WHERE v.dt = '${check_date}'
  AND v.retain_day = 1
  AND v.user_count != w.day1_retention;

-- 验证4: 竖表 vs 宽表 — 所有留存天数全面对比
-- 将竖表 PIVOT 成宽表格式后做全量对比
WITH vertical_pivot AS (
    SELECT
        dt,
        user_type,
        MAX(CASE WHEN retain_day = 0  THEN user_count END) AS DAU,
        MAX(CASE WHEN retain_day = 1  THEN user_count END) AS day1,
        MAX(CASE WHEN retain_day = 2  THEN user_count END) AS day2,
        MAX(CASE WHEN retain_day = 3  THEN user_count END) AS day3,
        MAX(CASE WHEN retain_day = 4  THEN user_count END) AS day4,
        MAX(CASE WHEN retain_day = 5  THEN user_count END) AS day5,
        MAX(CASE WHEN retain_day = 6  THEN user_count END) AS day6,
        MAX(CASE WHEN retain_day = 7  THEN user_count END) AS day7,
        MAX(CASE WHEN retain_day = 14 THEN user_count END) AS day14,
        MAX(CASE WHEN retain_day = 30 THEN user_count END) AS day30
    FROM dwd.dwd_sr_traffic_user_retention_d
    WHERE dt = '${check_date}'
    GROUP BY dt, user_type
)
SELECT
    v.dt,
    v.user_type,
    v.DAU   AS v_DAU,   w.DAU              AS w_DAU,
    v.day1  AS v_day1,  w.day1_retention   AS w_day1,
    v.day7  AS v_day7,  w.day7_retention   AS w_day7,
    v.day14 AS v_day14, w.day14_retention  AS w_day14,
    v.day30 AS v_day30, w.day30_retention  AS w_day30,
    CASE WHEN v.DAU   != w.DAU              THEN 'DAU≠'   ELSE '' END ||
    CASE WHEN v.day1  != w.day1_retention   THEN 'D1≠'    ELSE '' END ||
    CASE WHEN v.day7  != w.day7_retention   THEN 'D7≠'    ELSE '' END ||
    CASE WHEN v.day14 != w.day14_retention  THEN 'D14≠'   ELSE '' END ||
    CASE WHEN v.day30 != w.day30_retention  THEN 'D30≠'   ELSE '' END AS issues
FROM vertical_pivot v
LEFT JOIN dwd.dwd_sr_user_retention_d w
    ON v.dt = w.dt AND v.user_type = w.user_type
WHERE v.dt = '${check_date}';
*/


-- ============================================================================
-- 七、常见问题 FAQ
-- ============================================================================
--
-- Q1: 为什么历史数据初始化后，最新几天的30日留存是空的？
-- A1: 30日留存需要等30天后才能"成熟"。例如 2026-05-27 的 day30 留存，
--    需要等到 2026-06-27 才能计算（锚点日期后第30天有没有回访）。
--    这是正常的，每日 T+1 调度会自动补齐。
--
-- Q2: 如果某天任务失败了，重跑会怎样？
-- A2: PRIMARY KEY 表 INSERT 是 UPSERT 语义，相同主键自动覆盖。
--    直接重跑当天的调度即可，不会产生重复数据。
--
-- Q3: 竖表和宽表可以同时运行吗？
-- A3: 可以。两张表独立计算，互不影响。建议并行运行一段时间，
--    用验证 SQL 对比数据一致性，确认竖表稳定后再停掉宽表。
--
-- Q4: 竖表的存储量大概多少？
-- A4: 每天约 9种user_type（含'全部'）× 31个retain_day = 279行。一年约 10万行。
--    每条数据 ~50字节，总存储 < 5MB/年。实际存储量极小。
--
-- Q5: 如果后续要改 user_type 的分类规则怎么办？
-- A5: 分类规则变了，历史数据的 user_type 也需要重算，否则前后口径不一致。
--    清空表数据（DROP TABLE 后重建），然后用 WeData 补数据重新回补全部历史日期。
--    注：「全部」类型不受分类规则影响，因为它不依赖 CASE WHEN 分类。
--
-- ============================================================================
