
-- 完单数≥15单且近30天没有完单过的用户人数
select 
    -- user_id,
    -- accu_valid_order_num,
    -- latest_valid_order_time
    count(1) as unum
from dim.dim_silkworm_user
where accu_valid_order_num>=15
    and datediff(date_sub(current_date(),interval 1 day),latest_valid_order_time)>30
;


-- 统计周期内下单和利润
select
    count(distinct user_id) as `下单用户量`,
    count(1) as `下单量`,
    count(distinct if(order_status in (2,8),user_id,null)) as `有效订单用户量`,
    count(if(order_status in (2,8),auto_id,null)) as `有效订单量`,
    sum(if(order_status=2,profit,0)) as `有效订单利润(不含待改进订单)`,
    sum(if(order_status in (2,8),profit,0)) as `有效订单利润`
from dwd.dwd_sr_order_promotion_order
where dt between '2023-12-01' and '2024-12-31'
    and substr(order_time,1,10) between '2024-01-01' and '2024-12-31'
;


-- 不会同时出现同一个活动在三个平台都有的情况
select 
    store_promotion_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    jd_order_amt,
    jd_mlabel_rebate_amt,
    meituan_promotion_quota,
    eleme_promotion_quota,
    jd_promotion_quota
from dwd.dwd_sr_store_promotion
where dt between '2025-04-24' and '2025-05-07'
    and status in (1,4,5)
    and meituan_mlabel_rebate_amt>0 
    and eleme_mlabel_rebate_amt>0 
    and jd_mlabel_rebate_amt>0
limit 10
;


-- 店铺活动

SELECT `餐标`,
       sum(`活动名额`) `活动名额`,
       sum(`销单量`) `销单量`
