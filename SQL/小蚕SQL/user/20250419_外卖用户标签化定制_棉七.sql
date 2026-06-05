


============ part1 用户消费水平分布


-- 霸王餐支付金额均值和标准差
-- 每次取支付金额时，都要根据需要执行该逻辑，为后续剔除异常值准备
SELECT stddev(user_pay_amt) std_pay_amt, -- 标准差 28.14
       avg(user_pay_amt) avg_pay_amt -- 均值 25.6
FROM dwd.dwd_sr_order_promotion_order
WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
  AND date_format(order_time,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
  AND order_status IN (2,
                       8)
;

-- 剔除25725笔支付金额异常订单
-- select
--     count(1) tot,count(if(user_pay_amt>110.02,order_id,null)) cnt
-- from dwd.dwd_sr_order_promotion_order
--    WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
--      AND date_format(order_time,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
--      AND order_status IN (2,
--                           8)
-- ;



-- 消费水平分布（支付金额）
SELECT count(DISTINCT user_id) `用户量`,
       min(pay_amt) `最小值`,
       percentile_cont(pay_amt,0.1) `10分位`,
       percentile_cont(pay_amt,0.2) `20分位`,
       percentile_cont(pay_amt,0.3) `30分位`,
       percentile_cont(pay_amt,0.4) `40分位`,
       percentile_cont(pay_amt,0.5) `50分位`,
       percentile_cont(pay_amt,0.6) `60分位`,
       percentile_cont(pay_amt,0.7) `70分位`,
       percentile_cont(pay_amt,0.8) `80分位`,
       percentile_cont(pay_amt,0.9) `90分位`,
       max(pay_amt) `最大值`
FROM
  (SELECT order_id,
          user_pay_amt pay_amt,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
     AND date_format(order_time,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
     AND order_status IN (2,
                          8)
     and user_pay_amt>=(25.6-3*28.14) and user_pay_amt<=(25.6+3*28.14) -- 剔除异常值
     ) a
;


-- 消费频次分布
SELECT count(DISTINCT user_id) `用户量`,
       min(order_days) `最小值`,
       percentile_cont(order_days,0.1) `10分位`,
       percentile_cont(order_days,0.2) `20分位`,
       percentile_cont(order_days,0.3) `30分位`,
       percentile_cont(order_days,0.4) `40分位`,
       percentile_cont(order_days,0.5) `50分位`,
       percentile_cont(order_days,0.6) `60分位`,
       percentile_cont(order_days,0.7) `70分位`,
       percentile_cont(order_days,0.8) `80分位`,
       percentile_cont(order_days,0.9) `90分位`,
       max(order_days) `最大值`
FROM
  (SELECT user_id,
          count(DISTINCT order_date) order_days
   FROM
     (SELECT date_format(order_time,'%Y-%m-%d') AS order_date,
             user_id
      FROM dwd.dwd_sr_order_promotion_order
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
        AND date_format(order_time,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2) a
   GROUP BY 1) b ;



-- 访问天数分布
SELECT count(DISTINCT user_id) `用户量`,
       min(view_days) `最小值`,
       percentile_cont(view_days,0.1) `10分位`,
       percentile_cont(view_days,0.2) `20分位`,
       percentile_cont(view_days,0.3) `30分位`,
       percentile_cont(view_days,0.4) `40分位`,
       percentile_cont(view_days,0.5) `50分位`,
       percentile_cont(view_days,0.6) `60分位`,
       percentile_cont(view_days,0.7) `70分位`,
       percentile_cont(view_days,0.8) `80分位`,
       percentile_cont(view_days,0.9) `90分位`,
       max(view_days) `最大值`
FROM
  (SELECT user_id,
          count(DISTINCT dat) view_days
   FROM
     (SELECT date_format(dt,'%Y-%m-%d') dat,
             unnest_bitmap AS user_id
      FROM dwd.dwd_sr_traffic_viewuser_d,
           unnest_bitmap(user_ids) AS uid
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
      GROUP BY 1,
               2) a
   GROUP BY 1) b


-- 订单占比分布
SELECT count(DISTINCT user_id) `用户量`,
       min(cancel_order_num) `最小值`,
       percentile_cont(cancel_order_num,0.1) `10分位`,
       percentile_cont(cancel_order_num,0.2) `20分位`,
       percentile_cont(cancel_order_num,0.3) `30分位`,
       percentile_cont(cancel_order_num,0.4) `40分位`,
       percentile_cont(cancel_order_num,0.5) `50分位`,
       percentile_cont(cancel_order_num,0.6) `60分位`,
       percentile_cont(cancel_order_num,0.7) `70分位`,
       percentile_cont(cancel_order_num,0.8) `80分位`,
       percentile_cont(cancel_order_num,0.9) `90分位`,
       max(cancel_order_num) `最大值`,
       min(badcomm_order_num) `最小值`,
       percentile_cont(badcomm_order_num,0.1) `10分位`,
       percentile_cont(badcomm_order_num,0.2) `20分位`,
       percentile_cont(badcomm_order_num,0.3) `30分位`,
       percentile_cont(badcomm_order_num,0.4) `40分位`,
       percentile_cont(badcomm_order_num,0.5) `50分位`,
       percentile_cont(badcomm_order_num,0.6) `60分位`,
       percentile_cont(badcomm_order_num,0.7) `70分位`,
       percentile_cont(badcomm_order_num,0.8) `80分位`,
       percentile_cont(badcomm_order_num,0.9) `90分位`,
       max(badcomm_order_num) `最大值`,
       min(cancel_order_rate) `最小值`,
       percentile_cont(cancel_order_rate,0.1) `10分位`,
       percentile_cont(cancel_order_rate,0.2) `20分位`,
       percentile_cont(cancel_order_rate,0.3) `30分位`,
       percentile_cont(cancel_order_rate,0.4) `40分位`,
       percentile_cont(cancel_order_rate,0.5) `50分位`,
       percentile_cont(cancel_order_rate,0.6) `60分位`,
       percentile_cont(cancel_order_rate,0.7) `70分位`,
       percentile_cont(cancel_order_rate,0.8) `80分位`,
       percentile_cont(cancel_order_rate,0.9) `90分位`,
       max(cancel_order_rate) `最大值`,
       min(badcomm_order_rate) `最小值`,
       percentile_cont(badcomm_order_rate,0.1) `10分位`,
       percentile_cont(badcomm_order_rate,0.2) `20分位`,
       percentile_cont(badcomm_order_rate,0.3) `30分位`,
       percentile_cont(badcomm_order_rate,0.4) `40分位`,
       percentile_cont(badcomm_order_rate,0.5) `50分位`,
       percentile_cont(badcomm_order_rate,0.6) `60分位`,
       percentile_cont(badcomm_order_rate,0.7) `70分位`,
       percentile_cont(badcomm_order_rate,0.8) `80分位`,
       percentile_cont(badcomm_order_rate,0.9) `90分位`,
       max(badcomm_order_rate) `最大值`
FROM
  (SELECT user_id,
          count(order_id) order_num,
          count(if(order_status in(4,5),order_id,NULL)) cancel_order_num, -- 取消订单
          count(if(order_status=8,order_id,NULL)) badcomm_order_num,-- 待改进订单
          count(if(order_status in(4,5),order_id,NULL))/count(order_id) cancel_order_rate,
          count(if(order_status=8,order_id,NULL))/count(order_id) badcomm_order_rate
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-01-01' AND date_sub(current_date(),interval 1 DAY)
     AND date_format(order_time,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
   GROUP BY 1) a ;


-- 分小时uv
SELECT view_hr `小时`,
       avg(unum) `访问用下单t户量`
FROM
  (SELECT from_unixtime(cast(event_time AS bigint)/1000,'yyyy-MM-dd') AS view_date,
          hour(from_unixtime(cast(event_time AS bigint)/1000,'yyyy-MM-dd HH:mm:ss')) AS view_hr,
          count(DISTINCT user_id) unum
   FROM ods.ods_sr_event_log
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-04-01' AND '2025-04-18'
     AND user_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2)
GROUP BY 1;








