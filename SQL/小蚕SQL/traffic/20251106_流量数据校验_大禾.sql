======================== part1 外卖报名漏斗
-- 整体看，报名按钮点击UV > 订单报名UV
-- 报名按钮点击
with t1 as (
select
    activity_id,
    -- count(distinct distinct_id) clc_uv
    bitmap_agg(distinct_id) clc_uids
from dwd.dwd_sr_traffic_sensor_event_log_realtime
where date_format(time,'%Y-%m-%d')='2025-10-31'
     AND distinct_id regexp '^[0-9]{1,10}$'
     AND cast(activity_id as string) regexp '^[0-9]{1,10}$'
     and event='Takeaway_Baomingflow_Button_Click'
    --  and button_name in ('领红包并确定报名','立即报名领返利','领红包并抢名额',
    --             '报名返利','抢返利名额','领红包并抢名额','超前点单','立即抢单')
group by 1),


-- 活动下单&完单
t2 as (select
promotion_id,
baoming_uids,
valid_uids
from dws.dws_sr_store_takeawaypro_statis_d
where dt='2025-10-31'
    and eleme_promotion_quota>0)

select
    bitmap_union_count(t1.clc_uids) clc_uv,
    bitmap_union_count(t2.baoming_uids) baoming_uv,
    bitmap_union_count(t2.valid_uids) valid_uv
from t1 inner join t2 on t1.activity_id=t2.promotion_id
;


-- 订单报名&完单
SELECT bitmap_union_count(baoming_uids) baoming_uv, -- 487202
       bitmap_union_count(valid_uids) valid_uv -- 403799
FROM dws.dws_sr_store_takeawaypro_statis_d
WHERE dt='2025-10-31'
  AND promotion_quota>0;



-- 报名按钮点击UV
SELECT count(DISTINCT distinct_id) clc_uv -- 589105
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-10-31'
  AND distinct_id regexp '^[0-9]{1,10}$'
  AND cast(activity_id AS string) regexp '^[0-9]{1,10}$'
  AND event='Takeaway_Baomingflow_Button_Click'
  AND button_name IN ('领红包并确定报名',
                      '立即报名领返利',
                      '领红包并抢名额',
                      '报名返利',
                      '抢返利名额',
                      '领红包并抢名额',
                      '超前点单',
                      '立即抢单')
  ;


-- 分活动对比
-- 正向漏斗 验证：活动维度，报名按钮点击用户和下单用户差异

-- 报名按钮点击
with t1 as (
select
    ifnull(activity_id,0) activity_id,
    cast(distinct_id as int) user_id,
    time,
    business_name,
    platform_type,
    $app_version,
    button_name
from dwd.dwd_sr_traffic_sensor_event_log_realtime
where date_format(time,'%Y-%m-%d')='2025-11-03'
     AND distinct_id regexp '^[0-9]{1,10}$'
     -- AND cast(activity_id as string) regexp '^[0-9]{1,10}$'
     and event='Takeaway_Baomingflow_Button_Click'
group by 1,2,3,4,5,6,7),


-- 下单
t2 AS
  (SELECT store_promotion_id,
          user_id,
          order_time
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt='2025-11-03'
   GROUP BY 1,
            2,
            3),

-- 报名按钮点击和业务数据集
t3 AS (
SELECT t1.activity_id,
       t1.user_id,
       t1.time,
       business_name,
       platform_type,
       $app_version,
       button_name,
       t2.store_promotion_id AS yw_promotion_id,
       t2.user_id AS yw_user_id,
       t2.order_time
FROM t1
LEFT JOIN t2 ON -- t1.activity_id=t2.store_promotion_id
 -- AND
 t1.user_id=t2.user_id 
 -- AND date_format(t1.time,'%Y-%m-%d %H:%i')=date_format(t2.order_time,'%Y-%m-%d %H:%i'))
 AND date_diff('second',date_format(t2.order_time,'%Y-%m-%d %H:%i:%s'),date_format(t1.time,'%Y-%m-%d %H:%i:%s')) BETWEEN 0 AND 5


-- 第一种类型
-- 流量有用户，业务库无用户 11月3日 这样的用户有19,700人
-- 用户ID如 669875555 861197102 951537557 336882589 219177576 681762250 971249874 957846380 179773316 138286473
-- 后续排查思路（埋点是否存在误触发，是否用户下单受限制）
SELECT a.user_id
FROM
  (SELECT DISTINCT user_id
   FROM t1) a
