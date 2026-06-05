DROP VIEW IF EXISTS unite_view;
CREATE 
    VIEW IF NOT EXISTS
    unite_view (
            user_id,
            baoming_city_id,
            register_time,
            challenge_id,
            challenge_type,
            challenge_period_first_valid_order_time,
            is_new_user,
            user_level,
            create_time,
            first_takepart_invite_challenge_time,
            dt
    ) AS (
     SELECT
            t1.user_id,
            t2.baoming_city_id,
            t1.register_time,
            t2.challenge_id,
            t2.challenge_type,
            t1.challenge_period_first_valid_order_time,
            if(cast(unix_timestamp(t2.create_time) as int) < t1.register_time,1,0) as is_new_user,
            COALESCE(t3.user_level,t5.user_level) AS user_level,
            COALESCE(t3.create_time,t5.create_time) AS create_time,
            COALESCE(if(t4.first_takepart_invite_challenge_time=0,null,t4.first_takepart_invite_challenge_time),t6.first_takepart_invite_challenge_time) AS first_takepart_invite_challenge_time,
            from_unixtime(t1.challenge_period_first_valid_order_time, 'yyyy-MM-dd') AS dt
        FROM(
            SELECT
                *
            FROM
                `dim`.`dim_silkworm_challenge_silk_user_info`
            WHERE
            date_format(create_time,'yyyy-MM-dd')<'2024-09-11'
             and   inviter_takepart_id != 0
        ) AS t1
        left join
            dwd.dwd_sr_silkworm_challenge_user_promotion AS t2 --获取baoming_city_id,challenge_id,tuanzhang_id
        ON
            t1.inviter_takepart_id = t2.takepart_id
        left join
            ods.ods_sr_silkworm_challenge_register AS t3 --获取邀请人等级
        ON
            t1.inviter_takepart_id = t3.takepart_id and t1.invitor = t3.use_id
        left join
            dim.dim_silkworm_challenge_silk_user_info AS t4 --获取邀请人首次参与时间
        ON
            t1.invitor = t4.user_id
        left join
            ods.ods_sr_silkworm_challenge_register AS t5 --获取团长等级
        ON
            t2.takepart_id = t5.takepart_id and t2.tuanzhang_id = t5.use_id
        left join
            dim.dim_silkworm_challenge_silk_user_info AS t6 --获取团长首次参与时间
        ON
            t2.tuanzhang_id = t6.user_id
    );


DROP VIEW IF EXISTS order_dt;
CREATE 
    VIEW IF NOT EXISTS
    order_dt (
       
        order_num,
        lose_order_num,
        com_order_num,
        order_profit,
        lose_order_profit,
        com_order_profit,
        first_takepart_order_challenge_orders,
        challenge_id,
        user_level,
        user_id,
        takepart_order_user,
        baoming_city_id,
        dt 
    ) AS (
        SELECT
            --下单数
            sum(IF(t3.challenge_type=1,1,0)) AS order_num,
            sum(IF(t3.challenge_type=1 and final_status = 2,1,0)) AS lose_order_num,--参与下单挑战赛失败单数
            sum(IF(t3.challenge_type=1 and final_status = 1,1,0)) AS com_order_num,--参与下单挑战赛成功单数
            --订单利润
            sum(IF(t3.challenge_type=1,t1.profit/100,0)) AS order_profit,
            sum(IF(t3.challenge_type=1 and final_status = 2,t1.profit/100,0)) AS lose_order_profit,
            sum(IF(t3.challenge_type=1 and final_status = 1,t1.profit/100,0)) AS com_order_profit,
            sum(
                IF(UNIX_TIMESTAMP(t2.create_time) = t4.first_takepart_order_challenge_time and t3.challenge_type=1,1,0)
            ) AS first_takepart_order_challenge_orders,--首次参与订单挑战赛订单数量
            --挑战赛id
            t1.challenge_id,
            --用户等级
            t2.user_level,
            max(t1.use_id) as user_id,
            array_join(array_agg(IF(t3.challenge_type=1 and t4.first_order_time = unix_timestamp(t1.create_time),concat(t1.use_id,'-',t1.takepart_id),NULL)),',') AS takepart_order_user,--参与用户和活动
            --参与用户城市
            t3.baoming_city_id,
            t1.dt    
        FROM 
            ods.ods_sr_silkworm_challenge_task_detail AS t1
        left join
            ods.ods_sr_silkworm_challenge_register AS t2 --获取参加时间和等级
        ON
            t1.takepart_id = t2.takepart_id and t1.use_id = t2.use_id
        left join
            dwd.dwd_sr_silkworm_challenge_user_promotion AS t3 --获取参与城市
        ON
            t1.takepart_id = t3.takepart_id
        left join    
            `dim`.`dim_silkworm_challenge_silk_user_info` AS t4 --获取首次参与时间
        ON
            t1.use_id = t4.user_id
        GROUP BY
            t1.challenge_id,
            t2.user_level,
            t3.baoming_city_id,
            t1.dt    
    );



