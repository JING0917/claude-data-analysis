--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2024-09-24 14:48:35
--******************************************************************--
-- drop table if EXISTS dws.dws_sr_order_dashboard_county_d;

CREATE TABLE IF NOT EXISTS  dws.dws_sr_order_explore_county_d(
    `statisticsdate` date comment '统计日期',
    `platform_name` string comment '平台名称',
    `city_name` string comment '城市',
    `county_name` string comment '区县',
    `takeaway_newuser_num` int comment '小蚕新用户量',
    `newuser_num` int comment '到店新用户量',
    `yd_newuser_num` int comment '昨日新增用户量',
    `retention_newuser_num` int comment '留存新用户量',
    `explore_newuser_num` int comment '探店新用户',
    `welfare_newuser_num` int comment '公益新用户',
    `bind_wework_newuser_num` int comment '新绑定企微到店用户',
    `valid_newuser_num` int comment '新增有效用户',
    `valid_explore_newuser_num` int comment '探店新增有效用户',
    `valid_welfare_newuser_num` int comment '公益新增有效用户',
    `view_user_num` int comment '活跃用户',
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
    `first_order_user_num` int comment '首单用户',
    `first_explore_order_user_num` int comment '探店首单用户',
    `first_welfare_order_user_num` int comment '公益首单用户',
    `tot_used_promotion_quota` int comment '消耗活动名额',
    `explore_tot_used_promotion_quota` int comment '探店消耗活动名额',
    `welfare_tot_used_promotion_quota` int comment '公益消耗活动名额',
    `acc_view_user_num` int comment '累计访问用户量',
    `acc_explore_view_user_num` int comment '探店累计访问用户量',
    `acc_welfare_view_user_num` int comment '公益累计访问用户量',
    `acc_order_user_num` int comment '累计下单用户量',
    `acc_explore_order_user_num` int comment '探店累计下单用户量',
    `acc_welfare_order_user_num` int comment '公益累计下单用户量',
    `onlin_promotion_quota` int comment '活动名额',
    `explore_onlin_promotion_quota` int comment '探店活动名额',
    `welfare_onlin_promotion_quota` int comment '公益活动名额',
    `online_store_num` int comment '在线店铺数',
    `explore_online_store_num` int comment '探店在线店铺数',
    `welfare_online_store_num` int comment '公益在线店铺数',
    `order_promotion_num` int comment '下单活动数',
    `explore_order_promotion_num` int comment '探店下单活动数',
    `welfare_order_promotion_num` int comment '公益下单活动数',
    `promotion_num` int comment '活动数',
    `explore_promotion_num` int comment '探店活动数',
    `welfare_promotion_num` int comment '公益活动数',
    `renshen_order_num` int comment '人审订单量',
    `explore_renshen_order_num` int comment '探店人审订单量',
    `welfare_renshen_order_num` int comment '公益人审订单量',
    `renshen_order_cnt` int comment '人审订单次数',
    `explore_renshen_order_cnt` int comment '探店人审订单次数',
    `welfare_renshen_order_cnt` int comment '公益人审订单次数',
    `renshen_auth_num` int comment '人审认证量',
    `explore_renshen_auth_num` int comment '探店人审认证量',
    `welfare_renshen_auth_num` int comment '公益人审认证量',
    `notes_renshen_reject_order_num` int comment '笔记人审驳回订单量',
    `explore_notes_renshen_reject_order_num` int comment '探店笔记人审驳回订单量',
    `welfare_notes_renshen_reject_order_num` int comment '公益笔记人审驳回订单量',
    `notes_renshen_reject_num` int comment '笔记人审驳回次数',
    `explore_notes_renshen_reject_num` int comment '探店笔记人审驳回次数',
    `welfare_notes_renshen_reject_num` int comment '公益笔记人审驳回次数',
    `last7d_retention_newuser_num` int comment '7日留存新用户量',
    `last30d_retention_newuser_num` int comment '30日留存新用户量',
    `explore_order_newuser_num` int comment '探店下单新用户',
    `welfare_order_newuser_num` int comment '公益下单新用户',
    `explore_auth_newuser_num` int comment '探店认证新用户量',
    `welfare_auth_newuser_num` int comment '公益认证新用户量',
    `explore_bind_wework_newuser_num` int comment '探店新绑定企微到店用户',
    `welfare_bind_wework_newuser_num` int comment '公益新绑定企微到店用户',
    `explore_first_order_user_num` int comment '探店下首单用户',
    `welfare_first_order_user_num` int comment '公益下首单用户',
    `explore_first_finishorder_user_num` int comment '探店首次完单用户',
    `welfare_first_finishorder_newuser_num` int comment '公益首次完单用户',
    `explore_znorder_num` int comment '探店站内下单量',
    `explore_zworder_num` int comment '探店站外下单量',
    `explore_notpay_manucancel_order_num` int comment '探店未支付手动取消下单量',
    `explore_pay_timeout_order_num` int comment '探店支付超时取消下单量',
    `explore_payorder_num` int comment '探店已支付下单量',
    `explore_notverify_manucancel_order_num` int comment '探店未核销手动取消下单量',
    `welfare_notverify_manucancel_order_num` int comment '公益未核销手动取消下单量',
    `explore_verify_timeout_order_num` int comment '探店核销超时取消下单量',
    `welfare_verify_timeout_order_num` int comment '公益核销超时取消下单量',
    `explore_verify_rejectcancel_order_num` int comment '探店未核销驳回取消下单量',
    `explore_verifyorder_num` int comment '探店已核销下单量',
    `welfare_verifyorder_num` int comment '公益已核销下单量',
    `explore_notsubmitnote_manucancel_order_num` int comment '探店未提交笔记手动取消下单量',
    `explore_submitnote_timeout_order_num` int comment '探店笔记提交超时下单量',
    `welfare_submitnote_timeout_order_num` int comment '公益笔记提交超时下单量',
    `explore_notereject_cancel_order_num` int comment '探店笔记驳回取消下单量',
    `welfare_notereject_cancel_order_num` int comment '公益笔记驳回取消下单量',
    `explore_finishorder_num` int comment '探店完单量',
    `welfare_finishorder_num` int comment '公益完单量',
    `explore_upload_order_num` int comment '探店待上传下单量',
    `welfare_upload_order_num` int comment '公益待上传下单量',
    `explore_wcorder_num` int comment '探店当日完单量',
    `welfare_wcorder_num` int comment '公益当日完单量'
)
PRIMARY KEY (statisticsdate,platform_name,city_name,county_name)
COMMENT '到店区县日数据'
PARTITION BY date_trunc('day', statisticsdate)
DISTRIBUTED BY HASH (statisticsdate)
ORDER BY (statisticsdate)
PROPERTIES (
   "replication_num" ="2",
    "compression" = "LZ4"
);

