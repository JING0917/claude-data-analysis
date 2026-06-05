1、自营活动=非运营+运营。非运营即商务自建活动。cps接口活动不进入活动表，在订单表中，活动ID长度是1。
2、自营有效订单中，需要扣除运营有效订单、饿了么有效订单、美团专版有效订单、VIP有效订单。
1）运营订单：运营活动的有效订单；
2）饿了么订单：饿了么cps活动有效订单；
3）美团专版订单：美团cps活动有效订单；
4）VIP订单：大牌专享活动的有效订单；
5）扣减后名额消耗量：自营活动有效订单量。

-- 抢单点击
with t1 as (
select
    dt,
    user_id,
    device_id,
    county_id,
    activity_id
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and '2024-06-16'
    and event_name='Takeout_Grab_Click'
group by 1,2,3,4,5
),

-- uv
t2 as (
select
    dt,
    user_id,
    device_id,
    county_id
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and '2024-06-16'
group by 1,2,3,4
),

-- 城市
t3 as(
select 
    user_id,
    county_id
from dim.dim_silkworm_user
where substr(register_time,1,10) between '2024-06-01' and '2024-06-16'
)


-- 自营
select
    `统计日期`,
    `城市`,
    sum(`有效订单量`) as `有效订单量`,
    sum(uv) as uv,
    sum(`抢单点击用户量`) as `抢单点击用户量`,
    sum(`有效订单用户量`) as `有效订单用户量`,
    sum(`新用户量`) as `新用户量`,
    sum(`抢单点击新用户量`) as `抢单点击新用户量`,
    sum(`新用户有效订单量`) as `新用户有效订单量`,
    sum(`有效新用户量`) as `有效新用户量`
from
(
-- 日城市订单量
select 
    concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) as `统计日期`,
    c.city_name as `城市`,
    count(distinct if(t1.user_is is not null,a.order_id,null)) as `有效订单量`,
    0 as uv,
    0 as `抢单点击用户量`,
    count(distinct if(t1.user_is is not null,a.user_id,null)) as `有效订单用户量`,
    0 as `新用户量`,
    0 as `抢单点击新用户量`,
    count(distinct if(t1.user_is is not null and b.user_id is not null,a.order_id,null)) as `新用户有效订单量`,
    count(distinct if(t1.user_is is not null and b.user_id is not null,a.user_id,null)) as `有效新用户量`
from dwd.dwd_hive_silkworm_promotion_order a -- 订单
left join t3 b
    on a.user_id=b.user_id
left join dim.dim_hive_region_code c
    on a.county_id=c.county_id
inner join t1
    on a.user_id=cast(t1.user_id as int) 
        and concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0'))=t1.dt
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-06-01' and '2024-06-16'
    and a.order_status in (2,8)
    and length(cast(a.store_promotion_id as string))>1 -- 自营活动
group by 1,2

union all

-- 新用户量
select
    substr(a.register_time,1,10) as `统计日期`,
    b.city_name as `城市`,
    0 as `有效订单量`,
    0 as uv,
    0 as `抢单点击用户量`,
    0 as `有效订单用户量`,
    count(*) as `新用户量`,
    0 as `抢单点击新用户量`,
    0 as `新用户有效订单量`,
    0 as `有效新用户量`
from dim.dim_silkworm_user a
left join dim.dim_hive_region_code b
    on a.county_id=b.county_id
where substr(a.register_time,1,10) between '2024-06-01' and '2024-06-16'
group by 1,2

union all

-- 抢单点击
-- 自营
select 
    dt as `统计日期`,
    b.city_name as `城市`,
    0 as `有效订单量`,
    0 as uv,
    count(distinct if(length(t1.user_id)>0,t1.user_id,t1.device_id)) as `抢单点击用户量`,
    0 as `有效订单用户量`,
    0 as `新用户量`,
    count(distinct d.user_id) as `抢单点击新用户量`,
    0 as `新用户有效订单量`,
    0 as `有效新用户量`
from t1
left join dim.dim_hive_region_code b
    on cast(t1.county_id as int)=b.county_id
left join t3 d
    on cast(t1.user_id as int)=d.user_id
where length(t1.activity_id)>1
group by 1,2

union all
--uv
select
    dt as `统计日期`,
    b.city_name as `城市`,
    0 as `有效订单量`,
    count(distinct if(length(t2.user_id)>0,t2.user_id,t2.device_id)) as uv,
    0 as `抢单点击用户量`,
    0 as `有效订单用户量`,
    0 as `新用户量`,
    0 as `抢单点击新用户量`,
    0 as `新用户有效订单量`,
    0 as `有效新用户量`
