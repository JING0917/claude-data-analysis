-- =============== 计算用户经纬度和店铺经纬度之间距离
-- dim.dim_silkworm_user
-- dim.dim_silkworm_store
-- dim.dim_client_user_location


-- select user_id,user_location,store_id from dwd.dwd_hive_silkworm_promotion_order
-- where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-24'
--     and user_id=923592157

-- 店铺经纬度
select store_id,longitude,latitude from dim.dim_silkworm_store
where store_id in (613666,587191,625960)

-- 用户经纬度
select silk_id,longitude,latitude from dim.dim_client_user_location
where silk_id=923592157

-- 计算经纬度差
6378137*2*ASIN(SQRT(POWER(SIN((ta.start_point_lat-ta.end_point_lat)*ACOS(-1)/360),2) 
    + COS(ta.start_point_lat*ACOS(-1)/180)*COS(ta.end_point_lat*ACOS(-1)/180)
    * POWER(SIN((ta.start_point_lng-ta.end_point_lng)*ACOS(-1)/360),2)))
as  distance


select 6378137*2*ASIN(SQRT(POWER(SIN((30.296662-30.310336)*ACOS(-1)/360),2) 
    + COS(30.296662*ACOS(-1)/180)*COS(30.310336*ACOS(-1)/180)
    * POWER(SIN((120.388609-120.361889)*ACOS(-1)/360),2)))
as  distance

-- 计算下单用户和店铺间距离
select
    a.user_id,
    a.store_id,
    6378137*2
    * 
    ASIN(SQRT(POWER(SIN((c.start_latitude-b.end_latitude)*ACOS(-1)/360),2) 
    + 
    COS(c.start_latitude*ACOS(-1)/180)*COS(b.end_latitude*ACOS(-1)/180)
    * 
    POWER(SIN((c.start_longitude-b.end_longitude)*ACOS(-1)/360),2))) as  distance
from (select 
        user_id,
        store_id
    from dwd.dwd_hive_silkworm_promotion_order
    where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-24'
        and order_status in (2,8)
        and user_id=923592157
    group by 1,2) a
left join
    -- 用户经纬度
    (select silk_id,
        longitude as end_longitude,
        latitude as end_latitude
    from dim.dim_client_user_location
    where silk_id=923592157) b
on a.user_id=b.silk_id
        left join
        -- 店铺经纬度
        (select store_id,
            longitude as start_longitude,
            latitude as start_latitude 
        from dim.dim_silkworm_store
        where store_id in (613666,587191,625960)) c
on a.store_id=c.store_id


==============================
================ 到店用户和店铺之间距离
with t1 as (
select  to_date(a.create_time) as create_date,
            a.user_id,
            c.wechat_nickname as user_nickname,
            if(daren_score >= 40, 1, 0) is_daren, -- 1:达人
            is_bind_wework, -- 是否绑定企微，1：是
            is_finish_exam, -- 是否完成考核 1：是
            is_open_renshen, -- 是否开启人审 1：是
            auth_xiaohongshu_id,
            auth_dp_id,
            substring(daren_activate_time, 1, 10) as daren_activate_date, -- 达人激活日期
            substring(xiaohongshu_auth_first_time, 1, 10) as xiaohongshu_auth_first_date, -- 小红书首次认证日期
            substring(dp_auth_first_time, 1, 10) as dp_auth_first_date, -- 大众点评首次认证日期
            substring(xiaohongshu_first_order_time, 1, 10) as xiaohongshu_first_order_date, -- 小红书首次下单日期
            substring(dp_first_order_time, 1, 10) as dp_first_order_date, -- 大众点评首次下单日期
            substring(dp_auth_time, 1, 10) as dp_auth_date, -- 大众点评认证日期
            substring(xiaohongshu_auth_time, 1, 10) as xiaohongshu_auth_date, -- 小红书认证日期
            -- 访问用户
            first_view_date, -- 首次访问日期
            first_explode_view_date as first_explore_view_date, -- 探店首次访问日期
            first_welfare_view_date, -- 公益首次访问日期
            -- 新增首单用户
            first_order_date, -- 新增首单日期
            first_explode_order_date as first_explore_order_date, -- 探店新增首单日期
            first_welfare_order_date -- 公益新增首单日期
from dim.dim_hive_silkworm_explore_daren a
inner join dim.dim_silkworm_user b
on a.user_id=b.user_id
    and b.city_id=3301 -- 杭州市
left join dim.dim_silkworm_user_wechat c
	on b.user_wechat_id=cast(c.user_wechat_id as string)
where a.status = 1 -- 1:正常,2:删除 -- 20240823新增 修改人：dahe
    and first_view_date is not null -- 限制是首次访问用户
),


