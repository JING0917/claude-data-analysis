-- hotspots
Homepage_Opp_Click
Homepage_Feed_Banner_Click
HomePage_Feed_Placement_Click
Homepage_Headpic_Click

-- hotarea_id
Homepage_Opp_Click
HomePage_Feed_Placement_Click
Homepage_Headpic_Click


'Homepage_View',
'HomePage_View',
'Homepage_Opp_Click',
'Homepage_Feed_Banner_Ex',
'Homepage_Feed_Banner_Click',
'HomePage_Feed_Placement_EX',
'HomePage_Feed_Placement_Click',
'Homepage_Headpic_Ex',
'Homepage_Headpic_Click'


dws_sr_market_traffic_hotarea_d分日站内投放热区流量(按平台聚合)

DROP TABLE IF EXISTS dws.dws_sr_market_traffic_hotarea_d;

CREATE TABLE if not exists dws.dws_sr_market_traffic_hotarea_d (
    statistics_date date not null COMMENT '统计日期',
    platform_type int COMMENT '平台类型(99:全部;1:H5;2:微信小程序;3:到店微信小程序;4:探店微信小程序;5:Android;6:iOS)',
    resource_id int COMMENT '资源ID',
    put_id int COMMENT '投放位ID',
    abtest_id int COMMENT 'AB测试ID,999999999:全部',
    hotspots int COMMENT '热区ID'
    resource_name varchar(150) COMMENT '资源名称',
    put_name varchar(150) COMMENT '投放位名称',
    exp_name varchar(15) COMMENT 'AB测试组名称',
    expouse_num BIGINT COMMENT '总曝光次数',
    expouse_uv BIGINT COMMENT '去重曝光用户量',
    clc_num BIGINT COMMENT '总点击次数',
    clc_uv BIGINT COMMENT '去重点击用户量'
) ENGINE=OLAP
PRIMARY KEY(statistics_date, platform_type, resource_id, put_id,abtest_id,hotspots)
COMMENT "分日站内投放热区流量(按平台聚合)"
DISTRIBUTED BY HASH(resource_id,put_id)
PROPERTIES (
    "replication_num" = "2",
    "enable_persistent_index" = "true",
    "replicated_storage" = "true",
    "in_memory" = "false",
    "compression" = "LZ4"
);

DROP VIEW IF EXISTS traffic_info;


CREATE VIEW IF NOT EXISTS traffic_info (dt,event,user_id,platform_type,resource_id,put_id,abtest_id,hotspots,hotarea_id) AS
  (SELECT date(time) dt,
                     event,
                     get_json_string(properties,'$.user_id') user_id,
                     get_json_string(properties,'$.platform_type') platform_type,
                     get_json_string(properties,'$.resource_id') resource_id,
                     get_json_string(properties,'$.put_id') put_id,
                     get_json_string(properties,'$.abtest_id') abtest_id,
                     get_json_string(properties,'$.hotspots') hotspots,
                     get_json_string(properties,'$.hotarea_id') hotarea_id
   FROM ods.ods_sr_traffic_sensor_event_log_realtime
WHERE time >= '${T-1} 00:00:00'
  AND time < '${T-1} 00:00:00' + INTERVAL 1 DAY
  AND event IN ('Homepage_View',
                'HomePage_View',
                'Homepage_Opp_Click',
                'Homepage_Feed_Banner_Ex',
                'Homepage_Feed_Banner_Click',
                'HomePage_Feed_Placement_Ex',
                'HomePage_Feed_Placement_Click',
                'Homepage_Headpic_Ex',
                'Homepage_Headpic_Click'));



DROP VIEW IF EXISTS traffic_result;


