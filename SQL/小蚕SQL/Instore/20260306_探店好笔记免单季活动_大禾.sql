-- 统计口径

在explore_note_activity_record 这个表中的 order_id，有发奖励，或者满足发奖资格的订单，都会在这个表里。更准确的说是，满足发奖资格的 current_note_eligible 会等于 1。


本次活动的数据都在 explore_note_activity_record 表里，excellent_reward_time 是优秀奖励发放时间  good_reward_time 是良好奖励发放时间，有时间就代表发过，优秀和良好都是免单卡。
红包是 base_reward_time。一个订单只会有一条记录。

note_upload_history 这个是上传笔记表，这里面的 order_id 存在于 explore_note_activity_record 表，就应该算活动的笔记吧
因为一个用户可以重新上传笔记，那笔记 id 就会变，按需求来说，是可以先发良好奖励，再发优秀奖励的，用户可以两个奖励都有

这个上传表里有 quality_tag_id 字段，可以看笔记得分 quality_tag_id 1 是优秀，2 是良好

红包id：1140
良好笔记100元免单卡：237
优秀笔记通用免单卡：236


status in (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33)算核销单量；status in (5,19,20,35)算完单

达人和素人
SELECT user_id,
       if(xiaohongshu_fans_num>=500
          OR dp_user_lvl>=5,'达人','素人') user_type
FROM dim.dim_silkworm_explore_daren_cleanse;




LEFT JOIN
-- 下单指标
  (SELECT date(create_time) dt,
          city_name,
          user_type,
          bitmap_agg(user_id) AS baoming_uids -- 下单用户
   FROM note_info
   GROUP BY 1,
            2,
            3) c ON a.dt=c.dt
AND a.city_name=c.city_name
AND a.user_type=c.user_type
LEFT JOIN
-- 核销指标
  (SELECT date(verify_time) dt,
          city_name,
          user_type,
          bitmap_agg(if(order_status IN (4,5,11,12,13,14,15,16,17,18,19,20,21,22,30,31,32,33),user_id,NULL)) verify_uids -- 核销用户
   FROM note_info
   GROUP BY 1,
            2,
            3) d ON a.dt=d.dt
AND a.city_name=d.city_name
AND a.user_type=d.user_type
LEFT JOIN
-- 完单指标
  (SELECT date(finish_time) dt,
          city_name,
          user_type,
          count(DISTINCT if(order_status IN (5,19,20,34,35) and (is_yx_note=1 or is_lh_note=1 or is_send_rdp=1),order_id,NULL)) finord_num -- 完单数
   FROM note_info
   GROUP BY 1,
            2,
            3) e ON a.dt=e.dt
AND a.city_name=e.city_name
AND a.user_type=e.user_type;


20260311 调整
1）漏斗改截面，UV是探店整体
2）整体数据加优质笔记占比

================================================ 正式跑数
-- 达人和素人
DROP VIEW IF EXISTS user_info;


CREATE VIEW IF NOT EXISTS user_info (user_id,user_type,first_explode_order_date) AS
  (SELECT user_id,
          if(xiaohongshu_fans_num>=500
             OR dp_user_lvl>=5,'达人','素人') user_type,
          first_explode_order_date
   FROM dim.dim_silkworm_explore_daren_cleanse);


-- 流量
DROP VIEW IF EXISTS traffic_info;


CREATE VIEW IF NOT EXISTS traffic_info (dt,city_name,user_id,user_type,pv) AS
  (SELECT dt,
          a.city_name,
          a.user_id,
          c.user_type,
          a.pv
   FROM
     (SELECT date(time) dt,
                        concat($city,'市') city_name,
                                          distinct_id AS user_id,
                                          count(1) pv
      FROM dwd.dwd_sr_traffic_sensor_event_log_realtime
      WHERE date(time)='2026-03-06'
        AND event='MAR_LANDING_PAGE_VIEW'
        AND distinct_id regexp '^[0-9]{1,10}$'
      GROUP BY 1,
               2,
               3) a
   LEFT JOIN
     (SELECT city_name
      FROM dim.dim_silkworm_explore_city
      WHERE promotion_type IN ('101',
                               '111',
                               '1')
        AND city_name<>'阿里地区'
      GROUP BY 1) b ON a.city_name=b.city_name
   LEFT JOIN user_info c ON a.user_id=c.user_id
   WHERE b.city_name IS NOT NULL);

