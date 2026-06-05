=========== 打卡赛月数据
-- CK
-- 挑战赛
-- 分城市
select 
substring(dt,1,7) as mon,
b.city_name,
length(arrayDistinct(arrayFlatten(groupArray(par_user_list)))) as baoming_user_num,
length(arrayDistinct(arrayFlatten(groupArray(com_user_list)))) as finish_user_num,
sum(com_order_num+lose_order_num) as tot_valid_order_num,
sum(reward_value)/100 as tot_cost
from dws.dws_ck_silkworm_challenge a
left join (select city_name,
                substring(toString(city_id),1,4) as city_id
        from dim.dim_region_code
        group by 1,2) b
    on toString(a.baoming_city_id)=b.city_id
where a.dt between toString($begin_date$) and toString($end_date$)
    and a.challenge_id>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=1 -- 打卡
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2

union all

-- 全部
select 
substring(dt,1,7) as mon,
'全部' as city_name,
length(arrayDistinct(arrayFlatten(groupArray(par_user_list)))) as baoming_user_num,
length(arrayDistinct(arrayFlatten(groupArray(com_user_list)))) as finish_user_num,
sum(com_order_num+lose_order_num) as tot_valid_order_num,
sum(reward_value)/100 as tot_cost
from dws.dws_ck_silkworm_challenge a
where a.dt between toString($begin_date$) and toString($end_date$)
    and a.challenge_id>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=1 -- 打卡
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2



-- sr
-- 挑战赛
-- 分城市
select 
substring(cast(dt as string),1,7) as mon,
b.city_name,
array_length(par_user_list) as baoming_user_num,
array_length(com_user_list) as finish_user_num,
sum(com_order_num+lose_order_num) as tot_valid_order_num,
sum(reward_value)/100 as tot_cost
from dws.dws_sr_silkworm_challenge_td a
left join (select city_name,
                substring(cast(city_id as string),1,4) as city_id
        from dim.dim_silkworm_county
        group by 1,2) b
    on cast(a.baoming_city_id as string)=b.city_id
where a.dt between $begin_date$ and $end_date$
    and cast(a.challenge_id as int)>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=1 -- 打卡
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2,3,4

union all

-- 全部
select 
substring(cast(dt as string),1,7) as mon,
'全部' as city_name,
array_length(par_user_list) as baoming_user_num,
array_length(com_user_list) as finish_user_num,
sum(com_order_num+lose_order_num) as tot_valid_order_num,
sum(reward_value)/100 as tot_cost
from dws.dws_sr_silkworm_challenge_td a
where a.dt between $begin_date$ and $end_date$
    and cast(a.challenge_id as int)>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=1 -- 打卡
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2,3,4



============== 团长赛日数据
-- CK
-- 挑战赛
-- 分城市
select 
    substring(dt,1,7) as `月`,
    b.city_name as `城市`,
    length(arrayDistinct(arrayFlatten(groupArray(par_user_list)))) as `报名用户量`,
    length(arrayDistinct(arrayFlatten(groupArray(com_user_list)))) as `完成用户量`,
    sum(invited_user_num_dt) as `有效用户量`,
    sum(new_user_num) as `有效新增用户量`, -- 也是 拉新用户量
    sum(order_num_dt) as `有效用户订单量`,
    sum(reward_value)/100 as `活动支出`,
    sum(order_num_dt) as `新增用户订单量`
from dws.dws_ck_silkworm_challenge a
left join (select city_name,
                substring(toString(city_id),1,4) as city_id
        from dim.dim_region_code
        group by 1,2) b
    on toString(a.baoming_city_id)=b.city_id
where a.dt between toString($begin_date$) and toString($end_date$)
    and a.challenge_id>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=2 -- 团长
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2

union all 

-- 全部
select 
    substring(dt,1,7) as `月`,
    '全部' as `城市`,
    length(arrayDistinct(arrayFlatten(groupArray(par_user_list)))) as `报名用户量`,
    length(arrayDistinct(arrayFlatten(groupArray(com_user_list)))) as `完成用户量`,
    sum(invited_user_num_dt) as `有效用户量`,
    sum(new_user_num) as `有效新增用户量`, -- 也是 拉新用户量
    sum(order_num_dt) as `有效用户订单量`,
    sum(reward_value)/100 as `活动支出`,
    sum(order_num_dt) as `新增用户订单量`
