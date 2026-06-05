dim.dim_silkworm_explore_daren_cleanse


-- 到店已开通城市
drop view if exists city_info;
create view IF NOT EXISTS city_info (
	city_name
) as (
select
    city_name
from dim.dim_silkworm_explore_city
where province_name<>'新疆维吾尔族自治区' -- 剔除测试省份
    and status=1 -- 正常
    and promotion_type in ('101','111')
group by 1);


-- 首页浏览
drop view if exists hp_flow_info;
create view IF NOT EXISTS hp_flow_info (
	dt
	,city_name
	,user_id
	,bargain_hp_pv
) as (
select
    dt,
    b.city_name
    ,user_id
    ,sum(if(event_name='Bargain_Homepage_Ex',1,0)) bargain_hp_pv
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    cast(concat(substr(county_id,1,4),'00') as int) as city_id
from ods.ods_sr_event_log
where dt between '2025-03-01' and date_sub(current_date(),interval 2 day)
    and event_name='Bargain_Homepage_Ex'
    ) a
left join dim.dim_silkworm_county b on a.city_id=b.city_id
where user_id regexp '^[0-9]{1,10}$'
group by 1,2,3
);


-- 详情页浏览
drop view if exists dp_flow_info;
create view IF NOT EXISTS dp_flow_info (
	dt
	,city_name
	,activity_id
	,user_id
	,bargain_dp_pv
) as (
select
    dt,
    b.city_name
    ,activity_id
    ,user_id
    ,sum(if(event_name='StoreDiscovery_Activity_Details_Ex' and activity_type='砍价活动',1,0)) bargain_dp_pv -- `砍价活动详情页PV`
from (
select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dt,
    event_name,
    user_id,
    get_json_string(data,'$.activity_type') as activity_type,
    cast(concat(substr(county_id,1,4),'00') as int) as city_id,
    get_json_string(data,'$.activity_id') as activity_id
from ods.ods_sr_event_log
where dt between '2025-03-01' and date_sub(current_date(),interval 2 day)
    and event_name='StoreDiscovery_Activity_Details_Ex'
    ) a
left join dim.dim_silkworm_county b on a.city_id=b.city_id
where activity_id regexp '^[1-9]{1,8}$'
	and user_id regexp '^[0-9]{1,10}$'
group by 1,2,3,4
);


-- 下单日期
drop view if exists order_info;
create view IF not exists order_info (
    dat
    ,store_promotion_id
    ,user_id
    ,order_num
    ,payord_num
    ,current_veriord_num
    ,veriord_num
) as (
select
    date_format(dt,'%Y-%m-%d') as dat
    ,store_promotion_id
    ,user_id
    ,count(1) order_num
    ,count(if(date_format(a.pay_time,'%Y-%m-%d')=date_format(dt,'%Y-%m-%d'),order_id,null)) as payord_num
    ,count(if(date_format(a.verify_time,'%Y-%m-%d')=date_format(dt,'%Y-%m-%d'),order_id,null)) as current_veriord_num
    ,count(if(date_format(a.verify_time,'%Y-%m-%d')<>'1970-01-01',order_id,null)) as veriord_num
from dwd.dwd_sr_silkworm_explore_order a
left join dim.dim_silkworm_county b on a.city_id=b.county_id
where date_format(a.dt,'%Y-%m-%d') between '2025-02-10' and date_sub(current_date(),interval 1 day)
     and a.promotion_type in (5,6)
group by 1,2,3
    );


select
	`类型`
	,`统计日期`
	,`城市`
	,sum(`砍价主页PV`) `砍价主页PV`
	,sum(`砍价主页UV`) `砍价主页UV`
	,sum(`砍价活动详情页PV`) `砍价活动详情页PV`
	,sum(`砍价活动详情页UV`) `砍价活动详情页UV`
	,sum(`报名订单量`) `报名订单量`
	,sum(`支付订单量`) `支付订单量`
	,sum(`当日核销订单量`) `当日核销订单量`
	,sum(`核销订单量(截止目前)`) `核销订单量(截止目前)`
	,sum(`报名用户量`) `报名用户量`
	,sum(`支付用户量`) `支付用户量`
	,sum(`当日核销用户量`) `当日核销用户量`
	,sum(`核销用户量(截止目前)`) `核销用户量(截止目前)`