-- 用户首次优秀评级日期
DROP VIEW IF EXISTS first_excellent_note_info;


CREATE VIEW IF NOT EXISTS first_excellent_note_info (user_id,first_excellent_note_date) AS
  (SELECT user_id,
          min(dt) first_excellent_note_date
   FROM dwd.dwd_sr_silkworm_explore_notes_upload_record
   WHERE quality_tag_id=1
   GROUP BY 1);

-- 本次活动笔记和订单（只有有笔记的订单才计入）
DROP VIEW IF EXISTS note_info;


CREATE VIEW IF NOT EXISTS note_info (dt,order_id,notes_id,quality_tag_id,user_id,is_yx_note,is_lh_note,is_send_rdp,order_status,create_time,verify_time,finish_time,city_name,user_type,first_excellent_note_date,first_explode_order_date) AS
  (SELECT a.dt,
          a.order_id,
          a.notes_id,
          a.quality_tag_id,
          a.user_id,
          if(date(b.excellent_reward_time)<>'1970-01-01',1,0) is_yx_note,
          if(date(b.good_reward_time)<>'1970-01-01',1,0) is_lh_note,
          if(date(b.rdp_grant_time)<>'1970-01-01',1,0) is_send_rdp,
          c.status AS order_status,
          c.create_time,
          c.verify_time,
          c.finish_time,
          e.city_name,
          d.user_type,
          f.first_excellent_note_date,
          d.first_explode_order_date
   FROM
     (SELECT dt,
             order_id,
             notes_id,
             quality_tag_id,
             user_id
      FROM dwd.dwd_sr_silkworm_explore_notes_upload_record
      WHERE dt='2026-03-06') a
   LEFT JOIN dwd.dwd_sr_silkworm_explore_note_reward b ON a.order_id=b.order_id
   LEFT JOIN
     (SELECT order_id,
             status,
             create_time,
             verify_time,
             finish_time,
             city_id
      FROM dwd.dwd_sr_silkworm_explore_order
      WHERE dt BETWEEN date_sub('2026-03-06',interval 30 DAY) AND '2026-03-06'
        AND promotion_type IN (1,
                               4)) c ON a.order_id=c.order_id
     left join user_info d on a.user_id=d.user_id
     left join dim.dim_silkworm_county e on c.city_id=e.county_id
     left join first_excellent_note_info f on a.user_id=f.user_id
   WHERE b.order_id IS NOT NULL);


-- 统计流量+笔记指标
DROP VIEW IF EXISTS note_index;

