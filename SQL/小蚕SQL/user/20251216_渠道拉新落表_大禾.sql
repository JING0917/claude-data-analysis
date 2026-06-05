-- 每日渠道用户明细
WITH t01 AS
  (SELECT create_date,
          if(stage IN (2,99),user_id,NULL) AS user_id,
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
            5 ),

-- 广告渠道
ad AS
  (SELECT if(platform IN (20,21),20,platform) AS platform, date, CASE
                                                                     WHEN t1.advertiser_id='79265467' THEN '100'
                                                                     WHEN t1.advertiser_id='79265466' THEN '101'
                                                                     WHEN t1.advertiser_id='79265465' THEN '102'
                                                                     WHEN t1.advertiser_id='79265464' THEN '103'
                                                                     WHEN t1.advertiser_id='79265463' THEN '104'
                                                                     WHEN t1.advertiser_id='79265462' THEN '105'
                                                                     WHEN t1.advertiser_id='79265461' THEN '106'
                                                                     WHEN t1.advertiser_id='79265460' THEN '107'
                                                                     WHEN t1.advertiser_id='79265459' THEN '108'
                                                                     WHEN t1.advertiser_id='79265458' THEN '109'
                                                                     WHEN t1.advertiser_id='1840226988075079' THEN '01'
                                                                     WHEN t1.advertiser_id='1840226987411860' THEN '02'
                                                                     WHEN t1.advertiser_id='1840226986732551' THEN '03'
                                                                     WHEN t1.advertiser_id='1840226986031112' THEN '04'
                                                                     WHEN t1.advertiser_id='1840226985357572' THEN '05'
                                                                     WHEN t1.advertiser_id='1840226984642839' THEN '06'
                                                                     WHEN t1.advertiser_id='1840226983951363' THEN '07'
                                                                     WHEN t1.advertiser_id='1840226983078915' THEN 'iOS01'
                                                                     WHEN t1.advertiser_id='1840226982385860' THEN '08'
                                                                     WHEN t1.advertiser_id='1845484889268295' THEN 'iOS'
                                                                     WHEN t1.advertiser_id='1845484890625155' THEN '11'
                                                                     WHEN t1.advertiser_id='1845484889945159' THEN '12'
                                                                     WHEN t1.advertiser_id='73072489' THEN '200'
                                                                     WHEN t1.advertiser_id='73072494' THEN '201'
                                                                     WHEN t1.advertiser_id='73072497' THEN '202'
                                                                     WHEN t1.advertiser_id='73072500' THEN '203'
                                                                     ELSE coalesce(t2.sub_channel,0)
                                                                 END AS channel,
                                                                 cost
   FROM ods.ods_sr_ad_statement_record_realtime t1
   LEFT JOIN dim.dim_sr_user_nca_channel t2 ON t1.advertiser_id=t2.advertiser_id),



-- 每个渠道每个人平摊花费
t00 AS
  (SELECT a.create_date,
          a.platform,
          a.channel,
          coalesce(cost,0) AS cost_all,
          coalesce(cost,0)/ut AS avg_user_cost from
     (SELECT a.create_date, a.platform, channel, count(DISTINCT a.user_id) AS ut
      FROM t01 a
      LEFT JOIN dim.dim_silkworm_client_user_realtime b ON a.user_id=b.silk_id
      GROUP BY 1,2,3)a
   LEFT JOIN (
    -- 接口同步的渠道花费数据
              SELECT a.date,
                     a.platform_name,
                     a.channel,
                     a.cost
              FROM
                (SELECT date, 
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
                        END AS platform_name,
                        platform,
                        channel,
                        sum(cost/100) AS cost
                 FROM ad a
                 GROUP BY 1,
                          2,
                          3,
                          4 ) a
              JOIN
(SELECT platform,
        days_add(min(date),1) AS min_date, -- 使用每个渠道花费数据上线后的第二天数据
        min(date) AS before_min_date -- 有些渠道使用当天的花费
 FROM ods.ods_sr_ad_statement_record_realtime a -- 线上接口同步的
GROUP BY 1)b ON a.platform=b.platform
              AND ((a.platform IN (80,
                                 90)
                  AND a.date>=b.min_date)
                 OR (a.platform NOT IN (80,
                                      90)
                   AND a.date>=b.before_min_date))
              UNION ALL 
              -- 剩余线下同步的渠道花费数据
              SELECT create_date,
                   lower(channel_name) AS channel_name,
                   sub_channel AS channel,
                   cost
              FROM dwd.dwd_sr_user_nca_cost a -- 线下导入的
) c -- 渠道每日花费表
 ON a.create_date=c.date
   AND lower(a.platform)=lower(c.platform_name)
   AND a.channel=c.channel),


