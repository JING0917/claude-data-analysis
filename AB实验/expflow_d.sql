--JDBC SQL
--******************************************************************--
--author: dahe
--create time: 2026-03-12 11:02:27
--******************************************************************--

-- 20260424 新增距离 活动状态 修改人：dahe
-- ALTER TABLE dws.dws_sr_traffic_homepage_mix_expflow_d
--   ADD COLUMN distance int comment '距离(米)' AFTER promotion_id,
--   ADD COLUMN activity_status varchar(50) comment '活动状态' AFTER distance;

-- 20260427 distance/activity_status加入PRIMARY KEY（通过新建表+数据迁移方式更改，见migration脚本）
CREATE TABLE if not exists dws.dws_sr_traffic_homepage_mix_expflow_d (
  statistics_date date not null comment '统计日期',
  county_id int not null comment '区县ID',
  platform_name varchar(20) not null comment '平台名称',
  app_version varchar(20) not null comment '版本',
  expno varchar(20) not null comment '实验号',
  expflow varchar(20) not null comment '实验流(实验组/对照组)',
  activity_type varchar(20) not null comment '活动类型',
  promotion_id int not null comment '活动ID',
  distance int comment '距离(米)',
  activity_status varchar(50) comment '活动状态',
  expouse_num bigint comment '曝光量',
  expouse_uids bitmap comment '曝光用户列表',
  clc_num bigint comment '点击量',
  clc_uids bitmap comment '点击用户列表',
  detailpage_pv bigint comment '详情页PV',
  detailpage_view_uids bitmap comment '详情页浏览用户列表',
  baoming_order_num bigint comment '小蚕报名订单量',
  baoming_uids bitmap comment '小蚕报名用户列表',
  valid_order_num bigint comment '小蚕有效订单量',
  valid_uids bitmap comment '小蚕有效用户列表',
  xx_baoming_order_num bigint comment '晓晓报名订单量',
  xx_baoming_uids bitmap comment '晓晓报名用户列表',
  xx_valid_order_num bigint comment '晓晓有效订单量',
  xx_valid_uids bitmap comment '晓晓有效用户列表'
)
ENGINE=OLAP
PRIMARY KEY (statistics_date,county_id,platform_name,app_version,expno,expflow,activity_type,promotion_id,distance,activity_status)
COMMENT "首页融合归因实验日数据"
DISTRIBUTED BY HASH(statistics_date,county_id,promotion_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);


-- 流量解析
DROP VIEW IF EXISTS origin_traffic_info;


CREATE VIEW IF NOT EXISTS origin_traffic_info (time,event,county_id,activity_id,uid,platform_name,app_version,activity_type,user_id,expno,expflow,distance,activity_status) AS
  (SELECT time,
          event,
          get_json_string(properties,'$.city') AS county_id,
          -- get_json_string(properties,'$.position') AS position,
          get_json_string(properties,'$.activity_id') AS activity_id,
          get_json_string(properties,'$.user_id') AS uid,
          get_json_string(properties,'$.platform_type') AS platform_name,
          get_json_string(properties,'$.$app_version') AS app_version,
          -- get_json_string(properties,'$.button_name') AS button_name,
          -- get_json_string(properties,'$.from_source') AS from_source,
          get_json_string(properties,'$.activity_type') AS activity_type,
          distinct_id AS user_id,
          '0' as expno,
        --   if(right(distinct_id,1) between 0 and 7,'实验组','对照组') expflow -- 20260331 31日开始 实验组用户由0到4 调整为0到7 修改人:dahe
        case when right(distinct_id,1) between 0 and 3 then '实验组1'
            when right(distinct_id,1) between 4 and 7 then '实验组2'
            else '对照组'
        end as expflow -- 20260420 17日开始 实验组拆分出两个组 实验组1(用户由0到3) 实验组2(用户由4到7) 剩余是对照组 修改人:dahe
        -- 20260424 新增距离 活动状态 修改人:dahe
          ,get_json_string(properties,'$.distance') AS distance
          ,get_json_string(properties,'$.activity_status') AS activity_status       
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
   WHERE date_format(time,'%Y-%m-%d')='${T}'
     AND event IN ('Homepage_Feed_Activity_Ex',
                   'Homepage_Feed_Activity_Click',
                   'Takeaway_Detailpage_View',
                   'Takeaway_Baomingflow_Button_Click')
    AND distinct_id regexp '^[0-9]{1,10}$');

