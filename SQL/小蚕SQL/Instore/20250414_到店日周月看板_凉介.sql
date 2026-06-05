-- 口径：(均是截面口径)
-- 1）砍价GMV：当日支付剔除退款的含券金额，预购订单以活动id统计
-- 2）探店GMV：活动id维度，当日支付剔除退款-返豆金额
-- 3）支付名额数：当日支付剔除退款的名额数量，预购订单以活动id统计
-- 4）探店名额数：
-- 5）动销数：当日支付含退款的活动数量（改动理由：动销率主要反映商品销售活跃度，与退款无关，动销率应仅关注是否有成交，退款属于售后环节）
-- 6）砍价业务的折扣率：GMV/团购价
-- 7）探店业务的折扣率：（GMV-返豆金额）/团购价
-- 8）销单率：支付名额数/活动总名额
-- 9）销单率环比：今日-昨日的差值，+正数为增长，-负数为降低
-- 10）循环活动当日核销名额数：当日循环活动id维度实际核销名额（改动理由：之前核销名额数是当日支付且当日核销，但是商家角度卡的不是销售数量，卡的是核销数量，所以控制每日实际核销数量更重要）
-- 11）核销率：活动id维度的核销名额数/支付剔除退款名额数（近几天数据实时变化是ok的）
-- 12）循环活动当日完单名额数：当日循环活动id维度实际完单名额
-- 13）完单率：活动id维度的完单名额数/核销名额数（近几天数据实时变化是ok的）
-- 14）转化率：当日支付用户数/访问UV
-- 15）件单价：GMV/支付名额数

-- 活动总名额要单独统计
-- 团购价、返豆金额，统计支付活动的
-- 核销名额、完单名额以循环活动来统计（datart 砍价&合约视图）

-- 其他没啥问题 就是
-- 1.活动名额单独算
-- 2.团购价和反豆金额按实际产生的订单的去汇总
-- 3.累计核销名额数&累计完单名额数 按照循环活动ID和活动ID 生成的ID 字段去汇总当天的数量 销单明细里面的逻辑你看下

-- 还有订单表的dt 最好再往前放7天 
-- 然后访问uv再看下 promotion_type 会不会有别的 



20250417 业务反馈
1、探店和砍价做成两个表，因为字段名称有区别
2、活动数和活动总名额和销单明细的有细微差异，查一下
3、团购价、返豆金额不需要，总数无实际分析意义
4、折扣率是gmv/团购价，数对了，备注错了，备注的这些字全都不要
5、销单率环比
6、城市和品类也要分成两个表，按照需求文档的形式~

核销率的口径是周期内活动维度的，这个值只可能≤100%

价格段的数据我拆出来了，
砍价业务分为：0-60、60-120、120-180、180+，探店业务分为：0-30、30-60、60-90、90-120、120+
区间左闭右开，这个可以在sql里改一下然后也加在后续的分析表里了
平衡过商品量级和销单情况的（团购价口径，都是）

-- =================================================================================== 

-- 日报
-- drop table IF EXISTS dws.dws_sr_silkworm_explore_statis_d;

-- CREATE TABLE IF NOT EXISTS  dws.dws_sr_silkworm_explore_statis_d (
--     `statistics_date` date not null COMMENT '统计日期',
--     `business_name` varchar(10) COMMENT '业务名称',
--     `city_name` varchar(10) COMMENT '城市名称',
--     `cate2_name` varchar(20) COMMENT '二级品类',
--     `gmv` decimal(12,4) COMMENT 'GMV',
--     `promotion_num` int COMMENT '活动数',
--     `pay_promotion_quota` int COMMENT '支付名额',
--     `dongxiao_promotion_num` int COMMENT '动销数',
--     `group_amt` decimal(12,4) COMMENT '团购价',
--     `real_rebate_amt` decimal(12,4) COMMENT '返豆金额',
--     `tot_promotion_quota` int COMMENT '活动名额',
--     `acc_verify_quota` int  COMMENT '累计核销名额',
--     `acc_finish_quota` int COMMENT '累计完单名额',
--     `verify_quota` int  COMMENT '核销名额',
--     `finish_quota` int  COMMENT '完单名额',
--     `pay_user_num` int COMMENT '支付用户数',
--     `uv` int COMMENT '访问uv'
-- ) ENGINE=OLAP 
-- PRIMARY KEY(statistics_date,business_name,city_name,cate2_name)
-- COMMENT "到店业务日统计"
-- DISTRIBUTED BY HASH(statistics_date,business_name,city_name,cate2_name)
-- PROPERTIES (
-- "replication_num" = "2",
-- "in_memory" = "false",
-- "enable_persistent_index" = "true",
-- "replicated_storage" = "true",
-- "compression" = "LZ4"
-- );


