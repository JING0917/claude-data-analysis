drop table if exists ads.ads_sr_traffic_dau_d;

CREATE TABLE  if not exists ads.ads_sr_traffic_dau_d(
    `statistics_date`  DATE  NOT NULL COMMENT '统计日期',
    `cate2_index` varchar(30) NOT NULL COMMENT '二级指标',
    `sub_cate2_index` varchar(30) NOT NULL COMMENT '次二级指标',
    `sub_cate2_index_value` decimal(12,5) NOT NULL COMMENT '次二级指标值'
) ENGINE=OLAP
PRIMARY KEY (statistics_date,cate2_index,sub_cate2_index)
COMMENT "分日DAU构成"
DISTRIBUTED BY HASH(statistics_date)
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "replicated_storage" = "true",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);



-- 近31天每日访问登录用户
WITH t1 AS
  (SELECT date_format(dt,'%Y-%m-%d') AS dt,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt BETWEEN date_sub(current_date(),interval 31 DAY) AND date_sub(current_date(),interval 1 DAY)
   GROUP BY 1,
            2),


-- 访问天数区间用户转化率
t2 AS (
SELECT date_format(date_sub(current_date(),interval 1 DAY),'%Y-%m-%d') AS dt,
       days6_user_num,
       days12_user_num,
       days18_user_num,
       days30_user_num,
       mau,
       days6_user_num/mau days6_rate,
       days12_user_num/days6_user_num days12_rate,
       days18_user_num/days12_user_num days18_rate,
       days30_user_num/days18_user_num days30_rate
FROM
  (SELECT count(DISTINCT if(view_days BETWEEN 7 AND 30,user_id,NULL)) days6_user_num,
          count(DISTINCT if(view_days BETWEEN 13 AND 30,user_id,NULL)) days12_user_num,
          count(DISTINCT if(view_days BETWEEN 19 AND 30,user_id,NULL)) days18_user_num,
          count(DISTINCT if(view_days BETWEEN 25 AND 30,user_id,NULL)) days30_user_num
   FROM
     (SELECT user_id,
             count(1) view_days
      FROM t1
      WHERE dt<>date_sub(current_date(),interval 1 DAY)
      GROUP BY 1) a1) a
LEFT JOIN
  (SELECT count(DISTINCT user_id) mau
   FROM t1
   WHERE dt<>date_sub(current_date(),interval 1 DAY)) b ON 1=1),



-- 昨日访问用户中，用户近30天访问天数下（不含昨日）访问率
t3 AS
  (SELECT dt,
          ifnull(user_type,'沉默用户召回量') user_type,
                                      lastday_dau,
                                      mau,
                                      lastday_dau/mau AS view_rate
   FROM
     (SELECT a.dt,
             b.user_type,
             count(DISTINCT a.user_id) lastday_dau
      FROM
        (SELECT dt,
                a1.user_id
         FROM
           (SELECT dt,
                   user_id
            FROM t1
            WHERE dt=date_sub(current_date(),interval 1 DAY)) a1
         LEFT JOIN
           (SELECT user_id
            FROM dim.dim_silkworm_user
            WHERE date_format(register_time,'%Y-%m-%d')=date_sub(current_date(),interval 1 DAY)) a2 ON a1.user_id=a2.user_id
         WHERE a2.user_id IS NULL) a
      LEFT JOIN
        (SELECT b1.user_id,
                CASE WHEN view_days BETWEEN 1 AND 6 THEN '近30天访问1-6天' 
                    WHEN view_days BETWEEN 7 AND 12 THEN '近30天访问7-12天' 
                    WHEN view_days BETWEEN 13 AND 18 THEN '近30天访问13-18天' 
                    WHEN view_days BETWEEN 19 AND 24 THEN '近30天访问19-24天' 
                    WHEN view_days BETWEEN 25 AND 30 THEN '近30天访问25-30天' 
                END AS user_type
         FROM
           (SELECT user_id,
                   count(1) view_days
            FROM t1
            WHERE dt<>date_sub(current_date(),interval 1 DAY)
            GROUP BY 1) b1) b ON a.user_id =b.user_id
      GROUP BY 1,
               2) c
   LEFT JOIN
     (SELECT count(DISTINCT user_id) mau
      FROM t1
      WHERE dt<>date_sub(current_date(),interval 1 DAY)) d ON 1=1),



