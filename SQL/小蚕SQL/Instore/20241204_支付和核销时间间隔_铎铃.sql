-- 自然日
select
    hr,
    PERCENTILE_CONT(diff_hour,0) as `核销间隔最小值`,
    PERCENTILE_CONT(diff_hour,0.1) as `核销间隔10分位值`,
    PERCENTILE_CONT(diff_hour,0.2) as `核销间隔20分位值`,
    PERCENTILE_CONT(diff_hour,0.3) as `核销间隔30分位值`,
    PERCENTILE_CONT(diff_hour,0.4) as `核销间隔40分位值`,
    PERCENTILE_CONT(diff_hour,0.5) as `核销间隔50分位值`,
    PERCENTILE_CONT(diff_hour,0.6) as `核销间隔60分位值`,
    PERCENTILE_CONT(diff_hour,0.7) as `核销间隔70分位值`,
    PERCENTILE_CONT(diff_hour,0.8) as `核销间隔80分位值`,
    PERCENTILE_CONT(diff_hour,0.9) as `核销间隔90分位值`,
    PERCENTILE_CONT(diff_hour,1) as `核销间隔最大值`
from
(
select
    date(pay_time) as dt,
    hour(pay_time) as hr,
    date_diff('hour',str_to_jodatime(verify_time, 'yyyy-MM-dd HH:mm:ss'),str_to_jodatime(pay_time, 'yyyy-MM-dd HH:mm:ss')) as diff_hour
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4)
    and substr(pay_time,1,10)<>'1970-01-01'
    and substr(verify_time,1,10)<>'1970-01-01'
) a
group by 1
;

===============
-- 区分星期几
select
    b.day_of_week,
    hr,
    min(diff_hour) as `核销间隔最小值`,
    PERCENTILE_CONT(diff_hour,0.1) as `核销间隔10分位值`,
    PERCENTILE_CONT(diff_hour,0.2) as `核销间隔20分位值`,
    PERCENTILE_CONT(diff_hour,0.3) as `核销间隔30分位值`,
    PERCENTILE_CONT(diff_hour,0.4) as `核销间隔40分位值`,
    PERCENTILE_CONT(diff_hour,0.5) as `核销间隔50分位值`,
    PERCENTILE_CONT(diff_hour,0.6) as `核销间隔60分位值`,
    PERCENTILE_CONT(diff_hour,0.7) as `核销间隔70分位值`,
    PERCENTILE_CONT(diff_hour,0.8) as `核销间隔80分位值`,
    PERCENTILE_CONT(diff_hour,0.9) as `核销间隔90分位值`,
    max(diff_hour) as `核销间隔最大值`,
    count(1) as `订单量`
from
(
select
    date(pay_time) as dt,
    hour(pay_time) as hr,
    date_diff('hour',str_to_jodatime(verify_time, 'yyyy-MM-dd HH:mm:ss'),str_to_jodatime(pay_time, 'yyyy-MM-dd HH:mm:ss')) as diff_hour
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 33 day) and date_sub(current_date(),interval 3 day)
    and promotion_type in (1,4)
    and substr(pay_time,1,10)<>'1970-01-01'
    and substr(verify_time,1,10)<>'1970-01-01'
) a
left join dim.dim_silkworm_date b on a.dt=b.current_date_txt 
group by 1,2
;

-- 验证 无问题
select
    b.day_of_week,a.*
    -- hr,
    -- PERCENTILE_CONT(diff_hour,0) as `核销间隔最小值`,
    -- PERCENTILE_CONT(diff_hour,0.1) as `核销间隔10分位值`,
    -- PERCENTILE_CONT(diff_hour,0.2) as `核销间隔20分位值`,
    -- PERCENTILE_CONT(diff_hour,0.3) as `核销间隔30分位值`,
    -- PERCENTILE_CONT(diff_hour,0.4) as `核销间隔40分位值`,
    -- PERCENTILE_CONT(diff_hour,0.5) as `核销间隔50分位值`,
    -- PERCENTILE_CONT(diff_hour,0.6) as `核销间隔60分位值`,
    -- PERCENTILE_CONT(diff_hour,0.7) as `核销间隔70分位值`,
    -- PERCENTILE_CONT(diff_hour,0.8) as `核销间隔80分位值`,
    -- PERCENTILE_CONT(diff_hour,0.9) as `核销间隔90分位值`,
    -- PERCENTILE_CONT(diff_hour,1) as `核销间隔最大值`,
    -- count(1) as `订单量`
