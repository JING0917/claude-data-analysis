============== 销单明细 探店
with t0 as (
select left(begin_time,10) as begin_date
      ,promotion_id
      ,bd_id
      -- ,bargain_original_price      -- 砍价原价
      -- ,bargain_base_price          -- 砍价底价
    --   ,pay_amt                     -- 团购价    
      ,case when sub_category_type = 0 then '未知'   
            when sub_category_type = 1 then '包子粥铺'
            when sub_category_type = 2 then '汉堡西餐'
            when sub_category_type = 3 then '火锅烧烤'
            when sub_category_type = 4 then '快餐简餐'
            when sub_category_type = 5 then '理发/男士'
            when sub_category_type = 6 then '亲子/乐园'
            when sub_category_type = 7 then '水果生鲜'
            when sub_category_type = 8 then '甜品饮品'
            when sub_category_type = 9 then '休闲/玩乐'
            when sub_category_type = 10 then '炸串小吃'
            when sub_category_type = 11 then '正餐/多人餐'
       end  as sub_category_type             -- 餐品分类
      ,case when demand_promotion_type = 0 then '无要求'
              when demand_promotion_type = 1 then '大众点评'
              when demand_promotion_type = 2 then '小红书'
        end as platform                     -- 平台
      ,case when demand_promotion_type = 0 then '无要求'
              when demand_promotion_type = 1 then demand_dp_user_lvl
              when demand_promotion_type = 2 then demand_xiaohongshu_fans_num
        end as promotion_request               -- 活动要求
      ,case when demand_xiaohongshu_fans_num >= 1000 or demand_dp_user_lvl >5 then '高级'
            else '素人'
       end as promotion_category
      ,begin_time
      ,tot_promotion_quota
      ,combo_id
      ,store_id
      -- ,contract_id
      ,pay_amt     as group_amt       -- 下单金额(团购价)
      ,rebate_price      -- 反豆金额
      ,pay_amt - rebate_price as Take_home_price  -- 到手价
      ,cost_price        -- 成本价(含笔记)
      ,net_cost_price  --成本价(不含笔记)
      ,recurring_promotion_id
      ,if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) as id
      ,if(begin_time>putaway_time,begin_time,putaway_time) as actual_begin_time
from dwd.dwd_sr_silkworm_explore_promotion
where promotion_type in (1,4)
-- and left(begin_time,10) <= $end_date$ and left(end_time,10) >= $start_date$
 and left(begin_time,10) between $start_date$ and $end_date$
-- and left(begin_time,10) between '2025-04-08' and '2025-04-09'
-- and promotion_id = 424792 
)
-- ,t1 as (
-- select t0.*
--       ,left(actual_begin_time,10) as begin_date
-- from t0
-- -- where left(actual_begin_time,10) between left(date_sub(current_date,14),10) and left(date_sub(current_date,1),10)
-- -- where left(actual_begin_time,10) between $start_date$ and $end_date$
-- )
,t2 as (
select county_name          -- 区县
      ,business_district    -- 商圈
      ,store_id             -- 店铺id
      ,address_detail       -- 店铺地址
      ,store_name           -- 店铺名称
      ,city_name            -- 城市
   --   ,province_name        -- 省份
from dim.dim_silkworm_explore_store
where store_id in (select distinct store_id from t0)
)
,t3 as (
select a.store_promotion_id
      ,a.actual_pay_amt
      ,a.order_id
      ,if(b.promotion_type = 1,pay_time,a.create_time) as pay_time
      ,a.verify_time
      ,a.status
      ,a.real_rebate_amt
from (
select store_promotion_id
      ,pay_amt   as actual_pay_amt     -- 支付金额
      ,order_id
      ,pay_time       -- 支付时间
      ,verify_time    -- 核销时间
      ,create_time
      ,status
      ,real_rebate_amt
from dwd.dwd_sr_silkworm_explore_order
where store_promotion_id in (select distinct promotion_id from t0)
)a 
join dwd.dwd_sr_silkworm_explore_promotion b 
on a.store_promotion_id = b.promotion_id
)
,t4 as (
select combo_id
      ,combo_name
from dwd.dwd_sr_silkworm_explore_combo 
where combo_id in (select combo_id from t0)
)
,t5 as (
select statistics_date
      ,user_id
      ,activity_id
from dws.dws_sr_traffic_user_d
where statistics_date >= left(date_sub(current_date,30),10)
and if_view_storediscovery > 0
)
,t51 as (
select id
      ,min(left(begin_time,10)) as first_begin_time
from (
select if(recurring_promotion_id <>0,recurring_promotion_id,promotion_id) as id
      ,begin_time
from dwd.dwd_sr_silkworm_explore_promotion
where recurring_promotion_id in (select distinct recurring_promotion_id from t0)
or promotion_id in (select distinct promotion_id from t0)
) a 
group by 1
)
,t52 as (
select t0.id
      ,count(case when left(verify_time,10)= left(begin_time,10) then order_id end) as hx_order_num
      ,count(case when status in (5,19,20,35) and left(finish_time,10)= left(begin_time,10)then order_id end) as finish_order_num
from t0
left join dwd.dwd_sr_silkworm_explore_order a 
on t0.promotion_id = a.store_promotion_id
group by 1
)