FROM (
      -- 美团
      SELECT '美团' `类型`,
                  CASE
                      WHEN promotion_rebate_type=0 THEN concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
                      WHEN promotion_rebate_type=1 THEN concat('最高返',mlabel_rebate_amt)
                      ELSE '其他'
                  END `餐标`,
                  sum(promotion_quota) `活动名额`,
                  sum(finord_num) `销单量`
      FROM
        (SELECT store_promotion_id,
                cast(meituan_order_amt AS string) AS mlabel_threshold_amt,
                cast(meituan_mlabel_rebate_amt AS string) AS mlabel_rebate_amt,
                promotion_rebate_type,
                meituan_promotion_quota AS promotion_quota,
                meituan_finished_num AS finord_num
         FROM dwd.dwd_sr_store_promotion
         WHERE dt BETWEEN date_sub(current_date(),interval 240 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND date_format(begin_date,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 181 DAY) AND date_sub(current_date(),interval 2 DAY)
           AND status IN (1,
                          4,
                          5)
           AND meituan_mlabel_rebate_amt<>0) a
      GROUP BY 1,2

      UNION ALL 
      -- 饿了么
      SELECT '饿了么' `类型`,
                   CASE
                       WHEN promotion_rebate_type=0 THEN concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
                       WHEN promotion_rebate_type=1 THEN concat('最高返',mlabel_rebate_amt)
                       ELSE '其他'
                   END `餐标`,
                   sum(promotion_quota) `活动名额`,
                   sum(finord_num) `销单量`
      FROM
        (SELECT store_promotion_id,
                cast(eleme_order_amt AS string) AS mlabel_threshold_amt,
                cast(eleme_mlabel_rebate_amt AS string) AS mlabel_rebate_amt,
                promotion_rebate_type,
                eleme_promotion_quota AS promotion_quota,
                eleme_finished_num AS finord_num
         FROM dwd.dwd_sr_store_promotion
         WHERE dt BETWEEN date_sub(current_date(),interval 240 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND date_format(begin_date,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 181 DAY) AND date_sub(current_date(),interval 2 DAY)
           AND status IN (1,
                          4,
                          5)
           AND eleme_mlabel_rebate_amt<>0) a
      GROUP BY 1,2

      UNION ALL 
      -- 京东
      SELECT '京东' `类型`,
                  CASE
                      WHEN promotion_rebate_type=0 THEN concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
                      WHEN promotion_rebate_type=1 THEN concat('最高返',mlabel_rebate_amt)
                      ELSE '其他'
                  END `餐标`,
                  sum(promotion_quota) `活动名额`,
                  sum(finord_num) `销单量`
      FROM
        (SELECT store_promotion_id,
                cast(jd_order_amt AS string) AS mlabel_threshold_amt,
                cast(jd_mlabel_rebate_amt AS string) AS mlabel_rebate_amt,
                promotion_rebate_type,
                jd_promotion_quota AS promotion_quota,
                jd_finished_num AS finord_num
         FROM dwd.dwd_sr_store_promotion
         WHERE dt BETWEEN date_sub(current_date(),interval 240 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND date_format(begin_date,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 181 DAY) AND date_sub(current_date(),interval 2 DAY)
           AND status IN (1,
                          4,
                          5)
           AND jd_mlabel_rebate_amt<>0) a
      GROUP BY 1,2) tot
GROUP BY 1;





============= 霸王餐活动和订单
with t1 as (
select
    store_promotion_id,
    a.store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type,
    sub_category_type,
    store_brand_type,
    delivery_type,
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel,
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    sum(promotion_quota) over(partition by case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end) as acc_promotion_quota -- 累计活动名额
from (
select 
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
    is_youzhi_promotion -- 0:否,1:是
from dwd.dwd_sr_store_promotion
where dt between '2024-06-01' and '2024-07-31'
                and begin_date between '2024-07-01' and '2024-07-01'
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
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
where cast(dt as string) between '2024-06-01' and '2024-07-31'
    and substr(order_time,1,10) between '2024-07-01' and '2024-07-31'
    and store_promotion_id>0
group by 1
)



select
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type,
    sub_category_type,
    store_brand_type,
    delivery_type,
    mlabel,
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    acc_promotion_quota, -- 累计活动名额
    promotion_quota/acc_promotion_quota as quota_rate,
    order_num, -- 下单量
    valid_order_num, -- 有效下单量
    acc_order_num, -- 累计下单量
    acc_valid_order_num, -- 累计有效下单量
    order_num/acc_order_num as order_rate,
    valid_order_num/acc_valid_order_num as valid_order_rate,
    if(coalesce(order_num/promotion_quota,0)>1,1,coalesce(order_num/promotion_quota,0)) as xd_rate,
    if(coalesce(valid_order_num/promotion_quota,0)>1,1,coalesce(valid_order_num/promotion_quota,0)) as valid_xd_rate
from (
select
    t1.store_promotion_id,
    t1.store_id,
    t1.promotion_rebate_type, -- 0:霸王餐,1:返利餐
    t1.category_type,
    t1.sub_category_type,
    t1.store_brand_type,
    t1.delivery_type,
    t1.mlabel,
    t1.rebate_rate, -- 返现比例
    t1.promotion_quota, -- 活动名额
    t1.is_threshold, -- 是否有门槛 1:是,0:否
    t1.is_need_rating, -- 是否需要评价 1:是,0:否
    t1.is_virtual, -- 0:否,1:是
    t1.is_miaosha, -- 0:否,1:是
    t1.is_private, -- 0:否,1:是
    t1.is_vip_exclusive, -- 0:否,1:是
    t1.is_youzhi_promotion, -- 0:否,1:是
    t1.acc_promotion_quota, -- 累计活动名额
    t1.promotion_quota/t1.acc_promotion_quota as quota_rate,
    order_num, -- 下单量
    valid_order_num, -- 有效下单量
    sum(order_num) over(partition by mlabel order by mlabel) as acc_order_num, -- 累计下单量
    sum(valid_order_num) over(partition by mlabel order by mlabel) as acc_valid_order_num -- 累计有效下单量
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
) a
;


===================== 杭州探店核销用户中，首单用户
show create table dim.dim_silkworm_explore_daren_cleanse;

show create table dwd.dwd_sr_silkworm_explore_order;

select * from dwd.dwd_sr_silkworm_explore_order limit 10;

show create table dim.dim_silkworm_explore_store;

select * from dim.dim_silkworm_explore_store limit 10;

show create table dws.dws_sr_traffic_user_d;
show create table dwd.dwd_sr_silkworm_explore_promotion;

-- 探店首单用户
with t1 as (
select 
    a.user_id
from dim.dim_silkworm_explore_daren_cleanse a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and b.city_id=3301 -- 杭州
where substr(a.first_explode_order_date,1,10) between '2024-09-21' and '2024-09-22'
)

select
    a.user_id
from
(select 
    user_id
from dwd.dwd_sr_silkworm_explore_order
where date(dt)<=date_sub(current_date,interval 1 day)
    and substr(verify_time,1,10) between '2024-09-21' and '2024-09-22'
group by user_id) a
inner join t1 on a.user_id=t1.user_id
;


=================== 下单并核销
-- 杭州探店核销订单量
select
    a.dat as `统计日期`,
    b.city_name as `城市`,
    b.county_name as `区县`,
    sum(a.quota) as `活动名额`,
    sum(a.hx_order_num) as `核销订单量`
from
(select
    dat,
    store_id,
    sum(quota) as quota,
    sum(hx_order_num) as hx_order_num
from
    -- 探店核销订单量和活动名额
        (select 
            date(dt) as dat,
            store_id,
            0 as quota,
            count(order_id) as hx_order_num
        from dwd.dwd_sr_silkworm_explore_order
        where cast(date(dt) as string) between '2024-09-16' and '2024-09-22'
            and substr(verify_time,1,10) between '2024-09-16' and '2024-09-22'
        group by 1,2

        union all
        select
            dt as dat,
            store_id,
            sum(tot_promotion_quota) as quota,
            0 as hx_order_num
        from dwd.dwd_sr_silkworm_explore_promotion
        where cast(date(dt) as string) between '2024-09-16' and '2024-09-22'
            and substr(begin_time,1,10) between '2024-09-16' and '2024-09-22'
            and promotion_type in (1,4)
        group by 1,2
    ) a1
    group by 1,2
) a
inner join dim.dim_silkworm_explore_store b
on a.store_id=b.store_id 
    and b.city_name='杭州市'
group by 1,2,3
;
===================== 杭州探店核销用户中，首单用户



============= 超时取消订单
show create table dwd.dwd_sr_order_promotion_order;

-- select 
--     order_id,user_id
-- from dwd.dwd_sr_order_promotion_order
-- where dt>=date_sub(current_date(),interval 3 day)
--     and (substr(order_time,1,10)='2024-09-25'
--         or substr(order_submit_audit_time,1,13) between '2024-09-26 09' and '2024-09-26 11')
-- union 

-- select 
--     if(order_log regexp '填入订单号','已填入单号','未填单号') as is_add_orderid,
--     -- length(platform_evaluation_order_screenshot_url) as len_num,
--     length(platform_pic_ocr_result) as len_num,
--     count(1) as cnt
-- from dwd.dwd_sr_order_promotion_order
-- where dt>=date_sub(current_date(),interval 30 day)
--     -- and substr(order_submit_audit_time,1,10)='2024-09-25'
--     and order_status=5 -- 超时取消订单
--     and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
--     and order_log not regexp '填入订单号'
--     and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
-- -- and user_id=923592157
-- -- limit 10
-- group by 1,2 





-- where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between date_sub(current_date,7) and date_sub(current_date,1)
--     and order_status=5 -- 超时取消订单
--     and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
--     -- and length(platform_pic_ocr_result)<=1
--     and length(platform_evaluation_order_screenshot_url)<=1 -- 未提交图文反馈
--     and store_promotion_id>0 -- 非自营
--     and order_type not in (12,13) -- 专版
-- group by 1

-- 第二步超时取消
select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as dat,
    -- now() as run_time,
    order_status,
    -- if(order_log regexp '填入订单号','已填入单号','未填单号') as is_add_orderid,
    -- -- -- length(platform_evaluation_order_screenshot_url) as len_num,
    -- if(rebate_condition_desc regexp '用餐反馈','需反馈','无需反馈') as rebate_condition,
    -- length(platform_pic_ocr_result) as len_num,
    count(1) as cnt
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 3 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
    -- and order_status=5 -- 超时取消订单
    and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
    and order_log regexp '填入订单号'
    and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
    -- and length(platform_evaluation_order_screenshot_url)<=1 -- 未提交图文反馈
group by 1,2
;

select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as `下单日期`,
    now() as `统计时间`,
    count(1) as `总订单量`,
    sum(if(order_status=5,1,0)) as `超时取消订单量`,
    sum(if(order_status=5 
            and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,1,0)) as `第二步超时取消订单量`,
    count(if(order_status<>4 and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,auto_id,0)) as `待提交用餐反馈订单量`,
    count(distinct if(order_status=5,user_id,0)) as `超时取消用户量`,
    count(distinct if(order_status<>4 and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,user_id,0)) as `待提交用餐反馈用户量`
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 3 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
group by 1,2
;


select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date,
    now() as create_time,
    count(1) as order_num,
    count(distinct user_id) as order_user_num,
    count(distinct if(order_status=5,auto_id,0)) as timeout_cancelorder_num,
    count(distinct if(order_status=5,user_id,0)) as timeout_canceluser_num,
    count(distinct if(order_status=5 
            and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,auto_id,0)) as step_2nd_timeout_cancelorder_num,
    count(distinct if(order_status=5 
            and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,user_id,0)) as step_2nd_timeout_canceluser_num,
    count(distinct if(order_status<>4 and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,auto_id,0)) as step_2nd_wait_submitorder_num,
    count(distinct if(order_status<>4 and rebate_condition_desc regexp '用餐反馈' -- 用餐反馈订单
            and order_log regexp '填入订单号' -- 已提交订单号
            and length(platform_pic_ocr_result)<=1 -- 平台识别图片文本结果
            ,user_id,0)) as step_2nd_wait_submituser_num
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 3 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
group by 1,2;

select * from dws.dws_sr_order_timeout_cancelorder_d;

select
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as dat,
    auto_id,
    count(1) as cnt
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 3 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
group by 1,2
having count(1)>1
;


=========== 客服修改订单ID
select 
    -- order_time,order_id,order_log,platform_order_id
    order_log
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-09-01' and '2024-09-25'
    and substr(order_time,1,10) between '2024-09-25' and '2024-09-25'
group by 1
    -- and order_id='202409250996222094867'
    -- and user_id=923592157
;

select
    -- order_date `下单日期`,
    -- sum(if(user_order_id<>kf_modify_order_id,1,0)) as `客服修改订单量`
    order_date `下单日期`,
    concat('单',order_id) as `订单ID`,
    store_promotion_id as `活动ID`,
    order_log as `修改订单日志`,
    concat('单',user_order_id) as `用户填写订单ID`,
    concat('单',kf_modify_order_id) as `客服修改后订单ID`
from
    (select 
        substr(order_time,1,10) as order_date,
        order_id,
        store_promotion_id,
        order_log,
        regexp_extract(order_log, '(填入订单号：)(\\d+)( \\[\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\])', 2) AS user_order_id,
        platform_order_id as kf_modify_order_id
    from dwd.dwd_sr_order_promotion_order
    where cast(dt as string) between '2024-08-25' and '2024-09-26'
        and substr(order_time,1,10) between '2024-09-20' and '2024-09-26'
        and order_log regexp '填入订单号：'
    group by 1,2,3,4,5,6
    ) a
-- group by 1
where user_order_id<>kf_modify_order_id
;

SELECT 
    SUBSTRING(order_log, LOCATE('填入订单号：', order_log) + LENGTH('填入订单号：'), 19) AS order_number
FROM A;

SELECT 
  SUBSTRING(order_log, INSTR(order_log, '填入订单号：') + LENGTH('填入订单号：'), 19) AS order_number
FROM 
  A;


select regexp_extract(order_log, '(填入订单号：)(\\d+)( \\[\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\])', 2)
=========================


=============== 大牌店铺活动下单用户距离
show create table dwd.dwd_sr_order_promotion_order;

-- 大牌店活动下单店铺和用户
with t1 as (
select
    store_id,
    user_id
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 10 day) and date_sub(current_date(),interval 1 day)
    and substr(order_time,1,10) between '2024-09-20' and '2024-09-26'
    and order_status in (2,8)
group by 1,2
) a 
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.store_brand_type=1 -- 大牌
;


================ 活动销单（喜茶/奈雪/酸奶罐罐）
select
    case when b.store_name regexp '奈雪' then '奈雪的茶'
        when b.store_name regexp '喜茶' then '喜茶'
        when b.store_name regexp '酸奶罐罐' then '酸奶罐罐'
        when b.store_name regexp '霸王茶姬' then '霸王茶姬'
        when b.store_name regexp '喜姐炸串' then '喜姐炸串'
    else '其他' end as `品牌`,
    sum(promotion_quota) as `活动名额`,
    sum(finished_num) as `销单量`,
    round(sum(finished_num)/sum(promotion_quota),2) as `销单率`
from
(select
    store_id,
    sum(meituan_promotion_quota+eleme_promotion_quota) as promotion_quota,
    sum(meituan_finished_num+eleme_finished_num) as finished_num
from dwd.dwd_sr_store_promotion
where dt between '2024-10-01' and '2024-11-30'
    and begin_date between '2024-11-01' and '2024-11-30'
    and status in (1,4,5)
    and is_operation_promption=0
group by 1
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.store_name regexp '奈雪|喜茶|酸奶罐罐|霸王茶姬|喜姐炸串'
group by 1;

==================

==================== 牛角 千粉探店活动 
 show create table dwd.dwd_sr_silkworm_explore_promotion;
 show create table dim.dim_silkworm_explore_store;

-- 小红书千粉探店活动
with t1 as (
select
    a.begin_date,
    a.store_id,
    b.store_name,
    a.promotion_id,
    a.tot_promotion_quota,
    a.used_promotion_quota
from (
select  substring(begin_time,1,10) as begin_date,
        store_id,
        -- store_name,
        promotion_id,
        tot_promotion_quota,
        used_promotion_quota
from    dwd.dwd_sr_silkworm_explore_promotion
where   cast(dt as string) between '2024-08-01' and '2024-10-31'
            and str_to_date(substr(begin_time,1,10),'%Y-%m-%d') between '2024-10-01' and '2024-10-31'
            -- and status=1 -- 首次跑数据不限制，以免漏掉已下线数据 20240823调整 修改人：dahe
            and promotion_type in (1,4) -- 探店活动
            and demand_promotion_type=2 -- 2小红书 1点评
            and demand_xiaohongshu_fans_num>=100 -- 千粉
            -- and demand_dp_user_lvl>=5 -- 5级+
            ) a
left join dim.dim_silkworm_explore_store b
on      a.store_id = b.store_id
),

-- 0元到店订单
t2 as (
    select
            store_promotion_id,
            count(distinct if(status in (3,4,5,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,30,31,32,33),order_id,null)) as pay_order_num, -- 支付
            count(distinct if(status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),order_id,null)) as verify_order_num -- 核销
    from    dwd.dwd_sr_silkworm_explore_order
    where   cast(date(dt) as string) between '2024-10-01' and '2024-10-31'
    and store_name not regexp '测试'
    and promotion_type in (1,4)
group by 1
)

select
    t1.begin_date `活动开始日期`,
    t1.store_id `店铺ID`,
    t1.store_name `店铺名称`,
    sum(t1.tot_promotion_quota) `活动名额`,
    sum(t2.pay_order_num) `已支付订单量`,
    sum(t2.verify_order_num) `已核销订单量`
from t1 left join t2 on t1.promotion_id=t2.store_promotion_id
group by 1,2,3
;

========================

======================================

select 
    *
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
    and order_status=5 
    and order_log regexp '填入订单号'
;

-- 霸王餐订单统计
select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date, -- 下单日期
    store_promotion_id,
    count(order_id) as order_num, -- 订单量
    count(if(order_status in (2,8),order_id,null)) as valid_order_num, -- 有效订单量
    count(if(t1.order_status=5,t1.order_id,null)) as order_timeout_cancel_num, -- 超时取消订单量
    count(if(t1.order_status=4,t1.order_id,null)) as order_hand_cancel_num, -- 手动取消订单量
    count(if(t1.order_status=8,t1.order_id,null)) as order_pass_unsatisfactory_num, -- 已审核待改进订单量
    count(if(t1.order_status=12,t1.order_id,null)) as order_revive_num, -- 复活券订单量
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
group by 1,2
;

count(if(t1.order_status=2,t1.order_id,null)) as order_audit_pass_num,
count(if(t1.order_status=3 ,t1.order_id,null)) as order_audit_rejected_num,





============ 大牌活动
with t1 as (
select store_id
      ,store_name
from dim.dim_silkworm_store
where store_brand_type=1  -- 大牌店铺  =0 为正常店铺
),

t2 as (
select store_id              -- 店铺id
      ,store_promotion_id    -- 店铺活动id
      ,merchant_id           -- 商家id
      ,case when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt>0 then '美团|饿了么'
            when meituan_mlabel_rebate_amt>0 and eleme_mlabel_rebate_amt=0 then '美团'
            when meituan_mlabel_rebate_amt<=0 and eleme_mlabel_rebate_amt>0 then '饿了么'
       END AS store_platform      -- 平台名称
      ,city_id
      ,case when promotion_rebate_type=0 then concat('满',cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string),'返',cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string))
            when promotion_rebate_type=1 then concat('最高返',cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string))
       else '其他' end as mlabel     -- 餐标
       ,date_diff('hour',end_time,begin_time) as promotion_period                -- 活动开始日期                    -- 活动结束日期
       ,meituan_promotion_quota+eleme_promotion_quota as promotion_quota   -- 活动名额
       ,meituan_promotion_remain_quota+eleme_promotion_remain_quota as promotion_remain_quota   -- 剩余活动名额
       ,meituan_upload_num+eleme_upload_num as upload_num     -- 待上传数量
       ,meituan_audit_num+eleme_audit_num as audit_num     -- 待审核数量
       ,meituan_finished_num+eleme_finished_num as finished_num  -- 完成数量
       ,bd_id
       ,case when is_operation_promption=1 then '是' when is_operation_promption = 0 then '否' end as is_operation_promption -- 是否运营创建活动
from dwd.dwd_sr_store_promotion
where cast(dt as string) between '2024-10-01' and '2024-10-31'
),

