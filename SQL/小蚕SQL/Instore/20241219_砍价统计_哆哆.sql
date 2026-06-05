大禾，麻烦帮忙拉一份砍价的数据，我一会儿开完会和你对一下

数据1:
时间：2024-11-20～2024-12-17
城市：杭州、上海
维度：每日
数据：
探店主页的PV&UV、砍价主页的PV&UV、砍价活动详情页PV&UV、 活动详情页分享曝光量/UV、每日砍价人数（去重）、每日所有活动总砍价次数、砍价活动数、砍价名额数、砍价生成订单数、下单人数、当日下单中已支付订单数 当日下单中已核销订单数 


数据2:
时间：2024-12.11～2024-12-17
城市：杭州、上海
维度：每日
数据：
每日参与了砍价的用户ID、参与砍价的用户在当日浏览了x个活动、砍了x个活动



===== part2
-- 砍价记录
with t1 as (
select
	date(create_time) create_date,
	user_id,
	promotion_id
from dwd.dwd_sr_silkworm_explore_bargain_record
where date(create_time) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
	and status=1
group by 1,2,3
),


-- 活动
t2 as (
select
    promotion_id,
    if(substr(cast(city_code as string),1,4)='3101','上海','杭州') as city_name
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(cast(city_code as string),1,4) in ('3101','3301')
),


-- 访问砍价活动详情页
t3 as (
select dt,user_id,activity_id,count(1) as cnt from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_name='StoreDiscovery_Activity_Details_Ex' -- 探店活动详情页曝光
    and activity_type='砍价活动'
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
)

select
	t1.create_date as `统计日期`,
	t2.city_name `城市`,
	t1.user_id as `砍价用户ID`,
	if(t3.user_id is null,'否','是') as `是否访问砍价详情页`,
	count(distinct t3.activity_id) as `浏览砍价活动量`,
	count(distinct t1.promotion_id) as `砍价活动量`
from t1 inner join t2 on t1.promotion_id=t2.promotion_id
left join t3 on t1.create_date=t3.dt and t1.user_id=t3.user_id and t2.promotion_id=t3.activity_id
group by 1,2,3,4;



-- 砍价记录
with t1 as (
select
	date(create_time) create_date,
	user_id,
	promotion_id
from dwd.dwd_sr_silkworm_explore_bargain_record
where date(create_time) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
	and status=1
group by 1,2,3
),


-- 活动
t2 as (
select
    promotion_id,
    if(substr(cast(city_code as string),1,4)='3101','上海','杭州') as city_name
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(cast(city_code as string),1,4) in ('3101','3301')
)


select
	t1.create_date as `统计日期`,
	t2.city_name `城市`,
	t1.user_id as `砍价用户ID`,
	t1.promotion_id
from t1 inner join t2 on t1.promotion_id=t2.promotion_id

--

