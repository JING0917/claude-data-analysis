1、人群下单转化（人群+大盘  人群对大盘增量贡献）
2、人群访问、下单留存（大盘 人群VS大盘）

计划ID 117~120


select * from dim.dim_ma_plan where auto_id in (117,118,119,120); -- 54 55 56 53

select id,count(1) tot,count(distinct user_id) cnt from dim.dim_sr_usergroup_user_id where id in (54,55,56,53) group by 1;

=================================

-- 触达记录
DROP VIEW IF EXISTS takepart_info;


CREATE VIEW IF NOT EXISTS takepart_info (plan_id,plan_name,user_id) AS
  (SELECT a.plan_id,
          b.plan_name,
          a.user_id
   FROM
     (SELECT plan_id,
             user_id
      FROM dwd.dwd_sr_marketing_ma_plan_takepart
      WHERE create_time BETWEEN '2025-05-06 00:00:00' AND '2025-05-14 23:59:59'
        AND date_format(reach_time,'%Y-%m-%d') BETWEEN '2025-05-06' AND '2025-05-14'
        AND plan_id IN (117,
                        118,
                        119,
                        120)
      GROUP BY 1,
               2) a
   INNER JOIN dim.dim_ma_plan b ON a.plan_id=b.auto_id);



-- 霸王餐完单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (order_date,user_id,order_num,profit) AS
  (SELECT date_format(order_time,'%Y-%m-%d') order_date,
                                             user_id,
                                             count(1) order_num,
                                                      sum(IF(order_status=2,profit,0)) profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE ((dt BETWEEN '2025-05-06' AND '2025-05-15') or (dt BETWEEN '2025-04-19' AND '2025-04-28'))
     AND order_status IN (2,
                          8)
   GROUP BY 1,
            2);


-- 浏览
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (dt,user_id) AS
  (SELECT dt,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE ((dt BETWEEN '2025-05-06' AND '2025-05-15')
          OR (dt BETWEEN '2025-04-19' AND '2025-04-28'))
   GROUP BY 1,
            2);


-- 计划转化
DROP VIEW IF EXISTS transfer_info;


CREATE VIEW IF NOT EXISTS transfer_info (plan_id,plan_name,user_id,forder_num) AS
  (SELECT plan_id,
          plan_name,
          a.user_id,
          sum(IF(order_date BETWEEN '2025-04-19' AND '2025-04-28',order_num,0)) forder_num
   FROM takepart_info a
   LEFT JOIN order_info b ON a.user_id=b.user_id
   GROUP BY 1,
            2,
            3 
   HAVING sum(IF(order_date BETWEEN '2025-04-19' AND '2025-04-28',order_num,0))>0);




-- 计划转化
SELECT plan_id `计划ID`,
       plan_name `计划名称`,
       count(DISTINCT a.user_id) `触达用户量`,
       count(distinct if(order_date between '2025-04-19' AND '2025-04-28' and c.user_id is null,a.user_id,null)) `触达前完单用户量`,
       sum(if(order_date between '2025-04-19' AND '2025-04-28' and c.user_id is null,order_num,0)) `触达前完单量`,
       sum(if(order_date between '2025-04-19' AND '2025-04-28' and c.user_id is null,profit,0)) `触达前完单利润`,
       count(distinct if(order_date between '2025-05-06' AND '2025-05-15' and c.user_id is null,a.user_id,null)) `触达后完单用户量`,
       sum(if(order_date between '2025-05-06' AND '2025-05-15' and c.user_id is null,order_num,0)) `触达后完单量`,
       sum(if(order_date between '2025-05-06' AND '2025-05-15' and c.user_id is null,profit,0)) `触达后完单利润`
FROM takepart_info a
LEFT JOIN order_info b ON a.user_id=b.user_id
left join transfer_info c on a.plan_id=c.plan_id and a.user_id=c.user_id
GROUP BY 1,
         2;


-- 大盘
SELECT count(DISTINCT user_id) `触达用户量`,
       count(DISTINCT if(order_date BETWEEN '2025-04-19' AND '2025-04-28',user_id,NULL)) `触达前完单用户量`,
       sum(if(order_date BETWEEN '2025-04-19' AND '2025-04-28',order_num,0)) `触达前完单量`,
       sum(if(order_date BETWEEN '2025-04-19' AND '2025-04-28',profit,0)) `触达前完单利润`,
       count(DISTINCT if(order_date BETWEEN '2025-05-06' AND '2025-05-15',user_id,NULL)) `触达后完单用户量`,
       sum(if(order_date BETWEEN '2025-05-06' AND '2025-05-15',order_num,0)) `触达后完单量`,
       sum(if(order_date BETWEEN '2025-05-06' AND '2025-05-15',profit,0)) `触达后完单利润`
FROM order_info;


-- 访问留存
SELECT a.plan_id `计划ID`,
       a.plan_name `计划名称`,
       b.dt `访问日期`,
       count(DISTINCT if(d.user_id IS NULL,a.user_id,NULL)) `访问用户量`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=1
                         AND d.user_id IS NULL,a.user_id,NULL)) `次日访问留存`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=2
                         AND d.user_id IS NULL,a.user_id,NULL)) `2日访问留存`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=3
                         AND d.user_id IS NULL,a.user_id,NULL)) `3日访问留存`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=4
                         AND d.user_id IS NULL,a.user_id,NULL)) `4日访问留存`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=5
                         AND d.user_id IS NULL,a.user_id,NULL)) `5日访问留存`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=6
                         AND d.user_id IS NULL,a.user_id,NULL)) `6日访问留存`,
       count(DISTINCT if(date_diff('day',c.dt,b.dt)=7
                         AND d.user_id IS NULL,a.user_id,NULL)) `7日访问留存`
