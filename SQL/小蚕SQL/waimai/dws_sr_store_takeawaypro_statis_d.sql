--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2025-05-16 15:54:56
--******************************************************************--
-- drop table if exists dws.dws_sr_store_takeawaypro_statis_d;

create table if not exists dws.dws_sr_store_takeawaypro_statis_d (
    dt date NOT NULL COMMENT '分区日期',
    promotion_id int not null comment '活动ID',
    begin_date date comment '活动开始日期',
    end_date date comment '活动开始日期',
    store_id int comment '店铺ID',
    city_name varchar(50) comment '城市名称',
    county_name varchar(50) comment '区县名称',
    cate1 int comment '一级品类ID(0:无;1:早餐;2:正餐;3:下午茶;4:晚餐;5:夜宵;6:零售)',
    cate2 int comment '二级品类ID(0:无;1:包子粥铺;2:快餐简餐;3:甜品饮品;4:炸串小吃;5:火锅烧烤;6:汉堡西餐;7:零售;8:水果鲜花;9:成人用品)',
    store_platform varchar(10) comment '店铺平台',
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
    meituan_promotion_quota int comment '美团活动名额',
    eleme_promotion_quota int comment '饿了么活动名额',
    jd_promotion_quota int comment '京东活动名额',
    promotion_quota int comment '总活动名额',
    tot_homepage_activity_expose_num int comment '全站首页活动曝光量',
    tot_homepage_activity_clc_num int comment '全站首页活动点击量',
    tot_takeaway_detailpage_pv int comment '全站活动详情页PV',
    tot_takeaway_activity_enterstore_clc_num int comment '全站活动详情页进店点击量',
    tot_takeaway_graborder_button_clc_num int comment '全站活动详情页抢单按钮点击量',
    tot_takeaway_baoming_button_clc_num int comment '全站活动详情页报名按钮点击量',
    tot_homepage_activity_expose_uids bitmap comment '全站首页活动曝光用户列表',
    tot_homepage_activity_clc_uids bitmap comment '全站首页活动点击用户列表',
    tot_takeaway_detailpage_uids bitmap comment '全站活动详情页浏览用户列表',
    tot_takeaway_activity_enterstore_clc_uids bitmap comment '全站活动详情页进店点击用户列表',
    tot_takeaway_graborder_button_clc_uids bitmap comment '全站活动详情页抢单按钮点击用户列表',
    tot_takeaway_baoming_button_clc_uids bitmap comment '全站活动详情页报名按钮点击用户列表',
    app_homepage_activity_expose_num int comment 'APP端首页活动曝光量',
    app_homepage_activity_clc_num int comment 'APP端首页活动点击量',
    app_takeaway_detailpage_pv int comment 'APP端活动详情页PV',
    app_takeaway_activity_enterstore_clc_num int comment 'APP端活动详情页进店点击量',
    app_takeaway_graborder_button_clc_num int comment 'APP端活动详情页抢单按钮点击量',
    app_takeaway_baoming_button_clc_num int comment 'APP端活动详情页报名按钮点击量',
    app_homepage_activity_expose_uids bitmap comment 'APP端首页活动曝光用户列表',
    app_homepage_activity_clc_uids bitmap comment 'APP端首页活动点击用户列表',
    app_takeaway_detailpage_uids bitmap comment 'APP端活动详情页浏览用户列表',
    app_takeaway_activity_enterstore_clc_uids bitmap comment 'APP端活动详情页进店点击用户列表',
    app_takeaway_graborder_button_clc_uids bitmap comment 'APP端活动详情页抢单按钮点击用户列表',
    app_takeaway_baoming_button_clc_uids bitmap comment 'APP端活动详情页报名按钮点击用户列表',
    h5_homepage_activity_expose_num int comment 'H5端首页活动曝光量',
    h5_homepage_activity_clc_num int comment 'H5端首页活动点击量',
    h5_takeaway_detailpage_pv int comment 'H5端活动详情页PV',
    h5_takeaway_activity_enterstore_clc_num int comment 'H5端活动详情页进店点击量',
    h5_takeaway_graborder_button_clc_num int comment 'H5端活动详情页抢单按钮点击量',
    h5_takeaway_baoming_button_clc_num int comment 'H5端活动详情页报名按钮点击量',
    h5_homepage_activity_expose_uids bitmap comment 'H5端首页活动曝光用户列表',
    h5_homepage_activity_clc_uids bitmap comment 'H5端首页活动点击用户列表',
    h5_takeaway_detailpage_uids bitmap comment 'H5端活动详情页浏览用户列表',
    h5_takeaway_activity_enterstore_clc_uids bitmap comment 'H5端活动详情页进店点击用户列表',
    h5_takeaway_graborder_button_clc_uids bitmap comment 'H5端活动详情页抢单按钮点击用户列表',
    h5_takeaway_baoming_button_clc_uids bitmap comment 'H5端活动详情页报名按钮点击用户列表',
    minipro_homepage_activity_expose_num int comment '小程序端首页活动曝光量',
    minipro_homepage_activity_clc_num int comment '小程序端首页活动点击量',
    minipro_takeaway_detailpage_pv int comment '小程序端活动详情页PV',
    minipro_takeaway_activity_enterstore_clc_num int comment '小程序端活动详情页进店点击量',
    minipro_takeaway_graborder_button_clc_num int comment '小程序端活动详情页抢单按钮点击量',
    minipro_takeaway_baoming_button_clc_num int comment '小程序端活动详情页报名按钮点击量',
    minipro_homepage_activity_expose_uids bitmap comment '小程序端首页活动曝光用户列表',
    minipro_homepage_activity_clc_uids bitmap comment '小程序端首页活动点击用户列表',
    minipro_takeaway_detailpage_uids bitmap comment '小程序端活动详情页浏览用户列表',
    minipro_takeaway_activity_enterstore_clc_uids bitmap comment '小程序端活动详情页进店点击用户列表',
    minipro_takeaway_graborder_button_clc_uids bitmap comment '小程序端活动详情页抢单按钮点击用户列表',
    minipro_takeaway_baoming_button_clc_uids bitmap comment '小程序端活动详情页报名按钮点击用户列表',
    tot_search_expose_num int comment '全站搜索曝光量',
    tot_search_result_clc_num int comment '全站搜索结果点击量',
    tot_search_expose_uids bitmap comment '全站搜索曝光用户列表',
    tot_search_result_clc_uids bitmap comment '全站搜索结果点击用户列表',
    app_search_expose_num int comment 'APP端搜索曝光量',
    app_search_result_clc_num int comment 'APP端搜索结果点击量',
    app_search_expose_uids bitmap comment 'APP端搜索曝光用户列表',
    app_search_result_clc_uids bitmap comment 'APP端搜索结果点击用户列表',
    h5_search_expose_num int comment 'H5端搜索曝光量',
    h5_search_result_clc_num int comment 'H5端搜索结果点击量',
    h5_search_expose_uids bitmap comment 'H5端搜索曝光用户列表',
    h5_search_result_clc_uids bitmap comment 'H5端搜索结果点击用户列表',
    minipro_search_expose_num int comment '小程序端搜索曝光量',
    minipro_search_result_clc_num int comment '小程序端搜索结果点击量',
    minipro_search_expose_uids bitmap comment '小程序端搜索曝光用户列表',
    minipro_search_result_clc_uids bitmap comment '小程序端搜索结果点击用户列表',
    baoming_uids bitmap comment '全站报名用户列表',
    handle_cancel_uids bitmap comment '全站手动取消用户列表',
    timeout_cancel_uids bitmap comment '全站超时取消用户列表',
    cancel_uids bitmap comment '全站取消用户列表',
    revicp_uids bitmap comment '全站复活券用户列表',
    valid_uids bitmap comment '全站有效用户列表',
    order_num int comment '全站报名订单量',
    handle_cancel_order_num int comment '全站手动取消订单量',
    timeout_cancel_order_num int comment '全站超时取消订单量',
    cancel_order_num int comment '全站取消订单量',
    revicp_order_num int comment '全站复活券订单量',
    valid_order_num int comment '全站有效订单量',
    profit decimal(12,2) comment '全站订单利润',
    rebate_amt decimal(12,2) comment '全站实际返现金额',
    redpacket_amt decimal(12,2) comment '全站红包金额'
) ENGINE=OLAP
PRIMARY KEY(`dt`, `promotion_id`)
COMMENT "霸王餐活动转化统计"
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(`dt`, `promotion_id`)
PROPERTIES (
"replication_num" = "2",
"in_memory" = "false",
"enable_persistent_index" = "true",
"replicated_storage" = "true",
"compression" = "LZ4"
);


