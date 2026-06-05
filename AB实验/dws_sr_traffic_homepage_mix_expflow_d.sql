-- drop table if exists dws.dws_sr_traffic_homepage_mix_expflow_d;

CREATE TABLE if not exists dws.dws_sr_traffic_homepage_mix_expflow_d (
  statistics_date date not null comment '统计日期',
  county_id int not null comment '区县ID',
  platform_name varchar(20) not null comment '平台名称',
  app_version varchar(20) not null comment '版本',
  expno varchar(20) not null comment '实验号',
  expflow varchar(20) not null comment '实验流(实验组/对照组)',
  activity_type varchar(20) not null comment '活动类型',
  promotion_id int not null comment '活动ID',
  distance int not null comment '距离(米)',
  activity_status varchar(25) not null comment '活动状态',
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


-- ===========================================================================
-- 【优化1+4+5】流量解析 — 分区裁剪 + 临时表 + CPU优化 (dahe 20260430)
--
-- OLD 架构:
--   origin_traffic_info (VIEW) → traffic_info (VIEW) → 下游6个VIEW各自扫描ods表
--   问题1: date_add/字符串+INTERVAL 内部都转 days_add(), 分区裁剪器不折叠 → 288分区全扫(1196亿行!)
--   问题2: 下游6个视图，每个独立扫描ods表同一分区 ~4.28亿行
--   问题3: CTAS 建4.28亿行临时表，CPU飙到80%+。原因:
--          a) CTAS默认replication_num=3，写3副本 = 3倍写放大
--          b) REGEXP '5' / REGEXP '小程序' 触发正则引擎，LIKE更快
--          c) RIGHT(dist_id,1) 字符串操作，整数取模更快
--          d) CTAS 单事务原子操作，无法控制写入并行度
--
-- NEW 架构:
--   优化1: 分区谓词只用纯字符串常量 (date_add/字符串+INTERVAL 内部都转 days_add, 分区裁剪器不折叠)
--   优化4: origin_traffic_info + traffic_info 合并为临时表，ods只扫描一次
--   优化5: 预建表 + INSERT INTO 替代CTAS:
--          a) replication_num=1 (临时表无需多副本，省3倍写)
--          b) REGEXP → LIKE (精确子串匹配走KMP/BM，不走正则引擎)
--          c) RIGHT() → CAST(...AS BIGINT)%10 (整数运算省CPU)
--          d) Session参数调优 (parallel_fragment_exec_instance_num)
--          e) 显式BUCKETS=48 控制写入并行度
--
-- 预期 CPU: 80%+ → 预计 <50% (1196亿行→~4亿行, 分区裁剪是核心)
-- 验证: EXPLAIN查看 partitionsRatio (应为1/288), ScanNode实际扫描行数
-- ===========================================================================

-- OLD: origin_traffic_info (VIEW) + traffic_info (VIEW) — 已废弃，合并到 tmp_traffic_info
-- OLD: CTAS 一次性建表写入 — 已废弃，改为预建表 + INSERT INTO

-- Session参数调优
SET parallel_fragment_exec_instance_num = 8;
SET query_timeout = 7200;
SET enable_insert_strict = false;  -- 容忍少量格式异常行被过滤，避免整批INSERT失败

DROP TABLE IF EXISTS tmp_traffic_info;

-- 【优化5】预建表：显式控制副本数、分桶数、排序键
CREATE TABLE tmp_traffic_info (
    time DATETIME NOT NULL,
    event VARCHAR(50) NOT NULL,
    county_id INT NOT NULL,
    activity_id INT NOT NULL,
    uid VARCHAR(50),
    platform_name VARCHAR(20),
    app_version VARCHAR(20),
    activity_type VARCHAR(20),
    user_id VARCHAR(50) NOT NULL,
    expno VARCHAR(20) NOT NULL,
    expflow VARCHAR(20) NOT NULL,
    distance INT NOT NULL,
    activity_status VARCHAR(25) NOT NULL
)
ENGINE=OLAP
DUPLICATE KEY(time, event)          -- 按时间+事件排序，加速下游event过滤
DISTRIBUTED BY HASH(user_id) BUCKETS 48  -- 显式分桶，控制写入并行度
PROPERTIES (
    "replication_num" = "1",         -- 临时表无需多副本，省3倍写入
    "compression" = "LZ4"
);