LEFT JOIN
  (SELECT DISTINCT user_id
   FROM t2) b ON a.user_id=b.user_id
WHERE b.user_id IS NULL
LIMIT 10
;


-- 第一种类型
-- 有活动报名按钮点击，但无业务库订单报名信息
-- 用户ID如 685928356
-- 一个原因，因关联条件处理不对，活动ID不作为关联条件，用户ID和时间做关联条件，时间现在是同分钟，还是粗 调整为5秒内了
SELECT *
FROM t3
WHERE order_time IS NULL LIMIT 10;


select
  count(1) cnt,
  min(diff_snd) mix,
  percentile_cont(diff_snd,0.1) 10fw,
  percentile_cont(diff_snd,0.2) 20fw,
  percentile_cont(diff_snd,0.3) 30fw,
  percentile_cont(diff_snd,0.4) 40fw,
  percentile_cont(diff_snd,0.5) 50fw,
  percentile_cont(diff_snd,0.6) 60fw,
  percentile_cont(diff_snd,0.7) 70fw,
  percentile_cont(diff_snd,0.8) 80fw,
  percentile_cont(diff_snd,0.9) 90fw,
  max(diff_snd) max
from
(select
  user_id,
  date_diff('second',order_time,date_format(time,'%Y-%m-%d %H:%i:%s')) diff_snd
from t3) a
;








-- 以用户ID为例抽查 user_id=685928356 user_id=923592157
select store_promotion_id,
          user_id,
          order_time,
          order_id
from dwd.dwd_sr_order_promotion_order
WHERE dt='2025-10-20'
   and user_id=685928356
;

select
    activity_id,
    cast(distinct_id as int) user_id,
    time,
    business_name,
    platform_type,
    $app_version,
    button_name
from dwd.dwd_sr_traffic_sensor_event_log_realtime
where date_format(time,'%Y-%m-%d')='2025-10-20'
     AND distinct_id='685928356'
     -- AND cast(activity_id as string) regexp '^[0-9]{1,10}$'
     and event='Takeaway_Baomingflow_Button_Click'
;



select store_promotion_id,
          user_id,
          order_time,
          order_id,
          user_id
from dwd.dwd_sr_order_promotion_order
WHERE dt='2025-11-03'
   and user_id=669875555
;

select
    activity_id,
    cast(distinct_id as int) user_id,
    time,
    business_name,
    platform_type,
    $app_version,
    button_name
from dwd.dwd_sr_traffic_sensor_event_log_realtime
where date_format(time,'%Y-%m-%d')='2025-11-03'
     AND distinct_id='669875555'
     -- AND cast(activity_id as string) regexp '^[0-9]{1,10}$'
     and event='Takeaway_Baomingflow_Button_Click'
;


-- 业务库有用户，埋点无用户 这样用户量 11月3日有 7749人
-- 用户ID 如 746893452 261542255 487177704 395959819 686193582 533984456 171975375 977725254 861432907 651496808 
-- 此类情况 待排查原因
SELECT a.user_id
FROM
  (SELECT DISTINCT user_id
   FROM t2) a
LEFT JOIN
  (SELECT DISTINCT user_id
   FROM t1) b ON a.user_id=b.user_id
WHERE b.user_id IS NULL
LIMIT 10
;


select store_promotion_id,
          user_id,
          order_time,
          order_id,
          user_ip,
          order_platform_type
from dwd.dwd_sr_order_promotion_order
WHERE dt='2025-11-03'
   and user_id in (746893452,261542255,487177704,395959819,686193582,533984456,171975375,977725254,861432907,651496808)
;

select
    activity_id,
    cast(distinct_id as int) user_id,
    time,
    business_name,
    platform_type,
    $app_version,
    button_name
from dwd.dwd_sr_traffic_sensor_event_log_realtime
where date_format(time,'%Y-%m-%d')='2025-11-03'
     AND distinct_id in ('746893452','261542255','487177704','395959819','686193582','533984456','171975375','977725254','861432907','651496808')
     -- AND cast(activity_id as string) regexp '^[0-9]{1,10}$'
     and event='Takeaway_Baomingflow_Button_Click'
