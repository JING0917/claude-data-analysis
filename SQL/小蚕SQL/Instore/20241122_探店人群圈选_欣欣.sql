-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id,bind_interior_staff_wework_account
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id in (674,511)
    and status=0
group by 1,2,3
)

-- 千粉用户绑定粉丝企微
select 
    a.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    concat('企',t1.bind_interior_staff_wework_account) `添加探店企微账号`
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b
on a.user_id=b.user_id
    and b.city_id=3301 -- 杭州市
left join t1
on a.user_id=t1.user_id
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
where a.xiaohongshu_fans_num>=1000
;

============================================
-- 绑定企微858且最近一次下单超过7天
-- 绑定企微
with t1 as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1
),

-- 下单
-- t2 as (
--         select
--             user_id
--         from dwd.dwd_sr_silkworm_explore_order
--         where cast(dt as string)>='2024-06-18'
--             and promotion_type in (1,4)
--         group by 1
-- )


-- -- 674未下单用户
-- select t1.user_id from t1 left join t2 on t1.user_id=t2.user_id where t2.user_id is null;



-- 最近订单日期间隔
t2 as (
select
    user_id,
    date_diff('day',current_date(),max_order_date) as diff_days
from (
        select
            user_id,
            max(dt) as max_order_date
        from dwd.dwd_sr_silkworm_explore_order
        where cast(dt as string)>='2024-06-18'
            and promotion_type in (1,4)
        group by 1
    ) a
),

-- 用户位置信息
t3 as (
select
    silk_id,province,city,district,address_detail
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
),

-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
)



-- 858 且最近一次下单日期间隔>7天
select 
    t1.user_id `用户ID`,
    t4.wechat_nickname `微信昵称`,
    t4.dp_user_lvl `大众点评等级`,
    t4.xiaohongshu_fans_num `小红书粉丝数`,
    t3.province `省份`,
    t3.city `城市`,
    t3.district `区县`,
    t3.address_detail `地址`
from t1 
left join t2 on t1.user_id=t2.user_id and t2.diff_days>7
left join t3 on t1.user_id=t3.silk_id
left join t4 on t1.user_id=t4.user_id
where t2.user_id is null;





========================
-- 绑定企微674且未下探店单
-- 绑定企微
with t1 as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1
),

-- 下单
t2 as (
        select
            user_id
        from dwd.dwd_sr_silkworm_explore_order
        where cast(dt as string)>='2024-06-18'
            and promotion_type in (1,4)
        group by 1
),

-- 用户位置信息
t3 as (
select
    silk_id,province,city,district,address_detail,longitude as end_lon,latitude as end_lat
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
),

-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
)

-- -- 674未下单用户
select 
    t1.user_id `用户ID`,
    t4.wechat_nickname `微信昵称`,
    t4.dp_user_lvl `大众点评等级`,
    t4.xiaohongshu_fans_num `小红书粉丝数`,
    t3.province `省份`,
    t3.city `城市`,
    t3.district `区县`,
    t3.address_detail `地址`
from t1 
left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.silk_id
left join t4 on t1.user_id=t4.user_id
where t2.user_id is null;




=======
-- 绑定企微且近7天访问2007店铺且未下单
-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),


-- 昨日访问探店页面 全站
t2 as (
select
    cast(user_id as int) as user_id,count(1) as cnt
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_name in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View')
    and user_id regexp '^[0-9]{1,9}$'
    and store_id='2007'
group by 1
having count(1)>0
),

-- 下单即核销
t3 as (
        select
            user_id
        from dwd.dwd_sr_silkworm_explore_order
        where cast(dt as string)>='2024-06-18'
            and substr(verify_time,1,10)='1970-01-01'
            and promotion_type in (1,4)
        group by 1
),

-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
)


select
    t1.user_id,
    t4.wechat_nickname,
    t4.xiaohongshu_fans_num,
    t4.dp_user_lvl
from t1
inner join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
where t3.user_id is null
;



======= 下单女生
-- 绑定企微
with t1 as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1
),