-- 到店活动明细
DROP VIEW IF EXISTS pro_info;


CREATE VIEW IF NOT EXISTS pro_info (newpro_id,promotion_id,sub_category_type,promotion_type,tot_promotion_quota,rebate_price,cost_price,net_cost_price,group_amt,hand_price,tot_bargain_amt,bargain_original_price,bargain_base_price,bargain_max_discount,bargain_min_discount,city_name,begin_date,recurring_promotion_id,contract_id,price_interval) AS
  (SELECT newpro_id,
          promotion_id,
          sub_category_type,
          promotion_type,
          tot_promotion_quota,
          rebate_price,
          cost_price,
          net_cost_price,
          group_amt,
          hand_price,
          tot_bargain_amt,
          bargain_original_price,
          bargain_base_price,
          bargain_max_discount,
          bargain_min_discount,
          coalesce(city_name,'其他') as city_name,
          begin_date,
          recurring_promotion_id,
          contract_id,
          price_interval
   FROM
     (SELECT if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) as newpro_id,
             promotion_id ,
             CASE WHEN sub_category_type = 0 THEN '未知' WHEN sub_category_type = 1 THEN '包子粥铺' WHEN sub_category_type = 2 THEN '汉堡西餐' WHEN sub_category_type = 3 THEN '火锅烧烤' WHEN sub_category_type = 4 THEN '快餐简餐' WHEN sub_category_type = 5 THEN '理发/男士' WHEN sub_category_type = 6 THEN '亲子/乐园' WHEN sub_category_type = 7 THEN '水果生鲜' WHEN sub_category_type = 8 THEN '甜品饮品' WHEN sub_category_type = 9 THEN '休闲/玩乐' WHEN sub_category_type = 10 THEN '炸串小吃' WHEN sub_category_type = 11 THEN '正餐/多人餐' END AS sub_category_type,
             promotion_type,
             tot_promotion_quota,
             rebate_price, -- 返利价
             cost_price, -- 成本价(含笔记)
             net_cost_price, -- 成本价(不含笔记)
             pay_amt AS group_amt, -- 团购价
             pay_amt - rebate_price as hand_price,  -- 到手价
             tot_bargain_amt,-- 总砍价金额
             bargain_original_price,-- 砍价原价
             bargain_base_price,-- 砍价底价
             bargain_max_discount,-- 砍价最大折扣
             bargain_min_discount,-- 砍价最低折扣
             city_code AS county_id,
             date_format(begin_time,'%Y-%m-%d') as begin_date,
             recurring_promotion_id,
             contract_id,
             -- 团购价价格段
             CASE
                WHEN promotion_type IN (5,6)
                     AND pay_amt <60 THEN '0-60'
                WHEN promotion_type IN (5,6)
                     AND pay_amt >=60
                     AND pay_amt <120 THEN '60-120'
                WHEN promotion_type IN (5,6)
                     AND pay_amt >=120
                     AND pay_amt <180 THEN '120-180'
                WHEN promotion_type IN (5,6)
                     AND pay_amt >=180 THEN '180+'
                WHEN promotion_type IN (1,4)
                     AND pay_amt <30 THEN '0-30'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=30
                     AND pay_amt <60 THEN '30-60'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=60
                     AND pay_amt <90 THEN '60-90'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=90
                     AND pay_amt <120 THEN '90-120'
                WHEN promotion_type IN (1,4)
                     AND pay_amt >=120 THEN '120+'
                END price_interval
      FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE date_format(begin_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 16 DAY) AND date_sub(current_date(),interval 1 DAY)
AND promotion_type IN (1,
                       4,
                       5,
                       6) 
AND store_promotion_name NOT regexp '测试'                    
      ) a
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
                          '1')
   ) b ON a.county_id=b.county_id
  );



