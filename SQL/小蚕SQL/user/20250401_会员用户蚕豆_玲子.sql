1、近30天，小蚕会员用户累计返佣金额（外卖、砍价、探店）；

2、近30天有下单的会员人数（外卖、砍价、探店）；

3、近30天小蚕会员累计有返佣的订单数（外卖、砍价、探店）

以上：
--订单状态取下单完成
（外卖，用户下单，但忘记上传资料而过期的订单，返佣也计算在内）
（探店、砍价，用户购买还没核销，也计算在内）


-- 会员等级MAU
select
	b.user_level `会员等级`,count(distinct a.user_id) `用户量`
from
(select unnest_bitmap as user_id from dwd.dwd_sr_traffic_viewuser_d,unnest_bitmap(user_ids) as uid
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
	group by 1) a
left join dim.dim_silkworm_member b on a.user_id=b.user_id
group by 1
;

-- MAU
select
    bitmap_union_count(user_ids) as dau
from dwd.dwd_sr_traffic_viewuser_d
where date_format(dt,'%Y-%m-%d') between date_sub(current_date(),interval 30 day) and date_sub(current_date(),interval 1 day)
;