-- 下单即核销
t2 as (
select
    a.user_id
from
(select
    user_id,store_id,count(1) as order_num
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string)>='2024-06-18'
    and substr(verify_time,1,10)>='2024-10-21'
    and promotion_type in (1,4)
group by 1,2
having count(1)>=2
) a
inner join dim.dim_silkworm_explore_store b on a.store_id=b.store_id and b.sub_category_type=8 -- 甜品饮品
),

-- 性别
t3 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
)


select
    t1.user_id
from t1
inner join t2 on t1.user_id=t2.user_id
inner join t3 on t1.user_id=t3.user_id and t3.gender='女'
;


==============
-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),


-- 用户位置信息
t2 as (
select
    silk_id,b.store_id,
    ST_Distance_Sphere(a.longitude, a.latitude, b.longitude, b.latitude)/1000 as distance -- 距离 单位千米
from
(select
    silk_id,province,city,district,address_detail,longitude,latitude
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
) a
left join dim.dim_silkworm_explore_store b on 1=1 and b.store_id in (517,2007,1682)
),


-- 性别
t3 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
),

-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
)


select
    t2.store_id,
    t1.user_id,
    t1.bind_interior_staff_wework_id,
    t4.wechat_nickname,
    t4.xiaohongshu_fans_num,
    t4.dp_user_lvl
from t1
inner join t2 on t1.user_id=t2.silk_id and t2.distance<=5000
inner join t3 on t1.user_id=t3.user_id and t3.gender='女'
left join t4 on t1.user_id=t4.user_id
;



============

-- 绑定企微
with t1 as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1
),

-- 下单即核销
t2 as (
select
    a.user_id
from
(select
    user_id,store_id,count(1) as order_num
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string)>='2024-06-18'
    and substr(verify_time,1,10)>='2024-10-21'
    and promotion_type in (1,4)
group by 1,2
having count(1)>=2
) a
inner join dim.dim_silkworm_explore_store b on a.store_id=b.store_id and b.sub_category_type=8 -- 甜品饮品
),

-- 性别
t3 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
),

-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
)


select
    t1.user_id,
    t4.wechat_nickname,
    t4.xiaohongshu_fans_num,
    t4.dp_user_lvl
from t1
inner join t2 on t1.user_id=t2.user_id
inner join t3 on t1.user_id=t3.user_id and t3.gender='女'
left join t4 on t1.user_id=t4.user_id
;




========= 近1月核销1单 酒水女生
-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),

-- 下单即核销
t2 as (
select
    a.user_id
from
(select
    user_id,store_id,count(1) as order_num
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string)>='2024-06-18'
    and substr(verify_time,1,10)>='2024-10-21'
    and promotion_type in (1,4)
group by 1,2
having count(1)>=1
) a
inner join dim.dim_silkworm_explore_store b on a.store_id=b.store_id and b.sub_category_type in (8,9) -- 甜品饮品 休闲
),

-- 性别
t3 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
),

-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
)


select
    t1.user_id,
    t4.wechat_nickname,
    t4.xiaohongshu_fans_num,
    t4.dp_user_lvl
from t1
inner join t2 on t1.user_id=t2.user_id
inner join t3 on t1.user_id=t3.user_id and t3.gender='女'
left join t4 on t1.user_id=t4.user_id
;



杭州用户绑定了探店企微：用户id、微信昵称、性别、添加探店企微号、区域、详细地址、探店总订单（不校验订单状态）、探店已完成订单（有核销时间）、最近一次完单时间





-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),

-- 用户位置信息
t2 as (
select
    silk_id,province,city,district,address_detail,longitude,latitude
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
),


bind_innfo as (
select
    t1.user_id,
    t1.bind_interior_staff_wework_id,
    t2.district,
    t2.address_detail
from t1 inner join t2 on t1.user_id=t2.silk_id
),


-- 下单即核销
t3 as (
select
    user_id,
    count(1) as tot_order_num,
    count(if(substr(verify_time,1,10)<>'1970-01-01',order_id,null)) as finish_order_num
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string)>='2024-06-18'
    and promotion_type in (1,4)
group by 1
),

-- 性别
t4 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
),

-- 用户等级和微信昵称
t5 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
),


-- 下单时间
t6 as (
select
    user_id,
    max(verify_time) as latest_verify_time
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string)>='2024-06-18'
    and promotion_type in (1,4)
    and substr(verify_time,1,10)<>'1970-01-01'