DROP VIEW IF EXISTS invite_dt;

CREATE 
    VIEW IF NOT EXISTS
    invite_dt (
        first_takepart_invite_challenge_new_user_num,--首次参与邀请挑战赛拉新人数
        new_user_num, --新注册用户数
        user_level,
        challenge_id,
        baoming_city_id,
        invite_user_num,--邀请有效用户
        dt   
    ) AS (
        SELECT
            sum(
                IF(UNIX_TIMESTAMP(create_time) = first_takepart_invite_challenge_time and t11.challenge_type=2,if(cast(register_time AS int) > UNIX_TIMESTAMP(create_time),1,0),0)
            ) AS first_takepart_invite_challenge_new_user_num,--首次参与邀请挑战赛拉新人数
            sum(
                if(challenge_type=2 and cast(register_time AS int) > UNIX_TIMESTAMP(create_time),1,0)
            ) AS new_user_num, --新注册用户数
            user_level AS user_level,
            challenge_id,
            baoming_city_id,
            sum(1) AS invite_user_num,--邀请有效用户
            dt   
        FROM
            unite_view AS t11
        GROUP BY
            baoming_city_id,
            challenge_id,
            user_level,
            dt
    );





DROP VIEW IF EXISTS invite_order_dt;

CREATE 
    VIEW IF NOT EXISTS
    invite_order_dt (
            user_level,
            challenge_id,
            baoming_city_id,
            order_num,--下单数量
            new_order_num,--新用户下单数量
            new_order_profit,
            order_profit,
            dt  
    ) AS (
        SELECT
            t11.user_level AS user_level,
            t11.challenge_id,
            t11.baoming_city_id,
           count(t7.order_id) AS order_num,--下单数量
           sum(IF(t11.is_new_user=1,1,0)) AS new_order_num, --新用户下单数量
           sum(IF(t11.is_new_user=1,t7.profit,0)) AS new_order_profit,
           sum(t7.profit) AS order_profit,
          t7.dt  
        FROM
            unite_view AS t11
        left join(
            SELECT
                profit,
                order_id,
                user_id,
                dt
            FROM
                dwd.dwd_sr_order_promotion_order
            WHERE
                dt > '2024-04-25'  and dt < '2024-09-11' and  order_status in (2,8)
        ) AS t7
        ON
        --下单时间在首单时间往后，首单时间7天以内,状态为已审核/已审核但用户不满意
            t7.user_id = t11.user_id and datediff(t7.dt,from_unixtime(t11.challenge_period_first_valid_order_time, 'yyyy-MM-dd')) < 7 and datediff(t7.dt,from_unixtime(t11.challenge_period_first_valid_order_time, 'yyyy-MM-dd')) >= -5 
        --创建时间与审核时间不同，导致空白期，无法找到相应订单，参考用户 311951254
        WHERE
            t7.dt is not null
        GROUP BY
            t11.user_level,
            t11.baoming_city_id,
            t11.challenge_id,
            t7.dt
    );


DROP VIEW IF EXISTS com_order_takepart;

CREATE 
    VIEW IF NOT EXISTS
    com_order_takepart (
            commander_reward,--挑战赛结束完成团长额外奖励
            baoming_city_id,
            user_level,
            challenge_id,
            dt  
    ) AS (
        SELECT
            sum(get_json_object(t2.group_detail,'$.CommanderReward')/100) AS commander_reward,--挑战赛结束完成团长额外奖励
            t1.baoming_city_id,
            t3.user_level,
            t1.challenge_id,
            t1.c_dt  
        FROM(
            SELECT
                *,
                from_unixtime(close_time, 'yyyy-MM-dd') AS c_dt
            FROM
                dwd.dwd_sr_silkworm_challenge_user_promotion
            WHERE
                final_status = 1
        ) AS t1
        left join
            dim.dim_silkworm_challenge_promotion AS t2
        ON
            t1.challenge_id = t2.challenge_id
        left join
            ods.ods_sr_silkworm_challenge_register AS t3 --获取首次参与时间,等级
        ON
            t1.takepart_id = t3.takepart_id and t1.tuanzhang_id = t3.use_id
        GROUP BY
            t1.c_dt,
            t1.baoming_city_id,
            t3.user_level,
            t1.challenge_id

    );






