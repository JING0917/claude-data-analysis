DROP TABLE IF EXISTS dwd.dwd_sr_silkworm_rcs_meituan_shangjin_store_snapshot;

CREATE TABLE IF NOT EXISTS dwd.dwd_sr_silkworm_rcs_meituan_shangjin_store_snapshot (
    dt DATE NOT NULL COMMENT '日期分区',
    auto_id BIGINT NOT NULL COMMENT '自增ID',
    created_at DATETIME COMMENT '创建时间',
    updated_at DATETIME COMMENT '更新时间',
    wm_poi_id VARCHAR(64) COMMENT '外卖POI位置ID',
    name VARCHAR(64) COMMENT '店铺名称',
    city_code INT COMMENT '区县ID',
    icon_union_id VARCHAR(64) COMMENT 'ICON联合ID',
    poi_id VARCHAR(64) COMMENT 'POI位置ID',
    poi_id_str VARCHAR(64) COMMENT 'POI位置ID加密',
    picture VARCHAR(256) COMMENT '店铺图片地址',
    wx_appid VARCHAR(64) COMMENT '微信AppID',
    wx_app_orgid VARCHAR(64) COMMENT '原始微信AppID',
    wx_path VARCHAR(65533) COMMENT '微信页面路由',
    wm_poi_score VARCHAR(64) COMMENT '商家评分',
    min_price_tip VARCHAR(64) COMMENT '起送价格',
    category VARCHAR(64) COMMENT '品类',
    ratio INT COMMENT '佣金比例(例如:500 表示 500/10000=5%)',
    max_commission INT COMMENT '最大佣金金额(分)',
    activity_num INT COMMENT '活动数',
    last_record_day_time DATETIME COMMENT '最近一次记录时间',
    ms_get_type INT COMMENT '类型',
    total_inventory INT COMMENT '总库存',
    inventory INT COMMENT '可用库存',
    consumption_radio INT COMMENT '销单率'
) ENGINE = OLAP
PRIMARY KEY (dt, auto_id)
COMMENT "美团赏金店铺快照表"
DISTRIBUTED BY HASH (auto_id) BUCKETS 32
PROPERTIES (
    "compression" = "LZ4",
    "replication_num" = "3"
);


-- ============================================================
-- DWD 快照 INSERT（每日调度）
-- ============================================================
INSERT INTO dwd.dwd_sr_silkworm_rcs_meituan_shangjin_store_snapshot
SELECT
    '${T-1}' AS dt,
    auto_id,
    created_at,
    updated_at,
    wm_poi_id,
    name,
    city_code,
    icon_union_id,
    poi_id,
    poi_id_str,
    picture,
    wx_appid,
    wx_app_orgid,
    wx_path,
    wm_poi_score,
    min_price_tip,
    category,
    ratio,
    max_commission,
    activity_num,
    last_record_day_time,
    ms_get_type,
    total_inventory,
    inventory,
    consumption_radio
FROM dwd.dwd_sr_silkworm_rcs_meituan_shangjin_store
WHERE date(last_record_day_time) = '${T-1}';
