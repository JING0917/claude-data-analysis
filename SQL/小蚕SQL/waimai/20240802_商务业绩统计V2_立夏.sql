--SQL 
--******************************************************************--
--author: dahe
--create time: 2024-08-27 09:21:43
--******************************************************************--
-- 统计各bd人员，6、7月业绩

-- 查看某商务员工业务城市
-- select * from dim.dim_authority_authentication_employee a
-- left join dim.dim_silkworm_bd_city b
--     on a.staff_id=b.bd_id
-- where a.staff_id=2323


-- 在starrocks中执行，如果在datart使用，则切换数据源为starrocks

-- 城市维表
with dim_city as (
select
    substr(cast(county_id as string),1,4) as city_id,
    replace(city_name,'市','') as city_name
from dim.dim_silkworm_county
group by 1,2
),

-- bd对应店铺城市(city字段有null，从店铺活动取数据看下)
bd_store_city as (
select
    bd_id,
    store_id,
    dim_city.city_id as store_city_id,
    dim_city.city_name as store_city_name
from dim.dim_silkworm_store a
left join dim_city on substr(cast(a.city_id as string),1,4)=dim_city.city_id
where status=1 -- 已审核
group by 1,2,3,4
),


-- bd对应业务城市    
bd_bu_city as (
select
    bd_id,
    a.city_id as bu_city_id,
    dim_city.city_name as bu_city_name
from (
select
    bd_id,
    substr(unnest,1,4) as city_id
from
    (select
        a.bd_id,
        cast(get_json_string(b.city_id_list,'$.city_code_list') as array<string>) as city_id
    from dim.dim_silkworm_staff a
    left join dim.dim_silkworm_bd_city b
    on a.staff_id=b.bd_id
    ) a1,unnest(city_id)
group by 1,2
    ) a
left join dim_city on a.city_id=dim_city.city_id
),

-- -- bd店铺城市和业务城市
-- dim_bd as (
-- select
--     coalesce(a.bd_id,b.bd_id) as bd_id,
--     a.store_city_id,
--     a.store_city_name,
--     b.bu_city_id,
--     b.bu_city_name,
--     a.m6_valid_new_store_num,
--     a.m7_valid_new_store_num
-- from bd_store_city a
-- full join bd_bu_city b
-- on a.bd_id=b.bd_id and a.store_city_name=b.bu_city_name
-- ),



