
-- DROP TABLE IF EXISTS dwd.dwd_sr_traffic_instore_newuser_rp_d;


CREATE TABLE IF NOT EXISTS dwd.dwd_sr_traffic_instore_newuser_rp_d (
    user_id varchar(65533) comment '用户ID',
    view_date date not null comment '访问日期',
    business_name varchar(50) not null comment '业务线',
    event_name varchar(500) comment '事件名称'
) ENGINE=OLAP
DUPLICATE KEY(user_id)
COMMENT '到店新人红包流量明细'
PARTITION BY date_trunc('day',view_date)
DISTRIBUTED BY HASH(user_id)
PROPERTIES (
    "replication_num" = "1",
    "in_memory" = "false",
    "compression" = "LZ4",
    "bloom_filter_columns" = "business_name,event_name"
);

insert into dwd.dwd_sr_traffic_instore_newuser_rp_d
-- 到店新人红包页访问&领取红包点击
SELECT user_id,
       dt,
       if(canal_id='06051','砍价','探店') business_name,
       event_name
FROM
  (SELECT dt,
          event_name,
          get_json_string(DATA,'$.canal_id') AS canal_id,
          user_id
   FROM ods.ods_sr_event_log
   WHERE dt='${T-1}'
     AND event_name IN ('Instore_Minipprogram_Landingpage_View',
                        'Instore_Minipprogram_Landingpage_Click')
   GROUP BY 1,
            2,
            3,
            4) a
WHERE canal_id IN ('06051',
                   '0611')
GROUP BY 1,
         2,
         3,
         4
;





-- DROP TABLE IF EXISTS dws.dws_sr_market_instore_newuser_rp_d;


CREATE TABLE IF NOT EXISTS dws.dws_sr_market_instore_newuser_rp_d (
    business_name VARCHAR(25) NOT NULL COMMENT "业务线",
    statistics_date date NOT NULL COMMENT "统计日期",
    newuser_rpage_uv int COMMENT "新人红包页UV",
    newuser_rpage_clc_uv int COMMENT "新人红包点击UV",
    get_newuser_rp_unum int COMMENT "新人红包领取用户量",
    newuser_rp_pay_unum int COMMENT "新人红包支付(剔除退款)用户量",
    newuser_rp_verify_unum int COMMENT "新人红包核销/完单用户量"
) ENGINE=OLAP
DUPLICATE KEY(business_name)
COMMENT "到店新人红包日统计"
PARTITION BY date_trunc('day',statistics_date)
DISTRIBUTED BY HASH(business_name)
PROPERTIES (
    "replication_num" = "1",
    "in_memory" = "false",
    "compression" = "LZ4"
);


insert into dws.dws_sr_market_instore_newuser_rp_d


SELECT
  business_name,
  statistics_date,
  sum(newuser_rpage_uv) newuser_rpage_uv,
  sum(newuser_rpage_clc_uv) newuser_rpage_clc_uv,
  sum(get_newuser_rp_unum) get_newuser_rp_unum,
  sum(newuser_rp_pay_unum) newuser_rp_pay_unum,
  sum(newuser_rp_verify_unum) newuser_rp_verify_unum
FROM (
-- 到店新人红包页访问
SELECT view_date AS statistics_date,
       business_name,
       count(DISTINCT user_id) newuser_rpage_uv,
       0 newuser_rpage_clc_uv,
       0 get_newuser_rp_unum,
       0 newuser_rp_pay_unum,
       0 newuser_rp_verify_unum
FROM dwd.dwd_sr_traffic_instore_newuser_rp_d
WHERE view_date BETWEEN '2025-06-06' AND '${T-1}'
  AND event_name='Instore_Minipprogram_Landingpage_View'
GROUP BY 1,
         2

union all

-- 砍价新人红包领取和使用
SELECT a.statistics_date,
       '砍价' business_name,
       0,
       count(DISTINCT a.user_id) newuser_rpage_clc_uv,
       count(DISTINCT if(b.user_id IS NOT NULL,a.user_id,NULL)) get_newuser_rp_unum,
       count(DISTINCT if(b.pay_ordernum>0,a.user_id,NULL)) newuser_rp_pay_unum,
       count(DISTINCT if(b.verify_ordernum>0,a.user_id,NULL)) newuser_rp_verify_unum
FROM
-- 砍价新人红包领取点击用户
     (SELECT view_date as statistics_date,
             user_id
      FROM dwd.dwd_sr_traffic_instore_newuser_rp_d
      WHERE view_date BETWEEN '2025-06-06' AND '${T-1}'
        AND event_name='Instore_Minipprogram_Landingpage_Click'
        and business_name='砍价'
      GROUP BY 1,
               2) a
LEFT JOIN
-- 砍价新人红包领取使用
  (SELECT user_id,
          count(if(b2.auto_id is not null,b1.auto_ordere_id,null)) pay_ordernum,
          count(if(b2.status=5,auto_ordere_id,NULL)) verify_ordernum
   FROM
     (SELECT auto_ordere_id,
             user_id
      FROM dwd.dwd_sr_market_redpack_use_record
      WHERE dt BETWEEN '2025-06-06' AND '${T-1}'
        AND redpacket_id=398) b1
   left JOIN
     (SELECT auto_id,
             status
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN '2025-06-06' AND '${T-1}'
        AND promotion_type IN (5,
                               6,
                               8)
        AND status IN (3,
                       5,
                       36)) b2 ON b1.auto_ordere_id=b2.auto_id
    group by 1) b ON a.user_id=b.user_id
GROUP BY 1,2

union all

-- 探店新人红包领取和使用
SELECT a.statistics_date,
       '探店' business_name,
       0,
       count(DISTINCT a.user_id) newuser_rpage_clc_uv,
       count(DISTINCT if(b.user_id IS NOT NULL,a.user_id,NULL)) get_newuser_rp_unum,
       count(DISTINCT if(b.payord_num>0,a.user_id,NULL)) newuser_rp_pay_unum,
       count(DISTINCT if(b.finord_num>0,a.user_id,NULL)) newuser_rp_verify_unum
FROM
-- 探店新人红包领取点击用户
  (SELECT view_date as statistics_date,
             user_id
      FROM dwd.dwd_sr_traffic_instore_newuser_rp_d
      WHERE view_date BETWEEN '2025-06-11' AND '${T-1}'
        AND event_name='Instore_Minipprogram_Landingpage_Click'
        and business_name='探店'
      GROUP BY 1,
               2) a
LEFT JOIN
-- 探店新人红包领取使用
  (SELECT user_id,
          count(if(b2.auto_id is not null and b2.status not in (1,2,6,7,8,9,10,21),b1.auto_ordere_id,null)) payord_num,
          count(if(b2.status in (5,19,20,35),auto_ordere_id,NULL)) finord_num
   FROM
     (SELECT auto_ordere_id,
             user_id
      FROM dwd.dwd_sr_market_redpack_use_record
      WHERE dt BETWEEN '2025-06-11' AND '${T-1}'
        AND redpacket_id=399) b1
   left JOIN
     (SELECT auto_id,
             status
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN '2025-06-11' AND '${T-1}'
        AND promotion_type IN (1,
                               4)
    ) b2 ON b1.auto_ordere_id=b2.auto_id
    group by 1) b ON a.user_id=b.user_id
GROUP BY 1,2) toa

GROUP BY 1,
         2;


