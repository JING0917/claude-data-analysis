######################################################################################################
-- 外卖核心指标日报
-- 注册用户量+DAU+外卖销单率
WITH t1 AS
  (SELECT date_sub(current_date(),interval 1 DAY) AS statistics_date,
          count(1) accu_user_num,
   count(if(date_format(register_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY),user_id,NULL)) lastd_user_num,
   count(if(date_format(register_time,'%Y-%m-%d')=date_sub(current_date(),interval 2 DAY),user_id,NULL)) last2d_user_num
   FROM dim.dim_silkworm_user
   GROUP BY 1),

-- dau
t2 AS
  (SELECT date_format(latest_login_time,'%Y-%m-%d') dt,
                                       count(user_id) dau
   FROM dim.dim_silkworm_user
   WHERE date_format(latest_login_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY)
   GROUP BY 1),



-- 自营外卖销单率
t4 AS
  (SELECT b.dt,
          pro_num,
          promotion_quota,
          valid_order_num,
          profit,
          last2d_pro_num,
          last2d_promotion_quota,
          last2d_valid_order_num,
          last2d_profit,
          lasty_pro_num,
          lasty_promotion_quota,
          lasty_valid_order_num,
          lasty_profit
   FROM
     (SELECT dt,
             pro_num,
             promotion_quota,
             valid_order_num,
             profit,
             lag(pro_num) over(
                               ORDER BY dt) AS last2d_pro_num,
                          lag(promotion_quota) over(
                                                    ORDER BY dt) AS last2d_promotion_quota,
                                               lag(valid_order_num) over(
                                                                         ORDER BY dt) AS last2d_valid_order_num,
                                                                    lag(profit) over(
                                                                                     ORDER BY dt) AS last2d_profit
      FROM
        (SELECT dt,
                count(1) pro_num,
                         sum(promotion_quota) promotion_quota,
                                              sum(valid_order_num) valid_order_num,
                                                                   sum(profit) profit
         FROM dws.dws_sr_store_takeawaypro_statis_d
         WHERE dt BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         GROUP BY 1) a) b
   LEFT JOIN
     (SELECT dt,
             count(1) lasty_pro_num,
                      sum(promotion_quota) lasty_promotion_quota,
                                           sum(valid_order_num) lasty_valid_order_num,
                                                                sum(profit) lasty_profit
      FROM dws.dws_sr_store_takeawaypro_statis_d
      WHERE dt=date_sub(current_date(),interval 7 DAY)
      GROUP BY 1) c ON c.dt=date_sub(b.dt,interval 6 DAY)
   WHERE b.dt=date_sub(current_date(),interval 1 DAY)
   ),


-- 到店在线活动名额
t5 AS
  (SELECT promotion_online_date,
          explore_online_quota,
          bargain_online_quota,
          last2d_explore_online_quota,
          last2d_bargain_online_quota
   FROM
     (SELECT promotion_online_date,
             explore_online_quota,
             bargain_online_quota,
             lag(explore_online_quota) over(
                                            ORDER BY promotion_online_date) AS last2d_explore_online_quota,
                                       lag(bargain_online_quota) over(
                                                                      ORDER BY promotion_online_date) AS last2d_bargain_online_quota
      FROM
        (SELECT promotion_online_date,
                sum(if(promotion_type IN (1,4) and is_booking_enabled = 1,booking_daily_quota,tot_promotion_quota)) AS explore_online_quota,
                sum(if(promotion_type IN (5,6,8),tot_promotion_quota,0)) AS bargain_online_quota
         FROM dws.dws_sr_silkworm_explore_promotion_df
         WHERE promotion_type IN (1,
                                  4,
                                  5,
                                  6,
                                  8)
           AND promotion_status_type = '售卖中'
           AND promotion_online_date BETWEEN date_sub(CURRENT_DATE(),interval 2 DAY) AND date_sub(CURRENT_DATE(),interval 1 DAY)
         GROUP BY 1) a) b
   WHERE b.promotion_online_date=date_sub(CURRENT_DATE(),interval 1 DAY)
    ),

