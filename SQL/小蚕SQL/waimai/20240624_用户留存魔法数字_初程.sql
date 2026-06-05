目的：找到影响用户留存的主要因素
留存：未下单定义为流失，时间周期要看下下单时间分布


1、最近一次下单距离目前天数，最近一次有效单距目前天数
2、取消率是否高

======== part 1 流失用户购买频次
-- 5月下单用户，6月下单
with t1 as (
select
    c.user_id,
    c.user_type, -- 新老用户
    c.order_num, -- 5月下单量
    c.vaild_order_num, -- 5月有效下单量
    nvl(d.latest_order_num,0) as latest_order_num, -- 6月下单量
    nvl(d.latest_vaild_order_num,0) as latest_vaild_order_num -- 6月有效下单量
from (
select
    a.user_id,
    -- if(b.user_id is not null,'新用户','老用户') as user_type,
    b.user_level as user_type,
    count(a.order_id) order_num,
    count(if(a.order_status in (2,8),a.order_id,null)) as vaild_order_num
from dwd.dwd_hive_silkworm_promotion_order a
left join
-- -- 新用户
--         (select
--             user_id
--         from dim.dim_silkworm_user a
--         where substr(register_time,1,10) between '2024-05-01' and '2024-05-31'
--         ) b
dim.dim_silkworm_member b
    on a.user_id=b.user_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-05-01' and '2024-05-31'
group by 1,2
    ) c
left join
-- 6月下单
        (select
             user_id,
             count(order_id) as latest_order_num,
             count(if(order_status in (2,8),order_id,null)) as latest_vaild_order_num
        from dwd.dwd_hive_silkworm_promotion_order
        where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-24'
        group by user_id
        ) d
    on c.user_id=d.user_id

)


-- 新老用户流失用户购买频次用户量
select
    a.`用户类型`,
    a.`下单量`,
    a.`5月下单用户量`,
    b.`6月下单用户量`
from
-- 5月下单频次
(select
    user_type `用户类型`,
    order_num `下单量`,
    count(user_id) as `5月下单用户量`
from t1
where order_num>0 
group by 1,2) a
left join
-- 5月有下单且6月下单频次
(select
    user_type `用户类型`,
    latest_order_num `下单量`,
    count(user_id) as `6月下单用户量`
from t1
where order_num>0 
    and latest_order_num>0
group by 1,2) b
on a.`用户类型`=b.`用户类型`
    and a.`下单量`=b.`下单量`

union all

select
    a.`用户类型`,
    a.`下单量`,
    a.`5月下单用户量`,
    b.`6月下单用户量`
from
-- 5月下单频次
(select
    '整体' `用户类型`,
    order_num `下单量`,
    count(user_id) as `5月下单用户量`
from t1
where order_num>0 
group by 1,2) a
left join
-- 5月有下单且6月下单频次
(select
    '整体' `用户类型`,
    latest_order_num `下单量`,
    count(user_id) as `6月下单用户量`
from t1
where order_num>0 
    and latest_order_num>0
group by 1,2) b
on a.`用户类型`=b.`用户类型`
    and a.`下单量`=b.`下单量`



================= 流失用户5月下单时间间隔
-- 5月下单用户，6月下单
with t1 as (
select
    c.user_id,
    c.user_type, -- 新老用户
    c.order_num, -- 5月下单量
    c.vaild_order_num, -- 5月有效下单量
    nvl(d.latest_order_num,0) as latest_order_num, -- 6月下单量
    nvl(d.latest_vaild_order_num,0) as latest_vaild_order_num -- 6月有效下单量
from (
select
    a.user_id,
    if(b.user_id is not null,'新用户','老用户') as user_type,
    count(a.order_id) order_num,
    count(if(a.order_status in (2,8),a.order_id,null)) as vaild_order_num
from dwd.dwd_hive_silkworm_promotion_order a
left join
-- 新用户
        (select
            user_id
        from dim.dim_silkworm_user
        where substr(register_time,1,10) between '2024-05-01' and '2024-05-31'
        ) b
    on a.user_id=b.user_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-05-01' and '2024-05-31'
group by 1,2
    ) c
left join
-- 6月下单
        (select
             user_id,
             count(order_id) as latest_order_num,
             count(if(order_status in (2,8),order_id,null)) as latest_vaild_order_num
        from dwd.dwd_hive_silkworm_promotion_order
        where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-24'
        group by user_id
        ) d
    on c.user_id=d.user_id

)

