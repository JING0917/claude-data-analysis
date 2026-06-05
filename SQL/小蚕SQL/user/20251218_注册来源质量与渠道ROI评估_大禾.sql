=============================== 探查数据
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

-- 每日注册用户
select 
    date(register_time) dat,
    get_json_string(meituan_auth_user_detail,'$.re_ch') as `注册渠道`,
    -- get_json_string(meituan_auth_user_detail,'$.rpt') as `注册平台`,
    -- get_json_string(meituan_auth_user_detail,'$.cc') as `注册区县ID`,
    -- lower(get_json_string(meituan_auth_user_detail,'$.dm')) as `设备厂商`
    count(1) unum
from dim.dim_silkworm_user
where date(register_time) between '2025-11-01' and '2025-11-07'
group by 1,2;

-- 渠道拉新每日用户和花费
SELECT statistics_date,
       channel_name,
       count(DISTINCT user_id) newuser_num,
       sum(peruser_cost) cost_amt
FROM dwd.dwd_sr_user_newuser_channel_cost_d
GROUP BY 1,
         2;


-- 渠道拉新用户
SELECT statistics_date,
       channel_name,
       user_id,
       sum(peruser_cost) cost_amt
FROM dwd.dwd_sr_user_newuser_channel_cost_d
GROUP BY 1,
         2,
         3;

-- 是否有重复 没有
select user_id,count(1) cnt from
(SELECT statistics_date,
          channel_name,
          user_id,
          sum(peruser_cost) cost_amt
   FROM dwd.dwd_sr_user_newuser_channel_cost_d
   WHERE statistics_date BETWEEN '2025-11-01' AND '2025-11-30'
   GROUP BY 1,
            2,
            3) a
group by 1
having count(1)>1;


================================= 正式取数
-- 注册用户
WITH t1 AS
  (SELECT date(register_time) register_date,
                              get_json_string(meituan_auth_user_detail,'$.re_ch') AS register_channel,
                              user_id
   FROM dim.dim_silkworm_user
   WHERE date(register_time) BETWEEN '2025-11-01' AND '2025-11-30'),

-- 每日渠道用户明细和成本
t2 AS
  (SELECT statistics_date,
          channel_name,
          user_id,
          sum(peruser_cost) cost_amt
   FROM dwd.dwd_sr_user_newuser_channel_cost_d
   WHERE statistics_date BETWEEN '2025-11-01' AND '2025-11-30'
   GROUP BY 1,
            2,
            3),


-- 每日渠道用户明细
t3 AS
  (SELECT t1.register_date,
          CASE
              WHEN t2.user_id IS NOT NULL THEN t2.channel_name
              WHEN t1.register_channel='团长分享' THEN '团长分享'
              WHEN t1.register_channel='团长邀请码' THEN '团长邀请码'
              ELSE '自然新增'
          END register_channel,
              t1.user_id,
              t2.cost_amt AS register_cost
   FROM t1
      LEFT JOIN t2 ON t1.user_id=t2.user_id),




-- 用户营销支出和订单收益
t4 AS
  (SELECT register_date,
          user_id,
          sum(if(diff_days<=3,cost_amt,0)) 3days_cost_amt,
          sum(if(diff_days<=3,valid_order_num,0)) 3days_valid_order_num,
          sum(if(diff_days<=3,profit,0)) 3days_profit,
          sum(if(diff_days<=5,cost_amt,0)) 5days_cost_amt,
          sum(if(diff_days<=5,valid_order_num,0)) 5days_valid_order_num,
          sum(if(diff_days<=5,profit,0)) 5days_profit,
          sum(if(diff_days<=7,cost_amt,0)) 7days_cost_amt,
          sum(if(diff_days<=7,valid_order_num,0)) 7days_valid_order_num,
          sum(if(diff_days<=7,profit,0)) 7days_profit,
          sum(if(diff_days<=14,cost_amt,0)) 14days_cost_amt,
          sum(if(diff_days<=14,valid_order_num,0)) 14days_valid_order_num,
          sum(if(diff_days<=14,profit,0)) 14days_profit,
          sum(if(diff_days<=30,cost_amt,0)) 30days_cost_amt,
          sum(if(diff_days<=30,valid_order_num,0)) 30days_valid_order_num,
          sum(if(diff_days<=30,profit,0)) 30days_profit
   FROM
(SELECT statistics_date,
        register_date,
        a.user_id,
        cost_amt,
        valid_order_num,
        profit,
        date_diff('day',statistics_date,register_date) diff_days
 FROM
   (SELECT statistics_date,
           user_id,
           sum(cost_amt) cost_amt,
                         sum(valid_order_num) valid_order_num,
                                              sum(valid_profit) profit
    FROM dws.dws_sr_marketing_cost_user_d
    WHERE statistics_date BETWEEN '2025-11-01' AND '2025-12-31'
    GROUP BY 1,
             2) a
 LEFT JOIN t1 ON a.user_id=t1.user_id) b
   GROUP BY 1,
            2),

-- 用户访问留存
t5 AS
  (SELECT t3.register_date,
          t3.register_channel,
          count(if(date_diff('day',dt,register_date)=3,b.user_id,NULL)) `次3日访问留存用户量`,
          count(if(date_diff('day',dt,register_date)=5,b.user_id,NULL)) 次5日访问留存用户量,
          count(if(date_diff('day',dt,register_date)=7,b.user_id,NULL)) 次7日访问留存用户量,
          count(if(date_diff('day',dt,register_date)=14,b.user_id,NULL)) 次14日访问留存用户量,
          count(if(date_diff('day',dt,register_date)=30,b.user_id,NULL)) 次30日访问留存用户量
   FROM t3
   LEFT JOIN
(SELECT dt,
        unnest_bitmap AS user_id
 FROM dwd.dwd_sr_traffic_viewuser_d,
      unnest_bitmap(user_ids) AS uid
 WHERE dt BETWEEN '2025-11-01' AND '2025-12-31'
 GROUP BY 1,
          2) b ON t3.user_id=b.user_id
   GROUP BY 1,
            2)


