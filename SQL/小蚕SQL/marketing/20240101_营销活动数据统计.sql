-- 统计领取使用和收益
select
    substr(dat,1,7) as `年月`,
    redpacket_type as `活动类型`,
    count(redpacket_id) as `发放红包量`,
    count(if(b.order_status in (2,8) and redpacket_use_status=2,redpacket_id,null)) as `使用红包量`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,b.profit,null)) as `使用红包有效订单利润`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,b.redpacket_amt,null)) as `使用红包金额`
from (
-- 红包使用记录
select 
    cast(dt as string) as dat,
    redpacket_id,
    redpacket_use_status, -- 1：未使用 2：已使用 3：已失效
    user_id,
    order_id,
    case when redpacket_type=1 then '后台红包'
        when redpacket_type=2 then '拼手气红包'
        when redpacket_type=3 then '红包雨抽奖'
        when redpacket_type=4 then '积分兑换'
        when redpacket_type=5 then '用户召回活动'
        when redpacket_type=6 then '会员限时升级礼包'
        when redpacket_type=7 then '会员每日红包活动'
        when redpacket_type=8 then '挑战赛'
        when redpacket_type=9 then '抽奖活动'
        when redpacket_type=10 then '春节签到领红包(已下线)'
        when redpacket_type=11 then '趣淘用户注册领取红包'
        when redpacket_type=12 then '嗨皮用户注册领取红包'
        when redpacket_type=13 then '新用户下单奖励红包'
        when redpacket_type=14 then '社群晒图'
        when redpacket_type=15 then '团长包红包'
    end as redpacket_type
from dwd.dwd_sr_market_redpack_use_record
where cast(dt as string) between '2024-01-01' and '2024-09-20'
    ) a
left join 
-- 订单
    (
    select 
        order_id,
        profit,
        real_rebate_amt,
        redpacket_amt,
        order_status
    from dwd.dwd_sr_order_promotion_order 
    where cast(dt as string) between '2024-01-01' and '2024-09-20'
        and length(order_id)>=10
    ) b
on a.order_id=b.order_id
group by 1,2;



=========================== 用户与店铺距离
show create table test.test_client_user_location;

ST_Distance_Sphere(x_lng, x_lat, y_lng, y_lat)

select date_sub(current_date(),interval 6 day);


-- 数据量：10,415,889
select count(*) from test.test_client_user_location;

-- 更新时间是最近7天数据量：1,059,683
select count(*) from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day);

-- 是否存在同一天内一个用户多条数据（没有）
select date(created_at) as dat,silk_id,count(1) as cnt from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1,2
having count(1)>1;


-- 最近7天访问用户
with t as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
        -- 计算距离经纬度
--         (select longitude as star_lon,
--             latitude as star_lat 
-- from dim.dim_silkworm_explore_store
--         ) b
(select '浙帮人·面馆' as store_name,'120.17092600000001' as star_lon,'30.253997000000005' as star_lat
union all
select '鳗享屋·和牛·寿喜烧' as store_name,'120.37642700000004' as star_lon,'30.291015000000016' as star_lat
union all
select 'ITAMA-TEA鲜萃茶工坊(龙湖滨江天街店)' as store_name,'120.218471' as star_lon,'30.214333' as star_lat
union all
select '优壹佳-延边朝鲜族料理(中山北路店)' as store_name,'120.175577' as star_lon,'30.267724' as star_lat
) b
    on 1=1
),

-- 下单
t2 as (
select
    user_id,count(order_id) finished_num
from dwd.dwd_sr_silkworm_explore_order
where dt between '2024-06-18' and date_sub(current_date,1)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
    and status in (5,19,20)
group by user_id
)


select   
    store_name,
    silk_id
from t inner join t2 on t.silk_id<>t2.user_id
where distance<=5000 -- 5公里内
group by 1,2
;



===========================
-- 日期维表
show create table dim.dim_silkworm_date;
select * from dim.dim_silkworm_date;

=================== 营销活动效果评估
show create table dim.dim_silkworm_user;

