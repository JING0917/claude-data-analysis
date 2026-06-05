-- 区县业务监控：贡献大切指标环比±5%告警
-- 监控逻辑：只监控昨日数据，计算贡献度（占全国比例）>5%且环比在±5%之间的数据
-- 适用于帆软BI告警配置
-- 执行频率：每日凌晨1点 (CRON: 0 1 * * *)

WITH
-- 1. 基础数据：区县级指标（包含前日用于环比）
county_data AS (
    SELECT
        dt,
        city_name,
        county_name,
        COUNT(1) AS pro_num,
        SUM(promotion_quota) AS quota,
        SUM(order_num) AS order_num,
        SUM(cancel_order_num) AS cancel_order_num,
        SUM(valid_order_num) AS valid_order_num
    FROM dws.dws_sr_store_takeawaypro_statis_d
    WHERE dt IN (
        DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY),  -- 前日（用于环比计算）
        DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)   -- 昨日（监控目标）
    )
    GROUP BY 1, 2, 3
),

-- 2. 全国总量：用于计算贡献度
national_totals AS (
    SELECT
        dt,
        SUM(pro_num) AS national_pro_num,
        SUM(quota) AS national_quota,
        SUM(order_num) AS national_order_num,
        SUM(cancel_order_num) AS national_cancel_order_num,
        SUM(valid_order_num) AS national_valid_order_num
    FROM county_data
    GROUP BY dt
),

-- 3. 计算环比和贡献度
with_calculations AS (
    SELECT
        cd.dt,
        cd.city_name,
        cd.county_name,
        -- 指标值（NULL处理为0）
        IFNULL(cd.pro_num, 0) AS pro_num,
        IFNULL(cd.quota, 0) AS quota,
        IFNULL(cd.order_num, 0) AS order_num,
        IFNULL(cd.cancel_order_num, 0) AS cancel_order_num,
        IFNULL(cd.valid_order_num, 0) AS valid_order_num,

        -- 前日指标（用于环比计算）
        IFNULL(LAG(cd.pro_num) OVER (PARTITION BY cd.city_name, cd.county_name ORDER BY cd.dt), 0) AS lastd_pro_num,
        IFNULL(LAG(cd.quota) OVER (PARTITION BY cd.city_name, cd.county_name ORDER BY cd.dt), 0) AS lastd_quota,
        IFNULL(LAG(cd.order_num) OVER (PARTITION BY cd.city_name, cd.county_name ORDER BY cd.dt), 0) AS lastd_order_num,
        IFNULL(LAG(cd.cancel_order_num) OVER (PARTITION BY cd.city_name, cd.county_name ORDER BY cd.dt), 0) AS lastd_cancel_order_num,
        IFNULL(LAG(cd.valid_order_num) OVER (PARTITION BY cd.city_name, cd.county_name ORDER BY cd.dt), 0) AS lastd_valid_order_num,

        -- 贡献度（占全国比例）
        IFNULL(cd.pro_num, 0) / NULLIF(nt.national_pro_num, 0) AS pro_num_contribution,
        IFNULL(cd.quota, 0) / NULLIF(nt.national_quota, 0) AS quota_contribution,
        IFNULL(cd.order_num, 0) / NULLIF(nt.national_order_num, 0) AS order_num_contribution,
        IFNULL(cd.cancel_order_num, 0) / NULLIF(nt.national_cancel_order_num, 0) AS cancel_order_num_contribution,
        IFNULL(cd.valid_order_num, 0) / NULLIF(nt.national_valid_order_num, 0) AS valid_order_num_contribution
    FROM county_data cd
    LEFT JOIN national_totals nt ON cd.dt = nt.dt
)

