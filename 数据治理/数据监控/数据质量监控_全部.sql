-- ============================================================
-- 数据质量监控 — 实体表方案（StarRocks 定时调度 + 帆软BI查询）
-- 创建日期：2026-05-26
-- 更新日期：2026-05-26 — 合并同表扫描，优化CPU/IO消耗
-- 监控表：dim.dim_silkworm_user / dwd.dwd_sr_store_promotion / dwd.dwd_sr_order_promotion_order
-- 共18项监控，P0/P1/P2 三级告警
--
-- 方案说明：
--   ① 创建实体表 dwd.dwd_data_quality_monitor（只需执行一次）
--   ② 每天凌晨调度 INSERT SQL，写入昨日的监控结果（约 24 行/天）
--   ③ 帆软BI数据集直接查实体表：SELECT * FROM dwd.dwd_data_quality_monitor WHERE dt = CURDATE() - 1
--
-- 性能优化（v2）：
--   将24个独立UNION ALL（每表扫描12次）合并为13个分支，关键收益：
--   · Order 1-day: 5次扫描 → 1次（昨日分区90万行只扫1遍）
--   · Activity 1-day: 6次扫描 → 1次（昨日分区20万行只扫1遍）
--   · User 30-day: 2次扫描 → 1次
--   · User 1-day: 2次扫描 → 1次（监控4c+15合并）
--   预计整体CPU/IO降至原来的 1/3 ~ 1/2
-- ============================================================


-- ============================================================
-- 第一步：创建监控实体表（只执行一次）
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd.dwd_data_quality_monitor (
    `dt`              date         NOT NULL COMMENT '监控日期（检查的数据日期）',
    `监控类别`        varchar(32)  NOT NULL COMMENT '数据量监控/完整性/唯一性/时效性/一致性/有效性/业务逻辑/汇总校验',
    `监控项`          varchar(64)  NOT NULL COMMENT '具体检查项名称',
    `表名`            varchar(128) NOT NULL COMMENT '被监控的表',
    `优先级`          varchar(8)   NOT NULL COMMENT 'P0/P1/P2',
    `指标值`          varchar(64)  NULL     COMMENT '核心指标值',
    `阈值说明`        varchar(128) NULL     COMMENT '告警阈值规则描述',
    `告警级别`        varchar(32)  NULL     COMMENT '正常/P1-危险/P2-严重/P2-需排查',
    `详情`            varchar(65533) NULL   COMMENT '补充明细信息'
) ENGINE=OLAP
PRIMARY KEY (`dt`, `监控类别`, `监控项`, `表名`)
COMMENT '数据质量监控结果表'
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(`dt`) BUCKETS 4
PROPERTIES (
    'replication_num' = '3',
    'partition_live_number' = '90'
);


-- ============================================================
-- 第二步：每日 INSERT（StarRocks 定时调度，建议每天 07:00 执行）
--   ★ v2优化：按表+时间范围合并扫描，CROSS JOIN VALUES 拆成多行
-- ============================================================
INSERT INTO dwd.dwd_data_quality_monitor
(
    dt, 监控类别, 监控项, 表名, 优先级, 指标值, 阈值说明, 告警级别, 详情
)

-- ============================================================
-- 监控1a：日增量环比波动 — 用户表 (P0)
--   扫描：dim_user 近14天
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS dt,
    '数据量监控',
    '日增量环比波动-新增用户数',
    'dim.dim_silkworm_user',
    'P0',
    CAST(t.new_user_cnt AS VARCHAR),
    '日环比>±30%→P1, >±15%→P2',
    CASE
        WHEN t.new_user_cnt = 0 THEN 'P1-数据缺失'
        WHEN ABS(t.dod_pct) > 30 THEN 'P1-危险'
        WHEN ABS(t.dod_pct) > 15 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('昨日新增:', t.new_user_cnt, '; 前日:', CAST(t.prev_cnt AS VARCHAR),
           '; 日环比:', CAST(t.dod_pct AS VARCHAR), '%; 7天前:', CAST(t.wow_cnt AS VARCHAR),
           '; 周同比:', CAST(t.wow_pct AS VARCHAR), '%')
FROM (
    SELECT new_user_cnt, register_date,
        CAST(LAG(new_user_cnt, 1) OVER (ORDER BY register_date) AS VARCHAR) AS prev_cnt,
        CAST(LAG(new_user_cnt, 7) OVER (ORDER BY register_date) AS VARCHAR) AS wow_cnt,
        ROUND((new_user_cnt / NULLIF(LAG(new_user_cnt, 1) OVER (ORDER BY register_date), 0) - 1) * 100, 2) AS dod_pct,
        ROUND((new_user_cnt / NULLIF(LAG(new_user_cnt, 7) OVER (ORDER BY register_date), 0) - 1) * 100, 2) AS wow_pct
    FROM (
        SELECT substr(register_time, 1, 10) AS register_date,
            COUNT(DISTINCT user_id) AS new_user_cnt
        FROM dim.dim_silkworm_user
        WHERE substr(register_time, 1, 10) >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
        GROUP BY 1
    ) raw
) t
WHERE t.register_date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)

