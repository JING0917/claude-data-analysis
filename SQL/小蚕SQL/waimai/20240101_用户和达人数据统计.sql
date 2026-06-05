======================= 用户注册
show create table dim.dim_silkworm_user;

select user_id,city_id,county_id from dim.dim_silkworm_user limit 10;

-- 用户量：10848591  昨日注册用户量：23125
select count(1) from dim.dim_silkworm_user where substr(register_time,1,10)='2024-10-30';


show create table dim.dim_silkworm_county;

-- 注册用户量
select
    b.province_name,
    b.city_name,
    b.county_name,
    count(distinct user_id) as `用户量`
from dim.dim_silkworm_user a
left join dim.dim_silkworm_county b
on substr(cast(a.county_id as string),1,6)=cast(b.county_id as string)
group by 1,2,3
;

-- 注册用户量
select
    b.province_name,
    b.city_name,
    b.county_name,
    count(distinct user_id) as `用户量`
from (
select
    user_id,county_id
from dim.dim_silkworm_user
where substr(register_time,1,10)='2024-10-29'
    ) a
left join dim.dim_silkworm_county b
on substr(cast(a.county_id as string),1,6)=cast(b.county_id as string)
group by 1,2,3
order by `用户量` desc
;



-- 浙江省V3+用户
select
    b.city_name `城市`,
    b.county_name `区县`,
    count(if(c.user_level=3,a.user_id,null)) as `V3用户量`,
    count(if(c.user_level=4,a.user_id,null)) as `V4用户量`,
    count(if(c.user_level=5,a.user_id,null)) as `V5用户量`
from
(select
 user_id,city_id,county_id
from dim.dim_silkworm_user
where county_id<>0
) a 
inner join dim.dim_silkworm_county b on a.county_id=b.county_id and b.province_name='浙江省'
inner join dim.dim_silkworm_member c on a.user_id=c.user_id and c.user_level>=3
group by 1,2;



select
    `年龄`,
    gender `性别`,
    count(1) `用户量`
from
(select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user) a
group by 1,2; 

===========================================

-- 用户积分
select
    -- count(distinct if(current_point<10000,user_id,null)) `1万积分内用户量`,
    -- count(distinct if(current_point between 10000 and 24999,user_id,null)) `1至2.5万积分用户量`,
    -- count(distinct if(current_point between 25000 and 34999,user_id,null)) `2.5至3.5万积分用户量`,
    -- count(distinct if(current_point between 35000 and 39999,user_id,null)) `3.5至4万积分用户量`,
    -- count(distinct if(current_point>=40000,user_id,null)) `4积分以上用户量`

    count(distinct if(accumulate_point<10000,user_id,null)) `1万积分内用户量`,
    count(distinct if(accumulate_point between 10000 and 24999,user_id,null)) `1至2.5万积分用户量`,
    count(distinct if(accumulate_point between 25000 and 34999,user_id,null)) `2.5至3.5万积分用户量`,
    count(distinct if(accumulate_point between 35000 and 39999,user_id,null)) `3.5至4万积分用户量`,
    count(distinct if(accumulate_point>=40000,user_id,null)) `4积分以上用户量`
from dwd.dwd_sr_market_task_user
;



================ 用户量
show create table dim.dim_silkworm_user;

select user_id,phone,user_id_num from dim.dim_silkworm_user where is_logoff=0 and user_id_num is not null and user_id_num<>'' limit 10;

select
    count(user_id) as tot_unum, -- 2466772
    count(if(phone is not null and phone<>'',user_id,null)) phone_unum, -- 2139211
    count(if(user_id_num is not null and user_id_num<>'',user_id,null)) id_unum -- 1568144
