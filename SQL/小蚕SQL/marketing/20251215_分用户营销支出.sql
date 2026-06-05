--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2025-08-22 16:01:13
--******************************************************************--
-- drop table if exists dws.dws_sr_marketing_cost_user_d;

CREATE TABLE IF NOT EXISTS dws.dws_sr_marketing_cost_user_d (
    statistics_date DATE NOT NULL COMMENT '统计日期',
    business_name VARCHAR(32) NOT NULL COMMENT '业务线',
    cost_typename VARCHAR(128) NOT NULL COMMENT '成本类型名称',
    user_id INT NOT NULL COMMENT '用户ID',
    cost_amt DECIMAL(12,2) DEFAULT '0.00' COMMENT '花费',
    valid_order_num INT COMMENT '有效订单量(外卖是有效订单,探店是完单,砍价是核销)',
    valid_profit DECIMAL(12,2) DEFAULT '0.00' COMMENT '有效订单利润(外卖是已审核订单利润,探店是完单利润,砍价是核销利润)',
    unsatisfied_order_num INT COMMENT '不满意订单量(仅外卖业务)',
    unsatisfied_profit DECIMAL(12,2) DEFAULT '0.00' COMMENT '不满意订单利润(仅外卖业务)'
) 
ENGINE=OLAP
PRIMARY KEY(statistics_date, business_name, cost_typename, user_id)
COMMENT "用户营销花费日数据"
DISTRIBUTED BY HASH(statistics_date,user_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);



INSERT INTO dws.dws_sr_marketing_cost_user_d
-- 卡券支出、新人免单红包、新人三单红包、探店新人免单红包、渠道拉新、达人团长、客服蚕豆补偿、外卖和到店订单收益

-- 已使用的卡券
WITH t1 AS
  (SELECT DISTINCT card_type, -- 3:大牌专享券;7:订单复活券;8:vip额外返利券;13:定向大牌券;14:免单券;15:免审券
                   key_id,
                   card_id,
                   date_format(used_time,'%Y-%m-%d') used_date,
                   user_id
   FROM dwd.dwd_sr_market_rights_card
   WHERE dt BETWEEN date_sub(CURRENT_DATE,interval 90 DAY) AND date_sub(CURRENT_DATE,interval 1 DAY)
     AND date_format(used_time,'%Y-%m-%d')='${T-1}'
     AND card_type IN (3,
                       7,
                       8,
                       14,
                       15)
     AND card_status = 1 -- 0:未使用 1:已使用 2:已失效
 ),


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
   WHERE dt BETWEEN date_sub('${T-1}',interval 100 DAY) AND '${T-1}'
     -- AND order_status IN (2,
     --                      8,
     --                      12,
     --                      14) -- order_status(12:复活订单,14:免审不满足，公司承担费用)
     ),


-- vip额外返利金额
t3 AS
  (SELECT right(order_id,9) AS order_id_substr ,
          extra_rebate,
          user_id
   FROM dwd.dwd_sr_user_member_task_rebate_log
   WHERE dt BETWEEN date_sub('${T-1}',interval 90 DAY) AND '${T-1}'),