CREATE VIEW IF NOT EXISTS traffic_result (dt,event,user_id,platform_type,resource_id,put_id,abtest_id,hotspots,hotarea_id) AS
  (SELECT dt,
          event,
          user_id,
          CASE
              WHEN platform_type regexp '5' THEN 1
              WHEN platform_type IN ('小程序',
                                     '微信小程序') THEN 2
              WHEN platform_type IN ('到店微信小程序',
                                     '到店小程序') THEN 3
              WHEN platform_type = '探店小程序' THEN 4
              WHEN platform_type IN ('Android',
                                     'Harmony') THEN 5
              WHEN platform_type = 'iOS' THEN 6
          END AS platform_type,
          CASE
              WHEN resource_id='POPUP_NEW' THEN 106
              WHEN resource_id='THEME_SKIN' THEN 1
              WHEN resource_id='OPS_POPUP' THEN 3
              WHEN resource_id='BANNER' THEN 2
              WHEN resource_id IS NULL
                   OR resource_id='' THEN 0
              ELSE resource_id
          END AS resource_id,
          CASE
              WHEN put_id IS NULL
                   OR put_id='' THEN 0
              ELSE put_id
          END AS put_id,
          CASE
              WHEN abtest_id IS NULL
                   OR abtest_id='' THEN 0
              ELSE abtest_id
          END AS abtest_id,
          CASE
              WHEN hotspots IN ('1',
                                '热区1') THEN 1
              WHEN hotspots IN ('2',
                                '热区2') THEN 2
              WHEN hotspots IN ('3',
                                '热区3') THEN 3
              WHEN hotspots IN ('4',
                                '热区4') THEN 4
              WHEN hotspots IN ('5',
                                '热区5') THEN 5
              ELSE hotspots
          END hotspots,
              CASE
                  WHEN hotarea_id='0' THEN 1
                  WHEN hotarea_id='1' THEN 2
                  WHEN hotarea_id='2' THEN 3
                  WHEN hotarea_id='3' THEN 4
                  WHEN hotarea_id='4' THEN 5
                  ELSE hotarea_id
              END hotarea_id
   FROM traffic_info
   WHERE platform_type IS NOT NULL);


INSERT INTO dws.dws_sr_market_traffic_hotarea_d