-- 到店订单明细
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (store_promotion_id,order_id,user_id,promotion_type,pay_time,verify_time,finish_time,status,pay_amt,redpack_reward_amt,real_rebate_amt) AS
  (SELECT store_promotion_id,
          order_id,
          user_id,
          promotion_type,
          if(promotion_type = 4,create_time,pay_time) AS pay_time,
          verify_time,
          finish_time,
          status,
          coalesce(pay_amt,0) AS pay_amt,
          coalesce(red_pack_reward_num/100,0) AS redpack_reward_amt,
          real_rebate_amt
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 22 DAY) AND date_sub(current_date(),interval 0 DAY)
     AND promotion_type IN (1,
                            4,
                            5,
                            6)
     );



-- 访问UV
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (business_name,dat,city_name,sub_category_type,price_interval,uv) AS
  (SELECT if(promotion_type IN (1,4),'探店','砍价') business_name,
                                                a.dat,
                                                coalesce(b.city_name,'合计') city_name,
                                                coalesce(b.sub_category_type,'合计') sub_category_type,
                                                coalesce(b.price_interval,'合计') price_interval,
                                                count(DISTINCT (CASE WHEN promotion_type IN (1,4)
                                                                AND if_view_storediscovery>=1 THEN user_id WHEN promotion_type IN (5,6)
                                                                AND if_view_bargain>=1 THEN user_id END)) uv
   FROM
     (SELECT date_format(statistics_date,'%Y-%m-%d') dat,
                                                     activity_id,
                                                     user_id,
                                                     if_view_storediscovery,
                                                     if_view_bargain
      FROM dws.dws_sr_traffic_user_d
      WHERE date_format(statistics_date,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY)
        AND user_id regexp '^[0-9]{1,10}$'
        AND activity_id regexp '^[1-9]{1,9}$'
        AND (if_view_storediscovery>=1
             OR if_view_bargain>=1)
      GROUP BY 1,
               2,
               3,
               4,
               5) a
   INNER JOIN pro_info b ON a.activity_id=b.promotion_id
   GROUP BY grouping sets (
                          (business_name,dat,city_name,sub_category_type,price_interval),
                          (business_name,dat,city_name),
                          (business_name,dat,sub_category_type),
                          (business_name,dat,price_interval),
                          (business_name,dat)
                          )
);


-- 活动名额统计
DROP VIEW IF EXISTS quota_info;


CREATE VIEW IF NOT EXISTS quota_info (business_name,begin_date,city_name,sub_category_type,price_interval,tot_promotion_quota) AS (
SELECT IF(promotion_type IN (1,4),'探店','砍价') business_name,
       begin_date,
       coalesce(city_name,'合计') city_name,
       coalesce(sub_category_type,'合计') sub_category_type,
       coalesce(price_interval,'合计') price_interval,
       sum(tot_promotion_quota) tot_promotion_quota
FROM pro_info
GROUP BY grouping sets (
                       (business_name,begin_date,city_name,sub_category_type,price_interval),
                       (business_name,begin_date,city_name),
                       (business_name,begin_date,sub_category_type),
                       (business_name,begin_date,price_interval),
                       (business_name,begin_date)
                       )
);


-- 累计核销名额和完单名额
DROP VIEW IF EXISTS acc_verify_info;