-- 有累计有效订单量，无首次有效下单时间。24年1月1日前，有3776条，之后没有
select
count(*)
from dim.dim_silkworm_user
where substr(register_time,1,10)>='2024-01-01'
    and accu_valid_order_num>0
    and substr(first_valid_order_time,1,10)='1970-01-01'
limit 10;

-- 每日注册用户量&有效用户&流失用户
select
    substr(register_time,1,10) `注册日期`,
    count(1) `注册用户量`,
    count(if(inviter_user_id>0,user_id,null)) `团长拉新用户量`,
    count(if(inviter_user_id=0,user_id,null)) `自然量`,
    count(if(substr(first_valid_order_time,1,10)<>'1970-01-01',user_id,null)) `有效用户量`,
    count(if(substr(first_valid_order_time,1,10)<>'1970-01-01' and inviter_user_id>0,user_id,null)) `团长拉新有效用户量`,
    count(if(substr(first_valid_order_time,1,10)<>'1970-01-01' and inviter_user_id=0,user_id,null)) `自然增长有效用户量`,
    count(if(datediff(date_sub(current_date(),interval 1 day),cast(latest_login_time as datetime))>=30,user_id,null)) `流失用户量(访问)` -- 30天内未登录
    ,count(if(datediff(date_sub(current_date(),interval 1 day),cast(latest_login_time as datetime))>=30 and inviter_user_id>0,user_id,null)) `团长拉新流失用户量(访问)` -- 30天内未登录
    ,count(if(datediff(date_sub(current_date(),interval 1 day),cast(latest_login_time as datetime))>=30 and inviter_user_id=0,user_id,null)) `自然增长流失用户量(访问)` -- 30天内未登录
    ,count(if(datediff(date_sub(current_date(),interval 1 day),cast(latest_valid_order_time as datetime))>=30,user_id,null)) `流失用户量(下单)` -- 30天内无有效下单
    ,count(if(datediff(date_sub(current_date(),interval 1 day),cast(latest_valid_order_time as datetime))>=30 and inviter_user_id>0,user_id,null)) `团长拉新流失用户量(下单)` -- 30天内无有效下单
    ,count(if(datediff(date_sub(current_date(),interval 1 day),cast(latest_valid_order_time as datetime))>=30 and inviter_user_id=0,user_id,null)) `自然增长流失用户量(下单)` -- 30天内无有效下单
from dim.dim_silkworm_user
where substr(register_time,1,10)>='2024-01-01'
group by 1;



-- 每日注册用户3日&7日&14日&30日内累计下单、有效下单、红包支出、利润
select
    register_date as `注册日期`,
    user_type,
    count(distinct a.user_id) as `注册用户量`,
    count(distinct if(datediff(order_date,register_date)<=3 and b.order_status in (2,8),a.user_id,null)) as `3日内累计有效下单用户量`,
    count(distinct if(datediff(order_date,register_date)<=3 and b.order_status in (2,8),b.order_id,null)) as `3日内累计有效下单量`,
    sum(if(datediff(order_date,register_date)<=3 and b.order_status in (2,8),b.redpacket_amt,0)) as `3日内累计红包使用量`,
    sum(if(datediff(order_date,register_date)<=3 and b.order_status in (2,8),b.profit,0)) as `3日内累计有效订单利润`,
    count(distinct if(datediff(order_date,register_date)<=7 and b.order_status in (2,8),a.user_id,null)) as `7日内累计有效下单用户量`,
    count(distinct if(datediff(order_date,register_date)<=7 and b.order_status in (2,8),b.order_id,null)) as `7日内累计有效下单量`,
    sum(if(datediff(order_date,register_date)<=7 and b.order_status in (2,8),b.redpacket_amt,0)) as `7日内累计红包使用量`,
    sum(if(datediff(order_date,register_date)<=7 and b.order_status in (2,8),b.profit,0)) as `7日内累计有效订单利润`,
    count(distinct if(datediff(order_date,register_date)<=14 and b.order_status in (2,8),a.user_id,null)) as `14日内累计有效下单用户量`,
    count(distinct if(datediff(order_date,register_date)<=14 and b.order_status in (2,8),b.order_id,null)) as `14日内累计有效下单量`,
    sum(if(datediff(order_date,register_date)<=14 and b.order_status in (2,8),b.redpacket_amt,0)) as `14日内累计红包使用量`,
    sum(if(datediff(order_date,register_date)<=14 and b.order_status in (2,8),b.profit,0)) as `14日内累计有效订单利润`,
    count(distinct if(datediff(order_date,register_date)<=30 and b.order_status in (2,8),a.user_id,null)) as `30日内累计有效下单用户量`,
    count(distinct if(datediff(order_date,register_date)<=30 and b.order_status in (2,8),b.order_id,null)) as `30日内累计有效下单量`,
    sum(if(datediff(order_date,register_date)<=30 and b.order_status in (2,8),b.redpacket_amt,0)) as `30日内累计红包使用量`,
    sum(if(datediff(order_date,register_date)<=30 and b.order_status in (2,8),b.profit,0)) as `30日内累计有效订单利润`
