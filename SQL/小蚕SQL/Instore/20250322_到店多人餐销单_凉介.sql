with t1 as (
select 
	dt,
	promotion_id,
	case when promotion_type in (1,4) then '探店'
    else '砍价' end as business_name,
    tot_promotion_quota,
    b.city_name
from dwd.dwd_sr_silkworm_explore_promotion a
left join dim.dim_silkworm_county b on a.city_code=b.county_id
where date_format(a.dt,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and a.sub_category_type=11 -- 正餐/多人餐
    and a.promotion_type in (1,4,5,6)
),

-- 支付订单量
t2 as (
select
    store_promotion_id,
    case when promotion_type in (1,4) then '探店'
    else '砍价' end as business_name,
    count(1) as payord_num
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 40 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4,5,6)
    and date_format(pay_time,'%Y-%m-%d')<>'1970-01-01'
group by 1,2
)


select
	business_name `业务线`,
	city_name `城市`,
	ceil(avg(pro_num)) as `近30天日均活动数`,
	ceil(avg(quota)) as `近30天日均活动名额`,
	ceil(avg(payord_num)) as `近30天日均支付订单量`,
	concat(round(avg(payord_num)/avg(quota),2)*100,'%') as `销单率(支付)`
from
(select
	t1.dt,
	t1.business_name,
	t1.city_name,
	count(t1.promotion_id) as pro_num,
	sum(t1.tot_promotion_quota) as quota,
	sum(coalesce(payord_num,0)) as payord_num
from t1 left join t2 on t1.promotion_id=t2.store_promotion_id
group by 1,2,3) a
group by 1,2;


======== 到店活动数和名额
SELECT date_format(dt,'%Y-%m-%d') dat,
       CASE
           WHEN promotion_type IN (1,
                                   4) THEN '探店'
           ELSE '砍价'
       END AS business_name,
       count(1) `活动数`,
       sum(tot_promotion_quota) `活动名额`,
       count(if(date_format(begin_time,'%Y-%m-%d')<>date_format(end_time,'%Y-%m-%d'),promotion_id,NULL)) `跨天活动数`,
       sum(if(date_format(begin_time,'%Y-%m-%d')<>date_format(end_time,'%Y-%m-%d'),tot_promotion_quota,0)) `跨天活动名额`
FROM dwd.dwd_sr_silkworm_explore_promotion
WHERE promotion_type IN (1,
                         4,
                         5,
                         6)
GROUP BY 1,
         2;