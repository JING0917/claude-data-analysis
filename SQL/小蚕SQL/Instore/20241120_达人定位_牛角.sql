今日数据需求1：（且）
1）小红书粉丝大于等于500
2）定位在这3个地点附近2km内
余杭区时代天元城(海鸥路西) 120.010153,30.290294
滨江区浦沿元天科技大楼(惠商街) 120.168555,30.191312
萧山区海上明月生活广场(建设一路南)1楼14-124号 120.258948,30.200134
3）工作日下单双人餐的订单占50%以上
4）到手价金额10元以内的订单占50%以上
的用户
表头：
微信昵称、定位、小蚕id


今日数据需求2:
1）大众点评大于等于6级
2）定位在这个地点附近2km内
西湖区转塘星光荟(美院北街北) 120.083028,30.164927
3）工作日下单双人餐的订单占50%以上 
4）到手价金额10元以内的订单占50%以上
的用户
表头：
微信昵称、定位、小蚕id


今日数据需求3:
要求小红书大于等于200粉，或大众点评大于等于lv5的用户：
微信昵称、小蚕id、小红书粉丝数、大众点评等级、定位、认证时间、近30天支付单量、近30天核销单量



-- 用户定位下推送
with t1 as (
select
    user_id --,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=500
    )
    -- or (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    -- and dp_user_lvl>=6
    -- )
),

-- 最近7天访问用户
t2 as (
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
(select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
union all
select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
union all
select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
) b
    on 1=1
)


-- -- 下单
-- t3 as (
-- select
--     user_id,count(order_id) finished_num
-- from dwd.dwd_sr_silkworm_explore_order
-- where dt between '2024-06-18' and date_sub(current_date,1)
--     and store_name not regexp '测试'
--     and user_id<>329118405 -- 剔除测试账号
--     and promotion_type in (1,4) -- 探店
--     and status in (5,19,20)
-- group by user_id
-- )


select   
    store_name,
    count(distinct silk_id) as unum
from t2 inner join t1 on t.silk_id=t2.user_id
where distance<=2000 -- 5公里内
group by 1
;




-- 千粉用户绑定粉丝企微
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
;

====================== 正式跑数
with t1 as (
select
    user_id --,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    -- (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    -- and xiaohongshu_fans_num>=500
    -- )
    -- or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=6
    )
),

-- 最近7天访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    address_detail
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat,address_detail
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
        -- 计算距离经纬度
--         (select longitude as star_lon,
--             latitude as star_lat 
-- from dim.dim_silkworm_explore_store
--         ) b
(
-- select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
-- union all
-- select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
-- union all
-- select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
select '西湖区转塘星光荟(美院北街北)' as store_name,'120.083028' as star_lon,'30.164927' as star_lat
) b
    on 1=1
),


-- -- 下单
-- t3 as (
-- select
--     user_id,count(order_id) finished_num
-- from dwd.dwd_sr_silkworm_explore_order
-- where dt between '2024-06-18' and date_sub(current_date,1)
--     and store_name not regexp '测试'
--     and user_id<>329118405 -- 剔除测试账号
--     and promotion_type in (1,4) -- 探店
--     and status in (5,19,20)
-- group by user_id
-- )

-- 下单
order_info as (
select
    -- a.dt,
    a.user_id,
    sum(order_id) as tot_order_num,
    sum(if(b.day_of_week not in ('星期六','星期天'),order_num,0)) as workday_order_num
from (
select
    dt,
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between '2024-06-16' and date_sub(current_date,1)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
    and pay_amt>50
    and store_promotion_name regexp '单人餐'
group by 1,2
) a
inner join dim.dim_silkworm_date b on a.dt=b.current_date_txt
group by 1







t3 as (
select   
    store_name as `店铺地址`,
    -- count(distinct silk_id) as unum
    silk_id `用户ID`,
    address_detail `用户定位地址`
from t2 inner join t1 on t2.silk_id=t1.user_id
where distance<=3000 -- 5公里内
group by 1,2,3
),

-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
)

