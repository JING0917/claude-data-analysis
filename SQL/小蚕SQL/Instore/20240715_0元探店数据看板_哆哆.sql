-- dim.dim_silkworm_explore_merchant
-- dim.dim_silkworm_explore_store
-- dim.dim_silkworm_explore_daren



-- 'TakeoutOrder_Process_Ex', 'TakeoutOrder_Enter_Store_Click', 'TakeoutOrder_Number_Click', 'TakeoutOrder_Authorization_Check_Click', 'TakeoutOrder_Submit_Proof_Click', 'TakeoutOrder_Cancel_Click',


-- 以用户ID：923592157查看和验证数据
-- select * from dim.dim_silkworm_explore_daren 
-- where user_id=923592157
-- -- limit 10

*****************
-- dms看数据
-- -- 查看用户首次下单日期，和order表中，当status=5时，finish_time日期一致
-- SELECT silk_id,
--     FROM_UNIXTIME(`red_first_order`, '%Y-%m-%d') as red_first_order_date,
--     FROM_UNIXTIME(`dp_first_order`, '%Y-%m-%d') as dp_first_order_date
-- FROM `user` 
-- where `silk_id`  in (329118405,435364558,149179106)



-- -- 订单

-- SELECT 
-- `created_at`,
-- `silk_id`,
-- order_id,
-- FROM_UNIXTIME(`pay_time`, '%Y-%m-%d') as pay_date,
-- FROM_UNIXTIME(`finish_time`, '%Y-%m-%d') as finish_date,
-- FROM_UNIXTIME(`create_time`, '%Y-%m-%d') as create_date,
-- status
-- FROM `order` 
-- where `silk_id`  in (329118405,435364558,149179106)
-- and `status` =5
-- order by FROM_UNIXTIME(`create_time`, '%Y-%m-%d')
*****************




-- 存在问题
1）活动可以区分城市，但是是店铺城市，是否存在跨区销单的？(已确认，访问城市和区县，要和店铺城市和区县一致)


-- -- 城市维表
-- with dim_city as (
-- select
--     city_id,city_name,county_id,county_name
-- from dim.dim_hive_region_code
-- ),

====================== 第一部分 到店日数据
--Spark SQL
--******************************************************************--
--author: dahe
--create time: 2024-07-22 13:42:05
--******************************************************************--

统计口径：
1）新用户：统计周期内，首次访问探店页面(主页、达人主页、活动详情页)和公益页面(主页、发心页、公益我的页、活动详情页)的去重用户；
2）活跃用户：统计周期内，访问探店页面和公益页面的去重用户，页面如1中所述；
3）新增有效用户：统计周期内，首次提交名片认证的新用户；
4）解锁达人：统计周期内，解锁达人的新用户；
5）新增首单用户：统计周期内，产生首次有效订单的去重用户；
6）在线店铺：统计周期内，状态是“未删除”的店铺；
7）在线活动：统计周期内，状态是“上线”的活动；
8）下单量：统计周期内，产生的所有订单，不区分订单状态；
9）销单量：订单完成日期和统计周期一致的订单；
10）核销量：统计周期内，下单且核销的订单；
11）完单量：统计周期内，下单且状态是“已完成”的订单；
12）待上传订单：统计周期内：下单且状态是“已报名(待支付)”、“已报名(待认证)”、“已核销(待提交笔记)”、“笔记审核中(人工)”、“已驳回(待重新提交笔记)”、“补单-待提交笔记(商家承担返利)”、“补单-待提交返利(小蚕承担返利)”订单。

完成达人认证步骤：登录用户进入到店页面，先绑定到店企微，再观看视频和考试，通过考试后，提交小红书/大众点评账号截图以供审核，审核通过后，成为达人。