SELECT `注册日期`,
       `注册渠道`,
       `注册用户量`,
       `渠道拉新支出`,
       `近3日内营销支出`,
       `近3日内有效订单`,
       `近3日内订单利润`,
       `近5日内营销支出`,
       `近5日内有效订单`,
       `近5日内订单利润`,
       `近7日内营销支出`,
       `近7日内有效订单`,
       `近7日内订单利润`,
       `近14日内营销支出`,
       `近14日内有效订单`,
       `近14日内订单利润`,
       `近30日内营销支出`,
       `近30日内有效订单`,
       `近30日内订单利润`,
       `次3日访问留存用户量`,
       `次5日访问留存用户量`,
       `次7日访问留存用户量`,
       `次14日访问留存用户量`,
       `次30日访问留存用户量`,
       `次3日访问留存用户量`/`注册用户量` as`次3日访问留存率`,
       `次5日访问留存用户量`/`注册用户量` as`次5 日访问留存率`,
       `次7日访问留存用户量`/`注册用户量` as `次7日访问留存率`,
       `次14日访问留存用户量`/`注册用户量` as `次14日访问留存率`,
       `次30日访问留存用户量`/`注册用户量` as `次30日访问留存率`
FROM
(SELECT t3.register_date `注册日期`,
       t3.register_channel `注册渠道`,
       count(DISTINCT t3.user_id) `注册用户量`,
       ifnull(sum(t3.register_cost),0) `渠道拉新支出`,
       ifnull(sum(3days_cost_amt),0) `近3日内营销支出`,
       ifnull(sum(3days_valid_order_num),0) `近3日内有效订单`,
       ifnull(sum(3days_profit),0) `近3日内订单利润`,
       ifnull(sum(5days_cost_amt),0) `近5日内营销支出`,
       ifnull(sum(5days_valid_order_num),0) `近5日内有效订单`,
       ifnull(sum(5days_profit),0) `近5日内订单利润`,
       ifnull(sum(7days_cost_amt),0) `近7日内营销支出`,
       ifnull(sum(7days_valid_order_num),0) `近7日内有效订单`,
       ifnull(sum(7days_profit),0)`近7日内订单利润`,
       ifnull(sum(14days_cost_amt),0) `近14日内营销支出`,
       ifnull(sum(14days_valid_order_num),0) `近14日内有效订单`,
       ifnull(sum(14days_profit),0) `近14日内订单利润`,
       ifnull(sum(30days_cost_amt),0) `近30日内营销支出`,
       ifnull(sum(30days_valid_order_num),0) `近30日内有效订单`,
       ifnull(sum(30days_profit),0) `近30日内订单利润`
FROM t3
LEFT JOIN t4 ON t4.user_id=t3.user_id
GROUP BY 1,
         2) a
left join t5 on a.`注册日期`=t5.register_date and a.`注册渠道`=t5.register_channel ;


==================== 新老用户营销支出统计

SELECT channel_name `渠道`,
       if(user_type=2,'新用户','老用户') `用户类型`,
       count(DISTINCT user_id) `用户量`,
       sum(if(diff_days=0,cost_amt,0)) `当日营销支出`,
       sum(if(diff_days<=7,cost_amt,0)) `7日内营销支出`,
       sum(if(diff_days<=14,cost_amt,0)) `14日内营销支出`,
       sum(if(diff_days<=30,cost_amt,0)) `30日内营销支出`,
       sum(if(diff_days<=60,cost_amt,0)) `60日内营销支出`,
       sum(if(diff_days<=90,cost_amt,0)) `90日内营销支出`,
       sum(if(diff_days<=120,cost_amt,0)) `120日内营销支出`,
       sum(if(diff_days<=150,cost_amt,0)) `150日内营销支出`,
       sum(if(diff_days<=180,cost_amt,0)) `180日内营销支出`,
       sum(cost_amt) `累计营销支出`
FROM
  (SELECT a.statistics_date,
          register_date,
          a.user_id,
          user_type,
          channel_name,
          cost_amt,
          date_diff('day',statistics_date,register_date) diff_days
   FROM
     (SELECT statistics_date,
             user_id,
             sum(cost_amt) cost_amt,
             sum(valid_order_num) valid_order_num,
             sum(valid_profit) profit
      FROM dws.dws_sr_marketing_cost_user_d
      WHERE statistics_date BETWEEN '2025-08-01' AND '2026-02-26'
        AND cost_typename<>'渠道拉新'
      GROUP BY 1,
               2) a
   LEFT JOIN 
   -- 渠道用户
     (SELECT user_type,
       CASE
           WHEN channel_name='小红书'
                AND sub_channel_type='xcx75' THEN '小红书小程序'
           WHEN channel_name='小红书'
                AND sub_channel_type<>'xcx75' THEN '小红书APP'
           ELSE channel_name
       END channel_name,
       user_id,
       min(statistics_date) AS register_date
FROM dwd.dwd_sr_user_newuser_channel_cost_d
WHERE statistics_date BETWEEN '2025-08-01' AND '2026-02-26'
  AND user_type IN (2,
                    99)
GROUP BY 1,
         2,
         3) b ON a.user_id=b.user_id
   WHERE b.user_id IS NOT NULL) c
GROUP BY 1,
         2;





