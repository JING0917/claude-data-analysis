--SQL
--******************************************************************--
--author: dahe
--create time: 2024-08-15 09:48:15
--******************************************************************--

-- 以下SQL在sr中执行

desc dwd.dwd_sr_order_promotion_order

select 
    *
from dwd.dwd_sr_order_promotion_order


desc dim.dim_silkworm_explore_daren

show create table dim.dim_silkworm_explore_daren;

select * from dim.dim_silkworm_explore_daren limit 10


select * from dim.dim_silkworm_user
where user_id=923592157


select 1035/100000

================ 到店用户调研
-- 探店业务用户
with t1 as (
select  to_date(a.create_time) as create_date,
            a.user_id,
            b.wechat_nickname as user_nickname,
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
            substring(xiaohongshu_auth_time, 1, 10) as xiaohongshu_auth_date -- 小红书认证日期
    from (select * from dim.dim_silkworm_explore_daren where status=1
    ) a
inner join (
select b1.user_id,b2.wechat_nickname from
(select user_id,user_wechat_id from dim.dim_silkworm_user where city_id=3301) b1
left join (select * from dim.dim_silkworm_user_wechat) b2 
on b1.user_wechat_id=b2.user_wechat_id
            ) b
on a.user_id=b.user_id
),

-- 近7天累计外卖订单
t2 as (
select
    user_id,
    count(order_id) as cnt
from dwd.dwd_sr_order_promotion_order
    where dt between '2024-07-01' and date_sub(current_date,1)
        and to_date(substr(order_time,1,10)) between date_sub(current_date,7) and date_sub(current_date,1)
        and order_status in (2,8)
        and city_id=3301 -- 杭州市
    group by 1
    having count(order_id)>=10
),

-- 首次下单日期和下单量
t3 as (
select
    user_id,
    substr(min(if(status=5 and finish_time is not null,finish_time,null)),1,10) as first_order_date, -- 首次下单日期
    count(if(status=5 and finish_time is not null,order_id,null)) as order_num -- 订单量
from dwd.dwd_sr_silkworm_explore_order
where to_date(dt) between '2024-06-18' and date_sub(current_date,1)
    and store_name not regexp '测试'
group by user_id
),

t4 as (
-- 6月解锁达人但未下单用户
select
    '6月解锁达人但未下单用户' as `类型`,
    t1.user_id as `用户ID`,
    user_nickname as `用户昵称`
from t1
inner join t3 on t1.user_id=t3.user_id
where t1.daren_activate_date between '2024-06-18' and '2024-06-30'
    and t1.is_daren=1
    and t3.first_order_date is null

union all
-- 截止7月31日下首单且累计1单用户
select
    '截止7月31日下首单且累计1单用户' as `类型`,
    t3.user_id as `用户ID`,
    b.user_nickname as `用户昵称`
from t3
left join dim.dim_silkworm_user b on t3.user_id=b.user_id
where first_order_date is not null
    and first_order_date<='2024-07-31'
    and order_num=1

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
)

select  `类型`,count(`用户ID`) as cnt from t4 group by 1


-- sr
with t2 as (
select
    user_id,
    count(order_id) as cnt
from dwd.dwd_sr_order_promotion_order
    where dt between '2024-07-01' and date_sub(current_date,1)
        and to_date(substr(order_time,1,10)) between date_sub(current_date,7) and date_sub(current_date,1)
        and order_status in (2,8)
        and city_id=3301 -- 杭州市
    group by 1
    having count(order_id)>=10
)

select count(*) from t2


select
    user_id,
    concat(order_id,'单') as order_id,
    order_time
from dwd.dwd_sr_order_promotion_order
    where dt between '2024-07-01' and date_sub(current_date,1)
        and substr(order_time,1,10) between date_sub(current_date,7) and date_sub(current_date,1)
        and order_status in (2,8)
        and city_id=3301 -- 杭州市
        and user_id=21565024




select
    *
from dwd.dwd_sr_order_promotion_order
    where dt between '2024-07-01' and date_sub(current_date,1)
        and to_date(substr(order_time,1,10)) between date_sub(current_date,7) and date_sub(current_date,1)
        -- and order_status in (2,8)
        -- and city_id=3301 -- 杭州市
        and order_id in ('202408171077199130185',
'202408171147199153188',
'202408171236199269118',
'202408171316199302814',
'202408171415199311219')

