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



======== 第一部分 触发条件
-- 建议做聚合表模型，现在使用的是主键表建表
CREATE TABLE dws.dws_sr_marketing_ma_recon_h (
    `user_id` bigint not null comment "用户ID",
    `event_time` datetime not null comment "事件时间",
    `event_name` varchar(200) comment "事件名称",
    `event_cnt` int comment "事件次数"
) ENGINE=OLAP
PRIMARY KEY(`user_id`, `event_time`,`event_name`)
COMMENT "自动化营销触达小时数据"
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
    case when category_type=1 then '正餐美食'
        when category_type=2 then '饮品小吃' when category_type=3 then '休闲玩乐' when category_type=4 then '生活服务' when category_type=5 then '快餐简餐' when category_type=6 then '火锅烧烤' when category_type=7 then '汉堡西餐' when category_type=8 then '亲子乐园' else '其他' end cate1,
    case when sub_category_type=1 then '包子粥铺' when sub_category_type=2 then '汉堡西餐' when sub_category_type=3 then '火锅烧烤' when sub_category_type=4 then '快餐简餐' when sub_category_type=5 then '美发/丽人' when sub_category_type=6 then '亲子/乐园' when sub_category_type=7 then '水果生鲜' when sub_category_type=8 then '甜品饮品' when sub_category_type=9 then '休闲/玩乐' when sub_category_type=10 then '炸串小吃' when sub_category_type=11 then '正餐/多人餐' else '其他' end cate2,
case when category_id=1 then '包子粥铺' when category_id=2 then '面馆' when category_id=3 then '小吃快餐' when category_id=4 then '早茶' when category_id=5 then '汉堡西餐' when category_id=6 then '西餐' when category_id=7 then '火锅烧烤' when category_id=8 then '火锅' when category_id=9 then '烤肉' when category_id=10 then '烧烤烤串' when category_id=11 then '快餐简餐' when category_id=12 then '北京菜' when category_id=13 then '本帮江浙菜' when category_id=14 then '川菜' when category_id=15 then '创意菜' when category_id=16 then '东北菜' when category_id=17 then '东南亚菜' when category_id=18 then '韩国料理' when category_id=19 then '家常菜' when category_id=20 then '农家菜' when category_id=21 then '日本菜' when category_id=22 then '私房菜' when category_id=23 then '特色菜' when category_id=24 then '湘菜' when category_id=25 then '新疆菜' when category_id=26 then '鱼鲜' when category_id=27 then '粤菜' when category_id=28 then '自助餐' when category_id=29 then '理发/男士' when category_id=30 then 'SPA按摩' when category_id=31 then '熬夜修护' when category_id=31 then '补水保湿' when category_id=33 then '潮流染发' when category_id=34 then '防脱养发' when category_id=35 then '减肥瘦身' when category_id=36 then '紧致抗衰' when category_id=37 then '境外医美' when category_id=38 then '美白嫩肤' when category_id=39 then '美发' when category_id=40 then '美甲' when category_id=41 then '美睫' when category_id=42 then '美容/清洁' when category_id=43 then '美妆护肤' when category_id=44 then '祛痘' when category_id=45 then '头疗' when category_id=46 then '脱毛' when category_id=47 then '纹眉纹绣' when category_id=48 then '纹身' when category_id=49 then '舞蹈' when category_id=50 then '医学美容' when category_id=51 then '瑜伽/普拉提' when category_id=52 then '亲子/乐园' when category_id=53 then '冰雪海洋馆' when category_id=54 then '博物馆' when category_id=55 then '带娃泡汤' when category_id=56 then '电玩游戏' when category_id in (57,90) then '儿童乐园' when category_id=58 then '儿童摄影' when category_id=59 then '儿童游泳' when category_id=60 then '公园植物园' when category_id=61 then '滑板轮滑' when category_id=62 then '击剑培训' when category_id=63 then '篮球培训' when category_id=64 then '母婴购物' when category_id=65 then '农家采摘' when category_id=66 then '亲子餐厅' when category_id=67 then '亲子活动' when category_id=68 then '亲子酒店' when category_id=69 then '亲子游泳' when category_id=70 then '体适能培训' when category_id=71 then '托班/托儿所' when category_id=72 then '演出/展览' when category_id=73 then '婴幼服务' when category_id=74 then '孕产服务' when category_id=75 then '孕妇摄影' when category_id=76 then '早教' when category_id=77 then '水果生鲜' when category_id=78 then '甜品饮品' when category_id in (79,89) then '茶馆' when category_id=80 then '咖啡厅' when category_id=81 then '面包甜点' when category_id=82 then '食品滋补' when category_id=83 then '饮品店' when category_id=84 then '休闲/玩乐' when category_id=85 then 'DIY手工坊' when category_id=86 then 'KTV' when category_id=87 then 'Live House' when category_id=88 then '按摩/足疗' when category_id=91 then '健身中心' when category_id=92 then '酒吧' when category_id=93 then '剧本杀' when category_id=94 then '撸宠' when category_id=95 then '密室/沉浸' when category_id=96 then '棋牌室' when category_id=97 then '球类运动' when category_id=98 then '私人影院' when category_id=99 then '台球馆' when category_id=100 then '体育场馆' when category_id=101 then '团建/轰趴' when category_id=102 then '网吧/电竞' when category_id=103 then '洗浴/汗蒸' when category_id=104 then '新奇体验' when category_id=105 then '游乐游艺' when category_id=106 then '游泳馆' when category_id=107 then '桌面游戏' when category_id=108 then '炸串小吃' when category_id=109 then '螺蛳粉' when category_id=110 then '小龙虾' else '其他' end cate3,
    promotion_id
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 60 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
),