from
(
select
    order_id,pay_time,verify_time,
    date(pay_time) as dt,
    hour(pay_time) as hr,
    date_diff('hour',str_to_jodatime(verify_time, 'yyyy-MM-dd HH:mm:ss'),str_to_jodatime(pay_time, 'yyyy-MM-dd HH:mm:ss')) as diff_hour
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 33 day) and date_sub(current_date(),interval 3 day)
    and promotion_type in (1,4)
    and substr(pay_time,1,10)<>'1970-01-01'
    and substr(verify_time,1,10)<>'1970-01-01'
) a
left join dim.dim_silkworm_date b on a.dt=b.current_date_txt
where b.day_of_week='星期二'
    and a.hr=8
;



======= 支付时点分品类订单量
select
    b.day_of_week `周几`,
    a.hr `支付时点`,
    c.cate2_name `二级类目`,
    count(1) as `订单量`
from
(
select
    date(pay_time) as dt,
    hour(pay_time) as hr,
    store_promotion_id,
    date_diff('hour',str_to_jodatime(verify_time, 'yyyy-MM-dd HH:mm:ss'),str_to_jodatime(pay_time, 'yyyy-MM-dd HH:mm:ss')) as diff_hour
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 33 day) and date_sub(current_date(),interval 3 day)
    and promotion_type in (1,4)
    and substr(pay_time,1,10)<>'1970-01-01'
    and substr(verify_time,1,10)<>'1970-01-01'
) a
left join dim.dim_silkworm_date b on a.dt=b.current_date_txt
left join (
select
    promotion_id,
    case when sub_category_type=1 then '包子粥铺'
        when sub_category_type=2 then '汉堡西餐'
        when sub_category_type=3 then '火锅烧烤'
        when sub_category_type=4 then '快餐简餐'
        when sub_category_type=5 then '美发/丽人'
        when sub_category_type=6 then '亲子/乐园'
        when sub_category_type=7 then '水果生鲜'
        when sub_category_type=8 then '甜品饮品'
        when sub_category_type=9 then '休闲/玩乐'
        when sub_category_type=10 then '炸串小吃'
        when sub_category_type=11 then '正餐/多人餐'
    else '其他' end as cate2_name
from dwd.dwd_sr_silkworm_explore_promotion
where dt between date_sub(current_date(),interval 60 day) and date_sub(current_date(),interval 1 day)
) c on a.store_promotion_id=c.promotion_id
group by 1,2,3;



======= 核销时点分品类订单量
select
    b.day_of_week `周几`,
    a.hr `核销时点`,
    c.cate2_name `二级类目`,
    count(1) as `订单量`
from
(
select
    date(verify_time) as dt,
    hour(verify_time) as hr,
    store_promotion_id,
    date_diff('hour',str_to_jodatime(verify_time, 'yyyy-MM-dd HH:mm:ss'),str_to_jodatime(pay_time, 'yyyy-MM-dd HH:mm:ss')) as diff_hour
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 33 day) and date_sub(current_date(),interval 3 day)
    and promotion_type in (1,4)
    and substr(pay_time,1,10)<>'1970-01-01'
    and substr(verify_time,1,10)<>'1970-01-01'
) a
left join dim.dim_silkworm_date b on a.dt=b.current_date_txt
left join (
select
    promotion_id,
    case when sub_category_type=1 then '包子粥铺'
        when sub_category_type=2 then '汉堡西餐'
        when sub_category_type=3 then '火锅烧烤'
        when sub_category_type=4 then '快餐简餐'
        when sub_category_type=5 then '美发/丽人'
        when sub_category_type=6 then '亲子/乐园'
        when sub_category_type=7 then '水果生鲜'
        when sub_category_type=8 then '甜品饮品'
        when sub_category_type=9 then '休闲/玩乐'
        when sub_category_type=10 then '炸串小吃'
        when sub_category_type=11 then '正餐/多人餐'
    else '其他' end as cate2_name
from dwd.dwd_sr_silkworm_explore_promotion
where dt between date_sub(current_date(),interval 60 day) and date_sub(current_date(),interval 1 day)
) c on a.store_promotion_id=c.promotion_id
group by 1,2,3;


