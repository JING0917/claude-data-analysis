-- 解开每日访问登录用户
select unnest_bitmap as user_id from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_ename in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View','Store_Details_View')
group by 1
limit 100;

-- 登录用户 dau
select dt,bitmap_union_count(user_ids) as cnt from dwd.dwd_sr_traffic_viewuser_d where dt=date_sub(current_date(),interval 1 day) group by 1;

-- 登录用户 分端dau
select dt,platform_name,bitmap_union_count(user_ids) as cnt from dwd.dwd_sr_traffic_viewuser_d where dt>=date_sub(current_date(),interval 4 day) group by 1,2;


-- distance 是否有单位

select event_name,distance,version from ods.ods_sr_traffic_event_log 
where dt=current_date()
    and distance regexp 'M|m'
    and platform_name in ('Android','iOS')
    and version regexp '2.12.3'
    and hour(event_name)>=15
limit 10
;

-- DAU
select
    date_format(dt,'%Y-%m-%d') as dat,
    bitmap_union_count(user_ids) as dau
from dwd.dwd_sr_traffic_viewuser_d
where date_format(dt,'%Y-%m-%d') between '2024-08-10' and date_sub(current_date(),interval 1 day)
group by 1;


select
    statistics_date,count(distinct user_id) as dau
from dws.dws_sr_traffic_user_d
where statistics_date between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1;



-- 日均UV

SELECT `平台名称`,
       avg(dau) `月日均UV`
FROM (
-- dau
SELECT date_format(dt,'%Y-%m-%d') AS dat,
       CASE
           WHEN platform_name IN ('Android',
                                  'iOS') THEN 'App'
           ELSE platform_name
       END `平台名称`,
       bitmap_union_count(user_ids) AS dau
FROM dwd.dwd_sr_traffic_viewuser_d
WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
GROUP BY 1,
         2) a
GROUP BY 1;



-- 日均UV
SELECT `平台名称`,
       avg(uv) avg_uv
FROM (
-- 会员用户uv
SELECT a.dat,
       `平台名称`,
       count(DISTINCT if(user_level IS NOT NULL,a.user_id,NULL)) uv
FROM
-- 每日访问用户
  (SELECT date_format(dt,'%Y-%m-%d') AS dat,
          CASE WHEN platform_name IN ('Android',
                                     'iOS') THEN 'App' ELSE platform_name END `平台名称`,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
   GROUP BY 1,
            2,
            3) a

LEFT JOIN dim.dim_silkworm_member b ON a.user_id=b.user_id
GROUP BY 1,
         2) b
GROUP BY 1;


-- 会员页日均UV
SELECT `平台名称`,
       avg(dau) `月日均UV`
FROM (
-- dau
SELECT date_format(dt,'%Y-%m-%d') AS dat,
       CASE
           WHEN platform_name IN ('Android',
                                  'iOS') THEN 'App'
           ELSE platform_name
       END `平台名称`,
       bitmap_union_count(user_ids) AS dau
FROM dwd.dwd_sr_traffic_viewuser_d
WHERE date_format(dt,'%Y-%m-%d') BETWEEN '2025-03-01' AND '2025-03-31'
and event_ename regexp '^Member_'
GROUP BY 1,
         2) a
GROUP BY 1;


============ 统计下单流程用户量
show create table dwd.dwd_sr_order_promotion_order;

select statistics_date,
    count(*) as cnt,
    count(distinct user_id) as uv,
    count(distinct if(takeaway_detailpage_pv>0,user_id,null)) as `店铺活动详情页浏览用户量`,
    -- sum(homepage_pv) as sy_pv,
    count(distinct if(takeaway_graborder_button_click_num>0,user_id,null)) as `抢单按钮点击用户量`,
    -- sum(homepage_pv) as td_pv
    count(distinct if(takeaway_baoming_button_click_num>0,user_id,null)) as `报名按钮点击用户量`
from dws.dws_sr_traffic_user_d
where cast(statistics_date as string) between '2024-09-14' and '2024-10-14'
group by 1;


set query_timeout=12000;

-- 以下3个行为，
-- 活动详情页浏览
select
    a.dt,
    a.platform_name,
    a.version,
    count(distinct a.user_id) as `店铺活动详情页浏览用户量`,
    count(distinct if(b.user_id is not null,a.user_id,null)) as `抢单按钮点击用户量`,
    count(distinct if(c.user_id is not null,a.user_id,null)) as `报名按钮点击用户量`