-- 下单
t1 AS
  (SELECT a.order_time,
          a.order_id AS al_order_id,
          if(order_status IN (2,8),a.order_id,NULL) AS order_id,
          a.user_id AS al_user_id,
          if(order_status IN (2,8),a.user_id,NULL) AS user_id,
          a.order_status,
          if(a.order_status=2,profit,0) AS profit,
          if(order_status IN (2,8),b.real_rebate_amt,0) AS real_rebate_amt,
          b.redpacket_id
   FROM
     (SELECT order_time,
             order_id,
             user_id,
             order_status,
             profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt >'2025-03-01' )a
   LEFT JOIN
     (SELECT auto_id,
             order_id,
             redpacket_id,
             used_time,
             user_id,
             real_rebate_amt
      FROM dwd.dwd_sr_market_redpack_use_record
      WHERE dt >='2024-11-01'
        AND redpacket_use_status = 2)b ON a.order_id=b.order_id
   AND a.user_id=b.user_id
   AND length(a.order_id)>0),

-- 下载时间之前最近一次下单时间和下载时间之差
t2 AS
  (SELECT t1.user_id,
          min(datediff(date(t01.create_time),date(t1.order_time)))AS bet_day
   FROM t1
   JOIN t01 ON t1.user_id=t01.user_id
   AND t1.order_time<t01.create_time
   GROUP BY 1),

-- 用户类型
t3 AS
  (SELECT CASE
              WHEN a.stage=2
                   AND b.inviter_silk_id=0
                   AND from_unixtime(b.register_time,'yyyy-MM-dd')>=create_date THEN '无团长新增注册用户'
              WHEN a.stage=2
                   AND b.inviter_silk_id>0
                   AND from_unixtime(b.register_time,'yyyy-MM-dd')>=create_date THEN '有团长新增注册用户'
              WHEN (a.stage=99
                    OR from_unixtime(register_time,'yyyy-MM-dd')<create_date)
                   AND t2.bet_day BETWEEN 0 AND 21 THEN '召回活跃老用户'
              WHEN (a.stage=99
                    OR from_unixtime(register_time,'yyyy-MM-dd')<create_date)
                   AND (t2.bet_day>21
                        OR t2.bet_day IS NULL) THEN '召回流失用户'
              ELSE '其他'
          END AS user_flg,
          a.platform,
          a.channel,
          a.user_id,
          t1.order_id,
          t1.al_user_id,
          t1.al_order_id,
          t1.order_time,
          t1.order_status,
          t1.profit,
          t1.real_rebate_amt,
          a.create_time,
          a.create_date,
          t1.user_id AS order_user_id,
          datediff(date(t1.order_time), a.create_date) AS bet_day1, -- 老用户下单时间和下载时间之差
          datediff(date(t1.order_time), date(from_unixtime(b.register_time,'yyyy-MM-dd'))) AS bet_day2 -- 新用户下单时间和注册时间之差
   FROM t01 a
   LEFT JOIN dim.dim_silkworm_client_user_realtime b ON a.user_id=b.silk_id
   LEFT JOIN t1 ON a.user_id=t1.al_user_id
   LEFT JOIN t2 ON a.user_id=t2.user_id),

-- 用户类型数据集
t4 AS
  (SELECT a.* from
     (SELECT platform,channel,create_date,count(DISTINCT user_flg) AS flg_ct
      FROM t3
      GROUP BY 1,2,3 HAVING flg_ct=1)a
   JOIN t3 ON a.platform=t3.platform
   AND a.channel=t3.channel
   AND a.create_date=t3.create_date
   WHERE t3.user_flg='其他')


