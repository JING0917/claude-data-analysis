● general_visit_num
● delivery_finished_order_num
● delivery_promotion_visit_num
● delivery_canceled_order_num
● delivery_submitted_order_num
● instore_finished_order_num
● instore_cancel_order_num
● instore_promotion_visit_num
● instore_submitted_order_num
● instore_portal_visit_num
● instore_paid_order_num



======== 第一部分 触发条件和计划目标事件
-- 说明：目标需要从清让（后端开发）获取，一个营销活动，最多4个目标，
-- 建议做聚合表模型，现在使用的是主键表建表
CREATE TABLE dws.dws_sr_marketing_ma_recon_h (
    `user_id` bigint not null comment "用户ID",
    `event_time` datetime not null comment "事件时间",
    `event_name` varchar(200) comment "事件名称",
    `event_cnt` int comment "事件次数"
) ENGINE=OLAP
PRIMARY KEY(`user_id`, `event_time`,`event_name`)
COMMENT "自动化营销触发小时数据"
-- PARTITION BY date_trunc('day', create_time)
DISTRIBUTED BY HASH(`user_id`)
PROPERTIES (
"replication_num" = "2",
"in_memory" = "false",
"enable_persistent_index" = "true",
"replicated_storage" = "true",
"compression" = "LZ4"
);



with view_user as (
select 
    user_id,
    event_id,
    concat(substr(event_time,1,13),':00:00') as event_time,
    activity_id,
    count(1) as cnt
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 1 day)
    and event_id in ('App_Launch','Takeout_Activity_Detail_View',
        'StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View')
group by 1,2,3,4
),

-- 到店活动
instore_pro as (
select
    category_type as cate1,
    sub_category_type as cate2,
    category_id as cate3,
    promotion_id
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 60 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
),


