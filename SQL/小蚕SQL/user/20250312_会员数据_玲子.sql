1、基础信息：会员等级下用户量、性别、年龄、城市、注册时长（全量会员数据）
2、霸王餐订单利润贡献（排除饿了么专版订单）（取最近1年、最近一个月 分会员等级）
3、拉新贡献（取最近1年、取最近一个月数据 分会员等级）
4、权益成本：红包、抽奖奖品（大牌券、复活券、蚕豆）、VIP额外返利（取最近1年、取最近一个月数据 分会员等级）
5、下单行为：周下单用户占比、周消费频次、周下单利润 （取最近一个月 分会员等级）


select
    '${T-1}' as dt,
    count(if((LENGTH(bind_interior_staff_wework_account)<2) and a.user_level=1,a.user_id,null)) `V0用户量`,
    count(if( LENGTH(bind_interior_staff_wework_account)>2 and a.user_level=1,a.user_id,null)) `V1用户量`,
    count(if(a.user_level=2,a.user_id,null)) `V2用户量`,
    count(if(a.user_level=3,a.user_id,null)) `V3用户量`,
    count(if(a.user_level=4,a.user_id,null)) `V4用户量`,
    count(if(a.user_level=5,a.user_id,null)) `V5用户量`
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b
on a.user_id=b.user_id
-- left join dim_city on a.city_id=dim_city.city_id
-- where dim_city.city_name in ('杭州市','上海市','成都市','南京市','广州市','深圳市')
-- group by 1


-- 注册日期距今天数分布
select
    min(register_parse) as min_val,
    percentile_cont(register_parse,0.1) as 10_val,
    percentile_cont(register_parse,0.2) as 20_val,
    percentile_cont(register_parse,0.3) as 30_val,
    percentile_cont(register_parse,0.4) as 40_val,
    percentile_cont(register_parse,0.5) as 50_val,
    percentile_cont(register_parse,0.6) as 60_val,
    percentile_cont(register_parse,0.7) as 70_val,
    percentile_cont(register_parse,0.8) as 80_val,
    percentile_cont(register_parse,0.8) as 90_val,
    max(register_parse) as max_val
from
(select 
    user_id,
    register_time,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender,
    coalesce(year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)),'未知') as age,
    date_diff('day',current_date(),date_format(register_time,'%Y-%m-%d')) as register_parse
from dim.dim_silkworm_user
) a
;


========== part 1 基础信息
select
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as `用户等级`,
    gender AS `性别`,
    case when age='未知' as '未知'
        when age <18 then '18岁以下'
        when age between 18 and 22 then '18-22岁'
        when age between 23 and 27 then '23-27岁'
        when age between 28 and 32 then '28-32岁'
        when age between 33 and 37 then '33-37岁'
        when age between 38 and 42 then '38-42岁'
        when age between 43 and 47 then '43-47岁'
        when age >=48 then '48岁及以上'
    end as `年龄`,
    c.province_name `省份`,
    c.city_name `城市`,
    case when register_parse<=7 then '7天内'
        when register_parse between 8 and 15 then '8-15天'
        when register_parse between 16 and 30 then '16-30天'
        when register_parse between 31 and 60 then '31-60天'
        when register_parse between 61 and 90 then '61-90天'
        when register_parse between 91 and 180 then '90-180天'
        when register_parse between 181 and 365 then '181-365天'
        when register_parse between 366 and 730 then '366-730天'
        when register_parse>=721 then '2年以上'
    end as `注册时长`,
    count(distinct a.user_id) as `用户量`
from dim.dim_silkworm_member a
left join 
-- 注册用户
(select 
    user_id,
    register_time,
    case if(length(user_id_num)=18, cast(substring(user_id_num,17,1) as UNSIGNED)%2, if(length(user_id_num)=15,cast(substring(user_id_num,15,1) as UNSIGNED)%2,3))
            when 1 then '男'
            when 0 then '女'
    else '未知' end AS gender,
    coalesce(year(curdate())-if(length(user_id_num)=18,substring(user_id_num,7,4),if(length(user_id_num)=15,concat('19',substring(user_id_num,7,2)),null)),'未知') as age,
    date_diff('day',current_date(),date_format(register_time,'%Y-%m-%d')) as register_parse
from dim.dim_silkworm_user
) b on a.user_id=b.user_id
left join dim.dim_silkworm_county c on b.county_id=c.county_id
group by 1,2,3,4,5,6;


