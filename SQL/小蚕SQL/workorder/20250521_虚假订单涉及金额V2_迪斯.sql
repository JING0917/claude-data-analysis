-- 拉黑用户 71645条数据
WITH t1 AS
  (SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE status = 1
     AND left(latest_block_time,10)<>'1970-01-01'
     AND (left(block_release_time,10)='1970-01-01'
          OR left(block_release_time,10) < left(latest_block_time,10)
          )
     ),


-- 用户
t2 as (
select a.user_id 
      ,d.user_id_num
      ,d.user_real_name
      ,d.phone
      ,d.await_withdrawal_candou_num  -- 待提现蚕豆
      ,d.withdrawal_candou_num -- 体现中蚕豆
      ,d.withdrawal_candou_num+d.await_withdrawal_candou_num + d.tot_withdrawal_amt  as acc_candou_num -- 累计蚕豆数
      ,d.tot_withdrawal_amt   -- 已提现总金额
      ,d.latest_login_ip      -- 最近一次登陆的ip
      ,d.inviter_user_id   -- 团长ID
      ,b.province_name
      ,b.city_name
      ,b.county_name
      ,c.address_detail
from t1 a 
left join dim.dim_silkworm_user_location c on a.user_id=c.user_id
left join ods.ods_sr_silkworm_user d on a.user_id=d.user_id
),


-- 团长
t3 AS
  (SELECT a.user_id ,
          b.user_id_num ,
          a.user_real_name ,
          a.phone
   FROM dim.dim_silkworm_user a
  left join ods.ods_sr_silkworm_user b on a.user_id=b.user_id
),

-- 订单
t4 AS
  (SELECT rebate_condition_desc ,
          order_id ,
          platform_order_id ,
          order_time ,
          a.store_id ,
          b.store_name,
          user_id,
          real_rebate_amt,
          redpacket_amt
   FROM
     (SELECT rebate_condition_desc ,
             order_id ,
             platform_order_id ,
             order_time ,
             store_id ,
             user_id,
             real_rebate_amt,
             redpacket_amt
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2023-11-01' AND '2025-05-01'
        and order_status in (2,8)) a
   LEFT JOIN dim.dim_silkworm_store b ON a.store_id=b.store_id)


select t4.rebate_condition_desc as '订单类型'
      ,concat('单',t4.order_id) as '小蚕订单ID'
      ,concat('单',t4.platform_order_id) as '平台订单ID'
      ,t4.order_time as '下单时间'
      ,t4.store_id as '店铺ID'
      ,t4.store_name as '店铺名称'
      ,t4.user_id as '用户ID'
      ,t2.user_real_name as '用户真实姓名'
      ,concat('身',t2.user_id_num) as '用户身份证号'
      ,t2.phone as '用户手机号'
      ,t2.acc_candou_num as '累计蚕豆数'
      ,t2.await_withdrawal_candou_num as '现有蚕豆数'
      ,t2.tot_withdrawal_amt as '提现完成蚕豆数'
      ,t4.real_rebate_amt as '实际返现金额'
      ,t4.redpacket_amt as '红包返现金额'
      ,t2.city_name as '城市'
      ,t2.county_name as '区县'
      ,t2.address_detail as '用户定位地址'
      ,t2.latest_login_ip as '最近一次登陆的ip'
      ,t2.inviter_user_id as '团长ID'
      ,t3.user_real_name as '团长真实姓名'
      ,concat('身',t3.user_id_num) as '团长身份证号'
      ,t3.phone as '团长手机号'
from t1
left join t4 
on t1.user_id = t4.user_id 
left join t2 
on t4.user_id = t2.user_id
left join t3 
on t2.inviter_user_id = t3.user_id
where t4.user_id is not null
;







