dws.dws_sr_marketing_ma_recon_trigger_day -- 触达数据
dws.dws_sr_marketing_ma_recon_user_trans_day -- 触达转化

dim.dim_ma_experiment -- 自动营销实验
dim.dim_ma_plan -- 自动营销计划
dim.dim_ma_plan_target -- 目标


select * from dws.dws_sr_marketing_ma_recon_user_trans_day limit 10;

select * from dws.dws_sr_marketing_ma_recon_trigger_day limit 10;



-- ● general_visit_num
-- ● delivery_finished_order_num
-- ● delivery_promotion_visit_num
-- ● delivery_canceled_order_num
-- ● delivery_submitted_order_num
-- ● instore_finished_order_num
-- ● instore_cancel_order_num
-- ● instore_promotion_visit_num
-- ● instore_submitted_order_num
-- ● instore_portal_visit_num
-- ● instore_paid_order_num


dws.dws_sr_marketing_ma_recon_h

=================== 正式跑数据

with event_info as (
select event_ename,event_cname from dim.dim_ma_event
group by 1,2
),

target_info as (
select
    plan_id,
    auto_id as target_id, -- 计划目标ID
    case when type=1 then '首要目标'
        when type=2 then '次要目标1'
        when type=3 then '次要目标2'
        when type=4 then '次要目标3'
        when type=5 then '次要目标4'
    else '其他' end target_tname, -- 目标类型名称
    value as target_value, -- 计划目标值
    replace(replace(replace(replace(get_json_string(replace(replace(value,'[{','{'),']}]',']}'),'$.value'),'[',''),']',''),'"',''),',','至') as time_parse,
    replace(replace(replace(get_json_string(replace(replace(value,'[{','{'),']}]',']}'),'$.first_level'),'[',''),']',''),'"','') as first_level
from dim.dim_ma_plan_target
),


t1 as (
select
	a.plan_id,
	a.plan_name,
	coalesce(a.exp_id,0) as exp_id,
	coalesce(b.exp_name,'全部') as exp_name,
	coalesce(b.expflow_weight,'100') as expflow_weight,
	coalesce(b.auto_id,0) as sub_exp_id,--  实验二级ID 即实验组ID
	c.target_id, -- 计划目标ID
	-- c.target_value, -- 计划目标值
    c.target_tname, -- 目标类型名称
	concat(c.time_parse,d.event_cname) as target_name -- 计划目标值
from
-- 运营计划
(select
	auto_id as plan_id, -- 计划ID
	plan_name,
	exp_id -- 实验ID
from dim.dim_ma_plan
where status=1 -- 开启
    and auto_id<>9 -- 剔除测试计划
) a
-- 实验
left join dim.dim_ma_experiment b on a.exp_id=b.exp_id
left join target_info c on a.plan_id=c.plan_id -- c.auto_id  -- 以auto_id做关联时，无数据 待确认是否调整口径
left join event_info d on c.first_level=d.event_ename
),


-- MA计划目标实际触发和达成人数
-- 历史原因，pid=10的计划，做保留处理
t2 as (
select
    a.plan_id,
    a.plan_target_id,
    a.exp_auto_id,
    a.plan_reach_num,
    a.reach_users,
    b.reached_num,
    a.finished_num
from
(select 
    plan_id,
    plan_target_id,
    exp_auto_id,
    5396 as plan_reach_num, -- 计划触达人数
    reach_users, -- 触达人数
    array_length(target_finish_users) as finished_num -- 目标完成人数
from dws.dws_sr_marketing_ma_recon_trigger_day
where date(dt)='2025-02-06'
    and plan_id=10
) a
left join (
        select 
            plan_id,
            plan_target_id,
            exp_auto_id,
            sum(reach_finished_users) as reached_num -- 触达成功人数
        from dws.dws_sr_marketing_ma_recon_trigger_day
        where date(dt) between '2025-01-21' and '2025-02-06'
            and plan_id=10
        group by 1,2,3
) b
on a.plan_id=b.plan_id and a.plan_target_id=b.plan_target_id and a.exp_auto_id=b.exp_auto_id
),


