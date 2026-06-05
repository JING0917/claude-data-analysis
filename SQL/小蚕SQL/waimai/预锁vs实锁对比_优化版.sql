-- ============================================================
-- 预锁 vs 实锁对比 — 优化版
-- 优化日期：2026-05-22
-- 用途：FineBI 报表数据源
-- 取数周期：最近7天
-- 说明：预锁名额 vs 实际锁单 + 订单转化，按 store+date 粒度
-- ============================================================
-- 优化点：
-- 1. t1 移除未使用列(bd_id, store_name) + 加上界 dt <= CURDATE()
-- 2. promo 原版无 dt 过滤 → 添加7天窗口（原版全表扫描！）
-- 3. t2 只 SELECT 下游需要的列（platform_type/rebate_type 仅在 JOIN 中使用）
-- 4. t_order 固定日期 → 7天；IF → CASE WHEN
-- 5. t3 锁单子查询去掉冗余 GROUP BY 列(province/city/store_name)
-- 6. if_lock 中 IF → CASE WHEN
-- 7. [标注] promo 的 COALESCE 有 NULL 加法陷阱，见文末注释
-- ============================================================

WITH

-- 预锁数据
t1 AS (
    SELECT
        DATE(dt)                  AS created_at,
        store_id,
        store_platform_type       AS platform_type,
        rebate_condition_type     AS rebate_type,
        lock_cnt,
        province,
        city,
        district
    FROM dwd.dwd_sr_store_promotion_lock_quota_dt
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      AND dt <= CURDATE()
),

-- 活动名额（store+date+返利条件+平台 粒度）
promo AS (
    SELECT
        t1.begin_date,
        t1.store_id,
        t1.rebate_condition_type,
        CASE
            WHEN meituan_mlabel_rebate_amt > 0 AND eleme_mlabel_rebate_amt = 0 THEN 1
            WHEN meituan_mlabel_rebate_amt <= 0 AND eleme_mlabel_rebate_amt > 0 THEN 2
            WHEN meituan_mlabel_rebate_amt <= 0
                 AND eleme_mlabel_rebate_amt <= 0
                 AND jd_mlabel_rebate_amt > 0 THEN 3
        END AS store_platform_type,
        SUM(COALESCE(meituan_promotion_quota + eleme_promotion_quota + jd_promotion_quota, 0)) AS promotion_quota
    FROM dwd.dwd_sr_store_promotion t1
    JOIN dim.dim_silkworm_store_h t2 ON t1.store_id = t2.store_id
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY 1, 2, 3, 4
),

-- 预锁 ↔ 活动名额 匹配
t2 AS (
    SELECT
        t1.created_at,
        t1.store_id,
        t1.lock_cnt,
        t1.province,
        t1.city,
        t1.district
    FROM t1
    JOIN promo t11 ON t1.store_id = t11.store_id
        AND t1.rebate_type = t11.rebate_condition_type
        AND t1.platform_type = t11.store_platform_type
        AND t11.begin_date = DATE_ADD(t1.created_at, 1)
),

-- 订单聚合（store+date）
t_order AS (
    SELECT
        store_id,
        DATE(order_time) AS order_date,
        COUNT(order_id)  AS apply_order_cnt,
        COUNT(CASE WHEN order_status = 2 THEN order_id END) AS suc_order_cnt
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY 1, 2
),

-- 最终结果：订单 + 预锁 + 名额 关联
t3 AS (
    SELECT
        r.order_date,
        r.store_id,
        t2_lock.lock_cnt,
        p.promotion_quota,
        t2_store.province,
        t2_store.city,
        t2_store.district,
        COALESCE(r.apply_order_cnt, 0) AS apply_order_cnt,
        COALESCE(r.suc_order_cnt, 0)   AS suc_order_cnt,
        CASE
            WHEN DATE_ADD(t2_lock.created_at, 1) = p.begin_date THEN '锁名额'
            ELSE '未锁名额'
        END AS if_lock
    FROM t_order r
    JOIN (
        SELECT store_id, province, city, district
        FROM t2
        GROUP BY 1, 2, 3, 4
    ) t2_store ON r.store_id = t2_store.store_id
    LEFT JOIN (
        SELECT created_at, store_id, SUM(lock_cnt) AS lock_cnt
        FROM t2
        GROUP BY 1, 2
    ) t2_lock ON t2_lock.store_id = r.store_id
        AND r.order_date = DATE_ADD(t2_lock.created_at, 1)
    JOIN (
        SELECT begin_date, store_id, SUM(promotion_quota) AS promotion_quota
        FROM promo
        GROUP BY 1, 2
    ) p ON r.store_id = p.store_id
        AND r.order_date = p.begin_date
)