set query_timeout=12000;
set enable_spill = true;
set spill_mode = "force";

insert into dws.dws_sr_store_takeawaypro_statis_d

-- 店铺活动
WITH t1 AS (
SELECT begin_date,
       end_date,
       store_promotion_id,
       a.store_id,
       b.store_name,
       b.city_name,
       b.county_name,
       cate1,
       cate2,
       store_platform,
       store_type,
       store_brand_type,
       delivery_type,
       is_threshold,
       is_need_rating,
       is_virtual,
       is_miaosha,
       is_private,
       is_vip_exclusive,
       is_youzhi_promotion,
       promotion_rebate_type,
       mlabel_threshold_amt,
       mlabel_rebate_amt,
       CASE
           WHEN promotion_rebate_type=0 THEN concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
           WHEN promotion_rebate_type=1 THEN concat('最高返',mlabel_rebate_amt)
       END AS mlabel,
       meituan_promotion_quota,
       eleme_promotion_quota,
       jd_promotion_quota,
       promotion_quota
FROM (
SELECT begin_date,
       end_date,
       store_promotion_id,
       store_id,
       promotion_rebate_type,
       store_type,
       meituan_order_amt,
       meituan_mlabel_rebate_amt,
       eleme_order_amt,
       eleme_mlabel_rebate_amt,
       CASE
           WHEN ifnull(meituan_order_amt,0)>0 THEN meituan_order_amt
           WHEN ifnull(eleme_order_amt,0)>0 THEN eleme_order_amt
           WHEN ifnull(jd_order_amt,0)>0 THEN jd_order_amt
       END AS mlabel_threshold_amt,
       CASE
           WHEN ifnull(meituan_mlabel_rebate_amt,0)>0 THEN meituan_mlabel_rebate_amt
           WHEN ifnull(eleme_mlabel_rebate_amt,0)>0 THEN eleme_mlabel_rebate_amt
           WHEN ifnull(jd_mlabel_rebate_amt,0)>0 THEN jd_mlabel_rebate_amt
       END AS mlabel_rebate_amt,
       if(ifnull(meituan_order_amt,0)<>0
          OR ifnull(eleme_order_amt,0)<>0
          OR ifnull(jd_order_amt,0)<>0,1,0) is_threshold,
       if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating,
       ifnull(meituan_promotion_quota,0) + ifnull(eleme_promotion_quota,0) + ifnull(jd_promotion_quota,0) AS promotion_quota,
       is_virtual,
       is_miaosha,
       is_private,
       is_vip_exclusive,
       is_youzhi_promotion,
       CASE
           WHEN ifnull(meituan_order_amt,0)>0 THEN '美团'
           WHEN ifnull(eleme_order_amt,0)>0 THEN '饿了么'
           WHEN ifnull(jd_order_amt,0)>0 THEN '京东'
       END AS store_platform,
       ifnull(meituan_promotion_quota,0) meituan_promotion_quota,
       ifnull(eleme_promotion_quota,0) eleme_promotion_quota,
       ifnull(jd_promotion_quota,0) jd_promotion_quota
FROM dwd.dwd_sr_store_promotion
WHERE dt BETWEEN date_sub('${T-1}',interval 14 DAY) AND '${T-1}'
  AND date_format(begin_date,'%Y-%m-%d') between date_sub('${T-1}',interval 2 DAY) and '${T-1}'
  AND status IN (1,
                 4,
                 5)
 ) a
LEFT JOIN
  (SELECT store_id,
          store_name,
          city_name,
          district_name county_name,
          category_type cate1,
          sub_category_type cate2,
          store_brand_type,
          delivery_type
   FROM dim.dim_silkworm_store) b ON a.store_id=b.store_id
where b.store_name not regexp '测试' -- 测试店铺
 and a.store_id<>15901 -- 测试店铺
 and a.promotion_quota>0 -- 无效活动
 ),