======= part 2 霸王餐订单利润贡献（排除饿了么专版订单）（取最近1年、最近一个月）
drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);


-- 霸王餐订单
select
    b.user_lvl `会员等级`,
    count(distinct if(b.user_id is not null,a.user_id,null)) as `报名用户量`,
    count(distinct if(b.user_id is not null and a.order_status in (2,8),a.user_id,null)) as `完单用户量`,
    count(if(b.user_id is not null,a.auto_id,null)) as `报名订单量`,
    count(distinct if(b.user_id is not null and a.order_status in (2,8),a.auto_id,null)) as `完单量`,
    sum(if(b.user_id is not null and a.order_status=2,a.profit,0)) as `完单利润`
from dwd.dwd_sr_order_promotion_order a
left join member_info b on a.user_id=b.user_id
where date_format(a.dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
    and date_format(a.order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
group by 1;


-- 拉新
select
    a.user_lvl `会员等级`,
    count(distinct b.user_id) as `拉新用户量`
from member_info a left join dim.dim_silkworm_user b 
on a.user_id=b.inviter_user_id
    and date_format(b.register_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
group by 1
;



======= part3 权益成本
-- 权益
select
    activity_type,
    gift_id,
    gift_name,
    is_get,
    count(1) as `发放红包量`,
    sum(gift_num/100) as `红包返豆金额`
from dwd.dwd_sr_market_rpd_lottery_winning_record
where dt between date_sub(current_date(),interval 3000 day) and date_sub(current_date(),interval 1 day)
group by 1,2,3,4;


--------- 1 红包使用
drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);

drop view if exists rpused_info;
create view if not exists rpused_info (
    auto_ordere_id,order_id,user_id
) as (
select
    auto_ordere_id,
    order_id,
    user_id
from dwd.dwd_sr_market_redpack_use_record
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and auto_ordere_id<>0
);


-- 霸王餐订单
drop view if exists bwc_order;
create view if not exists bwc_order (
    user_id,order_id,auto_id,order_status,redpacket_amt,profit,order_time
) as (
select
    user_id,right(order_id,9) as order_id,auto_id,order_status,redpacket_amt,profit,order_time
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
    and date_format(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
    );


-- 用户信息
drop view if exists user_info;
create view if not exists user_info (
    auto_ordere_id,order_id,user_id,user_lvl
) as (
select
    auto_ordere_id,order_id,rpused_info.user_id,b.user_lvl
from rpused_info left join member_info b on rpused_info.user_id=b.user_id
);

-- 霸王餐使用红包金额
select
    user_info.user_lvl `会员等级`,
    sum(a.redpacket_amt) as `红包返豆金额`,
    sum(if(a.order_status=2,profit,0)) as `订单利润`
from user_info inner join bwc_order a 
on user_info.auto_ordere_id=a.order_id 
group by 1
;



------ 2 蚕豆
drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);

drop view if exists get_candou;
create view if not exists get_candou (
    user_id,candou_amt
) as (
select
    user_id,
    sum(gift_num/100) as candou_amt
from dwd.dwd_sr_market_rpd_lottery_winning_record
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and gift_name regexp '蚕豆'
    and is_get=2 -- 已领取
group by 1
);

select
    member_info.user_lvl `会员等级`,
    sum(candou_amt) as `蚕豆发放金额(元)`
from member_info inner join get_candou a 
on member_info.user_id=a.user_id 
group by 1
;




------ 3 VIP额外返利
-- drop view if exists member_info;
-- create view if not exists member_info (
--     user_id,user_lvl
-- ) as (
-- select a.user_id,
--     case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
--         when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
--         when a.user_level=2 then 'V2'
--         when a.user_level=3 then 'V3'
--         when a.user_level=4 then 'V4'
--         when a.user_level=5 then 'V5'
--     else '其他' end as user_lvl
-- from dim.dim_silkworm_member a
-- left join dim.dim_silkworm_user b on a.user_id=b.user_id
-- );


-- -- vip额外返利金额
-- drop view if exists vip_info;
-- create view if not exists vip_info (
--         user_id,
--     order_id,
--     extra_rebate
-- ) as (
-- select 
--     user_id,
--     order_id,
--     extra_rebate
-- from dwd.dwd_sr_user_member_task_rebate_log
-- where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
--     and length(order_id)>10
-- );


-- -- 霸王餐订单
-- drop view if exists bwc_order;
-- create view if not exists bwc_order (
--     user_id,order_id,auto_id,order_status,redpacket_amt,profit,order_time
-- ) as (
-- select
--     user_id,order_id,auto_id,order_status,redpacket_amt,profit,order_time
-- from dwd.dwd_sr_order_promotion_order
-- where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
--     and date_format(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
--     and order_status in (2,8)
--     );


-- -- 霸王餐使用红包金额
-- select
--     c.user_lvl `会员等级`,
--     sum(if(a.order_id is not null,vip_info.extra_rebate,0)) as `VIP返利金额`
-- from vip_info inner join bwc_order a 
-- on vip_info.order_id=a.order_id
-- left join member_info c on a.user_id=c.user_id
-- group by 1
-- ;

-- 已使用的卡券
drop view if exists t1;
create view if not exists t1 (
    card_type,key_id,card_id,used_time,user_id
) as (
select  card_type  -- 3:大牌专享券 7:订单复活券 8:vip额外返利券
        ,key_id     -- 订单id 
        ,card_id    -- 券id 
        ,used_time  -- 使用时间
        ,user_id
from dwd.dwd_sr_market_rights_card 
where card_status = 1      -- 0:未使用 1:已使用 2:已失效 
and card_type in (3,7,8) -- 3:大牌专享券 7:订单复活券 8:vip额外返利券
and date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
group by 1,2,3,4,5
);


-- -- 霸王餐订单
drop view if exists t2;
create view if not exists t2 (
    user_id,order_id,auto_id,order_status,redpacket_amt,profit,order_time
) as (
select
    user_id,order_id,auto_id,order_status,redpacket_amt,profit,order_time
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
    and date_format(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and order_status in (2,8)
    );


-- vip额外返利金额
drop view if exists t3;
create view if not exists t3 (
    order_id_substr,extra_rebate
) as (

select right(order_id,9) as order_id_substr
      ,extra_rebate
from dwd.dwd_sr_user_member_task_rebate_log
where dt between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
);

-- 会员信息
drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);

-- 额外返利
select member_info.user_lvl `会员等级`
      ,sum(case when t3.order_id_substr is not null then extra_rebate end) as `近365天VIP额外返利`   -- vip券支出
from t1 
join t2 
on t1.key_id = t2.auto_id
left join t3 
on t1.key_id = t3.order_id_substr
left join member_info on t1.user_id=member_info.user_id
group by 1;




============ part4 周下单用户占比、频次、利润
drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);


-- 霸王餐订单

select
    c.user_lvl,
    b.week_of_year,
    count(distinct if(c.user_id is not null and a.order_status in (2,8),a.user_id,null)) as `完单用户量`,
    count(distinct if(c.user_id is not null and a.order_status in (2,8),a.auto_id,null)) as `完单量`,
    sum(if(c.user_id is not null and a.order_status=2,a.profit,0)) as `完单利润`

from
    (select
        user_id,
        auto_id,
        order_status,
        redpacket_amt,
        profit,
        date_format(order_time,'%Y-%m-%d') as dat
    from dwd.dwd_sr_order_promotion_order
    where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 45 day) and date_sub(current_date(),interval 1 day)
        and date_format(order_time,'%Y-%m-%d') between '2025-02-10' and '2025-03-09' -- 取4周，排除春节假期
        ) a
left join dim.dim_silkworm_date b on a.dat=b.current_date_txt and b.current_date_txt between '2025-02-10' and '2025-03-09'
left join member_info c on a.user_id=c.user_id
group by 1,2;


============ part5 会员拉新利润
drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);


