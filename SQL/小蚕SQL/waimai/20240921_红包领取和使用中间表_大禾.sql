-- 统计领取使用和收益
select
    substr(dat,1,7) as `年月`,
    redpacket_type as `活动类型`,
    count(redpacket_id) as `发放红包量`,
    count(if(b.order_status in (2,8) and redpacket_use_status=2,redpacket_id,null)) as `使用红包量`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,b.profit,null)) as `使用红包有效订单利润`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,b.redpacket_amt,null)) as `使用红包金额`
from (
-- 红包使用记录
select 
    cast(dt as string) as dat,
    redpacket_id,
    redpacket_use_status, -- 1：未使用 2：已使用 3：已失效
    user_id,
    order_id,
    case when redpacket_type=1 then '后台红包'
        when redpacket_type=2 then '拼手气红包'
        when redpacket_type=3 then '红包雨抽奖'
        when redpacket_type=4 then '积分兑换'
        when redpacket_type=5 then '用户召回活动'
        when redpacket_type=6 then '会员限时升级礼包'
        when redpacket_type=7 then '会员每日红包活动'
        when redpacket_type=8 then '挑战赛'
        when redpacket_type=9 then '抽奖活动'
        when redpacket_type=10 then '春节签到领红包(已下线)'
        when redpacket_type=11 then '趣淘用户注册领取红包'
        when redpacket_type=12 then '嗨皮用户注册领取红包'
        when redpacket_type=13 then '新用户下单奖励红包'
        when redpacket_type=14 then '社群晒图'
        when redpacket_type=15 then '团长包红包'
    end as redpacket_type
from dwd.dwd_sr_market_redpack_use_record
where cast(dt as string) between '2024-01-01' and '2024-09-20'
    and redpacket_type<>10
    ) a
left join 
-- 订单
    (
    select 
        order_id,
        profit,
        real_rebate_amt,
        redpacket_amt,
        order_status
    from dwd.dwd_sr_order_promotion_order 
    where cast(dt as string) between '2024-01-01' and '2024-09-20'
        and length(order_id)>=10
    ) b
on a.order_id=b.order_id
group by 1,2;





enum SourceType {
    srt_default = 0;
    srt_admin = 1; // 后台红包
    srt_lucky = 2; // 拼手气红包
    srt_rain_lottery = 3; // 红包雨抽奖
    srt_exchange = 4; // 积分兑换
    srt_recall_user = 5; // 用户召回活动
    srt_vip_limited_gift = 6; // 会员限时升级礼包
    srt_vip_daily_lottery = 7; // 会员每日红包活动
    srt_challenge = 8; // 挑战赛
    srt_lottery = 9; // 抽奖活动
    srt_sf_sign = 10; // 春节签到领红包(已下线)
    srt_qu_tao=11; //趣淘用户注册领取红包
    srt_hi_pi=12; //嗨皮用户注册领取红包
}



红包类型(1:小蚕红包,2:拼手气红包,3:红包雨抽奖,4:积分兑换,5:用户召回活动,6:会员限时升级礼包,7:会员每日红包活动,8:挑战赛,9:抽奖活动,10:春节签到领红包(已下线)) 
20240910新增
11:淘趣用户注册领取红包 12:嗨皮用户注册领取红包 13:新用户下单奖励红包 14:社群晒图 15:团长包红包



大数据数据开发排期：预计9月26日开始
第一步：数据探查（1-2个工作日）
第二步：数据表和字段确认（1个工作日）
第三步：数据开发（暂定，需要数据探查后才能确认）
第四步：数据验收（1-2工作日）




中间表
CREATE TABLE dwds.dws_sr_market_redpacket_used_by_mon(
    substr(dat,1,7) as `年月`,
    redpacket_type as `活动类型`,
    count(redpacket_id) as `发放红包量`,
    count(if(b.order_status in (2,8) and redpacket_use_status=2,redpacket_id,null)) as `使用红包量`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,b.profit,null)) as `使用红包有效订单利润`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,b.redpacket_amt,null)) as `使用红包金额`
  ym varchar(10) NOT NULL comment '年月',
  redpacket_type_name varchar(50) NOT NULL comment '活动类型',
  grant_redpacket_num int DEFAULT 0 comment '发放红包量',
  used_redpacket_num int DEFAULT 0 comment '使用红包量',
  used_redpacket_valid_order_pfofit decimal(12,2) DEFAULT 0 comment '使用红包有效订单利润',
  used_redpacket_amt decimal(12,2) DEFAULT 0 comment '使用红包金额'
  )
comment '分活动类型红包领取使用月数据'








