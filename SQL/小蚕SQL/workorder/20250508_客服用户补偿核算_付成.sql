1、4月进线——先贝。占比预估，人均次数
超高价值、高价值、普通价值、低价值用户——听风

2、4月进线。新的规则进线补偿预估增加金额
拉列表
会话ID、用户ID、用户价值类型、会话类型
超高价值、高价值、普通价值——人群会话（+用户价值）

3、3月异常工单扣减蚕豆用户复购率（扣减30天内），
3月异常工单扣减蚕豆用户：30天前、30天后单量+利润
3月异常工单扣减蚕豆用户扣减总额、
扣减类型拆分；
用户排除补偿过的异常工单

4、4月补偿用户创造价值（利润）/补偿金额（蚕豆+使用红包）30天后
人数

5、4月手动发放大牌券+复活券涉及订单金额（客服发放）




============ 进线统计
-- 4月进线统计
-- 711条数据 用户ID等于0
SELECT session_id `会话ID`,
       a.user_id `用户ID`,
       status `会话状态`,
       tag_content `会话类型`,
       CASE
           WHEN b.user_true_level=0 THEN '低价值用户'
           WHEN b.user_true_level=1 THEN '普通价值用户'
           WHEN b.user_true_level=2 THEN '高价值用户'
           WHEN b.user_true_level=3 THEN '超高价值用户'
       END `用户价值类型`
FROM
-- 会话 user_id中混入了部分user_wechat_id，是否有其他情况暂未知
  (SELECT session_id,
          user_id,
          CASE
              WHEN status=1 THEN '已领取'
              WHEN status=2 THEN '已关闭'
              ELSE 0
          END status,
          tag_content
   FROM dwd.dwd_sr_qimo_session
   WHERE create_time BETWEEN '2025-04-01 00:00:00' AND '2025-04-30 23:59:59'
     AND user_id<>0) a
-- 用户价值
LEFT JOIN dwd.dwd_sr_user_usertag_dm_02 b ON a.user_id=b.user_id;


============ 3月异常工单扣减蚕豆用户复购率
DROP VIEW IF EXISTS workorder_info;


CREATE VIEW IF NOT EXISTS workorder_info (finish_time,user_id,order_id,deduct_amt,add_amt,cate3_name,rk) AS
  (SELECT a.finish_time,
          a.user_id,
          a.order_id,
          a.deduction_user_candou_amt/100 deduct_amt,
          ifnull(b.add_candou_num,0)/100 add_amt,
          cate3_name,
          row_number() over(partition BY user_id ORDER BY finish_time) rk
   FROM 
   -- 订单异常扣减蚕豆用户订单 订单唯一
     (SELECT finish_time,
             user_id,
             order_id,
             deduction_user_candou_amt,
             CASE WHEN cate3_type=1 THEN '多平台返现' WHEN cate3_type=2 THEN '评论未带图/字' WHEN cate3_type=3 THEN '评论不符合标准' WHEN cate3_type=4 THEN '好评卡返现' WHEN cate3_type=5 THEN '下错店铺' WHEN cate3_type=7 THEN '虚假订单' WHEN cate3_type=9 THEN '实付未满/使用美团大红包' WHEN cate3_type=10 THEN '评价折叠' WHEN cate3_type=21 THEN '评论未带图' WHEN cate3_type=22 THEN '评论未带字' WHEN cate3_type=23 THEN '全部退款' WHEN cate3_type=24 THEN '部分退款' WHEN cate3_type=26 THEN '下单时间不符' WHEN cate3_type=27 THEN '预订单' WHEN cate3_type=28 THEN '第三方店铺封控' WHEN cate3_type=30 THEN '用餐反馈图片不符' WHEN cate3_type=31 THEN '用餐反馈文字敷衍' WHEN cate3_type=33 THEN '多瓶饮料' WHEN cate3_type=34 THEN '活动规则不符' WHEN cate3_type=35 THEN '参与官方活动-美团' WHEN cate3_type=36 THEN '参与官方活动-饿了么' WHEN cate3_type=56 THEN '用户反馈重复/ 粘贴复制-图' WHEN cate3_type=57 THEN '用户反馈重复/ 粘贴复制-字' WHEN cate3_type=58 THEN '用户反馈重复/ 粘贴复制-字-图' WHEN cate3_type=60 THEN '用户反馈不符' WHEN cate3_type=65 THEN '虚假订单P图' WHEN cate3_type=66 THEN '用餐反馈图片和文字无关' WHEN cate3_type=67 THEN '用餐反馈店铺不符' WHEN cate3_type=68 THEN '用餐反馈时间不符' ELSE '其他' END cate3_name
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2025-03-01' AND '2025-03-31'
        AND cate2_type=1 -- 订单异常
        AND length(order_id)>=10 -- 排除空值订单
        AND deduction_user_candou_amt>0
        AND status=2 -- 已完结
) a
   LEFT JOIN 
   -- 蚕豆工单 订单不唯一 多次补蚕豆
     (SELECT order_id,
             sum(add_candou_num) add_candou_num
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2025-03-01' AND '2025-03-31'
        AND cate2_type=4 -- 蚕豆工单
        AND length(order_id)>=10 -- 排除空值订单
        AND add_candou_num>0
        AND status=2 -- 已完结
      GROUP BY 1) b ON a.order_id=b.order_id);


