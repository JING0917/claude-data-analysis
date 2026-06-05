================== part1 探查数据
-- 数据量：23,493,333 用户量：2,144,011
SELECT count(1) tot,
       count(DISTINCT user_id) user_num
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-11-01' AND '2025-11-30'
  AND store_promotion_id<>0;

    store_type int comment '店铺类型(0:普通店铺;1:优质店铺;2:大客户)',
    store_brand_type int comment '店铺品牌类型(0:正常类型;1:大牌)',
    delivery_type int comment '配送方式(0:默认方式,美团配送;1:商家自配送)',
    is_threshold int comment '是否有门槛(0:否;1:是)',
    is_need_rating int comment '是否需点评(0:否;1:是)',
    is_virtual int comment '是否虚拟活动(0:否;1:是)',
    is_miaosha int comment '是否秒杀活动(0:否;1:是)',
    is_private int comment '是否私有活动(0:否;1:是)',
    is_vip_exclusive int comment '是否VIP专享活动(0:否;1:是)',
    is_youzhi_promotion int comment '是否优质活动(0:否;1:是)',
    promotion_rebate_type int comment '活动返利类型(0:霸王餐,1:返利餐)',
    mlabel_threshold_amt decimal(12,2) comment '餐标门槛',
    mlabel_rebate_amt decimal(12,2) comment '餐标返现金额',
    mlabel varchar(50) comment '餐标',


================================================================= 这是甚么
-- 以订单为主 天然的把数据过滤 剩下有效数据
-- 日累计订单量 判断当日是否是新用户
-- 571878313 923592157
DROP VIEW IF EXISTS user_order_num;


CREATE VIEW IF NOT EXISTS user_order_num (order_date,user_id,accu_order_num) AS
  (SELECT order_date,
          user_id,
          sum(order_num) over(partition BY user_id
                              ORDER BY order_date) accu_order_num
   FROM
     (SELECT date(order_time) order_date,
                              user_id,
                              count(1) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE order_status IN (2,
                             8)
      GROUP BY 1,
               2) a);


-- 活动品类
DROP VIEW IF EXISTS store_cate;