-- bd 2323发布活动
select 
    a.store_id,
    b.store_name,
    a.bd_id
from
(select
    store_id,
    bd_id
from dwd.dwd_sr_store_promotion
where dt between '2024-01-01' and '2024-08-25'
    and begin_date>='2024-06-01'
    and bd_id=1649
group by 1,2
) a
left join dim.dim_silkworm_store b on a.store_id=b.store_id

-- sr跑数据
select
    substr(register_time,1,10) as dat,
    count(user_id) as tot,
    count(if(substr(first_valid_order_time,1,10)=substr(register_time,1,10),user_id,null)) as valid_cnt,
    count(if(substr(first_valid_order_time,1,10)<>'1970-01-01' and length(first_valid_order_time)>0,user_id,null)) as valid_cnt
from dim.dim_silkworm_user
where substr(register_time,1,10)>='2024-01-01'
group by 1


-- 有效下单时间
select
    b.user_id,
    a.user_id,
    b.min_order_time,
    a.first_valid_order_time
 from
-- 用户最小有效下单时间
(select user_id,min(order_time) over(partition by user_id order by order_time) as min_order_time
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'yyyy-MM-dd') ='2024-08-24' 
    and date_format(order_time,'yyyy-MM-dd')='2024-08-24'
    and order_status in (2,8)
) b
left join
-- 注册用户
(select user_id,first_valid_order_time from dim.dim_silkworm_user 
where substr(register_time,1,10)='2024-08-24') a
on a.user_id=b.user_id
-- 取出当日注册没有首单的用户
where a.user_id is not null 
    -- and substr(a.first_valid_order_time,1,10)='1970-01-01'
    and substr(a.first_valid_order_time,1,10)<>substr(b.min_order_time,1,10)



select
    substr(cast(county_id as string),1,4) as city_id,
    replace(city_name,'市','') as city_name
from dim_silkworm_county
group by 1,2

show create table dim.dim_silkworm_bd_city

select
    bd_id,
    substr(unnest,1,4) as city_id
from
    (select
        a.bd_id,
        cast(get_json_string(b.city_id_list,'$.city_code_list') as array<string>) as city_id
    from dim.dim_silkworm_staff a
    left join dim.dim_silkworm_bd_city b
    on a.staff_id=b.bd_id
    ) a1,unnest(city_id)
group by 1,2


select staff_id,bd_id from dim.dim_silkworm_staff where bd_id=946

select * from dim.dim_silkworm_bd_city where bd_id=1232

select
    to_date(date_add(to_date(begin_date),unnest)) as new_begin_date,
    begin_date,
    end_date,
    arr,
    bd_id,
    store_id,
    store_promotion_id,
    city_id,
    cooper_type,
    meituan_mlabel_rebate_amt,
    eleme_mlabel_rebate_amt,
    meituan_promotion_quota,
    eleme_promotion_quota
from
(select
    begin_date,
    end_date,
    array_generate(0,diff_num,1) as arr,
    bd_id,
    store_id,
    store_promotion_id,
    city_id,
    cooper_type,
    meituan_mlabel_rebate_amt,
    eleme_mlabel_rebate_amt,
    meituan_promotion_quota,
    eleme_promotion_quota
from
-- 7月发布活动
(select begin_date,
        end_date,
        cast(datediff(to_date(end_date),to_date(begin_date)) as int) as diff_num,
        bd_id,
        store_id,
        store_promotion_id,
        city_id,
        cooper_type,
        meituan_mlabel_rebate_amt,
        eleme_mlabel_rebate_amt,
        meituan_promotion_quota,
        eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between '2024-06-01' and '2024-07-31'
        and begin_date between '2024-07-01' and '2024-07-31'
        and status in (1,4,5)
        and store_promotion_id=26102977     -- 26056233
) a1
) a2,unnest(arr)


show create table dws.dws_sr_data_governance_monitor_d;

select * from dws.dws_sr_data_governance_monitor_d;

show create table dwd.dwd_sr_order_promotion_order;


select
    is_pay_exception,
    count(1) as cnt
from dwd.dwd_sr_store_promotion
where dt between '2024-06-01' and '2024-07-31'
        and begin_date between '2024-07-01' and '2024-07-31'
        and status in (1,4,5)
        -- and is_pay_exception=1
group by 1
limit 10


