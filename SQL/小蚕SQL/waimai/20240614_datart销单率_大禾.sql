-- 每日各城市
select `下单日期`,
    `城市`,
    `区县`,
    `店铺类别`,
    `平台名称`,
    `餐标`,
    `用餐反馈`,
    `是否优质活动`,
    sum(`美团活动名额`) as `美团活动名额`,
    sum(`饿了么活动名额`) as `饿了么活动名额`,
    sum(`活动名额`) as `活动名额`,
    sum(`有效订单量`) as `有效订单量`,
    sum(`有效订单用户量`) as `有效订单用户量`,
    sum(`店铺活动数`) as `店铺活动数`,
    sum(`有有效单店铺活动数`) as `有有效单店铺活动数`



=========================== 第二版
CREATE TABLE IF NOT EXISTS `dws`.`dws_hive_order_promotion_d_county` (
   `statistics_date` string comment '统计日期',
   `promotion_category` string comment '活动类别',
   `city_name` string comment '城市',
   `county_name` string comment '区县',
   `store_sub_category_type` string comment '店铺标签子类型',
   `store_platform` string comment '店铺平台名称',
   `threshold_order_amt` int comment '订单满返门槛金额',
   `order_rebate_maxamt` int comment '订单满返最大金额',
   `meal_label` string comment '餐标',
   `rebate_condition_desc` string comment '返利条件说明',
   `youzhi_promotion` string comment '优质活动',
   `meituan_promotion_quota` int comment '美团活动名额',
   `eleme_promotion_quota` int comment '饿了么活动名额',
   `tot_promotion_quota` int comment '总活动名额',
   `vaild_order_num` int comment '有效订单量',
   `vaild_order_user_num` int comment '有效订单用户量',  
   `store_promotion_num` int comment '店铺活动数',
   `vaild_order_store_promotion_num` int comment '有有效单店铺活动数'
)
partitioned by (dt string)
STORED AS PARQUET;



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
from dwd.dwd_hive_store_promotion
WHERE concat(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) between date_sub('2024-06-16',30) and '2024-06-16'
        AND status IN (1, 4, 5)
        and is_vip_exclusive=0
        and is_operation_promption=0
),

-- 订单
t2 as (
select
    concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) as statistics_date,
    order_id,
    user_id,
    store_promotion_id,
    county_id
from dwd.dwd_hive_silkworm_promotion_order
where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0'))='2024-06-16'
    and order_status in (2,8)
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


INSERT overwrite TABLE `dws`.`dws_hive_order_promotion_d_county` partition(dt='${T-1}')

-- 每日各城市
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
            CASE 
                WHEN b.meituan_rebate_amt > 0 THEN '美团'
                ELSE '饿了么' 
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
                WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', cast(b.meituan_order_amt as string), '返', cast(b.meituan_user_rebate_point/100 as string))
                WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', cast(b.meituan_user_rebate_point/100 as string))
                WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', cast(b.eleme_order_amt as string), '返', cast(b.eleme_user_rebate_point/100 as string))
                WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', cast(b.eleme_user_rebate_point/100 as string))
            END AS meal_label,
            CASE 
                WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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
where b.statistics_date='2024-06-16'
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
    CASE 
        WHEN b.meituan_rebate_amt > 0 THEN '美团'
        ELSE '饿了么' 
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
        WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', cast(b.meituan_order_amt as string), '返', cast(b.meituan_user_rebate_point/100 as string))
        WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', cast(b.meituan_user_rebate_point/100 as string))
        WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', cast(b.eleme_order_amt as string), '返', cast(b.eleme_user_rebate_point/100 as string))
        WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', cast(b.eleme_user_rebate_point/100 as string))
    END AS meal_label,
    CASE 
        WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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
left join dim.dim_hive_region_code d
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
            CASE 
                WHEN b.meituan_rebate_amt > 0 THEN '美团'
                ELSE '饿了么' 
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
                WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', cast(b.meituan_order_amt as string), '返', cast(b.meituan_user_rebate_point/100 as string))
                WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', cast(b.meituan_user_rebate_point/100 as string))
                WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', cast(b.eleme_order_amt as string), '返', cast(b.eleme_user_rebate_point/100 as string))
                WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', cast(b.eleme_user_rebate_point/100 as string))
            END AS meal_label,
            CASE 
                WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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
