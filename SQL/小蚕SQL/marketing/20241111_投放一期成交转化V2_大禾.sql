
=========== 给到数据开发使用 =============
-- 投放透传流量数据
with tc_info as (
select
    dt,
    case when platform_name in ('h5', '营销H5') then 'H5' 
        when platform_name = '小程序' then '小程序' 
        when platform_name = 'Android' then 'Android' 
        when platform_name = 'iOS' then 'iOS'
    else '其他' end as platform_name,
    user_id,
    resource_id,
    put_id,
    event_time,
    event_name
from ods.ods_sr_traffic_event_log 
where dt between date_sub(current_date(),interval 1 day) and current_date()
    and resource_id != 1
    and event_name in ('Homepage_Headpic_Ex','Homepage_Headpic_Click','HomePage_Banner_ex',
                        'HomePage_Banner_Click','Homepage_Operation_Popup_Ex','Homepage_Operation_Popup_Click',
                        'Homepage_Operation_Popup_Close','Homepage_Forced_Upgrade_Popup_Ex','Homepage_Forced_Upgrade_Popup_Click',
                        'Homepage_Forced_Upgrade_Popup_Close','Takeout_Activity_Detail_View','Takeout_Signup_Click')
    and resource_id  <> ''
    and resource_id is not null
    and put_id is not null
    and put_id  <> ''
group by 1,2,3,4,5,6,7
),

-- 投放曝光数据
bg_info as (
-- 投放流量数据
select
    dt,
    case when platform_name in ('h5', '营销H5') then 'H5' 
        when platform_name = '小程序' then '小程序' 
        when platform_name = 'Android' then 'Android' 
        when platform_name = 'iOS' then 'iOS'
    else '其他' end as platform_name,
    user_id,
    def_resource_id,
    def_put_id,
    event_time,
    event_name
from ods.ods_sr_traffic_event_log 
where dt between date_sub(current_date(),interval 1 day) and current_date()
    and def_resource_id != 1
    and event_name in ('Homepage_Headpic_Ex','HomePage_Banner_ex','Homepage_Operation_Popup_Ex','Homepage_Forced_Upgrade_Popup_Ex')
    and def_resource_id  <> ''
    and def_resource_id is not null
    and def_put_id is not null
    and def_put_id  <> ''
group by 1,2,3,4,5,6,7
),


-- 报名按钮点击
t1 as (
select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id,
    event_time,
    event_name
from ods.ods_sr_traffic_event_log 
where dt between date_sub(current_date(),interval 1 day) and current_date()
    and resource_id != 1
    and event_name='Takeout_Signup_Click'
    and resource_id  <> ''
    and resource_id is not null
    and put_id is not null
    and put_id  <> ''
group by 1,2,3,4,5,6,7
),


-- 订单
t2 as (
select
    auto_id,
    order_id,
    cast(user_id as int) as user_id,
    order_time,
    profit,
    order_status,
    store_promotion_id
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 1 day) and current_date()
    and order_status in (2,8) 
    ),


-- 下单和报名按钮点击时间差 和产品沟通后，1分钟内都计算
t3 as(
select
    t1.dt,
    t1.platform_name,
    t1.user_id,
    t1.resource_id,
    t1.put_id,
    t2.auto_id,
    t2.profit,
    t2.order_status,
    t2.order_time,
    t2.store_promotion_id
from t1
inner join t2
on t1.user_id=t2.user_id
    and date_diff('minute',t2.order_time,t1.event_time) between 0 and 1
group by 1,2,3,4,5,6,7,8,9,10
)




select
    dt,
    platform_name,
    resource_id,
    put_id,
    sum(exp_num) as exp_num,
    sum(expose_uv) as expose_uv,
    sum(click_num) as click_num, -- 点击量
    sum(click_uv) as click_uv, -- 点击用户量
    sum(detailpage_pv) as detailpage_pv, -- 活动详情页PV
    sum(detailpage_uv) as detailpage_uv, -- 活动详情页uv
    sum(vaild_order_user_num) as vaild_order_user_num, --有效用户量
    sum(valid_order_num) as valid_order_num, -- 有效订单量
    sum(valid_order_profit) as valid_order_profit, -- 订单利润     
    sum(valid_promotion_num) as valid_promotion_num -- 成交活动数