-- 霸王餐订单
wm_order as (
select
    user_id,
    concat(substr(order_time,1,13),':00:00') as event_time,
    order_status,
    count(1) as order_num
from dwd.dwd_sr_order_promotion_order
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
group by 1,2,3),


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
-- 一级类目
select user_id,event_time,'instore_cate1_zcms_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='正餐美食' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_xxwl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='休闲玩乐' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_shfw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='生活服务' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_qzly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='亲子乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_ypxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='饮品小吃' group by 1,2,3 union all
-- 二级类目
select user_id,event_time,'instore_cate2_bzzp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='包子粥铺' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_mflr_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='美发/丽人' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_qzly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='亲子/乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_sgsx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='水果生鲜' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_tpyp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='甜品饮品' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_xxwl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='休闲/玩乐' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_zcxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='炸串小吃' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_zcdrc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='正餐/多人餐' group by 1,2,3 union all
-- 三级类目
select user_id,event_time,'instore_cate3_bzzp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='包子粥铺' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_migu_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='面馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xckc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='小吃快餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zaocha_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='早茶' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xican_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_huoguo_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='火锅' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_kaorou_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='烤肉' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_skkc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='烧烤烤串' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='北京菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bbjzc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='本帮江浙菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_chca_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='川菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_cyc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='创意菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dbc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='东北菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dnyc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='东南亚菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hgll_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='韩国料理' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jcc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='家常菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_njc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='农家菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_rbc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='日本菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_sfc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='私房菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tsc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='特色菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='湘菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='新疆菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yuxian_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='鱼鲜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yuecai_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='粤菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zizc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='自助餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lfns_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='理发/男士' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_spam_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='SPA按摩' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ayxh_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='熬夜修护' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bsbs_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='补水保湿' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_chlrf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='潮流染发' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ftyf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='防脱养发' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jfjs_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='减肥瘦身' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jzks_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='紧致抗衰' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jwym_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='境外医美' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mbnf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美白嫩肤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_meifa_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美发' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_meijia_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美甲' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_meijie_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美睫' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mrqj_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美容/清洁' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mzhf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美妆护肤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qudou_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='祛痘' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_touliao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='头疗' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tuomao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='脱毛' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wmwx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='纹眉纹绣' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wenshen_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='纹身' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wudao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='舞蹈' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yxmr_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='医学美容' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yjplt_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='瑜伽/普拉提' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子/乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bxhyg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='冰雪海洋馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bowuguan_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='博物馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dwpt_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='带娃泡汤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dwyx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='电玩游戏' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_etly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='儿童乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_etsy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='儿童摄影' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_etyy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='儿童游泳' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_gyzwy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='公园植物园' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hblh_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='滑板轮滑' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jjpx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='击剑培训' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lqpx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='篮球培训' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mygw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='母婴购物' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_njcz_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='农家采摘' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzct_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子餐厅' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzhd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子活动' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzjd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子酒店' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzyy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子游泳' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tsnpx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='体适能培训' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tuoersuo_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='托班/托儿所' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yczl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='演出/展览' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yyfw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='婴幼服务' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ycfw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='孕产服务' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yfsy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='孕妇摄影' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zaojiao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='早教' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_sgsx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='水果生鲜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tpyp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='甜品饮品' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_chaguan_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='茶馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_kft_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='咖啡厅' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mbtd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='面包甜点' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_spzb_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='食品滋补' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ypd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='饮品店' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xxwl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='休闲/玩乐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_diy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='DIY手工坊' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ktv_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='KTV' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lh_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='Live House' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_amzl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='按摩/足疗' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jszx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='健身中心' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jb_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='酒吧' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jbs_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='剧本杀' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='撸宠' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mscj_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='密室/沉浸' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qps_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='棋牌室' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qlyd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='球类运动' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_sryy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='私人影院' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tqg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='台球馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tycg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '体育场馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tjhp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '团建/轰趴' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wbdj_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '网吧/电竞' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xyhz_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '洗浴/汗蒸' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xqty_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '新奇体验' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ylyy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '游乐游艺' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yyg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '游泳馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zmyx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '桌面游戏' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zcxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '炸串小吃' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lsf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '螺蛳粉' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xlx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '小龙虾' group by 1,2,3
),