,t6 as (
select 
        begin_date as '活动开始日期'
       ,store_id
       ,combo_id as '套餐ID'
       ,recurring_promotion_id
       ,promotion_id as '活动ID'
       ,element_at(array_remove(array_agg(store_name),0),1) as '店铺名称'
       ,element_at(array_remove(array_agg(city_name),0),1) as city
       ,element_at(array_remove(array_agg(county_name),0),1) as '区县'
       ,element_at(array_remove(array_agg(business_district),0),1) as '商圈'
       ,element_at(array_remove(array_agg(address_detail),0),1) as '店铺地址'
       ,coalesce(element_at(array_remove(array_agg(combo_name),0),1),'') as '套餐名称'
       ,element_at(array_remove(array_agg(sub_category_type),0),1) as '二级类目'
       ,element_at(array_remove(array_agg(platform),0),1) as '平台'
       ,sum(promotion_request) as '活动要求'
       ,element_at(array_remove(array_agg(promotion_category),0),1) as '活动分类'
       ,element_at(array_remove(array_agg(begin_time),0),1) as '首次发布活动时间'
       ,coalesce(element_at(array_remove(array_agg(user_nickname),0),1),'') as user_nickname
       ,sum(group_amt) as '团购价'
       ,sum(cost_price) as '成本价(含笔记)'
       ,sum(net_cost_price) as '成本价(不含笔记)'
       ,sum(rebate_price) as '返利金额'
       ,sum(Take_home_price) as '到手价'
       ,sum(tot_promotion_quota) as '活动总名额'
       ,sum(pay_promotion_quota) as '支付名额(不含退款)'
       ,sum(tot_pay_promotion_quota) as '支付名额(含退款)'
       ,sum(gmv) as 'GMV'
       ,sum(hx_promotion_quota) as '累计核销名额数'
       ,sum(finish_promotion_quota) as '累计完单名额数'
       ,coalesce(sum(gmv)/sum(acc_group_amt),0) as '折扣率'
       ,sum(uv) as '访问UV'
from (
select distinct begin_date
       ,t0.store_id
       ,t0.combo_id
       ,t0.recurring_promotion_id
       ,promotion_id
       ,store_name
       ,city_name
       ,county_name
       ,business_district
       ,address_detail
       ,combo_name
       ,sub_category_type
       ,platform
       ,promotion_request
       ,promotion_category
       ,first_begin_time as begin_time
       ,user_nickname
       ,group_amt
       ,rebate_price
       ,Take_home_price
       ,tot_promotion_quota
       ,0 as pay_promotion_quota
       ,0 as tot_pay_promotion_quota
       ,0 as gmv
       ,0 as acc_group_amt
       ,hx_order_num as hx_promotion_quota
       ,finish_order_num as finish_promotion_quota
       ,0 as uv
       ,cost_price -- 成本价(含笔记)
       ,net_cost_price  --成本价(不含笔记)
from t0
left join dim.dim_silkworm_staff a 
on t0.bd_id = a.bd_id 
left join t2
on t0.store_id = t2.store_id
left join t4 
on t0.combo_id = t4.combo_id
left join t51 
on t0.id =  t51.id
left join t52 
on t0.id = t52.id
-- group by 1,2,3,4,5

-- union all

-- select distinct begin_date
--        ,store_id
--        ,combo_id
--        ,recurring_promotion_id
--        ,promotion_id
--        ,store_name
--        ,city_name
--        ,county_name
--        ,business_district
--        ,address_detail
--        ,combo_name
--        ,0,0,0,0,0,0,0,0,0,0,0
-- from (select distinct begin_date,store_id,combo_id from t1) t1
-- left join t2
-- on t1.store_id = t2.store_id
-- left join t4 
-- on t1.combo_id = t4.combo_id

union all 

select  begin_date
       ,store_id
       ,combo_id
       ,recurring_promotion_id
       ,promotion_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status not in (1,2,6,7,8,9,10,21) then order_id end) as pay_promotion_quota
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') then order_id end) as tot_pay_promotion_quota
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status not in (1,2,6,7,8,9,10,21) then actual_pay_amt-real_rebate_amt end) as gmv
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status not in (1,2,6,7,8,9,10,21) then group_amt end) as acc_group_amt
    --    ,count(distinct case when begin_date = left(verify_time,10) then order_id end) as hx_promotion_num
    --    ,count(distinct case when status in (5,19,20,35) then order_id end) as finish_promotion_num
       ,0,0,0,0,0
