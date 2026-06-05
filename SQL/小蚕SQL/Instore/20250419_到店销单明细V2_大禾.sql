=========== 销单明细 探店

-- 探店支付订单明细
WITH t1 AS
  (SELECT store_promotion_id ,
          pay_amt AS actual_pay_amt ,
          order_id ,
          if(promotion_type = 1,pay_time,create_time) AS pay_time ,
          verify_time ,
          status ,
          real_rebate_amt
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 14 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND date_format(pay_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY)),


-- 探店活动明细
t2 AS
  (SELECT promotion_type,
          begin_date,
          promotion_id,
          bd_id,
          sub_category_type,
          platform,
          promotion_request,
          promotion_category,
          begin_time,
          tot_promotion_quota,
          combo_id,
          store_id,
          group_amt,
          rebate_price,
          hand_price,
          cost_price,
          net_cost_price,
          recurring_promotion_id,
          id,
          actual_begin_time,
          price_interval
   FROM
     (SELECT promotion_type,
             left(begin_time,10) AS begin_date ,
             promotion_id ,
             bd_id ,
             CASE WHEN sub_category_type = 0 THEN '未知' WHEN sub_category_type = 1 THEN '包子粥铺' WHEN sub_category_type = 2 THEN '汉堡西餐' WHEN sub_category_type = 3 THEN '火锅烧烤' WHEN sub_category_type = 4 THEN '快餐简餐' WHEN sub_category_type = 5 THEN '理发/男士' WHEN sub_category_type = 6 THEN '亲子/乐园' WHEN sub_category_type = 7 THEN '水果生鲜' WHEN sub_category_type = 8 THEN '甜品饮品' WHEN sub_category_type = 9 THEN '休闲/玩乐' WHEN sub_category_type = 10 THEN '炸串小吃' WHEN sub_category_type = 11 THEN '正餐/多人餐' END AS sub_category_type ,
CASE WHEN demand_promotion_type = 0 THEN '无要求' WHEN demand_promotion_type = 1 THEN '大众点评' WHEN demand_promotion_type = 2 THEN '小红书' END AS platform ,
CASE WHEN demand_promotion_type = 0 THEN '无要求' WHEN demand_promotion_type = 1 THEN demand_dp_user_lvl WHEN demand_promotion_type = 2 THEN demand_xiaohongshu_fans_num END AS promotion_request ,
CASE WHEN demand_xiaohongshu_fans_num >= 1000
      OR demand_dp_user_lvl >5 THEN '高级' ELSE '素人' END AS promotion_category ,
                                                          begin_time ,
                                                          tot_promotion_quota ,
                                                          combo_id ,
                                                          store_id ,
                                                          pay_amt AS group_amt ,
                                                          rebate_price ,
                                                          pay_amt - rebate_price AS hand_price ,
                                                          cost_price ,
                                                          net_cost_price ,
                                                          recurring_promotion_id ,
                                                          if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) AS id ,
                                                          if(begin_time>putaway_time,begin_time,putaway_time) AS actual_begin_time,
                                                          -- 团购价价格段
                                                          CASE WHEN pay_amt <30 THEN '0-30' WHEN pay_amt >=30
      AND pay_amt <60 THEN '30-60' WHEN pay_amt >=60
      AND pay_amt <90 THEN '60-90' WHEN pay_amt >=90
      AND pay_amt <120 THEN '90-120' WHEN pay_amt >=120 THEN '120+' END price_interval,
                                                                        city_code AS county_id
      FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE promotion_type IN (1,
                         4)
AND date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 50 DAY) AND date_sub(current_date(),interval 1 DAY)
AND date_format(begin_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)) a 
-- 到店已开通业务城市
INNER JOIN
(SELECT b1.county_id,
        b1.city_name
 FROM dim.dim_silkworm_county b1
 INNER JOIN dim.dim_silkworm_explore_city b2 ON b1.city_name=b2.city_name
 AND b2.province_name<>'新疆维吾尔族自治区'
 AND b2.status=1
 AND b2.promotion_type IN ('101',
                           '111',
                           '100',
                           '1')) b ON a.county_id=b.county_id),


