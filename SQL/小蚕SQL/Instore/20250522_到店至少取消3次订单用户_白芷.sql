-- 到店活动明细
DROP VIEW IF EXISTS pro_info;


CREATE VIEW IF NOT EXISTS pro_info (newpro_id,promotion_id,sub_category_type,promotion_type,tot_promotion_quota,rebate_price,cost_price,net_cost_price,group_amt,hand_price,tot_bargain_amt,bargain_original_price,bargain_base_price,bargain_max_discount,bargain_min_discount,city_name,begin_date,recurring_promotion_id,contract_id,price_interval,store_name) AS
  (SELECT newpro_id,
          promotion_id,
          sub_category_type,
          promotion_type,
          tot_promotion_quota,
          rebate_price,
          cost_price,
          net_cost_price,
          group_amt,
          hand_price,
          tot_bargain_amt,
          bargain_original_price,
          bargain_base_price,
          bargain_max_discount,
          bargain_min_discount,
          coalesce(city_name,'其他') as city_name,
          begin_date,
          recurring_promotion_id,
          contract_id,
          price_interval,
          store_name
   FROM
     (SELECT if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) as newpro_id,
             promotion_id ,
             CASE WHEN sub_category_type = 0 THEN '未知' WHEN sub_category_type = 1 THEN '包子粥铺' WHEN sub_category_type = 2 THEN '汉堡西餐' WHEN sub_category_type = 3 THEN '火锅烧烤' WHEN sub_category_type = 4 THEN '快餐简餐' WHEN sub_category_type = 5 THEN '理发/男士' WHEN sub_category_type = 6 THEN '亲子/乐园' WHEN sub_category_type = 7 THEN '水果生鲜' WHEN sub_category_type = 8 THEN '甜品饮品' WHEN sub_category_type = 9 THEN '休闲/玩乐' WHEN sub_category_type = 10 THEN '炸串小吃' WHEN sub_category_type = 11 THEN '正餐/多人餐' END AS sub_category_type,
             promotion_type,
             tot_promotion_quota,
             rebate_price, -- 返利价
             cost_price, -- 成本价(含笔记)
             net_cost_price, -- 成本价(不含笔记)
             pay_amt AS group_amt, -- 团购价
             pay_amt - rebate_price as hand_price,  -- 到手价
             tot_bargain_amt,-- 总砍价金额
             bargain_original_price,-- 砍价原价
             bargain_base_price,-- 砍价底价
             bargain_max_discount,-- 砍价最大折扣
             bargain_min_discount,-- 砍价最低折扣
             city_code AS county_id,
             date_format(begin_time,'%Y-%m-%d') as begin_date,
             recurring_promotion_id,
             contract_id,
             -- 团购价价格段
             CASE
                WHEN promotion_type IN (5,6)
                     AND pay_amt <60 THEN '0-60'
                WHEN promotion_type IN (5,6)
                     AND pay_amt >=60
                     AND pay_amt <120 THEN '60-120'
                WHEN promotion_type IN (5,6)
                     AND pay_amt >=120
                     AND pay_amt <180 THEN '120-180'
                WHEN promotion_type IN (5,6)
                     AND pay_amt >=180 THEN '180+'
                WHEN promotion_type IN (1,4)
                     AND pay_amt <30 THEN '0-30'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=30
                     AND pay_amt <60 THEN '30-60'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=60
                     AND pay_amt <90 THEN '60-90'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=90
                     AND pay_amt <120 THEN '90-120'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=120 THEN '120+'
                END price_interval,
                store_name
      FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE date_format(begin_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 200 DAY) AND date_sub(current_date(),interval 1 DAY)
AND promotion_type IN (
                       5,
                       6) 
AND store_promotion_name NOT regexp '测试'                    
      ) a
-- 到店已开通业务城市
INNER JOIN
  (SELECT b1.county_id,
          b1.city_name
   FROM dim.dim_silkworm_county b1
   INNER JOIN dim.dim_silkworm_explore_city b2 ON b1.city_name=b2.city_name
   AND b2.province_name<>'新疆维吾尔族自治区'
   AND b2.status=1
   AND b2.promotion_type IN ('101',
                          '111',
                          '100',
                          '1')
   ) b ON a.county_id=b.county_id
  );


-- 到店订单明细
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (store_promotion_id,order_id,user_id,promotion_type,pay_time,cancel_time,verify_time,finish_time,status,pay_amt,redpack_reward_amt,real_rebate_amt) AS
  (SELECT store_promotion_id,
          order_id,
          user_id,
          promotion_type,
          if(promotion_type = 4,create_time,pay_time) AS pay_time,
          cancel_time,
          verify_time,
          finish_time,
          status,
          coalesce(pay_amt,0) AS pay_amt,
          coalesce(red_pack_reward_num/100,0) AS redpack_reward_amt,
          real_rebate_amt
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub(current_date(),interval 200 DAY) AND date_sub(current_date(),interval 0 DAY)
     AND promotion_type IN (
                            5,
                            6)
     );

-- 筛选出至少取消3次订单用户
DROP VIEW IF EXISTS user_info;

 creat VIEW IF NOT EXISTS user_info (user_id,cancel_order_num) AS
  (SELECT user_id,
          count(DISTINCT IF(status IN (6,8,10),order_id,NULL)) cancel_order_num
   FROM order_info
   WHERE date_format(pay_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 180 DAY) AND date_sub(current_date(),interval 0 DAY)
   GROUP BY user_id HAVING count(DISTINCT IF(status IN (6,8,10),order_id,NULL))>=3) ;




select
    a.store_promotion_id `活动ID`,
    c.recurring_promotion_id `循环活动ID`,
    c.store_name `店铺名称`,
    a.user_id `用户ID`,
    concat('单',a.order_id) `订单ID`,
    a.pay_time `支付时间`,
    a.cancel_time `取消时间`
from (
    select * from order_info 
    where date_format(pay_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 DAY) AND date_sub(current_date(),interval 0 DAY)
    ) a inner join user_info b on a.user_id=b.user_id
left join pro_info c on a.store_promotion_id=c.promotion_id;















