-- 统计各bd人员，6、7月业绩

-- 城市维表
with dim_city as (
select
    substr(cast(county_id as string),1,4) as city_id,
    replace(city_name,'市','') as city_name
from dim.dim_hive_region_code
group by 1,2
),


-- bd对应店铺城市(city字段有null，从店铺活动取数据看下)
bd_store_city as (
select
    bd_id,
    city_id as store_city_id,
    replace(city,'市','') as store_city_name,
    count(if(substr(first_order_time,1,7)='2024-06',store_id,null)) as m6_valid_new_store_num, -- 新增有效店铺量
    count(if(substr(first_order_time,1,7)='2024-07',store_id,null)) as m7_valid_new_store_num -- 新增有效店铺量
from dim.dim_silkworm_store
-- where status=1 -- 已审核
group by 1,2,3
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
    substr(city_id,1,4) as city_id
from
    (select
        a.staff_id as bd_id,
        explode(split(b.city_id_list,',')) as city_id
    from ods.ods_hive_authority_authentication_employee a
    left join dim.dim_silkworm_bd_city b
    on a.staff_id=b.bd_id
    ) a1
group by 1,2
    ) a
left join dim_city on a.city_id=dim_city.city_id
),


-- bd店铺城市和业务城市
dim_bd as (
select
    coalesce(a.bd_id,b.bd_id) as bd_id,
    a.store_city_id,
    a.store_city_name,
    b.bu_city_id,
    b.bu_city_name,
    a.m6_valid_new_store_num,
    a.m7_valid_new_store_num
from bd_store_city a
full join bd_bu_city b
on a.bd_id=b.bd_id and a.store_city_name=b.bu_city_name
),



-- 店铺活动
t1 (
select
    substr(a.begin_date,1,7) as mon,
    b.bd_id,
    a.store_id,
    a.store_promotion_id,
    c.city_name,
    a.real_subscribe_num,
    (meituan_user_rebate_point/100) + (eleme_user_rebate_point/100) as rebate_amt,
    a.meituan_promotion_quota+a.eleme_promotion_quota as promotion_quota
from dwd.dwd_hive_store_promotion a
left join dim.dim_silkworm_store b
    on a.store_id=b.store_id
left join dim_city c
    on cast(a.city_id as string)=c.city_id
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-03-01' and date_sub(current_date,1)
        and a.begin_date between '2024-06-01' and '2024-07-31'
        and a.status in (1,4,5)
),

-- 订单
t2 as (
select
    store_promotion_id,
    count(auto_id) as vaild_order_num, -- 有效订单量
    sum(service_charge) as service_charge -- 服务费
from dwd.dwd_hive_silkworm_promotion_order
where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between '2024-04-01' and date_sub(current_date,1)
    and substr(order_time,1,10) between '2024-06-01' and '2024-07-31'
    and order_status in (2,8)
    and store_promotion_id>0
group by 1
),