UNION ALL

-- ============================================================
-- 监控1b：日增量环比波动 — 活动表 (P0)
--   扫描：activity 近14天
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '数据量监控',
    '日增量环比波动-新增活动量',
    'dwd.dwd_sr_store_promotion',
    'P0',
    CAST(t.promotion_cnt AS VARCHAR),
    '日环比>±30%→P1, >±15%→P2',
    CASE
        WHEN t.promotion_cnt = 0 THEN 'P1-数据缺失'
        WHEN ABS(t.dod_pct) > 30 THEN 'P1-危险'
        WHEN ABS(t.dod_pct) > 15 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('昨日新增活动:', t.promotion_cnt, '; 前日:', CAST(t.prev_cnt AS VARCHAR),
           '; 日环比:', CAST(t.dod_pct AS VARCHAR), '%; 7天前:', CAST(t.wow_cnt AS VARCHAR),
           '; 周同比:', CAST(t.wow_pct AS VARCHAR), '%')
FROM (
    SELECT promotion_cnt, dt,
        CAST(LAG(promotion_cnt, 1) OVER (ORDER BY dt) AS VARCHAR) AS prev_cnt,
        CAST(LAG(promotion_cnt, 7) OVER (ORDER BY dt) AS VARCHAR) AS wow_cnt,
        ROUND((promotion_cnt / NULLIF(LAG(promotion_cnt, 1) OVER (ORDER BY dt), 0) - 1) * 100, 2) AS dod_pct,
        ROUND((promotion_cnt / NULLIF(LAG(promotion_cnt, 7) OVER (ORDER BY dt), 0) - 1) * 100, 2) AS wow_pct
    FROM (
        SELECT dt, COUNT(DISTINCT store_promotion_id) AS promotion_cnt
        FROM dwd.dwd_sr_store_promotion
        WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
        GROUP BY dt
    ) raw
) t
WHERE t.dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)

UNION ALL

-- ============================================================
-- 监控1c：日增量环比波动 — 订单表 (P0)
--   扫描：order 近14天
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '数据量监控',
    '日增量环比波动-订单量',
    'dwd.dwd_sr_order_promotion_order',
    'P0',
    CAST(t.order_cnt AS VARCHAR),
    '日环比>±30%→P1, >±15%→P2',
    CASE
        WHEN t.order_cnt = 0 THEN 'P1-数据缺失'
        WHEN ABS(t.dod_pct) > 30 THEN 'P1-危险'
        WHEN ABS(t.dod_pct) > 15 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('昨日订单:', t.order_cnt, '; 有效:', t.valid_order_cnt, '; 取消:', t.cancel_order_cnt,
           '; 有效率:', CAST(t.valid_rate AS VARCHAR), '%; 日环比:', CAST(t.dod_pct AS VARCHAR), '%')
FROM (
    SELECT order_cnt, valid_order_cnt, cancel_order_cnt, dt,
        ROUND(valid_order_cnt / NULLIF(order_cnt, 0) * 100, 2) AS valid_rate,
        ROUND((order_cnt / NULLIF(LAG(order_cnt, 1) OVER (ORDER BY dt), 0) - 1) * 100, 2) AS dod_pct
    FROM (
        SELECT dt,
            COUNT(1) AS order_cnt,
            COUNT(DISTINCT CASE WHEN order_status IN (2, 8) THEN order_id END) AS valid_order_cnt,
            COUNT(DISTINCT CASE WHEN order_status IN (4, 5) THEN order_id END) AS cancel_order_cnt
        FROM dwd.dwd_sr_order_promotion_order
        WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
        GROUP BY dt
    ) raw
) t
WHERE t.dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)

UNION ALL