-- 用户注册当日完单转化+7日留存
t4 AS
  (SELECT c.register_date,
          c.register_usernum,
          c.valid_order_usernum,
          d.acc_7d_retention_num
   FROM
     (SELECT a.register_date,
             count(DISTINCT a.user_id) register_usernum,
                                       count(DISTINCT if(b.user_id IS NOT NULL,a.user_id,NULL)) valid_order_usernum
      FROM
        (SELECT user_id,
                date_format(register_time,'%Y-%m-%d') AS register_date
         FROM dim.dim_silkworm_user
         WHERE date_format(register_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 9 DAY) AND date_sub(current_date(),interval 1 DAY)) a
      LEFT JOIN
        (SELECT date_format(order_time,'%Y-%m-%d') AS order_date,
                user_id
         FROM dwd.dwd_sr_order_promotion_order
         WHERE date_format(order_time,'%Y-%m-%d') BETWEEN date_sub(current_date(),interval 9 DAY) AND date_sub(current_date(),interval 1 DAY)
           AND order_status IN (2,
                                8)
         GROUP BY 1,
                  2) b ON a.register_date=b.order_date
      AND a.user_id = b.user_id
GROUP BY 1) c
   LEFT JOIN
     (SELECT statistic_date,
             acc_7d_retention_num
      FROM dws.dws_sr_user_newuser_retention_d
      WHERE statistic_date BETWEEN date_sub(current_date(),interval 9 DAY) AND date_sub(current_date(),interval 1 DAY)
        AND city_name='全国'
        AND latest_login_platform='全部') d ON c.register_date=d.statistic_date),

-- 注册用户量和4单用户占比
t5 AS
  (SELECT dt,
          register_user_num,
          acc_signup_user_num,
          acc_above4ord_user_num
   FROM ads.ads_sr_user_signup_usernum_d
   WHERE dt BETWEEN date_sub(current_date(),interval 9 DAY) AND date_sub(current_date(),interval 1 DAY)),


-- 访问天数区间用户转化率
t6 AS
  (SELECT dt,
          '活跃用户转化率' cate2_index,
                    '近30天访问1-6天' sub_cate2_index,
                                 days6_rate sub_cate2_index_value
   FROM t2
   UNION ALL SELECT dt,
                    '活跃用户转化率' cate2_index,
                              '近30天访问7-12天' sub_cate2_index,
                                            days12_rate sub_cate2_index_value
   FROM t2
   UNION ALL SELECT dt,
                    '活跃用户转化率' cate2_index,
                              '近30天访问13-18天' sub_cate2_index,
                                             days18_rate sub_cate2_index_value
   FROM t2
   UNION ALL SELECT dt,
                    '活跃用户转化率' cate2_index,
                              '近30天访问19-24天' sub_cate2_index,
                                             days30_rate sub_cate2_index_value
   FROM t2)


SELECT dt,
       '注册用户量' AS cate2_index,
       '注册用户量' AS sub_cate2_index,
       register_user_num sub_cate2_index_value
FROM t5
UNION ALL
SELECT dt,
       '4单转化率' AS cate2_index,
       '4单转化率' AS sub_cate2_index,
       acc_above4ord_user_num/acc_signup_user_num sub_cate2_index_value
FROM t5
UNION ALL
SELECT register_date dt,
       '注册当日首单转化率' AS cate2_index,
       '注册当日首单转化率' AS sub_cate2_index,
       valid_order_usernum/register_usernum sub_cate2_index_value
FROM t4
UNION ALL
SELECT register_date dt,
       '注册用户次7日留存率' AS cate2_index,
       '注册用户次7日留存率' AS sub_cate2_index,
       acc_7d_retention_num/register_usernum sub_cate2_index_value
FROM t4
UNION ALL
SELECT dt,
       cate2_index,
       sub_cate2_index,
       sub_cate2_index_value
FROM t6
UNION ALL
SELECT dt,
       '活跃用户访问率' cate2_index,
                 user_type sub_cate2_index,
                 view_rate sub_cate2_index_value
FROM t3
WHERE user_type<>'沉默用户召回量'
UNION ALL
SELECT dt,
       '沉默用户召回量' cate2_index,
                 user_type sub_cate2_index,
                 lastday_dau sub_cate2_index_value
FROM t3
WHERE user_type='沉默用户召回量' ;









