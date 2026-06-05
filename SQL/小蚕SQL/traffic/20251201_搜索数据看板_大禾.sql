    `search_date` date comment '搜索时间',
    `entrance_name` String COMMENT '主页、0元探店',
    `search_method` VARCHAR(15) comment '搜索方式',
    `county_id` String COMMENT '区县id',
    `user_id` String COMMENT '用户id',
    `location` String COMMENT '当前页面',
    `activity_id` String COMMENT '活动ID',
    `keywords` String COMMENT '检索内容',
    `platform_name` String COMMENT '平台名称',
    `search_num` INT COMMENT '搜索量',
    `search_expose_num` INT COMMENT '搜索曝光量',
    `search_result_click_num` INT COMMENT '搜索结果点击量',
    `takeaway_baoming_order_num` INT COMMENT '外卖报名订单量',
    `takeaway_valid_order_num` INT COMMENT '外卖有效订单量',
    `takeaway_profit` DECIMAL(12,2) COMMENT '外卖有效订单利润',
    `takeaway_redpacket_amt` DECIMAL(12,2) COMMENT '外卖使用红包金额'

            bitmap_agg(if(search_num>0,user_id,NULL)) `搜索用户ids`,
            bitmap_agg(if(search_expose_num>0,user_id,NULL)) `搜索曝光用户ids`,
            bitmap_agg(if(search_result_click_num>0,user_id,NULL)) `搜索结果点击用户ids`,
            bitmap_agg(if(takeaway_baoming_order_num>0,user_id,NULL)) `外卖报名用户ids`,
            bitmap_agg(if(takeaway_valid_order_num>0,user_id,NULL)) `外卖有效用户ids`


SELECT  date(time) dt,
        event,
        get_json_string(properties, '$.city') AS county_id,
        count(1) tot,
        count(distinct distinct_id) uv
FROM    ods.ods_sr_traffic_sensor_event_log_realtime
WHERE   time between '2025-11-30 00:00:00'
and     '2025-11-30 23:59:59'
AND     event IN ('Search_Click', 'Search_Result_Ex', 'Search_Result_Click')
group by 1,
         2,
         3


======== 搜索订单归因
-- -- 搜索数据解析
-- WITH t AS
--   (SELECT time,
--           event,
--           get_json_string(properties,'$.entrance') AS entrance_name,
--           get_json_string(properties,'$.search_method') AS search_method,
--           get_json_string(properties,'$.city') AS county_id,
--           distinct_id AS user_id,
--           get_json_string(properties,'$.position') AS location,
--           get_json_string(properties,'$.activity_id') AS activity_id,
--           get_json_string(properties,'$.query_word') AS keywords,
--           get_json_string(properties,'$.platform_type') AS platform_name
--    FROM ods.ods_sr_traffic_sensor_event_log_realtime
--    WHERE date_format(time,'%Y-%m-%d')='2025-11-30'
--      AND event IN ('Search_Click',
--                    'Search_Result_Ex',
--                    'Search_Result_Click',
--                    'Takeaway_Detailpage_View')
--      AND distinct_id regexp '^[0-9]{1,10}$'),

-- -- 清洗t数据集 转换null值 剔除空等
-- t1 AS
--   (SELECT time,
--           event,
--           CASE
--               WHEN entrance_name IN ('首页',
--                                      '主页') THEN '首页'
--               WHEN entrance_name IS NULL THEN '其他'
--               ELSE entrance_name
--           END AS entrance_name,
--           search_method,
--           ifnull(county_id,'999999')county_id,
--                                     user_id,
--                                     location,
--                                     ifnull(activity_id,0) activity_id,
--                                                           keywords,
--                                                           CASE
--                                                               WHEN platform_name regexp '5' THEN 'H5'
--                                                               WHEN platform_name IN ('小程序',
--                                                                                      '微信小程序') THEN '微信小程序'
--                                                               ELSE platform_name
--                                                           END platform_name
--    FROM t
--    WHERE keywords IS NOT NULL
--      AND keywords<>''
--      AND platform_name IS NOT NULL),


