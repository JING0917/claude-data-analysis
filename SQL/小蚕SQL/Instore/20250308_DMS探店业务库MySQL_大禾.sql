
-- 提取一席地商家账单
select a.* from 
(SELECT created_at,
  '72478071' as merchant_id,
  `store_id`, 
  amount/100 as amt,
  promotion_id,
  silk_id,
  concat('单',order_id) as new_order_id,
  case when change_type=1 then '冻结/收入'
    when change_type=2 then '提现'
    when change_type=3 then '退款/扣减'
    when change_type=4 then '笔记补单'
    when change_type=5 then '转为可提现'
  else '其他' end change_type,
  remark,
  case when status=1 then '进行中'
    when status=2 then '成功'
    when status=3 then '失败'
  else '其他' end status
  FROM `store_bill`
where date(created_at) BETWEEN '2024-12-01' and '2025-01-19'
  ) a
inner join `store` b on a.store_id=b.id and b.`merchant_silk_id` =72478071
;




-- 提取每日砍价订单
select
  concat('单',a.order_id) `订单ID`,
  a.promotion_id `活动ID`,
  a.promotion_name `活动名称`,
  -- a.original_price/100 `原价`,
  a.store_id `店铺ID`,
  e.name `店铺名称`,
  a.silk_id `用户ID`,
  a.red_pack_id `红包明细ID`,
  b.contract_id `合约ID`,
  b.contract_name `合约名称`,
  if(a.promotion_type=5,'砍价','合约砍价') `订单类型`,
  a.pay_amount/100 `支付金额`,
  b.pay_price/100 `团购金额`,
  b.bargain_original_price/100 `原价`,
  a.pay_amount/b.bargain_original_price `支付折扣率`,
  c.refund_fault_amount/100 `扣除手续费`,
  d.pay_modename `支付方式`,
  a.order_status `订单状态`
from
-- 订单
(SELECT 
  promotion_type,
  order_id,
  promotion_id,
  promotion_name,
  original_price, -- 原价
  store_id,
  -- store_name,
  silk_id,
  red_pack_id, -- 红包明细ID
  `pay_amount`, -- 支付金额
  case when status=5 then '已完成'
    when `verified_time` <>0 then '已核销'
    when `pay_time`<>0 then '已支付'
  else '其他' end as order_status
FROM `order` 
where date(`created_at`) = '2025-03-08'
  and `promotion_type` in (5,6)
) a 
left join 
-- 活动
(select id,
  pay_price,
  `bargain_original_price`,
  `contract_id`,
  `contract_name` 
from `promotion` 
WHERE date(`created_at`) between '2025-01-01' and '2025-03-08' 
  and `promotion_type` in (5,6)
) b ON a.promotion_id=b.id 
left join
-- 扣除手续费
(select `order_id`,`refund_fault_amount` 
from `refund_history`
where date(`created_at`) between '2025-01-01' and '2025-03-08'
) c ON a.order_id=c.order_id
left join
-- 支付方式
(select
  order_id,case when `pay_mode`=0 then '支付宝' when `pay_mode`=1 then '微信' else '蚕豆' end as pay_modename
from `pay_history`
where date(`created_at`) between '2025-01-01' and '2025-03-08'
) d ON a.order_id=d.order_id
-- 店铺名称
left join `store` e ON a.store_id=e.id
;



-- 提取每日核销砍价订单
select
  date(a.created_at) as `创建日期`,
  a.verify_date `核销日期`,
  concat('单',a.order_id) `订单ID`,
  a.promotion_id `活动ID`,
  a.promotion_name `活动名称`,
  -- a.original_price/100 `原价`,
  a.store_id `店铺ID`,
  e.name `店铺名称`,
  a.silk_id `用户ID`,
  a.red_pack_id `红包明细ID`,
  b.contract_id `合约ID`,
  b.contract_name `合约名称`,
  if(a.promotion_type=5,'砍价','合约砍价') `订单类型`,
  a.pay_amount/100 `支付金额`,
  b.pay_price/100 `团购金额`,
  b.bargain_original_price/100 `原价`,
  a.pay_amount/b.bargain_original_price `支付折扣率`,
  c.refund_fault_amount/100 `扣除手续费`,
  d.pay_modename `支付方式`,
  a.order_status `订单状态`
-- count(1) cnt
from
-- 订单
(SELECT 
  created_at,
  from_unixtime(verified_time,'%Y-%m-%d') as verify_date,
  promotion_type,
  order_id,
  promotion_id,
  promotion_name,
  original_price, -- 原价
  store_id,
  -- store_name,
  silk_id,
  red_pack_id, -- 红包明细ID
  `pay_amount`, -- 支付金额
  case when status=5 then '已完成'
    when `verified_time` <>0 then '已核销'
    when `pay_time`<>0 then '已支付'
  else '其他' end as order_status
FROM `order` 
where from_unixtime(verified_time,'%Y-%m-%d')=DATE_SUB(curdate(),INTERVAL 1 DAY)
  and `promotion_type` in (5,6)
  and status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33) -- 核销
) a 
left join 
-- 活动
(select id,
  pay_price,
  `bargain_original_price`,
  `contract_id`,
  `contract_name` 
from `promotion` 
WHERE date(`created_at`) between '2024-06-01' and DATE_SUB(curdate(),INTERVAL 1 DAY) 
  and `promotion_type` in (5,6)
) b ON a.promotion_id=b.id 
left join
-- 扣除手续费
(select `order_id`,`refund_fault_amount` 
from `refund_history`
where date(`created_at`) between '2024-06-01' and DATE_SUB(curdate(),INTERVAL 1 DAY)
) c ON a.order_id=c.order_id
left join
-- 支付方式
(select
  order_id,case when `pay_mode`=0 then '支付宝' when `pay_mode`=1 then '微信' else '蚕豆' end as pay_modename
from `pay_history`
where date(`created_at`) between '2024-06-01' and DATE_SUB(curdate(),INTERVAL 1 DAY)
) d ON a.order_id=d.order_id
-- 店铺名称
left join `store` e ON a.store_id=e.id
;