insert into dws.dws_sr_order_explore_county_d

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
            str_to_date(substr(xiaohongshu_auth_time,1,10),'%Y-%m-%d') as xiaohongshu_auth_date, -- 小红书认证日期
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
    select  '${T-1}' as statistics_date,
            ifnull(platform_name, '全部') as platform_name,
            ifnull(city_name, '全部') as city_name,
            ifnull(county_name, '全部') as county_name,
            count(distinct a.user_id) as yd_newuser_num, -- 昨日新增用户量
            count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=1,b.user_id,null)) as retention_newuser_num, -- 次日留存新用户量,
            count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=7,b.user_id,null)) as last7d_retention_newuser_num, -- 7日留存新用户量 -- 20241008 新增 修改人：dahe
            count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=30,b.user_id,null)) as last30d_retention_newuser_num -- 30日留存新用户量 -- 20241008 新增 修改人：dahe
    from(
-- 昨日到店新增访问用户
        select  t1.first_view_date,
                t1.user_id,
                dim_user.platform_name,
                dim_user.city_name,
                dim_user.county_name
        from    dim_user
        inner join t1
        on      t1.user_id = dim_user.user_id
        and     first_view_date = date_sub('${T-1}', 1)
        ) a
    left join 
-- 访问用户
            (
                select  statistics_date,
                        cast(user_id as int) as user_id
                from    dws.dws_sr_traffic_user_d
                where   statistics_date in ('${T-1}',date_add('${T-1}',interval 7 day),date_add('${T-1}',interval 30 day))
                and     user_id regexp '^[0-9]{1,9}$' -- 20240823调整，限制登录用户，减少数据量 修改人：dahe
                group by 1,2
                having  (
                            sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
                            or      sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) > 0
                        )
            ) b
                on      a.user_id = b.user_id
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
            -- explore_pv,
            -- welfare_pv
            sum(explore_pv) as explore_pv, -- 20241008 新增逻辑 修改人：dahe
            sum(welfare_pv) as welfare_pv -- 20241008 新增逻辑 修改人：dahe
    from    (
                select  statistics_date, 
                        user_id, -- 20240823调整 修改人：dahe
                        case when platform_name in ('h5', '营销H5') then 'H5' when platform_name = 'Android' then 'Android' when platform_name = 'iOS' then 'iOS' when platform_name = '小程序' then '小程序' else '其他' end as platform_name,
                        cast(county_id as int) as county_id,
                        sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) as explore_pv, -- 值>0，则是探店用户
                        sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) as welfare_pv -- 值>0，则是公益用户
                from    dws.dws_sr_traffic_user_d
                where   statistics_date = '${T-1}' 
                group by 1,
                        2,
                        3,
                        4
            ) a
    left join dim_city
    on a.county_id = dim_city.county_id
group by 1,2,3,4,5 -- 20241008 新增逻辑 修改人：dahe
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
    on      b.county_id = dim_city.county_id
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
    on      a.county_id = dim_city.county_id
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
    select  a.dt as statistics_date,
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
    select  dt as statistics_date,
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



