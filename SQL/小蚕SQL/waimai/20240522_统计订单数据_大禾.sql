-- 下单数据统计
-- 循环活动的，要确认循环的时间周期，以便统计活动名额
-- 排查活动为什么没有关联上，已排除订单表store_promotion_id是0的情况。

select 
    -- concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) as `下单日期`,
    -- c.city as `店铺城市`,
    -- c.district as `店铺区县`,
    a.city_id,
    a.county_id,
    case when c.category_sub_type=1 then '包子粥铺'
        when c.category_sub_type=2 then '快餐简餐'
        when c.category_sub_type=3 then '甜品饮品'
        when c.category_sub_type=4 then '炸串小吃'
        when c.category_sub_type=5 then '火锅烧烤'
        when c.category_sub_type=6 then '汉堡西餐'
        when c.category_sub_type=7 then '零售'
        when c.category_sub_type=8 then '水果鲜花'
        when c.category_sub_type=9 then '成人用品'
        end as `店铺类别`,
    case when b.promotion_rebate_type=0 and b.meituan_rebate>0 then concat('美团-','满',cast(b.meituan_order_money/100 as string),'返',cast(b.meituan_rebate/100 as string))
        when b.promotion_rebate_type=1 and b.meituan_rebate>0 then concat('美团-','最高返',cast(b.meituan_rebate/100 as string))
        when b.promotion_rebate_type=0 and b.eleme_rebate>0 then concat('饿了么-','满',cast(b.eleme_order_money/100 as string),'返',cast(b.eleme_rebate/100 as string))
        when b.promotion_rebate_type=1 and b.eleme_rebate>0 then concat('饿了么-','最高返',cast(b.eleme_rebate/100 as string))
        end as `餐标`,
    case when b.rebate_condition_str regexp '用餐反馈' then '用餐反馈'
        else '无需反馈' end as `用餐反馈`,
    case when b.if_high_quality=1 then '优质活动'
        else '非优质活动' end as `是否优质活动`,
    sum(b.meituan_number) as `美团活动名额`,
    sum(b.eleme_number) as `饿了么活动名额`,
    count(a.order_id) as `有效订单量`,
    count(distinct a.user_id) as `有效订单用户量`
from dwd.dwd_hive_silkworm_promotion_order a -- 订单
left join dwd.dwd_store_promotion_in_created_at b  -- 店铺活动
    on a.store_promotion_id=b.id 
        and concat(b.year,'-',LPAD(b.month,2,'0'),'-',LPAD(b.day,2,'0')) between '2024-01-01' and date_sub(current_date,1)
        and b.status=1
left join dim.dim_store c -- 店铺
    on b.store_id=c.id
        and concat(b.year,'-',LPAD(b.month,2,'0'),'-',LPAD(b.day,2,'0')) between '2024-01-01' and date_sub(current_date,1)
        and b.status=1
where concat(a.year,'-',LPAD(a.month,2,'0'),'-',LPAD(a.day,2,'0')) between '2024-01-01' and date_sub(current_date,1)
    and a.order_status in (2,8)
    -- and c.city='上海市'
    and a.store_promotion_id<>0
group by 1,2,3,4,5,6