==========
== 探店支付和核销小时间隔
select
    hr,
    PERCENTILE_CONT(diff_hour,0) as `核销间隔最小值`,
    PERCENTILE_CONT(diff_hour,0.1) as `核销间隔10分位值`,
    PERCENTILE_CONT(diff_hour,0.2) as `核销间隔20分位值`,
    PERCENTILE_CONT(diff_hour,0.3) as `核销间隔30分位值`,
    PERCENTILE_CONT(diff_hour,0.4) as `核销间隔40分位值`,
    PERCENTILE_CONT(diff_hour,0.5) as `核销间隔50分位值`,
    PERCENTILE_CONT(diff_hour,0.6) as `核销间隔60分位值`,
    PERCENTILE_CONT(diff_hour,0.7) as `核销间隔70分位值`,
    PERCENTILE_CONT(diff_hour,0.8) as `核销间隔80分位值`,
    PERCENTILE_CONT(diff_hour,0.9) as `核销间隔90分位值`,
    PERCENTILE_CONT(diff_hour,1) as `核销间隔最大值`
from
(
-- select
--     hr,
--     avg(diff_hour) as avg_diff_hr
-- from (
select
    date(pay_time) as dt,
    hour(pay_time) as hr,
    date_diff('hour',str_to_jodatime(verify_time, 'yyyy-MM-dd HH:mm:ss'),str_to_jodatime(pay_time, 'yyyy-MM-dd HH:mm:ss')) as diff_hour
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4)
    and substr(pay_time,1,10)<>'1970-01-01'
    and substr(verify_time,1,10)<>'1970-01-01'
) a
-- group by hr) b
group by 1
;

select dt,bitmap_union_count(user_id) as cnt from dwd.dwd_sr_traffic_viewuser_d where dt>=date_sub(current_date(),interval 7 day) group by 1;

select unnest_bitmap from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_id) as uid
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_ename in ('StoreDiscovery_Homepage_View','StoreDiscovery_Activity_Details_View','Influencer_Page_View','Store_Details_View')
group by 1
limit 100;


select * from dws.dws_sr_store_perf_bd_acc_h
where dt=date_sub(current_date(),interval 1 day)
limit 10;


select
    dt,count(1) cnt
from ods.ods_sr_traffic_event_log
WHERE dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 0 day)
group by 1;


select
    *
from ods.ods_sr_traffic_event_log
-- WHERE dt between date_sub(current_date(),interval 3 day) and date_sub(current_date(),interval 2 day)
where cast(dt as string) between '2024-12-02' and '2024-12-03'
    and user_id in (496272879,643636508,143281458,269142951,171166771,464115554,245984023,169769206,921686402,65714806,783331877)
;

============ 探店销单率和其他相关性
-- 探店活动
with t1 as (
select
    promotion_id,
    pay_amt,
    rebate_price,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    demand_dp_fans,
    tot_promotion_quota
from dwd.dwd_sr_silkworm_explore_promotion
where dt<=date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
),

-- 订单
t2 as (
select 
    dt,
    store_promotion_id,
    count(order_id) as finished_order_num
from dwd.dwd_sr_silkworm_explore_order
where dt<=date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 探店
    and status in (4,5,19,20) -- 完单
group by 1,2),

-- 销单率
t3 as (
select
    t2.dt,
    t1.promotion_id,
    pay_amt,
    rebate_price,
    demand_dp_user_lvl,
    demand_xiaohongshu_fans_num,
    demand_dp_fans,
    tot_promotion_quota,
    t2.finished_order_num,
    t2.finished_order_num/tot_promotion_quota as finished_rate
from t1 left join t2 on t1.promotion_id=t2.store_promotion_id
)

select
    corr(finished_rate,pay_amt) `实际支付金额和销单率相关系数`,
    corr(finished_rate,rebate_price) `返利金额和销单率相关系数`,
    corr(finished_rate,tot_promotion_quota) `活动名额和销单率相关系数`,
    corr(finished_rate,demand_dp_user_lvl) `点评等级和销单率相关系数`,
    corr(finished_rate,demand_xiaohongshu_fans_num) `小红书粉丝数和销单率相关系数`,
    corr(finished_rate,demand_dp_fans) `点评粉丝数和销单率相关系数`
from t3
;



