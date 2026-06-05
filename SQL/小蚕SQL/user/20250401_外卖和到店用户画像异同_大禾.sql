外卖和到店用户画像异同，重合度

-- 霸王餐下单用户
DROP VIEW IF EXISTS bwc_user;


CREATE VIEW IF NOT EXISTS bwc_user (user_id,age,gender,is_order_user,province_name,city_name,county_name) AS
  (SELECT a.user_id,
          year(curdate())-IF(length(user_id_num)=18,
                                                 substring(user_id_num,7,4),
                                                 IF(length(user_id_num)=15,
                                                                        concat('19',substring(user_id_num,7,2)),
                                                                        NULL)) AS age,
                            CASE IF(length(user_id_num)=18,
                                                        cast(substring(user_id_num,17,1) AS UNSIGNED)%2,
                                                                                                     IF(length(user_id_num)=15,
                                                                                                                            cast(substring(user_id_num,15,1) AS UNSIGNED)%2,
                                                                                                                                                                         3))
                                WHEN 1 THEN '男'
                                WHEN 0 THEN '女'
                                ELSE '未知'
                            END AS gender,
                            IF(date_format(a.first_valid_order_time,'%Y-%m-%d')>='2024-06-18',
                                                                      1,
                                                                      0) is_order_user,
                                                                         coalesce(b.province_name,'其他') province_name,
                                                                                                        coalesce(b.city_name,'其他') city_name,
                                                                                                                                   coalesce(b.county_name,'其他') county_name
   FROM dim.dim_silkworm_user a
   LEFT JOIN dim.dim_silkworm_county b ON a.county_id=b.county_id);



-- 到店完单用户
DROP VIEW IF EXISTS explore_user;


CREATE VIEW IF NOT EXISTS explore_user (user_id) AS
  (SELECT user_id
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2024-06-18' AND date_sub(current_date(),interval 1 DAY)
     AND store_name NOT regexp '测试'
     AND status IN (5,
                    11,
                    14,
                    17,
                    18,
                    19,
                    22,
                    23,
                    28) -- 20250325 修改状态 修改人：dahe

   GROUP BY user_id);


-- 年龄和性别
SELECT CASE
           WHEN age IS NULL THEN '未知'
           WHEN age BETWEEN 0 AND 16 THEN '<=16岁'
           WHEN age BETWEEN 17 AND 22 THEN '17~22岁'
           WHEN age BETWEEN 23 AND 28 THEN '23~28岁'
           WHEN age BETWEEN 29 AND 34 THEN '29~34岁'
           WHEN age BETWEEN 35 AND 40 THEN '35~40岁'
           WHEN age BETWEEN 41 AND 46 THEN '41~46岁'
           ELSE '>=47岁'
       END `年龄段`,
       gender `性别`,
       count(a.user_id) `霸王餐完单用户量`,
       count(if(b.user_id IS NOT NULL,a.user_id,NULL)) `到店完单用户量`
FROM bwc_user a
LEFT JOIN explore_user b ON a.user_id=b.user_id
WHERE a.is_order_user=1
GROUP BY 1,
         2;


-- 杭州完单用户
SELECT county_name,
       CASE
           WHEN age IS NULL THEN '未知'
           WHEN age BETWEEN 0 AND 16 THEN '<=16岁'
           WHEN age BETWEEN 17 AND 22 THEN '17~22岁'
           WHEN age BETWEEN 23 AND 28 THEN '23~28岁'
           WHEN age BETWEEN 29 AND 34 THEN '29~34岁'
           WHEN age BETWEEN 35 AND 40 THEN '35~40岁'
           WHEN age BETWEEN 41 AND 46 THEN '41~46岁'
           ELSE '>=47岁'
       END `年龄段`,
       gender `性别`,
       count(a.user_id) `霸王餐完单用户量`,
       count(if(b.user_id IS NOT NULL,a.user_id,NULL)) `到店完单用户量`
FROM bwc_user a
LEFT JOIN explore_user b ON a.user_id=b.user_id
WHERE a.is_order_user=1
  AND city_name='杭州市'
GROUP BY 1,
         2,
         3;


-- 用户重合度
SELECT 
       count(a.user_id) `到店完单用户量`,
       count(if(b.user_id IS NOT NULL,a.user_id,NULL)) `霸王餐完单用户量`
FROM explore_user a
LEFT JOIN bwc_user b ON a.user_id=b.user_id and b.is_order_user=1
;




-- 霸王餐订单
DROP VIEW IF EXISTS bwc_order;