-- 统计领取使用和收益
SELECT
str_to_date(concat(年月,'-','01'),'%Y-%m-%d') as `年月日`,
活动类型,
活动类型对应数值,
发放红包量,
使用红包量,
使用红包有效订单利润,
使用红包金额
FROM
(
select
    substr(dat,1,7) as `年月`,
    redpacket_type as `活动类型`,
    number as `活动类型对应数值`,
    count(redpacket_id) as `发放红包量`,
    count(if(b.order_status in (2,8) and redpacket_use_status=2,redpacket_id,null)) as `使用红包量`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,(b.profit * 100),null)) as `使用红包有效订单利润`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,(b.redpacket_amt * 100),null)) as `使用红包金额`
from (
-- 红包使用记录
select 
    dt as dat,
    redpacket_id,
    redpacket_use_status, -- 1：未使用 2：已使用 3：已失效
    user_id,
    order_id,
    case when redpacket_type=1 then '后台红包'
        when redpacket_type=2 then '拼手气红包'
        when redpacket_type=3 then '红包雨抽奖'
        when redpacket_type=4 then '积分兑换'
        when redpacket_type=5 then '用户召回活动'
        when redpacket_type=6 then '会员限时升级礼包'
        when redpacket_type=7 then '会员每日红包活动'
        when redpacket_type=8 then '挑战赛'
        when redpacket_type=9 then '抽奖活动'
        when redpacket_type=10 then '春节签到领红包(已下线)'
        when redpacket_type=11 then '趣淘用户注册领取红包'
        when redpacket_type=12 then '嗨皮用户注册领取红包'
        when redpacket_type=13 then '新用户下单奖励红包'
        when redpacket_type=14 then '社群晒图'
        when redpacket_type=15 then '团长包红包'
    end as redpacket_type,
    case when redpacket_type=1 then 1
        when redpacket_type=2 then 2
        when redpacket_type=3 then 3
        when redpacket_type=4 then 4
        when redpacket_type=5 then 5
        when redpacket_type=6 then 6
        when redpacket_type=7 then 7
        when redpacket_type=8 then 8
        when redpacket_type=9 then 9
        when redpacket_type=10 then 10
        when redpacket_type=11 then 11
        when redpacket_type=12 then 12
        when redpacket_type=13 then 13
        when redpacket_type=14 then 14
        when redpacket_type=15 then 15
    end as number
from dwd.dwd_sr_market_redpack_use_record
where dt >= '2024-01-01' and dt <='${T-1}'
  and redpacket_type<>10
    ) a
left join 
-- 订单
    (
    select 
        order_id,
        profit,
        real_rebate_amt,
        redpacket_amt,
        order_status
    from dwd.dwd_sr_order_promotion_order 
    where dt >= '2024-01-01' and dt <='${T-1}'
        and length(order_id)>=10
    ) b
on a.order_id=b.order_id
group by 1,2,3
) t



select
    substr(order_audit_finish_time,1,7) as `年月`,
    redpacket_type as `活动类型`,
    count(redpacket_id) as `发放红包量`,
    count(if(b.order_status in (2,8) and redpacket_use_status=2,redpacket_id,null)) as `使用红包量`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,(b.profit * 100),null)) as `使用红包有效订单利润`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,(b.redpacket_amt * 100),null)) as `使用红包金额`
from (
-- 红包使用记录
select 
    dt as dat,
    redpacket_id,
    redpacket_use_status, -- 1：未使用 2：已使用 3：已失效
    user_id,
    order_id,
    case when redpacket_type=1 then '后台红包'
        when redpacket_type=2 then '拼手气红包'
        when redpacket_type=3 then '红包雨抽奖'
        when redpacket_type=4 then '积分兑换'
        when redpacket_type=5 then '用户召回活动'
        when redpacket_type=6 then '会员限时升级礼包'
        when redpacket_type=7 then '会员每日红包活动'
        when redpacket_type=8 then '挑战赛'
        when redpacket_type=9 then '抽奖活动'
        when redpacket_type=10 then '春节签到领红包(已下线)'
        when redpacket_type=11 then '趣淘用户注册领取红包'
        when redpacket_type=12 then '嗨皮用户注册领取红包'
        when redpacket_type=13 then '新用户下单奖励红包'
        when redpacket_type=14 then '社群晒图'
        when redpacket_type=15 then '团长包红包'
    end as redpacket_type
from dwd.dwd_sr_market_redpack_use_record
where cast(dt as string) between '2024-01-01' and '2024-11-06'
  and redpacket_type<>10
    ) a
left join 
-- 订单
    (
    select 
        order_id,
        profit,
        real_rebate_amt,
        redpacket_amt,
        order_status,
        order_audit_finish_time
    from dwd.dwd_sr_order_promotion_order 
    where cast(dt as string) between '2024-01-01' and '2024-11-06'
        and length(order_id)>=10
    ) b
on a.order_id=b.order_id
group by 1,2,3
;

