SELECT t3.create_date,
       t3.channel,
       '无团长新增注册用户' AS user_flg,
       '新增注册用户' AS new_or_not,
       t3.platform,
       cost_all AS avg_user_cost,
       0 AS user_ut,
       0 AS order_user_ut0,
       0 AS order_user_ut7,
       0 AS order_user_ut14,
       0 AS order_user_ut30,
       0 AS order_user_ut_all,
       0 AS order_ct0,
       0 AS order_ct7,
       0 AS order_ct14,
       0 AS order_ct30,
       0 AS order_ct_all,
       0 AS profit0,
       0 AS profit7,
       0 AS profit14,
       0 AS profit30,
       0 AS profit_all,
       0 AS real_rebate_amt0,
       0 AS real_rebate_amt7,
       0 AS real_rebate_amt14,
       0 AS real_rebate_amt30,
       0 AS real_rebate_amt_all,
       0 AS baoming_ut,
       0 AS baoming_ot
FROM t3
JOIN t4 ON t3.create_date=t4.create_date
AND t3.platform=t4.platform
AND t3.channel=t4.channel
JOIN t00 ON t3.create_date=t00.create_date
AND t3.platform=t00.platform
AND t3.channel=t00.channel
WHERE user_flg IN ('其他')
  AND t00.cost_all>0
GROUP BY 1,
         2,
         3,
         4,
         5,
         6
UNION ALL
SELECT t.date,
       t.channel,
       '无团长新增注册用户' AS user_flg,
       '新增注册用户' AS new_or_not,
       t.platform,
       t.cost,
       0 AS user_ut,
       0 AS order_user_ut0,
       0 AS order_user_ut7,
       0 AS order_user_ut14,
       0 AS order_user_ut30,
       0 AS order_user_ut_all,
       0 AS order_ct0,
       0 AS order_ct7,
       0 AS order_ct14,
       0 AS order_ct30,
       0 AS order_ct_all,
       0 AS profit0,
       0 AS profit7,
       0 AS profit14,
       0 AS profit30,
       0 AS profit_all,
       0 AS real_rebate_amt0,
       0 AS real_rebate_amt7,
       0 AS real_rebate_amt14,
       0 AS real_rebate_amt30,
       0 AS real_rebate_amt_all,
       0 AS baoming_ut,
       0 AS baoming_ot
FROM
  (SELECT date, CASE
                    WHEN platform=1 THEN 'vivo'
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
                END AS platform_name,
                platform,
                channel,
                sum(cost/100) AS cost
   FROM ad a
   GROUP BY 1,
            2,
            3,
            4)t
JOIN t3 ON t.platform=t3.platform
AND t.channel=t3.channel
AND t.date=t3.create_date
WHERE t3.platform IS NULL
GROUP BY 1,
         2,
         3,
         4,
         5,
         6
UNION ALL
SELECT t3.create_date,
       t3.channel,
       user_flg,
       '新增注册用户' AS new_or_not,
       t3.platform,
       avg_user_cost,
       count(DISTINCT user_id) AS user_ut,
       count(DISTINCT if(bet_day2=0,order_user_id,NULL)) AS order_user_ut0,
       count(DISTINCT if(bet_day2 BETWEEN 0 AND 6,order_user_id,NULL)) AS order_user_ut7,
       count(DISTINCT if(bet_day2 BETWEEN 0 AND 13,order_user_id,NULL)) AS order_user_ut14,
       count(DISTINCT if(bet_day2 BETWEEN 0 AND 29,order_user_id,NULL)) AS order_user_ut30,
       count(DISTINCT order_user_id) AS order_user_ut_all,
       count(DISTINCT if(bet_day2=0,order_id,NULL)) AS order_ct0,
       count(DISTINCT if(bet_day2 BETWEEN 0 AND 6 ,order_id,NULL)) AS order_ct7,
       count(DISTINCT if(bet_day2 BETWEEN 0 AND 13,order_id,NULL)) AS order_ct14,
       count(DISTINCT if(bet_day2 BETWEEN 0 AND 29,order_id,NULL)) AS order_ct30,
       count(DISTINCT order_id) AS order_ct_all,
       sum(if(bet_day2=0
              AND order_status=2,profit,0)) AS profit0,
       sum(if(bet_day2 BETWEEN 0 AND 6
              AND order_status=2,profit,0)) AS profit7,
       sum(if(bet_day2 BETWEEN 0 AND 13
              AND order_status=2,profit,0)) AS profit14,
       sum(if(bet_day2 BETWEEN 0 AND 29
              AND order_status=2,profit,0)) AS profit30,
       sum(if(order_status=2,profit,0)) AS profit_all,
       sum(if(bet_day2 =0 ,real_rebate_amt,0)) AS real_rebate_amt0,
       sum(if(bet_day2 BETWEEN 0 AND 6 ,real_rebate_amt,0)) AS real_rebate_amt7,
       sum(if(bet_day2 BETWEEN 0 AND 13 ,real_rebate_amt,0)) AS real_rebate_amt14,
       sum(if(bet_day2 BETWEEN 0 AND 29 ,real_rebate_amt,0)) AS real_rebate_amt30,
       sum(coalesce(real_rebate_amt,0)) AS real_rebate_amt_all,
       count(DISTINCT if(bet_day1=0,al_user_id,NULL)) AS baoming_ut,
       count(DISTINCT if(bet_day1=0,al_order_id,NULL)) AS baoming_ot
