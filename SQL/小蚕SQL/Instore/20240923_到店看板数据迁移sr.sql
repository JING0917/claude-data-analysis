-- part1到店业务整体数据
select 
	statisticsdate as "统计日期",
	sum(newuser_num) as "新用户数",
	sum(explore_newuser_num) as "探店新用户数",
	sum(welfare_newuser_num) as "公益新用户数",
	sum(yd_newuser_num) as "昨日新用户数",
	sum(yd_explore_newuser_num) as "昨日探店新用户数",
	sum(yd_welfare_newuser_num) as "昨日公益新用户数",
	sum(view_user_num) as "活跃用户数",
	sum(explore_view_user_num) as "探店活跃用户数",
	sum(welfare_view_user_num) as "公益活跃用户数",
	sum(yd_view_user_num) as "昨日活跃用户数",
	sum(yd_explore_view_user_num) as "昨日探店活跃用户数",
	sum(yd_welfare_view_user_num) as "昨日公益活跃用户数",
	sum(valid_newuser_num) as "新增有效用户数",
	sum(valid_explore_newuser_num) as "探店新增有效用户数",
	sum(valid_welfare_newuser_num) as "公益新增有效用户数",
	sum(yd_valid_newuser_num) as "昨日新增有效用户数",
	sum(yd_valid_explore_newuser_num) as "昨日探店新增有效用户数",
	sum(yd_valid_welfare_newuser_num) as "昨日公益新增有效用户数",
	sum(newdaren_num) as "解锁达人用户数",
	sum(yd_newdaren_num) as "昨日解锁达人用户数",
	sum(first_order_user_num) as "新增首单用户数",
	sum(first_explore_order_user_num) as "探店新增首单用户数",
	sum(first_welfare_order_user_num) as "公益新增首单用户数",
	sum(yd_first_order_user_num) as "昨日新增首单用户数",
	sum(yd_first_explore_order_user_num) as "昨日探店新增首单用户数",
	sum(yd_first_welfare_order_user_num) as "昨日公益新增首单用户数",
	sum(onlin_store_num) as "在线店铺数",
	sum(explore_onlin_store_num) as "探店在线店铺数",
	sum(welfare_onlin_store_num) as "公益在线店铺数",
	sum(yd_onlin_store_num) as "昨日在线店铺数",
	sum(yd_explore_onlin_store_num) as "昨日探店在线店铺数",
	sum(yd_welfare_onlin_store_num) as "昨日公益在线店铺数",
	sum(online_promotion_num) as "在线活动数",
	sum(explore_online_promotion_num) as "探店在线活动数",
	sum(welfare_online_promotion_num) as "公益在线活动数",
	sum(yd_online_promotion_num) as "昨日在线活动数",
	sum(yd_explore_online_promotion_num) as "昨日探店在线活动数",
	sum(yd_welfare_online_promotion_num) as "昨日公益在线活动数",
	sum(online_promotion_quota) as "在线活动名额",
	sum(explore_online_promotion_quota) as "探店在线活动名额",
	sum(welfare_online_promotion_quota) as "公益在线活动名额",
	sum(yd_online_promotion_quota) as "昨日在线活动名额",
	sum(yd_explore_online_promotion_quota) as "昨日探店在线活动名额",
	sum(yd_welfare_online_promotion_quota) as "昨日公益在线活动名额",
	sum(order_num) as "下单量",
	sum(explore_order_num) as "探店下单量",
	sum(welfare_order_num) as "公益下单量",
	sum(yd_order_num) as "昨日下单量",
	sum(yd_explore_order_num) as "昨日探店下单量",
	sum(yd_welfare_order_num) as "昨日公益下单量",
	sum(valid_order_num) as "销单量",
	sum(valid_explore_order_num) as "探店销单量",
	sum(valid_welfare_order_num) as "公益销单量",
	sum(yd_valid_order_num) as "昨日销单量",
	sum(yd_valid_explore_order_num) as "昨日探店销单量",
	sum(yd_valid_welfare_order_num) as "昨日公益销单量",
	sum(verify_order_num) as "核销订单量",
	sum(explore_verify_order_num) as "探店核销订单量",
	sum(welfare_verify_order_num) as "公益核销订单量",
	sum(yd_verify_order_num) as "昨日核销订单量",
	sum(yd_explore_verify_order_num) as "昨日探店核销订单量",
	sum(yd_welfare_verify_order_num) as "昨日公益核销订单量",
	sum(finish_order_num) as "完单量",
	sum(explore_finish_order_num) as "探店完单量",
	sum(welfare_finish_order_num) as "公益完单量",
	sum(yd_finish_order_num) as "昨日完单量",
	sum(yd_explore_finish_order_num) as "昨日探店完单量",
	sum(yd_welfare_finish_order_num) as "昨日公益完单量",
	sum(upload_order_num) as "待上传订单量",
	sum(explore_upload_order_num) as "探店待上传订单量",
	sum(welfare_upload_order_num) as "公益待上传订单量",
	sum(yd_upload_order_num) as "昨日待上传订单量",
	sum(yd_explore_upload_order_num) as "昨日探店待上传订单量",
	sum(yd_welfare_upload_order_num) as "昨日公益待上传订单量"
from dws.dws_ck_order_explore_dashboard_d
where toDate(dt)=$END_DATE$
group by statisticsdate



-- 0元到店订单
with t1 as (
select
    date(dt) as order_date,
    order_id,
    user_id,
    promotion_type,
    str_to_date(substr(pay_time,1,10),'%Y-%m-%d') as pay_date, -- 支付日期
    str_to_date(substr(finish_time,1,10),'%Y-%m-%d') as finish_date, -- 完成日期
    str_to_date(substr(cancel_time,1,10),'%Y-%m-%d') as cancel_date, -- 取消日期
    str_to_date(substr(refund_time,1,10),'%Y-%m-%d') as refund_date, -- 售后退款日期
    str_to_date(substr(verify_time,1,10),'%Y-%m-%d') as verify_date, -- 核销日期
    status
from dwd.dwd_sr_silkworm_explore_order
where date(dt) between date_sub($END_DATE$,interval 1 day) and $END_DATE$
    and store_name not regexp '测试'
        )

