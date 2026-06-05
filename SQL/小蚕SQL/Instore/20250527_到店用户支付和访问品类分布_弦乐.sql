================== part1 支付品类分布
-- 老用户
WITH t1 AS
  (SELECT user_id
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN '2024-06-01' AND '2025-02-28'
     AND date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
     AND promotion_type IN (1,
                            4)
   GROUP BY 1),

-- 支付
t2 AS
  (SELECT user_id,
          cate1_name,
          sum(order_num) order_num
   FROM
     (SELECT user_id,
             store_promotion_id,
             count(1) order_num
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN '2025-03-01' AND '2025-03-31'
        AND date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
        AND promotion_type IN (1,
                               4)
      GROUP BY 1,
               2) a
   INNER JOIN
     (SELECT CASE WHEN sub_category_type = 0 THEN '未知' WHEN sub_category_type = 1 THEN '包子粥铺' WHEN sub_category_type = 2 THEN '汉堡西餐' WHEN sub_category_type = 3 THEN '火锅烧烤' WHEN sub_category_type = 4 THEN '快餐简餐' WHEN sub_category_type = 5 THEN '理发/男士' WHEN sub_category_type = 6 THEN '亲子/乐园' WHEN sub_category_type = 7 THEN '水果生鲜' WHEN sub_category_type = 8 THEN '甜品饮品' WHEN sub_category_type = 9 THEN '休闲/玩乐' WHEN sub_category_type = 10 THEN '炸串小吃' WHEN sub_category_type = 11 THEN '正餐/多人餐' END AS cate1_name,
promotion_id
      FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE dt BETWEEN '2025-01-01' AND '2025-03-31'
AND promotion_type IN (1,
                       4)) b ON a.store_promotion_id=b.promotion_id
   GROUP BY 1,
          2)


SELECT '探店' `业务名称`,
            cate1_name `二级品类名称`,
            count(DISTINCT t1.user_id) `支付用户量`,
            sum(order_num) `支付订单量`
FROM t1
INNER JOIN t2 ON t1.user_id=t2.user_id
GROUP BY 1,
         2;




=============== part2 浏览品类分布
DROP VIEW IF EXISTS user_info;


CREATE VIEW IF NOT EXISTS user_info (user_id,business_name) AS
  (SELECT user_id,if(promotion_type in (1,4),'探店','砍价') business_name
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN '2024-06-01' AND '2025-03-31'
     AND date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
     AND promotion_type IN (1,
                            4,
                            5,
                            6)
   GROUP BY 1,2);


-- 浏览
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (activity_id,user_id,exp_pv,bar_pv) AS
  (SELECT activity_id,
          user_id,
          sum(if_view_storediscovery) exp_pv,
          sum(if_view_bargain) bar_pv
   FROM dws.dws_sr_traffic_user_d
   WHERE statistics_date BETWEEN '2025-04-01' AND '2025-04-30'
     AND user_id regexp '^[1-9]{1,10}$'
     AND activity_id regexp '^[1-9]{1,10}$'
     and (if_view_storediscovery>0 or if_view_bargain>0)
   GROUP BY 1,
            2);

-- 活动
DROP VIEW IF EXISTS pro_info;


CREATE VIEW IF NOT EXISTS pro_info (cate1_name,promotion_id) AS
  (SELECT CASE
              WHEN sub_category_type = 0 THEN '未知'
              WHEN sub_category_type = 1 THEN '包子粥铺'
              WHEN sub_category_type = 2 THEN '汉堡西餐'
              WHEN sub_category_type = 3 THEN '火锅烧烤'
              WHEN sub_category_type = 4 THEN '快餐简餐'
              WHEN sub_category_type = 5 THEN '理发/男士'
              WHEN sub_category_type = 6 THEN '亲子/乐园'
              WHEN sub_category_type = 7 THEN '水果生鲜'
              WHEN sub_category_type = 8 THEN '甜品饮品'
              WHEN sub_category_type = 9 THEN '休闲/玩乐'
              WHEN sub_category_type = 10 THEN '炸串小吃'
              WHEN sub_category_type = 11 THEN '正餐/多人餐'
          END AS cate1_name,
          promotion_id
   FROM dwd.dwd_sr_silkworm_explore_promotion
   WHERE dt BETWEEN '2025-01-01' AND '2025-03-31'
     AND promotion_type IN (1,
                            4,
                            5,
                            6));


select
    if(b.user_id is not null,'老用户','新用户') `用户类型`,
    c.cate1_name `二级品类名称`,
    count(distinct a.user_id) `浏览用户量`
from (select user_id,activity_id from view_info where exp_pv>0 group by 1,2) a left join user_info b on a.user_id=b.user_id and b.business_name='探店'
left join pro_info c on a.activity_id=c.promotion_id
group by 1,2;




=============== 支付留存
-- 支付
DROP VIEW IF EXISTS pay_info;