group by 1
)


select
    a.user_id `用户ID`,
    a.bind_interior_staff_wework_id `绑定企微ID`,
    t5.wechat_nickname `微信昵称`,
    t4.gender `性别`,
    a.district `用户定位区县`,
    a.address_detail `用户定位地址`,
    t3.tot_order_num `探店订单量`,
    t3.finished_num `探店完单量`,
    t6.latest_verify_time `最近一次完单时间`
from bind_innfo a
left join t3 on a.user_id=t3.user_id
left join t4 on a.user_id=t4.user_id
left join t5 on a.user_id=t5.user_id
left join t6 on a.user_id=t6.user_id
;


================
-- 11月份探店完单10以上的用户
-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),

-- 用户位置信息
t2 as (
select
    silk_id,province,city,district,address_detail,longitude,latitude
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
),


bind_innfo as (
select
    t1.user_id,
    t1.bind_interior_staff_wework_id,
    t2.province,
    t2.city,
    t2.district,
    t2.address_detail
from t1 left join t2 on t1.user_id=t2.silk_id
),


-- 完单
t3 as (
select
    user_id,
    count(1) as tot_order_num
from dwd.dwd_sr_silkworm_explore_order
where cast(dt as string)>='2024-06-18'
    and substr(verify_time,1,10) between '2024-11-01' and '2024-11-29'
    and promotion_type in (1,4)
    and status in (4,5,19,20)
group by 1
having count(1)>=10
),

-- 性别
t4 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
),

-- 用户等级和微信昵称
t5 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
),


-- 下单时间
t6 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
)


select
    a.user_id `用户ID`,
    a.bind_interior_staff_wework_id `绑定企微ID`,
    t5.wechat_nickname `微信昵称`,
    t4.gender `性别`,
    t6.dp_user_lvl `点评等级`,
    t6.xiaohongshu_fans_num `小红书粉丝数`,
    a.province `用户定位省份`,
    a.city `用户定位城市`,
    a.district `用户定位区县`,
    a.address_detail `用户定位地址`
from bind_innfo a
inner join t3 on a.user_id=t3.user_id
left join t4 on a.user_id=t4.user_id
left join t5 on a.user_id=t5.user_id
left join t6 on a.user_id=t6.user_id
;





===========
①绑定511 674但是用户位置不在杭州的用户ID 企微ID 微信昵称 完单数量 用户定位地址 用户定位区县 用户定位省份
②绑定511 674的杭州用户但是未下过探店订单的 用户ID 企微ID 微信昵称 性别 用户定位城市 用户定位地址 用户定位区县 用户定位省份 大众点评等级  小红书粉丝数


-- 探店用户圈选
-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and bind_interior_staff_wework_id in (674,511) -- 绑定企微
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),


-- 完单
t2 as (
        select
            user_id,
            count(1) as order_num -- 完单量
        from dwd.dwd_sr_silkworm_explore_order
        where cast(dt as string) between '2024-06-16' and '2024-12-11' -- 订单创建日期，自定义周期，根据需要取
            and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
            and status in (4,5,19,20) -- 表示完单，不用时，请注释掉
        group by 1
),


-- 用户位置非杭州 近90天位置信息
t3 as (
select
    silk_id,
    province,
    city,
    district,
    address_detail
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and city<>'杭州市'
),


-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
),

-- 性别
t5 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
)



-- 导出圈选用户
select 
    t1.user_id `用户ID`,
    t1.bind_interior_staff_wework_id `企微ID`,
    t4.wechat_nickname `微信昵称`,
    t5.gender `性别`,
    t5.`年龄`,
    t3.province `用户定位省份`,
    t3.city `用户定位城市`,
    t3.district `用户定位区县`,
    t3.address_detail `用户定位地址`,
    t2.order_num `完单量`
from t1 
left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.silk_id
left join t4 on t1.user_id=t4.user_id
left join t5 on t1.user_id=t5.user_id
;




-- 探店用户圈选
-- 绑定企微
with t1 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and bind_interior_staff_wework_id in (674,511) -- 绑定企微
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),


-- 下单
t2 as (
        select
            user_id
        from dwd.dwd_sr_silkworm_explore_order
        where cast(dt as string) between '2024-06-16' and '2024-12-11' -- 订单创建日期，自定义周期，根据需要取
            and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
        group by 1
),