-- 到店店铺属性
t3 AS
  (SELECT county_name ,
          business_district ,
          a.store_id ,
          address_detail ,
          store_name ,
          city_name ,
          longitude ,
          latitude
   FROM dim.dim_silkworm_explore_store a
   INNER JOIN t2 ON a.store_id=t2.store_id),


-- 套餐
t4 AS
  (SELECT a.combo_id ,
          combo_name
   FROM dwd.dwd_sr_silkworm_explore_combo a
   INNER JOIN t2 ON a.combo_id=t2.combo_id),


-- 浏览
t5 AS
  (SELECT statistics_date ,
          user_id ,
          activity_id
   FROM dws.dws_sr_traffic_user_d
   WHERE date_format(statistics_date,'%Y-%m-%d') between date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND if_view_storediscovery > 0),


-- 循环活动首次发布时间
t51 AS
  (SELECT id ,
          min(left(begin_time,10)) AS first_begin_time
   FROM
     (SELECT if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) AS id ,
             begin_time
      FROM dwd.dwd_sr_silkworm_explore_promotion
      WHERE recurring_promotion_id IN
          (SELECT DISTINCT recurring_promotion_id
           FROM t2)
        OR promotion_id IN
          (SELECT DISTINCT promotion_id
           FROM t2)) a
   GROUP BY 1),


-- 活动累计核销&完单
t52 AS
  (SELECT t2.id ,
          count(CASE WHEN left(verify_time,10)= left(begin_time,10) THEN order_id END) AS hx_order_num ,
          count(CASE WHEN status IN (5,19,20,35)
                AND left(finish_time,10)= left(begin_time,10)THEN order_id END) AS finish_order_num
   FROM t2
   LEFT JOIN
   -- 探店活动订单
     (SELECT store_promotion_id,
             order_id,
             verify_time,
             finish_time,
             status
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE promotion_type IN (1,
                               4)
        AND date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)) a ON t2.promotion_id = a.store_promotion_id
   GROUP BY 1),


-- 近7天店铺3公里内访问用户量
t53 AS
  (SELECT store_id,
          count(DISTINCT user_id) unum
   FROM
     (SELECT user_id,
             get_json_string(DATA,'$.store_id') AS store_id,
             get_json_string(DATA,'$.store_distance')/1000 store_distance
      FROM ods.ods_sr_event_log
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND event_name='StoreDiscovery_Activity_Details_Ex'
        AND user_id regexp '^[0-9]{1,10}$'
      GROUP BY 1,
               2,
               3) a
   WHERE store_distance<=3
   GROUP BY 1),