select
	statisticsdate as "统计日期",
	sum(newuser_num) as "新用户数",
	sum(explore_newuser_num) as "探店新用户数",
	sum(welfare_newuser_num) as "公益新用户数",
	sum(yd_newuser_num) as "昨日新用户数",
	sum(yd_explore_newuser_num) as "昨日探店新用户数",
	sum(yd_welfare_newuser_num) as "昨日公益新用户数",
	sum(view_user_num) as "活跃用户数",
	sum(explore_view_user_num) as "探店活跃用户数",
	sum(welfare_view_user_num) as "公益活跃用户数",
	sum(yd_view_user_num) as "昨日活跃用户数",
	sum(yd_explore_view_user_num) as "昨日探店活跃用户数",
	sum(yd_welfare_view_user_num) as "昨日公益活跃用户数",
	sum(valid_newuser_num) as "新增有效用户数",
	sum(valid_explore_newuser_num) as "探店新增有效用户数",
	sum(valid_welfare_newuser_num) as "公益新增有效用户数",
	sum(yd_valid_newuser_num) as "昨日新增有效用户数",
	sum(yd_valid_explore_newuser_num) as "昨日探店新增有效用户数",
	sum(yd_valid_welfare_newuser_num) as "昨日公益新增有效用户数",
	sum(newdaren_num) as "解锁达人用户数",
	sum(yd_newdaren_num) as "昨日解锁达人用户数",
	sum(first_order_user_num) as "新增首单用户数",
	sum(first_explore_order_user_num) as "探店新增首单用户数",
	sum(first_welfare_order_user_num) as "公益新增首单用户数",
	sum(yd_first_order_user_num) as "昨日新增首单用户数",
	sum(yd_first_explore_order_user_num) as "昨日探店新增首单用户数",
	sum(yd_first_welfare_order_user_num) as "昨日公益新增首单用户数",
	sum(onlin_store_num) as "在线店铺数",
	sum(explore_onlin_store_num) as "探店在线店铺数",
	sum(welfare_onlin_store_num) as "公益在线店铺数",
	sum(yd_onlin_store_num) as "昨日在线店铺数",
	sum(yd_explore_onlin_store_num) as "昨日探店在线店铺数",
	sum(yd_welfare_onlin_store_num) as "昨日公益在线店铺数",
	sum(online_promotion_num) as "在线活动数",
	sum(explore_online_promotion_num) as "探店在线活动数",
	sum(welfare_online_promotion_num) as "公益在线活动数",
	sum(yd_online_promotion_num) as "昨日在线活动数",
	sum(yd_explore_online_promotion_num) as "昨日探店在线活动数",
	sum(yd_welfare_online_promotion_num) as "昨日公益在线活动数",
	sum(online_promotion_quota) as "在线活动名额",
	sum(explore_online_promotion_quota) as "探店在线活动名额",
	sum(welfare_online_promotion_quota) as "公益在线活动名额",
	sum(yd_online_promotion_quota) as "昨日在线活动名额",
	sum(yd_explore_online_promotion_quota) as "昨日探店在线活动名额",
	sum(yd_welfare_online_promotion_quota) as "昨日公益在线活动名额",
	sum(order_num) as "下单量",
	sum(explore_order_num) as "探店下单量",
	sum(welfare_order_num) as "公益下单量",
	sum(yd_order_num) as "昨日下单量",
	sum(yd_explore_order_num) as "昨日探店下单量",
	sum(yd_welfare_order_num) as "昨日公益下单量",
	sum(valid_order_num) as "销单量",
	sum(valid_explore_order_num) as "探店销单量",
	sum(valid_welfare_order_num) as "公益销单量",
	sum(yd_valid_order_num) as "昨日销单量",
	sum(yd_valid_explore_order_num) as "昨日探店销单量",
	sum(yd_valid_welfare_order_num) as "昨日公益销单量",
	sum(upload_order_num) as "待上传订单量",
	sum(explore_upload_order_num) as "探店待上传订单量",
	sum(welfare_upload_order_num) as "公益待上传订单量",
	sum(yd_upload_order_num) as "昨日待上传订单量",
	sum(yd_explore_upload_order_num) as "昨日探店待上传订单量",
	sum(yd_welfare_upload_order_num) as "昨日公益待上传订单量",
	sum(verify_order_num) as "核销订单量",
	sum(explore_verify_order_num) as "探店核销订单量",
	sum(welfare_verify_order_num) as "公益核销订单量",
	sum(yd_verify_order_num) as "昨日核销订单量",
	sum(yd_explore_verify_order_num) as "昨日探店核销订单量",
	sum(yd_welfare_verify_order_num) as "昨日公益核销订单量",
	sum(finish_order_num) as "完单量",
	sum(explore_finish_order_num) as "探店完单量",
	sum(welfare_finish_order_num) as "公益完单量",
	sum(yd_finish_order_num) as "昨日完单量",
	sum(yd_explore_finish_order_num) as "昨日探店完单量",
	sum(yd_welfare_finish_order_num) as "昨日公益完单量"
from (
select
	*,
	0,0,0,0,0,0,0,0,0,0,0,0
from dws.dws_sr_order_explore_dashboard_d
where statisticsdate=$END_DATE$

union all

select
	$end_date$ as statisticsdate,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	-- 核销量(统计日期内下单，且核销日期大于等于统计日期，不限制订单状态)
	count(if(order_date=$END_DATE$ and verify_date>=$END_DATE$,order_id,null)) as verify_order_num,
	count(if(order_date=$END_DATE$ and verify_date>=$END_DATE$ and promotion_type in (1,4),order_id,null)) as explore_verify_order_num,
	count(if(order_date=$END_DATE$ and verify_date>=$END_DATE$ and promotion_type in (2,3),order_id,null)) as welfare_verify_order_num,
	count(if(order_date=date_sub($END_DATE$,interval 1 day) and verify_date>=date_sub($END_DATE$,interval 1 day),order_id,null)) as yd_verify_order_num,
	count(if(order_date=date_sub($END_DATE$,interval 1 day) and verify_date>=date_sub($END_DATE$,interval 1 day) and promotion_type in (1,4),order_id,null)) as yd_explore_verify_order_num,
	count(if(order_date=date_sub($END_DATE$,interval 1 day) and verify_date>=date_sub($END_DATE$,interval 1 day) and promotion_type in (2,3),order_id,null)) as yd_welfare_verify_order_num,
	-- 完单量(统计日期内下单，且完单日期大于等于统计日期，订单状态“已完成”)
	count(if(order_date=$END_DATE$ and finish_date>=$END_DATE$ and status=5,order_id,null)) as finish_order_num,
	count(if(order_date=$END_DATE$ and finish_date>=$END_DATE$ and status=5 and promotion_type in (1,4),order_id,null)) as explore_finish_order_num,
	count(if(order_date=$END_DATE$ and finish_date>=$END_DATE$ and status=5 and promotion_type in (2,3),order_id,null)) as welfare_finish_order_num,
	count(if(order_date=date_sub($END_DATE$,interval 1 day) and finish_date>=date_sub($END_DATE$,interval 1 day) and status=5,order_id,null)) as yd_finish_order_num,
	count(if(order_date=date_sub($END_DATE$,interval 1 day) and finish_date>=date_sub($END_DATE$,interval 1 day) and status=5 and promotion_type in (1,4),order_id,null)) as yd_explore_finish_order_num,
	count(if(order_date=date_sub($END_DATE$,interval 1 day) and finish_date>=date_sub($END_DATE$,interval 1 day) and status=5 and promotion_type in (2,3),order_id,null)) as yd_welfare_finish_order_num
from t1
group by 1
) a
group by 1;
============