dim.dim_silkworm_explore_daren
dim.dim_silkworm_explore_merchant
dim.dim_silkworm_explore_store
dwd.dwd_sr_silkworm_explore_auth_record
dwd.dwd_sr_silkworm_explore_bind_wework_record
dwd.dwd_sr_silkworm_explore_notes_upload_history
dwd.dwd_sr_silkworm_explore_order
dwd.dwd_sr_silkworm_explore_promotion
dwd.dwd_hive_silkworm_explore_reward_record





--Spark SQL
--******************************************************************--
--author: dahe
--create time: 2024-07-30 18:07:42
--******************************************************************--
-- drop table dws.dws_hive_order_explore_dashboard_county_d;

CREATE TABLE IF NOT EXISTS  dws.dws_hive_order_explore_dashboard_county_d(
`statisticsdate` string comment  '统计日期',
`platform_name` string comment  '平台名称',
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
`auth_xiaohongshu_newuser_num` int comment '新增认证小红书用户量',
`auth_dp_newuser_num` int comment '新增认证大众点评用户量',
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
`welfare_onlin_promotion_quota` int comment '公益活动名额',
-- `used_quota` int comment '名额消耗量', -- 20240807新增 修改人：dahe
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
)
comment '到店业务日区县数据看板'
partitioned by(dt string)
STORED AS ORC;


-- 城市维表
with dim_city as (
    select  city_id,
            city_name,
            county_id,
            county_name
    from  dim.dim_hive_region_code
), 

-- 用户维表
dim_user as (
    select  a.user_id,
            substr(a.register_time, 1, 10) as register_date,
            case when a.latest_login_platform = 'h5' then 'H5' when a.latest_login_platform = 'android' then 'Android' when a.latest_login_platform = 'ios' then 'iOS' when a.latest_login_platform = 'mini' then '小程序' else '其他' end as platform_name,
            nvl(case when a.county_id = 0 then '其他' when a.county_id is null then '其他' else dim_city.city_name end, '其他') as city_name,
            nvl(
                case when a.county_id = 0 then '其他' when a.county_id is null then '其他' else dim_city.county_name end,
                '其他'
            ) as county_name
    from    dim.dim_silkworm_user a
    left join dim_city
    on      a.county_id = dim_city.county_id
    where   is_logoff = 0 -- 未注销 20240823新增 修改人：dahe
), 

-- 探店业务用户
t1 as (
select  to_date(a.create_time) as create_date,
            b.bind_wework_date, -- 绑定企微日期
            a.user_id,
            if(daren_score >= 40, 1, 0) is_daren, -- 1:达人
            -- is_bind_wework, -- 是否绑定企微，1：是
            if(b.user_id is not null,1,0) as is_bind_wework, -- 是否绑定企微，1：是 20240823调整逻辑 修改人：dahe
            is_finish_exam, -- 是否完成考核 1：是
            is_open_renshen, -- 是否开启人审 1：是
            auth_xiaohongshu_id,
            auth_dp_id,
            substring(daren_activate_time, 1, 10) as daren_activate_date, -- 达人激活日期
            substring(xiaohongshu_auth_first_time, 1, 10) as xiaohongshu_auth_first_date, -- 小红书首次认证日期
            substring(dp_auth_first_time, 1, 10) as dp_auth_first_date, -- 大众点评首次认证日期
            substring(xiaohongshu_first_order_time, 1, 10) as xiaohongshu_first_order_date, -- 小红书首次下单日期
            substring(dp_first_order_time, 1, 10) as dp_first_order_date, -- 大众点评首次下单日期
            substring(dp_auth_time, 1, 10) as dp_auth_date, -- 大众点评认证日期
            substring(xiaohongshu_auth_time, 1, 10) as xiaohongshu_auth_date, -- 小红书认证日期
            -- 访问用户
            first_view_date, -- 首次访问日期
            first_explode_view_date as first_explore_view_date, -- 探店首次访问日期
            first_welfare_view_date, -- 公益首次访问日期
            -- 新增首单用户
            first_order_date, -- 新增首单日期
            first_explode_order_date as first_explore_order_date, -- 探店新增首单日期
            first_welfare_order_date -- 公益新增首单日期
    from    dim.dim_hive_silkworm_explore_daren a
left join 
-- 20240823 调整绑定企微逻辑
-- 绑定企微
        (select
            user_id,min(bind_wework_date) as bind_wework_date -- 取用户首次绑定企微日期，因存在多次绑定，绑定后机器人发考核题，考核题发送失败，用户会多次添加企微
        from (select
                    to_date(create_time) as bind_wework_date, -- 绑定企微日期
                    user_id
                from dwd.dwd_hive_silkworm_explore_bind_wework_record
                where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-18' and '${T-1}'
                    and status=0 -- 正常
                    and bind_interior_staff_wework_id>0
                group by 1,2
        ) b1
        group by 1
        ) b 
on a.user_id=b.user_id
where a.status = 1 -- 1:正常,2:删除 -- 20240823新增 修改人：dahe
), 