-- CREATE VIEW IF NOT EXISTS bwc_order (cate2_name,user_id) AS
--   (SELECT CASE
--               WHEN sub_category_type = 1 THEN '包子粥铺'
--               WHEN sub_category_type = 2 THEN '快餐简餐'
--               WHEN sub_category_type = 3 THEN '甜品饮品'
--               WHEN sub_category_type = 4 THEN '炸串小吃'
--               WHEN sub_category_type = 5 THEN '火锅烧烤'
--               WHEN sub_category_type = 6 THEN '汉堡西餐'
--               WHEN sub_category_type = 7 THEN '零售'
--               WHEN sub_category_type = 8 THEN '水果鲜花'
--               WHEN sub_category_type = 9 THEN '成人用品'
--               ELSE '其他'
--           END AS cate2_name,
--           user_id
--    FROM
--      (SELECT user_id,
--              store_id
--       FROM dwd.dwd_sr_order_promotion_order
--       WHERE date_format(order_time,'%Y-%m-%d') BETWEEN '2024-06-18' AND '2025-04-06'
--         AND order_status IN (2,
--                              8)
--       GROUP BY 1,
--                2) a
--    LEFT JOIN dim.dim_silkworm_store b ON a.store_id=b.store_id
--    GROUP BY 1,
--             2);

CREATE VIEW IF NOT EXISTS bwc_order (user_id,user_pay_amt) AS
  (SELECT user_id,
             user_pay_amt
      FROM dwd.dwd_sr_order_promotion_order
      WHERE date_format(order_time,'%Y-%m-%d') BETWEEN '2024-06-18' AND '2025-04-06'
        AND order_status IN (2,
                             8)
 );



-- 到店订单
DROP VIEW IF EXISTS exp_order;


-- CREATE VIEW IF NOT EXISTS exp_order ( user_id,cate2_name) AS
--   (SELECT user_id ,
--           cate2_name
--    FROM -- 订单

--      (SELECT user_id ,
--              store_promotion_id
--       FROM dwd.dwd_sr_silkworm_explore_order
--       WHERE dt BETWEEN '2024-06-18' AND date_sub(current_date(),interval 1 DAY) -- 此为示例，需根据触达成功时间来筛选

--         AND status IN (5,
--                        19,
--                        11,
--                        14,
--                        17,
--                        18,
--                        22,
--                        23,
--                        28)
--       GROUP BY 1,
--                2 ) a
--    LEFT JOIN -- 活动

--      (SELECT promotion_id ,
--              CASE WHEN sub_category_type=1 THEN '包子粥铺' WHEN sub_category_type=2 THEN '汉堡西餐' WHEN sub_category_type=3 THEN '火锅烧烤' WHEN sub_category_type=4 THEN '快餐简餐' WHEN sub_category_type=5 THEN '理发/男士' WHEN sub_category_type=6 THEN '亲子/乐园' WHEN sub_category_type=7 THEN '水果生鲜' WHEN sub_category_type=8 THEN '甜品饮品' WHEN sub_category_type=9 THEN '休闲/玩乐' WHEN sub_category_type=10 THEN '炸串小吃' WHEN sub_category_type=11 THEN '正餐/多人餐' ELSE '其他' END AS cate2_name
--       FROM dwd.dwd_sr_silkworm_explore_promotion
--       WHERE dt BETWEEN '2024-06-01' AND date_sub(current_date(),interval 1 DAY) ) b ON a.store_promotion_id=b.promotion_id
--    GROUP BY 1,
--             2);

CREATE VIEW IF NOT EXISTS exp_order ( user_id,price_interval) AS
  (SELECT user_id,
          ifnull(if(if(b.promotion_type in (5,6),2,1) =1,(b.pay_amt-b.rebate_price),b.bargain_base_price),0) as price_interval
   FROM -- 订单

     (SELECT user_id,
             store_promotion_id
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN '2024-06-18' AND date_sub(current_date(),interval 1 DAY) -- 此为示例，需根据触达成功时间来筛选
        -- and user_id in (923592157) -- 验数
        AND status IN (5,
                       19,
                       11,
                       14,
                       17,
                       18,
                       22,
                       23,
                       28)
      GROUP BY 1,
               2 ) a
   LEFT JOIN -- 活动

     (SELECT promotion_id ,
             bargain_base_price,
             pay_amt,
             rebate_price,
             promotion_type
      FROM dwd.dwd_sr_silkworm_explore_promotion
      WHERE dt BETWEEN '2024-06-01' AND date_sub(current_date(),interval 1 DAY) 
        and promotion_type in (1,4,5,6)
        -- and promotion_id in (286624,272667) -- 验数
        ) b ON a.store_promotion_id=b.promotion_id
     	
        
   GROUP BY 1,
            2);