-- 订单量
t4 as (
-- 霸王餐
select user_id,event_time,'delivery_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) group by 1,2,3 union all
select user_id,event_time,'delivery_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) group by 1,2,3 union all
select user_id,event_time,'delivery_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order group by 1,2,3 union all
-- 到店
select user_id,event_time,'instore_finished_order_num' as event_name,sum(order_num) as event_cnt from instore_order where status in (4,5,19,20) group by 1,2,3 union all
select user_id,event_time,'instore_cancel_order_num' as event_name,sum(order_num) as event_cnt from instore_order where status in (6,7,8,9,10,11,14,17,18,21,22,23,26,28,29,33) group by 1,2,3 union all
select user_id,event_time,'instore_submitted_order_num' as event_name,sum(order_num) as event_cnt from instore_order group by 1,2,3 union all
select user_id,event_time,'instore_paid_order_num' as event_name,sum(order_num) as event_cnt from instore_order where status in (3,4,5,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,28,30,31,32,33,34) group by 1,2,3
)


-- 触发事件汇总
select user_id,event_time,event_name,event_cnt from t1
union all
select user_id,event_time,event_name,event_cnt from t3
union all
select user_id,event_time,event_name,event_cnt from t4
;


=============== 第二部分 目标完成
-- 说明：目标需要从清让（后端开发）获取，一个营销活动，最多4个目标，

