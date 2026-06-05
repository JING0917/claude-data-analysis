with t1 as (
select
        store_id              -- 店铺id
        ,store_promotion_id    -- 店铺活动id
        ,merchant_id           -- 商家id
      ,case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
            when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
            when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
       END AS store_platform,
    meituan_promotion_quota + eleme_promotion_quota AS tot_promotion_quota, -- 活动名额
    meituan_promotion_remain_quota + eleme_promotion_remain_quota as tot_promotion_remain_quota, -- 剩余名额
    case when promotion_rebate_type=0 then concat('满',cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string),'返',cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string))
            when promotion_rebate_type=1 then concat('最高返',cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string))
       else '其他' end AS meal_label,
    concat(begin_time,'-',end_time) as promotion_duration,
    meituan_upload_num + eleme_upload_num as tot_upload_num, -- 待上传数量
    meituan_audit_num + eleme_audit_num as tot_audit_num, -- 待审核数量
    meituan_finished_num + eleme_finished_num as tot_finished_num, -- 完成数量
    bd_id,
    is_operation_promption
from dwd.dwd_sr_store_promotion
WHERE cast(dt as string) between '2025-01-01' and '2025-04-30'
    and substr(begin_date,1,10) between '2025-04-01' and '2025-04-30'
    and status in (1, 4, 5)
    -- and is_operation_promption=1 -- 是否运营创建活动 1：是   处理时需要去掉该限制，因查看到循环活动中，只标记了第一次创建时=1，之后开启循环，置为=0了
    and is_vip_exclusive=1 -- 是否VIP用户专享 1：是
),

-- show create table dim.dim_silkworm_store;

-- 店铺
t2 as (
select 
    store_id,
    store_name,
    city_name
from dim.dim_silkworm_store
where status=1 -- 已审核
    -- and store_name regexp '霸王茶姬'
)

select
    t1.store_promotion_id `活动ID`,
    t2.store_name as `店铺名称`,
    t2.city_name as `店铺城市`,
    store_platform as `平台名称`,
    meal_label as `餐标`,
    promotion_duration as `活动周期`,
    t1.bd_id,
    t3.user_nickname `花名`,
    sum(tot_promotion_quota) as `活动名额`,
    sum(tot_promotion_remain_quota) as `剩余名额`,
    sum(tot_upload_num) as `待上传数量`,
    sum(tot_audit_num) as `待审核数量`,
    sum(tot_finished_num) as `完成数量`
from t1
inner join t2 on t1.store_id=t2.store_id
left join dim.dim_silkworm_staff t3 on t1.bd_id=t3.bd_id
group by 1,2,3,4,5,6,7,8
;


================ 活动销单（喜茶/奈雪/酸奶罐罐）
select
    case when b.store_name regexp '奈雪' then '奈雪'
        when b.store_name regexp '喜茶' then '喜茶'
        when b.store_name regexp '酸奶罐罐' then '酸奶罐罐'
        when b.store_name regexp '霸王茶姬' then '霸王茶姬'
    else '其他' end as `品牌`,
    b.store_id,
    b.store_name,
    b.city_name,
    sum(promotion_quota) as `活动名额`,
    sum(finished_num) as `销单量`,
    round(sum(finished_num)/sum(promotion_quota),2) as `销单率`
from
(select
    store_id,
    sum(meituan_promotion_quota+eleme_promotion_quota) as promotion_quota,
    sum(meituan_finished_num+eleme_finished_num) as finished_num
from dwd.dwd_sr_store_promotion
where dt between '2025-01-01' and '2025-02-28'
    and begin_date between '2025-01-01' and '2025-02-28'
    and status in (1,4,5)
    and is_operation_promption=0
group by 1
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.store_name regexp '奈雪|喜茶|酸奶罐罐|霸王茶姬'
group by 1,2,3,4;



============== 品牌当日销单
喜姐炸串
霸王茶姬
奈雪的茶
古茗
爷爷不泡茶


select
    case when b.store_name regexp '喜姐炸串' then '喜姐炸串'
        -- when b.store_name regexp '喜姐炸串' then '喜姐炸串'
        when b.store_name regexp '霸王茶姬' then '霸王茶姬'
        when b.store_name regexp '茶百道' then '茶百道'
        when b.store_name regexp '爷爷不泡茶' then '爷爷不泡茶'
    else '其他' end as `品牌`,
    -- b.store_id,
    -- b.store_name,
    b.city_name,
    sum(promotion_quota) as `活动名额`,
    sum(finished_num) as `销单量`,
    round(sum(finished_num)/sum(promotion_quota),2) as `销单率`
from
(select
    store_id,
    sum(meituan_promotion_quota+eleme_promotion_quota) as promotion_quota,
    sum(meituan_finished_num+eleme_finished_num) as finished_num
from dwd.dwd_sr_store_promotion
where date_format(dt,'%Y-%m-%d') between '2025-01-01' and '2025-05-31'
    and date_format(begin_date,'%Y-%m-%d') between '2025-05-01' and '2025-05-31'
    and status in (1,4,5)
    -- and is_operation_promption=0
group by 1
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.store_name regexp '茶百道|霸王茶姬|爷爷不泡茶'
group by 1,2;











