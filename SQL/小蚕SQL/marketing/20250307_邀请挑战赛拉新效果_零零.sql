-- 挑战赛ID：443 呼朋赚豆团长赛  7天新增2名有效团员，可获得15蚕豆

-- 人群：当前有效团员<2
-- 

-- 挑战赛拉新
select
        -- date_format(dt,'%Y-%m-%d') as `统计日期`,
        challenge_id,
        challenge_name,
        array_length(array_unique_agg(par_user_list)) as `参与用户量`,
        sum(order_num_dt) as `完单量`,
        sum(new_user_num) as `拉新用户量`
    from dws.dws_sr_silkworm_challenge_td
    where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
        and challenge_id=443 --2月22日开始
    group by 1,2
;


=============== 正式跑数

drop view if exists tk_user;
create view if not exists tk_user (
    tk_user_id
) as (
select
        unnest as tk_user_id
from dws.dws_sr_silkworm_challenge_td,unnest(par_user_list) as unnest
where date_format(dt,'%Y-%m-%d') between '2025-02-22' and date_sub(current_date(),interval 1 day)
    and challenge_id=443 --2月22日开始
group by 1
    );


-- 注册用户
drop view if exists register_info;
create view if not exists register_info (
    register_time,user_id,inviter_user_id,first_valid_order_time
) as (
select
    register_time,
    user_id,
    inviter_user_id,
    first_valid_order_time
from dim.dim_silkworm_user
);



-- 团长拉新用户量分布
-- select
--     PERCENTILE_CONT(newuser_num,0.1) as 10_newuser_num, -- 1
--     PERCENTILE_CONT(newuser_num,0.2) as 20_newuser_num, -- 1
--     PERCENTILE_CONT(newuser_num,0.3) as 30_newuser_num, -- 1
--     PERCENTILE_CONT(newuser_num,0.4) as 40_newuser_num, -- 2
--     PERCENTILE_CONT(newuser_num,0.5) as 50_newuser_num, -- 2
--     PERCENTILE_CONT(newuser_num,0.6) as 60_newuser_num, -- 3
--     PERCENTILE_CONT(newuser_num,0.7) as 70_newuser_num, -- 4
--     PERCENTILE_CONT(newuser_num,0.8) as 80_newuser_num, -- 6
--     PERCENTILE_CONT(newuser_num,0.9) as 90_newuser_num, -- 10
--     PERCENTILE_CONT(newuser_num,0.95) as 95_newuser_num, -- 15
--     PERCENTILE_CONT(newuser_num,0.98) as 98_newuser_num, -- 27

--     PERCENTILE_CONT(valid_newuser_num,0.1) as 10_valid_newuser_num, -- 0
--     PERCENTILE_CONT(valid_newuser_num,0.2) as 20_valid_newuser_num, -- 0
--     PERCENTILE_CONT(valid_newuser_num,0.3) as 30_valid_newuser_num, -- 0
--     PERCENTILE_CONT(valid_newuser_num,0.4) as 40_valid_newuser_num, -- 1
--     PERCENTILE_CONT(valid_newuser_num,0.5) as 50_valid_newuser_num, -- 1
--     PERCENTILE_CONT(valid_newuser_num,0.6) as 60_valid_newuser_num, -- 1
--     PERCENTILE_CONT(valid_newuser_num,0.7) as 70_valid_newuser_num, -- 2
--     PERCENTILE_CONT(valid_newuser_num,0.8) as 80_valid_newuser_num, -- 3
--     PERCENTILE_CONT(valid_newuser_num,0.9) as 90_valid_newuser_num, -- 5
--     PERCENTILE_CONT(valid_newuser_num,0.95) as 95_valid_newuser_num, -- 7
--     PERCENTILE_CONT(valid_newuser_num,0.98) as 98_valid_newuser_num -- 11
-- from
-- (select
--     inviter_user_id,
--     count(user_id) as newuser_num,
--     count(if(date_format(first_valid_order_time,'%Y-%m-%d')<>'1970-01-01',user_id,null)) as valid_newuser_num
-- from register_info
-- where date_format(register_time,'%Y-%m-%d')<'2025-02-22'
-- group by inviter_user_id
-- ) a

-- 参与挑战赛团长拉新用户量
drop view if exists tuanzhang_info;
create view if not exists tuanzhang_info (
    inviter_user_id,newuser_num,valid_newuser_num
)
as(
select
    inviter_user_id,
    count(user_id) as newuser_num,
    count(if(date_format(first_valid_order_time,'%Y-%m-%d')<='2025-01-13',user_id,null)) as valid_newuser_num
from register_info a
inner join tk_user b on a.inviter_user_id=b.tk_user_id
where date_format(register_time,'%Y-%m-%d') between '2025-01-04' and '2025-01-13'
group by inviter_user_id
);




select
    c.valid_newuser_num,
    count(distinct a.tk_user_id) as `参与用户量`,
    count(distinct if(date_format(b.register_time,'%Y-%m-%d') between '2025-01-04' and '2025-01-13',b.user_id,null)) as `参与前拉新用户量`,
    count(distinct if((date_format(b.register_time,'%Y-%m-%d') between '2025-01-04' and '2025-01-13') and date_format(b.first_valid_order_time,'%Y-%m-%d')<='2025-01-13',b.user_id,null)) as `参与前有效拉新用户量`,
    count(distinct if(date_format(b.register_time,'%Y-%m-%d') between '2025-02-22' and date_sub(current_date(),interval 1 day),b.user_id,null)) as `参与后拉新用户量`,
    count(distinct if((date_format(b.register_time,'%Y-%m-%d') between '2025-02-22' and date_sub(current_date(),interval 1 day)) 
        and date_format(b.first_valid_order_time,'%Y-%m-%d')<'2025-02-22',b.user_id,null)) as `参与后有效拉新用户量`
from tk_user a left join register_info b on a.tk_user_id=b.inviter_user_id
left join tuanzhang_info c on a.tk_user_id=c.inviter_user_id
group by 1
;























