with t1 as (
select
    store_id,
    store_name,
    store_banner_list,
    merchant_id,
    store_platform,
    meal_label,
    rebate_condition_desc,
    time_duration,
    county_id,
    bd_id,
    sum(promotion_quota) as promotion_quota,
    0 as cancel_order_num,
    0 as valid_order_num
from (
    select
        begin_date,
        end_date,
        store_id,
        store_name,
        store_banner_list,
        merchant_id,
        case when meituan_rebate_amt>0 and eleme_rebate_amt>0 then '美团|饿了么'
            when meituan_rebate_amt>0 and eleme_rebate_amt=0 then '美团'
            when meituan_rebate_amt<=0 and eleme_rebate_amt>0 then '饿了么'
        END AS store_platform,
        CASE 
            WHEN promotion_rebate_type = 0 AND meituan_rebate_amt > 0 THEN concat('满', toString(meituan_order_amt), '返', toString(meituan_user_rebate_point/100))
            WHEN promotion_rebate_type = 1 AND meituan_rebate_amt > 0 THEN concat('最高返', toString(meituan_user_rebate_point/100))
            WHEN promotion_rebate_type = 0 AND eleme_rebate_amt > 0 THEN concat('满', toString(eleme_order_amt), '返', toString(eleme_user_rebate_point/100))
            WHEN promotion_rebate_type = 1 AND eleme_rebate_amt > 0 THEN concat('最高返', toString(eleme_user_rebate_point/100))
        END AS meal_label,
        CASE 
            WHEN match(rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
            ELSE '无需反馈' 
        END AS rebate_condition_desc,
        concat(toString(daily_begin_hour),':00','-',toString(daily_end_hour),':00') as time_duration,
        county_id,
        bd_id,
        CASE 
            WHEN sub_category_type = 1 THEN '包子粥铺'
            WHEN sub_category_type = 2 THEN '快餐简餐'
            WHEN sub_category_type = 3 THEN '甜品饮品'
            WHEN sub_category_type = 4 THEN '炸串小吃'
            WHEN sub_category_type = 5 THEN '火锅烧烤'
            WHEN sub_category_type = 6 THEN '汉堡西餐'
            WHEN sub_category_type = 7 THEN '零售'
            WHEN sub_category_type = 8 THEN '水果鲜花'
            WHEN sub_category_type = 9 THEN '成人用品'
        END AS store_sub_category_type,
        sum(meituan_promotion_quota+eleme_promotion_quota) as promotion_quota
    from dwd.dwd_ck_silkworm_store_promotion_merge_h
    where toDate(create_time)=toDate(end_date) -- 当日活动
        and toDate(begin_date)>=$begin_date$
        and toDate(end_date)<=$end_date$
    group by 1,2,3,4,5,6,7,8,9,10,11,12

    union all

    select
        begin_date,
        end_date,
        store_id,
        store_name,
        store_banner_list,
        merchant_id,
        case when meituan_rebate_amt>0 and eleme_rebate_amt>0 then '美团|饿了么'
            when meituan_rebate_amt>0 and eleme_rebate_amt=0 then '美团'
            when meituan_rebate_amt<=0 and eleme_rebate_amt>0 then '饿了么'
        END AS store_platform,
        CASE 
            WHEN promotion_rebate_type = 0 AND meituan_rebate_amt > 0 THEN concat('满', toString(meituan_order_amt), '返', toString(meituan_user_rebate_point/100))
            WHEN promotion_rebate_type = 1 AND meituan_rebate_amt > 0 THEN concat('最高返', toString(meituan_user_rebate_point/100))
            WHEN promotion_rebate_type = 0 AND eleme_rebate_amt > 0 THEN concat('满', toString(eleme_order_amt), '返', toString(eleme_user_rebate_point/100))
            WHEN promotion_rebate_type = 1 AND eleme_rebate_amt > 0 THEN concat('最高返', toString(eleme_user_rebate_point/100))
        END AS meal_label,
        CASE 
            WHEN match(rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
            ELSE '无需反馈' 
        END AS rebate_condition_desc,
        concat(toString(daily_begin_hour),':00','-',toString(daily_end_hour),':00') as time_duration,
        county_id,
        bd_id,
        sum(meituan_promotion_quota+eleme_promotion_quota) as promotion_quota
    from dwd.dwd_ck_silkworm_store_promotion_merge_h
    where toDate(create_time)<>toDate(end_date) -- 跨天活动
        and toDate(begin_date)>=$begin_date$
        and toDate(end_date)<=$end_date$
    group by 1,2,3,4,5,6,7,8,9,10,11,12
    ) a
group by 1,2,3,4,5,6,7,8,9,10
),


-- 验证数据（无问题）
-- select * from t1 where store_id=309171

-- 日订单量
t2 as (
select
    store_id,
    store_name,
    store_banner_list,
    merchant_id,
    case when meituan_rebate_amt>0 and eleme_rebate_amt>0 then '美团|饿了么'
        when meituan_rebate_amt>0 and eleme_rebate_amt=0 then '美团'
        when meituan_rebate_amt<=0 and eleme_rebate_amt>0 then '饿了么'
    END AS store_platform,
    CASE 
        WHEN promotion_rebate_type = 0 AND meituan_rebate_amt > 0 THEN concat('满', toString(meituan_order_amt), '返', toString(meituan_user_rebate_point/100))
        WHEN promotion_rebate_type = 1 AND meituan_rebate_amt > 0 THEN concat('最高返', toString(meituan_user_rebate_point/100))
        WHEN promotion_rebate_type = 0 AND eleme_rebate_amt > 0 THEN concat('满', toString(eleme_order_amt), '返', toString(eleme_user_rebate_point/100))
        WHEN promotion_rebate_type = 1 AND eleme_rebate_amt > 0 THEN concat('最高返', toString(eleme_user_rebate_point/100))
    END AS meal_label,
    CASE 
        WHEN match(rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
        ELSE '无需反馈' 
    END AS rebate_condition_desc,
    concat(toString(daily_begin_hour),':00','-',toString(daily_end_hour),':00') as time_duration,
    county_id,
    bd_id,
    0 as promotion_quota,
    sum(cancel_order_num) as cancel_order_num,
    sum(valid_order_num) as valid_order_num
from dwd.dwd_ck_silkworm_store_promotion_merge_h
where toDate(begin_date)>=$begin_date$
    and toDate(end_date)<=$end_date$
group by 1,2,3,4,5,6,7,8,9,10
)

-- -- 店铺日活动名额和订单量
select
*
from (select
    b.city_name as `城市`,
    b.county_name as `区县`,
    store_id as `店铺ID`,
    store_name as `店铺名称`,
    store_banner_list as `品牌名称`,
    merchant_id as `商家ID`,
    store_platform as `活动平台`,
    meal_label as `优惠条件`,
    rebate_condition_desc as `积分返回条件`,
    time_duration as `活动时间段`,
    bd_id,
    sum(promotion_quota) as `活动名额`,
    sum(cancel_order_num) as `取消订单量`,
    sum(valid_order_num) as `有效订单量`
from (
    select * from t1

    union all

    select * from t2
    ) a
left join dim.dim_region_code b
    on a.county_id=b.county_id 
group by 1,2,3,4,5,6,7,8,9,10,11
) a
where `城市`='杭州市'
and `品牌名称` like '%奈雪%'