=========== 探店分1-3级类目活动量
select
    case when category_type=1 then '正餐美食'
        when category_type=2 then '饮品小吃'
        when category_type=3 then '休闲玩乐'
        when category_type=4 then '生活服务'
        when category_type=5 then '快餐简餐'
        when category_type=6 then '火锅烧烤'
        when category_type=7 then '汉堡西餐'
        when category_type=8 then '亲子乐园'
    else '其他' end `一级类目`,
    case when sub_category_type=1 then '包子粥铺'
        when sub_category_type=2 then '汉堡西餐'
        when sub_category_type=3 then '火锅烧烤'
        when sub_category_type=4 then '快餐简餐'
        when sub_category_type=5 then '美发/丽人'
        when sub_category_type=6 then '亲子/乐园'
        when sub_category_type=7 then '水果生鲜'
        when sub_category_type=8 then '甜品饮品'
        when sub_category_type=9 then '休闲/玩乐'
        when sub_category_type=10 then '炸串小吃'
        when sub_category_type=11 then '正餐/多人餐'
    else '其他' end `二级类目`,
case when category_id=1 then '包子粥铺'
    when category_id=2 then '面馆'
    when category_id=3 then '小吃快餐'
    when category_id=4 then '早茶'
    when category_id=5 then '汉堡西餐'
    when category_id=6 then '西餐'
    when category_id=7 then '火锅烧烤'
    when category_id=8 then '火锅'
    when category_id=9 then '烤肉'
    when category_id=10 then '烧烤烤串'
    when category_id=11 then '快餐简餐'
    when category_id=12 then '北京菜'
    when category_id=13 then '本帮江浙菜'
    when category_id=14 then '川菜'
    when category_id=15 then '创意菜'
    when category_id=16 then '东北菜'
    when category_id=17 then '东南亚菜'
    when category_id=18 then '韩国料理'
    when category_id=19 then '家常菜'
    when category_id=20 then '农家菜'
    when category_id=21 then '日本菜'
    when category_id=22 then '私房菜'
    when category_id=23 then '特色菜'
    when category_id=24 then '湘菜'
    when category_id=25 then '新疆菜'
    when category_id=26 then '鱼鲜'
    when category_id=27 then '粤菜'
    when category_id=28 then '自助餐'
    when category_id=29 then '理发/男士'
    when category_id=30 then 'SPA按摩'
    when category_id=31 then '熬夜修护'
    when category_id=31 then '补水保湿'
    when category_id=33 then '潮流染发'
    when category_id=34 then '防脱养发'
    when category_id=35 then '减肥瘦身'
    when category_id=36 then '紧致抗衰'
    when category_id=37 then '境外医美'
    when category_id=38 then '美白嫩肤'
    when category_id=39 then '美发'
    when category_id=40 then '美甲'
    when category_id=41 then '美睫'
    when category_id=42 then '美容/清洁'
    when category_id=43 then '美妆护肤'
    when category_id=44 then '祛痘'
    when category_id=45 then '头疗'
    when category_id=46 then '脱毛'
    when category_id=47 then '纹眉纹绣'
    when category_id=48 then '纹身'
    when category_id=49 then '舞蹈'
    when category_id=50 then '医学美容'
    when category_id=51 then '瑜伽/普拉提'
    when category_id=52 then '亲子/乐园'
    when category_id=53 then '冰雪海洋馆'
    when category_id=54 then '博物馆'
    when category_id=55 then '带娃泡汤'
    when category_id=56 then '电玩游戏'
    when category_id=57 then '儿童乐园'
    when category_id=58 then '儿童摄影'
    when category_id=59 then '儿童游泳'
    when category_id=60 then '公园植物园'
    when category_id=61 then '滑板轮滑'
    when category_id=62 then '击剑培训'
    when category_id=63 then '篮球培训'
    when category_id=64 then '母婴购物'
    when category_id=65 then '农家采摘'
    when category_id=66 then '亲子餐厅'
    when category_id=67 then '亲子活动'
    when category_id=68 then '亲子酒店'
    when category_id=69 then '亲子游泳'
    when category_id=70 then '体适能培训'
    when category_id=71 then '托班/托儿所'
    when category_id=72 then '演出/展览'
    when category_id=73 then '婴幼服务'
    when category_id=74 then '孕产服务'
    when category_id=75 then '孕妇摄影'
    when category_id=76 then '早教'
    when category_id=77 then '水果生鲜'
    when category_id=78 then '甜品饮品'
    when category_id=79 then '茶馆'
    when category_id=80 then '咖啡厅'
    when category_id=81 then '面包甜点'
    when category_id=82 then '食品滋补'
    when category_id=83 then '饮品店'
    when category_id=84 then '休闲/玩乐'
    when category_id=85 then 'DIY手工坊'
    when category_id=86 then 'KTV'
    when category_id=87 then 'Live House'
    when category_id=88 then '按摩/足疗'
    when category_id=89 then '茶馆'
    when category_id=90 then '儿童乐园'
    when category_id=91 then '健身中心'
    when category_id=92 then '酒吧'
    when category_id=93 then '剧本杀'
    when category_id=94 then '撸宠'
    when category_id=95 then '密室/沉浸'
    when category_id=96 then '棋牌室'
    when category_id=97 then '球类运动'
    when category_id=98 then '私人影院'
    when category_id=99 then '台球馆'
    when category_id=100 then '体育场馆'
    when category_id=101 then '团建/轰趴'
    when category_id=102 then '网吧/电竞'
    when category_id=103 then '洗浴/汗蒸'
    when category_id=104 then '新奇体验'
    when category_id=105 then '游乐游艺'
    when category_id=106 then '游泳馆'
    when category_id=107 then '桌面游戏'
    when category_id=108 then '炸串小吃'
    when category_id=109 then '螺蛳粉'
    when category_id=110 then '小龙虾'