-- 流失用户5月下单时间间隔
select
    t1.user_id,
    t1.user_type,
    t1.order_num,
    b.order_time,
    b.first_order_time,
    b.last_order_time,
    b.next_order_time 
from t1
left join
    (select
        user_id,
        order_time,
        first_value(order_time) over(partition by user_id order by order_time asc) as first_order_time,
        last_value(order_time) over(partition by user_id order by order_time desc) as last_order_time,
        lead(order_time) over(partition by user_id order by order_time asc) as next_order_time 
    from dwd.dwd_hive_silkworm_promotion_order
    where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-05-01' and '2024-05-31'
    ) b
on t1.user_id=b.user_id
where t1.order_num>0 
    and t1.latest_order_num>0



======== part 2 区县流量
-- 流量日志
with t as (
select
    event_time,
    county_id,
    user_id,
    device_id,
    activity_id
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and date_sub(current_date,1)
    and event_name in ('HomePage_takeout_Activity_ex','HomePage_takeout_Activity_Click','Takeout_Activity_Detail_View')
    -- and cast(substr(county_id,1,4) as int) in (1101,4101,1201,6101,4201,3701,3702,3301,4406,3101)
    -- and length(activity_id)=8
    and activity_id regexp '^[1-9]{1,8}$' -- 自营活动  如果分析只需要自营活动的话，需要做此区分
)


-- 统计区县流量
select
    city_name as `城市`,
    county_name as `区县`,
    sum(avg_sy_bg_cnt) as `日均首页活动曝光量`,
    sum(avg_sy_bg_uv) as `日均首页活动曝光UV`,
    sum(avg_sy_bg_hd_num) `日均首页曝光活动量`,
    sum(avg_sy_hd_cnt) `日均首页活动点击量`,
    sum(avg_sy_hd_uv) `日均首页活动点击用户量`,
    sum(avg_sy_hd_num) `日均首页点击活动量`,
    sum(avg_hd_detail_pv) `日均活动详情页PV`,
    sum(avg_hd_detail_uv) `日均活动详情页UV`,
    sum(avg_hd_detail_num) `日均浏览活动量`
from (
-- 首页曝光
select
    city_name,
    county_name,
    avg(sy_bg_cnt) as avg_sy_bg_cnt,
    avg(sy_bg_uv) as avg_sy_bg_uv,
    avg(sy_bg_hd_num) avg_sy_bg_hd_num,
    0 as avg_sy_hd_cnt,
    0 as avg_sy_hd_uv,
    0 as avg_sy_hd_num,

    0 as avg_hd_detail_pv,
    0 as avg_hd_detail_uv,
    0 as avg_hd_detail_num
from (select 
    from_unixtime(event_time,'yyyy-MM-dd') as dat,
    b.city_name,
    b.county_name,
    count(*) as sy_bg_cnt,
    count(distinct if(length(a.user_id)>2,a.user_id,a.device_id)) as sy_bg_uv,
    count(distinct if(length(a.activity_id)=8,a.activity_id,null)) as sy_bg_hd_num
from (select * from t
where event_name in ('HomePage_takeout_Activity_ex')
    ) a
left join dim.dim_hive_region_code b
on cast(a.county_id as int)=b.county_id
group by 1,2,3) a
group by 1,2


union all

-- 首页活动点击
select
    city_name,
    county_name,
    0,
    0,
    0,
    avg(sy_hd_cnt) as avg_sy_hd_cnt,
    avg(sy_hd_uv) as avg_sy_hd_uv,
    avg(sy_hd_num) avg_sy_hd_num,
    0,
    0,
    0
from (select 
    from_unixtime(event_time,'yyyy-MM-dd') as dat,
    b.city_name,
    b.county_name,
    count(*) as sy_hd_cnt,
    count(distinct if(length(a.user_id)>2,a.user_id,a.device_id)) as sy_hd_uv,
    count(distinct if(length(a.activity_id)=8,a.activity_id,null)) as sy_hd_num
from (select * from t
where event_name in ('HomePage_takeout_Activity_Click')
    ) a
left join dim.dim_hive_region_code b
on cast(a.county_id as int)=b.county_id
group by 1,2,3) a
group by 1,2


union all

-- 活动详情页浏览
select
    city_name,
    county_name,
    0,
    0,
    0,
    0,
    0,
    0,
    avg(hd_detail_cnt) as avg_hd_detail_pv,
    avg(hd_detail_uv) as avg_hd_detail_uv,
    avg(hd_detail_num) avg_hd_detail_num
from (select 
    from_unixtime(event_time,'yyyy-MM-dd') as dat,
    b.city_name,
    b.county_name,
    count(*) as hd_detail_cnt,
    count(distinct if(length(a.user_id)>2,a.user_id,a.device_id)) as hd_detail_uv,
    count(distinct if(length(a.activity_id)=8,a.activity_id,null)) as hd_detail_num
from (select * from t
where event_name in ('Takeout_Activity_Detail_View')
    ) a
left join dim.dim_hive_region_code b
on cast(a.county_id as int)=b.county_id
group by 1,2,3) a
group by 1,2
) tot
group by 1,2