from
-- 活动详情页浏览
(select
    dt,
    platform_name,
    version,
    user_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-10-15' and '2024-10-15'
    and event_name='Takeout_Activity_Detail_View'
    -- and platform_name='iOS'
group by 1,2,3,4) a
left join
-- 活动详情页抢单按钮点击
(select
    dt,
    platform_name,
    version,
    user_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-10-15' and '2024-10-15'
    and event_name='Takeout_Grab_Click'
    -- and platform_name='iOS'
group by 1,2,3,4) b on a.dt=b.dt and a.platform_name=b.platform_name and a.version=b.version and a.user_id=b.user_id
left join
-- 报名按钮点击
(select
    dt,
    platform_name,
    version,
    user_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-10-15' and '2024-10-15'
    and event_name='Takeout_Signup_Click'
    -- and platform_name='iOS'
group by 1,2,3,4) c on a.dt=c.dt and a.platform_name=c.platform_name and a.version=c.version and a.user_id=c.user_id
group by 1,2,3
;



set query_timeout=12000;

-- 以下3个行为，
select
    dt,
    platform_name,
    -- version,
    -- count(distinct if(event_name='Takeout_Activity_Detail_View_Duration',user_id,null)) as `店铺活动详情页浏览时长用户量`,
    count(distinct if(event_name='Takeout_Activity_Detail_View',user_id,null)) as `店铺活动详情页浏览用户量`,
    count(distinct if(event_name='Takeout_Grab_Click',user_id,null)) as `抢单按钮点击用户量`,
    count(distinct if(event_name='Takeout_Signup_Click',user_id,null)) as `报名按钮点击用户量`
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-20' and '2024-11-24'
    and event_name in ('Takeout_Activity_Detail_View','Takeout_Grab_Click','Takeout_Signup_Click')
    -- and platform_name='iOS'
    and version regexp '2.12.4'
group by 1,2
;


-- 埋点上报错误日志
select 
    dt,
    platform_name,
    count(*) as error_num
-- *
-- dt,platform_name,error,value
from ods.ods_sr_traffic_event_log_error
where cast(dt as string) between '2024-10-17' and '2024-10-19'
    -- and length(value)<=2000
group by 1,2
;

-- 埋点上报错误日志
select 
    dt,
    platform_name,
    count(*) as error_num
from ods.ods_sr_traffic_event_log_error
where cast(dt as string) between '2024-09-27' and '2024-09-2930'
group by 1,2
;

-- 错误日志
select 
    -- *
    -- dt,
    -- platform_name,
    error,
    count(1) as cnt
from ods.ods_sr_traffic_event_log_error
where cast(dt as string) between '2024-09-27' and '2024-09-27'
    -- and length(value)<=2000
    -- and platform_name='Android'
group by 1
;



select * from ods.ods_sr_traffic_event_log_error where dt=current_date() limit 10;

-- 非登录用户占比17%
select 
    dt,
    count(distinct user_id) as totnum,
    count(distinct if(user_id regexp '^[0-9]{1,9}$',user_id,null)) as normal_usernum
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-24' and '2024-09-26'
group by 1
;

-- 非登录用户，通过rcs关联得到用户ID
-- device_id长度=62
set query_timeout=12000;

select
    -- a.dt,a.user_id,b.did,b.silk_id
    a.dt,
    count(distinct a.device_id) as `待转译用户量`,
    count(distinct if(b.did is not null,b.silk_id,null)) as `转译用户量`
from
(select 
    dt,
    device_id
    -- length(user_id) as len_num
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-20' and '2024-09-26'
    and user_id not regexp '^[0-9]{1,9}$'
    and length(device_id)=62
group by 1,2) a
left join (
    select
        silk_id,
        box_id as did
    from dim.dim_user_rcs
    union
    select
        silk_id,
        html_box_id as did
    from dim.dim_user_rcs
    union
    select
        silk_id,
        mini_box_id as did
    from dim.dim_user_rcs
) b on a.device_id=b.did
group by 1
;

show create table dim.dim_user_rcs;

select * from dim.dim_user_rcs limit 10;


-- -- 长度8
-- select length(cast(store_promotion_id as string))
-- from dwd.dwd_sr_store_promotion
-- where dt between '2024-09-01' and '2024-09-10'
--                 and begin_date between '2024-09-01' and '2024-09-10'
--                 and status in (1,4,5)
-- group by 1

set query_timeout=120000;
select
    event_name
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-10-15' and '2024-10-20'
    -- and event_name in ('Takeout_Activity_Detail_View','Takeout_Grab_Click','Takeout_Signup_Click')
    -- and platform_name='iOS'
group by 1
;


