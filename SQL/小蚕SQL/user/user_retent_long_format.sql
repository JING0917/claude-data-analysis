--JDBC SQL
--******************************************************************--
--author: Claude (长表结构版本)
--create time: 2026-04-08
--******************************************************************--
/*
用户留存统计 - 长表结构版
目标：计算每日用户留存数据，按用户类型和留存天数列举
版本：长表结构版
日期：2026-04-08

设计特点：
1. 扩展性强：使用长表结构，易于扩展更多留存天数
2. 查询灵活：支持按任意留存天数范围查询
3. 便于计算：留存率可直接计算（retention_count / dau）
4. 兼容性好：BI工具可轻松处理长表数据

表结构：
- dt: 日期
- user_type: 用户类型
- retention_day: 留存天数（1-30）
- dau: 日活用户数
- retention_count: 留存用户数

参数说明：
${T} - 当前处理日期，格式：'2026-03-31'

执行说明：
1. 首次执行：运行建表语句（如果表不存在）
2. 每日任务：执行数据插入部分
3. 依赖表：
   - dwd.dwd_sr_traffic_viewuser_d (用户访问表，包含user_ids bitmap)
   - dim.dim_silkworm_client_user_realtime (用户维度表)
*/

-- ==================== 建表语句（长表结构） ====================
-- 如果表不存在，先创建
CREATE TABLE IF NOT EXISTS dwd.dwd_sr_user_retention_long_d
(
    `dt` date NOT NULL COMMENT '日期',
    `user_type` string NOT NULL COMMENT '用户类型',
    `retention_day` int NOT NULL COMMENT '留存天数（1-30）',
    `dau` bigint NOT NULL COMMENT '日活用户数',
    `retention_count` bigint NOT NULL COMMENT '留存用户数',
    `retention_rate` decimal(8,4) COMMENT '留存率（retention_count/dau）'
) ENGINE=OLAP
PRIMARY KEY(dt, user_type, retention_day)
COMMENT "不同用户类型留存（长表结构）"
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(dt, user_type)
PROPERTIES (
    "replication_num" = "2",
    "in_memory" = "false",
    "enable_persistent_index" = "true",
    "replicated_storage" = "true",
    "compression" = "LZ4"
);

-- ==================== 数据插入（长表结构版） ====================
INSERT INTO dwd.dwd_sr_user_retention_long_d
WITH
-- 步骤1：基础数据准备 - 提取用户访问记录
-- 时间范围：${T}-60 到 ${T}（共61天，覆盖30天留存计算）
user_visits AS (
    SELECT
        DATE(dt) AS visit_date,
        unnest_bitmap AS user_id
    FROM dwd.dwd_sr_traffic_viewuser_d,
         unnest_bitmap(user_ids) AS uid
    WHERE dt BETWEEN DATE_SUB(DATE('${T}'), INTERVAL 60 DAY)
                 AND DATE('${T}')
    GROUP BY DATE(dt), unnest_bitmap
),

-- 步骤2：用户活跃日期矩阵
user_active_dates AS (
    SELECT
        user_id,
        visit_date AS active_date
    FROM user_visits
),

-- 步骤3：需要计算的基准日期范围（最近30天）
calc_dates AS (
    SELECT
        DATE_SUB(DATE('${T}'), INTERVAL n-1 DAY) AS cohort_date
    FROM (
        SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
        UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25
        UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
    ) nums
),

-- 步骤4：用户注册信息
user_registration AS (
    SELECT
        silk_id AS user_id,
        DATE(FROM_UNIXTIME(register_time, 'yyyy-MM-dd')) AS register_date
    FROM dim.dim_silkworm_client_user_realtime
),

-- 步骤5：计算每个用户在基准日期的前30天访问天数
user_30day_visits AS (
    SELECT
        cd.cohort_date,
        uad.user_id,
        COUNT(DISTINCT uv.visit_date) AS visit_days_last_30d
    FROM calc_dates cd
    CROSS JOIN user_active_dates uad
    LEFT JOIN user_visits uv
        ON uv.user_id = uad.user_id
        AND uv.visit_date BETWEEN DATE_SUB(cd.cohort_date, INTERVAL 30 DAY)
                              AND DATE_SUB(cd.cohort_date, INTERVAL 1 DAY)
    WHERE uad.active_date = cd.cohort_date  -- 只计算当天活跃的用户
    GROUP BY cd.cohort_date, uad.user_id
),

-- 步骤6：用户类型分类
user_type_classification AS (
    SELECT
        cohort_date,
        user_id,
        CASE
            WHEN visit_days_last_30d BETWEEN 1 AND 6 THEN '近30天访问1-6天'
            WHEN visit_days_last_30d BETWEEN 7 AND 12 THEN '近30天访问7-12天'
            WHEN visit_days_last_30d BETWEEN 13 AND 18 THEN '近30天访问13-18天'
            WHEN visit_days_last_30d BETWEEN 19 AND 24 THEN '近30天访问19-24天'
            WHEN visit_days_last_30d >= 25 THEN '近30天访问25-30天'
            WHEN visit_days_last_30d = 0 THEN '近30天无访问'
            ELSE '其他'
        END AS user_type
    FROM user_30day_visits
),