t3 as (
    select distinct left(city_id,4) as city_id
          ,city_name
    from dim.dim_silkworm_county
),

t4 as (
    select store_promotion_id
          ,count(order_id) as order_num
    from dwd.dwd_sr_order_promotion_order 
    where dt >= date_sub(current_date,7) 
    and order_status in (2,8)
    group by 1 
)

select t1.store_name,t2.*,t3.city_name,t4.order_num
from t2 
join t1 
on t1.store_id = t2.store_id
left join t3
on t2.city_id = t3.city_id
left join t4 
on t2.store_promotion_id = t4.store_promotion_id


=========== 导出大牌活动明细
-- 捷西  导出7月份大牌专享活动的数据（大牌专享：活动是VIP专享）
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
WHERE cast(dt as string) between '2024-09-01' and '2024-10-31'
    and substr(begin_date,1,10) between '2024-10-01' and '2024-10-31'
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
limit 10
)

select
    store_promotion_id as `活动ID`,
    merchant_id as `商家ID`,
    t2.store_name as `店铺名称`,
    t2.city_name as `店铺城市`,
    store_platform as `平台名称`,  
    tot_promotion_quota as `活动名额`,
    tot_promotion_remain_quota as `剩余名额`,
    meal_label as `餐标`,
    promotion_duration as `活动周期`,
    tot_upload_num as `待上传数量`,
    tot_audit_num as `待审核数量`,
    tot_finished_num as `完成数量`,
    bd_id,
    is_operation_promption `是否运营创建活动`
    -- count(store_promotion_id) as cnt -- 82
from t1
inner join t2 on t1.store_id=t2.store_id
;



===============
========= ai电话外呼

select
    count(distinct a.silk_id) `通知人数`,
    count(distinct if(a.call_status=1,a.silk_id,null)) `接通人数`,
    count(distinct if(a.call_status=1 and b.order_status in (2,8),a.silk_id,null)) `通知完单人数`
    -- ,0 as `驳回超时取消订单量`
from
(select 
    silk_id,call_status,promotion_order_id
    -- count(1) -- 21661
from temp.temp_user_ai_phone_call_record
where date_format(created_at,'%Y-%m-%d %H')>= '2024-10-17 09'
) a
left join (
select cast(right(order_id,9) as int) as order_id,order_status
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
) b on a.promotion_order_id=b.order_id
;

-- 驳回超时取消订单量
select
    substr(order_time,1,10) as `下单日期`,
    count(if(order_status=3,order_id,null)) as `驳回超时取消订单量`,
    count(order_id) as `订单量`,
    count(if(order_status=3,order_id,null))/count(order_id) as `驳回超时取消订单占比`
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 20 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 7 day)
group by 1
;


select * from dws.dws_sr_order_timeout_cancelorder_d where order_date=date_sub(current_date(),interval 1 day)


===============
-- 传订单截图订单量
select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') `下单日期`,
    count(order_id) as `订单量`,
    count(if(order_status in (2,8),order_id,null)) as `有效订单量`
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
    and length(platform_order_screenshot)>2 -- 已传订单截图
group by 1
;




-- 已传截图有效下单量2,3,4单用户量
select
    order_date `下单日期`,
    count(distinct if(valid_order_num>=2,user_id,null)) as `2单及以上用户量`,
    count(distinct if(valid_order_num>=3,user_id,null)) as `3单及以上用户量`,
    count(distinct if(valid_order_num>=4,user_id,null)) as `4单及以上用户量`
from
-- 已传截图用户有效下单量
(select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date,
    user_id,
    count(order_id) as valid_order_num
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 40 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 30 day)
    and length(platform_pic_ocr_result)>2 -- 已传订单截图
    and order_status in (2,8)
group by 1,2
having count(order_id)>=2 -- 只留2单及以上用户
) a
group by 1;


-- 已传截图用户有效下单量
select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as order_date,
    count(order_id) as valid_order_num
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 1 day)
    and length(platform_pic_ocr_result)>1 -- 已传订单截图
    and order_status in (2,8)
group by 1
;


-- 连续传订单截图用户量
select
    count(distinct user_id) as lx_user_num
from (
-- 连续传订单截图
select 
    user_id,
    order_time,
    load_order_pic,
    lead(load_order_pic) over(PARTITION by user_id order by order_time desc) as next_load_pic
from 
(select user_id,order_time,if(length(platform_order_screenshot)>2,1,0) as load_order_pic -- 是否传订单截图
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 30 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
) a
) b
where load_order_pic+next_load_pic=2
;