-- 统计
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
        sum(welfare_notes_renshen_reject_num) as welfare_notes_renshen_reject_num -- 公益笔记人审驳回次数
        -- 20241008新增 修改人：dahe
        ,sum(last7d_retention_newuser_num) as last7d_retention_newuser_num -- 7日留存新用户量
        ,sum(last30d_retention_newuser_num) as last30d_retention_newuser_num -- 30日留存新用户量
        ,sum(explore_order_newuser_num) as explore_order_newuser_num -- 探店下单新用户 当日新用户中下单人数
        ,sum(welfare_order_newuser_num) as welfare_order_newuser_num -- 公益下单新用户 当日新用户中下单人数
        ,sum(explore_auth_newuser_num) as explore_auth_newuser_num -- 探店认证新用户量
        ,sum(welfare_auth_newuser_num) as welfare_auth_newuser_num -- 公益认证新用户量
        ,sum(explore_bind_wework_newuser_num) as explore_bind_wework_newuser_num -- 探店新绑定企微到店用户
        ,sum(welfare_bind_wework_newuser_num) as welfare_bind_wework_newuser_num -- 公益新绑定企微到店用户
        ,sum(explore_first_order_user_num) as explore_first_order_user_num -- 探店下首单用户 当日用户中下首单人数
        ,sum(welfare_first_order_user_num) as welfare_first_order_user_num -- 公益下首单用户 当日用户中下首单人数   
        ,sum(explore_first_finishorder_user_num) as explore_first_finishorder_user_num -- 探店首次完单用户
        ,sum(welfare_first_finishorder_newuser_num) as welfare_first_finishorder_newuser_num -- 公益首次完单用户
        -- 20241009新增 修改人：dahe
        ,sum(explore_znorder_num) as explore_znorder_num -- 探店站内下单量
        ,sum(explore_zworder_num) as explore_zworder_num -- 探店站外下单量
        ,sum(explore_notpay_manucancel_order_num) as explore_notpay_manucancel_order_num -- 探店未支付手动取消下单量
        ,sum(explore_pay_timeout_order_num) as explore_pay_timeout_order_num -- 探店支付超时取消下单量
        ,sum(explore_payorder_num) as explore_payorder_num -- 探店已支付下单量
        ,sum(explore_notverify_manucancel_order_num) as explore_notverify_manucancel_order_num -- 探店未核销手动取消下单量
        ,sum(welfare_notverify_manucancel_order_num) as welfare_notverify_manucancel_order_num -- 公益未核销手动取消下单量
        ,sum(explore_verify_timeout_order_num) as explore_verify_timeout_order_num -- 探店核销超时取消下单量
        ,sum(welfare_verify_timeout_order_num) as welfare_verify_timeout_order_num -- 公益核销超时取消下单量
        ,sum(explore_verify_rejectcancel_order_num) as explore_verify_rejectcancel_order_num -- 探店未核销驳回取消下单量
        ,sum(explore_verifyorder_num) as explore_verifyorder_num -- 探店已核销下单量
        ,sum(welfare_verifyorder_num) as welfare_verifyorder_num -- 公益已核销下单量
        ,sum(explore_notsubmitnote_manucancel_order_num) as explore_notsubmitnote_manucancel_order_num -- 探店未提交笔记手动取消下单量
        ,sum(explore_submitnote_timeout_order_num) as explore_submitnote_timeout_order_num -- 探店笔记提交超时下单量
        ,sum(welfare_submitnote_timeout_order_num) as welfare_submitnote_timeout_order_num -- 公益笔记提交超时下单量
        ,sum(explore_notereject_cancel_order_num) as explore_notereject_cancel_order_num -- 探店笔记驳回取消下单量
        ,sum(welfare_notereject_cancel_order_num) as welfare_notereject_cancel_order_num -- 公益笔记驳回取消下单量
        ,sum(explore_finishorder_num) as explore_finishorder_num -- 探店完单量 当日下单且完单
        ,sum(welfare_finishorder_num) as welfare_finishorder_num -- 公益完单量 当日下单且完单
        ,sum(explore_upload_order_num) as explore_upload_order_num -- 探店待上传下单量
        ,sum(welfare_upload_order_num) as welfare_upload_order_num -- 公益待上传下单量               
        ,sum(explore_wcorder_num) as explore_wcorder_num -- 探店当日完单量
        ,sum(welfare_wcorder_num) as welfare_wcorder_num -- 公益当日完单量        