select
    t3.`店铺地址`,
    t3.`用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    t3.`用户定位地址`
from t3 left join t4 on t3.`用户ID`=t4.`用户ID`


===============
1）大众点评大于等于5级 或 小红书粉丝大于等于200
2）定位位于店铺位置2km内（余杭区美瑭广场：东经120°0′11.444″,北纬30°16′59.077″） 
3）工作日下单金额50以上单人餐占比50%以上


1）大众点评大于等于5级或小红书粉丝大于等于500
2）定位位于店铺位置2km内（滨江区滨康二苑26幢-经纬度：120.209187,30.177813）
3）下单金额100以内的订单占50%以上

with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 最近7天访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    address_detail
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat,address_detail
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
        -- 计算距离经纬度
--         (select longitude as star_lon,
--             latitude as star_lat 
-- from dim.dim_silkworm_explore_store
--         ) b
(
-- select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
-- union all
-- select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
-- union all
-- select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
-- select '余杭区美瑭广场' as store_name,'120.011444' as star_lon,'30.1659077' as star_lat
select '滨江区滨康二苑26幢' as store_name,'120.209187' as star_lon,'30.177813' as star_lat
) b
    on 1=1
),


-- 下单
order_info as (
select
    -- a.dt,
    a.user_id,
    sum(order_num) as tot_order_num,
    sum(if(b.day_of_week not in ('星期六','星期天'),order_num,0)) as workday_order_num,
    sum(if(b.day_of_week not in ('星期六','星期天'),order_num,0))/sum(order_num) as workday_order_rate
from (
select
    dt,
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between '2024-06-16' and date_sub(current_date,1)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
    and pay_amt>50
    and store_promotion_name regexp '单人餐'
group by 1,2
) a
inner join dim.dim_silkworm_date b on a.dt=b.current_date_txt
group by 1
),




t3 as (
select   
    store_name as `店铺地址`,
    -- count(distinct silk_id) as unum
    silk_id `用户ID`,
    address_detail `用户定位地址`
from t2 inner join t1 on t2.silk_id=t1.user_id
where distance<=2000 -- 5公里内
group by 1,2,3
),

-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
)

select
    t3.`店铺地址`,
    t3.`用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    t3.`用户定位地址`
from t3 left join t4 on t3.`用户ID`=t4.`用户ID`
inner join order_info on t3.`用户ID`=order_info.user_id and workday_order_rate>0.5
;



==========================
上周（11.18-11.24）以及上上周（11.11-11.17），大众点评lv5及以上和小红书大于等于200粉丝的达人核销量



with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 订单
t2 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between '2024-06-16' and date_sub(current_date,1)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
    and substr(verify_time,1,10) between '2024-11-18' and '2024-11-24'
group by 1
having count(order_id)>0
)


select
    count(t1.user_id) as cnt
from t1 inner join t2 on t1.user_id=t2.user_id
;



====================
1）大众点评大于等于5级
2）定位位于店铺位置5km内（萧山区众安·嘉润公馆南区：120.235429,30.237290） 
3）15天内没有核销过这家店的用户（店铺id：1263）


with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    -- (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    -- and xiaohongshu_fans_num>=200
    -- )
    -- or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 最近7天访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    address_detail
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat,address_detail
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
        -- 计算距离经纬度
--         (select longitude as star_lon,
--             latitude as star_lat 
-- from dim.dim_silkworm_explore_store
--         ) b
(
-- select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
-- union all
-- select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
-- union all
-- select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
-- select '余杭区美瑭广场' as store_name,'120.011444' as star_lon,'30.1659077' as star_lat
select '萧山区众安·嘉润公馆南区' as store_name,'120.235429' as star_lon,'30.237290' as star_lat
) b
    on 1=1
),


-- 下单
order_info as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(verify_time,'%Y-%m-d%') between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
    and store_id=1264
group by 1
),


