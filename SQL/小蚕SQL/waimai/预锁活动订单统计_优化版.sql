-- ============================================================
-- 预锁活动订单统计 — 优化版
-- 优化日期：2026-05-22
-- 用途：FineBI 报表数据源
-- 取数周期：t1/t_order 最近7天；t0 固定历史范围(2026-01-29起)
-- 粒度：store + date（非活动粒度）
-- ============================================================
-- 优化点：
-- 1. t0 移除未使用列(bd_id/store_name/province/city/district/platform_type/rebate_type)
-- 2. t0 WHERE 条件简化（等效变换 + 加上界防止扫未来数据）
-- 3. t1_base 预解析 JSON，只用一次 GET_JSON_OBJECT
-- 4. t_order 去除冗余子查询，直接查表
-- 5. IF → CASE WHEN 统一写法
-- 6. t2_agg 移除未使用的 xc_order_num / pt_order_num
-- 7. t1/t_order 取数周期从固定日期('2025-11-02') → 最近7天
-- ============================================================

WITH

-- 预锁数据
t0 AS (
    SELECT
        DATE(dt)               AS created_at,
        store_id,
        lock_cnt,
        CASE
            WHEN dt < '2026-02-25'
                  OR lock_type = 0 THEN '高报名率锁单'
            ELSE '低报名率锁单'
        END AS suo_type
    FROM dwd.dwd_sr_store_promotion_lock_quota_dt
    WHERE dt >= '2026-01-29'
      AND dt <= CURDATE()
      AND (dt <= '2026-02-24' OR lock_type IS NOT NULL)
),

t1_base AS (
    SELECT
        GET_JSON_OBJECT(promotion_condition, '$.bn') AS bn_val,
        begin_date,
        store_id
    FROM dwd.dwd_sr_store_promotion
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

-- 实际锁（按 store+date 聚合）
t1 AS (
    SELECT
        a.begin_date,
        a.store_id,
        c.province,
        c.city,
        c.district,
        c.store_name,
        CONCAT(c.address, c.address_detail) AS address,
        SUM(CAST(a.bn_val AS BIGINT))       AS lock_cnt
    FROM t1_base a
    JOIN dim.dim_silkworm_store_h c ON a.store_id = c.store_id
    WHERE c.store_brand_type = 1
      AND c.province IN ('上海市', '江苏省', '浙江省')
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

-- 大牌订单
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
        order_status
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
),

t2 AS (
    SELECT
        t1.begin_date,
        t1.store_id,
        t1.store_name,
        COALESCE(t0_agg.lock_cnt, 0)         AS lock_cnt_yu,
        COALESCE(t0_agg.di_lock_cnt, 0)      AS dilock_cnt_yu,
        COALESCE(t1.lock_cnt, 0)             AS lock_cnt_real,
        t1.province,
        t1.city,
        t1.district,
        t1.address,
        COALESCE(t2_agg.valid_order_num, 0)       AS valid_order_num,
        COALESCE(t2_agg.bd_order_num, 0)          AS bd_order_num,
        COALESCE(t2_agg.all_order_baoming_num, 0) AS all_order_baoming_num,
        COALESCE(d.promotion_quota, 0)            AS promotion_quota
    FROM t1
    LEFT JOIN (
        SELECT
            created_at,
            store_id,
            SUM(lock_cnt)                                                    AS lock_cnt,
            SUM(CASE WHEN suo_type = '低报名率锁单' THEN lock_cnt ELSE 0 END) AS di_lock_cnt
        FROM t0
        GROUP BY 1, 2
    ) t0_agg ON t1.store_id = t0_agg.store_id
        AND t1.begin_date = DATE_ADD(t0_agg.created_at, 1)
    LEFT JOIN (
        SELECT
            store_id,
            order_date,
            COUNT(CASE WHEN order_flg = '站内大牌' AND order_status = 2 THEN order_id END) AS bd_order_num,
            COUNT(CASE WHEN order_status = 2 THEN order_id END)                             AS valid_order_num,
            COUNT(order_id)                                                                  AS all_order_baoming_num
        FROM t_order
        GROUP BY 1, 2
    ) t2_agg ON t1.store_id = t2_agg.store_id
        AND t1.begin_date = t2_agg.order_date
    JOIN (
        SELECT
            store_id,
            begin_date AS dt,
            SUM(promotion_quota) AS promotion_quota
        FROM dws.dws_sr_store_takeawaypro_statis_d
        GROUP BY 1, 2
    ) d ON t1.store_id = d.store_id
        AND t1.begin_date = d.dt
)


SELECT
    begin_date,
    store_id,
    address,
    store_name,
    province,
    city,
    district,
    SUM(promotion_quota)      AS promotion_quota,
    SUM(dilock_cnt_yu)        AS dilock_cnt_yu,
    SUM(lock_cnt_yu)          AS lock_cnt_yu,
    SUM(lock_cnt_real)        AS lock_cnt_real,
    SUM(valid_order_num)      AS valid_order_num,
    SUM(bd_order_num)         AS bd_order_num,
    SUM(all_order_baoming_num) AS all_order_baoming_num
FROM t2
GROUP BY 1, 2, 3, 4, 5, 6, 7;


-- ============================================================
-- 原始版本（注释保留）
-- ============================================================
/*
WITH t0 AS
  (SELECT date(dt) AS created_at,
          store_id,
          bd_id,
          store_name,
          province,
          city,
          district,
          store_platform_type AS platform_type,
          rebate_condition_type AS rebate_type,
          lock_cnt,
          CASE
              WHEN dt<'2026-02-25' or(dt>='2026-02-25'
                                      AND lock_type=0) THEN '高报名率锁单'
              ELSE '低报名率锁单'
          END AS suo_type
   FROM dwd.dwd_sr_store_promotion_lock_quota_dt
   WHERE (dt BETWEEN '2026-01-29' AND '2026-02-24')
     OR (dt>='2026-02-25'
         AND lock_type IS NOT NULL)),

t1 AS
  (SELECT begin_date,
          a.store_id,
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
     AND c.province IN ('上海市',
                        '江苏省',
                        '浙江省')
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7),

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
      WHERE dt >'2025-11-01') a),

t2 AS
  (SELECT t1.begin_date,
          t1.store_id,
          t1.store_name,
          coalesce(t0.lock_cnt,0) AS lock_cnt_yu,
          coalesce(t0.di_lock_cnt,0) AS dilock_cnt_yu,
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
     (SELECT created_at,
             store_id,
             SUM(lock_cnt) AS lock_cnt,
             sum(if(suo_type='低报名率锁单',lock_cnt,0)) AS di_lock_cnt
      FROM t0
      GROUP BY 1,
               2)t0 ON t1.store_id=t0.store_id
   AND t1.begin_date=date_add(t0.created_at,1)
   LEFT JOIN
     (SELECT store_id,
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
               2)t2 ON t1.store_id=t2.store_id
   AND t1.begin_date=t2.order_date
   JOIN
     (SELECT store_id,
             begin_date AS dt,
             sum(promotion_quota) AS promotion_quota
      FROM dws.dws_sr_store_takeawaypro_statis_d
      GROUP BY 1,
               2)d ON t1.store_id=d.store_id
   AND t1.begin_date=d.dt)

SELECT begin_date,
       store_id,
       address,
       store_name,
       province,
       city,
       district,
       sum(promotion_quota) AS promotion_quota,
       sum(dilock_cnt_yu) AS dilock_cnt_yu,
       sum(lock_cnt_yu) AS lock_cnt_yu,
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
         7
*/