select date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day);


with t as (
-- 连续传订单截图用户量
select
    user_id
from (
-- 连续传订单截图
select 
    user_id,
    order_time,
    load_order_pic,
    lead(load_order_pic) over(PARTITION by user_id order by order_time desc) as next_load_pic
from 
(select user_id,order_time,substr(order_time,1,10) as order_date,if(length(platform_order_screenshot)>2,1,0) as load_order_pic -- 是否传订单截图
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 40 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
) a
) b
where load_order_pic+next_load_pic=2
group by 1
)

-- 连续传订单截图且昨日访问用户量
select
    -- count(distinct t.user_id) as cnt
    t.user_id
from t
-- inner join
-- -- 昨日访问用户
-- (select
--     user_id
-- from ods.ods_sr_traffic_event_log
-- where dt=date_sub(current_date(),interval 1 day)
-- group by 1) a
-- on a.user_id=cast(t.user_id as string)
-- 昨日下单用户
inner join (select user_id from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')=date_sub(current_date(),interval 1 day)
    ) b on b.user_id=t.user_id
;

select
    user_id,order_time,platform_order_screenshot
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 40 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
    and user_id=877719777   -- 186516771
;

-- 连续传订单截图  测试下
select 
    user_id,
    order_time,
    load_order_pic,
    lead(order_time) over(PARTITION by user_id order by order_time desc) as next_order_time,
    lead(load_order_pic) over(PARTITION by user_id order by order_time desc) as next_load_pic
from 
(select user_id,order_time,substr(order_time,1,10) as order_date,if(length(platform_order_screenshot)>2,1,0) as load_order_pic -- 是否传订单截图
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 40 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
    -- and length(platform_order_screenshot)>2 -- 传订单截图
    and user_id=468464703
-- order by user_id,order_time desc
) a


-- 前天首次下单且已传订单截图用户
select
    -- count(distinct a.user_id) as cnt
    -- a.user_id
    a.*
from
-- 已传截图用户有效下单量
(select 
    user_id
    ,order_id
    -- ,platform_evaluation_order_screenshot_result,is_success_recognize_order_screenshot
    ,platform_order_screenshot
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 2 day)
    and length(platform_order_screenshot)>2 -- 已传订单截图
    and order_status in (2,8)
-- group by 1,2,3
) a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and substr(b.first_valid_order_time,1,10)='2024-10-30'
;

show create table dwd.dwd_sr_order_promotion_order;

select * from dwd.dwd_sr_order_promotion_order where county_id>0 limit 10;

-- 前天首次下单且已传订单截图用户
select
    -- count(distinct a.user_id) as cnt
    -- a.user_id
    a.*
from
-- 已传截图用户有效下单量
(select 
    user_id
    ,order_id
    -- ,platform_evaluation_order_screenshot_result,is_success_recognize_order_screenshot
    ,platform_order_screenshot
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 2 day)
    and length(platform_order_screenshot)>2 -- 已传订单截图
    and order_status in (2,8)
-- group by 1,2,3
) a
inner join dim.dim_silkworm_user b on a.user_id=b.user_id and substr(b.first_valid_order_time,1,10)='2024-10-30'
;



-- 前天首次下单且已传订单截图用户,下单位置和店铺位置不同区
select
    a.user_id,
    b.county_name as `下单区县`,
    c.district_name as `店铺区县`
    -- count(if(c.district_name is not null and b.county_name<>c.district_name,user_id,null)) as cnt
from
-- 已传截图用户有效下单量
(select 
    store_id,user_id,cast(substr(cast(county_id as string),1,6) as int) as county_id
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 2 day)
    and length(platform_order_screenshot)>2 -- 已传订单截图
    and order_status in (2,8)
    and county_id>0 -- 剔除无位置信息数据
group by 1,2,3
) a
left join dim.dim_silkworm_county b on a.county_id=b.county_id
left join dim.dim_silkworm_store c on a.store_id=c.store_id
where c.district_name is not null and b.county_name<>c.district_name
;

============
========== 付成 订单审核记录中有过驳回且有效的订单量
-- 每日订单审核记录中有过驳回且有效的订单量
select substr(order_time,1,10) as dat,count(1) as cnt from dwd.dwd_sr_order_promotion_order 
where cast(dt as string)>='2024-09-01'
    and substr(order_time,1,10)>='2024-10-01'
    -- and user_id=923592157
    and order_log regexp '订单驳回：宝子，'
    -- and platform_pic_ocr_result regexp '订单已完成'
    and order_status in (2,8) -- 有效单
group by 1
;




======== MySQL执行
-- 上海&杭州探店订单量
select
  order_date as "下单日期",
  sum(if(b.city='上海市',f_cnt,0)) as "上海完单量",
  sum(if(b.city='上海市',j_cnt,0)) as "上海进行中订单量",
  sum(if(b.city='杭州市',f_cnt,0)) as "杭州完单量",
  sum(if(b.city='杭州市',j_cnt,0)) as "杭州进行中订单量"
from 
(select date(created_at) as order_date,
    store_id,
    count(if(status=5,order_id,null)) as f_cnt,
    count(if(status<>5,order_id,null)) as j_cnt
from `order`
where date(created_at) between '2024-10-18' and '2024-10-18'
    and store_name not like '%测试%'
  and  status in (1,2,3,4,5,12,13,15,16,24,25,30,31,32,33,34) -- 已完单+进行中
  and `promotion_type` in (1,4)
group by date(created_at),
    store_id) a
inner join store b on a.store_id=b.id and b.city in ('上海市','杭州市')
group by   order_date
;


========= 美团专版订单返现金额
select
    substr(order_time,1,10) as order_date,
    sum(real_rebate_amt)/count(order_id) as rebate_amt,
    count(order_id) as order_num
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-07-01' and '2024-10-21'
    and substr(order_time,1,10) between '2024-08-01' and '2024-10-21'
    and order_status in (2,8)
    and order_type=12
group by 1;


============ 霸王餐每日活动名额和订单量
select
    substr(order_time,1,10) as `下单日期`,
    count(order_id) as `总订单量`,
    count(if(order_status in (2,8),order_id,null)) as `总有效订单量`,
    count(if(store_promotion_id<>0,order_id,null)) as `自营订单量`,
    count(if(order_status in (2,8) and store_promotion_id<>0,order_id,null)) as `自营有效订单量`,
    sum(if(order_status=2,profit,0)) as `总有效利润`,
    sum(if(order_status=2 and store_promotion_id<>0,profit,0)) as `自营有效利润`
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 40 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 30 day)
group by 1
;

-- UV
set query_timeout=12000;

select dt,
    count(distinct user_id) as cnt 
from ods.ods_sr_traffic_event_log
where dt>=date_sub(current_date(),interval 7 day)
group by 1;


show create table dwd.dwd_sr_store_promotion;

-- 活动名额
select 
    begin_date,
    count(store_promotion_id) promotion_num,
    sum(meituan_promotion_quota+eleme_promotion_quota) as tot_pro_quota
from dwd.dwd_sr_store_promotion
where cast(dt as string) between '2024-09-20' and '2024-10-30'
        and begin_date between '2024-10-01' and '2024-10-30'
        and status in (1,4,5)
group by 1;




========= BD 实收利润查看
show create table dwd.dwd_sr_store_promotion;

select * from dwd.dwd_sr_store_promotion where substr(bad_debt_time,1,10)<>'1970-01-01' and substr(pay_time,1,10)<>'1970-01-01' limit 10;

select 
    -- dt,
    count(1) as tot,
    count(if(substr(pay_time,1,10)<>'1970-01-01',store_promotion_id,null)) as cnt1,
    count(if(substr(bad_debt_time,1,10)<>'1970-01-01',store_promotion_id,null)) as cnt2,
    sum(profit) as tot_profit,
    sum(if(substr(pay_time,1,10)<>'1970-01-01',profit,0)) as pay_profit,
    sum(if(substr(bad_debt_time,1,10)<>'1970-01-01',profit,0)) as bad_profit
from dwd.dwd_sr_store_promotion 
where 
    -- cast(dt as string) between '2024-09-01' and '2024-09-30'
    and substr(pay_time,1,10) between '2024-09-01' and '2024-09-30'
    and bd_id=6
-- group by 1
;

select staff_id,user_nickname,bd_id from dim.dim_silkworm_staff where user_nickname='小花';



select
    bd_id,
    sum(valid_order_num) as valid_order_num,
    sum(profit) as tot_profit,
    sum(if(substr(pay_time,1,10)<>'1970-01-01',profit,0)) as pay_profit,
    sum(if(substr(bad_debt_time,1,10)<>'1970-01-01',profit,0)) as bad_profit
from
(select 
    store_promotion_id,
    bd_id,
    pay_time,
    bad_debt_time
from dwd.dwd_sr_store_promotion 
where cast(dt as string) between '2024-01-01' and '2024-08-31'
    -- and begin_date between '2024-08-01' and '2024-08-31'
    and substr(pay_time,1,10) between '2024-07-01' and '2024-07-31'
    and bd_id=6
    ) a
