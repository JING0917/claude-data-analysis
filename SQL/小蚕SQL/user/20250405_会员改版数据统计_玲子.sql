-- 日均UV

SELECT `平台名称`,
       avg(dau) `月日均UV`
FROM (
-- dau
SELECT date_format(dt,'%Y-%m-%d') AS dat,
       CASE
           WHEN platform_name IN ('Android',
                                  'iOS') THEN 'App'
           ELSE platform_name
       END `平台名称`,
       bitmap_union_count(user_ids) AS dau
FROM dwd.dwd_sr_traffic_viewuser_d
WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
GROUP BY 1,
         2) a
GROUP BY 1;


-- 日均UV
SELECT `平台名称`,
       avg(uv) avg_uv
FROM (
-- 会员用户uv
SELECT a.dat,
       `平台名称`,
       count(DISTINCT if(user_level IS NOT NULL,a.user_id,NULL)) uv
FROM
-- 每日访问用户
  (SELECT date_format(dt,'%Y-%m-%d') AS dat,
          CASE WHEN platform_name IN ('Android',
                                     'iOS') THEN 'App' ELSE platform_name END `平台名称`,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
   GROUP BY 1,
            2,
            3) a

LEFT JOIN dim.dim_silkworm_member b ON a.user_id=b.user_id
GROUP BY 1,
         2) b
GROUP BY 1;


-- 会员页PV
SELECT platform_name,
       avg(pv) avg_pv
FROM
  (SELECT date_format(dt,'%Y-%m-%d') AS dat,
          platform_name,
          sum(memberpage_pv) pv
   FROM ods.ods_sr_event_log
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
     AND user_id regexp '^[0-9]{1,10}$'
   GROUP BY 1,
            2) a
GROUP BY 1;


============= 
-- 会员红包天天领
-- 日均
SELECT date_format(dat,'%H-%i') AS hr,
       user_level,
       avg(unum) avg_unum
FROM 
-- 分时段分会员等级领取用户量
  (SELECT dat,
          b.user_level,
          count(DISTINCT a.user_id) unum
   FROM 
   -- 分时段领取
     (SELECT user_id,
             date_format(create_time,'%Y-%m-%d %H-%i') AS dat
      FROM dwd.dwd_sr_market_rpd_lottery_winning_record
      WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND activity_type=3 -- 会员红包

        AND is_get=2 -- 已领取

      GROUP BY 1,
               2) a
   LEFT JOIN dim.dim_silkworm_member b ON a.user_id=b.user_id
   GROUP BY 1,
            2) b
GROUP BY 1,
         2;


-- 日均参与用户量
SELECT avg(unum) avg_num
FROM
  (SELECT date_format(create_time,'%Y-%m-%d') AS dat,
          count(DISTINCT user_id) unum
   FROM dwd.dwd_sr_market_rpd_lottery_winning_record
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND activity_type=3 -- 会员红包
     AND is_get=2 -- 已领取
   GROUP BY 1) a




========== 霸王餐订单
-- 会员量
SELECT count(if((LENGTH(bind_interior_staff_wework_account)<2)
                AND a.user_level=1,a.user_id,NULL)) `V0用户量`,
       count(if(LENGTH(bind_interior_staff_wework_account)>2
                AND a.user_level=1,a.user_id,NULL)) `V1用户量`,
       count(if(a.user_level=2,a.user_id,NULL)) `V2用户量`,
       count(if(a.user_level=3,a.user_id,NULL)) `V3用户量`,
       count(if(a.user_level=4,a.user_id,NULL)) `V4用户量`,
       count(if(a.user_level=5,a.user_id,NULL)) `V5用户量`
FROM dim.dim_silkworm_member a
LEFT JOIN dim.dim_silkworm_user b ON a.user_id=b.user_id;

-- 霸王餐已审核订单统计
DROP VIEW IF EXISTS bwc_order;


