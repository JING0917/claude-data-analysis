广州🍠探店1 chat_id='wrlre9DQAARPqcc1W6N4UMMB2omVy7xw' -- 132人
武汉🍠探店1 chat_id='wrlre9DQAAJzBu5yE05LMGrISW2x_kvQ' --112人
成都🍠探店1 chat_id='wrlre9DQAAyvXNghtWFU9Jl5GUTSqS6A' -- 120人



广州🍠探店1 2025-01-16-至今
武汉🍠探店1 2025-02-14-至今
成都🍠探店1 2025-02-17-至今
武汉🍠探店2 2025-02-19-至今
广州🍠探店2 2025-02-24-至今
成都🍠探店2 2025-02-25-至今
广州🍠探店3 2025-02-26-至今
成都🍠探店3 2025-02-26-至今


广州🍠探店4 2025-03-04-至今
杭州红薯探店1 2025-03-05-至今
杭州红薯探店2 2025-03-06-至今
上海🍠探店1 2025-03-07-至今
杭州红薯探店3 2025-03-07-至今
上海红薯探店2 2025-03-08-至今
成都🍠探店4 2025-03-10-至今
广州红薯探店5 2025-03-10-至今
上海红薯探店3 2025-03-11-至今
广州红薯探店6 2025-03-12-至今
杭州红薯探店4 2025-03-13-至今
成都红薯探店5 2025-03-13-至今
上海红薯探店4 2025-03-13-至今
上海红薯探店5 2025-03-14-至今

-- 状态是35订单数：2，直接用探店用户表
select
    status,count(1) as order_num
from dwd.dwd_sr_silkworm_explore_order
where promotion_type in (1,4)
    -- and substr(verify_time,1,10)<>'1970-01-01'
    and status=35
group by 1
;


dim.dim_wework_community -- 企微社群
dwd.dwd_sr_user_wework_community -- 企微社群用户



============== 正式跑数据
with com_info as (
select
    community_name,
    community_id
from dim.dim_wework_community
where community_name ='【小蚕】杭州砍价福利群8🧧'
group by 1,2
),

-- 企微群用户
com_user_info as (
select
    com_info.community_name,
    com_info.community_id,
    user_id
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1,2,3
),

-- 判断新老用户 根据各群创建日期判断(废弃) 根据用户进群时间判断
t1 as (
select
    a.user_id,
    first_explode_order_date,
    if(first_explode_order_date is null or date_format(first_explode_order_date,'%Y-%m-%d') >'2025-03-04','新用户','老用户') as user_type
from com_user_info a
left join dim.dim_silkworm_explore_daren_cleanse b
on b.user_id=a.user_id
),

-- 探店下单
-- 同一个用户，可能在多个企微群出现，所以只能统计单个群的探店订单数据
t2 as (
select
    user_id
    ,count(distinct order_id ) as apply_order_num
    ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
    ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
    ,count(distinct case when status=5 then order_id end) as finish_order_num
from 
    dwd.dwd_sr_silkworm_explore_order
where 
    dt between '2025-03-17' and date_sub(current_date(),interval 1 day)
    and promotion_type in (5,6)
group by user_id
)



select
    community_name as `企微群名称`,
    t1.user_id `用户ID`,
    t1.user_type `用户类型`,
    apply_order_num `报名订单量`,
    pay_order_num `支付订单量`,
    verify_order_num `核销订单量`,
    finish_order_num `完单订单量`
from t1 left join t2 on t1.user_id=t2.user_id
left join com_user_info on t1.user_id=com_user_info.user_id
;

====================== datart报表 输入社群名称和开始日期，自查
with com_info as (
select
    community_name,
    community_id,
    community_user_num
from dim.dim_wework_community
where community_name =$community_name$
group by 1,2,3
),

-- 企微群用户
com_user_info as (
select
    com_info.community_name,
    com_info.community_id,
    user_id,
    community_user_num
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1,2,3,4
),

-- 判断新老用户 根据各群创建日期判断(废弃) 根据用户进群时间判断
t1 as (
select
    a.user_id,
    first_explode_order_date,
    if(first_explode_order_date is null or date_format(first_explode_order_date,'%Y-%m-%d') >=$begin_date$,'新用户','老用户') as user_type
from com_user_info a
left join dim.dim_silkworm_explore_daren_cleanse b
on b.user_id=a.user_id
),

-- 探店下单
-- 同一个用户，可能在多个企微群出现，所以只能统计单个群的探店订单数据
t2 as (
select
    user_id
    ,count(distinct order_id ) as apply_order_num
    ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
    ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
    ,count(distinct case when status in (5,11,14,17,18,19,22,23,28) then order_id end) as finish_order_num
from 
    dwd.dwd_sr_silkworm_explore_order
where 
    dt between $begin_date$ and $end_date$
    and promotion_type in (1,4)
group by user_id
)



