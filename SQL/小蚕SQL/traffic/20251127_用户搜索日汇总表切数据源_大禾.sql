--JDBC SQL
--******************************************************************--
--author: xiaoda
--create time: 2024-10-28 11:10:30
--******************************************************************--
-- drop table dws.dws_sr_traffic_search_user_d;

CREATE TABLE IF NOT EXISTS dws.dws_sr_traffic_search_user_d
(
    `search_date` date comment '搜索时间',
    `entrance_name` String COMMENT '主页、0元探店',
    `county_id` String COMMENT '区县id',
    `user_id` String COMMENT '用户id',
    `location` String COMMENT '当前页面',
    `activity_id` String COMMENT '活动ID',
    `keywords` String COMMENT '检索内容',
    `platform_name` String COMMENT '平台名称',
    `search_num` INT COMMENT '搜索量',--主页搜索点击
    `search_expose_num` INT COMMENT '搜索曝光量', --主页搜索活动曝光
    `search_result_click_num` INT COMMENT '搜索结果点击量'--主页搜索结果点击
)
ENGINE=OLAP
COMMENT '用户搜索事件日表'
PARTITION BY date_trunc('day', search_date)
DISTRIBUTED BY HASH(search_date,entrance_name,county_id,user_id,location,activity_id,keywords,platform_name)
PROPERTIES (
"replication_num" ="2"
);



-- 替换日志表
INSERT into  dws.dws_sr_traffic_search_user_d 

-- select 
-- search_date,
-- entrance_name,
-- county_id,
-- user_id,
-- location,
-- activity_id,
-- keywords,
-- platform_name,
-- sum(search_num) as search_num,
-- sum(search_expose_num) as search_expose_num,
-- sum(search_result_click_num) as search_result_click_num
-- from
-- (
-- SELECT
--     dt AS search_date,
--     '主页' as entrance_name,
--     county_id,
--     user_id,
--     0 as location,
--     0 as activity_id,
--     COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) as keywords,
--     platform_name,
--     0 AS search_result_click_num, 
--     0 AS search_expose_num, 
--     COUNT(1) AS search_num
-- FROM
--     ods.ods_sr_event_log
-- WHERE
-- dt='${T-1}'
-- --   dt IN ('${T-1}', '${T-2}') 
--     -- AND 
--     -- user_id regexp '^[0-9]{1,9}$'
--     -- AND event_name = 'Homepage_Search_Click'
--     AND event_name in ('Homepage_Search_Click','Search_Entry_Direct_Search','Historical_Search_Click','Search_Discovery_Click','Intelligence_Activity_Id_Click')
-- GROUP BY
--     platform_name,'主页', user_id, county_id,  COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) ,dt


-- UNION ALL

-- SELECT
--     dt AS search_date,
--     '主页',
--     county_id,
--     user_id,
--     get_json_object(parse_json(data), "$.location") as location,
--     get_json_object(parse_json(data), "$.activity_id") as activity_id,
--     COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) as keywords,
--     platform_name,
--     0 AS field3, COUNT(1) AS field4, 0 AS field5
-- FROM
--     ods.ods_sr_event_log
-- WHERE
--  dt='${T-1}'
-- --   dt IN ('${T-1}', '${T-2}') 
--     -- AND 
--     -- user_id regexp '^[0-9]{1,9}$'
--     -- AND event_name = 'Homepage_Search_Activity_Ex'
--     AND event_name in ('Homepage_Search_Activity_Ex','Search_Result_Impression','Search_No_Result_Impression')
-- GROUP BY
--     platform_name,'主页', user_id, county_id, get_json_object(parse_json(data), "$.activity_id"), COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")),  get_json_object(parse_json(data), "$.location"),dt


-- UNION ALL

-- SELECT
--     dt,
--     '主页',
--     county_id,
--     user_id,
--     get_json_object(parse_json(data), "$.location") as location,
--    get_json_object(parse_json(data), "$.activity_id") as activity_id,
--     COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) as keywords,
--     platform_name,
--     COUNT(1) AS field3, 0 AS field4, 0 AS field5
-- FROM
--     ods.ods_sr_event_log
-- WHERE
-- dt='${T-1}'

--  --   dt IN ('${T-1}', '${T-2}') 
--     --  AND 
--     -- user_id regexp '^[0-9]{1,9}$'
--     -- AND event_name = 'Homepage_Search_Result_Click'
--     AND event_name in ('Homepage_Search_Result_Click','Search_Result_Recommended_Click','Search_No_Result_Recommended_Click')
-- GROUP BY
--     platform_name,'主页', user_id, county_id, get_json_object(parse_json(data), "$.activity_id"),  COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")), get_json_object(parse_json(data), "$.location"),dt
-- --到店



-- UNION ALL
-- SELECT
--     dt,
--     '0元探店',
--     county_id,
--     user_id,
--     0,0, 
--     COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) as keywords,
--     platform_name,
--     0 AS field3, 0 AS field4, COUNT(1) AS field5
-- FROM
--     ods.ods_sr_event_log
-- WHERE
-- dt='${T-1}'
-- --   dt IN ('${T-1}', '${T-2}') 
--     -- AND 
--     -- user_id regexp '^[0-9]{1,9}$'
--     AND event_name = 'StoreDiscovery_Search_Click'
    
-- GROUP BY
--     platform_name,'0元探店', user_id, county_id,  COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")),dt