-- 订单
t2 AS
  (SELECT a.store_promotion_id,
          bitmap_agg(a.user_id) AS baoming_uids,
          bitmap_agg(if(a.order_status=4,a.user_id,NULL)) AS handle_cancel_uids,
          bitmap_agg(if(a.order_status=5,a.user_id,NULL)) AS timeout_cancel_uids,
          bitmap_agg(if(a.order_status IN (4,5),a.user_id,NULL)) AS cancel_uids,
          bitmap_agg(if(a.order_status=12,a.user_id,NULL)) AS revicp_uids,
          bitmap_agg(if(a.order_status IN (2,8),a.user_id,NULL)) AS valid_uids,
          count(a.auto_id) AS order_num,
          count(if(a.order_status=4,a.auto_id,NULL)) AS handle_cancel_order_num,
          count(if(a.order_status=5,a.auto_id,NULL)) AS timeout_cancel_order_num,
          count(if(a.order_status IN (4,5),a.auto_id,NULL)) AS cancel_order_num,
          count(if(a.order_status=12,a.auto_id,NULL)) AS revicp_order_num,
          count(if(a.order_status IN (2,8),a.auto_id,NULL)) AS valid_order_num,
          sum(if(order_status=2,a.profit,0)) AS profit,
          sum(if(a.order_status IN (2,8),ifnull(a.real_rebate_amt,0),0)) rebate_amt,
          sum(if(a.order_status IN (2,8),ifnull(b.real_rebate_amt,0),0)) redpacket_amt
   FROM
     (SELECT auto_id,
             order_id,
             store_promotion_id,
             user_id,
             order_status,
             profit,
             real_rebate_amt
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub('${T-1}',interval 2 DAY) AND '${T-1}'
        AND store_promotion_id<>0 ) a
   LEFT JOIN
     (SELECT order_id,
             real_rebate_amt
      FROM dwd.dwd_sr_market_redpack_use_record
      WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}') b ON a.order_id=b.order_id and length(a.order_id)>10
   GROUP BY 1),

