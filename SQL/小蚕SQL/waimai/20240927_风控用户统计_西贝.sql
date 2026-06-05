============================
-- 用户封禁原因
show create table dim.dim_user_rcs;

select * from dim.dim_user_rcs limit 10;

select silk_id,app_device_info from dim.dim_user_rcs
where silk_id=923592157;

deviceLabels.device_suspicious_labels.b_adb_enable
deviceLabels.device_suspicious_labels.b_debuggable
deviceLabels.device_suspicious_labels.b_alter_loc
deviceLabels.device_suspicious_labels.b_root
deviceLabels.device_suspicious_labels.b_hook
deviceLabels.device_suspicious_labels.b_acc
deviceLabels.device_suspicious_labels.b_sim

select silk_id,app_device_info,get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_adb_enable') as k from dim.dim_user_rcs
where silk_id=923592157;

-- 获取用户封禁信息
SELECT silk_id,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_adb_enable') as b_adb_enable,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_debuggable') as b_debuggable,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_alter_loc') as b_alter_loc,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_root') as b_root,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_hook') as b_hook,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_acc') as b_acc,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_sim') as b_sim
FROM 
    dim.dim_user_rcs
where silk_id=923592157;


-- 造出数据集
-- 取出最后一层key和value
select
    silk_id,
    app_device_info, 
    parent_key, 
    parent_val,
    sub_key,
    sub_val,
    t4.`key` as j_key, 
    t4.value as j_val 
from
-- 取出第二层key和value
(select
    a.silk_id,
    a.app_device_info, 
    a.j_key as parent_key, 
    a.j_val as parent_val,
    t3.`key` as sub_key, 
    t3.value as sub_val 
from
-- 取出第一层key和value
(SELECT tj.silk_id,
    tj.app_device_info, 
    t2.`key` as j_key, 
    t2.value as j_val 
FROM dim.dim_user_rcs as tj, LATERAL JSON_EACH(app_device_info) as t2
where tj.silk_id=923592157) a,LATERAL JSON_EACH(j_val) as t3
where j_key='deviceLabels') b,LATERAL JSON_EACH(sub_val) as t4
where sub_key='device_suspicious_labels'
;

-- 数据量：116362 用户量：116362
select count(*) as cnt,count(distinct user_id) as cnt2 from dim.dim_risk_newuser;

select user_id from dwd.dwd_sr_market_rpd_lottery_winning_record
where dt=date_sub(current_date(),interval 1 day)
    and activity_type=1

-- 正式取数
with t as (
SELECT silk_id,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_adb_enable') as b_adb_enable,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_debuggable') as b_debuggable,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_alter_loc') as b_alter_loc,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_root') as b_root,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_hook') as b_hook,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_acc') as b_acc,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_sim') as b_sim
FROM 
    dim.dim_user_rcs
)

select
    count(distinct if(t.b_adb_enable=1,a.user_id,null)) as `打开adb调试风控用户数`,
    count(distinct if(t.b_adb_enable=1 and b.user_id is not null,a.user_id,null)) as `打开adb调试风控新用户数`,
    count(distinct if(t.b_debuggable=1,a.user_id,null)) as `开启调试风控用户数`,
    count(distinct if(t.b_debuggable=1 and b.user_id is not null,a.user_id,null)) as `开启调试风控新用户数`,
    count(distinct if(t.b_alter_loc=1,a.user_id,null)) as `修改定位风控用户数`,
    count(distinct if(t.b_alter_loc=1 and b.user_id is not null,a.user_id,null)) as `修改定位风控新用户数`, 
    count(distinct if(t.b_root=1,a.user_id,null)) as `root风控用户数`,
    count(distinct if(t.b_root=1 and b.user_id is not null,a.user_id,null)) as `root风控新用户数`, 
    count(distinct if(t.b_hook=1,a.user_id,null)) as `进程被注入其他代码或库风控用户数`,
    count(distinct if(t.b_hook=1 and b.user_id is not null,a.user_id,null)) as `进程被注入其他代码或库风控新用户数`, 
    count(distinct if(t.b_acc=1,a.user_id,null)) as `设备开启辅助服务，具备自动化操作能力风控用户数`,
    count(distinct if(t.b_acc=1 and b.user_id is not null,a.user_id,null)) as `设备开启辅助服务，具备自动化操作能力风控新用户数`, 
    count(distinct if(t.b_sim=1,a.user_id,null)) as `SIM卡异常风控用户数`,
    count(distinct if(t.b_sim=1 and b.user_id is not null,a.user_id,null)) as `SIM卡异常风控新用户数`