CREATE VIEW IF NOT EXISTS note_index (dt,city_name,user_type,pv,view_uids,note_uids,finord_num,youzhi_note_num,pubnote_num,excellent_note_num,good_note_num,normal_note_num,excellent_note_uids,first_excellent_note_uids,finord_uids) AS
(SELECT coalesce(a.dt,b.dt,c.dt) dt,
       coalesce(a.city_name,b.city_name,c.city_name) city_name,
       coalesce(a.user_type,b.user_type,c.user_type) user_type,
       a.pv,
       a.view_uids,
       note_uids,
       ifnull(finord_num,0) finord_num,
       ifnull(youzhi_note_num,0) youzhi_note_num,
       ifnull(pubnote_num,0) pubnote_num,
       ifnull(excellent_note_num,0) excellent_note_num,
       ifnull(good_note_num,0) good_note_num,
       ifnull(normal_note_num,0) normal_note_num,
       excellent_note_uids,
       first_excellent_note_uids,
       finord_uids
FROM
  (SELECT dt,
          city_name,
          user_type,
          sum(pv) pv,
          bitmap_agg(user_id) view_uids
   FROM traffic_info
   GROUP BY 1,
            2,
            3) a
LEFT JOIN
-- 笔记指标
  (SELECT dt,
          city_name,
          user_type,
          bitmap_agg(user_id) AS note_uids, -- 参与用户/发笔记用户
          count(DISTINCT if(quality_tag_id IN (1,2),notes_id,NULL)) youzhi_note_num, -- 优质笔记
          count(distinct notes_id) pubnote_num, -- 笔记数
          count(DISTINCT if(quality_tag_id=1,notes_id,NULL)) excellent_note_num, -- 优秀笔记数
          count(DISTINCT if(quality_tag_id=2,notes_id,NULL)) good_note_num, -- 良好笔记数
          count(DISTINCT if(quality_tag_id NOT IN (1,2),notes_id,NULL)) normal_note_num, -- 普通笔记数
          bitmap_agg(if(quality_tag_id=1,user_id,null)) excellent_note_uids, -- 优秀创作者数
          bitmap_agg(if(dt=first_excellent_note_date and quality_tag_id=1,user_id,null)) first_excellent_note_uids -- 首次优秀用户
   FROM note_info
   GROUP BY 1,
            2,
            3) b ON a.dt=b.dt
AND a.city_name=b.city_name
AND a.user_type=b.user_type
LEFT JOIN
-- 完单指标
  (SELECT date(finish_time) dt,
          city_name,
          user_type,
          count(DISTINCT if(order_status IN (5,19,20,34,35) and (is_yx_note=1 or is_lh_note=1 or is_send_rdp=1),order_id,NULL)) finord_num, -- 完单数
          bitmap_agg(if(order_status IN (5,19,20,34,35) and first_explode_order_date=date(finish_time),user_id,null)) finord_uids -- 新用户数
   FROM note_info
   GROUP BY 1,
            2,
            3) c ON a.dt=c.dt
AND a.city_name=c.city_name
AND a.user_type=c.user_type);



-- 下单转化漏斗
DROP VIEW IF EXISTS funnel_index;


CREATE VIEW IF NOT EXISTS funnel_index (dt,city_name,user_type,explore_uids,baoming_uids,verify_uids,pubnote_uids,youzhi_note_uids) AS
  (SELECT a.dt,
          a.city_name,
          a.user_type,
          bitmap_agg(a.user_id) explore_uids,
          bitmap_agg(if(b.user_id IS NOT NULL,a.user_id,NULL)) baoming_uids,
          bitmap_agg(if(c.user_id IS NOT NULL,a.user_id,NULL)) verify_uids,
          bitmap_agg(if(d.user_id IS NOT NULL,a.user_id,NULL)) pubnote_uids,
          bitmap_agg(if(e.user_id IS NOT NULL,a.user_id,NULL)) youzhi_note_uids
   FROM
(SELECT dt,
        city_name,
        user_type,
        user_id
 FROM traffic_info
 GROUP BY 1,
          2,
          3,
          4) a
   LEFT JOIN
(SELECT date(create_time) dt,
                          user_id
 FROM dwd.dwd_sr_silkworm_explore_order
 GROUP BY 1,
          2) b ON a.dt<=b.dt
   AND a.user_id=b.user_id
   LEFT JOIN
(SELECT date(verify_time) dt,
                          user_id
 FROM dwd.dwd_sr_silkworm_explore_order
 WHERE date(verify_time)<>'1970-01-01'
 GROUP BY 1,
          2) c ON b.dt<=c.dt
   AND b.user_id=c.user_id
   LEFT JOIN
(SELECT dt,
        user_id
 FROM note_info
 GROUP BY 1,
          2) d ON c.dt<=d.dt
   AND c.user_id=d.user_id
   LEFT JOIN
(SELECT dt,
        user_id
 FROM note_info
 WHERE quality_tag_id IN (1,
                          2)
 GROUP BY 1,
          2) e ON c.dt<=e.dt
   AND c.user_id=e.user_id
   GROUP BY 1,
            2,
            3);



-- 红包发放
DROP VIEW IF EXISTS grant_rdp;