FROM takepart_info a
LEFT JOIN view_info b ON a.user_id=b.user_id
LEFT JOIN view_info c ON b.user_id=c.user_id
LEFT JOIN transfer_info d ON a.plan_id=d.plan_id
AND a.user_id=d.user_id
GROUP BY 1,
         2,
         3;


-- 大盘留存
SELECT a.dt `访问日期`,
       count(DISTINCT a.user_id) `访问用户量`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=1,a.user_id,NULL)) `次日访问留存`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=2,a.user_id,NULL)) `2日访问留存`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=3,a.user_id,NULL)) `3日访问留存`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=4,a.user_id,NULL)) `4日访问留存`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=5,a.user_id,NULL)) `5日访问留存`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=6,a.user_id,NULL)) `6日访问留存`,
       count(DISTINCT if(date_diff('day',b.dt,a.dt)=7,a.user_id,NULL)) `7日访问留存`
FROM view_info a
LEFT JOIN view_info b ON a.user_id=b.user_id
GROUP BY 1;



-- 下单留存
SELECT a.plan_id `计划ID`,
       a.plan_name `计划名称`,
       b.order_date `下单日期`,
       count(DISTINCT if(d.user_id is null,a.user_id,null)) `完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=1 and d.user_id is null,a.user_id,NULL)) `次日留存完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=2 and d.user_id is null,a.user_id,NULL)) `2日留存完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=3 and d.user_id is null,a.user_id,NULL)) `3日留存完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=4 and d.user_id is null,a.user_id,NULL)) `4日留存完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=5 and d.user_id is null,a.user_id,NULL)) `5日留存完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=6 and d.user_id is null,a.user_id,NULL)) `6日留存完单用户量`,
       count(DISTINCT if(date_diff('day',c.order_date,b.order_date)=7 and d.user_id is null,a.user_id,NULL)) `7日留存完单用户量`
FROM takepart_info a
LEFT JOIN order_info b ON a.user_id=b.user_id
LEFT JOIN order_info c ON b.user_id=c.user_id
LEFT JOIN transfer_info d ON a.plan_id=d.plan_id
AND a.user_id=d.user_id
GROUP BY 1,
         2,
         3;


-- 大盘留存
SELECT a.order_date `下单日期`,
       count(DISTINCT a.user_id) `完单用户量`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=1,a.user_id,NULL)) `次日完单留存`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=2,a.user_id,NULL)) `2日完单留存`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=3,a.user_id,NULL)) `3日完单留存`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=4,a.user_id,NULL)) `4日完单留存`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=5,a.user_id,NULL)) `5日完单留存`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=6,a.user_id,NULL)) `6日完单留存`,
       count(DISTINCT if(date_diff('day',b.order_date,a.order_date)=7,a.user_id,NULL)) `7日完单留存`
FROM order_info a
LEFT JOIN order_info b ON a.user_id=b.user_id
GROUP BY 1;



================ 计划ID：134 转化
-- 触达记录
DROP VIEW IF EXISTS takepart_info;


CREATE VIEW IF NOT EXISTS takepart_info (plan_id,plan_name,user_id) AS
  (SELECT a.plan_id,
          b.plan_name,
          a.user_id
   FROM
     (SELECT plan_id,
             user_id
      FROM dwd.dwd_sr_marketing_ma_plan_takepart
      WHERE create_time BETWEEN '2025-05-14 00:00:00' AND '2025-05-14 23:59:59'
        AND date_format(reach_time,'%Y-%m-%d')='2025-05-14'
        AND plan_id=134
      GROUP BY 1,
               2) a
   INNER JOIN dim.dim_ma_plan b ON a.plan_id=b.auto_id);

-- 霸王餐完单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (order_date,user_id,order_num,pay_amt,profit) AS
  (SELECT date_format(order_time,'%Y-%m-%d') order_date,
                                             user_id,
                                             count(1) order_num,
                                             sum(user_pay_amt) pay_amt,
                                                      sum(IF(order_status=2,profit,0)) profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt='2025-05-14'
     AND order_status IN (2,
                          8)
    and store_platform_type=3 -- 京东
   GROUP BY 1,
            2);


-- 浏览
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (dt,user_id) AS
  (SELECT dt,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt='2025-05-14'
   and event_ename='Arrivehome_Topicpages_Ex'
   GROUP BY 1,
            2);


select
    plan_id `计划ID`,
    plan_name `计划名称`,
    count(distinct a.user_id) `触达用户量`,
    count(distinct if(b.user_id is not null,a.user_id,null)) `曝光用户量`,
    count(distinct if(c.user_id is not null,a.user_id,null)) `完单用户量`,
    sum(if(c.user_id is not null,c.order_num,0)) `完单量`,
    sum(if(c.user_id is not null,c.pay_amt,0)) `支付金额`,
    sum(if(c.user_id is not null,c.profit,0)) `完单利润`
from takepart_info a left join view_info b on a.user_id=b.user_id
left join order_info c on b.user_id=c.user_id
group by 1,2;












