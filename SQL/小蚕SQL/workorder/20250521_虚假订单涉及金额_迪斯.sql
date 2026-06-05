-- 虚假订单 13614条数据
WITH t1 AS
  (SELECT order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2024-01-01' AND '2025-05-01'
     AND cate2_type=1 -- 订单异常
     AND cate3_type=7 -- 虚假订单
     AND status=2 -- 已完结
   GROUP BY 1),


-- 用户
t2 as (
select a.user_id 
      ,d.user_id_num
      ,a.user_real_name
      ,a.phone
      ,a.await_withdrawal_candou_num  -- 待提现蚕豆
      ,a.withdrawal_candou_num -- 体现中蚕豆
      ,a.withdrawal_candou_num+a.await_withdrawal_candou_num + a.tot_withdrawal_amt  as acc_candou_num -- 累计蚕豆数
      ,a.tot_withdrawal_amt   -- 已提现总金额
      ,a.latest_login_ip      -- 最近一次登陆的ip
      ,a.inviter_user_id   -- 团长ID
      ,if(a.status = 1 and left(a.latest_block_time,10)<>'1970-01-01' and (left(a.block_release_time,10)='1970-01-01' or left(a.block_release_time,10) < left(a.latest_block_time,10)),'拉黑','') is_blackin
      ,if(a.is_logoff=0,'正常','已注销') is_logoff
      ,b.city_name
      ,b.county_name
      ,c.address_detail
from dim.dim_silkworm_user a 
inner join (
SELECT county_id,
       county_name,
       city_name
FROM dim.dim_silkworm_county
WHERE county_id IN (510108, 330782, 330110, 330122, 330105, 330112, 330106, 330109, 330108, 330127, 330113, 330111, 330182, 330102, 330114, 310107, 310112, 310101, 310106, 310113, 310116, 310120, 310151, 310105, 310114, 310110, 310117, 310104, 310115, 310109, 310118, 110101, 110107, 110112, 110108, 110119, 110109, 110118, 110111, 110116, 110115, 110105, 110114, 110117, 110102, 110106, 110113) 
) b on a.county_id=b.county_id
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
      WHERE dt BETWEEN '2023-11-01' AND '2025-05-01') a
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
on t1.order_id = t4.order_id 
left join t2 
on t4.user_id = t2.user_id
left join t3 
on t2.inviter_user_id = t3.user_id
;