-- 卡券支出(大牌券(旧+新)/复活券/额外返利/免单券/免审券)
t4 AS
  (SELECT statistics_date,
          business_name,
          cost_typename,
          user_id,
          sum(cost_amt) AS cost_amt
   FROM
     (SELECT t1.used_date AS statistics_date,
             '外卖' AS business_name,
             '大牌券' AS cost_typename,
             t1.user_id,
             coalesce(sum(CASE WHEN is_vip_exclusive_order = 1 THEN real_rebate_amt END),0) AS cost_amt
      FROM t1
      JOIN t2 ON t1.key_id = t2.auto_id
      LEFT JOIN t3 ON t1.key_id = t3.order_id_substr
      GROUP BY 1,
               2,
               3,
               4
      UNION ALL SELECT order_date AS statistics_date,
                       '外卖' AS business_name,
                       '大牌券' AS cost_typename,
                       user_id,
                       sum(real_rebate_amt) AS cost_amt
      FROM t2
      WHERE order_date='${T-1}'
        AND order_type=14
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2,
               3,
               4
      UNION ALL SELECT t1.used_date AS statistics_date,
                       '外卖' AS business_name,
                       '复活券' AS cost_typename,
                       t1.user_id,
                       coalesce(sum(CASE WHEN order_status = 12 THEN real_rebate_amt END),0) AS cost_amt
      FROM t1
      JOIN t2 ON t1.key_id = t2.auto_id
      LEFT JOIN t3 ON t1.key_id = t3.order_id_substr
      GROUP BY 1,
               2,
               3,
               4
      UNION ALL SELECT t1.used_date AS statistics_date,
                       '外卖' AS business_name,
                       '额外返利' AS cost_typename,
                       t1.user_id,
                       coalesce(sum(CASE WHEN t3.order_id_substr IS NOT NULL THEN extra_rebate END),0) AS cost_amt
      FROM t1
      JOIN t2 ON t1.key_id = t2.auto_id
      LEFT JOIN t3 ON t1.key_id = t3.order_id_substr
      GROUP BY 1,
               2,
               3,
               4
      UNION ALL SELECT t1.used_date AS statistics_date,
                       '外卖' AS business_name,
                       '免审券' AS cost_typename,
                       t1.user_id,
                       sum(coalesce(CASE WHEN order_status = 14 THEN if(real_rebate_amt>10,10,real_rebate_amt) END, 0)) AS cost_amt
      FROM t1
      JOIN t2 ON t1.key_id = t2.auto_id
      WHERE t1.card_type=15
      GROUP BY 1,
               2,
               3,
               4
      UNION ALL SELECT FROM_UNIXTIME(use_time, '%Y-%m-%d') AS statistics_date,
                       CASE WHEN order_type=1 THEN '外卖' WHEN order_type=2 THEN '探店' WHEN order_type=3 THEN '砍价' END AS business_name,
                       '免单券' AS cost_typename,
                       silk_id AS user_id,
                       sum(cast(get_json_object(extra, '$.red_pack_group[0].value') AS INT)/100) AS cost_amt
      FROM ods.ods_sr_free_card_use_record_realtime
      WHERE FROM_UNIXTIME(use_time, '%Y-%m-%d')='${T-1}'
      GROUP BY 1,
               2,
               3,
               4) a
   GROUP BY 1,
            2,
            3,
            4),


-- 领取了团长红包的新人
t42 AS
  (SELECT DISTINCT user_id
   FROM dwd.dwd_sr_user_newuser_wrp_get_record),

-- 订单id 和对应的使用红包的金额
t62 AS
  (SELECT order_id ,
          redpacket_amt ,
          to_date(order_time) AS order_date ,
          user_id ,
          row_number()over(partition BY user_id
                           ORDER BY order_time) AS rn
   FROM dwd.dwd_sr_order_promotion_order
   WHERE order_status IN (2,
                          8)),

-- 未领团长红包的团长拉的新人的 首次完单日期&第二次完单日期
t72 AS
  (SELECT a.user_id ,
          CASE
              WHEN rn =1 THEN order_date
          END AS first_order_date ,
          CASE
              WHEN rn =2 THEN order_date
          END AS second_order_date
   FROM ( 
    -- 未领团长红包的团长拉的新人
         SELECT t.user_id
         FROM
           (SELECT user_id
            FROM dim.dim_silkworm_user
            WHERE inviter_user_id >0) t
         LEFT JOIN
           (SELECT user_id
            FROM t42) tt ON t.user_id = tt.user_id
         WHERE tt.user_id IS NULL) a
   LEFT JOIN t62 b ON a.user_id = b.user_id),