-- -- 外卖订单
--  t4 AS
--   (SELECT store_promotion_id,
--           user_id,
--           auto_id,
--           order_time,
--           order_id,
--           order_status,
--           profit,
--           redpacket_amt
--    FROM
--      (SELECT store_promotion_id,
--              user_id,
--              auto_id,
--              order_time,
--              order_id,
--              order_status,
--              profit,
--              redpacket_amt,
--              row_number() over(partition BY user_id,store_promotion_id
--                                ORDER BY order_time DESC) rk
--       FROM dwd.dwd_sr_order_promotion_order
--       WHERE dt BETWEEN date_sub('2025-11-30',interval 1 DAY) AND '2025-11-30'
--         AND store_promotion_id>0) a
--    WHERE rk=1),

-- -- 最近一次搜索结果点击
-- latest_clc_info AS
--   ( SELECT time,
--            entrance_name,
--            search_method,
--            county_id,
--            user_id,
--            location,
--            activity_id,
--            keywords,
--            platform_name
--    FROM
--      (SELECT time,
--              entrance_name,
--              search_method,
--              county_id,
--              user_id,
--              location,
--              activity_id,
--              keywords,
--              platform_name,
--              row_number() over(partition BY entrance_name,search_method,county_id,user_id,keywords
--                                ORDER BY time DESC) rk
--       FROM t1
--       WHERE entrance_name IN ('首页',
--                               '主页')
--         AND event='Search_Result_Click') a
--    WHERE rk=1),


-- -- 订单归因数据集
--  t5 AS
--   (SELECT date_format(time,'%Y-%m-%d') search_date,
--                                        '首页' entrance_name,
--                                             search_method,
--                                             county_id,
--                                             a.user_id,
--                                             a.location,
--                                             a.activity_id,
--                                             a.keywords,
--                                             a.platform_name,
--                                             count(DISTINCT t4.auto_id) baoming_order_num,
--                                             count(DISTINCT if(t4.order_status IN (2,8),t4.auto_id,NULL)) valid_order_num,
--                                             sum(if(t4.order_status=2,t4.profit,0)) profit,
--                                             sum(if(t4.order_status=2,t4.redpacket_amt,0)) redpacket_amt
--    FROM
--      latest_clc_info a
--    LEFT JOIN t4 ON a.user_id=t4.user_id
--    AND a.activity_id=t4.store_promotion_id
--    AND date_diff('second',date_format(t4.order_time,'%Y-%m-%d %H:%i:%s'),date_format(a.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 30
--    GROUP BY 1,
--             2,
--             3,
--             4,
--             5,
--             6,
--             7,
--             8,
--             9)

-- select
-- search_date,
-- sum(baoming_order_num) baoming_order_num,
-- sum(valid_order_num) valid_order_num,
-- sum(profit) profit,
-- sum(redpacket_amt) redpacket_amt,
-- sum(profit)/sum(valid_order_num) avg_profit
-- from t5
-- group by 1;



============= part 漏斗 整体 分位置
WITH t AS
  (SELECT search_date,
       cast(location AS int) location,
                             sum(search_num) search_num,
                             sum(search_expose_num) search_expose_num,
                             sum(if(search_expose_num>0,search_result_click_num,0)) search_result_click_num,
                             sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) takeaway_baoming_order_num,
                             sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) takeaway_valid_order_num,
                             sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) takeaway_profit,
                             sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) takeaway_redpacket_amt,
                             bitmap_agg(if(search_num>0,user_id,NULL)) search_uids,
                             bitmap_agg(if(search_expose_num>0,user_id,NULL)) search_ex_uids,
                             bitmap_agg(if(search_result_click_num>0,user_id,NULL)) search_clc_uids,
                             bitmap_agg(if(takeaway_baoming_order_num>0,user_id,NULL)) search_bm_uids,
                             bitmap_agg(if(takeaway_valid_order_num>0,user_id,NULL)) search_valid_uids
FROM dws.dws_sr_traffic_search_user_d
WHERE search_date BETWEEN '${begin_date}' AND '${end_date}'
  AND entrance_name='首页'
GROUP BY 1,
         2)

SELECT search_date,
       '整体' location,
            sum(search_num) `搜索量`,
            sum(search_expose_num) `搜索曝光量`,
            sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
            sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
            sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
            sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
            sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
            bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
            bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
            bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
            bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
            bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
GROUP BY 1,
               2