from
-- 曝光
(
select
    dt,
    platform_name,
    def_resource_id as resource_id,
    def_put_id as put_id,
    count(1) as exp_num,
    count(distinct user_id) as expose_uv,
    0 as click_num, -- 点击量
    0 as click_uv, -- 点击用户量
    0 as detailpage_pv, -- 活动详情页PV
    0 as detailpage_uv, -- 活动详情页uv
    0 as vaild_order_user_num, --有效用户量
    0 as valid_order_num, -- 有效订单量
    0 as valid_order_profit, -- 订单利润     
    0 as valid_promotion_num -- 成交活动数
from bg_info
group by 1,2,3,4


union all

-- 点击和转化 因埋点透传从点击开始 故以点击作为漏斗起始事件
select
    dt,
    platform_name,
    resource_id,
    put_id,
    0,0,
    sum(click_num) as click_num, -- 点击量
    count(distinct clk_user_id) as click_uv, -- 点击用户量
    sum(if(view_user_id is not null,pv,0)) as detailpage_pv, -- 活动详情页PV
    count(distinct if(view_user_id is not null,clk_user_id,null)) as detailpage_uv, -- 活动详情页uv
    count(distinct if(order_user_id is not null,clk_user_id,null)) as vaild_order_user_num, --有效用户量
    count(distinct if(order_user_id is not null,auto_id,null)) as valid_order_num, -- 有效订单量
    sum(if(order_user_id is not null and order_status=2,profit,0)) as valid_order_profit, -- 订单利润     
    count(distinct if(store_promotion_id<>0 and order_user_id is not null,store_promotion_id,null))
        + sum(if(store_promotion_id=0 and order_user_id is not null,1,0)) as valid_promotion_num -- 成交活动数
from (
    select
        b.dt,
        b.platform_name,
        b.resource_id,
        b.put_id,
        b.user_id as clk_user_id,
        b.click_num,
        c.user_id as view_user_id,
        c.pv,
        e.user_id as order_user_id,
        e.auto_id,
        e.profit,
        e.order_status,
        e.store_promotion_id
    from
    -- 点击
    (select
        dt,
        platform_name,
        user_id,
        resource_id,
        put_id,
        count(1) as click_num
    from tc_info
    where event_name in ('Homepage_Headpic_Click','HomePage_Banner_Click','Homepage_Operation_Popup_Click',
                                'Homepage_Operation_Popup_Close','Homepage_Forced_Upgrade_Popup_Click',
                                'Homepage_Forced_Upgrade_Popup_Close')
    group by 1,2,3,4,5
    ) b 
    -- 浏览
    left join 
            (
        select
            dt,
            platform_name,
            user_id,
            resource_id,
            put_id,
            count(1) as pv
        from tc_info
        where event_name in ('Takeout_Activity_Detail_View')
        group by 1,2,3,4,5
            ) c on c.dt=b.dt
                    and c.platform_name=b.platform_name
                    and c.user_id=b.user_id
                    and c.resource_id=b.resource_id
                    and c.put_id=b.put_id
        -- 报名
        left join 
                (
            select
                dt,
                platform_name,
                user_id,
                resource_id,
                put_id,
                event_time
            from tc_info
            where event_name in ('Takeout_Signup_Click')
                ) d on c.dt=d.dt
                            and c.platform_name=d.platform_name
                            and c.user_id=d.user_id
                            and c.resource_id=d.resource_id
                            and c.put_id=d.put_id
            -- 下单
            left join t3 as e
                        on e.user_id=d.user_id
                            and e.platform_name=d.platform_name
                            and e.resource_id=d.resource_id 
                            and e.put_id=d.put_id
                            and date_diff('minute',e.order_time,d.event_time) between 0 and 1
group by 1,2,3,4,5,6,7,8,9,10,11,12,13
) toa
group by 1,2,3,4
) tob
group by 1,2,3,4
;





======================== 验埋点数据
20241130发现资源位ID和投放ID对应关系，与后台配置不一致，在iOS和Android出现此问题。原因：弹窗事件埋点，点击行为的资源位ID取值错误。

-- 点击漏斗
-- APP端有resource_id是1 开发反馈在2.12.7及以上版本调整了，28号下午看数据还有为1的数据
with tc_info as (
select
    dt,
    case when platform_name in ('h5', '营销H5') then 'H5' 
        when platform_name = '小程序' then '小程序' 
        when platform_name = 'Android' then 'Android' 
        when platform_name = 'iOS' then 'iOS'
    else '其他' end as platform_name,
    user_id,
    resource_id,
    put_id,
    event_time,
    event_name
    ,version
from ods.ods_sr_traffic_event_log 
where dt between date_sub(current_date(),interval 1 day) and current_date()
    -- and resource_id != 1
    and event_name in ('Homepage_Headpic_Ex','Homepage_Headpic_Click','HomePage_Banner_ex',
                        'HomePage_Banner_Click','Homepage_Operation_Popup_Ex','Homepage_Operation_Popup_Click',
                        'Homepage_Operation_Popup_Close','Homepage_Forced_Upgrade_Popup_Ex','Homepage_Forced_Upgrade_Popup_Click',
                        'Homepage_Forced_Upgrade_Popup_Close','Takeout_Activity_Detail_View','Takeout_Signup_Click')
    and resource_id  <> ''
    and resource_id is not null
    and put_id is not null
    and put_id  <> ''
group by 1,2,3,4,5,6,7
)

select
    dt,
    platform_name,
    resource_id,
    put_id,
    version,
    count(1) as click_num,
    count(distinct user_id) click_uv
from tc_info
where event_name in ('Homepage_Headpic_Click','HomePage_Banner_Click','Homepage_Operation_Popup_Click',
                            'Homepage_Operation_Popup_Close','Homepage_Forced_Upgrade_Popup_Click',
                            'Homepage_Forced_Upgrade_Popup_Close')
group by 1,2,3,4,5
;


=========
-- APP端有resource_id是1 开发反馈在2.12.7及以上版本调整了，28号下午看数据还有为1的数据
with bg_info as (
-- 投放流量数据
select
    dt,
    case when platform_name in ('h5', '营销H5') then 'H5' 
        when platform_name = '小程序' then '小程序' 
        when platform_name = 'Android' then 'Android' 
        when platform_name = 'iOS' then 'iOS'
    else '其他' end as platform_name,
    user_id,
    def_resource_id,
    def_put_id,
    event_time,
    event_name,
    version
from ods.ods_sr_traffic_event_log 
where dt between date_sub(current_date(),interval 1 day) and current_date()
    -- and def_resource_id != 1
    and event_name in ('Homepage_Headpic_Ex','HomePage_Banner_ex','Homepage_Operation_Popup_Ex','Homepage_Forced_Upgrade_Popup_Ex')
    and def_resource_id  <> ''
    and def_resource_id is not null
    and def_put_id is not null
    and def_put_id  <> ''
group by 1,2,3,4,5,6,7,8
)

select
    dt,
    platform_name,
    def_resource_id as resource_id,
    def_put_id as put_id,
    version,
    count(1) as bg_num,
    count(distinct user_id) as bg_uv
from bg_info
group by 1,2,3,4,5;