from t0
left join t3 
on t0.promotion_id = t3.store_promotion_id
group by 1,2,3,4,5

union all 

select  begin_date
       ,store_id
       ,combo_id
       ,recurring_promotion_id
       ,promotion_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct user_id) as uv
       ,0,0
from t0
left join t5
on t0.promotion_id = t5.activity_id
group by 1,2,3,4,5 
) a 
group by 1,2,3,4,5
) 
select * from t6 
where user_nickname not like '%测试%' and user_nickname <> ''
and city not like '%阿里地区%' and city not like '%西藏%'
<#if STORE_ID != 0>
        AND store_id IN (${STORE_ID})
</#if>



============== 销单明细 砍价&合约

with t0 as (
select id
from dwd.dwd_sr_contract_h
where name regexp '测试'
-- and status = 2 -- 进行中
)
,t00 as (
select
    city_name
from dim.dim_silkworm_explore_city
where province_name<>'新疆维吾尔族自治区' -- 剔除测试省份
    and status=1 -- 正常
    and promotion_type in ('101','111')
group by 1
)
,t1 as (
select left(begin_time,10) as begin_date
      ,JSON_KEYS(store_detail) as id
      ,promotion_id
      ,bd_id
      ,bargain_original_price      -- 砍价原价
      ,bargain_base_price          -- 砍价底价
      ,pay_amt                     -- 团购价    
      ,case when sub_category_type = 0 then '未知'   
            when sub_category_type = 1 then '包子粥铺'
            when sub_category_type = 2 then '汉堡西餐'
            when sub_category_type = 3 then '火锅烧烤'
            when sub_category_type = 4 then '快餐简餐'
            when sub_category_type = 5 then '理发/男士'
            when sub_category_type = 6 then '亲子/乐园'
            when sub_category_type = 7 then '水果生鲜'
            when sub_category_type = 8 then '甜品饮品'
            when sub_category_type = 9 then '休闲/玩乐'
            when sub_category_type = 10 then '炸串小吃'
            when sub_category_type = 11 then '正餐/多人餐'
       end  as sub_category_type             -- 餐品分类
      ,begin_time
      ,end_time
      ,tot_promotion_quota
      ,combo_id
      ,store_id
      ,contract_id
      ,promotion_type
      ,recurring_promotion_id
      ,bargain_num  -- 砍价刀数
    --   ,if(begin_time>putaway_time,begin_time,putaway_time) as actual_begin_time
    --   ,left(if(begin_time>putaway_time,begin_time,putaway_time),10) as begin_date
from dwd.dwd_sr_silkworm_explore_promotion
--  where left(begin_time,10) <= $end_date$ and left(end_time,10) >= $start_date$
where left(begin_time,10) between $start_date$ and $end_date$
-- where left(begin_time,10) between '2025-04-08' and '2025-04-09' 
and promotion_type in (5,6) 
and contract_id not in (select * from t0)
and store_promotion_name not like '%测试%'
)
,t11 as(
select t1.*
      ,cast(cast(tt.value as string) as bigint) as hx_store_id
from t1,LATERAL JSON_EACH(ifnull(id,'[0]')) as tt
)
,t12 as (
select begin_date
      ,promotion_id
      ,bd_id
      ,bargain_original_price      -- 砍价原价
      ,bargain_base_price          -- 砍价底价
      ,pay_amt                     -- 团购价    
      ,sub_category_type           -- 餐品分类
      ,begin_time
      ,tot_promotion_quota
      ,combo_id
      ,contract_id
      ,case when promotion_type = 5 then '砍价'
            when promotion_type = 6 then '合约'
       end as promotion_type
      ,recurring_promotion_id
      ,bargain_num
      ,if(promotion_type = 5,store_id,hx_store_id) as store_id
from(
select begin_date
      ,promotion_id
      ,bd_id
      ,bargain_original_price      -- 砍价原价
      ,bargain_base_price          -- 砍价底价
      ,pay_amt                     -- 团购价    
      ,sub_category_type           -- 餐品分类
      ,begin_time
      ,tot_promotion_quota
      ,combo_id
      ,store_id
      ,contract_id
      ,promotion_type
      ,recurring_promotion_id
      ,bargain_num
      ,group_concat(hx_store_id) as hx_store_id
from t11
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
) a
)

