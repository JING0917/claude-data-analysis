
-- 搜索数据解析
WITH t AS
  (SELECT time,
          event,
          get_json_string(properties,'$.entrance') AS entrance_name,
          get_json_string(properties,'$.search_method') AS search_method,
          get_json_string(properties,'$.city') AS county_id,
          distinct_id AS user_id,
          get_json_string(properties,'$.position') AS location,
          get_json_string(properties,'$.activity_id') AS activity_id,
          get_json_string(properties,'$.query_word') AS keywords,
          get_json_string(properties,'$.platform_type') AS platform_name
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='${T-1}'
     AND event IN ('Search_Click',
                   'Search_Result_Ex',
                   'Search_Result_Click',
                   'Takeaway_Detailpage_View')
     AND distinct_id regexp '^[0-9]{1,10}$'),

-- 清洗t数据集 转换null值 剔除空等
t1 AS
  (SELECT time,
          event,
          CASE
              WHEN entrance_name IN ('首页',
                                     '主页') THEN '首页'
              WHEN entrance_name IS NULL THEN '其他'
              ELSE entrance_name
          END AS entrance_name,
          search_method,
          ifnull(county_id,'999999')county_id,
                                    user_id,
                                    location,
                                    ifnull(activity_id,0) activity_id,
                                                          keywords,
                                                          CASE
                                                              WHEN platform_name regexp '5' THEN 'H5'
                                                              WHEN platform_name IN ('小程序',
                                                                                     '微信小程序') THEN '微信小程序'
                                                              ELSE platform_name
                                                          END platform_name
   FROM t
   WHERE keywords IS NOT NULL
     AND keywords<>''
     AND platform_name IS NOT NULL),

