-- 整体数据
SELECT search_date `统计日期`,
       '整体' `平台名称`,
       `搜索量`,
       `搜索用户量`,
       `搜索曝光量`,
       `搜索曝光用户量`,
       `搜索点击量`,
       `搜索点击用户量`,
       `搜索报名订单量`,
       `搜索报名用户量`,
       `搜索有效订单量`,
       `搜索有效订单用户量`,
       `搜索有效订单利润`,
       `无搜索结果搜索量`,
       `无搜索结果搜索用户量`,
       `无搜索结果点击搜索量`,
       `无搜索结果点击搜索用户量`,
       dau `DAU`
FROM
  (SELECT search_date,
          sum(search_num) `搜索量`,
          count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
          sum(search_expose_num) `搜索曝光量`,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
          sum(search_result_click_num) `搜索点击量`,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
          sum(takeaway_baoming_order_num) `搜索报名订单量`,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
          sum(takeaway_valid_order_num) `搜索有效订单量`,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
          sum(takeaway_profit) `搜索有效订单利润`,
          sum(if(search_num>0
                 AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`,
          sum(if(search_num>0
                 AND search_expose_num>0
                 AND search_result_click_num=0,search_num,0)) `无搜索结果点击搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num>0
                            AND search_result_click_num=0,user_id,0)) `无搜索结果点击搜索用户量`
   FROM
     (SELECT search_date,
             user_id,
             keywords,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num,
             sum(takeaway_profit) takeaway_profit
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '2025-11-26' AND '2025-12-02'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3 ) a1
   GROUP BY 1) a
LEFT JOIN
  (SELECT dt,
          bitmap_union_count(user_ids) AS dau
   FROM dwd.dwd_sr_traffic_viewuser_d
   WHERE dt BETWEEN '2025-11-26' AND '2025-12-02'
   GROUP BY 1) b ON a.search_date=b.dt

union all

SELECT search_date `统计日期`,
       a.platform_name `平台名称`,
       `搜索量`,
       `搜索用户量`,
       `搜索曝光量`,
       `搜索曝光用户量`,
       `搜索点击量`,
       `搜索点击用户量`,
       `搜索报名订单量`,
       `搜索报名用户量`,
       `搜索有效订单量`,
       `搜索有效订单用户量`,
       `搜索有效订单利润`,
       `无搜索结果搜索量`,
       `无搜索结果搜索用户量`,
       `无搜索结果点击搜索量`,
       `无搜索结果点击搜索用户量`,
       dau `DAU`
FROM
  (SELECT search_date,
          platform_name,
          sum(search_num) `搜索量`,
          count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
          sum(search_expose_num) `搜索曝光量`,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
          sum(search_result_click_num) `搜索点击量`,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
          sum(takeaway_baoming_order_num) `搜索报名订单量`,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
          sum(takeaway_valid_order_num) `搜索有效订单量`,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
          sum(takeaway_profit) `搜索有效订单利润`,
          sum(if(search_num>0
                 AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`,
          sum(if(search_num>0
                 AND search_expose_num>0
                 AND search_result_click_num=0,search_num,0)) `无搜索结果点击搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num>0
                            AND search_result_click_num=0,user_id,0)) `无搜索结果点击搜索用户量`
   FROM
     (SELECT search_date,
             platform_name,
             user_id,
             keywords,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num,
             sum(takeaway_profit) takeaway_profit
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '2025-11-26' AND '2025-12-02'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3,
               4 ) a1
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT dt,
          platform_name,
          bitmap_union_count(user_ids) AS dau
   FROM dwd.dwd_sr_traffic_viewuser_d
   WHERE dt BETWEEN '2025-11-26' AND '2025-12-02'
   GROUP BY 1,
            2) b ON a.search_date=b.dt
AND a.platform_name=b.platform_name;


-- 新老用户
SELECT search_date `统计日期`,
       user_type `用户类型`,
       `搜索量`,
       `搜索用户量`,
       `搜索曝光量`,
       `搜索曝光用户量`,
       `搜索点击量`,
       `搜索点击用户量`,
       `搜索报名订单量`,
       `搜索报名用户量`,
       `搜索有效订单量`,
       `搜索有效订单用户量`,
       `搜索有效订单利润`,
       `无搜索结果搜索量`,
       `无搜索结果搜索用户量`,
       `无搜索结果点击搜索量`,
       `无搜索结果点击搜索用户量`,
       dau `DAU`