select
    community_name as `企微群名称`,
    -- t1.user_id `用户ID`,
    community_user_num `群人数`,
    t1.user_type `用户类型`,
    count(distinct t1.user_id) `用户量`,
    count(distinct if(apply_order_num>0,t1.user_id,null)) `报名用户量`,
    count(distinct if(pay_order_num>0,t1.user_id,null)) `支付用户量`,
    count(distinct if(verify_order_num>0,t1.user_id,null)) `核销用户量`,
    count(distinct if(finish_order_num>0,t1.user_id,null)) `完单用户量`,
    sum(apply_order_num) `报名订单量`,
    sum(pay_order_num) `支付订单量`,
    sum(verify_order_num) `核销订单量`,
    sum(finish_order_num) `完单订单量`
from t1 left join t2 on t1.user_id=t2.user_id
left join com_user_info on t1.user_id=com_user_info.user_id
group by 1,2,3
;





================ 捷西需求

with com_info as (
select
    community_name,
    community_id,
    community_user_num
from dim.dim_wework_community
where community_name in (
'【小蚕】杭州砍价福利群8🧧',
'【小蚕】杭州砍价福利群9🧧',
'【小蚕】杭州砍价福利群10🧧',
'【小蚕】杭州砍价福利群11🧧',
'【小蚕】上海砍价福利群6🧧',
'【小蚕】上海砍价福利群7🧧',
'【小蚕】上海砍价福利群8🧧',
'【小蚕】长沙砍价福利群8🧧',
'【小蚕】长沙砍价福利群9🧧',
'【小蚕】合肥砍价福利群3🧧',
'【小蚕】武汉砍价福利群5🧧',
'【小蚕】武汉砍价福利群6🧧',
'【小蚕】深圳砍价福利群5🧧',
'【小蚕】深圳砍价福利群7🧧',
'【小蚕】深圳砍价福利群8🧧',
'【小蚕】成都砍价福利群2🧧（待开）',
'【小蚕】广州砍价福利群3🧧',
'【小蚕】广州砍价福利群4🧧',
'【小蚕】重庆砍价福利群🧧',
'【小蚕】苏州砍价福利群1',
'【小蚕】南京砍价福利群1'
)
group by 1,2,3
),

-- 企微群用户
com_user_info as (
select
    com_info.community_name,
    com_info.community_id,
    user_id,
    join_time
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1,2,3,4
),

-- 判断新老用户 根据各群创建日期判断(废弃) 根据用户进群时间判断
t1 as (
select
    a.community_name,
    a.user_id,
    first_explode_order_date,
    if(first_explode_order_date is null or date_format(first_explode_order_date,'%Y-%m-%d') >=date_format(join_time,'%Y-%m-%d'),'新用户','老用户') as user_type
from com_user_info a
left join dim.dim_silkworm_explore_daren_cleanse b
on b.user_id=a.user_id
),

-- 探店下单
-- 同一个用户，可能在多个企微群出现，所以只能统计单个群的探店订单数据
t2 as (
select
    user_id
    ,count(distinct order_id ) as apply_order_num
    ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
    ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
    ,count(distinct case when status=5 then order_id end) as finish_order_num
from 
    dwd.dwd_sr_silkworm_explore_order
where 
    dt between '2025-03-17' and date_sub(current_date(),interval 1 day)
    and promotion_type in (5,6)
group by user_id
)



select
    t1.community_name as `企微群名称`,
    t1.user_type `用户类型`,
    count(distinct com_user_info.user_id) `群人数`,
    count(distinct t1.user_id) `用户量`,
    count(distinct if(apply_order_num>0,t1.user_id,null)) `报名用户量`,
    count(distinct if(pay_order_num>0,t1.user_id,null)) `支付用户量`,
    count(distinct if(verify_order_num>0,t1.user_id,null)) `核销用户量`,
    count(distinct if(finish_order_num>0,t1.user_id,null)) `完单用户量`,
    sum(apply_order_num) `报名订单量`,
    sum(pay_order_num) `支付订单量`,
    sum(verify_order_num) `核销订单量`,
    sum(finish_order_num) `完单订单量`
from t1 left join t2 on t1.user_id=t2.user_id
left join com_user_info on t1.user_id=com_user_info.user_id and t1.community_name=com_user_info.community_name
group by 1,2
;




========== datart报表


with com_info as (
select
    REGEXP_REPLACE(community_name, '[\\x{1F900}-\\x{1F9FF}]', '') as community_name,
    community_id,
    community_user_num
from dim.dim_wework_community
where community_name REGEXP '砍价'
    and community_id is not null
    -- <#if community_name !=''>
    --    and community_name IN (${community_name})
    -- </#if>

group by 1,2,3
),