-- 留存用户量
view_newuser as (
    select  statistics_date,
            nvl(platform_name, '全部') as platform_name,
            nvl(city_name, '全部') as city_name,
            nvl(county_name, '全部') as county_name,
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
                            from    dws.dws_hive_traffic_user_d
                            where   to_date(statistics_date) between '${T-1}'
                            and     '${T-1}'
                            and     (
                                        user_id regexp '^[1-7]{1,7}$'
                                        or      user_id regexp '^[1-8]{1,8}$'
                                        or      user_id regexp '^[1-9]{1,9}$'
                                    ) -- 20240823调整，限制登录用户，减少数据量 修改人：dahe
                            group by 1
                            having  (
                                        sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
                                        or      sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) > 0
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
                from    dws.dws_hive_traffic_user_d
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
    select  to_date(create_time) as order_date,
            order_id,
            user_id,
            store_id,
            store_promotion_id,
            promotion_type,
            substring(pay_time, 1, 10) as pay_date, -- 支付日期
            substring(finish_time, 1, 10) as finish_date, -- 完成日期
            substring(cancel_time, 1, 10) as cancel_date, -- 取消日期
            substring(refund_time, 1, 10) as refund_date, -- 售后退款日期
            substring(verify_time, 1, 10) as verify_date, -- 核销日期
            status,
            notes_reject_cnt
    from    dwd.dwd_hive_silkworm_explore_order
    where   dt between '2024-06-18'
    and     '${T-1}'
    and     store_name not regexp '测试'
), 

-- 探店在线活动
t4 as (
    select  to_date(dt) as dt,
            promotion_type,
            '其他' as platform_name,
            nvl(if(dim_city.city_name is null, '其他', dim_city.city_name), '其他') as city_name,
            nvl(if(dim_city.city_name is null, '其他', dim_city.county_name), '其他') as county_name,
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
                from    dwd.dwd_hive_silkworm_explore_promotion
                where   dt between '2024-06-16'
                and     '${T-1}'
                and     substring(begin_time, 1, 10) = '${T-1}' 
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
    select  to_date(create_time) as statistics_date,
            business_type, -- 1：探店；2：公益
            '其他' as platform_name,
            nvl(if(dim_city.city_name is null, '其他', dim_city.city_name), '其他') as city_name,
            nvl(if(dim_city.city_name is null, '其他', dim_city.county_name), '其他') as county_name,
            count(distinct store_id) as online_store_num -- 在线店铺数
    from    dim.dim_silkworm_explore_store a
    left join dim_city
    on      a.city_id = dim_city.county_id
    where   to_date(a.create_time) = '${T-1}' 
    -- and a.status = 1 -- 正常 首次跑数据不限制，以免漏掉已下线数据 20240823调整 修改人：dahe
    group by 1,
            2,
            3,
            4,
            5
), 