inner join
(select
    store_promotion_id,
    count(order_id) as valid_order_num,
    sum(profit) as profit
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-05-20' and '2024-08-31'
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between '2024-05-20' and '2024-08-31'
    and order_status=2
group by store_promotion_id) b
on a.store_promotion_id=b.store_promotion_id
group by 1
;


-- 查看明细
select * from
(select
    store_promotion_id,
    order_time,
    order_audit_finish_time,
    order_id,
    profit
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-01-01' and '2024-10-31'
    -- and str_to_date(substr(order_time,1,10),'%Y-%m-%d') between '2024-09-01' and '2024-09-30'
    and order_status=2
    and bd_id=6
    ) a
left join
(select 
    store_promotion_id,
    bd_id,
    pay_time,
    bad_debt_time
from dwd.dwd_sr_store_promotion 
where cast(dt as string) between '2024-01-01' and '2024-10-31'
    -- and begin_date between '2024-09-01' and '2024-09-30'
    and substr(pay_time,1,10) between '2024-07-01' and '2024-07-31'
    and bd_id=6
    ) b
on a.store_promotion_id=b.store_promotion_id
;



select 
    -- pay_status,
    sum(fact_pay_rebate_amt) as paid_amt,
    sum((meituan_finished_num*meituan_mlabel_rebate_amt*100)+(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit,
    sum(fact_pay_rebate_amt-(meituan_finished_num*meituan_mlabel_rebate_amt*100)-(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit2
    -- sum(if(pay_status in (0,3,4),fact_rebate_amt*100,0)) as paid_amt,
    -- sum(if(pay_status in (0,3,4),(meituan_finished_num*meituan_mlabel_rebate_amt*100)+(eleme_finished_num*eleme_mlabel_rebate_amt*100),0)) as paid_profit,
    -- sum(if(substr(begin_date,1,10) between '2024-07-01' and '2024-07-31' and pay_abnormal_status=1,fact_rebate_amt*100,0)) as bad_profit
from dwd.dwd_sr_store_promotion
where -- substr(begin_date,1,7)='2024-09' and substr(pay_time,1,7)='2024-09'
    substr(pay_time,1,10) between '2024-09-01' and '2024-09-30'
    and bd_id=6
-- group by 1
;

select 
    bd_id,
    store_promotion_id,
    create_time,
    begin_date,
    pay_time,
    fact_pay_rebate_amt,
    meituan_finished_num,
    meituan_mlabel_rebate_amt,
    eleme_finished_num,
    eleme_mlabel_rebate_amt
from dwd.dwd_sr_store_promotion
where 
    -- substr(begin_date,1,7)='2024-09' and substr(pay_time,1,7)='2024-09'
    substr(pay_time,1,10) between '2024-09-01' and '2024-09-30'
    and bd_id=6
-- group by 1
;


-- 当月支付 实收利润(扣减后)
-- 需要更新近180天数据
select 
    bd_id,
    sum(fact_pay_rebate_amt-(meituan_finished_num*meituan_mlabel_rebate_amt*100)-(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit -- 实收利润(扣减后)
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7)='2024-08' -- 当月支付
group by 1
;


===================== 复活券订单统计
show create table dwd.dwd_sr_order_promotion_order;

dwd.dwd_sr_order_revicp_order -- 复活券订单表

-- 查看明细
select * from dwd.dwd_sr_order_revicp_order limit 10;

-- 20241105 2870条数据
select 
    date(create_time) as dat, -- 1105
    hour(create_time) as hr, -- 11
    count(1) as cnt, -- 2870
    count(distinct user_id) as user_num, -- 2870
    count(distinct order_id) as order_num -- 2870
    -- revival_coupon_id -- 32
from dwd.dwd_sr_order_revicp_order
where date(create_time)<='2024-11-06'
    and status=1 -- 已发放
group by 1,2;


-- 复活券发放后订单状态
select
    -- a.auto_id,
    -- a.order_id,
    -- b.order_time,
    -- b.order_audit_finish_time,
    -- b.order_status,
    -- b.real_rebate_amt,
    -- b.merchant_pay_amt,
    -- b.merchant_pay_status
    count(a.auto_id) as `复活券发放量`,
    count(distinct if(b.order_status in (2,8,12) 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    a.order_id,null)) as `复活订单量`,
    sum(if(b.order_status in (2,8,12) 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    b.real_rebate_amt,0)) as `复活订单返豆金额`,
    count(distinct if(b.order_status=2 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    a.order_id,null)) as `有商家账单复活订单量`,
    sum(if(b.order_status=2 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    b.real_rebate_amt,0)) as `有商家账单复活订单返豆金额`,
     sum(if(b.order_status=2 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    b.profit,0)) as `有商家账单复活订单利润`,  
    count(distinct if(b.order_status in (8,12) 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    a.order_id,null)) as `无商家账单复活订单量`,
    sum(if(b.order_status in (8,12) 
                    and substr(b.order_audit_finish_time,1,13) between '2024-11-06 11' and '2024-11-06 13',
                    b.real_rebate_amt,0)) as `无商家账单复活订单返豆金额`
from
-- 复活券发放订单
(
select
    auto_id,order_id
from dwd.dwd_sr_order_revicp_order
where date(create_time)=current_date()
    and status=1 -- 已发放
) a
left join 
-- 订单
(select 
    cast(right(order_id,9) as int) as order_id,
    order_time, -- 下单时间
    order_audit_finish_time, -- 订单审核完成时间
    order_status, -- 订单状态
    real_rebate_amt, -- 实际返豆金额
    merchant_pay_amt, -- 商家支付金额
    merchant_pay_status, -- 商家付款状态(0:暂未支付,1:已支付)
    profit
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
) b on a.order_id=b.order_id
;


-- 前日超时订单
select
    b.*,
    c.meituan_promotion_remain_quota,
    c.eleme_promotion_remain_quota
from
-- 订单
(select 
    cast(right(order_id,9) as int) as order_id,
    order_time, -- 下单时间
    order_audit_finish_time, -- 订单审核完成时间
    order_status, -- 订单状态
    real_rebate_amt, -- 实际返豆金额
    merchant_pay_amt, -- 商家支付金额
    merchant_pay_status, -- 商家付款状态(0:暂未支付,1:已支付)
    profit,
    store_promotion_id,
    user_id
-- count(order_id) as cnt,count(distinct user_id) as user_num
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and substr(order_time,1,10)='2024-11-04'
    and order_status=5
    and order_log regexp '填入订单号'
) b
left join dwd.dwd_sr_store_promotion c 
on b.store_promotion_id=c.store_promotion_id 
    and c.dt>=date_sub(current_date(),interval 30 day)
    and c.begin_date>='2024-11-01'



left join
-- 复活券发放订单
(
select
    auto_id,order_id
from dwd.dwd_sr_order_revicp_order
where date(create_time)=current_date()
    and status=1 -- 已发放
) a on a.order_id=b.order_id
;


-- 非自营订单量统计
select 
    order_type,
    rebate_condition_type,
    count(order_id) as order_num
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 7 day)
    and substr(order_time,1,10)='2024-11-04'
    and order_status=5
    and order_log regexp '填入订单号'
    and store_promotion_id=0
group by 1,2;


==============
-- 美团和饿了么专版订单分位值
select
    PERCENTILE_CONT(mt_order_num,0.5) as p50_value1,
    PERCENTILE_CONT(mt_order_num,0.75) as p75_value1,
    PERCENTILE_CONT(mt_order_num,0.9) as p90_value1,
    PERCENTILE_CONT(elm_order_num,0.5) as p50_value2,
    PERCENTILE_CONT(elm_order_num,0.75) as p75_value2,
    PERCENTILE_CONT(elm_order_num,0.9) as p90_value2
from
-- 最近90天下单用户
(select 
        user_id,
        sum(if(order_type=12,1,0)) as mt_order_num, -- 美团专版订单量
        sum(if(order_type=13,1,0)) as elm_order_num -- 饿了么专版订单量
        -- count(distinct user_id)
    from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 105 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
group by 1) a
-- where mt_order_num>0 and elm_order_num=0
where mt_order_num=0 and elm_order_num>0
;


-- 无order_id
select *
-- count(1) cnt -- 1082
from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 1 day) and date_sub(current_date(),interval 1 day)
        and order_id=''
;

-- 美团专版无实际返利订单
select 
count(1) `订单量`, -- 6385
count(distinct user_id) as `用户量` -- 6199 
from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 1 day) and date_sub(current_date(),interval 1 day)
        and order_type=12
        and real_rebate_amt=0
        and order_status in (2,8)
;

select 
    order_time,
    concat('单',order_id) as `订单ID`,
    user_id,
    real_rebate_amt,
    origin_rebate_amt,
    user_pay_amt
from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(substr(order_time,1,10),'%Y-%m-%d') 
            between date_sub(current_date(),interval 1 day) and date_sub(current_date(),interval 1 day)
        and order_type=12
        and real_rebate_amt=0
        and order_status in (2,8)
;



========= 超时取消订单
select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as `下单日期`,
    count(1) as `下单量`,
    count(distinct user_id) as `下单用户量`, 
    sum(if(order_status=5,1,0)) as `超时取消订单量`,
    count(distinct if(order_status=5,user_id,0)) as `超时取消用户量`,
    count(distinct if(order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,auto_id,0)) as `第二步超时取消订单量`,
    count(distinct if(order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,user_id,0)) as `第二步超时取消用户量`,
    count(distinct if(
            order_status in (0,3)
            ,auto_id,0)) as `待提交反馈订单量`,
    count(distinct if(
            order_status in (0,3)
            ,user_id,0)) as `待提交反馈用户量`
    ,count(if(order_status=3,order_id,null)) as `驳回订单量`
    ,count(distinct if(order_status=3,user_id,null)) as `驳回用户量`
    ,count(distinct if(order_type in (12,13) and order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,auto_id,0)) as `第二步超时取消专版订单量`
    ,count(distinct if(order_type in (12,13) and order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,user_id,0)) as `第二步超时取消专版用户量`
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 30 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 14 day)
group by 1
;



=============
-- 近三天开始的浙江省大牌专享活动（大牌专享：活动是VIP专享）
with t1 as (
select
    store_promotion_id,
    province_name,
    city_name,
    district_name,
    meituan_promotion_quota + eleme_promotion_quota AS tot_promotion_quota -- 活动名额
from dwd.dwd_sr_store_promotion a -- 活动
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.province_name='浙江省' and b.status=1 -- 杭州店铺
WHERE a.dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and str_to_date(a.begin_date,'%Y-%m-%d') between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day)
    and a.status in (1, 4, 5)
    and a.is_vip_exclusive=1 -- 是否VIP用户专享 1：是
),