CREATE VIEW IF NOT EXISTS grant_rdp (dt,city_name,user_type,grant_num) AS
  (SELECT a.dt,
          c.city AS city_name,
          b.user_type,
          sum(grant_num) grant_num
   FROM
     (SELECT dt,
             user_id,
             count(1) grant_num
      FROM dwd.dwd_sr_total_market_redpack_use_record
      WHERE dt='2026-03-06'
        AND redpacket_id=1140
      GROUP BY 1,
               2) a
   LEFT JOIN user_info b ON a.user_id=b.user_id
   LEFT JOIN dim.dim_silkworm_user_location c ON a.user_id=c.user_id
   GROUP BY 1,
            2,
            3);

-- 红包使用
DROP VIEW IF EXISTS use_rdp;


CREATE VIEW IF NOT EXISTS use_rdp (dt,city_name,user_type,used_num,used_rdp_amt) AS
  (SELECT a.dt,
          c.city AS city_name,
          b.user_type,
          sum(used_num) used_num,
          sum(used_rdp_amt) used_rdp_amt
   FROM
     (SELECT date(a1.used_time) as dt,
             a1.user_id,
             count(1) used_num,
             sum(if(a2.status in (5,19,20,34,35),a1.real_rebate_amt,0)) used_rdp_amt
      FROM dwd.dwd_sr_total_market_redpack_use_record a1
      left join dwd.dwd_sr_silkworm_explore_order a2 on a1.auto_ordere_id=a2.order_id
      WHERE date(a1.used_time)='2026-03-06'
        AND a1.redpacket_id=1140
      GROUP BY 1,
               2) a
   LEFT JOIN user_info b ON a.user_id=b.user_id
   LEFT JOIN dim.dim_silkworm_user_location c ON a.user_id=c.user_id
   GROUP BY 1,
            2,
            3);



-- 卡券发放
DROP VIEW IF EXISTS grant_coupon;


CREATE VIEW IF NOT EXISTS grant_coupon (dt,city_name,user_type,excellen_grant_num,good_grant_num) AS
  (SELECT a.dt,
          c.city AS city_name,
          b.user_type,
          sum(excellen_grant_num) excellen_grant_num,
          sum(good_grant_num) good_grant_num
   FROM
     (SELECT dt,
             user_id,
             sum(if(card_id=236,1,0)) excellen_grant_num,
             sum(if(card_id=237,1,0)) good_grant_num
      FROM dwd.dwd_sr_market_rights_card
      WHERE dt='2026-03-06'
        AND card_id in (236,237)
      GROUP BY 1,
               2) a
   LEFT JOIN user_info b ON a.user_id=b.user_id
   LEFT JOIN dim.dim_silkworm_user_location c ON a.user_id=c.user_id
   GROUP BY 1,
            2,
            3);

-- 卡券使用
DROP VIEW IF EXISTS use_coupon;


CREATE VIEW IF NOT EXISTS use_coupon (dt,city_name,user_type,excellen_use_num,good_use_num,excellen_use_amt,good_use_amt) AS
  (SELECT a.dt,
          c.city AS city_name,
          b.user_type,
          sum(excellen_use_num) excellen_use_num,
          sum(good_use_num) good_use_num,
          sum(excellen_use_amt) excellen_use_amt,
          sum(good_use_amt) good_use_amt
   FROM
     (SELECT date(a1.used_time) as dt,
             a1.user_id,
             sum(if(card_id=236,1,0)) excellen_use_num,
             sum(if(card_id=237,1,0)) good_use_num,
             sum(if(card_id=236,a2.original_price-a2.real_rebate_amt-(a2.red_pack_reward_num/100),0)) excellen_use_amt,
             sum(if(card_id=237,a2.original_price-a2.real_rebate_amt-(a2.red_pack_reward_num/100),0)) good_use_amt          
      FROM dwd.dwd_sr_market_rights_card a1
      left join dwd.dwd_sr_silkworm_explore_order a2 on a1.key_id=a2.auto_id
      WHERE date(a1.used_time)='2026-03-06'
        AND a1.card_id in (236,237)
      GROUP BY 1,
               2) a
   LEFT JOIN user_info b ON a.user_id=b.user_id
   LEFT JOIN dim.dim_silkworm_user_location c ON a.user_id=c.user_id
   GROUP BY 1,
            2,
            3);