from
(select
    user_id,
    str_to_date(substr(register_time,1,10),'%Y-%m-%d') as register_date,
    if(inviter_user_id=0,'自然增长','团长拉新') as user_type
from dim.dim_silkworm_user
where substr(register_time,1,10)>='2024-01-01'
) a
left join
-- 订单
(select
    user_id,
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date,
    order_id,
    order_status,
    redpacket_amt,
    profit
from dwd.dwd_sr_order_promotion_order
where cast(dt as string)>='2024-01-01'
    and substr(order_time,1,10)>='2024-01-01'
) b on a.user_id=b.user_id
group by 1,2;
    

-- 团长拉新支出
select
    register_date `注册日期`,
    sum(case when accu_valid_order_num_3d>=2 then 13
            when accu_valid_order_num_3d=1 then 3
        else 0 end) as `3日内累计团长拉新奖励`,
    sum(case when accu_valid_order_num_7d>=2 then 13
            when accu_valid_order_num_7d=1 then 3
        else 0 end) as `7日内累计团长拉新奖励`,
    sum(case when accu_valid_order_num_14d>=2 then 13
            when accu_valid_order_num_14d=1 then 3
        else 0 end) as `14日内累计团长拉新奖励`,
    sum(case when accu_valid_order_num_30d>=2 then 13
            when accu_valid_order_num_30d=1 then 3
        else 0 end) as `30日内累计团长拉新奖励`
from
(
select
    a.register_date,
    a.user_id,
    count(distinct if(datediff(order_date,register_date)<=3 and b.order_status in (2,8),b.order_id,null)) as accu_valid_order_num_3d,
    count(distinct if(datediff(order_date,register_date)<=7 and b.order_status in (2,8),b.order_id,null)) as accu_valid_order_num_7d,
    count(distinct if(datediff(order_date,register_date)<=14 and b.order_status in (2,8),b.order_id,null)) as accu_valid_order_num_14d,
    count(distinct if(datediff(order_date,register_date)<=30 and b.order_status in (2,8),b.order_id,null)) as accu_valid_order_num_30d
from
(select
    user_id,
    str_to_date(substr(register_time,1,10),'%Y-%m-%d') as register_date
from dim.dim_silkworm_user
where substr(register_time,1,10)>='2024-01-01'
    and inviter_user_id>0
) a
left join
-- 订单
(select
    user_id,
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date,
    order_id,
    order_status,
    redpacket_amt,
    profit
from dwd.dwd_sr_order_promotion_order
where cast(dt as string)>='2024-01-01'
    and substr(order_time,1,10)>='2024-01-01'
) b on a.user_id=b.user_id
group by 1,2
) c
group by 1
;


-- 订单量
select
    -- str_to_date(substr(order_time,1,10),'%Y-%m-%d') as `下单日期`,
    month(str_to_date(substr(order_time,1,10),'%Y-%m-%d')) as `下单月份`,
    -- order_status `订单状态`,
    count(order_id) as `下单量`,
    count(distinct user_id) as `下单用户量`,
    sum(profit) as `利润`
from dwd.dwd_sr_order_promotion_order
where cast(dt as string)>='2024-01-01'
    and substr(order_time,1,10)>='2024-01-01'
    and order_status in (2,8)
group by 1,2
;