-- V3+用户有效订单量
t2 as (
select
    store_promotion_id,
    sum(valid_order_num) as valid_order_num
from
    (select
        store_promotion_id,
        user_id,
        count(auto_id) as valid_order_num
    from dwd.dwd_sr_order_promotion_order
    where dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
        and str_to_date(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day)
        and order_status in (2,8)
    group by 1,2
    ) a
inner join dim.dim_silkworm_member b on a.user_id=b.user_id and b.user_level>=3 -- V3+用户
group by 1
    )


select
    province_name as `省份`,
    city_name as `城市`,
    district_name as `区县`,
    sum(tot_promotion_quota) as `活动名额`,
    sum(valid_order_num) as `有效订单量`
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
group by 1,2,3
;

============
-- 订单异常工单中订单，且已传订单截图
show create table dwd.dwd_sr_callcenter_workorder;

select count(a.order_id) as cnt from
(select
    order_id
from dwd.dwd_sr_callcenter_workorder
where cast(dt as string) between '2024-01-01' and '2024-11-14'
    and cate2_type=2
group by 1) a
inner join
(select order_id from dwd.dwd_sr_order_promotion_order 
where cast(dt as string)>='2023-11-01' 
and length(platform_order_screenshot)>2 -- 已传订单截图
) b on a.order_id=b.order_id
;


======== 探店笔记上传记录
show create table dwd.dwd_sr_silkworm_explore_notes_upload_record;


select
    hr as `小时`,
    avg(note_num) as `平均探店笔记数`
from (
-- 分小时统计
select
    a.dt,
    hour(a.create_time) as hr,
    sum(note_num) as note_num
from
-- 最近7天笔记上传笔记量
(select dt,
    create_time,
    order_id,
    count(distinct notes_id) as note_num
from dwd.dwd_sr_silkworm_explore_notes_upload_record
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
group by 1,2,3
) a
inner join dwd.dwd_sr_silkworm_explore_order b on a.order_id=b.order_id and b.promotion_type in (1,4) -- 探店订单
group by 1,2
) b
group by 1;


-- 人审笔记量
select
    hr as `小时`,
    avg(note_num) as `平均探店笔记数`
from (
-- 分小时统计
select
    a.dt,
    hour(a.create_time) as hr,
    sum(note_num) as note_num
from
-- 最近7天笔记上传笔记量
(select dt,
    create_time,
    order_id,
    count(distinct notes_id) as note_num
from dwd.dwd_sr_silkworm_explore_notes_upload_record
where dt between date_sub(current_date(),interval 4 day) and date_sub(current_date(),interval 1 day)
    and auditor_id<>0 -- 人审
group by 1,2,3
) a
group by 1,2) b
group by 1;




====== 
-- 探店店铺和活跃用户距离
select * from test.test_client_user_location limit 10;

-- 不存在为null为空数据
select store_id,longitude,latitude from dim.dim_silkworm_explore_store where latitude='' limit 10; 

show create table dwd.dwd_sr_silkworm_explore_promotion;

-- 用户定位
with t1 as (
select
    silk_id,longitude as end_lon,latitude as end_lat
from test.test_client_user_location
where date(updated_at) between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and city='杭州市'
    ),


-- 探店活动
t2 as
(select
    store_id,
    demand_promotion_type,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    pay_amt,
    ds_price,
    sum(tot_promotion_quota) as promotion_quota,
    sum(used_promotion_quota) as used_promotion_quota,
    sum(wait_verify_order_num) as wait_verify_order_num,
    sum(finished_num) as finished_num
from (
select
    store_id,
    promotion_id,
    demand_promotion_type,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    tot_promotion_quota,
    used_promotion_quota,
    pay_amt,-- 原价
    pay_amt-rebate_price as ds_price
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and substr(begin_time,1,10) between '2024-11-09' and '2024-11-16'
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
) a
left join 
-- 已支付待核销订单量 完单量
(select
    store_promotion_id,
    count(if(status=3,order_id,null)) as wait_verify_order_num,
    count(if(status in (5,19,20),order_id,null)) as finished_num
from dwd.dwd_sr_silkworm_explore_order
where dt>=date_sub(current_date(),interval 180 day)
    and promotion_type in (1,4)
    and status in (3,5,19,20) -- 已支付待核销
group by 1) b
on a.promotion_id=b.store_promotion_id
group by 1,2,3,4,5,6
),

-- 最近7天是否发活动
t3 as (
select
    store_id,if(pro_num>0,'是','否') as is_pub
from(
select
    store_id,
    count(1) as pro_num
from dwd.dwd_sr_silkworm_explore_promotion
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
group by 1) a
),

-- 昨日访问探店页面 全站
t4 as (
select
    cast(user_id as int) as user_id,count(1) as cnt
from ods.ods_sr_traffic_event_log
where cast(dt as string) between '2024-11-09' and '2024-11-16'        -- date_sub(current_date(),interval 1 day)
    -- and event_name in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View')
    and user_id regexp '^[0-9]{1,9}$'
group by 1
having count(1)>0
),


-- 店铺属性
t5 as (
select 
    a.store_id,
    a.store_name,
    a.province_name,
    a.city_name,
    a.county_name,
    a.longitude as star_lon,
    a.latitude as star_lat,
    t2.demand_promotion_type,
    t2.demand_dp_user_lvl,
    t2.demand_xiaohongshu_fans_num,
    t2.pay_amt,
    t2.ds_price,
    t2.promotion_quota,
    t2.used_promotion_quota,
    t2.wait_verify_order_num,
    t2.finished_num,
    t3.is_pub
from dim.dim_silkworm_explore_store a 
left join t2 on a.store_id=t2.store_id
left join t3 on a.store_id=t3.store_id
where city_name='杭州市'
    and status=1
),

-- daren
daren as (
select
    user_id
from dim.dim_silkworm_explore_daren_cleanse
where (substr(xiaohongshu_auth_first_time,1,10)<>'1970-01-01'
    and xiaohongshu_fans_num>=200
    )
    or (substr(dp_auth_first_time,1,10)<>'1970-01-01'
    and dp_user_lvl>=5
    )
),

-- 造出数据集
t6 as (
select
    silk_id,
    store_id,
    store_name,
    province_name,
    city_name,
    county_name,
    demand_promotion_type,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    pay_amt,
    ds_price,
    promotion_quota,
    used_promotion_quota,
    wait_verify_order_num,
    finished_num,
    is_pub,
    ST_Distance_Sphere(end_lon, end_lat, star_lon, star_lat) as distance,
    if(daren.user_id is not null,1,0) is_daren
from t1
inner join t4 on t1.silk_id=t4.user_id
left join daren on t1.silk_id=daren.user_id
left join t5 on 1=1
)