CREATE VIEW IF NOT EXISTS store_cate (store_id,cate1_name,cate2_name) AS
  (SELECT a.store_id,
          cate1_name,
          cate2_name
   FROM dwd.dwd_sr_order_promotion_order a
   LEFT JOIN
     (SELECT store_id,
             get_json_object( parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category1' ) AS cate1_name,
             get_json_object( parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category2' ) AS cate2_name
FROM dim.dim_silkworm_store) b ON a.store_id=b.store_id
   WHERE a.dt BETWEEN '2025-11-01' AND '2025-11-30'
   GROUP BY 1,
            2,
            3);


-- 是否有重复 无重复
-- SELECT store_id,
--        cate1_name,
--        cate2_name,
--        count(1) tot
-- FROM store_cate
-- GROUP BY 1,
--          2,
--          3 HAVING count(1)>1;

-- 活动曝光


-- 活动报名时剩余名额

-- 是否有待使用红包&红包金额
-- SELECT user_id,begin_time,end_time,redpacket_id,redpacket_value,count(1) tot from dwd.dwd_sr_market_redpack_use_record
-- where business_type=0 and date(begin_time)<='2025-11-01' and date(end_time)>='2025-11-30'
-- and redpacket_value<>0
-- having count(1)>1
-- ;



-- 聚合数据

SELECT 
       date(order_time) order_date,
       hour(order_time) order_hour,
       is_workday,
       a.user_id,
       if(date(order_time)=date(c.register_time),1,0) is_new_register_user,
       if(d.accu_order_num>=4,1,0) is_newuser,
       e.city_name,
       e.county_name,
       ifnull(f.cate1_name,'未知') cate1_name,
       ifnull(f.cate2_name,'未知') cate2_name,
       if(a.rebate_condition_desc IN ('无需反馈|无需任何好评'),0,1) is_rating,
       g.store_type,
       g.store_brand_type,
       g.is_vip_exclusive,
       g.promotion_rebate_type,
       g.mlabel_threshold_amt,
       g.mlabel_rebate_amt,
       g.mlabel,
       g.mlabel_rebate_amt/g.mlabel_threshold_amt rebate_ratio,
       if(a.user_pay_amt<=300,a.user_pay_amt-a.real_rebate_amt,0) ds_price,
       if(h.order_id is not null,1,0) is_use_rdp,
       if(order_status in (2,8),1,0) is_valid_order
FROM dwd.dwd_sr_order_promotion_order a
LEFT JOIN dim.dim_silkworm_date b ON date(a.order_time)=b.current_date_txt
LEFT JOIN dim.dim_silkworm_user c ON date(a.order_time)=date(c.register_time) AND a.user_id=c.user_id
LEFT JOIN user_order_num d ON date(a.order_time)=d.order_date and a.user_id=d.user_id
LEFT JOIN dim.dim_silkworm_county e ON a.county_id=e.county_id
LEFT JOIN store_cate f ON a.store_id=f.store_id
LEFT JOIN dws.dws_sr_store_takeawaypro_statis_d g ON a.store_promotion_id=g.promotion_id
LEFT JOIN dwd.dwd_sr_market_redpack_use_record h ON a.order_id=h.order_id
WHERE a.dt BETWEEN '2025-11-01' AND '2025-11-30'
  AND a.store_promotion_id<>0
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22
;


=========================== 以活动为主
select dt,count(1) tot,count(distinct promotion_id) cnt from dws.dws_sr_store_takeawaypro_statis_d where dt between '2025-11-01' and '2025-11-30' group by 1;

-- 906141行数据
SELECT *
FROM
  (SELECT dt,
          is_workday,
          promotion_id,
          city_name,
          county_name,
          CASE
              WHEN cate1 = 1 THEN '早餐'
              WHEN cate1 = 2 THEN '正餐'
              WHEN cate1 = 3 THEN '下午茶'
              WHEN cate1 = 4 THEN '晚餐'
              WHEN cate1 = 5 THEN '夜宵'
              WHEN cate1 = 6 THEN '零售'
              ELSE '其他'
          END AS cate1_name,
          CASE
              WHEN cate2 = 1 THEN '包子粥铺'
              WHEN cate2 = 2 THEN '快餐简餐'
              WHEN cate2 = 3 THEN '甜品饮品'
              WHEN cate2 = 4 THEN '炸串小吃'
              WHEN cate2 = 5 THEN '火锅烧烤'
              WHEN cate2 = 6 THEN '汉堡西餐'
              WHEN cate2 = 7 THEN '零售'
              WHEN cate2 = 8 THEN '水果鲜花'
              WHEN cate2 = 9 THEN '成人用品'
              ELSE '其他'
          END AS cate2_name,
          store_platform,
          CASE
              WHEN store_type=0 THEN '普通店铺'
              WHEN store_type=1 THEN '优质店铺'
              WHEN store_type=2 THEN '大客户'
              ELSE '其他'
          END store_type,
          if(store_brand_type=0,'非品牌','品牌') store_brand_type,
          is_need_rating,
          promotion_rebate_type,
          mlabel_threshold_amt,
          mlabel_rebate_amt,
          mlabel,
          sum(promotion_quota) promotion_quota,
          sum(ifnull(tot_homepage_activity_expose_num,0)) tot_homepage_activity_expose_num,
          sum(ifnull(tot_search_expose_num,0)) tot_search_expose_num,
          sum(ifnull(tot_homepage_activity_expose_num,0))+sum(ifnull(tot_search_expose_num,0)) tot_expouse_num,
          ifnull(bitmap_union_count(baoming_uids),0) bm_uv,
          sum(ifnull(order_num,0)) order_num,
          ifnull(bitmap_union_count(valid_uids),0) valid_uv,
          sum(ifnull(valid_order_num,0)) valid_order_num
   FROM dws.dws_sr_store_takeawaypro_statis_d a
   LEFT JOIN dim.dim_silkworm_date b ON a.dt=b.current_date_txt
   WHERE dt BETWEEN '2025-11-03' AND '2025-11-08'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15) tot
WHERE NOT (tot_expouse_num = 0
           AND bm_uv > 0);

=============================================== 活动曝光到转化
DROP VIEW IF EXISTS origin_traffic_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (time,event,county_id,position,activity_id,user_id) AS
  (SELECT time,
          event,
          get_json_string(properties,'$.city') AS county_id,
          get_json_string(properties,'$.position') AS position,
          get_json_string(properties,'$.activity_id') AS activity_id,
          distinct_id AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2025-12-08'
     AND event IN ('Homepage_Feed_Activity_Ex',
                   -- 'Homepage_Feed_Activity_Click',
                   'Search_Result_Ex'
                   -- 'Search_Result_Click'
                   )
    AND distinct_id regexp '^[0-9]{1,10}$'
    );

DROP VIEW IF EXISTS traffic_info;


CREATE VIEW IF NOT EXISTS traffic_info (time,event,county_id,position,activity_id,user_id) AS
  (SELECT time,
          event,
          CASE
              WHEN county_id IS NULL
                   OR county_id='0'
                   OR county_id=''
                   OR county_id='null' THEN 0
              ELSE cast(county_id AS int)
          END AS county_id,
          position,
          cast(activity_id AS int) activity_id,
                                   user_id
   FROM origin_traffic_info
   WHERE cast(activity_id as string) regexp '^[0-9]{1,8}$');


DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (order_time,promotion_id,user_id) AS
  (SELECT order_time,
          store_promotion_id promotion_id,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date(order_time)='2025-12-08'
     AND store_promotion_id<>0
    );


SELECT count(1) tot,
       count(DISTINCT user_id) uv,
       min(diff_snd) min_diff_snd,
       percentile_cont(diff_snd,0.1) 10_diff_snd,
       percentile_cont(diff_snd,0.2) 20_diff_snd,
       percentile_cont(diff_snd,0.3) 30_diff_snd,
       percentile_cont(diff_snd,0.4) 40_diff_snd,
       percentile_cont(diff_snd,0.5) 50_diff_snd,
       percentile_cont(diff_snd,0.6) 60_diff_snd,
       percentile_cont(diff_snd,0.7) 70_diff_snd,
       percentile_cont(diff_snd,0.8) 80_diff_snd,
       percentile_cont(diff_snd,0.9) 90_diff_snd,
       max(diff_snd) max_diff_snd
FROM
(SELECT a.time,
        a.event,
        a.county_id,
        a.position,
        a.activity_id,
        a.user_id,
        date_diff('second',b.order_time,a.time) AS diff_snd
 FROM traffic_info a
 LEFT JOIN order_info b ON a.activity_id=b.promotion_id
 AND a.user_id=b.user_id) toa;

-- -- 清洗流量数据

-- DROP VIEW IF EXISTS traffic_info;


-- CREATE VIEW IF NOT EXISTS traffic_info (time,event,county_id,POSITION,activity_id,user_id) AS
--   (SELECT time,
--           event,
--           CASE
--               WHEN county_id IS NULL
--                    OR county_id='0'
--                    OR county_id=''
--                    OR county_id='null' THEN 0
--               ELSE cast(county_id AS int)
--           END AS county_id,
--           POSITION,
--           cast(activity_id AS int) activity_id,
--                                    user_id
--    FROM origin_traffic_info
--    WHERE cast(activity_id as string) regexp '^[0-9]{1,8}$');




-- -- 统计首页feed流活动曝光和点击
-- DROP VIEW IF EXISTS feed_info;


-- CREATE VIEW IF NOT EXISTS feed_info (statistics_date,county_id,activity_id,platform_name,app_version,activity_type,expouse_num,expouse_uids,clc_num,clc_uids) AS
--   (SELECT date(time) statistics_date,
--                      county_id,
--                      -- position,
--                      activity_id,
--                      platform_name,
--                      app_version,
--                      activity_type,
--                      sum(if(event='Homepage_Feed_Activity_Ex',1,0)) expouse_num,
--                      bitmap_agg(if(event='Homepage_Feed_Activity_Ex',user_id,NULL)) expouse_uids,
--                      sum(if(event='Homepage_Feed_Activity_Click',1,0)) clc_num,
--                      bitmap_agg(if(event='Homepage_Feed_Activity_Click',user_id,NULL)) clc_uids
--    FROM traffic_info
--    WHERE event IN ('Homepage_Feed_Activity_Ex',
--                    'Homepage_Feed_Activity_Click')
--    GROUP BY 1,
--             2,
--             3,
--             4,
--             5,
--             6);


SELECT time,
          event,
          position,
          city_code,
          activity_id,
          distinct_id AS user_id
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2026-01-07'
     AND event IN ('Homepage_Feed_Activity_Ex',
                   'Homepage_Feed_Activity_Click')
    AND distinct_id='923592157'
    -- AND activity_id regexp '^[0-9]{1,8}$'
  ;


===========================================

-- 流量解析
DROP VIEW IF EXISTS origin_traffic_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (time,event,county_id,position,activity_id,distance,user_id) AS
  (SELECT time,
          event,
          get_json_string(properties,'$.city') AS county_id,
          get_json_string(properties,'$.position') AS position,
          get_json_string(properties,'$.activity_id') AS activity_id,
          get_json_string(properties,'$.distance') AS distance,
          distinct_id AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') between '2025-12-08' AND '2025-12-14'
     AND event IN ('Homepage_Feed_Activity_Ex',
                   'Search_Result_Ex'
                   )
    AND distinct_id regexp '^[0-9]{1,10}$'
    );

-- 流量清洗
DROP VIEW IF EXISTS traffic_info;


CREATE VIEW IF NOT EXISTS traffic_info (time,event,county_id,POSITION,activity_id,distance,user_id) AS
  (SELECT time,
          event,
          CASE
              WHEN county_id IS NULL
                   OR county_id='0'
                   OR county_id=''
                   OR county_id='null' THEN 0
              ELSE cast(county_id AS int)
          END AS county_id,
          POSITION,
          cast(activity_id AS int) activity_id,
                                   CASE
                                       WHEN distance>=0
                                            AND distance<=3000 THEN '<=3km'
                                       WHEN distance>3000
                                            AND distance<=5000 THEN '3-5km'
                                       WHEN distance>5000
                                            AND distance<=8000 THEN '5-8km'
                                       WHEN distance>8000
                                            AND distance<=10000 THEN '8-10km'
                                       WHEN distance>10000 THEN '>10km'
                                       ELSE '其他'
                                   END distance,
                                       user_id
   FROM origin_traffic_info
   WHERE cast(activity_id AS string) regexp '^[0-9]{1,8}$');


-- 报名
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (order_time,promotion_id,user_id) AS
  (SELECT
          order_time,
          store_promotion_id promotion_id,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date(order_time) between '2025-12-08' AND '2025-12-14'
     AND store_promotion_id<>0
    );


-- 活动品类
DROP VIEW IF EXISTS store_cate;


CREATE VIEW IF NOT EXISTS store_cate (store_id,cate1_name,cate2_name) AS
  (SELECT a.store_id,
          cate1_name,
          cate2_name
   FROM dwd.dwd_sr_order_promotion_order a
   LEFT JOIN
     (SELECT store_id,
             get_json_object( parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category1' ) AS cate1_name,
             get_json_object( parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category2' ) AS cate2_name
FROM dim.dim_silkworm_store) b ON a.store_id=b.store_id
   WHERE a.dt BETWEEN '2025-11-08' AND '2025-12-14'
   GROUP BY 1,
            2,
            3);

SELECT a.time,
       d.is_workday,
       a.user_id,
       g.client_level,
       g.gender,
       g.register_days,
       g.visit_days,
       g.last30d_visit_days,
       g.last30d_finish_avg_pay_amt,
       ifnull(e.city_name,'其他') city_name,
       ifnull(e.county_name,'其他') county_name,
       ifnull(c.cate1_name,'其他') cate1_name,
       ifnull(c.cate2_name,'其他') cate2_name,
       b.store_platform,
       CASE
           WHEN b.store_type=0 THEN '普通店铺'
           WHEN b.store_type=1 THEN '优质店铺'
           WHEN b.store_type=2 THEN '大客户'
           ELSE '其他'
       END store_type,
       if(b.store_brand_type=0,'非品牌','品牌') store_brand_type,
       b.is_need_rating,
       b.promotion_rebate_type,
       b.mlabel_threshold_amt,
       b.mlabel_rebate_amt,
       b.mlabel,
       b.promotion_quota,
       if(f.user_id IS NOT NULL,1,0) order_num
FROM traffic_info a
LEFT JOIN dws.dws_sr_store_takeawaypro_statis_d b ON a.activity_id=b.promotion_id
LEFT JOIN store_cate c ON b.store_id=c.store_id
LEFT JOIN dim.dim_silkworm_date d ON date(a.time)=d.current_date_txt
LEFT JOIN dim.dim_silkworm_county e ON a.county_id=e.county_id
LEFT JOIN order_info f ON a.activity_id=f.promotion_id
AND a.user_id=f.user_id
AND date_diff('minute',f.order_time,a.time) BETWEEN 0 AND 15
LEFT JOIN dwd.dwd_silkworm_user_feature_data g ON a.user_id=g.user_id
WHERE b.store_platform IS NOT NULL ;



drop table if exists dwd.dwd_sr_store_order_factor;
create table if not exists dwd.dwd_sr_store_order_factor (
expouse_time datetime comment '曝光时间',
is_workday int comment '是否工作日',
user_id int comment '用户ID',
client_level int comment '用户等级',
gender varchar(16) comment '性别',
register_days int comment '注册天数',
visit_days int comment '累计访问天数',
last30d_visit_days int comment '近30天访问天数',
last30d_finish_avg_pay_amt decimal(12,2) comment '近30天单均支付金额',
promotion_id int comment '活动ID',
city_name varchar(50) comment '城市',
county_name varchar(50) comment '区县',
cate1_name varchar(25) comment '一级品类',
cate2_name varchar(25) comment '二级品类',
store_platform varchar(25) comment '店铺平台',
store_type varchar(25) comment '店铺类型',
store_brand_type varchar(25) comment '店铺品牌类型',
is_need_rating int comment '是否需评价',
promotion_rebate_type varchar(25) comment '活动返利类型',
mlabel_threshold_amt decimal(12,2) comment '餐标门槛',
mlabel_rebate_amt decimal(12,2) comment '餐标返现金额',
mlabel varchar(25) comment '餐标',
promotion_quota int comment '活动名额',
order_num int comment '下单量'
) ENGINE=OLAP
DUPLICATE KEY(expouse_time, is_workday, user_id, client_level,gender,register_days,visit_days,last30d_visit_days,promotion_id)
COMMENT "外卖活动下单因素"
DISTRIBUTED BY HASH(expouse_time, user_id)
ORDER BY(expouse_time, user_id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2");




SELECT 
    expouse_time, -- 曝光时间
    hour(expouse_time) as expouse_hr, -- 曝光时点(第几个小时)
    promotion_id, -- 活动ID
    position, -- 位置
    is_workday, -- 是否工作日
    user_id, -- 用户ID
    client_level, -- 用户等级
    gender,
    register_days,
    visit_days,
    last30d_visit_days,
    city_name,
    county_name,
    cate1_name,
    cate2_name,
    store_platform,
    store_type,
    store_brand_type,
    is_need_rating,
    promotion_rebate_type,
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    mlabel,
    promotion_quota,
    order_num
FROM dwd.dwd_sr_store_order_factor
WHERE 
  ;




SELECT 
    expouse_time,
    hour(expouse_time) as expouse_hr,
    promotion_id,
    position,
    is_workday,
    user_id,
    client_level,
    gender,
    register_days,
    visit_days,
    last30d_visit_days,
    last30d_finish_avg_pay_amt,
    city_name,
    county_name,
    cate1_name,
    cate2_name,
    store_platform,
    store_type,
    store_brand_type,
    is_need_rating,
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    CASE WHEN mlabel_threshold_amt = 0 OR mlabel_threshold_amt IS NULL THEN 0 
         ELSE mlabel_rebate_amt/mlabel_threshold_amt END as rebate_ratio,
    promotion_quota,
    order_num as is_order
FROM dwd.dwd_sr_store_order_factor
WHERE date(expouse_time) between '2025-12-08' AND '2025-12-14'
  and promotion_rebate_type='霸王餐'
  and city_name='杭州市';























