-- 结果数据集
t6 as (
select 
        begin_date as '支付日期'
       ,price_interval `价格区间`
       ,store_id
       ,combo_id as '套餐ID'
       ,recurring_promotion_id
       ,promotion_id as '活动ID'
       ,element_at(array_remove(array_agg(store_name),0),1) as '店铺名称'
       ,element_at(array_remove(array_agg(city_name),0),1) as city
       ,element_at(array_remove(array_agg(county_name),0),1) as '区县'
       ,element_at(array_remove(array_agg(business_district),0),1) as '商圈'
       ,element_at(array_remove(array_agg(address_detail),0),1) as '店铺地址'
       ,coalesce(element_at(array_remove(array_agg(combo_name),0),1),'') as '套餐名称'
       ,element_at(array_remove(array_agg(sub_category_type),0),1) as '二级类目'
       ,element_at(array_remove(array_agg(platform),0),1) as '平台'
       ,sum(promotion_request) as '活动要求'
       ,element_at(array_remove(array_agg(promotion_category),0),1) as '活动分类'
       ,element_at(array_remove(array_agg(begin_time),0),1) as '首次发布活动时间'
       ,coalesce(element_at(array_remove(array_agg(user_nickname),0),1),'') as user_nickname
       ,sum(group_amt) as '团购价'
       ,sum(cost_price) as '成本价(含笔记)'
       ,sum(net_cost_price) as '成本价(不含笔记)'
       ,sum(rebate_price) as '返利金额'
       ,sum(hand_price) as '到手价'
       ,sum(tot_promotion_quota) as '活动总名额'
       ,sum(pay_promotion_quota) as '支付名额(不含退款)'
       ,sum(tot_pay_promotion_quota) as '支付名额(含退款)'
       ,sum(gmv) as 'GMV'
       ,sum(hx_promotion_quota) as '累计核销名额数'
       ,sum(finish_promotion_quota) as '累计完单名额数'
       ,sum(acc_group_amt) as '累计团购价'
       ,sum(uv) as '访问UV'
from (
select distinct date_format(pay_time,'%Y-%m-%d') begin_date
       ,price_interval
       ,t2.store_id
       ,t2.combo_id
       ,t2.recurring_promotion_id
       ,t2.promotion_id
       ,store_name
       ,city_name
       ,county_name
       ,business_district
       ,address_detail
       ,combo_name
       ,sub_category_type
       ,platform
       ,promotion_request
       ,promotion_category
       ,first_begin_time as begin_time
       ,user_nickname
       ,group_amt
       ,rebate_price
       ,hand_price
       ,tot_promotion_quota
       ,0 as pay_promotion_quota
       ,0 as tot_pay_promotion_quota
       ,0 as gmv
       ,0 as acc_group_amt
       ,hx_order_num as hx_promotion_quota
       ,finish_order_num as finish_promotion_quota
       ,0 as uv
       ,cost_price -- 成本价(含笔记)
       ,net_cost_price  --成本价(不含笔记)
from t1
inner join t2 on t2.promotion_id=t1.store_promotion_id
left join dim.dim_silkworm_staff a on t2.bd_id = a.bd_id 
left join t3 on t2.store_id = t3.store_id
left join t4 on t2.combo_id = t4.combo_id
left join t51 on t2.id =  t51.id
left join t52 on t2.id = t52.id

union all 

select  date_format(pay_time,'%Y-%m-%d') begin_date
       ,price_interval
       ,store_id
       ,combo_id
       ,recurring_promotion_id
       ,t2.promotion_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status not in (1,2,6,7,8,9,10,21) then order_id end) as pay_promotion_quota
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') then order_id end) as tot_pay_promotion_quota
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status not in (1,2,6,7,8,9,10,21) then actual_pay_amt-real_rebate_amt end) as gmv
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status not in (1,2,6,7,8,9,10,21) then group_amt end) as acc_group_amt
       ,0,0,0,0,0
from t1
inner join t2 on t2.promotion_id = t1.store_promotion_id
group by 1,2,3,4,5,6

union all 

select  date_format(pay_time,'%Y-%m-%d') begin_date
       ,price_interval
       ,store_id
       ,combo_id
       ,recurring_promotion_id
       ,promotion_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct user_id) as uv
       ,0,0
from t2
left join t5 on t2.promotion_id = t5.activity_id
inner join t1 on t2.promotion_id=t1.store_promotion_id
group by 1,2,3,4,5,6 
) a 
group by 1,2,3,4,5,6
) 


SELECT t6.*,
       t53.unum
FROM t6
LEFT JOIN t53 ON t6.store_id=t53.store_id
-- WHERE t6.user_nickname NOT regexp '测试'
--   AND user_nickname <> ''
--   AND city NOT regexp '阿里地区|西藏'
;



=========== 销单明细 砍价&合约

-- 合约
WITH t0 AS
  (SELECT id
   FROM dwd.dwd_sr_contract_h
   WHERE name not regexp '测试'),

-- 到店城市
t00 AS
  (SELECT city_name
   FROM dim.dim_silkworm_explore_city
   WHERE province_name<>'新疆维吾尔族自治区' -- 剔除测试省份
     AND status=1 -- 正常
     AND promotion_type IN ('101',
                            '111',
                            '100',
                            '1')
   GROUP BY 1),