from dws.dws_ck_silkworm_challenge a
where a.dt between toString($begin_date$) and toString($end_date$)
    and a.challenge_id>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=2 -- 团长
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2



-- 挑战赛
-- 分城市
select 
    substring(cast(dt as string),1,7) as `月`,
    b.city_name as `城市`,
    array_length(par_user_list) as `报名用户量`,
    array_length(com_user_list) as `完成用户量`,
    sum(invited_user_num_dt) as `有效用户量`,
    sum(new_user_num) as `有效新增用户量`, -- 也是 拉新用户量
    sum(order_num_dt) as `有效用户订单量`,
    sum(reward_value)/100 as `活动支出`,
    sum(order_num_dt) as `新增用户订单量`
from dws.dws_sr_silkworm_challenge_td a
left join (select city_name,
                substring(cast(city_id as string),1,4) as city_id
        from dim.dim_silkworm_county
        group by 1,2) b
    on cast(a.baoming_city_id as string)=b.city_id
where a.dt between $begin_date$ and $end_date$
    and cast(a.challenge_id as int)>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=2 -- 团长
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2,3,4

union all

-- 全部
select 
    substring(cast(dt as string),1,7) as `月`,
    '全部' as `城市`,
    array_length(par_user_list) as `报名用户量`,
    array_length(com_user_list) as `完成用户量`,
    sum(invited_user_num_dt) as `有效用户量`,
    sum(new_user_num) as `有效新增用户量`, -- 也是 拉新用户量
    sum(order_num_dt) as `有效用户订单量`,
    sum(reward_value)/100 as `活动支出`,
    sum(order_num_dt) as `新增用户订单量`
from dws.dws_sr_silkworm_challenge_td a
where a.dt between $begin_date$ and $end_date$
    and cast(a.challenge_id as int)>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=2 -- 团长
    and a.challenge_id in ($challenge_id$)
    and a.user_level in ($user_level$)
group by 1,2,3,4


=============== 打卡赛日数据
-- 挑战赛
-- 分城市
select 
    a.challenge_id as `活动ID`,
    a.challenge_name as `活动名称`,
    b.city_name as `城市`,
    array_length(par_user_list) as `报名用户量`,
    array_length(com_user_list) as `完成用户量`,
    sum(com_order_num+lose_order_num) as `活动订单量`,
    sum(reward_value)/100 as `活动支出`
from dws.dws_sr_silkworm_challenge_td a
left join (select city_name,
                substring(cast(city_id as string),1,4) as city_id
        from dim.dim_silkworm_county
        group by 1,2) b
    on cast(a.baoming_city_id as string)=b.city_id
where a.dt between $begin_date$ and $end_date$
    and cast(a.challenge_id as int)>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=1 -- 打卡
    and a.user_level in ($user_level$)
group by 1,2,3,4,5




date_sub(current_date(),interval 1 day)

-- 挑战赛
-- 分城市
select 
    a.challenge_id as `活动ID`,
    a.challenge_name as `活动名称`,
    b.city_name as `城市`,
    array_length(par_user_list) as `报名用户量`,
    array_length(com_user_list) as `完成用户量`,
    sum(invited_user_num_dt) as `有效用户量`,
    sum(new_user_num) as `有效新增用户量`, -- 也是 拉新用户量
    sum(order_num_dt) as `有效用户订单量`,
    sum(reward_value)/100 as `活动支出`,
    sum(order_num_dt) as `新增用户订单量`
from dws.dws_sr_silkworm_challenge_td a
left join (select city_name,
                substring(cast(city_id as string),1,4) as city_id
        from dim.dim_silkworm_county
        group by 1,2) b
    on cast(a.baoming_city_id as string)=b.city_id
where a.dt between $begin_date$ and $end_date$
    and cast(a.challenge_id as int)>=98 -- 2024年6月1日开始配置的挑战赛
    and a.challenge_type=2 -- 团长
    and a.user_level in ($user_level$)
group by 1,2,3,4,5