from dim.dim_silkworm_user
where is_logoff=0 -- 未注销
    and str_to_date(substr(latest_login_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
;


-- 用户量 176506（>=2）  0>=3）
select sum(cnt) from 
-- 最近30天登录过 同一个用户拥有多个账号
(select
    user_id_num,
    count(user_id) as cnt
from dim.dim_silkworm_user
where is_logoff=0 -- 未注销
    and str_to_date(substr(latest_login_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and user_id_num is not null and user_id_num<>''
group by 1
having count(user_id)>=3
) a
;


===============
-- 达人访问
set query_timeout=12000;

-- 杭州最近7天非达人活跃用户
select
    c.county_name `区县`,
    a.user_id as `用户ID`
from(
select
    cast(user_id as int) as user_id,
    cast(county_id as int) as county_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-29' and '2024-10-13'
-- dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4)='3301' -- 杭州
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2) a
inner join dim.dim_silkworm_explore_daren_cleanse b
on a.user_id=b.user_id 
    -- and (substr(b.xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    --     or substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and b.daren_score>=40
left join dim.dim_silkworm_county c on a.county_id=c.county_id
group by 1,2;

-- 杭州未解锁达人且近7天外卖订单>=3
with t1 as (
select 
    a.user_id
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and b.city_id=3301 -- 杭州
where a.daren_score<40
),

t2 as (
select 
    user_id,
    count(1) as order_num
from dwd.dwd_sr_order_promotion_order 
where cast(dt as string) between '2024-09-17' and '2024-09-23'
group by 1
having count(1)>=3
)
;



show create table dwd.dwd_sr_silkworm_explore_auth_record;

select status from dwd.dwd_sr_silkworm_explore_bind_wework_record
group by 1;

select
                    date(create_time) as bind_wework_date, -- 绑定企微日期
                    user_id
                from dwd.dwd_sr_silkworm_explore_bind_wework_record
                where dt<=current_date()
                    and status=0 -- 正常
                    and bind_interior_staff_wework_id>0
                group by 1,2
            ;
select * from dim.dim_silkworm_explore_store limit 10;


show create table dws.dws_sr_traffic_user_d;
select * from dws.dws_sr_traffic_user_d limit 10;

-- 达人访问
set query_timeout=12000;

-- 杭州活跃达人
select
    a.statistics_date `统计日期`,
    count(distinct a.user_id) as `杭州活跃达人量`
from
    (select  statistics_date,
            cast(user_id as int) as user_id
    from    dws.dws_sr_traffic_user_d
    where   cast(statistics_date as string) between '2024-09-29' and '2024-10-13'
        and user_id regexp '^[0-9]{1,9}$' -- 20240823调整，限制登录用户，减少数据量 修改人：dahe
        and substr(county_id,1,4)='3301' -- 杭州
    group by 1,2
    having  sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
    ) a
inner join dim.dim_silkworm_explore_daren_cleanse b
on a.user_id=b.user_id 
    and b.daren_score>=40
group by 1;


===========
================ 探店boss团长拉新
show create table dwd.dwd_sr_silkworm_explore_reward_record;

dim.dim_silkworm_explore_daren_cleanse;


select
    count(distinct a.user_id) as `拉新用户量`,
    count(distinct if(substr(b.xiaohongshu_auth_time,1,10)<>'1970-01-01' or substr(b.dp_auth_time,1,10)<>'1970-01-01',a.user_id,null)) as `已认证拉新用户量`
from 
-- (select user_id,
--     inviter_user_id
-- from dwd.dwd_sr_silkworm_explore_reward_record
-- where cast(dt as string) between '2024-09-01' and '2024-09-30' 
--     and inviter_user_id=924121252
--     and reward_type=3
-- group by 1,2) a
(select user_id,
    inviter_user_id from dim.dim_silkworm_user
where substr(register_time,1,10) between '2024-09-01' and '2024-09-30' 
    and inviter_user_id=924121252
) a
left join dim.dim_silkworm_explore_daren_cleanse b on a.user_id=b.user_id
;

-- 验证 该团长拉新118人
select count(1) as cnt from dim.dim_silkworm_user
where substr(register_time,1,10) between '2024-09-01' and '2024-09-30' 
    and inviter_user_id=924121252
;



================================ 到店绑定企微用户
show create table dwd.dwd_sr_silkworm_explore_bind_wework_record;

select * from dwd.dwd_sr_silkworm_explore_bind_wework_record limit 10

-- 绑定企微是674
with t1 as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and bind_interior_staff_wework_id in (674,511)
    and status=0
group by 1
)

-- select * from dim.dim_hive_silkworm_explore_daren
-- where substr(xiaohongshu_auth_first_time,1,10)='1970-01-01'
--         or substr(dp_auth_first_time,1,10)='1970-01-01'

-- show create table dim.dim_silkworm_explore_daren_cleanse;

-- 到店绑定企微但未完成认证用户
select
    t1.user_id
from t1
inner join dim.dim_silkworm_explore_daren_cleanse a
on t1.user_id=a.user_id
    and substr(a.xiaohongshu_auth_first_time,1,10)='1970-01-01'
        and substr(a.dp_auth_first_time,1,10)='1970-01-01'
inner join dim.dim_silkworm_user b
on a.user_id=b.user_id
    and b.city_id=3301 -- 杭州市


-- -- 是否存在已经认证，但达人分<40用户（存在）
-- select
--     count(*)
-- from dim.dim_silkworm_explore_daren_cleanse
-- where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
--         or substr(dp_auth_first_time,1,10)<>'1970-01-01'
--     )
--     and daren_score<40



-- 绑定企微用户
with t1 as (
select
    user_id
from dwd.dwd_hive_silkworm_explore_bind_wework_record
where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-18' and date_sub(current_date,1) -- 最小分区是20240618
    and bind_interior_staff_wework_id<>0
    and status=0
group by 1
)

-- 已经解锁达人身份，但未下探店订单用户
select
    a.user_id
from dim.dim_hive_silkworm_explore_daren a
inner join t1 on a.user_id=t1.user_id
where a.daren_score>=40
    and a.first_order_date is null
group by 1

select
first_order_date
from dim.dim_hive_silkworm_explore_daren
group by 1


-- 已解锁达人但未下单用户
select a.user_id from
(select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
        or substr(dp_auth_first_time,1,10)<>'1970-01-01'
    )
    and (substr(first_order_date,1,10) is null
    or substr(first_order_date,1,10)='1970-01-01'
    )
) a
inner join dim.dim_silkworm_user b
on a.user_id=b.user_id
    and b.city_id=3301 -- 杭州市
;

==========
show create table dim.dim_silkworm_explore_daren_cleanse;

show create table dim.dim_silkworm_user;

show create table dim.dim_silkworm_user_wechat;

-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id,bind_interior_staff_wework_account
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id in (674,511)
    and status=0
group by 1,2,3
)

-- 千粉用户绑定粉丝企微
select 
    a.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    concat('企',t1.bind_interior_staff_wework_account) `添加探店企微账号`
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b
on a.user_id=b.user_id
    and b.city_id=3301 -- 杭州市
left join t1
on a.user_id=t1.user_id
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
where a.xiaohongshu_fans_num>=1000
;


-- 绑定企微
with t1 as (
select
    user_id
    -- ,bind_interior_staff_wework_id
    -- ,bind_interior_staff_wework_account
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1
),

-- t2 as (
--         select
--             user_id
--         from dwd.dwd_sr_silkworm_explore_order
--         where cast(dt as string)>='2024-06-18'
--             and promotion_type in (1,4)
--         group by 1
-- )


-- -- 674未下单用户
-- select t1.user_id from t1 left join t2 on t1.user_id=t2.user_id where t2.user_id is null;



-- 订单
t2 as (
select
    user_id,
    date_diff('day',current_date(),max_order_date) as diff_days
from (
        select
            user_id,
            max(dt) as max_order_date
        from dwd.dwd_sr_silkworm_explore_order
        where cast(dt as string)>='2024-06-18'
            and promotion_type in (1,4)
        group by 1
    ) a
)


-- 858 且最近一次下单日期间隔>7天
select t1.user_id from t1 left join t2 on t1.user_id=t2.user_id and t2.diff_days>7 where t2.user_id is null;





select * from dim.dim_silkworm_user
where user_id in (147683250,923592157)
;

select * from dim.dim_silkworm_user_wechat
where user_wechat_id=9274743;

================================ 到店绑定企微用户




============ 根据身份证提取用户年龄、性别
select count(*) as tot, -- 10,611,918 总用户量
    count(distinct if(user_id_num is not null and user_id_num<>'',user_id_num,null)) as cnt, --2,054,337 有身份证ID去重用户量
    count(if(user_id_num is not null and user_id_num<>'',user_id_num,null)) as cnt2, -- 2,232,032 有身份证ID未去重用户量
    count(distinct if(user_id_num is not null and user_id_num<>'' 
                        and datediff(date_sub(current_date(),interval 1 day),cast(latest_login_time as datetime))>=30,
                        user_id_num,null)
        ) as cnt3 --593,661 有身份ID且近30天登录去重用户量
from dim.dim_silkworm_user

select user_id,
    cast(substring(user_id_num,7,8) as date) as `出生日期`,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS `性别`
from dim.dim_silkworm_user
limit 100
;




============== 欣欣 绑定过小红书/点评用户日活
set query_timeout=12000;

-- 杭州活跃达人
select
    a.statistics_date `统计日期`,
    count(distinct a.user_id) as `杭州活跃达人量`
from
    (select  statistics_date,
            cast(user_id as int) as user_id
    from    dws.dws_sr_traffic_user_d
    where   cast(statistics_date as string) between '2024-10-01' and '2024-10-31'
        and user_id regexp '^[0-9]{1,9}$' -- 20240823调整，限制登录用户，减少数据量 修改人：dahe
        and substr(county_id,1,4)='3301' -- 杭州    -- '3101' -- 上海
    group by 1,2
    having  sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
    ) a
inner join dim.dim_silkworm_explore_daren_cleanse b
on a.user_id=b.user_id 
    and (substr(b.xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
        or substr(dp_auth_first_time,1,10)<>'1970-01-01'
        )
group by 1;


show create table dwd.dwd_sr_silkworm_explore_order;

select
    b.city_name as `城市`,
    count(distinct a.user_id) as `首次核销探店订单用户量`
from
-- 首次核销探店订单用户数
(select 
    user_id,store_id,substr(min(verify_time),1,10) as min_verify_date
from dwd.dwd_sr_silkworm_explore_order
where cast(date(dt) as string) between '2024-06-01' and '2024-10-31'
    and promotion_type in (1,4) -- 探店
group by 1,2) a
inner join dim.dim_silkworm_explore_store b
on a.store_id=b.store_id 
    and b.city_name in ('杭州市','上海市')
where a.min_verify_date between '2024-10-01' and '2024-10-31'
group by 1
;



===================================== 牛角 杭州市近15天中数据
show create table dwd.dwd_sr_silkworm_explore_order;

show create table dwd.dwd_sr_silkworm_explore_promotion;

select
demand_dp_user_lvl,demand_xiaohongshu_fans_num
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 2 day)
group by 1,2;


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


===========
============================== 用户群数据量和阈值
-- 浏览探店但未下单用户量
select
    count(1) as tot_user_num -- 总用户量 4,846,634
    ,count(if(substr(first_explode_view_date,1,10) is not null and substr(first_explode_order_date,1,10) is null,user_id,null)) as newuser_num -- 新用户
    ,count(if((substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01' or substr(dp_auth_first_time,1,10)<>'1970-01-01')
                and substr(first_explode_order_date,1,10) is null,user_id,null)) as high_intention_newuser_num -- 高意向新用户
    ,count(if(substr(first_explode_order_date,1,10) is not null and is_bind_wework=0,user_id,null)) as induce_addwework_user_num -- 引导加企微用户
from dim.dim_silkworm_explore_daren_cleanse
where user_id<>329118405 -- 该用户是小蚕测试用户
;

select * from dim.dim_silkworm_explore_daren_cleanse where user_id=329118405;


-- 最近30天探店订单下单用户
-- 探店订单分位值
select
    PERCENTILE_CONT(explore_order_num,0.5) as p50_value,
    PERCENTILE_CONT(explore_order_num,0.75) as p75_value,
    PERCENTILE_CONT(explore_order_num,0.9) as p90_value
from (
-- 最近30天探店下单用户量 7146
select
    user_id,
    count(distinct order_id) as explore_order_num
from dwd.dwd_sr_silkworm_explore_order
where date(dt) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and promotion_type in (1,4)
    and user_id<>329118405 -- 该用户是小蚕测试用户
group by 1
    ) a
;

-- 数据是否异常 329118405 -- 该用户是小蚕测试用户
select * from dwd.dwd_sr_silkworm_explore_order
where date(dt) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and promotion_type in (1,4)
    and user_id=329118405
;

-- 下过探店订单，但最近30天内未下单用户
select count(distinct if(b.user_id is null,a.user_id,null)) as user_num
from
-- 下过探店订单用户
(select
    user_id
from dwd.dwd_sr_silkworm_explore_order
where date(dt) between '2024-06-18' and date_sub(current_date(),interval 31 day)
    and store_name not regexp '测试'
    and promotion_type in (1,4)
    and user_id<>329118405
group by 1) a
left join
-- 最近30天探店下单用户
(select
    user_id
from dwd.dwd_sr_silkworm_explore_order
where date(dt) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and promotion_type in (1,4)
    and user_id<>329118405
group by 1) b on a.user_id=b.user_id
;


-- 女性&霸王餐累计完单量>=3&不满意霸王餐订单量=0&探店订单=0
select
    count(a.user_id) as user_num
from
-- 女性&霸王餐累计完单量>=3
(select
    user_id
    -- count(1) cnt -- 931078
from dim.dim_silkworm_user
where accu_valid_order_num>=3
    and (case when user_id_num='' then '未知' when cast(substr(user_id_num,17,1) as int) % 2=1 then '男' else '女' end)<>'男'
) a
inner join
-- 近180天不满意霸王餐订单量
    (select 
        user_id,sum(if(order_status=8,1,0)) as unsatisfied_order_num
    from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 210 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    group by 1
    having sum(if(order_status=8,1,0))=0
    ) b
on a.user_id=b.user_id
inner join
-- 未产生探店订单用户
    (select
        user_id,sum(if(promotion_type in (1,4),1,0)) as explore_order_num
    from dwd.dwd_sr_silkworm_explore_order
    where date(dt) between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
        and store_name not regexp '测试'
        and user_id<>329118405 -- 该用户是小蚕测试用户
    group by 1
    having sum(if(promotion_type in (1,4),1,0))=0
    ) c on a.user_id=c.user_id
;



-- 最近30天下过甜品饮品订单用户
select
    count(distinct a.user_id) as user_num
    ,count(distinct if(a.order_status in (2,8),a.user_id,null)) as valid_user_num
from
-- 最近30天下单用户
(select 
        user_id,store_id,order_status,count(1) as order_num
    from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 45 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    group by 1,2,3
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.sub_category_type=3
;



-- 奶茶量下单分位值
select
    PERCENTILE_CONT(order_num,0.5) as p50_value,
    PERCENTILE_CONT(order_num,0.75) as p75_value,
    PERCENTILE_CONT(order_num,0.9) as p90_value
from 
-- 奶茶类下单量
(select
    user_id,sum(order_num) as order_num
from
-- 最近30天下单用户
(select 
        user_id,store_id,order_status,count(1) as order_num
    from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 45 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    group by 1,2,3
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.sub_category_type=3
group by 1) b
;



select
    count(distinct user_id) as user_num -- 1340217 -- 56751
from
-- 最近90天下单用户
(select 
        user_id,
        sum(if(order_type=12,1,0)) as mt_order_num,
        sum(if(order_type=13,1,0)) as elm_order_num
        -- count(distinct user_id)
    from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 105 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
group by 1) a
-- 美团下单>=3，饿了么下单=0
-- where mt_order_num>=3 and elm_order_num=0
-- 美团下单=0，饿了么下单>=3
where mt_order_num=0 and elm_order_num>=3
-- 看用户量
-- where mt_order_num>0 and elm_order_num=0
-- where mt_order_num=0 and elm_order_num>0
;


======== 探店访问和下单
select * from dim.dim_silkworm_county where county_name='钱塘区';

-- 钱塘区访问探店但未下单用户
select
    a.user_id
from
-- 近7天访问探店用户
(select  
    cast(user_id as int) as user_id
 from dws.dws_sr_traffic_user_d
 where statistics_date between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and substr(county_id,1,6)='330114'
 group by 1
 having sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv)>0
) a
inner join dim.dim_silkworm_explore_daren_cleanse b 
    on a.user_id=b.user_id 
    and substr(b.first_explode_order_date,1,10) is null  -- 未下探店单
    and b.user_id<>329118405 -- 该用户是小蚕测试用户
;

-- 验证 无问题
select * from dim.dim_silkworm_explore_daren_cleanse
where user_id=88694082;


=================
-- 探店用户下单量
with t1 as
(select 
  user_id,
  count(order_id) as order_num,
  count(if(status in (4,5,19,20),order_id,null)) as finished_num
from dwd.dwd_sr_silkworm_explore_order
where date(dt) between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
  and store_name not regexp '测试'
  and promotion_type in (1,4)
group by 1
),


-- 用户属性
t2 as (
select
  user_id,
  b.province_name,
  b.city_name,
  b.county_name,
  year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
  case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS `性别`
from dim.dim_silkworm_user a
left join dim.dim_silkworm_county b on a.county_id=b.county_id
  )


select
  t1.user_id `用户ID`,
  t2.province_name `省份`,
  t2.city_name `城市`,
  t2.county_name `区县`,
  t2.`年龄`,
  t2.`性别`,
  t1.order_num `探店下单量`,
  t1.finished_num `探店完单量`
from t1 left join t2 on t1.user_id=t2.user_id
;

=========
-- 探店达人
show create table dim.dim_silkworm_explore_daren_cleanse;
select * from dim.dim_silkworm_explore_daren_cleanse where dp_user_lvl<>0 limit 10;
select * from dim.dim_silkworm_explore_daren_cleanse where user_id in (862835879,369197103);

select
    -- substr(xiaohongshu_auth_first_time,1,10) as `认证日期`,
    substr(dp_auth_first_time,1,10) as `认证日期`,
    -- count(if(xiaohongshu_fans_num>=200,user_id,null)) as `小红书200+粉用户量`
    count(if(dp_user_lvl>=5,user_id,null)) as `大众点评5+用户量`
from dim.dim_silkworm_explore_daren_cleanse
where 
    -- substr(xiaohongshu_auth_first_time,1,10) between '2024-10-01' and '2024-10-31'
    substr(dp_auth_first_time,1,10) between '2024-10-01' and '2024-10-31'
group by 1;



=======
-- 指定团长拉新用户数据
select
    substr(register_time,1,10) `注册日期`,
    inviter_user_id `团长ID`,
    user_id `用户ID`,
    ifnull(b.city_name,'其他') `注册城市`,
    ifnull(b.county_name,'其他') `注册区县`,
    a.accu_valid_order_num `累计有效订单量`
from dim.dim_silkworm_user a
left join dim.dim_silkworm_county b on a.county_id=b.county_id
where str_to_date(register_time,'%Y-%m-%d') between date(date_sub(current_date(),interval (dayofweek(current_date())+3) day))
                                                and date(date_sub(current_date(),interval (dayofweek(current_date())-3) day)) -- 上周三本周二
    and inviter_user_id in (991296170) -- 根据需要自定义指定团长ID
    and accu_valid_order_num>=3 -- 有效订单>=3


===========
-- 探店新增达人用户量
select
    count(distinct user_id)
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10) between '2024-10-01' and '2024-10-31'
    and xiaohongshu_fans_num>=200
    and substr(dp_auth_first_time,1,10)='1970-01-01'
    )
    or (substr(dp_auth_first_time,1,10) between '2024-10-01' and '2024-10-31'
    and dp_user_lvl>=5
    and substr(xiaohongshu_auth_first_time,1,10)='1970-01-01'
    )
;

-- 累计达人
select
    count(distinct user_id)
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<='2024-11-18'
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<='2024-11-18'
    and dp_user_lvl>=5
    )
