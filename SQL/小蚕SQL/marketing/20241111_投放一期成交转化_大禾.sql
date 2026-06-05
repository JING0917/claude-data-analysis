========================== 投放数据转化统计
-- 以下3个行为，
select
    dt,
    platform_name,
    resource_id,
    put_id,
    count(distinct if(event_name='Takeout_Activity_Detail_View',user_id,null)) as `店铺活动详情页浏览用户量`,
    count(distinct if(event_name='Takeout_Grab_Click',user_id,null)) as `抢单按钮点击用户量`,
    count(distinct if(event_name='Takeout_Signup_Click',user_id,null)) as `报名按钮点击用户量`
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name in ('Takeout_Activity_Detail_View','Takeout_Grab_Click','Takeout_Signup_Click','Takeout_Activity_Detail_View_Duration')
    and resource_id<>''
group by 1,2,3,4
;

-- 测试一下

set query_timeout=12000;

-- 下单和报名按钮点击时间差 和产品沟通后，1分钟内都计算
with t as(
select
    c.*,d.*,date_diff('minute',order_time,event_time) as diff_time
from
-- 报名按钮点击
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id,
    event_time
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    -- and platform_name in ('iOS','Android')
    and resource_id<>''
    -- and put_id=2
group by 1,2,3,4,5,6) c
inner join
-- 订单
(select
    order_id,user_id,order_time,order_audit_finish_time,order_status,profit,
    -- case when order_platform=0 then 'H5'
    --     when order_platform=1 then '小程序'
    --     when order_platform=2 then 'APP'
    -- else '其他' end as order_platform_name
from dwd.dwd_sr_order_promotion_order
where dt='2024-11-10' -- 日期是当前天
    and order_status in (2,8)
    -- and order_platform=2 -- 0:H5,1:小程序,2:APP
    ) d
on c.user_id=d.user_id 
    -- and c.activity_id=cast(d.promotion_id as string) -- 不能作为条件，因专版活动订单无店铺活动ID
    and c.event_time<=d.order_time
where date_diff('minute',order_time,event_time) between 0 and 1
)

-- 报名按钮点击和下单时间差分位值
-- iOS 和Android端，中位值0，70分位值6,75分位值15,80分位值50

select
    PERCENTILE_CONT(diff_time,0.1) as p10_value,
    PERCENTILE_CONT(diff_time,0.2) as p20_value,
    PERCENTILE_CONT(diff_time,0.3) as p30_value,
    PERCENTILE_CONT(diff_time,0.4) as p40_value,
    PERCENTILE_CONT(diff_time,0.5) as p50_value,
    PERCENTILE_CONT(diff_time,0.6) as p60_value,
    PERCENTILE_CONT(diff_time,0.7) as p70_value,
    PERCENTILE_CONT(diff_time,0.75) as p75_value,
    PERCENTILE_CONT(diff_time,0.8) as p80_value,
    PERCENTILE_CONT(diff_time,0.9) as p90_value
from t
;

select order_id,store_promotion_id,user_id,order_time,order_audit_finish_time,order_status from dwd.dwd_sr_order_promotion_order
where dt='2024-11-10'
    and user_id=136821955 -- 937141579
;


select
    dt,
    platform_name,
    count(*) as cnt,
    sum(if(activity_id='' or activity_id is null),1,0) as cnt2
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    -- and platform_name in ('iOS','Android')
    and resource_id<>''
    -- and put_id=2
group by 1,2;



-- 正式统计
-- 投放转化
set query_timeout=12000;

with t1 as (
-- 报名按钮点击
select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id,
    event_time
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    and resource_id<>''
group by 1,2,3,4,5,6
),

-- 订单
t2 as (
select
    auto_id,
    order_id,
    cast(user_id as int) as user_id,
    order_time,
    profit,
    order_status
from dwd.dwd_sr_order_promotion_order
where dt='2024-11-10' -- 日期是当前天 每天更新最近两天数据 跨天要注意调整
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
    t2.order_time
from t1
inner join t2
on t1.user_id=t2.user_id
    and date_diff('minute',t2.order_time,t1.event_time) between 0 and 1
group by 1,2,3,4,5,6,7,8,9
)