-- 首页运营位点击和曝光
WITH t1 AS
  (SELECT a.dt,
          a.platform_type,
          resource_id,
          put_id,
          abtest_id,
          hotspots,
          ex_num,
          ex_uids,
          clc_num,
          clc_uids
   FROM
     (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             hotspots,
             count(1) clc_num,
                      bitmap_agg(user_id) clc_uids
      FROM
        (SELECT dt,
                platform_type,
                user_id,
                resource_id,
                put_id,
                abtest_id,
                coalesce(hotspots,hotarea_id) hotspots
         FROM traffic_result
         WHERE event='Homepage_Opp_Click'
           AND (hotspots IS NOT NULL
                OR hotarea_id IS NOT NULL)
           AND resource_id<>0
           AND resource_id IS NOT NULL
           AND put_id<>0
           AND put_id IS NOT NULL) a1
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN
     (SELECT dt,
             platform_type,
             count(1) ex_num,
                      bitmap_agg(user_id) ex_uids
      FROM traffic_result
      WHERE event IN ('Homepage_View',
                      'HomePage_View')
      GROUP BY 1,
               2) b ON a.dt=b.dt
   AND a.platform_type=b.platform_type),



-- 头图曝光点击
t2 AS
  (SELECT a.dt,
          a.platform_type,
          resource_id,
          put_id,
          abtest_id,
          hotspots,
          ex_num,
          ex_uids,
          clc_num,
          clc_uids
   FROM
     (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             hotspots,
             count(1) clc_num,
                      bitmap_agg(user_id) clc_uids
      FROM
        (SELECT dt,
                platform_type,
                user_id,
                resource_id,
                put_id,
                abtest_id,
                coalesce(hotspots,hotarea_id) hotspots
         FROM traffic_result
         WHERE event='Homepage_Headpic_Click'
           AND (hotspots IS NOT NULL
                OR hotarea_id IS NOT NULL)
           AND resource_id<>0
           AND resource_id IS NOT NULL
           AND put_id<>0
           AND put_id IS NOT NULL) a1
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN
     (SELECT dt,
             platform_type,
             count(1) ex_num,
                      bitmap_agg(user_id) ex_uids
      FROM traffic_result
      WHERE event IN ('Homepage_View',
                      'HomePage_View')
      GROUP BY 1,
               2) b ON a.dt=b.dt
   AND a.platform_type=b.platform_type),


-- fee流banner曝光点击
t3 AS
  (SELECT a.dt,
          a.platform_type,
          a.resource_id,
          a.put_id,
          a.abtest_id,
          hotspots,
          ex_num,
          ex_uids,
          clc_num,
          clc_uids
   FROM
     (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             hotspots,
             count(1) clc_num,
                      bitmap_agg(user_id) clc_uids
      FROM
        (SELECT dt,
                platform_type,
                user_id,
                resource_id,
                put_id,
                abtest_id,
                coalesce(hotspots,hotarea_id) hotspots
         FROM traffic_result
         WHERE event='Homepage_Feed_Banner_Click'
           AND (hotspots IS NOT NULL
                OR hotarea_id IS NOT NULL)
           AND resource_id<>0
           AND resource_id IS NOT NULL
           AND put_id<>0
           AND put_id IS NOT NULL) a1
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN
     (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             count(1) ex_num,
                      bitmap_agg(user_id) ex_uids
      FROM traffic_result
      WHERE event ='Homepage_Feed_Banner_Ex'
      GROUP BY 1,
               2,
               3,
               4,
               5) b ON a.dt=b.dt
   AND a.platform_type=b.platform_type
   AND a.resource_id=b.resource_id
   AND a.put_id=b.put_id
   AND a.abtest_id=b.abtest_id),


-- feed流资源位曝光点击
t4 AS
  (SELECT a.dt,
          a.platform_type,
          a.resource_id,
          a.put_id,
          a.abtest_id,
          hotspots,
          ex_num,
          ex_uids,
          clc_num,
          clc_uids
   FROM
     (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             hotspots,
             count(1) clc_num,
                      bitmap_agg(user_id) clc_uids
      FROM
        (SELECT dt,
                platform_type,
                user_id,
                resource_id,
                put_id,
                abtest_id,
                coalesce(hotspots,hotarea_id) hotspots
         FROM traffic_result
         WHERE event='HomePage_Feed_Placement_Click'
           AND (hotspots IS NOT NULL
                OR hotarea_id IS NOT NULL)
           AND resource_id<>0
           AND resource_id IS NOT NULL
           AND put_id<>0
           AND put_id IS NOT NULL) a1
      GROUP BY 1,
               2,
               3,
               4,
               5,
               6) a
   LEFT JOIN
     (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             count(1) ex_num,
                      bitmap_agg(user_id) ex_uids
      FROM traffic_result
      WHERE event ='HomePage_Feed_Placement_Ex'
      GROUP BY 1,
               2,
               3,
               4,
               5) b ON a.dt=b.dt
   AND a.platform_type=b.platform_type
   AND a.resource_id=b.resource_id
   AND a.put_id=b.put_id
   AND a.abtest_id=b.abtest_id),

-- 初聚合 后续调用
t5 AS (SELECT dt,
             platform_type,
             resource_id,
             put_id,
             abtest_id,
             hotspots,
             ex_num,
             ex_uids,
             clc_num,
             clc_uids
      FROM t1
      UNION ALL SELECT dt,
                       platform_type,
                       resource_id,
                       put_id,
                       abtest_id,
                       hotspots,
                       ex_num,
                       ex_uids,
                       clc_num,
                       clc_uids
      FROM t2
      UNION ALL SELECT dt,
                       platform_type,
                       resource_id,
                       put_id,
                       abtest_id,
                       hotspots,
                       ex_num,
                       ex_uids,
                       clc_num,
                       clc_uids
      FROM t3
      UNION ALL SELECT dt,
                       platform_type,
                       resource_id,
                       put_id,
                       abtest_id,
                       hotspots,
                       ex_num,
                       ex_uids,
                       clc_num,
                       clc_uids
      FROM t4),

-- 分组+整体聚合
t6 AS
  (SELECT dt,
          platform_type,
          resource_id,
          put_id,
          abtest_id,
          hotspots,
          sum(ex_num) ex_num,
                      bitmap_union_count(ex_uids) ex_uv,
                                                  sum(clc_num) clc_num,
                                                               bitmap_union_count(clc_uids) clc_uv
   FROM t5
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6
union all

SELECT dt,
          99 platform_type,
          resource_id,
          put_id,
          999999999 abtest_id,
          hotspots,
          sum(ex_num) ex_num,
                      bitmap_union_count(ex_uids) ex_uv,
                                                  sum(clc_num) clc_num,
                                                               bitmap_union_count(clc_uids) clc_uv
   FROM t5
   GROUP BY 1,
            2,
            3,
            4,
            5,
            6
)



SELECT dt,
       platform_type,
       b.resource_id,
       t6.put_id,
       t6.abtest_id,
       t6.hotspots,
       c.resource_name,
       b.put_name,
       d.exp_name,
       ex_num,
       ex_uv,
       clc_num,
       clc_uv
FROM t6
INNER JOIN dim.dim_res_position_put b ON t6.put_id = b.put_id and date(b.end_time)>='${T-1}'
INNER JOIN dim.dim_res_position c ON b.resource_id = c.resource_id
LEFT JOIN dim.dim_ma_experiment d ON t6.abtest_id = d.auto_id;







