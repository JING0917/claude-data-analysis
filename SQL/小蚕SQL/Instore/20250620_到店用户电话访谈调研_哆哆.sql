性别、年龄、城市、电话号、砍价累计完单数/单人餐完单数、探店总完单数

砍价高频用户（近30有5单砍价完单及以上）
探店高频用户（近30有5单探店完单及以上）
下单未完单用户（近7天有报名但是未完单用户）

================== 高频用户

-- 到店完单
WITH t1 AS
  (SELECT user_id,
          count(if(promotion_type IN (1,4),order_id,NULL)) exp_ordnum,
                                                           count(if(promotion_type IN (5,6,8)
                                                                    AND status=5,order_id,NULL)) bar_ordnum
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND promotion_type IN (5,
                            6,
                            8,
                            1,
                            4)
     AND status IN (5,
                    19,
                    20,
                    35)
   GROUP BY 1),



-- 探店累计完单
t2 AS
  (SELECT user_id,
          count(1) accu_exp_ordnum
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE promotion_type IN ( 1,
                             4)
     AND status IN (5,
                    19,
                    20,
                    35)
   GROUP BY 1),


-- 砍价累计完单
t3 AS
  ( SELECT user_id,
           count(1) accu_bar_ordnum,
                    count(if(b.guest_count_type=1,order_id,NULL)) accu_single_ordnum,
                                                                  count(if(b.guest_count_type NOT IN (0,1),order_id,NULL)) accu_notsingle_ordnum
   FROM
     (SELECT user_id,
             store_promotion_id,
             order_id
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE promotion_type IN (5,
                               6,
                               8)
        AND status=5) a
   LEFT JOIN
     (SELECT promotion_id,
             guest_count_type
      FROM dwd.dwd_sr_silkworm_explore_promotion
      WHERE promotion_type IN (5,
                               6,
                               8)) b ON a.store_promotion_id=b.promotion_id
   GROUP BY 1),


-- 用户信息
t4 AS
  (SELECT user_id,
          phone,
          year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),NULL)) AS age,
          CASE if(length(user_id_num)=18, cast(substring(user_id_num,17,1) AS UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) AS UNSIGNED)%2,3))
              WHEN 1 THEN '男'
              WHEN 0 THEN '女'
              ELSE '未知'
          END AS gender,
          city_name
   FROM ods.ods_sr_silkworm_user a
   LEFT JOIN dim.dim_silkworm_county b ON a.county_id=b.county_id)


SELECT
    '探店' `业务名称`,
    t1.user_id `用户ID`,
    t4.age `用户年龄`,
    t4.gender `用户性别`,
    t4.phone `用户手机号`,
    t4.city_name `用户城市`,
    t3.accu_bar_ordnum `砍价累计完单数`,
    t3.accu_single_ordnum `砍价累计单人餐完单数`,
    t3.accu_notsingle_ordnum `砍价累计多人餐完单数`,
    t2.accu_exp_ordnum as `探店累计完单数`
from t1 left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
where t1.exp_ordnum>=5

union all

SELECT
    '砍价' `业务名称`,
    t1.user_id `用户ID`,
    t4.age `用户年龄`,
    t4.gender `用户性别`,
    t4.phone `用户手机号`,
    t4.city_name `用户城市`,
    accu_bar_ordnum `砍价累计完单数`,
    accu_single_ordnum `砍价累计单人餐完单数`,
    accu_notsingle_ordnum `砍价累计多人餐完单数`,
    t2.accu_exp_ordnum `探店累计完单数`
from t1 left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
where t1.bar_ordnum>=5
;



======== 下单未完单用户

-- 到店访问