CREATE VIEW IF NOT EXISTS acc_verify_info (business_name,begin_date,city_name,sub_category_type,price_interval,acc_verify_quota,acc_finish_quota) AS (

-- 探店
SELECT '探店' business_name,
            a.begin_date,
            coalesce(city_name,'合计') city_name,
            coalesce(sub_category_type,'合计') sub_category_type,
            coalesce(price_interval,'合计') price_interval,
            count(DISTINCT IF(date_format(c.verify_time,'%Y-%m-%d')=a.begin_date,c.order_id,NULL)) acc_verify_quota,
            count(DISTINCT CASE WHEN c.status IN (5,19,20,35)
                  AND date_format(c.finish_time,'%Y-%m-%d')=a.begin_date THEN order_id END) AS acc_finish_quota
FROM pro_info a
LEFT JOIN
  (SELECT a.recurring_promotion_id,
          a.begin_date,
          b.verify_time,
          b.order_id,
          a.promotion_type,
          b.status,
          b.finish_time
   FROM pro_info a
   LEFT JOIN order_info b ON a.promotion_id=b.store_promotion_id
   WHERE a.promotion_type IN (1,
                              4)
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7) c ON a.recurring_promotion_id=c.recurring_promotion_id
AND a.begin_date=c.begin_date
   GROUP BY grouping sets (
                          (business_name,a.begin_date,city_name,sub_category_type,price_interval),
                          (business_name,a.begin_date,city_name),
                          (business_name,a.begin_date,sub_category_type),
                          (business_name,a.begin_date,price_interval),
                          (business_name,a.begin_date)
                          )

union all

-- 砍价
SELECT '砍价' business_name,
            a.begin_date,
            coalesce(city_name,'合计') city_name,
            coalesce(sub_category_type,'合计') sub_category_type,
            coalesce(price_interval,'合计') price_interval,
            count(DISTINCT IF(date_format(d.verify_time,'%Y-%m-%d')=a.begin_date,d.order_id,NULL)) acc_verify_quota,
            0 AS acc_finish_quota
FROM pro_info a
LEFT JOIN
  (SELECT a.recurring_promotion_id,
          a.begin_date,
          b.verify_time,
          b.order_id,
          a.promotion_type,
          b.status,
          b.finish_time
   FROM pro_info a
   LEFT JOIN order_info b ON a.promotion_id=b.store_promotion_id
   INNER JOIN
   -- 剔除测试合约
     (SELECT id
      FROM dwd.dwd_sr_contract_h
      WHERE name NOT regexp '测试') c ON a.contract_id=c.id
   WHERE a.promotion_type IN (5,
                              6)
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7) d ON a.recurring_promotion_id=d.recurring_promotion_id
AND a.begin_date=d.begin_date
   GROUP BY grouping sets (
                          (business_name,a.begin_date,city_name,sub_category_type,price_interval),
                          (business_name,a.begin_date,city_name),
                          (business_name,a.begin_date,sub_category_type),
                          (business_name,a.begin_date,price_interval),
                          (business_name,a.begin_date)
                          )
     );



-- 核销名额
DROP VIEW IF EXISTS verify_info;


CREATE VIEW IF NOT EXISTS verify_info (business_name,begin_date,city_name,sub_category_type,price_interval,verify_quota,finish_quota) AS
  (SELECT IF(a.promotion_type IN (1,
                                  4),'探店',
                                     '砍价') business_name,
                                           a.begin_date,
                                            coalesce(city_name,'合计') city_name,
                                          coalesce(sub_category_type,'合计') sub_category_type,
                                          coalesce(price_interval,'合计') price_interval,
                                          count(DISTINCT IF(date_format(b.verify_time,'%Y-%m-%d')=a.begin_date,b.order_id,NULL)) verify_quota,
                                          count(DISTINCT CASE WHEN a.promotion_type IN (5,6) THEN NULL 
                                                         WHEN a.promotion_type IN (1,4) 
                                                         AND b.status IN (5,19,20,35)
                                                         AND date_format(b.finish_time,'%Y-%m-%d')=a.begin_date THEN order_id END) AS finish_quota
   FROM pro_info a
   LEFT JOIN order_info b ON a.promotion_id=b.store_promotion_id
     GROUP BY grouping sets (
                          (business_name,a.begin_date,city_name,sub_category_type,price_interval),
                          (business_name,a.begin_date,city_name),
                          (business_name,a.begin_date,sub_category_type),
                          (business_name,a.begin_date,price_interval),
                          (business_name,a.begin_date)
                          )
     );