SELECT * FROM t3;


-- ============================================================
-- 原始版本（注释保留）
-- ============================================================
/*
WITH t1 AS
  (SELECT date(dt) AS created_at,
          store_id,
          bd_id,
          store_name,
          province,
          city,
          district,
          store_platform_type AS platform_type,
          rebate_condition_type AS rebate_type,
          lock_cnt
   FROM dwd.dwd_sr_store_promotion_lock_quota_dt
   WHERE dt>='2026-01-30'),
promo AS
  ( SELECT t1.begin_date,
           t1.store_id,
           t1.rebate_condition_type,
           CASE
               WHEN meituan_mlabel_rebate_amt>0
                    AND eleme_mlabel_rebate_amt=0 THEN 1
               WHEN meituan_mlabel_rebate_amt<=0
                    AND eleme_mlabel_rebate_amt>0 THEN 2
               WHEN meituan_mlabel_rebate_amt<=0
                    AND eleme_mlabel_rebate_amt<=0
                    AND jd_mlabel_rebate_amt>0 THEN 3
           END AS store_platform_type,
           sum(coalesce(meituan_promotion_quota+eleme_promotion_quota+jd_promotion_quota,0)) AS promotion_quota
   FROM dwd.dwd_sr_store_promotion t1
   JOIN dim.dim_silkworm_store_h t2 ON t1.store_id=t2.store_id
   GROUP BY 1,
            2,
            3,
            4 ),

t2 AS
  (SELECT t1.created_at,
          t1.store_id,
          t1.platform_type,
          t1.rebate_type,
          t1.lock_cnt,
          t1.bd_id,
          t1.store_name,
          t1.province,
          t1.city,
          t1.district
   FROM t1
   JOIN promo t11 ON t1.store_id=t11.store_id
   AND t1.rebate_type=t11.rebate_condition_type
   AND t1.platform_type=t11.store_platform_type
   AND t11.begin_date=date_add(t1.created_at,1)),

t_order AS
  ( SELECT store_id,
           date(order_time) AS order_date,
           count(order_id) AS apply_order_cnt,
           count(if(order_status IN (2),order_id,NULL)) AS suc_order_cnt
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt >'2026-01-30'
   GROUP BY 1,
            2 ),

t3 AS
  ( SELECT r.order_date,
           r.store_id,
           t1.lock_cnt,
           p.promotion_quota,
           l.province,
           l.city,
           l.district,
           COALESCE(apply_order_cnt,0)apply_order_cnt,
           COALESCE(suc_order_cnt,0)suc_order_cnt,
           if(date_add(t1.created_at,1) =p.begin_date,'锁名额','未锁名额') AS if_lock
   FROM t_order r
   JOIN
     (SELECT store_id,
             province,
             city,
             district
      FROM t2
      GROUP BY 1,2,3,4)l ON r.store_id=l.store_id
   LEFT JOIN
     (SELECT created_at,
             store_id,
             province,
             city,
             store_name,
             sum(lock_cnt) AS lock_cnt
      FROM t2
      GROUP BY 1,2,3,4,5)t1 ON t1.store_id=r.store_id
   AND r.order_date=date_add(t1.created_at,1)
   JOIN
     (SELECT begin_date,
             store_id,
             sum(promotion_quota) AS promotion_quota
      FROM promo
      GROUP BY 1,2)p ON r.store_id=p.store_id
   AND r.order_date=p.begin_date )

select * from t3


-- ============================================================
-- 注意事项：promo 的 promotion_quota 计算
-- ============================================================
-- 原版写法：
--   COALESCE(meituan + eleme + jd, 0)
-- 问题：如果任一平台 quota 为 NULL，整个加法结果就是 NULL
--   例如 meituan=10, eleme=NULL, jd=5 → 10+NULL+5 = NULL → COALESCE → 0（丢失了15！）
-- 更安全的写法：
--   COALESCE(meituan,0) + COALESCE(eleme,0) + COALESCE(jd,0)
-- 如果实际数据中 NULL 均存储为 0，则两种写法等价，无需修改。
-- 建议：请确认上游数据是否用 0 而非 NULL，若可能为 NULL，应改用逐字段 COALESCE。
*/