;


SELECT distinct_id
FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-11'
  AND get_json_string(properties,'$.resource_id')=11
  AND get_json_string(properties,'$.put_id') IN (3256,
                 3275)
GROUP BY 1 LIMIT 100;



SELECT distinct_id
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-11'
  AND resource_id=11
  AND put_id IN (3256,
                 3275)
GROUP BY 1 LIMIT 100;




-- 分事件数据量
-- 外卖下单漏斗
SELECT date_format(time,'%Y-%m-%d') AS dt,
    business_name,
    platform_type,
    -- $app_version,
    case when event='Takeaway_Baomingflow_Button_Click' then 3
    when event='Takeaway_Detailpage_View' then 2
    else 1 end event,
    count(1) `数据量`,
    count(distinct user_id) `UV(含匿名用户)`,
    count(distinct if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,null)) `登录UV`
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2025-11-04'
    and event in('HomePage_View','Homepage_View','Takeaway_Detailpage_View','Takeaway_Baomingflow_Button_Click')
    and business_name='外卖'
group by 1,2,3,4

union all
SELECT dt,
'外卖' business_name,
case when order_platform=0 then 'H5'
    when order_platform=1 then '小程序'
    when order_platform=2 then 'APP'
end as platform_type,
4 event,
count(1) `数据量`,
count(distinct user_id) `UV(含匿名用户)`,
count(distinct user_id) `登录UV`
FROM dwd.dwd_sr_order_promotion_order
WHERE dt='2025-11-04'
group by 1,2,3,4;




======================== 



======================== part2 城市流量
-- 分城市分业务线分端DAU
SELECT $city,
       business_name,
       platform_type,
       $app_version,
       count(DISTINCT user_id) uv,
       count(DISTINCT if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,NULL)) login_uv
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-03'
GROUP BY 1,
         2,
         3,
         4 ;


-- 分城市DAU
SELECT coalesce(a.$city,b.city_name,c.city_name) city_name,
       a.uv,
       a.login_uv,
       b.quota,
       c.ywk_uv
FROM
  (SELECT $city,
          count(DISTINCT user_id) uv,
          count(DISTINCT if(distinct_id regexp '^[0-9]{1,10}$',distinct_id,NULL)) login_uv
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2025-11-03'
   GROUP BY 1) a
FULL JOIN
  (SELECT replace(city_name,'市','') city_name,
          sum(promotion_quota) quota
   FROM dws.dws_sr_store_takeawaypro_statis_d
   WHERE dt='2025-11-03'
   GROUP BY 1) b ON a.$city=b.city_name
FULL JOIN
  (SELECT replace(city_name,'市','') city_name,
          count(1) ywk_uv
   FROM dws.dws_sr_user_login_d
   WHERE statistics_date='2025-11-03'
   GROUP BY 1) c ON a.$city=c.city_name;



-- 分城市uv
SELECT city,
       count(1) cnt
FROM
  ( SELECT distinct_id,
           get_json_string(properties, '$.city') city
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time, '%Y-%m-%d') = '2025-11-13'
     AND event='Withdrawpage_Click'
   GROUP BY 1,
            2 ) a
GROUP BY 1;
========================



======================== part3 资源位透传
SELECT a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.tot,
       a.unum,
       a.bg_num,
       a.bg_unum,
       a.clc_num,
       a.clc_unum
FROM
  (SELECT resource_id,
          put_id,
          abtest_id,
          count(1) tot,
          count(DISTINCT user_id) unum,
          sum(if(event regexp '_Ex$',1,0)) bg_num,
          count(DISTINCT if(event regexp '_Ex$',user_id,NULL)) bg_unum,
          sum(if(event regexp '_Click$',1,0)) clc_num,
          count(DISTINCT if(event regexp '_Click$',user_id,NULL)) clc_unum
   FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2025-11-06'
     AND put_id IN (3215)
   GROUP BY 1,
            2,
            3) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id;





========== 20251113 Android 以用户ID：497855671，在测试环境看数据
1、安卓端3.11.3版本，$AppViewScreen、$AppPageLeave事件，business_name有null值；
2、Homepage_Feed_Activity_Ex事件，没有上报数据，但Homepage_Feed_Activity_Click事件有上报