-- 经纬度缺失比例
set query_timeout=12000;

select
dt,
platform_name,
count(*) as tot,
sum(if(latitude is null or latitude='',1,0)) as latitude_cnt,
sum(if(longitude is null or longitude='',1,0)) as longitude_cnt
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-20' and '2024-11-26'
group by 1,2
;




-- ======================================
show create table ods.ods_sr_traffic_event_log;

select dt,count(*) as cnt from ods.ods_sr_traffic_event_log group by 1;

-- 对每个事件做问题排查
select 
    dt
    ,count(*) as tot -- 数据量
    ,sum(if(user_id is null or user_id='',1,0)) as null_user_num
    ,sum(if(activity_id is null or activity_id='',1,0)) as null_activity_num
    ,sum(if(activity_id regexp '^[1-9]{1,8}$',1,0)) as notnull_activity_num
    -- ,sum(if(activity_id not regexp '^[1-9]{1,8}$',1,0)) as unnormal_activity_num
    -- ,count(distinct user_id) as uv
    ,sum(if(order_id is null or order_id='',1,0)) as unnormal_num
    -- ,sum(if(upload_method is null or upload_method='',1,0)) as unnormal_num
    -- ,sum(if(location is null or location='',1,0)) as unnormal_num
from ods.ods_sr_traffic_event_log
where dt between '2024-08-12' and '2024-09-10' 
    and event_name='BigBrand_takeout_Activity_Click'
group by 1
;

-- 分端
select 
    platform_name
    ,count(*) as tot -- 数据量
    ,sum(if(user_id is null or user_id='',1,0)) as null_user_num
    ,sum(if(activity_id is null or activity_id='',1,0)) as null_activity_num
    -- ,sum(if(activity_id regexp '^[1-9]{1,8}$',1,0)) as notnull_activity_num
    -- ,sum(if(activity_id not regexp '^[1-9]{1,8}$',1,0)) as unnormal_activity_num
    ,sum(if(length(activity_id)=8,1,0)) as notnull_activity_num
    ,sum(if(length(activity_id)<>8,1,0)) as unnormal_activity_num
    -- ,count(distinct user_id) as uv
    -- ,sum(if(order_id is null or order_id='',1,0)) as unnormal_num
    -- ,sum(if(upload_method is null or upload_method='',1,0)) as unnormal_num
    -- ,sum(if(location is null or location='',1,0)) as unnormal_num
from ods.ods_sr_traffic_event_log
where dt ='2024-09-10' 
    and event_name='HomePage_takeout_Activity_ex'
group by 1
;

-- 查看明细
select 
    platform_name
    ,user_id
    ,activity_id
from ods.ods_sr_traffic_event_log
where dt ='2024-09-10' 
    and event_name='HomePage_takeout_Activity_ex'
    -- and activity_id not regexp '^[1-9]{1,8}$'
    and platform_name='Android'
    and length(activity_id)<>8
    -- and activity_id regexp '^[a-zA-Z].*'
    -- and (length(user_id)<=6 or length(user_id)>=10)
    -- and (activity_id is null or activity_id='')
group by 1,2,3
limit 100
;

=================
-- DAU
select 
    dt,count(distinct user_id) as uv
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-08-31' and '2024-09-22' 
group by 1;