from    -- 小蚕新用户
        (
            select  '${T-1}' as statistics_date,
                    ifnull(dim_user.platform_name, '全部') as platform_name,
                    ifnull(dim_user.city_name, '全部') as city_name,
                    ifnull(dim_user.county_name, '全部') as county_name,
                    count(distinct if(dim_user.register_date = '${T-1}',dim_user.user_id,null)) as takeaway_newuser_num, -- 小蚕新用户量(统计日期内注册)
                    count(distinct if(t1.first_view_date = '${T-1}', dim_user.user_id, null)) as newuser_num, -- 到店新用户量(统计日期内访问到店页面)
                    0 as yd_newuser_num, -- 昨日新增用户量
                    0 as retention_newuser_num, -- 留存新用户量
                    count(distinct if(t1.first_explore_view_date = '${T-1}', dim_user.user_id, null)) as explore_newuser_num, -- 探店新用户(统计日期内访问探店页面)
                    count(distinct if(t1.first_welfare_view_date = '${T-1}', dim_user.user_id, null)) as welfare_newuser_num, -- 公益新用户(统计日期内访问公益页面)
                    0 as bind_wework_newuser_num, -- 新绑定企微到店用户
                    0 as valid_newuser_num, -- 新增有效用户 20240807新增 修改人：dahe
                    0 as valid_explore_newuser_num, -- 探店新增有效用户
                    0 as valid_welfare_newuser_num, -- 公益新增有效用户
                    0 as view_user_num, -- 活跃用户量  20240807新增 修改人：dahe
                    0 as explore_view_user_num, -- 探店活跃用户量
                    0 as welfare_view_user_num, -- 公益活跃用户量
                    0 as newdaren_num, -- 新增解锁达人用户量
                    0 as auth_newuser_num, -- 新增认证用户量
                    0 as auth_xiaohongshu_newuser_num, -- 新增认证小红书用户量
                    0 as auth_dp_newuser_num, -- 新增认证大众点评用户量
                    0 as pass_exam_user_num, -- 通过考核用户量
                    0 as order_user_num, -- 下单用户量
                    0 as explore_order_user_num, -- 探店下单用户量
                    0 as welfare_order_user_num, -- 公益下单用户量
                    0 as order_num, -- 下单量
                    0 as explore_order_num, -- 探店下单量
                    0 as welfare_order_num, -- 公益下单量
                    0 as first_order_user_num, -- 首单用户
                    0 as first_explore_order_user_num, -- 探店首单用户
                    0 as first_welfare_order_user_num, -- 公益首单用户
                    0 as tot_used_promotion_quota, -- 消耗活动名额
                    0 as explore_tot_used_promotion_quota, -- 探店消耗活动名额
                    0 as welfare_tot_used_promotion_quota, -- 公益消耗活动名额
                    0 as acc_view_user_num, -- 累计访问用户量 20240807新增 修改人：dahe
                    0 as acc_explore_view_user_num, -- 探店累计访问用户量
                    0 as acc_welfare_view_user_num, -- 公益累计访问用户量
                    0 as acc_order_user_num, -- 累计下单用户量 20240807新增 修改人：dahe
                    0 as acc_explore_order_user_num, -- 探店累计下单用户量
                    0 as acc_welfare_order_user_num, -- 公益累计下单用户量
                    0 as onlin_promotion_quota, -- 活动名额 20240807新增 修改人：dahe
                    0 as explore_onlin_promotion_quota, -- 探店活动名额  
                    0 as welfare_onlin_promotion_quota, -- 公益活动名额
                    0 as online_store_num, -- 在线店铺数 20240807新增 修改人：dahe
                    0 as explore_online_store_num, -- 探店在线店铺数 
                    0 as welfare_online_store_num, -- 公益在线店铺数
                    0 as order_promotion_num, -- 下单活动数 20240807新增 修改人：dahe
                    0 as explore_order_promotion_num, -- 探店下单活动数
                    0 as welfare_order_promotion_num, -- 公益下单活动数
                    0 as promotion_num, -- 活动数 20240807新增 修改人：dahe
                    0 as explore_promotion_num, -- 探店活动数
                    0 as welfare_promotion_num, -- 公益活动数
                    0 as renshen_order_num, -- 人审订单量 20240807新增 修改人：dahe
                    0 as explore_renshen_order_num, -- 探店人审订单量
                    0 as welfare_renshen_order_num, -- 公益人审订单量
                    0 as renshen_order_cnt, -- 人审订单次数 -- 20240807新增 修改人：dahe
                    0 as explore_renshen_order_cnt, -- 探店人审订单次数 -- 20240807新增 修改人：dahe
                    0 as welfare_renshen_order_cnt, -- 公益人审订单次数 -- 20240807新增 修改人：dahe
                    0 as renshen_auth_num, -- 人审认证量 20240807新增 修改人：dahe
                    0 as explore_renshen_auth_num, -- 探店人审认证量
                    0 as welfare_renshen_auth_num, -- 公益人审认证量
                    0 as notes_renshen_reject_order_num, -- 笔记人审驳回订单量 20240807新增 修改人：dahe
                    0 as explore_notes_renshen_reject_order_num, -- 探店笔记人审驳回订单量
                    0 as welfare_notes_renshen_reject_order_num, -- 公益笔记人审驳回订单量
                    0 as notes_renshen_reject_num, -- 笔记人审驳回次数 20240807新增 修改人：dahe
                    0 as explore_notes_renshen_reject_num, -- 探店笔记人审驳回次数
                    0 as welfare_notes_renshen_reject_num -- 公益笔记人审驳回次数
                    -- 20241008新增 修改人：dahe
                    ,0 as last7d_retention_newuser_num -- 7日留存新用户量
                    ,0 as last30d_retention_newuser_num -- 30日留存新用户量
                    ,0 as explore_order_newuser_num -- 探店下单新用户 当日新用户中下单人数
                    ,0 as welfare_order_newuser_num -- 公益下单新用户 当日新用户中下单人数
                    ,0 as explore_auth_newuser_num -- 探店认证新用户量
                    ,0 as welfare_auth_newuser_num -- 公益认证新用户量
                    ,0 as explore_bind_wework_newuser_num -- 探店新绑定企微到店用户
                    ,0 as welfare_bind_wework_newuser_num -- 公益新绑定企微到店用户
                    ,0 as explore_first_order_user_num -- 探店下首单用户 当日用户中下首单人数
                    ,0 as welfare_first_order_user_num -- 公益下首单用户 当日用户中下首单人数   
                    ,0 as explore_first_finishorder_user_num -- 探店首次完单用户
                    ,0 as welfare_first_finishorder_newuser_num -- 公益首次完单用户
                    -- 20241009新增 修改人：dahe
                    ,0 as explore_znorder_num -- 探店站内下单量
                    ,0 as explore_zworder_num -- 探店站外下单量
                    ,0 as explore_notpay_manucancel_order_num -- 探店未支付手动取消下单量
                    ,0 as explore_pay_timeout_order_num -- 探店支付超时取消下单量
                    ,0 as explore_payorder_num -- 探店已支付下单量
                    ,0 as explore_notverify_manucancel_order_num -- 探店未核销手动取消下单量
                    ,0 as welfare_notverify_manucancel_order_num -- 公益未核销手动取消下单量
                    ,0 as explore_verify_timeout_order_num -- 探店核销超时取消下单量
                    ,0 as welfare_verify_timeout_order_num -- 公益核销超时取消下单量
                    ,0 as explore_verify_rejectcancel_order_num -- 探店未核销驳回取消下单量
                    ,0 as explore_verifyorder_num -- 探店已核销下单量
                    ,0 as welfare_verifyorder_num -- 公益已核销下单量
                    ,0 as explore_notsubmitnote_manucancel_order_num -- 探店未提交笔记手动取消下单量
                    ,0 as explore_submitnote_timeout_order_num -- 探店笔记提交超时下单量
                    ,0 as welfare_submitnote_timeout_order_num -- 公益笔记提交超时下单量
                    ,0 as explore_notereject_cancel_order_num -- 探店笔记驳回取消下单量
                    ,0 as welfare_notereject_cancel_order_num -- 公益笔记驳回取消下单量
                    ,0 as explore_finishorder_num -- 探店完单量 当日下单且完单
                    ,0 as welfare_finishorder_num -- 公益完单量 当日下单且完单
                    ,0 as explore_upload_order_num -- 探店待上传下单量
                    ,0 as welfare_upload_order_num -- 公益待上传下单量               
                    ,0 as explore_wcorder_num -- 探店当日完单量
                    ,0 as welfare_wcorder_num -- 公益当日完单量
            from    dim_user
            left join t1
            on      dim_user.user_id = t1.user_id
            -- where   dim_user.register_date = '${T-1}' -- 20240823 取消限制，新用户是首次访问 修改人：dahe
            group by grouping sets (
                        (dim_user.register_date),
                        (dim_user.register_date, dim_user.platform_name),
                        (dim_user.register_date, dim_user.city_name),
                        (dim_user.register_date, dim_user.platform_name, dim_user.city_name, dim_user.county_name)
                    )

            union all

            -- 留存用户
            select  statistics_date,
                    platform_name,
                    city_name,
                    county_name,
                    0, 0,
                    yd_newuser_num as yd_newuser_num, -- 昨日新增用户量
                    retention_newuser_num as retention_newuser_num, -- 留存新用户量
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                    ,last7d_retention_newuser_num -- 7日留存新用户量 -- 20241008 新增 修改人：dahe
                    ,last30d_retention_newuser_num -- 30日留存新用户量 -- 20241008 新增 修改人：dahe
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
            from    view_newuser

            union all

            -- 新增绑定企微用户
            select  '${T-1}' as statistics_date,
                    ifnull(dim_user.platform_name, '全部') as platform_name,
                    ifnull(dim_user.city_name, '全部') as city_name,
                    ifnull(dim_user.county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0,
                    count(
                        distinct if(
                            t1.bind_wework_date = '${T-1}'
                            and     t1.is_bind_wework = 1,
                                    dim_user.user_id,
                                    null
                        )
                    ) as bind_wework_newuser_num, -- 新绑定企微到店用户（需要限制当前日期 修改人：dahe）
                    count(
                        distinct if(
                            t1.first_view_date is not null
                            and     (
                                        t1.xiaohongshu_auth_first_date = '${T-1}'
                                        or      t1.dp_auth_first_date = '${T-1}'
                                    ),
                                    t1.user_id,
                                    null
                        )
                    ) as valid_newuser_num, -- 新增有效用户 20240807新增 修改人：dahe
                    count(
                        distinct if(
                            t1.first_explore_view_date is not null
                            and     (
                                        t1.xiaohongshu_auth_first_date = '${T-1}'
                                        or      t1.dp_auth_first_date = '${T-1}'
                                    ),
                                    t1.user_id,
                                    null
                        )
                    ) as valid_explore_newuser_num, -- 探店新增有效用户
                    count(
                        distinct if(
                            t1.first_welfare_view_date is not null
                            and     (
                                        t1.xiaohongshu_auth_first_date = '${T-1}'
                                        or      t1.dp_auth_first_date = '${T-1}'
                                    ),
                                    t1.user_id,
                                    null
                        )
                    ) as valid_welfare_newuser_num, -- 公益新增有效用户
                    0, 0, 0,
                    count(distinct if(daren_activate_date = '${T-1}' and is_daren=1, t1.user_id, null)) as newdaren_num, -- 新增解锁达人用户量 20240823调整 统计日期内激活且达人分>=40 修改人：dahe
                    count(
                        distinct if(
                            xiaohongshu_auth_first_date = '${T-1}'
                            or      dp_auth_first_date = '${T-1}',
                                    t1.user_id,
                                    null
                        )
                    ) as auth_newuser_num, -- 新增认证用户量
                    count(
                        distinct if(
                            xiaohongshu_auth_first_date = '${T-1}'
                            and     length(auth_xiaohongshu_id) > 1,
                                    t1.auth_xiaohongshu_id,
                                    null
                        )
                    ) as auth_xiaohongshu_newuser_num, -- 新增认证小红书名片数 历史原因，为减小改动，字段名不调整，只改建表中文字段名
                    count(
                        distinct if(
                            dp_auth_first_date = '${T-1}'
                            and     length(auth_dp_id) > 1,
                                    t1.auth_dp_id,
                                    null
                        )
                    ) as auth_dp_newuser_num, -- 新增认证大众点评名片数 历史原因，为减小改动，字段名不调整，只改建表中文字段名
                    -- count(distinct if(t1.create_date='${T-1}' and is_finish_exam = 1,t1.user_id,null)) as pass_exam_user_num,
                    count(distinct if(is_finish_exam = 1 and pass_exam_date='${T-1}',t1.user_id,null)) as pass_exam_user_num, -- 通过考核用户量 20240823调整，去掉create_date限制 修改人：dahe
                    0, 0, 0, 0, 0, 0,
                    count(
                        distinct if(
                            t1.first_order_date = '${T-1}',
                                    dim_user.user_id,
                                    null
                        )
                    ) as first_order_user_num, -- 首单用户
                    count(
                        distinct if(
                            t1.first_explore_order_date = '${T-1}',
                                    dim_user.user_id,
                                    null
                        )
                    ) as first_explore_order_user_num, -- 探店首单用户
                    count(
                        distinct if(
                            t1.first_welfare_order_date = '${T-1}',
                                    dim_user.user_id,
                                    null
                        )
                    ) as first_welfare_order_user_num, -- 公益首单用户
                    0, 0, 0, 
                    count(distinct if(t1.first_view_date is not null, dim_user.user_id, null)) as acc_view_user_num, -- 累计访问用户量 20240807新增 修改人：dahe
                    count(distinct if(t1.first_explore_view_date is not null, dim_user.user_id, null)) as acc_explore_view_user_num, -- 探店累计访问用户量
                    count(distinct if(t1.first_welfare_view_date is not null, dim_user.user_id, null)) as acc_welfare_view_user_num, -- 公益累计访问用户量
                    count(distinct if(t1.first_order_date is not null, dim_user.user_id, null)) as acc_order_user_num, -- 累计下单用户量 20240807新增 修改人：dahe
                    count(distinct if(t1.first_explore_order_date is not null, dim_user.user_id, null)) as acc_explore_order_user_num, -- 探店累计下单用户量
                    count(distinct if(t1.first_welfare_order_date is not null, dim_user.user_id, null)) as acc_welfare_order_user_num, -- 公益累计下单用户量
                    0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0
                    ,0
                    ,count(distinct if(t1.first_explore_view_date='${T-1}' and t3.order_date='${T-1}',t1.user_id,null)) as explore_order_newuser_num -- 探店下单新用户 当日新用户中下单人数
                    ,count(distinct if(t1.first_welfare_view_date='${T-1}' and t3.order_date='${T-1}',t1.user_id,null)) as welfare_order_newuser_num -- 公益下单新用户 当日新用户中下单人数
                    ,count(distinct if((t1.xiaohongshu_auth_first_date = '${T-1}' or t1.dp_auth_first_date = '${T-1}') and t1.first_explore_view_date='${T-1}',t1.user_id,null)) as explore_auth_newuser_num -- 探店认证新用户量
                    ,count(distinct if((t1.xiaohongshu_auth_first_date = '${T-1}' or t1.dp_auth_first_date = '${T-1}') and t1.first_welfare_view_date='${T-1}',t1.user_id,null)) as welfare_auth_newuser_num -- 公益认证新用户量
                    ,count(distinct if(t1.first_explore_view_date='${T-1}' and t1.bind_wework_date = '${T-1}' and t1.is_bind_wework = 1,dim_user.user_id,null)) as explore_bind_wework_newuser_num -- 探店新绑定企微到店用户
                    ,count(distinct if(t1.first_welfare_view_date='${T-1}' and t1.bind_wework_date = '${T-1}' and t1.is_bind_wework = 1,dim_user.user_id,null)) as welfare_bind_wework_newuser_num -- 公益新绑定企微到店用户
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4),t1.user_id,null)) as explore_first_order_user_num -- 探店下首单用户 当日用户中下首单人数
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3),t1.user_id,null)) as welfare_first_order_user_num -- 公益下首单用户 当日用户中下首单人数   
                    ,count(distinct if(t1.first_explore_order_date='${T-1}' and t3.promotion_type in (1,4),t1.user_id,null)) as explore_first_finishorder_user_num -- 探店首次完单用户
                    ,count(distinct if(t1.first_welfare_order_date='${T-1}' and t3.promotion_type in (2,3),t1.user_id,null)) as welfare_first_finishorder_newuser_num -- 公益首次完单用户
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0          
            from    t1
            left join dim_user
            on      dim_user.user_id = t1.user_id
            left join t3 on t1.user_id=t3.user_id -- 20241008 新增 修改人：dahe
            group by grouping sets (
                        ('${T-1}'),
                        ('${T-1}', dim_user.platform_name),
                        ('${T-1}', dim_user.city_name),
                        ('${T-1}', dim_user.platform_name, dim_user.city_name, dim_user.county_name)
                    )

            union all

            -- 活跃用户
            select  t2.statistics_date,
                    ifnull(t2.platform_name, '全部') as platform_name,
                    ifnull(t2.city_name, '全部') as city_name,
                    ifnull(t2.county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    count(distinct if(t2.explore_pv>0 or t2.welfare_pv>0,t2.user_id,null)) as view_user_num, -- 活跃用户量  20240807新增 修改人：dahe
                    count(distinct if(t2.explore_pv > 0, t2.user_id, null)) as explore_view_user_num, -- 探店活跃用户量
                    count(distinct if(t2.welfare_pv > 0, t2.user_id, null)) as welfare_view_user_num, -- 公益活跃用户量
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    from    t2
            group by grouping sets (
                        (t2.statistics_date),
                        (t2.statistics_date, t2.platform_name),
                        (t2.statistics_date, t2.city_name),
                        (t2.statistics_date, t2.platform_name, t2.city_name, t2.county_name)
                    )

            union all

            -- 下单用户
            select  '${T-1}' as statistics_date,
                    ifnull(dim_user.platform_name, '全部') as platform_name,
                    ifnull(dim_user.city_name, '全部') as city_name,
                    ifnull(dim_user.county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    count(distinct if(t3.order_date='${T-1}',t3.user_id,null)) as order_user_num, -- 下单用户量
                    count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4),t3.user_id,null)) as explore_order_user_num, -- 探店下单用户量
                    count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3),t3.user_id,null)) as welfare_order_user_num, -- 公益下单用户量
                    count(distinct if(t3.order_date='${T-1}',t3.order_id,null)) as order_num, -- 下单量
                    count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4),t3.order_id,null)) as explore_order_num, -- 探店下单量
                    count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3),t3.order_id,null)) as welfare_order_num, -- 公益下单量
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    -- 20241009新增 修改人：dahe
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type=1,t3.order_id,null)) as explore_znorder_num -- 探店站内下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type=4,t3.order_id,null)) as explore_zworder_num -- 探店站外下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status=8,t3.order_id,null)) as explore_notpay_manucancel_order_num -- 探店未支付手动取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status=6,t3.order_id,null)) as explore_pay_timeout_order_num -- 探店支付超时取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type=1 and t3.status in (3,4,5,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,30,31,32,33),t3.order_id,null)) as explore_payorder_num -- 探店已支付下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status=9,t3.order_id,null)) as explore_notverify_manucancel_order_num -- 探店未核销手动取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status=9,t3.order_id,null)) as welfare_notverify_manucancel_order_num -- 公益未核销手动取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status in (10,26),t3.order_id,null)) as explore_verify_timeout_order_num -- 探店核销超时取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status=10,t3.order_id,null)) as welfare_verify_timeout_order_num -- 公益核销超时取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status=27,t3.order_id,null)) as explore_verify_rejectcancel_order_num -- 探店未核销驳回取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),t3.order_id,null)) as explore_verifyorder_num -- 探店已核销下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,23),t3.order_id,null)) as welfare_verifyorder_num -- 公益已核销下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status=29,t3.order_id,null)) as explore_notsubmitnote_manucancel_order_num -- 探店未提交笔记手动取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status in (11,14,22,23),t3.order_id,null)) as explore_submitnote_timeout_order_num -- 探店笔记提交超时下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status in (11,14,22,23),t3.order_id,null)) as welfare_submitnote_timeout_order_num -- 公益笔记提交超时下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status=28,t3.order_id,null)) as explore_notereject_cancel_order_num -- 探店笔记驳回取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status=28,t3.order_id,null)) as welfare_notereject_cancel_order_num -- 公益笔记驳回取消下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status in (5,19,20),t3.order_id,null)) as explore_finishorder_num -- 探店完单量 当日下单且完单
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status in (5,19,20),t3.order_id,null)) as welfare_finishorder_num -- 公益完单量 当日下单且完单
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (1,4) and t3.status in (1,2,3,4,12,13,15,16,24,25,30,31,32,33),t3.order_id,null)) as explore_upload_order_num -- 探店待上传下单量
                    ,count(distinct if(t3.order_date='${T-1}' and t3.promotion_type in (2,3) and t3.status in (1,2,3,4,12,13,15,16),t3.order_id,null)) as welfare_upload_order_num -- 公益待上传下单量               
                    ,count(distinct if(t3.promotion_type in (1,4) and t3.finish_date='${T-1}',t3.order_id,null)) as explore_wcorder_num -- 探店当日完单量
                    ,count(distinct if(t3.promotion_type in (2,3) and t3.finish_date='${T-1}',t3.order_id,null)) as welfare_wcorder_num -- 公益当日完单量
            from    t3
            left join dim_user
            on      t3.user_id = dim_user.user_id
            group by grouping sets (
                        ('${T-1}'),
                        ('${T-1}', dim_user.platform_name),
                        ('${T-1}', dim_user.city_name),
                        ('${T-1}', dim_user.platform_name, dim_user.city_name, dim_user.county_name)
                    )
            union all

            -- 活动名额
            select  '${T-1}' as statistics_date,
                    ifnull(platform_name, '全部') as platform_name,
                    ifnull(city_name, '全部') as city_name,
                    ifnull(county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 
                    sum(if(dt='${T-1}',tot_used_promotion_quota,0)) as tot_used_promotion_quota, -- 消耗活动名额
                    sum(if(dt='${T-1}' and promotion_type in (1,4), tot_used_promotion_quota, 0)) as explore_tot_used_promotion_quota, -- 探店消耗活动名额
                    sum(if(dt='${T-1}' and promotion_type in (2,3), tot_used_promotion_quota, 0)) as welfare_tot_used_promotion_quota, -- 公益消耗活动名额
                    0, 0, 0, 0, 0, 0,
                    sum(if(dt='${T-1}',tot_online_promotion_quota,0)) as onlin_promotion_quota, -- 活动名额 20240807新增 修改人：dahe
                    sum(if(dt='${T-1}' and promotion_type in (1,4), tot_online_promotion_quota, 0)) as explore_onlin_promotion_quota, -- 探店活动名额  
                    sum(if(dt='${T-1}' and promotion_type in (2,3), tot_online_promotion_quota, 0)) as welfare_onlin_promotion_quota, -- 公益活动名额
                    0, 0, 0, 0, 0, 0,
                    sum(if(dt='${T-1}',online_promotion_num,0)) as promotion_num, -- 活动数 20240807新增 修改人：dahe
                    sum(if(dt='${T-1}' and promotion_type in (1,4), online_promotion_num, 0)) as explore_promotion_num, -- 探店活动数
                    sum(if(dt='${T-1}' and promotion_type in (2,3), online_promotion_num, 0)) as welfare_promotion_num, -- 公益活动数
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    from    t4
            group by grouping sets (
                                (dt), 
                                (dt, platform_name), 
                                (dt, city_name), 
                                (dt, platform_name, city_name, county_name)
                                )

            union all
            -- 在线店铺
            select  '${T-1}' as statistics_date,
                    ifnull(platform_name, '全部') as platform_name,
                    ifnull(city_name, '全部') as city_name,
                    ifnull(county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    sum(online_store_num) as online_store_num, -- 在线店铺数 20240807新增 修改人：dahe
                    sum(if(business_type = 1, online_store_num, 0)) as explore_online_store_num, -- 探店在线店铺数 
                    sum(if(business_type = 2, online_store_num, 0)) as welfare_online_store_num, -- 公益在线店铺数
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    from    t5
            group by grouping sets (
                        ('${T-1}'),
                        ('${T-1}', platform_name),
                        ('${T-1}', city_name),
                        ('${T-1}', platform_name, city_name, county_name)
                    )
            
            union all

            -- 下单活动数
            select  '${T-1}' as statistics_date,
                    ifnull(dim_user.platform_name, '全部') as platform_name,
                    ifnull(dim_user.city_name, '全部') as city_name,
                    ifnull(dim_user.county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 
                    count(distinct if(t3.order_date = '${T-1}' and t3.order_id is not null, t3.store_promotion_id, null)) as order_promotion_num, -- 下单活动数 20240807新增 修改人：dahe
                    count(
                        distinct if(t3.order_date = '${T-1}' and 
                            promotion_type in (1,4)
                            and     t3.order_id is not null,
                                    t3.store_promotion_id,
                                    null
                        )
                    ) as explore_order_promotion_num, -- 探店有下单活动数
                    count(
                        distinct if(t3.order_date = '${T-1}' and 
                            promotion_type in (2,3)
                            and     t3.order_id is not null,
                                    t3.store_promotion_id,
                                    null
                        )
                    ) as welfare_order_promotion_num, -- 公益有下单活动数
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    count(distinct if(t3.order_date = '${T-1}' and t3.notes_reject_cnt > 0, t3.order_id, null)) as notes_renshen_reject_order_num, -- 笔记人审驳回订单量 20240807新增 修改人：dahe
                    count(
                        distinct if(t3.order_date = '${T-1}' and 
                            promotion_type in (1,4)
                            and     t3.notes_reject_cnt > 0,
                                    t3.order_id,
                                    null
                        )
                    ) as explore_notes_renshen_reject_order_num, -- 探店笔记人审驳回订单量
                    count(
                        distinct if(t3.order_date = '${T-1}' and 
                            promotion_type in (2,3)
                            and     t3.notes_reject_cnt > 0,
                                    t3.order_id,
                                    null
                        )
                    ) as welfare_notes_renshen_reject_order_num, -- 公益笔记人审驳回订单量
                    sum(if(t3.order_date = '${T-1}',t3.notes_reject_cnt,0)) as notes_renshen_reject_num, -- 笔记人审驳回次数 20240807新增 修改人：dahe
                    sum(if(t3.order_date = '${T-1}' and promotion_type in (1,4), t3.notes_reject_cnt, 0)) as explore_notes_renshen_reject_num, -- 探店笔记人审驳回次数
                    sum(if(t3.order_date = '${T-1}' and promotion_type in (2,3), t3.notes_reject_cnt, 0)) as welfare_notes_renshen_reject_num -- 公益笔记人审驳回次数
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
                     from    t3
            left join dim_user
            on      dim_user.user_id = t3.user_id
            group by grouping sets (
                        ('${T-1}'),
                        ('${T-1}', dim_user.platform_name),
                        ('${T-1}', dim_user.city_name),
                        ('${T-1}', dim_user.platform_name, dim_user.city_name, dim_user.county_name)
                    )

            union all

            -- 人审认证订单
            select  statistics_date,
                    ifnull(platform_name, '全部') as platform_name,
                    ifnull(city_name, '全部') as city_name,
                    ifnull(county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0,
                    sum(renshen_order_num) as renshen_order_num, -- 人审订单量 20240807新增 修改人：dahe
                    sum(if(promotion_type in (1,4), renshen_order_num, 0)) as explore_renshen_order_num, -- 探店人审订单量
                    sum(if(promotion_type in (2,3), renshen_order_num, 0)) as welfare_renshen_order_num, -- 公益人审订单量
                    sum(renshen_order_cnt) as renshen_order_cnt, -- 人审订单次数 -- 20240807新增 修改人：dahe
                    sum(if(promotion_type in (1,4), renshen_order_cnt, 0)) as explore_renshen_order_cnt, -- 探店人审订单次数 -- 20240807新增 修改人：dahe
                    sum(if(promotion_type in (2,3), renshen_order_cnt, 0)) as welfare_renshen_order_cnt, -- 公益人审订单次数 -- 20240807新增 修改人：dahe
                    0, 0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
                     from    t6
            group by grouping sets (
                        (statistics_date),
                        (statistics_date, platform_name),
                        (statistics_date, city_name),
                        (statistics_date, platform_name, city_name, county_name)
                    )

            union all

            -- 人审认证
            select  statistics_date,
                    ifnull(platform_name, '全部') as platform_name,
                    ifnull(city_name, '全部') as city_name,
                    ifnull(county_name, '全部') as county_name,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                    sum(renshen_auth_cnt) as renshen_auth_num, -- 人审认证量 20240807新增 修改人：dahe
                    0, 0, 0, 0, 0, 0, 0, 0
                    -- 20241008新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
                     -- 20241009新增 修改人：dahe
                    ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 
                    from    t7
            group by grouping sets (
                        (statistics_date),
                        (statistics_date, platform_name),
                        (statistics_date, city_name),
                        (statistics_date, platform_name, city_name, county_name)
                    )
        ) toa
group by 1,
         2,
         3,
         4
;