select begin_date,
    cast(datediff(to_date(pay_time),to_date(begin_date)) as int) as diff_num,
    bd_id,
    store_id,
    store_promotion_id,
    substr(pay_time,1,10) as pay_date,
    is_pay_exception, -- 是否15日内未支付 0:否，1:是
    pay_status, -- 付款状态(0:商家已余额支付,1:后台创建活动开始,2:等待商家支付,3:支付完成,4:部分支付完成) 
    fact_pay_rebate_amt/100 as pay_amt
from dwd.dwd_sr_store_promotion
where dt between '2024-06-01' and '2024-07-31'
        and begin_date between '2024-07-01' and '2024-07-31'
        and status in (1,4,5)
        -- and substr(pay_time,1,10)<>'1970-01-01'
        and is_pay_exception=1
;


show create table dwd.dwd_sr_store_bd_call_record;

select * from dwd.dwd_sr_store_bd_call_record where dt>='2024-08-01' and staff_id=2323 limit 10


select
    dt
    ,bd_id
    ,count(auto_id) as call_num -- 外呼量
    ,count(if(is_connect=1,auto_id,null)) as jt_num -- 接通量
    ,sum(if(is_connect=1,duration,0)) as call_duration -- 通话时长
    ,sum(if(is_connect=1,duration,0))/count(if(is_connect=1,auto_id,null)) as avg_call_duration
from dwd.dwd_sr_store_bd_call_record
where dt between '2024-07-01' and '2024-07-31'
    and bd_id=1649
group by 1,2 
;

show create table dwd.dwd_sr_store_promotion;

select * from dim.dim_silkworm_store limit 10

show create table ods.ods_sr_traffic_event_log;

================ 页面主要埋点位置曝光和点击
with t1 as(
select
    dt,
    event_time,
    coalesce(platform_name,'其他') as platform_name,
    event_name,
    user_id,
    coalesce(function_button_type,'其他') as function_button_type,
    coalesce(brand_name,'其他') as brand_name,
    coalesce(newuser_gift_area,'其他') as newuser_gift_area,
    coalesce(market_area,'其他') as market_area,
    coalesce(discount_brand,'其他') as discount_brand,
    coalesce(button_name,'其他') as button_name
from ods.ods_sr_traffic_event_log
where dt between '2024-08-25' and '2024-08-31' -- 最近7天
    and event_name in (
        'HomePage_View'
        ,'HomePage_Featured_Section_Click'
        ,'BigBrand_Brand_Click'
        ,'BigBrand_Carousel_Click'
        ,'BigBrand_Meituan_RedPacket_Click'
        ,'BigBrand_Eleme_RedPacket_Click'
        ,'HomePage_Newcomer_Gift_Click'
        ,'HomePage_Marketing_ex'
        ,'HomePage_Marketing_Click'
        ,'HomePage_Banner_ex'
        ,'HomePage_Banner_Click'
        ,'Welfare_Page_View'
        ,'Welfare_Header_Image_Click'
        ,'Welfare_Brand_Advertisement_Click'
        ,'Welfare_Daily_Discount_Claim_Click'
        ,'Welfare_Side_Unboxing_Click')
),

-- 统计各事件指标
-- 首页浏览
t2 as (
select
    dt,
    coalesce(platform_name,'全部') as platform_name,
    count(event_time) as sy_pv,
    count(distinct user_id) as sy_uv
from t1
where event_name='HomePage_View'
group by grouping sets (
    (dt),
    (dt,platform_name)
     )
),

-- 福利页浏览
t3 as (
select
    dt,
    coalesce(platform_name,'全部') as platform_name,
    count(event_time) as fly_pv,
    count(distinct user_id) as fly_uv
from t1
where event_name='Welfare_Page_View'
group by grouping sets (
    (dt),
    (dt,platform_name)
     )
),


-- 主页金刚区点击
t4 as (
select
    '主页金刚区点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(function_button_type,'全部') as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='HomePage_Featured_Section_Click'
    and function_button_type is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,function_button_type),
    (dt,platform_name,function_button_type)
    )

union all
-- 大牌品牌点击
select
    '大牌品牌点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(brand_name,'全部') as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='BigBrand_Brand_Click'
    and brand_name is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,brand_name),
    (dt,platform_name,brand_name)
    )

union all
select
    '大牌轮播图点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    '全部' as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='BigBrand_Carousel_Click'
group by grouping sets (
    (dt),
    (dt,platform_name)
    )

