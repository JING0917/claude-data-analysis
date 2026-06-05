====== 探查
ods.ods_sr_user_vip_brand_card_realtime -- 新大牌券
dim.dim_silkworm_rights_card -- 小蚕卡券


-- 卡券发放和使用
-- 1个card_id只有1个cart_type
SELECT a.card_type,
       a.card_id,
       b.card_name,
       b.card_desc,
       a.num,
       a.used_num,
       a.unum,
       a.used_unum
FROM
  ( SELECT card_type,
           card_id,
           count(1) num,
           sum(if(date(used_time) <> '1970-01-01', 1, 0)) used_num,
           count(DISTINCT user_id) unum,
           count(DISTINCT if(date(used_time) <> '1970-01-01', user_id, NULL)) used_unum
   FROM dwd.dwd_sr_market_rights_card
   GROUP BY 1,
            2 ) a
LEFT JOIN dim.dim_silkworm_rights_card b ON a.card_type = b.card_type
AND a.card_id = b.card_id;


-- 大牌券最小和最大使用时间
SELECT card_type,
       min(used_time) min_used_time,
       max(used_time) max_used_time
FROM dwd.dwd_sr_market_rights_card
WHERE card_type IN (3,
                    13)
  AND date(used_time) <> '1970-01-01'
  AND key_id <> 0
GROUP BY 1;


-- 大牌券使用时间内 是否key_id都有值
-- 否 234306条数据无key_id

SELECT date(used_time) used_date,
       card_type,
       length(cast(key_id AS string)) len_num,
       count(1) tot,
       count(DISTINCT user_id) unum
FROM dwd.dwd_sr_market_rights_card
WHERE card_type IN (3,
                    13)
  AND date(used_time) > '2025-10-31'
GROUP BY 1,
         2,
         3;

-- 1个redpacket_id只有1个redpacket_type
SELECT redpacket_id,
       redpacket_type,
       count(1) cnt
FROM dim.dim_silkworm_redpack
GROUP BY 1,
         2 HAVING count(1)>1;



====== 
-- drop table if exists dws.dws_sr_marketing_cost_coupon_d;

CREATE TABLE IF NOT EXISTS dws.dws_sr_marketing_cost_coupon_d (
    statistics_date DATE NOT NULL COMMENT '统计日期',
    business_name VARCHAR(32) NOT NULL COMMENT '业务线',
    coupon_type INT NOT NULL COMMENT '券类型(1:卡券;2:红包)',
    coupon_id INT NOT NULL COMMENT '券ID',
    coupon_name VARCHAR(250) COMMENT '券名称',
    coupon_desc VARCHAR(1000) COMMENT '券描述',
    grant_num bigint COMMENT '发放量',
    grant_uids bitmap COMMENT '发放用户列表',
    used_num bigint COMMENT '使用量',
    used_uids bitmap COMMENT '使用用户列表',    
    cost_amt DECIMAL(12,2) DEFAULT '0.00' COMMENT '花费',
    cost_uids bitmap COMMENT '消耗用户列表'
) 
ENGINE=OLAP
PRIMARY KEY(statistics_date,business_name,coupon_type,coupon_id)
COMMENT "营销券消耗日数据"
DISTRIBUTED BY HASH(statistics_date,coupon_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);



INSERT INTO dws.dws_sr_marketing_cost_coupon_d

-- 以下统计卡券发放和使用+红包发放和使用

-- 3:大牌专享券;7:订单复活券;8:vip额外返利券;13:定向大牌券;14:免单券;15:免审券
-- 13:定向大牌券 存在已使用但key_id(订单ID)=0数据 不做处理 待后端修复
-- 14:免单券在到店场景也有 但量少 暂都归为外卖

-- 卡券发放
WITH grant_coupon AS
  (SELECT dt AS statistics_date,
          '外卖' AS business_name,
          card_id,
          count(1) grant_num,
                   bitmap_agg(user_id) grant_uids
   FROM dwd.dwd_sr_market_rights_card
   WHERE dt='2025-12-10'
     AND card_type IN (3,
                       7,
                       8,
                       13,
                       14,
                       15)
   GROUP BY 1,
            2,
            3 ),

-- 卡券使用
use_coupon AS
  (SELECT date(used_time) AS statistics_date,
          '外卖' AS business_name,
          card_id,
          count(1) used_num,
                   bitmap_agg(user_id) used_uids
   FROM dwd.dwd_sr_market_rights_card
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
     AND card_type IN (3,
                       7,
                       8,
                       13,
                       14,
                       15)
   GROUP BY 1,
            2,
            3 ),

-- 卡券消耗
t1 AS
  (SELECT DISTINCT card_type,
                   key_id,
                   card_id,
                   date_format(used_time,'%Y-%m-%d') used_date,
                                                     user_id
   FROM dwd.dwd_sr_market_rights_card
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
     AND card_type IN (3,
                       7,
                       8,
                       13,
                       14,
                       15)),