FROM t3
LEFT JOIN t00 ON t3.create_date=t00.create_date
AND t3.platform=t00.platform
AND t3.channel=t00.channel
WHERE user_flg IN ('无团长新增注册用户',
                   '有团长新增注册用户')
GROUP BY 1,
         2,
         3,
         4,
         5,
         6
UNION ALL
SELECT t3.create_date,
       t3.channel,
       user_flg,
       '召回老用户' AS new_or_not,
       t3.platform,
       avg_user_cost,
       count(DISTINCT user_id) AS user_ut,
       count(DISTINCT if(bet_day1=0,order_user_id,NULL)) AS order_user_ut0,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 6,order_user_id,NULL)) AS order_user_ut7,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 13,order_user_id,NULL)) AS order_user_ut14,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 29,order_user_id,NULL)) AS order_user_ut30,
       count(DISTINCT if(bet_day1 >=0,order_user_id,NULL)) AS order_user_ut_all,
       count(DISTINCT if(bet_day1=0,order_id,NULL)) AS order_ct0,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 6,order_id,NULL)) AS order_ct7,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 13,order_id,NULL)) AS order_ct14,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 29,order_id,NULL)) AS order_ct30,
       count(DISTINCT if(bet_day1 BETWEEN 0 AND 1095 ,order_id,NULL)) AS order_ct_all,
       sum(if(bet_day1 =0
              AND order_status=2,profit,0)) AS profit0,
       sum(if(bet_day1 BETWEEN 0 AND 6
              AND order_status=2,profit,0)) AS profit7,
       sum(if(bet_day1 BETWEEN 0 AND 13
              AND order_status=2,profit,0)) AS profit14,
       sum(if(bet_day1 BETWEEN 0 AND 29
              AND order_status=2,profit,0)) AS profit30,
       sum(if(bet_day1 BETWEEN 0 AND 1095
              AND order_status=2,profit,0)) AS profit_all,
       sum(if(bet_day1 =0 ,real_rebate_amt,0)) AS real_rebate_amt0,
       sum(if(bet_day1 BETWEEN 0 AND 6 ,real_rebate_amt,0)) AS real_rebate_amt7,
       sum(if(bet_day1 BETWEEN 0 AND 13 ,real_rebate_amt,0)) AS real_rebate_amt14,
       sum(if(bet_day1 BETWEEN 0 AND 29 ,real_rebate_amt,0)) AS real_rebate_amt30,
       sum(if(bet_day1 BETWEEN 0 AND 1095,real_rebate_amt,0)) AS real_rebate_amt_all,
       count(DISTINCT if(bet_day1=0,al_user_id,NULL)) AS baoming_ut,
       count(DISTINCT if(bet_day1=0,al_order_id,NULL)) AS baoming_ot
FROM t3
LEFT JOIN t00 ON t3.create_date=t00.create_date
AND t3.platform=t00.platform
AND t3.channel=t00.channel
WHERE user_flg IN ('召回活跃老用户',
                   '召回流失用户')
GROUP BY 1,
         2,
         3,
         4,
         5,
         6 ;

================================== 仅处理每日各渠道用户花费
-- drop table if exists dwd.dwd_sr_user_newuser_channel_cost_d;