-- 用户转化数据
t3 as (
select
    -- date(dt) as dt,
    plan_id,
    exp_auto_id,
    array_length(array_unique_agg(order_users)) as order_unum, -- 下单用户量
    sum(trigger_user_order) order_num, -- 完单量
    sum(order_redpacket_amt) userd_rp_amt, -- 使用红包金额
    sum(order_extra_rebate) vip_rebate_amt, -- VIP额外返利使用金额
    sum(order_challenge_expend) challenge_amt, -- 挑战赛支出
    sum(order_profit) order_profit-- 完单利润
from dws.dws_sr_marketing_ma_recon_user_trans_day
where date(dt) between '2025-01-21' and '2025-01-31'
group by 1,2
),


-- 计划触达人数
-- exp_id 无值时是0
plan_touch as (
select 
    date_format(dt,'%Y-%m-%d') as dat,
    plan_id,
    exp_id,
    user_nums 
from dim.dim_plan_crowd_d
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
),

-- MA计划目标实际触发和达成人数
-- exp_auto_id 无值时是0
touched_info as (
select 
    date_format(dt,'%Y-%m-%d') as dat,
    plan_id,
    plan_target_id,
    exp_auto_id,
    array_length(target_finish_users) as finished_num, -- 目标完成人数
    reach_finished_users as reached_num, -- 触达成功人数
    reach_users -- 触达人数
from dws.dws_sr_marketing_ma_recon_trigger_day
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
),

-- 计划触发和实际触达、完成
-- pid<>10 
t4 as (
select
    a.dat,
    a.plan_id,
    b.plan_target_id,
    a.exp_id,
    a.user_nums as plan_reach_num, -- 计划触发
    b.reach_users, -- 已触发
    b.reached_num, -- 触达成功
    b.finished_num -- 目标完成人数
from plan_touch a left join touched_info b
on a.dat=b.dat and a.plan_id=b.plan_id and a.exp_id=b.exp_auto_id
),

-- 用户转化数据
-- pid<>10 
t5 as (
select
    date_format(dt,'%Y-%m-%d') as dat,
    plan_id,
    exp_auto_id,
    array_length(array_unique_agg(order_users)) as order_unum, -- 下单用户量
    sum(trigger_user_order) order_num, -- 完单量
    sum(order_redpacket_amt) userd_rp_amt, -- 使用红包金额
    sum(order_extra_rebate) vip_rebate_amt, -- VIP额外返利使用金额
    sum(order_challenge_expend) challenge_amt, -- 挑战赛支出
    sum(order_profit) order_profit-- 完单利润
from dws.dws_sr_marketing_ma_recon_user_trans_day
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1,2,3
)


-- pid=10计划统计结果
select
    date_format('2024-02-06','%Y-%m-%d') as dat,
    t1.plan_id,
    t1.plan_name,
    t1.exp_id,
    t1.exp_name,
    t1.expflow_weight,
    t1.sub_exp_id,--  实验二级ID 即实验组ID
    t1.target_id, -- 计划目标ID
    t1.target_tname, -- 目标类型名称
    t1.target_name, -- 计划目标值
    t2.plan_reach_num,
    t2.reach_users,
    t2.reached_num,
    t2.finished_num,
    t3.order_num, -- 完单量
    t3.userd_rp_amt, -- 使用红包金额
    t3.vip_rebate_amt, -- VIP额外返利使用金额
    t3.challenge_amt, -- 挑战赛支出
    t3.order_profit-- 完单利润
from t1
left join t2 on t1.plan_id=t2.plan_id and t1.target_id=t2.plan_target_id and t1.sub_exp_id=t2.exp_auto_id
left join t3 on t1.plan_id=t3.plan_id and t1.sub_exp_id=t3.exp_auto_id
where t1.plan_id=10

