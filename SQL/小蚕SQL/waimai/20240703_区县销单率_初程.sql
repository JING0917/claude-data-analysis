-- 自营日活动
with t1 (
select
    substr(begin_date,1,10) as dat,
    c.city_name,
    c.county_name,
    CASE 
        WHEN b.sub_category_type = 1 THEN '包子粥铺'
        WHEN b.sub_category_type = 2 THEN '快餐简餐'
        WHEN b.sub_category_type = 3 THEN '甜品饮品'
        WHEN b.sub_category_type = 4 THEN '炸串小吃'
        WHEN b.sub_category_type = 5 THEN '火锅烧烤'
        WHEN b.sub_category_type = 6 THEN '汉堡西餐'
        WHEN b.sub_category_type = 7 THEN '零售'
        WHEN b.sub_category_type = 8 THEN '水果鲜花'
        WHEN b.sub_category_type = 9 THEN '成人用品'
    END AS store_sub_category_type,
    CASE 
        WHEN a.promotion_rebate_type = 0 AND a.meituan_rebate_amt > 0 THEN concat('满', cast(a.meituan_order_amt as string), '返', cast(a.meituan_user_rebate_point/100 as string))
        WHEN a.promotion_rebate_type = 1 AND a.meituan_rebate_amt > 0 THEN concat('最高返', cast(a.meituan_user_rebate_point/100 as string))
        WHEN a.promotion_rebate_type = 0 AND a.eleme_rebate_amt > 0 THEN concat('满', cast(a.eleme_order_amt as string), '返', cast(a.eleme_user_rebate_point/100 as string))
        WHEN a.promotion_rebate_type = 1 AND a.eleme_rebate_amt > 0 THEN concat('最高返', cast(a.eleme_user_rebate_point/100 as string))
    END AS meal_label,
    store_promotion_id,
    a.meituan_promotion_quota+a.eleme_promotion_quota as promotion_quota
from dwd.dwd_hive_store_promotion a
left join dim.dim_silkworm_store b
    on a.store_id=b.store_id
left join dim.dim_hive_region_code c
    on a.county_id=c.county_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-01-01' and '2024-06-30'
        and to_date(a.begin_date) between '2024-06-01' and '2024-06-30'
        and a.status in (1, 4, 5)
        and a.is_vip_exclusive=0 -- vip专享
        and a.is_operation_promption=0 -- 运营创建活动
),

-- 分时段自营有效单
t2 as (
select
    section_time,
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    avg(acc_vaild_order_num) as avg_acc_vaild_order_num
from 
(
-- 日有效单
select
    dat,
    section_time,
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    sum(vaild_order_num) over(partition by dat,city_name,county_name,store_sub_category_type,meal_label order by section_time) as acc_vaild_order_num
from (select
            a.dat,
            a.section_time,
            b.city_name,
            b.county_name,
            t1.store_sub_category_type,
            t1.meal_label,
            sum(a.vaild_order_num) as vaild_order_num
from (select 
            concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) as dat,
            substr(order_time,12,2) as section_time,
            store_promotion_id,
            county_id,
            count(order_id) as vaild_order_num
    from dwd.dwd_hive_silkworm_promotion_order
    where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-06-01' and '2024-06-30'
        and order_status in (2,8)
        and store_promotion_id>0
    group by 1,2,3,4
    ) a
    inner join t1 
        on a.store_promotion_id=t1.store_promotion_id
    left join dim.dim_hive_region_code b
        on a.county_id=b.county_id
    group by 1,2,3,4,5,6
    ) c
) toa
group by 1,2,3,4,5
),


-- 分日自营活动名额
t3 as (
select
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    avg(day_quota) as avg_day_quota
from (select
            dat,
            city_name,
            county_name,
            store_sub_category_type,
            meal_label,
            sum(promotion_quota) as day_quota
        from t1
    group by 1,2,3,4,5
    ) a
group by 1,2,3,4
)



