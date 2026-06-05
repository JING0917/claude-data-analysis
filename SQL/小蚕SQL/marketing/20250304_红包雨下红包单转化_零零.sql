-- 发放和使用
with t1 as (
select
    auto_id,
    dt,
    redpacket_id,
    redpacket_name `红包名称`,
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
      when redpacket_type=16 then '工单发放红包'
      when redpacket_type=17 then '探店单单返红包'
      when redpacket_type=18 then 'ma发放红包'
      when redpacket_type=20 then '周年庆每日领红包'
      when redpacket_type=21 then '周年庆猜一猜'
    end as `红包类型`,
    real_rebate_amt,
    auto_ordere_id,
    order_id,
    user_id
from dwd.dwd_sr_market_redpack_use_record
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and redpacket_id in (222,223,224,225)
),


-- 霸王餐订单
bwc_order as (
select
    user_id,order_id,auto_id,order_status,redpacket_amt,profit
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 70 day) and date_sub(current_date(),interval 1 day)
    )


-- 霸王餐
select
    t1.dt `统计日期`,
    t1.redpacket_id `红包ID`,
    t1.`红包名称`,
    t1.`红包类型`,
    count(distinct t1.auto_id) as `发放红包量`,
    sum(if(length(t1.order_id)>=20,1,0)) as `消耗量(报名)`,
    count(distinct if(length(t1.order_id)>=20,t1.user_id,null)) as `使用用户量(报名)`,
    sum(if(length(t1.order_id)>=20 and a.order_status in (2,8),1,0)) as `消耗量(完单)`,
    count(distinct if(length(t1.order_id)>=20 and a.order_status in (2,8),t1.user_id,null)) as `使用用户量(完单)`,
    sum(if(length(t1.order_id)>=20,t1.real_rebate_amt,0)) `使用红包金额(下单)`,
    sum(if(length(t1.order_id)>=20 and a.order_status in(2,8),t1.real_rebate_amt,0)) `使用红包金额(完单)`,
    sum(if(length(t1.order_id)>=20 and a.order_status in (2,8),a.redpacket_amt,0)) as `红包返豆金额`,
    sum(if(length(t1.order_id)>=20 and a.order_status=2,profit,0)) as `订单利润`
from t1 left join bwc_order as a on t1.order_id=a.order_id
group by 1,2,3,4
;