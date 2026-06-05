
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
t9.flq_cost_amt/t9.last2d_flq_cost_amt-1 `返利券消耗金额环比`,
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