-- 清洗流量数据
DROP VIEW IF EXISTS traffic_info;


CREATE VIEW IF NOT EXISTS traffic_info (time,event,county_id,activity_id,uid,platform_name,app_version,activity_type,user_id,expno,expflow,distance,activity_status) AS
  (SELECT time,
          event,
          CASE
              WHEN county_id IS NULL
                   OR county_id='0'
                   OR county_id=''
                   OR county_id='null' THEN 0
              ELSE cast(county_id AS int)
          END AS county_id,
          -- position,
          CASE
              WHEN activity_id regexp '^[0-9]{1,9}$' THEN cast(activity_id AS int) -- 20260331 活动ID调整为最长9位 修改人:dahe
              ELSE 0
          END activity_id,
              uid,
              CASE
                  WHEN platform_name regexp '5' THEN 'H5'
                  WHEN platform_name regexp '小程序' THEN '微信小程序'
                  WHEN platform_name IN ('Android',
                                         'Harmony') THEN 'Android'
                  WHEN platform_name='iOS' THEN 'iOS'
              END platform_name,
                  if(app_version IS NULL,'未知',app_version) app_version,
                                                           CASE
                                                               WHEN activity_type IS NULL
                                                                    OR activity_type='' THEN '小蚕活动'
                                                               ELSE activity_type
                                                           END activity_type,
                                                           user_id,
                                                           expno,
                                                           expflow,
                                                           if(distance is null,-1,distance) distance,
                                                           if(activity_status is null OR activity_status='','未知',activity_status) activity_status
   FROM origin_traffic_info
   WHERE (platform_name IS NOT NULL
          OR platform_name<>'')
     );



-- 统计首页feed流活动曝光和点击
DROP VIEW IF EXISTS feed_info;


CREATE VIEW IF NOT EXISTS feed_info (statistics_date,county_id,activity_id,platform_name,app_version,activity_type,expno,expflow,distance,activity_status,expouse_num,expouse_uids,clc_num,clc_uids) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     -- position,
                     activity_id,
                     platform_name,
                     app_version,
                     activity_type,
                     expno,
                     expflow,
                     distance,
                     activity_status,
                     sum(if(event='Homepage_Feed_Activity_Ex',1,0)) expouse_num,
                     bitmap_agg(if(event='Homepage_Feed_Activity_Ex',user_id,NULL)) expouse_uids,
                     sum(if(event='Homepage_Feed_Activity_Click',1,0)) clc_num,
                     bitmap_agg(if(event='Homepage_Feed_Activity_Click',user_id,NULL)) clc_uids
   FROM traffic_info
   WHERE event IN ('Homepage_Feed_Activity_Ex',
                   'Homepage_Feed_Activity_Click')
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10);

-- -- 验证 无重复
-- select county_id,platform_name,app_version,activity_id,activity_type,count(1) tot from feed_info group by 1,2,3,4,5 having count(1)>1 LIMIT 100;


-- 统计首页feed流活动点击
DROP VIEW IF EXISTS feed_clc;


CREATE VIEW IF NOT EXISTS feed_clc (statistics_date,county_id,activity_id,platform_name,app_version,activity_type,user_id,expno,expflow,distance,activity_status,clc_num) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     -- position,
                     activity_id,
                     platform_name,
                     app_version,
                     activity_type,
                     user_id,
                     expno,
                     expflow,
                     distance,
                     activity_status,
                     count(1) clc_num
   FROM traffic_info
   WHERE event='Homepage_Feed_Activity_Click'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11);

-- -- 验证 无重复
-- select county_id,platform_name,app_version,activity_id,user_id,count(1) tot from feed_clc group by 1,2,3,4,5 having count(1)>1 LIMIT 100;


-- 统计外卖详情页浏览
DROP VIEW IF EXISTS detail_view;


CREATE VIEW IF NOT EXISTS detail_view (statistics_date,county_id,activity_id,platform_name,app_version,user_id,expno,expflow,distance,activity_status,pv) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     activity_id,
                     platform_name,
                     app_version,
                     user_id,
                     expno,
                     expflow,
                     distance,
                     activity_status,
                     count(1) pv
   FROM traffic_info
   WHERE event='Takeaway_Detailpage_View'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10);