,t2 as ( 
select county_name          -- 区县
      ,business_district    -- 商圈
      ,store_id             -- 店铺id
      ,address_detail       -- 店铺地址
      ,store_name           -- 店铺名称
      ,city_name            -- 城市
   --   ,province_name        -- 省份
from dim.dim_silkworm_explore_store
where store_id in (select distinct hx_store_id from t11)
or store_id in (select distinct store_id from t11)
-- and city_name in (select * from t00)
)
,t3 as (
select store_promotion_id
      ,pay_amt   as actual_pay_amt     -- 支付金额
      ,order_id
      ,pay_time       -- 支付时间
      ,verify_time    -- 核销时间
      ,status
      ,red_pack_reward_num/100  as red_pack_reward_num
from dwd.dwd_sr_silkworm_explore_order
where store_promotion_id in (select distinct promotion_id from t11)
)
,t4 as (
select combo_id
      ,combo_name
from dwd.dwd_sr_silkworm_explore_combo
where combo_id in (select combo_id from t11)
)
-- ,t5 as (
-- select statistics_date
--       ,user_id
--       ,activity_id
-- from dws.dws_sr_traffic_user_d
-- where bargain_detailpage_expose_num <> 0
-- )
,t5 as (
select statistics_date
      ,user_id
      ,activity_id
from dws.dws_sr_traffic_user_d
where if_view_bargain > 0 
)
,t51 as (
select recurring_promotion_id
      ,min(begin_time) as first_begin_time
from dwd.dwd_sr_silkworm_explore_promotion
where recurring_promotion_id in (select distinct recurring_promotion_id from t12)
group by 1
)
,t52 as (
select t1.recurring_promotion_id
      ,left(begin_time,10) as begin_date
      ,count(case when left(verify_time,10)= left(begin_time,10) then order_id end) as hx_order_num
from t1
left join dwd.dwd_sr_silkworm_explore_order a 
on t1.promotion_id = a.store_promotion_id
group by 1,2
)
,t6 as (
select  begin_date as '活动开始日期'
       ,promotion_id as '活动ID'
       ,recurring_promotion_id as '循环活动ID'
       ,contract_id as '合约ID'
       ,combo_id as '套餐ID'
       ,element_at(array_remove(array_agg(store_id),0),1) as store_id
    --    ,element_at(array_remove(array_agg(promotion_id),0),1) as '活动ID'
    --    ,element_at(array_remove(array_agg(recurring_promotion_id),0),1) as '循环活动ID'
       ,'合约' as '业务类型'
       ,element_at(array_remove(array_agg(store_name),0),1) as '店铺名称'
       ,element_at(array_remove(array_agg(city_name),0),1) as city
       ,element_at(array_remove(array_agg(county_name),0),1) as '区县'
       ,element_at(array_remove(array_agg(business_district),0),1) as '商圈'
       ,element_at(array_remove(array_agg(address_detail),0),1) as '店铺地址'
       ,coalesce(element_at(array_remove(array_agg(combo_name),0),1),'') as '套餐名称'
       ,element_at(array_remove(array_agg(sub_category_type),0),1) as '二级类目'
       ,element_at(array_remove(array_agg(left(begin_time,10)),0),1) as '首次发布活动时间'
       ,coalesce(element_at(array_remove(array_agg(user_nickname),0),1),'') as user_nickname
       ,sum(bargain_original_price) as '砍价原价'
       ,sum(bargain_base_price) as '砍价底价'
       ,sum(group_amt) as '团购价'
       ,sum(pay_amt) as 'GMV' -- '支付金额'
       ,sum(tot_promotion_quota) as '活动总名额'
       ,sum(pay_promotion_quota) as '支付名额(不含退款)'
       ,sum(tot_pay_promotion_quota) as '支付名额(含退款)'
       ,sum(hx_promotion_quota) as '累计核销名额数'
       ,coalesce(sum(pay_amt)/sum(group_amt)/sum(pay_promotion_quota),0) as '折扣率'
    --    ,coalesce(sum(bargain_base_price)/sum(group_amt),0) as '预估折扣率'
    --    ,sum(uv) as '商详uv'
       ,sum(view_uv) as '访问UV'
       ,sum(bargain_num) as '砍价次数'
from (
select distinct t12.begin_date
       ,promotion_id
       ,t12.recurring_promotion_id
       ,contract_id
       ,combo_id
       ,0 as store_id
       ,0 as store_name 
       ,0 as city_name
       ,0 as county_name
       ,0 as business_district
       ,0 as address_detail
       ,0 as combo_name
       ,sub_category_type
       ,first_begin_time as begin_time
       ,user_nickname
       ,bargain_original_price
       ,bargain_base_price
       ,pay_amt as group_amt
       ,0 as pay_amt
       ,tot_promotion_quota
       ,0 as pay_promotion_quota
       ,0 as tot_pay_promotion_quota
       ,hx_order_num as hx_promotion_quota
       ,0 as actual_discount_rate
    --    ,0 as uv
       ,0 as view_uv
       ,bargain_num
from (select * from t12 where promotion_type = '合约')t12
left join dim.dim_silkworm_staff a 
on t12.bd_id = a.bd_id 
-- group by 1,2,3,4,5
left join t51 
on t12.recurring_promotion_id =  t51.recurring_promotion_id
left join t52 
on t12.recurring_promotion_id =  t52.recurring_promotion_id and t12.begin_date = t52.begin_date

union all

select  begin_date
       ,t11.promotion_id
       ,t11.recurring_promotion_id
       ,t11.contract_id
       ,t11.combo_id
       ,group_concat(distinct t2.store_id)
       ,group_concat(distinct store_name)
       ,group_concat(distinct city_name)
       ,group_concat(distinct county_name)
       ,group_concat(distinct business_district)
       ,group_concat(distinct address_detail)
       ,group_concat(distinct combo_name)
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    --    ,0
from (select * from t11 where promotion_type = 6)t11
left join t2
on t11.hx_store_id = t2.store_id
left join t4 
on t11.combo_id = t4.combo_id 
group by 1,2,3,4,5

union all 

select  begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36)then actual_pay_amt+red_pack_reward_num end) 
       ,0
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then order_id end) as pay_promotion_quota
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') then order_id end) as tot_pay_promotion_quota
    --    ,count(distinct case when begin_date = left(verify_time,10) then order_id end) as hx_promotion_quota
       ,0
       ,coalesce(sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then actual_pay_amt+red_pack_reward_num end)/sum(pay_amt)/count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00')  and status in (3,5,36) then order_id end),0) as actual_discount_rate
       ,0,0
    --    ,0
