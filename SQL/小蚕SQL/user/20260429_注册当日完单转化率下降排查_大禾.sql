================================================================================
-- 注册当日完单转化率下降排查
-- 异常时间：2026年4月16日起，下降约3pp
-- 指标定义：完单转化率 = 注册当日完单用户量 / 注册当日新增用户量
-- 分析框架：分子(完单量) → 分母(注册量) → 渠道结构 → 红包/活动
================================================================================


-- ============================================================
-- 第1步：异常确认 — 分子or分母
-- ============================================================

-- 1a. 每日注册量
SELECT date(register_time) AS dt,
       count(1) AS new_users
FROM dim.dim_silkworm_user
WHERE date(register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;

-- 1b. 每日注册用户中，当天完单的用户量
SELECT date(a.register_time) AS dt,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT b.user_id) AS completed_users,
       round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS conversion_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND date(b.order_time) = date(a.register_time)
    AND b.order_status IN (2, 8)  -- 有效订单
WHERE date(a.register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;

-- 1c. 确认数据是否完整（检查订单表的数据延迟）
SELECT date(order_time) AS dt,
       count(1) AS order_cnt,
       count(DISTINCT user_id) AS user_cnt
FROM dwd.dwd_sr_order_promotion_order
WHERE date(order_time) BETWEEN '2026-04-12' AND '2026-04-19'
  AND order_status IN (2, 8)
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 第2步：渠道拆解 — 哪个渠道变了
-- ============================================================

-- 2a. 每日各渠道注册量（含渠道分类）
SELECT date(register_time) AS dt,
       CASE
           WHEN get_json_string(meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
           WHEN get_json_string(meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
           WHEN get_json_string(meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                AND get_json_string(meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
           ELSE '未知'
       END AS channel_group,
       get_json_string(meituan_auth_user_detail, '$.re_ch') AS channel_detail,
       count(1) AS new_users
FROM dim.dim_silkworm_user
WHERE date(register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 2b. 各渠道注册用户的当日完单转化率
SELECT date(a.register_time) AS dt,
       CASE
           WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
           WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
           WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                AND get_json_string(a.meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
           ELSE '未知'
       END AS channel_group,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT b.user_id) AS completed_users,
       round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS conversion_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND date(b.order_time) = date(a.register_time)
    AND b.order_status IN (2, 8)
WHERE date(a.register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1, 2
ORDER BY 1, 2;

-- 2c. 渠道变化量级分析：4/14-4/15 vs 4/16-4/17 对比
WITH channel_daily AS (
    SELECT date(a.register_time) AS dt,
           CASE
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                    AND get_json_string(a.meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
               ELSE '未知'
           END AS channel_group,
           count(DISTINCT a.user_id) AS new_users,
           count(DISTINCT b.user_id) AS completed_users
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-17'
    GROUP BY 1, 2
)
SELECT channel_group,
       sum(CASE WHEN dt IN ('2026-04-14', '2026-04-15') THEN new_users ELSE 0 END) AS before_users,
       sum(CASE WHEN dt IN ('2026-04-16', '2026-04-17') THEN new_users ELSE 0 END) AS after_users,
       sum(CASE WHEN dt IN ('2026-04-16', '2026-04-17') THEN new_users ELSE 0 END)
       - sum(CASE WHEN dt IN ('2026-04-14', '2026-04-15') THEN new_users ELSE 0 END) AS user_change,
       round(sum(CASE WHEN dt IN ('2026-04-14', '2026-04-15') THEN completed_users ELSE 0 END) * 1.0
             / nullif(sum(CASE WHEN dt IN ('2026-04-14', '2026-04-15') THEN new_users ELSE 0 END), 0), 4) AS conv_before,
       round(sum(CASE WHEN dt IN ('2026-04-16', '2026-04-17') THEN completed_users ELSE 0 END) * 1.0
             / nullif(sum(CASE WHEN dt IN ('2026-04-16', '2026-04-17') THEN new_users ELSE 0 END), 0), 4) AS conv_after
FROM channel_daily
GROUP BY 1
ORDER BY 4 DESC;  -- 按注册变化量降序，定位变化最大的渠道


-- ============================================================
-- 第3步：辛普森悖论检查 — 渠道结构变化
-- ============================================================

-- 3a. 计算每个渠道在4/14-4/15的转化率（基准）
WITH baseline AS (
    SELECT CASE
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                    AND get_json_string(a.meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
               ELSE '未知'
           END AS channel_group,
           count(DISTINCT a.user_id) AS new_users,
           count(DISTINCT b.user_id) AS completed_users,
           round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS baseline_conv
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-15'
    GROUP BY 1
),
-- 4/16-4/17各渠道实际注册量
actual AS (
    SELECT CASE
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                    AND get_json_string(a.meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
               ELSE '未知'
           END AS channel_group,
           count(DISTINCT a.user_id) AS actual_users,
           count(DISTINCT b.user_id) AS actual_completed
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-16' AND '2026-04-17'
    GROUP BY 1
)
SELECT bl.channel_group,
       bl.new_users AS baseline_users,
       bl.baseline_conv,
       ac.actual_users,
       round(ac.actual_users * 1.0 / sum(ac.actual_users) OVER(), 4) AS actual_share,
       round(ac.actual_completed * 1.0 / ac.actual_users, 4) AS actual_conv,
       -- 反事实：如果每个渠道的转化率不变，用新结构算出的整体转化率
       round(bl.baseline_conv * ac.actual_users, 0) AS counterfactual_completed,
       -- 实际完单量 vs 反事实完单量 的差距
       round(ac.actual_completed - bl.baseline_conv * ac.actual_users, 0) AS completion_gap
FROM baseline bl
JOIN actual ac ON bl.channel_group = ac.channel_group
ORDER BY ac.actual_users DESC;

-- 3b. 汇总：反事实整体转化率 vs 实际整体转化率
WITH baseline AS (
    SELECT CASE
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                    AND get_json_string(a.meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
               ELSE '未知'
           END AS channel_group,
           round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS baseline_conv
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-15'
    GROUP BY 1
),
actual AS (
    SELECT CASE
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IN ('invite', 'share') THEN '团长拉新'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') = 'organic' THEN '自然新增'
               WHEN get_json_string(a.meituan_auth_user_detail, '$.re_ch') IS NOT NULL
                    AND get_json_string(a.meituan_auth_user_detail, '$.re_ch') != '' THEN '付费渠道'
               ELSE '未知'
           END AS channel_group,
           count(DISTINCT a.user_id) AS actual_users,
           count(DISTINCT b.user_id) AS actual_completed
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-16' AND '2026-04-17'
    GROUP BY 1
)
SELECT '4/14-4/15 实际' AS metric,
       round(sum(bl_completed) * 1.0 / sum(bl_users), 4) AS overall_conv
FROM (
    SELECT count(DISTINCT a.user_id) AS bl_users,
           count(DISTINCT b.user_id) AS bl_completed
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-15'
) t

UNION ALL

SELECT '4/16-4/17 实际' AS metric,
       round(sum(ac_completed) * 1.0 / sum(ac_users), 4) AS overall_conv
FROM (
    SELECT count(DISTINCT a.user_id) AS ac_users,
           count(DISTINCT b.user_id) AS ac_completed
    FROM dim.dim_silkworm_user a
    LEFT JOIN dwd.dwd_sr_order_promotion_order b
        ON a.user_id = b.user_id
        AND date(b.order_time) = date(a.register_time)
        AND b.order_status IN (2, 8)
    WHERE date(a.register_time) BETWEEN '2026-04-16' AND '2026-04-17'
) t

UNION ALL

SELECT '4/16-4/17 反事实(渠道转化率不变)' AS metric,
       round(sum(bl.baseline_conv * ac.actual_users) / sum(ac.actual_users), 4) AS counterfactual_conv
FROM baseline bl
JOIN actual ac ON bl.channel_group = ac.channel_group;


-- ============================================================
-- 第4步：新用户红包/优惠券排查
-- ============================================================

-- 4a. 每日新用户红包发放量（取注册当天）
SELECT date(a.register_time) AS dt,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT c.user_id) AS users_with_coupon,
       sum(c.grant_num) AS total_coupons,
       sum(c.used_num) AS used_coupons,
       round(sum(c.used_num) * 1.0 / nullif(sum(c.grant_num), 0), 4) AS coupon_use_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dws.dws_sr_marketing_cost_coupon_d c
    ON a.user_id = c.user_id
    AND c.dt = date(a.register_time)
WHERE date(a.register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;

-- 4b. 按红包类型细分（重点关注新人券）
SELECT date(a.register_time) AS dt,
       c.coupon_type,
       c.sub_coupon_type,
       count(DISTINCT a.user_id) AS new_users,
       sum(c.grant_num) AS total_granted,
       sum(c.used_num) AS total_used,
       round(sum(c.used_num) * 1.0 / nullif(sum(c.grant_num), 0), 4) AS use_rate
FROM dim.dim_silkworm_user a
JOIN dws.dws_sr_marketing_cost_coupon_d c
    ON a.user_id = c.user_id
    AND c.dt = date(a.register_time)
WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-17'
  AND c.sub_coupon_type LIKE '%新人%'  -- 新用户相关券
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 4c. 新用户是否有红包雨参与记录
SELECT date(a.register_time) AS dt,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT CASE WHEN r.grant_num > 0 THEN a.user_id END) AS hongbao_users,
       round(count(DISTINCT CASE WHEN r.grant_num > 0 THEN a.user_id END) * 1.0
             / count(DISTINCT a.user_id), 4) AS hongbao_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dws.dws_sr_marketing_cost_coupon_d r
    ON a.user_id = r.user_id
    AND r.dt = date(a.register_time)
    AND r.sub_coupon_type = '红包雨'  -- 红包雨类型，实际字段名需确认
WHERE date(a.register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 第5步：新用户当天行为漏斗
-- ============================================================

-- 5a. 注册当天漏斗：访问→曝光→点击→下单
SELECT date(a.register_time) AS dt,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT f.user_id) AS visited_users,
       count(DISTINCT CASE WHEN f.exposure_uv > 0 THEN f.user_id END) AS exposed_users,
       count(DISTINCT CASE WHEN f.click_uv > 0 THEN f.user_id END) AS clicked_users,
       count(DISTINCT CASE WHEN f.baoming_order_uv > 0 THEN f.user_id END) AS baoming_users,
       count(DISTINCT CASE WHEN f.valid_order_uv > 0 THEN f.user_id END) AS valid_order_users,
       round(count(DISTINCT f.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS visit_rate,
       round(count(DISTINCT CASE WHEN f.valid_order_uv > 0 THEN f.user_id END) * 1.0
             / count(DISTINCT a.user_id), 4) AS order_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dws.dws_sr_traffic_takeawaypro_funnel_d f
    ON a.user_id = f.user_id
    AND f.dt = date(a.register_time)
WHERE date(a.register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;

-- 5b. 注册当天各小时的完单分布（找时段异常）
SELECT date(a.register_time) AS dt,
       hour(b.order_time) AS order_hour,
       count(DISTINCT a.user_id) AS new_users_that_hour,
       count(DISTINCT b.user_id) AS completed_users
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND date(b.order_time) = date(a.register_time)
    AND b.order_status IN (2, 8)
WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-17'
GROUP BY 1, 2
ORDER BY 1, 2;


-- ============================================================
-- 第6步：延展检查 — 非当日完单的7日转化
-- ============================================================

-- 6a. 注册用户在7日内的累计完单转化（看是否当日下降但延后补偿）
SELECT date(a.register_time) AS dt,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT CASE WHEN datediff(date(b.order_time), date(a.register_time)) = 0 THEN b.user_id END) AS d0_users,
       count(DISTINCT CASE WHEN datediff(date(b.order_time), date(a.register_time)) <= 1 THEN b.user_id END) AS d1_users,
       count(DISTINCT CASE WHEN datediff(date(b.order_time), date(a.register_time)) <= 3 THEN b.user_id END) AS d3_users,
       count(DISTINCT CASE WHEN datediff(date(b.order_time), date(a.register_time)) <= 7 THEN b.user_id END) AS d7_users,
       round(count(DISTINCT CASE WHEN datediff(date(b.order_time), date(a.register_time)) = 0 THEN b.user_id END) * 1.0
             / count(DISTINCT a.user_id), 4) AS d0_conv,
       round(count(DISTINCT CASE WHEN datediff(date(b.order_time), date(a.register_time)) <= 7 THEN b.user_id END) * 1.0
             / count(DISTINCT a.user_id), 4) AS d7_conv
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND b.order_status IN (2, 8)
    AND date(b.order_time) BETWEEN date(a.register_time) AND date_add(date(a.register_time), 7)
WHERE date(a.register_time) BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;


================================================================================
-- 执行顺序建议：
-- 1. 先跑 1a, 1b, 1c → 判断是分子还是分母问题
-- 2. 根据判断结果，跑 2a, 2b, 2c → 定位到具体渠道
-- 3. 跑 3a, 3b → 辛普森悖论检查
-- 4. 跑 4a, 4b, 4c → 红包/优惠券排查
-- 5. 跑 5a, 5b → 漏斗和时段排查
-- 6. 跑 6a → 看是否当日下降但延后转化补偿
--
-- 注意事项：
-- - 部分字段名（如coupon_type, sub_coupon_type）可能与实际表结构有差异，请根据实际DDL调整
-- - 红包雨类型标识字段需确认，可能不是 '红包雨'，检查枚举值
-- - 如果get_json_string解析失败，检查meituan_auth_user_detail是否为有效JSON
================================================================================