SELECT to_date(time) dt,
       business_name,
       platform_type,
       $app_version,
       event,
       count(1) `数据量`,
       count(DISTINCT user_id) uv,
       count(DISTINCT distinct_id) login_uv
FROM events
WHERE to_date(time)='2025-11-14'
  AND hour(time)>=10
  -- AND minute(time)>=0
  AND distinct_id='497855671'
GROUP BY 1,
         2,
         3,
         4,
         5 ;






-- ods日志中解析
SELECT event,
       time,
       distinct_id,
       get_json_string(properties,'$.business_name') business_name,
       get_json_string(properties,'$.platform_type') platform_type,
       get_json_string(properties,'$.$app_version') $app_version,
       get_json_string(properties,'$.resource_id') resource_id,
       get_json_string(properties,'$.put_id') put_id,
       get_json_string(properties,'$.abtest_id') abtest_id,
       get_json_string(properties,'$.tracing') AS tracing
FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-17'
  AND distinct_id='923592157'
;



-- 资源位统计
with t as (SELECT event,
       time,
       distinct_id,
       get_json_string(properties,'$.business_name') business_name,
       get_json_string(properties,'$.platform_type') platform_type,
       get_json_string(properties,'$.$app_version') $app_version,
       get_json_string(properties,'$.resource_id') resource_id,
       get_json_string(properties,'$.put_id') put_id,
       get_json_string(properties,'$.abtest_id') abtest_id,
       get_json_string(properties,'$.tracing') AS tracing,
       get_json_string(properties,'$.user_id') AS user_id
FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-21'
        )




-- 资源位本位置曝光、点击
-- 金刚区统计异常 无点击 实际抽部分投放ID查看，有点击 需要排查
SELECT a.platform_type,
       a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.tot `数据量`,
       a.unum `用户量`,
       a.bg_num `曝光量`,
       a.bg_unum `曝光用户量`,
       a.clc_num `点击量`,
       a.clc_unum `点击用户量`
FROM
  (SELECT CASE
              WHEN platform_type IN ('微信小程序',
                                     '小程序') THEN '微信小程序'
              WHEN platform_type regexp '5' THEN 'H5'
              ELSE platform_type
          END platform_type,
          resource_id,
          put_id,
          abtest_id,
          count(1) tot,
          count(DISTINCT user_id) unum,
          sum(if(event regexp '_Ex$',1,0)) bg_num,
          count(DISTINCT if(event regexp '_Ex$',user_id,NULL)) bg_unum,
          sum(if(event regexp '_Click$',1,0)) clc_num,
          count(DISTINCT if(event regexp '_Click$',user_id,NULL)) clc_unum
   FROM t
   WHERE platform_type regexp '5|小程序'
   GROUP BY 1,
            2,
            3,
            4) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id;


-- 查找数据量较大用户
-- select distinct_id,count(1) tot from t group by 1 order by 2 desc limit 50;

-- 取出数据量较大用户行为日志
-- 取数耗时太久，从dwd直取，还是慢，从神策取
-- select * from t where distinct_id='493915504';

-- 抽查单用户透传
SELECT 
       distinct_id,
       count(1) tot
FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE date(time)='2025-11-21'
    and platform_type regexp '5'
group by 1
having count(1)>1000 limit 100;


with t as (SELECT event,
       time,
       distinct_id,
       get_json_string(properties,'$.business_name') business_name,
       get_json_string(properties,'$.platform_type') platform_type,
       get_json_string(properties,'$.$app_version') $app_version,
       get_json_string(properties,'$.resource_id') resource_id,
       get_json_string(properties,'$.put_id') put_id,
       get_json_string(properties,'$.abtest_id') abtest_id,
       get_json_string(properties,'$.tracing') AS tracing,
       get_json_string(properties,'$.user_id') AS user_id,
       get_json_string(properties,'city') AS city
FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-21'
        )

SELECT event,
       cast(time as varchar(25)) time,
       distinct_id,
       business_name,
       platform_type,
       $app_version,
       resource_id,
       put_id,
       abtest_id,
       tracing,
       user_id,
       city
FROM t
WHERE date(time)='2025-11-21'
  AND platform_type regexp '5'
  AND distinct_id IN ('377768789',
                      '322864356');


-- iOS端资源位透传验收

 -- 资源位统计