-- 外卖订单
t2 AS
  (SELECT auto_id ,
          date_format(order_time,'%Y-%m-%d') AS order_date,
          is_vip_exclusive_order,-- 1:大牌订单
          profit,
          service_charge,
          redpacket_amt, -- 小蚕红包
          real_rebate_amt, -- 返利金额
          origin_rebate_amt,
          order_status,
          user_pay_amt, -- 用户实际支付金额
          order_type, -- 14:官方大牌券
          user_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('2025-12-10',interval 100 DAY) AND '2025-12-10'
     ),


-- vip额外返利金额
t3 AS
  (SELECT right(order_id,9) AS order_id_substr ,
          extra_rebate,
          user_id
   FROM dwd.dwd_sr_user_member_task_rebate_log
   WHERE dt BETWEEN date_sub('2025-12-10',interval 90 DAY) AND '2025-12-10'),


-- 卡券支出(大牌券(旧+新)/复活券/额外返利/免单券/免审券)
t4 AS
  ( SELECT t1.used_date AS statistics_date,
           '外卖' AS business_name,
           t1.card_id,
           coalesce(sum(CASE WHEN is_vip_exclusive_order = 1 THEN real_rebate_amt END),0) AS cost_amt,
           bitmap_agg(if(is_vip_exclusive_order = 1,t1.user_id,NULL)) cost_uids
   FROM t1
   JOIN t2 ON t1.key_id = t2.auto_id
   WHERE t1.card_type IN (3,
                          13)
   GROUP BY 1,
            2,
            3
   UNION ALL SELECT t1.used_date AS statistics_date,
                    '外卖' AS business_name,
                    t1.card_id,
                    coalesce(sum(CASE WHEN order_status = 12 THEN real_rebate_amt END),0) AS cost_amt,
                    bitmap_agg(if(order_status = 12,t1.user_id,NULL)) cost_uids
   FROM t1
   JOIN t2 ON t1.key_id = t2.auto_id
   WHERE t1.card_type=7
   GROUP BY 1,
            2,
            3
   UNION ALL SELECT t1.used_date AS statistics_date,
                    '外卖' AS business_name,
                    t1.card_id,
                    coalesce(sum(CASE WHEN t3.order_id_substr IS NOT NULL THEN extra_rebate END),0) AS cost_amt,
                    bitmap_agg(if(t3.order_id_substr IS NOT NULL,t1.user_id,NULL)) cost_uids
   FROM t1
   JOIN t2 ON t1.key_id = t2.auto_id
   LEFT JOIN t3 ON t1.key_id = t3.order_id_substr
   WHERE t1.card_type=8
   GROUP BY 1,
            2,
            3
   UNION ALL SELECT t1.used_date AS statistics_date,
                    '外卖' AS business_name,
                    t1.card_id,
                    sum(coalesce(CASE WHEN order_status = 14 THEN if(real_rebate_amt>10,10,real_rebate_amt) END, 0)) AS cost_amt,
                    bitmap_agg(if(order_status = 14
                                  AND real_rebate_amt>10,t1.user_id,NULL)) cost_uids
   FROM t1
   JOIN t2 ON t1.key_id = t2.auto_id
   WHERE t1.card_type=15
   GROUP BY 1,
            2,
            3
   UNION ALL SELECT statistics_date,
             business_name,
             b.card_id,
             sum(if(b.user_id IS NOT NULL,cost_amt, 0)) AS cost_amt,
             bitmap_agg(if(b.user_id IS NOT NULL,a.user_id,NULL)) cost_uids
   FROM
     (SELECT FROM_UNIXTIME(use_time, '%Y-%m-%d') AS statistics_date,
             CASE WHEN order_type=1 THEN '外卖' 
                WHEN order_type=2 THEN '探店' 
                WHEN order_type=3 THEN '砍价' 
              END AS business_name,
              user_card_id,
              silk_id AS user_id,
              sum(cast(get_json_object(extra, '$.red_pack_group[0].value') AS INT)/100) AS cost_amt
      FROM ods.ods_sr_free_card_use_record_realtime
      WHERE FROM_UNIXTIME(use_time, '%Y-%m-%d')='2025-12-10'
      GROUP BY 1,
               2,
               3,
               4) a
   LEFT JOIN dwd.dwd_sr_market_rights_card b ON a.user_card_id=b.auto_id
   AND a.user_id=b.user_id
   AND a.statistics_date=date(b.used_time)
   GROUP BY 1,
            2,
            3),

-- 红包发放
grant_rdp AS
  (SELECT dt AS statistics_date,
          CASE
              WHEN business_type=0 THEN '外卖'
              WHEN business_type=1 THEN '砍价'
              WHEN business_type=2 THEN '探店'
          END AS business_name,
          redpacket_id,
          count(1) grant_num,
                   bitmap_agg(user_id) grant_uids
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE dt='2025-12-10'
     AND business_type IN (0,
                           1,
                           2)
   GROUP BY 1,
            2,
            3),