-- boss渠道拉新流量统计
select
    cast(dt as string) as `统计日期`,
    -- sum(if(event_name='Login_Button_Click',1,0)) as `点击量`,
    -- count(distinct if(event_name='Login_Button_Click',user_id,null)) as `点击uv`
    sum(if(event_name='Boss_Welcome_Page_ex',1,0)) as `欢迎页pv`,
    count(distinct if(event_name='Boss_Welcome_Page_ex',user_id,null)) as `欢迎页uv`,
    sum(if(event_name='Boss_HomePage_ex',1,0)) as `boss拉新主页pv`,
    count(distinct if(event_name='Boss_HomePage_ex',user_id,null)) as `boss拉新主页uv`,
    sum(if(event_name='Boss_to_TakeOut_click',1,0)) as `去点餐按钮点击量`,
    count(distinct if(event_name='Boss_to_TakeOut_click',user_id,null)) as `去点餐按钮点击用户量`
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-01' and '2024-10-09' 
    and event_name in (
        'Boss_Welcome_Page_ex','Boss_HomePage_ex','Boss_to_TakeOut_click'
group by 1
;

-- boss渠道下单用户量
select
    count(a.user_id) as `boss渠道去点餐按钮点击用户量`,
    count(distinct if(b.accu_valid_order_num>0,a.user_id,null)) as `boss渠道完单用户量`
from
(select
    cast(user_id as int) as user_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-01' and '2024-10-09' 
    and event_name='Boss_to_TakeOut_click'
    and user_id regexp '^[0-9]{1,9}$'
group by 1) a left join dim.dim_silkworm_user b on a.user_id=b.user_id
;

=============
=============== 搜索日数据
show create table dwd.dwd_sr_traffic_search_log;


select search_date,count(1) as cnt from dwd.dwd_sr_traffic_search_log group by 1;

-- 搜索词日均数据
select
    platform_name,
    -- keywords,
    avg(search_num) as `日均搜索量`,
    avg(search_user_num) as `日均搜索用户量`,
    avg(search_expose_num) as `日均搜索曝光量`,
    avg(search_result_click_num) as `日均搜索结果点击量`,
    avg(search_result_click_user_num) as `日均搜索结果点击用户量`
    ,avg(bg_promotion_num) as `搜索曝光活动数`
    ,avg(click_promotion_num) as `搜索点击活动数`
from
-- 搜索词日数据
(select
    search_date,
    -- platform_name,
    -- keywords,
    sum(search_num) as search_num, -- 搜索量
    count(distinct user_id) as search_user_num, -- 搜索用户量
    sum(search_expose_num) as search_expose_num, -- 搜索曝光量
    sum(search_result_click_num) as search_result_click_num, -- 搜索结果点击量
    count(distinct if(search_result_click_num>0,user_id,null)) as search_result_click_user_num --搜索结果点击用户量
    ,count(distinct if(search_expose_num>0,activity_id,null)) as bg_promotion_num -- 搜索曝光活动数
    ,count(distinct if(search_result_click_num>0,activity_id,null)) as click_promotion_num -- 搜索点击活动数
from dwd.dwd_sr_traffic_search_log
where search_date between '2024-08-12' and '2024-10-10'
    and entrance_name='主页'
    -- and platform_name regexp '5'
group by 1
) a
group by 1
-- order by `日均搜索量` desc
;


select
    search_date,
    activity_id, -- 店铺活动ID
    sum(search_expose_num) as search_expose_num -- 搜索曝光量
from dwd.dwd_sr_traffic_search_user_d
where search_date between '2024-08-12' and '2024-10-10'
    and entrance_name='主页'
group by 1,2




=============== 到店口令
show create table ods.ods_sr_traffic_event_log;

select * from ods.ods_sr_traffic_event_log where dt=date_sub(current_date(),interval 1 day) limit 10;

set query_timeout=12000;

-- 口令搜索用户
with t1 as (
select
    dt,
    -- event_name,
    event_time,
    platform_name,
    watchword_content,
    -- count(distinct user_id) as `命中用户量`,
    -- count(1) as `命中次数`
    cast(user_id as int) as user_id,
    -- user_id,
    -- watchword_content,
    count(1) as cnt
from ods.ods_sr_traffic_event_log
where event_name='Search_Command_Click'    -- 'Search_Command_Click'
    and cast(dt as string) between '2024-10-14' and '2024-10-14'
    -- and user_id regexp '^[0-9]{1,9}$'
    and watchword_content regexp '十月吃顿漂亮饭'
    -- and keywords regexp '吃顿漂亮饭'
group by 1,2,3,4,5
)


select
    watchword_content,
    count(distinct t1.user_id) as `口令触发用户量`,
    sum(t1.cnt) as `口令触发次数`,
    count(distinct if(a.xiaohongshu_auth_first_time is not null or a.dp_auth_first_time is not null,a.user_id,null)) as `口令命中已完成认证用户量`,
    count(distinct if(a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time,a.user_id,null)) as `口令触发后完成认证用户量`
from t1
left join dim.dim_silkworm_explore_daren_cleanse a 
on t1.user_id=a.user_id
    and (substr(a.xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
        or substr(a.dp_auth_first_time,1,10)<>'1970-01-01'
    )
group by 1
;



-- 探店下单流程页面曝光用户量
select
    dt,
    count(distinct if(event_name='StoreDiscovery_OrderProcess_Ex',user_id,null)) as td_uv,
    count(distinct if(event_name='Charity_OrderProcess_Ex',user_id,null)) as gy_uv
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 3 day) and current_date()
    and event_name in ('StoreDiscovery_OrderProcess_Ex','Charity_OrderProcess_Ex')
    and user_id regexp '^[0-9]{1,9}$'
group by 1
;


====================== 探店转化漏斗
StoreDiscovery_Activity_Ex -- 探店主页活动曝光
StoreDiscovery_Activity_Click -- 探店活动点击
StoreDiscovery_Activity_Details_View -- 探店活动详情页浏览
StoreDiscovery_Activity_Details_GrabOrder_Click -- 探店活动详情立即抢单点击
StoreDiscovery_OrderProcess_Verification_Click -- 探店订单流程核销点击

show create table dwd.dwd_sr_silkworm_explore_order;
show create table ods.ods_sr_traffic_event_log;

set query_timeout=12000;

-- 探店主页活动转化漏斗
select
    a.dt as `统计日期`,
    count(distinct a.user_id) as `探店主页活动曝光用户量`,
    count(distinct if(b.user_id is not null,a.user_id,null)) as `探店主页活动点击用户量`,
    count(distinct if(c.user_id is not null,a.user_id,null)) as `探店活动详情页浏览用户量`,
    count(distinct if(d.user_id is not null,a.user_id,null)) as `探店活动详情立即抢单点击用户量`,
    count(distinct if(e.user_id is not null,a.user_id,null)) as `报名按钮点击用户量`,
    count(distinct if(f.user_id is not null,a.user_id,null)) as `核销用户量`
from
-- 探店主页曝光
(select
    dt,
    cast(user_id as int) as user_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-08-12' and '2024-09-30'
    and event_name='StoreDiscovery_Activity_Ex'
group by 1,2
    ) a
left join
-- 探店主页活动点击
(select
    dt,
    cast(user_id as int) as user_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-08-12' and '2024-09-30'
    and event_name='StoreDiscovery_Activity_Click'
group by 1,2
    ) b on a.dt=b.dt and a.user_id=b.user_id
left join
-- 探店活动详情页浏览
(select
    dt,
    cast(user_id as int) as user_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-08-12' and '2024-09-30'
    and event_name='StoreDiscovery_Activity_Details_View'
group by 1,2
    ) c on b.dt=c.dt and b.user_id=c.user_id
left join
-- 探店活动详情页抢单点击
(select
    dt,
    cast(user_id as int) as user_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-08-12' and '2024-09-30'
    and event_name='StoreDiscovery_Activity_Details_GrabOrder_Click'
group by 1,2
    ) d on c.dt=d.dt and c.user_id=d.user_id
left join
-- 探店报名点击
(select
    dt,
    cast(user_id as int) as user_id
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-08-12' and '2024-09-30'
    and event_name='StoreDiscovery_OrderProcess_Verification_Click'
group by 1,2
    ) e on d.dt=e.dt and e.user_id=d.user_id
left join 
-- 订单核销
(select  
    user_id
from dwd.dwd_sr_silkworm_explore_order
where cast(date(dt) as string)>='2024-08-12'
    and store_name not regexp '测试'
    and promotion_type in (1,4) 
    and status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33)
group by 1) f
on e.user_id=f.user_id
group by 1;


