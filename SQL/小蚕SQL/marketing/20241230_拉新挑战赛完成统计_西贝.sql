dws_sr_challenge_user_promotion_stage_task


`com_user_list` ARRAY<string> comment'完成用户去重复',
dws_sr_silkworm_challenge_td
dws_sr_silkworm_challenge_td用户挑战赛按日汇总sr


CREATE 
    VIEW IF NOT EXISTS
        task_user_information (
            challenge_id, 
            current_stage, 
            takepart_id,             
            stage_finished_reward,
            stage_finish_reward,
            current_progress,
            baoming_city_id,
            user_length,
            close_time,
            final_status,
            dt,
            rewardNum,
            cardType,
            rewardType,
            expectNum,
            stage,
            tag,
            user_id,
            level
        ) AS (
        SELECT
            challenge_id,
            current_stage,
            takepart_id,
            stage_finished_reward,
            stage_finish_reward,
            current_progress,
            baoming_city_id,
            json_length(parse_json(group_user_id_list)) as user_length,
            close_time,
            final_status,
            dt,
            rewardNum,
            cardType,
            rewardType,
            expectNum,
            stage,
            tag,
            user_id,
            get_json_int(value,'$.Level') as level
        FROM(
            SELECT 
                challenge_id,
                current_stage,
                takepart_id,
                stage_finished_reward,
                stage_finish_reward,
                current_progress,
                baoming_city_id,
                group_user_id_list,
                close_time,
                final_status,
                dt,
                get_json_int(value,'$.RewardNum') as rewardNum,
                get_json_int(value,'$.CardType') as cardType,
                get_json_int(value,'$.RewardType') as rewardType,
                get_json_int(value,'$.ExpectNum') as expectNum,
                get_json_int(value,'$.Stage') as stage,
                `key` as tag,
                 get_json_int(value,'$.SilkId') AS user_id
            FROM 
                dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(stage_task)) AS t1111
        where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
        ) as t111,json_each(parse_json(group_user_id_list)) AS t222
    );



CREATE 
    VIEW  IF NOT EXISTS
        user_reward_information (
            reward_value,
            challenge_id,
            user_id,
            baoming_city_id,
            level,
            dt
        ) AS (
        SELECT
            sum(reward_value) AS reward_value,
            challenge_id,
            user_id,
            baoming_city_id,
            level,
            dt
        FROM(
            SELECT
                challenge_id,
                user_id,
                baoming_city_id,
                CASE
                    WHEN expectNum > current_progress THEN 0
                    WHEN rewardType = 1 THEN rewardNum/user_length
                    WHEN rewardType = 2 and cardType = 3 THEN 1000/user_length
                    WHEN rewardType = 3 THEN rewardNum/user_length
                    WHEN rewardType = 4 THEN 0
                END AS reward_value,
                level,
                from_unixtime(get_json_object(stage_finished_reward,concat('$[',IF(stage > 0,stage,tag),']')), 'yyyy-MM-dd') AS dt
            FROM
                task_user_information
        ) AS t1
        where
            dt is not null
        GROUP BY
            challenge_id,
            user_id,
            baoming_city_id,
            level,
            dt
    );



=========================
-- 完成拉新挑战赛用户
-- 共21,931人
select
    user_id,
    count(challenge_id) as finished_num
from
-- 近90天拉新挑战赛完成用户
(select 
    challenge_id,
    com_user_list,
    unnest as user_id
from dws.dws_sr_silkworm_challenge_td,unnest(com_user_list) AS unnest
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and challenge_type=2 -- 1:下单,2:邀请
) a
group by 1;



-- 参与用户
select
    challenge_id,
    get_json_int(value,'$.SilkId') AS user_id
from dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(group_user_id_list)) as user_id_list
where dt=date_sub(current_date(),interval 1 day)
    and challenge_type=2



============= 正式跑数
drop table if exists user_info;

