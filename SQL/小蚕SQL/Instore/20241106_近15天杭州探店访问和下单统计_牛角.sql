-- 用户维表
with t1 as (
    select user_id,
           case when xiaohongshu_fans_num between 200 and 499 then '小红书200-499粉'
               when xiaohongshu_fans_num>=500 then '小红书500粉及以上'
           else '其他' end as xhs_fs,
           case when dp_user_lvl>=5 then '大众点评V5及以上' else '其他' end as dp_lvl
    from dim.dim_silkworm_explore_daren_cleanse
    where xiaohongshu_fans_num>=200 or dp_user_lvl>=5
),




-- 杭州每日访问探店主页用户
t2 as (
    select  statistics_date, 
            cast(user_id as int) as user_id
    from    dws.dws_sr_traffic_user_d
    where   statistics_date between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
        and substr(county_id,1,4)='3301' -- 杭州
    group by 1,2
    having sum(explore_homepage_pv)>0
),


view_user as (
select
    statistics_date,
    xhs_fs,
    dp_lvl,
    count(distinct t2.user_id) as view_user_num,
    0 as pay_order_num,
    0 as verify_order_num
from t2 inner join t1 on t2.user_id=t1.user_id
group by grouping sets (
                        (statistics_date),
                        (statistics_date,xhs_fs),
                        (statistics_date,dp_lvl)
                        )

),


dim_pro as (
select
    promotion_id
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 60 day)
    and promotion_type in (1,4)
    and (demand_dp_user_lvl>=5 
        or demand_xiaohongshu_fans_num>=200
        )
),


-- 探店支付订单
t3 as (
-- 下单量
    select substr(pay_time,1,10) as statistics_date,
           xhs_fs,
           dp_lvl,
           0 as view_user_num,
           count(order_id) as pay_order_num,
           0 as verify_order_num
    from    dwd.dwd_sr_silkworm_explore_order a
    inner join dim.dim_silkworm_explore_store b on a.store_id=b.store_id and b.city_name='杭州市'
    inner join t1 on a.user_id=t1.user_id
    inner join dim_pro c on a.store_promotion_id=c.promotion_id
    where   date(a.dt) between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
        and a.store_name not regexp '测试'
        and a.promotion_type in (1,4)
group by grouping sets (
                        (statistics_date),
                        (statistics_date,xhs_fs),
                        (statistics_date,dp_lvl)
                        )

union all

-- 核销量
    select substr(verify_time,1,10) as statistics_date,
           xhs_fs,
           dp_lvl,
           0 as view_user_num,
           0 as pay_order_num,
           count(order_id) as verify_order_num
    from    dwd.dwd_sr_silkworm_explore_order a
    inner join dim.dim_silkworm_explore_store b on a.store_id=b.store_id and b.city_name='杭州市'
    inner join t1 on a.user_id=t1.user_id
    inner join dim_pro c on a.store_promotion_id=c.promotion_id
    where   date(a.dt) between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
        and a.store_name not regexp '测试'
        and a.promotion_type in (1,4)
group by grouping sets (
                        (statistics_date),
                        (statistics_date,xhs_fs),
                        (statistics_date,dp_lvl)
                        )
)


select
    statistics_date,
    xhs_fs,
    dp_lvl,
    sum(view_user_num) as `访问用户量`,
    sum(pay_order_num) as `下单量`,
    sum(verify_order_num) as `核销订单量`
from
(select * from t3
union all
select * from view_user
) tot
group by 1,2,3
;