with t as (SELECT event,
       time,
       distinct_id,
       get_json_string(properties,'$.business_name') business_name,
       get_json_string(properties,'$.platform_type') platform_type,
       get_json_string(properties,'$.$app_version') $app_version,
       get_json_string(properties,'$.resource_id') resource_id,
       get_json_string(properties,'$.put_id') put_id,
       get_json_string(properties,'$.abtest_id') abtest_id,
       get_json_string(properties,'$.tracing') AS tracing,
       get_json_string(properties,'$.user_id') AS user_id,
       get_json_string(properties,'$.city') AS city
FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='2025-11-25'
        )

select * from t where distinct_id='923592157'

select  
        event,
        -- platform_type,
        count(1) tot,
        count(distinct user_id) unum
from    dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE   date_format(time, '%Y-%m-%d') = '2025-11-25'
group by 1,
         2;


-- 资源位本位置曝光、点击
-- 金刚区统计异常 无点击 实际抽部分投放ID查看，有点击 需要排查
SELECT a.platform_type,
       a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.tot `数据量`,
       a.unum `用户量`,
       a.bg_num `曝光量`,
       a.bg_unum `曝光用户量`,
       a.clc_num `点击量`,
       a.clc_unum `点击用户量`
FROM
  (SELECT platform_type,
          resource_id,
          put_id,
          abtest_id,
          count(1) tot,
          count(DISTINCT user_id) unum,
          sum(if(event regexp '_Ex$',1,0)) bg_num,
          count(DISTINCT if(event regexp '_Ex$',user_id,NULL)) bg_unum,
          sum(if(event regexp '_Click$',1,0)) clc_num,
          count(DISTINCT if(event regexp '_Click$',user_id,NULL)) clc_unum
   FROM t
   WHERE platform_type in ('Android','iOS','Harmony')
   GROUP BY 1,
            2,
            3,
            4) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id;










==============
-- 小程序渠道归因事件校验数据
select  '自采' as `类型`,
        dt,
        event_name as event,
        count(1) `数据量`,
        count(distinct user_id) `用户量`
from    ods.ods_sr_event_log
where   dt between '2025-11-09'
and     '2025-11-15'
and     event_name in ('Register_User', 'Open_Link')
group by 1,
         2,
         3

union all
select  '神策' as `类型`,
        date_format(time, '%Y-%m-%d') dt, -- platform_type,
        event,
        count(1) `数据量`,
        count(distinct distinct_id) `用户量`
from    dwd.dwd_sr_traffic_sensor_event_log_realtime
WHERE   date_format(time, '%Y-%m-%d') between '2025-11-09'
and     '2025-11-15' -- and event in ('HomePage_takeout_Activity_ex','My_Page_Merchant_Onboarding_Ex')
and     event in ('Register_User', 'Open_Link')
group by 1,
         2,
         3;



==========================
-- 资源位统计
WITH base AS
  (SELECT event,
          date_format(time, '%Y-%m-%d') dt,
                                        get_json_string(properties,'$.platform_type') platform_type,
                                        get_json_string(properties,'$.resource_id') resource_id,
                                        get_json_string(properties,'$.put_id') put_id,
                                        get_json_string(properties,'$.abtest_id') abtest_id,
                                        get_json_string(properties,'$.user_id') AS user_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE date_format(time,'%Y-%m-%d')='${T-1}'
AND (RIGHT(event, 6) = '_Click'
     OR RIGHT(event, 6) = '_click'
     OR RIGHT(event, 6) = '_Close'
     OR RIGHT(event, 3) = '_Ex' )
)