CREATE VIEW IF NOT EXISTS pay_info (user_id,exp_paydt,bar_paydt,exp_2m_ordnum,exp_3m_ordnum, exp_4m_ordnum, exp_5m_ordnum, bar_2m_ordnum, bar_3m_ordnum, bar_4m_ordnum, bar_5m_ordnum) AS
  (SELECT user_id,
          min(if(promotion_type in (1,4),date_format(pay_time,'%Y-%m-%d'),null)) exp_paydt,
          min(if(promotion_type in (5,6),date_format(pay_time,'%Y-%m-%d'),null)) bar_paydt,
          count(if(promotion_type in (1,4) and date_format(pay_time,'%Y-%m-%d') between '2025-02-01' and '2025-02-28',order_id,null)) exp_2m_ordnum,
          count(if(promotion_type in (1,4) and date_format(pay_time,'%Y-%m-%d') between '2025-03-01' and '2025-03-31',order_id,null)) exp_3m_ordnum,
          count(if(promotion_type in (1,4) and date_format(pay_time,'%Y-%m-%d') between '2025-04-01' and '2025-04-30',order_id,null)) exp_4m_ordnum,
          count(if(promotion_type in (1,4) and date_format(pay_time,'%Y-%m-%d') between '2025-05-01' and '2025-05-26',order_id,null)) exp_5m_ordnum,
          count(if(promotion_type in (5,6) and date_format(pay_time,'%Y-%m-%d') between '2025-02-01' and '2025-02-28',order_id,null)) bar_2m_ordnum,
          count(if(promotion_type in (5,6) and date_format(pay_time,'%Y-%m-%d') between '2025-03-01' and '2025-03-31',order_id,null)) bar_3m_ordnum,
          count(if(promotion_type in (5,6) and date_format(pay_time,'%Y-%m-%d') between '2025-04-01' and '2025-04-30',order_id,null)) bar_4m_ordnum,
          count(if(promotion_type in (5,6) and date_format(pay_time,'%Y-%m-%d') between '2025-05-01' and '2025-05-26',order_id,null)) bar_5m_ordnum
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN '2024-06-01' AND '2025-05-26'
     AND date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
     AND promotion_type IN (1,
                            4,
                            5,
                            6)
   GROUP BY 1);


SELECT '探店' `业务名称`,
            '2月首单用户' `类型`,
                     count(DISTINCT a.user_id) `首单用户量`,
                     sum(if(b.user_id is not null,b.exp_2m_ordnum,0)) `支付订单量`,
                     count(DISTINCT if(exp_3m_ordnum>0,a.user_id,NULL)) `次月留存用户量`
FROM
  (SELECT user_id
   FROM pay_info
   WHERE exp_paydt BETWEEN '2025-02-01' AND '2025-02-28'
   GROUP BY user_id) a
LEFT JOIN pay_info b ON a.user_id=b.user_id
GROUP BY 1,
         2

union all

SELECT '探店' `业务名称`,
            '3月首单用户' `类型`,
                     count(DISTINCT a.user_id) `首单用户量`,
                     sum(if(b.user_id is not null,b.exp_3m_ordnum,0)) `支付订单量`,
                     count(DISTINCT if(exp_4m_ordnum>0,a.user_id,NULL)) `次月留存用户量`
FROM
  (SELECT user_id
   FROM pay_info
   WHERE exp_paydt BETWEEN '2025-03-01' AND '2025-03-31'
   GROUP BY user_id) a
LEFT JOIN pay_info b ON a.user_id=b.user_id
GROUP BY 1,
         2

union all

SELECT '探店' `业务名称`,
            '4月首单用户' `类型`,
                     count(DISTINCT a.user_id) `首单用户量`,
                     sum(if(b.user_id is not null,b.exp_4m_ordnum,0)) `支付订单量`,
                     count(DISTINCT if(exp_5m_ordnum>0,a.user_id,NULL)) `次月留存用户量`
FROM
  (SELECT user_id
   FROM pay_info
   WHERE exp_paydt BETWEEN '2025-04-01' AND '2025-04-30'
   GROUP BY user_id) a
LEFT JOIN pay_info b ON a.user_id=b.user_id
GROUP BY 1,
         2     

union all

SELECT '砍价' `业务名称`,
            '2月首单用户' `类型`,
                     count(DISTINCT a.user_id) `首单用户量`,
                     sum(if(b.user_id is not null,b.bar_2m_ordnum,0)) `支付订单量`,
                     count(DISTINCT if(bar_3m_ordnum>0,a.user_id,NULL)) `次月留存用户量`
FROM
  (SELECT user_id
   FROM pay_info
   WHERE bar_paydt BETWEEN '2025-02-01' AND '2025-02-28'
   GROUP BY user_id) a
LEFT JOIN pay_info b ON a.user_id=b.user_id
GROUP BY 1,
         2

union all

SELECT '砍价' `业务名称`,
            '3月首单用户' `类型`,
                     count(DISTINCT a.user_id) `首单用户量`,
                     sum(if(b.user_id is not null,b.bar_3m_ordnum,0)) `支付订单量`,
                     count(DISTINCT if(bar_4m_ordnum>0,a.user_id,NULL)) `次月留存用户量`
FROM
  (SELECT user_id
   FROM pay_info
   WHERE bar_paydt BETWEEN '2025-03-01' AND '2025-03-31'
   GROUP BY user_id) a
LEFT JOIN pay_info b ON a.user_id=b.user_id
GROUP BY 1,
         2

union all

SELECT '砍价' `业务名称`,
            '4月首单用户' `类型`,
                     count(DISTINCT a.user_id) `首单用户量`,
                     sum(if(b.user_id is not null,b.bar_4m_ordnum,0)) `支付订单量`,
                     count(DISTINCT if(bar_5m_ordnum>0,a.user_id,NULL)) `次月留存用户量`
FROM
  (SELECT user_id
   FROM pay_info
   WHERE bar_paydt BETWEEN '2025-04-01' AND '2025-04-30'
   GROUP BY user_id) a
LEFT JOIN pay_info b ON a.user_id=b.user_id
GROUP BY 1,
         2 
;   

