-- 以下3个行为，
-- 活动详情页浏览
select
    a.dt,
    a.platform_name,
    a.resource_id,
    a.put_id,
    count(distinct a.user_id) as `店铺活动详情页浏览用户量`,
    count(distinct if(b.user_id is not null,a.user_id,null)) as `抢单按钮点击用户量`,
    count(distinct if(c.user_id is not null,a.user_id,null)) as `报名按钮点击用户量`,
    count(distinct if(d.user_id is not null,d.auto_id,null)) as `有效订单量`,
    sum(if(d.user_id is not null and d.order_status=2,d.profit,0)) as `订单利润`
from
-- 活动详情页浏览
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Activity_Detail_View'
    and resource_id<>''
group by 1,2,3,4,5) a
left join
-- 活动详情页抢单按钮点击
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Grab_Click'
    and resource_id<>''
group by 1,2,3,4,5) b 
on a.dt=b.dt 
    and a.platform_name=b.platform_name 
    and a.user_id=b.user_id
    and a.resource_id=b.resource_id
    and a.put_id=b.put_id
left join
-- 报名按钮点击
t1 as c 
on a.dt=c.dt 
    and a.platform_name=c.platform_name 
    and a.resource_id=c.resource_id 
    and a.user_id=c.user_id
    and a.put_id=c.put_id
inner join
-- 订单
t3 as d
on c.user_id=d.user_id
    and c.platform_name=d.platform_name
    and c.resource_id=d.resource_id 
    and c.put_id=d.put_id
    and date_diff('minute',d.order_time,c.event_time) between 0 and 1
group by 1,2,3,4
;


-- 验证数据
-- 验证 Android端 20241110 rid=3 pid=16,报名按钮点击用户和有效订单
with t1 as (
-- 报名按钮点击
select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id,
    event_time
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    and resource_id=3
    and put_id=16
group by 1,2,3,4,5,6
),

-- 订单
t2 as (
select
    auto_id,
    order_id,
    cast(user_id as int) as user_id,
    order_time,
    profit,
    order_status
from dwd.dwd_sr_order_promotion_order
where dt='2024-11-10' -- 日期是当前天 每天更新最近两天数据
    and order_status in (2,8)
    )

-- 下单和报名按钮点击时间差 和产品沟通后，1分钟内都计算
        select
            t1.dt,
            t1.platform_name,
            t1.user_id,
            t1.resource_id,
            t1.put_id,
            t2.auto_id,
            t2.profit,
            t2.order_status
        from t1
    inner join t2
        on t1.user_id=t2.user_id
            and date_diff('minute',t2.order_time,t1.event_time) between 0 and 1
        group by 1,2,3,4,5,6,7,8
;


-- 报名按钮点击时 店铺ID是否null或空
select
    dt,
    platform_name,
    count(1) as cnt,
    sum(if(store_id='',1,0)) as cnt2
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    and resource_id<>''
group by 1,2;



======== 再次验数
set query_timeout=12000;
SET resource_group = 'silkworm_flink_group';

with t1 as (
-- 报名按钮点击
select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id,
    event_time
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    and platform_name='Android'
    and resource_id=3
    and put_id=16
group by 1,2,3,4,5,6
),

-- 订单
t2 as (
select
    auto_id,
    order_id,
    cast(user_id as int) as user_id,
    order_time,
    profit,
    order_status
from dwd.dwd_sr_order_promotion_order
where dt='2024-11-10' -- 日期是当前天 每天更新最近两天数据 跨天要注意调整
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
    t2.order_time
from t1
inner join t2
on t1.user_id=t2.user_id
    and date_diff('minute',t2.order_time,t1.event_time) between 0 and 1
group by 1,2,3,4,5,6,7,8,9
)


-- 以下3个行为，
-- 活动详情页浏览
select
    a.dt,
    a.platform_name,
    a.resource_id,
    a.put_id,
    a.user_id,
    b.user_id,
    c.user_id,
    c.event_time,
    d.user_id,
    d.auto_id,
    d.profit,
    d.order_status,
    d.order_time
from
-- 活动详情页浏览
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Activity_Detail_View'
    and platform_name='Android'
    and resource_id=3
    and put_id=16