-- 卡券核销
DROP VIEW IF EXISTS verify_coupon;


CREATE VIEW IF NOT EXISTS verify_coupon (dt,city_name,user_type,excellen_verify_amt,good_verify_amt) AS
  (SELECT a.dt,
          c.city AS city_name,
          b.user_type,
          sum(excellen_verify_amt) excellen_verify_amt,
          sum(good_verify_amt) good_verify_amt
   FROM
     (SELECT date(a2.verify_time) as dt,
             a1.user_id,
             sum(if(card_id=236,a2.pay_amt-a2.real_rebate_amt,0)) excellen_verify_amt,
             sum(if(card_id=237,a2.pay_amt-a2.real_rebate_amt,0)) good_verify_amt          
      FROM dwd.dwd_sr_market_rights_card a1
      left join dwd.dwd_sr_silkworm_explore_order a2 on a1.key_id=a2.auto_id
      WHERE a1.card_id in (236,237)
        AND date(a2.verify_time)='2026-03-06'
      GROUP BY 1,
               2) a
   LEFT JOIN user_info b ON a.user_id=b.user_id
   LEFT JOIN dim.dim_silkworm_user_location c ON a.user_id=c.user_id
   GROUP BY 1,
            2,
            3);


SELECT coalesce(a.dt,b.dt,c.dt,d.dt,e.dt,f.dt,g.dt) dt, 
       coalesce(a.city_name,b.city_name,c.city_name,d.city_name,e.city_name,f.city_name,g.city_name) city_name,
       coalesce(a.user_type,b.user_type,c.user_type,d.user_type,e.user_type,f.user_type,g.user_type) user_type,
       pv,
       view_uids,
       note_uids,
       finord_num,
       youzhi_note_num,
       pubnote_num,
       excellent_note_num,
       good_note_num,
       normal_note_num,
       excellent_note_uids,
       first_excellent_note_uids,
       finord_uids,
       explore_uids,
       baoming_uids,
       verify_uids,
       pubnote_uids,
       youzhi_note_uids,
       ifnull(grant_num,0) rdp_grant_num,
       ifnull(used_num,0) rdp_used_num,
       ifnull(used_rdp_amt,0) rdp_used_amt,
       ifnull(excellen_grant_num,0) excellen_grant_num,
       ifnull(good_grant_num,0) good_grant_num,
       ifnull(excellen_use_num,0) excellen_used_num,
       ifnull(good_use_num,0) good_used_num,
       ifnull(excellen_use_amt,0) excellen_used_amt,
       ifnull(good_use_amt,0) good_used_amt,
       ifnull(excellen_verify_amt,0) excellen_verify_amt,
       ifnull(good_verify_amt,0) good_verify_amt
FROM note_index a
LEFT JOIN funnel_index b ON a.dt=b.dt
AND a.city_name=b.city_name
AND a.user_type=b.user_type
LEFT JOIN grant_rdp c ON a.dt=c.dt
AND a.city_name=c.city_name
AND a.user_type=c.user_type
LEFT JOIN use_rdp d ON a.dt=d.dt
AND a.city_name=d.city_name
AND a.user_type=d.user_type
LEFT JOIN grant_coupon e ON a.dt=e.dt
AND a.city_name=e.city_name
AND a.user_type=e.user_type
LEFT JOIN use_coupon f ON a.dt=f.dt
AND a.city_name=f.city_name
AND a.user_type=f.user_type
LEFT JOIN verify_coupon g ON a.dt=g.dt
AND a.city_name=g.city_name
AND a.user_type=g.user_type ;