-- 人审订单
t6 as (
    select  concat(a.year, '-', LPAD(a.month, 2, '0'), '-', LPAD(a.day, 2, '0')) as statistics_date, -- demand_promotion_type, -- 1:dp,2:xiaohongshu
            t3.promotion_type,
            '其他' as platform_name,
            '其他' as city_name,
            '其他' as county_name,
            count(a.auto_id) as renshen_order_cnt, -- 人审次数
            count(distinct a.order_id) as renshen_order_num -- 人审订单量
    from    dwd.dwd_hive_silkworm_explore_notes_upload_record a
    left join t3
    on      a.order_id = t3.order_id
    where   concat(a.year, '-', LPAD(a.month, 2, '0'), '-', LPAD(a.day, 2, '0')) = '${T-1}'
    and     a.auditor_id <> 0 -- 非0：人审
    group by 1,
            2,
            3,
            4,
            5
), 

-- 人审认证
t7 as (
    select  concat(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) as statistics_date, -- account_type, -- 1:dp,2:xiaohongshu
            '其他' as platform_name,
            '其他' as city_name,
            '其他' as county_name,
            count(*) as renshen_auth_cnt -- 人审认证记录数
    from    dwd.dwd_hive_silkworm_explore_auth_record
    where   concat(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) = '${T-1}'
    and     operator_id <> 0 -- 非0：人审
    group by 1,
            2,
            3,
            4
) 




======================


promotion_type=1 是探店，相反是公益，按照=1来区分就行

活动名额数、名额消耗量、在线店铺数、在线活动数，区分不了城市、平台名称


1）留存分母不准确
2）探店和公益新用户
3）新绑企微转化率
4）新增有效用户（根据来源认证页面访问的前向页面区分）
5）新增解锁达人、认证名片，不限制是否访问
6）完单量、下单用户量，需要限制下单日期是统计日期，不限制是否访问
7）消耗探店名额数不准
8）累计访问用户量、累计下单用户量数据不准，需要限制首访、首下单日期<=统计日期
9）活动名额数、活动消耗不准
10）探店/公益下单活动数，改为”探店/公益有下单活动数“
11）在线店铺数：按照店铺城市，端为”全部“
12）人审订单量不准，需要记录每次变化的订单，不是最终状态；
13）增加“人审订单次数”指标
14）人审认证指标，要新接数据处理；
15）笔记人审驳回订单量、驳回次数，不限制订单状态；


======================




1）绑定企微到店用户(限制当前日期)
绑定企微用户转化率
2）解锁达人用户量（口径估计不准，要确认）
3）认证用户量、认证小红书名片数、认证大众点评名片数（口径估计不准，要确认）
4)通过考核用户量(限制当前日期)
5)下单用户量、下单量（需要用t3做主表，没有城市和端，设置为其他）
6）在线店铺数（两个统计表都不对，表一小于在线活动数，异常；表二是新增，错误统计）
7）笔记人审驳回订单量、笔记人审驳回次数（用订单表直接处理）
8）人审订单、人审认证（区分城市和端，使用对应数据表直接处理）

9）新用户数（表一和表二不一致）
10）在线店铺数（表一和表二不一致）
销单量
11）核销订单量（漏斗）
12）完单量（漏斗）
13）待上传订单量（漏斗）



解锁达人


dim.dim_silkworm_explore_daren
dim.dim_silkworm_explore_merchant
dim.dim_silkworm_explore_store
dwd.dwd_sr_silkworm_explore_auth_record
dwd.dwd_sr_silkworm_explore_bind_wework_record
dwd.dwd_sr_silkworm_explore_notes_upload_history
dwd.dwd_sr_silkworm_explore_order
dwd.dwd_sr_silkworm_explore_promotion
dwd.dwd_hive_silkworm_explore_reward_record