CREATE TABLE IF NOT EXISTS dwd.dwd_sr_user_newuser_channel_cost_d (
    statistics_date DATE NOT NULL COMMENT '统计日期',
    business_name VARCHAR(32) NOT NULL COMMENT '业务线',
    cost_typename VARCHAR(128) NOT NULL COMMENT '成本类型名称',
    user_id INT NOT NULL COMMENT '用户ID',
    cost_amt DECIMAL(12,2) NOT NULL DEFAULT '0.00' COMMENT '花费',
    valid_order_num INT COMMENT '有效订单量(外卖是有效订单,探店是完单,砍价是核销)',
    valid_profit DECIMAL(12,2) NOT NULL DEFAULT '0.00' COMMENT '有效订单利润(外卖是已审核订单利润,探店是完单利润,砍价是核销利润)',
    unsatisfied_order_num INT COMMENT '不满意订单量(仅外卖业务)',
    unsatisfied_profit DECIMAL(12,2) DEFAULT '0.00' COMMENT '不满意订单利润(仅外卖业务)'
) 
ENGINE=OLAP
DUPLICATE KEY(statistics_date, business_name, cost_typename, user_id)
COMMENT "新用户渠道花费日数据"
DISTRIBUTED BY HASH(statistics_date,user_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);


-- 每日渠道用户明细
WITH newuser_detail AS
  (SELECT create_date,
          if(stage IN (2,99),user_id,NULL) AS user_id,
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
            5 ),

-- 渠道花费
tot_cost AS
  (SELECT if(platform IN (20,21),20,platform) AS platform, date, CASE
                                                                     WHEN t1.advertiser_id='79265467' THEN '100'
                                                                     WHEN t1.advertiser_id='79265466' THEN '101'
                                                                     WHEN t1.advertiser_id='79265465' THEN '102'
                                                                     WHEN t1.advertiser_id='79265464' THEN '103'
                                                                     WHEN t1.advertiser_id='79265463' THEN '104'
                                                                     WHEN t1.advertiser_id='79265462' THEN '105'
                                                                     WHEN t1.advertiser_id='79265461' THEN '106'
                                                                     WHEN t1.advertiser_id='79265460' THEN '107'
                                                                     WHEN t1.advertiser_id='79265459' THEN '108'
                                                                     WHEN t1.advertiser_id='79265458' THEN '109'
                                                                     WHEN t1.advertiser_id='1840226988075079' THEN '01'
                                                                     WHEN t1.advertiser_id='1840226987411860' THEN '02'
                                                                     WHEN t1.advertiser_id='1840226986732551' THEN '03'
                                                                     WHEN t1.advertiser_id='1840226986031112' THEN '04'
                                                                     WHEN t1.advertiser_id='1840226985357572' THEN '05'
                                                                     WHEN t1.advertiser_id='1840226984642839' THEN '06'
                                                                     WHEN t1.advertiser_id='1840226983951363' THEN '07'
                                                                     WHEN t1.advertiser_id='1840226983078915' THEN 'iOS01'
                                                                     WHEN t1.advertiser_id='1840226982385860' THEN '08'
                                                                     WHEN t1.advertiser_id='1845484889268295' THEN 'iOS'
                                                                     WHEN t1.advertiser_id='1845484890625155' THEN '11'
                                                                     WHEN t1.advertiser_id='1845484889945159' THEN '12'
                                                                     WHEN t1.advertiser_id='73072489' THEN '200'
                                                                     WHEN t1.advertiser_id='73072494' THEN '201'
                                                                     WHEN t1.advertiser_id='73072497' THEN '202'
                                                                     WHEN t1.advertiser_id='73072500' THEN '203'
                                                                     ELSE coalesce(t2.sub_channel,0)
                                                                 END AS channel,
                                                                 cost/100 AS cost
   FROM ods.ods_sr_ad_statement_record_realtime t1
   LEFT JOIN dim.dim_sr_user_nca_channel t2 ON t1.advertiser_id=t2.advertiser_id),


-- 渠道用户量
peruser_cost AS
  (SELECT a.create_date,
          a.platform_type,
          a.channel,
          user_num,
          cost,
          cost/user_num peruser_cost
   FROM
     (SELECT create_date,
             platform_type,
             channel,
             count(DISTINCT user_id) user_num
      FROM newuser_detail
      WHERE user_id IS NOT NULL
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN tot_cost b ON a.create_date=b.date
   AND a.platform_type=b.platform
   AND a.channel=b.channel)




SELECT a.create_date,
       a.platform_type,
       a.platform AS platform_name,
       a.channel,
       a.stage,
       a.user_id,
       b.peruser_cost
FROM newuser_detail a
LEFT JOIN peruser_cost b ON a.create_date=b.create_date
AND a.platform_type=b.platform_type
AND a.channel=b.channel
WHERE a.user_id IS NOT NULL;