-- 统计bd各店铺下活动名额、完单量
t3 as (
select
bd_id,
city_name,
sum(if(mon='2024-06' and t1.real_subscribe_num=0,rebate_amt,0)) as bb_m6_rebate_amt, -- 半包6月总返利金额
sum(if(mon='2024-06' and t1.real_subscribe_num=0,promotion_quota,0)) as bb_m6_promotion_quota, -- 半包6月总活动名额
sum(if(mon='2024-06' and t1.real_subscribe_num=0 and t2.store_promotion_id is not null,vaild_order_num,0)) as bb_m6_valid_order_num, -- 半包6月总有效订单量
sum(if(mon='2024-06' and t1.real_subscribe_num=0 and t2.store_promotion_id is not null,service_charge,0)) as bb_m6_service_charge, -- 半包6月总服务费
sum(if(mon='2024-06' and t1.real_subscribe_num=1,rebate_amt,0)) as qb_m6_rebate_amt, -- 全包6月总返利金额
sum(if(mon='2024-06' and t1.real_subscribe_num=1,promotion_quota,0)) as qb_m6_promotion_quota, -- 全包6月总活动名额
sum(if(mon='2024-06' and t1.real_subscribe_num=1 and t2.store_promotion_id is not null,vaild_order_num,0)) as qb_m6_valid_order_num, -- 全包6月总有效订单量
sum(if(mon='2024-06' and t1.real_subscribe_num=1 and t2.store_promotion_id is not null,service_charge,0)) as qb_m6_service_charge, -- 全包6月总服务费
sum(if(mon='2024-06' and t1.real_subscribe_num=2,rebate_amt,0)) as yy_m6_rebate_amt, -- 1元6月总返利金额
sum(if(mon='2024-06' and t1.real_subscribe_num=2,promotion_quota,0)) as yy_m6_promotion_quota, -- 1元6月总活动名额
sum(if(mon='2024-06' and t1.real_subscribe_num=2 and t2.store_promotion_id is not null,vaild_order_num,0)) as yy_m6_valid_order_num, -- 1元6月总有效订单量
sum(if(mon='2024-06' and t1.real_subscribe_num=2 and t2.store_promotion_id is not null,service_charge,0)) as yy_m6_service_charge, -- 1元6月总服务费

sum(if(mon='2024-07' and t1.real_subscribe_num=0,rebate_amt,0)) as bb_m7_rebate_amt, -- 半包7月总返利金额
sum(if(mon='2024-07' and t1.real_subscribe_num=0,promotion_quota,0)) as bb_m7_promotion_quota, -- 半包7月总活动名额
sum(if(mon='2024-07' and t1.real_subscribe_num=0 and t2.store_promotion_id is not null,vaild_order_num,0)) as bb_m7_valid_order_num, -- 半包7月总有效订单量
sum(if(mon='2024-07' and t1.real_subscribe_num=0 and t2.store_promotion_id is not null,service_charge,0)) as bb_m7_service_charge, -- 半包7月总服务费
sum(if(mon='2024-07' and t1.real_subscribe_num=1,rebate_amt,0)) as qb_m7_rebate_amt, -- 全包7月总返利金额
sum(if(mon='2024-07' and t1.real_subscribe_num=1,promotion_quota,0)) as qb_m7_promotion_quota, -- 全包7月总活动名额
sum(if(mon='2024-07' and t1.real_subscribe_num=1 and t2.store_promotion_id is not null,vaild_order_num,0)) as qb_m7_valid_order_num, -- 全包7月总有效订单量
sum(if(mon='2024-07' and t1.real_subscribe_num=1 and t2.store_promotion_id is not null,service_charge,0)) as qb_m7_service_charge, -- 全包7月总服务费
sum(if(mon='2024-07' and t1.real_subscribe_num=2,rebate_amt,0)) as yy_m7_rebate_amt, -- 1元7月总返利金额
sum(if(mon='2024-07' and t1.real_subscribe_num=2,promotion_quota,0)) as yy_m7_promotion_quota, -- 1元7月总活动名额
sum(if(mon='2024-07' and t1.real_subscribe_num=2 and t2.store_promotion_id is not null,vaild_order_num,0)) as yy_m7_valid_order_num, -- 1元7月总有效订单量
sum(if(mon='2024-07' and t1.real_subscribe_num=2 and t2.store_promotion_id is not null,service_charge,0)) as yy_m7_service_charg -- 1元7月总服务费
from t1 left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2
)



select
    a.bd_id,
    -- store_city_id `店铺城市ID`,
    store_city_name `店铺城市`,
    -- bu_city_id `业务城市ID`,
    bu_city_name `业务城市`,
    m6_valid_new_store_num `6月新增有效店铺量`,
    m7_valid_new_store_num `7月新增有效店铺量`,
    bb_m6_rebate_amt `半包6月总返利金额`,
    bb_m6_promotion_quota `半包6月总活动名额`,
    bb_m6_valid_order_num `半包6月总有效订单量`,
    bb_m6_service_charge `半包6月总服务费`,
    qb_m6_rebate_amt `全包6月总返利金额`,
    qb_m6_promotion_quota `全包6月总活动名额`,
    qb_m6_valid_order_num `全包6月总有效订单量`,
    qb_m6_service_charge `全包6月总服务费`,
    yy_m6_rebate_amt `全包1元6月总返利金额`,
    yy_m6_promotion_quota `全包1元6月总活动名额`,
    yy_m6_valid_order_num `全包1元6月总有效订单量`,
    yy_m6_service_charge `全包1元6月总服务费`,
    bb_m7_rebate_amt `半包7月总返利金额`,
    bb_m7_promotion_quota `半包7月总活动名额`,
    bb_m7_valid_order_num `半包7月总有效订单量`,
    bb_m7_service_charge `半包7月总服务费`,
    qb_m7_rebate_amt `全包7月总返利金额`,
    qb_m7_promotion_quota `全包7月总活动名额`,
    qb_m7_valid_order_num `全包7月总有效订单量`,
    qb_m7_service_charge `全包7月总服务费`,
    yy_m7_rebate_amt `全包1元7月总返利金额`,
    yy_m7_promotion_quota `全包1元7月总活动名额`,
    yy_m7_valid_order_num `全包1元7月总有效订单量`,
    yy_m7_service_charg `全包1元7月总服务费`
from dim_bd a
left join t3 b
on a.bd_id=b.bd_id and a.store_city_name=b.city_name

















