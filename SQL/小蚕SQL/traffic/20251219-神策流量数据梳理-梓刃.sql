

---- 目标：区分每日、业务线、漏斗环节（识别总uv，详情页uv）

WITH f1 AS
  (SELECT left(time, 10) AS dt,
          business_name,
          distinct_id AS user_id,
          event,
          CASE
              WHEN lower(event) LIKE '%homepage%'
                   OR event IN ('Bargain_Activity_Details_Ex',
                                'StoreDiscovery_Activity_Details_Ex') THEN '首页浏览'
              WHEN lower(event) LIKE '%detail%view%' THEN '详情页浏览'
              ELSE ''
          END AS page_type,
          platform_type,
          activity_id AS promotion_id
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE left(time, 10) = '2025-12-16'
     AND distinct_id regexp '^[0-9]{1,10}$'
     AND ((business_name = '外卖'
           AND event IN ('HomePage_View',
                         'Homepage_View',
                         'Takeaway_Detailpage_View' ,
                         'Takeout_Activity_Detail_View',
                         'Homepage_Headpic_Ex' ))
          OR (business_name IN ('探店',
                                '砍价')
              AND event IN ('Instore_Homepage_View',
                            'Instore_Detailpage_View' ,
                            'Instore_Homepage_Feed_Activity_Ex',
                            'Bargain_Activity_Details_View',
                            'Bargain_Activity_Details_Ex',
                            'StoreDiscovery_Activity_Details_View',
                            'StoreDiscovery_Activity_Details_Ex'))))

SELECT business_name,
       page_type,
       count(DISTINCT user_id) AS uv
FROM f1
GROUP BY 1,
         2 ;