-- 验证 有重复 同活动ID activity_type不同
-- 丢弃activity_type 用首页曝光点击activity_type
-- select county_id,platform_name,app_version,activity_id,user_id,count(1) tot from detail_view group by 1,2,3,4,5 having count(1)>1 LIMIT 100;
-- select * from detail_view where uid='-8649375737743604889' and activity_id=88629789;


-- 报名按钮点击
DROP VIEW IF EXISTS bm_clc;


CREATE VIEW IF NOT EXISTS bm_clc (statistics_date,county_id,activity_id,platform_name,app_version,user_id,expno,expflow,distance,activity_status,bm_clc_num) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     activity_id,
                     platform_name,
                     app_version,
                     user_id,
                     expno,
                     expflow,
                     distance,
                     activity_status,
                     count(1) bm_clc_num
   FROM traffic_info
   WHERE event='Takeaway_Baomingflow_Button_Click'
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10);

-- -- 验证 无重复
-- select county_id,platform_name,app_version,activity_id,user_id,count(1) tot from bm_clc group by 1,2,3,4,5 having count(1)>1 LIMIT 100;



-- 外卖订单
DROP VIEW IF EXISTS order_info;


CREATE VIEW IF NOT EXISTS order_info (create_time,store_promotion_id,user_id,auto_id,order_time,order_id,order_status,order_type,profit) AS
  (SELECT create_time,
             store_promotion_id,
             user_id,
             auto_id,
             order_time,
             order_id,
             order_status,
             order_type,
             profit
      FROM dwd.dwd_sr_order_promotion_order
      WHERE dt BETWEEN date_sub('${T}',interval 1 DAY) AND '${T}');



-- 订单归因数据集
DROP VIEW IF EXISTS order_ascribe;


CREATE VIEW IF NOT EXISTS order_ascribe (statistics_date,county_id,activity_id,platform_name,app_version,user_id,expno,expflow,distance,activity_status,baoming_order_num,valid_order_num,profit,xx_baoming_order_num,xx_valid_order_num) AS
  (SELECT date_format(time,'%Y-%m-%d') statistics_date,
          county_id,
          activity_id,
          platform_name,
          app_version,
          user_id,
          expno,
          expflow,
          distance,
          activity_status,
          count(DISTINCT CASE WHEN rn=1 THEN auto_id END) baoming_order_num,
          count(DISTINCT CASE WHEN rn=1 AND order_status IN (2,8) THEN auto_id END) valid_order_num,
          sum(CASE WHEN rn=1 AND order_status=2 THEN profit ELSE 0 END) profit,
          count(DISTINCT CASE WHEN rn=1 AND order_type=15 THEN auto_id END) xx_baoming_order_num,
          count(DISTINCT CASE WHEN rn=1 AND order_status IN (2,8) AND order_type=15 THEN auto_id END) xx_valid_order_num
   FROM
     (SELECT a.time,
             a.county_id,
             a.activity_id,
             a.platform_name,
             a.app_version,
             a.user_id,
             a.expno,
             a.expflow,
             a.distance,
             a.activity_status,
             b.auto_id,
             b.order_status,
             b.profit,
             b.order_type,
             ROW_NUMBER() OVER (
               PARTITION BY a.user_id, IFNULL(b.auto_id, 0)
               ORDER BY ABS(date_diff('second',b.create_time,a.time))
             ) AS rn
      FROM
        (SELECT time,
                county_id,
                activity_id,
                platform_name,
                app_version,
                user_id,
                expno,
                expflow,
                distance,
                activity_status
         FROM traffic_info
         WHERE event='Takeaway_Detailpage_View') a
      LEFT JOIN order_info b ON a.user_id=b.user_id
        AND date_diff('minute',b.create_time,a.time) BETWEEN 0 AND 15) t
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10);



-- 聚合非首页流量数据
DROP VIEW IF EXISTS agg_funnel;


