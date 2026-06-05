-- ============================================================
-- 大牌券发放与转化分析 — 优化版
-- 优化日期：2026-05-22
-- 用途：FineBI 报表数据源
-- 取数周期：最近7天
-- 券类型：card_type IN (3, 13)
-- ============================================================
-- 优化点：
-- 1. t1 移除未使用列(card_type/card_status/used_date)：3列
-- 2. t2 移除未使用列(dt/order_date/platform_order_detail/store_platform_type/
--    store_promotion_id/user_id)：6列 → 列数减半
-- 3. t4 移除未使用列(auto_id/card_type/key_id/card_status/used_date/
--    promotion_order_id/brand_coupon_id)：输出从17列 → 10列
-- 4. IF → CASE WHEN 统一写法
-- 5. 取数周期从固定日期('2026-01-05') → 最近7天
-- ============================================================

WITH

-- 权益卡发放
t1 AS (
    SELECT
        auto_id,
        key_id,
        a.user_id,
        province,
        card_id,
        DATE(create_time) AS create_date
    FROM dwd.dwd_sr_market_rights_card a
    LEFT JOIN (
        SELECT user_id, province
        FROM dim.dim_silkworm_user_location
    ) b ON a.user_id = b.user_id
    WHERE create_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      AND card_type IN (3, 13)
),