else '其他' end `三级类目`,
    count(promotion_id) `活动量`
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
group by 1,2,3;


===============
热门地理位置下工作日（热门目标是有足够样本量来case测评）
100个到店活动列表页 活动结果（前端活动信息流）
包含信息：店铺名，活动名，活动评级（运营配置的，SABC），距离，团购价，距离/团购价（距离单位为m）最好超过30的帮忙颜色标注下，到手价，折扣（到手价价/团购价），返现金额（付x返x），活动要求（等级，粉丝数一类）

-- 活动量
select
    b.*,a.cnt
from
(select
 city_code,count(1) as cnt
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
group by 1) a
left join dim.dim_silkworm_county b on a.city_code=b.county_id
;


-- 最近7天分区活动量
-- 活动量
select
    b.province_name,
    b.city_name,
    b.county_name,
    b.business_district,
    a.cnt
from
(select
 city_code,count(1) as cnt
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
group by 1) a
left join dim.dim_silkworm_explore_store b on a.city_code=b.county_id
;

-- 筛选出经纬度
120.291024,30.304887 九堡新天地


-- 导出筛选经纬度周边活动
select
    a.*,b.day_of_week
from
(select
    str_to_date(begin_time,'%Y-%m-%d') as dat,
    promotion_id,
    store_id,
    store_name,
    demand_promotion_type, -- 活动要求类型(0:无要求,1:大众点评,2:小红书)",
    demand_dp_user_lvl, -- 大众点评要求用户等级
    demand_xiaohongshu_fans_num, -- 小红书粉丝数要求
    group_discount,-- 团购价
    rebate_price, -- 返利价
    pay_amt, -- 实际支付金额
    concat('满',pay_amt,'返',rebate_price) as rebate_condition,
    ST_Distance_Sphere(longitude, latitude, 120.291024, 30.304887) as distance
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
    and substr(cast(city_code as string),1,4)='3301' -- 限制杭州市
) a
left join dim.dim_silkworm_date b on a.dat=b.current_date_txt
where b.day_of_week not in ('星期六','星期天')
;


============
-- 探店首页曝光活动数
select
    bg_pro_num `探店首页曝光活动数`,
    count(distinct user_id) as `曝光用户量`
from
(select
    dt,
    user_id,
    count(distinct activity_id) as bg_pro_num
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_name='StoreDiscovery_Activity_Ex'
group by 1,2
) a
group by 1;




===============


热门地理位置下工作日（热门目标是有足够样本量来case测评）
100个到店活动列表页 活动结果（前端活动信息流）
包含信息：店铺名，活动名，活动评级（运营配置的，SABC），距离，团购价，距离/团购价（距离单位为m）最好超过30的帮忙颜色标注下，到手价，折扣（到手价价/团购价），返现金额（付x返x），活动要求（等级，粉丝数一类）

-- 活动量
select
    b.*,a.cnt
from
(select
 city_code,count(1) as cnt
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
group by 1) a
left join dim.dim_silkworm_county b on a.city_code=b.county_id
;


-- 最近7天分区活动量
-- 活动量
select
    b.province_name,
    b.city_name,
    b.county_name,
    b.business_district,
    a.cnt