-- 活动
t1 AS (select
  begin_date ,
  a.id ,
  promotion_id ,
  bd_id ,
  bargain_original_price, -- 原价
  bargain_base_price, -- 底价
  pay_amt, -- 团购价
  sub_category_type ,
  begin_time ,
  end_time ,
  tot_promotion_quota ,
  combo_id ,
  store_id ,
  a.contract_id ,
  promotion_type ,
  recurring_promotion_id ,
  bargain_num, -- 刀数
  price_interval
from
  (SELECT left(begin_time,10) AS begin_date ,
          JSON_KEYS(store_detail) AS id ,
          promotion_id ,
          bd_id ,
          bargain_original_price, -- 原价
          bargain_base_price, -- 底价
          pay_amt, -- 团购价
          CASE
              WHEN sub_category_type = 0 THEN '未知'
              WHEN sub_category_type = 1 THEN '包子粥铺'
              WHEN sub_category_type = 2 THEN '汉堡西餐'
              WHEN sub_category_type = 3 THEN '火锅烧烤'
              WHEN sub_category_type = 4 THEN '快餐简餐'
              WHEN sub_category_type = 5 THEN '理发/男士'
              WHEN sub_category_type = 6 THEN '亲子/乐园'
              WHEN sub_category_type = 7 THEN '水果生鲜'
              WHEN sub_category_type = 8 THEN '甜品饮品'
              WHEN sub_category_type = 9 THEN '休闲/玩乐'
              WHEN sub_category_type = 10 THEN '炸串小吃'
              WHEN sub_category_type = 11 THEN '正餐/多人餐'
          END AS sub_category_type ,
          begin_time ,
          end_time ,
          tot_promotion_quota ,
          combo_id ,
          store_id ,
          contract_id ,
          promotion_type ,
          recurring_promotion_id ,
          bargain_num, -- 刀数
          CASE
            WHEN pay_amt <60 THEN '0-60'
            WHEN pay_amt >=60
                 AND pay_amt <120 THEN '60-120'
            WHEN pay_amt >=120
                 AND pay_amt <180 THEN '120-180'
            WHEN pay_amt >=180 THEN '180+'
            END price_interval
   FROM dwd.dwd_sr_silkworm_explore_promotion
   WHERE dt BETWEEN date_sub(current_date(),interval 50 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND date_format(begin_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 0 DAY)
     AND promotion_type IN (5,
                            6)
     ) a inner join t0 on a.contract_id=t0.id
     ),

-- 核销店铺 活动可跨店核销
t11 as(
select t1.*
      ,cast(cast(tt.value as string) as bigint) as hx_store_id
from t1,LATERAL JSON_EACH(ifnull(id,'[0]')) as tt
),

-- 造出新活动数据集
t12 as (
select begin_date
      ,promotion_id
      ,bd_id
      ,bargain_original_price
      ,bargain_base_price
      ,pay_amt
      ,sub_category_type
      ,begin_time
      ,tot_promotion_quota
      ,combo_id
      ,contract_id
      ,case when promotion_type = 5 then '砍价'
            when promotion_type = 6 then '合约'
       end as promotion_type
      ,recurring_promotion_id
      ,bargain_num
      ,price_interval
      ,if(promotion_type = 5,store_id,hx_store_id) as store_id
from(
select begin_date
      ,promotion_id
      ,bd_id
      ,bargain_original_price      -- 砍价原价
      ,bargain_base_price          -- 砍价底价
      ,pay_amt                     -- 团购价    
      ,sub_category_type           -- 餐品分类
      ,begin_time
      ,tot_promotion_quota
      ,combo_id
      ,store_id
      ,contract_id
      ,promotion_type
      ,recurring_promotion_id
      ,bargain_num
      ,price_interval
      ,group_concat(hx_store_id) as hx_store_id
from t11
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
) a
),

-- 店铺数据
t2 as ( 
select a.county_name          -- 区县
      ,a.business_district    -- 商圈
      ,a.store_id             -- 店铺id
      ,a.address_detail       -- 店铺地址
      ,a.store_name           -- 店铺名称
      ,a.city_name            -- 城市
   --   ,province_name        -- 省份
from dim.dim_silkworm_explore_store a
inner join (select hx_store_id,store_id from t11 group by 1,2) b on a.store_id=b.hx_store_id or a.store_id=b.store_id
),

-- 支付订单
t3 as (select store_promotion_id
      ,pay_amt   as actual_pay_amt     -- 支付金额
      ,order_id
      ,pay_time       -- 支付时间
      ,verify_time    -- 核销时间
      ,status
      ,red_pack_reward_num/100  as red_pack_reward_num
from dwd.dwd_sr_silkworm_explore_order
where dt BETWEEN date_sub(current_date(),interval 14 DAY) AND date_sub(current_date(),interval 1 DAY)
),

-- 合约名称
t4 AS
  (SELECT a.combo_id ,
          a.combo_name
   FROM dwd.dwd_sr_silkworm_explore_combo a
   INNER JOIN
     (SELECT combo_id
      FROM t11
      GROUP BY 1) b ON a.combo_id=b.combo_id),

-- 浏览
t5 AS
  (SELECT statistics_date ,
          user_id ,
          activity_id
   FROM dws.dws_sr_traffic_user_d
   WHERE statistics_date BETWEEN date_sub(current_date(),interval 14 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND if_view_bargain > 0),

-- 循环活动首次开始日期
t51 AS
  (SELECT a.recurring_promotion_id,
          a.first_begin_time
   FROM
     (SELECT recurring_promotion_id ,
             min(begin_time) AS first_begin_time
      FROM dwd.dwd_sr_silkworm_explore_promotion
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 50 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND date_format(begin_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1) a
   INNER JOIN
     (SELECT recurring_promotion_id
      FROM t12
      GROUP BY 1) b ON a.recurring_promotion_id=b.recurring_promotion_id),

-- 累计核销量
t52 AS
  (SELECT t1.recurring_promotion_id ,
          left(begin_time,10) AS begin_date ,
          count(distinct if(left(verify_time,10)= left(begin_time,10),order_id,null)) AS hx_order_num
   FROM t1
   LEFT JOIN
     (SELECT order_id,
             verify_time,
             store_promotion_id
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND promotion_type IN (5,
                               6)) a ON t1.promotion_id = a.store_promotion_id
   GROUP BY 1,
            2),


-- 近7天店铺3公里内访问用户量
t53 AS
  (SELECT store_id,
          count(DISTINCT user_id) unum
   FROM
     (SELECT user_id,
             get_json_string(DATA,'$.store_id') AS store_id,
             get_json_string(DATA,'$.store_distance')/1000 store_distance
      FROM ods.ods_sr_event_log
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND event_name='StoreDiscovery_Activity_Details_Ex'
        AND user_id regexp '^[0-9]{1,10}$'
      GROUP BY 1,
               2,
               3) a
   WHERE store_distance<=3
   GROUP BY 1),



t6 as (
select  begin_date
       ,promotion_id as '活动ID'
       ,recurring_promotion_id as '循环活动ID'
       ,contract_id as '合约ID'
       ,combo_id as '套餐ID'
       ,price_interval
       ,element_at(array_remove(array_agg(store_id),0),1) as store_id
       ,'合约' as '业务类型'
       ,element_at(array_remove(array_agg(store_name),0),1) as '店铺名称'
       ,element_at(array_remove(array_agg(city_name),0),1) as city
       ,element_at(array_remove(array_agg(county_name),0),1) as '区县'
       ,element_at(array_remove(array_agg(business_district),0),1) as '商圈'
       ,element_at(array_remove(array_agg(address_detail),0),1) as '店铺地址'
       ,coalesce(element_at(array_remove(array_agg(combo_name),0),1),'') as '套餐名称'
       ,element_at(array_remove(array_agg(sub_category_type),0),1) as '二级类目'
       ,element_at(array_remove(array_agg(left(begin_time,10)),0),1) as '首次发布活动时间'
       ,coalesce(element_at(array_remove(array_agg(user_nickname),0),1),'') as user_nickname
       ,sum(bargain_original_price) as '砍价原价'
       ,sum(bargain_base_price) as '砍价底价'
       ,sum(group_amt) as '团购价'
       ,sum(pay_amt) as 'GMV' -- '支付金额'
       ,sum(tot_promotion_quota) as '活动总名额'
       ,sum(pay_promotion_quota) as '支付名额(不含退款)'
       ,sum(tot_pay_promotion_quota) as '支付名额(含退款)'
       ,sum(hx_promotion_quota) as '累计核销名额数'
       ,coalesce(sum(pay_amt)/sum(group_amt)/sum(pay_promotion_quota),0) as '折扣率'
       ,sum(view_uv) as '访问UV'
       ,sum(bargain_num) as '砍价次数'
from (
select distinct if(t3.pay_time is not null,date_format(t3.pay_time,'%Y-%m-%d'),date_format(t12.begin_date,'%Y-%m-%d')) as begin_date
       ,promotion_id
       ,t12.recurring_promotion_id
       ,contract_id
       ,combo_id
       ,price_interval
       ,0 as store_id
       ,0 as store_name 
       ,0 as city_name
       ,0 as county_name
       ,0 as business_district
       ,0 as address_detail
       ,0 as combo_name
       ,sub_category_type
       ,first_begin_time as begin_time
       ,user_nickname
       ,bargain_original_price
       ,bargain_base_price
       ,pay_amt as group_amt
       ,0 as pay_amt
       ,tot_promotion_quota
       ,0 as pay_promotion_quota
       ,0 as tot_pay_promotion_quota
       ,hx_order_num as hx_promotion_quota
       ,0 as actual_discount_rate
       ,0 as view_uv
       ,bargain_num
from (select * from t12 where promotion_type = '合约') t12
left join t3 on t3.store_promotion_id=t12.promotion_id
left join dim.dim_silkworm_staff a on t12.bd_id = a.bd_id 
left join t51 on t12.recurring_promotion_id = t51.recurring_promotion_id
left join t52 on t12.recurring_promotion_id = t52.recurring_promotion_id and t12.begin_date = t52.begin_date

union all

select  if(t3.pay_time is not null,date_format(t3.pay_time,'%Y-%m-%d'),date_format(t11.begin_date,'%Y-%m-%d')) as begin_date
       ,t11.promotion_id
       ,t11.recurring_promotion_id
       ,t11.contract_id
       ,t11.combo_id
       ,t11.price_interval
       ,group_concat(distinct t2.store_id)
       ,group_concat(distinct store_name)
       ,group_concat(distinct city_name)
       ,group_concat(distinct county_name)
       ,group_concat(distinct business_district)
       ,group_concat(distinct address_detail)
       ,group_concat(distinct combo_name)
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0
from (select * from t11 where promotion_type = 6) t11
left join t3 on t3.store_promotion_id=t11.promotion_id
left join t2 on t11.hx_store_id = t2.store_id
left join t4 on t11.combo_id = t4.combo_id 
group by 1,2,3,4,5,6

union all 

select  if(t3.pay_time is not null,date_format(t3.pay_time,'%Y-%m-%d'),date_format(t12.begin_date,'%Y-%m-%d')) as begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,t12.price_interval
       ,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36)then actual_pay_amt+red_pack_reward_num end) 
       ,0
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then order_id end) as pay_promotion_quota
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') then order_id end) as tot_pay_promotion_quota
       ,0
       ,coalesce(sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then actual_pay_amt+red_pack_reward_num end)/sum(pay_amt)/count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00')  and status in (3,5,36) then order_id end),0) as actual_discount_rate
       ,0,0
from (select * from t12 where promotion_type = '合约') t12
left join t3 
on t12.promotion_id = t3.store_promotion_id
group by 1,2,3,4,5,6

union all 

select  if(t3.pay_time is not null,date_format(t3.pay_time,'%Y-%m-%d'),date_format(t12.begin_date,'%Y-%m-%d')) as begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,t12.price_interval
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct case when begin_date = statistics_date then user_id end) as view_uv
       ,0
from (select * from t12 where promotion_type ='合约') t12
left join t3 on t3.store_promotion_id=t12.promotion_id
left join t5 on t12.promotion_id = t5.activity_id
group by 1,2,3,4,5,6
) a 
group by 1,2,3,4,5,6