-- 0元到店订单
with t1 as (
select
    date(dt) as order_date,
    order_id,
    user_id,
    promotion_type,
    str_to_date(substr(pay_time,1,10),'%Y-%m-%d') as pay_date, -- 支付日期
    str_to_date(substr(finish_time,1,10),'%Y-%m-%d') as finish_date, -- 完成日期
    str_to_date(substr(cancel_time,1,10),'%Y-%m-%d') as cancel_date, -- 取消日期
    str_to_date(substr(refund_time,1,10),'%Y-%m-%d') as refund_date, -- 售后退款日期
    str_to_date(substr(verify_time,1,10),'%Y-%m-%d') as verify_date, -- 核销日期
    status
from dwd.dwd_sr_silkworm_explore_order
where date(dt) between $begin_date$ and $END_DATE$
    and store_name not regexp '测试'
        )

select
	statisticsdate as "统计日期",
	sum(newuser_num) as "新用户数",
	sum(explore_newuser_num) as "探店新用户数",
	sum(welfare_newuser_num) as "公益新用户数",
	sum(yd_newuser_num) as "昨日新用户数",
	sum(yd_explore_newuser_num) as "昨日探店新用户数",
	sum(yd_welfare_newuser_num) as "昨日公益新用户数",
	sum(view_user_num) as "活跃用户数",
	sum(explore_view_user_num) as "探店活跃用户数",
	sum(welfare_view_user_num) as "公益活跃用户数",
	sum(yd_view_user_num) as "昨日活跃用户数",
	sum(yd_explore_view_user_num) as "昨日探店活跃用户数",
	sum(yd_welfare_view_user_num) as "昨日公益活跃用户数",
	sum(valid_newuser_num) as "新增有效用户数",
	sum(valid_explore_newuser_num) as "探店新增有效用户数",
	sum(valid_welfare_newuser_num) as "公益新增有效用户数",
	sum(yd_valid_newuser_num) as "昨日新增有效用户数",
	sum(yd_valid_explore_newuser_num) as "昨日探店新增有效用户数",
	sum(yd_valid_welfare_newuser_num) as "昨日公益新增有效用户数",
	sum(newdaren_num) as "解锁达人用户数",
	sum(yd_newdaren_num) as "昨日解锁达人用户数",
	sum(first_order_user_num) as "新增首单用户数",
	sum(first_explore_order_user_num) as "探店新增首单用户数",
	sum(first_welfare_order_user_num) as "公益新增首单用户数",
	sum(yd_first_order_user_num) as "昨日新增首单用户数",
	sum(yd_first_explore_order_user_num) as "昨日探店新增首单用户数",
	sum(yd_first_welfare_order_user_num) as "昨日公益新增首单用户数",
	sum(onlin_store_num) as "在线店铺数",
	sum(explore_onlin_store_num) as "探店在线店铺数",
	sum(welfare_onlin_store_num) as "公益在线店铺数",
	sum(yd_onlin_store_num) as "昨日在线店铺数",
	sum(yd_explore_onlin_store_num) as "昨日探店在线店铺数",
	sum(yd_welfare_onlin_store_num) as "昨日公益在线店铺数",
	sum(online_promotion_num) as "在线活动数",
	sum(explore_online_promotion_num) as "探店在线活动数",
	sum(welfare_online_promotion_num) as "公益在线活动数",
	sum(yd_online_promotion_num) as "昨日在线活动数",
	sum(yd_explore_online_promotion_num) as "昨日探店在线活动数",
	sum(yd_welfare_online_promotion_num) as "昨日公益在线活动数",
	sum(online_promotion_quota) as "在线活动名额",
	sum(explore_online_promotion_quota) as "探店在线活动名额",
	sum(welfare_online_promotion_quota) as "公益在线活动名额",
	sum(yd_online_promotion_quota) as "昨日在线活动名额",
	sum(yd_explore_online_promotion_quota) as "昨日探店在线活动名额",
	sum(yd_welfare_online_promotion_quota) as "昨日公益在线活动名额",
	sum(order_num) as "下单量",
	sum(explore_order_num) as "探店下单量",
	sum(welfare_order_num) as "公益下单量",
	sum(yd_order_num) as "昨日下单量",
	sum(yd_explore_order_num) as "昨日探店下单量",
	sum(yd_welfare_order_num) as "昨日公益下单量",
	sum(valid_order_num) as "销单量",
	sum(valid_explore_order_num) as "探店销单量",
	sum(valid_welfare_order_num) as "公益销单量",
	sum(yd_valid_order_num) as "昨日销单量",
	sum(yd_valid_explore_order_num) as "昨日探店销单量",
	sum(yd_valid_welfare_order_num) as "昨日公益销单量",
	sum(verify_order_num) as "核销订单量",
	sum(explore_verify_order_num) as "探店核销订单量",
	sum(welfare_verify_order_num) as "公益核销订单量",
	sum(yd_verify_order_num) as "昨日核销订单量",
	sum(yd_explore_verify_order_num) as "昨日探店核销订单量",
	sum(yd_welfare_verify_order_num) as "昨日公益核销订单量",
	sum(finish_order_num) as "完单量",
	sum(explore_finish_order_num) as "探店完单量",
	sum(welfare_finish_order_num) as "公益完单量",
	sum(yd_finish_order_num) as "昨日完单量",
	sum(yd_explore_finish_order_num) as "昨日探店完单量",
	sum(yd_welfare_finish_order_num) as "昨日公益完单量",
	sum(upload_order_num) as "待上传订单量",
	sum(explore_upload_order_num) as "探店待上传订单量",
	sum(welfare_upload_order_num) as "公益待上传订单量",
	sum(yd_upload_order_num) as "昨日待上传订单量",
	sum(yd_explore_upload_order_num) as "昨日探店待上传订单量",
	sum(yd_welfare_upload_order_num) as "昨日公益待上传订单量"