from
(select
 city_code,count(1) as cnt
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
group by 1) a
left join dim.dim_silkworm_explore_store b on a.city_code=b.county_id
;

-- 筛选出经纬度
-- 121.460046,31.229861 上海市静安区南京西路881号
-- 121.403189,31.167875 上海市徐汇区田林路276号


-- 导出筛选经纬度周边活动
select
    a.*,b.day_of_week
from
(select
    str_to_date(begin_time,'%Y-%m-%d') as dat,
    promotion_id,
    store_id,
    store_name,
    demand_promotion_type, -- 活动要求类型(0:无要求,1:大众点评,2:小红书)",
    demand_dp_user_lvl, -- 大众点评要求用户等级
    demand_xiaohongshu_fans_num, -- 小红书粉丝数要求
    group_discount,-- 团购价
    rebate_price, -- 返利价
    pay_amt, -- 实际支付金额
    concat('满',pay_amt,'返',rebate_price) as rebate_condition,
    ST_Distance_Sphere(longitude, latitude, 121.403189, 31.167875) as distance
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
    and substr(cast(city_code as string),1,4)='3101' -- 限制上海市
) a
left join dim.dim_silkworm_date b on a.dat=b.current_date_txt
where b.day_of_week not in ('星期六','星期天')
;


===============
-- 121.460046,31.229861 上海市静安区南京西路881号
-- 121.403189,31.167875 上海市徐汇区田林路276号

select 
    '上海市徐汇区田林路276号' as `地址`,
    a.dat `活动开始日期`,
    b.day_of_week `周几`,
    promotion_id `活动ID`,
    store_id `店铺ID`,
    store_name `店铺名称`,
    demand_dp_user_lvl `点评要求用户等级`,
    demand_xiaohongshu_fans_num `小红书粉丝数`,
    group_discount `团购价`,
    rebate_price `返利价`,
    pay_amt `实际支付金额`,
    pay_amt-rebate_price `到手价`,
    concat('满',pay_amt,'返',rebate_price) as `返现条件`,
    distance `距离(单位:米)`
from
(select
    str_to_date(begin_time,'%Y-%m-%d') as dat,
    promotion_id,
    store_id,
    store_name,
    demand_promotion_type, -- 活动要求类型(0:无要求,1:大众点评,2:小红书)",
    demand_dp_user_lvl, -- 大众点评要求用户等级
    demand_xiaohongshu_fans_num, -- 小红书粉丝数要求
    group_discount,-- 团购价
    rebate_price, -- 返利价
    pay_amt, -- 实际支付金额
    concat('满',pay_amt,'返',rebate_price) as rebate_condition,
    ST_Distance_Sphere(longitude, latitude, 121.403189, 31.167875) as distance
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
    and substr(cast(city_code as string),1,4)='3101' -- 限制上海市
) a
left join dim.dim_silkworm_date b on a.dat=b.current_date_txt
where b.day_of_week not in ('星期六','星期天')

union all

select 
    '上海市静安区南京西路881号' as `地址`,
    a.dat `活动开始日期`,
    b.day_of_week `周几`,
    promotion_id `活动ID`,
    store_id `店铺ID`,
    store_name `店铺名称`,
    demand_dp_user_lvl `点评要求用户等级`,
    demand_xiaohongshu_fans_num `小红书粉丝数`,
    group_discount `团购价`,
    rebate_price `返利价`,
    pay_amt `实际支付金额`,
    pay_amt-rebate_price `到手价`,
    concat('满',pay_amt,'返',rebate_price) as `返现条件`,
    distance `距离(单位:米)`
from
(select
    str_to_date(begin_time,'%Y-%m-%d') as dat,
    promotion_id,
    store_id,
    store_name,
    demand_promotion_type, -- 活动要求类型(0:无要求,1:大众点评,2:小红书)",
    demand_dp_user_lvl, -- 大众点评要求用户等级
    demand_xiaohongshu_fans_num, -- 小红书粉丝数要求
    group_discount,-- 团购价
    rebate_price, -- 返利价
    pay_amt, -- 实际支付金额
    concat('满',pay_amt,'返',rebate_price) as rebate_condition,
    ST_Distance_Sphere(longitude, latitude, 121.460046, 31.229861) as distance
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
    and substr(cast(city_code as string),1,4)='3101' -- 限制上海市
) a
left join dim.dim_silkworm_date b on a.dat=b.current_date_txt
where b.day_of_week not in ('星期六','星期天')
;


union all

