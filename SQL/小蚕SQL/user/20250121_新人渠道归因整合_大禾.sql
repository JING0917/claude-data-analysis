==========
一期需求：
1）按日、渠道、创建人展示指标结果

二期需求：
1）按日、渠道、创建人展示指标结果
2）1）中维度不变，展示明细数据表，明细数据表最小粒度：user_id。

三期需求：
1）在二期需求基础上，增加指标，其他不变
==========

-- 后端使用
dws.dws_sr_user_nca_olduser_d
dws.dws_sr_user_nca_olduser_click_d
dwd.dwd_sr_bargain_newuser
dws.dws_sr_user_newuser_channel_ascribe
dwd.dwd_sr_user_nca_baoming_d
dws.dws_sr_user_newuser_channel_ascribe_link_d



=========
改造建议：处理两张表，分别是渠道聚合表和用户明细表。
1）渠道聚合表（dws.dws_sr_user_nca_d）。维度：dt、channel_id、creator_id、channel_type，指标根据一期、二期、三期指标处理
2）用户明细表（dws.dws_sr_user_nca_d_user）。维度：dt、channel_id、creator_id、channel_type、user_id，指标根据一期、二期、三期指标处理




-- 表一
CREATE TABLE IF NOT EXISTS dws.dws_sr_user_nca_olduser_d
(
    `dt` date NOT NULL COMMENT '时间',
    `channel_id` string COMMENT '渠道id', --渠道id
    `creator_id` int COMMENT '创建人ID',--channel表admin_id管理员id
    `channel_name` string COMMENT '渠道',
    `channel_type` int COMMENT '渠道类型(0:未知,1:推广渠道,2:功能渠道)',
    `takeaway_baoming_user_num` int COMMENT '外卖报名用户量',
    `explore_baoming_user_num` int COMMENT '探店报名用户量',
    `welfare_baoming_user_num` int COMMENT '公益报名用户量',
    `takeaway_finord_user_num` int COMMENT '外卖完单用户量',
    `explore_finord_user_num` int COMMENT '探店完单用户量',
    `welfare_finord_user_num` int COMMENT '公益完单用户量',
    `takeaway_baoming_order_num` int COMMENT '外卖报名订单量',
    `explore_baoming_order_num` int COMMENT '探店报名订单量',
    `welfare_baoming_order_num` int COMMENT '公益报名订单量',
    `takeaway_finord_order_num` int COMMENT '外卖完单订单量',
    `unnote_explore_finord_order_num` int COMMENT '探店完单订单量(不含笔记)',
    `note_explore_finord_order_num` int COMMENT '探店完单订单量(含笔记)',
    `welfare_finord_order_num` int COMMENT '公益完单订单量',
    `takeaway_order_profit` int COMMENT '外卖订单利润',
    `unnote_explore_order_profit` int COMMENT '探店订单利润(不含笔记)',
    `note_explore_order_profit` int COMMENT '探店订单利润(含笔记)',
    `baoming_bargain_user_num` int COMMENT '参与砍价活动用户量',
    `bargain_finish_order_user_num` int COMMENT '参与砍价完单用户量',
    `baoming_bargain_promotion_num` int COMMENT '参与砍价活动量',
    `bargain_finish_order_num` int COMMENT '参与砍价完单量',
    `bargain_order_profit` int COMMENT '砍价利润(可能有负数)'
)
ENGINE=OLAP
PRIMARY KEY(dt,channel_id,creator_id,channel_name,channel_type)
COMMENT '新人渠道归因存量用户日数据'
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(channel_id,creator_id,channel_name,channel_type)
PROPERTIES (
"replication_num" ="2"
);


-- 表二 
-- 和表一 通过dt creator_id channel_id channel_type关联
CREATE TABLE IF NOT EXISTS dws.dws_sr_user_nca_olduser_click_d
(
    `dt` date NOT NULL COMMENT '时间',
    `channel_id` bigint COMMENT '渠道id', --渠道id
    `creator_id` bigint COMMENT '创建人ID',--channel表admin_id管理员id
    `channel_name` string COMMENT '渠道',
    `channel_type` int COMMENT '渠道类型(0:未知,1:推广渠道,2:功能渠道)',
    `user_num` int COMMENT '存量用户量',
    `dzdp_user_num` int COMMENT '存量用户大众点评认证用户量',
    `xhs_user_num` int COMMENT '存量用户小红书认证量'
)
ENGINE=OLAP
PRIMARY KEY(dt,channel_id,creator_id,channel_name,channel_type)
COMMENT '新人渠道归因存量用户日点击数据'
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(channel_id,creator_id,channel_name,channel_type)
PROPERTIES (
"replication_num" ="2"
);


-- 表三
-- 以register_date,channel_id,channel_type,creator_id为维度，汇总成 新用户参与砍价指标
-- 再和表一关联
CREATE TABLE IF NOT EXISTS dwd.dwd_sr_bargain_newuser (
    `user_id` string COMMENT '用户id',
    `creator_id` int COMMENT '创建人ID',--channel表admin_id管理员id
    `channel_name` string COMMENT '渠道', --channel表name渠道名称
    `activity_id` int COMMENT '活动ID',--func_channel表activity_id活动id
    `register_date` string COMMENT '注册日期',
    `channel_id` string COMMENT '渠道id', --渠道id
    `channel_type` int COMMENT '渠道类型:1.推广渠道,2.功能渠道,0.未知'
)
ENGINE=OLAP
PRIMARY KEY(user_id)
COMMENT '渠道注册参与砍价用户'
DISTRIBUTED BY HASH(user_id)
PROPERTIES (
"replication_num" ="2"
);