where b.statistics_date='2024-06-16'
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
    CASE 
        WHEN b.meituan_rebate_amt > 0 THEN '美团'
        ELSE '饿了么' 
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
        WHEN b.promotion_rebate_type = 0 AND b.meituan_rebate_amt > 0 THEN concat('满', cast(b.meituan_order_amt as string), '返', cast(b.meituan_user_rebate_point/100 as string))
        WHEN b.promotion_rebate_type = 1 AND b.meituan_rebate_amt > 0 THEN concat('最高返', cast(b.meituan_user_rebate_point/100 as string))
        WHEN b.promotion_rebate_type = 0 AND b.eleme_rebate_amt > 0 THEN concat('满', cast(b.eleme_order_amt as string), '返', cast(b.eleme_user_rebate_point/100 as string))
        WHEN b.promotion_rebate_type = 1 AND b.eleme_rebate_amt > 0 THEN concat('最高返', cast(b.eleme_user_rebate_point/100 as string))
    END AS meal_label,
    CASE 
        WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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




statistics_date as `统计日期`,
city_name `城市`,
county_name `区县`,
store_sub_category_type `店铺标签子类型`,
store_platform `店铺平台名称`,
threshold_order_amt `订单满返门槛金额`,
order_rebate_maxamt `订单满返最大金额`,
meal_label `餐标`,
rebate_condition_desc `返利条件说明`,
youzhi_promotion `优质活动`,
meituan_promotion_quota `美团活动名额`,
eleme_promotion_quota `饿了么活动名额`,
tot_promotion_quota `总活动名额`,
vaild_order_num `有效订单量`,
vaild_order_user_num `有效订单用户量`,  
store_promotion_num `店铺活动数`,
vaild_order_store_promotion_num `有有效单店铺活动数`
from dws.dws_ck_order_promotion_d_county
where dt between 
    and promotion_category='自营'


dt='${T-1}'



-- 销单率同环比
select
    t1.`统计日期`,
    t1.`城市`,
    t1.`总活动名额`,
    t1.`有效订单量`,
    t1.`总活动名额`/t2.`昨日总活动名额`-1 as `活动名额环比变化率`,
    t1.`有效订单量`/t2.`昨日有效订单量`-1 as `有效订单量环比变化率`,
    t1.`总活动名额`/t3.`去年同日总活动名额`-1 as `活动名额同比变化率`,
    t1.`有效订单量`/t3.`去年同日有效订单量`-1 as `有效订单量同比变化率`
-- 昨日
from (select 
            toDate(statistics_date) `统计日期`,
            city_name `城市`,
            sum(tot_promotion_quota) `总活动名额`,
            sum(vaild_order_num) `有效订单量`
        from dws.dws_ck_order_promotion_d_county
        where toDate(dt) between $END_DATE$ and $END_DATE$
            and promotion_category='自营'
            and length(city_name)>1
        group by 1,2
    ) t1
left join
    -- 前日
    (select 
        toDate(statistics_date) `统计日期`,
        city_name `城市`,
        sum(tot_promotion_quota) `昨日总活动名额`,
        sum(vaild_order_num) `昨日有效订单量`
    from dws.dws_ck_order_promotion_d_county
    where toDate(dt) between date_add(day,-1,$END_DATE$) and date_add(day,-1,$END_DATE$)
        and promotion_category='自营'
        and length(city_name)>1
    group by 1,2
    ) t2
on t1.`统计日期`=date_add(day,1,t2.`统计日期`)
        and t1.`城市`=t2.`城市`
left join
    -- 去年同期
    (select 
        toDate(statistics_date) `统计日期`,
        city_name `城市`,
        sum(tot_promotion_quota) `去年同日总活动名额`,
        sum(vaild_order_num) `去年同日有效订单量`
    from dws.dws_ck_order_promotion_d_county
    where toDate(dt) between date_add(year,-1,$END_DATE$) and date_add(year,-1,$END_DATE$)
        and promotion_category='自营'
        and length(city_name)>1
    group by 1,2
    ) t3
