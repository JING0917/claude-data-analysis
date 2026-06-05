-- boss渠道拉新流量统计
select
    cast(dt as string) as `统计日期`,
    sum(if(event_name='Boss_Welcome_Page_ex',1,0)) as `欢迎页pv`,
    count(distinct if(event_name='Boss_Welcome_Page_ex',user_id,null)) as `欢迎页uv`,
    sum(if(event_name='Boss_HomePage_ex',1,0)) as `boss拉新主页pv`,
    count(distinct if(event_name='Boss_HomePage_ex',user_id,null)) as `boss拉新主页uv`,
    sum(if(event_name='Boss_to_TakeOut_click',1,0)) as `去点餐按钮点击量`,
    count(distinct if(event_name='Boss_to_TakeOut_click',user_id,null)) as `去点餐按钮点击用户量`
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-09-01' and '2024-09-17' 
    and event_name in ('Boss_Welcome_Page_ex','Boss_HomePage_ex','Boss_to_TakeOut_click')
    and platform_name='营销H5'
group by 1
;

select user_id,inviter_user_id,register_time from  dim.dim_silkworm_user 
where user_id in (672572575,724372579,323372571,746618574,926618571,683372579,548572574,
171968578,515372575,277238575,199832573,188918573,413372579,114248572,974248578,664372572,
414372575);

show create table dwd.dwd_sr_order_promotion_order;

select 
-- dt,order_time,user_id,order_id
*
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-09-12' and '2024-09-17'
    and user_id in (672572575,724372579,323372571,746618574,926618571,683372579,548572574,
171968578,515372575,277238575,199832573,188918573,413372579,114248572,974248578,664372572,
414372575);