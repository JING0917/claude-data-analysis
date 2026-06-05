
============= 埋点事件
Red_Packet_Rainning_Page_Ex	红包雨触发下红包
Red_Packet_Rainning_Cover_Click	红包雨点击红包封面

Lottery_Page_Ex	抽奖页面曝光
Lottery_Open_RedPacket_Click 抽奖开红包点击（即点击红包封面开始抽奖的动作）

Member_Page_Ex	会员页曝光
Member_Red_Packet_Claim_Click 会员每日红包-领取按钮点击
Member_Cashback_Coupon_Claim_Click 会员返利券领取按钮点击



会员页有浏览无曝光，需要排查。

1）Member_Page_Ex （会员页曝光），MySQL业务库领取会员红包、会员返利券的用户，在该事件下，均无埋点记录。（时间范围均是1月8日）
2）抽查部分MySQL业务库领取会员红包、会员返利券的用户，Member_Page_View（会员页浏览）有上报。
3）抽查用户ID如：562616605,778734201,725364454

=============

======= 红包雨

-- 红包雨参与记录
-- 数据量10700，用户量6118
with t1 as (
select
    user_id,create_time
from dwd.dwd_sr_market_rpd_activity_takepart_record
where dt=date_sub(current_date(),interval 1 day)
),

-- 红包雨埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Red_Packet_Rainning_Page_Ex','Red_Packet_Rainning_Cover_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as view_diff
from t1 
left join t2 
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Red_Packet_Rainning_Page_Ex'
) tot
where view_diff between 0 and 5 -- 存在埋点触发时间晚于业务库时间 此时，这部分用户也会被计入
group by 1
),

-- 得到<=点击窗口期用户
t4 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as click_diff
from t1 
left join t2 
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Red_Packet_Rainning_Cover_Click'
) tot
where click_diff between 0 and 5 -- 存在埋点触发时间晚于业务库时间 此时，这部分用户也会被计入
group by 1
)




-- 命中用户量590 参与用户量6118 风险用户占比：9.6%
select 
	t1.user_id
-- 	,t1.create_time,
-- 	t3.user_id,
-- 	t4.user_id
from t1 left join t3 on t3.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
where t3.user_id is null and t4.user_id is null
group by 1
;



-- 验证数据
-- 验证t3表数据
-- 红包雨参与记录
with t1 as (
select
    user_id,create_time
from dwd.dwd_sr_market_rpd_activity_takepart_record
where dt=date_sub(current_date(),interval 1 day)
),

-- 红包雨埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Red_Packet_Rainning_Page_Ex','Red_Packet_Rainning_Cover_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	t1.user_id,
	cast(t1.create_time as string) create_time,
	t2.event_time,
	date_diff('minute',t1.create_time,t2.event_time) as view_diff
from t1 
left join t2 
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Red_Packet_Rainning_Page_Ex'
)

-- 查看明细无问题 t4不再看了，逻辑和t3一致
select
	*
from t3;


============ 抽奖

-- show create table dwd.dwd_sr_market_rpd_lottery_record;

-- 每日抽奖次数和人数一致 日均10,673
select 
    -- user_id,
    -- create_time
    dt,
    count(1) tot,
    count(distinct user_id) unum
from dwd.dwd_sr_market_rpd_lottery_record
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1
;



========== 正式跑数
-- 每日抽奖记录
-- 数据量：8476 用户量：8476
with t1 as (
select 
    user_id,
    create_time
from dwd.dwd_sr_market_rpd_lottery_record
where dt=date_sub(current_date(),interval 1 day)
group by 1,2
),

-- 抽奖埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Lottery_Page_Ex','Lottery_Open_RedPacket_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as view_diff
from t1
left join t2 
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Lottery_Page_Ex'
) tot
where view_diff between 0 and 5 -- 存在埋点触发时间晚于业务库时间 此时，这部分用户也会被计入
group by 1
),

-- 得到<=点击窗口期用户
t4 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as click_diff
from t1
left join t2
on t1.user_id=t2.user_id
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Lottery_Open_RedPacket_Click'
) tot
where click_diff between 0 and 5 -- 存在埋点触发时间晚于业务库时间 此时，这部分用户也会被计入
group by 1
)


-- 命中用户量5549 参与用户量8476 风险用户占比：63.4%
select 
	t1.user_id
-- 	,t1.create_time,
-- 	t3.user_id,
-- 	t4.user_id
from t1 left join t3 on t3.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
where t3.user_id is null and t4.user_id is null
group by 1
;


-- 验证数据
-- 验证t3数据
with t1 as (
select 
    user_id,
    create_time
from dwd.dwd_sr_market_rpd_lottery_record
where dt=date_sub(current_date(),interval 1 day)
group by 1,2
),

-- 抽奖埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Lottery_Page_Ex','Lottery_Open_RedPacket_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	date_diff('minute',t1.create_time,t2.event_time) as view_diff
from t1
left join t2 
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Lottery_Page_Ex'
)

-- 埋点触发时间晚于业务库时间数据642条
select * from t3;


====== 红包领取
-- dwd.dwd_sr_market_redpack_use_record

-- -- 查看领取数据记录
-- select
-- 	create_time,
--     user_id,
--     redpacket_id,
--     redpacket_name,
--     used_time,
--     real_rebate_amt
-- from dwd.dwd_sr_market_redpack_use_record
-- where dt=date_sub(current_date(),interval 1 day)
--     and redpacket_type=7 -- 会员每日红包活动
-- limit 100;