from
(select 
	'首次访问砍价老用户' `类型`
	,a.dt `统计日期`
	,a.city_name `城市`
	,sum(bargain_hp_pv) `砍价主页PV`
	,count(distinct if(bargain_hp_pv>0,a.user_id,null)) `砍价主页UV`
	,0 `砍价活动详情页PV`
	,0 `砍价活动详情页UV`
	,0 `报名订单量`
	,0 `支付订单量`
	,0 `当日核销订单量`
	,0 `核销订单量(截止目前)`
	,0 `报名用户量`
	,0 `支付用户量`
	,0 `当日核销用户量`
	,0 `核销用户量(截止目前)`
from hp_flow_info a inner join city_info b on a.city_name=b.city_name
inner join dim.dim_silkworm_explore_daren_cleanse c on a.user_id=c.user_id and date_format(c.first_bargain_view_date,'%Y-%m-%d')=a.dt
-- inner join dim.dim_silkworm_user d on a.user_id=d.user_id and date_format(d.register_time,'%Y-%m-%d')=a.dt
inner join dim.dim_silkworm_user d on a.user_id=d.user_id and date_format(d.register_time,'%Y-%m-%d')<a.dt
group by 1,2,3

union all
select 
	'首次访问砍价老用户' `类型`
	,a.dt `统计日期`
	,a.city_name `城市`
	,0 ,0
	,sum(bargain_dp_pv) `砍价活动详情页PV`
	,count(distinct if(bargain_dp_pv>0,a.user_id,null)) `砍价活动详情页UV`
	,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0
from dp_flow_info a inner join city_info b on a.city_name=b.city_name
inner join dim.dim_silkworm_explore_daren_cleanse c on a.user_id=c.user_id and date_format(c.first_bargain_view_date,'%Y-%m-%d')=a.dt
-- inner join dim.dim_silkworm_user d on a.user_id=d.user_id and date_format(d.register_time,'%Y-%m-%d')=a.dt
inner join dim.dim_silkworm_user d on a.user_id=d.user_id and date_format(d.register_time,'%Y-%m-%d')<a.dt
group by 1,2,3

union all

select 
	'首次访问砍价老用户' `类型`
	,b.dt `统计日期`
	,b.city_name `城市`
	,0 ,0 ,0 ,0 
	,sum(order_num) `报名订单量`
	,sum(payord_num) `支付订单量`
	,sum(current_veriord_num) `当日核销订单量`
	,sum(veriord_num) `核销订单量(截止目前)`
	,count(distinct if(order_num>0,b.user_id,null)) `报名用户量`
	,count(distinct if(payord_num>0,b.user_id,null)) `支付用户量`
	,count(distinct if(current_veriord_num>0,b.user_id,null)) `当日核销用户量`
	,count(distinct if(veriord_num>0,b.user_id,null)) `核销用户量(截止目前)`
from dp_flow_info b left join order_info c on b.dt=c.dat and b.activity_id=c.store_promotion_id and b.user_id=c.user_id
inner join city_info d on b.city_name=d.city_name
inner join dim.dim_silkworm_explore_daren_cleanse e on b.user_id=e.user_id and date_format(e.first_bargain_view_date,'%Y-%m-%d')=b.dt
-- inner join dim.dim_silkworm_user f on b.user_id=f.user_id and date_format(f.register_time,'%Y-%m-%d')=b.dt
inner join dim.dim_silkworm_user d on b.user_id=d.user_id and date_format(d.register_time,'%Y-%m-%d')<b.dt
group by 1,2,3
) tot
group by 1,2,3
;




============== 探店+砍价首页浏览活动数分布
-- 首页浏览
DROP VIEW IF EXISTS flow_info;


CREATE VIEW IF NOT EXISTS flow_info ( user_id ,avg_explore_pro_num ,avg_bargain_pro_num) AS ( -- 日均曝光活动数

SELECT user_id,
       ceil(avg(explore_pro_num)) avg_explore_pro_num, -- 取整以便使用
       ceil(avg(bargain_pro_num)) avg_bargain_pro_num
FROM (
-- 曝光活动数
SELECT dt,user_id ,
            count(distinct if(event_name='StoreDiscovery_Activity_Ex',activity_id,NULL)) explore_pro_num ,
            count(distinct if(event_name='Bargain_HomePage_takeout_Activity_ex',activity_id,NULL)) bargain_pro_num
FROM (
SELECT from_unixtime(cast(event_time AS bigint)/1000,'yyyy-MM-dd') AS dt,
       event_name,
       user_id,
       get_json_string(DATA,'$.activity_id') AS activity_id
FROM ods.ods_sr_event_log
WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 8 DAY) AND date_sub(current_date(),interval 2 DAY)
  AND event_name IN ('Bargain_HomePage_takeout_Activity_ex' ,
                     'StoreDiscovery_Activity_Ex' )
 -- and user_id regexp '^[0-9]{1,10}$'
 ) a
WHERE activity_id regexp '^[1-9]{1,8}$'
GROUP BY 1,
         2) b