-- 详情页PV
pv_info AS
  (SELECT date_format(a.time,'%Y-%m-%d') search_date,
                                         entrance_name,
                                         search_method,
                                         county_id,
                                         a.user_id,
                                         location,
                                         a.activity_id,
                                         keywords,
                                         a.platform_name,
                                         sum(pv) AS pv
   FROM
     (SELECT time,
             user_id,
             activity_id,
             platform_name,
             count(1) pv
      FROM t
      WHERE event='Takeaway_Detailpage_View'
      GROUP BY 1,
               2,
               3,
               4) a
   LEFT JOIN
     (SELECT time,
             entrance_name,
             search_method,
             county_id,
             user_id,
             location,
             activity_id,
             keywords,
             platform_name
      FROM t
      WHERE event='Search_Result_Click') b ON a.user_id=b.user_id
--    AND a.activity_id=b.activity_id
   AND a.platform_name=b.platform_name
   AND date_diff('second',date_format(a.time,'%Y-%m-%d %H:%i:%s'),date_format(b.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 30
   WHERE b.user_id IS NOT NULL
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9),


-- 搜索结果曝光和点击
t2 AS
  (SELECT a.search_date,
          a.entrance_name,
          a.search_method,
          a.county_id,
          a.user_id,
          a.location,
          a.activity_id,
          a.keywords,
          a.platform_name,
          search_expose_num,
          search_result_click_num,
          pv
   FROM
     (SELECT date_format(time,'%Y-%m-%d') search_date,
                                          entrance_name,
                                          search_method,
                                          county_id,
                                          user_id,
                                          location,
                                          activity_id,
                                          keywords,
                                          platform_name,
                                          count(1) AS search_expose_num
      FROM t1
      WHERE event='Search_Result_Ex'
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6,
               7,
               8,
               9) a
   LEFT JOIN
     (SELECT date_format(time,'%Y-%m-%d') search_date,
                                          entrance_name,
                                          search_method,
                                          county_id,
                                          user_id,
                                          location,
                                          activity_id,
                                          keywords,
                                          platform_name,
                                          count(1) search_result_click_num
      FROM t1
      WHERE event='Search_Result_Click'
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6,
               7,
               8,
               9) b ON a.search_date=b.search_date
   AND a.entrance_name=b.entrance_name
   AND a.search_method=b.search_method
   AND a.county_id=b.county_id
   AND a.user_id=b.user_id
   AND a.location=b.location
   AND a.activity_id=b.activity_id
   AND a.keywords=b.keywords
   AND a.platform_name=b.platform_name
   LEFT JOIN
     (SELECT search_date,
             entrance_name,
             search_method,
             county_id,
             user_id,
             location,
             activity_id,
             keywords,
             platform_name,
             pv
      FROM pv_info) c ON c.search_date=b.search_date
   AND c.entrance_name=b.entrance_name
   AND c.search_method=b.search_method
   AND c.county_id=b.county_id
   AND c.user_id=b.user_id
   AND c.location=b.location
   AND c.activity_id=b.activity_id
   AND c.keywords=b.keywords
   AND c.platform_name=b.platform_name),


 
-- 搜索量+搜索曝光+搜索点击汇总
 t3 AS
  (SELECT search_date,
          entrance_name,
          search_method,
          county_id,
          user_id,
          location,
          activity_id,
          keywords,
          platform_name,
          sum(search_num) search_num,
                          sum(search_expose_num) search_expose_num,
                                                 sum(search_result_click_num) search_result_click_num,
                                                                              sum(pv) pv
   FROM
     (SELECT date_format(time,'%Y-%m-%d') search_date,
                                          entrance_name,
                                          search_method,
                                          county_id,
                                          user_id,
                                          location,
                                          activity_id,
                                          keywords,
                                          platform_name,
                                          count(1) AS search_num,
                                          0 AS search_expose_num,
                                          0 AS search_result_click_num,
                                          0 AS pv
      FROM t1
      WHERE event='Search_Click'
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6,
               7,
               8,
               9
      UNION ALL SELECT search_date,
                       entrance_name,
                       search_method,
                       county_id,
                       user_id,
                       location,
                       activity_id,
                       keywords,
                       platform_name,
                       0 AS search_num,
                       search_expose_num,
                       search_result_click_num,
                       pv
      FROM t2) tot
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9),

-- 搜索场景下单归因 暂不做到店业务订单归因 一是业务上不确定到店是否做搜 二是销单更新周期长 不确定性高 数据更新逻辑暂无好方式处理

-- 外卖订单
 t4 AS
  (SELECT store_promotion_id,
          user_id,
          auto_id,
          order_time,
          order_id,
          order_status,
          profit,
          redpacket_amt
   FROM
     (SELECT store_promotion_id,
             user_id,
             auto_id,
             order_time,
             order_id,
             order_status,
             profit,
             redpacket_amt,
             row_number() over(partition BY user_id,store_promotion_id
                               ORDER BY order_time DESC) rk
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub('${T-1}',interval 1 DAY) AND '${T-1}'
        AND store_promotion_id>0) a
   WHERE rk=1),

-- 最近一次搜索结果点击
latest_clc_info AS
  ( SELECT time,
           entrance_name,
           search_method,
           county_id,
           user_id,
           location,
           activity_id,
           keywords,
           platform_name
   FROM
     (SELECT time,
             entrance_name,
             search_method,
             county_id,
             user_id,
             location,
             activity_id,
             keywords,
             platform_name,
             row_number() over(partition BY entrance_name,search_method,county_id,user_id,keywords
                               ORDER BY time DESC) rk
      FROM t1
      WHERE entrance_name IN ('首页',
                              '主页')
        AND event='Search_Result_Click') a
   WHERE rk=1),


-- 订单归因数据集
 t5 AS
  (SELECT date_format(time,'%Y-%m-%d') search_date,
                                       '首页' entrance_name,
                                            search_method,
                                            county_id,
                                            a.user_id,
                                            a.location,
                                            a.activity_id,
                                            a.keywords,
                                            a.platform_name,
                                            count(DISTINCT t4.auto_id) baoming_order_num,
                                            count(DISTINCT if(t4.order_status IN (2,8),t4.auto_id,NULL)) valid_order_num,
                                            sum(if(t4.order_status=2,t4.profit,0)) profit,
                                            sum(if(t4.order_status=2,t4.redpacket_amt,0)) redpacket_amt
   FROM
     latest_clc_info a
   LEFT JOIN t4 ON a.user_id=t4.user_id
   AND a.activity_id=t4.store_promotion_id
   AND date_diff('second',date_format(t4.order_time,'%Y-%m-%d %H:%i:%s'),date_format(a.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 30
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9)


-- 聚合搜索和外卖订单归因

SELECT t3.search_date,
       t3.entrance_name,
       t3.search_method,
       t3.county_id,
       t3.user_id,
       t3.location,
       t3.activity_id,
       t3.keywords,
       t3.platform_name,
       search_num,
       search_expose_num,
       search_result_click_num,
       pv,
       baoming_order_num,
       valid_order_num,
       profit,
       redpacket_amt
FROM t3
LEFT JOIN t5 ON t3.search_date=t5.search_date
AND t3.entrance_name=t5.entrance_name
AND t3.search_method=t5.search_method
AND t3.county_id=t5.county_id
AND t3.user_id=t5.user_id
AND t3.location=t5.location
AND t3.activity_id=t5.activity_id
AND t3.keywords=t5.keywords
AND t3.platform_name=t5.platform_name ;