-- -- 统计最大领取次数
-- select
--     user_id,
--     count(redpacket_id) as tot,
--     sum(real_rebate_amt) as amt
-- from dwd.dwd_sr_market_redpack_use_record
-- where dt=date_sub(current_date(),interval 1 day)
--     and redpacket_type=7 -- 会员每日红包活动
-- group by 1
-- order by 2 desc;

-- -- 832次，638人
-- select
-- 	dt,
--     count(redpacket_id) as tot,
--     count(distinct user_id) as unum,
--     sum(real_rebate_amt) as amt
-- from dwd.dwd_sr_market_redpack_use_record
-- where dt=date_sub(current_date(),interval 1 day)
--     and redpacket_type=7 -- 会员每日红包活动
-- group by 1
-- ;


--------
-- 正式跑数据
-- 数据量：832 用户量：637
with t1 as (
select 
    user_id,
    create_time
from dwd.dwd_sr_market_redpack_use_record
where dt=date_sub(current_date(),interval 1 day)
	and redpacket_type=7 -- 会员每日红包活动
group by 1,2
),

-- 会员每日红包埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Member_Page_Ex','Member_Red_Packet_Claim_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as view_diff
from t1
left join t2
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Page_Ex'
) tot
where view_diff between 0 and 5
group by 1
),

-- 得到<=点击窗口期用户
t4 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as click_diff
from t1
left join t2
on t1.user_id=t2.user_id
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Red_Packet_Claim_Click'
) tot
where click_diff between 0 and 5
group by 1
)


-- 命中用户量634 参与用户量637 风险用户占比：100%
select 
	t1.user_id
-- 	,t1.create_time,
-- 	t3.user_id,
-- 	t4.user_id
from t1 left join t3 on t3.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
where t3.user_id is null and t4.user_id is null
group by 1
;


-- 验证数据

with t1 as (
select 
    user_id,
    create_time
from dwd.dwd_sr_market_redpack_use_record
where dt=date_sub(current_date(),interval 1 day)
	and redpacket_type=7 -- 会员每日红包活动
group by 1,2
),

-- 会员每日红包埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Member_Page_Ex','Member_Red_Packet_Claim_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	t1.user_id,
	cast(t1.create_time as string) create_time,
	t2.event_time,
	date_diff('minute',t1.create_time,t2.event_time) as view_diff
from t1
left join t2
on t1.user_id=t2.user_id 
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Page_Ex'
),

-- 得到<=点击窗口期用户
t4 as (
select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	date_diff('minute',t1.create_time,t2.event_time) as click_diff
from t1
left join t2
on t1.user_id=t2.user_id
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Red_Packet_Claim_Click'
)

-- 参与用户量604 命中用户量493 命中率 81.6%
-- select t3.*,b.register_time,b.is_whitelist,b.block_reason,b.latest_block_time,b.user_risk_level from t3 left join dim.dim_silkworm_user b on t3.user_id=b.user_id;

select t4.*,b.register_time,b.is_whitelist,b.block_reason,b.latest_block_time,b.user_risk_level from t4 left join dim.dim_silkworm_user b on t4.user_id=b.user_id;




====== 权益
-- dwd.dwd_sr_market_rights_card

-- -- 3次，1人
-- select
--     dt,
--     count(1) cnt,
--     count(distinct user_id) unum
-- from dwd.dwd_sr_market_rights_card
-- where dt=date_sub(current_date(),interval 1 day)
--     and card_type=8 -- vip额外返利券
-- group by 1


-------------
-- 正式跑数据
-- 数据量124 用户量42
with t1 as (
select
    create_time,
    user_id
from dwd.dwd_sr_market_rights_card
where dt=date_sub(current_date(),interval 1 day)
    and card_type=8 -- vip额外返利券
group by 1,2
),

-- 会员返利券领取埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Member_Page_Ex','Member_Cashback_Coupon_Claim_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as view_diff
from t1
left join t2 
on t1.user_id=t2.user_id
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Page_Ex'
) tot
where view_diff between 0 and 5
group by 1
),

-- 得到<=点击窗口期用户
t4 as (
select
	user_id
from
-- 计算窗口期
(select
	t1.user_id,
	t1.create_time,
	t2.event_time,
	ifnull(date_diff('minute',t1.create_time,t2.event_time),-1) as click_diff
from t1
left join t2
on t1.user_id=t2.user_id
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Cashback_Coupon_Claim_Click'
) tot
where click_diff between 0 and 5
group by 1
)



-- 命中用户量3 参与用户量42 风险用户占比：7.1%
select 
	t1.user_id
-- 	,t1.create_time,
-- 	t3.user_id,
-- 	t4.user_id
from t1 left join t3 on t3.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
where t3.user_id is null and t4.user_id is null
group by 1
;


-- 验数
with t1 as (
select
    create_time,
    user_id
from dwd.dwd_sr_market_rights_card
where dt=date_sub(current_date(),interval 1 day)
    and card_type=8 -- vip额外返利券
group by 1,2
),

-- 会员返利券领取埋点记录
t2 as (
select
	event_name,
	user_id,
	event_time
from ods.ods_sr_traffic_event_log
where dt=date_sub(current_date(),interval 1 day)
    and event_name in ('Member_Page_Ex','Member_Cashback_Coupon_Claim_Click')
    and user_id regexp '^[0-9]{1,9}$'
group by 1,2,3
),


-- 得到<=曝光窗口期用户
t3 as (
select
	t1.user_id,
	cast(t1.create_time as string) create_time,
	t2.event_time,
	date_diff('minute',t1.create_time,t2.event_time) as view_diff
from t1
left join t2 
on t1.user_id=t2.user_id
	and hour(t1.create_time)=hour(t2.event_time)
	and t2.event_name='Member_Page_Ex'
)

-- 曝光数据均不是业务库参与用户的
select * from t3;




