from (
select
	*,
0 as verify_order_num,
0 as explore_verify_order_num,
0 as welfare_verify_order_num,
0 as yd_verify_order_num,
0 as yd_explore_verify_order_num,
0 as yd_welfare_verify_order_num,
0 as finish_order_num,
0 as explore_finish_order_num,
0 as welfare_finish_order_num,
0 as yd_finish_order_num,
0 as yd_explore_finish_order_num,
0 as yd_welfare_finish_order_num
from dws.dws_sr_order_explore_dashboard_d
where statisticsdate between $BEGIN_DATE$ and $END_DATE$

union all

select
	order_date as statisticsdate,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	-- 核销量(统计日期内下单，且核销日期大于等于统计日期，不限制订单状态)
	count(if(verify_date>=order_date,order_id,null)) as verify_order_num,
	count(if(verify_date>=order_date and promotion_type in (1,4),order_id,null)) as explore_verify_order_num,
	count(if(verify_date>=order_date and promotion_type in (2,3),order_id,null)) as welfare_verify_order_num,
	count(if(verify_date>=order_date,order_id,null)) as yd_verify_order_num,
	count(if(verify_date>=order_date and promotion_type in (1,4),order_id,null)) as yd_explore_verify_order_num,
	count(if(verify_date>=order_date and promotion_type in (2,3),order_id,null)) as yd_welfare_verify_order_num,
	-- 完单量(统计日期内下单，且完单日期大于等于统计日期，订单状态“已完成”)
	count(if(finish_date>=order_date and status=5,order_id,null)) as finish_order_num,
	count(if(finish_date>=order_date and status=5 and promotion_type in (1,4),order_id,null)) as explore_finish_order_num,
	count(if(finish_date>=order_date and status=5 and promotion_type in (2,3),order_id,null)) as welfare_finish_order_num,
	count(if(finish_date>=order_date and status=5,order_id,null)) as yd_finish_order_num,
	count(if(finish_date>=order_date and status=5 and promotion_type in (1,4),order_id,null)) as yd_explore_finish_order_num,
	count(if(finish_date>=order_date and status=5 and promotion_type in (2,3),order_id,null)) as yd_welfare_finish_order_num
from t1
group by 1
) a
group by 1;




===================
-- part3 到店区县数据
select 
    statisticsdate as "统计日期",
    platform_name as "平台名称",
    city_name as "城市",
    county_name as "区县",
    takeaway_newuser_num as "小蚕新用户量",
    newuser_num as "到店新用户量",
    newuser_num/takeaway_newuser_num as "到店新用户转化率",
    retention_view_user_num/yd_view_user_num as "到店新用户次日留存率",
    bind_wework_newuser_num as "绑定企微到店用户",
    bind_wework_newuser_num/takeaway_newuser_num as "绑定企微用户转化率",
    valid_newuser_num as "新增有效用户(首次提交名片认证)",
    valid_newuser_num/newuser_num as "新增有效用户(首次提交名片认证)转化率",
    view_user_num as "访问用户量",
    newdaren_num as "解锁达人用户量",
    auth_newuser_num as "认证用户量",
    auth_xiaohongshu_newuser_num as "认证小红书用户量",
    auth_dp_newuser_num as "认证大众点评用户量",
    pass_exam_user_num as "通过考核用户量",
    order_user_num as "下单用户量",
    order_num as "下单量",
    finish_order_num as "完单量(漏斗)",
    finish_order_num/order_num as "完单率",
    first_order_user_num as "首单用户量",
-- tot_used_promotion_quota/order_user_num as "人均下单量",
    order_num/order_user_num as "人均下单量",
    acc_view_user_num as "累计访问用户量",
    acc_order_user_num as "累计下单用户量",
    view_user_num/acc_view_user_num as "用户访问率",
    onlin_promotion_quota as "活动名额",
    tot_used_promotion_quota as "消耗活动名额",
    tot_used_promotion_quota/onlin_promotion_quota as "名额消耗率",
    online_store_num as "在线店铺数",
    order_promotion_num as "下单活动数",
    renshen_order_num as "人审订单量",
    renshen_order_cnt as "人审订单次数",
    renshen_auth_num as "人审认证量",
    notes_renshen_reject_order_num as "笔记人审驳回订单量",
    notes_renshen_reject_num as "笔记人审驳回次数"
from dws.dws_ck_order_explore_dashboard_county_d
where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
    and newuser_num>0
order by 1 desc

===================



drop table dws.dws_sr_order_explore_dashboard_county_d;

CREATE TABLE IF NOT EXISTS dws.dws_sr_order_explore_dashboard_county_d(
    `statisticsdate` date comment '统计日期',
    `platform_name` string comment '平台名称',
    `city_name` string comment '城市',
    `county_name` string comment '区县',
    `takeaway_newuser_num` int comment '小蚕新用户量',
    `newuser_num` int comment '到店新用户量',
    `yd_view_user_num` int comment '昨日访问用户量',
    `retention_view_user_num` int comment '今日留存访问用户量',
    `explore_newuser_num` int comment '探店新用户',
    `welfare_newuser_num` int comment '公益新用户',
    `bind_wework_newuser_num` int comment '新绑定企微到店用户',
    `valid_newuser_num` int comment '新增有效用户', -- 20240807新增 修改人：dahe
    `valid_explore_newuser_num` int comment '探店新增有效用户',
    `valid_welfare_newuser_num` int comment '公益新增有效用户',
    `view_user_num` int comment '活跃用户量', -- 20240807新增 修改人：dahe
    `explore_view_user_num` int comment '探店活跃用户量',
    `welfare_view_user_num` int comment '公益活跃用户量',
    `newdaren_num` int comment '新增解锁达人用户量',
    `auth_newuser_num` int comment '新增认证用户量',
    `auth_xiaohongshu_newuser_num` int comment '新增认证小红书名片量',
    `auth_dp_newuser_num` int comment '新增认证大众点评名片量',
    `pass_exam_user_num` int comment '通过考核用户量',
    `order_user_num` int comment '下单用户量',
    `explore_order_user_num` int comment '探店下单用户量',
    `welfare_order_user_num` int comment '公益下单用户量',
    `order_num` int comment '下单量',
    `explore_order_num` int comment '探店下单量',
    `welfare_order_num` int comment '公益下单量',
    `finish_order_num` int comment '完单量(漏斗)',
    `explore_finish_order_num` int comment '探店完单量(漏斗)',
    `welfare_finish_order_num` int comment '公益完单量(漏斗)',
    `first_order_user_num` int comment '首单用户',
    `first_explore_order_user_num` int comment '探店首单用户',
    `first_welfare_order_user_num` int comment '公益首单用户',
    `tot_used_promotion_quota` int comment '消耗活动名额',
    `explore_tot_used_promotion_quota` int comment '探店消耗活动名额',
    `welfare_tot_used_promotion_quota` int comment '公益消耗活动名额',
    `acc_view_user_num` int comment '累计访问用户量', -- 20240807新增 修改人：dahe
    `acc_explore_view_user_num` int comment '探店累计访问用户量',
    `acc_welfare_view_user_num` int comment '公益累计访问用户量',
    `acc_order_user_num` int comment '累计下单用户量', -- 20240807新增 修改人：dahe
    `acc_explore_order_user_num` int comment '探店累计下单用户量',
    `acc_welfare_order_user_num` int comment '公益累计下单用户量',
    `onlin_promotion_quota` int comment '活动名额', -- 20240807新增 修改人：dahe
    `explore_onlin_promotion_quota` int comment '探店活动名额',
    `welfare_onlin_promotion_quota` int comment '公益活动名额', -- `used_quota` int comment '名额消耗量', -- 20240807新增 修改人：dahe
    -- `explore_used_quota` int comment '探店名额消耗量',
    -- `welfare_used_quota` int comment '公益名额消耗量',
    `online_store_num` int comment '在线店铺数', -- 20240807新增 修改人：dahe
    `explore_online_store_num` int comment '探店在线店铺数',
    `welfare_online_store_num` int comment '公益在线店铺数',
    `order_promotion_num` int comment '下单活动数', -- 20240807新增 修改人：dahe
    `explore_order_promotion_num` int comment '探店下单活动数',
    `welfare_order_promotion_num` int comment '公益下单活动数',
    `promotion_num` int comment '活动数', -- 20240807新增 修改人：dahe
    `explore_promotion_num` int comment '探店活动数',
    `welfare_promotion_num` int comment '公益活动数',
    `renshen_order_num` int comment '人审订单量', -- 20240807新增 修改人：dahe
    `explore_renshen_order_num` int comment '探店人审订单量',
    `welfare_renshen_order_num` int comment '公益人审订单量',
    `renshen_order_cnt` int comment '人审订单次数', -- 20240807新增 修改人：dahe
    `explore_renshen_order_cnt` int comment '探店人审订单次数', -- 20240807新增 修改人：dahe
    `welfare_renshen_order_cnt` int comment '公益人审订单次数', -- 20240807新增 修改人：dahe
    `renshen_auth_num` int comment '人审认证量', -- 20240807新增 修改人：dahe
    `explore_renshen_auth_num` int comment '探店人审认证量',
    `welfare_renshen_auth_num` int comment '公益人审认证量',
    `notes_renshen_reject_order_num` int comment '笔记人审驳回订单量', -- 20240807新增 修改人：dahe
    `explore_notes_renshen_reject_order_num` int comment '探店笔记人审驳回订单量',
    `welfare_notes_renshen_reject_order_num` int comment '公益笔记人审驳回订单量',
    `notes_renshen_reject_num` int comment '笔记人审驳回次数', -- 20240807新增 修改人：dahe
    `explore_notes_renshen_reject_num` int comment '探店笔记人审驳回次数',
    `welfare_notes_renshen_reject_num` int comment '公益笔记人审驳回次数'
) comment '到店业务日区县数据看板' 
partitioned by(dt string) 
STORED AS ORC;





