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
    sum(if(event_name='Bargain_Activity_Details_Share_Ex',1,0)) `砍价活动详情页分享弹窗曝光量`,
    count(distinct if(event_name='Bargain_Activity_Details_Share_Ex',user_id,null)) `砍价活动详情页分享弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Ex',1,0)) `邀请砍价弹窗曝光量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Ex',user_id,null)) `邀请砍价弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Click',1,0)) `邀请砍价弹窗点击量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Click',user_id,null)) `邀请砍价弹窗点击UV`
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4)='3301' 
    and event_name in ('StoreDiscovery_Homepage_View',
        'Bargain_Homepage_Ex',
        'StoreDiscovery_Activity_Details_Ex',
        'Bargain_Share_Button_Click',
        'Bargain_Activity_Details_Share_Ex',
        'Invite_Bargain_Windows_Ex',
        'Invite_Bargain_Windows_Click',
        'Store_Details_View')
group by 1,2;



-- 埋点优化后日志
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
    sum(if(event_name='Bargain_Activity_Details_Share_Ex',1,0)) `砍价活动详情页分享弹窗曝光量`,
    count(distinct if(event_name='Bargain_Activity_Details_Share_Ex',user_id,null)) `砍价活动详情页分享弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Ex',1,0)) `邀请砍价弹窗曝光量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Ex',user_id,null)) `邀请砍价弹窗曝光UV`,
    sum(if(event_name='Invite_Bargain_Windows_Click',1,0)) `邀请砍价弹窗点击量`,
    count(distinct if(event_name='Invite_Bargain_Windows_Click',user_id,null)) `邀请砍价弹窗点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.activity_type') as activity_type
ods.ods_sr_event_log
where dt=date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4)='3301' 
    and event_name in ('StoreDiscovery_Homepage_View',
        'Bargain_Homepage_Ex',
        'StoreDiscovery_Activity_Details_Ex',
        'Bargain_Share_Button_Click',
        'Bargain_Activity_Details_Share_Ex',
        'Invite_Bargain_Windows_Ex',
        'Invite_Bargain_Windows_Click',
        'Store_Details_View')
    ) a
group by 1,2;

select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.activity_id') as activity_id
ods.ods_sr_event_log
where dt=date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4)='3301' 
    and event_name='StoreDiscovery_Activity_Details_Ex'
limit 100;



杭州2.9、2.10、2.11三天以下指标的pv、uv
砍价主页曝光、活动详情页曝光、活动详情页小banner曝光&点击、分享面板进群banner曝光&点击、加社群页面曝光、加社群页面按钮点击



-- 埋点优化后日志
select
    dt `统计日期`,
    '杭州' as `城市`,
    sum(if(event_name='Bargain_Homepage_Ex',1,0)) `砍价主页PV`,
    count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) `砍价主页UV`,
    sum(if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',1,0)) `砍价活动详情页PV`,
    count(distinct if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',user_id,null)) `砍价活动详情页UV`,  
    sum(if(event_name='Bargain_Activity_Details_small_banner_Ex',1,0)) `砍价活动详情页小banner曝光量`,
    count(distinct if(event_name='Bargain_Activity_Details_small_banner_Ex',user_id,null)) `砍价活动详情页小banner曝光UV`,
    sum(if(event_name='Bargain_Activity_Details_small_banner_Click',1,0)) `砍价活动详情页小banner点击量`,
    count(distinct if(event_name='Bargain_Activity_Details_small_banner_Click',user_id,null)) `砍价活动详情页小banner点击UV`,
    sum(if(event_name='Bargain_Share_Enter_Group_Banner_Ex',1,0)) `砍价分享面板进群banner曝光量`,
    count(distinct if(event_name='Bargain_Share_Enter_Group_Banner_Ex',user_id,null)) `砍价分享面板进群banner曝光UV`,
    sum(if(event_name='Bargain_Share_Enter_Group_Button_Click',1,0)) `砍价分享面板进群按钮点击量`,
    count(distinct if(event_name='Bargain_Share_Enter_Group_Button_Click',user_id,null)) `砍价分享面板进群按钮点击UV`,
    sum(if(event_name='Bargain_Enter_Group_Page_Ex',1,0)) `砍价进群页面曝光量`,
    count(distinct if(event_name='Bargain_Enter_Group_Page_Ex',user_id,null)) `砍价进群页面曝光UV`,
    sum(if(event_name='Bargain_Enter_Group_Button_Click',1,0)) `砍价进群按钮点击量`,
    count(distinct if(event_name='Bargain_Enter_Group_Button_Click',user_id,null)) `砍价进群按钮点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.activity_type') as activity_type