union all
-- pid<>10计划统计结果
select
    t4.dat,
    t1.plan_id,
    t1.plan_name,
    t1.exp_id,
    t1.exp_name,
    t1.expflow_weight,
    t1.sub_exp_id,--  实验二级ID 即实验组ID
    t1.target_id, -- 计划目标ID
    t1.target_tname, -- 目标类型名称
    t1.target_name, -- 计划目标值
    t4.plan_reach_num,
    t4.reach_users,
    t4.reached_num,
    t4.finished_num,
    t5.order_num, -- 完单量
    t5.userd_rp_amt, -- 使用红包金额
    t5.vip_rebate_amt, -- VIP额外返利使用金额
    t5.challenge_amt, -- 挑战赛支出
    t5.order_profit-- 完单利润
from t4
inner join t1 on t1.plan_id=t4.plan_id and t1.target_id=t4.plan_target_id and t1.sub_exp_id=t4.exp_id
left join t5 on t4.dat=t5.dat and t4.plan_id=t5.plan_id and t4.exp_id=t5.exp_auto_id
;


-- 结论
-- 实验组提高了用户的触达成功率和目标完成率，但由于实验组红包支出较高，导致ROI较低。为了控制成本，综合考虑促下单人群的低活跃性，可以设定一些条件，例如仅对特定商品或订单金额达到一定标准的用户提供首次完单免单。

-- 1、用户群体特性
-- 1）低活跃度：选择的用户群体是近30天内5天有下单行为且有效订单量0-2单用户，表明这些用户的活跃度较低。
-- 2）潜在价值：尽管活跃度低，但这些用户已经表现出一定的购买意愿，因此具有较高的潜在价值。

-- 2、数据对比
-- 1）目标完成率：
-- 实验组42.86%，高于对照组的35.03%。实验组在促进用户完成目标方面表现更好。
-- 2）完单量与利润：
-- 实验组完单量127单，完单利润306元；对照组分别为82单和193元。实验组在这两个指标上均优于对照组。
-- 4）ROI：
-- 实验组1.6，低于对照组的2.9。实验组的成本较高（红包金额117元 vs 对照组49元），导致其ROI较低。

-- 3、关键发现与问题
-- 1）触达成功率不足：
-- 实验组的触达成功率高于对照组，但仍然较低。需要进一步优化触达方式和内容，以提高用户参与度。



ma春节期间活动统计数据，可见下图：

结论
实验组目标完成率、完单量、利润均高于对照组，但由于实验组红包支出较高，导致ROI较低。

1、用户群体特性
1）低活跃度：选择的用户群体是近30天内5天有下单行为且有效订单量0-2单用户，表明这些用户的活跃度较低。
2）潜在价值：尽管活跃度低，但这些用户已经表现出一定的购买意愿，因此具有较高的潜在价值。

2、数据对比
1）目标完成率：
实验组42.86%，高于对照组的35.03%。实验组在促进用户完成目标方面表现更好。
2）完单量与利润：
实验组完单量127单，完单利润306元；对照组分别为82单和193元。实验组在这两个指标上均优于对照组。
4）ROI：
实验组1.6，低于对照组的2.9。实验组的成本较高（红包金额117元 vs 对照组49元），导致其ROI较低。为了控制成本，可以设定一些条件，例如仅对特定商品或订单金额达到一定标准的用户提供首次完单免单。

3、问题
1）触达成功率不足：
实验组触达成功率高于对照组，但仍然较低。需要进一步优化触达方式和内容，以提高用户参与度。





======= 汇总

with event_info as (
select event_ename,event_cname from dim.dim_ma_event
group by 1,2
),