-- 建议做聚合表模型，现在使用的是主键表建表
CREATE TABLE dws.dws_sr_marketing_ma_target_h (
    `user_id` bigint not null comment "用户ID",
    `event_time` datetime not null comment "事件时间",
    `event_name` varchar(200) comment "事件名称",
    `event_cnt` int comment "事件次数"
) ENGINE=OLAP
PRIMARY KEY(`user_id`, `event_time`,`event_name`)
COMMENT "自动化营销目标小时数据"
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
    case when category_type=1 then '正餐美食'
        when category_type=2 then '饮品小吃' when category_type=3 then '休闲玩乐' when category_type=4 then '生活服务' when category_type=5 then '快餐简餐' when category_type=6 then '火锅烧烤' when category_type=7 then '汉堡西餐' when category_type=8 then '亲子乐园' else '其他' end cate1,
    case when sub_category_type=1 then '包子粥铺' when sub_category_type=2 then '汉堡西餐' when sub_category_type=3 then '火锅烧烤' when sub_category_type=4 then '快餐简餐' when sub_category_type=5 then '美发/丽人' when sub_category_type=6 then '亲子/乐园' when sub_category_type=7 then '水果生鲜' when sub_category_type=8 then '甜品饮品' when sub_category_type=9 then '休闲/玩乐' when sub_category_type=10 then '炸串小吃' when sub_category_type=11 then '正餐/多人餐' else '其他' end cate2,
case when category_id=1 then '包子粥铺' when category_id=2 then '面馆' when category_id=3 then '小吃快餐' when category_id=4 then '早茶' when category_id=5 then '汉堡西餐' when category_id=6 then '西餐' when category_id=7 then '火锅烧烤' when category_id=8 then '火锅' when category_id=9 then '烤肉' when category_id=10 then '烧烤烤串' when category_id=11 then '快餐简餐' when category_id=12 then '北京菜' when category_id=13 then '本帮江浙菜' when category_id=14 then '川菜' when category_id=15 then '创意菜' when category_id=16 then '东北菜' when category_id=17 then '东南亚菜' when category_id=18 then '韩国料理' when category_id=19 then '家常菜' when category_id=20 then '农家菜' when category_id=21 then '日本菜' when category_id=22 then '私房菜' when category_id=23 then '特色菜' when category_id=24 then '湘菜' when category_id=25 then '新疆菜' when category_id=26 then '鱼鲜' when category_id=27 then '粤菜' when category_id=28 then '自助餐' when category_id=29 then '理发/男士' when category_id=30 then 'SPA按摩' when category_id=31 then '熬夜修护' when category_id=31 then '补水保湿' when category_id=33 then '潮流染发' when category_id=34 then '防脱养发' when category_id=35 then '减肥瘦身' when category_id=36 then '紧致抗衰' when category_id=37 then '境外医美' when category_id=38 then '美白嫩肤' when category_id=39 then '美发' when category_id=40 then '美甲' when category_id=41 then '美睫' when category_id=42 then '美容/清洁' when category_id=43 then '美妆护肤' when category_id=44 then '祛痘' when category_id=45 then '头疗' when category_id=46 then '脱毛' when category_id=47 then '纹眉纹绣' when category_id=48 then '纹身' when category_id=49 then '舞蹈' when category_id=50 then '医学美容' when category_id=51 then '瑜伽/普拉提' when category_id=52 then '亲子/乐园' when category_id=53 then '冰雪海洋馆' when category_id=54 then '博物馆' when category_id=55 then '带娃泡汤' when category_id=56 then '电玩游戏' when category_id in (57,90) then '儿童乐园' when category_id=58 then '儿童摄影' when category_id=59 then '儿童游泳' when category_id=60 then '公园植物园' when category_id=61 then '滑板轮滑' when category_id=62 then '击剑培训' when category_id=63 then '篮球培训' when category_id=64 then '母婴购物' when category_id=65 then '农家采摘' when category_id=66 then '亲子餐厅' when category_id=67 then '亲子活动' when category_id=68 then '亲子酒店' when category_id=69 then '亲子游泳' when category_id=70 then '体适能培训' when category_id=71 then '托班/托儿所' when category_id=72 then '演出/展览' when category_id=73 then '婴幼服务' when category_id=74 then '孕产服务' when category_id=75 then '孕妇摄影' when category_id=76 then '早教' when category_id=77 then '水果生鲜' when category_id=78 then '甜品饮品' when category_id in (79,89) then '茶馆' when category_id=80 then '咖啡厅' when category_id=81 then '面包甜点' when category_id=82 then '食品滋补' when category_id=83 then '饮品店' when category_id=84 then '休闲/玩乐' when category_id=85 then 'DIY手工坊' when category_id=86 then 'KTV' when category_id=87 then 'Live House' when category_id=88 then '按摩/足疗' when category_id=91 then '健身中心' when category_id=92 then '酒吧' when category_id=93 then '剧本杀' when category_id=94 then '撸宠' when category_id=95 then '密室/沉浸' when category_id=96 then '棋牌室' when category_id=97 then '球类运动' when category_id=98 then '私人影院' when category_id=99 then '台球馆' when category_id=100 then '体育场馆' when category_id=101 then '团建/轰趴' when category_id=102 then '网吧/电竞' when category_id=103 then '洗浴/汗蒸' when category_id=104 then '新奇体验' when category_id=105 then '游乐游艺' when category_id=106 then '游泳馆' when category_id=107 then '桌面游戏' when category_id=108 then '炸串小吃' when category_id=109 then '螺蛳粉' when category_id=110 then '小龙虾' else '其他' end cate3,
    promotion_id
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 60 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
),


