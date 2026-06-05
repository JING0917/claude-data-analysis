--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2024-06-18 14:57:03
--******************************************************************--

-- drop table if exists `ads`.`ads_ck_order_promotion_county_d` ON CLUSTER default_cluster ;

CREATE TABLE IF NOT EXISTS `ads`.`ads_ck_order_promotion_county_d` ON CLUSTER default_cluster  (
   `statistics_date` String comment '统计日期',
   `promotion_category` String comment '活动类别',
   `city_name` String comment '城市',
   `county_name` String comment '区县',
   `store_sub_category_type` String comment '店铺标签子类型',
   `store_platform` String comment '店铺平台名称',
   `threshold_order_amt` decimal(12,2) comment '订单满返门槛金额',
   `order_rebate_maxamt` decimal(12,2) comment '订单满返最大金额',
   `meal_label` String comment '餐标',
   `rebate_condition_desc` String comment '返利条件说明',
   `youzhi_promotion` String comment '优质活动',
   `meituan_promotion_quota` int comment '美团活动名额',
   `eleme_promotion_quota` int comment '饿了么活动名额',
   `tot_promotion_quota` int comment '总活动名额',
   `vaild_order_num` int comment '有效订单量',
   `vaild_order_user_num` int comment '有效订单用户量',  
   `store_promotion_num` int comment '店铺活动数',
   `vaild_order_store_promotion_num` int comment '有有效单店铺活动数',
   `dt` String comment '写入日期'
) engine=ReplicatedReplacingMergeTree('/clickhouse/tables/{shard}/ads_ck_order_promotion_county_d','{replica}')
partition by (dt)
-- order by (statistics_date,promotion_category,city_name,county_name,store_sub_category_type,store_platform,meal_label,rebate_condition_desc,youzhi_promotion);
order by (statistics_date);



-- 店铺活动
with t1 as (
select concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) as statistics_date,
    store_id,
    store_promotion_id,
    meituan_rebate_amt,
    meituan_order_amt,
    eleme_rebate_amt,
    eleme_order_amt,
    meituan_user_rebate_point,
    eleme_user_rebate_point,
    promotion_rebate_type,
    rebate_condition_desc,
    is_youzhi_promotion,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_ck_store_promotion
WHERE concat(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) between toString(date_add(day,-30,toDate('${T-1}'))) and '${T-1}'
        AND status IN (1, 4, 5) -- 进行中+已结束+已审核
        -- and is_vip_exclusive=0 -- vip专享
        -- and is_operation_promption=0 -- 非运营创建活动
),

-- 订单
t2 as (
select
    concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) as statistics_date,
    order_id,
    user_id,
    store_promotion_id,
    county_id
from dwd.dwd_ck_silkworm_promotion_order
where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0'))='${T-1}'
    and order_status in (2,8) -- 已审核+已审核待改进
),

-- 店铺
t3 as (
select 
    store_id,
    city,
    district,
    sub_category_type
from dim.dim_silkworm_store
where status=1 -- 已审核
)

INSERT INTO `ads`.`ads_ck_order_promotion_county_d`
select
    statistics_date,
    promotion_category,
    city_name,
    county_name,
    store_sub_category_type,
    store_platform,
    threshold_order_amt,
    order_rebate_maxamt,
    meal_label,
    rebate_condition_desc,
    youzhi_promotion,
    meituan_promotion_quota,
    eleme_promotion_quota,
    tot_promotion_quota,
    vaild_order_num,
    vaild_order_user_num,
    store_promotion_num,
    vaild_order_store_promotion_num,
    '${T-1}' as dt