-- 汇总 下单日期和花费
t82 AS
  (SELECT user_id ,
          first_order_date AS order_date ,
          3 AS reward -- 首单给的奖励
   FROM t72
   WHERE first_order_date IS NOT NULL
   UNION ALL SELECT user_id ,
                    second_order_date ,
                    10 AS reward -- 第二单给的奖励
   FROM t72
   WHERE second_order_date IS NOT NULL),

-- 团长拉新下单奖励
t5 AS
  (SELECT order_date AS statistics_date,
          '外卖' AS business_name,
          '团长拉新奖励' AS cost_typename,
          user_id ,
          SUM(reward) AS cost_amt
   FROM t82
   WHERE order_date BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}'
   GROUP BY 1,
            2,
            3,
            4),

-- 红包使用
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
   WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}'
     AND date_format(used_time,'%Y-%m-%d') BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}' -- 20250908 调整为更新近10天数据
     AND redpacket_use_status=2
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
   WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}'
     AND date_format(used_time,'%Y-%m-%d') BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}' -- 20250908 调整为更新近10天数据
     AND redpacket_use_status=2
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
   WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}'
     AND date_format(used_time,'%Y-%m-%d') BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}' -- 20250908 调整为更新近10天数据
     AND redpacket_use_status=2
     AND business_type=2),


-- 外卖订单
wm_order AS
  (SELECT order_id
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('${T-1}',interval 60 DAY) AND '${T-1}'
     AND order_status IN (2,
                          8)),

-- 到店订单
instore_order AS
  (SELECT auto_id,
          status
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub('${T-1}',interval 60 DAY) AND '${T-1}'
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

-- 红包使用
rdp_used_info AS
  (SELECT date_format(used_time,'%Y-%m-%d') used_date,
                                            CASE
                                                WHEN business_type=0
                                                     AND redpacket_type=18
                                                     AND redpacket_name NOT IN ('新人狂欢首单奖励',
                                                                                '新人首单狂欢奖励',
                                                                                '新人狂欢第3单奖励') THEN '外卖MA红包'
                                                WHEN business_type=1
                                                     AND redpacket_type=18 THEN '砍价MA红包'
                                                WHEN business_type=2
                                                     AND redpacket_type=18
                                                     AND redpacket_name NOT IN ('到店新人免单补贴红包',
                                                                                '到店新人完成3单奖励') THEN '探店MA红包'
                                                WHEN redpacket_name IN ('新人狂欢首单奖励',
                                                                        '新人首单狂欢奖励') THEN '新用户下单奖励红包'
                                                WHEN redpacket_name='新人狂欢第3单奖励' THEN '新人狂欢第3单奖励'
                                                WHEN redpacket_name='到店新人免单补贴红包' THEN '到店新人免单补贴红包'
                                                WHEN redpacket_name='到店新人完成3单奖励' THEN '到店新人完成3单奖励'
                                                WHEN redpacket_type=3 THEN '红包雨'
                                                WHEN redpacket_type=9 THEN '抽奖活动'
                                                WHEN redpacket_type=15
                                                     AND redpacket_id<>232 THEN '团长包红包'
                                                ELSE '其他红包'
                                            END rdp_typename,
                                                user_id,
                                                sum(real_rebate_amt) cost_amt
   FROM rdp_used_record
   GROUP BY 1,
            2,
            3),

-- 各红包类型支出
 t6 AS
  (SELECT used_date AS statistics_date,
          '外卖' AS business_name,
          '团长包红包' AS cost_typename,
          user_id,
          cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='团长包红包'
   UNION ALL SELECT used_date,
                    '外卖' AS business_name,
                    '新人首单红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='新用户下单奖励红包'
   UNION ALL SELECT used_date AS statistics_date,
                    '外卖' AS business_name,
                    '新人3单红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='新人狂欢第3单奖励'
   UNION ALL SELECT used_date AS statistics_date,
                    '探店' AS business_name,
                    '探店新人首单红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='到店新人免单补贴红包'
   UNION ALL SELECT used_date AS statistics_date,
                    '探店' AS business_name,
                    '探店新人3单红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='到店新人完成3单奖励'
   UNION ALL SELECT used_date AS statistics_date,
                    '外卖' AS business_name,
                    'MA发放红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='外卖MA红包'
   UNION ALL SELECT used_date AS statistics_date,
                    '砍价' AS business_name,
                    'MA发放红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='砍价MA红包'
   UNION ALL SELECT used_date AS statistics_date,
                    '探店' AS business_name,
                    'MA发放红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='探店MA红包'
   UNION ALL SELECT used_date AS statistics_date,
                    '外卖' AS business_name,
                    '红包雨' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='红包雨'
   UNION ALL SELECT used_date AS statistics_date,
                    '外卖' AS business_name,
                    '抽奖' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='抽奖活动'
   UNION ALL SELECT used_date AS statistics_date,
                    '外卖' AS business_name,
                    '其他红包' AS cost_typename,
                    user_id,
                    cost_amt
   FROM rdp_used_info
   WHERE rdp_typename='其他红包' ),

-- 探店达人团长拉新
t7 AS
  (SELECT dt as statistics_date,
          '探店' AS business_name,
          '达人团长拉新' AS cost_typename,
          user_id,
          sum(reward_amt) cost_amt
   FROM dwd.dwd_sr_silkworm_explore_reward_record
   WHERE dt BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}' -- 20250908 调整为更新近10天数据
     AND reward_type IN (3,
                         5)
   GROUP BY 1,
            2,
            3,
            4),