from t2
left join dim.dim_hive_region_code b
    on cast(t2.county_id as int)=b.county_id
group by 1,2
) tot
group by 1,2


-- ====================================================== 奈雪&喜茶转化 ======================================================
-- 喜茶和奈雪 转化漏斗
-- 城市维表
with t1 as (
select
    city_id,
    city_name,
    county_id,
    county_name
from dim.dim_hive_region_code
),

-- 奈雪&喜茶活动
t as (
select concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) as dat,
    t1.county_name,
    a.store_promotion_id,
    if(b.store_name regexp '喜茶','喜茶','奈雪的茶') as brand_name,
    a.meituan_promotion_quota+a.eleme_promotion_quota as tot_promotion_quota
from dwd.dwd_hive_store_promotion a -- 店铺活动
inner join dim.dim_silkworm_store b
on a.store_id=b.store_id
    and b.store_name regexp '奈雪|喜茶'
left join t1 
    on a.county_id=t1.county_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-01-01' and date_sub(current_date,1)
        and a.status in (1,4,5)
        and a.city_id=3101  -- 上海
        and a.is_vip_exclusive=0
        and a.is_operation_promption=0
),


-- 漏斗事件
t2 as (
select
    a.dt,
    a.event_time,
    a.uid,
    a.county_id,
    a.event_name,
    t.brand_name
from
-- 流量
(select
    dt,
    event_time,
    if(length(device_id)>0,device_id,user_id) as uid,
    cast(county_id as int) as county_id,
    event_name,
    activity_id
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and '2024-06-16'
    and event_name in ('HomePage_takeout_Activity_ex','HomePage_takeout_Activity_Click','Takeout_Activity_Detail_View','Takeout_Grab_Click','Homepage_Search_Click','Homepage_Search_Activity_Ex','Homepage_Search_Result_Click')
    and (length(device_id)>1 or length(user_id)>1)
    and length(county_id)=6 -- 区县有值
    and substr(county_id,1,4)='3101' -- 上海)
) a
inner join t 
    on a.activity_id=t.store_promotion_id
),

-- 城市pv uv
t3 as (
select 
    dt as `统计日期`,
    t1.county_name as `区县`,
    count(distinct a.uid) as uv
from 
-- 流量
(select
    dt,
    cast(county_id as int) as county_id,
    if(length(device_id)>0,device_id,user_id) as uid
from ods.ods_hive_traffic_event_log
where dt between '2024-06-01' and '2024-06-16'
    and (length(device_id)>1 or length(user_id)>1)
    and length(county_id)=6 -- 区县有值
    and substr(county_id,1,4)='3101' -- 上海
group by 1,2,3
) a
inner join t1 on a.county_id=t1.county_id
group by 1,2
),

-- 转化漏斗
t4 as (
select 
    a.dt as `统计日期`,
    t1.county_name as `区县`,
    a.brand_name as `品牌`,
    count(*) as `首页活动曝光量`,
    count(distinct a.uid) as `首页活动曝光UV`,
    count(if(b.uid is not null,a.uid,null)) as `首页活动点击量`,
    count(distinct if(b.uid is not null,a.uid,null)) as `首页活动点击用户量`,
    count(if(c.uid is not null,a.uid,null)) as `首页活动详情页PV`,
    count(distinct if(c.uid is not null,a.uid,null)) as `首页活动详情页UV`,
    count(if(d.uid is not null,a.uid,null)) as `首页抢单点击量`,
    count(distinct if(d.uid is not null,a.uid,null)) as `首页抢单点击用户量`
from t2 a
left join t2 b
    on a.dt=b.dt
        and a.uid=b.uid
        and a.county_id=b.county_id
        and a.brand_name=b.brand_name
        and b.event_name='HomePage_takeout_Activity_Click' -- 首页活动点击
left join t2 c
    on b.dt=c.dt
        and b.uid=c.uid
        and b.county_id=c.county_id
        and b.brand_name=c.brand_name
        and c.event_name='Takeout_Activity_Detail_View' -- 外卖活动详情浏览
left join t2 d
    on c.dt=d.dt
        and c.uid=d.uid
        and c.county_id=d.county_id
        and c.brand_name=d.brand_name
        and d.event_name='Takeout_Grab_Click' -- 抢单点击
left join t1 on a.county_id=t1.county_id
where a.event_name='HomePage_takeout_Activity_ex' -- 首页活动曝光
group by 1,2,3
),