-- 当月注册新用户下单
select
    month(register_date) as `注册月份`,
    user_type,
    count(distinct if(date_diff('month',order_date,register_date)=0 and b.order_status in (2,8),a.user_id,null)) as `下单用户量`,
    count(distinct if(date_diff('month',order_date,register_date)=0 and b.order_status in (2,8),b.order_id,null)) as `下单量`,
    sum(if(date_diff('month',order_date,register_date)=0 and b.order_status in (2,8),b.profit,0)) as `有效订单利润`
from
(select
    user_id,
    str_to_date(substr(register_time,1,10),'%Y-%m-%d') as register_date,
    if(inviter_user_id=0,'自然增长','团长拉新') as user_type
from dim.dim_silkworm_user
where substr(register_time,1,10)>='2024-01-01'
) a
left join
-- 订单
(select
    user_id,
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date,
    order_id,
    order_status,
    redpacket_amt,
    profit
from dwd.dwd_sr_order_promotion_order
where cast(dt as string)>='2024-01-01'
    and substr(order_time,1,10)>='2024-01-01'
) b on a.user_id=b.user_id
group by 1,2;



===========
============= 杭州探店店铺
show create table dim.dim_silkworm_explore_store;

select * from dim.dim_silkworm_explore_store limit 10;

show create table dwd.dwd_sr_silkworm_explore_promotion;

select
    a.store_id `店铺ID`,
    a.store_name `店铺名称`,
    a.sub_category_type `店铺二级标签`,
    a.city_name `城市`,
    a.county_name `区县`,
    a.business_district `商圈`,
    a.address_detail `店铺详细地址`,
    if(b.store_id is not null,'有在线活动','无在线活动') as `店铺状态`
from
(select
    store_id,store_name,sub_category_type,city_name,county_name,business_district,address_detail
from dim.dim_silkworm_explore_store
where status=1
    and city_name='杭州市'
) a 
left join (
select
    store_id
from dwd.dwd_sr_silkworm_explore_promotion
where status=1
    and (get_json_string(replace(cast(video as string), '\\', '\\'), '$.Url') is null
            or get_json_string(replace(cast(video as string), '\\', '\\'), '$.Url')=''
        )
group by 1
) b on a.store_id=b.store_id
;

SELECT
    store_id,
    video,
    get_json_string(replace(cast(video as string), '\\', '\\\\'), '$.Url') AS url
FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE status = 1
  AND video IS NOT NULL
LIMIT 100;



==============
-- 红包类型花费
select
    substr(order_audit_finish_time,1,7) as `年月`,
    redpacket_type as `活动类型`,
    count(redpacket_id) as `发放红包量`,
    count(if(b.order_status in (2,8) and redpacket_use_status=2,redpacket_id,null)) as `使用红包量`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,(b.profit * 100),null)) as `使用红包有效订单利润`,
    sum(if(b.order_status in (2,8) and redpacket_use_status=2,(b.redpacket_amt * 100),null)) as `使用红包金额`
from (
-- 红包使用记录
select 
    dt as dat,
    redpacket_id,
    redpacket_use_status, -- 1：未使用 2：已使用 3：已失效
    user_id,
    order_id,
    case when redpacket_type=1 then '后台红包'
        when redpacket_type=2 then '拼手气红包'
        when redpacket_type=3 then '红包雨抽奖'
        when redpacket_type=4 then '积分兑换'
        when redpacket_type=5 then '用户召回活动'
        when redpacket_type=6 then '会员限时升级礼包'
        when redpacket_type=7 then '会员每日红包活动'
        when redpacket_type=8 then '挑战赛'
        when redpacket_type=9 then '抽奖活动'
        when redpacket_type=10 then '春节签到领红包(已下线)'
        when redpacket_type=11 then '趣淘用户注册领取红包'
        when redpacket_type=12 then '嗨皮用户注册领取红包'
        when redpacket_type=13 then '新用户下单奖励红包'
        when redpacket_type=14 then '社群晒图'
        when redpacket_type=15 then '团长包红包'
    end as redpacket_type
from dwd.dwd_sr_market_redpack_use_record
where cast(dt as string) between '2024-01-01' and '2024-11-06'
  and redpacket_type<>10
    ) a