FROM
  (SELECT search_date,
          if(a2.user_id IS NOT NULL,'新用户','老用户') user_type,
          sum(search_num) `搜索量`,
          count(DISTINCT if(search_num>0,user_id,NULL)) `搜索用户量`,
          sum(search_expose_num) `搜索曝光量`,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) `搜索曝光用户量`,
          sum(search_result_click_num) `搜索点击量`,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) `搜索点击用户量`,
          sum(takeaway_baoming_order_num) `搜索报名订单量`,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) `搜索报名用户量`,
          sum(takeaway_valid_order_num) `搜索有效订单量`,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) `搜索有效订单用户量`,
          sum(takeaway_profit) `搜索有效订单利润`,
          sum(if(search_num>0
                 AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`,
          sum(if(search_num>0
                 AND search_expose_num>0
                 AND search_result_click_num=0,search_num,0)) `无搜索结果点击搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num>0
                            AND search_result_click_num=0,user_id,0)) `无搜索结果点击搜索用户量`
   FROM
     (SELECT search_date,
             user_id,
             keywords,
             activity_id,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num,
             sum(takeaway_profit) takeaway_profit
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '2025-11-26' AND '2025-12-02'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a1
   LEFT JOIN
     (SELECT user_id,
             date_format(register_time,'%Y-%m-%d') register_date
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-11-26' AND '2025-12-02') a2 ON a1.user_id=a2.user_id
   AND a1.search_date=a2.register_date
   GROUP BY 1,
            2) a
LEFT JOIN
  (SELECT dt,
          bitmap_union_count(user_ids) AS dau
   FROM dwd.dwd_sr_traffic_viewuser_d
   WHERE dt BETWEEN '2025-11-26' AND '2025-12-02'
   GROUP BY 1) b ON a.search_date=b.dt;


-- 分位置

WITH t AS
  (SELECT search_date,
       cast(location AS int) location,
                             sum(search_num) search_num,
                             sum(search_expose_num) search_expose_num,
                             sum(if(search_expose_num>0,search_result_click_num,0)) search_result_click_num,
                             sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) takeaway_baoming_order_num,
                             sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) takeaway_valid_order_num,
                             sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) takeaway_profit,
                             sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) takeaway_redpacket_amt,
                             bitmap_agg(if(search_num>0,user_id,NULL)) search_uids,
                             bitmap_agg(if(search_expose_num>0,user_id,NULL)) search_ex_uids,
                             bitmap_agg(if(search_result_click_num>0,user_id,NULL)) search_clc_uids,
                             bitmap_agg(if(takeaway_baoming_order_num>0,user_id,NULL)) search_bm_uids,
                             bitmap_agg(if(takeaway_valid_order_num>0,user_id,NULL)) search_valid_uids
FROM dws.dws_sr_traffic_search_user_d
WHERE search_date BETWEEN '2025-11-26' AND '2025-12-02'
  AND entrance_name='首页'
GROUP BY 1,
         2),


tot AS
  (SELECT search_date,
          CASE
              WHEN LOCATION=1 THEN '1'
              WHEN LOCATION=2 THEN '2'
              WHEN LOCATION=3 THEN '3'
              WHEN LOCATION=4 THEN '4'
              WHEN LOCATION=5 THEN '5'
              WHEN LOCATION=6 THEN '6'
              WHEN LOCATION=7 THEN '7'
              WHEN LOCATION=8 THEN '8'
              WHEN LOCATION=9 THEN '9'
              WHEN LOCATION=10 THEN '10'
              WHEN LOCATION BETWEEN 11 AND 15 THEN '11-15'
              WHEN LOCATION BETWEEN 16 AND 20 THEN '16-20'
              WHEN LOCATION BETWEEN 21 AND 30 THEN '21-30'
              WHEN LOCATION BETWEEN 31 AND 40 THEN '31-40'
              WHEN LOCATION BETWEEN 41 AND 50 THEN '41-50'
              WHEN LOCATION>=51 THEN '51级以上'
              ELSE '其他'
          END AS LOCATION,
          sum(search_num) `搜索量`,
                          sum(search_expose_num) `搜索曝光量`,
                          sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
                          sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
                          sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
                          sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
                          bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
                          bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
                          bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
                          bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
                          bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
   FROM t
   GROUP BY 1,
            2)