-- 用户位置非杭州 近90天位置信息
t3 as (
select
    silk_id,
    province,
    city,
    district,
    address_detail
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
),


-- 用户等级和微信昵称
t4 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
),

-- 性别
t5 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
)



-- 导出圈选用户
select 
    t1.user_id `用户ID`,
    t1.bind_interior_staff_wework_id `企微ID`,
    t4.wechat_nickname `微信昵称`,
    t4.dp_user_lvl `大众点评等级`,
    t4.xiaohongshu_fans_num `小红书粉丝数`,
    t5.gender `性别`,
    t5.`年龄`,
    t3.province `用户定位省份`,
    t3.city `用户定位城市`,
    t3.district `用户定位区县`,
    t3.address_detail `用户定位地址`
from t1 
inner join t3 on t1.user_id=t3.silk_id
left join t2 on t1.user_id=t2.user_id
left join t4 on t1.user_id=t4.user_id
left join t5 on t1.user_id=t5.user_id
where t2.user_id is null
;


===============
-- 新用户标签
-- 已添加企微
with t1 as (
select 
    user_id
from dim.dim_silkworm_explore_daren_cleanse 
where is_bind_wework=1
),

-- 核销订单量
t2 as (
select
    user_id,
    count(if(str_to_date(verify_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day),order_id,null)) as last7d_verify_order_num,
    count(if(str_to_date(verify_time,'%Y-%m-%d') between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 8 day),order_id,null)) as last15d_verify_order_num,
    count(if(str_to_date(verify_time,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 16 day),order_id,null)) as last30d_verify_order_num,
    count(if(str_to_date(verify_time,'%Y-%m-%d')>=date_sub(current_date(),interval 31 day),order_id,null)) as over3d_verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
)


select
    t2.user_id as `用户ID`,
    if(t2.last7d_verify_order_num>0,1,0) `近7天未下单已绑定企微用户`,
    if(t2.last15d_verify_order_num>0,1,0) `近8到15天未下单已绑定企微用户`,
    if(t2.last30d_verify_order_num>0,1,0) `近16到30天未下单已绑定企微用户`,
    if(t2.over3d_verify_order_num>0,1,0) `30天以上未下单已绑定企微用户`
from t1 inner join t2 on t1.user_id=t2.user_id
;


-- 是否有多个绑定日期  无
select
user_id,create_date,count(1) cnt
from
(select
    user_id,
    date(create_time) as create_date
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where status=1
group by 1,2) a
group by 1,2;


================== 企微标签
-- 已添加企微
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
),

-- 核销订单量
t2 as (
select
    user_id,
    sum(if(substr(verify_time,1,10)<>'1970-01-01',1,0)) as verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
),

-- 用户位置杭州 近7天位置信息
t3 as (
select
    user_id,city
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
),

-- 报名
t4 as (
select
    user_id,
    count(1) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
)

-- 结果出来后，需要将认证*天新用户是0的，做剔除
select
    t1.user_id,
    if(datediff(date_sub(current_date(),interval 1 day),t1.create_date)<=7 and (t2.verify_order_num=0 or t4.order_num is null),1,0) as `认证7天内新用户`,
    if(datediff(date_sub(current_date(),interval 1 day),t1.create_date) between 8 and 15 and (t2.verify_order_num=0 or t4.order_num is null),1,0) as `认证8-15天内新用户`,
    if(datediff(date_sub(current_date(),interval 1 day),t1.create_date) between 16 and 30 and (t2.verify_order_num=0 or t4.order_num is null),1,0) as `认证16-30天内新用户`,
    if(datediff(date_sub(current_date(),interval 1 day),t1.create_date)>30 and (t2.verify_order_num=0 or t4.order_num is null),1,0) as `认证30天以上新用户`,
    bind_interior_staff_wework_id as `绑定企微ID`
from t1
inner join t3 on t1.user_id=t3.user_id
left join t2 on t1.user_id=t2.user_id
left join t4 on t1.user_id=t4.user_id
group by 1,2,3,4,5,6
;




============= 核销用户分群