SELECT coalesce(a.`统计日期`,b.`统计日期`) `统计日期`,
       coalesce(a.`城市`,b.`城市`) `城市`,
       coalesce(a.`用户类型`,b.`用户类型`) `用户类型`,
       ifnull(`PV`,0) `PV`,
       ifnull(`UV`,0) `UV`,
       ifnull(`参与用户量`,0) `参与用户量`,
       ifnull(`完单量`,0) `完单量`,
       ifnull(`优质笔记数`,0) `优质笔记数`,
       ifnull(`发布笔记数`,0) `发布笔记数`,
       ifnull(`优秀笔记数`,0) `优秀笔记数`,
       ifnull(`良好笔记数`,0) `良好笔记数`,
       ifnull(`普通笔记数`,0) `普通笔记数`,
       ifnull(`优秀创作者数`,0) `优秀创作者数`,
       ifnull(`新优秀创作者数`,0) `新优秀创作者数`,
       ifnull(`新用户数`,0) `新用户数`,
       ifnull(`探店UV`,0) `探店UV`,
       ifnull(`下单用户量`,0) `下单用户量`,
       ifnull(`核销用户量`,0) `核销用户量`,
       ifnull(`发布笔记用户量`,0) `发布笔记用户量`,
       ifnull(`优质笔记用户量`,0) `优质笔记用户量`,
       ifnull(`红包发放量`,0) `红包发放量`,
       ifnull(`红包使用量`,0) `红包使用量`,
       ifnull(`红包使用金额`,0) `红包使用金额`,
       ifnull(`优秀免单卡发放量`,0) `优秀免单卡发放量`,
       ifnull(`良好免单卡发放量`,0) `良好免单卡发放量`,
       ifnull(`优秀免单卡使用量`,0) `优秀免单卡使用量`,
       ifnull(`良好免单卡使用量`,0) `良好免单卡使用量`,
       ifnull(`优秀免单卡使用金额`,0) `优秀免单卡使用金额`,
       ifnull(`良好免单卡使用金额`,0) `良好免单卡使用金额`,
       ifnull(`优秀免单卡核销金额`,0) `优秀免单卡核销金额`,
       ifnull(`良好免单卡核销金额`,0) `良好免单卡核销金额`
FROM
  (SELECT statistics_date `统计日期`,
          city_name `城市`,
          user_type `用户类型`,
          pv `PV`,
          finord_num `完单量`,
          youzhi_note_num `优质笔记数`,
          pubnote_num `发布笔记数`,
          excellent_note_num `优秀笔记数`,
          good_note_num `良好笔记数`,
          normal_note_num `普通笔记数`,
          rdp_grant_num `红包发放量`,
          rdp_used_num `红包使用量`,
          rdp_used_amt `红包使用金额`,
          excellen_grant_num `优秀免单卡发放量`,
          good_grant_num `良好免单卡发放量`,
          excellen_used_num `优秀免单卡使用量`,
          good_used_num `良好免单卡使用量`,
          excellen_used_amt `优秀免单卡使用金额`,
          good_used_amt `良好免单卡使用金额`,
          excellen_verify_amt `优秀免单卡核销金额`,
          good_verify_am `良好免单卡核销金额`
   FROM ads.ads_sr_market_explore_excellent_note_statis_d
   WHERE statistics_date BETWEEN '${begin_date}' AND '${end_date}') a
LEFT JOIN
  (SELECT statistics_date `统计日期`,
          city_name `城市`,
          user_type `用户类型`,
          bitmap_union_count(view_uids) `UV`,
          bitmap_union_count(note_uids) `参与用户量`,
          bitmap_union_count(excellent_note_uids) `优秀创作者数`,
          bitmap_union_count(first_excellent_note_uids) `新优秀创作者数`,
          bitmap_union_count(finord_uids) `新用户数`,
          bitmap_union_count(explore_uids) `探店UV`,
          bitmap_union_count(baoming_uids) `下单用户量`,
          bitmap_union_count(verify_uids) `核销用户量`,
          bitmap_union_count(pubnote_uids) `发布笔记用户量`,
          bitmap_union_count(youzhi_note_uids) `优质笔记用户量`
   FROM ads.ads_sr_market_explore_excellent_note_statis_d
   WHERE statistics_date BETWEEN '${begin_date}' AND '${end_date}'
   GROUP BY 1,
            2,
            3) b ON a.`统计日期`=b.`统计日期`
AND a.`城市`=b.`城市`
AND a.`用户类型`=b.`用户类型`


