-- 统计商家待支付活动
WITH t1 AS
  (SELECT bd_id,
          store_promotion_id,
          store_id,
          merchant_id
   FROM dwd.dwd_sr_store_promotion
   WHERE status IN (1,
                    4,
                    5)
     AND end_date>=date_sub(current_date(),interval 3 DAY)
     AND pay_status=2),

-- 解析商家账单
t2 AS
  (SELECT bd_id,
          CAST(get_json_string(parse_json(content), '$.SilkId') AS INT) AS uid,
          parse_json(get_json_string(parse_json(content), '$.StoreIds')) AS store_ids,
          parse_json(get_json_string(parse_json(content), '$.PromotionIds')) AS promotion_ids
   FROM dwd.dwd_sr_store_merchant_bill_push
   WHERE push_date = date_format(current_date(), '%Y-%m-%d')
     AND is_reminder = 0
     AND push_status = 2),

-- 裂变推送账单
t3 AS
  (SELECT bd_id,
           uid,
           CAST(sid.value AS INT) AS store_id,
           CAST(pid.value AS INT) AS promotion_id
   FROM t2,
        LATERAL json_each(t2.store_ids) sid,
                                        LATERAL json_each(t2.promotion_ids) pid),
-- 统计推送账单
t4 AS
  (SELECT bd_id,
          count(DISTINCT promotion_id) push_pro_num,
                                       count(DISTINCT store_id) push_store_num,
                                                                count(DISTINCT uid) push_merchant_num
   FROM t3
   GROUP BY 1),

-- 统计近3日待支付活动账单推送
t5 AS
  (SELECT bd_id,
          count(DISTINCT t1.store_promotion_id) latest3d_pro_num,
          count(DISTINCT t1.store_id) latest3d_store_num,
          count(DISTINCT t1.merchant_id) latest3d_merchant_num,
          count(DISTINCT if(b.promotion_id IS NOT NULL,t1.store_promotion_id,NULL)) latest3d_push_pro_num,
          count(DISTINCT if(b.promotion_id IS NOT NULL,t1.store_id,NULL)) latest3d_push_store_num,
          count(DISTINCT if(b.promotion_id IS NOT NULL,t1.merchant_id,NULL)) latest3d_push_merchant_num
   FROM t1
   LEFT JOIN
(SELECT promotion_id
 FROM t3
 GROUP BY 1) b ON t1.store_promotion_id=b.promotion_id
   GROUP BY 1),


-- 聚合
 t6 AS
  (SELECT bd_id,
          sum(latest3d_pro_num) latest3d_pro_num,
          sum(latest3d_store_num) latest3d_store_num,
          sum(latest3d_merchant_num) latest3d_merchant_num,
          sum(latest3d_push_pro_num) latest3d_push_pro_num,
          sum(latest3d_push_store_num) latest3d_push_store_num,
          sum(latest3d_push_merchant_num) latest3d_push_merchant_num,
          SUM(push_pro_num) push_pro_num,
          SUM(push_store_num) push_store_num,
          SUM(push_merchant_num) push_merchant_num
   FROM
     (SELECT bd_id,
             latest3d_pro_num,
             latest3d_store_num,
             latest3d_merchant_num,
             latest3d_push_pro_num,
             latest3d_push_store_num,
             latest3d_push_merchant_num,
             0 AS push_pro_num,
             0 AS push_store_num,
             0 AS push_merchant_num
      FROM t5
      UNION ALL SELECT bd_id,
                       0 AS latest3d_pro_num,
                       0 AS latest3d_store_num,
                       0 AS latest3d_merchant_num,
                       0 AS latest3d_push_pro_num,
                       0 AS latest3d_push_store_num,
                       0 AS latest3d_push_merchant_num,
                       push_pro_num,
                       push_store_num,
                       push_merchant_num
      FROM t4) toa
   GROUP BY 1)



SELECT t6.bd_id,
       lvl6_dept_name `六级部门名称`,
       lvl5_dept_name `五级部门名称`,
       lvl4_dept_name `四级部门名称`,
       lvl3_dept_name `三级部门名称`,
       lvl2_dept_name `二级部门名称`,
       lvl1_dept_name `一级部门名称`,
       latest3d_pro_num `近3天待支付活动数`,
       latest3d_store_num `近3天待支付店铺数`,
       latest3d_merchant_num `近3天待支付商家数`,
       latest3d_push_pro_num `近3天推送活动数`,
       latest3d_push_store_num `近3天推送店铺数`,
       latest3d_push_merchant_num `近3天推送商家数`,
       push_pro_num `推送活动数`,
       push_store_num `推送店铺数`,
       push_merchant_num `推送商家数`
FROM t6
LEFT JOIN dim.dim_silkworm_staff_depart b ON t6.bd_id=b.bd_id







