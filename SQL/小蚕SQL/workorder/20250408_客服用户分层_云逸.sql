============ 用户诚信分
SELECT CASE
           WHEN tot_score<85 THEN '初级'
           WHEN tot_score=85 THEN '中级'
           WHEN tot_score>85
                AND tot_score<90 THEN '高级'
           WHEN tot_score>=90 THEN '超级'
           ELSE '其他'
       END `级别`,
       count(DISTINCT user_id) `用户量`
FROM dim.dim_silkworm_user_intsr
WHERE status=1
GROUP BY 1;


============ 用户有效团员数
select
    case when valid_team_user_num<=2 then '初级'
    when valid_team_user_num between 3 and 6 then '中级'
    when valid_team_user_num between 7 and 20 then '高级'
    when valid_team_user_num>20 then '超级'
    else '其他' end `级别`,
    count(distinct user_id) `用户量`
from dim.dim_silkworm_user
where is_logoff=0 -- 0:未注销
group by 1;



========== 霸王餐订单
-- 霸王餐已审核订单统计
DROP VIEW IF EXISTS bwc_order;


CREATE VIEW IF NOT EXISTS bwc_order (user_id,ym_num,tot_order_num,avg_order_num) AS
(select
    user_id,count(distinct ym) ym_num,sum(order_num) tot_order_num,avg(order_num) avg_order_num
from
  (SELECT user_id,
        date_format(order_time,'%Y-%m') ym,
          count(auto_id) AS order_num -- 订单量
FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2024-12-01' AND date_sub(current_date(),interval 1 DAY)
     AND str_to_date(order_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 90 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND order_status=2
   GROUP BY 1,2) a
  group by 1);


-- SELECT CASE
--            WHEN order_num<=5
--                 OR order_num IS NULL THEN '新用户'
--            WHEN order_num>5 THEN '普通用户'
--            ELSE '其他'
--        END `用户类型`,
--        count(DISTINCT a.user_id) `用户量`
-- FROM dim.dim_silkworm_user a
-- LEFT JOIN bwc_order b ON a.user_id=b.user_id
-- WHERE is_logoff=0 -- 0:未注销

-- GROUP BY 1;


-- SELECT CASE
--            WHEN order_num>=20 THEN '活跃用户'
--            ELSE '其他'
--        END `用户类型`,
--        count(DISTINCT a.user_id) `用户量`
-- FROM dim.dim_silkworm_user a
-- LEFT JOIN bwc_order b ON a.user_id=b.user_id
-- WHERE is_logoff=0 -- 0:未注销

-- GROUP BY 1;


select * from bwc_order where user_id=923592157; -- 验数

-- 近3个月总完单量>150且持续3个月月均完单>20
select
    count(distinct if(tot_order_num>150 and avg_order_num>20 and ym_num>=3,user_id,null)) `用户量`
from bwc_order




======= 净剩价值
-- 有效订单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info ( user_id ,order_id ,redpacket_amt ,profit,order_status) AS
  (SELECT user_id ,
          order_id ,
          redpacket_amt ,
          profit,
          order_status
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN date_sub(current_date(),interval 210 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND str_to_date(order_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 180 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND order_status IN (2,
                          8));


-- 红包使用
DROP VIEW IF EXISTS used_rp_info;


CREATE VIEW IF NOT EXISTS used_rp_info (auto_id,order_id) AS
  (SELECT auto_id,
          order_id
   FROM dwd.dwd_sr_market_redpack_use_record
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 210 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND redpacket_use_status = 2 -- 已使用
);


-- 工单类型
DROP VIEW IF EXISTS workorder_info;


CREATE VIEW IF NOT EXISTS workorder_info (work_order_id,order_id, cate2_type, cate3_type, add_candou_num) AS
  (SELECT work_order_id,
          order_id,
          cate2_type,
          cate3_type,
          add_candou_num
   FROM dwd.dwd_sr_callcenter_workorder
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 210 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND length(order_id)>=10 -- 排除空值订单

   GROUP BY 1,
            2,
            3,
            4,
            5);


-- 工单红包
DROP VIEW IF EXISTS rp_info;


CREATE VIEW IF NOT EXISTS rp_info (record_id) AS
  (SELECT record_id
   FROM dwd.dwd_sr_callcenter_workorder_rp_grant
   WHERE date_format(create_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 210 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND redpacket_type=1 -- 霸王餐
     AND status=1 -- 发放成功
   GROUP BY 1);


-- 订单新数据集
DROP VIEW IF EXISTS statis_info;


CREATE VIEW IF NOT EXISTS statis_info (user_id,order_id,redpacket_amt,profit,used_rp_ordid,work_order_id,cate2_type,cate3_type,add_candou_num,record_id,order_status) AS
  (SELECT a.user_id ,
          a.order_id ,
          a.redpacket_amt ,
          a.profit,
          b.order_id AS used_rp_ordid, -- 红包使用订单ID
          c.work_order_id,
          c.cate2_type,
          c.cate3_type,
          c.add_candou_num,
          d.record_id,
          a.order_status
   FROM order_info a
   LEFT JOIN used_rp_info b ON a.order_id=b.order_id
   LEFT JOIN workorder_info c ON a.order_id=c.order_id
   LEFT JOIN rp_info d ON b.auto_id=d.record_id
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11);

-- 验证数据
select * from statis_info where user_id=923592157;


-- 是否有重复数据 工单会有多个订单(有)
select order_id,count(*) cnt from statis_info group by 1 having count(*)>1;

select * from statis_info where order_id in ('202502151207298755923');



-- 统计净剩价值
DROP VIEW IF EXISTS net_score;


CREATE VIEW IF NOT EXISTS net_score (user_id,net_score) AS
  (SELECT a.user_id,
          -- profit,
 -- rp_amt,
 -- add_candou,
 -- add_rp_amt,
 -- plat_ordnum,
 -- fake_ordnum,

          profit-rp_amt-add_candou-add_rp_amt-plat_ordnum-fake_ordnum AS net_score
   FROM 
   -- 非工单数指标
     (SELECT user_id,
             sum(if(order_status=2,profit,0)) AS profit, -- 订单利润
             sum(if(record_id IS NULL,redpacket_amt,0)) AS rp_amt, -- 外卖红包
             sum(2*(if(cate2_type=4,add_candou_num/100,0))) AS add_candou, -- 补偿蚕豆
             sum(2*(if(record_id IS NOT NULL,redpacket_amt,0))) AS add_rp_amt -- 补偿红包
FROM
        (SELECT user_id,
                order_id,
                redpacket_amt,
                profit,
                used_rp_ordid,
                cate2_type,
                cate3_type,
                add_candou_num,
                record_id,
                order_status
         FROM statis_info
         GROUP BY 1,
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                  8,
                  9,
                  10) a1
      GROUP BY 1) a
 -- 工单量指标
LEFT JOIN
     (SELECT user_id,
             count(DISTINCT if(cate3_type IN (1,35,36),work_order_id,NULL)) AS plat_ordnum, -- 多平台工单量
             count(DISTINCT if(cate3_type IN (7,65),work_order_id,NULL))*2 AS fake_ordnum -- 虚假订单工单量
FROM statis_info
      GROUP BY 1) b ON a.user_id=b.user_id );



-- 净剩余价值得分
select
    case when net_score<40 then '初级'
    when net_score>=40 and net_score<100 then '中级'
    when net_score>=100 and net_score<180 then '高级'
    when net_score>=180 then '超级'
    else '其他' end `等级`,
    count(distinct user_id) `用户量`
from net_score
group by 1;











