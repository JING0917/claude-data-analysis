WITH filtered_orders AS (
    -- 筛选时间和状态符合条件的订单
    SELECT 
        user_id,
        order_time,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_time) AS rn
    FROM dwd.dwd_sr_order_promotion_order
    WHERE dt BETWEEN '2025-01-01' AND '2025-11-16'
      AND order_status IN (2, 8)
),

-- 先过滤总订单数≥40的用户（减少后续计算量）
qualified_users AS (
    SELECT user_id
    FROM filtered_orders
    GROUP BY user_id
    HAVING COUNT(*) >= 140
),

-- 计算每个用户在90天窗口内的最大订单数
user_window_check AS (
    SELECT 
        a.user_id,
        -- 90天窗口内的订单数=最大序号-当前序号+1
        MAX(b.rn - a.rn + 1) AS max_orders_in_90days
    FROM filtered_orders a
    -- 关联同用户90天内的后续订单
    INNER JOIN filtered_orders b 
        ON a.user_id = b.user_id
        AND b.rn >= a.rn
        AND b.order_time <= a.order_time + INTERVAL 90 DAY
    INNER JOIN qualified_users q 
        ON a.user_id = q.user_id
    GROUP BY a.user_id 
),

-- 最终筛选出存在90天窗口下单≥40的用户
user_info as 
(SELECT DISTINCT user_id
FROM user_window_check
WHERE max_orders_in_90days >= 140
ORDER BY user_id),

-- select count(1) tot from user_info;

-- 近14天访问
view_info as (
select
unnest_bitmap as user_id 
from dws.dws_sr_user_login_d,unnest_bitmap(view_uids) as uid
where statistics_date between date_sub(current_date(),interval 14 day) and date_sub(current_date(),interval 1 day)
group by 1
)

-- 满足条件用户量
select
    c.new_user_level,
    count(distinct a.user_id) num
from user_info a inner join view_info b on a.user_id=b.user_id
left join dim.dim_silkworm_member c on a.user_id=c.user_id
group by 1;


-- 满足下单条件用户量
SELECT c.new_user_level,
       count(DISTINCT a.user_id) num
FROM user_info a
LEFT JOIN dim.dim_silkworm_member c ON a.user_id=c.user_id
GROUP BY 1;