union all  -- 砍价

select  begin_date
       ,promotion_id as '活动ID'
       ,recurring_promotion_id as '循环活动ID'
       ,contract_id as '合约ID'
       ,combo_id as '套餐ID'
       ,price_interval
       ,store_id
       ,'砍价' as promotion_type
       ,element_at(array_remove(array_agg(store_name),0),1) as store_name
       ,element_at(array_remove(array_agg(city_name),0),1) as city_name
       ,element_at(array_remove(array_agg(county_name),0),1) as county_name
       ,element_at(array_remove(array_agg(business_district),0),1) as business_district
       ,element_at(array_remove(array_agg(address_detail),0),1) as address_detail
       ,coalesce(element_at(array_remove(array_agg(combo_name),0),1),'') as combo_name
       ,element_at(array_remove(array_agg(sub_category_type),0),1) as sub_category_type
       ,element_at(array_remove(array_agg(left(begin_time,10)),0),1) as begin_time
       ,coalesce(element_at(array_remove(array_agg(user_nickname),0),1),'') as user_nickname
       ,sum(bargain_original_price) as bargain_original_price
       ,sum(bargain_base_price) as bargain_base_price
       ,sum(group_amt) as group_amt
       ,sum(pay_amt) as pay_amt
       ,sum(tot_promotion_quota) as tot_promotion_quota
       ,sum(pay_promotion_quota) as pay_promotion_quota
       ,sum(tot_pay_promotion_quota) as tot_pay_promotion_quota
       ,sum(hx_promotion_quota) as hx_promotion_quota
       ,coalesce(sum(pay_amt)/sum(group_amt)/sum(pay_promotion_quota),0) as actual_discount_rate
       ,sum(view_uv) as view_uv
       ,sum(bargain_num) as bargain_num
