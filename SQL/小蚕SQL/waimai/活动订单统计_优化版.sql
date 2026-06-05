-- ============================================================
-- 活动订单统计（优化版）
-- 优化日期：2026-05-22
-- 用途：FineBI 报表数据源
-- 取数周期：最近7天
-- ============================================================
-- 优化点：
-- 1. t_order 去除冗余子查询 + 未使用的dt列
-- 2. t1 a.* → 具体列名
-- 3. JSON函数在t1_base只算一次
-- 4. 嵌套IF → CASE WHEN
-- 5. t_order聚合去掉order_date（活动维度1:1，避免行膨胀）
-- 6. 取数周期从固定日期 → 最近7天动态日期
-- ============================================================

WITH
t1_base AS (
    SELECT
        GET_JSON_OBJECT(promotion_condition, '$.bn') AS bn_val,
        store_promotion_id,
        store_id,
        begin_date,
        eleme_promotion_quota,
        meituan_promotion_quota
    FROM dwd.dwd_sr_store_promotion
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

t1 AS (
    SELECT
        CAST(a.bn_val AS BIGINT) AS lock_cnt,
        a.store_promotion_id,
        a.store_id,
        a.begin_date,
        c.province,
        c.city,
        c.district,
        c.store_name,
        CASE
            WHEN a.eleme_promotion_quota > 0  THEN '饿了么'
            WHEN a.meituan_promotion_quota > 0 THEN '美团'
            ELSE '京东'
        END AS store_platform
    FROM t1_base a
    JOIN dim.dim_silkworm_store_h c ON a.store_id = c.store_id
    WHERE a.bn_val > 0
      AND c.province IN ('上海市', '江苏省', '浙江省')
),

t_order AS (
    SELECT
        CASE
            WHEN GET_JSON_OBJECT(platform_order_detail, '$.vip_promotion_card_id') > 0
                 AND order_type <> 14 THEN '站内大牌'
            WHEN order_type = 14 THEN '平台大牌'
            ELSE '普通'
        END AS order_flg,
        store_id,
        order_id,
        store_promotion_id,
        order_status,
        store_platform_type
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

t2 AS (
    SELECT
        t1.begin_date,
        t1.store_id,
        t1.store_promotion_id,
        t1.store_platform,
        t1.store_name,
        t1.lock_cnt,
        t1.province,
        t1.city,
        t1.district,
        COALESCE(t2_agg.bd_order_num, 0)  AS bd_order_num,
        COALESCE(d.promotion_quota, 0)     AS promotion_quota,
        COALESCE(d.valid_order_num, 0)     AS valid_order_num
    FROM t1
    LEFT JOIN (
        SELECT
            store_promotion_id,
            COUNT(IF(order_flg = '站内大牌' AND order_status IN (2, 8), order_id, NULL)) AS bd_order_num,
            COUNT(IF(order_flg = '平台大牌' AND order_status IN (2, 8), order_id, NULL)) AS xc_order_num,
            COUNT(IF(order_flg = '普通'     AND order_status IN (2, 8), order_id, NULL)) AS pt_order_num,
            COUNT(IF(order_status IN (2, 8), order_id, NULL)) AS all_order_num
        FROM t_order
        GROUP BY store_promotion_id
    ) t2_agg ON t1.store_promotion_id = t2_agg.store_promotion_id
    JOIN dws.dws_sr_store_takeawaypro_statis_d d ON t1.store_promotion_id = d.promotion_id
)

SELECT
    begin_date,
    store_id,
    store_promotion_id,
    store_name,
    province,
    city,
    district,
    store_platform,
    SUM(promotion_quota)  AS promotion_quota,
    SUM(lock_cnt)         AS lock_cnt,
    SUM(valid_order_num)  AS valid_order_num,
    SUM(bd_order_num)     AS bd_order_num
FROM t2
GROUP BY begin_date, store_id, store_promotion_id, store_name, province, city, district, store_platform;


-- ============================================================
-- 原始版本（注释保留）
-- ============================================================
/*
WITH t1 AS
  (SELECT (GET_JSON_OBJECT(promotion_condition,'$.bn'))AS lock_cnt,
          a.*,
          c.province,
          c.city,
          c.district,
          c.store_name,
          if(eleme_promotion_quota>0,'饿了么',if(meituan_promotion_quota>0,'美团','京东')) AS store_platform1
   FROM dwd.dwd_sr_store_promotion a
   JOIN dim.dim_silkworm_store_h c ON a.store_id=c.store_id
   WHERE dt>'2025-11-02'
     AND GET_JSON_OBJECT(promotion_condition,'$.bn')>0
     AND c.province IN ('上海市',
                        '江苏省',
                        '浙江省')),

t_order AS
  (SELECT CASE
              WHEN vip_card_id>0
                   AND order_type<>14 THEN '站内大牌'
              WHEN order_type=14 THEN '平台大牌'
              ELSE '普通'
          END AS order_flg,
          order_date,
          store_id,
          order_id,
          store_promotion_id,
          order_status,
          store_platform_type
   FROM
     ( SELECT dt,
              date(order_time) order_date,
                               store_id,
                               store_promotion_id,
                               GET_JSON_OBJECT(platform_order_detail, '$.vip_promotion_card_id') AS vip_card_id,
                               order_id,
                               order_status,
                               order_type,
                               store_platform_type
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt >'2025-11-01'
 )a),

t2 AS
  (SELECT t1.begin_date,
          t1.store_id,
          t1.store_promotion_id,
          t1.store_platform1 AS store_platform,
          t1.store_name,
          t1.lock_cnt,
          t1.province,
          t1.city,
          t1.district,
          coalesce(t2.all_order_num,0) AS all_order_num,
          coalesce(t2.bd_order_num,0) AS bd_order_num,
          COALESCE(d.promotion_quota,0) AS promotion_quota,
          COALESCE(d.valid_order_num,0) AS valid_order_num
   FROM t1
   LEFT JOIN
     (SELECT store_promotion_id,
             order_date,
             count(if(order_flg='站内大牌'
                      AND order_status IN (2,8),order_id,NULL)) AS bd_order_num,
             count(if(order_flg='平台大牌'
                      AND order_status IN (2,8),order_id,NULL)) AS xc_order_num,
             count(if(order_flg='普通'
                      AND order_status IN (2,8),order_id,NULL)) AS pt_order_num,
             count(if(order_status IN (2,8),order_id,NULL)) AS all_order_num
      FROM t_order
      GROUP BY 1,
               2)t2 ON t1.store_promotion_id=t2.store_promotion_id
   JOIN dws.dws_sr_store_takeawaypro_statis_d d ON t1.store_promotion_id=d.promotion_id)


SELECT begin_date,
       store_id,
       store_promotion_id,
       store_name,
       province,
       city,
       district,
       store_platform,
       sum(promotion_quota) AS promotion_quota,
       sum(lock_cnt) AS lock_cnt,
       -- sum(all_order_num) as all_order_num,
       sum(valid_order_num) AS valid_order_num,
       sum(bd_order_num) AS bd_order_num
FROM t2
GROUP BY 1,
         2,
         3,
         4,
         5,
         6,
         7,
         8
*/