-- 城市维表
with dim_city as (
    select  city_id,
            city_name,
            county_id,
            county_name
    from  dim.dim_silkworm_county
), 

-- 用户维表
dim_user as (
    select  a.user_id,
            substr(a.register_time, 1, 10) as register_date,
            case when a.latest_login_platform = 'h5' then 'H5' when a.latest_login_platform = 'android' then 'Android' when a.latest_login_platform = 'ios' then 'iOS' when a.latest_login_platform = 'mini' then '小程序' else '其他' end as platform_name,
            ifnull(case when a.county_id = 0 then '其他' when a.county_id is null then '其他' else dim_city.city_name end, '其他') as city_name,
            ifnull(
                case when a.county_id = 0 then '其他' when a.county_id is null then '其他' else dim_city.county_name end,
                '其他'
            ) as county_name
    from dim.dim_silkworm_user a
    left join dim_city
    on a.county_id = dim_city.county_id
    where is_logoff = 0 -- 未注销 20240823新增 修改人：dahe
), 



-- 探店业务用户
t1 as (
select  date(a.create_time) as create_date,
            b.bind_wework_date, -- 绑定企微日期
            a.user_id,
            if(daren_score >= 40, 1, 0) is_daren, -- 1:达人
            -- is_bind_wework, -- 是否绑定企微，1：是
            if(b.user_id is not null,1,0) as is_bind_wework, -- 是否绑定企微，1：是 20240823调整逻辑 修改人：dahe
            is_finish_exam, -- 是否完成考核 1：是
            is_open_renshen, -- 是否开启人审 1：是
            auth_xiaohongshu_id,
            auth_dp_id,
            str_to_date(substr(daren_activate_time,1,10),'%Y-%m-%d') as daren_activate_date, -- 达人激活日期
    		str_to_date(substr(xiaohongshu_auth_first_time,1,10),'%Y-%m-%d') as xiaohongshu_auth_first_date, -- 小红书首次认证日期
    		str_to_date(substr(dp_auth_first_time,1,10),'%Y-%m-%d') as dp_auth_first_date, -- 大众点评首次认证日期
    		str_to_date(substr(xiaohongshu_first_order_time,1,10),'%Y-%m-%d') as xiaohongshu_first_order_date, -- 小红书首次下单日期
    		str_to_date(substr(dp_first_order_time,1,10),'%Y-%m-%d') as dp_first_order_date, -- 大众点评首次下单日期
    		str_to_date(substr(dp_auth_time,1,10),'%Y-%m-%d') as dp_auth_date, -- 大众点评认证日期
    		str_to_date(substr(xiaohongshu_auth_time,1,10,'%Y-%m-%d') as xiaohongshu_auth_date, -- 小红书认证日期
    		-- 访问用户
    		str_to_date(substr(first_view_date,1,10),'%Y-%m-%d') as first_view_date, -- 首次访问日期
    		str_to_date(substr(first_explode_view_date,1,10),'%Y-%m-%d') as first_explore_view_date, -- 探店首次访问日期
    		str_to_date(substr(first_welfare_view_date,1,10),'%Y-%m-%d') as first_welfare_view_date, -- 公益首次访问日期
    		-- 新增首单用户
    		str_to_date(substr(first_order_date,1,10),'%Y-%m-%d') as first_order_date, -- 新增首单日期
    		str_to_date(substr(first_explode_order_date,1,10),'%Y-%m-%d') as first_explore_order_date, -- 探店新增首单日期
    		str_to_date(substr(first_welfare_order_date,1,10),'%Y-%m-%d') as first_welfare_order_date -- 公益新增首单日期
            -- 20240828 新增 修改人：dahe
            ,pass_exam_date
    from  dim.dim_silkworm_explore_daren_cleanse a
left join 
-- 20240823 调整绑定企微逻辑
-- 绑定企微
        (select
            user_id,min(bind_wework_date) as bind_wework_date -- 取用户首次绑定企微日期，因存在多次绑定，绑定后机器人发考核题，考核题发送失败，用户会多次添加企微
        from (select
                    date(create_time) as bind_wework_date, -- 绑定企微日期
                    user_id
                from dwd.dwd_sr_silkworm_explore_bind_wework_record
                where dt<='${T-1}'
                    and status=0 -- 正常
                    and bind_interior_staff_wework_id>0
                group by 1,2
        ) b1
        group by 1
        ) b 
on a.user_id=b.user_id
left join
-- 20240828 新增 修改人：dahe
-- 通过考试时间
        (select
            dt as pass_exam_date,
            user_id
        from dwd.dwd_sr_silkworm_explore_score_record
        where dt<='${T-1}'
            and add_type=3 -- 答题
            and status=1
        group by 1,2
        ) c
    on a.user_id=c.user_id
where a.status = 1 -- 1:正常,2:删除 -- 20240823新增 修改人：dahe
), 

-- 留存用户量
view_newuser as (
    select  statistics_date,
            ifnull(platform_name, '全部') as platform_name,
            ifnull(city_name, '全部') as city_name,
            ifnull(county_name, '全部') as county_name,
            count(distinct yd_newuser_id) as yd_newuser_num, -- 昨日新增用户量
            count(distinct if(yd_retention_user_id is not null, yd_newuser_id, null)) as retention_newuser_num -- 留存新用户量
    from    (
                select  '${T-1}' as statistics_date,
                        a.platform_name,
                        a.city_name,
                        a.county_name,
                        a.user_id as yd_newuser_id,
                        b.user_id as yd_retention_user_id
                from
                        -- 昨日到店新增访问用户
                        (
                            select  t1.user_id,
                                    dim_user.platform_name,
                                    dim_user.city_name,
                                    dim_user.county_name
                            from    dim_user
                            inner join t1
                            on      t1.user_id = dim_user.user_id
                            and     first_view_date = date_sub('${T-1}', 1)
                        ) a
                left join -- 今日访问用户
                        (
                            select  cast(user_id as int) as user_id,
                                    sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) as explore_pv, -- 值>0，则是探店用户
                                    sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) as welfare_pv -- 值>0，则是公益用户
                            from    dws.dws_sr_traffic_user_d
                            where   statistics_date ='${T-1}'
                            and   	user_id regexp '^[0-9]{1,9}$'
                                    ) -- 20240823调整，限制登录用户，减少数据量 修改人：dahe
                            group by 1
                            having  (
                                        (explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
                                        or      (welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) > 0
                                    )
                        ) b
                on      a.user_id = b.user_id
            ) t
    group by grouping sets (
                (statistics_date),
                (statistics_date, platform_name),
                (statistics_date, city_name),
                (statistics_date, platform_name, city_name, county_name)
            )
), 

