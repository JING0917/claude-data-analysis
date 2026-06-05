-- ******************************************************************--
-- 搜索分流
-- 用户分流由数据平台开发给到的规则转为SQL实现（用户中途不退出），后续埋点上报完整后，再按埋点上报处理
-- 后续在MA平台可实现实时查看实验效果，不依赖数分处理
-- ******************************************************************--
-- 用户分流
-- 搜索用户
DROP VIEW IF EXISTS se_user;


CREATE VIEW IF NOT EXISTS se_user (user_id) AS
  (SELECT user_id
   FROM dws.dws_sr_traffic_search_user_d
   WHERE search_date='2026-02-02'
   GROUP BY 1);

-- 计算每个实验组的权重区间
DROP VIEW IF EXISTS group_weight_range;


CREATE VIEW IF NOT EXISTS group_weight_range (group_id,exp_id,group_name,expflow_weight,start_weight,end_weight) AS (
SELECT auto_id AS group_id, -- AB实验组ID
       exp_id,
       exp_name AS group_name,
       expflow_weight,
       sum(ifnull(expflow_weight,0)) over(PARTITION BY exp_id
                                          ORDER BY auto_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - expflow_weight AS start_weight,
       sum(ifnull(expflow_weight,0)) over(PARTITION BY exp_id
                                          ORDER BY auto_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS end_weight
FROM dim.dim_ma_experiment
WHERE exp_id=109);

-- 计算每个用户的bucket值（0-99）
DROP VIEW IF EXISTS user_bucket;


CREATE VIEW IF NOT EXISTS user_bucket (user_id,exp_id,bucket) AS
  ( SELECT user_id,
           109 AS exp_id,
                 MOD(
          ABS(CONV(
              SUBSTR(MD5(CONCAT(CAST(user_id AS VARCHAR), CAST(109 AS VARCHAR))), 1, 8),
              16, 10
          )),
          100
      ) AS bucket
   FROM se_user);

-- 匹配用户所属实验组（左闭右开区间）
DROP VIEW IF EXISTS user_group;


CREATE VIEW IF NOT EXISTS user_group (user_id,exp_id,group_id,bucket,group_name) AS
  (SELECT ub.user_id,
          ub.exp_id,
          gwr.group_id,
          ub.bucket,
          COALESCE(gwr.group_name, '未分配') AS group_name
   FROM user_bucket ub
   LEFT JOIN group_weight_range gwr ON ub.exp_id = gwr.exp_id -- 左闭：bucket >= start_weight（第一个组start_weight为NULL，用0替代）
   AND ub.bucket >= COALESCE(gwr.start_weight, 0) -- 右开：bucket < end_weight
   AND ub.bucket < gwr.end_weight);





-- 搜索指标统计
SELECT search_date `搜索日期`,
       b.group_id `实验组ID`,
       b.group_name `组名称`,
       sum(search_num) `搜索量`,
       sum(search_expose_num) `搜索曝光量`,
       sum(if(search_expose_num>0,search_result_click_num,0)) `搜索结果点击量`,
       sum(if(search_expose_num>0,search_result_click_num,0))/sum(search_expose_num) `CTR`,
       sum(if(search_result_click_num>0,takeaway_baoming_order_num,0)) `外卖报名订单量`,
       sum(if(takeaway_baoming_order_num>0,takeaway_valid_order_num,0)) `外卖有效订单量`,
       sum(if(takeaway_valid_order_num>0,takeaway_profit,0)) `外卖有效订单利润`,
       sum(if(search_result_click_num>0,takeaway_baoming_order_num,0))/sum(search_num) `CVR`,
       count(DISTINCT if(search_num>0,a.user_id,NULL)) `搜索用户量`,
       count(DISTINCT if(search_expose_num>0,a.user_id,NULL)) `搜索曝光用户量`,
       count(DISTINCT if(search_result_click_num>0,a.user_id,NULL)) `搜索结果点击用户量`,
       count(DISTINCT if(takeaway_baoming_order_num>0,a.user_id,NULL)) `外卖报名用户量`,
       count(DISTINCT if(takeaway_valid_order_num>0,a.user_id,NULL)) `外卖有效用户量`,
       count(DISTINCT if(search_expose_num>0,activity_id,NULL)) `搜索曝光活动数`,
       count(DISTINCT if(search_result_click_num>0,activity_id,NULL)) `搜索点击活动数`,
       count(DISTINCT if(takeaway_baoming_order_num>0,activity_id,NULL)) `搜索报名活动数`
FROM dws.dws_sr_traffic_search_user_d a
LEFT JOIN user_group b ON a.user_id=b.user_id
WHERE search_date ='2026-02-02'
  AND entrance_name='首页'
GROUP BY 1,
         2,
         3;

-- 搜索无结果指标统计
SELECT search_date `搜索日期`,
       b.group_id `实验组ID`,
       b.group_name `组名称`,
       sum(search_num) `搜索量`,
       sum(if(search_num>0
              AND search_expose_num=0,search_num,0)) `无搜索结果搜索量`
FROM
  (SELECT search_date,
          user_id,
          keywords,
          sum(search_num) search_num,
          sum(search_expose_num) search_expose_num
   FROM dws.dws_sr_traffic_search_user_d
   WHERE search_date='2026-02-02'
     AND entrance_name = '首页'
   GROUP BY 1,
            2,
            3) a
LEFT JOIN user_group b ON a.user_id=b.user_id
GROUP BY 1,
         2,
         3;