create view if not exists user_info (
	user_id,
	finished_num
) as (
select
    user_id,
    count(challenge_id) as finished_num
from
-- 近90天拉新挑战赛完成用户
(select 
    challenge_id,
    com_user_list,
    unnest as user_id
from dws.dws_sr_silkworm_challenge_td,unnest(com_user_list) AS unnest
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
    and challenge_type=2 -- 1:下单,2:邀请
) a
group by 1);


drop view if exists task_user_information;
CREATE 
    VIEW IF NOT EXISTS
        task_user_information (
            challenge_id, 
            current_stage, 
            takepart_id,             
            stage_finished_reward,
            stage_finish_reward,
            current_progress,
            baoming_city_id,
            user_length,
            close_time,
            final_status,
            dt,
            rewardNum,
            cardType,
            rewardType,
            expectNum,
            stage,
            tag,
            level,
            user_id
        ) AS (
        SELECT
            challenge_id,
            current_stage,
            takepart_id,
            stage_finished_reward,
            stage_finish_reward,
            current_progress,
            baoming_city_id,
            json_length(parse_json(group_user_id_list)) as user_length,
            close_time,
            final_status,
            dt,
            rewardNum,
            cardType,
            rewardType,
            expectNum,
            stage,
            tag,
            get_json_int(value,'$.Level') as level,
            get_json_int(value,'$.SilkId') AS user_id
        FROM(
            SELECT 
                challenge_id,
                current_stage,
                takepart_id,
                stage_finished_reward,
                stage_finish_reward,
                current_progress,
                baoming_city_id,
                group_user_id_list,
                close_time,
                final_status,
                dt,
                get_json_int(value,'$.RewardNum') as rewardNum,
                get_json_int(value,'$.CardType') as cardType,
                get_json_int(value,'$.RewardType') as rewardType,
                get_json_int(value,'$.ExpectNum') as expectNum,
                get_json_int(value,'$.Stage') as stage,
                `key` as tag
            FROM 
                dwd.dwd_sr_silkworm_challenge_user_promotion,json_each(parse_json(stage_task)) AS t1111
        where dt between date_sub(current_date(),interval 180 day) and date_sub(current_date(),interval 1 day)
        	and challenge_type=2
        ) as t111,json_each(parse_json(group_user_id_list)) AS t222
    );

drop view if exists user_reward_information;

CREATE 
    VIEW  IF NOT EXISTS
        user_reward_information (
            reward_value,
            challenge_id,
            user_id,
            baoming_city_id,
            level,
            dt
        ) AS (
        SELECT
            sum(reward_value) AS reward_value,
            challenge_id,
            user_id,
            baoming_city_id,
            level,
            dt
        FROM(
            SELECT
                challenge_id,
                user_id,
                baoming_city_id,
                CASE
                    WHEN expectNum > current_progress THEN 0
                    WHEN rewardType = 1 THEN rewardNum/user_length
                    WHEN rewardType = 2 and cardType = 3 THEN 1000/user_length
                    WHEN rewardType = 3 THEN rewardNum/user_length
                    WHEN rewardType = 4 THEN 0
                END AS reward_value,
                level,
                from_unixtime(get_json_object(stage_finished_reward,concat('$[',IF(stage > 0,stage,tag),']')), 'yyyy-MM-dd') AS dt
            FROM
                task_user_information
        ) AS t1
        where
            dt is not null
        GROUP BY
            challenge_id,
            user_id,
            baoming_city_id,
            level,
            dt
    );


drop view if exists reward_info;

create view if not exists reward_info (
	user_id,reward_amt
) as (
select
	user_id,
	sum(reward_value)/100 as reward_amt
from user_reward_information
where dt between date_sub(current_date(),interval 90 day) and date_sub(current_date(),interval 1 day)
group by 1)
;

select
	user_info.user_id,
	user_info.finished_num `完成次数`,
	reward_info.reward_amt `返豆金额`
from user_info
left join reward_info on user_info.user_id=reward_info.user_id
;






