-- 近7天累计外卖订单
t2 as (
select
    user_id,
    count(order_id) as cnt
from dwd.dwd_hive_silkworm_promotion_order
    where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-07-01' and date_sub(current_date,1)
        and substr(order_time,1,10) between date_sub(current_date,7) and date_sub(current_date,1)
        and order_status in (2,8)
        and city_id=3301 -- 杭州市
    group by 1
    having count(order_id)>=10
),

-- 首次下单日期和下单量
t3 as (
select
    user_id,
    substr(min(finish_time),1,10) as first_order_date, -- 首次下单日期
    count(order_id) as order_num -- 订单量
from dwd.dwd_hive_silkworm_explore_order
where dt between '2024-06-18' and date_sub(current_date,1)
    and store_name not regexp '测试'
    and status=5
    and substr(finish_time,1,10)<>'1970-01-01'
group by user_id
),



-- 取出拟调研用户
-- 6月解锁达人但未下单用户
t4 as (
select
    '7月20日以后解锁达人但未下单用户' as `类型`,
    user_id as `用户ID`,
    user_nickname as `用户昵称`
from t1
where daren_activate_date between '2024-07-20' and '2024-09-12'
    and is_daren=1
    and first_order_date is null

union all
-- 截止7月31日下首单且累计1单用户
select
    '截止7月31日下首单且累计1单用户' as `类型`,
    t3.user_id as `用户ID`,
    c.wechat_nickname as `用户昵称`
from t3
left join dim.dim_silkworm_user b on t3.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c
	on b.user_wechat_id=cast(c.user_wechat_id as string)
where t3.first_order_date is not null
    and t3.first_order_date<='2024-07-31'
    and t3.order_num=1

union all
-- 近7日累计外卖有效单10+未解锁达人用户
select
    '近7日累计外卖有效单10+未解锁达人用户' as `类型`,
    a.user_id as `用户ID`,
    a.user_nickname as `用户昵称`
from
(select
    user_id,user_nickname
from t1
where is_daren=0
) a
inner join t2 on a.user_id=t2.user_id
),

t5 as (
select
	`类型`,
	`用户ID`,
	`用户昵称`,
    d.city as end_city_name,
    d.district as end_county_name,
    d.longitude as end_longitude,
    d.latitude as end_latitude
from t4
left join dim.dim_client_user_location d
	on t4.`用户ID`=d.silk_id
),


-- 到店店铺经纬度
t6 as (
select store_id,
	b.city_name,
    b.county_name,
    longitude as start_longitude,
    latitude as start_latitude 
from dim.dim_silkworm_explore_store a
left join dim.dim_hive_region_code b on a.city_id=b.county_id
where store_id in (202,308,518,569,819,835)
),


-- 计算下单用户和店铺间距离
t7 as (
select
    t5.`类型`,
	t5.`用户ID`,
	t5.`用户昵称`,
    t6.store_id,
    6378137*2
    * 
    ASIN(SQRT(POWER(SIN((t6.start_latitude-t5.end_latitude)*ACOS(-1)/360),2) 
    + 
    COS(t6.start_latitude*ACOS(-1)/180)*COS(t5.end_latitude*ACOS(-1)/180)
    * 
    POWER(SIN((t6.start_longitude-t5.end_longitude)*ACOS(-1)/360),2))) as  distance
from t5
left join t6
on t5.end_city_name=t6.city_name
	and t5.end_county_name=t6.county_name
)

select     
    `类型`,
    store_id,
	`用户ID`,
	`用户昵称`,
    -- count(distinct if(distance<=2000,store_id,null)) as `两公里内店铺数`
    if(distance<=2000,1,0) as is_save -- 是否使用数据
from t7
where `类型`='7月20日以后解锁达人但未下单用户'
    and is_save=1
group by 1,2,3,4,5