-- 核销订单量
with t1 as (
select
    user_id,
    sum(if(substr(verify_time,1,10)<>'1970-01-01',1,0)) as verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
),

-- 用户位置杭州 近7天位置信息
t2 as (
select
    user_id
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
),


-- 杭州用户
t3 as (
select
    t1.user_id,
    t1.verify_order_num,
    if(t1.verify_order_num=0,'新用户','老用户') as user_type
from t1
inner join t2 on t1.user_id=t2.user_id
)


select
    user_type `用户类型`,
    '核销订单量' as `指标名称`,
    PERCENTILE_CONT(verify_order_num,0.1) as `10分位值`,
    PERCENTILE_CONT(verify_order_num,0.2) as `20分位值`,
    PERCENTILE_CONT(verify_order_num,0.3) as `30分位值`,
    PERCENTILE_CONT(verify_order_num,0.4) as `40分位值`,
    PERCENTILE_CONT(verify_order_num,0.5) as `50分位值`,
    PERCENTILE_CONT(verify_order_num,0.6) as `60分位值`,
    PERCENTILE_CONT(verify_order_num,0.7) as `70分位值`,
    PERCENTILE_CONT(verify_order_num,0.8) as `80分位值`,
    PERCENTILE_CONT(verify_order_num,0.9) as `90分位值`, -- 21
    max(verify_order_num) as `最大值`
from t3
where verify_order_num>=21 -- 90分位值
group by 1,2
;



============
大禾 可以导一下绑定探店企微未完成过首单，小红书≥200粉，大众点评≥5级以上的杭州用户吗；表头：小蚕ID，微信昵称，绑定企微ID，最近一次访问探店页面时间，大众等级，小红书粉丝数，性别，位置，下单量


-- 已添加企微
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
),

-- 无核销订单用户
t2 as (
select
    user_id,
    sum(if(substr(verify_time,1,10)='1970-01-01',0,1)) as verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
),

-- 用户位置杭州 近7天位置信息
t3 as (
select
    user_id,update_time,province,city,county,address_detail
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
),

-- 报名
t4 as (
select
    user_id,
    count(1) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
),


-- 用户等级和微信昵称
t5 as (
select 
    a.user_id ,
    c.wechat_nickname,
    a.dp_user_lvl,
    a.xiaohongshu_fans_num
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id
left join dim.dim_silkworm_user_wechat c on b.user_wechat_id=c.user_wechat_id
),

-- 粉丝和等级
t6 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 性别
t7 as (
select user_id,
    year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)) as `年龄`,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender
from dim.dim_silkworm_user
)




-- 858 且最近一次下单日期间隔>7天
select 
    t3.user_id `用户ID`,
    t5.wechat_nickname `微信昵称`,
    t7.gender `性别`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    t6.dp_user_lvl `大众点评等级`,
    t6.xiaohongshu_fans_num `小红书粉丝数`,
    t4.order_num `下单量`,
    t3.province `省份`,
    t3.city `城市`,
    t3.county `区县`,
    t3.address_detail `地址`,
    cast(t3.update_time as string) `最近一次登录时间`
from t3
inner join t6 on t3.user_id=t6.user_id
left join t2 on t3.user_id=t2.user_id
left join t5 on t3.user_id=t5.user_id
left join t1 on t3.user_id=t1.user_id
left join t4 on t3.user_id=t4.user_id
left join t7 on t3.user_id=t7.user_id
where t2.verify_order_num=0 or t2.verify_order_num is null
;


============
绑定511但用户位置在上海的用户可以导一下小蚕ID 么


-- 有多次绑定记录，需业务定如何取
with t1 as (
select
    user_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where status=1
    and bind_interior_staff_wework_id=511
group by 1
),


-- 用户位置杭州 近7天位置信息
t2 as (
select
    user_id,update_time,province,city,county,address_detail
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and city='上海市'
)

select t2.* from t1 inner join t2 on t1.user_id=t2.user_id;



========= 探店新用户  11个用户群  用于首页弹窗投放

-- 近7天用户位置信息
with t1 as (
select
    user_id,update_time,province,city,county,address_detail
from dim.dim_silkworm_user_location
where date(update_time) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and city in ('上海市','广州市','武汉市','成都市')
    and county in ('浦东新区','闵行区','徐汇区','天河区','番禺区','增城区','武侯区','锦江区','成华区','洪山区','武昌区')
),