from ods.ods_sr_event_log
where dt between '2025-02-09' and date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4)='3301' 
    and event_name in (
        'Bargain_Homepage_Ex',
        'StoreDiscovery_Activity_Details_Ex',
        'Bargain_Activity_Details_small_banner_Ex',
        'Bargain_Activity_Details_small_banner_Click',
        'Bargain_Share_Enter_Group_Banner_Ex',
        'Bargain_Share_Enter_Group_Button_Click',
        'Bargain_Enter_Group_Page_Ex',
        'Bargain_Enter_Group_Button_Click')
    ) a
group by 1,2;



select
    dt `统计日期`,
    '杭州' as `城市`,
    sum(if(event_name='Bargain_Homepage_Ex',1,0)) `砍价主页PV`,
    count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) `砍价主页UV`,
    sum(if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',1,0)) `砍价活动详情页PV`,
    count(distinct if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',user_id,null)) `砍价活动详情页UV`,  
    sum(if(event_name='Bargain_Activity_Details_small_banner_Ex',1,0)) `砍价活动详情页小banner曝光量`,
    count(distinct if(event_name='Bargain_Activity_Details_small_banner_Ex',user_id,null)) `砍价活动详情页小banner曝光UV`,
    sum(if(event_name='Bargain_Activity_Details_small_banner_Click',1,0)) `砍价活动详情页小banner点击量`,
    count(distinct if(event_name='Bargain_Activity_Details_small_banner_Click',user_id,null)) `砍价活动详情页小banner点击UV`,
    sum(if(event_name='Bargain_Share_Enter_Group_Banner_Ex',1,0)) `砍价分享面板进群banner曝光量`,
    count(distinct if(event_name='Bargain_Share_Enter_Group_Banner_Ex',user_id,null)) `砍价分享面板进群banner曝光UV`,
    sum(if(event_name='Bargain_Share_Enter_Group_Button_Click',1,0)) `砍价分享面板进群按钮点击量`,
    count(distinct if(event_name='Bargain_Share_Enter_Group_Button_Click',user_id,null)) `砍价分享面板进群按钮点击UV`,
    sum(if(event_name='Bargain_Enter_Group_Page_Ex',1,0)) `砍价进群页面曝光量`,
    count(distinct if(event_name='Bargain_Enter_Group_Page_Ex',user_id,null)) `砍价进群页面曝光UV`,
    sum(if(event_name='Bargain_Enter_Group_Button_Click',1,0)) `砍价进群按钮点击量`,
    count(distinct if(event_name='Bargain_Enter_Group_Button_Click',user_id,null)) `砍价进群按钮点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.activity_type') as activity_type
from ods.ods_sr_event_log
where dt between '2025-02-09' and date_sub(current_date(),interval 1 day)
    and substr(county_id,1,4)='3301' 
    and event_name in (
        'Bargain_Homepage_Ex',
        'StoreDiscovery_Activity_Details_Ex',
        'Bargain_Activity_Details_small_banner_Ex',
        'Bargain_Activity_Details_small_banner_Click',
        'Bargain_Share_Enter_Group_Banner_Ex',
        'Bargain_Share_Enter_Group_Button_Click',
        'Bargain_Enter_Group_Page_Ex',
        'Bargain_Enter_Group_Button_Click')
    ) a
group by 1,2;



近7天每一天砍价主页访问pu/uv、轮播模块访问pv/uv、点击pv/uv、每一个筛选项的点击pv/uv

-- 日数据
select
    dt `统计日期`,
    sum(if(event_name='Bargain_Homepage_Ex',1,0)) `砍价主页PV`,
    count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) `砍价主页UV`, 
    sum(if(event_name='Bargain_Homepage_Slide_FengyunList',1,0)) `砍价主页轮播模块点击量`,
    count(distinct if(event_name='Bargain_Homepage_Slide_FengyunList',user_id,null)) `砍价主页轮播模块点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.filter_classification') as filter_classification,
    get_json_string(data,'$.filter_condition') as filter_condition
from ods.ods_sr_event_log
where dt between '2025-02-09' and date_sub(current_date(),interval 1 day)
    and event_name in (
        'Bargain_Homepage_Ex'
        ,'Bargain_Homepage_Slide_FengyunList'
        -- ,'Bargain_Homepage_Filter_Button_Click'
        )
    ) a
group by 1;


-- 砍价首页导航栏名称
select
    dt `统计日期`,
    filter_classification `砍价首页导航栏名称`,
    count(1) `点击量`,  
    count(distinct user_id) `点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.filter_classification') as filter_classification,
    get_json_string(data,'$.filter_condition') as filter_condition
from ods.ods_sr_event_log
where dt between '2025-02-09' and date_sub(current_date(),interval 1 day)
    and event_name ='Bargain_Homepage_Filter_Button_Click'
    ) a
group by 1,2;


-- 砍价首页导航筛选
select
    dt `统计日期`,
    filter_condition `砍价首页导航筛选`,
    count(1) `点击量`,  
    count(distinct user_id) `点击UV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.filter_classification') as filter_classification,
    get_json_string(data,'$.filter_condition') as filter_condition
from ods.ods_sr_event_log
where dt between '2025-02-09' and date_sub(current_date(),interval 1 day)
    and event_name ='Bargain_Homepage_Filter_Button_Click'
    ) a