select     
    store_id `店铺ID`
    ,store_name `店铺名称`
    ,province_name `店铺ID`
    ,city_name `店铺城市`
    ,county_name `店铺区县`
    ,demand_promotion_type `活动要求类型`
    ,demand_dp_user_lvl `点评要求用户等级`
    ,demand_xiaohongshu_fans_num `粉丝数要求`
    ,pay_amt `原价`
    ,ds_price `到手价`
    ,promotion_quota `活动名额`
    ,used_promotion_quota `已占用活动名额`
    ,wait_verify_order_num `已支付待核销订单量`
    ,finished_num `完单量`
    ,is_pub `近7天是否发布活动`
    ,count(distinct if(distance<=3000,silk_id,null)) as `3公里内用户量`
    ,count(distinct if(distance<=5000,silk_id,null)) as `5公里内用户量`
    ,count(distinct if(distance<=8000,silk_id,null)) as `8公里内用户量`
    ,count(distinct if(distance<=10000,silk_id,null)) as `10公里内用户量`
    ,count(distinct if(distance<=15000,silk_id,null)) as `15公里内用户量`
    ,count(distinct if(distance<=20000,silk_id,null)) as `20公里以内用户量`

    ,count(distinct if(is_daren=1 and distance<=3000,silk_id,null)) as `3公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=5000,silk_id,null)) as `5公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=8000,silk_id,null)) as `8公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=10000,silk_id,null)) as `10公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=15000,silk_id,null)) as `15公里内达人用户量`
    ,count(distinct if(is_daren=1 and distance<=20000,silk_id,null)) as `20公里以内达人用户量`


from t6
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;


===========
-- 捷西  导出7月份大牌专享活动的数据（大牌专享：活动是VIP专享）
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
WHERE cast(dt as string) between '2024-10-01' and '2024-11-30'
    and substr(begin_date,1,10) between '2024-11-01' and '2024-11-30'
    and status in (1, 4, 5)
    -- and is_operation_promption=1 -- 是否运营创建活动 1：是   处理时需要去掉该限制，因查看到循环活动中，只标记了第一次创建时=1，之后开启循环，置为=0了
    and is_vip_exclusive=1 -- 是否VIP用户专享 1：是
),


-- 店铺
t2 as (
select 
    store_id,
    store_name,
    city_name
from dim.dim_silkworm_store
where status=1 -- 已审核
    -- and store_name regexp '茶姬' 
    -- and city_name in ('杭州市','宁波市')
)

select
    store_promotion_id as `活动ID`,
    merchant_id as `商家ID`,
    t2.store_name as `店铺名称`,
    t2.city_name as `店铺城市`,
    store_platform as `平台名称`,  
    tot_promotion_quota as `活动名额`,
    tot_promotion_remain_quota as `剩余名额`,
    meal_label as `餐标`,
    promotion_duration as `活动周期`,
    tot_upload_num as `待上传数量`,
    tot_audit_num as `待审核数量`,
    tot_finished_num as `完成数量`,
    bd_id,
    is_operation_promption `是否运营创建活动`
    -- count(store_promotion_id) as cnt -- 82
from t1
inner join t2 on t1.store_id=t2.store_id
;