-- 4. 最终输出：仅昨日数据，贡献度>5%且环比在±5%之间
SELECT
    dt AS `统计日期`,
    city_name AS `城市`,
    county_name AS `区县`,

    -- 昨日指标
    pro_num AS `昨日活动量`,
    quota AS `昨日活动名额`,
    order_num AS `昨日下单量`,
    cancel_order_num AS `昨日取消订单量`,
    valid_order_num AS `昨日有效订单量`,

    -- 前日指标（用于参考）
    lastd_pro_num AS `前日活动量`,
    lastd_quota AS `前日活动名额`,
    lastd_order_num AS `前日下单量`,
    lastd_cancel_order_num AS `前日取消订单量`,
    lastd_valid_order_num AS `前日有效订单量`,

    -- 环比计算（NULL/0值已处理）
    IF(lastd_pro_num = 0, 0, pro_num / lastd_pro_num - 1) AS `活动量环比`,
    IF(lastd_quota = 0, 0, quota / lastd_quota - 1) AS `活动名额环比`,
    IF(lastd_order_num = 0, 0, order_num / lastd_order_num - 1) AS `下单量环比`,
    IF(lastd_cancel_order_num = 0, 0, cancel_order_num / lastd_cancel_order_num - 1) AS `取消订量环比`,
    IF(lastd_valid_order_num = 0, 0, valid_order_num / lastd_valid_order_num - 1) AS `有效订单量环比`,

    -- 贡献度（占全国比例）
    pro_num_contribution AS `活动量贡献度`,
    quota_contribution AS `活动名额贡献度`,
    order_num_contribution AS `下单量贡献度`,
    cancel_order_num_contribution AS `取消订单量贡献度`,
    valid_order_num_contribution AS `有效订单量贡献度`,

    -- 告警信息
    '需监控' AS `告警级别`,
    CONCAT_WS('、',
        IF(pro_num_contribution > 0.05 AND ABS(IF(lastd_pro_num = 0, 0, pro_num / lastd_pro_num - 1)) <= 0.05, '活动量', NULL),
        IF(quota_contribution > 0.05 AND ABS(IF(lastd_quota = 0, 0, quota / lastd_quota - 1)) <= 0.05, '活动名额', NULL),
        IF(order_num_contribution > 0.05 AND ABS(IF(lastd_order_num = 0, 0, order_num / lastd_order_num - 1)) <= 0.05, '下单量', NULL),
        IF(cancel_order_num_contribution > 0.05 AND ABS(IF(lastd_cancel_order_num = 0, 0, cancel_order_num / lastd_cancel_order_num - 1)) <= 0.05, '取消订单量', NULL),
        IF(valid_order_num_contribution > 0.05 AND ABS(IF(lastd_valid_order_num = 0, 0, valid_order_num / lastd_valid_order_num - 1)) <= 0.05, '有效订单量', NULL)
    ) AS `触发告警指标`
FROM with_calculations
WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)  -- 只监控昨日
  -- 告警条件：贡献度>5% AND 环比在±5%之间
  AND (
      (pro_num_contribution > 0.05 AND ABS(IF(lastd_pro_num = 0, 0, pro_num / lastd_pro_num - 1)) <= 0.05) OR
      (quota_contribution > 0.05 AND ABS(IF(lastd_quota = 0, 0, quota / lastd_quota - 1)) <= 0.05) OR
      (order_num_contribution > 0.05 AND ABS(IF(lastd_order_num = 0, 0, order_num / lastd_order_num - 1)) <= 0.05) OR
      (cancel_order_num_contribution > 0.05 AND ABS(IF(lastd_cancel_order_num = 0, 0, cancel_order_num / lastd_cancel_order_num - 1)) <= 0.05) OR
      (valid_order_num_contribution > 0.05 AND ABS(IF(lastd_valid_order_num = 0, 0, valid_order_num / lastd_valid_order_num - 1)) <= 0.05)
  )
ORDER BY city_name, county_name;

-- ============================================================
-- 参数配置说明：
-- 1. 贡献度阈值：当前设为5%（> 0.05），可根据业务重要性调整
-- 2. 环比阈值：当前设为±5%（ABS() <= 0.05），可根据监控灵敏度调整
-- 3. 监控指标：活动量、活动名额、下单量、取消订单量、有效订单量
-- 4. 时间范围：只监控昨日数据，使用前日数据计算环比
--
-- 帆软BI告警配置建议：
-- 1. 数据源：每日凌晨1点执行 (CRON: 0 1 * * *)
-- 2. 告警规则：当贡献度>5%且环比在±5%之间时触发告警
-- 3. 告警信息："[城市-区县] [指标] 贡献度[XX%]，环比波动[±X%]"
-- 4. 告警级别：当前输出均为"需监控"级别
-- 5. 触发指标：列出具体触发告警的指标名称
-- ============================================================