-- -- 店铺活动
wm_pro as (
select
    store_promotion_id, -- 店铺活动ID
    category_type, -- 店铺一级分类
    sub_category_type -- 店铺二级分类
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
    else '其他' end as sub_category_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
),


-- 霸王餐订单
-- 一级类目都是其他，dms看store表，category_type都是0，需要重新问下周总从下哪里取一级类目
wm_order as (
select
    b.user_id,
    b.event_time,
    b.order_status,
    a.category_type, -- 店铺一级分类
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
-- 一级类目
select user_id,event_time,'instore_cate1_zcms_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='正餐美食' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_xxwl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='休闲玩乐' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_shfw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='生活服务' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_qzly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='亲子乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate1_ypxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate1='饮品小吃' group by 1,2,3 union all
-- 二级类目
select user_id,event_time,'instore_cate2_bzzp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='包子粥铺' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_mflr_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='美发/丽人' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_qzly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='亲子/乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_sgsx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='水果生鲜' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_tpyp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='甜品饮品' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_xxwl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='休闲/玩乐' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_zcxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='炸串小吃' group by 1,2,3 union all
select user_id,event_time,'instore_cate2_zcdrc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate2='正餐/多人餐' group by 1,2,3 union all
-- 三级类目
select user_id,event_time,'instore_cate3_bzzp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='包子粥铺' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_migu_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='面馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xckc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='小吃快餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zaocha_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='早茶' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xican_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='西餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_huoguo_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='火锅' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_kaorou_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='烤肉' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_skkc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='烧烤烤串' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='北京菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bbjzc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='本帮江浙菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_chca_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='川菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_cyc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='创意菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dbc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='东北菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dnyc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='东南亚菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hgll_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='韩国料理' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jcc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='家常菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_njc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='农家菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_rbc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='日本菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_sfc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='私房菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tsc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='特色菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='湘菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xjc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='新疆菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yuxian_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='鱼鲜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yuecai_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='粤菜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zizc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='自助餐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lfns_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='理发/男士' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_spam_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='SPA按摩' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ayxh_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='熬夜修护' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bsbs_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='补水保湿' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_chlrf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='潮流染发' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ftyf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='防脱养发' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jfjs_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='减肥瘦身' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jzks_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='紧致抗衰' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jwym_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='境外医美' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mbnf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美白嫩肤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_meifa_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美发' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_meijia_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美甲' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_meijie_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美睫' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mrqj_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美容/清洁' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mzhf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='美妆护肤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qudou_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='祛痘' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_touliao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='头疗' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tuomao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='脱毛' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wmwx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='纹眉纹绣' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wenshen_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='纹身' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wudao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='舞蹈' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yxmr_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='医学美容' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yjplt_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='瑜伽/普拉提' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子/乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bxhyg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='冰雪海洋馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_bowuguan_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='博物馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dwpt_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='带娃泡汤' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_dwyx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='电玩游戏' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_etly_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='儿童乐园' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_etsy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='儿童摄影' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_etyy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='儿童游泳' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_gyzwy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='公园植物园' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_hblh_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='滑板轮滑' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jjpx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='击剑培训' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lqpx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='篮球培训' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mygw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='母婴购物' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_njcz_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='农家采摘' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzct_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子餐厅' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzhd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子活动' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzjd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子酒店' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qzyy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='亲子游泳' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tsnpx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='体适能培训' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tuoersuo_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='托班/托儿所' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yczl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='演出/展览' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yyfw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='婴幼服务' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ycfw_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='孕产服务' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yfsy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='孕妇摄影' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zaojiao_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='早教' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_sgsx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='水果生鲜' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tpyp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='甜品饮品' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_chaguan_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='茶馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_kft_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='咖啡厅' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mbtd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='面包甜点' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_spzb_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='食品滋补' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ypd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='饮品店' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xxwl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='休闲/玩乐' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_diy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='DIY手工坊' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ktv_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='KTV' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lh_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='Live House' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_amzl_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='按摩/足疗' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jszx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='健身中心' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jb_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='酒吧' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_jbs_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='剧本杀' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='撸宠' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_mscj_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='密室/沉浸' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qps_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='棋牌室' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_qlyd_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='球类运动' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_sryy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='私人影院' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tqg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3='台球馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tycg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '体育场馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_tjhp_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '团建/轰趴' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_wbdj_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '网吧/电竞' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xyhz_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '洗浴/汗蒸' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xqty_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '新奇体验' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_ylyy_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '游乐游艺' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_yyg_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '游泳馆' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zmyx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '桌面游戏' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_zcxc_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '炸串小吃' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_lsf_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '螺蛳粉' group by 1,2,3 union all
select user_id,event_time,'instore_cate3_xlx_visit_num' as event_name,sum(cnt) as event_cnt from t2 where cate3= '小龙虾' group by 1,2,3
),



