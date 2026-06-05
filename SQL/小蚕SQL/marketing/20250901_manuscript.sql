-- 复活券支出
SELECT strategy_id,
       sum(send_num) `发放成功数`,
       sum(if(b.key_id IS NOT NULL,1,0)) `使用数`,
       sum(if(c.order_id IS NOT NULL,1,0)) `复活券订单数`,
       sum(if(c.order_id IS NOT NULL
              AND date_format(order_audit_finish_time,'%Y-%m-%d %H:%i:%s')>'2025-09-18 13:30:00',c.real_rebate_amt,0)) `补贴金额`
FROM
  (SELECT strategy_id,
          silk_id,
          count(1) send_num
   FROM test.test_sr_ad_marketing_automation_strategy_exec_log
   WHERE date_format(created_at,'%Y-%m-%d')='2025-09-18'
     AND strategy_id IN (3446)
     AND STATE=3
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT user_id,
          key_id
   FROM dwd.dwd_sr_market_rights_card
   WHERE dt='2025-09-18'
     AND card_id=74
     AND key_id<>0
     AND date_format(used_time,'%Y-%m-%d')<>'1970-01-01'
     AND user_id<>848132951
   GROUP BY 1,
            2) b ON a.silk_id=b.user_id
LEFT JOIN
  (SELECT right(order_id,9) AS order_id,
          real_rebate_amt,
          order_audit_finish_time
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-09-16' AND '2025-09-18') c ON b.key_id=c.order_id
GROUP BY 1;



-- 绑定企微未激活用户
SELECT a.register_time `注册时间`,
       a.user_id `用户ID`,
       b.wechat_nickname `用户昵称`,
       a.bind_interior_staff_wework_id `绑定企微ID`,
       concat('备',c.device_id) `绑定设备ID`,
       c.wechat_nickname `设备名称`
FROM
  (SELECT register_time,
          user_id,
          user_wechat_id,
          bind_interior_staff_wechat_id,
          bind_interior_staff_wechat_account,
          bind_interior_staff_wework_id,
          bind_interior_staff_wework_account
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time, '%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND bind_interior_staff_wework_id <> '0'
     AND bind_interior_staff_wework_account = '0') a
LEFT JOIN dim.dim_silkworm_user_wechat b ON a.user_wechat_id=b.user_wechat_id
LEFT JOIN dim.dim_silkworm_device c ON a.bind_interior_staff_wework_id=c.bind_interior_staff_wework_id
AND c.device_type=1;


-- 月销单统计
SELECT date_format(dt,'%Y-%m') `统计日期`,
       city_name `城市名称`,
       county_name `区县名称`,
       CASE
           WHEN cate1=1 THEN '早餐'
           WHEN cate1=2 THEN '正餐'
           WHEN cate1=3 THEN '下午茶'
           WHEN cate1=4 THEN '晚餐'
           WHEN cate1=5 THEN '夜宵'
           WHEN cate1=6 THEN '零售'
           ELSE '其他'
       END `一级品类`,
       CASE
           WHEN cate2=1 THEN '包子粥铺'
           WHEN cate2=2 THEN '快餐简餐'
           WHEN cate2=3 THEN '甜品饮品'
           WHEN cate2=4 THEN '炸串小吃'
           WHEN cate2=5 THEN '火锅烧烤'
           WHEN cate2=6 THEN '汉堡西餐'
           WHEN cate2=7 THEN '零售'
           WHEN cate2=8 THEN '水果鲜花'
           WHEN cate2=9 THEN '成人用品'
           ELSE '其他'
       END `二级品类`,
       store_platform `店铺平台`,
       mlabel `餐标`,
       count(promotion_id) `活动数`,
       sum(meituan_promotion_quota) `美团活动名额`,
       sum(eleme_promotion_quota) `饿了么活动名额`,
       sum(jd_promotion_quota) `京东活动名额`,
       sum(promotion_quota) `总活动名额`,
       sum(order_num) `全站报名订单量`,
       sum(valid_order_num) `全站有效订单量`,
       sum(profit) `全站订单利润`,
       sum(rebate_amt) `全站实际返现金额`,
       sum(redpacket_amt) `全站红包金额`,
       sum(handle_cancel_order_num) `全站手动取消订单量`,
       sum(timeout_cancel_order_num) `全站超时取消订单量`,
       sum(cancel_order_num) `全站取消订单量`,
       sum(revicp_order_num) `全站复活券订单量`
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2025-01-01' AND '2025-08-31'
GROUP BY 1,
         2,
         3,
         4,
         5,
         6,
         7 ;


-- 超时取消订单
SELECT date_format(order_time,'%Y-%m-%d') `下单日期`,
       count(auto_id) AS `超时取消订单量`,
       count(DISTINCT user_id) AS `超时取消用户量`,
       count(if(order_log NOT regexp '填入订单号',auto_id,NULL)) `第一步超时取消订单量`,
       count(DISTINCT if(order_log NOT regexp '填入订单号',user_id,NULL)) `第一步超时取消用户量`,
       count(if(order_log regexp '填入订单号',auto_id,NULL)) `第二步超时取消订单量`,
       count(DISTINCT if(order_log regexp '填入订单号',user_id,NULL)) `第二步超时取消用户量`
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-08-01' AND '2025-09-15'
  AND order_status=5
GROUP BY 1;


-- 时点下单统计
SELECT date_format(order_time,'%Y-%m-%d %H') `下单时点`,
       count(1) `报名订单量`,
       count(DISTINCT user_id) `报名用户量`,
       count(if(order_status IN (2,8),order_id,NULL)) `完单量`,
       count(if(order_status IN (2,8),user_id,NULL)) `完单用户量`,
       sum(if(order_status=2,profit,0)) `利润`
FROM dwd.dwd_sr_order_promotion_order
WHERE dt = '2025-09-14'
GROUP BY 1;


====================== 
-- 砍价首页feed流实验
DROP VIEW IF EXISTS clc_info;

CREATE VIEW IF NOT EXISTS clc_info (clc_date,exp_name,activity_id,distinct_id) AS
  (SELECT date_format(time, '%Y-%m-%d') clc_date,
                                        IF(get_json_string(properties,'$.abtest_id') = 265,
                                                                                       '对照组',
                                                                                       '实验组') exp_name,
                                                                                              cast(get_json_string(properties,'$.activity_id') AS int) activity_id,
                                                                                                                                                       distinct_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-08-30' AND '2025-09-04'
     AND distinct_id regexp '^[0-9]{1,10}$'
     AND event='Instore_Homepage_Feed_Activity_Click'
     AND get_json_string(properties,'$.platform_type') IN ('小程序',
                                                           '微信小程序')
     AND get_json_string(properties,'$.page_name') = '砍价首页'
   GROUP BY 1,
            2,
            3,
            4);

DROP VIEW IF EXISTS order_info;

CREATE VIEW IF NOT EXISTS order_info (user_id,promotion_id,order_id,pay_amt,pay_date,verify_date) AS
  (SELECT user_id,
          store_promotion_id promotion_id,
                             order_id,
                             pay_amt,
                             date_format(pay_time,'%Y-%m-%d') pay_date,
                                                              date_format(verify_time,'%Y-%m-%d') verify_date
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-08-30' AND '2025-09-07'
     AND promotion_type IN (5,
                            6,
                            8));

SELECT clc_date,
       exp_name,
       count(DISTINCT order_id) `支付订单量`,
       sum(pay_amt) `支付金额`,
       count(DISTINCT b.distinct_id) `支付用户量`
FROM order_info a
INNER JOIN clc_info b ON b.distinct_id=a.user_id
AND b.activity_id=a.promotion_id
AND b.clc_date<=a.pay_date
GROUP BY 1,
         2;

SELECT clc_date,
       exp_name,
       count(DISTINCT order_id) `核销订单量`,
       count(DISTINCT b.distinct_id) `核销用户量`
FROM order_info a
INNER JOIN clc_info b ON b.distinct_id=a.user_id
AND b.activity_id=a.promotion_id
AND b.clc_date<=a.verify_date
GROUP BY 1,
         2;


=========== 砍价首页feed流上线后
-- 砍价首页曝光和点击
SELECT date_format(`time`,'%Y-%m-%d') clc_date,
       IF(platform_type = '到店小程序', '实验组', '对照组') exp_name,
       sum(if(event='Instore_Homepage_Feed_Activity_Ex',1,0)) `曝光量`,
       count(DISTINCT if(event='Instore_Homepage_Feed_Activity_Ex',distinct_id,NULL)) `曝光用户量`,
       sum(if(event='Instore_Homepage_Feed_Activity_Click',1,0)) `点击量`,
       count(DISTINCT if(event='Instore_Homepage_Feed_Activity_Click',distinct_id,NULL)) `点击用户量`
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-09-11' AND '2025-10-09'
  AND distinct_id regexp '^[0-9]{1,10}$'
  AND event IN ('Instore_Homepage_Feed_Activity_Ex',
                'Instore_Homepage_Feed_Activity_Click')
  AND platform_type IN ('到店小程序',
                        'Android',
                        'iOS')
  AND page_name= '砍价首页'
GROUP BY 1,
         2;


-- 砍价首页点击
DROP VIEW IF EXISTS clc_info;


CREATE VIEW IF NOT EXISTS clc_info (clc_date,exp_name,activity_id,distinct_id) AS
  (SELECT date_format(time, '%Y-%m-%d') clc_date,
                                        IF(platform_type = '到店小程序',
                                                           '实验组',
                                                           '对照组') exp_name,
                                                                  activity_id,
                                                                  distinct_id
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-09-11' AND '2025-10-09'
     AND distinct_id regexp '^[0-9]{1,10}$'
     AND event='Instore_Homepage_Feed_Activity_Click'
     AND platform_type IN ('到店小程序',
                           'Android',
                           'iOS')
     AND page_name= '砍价首页'
   GROUP BY 1,
            2,
            3,
            4);

-- 砍价下单
DROP VIEW IF EXISTS order_info;

CREATE VIEW IF NOT EXISTS order_info (user_id,promotion_id,order_id,pay_amt,pay_date,verify_date) AS
  (SELECT user_id,
          store_promotion_id promotion_id,
                             order_id,
                             pay_amt,
                             date_format(pay_time,'%Y-%m-%d') pay_date,
                                                              date_format(verify_time,'%Y-%m-%d') verify_date
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-09-11' AND '2025-10-09'
     AND promotion_type IN (5,
                            6,
                            8));

SELECT clc_date,
       exp_name,
       count(DISTINCT order_id) `支付订单量`,
       sum(pay_amt) `支付金额`,
       count(DISTINCT b.distinct_id) `支付用户量`
FROM order_info a
INNER JOIN clc_info b ON b.distinct_id=a.user_id
AND b.activity_id=a.promotion_id
AND b.clc_date<=a.pay_date
GROUP BY 1,
         2;


SELECT clc_date,
       exp_name,
       count(DISTINCT order_id) `核销订单量`,
       count(DISTINCT b.distinct_id) `核销用户量`
FROM order_info a
INNER JOIN clc_info b ON b.distinct_id=a.user_id
AND b.activity_id=a.promotion_id
AND b.clc_date<=a.verify_date
GROUP BY 1,
         2;
================================





-- 钱塘区用户明细
WITH t AS
  (SELECT a.user_id
   FROM
     (SELECT user_id,
             count(1) cnt
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-08-01' AND '2025-08-31'
        AND county_id=330114
        AND order_status IN (2,
                             8)
      GROUP BY 1 HAVING count(1)>=3) a
   INNER JOIN
     (SELECT user_id
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-08-01' AND '2025-08-31'
        AND county_id<>330114
        AND order_status IN (2,
                             8)
      GROUP BY 1) b ON a.user_id=b.user_id)


SELECT order_time `下单时间`,
       order_id `订单ID`,
       b.user_real_name `姓名`,
       b.user_id_num `身份证号`,
       c.phone `加密手机号`
FROM
  (SELECT order_time,
          concat('单',order_id) order_id,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-08-01' AND '2025-08-31'
     AND county_id=330114
     AND order_status IN (2,
                          8)) a
LEFT JOIN t ON a.user_id=t.user_id
LEFT JOIN dim.dim_silkworm_user b ON a.user_id=b.user_id
LEFT JOIN ods.ods_sr_silkworm_user c ON a.user_id=c.user_id
WHERE t.user_id IS NOT NULL;



=============================
-- DAU
SELECT statistics_date,
       city_name,
       bitmap_union_count(view_uids) dau
FROM dws.dws_sr_user_login_d
WHERE statistics_date BETWEEN '2025-09-18' AND '2025-09-22'
GROUP BY 1

-- 区县DAU
SELECT city_name,
       county_name,
       round(avg(dau),0) dau
FROM
  (SELECT statistics_date,
          city_name,
          county_name,
          bitmap_union_count(view_uids) dau
   FROM dws.dws_sr_user_login_d
   WHERE statistics_date BETWEEN '2025-09-18' AND '2025-09-22'
     AND city_name IN ('上海市',
                       '杭州市',
                       '广州市',
                       '成都市',
                       '深圳市',
                       '北京市',
                       '苏州市',
                       '南京市',
                       '武汉市',
                       '重庆市',
                       '合肥市',
                       '长沙市',
                       '东莞市',
                       '郑州市',
                       '宁波市',
                       '西安市',
                       '佛山市',
                       '金华市',
                       '南昌市',
                       '济南市',
                       '青岛市',
                       '天津市',
                       '无锡市')
   GROUP BY 1,
            2,
            3) a
GROUP BY 1,
         2;

-- 注册时间间隔DAU
SELECT user_type,
       round(avg(dau)) dau
FROM
  (SELECT statistics_date,
          CASE
              WHEN diff_days=0 THEN '当日注册用户'
              WHEN diff_days>0
                   AND diff_days<=7 THEN '1-7天内注册用户'
              WHEN diff_days>=8
                   AND diff_days<=14 THEN '8-14天内注册用户'
              WHEN diff_days>=15
                   AND diff_days<=30 THEN '15-30天内注册用户'
              WHEN diff_days>=31
                   AND diff_days<=60 THEN '31-60天内注册用户'
              WHEN diff_days>=61
                   AND diff_days<=90 THEN '61-90天内注册用户'
              WHEN diff_days>=91
                   AND diff_days<=180 THEN '91-180天内注册用户'
              WHEN diff_days>=181
                   AND diff_days<=270 THEN '181-270天内注册用户'
              WHEN diff_days>=271
                   AND diff_days<=365 THEN '271-365天内注册用户'
              WHEN diff_days>=366 THEN '365天以上注册用户'
              ELSE '其他'
          END user_type,
          count(user_id) dau
   FROM
     (SELECT statistics_date,
             date_diff('day',date_format(statistics_date, '%Y-%m-%d'),date_format(register_time, '%Y-%m-%d')) AS diff_days,
             a.user_id
      FROM
        (SELECT statistics_date,
                unnest_bitmap AS user_id
         FROM dws.dws_sr_user_login_d,
              unnest_bitmap(view_uids) AS uid
         WHERE statistics_date BETWEEN '2025-09-18' AND '2025-09-18'
         GROUP BY 1,
                  2) a
      LEFT JOIN dim.dim_silkworm_user b ON a.user_id=b.user_id
      GROUP BY 1,
               2,
               3) a
   GROUP BY 1,
            2) b
GROUP BY 1;





-- 商务团队销单 数据不准 废弃
SELECT lvl6_dept_name,
       sum(quota) quota,
       sum(order_num) valid_order_num
FROM
  (SELECT date_format(begin_date,'%Y-%m-%d') AS dt,
          bd_id,
          sum(ifnull(meituan_promotion_quota,0) + ifnull(eleme_promotion_quota,0) + ifnull(jd_promotion_quota,0)) AS quota,
          sum(ifnull(meituan_finished_num,0) + ifnull(eleme_finished_num,0) + ifnull(jd_finished_num,0)) AS order_num
   FROM dwd.dwd_sr_store_promotion
   WHERE dt BETWEEN '2024-12-01' AND '2025-09-21'
     AND date_format(begin_date,'%Y-%m-%d') BETWEEN '2025-01-01' AND '2025-09-21'
     AND status IN (1,
                    4,
                    5)
   GROUP BY 1,
            2) a
LEFT JOIN dim.dim_silkworm_staff_depart b ON a.bd_id=b.bd_id
GROUP BY 1;


-- 城市销单
select
    city_name,
    -- county_name,
	sum(promotion_quota) quota,
	sum(valid_order_num) valid_order_num
from dws.dws_sr_store_takeawaypro_statis_d
where dt between '2025-01-01' and '2025-09-21'
group by 1;


================= 近3个月未发活动商家
SELECT a.merchant_id `商家ID`,
       a.merchant_nickname `商家昵称`,
       a.merchant_real_name `商家真实姓名`,
       a.register_time `注册时间`,
       phone `手机号`,
       c.store_name_list `店铺列表`,
       c.province_name_list `省份列表`,
       c.ity_name_list `城市列表`,
       c.istrict_name_list `区县列表`
FROM dim.dim_silkworm_merchant a
LEFT JOIN
  (SELECT merchant_id,
          store_id
   FROM dwd.dwd_sr_store_promotion
   WHERE date_format(begin_date,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND status IN (1,
                    4,
                    5)
   GROUP BY 1,
            2) b ON a.merchant_id=b.merchant_id
LEFT JOIN
  (SELECT merchant_id,
          GROUP_CONCAT(store_name SEPARATOR ',') store_name_list,
          group_concat(province_name SEPARATOR ',') province_name_list,
          group_concat(city_name SEPARATOR ',') city_name_list,
          group_concat(district_name SEPARATOR ',') district_name_list
   FROM dim.dim_silkworm_store
   GROUP BY 1) c ON c.merchant_id=a.merchant_id
WHERE a.status=0
  AND a.is_logff=0
  AND length(a.phone)=11
  AND a.phone NOT LIKE '%*%'
  AND b.merchant_id IS NULL
  AND c.store_name_list IS NOT NULL
ORDER BY rand() LIMIT 20000;


=========== 
-- 店铺特殊服务费
SELECT store_id `店铺ID`,
       service_charge/100 `特殊服务费`
FROM
  (SELECT store_id,
          get_json_string(store_limit,'$.service_charge') service_charge
   FROM dim.dim_silkworm_store) a
WHERE service_charge IS NOT NULL LIMIT 10;


-- 幸运抽奖 即免费开红包 中奖记录
SELECT cast(create_time AS string) `中奖时间`,
       user_id `用户ID`,
       gift_id `奖品ID`,
       gift_name `奖品名称`,
       CASE
           WHEN gift_value_type=1 THEN '业务奖品'
           WHEN gift_value_type=2 THEN '成本奖品'
           WHEN gift_value_type=3 THEN '权益奖品'
           ELSE '其他'
       END `奖品价值类型`,
       CASE
           WHEN gift_value_subtype=1 THEN '小蚕会员卡券'
           WHEN gift_value_subtype=2 THEN '大牌券'
           WHEN gift_value_subtype=3 THEN '蚕豆红包'
           WHEN gift_value_subtype=4 THEN '1000元京东E卡'
           WHEN gift_value_subtype=5 THEN '小蚕红包'
           WHEN gift_value_subtype=6 THEN '百元打车券'
           WHEN gift_value_subtype=7 THEN '特价活动券'
           WHEN gift_value_subtype=8 THEN '权益卡券优惠券'
           WHEN gift_value_subtype=9 THEN '复活券'
           WHEN gift_value_subtype=10 THEN '小蚕红包组合'
           WHEN gift_value_subtype=11 THEN '非固定金额小蚕红包'
           ELSE '其他'
       END `奖品价值子类型`,
       if(is_get=2,'已领取','未领取') `是否领取` 
       -- card_num `卡券数量`,
       -- red_pack_group `红包组合信息`
FROM dwd.dwd_sr_market_rpd_lottery_winning_record
WHERE dt = '${begin_date}'
  AND activity_type = 1;





======================
-- 店铺品类
SELECT  store_id,
        store_name,
        city_name,
        district_name,
        get_json_object(
            parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
            '$.category1'
        ) AS cate1_name, -- 一级类目
        get_json_object(
            parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
            '$.category2'xc_c
        ) AS cate2_name -- 二级类目
FROM    dim.dim_silkworm_store
where date_format(latest_promotion_time,'%Y-%m-%d')>='2025-09-01'
limit   10;







SELECT a.ym `抽奖月份 `,
       a.gift_name `奖品名称`,
       a.cnt ` 中奖次数 `,
       b.tot_cnt ` 总抽奖次数 `,
       concat(cast(round(a.cnt/b.tot_cnt*100,5) AS string),'%') ` 中奖率 `
FROM
  (SELECT date_format(dt,'%Y-%m') ym,
          gift_name,
          count(*) cnt
   FROM dwd.dwd_sr_market_rpd_lottery_winning_record
   WHERE dt BETWEEN date_format(DATE_TRUNC('month', '${begin_date}'),'%Y-%m-%d') AND '${begin_date}'
     AND user_group_type IN (1,
                             2,
                             3)
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT date_format(dt,'%Y-%m') ym,
          count(*) tot_cnt
   FROM dwd.dwd_sr_market_rpd_lottery_winning_record
   WHERE dt BETWEEN date_format(DATE_TRUNC('month', '${begin_date}'),'%Y-%m-%d') AND '${begin_date}'
     AND user_group_type IN (1,
                             2,
                             3)
   GROUP BY 1) b ON a.ym=b.ym

;



SELECT a.ym `抽奖月份 `,
       a.`奖品价值子类型`,
       a.cnt ` 中奖次数 `,
       b.tot_cnt ` 总抽奖次数 `,
       concat(cast(round(a.cnt/b.tot_cnt*100,5) AS string),'%') ` 中奖率 `
FROM
  (SELECT date_format(dt,'%Y-%m') ym,
		  CASE
		      WHEN user_group_type=1 THEN '普通用户'
		      WHEN user_group_type=2 THEN '疲劳用户'
		      ELSE '羊毛用户'
		  END `用户类型`,
          CASE
              WHEN gift_value_subtype=1 THEN '小蚕会员卡券'
              WHEN gift_value_subtype=2 THEN '大牌券'
              WHEN gift_value_subtype=3 THEN '蚕豆红包'
              WHEN gift_value_subtype=4 THEN '1000元京东E卡'
              WHEN gift_value_subtype=5 THEN '小蚕红包'
              WHEN gift_value_subtype=6 THEN '百元打车券'
              WHEN gift_value_subtype=7 THEN '特价活动券'
              WHEN gift_value_subtype=8 THEN '权益卡券优惠券'
              WHEN gift_value_subtype=9 THEN '复活券'
              WHEN gift_value_subtype=10 THEN '小蚕红包组合'
              WHEN gift_value_subtype=11 THEN '非固定金额小蚕红包'
              ELSE '其他'
          END `奖品价值子类型`,
          count(*) cnt
   FROM dwd.dwd_sr_market_rpd_lottery_winning_record
   WHERE dt BETWEEN date_format(DATE_TRUNC('month', '${begin_date}'),'%Y-%m-%d') AND '${begin_date}'
     AND user_group_type IN (1,
                             2,
                             3)
   GROUP BY 1,
            2,
            3) a
LEFT JOIN
  (SELECT date_format(dt,'%Y-%m') ym,
          count(*) tot_cnt
   FROM dwd.dwd_sr_market_rpd_lottery_winning_record
   WHERE dt BETWEEN date_format(DATE_TRUNC('month', '${begin_date}'),'%Y-%m-%d') AND '${begin_date}'
     AND user_group_type IN (1,
                             2,
                             3)
   GROUP BY 1) b ON a.ym=b.ym






1）奖品名称中，同一抽奖月份或日期，出现名称相同奖品，因部分奖品名称带有“表情符号”，使用时，可以把“中奖次数”指标相加，再去除“总抽奖次数“。2）中奖率=中奖次数/总抽奖次数*100%。

-- 设置更新
DATE_FORMAT(updated_at, '%Y-%m-%d') >= '${T-1}' and DATE_FORMAT(created_at, '%Y-%m-%d') <= '${T-1}'



=============================== AI电话外呼
SELECT dat `外呼日期`,
       count(1) AS `呼叫总量`,
       count(DISTINCT a.silk_id) `通知人数`,
       count(DISTINCT if(a.call_status=2,a.silk_id,NULL)) `未接通人数`,
       count(DISTINCT if(a.call_status=2
                         AND b.order_status IN (2,8),a.silk_id,NULL)) `未接通且完单人数`,
       count(DISTINCT if(a.call_status=1,a.silk_id,NULL)) `接通人数`,
       count(DISTINCT if(a.call_status=1
                         AND b.order_status IN (2,8),a.silk_id,NULL)) `接通且完单人数`
FROM
  (SELECT date_format(created_at,'%Y-%m-%d') AS dat,
          silk_id,
          call_status,
          promotion_order_id
FROM temp.temp_user_ai_phone_call_record
   WHERE date_format(created_at,'%Y-%m-%d') BETWEEN '${begin_date}' AND '${end_date}'
     AND channel=0 -- 来源 0=超时 1=复活 2=拒绝",
) a
LEFT JOIN
  (SELECT cast(right(order_id,9) AS int) AS order_id,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt>=date_sub(current_date(),interval 14 DAY)
     AND date_format(order_time,'%Y-%m-%d') BETWEEN date_sub('${begin_date}',interval 3 day) AND '${end_date}') b ON a.promotion_order_id=b.order_id
GROUP BY 1 ;









背景：
1）小蚕APP、小程序、H5端，在做站内一些广告位置埋点的时候，产品侧期望能够做末次归因，及用户在某个session中，触发了广告位点击，之后的用户行为，会透传这个广告位属性（resource_id、put_id、abtest_id），同session内，当用户点了另外一个广告位，再换为新的广告位属性，继续透传。
2）在统计广告位的曝光次数、点击次数时，现有透传处理逻辑上报的广告位属性，无法区分广告位本身位置的曝光、点击（属于最开始的设计缺陷）。
3）广告位属性获取，当前埋点中，客户端获取后端接口获得。之后，要改为有后端下发给客户端。

客户端处理计划：
1）客户端在处理时，现有透传广告位属性，逻辑仍保留，埋点仍然上报前述提到的3个广告位属性。不过，广告位属性改为获取后端下发的数据。
2）后端下发给客户端广告位属性，统一用tracing参数，将广告位属性拼接（如 3-12-65），埋点也上报tracing属性。
3）数据上报后，统计数据时，如统计广告位本身的曝光、点击次数，使用tracing属性统计，统计某行为归因的时候，使用透传广告位属性。
4）对站内近200个广告位，逐个添加tracing属性。

诉求：
1）处理计划中的第4点，逐个广告位添加处理，费时费力，能否有更简洁的处理方式，如有，期望能得到神策放协助。



-- 昨日活跃用户城市top20
select
  a.city_name `城市`,
  a.`昨日活跃用户量`,
  b.`注册用户量`,
  a.`昨日活跃用户量`/b.`注册用户量` `昨日访问率`
from
(SELECT 
       city_name,
       bitmap_union_count(view_uids) `昨日活跃用户量`
FROM dws.dws_sr_user_login_d
WHERE statistics_date=date_sub(current_date(),interval 1 DAY)
GROUP BY 1
order by 2 desc limit 20) a
left join
(SELECT 
            city_name name,
            count(1) `注册用户量`
FROM dwd.dwd_silkworm_user_feature_data
WHERE city_name<>'未知'
GROUP BY 1) b ON a.city_name=b.city_name;



-- 外卖累计有效订单量分布
select
    count(1) `用户量`,
    min(accu_valid_order_num) min_num,
    percentile_cont(accu_valid_order_num,0.1) `10分位`,
    percentile_cont(accu_valid_order_num,0.2) `20分位`,
    percentile_cont(accu_valid_order_num,0.3) `30分位`,
    percentile_cont(accu_valid_order_num,0.4) `40分位`,
    percentile_cont(accu_valid_order_num,0.5) `50分位`,
    percentile_cont(accu_valid_order_num,0.6) `60分位`,
    percentile_cont(accu_valid_order_num,0.7) `70分位`,
    percentile_cont(accu_valid_order_num,0.8) `80分位`,
    percentile_cont(accu_valid_order_num,0.9) `90分位`,
    max(accu_valid_order_num) max_num
-- from 
-- (
-- SELECT 
--  accu_valid_order_num,
--     count(1) `截止昨日累计用户量`
from dim.dim_silkworm_user
;


-- 昨日访问用户分布
select
`设备品牌`,ceil(avg(`用户量`)) `用户量`
from
(select 
date_format(time,'%Y-%m-%d') dat,
    -- $manufacturer `设备制造商`,
    lower(if($brand is null,'其他',$brand)) `设备品牌`,
    -- $model `机型`,
    -- $os `操作系统`,
    -- $os_version `操作系统版本`,
    -- $app_version `应用版本`,
    count(distinct distinct_id) `用户量`
from dwd.dwd_sr_traffic_sensor_event_log_realtime 
where date_format(time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and distinct_id regexp '^[0-9]{1,10}$'
group by 1,2) a
group by 1
order by 2 desc;


-- 昨日访问用户分布

SELECT CASE
           WHEN `设备品牌`='vivo' THEN 'vivo'
           WHEN `设备品牌`='redmi' THEN '红米'
           WHEN `设备品牌`='xiaomi' THEN '小米'
           WHEN `设备品牌`='huawei' THEN '华为'
           WHEN `设备品牌`='honor' THEN '荣耀'
           WHEN `设备品牌`='iphone' THEN '苹果'
           WHEN `设备品牌`='oppo' THEN 'OPPO'
           WHEN `设备品牌`='oneplus' THEN '一加'
           WHEN `设备品牌`='realme' THEN '真我'
           WHEN `设备品牌`='samsung' THEN '三星'
           WHEN `设备品牌`='meizu' THEN '魅族'
           WHEN `设备品牌`='nubia' THEN '努比亚'
           ELSE '其他'
       END `设备品牌`,
       ceil(avg(`用户量`)) `用户量`
FROM
  (SELECT date_format(time,'%Y-%m-%d') dat,
          lower($brand) `设备品牌`,
          count(DISTINCT distinct_id) `用户量`
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND distinct_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2) a
GROUP BY 1
ORDER BY 2 DESC;



SELECT `操作系统`,
       ceil(avg(`用户量`)) `用户量`
FROM
  (SELECT date_format(time,'%Y-%m-%d') dat,
          $os `操作系统`,
              count(DISTINCT distinct_id) `用户量`
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND distinct_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2) a
GROUP BY 1
ORDER BY 2 DESC;




-- mau
-- 1-8月用自采
SELECT date_format(dt,'%Y-%m') ym,
       bitmap_union_count(user_ids) mau
FROM dwd.dwd_sr_traffic_viewuser_d
WHERE dt BETWEEN '2025-01-01' AND '2025-08-31'
GROUP BY 1

UNION ALL 
-- 9月及之后用神策
SELECT date_format(time,'%Y-%m') ym,
       count(DISTINCT distinct_id) mau
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-09-01' AND date_sub(current_date(),interval 1 DAY)
  AND distinct_id regexp '^[0-9]{1,10}$'
GROUP BY 1;



SELECT hr,
       min(`微信提现金额`) `最小值`,
       percentile_cont(`微信提现金额`,0.1) `10分位`,
       percentile_cont(`微信提现金额`,0.2) `20分位`,
       percentile_cont(`微信提现金额`,0.3) `30分位`,
       percentile_cont(`微信提现金额`,0.4) `40分位`,
       percentile_cont(`微信提现金额`,0.5) `50分位`,
       percentile_cont(`微信提现金额`,0.6) `60分位`,
       percentile_cont(`微信提现金额`,0.7) `70分位`,
       percentile_cont(`微信提现金额`,0.8) `80分位`,
       percentile_cont(`微信提现金额`,0.9) `90分位`,
       max(`微信提现金额`) `最大值`,
       min(`支付宝提现金额`) `最小值`,
       percentile_cont(`支付宝提现金额`,0.1) `10分位`,
       percentile_cont(`支付宝提现金额`,0.2) `20分位`,
       percentile_cont(`支付宝提现金额`,0.3) `30分位`,
       percentile_cont(`支付宝提现金额`,0.4) `40分位`,
       percentile_cont(`支付宝提现金额`,0.5) `50分位`,
       percentile_cont(`支付宝提现金额`,0.6) `60分位`,
       percentile_cont(`支付宝提现金额`,0.7) `70分位`,
       percentile_cont(`支付宝提现金额`,0.8) `80分位`,
       percentile_cont(`支付宝提现金额`,0.9) `90分位`,
       max(`支付宝提现金额`) `最大值`,
       min(`总提现金额`) `最小值`,
       percentile_cont(`总提现金额`,0.1) `10分位`,
       percentile_cont(`总提现金额`,0.2) `20分位`,
       percentile_cont(`总提现金额`,0.3) `30分位`,
       percentile_cont(`总提现金额`,0.4) `40分位`,
       percentile_cont(`总提现金额`,0.5) `50分位`,
       percentile_cont(`总提现金额`,0.6) `60分位`,
       percentile_cont(`总提现金额`,0.7) `70分位`,
       percentile_cont(`总提现金额`,0.8) `80分位`,
       percentile_cont(`总提现金额`,0.9) `90分位`,
       max(`总提现金额`) `最大值`,
       min(`微信提现用户量`) `最小值`,
       percentile_cont(`微信提现用户量`,0.1) `10分位`,
       percentile_cont(`微信提现用户量`,0.2) `20分位`,
       percentile_cont(`微信提现用户量`,0.3) `30分位`,
       percentile_cont(`微信提现用户量`,0.4) `40分位`,
       percentile_cont(`微信提现用户量`,0.5) `50分位`,
       percentile_cont(`微信提现用户量`,0.6) `60分位`,
       percentile_cont(`微信提现用户量`,0.7) `70分位`,
       percentile_cont(`微信提现用户量`,0.8) `80分位`,
       percentile_cont(`微信提现用户量`,0.9) `90分位`,
       max(`微信提现用户量`) `最大值`,
       min(`支付宝提现用户量`) `最小值`,
       percentile_cont(`支付宝提现用户量`,0.1) `10分位`,
       percentile_cont(`支付宝提现用户量`,0.2) `20分位`,
       percentile_cont(`支付宝提现用户量`,0.3) `30分位`,
       percentile_cont(`支付宝提现用户量`,0.4) `40分位`,
       percentile_cont(`支付宝提现用户量`,0.5) `50分位`,
       percentile_cont(`支付宝提现用户量`,0.6) `60分位`,
       percentile_cont(`支付宝提现用户量`,0.7) `70分位`,
       percentile_cont(`支付宝提现用户量`,0.8) `80分位`,
       percentile_cont(`支付宝提现用户量`,0.9) `90分位`,
       max(`支付宝提现用户量`) `最大值`,
       min(`总提现用户量`) `最小值`,
       percentile_cont(`总提现用户量`,0.1) `10分位`,
       percentile_cont(`总提现用户量`,0.2) `20分位`,
       percentile_cont(`总提现用户量`,0.3) `30分位`,
       percentile_cont(`总提现用户量`,0.4) `40分位`,
       percentile_cont(`总提现用户量`,0.5) `50分位`,
       percentile_cont(`总提现用户量`,0.6) `60分位`,
       percentile_cont(`总提现用户量`,0.7) `70分位`,
       percentile_cont(`总提现用户量`,0.8) `80分位`,
       percentile_cont(`总提现用户量`,0.9) `90分位`,
       max(`总提现用户量`) `最大值`
FROM
  (SELECT dt,
          hour(create_time) hr,
          sum(if(withdraw_pattern=0,withdraw_amt/100,0)) `微信红包提现金额`,
          sum(if(withdraw_pattern=5,withdraw_amt/100,0)) `云账户微信多笔转账提现金额`,
          sum(if(withdraw_pattern IN (0,5),withdraw_amt/100,0)) `微信提现金额`,
          sum(if(withdraw_pattern=2,withdraw_amt/100,0)) `支付宝转账提现金额`,
          sum(if(withdraw_pattern=6,withdraw_amt/100,0)) `云账户微信多笔转账提现金额`,
          sum(if(withdraw_pattern IN (2,6),withdraw_amt/100,0)) `支付宝提现金额`,
          sum(withdraw_amt/100) `总提现金额`,
          count(DISTINCT if(withdraw_pattern=0,user_id,NULL)) `微信红包提现用户量`,
          count(DISTINCT if(withdraw_pattern=5,user_id,NULL)) `云账户微信多笔转账提现用户量`,
          count(DISTINCT if(withdraw_pattern IN (0,5),user_id,NULL)) `微信提现用户量`,
          count(DISTINCT if(withdraw_pattern=2,user_id,NULL)) `支付宝转账提现用户量`,
          count(DISTINCT if(withdraw_pattern=6,user_id,NULL)) `云账户微信多笔转账提现用户量`,
          count(DISTINCT if(withdraw_pattern IN (2,6),user_id,NULL)) `支付宝提现用户量`,
          count(DISTINCT user_id) `总提现用户量`
   FROM dwd.dwd_sr_user_withdraw_record
   WHERE dt BETWEEN '2025-09-01' AND '2025-09-30'
     AND status=1
   GROUP BY 1,
            2) t
GROUP BY 1;


-- 打款渠道限额 客诉
select
    date_format(create_time,'%Y-%m') `统计日期`,
    count(distinct session_id) `会话数`,
    count(distinct user_id) `用户量`
from dwd.dwd_sr_qimo_session
where date_format(create_time,'%Y-%m-%d')>='2025-01-01' 
and tag_content regexp '打款渠道限额'
group by 1
;


select count(1) tot,count(distinct user_id) unum from dwd.dwd_sr_qimo_session;


-- 最近一次登录距昨日间隔天数
SELECT CASE
           WHEN `间隔天数`=0 THEN '昨日访问'
           WHEN `间隔天数`=1 THEN '前日访问'
           WHEN `间隔天数` BETWEEN 2 AND 5 THEN '2-5天前访问'
           WHEN `间隔天数` BETWEEN 6 AND 14 THEN '6-14天前访问'
           WHEN `间隔天数` BETWEEN 15 AND 30 THEN '15-30天前访问'
           WHEN `间隔天数`>30 THEN '30天前访问'
           ELSE '其他'
       END `最近一次登录距昨日间隔天数`,
       sum(`用户量`) `用户量`
FROM
  (SELECT date_diff('day',date_sub(current_date(),interval 1 DAY),date_format(last_login_time,'%Y-%m-%d')) `间隔天数`,
          count(1) `用户量`
   FROM dwd.dwd_silkworm_user_feature_data
   WHERE date_format(last_login_time,'%Y-%m-%d')<>date_sub(current_date(),interval 0 DAY)
     AND date_format(last_login_time,'%Y-%m-%d')<>'1970-01-01'
   GROUP BY 1) a
GROUP BY 1;




-- 近7日日均外卖详情页PV
SELECT count(1) cnt,
       min(avg_pv) min_pv,
       percentile_cont(avg_pv,0.1) fw10,
       percentile_cont(avg_pv,0.2) fw20,
       percentile_cont(avg_pv,0.3) fw30,
       percentile_cont(avg_pv,0.4) fw40,
       percentile_cont(avg_pv,0.5) fw50,
       percentile_cont(avg_pv,0.6) fw60,
       percentile_cont(avg_pv,0.7) fw70,
       percentile_cont(avg_pv,0.8) fw80,
       percentile_cont(avg_pv,0.9) fw90,
       max(avg_pv) max_pv ,
       CASE
           WHEN avg_pv <2 THEN '日均1次'
           WHEN avg_pv BETWEEN 2 AND 3 THEN '日均2-3次'
           WHEN avg_pv BETWEEN 4 AND 6 THEN '日均4-6次'
           WHEN avg_pv>6 THEN '日均7次及以上'
           ELSE '其他'
       END `近7日日均外卖详情页访问次数`,
       count(1) `用户量`
FROM
  (SELECT distinct_id,
          ceil(avg(pv)) avg_pv
   FROM
     (SELECT date_format(time,'%Y-%m-%d') dat,
             distinct_id,
             count(1) pv
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND distinct_id regexp '^[0-9]{1,10}$'
        AND event='Takeaway_Detailpage_View'
      GROUP BY 1,
               2) a
   GROUP BY 1) b
GROUP BY 1;


SELECT count(1) cnt,
       min(avg_cnt) min_pv,
       percentile_cont(avg_cnt,0.1) fw10,
       percentile_cont(avg_cnt,0.2) fw20,
       percentile_cont(avg_cnt,0.3) fw30,
       percentile_cont(avg_cnt,0.4) fw40,
       percentile_cont(avg_cnt,0.5) fw50,
       percentile_cont(avg_cnt,0.6) fw60,
       percentile_cont(avg_cnt,0.7) fw70,
       percentile_cont(avg_cnt,0.8) fw80,
       percentile_cont(avg_cnt,0.9) fw90,
       max(avg_cnt) max_pv ,
       CASE
           WHEN avg_cnt <2 THEN '日均1次'
           WHEN avg_cnt BETWEEN 2 AND 3 THEN '日均2-3次'
           WHEN avg_cnt BETWEEN 4 AND 6 THEN '日均4-6次'
           WHEN avg_cnt>6 THEN '日均7次及以上'
           ELSE '其他'
       END `近7日日均外卖报名按钮点击次数`,
       count(1) `用户量`
FROM
  (SELECT distinct_id,
          ceil(avg(cnt)) avg_cnt
   FROM
     (SELECT date_format(time,'%Y-%m-%d') dat,
             distinct_id,
             count(1) cnt
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND distinct_id regexp '^[0-9]{1,10}$'
        AND event='Takeaway_Baomingflow_Button_Click'
        and button_name in ('领红包并确定报名','立即报名领返利','立即抢单')
      GROUP BY 1,
               2) a
   GROUP BY 1) b
GROUP BY 1;




-- 近7日日均外卖详情页PV
SELECT '访问' `类型`,
            CASE
                WHEN avg_pv <2 THEN '日均1次'
                WHEN avg_pv BETWEEN 2 AND 3 THEN '日均2-3次'
                WHEN avg_pv BETWEEN 4 AND 6 THEN '日均4-6次'
                WHEN avg_pv>6 THEN '日均7次及以上'
                ELSE '其他'
            END `近7日日均外卖详情页访问次数`,
            count(1) `用户量`
FROM
  (SELECT distinct_id,
          ceil(avg(pv)) avg_pv
   FROM
     (SELECT date_format(time,'%Y-%m-%d') dat,
             distinct_id,
             count(1) pv
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND distinct_id regexp '^[0-9]{1,10}$'
        AND event='Takeaway_Detailpage_View'
      GROUP BY 1,
               2) a
   GROUP BY 1) b
GROUP BY 1

UNION ALL 

-- 近7日日均外卖报名按钮点击次数
SELECT '点击' `类型`,
            CASE
                WHEN avg_cnt <=1 THEN '日均1次'
                WHEN avg_cnt BETWEEN 2 AND 3 THEN '日均2-3次'
                WHEN avg_cnt>=4 THEN '日均4次及以上'
                ELSE '其他'
            END `近7日日均外卖报名按钮点击次数`,
            count(1) `用户量`
FROM
  (SELECT distinct_id,
          ceil(avg(cnt)) avg_cnt
   FROM
     (SELECT date_format(time,'%Y-%m-%d') dat,
             distinct_id,
             count(1) cnt
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND distinct_id regexp '^[0-9]{1,10}$'
        AND event='Takeaway_Baomingflow_Button_Click'
        AND button_name IN ('领红包并确定报名',
                            '立即报名领返利',
                            '立即抢单')
      GROUP BY 1,
               2) a
   GROUP BY 1) b
GROUP BY 1


SELECT CASE
           WHEN order_num=1 THEN '完成1单'
           WHEN order_num BETWEEN 2 AND 3 THEN '完成2-3单'
           WHEN order_num BETWEEN 4 AND 8 THEN '完成4-8单'
           WHEN order_num>=9 THEN '完成9单及以上'
           ELSE '其他'
       END `近7日累计完单量分布`,
       count(1) `用户量`
FROM
  (SELECT user_id,
          count(1) order_num
   FROM dwd.dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND order_status IN (2,
                          8)
   GROUP BY 1) a
GROUP BY 1





WITH t1 AS (
    SELECT  store_id,
             date_format(begin_date, '%Y-%m-%d') as begin_date,
            store_promotion_id,
            sum(ifnull(meituan_promotion_quota,0) + ifnull(eleme_promotion_quota,0) +ifnull(jd_promotion_quota,0)) as tot_promotion_quota
    FROM    dwd.dwd_sr_store_promotion
    WHERE   dt BETWEEN date_sub(current_date(),interval 14 DAY)
    AND     date_sub(current_date(),interval 1 DAY)
    AND     date_format(begin_date, '%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY)
    AND     date_sub(current_date(),interval 1 DAY)
    AND     status IN (1, 4, 5)
  group by 1,2,3
),

order_t AS (
    SELECT  order_time,
            substr(order_time, 12, 2) AS hour_t,
            user_id,
            order_id,
            store_promotion_id
    FROM    dwd.dwd_sr_order_promotion_order
    WHERE   dt BETWEEN date_sub(current_date(),interval 7 DAY) and date_sub(current_date(),interval 1 DAY)
    and     order_status IN (2, 8)
), 

-- 店铺
t2 AS (
    SELECT  store_id,
            store_name,
            city_name,
            district_name,
            xc_category,
            store_banner_list,
            get_json_object(
                parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
                '$.category1'
            ) AS cate1_name, -- 一级类目
            get_json_object(
                parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
                '$.category2'
            ) AS cate2_name -- 二级类目
    FROM    dim.dim_silkworm_store
)


SELECT  t2.cate1_name,
        t2.cate2_name,
        count(distinct t.order_id) as `有效订单量`
        count(distinct t.user_id) as `有效用户量`,
        count(distinct t1.store_promotion_id) as store_promotion_num, -- 活动数
        count(distinct t1.store_id) as store_num, -- 店铺数
        sum(tot_promotion_quota) as tot_promotion_quota -- 活动名额
FROM    order_t t
left join t1
on      t.store_promotion_id = t1.store_promotion_id
INNER JOIN t2
ON      t1.store_id = t2.store_id
GROUP BY 1,
         2;


-- 留存
with t as
(select
    user_id,
    statistics_date
from dws.dws_sr_traffic_user_d
where statistics_date between '2025-06-01' and '2025-07-10'
and user_id regexp '^[0-9]{1,10}$'
group by 1,2)

select
    a.statistics_date,
    count(distinct a.user_id) tot_unm,
    count(distinct if(date_diff('day',b.statistics_date,a.statistics_date)=1,a.user_id,null)) nd_unum,
    count(distinct if(date_diff('day',b.statistics_date,a.statistics_date)=3,a.user_id,null)) 3d_unum,
    count(distinct if(date_diff('day',b.statistics_date,a.statistics_date)=5,a.user_id,null)) 5d_unum,
    count(distinct if(date_diff('day',b.statistics_date,a.statistics_date)=7,a.user_id,null)) 7d_unum,
    count(distinct if(date_diff('day',b.statistics_date,a.statistics_date)=14,a.user_id,null)) 14d_unum,
    count(distinct if(date_diff('day',b.statistics_date,a.statistics_date)=30,a.user_id,null)) 30d_unum
from t a
left join t b on a.user_id=b.user_id and a.statistics_date<>b.statistics_date
group by 1;




-- 近7日日均外卖报名按钮点击次数
SELECT cnt `近7日访问天数`,
            count(1) `用户量`
FROM
  (SELECT distinct_id,
          count(distinct dat) cnt
   FROM
     (SELECT date_format(time,'%Y-%m-%d') dat,
             distinct_id
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date_format(time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND distinct_id regexp '^[0-9]{1,10}$'
      GROUP BY 1,
               2) a
   GROUP BY 1) b
GROUP BY 1
;


-- 近2个月没有发活动商家随机取1万条数据
SELECT a.merchant_id `商家ID`,
       a.merchant_nickname `商家昵称`,
       a.merchant_real_name `商家真实姓名`,
       a.register_time `注册时间`,
       cast(phone AS string) `手机号`,
       c.store_name_list `店铺列表`,
       c.province_name_list `省份列表`,
       c.city_name_list `城市列表`,
       c.district_name_list `区县列表`
FROM dim.dim_silkworm_merchant a
LEFT JOIN
  (SELECT merchant_id,
          store_id
   FROM dwd.dwd_sr_store_promotion
   -- WHERE date_format(begin_date,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY)
   WHERE date_format(begin_date,'%Y-%m-%d') BETWEEN '2025-10-01' AND date_sub(current_date(),interval 1 DAY)
     AND status IN (1,
                    4,
                    5)
   GROUP BY 1,
            2) b ON a.merchant_id=b.merchant_id
LEFT JOIN
  (SELECT merchant_id,
          GROUP_CONCAT(store_name SEPARATOR ',') store_name_list,
          group_concat(province_name SEPARATOR ',') province_name_list,
          group_concat(city_name SEPARATOR ',') city_name_list,
          group_concat(district_name SEPARATOR ',') district_name_list
   FROM dim.dim_silkworm_store
   GROUP BY 1) c ON c.merchant_id=a.merchant_id
WHERE a.status=0
  AND a.is_logff=0
  AND length(a.phone)=11
  AND a.phone NOT LIKE '%*%'
  AND b.merchant_id IS NULL
  AND c.store_name_list IS NOT NULL
ORDER BY rand() LIMIT 10000;



-- 挑战赛支出
t5 as (
    SELECT
        challenge_id,
        user_id,
        dt,
        challenge_type,
        sum(reward_value)/100 as reward_value
    from(
        SELECT
            challenge_id,
            takepart_id,
            stage,
            get_json_int(value,'$.SilkId') as user_id,
            dt,
            challenge_type,
            ifnull(ROUND(reward_value/sum(get_json_int(value,'$.TaskNum')) over(PARTITION BY takepart_id,stage) * get_json_int(value,'$.TaskNum')),0) as reward_value
        FROM(
            SELECT 
                challenge_id,
                takepart_id,
                group_user_id_list,
                challenge_type,
                get_json_int(value,'$.ExpectNum'),
                CASE
                    WHEN get_json_int(value,'$.ExpectNum') > current_progress THEN 0
                    WHEN get_json_int(value,'$.RewardType') = 1 THEN get_json_int(value,'$.RewardNum')
                    WHEN get_json_int(value,'$.RewardType') = 2 and get_json_int(value,'$.CardType') = 3 THEN 1000
                    WHEN get_json_int(value,'$.RewardType') = 3 THEN get_json_int(value,'$.RewardNum')
                    WHEN get_json_int(value,'$.RewardType') = 4 THEN 0
                END AS reward_value,
                IF(get_json_int(value,'$.Stage') > 0,get_json_int(value,'$.Stage'),`key`) as stage,
                from_unixtime(get_json_object(stage_finished_reward,concat('$[',IF(get_json_int(value,'$.Stage') > 0,get_json_int(value,'$.Stage'),`key`),']')), 'yyyy-MM-dd') AS dt
            FROM 
                dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(stage_task)) AS t1111
                where challenge_type in (1,2) -- 2表示拉新挑战赛 1下单挑战赛
        ) as t111,json_each(parse_json(group_user_id_list)) AS t222
        WHERE
             dt >='2024-04-07' -- 最早时间
             -- BETWEEN '2025-01-01' AND '2025-05-31' 
            
    ) as tt_1
    group BY
        1,2,3,4
),



-- 新用户访问留存
select
    statistic_date,
    sum(register_num) reg_num,
    sum(acc_1d_retention_num) acc_1d_retention_num,
    sum(acc_2d_retention_num) acc_2d_retention_num,
    sum(acc_3d_retention_num) acc_3d_retention_num,
    sum(acc_4d_retention_num) acc_4d_retention_num,
    sum(acc_5d_retention_num) acc_5d_retention_num,
    sum(acc_7d_retention_num) acc_7d_retention_num,
    sum(acc_14d_retention_num) acc_14d_retention_num,
    sum(acc_30d_retention_num) acc_30d_retention_num
from dws.dws_sr_user_newuser_retention_d
where statistic_date between '2025-08-01' and '2025-10-16'
group by 1;



-- 0库存活动占比
SELECT date_format(begin_date,'%Y-%m-%d') dat,
       count(1) `活动量`,
       count(if((meituan_promotion_quota+eleme_promotion_quota+jd_promotion_quota) = (meituan_promotion_remain_quota+eleme_promotion_remain_quota+jd_promotion_remain_quota),store_promotion_id,NULL) ) `0库存活动量`,
       count(if((meituan_promotion_quota+eleme_promotion_quota+jd_promotion_quota) = (meituan_promotion_remain_quota+eleme_promotion_remain_quota+jd_promotion_remain_quota),store_promotion_id,NULL) )/count(1) `0库存活动占比`
FROM dwd.dwd_sr_store_promotion
WHERE dt BETWEEN '2025-08-20' AND '2025-09-20'
  AND date_format(begin_date,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-09-20'
GROUP BY 1;


-- 自采

SELECT event_date,
       count(1) cnt
FROM dwd.dwd_sr_traffic_user_view
WHERE event_date BETWEEN '2025-10-11' AND '2025-10-16'
GROUP BY 1;

-- 神策
SELECT date_format(time,'%Y-%m-%d') dat,
       count(DISTINCT distinct_id) cnt
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-09-11' AND '2025-10-16'
  AND distinct_id regexp '^[0-9]{1,10}$'
GROUP BY 1;


-- 用户完单和拉新
SELECT count(DISTINCT a.user_id) unum
FROM
  ( SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE accu_valid_order_num >= 3 ) a
LEFT JOIN
  ( SELECT inviter_user_id,
           count(1) cnt
   FROM dim.dim_silkworm_user
   WHERE inviter_user_id <> 0 -- where inviter_user_id  in (1355018,2680246,3410357,4280469,4857046)

   GROUP BY 1 ) b ON a.user_id = b.inviter_user_id
WHERE b.cnt IS NULL;

==================
-- 近7日用户访问天数
WITH t1 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
   GROUP BY 1,
            2),


 t2 AS
  (SELECT a.dat,
          a.user_id,
          a.cnt
   FROM
     (SELECT date_sub(current_date(),interval 1 DAY) AS dat,
             user_id,
             count(DISTINCT statistics_date) cnt
      FROM t1
      GROUP BY 1,
               2) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY)) b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL)


SELECT dat `访问日期`,
       count(1) `DAU`,
       min(cnt) `最小值`,
       percentile_cont(cnt,0.1) `10分位`,
       percentile_cont(cnt,0.2) `20分位`,
       percentile_cont(cnt,0.25) `25分位`,
       percentile_cont(cnt,0.3) `30分位`,
       percentile_cont(cnt,0.4) `40分位`,
       percentile_cont(cnt,0.5) `50分位`,
       percentile_cont(cnt,0.6) `60分位`,
       percentile_cont(cnt,0.7) `70分位`,
       percentile_cont(cnt,0.75) `75分位`,
       percentile_cont(cnt,0.8) `80分位`,
       percentile_cont(cnt,0.9) `90分位`,
       max(cnt) `最大值`
FROM t2
GROUP BY 1;


-- 近7日访问
WITH t1 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN date_sub(current_date(),interval 8 DAY) AND date_sub(current_date(),interval 2 DAY)
   GROUP BY 1,
            2),

-- 截止昨日沉默用户
-- select count(a.user_id) from
-- (SELECT user_id
--       FROM dim.dim_silkworm_user
--       WHERE date_format(register_time,'%Y-%m-%d')<>'2025-10-20' -- date_sub(current_date(),interval 4 DAY)
--       ) a
-- left join
--      (SELECT 
--              user_id,
--              count(DISTINCT statistics_date) cnt
--       FROM t1
--       GROUP BY 1
--                ) b  
--     ON a.user_id=b.user_id
-- WHERE b.user_id IS NULL;

-- 昨日日活 排除当日注册
     t2 AS
  (SELECT a.dat,
          a.user_id,
          a.cnt
   FROM
     (SELECT date_sub(current_date(),interval 2 DAY) AS dat,
             user_id,
             count(DISTINCT statistics_date) cnt
      FROM t1
      GROUP BY 1,
               2) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d')='2025-10-20' -- date_sub(current_date(),interval 4 DAY)
      ) b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL)


-- 近7日访问天数分布
-- SELECT dat `统计日期`,
--        count(1) `近7日访问用户量`,
--        min(cnt) `最小值`,
--        percentile_cont(cnt,0.1) `10分位`,
--        percentile_cont(cnt,0.2) `20分位`,
--        percentile_cont(cnt,0.25) `25分位`,
--        percentile_cont(cnt,0.3) `30分位`,
--        percentile_cont(cnt,0.4) `40分位`,
--        percentile_cont(cnt,0.5) `50分位`,
--        percentile_cont(cnt,0.6) `60分位`,
--        percentile_cont(cnt,0.7) `70分位`,
--        percentile_cont(cnt,0.75) `75分位`,
--        percentile_cont(cnt,0.8) `80分位`,
--        percentile_cont(cnt,0.9) `90分位`,
--        max(cnt) `最大值`
-- FROM t2
-- GROUP BY 1;

-- 活跃用户量级
-- select
--     count(1) `近7日访问用户量`,
--     count(if(cnt=1,user_id,null)) `低活跃用户量`,
--     count(if(cnt between 2 and 5,user_id,null)) `中活跃用户量`,
--     count(if(cnt>5,user_id,null)) `高活跃用户量`
-- from t2;

-- DAU用户类型分布
SELECT statistics_date `访问日期`,
       CASE
           WHEN b.user_id IS NOT NULL THEN '当日注册用户'
           WHEN t2.cnt=1 THEN '低活跃用户'
           WHEN t2.cnt BETWEEN 2 AND 5 THEN '中活跃用户'
           WHEN cnt>5 THEN '高活跃用户'
           WHEN t2.cnt IS NULL THEN '沉默用户'
           ELSE '其他'
       END `用户类型`,
       count(DISTINCT a.user_id) dau
FROM
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date = date_sub(current_date(),interval 1 DAY)
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY) ) b ON a.user_id=b.user_id
LEFT JOIN t2 ON a.user_id=t2.user_id
GROUP BY 1,
         2;