select 
    '上海市徐汇区田林路276号' as `地址`,
    a.dat `活动开始日期`,
    b.day_of_week `周几`,
    promotion_id `活动ID`,
    store_id `店铺ID`,
    store_name `店铺名称`,
    demand_dp_user_lvl `点评要求用户等级`,
    demand_xiaohongshu_fans_num `小红书粉丝数`,
    group_discount `团购价`,
    rebate_price `返利价`,
    pay_amt `实际支付金额`,
    pay_amt-rebate_price `到手价`,
    concat('满',pay_amt,'返',rebate_price) as `返现条件`,
    distance `距离(单位:米)`
from
(select
    str_to_date(begin_time,'%Y-%m-%d') as dat,
    promotion_id,
    store_id,
    store_name,
    demand_promotion_type, -- 活动要求类型(0:无要求,1:大众点评,2:小红书)",
    demand_dp_user_lvl, -- 大众点评要求用户等级
    demand_xiaohongshu_fans_num, -- 小红书粉丝数要求
    group_discount,-- 团购价
    rebate_price, -- 返利价
    pay_amt, -- 实际支付金额
    concat('满',pay_amt,'返',rebate_price) as rebate_condition,
    ST_Distance_Sphere(longitude, latitude, 121.403189, 31.167875) as distance
from dwd.dwd_sr_silkworm_explore_promotion
where dt>=date_sub(current_date(),interval 180 day)
    and str_to_date(begin_time,'%Y-%m-%d') between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    -- and status=1 -- 在线
    and promotion_type in (1,4) -- 探店
    and substr(cast(city_code as string),1,4)='3101' -- 限制上海市
) a
left join dim.dim_silkworm_date b on a.dat=b.current_date_txt
where b.day_of_week not in ('星期六','星期天')
;


=========== 首页
select
    dt,
    sum(if(event_name='StoreDiscovery_Activity_Ex',1,0)) as `探店首页活动曝光量`,
    count(distinct if(event_name='StoreDiscovery_Activity_Ex',user_id,null)) as `探店首页活动曝光用户量`,
    sum(if(event_name='StoreDiscovery_Activity_Click',1,0)) as `探店首页活动点击量`,
    count(distinct if(event_name='StoreDiscovery_Activity_Click',user_id,null)) as `探店首页活动点击用户量`
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 1 day)
    and event_name in ('StoreDiscovery_Activity_Ex','StoreDiscovery_Activity_Click')
group by 1;


-- 分城市区县
select
    dt,
    b.province_name,
    b.city_name,
    b.county_name,
    `探店首页活动曝光量`,
    `探店首页活动曝光用户量`,
    `探店首页活动点击量`,
    `探店首页活动点击用户量`
from
(select
    dt,
    county_id,
    sum(if(event_name='StoreDiscovery_Activity_Ex',1,0)) as `探店首页活动曝光量`,
    count(distinct if(event_name='StoreDiscovery_Activity_Ex',user_id,null)) as `探店首页活动曝光用户量`,
    sum(if(event_name='StoreDiscovery_Activity_Click',1,0)) as `探店首页活动点击量`,
    count(distinct if(event_name='StoreDiscovery_Activity_Click',user_id,null)) as `探店首页活动点击用户量`
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and event_name in ('StoreDiscovery_Activity_Ex','StoreDiscovery_Activity_Click')
group by 1,2
) a
left join dim.dim_silkworm_county b on a.county_id=b.county_id
;


-- 全国
select
    dt,
    '全国' province_name,
    '全国' city_name,
    '全国' county_name,
    sum(if(event_name='StoreDiscovery_Activity_Ex',1,0)) as `探店首页活动曝光量`,
    count(distinct if(event_name='StoreDiscovery_Activity_Ex',user_id,null)) as `探店首页活动曝光用户量`,
    sum(if(event_name='StoreDiscovery_Activity_Click',1,0)) as `探店首页活动点击量`,
    count(distinct if(event_name='StoreDiscovery_Activity_Click',user_id,null)) as `探店首页活动点击用户量`
from
(select
    *
from ods.ods_sr_traffic_event_log
where dt between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
    and event_name in ('StoreDiscovery_Activity_Ex','StoreDiscovery_Activity_Click')
) a
left join dim.dim_silkworm_county b on a.county_id=b.county_id
where b.city_name in ('杭州市','上海市','广州市','成都市','武汉市')
group by 1,2,3,4
;