========== 首页筛选按钮点击
set query_timeout=12000;

select
    dt `统计日期`,
    count(*) as `点击量`,
    count(distinct user_id) `点击用户量`
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-14' and '2024-10-14'
    and event_name='HomePage_Activity_Filter_Click' -- 主页活动筛选点击
    -- and event_name='HomePage_View'
    -- and promotion_platform_name is not null
    -- and promotion_platform_name<>''
    and meal_time is not null
    and meal_time<>''
group by 1;


select
first_explode_order_date,
count(1) as cnt
from dim.dim_silkworm_explore_daren_cleanse
where first_explode_order_date is not null
    and status=1
group by 1;

select
statisticsdate,
first_explore_order_user_num,
acc_explore_order_user_num
from dws.dws_sr_order_explore_dashboard_county_d
where platform_name='全部'
    and city_name='全部'
    and county_name='全部'
;



================== 口令搜索用户属性
set query_timeout=12000;

-- 口令搜索用户
with t1 as (
select
    dt,
    -- event_name,
    event_time,
    platform_name,
    watchword_content,
    -- count(distinct user_id) as `命中用户量`,
    -- count(1) as `命中次数`
    cast(user_id as int) as user_id,
    -- user_id,
    -- watchword_content,
    count(1) as cnt
from ods.ods_sr_traffic_event_log
where event_name='Search_Command_Click'    -- 'Search_Command_Click'
    and cast(dt as string) between '2024-11-11' and '2024-11-13'
    -- and user_id regexp '^[0-9]{1,9}$'
    and watchword_content regexp '秋天一起来探店'
    -- and keywords regexp '吃顿漂亮饭'
group by 1,2,3,4,5
)