-- 昨日DAU
SELECT statistics_date,
       bitmap_union_count(view_uids) dau
FROM dws.dws_sr_user_login_d
WHERE statistics_date=date_sub(current_date(),interval 1 DAY)
GROUP BY 1;





-- 9月25日访问用户的近7日访问天数
WITH t1 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN '2025-09-18' AND '2025-09-24'
   GROUP BY 1,
            2),

-- 昨日日活 排除当日注册
dau AS
  (SELECT a.dat,
          a.user_id,
          a.cnt
   FROM
     (SELECT date_sub(current_date(),interval 2 DAY) AS dat,
             user_id,
             count(DISTINCT statistics_date) cnt
      FROM t1
      GROUP BY 1,
               2) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d')='2025-09-25' -- date_sub(current_date(),interval 4 DAY)
      ) b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL),

-- DAU用户类型分布
t2 AS 
(SELECT statistics_date,
       CASE
           WHEN b.user_id IS NOT NULL THEN '当日注册用户'
           WHEN t2.cnt=1 THEN '低活跃用户'
           WHEN t2.cnt BETWEEN 2 AND 5 THEN '中活跃用户'
           WHEN cnt>5 THEN '高活跃用户'
           WHEN t2.cnt IS NULL THEN '沉默用户'
           ELSE '其他'
       END `用户类型`,
       a.user_id
FROM
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date = '2025-09-25'
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d')='2025-09-25') b ON a.user_id=b.user_id
LEFT JOIN dau t2 ON a.user_id=t2.user_id
GROUP BY 1,
         2,
         3),

-- 26号后访问
t3 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN '2025-09-26' AND '2025-09-30'
   GROUP BY 1,
            2)

SELECT t2.`用户类型`,
       count(DISTINCT t2.user_id) `DAU`,
       count(DISTINCT if(date_diff('day',t3.statistics_date,t2.statistics_date)=1,t2.user_id,NULL)) `次日留存用户量`,
       count(DISTINCT if(date_diff('day',t3.statistics_date,t2.statistics_date)=2,t2.user_id,NULL)) `次2日留存用户量`,
       count(DISTINCT if(date_diff('day',t3.statistics_date,t2.statistics_date)=3,t2.user_id,NULL)) `次3日留存用户量`,
       count(DISTINCT if(date_diff('day',t3.statistics_date,t2.statistics_date)=4,t2.user_id,NULL)) `次4日留存用户量`,
       count(DISTINCT if(date_diff('day',t3.statistics_date,t2.statistics_date)=5,t2.user_id,NULL)) `次5日留存用户量`
FROM t2
LEFT JOIN t3 ON t2.user_id=t3.user_id
AND t2.statistics_date<>t3.statistics_date
GROUP BY 1


-- 注册用户当日完单转化和访问留存
SELECT register_date `注册日期`,
       user_type `用户类型`,
       count(DISTINCT a.user_id) `注册用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=1,a.user_id,NULL)) `次日留存用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=2,a.user_id,NULL)) `次2日留存用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=3,a.user_id,NULL)) `次3日留存用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=4,a.user_id,NULL)) `次4日留存用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=5,a.user_id,NULL)) `次5日留存用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=6,a.user_id,NULL)) `次6日留存用户量`,
       count(DISTINCT if(date_diff('day',b.statistics_date,a.register_date)=7,a.user_id,NULL)) `次7日留存用户量`
FROM
  (SELECT date_format(register_time,'%Y-%m-%d') register_date,
          user_id,
          if(date_format(register_time,'%Y-%m-%d')=date_format(first_valid_order_time,'%Y-%m-%d'),'首单','非首单') user_type
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-09-18' AND '2025-09-24') a
LEFT JOIN
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN '2025-09-19' AND '2025-09-30'
   GROUP BY 1,
            2) b ON a.user_id=b.user_id
AND a.register_date<>b.statistics_date
GROUP BY 1,
         2;





-- 完单量下用户分布
-- 9月25日访问用户的近7日访问天数
WITH t1 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN '2025-09-18' AND '2025-09-24'
   GROUP BY 1,
            2),

  -- 完单量
t3 as
  (SELECT user_id,if(order_num>=4,'>=4单用户','<4单用户') user_type
   FROM
     (SELECT user_id, coalesce(count(1),0) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt<='2025-09-24'
        AND order_status IN (2,8)
      GROUP BY 1) a)

-- -- 截止昨日沉默用户
SELECT if(t3.user_id IS NULL,'<4单用户',user_type) user_type,
       count(a.user_id)
FROM
  (SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d')<='2025-09-24') a
LEFT JOIN
  (SELECT user_id,
          count(DISTINCT statistics_date) cnt
   FROM t1
   GROUP BY 1 ) b ON a.user_id=b.user_id
LEFT JOIN t3 ON a.user_id=t3.user_id
WHERE b.user_id IS NULL
group by 1;


-- 昨日日活 排除当日注册
 t2 AS
  (SELECT a.user_id,
          a.cnt
   FROM
     (SELECT user_id,
             count(DISTINCT statistics_date) cnt
      FROM t1
      GROUP BY 1) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d')='2025-09-25' ) b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL),

-- -- 完单量
-- t3 as
--   (SELECT user_id,if(order_num>=4,'>=4单用户','<4单用户') user_type
--    FROM
--      (SELECT user_id, coalesce(count(1),0) order_num
--       FROM dwd.dwd_sr_order_promotion_order
--       WHERE dt<='2025-09-24'
--         AND order_status IN (2,8)
--       GROUP BY 1) a)


-- 活跃用户量级
SELECT if(t3.user_id is null,'<4单用户',user_type) user_type,
       count(1) `近7日访问用户量`,
       count(if(cnt=1,t2.user_id,NULL)) `低活跃用户量`,
       count(if(cnt BETWEEN 2 AND 5,t2.user_id,NULL)) `中活跃用户量`,
       count(if(cnt>5,t2.user_id,NULL)) `高活跃用户量`
FROM t2
LEFT JOIN t3 ON t2.user_id=t3.user_id
GROUP BY 1;


-- 注册用户完单
WITH t1 AS
  (SELECT user_id,
          if(order_num>=4,'>=4单用户','<4单用户') user_type
   FROM
     (SELECT user_id,
             coalesce(count(1),0) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt='2025-09-25'
        AND order_status IN (2,
                             8)
      GROUP BY 1) a)

SELECT if(t1.user_id IS NULL,'<4单用户',user_type) user_type,
       count(1) cnt
FROM
  (SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d')='2025-09-25') a
LEFT JOIN t1 ON a.user_id=t1.user_id
GROUP BY 1;




-- 某日日活
--
WITH t1 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN '2025-09-18' AND '2025-09-24'
   GROUP BY 1,
            2),

-- 昨日日活 排除当日注册
dau AS
  (SELECT a.dat,
          a.user_id,
          a.cnt
   FROM
     (SELECT date_sub(current_date(),interval 2 DAY) AS dat,
             user_id,
             count(DISTINCT statistics_date) cnt
      FROM t1
      GROUP BY 1,
               2) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d')<='2025-09-24' -- date_sub(current_date(),interval 4 DAY)
      ) b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL),

-- 完单量
t3 as
  (SELECT user_id,if(order_num>=4,'>=4单用户','<4单用户') user_type
   FROM
     (SELECT user_id, coalesce(count(1),0) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt<='2025-09-24'
        AND order_status IN (2,8)
      GROUP BY 1) a)

-- DAU用户类型分布
SELECT statistics_date,
if(t3.user_id is null,'<4单用户',t3.user_type) user_type,
       CASE
           WHEN b.user_id IS NOT NULL THEN '当日注册用户'
           WHEN t2.cnt=1 THEN '低活跃用户'
           WHEN t2.cnt BETWEEN 2 AND 5 THEN '中活跃用户'
           WHEN cnt>5 THEN '高活跃用户'
           WHEN t2.cnt IS NULL THEN '沉默用户'
           ELSE '其他'
       END `用户类型`,
       count(distinct a.user_id) dau
FROM
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date = '2025-09-25'
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT user_id
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d')='2025-09-25') b ON a.user_id=b.user_id
LEFT JOIN dau t2 ON a.user_id=t2.user_id
left join t3 on a.user_id=t3.user_id
GROUP BY 1,
         2,
         3


-- 第一步超时取消订单活动的剩余名额
SELECT `下单日期`,
       count(DISTINCT a.store_promotion_id) `第一步超时取消活动量`,
       sum(`第一步超时取消订单量`) `第一步超时取消订单量`,
       count(DISTINCT if(b.remain_quota = 0, b.store_promotion_id, NULL)) `第一步超时取消活动名额为0活动量`,
       count(DISTINCT if(b.remain_quota = 0, b.store_promotion_id, NULL))/count(DISTINCT a.store_promotion_id) `第一步超时取消无名额活动占比`
FROM
  ( SELECT date_format(order_time, '%Y-%m-%d') `下单日期`,
           store_promotion_id,
           count(auto_id) `第一步超时取消订单量`
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(), interval 2 DAY) AND date_sub(current_date(), interval 0 DAY)
     AND date_format(order_time, '%Y-%m-%d') = date_sub(current_date(), interval 0 DAY)
     AND order_status = 5
   GROUP BY 1,
            2 ) a
LEFT JOIN
  ( SELECT store_promotion_id,
           ifnull(jd_promotion_remain_quota, 0) + ifnull(eleme_promotion_remain_quota, 0) + ifnull(meituan_promotion_remain_quota, 0) AS remain_quota
   FROM dwd.dwd_sr_store_promotion
   WHERE dt BETWEEN date_sub(current_date(), interval 3 DAY) AND date_sub(current_date(), interval 0 DAY)
     AND date_format(begin_date, '%Y-%m-%d') = date_sub(current_date(), interval 0 DAY) ) b ON a.store_promotion_id = b.store_promotion_id
GROUP BY 1;


-- 员工数据
WITH emp_base AS
  (SELECT a.employee_id,
          a.ding_talk_user_id,
          a.is_manager,
          b.staff_id,
          b.bd_id,
          b.user_real_name,
          b.user_nickname,
          c.ding_talk_dept_id,
          c.department_name,
          c.parent_id AS dept_parent_id,
          c.status,
          b.resign_time
   FROM
     (SELECT employee_id,
             ding_talk_user_id,
             is_manager,
             ding_talk_dept_id
      FROM
        (SELECT employee_id,
                ding_talk_user_id,
                is_manager,
                ding_talk_dept_id,
                row_number() over(partition BY ding_talk_user_id
                                  ORDER BY employee_id DESC) AS rn
         FROM dwd.dwd_sr_silkworm_dingtalk_employee) a1
      WHERE rn=1) a
   LEFT JOIN dim.dim_silkworm_staff b ON a.ding_talk_user_id = b.dingding_user_id
   LEFT JOIN dwd.dwd_sr_silkworm_dingtalk_dept c ON a.ding_talk_dept_id = c.ding_talk_dept_id
   WHERE b.staff_id IS NOT NULL
     AND date_format(b.resign_time,'%Y-%m-%d')='1970-01-01' -- 20251022修改 新增过滤离职员工逻辑 修改人：dahe
 )

-- 待支付活动量
SELECT count(store_promotion_id) pro_num
FROM dwd.dwd_sr_store_promotion
WHERE dt BETWEEN '2025-07-01' AND '2025-10-22'
  AND pay_status=2
  AND date_format(pay_time,'%Y-%m-%d %H')<'2025-10-21 13';

-- 某时间点后未支付订单
SELECT COUNT(1)
FROM dwd.dwd_sr_store_promotion
WHERE date_format(pay_time,'%Y-%m-%d %H')>='2025-10-21 13'
  AND pay_status IN (0,
                     3,
                     4);



select
  *
from dwd.dwd_sr_silkworm_explore_order
where dt between '2024-06-18' and '2025-10-23'
and user_id=556865119
and promotion_type in (1,4)
and status in (5,19,20,34,35);



DROP VIEW IF EXISTS t1;


CREATE VIEW IF NOT EXISTS t1 (statistics_date,user_id,explore_pv,welfare_pv,bargain_pv) AS
  (SELECT dt AS statistics_date,
          user_id,
          if(business_name='探店',1,0) explore_pv,
                                     0 AS welfare_pv,
                                     if(business_name='砍价',1,0) bargain_pv
   FROM
     (SELECT date_format(time,'%Y-%m-%d') AS dt,
             distinct_id AS user_id,
             business_name
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date_format(time,'%Y-%m-%d') BETWEEN '${T-2}' AND '${T-1}'
        AND distinct_id regexp '^[0-9]{1,10}$'
        AND business_name IN ('探店',
                              '砍价')
      GROUP BY 1,
               2,
               3) a
   GROUP BY 1,
            2,
            3,
            4,
            5);



-- 有效用户量>=100团长
SELECT a.inviter_user_id,
       cast(phone AS string) `手机号`,
       `1月拉新用户量`,
       `2月拉新用户量`,
       `3月拉新用户量`,
       `4月拉新用户量`,
       `5月拉新用户量`,
       `6月拉新用户量`,
       `7月拉新用户量`,
       `8月拉新用户量`,
       `9月拉新用户量`,
       `10月拉新用户量`,
       `前60-30天拉新用户量`,
       `近30天拉新用户量`,
       (`近30天拉新用户量`/`前60-30天拉新用户量`)-1 `近30天拉新环比`

FROM 
-- 969个团长
  (SELECT inviter_user_id,
          count(1) cnt
   FROM dim.dim_silkworm_user
   WHERE inviter_user_id<>0
     AND date_format(first_valid_order_time,'%Y-%m-%d')<>'1970-01-01'
   GROUP BY 1
   HAVING count(1)>=100) a
