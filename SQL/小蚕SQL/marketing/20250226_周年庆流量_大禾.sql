-- 周年庆活动页
select
    a.dat `统计日期`,
    a.dau,
    b.`周年庆活动页PV`,
    b.`周年庆活动页UV`,
    b.`每日盲盒曝光UV`,
    b.`每日盲盒点击UV`,
    b.`每日盲盒设置提醒点击UV`,
    b.`探店单单返模块曝光UV`,
    b.`探店单单返模块点击UV`
from
(select
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dat,
    count(1) as dau
from ods.ods_sr_event_log
where dt between date_sub(current_date(),interval 7 day) and date_sub(current_date(),interval 0 day)
group by 1) a
left join
(select 
    from_unixtime(cast(event_time as bigint)/1000,'yyyy-MM-dd') as dat,
    COUNT(if(event_name='Anniversary_Page_Ex',event_name,null)) AS `周年庆活动页PV`,
    count(distinct if(event_name='Anniversary_Page_Ex',user_id,null)) as `周年庆活动页UV`,
    count(distinct if(event_name='Anniversary_Page_Ex',user_id,null)) as `每日盲盒曝光UV`,
    count(distinct if(event_name='Anniversary_Open_Blindbox_Module_Click',user_id,null)) as `每日盲盒点击UV`,
    count(distinct if(event_name='Anniversary_Open_Blindbox_Reminder_Module_Click',user_id,null)) as `每日盲盒设置提醒点击UV`,
    count(distinct if(event_name='Anniversary_Rebate_Per_Order_Ex',user_id,null)) as `探店单单返模块曝光UV`,
    count(distinct if(event_name='Anniversary_Rebate_Per_Order_Activity_Click',user_id,null)) as `探店单单返模块点击UV`,
    count(distinct if(event_name='Anniversary_Activity_Flash_Sale_Ex',user_id,null)) as `砍价秒杀模块曝光UV`,
    count(distinct if(event_name='Anniversary_Activity_Card_Click',user_id,null)) as `砍价秒杀模块点击UV`,
    count(distinct if(event_name='Anniversary_Activity_Flash_Sale_Reminder_Button_Click',user_id,null)) as `秒杀模块设置提醒点击UV`,
    count(distinct if(event_name='In_Store_Flash_Sale_Activity_Page_Ex',user_id,null)) as `秒杀列表页曝光UV`,
    count(distinct if(event_name='In_Store_Flash_Sale_Activity_Detail_Ex',user_id,null)) as `秒杀活动详情页曝光UV`
from ods.ods_sr_event_log
where dt between date_sub(current_date(),interval 1 day) and date_sub(current_date(),interval 0 day)
    and event_name in (
        'Anniversary_Page_Ex'
        ,'Anniversary_Open_Blindbox_Module_Click'
        ,'Anniversary_Open_Blindbox_Reminder_Module_Click'
        ,'Anniversary_Rebate_Per_Order_Ex'
        ,'Anniversary_Rebate_Per_Order_Activity_Click'
        ,'Anniversary_Activity_Flash_Sale_Ex'
        ,'Anniversary_Activity_Card_Click'
        ,'Anniversary_Activity_Flash_Sale_Reminder_Button_Click'
        ,'In_Store_Flash_Sale_Activity_Page_Ex'
        ,'In_Store_Flash_Sale_Activity_Detail_Ex'
        )
group by 1) b on a.dat=b.dat
;