-- 用户核销订单量
t2 as (
select
    user_id,
    sum(if(substr(verify_time,1,10)='1970-01-01',0,1)) as verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
)


-- select
--     city,
--     county,
--     count(t1.user_id) as tot_unum,
--     count(distinct if(t2.verify_order_num=0 or t2.verify_order_num is null,t1.user_id,null)) as valid_unum
-- from t1
-- left join t2 on t1.user_id=t2.user_id
-- -- where t2.verify_order_num=0 or t2.verify_order_num is null
-- group by 1,2;

select
    concat(city,county,'探店新用户') as groupname, -- 用户群名称
    t1.user_id
from t1
left join t2 on t1.user_id=t2.user_id
where t2.verify_order_num=0 or t2.verify_order_num is null -- 无核销订单的用户，判定为新用户
;




=============
5级以上or200粉以上的用户需要导一下 用户ID 大众等级 小红书粉丝数 企微ID 完单数量（有核销订单）


-- 已添加企微
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
),

-- 核销订单量
t2 as (
select
    user_id,
    sum(if(substr(verify_time,1,10)='1970-01-01',0,1)) as verify_order_num
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
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
)




-- 858 且最近一次下单日期间隔>7天
select 
    t3.user_id `用户ID`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    t3.dp_user_lvl `大众点评等级`,
    t3.xiaohongshu_fans_num `小红书粉丝数`,
    t2.verify_order_num `核销订单量`
from t3
left join t2 on t3.user_id=t2.user_id
left join t1 on t3.user_id=t1.user_id
;





==============
大禾 绑定企业微信1017 1032 1054的用户ID 绑定企微 大众等级 小红书粉丝数 位置 下单次数 核销单量 性别 外卖已完成订单量 小蚕会员等级 这些信息可以导一下么

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
    and bind_interior_staff_wework_id in (1017,1032,1054)
),


-- 下单和核销订单量
t2 as (
select
    user_id,
    count(1) as order_num,
    sum(if(substr(verify_time,1,10)='1970-01-01',0,1)) as verify_order_num
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
)


select 
    t1.user_id `用户ID`,
    t5.gender `性别`,
    a.user_level `会员等级`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    t3.dp_user_lvl `大众点评等级`,
    t3.xiaohongshu_fans_num `小红书粉丝数`,
    t2.order_num `下单量`,
    t2.verify_order_num `核销订单量`,
    t5.accu_valid_order_num `霸王餐累计有效订单量`,
    t4.province `用户定位省份`,
    t4.city `用户定位城市`,
    t4.county `用户定位区县`,
    t4.address_detail `用户定位地址`
from t1
left join t3 on t3.user_id=t1.user_id
left join t2 on t2.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
left join t5 on t5.user_id=t1.user_id
left join dim.dim_silkworm_member a on a.user_id=t1.user_id
;




大禾 绑定674、511、988、1017、1032、1054的杭州用户ID 绑定企微 大众等级 小红书粉丝 下单次数 完单次数（有核销时间） 最近一次核销时间 这些信息可以导一下嘛

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
    and bind_interior_staff_wework_id in (674、511、988、1017、1032、1054)
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
)



select 
    t1.user_id `用户ID`,
    t1.bind_interior_staff_wework_id `添加探店企微ID`,
    t3.dp_user_lvl `大众点评等级`,
    t3.xiaohongshu_fans_num `小红书粉丝数`,
    t2.order_num `下单量`,
    t2.verify_order_num `核销订单量`,
    t2.latest_verify_time `最近一次核销时间`,
    t4.province `用户定位省份`,
    t4.city `用户定位城市`,
    t4.county `用户定位区县`,
    t4.address_detail `用户定位地址`
from t1
left join t3 on t3.user_id=t1.user_id
left join t2 on t2.user_id=t1.user_id
left join t4 on t4.user_id=t1.user_id
;






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
    and bind_interior_staff_wework_id in (674, 511, 988, 1017, 1032, 1054, 1034, 858, 686, 675, 1008, 513, 1070, 1069, 1102, 1036, 1110, 989, 1015, 678, 655, 1037)
)

select * from t1;



