-- 20251124修改 替换流量统计由traffic_user_d为神策dwd表。8月22日及之前数据，使用traffic_user_d，23日及之后，使用神策采集日志 修改人：dahe 修改人：大禾 
traffic_info AS
  (SELECT date_format(time,'%Y-%m-%d') AS dt,
          CASE
              WHEN platform_type regexp '5' THEN 'H5'
              WHEN platform_type IN ('小程序',
                                     '微信小程序') THEN '微信小程序'
              WHEN platform_type IN ('Android',
                                     'iOS',
                                     'Harmony') THEN 'APP'
          END AS platform_name,
          event,
          activity_id,
          user_id,
          button_name
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub('${T-1}',interval 2 DAY) AND '${T-1}'
     AND cast(activity_id as string) regexp '^[0-9]{1,8}$'
     AND platform_type IN ('H5',
                           'h5',
                           '小程序',
                           '微信小程序',
                           'Android',
                           'iOS',
                           'Harmony')
     AND event IN ('Homepage_Feed_Activity_Ex',
                   'Homepage_Feed_Activity_Click',
                   'Takeaway_Detailpage_View',
                   'Takeout_Enter_Store_Click',
                   'Takeaway_Baomingflow_Button_Click',
                   'Search_Result_Ex',
                   'Search_Result_Click')),

traffic_result AS
  (SELECT activity_id,
          platform_name,
          user_id,
          sum(if(event='Homepage_Feed_Activity_Ex',1,0)) homepage_takeaway_activity_expose,
          sum(if(event='Homepage_Feed_Activity_Click',1,0)) homepage_takeaway_activity_click_num,
          sum(if(event='Takeaway_Detailpage_View',1,0)) takeaway_detailpage_pv,
          sum(if(event='Takeout_Enter_Store_Click',1,0)) takeaway_activity_enterstore_click_num,
          sum(if(event='Takeaway_Baomingflow_Button_Click' AND button_name IN ('超期点单','进店下单','立即抢单','立即抢'),1,0)) takeaway_graborder_button_click_num,
          sum(if(event='Takeaway_Baomingflow_Button_Click' AND button_name IN ('领红包并确定报名','领红包并抢名额'),1,0)) takeaway_baoming_button_click_num,
          sum(if(event='Search_Result_Ex',1,0)) search_expose_num,
          sum(if(event='Search_Result_Click',1,0)) search_result_click_num
   FROM traffic_info
   GROUP BY 1,
            2,
            3),