t3 as (
select   
    store_name as `店铺地址`,
    -- count(distinct silk_id) as unum
    silk_id `用户ID`,
    address_detail `用户定位地址`
from t2 inner join t1 on t2.silk_id=t1.user_id
where distance<5000 -- 5公里内
group by 1,2,3
),


-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),


t5 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(pay_time,'%Y-%m-d%')<=date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
having count(order_id)>1
)


select
    t3.`店铺地址`,
    t3.`用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    t3.`用户定位地址`,
    if(t5.user_id is null,'新用户','老用户') `新老用户`
from t3 left join t4 on t3.`用户ID`=t4.`用户ID`
left join order_info on t3.`用户ID`=order_info.user_id
left join t5 on t3.`用户ID`=t5.user_id
where order_info.user_id is null
;



with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    -- (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    -- and xiaohongshu_fans_num>=200
    -- )
    -- or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 最近7天访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    address_detail
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat,address_detail
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
        -- 计算距离经纬度
--         (select longitude as star_lon,
--             latitude as star_lat 
-- from dim.dim_silkworm_explore_store
--         ) b
(
-- select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
-- union all
-- select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
-- union all
-- select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
-- select '余杭区美瑭广场' as store_name,'120.011444' as star_lon,'30.1659077' as star_lat
select '新' as store_name,'120.004745' as star_lon,'30.281421' as star_lat
) b
    on 1=1
)

select   
    -- store_name as `店铺地址`,
    -- -- count(distinct silk_id) as unum
    -- silk_id `用户ID`,
    -- address_detail `用户定位地址`
    count(t1.user_id) as cnt
from t2 inner join t1 on t2.silk_id=t1.user_id
where distance<3000 -- 5公里内
-- group by 1,2,3
;


===================
需求1:
1）大众点评大于等于5级
2）定位位于店铺位置5km内（西湖区剑桥公社D座：120.094801,30.305652） 
3）15天内没有核销过这家店的用户（店铺id：954）

需求2:
1）大众点评大于等于5级
2）定位位于店铺位置5km内（滨江区龙湖杭州滨江天街：120.203866,30.200786）

需求3:
1）大众点评大于等于5级
2）定位位于店铺位置5km内（萧山区众安·嘉润公馆南区：120.235429,30.237290） 
3）5天内没有核销过这家店的用户（店铺id：1264）

需求4:
1）大众点评大于等于5级
2）定位位于店铺位置5km内（余杭区欧美金融城东区住宅1期：120.004745,30.281421） 
3）30天内没有核销过这家店的用户（店铺id：1646）




with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    -- (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    -- and xiaohongshu_fans_num>=200
    -- )
    -- or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 最近7天访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    address_detail
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat,address_detail
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
-- 计算距离经纬度
    (
    -- select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat
    -- union all
    -- select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat
    -- union all
    -- select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat
    -- select '余杭区美瑭广场' as store_name,'120.011444' as star_lon,'30.1659077' as star_lat
    select '余杭区欧美金融城东区住宅1期' as store_name,'120.004745' as star_lon,'30.281421' as star_lat
    ) b
        on 1=1
),


-- 订单核销
order_info as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(verify_time,'%Y-%m-d%') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day) -- 根据需求自定义修改，现在限制是30天内核销
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
    and store_id=1646 -- 指定店铺ID核销，根据需要自行修改
group by 1
having count(order_id)>=1
),


-- 绑定企微用户和店铺距离
t3 as (
select   
    store_name `店铺地址`,
    silk_id `用户ID`,
    address_detail `用户定位地址`
from t2 inner join t1 on t2.silk_id=t1.user_id
where distance<5000 -- 5公里内
group by 1,2,3
),


-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),


-- 有支付订单量
t5 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(pay_time,'%Y-%m-%d')<=date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
having count(order_id)>1
)


select
    t3.`店铺地址`,
    t3.`用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    t3.`用户定位地址`,
    if(t5.user_id is null,'新用户','老用户') `新老用户`
from t3 left join t4 on t3.`用户ID`=t4.`用户ID`
left join order_info on t3.`用户ID`=order_info.user_id
left join t5 on t3.`用户ID`=t5.user_id
where order_info.user_id is null
;

