drop view if exists t6;
create view IF NOT EXISTS t6 (
    user_id,exp_order_num,exp_valid_order_num,exp_profit,kj_order_num,kj_valid_order_num,kj_profit
) as (
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
    where dt between '2025-04-01' and date_sub(current_date(),interval 0 day)
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
        where dt between '2024-06-01' and date_sub(current_date(),interval 0 day)
        ) b on a.store_promotion_id=b.promotion_id
    group by 1
);


with com_info as (
select
    community_name,
    community_id,
    community_user_num
from dim.dim_wework_community
where community_name in (
'【小蚕】杭州砍价福利群17🧧',
'【小蚕】苏州砍价福利群5🧧',
'【小蚕】美食地图-东莞站49',
'【小蚕】美食地图-东莞站50',
'【小蚕】上海砍价福利群12🧧',
'【小蚕】上海砍价福利群13🧧',
'【小蚕】金牛区外卖聚集地13',
'【小蚕】广州霸王餐福利群17',
'【小蚕】合肥砍价福利群6🧧'
)
group by 1,2,3
),

-- 企微群用户
com_user_info as (
select
    com_info.community_name,
    com_info.community_id,
    user_id,
    join_time
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1,2,3,4
),

-- 判断新老用户 根据各群创建日期判断(废弃) 根据用户进群时间判断
t1 as (
select
    a.community_name,
    a.user_id,
    first_explode_order_date,
    if(first_explode_order_date is null or date_format(first_explode_order_date,'%Y-%m-%d') >=date_format(join_time,'%Y-%m-%d'),'有效用户','非有效用户') as user_type
from com_user_info a
left join dim.dim_silkworm_explore_daren_cleanse b
on b.user_id=a.user_id
)

-- -- 探店下单
-- -- 同一个用户，可能在多个企微群出现，所以只能统计单个群的探店订单数据
-- t2 as (
-- select
--     user_id
--     ,count(distinct order_id ) as apply_order_num
--     ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
--     ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
--     ,count(distinct case when status=5 then order_id end) as finish_order_num
-- from 
--     dwd.dwd_sr_silkworm_explore_order
-- where 
--     date_format(dt,'%Y-%m-%d') between '2025-03-01' and '2025-03-31'
--     and promotion_type in (5,6)
-- group by user_id
-- ),

-- -- 判断是否有效用户
-- t3 as (
-- select
--     a.community_name,
--     a.user_id,
--     first_valid_order_time,
--     if(first_valid_order_time is null or date_format(first_valid_order_time,'%Y-%m-%d')='1970-01-01' or date_format(first_valid_order_time,'%Y-%m-%d') >=date_format(join_time,'%Y-%m-%d'),'有效用户','非有效用户') as user_type
-- from com_user_info a
-- left join dim.dim_silkworm_user b
-- on b.user_id=a.user_id
-- ),

-- -- 霸王餐有效单
-- t4 as (
-- select
--     user_id
--     ,count(distinct auto_id ) as valid_order_num
-- from 
--     dwd.dwd_sr_order_promotion_order
-- where 
--     date_format(dt,'%Y-%m-%d') between '2025-03-01' and '2025-03-31'
--     and order_status in (2,8)
-- group by user_id
-- )


select
    t1.community_name as `企微群名称`,
    t1.user_type `用户类型`,
    count(distinct com_user_info.user_id) `群人数`,
    count(distinct t1.user_id) `用户量`,
    count(distinct if(exp_valid_order_num>0,t1.user_id,null)) `完单用户量`,
    sum(exp_valid_order_num) `完单订单量`
from t1 left join t6 on t1.user_id=t6.user_id
left join com_user_info on t1.user_id=com_user_info.user_id and t1.community_name=com_user_info.community_name
group by 1,2
;