-- 霸王餐店铺活动
wm_pro as (
select
    store_promotion_id, -- 店铺活动ID
    sub_category_type as cate2 -- 店铺二级分类
from (
select 
    store_promotion_id,
    store_id
from dwd.dwd_sr_store_promotion
where dt between date_sub(current_date(),interval 60 day) and date_sub(current_date(),interval 1 day)
                and str_to_date(begin_date,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    sub_category_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
),


-- 霸王餐订单
-- 一级类目都是其他，dms看store表，category_type都是0，需要重新问下周总从下哪里取一级类目。一级类目在业务库中没有，因实时写入es。
wm_order as (
select
    b.user_id,
    b.event_time,
    b.order_status,
    a.cate2, -- 店铺二级分类
    sum(order_num) as order_num
from wm_pro a
inner join
-- 霸王餐订单
(select
    user_id,
    concat(substr(order_time,1,13),':00:00') as event_time,
    order_status,
    store_promotion_id,
    count(1) as order_num
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and store_promotion_id>0 -- 自营活动才有类目
group by 1,2,3,4) b 
    on a.store_promotion_id=b.store_promotion_id
group by 1,2,3,4
),


-- 到店订单
instore_order as (
select
    user_id,
    concat(substr(cast(create_time as string),1,13),':00:00') as event_time,
    status,
    count(1) as order_num
from
dwd.dwd_sr_silkworm_explore_order
where dt<=date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
group by 1,2,3
),


-- 访问+浏览
t1 as (
-- 访问
select
    user_id,
    event_time,
    'general_visit_num' as event_name,
    sum(cnt) as event_cnt
from view_user
where event_id='App_Launch'
group by 1,2,3

union all
-- 浏览霸王餐活动
select
    user_id,
    event_time,
    'delivery_promotion_visit_num' as event_name,
    count(distinct activity_id) as event_cnt
from view_user
where event_id='Takeout_Activity_Detail_View'
group by 1,2,3

union all
-- 浏览探店首页
select
    user_id,
    event_time,
    'instore_portal_visit_num' as event_name,
    sum(cnt) as event_cnt
from view_user
where event_id='StoreDiscovery_Homepage_View'
group by 1,2,3

union all
-- 浏览探店活动
select
    user_id,
    event_time,
    'instore_promotion_visit_num' as event_name,
    count(distinct activity_id) as event_cnt
from view_user
where event_id='StoreDiscovery_Activity_Details_View'
group by 1,2,3
),

-- 浏览探店类目
t2 as (
select
    a.user_id,
    a.event_id,
    a.event_time,
    b.cate1,
    b.cate2,
    b.cate3,
    sum(cnt) as cnt
from view_user a
left join instore_pro b on a.activity_id=b.promotion_id
group by 1,2,3,4,5,6
),

-- 浏览探店类目次数
t3 as (
-- 1&2&3级类目
select user_id,event_time,'instore_cate1_1_cate2_1_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=1 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_1_cate3_2_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=1 and cate3=2 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_1_cate3_3_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=1 and cate3=3 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_1_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=1 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_1_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=1 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_5_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=5 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_6_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=6 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_18_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=18 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_27_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=27 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_80_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=80 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_2_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=2 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_7_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=7 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_8_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=8 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_9_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=9 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_14_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=14 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_16_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=16 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_18_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=18 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_23_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=23 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_24_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=24 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_28_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=28 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_3_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=3 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_2_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=2 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_3_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=3 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_5_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=5 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_7_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=7 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_8_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=8 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_9_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=9 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_14_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=14 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_16_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=16 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_17_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=17 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_18_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=18 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_19_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=19 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_22_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=22 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_23_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=23 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_24_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=24 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_26_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=26 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_27_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=27 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_28_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=28 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_29_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=29 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_50_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=50 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_77_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=77 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_78_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=78 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_79_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=79 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_80_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=80 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_84_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=84 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_89_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=89 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_92_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=92 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_97_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=97 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_4_cate3_109_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=4 and cate3=109 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_8_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=8 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_2_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=2 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_3_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=3 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_6_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=6 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_7_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=7 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_8_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=8 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_9_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=9 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_12_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=12 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_14_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=14 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_16_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=16 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_17_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=17 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_18_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=18 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_19_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=19 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_20_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=20 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_22_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=22 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_23_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=23 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_24_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=24 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_25_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=25 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_26_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=26 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_27_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=27 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_28_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=28 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_29_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=29 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_78_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=78 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_79_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=79 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_92_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=92 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_97_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=97 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_1_cate2_11_cate3_109_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=1 and cate2=11 and cate3=109 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_7_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=7 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_7_cate3_77_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=7 and cate3=77 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_7_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=7 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_77_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=77 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_78_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=78 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_79_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=79 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_80_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=80 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_82_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=82 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_83_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=83 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_84_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=84 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_89_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=89 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_8_cate3_92_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=8 and cate3=92 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_3_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=3 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_2_cate2_10_cate3_109_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=2 and cate2=10 and cate3=109 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_29_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=29 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_30_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=30 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_31_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=31 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_34_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=34 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_40_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=40 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_42_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=42 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_50_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=50 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_84_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=84 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_5_cate3_97_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=5 and cate3=97 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_6_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=6 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_29_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=29 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_30_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=30 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_31_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=31 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_35_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=35 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_38_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=38 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_40_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=40 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_42_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=42 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_78_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=78 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_82_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=82 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_84_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=84 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_85_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=85 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_87_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=87 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_88_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=88 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_89_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=89 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_92_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=92 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_93_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=93 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_94_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=94 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_95_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=95 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_96_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=96 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_97_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=97 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_99_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=99 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_104_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=104 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_3_cate2_9_cate3_105_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=3 and cate2=9 and cate3=105 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_7_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=7 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_29_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=29 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_30_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=30 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_34_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=34 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_39_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=39 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_40_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=40 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_42_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=42 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_50_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=50 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_78_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=78 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_4_cate2_5_cate3_97_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=4 and cate2=5 and cate3=97 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_1_cate3_1_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=1 and cate3=1 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_1_cate3_2_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=1 and cate3=2 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_1_cate3_3_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=1 and cate3=3 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_1_cate3_4_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=1 and cate3=4 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_1_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=1 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_2_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=2 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_3_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=3 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_7_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=7 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_8_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=8 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_14_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=14 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_16_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=16 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_18_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=18 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_22_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=22 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_23_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=23 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_24_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=24 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_79_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=79 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_80_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=80 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_5_cate2_4_cate3_109_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=5 and cate2=4 and cate3=109 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_7_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=7 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_8_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=8 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_9_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=9 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_10_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=10 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_13_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=13 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_14_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=14 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_15_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=15 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_16_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=16 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_24_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=24 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_28_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=28 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_6_cate2_3_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=6 and cate2=3 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_5_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=5 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_6_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=6 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_11_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=11 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_18_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=18 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_21_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=21 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_27_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=27 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_80_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=80 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_81_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=81 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_7_cate2_2_cate3_108_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=7 and cate2=2 and cate3=108 group by 1,2,3 union all
select user_id,event_time,'instore_cate1_8_cate2_6_cate3_52_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1=8 and cate2=6 and cate3=52 group by 1,2,3
),



-- 订单量
t4 as (
-- 霸王餐
select user_id,event_time,'delivery_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) group by 1,2,3 union all
select user_id,event_time,'delivery_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) group by 1,2,3 union all
select user_id,event_time,'delivery_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order group by 1,2,3 union all
-- 霸王餐二级类目完单
select user_id,event_time,'delivery_cate2_1_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=1 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_2_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=2 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_3_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=3 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_4_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=4 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_5_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=5 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_6_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=6 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_7_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=7 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_8_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=8 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_9_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and cate2=9 group by 1,2,3 union all
-- 霸王餐二级类目取消
select user_id,event_time,'delivery_cate2_1_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=1 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_2_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=2 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_3_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=3 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_4_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=4 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_5_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=5 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_6_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=6 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_7_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=7 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_8_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=8 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_9_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and cate2=9 group by 1,2,3 union all
-- 霸王餐二级类目提交
select user_id,event_time,'delivery_cate2_1_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=1 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_2_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=2 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_3_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=3 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_4_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=4 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_5_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=5 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_6_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=6 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_7_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=7 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_8_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=8 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_9_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where cate2=9 group by 1,2,3 union all
-- 到店
select user_id,event_time,'instore_finished_order_num' as event_name,sum(order_num) as event_cnt from instore_order where status in (4,5,19,20) group by 1,2,3 union all
select user_id,event_time,'instore_cancel_order_num' as event_name,sum(order_num) as event_cnt from instore_order where status in (6,7,8,9,10,11,14,17,18,21,22,23,26,28,29,33) group by 1,2,3 union all
select user_id,event_time,'instore_submitted_order_num' as event_name,sum(order_num) as event_cnt from instore_order group by 1,2,3 union all
select user_id,event_time,'instore_paid_order_num' as event_name,sum(order_num) as event_cnt from instore_order where status in (3,4,5,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,28,30,31,32,33,34) group by 1,2,3
),


-- 浏览霸王餐活动类目
t5 as (
select
    a.user_id,
    a.event_id,
    a.event_time,
    b.sub_category_type,
    sum(cnt) as cnt
from view_user a
left join wm_pro b on a.activity_id=b.store_promotion_id
group by 1,2,3,4
),


-- 浏览霸王餐活动二级类目次数
t6 as (
-- 二级类目
select user_id,event_time,'delivery_cate2_1_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=1 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_2_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=2 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_3_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=3 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_4_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=4 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_5_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=5 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_6_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=6 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_7_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=7 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_8_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=8 group by 1,2,3 union all
select user_id,event_time,'delivery_cate2_9_visit_num' as event_name,sum(cnt) as event_cnt from t5 where cate2=9 group by 1,2,3
)


-- 触发事件汇总
select user_id,event_time,event_name,event_cnt from t1
union all
select user_id,event_time,event_name,event_cnt from t3
union all
select user_id,event_time,event_name,event_cnt from t4
union all
select user_id,event_time,event_name,event_cnt from t6
;






=============== 第二部分 事件维表  将触发事件和计划目标事件合在一起 展开各类目
CREATE TABLE dim.dim_ma_event (
    `create_time` datetime not null comment "创建时间",
    `event_ename` varchar(200) not null comment "事件英文名称"
    `event_cname` varchar(200) not null comment "事件中文名称"
    `index_name` varchar(200) not null comment "指标名称"
) ENGINE=OLAP
PRIMARY KEY(`create_time`,`event_name`)
COMMENT "自动化营销事件"
PARTITION BY date_trunc('day', create_time)
DISTRIBUTED BY HASH(`create_time`)
PROPERTIES (
"replication_num" = "2",
"in_memory" = "false",
"enable_persistent_index" = "true",
"replicated_storage" = "true",
"compression" = "LZ4"
);



-- 访问+浏览
t1 as (
-- 访问+浏览
select now() as event_time,'general_visit_num' as event_ename,'访问应用' as event_cname,'访问次数' as index_name union all
select now() as event_time,'delivery_promotion_visit_num' as event_ename,'浏览霸王餐活动' as event_cname,'浏览霸王餐活动数' as index_name union all
select now() as event_time,'instore_portal_visit_num' as event_ename,'访问探店首页' as event_cname,'访问次数' as index_name union all
select now() as event_time,'instore_promotion_visit_num' as event_ename,'浏览探店活动类目' as event_cname,'浏览探店活动数' as index_name union all
-- 浏览探店
select now() as event_time,'instore_cate1_1_cate2_1_cate3_1_visit_num' as event_ename,'浏览探店活动正餐美食包子粥铺包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_1_cate3_2_visit_num' as event_ename,'浏览探店活动正餐美食包子粥铺面馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_1_cate3_3_visit_num' as event_ename,'浏览探店活动正餐美食包子粥铺小吃快餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_1_cate3_11_visit_num' as event_ename,'浏览探店活动正餐美食包子粥铺快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_1_cate3_13_visit_num' as event_ename,'浏览探店活动正餐美食包子粥铺本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_1_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_5_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐汉堡西餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_6_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐西餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_11_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_15_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_18_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐韩国料理' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_21_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_27_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐粤菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_80_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐咖啡厅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_81_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_2_cate3_108_visit_num' as event_ename,'浏览探店活动正餐美食汉堡西餐炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_7_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤火锅烧烤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_8_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤火锅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_9_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤烤肉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_10_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_11_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_13_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_14_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤川菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_15_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_16_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤东北菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_18_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤韩国料理' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_21_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_23_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤特色菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_24_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤湘菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_28_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤自助餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_3_cate3_108_visit_num' as event_ename,'浏览探店活动正餐美食火锅烧烤炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_2_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐面馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_3_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐小吃快餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_5_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐汉堡西餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_7_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐火锅烧烤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_8_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐火锅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_9_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐烤肉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_10_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_11_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_13_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_14_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐川菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_15_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_16_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐东北菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_17_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐东南亚菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_18_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐韩国料理' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_19_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐家常菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_21_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_22_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐私房菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_23_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐特色菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_24_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐湘菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_26_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐鱼鲜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_27_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐粤菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_28_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐自助餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_29_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐理发/男士' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_50_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐医学美容' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_77_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐水果生鲜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_78_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐甜品饮品' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_79_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_80_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐咖啡厅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_81_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_84_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐休闲/玩乐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_89_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_92_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐酒吧' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_97_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐球类运动' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_108_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_4_cate3_109_visit_num' as event_ename,'浏览探店活动正餐美食快餐简餐螺蛳粉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_8_cate3_11_visit_num' as event_ename,'浏览探店活动正餐美食甜品饮品快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_1_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_2_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐面馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_3_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐小吃快餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_6_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐西餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_7_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐火锅烧烤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_8_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐火锅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_9_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐烤肉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_10_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_11_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_12_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐北京菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_13_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_14_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐川菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_15_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_16_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐东北菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_17_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐东南亚菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_18_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐韩国料理' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_19_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐家常菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_20_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐农家菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_21_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_22_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐私房菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_23_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐特色菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_24_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐湘菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_25_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐新疆菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_26_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐鱼鲜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_27_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐粤菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_28_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐自助餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_29_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐理发/男士' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_78_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐甜品饮品' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_79_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_81_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_92_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐酒吧' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_97_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐球类运动' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_108_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_1_cate2_11_cate3_109_visit_num' as event_ename,'浏览探店活动正餐美食正餐/多人餐螺蛳粉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_7_cate3_1_visit_num' as event_ename,'浏览探店活动饮品小吃水果生鲜包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_7_cate3_77_visit_num' as event_ename,'浏览探店活动饮品小吃水果生鲜水果生鲜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_7_cate3_108_visit_num' as event_ename,'浏览探店活动饮品小吃水果生鲜炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_10_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_11_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_15_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_77_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品水果生鲜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_78_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品甜品饮品' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_79_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_80_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品咖啡厅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_81_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_82_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品食品滋补' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_83_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品饮品店' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_84_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品休闲/玩乐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_89_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_8_cate3_92_visit_num' as event_ename,'浏览探店活动饮品小吃甜品饮品酒吧' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_3_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃小吃快餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_10_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_11_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_21_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_81_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_108_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_2_cate2_10_cate3_109_visit_num' as event_ename,'浏览探店活动饮品小吃炸串小吃螺蛳粉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_29_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士理发/男士' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_30_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士SPA按摩' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_31_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士熬夜修护' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_34_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士防脱养发' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_40_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士美甲' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_42_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士美容/清洁' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_50_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士医学美容' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_84_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士休闲/玩乐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_5_cate3_97_visit_num' as event_ename,'浏览探店活动休闲玩乐理发/男士球类运动' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_6_cate3_1_visit_num' as event_ename,'浏览探店活动休闲玩乐亲子/乐园包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_11_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_15_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_29_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐理发/男士' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_30_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐SPA按摩' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_31_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐熬夜修护' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_35_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐减肥瘦身' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_38_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐美白嫩肤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_40_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐美甲' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_42_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐美容/清洁' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_78_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐甜品饮品' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_82_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐食品滋补' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_84_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐休闲/玩乐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_85_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐DIY手工坊' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_87_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐Live House' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_88_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐按摩/足疗' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_89_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_92_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐酒吧' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_93_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐剧本杀' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_94_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐撸宠' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_95_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐密室/沉浸' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_96_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐棋牌室' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_97_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐球类运动' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_99_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐台球馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_104_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐新奇体验' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_3_cate2_9_cate3_105_visit_num' as event_ename,'浏览探店活动休闲玩乐休闲/玩乐游乐游艺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_1_visit_num' as event_ename,'浏览探店活动生活服务理发/男士包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_7_visit_num' as event_ename,'浏览探店活动生活服务理发/男士火锅烧烤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_11_visit_num' as event_ename,'浏览探店活动生活服务理发/男士快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_29_visit_num' as event_ename,'浏览探店活动生活服务理发/男士理发/男士' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_30_visit_num' as event_ename,'浏览探店活动生活服务理发/男士SPA按摩' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_34_visit_num' as event_ename,'浏览探店活动生活服务理发/男士防脱养发' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_39_visit_num' as event_ename,'浏览探店活动生活服务理发/男士美发' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_40_visit_num' as event_ename,'浏览探店活动生活服务理发/男士美甲' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_42_visit_num' as event_ename,'浏览探店活动生活服务理发/男士美容/清洁' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_50_visit_num' as event_ename,'浏览探店活动生活服务理发/男士医学美容' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_78_visit_num' as event_ename,'浏览探店活动生活服务理发/男士甜品饮品' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_4_cate2_5_cate3_97_visit_num' as event_ename,'浏览探店活动生活服务理发/男士球类运动' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_1_cate3_1_visit_num' as event_ename,'浏览探店活动快餐简餐包子粥铺包子粥铺' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_1_cate3_2_visit_num' as event_ename,'浏览探店活动快餐简餐包子粥铺面馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_1_cate3_3_visit_num' as event_ename,'浏览探店活动快餐简餐包子粥铺小吃快餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_1_cate3_4_visit_num' as event_ename,'浏览探店活动快餐简餐包子粥铺早茶' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_1_cate3_13_visit_num' as event_ename,'浏览探店活动快餐简餐包子粥铺本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_2_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐面馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_3_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐小吃快餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_7_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐火锅烧烤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_8_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐火锅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_10_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_11_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_13_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_14_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐川菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_16_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐东北菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_18_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐韩国料理' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_21_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_22_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐私房菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_23_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐特色菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_24_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐湘菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_79_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐茶馆' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_80_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐咖啡厅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_81_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_108_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_5_cate2_4_cate3_109_visit_num' as event_ename,'浏览探店活动快餐简餐快餐简餐螺蛳粉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_7_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤火锅烧烤' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_8_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤火锅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_9_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤烤肉' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_10_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤烧烤烤串' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_11_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_13_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤本帮江浙菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_14_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤川菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_15_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤创意菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_16_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤东北菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_24_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤湘菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_28_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤自助餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_6_cate2_3_cate3_108_visit_num' as event_ename,'浏览探店活动火锅烧烤火锅烧烤炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_5_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐汉堡西餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_6_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐西餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_11_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐快餐简餐' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_18_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐韩国料理' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_21_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐日本菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_27_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐粤菜' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_80_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐咖啡厅' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_81_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐面包甜点' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_7_cate2_2_cate3_108_visit_num' as event_ename,'浏览探店活动汉堡西餐汉堡西餐炸串小吃' as event_cname,'浏览探店活动类目' as index_name union all
select now() as event_time,'instore_cate1_8_cate2_6_cate3_52_visit_num' as event_ename,'浏览探店活动亲子乐园亲子/乐园亲子/乐园' as event_cname,'浏览探店活动类目' as index_name union all
-- 霸王餐订单
select now() as event_time,'delivery_finished_order_num' as event_ename,'完成霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_canceled_order_num' as event_ename,'取消霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_submitted_order_num' as event_ename,'提交霸王餐订单' as event_cname,'订单数' as index_name union all
-- 霸王餐二级完单
select now() as event_time,'delivery_cate2_1_finished_order_num' as event_ename,'完成包子粥铺霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_2_finished_order_num' as event_ename,'完成快餐简餐霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_3_finished_order_num' as event_ename,'完成甜品饮品霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_4_finished_order_num' as event_ename,'完成炸串小吃霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_5_finished_order_num' as event_ename,'完成火锅烧烤霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_6_finished_order_num' as event_ename,'完成汉堡西餐霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_7_finished_order_num' as event_ename,'完成零售霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_8_finished_order_num' as event_ename,'完成水果鲜花霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_9_finished_order_num' as event_ename,'完成成人用品霸王餐订单' as event_cname,'订单数' as index_name union all
-- 霸王餐二级取消
select now() as event_time,'delivery_cate2_1_canceled_order_num' as event_ename,'取消包子粥铺霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_2_canceled_order_num' as event_ename,'取消快餐简餐霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_3_canceled_order_num' as event_ename,'取消甜品饮品霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_4_canceled_order_num' as event_ename,'取消炸串小吃霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_5_canceled_order_num' as event_ename,'取消火锅烧烤霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_6_canceled_order_num' as event_ename,'取消汉堡西餐霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_7_canceled_order_num' as event_ename,'取消零售霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_8_canceled_order_num' as event_ename,'取消水果鲜花霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_9_canceled_order_num' as event_ename,'取消成人用品霸王餐订单' as event_cname,'订单数' as index_name union all
-- 霸王餐二级提交
select now() as event_time,'delivery_cate2_1_submitted_order_num' as event_ename,'提交包子粥铺霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_2_submitted_order_num' as event_ename,'提交快餐简餐霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_3_submitted_order_num' as event_ename,'提交甜品饮品霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_4_submitted_order_num' as event_ename,'提交炸串小吃霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_5_submitted_order_num' as event_ename,'提交火锅烧烤霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_6_submitted_order_num' as event_ename,'提交汉堡西餐霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_7_submitted_order_num' as event_ename,'提交零售霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_8_submitted_order_num' as event_ename,'提交水果鲜花霸王餐订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'delivery_cate2_9_submitted_order_num' as event_ename,'提交成人用品霸王餐订单' as event_cname,'订单数' as index_name union all
-- 到店
select now() as event_time,'instore_finished_order_num' as event_ename,'完成探店订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'instore_cancel_order_num' as event_ename,'取消探店订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'instore_submitted_order_num' as event_ename,'提交探店订单' as event_cname,'订单数' as index_name union all
select now() as event_time,'instore_paid_order_num' as event_ename,'支付探店订单' as event_cname,'订单数' as index_name union all
-- 浏览霸王餐二级
select now() as event_time,'delivery_cate2_1_visit_num' as event_ename,'浏览霸王餐活动包子粥铺' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_2_visit_num' as event_ename,'浏览霸王餐活动快餐简餐' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_3_visit_num' as event_ename,'浏览霸王餐活动甜品饮品' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_4_visit_num' as event_ename,'浏览霸王餐活动炸串小吃' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_5_visit_num' as event_ename,'浏览霸王餐活动火锅烧烤' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_6_visit_num' as event_ename,'浏览霸王餐活动汉堡西餐' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_7_visit_num' as event_ename,'浏览霸王餐活动零售' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_8_visit_num' as event_ename,'浏览霸王餐活动水果鲜花' as event_cname,'浏览霸王餐活动类目' as index_name union all
select now() as event_time,'delivery_cate2_9_visit_num' as event_ename,'浏览霸王餐活动成人用品' as event_cname,'浏览霸王餐活动类目' as index_name





======= 第三部分 将霸王餐二级类目、到店一二三级类目，同步到清让指定的MySQL库，或者大数据自己的MySQL库（优先后端指定）
-- 1、霸王餐二级类目口径
-- 每日全量同步
select
    sub_category_type as cate2,
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
    else '其他' end as cat2_name
from dim.dim_silkworm_store
group by 1,2;


-- 2、探店订单类目
从dim.dim_silkworm_explore_cate直接抽，推到MySQL。dim.dim_silkworm_explore_cate表，手动维护，达哥这边从跳板机导入sr。


========= 第四部分 用户触达成功，打上标签
-- 创建运营计划时，用户配置时，给你触达到的用户打标签，标签需要从清让那边同步过来，落SR。（具体标签数据格式和值，需要再看）



================== 第五部分 目标达成统计
CREATE TABLE dws.dws_sr_marketing_ma_target_progress (
    `user_id` bigint not null comment "用户ID",
    `plan_id` bigint not null comment "计划ID",
    `target_name` varchar(200) comment "目标名称",
    `is_finished` int comment "是否完成目标(0:否,1:是)"
) ENGINE=OLAP
PRIMARY KEY(`user_id`, `plan_id`,`target_name`)
COMMENT "自动化营销目标进度"
-- PARTITION BY date_trunc('day', create_time)
DISTRIBUTED BY HASH(`user_id`)
PROPERTIES (
"replication_num" = "2",
"in_memory" = "false",
"enable_persistent_index" = "true",
"replicated_storage" = "true",
"compression" = "LZ4"
);



















