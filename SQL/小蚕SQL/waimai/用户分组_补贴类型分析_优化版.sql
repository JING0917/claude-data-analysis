-- ============================================================
-- 用户分组补贴类型分析 — 优化版
-- 优化日期：2026-05-22
-- 用途：FineBI 报表数据源
-- 取数周期：最近7天
-- 用户群：group_id=1614
-- 说明：按日期统计平台补贴(小蚕) vs 站内补贴(商家)的订单与返利
-- ============================================================
-- 优化点：
-- 1. 冗余子查询去掉 → CTE 扁平化（原版外层套了无意义的 SELECT * FROM (SELECT ...) a）
-- 2. 移除未使用列（auto_id/platform_order_detail/store_platform_type/store_promotion_id/order_status/dt）
-- 3. IF → CASE WHEN
-- 4. 取数周期从固定日期('2025-11-26') → 最近7天
-- 5. 用户群去重 GROUP BY 1 → DISTINCT
-- ============================================================

WITH
t_base AS (
    SELECT
        DATE(a.order_time) AS order_date,
        a.user_id,
        a.order_id,
        GET_JSON_OBJECT(a.platform_order_detail, '$.vip_promotion_card_id') AS vip_card_id,
        a.real_rebate_amt,
        a.order_type
    FROM dwd.dwd_sr_order_promotion_order a
    JOIN (
        SELECT DISTINCT user_id
        FROM dws.dws_user_group
        WHERE group_id = 1614
    ) b ON a.user_id = b.user_id
    WHERE a.order_status IN (2, 8)
      AND a.dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
)

SELECT
    order_date,

    -- 汇总（平台补贴 + 站内补贴）
    COUNT(DISTINCT CASE WHEN order_type = 14 OR (vip_card_id > 0 AND order_type <> 14) THEN user_id END)  AS `总用户量`,
    COUNT(DISTINCT CASE WHEN order_type = 14 OR (vip_card_id > 0 AND order_type <> 14) THEN order_id END) AS `总完单量`,
    SUM(CASE WHEN order_type = 14 OR (vip_card_id > 0 AND order_type <> 14) THEN real_rebate_amt ELSE 0 END) AS `总返利金`,

    -- 平台补贴（小蚕侧：order_type=14）
    COUNT(DISTINCT CASE WHEN order_type = 14 THEN user_id END)  AS `平台补贴用户量`,
    COUNT(DISTINCT CASE WHEN order_type = 14 THEN order_id END) AS `平台补贴完单量`,
    SUM(CASE WHEN order_type = 14 THEN real_rebate_amt ELSE 0 END) AS `平台补贴订单总返利金`,

    -- 商家侧（站内补贴：vip_card_id>0 且非平台单）
    COUNT(DISTINCT CASE WHEN vip_card_id > 0 AND order_type <> 14 THEN user_id END)  AS `站内补贴用户量`,
    COUNT(DISTINCT CASE WHEN vip_card_id > 0 AND order_type <> 14 THEN order_id END) AS `站内补贴完单量`,
    SUM(CASE WHEN vip_card_id > 0 AND order_type <> 14 THEN real_rebate_amt ELSE 0 END) AS `站内补贴订单总返利金`
FROM t_base
GROUP BY 1;


-- ============================================================
-- 原始版本（注释保留）
-- ============================================================
/*
select
order_date,
-- 汇总
count(distinct if(order_type=14 or (vip_card_id>0 and order_type<>14),user_id,null)) as `总用户量`,
count(distinct if(order_type=14 or (vip_card_id>0 and order_type<>14),order_id,null)) as `总完单量`,
sum(if(order_type=14 or (vip_card_id>0 and order_type<>14),real_rebate_amt,0)) as `总返利金`,
-- 小蚕侧
count(distinct if(order_type=14,user_id,null)) as `平台补贴用户量`,
count(distinct if(order_type=14,order_id,null)) as `平台补贴完单量`,
sum(if(order_type=14,real_rebate_amt,0)) as `平台补贴订单总返利金`,

-- 商家侧
count(distinct if(vip_card_id>0 and order_type<>14,user_id,null)) as `站内补贴用户量`,
count(distinct if(vip_card_id>0 and order_type<>14,order_id,null)) as `站内补贴完单量`,
sum(if(vip_card_id>0 and order_type<>14,real_rebate_amt,0)) as `站内补贴订单总返利金`
from(
select
dt,
a.user_id,
order_id,
date(order_time) as order_date,
auto_id,
platform_order_detail,
GET_JSON_OBJECT(platform_order_detail,'$.vip_promotion_card_id') as vip_card_id,
real_rebate_amt,
order_type,
store_platform_type,
store_promotion_id,
order_status
from dwd.dwd_sr_order_promotion_order a
join (select user_id from dws.dws_user_group where group_id=1614  group by 1)b on a.user_id=b.user_id
where order_status in (2,8)
and dt >= '2025-11-26'
)a
group by 1
*/