group by 1,2;





拉一下砍价近一周每天活动详情页的pv、uv，活动详情页的状态（已售罄、进行中....）

-- 砍价活动详情页流量
select
    dt `统计日期`
    ,'砍价活动详情页' `页面`
    ,count(1) `PV`
    ,count(distinct user_id) `UV`
    sum(if(state='可抢',1,0)) `可抢活动PV`,
    count(distinct if(state='可抢',user_id,null)) `可抢活动UV`,
    sum(if(state='预购',1,0)) `预购活动PV`,
    count(distinct if(state='预购',user_id,null)) `预购活动UV`,
    sum(if(state='已抢',1,0)) `已抢活动PV`,
    count(distinct if(state='已抢',user_id,null)) `已抢活动UV`,
    sum(if(state='售罄',1,0)) `售罄活动PV`,
    count(distinct if(state='售罄',user_id,null)) `售罄活动UV`,
    sum(if(state='未开始',1,0)) `未开始活动PV`,
    count(distinct if(state='未开始',user_id,null)) `未开始活动UV`,
    sum(if(state='已结束',1,0)) `已结束活动PV`,
    count(distinct if(state='已结束',user_id,null)) `已结束活动UV`,
    sum(if(state='砍价',1,0)) `砍价活动PV`,
    count(distinct if(state='砍价',user_id,null)) `砍价活动UV`,
    sum(if(state='再砍',1,0)) `再砍活动PV`,
    count(distinct if(state='再砍',user_id,null)) `再砍活动UV`,
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.state') as state
from ods.ods_sr_event_log
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_name ='Bargain_Activity_Details_Ex'
    ) a
group by 1,2;






========== 捷西
-- 砍价进群页面曝光点击
select
    dt `统计日期`,
    sum(if(event_name='Bargain_Enter_Group_Page_Ex',1,0)) `砍价进群页面曝光量`,
    count(distinct if(event_name='Bargain_Enter_Group_Page_Ex',user_id,null)) `砍价进群页面曝光UV`,
    sum(if(event_name='Bargain_Enter_Group_Button_Click',1,0)) `砍价进群按钮点击量`,
    count(distinct if(event_name='Bargain_Enter_Group_Button_Click',user_id,null)) `砍价进群按钮点击UV`
from ods.ods_sr_event_log
where dt between '2025-03-01' and date_sub(current_date(),interval 1 day)
    and event_name in (
        'Bargain_Enter_Group_Page_Ex',
        'Bargain_Enter_Group_Button_Click')
group by 1;
