from (select * from t12 where promotion_type = '合约')t12
left join t3 
on t12.promotion_id = t3.store_promotion_id
group by 1,2,3,4,5

union all 

select  begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct case when begin_date = statistics_date then user_id end) as view_uv
       ,0
    --    ,0
from (select * from t12 where promotion_type ='合约')t12
left join t5
on t12.promotion_id = t5.activity_id
group by 1,2,3,4,5

-- union all 

-- select  begin_date
--        ,t12.promotion_id
--        ,t12.recurring_promotion_id
--        ,t12.contract_id
--        ,t12.combo_id
--        ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
--        ,count(distinct user_id) as view_uv
-- from (select * from t12 where promotion_type ='合约')t12
-- left join t55
-- on t12.promotion_id = t55.activity_id
-- group by 1,2,3,4,5
) a 
-- where (user_nickname not like '%测试%' and user_nickname <> '')
group by 1,2,3,4,5

union all  -- 砍价

select  begin_date
       ,promotion_id as '活动ID'
       ,recurring_promotion_id as '循环活动ID'
       ,contract_id as '合约ID'
       ,combo_id as '套餐ID'
       ,store_id
    --    ,element_at(array_remove(array_agg(promotion_id),0),1) as promotion_id
    --    ,element_at(array_remove(array_agg(recurring_promotion_id),0),1) as recurring_promotion_id
       ,'砍价' as promotion_type
       ,element_at(array_remove(array_agg(store_name),0),1) as store_name
       ,element_at(array_remove(array_agg(city_name),0),1) as city_name
       ,element_at(array_remove(array_agg(county_name),0),1) as county_name
       ,element_at(array_remove(array_agg(business_district),0),1) as business_district
       ,element_at(array_remove(array_agg(address_detail),0),1) as address_detail
       ,coalesce(element_at(array_remove(array_agg(combo_name),0),1),'') as combo_name
       ,element_at(array_remove(array_agg(sub_category_type),0),1) as sub_category_type
       ,element_at(array_remove(array_agg(left(begin_time,10)),0),1) as begin_time
       ,coalesce(element_at(array_remove(array_agg(user_nickname),0),1),'') as user_nickname
       ,sum(bargain_original_price) as bargain_original_price
       ,sum(bargain_base_price) as bargain_base_price
       ,sum(group_amt) as group_amt
       ,sum(pay_amt) as pay_amt
       ,sum(tot_promotion_quota) as tot_promotion_quota
       ,sum(pay_promotion_quota) as pay_promotion_quota
       ,sum(tot_pay_promotion_quota) as tot_pay_promotion_quota
       ,sum(hx_promotion_quota) as hx_promotion_quota
       ,coalesce(sum(pay_amt)/sum(group_amt)/sum(pay_promotion_quota),0) as actual_discount_rate
    --    ,coalesce(sum(bargain_base_price)/sum(group_amt),0) as discount_rate
    --    ,sum(uv) as click_uv
       ,sum(view_uv) as view_uv
       ,sum(bargain_num) as bargain_num