agg AS (
    SELECT 
        dt,
        CASE
            WHEN platform_type_raw regexp '5' THEN 1
            WHEN platform_type_raw IN ('小程序','微信小程序') THEN 2
            WHEN platform_type_raw IN ('到店微信小程序','到店小程序') THEN 3
            WHEN platform_type_raw='探店小程序' THEN 4
            WHEN platform_type_raw='Android' THEN 5
            WHEN platform_type_raw='iOS' THEN 6
            WHEN platform_type_raw='Harmony' THEN 7
        END AS platform_type,
        resource_id,
        put_id,
        abtest_id,
        SUM(CASE WHEN event LIKE '%_Ex' THEN 1 ELSE 0 END) AS bg_num,
        bitmap_union(CASE WHEN event LIKE '%_Ex' THEN bitmap_hash(user_id) END) AS bg_uv,
        SUM(CASE WHEN event LIKE '%_Click' OR event LIKE '%_click' OR event LIKE '%_Close' THEN 1 ELSE 0 END) AS clc_num,
        bitmap_union(CASE WHEN event LIKE '%_Click' OR event LIKE '%_click' OR event LIKE '%_Close' THEN bitmap_hash(user_id) END) AS clc_uv
    FROM base
    WHERE resource_id IS NOT NULL
      AND resource_id <> '0'
      AND resource_id <> 'UPGRADE_POPUP'
      AND platform_type IS NOT NULL
    GROUP BY 1,2,3,4,5
),

final AS (
    SELECT 
        dt,
        platform_type,
        resource_id,
        put_id,
        abtest_id,
        bg_num,
        bitmap_count(bg_uv) AS bg_unum,
        clc_num,
        bitmap_count(clc_uv) AS clc_uv
    FROM agg

    UNION ALL

    SELECT 
        dt,
        99 AS platform_type,
        resource_id,
        put_id,
        abtest_id,
        SUM(bg_num),
        bitmap_count(bitmap_union(bg_uv)),
        SUM(clc_num),
        bitmap_count(bitmap_union(clc_uv))
    FROM agg
    GROUP BY 1,2,3,4,5
)

SELECT 
    f.dt AS statistics_date,
    f.platform_type,
    f.resource_id,
    f.put_id,
    f.abtest_id,
    c.resource_name,
    b.put_name,
    f.bg_num,
    f.bg_unum,
    f.clc_num,
    f.clc_uv
FROM final f
LEFT JOIN dim.dim_res_position_put b ON f.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON f.resource_id=c.resource_id;



-- 资源位本位置曝光、点击
-- 金刚区统计异常 无点击 实际抽部分投放ID查看，有点击 需要排查
SELECT dt AS statistics_date,
       a.platform_type,
       a.resource_id,
       a.put_id,
       a.abtest_id,
       c.resource_name,
       b.put_name,
       a.bg_num expouse_num,
       a.bg_unum expouse_uv,
       a.clc_num,
       a.clc_uv
FROM
  (SELECT dt,
          CASE
              WHEN platform_type regexp '5' THEN 1
              WHEN platform_type IN ('小程序',
                                     '微信小程序') THEN 2
              WHEN platform_type IN ('到店微信小程序',
                                     '到店小程序') THEN 3
              WHEN platform_type='探店小程序' THEN 4
              WHEN platform_type='Android' THEN 5
              WHEN platform_type='iOS' THEN 6
              WHEN platform_type='Harmony' THEN 7
          END platform_type,
          resource_id,
          put_id,
          abtest_id,
          sum(if(event regexp '_Ex$',cnt,0)) bg_num,
          count(DISTINCT if(event regexp '_Ex$',user_id,NULL)) bg_unum,
          sum(if(event regexp '_Click$|_click$|_Close$',cnt,0)) clc_num,
          count(DISTINCT if(event regexp '_Click$|_click$|_Close$',user_id,NULL)) clc_uv
   FROM t
   WHERE resource_id IS NOT NULL
     AND resource_id<>0
     AND resource_id<>'UPGRADE_POPUP'
     AND platform_type IS NOT NULL
   GROUP BY 1,
            2,
            3,
            4,
            5
   UNION ALL SELECT dt,
                    99 platform_type,
                       resource_id,
                       put_id,
                       abtest_id,
                       sum(if(event regexp '_Ex$',cnt,0)) bg_num,
                       count(DISTINCT if(event regexp '_Ex$',user_id,NULL)) bg_unum,
                       sum(if(event regexp '_Click$|_click$|_Close$',cnt,0)) clc_num,
                       count(DISTINCT if(event regexp '_Click$|_click$|_Close$',user_id,NULL)) clc_uv
   FROM t
   WHERE resource_id IS NOT NULL
     AND resource_id<>0
     AND resource_id<>'UPGRADE_POPUP'
     AND platform_type IS NOT NULL
   GROUP BY 1,
            2,
            3,
            4,
            5 ) a