-- 0元到店访问用户
t2 as (
    select  statistics_date,
            user_id,
            platform_name,
            case when a.county_id = 0 then '其他' when a.county_id is null then '全部' else dim_city.city_name end as city_name,
            case when a.county_id = 0 then '其他' when a.county_id is null then '全部' else dim_city.county_name end as county_name,
            explore_pv,
            welfare_pv
    from    (
                select  statistics_date, 
                        -- cast(user_id as int) as user_id,
                        user_id, -- 20240823调整 修改人：dahe
                        case when platform_name in ('h5', '营销H5') then 'H5' when platform_name = 'Android' then 'Android' when platform_name = 'iOS' then 'iOS' when platform_name = '小程序' then '小程序' else '其他' end as platform_name,
                        cast(county_id as int) as county_id,
                        sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) as explore_pv, -- 值>0，则是探店用户
                        sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) as welfare_pv -- 值>0，则是公益用户
                from    dws.dws_sr_traffic_user_d
                where   to_date(statistics_date) = '${T-1}' 
                        -- and (user_id regexp '^[1-7]{1,7}$'
                        -- or user_id regexp '^[1-8]{1,8}$'
                        -- or user_id regexp '^[1-9]{1,9}$') -- 20240823调整，去掉限制，浏览用户不限制登录 修改人：dahe
                group by 1,
                        2,
                        3,
                        4
            ) a
    left join dim_city
    on a.county_id = dim_city.county_id
), 

-- 0元到店订单
t3 as (
    select  date(dt) as order_date,
            order_id,
            user_id,
            store_id,
            store_promotion_id,
            promotion_type,
    		str_to_date(substr(pay_time,1,10),'%Y-%m-%d') as pay_date, -- 支付日期
    		str_to_date(substr(finish_time,1,10),'%Y-%m-%d') as finish_date, -- 完成日期
    		str_to_date(substr(cancel_time,1,10),'%Y-%m-%d') as cancel_date, -- 取消日期
    		str_to_date(substr(refund_time,1,10),'%Y-%m-%d') as refund_date, -- 售后退款日期
    		str_to_date(substr(verify_time,1,10),'%Y-%m-%d') as verify_date, -- 核销日期
            status,
            notes_reject_cnt
    from    dwd.dwd_sr_silkworm_explore_order
    where    date(dt) between date_sub('${T-1}',interval 1 day) and '${T-1}'
    and store_name not regexp '测试'
), 


-- 探店在线活动
t4 as (
    select  to_date(dt) as dt,
            promotion_type,
            '其他' as platform_name,
            ifnull(if(dim_city.city_name is null, '其他', dim_city.city_name), '其他') as city_name,
            ifnull(if(dim_city.city_name is null, '其他', dim_city.county_name), '其他') as county_name,
            count(promotion_id) as online_promotion_num, -- 在线活动数
            sum(tot_promotion_quota) as tot_online_promotion_quota, -- 在线活动名额
            sum(used_promotion_quota) as tot_used_promotion_quota -- 消耗活动名额
    from(
                select  substring(begin_time, 1, 10) as dt,
                        promotion_type,
                        store_id,
                        promotion_id,
                        status,
                        tot_promotion_quota,
                        used_promotion_quota
                from    dwd.dwd_sr_silkworm_explore_promotion
                where   dt between date_sub('${T-1}',interval 1 day) and '${T-1}'
            				and str_to_date(substr(begin_time,1,10),'%Y-%m-%d') between date_sub('${T-1}',1) and '${T-1}'
                -- and status=1 -- 首次跑数据不限制，以免漏掉已下线数据 20240823调整 修改人：dahe
            ) a
    left join dim.dim_silkworm_explore_store b
    on      a.store_id = b.store_id
    left join dim_city
    on      b.city_id = dim_city.county_id
    group by 1,
            2,
            3,
            4,
            5
), 


-- 探店在线店铺
t5 as (
    select  date(create_time) as statistics_date,
            business_type, -- 1：探店；2：公益
            '其他' as platform_name,
            ifnull(if(dim_city.city_name is null, '其他', dim_city.city_name), '其他') as city_name,
            ifnull(if(dim_city.city_name is null, '其他', dim_city.county_name), '其他') as county_name,
            count(distinct store_id) as online_store_num -- 在线店铺数
    from    dim.dim_silkworm_explore_store a
    left join dim_city
    on      a.city_id = dim_city.county_id
    -- 20240823调整 不限制，以免漏掉已下线数据  修改人：dahe
    where  a.status = 1 -- 正常 
    group by 1,
            2,
            3,
            4,
            5
), 