CREATE VIEW IF NOT EXISTS bwc_order (user_level,baoming_unum,order_num,finord_unum,finord_num,profit) AS
  (SELECT user_level,
          count(DISTINCT a.user_id) baoming_unum, -- 报名用户量
          sum(order_num) order_num, -- 报名订单量
          count(DISTINCT if(finord_num>0,a.user_id,NULL)) finord_unum, -- 完单用户量
          sum(finord_num) finord_num, -- 完单量
          sum(profit) profit -- 完单利润
FROM
     (SELECT user_id,
             count(auto_id) AS order_num, -- 报名订单量
             count(if(order_status IN (2,8),auto_id,NULL)) finord_num, -- 完单量
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2023-11-01' AND date_sub(current_date(),interval 1 DAY)
        AND str_to_date(order_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 365 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1) a
   LEFT JOIN 
   -- 会员
  (SELECT b1.user_id,
          CASE
              WHEN LENGTH(b2.bind_interior_staff_wework_account)<2
                   AND b1.user_level=1 THEN 0
              WHEN LENGTH(b2.bind_interior_staff_wework_account)>2
                   AND b1.user_level=1 THEN 1
              ELSE b1.user_level
          END user_level
   FROM dim.dim_silkworm_member b1 LEFT join dim.dim_silkworm_user b2 ON b1.user_id=b2.user_id )b ON a.user_id=b.user_id
   GROUP BY 1);


SELECT *
FROM bwc_order;


======= 霸王餐订单分布
DROP VIEW IF EXISTS bwc_order;


CREATE VIEW IF NOT EXISTS bwc_order (user_level,user_id,order_num,finord_num,profit,real_rebate_amt,user_pay_amt) AS
  (SELECT user_level,
          a.user_id,
          order_num, -- 报名订单量
          finord_num, -- 完单量
          profit, -- 完单利润
          real_rebate_amt,
          user_pay_amt
FROM
     (SELECT user_id,
             count(auto_id) AS order_num, -- 报名订单量
             count(if(order_status IN (2,8),auto_id,NULL)) finord_num, -- 完单量
             sum(if(order_status=2,profit,0)) profit,
             sum(if(order_status IN (2,8),real_rebate_amt,0)) real_rebate_amt,
             sum(if(order_status IN (2,8),user_pay_amt,0))+sum(if(order_status IN (2,8),redpacket_amt,0)) user_pay_amt
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2023-11-01' AND date_sub(current_date(),interval 1 DAY)
        AND str_to_date(order_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 365 DAY) AND date_sub(current_date(),interval 1 DAY)
      GROUP BY 1) a
   LEFT JOIN 
   -- 会员
  (SELECT b1.user_id,
          CASE
              WHEN LENGTH(b2.bind_interior_staff_wework_account)<2
                   AND b1.user_level=1 THEN 0
              WHEN LENGTH(b2.bind_interior_staff_wework_account)>2
                   AND b1.user_level=1 THEN 1
              ELSE b1.user_level
          END user_level
   FROM dim.dim_silkworm_member b1 LEFT join dim.dim_silkworm_user b2 ON b1.user_id=b2.user_id ) b ON a.user_id=b.user_id
 );

select
    user_level `会员等级`,
    count(distinct user_id) `用户量`,
    -- min(finord_num) `最小值`,
    -- percentile_cont(finord_num,0.1) `10分位`,
    -- percentile_cont(finord_num,0.2) `20分位`,
    -- percentile_cont(finord_num,0.3) `30分位`,
    -- percentile_cont(finord_num,0.4) `40分位`,
    -- percentile_cont(finord_num,0.5) `50分位`,
    -- percentile_cont(finord_num,0.6) `60分位`,
    -- percentile_cont(finord_num,0.7) `70分位`,
    -- percentile_cont(finord_num,0.8) `80分位`,
    -- percentile_cont(finord_num,0.9) `90分位`,
    -- max(finord_num) `最大值`,
    -- min(profit) `最小值`,
    -- percentile_cont(profit,0.1) `10分位`,
    -- percentile_cont(profit,0.2) `20分位`,
    -- percentile_cont(profit,0.3) `30分位`,
    -- percentile_cont(profit,0.4) `40分位`,
    -- percentile_cont(profit,0.5) `50分位`,
    -- percentile_cont(profit,0.6) `60分位`,
    -- percentile_cont(profit,0.7) `70分位`,
    -- percentile_cont(profit,0.8) `80分位`,
    -- percentile_cont(profit,0.9) `90分位`,
    -- max(profit) `最大值`
    min(real_rebate_amt) `最小值`,
    percentile_cont(real_rebate_amt,0.1) `10分位`,
    percentile_cont(real_rebate_amt,0.2) `20分位`,
    percentile_cont(real_rebate_amt,0.3) `30分位`,
    percentile_cont(real_rebate_amt,0.4) `40分位`,
    percentile_cont(real_rebate_amt,0.5) `50分位`,
    percentile_cont(real_rebate_amt,0.6) `60分位`,
    percentile_cont(real_rebate_amt,0.7) `70分位`,
    percentile_cont(real_rebate_amt,0.8) `80分位`,
    percentile_cont(real_rebate_amt,0.9) `90分位`,
    max(real_rebate_amt) `最大值`,
    min(user_pay_amt) `最小值`,
    percentile_cont(user_pay_amt,0.1) `10分位`,
    percentile_cont(user_pay_amt,0.2) `20分位`,
    percentile_cont(user_pay_amt,0.3) `30分位`,
    percentile_cont(user_pay_amt,0.4) `40分位`,
    percentile_cont(user_pay_amt,0.5) `50分位`,
    percentile_cont(user_pay_amt,0.6) `60分位`,
    percentile_cont(user_pay_amt,0.7) `70分位`,
    percentile_cont(user_pay_amt,0.8) `80分位`,
    percentile_cont(user_pay_amt,0.9) `90分位`,
    max(user_pay_amt) `最大值`
from bwc_order
group by 1;





=========== 到店订单
drop view if exists exp_order;

create view IF NOT EXISTS exp_order (user_id,exp_order_num,exp_valid_order_num,exp_profit,kj_order_num,kj_valid_order_num,kj_profit) as (
select
    user_id
    ,count(if(promotion_type in (1,4),order_id,null)) as exp_order_num -- 探店订单量
    ,count(if(promotion_type in (1,4) and status in (5,19,20,35),order_id,null)) as exp_valid_order_num -- 探店有完成订单量
    ,sum(case when promotion_type =1 and status in (5,19) then pay_amt - real_rebate_amt - cost_price
           when promotion_type =1 and status in (11,14,17,18,22,23,28) then pay_amt - net_cost_price 
           when promotion_type =4 and status in (5,19) then cost_price - real_rebate_amt
        else 0 end) as exp_profit -- 探店完单利润
    ,count(if(promotion_type in (5,6),order_id,null)) as kj_order_num -- 砍价下单量
    ,count(if(promotion_type in (5,6) and status=5,order_id,null)) as kj_valid_order_num -- 砍价完单量
    ,sum(if(promotion_type in (5,6) and status=5,pay_amt,0)) as kj_profit -- 砍价完单利润
from
-- 订单
(select
    order_id
    ,promotion_type
    ,user_id
    ,store_promotion_id
    ,status
    ,pay_amt
    ,real_rebate_amt
from dwd.dwd_sr_silkworm_explore_order
where date_format(dt,'%Y-%m-%d') between '2024-06-01' and date_sub(current_date(),interval 1 day)
) a
left join
-- 活动
(select promotion_id 
      ,cost_price -- 成本价(含笔记)
      ,net_cost_price  -- 成本价(不含笔记)
      ,bargain_original_price -- 砍价原价
      ,bargain_base_price   -- 砍价底价
from dwd.dwd_sr_silkworm_explore_promotion
where date_format(dt,'%Y-%m-%d') between '2024-06-01' and date_sub(current_date(),interval 1 day)
) b on a.store_promotion_id=b.promotion_id
group by 1
);


SELECT user_level,
       count(DISTINCT if(exp_order_num>0,a.user_id,NULL)) `探店报名用户量`,
       count(DISTINCT if(exp_valid_order_num>0,a.user_id,NULL)) `探店完单用户量`,
       sum(exp_order_num) `探店报名订单量`,
       sum(exp_valid_order_num) `探店完单量`,
       sum(exp_profit) `探店利润`,
       count(DISTINCT if(kj_order_num>0,a.user_id,NULL)) `砍价报名用户量`,
       count(DISTINCT if(kj_valid_order_num>0,a.user_id,NULL)) `砍价完单用户量`,
       sum(kj_order_num) `砍价报名订单量`,
       sum(kj_valid_order_num) `砍价完单量`,
       sum(kj_profit) `砍价利润`
FROM exp_order a 
left join
-- 会员
  (SELECT b1.user_id,
          CASE
              WHEN LENGTH(b2.bind_interior_staff_wework_account)<2
                   AND b1.user_level=1 THEN 0
              WHEN LENGTH(b2.bind_interior_staff_wework_account)>2
                   AND b1.user_level=1 THEN 1
              ELSE b1.user_level
          END user_level
   FROM dim.dim_silkworm_member b1
   LEFT JOIN dim.dim_silkworm_user b2 ON b1.user_id=b2.user_id) b ON a.user_id=b.user_id
GROUP BY 1;


====== 注册时间间隔分布

SELECT user_level `会员等级`,
       count(DISTINCT user_id) `用户量`,
       min(login_diff_days) `最小值`,
       percentile_cont(login_diff_days,0.1) `10分位`,
       percentile_cont(login_diff_days,0.2) `20分位`,
       percentile_cont(login_diff_days,0.3) `30分位`,
       percentile_cont(login_diff_days,0.4) `40分位`,
       percentile_cont(login_diff_days,0.5) `50分位`,
       percentile_cont(login_diff_days,0.6) `60分位`,
       percentile_cont(login_diff_days,0.7) `70分位`,
       percentile_cont(login_diff_days,0.8) `80分位`,
       percentile_cont(login_diff_days,0.9) `90分位`,
       max(login_diff_days) `最大值`,
       min(order_diff_days) `最小值`,
       percentile_cont(order_diff_days,0.1) `10分位`,
       percentile_cont(order_diff_days,0.2) `20分位`,
       percentile_cont(order_diff_days,0.3) `30分位`,
       percentile_cont(order_diff_days,0.4) `40分位`,
       percentile_cont(order_diff_days,0.5) `50分位`,
       percentile_cont(order_diff_days,0.6) `60分位`,
       percentile_cont(order_diff_days,0.7) `70分位`,
       percentile_cont(order_diff_days,0.8) `80分位`,
       percentile_cont(order_diff_days,0.9) `90分位`,
       max(order_diff_days) `最大值`
FROM
  (SELECT b1.user_id,
          CASE
              WHEN LENGTH(b2.bind_interior_staff_wework_account)<2
                   AND b1.user_level=1 THEN 0
              WHEN LENGTH(b2.bind_interior_staff_wework_account)>2
                   AND b1.user_level=1 THEN 1
              ELSE b1.user_level
          END user_level,
          if(date_format(b2.latest_login_time,'%Y-%m-%d')='1970-01-01',99999,date_diff('day',date_format(b2.latest_login_time,'%Y-%m-%d'),date_format(b2.register_time,'%Y-%m-%d'))) AS login_diff_days, -- 访问
          if(date_format(b2.first_valid_order_time,'%Y-%m-%d')='1970-01-01',99999,date_diff('day',date_format(b2.first_valid_order_time,'%Y-%m-%d'),date_format(b2.register_time,'%Y-%m-%d'))) as order_diff_days -- 完单
   FROM dim.dim_silkworm_member b1
   LEFT JOIN dim.dim_silkworm_user b2 ON b1.user_id=b2.user_id
--    AND date_format(b2.latest_login_time,'%Y-%m-%d')<>'1970-01-01' -- 过滤845条没有最近一次登录时间用户
   AND date_format(b2.register_time,'%Y-%m-%d')<>'1970-01-01' -- 过滤186条没有最近一次登录时间用户
   AND b2.is_logoff=0 -- 未注销
) toa
GROUP BY 1;



========= 新用户来源
-- 判断用户是否是挑战赛拉新来的
-- 不存在有邀请用户ID且上级邀请挑战赛信息没值的情况，所以，invitor<>0时，对应用户是挑战赛拉来的新用户
select * from ods.ods_silkworm_challenge_silk_user_info where invitor<>0 and (inviter_takepart_id=0 or inviter_takepart_id is null) limit 10;


-- 日均
SELECT ceil(avg(newuser)) `日均新用户量`,
       ceil(avg(challenge_newuser)) `日均挑战赛拉新用户量`,
       ceil(avg(tuanzhang_newuser)) `日均团长拉新用户量`,
       ceil(avg(postive_newuser)) `日均自然增长新用户量`
FROM 
-- 每日拉新用户量
  (SELECT date_format(a.register_time,'%Y-%m-%d') register_date,
          count(a.user_id) newuser,
          count(if(b.invitor IS NOT NULL,a.user_id,NULL)) challenge_newuser,
          count(if(a.inviter_user_id<>0
                   AND b.invitor IS NULL,a.user_id,NULL)) tuanzhang_newuser,
          count(if(a.inviter_user_id=0
                   AND b.invitor IS NULL,a.user_id,NULL)) postive_newuser
   FROM dim.dim_silkworm_user a
   LEFT JOIN
    -- 挑战赛拉新
     (SELECT 
             -- from_unixtime(register_time,'%Y-%m-%d') as register_date,
             invitor,
             user_id
      FROM ods.ods_silkworm_challenge_silk_user_info
      WHERE date_format(create_time,'%Y-%m-%d') BETWEEN '2024-04-08' AND '2024-12-31'
        AND invitor<>0
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   WHERE date_format(a.register_time,'%Y-%m-%d') BETWEEN '2024-04-08' AND '2024-12-31'
   GROUP BY 1) c
;


======= 会员页模块流量
SELECT event_name,
       avg(pv) avg_pv,
       ceil(avg(uv)) avg_uv
FROM
  (SELECT date_format(dt,'%Y-%m-%d'),
          event_name,
          count(1) pv,
          count(DISTINCT user_id) uv
   FROM ods.ods_sr_event_log
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND event_name IN ('Member_Task_Go_to_Order_Click', -- 去点餐按钮点击
                        'Member_Task_Get_Team_Member_Click', -- 去获取团员按钮点击
                        'Member_Upgrade_Wish_Click' -- 许愿按钮点击
                        )
     AND user_id regexp '^[0-9]{1,10}$'
GROUP BY 1,2) a
group by 1
  ;



========= 许愿池

SELECT count(DISTINCT if(is_get=1,user_id,NULL)) `领取成功用户量`,
       count(DISTINCT if(length(pack_productid_list)>10,user_id,NULL)) `许愿成功用户量`
FROM dwd.dwd_sr_market_user_pack
WHERE date(dt) BETWEEN DATE_SUB(curdate(),INTERVAL 30 DAY) AND DATE_SUB(curdate(),INTERVAL 1 DAY)
  AND pack_type=11 -- 许愿池
;