======== part 3 流失用户浏览行为
-- 5月下单用户，6月下单
with t1 as (
select
    c.user_id,
    c.user_type, -- 新老用户
    c.order_num, -- 5月下单量
    c.vaild_order_num, -- 5月有效下单量
    nvl(d.latest_order_num,0) as latest_order_num, -- 6月下单量
    nvl(d.latest_vaild_order_num,0) as latest_vaild_order_num -- 6月有效下单量
from (select
            a.user_id,
            -- datediff(date_sub(current_date,1),to_date(substr(a.order_time,1,10))) as diff_order_days,
            if(b.user_id is not null,'新用户','老用户') as user_type,
            count(a.order_id) order_num,
            count(if(a.order_status in (2,8),a.order_id,null)) as vaild_order_num
from dwd.dwd_hive_silkworm_promotion_order a
left join
-- 新用户
        (select
            user_id
        from dim.dim_silkworm_user
        where substr(register_time,1,10) between '2024-05-01' and '2024-05-31'
        ) b
    on a.user_id=b.user_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-05-01' and '2024-05-31'
group by 1,2
    ) c
left join
-- 6月下单
        (select
             user_id,
             count(order_id) as latest_order_num,
             count(if(order_status in (2,8),order_id,null)) as latest_vaild_order_num
        from dwd.dwd_hive_silkworm_promotion_order
        where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-24'
        group by user_id
        ) d
    on c.user_id=d.user_id
),

-- 流量日志
t2 as (
select
    dt,
    event_time,
    user_id,
    activity_id,
    event_name
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and '2024-06-24'
    and event_name in (
        'HomePage_View'
        -- 'HomePage_takeout_Activity_ex'
        -- 'HomePage_takeout_Activity_Click'
        -- 'Takeout_Activity_Detail_View'
        -- 'Takeout_Grab_Click'
        -- 'Homepage_Search_Activity_Ex'
        -- 'Homepage_Search_Result_Click'
        )
    -- and length(activity_id)>=1
),



-- 留存用户日志 between 8 and 16用户
t3 as (
select
    t2.dt,
    t2.event_time,
    t2.user_id,
    t2.activity_id,
    t2.event_name,
    b.user_type,
    b.order_num
from t2
inner join (
    select
        user_id,
        user_type,
        order_num
    from t1
where order_num between 8 and 16
        and latest_order_num between 8 and 16
    ) b
on t2.user_id=b.user_id 
)



-- 留存用户行为统计
select
    order_num,
    user_type,
    count(*) as sy_pv,
    count(distinct user_id) as sy_uv
from t3
group by 1,2

union all

-- 整体
select
    order_num,
    '整体' user_type,
    count(*) as sy_pv,
    count(distinct user_id) as sy_uv
from t3
group by 1,2



-- union all

-- select
-- user_id,
-- user_type,
-- 0 as sy_pv,
-- count(*) as sy_hd_bg,
-- 0 as sy_hd_dj,
-- 0 as hd_pv,
-- 0 as qd_dj,
-- 0 as ss_bg,
-- 0 as ss_dj
-- from t3
-- where event_name='HomePage_takeout_Activity_ex'
-- group by 1,2

