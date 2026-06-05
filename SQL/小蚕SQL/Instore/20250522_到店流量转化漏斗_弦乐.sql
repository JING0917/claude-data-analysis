HomePage_Bargain_Show   到店霸王餐模块曝光
HomePage_Bargain_Click  到店霸王餐模块点击
HomePage_Visitstore_Show    0元探店模块曝光
HomePage_Visitstore_Click   0元探店模块点击
StoreDiscovery_Activity_Ex 探店主页活动曝光
StoreDiscovery_Activity_Click 探店主页活动点击
StoreDiscovery_Activity_Details_View 探店活动详情页浏览
StoreDiscovery_Activity_Details_GrabOrder_Click 探店活动详情页抢单按钮点击
StoreDiscovery_Activity_Details_Cancel_Click 探店活动详情页取消报名按钮点击
StoreDiscovery_OrderProcess_Verification_Click 探店订单流程核销点击
StoreDiscovery_OrderProcess_Submit_Click 探店订单流程提交订单点击





=============== part1 探店
-- 流量
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (event_date,event_name,user_id) AS
  (SELECT from_unixtime(cast(event_time AS bigint)/1000,'yyyy-MM-dd') AS event_date,
          event_name,
          user_id
   FROM ods.ods_sr_event_log
   WHERE dt BETWEEN '2025-05-11' AND date_sub(current_date(),interval 1 DAY)
     AND event_name IN ('StoreDiscovery_Activity_Ex',
                        'StoreDiscovery_Activity_Click',
                        'StoreDiscovery_Activity_Details_View',
                        'StoreDiscovery_Activity_Details_GrabOrder_Click',
                        'StoreDiscovery_Activity_Details_Cancel_Click',
                        'StoreDiscovery_OrderProcess_Verification_Click',
                        'StoreDiscovery_OrderProcess_Submit_Click' )
     AND user_id regexp '^[0-9]{1,10}$');



-- 订单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (dt,user_id) AS
  (SELECT dt,
          user_id
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN '2025-05-11' AND date_sub(current_date(),interval 1 DAY)
    and promotion_type in (1,4)
   GROUP BY 1,
            2 );


SELECT a.event_date,
       sum(if(a.event_name='StoreDiscovery_Activity_Ex',1,0)) `探店主页活动曝光量`,
       count(DISTINCT if(a.event_name='StoreDiscovery_Activity_Ex',a.user_id,NULL)) `探店主页活动曝光UV`,
       sum(if(b.event_name='StoreDiscovery_Activity_Click',1,0)) `探店主页活动点击量`,
       count(DISTINCT if(b.event_name='StoreDiscovery_Activity_Click',b.user_id,NULL)) `探店主页活动点击UV`,
       sum(if(c.event_name='StoreDiscovery_Activity_Details_View',1,0)) `探店活动详情页PV`,
       count(DISTINCT if(c.event_name='StoreDiscovery_Activity_Details_View',c.user_id,NULL)) `探店活动详情页UV`,
       sum(if(d.event_name='StoreDiscovery_Activity_Details_GrabOrder_Click',1,0)) `探店活动详情页抢单按钮点击量`,
       count(DISTINCT if(d.event_name='StoreDiscovery_Activity_Details_GrabOrder_Click',d.user_id,NULL)) `探店活动详情页抢单按钮点击UV`,
       sum(if(e.event_name='StoreDiscovery_Activity_Details_Cancel_Click',1,0)) `探店活动详情页取消报名按钮点击量`,
       count(DISTINCT if(e.event_name='StoreDiscovery_Activity_Details_Cancel_Click',e.user_id,NULL)) `探店活动详情页取消报名按钮点击UV`,
       sum(if(f.event_name='StoreDiscovery_OrderProcess_Verification_Click',1,0)) `探店订单流程核销点击量`,
       count(DISTINCT if(f.event_name='StoreDiscovery_OrderProcess_Verification_Click',f.user_id,NULL)) `探店订单流程核销点击UV`,
       sum(if(g.event_name='StoreDiscovery_OrderProcess_Submit_Click',1,0)) `探店订单流程提交订单点击量`,
       count(DISTINCT if(g.event_name='StoreDiscovery_OrderProcess_Submit_Click',g.user_id,NULL)) `探店订单流程提交订单点击UV`,
       count(DISTINCT if(h.user_id IS NOT NULL,a.user_id,NULL)) `探店报名用户量`