select 
--   sum(order_num),
--   sum(order_profit),
--   sum(lose_order_profit),
--   sum(com_order_profit),
--   sum(new_order_num),
--   sum(new_order_profit),
--   sum(invite_user_num),
--   sum(first_takepart_order_challenge_orders),
--   sum(first_takepart_invite_challenge_new_user_num),
--   sum(lose_order_num),
--   sum(com_order_num),
--   sum(takepart_order_user),
--   sum(new_user_num),
--   sum(commander_reward)
count(*) -- 数据量：
from 
(
-- 7月数据量：34944
select
    dt,
    challenge_id,
    baoming_city_id,
    user_level,
    order_num, --订单数量
    order_profit, --订单利润
    first_takepart_order_challenge_orders, --第一次参与订单挑战赛下单数量
    lose_order_num,
    com_order_num,
    takepart_order_user, --参与下单挑战赛并且下单的列表
    lose_order_profit,
    com_order_profit,
    0 as new_order_num,--新用户单量
    0 as new_order_profit,--新用户利润
    0 as commander_reward,
    0 as invite_user_num, --有效邀请用户数量
    0 as first_takepart_invite_challenge_new_user_num, --第一次参与邀请挑战赛拉新数量
    0 as new_user_num --新注册用户数
from
    order_dt

-- union all

-- 7月数据量：20726
-- select
--     dt,
--     challenge_id,
--     baoming_city_id,
--     user_level,
--     order_num, --订单数量
--     order_profit, --订单利润
--     0 as first_takepart_order_challenge_orders, --第一次参与订单挑战赛下单数量
--     0 as lose_order_num,
--     0 as com_order_num,
--     0 as takepart_order_user, --参与下单挑战赛并且下单的列表
--     0 as lose_order_profit,
--     0 as com_order_profit,
--     new_order_num,--新用户单量
--     new_order_profit,--新用户利润
--     0 as commander_reward,
--     0 as invite_user_num, --有效邀请用户数量
--     0 as first_takepart_invite_challenge_new_user_num, --第一次参与邀请挑战赛拉新数量
--     0 as new_user_num --新注册用户数
-- from 
--     invite_order_dt

union all
-- 7月数据量：16357
select
    dt,
    challenge_id,
    baoming_city_id,
    user_level,
    0 as order_num, --订单数量
    0 as order_profit, --订单利润
    0 as first_takepart_order_challenge_orders, --第一次参与订单挑战赛下单数量
    0 as lose_order_num,
    0 as com_order_num,
    0 as takepart_order_user, --参与下单挑战赛并且下单的列表
    0 as lose_order_profit,
    0 as com_order_profit,
    0 as new_order_num,--新用户单量
    0 as new_order_profit,--新用户利润
    commander_reward, --挑战赛完成奖励
    0 as invite_user_num, --有效邀请用户数量
    0 as first_takepart_invite_challenge_new_user_num, --第一次参与邀请挑战赛拉新数量
    0 as new_user_num --新注册用户数
from com_order_takepart

-- union all

-- 7月数据量：12793
-- select
--     dt,
--     challenge_id,
--     baoming_city_id,
--     user_level,
--     0 as order_num, --订单数量
--     0 as order_profit, --订单利润
--     0 as first_takepart_order_challenge_orders, --第一次参与订单挑战赛下单数量
--     0 as lose_order_num,
--     0 as com_order_num,
--     0 as takepart_order_user, --参与下单挑战赛并且下单的列表
--     0 as lose_order_profit,
--     0 as com_order_profit,
--     0 as new_order_num,--新用户单量
--     0 as new_order_profit,--新用户利润
--     0 as commander_reward, --挑战赛完成奖励
--     invite_user_num, --有效邀请用户数量
--     first_takepart_invite_challenge_new_user_num, --第一次参与邀请挑战赛拉新数量
--     new_user_num --新注册用户数
-- from invite_dt
) tot
where dt between '2024-07-01' and '2024-07-31'