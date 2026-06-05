with t1 as (
    select left(register_time,10) as register_date
           ,user_id
    from dim.dim_silkworm_user
    where left(register_time,10) = '${T-1}'
),

t2 as (
    select user_id
            ,order_id
           from dwd.dwd_hive_silkworm_redpack_user_red_pack
           where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) ='${T-1}'
           and redpacket_id in (232,233,234,235,236)
           -- and redpacket_use_status=2
),

t3 as (
    select service_charge 
            ,user_id
            ,order_id
            ,redpacket_amt
            ,left(order_time,10) as order_date
    from dwd.dwd_hive_silkworm_promotion_order
    where concat(year,'-',LPAD(month,2,'0'),'-',LPAD(day,2,'0')) between date_sub('${T-1}',60) and '${T-1}'
    and order_status in (2,8)
)

select a.register_date -- 注册日期
      ,count(distinct a.user_id) as register_number -- 注册用户量
         ,sum(if(order_date = register_date and t2.redpacket_use_status=2,c.redpacket_amt,0)) as  today_used_redpack_amt -- 当日使用红包金额
         ,sum(if(order_date = register_date,c.service_charge,0)) as today_income_service_charge -- 当日服务费收入
         ,count(distinct if(order_date = register_date,c.order_id,null)) as valid_order_num  -- 当日有效订单量
         ,count(distinct if(order_date = register_date,c.user_id,null)) as valid_user_num   -- 当日有效订单用户量
         ,count(distinct if(order_date = register_date and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 当日使用红包有效订单量
         ,count(distinct if(order_date = register_date and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 当日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',1) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  tomorrow_used_redpack_amt -- 次日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',1) ,c.service_charge,0)) as tomorrow_income_service_charge -- 次日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',1),c.order_id,null)) as valid_order_num  -- 次日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',1),c.user_id,null)) as valid_user_num   -- 次日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',1) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 次日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',1) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 次日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',2) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  three_days_used_redpack_amt -- 3日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',2) ,c.service_charge,0)) as three_days_income_service_charge -- 3日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',2),c.order_id,null)) as valid_order_num  -- 3日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',2),c.user_id,null)) as valid_user_num   -- 3日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',2) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 3日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',2) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 3日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',4) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  five_days_used_redpack_amt -- 5日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',4) ,c.service_charge,0)) as five_days_income_service_charge -- 5日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',4),c.order_id,null)) as valid_order_num  -- 5日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',4),c.user_id,null)) as valid_user_num   -- 5日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',4) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 5日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',4) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 5日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',6) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  seven_days_used_redpack_amt -- 7日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',6) ,c.service_charge,0)) as seven_days_income_service_charge -- 7日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',6),c.order_id,null)) as valid_order_num  -- 7日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',6),c.user_id,null)) as valid_user_num   -- 7日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',6) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 7日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',6) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 7日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',13) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  fourteen_days_used_redpack_amt -- 14日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',13) ,c.service_charge,0)) as fourteen_days_income_service_charge -- 14日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',13),c.order_id,null)) as valid_order_num  -- 14日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',13),c.user_id,null)) as valid_user_num   -- 14日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',13) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 14日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',13) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 14日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',29) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  thirty_days_used_redpack_amt -- 30日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',29) ,c.service_charge,0)) as thirty_days_income_service_charge -- 30日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',29),c.order_id,null)) as valid_order_num  -- 30日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',29),c.user_id,null)) as valid_user_num   -- 30日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',29) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 30日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',29) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 30日使用红包下单用户量
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',59) and t2.redpacket_use_status=2 ,c.redpacket_amt,0)) as  sixty_days_used_redpack_amt -- 60日使用红包金额
         ,sum(if(order_date between '${T-1}' and date_add('${T-1}',59) ,c.service_charge,0)) as sixty_days_income_service_charge -- 60日服务费收入
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',59),c.order_id,null)) as valid_order_num  -- 60日有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',59),c.user_id,null)) as valid_user_num   -- 60日有效订单用户量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',59) and t2.redpacket_use_status=2 and b.user_id is not null,c.order_id,null)) as valid_order_num  -- 60日使用红包有效订单量
         ,count(distinct if(order_date between '${T-1}' and date_add('${T-1}',59) and t2.redpacket_use_status=2 and b.user_id is not null,c.user_id,null)) as valid_user_num   -- 60日使用红包下单用户量
from t1 a
left join t2 b 
on a.user_id=b.user_id 
left join t3 c 
on b.order_id=c.order_id
group by a.register_date
