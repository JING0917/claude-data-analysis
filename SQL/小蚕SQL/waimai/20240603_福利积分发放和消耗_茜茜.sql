--SQL
--******************************************************************--
--author: dahe
--create time: 2024-06-03 19:13:57
--******************************************************************--


-- 任务积分
-- desc dwd.dwd_hive_market_activity_task_user_point_history_partition

-- 最小分区 2023-11-10
-- show partitions dwd.dwd_hive_market_activity_task_user_point_history_partition

-- select 
-- min(`day`) as min_day
-- from dwd.dwd_hive_market_activity_task_user_point_history_partition
-- where year='2023' and month='11'

-- select * from dwd.dwd_hive_market_activity_task_user_point_history_partition
-- where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2023-11-10' and '2023-11-10'
-- limit 10



-- 用户获取和消耗积分
drop table if exists t1;

cache table t1 as
select
    b.user_id,
    if(length(c.phone)>=11,1,0) as is_phone,
    `发放积分`-`消耗积分` as remain_point
from (select 
            user_id,
            sum(`发放积分`) as `发放积分`,
            sum(`消耗积分`) as `消耗积分`
        -- 积分发放
        from (select user_id,
            sum(current_operate_get_point) as `发放积分`,
            0 as `消耗积分`
        from dwd.dwd_hive_market_activity_task_user_point_history_partition
        where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2023-11-10' and '2023-12-31'
            and current_operate_get_point>0
        group by user_id

        union all
        -- 积分消耗
        select user_id,
            0 as `发放积分`,
            sum(abs(current_operate_get_point)) as `消耗积分`
        from dwd.dwd_hive_market_activity_task_user_point_history_partition
        where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-01-01' and date_sub(current_date,1)
            and current_operate_get_point<0
        group by user_id
            ) a
        group by user_id
        ) b
left join dim.dim_silkworm_user c
    on b.user_id=c.user_id
;

-- 数据量：1,331,100  用户量：1,331,100
select count(*) as tot,count(distinct user_id) as cnt from t1;

-- 最小剩余积分：-205468  最大剩余积分：478120
select min(remain_point) as min_remain_point,max(remain_point) as max_remain_point from t1;

select * from t1 where remain_point=-205468 or remain_point=478120;

-- 取剩余积分的分位值
drop table if exists t2;

cache table t2 as
select
    percentile(remain_point,0.1) as f10_interval, -- -50
    percentile(remain_point,0.2) as f20_interval, -- 70
    percentile(remain_point,0.3) as f30_interval, -- 400
    percentile(remain_point,0.4) as f40_interval, -- 620
    percentile(remain_point,0.5) as f50_interval, -- 1100
    percentile(remain_point,0.6) as f60_interval, -- 1450
    percentile(remain_point,0.7) as f70_interval, -- 2220
    percentile(remain_point,0.8) as f80_interval, -- 3250
    percentile(remain_point,0.9) as f90_interval -- 5320
from t1
;

select * from t2;


-- 取各分分位值下用户量
select
    fw_level as `分位值`,
    count(user_id) as `用户量`,
    count(if(is_phone=1,user_id,null)) as `有手机号用户量`
from(select 
        user_id,
        is_phone,
        case when remain_point<=f10_interval then 1
            when remain_point>f10_interval and remain_point<=f20_interval then 2
            when remain_point>f20_interval and remain_point<=f30_interval then 3
            when remain_point>f30_interval and remain_point<=f40_interval then 4
            when remain_point>f40_interval and remain_point<=f50_interval then 5
            when remain_point>f50_interval and remain_point<=f60_interval then 6
            when remain_point>f60_interval and remain_point<=f70_interval then 7
            when remain_point>f70_interval and remain_point<=f80_interval then 8
            when remain_point>f80_interval and remain_point<=f90_interval then 9
            when remain_point>f90_interval then 10
        end as fw_level
    from t1 left join t2
        on 1=1
    ) a
group by 1;

-- 90分位值以上的积分分布
drop table if exists t3;

cache table t3 as
select
    percentile(remain_point,0.1) as f10_interval, -- 5650
    percentile(remain_point,0.2) as f20_interval, -- 6020
    percentile(remain_point,0.3) as f30_interval, -- 6440
    percentile(remain_point,0.4) as f40_interval, -- 6940
    percentile(remain_point,0.5) as f50_interval, -- 7510
    percentile(remain_point,0.6) as f60_interval, -- 8240
    percentile(remain_point,0.7) as f70_interval, -- 9160
    percentile(remain_point,0.8) as f80_interval, -- 10460
    percentile(remain_point,0.9) as f90_interval -- 12678
from t1
where remain_point>5320
;

select * from t3;

-- 90分位值以上各分位值下用户量
select
    fw_level as `分位值`,
    count(user_id) as `用户量`,
    count(if(is_phone=1,user_id,null)) as `有手机号用户量`
from(select 
        user_id,
        is_phone,
        case when remain_point<=f10_interval then 1
            when remain_point>f10_interval and remain_point<=f20_interval then 2
            when remain_point>f20_interval and remain_point<=f30_interval then 3
            when remain_point>f30_interval and remain_point<=f40_interval then 4
            when remain_point>f40_interval and remain_point<=f50_interval then 5
            when remain_point>f50_interval and remain_point<=f60_interval then 6
            when remain_point>f60_interval and remain_point<=f70_interval then 7
            when remain_point>f70_interval and remain_point<=f80_interval then 8
            when remain_point>f80_interval and remain_point<=f90_interval then 9
            when remain_point>f90_interval then 10
        end as fw_level
    from t1 inner join t3
        on 1=1
where t1.remain_point>5320
    ) a
group by 1;