-- 步骤7：用户类型最终确定（考虑注册用户）
user_final_type AS (
    SELECT
        utc.cohort_date AS dt,
        utc.user_id,
        COALESCE(
            utc.user_type,
            CASE
                WHEN ur.register_date = utc.cohort_date THEN '注册'
                ELSE '近30天无访问'
            END
        ) AS user_type
    FROM user_type_classification utc
    LEFT JOIN user_registration ur
        ON utc.user_id = ur.user_id
),

-- 步骤8：留存匹配 - 找到用户后续回访
user_return_visits AS (
    SELECT
        uft.dt,
        uft.user_type,
        uft.user_id,
        uad2.active_date AS return_date,
        DATEDIFF(uad2.active_date, uft.dt) AS days_diff
    FROM user_final_type uft
    LEFT JOIN user_active_dates uad2
        ON uft.user_id = uad2.user_id
        AND uad2.active_date > uft.dt
        AND uad2.active_date <= DATE_ADD(uft.dt, INTERVAL 30 DAY)
),

-- 步骤9：按留存天数聚合（长表格式）
retention_by_day AS (
    SELECT
        dt,
        user_type,
        days_diff AS retention_day,
        COUNT(DISTINCT user_id) AS retention_count
    FROM user_return_visits
    WHERE days_diff BETWEEN 1 AND 30
    GROUP BY dt, user_type, days_diff
),

-- 步骤10：计算每日各用户类型的DAU
dau_by_type AS (
    SELECT
        dt,
        user_type,
        COUNT(DISTINCT user_id) AS dau
    FROM user_final_type
    GROUP BY dt, user_type
),

-- 步骤11：生成完整的留存天数序列（1-30天）
retention_days AS (
    SELECT 1 AS retention_day UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25
    UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30
),

-- 步骤12：组合所有维度（日期×用户类型×留存天数）
all_combinations AS (
    SELECT
        dt,
        user_type,
        rd.retention_day
    FROM dau_by_type dbt
    CROSS JOIN retention_days rd
),

-- 步骤13：最终数据准备
final_data AS (
    SELECT
        ac.dt,
        ac.user_type,
        ac.retention_day,
        dbt.dau,
        COALESCE(rbd.retention_count, 0) AS retention_count,
        CASE
            WHEN dbt.dau > 0 THEN ROUND(COALESCE(rbd.retention_count, 0) * 100.0 / dbt.dau, 4)
            ELSE 0
        END AS retention_rate
    FROM all_combinations ac
    LEFT JOIN dau_by_type dbt
        ON ac.dt = dbt.dt AND ac.user_type = dbt.user_type
    LEFT JOIN retention_by_day rbd
        ON ac.dt = rbd.dt AND ac.user_type = rbd.user_type AND ac.retention_day = rbd.retention_day
)

-- 插入数据
SELECT
    dt,
    user_type,
    retention_day,
    dau,
    retention_count,
    retention_rate
FROM final_data
ORDER BY dt DESC, user_type, retention_day;

-- ==================== 长表结构优势说明 ====================
/*
长表结构优势：
1. 扩展性强：无需修改表结构即可支持更多留存天数
2. 查询灵活：
   - 查询前N天留存：WHERE retention_day <= N
   - 查询特定留存天数：WHERE retention_day = 7
   - 计算留存率：retention_count / dau
3. 存储高效：只存储实际需要的留存天数，可轻松扩展到60、90天
4. 分析方便：
   - 趋势分析：按retention_day分组查看留存曲线
   - 对比分析：不同用户类型的留存对比
   - 聚合分析：计算平均留存、中位数留存等

查询示例：
1. 查看某日各用户类型的留存曲线
   SELECT retention_day, user_type, retention_count, retention_rate
   FROM dwd.dwd_sr_user_retention_long_d
   WHERE dt = '2026-03-31'
   ORDER BY user_type, retention_day;

2. 查看最近7天各用户类型的DAU和次日留存
   SELECT dt, user_type, dau,
          MAX(CASE WHEN retention_day = 1 THEN retention_rate END) as day1_retention_rate
   FROM dwd.dwd_sr_user_retention_long_d
   WHERE dt >= DATE_SUB('2026-03-31', INTERVAL 7 DAY)
   GROUP BY dt, user_type, dau
   ORDER BY dt DESC, user_type;

3. 计算各用户类型的7日留存中位数
   SELECT user_type,
          PERCENTILE(retention_rate, 0.5) as median_7day_retention
   FROM dwd.dwd_sr_user_retention_long_d
   WHERE retention_day = 7
   GROUP BY user_type;

注意事项：
1. 数据量：长表结构会使行数增加30倍，但每行数据量小
2. 分区策略：按日期分区，提高查询性能
3. 索引优化：主键(dt, user_type, retention_day)支持常见查询模式
4. 兼容性：BI工具可能需要调整查询方式，但通常更容易处理长表
*/