-- 企微群用户
com_user_info as (
select
    com_info.community_name,
    com_info.community_id,
    user_id,
    join_time,
    community_user_num
from dwd.dwd_sr_user_wework_community a
inner join com_info on a.community_id=com_info.community_id
group by 1,2,3,4,5
),

-- 判断新老用户 根据各群创建日期判断(废弃) 根据用户进群时间判断
t1 as (
select
    a.community_name,
    a.user_id,
    first_explode_order_date,
    if(first_explode_order_date is null or date_format(first_explode_order_date,'%Y-%m-%d') >=date_format(join_time,'%Y-%m-%d'),'新用户','老用户') as user_type
from com_user_info a
left join dim.dim_silkworm_explore_daren_cleanse b
on b.user_id=a.user_id
),

-- 探店下单
-- 同一个用户，可能在多个企微群出现，所以只能统计单个群的探店订单数据
t2 as (
select
    user_id
    ,count(distinct order_id ) as apply_order_num
    ,count(distinct case when substr(pay_time,1,10)<> '1970-01-01' then order_id end) as pay_order_num
    ,count(distinct case when substr(verify_time,1,10)<> '1970-01-01' then order_id end) as verify_order_num
    ,count(distinct case when status=5 then order_id end) as finish_order_num
from 
    dwd.dwd_sr_silkworm_explore_order
where 
    dt between $begin_date$ and $end_date$
    and promotion_type in (5,6)
group by user_id
)



select
    t1.community_name as `企微群名称`,
    com_user_info.community_user_num `群人数`,
    t1.user_type `用户类型`,
    count(distinct t1.user_id) `用户量`,
    count(distinct if(apply_order_num>0,t1.user_id,null)) `报名用户量`,
    count(distinct if(pay_order_num>0,t1.user_id,null)) `支付用户量`,
    count(distinct if(verify_order_num>0,t1.user_id,null)) `核销用户量`,
    count(distinct if(finish_order_num>0,t1.user_id,null)) `完单用户量`,
    sum(apply_order_num) `报名订单量`,
    sum(pay_order_num) `支付订单量`,
    sum(verify_order_num) `核销订单量`,
    sum(finish_order_num) `完单订单量`
from t1 left join t2 on t1.user_id=t2.user_id
left join com_user_info on t1.user_id=com_user_info.user_id and t1.community_name=com_user_info.community_name
group by 1,2,3
;




=============== 20250507 捷西需求
WITH com_info AS
  (SELECT community_name,
          community_id,
          community_user_num
   FROM dim.dim_wework_community
   WHERE community_name IN ('【小蚕】美食地图-无锡站52',
'【小蚕】美食地图-中山站16',
'【小蚕】美食地图-东莞站48',
'【小蚕】美食地图-沈阳站21',
'【小蚕】昆明霸王餐福利32群',
'【小蚕】汕头内部福利群7',
'【小蚕】美食地图-长沙站48',
'【小蚕】美食地图-台州站30',
'【小蚕】美食地图-常州站32',
'【小蚕】美食地图-南昌站57',
'【小蚕】美食地图-福州站32',
'【小蚕】美食地图-济南站73',
'【小蚕】美食地图-惠州站18',
'【小蚕】佛山霸王餐福利47群',
'【小蚕】美食地图-宁波站51',
'【小蚕】美食地图-衢州站3',
'【小蚕】美食地图-厦门站36',
'【温州】小蚕霸王餐福利群45',
'【小蚕】鄞州区外卖聚集地24',
'【小蚕】美食地图-南通站27',
'【小蚕】美食地图-泉州站17',
'【小蚕】美食地图-南昌站58',
'【小蚕】嘉兴霸王餐福利群22',
'【小蚕】美食地图-镇江站5',
'【小蚕】美食地图-无锡站53',
'【小蚕】美食地图-石家庄站17',
'【小蚕】美食地图-扬州站13',
'【小蚕】美食地图-东莞站50',
'【西安】未央区外卖聚集地5',
'【小蚕】美食地图-西安站84',
'【小蚕】美食地图-南昌站59',
'【小蚕】太原霸王餐福利29',
'【小蚕】美食地图-东莞站51',
'【小蚕】美食地图-沈阳站22')
   GROUP BY 1,
            2,
            3)


SELECT com_info.community_name `群名称`,
       community_user_num `群人数`,
       count(distinct a.user_wechat_id) `群人数2`,
       count(DISTINCT if(b.cnt>0,a.user_id,NULL)) `有效用户量`
FROM dwd.dwd_sr_user_wework_community a
inner JOIN com_info ON a.community_id=com_info.community_id
LEFT JOIN
  (SELECT user_id,
          count(1) cnt
   FROM dwd.dwd_sr_order_promotion_order
   WHERE dt BETWEEN '2024-04-01' AND '2025-04-30'
     AND order_status IN (2,
                          8)
   GROUP BY 1) b ON a.user_id=b.user_id
GROUP BY 1,
         2;






