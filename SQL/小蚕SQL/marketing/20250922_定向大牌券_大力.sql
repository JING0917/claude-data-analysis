-- 定向大牌券发放和使用
SELECT card_type,
       card_id,
       count(1) cnt
FROM dwd.dwd_sr_market_rights_card
WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-09-15' AND '2025-09-21'
  AND card_type=13
GROUP BY 1,
         2;


-- 使用间隔分位值
SELECT card_type,
       count(1) `数据量`,
       min(diff_hour) `最小值`,
       PERCENTILE_CONT(diff_hour,0.1) `10分位`,
       PERCENTILE_CONT(diff_hour,0.2) `20分位`,
       PERCENTILE_CONT(diff_hour,0.3) `30分位`,
       PERCENTILE_CONT(diff_hour,0.4) `40分位`,
       PERCENTILE_CONT(diff_hour,0.5) `50分位`,
       PERCENTILE_CONT(diff_hour,0.6) `60分位`,
       PERCENTILE_CONT(diff_hour,0.7) `70分位`,
       PERCENTILE_CONT(diff_hour,0.8) `80分位`,
       PERCENTILE_CONT(diff_hour,0.9) `90分位`,
       max(diff_hour) `最大值`
FROM
  (SELECT card_type,
          create_time,
          used_time,
          date_diff('minute',date_format(used_time, 'yyyy-MM-dd HH:mm:ss'),date_format(create_time, 'yyyy-MM-dd HH:mm:ss')) AS diff_hour
   FROM dwd.dwd_sr_market_rights_card
   WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-09-14'
     AND card_type in (3,13)
     AND card_status=1) a
group by 1
  ;


-- 新旧大牌券发放和使用
SELECT date_format(create_time,'%Y-%m-%d') `发放日期`,
       if(card_type=3,'旧','新') `大牌券类型`,
       count(1) `大牌券发放量`,
       sum(if(card_status=1,1,0)) `大牌券使用量`
FROM dwd.dwd_sr_market_rights_card
WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-09-22'
  AND card_type IN (3,
                    13)
GROUP BY 1,
         2;


SELECT date_format(create_time,'%Y-%m-%d') `发放日期`,
       sum(if(card_type=3,1,0)) `旧大牌券发放量`,
       sum(if(card_type=3
              AND card_status=1,1,0)) `旧大牌券使用量`,
       sum(if(card_type=13,1,0)) `新大牌券发放量`,
       sum(if(card_type=13
              AND card_status=1,1,0)) `新大牌券使用量`
FROM dwd.dwd_sr_market_rights_card
WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-09-22'
  AND card_type IN (3,
                    13)
GROUP BY 1;



-- 定向大牌券花费
SELECT 
-- order_id,
-- right(order_id,9) oid
 sum(real_rebate_amt) rebate_amt
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-09-16' AND '2025-09-22'
  AND order_status IN (2,
                       8)
  AND order_type=14 ;


-- 旧大牌券使用
SELECT `使用日期`,
       `大牌券类型`,
       `大牌券使用量`,
       cost_amt `花费`
FROM
  (SELECT date_format(used_time,'%Y-%m-%d') `使用日期`,
          '旧' `大牌券类型`,
              sum(if(card_status=1,1,0)) `大牌券使用量`
   FROM dwd.dwd_sr_market_rights_card
   WHERE date_format(used_time,'%Y-%m-%d') BETWEEN '2025-08-16' AND '2025-09-22'
     AND card_type=3
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT statistics_date,
          cost_amt
   FROM ads.ads_sr_marketing_cost_d
   WHERE statistics_date BETWEEN '2025-08-16' AND '2025-09-22'
     AND cost_typename='大牌券') b ON a.`使用日期`=b.statistics_date ;