on t1.`统计日期`=date_add(year,1,t3.`统计日期`)
        and t1.`城市`=t3.`城市`





    -- t1.`有效订单量`/t1.`总活动名额` as `销单率`,
    -- t1.`总活动名额`/t2.`昨日总活动名额`-1 as `活动名额环比变化率`,
    -- t1.`有效订单量`/t2.`昨日有效订单量`-1 as `有效订单量环比变化率`,
    -- t1.`总活动名额`/t3.`去年同日总活动名额`-1 as `活动名额同比变化率`,
    -- t1.`有效订单量`/t3.`去年同日有效订单量`-1 as `有效订单量同比变化率`,
    -- coalesce(coalesce(t1.`有效订单量`,0)-coalesce(t2.`昨日有效订单量`,0),0)/coalesce(coalesce(t1.`总活动名额`,0)-coalesce(t2.`昨日总活动名额`,0),0)-1 as `销单率环比变化率`,
    -- coalesce(coalesce(t1.`有效订单量`,0)-coalesce(t3.`去年同日有效订单量`,0),0)/coalesce(coalesce(t1.`总活动名额`,0)-coalesce(t3.`去年同日总活动名额`,0),0)-1 as `销单率同比变化率`




select
    a.`统计日期`,
    a.`城市`,
    a.`餐标`,
    a.`活动名额`,
    a.`有效订单量`,
    a.`销单率`,
    b.`总活动名额`,
    b.`总有效订单量`,
    b.`平均销单率`,
    a.`活动名额`/b.`总活动名额` as `活动名额占比`,
    a.`有效订单量`/b.`总有效订单量` as `有效订单占比`
from (select 
            toDate(statistics_date) `统计日期`,
            city_name `城市`,
            replace(replace(meal_label,'.00',''),'.0','') as `餐标`,
            sum(tot_promotion_quota) as `活动名额`,
            sum(vaild_order_num) as `有效订单量`,
            IF(`活动名额`= 0, 0,`有效订单量`/`活动名额`) AS `销单率`  
            -- if(sum(tot_promotion_quota)=0,0,sum(vaild_order_num)/sum(tot_promotion_quota)) as `销单率`
    from dws.dws_ck_order_promotion_d_county
        where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
            and promotion_category='自营'
            and length(city_name)>1
    group by 1,2,3
    ) a

left join
-- 城市整体
    (select 
            toDate(statistics_date) `统计日期`,
            city_name `城市`,
            sum(tot_promotion_quota) as `总活动名额`,
            sum(vaild_order_num) as `总有效订单量`,
            IF(`总活动名额`= 0, 0,`总有效订单量`/`总活动名额`) AS `平均销单率`  
    from dws.dws_ck_order_promotion_d_county
    where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
        and promotion_category='自营'
        and length(city_name)>1
    group by 1,2) b
on a.`统计日期`=b.`统计日期`
    and a.`城市`=b.`城市`


select
    b.province_name,
    a.*
from (select 
    toDate(statistics_date) `统计日期`,
    city_name `城市`,
    county_name `区县`,
    store_sub_category_type `店铺标签子类型`,
    store_platform `店铺平台名称`,
    threshold_order_amt `订单满返门槛金额`,
    order_rebate_maxamt `订单满返最大金额`,
    meal_label `餐标`,
    rebate_condition_desc `返利条件说明`,
    youzhi_promotion `优质活动`,
    meituan_promotion_quota `美团活动名额`,
    eleme_promotion_quota `饿了么活动名额`,
    tot_promotion_quota `总活动名额`,
    vaild_order_num `有效订单量`,
    vaild_order_user_num `有效订单用户量`,  
    store_promotion_num `店铺活动数`,
    vaild_order_store_promotion_num `有有效单店铺活动数`
from dws.dws_ck_order_promotion_d_county
where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
    and promotion_category='自营'
    and length(city_name)>1
    and city_name<>'全国'
    and `总活动名额`>0
) a
left join dim.dim_region_code b
on a.county_name=b.county_name





=============== ck数据表

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
        AND status IN (1, 4, 5)
        and is_vip_exclusive=0 -- vip专享
        and is_operation_promption=0 -- 运营创建活动
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
    and order_status in (2,8)
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

INSERT overwrite TABLE `ads`.`ads_ck_order_promotion_county_d` partition(dt='${T-1}')

-- 每日各城市
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
                WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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
        WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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
                WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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
        WHEN b.rebate_condition_desc regexp '用餐反馈' THEN '用餐反馈'
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








