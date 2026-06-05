select 
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
    and `总活动名额`>0


===============================
-- part1 城市活动和订单明细


-- 店铺活动
with t1 as (
select
    a.begin_date,
    store_promotion_id, -- 店铺活动ID
    a.store_id, -- 店铺ID
    b.city_name,
    b.district_name,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type, -- 店铺一级分类
    sub_category_type, -- 店铺二级分类
    store_brand_type, -- 品牌类别
    delivery_type, -- 配送类型
    meituan_order_amt, -- 美团满返门槛
    meituan_mlabel_rebate_amt, -- 美团返现金额
    eleme_order_amt, -- 饿了么满返门槛
    eleme_mlabel_rebate_amt, -- 饿了么返现金额
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    store_platform, -- 店铺平台名称
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from (
select 
    begin_date,
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
        when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
        when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
    END AS store_platform,
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between date_sub(current_date(),interval 50 day) and date_sub(current_date(),interval 1 day)
                and str_to_date(begin_date,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    replace(city_name,'市','') as city_name,
    district_name,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 0 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 0 day) and date_sub(current_date(),interval 0 day)
    and store_promotion_id>0
group by 1
)



select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    city_name as `城市`,
    district_name as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10

===============================

-- part2 词云
select
`城市`,
`餐标`,
avg(`总活动名额`) as `日均活动名额`,
avg(`有效订单量`) as `日均有效订单量`
from (select 
            toDate(statistics_date) `统计日期`,
            city_name `城市`,
            replace(replace(meal_label,'.00',''),'.0','') as `餐标`,
            sum(tot_promotion_quota) as `总活动名额`,
            sum(vaild_order_num) as `有效订单量`
    from dws.dws_ck_order_promotion_d_county
    where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
            and promotion_category='自营'
            and length(city_name)>1
    group by 1,2,3
) a
where a.`总活动名额`>0
group by `城市`,`餐标`


===============================
-- 店铺活动
with t1 as (
select
    a.begin_date,
    store_promotion_id, -- 店铺活动ID
    a.store_id, -- 店铺ID
    b.city_name,
    b.district_name,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type, -- 店铺一级分类
    sub_category_type, -- 店铺二级分类
    store_brand_type, -- 品牌类别
    delivery_type, -- 配送类型
    meituan_order_amt, -- 美团满返门槛
    meituan_mlabel_rebate_amt, -- 美团返现金额
    eleme_order_amt, -- 饿了么满返门槛
    eleme_mlabel_rebate_amt, -- 饿了么返现金额
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    store_platform, -- 店铺平台名称
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from (
select 
    begin_date,
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
        when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
        when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
    END AS store_platform,
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between date_sub($END_DATE$,interval 20 day) and $END_DATE$
                and str_to_date(begin_date,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    replace(city_name,'市','') as city_name,
    district_name,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where dt between date_sub($END_DATE$,interval 7 day) and $END_DATE$
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
    and store_promotion_id>0
group by 1
)


-- 城市日均
    `城市`,
    `餐标`,
    avg(`总活动名额`) as `日均活动名额`,
    avg(`有效订单量`) as `日均有效订单量`
from
    (select
        t1.begin_date as `统计日期`,
        city_name as `城市`,
        mlabel as `餐标`,
        sum(promotion_quota) as `总活动名额`,
        sum(valid_order_num) as `有效订单量`
    from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
    where length(city_name)>1
    group by 1,2,3
    ) a
where a.`总活动名额`>0
group by `城市`,`餐标`

========================


-- part3 城市活动和订单_餐标

select
--    a.`统计日期`,
    a.`城市`,
    a.`餐标`,
    a.`活动名额`,
    a.`有效订单量`,
    a.`销单率`,
    b.`总活动名额` as `总活动名额`,
    b.`总有效订单量` as `总有效订单量`,
    b.`平均销单率` as `平均销单率`,
    a.`活动名额`/b.`总活动名额` as `活动名额占比`,
    a.`有效订单量`/b.`总有效订单量` as `有效订单占比`
from (select 
--            toDate(statistics_date) `统计日期`,
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
    group by 1,2
    having `活动名额`>0
    ) a

left join
-- 城市整体
    (select 
--            toDate(statistics_date) `统计日期`,
            city_name `城市`,
            sum(tot_promotion_quota) as `总活动名额`,
            sum(vaild_order_num) as `总有效订单量`,
            IF(`总活动名额`= 0, 0,`总有效订单量`/`总活动名额`) AS `平均销单率`  
    from dws.dws_ck_order_promotion_d_county
    where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
        and promotion_category='自营'
        and length(city_name)>1
    group by 1
    having `总活动名额`>0) b
on -- a.`统计日期`=b.`统计日期`
--    and 
    a.`城市`=b.`城市`


========================
-- 店铺活动
with t1 as (
select
    a.begin_date,
    store_promotion_id, -- 店铺活动ID
    a.store_id, -- 店铺ID
    b.city_name,
    b.district_name,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type, -- 店铺一级分类
    sub_category_type, -- 店铺二级分类
    store_brand_type, -- 品牌类别
    delivery_type, -- 配送类型
    meituan_order_amt, -- 美团满返门槛
    meituan_mlabel_rebate_amt, -- 美团返现金额
    eleme_order_amt, -- 饿了么满返门槛
    eleme_mlabel_rebate_amt, -- 饿了么返现金额
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    store_platform, -- 店铺平台名称
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from (
select 
    begin_date,
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
        when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
        when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
    END AS store_platform,
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between date_sub($END_DATE$,interval 20 day) and $END_DATE$
                and str_to_date(begin_date,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    replace(city_name,'市','') as city_name,
    district_name,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where dt between date_sub($END_DATE$,interval 7 day) and $END_DATE$
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
    and store_promotion_id>0
group by 1
),

-- 日汇总
t3 as (
select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    city_name as `城市`,
    district_name as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10
)



select
    a.`城市`,
    a.`餐标`,
    a.`活动名额`,
    a.`有效订单量`,
    a.`销单率`,
    b.`总活动名额` as `总活动名额`,
    b.`总有效订单量` as `总有效订单量`,
    b.`平均销单率` as `平均销单率`,
    a.`活动名额`/b.`总活动名额` as `活动名额占比`,
    a.`有效订单量`/b.`总有效订单量` as `有效订单占比`
from (
    select
        `城市`,
        `餐标`,
        `活动名额`,
        `有效订单量`,
        IF(`活动名额`= 0, 0,`有效订单量`/`活动名额`) AS `销单率`  
    from(
        select 
            `城市`,
            `餐标`,
            sum(`总活动名额`) as `活动名额`,
            sum(`有效订单量`) as `有效订单量`
        from t3
            where length(city_name)>1
        group by 1,2
        having sum(`总活动名额`)>0
        ) a1
    ) a
left join
-- 城市整体
    (select
        `城市`,
        `总活动名额`,
        `总有效订单量`,
        IF(`总活动名额`= 0, 0,`总有效订单量`/`总活动名额`) AS `平均销单率`  
    from(
        select 
            `城市`,
            sum(`总活动名额`) as `总活动名额`,
            sum(`有效订单量`) as `总有效订单量`
        from t3
            where length(city_name)>1
        group by 1
        having sum(`总活动名额`)>0
        ) b1
    ) b
on a.`城市`=b.`城市`




======================
-- part4 热力图

select
        `省份`,
        avg(`总活动名额`) as `日均活动名额`,
        avg(`有效订单量`) as `日均有效订单量`,
        `日均有效订单量`/`日均活动名额` as `销单率`
from (select 
            toDate(statistics_date) `统计日期`,
            b.province_name as `省份`,
            sum(tot_promotion_quota) as `总活动名额`,
            sum(vaild_order_num) as `有效订单量`
    from dws.dws_ck_order_promotion_d_county a
left join
    (select 
        city_name,
        province_name 
    from dim.dim_region_code
    group by 1,2
    ) b
on a.city_name=b.city_name
where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
            and promotion_category='自营'
            and length(city_name)>1
            and city_name<>'全国'
            and length(b.province_name)>2
    group by 1,2
    having `总活动名额`>0
) a
group by 1


======================
-- 店铺活动
with t1 as (
select
    a.begin_date,
    store_promotion_id, -- 店铺活动ID
    a.store_id, -- 店铺ID
    b.city_name,
    b.district_name,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type, -- 店铺一级分类
    sub_category_type, -- 店铺二级分类
    store_brand_type, -- 品牌类别
    delivery_type, -- 配送类型
    meituan_order_amt, -- 美团满返门槛
    meituan_mlabel_rebate_amt, -- 美团返现金额
    eleme_order_amt, -- 饿了么满返门槛
    eleme_mlabel_rebate_amt, -- 饿了么返现金额
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    store_platform, -- 店铺平台名称
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from (
select 
    begin_date,
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
        when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
        when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
    END AS store_platform,
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between date_sub($END_DATE$,interval 20 day) and $END_DATE$
                and str_to_date(begin_date,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    replace(city_name,'市','') as city_name,
    district_name,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where dt between date_sub($END_DATE$,interval 7 day) and $END_DATE$
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
    and store_promotion_id>0
group by 1
),

-- 日汇总
t3 as (
select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    city_name as `城市`,
    district_name as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10
)


-- 分省份
select
        `省份`,
        avg(`总活动名额`) as `日均活动名额`,
        avg(`有效订单量`) as `日均有效订单量`,
        avg(`有效订单量`)/avg(`总活动名额`) as `销单率`
from (select 
            `统计日期`,
            b.province_name as `省份`,
            sum(`总活动名额`) as `总活动名额`,
            sum(`有效订单量`) as `有效订单量`
    from t3 a
left join
    (select 
        replace(city_name,'市','') as city_name,
        province_name 
    from dim.dim_silkworm_county
    group by 1,2
    ) b
on a.`城市`=b.city_name
where length(a.`城市`)>1
    and length(b.province_name)>2
    group by 1,2
    having sum(`总活动名额`)>0
) a
group by 1

union all

select
        `省份`,
        avg(`总活动名额`) as `日均活动名额`,
        avg(`有效订单量`) as `日均有效订单量`,
        avg(`有效订单量`)/avg(`总活动名额`) as `销单率`
from (select 
            `统计日期`,
            '全国' as `省份`,
            sum(`总活动名额`) as `总活动名额`,
            sum(`有效订单量`) as `有效订单量`
    from t3
    group by 1,2
    having sum(`总活动名额`)>0
) a
group by 1
==================

-- part5 数据表格下载

select
    `统计日期`,
    `城市`,
    `区县`,
    `总活动名额`,
    `有效订单量`,
    `有效订单量`/`总活动名额` as `销单率`,
    `有效订单量`/`有效订单用户量` as `人均订单量`
from (select 
            toDate(statistics_date) `统计日期`,
            city_name `城市`,
            county_name `区县`,
            sum(tot_promotion_quota) `总活动名额`,
            sum(vaild_order_num) `有效订单量`,
            sum(vaild_order_user_num) `有效订单用户量`
    from dws.dws_ck_order_promotion_d_county
        where toDate(dt) between $BEGIN_DATE$ and $END_DATE$
            and promotion_category='自营'
            and length(city_name)>1
        group by 1,2,3
        having `总活动名额`>0
    ) a



====================
-- 店铺活动
with t1 as (
select
    a.begin_date,
    store_promotion_id, -- 店铺活动ID
    a.store_id, -- 店铺ID
    b.city_name,
    b.district_name,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type, -- 店铺一级分类
    sub_category_type, -- 店铺二级分类
    store_brand_type, -- 品牌类别
    delivery_type, -- 配送类型
    meituan_order_amt, -- 美团满返门槛
    meituan_mlabel_rebate_amt, -- 美团返现金额
    eleme_order_amt, -- 饿了么满返门槛
    eleme_mlabel_rebate_amt, -- 饿了么返现金额
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    store_platform, -- 店铺平台名称
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from (
select 
    begin_date,
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
        when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
        when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
    END AS store_platform,
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between date_sub($END_DATE$,interval 20 day) and $END_DATE$
                and str_to_date(begin_date,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    replace(city_name,'市','') as city_name,
    district_name,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    user_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where dt between date_sub($END_DATE$,interval 7 day) and $END_DATE$
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
    and store_promotion_id>0
group by 1,2
),

-- 日汇总
t3 as (
select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    city_name as `城市`,
    district_name as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`,
    count(distinct if(valid_order_num>0,t2.user_id,null)) as `有效订单用户量`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10
),


-- 全国日汇总
t4 as (
select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    '全国' as `城市`,
    '全国' as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`,
    count(distinct if(valid_order_num>0,t2.user_id,null)) as `有效订单用户量`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10
)


-- 分城市
select
    `统计日期`,
    `城市`,
    `区县`,
    `总活动名额`,
    `有效订单量`,
    `有效订单量`/`总活动名额` as `销单率`,
    `有效订单量`/`有效订单用户量` as `人均订单量`
from (select 
            `统计日期`,
            `城市`,
            `区县`,
            sum(`总活动名额`) `总活动名额`,
            sum(`有效订单量`) `有效订单量`,
            sum(`有效订单用户量`) `有效订单用户量`
    from t3
        where length(`城市`)>1
        group by 1,2,3
        having sum(`总活动名额`)>0
    ) a

union all

-- 全国
select
    `统计日期`,
    `城市`,
    `区县`,
    `总活动名额`,
    `有效订单量`,
    `有效订单量`/`总活动名额` as `销单率`,
    `有效订单量`/`有效订单用户量` as `人均订单量`
from (select 
            `统计日期`,
            `城市`,
            `区县`,
            sum(`总活动名额`) `总活动名额`,
            sum(`有效订单量`) `有效订单量`,
            sum(`有效订单用户量`) `有效订单用户量`
    from t4
        group by 1,2,3
        having sum(`总活动名额`)>0
    ) a


===============
-- part6 明细下载

select 
toDate(statistics_date) `统计日期`,
city_name `城市`,
county_name `区县`,
store_sub_category_type `店铺标签子类型`,
store_platform `店铺平台名称`,
threshold_order_amt `订单满返门槛金额`,
order_rebate_maxamt `订单满返最大金额`,
replace(replace(meal_label,'.00',''),'.0','') `餐标`,
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
    and `总活动名额`>0


================
-- 店铺活动
with t1 as (
select
    a.begin_date,
    store_promotion_id, -- 店铺活动ID
    a.store_id, -- 店铺ID
    b.city_name,
    b.district_name,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type, -- 店铺一级分类
    sub_category_type, -- 店铺二级分类
    store_brand_type, -- 品牌类别
    delivery_type, -- 配送类型
    meituan_order_amt, -- 美团满返门槛
    meituan_mlabel_rebate_amt, -- 美团返现金额
    eleme_order_amt, -- 饿了么满返门槛
    eleme_mlabel_rebate_amt, -- 饿了么返现金额
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    store_platform, -- 店铺平台名称
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from (
select 
    begin_date,
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
        when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
        when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
    END AS store_platform,
    rebate_condition_desc,
    meituan_promotion_quota,
    eleme_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between date_sub($END_DATE$,interval 20 day) and $END_DATE$
                and str_to_date(begin_date,'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    replace(city_name,'市','') as city_name,
    district_name,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    user_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where dt between date_sub($END_DATE$,interval 7 day) and $END_DATE$
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between $BEGIN_DATE$ and $END_DATE$
    and store_promotion_id>0
group by 1,2
),

-- 日汇总
t3 as (
select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    city_name as `城市`,
    district_name as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`,
    count(distinct if(valid_order_num>0,t2.user_id,null)) as `有效订单用户量`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10
),

-- 全国日汇总
t4 as (
select
    t1.begin_date as `统计日期`,
    -- '自营' as `活动类别`,
    '全国' as `城市`,
    '全国' as `区县`,
    sub_category_type as `店铺标签子类型`,
    store_platform as `店铺平台名称`,
    mlabel_threshold_amt as `订单满返门槛金额`,
    mlabel_rebate_amt as `订单满返最大金额`,
    mlabel as `餐标`,
    rebate_condition_desc as `返利条件说明`,
    is_youzhi_promotion as `优质活动`, -- 0:否,1:是
    sum(meituan_promotion_quota) as `美团活动名额`,
    sum(eleme_promotion_quota) as `饿了么活动名额`,
    sum(promotion_quota) as `总活动名额`,
    sum(valid_order_num) as `有效订单量`,
    count(distinct t1.store_promotion_id) as `店铺活动数`,
    count(distinct if(valid_order_num>0,t1.store_promotion_id,null)) as `有有效单店铺活动数`,
    count(distinct if(valid_order_num>0,t2.user_id,null)) as `有效订单用户量`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4,5,6,7,8,9,10
)


select 
    `统计日期`,
    `城市`,
    `区县`,
    `店铺标签子类型`,
    `店铺平台名称`,
    `订单满返门槛金额`,
    `订单满返最大金额`,
    `餐标`,
    `返利条件说明`,
    if(`优质活动`=0,'非优质活动','优质活动') `优质活动`,
    `美团活动名额`,
    `饿了么活动名额`,
    `总活动名额`,
    `有效订单量`,
    `有效订单用户量`,  
    `店铺活动数`,
    `有有效单店铺活动数`
from t3
where length(`城市`)>1
    and `总活动名额`>0

union all

select 
    `统计日期`,
    `城市`,
    `区县`,
    `店铺标签子类型`,
    `店铺平台名称`,
    `订单满返门槛金额`,
    `订单满返最大金额`,
    `餐标`,
    `返利条件说明`,
    if(`优质活动`=0,'非优质活动','优质活动') `优质活动`,
    `美团活动名额`,
    `饿了么活动名额`,
    `总活动名额`,
    `有效订单量`,
    `有效订单用户量`,  
    `店铺活动数`,
    `有有效单店铺活动数`
from t4
where `总活动名额`>0


--Spark SQL
--******************************************************************--
--author: dahe
--create time: 2024-06-17 17:47:41
--******************************************************************--
-- drop table if exists `dws`.`dws_hive_order_promotion_d_county`;

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
STORED AS ORC;



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
WHERE concat(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')) between date_sub('${T-1}',30) and '${T-1}'
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
from dwd.dwd_hive_silkworm_promotion_order
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