==== part 1
-- 访问
with t1 as (
select 
	dt,
	if(substr(county_id,1,4)='3101','上海','杭州') as city_name,
	sum(if(event_name='StoreDiscovery_Homepage_View',1,0)) as td_pv, -- 探店主页PV
	count(distinct if(event_name='StoreDiscovery_Homepage_View',user_id,null)) as td_uv, -- 探店主页UV
	sum(if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',1,0)) as kjd_pv, -- 砍价活动详情页PV
	count(distinct if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',user_id,null)) as kjd_uv, -- 砍价活动详情页UV
	sum(if(event_name='Invite_Bargain_Windows_Ex',1,0)) as hd_bg_num, -- 活动详情页分享曝光量
	count(distinct if(event_name='Invite_Bargain_Windows_Ex',user_id,null)) as hd_bg_uv, -- 活动详情页分享曝光UV
	sum(if(event_name='Bargain_Homepage_Ex',1,0)) as kj_pv, -- 砍价主页PV
	count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) as kj_uv -- 砍价主页UV
from ods.ods_sr_traffic_event_log
where dt between '2024-12-01' and date_sub(current_date(),interval 1 day)
    and event_name in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_Ex','Invite_Bargain_Windows_Ex','Bargain_Homepage_Ex')
    and substr(county_id,1,4) in ('3101','3301')
group by 1,2
),

-- 砍价参与记录
t2 as (
select
	date(create_time) create_date,
	user_id,
	promotion_id
from dwd.dwd_sr_silkworm_explore_bargain_record
where date(create_time) between '2024-11-20' and date_sub(current_date(),interval 1 day)
	and status=1
),


-- 活动
t3 as (
select
	dt,
    promotion_id,
    if(substr(cast(city_code as string),1,4)='3101','上海','杭州') as city_name,
    tot_promotion_quota
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(cast(city_code as string),1,4) in ('3101','3301')
    and promotion_type=5 -- 砍价 
),


-- 参与砍价统计
t4 as (
select
	create_date,
	city_name,
	count(distinct user_id) as kj_user_num, -- 砍价人数
	count(1) as kj_cnt -- 砍价次数
from t2 inner join t3 on t2.promotion_id=t3.promotion_id
group by 1,2
),

-- 砍价活动和名额
t5 as (
select
	dt,
	city_name,
	count(1) as kj_pronum, -- 砍价活动数
	sum(tot_promotion_quota) as kj_quota -- 砍价活动名额
from t3
where dt between '2024-11-20' and date_sub(current_date(),interval 1 day)
group by 1,2
),


-- 砍价订单 
t6 as (
select
	a.dt,
	city_name,
	count(1) as order_num, -- 砍价报名量
	count(distinct user_id) as order_user_num, -- 砍价报名用户量
	count(if(substr(pay_time,1,10)<>'1970-01-01',order_id,null)) as pay_order_num, -- 砍价支付订单量
	count(if(substr(verify_time,1,10)<>'1970-01-01',order_id,null)) as verify_order_num -- 砍价核销订单量
from
	(select dt,
	    store_promotion_id,
	    create_time,
	    pay_time,
	    verify_time,
	    order_id,
	    user_id
	from dwd.dwd_sr_silkworm_explore_order
	where dt between '2024-11-20' and date_sub(current_date(),interval 1 day)
	    and promotion_type=5 -- 砍价
	) a inner join t3 on a.store_promotion_id=t3.promotion_id
group by 1,2
)


select
	dt,
	city_name,
	sum(td_pv) as `探店主页PV`,
	sum(td_uv) as `探店主页UV`,
	sum(kj_pv) as `砍价主页PV`,
	sum(kj_uv) as `砍价主页UV`,
	sum(kjd_pv) as `砍价活动详情页PV`,
	sum(kjd_uv) as `砍价活动详情页UV`,
	sum(hd_bg_num) as `活动详情页分享曝光量`,
	sum(hd_bg_uv) as `活动详情页分享曝光UV`,
	sum(kj_user_num) as `砍价人数`,
	sum(kj_cnt) as `砍价次数`,
	sum(kj_pronum) as `砍价活动数`,
	sum(kj_quota) as `砍价活动名额`,
	sum(order_num) as `砍价报名量`,
	sum(order_user_num) as `砍价报名用户量`,
	sum(pay_order_num) as `砍价支付订单量`,
	sum(verify_order_num) as `砍价核销订单量`
from
(select
	dt,
	city_name,
	td_pv, -- 探店主页PV
	td_uv, -- 探店主页UV
	kjd_pv, -- 砍价活动详情页PV
	kjd_uv, -- 砍价活动详情页UV
	hd_bg_num, -- 活动详情页分享曝光量
	hd_bg_uv, -- 活动详情页分享曝光UV
	kj_pv, -- 砍价主页PV
	kj_uv, -- 砍价主页UV 
	0 kj_user_num, -- 砍价人数
	0 kj_cnt, -- 砍价次数
	0 kj_pronum, -- 砍价活动数
	0 kj_quota, -- 砍价活动名额
	0 order_num, -- 砍价报名量
	0 order_user_num, -- 砍价报名用户量
	0 pay_order_num, -- 砍价支付订单量
	0 verify_order_num -- 砍价核销订单量
from t1

union all

select
	create_date as dt,
	city_name,
	0,0,0,0,0,0,0,0,
	kj_user_num, -- 砍价人数
	kj_cnt, -- 砍价次数
	0,0,0,0,0,0
from t4

union all

select
	dt,
	city_name,
	0,0,0,0,0,0,0,0,0,0,
	kj_pronum, -- 砍价活动数
	kj_quota, -- 砍价活动名额
	0,0,0,0
from t5

union all

select
	dt,
	city_name,
	0,0,0,0,0,0,0,0,0,0,0,0,
	order_num, -- 砍价报名量
	order_user_num, -- 砍价报名用户量
	pay_order_num, -- 砍价支付订单量
	verify_order_num -- 砍价核销订单量
from t6
) tot
group by 1,2;









