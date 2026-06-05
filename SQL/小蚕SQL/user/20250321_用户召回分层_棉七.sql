============ 新人沉睡用户
-- 周年庆红包领取
drop view if exists rdp_info;
create view IF NOT EXISTS rdp_info (
    user_id
) as (
select
    user_id
from dwd.dwd_sr_market_redpack_use_record
where date_format(dt,'%Y-%m-%d') between '2025-02-20' and date_sub(current_date(),interval 1 day)
    and redpacket_id in (346,347,348,349,350)
group by 1
);

-- 新人沉睡用户
select count(distinct if(b.user_id is null,a.user_id,null)) unum
from (
    select
        user_id
    from dim.dim_silkworm_user
    where date_diff('day',date_format(current_date(),'%Y-%m-%d'),date_format(register_time,'%Y-%m-%d')) between 8 and 29
      and accu_valid_order_num=0
      and date_diff('day',date_format(current_date(),'%Y-%m-%d'),date_format(latest_login_time,'%Y-%m-%d')) between 0 and 29
      ) a
left join rdp_info b on a.user_id=b.user_id
;

-- 预流失用户
select count(if(b.user_id is null,a.user_id,null)) as unum
from (
    select user_id
    from dim.dim_silkworm_user
    where date_format(register_time,'%Y-%m-%d')>=date_sub(current_date(),interval 30 day)
      and accu_valid_order_num>=2
      and (date_diff('day',date_format(current_date(),'%Y-%m-%d'),date_format(latest_login_time,'%Y-%m-%d')) between 7 and 30
            or date_diff('day',date_format(current_date(),'%Y-%m-%d'),date_format(latest_valid_order_time,'%Y-%m-%d')) between 7 and 30
            )
) a left join rdp_info b on a.user_id=b.user_id
;

============= 用户完单和利润
drop view if exists user_info;
create view if not exists user_info (
      user_id
) as (
select user_id
from dim.dim_silkworm_user
where date_format(latest_valid_order_time,'%Y-%m-%d')>=date_sub(current_date(),interval 30 day)
);


-- 下单
drop view if exists order_info;
create view IF NOT EXISTS order_info (
    user_id,order_num,valid_order_num,profit
)
as (
select
    user_id
    ,count(auto_id) as order_num -- 订单量
    ,count(if(order_status in (2,8),auto_id,null)) as valid_order_num -- 有效订单量
    ,sum(if(order_status=2,profit,0)) as profit -- 有效单利润
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 210 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
group by 1
);

-- 周年庆红包领取
drop view if exists rdp_info;
create view IF NOT EXISTS rdp_info (
    user_id
) as (
select
    user_id
from dwd.dwd_sr_market_redpack_use_record
where date_format(dt,'%Y-%m-%d') between '2025-02-20' and date_sub(current_date(),interval 1 day)
    and redpacket_id in (346,347,348,349,350)
group by 1
);


-- 高价值沉默用户
select
      count(distinct if(c.user_id is null,a.user_id,null)) unum
from user_info a inner join order_info b on a.user_id=b.user_id and b.valid_order_num>=27 and b.profit>19
left join rdp_info c on a.user_id=c.user_id
;

-- 中价值沉默用户
select
      count(distinct if(c.user_id is null,a.user_id,null)) unum
from user_info a inner join order_info b on a.user_id=b.user_id and b.valid_order_num between 5 and 26 and b.profit>=6.5
left join rdp_info c on a.user_id=c.user_id
;


====== 用户完单和访问
drop view if exists user_info;
create view if not exists user_info (
      user_id
) as (
select user_id
from dim.dim_silkworm_user
where date_diff('day',date_format(current_date(),'%Y-%m-%d'),date_format(latest_valid_order_time,'%Y-%m-%d'))>=30
      and accu_valid_order_num<=5
);


-- 用户访问
drop view if exists view_info;
create view IF NOT EXISTS view_info (
    user_id
    )