SELECT location,
       avg(`搜索曝光量`) `搜索曝光量`,
       avg(`搜索结果点击量`) `搜索结果点击量`,
       avg(`外卖报名订单量`) `搜索报名订单量`,
       avg(`外卖有效订单量`) `搜索有效订单量`,
       avg(`搜索曝光用户量`) `搜索曝光用户量`,
       avg(`搜索结果点击用户量`) `搜索结果点击用户量`,
       avg(`外卖报名用户量`) `搜索报名用户量`,
       avg(`外卖有效用户量`) `搜索有效用户量`
FROM tot
GROUP BY 1;









tot as (SELECT search_date,
       '整体' location,
            sum(search_num) `搜索量`,
            sum(search_expose_num) `搜索曝光量`,
            sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
            sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
            sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
            sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
            sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
            bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
            bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
            bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
            bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
            bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
GROUP BY 1,
     2
UNION ALL
SELECT search_date,
       'top1' location,
              sum(search_num) `搜索量`,
              sum(search_expose_num) `搜索曝光量`,
              sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
              sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
              sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
              sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
              sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
              bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
              bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
              bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
              bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
              bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
WHERE location=1
GROUP BY 1,
         2
UNION ALL
SELECT search_date,
       'top3' location,
              sum(search_num) `搜索量`,
              sum(search_expose_num) `搜索曝光量`,
              sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
              sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
              sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
              sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
              sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
              bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
              bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
              bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
              bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
              bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
WHERE location BETWEEN 1 AND 3
GROUP BY 1,
         2
UNION ALL
SELECT search_date,
       'top10' location,
               sum(search_num) `搜索量`,
               sum(search_expose_num) `搜索曝光量`,
               sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
               sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
               sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
               sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
               sum(if(takeaway_valid_order_num>0,takeaway_redpacket_amt,0)) `外卖使用红包金额`,
               bitmap_union_count(if(search_num>0,search_uids,NULL)) `搜索用户量`,
               bitmap_union_count(if(search_expose_num>0,search_ex_uids,NULL)) `搜索曝光用户量`,
               bitmap_union_count(if(search_result_click_num>0,search_clc_uids,NULL)) `搜索结果点击用户量`,
               bitmap_union_count(if(takeaway_baoming_order_num>0,search_bm_uids,NULL)) `外卖报名用户量`,
               bitmap_union_count(if(takeaway_valid_order_num>0,search_valid_uids,NULL)) `外卖有效用户量`
FROM t
WHERE location BETWEEN 1 AND 10
GROUP BY 1,
         2) 



SELECT location,
       avg(`搜索量`) `搜索量`,
       avg(`搜索曝光量`) `搜索曝光量`,
       avg(`搜索结果点击量`) `搜索结果点击量`,
       avg(`外卖报名订单量`) `搜索报名订单量`,
       avg(`外卖有效订单量`) `搜索有效订单量`,
       avg(`外卖有效订单利润`) `搜索有效订单利润`,
       avg(`外卖使用红包金额`) `搜索使用红包金额`,
       avg(`搜索用户量`) `搜索用户量`,
       avg(`搜索曝光用户量`) `搜索曝光用户量`,
       avg(`搜索结果点击用户量`) `搜索结果点击用户量`,
       avg(`外卖报名用户量`) `搜索报名用户量`,
       avg(`外卖有效用户量`) `搜索有效用户量`
FROM tot
GROUP BY 1;


-- 新注册用户搜索后访问留存
WITH t1 AS
  (SELECT search_date,
          a1.user_id
   FROM
     (SELECT search_date,
             user_id,
             keywords,
             sum(search_num) search_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '2025-11-01' AND '2025-11-30'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a1
   LEFT JOIN
     (SELECT user_id,
             date_format(register_time,'%Y-%m-%d') register_date
      FROM dim.dim_silkworm_user
      WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-11-01' AND '2025-11-30') a2 ON a1.user_id=a2.user_id
   AND a1.search_date=a2.register_date
   WHERE a1.search_num>0
     AND a2.user_id IS NOT NULL
   GROUP BY 1,
            2),

-- 访问
t2 AS
  (SELECT dt,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt BETWEEN '2025-11-01' AND '2025-12-04'
   GROUP BY 1,
            2)


SELECT search_date `统计日期`,
       count(DISTINCT t1.user_id) `搜索新用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.search_date)=1,t1.user_id,NULL)) `次日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.search_date)=7,t1.user_id,NULL)) `7日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.search_date)=14,t1.user_id,NULL)) `14日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.search_date)=30,t1.user_id,NULL)) `30日留存用户量`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