-- 红包使用
use_rdp AS
  (SELECT date(used_time) AS statistics_date,
          CASE
              WHEN business_type=0 THEN '外卖'
              WHEN business_type=1 THEN '砍价'
              WHEN business_type=2 THEN '探店'
          END AS business_name,
          redpacket_id,
          count(1) used_num,
                   bitmap_agg(user_id) used_uids
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
     AND business_type IN (0,
                           1,
                           2)
   GROUP BY 1,
            2,
            3),


-- 红包消耗
-- 外卖红包使用
wm_rdp_used AS
  (SELECT used_time,
          order_id,
          business_type,
          redpacket_type,
          redpacket_name,
          redpacket_id,
          real_rebate_amt,
          user_id
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
     AND business_type=0),

-- 砍价红包使用
bargain_rdp_used AS
  (SELECT used_time,
          auto_ordere_id,
          business_type,
          redpacket_type,
          redpacket_name,
          redpacket_id,
          real_rebate_amt,
          user_id
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
     AND business_type=1),

-- 探店红包使用
explore_rdp_used AS
  (SELECT used_time,
          auto_ordere_id,
          business_type,
          redpacket_type,
          redpacket_name,
          redpacket_id,
          real_rebate_amt,
          user_id
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
     AND business_type=2),


-- 外卖订单
wm_order AS
  (SELECT order_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('2025-12-10',interval 60 DAY) AND '2025-12-10'
     AND order_status IN (2,
                          8)),

-- 到店订单
instore_order AS
  (SELECT auto_id,
          status
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub('2025-12-10',interval 60 DAY) AND '2025-12-10'
     AND promotion_type IN (1,
                            4,
                            5,
                            6,
                            8)
     AND status IN (5,
                    19,
                    20,
                    34,
                    35)),

-- 红包使用记录
rdp_used_record AS
  (SELECT used_time,
          a.order_id,
          business_type,
          redpacket_type,
          redpacket_name,
          redpacket_id,
          real_rebate_amt,
          a.user_id
   FROM wm_rdp_used a
   INNER JOIN wm_order b ON a.order_id=b.order_id
   UNION ALL SELECT used_time,
                    a.auto_ordere_id AS order_id,
                    business_type,
                    redpacket_type,
                    redpacket_name,
                    redpacket_id,
                    real_rebate_amt,
                    a.user_id
   FROM bargain_rdp_used a
   INNER JOIN instore_order b ON a.auto_ordere_id=b.auto_id
   AND b.status=5
   UNION ALL SELECT used_time,
                    a.auto_ordere_id AS order_id,
                    business_type,
                    redpacket_type,
                    redpacket_name,
                    redpacket_id,
                    real_rebate_amt,
                    a.user_id
   FROM explore_rdp_used a
   INNER JOIN instore_order b ON a.auto_ordere_id=b.auto_id),


-- 红包消耗
t5 AS
  (SELECT date(used_time) statistics_date,
                          CASE
                              WHEN business_type=0 THEN '外卖'
                              WHEN business_type=1 THEN '砍价'
                              WHEN business_type=2 THEN '探店'
                          END AS business_name,
                          redpacket_id,
                          sum(real_rebate_amt) cost_amt,
                                               bitmap_agg(user_id) cost_uids
   FROM rdp_used_record
   WHERE used_time BETWEEN '2025-12-10 00:00:00' AND '2025-12-10 23:59:59'
   GROUP BY 1,
            2,
            3)


-- 卡券和红包数据指标聚合
SELECT a.statistics_date,
       a.business_name,
       1 AS coupon_type,
       a.card_id AS coupon_id,
       c.card_name AS coupon_name,
       c.card_desc AS coupon_desc,
       a.grant_num,
       a.grant_uids,
       b.used_num,
       b.used_uids,
       t4.cost_amt,
       t4.cost_uids
FROM grant_coupon a
LEFT JOIN use_coupon b ON a.statistics_date=b.statistics_date
AND a.business_name=b.business_name
AND a.card_id=b.card_id
LEFT JOIN t4 ON a.statistics_date=t4.statistics_date
AND a.business_name=t4.business_name
AND a.card_id=t4.card_id
INNER JOIN dim.dim_silkworm_rights_card c ON a.card_id=c.card_id
AND (c.card_name NOT regexp '测试'
     OR c.card_desc NOT regexp '测试')
UNION ALL
SELECT a.statistics_date,
       a.business_name,
       2 AS coupon_type,
       a.redpacket_id AS coupon_id,
       c.redpacket_name AS coupon_name,
       c.redpacket_desc AS coupon_desc,
       a.grant_num,
       a.grant_uids,
       b.used_num,
       b.used_uids,
       t5.cost_amt,
       t5.cost_uids
FROM grant_rdp a
LEFT JOIN use_rdp b ON a.statistics_date=b.statistics_date
AND a.business_name=b.business_name
AND a.redpacket_id=b.redpacket_id
LEFT JOIN t5 ON a.statistics_date=t5.statistics_date
AND a.business_name=t5.business_name
AND a.redpacket_id=t5.redpacket_id
INNER JOIN dim.dim_silkworm_redpack c ON a.redpacket_id=c.redpacket_id
AND (c.redpacket_name NOT regexp '测试'
     OR c.redpacket_desc NOT regexp '测试');