-- 订单明细
t2 AS (
    SELECT
        auto_id,
        order_id,
        GET_JSON_OBJECT(platform_order_detail, '$.vip_promotion_card_id') AS vip_card_id,
        real_rebate_amt,
        order_type,
        order_status,
        profit
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

-- 公司承担大牌订单
t3 AS (
    SELECT
        promotion_order_id,
        brand_coupon_id,
        silk_id
    FROM ods.ods_sr_top_brand_order_realtime
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

-- 券 → 订单 关联（两条链路：品牌券 + 卡券key）
t4 AS (
    SELECT
        t1.card_id,
        t1.province,
        t1.create_date,
        t1.user_id,
        COALESCE(a.order_id, b.order_id)               AS order_id,
        COALESCE(a.order_type, b.order_type)           AS order_type,
        COALESCE(a.vip_card_id, b.vip_card_id)         AS vip_card_id,
        COALESCE(a.order_status, b.order_status)       AS order_status,
        COALESCE(a.real_rebate_amt, b.real_rebate_amt) AS real_rebate_amt,
        COALESCE(a.profit, b.profit)                   AS profit
    FROM t1
    LEFT JOIN t3 ON t1.auto_id = t3.brand_coupon_id
        AND t1.user_id = t3.silk_id
    LEFT JOIN t2 a ON t3.promotion_order_id = a.auto_id
    LEFT JOIN t2 b ON t1.key_id = b.auto_id
        AND LENGTH(b.order_id) > 0
)


SELECT
    card_id,
    province,
    create_date,

    -- 汇总
    COUNT(*)                                                                                       AS fa_ct,
    COUNT(order_id)                                                                                AS order_ct,
    COUNT(DISTINCT CASE WHEN order_status IN (2, 8) THEN order_id END)                             AS order_suc_ct,
    SUM(CASE WHEN (order_type = 14 OR (vip_card_id > 0 AND order_type <> 14))
                  AND order_status IN (2, 8) THEN real_rebate_amt ELSE 0 END)                      AS all_real_rebate_amt,

    -- 平台补贴（小蚕侧）
    COUNT(DISTINCT CASE WHEN order_type = 14 THEN user_id END)                                     AS xc_ut,
    COUNT(DISTINCT CASE WHEN order_type = 14 THEN order_id END)                                    AS xc_ot,
    COUNT(DISTINCT CASE WHEN order_type = 14 AND order_status IN (2, 8) THEN order_id END)        AS xc_sucot,
    SUM(CASE WHEN order_type = 14 AND order_status IN (2, 8) THEN real_rebate_amt ELSE 0 END)     AS xc_real_rebate_amt,

    -- 商家侧（站内补贴）
    COUNT(DISTINCT CASE WHEN vip_card_id > 0 AND order_type <> 14 THEN user_id END)               AS bd_ut,
    COUNT(DISTINCT CASE WHEN vip_card_id > 0 AND order_type <> 14 THEN order_id END)              AS bd_ot,
    COUNT(DISTINCT CASE WHEN vip_card_id > 0 AND order_status IN (2, 8)
                             AND order_type <> 14 THEN order_id END)                               AS bd_suc_ot,
    SUM(CASE WHEN vip_card_id > 0 AND order_type <> 14
                  AND order_status IN (2, 8) THEN real_rebate_amt ELSE 0 END)                      AS bd_real_rebate_amt,
    SUM(CASE WHEN vip_card_id > 0 AND order_type <> 14
                  AND order_status = 2 THEN profit ELSE 0 END)                                     AS profit
FROM t4
GROUP BY 1, 2, 3;


-- ============================================================
-- 原始版本（注释保留）
-- ============================================================
/*
WITH t1 AS
  (SELECT auto_id,
          card_type,
          key_id,
          a.user_id,
          province,
          card_id,
          card_status,
          date(create_time) AS create_date,
          date_format(used_time, '%Y-%m-%d') used_date
   FROM dwd.dwd_sr_market_rights_card a
   LEFT JOIN
     (SELECT user_id,
             province
      FROM dim.dim_silkworm_user_location) b ON a.user_id=b.user_id
   WHERE create_time >= '2026-01-05'
AND card_type IN (3,
                  13)),

t2 AS
  (SELECT dt,
          user_id,
          order_id,
          date(order_time) AS order_date,
          auto_id,
          platform_order_detail,
          GET_JSON_OBJECT(platform_order_detail, '$.vip_promotion_card_id') AS vip_card_id,
          real_rebate_amt,
          order_type,
          store_platform_type,
          store_promotion_id,
          order_status,
          profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt >= '2026-01-05' ),

t3 AS
  (SELECT promotion_order_id,
          brand_coupon_id,
          silk_id
   FROM ods.ods_sr_top_brand_order_realtime
   WHERE `created_at` >= '2026-01-05') ,

t4 AS
  (SELECT t1.auto_id,
          t1.card_type,
          t1.key_id,
          t1.user_id,
          t1.province,
          t1.card_id,
          t1.card_status,
          t1.create_date,
          t1.used_date,
          t3.promotion_order_id,
          t3.brand_coupon_id,
          COALESCE(a.real_rebate_amt,b.real_rebate_amt) AS real_rebate_amt,
          COALESCE(a.order_type,b.order_type) AS order_type,
          COALESCE(a.vip_card_id,b.vip_card_id) AS vip_card_id,
          COALESCE(a.order_status,b.order_status) AS order_status,
          COALESCE(a.order_id,b.order_id) AS order_id,
          coalesce(a.profit,b.profit) AS profit
   FROM t1
   LEFT JOIN t3 ON t1.auto_id=t3.brand_coupon_id
   AND t1.user_id=t3.silk_id
   LEFT JOIN t2 a ON t3.promotion_order_id=a.auto_id
   LEFT JOIN t2 b ON t1.key_id=b.auto_id
   AND length(b.order_id)>0)


SELECT t4.card_id,
       province,
       t4.create_date,

       count(*) AS fa_ct,
       count(order_id) AS order_ct,
       count(DISTINCT if(order_status IN (2,8),order_id,NULL)) AS order_suc_ct,
       sum(if((order_type=14
               OR (vip_card_id>0
                   AND order_type<>14))
              AND order_status IN (2,8) ,real_rebate_amt,0)) AS all_real_rebate_amt,

       count(DISTINCT if(order_type=14,user_id,NULL)) AS xc_ut,
       count(DISTINCT if(order_type=14,order_id,NULL)) AS xc_ot,
       count(DISTINCT if(order_type=14
                         AND order_status IN (2,8),order_id,NULL)) AS xc_sucot,
       sum(if(order_type=14
              AND order_status IN (2,8) ,real_rebate_amt,0)) AS xc_real_rebate_amt,

       count(DISTINCT if(vip_card_id>0
                         AND order_type<>14,user_id,NULL)) AS bd_ut,
       count(DISTINCT if(vip_card_id>0
                         AND order_type<>14,order_id,NULL)) AS bd_ot,
       count(DISTINCT if(vip_card_id>0
                         AND order_status IN (2,8)
                         AND order_type<>14,order_id,NULL)) AS bd_suc_ot,
       sum(if(vip_card_id>0
              AND order_type<>14
              AND order_status IN (2,8),real_rebate_amt,0)) AS bd_real_rebate_amt,
       sum(if(vip_card_id>0
              AND order_type<>14
              AND order_status=2,profit,0)) AS profit
FROM t4
GROUP BY 1,
         2,
         3
*/
