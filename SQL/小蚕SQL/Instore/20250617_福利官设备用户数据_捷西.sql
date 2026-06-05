-- 有多次绑定记录，取最近一次
WITH t1 AS
  (SELECT user_id,
          create_date,
          bind_interior_staff_wework_id,
          bind_interior_staff_wework_account
   FROM
     (SELECT user_id,
             date(create_time) AS create_date,
             bind_interior_staff_wework_account,
             bind_interior_staff_wework_id,
             row_number() over(partition BY user_id
                               ORDER BY create_time DESC) AS rk
      FROM dwd.dwd_sr_silkworm_explore_bind_wework_record
      WHERE status=1) a
   WHERE rk=1),

-- 外卖订单量
t2 AS
  (SELECT user_id,
          count(1) wm_valid_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND order_status IN (2,
                          8)
   GROUP BY 1),

-- 到店支付订单量
t3 AS
  (SELECT user_id,
          sum(if(date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
                 AND promotion_type IN (1,4),0,1)) AS exp_pay_order_num,
          sum(if(date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
                 AND promotion_type IN (5,6,8),0,1)) AS bar_pay_order_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND promotion_type IN (1,
                            4,
                            5,
                            6,
                            8)
     AND (store_name NOT regexp '测试'
          OR store_promotion_name NOT regexp '测试'
          OR user_id<>329118405)
   GROUP BY 1),

-- 用户报名
 t4 AS
  (SELECT user_id
   FROM dwd.dwd_sr_order_promotion_order
   GROUP BY 1
   UNION SELECT user_id
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE promotion_type IN (1,
                            4,
                            5,
                            6,
                            8)
     AND (store_name NOT regexp '测试'
          OR store_promotion_name NOT regexp '测试'
          OR user_id<>329118405)
   GROUP BY 1),
-- 近30天用户报名

 t5 AS
  (SELECT user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
   GROUP BY 1
   UNION SELECT user_id
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND promotion_type IN (1,
                            4,
                            5,
                            6,
                            8)
     AND (store_name NOT regexp '测试'
          OR store_promotion_name NOT regexp '测试'
          OR user_id<>329118405)
   GROUP BY 1)




SELECT bind_interior_staff_wework_id `绑定企微ID`,
       count(distinct t1.user_id) `绑定用户数`,
       count(distinct if(t2.wm_valid_order_num>1,t1.user_id,NULL)) `近30天外卖完单用户数`,
       count(distinct if(t3.exp_pay_order_num>=1,t1.user_id,NULL)) `近30天探店支付用户数`,
       count(distinct if(t3.bar_pay_order_num>=1,t1.user_id,NULL)) `近30天砍价支付用户数`,
       count(distinct if(t4.user_id IS NULL,t1.user_id,NULL)) `从未下单用户数`,
       count(distinct if(t4.user_id IS NOT NULL
                         AND t5.user_id IS NULL,t1.user_id,NULL)) `下过单且近30天未下单用户数`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
LEFT JOIN t3 ON t1.user_id=t3.user_id
LEFT JOIN t4 ON t1.user_id=t4.user_id
LEFT JOIN t5 ON t1.user_id=t5.user_id
GROUP BY 1;




======== 企微ID名称
WITH t1 AS
  (SELECT user_id,
          create_date,
          bind_interior_staff_wework_id
   FROM
     (SELECT user_id,
             date(create_time) AS create_date,
             bind_interior_staff_wework_id,
             row_number() over(partition BY user_id
                               ORDER BY create_time DESC) AS rk
      FROM dwd.dwd_sr_silkworm_explore_bind_wework_record
      WHERE status=1) a
   WHERE rk=1)

select
bind_interior_staff_wework_id,
wework_name
from t1
left join
(select user_id,wework_name
from dim.dim_silkworm_explore_daren_cleanse
) a on t1.user_id=a.user_id
group by 1,2