from 
-- 每日各城市
(select statistics_date,
    promotion_category,
    city_name,
    county_name,
    store_sub_category_type,
    store_platform,
    threshold_order_amt,
    order_rebate_maxamt,
    meal_label,
    rebate_condition_desc,
    youzhi_promotion,
    sum(meituan_promotion_quota) as meituan_promotion_quota,
    sum(eleme_promotion_quota) as eleme_promotion_quota,
    sum(tot_promotion_quota) as tot_promotion_quota,
    sum(vaild_order_num) as vaild_order_num,
    sum(vaild_order_user_num) as vaild_order_user_num,
    sum(store_promotion_num) as store_promotion_num,
    sum(vaild_order_store_promotion_num) as vaild_order_store_promotion_num
from (SELECT 
            b.statistics_date,
            '自营' as promotion_category, -- 排除运营活动&VIP专享
            c.city AS city_name,
            c.district AS county_name,
            CASE 
                WHEN c.sub_category_type = 1 THEN '包子粥铺'
                WHEN c.sub_category_type = 2 THEN '快餐简餐'
                WHEN c.sub_category_type = 3 THEN '甜品饮品'
                WHEN c.sub_category_type = 4 THEN '炸串小吃'
                WHEN c.sub_category_type = 5 THEN '火锅烧烤'
                WHEN c.sub_category_type = 6 THEN '汉堡西餐'
                WHEN c.sub_category_type = 7 THEN '零售'
                WHEN c.sub_category_type = 8 THEN '水果鲜花'
                WHEN c.sub_category_type = 9 THEN '成人用品'
            END AS store_sub_category_type,
            case when b.meituan_rebate_amt>0 and b.eleme_rebate_amt>0 then '美团|饿了么'
                 when b.meituan_rebate_amt>0 and b.eleme_rebate_amt=0 then '美团'
                 when b.meituan_rebate_amt<=0 and b.eleme_rebate_amt>0 then '饿了么'
            END AS store_platform,
            CASE 
                WHEN b.meituan_rebate_amt > 0 THEN b.meituan_order_amt
                WHEN b.eleme_rebate_amt > 0 THEN b.eleme_order_amt
            END AS threshold_order_amt,
            CASE 
                WHEN b.meituan_rebate_amt > 0 THEN b.meituan_user_rebate_point/100
                WHEN b.eleme_rebate_amt > 0 THEN b.eleme_user_rebate_point/100
            END AS order_rebate_maxamt,
            CASE 
                WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', toString(b.meituan_order_amt), '返', toString(b.meituan_user_rebate_point/100))
                WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', toString(b.meituan_user_rebate_point/100))
                WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', toString(b.eleme_order_amt), '返', toString(b.eleme_user_rebate_point/100))
                WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', toString(b.eleme_user_rebate_point/100))
            END AS meal_label,
            CASE 
                WHEN match(b.rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
                ELSE '无需反馈' 
            END AS rebate_condition_desc,
            CASE 
                WHEN b.is_youzhi_promotion = 1 THEN '优质活动'
                ELSE '非优质活动' 
            END AS youzhi_promotion,
            sum(b.meituan_promotion_quota) AS meituan_promotion_quota,
            sum(b.eleme_promotion_quota) AS eleme_promotion_quota,
            sum(b.meituan_promotion_quota) + sum(b.eleme_promotion_quota) AS tot_promotion_quota,
            0 AS vaild_order_num,
            0 AS vaild_order_user_num,
            count(b.store_promotion_id) AS store_promotion_num,
            0 AS vaild_order_store_promotion_num
FROM t1 b 
LEFT JOIN t3 c -- 店铺
    ON b.store_id = c.store_id
where b.statistics_date='${T-1}'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11

union all

-- 下单数据统计
select 
    a.statistics_date,
    '自营' as promotion_category,
    d.city_name as city_name,
    d.county_name as county_name,
    CASE 
        WHEN c.sub_category_type = 1 THEN '包子粥铺'
        WHEN c.sub_category_type = 2 THEN '快餐简餐'
        WHEN c.sub_category_type = 3 THEN '甜品饮品'
        WHEN c.sub_category_type = 4 THEN '炸串小吃'
        WHEN c.sub_category_type = 5 THEN '火锅烧烤'
        WHEN c.sub_category_type = 6 THEN '汉堡西餐'
        WHEN c.sub_category_type = 7 THEN '零售'
        WHEN c.sub_category_type = 8 THEN '水果鲜花'
        WHEN c.sub_category_type = 9 THEN '成人用品'
    END AS store_sub_category_type,
    case when b.meituan_rebate_amt>0 and b.eleme_rebate_amt>0 then '美团|饿了么'
        when b.meituan_rebate_amt>0 and b.eleme_rebate_amt=0 then '美团'
        when b.meituan_rebate_amt<=0 and b.eleme_rebate_amt>0 then '饿了么'
    END AS store_platform,
    CASE 
        WHEN b.meituan_rebate_amt > 0 THEN b.meituan_order_amt
        WHEN b.eleme_rebate_amt > 0 THEN b.eleme_order_amt
    END AS threshold_order_amt,
    CASE 
        WHEN b.meituan_rebate_amt > 0 THEN b.meituan_user_rebate_point/100
        WHEN b.eleme_rebate_amt > 0 THEN b.eleme_user_rebate_point/100
    END AS order_rebate_maxamt,
    CASE 
        WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', toString(b.meituan_order_amt), '返', toString(b.meituan_user_rebate_point/100))
        WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', toString(b.meituan_user_rebate_point/100))
        WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', toString(b.eleme_order_amt), '返', toString(b.eleme_user_rebate_point/100))
        WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', toString(b.eleme_user_rebate_point/100))
    END AS meal_label,
    CASE 
        WHEN match(b.rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
        ELSE '无需反馈' 
    END AS rebate_condition_desc,
    CASE 
        WHEN b.is_youzhi_promotion = 1 THEN '优质活动'
        ELSE '非优质活动' 
    END AS youzhi_promotion,
    0 as meituan_promotion_quota,
    0 as eleme_promotion_quota,
    0 AS tot_promotion_quota,
    count(a.order_id) as vaild_order_num,
    count(distinct a.user_id) as vaild_order_user_num,
    0 as store_promotion_num,
    count(distinct if(a.store_promotion_id is not null,b.store_promotion_id,null)) as vaild_order_store_promotion_num 
from t2 a -- 订单
inner join t1 b  -- 店铺活动
    on a.store_promotion_id=b.store_promotion_id 
left join t3 c -- 店铺
    on b.store_id=c.store_id
left join dim.dim_region_code d
    on a.county_id=d.county_id
group by 1,2,3,4,5,6,7,8,9,10,11
) tot
group by 1,2,3,4,5,6,7,8,9,10,11


union all

-- 全国
select statistics_date,
    promotion_category,
    city_name,
    county_name,
    store_sub_category_type,
    store_platform,
    threshold_order_amt,
    order_rebate_maxamt,
    meal_label,
    rebate_condition_desc,
    youzhi_promotion,
    sum(meituan_promotion_quota) as meituan_promotion_quota,
    sum(eleme_promotion_quota) as eleme_promotion_quota,
    sum(tot_promotion_quota) as tot_promotion_quota,
    sum(vaild_order_num) as vaild_order_num,
    sum(vaild_order_user_num) as vaild_order_user_num,
    sum(store_promotion_num) as store_promotion_num,
    sum(vaild_order_store_promotion_num) as vaild_order_store_promotion_num
from (SELECT 
            b.statistics_date,
            '自营' as promotion_category, -- 排除运营活动&VIP专享
            '全国' AS city_name,
            '全国' AS county_name,
            CASE 
                WHEN c.sub_category_type = 1 THEN '包子粥铺'
                WHEN c.sub_category_type = 2 THEN '快餐简餐'
                WHEN c.sub_category_type = 3 THEN '甜品饮品'
                WHEN c.sub_category_type = 4 THEN '炸串小吃'
                WHEN c.sub_category_type = 5 THEN '火锅烧烤'
                WHEN c.sub_category_type = 6 THEN '汉堡西餐'
                WHEN c.sub_category_type = 7 THEN '零售'
                WHEN c.sub_category_type = 8 THEN '水果鲜花'
                WHEN c.sub_category_type = 9 THEN '成人用品'
            END AS store_sub_category_type,
            case when b.meituan_rebate_amt>0 and b.eleme_rebate_amt>0 then '美团|饿了么'
                 when b.meituan_rebate_amt>0 and b.eleme_rebate_amt=0 then '美团'
                 when b.meituan_rebate_amt<=0 and b.eleme_rebate_amt>0 then '饿了么'
            END AS store_platform,
            CASE 
                WHEN b.meituan_rebate_amt > 0 THEN b.meituan_order_amt
                WHEN b.eleme_rebate_amt > 0 THEN b.eleme_order_amt
            END AS threshold_order_amt,
            CASE 
                WHEN b.meituan_rebate_amt > 0 THEN b.meituan_user_rebate_point/100
                WHEN b.eleme_rebate_amt > 0 THEN b.eleme_user_rebate_point/100
            END AS order_rebate_maxamt,
            CASE 
                WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', toString(b.meituan_order_amt), '返', toString(b.meituan_user_rebate_point/100))
                WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', toString(b.meituan_user_rebate_point/100))
                WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', toString(b.eleme_order_amt), '返', toString(b.eleme_user_rebate_point/100))
                WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', toString(b.eleme_user_rebate_point/100))
            END AS meal_label,
            CASE 
                WHEN match(b.rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
                ELSE '无需反馈' 
            END AS rebate_condition_desc,
            CASE 
                WHEN b.is_youzhi_promotion = 1 THEN '优质活动'
                ELSE '非优质活动' 
            END AS youzhi_promotion,
            sum(b.meituan_promotion_quota) AS meituan_promotion_quota,
            sum(b.eleme_promotion_quota) AS eleme_promotion_quota,
            sum(b.meituan_promotion_quota) + sum(b.eleme_promotion_quota) AS tot_promotion_quota,
            0 AS vaild_order_num,
            0 AS vaild_order_user_num,
            count(b.store_promotion_id) AS store_promotion_num,
            0 AS vaild_order_store_promotion_num
FROM t1 b 
LEFT JOIN t3 c -- 店铺
    ON b.store_id = c.store_id
where b.statistics_date='${T-1}'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11

union all

-- 下单数据统计
select 
    a.statistics_date,
    '自营' as promotion_category,
    '全国' as city_name,
    '全国' as county_name,
    CASE 
        WHEN c.sub_category_type = 1 THEN '包子粥铺'
        WHEN c.sub_category_type = 2 THEN '快餐简餐'
        WHEN c.sub_category_type = 3 THEN '甜品饮品'
        WHEN c.sub_category_type = 4 THEN '炸串小吃'
        WHEN c.sub_category_type = 5 THEN '火锅烧烤'
        WHEN c.sub_category_type = 6 THEN '汉堡西餐'
        WHEN c.sub_category_type = 7 THEN '零售'
        WHEN c.sub_category_type = 8 THEN '水果鲜花'
        WHEN c.sub_category_type = 9 THEN '成人用品'
    END AS store_sub_category_type,
            case when b.meituan_rebate_amt>0 and b.eleme_rebate_amt>0 then '美团|饿了么'
                 when b.meituan_rebate_amt>0 and b.eleme_rebate_amt=0 then '美团'
                 when b.meituan_rebate_amt<=0 and b.eleme_rebate_amt>0 then '饿了么'
            END AS store_platform,
    CASE 
        WHEN b.meituan_rebate_amt > 0 THEN b.meituan_order_amt
        WHEN b.eleme_rebate_amt > 0 THEN b.eleme_order_amt
    END AS threshold_order_amt,
    CASE 
        WHEN b.meituan_rebate_amt > 0 THEN b.meituan_user_rebate_point/100
        WHEN b.eleme_rebate_amt > 0 THEN b.eleme_user_rebate_point/100
    END AS order_rebate_maxamt,
    CASE 
        WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', toString(b.meituan_order_amt), '返', toString(b.meituan_user_rebate_point/100))
        WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', toString(b.meituan_user_rebate_point/100 ))
        WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', toString(b.eleme_order_amt), '返', toString(b.eleme_user_rebate_point/100))
        WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', toString(b.eleme_user_rebate_point/100))
    END AS meal_label,
    CASE 
        WHEN match(b.rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
        ELSE '无需反馈' 
    END AS rebate_condition_desc,
    CASE 
        WHEN b.is_youzhi_promotion = 1 THEN '优质活动'
        ELSE '非优质活动' 
    END AS youzhi_promotion,
    0 as meituan_promotion_quota,
    0 as eleme_promotion_quota,
    0 AS tot_promotion_quota,
    count(a.order_id) as vaild_order_num,
    count(distinct a.user_id) as vaild_order_user_num,
    0 as store_promotion_num,
    count(distinct if(a.store_promotion_id is not null,b.store_promotion_id,null)) as vaild_order_store_promotion_num 
from t2 a -- 订单
inner join t1 b  -- 店铺活动
    on a.store_promotion_id=b.store_promotion_id 
left join t3 c -- 店铺
    on b.store_id=c.store_id
group by 1,2,3,4,5,6,7,8,9,10,11
) tot
group by 1,2,3,4,5,6,7,8,9,10,11
) toc


=========================
select
    b.city_name as `城市`,
    b.county_name as `区县`,
    store_id as `店铺ID`,
    store_name as `店铺名称`,
    store_banner_list as `品牌名称`,
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
    END AS `品类`,
    merchant_id as `商家ID`,
    case when meituan_rebate_amt>0 and eleme_rebate_amt>0 then '美团|饿了么'
        when meituan_rebate_amt>0 and eleme_rebate_amt=0 then '美团'
        when meituan_rebate_amt<=0 and eleme_rebate_amt>0 then '饿了么'
    END AS `活动平台`,
    CASE 
        WHEN promotion_rebate_type = 0 AND meituan_rebate_amt > 0 THEN concat('满', toString(meituan_order_amt), '返', toString(meituan_user_rebate_point/100))
        WHEN promotion_rebate_type = 1 AND meituan_rebate_amt > 0 THEN concat('最高返', toString(meituan_user_rebate_point/100))
        WHEN promotion_rebate_type = 0 AND eleme_rebate_amt > 0 THEN concat('满', toString(eleme_order_amt), '返', toString(eleme_user_rebate_point/100))
        WHEN promotion_rebate_type = 1 AND eleme_rebate_amt > 0 THEN concat('最高返', toString(eleme_user_rebate_point/100))
    END AS `优惠条件`,
    CASE 
        WHEN match(rebate_condition_desc,'用餐反馈') THEN '用餐反馈'
        ELSE '无需反馈' 
    END AS `积分返回条件`,
    concat(toString(daily_begin_hour),':00','-',toString(daily_end_hour),':00') as `活动时间段`,
    bd_id,
    sum(meituan_promotion_quota+eleme_promotion_quota) as `活动名额`,
    sum(cancel_order_num) as `取消订单量`,
    sum(valid_order_num) as `有效订单量`
from dwd.dwd_ck_silkworm_store_promotion_merge_h a
left join dim.dim_region_code b
    on a.county_id=b.county_id 
where toDate(begin_date)>=$begin_date$
    and toDate(end_date)<=$end_date$
group by 1,2,3,4,5,6,7,8,9,10,11,12

































