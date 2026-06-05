-- ============================================================
-- 活动订单统计（含报名订单数）- 优化版
-- 优化日期：2026-05-22
-- 用途：FineBI 报表数据源
-- 取数周期：最近7天
-- ============================================================
-- 优化点：
-- 1. t1_base 预解析 JSON (promotion_condition)，避免重复调用 GET_JSON_OBJECT
-- 2. t_order 去除冗余子查询，直接查表 + CASE WHEN
-- 3. IF → CASE WHEN 统一写法
-- 4. t2_agg 移除未使用的 xc_order_num / pt_order_num（减少中间结果集）
-- 5. 取数周期从固定日期('2025-11-02') → 最近7天动态日期
-- ============================================================

WITH
t1_base AS (
    SELECT
        GET_JSON_OBJECT(promotion_condition, '$.bn') AS bn_val,
        begin_date,
        store_id,
        store_promotion_id
    FROM dwd.dwd_sr_store_promotion
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

t1 AS (
    SELECT
        a.begin_date,
        a.store_id,
        a.store_promotion_id,
        c.province,
        c.city,
        c.district,
        c.store_name,
        CONCAT(c.address, c.address_detail) AS address,
        SUM(CAST(a.bn_val AS BIGINT)) AS lock_cnt
    FROM t1_base a
    JOIN dim.dim_silkworm_store_h c ON a.store_id = c.store_id
    WHERE a.bn_val > 0
      AND c.store_brand_type = 1
      AND c.province IN ('上海市', '江苏省', '浙江省')
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

t_order AS (
    SELECT
        CASE
            WHEN GET_JSON_OBJECT(platform_order_detail, '$.vip_promotion_card_id') > 0
                 AND order_type <> 14 THEN '站内大牌'
            WHEN order_type = 14 THEN '平台大牌'
            ELSE '普通'
        END AS order_flg,
        DATE(order_time) AS order_date,
        store_id,
        order_id,
        store_promotion_id,
        order_status
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

t2 AS (
    SELECT
        t1.begin_date,
        t1.store_id,
        t1.store_promotion_id,
        t1.store_name,
        COALESCE(t1.lock_cnt, 0)                    AS lock_cnt_real,
        t1.province,
        t1.city,
        t1.district,
        t1.address,
        COALESCE(t2_agg.valid_order_num, 0)         AS valid_order_num,
        COALESCE(t2_agg.bd_order_num, 0)            AS bd_order_num,
        COALESCE(t2_agg.all_order_baoming_num, 0)   AS all_order_baoming_num,
        COALESCE(d.promotion_quota, 0)              AS promotion_quota
    FROM t1
    LEFT JOIN (
        SELECT
            store_id,
            store_promotion_id,
            order_date,
            COUNT(CASE WHEN order_flg = '站内大牌' AND order_status = 2 THEN order_id END) AS bd_order_num,
            COUNT(CASE WHEN order_status = 2 THEN order_id END)                             AS valid_order_num,
            COUNT(order_id)                                                                  AS all_order_baoming_num
        FROM t_order
        GROUP BY 1, 2, 3
    ) t2_agg ON t1.store_id = t2_agg.store_id
        AND t1.begin_date = t2_agg.order_date
        AND t1.store_promotion_id = t2_agg.store_promotion_id
    JOIN (
        SELECT
            store_id,
            promotion_id,
            begin_date AS dt,
            SUM(promotion_quota) AS promotion_quota
        FROM dws.dws_sr_store_takeawaypro_statis_d
        GROUP BY 1, 2, 3
    ) d ON t1.store_id = d.store_id
        AND t1.begin_date = d.dt
        AND d.promotion_id = t1.store_promotion_id
)


SELECT
    begin_date,
    store_id,
    address,
    store_promotion_id,
    store_name,
    province,
    city,
    district,
    SUM(promotion_quota)        AS promotion_quota,
    SUM(lock_cnt_real)          AS lock_cnt_real,
    SUM(valid_order_num)        AS valid_order_num,
    SUM(bd_order_num)           AS bd_order_num,
    SUM(all_order_baoming_num)  AS all_order_baoming_num
FROM t2
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;


-- ============================================================
-- 原始版本（注释保留）
-- ============================================================
/*
WITH t1 AS
  (SELECT begin_date,
          a.store_id,
          a.store_promotion_id,
          c.province,
          c.city,
          c.district,
          c.store_name,
          CONCAT(c.address,c.address_detail) AS address,
          sum(GET_JSON_OBJECT(promotion_condition,'$.bn'))AS lock_cnt
FROM dwd.dwd_sr_store_promotion a
   JOIN dim.dim_silkworm_store_h c ON a.store_id=c.store_id
   AND c.store_brand_type=1
   WHERE dt>'2025-11-02'
     AND GET_JSON_OBJECT(promotion_condition,'$.bn')>0
     AND c.province IN ('上海市',
                        '江苏省',
                        '浙江省')
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8),

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
 ) a),

t2 AS
  (SELECT t1.begin_date,
          t1.store_id,
          t1.store_promotion_id,
          t1.store_name,
          coalesce(t1.lock_cnt,0) AS lock_cnt_real,
          t1.province,
          t1.city,
          t1.district,
          t1.address,
          coalesce(t2.all_order_num,0) AS valid_order_num,
          coalesce(t2.bd_order_num,0) AS bd_order_num,
          COALESCE(d.promotion_quota,0) AS promotion_quota,
          COALESCE(all_order_baoming_num,0) AS all_order_baoming_num
   FROM t1
LEFT JOIN
     (SELECT store_id,
             store_promotion_id,
             order_date,
             count(if(order_flg='站内大牌'
                      AND order_status IN (2),order_id,NULL)) AS bd_order_num,
             count(if(order_flg='平台大牌'
                      AND order_status IN (2),order_id,NULL)) AS xc_order_num,
             count(if(order_flg='普通'
                      AND order_status IN (2),order_id,NULL)) AS pt_order_num,
             count(if(order_status IN (2),order_id,NULL)) AS all_order_num,
             count(order_id) AS all_order_baoming_num
      FROM t_order
      GROUP BY 1,
               2,
               3) t2 ON t1.store_id=t2.store_id
   AND t1.begin_date=t2.order_date
   AND t1.store_promotion_id=t2.store_promotion_id
   JOIN
     (SELECT store_id,
             promotion_id,
             begin_date AS dt,
             sum(promotion_quota) AS promotion_quota
      FROM dws.dws_sr_store_takeawaypro_statis_d
      GROUP BY 1,
               2,
               3) d ON t1.store_id=d.store_id
   AND t1.begin_date=d.dt
   AND d.promotion_id=t1.store_promotion_id)


SELECT begin_date,
       store_id,
       address,
       store_promotion_id,
       store_name,
       province,
       city,
       district,
       sum(promotion_quota) AS promotion_quota,
       sum(lock_cnt_real) AS lock_cnt_real,
       sum(valid_order_num) AS valid_order_num,
       sum(bd_order_num) AS bd_order_num,
       sum(all_order_baoming_num) AS all_order_baoming_num
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
