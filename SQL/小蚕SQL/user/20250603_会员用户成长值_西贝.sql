-- 订单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (user_id,order_score) AS
  (SELECT user_id,
          sum(CASE WHEN profit IS NULL
              OR (profit>0
                  AND profit<=2) THEN 10 
              WHEN profit>2 AND profit<=3 THEN 12
              WHEN profit>3 AND profit<=10 THEN 15 
              WHEN profit>10 THEN 20 ELSE 0 END) order_score
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(),interval 365 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND order_status=2
   GROUP BY 1);


-- 邀请注册
DROP VIEW IF EXISTS user_info;


CREATE VIEW IF NOT EXISTS user_info (user_id,newuser_num) AS
  (SELECT inviter_user_id AS user_id,
          count(1) newuser_num
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 365 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND inviter_user_id<>0
   GROUP BY 1);

 -- 签到

DROP VIEW IF EXISTS sign_info;


CREATE VIEW IF NOT EXISTS sign_info (user_id,checkin_time,date_only,rn,grp) AS
  ( SELECT user_id,
           checkin_time,
           date(checkin_time) AS date_only,
           ROW_NUMBER() OVER (PARTITION BY user_id
                              ORDER BY DATE(checkin_time)) AS rn,
                        DATE_SUB(DATE(checkin_time), INTERVAL ROW_NUMBER() OVER (PARTITION BY user_id
                                                                                 ORDER BY DATE(checkin_time)) DAY) AS grp
   FROM dwd.dwd_sr_market_sign_point
   WHERE dt BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY));


-- 签到分组
DROP VIEW IF EXISTS sign_group;


CREATE VIEW IF NOT EXISTS sign_group (user_id,grp,sign_days) AS
  ( SELECT user_id,
           grp,
           COUNT(*) AS sign_days
   FROM sign_info
   GROUP BY user_id,
            grp);


-- 成长值
DROP VIEW IF EXISTS score_info;


CREATE VIEW IF NOT EXISTS score_info (user_id,user_lvl,order_score,newuser_score,sign_3days_score,sign_7days_score) AS
  (SELECT a.user_id,
          CASE
              WHEN LENGTH(f.bind_interior_staff_wework_account)<2
                   AND a.user_level=1 THEN 0
              WHEN LENGTH(f.bind_interior_staff_wework_account)>2
                   AND a.user_level=1 THEN 1
              ELSE a.user_level
          END user_lvl,
          if(b.user_id is null,0,b.order_score) order_score,
                  IF(c.user_id IS NULL,0,c.newuser_num*3) newuser_score,
                                                          IF(d.user_id IS NOT NULL,
                                                                          2,
                                                                          0) sign_3days_score,
                                                                             IF(e.user_id IS NOT NULL,
                                                                                               6,
                                                                                               0) sign_7days_score
   FROM dim.dim_silkworm_member a
   LEFT JOIN order_info b ON a.user_id=b.user_id
   LEFT JOIN user_info c ON a.user_id=c.user_id
   LEFT JOIN
     (SELECT user_id
      FROM sign_group
      WHERE sign_days >= 3
        AND sign_days < 7
      GROUP BY 1) d ON a.user_id=d.user_id
   LEFT JOIN
     (SELECT user_id
      FROM sign_group
      WHERE sign_days=7
      GROUP BY 1) e ON a.user_id=e.user_id
   LEFT JOIN dim.dim_silkworm_user f ON a.user_id=f.user_id);


select 
    count(distinct if(user_lvl=0,user_id,null)) `V0等级用户量`,
    count(distinct if(user_lvl=1,user_id,null)) `V1等级用户量`,
    count(distinct if(user_lvl=2,user_id,null)) `V2等级用户量`,
    count(distinct if(user_lvl=3,user_id,null)) `V3等级用户量`,
    count(distinct if(user_lvl=4,user_id,null)) `V4等级用户量`,
    count(distinct if(user_lvl=5,user_id,null)) `V5等级用户量`,
    count(distinct if(user_lvl=0 and order_score+newuser_score+sign_3days_score+sign_7days_score<120,user_id,null)) `新V0等级用户量`,
    count(distinct if(user_lvl<>0 and order_score+newuser_score+sign_3days_score+sign_7days_score<120,user_id,null)) `新V1等级用户量`,
    count(distinct if(order_score+newuser_score+sign_3days_score+sign_7days_score>=120 and order_score+newuser_score+sign_3days_score+sign_7days_score<240,user_id,null)) `新V2等级用户量`,
    count(distinct if(order_score+newuser_score+sign_3days_score+sign_7days_score>=240 and order_score+newuser_score+sign_3days_score+sign_7days_score<600,user_id,null)) `新V3等级用户量`,
    count(distinct if(order_score+newuser_score+sign_3days_score+sign_7days_score>=600 and order_score+newuser_score+sign_3days_score+sign_7days_score<1200,user_id,null)) `新V4等级用户量`,
    count(distinct if(order_score+newuser_score+sign_3days_score+sign_7days_score>=1200 and order_score+newuser_score+sign_3days_score+sign_7days_score<3000,user_id,null)) `新V5等级用户量`,
    count(distinct if(order_score+newuser_score+sign_3days_score+sign_7days_score>=3000,user_id,null)) `新V6等级用户量`
from score_info
;