t3 as (
select
    activity_id,
    -- 全部
    sum(homepage_takeaway_activity_expose) tot_homepage_activity_expose_num,
    sum(homepage_takeaway_activity_click_num) tot_homepage_activity_clc_num,
    sum(takeaway_detailpage_pv) tot_takeaway_detailpage_pv,
    sum(takeaway_activity_enterstore_click_num) tot_takeaway_activity_enterstore_clc_num,
    sum(takeaway_graborder_button_click_num) tot_takeaway_graborder_button_clc_num,
    sum(takeaway_baoming_button_click_num) tot_takeaway_baoming_button_clc_num,
    bitmap_agg(if(homepage_takeaway_activity_expose>0,user_id,null)) tot_homepage_activity_expose_uids,
    bitmap_agg(if(homepage_takeaway_activity_click_num>0,user_id,null)) tot_homepage_activity_clc_uids,
    bitmap_agg(if(takeaway_detailpage_pv>0,user_id,null)) tot_takeaway_detailpage_uids,
    bitmap_agg(if(takeaway_activity_enterstore_click_num>0,user_id,null)) tot_takeaway_activity_enterstore_clc_uids,
    bitmap_agg(if(takeaway_graborder_button_click_num>0,user_id,null)) tot_takeaway_graborder_button_clc_uids,
    bitmap_agg(if(takeaway_baoming_button_click_num>0,user_id,null)) tot_takeaway_baoming_button_clc_uids,
    -- APP
    sum(if(platform_name='APP',homepage_takeaway_activity_expose,0)) app_homepage_activity_expose_num,
    sum(if(platform_name='APP',homepage_takeaway_activity_click_num,0)) app_homepage_activity_clc_num,
    sum(if(platform_name='APP',takeaway_detailpage_pv,0)) app_takeaway_detailpage_pv,
    sum(if(platform_name='APP',takeaway_activity_enterstore_click_num,0)) app_takeaway_activity_enterstore_clc_num,
    sum(if(platform_name='APP',takeaway_graborder_button_click_num,0)) app_takeaway_graborder_button_clc_num,
    sum(if(platform_name='APP',takeaway_baoming_button_click_num,0)) app_takeaway_baoming_button_clc_num,
    bitmap_agg(if(platform_name='APP' and homepage_takeaway_activity_expose>0,user_id,null)) app_homepage_activity_expose_uids,
    bitmap_agg(if(platform_name='APP' and homepage_takeaway_activity_click_num>0,user_id,null)) app_homepage_activity_clc_uids,
    bitmap_agg(if(platform_name='APP' and takeaway_detailpage_pv>0,user_id,null)) app_takeaway_detailpage_uids,
    bitmap_agg(if(platform_name='APP' and takeaway_activity_enterstore_click_num>0,user_id,null)) app_takeaway_activity_enterstore_clc_uids,
    bitmap_agg(if(platform_name='APP' and takeaway_graborder_button_click_num>0,user_id,null)) app_takeaway_graborder_button_clc_uids,
    bitmap_agg(if(platform_name='APP' and takeaway_baoming_button_click_num>0,user_id,null)) app_takeaway_baoming_button_clc_uids,
    -- H5
    sum(if(platform_name='H5',homepage_takeaway_activity_expose,0)) h5_homepage_activity_expose_num,
    sum(if(platform_name='H5',homepage_takeaway_activity_click_num,0)) h5_homepage_activity_clc_num,
    sum(if(platform_name='H5',takeaway_detailpage_pv,0)) h5_takeaway_detailpage_pv,
    sum(if(platform_name='H5',takeaway_activity_enterstore_click_num,0)) h5_takeaway_activity_enterstore_clc_num,
    sum(if(platform_name='H5',takeaway_graborder_button_click_num,0)) h5_takeaway_graborder_button_clc_num,
    sum(if(platform_name='H5',takeaway_baoming_button_click_num,0)) h5_takeaway_baoming_button_clc_num,
    bitmap_agg(if(platform_name='H5' and homepage_takeaway_activity_expose>0,user_id,null)) h5_homepage_activity_expose_uids,
    bitmap_agg(if(platform_name='H5' and homepage_takeaway_activity_click_num>0,user_id,null)) h5_homepage_activity_clc_uids,
    bitmap_agg(if(platform_name='H5' and takeaway_detailpage_pv>0,user_id,null)) h5_takeaway_detailpage_uids,
    bitmap_agg(if(platform_name='H5' and takeaway_activity_enterstore_click_num>0,user_id,null)) h5_takeaway_activity_enterstore_clc_uids,
    bitmap_agg(if(platform_name='H5' and takeaway_graborder_button_click_num>0,user_id,null)) h5_takeaway_graborder_button_clc_uids,
    bitmap_agg(if(platform_name='H5' and takeaway_baoming_button_click_num>0,user_id,null)) h5_takeaway_baoming_button_clc_uids,
    -- 小程序
    sum(if(platform_name='微信小程序',homepage_takeaway_activity_expose,0)) minipro_homepage_activity_expose_num,
    sum(if(platform_name='微信小程序',homepage_takeaway_activity_click_num,0)) minipro_homepage_activity_clc_num,
    sum(if(platform_name='微信小程序',takeaway_detailpage_pv,0)) minipro_takeaway_detailpage_pv,
    sum(if(platform_name='微信小程序',takeaway_activity_enterstore_click_num,0)) minipro_takeaway_activity_enterstore_clc_num,
    sum(if(platform_name='微信小程序',takeaway_graborder_button_click_num,0)) minipro_takeaway_graborder_button_clc_num,
    sum(if(platform_name='微信小程序',takeaway_baoming_button_click_num,0)) minipro_takeaway_baoming_button_clc_num,
    bitmap_agg(if(platform_name='微信小程序' and homepage_takeaway_activity_expose>0,user_id,null)) minipro_homepage_activity_expose_uids,
    bitmap_agg(if(platform_name='微信小程序' and homepage_takeaway_activity_click_num>0,user_id,null)) minipro_homepage_activity_clc_uids,
    bitmap_agg(if(platform_name='微信小程序' and takeaway_detailpage_pv>0,user_id,null)) minipro_takeaway_detailpage_uids,
    bitmap_agg(if(platform_name='微信小程序' and takeaway_activity_enterstore_click_num>0,user_id,null)) minipro_takeaway_activity_enterstore_clc_uids,
    bitmap_agg(if(platform_name='微信小程序' and takeaway_graborder_button_click_num>0,user_id,null)) minipro_takeaway_graborder_button_clc_uids,
    bitmap_agg(if(platform_name='微信小程序' and takeaway_baoming_button_click_num>0,user_id,null)) minipro_takeaway_baoming_button_clc_uids,

    sum(search_expose_num) tot_search_expose_num,
    sum(search_result_click_num) tot_search_result_clc_num,
    bitmap_agg(if(search_expose_num>0,user_id,null)) tot_search_expose_uids,
    bitmap_agg(if(search_result_click_num>0,user_id,null)) tot_search_result_clc_uids,

    sum(if(platform_name='APP',search_expose_num,0)) app_search_expose_num,
    sum(if(platform_name='APP',search_result_click_num,0)) app_search_result_clc_num,
    bitmap_agg(if(platform_name='APP' and search_expose_num>0,user_id,null)) app_search_expose_uids,
    bitmap_agg(if(platform_name='APP' and search_result_click_num>0,user_id,null)) app_search_result_clc_uids,

    sum(if(platform_name='H5',search_expose_num,0)) h5_search_expose_num,
    sum(if(platform_name='H5',search_result_click_num,0)) h5_search_result_clc_num,
    bitmap_agg(if(platform_name='H5' and search_expose_num>0,user_id,null)) h5_search_expose_uids,
    bitmap_agg(if(platform_name='H5' and search_result_click_num>0,user_id,null)) h5_search_result_clc_uids,

    sum(if(platform_name='微信小程序',search_expose_num,0)) minipro_search_expose_num,
    sum(if(platform_name='微信小程序',search_result_click_num,0)) minipro_search_result_clc_num,
    bitmap_agg(if(platform_name='微信小程序' and search_expose_num>0,user_id,null)) minipro_search_expose_uids,
    bitmap_agg(if(platform_name='微信小程序' and search_result_click_num>0,user_id,null)) minipro_search_result_clc_uids
from traffic_result
group by 1
)