UNION ALL
SELECT search_date,
       'top1' location,
              sum(search_num) `搜索量`,
              sum(search_expose_num) `搜索曝光量`,
              sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
              sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
              sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
              sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
              sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
              bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
              bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
              bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
              bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
              bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
WHERE location=1
GROUP BY 1,
         2
UNION ALL
SELECT search_date,
       'top3' location,
              sum(search_num) `搜索量`,
              sum(search_expose_num) `搜索曝光量`,
              sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
              sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
              sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
              sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
              sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
              bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
              bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
              bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
              bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
              bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
WHERE location BETWEEN 1 AND 3
GROUP BY 1,
         2
UNION ALL
SELECT search_date,
       'top10' location,
               sum(search_num) `搜索量`,
               sum(search_expose_num) `搜索曝光量`,
               sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
               sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
               sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
               sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
               sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
               bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
               bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
               bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
               bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
               bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
WHERE location BETWEEN 1 AND 10
GROUP BY 1,
         2


-- 漏斗
SELECT search_date `搜索日期`,
       sum(search_num) `搜索量`,
       count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
       sum(search_expose_num) `搜索曝光量`,
       count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
       sum(search_result_click_num) `搜索点击量`,
       count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
       sum(takeaway_baoming_order_num) `搜索报名订单量`,
       count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
       sum(takeaway_valid_order_num) `搜索有效订单量`,
       count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
       sum(if(search_num>0
              AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
       count(DISTINCT if(search_num>0
                         AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`
FROM
  (SELECT search_date,
          keywords,
          user_id,
          sum(search_num) search_num,
          sum(search_expose_num) search_expose_num,
          sum(search_result_click_num) search_result_click_num,
          sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
          sum(takeaway_valid_order_num) takeaway_valid_order_num
   FROM dws.dws_sr_traffic_search_user_d
   WHERE search_date BETWEEN '${begin_date}' AND '${end_date}'
     AND entrance_name = '首页'
   GROUP BY 1,
            2,
            3) a
GROUP BY 1;




-- 搜索词云
SELECT 
       keywords `搜索词`,
       avg(`搜索量`) `日均搜索量`,
       avg(`搜索用户量`) `日均搜索用户量`,
       avg(`搜索曝光量`) `日均搜索曝光量`,
       avg(`搜索曝光用户量`) `日均搜索曝光用户量`,
       avg(`搜索点击量`) `日均搜索点击量`,
       avg(`搜索点击用户量`) `日均搜索点击用户量`,
       avg(`搜索报名订单量`) `日均搜索报名订单量`,
       avg(`搜索报名用户量`) `日均搜索报名用户量`,
       avg(`搜索有效订单量`) `日均搜索有效订单量`,
       avg(`搜索有效订单用户量`) `日均搜索有效订单用户量`,
       avg(`无搜索结果搜索量`) `日均无搜索结果搜索量`,
       avg(`无搜索结果搜索用户量`) `日均无搜索结果搜索用户量`
FROM
  (SELECT search_date `搜索日期`,
          keywords,
          sum(search_num) `搜索量`,
          count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
          sum(search_expose_num) `搜索曝光量`,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
          sum(search_result_click_num) `搜索点击量`,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
          sum(takeaway_baoming_order_num) `搜索报名订单量`,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
          sum(takeaway_valid_order_num) `搜索有效订单量`,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
          sum(if(search_num>0
                 AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`
   FROM
     (SELECT search_date,
             keywords,
             user_id,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '${begin_date}' AND '${end_date}'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a
   GROUP BY 1,
            2) b
GROUP BY 1

UNION ALL
SELECT 
       keywords `搜索词`,
       avg(`搜索量`) `日均搜索量`,
       avg(`搜索用户量`) `日均搜索用户量`,
       avg(`搜索曝光量`) `日均搜索曝光量`,
       avg(`搜索曝光用户量`) `日均搜索曝光用户量`,
       avg(`搜索点击量`) `日均搜索点击量`,
       avg(`搜索点击用户量`) `日均搜索点击用户量`,
       avg(`搜索报名订单量`) `日均搜索报名订单量`,
       avg(`搜索报名用户量`) `日均搜索报名用户量`,
       avg(`搜索有效订单量`) `日均搜索有效订单量`,
       avg(`搜索有效订单用户量`) `日均搜索有效订单用户量`,
       avg(`无搜索结果搜索量`) `日均无搜索结果搜索量`,
       avg(`无搜索结果搜索用户量`) `日均无搜索结果搜索用户量`
FROM
  (SELECT search_date `搜索日期`,
          keywords,
          sum(search_num) `搜索量`,
          count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
          sum(search_expose_num) `搜索曝光量`,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
          sum(search_result_click_num) `搜索点击量`,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
          sum(takeaway_baoming_order_num) `搜索报名订单量`,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
          sum(takeaway_valid_order_num) `搜索有效订单量`,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
          sum(if(search_num>0
                 AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`
   FROM
     (SELECT search_date,
             '整体' keywords,
             user_id,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_detailpage_pv) pv,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '${begin_date}' AND '${end_date}'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a
   GROUP BY 1,
            2) b
GROUP BY 1



=================== 活动维度
-- 用户汇总
SELECT search_date `搜索日期`,
       user_type `用户类型`,
       -- activity_id `活动ID`,
       sum(search_num) `搜索量`,
       count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
       sum(search_expose_num) `搜索曝光量`,
       count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
       sum(search_result_click_num) `搜索点击量`,
       count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
       sum(takeaway_baoming_order_num) `搜索报名订单量`,
       count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
       sum(takeaway_valid_order_num) `搜索有效订单量`,
       count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`
FROM
  (SELECT search_date,
          activity_id,
          a.user_id,
          CASE
              WHEN b.accu_valid_order_num>=4 THEN '老用户'
              WHEN b.accu_valid_order_num<4
                   AND b.user_id IS NOT NULL THEN '新用户'
              ELSE '其他'
          END user_type,
          search_num,
          search_expose_num,
          search_result_click_num,
          takeaway_baoming_order_num,
          takeaway_valid_order_num
   FROM
     (SELECT search_date,
             activity_id,
             user_id,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date='2025-11-29'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN dim.dim_silkworm_user b ON a.user_id=cast(b.user_id AS string)) c
GROUP BY 1,
         2;


-- 用户类型汇总
SELECT search_date,
       user_type,
       activity_id,
       sum(search_num) search_num,
       sum(search_expose_num) search_expose_num,
       sum(search_result_click_num) search_result_click_num,
       sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
       sum(takeaway_valid_order_num) takeaway_valid_order_num
FROM
  (SELECT search_date,
          activity_id,
          a.user_id,
          CASE
              WHEN b.accu_valid_order_num>=4 THEN '老用户'
              WHEN b.accu_valid_order_num<4
                   AND b.user_id IS NOT NULL THEN '新用户'
              ELSE '其他'
          END user_type,
          search_num,
          search_expose_num,
          search_result_click_num,
          takeaway_baoming_order_num,
          takeaway_valid_order_num
   FROM
     (SELECT search_date,
             activity_id,
             user_id,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date='2025-11-29'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN dim.dim_silkworm_user b ON a.user_id=cast(b.user_id AS string)) c
GROUP BY 1,
         2,
         3;



-- 店铺维度
SELECT search_date `搜索日期`,
       store_id `店铺ID`,
       store_type `店铺类型`,
       bg_pro_num `曝光活动数`,
       search_expose_num `搜索结果曝光量`,
       search_result_click_num `搜索结果点击量`,
       takeaway_baoming_order_num `搜索报名订单量`,
       takeaway_valid_order_num `搜索有效订单量`
FROM
  (SELECT search_date,
          ifnull(b.store_id,0) store_id,
          CASE
              WHEN c.store_id IS NOT NULL THEN '新店铺'
              WHEN b.store_id IS NOT NULL THEN '老店铺'
              ELSE '其他'
          END store_type,
          count(DISTINCT if(b.store_promotion_id IS NOT NULL,a.activity_id,NULL)) bg_pro_num,
          sum(search_expose_num) search_expose_num,
          sum(search_result_click_num) search_result_click_num,
          sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
          sum(takeaway_valid_order_num) takeaway_valid_order_num
   FROM
     (SELECT search_date,
             activity_id,
             user_id,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '${begin_date}' AND '${end_date}'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN
     (SELECT store_promotion_id,
             store_id
      FROM dwd.dwd_sr_store_promotion
      WHERE begin_date BETWEEN date_sub('${end_date}',interval 14 DAY) AND '${end_date}') b ON a.activity_id=b.store_promotion_id
   LEFT JOIN
     (SELECT store_id
      FROM dws.dws_sr_store_bd_id_first_promotion
      WHERE date_format(first_promotion_time,'%Y-%m-%d') BETWEEN date_sub('${end_date}',interval 7 DAY) AND '${end_date}') c ON b.store_id=c.store_id
   GROUP BY 1,
            2,
            3) d





SELECT search_date `搜索日期`,
       sum(search_num) `搜索量`,
       count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
       sum(search_expose_num) `搜索曝光量`,
       count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
       sum(search_result_click_num) `搜索点击量`,
       count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
       sum(takeaway_baoming_order_num) `搜索报名订单量`,
       count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
       sum(takeaway_valid_order_num) `搜索有效订单量`,
       count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
       sum(if(search_num>0
              AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
       count(DISTINCT if(search_num>0
                         AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`,
       count(DISTINCT if(search_expose_num>0 and length(activity_id)=8,activity_id,null)) `曝光自营活动数`,
       count(DISTINCT if(search_result_click_num>0 and length(activity_id)=8,activity_id,null)) `点击自营活动数`,
       count(DISTINCT if(takeaway_baoming_order_num>0 and length(activity_id)=8,activity_id,null)) `报名自营活动数`
FROM
  (SELECT search_date,
          keywords,
          user_id,
          activity_id,
          sum(search_num) search_num,
          sum(search_expose_num) search_expose_num,
          sum(search_result_click_num) search_result_click_num,
          sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
          sum(takeaway_valid_order_num) takeaway_valid_order_num
   FROM dws.dws_sr_traffic_search_user_d
   WHERE search_date BETWEEN '${begin_date}' AND '${end_date}'
     AND entrance_name = '首页'
   GROUP BY 1,
            2,
            3) a
GROUP BY 1




CREATE TABLE `ods_sr_top_brand_order_realtime` (
  `id` bigint(20) NOT NULL COMMENT "主键ID",
  `created_at` datetime NULL COMMENT "创建时间",
  `updated_at` datetime NULL COMMENT "更新时间",
  `activity_id` int(11) NULL COMMENT "活动id",
  `silk_id` bigint(20) NULL COMMENT "用户id",
  `activity_type` int(11) NULL COMMENT "活动类型 1品牌活动 2单品活动",
  `start_time` int(11) NULL COMMENT "活动开始时间",
  `end_time` int(11) NULL COMMENT "活动结束时间",
  `brand_id` int(11) NULL COMMENT "品牌id",
  `reason` varchar(256) NULL COMMENT "检测失败原因",
  `brand_name` varchar(256) NULL COMMENT "品牌名",
  `goods_id` int(11) NULL COMMENT "商品id",
  `goods_name` varchar(56) NULL COMMENT "商品名",
  `promotion_order_id` bigint(20) NULL COMMENT "小蚕订单号",
  `platform_order_no` varchar(56) NULL COMMENT "平台订单号",
  `min` bigint(20) NULL COMMENT "满减起始金额(满x返y的x)",
  `benefit` bigint(20) NULL COMMENT "满返金额(满x返y的y)",
  `extra_card_id` bigint(20) NULL COMMENT "vip额外返利券id",
  `red_pack_id` bigint(20) NULL COMMENT "使用的红包id",
  `status` int(11) NULL COMMENT "状态 0已报名待下单 1 已取消 2 已完成",
  `platform` int(11) NULL COMMENT "平台 1美团2饿了么3京东",
  `order_time` int(11) NULL COMMENT "下单时间",
  `store_name` varchar(256) NULL COMMENT "店铺名",
  `real_charge` int(11) NULL COMMENT "实付金额",
  `refund` int(11) NULL COMMENT "退款金额"
) ENGINE=OLAP 
PRIMARY KEY(`id`)
COMMENT "大牌券订单表"
DISTRIBUTED BY HASH(`id`)
PROPERTIES (
    "compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "true",
"replicated_storage" = "true",
"replication_num" = "3"
);




