-- 挑战赛支出
t8 AS
  (SELECT a.dt AS statistics_date,
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
      WHERE dt ='${T-1}'
        AND is_grant_success = 1
        AND reward_type=1
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN
     (SELECT takepart_id,
             challenge_type
      FROM dwd.dwd_sr_silkworm_challenge_user_promotion
      WHERE dt BETWEEN date_sub('${T-1}',interval 30 DAY) AND '${T-1}'
        AND challenge_type IN (1,
                               2)) b ON a.takepart_id=b.takepart_id
   GROUP BY 1,
            2,
            3,
            4),

-- 用户补偿蚕豆
t9 AS
  (SELECT dt AS statistics_date,
          '外卖' AS business_name,
          '用户补偿蚕豆' AS cost_typename,
          user_id,
          sum(add_candou_num/100) cost_amt
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE dt BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}' -- 20250908 调整为更新近10天数据
     AND cate2_type=4 -- 蚕豆工单
     AND length(order_id)>=10 -- 排除空值订单
     AND add_candou_num>0
     AND status=2 -- 已完结
   GROUP BY 1,
            2,
            3,
            4),

-- 渠道拉新成支出
t10 AS
  (SELECT statistics_date,
          '外卖' business_name,
               '渠道拉新' cost_typename,
                      user_id,
                      sum(peruser_cost) cost_amt
   FROM dwd.dwd_sr_user_newuser_channel_cost_d
   WHERE statistics_date BETWEEN DATE_SUB('${T-1}',INTERVAL 10 DAY) AND '${T-1}'
   GROUP BY 1,
            2,
            3,
            4),

-- 外卖订单利润
wm_income AS
  (SELECT date(order_time) statistics_date,
                           '外卖' business_name,
                                '收益' cost_typename,
                                     user_id,
                                     count(1) valid_order_num,
                                     sum(if(order_status=2,profit,0)) valid_profit,
                                     count(if(order_status=8,auto_id,NULL)) unsatisfied_order_num,
                                     sum(if(order_status=8,profit,0)) unsatisfied_profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub('${T-1}',interval 60 DAY) AND '${T-1}'
     AND date(order_time)='${T-1}'
     AND order_status IN (2,
                          8)
   GROUP BY 1,
            2,
            3,
            4),