union all
select
    '大牌美团红包点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    '全部' as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='BigBrand_Meituan_RedPacket_Click'
group by grouping sets (
    (dt),
    (dt,platform_name)
    )

union all
select
    '大牌饿了么红包点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    '全部' as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='BigBrand_Eleme_RedPacket_Click'
group by grouping sets (
    (dt),
    (dt,platform_name)
    )

union all
select
    '新人有礼专区点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(newuser_gift_area,'全部') as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='HomePage_Newcomer_Gift_Click'
    and newuser_gift_area is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,newuser_gift_area),
    (dt,platform_name,newuser_gift_area)
    )

union all
select
    '主页营销区域' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(market_area,'全部') as button_name,
    count(if(event_name='HomePage_Marketing_ex',event_time,null)) as bg_cnt,
    count(distinct if(event_name='HomePage_Marketing_ex',user_id,null)) as bg_uv,
    count(if(event_name='HomePage_Marketing_Click',event_time,null)) as dj_cnt,
    count(distinct if(event_name='HomePage_Marketing_Click',user_id,null)) as dj_uv
from t1
where event_name in ('HomePage_Marketing_ex','HomePage_Marketing_Click')
    and market_area is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,market_area),
    (dt,platform_name,market_area)
    )

union all
select
    '主页banner' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    '全部' as button_name,
    count(if(event_name='HomePage_Banner_ex',event_time,null)) as bg_cnt,
    count(distinct if(event_name='HomePage_Banner_ex',user_id,null)) as bg_uv,
    count(if(event_name='HomePage_Banner_Click',event_time,null)) as dj_cnt,
    count(distinct if(event_name='HomePage_Banner_Click',user_id,null)) as dj_uv
from t1
where event_name in ('HomePage_Banner_ex','HomePage_Banner_Click')
group by grouping sets (
    (dt),
    (dt,platform_name)
    )

union all
select
    '福利页头图点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    '全部' as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name='Welfare_Header_Image_Click'
group by grouping sets (
    (dt),
    (dt,platform_name)
    )

union all
select
    '福利页品牌广告位点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(brand_name,'全部') as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name ='Welfare_Brand_Advertisement_Click'
    and brand_name is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,brand_name),
    (dt,platform_name,brand_name)
    )

union all
select
    '福利折扣天天领点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(discount_brand,'全部') as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name ='Welfare_Daily_Discount_Claim_Click'
    and discount_brand is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,discount_brand),
    (dt,platform_name,discount_brand)
    )

union all
select
    '福利侧面开箱点击' as tp,
    dt,
    coalesce(platform_name,'全部') as platform_name,
    coalesce(button_name,'全部') as button_name,
    0 as bg_cnt,
    0 as bg_uv,
    count(event_time) as dj_cnt,
    count(distinct user_id) as dj_uv
from t1
where event_name ='Welfare_Side_Unboxing_Click'
    and button_name is not null
group by grouping sets (
    (dt),
    (dt,platform_name),
    (dt,button_name),
    (dt,platform_name,button_name)
    )
)


-- 8月月日均
select
    `类型`,
    `平台名称`,
    `模块或按钮名称`,
    avg(`首页PV`) as `首页PV`,
    avg(`首页UV`) as `首页UV`,
    avg(`福利页首页PV`) as `福利页首页PV`,
    avg(`福利页首页UV`) as `福利页首页UV`,
    avg(`曝光量`) as `曝光量`,
    avg(`曝光用户量`) as `曝光用户量`,
    avg(`点击量`) as `点击量`,
    avg(`点击用户量`) as `点击用户量`  
from (
-- 日数据    
select
    tp as `类型`,
    t4.dt as `统计日期`,
    t4.platform_name as `平台名称`,
    button_name as `模块或按钮名称`,
    sy_pv as `首页PV`,
    sy_uv as `首页UV`,
    fly_pv as `福利页首页PV`,
    fly_uv as `福利页首页UV`,
    bg_cnt as `曝光量`,
    bg_uv as `曝光用户量`,
    dj_cnt as `点击量`,
    dj_uv as `点击用户量`
from t4 
left join t2 on t4.dt=t2.dt and t4.platform_name=t2.platform_name
left join t3 on t4.dt=t3.dt and t4.platform_name=t3.platform_name
) a
group by 1,2,3

================ 页面主要埋点位置曝光和点击