========
select
    month(pay_time) as mon,
    bd_id,
    sum(fact_pay_rebate_amt-(meituan_finished_num*meituan_mlabel_rebate_amt*100)-(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit -- 实收利润(扣减后)
    ,sum(
        if(cooper_type=1,(meituan_mlabel_rebate_amt+service_charge)*meituan_finished_num*0.06
        + (eleme_mlabel_rebate_amt+service_charge)*eleme_finished_num*0.06
        ,0
        )
        ) as valuadd_service_charge -- 增值服务费6%
    ,sum(if(cooper_type=2,(meituan_finished_num+eleme_finished_num)*1,0)) as user_undertake_1yuan
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
    -- and month(update_time)=month(pay_time)
    and bd_id in (6,1316,1222,1284,1843,1885)
    -- and fact_rebate_amt>0
group by 1,2
;

select
    month(pay_time) as mon,
    bd_id,
    sum(fact_pay_rebate_amt-(meituan_finished_num*meituan_mlabel_rebate_amt*100)-(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit -- 实收利润(扣减后)
    ,sum(
        if(cooper_type=1,(meituan_mlabel_rebate_amt+service_charge)*meituan_finished_num*0.06
        + (eleme_mlabel_rebate_amt+service_charge)*eleme_finished_num*0.06
        ,0
        )
        ) as valuadd_service_charge -- 增值服务费6%
    ,sum(if(cooper_type=1,fact_rebate_amt,0))/1.06*0.06 as valuadd_service_charge2
    ,sum(if(cooper_type=2,(meituan_finished_num+eleme_finished_num)*1,0))/1.06*0.06 as user_undertake_1yuan
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
    and month(update_time)=month(pay_time)
    -- and bd_id in (6,1316,1222,1284,1843,1885)
    and fact_rebate_amt>0
group by 1,2
;


-- 服务费*完单量=实收利润
select
    month(pay_time) as mon,
    bd_id,
    sum(service_charge*(meituan_finished_num+eleme_finished_num)) as profit
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
    and bd_id in (6,1316,1222,1284,1843,1885)
group by 1,2
;


-- 实收金额+实收金额/1.06=实收利润
select
    month(pay_time) as mon,
    bd_id,
    sum(if(cooper_type in (1,2),fact_rebate_amt/1.06,fact_rebate_amt)) as profit1
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
    and bd_id in (6,1316,1222,1284,1843,1885)
group by 1,2
;

select
    month(current_date()) as mon,
    bd_id,
    sum(fact_pay_rebate_amt-(meituan_finished_num*meituan_mlabel_rebate_amt*100)-(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit -- 实收利润(扣减后)
from dwd.dwd_sr_store_promotion
where month(pay_time)=month(current_date()) -- 当月支付
    and month(update_time)=month(current_date()) -- 当月更新
    and bd_id in (6,1316,1222,1284,1843,1885)
    and fact_rebate_amt>0 -- 实际支付>0
group by 1,2
;

-- 增值服务费6% 用户承担1元
select
    month(pay_time) as mon,
    bd_id,
    sum(
        if(cooper_type=1,(meituan_mlabel_rebate_amt+service_charge)*meituan_finished_num*0.06
        + (eleme_mlabel_rebate_amt+service_charge)*eleme_finished_num*0.06
        ,0
        )
        ) as valuadd_service_charge, -- 增值服务费6%
    sum(if(cooper_type=2,(meituan_finished_num+eleme_finished_num)*1,0)) as user_undertake_1yuan
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
    and bd_id in (6,1316,1222,1284,1843,1885)
group by 1,2
;


======= 数据中心 bd数据看板
select
  mon,a.bd_id,b.user_nickname,
  paid_profit, -- 实收利润
  valuadd_service_charge, -- 增值服务费6%
  user_undertake_1yuan, -- 增值服务费用户承担1元
  paid_profit-valuadd_service_charge-user_undertake_1yuan as deduct_fact_receive_profit -- 实收利润（扣减后）
from
(select
    month(pay_time) as mon,
    bd_id,
    sum(fact_pay_rebate_amt-(meituan_finished_num*meituan_mlabel_rebate_amt*100)-(eleme_finished_num*eleme_mlabel_rebate_amt*100)) as paid_profit -- 实收利润
    ,sum(if(cooper_type=1,fact_rebate_amt,0))/1.06*0.06*100 as valuadd_service_charge
    ,sum(if(cooper_type=2,fact_rebate_amt,0))/1.06*0.06*100 as user_undertake_1yuan
from dwd.dwd_sr_store_promotion
where substr(pay_time,1,7) between '2024-10' and '2024-10' -- 当月支付
    and month(update_time)=month(pay_time)
    -- and bd_id in (1357,1649)
    and fact_rebate_amt>0
group by 1,2
) a
left join dim.dim_silkworm_staff b on a.bd_id=b.bd_id
;

==========
-- 商家待支付活动数分位值
select
    PERCENTILE_CONT(pro_num,0.1) as `待支付活动数10分位值`,
    PERCENTILE_CONT(pro_num,0.2) as `待支付活动数20分位值`,
    PERCENTILE_CONT(pro_num,0.3) as `待支付活动数30分位值`,
    PERCENTILE_CONT(pro_num,0.4) as `待支付活动数40分位值`,
    PERCENTILE_CONT(pro_num,0.5) as `待支付活动数50分位值`,
    PERCENTILE_CONT(pro_num,0.6) as `待支付活动数60分位值`,
    PERCENTILE_CONT(pro_num,0.7) as `待支付活动数70分位值`,
    PERCENTILE_CONT(pro_num,0.8) as `待支付活动数80分位值`,
    PERCENTILE_CONT(pro_num,0.9) as `待支付活动数90分位值`,
    PERCENTILE_CONT(pro_num,1) as `待支付活动数最大值`
    -- count(1) as `商家数`
from
(select
    -- merchant_id,
    store_id,
    count(store_promotion_id) pro_num
    -- str_to_date(end_date,'%Y-%m-%d') `活动结束日期`,
    -- count(store_promotion_id) `待支付活动数`,
    -- count(distinct store_id) `待支付店铺数`,
    -- count(distinct merchant_id) `待支付商家数`
from dwd.dwd_sr_store_promotion
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day) -- 近30天内发布活动
    and str_to_date(begin_date,'%Y-%m-%d') between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day) -- 近3天开始活动
    and pay_status=2
    and status in (1,4,5)
group by 1
-- having count(store_promotion_id)>=100 -- 筛选>=100待支付活动商家
order by 2 desc
) a
;


============
select
    -- case when b.store_name regexp '古茗' then '古茗'
    -- else '其他' end as `品牌`,
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
where dt between '2024-10-01' and '2024-11-27'
    and begin_date between '2024-11-20' and '2024-11-27'
    and status in (1,4,5)
    and is_operation_promption=0
group by 1
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.store_name regexp '古茗'
group by 1,2,3
;

select * from dim.dim_silkworm_store limit 100;

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
where dt between '2024-10-21' and '2024-11-26'
    and begin_date between '2024-11-20' and '2024-11-26'
    and status in (1,4,5)
    and is_operation_promption=0
group by 1
) a
inner join dim.dim_silkworm_store b on a.store_id=b.store_id and b.store_name regexp '奈雪|喜茶|酸奶罐罐|霸王茶姬'
group by 1,2,3,4;



========= 超时取消订单
select 
    str_to_date(substr(order_time,1,10),'%Y-%m-%d') as `下单日期`,
    count(1) as `下单量`,
    count(distinct user_id) as `下单用户量`, 
    sum(if(order_status=5,1,0)) as `超时取消订单量`,
    count(distinct if(order_status=5,user_id,0)) as `超时取消用户量`,
    count(distinct if(order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,auto_id,0)) as `第二步超时取消订单量`,
    count(distinct if(order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,user_id,0)) as `第二步超时取消用户量`,
    count(distinct if(
            order_status in (0,3)
            ,auto_id,0)) as `待提交反馈订单量`,
    count(distinct if(
            order_status in (0,3)
            ,user_id,0)) as `待提交反馈用户量`
    ,count(if(order_status=3,order_id,null)) as `驳回订单量`
    ,count(distinct if(order_status=3,user_id,null)) as `驳回用户量`
    ,count(distinct if(order_type in (12,13) and order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,auto_id,0)) as `第二步超时取消专版订单量`
    ,count(distinct if(order_type in (12,13) and order_status=5 
            and order_log regexp '填入订单号' -- 已提交订单号
            ,user_id,0)) as `第二步超时取消专版用户量`
from dwd.dwd_sr_order_promotion_order
where dt>=date_sub(current_date(),interval 30 day)
    and str_to_date(substr(order_time,1,10),'%Y-%m-%d')>=date_sub(current_date(),interval 15 day)
group by 1
;


==============
-- 最近7天实付不满且返现为0订单
select
    concat('单',order_id) as `订单ID`,
    user_id `用户ID`,
    order_time `下单时间`,
    store_promotion_id `活动ID`,
    case when promotion_rebate_type=0 then concat('满',order_amt,'返',origin_rebate_amt)
       else '其他' end as `餐标`,
    order_amt `餐标门槛`,
    origin_rebate_amt `餐标返现`,
    real_rebate_amt `实际返现金额`,
    user_pay_amt `用户实际支付金额`,
    redpacket_amt `小蚕红包金额`
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and order_status=2
    and promotion_rebate_type=0 -- 0:霸王餐,1:返利餐
    and user_pay_amt<order_amt
    and real_rebate_amt=0
;


=========== 近15天下单量分布
select
    order_num `完单量`,count(user_id) as `用户量`
from
(select
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1) a
group by 1;


===========
①近15天完单≤3且11月完单≥7单的用户数量和这部分用户在11月的人均完单数
②昨天拉的：3单＜近15天完单≤7单；8单≤近15天完单≤12单；13单≤近15天完单≤18单以上三个区间的用户群在11月份的人均完单量分别是多少


-- 近15天完单<=3
with t1 as (
select
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1
having count(auto_id)<=3
),

-- 11月完单
t2 as (
select
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-11-01' and '2024-11-30'
    and order_status in (2,8)
group by 1
)

select
    count(if(t2.order_num>=7,t1.user_id,null)) `近15天完单≤3且11月完单≥7单用户量`,
    sum(if(t2.order_num>=7,t2.order_num,0)) `近15天完单≤3且11月完单≥7单用户订单量`
from t1
left join t2 on t1.user_id=t2.user_id
;



-- 近15天完单
with t1 as (
select
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
group by 1
),

-- 11月完单
t2 as (
select
    user_id,
    count(auto_id) as order_num
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-11-01' and '2024-11-30'
    and order_status in (2,8)
group by 1
)


select
    count(if(t1.order_num between 4 and 7,t2.user_id,null)) `近15天完单量4-7单用户量`,
    sum(if(t1.order_num between 4 and 7,t2.order_num,0)) `近15天完单量4-7单用户订单量`,
    sum(if(t1.order_num between 4 and 7,t2.order_num,0))/count(if(t1.order_num between 4 and 7,t2.user_id,null)) as `近15天完单量4-7单用户人均订单量`,
    count(if(t1.order_num between 8 and 12,t2.user_id,null)) `近15天完单量8-12单用户量`,
    sum(if(t1.order_num between 8 and 12,t2.order_num,0)) `近15天完单量8-12单用户订单量`,
    sum(if(t1.order_num between 8 and 12,t2.order_num,0))/count(if(t1.order_num between 8 and 12,t2.user_id,null)) as `近15天完单量8-12单用户人均订单量`,
    count(if(t1.order_num between 13 and 18,t2.user_id,null)) `近15天完单量13-18单用户量`,
    sum(if(t1.order_num between 13 and 18,t2.order_num,0)) `近15天完单量13-18单用户订单量`,
    sum(if(t1.order_num between 13 and 18,t2.order_num,0))/count(if(t1.order_num between 13 and 18,t2.user_id,null)) as `近15天完单量13-18单用户人均订单量`
from t1
left join t2 on t1.user_id=t2.user_id
;


=============== 24年12月BD发布活动中，账单金额>0活动数
select
    count(store_promotion_id) num    -- 店铺活动id 
from dwd.dwd_sr_store_promotion
WHERE cast(dt as string) between '2024-01-01' and '2024-12-31'
    and substr(begin_date,1,10) between '2024-12-01' and '2024-12-31'
    and status in (1, 4, 5)
    and promotion_type=1 -- 后台创建活动
    and eleme_finished_num+meituan_finished_num>0




=========== 次日回款率
select
    '全部' bd_id,
    count(1) as `12月普通店铺活动量`,
    sum(if(date_diff('day',cast(pay_time as date),cast(begin_date as date))=1,1,0)) as `12月普通店铺次日回款活动量`,
    sum(if(date_diff('day',cast(pay_time as date),cast(begin_date as date))=1,1,0))/count(1) as `12月普通店铺次日回款率`
from dwd.dwd_sr_store_promotion
where dt between '2024-11-01' and '2024-12-31'
    and begin_date between '2024-12-01' and '2024-12-31'
    and store_type=0
    and status in (1,4,5)
group by 1

union all

select
    bd_id,
    count(1) as `12月普通店铺活动量`,
    sum(if(date_diff('day',cast(pay_time as date),cast(begin_date as date))=1,1,0)) as `12月普通店铺次日回款活动量`,
    sum(if(date_diff('day',cast(pay_time as date),cast(begin_date as date))=1,1,0))/count(1) as `12月普通店铺次日回款率`
from dwd.dwd_sr_store_promotion
where dt between '2024-11-01' and '2024-12-31'
    and begin_date between '2024-12-01' and '2024-12-31'
    and store_type=0
    and status in (1,4,5)
group by 1
;



== 近7天区县销单率
select
    t1.province_name `省份`,
    t1.city_name `城市`,
    t1.county_name `区县`,
    t2.province_name `店铺省份`,
    t2.city_name `店铺城市`,
    t2.district_name `店铺区县`,
    avg_quota `近7日日均活动名额`,
    avg_order_num `近7日日均有效订单量`
from dim.dim_silkworm_county t1
left join
-- 7日均值
(select
    province_name,
    city_name,
    district_name,
    avg(quota) as avg_quota,
    avg(order_num) as avg_order_num
from
    -- 汇总
    (select
        a.begin_date,
        b.province_name,
        b.city_name,
        b.district_name,
        sum(quota) as quota,
        sum(order_num) as order_num
    from
        (select
            store_id,
            begin_date,
            sum(eleme_promotion_quota+meituan_promotion_quota) as quota,
            sum(eleme_finished_num+meituan_finished_num) as order_num
        from dwd.dwd_sr_store_promotion
        where dt between '2025-01-01' and '2025-02-16'
            and begin_date between '2025-02-10' and '2025-02-16'
            and status in (1,4,5)
        group by 1,2
        ) a left join dim.dim_silkworm_store b on a.store_id=b.store_id
    group by 1,2,3,4
) c
group by 1,2,3
) t2
on t1.county_name=t2.district_name
;




