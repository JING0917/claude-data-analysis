================ 绑定企微ID：1017的用户，订单首次核销时间
-- 已添加企微
-- 有多次绑定记录，需业务定如何取
with t1 as (
select
    user_id,create_date,bind_interior_staff_wework_id
from
    (select
        user_id,
        date(create_time) as create_date,
        bind_interior_staff_wework_id,
        row_number() over(partition by user_id order by create_time desc) as rk
    from dwd.dwd_sr_silkworm_explore_bind_wework_record
    where status=1
    ) a
where rk=1
    and bind_interior_staff_wework_id=1017
),

-- 用户核销订单量
t2 as (
select
    user_id,
    min(verify_time) as `探店订单首次核销时间`
from dwd.dwd_sr_silkworm_explore_order
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and promotion_type in (1,4) -- 活动类型 1和4是探店订单;2和3是公益订单
    and substr(verify_time,1,10)<>'1970-01-01'
group by 1
)

select
    t1.user_id as `用户ID`,
    b.user_nickname as `用户昵称`,
    t2.`探店订单首次核销时间`
from t1 left join t2 on t1.user_id=t2.user_id
left join dim.dim_silkworm_user b on t1.user_id=b.user_id
;