select
    watchword_content,
    count(distinct t1.user_id) as `口令触发用户量`,
    count(distinct if(a.xiaohongshu_auth_first_time is not null or a.dp_auth_first_time is not null,a.user_id,null)) as `口令命中已完成认证用户量`,
    count(distinct if((a.xiaohongshu_auth_first_time is not null or a.dp_auth_first_time is not null)
     and a.xiaohongshu_fans_num>=200,a.user_id,null)) as `口令命中已完成认证小红书千粉用户量`,
    count(distinct if((a.xiaohongshu_auth_first_time is not null or a.dp_auth_first_time is not null)
     and a.dp_user_lvl>=5,a.user_id,null)) as `口令命中已完成认证点评5+级用户量`,
    count(distinct if((a.xiaohongshu_auth_first_time is not null or a.dp_auth_first_time is not null)
     and a.dp_user_lvl>=5 and a.xiaohongshu_fans_num>=200,a.user_id,null)) as `口令命中已完成认证千粉且点评5+级用户量`,

    count(distinct if(a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time,a.user_id,null)) as `口令触发后完成认证用户量`,
    count(distinct if((a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time) and a.xiaohongshu_fans_num>=200,a.user_id,null)) as `口令触发后完成认证千粉用户量`,
    count(distinct if((a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time) and a.dp_user_lvl>=5,a.user_id,null)) as `口令触发后完成认证点评5+级用户量`,
    count(distinct if((a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time) 
    and a.xiaohongshu_fans_num>=200 and a.dp_user_lvl>=5,a.user_id,null)) as `口令触发后完成认证千粉且点评5+级用户量`