-- UNION ALL
-- SELECT
--     dt AS search_date,
--     '0元探店',
--     county_id,
--     user_id,
--     get_json_object(parse_json(data), "$.location") as location,
--     get_json_object(parse_json(data), "$.activity_id") as activity_id,
--     COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) as keywords,
--     platform_name,
--     0 AS field3, COUNT(1) AS field4, 0 AS field5
-- FROM
--     ods.ods_sr_event_log
-- WHERE
-- dt='${T-1}'
-- --   dt IN ('${T-1}', '${T-2}') 
--     -- AND 
--     -- user_id regexp '^[0-9]{1,9}$'
--     AND event_name = 'StoreDiscovery_Search_Results_Ex'
-- GROUP BY
--     platform_name,'0元探店', user_id, county_id, get_json_object(parse_json(data), "$.activity_id"),  COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")), get_json_object(parse_json(data), "$.location"),dt


-- UNION ALL
-- SELECT
--     dt AS search_date,
--     '0元探店',
--     county_id,
--     user_id,
--     get_json_object(parse_json(data), "$.location") as location,
--    get_json_object(parse_json(data), "$.activity_id") as  activity_id,
--     COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")) as keywords,
--     platform_name,
--     COUNT(1) AS field3, 0 AS field4, 0 AS field5
-- FROM
--     ods.ods_sr_event_log
-- WHERE
-- dt='${T-1}'
-- --   dt IN ('${T-1}', '${T-2}') 
--     -- AND 
--     -- user_id regexp '^[0-9]{1,9}$'
--     AND event_name = 'StoreDiscovery_Search_Results_Click'
-- GROUP BY
--     platform_name,'0元探店', user_id, county_id, get_json_object(parse_json(data), "$.activity_id"),  COALESCE(get_json_object(parse_json(data), "$.search_content"), get_json_object(parse_json(data), "$.search_word")), get_json_object(parse_json(data), "$.location"),dt
-- ) tt
-- group BY
-- search_date,
-- entrance_name,
-- county_id,
-- user_id,
-- location,
-- activity_id,
-- keywords,
-- platform_name


ALTER TABLE dws.dws_sr_traffic_search_user_d
ADD COLUMN search_method VARCHAR(15) comment "搜索方式" AFTER entrance_name;


ALTER TABLE dws.dws_sr_traffic_search_user_d
ADD COLUMN (
   takeaway_baoming_order_num INT DEFAULT 0 comment "外卖报名订单量",
   takeaway_valid_order_num INT DEFAULT 0 comment "外卖有效订单量",
   takeaway_profit decimal(12,2) DEFAULT 0.00 comment "外卖有效订单利润",
   takeaway_redpacket_amt decimal(12,2) DEFAULT 0.00 comment "外卖使用红包金额"
);



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
                   'Search_Result_Click')
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
          search_result_click_num
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
   AND a.platform_name=b.platform_name),


 
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
                                                 sum(search_result_click_num) search_result_click_num
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
                                          0 AS search_result_click_num
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
                       search_result_click_num
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
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('${T-1}',interval 1 day) AND '${T-1}'),


-- 订单归因数据集
 t5 AS
  (SELECT date_format(time,'%Y-%m-%d') search_date,
                                       '首页' entrance_name,
                                            search_method,
                                            county_id,
                                            t1.user_id,
                                            t1.location,
                                            t1.activity_id,
                                            t1.keywords,
                                            t1.platform_name,
                                            count(DISTINCT t4.auto_id) baoming_order_num,
                                                                       count(DISTINCT if(t4.order_status IN (2,8),t4.auto_id,NULL)) valid_order_num,
                                                                                                                                    sum(if(t4.order_status=2,t4.profit,0)) profit,
                                                                                                                                                                           sum(if(t4.order_status=2,t4.redpacket_amt,0)) redpacket_amt
   FROM
     (SELECT time,
             entrance_name,
             search_method,
             county_id,
             user_id,
             location,
             activity_id,
             keywords,
             platform_name
      FROM t1
      WHERE entrance_name IN ('首页',
                              '主页')
        AND event='Search_Result_Click') t1
   LEFT JOIN t4 ON t1.user_id=t4.user_id
   AND t1.activity_id=t4.store_promotion_id
   AND date_diff('second',date_format(t4.order_time,'%Y-%m-%d %H:%i:%s'),date_format(t1.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 30
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
AND t3.platform_name=t5.platform_name 
;



CREATE TABLE `dws_sr_traffic_search_user_d` (
  `search_date` date NULL COMMENT "搜索时间",
  `entrance_name` varchar(65533) NULL COMMENT "主页、0元探店",
  `search_method` varchar(15) NULL COMMENT "搜索方式",
  `county_id` varchar(65533) NULL COMMENT "区县id",
  `user_id` varchar(65533) NULL COMMENT "用户id",
  `location` varchar(65533) NULL COMMENT "当前页面",
  `activity_id` varchar(65533) NULL COMMENT "活动ID",
  `keywords` varchar(65533) NULL COMMENT "检索内容",
  `platform_name` varchar(65533) NULL COMMENT "平台名称",
  `search_num` int(11) NULL COMMENT "搜索量",
  `search_expose_num` int(11) NULL COMMENT "搜索曝光量",
  `search_result_click_num` int(11) NULL COMMENT "搜索结果点击量",
  `takeaway_baoming_order_num` int(11) NULL COMMENT "外卖报名订单量",
  `takeaway_valid_order_num` int(11) NULL COMMENT "外卖有效订单量",
  `takeaway_profit` decimal(12, 2) NULL COMMENT "外卖有效订单利润",
  `takeaway_redpacket_amt` decimal(12, 2) NULL COMMENT "外卖使用红包金额"
) ENGINE=OLAP 
DUPLICATE KEY(`search_date`, `entrance_name`)
COMMENT "用户搜索事件日表"
PARTITION BY date_trunc('day', search_date)
DISTRIBUTED BY HASH(`search_date`, `entrance_name`, `county_id`, `user_id`, `location`, `activity_id`, `keywords`, `platform_name`)
PROPERTIES (
    "compression" = "LZ4",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);