select
    t2.city_name,
    t2.county_name,
    t2.store_sub_category_type,
    t2.meal_label,
    t2.section_time,
    t2.avg_acc_vaild_order_num,
    t3.avg_day_quota
from t2
left join t3
    on t2.city_name=t3.city_name
        and t2.county_name=t3.county_name
        and t2.store_sub_category_type=t3.store_sub_category_type
        and t2.meal_label=t3.meal_label




-- 活动曝光量和曝光UV
with t1 as (
select
    a.statistics_date,
    c.city_name,
    c.county_name,
    b.store_sub_category_type,
    b.meal_label,
    count(distinct user_id) as bg_uv,
    sum(search_expose_num+homepage_takeaway_activity_expose) as bg_cnt
from (select
            statistics_date,
            county_id,
            user_id,
            activity_id,
            search_expose_num,
            homepage_takeaway_activity_expose
        from dws.dws_hive_traffic_user_d
        where statistics_date between '2024-06-01' and '2024-06-30'
            and activity_id regexp '^[0-9]{1,8}$'
            and (user_id regexp '^[0-9]{1,7}$' 
                or user_id regexp '^[0-9]{1,8}$' 
                or user_id regexp '^[0-9]{1,9}$')
            and (search_expose_num>0 
                or homepage_takeaway_activity_expose>0)
    ) a
left join 
-- 自营活动
        (select
            cast(a.store_promotion_id as string) as store_promotion_id,
            CASE 
                WHEN b.sub_category_type = 1 THEN '包子粥铺'
                WHEN b.sub_category_type = 2 THEN '快餐简餐'
                WHEN b.sub_category_type = 3 THEN '甜品饮品'
                WHEN b.sub_category_type = 4 THEN '炸串小吃'
                WHEN b.sub_category_type = 5 THEN '火锅烧烤'
                WHEN b.sub_category_type = 6 THEN '汉堡西餐'
                WHEN b.sub_category_type = 7 THEN '零售'
                WHEN b.sub_category_type = 8 THEN '水果鲜花'
                WHEN b.sub_category_type = 9 THEN '成人用品'
            END AS store_sub_category_type,
            CASE 
                WHEN a.promotion_rebate_type = 0 AND a.meituan_rebate_amt > 0 THEN concat('满', cast(a.meituan_order_amt as string), '返', cast(a.meituan_user_rebate_point/100 as string))
                WHEN a.promotion_rebate_type = 1 AND a.meituan_rebate_amt > 0 THEN concat('最高返', cast(a.meituan_user_rebate_point/100 as string))
                WHEN a.promotion_rebate_type = 0 AND a.eleme_rebate_amt > 0 THEN concat('满', cast(a.eleme_order_amt as string), '返', cast(a.eleme_user_rebate_point/100 as string))
                WHEN a.promotion_rebate_type = 1 AND a.eleme_rebate_amt > 0 THEN concat('最高返', cast(a.eleme_user_rebate_point/100 as string))
            END AS meal_label
        from dwd.dwd_hive_store_promotion a
        left join dim.dim_silkworm_store b
            on a.store_id=b.store_id
        where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-01-01' and '2024-06-30'
                and to_date(a.begin_date) between '2024-06-01' and '2024-06-30'
                and a.status in (1, 4, 5)
                and a.is_vip_exclusive=0 -- vip专享
                and a.is_operation_promption=0 -- 运营创建活动
        ) b
    on a.activity_id=b.store_promotion_id
left join dim.dim_hive_region_code c
    on cast(a.county_id as int)=c.county_id
group by 1,2,3,4,5
)


-- 日均
select
    city_name,
    county_name,
    store_sub_category_type,
    meal_label,
    avg(bg_uv) as avg_bg_uv,
    avg(bg_cnt) as avg_bg_cnt
from t1
where city_name in ('上海市')
group by 1,2,3,4

