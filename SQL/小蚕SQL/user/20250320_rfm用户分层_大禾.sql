-- 拉黑用户
drop view if not exists blackuser_info;
create view if not exists blackuser_info (
    user_id
)
as (
select
    user_id
from dim.dim_silkworm_user
where date_format(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and left(latest_block_time,10)<>'1970-01-01'
    and (left(block_release_time,10)='1970-01-01' or left(block_release_time,10) < left(latest_block_time,10))
    and status = 1 -- 封号状态
    -- and is_logoff=0 -- 未注销
);



-- 霸王餐最近完单距今天数
drop view if exists t1;
create view IF NOT EXISTS t1 (
    user_id,wm_order_interval_day
)
 as (
select
    user_id
    ,date_diff('day',current_date(),str_to_jodatime(order_time,'yyyy-MM-dd HH:mm:ss')) as wm_order_interval_day
from (
    select
        user_id,max(order_time) as order_time
    from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 210 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1
    ) a
);

-- 霸王餐完单
-- 3,585,631 人
-- 有效下单 2,900,874 人
drop view if exists t2;
create view IF NOT EXISTS t2 (
    user_id,
    wm_order_num,
    wm_valid_order_num,
    wm_profit
)
as (
select
    user_id
    ,count(auto_id) as wm_order_num -- 订单量
    ,count(if(order_status in (2,8),auto_id,null)) as wm_valid_order_num -- 有效订单量
    ,sum(if(order_status in (2,8),profit,0)) as wm_profit -- 有效单利润
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 210 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
group by 1
);