as (
    select
        user_id
    from dws.dws_sr_traffic_user_d
where date_format(statistics_date,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 30 day)
    and user_id regexp '^[0-9]{1,9}$'
group by 1);

-- 周年庆红包领取
drop view if exists rdp_info;
create view IF NOT EXISTS rdp_info (
    user_id
) as (
select
    user_id
from dwd.dwd_sr_market_redpack_use_record
where date_format(dt,'%Y-%m-%d') between '2025-02-20' and date_sub(current_date(),interval 1 day)
    and redpacket_id in (346,347,348,349,350)
group by 1
);


-- 沉睡低频用户
select count(distinct if(b.user_id is not null and c.user_id is null,a.user_id,null)) unum
from user_info a left join view_info b on a.user_id=b.user_id
left join rdp_info c on a.user_id=c.user_id;


========== 探店单
drop view if exists user_info;
create view if not exists user_info (
      user_id
) as (
select user_id
from dim.dim_silkworm_user
where date_diff('day',date_format(current_date(),'%Y-%m-%d'),date_format(latest_valid_order_time,'%Y-%m-%d'))>=30
);


-- 用户访问
drop view if exists view_info;
create view IF NOT EXISTS view_info (
    user_id
    )
as (
    select
        user_id
    from dws.dws_sr_traffic_user_d
where date_format(statistics_date,'%Y-%m-%d') between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and user_id regexp '^[0-9]{1,9}$'
group by 1);


-- 探店完单和利润
drop view if exists t6;
create view IF NOT EXISTS t6 (
    user_id,exp_order_num,exp_valid_order_num,exp_profit --,kj_order_num,kj_valid_order_num,kj_profit
) as (
select
    user_id
    ,count(if(promotion_type in (1,4),order_id,null)) as exp_order_num -- 探店订单量
    ,count(if(promotion_type in (1,4) and status in (5,19,20,35),order_id,null)) as exp_valid_order_num -- 探店有完成订单量
    ,sum(case when promotion_type =1 and status in (5,19) then pay_amt - real_rebate_amt - cost_price
           when promotion_type =1 and status in (11,14,17,18,22,23,28) then pay_amt - net_cost_price 
           when promotion_type =4 and status in (5,19) then cost_price - real_rebate_amt
        else 0 end) as exp_profit -- 探店完单利润
    -- ,count(if(promotion_type=5,order_id,null)) as kj_order_num -- 砍价下单量
    -- ,count(if(promotion_type=5 and status=5,order_id,null)) as kj_valid_order_num -- 砍价完单量
    -- ,sum(if(promotion_type =5 and status=5,pay_amt,0)) as kj_profit -- 砍价完单利润
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
    where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
            and status in (5,19,11,14,17,18,22,23,28)
    ) a
left join
        -- 活动
        (select promotion_id 
              ,cost_price -- 成本价(含笔记)
              ,net_cost_price  -- 成本价(不含笔记)
              ,bargain_original_price -- 砍价原价
              ,bargain_base_price   -- 砍价底价
        from dwd.dwd_sr_silkworm_explore_promotion
        where dt between '2024-06-01' and date_sub(current_date(),interval 1 day)
        ) b on a.store_promotion_id=b.promotion_id
    group by 1
);


-- 周年庆红包领取
drop view if exists rdp_info;
create view IF NOT EXISTS rdp_info (
    user_id
) as (
select
    user_id
from dwd.dwd_sr_market_redpack_use_record
where date_format(dt,'%Y-%m-%d') between '2025-02-20' and date_sub(current_date(),interval 1 day)
    and redpacket_id in (346,347,348,349,350)
group by 1
);


-- 探店偏好用户
select 
      count(if(t6.user_id is not null and c.user_id is null,a.user_id,null)) as unum 
from user_info a left join view_info b on a.user_id=b.user_id
left join t6 on a.user_id=t6.user_id and t6.exp_valid_order_num>1
left join rdp_info c on a.user_id=c.user_id;

