-- 人审订单
t6 as (
    select  a.dt as statistics_date, -- demand_promotion_type, -- 1:dp,2:xiaohongshu
            t3.promotion_type,
            '其他' as platform_name,
            '其他' as city_name,
            '其他' as county_name,
            count(a.auto_id) as renshen_order_cnt, -- 人审次数
            count(distinct a.order_id) as renshen_order_num -- 人审订单量
    from    dwd.dwd_sr_silkworm_explore_notes_upload_record a
    left join t3
    on      a.order_id = t3.order_id
    where   a.dt = '${T-1}'
    and     a.auditor_id <> 0 -- 非0：人审
    group by 1,
            2,
            3,
            4,
            5
), 

-- 人审认证
t7 as (
    select  dt as statistics_date, -- account_type, -- 1:dp,2:xiaohongshu
            '其他' as platform_name,
            '其他' as city_name,
            '其他' as county_name,
            count(*) as renshen_auth_cnt -- 人审认证记录数
    from    dwd.dwd_sr_silkworm_explore_auth_record
    where   dt = '${T-1}'
    and     operator_id <> 0 -- 非0：人审
    group by 1,
            2,
            3,
            4
)

========================
-- 城市维表
with dim_city as (
    select  city_id,
            city_name,
            county_id,
            county_name
    from  dim.dim_silkworm_county
), 

-- 用户维表
dim_user as (
    select  a.user_id,
            substr(a.register_time, 1, 10) as register_date,
            case when a.latest_login_platform = 'h5' then 'H5' when a.latest_login_platform = 'android' then 'Android' when a.latest_login_platform = 'ios' then 'iOS' when a.latest_login_platform = 'mini' then '小程序' else '其他' end as platform_name,
            ifnull(case when a.county_id = 0 then '其他' when a.county_id is null then '其他' else dim_city.city_name end, '其他') as city_name,
            ifnull(
                case when a.county_id = 0 then '其他' when a.county_id is null then '其他' else dim_city.county_name end,
                '其他'
            ) as county_name
    from dim.dim_silkworm_user a
    left join dim_city
    on a.county_id = dim_city.county_id
    where is_logoff = 0 -- 未注销 20240823新增 修改人：dahe
), 


-- 0元到店订单
t3 as (
    select  date(dt) as order_date,
            order_id,
            user_id,
            store_id,
            store_promotion_id,
            promotion_type,
    		str_to_date(substr(pay_time,1,10),'%Y-%m-%d') as pay_date, -- 支付日期
    		str_to_date(substr(finish_time,1,10),'%Y-%m-%d') as finish_date, -- 完成日期
    		str_to_date(substr(cancel_time,1,10),'%Y-%m-%d') as cancel_date, -- 取消日期
    		str_to_date(substr(refund_time,1,10),'%Y-%m-%d') as refund_date, -- 售后退款日期
    		str_to_date(substr(verify_time,1,10),'%Y-%m-%d') as verify_date, -- 核销日期
            status,
            notes_reject_cnt
    from    dwd.dwd_sr_silkworm_explore_order
    where    date(dt) between date_sub($end_date$,interval 30 day) and $end_date$
    and store_name not regexp '测试'
)


select 
    statisticsdate as "统计日期",
    platform_name as "平台名称",
    city_name as "城市",
    county_name as "区县",
    takeaway_newuser_num as "小蚕新用户量",
    newuser_num as "到店新用户量",
    newuser_num/takeaway_newuser_num as "到店新用户转化率",
    retention_view_user_num/yd_view_user_num as "到店新用户次日留存率",
    bind_wework_newuser_num as "绑定企微到店用户",
    bind_wework_newuser_num/takeaway_newuser_num as "绑定企微用户转化率",
    valid_newuser_num as "新增有效用户(首次提交名片认证)",
    valid_newuser_num/newuser_num as "新增有效用户(首次提交名片认证)转化率",
    view_user_num as "访问用户量",
    newdaren_num as "解锁达人用户量",
    auth_newuser_num as "认证用户量",
    auth_xiaohongshu_newuser_num as "认证小红书用户量",
    auth_dp_newuser_num as "认证大众点评用户量",
    pass_exam_user_num as "通过考核用户量",
    order_user_num as "下单用户量",
    order_num as "下单量",
    finish_order_num as "完单量(漏斗)",
    finish_order_num/order_num as "完单率",
    first_order_user_num as "首单用户量",
	-- tot_used_promotion_quota/order_user_num as "人均下单量",
    order_num/order_user_num as "人均下单量",
    acc_view_user_num as "累计访问用户量",
    acc_order_user_num as "累计下单用户量",
    view_user_num/acc_view_user_num as "用户访问率",
    onlin_promotion_quota as "活动名额",
    tot_used_promotion_quota as "消耗活动名额",
    tot_used_promotion_quota/onlin_promotion_quota as "名额消耗率",
    online_store_num as "在线店铺数",
    order_promotion_num as "下单活动数",
    renshen_order_num as "人审订单量",
    renshen_order_cnt as "人审订单次数",
    renshen_auth_num as "人审认证量",
    notes_renshen_reject_order_num as "笔记人审驳回订单量",
    notes_renshen_reject_num as "笔记人审驳回次数"