-- 【优化5】INSERT INTO 替代 CTAS，写入阶段可并行
INSERT INTO tmp_traffic_info
SELECT
    time,
    event,
    CASE
        WHEN county_raw IS NULL OR county_raw='0' OR county_raw='' OR county_raw='null' THEN 0
        WHEN county_raw REGEXP '^[0-9]{1,9}$' THEN CAST(county_raw AS INT)
        ELSE 0  -- 【修复】非数值字符串CAST返回NULL→违反NOT NULL→INSERT strict mode过滤失败,加ELSE 0兜底
    END AS county_id,
    CASE
        WHEN activity_raw REGEXP '^[0-9]{1,9}$' THEN CAST(activity_raw AS INT)
        ELSE 0
    END AS activity_id,
    uid,
    CASE
        WHEN platform_raw LIKE '%5%' THEN 'H5'                    -- 【优化5】LIKE替代REGEXP
        WHEN platform_raw LIKE '%小程序%' THEN '微信小程序'       -- 【优化5】LIKE替代REGEXP
        WHEN platform_raw IN ('Android', 'Harmony') THEN 'Android'
        WHEN platform_raw = 'iOS' THEN 'iOS'
    END AS platform_name,
    IF(app_ver IS NULL, '未知', app_ver) AS app_version,
    CASE
        WHEN act_type IS NULL OR act_type = '' THEN '小蚕活动'
        ELSE act_type
    END AS activity_type,
    user_id,
    '0' AS expno,
    CASE
        -- 【优化5】CAST取模替代RIGHT()字符串截取，整数运算省CPU
        WHEN CAST(dist_id AS BIGINT) % 10 BETWEEN 0 AND 3 THEN '实验组1'
        WHEN CAST(dist_id AS BIGINT) % 10 BETWEEN 4 AND 7 THEN '实验组2'
        ELSE '对照组'
    END AS expflow,
    IF(dist IS NULL, -1, CAST(dist AS INT)) AS distance,
    IF(stat IS NULL OR stat = '', '未知', stat) AS activity_status
FROM (
    SELECT
        time,
        event,
        get_json_string(properties, '$.city') AS county_raw,
        get_json_string(properties, '$.activity_id') AS activity_raw,
        get_json_string(properties, '$.user_id') AS uid,
        get_json_string(properties, '$.platform_type') AS platform_raw,
        get_json_string(properties, '$.$app_version') AS app_ver,
        get_json_string(properties, '$.activity_type') AS act_type,
        get_json_string(properties, '$.distance') AS dist,
        get_json_string(properties, '$.activity_status') AS stat,
        distinct_id AS user_id,
        distinct_id AS dist_id
    FROM ods.ods_sr_traffic_sensor_event_log_realtime
    WHERE time >= '${T} 00:00:00'
      AND time <= '${T} 23:59:59'  -- 【优化1】纯字符串常量, date_add/+INTERVAL内部都转days_add, 分区裁剪器不折叠
      AND event IN ('Homepage_Feed_Activity_Ex',
                    'Homepage_Feed_Activity_Click',
                    'Takeaway_Detailpage_View',
                    'Takeaway_Baomingflow_Button_Click')
      AND distinct_id REGEXP '^[0-9]{1,10}$'
) t
WHERE platform_raw IS NOT NULL
  AND platform_raw <> '';


-- ===========================================================================
-- 统计首页feed流活动曝光和点击
-- 【优化2】保留 distance/activity_status 分组 — 不裂变的原因:
--   曝光和点击是流量侧事件，每条事件天然携带自身的distance/activity_status，
--   按这些维度分组统计曝光量/点击量是正确的聚合，不会导致数据翻倍。
-- 【优化4】数据源改为 tmp_traffic_info
-- ===========================================================================

DROP VIEW IF EXISTS feed_info;

-- OLD: FROM traffic_info
-- NEW: FROM tmp_traffic_info
CREATE VIEW IF NOT EXISTS feed_info (statistics_date,county_id,activity_id,platform_name,app_version,activity_type,expno,expflow,distance,activity_status,expouse_num,expouse_uids,clc_num,clc_uids) AS
  (SELECT date(time) statistics_date,
                     county_id,
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
   FROM tmp_traffic_info
   WHERE event IN ('Homepage_Feed_Activity_Ex',
                   'Homepage_Feed_Activity_Click')
   GROUP BY 1,2,3,4,5,6,7,8,9,10);


-- ===========================================================================
-- 【优化2-核心】用户-活动维度归因视图 (NEW — 解决裂变的关键)
--
-- 问题: 同一个promotion_id曝光给不同人/同一人不同时间点，
--      distance/activity_status都会变化。如果把这两个字段直接加到下游
--      转化视图(detail_view/bm_clc/order_ascribe)的GROUP BY和JOIN中，
--      一个用户的一次转化会被复制到多个(distance,status)组合上，
--      订单数会翻N倍(裂变)。
--
-- 解决: 为每个(user_id, activity_id, date)分配唯一的distance/activity_status，
--      后续所有转化事件都归因到这个唯一值。
--
-- 归因策略: 取当天该用户对该活动 最后一次点击 的距离/状态。
--         如果当天没有点击，则取 最后一次曝光 的距离/状态。
--         点击优先于曝光(点击更能代表用户实际意图和决策场景)。
--
-- 【优化4】数据源改为 tmp_traffic_info
-- ===========================================================================