-- 有效订单量
t5 as (
select 
    concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) as `下单日期`,
    b.county_name as `区县`,
    t.brand_name as `品牌名称`,
    count(a.order_id) as order_num
from dwd.dwd_hive_silkworm_promotion_order a
-- 城市区县
left join t1 b
    on a.county_id=b.county_id
inner join t
    on a.store_promotion_id=t.store_promotion_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-06-01' and date_sub(current_date,1)
    and a.store_promotion_id>0 -- 自营
    and a.city_id=3101
group by 1,2,3
),


-- 活动名额
t6 as (
select 
    dat as `发布日期`,
    county_name as `区县`,
    brand_name as `品牌名称`,
    sum(tot_promotion_quota) as `活动名额`
from t
where county_name is not null
group by 1,2,3),


-- 搜索量
t7 as (
select 
    a.dt as `统计日期`,
    t1.county_name as `区县`,
    a.brand_name as `品牌`,
    count(*) as `搜索量`,
    count(distinct a.uid) as `搜索UV`
from t2 a
left join t1 on a.county_id=t1.county_id
where a.event_name='Homepage_Search_Click' -- 搜索点击
group by 1,2,3
),


-- 搜索转化漏斗
-- 'Homepage_Search_Activity_Ex','Homepage_Search_Result_Click'
t8 as (
select 
    a.dt as `统计日期`,
    t1.county_name as `区县`,
    a.brand_name as `品牌`,
    count(*) as `搜索曝光量`,
    count(distinct a.uid) as `搜索曝光UV`,
    count(if(b.uid is not null,a.uid,null)) as `搜索结果点击量`,
    count(distinct if(b.uid is not null,a.uid,null)) as `搜索结果点击用户量`,
    count(if(c.uid is not null,a.uid,null)) as `搜索抢单点击量`,
    count(distinct if(c.uid is not null,a.uid,null)) as `搜索抢单点击用户量`
from t2 a
left join t2 b
    on a.dt=b.dt
        and a.uid=b.uid
        and a.county_id=b.county_id
        and a.brand_name=b.brand_name
        and b.event_name='Homepage_Search_Result_Click' -- 搜索结果点击
left join t2 c
    on b.dt=c.dt
        and b.uid=c.uid
        and b.county_id=c.county_id
        and b.brand_name=c.brand_name
        and c.event_name='Takeout_Grab_Click' -- 抢单点击
left join t1 on a.county_id=t1.county_id
where a.event_name='Homepage_Search_Activity_Ex' -- 搜索曝光
group by 1,2,3
)



-- 聚合数据

select
    t6.`发布日期`,
    '上海' as `城市`,
    t6.`区县`,
    t6.`品牌名称`,
    t6.`活动名额`,
    t3.uv as `城市UV`,
    t4.`首页活动曝光量`,
    t4.`首页活动曝光UV`,
    t4.`首页活动点击量`,
    t4.`首页活动点击用户量`,
    t4.`首页活动详情页PV`,
    t4.`首页活动详情页UV`,
    t4.`首页抢单点击量`,
    t4.`首页抢单点击用户量`,
    t7.`搜索量`,
    t7.`搜索UV`,
    t8.`搜索曝光量`,
    t8.`搜索曝光UV`,
    t8.`搜索结果点击量`,
    t8.`搜索结果点击用户量`,
    t8.`搜索抢单点击量`,
    t8.`搜索抢单点击用户量`,
    t5.order_num as `自营有效订单量`
from t6
left join t3
    on t6.`发布日期`=t3.`统计日期`
        and t6.`区县`=t3.`区县`
left join t4
    on t6.`发布日期`=t4.`统计日期`
        and t6.`区县`=t4.`区县`
        and t6.`品牌名称`=t4.`品牌`
left join t5
    on t6.`发布日期`=t5.`下单日期`
        and t6.`区县`=t5.`区县`
        and t6.`品牌名称`=t5.`品牌名称`
left join t7
    on t6.`发布日期`=t7.`统计日期`
        and t6.`区县`=t7.`区县`
        and t6.`品牌名称`=t7.`品牌`
left join t8
    on t6.`发布日期`=t8.`统计日期`
        and t6.`区县`=t8.`区县`
        and t6.`品牌名称`=t8.`品牌`