-- ============================================================
-- ★ 合并扫描1：User 30-day → 监控2a(字段空值率) + 监控10(注册时间异常)
--   原2次独立扫描 → 现1次扫描，CROSS JOIN 拆成2行
--   扫描量：~90万行（3万/天 × 30天）
-- ============================================================
WITH user_30d AS (
    SELECT
        COUNT(1) AS total_cnt,
        SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
        SUM(CASE WHEN register_time IS NULL THEN 1 ELSE 0 END) AS null_register_time,
        SUM(CASE WHEN phone IS NULL OR phone = '' THEN 1 ELSE 0 END) AS null_phone,
        SUM(CASE WHEN city_id IS NULL THEN 1 ELSE 0 END) AS null_city_id,
        SUM(CASE WHEN county_id IS NULL THEN 1 ELSE 0 END) AS null_county_id,
        SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
        SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS null_status,
        SUM(CASE WHEN is_logoff IS NULL THEN 1 ELSE 0 END) AS null_is_logoff,
        SUM(CASE WHEN register_time > NOW() THEN 1 ELSE 0 END) AS future_reg,
        SUM(CASE WHEN register_time < '2020-01-01' THEN 1 ELSE 0 END) AS early_reg,
        SUM(CASE WHEN register_time IS NULL THEN 1 ELSE 0 END) AS empty_reg  -- same as null_register_time
    FROM dim.dim_silkworm_user
    WHERE substr(register_time, 1, 10) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
)
SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS dt,
    t.`监控类别`,
    t.`监控项`,
    t.`表名`,
    t.`优先级`,
    -- 指标值
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN CAST(ROUND(GREATEST(
            m.null_user_id, m.null_register_time, m.null_phone,
            m.null_city_id, m.null_county_id, m.null_gender,
            m.null_status, m.null_is_logoff
        ) / m.total_cnt * 100, 4) AS VARCHAR)
        WHEN '注册时间异常值' THEN CAST(m.future_reg + m.early_reg + m.empty_reg AS VARCHAR)
    END AS `指标值`,
    -- 阈值说明
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN '主键/核心字段空值→P1; 维度字段>5%→P2'
        WHEN '注册时间异常值' THEN '异常数>0→P2'
    END AS `阈值说明`,
    -- 告警级别
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN
            CASE WHEN m.null_user_id > 0 OR m.null_register_time > 0 THEN 'P1-危险'
                 WHEN (m.null_city_id + m.null_county_id) / m.total_cnt > 0.05 THEN 'P2-严重'
                 ELSE '正常' END
        WHEN '注册时间异常值' THEN
            CASE WHEN m.future_reg > 0 OR m.early_reg > 0 THEN 'P2-严重' ELSE '正常' END
    END AS `告警级别`,
    -- 详情
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN CONCAT(
            '(近30天) user_id:', CAST(ROUND(m.null_user_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'register_time:', CAST(ROUND(m.null_register_time/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'phone:', CAST(ROUND(m.null_phone/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'city_id:', CAST(ROUND(m.null_city_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'county_id:', CAST(ROUND(m.null_county_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'gender:', CAST(ROUND(m.null_gender/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'status:', CAST(ROUND(m.null_status/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'is_logoff:', CAST(ROUND(m.null_is_logoff/m.total_cnt*100,4) AS VARCHAR), '%')
        WHEN '注册时间异常值' THEN CONCAT(
            '(近30天) 总用户:', CAST(m.total_cnt AS VARCHAR),
            '; 未来时间:', CAST(m.future_reg AS VARCHAR),
            '; 极早时间(<2020):', CAST(m.early_reg AS VARCHAR),
            '; 注册时间为空:', CAST(m.empty_reg AS VARCHAR))
    END AS `详情`
FROM user_30d m
CROSS JOIN (
    VALUES
    ('完整性',   '字段空值率检查', 'dim.dim_silkworm_user', 'P0'),
    ('有效性',   '注册时间异常值', 'dim.dim_silkworm_user', 'P2')
) t(`监控类别`, `监控项`, `表名`, `优先级`)

UNION ALL

-- ============================================================
-- 监控3a：主键唯一性 — 用户表 (P0)
--   注意：必须全表扫描（用户表无dt分区），无法合并
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '唯一性',
    '主键重复检查',
    'dim.dim_silkworm_user',
    'P0',
    CAST(COUNT(1) - COUNT(DISTINCT user_id) AS VARCHAR),
    '重复数>0→P1',
    CASE
        WHEN COUNT(1) != COUNT(DISTINCT user_id) THEN 'P1-危险'
        ELSE '正常'
    END,
    CONCAT('总记录:', CAST(COUNT(1) AS VARCHAR), '; 唯一user_id:', CAST(COUNT(DISTINCT user_id) AS VARCHAR))
FROM dim.dim_silkworm_user

UNION ALL

-- ============================================================
-- ★ 合并扫描2：Activity 1-day → 监控2b + 3b + 4a + 8 + 11 + 12
--   原6次独立扫描 → 现1次扫描昨日分区，CROSS JOIN 拆成6行
--   扫描量：~20万行（1天分区）
-- ============================================================
WITH activity_1d AS (
    SELECT
        COUNT(1) AS total_cnt,
        COUNT(DISTINCT store_promotion_id) AS unique_pk_cnt,
        -- 空值计数 (监控2b)
        SUM(CASE WHEN store_promotion_id IS NULL THEN 1 ELSE 0 END) AS null_store_promotion_id,
        SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS null_store_id,
        SUM(CASE WHEN merchant_id IS NULL THEN 1 ELSE 0 END) AS null_merchant_id,
        SUM(CASE WHEN begin_date IS NULL OR begin_date = '' THEN 1 ELSE 0 END) AS null_begin_date,
        SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS null_status,
        SUM(CASE WHEN city_id IS NULL THEN 1 ELSE 0 END) AS null_city_id,
        SUM(CASE WHEN county_id IS NULL THEN 1 ELSE 0 END) AS null_county_id,
        SUM(CASE WHEN bd_id IS NULL THEN 1 ELSE 0 END) AS null_bd_id,
        -- 状态分布 (监控8)
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS status_0,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS status_1,
        SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) AS status_2,
        SUM(CASE WHEN status = 3 THEN 1 ELSE 0 END) AS status_3,
        SUM(CASE WHEN status = 4 THEN 1 ELSE 0 END) AS status_4,
        SUM(CASE WHEN status = 5 THEN 1 ELSE 0 END) AS status_5,
        -- 配额超限 (监控11, 只看status=1)
        SUM(CASE WHEN status = 1 AND meituan_finished_num > meituan_promotion_quota AND meituan_promotion_quota > 0 THEN 1 ELSE 0 END) AS mt_over_quota,
        SUM(CASE WHEN status = 1 AND eleme_finished_num > eleme_promotion_quota AND eleme_promotion_quota > 0 THEN 1 ELSE 0 END) AS elm_over_quota,
        SUM(CASE WHEN status = 1 AND jd_finished_num > jd_promotion_quota AND jd_promotion_quota > 0 THEN 1 ELSE 0 END) AS jd_over_quota,
        -- 日期逻辑错误 (监控12)
        SUM(CASE WHEN end_date < begin_date THEN 1 ELSE 0 END) AS date_reverse,
        SUM(CASE WHEN begin_date IS NULL OR end_date IS NULL THEN 1 ELSE 0 END) AS date_null
    FROM dwd.dwd_sr_store_promotion
    WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
)
SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS dt,
    t.`监控类别`,
    t.`监控项`,
    t.`表名`,
    t.`优先级`,
    -- 指标值
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN CAST(ROUND(GREATEST(
            m.null_store_promotion_id, m.null_store_id, m.null_merchant_id,
            m.null_begin_date, m.null_status, m.null_city_id,
            m.null_county_id, m.null_bd_id
        ) / m.total_cnt * 100, 4) AS VARCHAR)
        WHEN '主键重复检查' THEN CAST(m.total_cnt - m.unique_pk_cnt AS VARCHAR)
        WHEN '分区数据延迟检测' THEN CAST(m.total_cnt AS VARCHAR)
        WHEN '活动状态分布' THEN CAST(m.total_cnt AS VARCHAR)
        WHEN '配额完成率超100%' THEN CAST(m.mt_over_quota + m.elm_over_quota + m.jd_over_quota AS VARCHAR)
        WHEN '活动日期逻辑错误' THEN CAST(m.date_reverse AS VARCHAR)
    END AS `指标值`,
    -- 阈值说明
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN '主键/核心字段空值→P1; 维度字段>5%→P2'
        WHEN '主键重复检查' THEN '重复数>0→P1'
        WHEN '分区数据延迟检测' THEN '数据量=0→P1; <100→P2'
        WHEN '活动状态分布' THEN '驳回/拉黑占比突增需关注'
        WHEN '配额完成率超100%' THEN '任一平台超配额>0→P2'
        WHEN '活动日期逻辑错误' THEN '日期倒挂>0→P2'
    END AS `阈值说明`,
    -- 告警级别
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN
            CASE WHEN m.null_store_promotion_id > 0 OR m.null_store_id > 0 THEN 'P1-危险'
                 WHEN (m.null_city_id + m.null_county_id) / m.total_cnt > 0.05 THEN 'P2-严重'
                 ELSE '正常' END
        WHEN '主键重复检查' THEN
            CASE WHEN m.total_cnt != m.unique_pk_cnt THEN 'P1-危险' ELSE '正常' END
        WHEN '分区数据延迟检测' THEN
            CASE WHEN m.total_cnt = 0 THEN 'P1-数据缺失'
                 WHEN m.total_cnt < 100 THEN 'P2-数据偏少'
                 ELSE '正常' END
        WHEN '活动状态分布' THEN '正常'
        WHEN '配额完成率超100%' THEN
            CASE WHEN m.mt_over_quota > 0 OR m.elm_over_quota > 0 THEN 'P2-严重' ELSE '正常' END
        WHEN '活动日期逻辑错误' THEN
            CASE WHEN m.date_reverse > 0 THEN 'P2-严重' ELSE '正常' END
    END AS `告警级别`,
    -- 详情
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN CONCAT(
            'store_promotion_id:', CAST(ROUND(m.null_store_promotion_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'store_id:', CAST(ROUND(m.null_store_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'merchant_id:', CAST(ROUND(m.null_merchant_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'begin_date:', CAST(ROUND(m.null_begin_date/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'status:', CAST(ROUND(m.null_status/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'city_id:', CAST(ROUND(m.null_city_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'county_id:', CAST(ROUND(m.null_county_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'bd_id:', CAST(ROUND(m.null_bd_id/m.total_cnt*100,4) AS VARCHAR), '%')
        WHEN '主键重复检查' THEN CONCAT('总记录:', CAST(m.total_cnt AS VARCHAR),
            '; 唯一store_promotion_id:', CAST(m.unique_pk_cnt AS VARCHAR))
        WHEN '分区数据延迟检测' THEN CONCAT('昨日分区:',
            CAST(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS VARCHAR),
            '; 数据量:', CAST(m.total_cnt AS VARCHAR))
        WHEN '活动状态分布' THEN CONCAT(
            'status=0(待审核):', CAST(m.status_0 AS VARCHAR),
            '; 1(已审核):', CAST(m.status_1 AS VARCHAR),
            '; 2(驳回):', CAST(m.status_2 AS VARCHAR),
            '; 3(拉黑):', CAST(m.status_3 AS VARCHAR),
            '; 4(商家结束):', CAST(m.status_4 AS VARCHAR),
            '; 5(最终结束):', CAST(m.status_5 AS VARCHAR))
        WHEN '配额完成率超100%' THEN CONCAT(
            '美团超配额:', CAST(m.mt_over_quota AS VARCHAR),
            '; 饿了么:', CAST(m.elm_over_quota AS VARCHAR),
            '; 京东:', CAST(m.jd_over_quota AS VARCHAR))
        WHEN '活动日期逻辑错误' THEN CONCAT(
            '新增活动:', CAST(m.total_cnt AS VARCHAR),
            '; 日期倒挂:', CAST(m.date_reverse AS VARCHAR),
            '; 日期为空:', CAST(m.date_null AS VARCHAR))
    END AS `详情`
FROM activity_1d m
CROSS JOIN (
    VALUES
    ('完整性',   '字段空值率检查',     'dwd.dwd_sr_store_promotion', 'P0'),
    ('唯一性',   '主键重复检查',       'dwd.dwd_sr_store_promotion', 'P0'),
    ('时效性',   '分区数据延迟检测',   'dwd.dwd_sr_store_promotion', 'P0'),
    ('有效性',   '活动状态分布',       'dwd.dwd_sr_store_promotion', 'P1'),
    ('业务逻辑', '配额完成率超100%',   'dwd.dwd_sr_store_promotion', 'P1'),
    ('业务逻辑', '活动日期逻辑错误',   'dwd.dwd_sr_store_promotion', 'P1')
) t(`监控类别`, `监控项`, `表名`, `优先级`)

UNION ALL

-- ============================================================
-- ★ 合并扫描3：Order 1-day → 监控2c + 3c + 4b + 9 + 13
--   原5次独立扫描 → 现1次扫描昨日分区，CROSS JOIN 拆成5行
--   扫描量：~90万行（1天分区），最大收益项
-- ============================================================
WITH order_1d AS (
    SELECT
        COUNT(1) AS total_cnt,
        COUNT(DISTINCT auto_id, dt) AS unique_pk_cnt,
        -- 空值计数 (监控2c)
        SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS null_order_id,
        SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
        SUM(CASE WHEN store_promotion_id IS NULL THEN 1 ELSE 0 END) AS null_store_promotion_id,
        SUM(CASE WHEN user_pay_amt IS NULL THEN 1 ELSE 0 END) AS null_user_pay_amt,
        SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_order_status,
        SUM(CASE WHEN city_id IS NULL THEN 1 ELSE 0 END) AS null_city_id,
        SUM(CASE WHEN county_id IS NULL THEN 1 ELSE 0 END) AS null_county_id,
        SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS null_store_id,
        SUM(CASE WHEN merchant_id IS NULL THEN 1 ELSE 0 END) AS null_merchant_id,
        SUM(CASE WHEN order_type IS NULL THEN 1 ELSE 0 END) AS null_order_type,
        -- 有效订单 & 金额异常 (监控9, 仅有效订单 status IN (2,8))
        COUNT(CASE WHEN order_status IN (2, 8) THEN 1 END) AS valid_order_cnt,
        SUM(CASE WHEN order_status IN (2, 8) AND user_pay_amt <= 0 THEN 1 ELSE 0 END) AS non_positive_amt,
        SUM(CASE WHEN order_status IN (2, 8) AND user_pay_amt > 5000 THEN 1 ELSE 0 END) AS super_large_amt,
        -- 时间逻辑错误 (监控13)
        SUM(CASE WHEN order_audit_finish_time < order_submit_audit_time
                  AND order_audit_finish_time IS NOT NULL AND order_audit_finish_time <> ''
                  AND order_submit_audit_time IS NOT NULL AND order_submit_audit_time <> '' THEN 1 ELSE 0 END) AS audit_time_err,
        SUM(CASE WHEN auth_order_finish_time < order_time
                  AND auth_order_finish_time IS NOT NULL AND auth_order_finish_time <> ''
                  AND order_time IS NOT NULL AND order_time <> '' THEN 1 ELSE 0 END) AS auth_time_err
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
)
SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS dt,
    t.`监控类别`,
    t.`监控项`,
    t.`表名`,
    t.`优先级`,
    -- 指标值
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN CAST(ROUND(GREATEST(
            m.null_order_id, m.null_user_id, m.null_store_promotion_id,
            m.null_user_pay_amt, m.null_order_status, m.null_city_id,
            m.null_county_id, m.null_store_id, m.null_merchant_id, m.null_order_type
        ) / m.total_cnt * 100, 4) AS VARCHAR)
        WHEN '主键重复检查' THEN CAST(m.total_cnt - m.unique_pk_cnt AS VARCHAR)
        WHEN '分区数据延迟检测' THEN CAST(m.total_cnt AS VARCHAR)
        WHEN '支付金额异常值' THEN
            CAST(ROUND(m.non_positive_amt / NULLIF(m.valid_order_cnt, 0) * 100, 4) AS VARCHAR)
        WHEN '订单时间逻辑错误' THEN CAST(m.audit_time_err + m.auth_time_err AS VARCHAR)
    END AS `指标值`,
    -- 阈值说明
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN '主键/核心字段空值→P1; 维度字段>5%→P2'
        WHEN '主键重复检查' THEN '重复数>0→P1'
        WHEN '分区数据延迟检测' THEN '数据量=0→P1; <1000→P2'
        WHEN '支付金额异常值' THEN '非正金额占比>1%→P2; 超大额(>5000)>10→关注'
        WHEN '订单时间逻辑错误' THEN '时间倒挂>0→P2'
    END AS `阈值说明`,
    -- 告警级别
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN
            CASE WHEN m.null_order_id > 0 OR m.null_user_id > 0 THEN 'P1-危险'
                 WHEN (m.null_city_id + m.null_county_id + m.null_store_id) / m.total_cnt > 0.05 THEN 'P2-严重'
                 ELSE '正常' END
        WHEN '主键重复检查' THEN
            CASE WHEN m.total_cnt != m.unique_pk_cnt THEN 'P1-危险' ELSE '正常' END
        WHEN '分区数据延迟检测' THEN
            CASE WHEN m.total_cnt = 0 THEN 'P1-数据缺失'
                 WHEN m.total_cnt < 1000 THEN 'P2-数据偏少'
                 ELSE '正常' END
        WHEN '支付金额异常值' THEN
            CASE WHEN m.non_positive_amt / NULLIF(m.valid_order_cnt, 0) > 0.01 THEN 'P2-严重'
                 ELSE '正常' END
        WHEN '订单时间逻辑错误' THEN
            CASE WHEN m.audit_time_err > 0 OR m.auth_time_err > 0 THEN 'P2-严重'
                 ELSE '正常' END
    END AS `告警级别`,
    -- 详情
    CASE t.`监控项`
        WHEN '字段空值率检查' THEN CONCAT(
            'order_id:', CAST(ROUND(m.null_order_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'user_id:', CAST(ROUND(m.null_user_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'store_promotion_id:', CAST(ROUND(m.null_store_promotion_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'user_pay_amt:', CAST(ROUND(m.null_user_pay_amt/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'order_status:', CAST(ROUND(m.null_order_status/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'city_id:', CAST(ROUND(m.null_city_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'county_id:', CAST(ROUND(m.null_county_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'store_id:', CAST(ROUND(m.null_store_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'merchant_id:', CAST(ROUND(m.null_merchant_id/m.total_cnt*100,4) AS VARCHAR), '%; ',
            'order_type:', CAST(ROUND(m.null_order_type/m.total_cnt*100,4) AS VARCHAR), '%')
        WHEN '主键重复检查' THEN CONCAT('总记录:', CAST(m.total_cnt AS VARCHAR),
            '; 唯一(auto_id,dt):', CAST(m.unique_pk_cnt AS VARCHAR))
        WHEN '分区数据延迟检测' THEN CONCAT('昨日分区:',
            CAST(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS VARCHAR),
            '; 数据量:', CAST(m.total_cnt AS VARCHAR))
        WHEN '支付金额异常值' THEN CONCAT(
            '有效订单:', CAST(m.valid_order_cnt AS VARCHAR),
            '; 非正金额:', CAST(m.non_positive_amt AS VARCHAR),
            '; 超大额(>5000):', CAST(m.super_large_amt AS VARCHAR))
        WHEN '订单时间逻辑错误' THEN CONCAT(
            '审核早于提交:', CAST(m.audit_time_err AS VARCHAR),
            '; 完成早于下单:', CAST(m.auth_time_err AS VARCHAR))
    END AS `详情`
FROM order_1d m
CROSS JOIN (
    VALUES
    ('完整性',   '字段空值率检查',     'dwd.dwd_sr_order_promotion_order', 'P0'),
    ('唯一性',   '主键重复检查',       'dwd.dwd_sr_order_promotion_order', 'P0'),
    ('时效性',   '分区数据延迟检测',   'dwd.dwd_sr_order_promotion_order', 'P0'),
    ('有效性',   '支付金额异常值',     'dwd.dwd_sr_order_promotion_order', 'P2'),
    ('业务逻辑', '订单时间逻辑错误',   'dwd.dwd_sr_order_promotion_order', 'P2')
) t(`监控类别`, `监控项`, `表名`, `优先级`)

UNION ALL

-- ============================================================
-- ★ 合并扫描4：User 1-day + 监控15 → 监控4c(昨日注册) + 监控15(用户量交叉)
--   原2次user扫描 → 现1次user扫描 + 1次order扫描，CROSS JOIN 拆成2行
-- ============================================================
WITH user_reg AS (
    SELECT COUNT(DISTINCT user_id) AS new_user_cnt
    FROM dim.dim_silkworm_user
    WHERE substr(register_time, 1, 10) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
),
order_users AS (
    SELECT COUNT(DISTINCT user_id) AS order_user_cnt
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
)
SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS dt,
    t.`监控类别`,
    t.`监控项`,
    t.`表名`,
    t.`优先级`,
    -- 指标值
    CASE t.`监控项`
        WHEN '分区数据延迟检测' THEN CAST(COALESCE(u.new_user_cnt, 0) AS VARCHAR)
        WHEN '用户量交叉校验' THEN CAST(COALESCE(o.order_user_cnt, 0) - u.new_user_cnt AS VARCHAR)
    END AS `指标值`,
    -- 阈值说明
    CASE t.`监控项`
        WHEN '分区数据延迟检测' THEN '昨日新注册=0→P2'
        WHEN '用户量交叉校验' THEN '差异>新增用户10%→P2'
    END AS `阈值说明`,
    -- 告警级别
    CASE t.`监控项`
        WHEN '分区数据延迟检测' THEN
            CASE WHEN COALESCE(u.new_user_cnt, 0) = 0 THEN 'P2-数据偏少' ELSE '正常' END
        WHEN '用户量交叉校验' THEN
            CASE WHEN COALESCE(o.order_user_cnt, 0) - u.new_user_cnt > u.new_user_cnt * 0.1
                THEN 'P2-请关注' ELSE '正常' END
    END AS `告警级别`,
    -- 详情
    CASE t.`监控项`
        WHEN '分区数据延迟检测' THEN
            CONCAT('昨日新注册用户数:', CAST(COALESCE(u.new_user_cnt, 0) AS VARCHAR))
        WHEN '用户量交叉校验' THEN
            CONCAT('用户表新增:', CAST(u.new_user_cnt AS VARCHAR),
                   '; 订单表下单用户:', CAST(COALESCE(o.order_user_cnt, 0) AS VARCHAR))
    END AS `详情`
FROM user_reg u
CROSS JOIN order_users o
CROSS JOIN (
    VALUES
    ('时效性',   '分区数据延迟检测', 'dim.dim_silkworm_user', 'P0'),
    ('汇总校验', '用户量交叉校验',   '用户表↔订单表',         'P1')
) t(`监控类别`, `监控项`, `表名`, `优先级`)

UNION ALL

-- ============================================================
-- 监控5：用户ID关联校验 — 订单表↔用户表 (P1)
--   扫描：order昨日 DISTINCT user_id + LEFT JOIN user（点查）
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '一致性',
    '用户ID关联校验',
    '订单表↔用户表',
    'P1',
    CAST(ROUND(
        (COUNT(DISTINCT o.user_id) - COUNT(DISTINCT u.user_id)) / NULLIF(COUNT(DISTINCT o.user_id), 0) * 100, 4
    ) AS VARCHAR),
    '无映射率>1%→P1; >0→P2',
    CASE
        WHEN (COUNT(DISTINCT o.user_id) - COUNT(DISTINCT u.user_id)) / NULLIF(COUNT(DISTINCT o.user_id), 0) > 0.01 THEN 'P1-危险'
        WHEN (COUNT(DISTINCT o.user_id) - COUNT(DISTINCT u.user_id)) > 0 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('订单用户数:', CAST(COUNT(DISTINCT o.user_id) AS VARCHAR),
           '; 有映射:', CAST(COUNT(DISTINCT u.user_id) AS VARCHAR),
           '; 无映射:', CAST(COUNT(DISTINCT o.user_id) - COUNT(DISTINCT u.user_id) AS VARCHAR))
FROM (
    SELECT DISTINCT user_id
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
) o
LEFT JOIN dim.dim_silkworm_user u ON o.user_id = u.user_id

UNION ALL

-- ============================================================
-- 监控6：活动ID关联校验 — 订单表↔活动表 (P1)
--   扫描：order昨日 DISTINCT store_promotion_id + LEFT JOIN activity（点查）
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '一致性',
    '活动ID关联校验',
    '订单表↔活动表',
    'P1',
    CAST(COUNT(DISTINCT o.store_promotion_id) - COUNT(DISTINCT p.store_promotion_id) AS VARCHAR),
    '无效关联>0→P2',
    CASE
        WHEN COUNT(DISTINCT o.store_promotion_id) - COUNT(DISTINCT p.store_promotion_id) > 0 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('订单关联活动数:', CAST(COUNT(DISTINCT o.store_promotion_id) AS VARCHAR),
           '; 有效活动:', CAST(COUNT(DISTINCT p.store_promotion_id) AS VARCHAR))
FROM (
    SELECT DISTINCT store_promotion_id
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      AND store_promotion_id <> 0
) o
LEFT JOIN dwd.dwd_sr_store_promotion p ON o.store_promotion_id = p.store_promotion_id

UNION ALL

-- ============================================================
-- 监控7：订单状态分布 — 取消率周同比变化 (P1)
--   扫描：order 昨天 + 7天前，2个特定分区
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '有效性',
    '订单状态分布-取消率',
    'dwd.dwd_sr_order_promotion_order',
    'P1',
    CAST(t.cancel_rate AS VARCHAR),
    '取消率周同比上升>5百分点→P2',
    CASE
        WHEN t.cancel_rate - t.cancel_rate_7d > 5 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('昨日取消率:', CAST(t.cancel_rate AS VARCHAR), '%; 7天前取消率:', CAST(t.cancel_rate_7d AS VARCHAR),
           '%; 变化:', CAST(ROUND(t.cancel_rate - t.cancel_rate_7d, 2) AS VARCHAR), '百分点')
FROM (
    SELECT
        MAX(CASE WHEN dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN cancel_rate END) AS cancel_rate,
        MAX(CASE WHEN dt = DATE_SUB(CURRENT_DATE(), INTERVAL 8 DAY) THEN cancel_rate END) AS cancel_rate_7d
    FROM (
        SELECT dt,
            ROUND(SUM(CASE WHEN order_status IN (4, 5) THEN 1 ELSE 0 END) / COUNT(1) * 100, 2) AS cancel_rate
        FROM dwd.dwd_sr_order_promotion_order
        WHERE dt IN (DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), DATE_SUB(CURRENT_DATE(), INTERVAL 8 DAY))
        GROUP BY dt
    ) raw
) t

UNION ALL

-- ============================================================
-- 监控14：注销用户订单异常 (P2)
--   扫描：order昨日 + INNER JOIN user (is_logoff=1)
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '业务逻辑',
    '注销用户订单异常',
    '订单表↔用户表',
    'P2',
    CAST(COUNT(DISTINCT o.order_id) AS VARCHAR),
    '异常订单>0→P2',
    CASE
        WHEN COUNT(DISTINCT o.order_id) > 0 THEN 'P2-严重'
        ELSE '正常'
    END,
    CONCAT('异常订单数:', CAST(COUNT(DISTINCT o.order_id) AS VARCHAR),
           '; 异常用户数:', CAST(COUNT(DISTINCT o.user_id) AS VARCHAR))
FROM dwd.dwd_sr_order_promotion_order o
INNER JOIN dim.dim_silkworm_user u ON o.user_id = u.user_id
WHERE o.dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  AND u.is_logoff = 1
  AND o.order_status IN (2, 8)

UNION ALL

-- ============================================================
-- 监控16：活动表与订单表订单量交叉校验 (P1)
--   扫描：activity 近7天 + order 近3天 + LEFT JOIN
-- ============================================================
SELECT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    '汇总校验',
    '活动订单量交叉校验',
    '活动表↔订单表',
    'P1',
    CAST(COUNT(DISTINCT CASE WHEN ABS(p.meituan_finished_num - COALESCE(o.meituan_order_cnt, 0)) > 5
        THEN p.store_promotion_id END) AS VARCHAR),
    '差异>5单的活动数>0→P2',
    CASE
        WHEN COUNT(DISTINCT CASE WHEN ABS(p.meituan_finished_num - COALESCE(o.meituan_order_cnt, 0)) > 5
            THEN p.store_promotion_id END) > 0 THEN 'P2-需排查'
        ELSE '正常'
    END,
    CONCAT('差异>5单的活动数:', CAST(COUNT(DISTINCT CASE WHEN ABS(p.meituan_finished_num - COALESCE(o.meituan_order_cnt, 0)) > 5
        THEN p.store_promotion_id END) AS VARCHAR),
           '; 最大差异:', CAST(MAX(ABS(p.meituan_finished_num - COALESCE(o.meituan_order_cnt, 0))) AS VARCHAR))
FROM dwd.dwd_sr_store_promotion p
LEFT JOIN (
    SELECT store_promotion_id, COUNT(DISTINCT order_id) AS meituan_order_cnt
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
      AND order_status IN (2, 8)
    GROUP BY store_promotion_id
) o ON p.store_promotion_id = o.store_promotion_id
WHERE p.status = 1
  AND p.meituan_finished_num > 0
  AND p.dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);


-- ============================================================
-- 第三步：帆软BI数据集（极简查询）
-- ============================================================
-- 方式A：只查昨日监控结果
SELECT *
FROM dwd.dwd_data_quality_monitor
WHERE dt = CURDATE() - 1
ORDER BY 优先级, 监控类别, 监控项;

-- 方式B：查近7天告警趋势（折线图用）
SELECT dt, 监控类别, 监控项, 告警级别, COUNT(1) AS `告警次数`
FROM dwd.dwd_data_quality_monitor
WHERE dt >= CURDATE() - 7
  AND 告警级别 != '正常'
GROUP BY dt, 监控类别, 监控项, 告警级别
ORDER BY dt DESC;

-- 方式C：今日监控总览（卡片图用）
SELECT
    SUM(CASE WHEN 告警级别 = 'P1-危险' THEN 1 ELSE 0 END) AS `P1告警数`,
    SUM(CASE WHEN 告警级别 LIKE 'P2%' THEN 1 ELSE 0 END) AS `P2告警数`,
    SUM(CASE WHEN 告警级别 = '正常' THEN 1 ELSE 0 END) AS `正常数`
FROM dwd.dwd_data_quality_monitor
WHERE dt = CURDATE() - 1;