target_info as (
select
    plan_id,
    auto_id as target_id, -- 计划目标ID
    case when type=1 then '首要目标'
        when type=2 then '次要目标1'
        when type=3 then '次要目标2'
        when type=4 then '次要目标3'
        when type=5 then '次要目标4'
    else '其他' end target_tname, -- 目标类型名称
    value as target_value, -- 计划目标值
    replace(replace(replace(replace(get_json_string(replace(replace(value,'[{','{'),']}]',']}'),'$.value'),'[',''),']',''),'"',''),',','至') as time_parse,
    replace(replace(replace(get_json_string(replace(replace(value,'[{','{'),']}]',']}'),'$.first_level'),'[',''),']',''),'"','') as first_level
from dim.dim_ma_plan_target
),


t1 as (
select
    a.plan_id,
    a.plan_name,
    coalesce(a.exp_id,0) as exp_id,
    coalesce(b.exp_name,'全部') as exp_name,
    coalesce(b.expflow_weight,'100') as expflow_weight,
    coalesce(b.auto_id,0) as sub_exp_id,
    c.target_id,
    c.target_tname,
    concat(c.time_parse,d.event_cname) as target_name
from
-- 运营计划
(select
    auto_id as plan_id,
    plan_name,
    exp_id
from dim.dim_ma_plan
where status=1 -- 开启
    and auto_id<>9 -- 剔除测试计划
) a
-- 实验
left join dim.dim_ma_experiment b on a.exp_id=b.exp_id
left join target_info c on a.plan_id=c.plan_id
left join event_info d on c.first_level=d.event_ename
),


-- MA计划目标实际触发和达成人数
-- 历史原因，pid=10的计划，做保留处理
t2 as (
select
    a.plan_id,
    a.plan_target_id,
    a.exp_auto_id,
    a.plan_reach_num,
    a.reach_users,
    b.reached_num,
    a.finished_num,
    a.acc_reach_users,
    a.acc_finished_num,
    b.reached_num as acc_reached_num
from
(select 
    plan_id,
    plan_target_id,
    exp_auto_id,
    5396 as plan_reach_num, -- 计划触达人数
    reach_users, -- 触达人数
    array_length(target_finish_users) as finished_num, -- 目标完成人数
    reach_users as acc_reach_users,-- 累计触达人数
    array_length(target_finish_users) as acc_finished_num -- 累计完成人数
from dws.dws_sr_marketing_ma_recon_trigger_day
where date_format(dt,'%Y-%m-%d')='2025-02-06'
    and plan_id=10
) a
left join (
        select 
            plan_id,
            plan_target_id,
            exp_auto_id,
            sum(reach_finished_users) as reached_num -- 触达成功人数
        from dws.dws_sr_marketing_ma_recon_trigger_day
        where date_format(dt,'%Y-%m-%d') between '2025-01-21' and '2025-02-06'
            and plan_id=10
        group by 1,2,3
) b
on a.plan_id=b.plan_id and a.plan_target_id=b.plan_target_id and a.exp_auto_id=b.exp_auto_id
),


-- 用户转化数据
t3 as (
select
    plan_id,
    exp_auto_id,
    array_length(array_unique_agg(order_users)) as order_unum,
    sum(trigger_user_order) order_num, 
    sum(order_redpacket_amt) userd_rp_amt,
    sum(order_extra_rebate) vip_rebate_amt,
    sum(order_challenge_expend) challenge_amt,
    sum(order_profit) order_profit
from dws.dws_sr_marketing_ma_recon_user_trans_day
where dt between '2025-01-21' and '2025-01-31'
group by 1,2
),