;

-- 达人下单和核销
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<='2024-10-31' 
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<='2024-10-31' 
    and dp_user_lvl>=5
    )
),


t2 as (
select
    user_id,
    count(order_id) order_num
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string) between '2024-10-01' and '2024-10-31'
    -- and substr(verify_time,1,10) between '2024-11-01' and '2024-11-18'
    and store_name not regexp '测试'
    and user_id<>329118405 
    -- and status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33)
    and promotion_type in (1,4)
group by 1
)

-- select
--     t1.user_id,
--     t1.xiaohongshu_fans_num,
--     t1.dp_user_lvl,
--     sum(order_num) as order_num
-- from t1
-- inner join t2 on t1.user_id=t2.user_id
-- group by 1,2,3
-- ;

select
    count(distinct t1.user_id) as ucnt,
    sum(order_num) as order_num
from t1
inner join t2 on t1.user_id=t2.user_id
;

-- 达人访问量
with t1 as (
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<='2024-10-31' 
    and xiaohongshu_fans_num>=200 
    )
    or (substr(dp_auth_first_time,1,10)<='2024-10-31' 
    and dp_user_lvl>=5
    )
),


t2 as (
select  
        cast(user_id as int) as user_id
from    dws.dws_sr_traffic_user_d
where   statistics_date between '2024-10-01' and '2024-10-31' 
and     user_id regexp '^[0-9]{1,9}$' 
group by 1
having sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
)

select count(t1.user_id) as cnt from t1 inner join t2 on t1.user_id=t2.user_id;

===========
-- 认证
show create table dwd.dwd_sr_silkworm_explore_auth_record;

-- operator_id -- 0机审 非0人审
select
    dt,
    count(1) as `审核次数`,
    sum(if(operator_id=0,1,0)) as `机审次数`
from dwd.dwd_sr_silkworm_explore_auth_record
where cast(dt as string) between '2024-11-16' and '2024-11-19'
    and account_type=1 -- 1点评 2红书
    and status=1 -- 1正常 2废弃
group by 1
;


select
    dt,
    hour(create_time) hr,
    count(distinct user_id) over(partition by dt,hour(create_time) order by dt,hour(create_time)) as uv
    -- multi_distinct_count(user_id) over(partition by dt,hour(create_time) order by dt,hour(create_time)) as uv
from dwd.dwd_sr_silkworm_explore_auth_record
where cast(dt as string) between '2024-11-19' and '2024-11-19'
    and account_type=1 -- 1点评 2红书
    -- and status=1 -- 1正常 2废弃
group by 1,2
;