-- 到店支付+核销+完单+利润
-- 支付
t6 AS
  (SELECT pay_date,
          explore_payord_num,
          bargain_payord_num,
          last2d_explore_payord_num,
          last2d_bargain_payord_num
   FROM
     (SELECT pay_date,
             explore_payord_num,
             bargain_payord_num,
             lag(explore_payord_num) over (
                                           ORDER BY pay_date) AS last2d_explore_payord_num,
                                     lag(bargain_payord_num) over (
                                                                   ORDER BY pay_date) AS last2d_bargain_payord_num
      FROM
        (SELECT date_format(pay_time,'%Y-%m-%d') pay_date,
                                                 count(if(promotion_type IN (1,4),order_id,NULL)) explore_payord_num,
                                                                                                  count(if(promotion_type IN (5,6,8),order_id,NULL)) bargain_payord_num
         FROM dwd.dwd_sr_silkworm_explore_order
         WHERE dt BETWEEN date_sub(current_date(),interval 60 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND date_format(pay_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 3 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND promotion_type IN (1,
                                  4,
                                  5,
                                  6,
                                  8)
         GROUP BY 1) a) b
   WHERE pay_date=date_sub(current_date(),interval 1 DAY)
    ),

-- 核销
t7 AS
  (SELECT verify_date,
          explore_verord_num,
          bargain_verord_num,
          last2d_explore_verord_num,
          last2d_bargain_verord_num
   FROM
     (SELECT verify_date,
             explore_verord_num,
             bargain_verord_num,
             lag(explore_verord_num) over (
                                           ORDER BY verify_date) AS last2d_explore_verord_num,
                                     lag(bargain_verord_num) over (
                                                                   ORDER BY verify_date) AS last2d_bargain_verord_num
      FROM
        (SELECT date_format(verify_time,'%Y-%m-%d') verify_date,
                                                 count(if(promotion_type IN (1,4),order_id,NULL)) explore_verord_num,
                                                                                                  count(if(promotion_type IN (5,6,8),order_id,NULL)) bargain_verord_num
         FROM dwd.dwd_sr_silkworm_explore_order
         WHERE dt BETWEEN date_sub(current_date(),interval 60 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND date_format(verify_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 3 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND promotion_type IN (1,
                                  4,
                                  5,
                                  6,
                                  8)
         GROUP BY 1) a) b
   WHERE verify_date=date_sub(current_date(),interval 1 DAY)
    ),


-- 完单
t8 AS
  (SELECT finish_date,
          explore_finord_num,
          last2d_explore_finord_num
   FROM
     (SELECT finish_date,
             explore_finord_num,
             lag(explore_finord_num) over (
                                           ORDER BY finish_date) AS last2d_explore_finord_num
      FROM
        (SELECT date_format(finish_time,'%Y-%m-%d') finish_date,
                                                    count(order_id) explore_finord_num
         FROM dwd.dwd_sr_silkworm_explore_order
         WHERE dt BETWEEN date_sub(current_date(),interval 60 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND date_format(finish_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 3 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND status IN (5,
                          19,
                          20,
                          34,
                          35)
           AND promotion_type IN (1,
                                  4)
         GROUP BY 1) a) b
   WHERE finish_date=date_sub(current_date(),interval 1 DAY)),

-- 到店完单利润
t9 
as (
select
    finish_date,
    explore_profit,
    bargain_profit,
    last2d_explore_profit,
    last2d_bargain_profit 
from    
(select
    finish_date,
    explore_profit,
    bargain_profit,
    lag(explore_profit) over(order by finish_date) as last2d_explore_profit,
    lag(bargain_profit) over(order by finish_date) as last2d_bargain_profit
from
(select
    finish_date,
    sum( if( promotion_type IN (1, 4)
                      AND status IN (5, 19, 20, 34, 35), CASE WHEN a.promotion_type = 1
                      AND b.cost_price > 0 THEN a.pay_amt - (a.real_rebate_amt + b.cost_price) WHEN a.promotion_type = 4 THEN a.pay_amt - a.real_rebate_amt ELSE a.pay_amt - a.real_rebate_amt END, 0 ) ) 
    +
    sum(if( promotion_type IN (1, 4)
             AND status IN (5, 19, 20, 34, 35), CASE WHEN (b.net_cost_price - a.pay_amt) >= 0 THEN b.net_cost_price - a.pay_amt ELSE 0 END, 0 )) as explore_profit,
    sum(if(promotion_type in (5,6,8) and status=5,pay_amt,0)) as bargain_profit
from
  (SELECT order_id ,
          date_format(finish_time,'%Y-%m-%d') AS finish_date ,
          promotion_type ,
          user_id ,
          store_promotion_id ,
          status ,
          pay_amt ,
          real_rebate_amt ,
          red_pack_reward_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub(current_date(),interval 60 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND date_format(finish_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 3 DAY) AND date_sub(current_date(),interval 1 DAY) ) a
LEFT JOIN 
  (SELECT promotion_id,
          cost_price,
          net_cost_price ,
          bargain_original_price ,
          bargain_base_price
   FROM dwd.dwd_sr_silkworm_explore_promotion
   WHERE dt BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY) ) b ON a.store_promotion_id=b.promotion_id
GROUP BY 1) toa
) tob
where finish_date=date_sub(current_date(),interval 1 DAY)
),


-- 总营销支出
 t10 AS
  (SELECT statistics_date,
          cost_amt,
          last2d_cost_amt
   FROM
     (SELECT statistics_date,
             cost_amt,
             lag(cost_amt) over(
                                ORDER BY statistics_date) AS last2d_cost_amt
      FROM
        (SELECT statistics_date,
                sum(cost_amt) cost_amt
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),


-- 外卖有效订单量和利润
t11 AS
  (SELECT order_date,
          order_num,
          profit,
          last2d_order_num,
          last2d_profit
   FROM
     (SELECT order_date,
             order_num,
             profit,
             lag(order_num) over(
                                 ORDER BY order_date) last2d_order_num,
                                                      lag(profit) over(
                                                                       ORDER BY order_date) last2d_profit
      FROM
        (SELECT date_format(order_time,'%Y-%m-%d') order_date,
                                                   count(1) order_num,
                                                            sum(profit) profit
         FROM dwd.dwd_sr_order_promotion_order
         WHERE dt BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY) 
            AND date_format(order_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 3 DAY) AND date_sub(current_date(),interval 1 DAY)
            AND order_status IN (2,
                                 8)
         GROUP BY 1) a) b
   WHERE order_date=date_sub(current_date(),interval 1 DAY)),

-- 团长拉新
 t12 AS
  (SELECT statistics_date,
          cost_amt,
          last2d_cost_amt
   FROM
     (SELECT statistics_date,
             cost_amt,
             lag(cost_amt) over(
                                ORDER BY statistics_date) AS last2d_cost_amt
      FROM
        (SELECT statistics_date,
                sum(cost_amt) cost_amt
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         and cost_typename='团长拉新奖励'
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),


-- 新人首单红包
 t13 AS
  (SELECT statistics_date,
          cost_amt,
          last2d_cost_amt
   FROM
     (SELECT statistics_date,
             cost_amt,
             lag(cost_amt) over(
                                ORDER BY statistics_date) AS last2d_cost_amt
      FROM
        (SELECT statistics_date,
                sum(cost_amt) cost_amt
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         and cost_typename='新人首单红包'
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),

-- 新人3单红包
 t14 AS
  (SELECT statistics_date,
          cost_amt,
          last2d_cost_amt
   FROM
     (SELECT statistics_date,
             cost_amt,
             lag(cost_amt) over(
                                ORDER BY statistics_date) AS last2d_cost_amt
      FROM
        (SELECT statistics_date,
                sum(cost_amt) cost_amt
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         and cost_typename='新人3单红包'
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),

-- 20251110 切换新数据源 修改人：dahe
-- 渠道拉新
 t15 AS
  (SELECT statistics_date,
          cost_amt,
          last2d_cost_amt
   FROM
     (SELECT statistics_date,
             cost_amt,
             lag(cost_amt) over(
                                ORDER BY statistics_date) AS last2d_cost_amt
      FROM
        (SELECT date_format(created_at,'%Y-%m-%d') as statistics_date,
                sum(cost/100) cost_amt
         FROM ods.ods_sr_ad_statement_record_realtime
         WHERE date_format(created_at,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 3 DAY) AND date_sub(current_date(),interval 1 DAY)
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),



-- 抽奖
 t16 AS
  (SELECT statistics_date,
          cost_amt,
          last2d_cost_amt
   FROM
     (SELECT statistics_date,
             cost_amt,
             lag(cost_amt) over(
                                ORDER BY statistics_date) AS last2d_cost_amt
      FROM
        (SELECT statistics_date,
                sum(cost_amt) cost_amt
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         and cost_typename='抽奖'
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),

-- 下单挑战赛和ma红包
 t17 AS
  (SELECT statistics_date,
          tz_cost,
          ma_cost,
          last2d_tz_cost,
          last2d_ma_cost
   FROM
     (SELECT statistics_date,
             tz_cost,
             ma_cost,
             lag(tz_cost) over(ORDER BY statistics_date) AS last2d_tz_cost,
             lag(ma_cost) over(ORDER BY statistics_date) AS last2d_ma_cost
      FROM
        (SELECT statistics_date,
                sum(if(cost_typename='下单挑战赛',cost_amt,0)) tz_cost,
                sum(if(cost_typename='MA发放红包',cost_amt,0)) ma_cost
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         and cost_typename IN ('下单挑战赛','MA发放红包')
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),


select
    t1.statistics_date `统计日期`,
    t1.accu_user_num `截止昨日累计注册用户量`,
    t1.lastd_user_num `昨日注册用户量`,
    t1.lastd_user_num/last2d_user_num-1 `注册用户量环比`,
    t2.dau/t1.accu_user_num `昨日访问率`,
    t4.valid_order_num/t4.promotion_quota `昨日自营外卖销单率`,
    t2.dau `昨日全站DAU`,
    t11.order_num `昨日外卖有效订单量`,
    t11.profit `昨日外卖有效订单利润`,
    t11.order_num/t11.last2d_order_num-1 `昨日外卖有效订单量环比`,
    t11.profit/t11.last2d_profit-1 `昨日外卖有效订单利润环比`,
    t4.pro_num `昨日自营外卖活动数`,
    t4.pro_num/last2d_pro_num-1 `自营外卖活动数据环比`,
    t4.pro_num/lasty_pro_num-1 `自营外卖活动数据同比`,
    t4.promotion_quota `昨日自营外卖活动名额`,
    t4.promotion_quota/last2d_promotion_quota-1 `自营外卖活动名额环比`,
    t4.promotion_quota/lasty_promotion_quota-1 `自营外卖活动名额同比`,
    t4.valid_order_num `昨日自营外卖有效订单量`,
    t4.valid_order_num/last2d_valid_order_num-1 `自营外卖有效订单量环比`,
    t4.valid_order_num/lasty_valid_order_num-1 `自营外卖有效订单量同比`,
    t4.profit `昨日自营外卖有效订单利润`,
    t4.profit/t4.last2d_profit-1 `昨日自营外卖有效订单利润环比`,
    t4.profit/t4.lasty_profit-1 `自营外卖有效订单利润同比`,
    t5.explore_online_quota `昨日探店在线活动名额`,
    t5.explore_online_quota/last2d_explore_online_quota-1 `探店在线活动名额环比`,
    t5.bargain_online_quota `昨日砍价在线活动名额`,
    t5.bargain_online_quota/last2d_bargain_online_quota-1 `砍价在线活动名额环比`,
    t6.explore_payord_num `昨日探店支付订单量`,
    t6.explore_payord_num/last2d_explore_payord_num-1 `探店支付订单量环比`,
    t6.bargain_payord_num `昨日砍价支付订单量`,
    t6.bargain_payord_num/last2d_bargain_payord_num-1 `砍价支付订单量环比`,
    t7.explore_verord_num `昨日探店核销订单量`,
    t7.explore_verord_num/last2d_explore_verord_num-1 `探店核销订单量环比`,
    t7.bargain_verord_num `昨日砍价核销订单量`,
    t7.bargain_verord_num/last2d_bargain_verord_num-1 `砍价核销订单量环比`,
    t8.explore_finord_num `昨日探店完单订单量`,
    t8.explore_finord_num/last2d_explore_finord_num-1 `探店完单订单量环比`,
    t9.explore_profit `昨日探店利润`,
    t9.explore_profit/last2d_explore_profit-1 `探店利润环比`,
    t9.bargain_profit `昨日砍价利润`,
    t9.bargain_profit/last2d_bargain_profit-1 `砍价利润环比`,
    t10.cost_amt `昨日营销支出`,
    t10.cost_amt/t10.last2d_cost_amt-1 `营销支出环比`,
    t12.cost_amt `昨日团长拉新支出`,
    t12.cost_amt/t12.last2d_cost_amt-1 `团长拉新支出环比`,
    t13.cost_amt `昨日新人首单红包消耗`,
    t13.cost_amt/t13.last2d_cost_amt-1 `新人首单红包消耗环比`,
    t14.cost_amt `昨日新人3单红包消耗`,
    t14.cost_amt/t14.last2d_cost_amt-1 `新人3单红包消耗环比`,
    t15.cost_amt `渠道拉新支出`,
    t15.cost_amt/t15.last2d_cost_amt-1 `渠道拉新支出环比`,
    t16.cost_amt `昨日抽奖支出`,
    t16.cost_amt/t16.last2d_cost_amt-1 `抽奖支出环比`,
    t17.tz_cost `昨日下单挑战赛支出`,
    t17.tz_cost/t17.last2d_tz_cost-1 下单挑战赛支出环比`,
    t17.ma_cost `昨日MA红包支出`,
    t17.ma_cost/t17.last2d_ma_cost-1 MA红包支出环比`
from t1 left join t2 on t1.statistics_date=t2.dt
left join t4 on t1.statistics_date=t4.dt
left join t5 on t1.statistics_date=t5.promotion_online_date
left join t6 on t1.statistics_date=t6.pay_date
left join t7 on t1.statistics_date=t7.verify_date
left join t8 on t1.statistics_date=t8.finish_date
left join t9 on t1.statistics_date=t9.finish_date
left join t10 on t1.statistics_date=t10.statistics_date
left join t11 on t1.statistics_date=t11.order_date
left join t12 on t1.statistics_date=t12.statistics_date
left join t13 on t1.statistics_date=t13.statistics_date
left join t14 on t1.statistics_date=t14.statistics_date
left join t15 on t1.statistics_date=t15.statistics_date
left join t16 on t1.statistics_date=t16.statistics_date
left join t17 on t1.statistics_date=t17.statistics_date
######################################################################################################


######################################################################################################
-- 产品+运营考核指标日报（加一部分主要业务指标）

-- 指标
-- DAU 月日均DAU 用户次2日留存 新用户 不同访问天数用户
-- 注册用户量 团长拉新用户量 渠道拉新用户量 自然增长用户量 拉新团长数
-- 自营活动数 自营活动名额 
-- 自营报名订单量 自营有效订单量 自营取消订单量 自营手动取消订单量 自营超时取消订单量 月有效订单量 年累计有效订单量
-- 总营销支出 新人首单 新人3单红包 团长拉新 渠道拉新 下单挑战赛 MA红包 抽奖




-- 月日均DAU
WITH daily_dau AS (
    SELECT
        dt,
        bitmap_union_count(user_ids) AS dau
    FROM dwd.dwd_sr_traffic_viewuser_d
    WHERE dt >= DATE_TRUNC('month', DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
      AND dt <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    GROUP BY dt
),

monthly_avg AS (
    SELECT
        CASE
            WHEN dt >= DATE_TRUNC('month', CURRENT_DATE()) THEN 'current'
            ELSE 'previous'
        END AS month_type,
        AVG(dau) AS avg_dau
    FROM daily_dau
    GROUP BY month_type
),

-- 月日均DAU
t1 as (SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS statistics_date,
    COALESCE(MAX(CASE WHEN month_type = 'current' THEN avg_dau END), 0) AS cur_avg_dau,
    COALESCE(MAX(CASE WHEN month_type = 'previous' THEN avg_dau END), 0) AS lastm_avg_dau
FROM monthly_avg),


-- dau
t2 AS
  (SELECT dt,
          dau,
          last2d_dau
   FROM
     (SELECT dt,
             dau,
             lag(dau) over(
                           ORDER BY dt) last2d_dau
      FROM
        (SELECT dt,
                bitmap_union_count(user_ids) dau
         FROM dwd.dwd_sr_traffic_viewuser_d
         WHERE dt BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         GROUP BY 1) a) b
   WHERE dt=date_sub(current_date(),interval 1 DAY)),


-- 日活拆分
t3 AS
  (SELECT
    dt,
    MAX(IF(user_type = '注册', DAU, 0)) AS register_num,
    MAX(IF(user_type = '近30天无访问', DAU, 0)) AS recall_num,
    MAX(IF(user_type = '近30天访问1-6天', DAU, 0)) AS view6_num,
    MAX(IF(user_type = '近30天访问7-12天', DAU, 0)) AS view12_num,
    MAX(IF(user_type = '近30天访问13-18天', DAU, 0)) AS view18_num,
    MAX(IF(user_type = '近30天访问19-24天', DAU, 0)) AS view24_num,
    MAX(IF(user_type = '近30天访问25-30天', DAU, 0)) AS view30_num
FROM dwd.dwd_sr_user_retention_d
WHERE dt = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  AND user_type IN ('注册','近30天无访问','近30天访问1-6天','近30天访问7-12天','近30天访问13-18天','近30天访问19-24天','近30天访问25-30天')
GROUP BY dt),

-- 注册用户
t4 AS
  (SELECT register_date,
          newuser_num,
          last2d_newuser_num
   FROM
     (SELECT register_date,
             newuser_num,
             lag(newuser_num) over(
                                   ORDER BY register_date) last2d_newuser_num
      FROM
        (SELECT date(register_time) register_date,
                                    count(*) newuser_num
         FROM dim.dim_silkworm_user
         WHERE date(register_time) BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         GROUP BY 1) a) b
   WHERE register_date=date_sub(current_date(),interval 1 DAY)),

-- 注册用户拆分
t5 AS
  (SELECT register_date,
          count(if(is_tz=1
                   AND b.user_id IS NULL,a.user_id,NULL)) tz_newuser_num,
          count(if(b.user_id IS NOT NULL,a.user_id,NULL)) qd_newuser_num,
          count(if(is_tz=0 AND b.user_id IS NULL,a.user_id,NULL)) zr_newuser_num
   FROM
     (SELECT date(register_time) register_date,
                                 user_id,
                                 if(inviter_user_id=0,0,1) is_tz
      FROM dim.dim_silkworm_user
      WHERE date(register_time)=date_sub(current_date(),interval 1 DAY)) a
   LEFT JOIN -- 渠道拉新

     (SELECT user_id
      FROM dwd.dwd_sr_user_newuser_channel_cost_d
      WHERE statistics_date=date_sub(current_date(),interval 1 DAY)
        AND user_type=2
      GROUP BY 1) b ON a.user_id=b.user_id
   GROUP BY 1),

-- 自营订单
t6 AS (
SELECT dt,
       quota,
       ordnum,
       valid_ordnum,
       cancel_ordnum,
       handle_cancel_ordnum,
       timeout_cancel_ordnum,
       last2d_quota,
       last2d_ordnum,
       last2d_valid_ordnum,
       last2d_cancel_ordnum,
       last2d_handle_cancel_ordnum,
       last2d_timeout_cancel_ordnum
FROM
  (SELECT dt,
          quota,
          ordnum,
          valid_ordnum,
          cancel_ordnum,
          handle_cancel_ordnum,
          timeout_cancel_ordnum,
          lag(quota) over(ORDER BY dt) last2d_quota,
          lag(ordnum) over(ORDER BY dt) last2d_ordnum,
          lag(valid_ordnum) over(ORDER BY dt) last2d_valid_ordnum,
          lag(cancel_ordnum) over(ORDER BY dt) last2d_cancel_ordnum,
          lag(handle_cancel_ordnum) over(ORDER BY dt) last2d_handle_cancel_ordnum,
          lag(timeout_cancel_ordnum) over(ORDER BY dt) last2d_timeout_cancel_ordnum
   FROM
(SELECT dt,
        ifnull(sum(promotion_quota),0) quota,
        ifnull(sum(order_num),0) ordnum,
        ifnull(sum(valid_order_num),0) valid_ordnum,
        ifnull(sum(cancel_order_num),0) cancel_ordnum,
        ifnull(sum(handle_cancel_order_num),0) handle_cancel_ordnum,
        ifnull(sum(timeout_cancel_order_num),0) timeout_cancel_ordnum
 FROM dws.dws_sr_store_takeawaypro_statis_d
 WHERE dt BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
 GROUP BY 1) a ) b
WHERE dt=date_sub(current_date(),interval 1 DAY)),


-- 营销支出
-- 非红包和卡券支出
t7 AS
  (SELECT statistics_date,
          tz_newuser_cost,
          qd_newuser_cost,
          ordtz_cost,
          invitz_cost,
          dr_newuser_cost,
          last2d_tz_newuser_cost,
          last2d_qd_newuser_cost,
          last2d_ordtz_cost,
          last2d_invitz_cost,
          last2d_dr_newuser_cost    
   FROM
     (SELECT statistics_date,
             tz_newuser_cost,
             qd_newuser_cost,
             ordtz_cost,
             invitz_cost,
             dr_newuser_cost,
             lag(tz_newuser_cost) over(order by statistics_date) last2d_tz_newuser_cost,
             lag(qd_newuser_cost) over(order by statistics_date) last2d_qd_newuser_cost,
             lag(ordtz_cost) over(order by statistics_date) last2d_ordtz_cost,
             lag(invitz_cost) over(order by statistics_date) last2d_invitz_cost,
             lag(bc_cost) over(order by statistics_date) last2d_bc_cost,
             lag(dr_newuser_cost) over(order by statistics_date) last2d_dr_newuser_cost
      FROM
        (SELECT statistics_date,
                sum(if(cost_typename='团长拉新奖励',cost_amt,0)) tz_newuser_cost,
                sum(if(cost_typename='渠道拉新',cost_amt,0)) qd_newuser_cost,
                sum(if(cost_typename='下单挑战赛',cost_amt,0)) ordtz_cost,
                sum(if(cost_typename='邀请挑战赛',cost_amt,0)) invitz_cost,
                sum(if(cost_typename='用户补偿蚕豆',cost_amt,0)) bc_cost,
                sum(if(cost_typename='达人团长拉新',cost_amt,0)) dr_newuser_cost
         FROM ads.ads_sr_marketing_cost_d
         WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
         GROUP BY 1) a) b
   WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),


-- 卡券和红包发放使用消耗
t8 AS
(SELECT statistics_date,
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
       sum(grant_num) grant_num,
       sum(used_num) used_num,
       sum(cost_amt) cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
  AND (coupon_name NOT regexp '测试'
       OR coupon_desc NOT regexp '测试')
  AND coupon_type=1
GROUP BY 1,
         2
UNION ALL
-- 红包
SELECT statistics_date,
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
           WHEN sub_coupon_type=7 THEN '会员每日红包活动'
           WHEN sub_coupon_type=21 THEN '周年庆猜一猜'
           ELSE coupon_name
       END cost_typename,
       sum(grant_num) grant_num,
       sum(used_num) used_num,
       sum(cost_amt) cost_amt
FROM dws.dws_sr_marketing_cost_coupon_d
WHERE statistics_date BETWEEN date_sub(current_date(),interval 2 DAY) AND date_sub(current_date(),interval 1 DAY)
  AND coupon_type=2
  AND coupon_id<>339 -- 排除无分类且无消耗红包ID
GROUP BY 1,
         2),

-- 卡券和红包发放使用消耗
t9 AS
  (SELECT statistics_date,
          newuser_st_grant_num,
          newuser_st_used_num,
          newuser_st_cost_amt,
          newuser_th_grant_num,
          newuser_th_used_num,
          newuser_th_cost_amt,
          ma_grant_num,
          ma_used_num,
          ma_cost_amt,
          cj_grant_num,
          cj_used_num,
          cj_cost_amt,
          yb_grant_num,
          yb_used_num,
          yb_cost_amt,
          bc_grant_num,
          bc_used_num,
          bc_cost_amt,
          flq_grant_num,
          flq_used_num,
          flq_cost_amt,
          fhq_grant_num,
          fhq_used_num,
          fhq_cost_amt,
          last2d_newuser_st_grant_num,
          last2d_newuser_st_used_num,
          last2d_newuser_st_cost_amt,
          last2d_newuser_th_grant_num,
          last2d_newuser_th_used_num,
          last2d_newuser_th_cost_amt,
          last2d_ma_grant_num,
          last2d_ma_used_num,
          last2d_ma_cost_amt,
          last2d_cj_grant_num,
          last2d_cj_used_num,
          last2d_cj_cost_amt,
          last2d_yb_grant_num,
          last2d_yb_used_num,
          last2d_yb_cost_amt,
          last2d_bc_grant_num,
          last2d_bc_used_num,
          last2d_bc_cost_amt,
          last2d_flq_grant_num,
          last2d_flq_used_num,
          last2d_flq_cost_amt,
          last2d_fhq_grant_num,
          last2d_fhq_used_num,
          last2d_fhq_cost_amt
   FROM
     (SELECT statistics_date,
             newuser_st_grant_num,
             newuser_st_used_num,
             newuser_st_cost_amt,
             newuser_th_grant_num,
             newuser_th_used_num,
             newuser_th_cost_amt,
             ma_grant_num,
             ma_used_num,
             ma_cost_amt,
             cj_grant_num,
             cj_used_num,
             cj_cost_amt,
             yb_grant_num,
             yb_used_num,
             yb_cost_amt,
             bc_grant_num,
             bc_used_num,
             bc_cost_amt,
             flq_grant_num,
             flq_used_num,
             flq_cost_amt,
             fhq_grant_num,
             fhq_used_num,
             fhq_cost_amt,
             lag(newuser_st_grant_num) over(order by statistics_date) last2d_newuser_st_grant_num,
             lag(newuser_st_used_num) over(order by statistics_date) last2d_newuser_st_used_num,
             lag(newuser_st_cost_amt) over(order by statistics_date) last2d_newuser_st_cost_amt,
             lag(newuser_th_grant_num) over(order by statistics_date) last2d_newuser_th_grant_num,
             lag(newuser_th_used_num) over(order by statistics_date) last2d_newuser_th_used_num,
             lag(newuser_th_cost_amt) over(order by statistics_date) last2d_newuser_th_cost_amt,
             lag(ma_grant_num) over(order by statistics_date) last2d_ma_grant_num,
             lag(ma_used_num) over(order by statistics_date) last2d_ma_used_num,
             lag(ma_cost_amt) over(order by statistics_date) last2d_ma_cost_amt,
             lag(cj_grant_num) over(order by statistics_date) last2d_cj_grant_num,
             lag(cj_used_num) over(order by statistics_date) last2d_cj_used_num,
             lag(cj_cost_amt) over(order by statistics_date) last2d_cj_cost_amt,
             lag(yb_grant_num) over(order by statistics_date) last2d_yb_grant_num,
             lag(yb_used_num) over(order by statistics_date) last2d_yb_used_num,
             lag(yb_cost_amt) over(order by statistics_date) last2d_yb_cost_amt,
             lag(bc_grant_num) over(order by statistics_date) last2d_bc_grant_num,
             lag(bc_used_num) over(order by statistics_date) last2d_bc_used_num,
             lag(bc_cost_amt) over(order by statistics_date) last2d_bc_cost_amt,
             lag(flq_grant_num) over(order by statistics_date) last2d_flq_grant_num,
             lag(flq_used_num) over(order by statistics_date) last2d_flq_used_num,
             lag(flq_cost_amt) over(order by statistics_date) last2d_flq_cost_amt,
             lag(fhq_grant_num) over(order by statistics_date) last2d_fhq_grant_num,
             lag(fhq_used_num) over(order by statistics_date) last2d_fhq_used_num,
             lag(fhq_cost_amt) over(order by statistics_date) last2d_fhq_cost_amt
      FROM
        (SELECT statistics_date,
                sum(if(cost_typename='新用户下单奖励红包',grant_num,0)) newuser_st_grant_num,
                sum(if(cost_typename='新用户下单奖励红包',used_num,0)) newuser_st_used_num,
                sum(if(cost_typename='新用户下单奖励红包',cost_amt,0)) newuser_st_cost_amt,
                sum(if(cost_typename='新人狂欢第3单奖励',grant_num,0)) newuser_th_grant_num,
                sum(if(cost_typename='新人狂欢第3单奖励',used_num,0)) newuser_th_used_num,
                sum(if(cost_typename='新人狂欢第3单奖励',cost_amt,0)) newuser_th_cost_amt,
                sum(if(cost_typename='外卖MA红包',grant_num,0)) ma_grant_num,
                sum(if(cost_typename='外卖MA红包',used_num,0)) ma_used_num,
                sum(if(cost_typename='外卖MA红包',cost_amt,0)) ma_cost_amt,
                sum(if(cost_typename='抽奖活动',grant_num,0)) cj_grant_num,
                sum(if(cost_typename='抽奖活动',used_num,0)) cj_used_num,
                sum(if(cost_typename='抽奖活动',cost_amt,0)) cj_cost_amt,
                sum(if(cost_typename='积分兑换',grant_num,0)) yb_grant_num,
                sum(if(cost_typename='积分兑换',used_num,0)) yb_used_num,
                sum(if(cost_typename='积分兑换',cost_amt,0)) yb_cost_amt,
                sum(if(cost_typename='客服补偿红包',grant_num,0)) bc_grant_num,
                sum(if(cost_typename='客服补偿红包',used_num,0)) bc_used_num,
                sum(if(cost_typename='客服补偿红包',cost_amt,0)) bc_cost_amt,
                sum(if(cost_typename='返利券',used_num,0)) flq_grant_num,
                sum(if(cost_typename='返利券',used_num,0)) flq_used_num,
                sum(if(cost_typename='返利券',cost_amt,0)) flq_cost_amt,
                sum(if(cost_typename='复活券',grant_num,0)) fhq_grant_num,
                sum(if(cost_typename='复活券',used_num,0)) fhq_used_num,
                sum(if(cost_typename='复活券',cost_amt,0)) fhq_cost_amt
         FROM t8
         GROUP BY 1) a) b
WHERE statistics_date=date_sub(current_date(),interval 1 DAY)),

-- 年累计自营有效订单量
t10 as (
SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS statistics_date,
    -- 今年累计（截至昨日）
    COALESCE((SELECT COUNT(*) FROM dwd.dwd_sr_order_promotion_order
              WHERE dt >= DATE_TRUNC('year', CURRENT_DATE())
                AND dt <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
                AND order_status IN (2,8)
                AND store_promotion_id<>0), 0) AS current_year_orders,
    -- 去年同期累计（截至昨日）
    COALESCE((SELECT COUNT(*) FROM dwd.dwd_sr_order_promotion_order
              WHERE dt >= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 YEAR)
                AND dt <= DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 YEAR)
                AND order_status IN (2,8)
                AND store_promotion_id<>0
                ), 0) AS last_year_orders,
    -- 去年一整年有效订单量（1月1日～12月31日）
    COALESCE((SELECT COUNT(*) FROM dwd.dwd_sr_order_promotion_order
              WHERE dt >= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 YEAR)
                AND dt <= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 DAY)
                AND order_status IN (2,8)
                AND store_promotion_id<>0), 0) AS last_year_full_orders,
    -- 基于去年全年的目标订单量（增长50%）
    COALESCE((SELECT COUNT(*) FROM dwd.dwd_sr_order_promotion_order
              WHERE dt >= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 YEAR)
                AND dt <= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 DAY)
                AND order_status IN (2,8)
                AND store_promotion_id<>0), 0) * 1.5 AS target_orders,
    -- 完成目标进度百分比（今年累计 / 目标值）
        COALESCE((SELECT COUNT(*) FROM dwd.dwd_sr_order_promotion_order
                  WHERE dt >= DATE_TRUNC('year', CURRENT_DATE())
                    AND dt <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
                    AND order_status IN (2,8)
                    AND store_promotion_id<>0), 0) 
        / NULLIF(
            COALESCE((SELECT COUNT(*) FROM dwd.dwd_sr_order_promotion_order
                      WHERE dt >= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 YEAR)
                        AND dt <= DATE_SUB(DATE_TRUNC('year', CURRENT_DATE()), INTERVAL 1 DAY)
                        AND order_status IN (2,8)
                        AND store_promotion_id<>0), 0) * 1.5, 0
        ) AS completion_percent
        ),

-- DAU进度
t11 as (
SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AS statistics_date,
    -- 去年日峰值 DAU
    MAX(CASE WHEN dt BETWEEN DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 YEAR
                  AND DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 DAY
             THEN dau END) AS last_year_peak_dau,
    -- 目标值（去年峰值 * 1.5）
    MAX(CASE WHEN dt BETWEEN DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 YEAR
                  AND DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 DAY
             THEN dau END) * 1.5 AS target_peak_dau,
    -- 今年截至昨日的日峰值 DAU
    MAX(CASE WHEN dt >= DATE_TRUNC('year', CURRENT_DATE())
              AND dt <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
             THEN dau END) AS this_year_peak_dau,
    -- 完成进度百分比
        MAX(CASE WHEN dt >= DATE_TRUNC('year', CURRENT_DATE())
                  AND dt <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
                 THEN dau END)
        / NULLIF(MAX(CASE WHEN dt BETWEEN DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 YEAR
                          AND DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 DAY
                         THEN dau END) * 1.5, 0) AS completion_percent
FROM (
    SELECT dt, bitmap_union_count(user_ids) AS dau
    FROM dwd.dwd_sr_traffic_viewuser_d
    WHERE dt >= DATE_TRUNC('year', CURRENT_DATE()) - INTERVAL 1 YEAR
      AND dt <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    GROUP BY dt
) t
)


select
t11.statistics_date `统计日期`,
t11.target_peak_dau `DAU峰值目标`,
t11.this_year_peak_dau `今年DAU峰值`,
t11.completion_percent `DAU目标进度`,
t10.current_year_orders `今年累计有效订单量`,
t10.target_orders `有效订单量目标`,
t10.completion_percent `有效订单量进度`,
t1.cur_avg_dau `本月日均DAU`,
t1.lastm_avg_dau `上月日均DAU`,
t1.cur_avg_dau/t1.lastm_avg_dau-1 `月日均DAU环比`,
t2.dau `昨日DAU`,
t2.last2d_dau `前日DAU`,
t2.dau/t2.last2d_dau-1 `DAU环比`,
t3.register_num `昨日注册用户量`,
t3.recall_num `昨日召回用户量`,
t3.view6_num `近30天活跃1-6天用户量`,
t3.view12_num `近30天活跃7-12天用户量`,
t3.view18_num `近30天活跃13-18天用户量`,
t3.view24_num `近30天活跃19-24天用户量`,
t3.view30_num `近30天活跃25-30天用户量`,
t4.newuser_num `注册用户量`,
t4.last2d_newuser_num `前日注册用户量`,
t4.newuser_num/t4.last2d_newuser_num-1 `注册用户量环比`,
t5.tz_newuser_num `团长拉新用户量`,
t5.qd_newuser_num `渠道拉新用户量`,
t5.zr_newuser_num `自然新增用户量`,
t6.quota `活动名额`,
t6.quota/t6.last2d_quota-1 `活动名额环比`,
t6.ordnum `报名订单量`,
t6.ordnum/t6.last2d_ordnum-1 `报名订单量环比`,
t6.valid_ordnum `有效订单量`,
t6.valid_ordnum/t6.last2d_valid_ordnum-1 `有效订单量环比`,
t6.cancel_ordnum `取消订单量`,
t6.cancel_ordnum/t6.last2d_cancel_ordnum-1 `取消订单量环比`,
t7.tz_newuser_cost `团长拉新奖励`,
t7.qd_newuser_cost `渠道拉新支出`,
t7.ordtz_cost `下单挑战赛支出`,
t7.invitz_cost `邀请挑战赛支出`,
t7.dr_newuser_cost `探店达人团长拉新奖励`,
t7.tz_newuser_cost/t7.last2d_tz_newuser_cost-1 `团长拉新奖励环比`,
t7.qd_newuser_cost/t7.last2d_qd_newuser_cost-1 `渠道拉新支出环比`,
t7.ordtz_cost/t7.last2d_ordtz_cost-1 `下单挑战赛支出环比`,
t7.invitz_cost/t7.last2d_invitz_cost-1 `邀请挑战赛支出环比`,
t7.dr_newuser_cost/t7.last2d_dr_newuser_cost-1 `探店达人团长拉新奖励环比`,  
t9.newuser_st_grant_num `新人免单红包发放量`,
t9.newuser_st_used_num `新人免单红包使用量`,
t9.newuser_st_cost_amt `新人免单红包消耗金额`,
t9.newuser_th_grant_num `三单红包发放量`,
t9.newuser_th_used_num `三单红包使用量`,
t9.newuser_th_cost_amt `三单红包消耗金额`,
t9.ma_grant_num `外卖MA红包发放量`,
t9.ma_used_num `外卖MA红包使用量`,
t9.ma_cost_amt `外卖MA红包消耗金额`,
t9.cj_grant_num `抽奖红包发放量`,
t9.cj_used_num `抽奖红包使用量`,
t9.cj_cost_amt `抽奖红包消耗金额`,
t9.yb_grant_num `元宝红包兑换量`,
t9.yb_used_num `元宝红包使用量`,
t9.yb_cost_amt `元宝红包消耗金额`,
t9.bc_grant_num `客服补偿红包发放量`,
t9.bc_used_num `客服补偿红包使用量`,
t9.bc_cost_amt `客服补偿红包消耗金额`,
t9.flq_grant_num `返利券发放量`,
t9.flq_used_num `返利券使用量`,
t9.flq_cost_amt `返利券消耗金额`,
t9.fhq_grant_num `复活券发放量`,
t9.fhq_used_num `复活券使用量`,
t9.fhq_cost_amt `复活券使用金额`,
t9.newuser_st_grant_num/t9.last2d_newuser_st_grant_num-1 `新人免单红包发放量环比`,
t9.newuser_st_used_num/t9.last2d_newuser_st_used_num-1 `新人免单红包使用量环比`,
t9.newuser_st_cost_amt/t9.last2d_newuser_st_cost_amt-1 `新人免单红包消耗金额环比`,
t9.newuser_th_grant_num/t9.last2d_newuser_th_grant_num-1 `三单红包发放量环比`,
t9.newuser_th_used_num/t9.last2d_newuser_th_used_num-1 `三单红包使用量环比`,
t9.newuser_th_cost_amt/t9.last2d_newuser_th_cost_amt-1 `三单红包消耗金额环比`,
t9.ma_grant_num/t9.last2d_ma_grant_num-1 `外卖MA红包发放量环比`,
t9.ma_used_num/t9.last2d_ma_used_num-1 `外卖MA红包使用量环比`,
t9.ma_cost_amt/t9.last2d_ma_cost_amt-1 `外卖MA红包消耗金额环比`,
t9.cj_grant_num/t9.last2d_cj_grant_num-1 `抽奖红包发放量环比`,
t9.cj_used_num/t9.last2d_cj_used_num-1 `抽奖红包使用量环比`,
t9.cj_cost_amt/t9.last2d_cj_cost_amt-1 `抽奖红包消耗金额环比`,
t9.yb_grant_num/t9.last2d_yb_grant_num-1 `元宝红包兑换量环比`,
t9.yb_used_num/t9.last2d_yb_used_num-1 `元宝红包使用量环比`,
t9.yb_cost_amt/t9.last2d_yb_cost_amt-1 `元宝红包消耗金额环比`,
t9.bc_grant_num/t9.last2d_bc_grant_num-1 `客服补偿红包发放量环比`,
t9.bc_used_num/t9.last2d_bc_used_num-1 `客服补偿红包使用量环比`,
t9.bc_cost_amt/t9.last2d_bc_cost_amt-1 `客服补偿红包消耗金额环比`,
t9.flq_grant_num/t9.last2d_flq_grant_num-1 `返利券发放量环比`,
t9.flq_used_num/t9.last2d_flq_used_num-1 `返利券使用量环比`,
t9.flq_cost_amt/t9.last2d_flq_cost_amt-1 `返利券消耗金额`,
t9.fhq_grant_num/t9.last2d_fhq_grant_num-1 `复活券发放量环比`,
t9.fhq_used_num/t9.last2d_fhq_used_num-1 `复活券使用量环比`,
t9.fhq_cost_amt/t9.last2d_fhq_cost_amt-1 `复活券消耗金额环比`
from t11 left join t10 on t11.statistics_date=t10.statistics_date
left join t1 on t11.statistics_date=t1.statistics_date
left join t2 on t11.statistics_date=t2.dt
left join t3 on t11.statistics_date=t3.dt
left join t4 on t11.statistics_date=t4.register_date
left join t5 on t11.statistics_date=t5.register_date
left join t6 on t11.statistics_date=t6.dt
left join t7 on t11.statistics_date=t7.statistics_date
left join t9 on t11.statistics_date=t9.statistics_date