==
1）大众点评大于等于5级
2）定位位于店铺位置5km内（滨江区龙湖杭州滨江天街：120.203866,30.200786）

-- 达人筛选
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    -- (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    -- and xiaohongshu_fans_num>=200
    -- )
    -- or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 最近访问用户
t2 as (
select
    silk_id,
    store_name,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    address_detail
from
    (select
        silk_id,longitude as end_lon,latitude as end_lat,address_detail
    from test.test_client_user_location
    where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    ) a
left join
-- 计算距离经纬度
    (
    select '余杭区时代天元城(海鸥路西)' as store_name,'120.010153' as star_lon,'30.290294' as star_lat union all 
    union all
    select '滨江区浦沿元天科技大楼(惠商街)' as store_name,'120.168555' as star_lon,'30.191312' as star_lat union all 
    union all
    select '萧山区海上明月生活广场(建设一路南)1楼14-124号' as store_name,'120.258948' as star_lon,'30.200134' as star_lat union all 
    select '余杭区美瑭广场' as store_name,'120.011444' as star_lon,'30.1659077' as star_lat union all 
    select '滨江区龙湖杭州滨江天街' as store_name,'120.203866' as star_lon,'30.200786' as star_lat
    ) b
        on 1=1
),



-- 绑定企微用户和店铺距离
t3 as (
select   
    store_name `店铺地址`,
    silk_id `用户ID`,
    address_detail `用户定位地址`
from t2 inner join t1 on t2.silk_id=t1.user_id
where distance<5000 -- 5公里内 -- 根据需要自行调整
group by 1,2,3
),


-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),


-- 有支付订单量
t5 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(pay_time,'%Y-%m-%d')<=date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
having count(order_id)>1
)


select
    t3.`店铺地址`,
    t3.`用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    t3.`用户定位地址`,
    if(t5.user_id is null,'新用户','老用户') `新老用户`
from t3 left join t4 on t3.`用户ID`=t4.`用户ID`
left join t5 on t3.`用户ID`=t5.user_id
;


-- 指定周期内认证达人
select
    count(user_id) as auth_user_num -- 认证用户量
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10) between '2024-11-01' and '2024-11-27' -- 根据需要自行调整
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10) between '2024-11-01' and '2024-11-27' -- 根据需要自行调整
    and dp_user_lvl>=5 -- 根据需要调整
    )


========
1）小红书大于等于800粉
2）11月支付10单以上
3）老用户


-- 达人筛选
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    -- or 
    -- (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    -- and dp_user_lvl>=5
    -- )
),




-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),


-- 有支付订单量
t5 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(pay_time,'%Y-%m-%d')<=date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
having count(order_id)>=1
),

-- 支付订单量>=10
t6 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and substr(pay_time,1,10) between '2024-11-01' and '2024-11-29'
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
having count(order_id)>=10
)


select
    t1.user_id `用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    if(t5.user_id is null,'新用户','老用户') `新老用户`
from t1 inner join t6 on t1.user_id=t6.user_id
left join t5 on t1.user_id=t5.user_id
left join t4 on t1.user_id=t4.`用户ID`
;





