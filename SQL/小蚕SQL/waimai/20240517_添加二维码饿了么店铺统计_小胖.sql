-- 20240516 取数 小胖
-- 需求：按BD团队、BD，统计添加【饿了么店铺门店二维码】的店铺数。
-- 1）统计周期：24年5月14日到16日
-- 2）店铺状态：已审核
-- 3）平台店铺类型：包含饿了么

-- 添加饿了么店铺门店二维码店铺数
-- desc dim.dim_store

select
    bd_id,
    count(*) as `总店铺数`,
    count(if(qr_value is not null,id,null)) as `已添加店铺数`,
    count(if(qr_value is not null and qr_date between '2024-05-14' and '2024-05-16',id,null)) as `新添加店铺数`
from 
-- 添加饿了么店铺门店二维码
    (select
        id,
        bd_id,
        get_json_object(eleme_auth_shop_detail,'$.eleme_qrcode_result') AS qr_value,
        from_unixtime(get_json_object(eleme_auth_shop_detail,'$.eleme_id_ut'),'yyyy-MM-dd') AS qr_date
    from dim.dim_store
    where length(eleme_name)>1
        -- and date(created_at) between '2024-05-14' and '2024-05-16'
        and status=1 -- 已审核  0:待审核,1:已审核,2:已驳回,3:已拉黑,99:所有
    ) a
group by bd_id



-- 通过bd表中account_id 和team_account表的id找到团队名
-- wechat_scrm实例下，real_account_manager库
select
    a.`id`,
    a.account_id,
    b.name
from `team_account` as a
left join `team` as b
on a.team_id=b.id
