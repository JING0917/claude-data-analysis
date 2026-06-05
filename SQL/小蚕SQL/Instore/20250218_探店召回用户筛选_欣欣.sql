大禾 这个再要一份数据奥 绑定674、511、988、1017、1032、1054、1034、858、686、675、1008的用户
【用户ID 绑定企微 大众等级 小红书粉丝 性别 下单次数 完单次数（有核销时间） 最近一次核销时间 最近一次访问探店时间（访问探店首页+活动页）】

-- 有多次绑定记录，需业务定如何取
with t1 as (
select
    user_id,create_date,bind_interior_staff_wework_id
from
    (select
        user_id,
        date(create_time) as create_date,
        bind_interior_staff_wework_id,
        row_number() over(partition by user_id order by create_time desc) as rk
    from dwd.dwd_sr_silkworm_explore_bind_wework_record
    where status=1
    ) a
where rk=1
    and bind_interior_staff_wework_id in (674,511,988,1017,1032,1054,1034,858,686,675,1008)
),

-- 下单和核销订单量
t2 as (
select
    user_id,
    count(1) as order_num,
    sum(if(substr(verify_time,1,10)='1970-01-01',0,1)) as verify_order_num,
    max(verify_time) as latest_verify_time
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
),


-- 粉丝和等级
t3 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    -- and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    -- and dp_user_lvl>=5
    )
),

-- 用户位置信息
t4 as (
select
    user_id,update_time,province,city,county,address_detail
from dim.dim_silkworm_user_location
),

-- 性别
t5 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender,
    accu_valid_order_num
from dim.dim_silkworm_user
),

drop view if exists t6;
create view IF NOT EXISTS t3 (
    user_id,
    latest_viewdate
)
as (
select
	user_id,
	max(statistics_date) as latest_viewdate
from dws.dws_sr_traffic_user_d
where statistics_date between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
	and user_id regexp '^[0-9]{1,9}$'
	and (explore_homepage_pv+explore_activity_detailpage_pv)>0
group by 1
);






select 
    t1.user_id `用户ID`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    t5.gender `性别`,
    t3.dp_user_lvl `大众点评等级`,
    t3.xiaohongshu_fans_num `小红书粉丝数`,
    t2.order_num `下单量`,
    t2.verify_order_num `核销订单量`,
    t2.latest_verify_time `最近一次核销时间`,
    t6.latest_viewdate `最近一次访问探店日期`,
    t4.province `用户定位省份`,
    t4.city `用户定位城市`,
    t4.county `用户定位区县`,
    t4.address_detail `用户定位地址`
from t1
left join t3 on t3.user_id=t1.user_id
left join t2 on t2.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
left join t5 on t5.user_id=t1.user_id
left join t6 on t6.user_id=t1.user_id
;