-- 达人
select
    '小红书' `认证平台`,
    '200-499' `粉丝/等级`,
    count(if(xiaohongshu_fans_num between 200 and 499,user_id,null)) `总达人数`,
    count(if(str_to_date(xiaohongshu_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and xiaohongshu_fans_num between 200 and 499,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'

union all
-- 达人
select
    '小红书' `认证平台`,
    '500-999' `粉丝/等级`,
    count(if(xiaohongshu_fans_num between 500 and 999,user_id,null)) `总达人数`,
    count(if(str_to_date(xiaohongshu_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and xiaohongshu_fans_num between 500 and 999,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'

union all
-- 达人
select
    '小红书' `认证平台`,
    '1000以上' `粉丝/等级`,
    count(if(xiaohongshu_fans_num>=1000,user_id,null)) `总达人数`,
    count(if(str_to_date(xiaohongshu_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and xiaohongshu_fans_num>=1000,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'

union all
-- 达人
select
    '小红书' `认证平台`,
    '总计' `粉丝/等级`,
    count(if(xiaohongshu_fans_num>=200,user_id,null)) `总达人数`,
    count(if(str_to_date(xiaohongshu_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and xiaohongshu_fans_num>=200,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'

union all
select
    '大众点评' `认证平台`,
    'V5及以上' `粉丝/等级`,
    count(if(dp_user_lvl>=5,user_id,null)) `总达人数`,
    count(if(str_to_date(dp_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and dp_user_lvl>=5,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(dp_auth_first_time,1,10)<>'1970-01-01'

union all
select
    '大众点评' `认证平台`,
    '百粉' `粉丝/等级`,
    count(if(dp_fans_num between 100 and 999,user_id,null)) `总达人数`,
    count(if(str_to_date(dp_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and dp_fans_num between 100 and 999,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(dp_auth_first_time,1,10)<>'1970-01-01'

union all
select
    '大众点评' `认证平台`,
    '千粉' `粉丝/等级`,
    count(if(dp_fans_num>=1000,user_id,null)) `总达人数`,
    count(if(str_to_date(dp_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and dp_fans_num>=1000,user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(dp_auth_first_time,1,10)<>'1970-01-01'

union all
select
    '大众点评' `认证平台`,
    '总计' `粉丝/等级`,
    count(if(dp_fans_num>=100 or dp_user_lvl>=5,user_id,null)) `总达人数`,
    count(if(str_to_date(dp_auth_first_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 day) 
                and (dp_fans_num>=100 or dp_user_lvl>=5),user_id,null)) `昨日新增达人数`
from dim.dim_silkworm_explore_daren_cleanse
where substr(dp_auth_first_time,1,10)<>'1970-01-01'




=============
需求1、是外卖老用户（下过1单及以上）且是探店新用户（认证后未下过首单）的达人用户（200粉/5级）：用户id+微信昵称+大众点评等级+小红书粉丝+定位+添加企微号
目的：新探店用户进行拉群，补贴小蚕外卖红包，看一下激活效果
需求2、小红书1000粉及以上新用户：用户id+微信昵称+小红书粉丝+定位+添加企微号
目的：给千粉达人推送漂亮饭，看一下激活效果
需求3、小红书大于等于200粉用户：小蚕id+微信昵称+粉丝数+11月探店下单（支付）次数+11月探店核销单量
目的：分析目前活跃达人用户数，活跃用户率，测算达人用户缺口量


-- 用户群名称：大众4级以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where 
    substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=4
;


-- 用户群名称：大众5级以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where 
    substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
;


-- 用户群名称：大众6级以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where 
    substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=6
;

-- 用户群名称：大众7级以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where 
    substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=7
;

-- 用户群名称：大众8级以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where 
    substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=8
;


-- 用户群名称：小红书200粉以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
;


-- 用户群名称：小红书500粉以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=500
;


-- 用户群名称：小红书1000粉以上
-- 口径
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=1000
;


=============
需求1、是外卖老用户（下过1单及以上）且是探店新用户（认证后未下过首单）的达人用户（200粉/5级）：用户id+微信昵称+大众点评等级+小红书粉丝+定位+添加企微号
目的：新探店用户进行拉群，补贴小蚕外卖红包，看一下激活效果

需求2、小红书1000粉及以上新用户：用户id+微信昵称+小红书粉丝+定位+添加企微号
目的：给千粉达人推送漂亮饭，看一下激活效果

需求3、小红书大于等于200粉用户：小蚕id+微信昵称+粉丝数+11月探店下单（支付）次数+11月探店核销单量
目的：分析目前活跃达人用户数，活跃用户率，测算达人用户缺口量


=========== 需求1
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (
        (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    or 
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
        ) 
    and first_order_date is null -- 未下单

),



-- 用户微信
t2 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),



-- 绑定企微
t3 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),

-- 下过霸王餐用户
t4 as (
select
    user_id
from dim.dim_silkworm_user
where accu_valid_order_num>=1
),


-- 最近访问用户
t5 as (
select
    silk_id,
    province,
    city,
    district,
    address_detail
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
)


select
    t1.user_id `用户ID`,
    t1.xiaohongshu_fans_num `小红书粉丝数`,
    t1.dp_user_lvl `大众点评等级`,
    t2.`微信ID`,
    t2.`微信昵称`,
    t3.bind_interior_staff_wework_id `绑定企微ID`,
    t5.province,
    t5.city,
    t5.district,
    t5.address_detail
from t1 left join t2 on t1.user_id=t2.`用户ID`
left join t3 on t3.user_id=t1.user_id
inner join t4 on t4.user_id=t1.user_id
left join t5 on t1.user_id=t5.silk_id
;

=================== 需求2

with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
        (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=1000)
    and first_order_date is null -- 未下单

),



-- 用户微信
t2 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),



-- 绑定企微
t3 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    -- and bind_interior_staff_wework_id=858
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),

-- 下过霸王餐用户
t4 as (
select
    user_id
from dim.dim_silkworm_user
where accu_valid_order_num>=1
),


-- 最近访问用户
t5 as (
select
    silk_id,
    province,
    city,
    district,
    address_detail
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
)


select
    t1.user_id `用户ID`,
    t1.xiaohongshu_fans_num `小红书粉丝数`,
    t1.dp_user_lvl `大众点评等级`,
    t2.`微信ID`,
    t2.`微信昵称`,
    t3.bind_interior_staff_wework_id `绑定企微ID`,
    t5.province `用户定位省份`,
    t5.city `用户定位城市`,
    t5.district `用户定位区县`,
    t5.address_detail `用户定位地址`
from t1 left join t2 on t1.user_id=t2.`用户ID`
left join t3 on t3.user_id=t1.user_id
inner join t4 on t4.user_id=t1.user_id
left join t5 on t1.user_id=t5.silk_id
;



=================== 需求3
-- 达人筛选
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    -- or 
    -- (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    -- and dp_user_lvl>=5
    -- )
),




-- 用户微信
t4 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),


-- 11月支付订单量
t5 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and substr(pay_time,1,10) between '2024-11-01' and '2024-11-30'
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
),

-- 11月核销订单量
t5 as (
select
    user_id,
    count(order_id) as verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and substr(verify_time,1,10) between '2024-11-01' and '2024-11-30'
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
)


select
    t1.user_id `用户ID`,
    t4.`微信ID`,
    t4.`微信昵称`,
    t1.xiaohongshu_fans_num `小红书粉丝数`,
    t5.order_num `支付订单量`,
    t6.verify_order_num `核销订单量`
from t1 
left join t5 on t1.user_id=t5.user_id
left join t4 on t1.user_id=t4.`用户ID`
left join t6 on t1.user_id=t6.user_id
;



====================
大禾，今天能不能给我导一个名单：小红书千粉及以上 & 大众v6及以上
sheet1小红书：微信昵称+小蚕id+粉丝数+所绑定企微+是否新用户
sheet2大众点评：微信昵称+小蚕id+等级+所绑定企微+是否新用户


-- 达人筛选
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=1000
    )
    -- or
    -- (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    -- and dp_user_lvl>=6
    -- )
),


-- 用户微信
t2 as (
select 
    b.user_id `用户ID`,
    b.user_wechat_id `微信ID`,
    c.wechat_nickname as `微信昵称`
from dim.dim_silkworm_user b
left join dim.dim_silkworm_user_wechat c
on b.user_wechat_id=c.user_wechat_id
),


-- 有支付订单量
t3 as (
select
    user_id,
    count(order_id) as order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<= date_sub(current_date(),interval 1 day)
    and str_to_date(pay_time,'%Y-%m-%d')<=date_sub(current_date(),interval 1 day)
    and store_name not regexp '测试'
    and user_id<>329118405 -- 剔除测试账号
    and promotion_type in (1,4) -- 探店
group by 1
having count(order_id)>=1
),



-- 绑定企微
t4 as (
select
    user_id,bind_interior_staff_wework_id
from dwd.dwd_sr_silkworm_explore_bind_wework_record
where cast(dt as string)>='2024-06-18'
    and status=1 -- 1:正常,2:已放弃
group by 1,2
),

-- 用户位置 近90天位置信息
t5 as (
select
    silk_id,
    province,
    city,
    district,
    address_detail
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
)


select
    t1.user_id `用户ID`,
    t2.`微信ID`,
    t2.`微信昵称`,
    t4.bind_interior_staff_wework_id `绑定企微ID`,
    t1.xiaohongshu_fans_num `小红书粉丝数`,
    if(t3.user_id is null,'新用户','老用户') `新老用户`,
    t5.province `用户定位省份`,
    t5.city `用户定位城市`,
    t5.district `用户定位区县`,
    t5.address_detail `用户定位地址`
from t1 left join t2 on t1.user_id=t2.`用户ID`
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
left join t5 on t1.user_id=t5.silk_id
;



============== 达人标签
-- 达人筛选
with t1 as (
select
    user_id,xiaohongshu_fans_num,dp_user_lvl
from dim.dim_silkworm_explore_daren_cleanse
where 
    (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=1000
    )
    or
    (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=6
    )
),


-- 核销订单量
t2 as (
select
    user_id,count(1) as verify_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(verify_time,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
group by 1
having count(1)>=1
),


-- 用户位置 近90天位置信息
t3 as (
select
    silk_id as user_id,
    province as province_name
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and province in ('浙江省','上海市','四川省','广东省','湖北省')
group by 1,2
)


select
    t1.user_id as `用户ID`,
    if(t1.xiaohongshu_fans_num>=1000 and t3.province_name='浙江省',1,0) `杭州千粉老用户`,
    if(t1.xiaohongshu_fans_num>=1000 and t3.province_name='上海市',1,0) `上海千粉老用户`,
    if(t1.xiaohongshu_fans_num>=1000 and t3.province_name='四川省',1,0) `成都千粉老用户`,
    if(t1.xiaohongshu_fans_num>=1000 and t3.province_name='广东省',1,0) `广州千粉老用户`,
    if(t1.xiaohongshu_fans_num>=1000 and t3.province_name='湖北省',1,0) `武汉千粉老用户`,

    if(t1.dp_user_lvl>=6 and t3.province_name='浙江省',1,0) `杭州V6+老用户`,
    if(t1.dp_user_lvl>=6 and t3.province_name='上海市',1,0) `上海V6+老用户`,
    if(t1.dp_user_lvl>=6 and t3.province_name='四川省',1,0) `成都V6+老用户`,
    if(t1.dp_user_lvl>=6 and t3.province_name='广东省',1,0) `广州V6+老用户`,
    if(t1.dp_user_lvl>=6 and t3.province_name='湖北省',1,0) `武汉V6+老用户`
from t1 inner join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
;




============= 认证记录表中有但用户表无认证时间的用户
select
    a.*
from
    -- 认证记录用户
    (select
        *
    from dwd.dwd_sr_silkworm_explore_auth_record
    where dt>='2024-06-01'
    ) a
left join
        (select
            user_id
        from dim.dim_silkworm_explore_daren_cleanse
        where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
            or substr(dp_auth_first_time,1,10)<>'1970-01-01'
        ) b
    on a.user_id=b.user_id
where b.user_id is null;

-- 正式取数
select
    a.*
from
    -- 认证记录用户
    (select
        *
    from dwd.dwd_sr_silkworm_explore_auth_record
    where dt>='2024-06-01'
        and status=3
    ) a
left join
        (select
            user_id
        from dim.dim_silkworm_explore_daren_cleanse
        where substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
            or substr(dp_auth_first_time,1,10)<>'1970-01-01'
        ) b
    on a.user_id=b.user_id
where b.user_id is null;