with t as (
select
    user_id,
    if(daren_score>=40,1,0) is_daren, -- 1:达人
    substring(daren_activate_time,1,10) as daren_activate_date, -- 达人激活日期
    substring(xiaohongshu_auth_first_time,1,10) as xiaohongshu_auth_first_date, -- 小红书首次认证日期
    substring(dp_auth_first_time,1,10) as dp_auth_first_date, -- 大众点评首次认证日期
    substring(xiaohongshu_first_order_time,1,10) as xiaohongshu_first_order_date, -- 小红书首次下单日期
    substring(dp_first_order_time,1,10) as dp_first_order_date, -- 大众点评首次下单日期
    -- 访问用户
    first_view_date, -- 首次访问日期
    first_explode_view_date as first_explore_view_date, -- 探店首次访问日期
    first_welfare_view_date, -- 公益首次访问日期
    -- 新增首单用户
    first_order_date, -- 新增首单日期
    first_explode_order_date as first_explore_order_date, -- 探店新增首单日期
    first_welfare_order_date -- 公益新增首单日期
from dim.dim_hive_silkworm_explore_daren a
where status=1 -- 1:正常,2:删除
    -- and first_view_date between date_sub('${T-1}',1) and '${T-1}'
)

select
    first_view_date,
    -- 新用户数（首次访问日期是统计日期）
    count(distinct user_id) as newuser_num -- 今日整体新用户数
from t
group by 1



with t1 as (
select
    a.user_id,
    if(daren_score>=40,1,0) is_daren, -- 1:达人
    substring(daren_activate_time,1,10) as daren_activate_date, -- 达人激活日期
    substring(xiaohongshu_auth_first_time,1,10) as xiaohongshu_auth_first_date, -- 小红书首次认证日期
    substring(dp_auth_first_time,1,10) as dp_auth_first_date, -- 大众点评首次认证日期
    substring(xiaohongshu_first_order_time,1,10) as xiaohongshu_first_order_date, -- 小红书首次下单日期
    substring(dp_first_order_time,1,10) as dp_first_order_date, -- 大众点评首次下单日期
    -- 访问用户
    first_view_date, -- 首次访问日期
    first_explode_view_date as first_explore_view_date, -- 探店首次访问日期
    first_welfare_view_date, -- 公益首次访问日期
    -- 新增首单用户
    first_order_date, -- 新增首单日期
    first_explode_order_date as first_explore_order_date, -- 探店新增首单日期
    first_welfare_order_date -- 公益新增首单日期
from dim.dim_hive_silkworm_explore_daren a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and b.city_id=3301 -- 杭州
-- where daren_score>=40
),


-- 探店用户下首单时间
t2 as (
    select  user_id,
        cast(to_date(min(create_time)) as string) as order_date
    from    dwd.dwd_hive_silkworm_explore_order
    where   dt between '2024-06-18'
    and     '2024-09-09'
    and     store_name not regexp '测试'
    and promotion_type in (1,4) -- 探店
group by 1
)


select
    count(distinct if(daren_activate_date between '2024-08-26' and '2024-09-01' and is_daren=1,t1.user_id,null)) as `0826-0901解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-08-26' and '2024-09-01' and is_daren=1 and t2.order_date between '2024-08-26' and '2024-09-01',t1.user_id,null)) as `0826-0901下首单且解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-08-26' and '2024-09-01' and is_daren=1 and first_explore_order_date between '2024-08-26' and '2024-09-01',t1.user_id,null)) as `0826-0901完成首单且解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-02' and '2024-09-07' and is_daren=1,t1.user_id,null)) as `0902-0907解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-02' and '2024-09-07' and is_daren=1 and t2.order_date between '2024-09-02' and '2024-09-07',t1.user_id,null)) as `0902-0907下首单且解锁达人用户数`,
    count(distinct if(daren_activate_date between '2024-09-02' and '2024-09-07' and is_daren=1 and first_explore_order_date between '2024-09-02' and '2024-09-07',t1.user_id,null)) as `0902-0907完成首单且解锁达人用户数`
from t1 left join t2 on t1.user_id=t2.user_id



