LEFT JOIN dim.dim_res_position_put b ON a.put_id=b.put_id
LEFT JOIN dim.dim_res_position c ON a.resource_id=c.resource_id;














-- -- 数据量
-- SELECT CASE
--            WHEN event regexp '_Ex$' THEN '曝光'
--            WHEN event regexp '_Click$' THEN '点击'
--            WHEN event regexp '_View$' THEN '浏览'
--            ELSE '其他'
--        END AS event,
--        platform_type,
--        resource_id,
--        put_id,
--        abtest_id,
--        count(1) tot
-- FROM t
-- GROUP BY 1,
--          2,
--          3,
--          4,
--          5;




SELECT dt,
       event,
       platform_type,
       $app_version,
       city,
       tot `数据量`,
       uv `用户量`
FROM
  ( SELECT date(time) dt,
           event,
           get_json_string(properties, '$.platform_type') AS platform_type,
           get_json_string(properties, '$.city') AS city,
           get_json_string(properties, '$.$app_version') AS $app_version,
           count(1) tot,
           count(DISTINCT distinct_id) uv
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE time BETWEEN '2025-11-30 00:00:00' AND '2025-11-30 23:59:59'
     AND event IN ('Search_Click',
                   'Search_Result_Ex',
                   'Search_Result_Click')
   GROUP BY 1,
            2,
            3,
            4,
            5 ) tot
WHERE city IS NULL
  OR city = 0
  OR city = '';



============ 搜索曝光事件，position采集异常
-- 搜索数据解析
WITH t AS
  (SELECT time,
          event,
          get_json_string(properties,'$.entrance') AS entrance_name,
          get_json_string(properties,'$.search_method') AS search_method,
          get_json_string(properties,'$.city') AS county_id,
          distinct_id AS user_id,
          get_json_string(properties,'$.position') AS location,
          get_json_string(properties,'$.activity_id') AS activity_id,
          get_json_string(properties,'$.query_word') AS keywords,
          get_json_string(properties,'$.platform_type') AS platform_name,
          get_json_string(properties,'$.$app_version') AS $app_version
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='2025-12-08'
     AND event IN ('Search_Click',
                   'Search_Result_Ex',
                   'Search_Result_Click',
                   'Takeaway_Detailpage_View')
     AND distinct_id regexp '^[0-9]{1,10}$')

-- badcase
select cast(time as string) as dt_time,* from t where user_id=272979919;


-- 清洗t数据集 转换null值 剔除空等
t1 AS
  (SELECT time,
          event,
          CASE
              WHEN entrance_name IN ('首页',
                                     '主页') THEN '首页'
              WHEN entrance_name IS NULL THEN '其他'
              ELSE entrance_name
          END AS entrance_name,
          search_method,
          ifnull(county_id,'999999')county_id,
                                    user_id,
                                    location,
                                    ifnull(activity_id,0) activity_id,
                                                          keywords,
                                                          CASE
                                                              WHEN platform_name regexp '5' THEN 'H5'
                                                              WHEN platform_name IN ('小程序',
                                                                                     '微信小程序') THEN '微信小程序'
                                                              ELSE platform_name
                                                          END platform_name,
                                                          $app_version
   FROM t
   WHERE keywords IS NOT NULL
     AND keywords<>''
     AND platform_name IS NOT NULL)

SELECT a.*
FROM 
-- 搜索曝光是2、3位置
  (SELECT date(time) `统计日期`,
          platform_name,
          search_method,
          keywords,
          $app_version,
          user_id,
          count(1) bg_num
   FROM t1
   WHERE event='Search_Result_Ex'
     AND entrance_name='首页'
     AND LOCATION IN ('2',
                      '3')
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6 HAVING count(1)>0) a
LEFT JOIN 
-- 搜索曝光是1位置
  (SELECT date(time) `统计日期`,
          platform_name,
          search_method,
          keywords,
          $app_version,
          user_id,
          count(1) bg_num
   FROM t1
   WHERE event='Search_Result_Ex'
     AND entrance_name='首页'
     AND LOCATION='1'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6) b ON a.`统计日期`=b.`统计日期`
AND a.platform_name=b.platform_name
AND a.search_method=b.search_method
AND a.keywords=b.keywords
AND a.$app_version=b.$app_version
AND a.user_id=b.user_id
WHERE b.user_id IS NULL LIMIT 1000;



















