GROUP BY 1;


-- 注册用户整体留存
WITH t1 AS
  (SELECT user_id,
          date_format(register_time,'%Y-%m-%d') register_date
   FROM dim.dim_silkworm_user
   WHERE date_format(register_time,'%Y-%m-%d') BETWEEN '2025-11-01' AND '2025-11-30'),

-- 访问
t2 AS
  (SELECT dt,
          unnest_bitmap AS user_id
   FROM dwd.dwd_sr_traffic_viewuser_d,
        unnest_bitmap(user_ids) AS uid
   WHERE dt BETWEEN '2025-11-01' AND '2025-12-04'
   GROUP BY 1,
            2)


SELECT register_date `统计日期`,
       count(DISTINCT t1.user_id) `注册用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.register_date)=1,t1.user_id,NULL)) `次日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.register_date)=7,t1.user_id,NULL)) `7日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.register_date)=14,t1.user_id,NULL)) `14日留存用户量`,
       count(DISTINCT if(date_diff('day',t2.dt,t1.register_date)=30,t1.user_id,NULL)) `30日留存用户量`
FROM t1
LEFT JOIN t2 ON t1.user_id=t2.user_id
GROUP BY 1;




CREATE TABLE `dim_silkworm_wework_account_realtime` (
  `id` bigint(20) NOT NULL COMMENT "自增主键",
  `created_at` datetime NULL COMMENT "创建时间",
  `updated_at` datetime NULL COMMENT "更新时间",
  `vid` bigint(20) NULL COMMENT "vid",
  `corp_id` bigint(20) NULL COMMENT "corp_id",
  `acctid` varchar(64) NULL COMMENT "acctid",
  `name` varchar(128) NULL COMMENT "名称",
  `avatar_url` varchar(256) NULL COMMENT "头像链接",
  `union_id` varchar(64) NULL COMMENT "union_id",
  `phone` varchar(32) NULL COMMENT "手机号",
  `gender` int(11) NULL COMMENT "性别",
  `conn_status` int(11) NULL COMMENT "连接状态",
  `connected_time` int(11) NULL COMMENT "连接时间",
  `disconnected_time` int(11) NULL COMMENT "断开连接时间",
  `plugin_version_name` varchar(32) NULL COMMENT "插件版本名称",
  `wework_version` varchar(32) NULL COMMENT "企业微信版本",
  `remark` varchar(128) NULL COMMENT "备注",
  `if_init_contact` int(11) NULL COMMENT "是否初始化联系人",
  `if_init_group` int(11) NULL COMMENT "是否初始化群组",
  `source` int(11) NULL COMMENT "来源",
  `proto_version` int(11) NULL COMMENT "协议版本",
  `pit` int(11) NULL COMMENT "pit",
  `pit_status` int(11) NULL COMMENT "pit 状态"
) ENGINE=OLAP 
PRIMARY KEY(`id`)
DISTRIBUTED BY HASH(`id`)
PROPERTIES (
  "compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);




SELECT register_time `注册时间`,
       a.user_id `用户ID`,
       bind_interior_staff_wework_id `绑定企微ID`,
       b.name `绑定企微名称`,
       if(is_logoff=0,'否','是') `是否已注销`,
       c.province `用户最近一次登录省份`,
       c.city `用户最近一次登录城市`,
       c.county `用户最近一次登录区县`
FROM
  (SELECT register_time,
          user_id,
          bind_interior_staff_wework_id,
          is_logoff
   FROM dim.dim_silkworm_user
   WHERE date(register_time) BETWEEN '2025-12-31' AND '2025-12-31') a
LEFT JOIN dim.dim_silkworm_wework_account_realtime b ON cast(a.bind_interior_staff_wework_id AS int)=b.id
LEFT JOIN dim.dim_silkworm_user_location c ON a.user_id=c.user_id;







====================== 搜索无结果
-- 搜索无结果统计
SELECT search_date,
       a.user_id,
       query,
       search_num,
       search_expose_num,
       address_detail user_address,
       b.longitude,
       b.latitude
FROM
  (SELECT search_date,
          user_id,
          keywords AS query,
          search_num,
          search_expose_num
   FROM
     (SELECT search_date,
             user_id,
             keywords,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num,
             sum(takeaway_baoming_order_num) takeaway_baoming_order_num,
             sum(takeaway_valid_order_num) takeaway_valid_order_num,
             sum(takeaway_profit) takeaway_profit
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '2025-12-02' AND '2025-12-02'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3) a
   WHERE search_num>0
     AND search_expose_num=0) a
LEFT JOIN dim.dim_silkworm_user_location b ON a.user_id=b.user_id;

-- 店铺
SELECT store_id,
       store_name,
       concat ( province_name, city_name, district_name, address, address_detail ) AS store_address,
       longitude,
       latitude
FROM dim.dim_silkworm_store
WHERE substr (latest_promotion_time, 1, 10)>='2025-12-02'



========================= 搜索词
-- 数据量：289489
-- 日均搜索量
SELECT keywords AS query,
       ceil(avg(search_num)) avg_search_num,
       ceil(avg(search_unum)) avg_search_unum
FROM
  (SELECT search_date,
          keywords,
          sum(search_num) search_num,
          count(DISTINCT if(search_num>0,user_id,NULL)) search_unum
   FROM dws.dws_sr_traffic_search_user_d
   WHERE search_date BETWEEN '2025-12-02' AND '2025-12-08'
     AND entrance_name = '首页'
   GROUP BY 1,
            2) a
GROUP BY 1;


-- 数据量：649811
WITH t1 AS
  (SELECT search_date,
          keywords AS query,
          CASE
              WHEN location=1 THEN '1'
              WHEN location=2 THEN '2'
              WHEN location=3 THEN '3'
              WHEN location=4 THEN '4'
              WHEN location=5 THEN '5'
              WHEN location=6 THEN '6'
              WHEN location=7 THEN '7'
              WHEN location=8 THEN '8'
              WHEN location=9 THEN '9'
              WHEN location=10 THEN '10'
              WHEN location BETWEEN 11 AND 15 THEN '11-15'
              WHEN location BETWEEN 16 AND 20 THEN '16-20'
              WHEN location BETWEEN 21 AND 30 THEN '21-30'
              WHEN location BETWEEN 31 AND 40 THEN '31-40'
              WHEN location BETWEEN 41 AND 50 THEN '41-50'
              WHEN location>=51 THEN '51级以上'
              ELSE '其他'
          END AS position,
          sum(search_expose_num) search_expose_num,
          sum(if(search_expose_num>0,search_result_click_num,0)) search_result_click_num,
          sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) takeaway_baoming_order_num,
          sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) takeaway_valid_order_num,
          count(DISTINCT if(search_num>0,user_id,NULL)) search_unum,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) search_expose_unum,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) search_result_click_unum,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) takeaway_baoming_order_unum,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) takeaway_valid_order_unum
   FROM dws.dws_sr_traffic_search_user_d
WHERE search_date BETWEEN '2025-12-02' AND '2025-12-08'
AND entrance_name = '首页'
   GROUP BY 1,
            2,
            3)


SELECT query,
       position,
       ceil(avg(search_expose_num)) avg_search_expose_num,
       ceil(avg(search_result_click_num)) avg_search_result_click_num,
       ceil(avg(search_result_click_num)) avg_takeaway_baoming_order_num,
       ceil(avg(takeaway_baoming_order_num)) avg_takeaway_valid_order_num,
       ceil(avg(search_expose_unum)) avg_search_expose_unum,
       ceil(avg(search_result_click_unum)) avg_search_result_click_unum,
       ceil(avg(takeaway_baoming_order_unum)) avg_takeaway_baoming_order_unum,
       ceil(avg(takeaway_valid_order_unum)) avg_takeaway_valid_order_unum
FROM t1
GROUP BY 1,
         2



-- 搜索词日均指标
-- 数据量29万
WITH t1 AS (
SELECT keywords AS query,
       ceil(avg(search_num)) `日均搜索量`,
       ceil(avg(search_expose_num)) `日均搜索结果曝光量`,
       ceil(avg(search_result_click_num)) `日均搜索结果点击量`,
       ceil(avg(takeaway_baoming_order_num)) `日均搜索报名订单量`,
       ceil(avg(takeaway_valid_order_num)) `日均搜索有效订单量`,
       ceil(avg(search_unum)) `日均搜索用户量`,
       ceil(avg(search_expose_unum)) `日均搜索结果曝光用户量`,
       ceil(avg(search_result_click_unum)) `日均搜索结果点击用户量`,
       ceil(avg(takeaway_baoming_order_unum)) `日均搜索报名用户量`,
       ceil(avg(takeaway_valid_order_unum)) `日均搜索有效用户量`
FROM
  (SELECT search_date,
          keywords,
          sum(search_num) search_num,
          sum(search_expose_num) search_expose_num,
          sum(if(search_expose_num>0,search_result_click_num,0)) search_result_click_num,
          sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) takeaway_baoming_order_num,
          sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) takeaway_valid_order_num,
          count(DISTINCT if(search_num>0,user_id,NULL)) search_unum,
          count(DISTINCT if(search_expose_num>0,user_id,NULL)) search_expose_unum,
          count(DISTINCT if(search_result_click_num>0,user_id,NULL)) search_result_click_unum,
          count(DISTINCT if(takeaway_baoming_order_num>0,user_id,NULL)) takeaway_baoming_order_unum,
          count(DISTINCT if(takeaway_valid_order_num>0,user_id,NULL)) takeaway_valid_order_unum
   FROM dws.dws_sr_traffic_search_user_d
   WHERE search_date BETWEEN '2025-12-02' AND '2025-12-08'
     AND entrance_name = '首页'
   GROUP BY 1,
            2) a
GROUP BY 1),


-- 无结果
t2 AS (SELECT keywords,
       ceil(avg(`无搜索结果搜索量`)) `日均无搜索结果搜索量`,
       ceil(avg(`无搜索结果搜索用户量`)) `日均无搜索结果搜索用户量`,
       ceil(avg(`无搜索结果点击搜索量`)) `日均无搜索结果点击搜索量`,
       ceil(avg(`无搜索结果点击搜索用户量`)) `日均无搜索结果点击搜索用户量`
FROM
  (SELECT search_date,
          keywords,
          sum(if(search_num>0
                 AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num=0,user_id,NULL)) `无搜索结果搜索用户量`,
          sum(if(search_num>0
                 AND search_expose_num>0
                 AND search_result_click_num=0,search_num,0)) `无搜索结果点击搜索量`,
          count(DISTINCT if(search_num>0
                            AND search_expose_num>0
                            AND search_result_click_num=0,user_id,0)) `无搜索结果点击搜索用户量`
   FROM
     (SELECT search_date,
             platform_name,
             user_id,
             keywords,
             sum(search_num) search_num,
             sum(search_expose_num) search_expose_num,
             sum(search_result_click_num) search_result_click_num
      FROM dws.dws_sr_traffic_search_user_d
      WHERE search_date BETWEEN '2025-12-02' AND '2025-12-08'
        AND entrance_name = '首页'
      GROUP BY 1,
               2,
               3,
               4) a
   GROUP BY 1,
            2) b
GROUP BY 1)


SELECT t1.query,
       t1.`日均搜索量`,
       t1.`日均搜索结果曝光量`,
       t1.`日均搜索结果点击量`,
       t1.`日均搜索报名订单量`,
       t1.`日均搜索有效订单量`,
       t1.`日均搜索用户量`,
       t1.`日均搜索结果曝光用户量`,
       t1.`日均搜索结果点击用户量`,
       t1.`日均搜索报名用户量`,
       t1.`日均搜索有效用户量`,
       t2.`日均无搜索结果搜索量`,
       t2.`日均无搜索结果搜索用户量`,
       t2.`日均无搜索结果点击搜索量`,
       t2.`日均无搜索结果点击搜索用户量`
FROM t1
LEFT JOIN t2 ON t1.query=t2.keywords;