SELECT date(t1.begin_date) as dt,
       t1.store_promotion_id,
       t1.begin_date,
       t1.end_date,
       t1.store_id,
       t1.city_name,
       t1.county_name,
       t1.cate1,
       t1.cate2,
       t1.store_platform,
       t1.store_type,
       t1.store_brand_type,
       t1.delivery_type,
       t1.is_threshold,
       t1.is_need_rating,
       t1.is_virtual,
       t1.is_miaosha,
       t1.is_private,
       t1.is_vip_exclusive,
       t1.is_youzhi_promotion,
       t1.promotion_rebate_type,
       t1.mlabel_threshold_amt,
       t1.mlabel_rebate_amt,
       t1.mlabel,
       t1.meituan_promotion_quota,
       t1.eleme_promotion_quota,
       t1.jd_promotion_quota,
       t1.promotion_quota,
       t3.tot_homepage_activity_expose_num,
       t3.tot_homepage_activity_clc_num,
       t3.tot_takeaway_detailpage_pv,
       t3.tot_takeaway_activity_enterstore_clc_num,
       t3.tot_takeaway_graborder_button_clc_num,
       t3.tot_takeaway_baoming_button_clc_num,
       t3.tot_homepage_activity_expose_uids,
       t3.tot_homepage_activity_clc_uids,
       t3.tot_takeaway_detailpage_uids,
       t3.tot_takeaway_activity_enterstore_clc_uids,
       t3.tot_takeaway_graborder_button_clc_uids,
       t3.tot_takeaway_baoming_button_clc_uids,
       t3.app_homepage_activity_expose_num,
       t3.app_homepage_activity_clc_num,
       t3.app_takeaway_detailpage_pv,
       t3.app_takeaway_activity_enterstore_clc_num,
       t3.app_takeaway_graborder_button_clc_num,
       t3.app_takeaway_baoming_button_clc_num,
       t3.app_homepage_activity_expose_uids,
       t3.app_homepage_activity_clc_uids,
       t3.app_takeaway_detailpage_uids,
       t3.app_takeaway_activity_enterstore_clc_uids,
       t3.app_takeaway_graborder_button_clc_uids,
       t3.app_takeaway_baoming_button_clc_uids,
       t3.h5_homepage_activity_expose_num,
       t3.h5_homepage_activity_clc_num,
       t3.h5_takeaway_detailpage_pv,
       t3.h5_takeaway_activity_enterstore_clc_num,
       t3.h5_takeaway_graborder_button_clc_num,
       t3.h5_takeaway_baoming_button_clc_num,
       t3.h5_homepage_activity_expose_uids,
       t3.h5_homepage_activity_clc_uids,
       t3.h5_takeaway_detailpage_uids,
       t3.h5_takeaway_activity_enterstore_clc_uids,
       t3.h5_takeaway_graborder_button_clc_uids,
       t3.h5_takeaway_baoming_button_clc_uids,
       t3.minipro_homepage_activity_expose_num,
       t3.minipro_homepage_activity_clc_num,
       t3.minipro_takeaway_detailpage_pv,
       t3.minipro_takeaway_activity_enterstore_clc_num,
       t3.minipro_takeaway_graborder_button_clc_num,
       t3.minipro_takeaway_baoming_button_clc_num,
       t3.minipro_homepage_activity_expose_uids,
       t3.minipro_homepage_activity_clc_uids,
       t3.minipro_takeaway_detailpage_uids,
       t3.minipro_takeaway_activity_enterstore_clc_uids,
       t3.minipro_takeaway_graborder_button_clc_uids,
       t3.minipro_takeaway_baoming_button_clc_uids,
       t3.tot_search_expose_num,
       t3.tot_search_result_clc_num,
       t3.tot_search_expose_uids,
       t3.tot_search_result_clc_uids,
       t3.app_search_expose_num,
       t3.app_search_result_clc_num,
       t3.app_search_expose_uids,
       t3.app_search_result_clc_uids,
       t3.h5_search_expose_num,
       t3.h5_search_result_clc_num,
       t3.h5_search_expose_uids,
       t3.h5_search_result_clc_uids,
       t3.minipro_search_expose_num,
       t3.minipro_search_result_clc_num,
       t3.minipro_search_expose_uids,
       t3.minipro_search_result_clc_uids,
       t2.baoming_uids,
       t2.handle_cancel_uids,
       t2.timeout_cancel_uids,
       t2.cancel_uids,
       t2.revicp_uids,
       t2.valid_uids,
       t2.order_num,
       t2.handle_cancel_order_num,
       t2.timeout_cancel_order_num,
       t2.cancel_order_num,
       t2.revicp_order_num,
       t2.valid_order_num,
       t2.profit,
       t2.rebate_amt,
       t2.redpacket_amt
FROM t1
LEFT JOIN t2 ON t1.store_promotion_id=t2.store_promotion_id
left join t3 on t1.store_promotion_id=t3.activity_id;




































