FROM
  (SELECT event_date,user_id,event_name
   FROM view_info
   WHERE event_name='StoreDiscovery_Activity_Ex' group by 1,2,3) a
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_Activity_Click' group by 1,2,3) b ON a.event_date=b.event_date AND a.user_id=b.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_Activity_Details_View' group by 1,2,3) c ON b.event_date=c.event_date AND b.user_id=c.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_Activity_Details_GrabOrder_Click' group by 1,2,3) d ON b.event_date=d.event_date AND b.user_id=d.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_Activity_Details_Cancel_Click' group by 1,2,3) e ON b.event_date=e.event_date AND b.user_id=e.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_OrderProcess_Verification_Click' group by 1,2,3) f ON b.event_date=f.event_date AND b.user_id=f.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_OrderProcess_Submit_Click' group by 1,2,3) g ON b.event_date=g.event_date AND b.user_id=g.user_id
LEFT JOIN order_info h ON a.event_date=h.dt AND a.user_id=h.user_id
GROUP BY 1;


=================== part2 砍价
-- 流量
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (event_date,event_name,user_id,activity_type) AS
  (SELECT from_unixtime(cast(event_time AS bigint)/1000,'yyyy-MM-dd') AS event_date,
          event_name,
          user_id,
          get_json_string(data,'$.activity_type') as activity_type -- 值是5,6,砍价活动
   FROM ods.ods_sr_event_log
   WHERE dt BETWEEN '2025-05-11' AND date_sub(current_date(),interval 1 DAY)
     AND event_name IN ('Bargain_HomePage_takeout_Activity_ex', -- 砍价首页曝光
                        'Bargain_Activity_Details_Ex', -- 砍价详情页曝光
                        'Bargain_Button_Click', -- 砍价按钮点击
                        'StoreDiscovery_Activity_Details_GrabOrder_Click', -- 活动详情页抢购按钮点击
                        'Bargain_Order_Pay', -- 砍价订单支付
                        'Bargain_Order_Cancel_Success' -- 取消订单成功
                        )
     AND user_id regexp '^[0-9]{1,10}$');



-- 订单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (dt,user_id) AS
  (SELECT dt,
          user_id
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN '2025-05-11' AND date_sub(current_date(),interval 1 DAY)
    and promotion_type in (5,6)
   GROUP BY 1,
            2 );


SELECT a.event_date,
       sum(if(a.event_name='Bargain_HomePage_takeout_Activity_ex',1,0)) `砍价主页活动曝光量`,
       count(DISTINCT if(a.event_name='Bargain_HomePage_takeout_Activity_ex',a.user_id,NULL)) `砍价主页活动曝光UV`,
       sum(if(b.event_name='Bargain_Activity_Details_Ex',1,0)) `砍价活动详情页PV`,
       count(DISTINCT if(b.event_name='Bargain_Activity_Details_Ex',b.user_id,NULL)) `砍价活动详情页UV`,
       sum(if(c.event_name='Bargain_Button_Click',1,0)) `砍价活动详情页砍价按钮点击量`,
       count(DISTINCT if(c.event_name='Bargain_Button_Click',c.user_id,NULL)) `砍价活动详情页砍价按钮点击UV`,
       sum(if(d.event_name='StoreDiscovery_Activity_Details_GrabOrder_Click',1,0)) `砍价活动详情页抢购按钮点击量`,
       count(DISTINCT if(d.event_name='StoreDiscovery_Activity_Details_GrabOrder_Click',d.user_id,NULL)) `探店活动详情页抢单按钮点击UV`,
       sum(if(e.event_name='Bargain_Order_Pay',1,0)) `砍价订单支付按钮点击量`,
       count(DISTINCT if(e.event_name='Bargain_Order_Pay',e.user_id,NULL)) `砍价订单支付按钮点击UV`,
       sum(if(f.event_name='Bargain_Order_Cancel_Success',1,0)) `砍价取消订单成功按钮点击量`,
       count(DISTINCT if(f.event_name='Bargain_Order_Cancel_Success',f.user_id,NULL)) `砍价取消订单成功按钮点击UV`,
       count(DISTINCT if(h.user_id IS NOT NULL,a.user_id,NULL)) `砍价报名用户量`
FROM
  (SELECT event_date,user_id,event_name
   FROM view_info
   WHERE event_name='Bargain_HomePage_takeout_Activity_ex' group by 1,2,3) a
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='Bargain_Activity_Details_Ex' group by 1,2,3) b ON a.event_date=b.event_date AND a.user_id=b.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='Bargain_Button_Click' group by 1,2,3) c ON b.event_date=c.event_date AND b.user_id=c.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='StoreDiscovery_Activity_Details_GrabOrder_Click' and activity_type='砍价活动' group by 1,2,3) d ON b.event_date=d.event_date AND b.user_id=d.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='Bargain_Order_Pay' group by 1,2,3) e ON b.event_date=e.event_date AND b.user_id=e.user_id
LEFT JOIN (select event_date,user_id,event_name from view_info where event_name='Bargain_Order_Cancel_Success' group by 1,2,3) f ON b.event_date=f.event_date AND b.user_id=f.user_id
LEFT JOIN order_info h ON a.event_date=h.dt AND a.user_id=h.user_id
GROUP BY 1;






