SELECT toa.user_id `用户ID`,
       toa.cate3_name `扣减类型`,
       toa.deduct_amt `扣减金额`,
       tob.order_num `扣减前30天有效订单量`,
       tob.profit `扣减前30天有效订单利润`,
       toc.order_num `扣减后30天有效订单量`,
       toc.profit `扣减后30天有效订单利润`
FROM
-- 排除已补偿过用户
  (SELECT user_id,
          cate3_name,
          sum(deduct_amt) deduct_amt
   FROM workorder_info
   WHERE add_amt=0
   GROUP BY 1,
            2) toa
LEFT JOIN
-- 扣减前30天下单利润
  (SELECT a.user_id,
          sum(order_num) order_num,
          sum(profit) profit
   FROM
     (SELECT user_id,
             date_format(finish_time,'%Y-%m-%d') AS finish_date
      FROM workorder_info
      WHERE rk=1
        AND add_amt=0) a
   LEFT JOIN
     (SELECT date_format(order_time,'%Y-%m-%d') order_date,
             user_id,
             count(1) order_num,
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-01-01' AND '2025-03-31'
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   AND date_diff('day',finish_date,order_date) BETWEEN 1 AND 30
   GROUP BY 1) tob ON toa.user_id=tob.user_id
LEFT JOIN
-- 扣减后30天下单利润
  (SELECT a.user_id,
          sum(order_num) order_num,
          sum(profit) profit
   FROM
     (SELECT user_id,
             date_format(finish_time,'%Y-%m-%d') AS finish_date
      FROM workorder_info
      WHERE rk=1
        AND add_amt=0) a
   LEFT JOIN
     (SELECT date_format(order_time,'%Y-%m-%d') order_date,
             user_id,
             count(1) order_num,
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-03-01' AND '2025-05-05'
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   AND date_diff('day',order_date,finish_date) BETWEEN 1 AND 30
   GROUP BY 1) toc ON tob.user_id=toc.user_id;

====================
-- 4月补偿用户创造价值（利润）
-- 12653 数据量

DROP VIEW IF EXISTS workorder_user;


CREATE VIEW IF NOT EXISTS workorder_user (finish_date,user_id,add_candou_num,rp_amt) AS
  (SELECT  finish_date,
           user_id,
           sum(add_candou_num)/100 add_candou_num,
           sum(rp_amt) rp_amt
   FROM
   -- 补蚕豆
     (SELECT date_format(finish_time,'%Y-%m-%d') finish_date,
             user_id,
             sum(add_candou_num) add_candou_num,
             0 rp_amt
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2025-04-01' AND '2025-04-30'
        AND cate2_type=4 -- 蚕豆工单
        AND length(order_id)>=10 -- 排除空值订单
        AND add_candou_num>0
        AND status=2 -- 已完结
      GROUP BY 1,2

      UNION ALL 

   -- 补红包

      SELECT finish_date,
             a.user_id,
             0,
             sum(redpacket_amt) rp_amt
      FROM
      -- 客服发红包
        (SELECT user_id,
                record_id
         FROM dwd.dwd_sr_callcenter_workorder_rp_grant
         WHERE create_time BETWEEN '2025-01-01 00:00:00' AND '2025-05-08 23:59:59' 
           AND redpacket_type=1 -- 霸王餐
           AND status=1 -- 发放成功
         GROUP BY 1,
                  2) a
      INNER JOIN
      -- 红包使用
        (SELECT auto_id,
                order_id
         FROM dwd.dwd_sr_market_redpack_use_record
         WHERE dt BETWEEN '2025-04-01' AND date_sub(current_date(),interval 1 DAY)
           AND date_format(used_time,'%Y-%m-%d') BETWEEN '2025-04-01' AND '2025-04-30'
           AND redpacket_use_status = 2 -- 已使用
        ) b on b.auto_id=a.record_id
      INNER JOIN
        (SELECT order_id,
                redpacket_amt,
                date_format(order_time,'%Y-%m-%d') finish_date
         FROM dwd.dwd_sr_order_promotion_order
         WHERE dt BETWEEN '2025-04-01' AND '2025-05-08'
           AND order_status IN (2,
                                8)) c ON b.order_id=c.order_id
      GROUP BY 1,2) toa
   GROUP BY 1,2);


SELECT toa.user_id,
       add_candou_num `补偿蚕豆`,
       rp_amt `补偿红包金额`,
       order_num `补偿后30天内霸王餐完单量`,
       profit `补偿后30天内霸王餐订单利润`
FROM
-- 用户补偿
  (SELECT user_id,
          sum(add_candou_num) add_candou_num,
          sum(rp_amt) rp_amt
   FROM workorder_user
   GROUP BY 1) toa
LEFT JOIN
-- 补偿用户30天内霸王餐完单
  (SELECT a.user_id,
          sum(order_num) order_num,
          sum(profit) profit
   FROM
     (SELECT user_id,
             min(finish_date) finish_date
      FROM workorder_user
      WHERE add_candou_num>0
        OR rp_amt>0
      GROUP BY 1) a
   LEFT JOIN
     (SELECT user_id,
             date_format(order_time,'%Y-%m-%d') order_date,
             count(1) order_num,
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2025-04-01' AND '2025-05-08'
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   AND date_diff('day',order_date,finish_date) BETWEEN 1 AND 30
   GROUP BY 1) tob ON toa.user_id=tob.user_id;



============ 24年9月异常工单扣减蚕豆用户复购率
DROP VIEW IF EXISTS workorder_info;


CREATE VIEW IF NOT EXISTS workorder_info (finish_time,user_id,order_id,deduct_amt,add_amt,cate3_name,rk) AS
  (SELECT a.finish_time,
          a.user_id,
          a.order_id,
          a.deduction_user_candou_amt/100 deduct_amt,
          ifnull(b.add_candou_num,0)/100 add_amt,
          cate3_name,
          row_number() over(partition BY user_id ORDER BY finish_time) rk
   FROM 
   -- 订单异常扣减蚕豆用户订单 订单唯一
     (SELECT finish_time,
             user_id,
             order_id,
             deduction_user_candou_amt,
             CASE WHEN cate3_type=1 THEN '多平台返现' WHEN cate3_type=2 THEN '评论未带图/字' WHEN cate3_type=3 THEN '评论不符合标准' WHEN cate3_type=4 THEN '好评卡返现' WHEN cate3_type=5 THEN '下错店铺' WHEN cate3_type=7 THEN '虚假订单' WHEN cate3_type=9 THEN '实付未满/使用美团大红包' WHEN cate3_type=10 THEN '评价折叠' WHEN cate3_type=21 THEN '评论未带图' WHEN cate3_type=22 THEN '评论未带字' WHEN cate3_type=23 THEN '全部退款' WHEN cate3_type=24 THEN '部分退款' WHEN cate3_type=26 THEN '下单时间不符' WHEN cate3_type=27 THEN '预订单' WHEN cate3_type=28 THEN '第三方店铺封控' WHEN cate3_type=30 THEN '用餐反馈图片不符' WHEN cate3_type=31 THEN '用餐反馈文字敷衍' WHEN cate3_type=33 THEN '多瓶饮料' WHEN cate3_type=34 THEN '活动规则不符' WHEN cate3_type=35 THEN '参与官方活动-美团' WHEN cate3_type=36 THEN '参与官方活动-饿了么' WHEN cate3_type=56 THEN '用户反馈重复/ 粘贴复制-图' WHEN cate3_type=57 THEN '用户反馈重复/ 粘贴复制-字' WHEN cate3_type=58 THEN '用户反馈重复/ 粘贴复制-字-图' WHEN cate3_type=60 THEN '用户反馈不符' WHEN cate3_type=65 THEN '虚假订单P图' WHEN cate3_type=66 THEN '用餐反馈图片和文字无关' WHEN cate3_type=67 THEN '用餐反馈店铺不符' WHEN cate3_type=68 THEN '用餐反馈时间不符' ELSE '其他' END cate3_name
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2024-09-01' AND '2024-09-30'
        AND cate2_type=1 -- 订单异常
        AND length(order_id)>=10 -- 排除空值订单
        AND deduction_user_candou_amt>0
        AND status=2 -- 已完结
) a
   LEFT JOIN 
   -- 蚕豆工单 订单不唯一 多次补蚕豆
     (SELECT order_id,
             sum(add_candou_num) add_candou_num
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2024-09-01' AND '2024-09-30'
        AND cate2_type=4 -- 蚕豆工单
        AND length(order_id)>=10 -- 排除空值订单
        AND add_candou_num>0
        AND status=2 -- 已完结
      GROUP BY 1) b ON a.order_id=b.order_id);


SELECT toa.user_id `用户ID`,
       toa.cate3_name `扣减类型`,
       toa.deduct_amt `扣减金额`,
       tob.order_num `扣减前90天有效订单量`,
       tob.profit `扣减前90天有效订单利润`,
       toc.order_num `扣减后90天有效订单量`,
       toc.profit `扣减后90天有效订单利润`
FROM
-- 排除已补偿过用户
  (SELECT user_id,
          cate3_name,
          sum(deduct_amt) deduct_amt
   FROM workorder_info
   WHERE add_amt=0
   GROUP BY 1,
            2) toa
LEFT JOIN
-- 扣减前90天下单利润
  (SELECT a.user_id,
          sum(order_num) order_num,
          sum(profit) profit
   FROM
     (SELECT user_id,
             date_format(finish_time,'%Y-%m-%d') AS finish_date
      FROM workorder_info
      WHERE rk=1
        AND add_amt=0) a
   LEFT JOIN
     (SELECT date_format(order_time,'%Y-%m-%d') order_date,
             user_id,
             count(1) order_num,
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub('2024-09-30',interval 120 day) AND '2024-09-30'
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   AND date_diff('day',finish_date,order_date) BETWEEN 1 AND 90
   GROUP BY 1) tob ON toa.user_id=tob.user_id
LEFT JOIN
-- 扣减后90天下单利润
  (SELECT a.user_id,
          sum(order_num) order_num,
          sum(profit) profit
   FROM
     (SELECT user_id,
             date_format(finish_time,'%Y-%m-%d') AS finish_date
      FROM workorder_info
      WHERE rk=1
        AND add_amt=0) a
   LEFT JOIN
     (SELECT date_format(order_time,'%Y-%m-%d') order_date,
             user_id,
             count(1) order_num,
             sum(if(order_status=2,profit,0)) profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2024-10-10' AND date_add('2024-10-10',interval 120 day)
        AND order_status IN (2,
                             8)
      GROUP BY 1,
               2) b ON a.user_id=b.user_id
   AND date_diff('day',order_date,finish_date) BETWEEN 1 AND 90
   GROUP BY 1) toc ON tob.user_id=toc.user_id;



======= 24年9月无扣减用户下单
DROP VIEW IF EXISTS workorder_info;


CREATE VIEW IF NOT EXISTS workorder_info (finish_time,user_id,order_id,deduct_amt,add_amt,cate3_name,rk) AS
  (SELECT a.finish_time,
          a.user_id,
          a.order_id,
          a.deduction_user_candou_amt/100 deduct_amt,
          ifnull(b.add_candou_num,0)/100 add_amt,
          cate3_name,
          row_number() over(partition BY user_id ORDER BY finish_time) rk
   FROM 
   -- 订单异常扣减蚕豆用户订单 订单唯一
     (SELECT finish_time,
             user_id,
             order_id,
             deduction_user_candou_amt,
             CASE WHEN cate3_type=1 THEN '多平台返现' WHEN cate3_type=2 THEN '评论未带图/字' WHEN cate3_type=3 THEN '评论不符合标准' WHEN cate3_type=4 THEN '好评卡返现' WHEN cate3_type=5 THEN '下错店铺' WHEN cate3_type=7 THEN '虚假订单' WHEN cate3_type=9 THEN '实付未满/使用美团大红包' WHEN cate3_type=10 THEN '评价折叠' WHEN cate3_type=21 THEN '评论未带图' WHEN cate3_type=22 THEN '评论未带字' WHEN cate3_type=23 THEN '全部退款' WHEN cate3_type=24 THEN '部分退款' WHEN cate3_type=26 THEN '下单时间不符' WHEN cate3_type=27 THEN '预订单' WHEN cate3_type=28 THEN '第三方店铺封控' WHEN cate3_type=30 THEN '用餐反馈图片不符' WHEN cate3_type=31 THEN '用餐反馈文字敷衍' WHEN cate3_type=33 THEN '多瓶饮料' WHEN cate3_type=34 THEN '活动规则不符' WHEN cate3_type=35 THEN '参与官方活动-美团' WHEN cate3_type=36 THEN '参与官方活动-饿了么' WHEN cate3_type=56 THEN '用户反馈重复/ 粘贴复制-图' WHEN cate3_type=57 THEN '用户反馈重复/ 粘贴复制-字' WHEN cate3_type=58 THEN '用户反馈重复/ 粘贴复制-字-图' WHEN cate3_type=60 THEN '用户反馈不符' WHEN cate3_type=65 THEN '虚假订单P图' WHEN cate3_type=66 THEN '用餐反馈图片和文字无关' WHEN cate3_type=67 THEN '用餐反馈店铺不符' WHEN cate3_type=68 THEN '用餐反馈时间不符' ELSE '其他' END cate3_name
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2024-09-01' AND '2024-09-30'
        AND cate2_type=1 -- 订单异常
        AND length(order_id)>=10 -- 排除空值订单
        AND deduction_user_candou_amt>0
        AND status=2 -- 已完结
) a
   LEFT JOIN 
   -- 蚕豆工单 订单不唯一 多次补蚕豆
     (SELECT order_id,
             sum(add_candou_num) add_candou_num
      FROM dwd.dwd_sr_callcenter_workorder
      WHERE dt BETWEEN '2024-09-01' AND '2024-09-30'
        AND cate2_type=4 -- 蚕豆工单
        AND length(order_id)>=10 -- 排除空值订单
        AND add_candou_num>0
        AND status=2 -- 已完结
      GROUP BY 1) b ON a.order_id=b.order_id);


drop view if EXISTS order_info;
CREATE VIEW IF NOT EXISTS order_info (user_id,order_date) AS
(SELECT 
             user_id,
             min(order_time,'%Y-%m-%d') order_date
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN '2024-09-01' AND '2024-09-30'
        AND order_status IN (2,
                             8)
      GROUP BY 1);



-- 分前后各自跑
SELECT count(DISTINCT c.user_id) `用户量`
    --    ,sum(if(date_diff('day',c.order_date,tob.order_date) BETWEEN 1 AND 90,tob.order_num,0)) `下单前90天有效订单量`
    --    ,sum(if(date_diff('day',c.order_date,tob.order_date) BETWEEN 1 AND 90,tob.profit,0)) `下单前90天有效订单利润`
       ,sum(if(date_diff('day',toc.order_date,c.order_date) BETWEEN 1 AND 90,toc.order_num,0)) `下单后90天有效订单量`
       ,sum(if(date_diff('day',toc.order_date,c.order_date) BETWEEN 1 AND 90,toc.profit,0)) `下单后90天有效订单利润`
FROM
  (SELECT a.user_id,
          a.order_date
   FROM order_info a
   LEFT JOIN
     (SELECT user_id
      FROM workorder_info
      WHERE rk=1
        AND add_amt=0) b ON a.user_id=b.user_id
   WHERE b.user_id IS NULL) c
-- LEFT JOIN 
-- -- 前90天下单利润
--   (SELECT date_format(order_time,'%Y-%m-%d') order_date,
--           user_id,
--           count(1) order_num,
--           sum(if(order_status=2,profit,0)) profit
--    FROM dwd.dwd_sr_order_promotion_order
--    WHERE dt BETWEEN date_sub('2024-09-30',interval 120 DAY) AND '2024-09-30'
--      AND order_status IN (2,
--                           8)
--    GROUP BY 1,
--             2) tob ON c.user_id=tob.user_id
-- AND date_diff('day',c.order_date,tob.order_date) BETWEEN 1 AND 90
LEFT JOIN 
-- 后90天下单利润
  (SELECT date_format(order_time,'%Y-%m-%d') order_date,
          user_id,
          count(1) order_num,
          sum(if(order_status=2,profit,0)) profit
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2024-10-10' AND date_add('2024-10-10',interval 120 DAY)
     AND order_status IN (2,
                          8)
   GROUP BY 1,
            2) toc ON c.user_id=toc.user_id
AND date_diff('day',toc.order_date,c.order_date) BETWEEN 1 AND 90 
;




