DROP VIEW IF EXISTS user_activity_distance_attr;

-- OLD: FROM traffic_info
-- NEW: FROM tmp_traffic_info
CREATE VIEW IF NOT EXISTS user_activity_distance_attr (statistics_date,user_id,activity_id,distance,activity_status) AS
  SELECT statistics_date,
         user_id,
         activity_id,
         distance,
         activity_status
  FROM (
    SELECT date(time) AS statistics_date,
           user_id,
           activity_id,
           distance,
           activity_status,
           ROW_NUMBER() OVER (
             PARTITION BY date(time), user_id, activity_id
             ORDER BY time DESC  -- 取当天最后一次事件
           ) AS rn
    FROM tmp_traffic_info
    WHERE event IN ('Homepage_Feed_Activity_Click', 'Homepage_Feed_Activity_Ex')
      AND distance IS NOT NULL
      AND activity_status IS NOT NULL
  ) t
  WHERE rn = 1;


-- ===========================================================================
-- 统计首页feed流活动点击
-- 【优化2】保持无 distance/activity_status — 作为下游锚点表，不携带曝光维度
-- 【优化4】数据源改为 tmp_traffic_info
-- ===========================================================================

DROP VIEW IF EXISTS feed_clc;

-- OLD: FROM traffic_info
-- NEW: FROM tmp_traffic_info
CREATE VIEW IF NOT EXISTS feed_clc (statistics_date,county_id,activity_id,platform_name,app_version,activity_type,user_id,expno,expflow,clc_num) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     activity_id,
                     platform_name,
                     app_version,
                     activity_type,
                     user_id,
                     expno,
                     expflow,
                     count(1) clc_num
   FROM tmp_traffic_info
   WHERE event='Homepage_Feed_Activity_Click'
   GROUP BY 1,2,3,4,5,6,7,8,9);


-- ===========================================================================
-- 统计外卖详情页浏览
-- 【优化2】保持无 distance/activity_status — 转化事件不携带曝光维度
-- 【优化4】数据源改为 tmp_traffic_info
-- ===========================================================================

DROP VIEW IF EXISTS detail_view;

-- OLD: FROM traffic_info
-- NEW: FROM tmp_traffic_info
CREATE VIEW IF NOT EXISTS detail_view (statistics_date,county_id,activity_id,platform_name,app_version,user_id,expno,expflow,pv) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     activity_id,
                     platform_name,
                     app_version,
                     user_id,
                     expno,
                     expflow,
                     count(1) pv
   FROM tmp_traffic_info
   WHERE event='Takeaway_Detailpage_View'
   GROUP BY 1,2,3,4,5,6,7,8);


-- ===========================================================================
-- 报名按钮点击
-- 【优化2】保持无 distance/activity_status
-- 【优化4】数据源改为 tmp_traffic_info
-- ===========================================================================

DROP VIEW IF EXISTS bm_clc;

-- OLD: FROM traffic_info
-- NEW: FROM tmp_traffic_info
CREATE VIEW IF NOT EXISTS bm_clc (statistics_date,county_id,activity_id,platform_name,app_version,user_id,expno,expflow,bm_clc_num) AS
  (SELECT date(time) statistics_date,
                     county_id,
                     activity_id,
                     platform_name,
                     app_version,
                     user_id,
                     expno,
                     expflow,
                     count(1) bm_clc_num
   FROM tmp_traffic_info
   WHERE event='Takeaway_Baomingflow_Button_Click'
   GROUP BY 1,2,3,4,5,6,7,8);


-- ===========================================================================
-- 外卖订单 (不变)
-- ===========================================================================

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


-- ===========================================================================
-- 【优化3】订单归因数据集 — ROW_NUMBER去重
--
-- OLD: count(DISTINCT b.auto_id) — 一个订单可能匹配多条详情浏览，重复计数
-- NEW: ROW_NUMBER + CASE WHEN rn=1 — 每个订单只匹配时间差最小的那条详情浏览
--
-- 原因: 用户在15分钟内可能浏览多次详情页，每次都匹配到同一笔订单，
--      直接count(DISTINCT auto_id) 会因为不同的(a.time, county_id...)
--      组合而无法真正去重。ROW_NUMBER保证每个auto_id只归因一次。
-- ===========================================================================

DROP VIEW IF EXISTS order_ascribe;