-- 订单量
t4 as (
-- 霸王餐
select user_id,event_time,'delivery_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) group by 1,2,3 union all
select user_id,event_time,'delivery_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) group by 1,2,3 union all
select user_id,event_time,'delivery_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order group by 1,2,3 union all
-- 霸王餐一级类目完单
select user_id,event_time,'delivery_cate1_zc_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and category_type='早餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_zhc_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and category_type='正餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_xwc_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and category_type='下午茶' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_wc_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and category_type='晚餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_yx_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and category_type='夜宵' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_ls_finished_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (2,8) and category_type='零售' group by 1,2,3 union all
-- 霸王餐一级类目取消
select user_id,event_time,'delivery_cate1_zc_canceled_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and category_type='早餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_zhc_cancel_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and category_type='正餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_xwc_cancel_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and category_type='下午茶' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_wc_cancel_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and category_type='晚餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_yx_cancel_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and category_type='夜宵' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_ls_cancel_order_num' as event_name,sum(order_num) as event_cnt from wm_order where order_status in (4,5) and category_type='零售' group by 1,2,3 union all
-- 霸王餐一级类目提交
select user_id,event_time,'delivery_cate1_zc_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where category_type='早餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_zhc_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where category_type='正餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_xwc_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where category_type='下午茶' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_wc_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where category_type='晚餐' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_yx_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where category_type='夜宵' group by 1,2,3 union all
select user_id,event_time,'delivery_cate1_ls_submitted_order_num' as event_name,sum(order_num) as event_cnt from wm_order where category_type='零售' group by 1,2,3 union all
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
select user_id,event_time,'delivery_subcate_bzzp_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='包子粥铺' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_kcjc_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='快餐简餐' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_tpyp_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='甜品饮品' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_zcxc_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='炸串小吃' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_hgsk_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='火锅烧烤' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_hbxc_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='汉堡西餐' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_sgsx_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='水果生鲜' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_ls_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='零售' group by 1,2,3 union all
select user_id,event_time,'delivery_subcate_cryp_visit_num' as event_name,sum(cnt) as event_cnt from t5 where sub_category_type='成人用品' group by 1,2,3
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






