LEFT JOIN
  (SELECT inviter_user_id,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-01-01' AND '2025-01-31',user_id,NULL)) `1月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-02-01' AND '2025-02-28',user_id,NULL)) `2月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31',user_id,NULL)) `3月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-04-01' AND '2025-04-30',user_id,NULL)) `4月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-05-01' AND '2025-05-31',user_id,NULL)) `5月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-06-01' AND '2025-06-30',user_id,NULL)) `6月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-07-01' AND '2025-07-31',user_id,NULL)) `7月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-08-01' AND '2025-08-31',user_id,NULL)) `8月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-09-30',user_id,NULL)) `9月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN '2025-10-01' AND '2025-10-22',user_id,NULL)) `10月拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN date_sub('2025-10-22',interval 59 day) AND date_sub('2025-10-22',interval 30 day),user_id,NULL)) `前60-30天拉新用户量`,
          count(if(date_format(register_time,'%Y-%m-%d') BETWEEN date_sub('2025-10-22',interval 29 day) AND '2025-10-22',user_id,NULL)) `近30天拉新用户量`
   FROM dim.dim_silkworm_user
   WHERE inviter_user_id<>0
     AND date_format(register_time,'%Y-%m-%d') BETWEEN '2025-01-01' AND '2025-10-22'
   GROUP BY 1) b ON a.inviter_user_id=b.inviter_user_id
LEFT JOIN ods.ods_sr_silkworm_user c ON a.inviter_user_id=c.user_id;



SELECT b.inviter_user_id,
       a.user_id,
       c.phone
FROM
  (SELECT user_id,
          phone
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d') BETWEEN date_sub('2025-10-22',interval 29 DAY) AND '2025-10-22'
     AND date_format(first_valid_order_time,'%Y-%m-%d')<>'1970-01-01') a
INNER JOIN
  (SELECT inviter_user_id,
          user_id
   FROM ods.ods_sr_silkworm_user
   WHERE inviter_user_id IN (12388801,
                             15421501)) b
on a.user_id=b.user_id
left join ods.ods_sr_silkworm_user c ON a.user_id=c.user_id;





=============== 虚假订单用户案例
SELECT `订单ID`,
       `下单时间`,
       c.store_name `店铺名称`,
       `返利金额`,
       a.user_id `用户ID`,
       b.user_real_name `用户姓名`,
       b.phone `用户手机号`,
       b.user_id_num `用户身份证号`,
       d.province `用户定位省份`,
       d.city `用户定位城市`,
       d.county `用户定位区县`,
       d.street `用户定位街道`,
       d.address_detail `用户定位详细地址`
FROM
  (SELECT concat('单',order_id) `订单ID`,
          order_time `下单时间`,
          store_id,
          real_rebate_amt `返利金额`,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2021-01-01' AND '2025-10-23'
     AND user_id IN (991244384,
                     822132382,
                     142492412,
                     721454412,
                     589668414,
                     889554917,
                     199478910,
                     812475588,
                     133698386)) a
LEFT JOIN ods.ods_sr_silkworm_user b ON a.user_id=b.user_id
LEFT JOIN dim.dim_silkworm_store c ON a.store_id=c.store_id
LEFT JOIN dim.dim_silkworm_user_location d ON a.user_id=d.user_id;







========================== 商家合作模式

-- -- 增值服务费
-- select
--     month(pay_time) as mon,
--     bd_id,
--     sum(
--         if(cooper_type=1,(meituan_mlabel_rebate_amt+service_charge)*meituan_finished_num*0.06
--         + (eleme_mlabel_rebate_amt+service_charge)*eleme_finished_num*0.06
--         ,0
--         )
--         ) as valuadd_service_charge, -- 增值服务费6%
--     sum(if(cooper_type=2,(meituan_finished_num+eleme_finished_num)*1,0)) as user_undertake_1yuan
-- from dwd.dwd_sr_store_promotion
-- where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
--     and bd_id in (6,1316,1222,1284,1843,1885)
-- group by 1,2


--  活动
DROP VIEW IF EXISTS t1;


CREATE VIEW IF NOT EXISTS t1 (begin_date, store_promotion_id, cooper_type, pay_status, estimate_rebate_amt, fact_pay_rebate_amt, service_charge, valuadd_service_charge,promotion_quota,finished_num,origin_service_charge) AS
  (SELECT begin_date,
       store_promotion_id,
       cooper_type,
       pay_status,
       estimate_rebate_amt,
       fact_pay_rebate_amt,
       service_charge,
       valuadd_service_charge,
       promotion_quota,
       finished_num,
       origin_service_charge
   FROM
     (SELECT begin_date,
       store_promotion_id,
       store_id,
       CASE 
           WHEN cooper_type=1 THEN '品牌推广服务模式(服务费总额增加6%)' 
           WHEN cooper_type=2 THEN '品牌推广服务模式(用户承担1元)' 
           WHEN cooper_type=3 THEN '品牌推广服务模式(0成本)' -- 全包
           ELSE '其他'
       END cooper_type,
       CASE
           WHEN pay_status=0 THEN '商家已余额支付'
           WHEN pay_status=1 THEN '后台创建活动开始'
           WHEN pay_status=2 THEN '等待商家支付'
           WHEN pay_status=3 THEN '支付完成'
           WHEN pay_status=4 THEN '部分支付完成'
           ELSE '其他'
       END pay_status,
       estimate_rebate_amt,
       fact_pay_rebate_amt/100 AS fact_pay_rebate_amt,
       -- ifnull(meituan_finished_num,0)*service_charge
       --  + ifnull(eleme_finished_num,0)*service_charge
       --  + ifnull(jd_finished_num,0)*service_charge as service_charge,
      CASE
           WHEN service_charge<>0 AND meituan_status=1 THEN (ifnull(meituan_mlabel_threshold_amt,0)+ifnull(service_charge,0)-ifnull(meituan_mlabel_rebate_amt,0)-ifnull(channel_expend,0))*ifnull(meituan_finished_num,0)
           WHEN service_charge<>0 AND eleme_status=1 THEN (ifnull(eleme_mlabel_threshold_amt,0)+ifnull(service_charge,0)-ifnull(eleme_mlabel_rebate_amt,0)-ifnull(channel_expend,0))*ifnull(eleme_finished_num,0)
           WHEN service_charge<>0 AND jd_status=1 THEN (ifnull(jd_rebate_amt,0)+ifnull(service_charge,0)-ifnull(jd_mlabel_rebate_amt,0)-ifnull(channel_expend,0))*ifnull(jd_finished_num,0)
           WHEN service_charge=0 AND meituan_status=1 THEN (ifnull(meituan_mlabel_threshold_amt,0)-ifnull(meituan_mlabel_rebate_amt,0)-ifnull(channel_expend,0))*ifnull(meituan_finished_num,0)
           WHEN service_charge=0 AND eleme_status=1 THEN (ifnull(eleme_mlabel_threshold_amt,0)-ifnull(eleme_mlabel_rebate_amt,0)-ifnull(channel_expend,0))*ifnull(eleme_finished_num,0)
           WHEN service_charge=0 AND jd_status=1 THEN (ifnull(jd_rebate_amt,0)-ifnull(jd_mlabel_rebate_amt,0)-ifnull(channel_expend,0))*ifnull(jd_finished_num,0)
           ELSE 0
       END service_charge,
       IF(cooper_type=1,((ifnull(meituan_mlabel_rebate_amt,0)+service_charge))*ifnull(meituan_finished_num,0)*0.06 
        + ((ifnull(eleme_mlabel_rebate_amt,0)+service_charge))*ifnull(eleme_finished_num,0)*0.06 
        + ((ifnull(jd_mlabel_rebate_amt,0)+service_charge))*ifnull(jd_finished_num,0)*0.06,0) AS valuadd_service_charge,
        ifnull(meituan_promotion_quota,0)+ifnull(eleme_promotion_quota,0)+ifnull(jd_promotion_quota,0) promotion_quota,
        ifnull(meituan_finished_num,0)+ifnull(eleme_finished_num,0)+ ifnull(jd_finished_num,0) finished_num,
        service_charge as origin_service_charge
FROM dwd.dwd_sr_store_promotion
WHERE dt BETWEEN '2022-11-01' AND '2025-10-29'
  AND begin_date BETWEEN '2023-01-01' AND '2025-10-28'
  AND status IN (1,
                 4,
                 5)
  AND store_id<>15901
  AND cooper_type in (1,2,3)
    ) a
LEFT JOIN
(SELECT store_id,
        store_name
 FROM dim.dim_silkworm_store) b ON a.store_id=b.store_id
WHERE b.store_name NOT regexp '测试'
    and a.promotion_quota>0);

-- select * from t1 limit 10;

-- 订单
DROP VIEW IF EXISTS t2;


CREATE VIEW IF NOT EXISTS t2 (store_promotion_id,real_rebate_amt,valid_order_num,profit) AS
  (SELECT store_promotion_id,
          sum(real_rebate_amt) AS real_rebate_amt,
          count(1) valid_order_num,
          sum(if(order_status=2,profit,0)) profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2022-12-01' AND '2025-10-29'
     AND date_format(order_time,'%Y-%m-%d') BETWEEN '2023-01-01' AND '2025-10-28'
     AND order_status IN (2,
                          8)
     AND store_promotion_id>0
   GROUP BY 1);

-- 工单
DROP VIEW IF EXISTS t3;


CREATE VIEW IF NOT EXISTS t3 (promotion_id,deduction_user_candou_amt,add_candou_num) AS
  (SELECT promotion_id,
          sum(deduction_user_candou_amt/100) AS deduction_user_candou_amt,
          sum(add_candou_num/100) as add_candou_num
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2022-12-01' AND '2025-10-29'
     AND status=2
   GROUP BY 1);


SELECT date_format(begin_date,'%Y-%m') `统计月份`,
       cooper_type `商家合作模式`,
       pay_status `账单状态`,
       sum(promotion_quota) `活动名额`,
       sum(valid_order_num) `有效订单量`,
       sum(estimate_rebate_amt) `原账单金额`,
       sum(fact_pay_rebate_amt) `实际支付金额`,
       sum(service_charge) `服务费`,
       sum(valuadd_service_charge) `增值服务费`,
       sum(real_rebate_amt) `返豆金额`,
       sum(deduction_user_candou_amt) `工单退返金额`,
       sum(add_candou_num) `补偿用户蚕豆金额`,
       sum(profit) `订单利润`
FROM t1
LEFT JOIN t2 ON t1.store_promotion_id=t2.store_promotion_id
LEFT JOIN t3 ON t1.store_promotion_id=t3.promotion_id
GROUP BY 1,
         2,
         3;

-- 验证 空值导致错误
select store_promotion_id,
cooper_type,
meituan_mlabel_rebate_amt,
meituan_finished_num,
eleme_mlabel_rebate_amt,
eleme_finished_num,
jd_mlabel_rebate_amt,
jd_finished_num,
service_charge,
IF(cooper_type=1,(meituan_mlabel_rebate_amt+service_charge)*ifnull(meituan_finished_num,0)*0.06 
        + (eleme_mlabel_rebate_amt+service_charge)*ifnull(eleme_finished_num,0)*0.06 
        + (ifnull(jd_mlabel_rebate_amt,0)+service_charge)*ifnull(jd_finished_num,0)*0.06,0) AS valuadd_service_charge
 from dwd.dwd_sr_store_promotion
WHERE dt BETWEEN '2024-11-01' AND '2025-10-27'
  AND begin_date BETWEEN '2025-01-01' AND '2025-10-26'
  AND store_promotion_id=46082785;

========================== 商家合作模式



-- 获取IDFA

-- user_id 唯一
select login_platform,
    count(1) tot,
    count(distinct user_id) cnt
from dim.dim_fingerprint
group by 1;

-- 示例
select * from dim.dim_fingerprint where length(idfa)>1 limit 10;

select 
    count(1) tot,
    count(if(length(idfa)>1,user_id,null)) idfa_cnt,
    count(if(length(idfa)>1,user_id,null))/count(1) idfa_rate
from dim.dim_fingerprint
where login_platform='ios';


select 
    -- date_format(create_time,'%Y-%m-%d') `统计日期`,
    count(if(login_platform='ios',user_id,null)) `ios用户量`,
    count(if(login_platform='android',user_id,null)) `android用户量`,
    count(if(login_platform='ios' and length(idfa)>1,user_id,null))/sum(if(login_platform='ios',1,0)) `idfa采集率`,
    count(if(login_platform='android' and length(oaid)>1,user_id,null))/sum(if(login_platform='android',1,0)) `oaid采集率`
from dim.dim_fingerprint
where login_platform in ('android','ios')
    -- and date_format(create_time,'%Y-%m-%d')  between '2025-10-22' and '2025-10-28'
-- group by 1;



================== svip 用户第一步超时取消订单统计
-- svip 用户
WITH t1 AS
  (SELECT
          new_level,
          silk_id AS user_id
   FROM dwd.dwd_client_vip
   WHERE is_plus=0
   and from_unixtime(plus_activated_at,'%Y-%m-%d')<='2025-10-27'
   GROUP BY 1,
            2),

-- 第一步超时取消订单
t2 AS
  (SELECT user_id,
          count(auto_id) AS `报名订单量`,
          count(if(order_status=5 AND order_log NOT regexp '填入订单号',auto_id,NULL)) `第一步超时取消订单量`
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt='2025-10-27'
     AND store_promotion_id>0
   GROUP BY 1)


SELECT 
       new_level,
       count(DISTINCT t1.user_id) `用户量`,
       sum(`报名订单量`) `报名订单量`,
       count(DISTINCT if(t2.user_id IS NOT NULL and `第一步超时取消订单量`>0,t1.user_id,NULL)) `第一步超时取消用户量(剔除专版订单)`,
       sum(ifnull(`第一步超时取消订单量`,0)) `第一步超时取消订单量(剔除专版订单)`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
GROUP BY 1;






=================== 神策每日各业务线DAU
SELECT date_format(time,'%Y-%m-%d') AS dt,
       CASE
           WHEN (business_name<>'外卖'
                 AND event regexp 'Bargain|StoreDiscovery')
                OR (business_name='砍价'
                    AND event regexp 'Instore') THEN '砍价'
           WHEN (business_name<>'砍价'
                 AND event regexp 'StoreDiscovery')
                OR (business_name='探店'
                    AND event regexp 'Instore') THEN '探店'
           ELSE '外卖'
       END business_name,
       count(DISTINCT distinct_id) dau
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-10-18'
  AND distinct_id regexp '^[0-9]{1,10}$'
GROUP BY 1,
         2;



SELECT statistics_date,
       sum(if(business_name='外卖',dau,0)) AS `外卖UV`,
       sum(if(business_name='探店',dau,0)) AS `探店UV`,
       sum(if(business_name='砍价',dau,0)) AS `砍价UV`
FROM temp.temp_sr_traffic_business_uv_d
WHERE statistics_date BETWEEN '2025-07-17' AND '2025-10-28'
  AND business_name IN ('外卖',
                        '探店',
                        '砍价')
GROUP BY 1;



SELECT dt,
       CASE
           WHEN event_ename LIKE '%Bargain%'
                OR event_ename IN ('StoreDiscovery_Activity_Details_Atmosphere_Ex',
                                   'StoreDiscovery_Activity_Details_GrabOrder_Click') THEN '砍价'
           WHEN event_ename LIKE '%StoreDiscovery%' THEN '探店'
           ELSE '外卖'
       END business_name,
       bitmap_union_count(user_ids) dau
FROM dwd.dwd_sr_traffic_viewuser_d
WHERE dt BETWEEN '2025-01-01' AND '2025-07-16'
GROUP BY 1,
         2;



SELECT date_format(time,'%Y-%m-%d') AS dt,
       CASE
           WHEN (business_name<>'外卖'
                 AND event regexp 'Bargain|StoreDiscovery')
                OR (business_name='砍价'
                    AND event regexp 'Instore') THEN '砍价'
           WHEN (business_name<>'砍价'
                 AND event regexp 'StoreDiscovery')
                OR (business_name='探店'
                    AND event regexp 'Instore') THEN '探店'
           ELSE '外卖'
       END business_name,
       count(DISTINCT distinct_id) dau
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-10-18'
  AND distinct_id regexp '^[0-9]{1,10}$'
GROUP BY 1,
         2;


SELECT dt,
       platform_name,
       ifnull(c.city_id,0) city_id,
       ifnull(c.county_id,0) AS county_id,
       business_name,
       a.user_id
FROM
  (SELECT date_format(time,'%Y-%m-%d') AS dt,
          CASE
              WHEN platform_type regexp '到店' THEN '到店小程序'
              WHEN platform_type regexp '小程序' THEN '微信小程序'
              WHEN platform_type regexp '5' THEN 'H5'
              WHEN platform_type='iOS' then 'APP'
              WHEN platform_type='Android' then 'APP'
              WHEN platform_type='Harmony' then 'Harmony'
              ELSE '其他'
          END platform_name,
                 CASE
           WHEN (business_name<>'外卖'
                 AND event regexp 'Bargain|StoreDiscovery')
                OR (business_name='砍价'
                    AND event regexp 'Instore') THEN '砍价'
           WHEN (business_name<>'砍价'
                 AND event regexp 'StoreDiscovery')
                OR (business_name='探店'
                    AND event regexp 'Instore') THEN '探店'
           ELSE '外卖'
       END business_name,
          distinct_id AS user_id
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='${T-1}'
     AND distinct_id regexp '^[0-9]{1,10}$') a
LEFT JOIN
  (SELECT user_id,
          county_id
   FROM dim.dim_silkworm_user) b ON a.user_id=b.user_id
LEFT JOIN
  (SELECT city_id,
          county_id
   FROM dim.dim_silkworm_county) c ON b.county_id=c.county_id
GROUP BY 1,
         2,
         3,
         4,
         5,
         6
;


==================================== 驳回订单的工单
select
    dt `下单日期`,
    day_of_week `星期几`,
    holiday `节假日`,
    cnt `驳回订单量`,
    if(holiday='非节假日' and day_of_week not in ('星期六','星期天'),'是','否') `是否带入计算`
from
(select
    dt,
    count(auto_id) cnt
from dwd.dwd_sr_order_promotion_order
where dt between '2025-08-01' and '2025-10-29'
and order_status in (3,10)
and audit_reason_type=6
group by 1) a
left join dim.dim_silkworm_date b on a.dt=b.current_date_txt
;



select
    -- a.dt,
    -- a.auto_id,
    -- a.order_id,
    -- b.order_id as workorder_order_id,
    -- b.work_order_id,
    -- b.cate2_type,
    -- b.cate3_type,
    -- b.status 
    a.dt `下单日期`,
    c.day_of_week `星期几`,
    c.holiday `节假日`,
    if(c.holiday='非节假日' and c.day_of_week not in ('星期六','星期天'),'是','否') `是否带入计算`,
    count(distinct a.order_id) `驳回订单量`,
    count(distinct b.work_order_id) `工单量`
from
(select
    dt,
    auto_id,
    order_id
from dwd.dwd_sr_order_promotion_order
where dt between '2025-08-01' and '2025-10-29'
and order_status in (3,10)
and audit_reason_type=6) a
left join
(select order_id,
    work_order_id,
    cate2_type,
    cate3_type,
    status 
from dwd.dwd_sr_callcenter_workorder
where date_format(dt,'%Y-%m-%d') between '2025-08-01' and '2025-10-30') b
on a.order_id=b.order_id
left join dim.dim_silkworm_date c on a.dt=c.current_date_txt
group by 1,2,3,4;



=========================== 
-- 有效拉新top40 团长
select  a.inviter_user_id,
        a.order_num,
        b.phone
from(
            select  inviter_user_id,
                    sum(accu_valid_order_num) order_num
            from    dim.dim_silkworm_user
            group by 1
            order by 2 desc
            limit   50
        ) a
left join ods.ods_sr_silkworm_user b
on      a.inviter_user_id = b.user_id;

-- top40团长的团员
with t1 as (
select a.inviter_user_id,a.user_id,b.phone from
(select
    inviter_user_id,
    user_id
from dim.dim_silkworm_user
where date_format(register_time,'%Y-%m-%d') between '2025-10-19' and '2025-10-28' and accu_valid_order_num>0 and inviter_user_id in (12921018,
14361018,
178972015,
55175057,
76448507,
45318704,
35923703,
198846017,
45481104,
61895069,
199937107,
96639109,
51327505,
516292050,
171777408,
57556505,
87485082,
447637856,
155595702,
242443701,
25729502,
72363707,
256589603,
43778504,
97764509,
98325093,
636937501,
785179079,
52335057,
857452089,
475257718,
31367035,
563221702,
348134500,
58679057,
26941702,
48363704,
731787701,
456628502,
54746705)) a
left join ods.ods_sr_silkworm_user b
on      a.user_id = b.user_id),

-- 有效订单
t2 as (select
user_id,
count(1) valid_num
from dwd.dwd_sr_order_promotion_order
where dt between '2025-10-19' and '2025-10-28'
    and order_status in (2,8)
group by 1
having count(1)>4)

select
t1.inviter_user_id,t1.user_id,t1.phone,t2.valid_num
from t1 inner join t2 on t1.user_id=t2.user_id;



================= 经纪人数据统计
大禾我们现在需要核对下经纪人账户的余额，10月份之前合作的经纪人，截至9月30日可提现余额（经纪人ID、可提现金额），10月1日至目前新增加的经纪人佣金金额（经纪人ID、BD、消耗份额、系统利润金额、经纪人佣金、经纪人利润）这些字段

-- 可提现金额
SELECT agent_id `经济人ID`,
       sum(if(record_type=0,agent_fee,0)) `经济人收益金额`,
       sum(if(record_type=1
              AND withdraw_status=1,agent_fee,0)) `经济人提现金额`,
       sum(if(record_type=0,agent_fee,0)) - sum(if(record_type=1
                                                        AND withdraw_status=1,agent_fee,0)) `可提现金额`
FROM dwd.dwd_sr_store_silkworm_agent_income
WHERE date_format(create_time,'%Y-%m-%d')<'2025-09-30'
GROUP BY 1 ;



SELECT silk_id `经济人ID`,
       sum(if(record_type=0,agency_fee/100,0)) `经济人收益金额`,
       sum(if(record_type=1
              AND withdraw_status=1,agency_fee/100,0)) `经济人提现金额`,
       sum(if(record_type=2,agency_fee/100,0)) `经济人提现返还金额`,
       sum(if(record_type=3,agency_fee/100,0)) `经济人解冻金额`,
       sum(if(record_type=4,agency_fee/100,0)) `经济人手动扣减金额`,
       sum(if(record_type=0,agency_fee/100,0)) - sum(if(record_type=1 AND withdraw_status=1,agency_fee/100,0)) `可提现金额` -- 经济人收益 减去 经济人提现
FROM silkworm_agency.agency_earning_record
WHERE date_format(created_at,'%Y-%m-%d')<'2025-09-30'
  AND silk_id=12412018
GROUP BY 1 ;



-- 10月新增经纪人指标统计
SELECT a.silk_id `经济人ID`,
       a.bd_id,
       c.order_num `消耗份额`,
       c.profit `系统利润金额`,
       b.`经济人佣金`,
       c.profit-b.`经济人佣金` `经纪人利润`
FROM 
-- 10月新增经纪人
  (SELECT silk_id,bd_id
   FROM test.test_sr_silkworm_agency_merchant_agency
   WHERE date_format(created_at,'%Y-%m-%d') between '2025-10-01' and '2025-10-31'
   GROUP BY 1,2) a 
-- 经济人收益
LEFT JOIN (
SELECT silk_id,
       sum(agency_fee/100) `经济人佣金`
FROM test.test_sr_silkworm_agency_agency_earning_record
WHERE date_format(created_at,'%Y-%m-%d') between '2025-10-01' and '2025-10-31'
  AND record_type=0
GROUP BY 1
 ) b ON a.silk_id=b.silk_id 
-- 经纪人订单
LEFT JOIN
  ( SELECT silk_id,
           sum(order_num) order_num,
           sum(profit) profit
   FROM
     (SELECT silk_id,
             promotion_id
      FROM test.test_sr_silkworm_agency_agency_earning_record
      WHERE date_format(created_at,'%Y-%m-%d') between '2025-10-01' and '2025-10-31'
        AND promotion_id<>0
      GROUP BY 1,
               2) c1
   LEFT JOIN
     (SELECT store_promotion_id,
             count(1) order_num,
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-10-01' AND '2025-10-31'
        AND order_status IN (2,
                             8)
      GROUP BY 1) c2 ON c2.store_promotion_id=c1.promotion_id
   GROUP BY 1) c ON a.silk_id=c.silk_id ;

================ 月活用户积分兑换后访问频次统计
-- 8月mau
-- 2571174
WITH t1 AS
  (SELECT CASE
              WHEN view_days BETWEEN 1 AND 6 THEN '1-6天'
              WHEN view_days BETWEEN 7 AND 12 THEN '7-12天'
              WHEN view_days BETWEEN 13 AND 18 THEN '13-18天'
              WHEN view_days BETWEEN 19 AND 24 THEN '19-24天'
              WHEN view_days BETWEEN 25 AND 30 THEN '25-30天'
              ELSE '其他'
          END user_type,
              a.user_id,
              view_days
   FROM
     (SELECT user_id,
             count(event_date) AS view_days
      FROM dwd.dwd_sr_traffic_user_view
      WHERE event_date BETWEEN '2025-08-01' AND '2025-08-30'
      GROUP BY 1) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-08-01' AND '2025-08-31') b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL),

-- 9月MAU
t2 AS
  (SELECT user_id,count(event_date) AS view_days
   FROM dwd.dwd_sr_traffic_user_view
   WHERE event_date BETWEEN '2025-09-01' AND '2025-09-30'
   GROUP BY 1),

-- 8月积分兑换
t3 AS
  (SELECT user_id
   FROM dwd.dwd_sr_market_task_point
   WHERE dt BETWEEN '2025-08-01' AND '2025-08-30'
     AND current_operate_get_point<0
   GROUP BY 1),


-- 9月积分兑换
t4 AS
  (SELECT user_id
   FROM dwd.dwd_sr_market_task_point
   WHERE dt BETWEEN '2025-09-01' AND '2025-09-30'
     AND current_operate_get_point<0
   GROUP BY 1)


SELECT `活跃类型`,
       count(user_id) `8月MAU`,
       avg(`活跃天数差异`) `活跃天数差异`
FROM
  (SELECT `活跃类型`,
          user_id,
          `9月活跃天数`-`8月活跃天数` as `活跃天数差异`
from
(select
  t1.user_type `活跃类型`,
  t1.user_id,
  t1.view_days `8月活跃天数`,
  if(t3.user_id is not null and t4.user_id is not null,t2.view_days,0) `9月活跃天数`
from t1
left join t3 on t1.user_id=t3.user_id
left join t2 on t1.user_id=t2.user_id
left join t4 on t1.user_id=t4.user_id
) a
where `9月活跃天数`<>0) b
GROUP BY 1;


select
  user_type,
  count(t1.user_id) mau,
  count(if(t3.user_id is not null,t1.user_id,null)) take_unum
from t1 left join t3 on t1.user_id=t3.user_id
group by 1;



-- 当前有可兑换积分用户量
SELECT count(1) `总用户量`,
       count(if(current_operate_get_point > 0, user_id, NULL)) `有可兑换积分用户量`
FROM
  ( SELECT user_id,
           sum(current_operate_get_point) current_operate_get_point
   FROM dwd.dwd_sr_market_task_point
   GROUP BY 1 ) a;


-- 有可兑换积分用户中的月活
WITH t1 AS
  (SELECT CASE
              WHEN view_days BETWEEN 1 AND 6 THEN '1-6天'
              WHEN view_days BETWEEN 7 AND 12 THEN '7-12天'
              WHEN view_days BETWEEN 13 AND 18 THEN '13-18天'
              WHEN view_days BETWEEN 19 AND 24 THEN '19-24天'
              WHEN view_days BETWEEN 25 AND 30 THEN '25-30天'
              ELSE '其他'
          END user_type,
              a.user_id,
              view_days
   FROM
     (SELECT user_id,
             count(event_date) AS view_days
      FROM dwd.dwd_sr_traffic_user_view
      WHERE event_date BETWEEN '2025-10-01' AND '2025-10-30'
      GROUP BY 1) a
   LEFT JOIN
     (SELECT user_id
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-10-01' AND '2025-10-30') b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL),


t2 AS
  ( SELECT user_id,
           sum(current_operate_get_point) current_operate_get_point
   FROM dwd.dwd_sr_market_task_point
   GROUP BY 1 HAVING sum(current_operate_get_point)>0)


SELECT user_type,
       count(t1.user_id) tot,
       count(if(t2.user_id IS NOT NULL,t1.user_id,NULL)) cnt
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
GROUP BY 1;




=============== dau 拆解
-- 临期红包红包
-- mau 9月30日至10月29日
WITH t1 AS
  (SELECT CASE
              WHEN view_days BETWEEN 1 AND 6 THEN '1-6天'
              WHEN view_days BETWEEN 7 AND 12 THEN '7-12天'
              WHEN view_days BETWEEN 13 AND 18 THEN '13-18天'
              WHEN view_days BETWEEN 19 AND 24 THEN '19-24天'
              WHEN view_days BETWEEN 25 AND 30 THEN '25-30天'
              ELSE '其他'
          END user_type,
              user_id,
              view_days
   FROM
     (SELECT user_id,
             count(event_date) AS view_days
      FROM dwd.dwd_sr_traffic_user_view
      WHERE event_date BETWEEN '2025-09-30' AND '2025-10-29'
      GROUP BY 1) a),

-- 红包有效期是1030
t2 AS
  (SELECT user_id
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt BETWEEN '2025-01-01' AND '2025-10-30'
     AND date_format(end_time,'%Y-%m-%d')='2025-10-30'
   GROUP BY 1),

-- 1030访问用户
t3 AS
  (SELECT user_id
   FROM dwd.dwd_sr_traffic_user_view
   WHERE event_date ='2025-10-30'
   GROUP BY 1)

SELECT user_type,
       count(t1.user_id) `MAU`,
       count(if(t2.user_id IS NOT NULL,t1.user_id,NULL)) `红包临期用户量`,
       count(if(t2.user_id IS NOT NULL
                AND t3.user_id IS NOT NULL,t1.user_id,NULL)) `红包临期活跃用户量`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
LEFT JOIN t3 ON t1.user_id=t3.user_id
GROUP BY 1;


-- 临期卡券
-- mau 9月30日至10月29日
WITH t1 AS
  (SELECT CASE
              WHEN view_days BETWEEN 1 AND 6 THEN '1-6天'
              WHEN view_days BETWEEN 7 AND 12 THEN '7-12天'
              WHEN view_days BETWEEN 13 AND 18 THEN '13-18天'
              WHEN view_days BETWEEN 19 AND 24 THEN '19-24天'
              WHEN view_days BETWEEN 25 AND 30 THEN '25-30天'
              ELSE '其他'
          END user_type,
              user_id,
              view_days
   FROM
     (SELECT user_id,
             count(event_date) AS view_days
      FROM dwd.dwd_sr_traffic_user_view
      WHERE event_date BETWEEN '2025-09-30' AND '2025-10-29'
      GROUP BY 1) a),

-- 卡券有效期是1030
t2 AS
  (SELECT user_id
   FROM dwd.dwd_sr_market_rights_card
WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-01-01' AND '2025-10-30'
  
     AND date_format(expire_time,'%Y-%m-%d')='2025-10-30'
     AND card_type in (7,14,1,3,13)
   GROUP BY 1),

-- 1030访问用户
t3 AS
  (SELECT user_id
   FROM dwd.dwd_sr_traffic_user_view
   WHERE event_date ='2025-10-30'
   GROUP BY 1)

SELECT user_type,
       count(t1.user_id) `MAU`,
       count(if(t2.user_id IS NOT NULL,t1.user_id,NULL)) `卡券临期用户量`,
       count(if(t2.user_id IS NOT NULL
                AND t3.user_id IS NOT NULL,t1.user_id,NULL)) `卡券临期活跃用户量`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
LEFT JOIN t3 ON t1.user_id=t3.user_id
GROUP BY 1;


-- 可提现蚕豆
-- mau 9月30日至10月29日
WITH t1 AS
  (SELECT CASE
              WHEN view_days BETWEEN 1 AND 6 THEN '1-6天'
              WHEN view_days BETWEEN 7 AND 12 THEN '7-12天'
              WHEN view_days BETWEEN 13 AND 18 THEN '13-18天'
              WHEN view_days BETWEEN 19 AND 24 THEN '19-24天'
              WHEN view_days BETWEEN 25 AND 30 THEN '25-30天'
              ELSE '其他'
          END user_type,
              user_id,
              view_days
   FROM
     (SELECT user_id,
             count(event_date) AS view_days
      FROM dwd.dwd_sr_traffic_user_view
      WHERE event_date BETWEEN '2025-09-30' AND '2025-10-29'
      GROUP BY 1) a),

-- 可提现蚕豆
t2 AS
  (SELECT user_id
   FROM
     (SELECT user_id,
             (user_extra_point/100)+await_withdrawal_candou_num AS `现有蚕豆数`
      FROM dim.dim_silkworm_user) a
   WHERE `现有蚕豆数`>=1),


-- 1030访问用户
t3 AS
  (SELECT user_id
   FROM dwd.dwd_sr_traffic_user_view
   WHERE event_date ='2025-10-30'
   GROUP BY 1)


SELECT user_type,
       count(t1.user_id) `MAU`,
       count(if(t2.user_id IS NOT NULL,t1.user_id,NULL)) `可提现蚕豆>=1用户量`,
       count(if(t2.user_id IS NOT NULL
                AND t3.user_id IS NOT NULL,t1.user_id,NULL)) `可提现蚕豆>=1活跃用户量`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
LEFT JOIN t3 ON t1.user_id=t3.user_id
GROUP BY 1;



-- 会员月活
WITH t1 AS
  (SELECT CASE
              WHEN view_days BETWEEN 1 AND 6 THEN '1-6天'
              WHEN view_days BETWEEN 7 AND 12 THEN '7-12天'
              WHEN view_days BETWEEN 13 AND 18 THEN '13-18天'
              WHEN view_days BETWEEN 19 AND 24 THEN '19-24天'
              WHEN view_days BETWEEN 25 AND 30 THEN '25-30天'
              ELSE '其他'
          END user_type,
              user_lvl,
              alarm_lvl,
              a.user_id,
              view_days
   FROM
     (SELECT user_id,
             count(event_date) AS view_days
      FROM dwd.dwd_sr_traffic_user_view
      WHERE event_date BETWEEN '2025-09-30' AND '2025-10-29'
      GROUP BY 1) a
   LEFT JOIN
     (SELECT new_level user_lvl,
                      CASE WHEN score/100 BETWEEN 85 AND 95 THEN 2 
                        WHEN score/100 BETWEEN 185 AND 195 THEN 3 
                        WHEN score/100 BETWEEN 485 AND 495 THEN 4 
                        WHEN score/100 BETWEEN 985 AND 995 THEN 5 
                        WHEN score/100 BETWEEN 1485 AND 1495 THEN 6 
                        WHEN score/100 >1495 THEN 7 
                      ELSE 0 END alarm_lvl,
silk_id AS user_id
      FROM dwd.dwd_client_vip
WHERE is_plus=0
      GROUP BY 1,
               2,
               3) b ON a.user_id=b.user_id),


-- 1030访问用户
t3 AS
  (SELECT user_id
   FROM dwd.dwd_sr_traffic_user_view
   WHERE event_date ='2025-10-30'
   GROUP BY 1)


SELECT user_lvl,
       user_type,
       count(t1.user_id) `MAU`,
       count(if(t1.alarm_lvl=2,t1.user_id,NULL)) `V1提醒升级MAU`,
       count(if(t1.alarm_lvl=3,t1.user_id,NULL)) `V2提醒升级MAU`,
       count(if(t1.alarm_lvl=4,t1.user_id,NULL)) `V3提醒升级MAU`,
       count(if(t1.alarm_lvl=5,t1.user_id,NULL)) `V4提醒升级MAU`,
       count(if(t1.alarm_lvl=6,t1.user_id,NULL)) `V5提醒升级MAU`,
       count(if(t1.alarm_lvl=7,t1.user_id,NULL)) `V6提醒升级MAU`,
       count(if(t1.alarm_lvl=2 and t3.user_id is not null,t1.user_id,NULL)) `V1提醒升级活跃用户量`,
       count(if(t1.alarm_lvl=3 and t3.user_id is not null,t1.user_id,NULL)) `V2提醒升级活跃用户量`,
       count(if(t1.alarm_lvl=4 and t3.user_id is not null,t1.user_id,NULL)) `V3提醒升级活跃用户量`,
       count(if(t1.alarm_lvl=5 and t3.user_id is not null,t1.user_id,NULL)) `V4提醒升级活跃用户量`,
       count(if(t1.alarm_lvl=6 and t3.user_id is not null,t1.user_id,NULL)) `V5提醒升级活跃用户量`,
       count(if(t1.alarm_lvl=7 and t3.user_id is not null,t1.user_id,NULL)) `V6提醒升级活跃用户量`
FROM t1
LEFT JOIN t3 ON t1.user_id=t3.user_id
GROUP BY 1,
         2;



-- array 数组计数
SELECT date_format(dt,'%Y-%m') ym,
       cardinality(array_unique_agg(com_user_list)) uids
FROM dws.dws_sr_silkworm_challenge_td
WHERE dt BETWEEN '2025-01-01' AND '2025-10-30'
  AND challenge_type=1
GROUP BY 1;




=============== 每日访问用户登录和匿名统计
WITH t1 AS
  (SELECT date_format(time,'%Y-%m-%d') dat,
                                       distinct_id,
                                       user_id,
                                       $ip,
                                       if(distinct_id regexp '^[0-9]{1,10}$',1,0) is_login
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-10-25' AND '2025-10-31'
   GROUP BY 1,
            2,
            3,
            4,
            5),

-- 匿名量
 t2 AS
  (SELECT dat,
          user_id,
          sum(is_login) login_num
   FROM t1
   GROUP BY 1,
            2)

SELECT a.dat,
       a.`登录用户量`,
       b.`匿名用户量`
FROM
  (SELECT dat,
          count(DISTINCT if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,NULL)) `登录用户量`
   FROM t1
   GROUP BY 1) a
LEFT JOIN
  (SELECT dat,
          count(DISTINCT if(login_num=0,user_id,NULL)) `匿名用户量`
   FROM t2
   GROUP BY 1) b ON a.dat=b.dat ;


-- 匿名登录user_id
-- select * from t2 where login_num=0 limit 100;

-- 匿名登录user_id明细
-- select * from t1 where user_id in ('-8839329809134959886','2790807382388092716');

-- 匿名user_id总量
-- select dat,count(1) tot,count(distinct user_id) from t2 where login_num=0 group by 1;


-- 匿名用户user_id下IP分布
SELECT t1.dat,
       t1.$ip,
          count(DISTINCT t1.user_id) uid_num
FROM t1
LEFT JOIN
  (SELECT dat,
          user_id
   FROM t2
   WHERE login_num=0) a ON a.dat=t1.dat
AND a.user_id=t1.user_id
WHERE a.user_id IS NOT NULL
GROUP BY 1,
         2;


-- top ip是客服外包，访问端是营销H5
SELECT date_format(time,'%Y-%m-%d') dat,
                                       platform_type,
                                       $ip,
                                       $city,
                                       count(if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,null)) login_unum,
                                       count(distinct user_id) uid_num
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-10-26' AND '2025-10-26'
        AND $ip in ('39.164.132.6','61.191.146.222','39.165.187.219','220.184.23.29','115.204.36.161')
   GROUP BY 1,
            2,
            3,
            4;



-- 单user_id多did
SELECT dat,
       user_id,
       count(1) cnt
FROM t1
GROUP BY 1,
         2 HAVING count(1)>=2 LIMIT 20


-- select * from t1 where dat='2025-10-25' and user_id='7371290155550831710';



-- 登录用户中<5单用户量
SELECT dat,
       count(if(b.user_id IS NOT NULL,distinct_id,NULL)) `<5单用户量`
FROM
  (SELECT date_format(time,'%Y-%m-%d') dat,
          distinct_id
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d') BETWEEN '2025-10-25' AND '2025-10-31'
     AND distinct_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2) a
INNER JOIN dim.dim_silkworm_user b ON a.distinct_id=b.user_id
AND b.accu_valid_order_num<5
GROUP BY 1;









=================== 限制自营外卖下单用户
SELECT a.user_id `用户ID`,
       register_time `注册时间`,
       a.new_user_level `会员等级`,
       if(a.is_plus = 0, '否', '是') `是否plus`,
       unsatisfied_order_num `不满意订单量`,
       valid_team_user_num `有效团员数`,
       accu_valid_order_num `累计有效订单量`,
       latest_valid_order_time `最近一次有效订单时间`,
       latest_login_time `最近一次登录时间`,
       latest_login_app_version `最近一次登录APP版本`,
       latest_block_time `最近一次拉黑时间`,
       if(is_logoff=0, '否', '是') `是否注销`
FROM
  ( SELECT user_id,
           new_user_level,
           is_plus
   FROM dim.dim_silkworm_member
   WHERE diroper_blacked_status = 1 ) a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id = b.user_id;


-- 限制自营外卖下单用户 最新异常记录
SELECT a.user_id `用户ID`,
       register_time `注册时间`,
       a.new_user_level `会员等级`,
       if(a.is_plus = 0, '否', '是') `是否plus`,
       unsatisfied_order_num `不满意订单量`,
       valid_team_user_num `有效团员数`,
       accu_valid_order_num `累计有效订单量`,
       latest_valid_order_time `最近一次有效订单时间`,
       latest_login_time `最近一次登录时间`,
       latest_login_app_version `最近一次登录APP版本`,
       latest_block_time `最近一次拉黑时间`,
       if(is_logoff=0, '否', '是') `是否注销`,
       `异常类型`
FROM
  (SELECT user_id,
          new_user_level,
          is_plus
   FROM dim.dim_silkworm_member
   WHERE diroper_blacked_status = 1) a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id = b.user_id
LEFT JOIN
  (SELECT user_id,
          CASE
              WHEN monitor_type= 0 THEN '用户每日订单数满额'
              WHEN monitor_type= 1 THEN '用户被拉黑'
              WHEN monitor_type= 2 THEN '用户被封功能'
              WHEN monitor_type= 3 THEN '用户打开白名单功能'
              WHEN monitor_type= 4 THEN '用户拉黑解除'
              WHEN monitor_type= 5 THEN '用户解除注销'
              WHEN monitor_type= 6 THEN '用户每日增加蚕豆超过阈值'
              WHEN monitor_type= 7 THEN '用户解除签约'
              WHEN monitor_type= 8 THEN '拉黑实名'
              WHEN monitor_type= 9 THEN '解除拉黑实名'
              ELSE '其他'
          END `异常类型`
   FROM
     (SELECT user_id,
             create_time,
             monitor_type,
             row_number() over(partition BY user_id
                               ORDER BY create_time DESC) rk
      FROM dim.dim_silkworm_exception_user) c1
   WHERE rk=1) c ON a.user_id=c.user_id ;


-- 虚假订单量
WITH t1 AS
  (SELECT user_id,
          count(DISTINCT order_id) `虚假订单量`
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2025-07-01' AND '2025-11-04'
     AND cate3_type in (7,65)
     AND status=2
   GROUP BY 1)

-- 11636人
-- 限制自营外卖下单用户 最新外卖直营拉黑记录
SELECT a.user_id `用户ID`,
       register_time `注册时间`,
       a.new_user_level `会员等级`,
       if(a.is_plus = 0, '否', '是') `是否plus`,
       unsatisfied_order_num `不满意订单量`,
       valid_team_user_num `有效团员数`,
       accu_valid_order_num `累计有效订单量`,
       latest_valid_order_time `最近一次有效订单时间`,
       latest_login_time `最近一次登录时间`,
       latest_login_app_version `最近一次登录APP版本`,
       latest_block_time `最近一次拉黑时间`,
       if(is_logoff=0, '否', '是') `是否注销`,
       cast(c.create_time as varchar(30)) `最近一次直营拉黑时间`,
       c.remark `最近一次直营拉黑原因`,
       t1.`虚假订单量`
FROM
  (SELECT user_id,
          new_user_level,
          is_plus
   FROM dim.dim_silkworm_member
   WHERE diroper_blacked_status = 1) a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id = b.user_id
LEFT JOIN
  (SELECT user_id,create_time,remark
   FROM
     (SELECT user_id,
             create_time,
             remark,
             row_number() over(partition BY user_id
                               ORDER BY create_time DESC) rk
      FROM dwd.dwd_sr_user_block_record
      where block_type=1 and status=1) c1
   WHERE rk=1) c ON a.user_id=c.user_id
LEFT JOIN t1 on a.user_id=t1.user_id ;

====================








date_format(,'%Y-%m-%d %H:%i:%s')




====================== 
-- 用户最早提现日期
WITH t1 AS
  (SELECT dt,
          user_id,
          create_time,
          status
   FROM
     (SELECT dt,
             user_id,
             create_time,
             status,
             row_number() over(partition BY user_id
                               ORDER BY create_time DESC) rk
      FROM dwd.dwd_sr_user_withdraw_record) a
   WHERE rk=1),

-- 用户访问
t2 AS
  (SELECT event_date,
          user_id
   FROM dwd.dwd_sr_traffic_user_view
   where event_date BETWEEN '2025-10-14' and '2025-11-05')

SELECT a.dt,
       count(DISTINCT a.user_id) `首次提现成功用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL
                         AND date_diff('day',b.event_date,a.dt)=1,a.user_id,NULL)) `首次提现成功次日访问留存用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL
                         AND date_diff('day',b.event_date,a.dt)=3,a.user_id,NULL)) `首次提现成功次3日访问留存用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL
                         AND date_diff('day',b.event_date,a.dt)=5,a.user_id,NULL)) `首次提现成功次5日访问留存用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL
                         AND date_diff('day',b.event_date,a.dt)=7,a.user_id,NULL)) `首次提现成功次7日访问留存用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL
                         AND date_diff('day',b.event_date,a.dt)=14,a.user_id,NULL)) `首次提现成功次14日访问留存用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL
                         AND date_diff('day',b.event_date,a.dt)=30,a.user_id,NULL)) `首次提现成功次30日访问留存用户量`
FROM
  (SELECT user_id,
          dt
   FROM t1
   WHERE dt BETWEEN '2025-10-13' AND '2025-11-04'
     AND status=1) a
LEFT JOIN t2 b ON a.user_id=b.user_id
AND a.dt<>b.event_date
GROUP BY 1;





-- 用户添加企微
t3 as (
select

from 
)



select  date_format(register_time, '%Y-%m-%d') `注册日期`,
        count(1) `注册用户量`,
        count(if(bind_interior_staff_wework_id <> '0', user_id, null)) `添加企微用户量`,
        count(if(bind_interior_staff_wework_account <> '0', user_id, null)) `激活用户量`
from    dim.dim_silkworm_user
where   date_format(register_time, '%Y-%m-%d') between '${begin_date}' and '${end_date}'
group by 1




===================
-- 某日访问用户
SELECT DISTINCT distinct_id as user_id
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-10-31'
  AND distinct_id regexp '^[0-9]{1,10}$'



-- 18至25岁用户
WITH t1 AS
  (SELECT user_id
   FROM dwd.dwd_silkworm_user_feature_data
   WHERE age BETWEEN 18 AND 25
   GROUP BY 1),

-- 近30天美团完单量含联盟、专版订单）
t2 AS
  (SELECT user_id,
          count(1) valid_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND store_platform_type=1
     AND order_status IN (2,
                          8)
   GROUP BY 1 HAVING count(1)>10),

-- 累计美团完单量（含联盟、专版订单）
t3 AS
  (SELECT user_id,
          count(1) valid_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2021-01-01' AND date_sub(current_date(),interval 1 DAY)
     AND store_platform_type=1
     AND order_status IN (2,
                          8)
   GROUP BY 1 HAVING count(1)>30),


SELECT count(distin t1.user_id) num
FROM t1
INNER JOIN t2 ON t1.user_id=t2.user_id
INNER JOIN t3 ON t1.user_id=t3.user_id
;





========= 近14天每日第一步超时取消用户量、外呼召回用户量+完单量
-- 背景：报名活动后未提交订单号超时取消，活动仍有名额时，做同活动当日AI电话召回，告知用户，已超时取消活动仍有名额，如有需求，请在小蚕下单
-- 外呼记录
WITH t1 AS
  (SELECT date_format(create_time,'%Y-%m-%d') call_date,
                                              order_id,
                                              user_id,
                                              call_status
   FROM dwd.dwd_sr_order_ai_call_log
   WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-11-11' AND '2026-01-05'
     AND bwc_type=0
     AND source_type=3),


-- 订单
t2 AS
  (SELECT user_id,
          store_promotion_id,
          right(order_id,9) AS order_id,
          order_time,
          create_time,
          order_status,
          order_log
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-11-11' AND '2026-01-06'),


-- 超时取消订单AI外呼记录
t3 AS
  (SELECT call_date,
          t1.order_id,
          t1.user_id,
          call_status,
          store_promotion_id,
          order_time,
          create_time,
          order_status,
          order_log
   FROM t1
   LEFT JOIN t2 ON t1.order_id=t2.order_id),


-- 第一步超时召回用户完单
t4 AS
  (SELECT a.user_id,
          a.order_id,
          date_format(a.order_time,'%Y-%m-%d') order_date
   FROM
     (SELECT *
      FROM t2
      WHERE order_status IN (2,
                             8)) a
   LEFT JOIN
     (SELECT user_id,
             store_promotion_id,
             order_time,
             order_id
      FROM t3
      WHERE order_log NOT regexp '填入订单号'
      GROUP BY 1,
               2,
               3,
               4) b ON a.user_id=b.user_id
   AND a.store_promotion_id=b.store_promotion_id
   AND date_format(a.order_time,'%Y-%m-%d')=date_format(b.order_time,'%Y-%m-%d')
   AND date_format(a.order_time,'%Y-%m-%d')>=date_format(b.order_time,'%Y-%m-%d')
   AND a.order_id<>b.order_id
   WHERE b.user_id IS NOT NULL
   GROUP BY 1,
            2,
            3)

SELECT call_date,
       count(if(order_log NOT regexp '填入订单号',order_id,NULL)) `第一步超时取消外呼量`,
       count(DISTINCT if(order_log NOT regexp '填入订单号',user_id,NULL)) `第一步超时取消外呼用户量`,
       count(if(order_log NOT regexp '填入订单号'
                AND call_status=1,order_id,NULL)) `第一步超时取消外呼接通量`,
       count(DISTINCT if(order_log NOT regexp '填入订单号'
                         AND call_status=1,user_id,NULL)) `第一步超时取消外呼接通用户量`
FROM t3
GROUP BY 1;



SELECT order_date,
       count(DISTINCT user_id) `第一步超时取消外呼召回完单用户量`,
       count(DISTINCT order_id) `第一步超时取消外呼召回完单量`
FROM t4
GROUP BY 1;



-- 统计第一步超时取消后，用户主动回访并完单订单量、用户量
-- 第一步超时取消订单用户和活动
with t1 as (
SELECT user_id,
          store_promotion_id,
          order_id,
          order_time,
          order_log,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-11-01' AND '2026-01-05'
     AND order_status in (2,5,8)
     AND store_promotion_id>0),

-- 超时取消外呼成功
t2 AS
  (SELECT a.call_date,
          a.order_id,
          a.user_id,
          b.store_promotion_id
   FROM
     (SELECT date_format(create_time,'%Y-%m-%d') call_date,
                                                 order_id,
                                                 user_id
      FROM dwd.dwd_sr_order_ai_call_log
      WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-11-11' AND '2025-12-31'
        AND bwc_type=0
        AND source_type IN (0,
                            3)
        AND call_status=1) a
   LEFT JOIN
     (SELECT right(order_id,9) order_id,
                               store_promotion_id
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-11-01' AND '2025-12-31'
        AND store_promotion_id>0) b ON a.order_id=b.order_id
   GROUP BY 1,
            2,
            3,
            4),


-- 同活动，超时取消后完单
t3 AS
  (SELECT a.dat,
          a.user_id,
          a.store_promotion_id,
          a.cancel_order_time,
          b.order_time
   FROM
     (SELECT date_format(order_time,'%Y-%m-%d') dat,
                                                user_id,
                                                store_promotion_id,
                                                min(order_time) cancel_order_time
      FROM t1
      WHERE order_status= 5
        AND order_log NOT regexp '填入订单号'
      GROUP BY 1,
               2,
               3) a
   INNER JOIN
     (SELECT date_format(order_time,'%Y-%m-%d') dat,
                                                user_id,
                                                store_promotion_id,
                                                max(order_time) order_time
      FROM t1
      WHERE order_status IN (2,
                             8)
      GROUP BY 1,
               2,
               3) b ON a.dat=b.dat
   AND a.user_id=b.user_id
   AND a.store_promotion_id=b.store_promotion_id
   AND a.cancel_order_time<b.order_time
   GROUP BY 1,
            2,
            3,
            4,
            5)

-- 排除已外呼成功用户和活动后，统计同活动同用户自主回来完单用户量
SELECT t3.dat,
       count(DISTINCT t3.user_id) num
FROM t3
LEFT JOIN
  (SELECT call_date,
          user_id,
          store_promotion_id
   FROM t2
   GROUP BY 1,
            2,
            3) b ON t3.dat=b.call_date
AND t3.user_id=b.user_id
AND t3.store_promotion_id=b.store_promotion_id
WHERE b.user_id IS NULL
GROUP BY 1;



-- 第一步超时取消用户量
SELECT date_format(order_time,'%Y-%m-%d') dat,
       count(DISTINCT user_id) unum
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-10-27' AND '2025-11-14'
  AND order_status=5
  AND order_log NOT regexp '填入订单号'
  AND store_promotion_id>0
GROUP BY 1;

-- 超时取消外呼用户量
SELECT date_format(create_time,'%Y-%m-%d') call_date,
       count(DISTINCT if(call_status<>1,user_id,NULL)) `外呼用户量`,
       count(DISTINCT if(call_status=1,user_id,NULL)) `外呼成功用户量`
FROM dwd.dwd_sr_order_ai_call_log
WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-10-27' AND '2025-11-13'
  AND bwc_type=0
  AND source_type IN (0,
                      3)
GROUP BY 1;

-- 外呼用户量
SELECT date_format(create_time,'%Y-%m-%d') call_date,
       count(DISTINCT user_id) `外呼用户量`,
       count(DISTINCT if(call_status=1,user_id,NULL)) `外呼成功用户量`
FROM dwd.dwd_sr_order_ai_call_log
WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2025-10-27' AND '2025-11-13'
  AND bwc_type=0
  AND source_type=3
GROUP BY 1;



-- 抽取AI外呼召回用户完单数据
-- select * from t4 limit 10;

-- 验证用户下单情况
select * from t2 where store_promotion_id=81108363;

======================= 




-- 取店铺品类

SELECT store_id `店铺ID`,
       store_name `店铺名称`,
       city_name `城市`,
       district_name `区县`,
       CASE
           WHEN sub_category_type = 1 THEN '包子粥铺'
           WHEN sub_category_type = 2 THEN '快餐简餐'
           WHEN sub_category_type = 3 THEN '甜品饮品'
           WHEN sub_category_type = 4 THEN '炸串小吃'
           WHEN sub_category_type = 5 THEN '火锅烧烤'
           WHEN sub_category_type = 6 THEN '汉堡西餐'
           WHEN sub_category_type = 7 THEN '零售'
           WHEN sub_category_type = 8 THEN '水果鲜花'
           WHEN sub_category_type = 9 THEN '成人用品'
       END AS `旧二级品类`,
       xc_category,
       get_json_object(parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category1') AS `新一级品类`,
       get_json_object(parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category2') AS `新二级品类`
FROM dim.dim_silkworm_store LIMIT 10;






======================
-- 自营日活动
with t1 (
select
    substr(begin_date,1,10) as dat,
    c.city_name,
    c.county_name,
    CASE 
        WHEN b.sub_category_type = 1 THEN '包子粥铺'
        WHEN b.sub_category_type = 2 THEN '快餐简餐'
        WHEN b.sub_category_type = 3 THEN '甜品饮品'
        WHEN b.sub_category_type = 4 THEN '炸串小吃'
        WHEN b.sub_category_type = 5 THEN '火锅烧烤'
        WHEN b.sub_category_type = 6 THEN '汉堡西餐'
        WHEN b.sub_category_type = 7 THEN '零售'
        WHEN b.sub_category_type = 8 THEN '水果鲜花'
        WHEN b.sub_category_type = 9 THEN '成人用品'
    END AS store_sub_category_type,
    CASE 
        WHEN a.promotion_rebate_type = 0 AND a.meituan_rebate_amt > 0 THEN concat('满', cast(a.meituan_order_amt as string), '返', cast(a.meituan_user_rebate_point/100 as string))
        WHEN a.promotion_rebate_type = 1 AND a.meituan_rebate_amt > 0 THEN concat('最高返', cast(a.meituan_user_rebate_point/100 as string))
        WHEN a.promotion_rebate_type = 0 AND a.eleme_rebate_amt > 0 THEN concat('满', cast(a.eleme_order_amt as string), '返', cast(a.eleme_user_rebate_point/100 as string))
        WHEN a.promotion_rebate_type = 1 AND a.eleme_rebate_amt > 0 THEN concat('最高返', cast(a.eleme_user_rebate_point/100 as string))
    END AS meal_label,
    store_promotion_id,
    a.meituan_promotion_quota+a.eleme_promotion_quota as promotion_quota
from dwd.dwd_hive_store_promotion a
left join dim.dim_silkworm_store b
    on a.store_id=b.store_id
left join dim.dim_hive_region_code c
    on a.county_id=c.county_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-01-01' and '2024-06-30'
        and to_date(a.begin_date) between '2024-06-01' and '2024-06-30'
        and a.status in (1, 4, 5)
        and a.is_vip_exclusive=0 -- vip专享
        and a.is_operation_promption=0 -- 运营创建活动
),

-- 分时段自营有效单
t2 as (
select
    section_time,
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    avg(acc_vaild_order_num) as avg_acc_vaild_order_num
from 
(
-- 日有效单
select
    dat,
    section_time,
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    sum(vaild_order_num) over(partition by dat,city_name,county_name,store_sub_category_type,meal_label order by section_time) as acc_vaild_order_num
from (select
            a.dat,
            a.section_time,
            b.city_name,
            b.county_name,
            t1.store_sub_category_type,
            t1.meal_label,
            sum(a.vaild_order_num) as vaild_order_num
from (select 
            concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) as dat,
            substr(order_time,12,2) as section_time,
            store_promotion_id,
            county_id,
            count(order_id) as vaild_order_num
    from dwd.dwd_hive_silkworm_promotion_order
    where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-30'
        and order_status in (2,8)
        and store_promotion_id>0
    group by 1,2,3,4
    ) a
    inner join t1 
        on a.store_promotion_id=t1.store_promotion_id
    left join dim.dim_hive_region_code b
        on a.county_id=b.county_id
    group by 1,2,3,4,5,6
    ) c
) toa
group by 1,2,3,4,5
),


-- 分日自营活动名额
t3 as (
select
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    avg(day_quota) as avg_day_quota
from (select
            dat,
            city_name,
            county_name,
            store_sub_category_type,
            meal_label,
            sum(promotion_quota) as day_quota
        from t1
    group by 1,2,3,4,5
    ) a
group by 1,2,3,4
)



select
    t2.city_name,
    t2.county_name,
    t2.store_sub_category_type,
    t2.meal_label,
    t2.section_time,
    t2.avg_acc_vaild_order_num,
    t3.avg_day_quota
from t2
left join t3
    on t2.city_name=t3.city_name
        and t2.county_name=t3.county_name
        and t2.store_sub_category_type=t3.store_sub_category_type
        and t2.meal_label=t3.meal_label


=======================


-- 资源位本位置曝光、点击
SELECT a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.tot,
       a.unum,
       a.bg_num,
       a.bg_unum,
       a.clc_num,
       a.clc_unum
FROM
  (SELECT resource_id,
          put_id,
          abtest_id,
          count(1) tot,
          count(DISTINCT user_id) unum,
          sum(if(event regexp '_Ex$',1,0)) bg_num,
          count(DISTINCT if(event regexp '_Ex$',user_id,NULL)) bg_unum,
          sum(if(event regexp '_Click$',1,0)) clc_num,
          count(DISTINCT if(event regexp '_Click$',user_id,NULL)) clc_unum
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2025-11-06'
     AND put_id IN (3215)
   GROUP BY 1,
            2,
            3) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id;

=====================================================
-- 每日发起提现用户量 18w+
-- 流量和实际每日提现成功用户量之间gap太大，流量需校准

SELECT distinct_id,
       get_json_string(properties, '$.page_name') page_name,
       get_json_string(properties, '$.city') city,
       get_json_string(properties, '$.module_name') module_name,
       get_json_string(properties, '$.button_name') button_name
FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time, '%Y-%m-%d') = '2025-11-13'
  AND event='Withdrawpage_Click';

-- 每日提现成功用户量 26w+1
SELECT dt,
       count(DISTINCT user_id) `总提现用户量`
FROM dwd.dwd_sr_user_withdraw_record
WHERE dt BETWEEN '2025-11-10' AND '2025-11-17'
  AND status=1
GROUP BY 1;


-- 首次提现
WITH t1 AS
  (SELECT user_id,
          date(min(create_time)) min_date
   FROM dwd.dwd_sr_user_withdraw_record
   WHERE status=1
   GROUP BY 1),

-- 每日访问用户
t2 AS
  (SELECT statistics_date,
          unnest_bitmap AS user_id
   FROM dws.dws_sr_user_login_d,
        unnest_bitmap(view_uids) AS uid
   WHERE statistics_date BETWEEN '2025-10-18' AND '2025-11-17'
   GROUP BY 1,
            2)

-- 整体
SELECT min_date `首次提现日期`,
       count(DISTINCT t1.user_id) `首次提现用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=1,t1.user_id,NULL)) `首次提现次日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=3,t1.user_id,NULL)) `首次提现次3日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=7,t1.user_id,NULL)) `首次提现次7日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=14,t1.user_id,NULL)) `首次提现次14日留存用户量`
FROM
  (SELECT user_id,
          min_date
   FROM t1
   WHERE min_date BETWEEN '2025-10-18' AND '2025-11-17') t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
AND t1.min_date<>t2.statistics_date
GROUP BY 1;


SELECT min_date `首次提现日期`,
       count(DISTINCT t1.user_id) `首次提现用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=1,t1.user_id,NULL)) `首次提现次日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=3,t1.user_id,NULL)) `首次提现次3日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=7,t1.user_id,NULL)) `首次提现次7日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.statistics_date,t1.min_date)=14,t1.user_id,NULL)) `首次提现次14日留存用户量`
FROM
  (SELECT user_id,
          min_date
   FROM t1
   WHERE min_date BETWEEN '2025-10-18' AND '2025-11-17') t1
INNER JOIN
  (SELECT date_format(register_time,'%Y-%m-%d') register_date,
          user_id
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-10-18' AND '2025-11-17') b ON t1.user_id=b.user_id
AND t1.min_date=b.register_date
LEFT JOIN t2 ON t1.user_id=t2.user_id
AND t1.min_date<>t2.statistics_date
GROUP BY 1;




           
=====================================================
temp.temp_sr_ad_marketing_automation_envelope_coupons_log
temp.temp_sr_ad_marketing_automation_envelope_coupons

-- MA红包策略
WITH t1 AS
  (SELECT a.node_id,
          a.strategy_id,
          b.stratery_name,
          node_property,
          start_time,
          end_time,
          trigger_recurring
   FROM
     (SELECT node_id,
             strategy_id,
             node_property
      FROM dim.dim_ma_strategy_node
      WHERE node_type = 7
        AND LENGTH(node_property)>2) a
   LEFT JOIN dim.dim_ma_strategy b ON a.strategy_id=b.strategy_id
   WHERE date_format(start_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-11-18'),


-- 红包策略下红包
t2 AS
  (SELECT node_id,
          a.strategy_id,
          a.stratery_name,
          a.start_time,
          a.end_time,
          b.envelope_id
   FROM
     (SELECT node_id,
             strategy_id,
             stratery_name,
             start_time,
             end_time,
             UNNEST AS target_id
      FROM t1,
           UNNEST(split(replace(replace(replace(node_property,'{"target_ids":',''),']}',''),'[',''),",")) AS UNNEST
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN temp.temp_sr_ad_marketing_automation_envelope_coupons b ON cast(a.target_id as int)=b.id and a.strategy_id=b.plan_id),


-- 计划发放量统计
t3 AS
  (SELECT strategy_id,
          node_id,
          count(1) tot_num
   FROM test.test_sr_ad_marketing_automation_strategy_exec_log
   WHERE STATE=3
   GROUP BY 1,
            2),

-- 实际发放
-- t4 AS
--   (SELECT plan_id,
--           envelope_id,
--           sum(if(reach_num>100,1,reach_num)) reach_num
--    FROM
--      (SELECT plan_id,
--              envelope_id,
--              silk_id,
--              count(1) reach_num
--       FROM temp.temp_sr_ad_marketing_automation_envelope_coupons_log
--       GROUP BY 1,
--                2,
--                3) a
--    GROUP BY 1,
--             2)

 t4 AS
  (SELECT a.plan_id,
          a.envelope_id,
          a.node_id,
          sum(if(reach_num>100,1,reach_num)) reach_num
   FROM
     (SELECT plan_id,
             envelope_id,
             node_id,
             user_id,
             event_id,
             count(1) reach_num
      FROM dwd.dwd_sr_marketing_ma_plan_takepart_realtime
      WHERE status=2
      GROUP BY 1,
               2,
               3,
               4,
               5) a
   LEFT JOIN
     (SELECT strategy_id,
             node_id,
             silk_id,
             flow_id
      FROM test.test_sr_ad_marketing_automation_strategy_exec_log
      WHERE STATE=3
      GROUP BY 1,
               2,
               3,
               4) b ON a.plan_id=b.strategy_id
   AND a.node_id=b.node_id
   AND a.user_id=b.silk_id
   AND a.event_id=b.flow_id
   WHERE b.strategy_id IS NOT NULL
   GROUP BY 1,
            2,
            3)


-- select * from t3 where strategy_id=3555;

SELECT t2.strategy_id,
       t2.stratery_name,
       t2.node_id,
       ifnull(cast(t2.start_time AS varchar(25)),'') start_time,
       ifnull(cast(t2.end_time AS varchar(25)),'') end_time,
       t2.envelope_id,
       ifnull(t3.tot_num,0) `计划发放红包量`,
       ifnull(t4.reach_num,0) `实际发放红包量`
FROM t2
LEFT JOIN t3 ON t2.strategy_id=t3.strategy_id
AND t2.node_id=t3.node_id
LEFT JOIN t4 ON t2.strategy_id=t4.plan_id
AND t2.node_id=t4.node_id
AND t2.envelope_id=t4.envelope_id;

=========
-- 超发明细

WITH t1 AS
  (SELECT a.node_id,
          a.strategy_id,
          b.stratery_name,
          node_property,
          start_time,
          end_time,
          trigger_recurring
   FROM
     (SELECT node_id,
             strategy_id,
             node_property
      FROM dim.dim_ma_strategy_node
      WHERE node_type = 7
        AND LENGTH(node_property)>2) a
   LEFT JOIN dim.dim_ma_strategy b ON a.strategy_id=b.strategy_id
   WHERE date_format(start_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-11-18'),


-- 红包策略下红包
t2 AS
  (SELECT node_id,
          a.strategy_id,
          a.stratery_name,
          a.start_time,
          a.end_time,
          b.envelope_id
   FROM
     (SELECT node_id,
             strategy_id,
             stratery_name,
             start_time,
             end_time,
             UNNEST AS target_id
      FROM t1,
           UNNEST(split(replace(replace(replace(node_property,'{"target_ids":',''),']}',''),'[',''),",")) AS UNNEST
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN temp.temp_sr_ad_marketing_automation_envelope_coupons b ON cast(a.target_id as int)=b.id and a.strategy_id=b.plan_id),

-- 计划发和实际发
t3 AS
  (SELECT a.plan_id,
          a.envelope_id,
          a.node_id,
          a.user_id,
          a.event_id,
          b.plan_num,
          if(reach_num>100,1,reach_num) reach_num
   FROM
     (SELECT plan_id,
             envelope_id,
             node_id,
             user_id,
             event_id,
             count(1) reach_num
      FROM dwd.dwd_sr_marketing_ma_plan_takepart_realtime
      WHERE status=2
      GROUP BY 1,
               2,
               3,
               4,
               5) a
   LEFT JOIN
     (SELECT strategy_id,
             node_id,
             silk_id,
             flow_id,
             count(1) plan_num
      FROM test.test_sr_ad_marketing_automation_strategy_exec_log
      WHERE STATE=3
      GROUP BY 1,
               2,
               3,
               4) b ON a.plan_id=b.strategy_id
   AND a.node_id=b.node_id
   AND a.user_id=b.silk_id
   AND a.event_id=b.flow_id
   WHERE b.strategy_id IS NOT NULL),


-- -- 超发红包
-- SELECT 
--     a.envelope_id,
--     sum(reach_num) reach_num,
--     sum(plan_num) plan_num
-- FROM
--   (SELECT plan_id,
--           envelope_id,
--           node_id,
--           user_id,
--           event_id,
--           reach_num,
--           plan_num
--    FROM t3
--    WHERE reach_num>plan_num) a
-- LEFT JOIN t2 ON a.plan_id=t2.strategy_id
-- AND a.node_id=t2.node_id
-- AND a.envelope_id=t2.envelope_id
-- WHERE t2.strategy_id IS NOT NULL
-- group by 1;

-- 用户完单量和利润
select
  user_id,
from dwd.dwd_sr_order_promotion_order
where dt between '2025-09-18' and '2025-11-23'
and order_status in (2,8)



-- 超发红包明细
-- 策略最小开始日期是20250918

(SELECT 
       a.plan_id,
       a.envelope_id,
       a.node_id,
       a.user_id,
       a.event_id,
       t2.start_time,
       t2.end_time,
       a.plan_num,
       a.reach_num
FROM
  (SELECT plan_id,
          envelope_id,
          node_id,
          user_id,
          event_id,
          reach_num,
          plan_num
   FROM t3
   WHERE reach_num>plan_num) a
LEFT JOIN t2 ON a.plan_id=t2.strategy_id
AND a.node_id=t2.node_id
AND a.envelope_id=t2.envelope_id
WHERE t2.strategy_id IS NOT NULL
) toa
where envelope_id IN (707, 735, 732, 711, 723, 708, 726, 729, 736, 717, 737, 714, 709, 733, 720, 734, 724, 727, 
  730, 712, 713, 728, 725, 718, 731, 715, 719, 721, 716, 722, 832, 806, 699, 700, 327)




==============
## 统计超发金额


WITH t1 AS
  (SELECT a.node_id,
          a.strategy_id,
          b.stratery_name,
          node_property,
          start_time,
          end_time,
          trigger_recurring
   FROM
     (SELECT node_id,
             strategy_id,
             node_property
      FROM dim.dim_ma_strategy_node
      WHERE node_type = 7
        AND LENGTH(node_property)>2) a
   LEFT JOIN dim.dim_ma_strategy b ON a.strategy_id=b.strategy_id
   WHERE date_format(start_time,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-11-18'),


-- 红包策略下红包
t2 AS
  (SELECT node_id,
          a.strategy_id,
          a.stratery_name,
          a.start_time,
          a.end_time,
          b.envelope_id
   FROM
     (SELECT node_id,
             strategy_id,
             stratery_name,
             start_time,
             end_time,
             UNNEST AS target_id
      FROM t1,
           UNNEST(split(replace(replace(replace(node_property,'{"target_ids":',''),']}',''),'[',''),",")) AS UNNEST
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN temp.temp_sr_ad_marketing_automation_envelope_coupons b ON cast(a.target_id as int)=b.id and a.strategy_id=b.plan_id),


-- 计划发和实际发
t3 AS
  (SELECT a.plan_id,
          a.envelope_id,
          a.node_id,
          a.user_id,
          a.event_id,
          b.plan_num,
          if(reach_num>100,1,reach_num) reach_num
   FROM 
   -- 实际发
     (SELECT plan_id,
             envelope_id,
             node_id,
             user_id,
             event_id,
             count(1) reach_num
      FROM dwd.dwd_sr_marketing_ma_plan_takepart_realtime
      WHERE status=2
        AND type=7
      GROUP BY 1,
               2,
               3,
               4,
               5) a
   LEFT JOIN 
   -- 计划发
     (SELECT strategy_id,
             node_id,
             silk_id,
             flow_id,
             count(1) plan_num
      FROM test.test_sr_ad_marketing_automation_strategy_exec_log
      WHERE STATE=3
      GROUP BY 1,
               2,
               3,
               4) b ON a.plan_id=b.strategy_id
   AND a.node_id=b.node_id
   AND a.user_id=b.silk_id
   AND a.event_id=b.flow_id
   WHERE b.strategy_id IS NOT NULL),

-- 超发红包和用户
t4 AS
  (SELECT plan_id,
          envelope_id,
          user_id,
          sum(reach_num) reach_num,
                         sum(plan_num) plan_num
   FROM t3
   WHERE reach_num>plan_num
   GROUP BY 1,
            2,
            3),


-- select plan_id,envelope_id,count(1) tot,count(distinct user_id) unum,sum(reach_num) reach_num,sum(plan_num) plan_num from t4 group by 1,2;

-- 红包实际发放和使用
t5 AS
  (SELECT redpacket_id,
          user_id,
          count(1) tot,
                   count(DISTINCT if(redpacket_use_status=2,order_id,null)) cost_order_num,
                                            sum(if(redpacket_use_status=2,1,0)) used_num,
                                                                                sum(if(redpacket_use_status=2,real_rebate_amt,0)) redpacket_amt
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt BETWEEN '2025-08-01' AND '2025-11-19' -- AND date_format(used_time,'%Y-%m-%d') BETWEEN '2025-10-01' AND '2025-10-31'
   GROUP BY 1,
            2),

-- 用户完单量和利润
t6 AS
  (SELECT user_id,
          count(1) valid_order_num,
                   sum(if(order_status=2,profit,0)) profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-09-18' and '2025-11-23' -- date_sub('2025-09-17',interval 96 day) AND '2025-09-17'
     AND order_status IN (2,
                          8)
   GROUP BY 1),

-- 红包实际发放和使用
t7 AS
  (SELECT 
          user_id,
          count(1) tot,
                   count(DISTINCT if(redpacket_use_status=2,order_id,null)) tot_cost_order_num,
                                            sum(if(redpacket_use_status=2,1,0)) tot_used_num,
                                                                                sum(if(redpacket_use_status=2,real_rebate_amt,0)) tot_redpacket_amt
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt BETWEEN '2025-08-01' AND '2025-11-19' -- AND date_format(used_time,'%Y-%m-%d') BETWEEN '2025-10-01' AND '2025-10-31'

   GROUP BY 1)




-- 超用用户消耗 验证明细

SELECT a.plan_id,
       a.envelope_id,
       a.user_id,
       a.cost_order_num,
       a.redpacket_amt,
       t6.valid_order_num,
       t6.profit
FROM
  (SELECT plan_id,
          envelope_id,
          t4.user_id,
          sum(cost_order_num) cost_order_num,
          sum(redpacket_amt) redpacket_amt
   FROM t4
   LEFT JOIN t5 ON t4.envelope_id = t5.redpacket_id
   AND t4.user_id = t5.user_id
   WHERE t5.user_id IS NOT NULL
     AND t4.plan_num<t5.tot
     AND t5.used_num>t4.plan_num
   GROUP BY 1,
            2,
            3) a
LEFT JOIN t6 ON a.user_id=t6.user_id
WHERE t6.user_id IS NOT NULL
  AND a.envelope_id=806 LIMIT 1000 ;




-- 超发消耗且后续有利润贡献
SELECT plan_id,
       envelope_id,
       count(distinct user_id) unum,
       sum(cost_order_num) cost_order_num,
       sum(redpacket_amt) redpacket_amt,
       sum(valid_order_num) valid_order_num,
       sum(tot_cost_order_num) tot_cost_order_num,
       sum(tot_redpacket_amt) tot_redpacket_amt
       
FROM
  (
    SELECT plan_id,
          envelope_id,
          a.user_id,
          cost_order_num,
          redpacket_amt,
          valid_order_num,
          (valid_order_num-cost_order_num)*2.4 add_profit,
          tot_cost_order_num,
          tot_redpacket_amt
   FROM
     (SELECT plan_id,
             envelope_id,
             t4.user_id,
             sum(cost_order_num) cost_order_num,
             sum(redpacket_amt) redpacket_amt
      FROM t4
      LEFT JOIN t5 ON t4.envelope_id = t5.redpacket_id
      AND t4.user_id = t5.user_id
      WHERE t5.user_id IS NOT NULL
        AND t4.plan_num<t5.tot
        AND t5.used_num>t4.plan_num
      GROUP BY 1,
               2,
               3
               ) a
   LEFT JOIN t6 ON a.user_id=t6.user_id
   LEFT JOIN t7 ON a.user_id=t7.user_id
   WHERE t6.user_id IS NOT NULL
    AND t7.user_id IS NOT NULL
    --  AND cost_order_num<valid_order_num
    --  and a.plan_id=3508 and envelope_id=707
    -- order by cost_order_num desc limit 100
    AND a.cost_order_num>0
     AND a.cost_order_num<valid_order_num
     ) toa
GROUP BY 1,
         2;


-- -- 验证
-- select redpacket_id,used_time,user_id,order_id,redpacket_use_status from dwd.dwd_sr_market_redpack_use_record
--    WHERE dt BETWEEN '2025-08-01' AND '2025-11-19'
--    and user_id=694764902 -- 717877159;

-- select order_time,user_id,order_id
-- from dwd.dwd_sr_order_promotion_order
--    WHERE dt BETWEEN '2025-09-18' and '2025-11-23' -- date_sub('2025-09-17',interval 96 day) AND '2025-09-17'
--      AND order_status IN (2,
--                           8)
--     and user_id=694764902 -- 717877159;




-- 验证 超发消耗红包实际发和到手 是否有差异
-- ma发放
WITH t1 AS (
  SELECT -- plan_id,
       envelope_id,
       -- node_id,
       -- user_id,
       -- event_id,
       count(1) reach_num
FROM dwd.dwd_sr_marketing_ma_plan_takepart_realtime
WHERE status=2
  AND TYPE=7
  AND envelope_id IN (707, 735, 732, 711, 723, 708, 726, 729, 736, 717, 737, 714, 709, 733, 720, 734, 724, 727, 
  730, 712, 713, 728, 725, 718, 731, 715, 719, 721, 716, 722, 832, 806, 699, 700, 327)
GROUP BY 1),

-- 红包实际发放和使用
t2 AS
  (SELECT redpacket_id,
          count(1) tot,
                   sum(if(redpacket_use_status=2,1,0)) used_num,
                                                       sum(if(redpacket_use_status=2,real_rebate_amt,0)) redpacket_amt
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt BETWEEN '2025-08-01' AND '2025-11-19'
      AND redpacket_id IN (707, 735, 732, 711, 723, 708, 726, 729, 736, 717, 737, 714, 709, 733, 720, 734, 724, 727, 
    730, 712, 713, 728, 725, 718, 731, 715, 719, 721, 716, 722, 832, 806, 699, 700, 327)
   GROUP BY 1)

SELECT t1.envelope_id,
       t1.reach_num,
       t2.tot,
       t2.used_num,
       t2.redpacket_amt
FROM t1
LEFT JOIN t2 ON t1.envelope_id=t2.redpacket_id ;


-- 以策略3508来看发放
SELECT redpacket_id,
       user_id,
       date_format(create_time,'%Y-%m-%d %H:%i:%s') create_time,
       count(1) tot
FROM dwd.dwd_sr_market_redpack_use_record
WHERE dt ='2025-10-13'
  AND redpacket_id IN (707,
                       708,
                       709)
GROUP BY 1,
         2,
         3 HAVING count(1)>10 LIMIT 100;


-- 以某用户来看
SELECT *
FROM dwd.dwd_sr_market_redpack_use_record
WHERE dt ='2025-10-13'
  AND redpacket_id=707
  AND user_id=193612911;


== 超发数量
select redpacket_id,
          dt,
          sum(if(cnt=1,1,0)) plan_num,
          count(1) unum,
          sum(cnt) tot
from (SELECT redpacket_id,
          dt,
          user_id,
          count(1) cnt
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt BETWEEN '2025-09-18' AND '2025-11-19'
      AND redpacket_id IN (707, 735, 732, 711, 723, 708, 726, 729, 736, 717, 737, 714, 709, 733, 720, 734, 724, 727, 
    730, 712, 713, 728, 725, 718, 731, 715, 719, 721, 716, 722, 832, 806, 699, 700, 327)
   GROUP BY 1,2,3) a
group by 1,2;


=====================
-- 搜索场景下单归因
WITH t1 AS
  (SELECT distinct_id AS user_id,
          time
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date(time)='2025-11-17' 
     -- AND event='Takeaway_Baomingflow_Button_Click'
     -- AND from_source='搜索结果'
     AND event='Search_Result_Click'
     AND entrance IN ('首页',
                   '主页')
     AND distinct_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2),

-- 订单
 t2 AS
  (SELECT store_promotion_id,
          user_id,
          order_time,
          order_id,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-11-17' AND '2025-11-18'),

-- 订单归因数据集
 t3 AS
  (SELECT t1.user_id,
          t1.time,
          t2.store_promotion_id AS yw_promotion_id,
          t2.user_id AS yw_user_id,
          t2.order_time,
          t2.order_id,
          t2.order_status
   FROM t1
   LEFT JOIN t2 ON t1.user_id=t2.user_id
   -- AND date_diff('second',date_format(t2.order_time,'%Y-%m-%d %H:%i:%s'),date_format(t1.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 5)
   AND date_diff('second',date_format(t2.order_time,'%Y-%m-%d %H:%i:%s'),date_format(t1.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 30)




SELECT date_format(time,'%Y-%m-%d') `下单日期`,
       COUNT(DISTINCT user_id) `搜索结果点击用户量`,
       count(DISTINCT if(yw_user_id IS NOT NULL,order_id,NULL)) `下单量`,
       count(DISTINCT if(yw_user_id IS NOT NULL,yw_user_id,NULL)) `下单用户量`,
       count(DISTINCT if(yw_user_id IS NOT NULL
                         AND order_status IN (2,8),order_id,NULL)) `完单量`,
       count(DISTINCT if(yw_user_id IS NOT NULL
                         AND order_status IN (2,8),yw_user_id,NULL)) `完单用户量`
FROM t3
GROUP BY 1;




=======================================
-- 店铺名称不一致工单统计

-- 店铺名称不一致订单
WITH t1 AS
  (SELECT order_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-09-01' AND '2025-11-17'
     AND (audit_reason_type=6
          OR customer_service_audit_feedback regexp '非活动店铺订单')),

-- 工单
t2 AS
  (SELECT dt,
          work_order_id,
          order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-09-01' AND '2025-11-17')


SELECT dt,
       count(DISTINCT t2.work_order_id) `店铺名称不一致工单量`
FROM t2
LEFT JOIN t1 ON t2.order_id=t1.order_id
WHERE t1.order_id IS NOT NULL
GROUP BY 1;

=======================================

-- 不满意订单用户量
WITH t1 AS
  (SELECT date_format(dt,'%Y-%m') ym,
                                  user_id,
                                  count(1) order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-09-01' AND '2025-10-31'
     AND order_status=8
   GROUP BY 1,
            2)

SELECT ym,
       user_id,
       order_num
FROM t1
WHERE order_num>=6
GROUP BY 1,
         2 ;


-- 不满意订单量分布
SELECT ym `月份`,
       order_num `订单量`,
       count(1) `用户量`
FROM t1
GROUP BY 1,
         2;

-- 不满意订单用户重合度
SELECT count(DISTINCT a.user_id) `10月不满意订单用户量`,
       count(DISTINCT if(b.user_id IS NOT NULL,a.user_id,NULL)) `不满意订单重合用户量`
FROM
  (SELECT user_id
   FROM t1
   WHERE ym='2025-10'
   GROUP BY 1) a
LEFT JOIN
  (SELECT user_id
   FROM t1
   WHERE ym='2025-09'
   GROUP BY 1) b ON a.user_id=b.user_id ;





================ 不满意订单量
WITH t AS
  (SELECT store_id,
          count(1) valid_order_num,
                   count(if(order_status=8,auto_id,NULL)) unsatisfied_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-10-01' AND '2025-10-31'
     AND order_status IN (2,
                          8)
   GROUP BY 1)


-- 不满意订单量
select
  unsatisfied_order_num,
  count(1) store_num
from t
where unsatisfied_order_num between 1 and 10
group by 1;

-- 完单中不满意订单占比
SELECT CASE
           WHEN rate=0 THEN '无不满意订单'
           WHEN rate>0
                AND rate<0.05 THEN '5%以内'
           WHEN rate>=0.05
                AND rate<0.1 THEN '5%-10%'
           WHEN rate>=0.1
                AND rate<0.15 THEN '10%-15%'
           WHEN rate>=0.15
                AND rate<0.2 THEN '15%-20%'
           WHEN rate>=0.2
                AND rate<0.25 THEN '20%-25%'
           WHEN rate>=0.25
                AND rate<0.3 THEN '25%-30%'
           WHEN rate>=0.3 THEN '30%及以上'
           ELSE '其他'
       END `完单中不满意订单占比`,
       count(1) cnt
FROM
  (SELECT store_id,
          unsatisfied_order_num/valid_order_num AS rate
   FROM t
   WHERE valid_order_num>=10) a
GROUP BY 1;


-- 不满意订单分布
SELECT CASE
           WHEN unsatisfied_order_num BETWEEN 1 AND 5 THEN '1-5单'
           WHEN unsatisfied_order_num BETWEEN 6 AND 10 THEN '6-10单'
           WHEN unsatisfied_order_num BETWEEN 11 AND 15 THEN '11-15单'
           WHEN unsatisfied_order_num BETWEEN 16 AND 20 THEN '16-20单'
           WHEN unsatisfied_order_num BETWEEN 21 AND 25 THEN '21-25单'
           WHEN unsatisfied_order_num BETWEEN 26 AND 30 THEN '26-30单'
       END `不满意订单量区间`,
       count(1) `店铺数`
FROM t
WHERE unsatisfied_order_num>0
GROUP BY 1;



-- 不满意订单占比分布
SELECT CASE
           WHEN unsatisfied_order_num BETWEEN 1 AND 5 THEN '1-5单'
           WHEN unsatisfied_order_num BETWEEN 6 AND 10 THEN '6-10单'
           WHEN unsatisfied_order_num BETWEEN 11 AND 15 THEN '11-15单'
           WHEN unsatisfied_order_num BETWEEN 16 AND 20 THEN '16-20单'
           WHEN unsatisfied_order_num BETWEEN 21 AND 25 THEN '21-25单'
           WHEN unsatisfied_order_num BETWEEN 26 AND 30 THEN '26-30单'
       END `不满意订单量区间`,
       count(1) `店铺数`,
       min(rate) `不满意订单占比最小值`,
       percentile_cont(rate,0.1) `不满意订单占比10分位`,
       percentile_cont(rate,0.2) `不满意订单占比20分位`,
       percentile_cont(rate,0.3) `不满意订单占比30分位`,
       percentile_cont(rate,0.4) `不满意订单占比40分位`,
       percentile_cont(rate,0.5) `不满意订单占比50分位`,
       percentile_cont(rate,0.6) `不满意订单占比60分位`,
       percentile_cont(rate,0.7) `不满意订单占比70分位`,
       percentile_cont(rate,0.8) `不满意订单占比80分位`,
       percentile_cont(rate,0.9) `不满意订单占比90分位`,
       max(rate) `不满意订单占比最大值`
FROM
  (SELECT store_id,
          unsatisfied_order_num,
          unsatisfied_order_num/valid_order_num rate
   FROM t
   WHERE unsatisfied_order_num>0) toa
GROUP BY 1;


-- 不满意订单占比分布
SELECT CASE
           WHEN unsatisfied_order_num BETWEEN 1 AND 5 THEN '1-5单'
           WHEN unsatisfied_order_num BETWEEN 6 AND 10 THEN '6-10单'
           WHEN unsatisfied_order_num BETWEEN 11 AND 15 THEN '11-15单'
           WHEN unsatisfied_order_num BETWEEN 16 AND 20 THEN '16-20单'
           WHEN unsatisfied_order_num BETWEEN 21 AND 25 THEN '21-25单'
           WHEN unsatisfied_order_num BETWEEN 26 AND 30 THEN '26-30单'
       END `不满意订单量区间`,
       sum(unsatisfied_order_num) `不满意订单量`,
       sum(valid_order_num) `有效订单量`
FROM t
WHERE unsatisfied_order_num>0
GROUP BY 1;



-- 本月不满意订单
WITH t1 AS
  (SELECT user_id,
          count(1) valid_order_num,
                   count(if(order_status=8,auto_id,NULL)) unsatisfied_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2026-03-01' AND '2026-03-29'
     AND order_status IN (2,
                          8)
   GROUP BY 1),

-- 1月不满意订单
t2 AS
  (SELECT user_id,
          count(1) valid_order_num,
                   count(if(order_status=8,auto_id,NULL)) unsatisfied_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2026-01-01' AND '2026-01-29'
     AND order_status IN (2,
                          8)
   GROUP BY 1)

-- 不满意订单量分布
SELECT CASE
           WHEN unsatisfied_order_num BETWEEN 2 AND 5 THEN '2-5单'
           WHEN unsatisfied_order_num>=6 THEN '6单及以上'
           ELSE '其他'
       END `不满意订单量区间`,
       count(1) `用户量`
FROM t1
GROUP BY 1;

-- 不满意订单用户明细
SELECT t1.user_id,
       t1.unsatisfied_order_num,
       t1.valid_order_num,
       new_level,
       is_plus
FROM t1
LEFT JOIN
  ( SELECT silk_id,
           new_level,
           is_plus
   FROM ods.ods_sr_client_vip_realtime ) b ON t1.user_id = b.silk_id
WHERE t1.unsatisfied_order_num>=2;


-- 与上月用户重合度
SELECT a.`不满意订单量区间`,
       count(a.user_id) `本月不满意订单用户量`,
       count(if(b.user_id IS NOT NULL,a.user_id,NULL)) `与1月不满意订单重合用户量`
FROM
  (SELECT user_id,
          CASE
              WHEN unsatisfied_order_num BETWEEN 2 AND 5 THEN '2-5单'
              WHEN unsatisfied_order_num>=6 THEN '6单及以上'
              ELSE '其他'
          END `不满意订单量区间`
   FROM t1
   WHERE unsatisfied_order_num>=2) a
LEFT JOIN
  (SELECT user_id,
          CASE
              WHEN unsatisfied_order_num BETWEEN 2 AND 5 THEN '2-5单'
              WHEN unsatisfied_order_num>=6 THEN '6单及以上'
              ELSE '其他'
          END `不满意订单量区间`
   FROM t2
   WHERE unsatisfied_order_num>=2) b ON a.user_id=b.user_id
AND a.`不满意订单量区间`=b.`不满意订单量区间`
GROUP BY 1;


-- 与上月用户重合度
SELECT a.`不满意订单量区间`,
       count(a.user_id) `本月不满意订单用户量`,
       count(if(b.user_id IS NOT NULL,a.user_id,NULL)) `与1月不满意订单重合用户量`
FROM
  (SELECT user_id,
          CASE
              WHEN unsatisfied_order_num>=6 THEN '6单及以上'
              ELSE unsatisfied_order_num
          END `不满意订单量区间`
   FROM t1
   WHERE unsatisfied_order_num BETWEEN 2 AND 5) a
LEFT JOIN
  (SELECT user_id
   FROM t2
   WHERE unsatisfied_order_num BETWEEN 2 AND 5) b ON a.user_id=b.user_id
GROUP BY 1;


================== 搜索数据统计

select  search_date `搜索日期`,
        -- keywords `搜索词`,
        count(distinct user_id) `搜索用户量`,
        sum(search_num) `搜索量`,
        sum(search_expose_num) `搜索结果曝光量`,
        sum(search_result_click_num) `搜索结果点击量`,
        sum(takeaway_baoming_order_num) `搜索报名订单量`,
        sum(takeaway_valid_order_num) `搜索有效订单量`,
        sum(takeaway_profit) `搜索有效订单利润`,
        sum(takeaway_redpacket_amt) `搜索订单使用红包金额`
from    dws.dws_sr_traffic_search_user_d
where   search_date = '2025-11-26'
group by 1
-- having sum(search_num)>10000
-- order by 4 desc
-- limit 1000;


=======================================================================
SELECT dt `统计日期`,
       redpacket_id `红包ID`,
       redpacket_name `红包名称`,
       business_name `业务线`,
       redpacket_status `红包状态`,
       tot `发放量`,
       unum `发放用户量`,
       used_num `使用量`,
       used_unum `使用用户量`,
       cost_amt `使用金额`
FROM
  (SELECT dt,
          redpacket_id,
          count(1) tot,
          count(DISTINCT user_id) unum,
          sum(if(redpacket_use_status=2,1,0)) used_num,
          count(DISTINCT if(redpacket_use_status=1,user_id,NULL)) used_unum,
          sum(if(redpacket_use_status=2,real_rebate_amt,0)) cost_amt
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt BETWEEN '2025-11-21' AND '2025-11-27'
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT redpacket_id,
          redpacket_name,
          CASE
              WHEN business_type=0 THEN '霸王餐'
              WHEN business_type=1 THEN '砍价'
              WHEN business_type=2 THEN '探店'
              ELSE '其他'
          END business_name,
          if(redpacket_status=1,'在线','下线') redpacket_status
   FROM dim.dim_silkworm_redpack) b ON a.redpacket_id=b.redpacket_id;






============== 商家不合作工单
-- SELECT work_order_id `工单ID`,
--        content `工单内容`,
--        a.status `工单状态`,
--        a.audit_status `工单审核状态`,
--        merchant_id `商家ID`,
--        store_id `店铺ID`,
--        store_name `店铺名称`,
--        CASE
--            WHEN promotion_type IN (1,
--                                    4) THEN '探店'
--            WHEN promotion_type IN (5,
--                                    6,
--                                    8) THEN '砍价'
--            ELSE '其他'
--        END `活动类型`,
--        b.bd_id,
--        lvl6_dept_name `一级部门名称`,
--        lvl5_dept_name `二级部门名称`,
--        lvl4_dept_name `三级部门名称`,
--        lvl3_dept_name `四级部门名称`,
--        lvl2_dept_name `五级部门名称`,
--        lvl1_dept_name `六级部门名称`,
--        begin_time `活动开始时间`,
--        finish_time `审核完成时间`,
--        date_ddiff('day',finish_time,begin_time) `生命天数`
-- FROM
--   (SELECT work_order_id,
--           create_time,
--           finish_time,
--           audit_time,
--           content,
--           promotion_id,
--           if(status=2,'已完结','待受理') status,
--           CASE
--               WHEN audit_status=0 THEN '未知'
--               WHEN audit_status=1 THEN '待审核'
--               WHEN audit_status=2 THEN '审核通过'
--               WHEN audit_status=3 THEN '审核驳回'
--               ELSE '其他'
--           END audit_status
--    FROM dwd.dwd_sr_callcenter_workorder
--    WHERE dt BETWEEN '2025-11-01' AND '2025-11-30'
--      AND cate3_type IN (69,
--                         71)) a
-- LEFT JOIN dwd.dwd_sr_silkworm_explore_promotion b ON a.promotion_id=b.promotion_id
-- LEFT JOIN dim.dim_silkworm_staff_depart c ON b.bd_id=c.bd_id ;


SELECT `商家ID`,
       c.store_id `店铺ID`,
       `业务类型`,
       `合作处理结果`,
       `BD受理人`,
       `BD团队`,
       cast(min_begin_time AS string) `首次活动开始时间`,
       cast(`工单最后更新时间` AS string) `工单最后更新时间`,
       date_diff('day', `工单最后更新时间`, min_begin_time) AS `生命天数`
FROM
  (SELECT auto_id,
          t.merchant_silk_id AS `商家ID`,
          CAST(item AS INT) AS `店铺ID`,
          IF(t.business_type = 1, '砍价', '探店') AS `业务类型`,
          '商家不合作' AS `合作处理结果`,
          t.bd_receiver AS `BD受理人`,
          t.bd_team_name AS `BD团队`,
          t.created_at AS `合作开始时间`,
          t.updated_at AS `工单最后更新时间`
   FROM temp.temp_sr_silkworm_explore_merchant_refusal_receive t
   JOIN UNNEST(split(replace(replace(CAST(t.store_id AS STRING), '[', ''), ']', ''), ',')) AS u(item)
   WHERE t.created_at BETWEEN '2025-11-01 00:00:00' AND '2025-11-30 23:59:59'
     AND t.processing_scheme = 2) a
LEFT JOIN
  (SELECT merchant_id,
          min(create_time) min_begin_time
   FROM dwd.dwd_sr_silkworm_explore_promotion
   GROUP BY 1) b ON a.`商家ID`=b.merchant_id
LEFT JOIN temp.temp_sr_silkworm_explore_merchant_refusal_receive c ON a.auto_id=c.auto_id
;




========= 每日注册用户量
SELECT date_format(register_time,'%Y-%m-%d') dat,
       count(1) `注册用户量`,
       count(if(inviter_user_id<>0,user_id,NULL)) `团长拉新用户量`,
       count(DISTINCT if(inviter_user_id<>0,inviter_user_id,NULL)) `拉新团长用户量`
FROM dim.dim_silkworm_user
WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2024-01-01' AND '2025-11-09'
GROUP BY 1;


======== 外卖活动指标
SELECT dt,
       promotion_id,
       count(promotion_id) tot,
       count(DISTINCT promotion_id) cnt,
       sum(tot_homepage_activity_expose_num)+sum(tot_search_expose_num) bg_num,
       sum(tot_homepage_activity_clc_num)+sum(tot_search_result_clc_num) clc_num,
       sum(order_num) order_num
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt='2025-11-20'
GROUP BY 1,
         2
ORDER BY order_num DESC LIMIT 100 ;


======== 挑战赛用户量

SELECT date_format(dt,'%Y-%m') ym,
       cardinality(array_unique_agg(com_user_list)) uids
FROM dws.dws_sr_silkworm_challenge_td
WHERE dt BETWEEN '2025-10-28' AND '2025-10-30'
  AND challenge_type=1
GROUP BY 1;



SELECT date(dt) dt,
       count(1) cnt,
       count(DISTINCT if(challenge_type = 1, challenge_id, NULL)) daka_cnt,
       count(DISTINCT if(challenge_type = 2, challenge_id, NULL)) laxin_cnt,
       count(if(challenge_type = 1, takepart_id, NULL)) daka_num,
       count(if(challenge_type = 2, takepart_id, NULL)) laxin_num
FROM dwd.dwd_sr_silkworm_challenge_user_promotion
WHERE dt BETWEEN '2025-08-20' AND '2025-09-07'
GROUP BY 1;

SELECT a.challenge_id,
       b.challenge_name,
       b.challenge_desc,
       a.unum `参与用户量`
FROM
  ( SELECT challenge_id,
           count(DISTINCT user_id) unum
   FROM
     ( SELECT challenge_id,
              get_json_int(value, '$.SilkId') AS user_id
      FROM dwd.dwd_sr_silkworm_challenge_user_promotion,
           json_each(parse_json(group_user_id_list)) AS a
      WHERE dt BETWEEN '2025-06-01' AND '2025-06-07'
        AND challenge_type = 1
      GROUP BY 1,
               2 ) a1
   GROUP BY 1 ) a
LEFT JOIN dim.dim_silkworm_challenge_promotion b ON a.challenge_id = b.challenge_id;


SELECT *
FROM
  ( SELECT challenge_id,
           challenge_name,
           challenge_desc,
           from_unixtime(begin_time, '%Y-%m-%d') begin_date,
           from_unixtime(end_time, '%Y-%m-%d') end_date
   FROM dim.dim_silkworm_challenge_promotion
   WHERE challenge_type = 1 ) a
WHERE begin_date BETWEEN '2025-05-18' AND '2025-05-24';


============ 挑战赛支出统计
SELECT a.dt AS statistics_date,
          '外卖' AS business_name,
          if(challenge_type=1,'下单挑战赛','邀请挑战赛') AS cost_typename,
          user_id,
          sum(reward_num)/100 AS cost_amt
   FROM
     (SELECT dt,
             user_id,
             takepart_id,
             sum(grant_num) reward_num
      FROM ods.ods_sr_silkworm_challenge_user_reward
      WHERE dt ='2025-12-15'
        AND is_grant_success = 1
        AND reward_type=1
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN
     (SELECT takepart_id,
             challenge_type
      FROM dwd.dwd_sr_silkworm_challenge_user_promotion
      WHERE dt BETWEEN date_sub('2025-12-15',interval 30 DAY) AND '2025-12-15'
        AND challenge_type IN (1,
                               2)) b ON a.takepart_id=b.takepart_id
   GROUP BY 1,
            2,
            3,
            4
limit 10;



================ 外卖取消订单时间分布
-- 分布
SELECT if(order_status=4,'手动取消','超时取消') `取消类型`,
       count(DISTINCT user_id) `用户量`,
       count(auto_id) `订单量`,
       min(diff_snd) `最小值`,
       percentile_cont(diff_snd,0.1) `10分位值`,
       percentile_cont(diff_snd,0.2) `20分位值`,
       percentile_cont(diff_snd,0.3) `30分位值`,
       percentile_cont(diff_snd,0.4) `40分位值`,
       percentile_cont(diff_snd,0.5) `50分位值`,
       percentile_cont(diff_snd,0.6) `60分位值`,
       percentile_cont(diff_snd,0.7) `70分位值`,
       percentile_cont(diff_snd,0.8) `80分位值`,
       percentile_cont(diff_snd,0.9) `90分位值`,
       max(diff_snd) `最大值`
FROM
  (SELECT auto_id,
          user_id,
          order_time,
          order_status,
          cancel_time,
          date_diff('second',cancel_time,order_time) diff_snd
   FROM
     (SELECT auto_id,
             user_id,
             order_time,
             order_status,
             platform_order_detail,
             from_unixtime(get_json_string(platform_order_detail,'$.cancel_time'),'%Y-%m-%d %H:%i:%s') cancel_time
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-12-09' AND '2025-12-15'
        AND order_status IN (4,
                             5)) a) b
GROUP BY 1;


-- 统计
SELECT if(order_status=4,'手动取消','超时取消') `取消类型`,
       CASE
           WHEN order_status=4
                AND diff_snd BETWEEN 1 AND 59 THEN '1分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 61 AND 119 THEN '1-2分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 120 AND 299 THEN '2-5分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 300 AND 599 THEN '5-10分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 600 AND 899 THEN '10-15分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 900 AND 1199 THEN '15-20分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 1200 AND 1799 THEN '20-30分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 1800 AND 3599 THEN '30-60分钟内'
           WHEN order_status=4
                AND diff_snd BETWEEN 3600 AND 7199 THEN '1-2小时内'
           WHEN order_status=4
                AND diff_snd>=7200 THEN '2小时及以上'
           WHEN order_status=5
                AND diff_snd BETWEEN 7 AND 1799 THEN '30分钟内'
           WHEN order_status=5
                AND diff_snd BETWEEN 1800 AND 3599 THEN '30-60分钟内'
           WHEN order_status=5
                AND diff_snd BETWEEN 3600 AND 14399 THEN '1-4小时内'
           WHEN order_status=5
                AND diff_snd BETWEEN 14400 AND 21599 THEN '4-6小时内'
           WHEN order_status=5
                AND diff_snd BETWEEN 21600 AND 28799 THEN '6-8小时内'
           WHEN order_status=5
                AND diff_snd BETWEEN 28800 AND 32399 THEN '8-9小时内'
           WHEN order_status=5
                AND diff_snd >=32400 THEN '9小时及以上'
           ELSE '其他'
       END `取消时间区间`,
       count(DISTINCT user_id) `用户量`,
       count(auto_id) `订单量`
FROM
  (SELECT auto_id,
          user_id,
          order_time,
          order_status,
          cancel_time,
          date_diff('second',cancel_time,order_time) diff_snd
   FROM
     (SELECT auto_id,
             user_id,
             order_time,
             order_status,
             platform_order_detail,
             from_unixtime(get_json_string(platform_order_detail,'$.cancel_time'),'%Y-%m-%d %H:%i:%s') cancel_time
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '${begin_date}' AND '${end_date}'
        AND order_status IN (4,
                             5)) a) b
GROUP BY 1,
         2;

===================== 实付金额、到手价分布
WITH t1 AS
  (SELECT auto_id,
          user_id,
          order_time,
          order_status,
          user_pay_amt,
          real_rebate_amt,
          user_pay_amt-real_rebate_amt AS ds_amt
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-09' AND '2025-12-15')


SELECT '实付金额' `类型`,
              count(DISTINCT user_id) `用户量`,
              count(auto_id) `订单量`,
              min(user_pay_amt) `最小值`,
              percentile_cont(user_pay_amt,0.1) `10分位值`,
              percentile_cont(user_pay_amt,0.2) `20分位值`,
              percentile_cont(user_pay_amt,0.3) `30分位值`,
              percentile_cont(user_pay_amt,0.4) `40分位值`,
              percentile_cont(user_pay_amt,0.5) `50分位值`,
              percentile_cont(user_pay_amt,0.6) `60分位值`,
              percentile_cont(user_pay_amt,0.7) `70分位值`,
              percentile_cont(user_pay_amt,0.8) `80分位值`,
              percentile_cont(user_pay_amt,0.9) `90分位值`,
              max(user_pay_amt) `最大值`
FROM t1
WHERE user_pay_amt>0
  AND user_pay_amt<=300
UNION ALL
SELECT '到手价' `类型`,
             count(DISTINCT user_id) `用户量`,
             count(auto_id) `订单量`,
             min(ds_amt) `最小值`,
             percentile_cont(ds_amt,0.1) `10分位值`,
             percentile_cont(ds_amt,0.2) `20分位值`,
             percentile_cont(ds_amt,0.3) `30分位值`,
             percentile_cont(ds_amt,0.4) `40分位值`,
             percentile_cont(ds_amt,0.5) `50分位值`,
             percentile_cont(ds_amt,0.6) `60分位值`,
             percentile_cont(ds_amt,0.7) `70分位值`,
             percentile_cont(ds_amt,0.8) `80分位值`,
             percentile_cont(ds_amt,0.9) `90分位值`,
             max(ds_amt) `最大值`
FROM t1
WHERE user_pay_amt>0
  AND user_pay_amt<=300
  AND ds_amt>=0;




================ 外卖取消订单时间分布(单位:秒)
-- 分布
SELECT if(order_status=4,'手动取消','超时取消') `取消类型`,
       count(DISTINCT user_id) `用户量`,
       count(auto_id) `订单量`,
       min(diff_snd) `最小值`,
       percentile_cont(diff_snd,0.1) `10分位值`,
       percentile_cont(diff_snd,0.2) `20分位值`,
       percentile_cont(diff_snd,0.3) `30分位值`,
       percentile_cont(diff_snd,0.4) `40分位值`,
       percentile_cont(diff_snd,0.5) `50分位值`,
       percentile_cont(diff_snd,0.6) `60分位值`,
       percentile_cont(diff_snd,0.7) `70分位值`,
       percentile_cont(diff_snd,0.8) `80分位值`,
       percentile_cont(diff_snd,0.9) `90分位值`,
       max(diff_snd) `最大值`
FROM
  (SELECT auto_id,
          user_id,
          order_time,
          order_status,
          cancel_time,
          date_diff('second',cancel_time,order_time) diff_snd
   FROM
     (SELECT auto_id,
             user_id,
             order_time,
             order_status,
             platform_order_detail,
             from_unixtime(get_json_string(platform_order_detail,'$.cancel_time'),'%Y-%m-%d %H:%i:%s') cancel_time
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-12-09' AND '2025-12-15'
        AND order_status IN (4,
                             5)) a) b
GROUP BY 1;



-- 20251217_10日至13日期间非第一条元宝oldpoint是0用户
SELECT DISTINCT silk_id
FROM
  ( SELECT silk_id,
           created_at,
           old_point,
           TYPE,
           row_number() over( partition BY silk_id
                             ORDER BY created_at ) AS rn
   FROM dwd.dwd_sr_user_point_history_partition_realtime
   WHERE date(created_at) BETWEEN '2025-12-10' AND '2025-12-13'
     AND old_point = 0
     AND TYPE = 1 ) a
WHERE rn <> 1;


SELECT statistics_date,
       business_name,
       coupon_type,
       coupon_id,
       coupon_name,
       sum(grant_num) grant_num,
       bitmap_union_count(grant_uids) grant_unum,
       sum(use_num) use_num,
       bitmap_union_count(use_uids) use_unum,
       sum(cost_num) cost_num,
       bitmap_union_count(cost_uids) cost_unum
FROM dws.dws_sr_marketing_cost_coupon_d
GROUP BY 1,
         2,
         3,
         4,
         5;



=========================
-- 券发放使用消耗
SELECT statistics_date,
       business_name,
       coupon_type,
       coupon_id,
       coupon_name,
       sum(grant_num) grant_num,
       bitmap_union_count(grant_uids) grant_unum,
       sum(used_num) use_num,
       bitmap_union_count(used_uids) use_unum,
       sum(cost_amt) cost_amt,
       bitmap_union_count(cost_uids) cost_unum
FROM dws.dws_sr_marketing_cost_coupon_d
GROUP BY 1,
         2,
         3,
         4,
         5;


-- 用户花费和收益
select
    statistics_date '统计日期',
    business_name '业务线',
    cost_typename '成本类型名称',
    count(distinct user_id) '用户量',
    sum(cost_amt) '花费',
    sum(valid_order_num) '有效订单量(外卖是有效订单,探店是完单,砍价是核销)',
    sum(valid_profit) '有效订单利润(外卖是已审核订单利润,探店是完单利润,砍价是核销利润)'
from dws.dws_sr_marketing_cost_user_d
group by 1,2,3;


=========================
-- 日活监测
-- 分端+全部
SELECT date(time) `统计日期`,
       CASE
           WHEN platform_type regexp '5' THEN 'H5'
           WHEN platform_type IN ('小程序',
                                  '微信小程序') THEN '微信小程序'
           WHEN platform_type IN ('到店小程序',
                                  '到店微信小程序') THEN '到店微信小程序'
           WHEN platform_type ='探店小程序' THEN '探店微信小程序'
           WHEN platform_type='Android' THEN 'Android'
           WHEN platform_type='iOS' THEN 'iOS'
           WHEN platform_type='Harmony' THEN 'Harmony'
           ELSE '其他'
       END `平台名称`,
       count(1) `数据量`,
       count(DISTINCT user_id) `用户量`,
       count(DISTINCT if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,NULL)) `登录用户量`
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time) BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
GROUP BY 1,
         2
UNION ALL
SELECT date(time) `统计日期`,
       '全部' `平台名称`,
                count(1) `数据量`,
                count(DISTINCT user_id) `用户量`,
                count(DISTINCT if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,NULL)) `登录用户量`
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time) BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
GROUP BY 1,
         2



风控用户列表：不满意订单、直营拉黑。点击用户后跳转到用户明细。




SELECT date(order_time) order_date,
       count(1) `总报名订单量`,
       count(DISTINCT user_id) `总报名用户量`,
       sum(if(store_promotion_id<>0,1,0)) `自营报名订单量`,
       count(DISTINCT if(store_promotion_id<>0,user_id,NULL)) `自营报名用户量`,
       sum(if(store_promotion_id<>0
              AND order_status IN (2,8),1,0)) `自营有效订单量`,
       count(DISTINCT if(store_promotion_id<>0
                         AND order_status IN (2,8),user_id,NULL)) `自营报名用户量`,
       sum(if(store_promotion_id<>0
              AND order_type=12,1,0)) `美团专版报名订单量`,
       count(DISTINCT if(store_promotion_id<>0
                         AND order_type=12,user_id,NULL)) `美团专版报名用户量`,
       sum(if(store_promotion_id<>0
              AND order_status IN (2,8)
              AND order_type=12,1,0)) `美团专版有效订单量`,
       count(DISTINCT if(store_promotion_id<>0
                         AND order_status IN (2,8)
                         AND order_type=12,user_id,NULL)) `美团专有效名用户量`
FROM dwd.dwd_sr_order_promotion_order a
LEFT JOIN dim.dim_silkworm_date b ON date(a.order_time)=b.current_date_txt
WHERE a.dt BETWEEN '2025-11-01' AND '2025-12-22'
GROUP BY 1;



============== 到店每日有效拉新
-- hongxiu
SELECT dt,
       count(DISTINCT user_id) uv
FROM
  (SELECT dt,
          user_id,
          inviter_user_id,
          ROW_NUMBER()over(partition BY user_id
                           ORDER BY dt)rk
   FROM
     (SELECT dt,
             user_id,
             inviter_user_id,
             sum(reward_amt) cost_amt
      FROM dwd.dwd_sr_silkworm_explore_reward_record
      WHERE inviter_user_id <> 0
        AND reward_type IN (3,
                            5)
      GROUP BY 1,
               2,
               3 HAVING sum(reward_amt) > 0) t) a
WHERE rk=1
GROUP BY 1



-- ziren
WITH t1 AS
  (SELECT user_id,
          inviter_user_id
   FROM dim.dim_silkworm_user
   WHERE inviter_user_id > 0
   GROUP BY 1,
            2),

 fon AS
  (SELECT user_id,
          first_bargain_order_date
   FROM dim.dim_silkworm_explore_daren_cleanse
   WHERE first_bargain_order_date IS NOT NULL)


SELECT fon.first_bargain_order_date,
       -- count(DISTINCT fon.user_id) AS valid_bargain_member_user_cnt
       fon.user_id
FROM t1
JOIN fon ON fon.user_id = t1.user_id
-- GROUP BY 1
where fon.first_bargain_order_date='2025-12-22'







================== 注册用户量
with t1 as (SELECT create_date,
          if(stage=2,user_id,NULL) AS user_id,
          platform_type,
          platform,
          channel,
          min(create_time) AS create_time,
          min(stage) AS stage -- 如果同一天由新用户转为老用户，则算作当天新用户
 from
     ( SELECT if(platform=100,date(created_at),date(updated_at)) AS create_date, 
              silk_id AS user_id, 
              platform AS platform_type, 
              step AS stage, 
              CASE WHEN platform=1 THEN 'vivo' 
                WHEN platform=10 THEN '小米' 
                WHEN platform=20 THEN '苹果' 
                WHEN platform=30 THEN 'oppo' 
                WHEN platform=40 THEN '荣耀' 
                WHEN platform=50 THEN '华为' 
                WHEN platform=60 THEN '应用宝' 
                WHEN platform=61 THEN '广点通' 
                WHEN platform=2 THEN 'vivo_点触传媒' 
                WHEN platform=70 THEN '美数召回' 
                WHEN platform=80 THEN '抖音' 
                WHEN platform=90 THEN '快手' 
                WHEN platform=100 THEN '百度搜索' 
                WHEN platform=110 THEN '流量助推' 
                WHEN platform=120 THEN 'soul' 
                WHEN platform=130 THEN '小红书' 
                ELSE '其他' 
            END AS platform, 
            if(length(channel)>0,channel,0) AS channel, 
            updated_at AS create_time
      FROM ods.ods_sr_user_monitor_record_realtime
      WHERE NOT (date(created_at) IN ('2025-09-01', '2025-09-02', '2025-09-03', '2025-09-04', '2025-09-05', '2025-09-06', '2025-09-07', '2025-09-08', '2025-09-09', '2025-09-10')
                 AND platform=70 )
      UNION ALL SELECT date(created_at) AS create_date,
                       silk_id, 
                       platform AS platform_type, 
                       99 AS stage, 
                       CASE WHEN platform=70 THEN '美数召回' ELSE '其他' END AS platform,
                       0 AS channel, 
                       min(created_at) AS created_at -- 每个用户每天去重
      FROM ods.ods_sr_user_launch_record_realtime
      WHERE silk_id>0
      GROUP BY 1,2,3,4,5,6) a
   GROUP BY 1,
            2,
            3,
            4,
            5)

SELECT date(register_time) register_date,
       count(DISTINCT a.user_id) `注册用户量`,
       count(DISTINCT if(inviter_user_id<>0,a.user_id,NULL)) `团长拉新用户量`,
       count(DISTINCT if(t1.user_id IS NOT NULL,a.user_id,NULL)) `渠道拉新用户量`
FROM dim.dim_silkworm_user a
LEFT JOIN t1 ON a.user_id=t1.user_id
WHERE date(register_time) BETWEEN '2024-01-01' AND '2025-12-22'
GROUP BY 1;


SELECT create_date,
       platform,
       count(DISTINCT user_id) unum
FROM t1 grop BY 1,
                2;


======== 首页feed转化
select 
      statistics_date,
      ifnull(b.city_name,'其他') '城市',
      ifnull(b.county_name,'其他') '区县',
      platform_name '平台名称',
      app_version '版本',
      sum(expouse_num) '曝光量',
      bitmap_union_count(expouse_uids) '曝光用户量',
      sum(clc_num) '点击量',
      bitmap_union_count(clc_uids) '点击用户量',
      sum(detailpage_pv) '详情页PV',
      bitmap_union_count(detailpage_view_uids) '详情页UV',
      sum(baoming_order_num) '报名订单量',
      bitmap_union_count(baoming_uids) '报名用户量',
      sum(valid_order_num) '有效订单量',
      bitmap_union_count(valid_uids) '有效用户量',
      sum(xx_baoming_order_num) '晓晓报名订单量',
      bitmap_union_count(xx_baoming_uids) '晓晓报名用户量',
      sum(xx_valid_order_num) '晓晓有效订单量',
      bitmap_union_count(xx_valid_uids) '晓晓有效用户量'
from (select statistics_date,
  ifnull(b.city_name,'其他') city_name,
      ifnull(b.county_name,'其他') county_name,
      platform_name,
      app_version,
      activity_type,
      promotion_id,
      expouse_num,
      expouse_uids,
      clc_num,
      clc_uids,
      detailpage_pv,
      detailpage_view_uids,
      baoming_order_num,
      baoming_uids,
      valid_order_num,
      valid_uids,
      xx_baoming_order_num,
      xx_baoming_uids,
      xx_valid_order_num,
      xx_valid_uids
 from dws.dws_sr_traffic_homepage_mix_ascribe_d a
left join dim.dim_silkworm_county b on a.county_id=b.county_id
where a.statistics_date between '${begin_date}' and '${end_date}'
) tot
where 1=1 
<parameter> and city_name in ('${city_name}') </parameter>
<parameter> and county_name in ('${county_name}') </parameter>
<parameter> and platform_name in ('${platform_name}') </parameter>
<parameter> and app_version in ('${app_version}') </parameter>
group by 1,2,3,4,5



SELECT * FROM demo_contract WHERE 1=1 <parameter> and "合同类型" in ('${文本参数}') </parameter>


======================
-- 昨日在线店铺
WITH t1 AS
  (SELECT store_id
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt='2025-12-23'
   GROUP BY 1)


SELECT count(DISTINCT a.store_id) `昨日在线店铺数`,
       count(DISTINCT if(a.store_brand_type=1,a.store_id,NULL)) `昨日在线品牌店铺数`,
       bitmap_union_count(if(a.dt='2025-12-23',valid_uids,NULL)) `昨日在线店铺完单用户量`,
       bitmap_union_count(if(a.dt='2025-12-23'
                             AND a.store_brand_type=1,valid_uids,NULL)) `昨日在线品牌店铺完单用户量`,
       bitmap_union_count(if(a.dt BETWEEN date_sub('2025-12-23',interval 30 DAY) AND '2025-12-23',valid_uids,NULL)) `昨日在线店铺近30天完单用户量`,
       bitmap_union_count(if(a.dt BETWEEN date_sub('2025-12-23',interval 30 DAY) AND '2025-12-23'
                             AND a.store_brand_type=1,valid_uids,NULL)) `昨日在线品牌店铺近30天完单用户量`,
       bitmap_union_count(if(a.dt BETWEEN date_sub('2025-12-23',interval 90 DAY) AND '2025-12-23',valid_uids,NULL)) `昨日在线店铺近90天完单用户量`,
       bitmap_union_count(if(a.dt BETWEEN date_sub('2025-12-23',interval 90 DAY) AND '2025-12-23'
                             AND a.store_brand_type=1,valid_uids,NULL)) `昨日在线品牌店铺近90天完单用户量`,
       bitmap_union_count(valid_uids) `昨日在线店铺近180天完单用户量`,
       bitmap_union_count(if(a.store_brand_type=1,valid_uids,NULL)) `昨日在线品牌店铺近180天完单用户量`
FROM
  (SELECT dt,
          store_id,
          store_brand_type,
          valid_uids
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt BETWEEN date_sub('2025-12-23',interval 180 DAY) AND '2025-12-23') a
INNER JOIN t1 ON t1.store_id=a.store_id ;


=============
-- 外卖到手价分布
SELECT count(DISTINCT user_id) `用户量`, -- 2,886,216
       count(1) `有效订单量`, -- 57,998,287
       -- min(ds_amt) `最小实付金额`, -- -8028.3
       percentile_cont(ds_amt,0.1) `10分位实付金额`, -- 4
       percentile_cont(ds_amt,0.2) `20分位实付金额`, -- 5.8
       percentile_cont(ds_amt,0.3) `30分位实付金额`, -- 7.2
       percentile_cont(ds_amt,0.4) `40分位实付金额`, -- 8.58
       percentile_cont(ds_amt,0.5) `中位数实付金额`, -- 9.88
       percentile_cont(ds_amt,0.6) `60分位实付金额`, -- 10.89
       percentile_cont(ds_amt,0.7) `70分位实付金额`, -- 12.44
       percentile_cont(ds_amt,0.8) `80分位实付金额`, -- 14.3
       percentile_cont(ds_amt,0.9) `90分位实付金额`, -- 17.29
       max(ds_amt) `最大实付金额` -- 297
FROM
  (SELECT user_id,
          user_pay_amt,
          real_rebate_amt,
          user_pay_amt-real_rebate_amt ds_amt
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('2025-12-23',interval 90 DAY) AND '2025-12-23'
     AND order_status IN (2,
                          8)
     AND user_pay_amt<=300) a ;


-- 近30天用户完单利润分布
SELECT count(DISTINCT user_id) `用户量`, -- 2,050,137
       min(profit) `最小利润`, -- 0
       percentile_cont(profit,0.1) `10分位利润`, -- 3
       percentile_cont(profit,0.2) `20分位利润`, -- 3
       percentile_cont(profit,0.3) `30分位利润`, -- 6
       percentile_cont(profit,0.4) `40分位利润`, -- 9
       percentile_cont(profit,0.5) `中位数利润`, -- 13.12
       percentile_cont(profit,0.6) `60分位利润`, -- 19.73
       percentile_cont(profit,0.7) `70分位利润`, -- 29
       percentile_cont(profit,0.8) `80分位利润`, -- 43.3
       percentile_cont(profit,0.9) `90分位利润`, -- 69
       max(profit) `最大利润` -- 1996.23
FROM
  (SELECT user_id,
          sum(profit) profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('2025-12-23',interval 30 DAY) AND '2025-12-23'
     AND order_status=2
   GROUP BY 1) a
;




dim_silkworm_staff_depart小蚕员工部门
dws_sr_silkworm_instore_bargain_operation_ba_dashboard砍价运营漏斗分析看板


DAU在9点到10点之间下降原因


-- 分端DAU
SELECT 
    CONCAT(DATE_FORMAT(time, '%Y-%m-%d %H:'), FLOOR(MINUTE(time)/10)*10, ':00') AS statistics_time_period,
     CASE
     WHEN platform_type regexp '5' THEN 'H5'
     WHEN platform_type IN ('小程序',
                             '微信小程序') THEN '微信小程序'
     WHEN platform_type IN ('到店小程序',
                             '到店微信小程序') THEN '到店微信小程序'
     WHEN platform_type ='探店小程序' THEN '探店微信小程序'
     WHEN platform_type IN ('Android',
                            'Harmony') THEN 'Android'
     WHEN platform_type='iOS' THEN 'iOS'
     ELSE '未知'
 END platform_name,
    count(distinct distinct_id) uv
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time) between '2025-12-17' and '2025-12-19'
    and hour(time)=9
  AND distinct_id regexp '^[0-9]{1,10}$'
GROUP BY 1,2;




============= 晓晓订单
SELECT dt,
       count(1) tot,
       count(DISTINCT user_id) unum,
       count(if(order_status IN (2,8),auto_id,NULL)) xx_num,
       count(DISTINCT if(order_status IN (2,8),user_id,NULL)) xx_unum
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-12-25' AND '2025-12-29'
  AND order_type=15
GROUP BY 1;



============= 指定知识点下用户
SELECT knowledge_id,
       count(DISTINCT a.silk_id) `总用户量`,
       count(DISTINCT if(b.tot_score>=85,a.silk_id,NULL)) `诚信分>=85总用户量`,
       count(DISTINCT if(b.order_score>=25,a.silk_id,NULL)) `下单行为分>=25总用户量`,
       count(DISTINCT if(b.order_score=30,a.silk_id,NULL)) `下单行为分=30总用户量`,
       count(DISTINCT if(a.turn_human=1,a.silk_id,NULL)) `转人工用户量`,
       count(DISTINCT if(a.turn_human=1
                         AND b.tot_score>=85,a.silk_id,NULL)) `转人工且诚信分>=85用户量`,
       count(DISTINCT if(a.turn_human=1
                         AND b.order_score>=25,a.silk_id,NULL)) `转人工且下单行为分>=25用户量`,
       count(DISTINCT if(a.turn_human=1
                         AND b.order_score=30,a.silk_id,NULL)) `转人工且下单行为分=30用户量`,
       count(DISTINCT if(b.sham_rebate_score>=25,a.silk_id,NULL)) `风险订单行为分>=25总用户量`,
       count(DISTINCT if(b.sham_rebate_score=30,a.silk_id,NULL)) `风险订单行为分=30总用户量`,
       count(DISTINCT if(a.turn_human=1
                         AND b.sham_rebate_score>=25,a.silk_id,NULL)) `转人工且风险订单行为分>=25用户量`,
       count(DISTINCT if(a.turn_human=1
                         AND b.sham_rebate_score=30,a.silk_id,NULL)) `转人工且风险订单行为分=30用户量`,
       count(DISTINCT if(b.sham_order_num=0,a.silk_id,NULL)) `虚假订单=0总用户量`,
       count(DISTINCT if(a.turn_human=1
                         AND b.sham_order_num=0,a.silk_id,NULL)) `转人工且虚假订单=0用户量`
FROM
  (SELECT knowledge_id,
          silk_id,
          turn_human
   FROM dwd.dwd_sr_knowledge_session
   WHERE dt BETWEEN '2025-12-26' AND '2025-12-28'
     AND knowledge_id IN (278,
                          269,
                          262,
                          251,
                          249,
                          238,
                          210,
                          208,
                          199,
                          197,
                          195,
                          181,
                          179,
                          175,
                          168,
                          162,
                          358,
                          356,
                          427,
                          426,
                          425)
   GROUP BY 1,
            2,
            3) a
LEFT JOIN dim.dim_silkworm_user_intsr b ON a.silk_id=b.user_id
GROUP BY 1;



======================= 每日卡券/红包发放、使用、消耗
-- 整体消耗
select
-- statistics_date
business_name,
cost_typename,
sum(cost_amt) cost_amt
from ads.ads_sr_marketing_cost_d
where statistics_date between '2025-12-01' and '2025-12-28'
group by 1,2;


-- 卡券和红包类型消耗
SELECT -- statistics_date,
business_name,
if(coupon_type=1,'卡券','红包') `类别1`,
CASE
    WHEN sub_coupon_type=0 THEN '未知'
    WHEN sub_coupon_type=1 THEN '后台红包'
    WHEN sub_coupon_type=2 THEN '拼手气红包'
    WHEN sub_coupon_type=3 THEN '红包雨抽奖'
    WHEN sub_coupon_type=4 THEN '积分兑换'
    WHEN sub_coupon_type=5 THEN '用户召回活动'
    WHEN sub_coupon_type=6 THEN '会员限时升级礼包'
    WHEN sub_coupon_type=7 THEN '会员每日红包活动'
    WHEN sub_coupon_type=8 THEN '挑战赛'
    WHEN sub_coupon_type=9 THEN '抽奖活动'
    WHEN sub_coupon_type=10 THEN '春节签到领红包(已下线)'
    WHEN sub_coupon_type=11 THEN '趣淘用户注册领取红包'
    WHEN sub_coupon_type=12 THEN '嗨皮用户注册领取红包'
    WHEN sub_coupon_type=13 THEN '新用户下单奖励红包'
    WHEN sub_coupon_type=14 THEN '社群晒图'
    WHEN sub_coupon_type=15 THEN '团长包红包'
    WHEN sub_coupon_type=16 THEN '工单发放红包'
    WHEN sub_coupon_type=17 THEN '探店单单反发放红包'
    WHEN sub_coupon_type=18 THEN 'ma发放红包'
    WHEN sub_coupon_type=20 THEN '周年庆每日领红包'
    WHEN sub_coupon_type=21 THEN '周年庆猜一猜'
    WHEN sub_coupon_type=22 THEN '到店社群新人红包'
    WHEN sub_coupon_type=23 THEN '地推活动新人红包'
    WHEN sub_coupon_type=24 THEN '观看广告得红包雨抽奖'
    WHEN sub_coupon_type=25 THEN '探店抽奖'
    WHEN sub_coupon_type=26 THEN '砍价抽奖'
    WHEN sub_coupon_type=27 THEN '会员天天签到抽奖'
    WHEN sub_coupon_type=28 THEN '免单卡红包'
    WHEN sub_coupon_type=29 THEN '二楼红包'
    WHEN sub_coupon_type=30 THEN '积分抽奖'
    WHEN sub_coupon_type=31 THEN '探店营销'
    ELSE '未知'
END AS `类别2`,
CASE
    WHEN business_name='外卖'
         AND sub_coupon_type=18
         AND coupon_name NOT IN ('新人狂欢首单奖励',
                                    '新人首单狂欢奖励',
                                    '新人狂欢第3单奖励') THEN '外卖MA红包'
    WHEN business_name='砍价'
         AND sub_coupon_type=18 THEN '砍价MA红包'
    WHEN business_name='探店'
         AND sub_coupon_type=18
         AND coupon_name NOT IN ('到店新人免单补贴红包',
                                    '到店新人完成3单奖励') THEN '探店MA红包'
    WHEN coupon_name IN ('新人狂欢首单奖励',
                            '新人首单狂欢奖励') THEN '新用户下单奖励红包'
    WHEN coupon_name='新人狂欢第3单奖励' THEN '新人狂欢第3单奖励'
    WHEN coupon_name='到店新人免单补贴红包' THEN '到店新人免单补贴红包'
    WHEN coupon_name='到店新人完成3单奖励' THEN '到店新人完成3单奖励'
    WHEN sub_coupon_type=3 THEN '红包雨'
    WHEN sub_coupon_type=9 THEN '抽奖活动'
    WHEN sub_coupon_type=15
         AND coupon_id<>232 THEN '团长包红包'
    WHEN sub_coupon_type=22  OR coupon_name in ('社群拉新红包','社群福利红包','探店优秀笔记奖励','社群会员红包','社群活动红包') THEN '社群红包'
    WHEN sub_coupon_type=8 and coupon_name in ('社群专享红包','社群专享口令红包') THEN '社群晒图'    
    WHEN coupon_name in ('平台砍价红包','平台到店红包','平台红包') THEN '客服补偿红包'
    WHEN coupon_name in ('砍价补偿红包','探店补偿红包','砍价无门槛红包','探店无门槛红包') THEN '商家不合作订单取消补偿红包'
    WHEN coupon_name in ('到店会员日红包','社群会员日红包') THEN '商家不合作订单取消补偿红包'
    WHEN sub_coupon_type=31 THEN '探店营销'
    WHEN sub_coupon_type=24 AND coupon_name in ('小蚕外卖红包') THEN '红包雨'
    WHEN sub_coupon_type=27 THEN '会员天天签到抽奖'
    WHEN sub_coupon_type=6 THEN '会员限时升级礼包'
    WHEN sub_coupon_type=4 THEN '积分兑换'
    WHEN sub_coupon_type=28 THEN '免单卡红包'
    WHEN sub_coupon_type=14 THEN '社群晒图'

    ELSE coupon_name
END rdp_typename,
coupon_name,
coupon_desc,
sum(cost_amt) cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistics_date BETWEEN '2025-12-01' AND '2025-12-28'
GROUP BY 1,
         2,
         3,
         4,
         5;


-- 正式取数
-- 非红包和卡券支出
SELECT statistics_date,
       business_name,
       cost_typename,
       sum(cost_amt) cost_amt
FROM ads.ads_sr_marketing_cost_d
WHERE statistics_date BETWEEN '2025-12-01' AND '2025-12-28'
  AND cost_typename IN ('团长拉新奖励',
                        '新人首单红包',
                        '渠道拉新',
                        '新人3单红包',
                        '下单挑战赛',
                        '邀请挑战赛',
                        '用户补偿蚕豆',
                        '达人团长拉新')
GROUP BY 1,
         2,
         3
UNION ALL 
-- 卡券
SELECT statistics_date,
       business_name,
       CASE
           WHEN coupon_name regexp '大牌'
                OR coupon_name IN ('库迪3选1',
                                   '瑞幸3选1',
                                   '沪上3选1')
                OR coupon_desc regexp '大牌活动'
                OR coupon_name ='社群奶茶福利券' THEN '大牌券'
           WHEN coupon_name regexp '复活券' THEN '复活券'
           WHEN coupon_name regexp '返利券' THEN '返利券'
           WHEN coupon_name regexp '免审券' THEN '免审券'
           WHEN coupon_name regexp '免单券' THEN '免单券'
           ELSE '其他'
       END AS cost_typename,
       sum(cost_amt) cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistic_date BETWEEN '2025-12-01' AND '2025-12-28'
  AND (coupon_name NOT regexp '测试'
       OR coupon_desc NOT regexp '测试')
  AND coupon_type=1
GROUP BY 1,
         2,
         3
UNION ALL
-- 红包
SELECT statistics_date,
       business_name,
       CASE
           WHEN business_name='外卖'
                AND sub_coupon_type=18
                AND coupon_name NOT IN ('新人狂欢首单奖励',
                                        '新人首单狂欢奖励',
                                        '新人狂欢第3单奖励') THEN '外卖MA红包'
           WHEN business_name='砍价'
                AND sub_coupon_type=18 THEN '砍价MA红包'
           WHEN business_name='探店'
                AND sub_coupon_type=18
                AND coupon_name NOT IN ('到店新人免单补贴红包',
                                        '到店新人完成3单奖励') THEN '探店MA红包'
           WHEN coupon_name IN ('新人狂欢首单奖励',
                                '新人首单狂欢奖励') THEN '新用户下单奖励红包'
           WHEN coupon_name='新人狂欢第3单奖励' THEN '新人狂欢第3单奖励'
           WHEN coupon_name='到店新人免单补贴红包' THEN '到店新人免单补贴红包'
           WHEN coupon_name='到店新人完成3单奖励' THEN '到店新人完成3单奖励'
           WHEN sub_coupon_type=3 THEN '红包雨'
           WHEN sub_coupon_type=9 THEN '抽奖活动'
           WHEN sub_coupon_type=15
                AND coupon_id<>232 THEN '团长包红包'
           WHEN sub_coupon_type=22
                OR coupon_name IN ('社群拉新红包',
                                   '社群福利红包',
                                   '探店优秀笔记奖励',
                                   '社群会员红包',
                                   '社群活动红包') THEN '社群红包'
           WHEN sub_coupon_type=8
                AND coupon_name IN ('社群专享红包',
                                    '社群专享口令红包') THEN '社群晒图'
           WHEN coupon_name IN ('平台砍价红包',
                                '平台到店红包',
                                '平台红包') THEN '客服补偿红包'
           WHEN coupon_name IN ('砍价补偿红包',
                                '探店补偿红包',
                                '砍价无门槛红包',
                                '探店无门槛红包') THEN '商家不合作订单取消补偿红包'
           WHEN coupon_name IN ('到店会员日红包',
                                '社群会员日红包') THEN '商家不合作订单取消补偿红包'
           WHEN sub_coupon_type=31 THEN '探店营销'
           WHEN sub_coupon_type=24
                AND coupon_name IN ('小蚕外卖红包') THEN '红包雨'
           WHEN sub_coupon_type=27 THEN '会员天天签到抽奖'
           WHEN sub_coupon_type=6 THEN '会员限时升级礼包'
           WHEN sub_coupon_type=4 THEN '积分兑换'
           WHEN sub_coupon_type=28 THEN '免单卡红包'
           WHEN sub_coupon_type=14 THEN '社群晒图'
           WHEN sub_coupon_type=16 THEN '工单发放红包'
           WHEN coupon_name='美食侦探奖励红包' THEN '美食侦探奖励红包'
           ELSE coupon_name
       END cost_typename,
       sum(cost_amt) cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistics_date BETWEEN '2025-12-01' AND '2025-12-28'
  AND coupon_type=2
GROUP BY 1,
         2,
         3;




========== 拉黑用户
left(latest_block_time,10)<>'1970-01-01'
    and (left(block_release_time,10)='1970-01-01' or left(block_release_time,10) < left(latest_block_time,10))
and status = 1 -- 封号状态
from dim.dim_silkworm_user



=================================================================================
SELECT a.`统计日期`,
       `活动名额`,
       `总报名用户量`,
       `总有效用户量`,
       `总报名量`,
       `总有效订单量`,
       `总有效订单利润`,
       `自营报名用户量`,
       `自营有效用户量`,
       `自营报名量`,
       `自营有效订单量`,
       `自营有效订单利润`
FROM (
-- 订单
SELECT date_format(order_time,'%Y-%m') `统计日期`,
       count(DISTINCT user_id) `总报名用户量`,
       count(DISTINCT if(order_status IN (2,8),user_id,NULL)) `总有效用户量`,
       count(1) `总报名量`,
       sum(if(order_status IN (2,8),1,0)) `总有效订单量`,
       sum(if(order_status = 2,profit,0)) `总有效订单利润`,
       count(DISTINCT if(store_promotion_id<>0,user_id,NULL)) `自营报名用户量`,
       count(DISTINCT if(store_promotion_id<>0
                         AND order_status IN (2,8),user_id,NULL)) `自营有效用户量`,
       sum(if(store_promotion_id<>0,1,0)) `自营报名量`,
       sum(if(store_promotion_id<>0
              AND order_status IN (2,8),1,0)) `自营有效订单量`,
       sum(if(store_promotion_id<>0
              AND order_status = 2,profit,0)) `自营有效订单利润`
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2021-01-01' AND '2025-12-31'
GROUP BY 1) a
left join
-- 活动名额
(SELECT date_format(begin_date,'%Y-%m') `统计日期`,
       sum(ifnull(meituan_promotion_quota,0))+sum(ifnull(eleme_promotion_quota,0))+sum(ifnull(jd_promotion_quota,0)) AS `活动名额`
FROM dwd.dwd_sr_store_promotion
WHERE dt BETWEEN '2021-01-01' AND '2025-12-31'
  AND status IN (1,
                 4,
                 5)
GROUP BY 1) b ON a.`统计日期`=b.`统计日期`;




=================================================================================

-- 25年12月上传订单截图有效订单量：12,930,585，上传截图订单量：12,997,218
SELECT count(1) order_num
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-12-01' AND '2025-12-31' -- and     order_status in (2,8)
AND platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/';



-- 各个用户12月超3单上传截图有效订单量：11,265,817，上传截图订单量：11,318,815
SELECT count(DISTINCT if(platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/',auto_id,NULL)) order_num,
       count(DISTINCT if(platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
                         AND order_status IN (2,8),auto_id,NULL)) valid_order_num
FROM
  (SELECT auto_id,
          order_time,
          user_id,
          order_status,
          platform_evaluation_order_screenshot_url,
          row_number() over(partition BY user_id order by order_time) rk
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31') a
WHERE rk>=3;


-- 各个用户12月超3单上传截图且未进入人审有效订单量：10,087,309，上传截图且未进入人审订单量：10,111,967
SELECT count(DISTINCT if(platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
                         AND c.order_id IS NULL,auto_id,NULL)) order_num,
       count(DISTINCT if(platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
                         AND order_status IN (2,8)
                         AND c.order_id IS NULL,auto_id,NULL)) valid_order_num
FROM
  (SELECT auto_id,
          order_time,
          order_id,
          user_id,
          order_status,
          platform_evaluation_order_screenshot_url
   FROM
     (SELECT auto_id,
             order_time,
             order_id,
             user_id,
             order_status,
             platform_evaluation_order_screenshot_url,
             row_number() over(partition BY user_id
                               ORDER BY order_time) rk
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-12-01' AND '2025-12-31') a
   WHERE rk>3) b
LEFT JOIN
  (SELECT order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2025-12-01' AND '2026-01-07'
   GROUP BY 1) c ON b.order_id=c.order_id ;


1）25年12月上传订单截图有效订单量：12,930,585，上传截图订单量：12,997,218。
2）各用户12月超3单上传截图有效订单量：11,265,817，上传截图订单量：11,318,815。
3）各用户12月超3单上传截图且未进入人审有效订单量：10,087,309，上传截图且未进入人审订单量：10,111,967。


-- 近10天下单中，下单前7天超5、4、3单是截图上传
WITH t1 AS
  (SELECT auto_id
   FROM
     (SELECT auto_id,
             order_time,
             order_id,
             user_id,
             order_status,
             row_number() over(partition BY user_id
                               ORDER BY order_time) rk
      FROM
        (SELECT auto_id,
                order_time,
                order_id,
                user_id,
                order_status
         FROM
           (SELECT auto_id,
                   a.order_time,
                   order_id,
                   a.user_id,
                   order_status,
                   platform_evaluation_order_screenshot_url,
                   date_diff('day',b.order_time,a.order_time) diff_days
            FROM
              (SELECT auto_id,
                      order_time,
                      order_id,
                      user_id,
                      order_status,
                      platform_evaluation_order_screenshot_url
               FROM dwd.dwd_sr_order_promotion_order
               WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
                 AND platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
                 AND real_rebate_amt>15) a
            LEFT JOIN
              (SELECT user_id,
                      order_time
               FROM dwd.dwd_sr_order_promotion_order
               WHERE dt BETWEEN '2025-11-01' AND '2025-12-30') b ON a.user_id=b.user_id
            AND date_diff('day',b.order_time,a.order_time) BETWEEN 1 AND 7 -- WHERE a.user_id=841625717 -- 验证
 ) c
         WHERE diff_days IS NOT NULL
         GROUP BY 1,
                  2,
                  3,
                  4,
                  5) toa ) tob
   WHERE rk>=5
   GROUP BY 1)

-- 本期需要进入P图检测订单量
SELECT count(DISTINCT if(t1.auto_id is null,a.auto_id,null)) AS order_num,
       count(DISTINCT if(t1.auto_id is null AND a.order_status IN (2,8),a.auto_id,null)) valid_order_num
FROM
  (SELECT auto_id,
          order_time,
          order_id,
          user_id,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
     AND platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
     AND real_rebate_amt>15) a
left JOIN t1 ON a.auto_id=t1.auto_id;



-- 本期未入人审进入P图检测订单量
SELECT count(DISTINCT if(t1.auto_id is null and c.order_id IS NULL,a.auto_id,NULL)) order_num,
       count(DISTINCT if(t1.auto_id is null and order_status IN (2,8)
                         AND c.order_id IS NULL,a.auto_id,NULL)) valid_order_num
FROM
  (SELECT auto_id,
          order_time,
          order_id,
          user_id,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
     AND platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
     AND real_rebate_amt>15) a
LEFT JOIN t1 ON a.auto_id=t1.auto_id
LEFT JOIN
  (SELECT order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2025-12-01' AND '2026-01-11'
   GROUP BY 1) c ON a.order_id=c.order_id;

-- 返利>30截图检测
SELECT count(1) tot
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
  AND platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
  AND real_rebate_amt>30;


-- 返利>30截图检测未进人审
SELECT count(DISTINCT if(c.order_id IS NULL,a.auto_id,NULL)) order_num,
       count(DISTINCT if(order_status IN (2,8)
                         AND c.order_id IS NULL,a.auto_id,NULL)) valid_order_num
FROM
  (SELECT auto_id,
    
          order_id,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
     AND platform_evaluation_order_screenshot_url regexp 'https://web.xinyifm.cn/oss/xc-app/'
     AND real_rebate_amt>30) a
LEFT JOIN
  (SELECT order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN '2025-12-01' AND '2026-01-11'
   GROUP BY 1) c ON a.order_id=c.order_id;


-- 每天下单>4
SELECT count(auto_id) cnt,
       count(if(order_status IN (2,8),auto_id,NULL)) valid_num
FROM
  (SELECT dt,
          auto_id,
          order_time,
          user_id,
          order_status,
          row_number() over(partition BY dt,user_id
                            ORDER BY order_time) rk
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31') a
WHERE rk>4 ;

================
目的：
1）2026年销单率目标评定参考（核心目的），销单率有哪些点可以提升，空间有多大；
2）搜推能够落地执行的方向评估。

期望：
尤其要分城市去看，后续搜推估计也要分城市做不同策略
1）分两个角度看，用户来了没下单用户，为什么没下单，怎么促进更多用户下单
2）单没销出去，是什么原因，系统、用户、活动等等，下钻


-- 报名用户量
SELECT date(order_time) AS order_date,
       count(DISTINCT user_id) ord_unum
FROM dwd.dwd_sr_order_promotion_order
WHERE date(order_time) BETWEEN '2025-12-01' AND '2025-12-31'
GROUP BY 1;

#########################
-- 访问未下单用户统计
-- 有些报名用户不在访问用户中 不用此逻辑
SELECT a.dt,
       count(DISTINCT a.user_id) dau,
       count(DISTINCT if(b.user_id IS NOT NULL,a.user_id,NULL)) nord_user_num
FROM
  (SELECT dt,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31'
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT date(order_time) AS order_date,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date(order_time) BETWEEN '2025-12-01' AND '2025-12-31'
   GROUP BY 1,
            2) b ON a.dt=b.order_date
AND a.user_id=b.user_id
GROUP BY 1;


-- 使用这个逻辑
SELECT a.dt,
       a.dau,
       b.ord_unum,
       a.dau-b.ord_unum nord_user_num
FROM
  (SELECT dt,
          bitmap_union_count(user_ids) dau
   FROM dwd.dwd_sr_traffic_viewuser_d
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31'
   GROUP BY 1) a
LEFT JOIN
  (SELECT date(order_time) AS order_date,
          count(DISTINCT user_id) ord_unum
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date(order_time) BETWEEN '2025-12-01' AND '2025-12-31'
   GROUP BY 1) b ON a.dt=b.order_date ;



-- -- 仅访问首页用户
-- -- 每日访问事件
-- WITH t1 AS
--   (SELECT dt,
--           lower(event_ename) event_name,
--                              unnest_bitmap AS user_id
--    FROM dwd.dwd_sr_traffic_viewuser_d,
--         unnest_bitmap(user_ids) AS uid
--    WHERE dt BETWEEN '2025-12-25' AND '2025-12-31'
--    GROUP BY 1,
--             2,
--             3),


-- 仅触达一个事件用户
-- t2 AS
--   (
--     SELECT  dt,
--           user_id,
--           count(DISTINCT event_name) cnt
--    FROM t1
--    GROUP BY 1,
--             2
--             HAVING count(DISTINCT event_name)=1)
            
-- -- 仅一个事件用户日均2100人左右 不使用本逻辑 改用用户无takeaway_detailpage_view事件
-- SELECT dt,
--         count(1) tot
--    FROM t2
-- group by 1;


-- SELECT dt,
--        count(a.user_id) one_dau,
--        count(DISTINCT if(b.user_id IS NOT NULL,a.user_id,NULL)) view_order_unum
-- FROM
--   (SELECT t2.dt,
--           t2.user_id
--    FROM t2
--    INNER JOIN t1 ON t2.dt=t1.dt
--    AND t2.user_id=t1.user_id
--    AND t1.event_name='homepage_view') a
-- LEFT JOIN
--   (SELECT date(order_time) order_date,
--           user_id
--    FROM dwd.dwd_sr_order_promotion_order
--    WHERE date(order_time) BETWEEN '2025-12-25' AND '2025-12-31'
--    GROUP BY 1,
--             2) b ON a.dt=b.order_date
-- AND a.user_id=b.user_id
-- GROUP BY 1 ;



-- 每日访问事件
WITH t1 AS
  (SELECT dt,
          lower(event_ename) event_name,
                             unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31'
   GROUP BY 1,
            2,
            3),

-- 有曝光无点击或无详情页浏览
t2 AS
  (SELECT a.dt,
          a.user_id as view_user_id,
          b.user_id as ex_user_id,
          c.user_id as clk_user_id,
          d.user_id as dp_user_id,
          e.user_id as seex_user_id,
          f.user_id as seclc_user_id
   FROM
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_view'
      GROUP BY 1,
               2 ) a
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_feed_activity_ex'
      GROUP BY 1,
               2 ) b ON a.dt=b.dt
   AND a.user_id=b.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_feed_activity_click'
      GROUP BY 1,
               2 ) c ON a.dt=c.dt
   AND a.user_id=c.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='takeaway_detailpage_view'
      GROUP BY 1,
               2 ) d ON a.dt=d.dt
   AND a.user_id=d.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='search_result_ex'
      GROUP BY 1,
               2 ) e ON a.dt=e.dt
   AND a.user_id=e.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='search_result_click'
      GROUP BY 1,
               2 ) f ON a.dt=f.dt
   AND a.user_id=f.user_id
   )

SELECT dt,
       count(distinct a.view_user_id) `首页UV`,
       count(DISTINCT if(b.user_id IS NOT NULL,a.view_user_id,NULL)) `报名UV`,
       count(distinct if(a.ex_user_id is not null,a.view_user_id,null)) `曝光UV`,
       count(distinct if(a.ex_user_id is null,a.view_user_id,null)) `无曝光UV`,
       count(distinct if(a.clk_user_id is not null,a.view_user_id,null)) `点击UV`,
       count(distinct if(a.clk_user_id is null,a.view_user_id,null)) `无点击UV`,
       count(distinct if(a.dp_user_id is not null,a.view_user_id,null)) `详情页UV`,
       count(distinct if(a.dp_user_id is null,a.view_user_id,null)) `无详情页UV`,
       count(distinct if(a.dp_user_id is null and b.user_id is not null,a.view_user_id,null)) `有报名无详情UV`,
       count(distinct if(a.clk_user_id is null and b.user_id is null,a.view_user_id,null)) `无点击无报名UV`,
       count(distinct if(a.seclc_user_id is null and a.clk_user_id is null,a.view_user_id,null)) `无首页和搜索feed活动点击UV`
FROM t2 a
LEFT JOIN
  (SELECT date(order_time) order_date,
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE date(order_time) BETWEEN '2025-12-01' AND '2025-12-31'
   GROUP BY 1,
            2) b ON a.dt=b.order_date
AND a.view_user_id=b.user_id
GROUP BY 1 ;


-- 12月24日 首页浏览但无首页feed活动点击UV
-- 新老用户区别
-- 每日访问事件
WITH t1 AS
  (SELECT dt,
          lower(event_ename) event_name,
                             unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt='2025-12-24'
   GROUP BY 1,
            2,
            3),

-- 有曝光无点击或无详情页浏览
t2 AS
  (SELECT a.dt,
          a.user_id as view_user_id,
          b.user_id as ex_user_id,
          c.user_id as clk_user_id,
          d.user_id as dp_user_id,
          e.user_id as seex_user_id,
          f.user_id as seclc_user_id
   FROM
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_view'
      GROUP BY 1,
               2 ) a
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_feed_activity_ex'
      GROUP BY 1,
               2 ) b ON a.dt=b.dt
   AND a.user_id=b.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_feed_activity_click'
      GROUP BY 1,
               2 ) c ON a.dt=c.dt
   AND a.user_id=c.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='takeaway_detailpage_view'
      GROUP BY 1,
               2 ) d ON a.dt=d.dt
   AND a.user_id=d.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='search_result_ex'
      GROUP BY 1,
               2 ) e ON a.dt=e.dt
   AND a.user_id=e.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='search_result_click'
      GROUP BY 1,
               2 ) f ON a.dt=f.dt
   AND a.user_id=f.user_id
   ),

-- 新老用户
t3 AS
  (SELECT user_id,
          if(order_num>0, 1, 0) user_type
    from (SELECT user_id, count(1) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt<='2025-12-23'
        AND order_status IN (2, 8)
      GROUP BY 1) a)

SELECT if(user_type is null,0,user_type) user_type,
       count(distinct a.view_user_id) `首页UV`,
       count(distinct if(a.ex_user_id is not null,a.view_user_id,null)) `曝光UV`,
       count(distinct if(a.ex_user_id is null,a.view_user_id,null)) `无曝光UV`,
       count(distinct if(a.clk_user_id is not null,a.view_user_id,null)) `点击UV`,
       count(distinct if(a.clk_user_id is null,a.view_user_id,null)) `无点击UV`,
       count(distinct if(a.dp_user_id is not null,a.view_user_id,null)) `详情页UV`,
       count(distinct if(a.dp_user_id is null,a.view_user_id,null)) `无详情页UV`,
       count(distinct if(a.seclc_user_id is null and a.clk_user_id is null,a.view_user_id,null)) `无首页和搜索feed活动点击UV`
FROM t2 a
LEFT JOIN
  t3 b ON a.view_user_id=b.user_id
GROUP BY 1 ;



===== 无首页和搜索feed活动点击用户
-- 12月24日 首页浏览但无首页feed活动点击UV
-- 新老用户区别
-- 每日访问事件
WITH t1 AS
  (SELECT dt,
          lower(event_ename) event_name,
                             unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt='2025-12-24'
   GROUP BY 1,
            2,
            3),

-- 有曝光无点击或无详情页浏览
t2 AS
  (SELECT a.dt,
          a.user_id as view_user_id,
          b.user_id as ex_user_id,
          c.user_id as clk_user_id,
          d.user_id as dp_user_id,
          e.user_id as seex_user_id,
          f.user_id as seclc_user_id
   FROM
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_view'
      GROUP BY 1,
               2 ) a
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_feed_activity_ex'
      GROUP BY 1,
               2 ) b ON a.dt=b.dt
   AND a.user_id=b.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='homepage_feed_activity_click'
      GROUP BY 1,
               2 ) c ON a.dt=c.dt
   AND a.user_id=c.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='takeaway_detailpage_view'
      GROUP BY 1,
               2 ) d ON a.dt=d.dt
   AND a.user_id=d.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='search_result_ex'
      GROUP BY 1,
               2 ) e ON a.dt=e.dt
   AND a.user_id=e.user_id
   LEFT JOIN
     (SELECT dt,
             user_id
      FROM t1
      WHERE event_name='search_result_click'
      GROUP BY 1,
               2 ) f ON a.dt=f.dt
   AND a.user_id=f.user_id
   ),

-- 近30天访问天数
t3 AS
  (SELECT user_id,
          count(DISTINCT dt) days
   FROM
     (SELECT dt,
             unnest_bitmap AS user_id
      FROM dwd.dwd_sr_traffic_viewuser_d,
           unnest_bitmap(user_ids) AS uid
      WHERE dt BETWEEN date_sub('2025-12-23',interval 30 DAY) AND '2025-12-23'
      GROUP BY 1,
               2) a
   GROUP BY 1),


-- 新老用户
t4 AS
  (SELECT user_id,
          if(order_num>0, 1, 0) user_type
   from (SELECT user_id, count(1) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt<='2025-12-23'
        AND order_status IN (2, 8)
      GROUP BY 1) a)


-- 老用户近30天访问天数分布
SELECT user_type,
       count(1) uv,
       min(days) min_days, -- 0
       percentile_cont(days,0.1) 10_v,  -- 5
       percentile_cont(days,0.2) 20_v,  -- 9
       percentile_cont(days,0.3) 30_v,  -- 14
       percentile_cont(days,0.4) 40_v,  -- 17
       percentile_cont(days,0.5) 50_v,  -- 21
       percentile_cont(days,0.6) 60_v,  -- 24
       percentile_cont(days,0.7) 70_v,  -- 27
       percentile_cont(days,0.8) 80_v,  -- 29
       percentile_cont(days,0.9) 90_v,  -- 30
       max(days) max_days
FROM
(SELECT ifnull(days,0) days,
        a.user_id,
        t3.user_type
 FROM
   (SELECT user_id
    FROM t1
    GROUP BY 1) a
 INNER JOIN t4 ON a.user_id=t4.user_id
 LEFT JOIN t3 ON a.user_id=t3.user_id
 GROUP BY 1,
          2,
          3) toa
GROUP BY 1 ;


-- 无首页feed&搜索feed流活动点击近30天访问天数分布
select
       count(1) uv,
       min(days) min_days,
       percentile_cont(days,0.1) 10_v,  -- 2
       percentile_cont(days,0.2) 20_v,  -- 5
       percentile_cont(days,0.3) 30_v,  -- 8
       percentile_cont(days,0.4) 40_v,  -- 12
       percentile_cont(days,0.5) 50_v,  -- 15
       percentile_cont(days,0.6) 60_v,  -- 19
       percentile_cont(days,0.7) 70_v,  -- 22
       percentile_cont(days,0.8) 80_v,  -- 25
       percentile_cont(days,0.9) 90_v,  -- 28
       max(days) max_days
from (
SELECT ifnull(days,0) days,
    --    count(DISTINCT a.view_user_id) uv
    a.view_user_id
  from (SELECT view_user_id
   FROM t2
   WHERE seclc_user_id IS NULL
     AND clk_user_id IS NULL
   GROUP BY 1) a
LEFT JOIN t3 ON a.view_user_id=t3.user_id
GROUP BY 1,2
) toa
;










-- 小蚕霸王餐在仅在首页feed流、搜索feed流分发餐品活动，以单列卡片形式展示。经统计发现，12月日均首页访问UV：94.6万，其中，无首页feed流活动点击UV：36.6万，
-- 同时，经查看，无首页feed流活动点击的用户，有24.8万人，也没有搜索feed流活动点击。现在要分析用户不点击原因，提供些思路。

SELECT dt,
       count(promotion_id) AS pro_num,
       sum(if(tot_exp_num>0,1,0)) bg_pro_num,
       sum(tot_exp_num) exp_num,
       sum(tot_exp_num)/sum(if(tot_exp_num>0,1,0)) per_pro_exp_num
FROM
  (SELECT dt,
          promotion_id,
          -- city_name,
-- county_name,
--     case
--         when cate2 = 1 then '包子粥铺'
--         when cate2 = 2 then '快餐简餐'
--         when cate2 = 3 then '甜品饮品'
--         when cate2 = 4 then '炸串小吃'
--         when cate2 = 5 then '火锅烧烤'
--         when cate2 = 6 then '汉堡西餐'
--         when cate2 = 7 then '零售'
--         when cate2 = 8 then '水果鲜花'
--         when cate2 = 9 then '成人用品'
--             else '其他' end as cate2_name,
--     mlabel_threshold_amt,
--     mlabel_rebate_amt,
--     mlabel_rebate_amt/mlabel_threshold_amt as rebate_ratio,
--     mlabel,
--     promotion_quota,

          tot_homepage_activity_expose_num+tot_search_expose_num tot_exp_num
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31') a
GROUP BY 1;

SELECT dt,
       count(DISTINCT promotion_id) pro_num,
       count(DISTINCT if(exp_num>0,promotion_id,NULL)) bg_pro_num,
       bitmap_union_count(ex_uids) ex_uv
FROM
  (SELECT dt,
          promotion_id,
          tot_homepage_activity_expose_num exp_num,
          tot_homepage_activity_expose_uids AS ex_uids
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31'
   UNION ALL SELECT dt,
                    promotion_id,
                    tot_search_expose_num exp_num,
                    tot_search_expose_uids AS ex_uids
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt BETWEEN '2025-12-01' AND '2025-12-31' ) a
GROUP BY 1 ;


-- 大牌券订单
SELECT order_id,
       CASE
           WHEN order_type=14 THEN '小蚕承担成本大牌活动订单'
           WHEN get_json_string(platform_order_detail,'$.vip_promotion_card_id')>0 THEN '商家承担成本大牌活动订单'
           ELSE '自营订单'
       END order_typename
FROM dwd.dwd_sr_order_promotion_order
WHERE dt ='2025-12-01'
  AND store_promotion_id<>0 LIMIT 100;



要做也只能是上因果推断模型了，本质是拿到每个用户同周期内多个营销活动的参与和是否报名、后续次**天是否访问（日期、用户ID、活动类型/名称、参与次数、是否报名/完单、**天是否访问）这样的数据，给每个营销活动一个加权值，作为每个营销活动对报名、留存的解释占比。






-- 自营活动中区分大牌活动
SELECT order_id,
       CASE
           WHEN order_type=14 THEN '小蚕承担成本大牌活动订单'
           WHEN get_json_string(platform_order_detail,'$.vip_promotion_card_id')>0 THEN '商家承担成本大牌活动订单'
           ELSE '自营订单'
       END order_typename
FROM dwd.dwd_sr_order_promotion_order
WHERE dt ='2025-12-01'
  AND store_promotion_id<>0 LIMIT 100;




-- 月日均DAU
SELECT date_format(dt,'%Y-%m') mon,
       avg(cnt) `月日均UV`
FROM
  (SELECT dt,
          bitmap_union_count(user_ids) AS cnt
   FROM dwd.dwd_sr_traffic_viewuser_d
   WHERE dt BETWEEN '2024-01-01' AND '2025-12-31'
   GROUP BY 1) a
GROUP BY 1;


-- 月日均订单
SELECT date_format(dt,'%Y-%m') mon,
       avg(order_num) `日均报名订单量`,
       avg(valid_num) `日均有效订单量`,
       avg(order_unum) `日均报名用户量`,
       avg(valid_unum) `日均有效用户量`
FROM
  (SELECT dt,
          count(1) order_num,
          count(if(order_status IN (2,8),auto_id,NULL)) valid_num,
          count(DISTINCT user_id) order_unum,
          count(DISTINCT if(order_status IN (2,8),user_id,NULL)) valid_unum
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2024-01-01' AND '2025-12-31'
   GROUP BY 1) a
GROUP BY 1;


-- 月日均活动名额
SELECT month(dt) mon,
       avg(cnt) `日均活动数`,
       avg(quota) `日均活动名额`
FROM
  (SELECT dt,
          count(promotion_id) cnt sum(ifnull(meituan_promotion_quota,0)) + sum(ifnull(eleme_promotion_quota,0)) + sum(ifnull(jd_promotion_quota,0)) AS quota
   FROM dwd.dwd_sr_store_promotion
   WHERE dt BETWEEN '2024-01-01' AND '2025-12-31'
     AND status IN (1,
                    4,
                    5)
   GROUP BY 1) a
GROUP BY 1;





======== 红包雨参与和中奖

-- 参与
SELECT a.dt `统计日期`,
       count(DISTINCT a.activity_id) `参与量`,
       count(DISTINCT a.user_id) `参与用户量`,
       count(DISTINCT if(b.coupon_id<>0,a.user_id,NULL)) `中奖用户量`
FROM
  (SELECT dt,
          activity_id,
          user_id
   FROM dwd.dwd_sr_market_rpd_activity_takepart_record
   WHERE dt BETWEEN '2026-01-12' AND '2026-01-18') a
LEFT JOIN
  (SELECT dt,
          get_json_string(extend, '$.activity_id') activity_id,
          get_json_string(extend, '$.coupon_id') coupon_id,
          user_id
          -- sum(ifnull(get_json_string(red_pack_group, '$[0].red_pack_id'),0)) +sum(ifnull(get_json_string(red_pack_group, '$[1].red_pack_id'),0)) +sum(ifnull(get_json_string(red_pack_group, '$[2].red_pack_id'),0)) +sum(ifnull(get_json_string(red_pack_group, '$[3].red_pack_id'),0)) +sum(ifnull(get_json_string(red_pack_group, '$[4].red_pack_id'),0)) AS rdp_id

   FROM dwd.dwd_sr_market_rpd_lottery_winning_record
   WHERE dt BETWEEN '2026-01-12' AND '2026-01-18'
     AND activity_type = 2
   GROUP BY 1,
            2,
            3,
            4) b ON a.dt=b.dt
AND a.activity_id=b.activity_id
AND a.user_id=b.user_id
GROUP BY 1;



SELECT dt `统计日期`,
       promotion_id `活动ID`,
       city_name `城市名称`,
       county_name `区县名称`,
       CASE
           WHEN cate1=1 THEN '早餐'
           WHEN cate1=2 THEN '正餐'
           WHEN cate1=3 THEN '下午茶'
           WHEN cate1=4 THEN '晚餐'
           WHEN cate1=5 THEN '夜宵'
           WHEN cate1=6 THEN '零售'
           ELSE '其他'
       END `一级品类`,
       CASE
           WHEN cate2=1 THEN '包子粥铺'
           WHEN cate2=2 THEN '快餐简餐'
           WHEN cate2=3 THEN '甜品饮品'
           WHEN cate2=4 THEN '炸串小吃'
           WHEN cate2=5 THEN '火锅烧烤'
           WHEN cate2=6 THEN '汉堡西餐'
           WHEN cate2=7 THEN '零售'
           WHEN cate2=8 THEN '水果鲜花'
           WHEN cate2=9 THEN '成人用品'
           ELSE '其他'
       END `二级品类`,
       store_platform `店铺平台`,
       CASE
           WHEN store_type=0 THEN '普通店铺'
           WHEN store_type=1 THEN '优质店铺'
           WHEN store_type=2 THEN '大客户'
           ELSE '其他'
       END `店铺类型`,
       if(store_brand_type=1,'大牌','非大牌') `品牌类型`,
       CASE
           WHEN delivery_type=0 THEN '美团配送'
           WHEN delivery_type=1 THEN '商家自配送'
           ELSE '其他'
       END `配送方式`,
       if(is_threshold=1,'是','否') `是否有门槛`,
       if(is_need_rating=1,'是','否') `是否需点评`,
       if(promotion_rebate_type=0,'霸王餐','返利餐') `返利类型`,
       mlabel_threshold_amt `餐标门槛`,
       mlabel_rebate_amt `餐标返现金额`,
       mlabel `餐标`,
       if(mlabel_threshold_amt=0,0,mlabel_rebate_amt/mlabel_threshold_amt) `返现比例`,
       sum(promotion_quota) `活动名额`,
       sum(tot_homepage_activity_expose_num) `首页活动曝光量`,
       sum(tot_homepage_activity_clc_num) `首页活动点击量`,
       sum(tot_takeaway_detailpage_pv) `活动详情页PV`,
       bitmap_union_count(tot_homepage_activity_expose_uids bitmap COMMENT) `首页活动曝光UV`,
       bitmap_union_count(tot_homepage_activity_clc_uids bitmap COMMENT) `首页活动点击UV`,
       bitmap_union_count(tot_takeaway_detailpage_uids bitmap COMMENT) `活动详情页UV`,
       SUM(tot_search_expose_num) `搜索曝光量`,
       SUM(tot_search_result_clc_num) `搜索结果点击量`,
       bitmap_union_count(tot_search_expose_uids) `搜索曝光UV`,
       bitmap_union_count(tot_search_result_clc_uids) `搜索结果点击UV`,
       sum(order_num) `报名订单量`,
       sum(valid_order_num) `有效订单量`,
       sum(handle_cancel_order_num) `手动取消订单量`,
       sum(timeout_cancel_order_num) `超时取消订单量`,
       sum(cancel_order_num) `取消订单量`,
       bitmap_union_count(baoming_uids) `报名UV`,
       bitmap_union_count(handle_cancel_uids) `手动取消UV`,
       bitmap_union_count(timeout_cancel_uids) `超时取消UV`,
       bitmap_union_count(cancel_uids) `取消UV`,
       bitmap_union_count(valid_uids) `有效UV`
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt ='2025-12-08'
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
         15,
         16,
         17 ;


SELECT `城市名称`,
       `区县名称`,
       avg(`首页活动曝光量`) `首页活动曝光量`,
       avg(`首页活动点击量`) `首页活动点击量`,
       avg(`首页活动曝光UV`) `首页活动曝光UV`,
       avg(`首页活动点击UV`) `首页活动点击UV`,
       avg(`搜索曝光量`) `搜索曝光量`,
       avg(`搜索结果点击量`) `搜索结果点击量`,
       avg(`搜索曝光UV`) `搜索曝光UV`
FROM
  (SELECT dt `统计日期`,
          city_name `城市名称`,
          county_name `区县名称`,
          sum(tot_homepage_activity_expose_num) `首页活动曝光量`,
          sum(tot_homepage_activity_clc_num) `首页活动点击量`,
          sum(tot_takeaway_detailpage_pv) `活动详情页PV`,
          bitmap_union_count(tot_homepage_activity_expose_uids bitmap COMMENT) `首页活动曝光UV`,
          bitmap_union_count(tot_homepage_activity_clc_uids bitmap COMMENT) `首页活动点击UV`,
          bitmap_union_count(tot_takeaway_detailpage_uids bitmap COMMENT) `活动详情页UV`,
          SUM(tot_search_expose_num) `搜索曝光量`,
          SUM(tot_search_result_clc_num) `搜索结果点击量`,
          bitmap_union_count(tot_search_expose_uids) `搜索曝光UV`,
          bitmap_union_count(tot_search_result_clc_uids) `搜索结果点击UV`
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt BETWEEN '2025-12-08' AND '2025-12-14'
     AND city_name='上海市'
   GROUP BY 1,
            2,
            3) a
GROUP BY 1,
         2;






请以文件中“销单率”列为目标，自主设置分析维度，定位哪些地方销单率低，以便为后续分析提供方向。其中，销单率=有效订单量/活动名额，销单率大于1属于正常现象，因有些活动名额，商家收到了差评，会被系统放出来，用户可以在这些名额下单，或者可以根据“是否销单率大于1”列，在分析时排除，但要告知为什么排除，排除了多少活动，活动名额是多少。另外，数据已经是活动ID维度的统计结果。


在盘货时，要先针对同维度下，做一些描述性统计，看看活动名额、有效订单量、曝光这些指标的分布，以及指标相关性。

主要目的就是盘货，针对活动ID的有效订单量，在给到的维度下，定位出有效订单是否有问题，有的话，是哪些问题，是什么原因。现在的数据，原因分析可能做不到，可以不做。



请以文件中“销单率”列为目标，自主设置分析维度，定位哪些地方销单率低，以便为后续分析提供方向。其中，销单率=有效订单量/活动名额。销单率大于1属于正常现象，因有些活动名额，商家收到了差评，会被系统放出来，用户可以在这些名额下单，在分析时排除，但要告知为什么排除，排除了多少活动，活动名额是多少。另外，数据已经是活动ID维度的统计结果。

在盘货时，要先找出有效销单量是0的活动、以及有效销单量低于同城市同区县整体的活动，再根据这些活动，做描述性统计，定位出集中在哪些城市区县、哪些品类、哪些餐标上。

需要输出有效销单量是0的活动、以及有效销单量低于同城市同区县整体的活动清单，保留所有字段，再增加一列，识别到的原因，字段列名”低销单识别规则“，以及描述统计的结果。




已经在jupyter中传3个文件，名称分别是“20260122_货盘盘点01”、“20260122_货盘盘点02”、“20260122_货盘盘点03”。文件中数据表表头均一致，需要先将数据合并。再去分析。

以文件中“销单率”列为目标，自主设置分析维度，定位哪些地方销单率低，以便为后续分析提供方向。其中，销单率=有效订单量/活动名额。销单率大于1属于正常现象，因有些活动名额，商家收到了差评，会被系统放出来，用户可以在这些名额下单，在分析时排除，但要告知为什么排除，排除了多少活动，活动名额是多少。另外，数据已经是活动ID维度的统计结果。

在盘货时，要先找出有效销单量是0的活动、以及有效销单量低于同城市同区县整体的活动，再根据这些活动，做描述性统计，定位出集中在哪些城市区县、哪些品类、哪些餐标上。

需要输出有效销单量是0的活动、以及有效销单量低于同城市同区县整体的活动清单，保留所有字段，再增加一列，识别到的原因，字段列名”低销单识别规则“，以及描述统计的结果。


在盘货时，要先找出有效销单量是0的活动、以及有效销单量低于同城市同区县整体的活动，再根据这些活动，做描述性统计，定位出集中在哪些城市区县、哪些品类、哪些餐标上。

补充两点：
1）不看一级品类，看二级品类，因一级品类标注都是“其他”。逻辑中增加复合维度：城市+区县+二级品类+餐标的描述统计，以及增加餐标门槛、餐标返现金额维度下的统计。
2）返利类型有“霸王餐”、“返利餐”，霸王餐“餐标”是“满*返*”格式，所以“餐标门槛”、“餐标返现金额”有值，返利餐的“餐标门槛”、“餐标返现金额”，不一定有值，需要区分霸王餐、返利餐两种类型，分别找出有效订单量0的活动、低销单率活动，再做描述统计。补充餐标门槛、餐标返现金额作为维度做描述统计。

多维度描述统计，要增加城市+区县维度、餐标维度，每个维度都给到活动名额top100的数据，并且，描述统计要给出指标下的分位值






已经在jupyter中传3个文件，名称分别是“20260122_货盘盘点01.xlsx”、“20260122_货盘盘点02.xlsx”、“20260122_货盘盘点03.xlsx”。文件中数据表表头均一致，需要先将数据合并，筛选“返利类型”=“霸王餐”的数据，再去分析。
以文件中“销单率”列为目标，以文件中活动ID为粒度，限制在同城市+区县+二级品类下（因是外卖类App，基于用户位置），统计各个活动ID的销单率、首页活动曝光量、首页活动曝光UV、搜索曝光量、搜索曝光UV等指标的分布，先定位出哪些城市+区县+二级品类销单率低，再根据数据，分析销单率低的原因，期望是找到事UV不足，还是曝光不足，还是餐标门槛太高，或者返现金额太小、活动供应过剩（即活动名额很多，UV少）等。最好可以在结果中输出这些结果。

其中，销单率=有效订单量/活动名额。销单率大于1属于正常现象，因有些活动名额，商家收到了差评，会被系统放出来，用户可以在这些名额下单，在分析时排除，以及排除首页活动曝光UV+搜索曝光UV之和，小于报名订单量的数据，但要告知排除了多少活动，活动名额是多少。

补充：
文件数据表头：统计日期 活动ID  城市名称  区县名称  一级品类  二级品类  店铺平台  店铺类型  品牌类型  配送方式  是否有门槛 是否需点评 返利类型  餐标  餐标门槛  餐标返现金额  返现比例  活动名额  首页活动曝光量 首页活动点击量 活动详情页PV 首页活动曝光UV  首页活动点击UV  活动详情页UV 搜索曝光量 搜索结果点击量 搜索曝光UV  搜索结果点击UV  报名订单量 有效订单量 手动取消订单量 超时取消订单量 取消订单量 报名UV  手动取消UV  超时取消UV  取消UV  有效UV  销单率 区县首页活动曝光量 区县首页活动点击量 区县活动详情页PV 区县首页活动曝光UV  区县首页活动点击UV  区县活动详情页UV 区县搜索曝光量 区县搜索结果点击量 区县搜索曝光UV  区县搜索结果点击UV

可以直接给到结果，或者给到可以在jupyter执行的Python脚本


-- 探店订单分布
SELECT date_format(dt,'%Y-%m') `月份`,
       count(1) `订单量`,
       count(DISTINCT user_id) `下单用户量`,
       count(DISTINCT if(status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,NULL)) `核销订单量`,
       count(DISTINCT if(status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),user_id,NULL)) `核销用户量`,
       count(DISTINCT if(status IN (5,19,20,34,35),order_id,NULL)) `完单量`,
       count(DISTINCT if(status IN (5,19,20,34,35),user_id,NULL)) `完单用户量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-25'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,NULL)) `12月同期核销订单量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-25'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),user_id,NULL)) `12月同期核销用户量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-25'
                         AND status IN (5,19,20,34,35),order_id,NULL)) `12月同期完单量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-25'
                         AND status IN (5,19,20,34,35),user_id,NULL)) `12月同期完单用户量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-25'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,NULL)) `1月同期核销订单量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-25'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),user_id,NULL)) `1月同期核销用户量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-25'
                         AND status IN (5,19,20,34,35),order_id,NULL)) `1月同期完单量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-25'
                         AND status IN (5,19,20,34,35),user_id,NULL)) `1月同期完单用户量`
FROM dwd.dwd_sr_silkworm_explore_order
WHERE dt BETWEEN '2025-11-01' AND '2026-01-25'
  AND promotion_type IN (1,
                         4)
GROUP BY 1;

-- 新老客（按照是否核销区分）
-- 同用户当月下单，首次下单时是新，则本月为新，首次下单时是老，则本月是老
-- 按月取数 逻辑处理不复杂 快
WITH t1 AS
  (SELECT user_id,min(date_format(dt,'%Y-%m')) as min_mon
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date(verify_time)<>'1970-01-01'
     AND promotion_type IN (1,
                            4)
   GROUP BY 1)

SELECT date_format(dt,'%Y-%m') `月份`,
       if(t1.user_id IS NOT NULL and min_mon=date_format(dt,'%Y-%m'),'新用户','老用户') `用户类型(是否有核销)`,
       count(1) `订单量`,
       count(DISTINCT a.user_id) `下单用户量`,
       count(DISTINCT if(status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,NULL)) `核销订单量`,
       count(DISTINCT if(status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),a.user_id,NULL)) `核销用户量`,
       count(DISTINCT if(status IN (5,19,20,34,35),order_id,NULL)) `完单量`,
       count(DISTINCT if(status IN (5,19,20,34,35),a.user_id,NULL)) `完单用户量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-31'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,NULL)) `12月同期核销订单量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-31'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),a.user_id,NULL)) `12月同期核销用户量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-31'
                         AND status IN (5,19,20,34,35),order_id,NULL)) `12月同期完单量`,
       count(DISTINCT if(dt BETWEEN '2025-12-01' AND '2025-12-31'
                         AND status IN (5,19,20,34,35),a.user_id,NULL)) `12月同期完单用户量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-31'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,NULL)) `1月同期核销订单量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-31'
                         AND status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),a.user_id,NULL)) `1月同期核销用户量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-31'
                         AND status IN (5,19,20,34,35),order_id,NULL)) `1月同期完单量`,
       count(DISTINCT if(dt BETWEEN '2026-01-01' AND '2026-01-31'
                         AND status IN (5,19,20,34,35),a.user_id,NULL)) `1月同期完单用户量`
FROM
  (SELECT dt,
          order_id,
          user_id,
          status
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN '2025-11-01' AND '2025-11-30'
     AND promotion_type IN (1,
                            4)) a
LEFT JOIN t1 ON a.user_id=t1.user_id
GROUP BY 1,
         2;

======================================
-- 用户设备量等统计
SELECT count(DISTINCT $device_id) `设备量`,
       count(DISTINCT user_id) `用户量`,
       count(DISTINCT distinct_id) `用户量(含登录)`,
       count(DISTINCT if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,NULL)) `登录用户量`
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time)='2026-01-28'
  AND ((platform_type regexp '5'
        AND event NOT IN ('App_Launch',
                          'Change_Location'))
       OR platform_type NOT regexp '5')
  AND $device_id IS NOT NULL
;


-- 匿名用户设备数分布
SELECT uid_num `匿名用户量`,
       count(1) `设备量`
FROM
  (SELECT $device_id,
          count(DISTINCT user_id) uid_num
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date(time)='2026-01-28'
     AND distinct_id NOT regexp '^[0-9]{1,10}$'
     AND ((platform_type regexp '5'
           AND event NOT IN ('App_Launch',
                             'Change_Location'))
          OR platform_type NOT regexp '5')
   GROUP BY 1) a
GROUP BY 1;


-- 无device_id的匿名用户分布
SELECT platform_type,
       count(DISTINCT user_id) `无设备ID匿名用户量`
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time)='2026-01-28'
  AND distinct_id NOT regexp '^[0-9]{1,10}$'
  AND ((platform_type regexp '5'
        AND event NOT IN ('App_Launch',
                          'Change_Location'))
       OR platform_type NOT regexp '5')
  AND $device_id IS NULL
GROUP BY 1;





-- 匿名用户设备数分布
SELECT uid_num `匿名用户量`,
       count(1) `设备量`
FROM
  (SELECT $device_id,
          count(DISTINCT user_id) uid_num
   FROM events
   WHERE date(time)='2026-01-28'
     AND distinct_id NOT regexp '^[0-9]{1,10}$'
     AND ((platform_type regexp '5'
           AND event NOT IN ('App_Launch',
                             'Change_Location'))
          OR platform_type NOT regexp '5')
   GROUP BY 1) a
GROUP BY 1;


-- 无device_id的匿名用户分布
SELECT platform_type `平台名称`,
       count(DISTINCT user_id) `无设备ID匿名用户量`
FROM events
WHERE date(time)='2026-01-28'
  AND distinct_id NOT regexp '^[0-9]{1,10}$'
  AND ((platform_type regexp '5'
        AND event NOT IN ('App_Launch',
                          'Change_Location'))
       OR platform_type NOT regexp '5')
  AND $device_id IS NULL
GROUP BY 1;



-- H5端无设备信息的 是否IP集中（否）
SELECT platform_type,
       $ip,
       count(DISTINCT user_id) `匿名用户量`
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time)='2026-01-28'
  AND distinct_id NOT regexp '^[0-9]{1,10}$'
  AND ((platform_type regexp '5'
        AND event NOT IN ('App_Launch',
                          'Change_Location'))
       OR platform_type NOT regexp '5')
  AND platform_type regexp '5'
  AND $device_id IS NULL
GROUP BY 1,
         2
ORDER BY 3 DESC LIMIT 1000;


-- and( (lower(platform_type)='h5' and event<>'App_Launch' and event<>'Change_Location' and $url regexp  'gw.djtaoke.cn/static/silk/nauth.html#/member-income-rank/member'-- 赚钱页
--      ) 
--      or lower(platform_type)<>'h5'
--      or  (lower(platform_type)='h5' and $url not regexp  'gw.djtaoke.cn/static/silk/nauth.html#/member-income-rank/member')


-- 抽奖来源发放免单券
-- 1月19日至21日超发
SELECT dt,
       count(1) tot,
       count(if(date(used_time)<>'1970-01-01',auto_id,NULL)) used_num
FROM dwd.dwd_sr_market_rights_card
WHERE dt BETWEEN '2026-01-01' AND '2026-01-29'
  AND card_type=14
  AND card_id=109
GROUP BY 1;


-- 超发用户客服补偿
SELECT a.user_id,
       b.candou_amt,
       toa.tot,
       toa.redpacket_amt,
       toa.real_rebate_amt
FROM
-- 超发用户
  (SELECT user_id
   FROM dwd.dwd_sr_market_rights_card
   WHERE dt BETWEEN '2026-01-17' AND '2026-01-23'
     AND card_type=14
     -- AND card_id=109
   GROUP BY 1) a
LEFT JOIN
-- 客服补蚕豆
  (SELECT user_id,
          sum(add_candou_num/100) candou_amt
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2026-01-17' AND '2026-01-25'
     AND cate2_type=4
   GROUP BY 1) b ON a.user_id=b.user_id
LEFT JOIN
-- 客服补红包
  (SELECT user_id,
          count(1) tot,
          sum(redpacket_amt) redpacket_amt,
          sum(real_rebate_amt) real_rebate_amt
   FROM
     (SELECT record_id,
             work_order_id,
             redpacket_amt
      FROM dwd.dwd_sr_callcenter_workorder_rp_grant
      WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2026-01-17' AND '2026-01-25'
        AND redpacket_type=1 -- 霸王餐
        AND status=1 -- 发放成功
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN
     (SELECT work_order_id,
             order_id
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2026-01-17' AND '2026-01-25'
      GROUP BY 1,
               2) b ON a.work_order_id=b.work_order_id
   left JOIN
     (SELECT auto_id,
             order_id,
             real_rebate_amt,
             user_id
      FROM dwd.dwd_sr_market_redpack_use_record
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2026-01-17' AND '2026-01-25'
        AND redpacket_use_status = 2 -- 已使用
        AND order_id<>''
        AND order_id IS NOT NULL) c ON b.order_id=c.order_id
   GROUP BY 1) toa ON a.user_id=toa.user_id;




-- 日流量+注册+销单
SELECT a.dt `统计日期`,
       `注册用户量`,
       `新增有效团员量`,
       `累计注册用户量`,
       `累计完单4单及以上用户量`,
       `DAU`,
       `活动名额`,
       `报名订单量`,
       `有效订单量`,
       `手动取消订单量`,
       `超时取消订单量`,
       `取消订单量`,
       `有效订单利润`,
       `有效订单量`/`活动名额` AS `销单率`
from

  (SELECT dt,
          register_user_num `注册用户量`,
          acc_signup_user_num `累计注册用户量`,
          acc_above4ord_user_num `累计完单4单及以上用户量`
   FROM ads.ads_sr_user_signup_usernum_d
   WHERE dt BETWEEN '${begin_date}' AND '${end_date}') a
LEFT JOIN
  (SELECT dt,
          bitmap_union_count(user_ids) AS `DAU`
   FROM dwd.dwd_sr_traffic_viewuser_d
   WHERE dt BETWEEN '${begin_date}' AND '${end_date}'
   GROUP BY 1) b ON a.dt=b.dt
LEFT JOIN
  (SELECT dt,
          ifnull(sum(promotion_quota),0) `活动名额`,
          ifnull(sum(order_num),0) `报名订单量`,
          ifnull(sum(valid_order_num),0) `有效订单量`,
          ifnull(sum(handle_cancel_order_num),0) `手动取消订单量`,
          ifnull(sum(timeout_cancel_order_num),0) `超时取消订单量`,
          ifnull(sum(cancel_order_num),0) `取消订单量`,
          ifnull(sum(profit),0) `有效订单利润`
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt BETWEEN '${begin_date}' AND '${end_date}'
   GROUP BY 1) c ON a.dt=c.dt
LEFT JOIN
  (SELECT date(first_valid_order_time) AS dt,
          count(1) `新增有效团员量`
   FROM dim.dim_silkworm_user
   WHERE date(first_valid_order_time) BETWEEN '${begin_date}' AND '${end_date}'
     AND inviter_user_id<>0
   GROUP BY 1) d ON a.dt=d.dt;









三、述职内容建议（四大核心维度）
请围绕以下框架准备述职内容，每人陈述时间20-25分钟，问答环节10-15分钟：
1. 回顾与结果
陈述年度团队目标与KPI/OKR达成情况，重点展示3-5项关键团队成果。
2. 诊断与分析
从团队配置、管理举措、流程机制等方面，分析其对目标达成的影响与得失。
3. 规划与举措
阐述2026年团队目标、实现策略及核心管理举措。
4. 需求与建议
提出实现团队目标所需的关键资源或授权，以及对跨部门/公司流程的优化建议。


-- 探店完单订单明细
SELECT CONCAT('单',order_id) `订单ID`,
       cast(create_time AS string) `创建时间`,
       cast(finish_time AS string) `完单时间`,
       pay_amt `支付价格`,
       real_rebate_amt `实际返现金额`,
       withdrawal_time `可提现时间`,
       red_pack_reward_num/100 `红包返豆金额`
FROM dwd.dwd_sr_silkworm_explore_order
WHERE promotion_type IN (1,
                         4)
  AND status IN (5,
                 19,
                 20,
                 34,
                 35)


-- 近90天虚假订单
SELECT concat('单',a.order_id) `订单ID`,
       platform_order_screenshot `平台订单截图`,
       platform_pic_ocr_result `平台识别图片文本结果`,
       platform_order_rate_detail `平台订单评价详情`
FROM
  (SELECT order_id
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN date_sub(CURRENT_DATE,interval 90 DAY) AND date_sub(CURRENT_DATE,interval 1 DAY)
     AND cate3_type=7
     AND relation_order_source_type=0
   GROUP BY 1) a
LEFT JOIN
  (SELECT order_id,
          platform_order_screenshot,
          platform_pic_ocr_result,
          platform_order_rate_detail
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(CURRENT_DATE,interval 150 DAY) AND date_sub(CURRENT_DATE,interval 1 DAY)) b ON a.order_id=b.order_id ;

-- 店铺城市已支付外卖活动金额
SELECT
  city_name `店铺城市`,
  sum(1m_rebate_amt) `1月商家已支付金额`,
  sum(2m_rebate_amt) `2月商家已支付金额`,
  sum(3m_rebate_amt) `3月商家已支付金额`,
  sum(4m_rebate_amt) `4月商家已支付金额`,
  sum(5m_rebate_amt) `5月商家已支付金额`,
  sum(6m_rebate_amt) `6月商家已支付金额`,
  sum(7m_rebate_amt) `7月商家已支付金额`,
  sum(8m_rebate_amt) `8月商家已支付金额`,
  sum(9m_rebate_amt) `9月商家已支付金额`,
  sum(10m_rebate_amt) `10月商家已支付金额`,
  sum(11m_rebate_amt) `11月商家已支付金额`,
  sum(12m_rebate_amt) `12月商家已支付金额`
from
(select
      store_id,
      sum(if(date(pay_time) between '2025-01-01' and '2025-01-31',fact_pay_rebate_amt/100,0)) 1m_rebate_amt,
      sum(if(date(pay_time) between '2025-02-01' and '2025-02-28',fact_pay_rebate_amt/100,0)) 2m_rebate_amt,
      sum(if(date(pay_time) between '2025-03-01' and '2025-03-31',fact_pay_rebate_amt/100,0)) 3m_rebate_amt,
      sum(if(date(pay_time) between '2025-04-01' and '2025-04-30',fact_pay_rebate_amt/100,0)) 4m_rebate_amt,
      sum(if(date(pay_time) between '2025-05-01' and '2025-05-31',fact_pay_rebate_amt/100,0)) 5m_rebate_amt,
      sum(if(date(pay_time) between '2025-06-01' and '2025-06-30',fact_pay_rebate_amt/100,0)) 6m_rebate_amt,
      sum(if(date(pay_time) between '2025-07-01' and '2025-07-31',fact_pay_rebate_amt/100,0)) 7m_rebate_amt,
      sum(if(date(pay_time) between '2025-08-01' and '2025-08-31',fact_pay_rebate_amt/100,0)) 8m_rebate_amt,
      sum(if(date(pay_time) between '2025-09-01' and '2025-09-30',fact_pay_rebate_amt/100,0)) 9m_rebate_amt,
      sum(if(date(pay_time) between '2025-10-01' and '2025-10-31',fact_pay_rebate_amt/100,0)) 10m_rebate_amt,
      sum(if(date(pay_time) between '2025-11-01' and '2025-11-30',fact_pay_rebate_amt/100,0)) 11m_rebate_amt,
      sum(if(date(pay_time) between '2025-12-01' and '2025-12-31',fact_pay_rebate_amt/100,0)) 12m_rebate_amt
from dwd.dwd_sr_store_promotion
where date(pay_time) between '2025-01-01' and '2025-12-31'
and pay_status in (0,3,4)
and status in (1,4,5)
group by 1) a
left join dim.dim_silkworm_store on a.store_id=b.store_id
group by 1;



curl -fsSL https://claude.ai/install.sh | bash





日活、供给、单量


dwd.dwd_sr_total_market_redpack_use_record -- dwd.dwd_sr_market_redpack_use_record 20260304替换数据表 因旧表25年4月22日至9月4日数据缺失 修改人：大禾







SELECT dt `统计日期`,
       city_name `城市名称`,
       CASE
           WHEN cate1=1 THEN '早餐'
           WHEN cate1=2 THEN '正餐'
           WHEN cate1=3 THEN '下午茶'
           WHEN cate1=4 THEN '晚餐'
           WHEN cate1=5 THEN '夜宵'
           WHEN cate1=6 THEN '零售'
           ELSE '其他'
       END `一级品类`,
       CASE
           WHEN cate2=1 THEN '包子粥铺'
           WHEN cate2=2 THEN '快餐简餐'
           WHEN cate2=3 THEN '甜品饮品'
           WHEN cate2=4 THEN '炸串小吃'
           WHEN cate2=5 THEN '火锅烧烤'
           WHEN cate2=6 THEN '汉堡西餐'
           WHEN cate2=7 THEN '零售'
           WHEN cate2=8 THEN '水果鲜花'
           WHEN cate2=9 THEN '成人用品'
           ELSE '其他'
       END `二级品类`,
       mlabel `餐标`,
       count(promotion_id) `活动数`,
       sum(promotion_quota) `总活动名额`,
       sum(order_num) `报名订单量`,
       sum(valid_order_num) `有效订单量`
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt BETWEEN '2026-02-25' AND '2026-03-03'
  AND city_name IN ('上海市',
                    '成都市',
                    '杭州市',
                    '深圳市',
                    '广州市')
GROUP BY 1,
         2,
         3,
         4,
         5;



-- 会员等级
SELECT dt `统计日期`,
       count(DISTINCT if(new_level=1,silk_id,NULL)) `V1等级用户量`,
       count(DISTINCT if(new_level=2,silk_id,NULL)) `V2等级用户量`,
       count(DISTINCT if(new_level=3,silk_id,NULL)) `V3等级用户量`,
       count(DISTINCT if(new_level=4,silk_id,NULL)) `V4等级用户量`,
       count(DISTINCT if(new_level=5,silk_id,NULL)) `V5等级用户量`,
       count(DISTINCT if(new_level=6,silk_id,NULL)) `V6等级用户量`
FROM dwd.dwd_sr_client_vip_new_level_dt
GROUP BY 1;


-- 近30日有活动店铺或新店铺类目
-- 店铺数：130727 无类目店铺数：11486
SELECT count(1) `店铺数`,
       count(if(length(xc_category)<=2
                OR xc_category IS NULL,store_id,NULL)) `无类目店铺数`
FROM
  (SELECT store_id,
          xc_category
   FROM dim.dim_silkworm_store
   WHERE date(latest_promotion_time) BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
   UNION SELECT store_id,
                xc_category
   FROM dim.dim_silkworm_store
   WHERE date(create_time) BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)) a ;



===== 用户蚕豆数据
select
    user_id,
    (user_extra_point/100)+await_withdrawal_candou_num as `现有蚕豆数`,
    await_withdrawal_candou_num as `返利现有蚕豆数`,
    user_extra_point/100 as `营销现有蚕豆数`,
    (user_extra_point/100)+await_withdrawal_candou_num+tot_withdrawal_amt+withdrawal_candou_num as `累计蚕豆数`
from dim.dim_silkworm_user




SELECT left(got_time,7) AS '获得时间',
       count(if(pack_type IN (3,4,5,8,9,12,13,14,15,16,17) , pack_id, NULL)) AS '礼包数量',
       count(if(pack_type = 11 , pack_id,NULL)) AS '礼包数量-11',
       count(if(pack_type IN (18,19,20,21,22,23,24,25,26,27) , pack_id, NULL)) AS '礼包数量-升级'
FROM dwd.dwd_sr_market_user_pack
WHERE left(got_time,7) >= '2025-10'
GROUP BY 1


-- 周年庆每日限时激活礼包许愿报名和领取成功用户数
SELECT dt `统计日期`,
       count(DISTINCT if(pack_detail regexp '"is_select":1',user_id,NULL)) `许愿报名用户量`,
       count(DISTINCT if(date(got_time)<>'1970-01-01',user_id,NULL)) `领取成功用户量`
FROM dwd.dwd_sr_market_user_pack
WHERE dt BETWEEN '2026-03-01' AND '2026-03-05'
  AND pack_type=11
GROUP BY 1;




===================== 晓晓销单率 
-- 在晓晓MySQL业务库执行 要特小心
SELECT
    COUNT(DISTINCT o.id) AS completed_orders,
    SUM(t.task_total_quota) AS total_quota
FROM bwc_task t
LEFT JOIN bwc_order o 
    ON o.task_id = t.id 
    AND o.data_state = 0 
    AND o.order_status IN (4, -3)
WHERE t.data_state = 0
  AND t.task_start_time >= '统计周期开始时间'
  AND t.task_start_time <= '统计周期结束时间'

-- 探查数据
SELECT date(`task_start_time`) dt,
       count(*) tot,
       sum(if(data_state = 0, `task_total_quota`, 0)) quota
FROM `bwc_task`
WHERE `id` BETWEEN 15919846 AND 16919846
GROUP BY 1
ORDER BY 1 DESC;


-- 统计晓晓25年12与每日销单
SELECT t.dt,
       sum(o.completed_orders) AS completed_orders, -- 完单量(和小蚕有效订单量等同)
       SUM(t.task_total_quota) AS total_quota -- 活动名额
FROM
  (SELECT id,
          date(task_start_time) dt,
          task_total_quota
   FROM bwc_task
   WHERE id BETWEEN 15919846 AND 16919846
     AND data_state = 0
     AND date(task_start_time) BETWEEN '2025-12-01' AND '2025-12-31') t
LEFT JOIN
  (SELECT task_id,
          COUNT(DISTINCT id) completed_orders
   FROM bwc_order
   WHERE id BETWEEN 85015119 AND 90015119 -- 直接在MySQL业务库执行，为了少跑数据，筛选出12月份订单的主键ID区间
     AND data_state = 0
     AND order_status IN (4,
                          -3)
   GROUP BY 1 ) o ON o.task_id = t.id
GROUP BY 1;


-- 分小时下单量
SELECT create_date,
       task_id,
       if(`下单时点`<12,'12点前','12点后') `时间段`,
       sum(quota) `活动名额`,
       sum(`下单量`) `下单量`,
       sum(`小蚕下单量`) `小蚕下单量`
FROM
  (SELECT task_id,
          create_date,
          hour(`create_time`) `下单时点`,
          count(`id`) `下单量`,
          sum(if(user_id = 2625802, 1, 0)) `小蚕下单量`
   FROM `bwc_order`
   WHERE `id` BETWEEN 92199059 AND 92249493
   GROUP BY 1,
            2,
            3) a
LEFT JOIN
  (SELECT id,
          sum(if(data_state = 0, `task_total_quota`, 0)) quota
   FROM `bwc_task`
   WHERE `id` BETWEEN 16854567 AND 16954567
   GROUP BY 1) b ON a.task_id=b.id
where a.`小蚕下单量`<>0
GROUP BY 1,2,3;



=========================================================================================================
select
user_id,age,
from dwd.dwd_silkworm_user_feature_data




ods_sr_client_vip_realtime




-- 用户
SELECT CASE
           WHEN `年龄` IS NULL
                or `年龄`=0 THEN '未知'
           WHEN `年龄`<=24 THEN '学生党'
           ELSE '职场人'
       END `用户画像`,
       if(is_plus=1,'是','否') `是否SVIP`,
       `会员等级`,
       count(DISTINCT user_id) `用户量`,
       sum(`累计完单量`) `累计完单量`,
       sum(`近14天拉新用户量`) `近14天拉新用户量`,
       sum(`近14天有效拉新用户量`) `近14天有效拉新用户量`
FROM
  (SELECT a.user_id,
          year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),NULL)) AS `年龄`,
          accu_valid_order_num `累计完单量`,
          b.newuser_num `近14天拉新用户量`,
          b.valid_newuser_num `近14天有效拉新用户量`,
          CASE
              WHEN c.new_level=1 THEN 'V1'
              WHEN c.new_level=2 THEN 'V2'
              WHEN c.new_level=3 THEN 'V3'
              WHEN c.new_level=4 THEN 'V4'
              WHEN c.new_level=5 THEN 'V5'
              WHEN c.new_level=6 THEN 'V6'
          END `会员等级`,
          c.is_plus
   FROM dim.dim_silkworm_user a
   LEFT JOIN
     (SELECT inviter_user_id,
             count(distinct user_id) newuser_num,
             count(if(accu_valid_order_num>=1,user_id,NULL)) valid_newuser_num
      FROM dim.dim_silkworm_user
      WHERE date(register_time) BETWEEN date_sub(current_date(),interval 14 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1) b ON a.user_id=b.inviter_user_id
   LEFT JOIN ods.ods_sr_client_vip_realtime c ON a.user_id=c.silk_id) tot
GROUP BY 1,
         2,
         3;






-- 用户top品类
SELECT CASE
           WHEN `年龄` IS NULL
                AND `年龄`=0 THEN '未知'
           WHEN `年龄`<=24 THEN '学生党'
           ELSE '职场人'
       END `用户画像`,
       cate2_name,
       sum(order_num) order_num
FROM
  (SELECT user_id,
          year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),NULL)) AS `年龄`
   FROM dim.dim_silkworm_user) a
INNER JOIN
  (SELECT user_id,
          cate2_name,
          sum(order_num) order_num
   FROM
     (SELECT user_id,
             store_id,
             count(1) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub(current_date(),interval 14 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1,
               2) b1
   LEFT JOIN
     (SELECT store_id,
             get_json_object(parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category1') AS cate1_name,
             get_json_object(parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category2') AS cate2_name
      FROM dim.dim_silkworm_store) b2 ON b1.store_id=b2.store_id
   GROUP BY 1,
            2) b ON a.user_id=b.user_id
GROUP BY 1,
         2;


-- 用户top品牌

SELECT CASE
           WHEN `年龄` IS NULL
                AND `年龄`=0 THEN '未知'
           WHEN `年龄`<=24 THEN '学生党'
           ELSE '职场人'
       END `用户画像`,
       cate2_name,
       store_banner_list,
       sum(order_num) order_num
FROM
  (SELECT user_id,
          year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),NULL)) AS `年龄`
   FROM dim.dim_silkworm_user) a
INNER JOIN
  (SELECT user_id,
          store_banner_list,
          cate2_name,
          sum(order_num) order_num
   FROM
     (SELECT user_id,
             store_id,
             count(1) order_num
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub(current_date(),interval 14 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1,
               2) b1
   LEFT JOIN
     (SELECT store_id,
             store_banner_list,
             get_json_object(parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')), '$.category2') AS cate2_name
      FROM dim.dim_silkworm_store
) b2 ON b1.store_id=b2.store_id
   GROUP BY 1,
            2,
            3) b ON a.user_id=b.user_id
GROUP BY 1,
         2,
         3;



SELECT  store_banner_list,
        if(store_brand_type = 1, '大牌', '其他') store_brand_type,
        case
            when store_type = 0 then '普通店铺' 
            when store_type = 1 then '优质店铺' 
            when store_type = 2 then '大客户' 
            else '其他'
        end store_type
FROM    dim.dim_silkworm_store
where   store_banner_list not regexp 'http|null'
and     store_banner_list <> '[]'
and     store_banner_list <> ''
group by 1,
         2,
         3
;




SELECT  store_id,
        store_name,
        city_name,
        district_name,
        get_json_object(
            parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
            '$.category1'
        ) AS cate1_name, -- 一级类目
        get_json_object(
            parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
            '$.category2'xc_c
        ) AS cate2_name -- 二级类目
FROM    dim.dim_silkworm_store
where date_format(latest_promotion_time,'%Y-%m-%d')>='2025-09-01'
limit   10;



-- 用户近30天访问和下单分布
DROP VIEW IF EXISTS t;


CREATE VIEW IF NOT EXISTS t (user_id,view_days,ordnum,valid_ordnum) AS
  (SELECT b.user_id,
          view_days,
          ifnull(ordnum,0) ordnum,
                           ifnull(valid_ordnum,0) valid_ordnum
   FROM
     (SELECT user_id,
             count(dt) view_days
      FROM
        (SELECT dt,
                unnest_bitmap AS user_id
         FROM dwd.dwd_sr_traffic_viewuser_d,
              unnest_bitmap(user_ids) AS uid
         WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
         GROUP BY 1,
                  2) a
      GROUP BY 1) b
   LEFT JOIN
     (SELECT user_id,
             count(1) ordnum,
                      count(IF(order_status IN (2,8),auto_id,NULL)) valid_ordnum
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-12-01' AND '2025-12-30'
      GROUP BY 1) c ON b.user_id=c.user_id);

SELECT '访问天数' `类型`,
              count(1) `用户量`,
              min(view_days) `最小值`,
              percentile_cont(view_days,0.1) `10分位值`,
              percentile_cont(view_days,0.2) `20分位值`,
              percentile_cont(view_days,0.3) `30分位值`,
              percentile_cont(view_days,0.4) `40分位值`,
              percentile_cont(view_days,0.5) `50分位值`,
              percentile_cont(view_days,0.6) `60分位值`,
              percentile_cont(view_days,0.7) `70分位值`,
              percentile_cont(view_days,0.8) `80分位值`,
              percentile_cont(view_days,0.9) `90分位值`,
              max(view_days) `最大值`
FROM t
GROUP BY 1
UNION ALL
SELECT '下单量' `类型`,
             count(1) `用户量`,
             min(ordnum) `最小值`,
             percentile_cont(ordnum,0.1) `10分位值`,
             percentile_cont(ordnum,0.2) `20分位值`,
             percentile_cont(ordnum,0.3) `30分位值`,
             percentile_cont(ordnum,0.4) `40分位值`,
             percentile_cont(ordnum,0.5) `50分位值`,
             percentile_cont(ordnum,0.6) `60分位值`,
             percentile_cont(ordnum,0.7) `70分位值`,
             percentile_cont(ordnum,0.8) `80分位值`,
             percentile_cont(ordnum,0.9) `90分位值`,
             max(ordnum) `最大值`
FROM t
GROUP BY 1
UNION ALL
SELECT '有效订单量' `类型`,
               count(1) `用户量`,
               min(valid_ordnum) `最小值`,
               percentile_cont(valid_ordnum,0.1) `10分位值`,
               percentile_cont(valid_ordnum,0.2) `20分位值`,
               percentile_cont(valid_ordnum,0.3) `30分位值`,
               percentile_cont(valid_ordnum,0.4) `40分位值`,
               percentile_cont(valid_ordnum,0.5) `50分位值`,
               percentile_cont(valid_ordnum,0.6) `60分位值`,
               percentile_cont(valid_ordnum,0.7) `70分位值`,
               percentile_cont(valid_ordnum,0.8) `80分位值`,
               percentile_cont(valid_ordnum,0.9) `90分位值`,
               max(valid_ordnum) `最大值`
FROM t
GROUP BY 1;


-- 到店用户
SELECT a.user_id,
       a.create_time,
       a.update_time,
       a.daren_score,
       a.is_bind_wework,
       a.blackbox_order_num,
       a.welfare_blackbox_order_num,
       a.welfare_notes_num,
       a.xiaohongshu_notes_num,
       a.dp_notes_num,
       a.acc_rebate_amt,
       a.acc_reduce_carbon_emissions,
       a.auth_xiaohongshu_id,
       a.auth_dp_id,
       a.xiaohongshu_auth_first_time,
       a.dp_auth_first_time,
       a.xiaohongshu_cancel_auth_latest_time,
       a.dp_cancel_auth_latest_time,
       a.popup_time,
       a.xiaohongshu_first_order_time,
       a.dp_first_order_time,
       a.is_open_auto_audit,
       a.is_risk_user,
       a.status,
       a.is_open_renshen,
       a.is_finish_exam,
       a.operator_id,
       a.xiaohongshu_fans_num,
       a.dp_user_lvl,
       a.acc_welfare_rebate_amt,
       a.dp_auth_time,
       a.xiaohongshu_auth_time,
       a.welfare_timeout_time,
       a.welfare_verify_timeout_time,
       a.welfare_notes_upload_timeout_time,
       a.wework_name,
       a.wework_avatar_url,
       a.welfare_notes_first_upload_time,
       a.daren_activate_time,
       a.welfare_verify_num,
       a.dp_auth_city_id,
       a.xiaohongshu_auth_city_id,
       b.first_view_date,
       b.first_explode_view_date,
       b.first_welfare_view_date,
       a.first_order_date,
       a.first_explode_order_date,
       a.first_welfare_order_date,
       a.explore_zhanwai_order_num,
       a.dp_fans_num,
       a.auth_renshen_type,
       a.verify_renshen_type,
       a.latest_bind_xiaohongshu_user_id,
       a.first_explode_order_time,
       b.first_bargain_view_date,
       a.first_bargain_order_date
FROM
  (SELECT user_id,
          create_time,
          update_time,
          daren_score,
          is_bind_wework,
          blackbox_order_num,
          welfare_blackbox_order_num,
          welfare_notes_num,
          xiaohongshu_notes_num,
          dp_notes_num,
          acc_rebate_amt,
          acc_reduce_carbon_emissions,
          auth_xiaohongshu_id,
          auth_dp_id,
          xiaohongshu_auth_first_time,
          dp_auth_first_time,
          xiaohongshu_cancel_auth_latest_time,
          dp_cancel_auth_latest_time,
          popup_time,
          xiaohongshu_first_order_time,
          dp_first_order_time,
          is_open_auto_audit,
          is_risk_user,
          status,
          is_open_renshen,
          is_finish_exam,
          operator_id,
          xiaohongshu_fans_num,
          dp_user_lvl,
          acc_welfare_rebate_amt,
          dp_auth_time,
          xiaohongshu_auth_time,
          welfare_timeout_time,
          welfare_verify_timeout_time,
          welfare_notes_upload_timeout_time,
          wework_name,
          wework_avatar_url,
          welfare_notes_first_upload_time,
          daren_activate_time,
          welfare_verify_num,
          dp_auth_city_id,
          xiaohongshu_auth_city_id,
          first_view_date,
          first_explode_view_date,
          first_welfare_view_date,
          first_order_date,
          first_explode_order_date,
          first_welfare_order_date,
          explore_zhanwai_order_num,
          dp_fans_num,
          auth_renshen_type,
          verify_renshen_type,
          latest_bind_xiaohongshu_user_id,
          first_explode_order_time,
          first_bargain_view_date,
          first_bargain_order_date
   FROM dim.dim_silkworm_explore_daren_cleanse
   WHERE first_view_date IS NULL
     AND first_order_date IS NOT NULL
     OR (first_view_date IS NOT NULL
         AND first_order_date IS NOT NULL
         AND first_view_date>first_order_date)) a
LEFT JOIN
  (SELECT user_id,
          min(date(create_time)) first_view_date,
          min(if(promotion_type IN (1,4),date(create_time),NULL)) first_explode_view_date,
          min(if(promotion_type IN (2,3),date(create_time),NULL)) first_welfare_view_date,
          min(if(promotion_type IN (5,6,8),date(create_time),NULL)) first_bargain_view_date
   FROM dwd.dwd_sr_silkworm_explore_order
   GROUP BY 1) b ON a.user_id=b.user_id;



DROP VIEW IF EXISTS stat_info;


CREATE VIEW IF NOT EXISTS stat_info (tatistics_date, county_id, activity_id, platform_name, app_version, activity_type, store_platform, is_brand, hand_price, rebate_rate, user_distance, user_type, clc_date, clc_county_id, clc_activity_id, clc_platform_name, clc_app_version, clc_activity_type, clc_store_platform, clc_is_brand, clc_hand_price, clc_rebate_rate, clc_user_distance, clc_user_type, expouse_num, expouse_uv, clc_num, clc_uv) AS
  (SELECT a.tatistics_date,
          a.county_id,
          a.activity_id,
          a.platform_name,
          a.app_version,
          a.activity_type,
          a.store_platform,
          a.is_brand,
          a.hand_price,
          a.rebate_rate,
          a.user_distance,
          a.user_type,
          b.statistics_date clc_date,
          b.county_id clc_county_id,
          b.activity_id clc_activity_id,
          b.platform_name clc_platform_name,
          b.app_version clc_app_version,
          b.activity_type clc_activity_type,
          b.store_platform clc_store_platform,
          b.is_brand clc_is_brand,
          b.hand_price clc_hand_price,
          b.rebate_rate clc_rebate_rate,
          b.user_distance clc_user_distance,
          b.user_type clc_user_type,
          a.expouse_num expouse_num,
          bitmap_union_count(a.expouse_uids) expouse_uv,
          b.clc_num,
          bitmap_union_count(b.clc_uids) clc_uv,
FROM -- 曝光统计
(SELECT date(time) AS statistics_date,
        county_id,
        activity_id,
        platform_name,
        app_version,
        activity_type,
        store_platform,
        is_brand,
        if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
        rebate_rate,
        user_distance,
        user_type,
        COUNT(*) AS expouse_num,
        bitmap_agg(user_id) AS expouse_uids
 FROM traffic_info
 WHERE event = 'Homepage_Feed_Activity_Ex'
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
          12) a
   LEFT JOIN ( -- 点击统计

              SELECT date(time) AS statistics_date,
                     county_id,
                     activity_id,
                     platform_name,
                     app_version,
                     activity_type,
                     store_platform,
                     is_brand,
                     if(mlabel_threshold_amt=0, mlabel_rebate_amt, mlabel_threshold_amt-mlabel_rebate_amt) AS hand_price,
                     rebate_rate,
                     user_distance,
                     user_type,
                     COUNT(*) AS clc_num,
                     bitmap_agg(user_id) AS clc_uids
              FROM traffic_info
              WHERE event = 'Homepage_Feed_Activity_Click'
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
                       12) b ON a.statistics_date = b.statistics_date
   AND a.county_id = b.county_id
   AND a.activity_id = b.activity_id
   AND a.platform_name = b.platform_name
   AND a.app_version = b.app_version
   AND a.activity_type = b.activity_type
   AND a.store_platform = b.store_platform
   AND a.is_brand = b.is_brand
   AND a.user_distance = b.user_distance
   AND a.user_type = b.user_type
   AND a.hand_price = b.hand_price
   AND a.rebate_rate = b.rebate_rate);



-- 上传订单号截图检测
SELECT dt,
       count(auto_id) `下单量`,
       count(if(platform_pic IS NOT NULL,auto_id,NULL)) `上传订单截图下单量`,
       count(if(order_status IN (2,8),auto_id,NULL)) `有效订单量`,
       count(if(platform_pic IS NOT NULL
                AND order_status IN (2,8),auto_id,NULL)) `上传订单截图有效订单量`
FROM
  (SELECT dt,
          order_id,
          auto_id,
          get_json_string(platform_pic_ocr_result,'$.platform_pic') AS platform_pic,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2026-03-20' AND '2026-03-25'
     AND store_promotion_id<>0) a
GROUP BY 1;


-- 新用户前3单截图上传订单号检测的用户量
SELECT 
    register_date,
    COUNT(DISTINCT a.user_id) AS `注册用户量`,
    COUNT(DISTINCT if(date(a.first_valid_order_time)<>'1970-01-01',a.user_id,null)) `有效用户量`,
    COUNT(DISTINCT IF(b.is_1st_check = 1, a.user_id, NULL)) AS `首单长传订单截图检测注册用户量`,
    COUNT(DISTINCT IF(b.is_2nd_check = 1, a.user_id, NULL)) AS `二单长传订单截图检测注册用户量`,
    COUNT(DISTINCT IF(b.is_3th_check = 1, a.user_id, NULL)) AS `三单长传订单截图检测注册用户量`
FROM (
    SELECT DATE(register_time) AS register_date, user_id,first_valid_order_time
    FROM dim.dim_silkworm_user
    WHERE DATE(register_time) BETWEEN '2025-12-01' AND '2025-12-31'
) a
LEFT JOIN (
    SELECT 
        user_id,
        MAX(IF(rk = 1 AND platform_pic_valid = 1, 1, 0)) AS is_1st_check,
        MAX(IF(rk = 2 AND platform_pic_valid = 1, 1, 0)) AS is_2nd_check,
        MAX(IF(rk = 3 AND platform_pic_valid = 1, 1, 0)) AS is_3th_check
    FROM (
        SELECT 
            user_id,
            ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_time) AS rk,
            CASE 
                WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') IS NOT NULL
                     AND GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') != '' 
                THEN 1 
                ELSE 0 
            END AS platform_pic_valid
        FROM dwd.dwd_sr_order_promotion_order
        WHERE dt BETWEEN '2025-12-01' AND '2026-03-26'
          AND store_promotion_id <> 0
          AND order_status IN (2,8)
    ) t
    WHERE rk <= 3
    GROUP BY user_id
) b ON a.user_id = b.user_id
GROUP BY register_date;




-- 新用户前3单截图上传订单号检测的订单量
SELECT a.dt,
       count(auto_id) `有效订单量`,
       count(if(rk=1,auto_id,null)) `首单量`,
       count(if(rk=2,auto_id,null)) `二单量`,
       count(if(rk=3,auto_id,null)) `三单量`,
       count(if(rk=1
                AND platform_pic_valid=1,auto_id,NULL)) `首单传截图有效订单量`,
       count(if(rk=2
                AND platform_pic_valid=1,auto_id,NULL)) `二单传截图有效订单量`,
       count(if(rk=3
                AND platform_pic_valid=1,auto_id,NULL)) `三单传截图有效订单量`
FROM
  ( SELECT dt,
           auto_id,
           user_id,
           ROW_NUMBER() OVER (PARTITION BY user_id
                              ORDER BY order_time) AS rk,
           CASE
               WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') IS NOT NULL
                    AND GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') != '' THEN 1
               ELSE 0
           END AS platform_pic_valid
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2026-03-26'
     AND store_promotion_id <> 0
     AND order_status IN (2,
                          8) ) a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id = b.user_id
AND date(b.register_time) BETWEEN '2025-12-01' AND '2025-12-31'
WHERE b.user_id IS NOT NULL
GROUP BY 1;


-- web单号检测新用户完单
SELECT a.dt,
       count(auto_id) `下单量`,
       count(if(order_status IN (2,8),auto_id,NULL)) `有效订单量`,
       count(if(order_status IN (2,8)
                AND platform_pic_valid=1,auto_id,NULL)) `传了订单号有效订单量`
FROM
  (SELECT dt,
          auto_id,
          user_id,
          CASE
              WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') IS NOT NULL
                   AND GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') != '' THEN 1
              ELSE 0
          END AS platform_pic_valid,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2026-03-26'
     AND store_promotion_id <> 0) a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id = b.user_id
AND date(b.register_time) BETWEEN '2025-12-01' AND '2025-12-31'
WHERE b.user_id IS NOT NULL
  AND a.dt BETWEEN '2025-12-01' AND '2025-12-31'
GROUP BY 1;


-- web单号检测或截图检测单号新用户完单
SELECT a.dt,
       count(if(platform_pic_valid=1,auto_id,NULL)) `传了单号订单量`,
       count(if(order_status IN (2,8)
                AND platform_pic_valid=1,auto_id,NULL)) `传了单号有效订单量`
FROM
  (SELECT dt,
          auto_id,
          user_id,
          CASE
              WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') IS NOT NULL
                   AND GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') != '' THEN 1
                   WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') IS NOT NULL
                    AND GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') != '' THEN 1
              ELSE 0
          END AS platform_pic_valid, -- 是否传了单号，order_html是自动检测 platform_pic是用户传订单截图做检测
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2025-12-01' AND '2026-03-26'
     AND store_promotion_id <> 0) a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id = b.user_id
AND date(b.register_time) BETWEEN '2025-12-01' AND '2025-12-31'
WHERE b.user_id IS NOT NULL
  AND a.dt BETWEEN '2025-12-01' AND '2025-12-31'
GROUP BY 1;


SELECT dt,
       auto_id,
       user_id,
       CASE
           WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') IS NOT NULL
                AND GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') != '' THEN 1
           WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') IS NOT NULL
                AND GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') != '' THEN 1
           ELSE 0
       END AS platform_pic_valid, -- 是否传了单号，order_html是自动检测 platform_pic是用户传订单截图做检测
       order_status
FROM dwd.dwd_sr_order_promotion_order
WHERE dt BETWEEN '2025-12-01' AND '2026-03-26'



SELECT count(*) `下单量`,
       sum(user_pay_amt) `下单金额`,
       sum(profit) `下单利润`,
       count(if(order_status IN (2,8),auto_id,NULL)) `有效下单量`,
       sum(if(order_status IN (2,8),user_pay_amt,0)) `有效下单金额`,
       sum(if(order_status IN (2,8),profit,0)) `有效下单利润`
FROM dwd.dwd_sr_order_promotion_order
WHERE dt='2026-03-11'
  AND date_format(create_time,'%Y-%m-%d %H:%i') BETWEEN '2026-03-11 11:20' AND '2026-03-11 11:35';


################################# 指定店铺周边的人和活动
-- 指定店铺定位
WITH t1 AS
  (SELECT store_id,
          store_name,
          longitude AS star_lon,
          latitude AS star_lat
   FROM dim.dim_silkworm_store
   WHERE store_id IN (4137,
                      3581,
                      4116,
                      4411,
                      3646,
                      192) -- 根据需要写店铺ID
   ),

-- 用户定位
t2 AS
  (SELECT user_id,
          province,
          city,
          county,
          address_detail,
          longitude,
          latitude
   FROM dim.dim_silkworm_user_location
   WHERE date(update_time) BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY) -- 根据需要筛选用户访问的日期 每个用户只有最近一次定位数据
   )


-- 筛选t1半径5公里内用户
select store_id `店铺ID`,
    store_name `店铺名称`,
    user_id `用户ID`,
    province `用户定位省份`,
    city `用户定位城市`,
    county `用户定位区县`,
    address_detail `用户定位地址`
from 
(select 
    store_id,
    store_name,
    user_id,
    province,
    city,
    county,
    address_detail,
    ST_Distance_Sphere(longitude, latitude, star_lon, star_lat) as distance
from t1 left join t2 on 1=1 
) a
where distance<=5000
group by 1,2,3,4,5,6,7;


-- 要计算活动的话，在外卖活动表统计好每个店铺的活动数、活动名额，和店铺关联一下就行


##########################################################################################
-- 会员用户分布

-- 会员
WITH member_info AS
  (SELECT silk_id user_id,
                  new_level,
                  is_plus
   FROM ods.ods_sr_client_vip_realtime
   WHERE new_level BETWEEN 2 AND 6),


-- 访问用户
t1 AS
  (SELECT unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt BETWEEN '2026-03-01' AND '2026-03-30'
   GROUP BY 1),


-- 完单
t2 AS
  (SELECT user_id,count(auto_id) valid_order_num
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2026-03-01' AND '2026-03-30'
     AND order_status IN (2,
                          8)
   GROUP BY 1),

-- 拉新
t3 AS
  (SELECT inviter_user_id,
          count(user_id) newuser_num
   FROM dim.dim_silkworm_user
   WHERE date(register_time) BETWEEN '2026-03-01' AND '2026-03-30'
     AND inviter_user_id<>0
   GROUP BY 1),

-- 昨日访问用户
t4 AS
  (SELECT unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt='2026-03-30'
   GROUP BY 1)



SELECT new_level `会员等级`,
       if(is_plus=0,'否','是') `是否plus`,
       count(DISTINCT a.user_id) `会员量`,
       count(DISTINCT if(t1.user_id IS NOT NULL,a.user_id,NULL)) `3月活跃会员量`,
       count(DISTINCT if(t2.user_id IS NOT NULL
                         AND t2.valid_order_num>=1,a.user_id,NULL)) `3月完单会员量`,
       count(DISTINCT if(t3.inviter_user_id IS NOT NULL
                         AND t3.newuser_num>=1,a.user_id,NULL)) `3月有拉新会员量`,
       sum(t2.valid_order_num) `3月完单量`,
       sum(t3.newuser_num) `3月拉新量`,
       count(DISTINCT if(t4.user_id IS NOT NULL,a.user_id,NULL)) `昨日活跃会员量`
FROM member_info a
LEFT JOIN t1 ON a.user_id=t1.user_id
LEFT JOIN t2 ON a.user_id=t2.user_id
LEFT JOIN t3 ON a.user_id=t3.inviter_user_id
LEFT JOIN t4 ON a.user_id=t4.user_id
GROUP BY 1,
         2;




-- 蚕豆兑换中非实名认证用户量
SELECT count(a.user_id) `蚕豆兑换用户量`,
       count(if(b.user_id_num IS NULL,a.user_id,NULL)) `未实名认证蚕豆兑换用户量`
FROM
  (SELECT user_id
   FROM dwd.dwd_sr_user_candou_exchange_record
   WHERE date(create_time)='2026-03-31'
   GROUP BY 1) a
LEFT JOIN ods.ods_sr_silkworm_user b ON a.user_id=b.user_id;


-- 未实名用户兑换金额
SELECT a.user_id,
       c.product_name,
       a.amt
FROM
  (SELECT user_id,
          product_id,
          sum(amt) amt
   FROM dwd.dwd_sr_user_candou_exchange_record
   WHERE date(create_time)='2026-03-31'
     AND status=2
   GROUP BY 1,
            2) a
INNER JOIN
  (SELECT b1.user_id
   FROM
     (SELECT user_id
      FROM dwd.dwd_sr_user_candou_exchange_record
      WHERE date(create_time)='2026-03-31'
      GROUP BY 1) b1
   LEFT JOIN ods.ods_sr_silkworm_user b2 ON b1.user_id=b2.user_id
   WHERE b2.user_id_num IS NULL) b ON a.user_id=b.user_id
LEFT JOIN dim.dim_candou_exchange_product c ON a.product_id=c.product_id ;


###########################


店铺热卖（新版本该功能上线）
订单截图检测（增加风控力度，可能误伤范围扩大）


目前已知，报名转化率环比下降（68.8%->65%）


-- 昨日下单今日第二步超时取消订单明细
select
-- date(cancel_time),
-- count(if(platform_pic_valid=1,auto_id,null)) `超时取消订单量`,
-- count(distinct if(platform_pic_valid=1,user_id,null)) `超时取消用户量`
*
from
(SELECT   order_time `下单时间`,
          auto_id,
          CONCAT('单',order_id) `订单ID`,
          user_id `用户ID`,
          CASE
              WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') IS NOT NULL
                   AND GET_JSON_STRING(platform_pic_ocr_result, '$.order_html') != '' THEN 1
                   WHEN GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') IS NOT NULL
                    AND GET_JSON_STRING(platform_pic_ocr_result, '$.platform_pic') != '' THEN 1
              ELSE 0
          END AS platform_pic_valid, -- 是否传了单号，order_html是自动检测 platform_pic是用户传订单截图做检测
          cast(FROM_UNIXTIME(GET_JSON_STRING(platform_order_detail, '$.cancel_time'),'%Y-%m-%d %H:%i:%s') as string) cancel_time
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt='2026-04-08'
     and order_status=5) a
where date(cancel_time)='2026-04-09'
and platform_pic_valid=1
group by 1;


-- 日活和名额

SELECT coalesce(a.city_name,b.city_name) `城市`,
       coalesce(a.county_name,b.county_name) `区县`,
       avg_pro_num `日均活动数`,
       avg_quota `日均活动名额`,
       avg_order_num `日均报名订单量`,
       avg_valid_ordnum `日均有效订单量`,
       avg_uv `日均UV`
FROM -- 日均活动指标

  (SELECT city_name,
          county_name,
          round(avg(pro_num),0) avg_pro_num,
          round(avg(quota),0) avg_quota,
          round(avg(order_num),0) avg_order_num,
          round(avg(valid_order_num),0) avg_valid_ordnum
   FROM -- 近90天每日活动和订单

     (SELECT dt,
             city_name,
             county_name,
             count(promotion_id) pro_num,
             sum(promotion_quota) quota,
             sum(order_num) order_num,
             sum(valid_order_num) valid_order_num
      FROM dws.dws_sr_store_takeawaypro_statis_d
      WHERE dt BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND city_name IN ('上海市',
                          '杭州市',
                          '成都市',
                          '广州市',
                          '深圳市',
                          '北京市',
                          '苏州市',
                          '南京市',
                          '武汉市',
                          '合肥市')
      GROUP BY 1,
               2,
               3) a1
   GROUP BY 1,
            2) a
LEFT JOIN -- 近90天日均UV

  (SELECT b2.city_name,
          b2.county_name,
          round(avg(uv),0) avg_uv
   FROM
     (SELECT dt,
             cast(county_id AS int) county_id,
             bitmap_union_count(user_ids) uv
      FROM dwd.dwd_sr_traffic_viewuser_d
      WHERE dt BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1,
               2) b1
   LEFT JOIN dim.dim_silkworm_county b2 ON b1.county_id=b2.county_id
   GROUP BY 1,
            2) b ON a.city_name=b.city_name
AND a.county_name=b.county_name ;




-- 美团专版订单占比
SELECT  dt,
        sum(if(store_platform_type = 1, 1, 0)) `美团订单量`,
        sum(if(order_type = 12, 1, 0)) `美团专版订单量`,
        sum(if(order_type = 12, 1, 0)) / sum(if(store_platform_type = 1, 1, 0)) rate
FROM    dwd.dwd_sr_order_promotion_order
WHERE   dt between '2026-03-09'
and     '2026-04-09'
and     order_status in (2, 8)
group by 1;



SELECT 
  b.province_name `省份`,
  `城市`,
    `区县`,
    `昨日活跃用户量`
FROM
(SELECT 
       city_name `城市`,
       county_name `区县`,
       bitmap_union_count(view_uids) `昨日活跃用户量`
FROM dws.dws_sr_user_login_d
WHERE statistics_date=date_sub(current_date(),interval 1 DAY)
GROUP BY 1,
         2) a
left join dim.dim_silkworm_county b on b.county_name=a.`区县`

SELECT c.province_name `省份`,
       coalesce(a.city_name,b.city_name) `城市`,
       coalesce(a.county_name,b.county_name) `区县`,
       a.`活动名额`,
       b.`昨日活跃用户量`
FROM
  (SELECT city_name,
          county_name,
          sum(promotion_quota) `活动名额`
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt=date_sub(current_date(),interval 1 DAY)
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT city_name,
          county_name,
          bitmap_union_count(view_uids) `昨日活跃用户量`
   FROM dws.dws_sr_user_login_d
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)
   GROUP BY 1,
            2) b ON a.city_name=b.city_name
AND a.county_name=b.county_name
LEFT JOIN dim.dim_silkworm_county c ON a.city_name=c.city_name
AND a.county_name=c.county_name



-- 分平台有效订单
SELECT `总有效订单量`,
       CASE
           WHEN a.`总有效订单量` BETWEEN 1 AND 2 THEN '1-2单'
           WHEN a.`总有效订单量` BETWEEN 3 AND 4 THEN '3-4单'
           WHEN a.`总有效订单量` BETWEEN 5 AND 6 THEN '5-6单'
           WHEN a.`总有效订单量`>=7 THEN '7单及以上'
       END `有效订单量分布`,
       count(a.user_id) `用户量`,
       sum(`美团订单量`) `美团订单量`,
       sum(`美团专版订单量`) `美团专版订单量`,
       sum(`饿了么订单量`) `饿了么订单量`,
       sum(`饿了么专版订单量`)
FROM
  (SELECT user_id,
          count(1) `总有效订单量`,
          sum(if(store_platform_type = 1, 1, 0)) `美团订单量`,
          sum(if(order_type = 12, 1, 0)) `美团专版订单量`,
          sum(if(store_platform_type = 2, 1, 0)) `饿了么订单量`,
          sum(if(order_type = 13, 1, 0)) `饿了么专版订单量`
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2026-03-09' AND '2026-03-15' -- 近7天（被关联的b表 美团可取到更多用户）
AND order_status IN (2,
                     8)
   GROUP BY 1) a
GROUP BY 1,2;


-- 美团订单（目前只能取美团订单）
SELECT order_num `订单量`,
       CASE
           WHEN order_num BETWEEN 1 AND 2 THEN '1-2单'
           WHEN order_num BETWEEN 3 AND 4 THEN '3-4单'
           WHEN order_num BETWEEN 5 AND 6 THEN '5-6单'
           WHEN order_num>=7 THEN '7单及以上'
       END `订单量分布`,
       count(silk_id) `用户量`,
       sum(order_num) `订单量`
FROM
  (SELECT silk_id,
          count(DISTINCT order_no) order_num
   FROM dwd.dwd_silkworm_fp_client_feature
   WHERE date(order_time) BETWEEN '2026-03-09' AND '2026-03-15'
     AND platform=1
     AND (silk_id IS NOT NULL
          AND silk_id<>0)
   GROUP BY 1) a
GROUP BY 1,
         2;


-- 同用户在小蚕和美团 美团单量差异
SELECT a.`总有效订单量` `小蚕有效订单量`,
       ifnull(b.order_num,0) `美团平台订单量`,
       count(DISTINCT a.user_id) `小蚕用户量`,
       sum(`美团订单量`) `小蚕美团订单量`,
       ifnull(sum(order_num),0) `美团订单量`
FROM -- 小蚕美团订单

  (SELECT user_id,
          count(1) `总有效订单量`,
          sum(if(store_platform_type = 1, 1, 0)) `美团订单量`,
          sum(if(order_type = 12, 1, 0)) `美团专版订单量`,
          sum(if(store_platform_type = 2, 1, 0)) `饿了么订单量`,
          sum(if(order_type = 13, 1, 0)) `饿了么专版订单量`
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2026-03-09' AND '2026-03-15' -- 近7天（被关联的b表 美团可取到更多用户）
AND order_status IN (2,
                     8)
   GROUP BY 1) a
LEFT JOIN -- 美团订单

  (SELECT silk_id,
          count(DISTINCT order_no) order_num
   FROM dwd.dwd_silkworm_fp_client_feature
   WHERE date(order_time) BETWEEN '2026-03-09' AND '2026-03-15'
     AND platform=1
     AND (silk_id IS NOT NULL
          AND silk_id<>0)
   GROUP BY 1) b ON a.user_id=b.silk_id
GROUP BY 1,
         2;