-- 计划触达人数
plan_touch as (
select 
    date_format(dt,'%Y-%m-%d') as dat,
    plan_id,
    exp_id,
    user_nums 
from dim.dim_plan_crowd_d
where date_format(dt,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
),

-- MA计划目标实际触发和达成人数
touched_info as (
select
        a.dat,
        a.plan_id,
        a.plan_target_id,
        a.exp_auto_id,
        b.finished_num, -- 目标完成人数
        a.reached_num, -- 触达成功人数
        a.reach_users, -- 触达人数
        b.acc_finished_num,
        a.acc_reached_num,
        a.acc_reach_users
from
    (select 
        date_format(dt,'%Y-%m-%d') as dat,
        plan_id,
        plan_target_id,
        exp_auto_id,
        -- array_length(target_finish_users) as finished_num, -- 目标完成人数
        reach_finished_users as reached_num, -- 触达成功人数
        reach_users, -- 触达人数
        -- sum(array_length(target_finish_users)) over(partition by plan_id,plan_target_id,exp_auto_id order by date_format(dt,'%Y-%m-%d')) as acc_finished_num,
        sum(reach_finished_users) over(partition by plan_id,plan_target_id,exp_auto_id order by date_format(dt,'%Y-%m-%d')) as acc_reached_num,
        sum(reach_users) over(partition by plan_id,plan_target_id,exp_auto_id order by date_format(dt,'%Y-%m-%d')) as acc_reach_users
    from dws.dws_sr_marketing_ma_recon_trigger_day
    where date_format(dt,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
    ) a
left join
    (
    select 
        date_format(dt,'%Y-%m-%d') as dat,
        plan_id,
        plan_target_id,
        exp_auto_id,
        array_length(target_finish_users) as finished_num, -- 目标完成人数
        sum(array_length(target_finish_users)) over(partition by plan_id,plan_target_id,exp_auto_id order by date_format(dt,'%Y-%m-%d')) as acc_finished_num,
    from dws.dws_sr_marketing_ma_recon_trigger_day
    where date_format(dt,'%Y-%m-%d') between $BEGIN_DATE$ and date_sub(current_date(),interval 0 day)
    ) b on a.dat=date_sub(b.dat,interval 1 day) and a.plan_id=b.plan_id and a.plan_target_id=b.plan_target_id and a.exp_auto_id=b.exp_auto_id
),

-- 计划触发和实际触达、完成
-- pid<>10 
t4 as (
select
    a.dat,
    a.plan_id,
    b.plan_target_id,
    a.exp_id,
    a.user_nums as plan_reach_num, -- 计划触发
    b.reach_users, -- 已触发
    b.reached_num, -- 触达成功
    b.finished_num, -- 目标完成人数
    b.acc_finished_num,
    b.acc_reached_num,
    b.acc_reach_users
from plan_touch a left join touched_info b
on a.dat=b.dat and a.plan_id=b.plan_id and a.exp_id=b.exp_auto_id
),


-- 用户转化数据
-- pid<>10 
t5 as (
select
    a.dat,
    a.plan_id,
    a.exp_auto_id,
    a.order_unum,
    a.order_num, 
    a.userd_rp_amt,
    a.vip_rebate_amt,
    a.challenge_amt,
    a.order_profit,
    b.acc_order_unum,
    a.acc_order_num,
    a.acc_userd_rp_amt,
    a.acc_vip_rebate_amt,
    a.acc_challenge_amt,
    a.acc_order_profit  
from
    (select
            dat,
            plan_id,
            exp_auto_id,
            order_unum,
            order_num, 
            userd_rp_amt,
            vip_rebate_amt,
            challenge_amt,
            order_profit,
            sum(order_num) over(partition by plan_id,exp_auto_id order by dat) as acc_order_num,
            sum(userd_rp_amt) over(partition by plan_id,exp_auto_id order by dat) as acc_userd_rp_amt,
            sum(vip_rebate_amt) over(partition by plan_id,exp_auto_id order by dat) as acc_vip_rebate_amt,
            sum(challenge_amt) over(partition by plan_id,exp_auto_id order by dat) as acc_challenge_amt,
            sum(order_profit) over(partition by plan_id,exp_auto_id order by dat) as acc_order_profit
    from
        (select
            date_format(dt,'%Y-%m-%d') as dat,
            plan_id,
            exp_auto_id,
            array_length(array_unique_agg(order_users)) as order_unum,
            sum(trigger_user_order) order_num, 
            sum(order_redpacket_amt) userd_rp_amt,
            sum(order_extra_rebate) vip_rebate_amt,
            sum(order_challenge_expend) challenge_amt,
            sum(order_profit) order_profit
        from dws.dws_sr_marketing_ma_recon_user_trans_day
        where date_format(dt,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
        group by 1,2,3
        ) a1
    group by 1,2,3,4,5,6,7,8,9
    ) a
    left join 
    -- 累计下单用户量
        (select
                date_format(dt,'%Y-%m-%d') as dat,
                plan_id,
                exp_auto_id,
                sum(array_length(array_unique_agg(order_users))) over(partition by plan_id,exp_auto_id order by date_format(dt,'%Y-%m-%d')) as acc_order_unum
            from dws.dws_sr_marketing_ma_recon_user_trans_day
            where date_format(dt,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
        group by 1,2,3
            ) b
    on a.dat=b.dat and a.plan_id=b.plan_id and a.exp_auto_id=b.exp_auto_id
)


-- pid=10计划统计结果
select
    date_format('2024-02-06','%Y-%m-%d') as `统计日期`,
    t1.plan_id `计划ID`,
    t1.plan_name `计划名称`,
    t1.exp_id `实验ID`,
    coalesce(t1.exp_name,'全部') `实验名称`,
    t1.expflow_weight/100 `分流权重`,
    t1.sub_exp_id `实验组ID`,
    t1.target_id `目标ID`,
    t1.target_tname `目标类型名称`,
    t1.target_name `目标值`,
    t2.plan_reach_num `计划触发人数`,
    t2.reach_users `触发人数`,
    t2.reached_num `触达成功人数`,
    t2.finished_num `完成目标人数`,
    t3.order_unum `日下单用户数`,
    t3.order_num `日完单量`,
    t3.userd_rp_amt `日使用红包金额`,
    t3.vip_rebate_amt `日VIP额外返利使用金额`,
    t3.challenge_amt `日挑战赛支出`,
    t3.order_profit `日完单利润`,
    t2.acc_reach_users `累计触发人数`,
    t2.acc_finished_num `累计完成目标人数`,
    t2.acc_reached_num `累计触达成功人数`,
    t3.order_unum `累计下单用户数`,
    t3.order_num `累计完单量`,
    t3.userd_rp_amt `累计使用红包金额`,
    t3.vip_rebate_amt `累计VIP额外返利使用金额`,
    t3.challenge_amt `累计挑战赛支出`,
    t3.order_profit `累计完单利润`
from t1
left join t2 on t1.plan_id=t2.plan_id and t1.target_id=t2.plan_target_id and t1.sub_exp_id=t2.exp_auto_id
left join t3 on t1.plan_id=t3.plan_id and t1.sub_exp_id=t3.exp_auto_id
where t1.plan_id=10

union all
-- pid<>10计划统计结果
select
    t4.dat `统计日期`,
    t1.plan_id `计划ID`,
    t1.plan_name `计划名称`,
    t1.exp_id `实验ID`,
    coalesce(t1.exp_name,'全部') `实验名称`,
    t1.expflow_weight/100 `分流权重`,
    t1.sub_exp_id `实验组ID`,
    t1.target_id `目标ID`,
    t1.target_tname `目标类型名称`,
    t1.target_name `目标值`,
    t4.plan_reach_num `计划触发人数`,
    t4.reach_users `触发人数`,
    t4.reached_num `触达成功人数`,
    t4.finished_num `完成目标人数`,
    t5.order_unum `下单用户数`,
    t5.order_num `完单量`,
    t5.userd_rp_amt `使用红包金额`,
    t5.vip_rebate_amt `VIP额外返利使用金额`,
    t5.challenge_amt `挑战赛支出`,
    t5.order_profit `完单利润`,
    t4.acc_reach_users `累计触发人数`,
    t4.acc_finished_num `累计完成目标人数`,
    t4.acc_reached_num `累计触达成功人数`,
    t5.acc_order_unum `累计下单用户数`,
    t5.acc_order_num `累计完单量`,
    t5.acc_userd_rp_amt `累计使用红包金额`,
    t5.acc_vip_rebate_amt `累计VIP额外返利使用金额`,
    t5.acc_challenge_amt `累计挑战赛支出`,
    t5.acc_order_profit `累计完单利润`
from t4
inner join t1 on t1.plan_id=t4.plan_id and t1.target_id=t4.plan_target_id and t1.sub_exp_id=t4.exp_id
left join t5 on t4.dat=t5.dat and t4.plan_id=t5.plan_id and t4.exp_id=t5.exp_auto_id
;


====================================
-- plan_id=36 单独统计
select
    plan_id,
    auto_id as target_id, -- 计划目标ID
    case when type=1 then '首要目标'
        when type=2 then '次要目标1'
        when type=3 then '次要目标2'
        when type=4 then '次要目标3'
        when type=5 then '次要目标4'
    else '其他' end target_tname, -- 目标类型名称
    value as target_value, -- 计划目标值
    replace(replace(replace(replace(get_json_string(replace(replace(value,'[{','{'),']}]',']}'),'$.value'),'[',''),']',''),'"',''),',','至') as time_parse,
    replace(replace(replace(get_json_string(replace(replace(value,'[{','{'),']}]',']}'),'$.first_level'),'[',''),']',''),'"','') as first_level
from dim.dim_ma_plan_target
where plan_id=36
;

-- 165521 人
with plan_user as (
select user_id 
from dwd.dwd_sr_marketing_ma_plan_takepart
where plan_id=36
group by 1
),

-- 访问小蚕
view_info as (
select unnest_bitmap as user_id from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where date_format(dt,'%Y-%m-%d') between '2025-03-03' and date_sub(current_date(),interval 1 day)
group by 1
),

-- 访问主页
view_zy as (
select unnest_bitmap as user_id from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where date_format(dt,'%Y-%m-%d') between '2025-03-03' and date_sub(current_date(),interval 1 day)
    and event_ename regexp 'Homepage'
group by 1
),

-- 霸王餐详情页浏览
view_dp as (
select unnest_bitmap as user_id from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where date_format(dt,'%Y-%m-%d') between '2025-03-03' and date_sub(current_date(),interval 1 day)
    and event_ename='Takeout_Activity_Detail_View'
group by 1
),

order_info as (
select
    user_id
    ,count(auto_id) as wm_order_num -- 订单量
    ,count(if(order_status in (2,8),auto_id,null)) as wm_valid_order_num -- 有效订单量
    ,sum(if(order_status=2,profit,0)) as wm_profit -- 有效单利润
    ,sum(if(order_status in (2,8),redpacket_amt,0)) as redpacket_amt
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 10 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(order_time,'%Y-%m-%d') between '2025-03-03' and date_sub(current_date(),interval 1 day)
group by 1
)

select
    count(distinct plan_user.user_id) as `触达用户量`,
    count(distinct if(view_info.user_id is not null,plan_user.user_id,null)) `访问小蚕用户量`,
    count(distinct if(view_zy.user_id is not null,plan_user.user_id,null)) `访问主页用户量`,
    count(distinct if(view_dp.user_id is not null,plan_user.user_id,null)) `霸王餐详情页浏览用户量`,
    count(distinct if(order_info.user_id is not null and wm_order_num>0,plan_user.user_id,null)) as `霸王餐下单用户量`,
    sum(wm_order_num) as `霸王餐下单量`,
    count(distinct if(order_info.user_id is not null and wm_valid_order_num>0,plan_user.user_id,null)) as `霸王餐有效订单用户量`,
    sum(wm_valid_order_num) as `霸王餐有效订单量`,
    sum(redpacket_amt) as `使用红包金额`,
    sum(wm_profit) as `霸王餐有效订单利润`
from plan_user left join view_info on plan_user.user_id=view_info.user_id
left join view_zy on plan_user.user_id=view_zy.user_id
left join view_dp on plan_user.user_id=view_dp.user_id
left join order_info on plan_user.user_id=order_info.user_id
;