-- 霸王餐订单
drop view if exists bwc_order;
create view if not exists bwc_order (
    user_id,profit
) as (
select
    user_id,sum(profit) as profit
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
    and date_format(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and order_status=2
group by 1
    );


-- 拉新
select
    a.user_lvl `会员等级`,
    count(distinct b.user_id) as `拉新用户量`,
    sum(profit) as `近365天拉新用户利润`
from member_info a left join dim.dim_silkworm_user b 
on a.user_id=b.inviter_user_id
    and date_format(b.register_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
left join bwc_order c on b.user_id=c.user_id
group by 1
;


=========== part6 自然新增用户利润
-- 霸王餐订单
drop view if exists bwc_order;
create view if not exists bwc_order (
    user_id,profit
) as (
select
    user_id,sum(profit) as profit
from dwd.dwd_sr_order_promotion_order
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
    and date_format(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and order_status=2
group by 1
    );


-- 自然增长新客
select
    count(a.user_id) as '新用户量',
    sum(b.profit) as `近365天新用户利润`
from dim.dim_silkworm_user a
left join bwc_order b 
on a.user_id=b.user_id 
    and date_format(a.register_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
    and a.inviter_user_id=0
;




========== part 7 拉新成本
拉新数据，奖励拉新者、本拉新者，分别的成本（30天、365天实际支出）

drop view if exists member_info;
create view if not exists member_info (
    user_id,user_lvl
) as (
select a.user_id,
    case when length(bind_interior_staff_wework_account)<2 and a.user_level=1 then 'V0'
        when length(bind_interior_staff_wework_account)>2 and a.user_level=1 then 'V1'
        when a.user_level=2 then 'V2'
        when a.user_level=3 then 'V3'
        when a.user_level=4 then 'V4'
        when a.user_level=5 then 'V5'
    else '其他' end as user_lvl
from dim.dim_silkworm_member a
left join dim.dim_silkworm_user b on a.user_id=b.user_id
);


-- 团长拉新支出
drop view if exists rp_info;
create view if not exists rp_info (
    redpack_id
) as (
-- 红包ID
select
     cast(get_json_string(value, "$.red_pack_id") as int) redpack_id
from
    (
    select * from dwd.dwd_sr_user_newuser_reward_record,JSON_EACH(PARSE_JSON(redpack_info)) as unnest
    ) t1
group by 1

union 

-- 取包红包的红包id
-- 红包ID：265
select 
     cast(get_json_string(before_fst_order_info, "$[0].red_pack_id") as int) red_pack_id
from
    dwd.dwd_sr_user_newuser_wrp_get_record
group by 1
);


-- 统计红包使用金额
drop view if exists rp_amt;
create view if not exists rp_amt (
    user_id,newuser_redpack_amt,tuanzhang_bhb_amt
)
as (   
select
    user_id,
    sum(if(b.order_id is not null and a.redpacket_id not in (265,268,269),b.redpacket_amt,0)) as newuser_redpack_amt,
    sum(if(b.order_id is not null and a.redpacket_id in (265,268,269),b.redpacket_amt,0)) as tuanzhang_bhb_amt
from (
    select 
        redpacket_id,auto_ordere_id,order_id,user_id
        from dwd.dwd_sr_market_redpack_use_record
        where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
            and redpacket_id in (select redpack_id from rp_info)
            and redpacket_use_status=2 -- 已使用
    ) a 
left join (
    select 
        order_id,
        redpacket_amt
    from dwd.dwd_sr_order_promotion_order 
    where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
        and date_format(order_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
        and order_status in (2,8)
        ) b on a.order_id=b.order_id
group by 1
);

-- 有包红包权益新用户
drop view if exists bhb_info;
create view if not exists bhb_info (
    user_id,user_type
)
as (  
select user_id,'包红包用户' as user_type
from dwd.dwd_sr_market_redpack_use_record
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 400 day) and date_sub(current_date(),interval 1 day)
    and redpacket_id in (265,268,269)
group by 1,2);

-- 团长拉新用户信息
drop view if exists newuser_info;
create view if not exists newuser_info (
    inviter_user_id,tuanzhang_newuser_amt
) as (
select inviter_user_id,sum(case when accu_valid_order_num=1 then 3 when accu_valid_order_num>=2 then 10 else 0 end) as tuanzhang_newuser_amt
from dim.dim_silkworm_user a
left join bhb_info b on a.user_id=b.user_id
where a.inviter_user_id>0
    and date_format(a.register_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
group by 1
);


select
    a.user_lvl `会员等级`,
    sum(newuser_redpack_amt) as `新人免单红包支出`,
    sum(if(c.user_type='包红包用户',b.tuanzhang_bhb_amt,0)) as `团长包红包支出`,
    sum(if(c.user_id is null and d.inviter_user_id is not null,d.tuanzhang_newuser_amt,0)) as `团长拉新支出`
from member_info a left join rp_amt b on a.user_id=b.user_id
left join bhb_info c on a.user_id=c.user_id
left join newuser_info d on a.user_id=d.inviter_user_id
group by 1
;


-- 拉新有效用户
select count(1) as tot_newuser_num,count(if(accu_valid_order_num>=1,user_id,null)) as valid_newuser_num
from dim.dim_silkworm_user
where inviter_user_id>0
    and date_format(register_time,'%Y-%m-%d') between date_sub(current_date(),interval 365 day) and date_sub(current_date(),interval 1 day)
group by 1;





