GROUP BY 1);


-- 近7天砍价支付订单量
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (user_id,promotion_type,order_num) AS
  (SELECT user_id,
          promotion_type,
          count(1) AS order_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE date_format(dt,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 8 DAY) AND date_sub(current_date(),interval 2 DAY)
   GROUP BY 1,
            2);



SELECT count(DISTINCT a.user_id) `曝光用户量`,
       min(avg_explore_pro_num) `最小值`,
       percentile_cont(avg_explore_pro_num,0.1) `10分位`,
       percentile_cont(avg_explore_pro_num,0.2) `20分位`,
       percentile_cont(avg_explore_pro_num,0.3) `30分位`,
       percentile_cont(avg_explore_pro_num,0.4) `40分位`,
       percentile_cont(avg_explore_pro_num,0.5) `50分位`,
       percentile_cont(avg_explore_pro_num,0.6) `60分位`,
       percentile_cont(avg_explore_pro_num,0.7) `70分位`,
       percentile_cont(avg_explore_pro_num,0.8) `80分位`,
       percentile_cont(avg_explore_pro_num,0.9) `90分位`,
       max(avg_explore_pro_num) `最大值` 
 --    count(distinct user_id) `曝光用户量`,
 --    min(avg_bargain_pro_num) `最小值`,
 --    percentile_cont(avg_bargain_pro_num,0.1) `10分位`,
 --    percentile_cont(avg_bargain_pro_num,0.2) `20分位`,
 --    percentile_cont(avg_bargain_pro_num,0.3) `30分位`,
 --    percentile_cont(avg_bargain_pro_num,0.4) `40分位`,
 --    percentile_cont(avg_bargain_pro_num,0.5) `50分位`,
 --    percentile_cont(avg_bargain_pro_num,0.6) `60分位`,
 --    percentile_cont(avg_bargain_pro_num,0.7) `70分位`,
 --    percentile_cont(avg_bargain_pro_num,0.8) `80分位`,
 --    percentile_cont(avg_bargain_pro_num,0.9) `90分位`,
 --    max(avg_bargain_pro_num) `最大值`
FROM flow_info a inner join order_info b on a.user_id=b.user_id and b.promotion_type in (1,4)
WHERE avg_explore_pro_num<>0 
-- avg_bargain_pro_num<>0
;


============ 到店首页流量统计
DROP VIEW IF EXISTS view_info;


CREATE VIEW IF NOT EXISTS view_info (dt,event_name,user_id,activity_type,filter_condition,filter_classification,filter_condition) AS
  (SELECT dt,
          event_name,
          user_id,
          get_json_string(data,'$.activity_type') activity_type,
                                                  get_json_string(data,'$.filter_condition') filter_condition,
                                                                                             get_json_string(data,'$.filter_classification') filter_classification
                                                                                             
   FROM ods.ods_sr_event_log
   WHERE dt between '2025-05-02' and '2025-05-08'
     AND event_name IN ('StoreDiscovery_Homepage_Activities_Filter', -- 探店主页筛选
                        'StoreDiscovery_Homepage_InfluencerZone_Module_Ex', -- 探店主页曝光
                        'Bargain_Homepage_Ex', -- 砍价主页曝光
                        'Bargain_Homepage_Filter_Button_Click' -- 砍价主页筛选
                        )
    and user_id regexp '^[0-9]{1,10}$');


SELECT filter_condition,
       ceil(avg(`曝光量`)) `曝光量`,
       ceil(avg(`曝光用户量`)) `曝光用户量`,
       ceil(avg(`点击量`)) `点击量`,
       ceil(avg(`点击用户量`)) `点击用户量`
FROM
  (SELECT dt,
          filter_condition,
          sum(if(event_name='Bargain_Homepage_Ex',1,0)) `曝光量`,
          count(distinct if(event_name='Bargain_Homepage_Ex',user_id,null)) `曝光用户量`,
          sum(if(event_name='Bargain_Homepage_Filter_Button_Click',1,0)) `点击量`,
          count(DISTINCT if(event_name='Bargain_Homepage_Filter_Button_Click',user_id,NULL)) `点击用户量`
   FROM view_info
   GROUP BY 1,
            2) a
GROUP BY 1;











