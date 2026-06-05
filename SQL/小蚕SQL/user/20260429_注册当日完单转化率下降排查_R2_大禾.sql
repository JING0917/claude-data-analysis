================================================================================
-- 注册当日完单转化率下降排查 — 第二轮：平台侧定位
-- 背景：全渠道、全漏斗、全时段同步下降，小蚕内部无可疑
-- 核心假设：美团/饿了么侧在4/16前后有策略变更
================================================================================


-- ============================================================
-- 查询1：美团 vs 饿了么 拆分
-- ============================================================

-- 1a. 新用户首单平台分布（看下降是美团驱动还是饿了么驱动）
SELECT CASE WHEN date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-15' THEN 'before'
            WHEN date(a.register_time) BETWEEN '2026-04-16' AND '2026-04-17' THEN 'after'
       END AS period,
       b.platform,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT b.user_id) AS completed_users,
       round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS conversion_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND date(b.order_time) = date(a.register_time)
    AND b.order_status IN (2, 8)
WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-17'
GROUP BY 1, 2
ORDER BY 1, 2;

-- 1b. 备选（无platform字段，用platform_id区分）
SELECT CASE WHEN date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-15' THEN 'before'
            WHEN date(a.register_time) BETWEEN '2026-04-16' AND '2026-04-17' THEN 'after'
       END AS period,
       CASE WHEN b.platform_id = 1 THEN '美团'
            WHEN b.platform_id = 2 THEN '饿了么'
            ELSE '其他'
       END AS platform,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT b.user_id) AS completed_users,
       round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS conversion_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND date(b.order_time) = date(a.register_time)
    AND b.order_status IN (2, 8)
WHERE date(a.register_time) BETWEEN '2026-04-14' AND '2026-04-17'
GROUP BY 1, 2
ORDER BY 1, 2;


-- ============================================================
-- 查询2：平台侧给量变化 — 小蚕在美团侧的曝光和点击是否下降
-- ============================================================

-- 2a. 全平台曝光→点击→下单漏斗（所有用户）
SELECT dt,
       sum(exposure_uv)       AS exposure_uv,
       sum(click_uv)          AS click_uv,
       sum(valid_order_uv)    AS order_uv,
       round(sum(click_uv) * 1.0 / nullif(sum(exposure_uv), 0), 4)      AS ctr,
       round(sum(valid_order_uv) * 1.0 / nullif(sum(click_uv), 0), 4)   AS click_to_order_rate
FROM dws.dws_sr_traffic_takeawaypro_funnel_d
WHERE dt BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;

-- 2b. 按平台拆分的漏斗（如有platform字段）
SELECT dt,
       platform,
       sum(exposure_uv)       AS exposure_uv,
       sum(click_uv)          AS click_uv,
       round(sum(click_uv) * 1.0 / nullif(sum(exposure_uv), 0), 4)      AS ctr
FROM dws.dws_sr_traffic_takeawaypro_funnel_d
WHERE dt BETWEEN '2026-04-12' AND '2026-04-19'
GROUP BY 1, 2
ORDER BY 1, 2;


-- ============================================================
-- 查询3：4月整月转化率趋势（确认是4/16突变还是已在下行通道）
-- ============================================================

SELECT date(a.register_time) AS dt,
       count(DISTINCT a.user_id) AS new_users,
       count(DISTINCT b.user_id) AS completed_users,
       round(count(DISTINCT b.user_id) * 1.0 / count(DISTINCT a.user_id), 4) AS conversion_rate
FROM dim.dim_silkworm_user a
LEFT JOIN dwd.dwd_sr_order_promotion_order b
    ON a.user_id = b.user_id
    AND date(b.order_time) = date(a.register_time)
    AND b.order_status IN (2, 8)
WHERE date(a.register_time) BETWEEN '2026-04-01' AND '2026-04-19'
GROUP BY 1
ORDER BY 1;


================================================================================
-- 解读框架：
--
-- 查询1：
--   ├── 仅美团掉 → 美团侧变更
--   ├── 仅饿了么掉 → 饿了么侧变更
--   └── 两个都掉 → 双平台同步调整，或下游供给问题
--
-- 查询2：
--   ├── 曝光降了 → 平台减少了给小蚕的流量
--   ├── 曝光不变、CTR降了 → 平台调整了排序/展示策略，小蚕位置变差
--   ├── CTR不变、下单率降了 → 落地页或美团侧转化问题
--   └── 全不变 → 回到小蚕内部排查
--
-- 查询3：
--   ├── 4/16突变 → 事件驱动，需定位当天发生了什么
--   └── 4月初已在下降 → 趋势问题，非突发
================================================================================