-- OLD: FROM traffic_info (inner subquery)
-- NEW: FROM tmp_traffic_info (inner subquery)
CREATE VIEW IF NOT EXISTS order_ascribe (statistics_date,county_id,activity_id,platform_name,app_version,user_id,expno,expflow,baoming_order_num,valid_order_num,profit,xx_baoming_order_num,xx_valid_order_num) AS
  (SELECT date_format(time,'%Y-%m-%d') statistics_date,
          county_id,
          activity_id,
          platform_name,
          app_version,
          user_id,
          expno,
          expflow,
          count(DISTINCT CASE WHEN rn=1 THEN auto_id END) baoming_order_num,  -- 【优化3】只计rn=1
          count(DISTINCT CASE WHEN rn=1 AND order_status IN (2,8) THEN auto_id END) valid_order_num,  -- 【优化3】
          sum(CASE WHEN rn=1 AND order_status=2 THEN profit ELSE 0 END) profit,  -- 【优化3】
          count(DISTINCT CASE WHEN rn=1 AND order_type=15 THEN auto_id END) xx_baoming_order_num,  -- 【优化3】
          count(DISTINCT CASE WHEN rn=1 AND order_status IN (2,8) AND order_type=15 THEN auto_id END) xx_valid_order_num  -- 【优化3】
   FROM
     (SELECT a.time,
             a.county_id,
             a.activity_id,
             a.platform_name,
             a.app_version,
             a.user_id,
             a.expno,
             a.expflow,
             b.auto_id,
             b.order_status,
             b.profit,
             b.order_type,
             -- 【优化3】按(user_id, auto_id)分区，取时间差最小的详情浏览
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
                expflow
         FROM tmp_traffic_info
         WHERE event='Takeaway_Detailpage_View') a
      LEFT JOIN order_info b ON a.user_id=b.user_id
        AND date_diff('minute',b.create_time,a.time) BETWEEN 0 AND 15) t
   GROUP BY 1,2,3,4,5,6,7,8);


-- ===========================================================================
-- 【优化2-核心】聚合非首页流量数据 — 通过归因视图引入distance/activity_status
--
-- 核心变化:
--   1. 新增 LEFT JOIN user_activity_distance_attr attr
--      为每个点击用户赋予唯一的(distance, activity_status)
--   2. 下游JOIN(detail_view/bm_clc/order_ascribe)不匹配distance/activity_status
--      因转化事件不携带这些字段，且归因后无需匹配
--   3. GROUP BY 增加 distance, activity_status (来自归因视图，唯一值)
-- ===========================================================================

DROP VIEW IF EXISTS agg_funnel;

CREATE VIEW IF NOT EXISTS agg_funnel (statistics_date,county_id,activity_id,platform_name,app_version,expno,expflow,activity_type,distance,activity_status,view_uids,pv,bm_uids,bm_clc_num,order_uids,bm_order_num,valid_order_uids,valid_order_num,profit,xx_bm_order_uids,xx_bm_order_num,xx_valid_order_uids,xx_valid_order_num) AS
  (SELECT a.statistics_date,
          a.county_id,
          a.activity_id,
          a.platform_name,
          a.app_version,
          a.expno,
          a.expflow,
          a.activity_type,
          attr.distance,            -- 【优化2】从归因视图获取，每个(user,activity)唯一
          attr.activity_status,     -- 【优化2】从归因视图获取，不会裂变
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
   -- 【优化2-关键】关联归因视图: 每个(user,activity)→唯一(distance, activity_status)
   LEFT JOIN user_activity_distance_attr attr
     ON a.statistics_date = attr.statistics_date
     AND a.user_id = attr.user_id
     AND a.activity_id = attr.activity_id
   -- 下游JOIN: 不匹配distance/activity_status（转化事件不携带曝光维度）
   LEFT JOIN detail_view b ON a.statistics_date=b.statistics_date
     AND a.county_id=b.county_id
     AND a.activity_id=b.activity_id
     AND a.platform_name=b.platform_name
     AND a.app_version=b.app_version
     AND a.user_id=b.user_id
   LEFT JOIN bm_clc c ON c.statistics_date=b.statistics_date
     AND c.county_id=b.county_id
     AND c.activity_id=b.activity_id
     AND c.platform_name=b.platform_name
     AND c.app_version=b.app_version
     AND c.user_id=b.user_id
   LEFT JOIN order_ascribe d ON c.statistics_date=d.statistics_date
     AND c.county_id=d.county_id
     AND c.activity_id=d.activity_id
     AND c.platform_name=d.platform_name
     AND c.app_version=d.app_version
     AND c.user_id=d.user_id
   GROUP BY 1,2,3,4,5,6,7,8,9,10);


-- ===========================================================================
-- 最终写入
--
-- 【优化2】变化:
--   OLD: 0 as distance, '未知' as activity_status (硬编码占位值)
--   NEW: a.distance, a.activity_status (来自feed_info的真实曝光维度数据)
--   JOIN条件: 增加 AND a.distance=b.distance AND a.activity_status=b.activity_status
--   原因: feed_info(曝光按距离/状态分组) × agg_funnel(转化按归因分组) → 完整漏斗
-- ===========================================================================

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
   AND a.activity_status=b.activity_status;