CREATE VIEW IF NOT EXISTS agg_funnel (statistics_date,county_id,activity_id,platform_name,app_version,expno,expflow,activity_type,distance,activity_status,view_uids,pv,bm_uids,bm_clc_num, order_uids,bm_order_num,valid_order_uids,valid_order_num,profit,xx_bm_order_uids,xx_bm_order_num,xx_valid_order_uids,xx_valid_order_num) AS
  (SELECT a.statistics_date,
          a.county_id,
          a.activity_id,
          a.platform_name,
          a.app_version,
          a.expno,
          a.expflow,
          a.activity_type,
          a.distance,
          a.activity_status,
          bitmap_agg(if(b.user_id IS NOT NULL,a.user_id,NULL)) view_uids,
          sum(if(b.user_id IS NOT NULL,b.pv,0)) pv,
          bitmap_agg(if(c.user_id IS NOT NULL,a.user_id,NULL)) bm_uids,
          sum(if(c.user_id IS NOT NULL,c.bm_clc_num,0)) bm_clc_num,
          bitmap_agg(if(d.user_id IS NOT NULL,a.user_id,NULL)) order_uids,
          sum(if(d.user_id IS NOT NULL,d.baoming_order_num,0)) bm_order_num,
          bitmap_agg(if(d.user_id IS NOT NULL AND d.valid_order_num>0,a.user_id,NULL)) valid_order_uids,
          sum(if(d.user_id IS NOT NULL AND d.valid_order_num>0,d.valid_order_num,0)) valid_order_num,
          sum(if(d.user_id IS NOT NULL AND d.valid_order_num>0,d.profit,0)) profit,
          bitmap_agg(if(d.user_id IS NOT NULL AND d.xx_baoming_order_num>0,a.user_id,NULL)) xx_bm_order_uids,
          sum(if(d.user_id IS NOT NULL,d.xx_baoming_order_num,0)) xx_bm_order_num,
          bitmap_agg(if(d.user_id IS NOT NULL AND d.xx_valid_order_num>0,a.user_id,NULL)) xx_valid_order_uids,
          sum(if(d.user_id IS NOT NULL AND d.xx_valid_order_num>0,d.valid_order_num,0)) xx_valid_order_num
   FROM feed_clc a
   LEFT JOIN detail_view b ON a.statistics_date=b.statistics_date
   AND a.county_id=b.county_id
   AND a.activity_id=b.activity_id
   AND a.platform_name=b.platform_name
   AND a.app_version=b.app_version
   AND a.user_id=b.user_id
   AND a.distance=b.distance
   AND a.activity_status=b.activity_status
   LEFT JOIN bm_clc c ON c.statistics_date=b.statistics_date
   AND c.county_id=b.county_id
   AND c.activity_id=b.activity_id
   AND c.platform_name=b.platform_name
   AND c.app_version=b.app_version
   AND c.user_id=b.user_id
   AND c.distance=b.distance
   AND c.activity_status=b.activity_status
   LEFT JOIN order_ascribe d ON c.statistics_date=d.statistics_date
   AND c.county_id=d.county_id
   AND c.activity_id=d.activity_id
   AND c.platform_name=d.platform_name
   AND c.app_version=d.app_version
   AND c.user_id=d.user_id
   AND c.distance=d.distance
   AND c.activity_status=d.activity_status
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10);

INSERT INTO dws.dws_sr_traffic_homepage_mix_expflow_d

SELECT a.statistics_date,
       a.county_id,
       a.platform_name,
       a.app_version,
       a.expno,
       a.expflow,
       a.activity_type,
       a.activity_id,
       a.distance,
       a.activity_status,
       a.expouse_num,
       a.expouse_uids,
       a.clc_num,
       a.clc_uids,
       pv,
       view_uids,
       bm_order_num,
       order_uids,
       valid_order_num,
       valid_order_uids,
       xx_bm_order_num,
       xx_bm_order_uids,
       xx_valid_order_num,
       xx_valid_order_uids       
FROM feed_info a
LEFT JOIN agg_funnel b
ON a.statistics_date=b.statistics_date
   AND a.county_id=b.county_id
   AND a.activity_id=b.activity_id
   AND a.platform_name=b.platform_name
   AND a.app_version=b.app_version
   AND a.expno=b.expno
   AND a.expflow=b.expflow
   AND a.distance=b.distance
   AND a.activity_status=b.activity_status
;