-- 到店订单数据集
instore_order_info AS
  (SELECT order_id ,
          date(dt) AS dt ,
          promotion_type ,
          user_id ,
          store_promotion_id ,
          status ,
          pay_amt ,
          real_rebate_amt ,
          red_pack_reward_num ,
          finish_time ,
          verify_time ,
          cost_price, -- 成本价(含笔记)
          net_cost_price, -- 成本价(不含笔记)
          bargain_original_price, -- 砍价原价
          bargain_base_price -- 砍价底价
FROM
     (SELECT order_id ,
             date(dt) AS dt ,
             promotion_type ,
             user_id ,
             store_promotion_id ,
             status ,
             pay_amt ,
             real_rebate_amt ,
             red_pack_reward_num ,
             finish_time ,
             verify_time
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN date_sub(current_date(),interval 60 DAY) AND date_sub(current_date(),interval 1 DAY) ) a
   LEFT JOIN 
   -- 活动
     (SELECT promotion_id ,
             cost_price, -- 成本价(含笔记)
             net_cost_price, -- 成本价(不含笔记)
             bargain_original_price, -- 砍价原价
             bargain_base_price -- 砍价底价
      FROM dwd.dwd_sr_silkworm_explore_promotion
      WHERE dt BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY) ) b 
  ON a.store_promotion_id=b.promotion_id),

-- 探店订单利润
t11 AS
(SELECT date(finish_time) statistics_date,
       '探店' business_name,
            '收益' cost_typename,
                 user_id,
                 count(1) valid_order_num,
                 sum(CASE WHEN promotion_type = 1 AND cost_price > 0 THEN pay_amt - (real_rebate_amt + cost_price) 
                        WHEN promotion_type = 4 THEN pay_amt - real_rebate_amt 
                        ELSE pay_amt - real_rebate_amt 
                      END 
                    )
                 + sum( CASE WHEN (pay_amt - net_cost_price) >= 0 THEN pay_amt - net_cost_price 
                            ELSE 0 
                          END 
                      ) AS valid_profit,
                 0 unsatisfied_order_num,
                 0 unsatisfied_profit
FROM instore_order_info
WHERE date(finish_time)='${T-1}'
  AND promotion_type IN (1,
                         4 )
  AND status IN (5,
                 19,
                 20,
                 34,
                 35)
GROUP BY 1,
         2,
         3,
         4),


-- 砍价订单利润
t12 AS
  (SELECT date(verify_time) statistics_date,
                            '砍价' business_name,
                                 '收益' cost_typename,
                                      user_id,
                                      count(order_id) AS valid_order_num,
                                      sum(pay_amt) AS valid_profit,
                                      0 unsatisfied_order_num,
                                      0 unsatisfied_profit
   FROM instore_order_info
   WHERE date(verify_time)='${T-1}'
     AND promotion_type IN (5,
                            6,
                            8)
     AND status =5
   GROUP BY 1,
            2,
            3,
            4),


-- 聚合成本指标
t13 AS
  (SELECT statistics_date,
          business_name,
          cost_typename,
          user_id,
          cost_amt
   FROM t4
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt
   FROM t5
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt
   FROM t6
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt
   FROM t7
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt
   FROM t8
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt
   FROM t9
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt
   FROM t10),

-- 聚合订单收益
t14 AS
  ( SELECT statistics_date,
           business_name,
           cost_typename,
           user_id,
           valid_order_num,
           valid_profit,
           unsatisfied_order_num,
           unsatisfied_profit
   FROM wm_income
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    valid_order_num,
                    valid_profit,
                    unsatisfied_order_num,
                    unsatisfied_profit
   FROM t11
   UNION ALL SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    valid_order_num,
                    valid_profit,
                    unsatisfied_order_num,
                    unsatisfied_profit
   FROM t12)




SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    cost_amt,
                    0 valid_order_num,
                    0 valid_profit,
                    0 unsatisfied_order_num,
                    0 unsatisfied_profit

from t13
union all
SELECT statistics_date,
                    business_name,
                    cost_typename,
                    user_id,
                    0 cost_amt,
                    valid_order_num,
                    valid_profit,
                    unsatisfied_order_num,
                    unsatisfied_profit

from t14;