-- 非uv指标统计
drop view if exists index_info;

create view IF NOT EXISTS index_info (business_name,begin_date,city_name,sub_category_type,price_interval,gmv,pay_promotion_quota,dongxiao_promotion_num,group_amt,real_rebate_amt,pay_user_num,promotion_num) as
(SELECT if(a.promotion_type IN (1,4),'探店','砍价') business_name,
      begin_date,
      coalesce(city_name,'合计') city_name,
      coalesce(sub_category_type,'合计') sub_category_type,
      coalesce(price_interval,'合计') price_interval,
      -- gmv
      sum(CASE WHEN a.promotion_type IN (5,6)
          AND pay_time BETWEEN concat(left(date_sub(a.begin_date,7),10),' 00:00:00') AND concat(left(date_add(a.begin_date,1),10),' 00:05:00')
          AND status IN (3,5,36) THEN pay_amt+redpack_reward_amt 
          WHEN a.promotion_type IN (1,4)
          AND date_format(pay_time,'%Y-%m-%d') <> '1970-01-01'
          AND status NOT IN (1,2,6,7,8,9,10,21) THEN pay_amt-real_rebate_amt ELSE 0 END) AS gmv,
      -- 支付名额数
      count(DISTINCT CASE WHEN a.promotion_type IN (5,6)
            AND pay_time BETWEEN concat(left(date_sub(begin_date,7),10),' 00:00:00') AND concat(left(date_add(begin_date,1),10),' 00:05:00')
            AND status IN (3,5,36) then order_id 
            WHEN a.promotion_type IN (1,4)
            AND date_format(pay_time,'%Y-%m-%d') <> '1970-01-01'
            AND status NOT IN (1,2,6,7,8,9,10,21) THEN order_id END) AS pay_promotion_quota,
      -- 动销数
      count(DISTINCT CASE WHEN a.promotion_type IN (5,6)
            AND pay_time BETWEEN concat(left(date_sub(begin_date,7),10),' 00:00:00') AND concat(left(date_add(begin_date,1),10),' 00:05:00') THEN newpro_id 
            WHEN a.promotion_type IN (1,4)
            AND date_format(pay_time,'%Y-%m-%d') <> '1970-01-01' THEN newpro_id END) AS dongxiao_promotion_num,
      -- 团购价
      sum(CASE WHEN a.promotion_type IN (5,6)
            AND pay_time BETWEEN concat(left(date_sub(begin_date,7),10),' 00:00:00') AND concat(left(date_add(begin_date,1),10),' 00:05:00')
            AND status IN (3,5,36) then group_amt 
            WHEN a.promotion_type IN (1,4)
            AND date_format(pay_time,'%Y-%m-%d') <> '1970-01-01'
            AND status NOT IN (1,2,6,7,8,9,10,21) THEN group_amt ELSE 0 END) AS group_amt,
      -- 返豆金额
      sum(if(a.promotion_type IN (1,4)
            AND date_format(pay_time,'%Y-%m-%d') <> '1970-01-01'
            AND status NOT IN (1,2,6,7,8,9,10,21),real_rebate_amt,0)) real_rebate_amt,
      -- 支付用户数
      count(DISTINCT CASE WHEN a.promotion_type IN (5,6)
            AND pay_time BETWEEN concat(left(date_sub(begin_date,7),10),' 00:00:00') AND concat(left(date_add(begin_date,1),10),' 00:05:00')
            AND status IN (3,5,36) then user_id 
            WHEN a.promotion_type IN (1,4)
            AND date_format(pay_time,'%Y-%m-%d') <> '1970-01-01'
            AND status NOT IN (1,2,6,7,8,9,10,21) THEN user_id END) AS pay_user_num,
      -- 活动数
      count(distinct a.promotion_id) promotion_num  
FROM pro_info a
LEFT JOIN order_info b ON a.promotion_id=b.store_promotion_id
   GROUP BY grouping sets (
                          (business_name,begin_date,city_name,sub_category_type,price_interval),
                          (business_name,begin_date,city_name),
                          (business_name,begin_date,sub_category_type),
                          (business_name,begin_date,price_interval),
                          (business_name,begin_date)
                          )
);