-- 分品类下单
select
	a.cate2_name `霸王餐二级品类`,
	b.cate2_name as `到店二级品类`,
	CASE
           WHEN age IS NULL THEN '未知'
           WHEN age BETWEEN 0 AND 16 THEN '<=16岁'
           WHEN age BETWEEN 17 AND 22 THEN '17~22岁'
           WHEN age BETWEEN 23 AND 28 THEN '23~28岁'
           WHEN age BETWEEN 29 AND 34 THEN '29~34岁'
           WHEN age BETWEEN 35 AND 40 THEN '35~40岁'
           WHEN age BETWEEN 41 AND 46 THEN '41~46岁'
           ELSE '>=47岁'
       END `年龄段`,
	c.gender `性别`,
	count(distinct a.user_id) `霸王餐下单用户量`,
	count(distinct if(b.user_id is not null,a.user_id,null) `到店下单用户量`
from bwc_order a
full join exp_order b on a.user_id=b.user_id
left join bwc_user c on a.user_id=c.user_id
where c.is_order_user=1
group by 1,2,3,4;


-- 霸王餐用户支付金额分位值
select
	 percentile_cont(user_pay_amt,0.1) `10分位`,
	 percentile_cont(user_pay_amt,0.2) `20分位`,
	 percentile_cont(user_pay_amt,0.3) `30分位`,
	 percentile_cont(user_pay_amt,0.4) `40分位`,
	 percentile_cont(user_pay_amt,0.5) `50分位`,
	 percentile_cont(user_pay_amt,0.6) `60分位`,
	 percentile_cont(user_pay_amt,0.7) `70分位`,
	 percentile_cont(user_pay_amt,0.8) `80分位`,
	 percentile_cont(user_pay_amt,0.9) `90分位`
from bwc_order;


-- 到店用户支付金额分位值
select
	 percentile_cont(price_interval,0.1) `10分位`,
	 percentile_cont(price_interval,0.2) `20分位`,
	 percentile_cont(price_interval,0.3) `30分位`,
	 percentile_cont(price_interval,0.4) `40分位`,
	 percentile_cont(price_interval,0.5) `50分位`,
	 percentile_cont(price_interval,0.6) `60分位`,
	 percentile_cont(price_interval,0.7) `70分位`,
	 percentile_cont(price_interval,0.8) `80分位`,
	 percentile_cont(price_interval,0.9) `90分位`
    -- *
from exp_order
-- where user_id=923592157 -- 验数
;



-- 价格
SELECT CASE
           WHEN a.user_pay_amt<=18 THEN '18元及以下'
           WHEN a.user_pay_amt>18
                AND a.user_pay_amt<=21.9 THEN '19-22元'
           WHEN a.user_pay_amt>21.9
                AND a.user_pay_amt<=25.3 THEN '23-25元'
           WHEN a.user_pay_amt>25.3
                AND a.user_pay_amt<=28.98 THEN '26-29元'
           WHEN a.user_pay_amt>28.98 THEN '29元以上'
       END `霸王餐支付金额`,
       CASE
           WHEN b.price_interval<=2 THEN '2元及以下'
           WHEN a.user_pay_amt>2
                AND a.user_pay_amt<=5 THEN '3-5元'
           WHEN a.user_pay_amt>5
                AND a.user_pay_amt<=13 THEN '6-13元'
           WHEN a.user_pay_amt>13
                AND a.user_pay_amt<=21 THEN '14-21元'
           WHEN a.user_pay_amt>21
                AND a.user_pay_amt<=34 THEN '22-34元'
           WHEN a.user_pay_amt>34
                AND a.user_pay_amt<=50 THEN '35-50元'
           WHEN a.user_pay_amt>50 THEN '50元以上'
       END `到店支付金额`,
       CASE
           WHEN age IS NULL THEN '未知'
           WHEN age BETWEEN 0 AND 16 THEN '<=16岁'
           WHEN age BETWEEN 17 AND 22 THEN '17~22岁'
           WHEN age BETWEEN 23 AND 28 THEN '23~28岁'
           WHEN age BETWEEN 29 AND 34 THEN '29~34岁'
           WHEN age BETWEEN 35 AND 40 THEN '35~40岁'
           WHEN age BETWEEN 41 AND 46 THEN '41~46岁'
           ELSE '>=47岁'
       END `年龄段`,
       c.gender `性别`,
       count(DISTINCT a.user_id) `霸王餐下单用户量`,
       count(distinct if(b.user_id is not null,a.user_id,null)) `到店下单用户量`
FROM bwc_order a
FULL JOIN exp_order b ON a.user_id=b.user_id
LEFT JOIN bwc_user c ON a.user_id=c.user_id
WHERE c.is_order_user=1
GROUP BY 1,
         2,
         3,
         4;



因无法获取用户的准确分组，5个人群圈选后创建的运营策略配置后，判断用户是否领红包（红包ID：377），圈选出以下人群：
● 预流失无领取红包用户
● 高价值沉默无领取红包用户
● 中价值沉默无领取红包用户
● 沉睡低频无领取红包用户



















































