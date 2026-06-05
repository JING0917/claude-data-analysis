-- part1 探店
with com_info as (
select
    community_name,
    community_id
from dim.dim_wework_community
where community_name regexp '探店'
group by 1,2
),

-- 企微群用户
com_user_info as (
select
    user_id
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1
),

-- 是否加探店群
t1 as (select 
  a.user_id,
  if(c.promotion_type in ('101','111') and d.user_id is not null,'已进探店群','未进探店群') as is_explore_community -- 20250120 promotion_type做十进制到二进制转换 修改人：dahe
from dim.dim_silkworm_user a
INNER join dim.dim_silkworm_user_location b
    on a.user_id=b.user_id
        and date(b.update_time) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day) -- 近30天有活跃
    -- 探店城市是已开通城市
    inner join
        (select
            city_name,
            promotion_type
        from dim.dim_silkworm_explore_city
        where province_name<>'新疆维吾尔族自治区' -- 剔除测试省份
                and status=1 -- 正常
            group by 1,2
        ) c
    on b.city=c.city_name
        left join com_user_info d on a.user_id=d.user_id
group by 1,2
)

-- 统计 未进：1269705 已进：13107
select is_explore_community,count(1) cnt from t1 group by 1;


-- part 2 砍价
with com_info as (
select
    community_name,
    community_id
from dim.dim_wework_community
where community_name regexp '砍价'
group by 1,2
),

-- 企微群用户
com_user_info as (
select
    user_id
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1
),

-- 是否加探店群
t1 as (select 
  a.user_id,
  if(c.promotion_type in ('101','111') and d.user_id is not null,'已进砍价群','未进砍价群') as is_explore_community -- 20250120 promotion_type做十进制到二进制转换 修改人：dahe
from dim.dim_silkworm_user a
INNER join dim.dim_silkworm_user_location b
    on a.user_id=b.user_id
        and date(b.update_time) between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day) -- 近30天有活跃
    -- 探店城市是已开通城市
    inner join
        (select
            city_name,
            promotion_type
        from dim.dim_silkworm_explore_city
        where province_name<>'新疆维吾尔族自治区' -- 剔除测试省份
                and status=1 -- 正常
            group by 1,2
        ) c
    on b.city=c.city_name
        left join com_user_info d on a.user_id=d.user_id
group by 1,2
)

-- 统计 未进：1277823 已进：4989
select is_explore_community,count(1) cnt from t1 group by 1;