from (
select distinct if(t3.pay_time is not null,date_format(t3.pay_time,'%Y-%m-%d'),date_format(t1.begin_date,'%Y-%m-%d')) as begin_date
       ,t1.promotion_id
       ,t1.recurring_promotion_id
       ,t1.contract_id
       ,t1.combo_id
       ,t1.price_interval
       ,t1.store_id
       ,store_name 
       ,city_name
       ,county_name
       ,business_district
       ,address_detail
       ,combo_name
       ,sub_category_type
       ,first_begin_time as begin_time
       ,user_nickname
       ,bargain_original_price
       ,bargain_base_price
       ,pay_amt as group_amt
       ,0 as pay_amt
       ,tot_promotion_quota
       ,0 as pay_promotion_quota
       ,0 as tot_pay_promotion_quota
       ,hx_order_num as hx_promotion_quota
       ,0 as actual_discount_rate
       ,0 as view_uv
       ,bargain_num
from (select * from t1 where promotion_type = '5') t1 left join t3 on t3.store_promotion_id=t1.promotion_id
left join dim.dim_silkworm_staff a on t1.bd_id = a.bd_id 
left join t2 on t1.store_id = t2.store_id
left join t4 on t1.combo_id = t4.combo_id
left join t51 on t1.recurring_promotion_id = t51.recurring_promotion_id
left join t52 on t1.recurring_promotion_id = t52.recurring_promotion_id and t1.begin_date = t52.begin_date

union all 

select  if(t3.pay_time is not null,date_format(t3.pay_time,'%Y-%m-%d'),date_format(t12.begin_date,'%Y-%m-%d')) as begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,t12.price_interval
       ,t12.store_id
       ,0,0,0,0,0,0,0,0,0,0,0,0
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then actual_pay_amt+red_pack_reward_num end) 
       ,0
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then order_id end) as pay_promotion_quota
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') then order_id end) as tot_pay_promotion_quota
    --    ,count(distinct case when begin_date = left(verify_time,10) then order_id end) as hx_promotion_quota
       ,0
       ,coalesce(sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then actual_pay_amt+red_pack_reward_num end)/sum(pay_amt)/count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00')  and status in (3,5,36)then order_id end),0) as actual_discount_rate
       ,0,0
from (select * from t12 where promotion_type = '砍价') t12
left join t3 
on t12.promotion_id = t3.store_promotion_id
group by 1,2,3,4,5,6,7

union all 

select  begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,t12.price_interval
       ,t12.store_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct case when begin_date = statistics_date then user_id end) as uv
       ,0
from (select * from t12 where promotion_type = '砍价') t12
left join t5
on t12.promotion_id = t5.activity_id
group by 1,2,3,4,5,6,7

) a 
group by 1,2,3,4,5,6,7
) 



SELECT t6.*,
       t53.unum
FROM t6
LEFT JOIN t53 ON t6.store_id=t53.store_id
WHERE t6.begin_date=date_sub(current_date(),interval 1 day)
;