from dim.dim_risk_newuser a
left join t on a.user_id=t.silk_id
left join dim.dim_silkworm_user b on a.user_id=b.user_id and substr(b.register_time,1,10)>='2024-08-29'
=========================================



-- 20240927第二次取数
-- 正式取数
with t as (
SELECT silk_id,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_adb_enable') as b_adb_enable,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_debuggable') as b_debuggable,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_alter_loc') as b_alter_loc,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_root') as b_root,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_hook') as b_hook,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_acc') as b_acc,
    get_json_string(app_device_info,'$.deviceLabels.device_suspicious_labels.b_sim') as b_sim
FROM 
    dim.dim_user_rcs
)

select
    count(distinct if(t.b_adb_enable=1,a.user_id,null)) as `打开adb调试风控用户数`,
    -- count(distinct if(t.b_adb_enable=1 and b.user_id is not null,a.user_id,null)) as `打开adb调试风控新用户数`,
    count(distinct if(t.b_debuggable=1,a.user_id,null)) as `开启调试风控用户数`,
    -- count(distinct if(t.b_debuggable=1 and b.user_id is not null,a.user_id,null)) as `开启调试风控新用户数`,
    count(distinct if(t.b_alter_loc=1,a.user_id,null)) as `修改定位风控用户数`,
    -- count(distinct if(t.b_alter_loc=1 and b.user_id is not null,a.user_id,null)) as `修改定位风控新用户数`, 
    count(distinct if(t.b_root=1,a.user_id,null)) as `root风控用户数`,
    -- count(distinct if(t.b_root=1 and b.user_id is not null,a.user_id,null)) as `root风控新用户数`, 
    count(distinct if(t.b_hook=1,a.user_id,null)) as `进程被注入其他代码或库风控用户数`,
    -- count(distinct if(t.b_hook=1 and b.user_id is not null,a.user_id,null)) as `进程被注入其他代码或库风控新用户数`, 
    count(distinct if(t.b_acc=1,a.user_id,null)) as `设备开启辅助服务，具备自动化操作能力风控用户数`,
    -- count(distinct if(t.b_acc=1 and b.user_id is not null,a.user_id,null)) as `设备开启辅助服务，具备自动化操作能力风控新用户数`, 
    count(distinct if(t.b_sim=1,a.user_id,null)) as `SIM卡异常风控用户数`
    -- count(distinct if(t.b_sim=1 and b.user_id is not null,a.user_id,null)) as `SIM卡异常风控新用户数`
from 
-- dim.dim_risk_newuser a
(select user_id from dwd.dwd_sr_market_rpd_lottery_winning_record
where dt=date_sub(current_date(),interval 1 day)
    and activity_type=1
group by 1) a
left join t on a.user_id=t.silk_id
-- left join dim.dim_silkworm_user b on a.user_id=b.user_id and substr(b.register_time,1,10)>='2024-08-29'


select
    t1.user_id,
    b.register_time as `注册时间`,
    b.accu_valid_order_num as `累计有效订单量`,
    b.block_reason as `拉黑原因`,
    b.latest_block_time as `最近一次拉黑时间`,
    if(b.status=1 and length(b.latest_block_time)>0 and str_to_date(b.latest_block_time,'%Y-%m-%d %H:%i:%s')<now(),'是','否') as `是否拉黑`
from t1 left join dim.dim_silkworm_user b on t1.user_id=b.user_id
;
