group by 1,2,3,4,5) a
left join
-- 活动详情页抢单按钮点击
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Grab_Click'
    and platform_name='Android'
    and resource_id=3
    and put_id=16
group by 1,2,3,4,5) b 
on a.dt=b.dt 
    and a.platform_name=b.platform_name 
    and a.user_id=b.user_id
    and a.resource_id=b.resource_id
    and a.put_id=b.put_id
left join
-- 报名按钮点击
t1 as c 
on a.dt=c.dt 
    and a.platform_name=c.platform_name 
    and a.resource_id=c.resource_id 
    and a.user_id=c.user_id
    and a.put_id=c.put_id
inner join
-- 订单
t3 as d
on c.user_id=d.user_id
    and c.platform_name=d.platform_name
    and c.resource_id=d.resource_id 
    and c.put_id=d.put_id
    and date_diff('minute',d.order_time,c.event_time) between 0 and 1
;


======================= 正式可用版本
SET resource_group = 'silkworm_flink_group';
set query_timeout=12000;

with t1 as (
-- 报名按钮点击
select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id,
    event_time
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Signup_Click'
    -- and platform_name='Android'
    and resource_id<>''
    -- and put_id=16
group by 1,2,3,4,5,6
),

-- 订单
t2 as (
select
    auto_id,
    order_id,
    cast(user_id as int) as user_id,
    order_time,
    profit,
    order_status
from dwd.dwd_sr_order_promotion_order
where dt='2024-11-10' -- 日期是当前天 每天更新最近两天数据 跨天要注意调整
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
    t2.order_time
from t1
inner join t2
on t1.user_id=t2.user_id
    and date_diff('minute',t2.order_time,t1.event_time) between 0 and 1
group by 1,2,3,4,5,6,7,8,9
)


-- 以下3个行为，
-- 活动详情页浏览
select
    dt,
    platform_name,
    resource_id,
    put_id,
    count(distinct view_user_id) as `店铺活动详情页浏览用户量`,
    count(distinct if(grab_user_id is not null,view_user_id,null)) as `抢单按钮点击用户量`,
    count(distinct if(bm_user_id is not null,view_user_id,null)) as `报名按钮点击用户量`,
    count(distinct if(order_user_id is not null,auto_id,null)) as `有效订单量`,
    sum(if(order_user_id is not null and order_status=2,profit,0)) as `订单利润`    
from
(select
    a.dt,
    a.platform_name,
    a.resource_id,
    a.put_id,
    a.user_id as view_user_id,
    b.user_id as grab_user_id,
    c.user_id as bm_user_id,
    d.user_id as order_user_id,
    d.auto_id,
    d.profit,
    d.order_status
from
-- 活动详情页浏览
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Activity_Detail_View'
    -- and platform_name='Android'
    and resource_id<>''
    -- and put_id=16
group by 1,2,3,4,5) a
left join
-- 活动详情页抢单按钮点击
(select
    dt,
    platform_name,
    user_id,
    resource_id,
    put_id
from ods.ods_sr_traffic_event_log 
where cast(dt as string) between '2024-11-10' and '2024-11-10'
    and event_name='Takeout_Grab_Click'
    -- and platform_name='Android'
    and resource_id<>''
    -- and put_id=16
group by 1,2,3,4,5) b 
on a.dt=b.dt 
    and a.platform_name=b.platform_name 
    and a.user_id=b.user_id
    and a.resource_id=b.resource_id
    and a.put_id=b.put_id
left join
-- 报名按钮点击
t1 as c 
on a.dt=c.dt 
    and a.platform_name=c.platform_name 
    and a.resource_id=c.resource_id 
    and a.user_id=c.user_id
    and a.put_id=c.put_id
inner join
-- 订单
t3 as d
on c.user_id=d.user_id
    and c.platform_name=d.platform_name
    and c.resource_id=d.resource_id 
    and c.put_id=d.put_id
    and date_diff('minute',d.order_time,c.event_time) between 0 and 1
group by 1,2,3,4,5,6,7,8,9,10,11
    ) toa
group by 1,2,3,4
;


========================================== 
-- 给到数据开发使用

SET resource_group = 'silkworm_flink_group';
set query_timeout=12000;

