--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2024-09-24 14:48:35
--******************************************************************--
-- drop table if EXISTS dws.dws_sr_order_county_d;

CREATE TABLE IF NOT EXISTS  dws.dws_sr_user_explore_viewretention_county_d(
    `statisticsdate` date comment '统计日期',
    `platform_name` string comment '平台名称',
    `city_name` string comment '城市',
    `county_name` string comment '区县',
    `yd_explore_newuser_num` int comment '昨日探店新增用户量',
    `lastd_explore_retention_newuser_num` int comment '次日探店留存新用户量',
    `last7d_explore_retention_newuser_num` int comment '7日探店留存新用户量',
    `last30d_explore_etention_newuser_num` int comment '30日探店留存新用户量',
    `yd_welfare_newuser_num` int comment '昨日公益新增用户量',
    `lastd_welfare_retention_newuser_num` int comment '次日公益留存新用户量',
    `last7d_welfare_retention_newuser_num` int comment '7日公益留存新用户量',
    `last30d_welfare_etention_newuser_num` int comment '30日公益留存新用户量'
)
PRIMARY KEY (statisticsdate,platform_name,city_name,county_name)
COMMENT '到店用户访问留存日数据'
PARTITION BY date_trunc('day', statisticsdate)
DISTRIBUTED BY HASH (statisticsdate)
ORDER BY (statisticsdate)
PROPERTIES (
   "replication_num" ="2",
    "compression" = "LZ4"
);

insert into dws.dws_sr_user_explore_viewretention_county_d

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
            a.user_id,
            if(daren_score >= 40, 1, 0) is_daren, -- 1:达人
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
    from  dim.dim_silkworm_explore_daren_cleanse a
   where date_format(first_view_date, 'yyyy-MM-dd') between '2024-08-12' and '${T-1}'  -- 首次跑数据 因流量数据从8月12日起
-- where str_to_date(register_time,'%Y-%m-%d') between date_sub('${T-1}',interval 30 day) and '${T-1}' -- 自动调度时使用
)


-- -- 留存用户量
select  first_view_date as statistics_date,
        ifnull(platform_name, '全部') as platform_name,
        ifnull(city_name, '全部') as city_name,
        ifnull(county_name, '全部') as county_name,
        count(distinct if(b.explore_pv>0,a.user_id,null)) as yd_explore_newuser_num, -- 昨日探店新增用户量
        count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=1 and b.explore_pv>0,b.user_id,null)) as lastd_explore_retention_newuser_num, -- 次日探店留存新用户量
        count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=7 and b.explore_pv>0,b.user_id,null)) as last7d_explore_retention_newuser_num, -- 7日探店留存新用户量
        count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=30 and b.explore_pv>0,b.user_id,null)) as last30d_explore_etention_newuser_num, -- 30日探店留存新用户量
        count(distinct if(b.welfare_pv>0,a.user_id,null)) as yd_welfare_newuser_num, -- 昨日公益新增用户量
        count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=1 and b.welfare_pv>0,b.user_id,null)) as lastd_welfare_retention_newuser_num, -- 次日公益留存新用户量
        count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=7 and b.welfare_pv>0,b.user_id,null)) as last7d_welfare_retention_newuser_num, -- 7日公益留存新用户量
        count(distinct if(date_diff('day',b.statistics_date,a.first_view_date)=30 and b.welfare_pv>0,b.user_id,null)) as last30d_welfare_etention_newuser_num -- 30日公益留存新用户量
from(
-- 昨日到店新增访问用户
        select  if(t1.first_explore_view_date<>'1970-01-01',t1.first_explore_view_date,t1.first_welfare_view_date) as first_view_date,
                t1.user_id,
                dim_user.platform_name,
                dim_user.city_name,
                dim_user.county_name
        from    dim_user
        inner join t1
        on      t1.user_id = dim_user.user_id
        ) a
    left join 
-- 访问用户
            (
                select  statistics_date,
                        cast(user_id as int) as user_id,
                        sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) as explore_pv,
                        sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) as welfare_pv
                from    dws.dws_sr_traffic_user_d
                where   statistics_date between '2024-08-12' and '${T-1}' -- 首次跑数据
                -- where   statistics_date between '${T-1}' and date_add('${T-1}',interval 30 day) -- 自动跑数据时，跑最近30天
                and     user_id regexp '^[0-9]{1,9}$' -- 20240823调整，限制登录用户，减少数据量 修改人：dahe
                group by 1,2
                having  (
                            sum(explore_homepage_pv + daren_homepage_pv + explore_activity_detailpage_pv) > 0
                            or      sum(welfare_homepage_pv + welfare_activity_detailpage_pv + weifare_faxinpage_pv + weifare_mypage_pv) > 0
                        )
            ) b
                on      a.user_id = b.user_id
    group by grouping sets (
                (first_view_date),
                (first_view_date, platform_name),
                (first_view_date, city_name),
                (first_view_date, platform_name, city_name, county_name)
            )
;




         