-- union all

-- select
-- user_id,
-- user_type,
-- 0 as sy_pv,
-- 0 as sy_hd_bg,
-- count(*) as sy_hd_dj,
-- 0 as hd_pv,
-- 0 as qd_dj,
-- 0 as ss_bg,
-- 0 as ss_dj
-- from t3
-- where event_name='HomePage_takeout_Activity_Click'
-- group by 1,2

-- union all

-- select
-- user_id,
-- user_type,
-- 0 as sy_pv,
-- 0 as sy_hd_bg,
-- 0 as sy_hd_dj,
-- count(*) as hd_pv,
-- 0 as qd_dj,
-- 0 as ss_bg,
-- 0 as ss_dj
-- from t3
-- where event_name='Takeout_Activity_Detail_View'
-- group by 1,2

-- union all

-- select
-- user_id,
-- user_type,
-- 0 as sy_pv,
-- 0 as sy_hd_bg,
-- 0 as sy_hd_dj,
-- 0 as hd_pv,
-- count(*) as qd_dj,
-- 0 as ss_bg,
-- 0 as ss_dj
-- from t3
-- where event_name='Takeout_Grab_Click'
-- group by 1,2

-- union all

-- select
-- user_id,
-- user_type,
-- 0 as sy_pv,
-- 0 as sy_hd_bg,
-- 0 as sy_hd_dj,
-- 0 as hd_pv,
-- 0 as qd_dj,
-- count(*) as ss_bg,
-- 0 as ss_dj
-- from t3
-- where event_name='Homepage_Search_Activity_Ex'
-- group by 1,2

-- union all

-- select
-- user_id,
-- user_type,
-- 0 as sy_pv,
-- 0 as sy_hd_bg,
-- 0 as sy_hd_dj,
-- 0 as hd_pv,
-- 0 as qd_dj,
-- 0 as ss_bg,
-- count(*) as ss_dj
-- from t3
-- where event_name='Homepage_Search_Result_Click'
-- group by 1,2
-- )

===== 确认是否下单留存是常态规律
-- 5月下单用户，6月下单
with t1 as (
select
    c.user_id,
    c.user_type, -- 新老用户
    c.order_num, -- 5月下单量
    c.vaild_order_num, -- 5月有效下单量
    nvl(d.latest_order_num,0) as latest_order_num, -- 6月下单量
    nvl(d.latest_vaild_order_num,0) as latest_vaild_order_num -- 6月有效下单量
from (select
            a.user_id,
            -- datediff(date_sub(current_date,1),to_date(substr(a.order_time,1,10))) as diff_order_days,
            if(b.user_id is not null,'新用户','老用户') as user_type,
            count(a.order_id) order_num,
            count(if(a.order_status in (2,8),a.order_id,null)) as vaild_order_num
from dwd.dwd_hive_silkworm_promotion_order a
left join
-- 新用户
        (select
            user_id
        from dim.dim_silkworm_user
        where substr(register_time,1,10) between '2024-04-01' and '2024-04-30'
        ) b
    on a.user_id=b.user_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-04-01' and '2024-04-30'
group by 1,2
    ) c
left join
-- 6月下单
        (select
             user_id,
             count(order_id) as latest_order_num,
             count(if(order_status in (2,8),order_id,null)) as latest_vaild_order_num
        from dwd.dwd_hive_silkworm_promotion_order
        where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-05-01' and '2024-05-31'
        group by user_id
        ) d
    on c.user_id=d.user_id
)


select
user_type `用户类型`,
order_num `下单量`,
count(user_id) as `下单用户量`
from t1
where order_num>0 
    and latest_order_num>0
group by 1,2

union all

select
'整体' `用户类型`,
order_num `下单量`,
count(user_id) as `下单用户量`
from t1
where order_num>0 
    and latest_order_num>0
group by 1,2


-- 首页PV
select 
    -- dt,
    count(*) as pv,
    count(distinct if(length(user_id)>1,user_id,null)) as uv
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and '2024-06-24'
    and event_name ='HomePage_View'
-- group by dt



