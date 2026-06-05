
-- 到店活动明细
DROP VIEW IF EXISTS exp_pro;


CREATE VIEW IF NOT EXISTS exp_pro (newpro_id,promotion_id,sub_category_type,promotion_type,tot_promotion_quota,group_discount,rebate_price,cost_price,net_cost_price,group_amt,hand_price,tot_bargain_amt,bargain_original_price,bargain_base_price,bargain_max_discount,bargain_min_discount,city_name,begin_date,recurring_promotion_id) AS
  (SELECT newpro_id,
          promotion_id,
          sub_category_type,
          promotion_type,
          tot_promotion_quota,
          group_discount,
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
          recurring_promotion_id
   FROM
     (SELECT if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) as newpro_id,
             promotion_id ,
             CASE WHEN sub_category_type = 0 THEN '未知' WHEN sub_category_type = 1 THEN '包子粥铺' WHEN sub_category_type = 2 THEN '汉堡西餐' WHEN sub_category_type = 3 THEN '火锅烧烤' WHEN sub_category_type = 4 THEN '快餐简餐' WHEN sub_category_type = 5 THEN '理发/男士' WHEN sub_category_type = 6 THEN '亲子/乐园' WHEN sub_category_type = 7 THEN '水果生鲜' WHEN sub_category_type = 8 THEN '甜品饮品' WHEN sub_category_type = 9 THEN '休闲/玩乐' WHEN sub_category_type = 10 THEN '炸串小吃' WHEN sub_category_type = 11 THEN '正餐/多人餐' END AS sub_category_type,
             promotion_type,
             tot_promotion_quota,
             group_discount, -- 团购价
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
             recurring_promotion_id
      FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE date_format(begin_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY)
AND promotion_type IN (1,
                       4,
                       5,
                       6) 
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




-- 到店订单
DROP VIEW IF EXISTS exp_order;


CREATE VIEW IF NOT EXISTS exp_order (store_promotion_id,order_id,user_id,promotion_type,pay_time,verify_time,finish_time,status,pay_amt,redpack_reward_amt,real_rebate_amt) AS
  (SELECT store_promotion_id,
          order_id,
          user_id,
          promotion_type,
          if(promotion_type = 4,create_time,pay_time) AS pay_time,
          verify_time,
          finish_time,
          status,
          coalesce(pay_amt,0) AS pay_amt,
          coalesce(red_pack_reward_num/100,0) AS redpack_reward_amt,
          real_rebate_amt
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 60 DAY) AND date_sub(current_date(),interval 1 DAY)
    and date_format(pay_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND promotion_type IN (1,
                            4,
                            5,
                            6)
     );


-- 时间间隔时要剔除无核销的数据，时间间隔要单独跑

SELECT business_name,
       city_name,
       count(distinct user_id) `用户量`,
       min(avg_payord_num) `最小值`,
       percentile_cont(avg_payord_num,0.1) `10分位`,
       percentile_cont(avg_payord_num,0.2) `20分位`,
       percentile_cont(avg_payord_num,0.3) `30分位`,
       percentile_cont(avg_payord_num,0.4) `40分位`,
       percentile_cont(avg_payord_num,0.5) `50分位`,
       percentile_cont(avg_payord_num,0.6) `60分位`,
       percentile_cont(avg_payord_num,0.7) `70分位`,
       percentile_cont(avg_payord_num,0.8) `80分位`,
       percentile_cont(avg_payord_num,0.9) `90分位`,
       max(avg_payord_num) `最大值`,
       min(avg_group_amt) `最小值`,
       percentile_cont(avg_group_amt,0.1) `10分位`,
       percentile_cont(avg_group_amt,0.2) `20分位`,
       percentile_cont(avg_group_amt,0.3) `30分位`,
       percentile_cont(avg_group_amt,0.4) `40分位`,
       percentile_cont(avg_group_amt,0.5) `50分位`,
       percentile_cont(avg_group_amt,0.6) `60分位`,
       percentile_cont(avg_group_amt,0.7) `70分位`,
       percentile_cont(avg_group_amt,0.8) `80分位`,
       percentile_cont(avg_group_amt,0.9) `90分位`,
       max(avg_group_amt) `最大值`
FROM
  (SELECT business_name,
          city_name,
          user_id,
          avg(payord_num) avg_payord_num,
          avg(group_amt) avg_group_amt
   FROM
     (SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             a.city_name,
             b.user_id,
             date_format(b.pay_time,'%Y-%m-%d') AS pat_date,
             count(DISTINCT b.order_id) payord_num,
             sum(a.group_amt) group_amt
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id
      GROUP BY 1,
               2,
               3,
               4) c
   GROUP BY 1,
            2,
            3) d
GROUP BY 1,
         2;


 -- 整体
SELECT business_name,
       city_name,
       count(distinct user_id) `用户量`,
       min(avg_payord_num) `最小值`,
       percentile_cont(avg_payord_num,0.1) `10分位`,
       percentile_cont(avg_payord_num,0.2) `20分位`,
       percentile_cont(avg_payord_num,0.3) `30分位`,
       percentile_cont(avg_payord_num,0.4) `40分位`,
       percentile_cont(avg_payord_num,0.5) `50分位`,
       percentile_cont(avg_payord_num,0.6) `60分位`,
       percentile_cont(avg_payord_num,0.7) `70分位`,
       percentile_cont(avg_payord_num,0.8) `80分位`,
       percentile_cont(avg_payord_num,0.9) `90分位`,
       max(avg_payord_num) `最大值`,
       min(avg_group_amt) `最小值`,
       percentile_cont(avg_group_amt,0.1) `10分位`,
       percentile_cont(avg_group_amt,0.2) `20分位`,
       percentile_cont(avg_group_amt,0.3) `30分位`,
       percentile_cont(avg_group_amt,0.4) `40分位`,
       percentile_cont(avg_group_amt,0.5) `50分位`,
       percentile_cont(avg_group_amt,0.6) `60分位`,
       percentile_cont(avg_group_amt,0.7) `70分位`,
       percentile_cont(avg_group_amt,0.8) `80分位`,
       percentile_cont(avg_group_amt,0.9) `90分位`,
       max(avg_group_amt) `最大值`
FROM
  (SELECT business_name,
          city_name,
          user_id,
          avg(payord_num) avg_payord_num,
          avg(group_amt) avg_group_amt
   FROM
     (SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             '全部' city_name,
             b.user_id,
             date_format(b.pay_time,'%Y-%m-%d') AS pat_date,
             count(DISTINCT b.order_id) payord_num,
             sum(a.group_amt) group_amt
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id
      GROUP BY 1,
               2,
               3,
               4) c
   GROUP BY 1,
            2,
            3) d
GROUP BY 1,
         2;     



-- 核销时间间隔
SELECT business_name,
       city_name,
       count(user_id) `用户量`,
       min(avg_diff_hrs) `最小值`,
       percentile_cont(avg_diff_hrs,0.1) `10分位`,
       percentile_cont(avg_diff_hrs,0.2) `20分位`,
       percentile_cont(avg_diff_hrs,0.3) `30分位`,
       percentile_cont(avg_diff_hrs,0.4) `40分位`,
       percentile_cont(avg_diff_hrs,0.5) `50分位`,
       percentile_cont(avg_diff_hrs,0.6) `60分位`,
       percentile_cont(avg_diff_hrs,0.7) `70分位`,
       percentile_cont(avg_diff_hrs,0.8) `80分位`,
       percentile_cont(avg_diff_hrs,0.9) `90分位`,
       max(avg_diff_hrs) `最大值`
FROM
  (SELECT business_name,
          city_name,
          user_id,
          avg(diff_hrs) avg_diff_hrs
   FROM
     (SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             a.city_name,
             b.user_id,
             date_format(b.pay_time,'%Y-%m-%d') AS pat_date,
             if(date_format(b.verify_time,'%Y-%m-%d')='1970-01-01',999999999999999,date_diff('hour',date_format(b.verify_time,'%Y-%m-%d %H:%i:%s'),date_format(b.pay_time,'%Y-%m-%d %H:%i:%s'))) diff_hrs
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id) c
   WHERE diff_hrs<>999999999999999
   GROUP BY 1,
            2,
            3) d
GROUP BY 1,
         2;

-- 核销时间间隔 全部
SELECT business_name,
       city_name,
       count(user_id) `用户量`,
       min(avg_diff_hrs) `最小值`,
       percentile_cont(avg_diff_hrs,0.1) `10分位`,
       percentile_cont(avg_diff_hrs,0.2) `20分位`,
       percentile_cont(avg_diff_hrs,0.3) `30分位`,
       percentile_cont(avg_diff_hrs,0.4) `40分位`,
       percentile_cont(avg_diff_hrs,0.5) `50分位`,
       percentile_cont(avg_diff_hrs,0.6) `60分位`,
       percentile_cont(avg_diff_hrs,0.7) `70分位`,
       percentile_cont(avg_diff_hrs,0.8) `80分位`,
       percentile_cont(avg_diff_hrs,0.9) `90分位`,
       max(avg_diff_hrs) `最大值`
FROM
  (SELECT business_name,
          city_name,
          user_id,
          avg(diff_hrs) avg_diff_hrs
   FROM
     (SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             '全部' city_name,
             b.user_id,
             date_format(b.pay_time,'%Y-%m-%d') AS pat_date,
             if(date_format(b.verify_time,'%Y-%m-%d')='1970-01-01',999999999999999,date_diff('hour',date_format(b.verify_time,'%Y-%m-%d %H:%i:%s'),date_format(b.pay_time,'%Y-%m-%d %H:%i:%s'))) diff_hrs
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id) c
   WHERE diff_hrs<>999999999999999
   GROUP BY 1,
            2,
            3) d
GROUP BY 1,
         2;


=========== 用户量和占比
-- 支付订单量
SELECT business_name `业务线`,
       city_name `城市`,
       payord_num `近30天支付订单量`,
       count(DISTINCT user_id) `用户量`
FROM
     (SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             a.city_name,
             b.user_id,
             count(DISTINCT b.order_id) payord_num
            -- count(DISTINCT CASE WHEN a.promotion_type IN (5,6)
            -- AND date_format(b.pay_time,'%Y-%m-%d') <> '1970-01-01'
            -- AND b.status IN (3,5,36) then order_id 
            -- WHEN a.promotion_type IN (1,4)
            -- AND b.pay_time BETWEEN concat(left(date_sub(begin_date,7),10),' 00:00:00') AND concat(left(date_add(begin_date,1),10),' 00:05:00')
            -- AND b.status NOT IN (1,2,6,7,8,9,10,21) THEN order_id END) payord_num
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id
      GROUP BY 1,
               2,
               3) c
GROUP BY 1,
         2,
         3

union all

SELECT business_name `业务线`,
       city_name `城市`,
       payord_num `近30天支付订单量`,
       count(DISTINCT user_id) `用户量`
FROM
     (SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             '全部' city_name,
             b.user_id,
             count(DISTINCT b.order_id) payord_num
            -- count(DISTINCT CASE WHEN a.promotion_type IN (5,6)
            -- AND date_format(b.pay_time,'%Y-%m-%d') <> '1970-01-01'
            -- AND b.status IN (3,5,36) then order_id 
            -- WHEN a.promotion_type IN (1,4)
            -- AND b.pay_time BETWEEN concat(left(date_sub(begin_date,7),10),' 00:00:00') AND concat(left(date_add(begin_date,1),10),' 00:05:00')
            -- AND b.status NOT IN (1,2,6,7,8,9,10,21) THEN order_id END) payord_num
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id
      GROUP BY 1,
               2,
               3) c
GROUP BY 1,
         2,
         3
;


-- 团购价
SELECT business_name `业务线`,
       city_name `城市`,
 CASE
     WHEN business_name='砍价'
          AND group_amt <60 THEN '0-60'
     WHEN business_name='砍价'
          AND group_amt >=60
          AND group_amt <120 THEN '60-120'
     WHEN business_name='砍价'
          AND group_amt >=120
          AND group_amt <180 THEN '120-180'
     WHEN business_name='砍价'
          AND group_amt >=180 THEN '180+'
     WHEN business_name='探店'
          AND group_amt <30 THEN '0-30'
     WHEN business_name='探店'
          AND group_amt >=30
          AND group_amt <60 THEN '30-60'
     WHEN business_name='探店'
          AND group_amt >=60
          AND group_amt <90 THEN '60-90'
     WHEN business_name='探店'
          AND group_amt >=90
          AND group_amt <120 THEN '90-120'
     WHEN business_name='探店'
          AND group_amt >=120 THEN '120+'
     ELSE '其他'
 END `近30天团购价(元)`,
       count(DISTINCT user_id) `用户量`
FROM
     (SELECT a.promotion_id,
            if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             a.city_name,
             b.user_id,
             sum(group_amt) group_amt
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id
      GROUP BY 1,
               2,
               3,
               4) c
   GROUP BY 1,
            2,
            3

union all


SELECT business_name `业务线`,
       city_name `城市`,
 CASE
     WHEN business_name='砍价'
          AND group_amt <60 THEN '0-60'
     WHEN business_name='砍价'
          AND group_amt >=60
          AND group_amt <120 THEN '60-120'
     WHEN business_name='砍价'
          AND group_amt >=120
          AND group_amt <180 THEN '120-180'
     WHEN business_name='砍价'
          AND group_amt >=180 THEN '180+'
     WHEN business_name='探店'
          AND group_amt <30 THEN '0-30'
     WHEN business_name='探店'
          AND group_amt >=30
          AND group_amt <60 THEN '30-60'
     WHEN business_name='探店'
          AND group_amt >=60
          AND group_amt <90 THEN '60-90'
     WHEN business_name='探店'
          AND group_amt >=90
          AND group_amt <120 THEN '90-120'
     WHEN business_name='探店'
          AND group_amt >=120 THEN '120+'
     ELSE group_amt
 END `近30天团购价(元)`,
       count(DISTINCT user_id) `用户量`
FROM
     (SELECT a.promotion_id,
            if(a.promotion_type IN (1,4),'探店','砍价') business_name,
             '全部' city_name,
             b.user_id,
             sum(group_amt) group_amt
      FROM exp_pro a
      INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id
      GROUP BY 1,
               2,
               3,
               4) c
   GROUP BY 1,
            2,
            3
;



-- 核销时间间隔

SELECT business_name `业务线`,
       city_name `城市`,
       CASE
           WHEN diff_hrs<1 THEN '1小时内'
           WHEN diff_hrs>=1
                AND diff_hrs<2 THEN '1-2小时内'
           WHEN diff_hrs>=2
                AND diff_hrs<4 THEN '2-4小时内'
           WHEN diff_hrs>=4
                AND diff_hrs<8 THEN '4-8小时内'
           WHEN diff_hrs>=8
                AND diff_hrs<12 THEN '8-12小时内'
           WHEN diff_hrs>=12
                AND diff_hrs<24 THEN '12-24小时内'
           WHEN diff_hrs>=24
                AND diff_hrs<48 THEN '24-48小时内'
           WHEN diff_hrs>=48
                AND diff_hrs<72 THEN '48-72小时内'
           WHEN diff_hrs>=72
                AND diff_hrs<96 THEN '72-96小时内'
           WHEN diff_hrs>=96
                AND diff_hrs<120 THEN '96-120小时内'
           WHEN diff_hrs>=120
                AND diff_hrs<144 THEN '120-144小时内'
           WHEN diff_hrs>=144
                AND diff_hrs<168 THEN '144-168小时内'
           WHEN diff_hrs>=168 THEN '168小时+'
           ELSE '其他'
       END `核销时效(左闭右开)`,
       count(user_id) `用户量`
FROM
  (SELECT a.promotion_id,
          if(a.promotion_type IN (1,4),'探店','砍价') business_name,
          a.city_name,
          b.user_id,
          date_format(b.pay_time,'%Y-%m-%d') AS pat_date,
          if(date_format(b.verify_time,'%Y-%m-%d')='1970-01-01',999999999999999,date_diff('hour',date_format(b.verify_time,'%Y-%m-%d %H:%i:%s'),date_format(b.pay_time,'%Y-%m-%d %H:%i:%s'))) diff_hrs
   FROM exp_pro a
   INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id) c
WHERE diff_hrs<>999999999999999
GROUP BY 1,
         2,
         3

union all

SELECT business_name `业务线`,
       city_name `城市`,
       CASE
           WHEN diff_hrs<1 THEN '1小时内'
           WHEN diff_hrs>=1
                AND diff_hrs<2 THEN '1-2小时内'
           WHEN diff_hrs>=2
                AND diff_hrs<4 THEN '2-4小时内'
           WHEN diff_hrs>=4
                AND diff_hrs<8 THEN '4-8小时内'
           WHEN diff_hrs>=8
                AND diff_hrs<12 THEN '8-12小时内'
           WHEN diff_hrs>=12
                AND diff_hrs<24 THEN '12-24小时内'
           WHEN diff_hrs>=24
                AND diff_hrs<48 THEN '24-48小时内'
           WHEN diff_hrs>=48
                AND diff_hrs<72 THEN '48-72小时内'
           WHEN diff_hrs>=72
                AND diff_hrs<96 THEN '72-96小时内'
           WHEN diff_hrs>=96
                AND diff_hrs<120 THEN '96-120小时内'
           WHEN diff_hrs>=120
                AND diff_hrs<144 THEN '120-144小时内'
           WHEN diff_hrs>=144
                AND diff_hrs<168 THEN '144-168小时内'
           WHEN diff_hrs>=168 THEN '168小时+'
           ELSE '其他'
       END `核销时效(左闭右开)`,
       count(user_id) `用户量`
FROM
  (SELECT a.promotion_id,
          if(a.promotion_type IN (1,4),'探店','砍价') business_name,
          '全部' city_name,
          b.user_id,
          date_format(b.pay_time,'%Y-%m-%d') AS pat_date,
          if(date_format(b.verify_time,'%Y-%m-%d')='1970-01-01',999999999999999,date_diff('hour',date_format(b.verify_time,'%Y-%m-%d %H:%i:%s'),date_format(b.pay_time,'%Y-%m-%d %H:%i:%s'))) diff_hrs
   FROM exp_pro a
   INNER JOIN exp_order b ON a.promotion_id=b.store_promotion_id) c
WHERE diff_hrs<>999999999999999
GROUP BY 1,
         2,
         3