from (
select distinct  t1.begin_date
       ,t1.promotion_id
       ,t1.recurring_promotion_id
       ,t1.contract_id
       ,t1.combo_id
       ,t1.store_id
    --    ,group_concat(distinct promotion_id) as promotion_id
    --    ,group_concat(distinct recurring_promotion_id) as recurring_promotion_id
       ,store_name 
       ,city_name
       ,county_name
       ,business_district
       ,address_detail
       ,combo_name
       ,sub_category_type
       ,first_begin_time as begin_time
       ,user_nickname
       ,bargain_original_price
       ,bargain_base_price
       ,pay_amt as group_amt
       ,0 as pay_amt
       ,tot_promotion_quota
       ,0 as pay_promotion_quota
       ,0 as tot_pay_promotion_quota
       ,hx_order_num as hx_promotion_quota
       ,0 as actual_discount_rate
    --    ,0 as uv
       ,0 as view_uv
       ,bargain_num
from (select * from t1 where promotion_type = '5')t1
left join dim.dim_silkworm_staff a 
on t1.bd_id = a.bd_id 
left join t2
on t1.store_id = t2.store_id
left join t4 
on t1.combo_id = t4.combo_id
left join t51 
on t1.recurring_promotion_id =  t51.recurring_promotion_id
left join t52 
on t1.recurring_promotion_id =  t52.recurring_promotion_id and t1.begin_date = t52.begin_date

union all 

select  begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,t12.store_id
       ,0,0,0,0,0,0,0,0,0,0,0,0
       ,sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then actual_pay_amt+red_pack_reward_num end) 
       ,0
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then order_id end) as pay_promotion_quota
       ,count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') then order_id end) as tot_pay_promotion_quota
    --    ,count(distinct case when begin_date = left(verify_time,10) then order_id end) as hx_promotion_quota
       ,0
       ,coalesce(sum(case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00') and status in (3,5,36) then actual_pay_amt+red_pack_reward_num end)/sum(pay_amt)/count(distinct case when pay_time between concat(left(date_sub(begin_date,7),10),' 00:00:00') and concat(left(date_add(begin_date,1),10),' 00:05:00')  and status in (3,5,36)then order_id end),0) as actual_discount_rate
       ,0,0
from (select * from t12 where promotion_type = '砍价')t12
left join t3 
on t12.promotion_id = t3.store_promotion_id
group by 1,2,3,4,5,6

union all 

select  begin_date
       ,t12.promotion_id
       ,t12.recurring_promotion_id
       ,t12.contract_id
       ,t12.combo_id
       ,t12.store_id
       ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       ,count(distinct case when begin_date = statistics_date then user_id end) as uv
       ,0
    --    ,0
from (select * from t12 where promotion_type = '砍价')t12
left join t5
on t12.promotion_id = t5.activity_id
group by 1,2,3,4,5,6

-- union all 

-- select  begin_date
--        ,t12.promotion_id
--        ,t12.recurring_promotion_id
--        ,t12.contract_id
--        ,t12.combo_id
--        ,t12.store_id
--        ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
--        ,count(distinct user_id) as uv
-- from (select * from t12 where promotion_type = '砍价')t12
-- left join t55
-- on t12.promotion_id = t55.activity_id
-- group by 1,2,3,4,5,6
) a 
-- where user_nickname not like '%测试%' and user_nickname <> ''
group by 1,2,3,4,5,6
) 
select * from t6 
where user_nickname not like '%测试%' and user_nickname <> ''
and city not like '%阿里地区%' and city not like '%西藏%'
<#if STORE_ID != 0>
        AND store_id IN (${STORE_ID})
</#if>

