left join 
-- 订单
    (
    select 
        order_id,
        profit,
        real_rebate_amt,
        redpacket_amt,
        order_status,
        order_audit_finish_time
    from dwd.dwd_sr_order_promotion_order 
    where cast(dt as string) between '2024-01-01' and '2024-11-06'
        and length(order_id)>=10
    ) b
on a.order_id=b.order_id
group by 1,2
;



========
-- 取发布活动商务
select
    a.bd_id,
    c.user_nickname `花名`,
    a.store_id `店铺ID`,
    b.store_name `店铺名称`,
    b.phone `联系电话`,
    b.address_detail `店铺地址详情`
    -- count(distinct a.store_id) as `店铺数` -- 1085
from
-- 指定时间范围内发布活动
(select 
    bd_id,
    store_id
from dwd.dwd_sr_store_promotion
where cast(dt as string) between '2024-10-01' and '2024-11-13' -- 时间范围根据需求自取
group by 1,2
) a
-- 店铺
inner join dim.dim_silkworm_store b on a.store_id=b.store_id
inner join 
-- 花名
-- 指定bd
(select 
    bd_id,
    user_nickname 
from dim.dim_silkworm_staff
where bd_id in (656 , 669 , 841 , 842 , 851 , 889 , 950 , 1015 , 1016 , 1084, 1255, 1256, 1275, 1350, 1364, 1431)
group by 1,2) c
on a.bd_id=c.bd_id
;


================== 12月参与打卡赛用户
show create table dws.dws_sr_silkworm_challenge_td;

-- 12月参与打卡挑战赛用户量：32369
select
    array_length(array_unique_agg(par_user_list)) as par_user_id
from dws.dws_sr_silkworm_challenge_td
where cast(dt as date) between '2024-12-01' and '2024-12-16'
    and challenge_type=1 -- 打卡
;

-- 12月参与打卡挑战赛完成订单量：298822
select
    sum(order_num_dt) as tot_order_num
from dws.dws_sr_silkworm_challenge_td
where cast(dt as date) between '2024-12-01' and '2024-12-16'
    and challenge_type=1 -- 打卡
;

select 298822/32369  
;

-- 12月参与打卡赛用户
with t1 as (
select
    unnest as user_id
from dws.dws_sr_silkworm_challenge_td,unnest(par_user_list) as unnest
where cast(dt as date) between '2024-12-01' and '2024-12-16'
    and challenge_type=1 -- 打卡
group by 1
    ),

-- 订单
t2 as (
select
    user_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-10-01' and '2024-11-30'
    and substr(order_time,1,10) between '2024-11-01' and '2024-11-30'
group by 1
)

select
    sum(valid_order_num) as valid_order_num,
    sum(order_num) as order_num
from t1 inner join t2 on t1.user_id=t2.user_id;


select
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(distinct user_id) as order_unum, -- 用户量
    count(if(order_status in (2,8),auto_id,null))/count(distinct user_id)
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-11-01' and '2024-12-17'
    and substr(order_time,1,10) between '2024-12-01' and '2024-12-17'
;


select
    order_num `完单量`,count(user_id) as `用户量`
from
(select
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1) a
group by 1;



======= 挑战赛统计

with t1 as (
select
    unnest as user_id
from dws.dws_sr_silkworm_challenge_td,unnest(par_user_list) as unnest
where cast(dt as date) between '2024-12-01' and '2024-12-16'
    and challenge_type=1 -- 打卡
group by 1
    ),

-- 订单
t2 as (
select
    user_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-10-01' and '2024-11-30'
    and substr(order_time,1,10) between '2024-11-01' and '2024-11-30'
group by 1
)

select
    sum(valid_order_num) as valid_order_num,
    sum(order_num) as order_num
from t1 inner join t2 on t1.user_id=t2.user_id;


-- 人均下单量
select
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(distinct user_id) as order_unum, -- 用户量
    count(if(order_status in (2,8),auto_id,null))/count(distinct user_id)
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-10-01' and '2024-11-30'
    and substr(order_time,1,10) between '2024-11-01' and '2024-11-30'
;


