-- 店铺活动
t1 as (
select
     a.new_begin_date,
     substr(a.begin_date,1,10) as begin_date,
     a.end_date,
     a.bd_id,
     a.store_id,
     a.store_promotion_id,
     c.city_name,
     a.cooper_type,
     is_youzhi_promotion,
     (meituan_mlabel_rebate_amt) + (eleme_mlabel_rebate_amt) as rebate_amt,
     a.meituan_promotion_quota+a.eleme_promotion_quota as promotion_quota,
     b.first_promotion_date,
     a.is_threshold,
     a.is_need_rating,
     a.service_charge

from 
-- 得到新活动开始日期
(select
    to_date(date_add(to_date(begin_date),unnest)) as new_begin_date,
    begin_date,
    end_date,
    arr,
    bd_id,
    store_id,
    store_promotion_id,
    city_id,
    cooper_type,
    is_youzhi_promotion,
    meituan_mlabel_rebate_amt,
    eleme_mlabel_rebate_amt,
    meituan_promotion_quota,
    eleme_promotion_quota,
    is_threshold,
    is_need_rating,
    service_charge
from
-- 构造跨天活动日期，作为新活动开始日期
    (select
        begin_date,
        end_date,
        array_generate(0,diff_num,1) as arr,
        bd_id,
        store_id,
        store_promotion_id,
        city_id,
        cooper_type,
        is_youzhi_promotion,
        meituan_mlabel_rebate_amt,
        eleme_mlabel_rebate_amt,
        meituan_promotion_quota,
        eleme_promotion_quota,
        is_threshold,
        is_need_rating,
        service_charge
    from
        -- 7月发布活动
        (select begin_date,
                end_date,
                cast(datediff(to_date(end_date),to_date(begin_date)) as int) as diff_num,
                bd_id,
                store_id,
                store_promotion_id,
                city_id,
                cooper_type,
                is_youzhi_promotion,
                meituan_mlabel_rebate_amt,
                eleme_mlabel_rebate_amt,
                meituan_promotion_quota,
                eleme_promotion_quota,
                if(meituan_mlabel_threshold_amt<>0 or eleme_mlabel_threshold_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
                if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
                service_charge
        from dwd.dwd_sr_store_promotion
        where dt between '2024-06-01' and '2024-07-31'
                and begin_date between '2024-07-01' and '2024-07-31'
                and status in (1,4,5)
        ) a1
) a2,unnest(arr)
) a
left join 
-- 店铺7月首次发布活动时间
        (select store_id,
            substr(first_promotion_time,1,10) as first_promotion_date
        from dim.dim_silkworm_store
        where substr(first_promotion_time,1,10) between '2024-07-01' and '2024-07-31'
        ) b
on a.store_id=b.store_id
left join dim_city c
        on cast(a.city_id as string)=c.city_id
),

-- 验证数据 无问题
-- select * from t1 where store_promotion_id in (26102977,26056233)


-- 订单
t2 as (
select
    store_promotion_id,
    substr(order_time,1,10) as order_date,
    count(order_id) as valid_order_num, -- 有效订单量
    sum(service_charge) as service_charge, -- 服务费
    sum(profit) as profit -- 利润
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-06-01' and '2024-07-31'
    and substr(order_time,1,10) between '2024-07-01' and '2024-07-31'
    and order_status in (2,8)
    and store_promotion_id>0
group by 1,2
),


-- 月订单最小时间
t3 as (
select
    store_promotion_id,
    min(order_time) as min_order_time -- 最小下单时间
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-06-01' and '2024-07-31'
        and substr(order_time,1,10) between '2024-07-01' and '2024-07-31'
        and order_status in (2,8)
        and store_promotion_id>0
group by 1
),


-- bd店铺累计有效订单
t4 as (
-- 对累计订单量排序，以便使用首个>=10日期   
select
    order_date,
    store_id,
    bd_id,
    acc_vaild_order_num,
    row_number() over(partition by store_id,bd_id order by acc_vaild_order_num asc) as rk
from
-- 累计有效订单
    (select
        order_date,
        store_id,
        bd_id,
        sum(vaild_order_num) over(partition by store_id,bd_id order by order_date) as acc_vaild_order_num
    from (
        select
            store_id,
            bd_id,
            substr(order_time,1,10) as order_date,
            count(order_id) as vaild_order_num
        from dwd.dwd_sr_order_promotion_order
        where cast(dt as string) between '2024-06-01' and '2024-07-31'
            and substr(order_time,1,10) between '2024-07-01' and '2024-07-31'
            and order_status in (2,8)
            and store_promotion_id>0
        group by 1,2,3
             ) a
    ) b
where acc_vaild_order_num>=10
),



-- 7月发布活动
t5 as (
select
    begin_date,
    bd_id,
    store_id,
    store_promotion_id,
    b.city_name,
    pay_status, -- 付款状态(0:商家已余额支付,1:后台创建活动开始,2:等待商家支付,3:支付完成,4:部分支付完成) 
    pay_amt
from 
    (select begin_date,
        bd_id,
        store_id,
        store_promotion_id,
        city_id,
        pay_status, -- 付款状态(0:商家已余额支付,1:后台创建活动开始,2:等待商家支付,3:支付完成,4:部分支付完成) 
        fact_pay_rebate_amt/100 as pay_amt
    from dwd.dwd_sr_store_promotion
    where dt between '2024-06-01' and '2024-07-31'
            and begin_date between '2024-07-01' and '2024-07-31'
            and status in (1,4,5)
            and is_pay_exception=1 -- 是否15日内未支付 0:否，1:是
    ) a
left join dim_city b
        on cast(a.city_id as string)=b.city_id
),


-- 外呼统计
t6 as (
select
    dt
    ,bd_id
    ,count(auto_id) as call_num -- 外呼量
    ,count(if(is_connect=1,auto_id,null)) as jt_num -- 接通量
    ,sum(if(is_connect=1,duration,0)) as call_duration -- 通话时长
    ,sum(if(is_connect=1,duration,0))/count(if(is_connect=1,auto_id,null)) as avg_call_duration
from dwd.dwd_sr_store_bd_call_record
where dt between '2024-07-01' and '2024-07-31'
group by 1,2
),
-- 各部分统计后要做过滤，没日期的数据要过滤掉。因部分bd在指定条件下可能没有对应指标结果

-- -- 统计各bd新店铺数
t7 as (
-- 外呼
select
    t6.dt as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,call_num -- 外呼量
    ,jt_num -- 接通量
    ,call_duration -- 通话时长
    ,0 as new_store_num -- 新店铺数
    ,0 as valid_new_store_num -- 有效新店铺
    ,0 as online_store_num
    ,0 as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,0 as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join t6 on a.bd_id=t6.bd_id

union all
-- 新店铺
select
    t1.begin_date as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,count(distinct if(t1.first_promotion_date is not null,t1.store_id,null)) as new_store_num -- 新店铺数
    ,0 as valid_new_store_num -- 有效新店铺
    ,0 as online_store_num
    ,0 as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,0 as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join t1 on a.bd_id=t1.bd_id and a.bu_city_name=t1.city_name
group by 1,2,3,4

union all
-- 统计各bd有效新店铺数
select
    substr(t3.min_order_time,1,10) as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,0 as new_store_num
    ,count(distinct if(t1.first_promotion_date is not null and t3.min_order_time is not null,t1.store_id,null)) as valid_new_store_num -- 有效新店铺
    ,0 as online_store_num
    ,count(distinct if(t1.is_youzhi_promotion=1 and t3.min_order_time is not null,store_id,null)) as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,count(distinct if(t1.is_youzhi_promotion=1 and t3.min_order_time is not null,t1.store_promotion_id,null)) as youzhi_promotion_num -- 优质活动数
    ,0 as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join t1 on a.bd_id=t1.bd_id and a.bu_city_name=t1.city_name
left join t3 on t1.store_promotion_id=t3.store_promotion_id
group by 1,2,3,4

union all
-- 在线店铺数
select
    t1.new_begin_date as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,0 as new_store_num
    ,0 as valid_new_store_num -- 有效新店铺
    ,count(distinct store_id) as online_store_num
    ,0 as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,0 as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join t1 on a.bd_id=t1.bd_id and a.bu_city_name=t1.city_name
group by 1,2,3,4

union all
-- 活跃店铺
select
    b.order_date as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,0 as new_store_num
    ,0 as valid_new_store_num
    ,0 as online_store_num -- 在线店铺数
    ,0 as youzhi_store_num
    ,count(distinct if(c.first_promotion_date is not null,b.store_id,null)) as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,0 as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join 
    (select
        order_date,t4.store_id,t4.bd_id,b.store_city_name
    from t4 
    left join bd_store_city b on t4.store_id=b.store_id
    where acc_vaild_order_num>=10 and rk=1
    ) b 
on a.bd_id=b.bd_id and a.bu_city_name=b.store_city_name
left join 
-- 店铺7月首次发布活动时间
        (select store_id,
            substr(first_promotion_time,1,10) as first_promotion_date
        from dim.dim_silkworm_store
        where substr(first_promotion_time,1,10) between '2024-07-01' and '2024-07-31'
        ) c
on c.store_id=b.store_id
group by 1,2,3,4

union all
-- 活动名额
select
    b.begin_date as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,0 as new_store_num
    ,0 as valid_new_store_num
    ,0 as online_store_num -- 在线店铺数
    ,0 as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,sum(promotion_quota) as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,sum(if(b.is_youzhi_promotion=1,promotion_quota,0)) as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,sum(if(b.is_threshold=1,promotion_quota,0)) as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,sum(if(b.is_threshold=0,promotion_quota,0)) as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,sum(if(b.is_need_rating=1,promotion_quota,0)) as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,sum(if(b.is_need_rating=0,promotion_quota,0)) as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,sum(if(b.service_charge<=2,promotion_quota,0)) as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join 
    (select
        begin_date,end_date,store_promotion_id,bd_id,is_youzhi_promotion,promotion_quota,is_threshold,is_need_rating,service_charge,city_name
    from t1
    group by 1,2,3,4,5,6,7,8,9,10
    ) b 
on a.bd_id=b.bd_id and a.bu_city_name=b.city_name
group by 1,2,3,4

union all
-- 消耗活动名额
select
    t2.order_date as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,0 as new_store_num
    ,0 as valid_new_store_num
    ,0 as online_store_num -- 在线店铺数
    ,0 as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,0 as tot_promotion_quota -- 活动名额
    ,sum(t2.valid_order_num) as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,sum(if(b.is_youzhi_promotion=1,t2.valid_order_num,0)) as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,sum(if(b.is_threshold=1,t2.valid_order_num,0)) as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,sum(if(b.is_threshold=0,t2.valid_order_num,0)) as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,sum(if(b.is_need_rating=1,t2.valid_order_num,0)) as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,sum(if(b.is_need_rating=0,t2.valid_order_num,0)) as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,sum(if(b.service_charge<=2,t2.valid_order_num,0)) as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,sum(if(b.cooper_type=1 and t2.store_promotion_id is not null,b.rebate_amt,0)) as qb_rebate_amt -- 全包6%返利金额
    ,sum(if(b.cooper_type=1 and t2.store_promotion_id is not null,t2.service_charge,0)) as qb_service_charge -- 全包6%服务费
    ,sum(if(b.cooper_type=1,b.promotion_quota,0)) as qb_promotion_quota -- 全包6%活动名额
    ,sum(if(b.cooper_type=1 and t2.store_promotion_id is not null,t2.valid_order_num,0)) as qb_valid_order_num -- 全包6%有效订单量
    ,sum(if(b.cooper_type=1 and t2.store_promotion_id is not null,t2.profit,0)) as qb_profit -- 全包6%利润
    ,sum(if(b.cooper_type=2 and t2.store_promotion_id is not null,b.rebate_amt,0)) as yy_rebate_amt -- 全包1元返利金额
    ,sum(if(b.cooper_type=2 and t2.store_promotion_id is not null,t2.service_charge,0)) as yy_service_charge -- 全包1元服务费
    ,sum(if(b.cooper_type=2,b.promotion_quota,0)) as yy_promotion_quota -- 全包1元活动名额
    ,sum(if(b.cooper_type=2 and t2.store_promotion_id is not null,t2.valid_order_num,0)) as yy_valid_order_num -- 全包1元有效订单量
    ,sum(if(b.cooper_type=2 and t2.store_promotion_id is not null,t2.profit,0)) as yy_profit -- 1元利润
    ,sum(if(b.cooper_type=0 and t2.store_promotion_id is not null,b.rebate_amt,0)) as bb_rebate_amt -- 半包返利金额
    ,sum(if(b.cooper_type=0 and t2.store_promotion_id is not null,b.service_charge,0)) as bb_service_charge -- 半包服务费
    ,sum(if(b.cooper_type=0,b.promotion_quota,0)) as bb_promotion_quota -- 半包活动名额
    ,sum(if(b.cooper_type=0 and t2.store_promotion_id is not null,t2.valid_order_num,0)) as bb_valid_order_num -- 半包有效订单量
    ,sum(if(b.cooper_type=0 and t2.store_promotion_id is not null,t2 .profit,0)) as bb_profit -- 半包利润
    ,0 as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join 
    (select
        begin_date,end_date,store_promotion_id,bd_id,is_youzhi_promotion,is_threshold,is_need_rating,service_charge,cooper_type,rebate_amt,promotion_quota,city_name
    from t1
    group by 1,2,3,4,5,6,7,8,9,10,11,12
    ) b 
on a.bd_id=b.bd_id and a.bu_city_name=b.city_name
left join t2 on b.store_promotion_id=t2.store_promotion_id
group by 1,2,3,4

union all
-- 待支付活动金额
select
    t5.begin_date as statisticsdate
    ,a.bd_id
    ,a.bu_city_id
    ,a.bu_city_name
    ,0 as call_num -- 外呼量
    ,0 as jt_num -- 接通量
    ,0 as call_duration -- 通话时长
    ,0 as new_store_num
    ,0 as valid_new_store_num
    ,0 as online_store_num -- 在线店铺数
    ,0 as youzhi_store_num
    ,0 as hy_store_num -- 活跃店铺数
    ,0 as youzhi_promotion_num
    ,0 as tot_promotion_quota -- 活动名额
    ,0 as used_quota -- 消耗名额
    ,0 as youzhi_promotion_quota -- 优质活动名额
    ,0 as used_youzhi_quota
    ,0 as ymk_promotion_quota -- 有门槛活动名额
    ,0 as ymk_used_quota -- 有门槛消耗活动名额
    ,0 as wmk_promotion_quota -- 无门槛活动名额
    ,0 as wmk_used_quota -- 无门槛消耗活动名额
    ,0 as ypj_promotion_quota -- 有评价活动名额
    ,0 as ypj_used_quota -- 有评价消耗活动名额
    ,0 as wpj_promotion_quota -- 无评价活动名额
    ,0 as wpj_used_quota -- 无评价消耗活动名额
    ,0 as less2_promotion_quota -- 2元及以下服务费活动名额
    ,0 as less2_used_quota -- 2元及以下服务费活动消耗名额
    ,0 as qb_rebate_amt -- 全包6%返利金额
    ,0 as qb_service_charge -- 全包6%服务费
    ,0 as qb_promotion_quota -- 全包6%活动名额
    ,0 as qb_valid_order_num -- 全包6%有效订单量
    ,0 as qb_profit -- 全包6%利润
    ,0 as yy_rebate_amt -- 全包1元返利金额
    ,0 as yy_service_charge -- 全包1元服务费
    ,0 as yy_promotion_quota -- 全包1元活动名额
    ,0 as yy_valid_order_num -- 全包1元有效订单量
    ,0 as yy_profit -- 1元利润
    ,0 as bb_rebate_amt -- 半包返利金额
    ,0 as bb_service_charge -- 半包服务费
    ,0 as bb_promotion_quota -- 半包活动名额
    ,0 as bb_valid_order_num -- 半包有效订单量
    ,0 as bb_profit -- 半包利润
    ,sum(pay_amt) as bepaid_pay_amt -- 待支付活动金额
from bd_bu_city a
left join t5
on a.bd_id=t5.bd_id and a.bu_city_name=t5.city_name
group by 1,2,3,4
    )




select
    statisticsdate as `统计日期`
    ,bd_id as `bd_id`
    ,bu_city_id as `商务业务城市ID`
    ,bu_city_name as`商务业务城市`
    ,sum(call_num) as `外呼量`
    ,sum(jt_num) as `接通量`
    ,sum(call_duration) as `通话时长`
    ,sum(new_store_num) as `新店铺数`
    ,sum(valid_new_store_num) as `有效新店铺数`
    ,sum(online_store_num) as `在线店铺数`
    ,sum(youzhi_store_num) as `优质店铺数`
    ,sum(hy_store_num) as `活跃新店铺数`
    ,sum(youzhi_promotion_num) as `优质活动数`
    ,sum(tot_promotion_quota) as `活动名额`
    ,sum(used_quota) as `消耗名额`
    ,sum(youzhi_promotion_quota) as `优质活动名额`
    ,sum(used_youzhi_quota) as `优质活动消耗名额`
    ,sum(ymk_promotion_quota) as `有门槛活动名额`
    ,sum(ymk_used_quota) as `有门槛消耗活动名额`
    ,sum(wmk_promotion_quota) as `无门槛活动名额`
    ,sum(wmk_used_quota) as `无门槛消耗活动名额`
    ,sum(ypj_promotion_quota) as `有评价活动名额`
    ,sum(ypj_used_quota) as `有评价消耗活动名额`
    ,sum(wpj_promotion_quota) as `无评价活动名额`
    ,sum(wpj_used_quota) as `无评价消耗活动名额`
    ,sum(less2_promotion_quota) as `两元及以下服务费活动名额`
    ,sum(less2_used_quota) as `两元及以下服务费活动消耗名额`
    ,sum(qb_rebate_amt) as `全包6%返利金额`
    ,sum(qb_service_charge) as `全包6%服务费`
    ,sum(qb_promotion_quota) as `全包6%活动名额`
    ,sum(qb_valid_order_num) as `全包6%有效订单量`
    ,sum(qb_profit) as `全包6%利润`
    ,sum(yy_rebate_amt) as `全包一元返利金额`
    ,sum(yy_service_charge) as `全包一元服务费`
    ,sum(yy_promotion_quota) as `全包一元活动名额`
    ,sum(yy_valid_order_num) as `全包一元有效订单量`
    ,sum(yy_profit) as `全包一元利润`
    ,sum(bb_rebate_amt) as `半包返利金额`
    ,sum(bb_service_charge) as `半包服务费`
    ,sum(bb_promotion_quota) as `半包活动名额`
    ,sum(bb_valid_order_num) as `半包有效订单量`
    ,sum(bb_profit) as `半包利润`
    ,sum(bepaid_pay_amt) as `待支付活动金额`
from t7
group by 1,2,3,4