from t1
left join dim.dim_silkworm_explore_daren_cleanse a 
on t1.user_id=a.user_id
    and (substr(a.xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
        or substr(a.dp_auth_first_time,1,10)<>'1970-01-01'
    )
group by 1
;

-- 用户ID
select
    -- a.user_id as `口令触发后完成认证千粉且点评5+级用户ID`
    a.user_id as `口令触发后完成认证点评5+级用户ID`
from t1
left join dim.dim_silkworm_explore_daren_cleanse a 
on t1.user_id=a.user_id
    and (substr(a.xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
        or substr(a.dp_auth_first_time,1,10)<>'1970-01-01'
    )
-- where (a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time)
--     and a.xiaohongshu_fans_num>=1000 
--     and a.dp_user_lvl>=5 -- 口令触发后完成认证千粉且点评5+级用户 
where (a.xiaohongshu_auth_first_time>t1.event_time or a.dp_auth_first_time>t1.event_time)
    and a.dp_user_lvl>=5 -- 口令触发后完成认证点评5+级用户
group by 1
;


select
-- xiaohongshu_fans_num,
dp_user_lvl,
count(1) as cnt
from dim.dim_silkworm_explore_daren_cleanse
group by 1;

======================================

-- 统计指定时间范围内，探店流量数据
set query_timeout=12000;

select
    '1021-1027' as `统计周期`,
    count(distinct if(event_name='StoreDiscovery_Homepage_View',user_id,null)) as `探店主页UV`
    ,count(if(event_name='StoreDiscovery_Homepage_View',user_id,null)) as `探店主页PV`
    ,count(distinct if(event_name='StoreDiscovery_Activity_Details_View',user_id,null)) as `探店活动详情页页UV`
    ,count(if(event_name='StoreDiscovery_Activity_Details_View',user_id,null)) as `探店活动详情页PV`
    ,count(distinct if(event_name='StoreDiscovery_Activity_Details_GrabOrder_Click',user_id,null)) as `探店活动详情立即抢单点击UV`
    ,count(if(event_name='StoreDiscovery_Activity_Details_GrabOrder_Click',user_id,null)) as `探店活动详情立即抢单点击量`
    ,count(distinct if(event_name='StoreDiscovery_Activity_Details_Registration_Click',user_id,null)) as `探店活动详情确认报名点击UV`
    ,count(if(event_name='StoreDiscovery_Activity_Details_Registration_Click',user_id,null)) as `探店活动详情确认报名点击量`
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-10-21' and '2024-10-27'
    and event_name in (
        'StoreDiscovery_Homepage_View'
    ,'StoreDiscovery_Activity_Details_View'
    ,'StoreDiscovery_Activity_Details_GrabOrder_Click'
    ,'StoreDiscovery_Activity_Details_Registration_Click'
    )
    and substr(county_id,1,4)='3301' -- 杭州
group by 1
;



========= 搜索日志
select * from ods.ods_sr_traffic_event_log 
where cast(dt as string)='2024-10-28'
    and user_id='22477024'
    and keywords='元小'
;

set query_timeout=12000;

-- 主页入口搜索
select dt,
    sum(if(event_name='Homepage_Search_Click',1,0)) `搜索量`,
    count(distinct if(event_name='Homepage_Search_Click',user_id,null)) `搜索用户量`,
    sum(if(event_name='Homepage_Search_Activity_Ex',1,0)) `搜索曝光量`,
    count(distinct if(event_name='Homepage_Search_Activity_Ex',user_id,null)) `搜索曝光用户量`,
    sum(if(event_name='Homepage_Search_Result_Click',1,0)) `搜索结果点击量`,
    count(distinct if(event_name='Homepage_Search_Result_Click',user_id,null)) `搜索结果点击用户量`
from ods.ods_sr_traffic_event_log
where dt>='2024-10-28'
    and event_name in ('Homepage_Search_Click','Homepage_Search_Activity_Ex','Homepage_Search_Result_Click')
group by 1;



show create table dws.dws_sr_traffic_search_user_d;

select * from dws.dws_sr_traffic_search_user_d
where search_date='2024-10-28'
    and keywords='元小'
    and user_id='22477024'
;




=======搜索量

select keywords,count(1) as cnt from ods.ods_sr_traffic_event_log
where dt between '2024-12-01' and '2024-12-19'
    and event_name='Homepage_Search_Click'
group by 1
having count(1)>=5;


====== 砍价流量
-- 杭州砍价流量统计
select
    dt `统计日期`,
    '杭州' as `城市`,
    sum(if(event_name='StoreDiscovery_Homepage_View',1,0)) `探店主页PV`,
    count(distinct if(event_name='StoreDiscovery_Homepage_View',user_id,null)) `探店主页UV`,
    sum(if(event_name='Bargain_Homepage_Ex',1,0)) `砍价主页PV`,
    count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) `砍价主页UV`,
    sum(if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',1,0)) `砍价活动详情页PV`,
    count(distinct if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',user_id,null)) `砍价活动详情页UV`,  
    sum(if(event_name='Store_Details_View',1,0)) `店铺详情页PV`,
    count(distinct if(event_name='Store_Details_View',user_id,null)) `店铺详情页UV`,
    sum(if(event_name='Bargain_Share_Button_Click',1,0)) `砍价分享按钮点击量`,
    count(distinct if(event_name='Bargain_Share_Button_Click',user_id,null)) `砍价分享按钮点击UV`,
    -- sum(if(event_name='Bargain_Share_Button_Click' and share_id='微信好友',1,0)) `砍价微信好友分享按钮点击量`,
    -- count(distinct if(event_name='Bargain_Share_Button_Click' and share_id='微信好友',user_id,null)) `砍价微信好友分享按钮点击UV`,
    -- sum(if(event_name='Bargain_Share_Button_Click' and share_id='朋友圈',1,0)) `砍价朋友圈分享按钮点击量`,
    -- count(distinct if(event_name='Bargain_Share_Button_Click' and share_id='朋友圈',user_id,null)) `砍价朋友圈分享按钮点击UV`,
    -- sum(if(event_name='Bargain_Share_Button_Click' and share_id='海报',1,0)) `砍价海报分享按钮点击量`,
    -- count(distinct if(event_name='Bargain_Share_Button_Click' and share_id='海报',user_id,null)) `砍价海报分享按钮点击UV`,
    sum(if(event_name='Bargain_Activity_Details_Share_Ex',1,0)) `砍价活动详情页分享弹窗曝光量`,
    count(distinct if(event_name='Bargain_Activity_Details_Share_Ex',user_id,null)) `砍价活动详情页分享弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Ex',1,0)) `邀请砍价弹窗曝光量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Ex',user_id,null)) `邀请砍价弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Click',1,0)) `邀请砍价弹窗点击量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Click',user_id,null)) `邀请砍价弹窗点击UV`
from ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 2 day)
    and substr(county_id,1,4)='3301' -- 杭州
    and event_name in ('StoreDiscovery_Homepage_View',
        'Bargain_Homepage_Ex',
        'StoreDiscovery_Activity_Details_Ex',
        'Bargain_Share_Button_Click',
        'Bargain_Activity_Details_Share_Ex',
        'Invite_Bargain_Windows_Ex',
        'Invite_Bargain_Windows_Click',
        'Store_Details_View')
group by 1,2;


select
    *
from ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 2 day)
    and substr(county_id,1,4)='3301' -- 杭州
    and event_name='Bargain_Share_Button_Click';


===================

=================== 测试环境埋点日志
select
    date(event_time) as dt,
    count(1)
from
    (select 
        from_unixtime(cast(element_at(BaseInfoHeader, 'time') as bigint) / 1000) AS event_time,
        element_at(data,'event_id') as event_name,
        element_at(BaseInfoHeader,'platform_type') as platform_name,
        element_at(BaseInfoHeader,'distinct_id') as user_id,
        element_at(BaseInfoHeader,'X-Version') as version,
        element_at(BaseInfoHeader,'X-Citycode') as county_id,
        element_at(BaseInfoHeader,'model') as model,
        element_at(BaseInfoHeader,'device_id') as device_id
    from ods.ods_sr_event_log_test
    where dt between date_sub(current_date(),interval 1 day) and current_date()
    ) a
group by 1;




select
    *
from
    (select 
        element_at(BaseInfoHeader, 'dt') as event_time,
        element_at(data,'event_id') as event_name,
        element_at(BaseInfoHeader,'platform_type') as platform_name,
        element_at(BaseInfoHeader,'distinct_id') as user_id,
        element_at(BaseInfoHeader,'X-Version') as version,
        element_at(BaseInfoHeader,'X-Citycode') as county_id,
        element_at(BaseInfoHeader,'model') as model,
        element_at(BaseInfoHeader,'device_id') as device_id
    from ods.ods_sr_event_log_test
    where str_to_date(dt,'%Y-%m-%d') between date_sub(current_date(),interval 5 day) and current_date()
    ) a
where date(event_time) between date_sub(current_date(),interval 1 day) and current_date()
;




============ 用户访问天数
drop view if exists t1;
create view if not exists t1 (
dt,user_id
) as (
select dt,
    unnest_bitmap as user_id 
from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1,2
);




select
    min(days) as `最小值`,
    PERCENTILE_CONT(days,0.1) as `10分位值`,
    PERCENTILE_CONT(days,0.2) as `20分位值`,
    PERCENTILE_CONT(days,0.3) as `30分位值`,
    PERCENTILE_CONT(days,0.4) as `40分位值`,
    PERCENTILE_CONT(days,0.5) as `50分位值`,
    PERCENTILE_CONT(days,0.6) as `60分位值`,
    PERCENTILE_CONT(days,0.7) as `70分位值`,
    PERCENTILE_CONT(days,0.8) as `80分位值`,
    PERCENTILE_CONT(days,0.9) as `90分位值`,
    max(days) as `最大值`,
    avg(days) as avg_days -- 3天
from (
select
    user_id,count(distinct dt) as days
from t1
group by 1) a


-- 新注册用户首周访问
select
    min(days) as `最小值`,
    PERCENTILE_CONT(days,0.1) as `10分位值`,
    PERCENTILE_CONT(days,0.2) as `20分位值`,
    PERCENTILE_CONT(days,0.3) as `30分位值`,
    PERCENTILE_CONT(days,0.4) as `40分位值`,
    PERCENTILE_CONT(days,0.5) as `50分位值`,
    PERCENTILE_CONT(days,0.6) as `60分位值`,
    PERCENTILE_CONT(days,0.7) as `70分位值`,
    PERCENTILE_CONT(days,0.8) as `80分位值`,
    PERCENTILE_CONT(days,0.9) as `90分位值`,
    max(days) as `最大值`,
    avg(days) as avg_days -- 1.6天
from (
select
    t1.user_id,count(distinct dt) as days
from t1
inner join dim.dim_silkworm_user b on t1.user_id=b.user_id 
    and date_format(b.register_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1) a
;



======= 注册用户7日访问留存
drop view if exists t1;
create view if not exists t1 (
dt,user_id
) as (
select dt,
    unnest_bitmap as user_id 
from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where dt between date_sub(current_date(),interval 14 day) and date_sub(current_date(),interval 1 day)
group by 1,2
);



-- 新注册用户7日访问留存
select
    count(distinct b.user_id) as tot,
    count(distinct if(date_diff('day',t1.dt,date_format(b.register_time,'%Y-%m-%d'))=7,b.user_id,null)) as `7日访问留存用户量`,
    count(distinct if(date_diff('day',t1.dt,date_format(b.register_time,'%Y-%m-%d'))=7,b.user_id,null))/count(distinct b.user_id) as `7日访问留存用户率`
from (
select user_id,
    register_time 
from dim.dim_silkworm_user
where date_format(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 14 day) and date_sub(current_date(),interval 8 day)
) b
left join t1 on t1.user_id=b.user_id 
;