-- 以下逻辑按照日统计，小时统计时，需要注意跨天的小时处理

with t as (
-- 投放流量数据
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
where dt=current_date()
    and event_name in ('Homepage_Headpic_Ex','Homepage_Headpic_Click','HomePage_Banner_ex',
                        'HomePage_Banner_Click','Homepage_Operation_Popup_Ex','Homepage_Operation_Popup_Click',
                        'Homepage_Operation_Popup_Close','Homepage_Forced_Upgrade_Popup_Ex','Homepage_Forced_Upgrade_Popup_Click',
                        'Homepage_Forced_Upgrade_Popup_Close','Takeout_Activity_Detail_View','Takeout_Signup_Click')
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
    event_time
from ods.ods_sr_traffic_event_log 
where dt=current_date()
    and event_name='Takeout_Signup_Click'
group by 1,2,3,4,5,6
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
where dt between date_sub(current_date(),interval 7 day) and current_date() 
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=current_date()
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


-- 成交漏斗
select
    dt,
    platform_name,
    resource_id,
    put_id,
    count(distinct bg_user_id) as exp_user_num, -- 曝光用户量
    sum(exp_num) as exp_num, -- 曝光量
    count(distinct if(clk_user_id is not null,bg_user_id,null)) as click_user_num, -- 点击用户量
    sum(if(clk_user_id is not null,click_num,0)) as click_num, -- 点击量
    count(distinct if(view_user_id is not null,bg_user_id,null)) as detailpage_uv, -- 浏览用户量
    sum(if(view_user_id is not null,pv,0)) as detailpage_pv, -- 浏览量
    count(distinct if(order_user_id is not null,bg_user_id,null)) as valid_order_user_num, -- 有效下单用户量
    count(distinct if(order_user_id is not null,auto_id,null)) as valid_order_num, -- 有效订单量
    sum(if(order_user_id is not null and order_status=2,profit,0)) as profit, -- 订单利润     
    -- count(distinct if(order_user_id is not null,store_promotion_id,null)) as valid_pro_num -- 成交活动数  非自营订单中，活动ID=0
    count(distinct if(store_promotion_id<>0 and order_user_id is not null,store_promotion_id,null))
        + sum(if(store_promotion_id=0 and order_user_id is not null,1,0)) as valid_pro_num -- 成交活动数
(
select
    a.dt,
    a.platform_name,
    a.resource_id,
    a.put_id,
    a.user_id as bg_user_id,
    a.exp_num,
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
    -- 曝光
    (select
        dt,
        platform_name,
        user_id,
        resource_id,
        put_id,
        count(1) as exp_num
    from t
    where event_name in ('Homepage_Headpic_Ex','HomePage_Banner_ex','Homepage_Operation_Popup_Ex',
                        'Homepage_Forced_Upgrade_Popup_Ex')
    group by 1,2,3,4,5
    ) a
    -- 点击
    left join 
        (select
            dt,
            platform_name,
            user_id,
            resource_id,
            put_id,
            count(1) as click_num
        from t
        where event_name in ('Homepage_Headpic_Click','HomePage_Banner_Click','Homepage_Operation_Popup_Click',
                            'Homepage_Operation_Popup_Close','Homepage_Forced_Upgrade_Popup_Click',
                            'Homepage_Forced_Upgrade_Popup_Close')
        group by 1,2,3,4,5
        ) b on a.dt=b.dt
                and a.platform_name=b.platform_name
                and a.user_id=b.user_id
                and a.resource_id=b.resource_id
                and a.put_id=b.put_id
        -- 浏览
        left join 
            (select
                dt,
                platform_name,
                user_id,
                resource_id,
                put_id,
                count(1) as pv
            from t
            where event_name in ('Takeout_Activity_Detail_View')
            group by 1,2,3,4,5
            ) c on c.dt=b.dt
                    and c.platform_name=b.platform_name
                    and c.user_id=b.user_id
                    and c.resource_id=b.resource_id
                    and c.put_id=b.put_id
            -- 报名
            left join 
                (select
                    dt,
                    platform_name,
                    user_id,
                    resource_id,
                    put_id,
                    event_time
                from t1
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
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
) toa
group by 1,2,3,4;
