from (
select  statistics_date,
        platform_name,
        city_name,
        county_name,
        sum(takeaway_newuser_num) as takeaway_newuser_num, -- 小蚕新用户量
        sum(newuser_num) as newuser_num, -- 到店新用户量
        sum(yd_newuser_num) as yd_newuser_num, -- 昨日新增用户量
        sum(retention_newuser_num) as retention_newuser_num, -- 留存新用户量
        sum(explore_newuser_num) as explore_newuser_num, -- 探店新用户
        sum(welfare_newuser_num) as welfare_newuser_num, -- 公益新用户
        sum(bind_wework_newuser_num) as bind_wework_newuser_num, -- 新绑定企微到店用户
        sum(valid_newuser_num) as valid_newuser_num, -- 新增有效用户 20240807新增 修改人：dahe
        sum(valid_explore_newuser_num) as valid_explore_newuser_num, -- 探店新增有效用户
        sum(valid_welfare_newuser_num) as valid_welfare_newuser_num, -- 公益新增有效用户
        sum(view_user_num) as view_user_num, -- 活跃用户 20240807新增 修改人：dahe
        sum(explore_view_user_num) as explore_view_user_num, -- 探店活跃用户量
        sum(welfare_view_user_num) as welfare_view_user_num, -- 公益活跃用户量
        sum(newdaren_num) as newdaren_num, -- 新增解锁达人用户量
        sum(auth_newuser_num) as auth_newuser_num, -- 新增认证用户量
        sum(auth_xiaohongshu_newuser_num) as auth_xiaohongshu_newuser_num, -- 新增认证小红书用户量
        sum(auth_dp_newuser_num) as auth_dp_newuser_num, -- 新增认证大众点评用户量
        sum(pass_exam_user_num) as pass_exam_user_num, -- 通过考核用户量
        sum(order_user_num) as order_user_num, -- 下单用户量
        sum(explore_order_user_num) as explore_order_user_num, -- 探店下单用户量
        sum(welfare_order_user_num) as welfare_order_user_num, -- 公益下单用户量
        sum(order_num) as order_num, -- 下单量
        sum(explore_order_num) as explore_order_num, -- 探店下单量
        sum(welfare_order_num) as welfare_order_num, -- 公益下单量
        sum(first_order_user_num) as first_order_user_num, -- 首单用户
        sum(first_explore_order_user_num) as first_explore_order_user_num, -- 探店首单用户
        sum(first_welfare_order_user_num) as first_welfare_order_user_num, -- 公益首单用户
        sum(tot_used_promotion_quota) as tot_used_promotion_quota, -- 消耗活动名额
        sum(explore_tot_used_promotion_quota) as explore_tot_used_promotion_quota, -- 探店消耗活动名额
        sum(welfare_tot_used_promotion_quota) as welfare_tot_used_promotion_quota, -- 公益消耗活动名额
        sum(acc_view_user_num) as acc_view_user_num, -- 累计访问用户量  20240807新增 修改人：dahe
        sum(acc_explore_view_user_num) as acc_explore_view_user_num, -- 探店累计访问用户量
        sum(acc_welfare_view_user_num) as acc_welfare_view_user_num, -- 公益累计访问用户量
        sum(acc_order_user_num) as acc_order_user_num, -- 累计下单用户量  20240807新增 修改人：dahe
        sum(acc_explore_order_user_num) as acc_explore_order_user_num, -- 探店累计下单用户量
        sum(acc_welfare_order_user_num) as acc_welfare_order_user_num, -- 公益累计下单用户量
        sum(onlin_promotion_quota) as onlin_promotion_quota, -- 活动名额 20240807新增 修改人：dahe
        sum(explore_onlin_promotion_quota) as explore_onlin_promotion_quota, -- 探店活动名额  
        sum(welfare_onlin_promotion_quota) as welfare_onlin_promotion_quota, -- 公益活动名额
        sum(online_store_num) as online_store_num, -- 在线店铺数 20240807新增 修改人：dahe)
        sum(explore_online_store_num) as explore_online_store_num, -- 探店在线店铺数 
        sum(welfare_online_store_num) as welfare_online_store_num, -- 公益在线店铺数
        sum(order_promotion_num) as order_promotion_num, -- 下单活动数 20240807新增 修改人：dahe)
        sum(explore_order_promotion_num) as explore_order_promotion_num, -- 探店下单活动数
        sum(welfare_order_promotion_num) as welfare_order_promotion_num, -- 公益下单活动数
        sum(promotion_num) as promotion_num, -- 活动数 20240807新增 修改人：dahe
        sum(explore_promotion_num) as explore_promotion_num, -- 探店活动数
        sum(welfare_promotion_num) as welfare_promotion_num, -- 公益活动数
        sum(renshen_order_num) as renshen_order_num, -- 人审订单量 20240807新增 修改人：dahe)
        sum(explore_renshen_order_num) as explore_renshen_order_num, -- 探店人审订单量
        sum(welfare_renshen_order_num) as welfare_renshen_order_num, -- 公益人审订单量
        sum(renshen_order_cnt) as renshen_order_cnt, -- 人审订单次数 -- 20240807新增 修改人：dahe
        sum(explore_renshen_order_cnt) as explore_renshen_order_cnt, -- 探店人审订单次数 -- 20240807新增 修改人：dahe
        sum(welfare_renshen_order_cnt) as welfare_renshen_order_cnt, -- 公益人审订单次数 -- 20240807新增 修改人：dahe
        sum(renshen_auth_num) as renshen_auth_num, -- 人审认证量 20240807新增 修改人：dahe)
        sum(explore_renshen_auth_num) as explore_renshen_auth_num, -- 探店人审认证量
        sum(welfare_renshen_auth_num) as welfare_renshen_auth_num, -- 公益人审认证量
        sum(notes_renshen_reject_order_num) as notes_renshen_reject_order_num, -- 笔记人审驳回订单量 20240807新增 修改人：dahe
        sum(explore_notes_renshen_reject_order_num) as explore_notes_renshen_reject_order_num, -- 探店笔记人审驳回订单量
        sum(welfare_notes_renshen_reject_order_num) as welfare_notes_renshen_reject_order_num, -- 公益笔记人审驳回订单量
        sum(notes_renshen_reject_num) as notes_renshen_reject_num, -- 笔记人审驳回次数 20240807新增 修改人：dahe
        sum(explore_notes_renshen_reject_num) as explore_notes_renshen_reject_num, -- 探店笔记人审驳回次数
        sum(welfare_notes_renshen_reject_num) as welfare_notes_renshen_reject_num, -- 公益笔记人审驳回次数
        sum(finish_order_num) as finish_order_num, -- 完单量
        sum(explore_finish_order_num) as explore_finish_order_num, -- 探店完单量
        sum(welfare_finish_order_num) as welfare_finish_order_num -- 公益完单量
from (
		select
			*,
			0 as finish_order_num,
			0 as explore_finish_order_num,
			0 as welfare_finish_order_num
		from dws.dws_sr_order_explore_dashboard_county_d
		where statisticsdate between $BEGIN_DATE$ and $END_DATE$

		union all

		select 
			t3.finish_date,
			ifnull(dim_user.platform_name, '全部') as platform_name,
			ifnull(dim_user.city_name, '全部') as city_name,
			ifnull(dim_user.county_name, '全部') as county_name,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			-- 完单
			count(distinct if(t3.status=5,t3.order_id,null)) as finish_order_num, -- 完单量(漏斗)
			count(distinct if(t3.promotion_type in (1,4) and t3.status=5,t3.order_id,null)) as explore_finish_order_num, -- 探店完单量(漏斗)
			count(distinct if(t3.promotion_type in (2,3) and t3.status=5,t3.order_id,null)) as welfare_finish_order_num -- 公益完单量(漏斗)
		from t3
		left join dim_user
		on  t3.user_id = dim_user.user_id
		where t3.finish_date between $BEGIN_DATE$ and $END_DATE$
		group by grouping sets (
		            (t3.finish_date),
		            (t3.finish_date, dim_user.platform_name),
		            (t3.finish_date, dim_user.city_name),
		            (t3.finish_date, dim_user.platform_name, dim_user.city_name, dim_user.county_name)
		        )
	) a
group by 1
 ) b
