-- 表四
-- 以register_date,channel_id,channel_type,creator_id为维度，汇总成 需求指标
-- 看起来表一 已经包含这些指标，需要再看下是否表四还需要
CREATE TABLE IF NOT EXISTS dws.dws_sr_user_newuser_channel_ascribe
(
    `register_date` date NOT NULL comment '注册时间',
    `user_id` int  NOT NULL COMMENT '用户id',
    `creator_id` int COMMENT '创建人ID',--channel表admin_id管理员id
    `channel_name` string COMMENT '渠道', --channel表name渠道名称
    `activity_id` int COMMENT '活动ID',--func_channel表activity_id活动id
    `channel_id` int COMMENT '渠道id', --渠道id
    `channel_type` int COMMENT '渠道类型:1.推广渠道,2.功能渠道,0.未知',
    `is_bind_phone` int COMMENT '是否绑定手机号(0:否,1:是)',
    `user_nickname` string COMMENT '用户昵称',
    `user_avatar_url` string COMMENT '头像url地址',
    `inviter_user_id` string COMMENT '上级用户id',
    `address` string COMMENT '地区',
    `baoming_takeaway_promotion_num` int DEFAULT '0' COMMENT '报名外卖活动数',
    `takeaway_order_num` int DEFAULT '0' COMMENT '外卖订单数',
    `takeaway_order_profit` decimal(12,2) DEFAULT '0.00' COMMENT '外卖订单利润',
    `baoming_explore_promotion_num` int DEFAULT '0' COMMENT '报名探店活动数',
    `explore_order_h_num` int DEFAULT '0' COMMENT '探店订单数(含笔记)',
    `explore_order_bh_num` int DEFAULT '0' COMMENT '探店订单数(不含笔记)',
    `explore_order_h_profit` decimal(12,2) DEFAULT '0.00' COMMENT '探店订单利润(含笔记)',
    `explore_order_bh_profit` decimal(12,2) DEFAULT '0.00' COMMENT '探店订单利润(不含笔记)',
    `baoming_welfare_promotion_num` int DEFAULT '0' COMMENT '报名公益活动数',
    `welfare_order_num` int DEFAULT '0' COMMENT '公益订单数',
    `tot_order_profit` decimal(12,2) DEFAULT '0.00' COMMENT '总订单利润',
    `baoming_bargain_user_num` int COMMENT '参与砍价活动用户量',
    `bargain_finish_order_user_num` int COMMENT '参与砍价完单用户量',
    `bargain_order_profit` int COMMENT '砍价利润(可能有负数)',
    `baoming_bargain_promotion_num` int COMMENT '参与砍价活动量',
    `bargain_finish_order_num` int COMMENT '参与砍价完单量'

)
ENGINE=OLAP
PRIMARY KEY(register_date,user_id)
COMMENT '渠道注册用户转化情况表'
PARTITION BY date_trunc('day', register_date)
DISTRIBUTED BY HASH(register_date,user_id)
PROPERTIES (
"replication_num" ="2"
);



-- 表五
-- 看起来表四已经包含，需确认表五是否还需要，不需要的话，直接用表四
-- 前述条件成立时，走表四处理逻辑
CREATE TABLE IF NOT EXISTS dwd.dwd_sr_user_nca_baoming_d
(
    --维度
    `dt` datetime NOT NULL COMMENT '时间',
    `user_id` int NOT NULL COMMENT '用户id',
    `promotion_type` int COMMENT '活动类型(探店，外卖，公益，砍价)',
    `channel_id` string COMMENT '渠道id', --渠道id
    `creator_id` int COMMENT '创建人ID',--channel表admin_id管理员id
    `channel_name` string COMMENT '渠道',
    `channel_type` int COMMENT '渠道类型(0:未知,1:推广渠道,2:功能渠道)',
    `promotion_id` bigint COMMENT '活动id'
)
ENGINE=OLAP
PRIMARY KEY(dt,user_id,promotion_type,channel_id,creator_id,channel_name,channel_type,promotion_id)
COMMENT '用户点击报名活动'
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(user_id,promotion_type,channel_id,creator_id,channel_name,channel_type,promotion_id)
PROPERTIES (
"replication_num" ="2"
);



-- 表六
-- 退掉activity_id维度，其他维度做聚合，再和表一 通过dt creator_id channel_id channel_type关联
-- open_link_num 值作为维度，最后再和表一关联使用
CREATE TABLE IF NOT EXISTS dws.dws_sr_user_newuser_channel_ascribe_link_d
(
    --维度
    `channel_type` int COMMENT '渠道类型:1.推广渠道,2.功能渠道,0.未知',
    `dt` date COMMENT '链接打开时间',
    `channel_id` string COMMENT '渠道id', --渠道id
    `creator_id` int COMMENT '创建人ID',--channel表admin_id管理员id
    `channel_name` string COMMENT '渠道', --channel表name渠道名称
    `activity_id` int COMMENT '活动ID',--func_channel表activity_id活动id
    `open_link_num` int COMMENT '打开链接数量'
)
ENGINE=OLAP
PRIMARY KEY(channel_type,dt,channel_id)
COMMENT '新人渠道链接点击统计日表'
PARTITION BY date_trunc('day', dt)
DISTRIBUTED BY HASH(channel_type,dt,channel_id)
PROPERTIES (
"replication_num" ="2"
);










