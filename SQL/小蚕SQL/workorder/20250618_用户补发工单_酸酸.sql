工单创建日期 工单ID 日期 bd_id bd花名 店铺ID 店铺名称 红包金额 蚕豆金额


========================= 用户补发蚕豆和红包 同一个店铺，给用户驳回


SELECT `类型`,
       `创建时间`,
       `工单ID`,
       c.store_id `店铺ID`,
       d.store_name `店铺名称`,
       `金额`
FROM
(
-- 蚕豆工单
SELECT '蚕豆' `类型`,
            cast(create_time as string) `创建时间`,
            work_order_id `工单ID`,
            store_id,
            add_candou_num/100 `金额`
FROM dwd.dwd_sr_callcenter_workorder
WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-05-01' AND date_sub(current_date(),interval 1 DAY)
  AND cate2_type=4 -- 用户补发
  AND cate3_type=44 -- 同一个店铺，给用户驳回

union all

-- 工单红包
SELECT '红包' `类型`,
            cast(create_time AS string) `创建时间`,
            a.work_order_id `工单ID`,
            b.store_id,
            a.redpacket_amt `金额`
FROM
  (SELECT create_time,
          work_order_id,
          redpacket_amt
   FROM dwd.dwd_sr_callcenter_workorder_rp_grant
   WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-05-01' AND date_sub(current_date(),interval 1 DAY)
     AND status=1 -- 发放成功
) a
LEFT JOIN
  (SELECT work_order_id,
          store_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
     AND cate2_type=4
     AND cate3_type=44) b ON a.work_order_id=b.work_order_id
) c
LEFT JOIN dim.dim_silkworm_store d on c.store_id=d.store_id
;


================ 驳回订单
SELECT order_time `下单时间`,
       concat('单',a.order_id) `订单ID`,
       a.store_id `店铺ID`,
       store_name `店铺名称`,
       a.bd_id,
       d.user_nickname `商务花名`,
       origin_rebate_amt `应返蚕豆金额`
FROM
  (SELECT order_time,
          order_id,
          store_id,
          bd_id,
          origin_rebate_amt
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-05-01' AND date_sub(current_date(),interval 1 DAY)
     AND order_status=3 -- 驳回
     ) a
INNER JOIN 
-- 蚕豆工单
  (SELECT order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
     AND cate3_type=44 -- 同一个店铺，给用户驳回
   GROUP BY 1) b ON a.order_id=b.order_id
LEFT JOIN dim.dim_silkworm_store c on a.store_id=c.store_id
LEFT JOIN dim.dim_silkworm_staff d on a.bd_id=d.bd_id
;