-- WITH t1 AS
--   (SELECT CASE
--               WHEN event_ename LIKE '%Bargain%'
--                    OR event_ename IN ('StoreDiscovery_Activity_Details_Atmosphere_Ex',
--                                       'StoreDiscovery_Activity_Details_GrabOrder_Click') THEN '砍价'
--               WHEN event_ename LIKE '%StoreDiscovery%' THEN '探店'
--               ELSE '外卖'
--           END business_name,
--               unnest_bitmap AS user_id
--    FROM dwd.dwd_sr_traffic_viewuser_d,
--         unnest_bitmap(user_ids) AS uid
--    WHERE dt BETWEEN date_sub(current_date(),interval 30 DAY) AND date_sub(current_date(),interval 1 DAY)),



-- 到店完单
WITH t1 AS
  (SELECT user_id,
          count(if(promotion_type IN (1,4),order_id,NULL)) exp_ordnum,
          count(if(promotion_type IN (5,6,8),order_id,NULL)) bar_ordnum,
          count(if(promotion_type IN (1,4) AND status IN (5, 19, 20, 35),order_id,NULL)) exp_finord_num,
          count(if(promotion_type IN (5,6,8) AND status=5,order_id,NULL)) bar_finord_num
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE dt BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)
     AND promotion_type IN (5,
                            6,
                            8,
                            1,
                            4)
   GROUP BY 1),


-- 探店累计完单
t2 AS
  (SELECT user_id,
          count(1) accu_exp_ordnum
   FROM dwd.dwd_sr_silkworm_explore_order
   WHERE promotion_type IN ( 1,
                             4)
     AND status IN (5,
                    19,
                    20,
                    35)
   GROUP BY 1),


-- 砍价累计完单
t3 AS
  ( SELECT user_id,
           count(1) accu_bar_ordnum,
                    count(if(b.guest_count_type=1,order_id,NULL)) accu_single_ordnum,
                                                                  count(if(b.guest_count_type NOT IN (0,1),order_id,NULL)) accu_notsingle_ordnum
   FROM
     (SELECT user_id,
             store_promotion_id,
             order_id
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE promotion_type IN (5,
                               6,
                               8)
        AND status=5) a
   LEFT JOIN
     (SELECT promotion_id,
             guest_count_type
      FROM dwd.dwd_sr_silkworm_explore_promotion
      WHERE promotion_type IN (5,
                               6,
                               8)) b ON a.store_promotion_id=b.promotion_id
   GROUP BY 1),


-- 用户信息
t4 AS
  (SELECT user_id,
          phone,
          year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),NULL)) AS age,
          CASE if(length(user_id_num)=18, cast(substring(user_id_num,17,1) AS UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) AS UNSIGNED)%2,3))
              WHEN 1 THEN '男'
              WHEN 0 THEN '女'
              ELSE '未知'
          END AS gender,
          city_name
   FROM ods.ods_sr_silkworm_user a
   LEFT JOIN dim.dim_silkworm_county b ON a.county_id=b.county_id)


SELECT
    '探店' `业务名称`,
    t1.user_id `用户ID`,
    t4.age `用户年龄`,
    t4.gender `用户性别`,
    t4.phone `用户手机号`,
    t4.city_name `用户城市`,
    t3.accu_bar_ordnum `砍价累计完单数`,
    t3.accu_single_ordnum `砍价累计单人餐完单数`,
    t3.accu_notsingle_ordnum `砍价累计多人餐完单数`,
    t2.accu_exp_ordnum as `探店累计完单数`
from t1 left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
where t1.exp_ordnum>=1 and t1.exp_finord_num=0

union all

SELECT
    '砍价' `业务名称`,
    t1.user_id `用户ID`,
    t4.age `用户年龄`,
    t4.gender `用户性别`,
    t4.phone `用户手机号`,
    t4.city_name `用户城市`,
    accu_bar_ordnum `砍价累计完单数`,
    accu_single_ordnum `砍价累计单人餐完单数`,
    accu_notsingle_ordnum `砍价累计多人餐完单数`,
    t2.accu_exp_ordnum `探店累计完单数`
from t1 left join t2 on t1.user_id=t2.user_id
left join t3 on t1.user_id=t3.user_id
left join t4 on t1.user_id=t4.user_id
where t1.bar_ordnum>=1 and t1.bar_finord_num=0
;

















