================== 探店达人用户访问
-- 探店业务用户
with t1 as (
select
    a.user_id
from dim.dim_hive_silkworm_explore_daren a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and b.city_id=3301 -- 杭州
where daren_score>=40
),


-- 0元到店访问用户
t2 as (select
            statistics_date,
            platform_name,
            cast(user_id as int) as user_id,
            sum(explore_homepage_pv+daren_homepage_pv+explore_activity_detailpage_pv) as explore_pv, -- 值>0，则是探店用户
            sum(welfare_homepage_pv+welfare_activity_detailpage_pv+weifare_faxinpage_pv+weifare_mypage_pv) as welfare_pv -- 值>0，则是公益用户
        from dws.dws_hive_traffic_user_d
        where to_date(statistics_date) between '2024-09-08' and '2024-09-17'
            -- and (user_id regexp '^[1-7]{1,7}$'
            -- or user_id regexp '^[1-8]{1,8}$'
            -- or user_id regexp '^[1-9]{1,9}$')
            and user_id regexp '^[0-9]{1,9}$'
        group by 1,2,3
      )

select 
statistics_date as `统计日期`,
-- platform_name as `平台名称`,
count(DISTINCT if(t1.user_id is not null,t2.user_id,null)) as `活跃达人用户量`
from t2
left join t1 on t2.user_id=t1.user_id
where explore_pv>0 or welfare_pv>0
group by 1
;



============
-- 固定周期达人下单统计
with t1 as (
select
    a.user_id,
    if(daren_score>=40,1,0) is_daren, -- 1:达人
    substring(daren_activate_time,1,10) as daren_activate_date, -- 达人激活日期
    substring(xiaohongshu_auth_first_time,1,10) as xiaohongshu_auth_first_date, -- 小红书首次认证日期
    substring(dp_auth_first_time,1,10) as dp_auth_first_date, -- 大众点评首次认证日期
    substring(xiaohongshu_first_order_time,1,10) as xiaohongshu_first_order_date, -- 小红书首次下单日期
    substring(dp_first_order_time,1,10) as dp_first_order_date, -- 大众点评首次下单日期
    -- 访问用户
    first_view_date, -- 首次访问日期
    first_explode_view_date as first_explore_view_date, -- 探店首次访问日期
    first_welfare_view_date, -- 公益首次访问日期
    -- 新增首单用户
    first_order_date, -- 新增首单日期
    first_explode_order_date as first_explore_order_date, -- 探店新增首单日期
    first_welfare_order_date -- 公益新增首单日期
from dim.dim_hive_silkworm_explore_daren a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and b.city_id=3301 -- 杭州
-- where daren_score>=40
),


-- 用户下首单时间
t2 as (
    select  user_id,
        cast(to_date(min(create_time)) as string) as order_date
    from    dwd.dwd_hive_silkworm_explore_order
    where   dt between '2024-06-18'
    and     '2024-09-17'
    and     store_name not regexp '测试'
    and promotion_type in (1,4) -- 探店
group by 1
)


select
    count(distinct if(daren_activate_date between '2024-09-03' and '2024-09-09' and is_daren=1,t1.user_id,null)) as `0903-0909解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-03' and '2024-09-09' and is_daren=1 and t2.order_date between '2024-09-03' and '2024-09-09',t1.user_id,null)) as `0903-0909下首单且解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-03' and '2024-09-09' and is_daren=1 and first_explore_order_date between '2024-09-03' and '2024-09-09',t1.user_id,null)) as `0903-0909完成首单且解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-10' and '2024-09-16' and is_daren=1,t1.user_id,null)) as `0910-0916解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-10' and '2024-09-16' and is_daren=1 and t2.order_date between '2024-09-10' and '2024-09-16',t1.user_id,null)) as `0910-0916下首单且解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-10' and '2024-09-16' and is_daren=1 and first_explore_order_date between '2024-09-10' and '2024-09-16',t1.user_id,null)) as `0910-0916完成首单且解锁达人用户数`
from t1 left join t2 on t1.user_id=t2.user_id
;
============