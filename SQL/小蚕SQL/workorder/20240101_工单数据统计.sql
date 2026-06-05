-- 最近7天人工驳回订单
select
c.dt as `下单日期`,
count (DISTINCT a.order_id) `人工驳回订单量`,
count (DISTINCT if(c.order_status in (2,8),a.order_id,null)) `人工驳回完单订单量`
from
(
select 
  work_order_id,
  invitee_id,
  order_id,
  invitee_group_id,
  audit_status,
  status
from 
  dwd.dwd_sr_callcenter_workorder_h 
where dt>='2024-10-01' 
) a
inner join 
(select work_order_id 
from dwd.dwd_sr_callcenter_workorder_log_h 
where dt>='2024-10-01'  and action=13 
) b
on a.work_order_id=b.work_order_id
left join
(select * from dwd.dwd_sr_order_promotion_order where  dt>='2024-10-12') c
on a.order_id=c.order_id
where invitee_id!=1589
group by c.dt
;

============= 客服IM消息
show create table dwd.dwd_sr_callcenter_im_message;

select 
    count(*) as `总量`,
    sum(if(message_content not regexp '人工|客服|人呢|在吗|你好|您好|好的|？|有人吗|额|嗯|对的' 
            and message_content not regexp '^[0-9]',1,0)) as `剔除后总量`
from dwd.dwd_sr_callcenter_im_message
where server_type<>3
;

-- 验证
select message_content from dwd.dwd_sr_callcenter_im_message where message_content regexp '^[0-9]' and server_type<>3 limit 10;
============= 客服IM消息



========= 工单
show create table dwd.dwd_sr_callcenter_workorder;


select 
    work_order_id,
    cast(create_time as string) as create_time,
    wore_order_type,
    cate3_type
from dwd.dwd_sr_callcenter_workorder
where cast(dt as string) in ('2024-01-04','2024-01-09','2024-01-11',
                            '2024-01-18','2024-01-30','2024-02-26',
                            '2024-03-06','2024-03-19'
                            )
    and wore_order_type=5 -- 平台异常
    and cate3_type=10 -- 评价折叠
;

select
  a.user_id `用户ID`,
  count(distinct a.work_order_id) as `工单次数`
from
(select 
    work_order_id,
    create_time,
    wore_order_type,
    cate3_type,
    invitee_id,
    user_id
from dwd.dwd_sr_callcenter_workorder
where cast(dt as string) between '2024-10-01' and '2024-10-31'
    and wore_order_type=1 -- 用户异常
    and cate3_type=10 -- 评价折叠
    and status=2
) a
left join dim.dim_silkworm_staff_role_h b on a.invitee_id=b.staff_id
inner join dim.dim_silkworm_role_h c on b.role_id=c.role_id and c.role_name regexp '客服'
group by 1
;


show create table dwd.dwd_sr_callcenter_workorder_log_h;

-- 用户异常工单量分布 客服受理已完结
select
    '用户异常-多平台类型' `工单类型`,
    -- PERCENTILE_CONT(workorder_num,0.1) as `工单量10分位值`,
    -- PERCENTILE_CONT(workorder_num,0.2) as `工单量20分位值`,
    -- PERCENTILE_CONT(workorder_num,0.3) as `工单量30分位值`,
    -- PERCENTILE_CONT(workorder_num,0.4) as `工单量40分位值`,
    -- PERCENTILE_CONT(workorder_num,0.5) as `工单量50分位值`,
    -- PERCENTILE_CONT(workorder_num,0.6) as `工单量60分位值`,
    -- PERCENTILE_CONT(workorder_num,0.7) as `工单量70分位值`,
    -- PERCENTILE_CONT(workorder_num,0.8) as `工单量80分位值`,
    -- PERCENTILE_CONT(workorder_num,0.9) as `工单量90分位值`
    count(if(workorder_num=1,user_id,null)) `1单及以下用户量`,
    count(if(workorder_num=2,user_id,null)) `2单用户量`,
    count(if(workorder_num=3,user_id,null)) `3单用户量`,
    count(if(workorder_num=4,user_id,null)) `4单用户量`,
    count(if(workorder_num=5,user_id,null)) `5单用户量`,
    count(if(workorder_num>5,user_id,null)) `5单以上用户量`
from (
-- 用户异常工单次数
select
  a.user_id,
  count(distinct a.work_order_id) as workorder_num
from
(select 
    work_order_id,
    create_time,
    wore_order_type,
    cate3_type,
    invitee_id,
    user_id
from dwd.dwd_sr_callcenter_workorder
where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
    and wore_order_type=1 -- 用户异常
    and cate3_type=1 -- 1:多平台类型,10:评价折叠,7:虚假订单,60:用户反馈不符,23:全部退款
    and status=2 -- 已完结
) a
left join dim.dim_silkworm_staff_role_h b on a.invitee_id=b.staff_id
inner join dim.dim_silkworm_role_h c on b.role_id=c.role_id and c.role_name regexp '客服'
group by 1
) toa
;


=========
15天内提交的这个类型：【用户异常-用餐反馈不符】 的异常工单，涉及到用户id以及一个用户id账号下有几单此类型工单

select 
    user_id,count(order_id) as order_num
from dwd.dwd_sr_callcenter_workorder
where dt between date_sub(current_date(),interval 15 day) and date_sub(current_date(),interval 1 day)
    and wore_order_type=1 -- 用户异常
    and cate3_type=60 -- 1:多平台类型,10:评价折叠,7:虚假订单,60:用户反馈不符,23:全部退款
    -- and status=2 -- 已完结
group by 1;












