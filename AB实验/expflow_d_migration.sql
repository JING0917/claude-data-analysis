-- =============================================
-- 在线迁移: 为主表扩展PRIMARY KEY
-- 目标: PRIMARY KEY添加 distance, activity_status
-- 方式: 建新表 → INSERT SELECT → RENAME切换
-- 说明: 全程不删除原表, 切换在秒级完成
-- 作者: dahe
-- 日期: 2026-04-27
-- =============================================

-- Step 1: 创建新表（PRIMARY KEY包含distance, activity_status）
CREATE TABLE IF NOT EXISTS dws.dws_sr_traffic_homepage_mix_expflow_d_v2 (
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
COMMENT "首页融合归因实验日数据_v2"
DISTRIBUTED BY HASH(statistics_date,county_id,promotion_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);


-- Step 2: 迁移数据（从旧表写入新表）
-- 如果原表已经有distance/activity_status列（通过之前的ALTER TABLE加的）
INSERT INTO dws.dws_sr_traffic_homepage_mix_expflow_d_v2
SELECT * FROM dws.dws_sr_traffic_homepage_mix_expflow_d;


-- Step 3: 表名切换（原子操作, 秒级完成）
ALTER TABLE dws.dws_sr_traffic_homepage_mix_expflow_d RENAME dws.dws_sr_traffic_homepage_mix_expflow_d_bak_20260427;
ALTER TABLE dws.dws_sr_traffic_homepage_mix_expflow_d_v2 RENAME dws.dws_sr_traffic_homepage_mix_expflow_d;


-- Step 4: 验证数据完整性
-- SELECT count(1) FROM dws.dws_sr_traffic_homepage_mix_expflow_d;
-- SELECT count(1) FROM dws.dws_sr_traffic_homepage_mix_expflow_d_bak_20260427;


-- Step 5: 确认无误后删除备份表
-- DROP TABLE IF EXISTS dws.dws_sr_traffic_homepage_mix_expflow_d_bak_20260427;