SELECT coalesce(a.begin_date,b.dat,c.begin_date,d.begin_date,e.begin_date) statistics_date,
       coalesce(a.business_name,b.business_name,c.business_name,d.business_name,e.business_name) business_name,
       coalesce(a.city_name,b.city_name,c.city_name,d.city_name,e.city_name) city_name,
       coalesce(a.sub_category_type,b.sub_category_type,c.sub_category_type,d.sub_category_type,e.sub_category_type) sub_category_type,
       coalesce(a.price_interval,b.price_interval,c.price_interval,d.price_interval,e.price_interval) price_interval,
       gmv,
       promotion_num,
       pay_promotion_quota,
       dongxiao_promotion_num,
       group_amt,
       real_rebate_amt,
       tot_promotion_quota,
       acc_verify_quota,
       acc_finish_quota,
       verify_quota,
       pay_user_num,
       uv
FROM index_info a
FULL JOIN view_info b ON a.business_name=b.business_name
AND a.begin_date=b.dat
AND a.city_name=b.city_name
AND a.sub_category_type=b.sub_category_type
AND a.price_interval=b.price_interval
FULL JOIN quota_info c ON a.business_name=c.business_name
AND a.begin_date=c.begin_date
AND a.city_name=c.city_name
AND a.sub_category_type=c.sub_category_type
AND a.price_interval=c.price_interval
FULL JOIN acc_verify_info d ON a.business_name=d.business_name
AND a.begin_date=d.begin_date
AND a.city_name=d.city_name
AND a.sub_category_type=d.sub_category_type
AND a.price_interval=d.price_interval
FULL JOIN verify_info e ON a.business_name=e.business_name
AND a.begin_date=e.begin_date
AND a.city_name=e.city_name
AND a.sub_category_type=e.sub_category_type
AND a.price_interval=e.price_interval
where a.begin_date=date_sub(current_date(),interval 1 DAY)
;


=========== 验数
-- 活动名额
select
IF(promotion_type IN (1,4),'探店','砍价') business_name,
       date_format(begin_time,'%Y-%m-%d') begin_date,
       sum(tot_promotion_quota) tot_promotion_quota
from dwd.dwd_sr_silkworm_explore_promotion
WHERE date_format(begin_time,'%Y-%m-%d')='2025-04-14'
AND promotion_type IN (1,
                       4,
                       5,
                       6)
group by 1,2;

-- 核销和完单
SELECT IF(promotion_type IN (1,4),'探店','砍价') business_name,
          date_format(verify_time,'%Y-%m-%d') dat,
          count(DISTINCT if(date_format(verify_time,'%Y-%m-%d')<>'1970-01-01',order_id,null)) verify_promotion_quota,
          count(DISTINCT CASE WHEN promotion_type IN (1,4)
                AND status IN (5,19,20,35)
                AND date_format(finish_time,'%Y-%m-%d')<>'1970-01-01' THEN order_id 
                WHEN promotion_type IN (5,6)
                AND status=5
                AND date_format(finish_time,'%Y-%m-%d')<>'1970-01-01' THEN order_id END) AS finord_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 21 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND promotion_type IN (1,
                            4,
                            5,
                            6)
group by 1,2


=========================== 周报













