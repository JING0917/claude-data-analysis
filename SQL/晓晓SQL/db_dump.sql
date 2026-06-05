SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `20230322sxy` (
  `商户订单号` varchar(255) DEFAULT NULL,
  `订单流水号` varchar(255) DEFAULT NULL,
  `银行订单号` varchar(255) DEFAULT NULL,
  `银行流水号` varchar(255) DEFAULT NULL,
  `订单金额（元）` varchar(255) DEFAULT NULL,
  `订单状态` varchar(255) DEFAULT NULL,
  `支付金额（元）` varchar(255) DEFAULT NULL,
  `已退款金额（元）` varchar(255) DEFAULT NULL,
  `手续费（元）` varchar(255) DEFAULT NULL,
  `手续费收费方式` varchar(255) DEFAULT NULL,
  `下单时间` varchar(255) DEFAULT NULL,
  `完成时间` varchar(255) DEFAULT NULL,
  `支付方式` varchar(255) DEFAULT NULL,
  `支付银行` varchar(255) DEFAULT NULL,
  `备注` varchar(255) DEFAULT NULL,
  `项目ID` varchar(255) DEFAULT NULL,
  `check` tinyint(1) DEFAULT '0',
  KEY `idx` (`商户订单号`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `shopid` int(11) DEFAULT NULL COMMENT '门店id',
  `platformtype` int(11) DEFAULT NULL COMMENT '平台类型(1美团 2饿了么)',
  `full` decimal(18,2) DEFAULT NULL COMMENT '满减满值',
  `sub` decimal(18,2) DEFAULT NULL COMMENT '满减减值',
  `maxnumber` int(11) DEFAULT NULL COMMENT '当日最大数量',
  `starttime` timestamp NULL DEFAULT NULL COMMENT '活动开始时间',
  `endtime` timestamp NULL DEFAULT NULL COMMENT '活动结束时间',
  `todaystarttime` varchar(32) DEFAULT NULL COMMENT '当日开始时间',
  `todayendtime` varchar(32) DEFAULT NULL COMMENT '当日结束时间',
  `remark` varchar(256) DEFAULT NULL COMMENT '备注tips',
  `isforbid` int(11) DEFAULT NULL COMMENT '是否禁用 0正常 1禁用',
  `isdelete` int(11) DEFAULT NULL COMMENT '是否删除(0：正常 1：删除)',
  `createtime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `tips` varchar(12) DEFAULT NULL COMMENT '活动的备注信息',
  `commission` decimal(18,2) DEFAULT NULL COMMENT '活动佣金',
  `deduction` decimal(18,2) DEFAULT NULL COMMENT '扣钱金额',
  `vipdeduction` decimal(18,2) DEFAULT '0.00' COMMENT '会员扣钱金额',
  `sysmasterid` int(11) DEFAULT NULL COMMENT '修改人id',
  `updatetime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `updateremark` longtext COMMENT '修改了什么内容',
  `creator` int(11) DEFAULT NULL COMMENT '创建人id',
  `agentid` int(11) DEFAULT NULL COMMENT '代理商id',
  `isentryfee` int(11) DEFAULT NULL COMMENT '是否要报名费 1：要报名费 0：不要报名费',
  `shelftype` tinyint(4) DEFAULT '1' COMMENT '上架方式 1:后台系统 2:小程序',
  `creatortype` tinyint(4) DEFAULT '1' COMMENT '创建人类型 1:管理员 2:代理商 3:商家',
  `frozenamount` decimal(18,2) DEFAULT '0.00' COMMENT '冻结金额',
  `returnamount` decimal(18,2) DEFAULT '0.00' COMMENT '已退回金额',
  `refundstatus` tinyint(4) DEFAULT '0' COMMENT '是否已退回押金(0:未退回 1:已退回)',
  `issoldout` tinyint(4) DEFAULT '0' COMMENT '当日是否已售完(0:未售完  1:已售完)',
  `disabletime` timestamp NULL DEFAULT NULL COMMENT '系统自动下架时间',
  `offtype` tinyint(4) DEFAULT '1' COMMENT '下架类型(1:后台下架 2:系统下架)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_shop_id` (`shopid`) USING BTREE,
  KEY `idx_agent_id` (`agentid`) USING BTREE,
  KEY `platformtype` (`platformtype`) USING BTREE,
  KEY `isforbid` (`isforbid`,`isdelete`,`issoldout`) USING BTREE,
  KEY `idx_todayendtime` (`todayendtime`) USING BTREE,
  KEY `idx_endtime` (`endtime`) USING BTREE,
  KEY `idx_starttime` (`starttime`,`endtime`) USING BTREE,
  KEY `tips` (`tips`) USING BTREE,
  KEY `shopid` (`shopid`,`platformtype`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=253289 DEFAULT CHARSET=utf8mb4 COMMENT='商家活动表';

CREATE TABLE `agent` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `name` longtext COMMENT '代理商名称',
  `telphone` longtext COMMENT '电话号码',
  `address` longtext COMMENT '地址',
  `email` longtext COMMENT '邮箱',
  `sysmasterid` int(11) DEFAULT NULL COMMENT '管理员id',
  `isforbid` int(11) DEFAULT NULL COMMENT '是否禁用 0正常 1禁用',
  `isdelete` int(11) DEFAULT NULL COMMENT '是否已删除 0正常 1已删除',
  `createtime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `isenabledvip` int(11) DEFAULT NULL COMMENT '是否支持会员(0否  1是)',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COMMENT='代理商表';

CREATE TABLE `bwc_activity` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `act_type` varchar(255) NOT NULL DEFAULT '' COMMENT '活动分类',
  `act_name` varchar(255) NOT NULL DEFAULT '' COMMENT '活动名称',
  `start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `act_params` varchar(1500) NOT NULL DEFAULT '' COMMENT '活动参数json字段',
  `disable` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否禁用 0否1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='活动表';

CREATE TABLE `bwc_activity_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type` tinyint(4) DEFAULT NULL COMMENT '类型：1，会员红包天天领 2：下单时间限制',
  `user_id` int(11) NOT NULL COMMENT 'bwc_user.id，C用户id',
  `created_by` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_admin.id 管理员id',
  `updated_by` int(11) DEFAULT NULL COMMENT 'bwc_admin.id 管理员id',
  `data_state` tinyint(4) NOT NULL DEFAULT '0',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id_type` (`type`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=550391 DEFAULT CHARSET=utf8mb4 COMMENT='活动拉黑表';

CREATE TABLE `bwc_admin` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(32) NOT NULL COMMENT '用户名',
  `password` varchar(32) NOT NULL COMMENT '密码',
  `salt` varchar(4) NOT NULL COMMENT '密码盐',
  `admin_nick` varchar(255) NOT NULL DEFAULT '' COMMENT '用户昵称',
  `admin_role` varchar(20) NOT NULL DEFAULT '',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '所属代理id',
  `all_agent` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '全区域权限，1是2否',
  `real_name` varchar(255) NOT NULL DEFAULT '' COMMENT '真实姓名',
  `admin_portrait` varchar(255) NOT NULL DEFAULT '' COMMENT '用户头像',
  `admin_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `customer_service_qr_url` varchar(255) CHARACTER SET utf8mb4 DEFAULT NULL COMMENT '客服企微二维码',
  `last_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次登陆时间',
  `last_ip` varchar(255) NOT NULL DEFAULT '' COMMENT '上次登陆ip',
  `reset_password_time` datetime DEFAULT NULL COMMENT '重置密码时间',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态：1未启用，2已启用，3禁止登陆',
  `prohibit_publishing` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '禁止发布任务',
  `max_account_receivable` int(11) NOT NULL DEFAULT '1000000' COMMENT '商务最大待收金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `openid` varchar(255) NOT NULL DEFAULT '' COMMENT 'OpenID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_username` (`username`) USING BTREE,
  KEY `idx_admin_mobile` (`admin_mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1577 DEFAULT CHARSET=utf8;

CREATE TABLE `bwc_admin_agent` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT 'admin后台用户表',
  `agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '代理区域表id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常1删除',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=81342 DEFAULT CHARSET=utf8mb4 COMMENT='代理区域和后台管理员的绑定表';

CREATE TABLE `bwc_admin_api_visit_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '访问用户id',
  `ip` varchar(20) NOT NULL DEFAULT '' COMMENT '访问用户ip',
  `method` varchar(255) NOT NULL DEFAULT '' COMMENT '操作名',
  `params` json NOT NULL COMMENT '参数',
  `response_data` json NOT NULL COMMENT '相应数据',
  `time` datetime DEFAULT NULL COMMENT '操作时间',
  `day` date DEFAULT NULL COMMENT '操作日期',
  `token` varchar(255) NOT NULL DEFAULT '' COMMENT '访问token',
  `host` varchar(255) NOT NULL COMMENT '访问页面',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `admin_id` (`admin_id`),
  KEY `day` (`day`),
  KEY `time` (`time`),
  KEY `admin_id_2` (`admin_id`,`day`),
  KEY `method` (`method`),
  KEY `method_2` (`method`,`day`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_admin_copy1` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(32) NOT NULL COMMENT '用户名',
  `password` varchar(32) NOT NULL COMMENT '密码',
  `salt` varchar(4) NOT NULL COMMENT '密码盐',
  `admin_nick` varchar(255) NOT NULL DEFAULT '' COMMENT '用户昵称',
  `admin_role` varchar(20) NOT NULL DEFAULT '',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '所属代理id',
  `all_agent` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '全区域权限，1是2否',
  `real_name` varchar(255) NOT NULL DEFAULT '' COMMENT '真实姓名',
  `admin_portrait` varchar(255) NOT NULL DEFAULT '' COMMENT '用户头像',
  `admin_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `last_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次登陆时间',
  `last_ip` varchar(255) NOT NULL DEFAULT '' COMMENT '上次登陆ip',
  `reset_password_time` datetime DEFAULT NULL COMMENT '重置密码时间',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态：1未启用，2已启用，3禁止登陆',
  `prohibit_publishing` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '禁止发布任务',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_username` (`username`) USING BTREE,
  KEY `idx_admin_mobile` (`admin_mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=605 DEFAULT CHARSET=utf8;

CREATE TABLE `bwc_admin_daily_profit` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `calc_date` date NOT NULL COMMENT '统计日期',
  `date_month` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '日期转成数字',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '放单人id，bwc_admin.id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单区域代理id，bwc_agent.id',
  `group_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '组ID，bwc_group.id',
  `total_order_num` int(11) NOT NULL DEFAULT '0' COMMENT '订单量（总）',
  `task_receipt_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '接单价格（总）',
  `total_cashback_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实际返现（总）',
  `total_order_cashback_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单返现（总）',
  `total_middleman_task_rebate` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返点（总）',
  `total_channel_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '渠道（总）',
  `total_estimated_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '预估佣金（总）',
  `total_headquarter_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总部抽成（总）',
  `data_state` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_unique_daily_profit` (`calc_date`,`date_month`,`admin_id`,`agent_id`),
  KEY `idx_admin_id` (`admin_id`),
  KEY `idx_agent_id` (`agent_id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_calc_date` (`calc_date`)
) ENGINE=InnoDB AUTO_INCREMENT=951859 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_admin_daily_profit_change_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `daily_profit_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '放单人id，bwc_admin.id',
  `order_id` int(11) NOT NULL DEFAULT '0',
  `task_receipt_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `cashback_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实际返现',
  `order_cashback_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单返现',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_daily_profit` (`daily_profit_id`,`order_id`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11503 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_admin_dynamic_adjust_price` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `is_open` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否打开 0否; 1是',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0默认; 1竞品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_admin` (`admin_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_admin_role` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `role_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '角色id',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8183 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_admin_seller_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `admin_id` int(11) unsigned NOT NULL COMMENT '销售id，bwc_admin.id',
  `seller_id` int(11) unsigned NOT NULL COMMENT '商家id，bwc_seller.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态，0表示正常，1表示删除',
  `created_by` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_admin.id 管理员ID',
  `updated_by` int(11) DEFAULT NULL COMMENT 'bwc_admin.id 管理员ID',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=626 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_admin_silk` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓bwc_admin表id',
  `silk_admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '小蚕对应的销售id(crm成员管理)',
  `silk_account_id` int(10) NOT NULL COMMENT '小蚕对应的admin_id(系统管理组织架构)',
  `silk_callback_data` json DEFAULT NULL,
  `is_sync_city` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已经同步过城市信息：0没有，1已同步',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_silk_admin_id` (`silk_admin_id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=194 DEFAULT CHARSET=utf8mb4 COMMENT='晓晓销售关联小蚕销售id';

CREATE TABLE `bwc_advertisement` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `adv_title` varchar(255) NOT NULL DEFAULT '' COMMENT '广告标题',
  `adv_image_url` varchar(255) NOT NULL DEFAULT '' COMMENT '广告图片链接',
  `adv_skip_config` text NOT NULL COMMENT '广告跳转配置，json',
  `adv_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '广告跳转类型 0不跳转 1展示图片 2内链跳转 3http链接 4跳转到小程序 5跳转到外部app 6展示视频',
  `application` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端场景',
  `adv_position` varchar(255) NOT NULL DEFAULT 'web' COMMENT '广告位置',
  `is_nationwide` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否全国 0:否 1:是',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1显示 2禁用',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '排序',
  `min_version` varchar(255) NOT NULL DEFAULT '' COMMENT '最低版本号',
  `max_version` varchar(255) NOT NULL DEFAULT '' COMMENT '最高版本号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=469 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_advertisement_agent_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `advertisement_id` int(11) unsigned NOT NULL COMMENT '通用活动ID，关联bwc_advertisement.id',
  `agent_id` int(11) unsigned NOT NULL COMMENT '代理ID，关联bwc_agent.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_advertisement_id` (`advertisement_id`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COMMENT='广告-代理关联表';

CREATE TABLE `bwc_advertisement_click_record` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `platform` varchar(30) NOT NULL DEFAULT '' COMMENT '平台',
  `version` varchar(255) NOT NULL DEFAULT '' COMMENT '版本',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户id',
  `user_device_cid` varchar(80) NOT NULL DEFAULT '' COMMENT '设备号',
  `ad_id` int(10) NOT NULL DEFAULT '0' COMMENT 'bwc_advertisement表id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_user_device_cid` (`user_device_cid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=726069 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `agent_name` varchar(30) NOT NULL DEFAULT '' COMMENT '代理名称',
  `agent_code` varchar(32) NOT NULL DEFAULT '' COMMENT '代理编号',
  `city_code` varchar(20) NOT NULL DEFAULT '' COMMENT '城市代码',
  `agent_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '代理可用 1可用2禁用',
  `current_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '当前余额',
  `pre_order_volume_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '预存单量金额',
  `is_enable_pre_order_volume` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否启用预存单量 1启用 0禁用',
  `pre_order_volume` int(11) NOT NULL DEFAULT '0' COMMENT '预存单量',
  `check_amount` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要校验余额，1不校验，2校验',
  `warning_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '预警金额',
  `deadline_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '死线金额',
  `is_headquarter` tinyint(1) NOT NULL DEFAULT '0' COMMENT '总部/代理属性；0=否（普通代理），1=总部代理，2=非直营',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `alipay_app_id` varchar(50) NOT NULL DEFAULT '' COMMENT '支付宝商家版appid',
  `alipay_public_key` varchar(2500) NOT NULL DEFAULT '' COMMENT '支付宝公钥',
  `headquarter_charging_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '总部收费方式：1 每单固定费用，2 只抽取金币费用',
  `headquarter_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.10' COMMENT '总部抽取费用',
  `seller_release_task_commission_fee` decimal(10,2) unsigned NOT NULL DEFAULT '3.00' COMMENT '商家发布任务手续费',
  `sale_release_task_commission_fee` decimal(10,2) unsigned NOT NULL DEFAULT '2.00' COMMENT '后台发布任务手续费',
  `self_activity_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '自营活动启用 1启用2禁用',
  `mt_activity_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `mtg_gp_activity_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '美团团购活动启用 1启用 2禁用',
  `mt_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `htl_activity_enabled` tinyint(1) NOT NULL DEFAULT '2' COMMENT '灰太狼活动启用 1启用2禁用',
  `htl_subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '灰太狼活动补贴金额',
  `general_subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '通用补贴金额',
  `ele_activity_enabled` tinyint(1) NOT NULL DEFAULT '2' COMMENT '饿了么活动启用 1启用2禁用',
  `ele_feedback_activity_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '饿了么反馈活动启用 1启用2禁用',
  `ele_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `sort_rule` varchar(255) NOT NULL DEFAULT '' COMMENT '排序规则',
  `show_new_store` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否优先展示上新店铺  1开;2关',
  `app_order_no_check_enabled` tinyint(1) NOT NULL DEFAULT '2' COMMENT 'app订单号检测开关 1开;2关',
  `applet_redirect_re_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '小程序报名跳转领红包开关 1开; 2关',
  `order_detail_applet_redirect_re_enabled` tinyint(1) DEFAULT '2' COMMENT '订单详情小程序报名跳转领红包开关 1开; 2关',
  `ele_commission_ratio` tinyint(3) NOT NULL DEFAULT '0' COMMENT '饿了么佣金设置最低比例',
  `can_create_task` tinyint(1) NOT NULL DEFAULT '2' COMMENT '没有进店链接能否创建活动：1可以2不可以',
  `mt_deduct_ratio` int(10) NOT NULL DEFAULT '1000' COMMENT '美团抽成比例(万分比)',
  `ele_deduct_ratio` int(10) NOT NULL DEFAULT '1000' COMMENT '饿了么霸王餐总部抽成比例',
  `ele_feedback_cashback_min_ratio` int(10) NOT NULL DEFAULT '2000' COMMENT '饿了么专享返现比例下限(万分比)',
  `ele_feedback_deduct_ratio` int(10) NOT NULL DEFAULT '1000' COMMENT '饿了么专享抽成比例(万分比)',
  `ele_feedback_main_deduct_ratio` int(10) NOT NULL DEFAULT '500' COMMENT '饿了么专享总部抽成比例(万分比)',
  `mtg_gp_subsidy_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '美团团购统一返现渠道补贴比例（万分比）',
  `mtg_gp_unified_cash_back_headquarter_ratio` int(11) NOT NULL DEFAULT '5000' COMMENT '美团团购统一返现总部抽成比例（万分比）',
  `mtg_gp_unified_cash_back_agent_ratio` int(11) NOT NULL DEFAULT '5000' COMMENT '美团团购统一返现代理抽成比例（万分比）',
  `open_third_push_task` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否开启给第三方平台推送活动，0否1是，默认开启',
  `platforms_tip` varchar(255) NOT NULL DEFAULT '' COMMENT '分控提示的平台，多个平台用英文逗号分隔“,”',
  `platforms_re_buy` varchar(255) NOT NULL DEFAULT '' COMMENT '分控复购的平台，多个平台用英文逗号分隔“,”',
  `max_account_receivable` decimal(10,2) NOT NULL DEFAULT '1000000.00' COMMENT '商务最大待收金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `ele_main_deduct_ratio` int(11) NOT NULL COMMENT '饿了么霸王餐代理抽成比例',
  `mt_main_deduct_ratio` int(11) NOT NULL COMMENT '美团霸王餐总部抽成比例',
  `subsidy_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '美团统一返现渠道补贴比例（万分比）',
  `mtg_cash_back_to_wallet_enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '美团官方活动走美团钱包返现开关 0关闭 1开启',
  `commission_ratio` int(11) NOT NULL COMMENT '美团统一返现结算该城市佣金比例（万分比）',
  `enable_order_timeout_limit_rule` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '超时取消限制规则 2：关 1：开',
  `mt_unified_cash_back_headquarter_ratio` int(11) NOT NULL DEFAULT '5000' COMMENT '美团统一返现总部抽成比例（万分比）',
  `mt_unified_cash_back_agent_ratio` int(11) NOT NULL DEFAULT '5000' COMMENT '美团统一返现代理抽成比例（万分比）',
  `advertisement_for_bill` text COMMENT '对账单广告',
  `bargain_enabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否开启砍价捡漏 0:未开启 1:已开启',
  `is_close_platform` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否活动详情隐藏平台：1隐藏，2不隐藏',
  `enable_es_search` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否启用es搜索 0:关闭 1:启用',
  `search_sort_rule` varchar(128) NOT NULL DEFAULT '' COMMENT '搜索排序规则,默认1,2,3,4,5,6',
  `new_user_special_switch` tinyint(1) NOT NULL DEFAULT '2' COMMENT '新人专版：1开启，2关闭',
  `mz_activity_enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '美赚霸王餐活动启用开关 1启用 2禁用',
  `mz_headquarter_ratio` int(11) NOT NULL DEFAULT '10000' COMMENT '美赚霸王餐总部抽成比例（万分比）',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_city_code` (`city_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=308 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_activity` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(15) NOT NULL DEFAULT '' COMMENT '活动名称',
  `invite_cover` varchar(1500) NOT NULL DEFAULT '' COMMENT '封面图URL',
  `sign_up_cover` varchar(1500) NOT NULL DEFAULT '' COMMENT '封面图URL',
  `invite_address_type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '进群地址类型 1url链接;2图片链接',
  `invite_group_entry_address` varchar(1500) NOT NULL DEFAULT '' COMMENT '进群地址',
  `sign_up_address_type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '进群地址类型 1url链接;2图片链接',
  `sign_up_group_entry_address` varchar(1500) NOT NULL DEFAULT '' COMMENT '进群地址',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '活动开始时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '活动结束时间',
  `uri` varchar(100) DEFAULT NULL COMMENT '活动链接URI',
  `share_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享人数',
  `register_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册人数',
  `cash_back_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现人数',
  `sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单人数',
  `order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单收益人数',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1. 生效  2. 暂停',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uri` (`uri`)
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动表';

CREATE TABLE `bwc_agent_activity_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动ID',
  `activity_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '活动URL',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '活动封面url',
  `share_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享人数',
  `register_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册人数',
  `cash_back_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现人数',
  `sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单人数',
  `order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单收益人数',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1. 开启  2. 关闭 3. 过期',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5483 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动配置表';

CREATE TABLE `bwc_agent_activity_ext` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(15) NOT NULL DEFAULT '0' COMMENT '活动id',
  `desc` varchar(255) NOT NULL DEFAULT '' COMMENT 'desc',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT 'key',
  `value` text COMMENT '值',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_act_key` (`activity_id`,`key`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=123 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动扩展表';

CREATE TABLE `bwc_agent_activity_invite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `invite_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '邀请人数',
  `reward_gold` decimal(10,2) unsigned NOT NULL COMMENT '奖励积分',
  `actual_invite_num` int(11) unsigned NOT NULL COMMENT '增加邀请人数',
  `actual_reward_gold` decimal(10,2) unsigned NOT NULL COMMENT '增加奖励积分',
  `level` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '阶梯级别',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=241 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动邀请奖励表';

CREATE TABLE `bwc_agent_activity_invite_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理活动id',
  `activity_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动用户id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '被邀请用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '收入',
  `finish_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1正常，2已撤销',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=57994 DEFAULT CHARSET=utf8mb4 COMMENT='用户-邀请阶梯关联表';

CREATE TABLE `bwc_agent_activity_other` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动ID',
  `title` varchar(15) NOT NULL DEFAULT '' COMMENT '活动标题',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '活动介绍',
  `url` varchar(1500) NOT NULL DEFAULT '' COMMENT '活动跳转地址',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动-其他活动表';

CREATE TABLE `bwc_agent_activity_red_envelopes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动ID',
  `name` varchar(20) NOT NULL DEFAULT '' COMMENT '红包名称',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `end_time` datetime DEFAULT NULL COMMENT '红包结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动发放红包表';

CREATE TABLE `bwc_agent_activity_sign_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单数量',
  `reward_gold` decimal(10,2) unsigned NOT NULL COMMENT '奖励积分',
  `actual_sign_up_num` int(11) unsigned NOT NULL COMMENT '增加邀请人数',
  `actual_reward_gold` decimal(10,2) unsigned NOT NULL COMMENT '增加奖励积分',
  `level` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '阶梯级别',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=149 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动下单奖励表';

CREATE TABLE `bwc_agent_activity_sign_up_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理活动id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '参与活动用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '收入',
  `finish_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1正常，2已撤销',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=475576 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_activity_user_limit` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_activity` (`user_id`,`activity_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='用户活动限制表';

CREATE TABLE `bwc_agent_activity_user_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动用户id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型，1邀请，2下单',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `oat` (`order_id`,`activity_id`,`type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=842908 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动用户表';

CREATE TABLE `bwc_agent_activity_user_sign_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `total_quantity` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总数额',
  `finished_order_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '已完成订单数量',
  `finished_order_level` int(11) unsigned DEFAULT '0' COMMENT '已完成活动档位',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态 1正常; 2禁用',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型，1邀请，2订单',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `aut` (`activity_id`,`user_id`,`type`)
) ENGINE=InnoDB AUTO_INCREMENT=253916 DEFAULT CHARSET=utf8mb4 COMMENT='城市活动用户表';

CREATE TABLE `bwc_agent_ad` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `agent_id` int(10) NOT NULL COMMENT '代理id',
  `adv_image_url` varchar(255) NOT NULL DEFAULT '' COMMENT '霸屏广告图片url',
  `adv_invite_image_url` varchar(255) NOT NULL DEFAULT '' COMMENT '邀请活动霸屏广告url',
  `adv_skip_config` text NOT NULL COMMENT '广告跳转配置',
  `adv_position` varchar(255) NOT NULL DEFAULT '' COMMENT '广告位置',
  `adv_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '广告跳转类型 0不跳转 1展示图片 2内链跳转 3http链接 4跳转到小程序 5跳转到外部app',
  `ad_show_count` int(10) NOT NULL DEFAULT '0' COMMENT '广告当日展现次数',
  `ad_start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `ad_end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13315 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_area_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `date_month` int(11) NOT NULL DEFAULT '0' COMMENT '日期转成数字',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT 'key',
  `value` text COMMENT 'value',
  `desc` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=37900 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_area_config_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `date_month` int(11) NOT NULL DEFAULT '0' COMMENT '日期转成数字',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `data` text COMMENT '配置数据',
  `is_exec` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否执行了计划；0否，1是, 2第一次初始化',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2584 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_balance_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理城市id',
  `agent_name` varchar(30) NOT NULL DEFAULT '' COMMENT '代理城市名称',
  `current_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '当前余额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_agent_snapshot_date` (`agent_id`,`snapshot_date`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=21488 DEFAULT CHARSET=utf8mb4 COMMENT='代理城市余额快照';

CREATE TABLE `bwc_agent_billing_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `type` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '类型 1充值，2短信通知扣费，3短信验证码扣费，4用户返现扣费，5邀请奖励扣费，6机审接口付费，7每单服务费，8中间人打款，9管理员扣款，10渠道推广分佣，11渠道推广退款，12商家支付打款给代理，13代理提现，14代理提现驳回 15APP推送通知 16ai外呼 17 全区域分成扣费 18 全区域分成收入 19活动完成-下单返利 20活动完成-邀请返利 21订单取消扣除积分 22订单扣除积分 23订单扣除金币 24订单取消扣除团员奖励 25订单取消扣除下单返利活动奖励 26订单取消扣除邀请返利活动奖励 27订单增加积分 28订单增加金币 29订单恢复增加积分 30订单恢复增加团员奖励 31订单恢复增加下单返利活动奖励 32订单恢复增加邀请返利活动奖励 33营销推送 34商家退款-扣费 35运营短信 36自动任务-APP推送 37自动任务-短信 38渠道推广分佣（上级）39渠道推广退款（上级）40物料返现补贴-扣费 41市场部拉新提成-扣费 42商家获客费用-扣费 43用户返现-扣费（通用活动）44订单助力加返-增加用户积分 45餐餐有返中间人返佣 46订单助力加返-扣除用户积分 47助力领现金现金任务-扣除代理 48助力领现金-可提现金币-扣除代理',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '关联订单id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '关联任务id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '关联用户id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '金额',
  `data` text COMMENT '短信相关json数据',
  `out_biz_no` varchar(100) DEFAULT NULL COMMENT '支付宝外部单号',
  `trans_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '支付宝支付时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_out_biz_no` (`out_biz_no`) USING BTREE,
  KEY `agent_id` (`data_state`,`agent_id`,`create_time`,`type`,`order_id`,`task_id`,`user_id`,`amount`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_type_agent_id_create_time` (`type`,`agent_id`,`create_time`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_trans_date` (`trans_date`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=326358435 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_agent_deductions_sync` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `out_agent_deductions_Id` varchar(64) NOT NULL DEFAULT '' COMMENT '外补扣款id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `scene_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '扣款场景类型 0:伴餐系统补贴扣款 1:商家提成扣款 2:商务提成扣款',
  `extend_params` json DEFAULT NULL COMMENT '扩展参数',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=93952 DEFAULT CHARSET=utf8mb4 COMMENT='外部代理扣款同步表';

CREATE TABLE `bwc_agent_distance` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `distance` int(11) unsigned NOT NULL DEFAULT '10000' COMMENT '距离，单位米',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `agent_id_idx` (`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_dynamic_adjust_price` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `is_open` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否打开 0否; 1是',
  `adjust_way` tinyint(3) NOT NULL DEFAULT '0' COMMENT '1最多返到无利润; 2低于餐标3元; 3低于餐标5元; 4最多返到餐标',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0默认; 1竞品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_agent` (`agent_id`,`type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_dynamic_adjust_price_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `before_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '调整前',
  `current_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '当前',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_general_subsidy` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `general_subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '通用补贴金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent` (`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COMMENT='城市通用补贴配置表';

CREATE TABLE `bwc_agent_middleman_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_id` tinyint(2) DEFAULT '0' COMMENT '平台id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家账单id',
  `seller_bill_no` varchar(100) NOT NULL DEFAULT '' COMMENT '商家的账单号',
  `seller_bill_fee` decimal(10,2) DEFAULT NULL COMMENT '商家应付的账单总金额',
  `seller_bill_payment_time` datetime DEFAULT NULL COMMENT '商家账单支付时间',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理商id',
  `agent_bill_no` varchar(100) NOT NULL DEFAULT '' COMMENT '本次付款账单号',
  `agent_trade_no` varchar(100) NOT NULL DEFAULT '' COMMENT '打款后的支付流水号',
  `agent_bill_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '账单状态 1. 创建 2. 已结算 3. 打款失败',
  `agent_income` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '代理商收入',
  `agent_transfer_response` text COMMENT '转账的返回值',
  `middleman_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '中间人id',
  `middleman_bill_no` varchar(100) NOT NULL DEFAULT '' COMMENT '中间人本次付款账单号',
  `middleman_trade_no` varchar(100) NOT NULL DEFAULT '' COMMENT '给中间人打款后的支付流水号',
  `middleman_bill_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '账单状态 1. 创建 2. 已结算 3. 打款失败',
  `middleman_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '中间人收入',
  `middleman_payment_time` datetime DEFAULT NULL COMMENT '中间人打款时间',
  `headquarter_income` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '付给总部的金额',
  `payment_commission_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '支付手续费',
  `customer_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '应付给顾客的金额',
  `middleman_transfer_response` text COMMENT '转账的返回值',
  `rebate_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '推广金额',
  `miscellaneous_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '其他费用（短信通知费用、机审审核接口费用、每单服务费）',
  `provider_agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '上单城市agent_id',
  `provider_agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '上单城市分成收入',
  `loss_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '亏损金额',
  `net_profit` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '纯利润',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `middleman_payment_channel` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '中间人支付渠道，默认0：支付宝打款 1：到中间人账户余额',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_seller_bill_no` (`seller_bill_no`) USING BTREE,
  KEY `idx_agent_bill_no` (`agent_bill_no`) USING BTREE,
  KEY `idx_middleman_bill_no` (`middleman_bill_no`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`) USING BTREE,
  KEY `idx_middleman_id` (`middleman_id`,`data_state`,`middleman_bill_status`,`middleman_income`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12370775 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='代理商表';

CREATE TABLE `bwc_agent_ratio_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) unsigned NOT NULL COMMENT '代理区域id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型配置：1（美团官方活动比例配置）',
  `start_value` int(1) NOT NULL DEFAULT '0' COMMENT '比例区间，开始字段（万分比）',
  `end_value` int(1) NOT NULL DEFAULT '0' COMMENT '比例区间结束字段（万分比）',
  `main_deduct_ratio` int(1) NOT NULL DEFAULT '0' COMMENT '总部抽成比例（万分比）',
  `agent_deduct_ratio` int(1) NOT NULL DEFAULT '0' COMMENT '代理抽成比例（万分比）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_agent_id` (`agent_id`,`data_state`,`type`,`start_value`,`end_value`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8284 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_recover_amount` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `type` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '类型 1充值，2短信通知扣费，3短信验证码扣费，4用户返现扣费，5邀请奖励扣费，6机审接口付费，7每单服务费，8中间人打款，9管理员扣款，10渠道推广分佣，11渠道推广退款，12商家支付打款给代理，13代理提现，14代理提现驳回 15APP推送通知  16ai外呼 17 全区域分成扣费  18 全区域分成收入 19活动完成-下单返利 20活动完成-邀请返利 21订单取消扣除积分 22订单扣除积分 23订单扣除金币 24订单取消扣除团员奖励 25订单取消扣除下单返利活动奖励 26订单取消扣除邀请返利活动奖励 27订单增加积分 28订单增加金币 29订单恢复增加积分 30订单恢复增加团员奖励 31订单恢复增加下单返利活动奖励 32订单恢复增加邀请返利活动奖励',
  `currency_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '货币类型1积分2金币',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `remark` varchar(30) NOT NULL DEFAULT '' COMMENT '扣款原因',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1. 欠款中 2. 已补齐',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`,`type`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=90610 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_recover_amount_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `agent_recover_amount_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_agent_recover_amount主键id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `type` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '类型 1充值，2短信通知扣费，3短信验证码扣费，4用户返现扣费，5邀请奖励扣费，6机审接口付费，7每单服务费，8中间人打款，9管理员扣款，10渠道推广分佣，11渠道推广退款，12商家支付打款给代理，13代理提现，14代理提现驳回 15APP推送通知  16ai外呼 17 全区域分成扣费  18 全区域分成收入 19活动完成-下单返利 20活动完成-邀请返利 21订单取消扣除积分 22订单扣除积分 23订单扣除金币 24订单取消扣除团员奖励 25订单取消扣除下单返利活动奖励 26订单取消扣除邀请返利活动奖励 27订单增加积分 28订单增加金币 29订单恢复增加积分 30订单恢复增加团员奖励 31订单恢复增加下单返利活动奖励 32订单恢复增加邀请返利活动奖励',
  `currency_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '货币类型1积分2金币',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `remark` varchar(30) NOT NULL DEFAULT '' COMMENT '扣款原因',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1. 欠款中 2. 已补齐',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2985797 DEFAULT CHARSET=utf8mb4 COMMENT='负积分记录快照';

CREATE TABLE `bwc_agent_scene_platform` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `platform` varchar(50) NOT NULL DEFAULT '' COMMENT '客户端平台',
  `scene` varchar(50) NOT NULL DEFAULT '' COMMENT '场景',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `scene` (`scene`),
  KEY `platform_abbr` (`platform`)
) ENGINE=InnoDB AUTO_INCREMENT=100981 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_seller_pay_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '代理id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '支付金额',
  `seller_bill_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家账单id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=10812196 DEFAULT CHARSET=utf8mb4 COMMENT='商家支付代理账单记录表';

CREATE TABLE `bwc_agent_sort` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_urban_activity_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `cover` varchar(1500) NOT NULL DEFAULT '' COMMENT '活动封面url',
  `main_border_color` varchar(10) NOT NULL DEFAULT '' COMMENT '边框主题颜色',
  `main_inner_border_color` varchar(10) NOT NULL COMMENT '内边框主题颜色',
  `index_icon` varchar(1500) NOT NULL DEFAULT '' COMMENT '主页图标',
  `rules` varchar(2500) NOT NULL DEFAULT '' COMMENT '活动规则',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1. 开启  2. 关闭',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `agent_id` (`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=345 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_agent_wechat` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `is_score_wechat` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否开启积分微信：0不开启，1开启',
  `is_gold_wechat` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否开启金币微信提现：0不开启，1开启',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_agent` (`data_state`,`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=300 DEFAULT CHARSET=utf8mb4 COMMENT='代理关联表：是否开启微信提现';

CREATE TABLE `bwc_agent_withdraw_cash` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '代理id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '提现金额',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝姓名',
  `image_url` varchar(300) NOT NULL DEFAULT '' COMMENT '提现凭证',
  `ext` varchar(10) NOT NULL DEFAULT '' COMMENT '上传的凭证后缀格式',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '提现状态：1提现审核中，2审核通过，3审核失败',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '提现人id',
  `audit_id` int(10) NOT NULL DEFAULT '0' COMMENT '审核人',
  `audit_image_url` varchar(300) NOT NULL DEFAULT '' COMMENT '审核通过/不通过凭证',
  `audit_ext` varchar(10) NOT NULL DEFAULT '' COMMENT '审核人上传的文件后缀格式',
  `audit_remark` varchar(300) DEFAULT '' COMMENT '审核通过/不通过备注',
  `audit_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '审核时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=898 DEFAULT CHARSET=utf8mb4 COMMENT='代理提现记录表';

CREATE TABLE `bwc_alipay_account_order_number` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单次数',
  `app_order_reward` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '获取APP首单奖励 1. 可以获取  2无法获取',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_alipay_account` (`user_alipay_account`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=737341 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_alipay_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '封号原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_alipay_account` (`alipay_account`,`data_state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=281497 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_alipay_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户id',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '用户支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '用户支付宝姓名',
  `old_user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '变更之前用户的支付宝账号',
  `old_user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '变更之前用户支付宝姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_user_alipay_account` (`user_alipay_account`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=807877 DEFAULT CHARSET=utf8mb4 COMMENT='用户变更支付宝信息记录';

CREATE TABLE `bwc_all_amount_cash_no_qualification_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=84277 DEFAULT CHARSET=utf8mb4 COMMENT='新版首单全额返老用户无资格表';

CREATE TABLE `bwc_amap_service` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `service_key` varchar(255) NOT NULL DEFAULT '' COMMENT 'key',
  `service_name` varchar(255) NOT NULL DEFAULT '' COMMENT '服务名称',
  `service_desc` varchar(255) NOT NULL DEFAULT '' COMMENT '服务描述',
  `service_code` varchar(255) NOT NULL DEFAULT '' COMMENT '服务编码',
  `sid` varchar(255) NOT NULL DEFAULT '' COMMENT '服务SID',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_anti_crawler_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `ip` varchar(30) NOT NULL DEFAULT '' COMMENT 'ip',
  `user_device_cid` varchar(50) NOT NULL DEFAULT '' COMMENT '设备id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `ip` (`ip`),
  KEY `user_device_cid` (`user_device_cid`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_app_push` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `identification_id` varchar(100) NOT NULL DEFAULT '' COMMENT '返回的：msg_id',
  `template_code` varchar(50) NOT NULL DEFAULT '' COMMENT '发送模板',
  `audiences` json DEFAULT NULL COMMENT '发送目标',
  `params` json DEFAULT NULL COMMENT '发起请求时候的json',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '发送状态：1发送中，2发送成功，3发送失败',
  `error_msg` text COMMENT '失败原因',
  `msg_event_log_id` int(11) DEFAULT '0' COMMENT '消息事件日志id',
  `marketing_push_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '运营营销推送日志id',
  `agent_deduction_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '代理扣款状态0未扣款 1已扣款',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_identification_id` (`identification_id`) USING BTREE,
  KEY `idx_marketing_push_log_id` (`marketing_push_log_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=676098925 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_app_push_bak` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `identification_id` varchar(100) NOT NULL DEFAULT '' COMMENT '返回的：msg_id',
  `template_code` varchar(50) NOT NULL DEFAULT '' COMMENT '发送模板',
  `audiences` json DEFAULT NULL COMMENT '发送目标',
  `params` json DEFAULT NULL COMMENT '发起请求时候的json',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '发送状态：1发送中，2发送成功，3发送失败',
  `error_msg` text COMMENT '失败原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_identification_id` (`identification_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_app_push_channel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT 'APP推送渠道名称',
  `code` varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '系统编码',
  `enabled` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否开启',
  `config` text CHARACTER SET utf8 NOT NULL COMMENT '配置',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_app_push_template` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `channel_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'app推送渠道id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '发送类型 1. 离线消息 2. 厂商渠道提醒 3. 其他',
  `code` varchar(50) CHARACTER SET utf8 NOT NULL COMMENT '模板编码',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '模板名称',
  `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用 1是其他否',
  `config` text COMMENT '配置',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=96 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_app_version` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app_name` varchar(255) NOT NULL DEFAULT '' COMMENT '应用名',
  `app_version_code` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '版本号',
  `app_version_name` varchar(255) NOT NULL DEFAULT '' COMMENT '版本名',
  `app_update_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '更新类型（1：整包更新，2：热更新）',
  `app_resource_url` varchar(500) NOT NULL DEFAULT '' COMMENT '资源下载地址',
  `app_lowest_version` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '最低兼容版本',
  `is_force` tinyint(1) unsigned NOT NULL COMMENT '是否强制更新(1:是，2：否)',
  `platform` varchar(32) NOT NULL DEFAULT '' COMMENT '平台',
  `is_enabled` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否启用（1：是，2：否）',
  `update_enabled_time` timestamp NULL DEFAULT NULL COMMENT '更新生效时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1禁用',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `platform_ext_info` json DEFAULT NULL COMMENT '安卓特有，平台生效字段JSON， 1：小米 2：华为 3：应用宝 4：vivo 5：opopo',
  `text` text COMMENT '更新版本展示文案',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COMMENT='app版本表';

CREATE TABLE `bwc_application` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `client_key` varchar(255) NOT NULL DEFAULT '' COMMENT '客户端key',
  `app_name` varchar(255) NOT NULL DEFAULT '' COMMENT '应用名称',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_authority` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `auth_name` varchar(255) NOT NULL COMMENT '权限名称',
  `auth_key` varchar(255) NOT NULL COMMENT '权限key',
  `auth_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '权限类型 0页面 1接口 2操作',
  `auth_parent_page` int(11) NOT NULL DEFAULT '0' COMMENT '父级页面',
  `auth_group` varchar(255) NOT NULL DEFAULT '' COMMENT '权限组',
  `auth_description` text NOT NULL COMMENT '权限描述',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8;

CREATE TABLE `bwc_authority_temp` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '权限名称',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT '权限key',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '权限类型 0页面 1组件 2接口',
  `method` varchar(20) NOT NULL DEFAULT '' COMMENT 'GET/POST',
  `parent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属页面id',
  `group` varchar(50) NOT NULL DEFAULT '' COMMENT '分组',
  `description` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '权限描述',
  `disabled` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否禁用1是2否',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2524 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_auto_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_title` varchar(255) NOT NULL DEFAULT '' COMMENT '自动任务标题',
  `target_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '目标类型1:用户 2:商家',
  `task_condition_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务触发条件id',
  `time_interval_type` int(11) NOT NULL DEFAULT '0' COMMENT '触发时间间隔0:永不 1:7天 2:15天 3:30天 4:一年',
  `event` varchar(255) NOT NULL DEFAULT '' COMMENT '触发事件(存的数组json) 1:APP推送 2:发送短信 3:赠送优惠券 4:赠送晓晓红包',
  `params` text COMMENT '事件参数json',
  `run_time` varchar(12) NOT NULL DEFAULT '' COMMENT '每日运行时间(格式10:00)',
  `status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '状态（0开启 1关闭）',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COMMENT='自动任务表';

CREATE TABLE `bwc_auto_task_agent` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `auto_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '自动任务id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6529 DEFAULT CHARSET=utf8mb4 COMMENT='自动任务代理城市表';

CREATE TABLE `bwc_auto_task_condition` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `condition_name` varchar(255) NOT NULL DEFAULT '' COMMENT '条件名称',
  `condition_code` varchar(255) NOT NULL DEFAULT '' COMMENT '条件code',
  `target_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '类型 1用户 2商家',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COMMENT='任务触发条件表';

CREATE TABLE `bwc_auto_task_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `auto_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '自动任务id',
  `task_title` varchar(255) NOT NULL DEFAULT '' COMMENT '自动任务标题',
  `task_condition_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务触发条件id',
  `event` varchar(255) NOT NULL DEFAULT '' COMMENT '触发事件(存的数组json) 1:APP推送 2:发送短信 3:赠送优惠券 4:赠送晓晓红包',
  `params` text COMMENT '事件参数json',
  `executed_user_num` int(11) NOT NULL DEFAULT '0' COMMENT '已执行用户数量',
  `app_push_user_num` int(11) NOT NULL DEFAULT '0' COMMENT 'APP推送发起用户数',
  `sms_user_num` int(11) NOT NULL DEFAULT '0' COMMENT '短信发起用户数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_auto_task_id` (`auto_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=612 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_auto_task_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `auto_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '自动任务id',
  `target_id` int(11) NOT NULL DEFAULT '0' COMMENT '执行目标用户id',
  `target_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '目标类型1:用户 2:商家',
  `auto_task_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '自动任务日志id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_target_id` (`target_id`),
  KEY `auto_task_id_target_type_gmt_created_index` (`auto_task_id`,`target_type`,`gmt_created`),
  KEY `idx_auto_task_log` (`auto_task_log_id`,`target_type`)
) ENGINE=InnoDB AUTO_INCREMENT=8287130 DEFAULT CHARSET=utf8mb4 COMMENT='自动任务触发记录表';

CREATE TABLE `bwc_auto_task_red_envelopes_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `auto_task_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '自动任务日志ID',
  `task_condition_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务触发条件id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `red_envelopes_id` int(11) NOT NULL DEFAULT '0' COMMENT '红包id（手动领取后需要更新这个字段）',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `red_envelope_period` int(11) NOT NULL DEFAULT '0' COMMENT '红包期限（天数，红包到账到时候算起；0：无期限）',
  `type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '红包类型(1自动发放的红包,2需要手动领取的红包)',
  `is_receive` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否已领取（0未领取，1已领取）',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id_type_receive` (`user_id`,`type`,`is_receive`),
  KEY `idx_task_condition_id` (`task_condition_id`),
  KEY `idx_red_envelopes_id` (`red_envelopes_id`),
  KEY `idx_user_id` (`user_id`,`gmt_created`,`is_delete`)
) ENGINE=InnoDB AUTO_INCREMENT=43745628 DEFAULT CHARSET=utf8mb4 COMMENT='自动任务发放的红包记录表';

CREATE TABLE `bwc_bank` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `bank_name` varchar(80) NOT NULL COMMENT '银行名字',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '（备用）银行类型：1常见银行，0不常见',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `bank_name` (`bank_name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7164 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_banner` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `banner_title` varchar(255) NOT NULL DEFAULT '' COMMENT 'banner标题',
  `banner_image_url` varchar(255) NOT NULL DEFAULT '' COMMENT 'banner图片链接',
  `banner_target_path` varchar(1500) NOT NULL DEFAULT '' COMMENT 'banner跳转地址',
  `banner_target_applet_code` varchar(1500) NOT NULL DEFAULT '' COMMENT 'banner跳转目标applet',
  `banner_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT 'banner类型 0不跳转 1 跳转到小程序，applet_code + path都返回 2 外链web跳转 返回path 3 展示图片 返回path',
  `banner_cate` varchar(255) NOT NULL DEFAULT '' COMMENT '广告类型key',
  `banner_scene` varchar(255) NOT NULL DEFAULT 'web' COMMENT '场景值',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1显示 2禁用',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '排序',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_banner_cate` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `cate_key` varchar(255) NOT NULL DEFAULT '' COMMENT '广告类型key',
  `cate_name` varchar(255) NOT NULL DEFAULT '' COMMENT '广告类型名称',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_bc_order_sync` (
  `id` int(11) NOT NULL COMMENT '主键id',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `user_id` int(1) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `user_nick` varchar(50) NOT NULL DEFAULT '' COMMENT '用户昵称',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '推广员id',
  `platform_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单平台id',
  `order_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '订单联系号码',
  `order_phone_tail` varchar(20) NOT NULL DEFAULT '' COMMENT '手机尾号',
  `order_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '-2已驳回 -1已取消 1审核中 2已完成',
  `draw_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '抽奖状态 0:未抽奖 1:已抽奖',
  `payment_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '佣金入账状态 0:未入账 1:已入账',
  `middleman_id` int(11) NOT NULL COMMENT '中间人id',
  `middleman_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '中间人收入',
  `income_time` datetime DEFAULT NULL COMMENT '佣金入账时间',
  `time_node` varchar(255) NOT NULL COMMENT '时间节点',
  `tenant_id` int(11) NOT NULL DEFAULT '0' COMMENT '租户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_id` (`middleman_id`,`gmt_created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='伴餐订单同步表';

CREATE TABLE `bwc_bill_change_fee_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型：1账单金额修改（未支付账单），2分账账单表修改订单金额，3分账账单表修改中间人金额，4账单金额修改（已支付账单）',
  `bill_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '修改后的金额',
  `old_bill_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '修改之前的金额',
  `reason` varchar(500) NOT NULL DEFAULT '' COMMENT '修改原因',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `bill_id` int(10) NOT NULL DEFAULT '0' COMMENT '账单id',
  `agent_middleman_bill_id` int(10) NOT NULL DEFAULT '0' COMMENT '分账账单表id',
  `middleman_id` int(10) NOT NULL DEFAULT '0' COMMENT '中间人id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_agent_bill_id_type` (`agent_middleman_bill_id`,`type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=867287 DEFAULT CHARSET=utf8mb4 COMMENT='账单相关修改金额日志表';

CREATE TABLE `bwc_blacklist_map` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户id',
  `blacklist_phone` varchar(11) NOT NULL DEFAULT '' COMMENT '黑名单手机号',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_user_id_phone` (`user_id`,`blacklist_phone`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=44923 DEFAULT CHARSET=utf8mb4 COMMENT='用户和黑名单手机号映射表';

CREATE TABLE `bwc_blacklist_rules` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '匹配类型:1:登录ip，2设备号，3支付宝姓名，4支付宝账号，5实时ip，6极光设备号，7实名认证身份证号， 8手机号',
  `content` varchar(255) NOT NULL DEFAULT '' COMMENT '匹配内容',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '新增时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  PRIMARY KEY (`id`),
  KEY `idx_content` (`type`,`content`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15198 DEFAULT CHARSET=utf8mb4 COMMENT='自动拉黑规则表';

CREATE TABLE `bwc_brand` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL COMMENT '大牌名称',
  `logo` varchar(255) NOT NULL COMMENT 'logo',
  `cover` varchar(255) NOT NULL COMMENT '封面主图',
  `banner` json NOT NULL COMMENT '轮播图',
  `weight` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '权重：范围0 - 1',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否启用，1：是 0：否',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `theme_color` varchar(64) DEFAULT NULL COMMENT '品牌主题色',
  `theme_color_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '主题色是否对活动生效 0：否 1：是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COMMENT='大牌专享表';

CREATE TABLE `bwc_business_platform` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_name` varchar(10) NOT NULL DEFAULT '' COMMENT '平台名称',
  `display_name` varchar(10) NOT NULL DEFAULT '' COMMENT '展示名称',
  `platform_abbreviation` varchar(32) NOT NULL DEFAULT '' COMMENT '平台简称（英文简写）',
  `platform_logo` varchar(255) NOT NULL DEFAULT '' COMMENT '平台logo',
  `main_color` varchar(20) NOT NULL DEFAULT '' COMMENT '平台主色',
  `contrast_color` varchar(20) NOT NULL DEFAULT '' COMMENT '平台反差色',
  `task_details_advertisement_position` varchar(20) NOT NULL DEFAULT '' COMMENT '任务详情页广告位置',
  `order_example_images_config` varchar(1500) NOT NULL DEFAULT '' COMMENT '订单示例图片配置',
  `task_registration_instructions` varchar(1500) NOT NULL DEFAULT '' COMMENT '报名须知',
  `task_matters_needing_attention` varchar(1500) NOT NULL DEFAULT '' COMMENT '注意事项',
  `task_detailed_rules` text NOT NULL COMMENT '详细规则',
  `task_detailed_rules_old` text COMMENT '详细规则（旧）',
  `text_color` varchar(20) NOT NULL DEFAULT '' COMMENT '文字颜色',
  `icon_bg_color` varchar(20) NOT NULL DEFAULT '' COMMENT '图标背景颜色',
  `index_bg_image` varchar(255) NOT NULL COMMENT '主页列表背景图片',
  `activity_flow` text COMMENT '活动流程，json',
  `order_flow` text COMMENT '订单流程，json',
  `machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否机审1是2否',
  `is_order_reminder` tinyint(1) NOT NULL DEFAULT '2' COMMENT '下单提醒开关，1开；2关',
  `reminder_frequency` tinyint(1) NOT NULL DEFAULT '2' COMMENT '提醒频率 1仅提醒一次；2总是提醒',
  `reminder_text` varchar(1500) NOT NULL DEFAULT '' COMMENT '提醒文案',
  `modify_frequency_time` int(11) NOT NULL DEFAULT '0' COMMENT '修改频率的时间戳',
  `order_submit_time` int(11) NOT NULL DEFAULT '0' COMMENT '下单倒计时时间',
  `is_timeout_order_reminder` tinyint(1) NOT NULL DEFAULT '2' COMMENT '超时下单提醒开关，1开；2关',
  `timeout_time` varchar(20) NOT NULL DEFAULT '' COMMENT '超时时间设置',
  `timeout_reminder_text` varchar(1500) NOT NULL DEFAULT '' COMMENT '超时弹窗文案',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `task_detailed_rules_order_limit` text COMMENT '详细规则（超时取消)',
  `task_registration_instructions_order_limit` text COMMENT '报名须知（超时取消)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_platform_abbreviation` (`platform_abbreviation`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_business_platform_20231013` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_name` varchar(10) NOT NULL DEFAULT '' COMMENT '平台名称',
  `platform_abbreviation` varchar(10) NOT NULL DEFAULT '' COMMENT '平台简称（英文简写）',
  `platform_logo` varchar(255) NOT NULL DEFAULT '' COMMENT '平台logo',
  `main_color` varchar(20) NOT NULL DEFAULT '' COMMENT '平台主色',
  `contrast_color` varchar(20) NOT NULL DEFAULT '' COMMENT '平台反差色',
  `task_details_advertisement_position` varchar(20) NOT NULL DEFAULT '' COMMENT '任务详情页广告位置',
  `order_example_images_config` varchar(1500) NOT NULL DEFAULT '' COMMENT '订单示例图片配置',
  `task_registration_instructions` varchar(1500) NOT NULL DEFAULT '' COMMENT '报名须知',
  `task_matters_needing_attention` varchar(1500) NOT NULL DEFAULT '' COMMENT '注意事项',
  `task_detailed_rules` varchar(1500) NOT NULL DEFAULT '' COMMENT '详细规则',
  `text_color` varchar(20) NOT NULL DEFAULT '' COMMENT '文字颜色',
  `icon_bg_color` varchar(20) NOT NULL DEFAULT '' COMMENT '图标背景颜色',
  `index_bg_image` varchar(255) NOT NULL COMMENT '主页列表背景图片',
  `activity_flow` text COMMENT '活动流程，json',
  `order_flow` text COMMENT '订单流程，json',
  `machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否机审1是2否',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_business_platform_20250410` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_name` varchar(10) NOT NULL DEFAULT '' COMMENT '平台名称',
  `platform_abbreviation` varchar(32) NOT NULL DEFAULT '' COMMENT '平台简称（英文简写）',
  `platform_logo` varchar(255) NOT NULL DEFAULT '' COMMENT '平台logo',
  `main_color` varchar(20) NOT NULL DEFAULT '' COMMENT '平台主色',
  `contrast_color` varchar(20) NOT NULL DEFAULT '' COMMENT '平台反差色',
  `task_details_advertisement_position` varchar(20) NOT NULL DEFAULT '' COMMENT '任务详情页广告位置',
  `order_example_images_config` varchar(1500) NOT NULL DEFAULT '' COMMENT '订单示例图片配置',
  `task_registration_instructions` varchar(1500) NOT NULL DEFAULT '' COMMENT '报名须知',
  `task_matters_needing_attention` varchar(1500) NOT NULL DEFAULT '' COMMENT '注意事项',
  `task_detailed_rules` text NOT NULL COMMENT '详细规则',
  `text_color` varchar(20) NOT NULL DEFAULT '' COMMENT '文字颜色',
  `icon_bg_color` varchar(20) NOT NULL DEFAULT '' COMMENT '图标背景颜色',
  `index_bg_image` varchar(255) NOT NULL COMMENT '主页列表背景图片',
  `activity_flow` text COMMENT '活动流程，json',
  `order_flow` text COMMENT '订单流程，json',
  `machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否机审1是2否',
  `is_order_reminder` tinyint(1) NOT NULL DEFAULT '2' COMMENT '下单提醒开关，1开；2关',
  `reminder_frequency` tinyint(1) NOT NULL DEFAULT '2' COMMENT '提醒频率 1仅提醒一次；2总是提醒',
  `reminder_text` varchar(1500) NOT NULL DEFAULT '' COMMENT '提醒文案',
  `modify_frequency_time` int(11) NOT NULL DEFAULT '0' COMMENT '修改频率的时间戳',
  `order_submit_time` int(11) NOT NULL DEFAULT '0' COMMENT '下单倒计时时间',
  `is_timeout_order_reminder` tinyint(1) NOT NULL DEFAULT '2' COMMENT '超时下单提醒开关，1开；2关',
  `timeout_time` varchar(20) NOT NULL DEFAULT '' COMMENT '超时时间设置',
  `timeout_reminder_text` varchar(1500) NOT NULL DEFAULT '' COMMENT '超时弹窗文案',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `task_detailed_rules_old` varchar(1500) DEFAULT NULL COMMENT '详细规则（旧）',
  `task_detailed_rules_order_limit` text COMMENT '详细规则（超时取消)',
  `task_registration_instructions_order_limit` text COMMENT '报名须知（超时取消)',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_business_platform_ext` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_abbreviation` varchar(32) NOT NULL DEFAULT '' COMMENT '平台简称（英文简写）',
  `min_version` int(11) NOT NULL DEFAULT '0' COMMENT '最小兼容版本',
  `max_version` int(11) NOT NULL DEFAULT '0' COMMENT '最大兼容版本',
  `activity_flow` text COMMENT '活动流程，json',
  `order_flow` text COMMENT '订单流程，json',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `order_flow_order_limit` text COMMENT '订单流程，json（超时取消）',
  `activity_flow_order_limit` text COMMENT '活动流程，json（超时取消）',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_business_settlement` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '商务id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '所属城市id',
  `date_month` int(11) NOT NULL DEFAULT '0' COMMENT '结算月份',
  `to_be_settlement_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '待结算金额',
  `settlement_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '可结算金额',
  `self_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '个人佣金',
  `cross_month_self_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '跨月个人佣金',
  `to_be_self_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '待结算个人佣金',
  `group_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '团队佣金',
  `cross_month_group_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '跨月团队佣金',
  `to_be_group_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '待结算团队佣金',
  `commission_plan` text COMMENT '提成阶梯比例',
  `async_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '异步执行状态 1:开始计算 2:计算完成',
  `start_time` datetime DEFAULT NULL COMMENT '结算开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结算结束时间',
  `pay_end_time` datetime DEFAULT NULL COMMENT '支付截止时间,统计用',
  `settlement_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:未结算 1:已结算',
  `settlement_time` datetime DEFAULT NULL COMMENT '结算时间',
  `settled_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '结算人，bwc_admin.id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  PRIMARY KEY (`id`),
  KEY `idx_admin_agent_data_state` (`admin_id`,`agent_id`,`data_state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=31942 DEFAULT CHARSET=utf8mb4 COMMENT='商务结算表';

CREATE TABLE `bwc_business_settlement_detail` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `business_settlement_id` int(11) NOT NULL COMMENT '商务结算表id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '商务id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理城市id',
  `settlement_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `settlement_time` datetime DEFAULT NULL COMMENT '结算时间',
  `settlement_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:已结算',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  PRIMARY KEY (`id`),
  KEY `idx_admin_id` (`admin_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=224 DEFAULT CHARSET=utf8mb4 COMMENT='商务结算明细表';

CREATE TABLE `bwc_category_tag` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_id` int(11) unsigned NOT NULL COMMENT '品类ID，关联bwc_store_category.id',
  `tag` varchar(255) NOT NULL COMMENT '品类标签',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COMMENT='品类与品类标签的对应表';

CREATE TABLE `bwc_cl_sms_agent_deduction_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `phone` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号码',
  `msg_id` varchar(32) NOT NULL COMMENT '创蓝批量短信消息id',
  `agent_deduction_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '代理扣费状态 0:未扣费 1:已扣费',
  `push_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '1:普通短信 2:营销短信 3:自动任务短信',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT '来源id  营销推送或者自动任务记录id',
  `template_id` varchar(64) NOT NULL DEFAULT '' COMMENT '模板id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_phone` (`phone`),
  KEY `idx_msg_id` (`msg_id`),
  KEY `idx_create_time` (`gmt_created`,`is_delete`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='创蓝批量短信代理扣费记录表';

CREATE TABLE `bwc_client_user_visit_last` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端',
  `ip` varchar(32) NOT NULL DEFAULT '' COMMENT '登陆ip',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备号',
  `create_date` date NOT NULL COMMENT '日期',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_create_date` (`create_date`,`user_device_cid`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`,`create_date`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=83335246 DEFAULT CHARSET=utf8mb4 COMMENT='app/h5首页最后一次访问记录';

CREATE TABLE `bwc_client_user_visit_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id，未登录为0',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `mark` varchar(50) NOT NULL DEFAULT '' COMMENT '登陆标识',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端',
  `ip` varchar(32) NOT NULL DEFAULT '' COMMENT '登陆ip',
  `url` text NOT NULL COMMENT '访问页面url',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `visit_hour` datetime DEFAULT NULL COMMENT '访问时间(小时)',
  `visit_time` datetime DEFAULT NULL COMMENT '访问时间',
  `visit_day` date DEFAULT NULL COMMENT '访问日期',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_visit_day` (`visit_day`) USING BTREE,
  KEY `idx_mark` (`mark`) USING BTREE,
  KEY `idx_ip` (`ip`,`data_state`,`create_time`),
  KEY `create_time` (`create_time`,`data_state`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`,`create_time`) USING BTREE,
  KEY `user_id` (`user_id`,`visit_time`),
  KEY `ip` (`ip`,`visit_time`),
  KEY `user_device_cid` (`user_device_cid`,`visit_time`)
) ENGINE=InnoDB AUTO_INCREMENT=191174763 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_client_user_visit_record_xc` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `mark` varchar(50) NOT NULL DEFAULT '' COMMENT '登陆标识',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端',
  `ip` varchar(32) NOT NULL DEFAULT '' COMMENT '登陆ip',
  `url` text NOT NULL COMMENT '访问页面url',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `visit_hour` datetime DEFAULT NULL COMMENT '访问时间(小时)',
  `visit_time` datetime DEFAULT NULL COMMENT '访问时间',
  `visit_day` date DEFAULT NULL COMMENT '访问日期',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_visit_day` (`visit_day`) USING BTREE,
  KEY `idx_mark` (`mark`) USING BTREE,
  KEY `idx_ip` (`ip`,`data_state`,`create_time`),
  KEY `create_time` (`create_time`,`data_state`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=334948280 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_client_visit_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备号',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `mark` varchar(50) NOT NULL DEFAULT '' COMMENT '登陆标识',
  `p_mark` varchar(50) NOT NULL DEFAULT '' COMMENT '推广位标识',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端',
  `ip` varchar(32) NOT NULL DEFAULT '' COMMENT '登陆ip',
  `url` text NOT NULL COMMENT '访问页面url',
  `page` varchar(50) NOT NULL DEFAULT '' COMMENT '访问页面路径',
  `scene` varchar(32) NOT NULL DEFAULT 'default' COMMENT '场景值 default默认  qrcode:扫码进入 mini_qrcode:小程序扫码 mini_short_link:小程序短链',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `visit_hour` datetime DEFAULT NULL COMMENT '访问时间(小时)',
  `visit_time` datetime DEFAULT NULL COMMENT '访问时间',
  `visit_day` date DEFAULT NULL COMMENT '访问日期',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_page` (`visit_time`,`is_delete`,`page`) USING BTREE,
  KEY `idx_p_mark` (`p_mark`)
) ENGINE=InnoDB AUTO_INCREMENT=336704 DEFAULT CHARSET=utf8mb4 COMMENT='用户访问页面记录表';

CREATE TABLE `bwc_compensation_mechanism` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `server_name` varchar(64) NOT NULL DEFAULT '' COMMENT '服务名称',
  `biz_id` varchar(100) NOT NULL DEFAULT '' COMMENT '关联业务id',
  `biz_type` int(11) NOT NULL DEFAULT '0' COMMENT '关联业务类型:1小蚕订单取消，2用户数据同步, 3商家信息同步，4任务信息同步 5订单更新（ScrmAuditPromotionOrder）6更新账单（OprStorePromotion）7获取用户信息（GetClientUser）8审核任务（ScrmAuditStorePromotion）9更新外卖单号（ScrmUpdatePromotionOrder）10 更新bd账号（ScrmOprBd）',
  `interface_name` varchar(255) NOT NULL DEFAULT '' COMMENT '请求接口完整地址',
  `request_payload` text NOT NULL COMMENT '请求参数json_encode以后的字符串',
  `status` varchar(30) NOT NULL DEFAULT '' COMMENT '请求状态：PENDING,PROCESSING,SUCCESS,FAILED',
  `max_retries` int(11) NOT NULL DEFAULT '0' COMMENT '最大重试次数，暂定5次',
  `retries_count` int(11) NOT NULL DEFAULT '0' COMMENT '当前已重试次数',
  `next_retry_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下次重试时间（采用退避策略：1 分钟，5 分钟，15 分钟，30 分钟，1 小时）',
  `fail_reason` text COMMENT '失败原因或异常信息',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_scan` (`status`,`next_retry_time`,`retries_count`),
  KEY `idx_biz_id` (`biz_id`,`biz_type`),
  KEY `idx_interface_name` (`interface_name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=108024316 DEFAULT CHARSET=utf8mb4 COMMENT='晓晓调用第三方的补偿机制';

CREATE TABLE `bwc_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` varchar(255) NOT NULL DEFAULT 'string' COMMENT '配置类型',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '配置名称',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT '配置key',
  `value` longtext NOT NULL COMMENT '配置value',
  `group` varchar(255) NOT NULL DEFAULT '' COMMENT '分组',
  `platform` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '平台',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=662 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_coupon_template` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `coupon_name` varchar(64) NOT NULL DEFAULT '' COMMENT '券名称',
  `coupon_type` int(11) NOT NULL DEFAULT '0' COMMENT '券类型 1:大牌专享券 2:提前抢单券 3:延迟上传券 4:超级免单券 5:超时复活券',
  `coupon_desc` varchar(500) NOT NULL DEFAULT '' COMMENT '券描述',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  `advance_time` int(11) NOT NULL COMMENT '提前抢单的时间，单位，秒',
  `use_desc` varchar(256) NOT NULL DEFAULT '' COMMENT '使用描述',
  `coupon_logo` varchar(500) NOT NULL DEFAULT '' COMMENT '券LOGO',
  `disclaimer` longtext NOT NULL COMMENT '详细描述-免责声明',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COMMENT='优惠券模板';

CREATE TABLE `bwc_create_task_excel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人id',
  `operation_ip` varchar(20) NOT NULL DEFAULT '' COMMENT '操作ip',
  `total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '总数量',
  `success_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '成功数',
  `fail_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '失败数',
  `task_start_time` datetime DEFAULT NULL COMMENT '任务开始时间',
  `task_finish_time` datetime DEFAULT NULL COMMENT '任务完成时间',
  `excel_data` mediumtext COMMENT 'excel上传数据',
  `finish_data` mediumtext COMMENT '任务完成数据',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1533 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_customize_geofence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL DEFAULT '' COMMENT '围栏名称',
  `parent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '父围栏id，bwc_geo_fences.id',
  `level` varchar(64) NOT NULL DEFAULT '0' COMMENT '围栏级别：province：省份 city：城市 district：区域\n',
  `province` varchar(32) NOT NULL DEFAULT '' COMMENT '省份',
  `city` varchar(32) NOT NULL DEFAULT '' COMMENT '城市',
  `district` varchar(32) NOT NULL DEFAULT '' COMMENT '地区',
  `city_code` varchar(32) NOT NULL DEFAULT '' COMMENT '高德，citycode',
  `ad_code` varchar(32) NOT NULL DEFAULT '' COMMENT '高德，adcode',
  `city_ad_code` varchar(32) NOT NULL DEFAULT '' COMMENT '城市行政区划代码',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_adcode` (`ad_code`) USING BTREE,
  KEY `idx_parent_id` (`parent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3647 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='自建行政区地理位置围栏';

CREATE TABLE `bwc_delayed_audit_config` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL DEFAULT '' COMMENT '分类：审核登记配置audit_level_config，用户来源：user_source_config',
  `sub_type` varchar(50) NOT NULL DEFAULT '' COMMENT '子类:为空的时候，key-name等价id-name',
  `third_type` varchar(50) NOT NULL DEFAULT '' COMMENT '三级目录：为空的时候，不存在三级',
  `key` varchar(100) NOT NULL DEFAULT '' COMMENT 'key',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '名称',
  `value` varchar(50) NOT NULL DEFAULT '' COMMENT 'value',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_ele_order_finished_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=448 DEFAULT CHARSET=utf8mb4 COMMENT='饿了么订单状态更新为完成记录';

CREATE TABLE `bwc_energy_goods` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT '名称',
  `brief_desc` varchar(255) NOT NULL COMMENT '简述',
  `cover` varchar(255) NOT NULL COMMENT '主图',
  `type` int(11) NOT NULL COMMENT '商品类型：1：卡券 2：卡密 3：晓晓红包 4：实物 5：福利',
  `price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '能量价格',
  `set_stock_quantity` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '预设库存',
  `stock_quantity` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '库存',
  `stock_type` tinyint(1) unsigned NOT NULL COMMENT '库存类型，1：日、2：周、3：月、4：总，注意卡密类型只能总库存',
  `tips` varchar(255) NOT NULL DEFAULT '' COMMENT '兑换提示',
  `weight` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '权重：范围0 - 1',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否启用，1：是 0：否',
  `sales_volume` int(11) NOT NULL DEFAULT '0' COMMENT '销量',
  `current_sales_volume` int(11) DEFAULT '0' COMMENT '当期销量',
  `attach` json DEFAULT NULL COMMENT '特定字段json\n\ncoupon_id卡券id，bwc_coupon_template.id\nred_envelope_price, 晓晓红包价格\nsend_type，发放方式1：图片 2：链接\nlink_url：链接\nimage_url：图片',
  `created_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '创建者，bwc_admin.id',
  `updated_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '更新者，bwc_admin.id',
  `data_state` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态：0正常1删除',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COMMENT='能量站商品表';

CREATE TABLE `bwc_energy_mall_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户id',
  `goods_id` int(11) NOT NULL COMMENT '商品id',
  `order_no` varchar(32) NOT NULL COMMENT '订单号',
  `goods_name` varchar(255) NOT NULL COMMENT '商品名称',
  `price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '能量价格',
  `cover` varchar(255) NOT NULL COMMENT '主图',
  `type` int(11) NOT NULL COMMENT '商品类型：1：卡券 2：卡密 3：晓晓红包 4：实物 5：福利',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT '来源id',
  `attach` json DEFAULT NULL COMMENT '特定字段json\n\ncoupon_id卡券id，bwc_coupon_template.id\nred_envelope_price, 晓晓红包价格\nsend_type，发放方式1：图片 2：链接\nlink_url：链接\nimage_url：图片',
  `address_id` int(11) DEFAULT NULL COMMENT '用户收货地址id',
  `full_address` varchar(255) DEFAULT NULL COMMENT '完整地址',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=856925 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_energy_mall_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_name` varchar(64) NOT NULL DEFAULT '' COMMENT '任务名称',
  `icon_url` varchar(255) NOT NULL DEFAULT '' COMMENT '图标',
  `task_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '任务类型 1:每日签到 2:分享海报 3:观看视频 4:完成订单 5:邀请团员注册',
  `daily_count` int(11) DEFAULT NULL COMMENT '任务每日可完成次数,未设置即为不限次数',
  `energy_base` int(11) NOT NULL DEFAULT '0' COMMENT '能量基数,即每完成一次有效任务可得能量值',
  `inc_energy` int(11) NOT NULL DEFAULT '0' COMMENT '连续签到每日递增值',
  `inc_max_days` int(11) NOT NULL DEFAULT '0' COMMENT '连续签到不再递增天数',
  `task_desc` varchar(256) NOT NULL DEFAULT '' COMMENT '任务简述',
  `sort` int(11) NOT NULL DEFAULT '0' COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:启用 1:禁用',
  `is_continue_complete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:完成后不可继续完成 1:完成后可继续完成',
  `button_text` varchar(64) NOT NULL DEFAULT '' COMMENT '按钮文字',
  `client_version` int(11) NOT NULL DEFAULT '0' COMMENT '客户端版本,客户端版本大于等于当前版本时才显示',
  `client_type` varchar(64) NOT NULL DEFAULT '' COMMENT '支持客户端类型',
  `h5_url` varchar(128) NOT NULL DEFAULT '' COMMENT 'h5链接',
  `header_image_switch` tinyint(1) NOT NULL DEFAULT '0' COMMENT '列表头图开关 0:关闭 1:开启',
  `header_image` varchar(256) NOT NULL DEFAULT '' COMMENT '列表头图url',
  `header_button_text` varchar(64) NOT NULL DEFAULT '' COMMENT '下载列表按钮文字',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COMMENT='能量商城每日任务';

CREATE TABLE `bwc_energy_mall_third` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `out_order_id` varchar(64) NOT NULL DEFAULT '' COMMENT '三方订单id',
  `out_content` json DEFAULT NULL COMMENT '三方回调内容',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_out_order_id` (`out_order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=68326 DEFAULT CHARSET=utf8mb4 COMMENT='能量商城三方数据';

CREATE TABLE `bwc_env_white` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `white_key` varchar(50) NOT NULL DEFAULT '' COMMENT '白名单key',
  `white_value` varchar(255) NOT NULL DEFAULT '' COMMENT '白名单value',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_excel_download_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '文件名，为空时有默认',
  `operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人id',
  `operation_ip` varchar(20) NOT NULL DEFAULT '' COMMENT '操作ip',
  `task_start_time` datetime DEFAULT NULL COMMENT '任务开始时间',
  `task_finish_time` datetime DEFAULT NULL COMMENT '任务完成时间',
  `excel_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1.全部订单,2.未结算订单,3.商家账单批量导出excel,4.商家账单导出excel,5.发账单导出excel,6.发店铺账单导出excel,7.美团霸王餐账单导出excel,8.导出吃吃龟格式的excel,9.导出吃吃龟未结算账单,10.导出吃吃龟多个商家excel的zip,11.任务excel,13.订单明细导出,14.代理数据统计导出,15.提成结算导出,16.数据统计导出,17.提现账号excel,18.订单审核记录excel,19.修改账单记录excel,20.任务修改记录excel,21.工单中心-工单列表-工单明细导出,22.工单中心-明细统计-工作量明细导出,23.饿了么账单excel,24.推广-推广分组-查询数据-推广数据导出,25.财务-商家退款记录导出,26.饿了么专享账单excel,27.商务-线索管理-列表数据导出,28.灰太狼账单excel,29.店铺开票支付记录,30.标记店铺每日账单导出,31.批量订单行为导出， 32：商家端招商加盟，33. 美团对账单, 34:美团官方团购对账单, 35:美团官方团购账单导出Excel, 36:三方用户订单导出, 42:代理消费记录明细导出，40. 关联商家信息',
  `param` text COMMENT '导出表格参数，json格式',
  `excel_download_url` varchar(1500) DEFAULT NULL COMMENT 'excel下载链接',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '完成状态，1 未完成, 2 已完成, 3 异常失败',
  `processed_row` int(11) NOT NULL DEFAULT '0' COMMENT '已处理数据条数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_operator_id` (`operator_id`,`data_state`) USING BTREE,
  KEY `idx_excel_type` (`excel_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=739078 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_exception` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `biz_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '1bwc_seller_bill_order表，2bwc_seller_bill表 3商家充值 4商家创建活动 5商家活动退款 6退款修复之首信易 7退款修复之晓晓钱包 8退款修复之代理受益等 9退款修复之退款回调失败 10晓晓支付账单给代理打钱',
  `biz_id` int(10) NOT NULL DEFAULT '0' COMMENT '业务表id',
  `biz_parent_id` int(10) NOT NULL COMMENT '业务对应的父级id',
  `exception` json NOT NULL COMMENT '全部错误信息',
  `message` text NOT NULL COMMENT '错误提示',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否已经重试：1失败，2成功',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26657 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_fake_user_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_nick` varchar(255) NOT NULL COMMENT '用户昵称',
  `user_avatar` varchar(255) NOT NULL COMMENT '用户头像',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=201 DEFAULT CHARSET=utf8mb4 COMMENT='假用户数据表';

CREATE TABLE `bwc_friend_help_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '助力活动配置id',
  `target_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '目标金额',
  `must_condition_json` varchar(500) NOT NULL DEFAULT '' COMMENT '硬性要求json字符串',
  `invite_old_user_interval` varchar(50) NOT NULL DEFAULT '' COMMENT '成功提现需拉已注册用户区间',
  `invite_new_user_interval` varchar(50) NOT NULL DEFAULT '' COMMENT '成功提现需拉新注册用户区间',
  `finish_order_interval` varchar(50) NOT NULL DEFAULT '' COMMENT '成功提现需周期内完成订单区间',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '发布状态 -1:已删除 1:已发布',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_activity_config_id` (`activity_config_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='助力领现金活动表';

CREATE TABLE `bwc_friend_help_activity_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type` tinyint(4) DEFAULT NULL COMMENT '类型：1限制用户助力领现金最终成功,2限制同设备助力领现金最终成功,3限制用户助力领现金转盘转不到红包、直接打款现金奖品',
  `user_id` int(11) NOT NULL COMMENT 'bwc_user.id，用户id',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id_type` (`user_id`,`type`) USING BTREE,
  KEY `idx_user_device_cid_type` (`user_device_cid`,`type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=161 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='助力领现金活动拉黑表';

CREATE TABLE `bwc_friend_help_activity_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `target_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '目标金额',
  `must_condition_json` varchar(500) NOT NULL DEFAULT '' COMMENT '硬性要求json字符串',
  `invite_old_user_interval` varchar(50) NOT NULL DEFAULT '' COMMENT '成功提现需拉已注册用户区间',
  `invite_new_user_interval` varchar(50) NOT NULL DEFAULT '' COMMENT '成功提现需拉新注册用户区间',
  `finish_order_interval` varchar(50) NOT NULL DEFAULT '' COMMENT '成功提现需周期内完成订单区间',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '发布状态 -1:已删除 0:未发布 1:已发布 2:已修改未发布 3:已删除未发布',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='助力领现金配置表';

CREATE TABLE `bwc_friend_help_activity_prize_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `prize_name` varchar(20) NOT NULL DEFAULT '' COMMENT '奖品名称',
  `prize_logo` varchar(255) NOT NULL DEFAULT '' COMMENT '奖品LOGO',
  `prize_option_code` varchar(32) NOT NULL DEFAULT '' COMMENT '奖品类型编码对应另一个助力活动奖品类型表code',
  `prize_value_type` tinyint(2) NOT NULL COMMENT '奖品取值类型 1:范围内随机 2:固定值',
  `fixed_value` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '固定取值',
  `range_min_value` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '范围取值最小值',
  `range_max_value` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '范围取值最大值',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '卡券类型奖品券模板id',
  `daily_stock` int(11) NOT NULL DEFAULT '0' COMMENT '每日库存',
  `daily_draw_num` int(11) NOT NULL DEFAULT '0' COMMENT '当日中奖数量',
  `lock_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '锁定状态锁定后无法修改 0:未锁定 1:已锁定',
  `draw_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '抽奖状态 0:正常 1:无法抽中',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='助力领现金活动抽奖大转盘配置表';

CREATE TABLE `bwc_friend_help_activity_prize_option` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `option_name` varchar(20) NOT NULL DEFAULT '' COMMENT '选项名称',
  `option_code` varchar(20) NOT NULL COMMENT '选项编码',
  `lock_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '锁定状态锁定后无法选中或者直接不显示 0:未锁定 1:已锁定',
  `sort` int(11) NOT NULL DEFAULT '0' COMMENT '排序',
  `option_remark` varchar(255) NOT NULL DEFAULT '' COMMENT '选项抽中后的提示语',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_friend_help_draw_times` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '好友助力任务id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '助力用户id',
  `friend_help_record_id` int(11) NOT NULL DEFAULT '0' COMMENT '好友助力记录id',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '抽奖次数类型 1:好友助力赞现金次数 2:运营抽奖次数',
  `is_used` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否已使用 0:未使用 1:已使用',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT '来源id',
  `source_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '来源类型0:系统赠送 1:运营抽奖 2:用户助力 3:订单完成',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_source` (`source_id`,`source_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=343086 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='好友助力抽奖次数表';

CREATE TABLE `bwc_friend_help_prize_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `task_draw_times_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务抽奖次数id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `prize_name` varchar(255) NOT NULL DEFAULT '' COMMENT '奖品名称',
  `prize_logo` varchar(255) NOT NULL DEFAULT '' COMMENT '奖品LOGO',
  `prize_option_code` varchar(32) NOT NULL DEFAULT '' COMMENT '奖品类型编码对应另一个助力活动奖品类型表code',
  `prize_value_type` tinyint(2) NOT NULL COMMENT '奖品取值类型 1:范围内随机 2:固定值',
  `prize_value` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '固定取值',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '卡券类型奖品券模板id',
  `prize_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '抽奖大转盘配置id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=123745 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_friend_help_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '好友助力任务id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '助力用户id',
  `task_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务的用户id',
  `is_new_user` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否是新用户助力 0:不是新用户 1:是新用户',
  `is_read` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否已读 0未读 1已读',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_task_user_id` (`task_user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9011 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='好友助力记录表';

CREATE TABLE `bwc_friend_help_roi_order` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `order_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:涟漪订单 1:直接订单',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_create_agent_order` (`gmt_created`,`agent_id`,`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=510947 DEFAULT CHARSET=utf8mb4 COMMENT='助力领现金用户roi订单表';

CREATE TABLE `bwc_friend_help_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '助力领现金活动id',
  `task_no` varchar(32) NOT NULL DEFAULT '' COMMENT '活动任务编码',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `target_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '活动目标金额',
  `current_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '当前金额',
  `current_gold` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '当前金币',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动城市id',
  `invite_old_user_num` int(11) NOT NULL DEFAULT '0' COMMENT '成功提现需拉已注册用户数量',
  `invite_new_user_num` int(11) NOT NULL DEFAULT '0' COMMENT '成功提现需拉新注册用户数量',
  `finish_order_num` int(11) NOT NULL DEFAULT '0' COMMENT '成功提现需周期内完成订单数量',
  `current_invite_old_user_num` int(11) NOT NULL DEFAULT '0' COMMENT '当前已注册用户数量',
  `current_invite_new_user_num` int(11) NOT NULL DEFAULT '0' COMMENT '当前新注册用户数量',
  `current_finish_order_num` int(11) NOT NULL DEFAULT '0' COMMENT '当前完成订单数量',
  `deadline` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '活动最后期限',
  `task_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '任务状态 -1:失败 0:进行中 1:成功',
  `cash_back_method` tinyint(2) NOT NULL DEFAULT '0' COMMENT '提现方式 0:未选择 1:微信零钱 2:晓晓积分',
  `cash_back_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '提现状态 0:未提现 1:微信零钱到账成功 2:晓晓积分到账 ',
  `success_time` timestamp NULL DEFAULT NULL COMMENT '活动成功时间',
  `device_id` varchar(64) NOT NULL DEFAULT '' COMMENT '设备号',
  `start_amount_list` varchar(255) NOT NULL DEFAULT '' COMMENT '初始化活动抽奖金额列表json',
  `select_cash_back_method_amount_list` varchar(255) NOT NULL DEFAULT '' COMMENT '选择提现方式抽奖金额列表json',
  `cash_amount_list` varchar(255) NOT NULL DEFAULT '' COMMENT '初始化活动抽奖金额列表json',
  `cash_draw_num` int(11) NOT NULL DEFAULT '0' COMMENT '赞现金抽奖已抽次数',
  `sys_draw_times` int(11) NOT NULL DEFAULT '0' COMMENT '剩余系统赠送抽奖波数',
  `random_no` int(11) NOT NULL DEFAULT '0' COMMENT '任务随机数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_task_no` (`task_no`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_task_status` (`task_status`) USING BTREE,
  KEY `idx_gmt_created` (`gmt_created`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=126811 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_general_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `search_keyword` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺搜索关键词',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `task_start_time` datetime NOT NULL COMMENT '活动开始时间',
  `task_end_time` datetime NOT NULL COMMENT '活动结束时间',
  `start_time` time NOT NULL COMMENT '报名开始时间',
  `end_time` time NOT NULL COMMENT '报名结束时间',
  `task_total_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务名额',
  `task_applicants_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '已报名人数',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要好评，1图文反馈3文字反馈2无需反馈（兼容以前数据）4无需图文',
  `is_machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否自动通过审核',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 bwc_business_platform.id',
  `is_nationwide` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否全国通用 0:否 1:是',
  `data_state` tinyint(1) unsigned zerofill NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '任务状态 1进行中 2已关闭',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_end_time` (`data_state`,`task_end_time`,`task_start_time`) USING BTREE,
  KEY `idx_task_type` (`task_type`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=149 DEFAULT CHARSET=utf8mb4 COMMENT='通用活动表';

CREATE TABLE `bwc_general_task_agent_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `general_task_id` int(11) unsigned NOT NULL COMMENT '通用活动ID，关联bwc_general_task.id',
  `agent_id` int(11) unsigned NOT NULL COMMENT '代理ID，关联bwc_agent.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_general_task_id` (`general_task_id`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=523 DEFAULT CHARSET=utf8mb4 COMMENT='通用活动-代理关联表';

CREATE TABLE `bwc_general_task_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `general_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '通用任务id,bwc_general_task.id',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作员id',
  `before_data` text NOT NULL COMMENT '修改前数据，json',
  `after_data` text NOT NULL COMMENT '修改后数据，json',
  `operation_ip` varchar(20) NOT NULL COMMENT '操作ip',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_general_task_id` (`general_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=378 DEFAULT CHARSET=utf8mb4 COMMENT='通用活动-修改记录表';

CREATE TABLE `bwc_general_task_views` (
  `id` int(11) unsigned NOT NULL COMMENT '主键',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 bwc_business_platform.id',
  `home_page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '主页展示量',
  `page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '浏览量',
  `browsing_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '浏览用户量',
  `registered_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数量',
  `registered_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户量',
  `task_start_time` datetime DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '报名结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_type` (`task_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通用活动-浏览记录表';

CREATE TABLE `bwc_geo_channel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` varchar(30) NOT NULL DEFAULT '' COMMENT '渠道编码',
  `config` text COMMENT '配置',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 1腾讯2高德',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_geo_task_chain` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `scene_code` varchar(32) NOT NULL DEFAULT '' COMMENT '场景编码',
  `channel_code` varchar(32) NOT NULL DEFAULT '' COMMENT '渠道编码',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '调用排序',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_geofence` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '围栏名称',
  `code` varchar(20) NOT NULL DEFAULT '' COMMENT '行政区划编码',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '围栏类型 1 自定义 2行政区划',
  `gfid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '围栏id',
  `desc` varchar(255) NOT NULL DEFAULT '' COMMENT '围栏描述',
  `qr_url` varchar(255) NOT NULL DEFAULT '' COMMENT '微信二维码url',
  `customer_service_qr_url` text COMMENT '客服企微二维码',
  `level` tinyint(1) unsigned DEFAULT '2' COMMENT '分级',
  `points` text COMMENT '围栏坐标点',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_code` (`code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=258 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_global_area_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '配置名称',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT '配置key',
  `value` text NOT NULL COMMENT '配置value',
  `group` varchar(20) NOT NULL DEFAULT '' COMMENT '组',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_group` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '名称',
  `is_disabled` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否禁用；1是;2否',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4 COMMENT='组织表';

CREATE TABLE `bwc_group_member` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL DEFAULT '0' COMMENT '组id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT 'admin表id',
  `is_leader` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否主管; 1是；2否',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_grp_adm` (`group_id`,`admin_id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=480 DEFAULT CHARSET=utf8mb4 COMMENT='组织成员表';

CREATE TABLE `bwc_growth_value_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT 'type=1:订单id type=2:团员id',
  `source_type` int(11) NOT NULL DEFAULT '0' COMMENT '1:个人下单 2:新团员下单',
  `growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '成长值',
  `mark` varchar(64) NOT NULL DEFAULT '' COMMENT '备注',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_source` (`user_id`,`source_id`,`source_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=38689187 DEFAULT CHARSET=utf8mb4 COMMENT='用户成长值变更记录表';

CREATE TABLE `bwc_icp_task` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '类型：1常规任务，2小吃，3家常菜',
  `store_name` varchar(100) NOT NULL COMMENT '店铺名称',
  `store_introduce` varchar(400) NOT NULL COMMENT '店铺介绍',
  `seller_introduce` text NOT NULL COMMENT '商家介绍',
  `cover` varchar(100) DEFAULT '' COMMENT '封面图',
  `seller_address` varchar(100) DEFAULT '' COMMENT '商家地址',
  `seller_mobile` varchar(100) DEFAULT '' COMMENT '商家联系方式',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '发布人',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '任务状态：1审核中，2审核完成',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=256 DEFAULT CHARSET=utf8mb4 COMMENT='任务表';

CREATE TABLE `bwc_icp_task_images` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `icp_task_id` int(10) NOT NULL DEFAULT '0' COMMENT 'icp任务id',
  `image_url` varchar(255) NOT NULL DEFAULT '' COMMENT '图片',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1554 DEFAULT CHARSET=utf8mb4 COMMENT='icp任务关联图片表';

CREATE TABLE `bwc_icp_user` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL DEFAULT '' COMMENT '用户名',
  `email` varchar(50) NOT NULL DEFAULT '' COMMENT '邮箱',
  `salt` varchar(10) NOT NULL DEFAULT '',
  `password` varchar(40) NOT NULL DEFAULT '' COMMENT '密码',
  `avatar` varchar(255) NOT NULL DEFAULT '' COMMENT '头像',
  `ip` varchar(40) NOT NULL DEFAULT '' COMMENT '上次登录的ip',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1未启用，2已启用，3禁用',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `id_username` (`username`) USING BTREE,
  KEY `id_email` (`email`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COMMENT='Icp用户表';

CREATE TABLE `bwc_icp_user_identity` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户id',
  `type` tinyint(1) NOT NULL COMMENT '身份类型：1个人，2商家',
  `mobile` varchar(18) DEFAULT '' COMMENT '手机号',
  `seller_name` varchar(100) DEFAULT '' COMMENT '商家名称',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `id_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COMMENT='用户身份表';

CREATE TABLE `bwc_identity_card` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `real_name` varchar(30) NOT NULL DEFAULT '' COMMENT '认证的姓名',
  `id_card` varchar(255) NOT NULL DEFAULT '' COMMENT '身份证号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_id_card` (`id_card`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=741563 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_identity_card_mobile` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `mobile` varchar(30) NOT NULL DEFAULT '' COMMENT '认证的手机号',
  `identity_card_id` int(10) NOT NULL DEFAULT '0' COMMENT '身份证表id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_identity_card_id` (`identity_card_id`) USING BTREE,
  KEY `idx_mobile` (`mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=144541 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_identity_card_withdrawal_amount` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `identity_card_id` int(11) NOT NULL COMMENT '身份证表',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总金额，单位元，两位小数',
  `month_amount` decimal(10,2) NOT NULL COMMENT '当月总金额，单位元，两位小数',
  `user_score_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户端积分提现金额，单位元，两位小数',
  `user_gold_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户端提现金额，单位元，两位小数',
  `middleman_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '中间人提现金额，单位元，两位小数',
  `cps_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户提现金额，单位元，两位小数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：默认0，删除1',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_identity_card_id` (`identity_card_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=42249 DEFAULT CHARSET=utf8mb4 COMMENT='晓晓用户在云账户提现的总金额';

CREATE TABLE `bwc_invite_phone_activity` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title` varchar(50) NOT NULL DEFAULT '' COMMENT '活动名称',
  `start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `leaderboard_display_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '排行榜展示人数',
  `display_reward_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '展示奖励人数',
  `actual_reward_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '实际奖励人数',
  `reward_threshold` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '奖励门槛',
  `additional_reward_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '额外奖励金币',
  `index_page_popup_switch` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '首页弹窗开关，0. 关，1. 开',
  `index_page_popup_image_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '首页弹窗',
  `background_image_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '活动背景图',
  `staff_qr_code_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '活动专员二维码',
  `rank_banner_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '排行榜banner图片url',
  `description` text COMMENT '活动说明',
  `rules` text COMMENT '活动规则',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态 1进行中，2已停用',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `end_time` (`end_time`,`start_time`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COMMENT='邀新领手机活动表';

CREATE TABLE `bwc_invite_phone_activity_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `sign_up_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '报名id',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `invited_user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '被邀请人用户id',
  `register_time` datetime DEFAULT NULL COMMENT '被邀用户注册时间',
  `order_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '订单id，完成时才填充',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '被邀请用户完成订单所属代理id',
  `order_time` datetime DEFAULT NULL COMMENT '下单时间',
  `complete_time` datetime DEFAULT NULL COMMENT '完成时间',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态，1正常，2已撤销',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_invited_user_id` (`invited_user_id`),
  KEY `idx_activity_user_invite_user_id` (`activity_id`,`user_id`,`invited_user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16965 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机完成记录表';

CREATE TABLE `bwc_invite_phone_activity_physical` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `sign_up_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '报名id',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `tiers_id` int(10) unsigned NOT NULL COMMENT '档位id',
  `order_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '触发奖励的订单id',
  `threshold` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '达标人数',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '兑换类型，1实物，2金币',
  `image_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '实物图片',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '实物名称',
  `reward_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '奖励金币',
  `apply_time` datetime DEFAULT NULL COMMENT '申请时间',
  `reward_issue_time` datetime DEFAULT NULL COMMENT '奖励发放时间',
  `delivery_address` text COMMENT '收货地址',
  `recipient_name` varchar(20) NOT NULL DEFAULT '' COMMENT '收货人姓名',
  `recipient_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '收货人手机号',
  `courier_company` varchar(50) NOT NULL DEFAULT '' COMMENT '快递公司',
  `tracking_number` varchar(50) NOT NULL DEFAULT '' COMMENT '快递单号',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态，0. 未发放，1. 已发放，2. 已撤销',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`activity_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机实物奖励申请';

CREATE TABLE `bwc_invite_phone_activity_physical_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_physical_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户领取基础奖励记录id,bwc_invite_phone_activity_physical主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `invited_user_id` int(10) NOT NULL DEFAULT '0' COMMENT '被邀请人用户id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '新用户订单',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '新用户订单代理id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '该用户分摊金额',
  `is_deducted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已扣除代理余额 0:未扣除 1:已扣除',
  `is_increase` tinyint(1) NOT NULL DEFAULT '0' COMMENT '回滚时是否增加代理余额 0:未增加 1:已增加',
  `remark` varchar(128) NOT NULL DEFAULT '' COMMENT '备注',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态，0:正常 1:回滚',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`activity_id`,`user_id`),
  KEY `idx_activity_physical_id` (`activity_physical_id`),
  KEY `idx_activity_invite_user` (`activity_id`,`invited_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2961 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机实物金币奖励分摊明细表';

CREATE TABLE `bwc_invite_phone_activity_physical_pending_completion_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_physical_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户领取基础奖励记录id,bwc_invite_phone_activity_reward主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '补齐金额',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态，1待补齐，2:已补齐',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`activity_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机实物金币奖励因取消待补齐金额';

CREATE TABLE `bwc_invite_phone_activity_physical_tiers` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '实物名称',
  `image_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '实物图片',
  `threshold` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '邀请达标人数',
  `reward_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '可折现金币',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机活动实物奖励档位表';

CREATE TABLE `bwc_invite_phone_activity_reward` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `sign_up_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '报名id',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `tiers_id` int(10) unsigned NOT NULL COMMENT '档位id',
  `order_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '触发奖励的订单id',
  `threshold` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '达标人数',
  `reward_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '奖励金币',
  `reward_time` datetime DEFAULT NULL COMMENT '奖励时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_user_id` (`activity_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=208 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机金币奖励';

CREATE TABLE `bwc_invite_phone_activity_reward_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_reward_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户领取基础奖励记录id,bwc_invite_phone_activity_reward主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `invited_user_id` int(10) NOT NULL DEFAULT '0' COMMENT '被邀请人用户id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '新用户订单',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '新用户订单代理id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '该用户分摊金额',
  `is_deducted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已扣除代理余额 0:未扣除 1:已扣除',
  `is_increase` tinyint(1) NOT NULL DEFAULT '0' COMMENT '回滚增加代理余额 0：未处理 1：已处理',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:正常 1:回滚',
  `remark` varchar(128) NOT NULL DEFAULT '' COMMENT '备注',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`activity_id`,`user_id`),
  KEY `idx_activity_invite_user` (`activity_id`,`invited_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=496 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机基础奖励分摊明细表';

CREATE TABLE `bwc_invite_phone_activity_reward_pending_completion_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_reward_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户领取基础奖励记录id,bwc_invite_phone_activity_reward主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '补齐金额',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态，1待补齐，2:已补齐',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`activity_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机基础奖励因取消待补齐金额';

CREATE TABLE `bwc_invite_phone_activity_reward_tiers` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `threshold` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '邀请达标人数',
  `reward_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '奖励金币',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机活动奖励档位表';

CREATE TABLE `bwc_invite_phone_activity_sign_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `sign_up_time` datetime DEFAULT NULL COMMENT '报名时间',
  `invite_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '邀请人数',
  `order_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '下单数量',
  `finished_order_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '完成订单数量',
  `revoked` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否撤销过 0. 否，1. 是',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_activity_user` (`activity_id`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=21145 DEFAULT CHARSET=utf8mb4 COMMENT='邀新送手机报名表';

CREATE TABLE `bwc_invite_phone_leaderboard_virtual` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `invited_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '邀请成功人数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=291 DEFAULT CHARSET=utf8mb4 COMMENT='排行榜虚拟数据';

CREATE TABLE `bwc_line_chart_data` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `data_date` date DEFAULT NULL COMMENT '数据日期',
  `all_count` int(11) NOT NULL DEFAULT '0' COMMENT '合计名额总数（自营活动+美团官方活动+饿了么官方活动+合作平台）',
  `all_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '合计已报名数（自营活动+美团官方活动+饿了么官方活动+合作平台）',
  `all_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '合计的核销率',
  `self_count` int(11) NOT NULL DEFAULT '0' COMMENT '自营活动活动总数',
  `self_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '自营活动活动已报名数',
  `self_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '自营活动活动核销率',
  `mtgf_count` int(11) NOT NULL DEFAULT '0' COMMENT '美团官方活动总数',
  `mtgf_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '美团官方活动已报名数',
  `mtgf_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '美团官方活动核销率',
  `elmgf_count` int(11) NOT NULL DEFAULT '0' COMMENT '饿了么官方活动活动总数',
  `elmgf_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '饿了么官方活动已报名数',
  `elmgf_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '饿了么官方活动核销率',
  `htl_count` int(11) NOT NULL DEFAULT '0' COMMENT '合作平台总数',
  `htl_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '合作平台已报名数',
  `htl_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '合作平台核销率',
  `mz_count` int(11) NOT NULL DEFAULT '0' COMMENT '美赚总数',
  `mz_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '美赚已报名数',
  `mz_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '美赚核销率',
  `silk_count` int(11) NOT NULL DEFAULT '0' COMMENT '小蚕平台总数',
  `silk_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '小蚕平台已报名人数',
  `silk_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '小蚕平台核销率',
  `new_store_quota_count` int(11) NOT NULL DEFAULT '0' COMMENT '新增店铺活动总数',
  `new_store_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '新增店铺活动已报名数',
  `new_store_write_off_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '新增店铺活动核销率',
  `pv_count` int(11) NOT NULL DEFAULT '0' COMMENT 'PV访问数',
  `uv_count` int(11) NOT NULL DEFAULT '0' COMMENT 'UV访问数',
  `placed_order_user_count` int(11) NOT NULL DEFAULT '0' COMMENT '下单人数',
  `placed_order_conversion_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '下单转化率',
  `new_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '新增注册用户数',
  `new_placed_order_user_count` int(11) NOT NULL DEFAULT '0' COMMENT '新增下单用户数',
  `new_user_placed_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '新增用户下单数',
  `new_user_placed_order_conversion_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '新增用户下单转化率',
  `repurchase_card_count` int(11) NOT NULL DEFAULT '0' COMMENT '复购卡总名额',
  `repurchase_card_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '复购卡已报名名额',
  `new_general_count` int(11) NOT NULL DEFAULT '0' COMMENT '新用户通用活动总名额',
  `new_general_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '新用户通用活动已报名数',
  `old_general_count` int(11) NOT NULL DEFAULT '0' COMMENT '老用户通用活动总名额',
  `old_general_registered_count` int(11) NOT NULL DEFAULT '0' COMMENT '老用户通用活动已报名数',
  `machine_audit_pass_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '机审通过率',
  `pending_audit_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '待审核订单数',
  `completed_machine_audit_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '机审通过订单数',
  `delayed_audit_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '延迟审核率',
  `delayed_audit_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '延迟审核订单数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key_date_agent` (`data_date`,`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=128629 DEFAULT CHARSET=utf8mb4 COMMENT='数据大屏折线图每日数据';

CREATE TABLE `bwc_live_activity_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `live_activity_id` varchar(64) NOT NULL DEFAULT '' COMMENT '灵动岛id',
  `channel_code` varchar(32) NOT NULL DEFAULT '' COMMENT '推送渠道',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '灵动岛状态 0正常 1已结束',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5273040 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_lkl` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `request_no` varchar(50) NOT NULL DEFAULT '' COMMENT '发起第三方请求的单号',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '金额',
  `pay_method` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '10.拉卡拉-支付宝 11.拉卡拉-微信 12.拉卡拉-晓晓钱包 13.拉卡拉-微信小程序',
  `receipt_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '真实到账金额',
  `pay_no` varchar(255) NOT NULL DEFAULT '' COMMENT 'java返回的支付单号',
  `payment_time` datetime DEFAULT NULL COMMENT '支付时间',
  `pay_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '支付状态1.待支付 2.已支付 3支付失败',
  `remark` text COMMENT '备注',
  `status` tinyint(1) unsigned DEFAULT '0' COMMENT '订单状态 1.正常 2.已撤销',
  `type` tinyint(4) DEFAULT '0' COMMENT '类型：1账单支付，2充值，3活动预支付，4循环任务预支付，5预存单量，6提现退款，7单个任务退款，8循环任务退款',
  `refund_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '退款金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_request_no` (`request_no`) USING BTREE,
  KEY `idx_pay_no` (`pay_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=329461 DEFAULT CHARSET=utf8mb4 COMMENT='拉卡拉发起java支付主表';

CREATE TABLE `bwc_lkl_pre_order_volume` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家id',
  `pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '预存单量',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预存单量关联表';

CREATE TABLE `bwc_lkl_pre_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家创建的任务id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16175 DEFAULT CHARSET=utf8mb4 COMMENT='预支付单个活动关联表';

CREATE TABLE `bwc_lkl_pre_task_cycle` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_cycle_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家创建的循环任务id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`) USING BTREE,
  KEY `idx_task_cycle_id` (`task_cycle_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=109 DEFAULT CHARSET=utf8mb4 COMMENT='循环发布任务关联表';

CREATE TABLE `bwc_lkl_pre_task_cycle_refund` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '我们生成的账单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `task_id` int(11) DEFAULT NULL,
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COMMENT='循环发布任务退款关联表';

CREATE TABLE `bwc_lkl_pre_task_refund` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '我们生成的账单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `task_id` int(11) DEFAULT NULL,
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8842 DEFAULT CHARSET=utf8mb4 COMMENT='单个预支付任务活动退款表';

CREATE TABLE `bwc_lkl_seller_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '我们生成的账单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=957719 DEFAULT CHARSET=utf8mb4 COMMENT='商家账单支付关联表';

CREATE TABLE `bwc_lkl_top_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(10) NOT NULL COMMENT '商家id',
  `top_up_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家提现记录id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`),
  KEY `idx_top_up_id` (`top_up_id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=457 DEFAULT CHARSET=utf8mb4 COMMENT='充值关联表';

CREATE TABLE `bwc_lkl_wallet_pre_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_money_record_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家创建的任务id',
  `money` decimal(10,2) NOT NULL DEFAULT '0.00',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '晓晓钱包账户：1首信易，2拉卡拉',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`seller_money_record_id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4181 DEFAULT CHARSET=utf8mb4 COMMENT='拉卡拉晓晓钱包支付关联表';

CREATE TABLE `bwc_lkl_wallet_pre_task_cycle` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_money_record_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_id` int(11) NOT NULL DEFAULT '0',
  `task_cycle_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家创建的循环任务id',
  `money` decimal(10,2) NOT NULL DEFAULT '0.00',
  `refund_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '循环任务已经退给商家晓晓钱包的钱',
  `used_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '发布单日任务，已经使用的钱',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '晓晓钱包账户：1首信易，2拉卡拉',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`seller_money_record_id`) USING BTREE,
  KEY `idx_task_cycle_id` (`task_cycle_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COMMENT='拉卡拉晓晓钱包支付循环任务关联表';

CREATE TABLE `bwc_lkl_withdrawal` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(11) NOT NULL DEFAULT '0' COMMENT '退款lklid',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `from_lkl_id` int(10) NOT NULL DEFAULT '0' COMMENT '提现对应充值id',
  `from_lkl_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '提现对应的充值金额',
  `from_lkl_refund_status` tinyint(10) NOT NULL DEFAULT '0' COMMENT '状态：1退款中，2退款成功，3退款失败',
  `from_lkl_refund_time` timestamp NULL DEFAULT NULL COMMENT '退款成功时间',
  `from_lkl_refund_message` text COMMENT '退款失败原因',
  `from_lkl_refund_pay_no` varchar(50) DEFAULT NULL COMMENT '退款单号',
  `seller_money_record_id` int(11) NOT NULL DEFAULT '0' COMMENT '对应提现记录id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`from_lkl_id`),
  KEY `idx_task_id` (`from_lkl_amount`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COMMENT='提现关联表';

CREATE TABLE `bwc_login_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) unsigned NOT NULL COMMENT '用户id',
  `login_ip` varchar(20) NOT NULL COMMENT '登陆ip',
  `login_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '登陆时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=329470 DEFAULT CHARSET=utf8;

CREATE TABLE `bwc_login_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端',
  `mark` varchar(50) NOT NULL DEFAULT '' COMMENT '登陆标识',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册成功用户id',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广员id（为0时无推广注册的）',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT '登陆页面url',
  `ip` varchar(20) NOT NULL COMMENT '登陆ip',
  `login_type` varchar(20) NOT NULL DEFAULT '' COMMENT '登陆方式 sms短信 password 密码',
  `is_register` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否注册1是2否',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_device` (`user_device_cid`,`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=10125860 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_marketing_accurate_push_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `push_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '营销推送id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '推送目标用户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`push_task_id`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=195 DEFAULT CHARSET=utf8mb4 COMMENT='营销推送精准推送用户关系表';

CREATE TABLE `bwc_marketing_preview_user_count_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `target_type` tinyint(2) NOT NULL COMMENT '推送目标用户 1:全部 2:精准推送 3:根据条件筛选',
  `condition_json` text COMMENT '条件筛选json',
  `user_count` int(255) NOT NULL DEFAULT '0' COMMENT '筛选后用户数',
  `task_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '任务状态 0:未执行 1:执行中 2:执行成功 3:执行失败',
  `error_msg` varchar(255) NOT NULL DEFAULT '' COMMENT '执行失败异常原因',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_marketing_promotion_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `platform` tinyint(2) NOT NULL DEFAULT '1' COMMENT '平台类型 1:美团 2:饿了么',
  `name` varchar(255) NOT NULL COMMENT '活动名称',
  `activity_id` varchar(32) NOT NULL COMMENT '第三方活动id',
  `cover` varchar(255) NOT NULL COMMENT '图片链接',
  `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '活动开始时间',
  `end_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '活动结束时间',
  `config_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '配置方式1:api自动获取 2:手动设置',
  `deep_link` text COMMENT 'deeplink链接',
  `mini_app_id` varchar(255) NOT NULL COMMENT '小程序id',
  `mini_app_path` varchar(255) DEFAULT NULL COMMENT '小程序跳转路径',
  `sort` int(11) NOT NULL DEFAULT '0' COMMENT '排序',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=510 DEFAULT CHARSET=utf8mb4 COMMENT='推广营销活动';

CREATE TABLE `bwc_marketing_push_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `push_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '营销推送id',
  `title` varchar(255) NOT NULL COMMENT '推送标题',
  `content` varchar(255) NOT NULL COMMENT '推送内容',
  `user_num` int(11) NOT NULL DEFAULT '0' COMMENT '符合推送条件的人数',
  `msg_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '消息类型 1:系统公告 2:营销推送',
  `show_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否在消息中心显示 0显示 1不显示',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=971 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_marketing_push_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `marketing_push_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '营销推送日志id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '推送目标用户id',
  `title` varchar(255) NOT NULL COMMENT '推送标题',
  `content` varchar(255) NOT NULL COMMENT '推送内容',
  `msg_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '消息类型 1:系统公告 2:营销推送',
  `read_status` tinyint(2) DEFAULT '0' COMMENT '阅读状态 0未读 1:已读',
  `show_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否在消息中心显示 0显示 1不显示',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_gmt_created` (`gmt_created`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=581357413 DEFAULT CHARSET=utf8mb4 COMMENT='营销推送APP推送记录';

CREATE TABLE `bwc_marketing_push_record_20250426` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `marketing_push_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '营销推送日志id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '推送目标用户id',
  `title` varchar(255) NOT NULL COMMENT '推送标题',
  `content` varchar(255) NOT NULL COMMENT '推送内容',
  `msg_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '消息类型 1:系统公告 2:营销推送',
  `read_status` tinyint(2) DEFAULT '0' COMMENT '阅读状态 0未读 1:已读',
  `show_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否在消息中心显示 0显示 1不显示',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=714571183 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_marketing_push_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '类型1:营销推送  2:营销短信',
  `msg_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '消息类型 1:系统公告 2:营销推送',
  `task_title` varchar(255) NOT NULL COMMENT '任务标题',
  `push_platform` varchar(50) NOT NULL COMMENT '推送平台数组格式json["ios", "android"]',
  `title` varchar(255) NOT NULL COMMENT '推送标题',
  `content` varchar(255) NOT NULL COMMENT '推送内容',
  `click_event` tinyint(2) NOT NULL DEFAULT '1' COMMENT '1:仅打开APP 2:打开APP功能页面 3:APP内打开Webview网页',
  `app_page_code` varchar(255) NOT NULL DEFAULT '' COMMENT 'APP功能页面码',
  `web_view_url` varchar(255) NOT NULL DEFAULT '' COMMENT 'Webview跳转地址',
  `target_type` tinyint(2) NOT NULL COMMENT '推送目标用户 1:全部 2:精准推送 3:根据条件筛选',
  `send_time_type` tinyint(2) NOT NULL COMMENT '发送时机 1:立即发送 2:定时发送 3:定时重复发送',
  `definite_time` timestamp NULL DEFAULT NULL COMMENT '定时发送定时时间',
  `repeat_time` varchar(32) DEFAULT '' COMMENT '定时重复发送的时间',
  `repeat_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '定时重复发送类型 0:无1:每天 2:每周1-7 3:每月1-31日',
  `repeat_day` tinyint(2) NOT NULL DEFAULT '0' COMMENT '定时重复发送日期或每周的时间-每周1-7每月1-31日',
  `start_time` timestamp NULL DEFAULT NULL COMMENT '开始时间',
  `end_time` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `repeat_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '重复发送状态 0正常发送 1关闭',
  `show_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否在消息中心显示 0显示 1不显示',
  `condition_json` text COMMENT '条件筛选json',
  `last_send_time` timestamp NULL DEFAULT NULL COMMENT '上一次发送时间',
  `last_send_user_count` int(11) NOT NULL DEFAULT '0' COMMENT '上一次推送的目标人数',
  `agent_deduction_config` tinyint(2) NOT NULL DEFAULT '0' COMMENT '代理商扣费配置 0扣费  1不扣费',
  `agent_deduction_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '代理商扣费金额设置为0代表获取系统配置',
  `sms_template_id` varchar(50) NOT NULL DEFAULT '' COMMENT '短信模板id',
  `sms_channel_code` varchar(32) NOT NULL DEFAULT '' COMMENT '短信渠道code(示例:JSMS或者TENCENT_SMS)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=679 DEFAULT CHARSET=utf8mb4 COMMENT='营销推送记录表';

CREATE TABLE `bwc_marketing_sms_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `marketing_push_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '营销推送日志id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '目标用户id',
  `phone` varchar(32) NOT NULL COMMENT '手机号码',
  `template_id` varchar(32) NOT NULL COMMENT '短信模板id',
  `send_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '发送状态 1:发送成功 2:发送失败',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_marketing_push_log_id` (`marketing_push_log_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=458242 DEFAULT CHARSET=utf8mb4 COMMENT='营销短信记录表';

CREATE TABLE `bwc_member_right` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT '权益名称',
  `brief_desc` varchar(255) NOT NULL COMMENT '权益简述',
  `logo` varchar(255) NOT NULL COMMENT '权益图标',
  `introduction` varchar(255) NOT NULL COMMENT '权益说明',
  `member_level_id` int(11) NOT NULL COMMENT '解锁等级，bwc_vip_level.id',
  `member_level` int(11) NOT NULL DEFAULT '0' COMMENT '解锁等级,bwc_vip_level.level_value',
  `image_url` varchar(200) NOT NULL DEFAULT '' COMMENT '图片链接',
  `link_url` varchar(255) NOT NULL COMMENT '网页链接',
  `equity_rule` varchar(200) NOT NULL DEFAULT '' COMMENT '等级要求',
  `send_type` tinyint(1) unsigned NOT NULL COMMENT '发放方式1：图片 2：链接 3:报名领取',
  `reset_time_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '重置报名时间类型 0:单次权益，不重置 1:每隔一周 2:每隔一月 3:每隔一年 4:自然周 5:自然月 6:自然年',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否启用，1：是 0：否',
  `data_state` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态：0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='会员权益表';

CREATE TABLE `bwc_member_right_sign_up_edit_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `sign_up_record_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员权益报名记录id',
  `type` tinyint(2) NOT NULL COMMENT '修改类型 1:确认处理 2:拒绝处理 3:更新备注',
  `content` varchar(255) DEFAULT NULL COMMENT '内容',
  `create_user_name` varchar(255) NOT NULL COMMENT '创建人用户名称冗余',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_member_right_sign_up_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_mobile` varchar(11) NOT NULL COMMENT '用户手机号',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户当时会员等级id',
  `member_right_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员权益id',
  `member_right_name` varchar(255) NOT NULL COMMENT '权益名称',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '报名状态  1:已报名,待处理 2:已确认 3:已拒绝',
  `notice_desc` varchar(255) DEFAULT NULL COMMENT '通知说明',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `approved_at` datetime DEFAULT NULL COMMENT '通过时间',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_merchant_settled` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `mark` varchar(20) NOT NULL DEFAULT '' COMMENT '登陆标识',
  `merchant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '门店名称',
  `contact_name` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人姓名',
  `contact_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人手机号',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端',
  `ip` varchar(32) NOT NULL DEFAULT '' COMMENT '登陆ip',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT '访问页面url',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=21071 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_merchant_settled_follow_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `merchant_settled_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家入驻申请记录id',
  `content` text NOT NULL COMMENT '跟进内容',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_merchant_settled` (`merchant_settled_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商家入驻申请跟进记录表';

CREATE TABLE `bwc_message` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '消息类型；\n0 常规消息;\n1 引导页消息;\n12 省钱计算器;\n13 首页筛选+活动引导;\n14 首页浏览红包;\n15 首单全额返;\n18 下载app奖励;',
  `text` varchar(255) NOT NULL DEFAULT '' COMMENT '消息内容',
  `scene` varchar(50) NOT NULL DEFAULT '' COMMENT '场景值，对应user_version表',
  `version` int(10) NOT NULL DEFAULT '0',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_ver` (`version`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_message_event` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `parent_id` int(11) NOT NULL DEFAULT '0' COMMENT '父id',
  `event_name` varchar(255) NOT NULL COMMENT '消息事件名称',
  `event_code` varchar(255) NOT NULL COMMENT '事件编码',
  `show_msg_config_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '是否在消息中心配置中显示0不显示  1显示',
  `show_user_config` tinyint(2) NOT NULL DEFAULT '1' COMMENT '用户端是否在消息中心配置中显示0不显示  1显示',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_message_event_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `message_event_id` int(11) NOT NULL COMMENT '消息事件id',
  `config_type` tinyint(2) DEFAULT NULL COMMENT '配置类型 1:微信 2:APP通知 3:短信候补 4:AI外呼候补 5:小程序一次性订阅消息',
  `sms_send_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '短信发送类型 1:必发 2:候补',
  `config_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '配置开关 0:关闭 1:开启',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `message_event_id` (`message_event_id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_message_event_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `event_code` varchar(255) NOT NULL COMMENT '事件编码',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `req_body` varchar(500) DEFAULT NULL COMMENT '请求入参',
  `wechat_msg_status` tinyint(2) DEFAULT '0' COMMENT '微信消息状态 0:未发送 1:发送中  2:发送成功 3:发送失败',
  `app_push_status` tinyint(2) DEFAULT '0' COMMENT 'APP推送状态 0:未发送 1:发送中  2:发送成功 3:发送失败',
  `sms_msg_status` tinyint(2) DEFAULT '0' COMMENT '短信消息状态 0:未发送 1:发送中  2:发送成功 3:发送失败',
  `voice_msg_status` tinyint(2) DEFAULT '0' COMMENT '语音消息状态 0:未发送 1:发送中  2:发送成功 3:发送失败',
  `unsend_reason` tinyint(2) DEFAULT '0' COMMENT '未推送原因 0:正常 1:夜间用户开启免打扰 2:用户设置关闭该事件',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_event_code` (`event_code`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=394679544 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_middleman` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `real_name` varchar(20) NOT NULL DEFAULT '' COMMENT '中间人姓名',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '中间人手机号',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `withdrawable_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '可提现余额',
  `sum_earning` decimal(10,2) DEFAULT '0.00' COMMENT '累计收益',
  `artificial_freezing_balance` decimal(10,2) DEFAULT '0.00' COMMENT '人工冻结金额',
  `artificial_freezing_reason` varchar(50) DEFAULT NULL COMMENT '人工冻结原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `alipay_update_time` timestamp NULL DEFAULT NULL COMMENT '支付宝修改时间',
  `deduct_balance` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '人工扣除金额',
  `identity_card_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0:未通过考核，1:正式经纪人',
  `formal_time` datetime DEFAULT NULL COMMENT '成为正式经纪人的时间',
  `calculate_start_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '周期统计开始时间',
  `frozen_status` tinyint(1) NOT NULL DEFAULT '2' COMMENT '冻结状态 1冻结; 2正常',
  `single_withdrawal_min_amount` decimal(10,2) unsigned NOT NULL DEFAULT '100.00' COMMENT '单笔提现最小金额',
  `new_yzh_sign_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '新版云账户是否签约',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_mobile` (`mobile`) USING BTREE,
  KEY `idx_identity_card_id` (`identity_card_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7303 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_middleman_assessment_cycle` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `middleman_id` bigint(20) NOT NULL COMMENT '中间人id',
  `cycle_index` int(11) NOT NULL COMMENT '周期序号，从1开始',
  `start_time` datetime NOT NULL COMMENT '周期开始时间',
  `end_time` datetime NOT NULL COMMENT '周期结束时间',
  `is_passed` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否通过考核：0-未通过，1-通过',
  `actual_store_count` int(11) NOT NULL DEFAULT '0' COMMENT '实际店铺数',
  `actual_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '实际订单数',
  `pre_id` int(11) NOT NULL DEFAULT '0' COMMENT '上期id',
  `total_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '总单量',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_id` (`middleman_id`),
  KEY `idx_time` (`start_time`,`end_time`)
) ENGINE=InnoDB AUTO_INCREMENT=27575 DEFAULT CHARSET=utf8mb4 COMMENT='中间人考核周期表';

CREATE TABLE `bwc_middleman_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `middleman_id` int(11) NOT NULL DEFAULT '0' COMMENT '中间人id',
  `config_code` varchar(255) NOT NULL COMMENT '设置code（STORE_REVIVE_SWITCH:关联店铺复活统一开关）',
  `config_status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '设置开关 0:关闭 1:开启',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `middleman_id` (`middleman_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COMMENT='中间人设置表';

CREATE TABLE `bwc_middleman_dynamic_adjust_price` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `middleman_id` int(11) NOT NULL DEFAULT '0' COMMENT '中间人id',
  `is_open` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否打开 0否; 1是',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0默认; 1竞品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_middleman` (`middleman_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_middleman_frozen_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `middleman_id` int(11) NOT NULL DEFAULT '0' COMMENT '中间人id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `admin_name` varchar(255) NOT NULL DEFAULT '' COMMENT '管理员名称',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_admin` (`admin_id`) USING BTREE,
  KEY `idx_middleman_id` (`middleman_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_middleman_ladder_reward` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `middleman_id` int(10) NOT NULL DEFAULT '0' COMMENT '中间人表id',
  `date_month` int(11) NOT NULL DEFAULT '0' COMMENT '所属年份月份：例如202503',
  `order_num` int(10) NOT NULL DEFAULT '0' COMMENT '订单量',
  `is_full_settlement` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否全部结算：1是，0否',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '额外打款金额',
  `is_payment` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否打款：0未打款，1打款中，2已打款，3打款失败',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_id` (`middleman_id`) USING BTREE,
  KEY `idx_year_month` (`date_month`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励表';

CREATE TABLE `bwc_middleman_ladder_reward_batch` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `middleman_id` int(10) NOT NULL DEFAULT '0' COMMENT '打款中间人id',
  `order_num` int(10) NOT NULL DEFAULT '0' COMMENT '总的订单量',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '额外打款金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_id` (`middleman_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励批量合并打款表';

CREATE TABLE `bwc_middleman_ladder_reward_batch_relation` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `middleman_ladder_reward_batch_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_middleman_ladder_reward_batch表id',
  `middleman_ladder_reward_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_middleman_ladder_reward表id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_ladder_reward_batch_id` (`middleman_ladder_reward_batch_id`) USING BTREE,
  KEY `idx_middleman_ladder_reward_id` (`middleman_ladder_reward_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励批量合并打款关联中间人表';

CREATE TABLE `bwc_middleman_ladder_reward_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `date_month` int(11) NOT NULL DEFAULT '0' COMMENT '日期转成数字',
  `data` json DEFAULT NULL COMMENT '保存的数据json',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_date_month` (`date_month`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励配置表';

CREATE TABLE `bwc_middleman_ladder_reward_config_relation` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `config_id` int(11) NOT NULL DEFAULT '0' COMMENT '基础信息配置表id',
  `middleman_id` int(11) NOT NULL COMMENT '中间人id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_config_id` (`config_id`) USING BTREE,
  KEY `idx_middleman_id` (`middleman_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励配置关联中间人表';

CREATE TABLE `bwc_middleman_ladder_reward_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `middleman_ladder_reward_id` int(11) NOT NULL DEFAULT '0' COMMENT '中间人阶梯奖励表id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理城市id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_ladder_reward_order` (`middleman_ladder_reward_id`,`order_id`) USING BTREE,
  KEY `idx_middleman_ladder_reward_task` (`middleman_ladder_reward_id`,`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=91692 DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励订单关联表';

CREATE TABLE `bwc_middleman_ladder_reward_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `middleman_ladder_reward_id` int(11) NOT NULL DEFAULT '0' COMMENT '中间人阶梯奖励表id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_ladder_reward_order` (`middleman_ladder_reward_id`,`task_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='中间人阶梯奖励任务关联表';

CREATE TABLE `bwc_middleman_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `middleman_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_middleman主键id',
  `real_name` varchar(20) NOT NULL DEFAULT '' COMMENT '中间人姓名',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '中间人手机号',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `withdrawable_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '可提现余额',
  `sum_earning` decimal(10,2) DEFAULT '0.00' COMMENT '累计收益',
  `artificial_freezing_balance` decimal(10,2) DEFAULT '0.00' COMMENT '人工冻结金额',
  `artificial_freezing_reason` varchar(500) DEFAULT NULL COMMENT '人工冻结原因',
  `deduct_balance` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '人工扣除金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_snapshot_date` (`middleman_id`,`snapshot_date`) USING BTREE,
  KEY `idx_mobile` (`mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=522198 DEFAULT CHARSET=utf8mb4 COMMENT='中间人账户余额快照';

CREATE TABLE `bwc_middleman_statement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `middleman_id` bigint(20) DEFAULT NULL COMMENT '推广id',
  `type` tinyint(2) DEFAULT NULL COMMENT '流水类型枚举(1:订单佣金入账 2:财务人工扣除 3:财务人工扣除返还 4:提现扣除 5:提现失败返还 6:餐餐有返-中间人返点 7:中间人阶梯奖励 8:财务人工增加)',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '变动金额',
  `balance` decimal(18,2) DEFAULT NULL COMMENT '当前余额',
  `direction` tinyint(1) DEFAULT NULL COMMENT '(1为增加 0为减少)',
  `source_id` varchar(32) DEFAULT '0' COMMENT '流水来源id',
  `source_type` tinyint(2) DEFAULT NULL COMMENT '来源类型枚举(1:代理商账单表bwc_agent_middleman_bill 2:中间人提现id3:餐餐有返订单id，4中间人阶梯奖励id，5中间人阶梯奖励批量表id)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `update_by` bigint(20) DEFAULT NULL COMMENT '修改人',
  `gmt_created` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `is_delete` tinyint(2) DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `middleman_id` (`middleman_id`) USING BTREE,
  KEY `gmt_created` (`gmt_created`,`is_delete`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2786899 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='中间人余额流水表';

CREATE TABLE `bwc_middleman_withdrawal` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `middleman_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '中间人id',
  `middleman_name` varchar(50) DEFAULT NULL COMMENT '中间人名字',
  `withdrawal_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '提现金额',
  `remaining_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '剩余金额',
  `taxation` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '代扣税费',
  `reconciliation_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '调账金额',
  `received_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '实际到账金额',
  `withdrawal_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '提现状态 1 申请中 2已打款 3已驳回 4打款中 5打款失败',
  `method_time` datetime DEFAULT NULL COMMENT '操作时间',
  `payment_person_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '打款人id',
  `payment_person` varchar(255) NOT NULL DEFAULT '' COMMENT '打款人',
  `reject_reason` varchar(50) DEFAULT NULL COMMENT '驳回原因',
  `reconciliation_remark` varchar(50) DEFAULT NULL COMMENT '调账说明',
  `create_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `update_by` bigint(20) DEFAULT NULL COMMENT '修改人',
  `gmt_created` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `is_delete` tinyint(2) DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `middleman_id` (`middleman_id`) USING BTREE,
  KEY `gmt_created` (`gmt_created`,`is_delete`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=36990 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_middleman_withdrawal_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `withdrawal_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '提现id',
  `middleman_id` int(11) NOT NULL COMMENT '中间人id，bwc_middleman.id',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '用户支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `withdrawal_payment_no` varchar(100) NOT NULL DEFAULT '' COMMENT '订单编号',
  `withdrawal_payment_fail_reason` varchar(100) NOT NULL DEFAULT '' COMMENT '打款失败原因',
  `withdrawal_payment_trade_no` varchar(100) NOT NULL DEFAULT '' COMMENT '转账流水号',
  `withdrawal_payment_transfer_response` text COMMENT '转账的返回值',
  `withdrawal_payment_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '打款金额',
  `withdrawal_payment_time` datetime DEFAULT NULL COMMENT '打款时间',
  `payment_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '打款状态 0申请中 1打款中 2已打款 3打款失败',
  `create_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `update_by` bigint(20) DEFAULT NULL COMMENT '修改人',
  `gmt_created` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `is_delete` tinyint(2) DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  `withdrawal_payment_transfer_request` text COMMENT '转账请求值',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `withdrawal_id` (`withdrawal_id`) USING BTREE,
  KEY `gmt_created` (`gmt_created`,`is_delete`) USING BTREE,
  KEY `idx_middleman_id` (`middleman_id`)
) ENGINE=InnoDB AUTO_INCREMENT=37015 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_middleman_withdrawal_restrict` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `middleman_id` int(11) NOT NULL DEFAULT '0' COMMENT '中间人id',
  `remark` varchar(200) NOT NULL DEFAULT '' COMMENT '备注',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `middleman_id` (`middleman_id`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COMMENT='中间人提现限制表';

CREATE TABLE `bwc_middleman_withdrawal_yun_tax` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `middleman_withdrawal_id` int(11) NOT NULL COMMENT '提现表id',
  `user_real_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户实收金额，单位元，两位小数',
  `received_personal_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳个税，单位元，两位小数',
  `received_value_added_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳增值税，单位元，两位小数',
  `received_additional_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳附加税费，单位元，两位小数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_middleman_withdrawal_id` (`middleman_withdrawal_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4489 DEFAULT CHARSET=utf8mb4 COMMENT='提现云账户中间人税率计算记录表';

CREATE TABLE `bwc_mini_programs_subscribe_auth` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `auth_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '授权状态：-1:拒绝授权，1:同意授权',
  `push_scene_code` varchar(64) NOT NULL DEFAULT '' COMMENT '推送场景code',
  `app_id` varchar(64) NOT NULL DEFAULT '' COMMENT '小程序appid',
  `openid` varchar(64) NOT NULL DEFAULT '' COMMENT '用户在小程序的openid',
  `template_id` varchar(128) NOT NULL DEFAULT '' COMMENT '订阅消息模板ID',
  `auth_count` int(11) NOT NULL DEFAULT '0' COMMENT '待发送次数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_openid_template_scene` (`app_id`,`openid`,`template_id`,`push_scene_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_scene` (`push_scene_code`),
  KEY `idx_openid` (`openid`),
  KEY `idx_template` (`template_id`)
) ENGINE=InnoDB AUTO_INCREMENT=111725 DEFAULT CHARSET=utf8mb4 COMMENT='小程序订阅消息授权表';

CREATE TABLE `bwc_mini_programs_subscribe_send_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `push_scene_code` varchar(64) NOT NULL DEFAULT '' COMMENT '推送场景标识(bwc_mini_programs_subscribe_template.push_scene)',
  `message_event_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '消息推送记录id',
  `app_id` varchar(64) NOT NULL COMMENT '小程序appid',
  `openid` varchar(64) NOT NULL COMMENT '接收用户openid',
  `template_id` varchar(128) NOT NULL COMMENT '消息模板ID',
  `message_content` text COMMENT '消息内容(JSON格式)',
  `send_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '发送状态：-1:发送失败，1:发送成功',
  `send_time` datetime DEFAULT NULL COMMENT '发送时间',
  `result_info` varchar(500) NOT NULL DEFAULT '' COMMENT '微信API返回信息',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_openid` (`openid`),
  KEY `idx_template` (`template_id`),
  KEY `idx_scene` (`push_scene_code`),
  KEY `idx_send_time` (`send_time`)
) ENGINE=InnoDB AUTO_INCREMENT=51067 DEFAULT CHARSET=utf8mb4 COMMENT='小程序订阅消息发送记录表';

CREATE TABLE `bwc_mini_programs_subscribe_template` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `app_id` varchar(64) NOT NULL COMMENT '小程序AppID',
  `template_id` varchar(64) NOT NULL COMMENT '模板ID',
  `template_name` varchar(64) NOT NULL DEFAULT '' COMMENT '模板名称',
  `page_path` varchar(255) NOT NULL DEFAULT '' COMMENT '用户点击消息后跳转的小程序页面路径',
  `auth_scene_code` varchar(64) NOT NULL COMMENT '授权场景code(同一授权场景每个appid只能存在最多三个启用的模板,否则前端拉起订阅授权会报错)',
  `push_scene_code` varchar(64) NOT NULL COMMENT '推送场景code',
  `status` tinyint(2) NOT NULL DEFAULT '1' COMMENT '状态(-1:禁用,1:启用)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_app_template_auth_scene_code` (`app_id`,`template_id`,`auth_scene_code`),
  KEY `idx_auth_scene_code` (`auth_scene_code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COMMENT='小程序一次性订阅模板表';

CREATE TABLE `bwc_money_calc_cate` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title` varchar(50) NOT NULL DEFAULT '' COMMENT '标题',
  `month_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '每月点外卖次数',
  `avg_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '均价',
  `cash_back` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返现',
  `before_consumption_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '以前每年消费金额',
  `after_consumption_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '以后每年消费金额',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态：1. 启动，其他禁用',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_money_calc_equivalent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `cate_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '阶梯id',
  `model` varchar(20) NOT NULL DEFAULT '' COMMENT '机型，用字母表示，全小写',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '实物名称',
  `img` varchar(1500) NOT NULL DEFAULT '' COMMENT '实物图片',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_mp_wechat_config` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL COMMENT '公众号名称',
  `qrcode_url` varchar(255) DEFAULT NULL COMMENT '公众号二维码链接',
  `is_jump_mini_program` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否显示跳转小程序按钮 1：是 0：不是',
  `is_close_popover` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否允许用户关闭弹窗 1：是 0：不是',
  `is_order_feedback_popover` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '订单反馈弹窗显示',
  `is_first_follow_prize` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '首次关注公众号奖励',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  `created_by` int(11) DEFAULT NULL COMMENT '创建人，bwc_admin.id',
  `updated_by` int(11) DEFAULT NULL COMMENT '更新人，bwc_admin.id',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='微信功能配置表';

CREATE TABLE `bwc_mt_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '配置名称',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT '配置key',
  `value` text NOT NULL COMMENT '配置value',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_new_user_operation_condition` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `condition_name` varchar(255) NOT NULL DEFAULT '' COMMENT '条件名称',
  `condition_code` varchar(255) NOT NULL DEFAULT '' COMMENT '条件code',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COMMENT='新用户运营任务触发条件表';

CREATE TABLE `bwc_new_user_operation_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `new_user_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '新用户运营任务id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '执行目标用户id',
  `task_condition_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务触发条件id',
  `red_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `params` text COMMENT '事件参数json',
  `app_push_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT 'APP推送状态 0:未发送 1:发送中  2:发送成功 3:发送失败',
  `sms_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '短信消息状态 0:未发送 1:发送中  2:发送成功 3:发送失败',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `app_push_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'app推送扣费金额',
  `sms_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '短信扣费金额',
  `date_str` date DEFAULT NULL COMMENT '触发日期',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `auto_task_id_target_type_gmt_created_index` (`new_user_task_id`,`gmt_created`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=330481 DEFAULT CHARSET=utf8mb4 COMMENT='新用户运营任务触发记录表';

CREATE TABLE `bwc_new_user_operation_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_title` varchar(255) NOT NULL DEFAULT '' COMMENT '自动任务标题',
  `task_condition_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务触发条件id',
  `event` varchar(255) NOT NULL DEFAULT '' COMMENT '触发事件(存的数组json) 1:APP推送 2:发送短信 3:赠送晓晓红包',
  `params` text COMMENT '事件参数json',
  `status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '状态（0开启 1关闭）',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COMMENT='新用户运营任务表';

CREATE TABLE `bwc_new_user_task_agent` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `new_user_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '自动任务id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7733 DEFAULT CHARSET=utf8mb4 COMMENT='新用户运营任务代理城市表';

CREATE TABLE `bwc_notice` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `notice_scene_code` varchar(30) NOT NULL DEFAULT '' COMMENT '通知场景code',
  `params` text NOT NULL COMMENT '通知参数',
  `success_channel_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '发送成功渠道',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1. 发送未完成 2. 发送已完成 3. 发送失败',
  `failure_reason` text COMMENT '失败原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=53350155 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_notice_channel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `scene_code` varchar(30) NOT NULL DEFAULT '' COMMENT '场景code',
  `channel_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1. 发送公众号订阅通知 2. 发送极光自定义消息 3. 发送APP推送 4. 发送短信',
  `params` json NOT NULL COMMENT '参数',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '提醒渠道排序',
  `wait_second` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '提醒等待延迟',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_notice_scene` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `notice_scene_title` varchar(50) NOT NULL DEFAULT '' COMMENT '场景名称',
  `notice_scene_code` varchar(128) NOT NULL DEFAULT '' COMMENT '场景CODE',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_novice` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `version` int(10) NOT NULL DEFAULT '0',
  `text` text COMMENT '内容',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_odd` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `level` int(1) NOT NULL DEFAULT '3' COMMENT 'P0：最高风险，立即处理 P1：影响可用，紧急处理 P2：可能影响可用 尽快处理 P3：不影响可用 需要排查',
  `code` varchar(50) NOT NULL DEFAULT '' COMMENT '异常代码',
  `msg` varchar(50) NOT NULL DEFAULT '' COMMENT '异常说明',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '异常订单id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '异常任务id',
  `progress` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '异常进度 1：未处理 2：处理中 3：暂时搁置 4：已解决',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '异常备注',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1926 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_old_user_general_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `search_keyword` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺搜索关键词',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `task_start_date` date NOT NULL COMMENT '活动开始时间',
  `task_end_date` date NOT NULL COMMENT '活动结束时间',
  `task_start_time` datetime NOT NULL COMMENT '活动开始时间',
  `task_end_time` datetime NOT NULL COMMENT '活动结束时间',
  `task_total_quota` int(11) NOT NULL DEFAULT '0' COMMENT '任务名额',
  `task_applicants_quota` int(11) NOT NULL DEFAULT '0' COMMENT '已报名人数',
  `meal_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要好评，1图文反馈3文字反馈2无需反馈（兼容以前数据）4无需图文',
  `is_machine_audit` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否自动通过审核',
  `task_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '类型 bwc_business_platform.id',
  `is_nationwide` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否全国通用 0:否 1:是',
  `repurchase_interval` int(11) NOT NULL DEFAULT '0' COMMENT '复购间隔',
  `vip_level` int(1) NOT NULL DEFAULT '0' COMMENT '最低会员等级',
  `big_brand_coupon_count` int(11) NOT NULL DEFAULT '0' COMMENT '需要大牌券张数 默认0,不需要',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '任务状态 1进行中 2已关闭',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_task_list` (`task_start_date`,`task_end_date`,`is_delete`,`status`,`store_name`,`search_keyword`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COMMENT='老用户通用活动';

CREATE TABLE `bwc_old_user_general_task_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` int(11) NOT NULL COMMENT '通用活动ID，关联bwc_general_task.id',
  `agent_id` int(11) NOT NULL COMMENT '代理ID，关联bwc_agent.id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_task_agent` (`task_id`,`agent_id`),
  KEY `idx_agent` (`agent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=298 DEFAULT CHARSET=utf8mb4 COMMENT='老用户通用活动-代理关联表';

CREATE TABLE `bwc_old_user_general_task_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '通用任务id,bwc_general_task.id',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作员id',
  `before_data` text NOT NULL COMMENT '修改前数据，json',
  `after_data` text NOT NULL COMMENT '修改后数据，json',
  `operation_ip` varchar(20) NOT NULL COMMENT '操作ip',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COMMENT='通用活动-修改记录表';

CREATE TABLE `bwc_old_user_general_task_time_range` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` int(11) NOT NULL COMMENT '老用户通用活动id',
  `start_time` time NOT NULL COMMENT '活动开始时间',
  `end_time` time NOT NULL COMMENT '活动结束时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8mb4 COMMENT='老用户通用活动-活动时段';

CREATE TABLE `bwc_old_user_general_task_views` (
  `id` int(11) unsigned NOT NULL COMMENT '老用户通用活动主键id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 bwc_business_platform.id',
  `home_page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '主页展示量',
  `page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '浏览量',
  `browsing_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '浏览用户量',
  `registered_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数量',
  `registered_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户量',
  `task_start_time` datetime DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '报名结束时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_type` (`task_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='老用户通用活动-浏览记录表';

CREATE TABLE `bwc_open_receivables` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `appid` varchar(50) NOT NULL DEFAULT '' COMMENT '第三方appid',
  `date` date DEFAULT NULL COMMENT '日期',
  `download_path` varchar(1500) NOT NULL DEFAULT '' COMMENT '下载地址',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3733 DEFAULT CHARSET=utf8mb4 COMMENT='开放平台对账单';

CREATE TABLE `bwc_open_task_app_subsidy_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_app_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '三方平台id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='开放平台渠道补贴城市配置表';

CREATE TABLE `bwc_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `user_id` int(1) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `user_nick` varchar(50) NOT NULL DEFAULT '' COMMENT '用户昵称',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_id` int(11) unsigned NOT NULL COMMENT '任务名称',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `platform_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单平台id',
  `task_full_minus_rule` varchar(20) NOT NULL DEFAULT '' COMMENT '满减规则',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `take_out_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '外卖订单号',
  `take_out_paid_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '外卖实付金额',
  `task_out_order_images` varchar(1500) NOT NULL DEFAULT '' COMMENT '外卖订单截图',
  `task_out_evaluate_images` varchar(1500) NOT NULL DEFAULT '' COMMENT '外卖评价截图',
  `task_out_finish_images` varchar(1500) NOT NULL DEFAULT '' COMMENT '外卖完成截图',
  `promoter_user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广用户id',
  `order_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '-4待返现 -3待确认 -2已驳回 -1已取消 1已报名 2已提交 3待审核 4已完成 5已下单 6待返现',
  `cancel_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1用户取消 2超时取消 3过期取消 4审核人工取消 5退款取消 6任务失败',
  `payment_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '打款状态 1打款中 2已打款 3打款失败',
  `is_expired` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否过期 1是2否',
  `order_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '订单联系号码',
  `order_phone_tail` varchar(20) NOT NULL DEFAULT '' COMMENT '手机尾号',
  `order_rejection_reasons` varchar(255) NOT NULL DEFAULT '' COMMENT '驳回理由',
  `order_deduction_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要好评，1图文反馈3文字反馈2无需反馈（兼容以前数据）4无需图文',
  `praise_demand` varchar(20) NOT NULL DEFAULT '3,30' COMMENT '好评需求 逗号分隔，前面是图片数量，后面是文字数量。is_praise=1时生效',
  `is_timing_reminder` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '已定时提醒过 1是2否',
  `machine_audit_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '-1审核不通过 0未审核 1审核通过',
  `machine_audit_remark` varchar(512) NOT NULL DEFAULT '' COMMENT '审核备注',
  `satisfied` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否满意1是2否',
  `platform_verify` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否平台认证存在的订单。0：不是 1：是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `confirm_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1.待确认问题订单，2已确认',
  `create_date` date DEFAULT NULL COMMENT '下单时间',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_promoter_user_id` (`promoter_user_id`),
  KEY `idx_order_phone_agent_id` (`order_phone`,`agent_id`,`data_state`,`create_time`),
  KEY `idx_agent_id` (`agent_id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `home` (`user_id`,`create_time`,`order_status`,`store_name`,`task_full_minus_rule`,`task_cover`,`is_praise`,`praise_demand`) USING BTREE,
  KEY `take_out_order_no` (`take_out_order_no`,`create_time`) USING BTREE,
  KEY `seller` (`task_id`,`order_status`) USING BTREE,
  KEY `client` (`user_id`,`order_status`,`create_time`,`order_no`,`order_rejection_reasons`,`store_name`,`task_cover`,`meal_price`,`cash_back_amount`,`cancel_status`,`is_expired`,`payment_status`) USING BTREE,
  KEY `service` (`create_time`,`agent_id`,`order_status`,`machine_audit_status`,`order_no`,`order_phone`,`order_phone_tail`,`user_nick`,`store_id`,`store_name`,`meal_price`,`cash_back_amount`) USING BTREE,
  KEY `idx_order_no` (`order_no`) USING BTREE,
  KEY `idx_create_date` (`create_date`) USING BTREE,
  KEY `idx_order_phone_tail` (`order_phone_tail`,`store_id`,`create_date`),
  KEY `idx_order_status_create_date` (`order_status`,`create_date`),
  KEY `idx_data_state_create_time` (`data_state`,`create_time`,`platform_id`,`agent_id`,`order_status`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=95077120 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_admin_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '代理id',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id` (`order_id`) USING BTREE,
  UNIQUE KEY `idx_order_agent_id` (`order_id`,`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7426385 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_app_credentials` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `order_id` int(1) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '报名时的手机号',
  `appid` varchar(50) NOT NULL DEFAULT '' COMMENT '第三方appid',
  `video_url` varchar(512) NOT NULL DEFAULT '' COMMENT '订单视频链接',
  `task_receipt_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `cash_back_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `task_rebate` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返点',
  `settlement_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '结算方式，1. 按比例 2. 扣除固定金额 3. 有最大限制金额的扣除利润',
  `commission_rebate_rate` int(11) NOT NULL DEFAULT '0' COMMENT '返佣万分比',
  `commission_rebate_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返佣金额',
  `commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '佣金',
  `settlement_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '补贴金额',
  `total_cash_back_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总返现金额（含补贴）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_no` (`order_no`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_app_id` (`appid`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2680846 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_audit_map` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '类型：1通过/不满意通过；2驳回',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '名称',
  `desc` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_audit_reason` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `audit_map_id` int(11) NOT NULL DEFAULT '0' COMMENT '映射id',
  `raw_data` text COMMENT '数据json',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2637 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_audit_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `target_status` tinyint(1) NOT NULL DEFAULT '4' COMMENT '操作目标状态',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `target_status` (`target_status`,`create_time`),
  KEY `order_id` (`order_id`),
  KEY `idx_create_time_admin_id` (`create_time`,`admin_id`)
) ENGINE=InnoDB AUTO_INCREMENT=96769237 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_cancel_reasons` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_order.id，订单id',
  `cancel_reason` varchar(255) NOT NULL COMMENT '取消原因',
  `data_state` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NULL DEFAULT NULL,
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `order_audit_record_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_order_audit_record.id 操作id',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_order_audit_record_id` (`order_audit_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=206698 DEFAULT CHARSET=utf8mb4 COMMENT='订单取消原因表';

CREATE TABLE `bwc_order_cancel_record` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_order.id，订单id',
  `activity_id` int(10) NOT NULL DEFAULT '0' COMMENT '活动id',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作人',
  `has_deduct_gold` tinyint(3) NOT NULL DEFAULT '2' COMMENT '是否关联扣除了金币 1是; 2否',
  `score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣除积分',
  `gold` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣除的金币',
  `has_recover` tinyint(3) NOT NULL DEFAULT '2' COMMENT '是否已经恢复 1是;2否',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=56398 DEFAULT CHARSET=utf8mb4 COMMENT='订单取消原因表';

CREATE TABLE `bwc_order_cash_back_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现userId',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '用户支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `cash_back_payment_no` varchar(100) NOT NULL DEFAULT '' COMMENT '返现订单编号',
  `cash_back_payment_fail_reason` varchar(100) NOT NULL DEFAULT '' COMMENT '返现打款失败原因',
  `cash_back_payment_trade_no` varchar(100) NOT NULL DEFAULT '' COMMENT '返现支付宝转账流水号',
  `cash_back_payment_transfer_response` text COMMENT '返现转账的返回值',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现打款金额',
  `cash_back_payment_time` datetime DEFAULT NULL COMMENT '返现打款时间',
  `cash_back_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '返现状态 1打款中 2已打款 3打款失败',
  `cash_back_trans_date` datetime DEFAULT NULL COMMENT '打款成功，钱到账时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`,`create_time`),
  KEY `idx_cash_back_payment_time` (`cash_back_payment_time`) USING BTREE,
  KEY `idx_order_no` (`order_no`) USING BTREE,
  KEY `idx_cash_back_status` (`cash_back_status`),
  KEY `idx_cash_back_payment_no` (`cash_back_payment_no`) USING BTREE,
  KEY `idx_user_alipay_name` (`user_alipay_name`) USING BTREE,
  KEY `idx_user_alipay_account` (`user_alipay_account`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=56577627 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_order_check` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `app_order_no_check_enabled` tinyint(1) NOT NULL DEFAULT '2' COMMENT 'app订单号检测开关 1开;2关',
  `order_info_popup_reminder` tinyint(1) NOT NULL DEFAULT '1' COMMENT '订单信息弹窗提醒 1开； 2关',
  `order_cancel_popup_reminder` tinyint(1) NOT NULL DEFAULT '1' COMMENT '订单取消/退款弹窗提交 1开; 2关',
  `open_edit_take_out_order_no` tinyint(1) NOT NULL DEFAULT '1' COMMENT '开启编辑外卖单号 1开；2关',
  `allow_detect_order` tinyint(1) NOT NULL DEFAULT '1' COMMENT '允许检测单号 1开; 2关',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id` (`order_id`,`app_order_no_check_enabled`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=22869759 DEFAULT CHARSET=utf8mb4 COMMENT='订单号校验关联';

CREATE TABLE `bwc_order_confirm_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `order_id` int(10) NOT NULL DEFAULT '0' COMMENT '订单id',
  `initiate` tinyint(1) NOT NULL DEFAULT '0' COMMENT '操作状态：1人工发起的，2系统发起的',
  `reason_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '问题类型',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `remark` varchar(200) NOT NULL DEFAULT '' COMMENT '说明/原因',
  `parent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '回复的父类id',
  `is_confirm` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0待确认，1已确认',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2599 DEFAULT CHARSET=utf8mb4 COMMENT='客服和商务确认订单记录表';

CREATE TABLE `bwc_order_coupon` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL COMMENT '订单id，对应bwc_order.id',
  `user_id` int(11) NOT NULL COMMENT '用户id，bwc_user.id',
  `user_coupon_id` int(11) NOT NULL COMMENT '券id，bwc_user_coupon.id',
  `coupon_type` tinyint(1) NOT NULL COMMENT '券类型，bwc_user_coupon.coupon_type',
  `data_state` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态：0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_order_coupon` (`user_id`,`order_id`,`coupon_type`) USING BTREE,
  KEY `idx_user_coupon_id` (`user_coupon_id`),
  KEY `idx_order_id_coupon_type` (`order_id`,`coupon_type`)
) ENGINE=InnoDB AUTO_INCREMENT=1322077 DEFAULT CHARSET=utf8 COMMENT='订单使用券表';

CREATE TABLE `bwc_order_deduct_cashback` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_order.id，订单id',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作人',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣除金额',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '扣款理由',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态，1正常，2已过期',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7847 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_deductible` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `deductible_score` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '可扣除积分',
  `deductible_gold` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '可扣除金币',
  `data_state` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=178425 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_delayed_payment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '处理状态 1待处理 2已处理',
  `remark` text COMMENT '备注数据(json格式)，数据处理链',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=577820 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_detail_btn_status` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `step_one_btn` tinyint(1) NOT NULL DEFAULT '0' COMMENT '步骤一按钮点击状态 0未点击; 1已点击',
  `step_two_btn` tinyint(1) NOT NULL DEFAULT '0' COMMENT '步骤二按钮点击状态 0未点击; 1已点击',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7217989 DEFAULT CHARSET=utf8mb4 COMMENT='订单详情步骤按钮点击状态';

CREATE TABLE `bwc_order_ele` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `lock_id` int(11) NOT NULL DEFAULT '0' COMMENT '库存锁id',
  `lock_time` int(11) NOT NULL DEFAULT '0' COMMENT '库存锁id',
  `ele_phone` varchar(11) NOT NULL DEFAULT '' COMMENT '用户饿了么手机号',
  `type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '类型 1餐标类型; 2比例类型',
  `biz_type` varchar(20) NOT NULL DEFAULT '' COMMENT '店铺类型',
  `take_out_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '外卖订单号',
  `third_task_id` varchar(255) NOT NULL DEFAULT '' COMMENT '饿了么原始任务id',
  `store_id` varchar(100) NOT NULL DEFAULT '' COMMENT '店铺id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '封面',
  `ratio` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '佣金比例',
  `user_ratio` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户佣金万分比',
  `headquarters_commission_ratio` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '总部抽成万分比',
  `agent_commission_ratio` int(10) DEFAULT '0' COMMENT '代理抽成万分比',
  `cashback_service_ratio` int(10) NOT NULL DEFAULT '0' COMMENT '返现技术服务费比例',
  `commission_service_ratio` int(10) NOT NULL DEFAULT '0' COMMENT '佣金技术服务费比例',
  `link` text NOT NULL COMMENT '进店链接',
  `commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '佣金金额',
  `user_max_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户最大返现佣金',
  `headquarters_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总部佣金',
  `max_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最大预估佣金(饿了么的commission字段)',
  `real_charge` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `settle_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理收入',
  `ele_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '饿了么返回的收入',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `distance` double(10,2) NOT NULL DEFAULT '0.00' COMMENT '下单时的距离',
  `popup_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '弹窗提醒状态 1每次都提醒；2取消提醒',
  `ext_data` text COMMENT '额外数据json格式',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`,`store_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1095797 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_ele_query_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `query_data` text COMMENT '查询结果数据json格式',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_elm_state_sync` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `take_out_order_no` varchar(64) NOT NULL DEFAULT '' COMMENT '外卖订单号',
  `is_completed` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否完成 0:未完成 1:已完成',
  `query_nums` int(11) NOT NULL DEFAULT '0' COMMENT '查询次数',
  `pay_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `settle` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算预估收入。最终到手的佣金，没有扣除技术服务；结算之后有值',
  `settle_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_out_order_no` (`take_out_order_no`) USING BTREE,
  KEY `idx_create_completed_query_nums` (`gmt_created`,`is_completed`,`query_nums`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=462145 DEFAULT CHARSET=utf8mb4 COMMENT='饿了么官方活动订单状态同步表';

CREATE TABLE `bwc_order_force_revival` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单强制复活记录表';

CREATE TABLE `bwc_order_general` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `general_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '通用任务id，bwc_general_task.id',
  `task_end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `task_start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `poi` text COMMENT '高德识别POI',
  `poi_agent_id` int(11) DEFAULT NULL COMMENT '识别的代理id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `enable_image_review` tinyint(1) NOT NULL DEFAULT '0' COMMENT '通用活动是否开启传图审核 (0=disabled, 1=enabled)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_general_task_id` (`general_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4764 DEFAULT CHARSET=utf8mb4 COMMENT='通用活动订单表';

CREATE TABLE `bwc_order_group_buy` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `is_designation` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否指定套餐，1是2否',
  `designation` varchar(50) NOT NULL DEFAULT '' COMMENT '套餐名',
  `designation_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '套餐url',
  `dy_designation_params` varchar(4500) NOT NULL DEFAULT '' COMMENT '抖音转链参数',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=398 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_order_htl_status` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `machine_audit_status` int(11) NOT NULL DEFAULT '0' COMMENT '订单机审状态 0未通过 1通过',
  `htl_audit_status` int(11) NOT NULL DEFAULT '0' COMMENT '灰太狼审核状态  0未通过; 1通过',
  `htl_audit_data` varchar(2000) NOT NULL DEFAULT '' COMMENT '灰太狼审核原始数据',
  `machine_audit_data` varchar(2000) NOT NULL DEFAULT '' COMMENT '机审原始数据',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=255325 DEFAULT CHARSET=utf8mb4 COMMENT='灰太狼订单机审情况和灰太狼审核情况表';

CREATE TABLE `bwc_order_img` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `img_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '用户截图',
  `take_out_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '图片对应的外卖单号',
  `app_show_order_img` tinyint(4) NOT NULL DEFAULT '2' COMMENT 'app是否显示图片 1是; 2否',
  `reg_num` int(10) NOT NULL DEFAULT '0' COMMENT '识别次数',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id_order_no` (`order_id`,`take_out_order_no`) USING BTREE,
  UNIQUE KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=344689 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_info` (
  `id` int(11) unsigned NOT NULL COMMENT '订单id',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `order_deduction_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '管理员扣款金额',
  `order_deduction_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '管理员扣款理由',
  `machine_audit_remark` varchar(255) NOT NULL DEFAULT '' COMMENT '机审备注',
  `cancel_num` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '取消扣款次数',
  `reupload_num` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '表示允许已经修改的次数,默认值0',
  `current_debit` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '当前应扣款',
  `current_cashback_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '当前应返现金额',
  `actual_cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '实际返现金额',
  `actual_rebate_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '实际推广奖励金额',
  `suggestions` varchar(255) NOT NULL DEFAULT '' COMMENT '意见和建议',
  `take_out_order_no_error_tips` varchar(255) NOT NULL DEFAULT '' COMMENT '订单号错误提示',
  `task_out_order_images_error_tips` varchar(255) NOT NULL DEFAULT '' COMMENT '订单截图错误提示',
  `task_out_evaluate_images_error_tips` varchar(255) NOT NULL DEFAULT '' COMMENT '评价截图错误提示',
  `store_enter_qr` varchar(255) NOT NULL DEFAULT '' COMMENT '进入店铺二维码',
  `alipay_error_tips` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '支付宝信息错误提示 0正常 1异常',
  `red_envelope_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '使用红包id',
  `red_envelope_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '使用红包金额',
  `cancel_order_pre_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单取消之前的状态：-2已驳回 -1已取消 1已报名 2已提交 3待审核 4已完成',
  `sign_up_client` varchar(20) NOT NULL DEFAULT '' COMMENT '下单客户端平台',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_no` (`order_no`),
  KEY `re_envelope` (`red_envelope_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_order_info_deduction_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0',
  `order_deduction_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '扣款类型：1管理员扣款，2系统自动扣款',
  `data_state` tinyint(1) NOT NULL DEFAULT '0',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=26809 DEFAULT CHARSET=utf8mb4 COMMENT='order_info扣款类型表';

CREATE TABLE `bwc_order_invite_boost_prize_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `config_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '配置类型 0:每日助力加返任务名额配置 1:奖池配置',
  `prize_type_code` varchar(32) NOT NULL DEFAULT '' COMMENT '奖池奖品编码',
  `min_value` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '配置最小值 为1时是红包或者能量最小值',
  `max_value` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '配置最大值为1时是红包或者能量最大值',
  `daily_stock` int(11) NOT NULL DEFAULT '0' COMMENT '每日库存',
  `daily_draw_num` int(11) NOT NULL DEFAULT '0' COMMENT '当日中奖数量',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '卡券类型奖品券模板id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COMMENT='订单助力加返配置表';

CREATE TABLE `bwc_order_invite_boost_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单助力加返任务id',
  `boost_type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '助力类型 1:助力 2:下单 3:下单取消',
  `amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '金额',
  `is_new_user` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否是新用户 0:老用户 1:新用户',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '下单助力的订单id',
  `prize_type_code` varchar(32) NOT NULL DEFAULT '' COMMENT '奖池奖品编码',
  `prize_source_id` int(11) NOT NULL DEFAULT '0' COMMENT '奖品对应表的id',
  `prize_value` varchar(255) NOT NULL COMMENT '奖品值 红包能量为金额 卡券为卡券名称',
  `prize_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '奖品配置表id',
  `is_read` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否已读 0:未读 1:已读',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=65431 DEFAULT CHARSET=utf8mb4 COMMENT='订单助力加返助力记录';

CREATE TABLE `bwc_order_invite_boost_roi` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `order_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:涟漪订单 1:直接订单',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_create_agent_order` (`gmt_created`,`agent_id`,`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=164599 DEFAULT CHARSET=utf8mb4 COMMENT='助力加返用户roi订单表';

CREATE TABLE `bwc_order_invite_boost_task` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_no` varchar(32) NOT NULL DEFAULT '' COMMENT '任务编号',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '城市id',
  `max_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '最高可加返',
  `current_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '实时加返',
  `first_order_num` int(11) NOT NULL DEFAULT '0' COMMENT '助力后首单量',
  `invite_boost_num` int(11) NOT NULL DEFAULT '0' COMMENT '总加返笔数',
  `task_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '任务状态 -1:已失效 0:未邀请 1:进行中 2:已结束',
  `task_end_time` datetime DEFAULT NULL COMMENT '任务结束时间',
  `task_expire_time` datetime DEFAULT NULL COMMENT '任务失效时间',
  `point_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '金币到账状态 -1:已扣除 0:未到账 1:已到账',
  `point_time` datetime DEFAULT NULL COMMENT '金币到账时间',
  `vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '参与活动时的会员等级',
  `rebate_delay_time` int(11) NOT NULL DEFAULT '0' COMMENT '加返延迟到账积分时间（小时）',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_task_no` (`task_no`) USING BTREE,
  UNIQUE KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`),
  KEY `idx_task_status` (`task_status`,`current_amount`)
) ENGINE=InnoDB AUTO_INCREMENT=133736 DEFAULT CHARSET=utf8mb4 COMMENT='订单助力加返任务记录';

CREATE TABLE `bwc_order_machine_audit` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单表id',
  `platform_order_screenshot` varchar(1500) NOT NULL DEFAULT '' COMMENT '订单截图合成以后的单图',
  `platform_evaluation_screenshot` varchar(1500) NOT NULL DEFAULT '' COMMENT '反馈截图合成以后的单图',
  `ocr_order_image_result` varchar(1500) NOT NULL DEFAULT '' COMMENT 'ocr识别结果，订单截图，json格式字符串',
  `ocr_evaluate_image_result` varchar(1500) NOT NULL DEFAULT '' COMMENT 'ocr识别结果，评价截图，json格式字符串',
  `ocr_all_pass` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'ocr识别是否全部通过，1通过，2不通过',
  `ocr_white_list` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否ocr白名单内 1是； 2否',
  `order_audit_result` varchar(255) NOT NULL DEFAULT '' COMMENT '机审扣款以后，保存需要提示给用户的文案',
  `is_manual_audit` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否人工审核',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3117002 DEFAULT CHARSET=utf8mb4 COMMENT='订单机审关联表';

CREATE TABLE `bwc_order_meituan_callback` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_no` varchar(50) NOT NULL COMMENT '订单号',
  `business_line` int(11) DEFAULT NULL COMMENT '美团-业务线',
  `sub_business_line` int(11) DEFAULT NULL COMMENT '美团-子业务线',
  `act_id` int(11) DEFAULT NULL COMMENT '美团-活动id，可以在联盟活动列表中查看获取',
  `quantity` int(11) DEFAULT NULL COMMENT '美团-商品数量',
  `pay_time` varchar(20) DEFAULT NULL COMMENT '美团-订单支付时间，10位时间戳',
  `mod_time` varchar(20) DEFAULT NULL COMMENT '美团-订单信息修改时间，10位时间戳',
  `pay_price` decimal(10,2) DEFAULT '0.00' COMMENT '美团-订单用户实际支付金额',
  `profit` decimal(10,2) DEFAULT '0.00' COMMENT '美团-订单预估返佣金额\n\n',
  `cpa_profit` decimal(10,2) DEFAULT '0.00' COMMENT '美团-订单预估cpa总收益（优选、话费券）',
  `sid` varchar(255) DEFAULT NULL COMMENT '美团-订单对应的推广位sid',
  `app_key` varchar(255) DEFAULT NULL COMMENT '美团-订单对应的appkey，外卖、话费、闪购、优选、酒店订单会返回该字段',
  `sms_title` varchar(255) DEFAULT NULL COMMENT '美团-订单标题',
  `status` int(11) DEFAULT NULL COMMENT '美团-订单状态，外卖、话费、闪购、优选、酒店订单会返回该字段\n\n1 已付款\n\n8 已完成\n\n9 已退款或风控',
  `trade_type_list` json DEFAULT NULL COMMENT '美团-订单的奖励类型\n\n话费订单类型返回该字段\n\n3 首购奖励\n\n5 留存奖励\n\n优选订单类型返回该字段\n\n2 cps\n\n3 首购奖励',
  `risk_order` int(11) DEFAULT NULL COMMENT '美团-0表示非风控订单，1表示风控订单',
  `refund_profit` decimal(10,2) DEFAULT NULL COMMENT '美团-订单需要扣除的返佣金额，外卖、话费、闪购、优选、酒店订单若发生退款会返回该字段',
  `cpa_refund_profit` decimal(10,2) DEFAULT NULL COMMENT '美团-订单需要扣除的cpa返佣金额（优选、话费券）',
  `refund_info_list` json DEFAULT NULL COMMENT '美团-退款列表',
  `refund_profit_list` json DEFAULT NULL COMMENT '美团-退款佣金明细',
  `is_deleted` tinyint(1) NOT NULL DEFAULT '0',
  `create_by` bigint(255) NOT NULL DEFAULT '0',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_by` bigint(20) NOT NULL DEFAULT '0',
  `gmt_update` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_order_no` (`order_no`) USING BTREE,
  KEY `idx_gmt_create` (`gmt_create`) USING BTREE,
  KEY `idx_sid` (`sid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5488305 DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

CREATE TABLE `bwc_order_mt` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '类型 1餐标类型; 2比例类型',
  `subsidy_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '渠道补贴比例，万分比，默认为 0，补贴⽐例最⼤为渠道结佣的 100% 即补贴范围：[0, 10000] = [0%,100%]',
  `mt_unified_cash_back_headquarter_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '美团统一返现总部抽成比例（万分比）',
  `mt_unified_cash_back_agent_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '美团统一返现代理抽成比例（万分比）',
  `commission_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '美团统一返现结算该城市佣金比例（万分比）',
  `media_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '美团统一返现渠道佣⾦⽐例（万分比）',
  `media_max_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '美团【统⼀返现】渠道佣⾦上限',
  `mt_phone` varchar(11) NOT NULL COMMENT '用户美团手机号',
  `poi_event_id` varchar(50) NOT NULL DEFAULT '' COMMENT '美团活动id',
  `user_event_id` varchar(255) NOT NULL DEFAULT '' COMMENT '用户美团任务 id',
  `third_task_id` varchar(255) NOT NULL DEFAULT '' COMMENT '美团原始任务id',
  `seller_id` varchar(100) NOT NULL DEFAULT '' COMMENT '商家id',
  `seller_name` varchar(50) NOT NULL DEFAULT '' COMMENT '商家名称，同店铺名称',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '封面',
  `ratio` int(10) NOT NULL DEFAULT '0' COMMENT '佣金比例万分比',
  `user_ratio` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户佣金万分比',
  `action_url` text NOT NULL COMMENT '用户行为链接\r, 点击上报，曝光上报',
  `headquarters_commission_ratio` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '总部抽成万分比',
  `agent_commission_ratio` int(10) DEFAULT '0' COMMENT '代理抽成万分比',
  `commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '佣金金额',
  `max_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最高返现佣金',
  `user_max_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户最大返现佣金',
  `real_charge` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理收入',
  `settlement` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1已结算，其他未结算',
  `headquarters_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总部佣金',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `distance` double(10,2) NOT NULL DEFAULT '0.00' COMMENT '下单时的距离',
  `ext_data` text COMMENT '额外数据json格式',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `completion_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_event_id` (`user_event_id`) USING BTREE,
  KEY `idx_type_completion_time` (`type`,`completion_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=17850314 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_mt_code` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `code` int(11) NOT NULL DEFAULT '0' COMMENT '美团回调推送的code值',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18245669 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_mt_gp` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '类型 1美团团购; 2点评团购',
  `take_out_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '外卖订单号',
  `cash_back_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '返现类型：1：统一返现 0：独立返现',
  `product_index_id` varchar(255) NOT NULL DEFAULT '' COMMENT '团单标识id',
  `mt_phone` varchar(11) NOT NULL DEFAULT '' COMMENT '用户美团手机号',
  `poi_event_id` varchar(50) NOT NULL DEFAULT '' COMMENT '美团活动id',
  `user_event_id` varchar(255) NOT NULL DEFAULT '' COMMENT '用户美团任务 id',
  `seller_name` varchar(255) NOT NULL DEFAULT '' COMMENT '商家名称，同店铺名称',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT 'poi 头图',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '⻔店地址, 包含交叉路',
  `meal_name` varchar(255) NOT NULL DEFAULT '' COMMENT '团单名称',
  `meal_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '团单封面',
  `category_name` varchar(50) NOT NULL DEFAULT '' COMMENT '主营品类名称',
  `mt_score` varchar(255) NOT NULL DEFAULT '' COMMENT '美团评分',
  `pay_price` int(11) NOT NULL DEFAULT '0' COMMENT '⽀付价, 优惠后价格, 单位分',
  `market_price` int(11) NOT NULL DEFAULT '0' COMMENT '原价, 单位分',
  `subsidy_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '渠道补贴比例，万分比，默认为 0，补贴⽐例最大为渠道结佣的 100% 即补贴范围：[0, 10000] = [0%,100%]',
  `subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '渠道补贴金额，单位：元',
  `unified_cash_back_headquarter_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '统一返现总部抽成比例（万分比）',
  `unified_cash_back_agent_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '统一返现代理抽成比例（万分比）',
  `media_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '渠道佣金，单位：元，自己计算的',
  `org_user_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '原始⽤户佣⾦⽐例',
  `org_media_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '原始渠道佣⾦⽐例',
  `user_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '⽤户佣⾦⽐例（叠加渠道补贴后的结果）',
  `user_comment_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '⽤户追加评价佣金比例，直接展示给⽤户',
  `media_ratio` int(11) NOT NULL DEFAULT '0' COMMENT '渠道佣⾦⽐例（扣减渠道补贴后的结果）',
  `user_max_commission` int(11) NOT NULL DEFAULT '0' COMMENT '⽤户佣⾦上限（叠加渠道补贴后的结果）',
  `media_max_commission` int(11) NOT NULL DEFAULT '-1' COMMENT '渠道佣⾦上限（扣减渠道补贴后的结果）',
  `order_limit_exact_time` varchar(20) NOT NULL DEFAULT '' COMMENT '⽤户任务结束时间，格式：毫秒字符串',
  `cancel_time` int(11) NOT NULL DEFAULT '0' COMMENT '⾃动取消时间,报名后多⻓时间内必须下单，单位：分',
  `consume_time` int(11) NOT NULL DEFAULT '0' COMMENT '下单后多⻓时间内必须核销，单位：天,计算⽅式：报名时间 + x ⽇的 23:59:59',
  `delay_cash_back_time` int(11) NOT NULL DEFAULT '0' COMMENT '延迟返现时间，单位：小时(完成后 + x ⼩时)',
  `comment_time` int(11) NOT NULL DEFAULT '0' COMMENT '核销后多⻓时间内必须评价，单位：天,计算⽅式：核销时间 + x ⽇的 23:59:59',
  `comment_text_length` int(11) NOT NULL DEFAULT '0' COMMENT '评价字数要求',
  `comment_picture_count` int(11) NOT NULL DEFAULT '0' COMMENT '评价图⽚数量要求',
  `action_url` text NOT NULL COMMENT '用户行为链接',
  `real_charge` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理收入',
  `order_time` int(11) NOT NULL DEFAULT '0' COMMENT '下单时间，从美团回调推送中取得',
  `task_start_time` varchar(13) NOT NULL DEFAULT '' COMMENT '用户任务开始时间，从美团回调推送中取得',
  `task_end_time` varchar(13) NOT NULL DEFAULT '' COMMENT '用户任务结束时间，从美团回调推送中取得',
  `is_hx` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否核销 0否 1是',
  `is_hx_cash_back` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否核销返现 0否 1是',
  `hx_time` int(11) NOT NULL DEFAULT '0' COMMENT '核销完成时间，收到美团第一次推送code=100的时候',
  `hx_cash_back` int(11) NOT NULL DEFAULT '0' COMMENT '核销返现金额，单位：分',
  `hx_expected_cash_back_time` int(11) NOT NULL DEFAULT '0' COMMENT '核销返现预计到账时间',
  `is_fk` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否反馈 0否 1是',
  `is_fk_cash_back` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否反馈返现 0否 1是',
  `fk_time` int(11) NOT NULL DEFAULT '0' COMMENT '反馈完成时间，收到美团第二次推送code=100的时候',
  `fk_cash_back` int(11) NOT NULL DEFAULT '0' COMMENT '反馈返现金额',
  `fk_expected_cash_back_time` int(11) NOT NULL DEFAULT '0' COMMENT '反馈返现预计到账时间',
  `fail_reason_msg` varchar(255) NOT NULL DEFAULT '' COMMENT '失败原因',
  `code` int(11) NOT NULL DEFAULT '0' COMMENT 'code值；1已报名; 2 已下单; 3已核销，待返现；4已返现；5已反馈，待返现；6已完成；7反馈不达标',
  `hx_code` int(11) NOT NULL DEFAULT '0' COMMENT '核销流程code值，美团返回的原始值',
  `fk_code` int(11) NOT NULL DEFAULT '0' COMMENT '反馈流程code值, 美团返回的原始值',
  `is_timeout_complete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否超时完成 0否; 1是',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `distance` double(10,2) NOT NULL DEFAULT '0.00' COMMENT '下单时的距离',
  `client_ip` varchar(30) NOT NULL DEFAULT '' COMMENT '客户端 Ip(⽤户⻛控校验)',
  `mtg_gp_push_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '美团官方团购推送时间戳，毫秒级',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `completion_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_type_completion_time` (`type`,`completion_time`) USING BTREE,
  KEY `idx_mt_phone_product_index_id` (`order_id`,`product_index_id`,`mt_phone`,`data_state`) USING BTREE,
  KEY `idx_user_event_id` (`user_event_id`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_order_id_type` (`order_id`,`type`,`data_state`,`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=2254 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_mt_gp_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `cash_back_type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '类型 1核销返; 2反馈返',
  `real_charge` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现金额',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理收入',
  `bill_id` int(11) NOT NULL DEFAULT '0' COMMENT '账单id',
  `is_settlement` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1已结算，其他未结算',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=1038 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_mz` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `user_identifier` varchar(20) NOT NULL DEFAULT '' COMMENT '给第三方平台的用户唯一标识',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `shop_id` int(11) unsigned DEFAULT NULL COMMENT '店铺id',
  `sign_up_phone` varchar(11) NOT NULL DEFAULT '' COMMENT '报名手机号',
  `sign_up_id` varchar(255) NOT NULL DEFAULT '' COMMENT '报名 id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺地址',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺封面',
  `action_url` text COMMENT '进店链接',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `settlement_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额初始',
  `commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '佣金金额实际',
  `agent_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理佣金金额',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理收入',
  `headquarter_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总部收入',
  `mz_headquarter_ratio` int(11) NOT NULL DEFAULT '10000' COMMENT '美赚霸王餐总部抽成比例（万分比）',
  `immediate_feedback` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否当日评价 0：否 1：是',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `distance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '下单时的距离',
  `rebate_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返现金额',
  `order_status` int(11) NOT NULL DEFAULT '0' COMMENT '订单状态：-2已驳回, -1已取消, 1已报名, 2已提交, 3待审核, 4已完成',
  `failure_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '失败原因',
  `need_after_sale_img` tinyint(1) NOT NULL DEFAULT '0' COMMENT '驳回后是否需要提交售后截图 0不需要售后图 1需要售后图',
  `need_video` tinyint(1) NOT NULL DEFAULT '0' COMMENT '驳回后是否需要提交录屏 0不需要 1需要',
  `submit_status` int(11) NOT NULL DEFAULT '0' COMMENT '订单提交到第三方状态 0未提交; 1已提交单号; 2已提交截图',
  `task_start_time` varchar(128) NOT NULL DEFAULT '' COMMENT '开始时间，字符串',
  `task_end_time` varchar(128) NOT NULL DEFAULT '' COMMENT '结束时间，字符串',
  `task_requirement` varchar(255) DEFAULT NULL COMMENT '活动要求',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `completion_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `pre_completion_deduction_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '完成前扣款金额 单位元，两位小数',
  `post_completion_deduction_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '完成后扣款金额 单位元，两位小数',
  `deduct_reason` varchar(255) DEFAULT NULL COMMENT '扣款原因',
  `platform_order_screenshot` varchar(1500) NOT NULL DEFAULT '' COMMENT '订单截图',
  `platform_evaluation_screenshot` varchar(1500) NOT NULL DEFAULT '' COMMENT '评价截图',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_sign_up_id` (`sign_up_id`) USING BTREE,
  KEY `idx_task_id` (`task_id`),
  KEY `idx_shop_id` (`shop_id`)
) ENGINE=InnoDB AUTO_INCREMENT=14676 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_mz_deduction` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `order_mz_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '美赚订单id',
  `deduction_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '扣款标识（第三方平台返回）',
  `order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '平台订单号',
  `deduction_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣款金额（总）',
  `real_deduction_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣款金额（本次）',
  `deduction_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '扣款原因',
  `deduction_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '扣款时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_deduction_id` (`deduction_id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_order_mz_id` (`order_mz_id`) USING BTREE,
  KEY `idx_order_no` (`order_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8mb4 COMMENT='美赚订单扣款记录表';

CREATE TABLE `bwc_order_mz_status` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `machine_audit_status` int(11) NOT NULL DEFAULT '0' COMMENT '订单机审状态 0未通过 1通过',
  `audit_status` int(11) NOT NULL DEFAULT '0' COMMENT '美赚审核状态  0未通过; 1通过',
  `audit_data` text COMMENT '美赚审核原始数据',
  `machine_audit_data` text COMMENT '机审原始数据',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7642 DEFAULT CHARSET=utf8mb4 COMMENT='订单机审情况和美赚审核情况表';

CREATE TABLE `bwc_order_old_general` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '老用户通用活动id',
  `poi` text COMMENT '高德识别POI',
  `poi_agent_id` int(11) DEFAULT NULL COMMENT '识别的代理id',
  `enable_image_review` tinyint(1) NOT NULL DEFAULT '0' COMMENT '通用活动是否开启传图审核 (0=disabled, 1=enabled)',
  `start_time` time DEFAULT NULL COMMENT '抢单开始时间',
  `end_time` time DEFAULT NULL COMMENT '抢单结束时间',
  `create_date` date NOT NULL COMMENT '订单创建日期',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_create` (`user_id`,`create_date`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2581 DEFAULT CHARSET=utf8mb4 COMMENT='老用户通用活动订单表';

CREATE TABLE `bwc_order_profit` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id，bwc_order.id',
  `settle_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算佣金',
  `estimated_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '预估佣金，订单完成',
  `actual_commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实际佣金',
  `settle_order_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '结算时订单状态',
  `task_receipt_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `cashback_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实际返现',
  `order_cashback_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单返现价格',
  `middleman_task_rebate` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '中间人返点',
  `channel_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '渠道返点',
  `headquarter_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '总部抽成',
  `current_debit` decimal(10,2) NOT NULL COMMENT '当前扣款',
  `red_envelope_amount` decimal(10,2) NOT NULL COMMENT '红包',
  `config_snapshot` text COMMENT '配置快照',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '放单人id，bwc_admin.id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '放单人区域id，bwc_agent.id',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '被上单城市收入',
  `admin_agent_id` int(11) NOT NULL COMMENT '销售所属代理，bwc_agent.id',
  `admin_agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '上单城市收入',
  `settlement_time` timestamp NULL DEFAULT NULL COMMENT '所属账单结算时间',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属账单id',
  `is_bill_settlement` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '所属账单是否结算; 0否;1是',
  `is_cancel` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '订单是否取消; 0否;1是',
  `is_difference` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否有差异：1：是 0：否',
  `data_state` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`agent_id`,`data_state`,`order_id`) USING BTREE,
  KEY `order_id` (`order_id`),
  KEY `idx_settlement_time` (`settlement_time`),
  KEY `create_time` (`create_time`,`admin_id`,`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=55596022 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_ratio_info` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_id` int(1) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `ratio` int(10) NOT NULL DEFAULT '0' COMMENT '返现比例',
  `max_amount` decimal(10,2) DEFAULT '0.00' COMMENT '最高返',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `fee` decimal(10,2) DEFAULT '0.00' COMMENT '差额费',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=9086 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_rebate_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广奖励userId',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '用户支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `rebate_payment_no` varchar(100) NOT NULL DEFAULT '' COMMENT '推广奖励订单编号',
  `rebate_payment_fail_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '推广奖励打款失败原因',
  `rebate_payment_trade_no` varchar(100) NOT NULL DEFAULT '' COMMENT '推广奖励支付宝转账流水号',
  `rebate_payment_transfer_response` text COMMENT '推广奖励转账的返回值',
  `rebate_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '推广奖励打款金额',
  `rebate_payment_time` datetime DEFAULT NULL COMMENT '推广奖励打款时间',
  `rebate_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '打款状态 1打款中 2已打款 3打款失败',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_no` (`order_no`),
  KEY `idx_user` (`user_id`,`data_state`,`create_time`,`rebate_amount`),
  KEY `idx_rebate_payment_no` (`rebate_payment_no`) USING BTREE,
  KEY `idx_rebate_payment_time` (`rebate_payment_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14060427 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_order_recover_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `target_status` tinyint(1) NOT NULL DEFAULT '4' COMMENT '操作目标状态',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18063 DEFAULT CHARSET=utf8mb4 COMMENT='订单恢复日志表';

CREATE TABLE `bwc_order_refund` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `biz_no` varchar(40) NOT NULL DEFAULT '' COMMENT '唯一标识',
  `platform` tinyint(1) NOT NULL DEFAULT '0' COMMENT '退款来源：1美团，2饿了么',
  `platform_abbreviation` varchar(10) NOT NULL DEFAULT '' COMMENT '退款来源平台简称',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '退款类型：1全部退款，2部分退款',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '退款金额',
  `take_out_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '外卖订单号',
  `callback_data` json DEFAULT NULL COMMENT '三方回调的全部信息',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `biz_no` (`biz_no`) USING BTREE,
  KEY `take_out_order_no` (`take_out_order_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2752390 DEFAULT CHARSET=utf8mb4 COMMENT='外卖单号退款表';

CREATE TABLE `bwc_order_reject_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `order_rejection_reasons` varchar(255) DEFAULT NULL COMMENT '驳回原因',
  `take_out_order_no_error_tips` varchar(255) DEFAULT NULL COMMENT '订单号错误提示',
  `task_out_order_images_error_tips` varchar(255) DEFAULT NULL COMMENT '订单截图错误提示',
  `task_out_evaluate_images_error_tips` varchar(255) DEFAULT NULL COMMENT '评价截图错误提示',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=402282 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_remark` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL COMMENT '订单id',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '订单备注',
  `create_by_name` varchar(32) NOT NULL DEFAULT '' COMMENT '修改人名称',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=109371 DEFAULT CHARSET=utf8mb4 COMMENT='订单备注表';

CREATE TABLE `bwc_order_repurchase_card` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `repurchase_card_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '复购卡任务id，bwc_repurchase_card_task.id',
  `task_end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `task_start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `task_start_date` date DEFAULT NULL COMMENT '活动开始日期',
  `task_end_date` date DEFAULT NULL COMMENT '活动结束日期',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_repurchase_card_task_id` (`repurchase_card_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=83496 DEFAULT CHARSET=utf8mb4 COMMENT='复购卡活动订单表';

CREATE TABLE `bwc_order_roi` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理城市id',
  `profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单利润',
  `total_cost` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单总成本',
  `red_packet_cost` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包成本',
  `super_rebate_cost` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '超级返利成本',
  `extra_cost` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '额外成本,例如不能复活订单但是复活了的订单',
  `platform_code` varchar(32) NOT NULL DEFAULT '' COMMENT '订单平台编码',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_create_agent` (`gmt_created`,`agent_id`),
  KEY `idx_create_user` (`gmt_created`,`user_id`),
  KEY `idx_order` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18510434 DEFAULT CHARSET=utf8mb4 COMMENT='订单roi记录表';

CREATE TABLE `bwc_order_screenshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `screenshot_url` varchar(1024) NOT NULL DEFAULT '' COMMENT '上传的截图url',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='订单截图表';

CREATE TABLE `bwc_order_sign_up_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `version` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名版本号',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '报名平台',
  `mark` varchar(20) NOT NULL DEFAULT '' COMMENT '标识',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `order_id` (`order_id`) USING BTREE,
  KEY `mark` (`mark`) USING BTREE,
  KEY `version` (`version`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=67587562 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_order_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `data` json DEFAULT NULL COMMENT '订单数据，json',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=39928133 DEFAULT CHARSET=utf8mb4 COMMENT='订单快照表';

CREATE TABLE `bwc_order_sort` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `sort_level` tinyint(1) NOT NULL DEFAULT '1' COMMENT '排序等级：数值越大，排序越靠前',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1427744 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_sqs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `meal_name` varchar(255) NOT NULL DEFAULT '' COMMENT '神抢手套餐名称',
  `meal_link` varchar(255) NOT NULL DEFAULT '' COMMENT '神抢手套餐链接',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2187 DEFAULT CHARSET=utf8mb4 COMMENT='神抢手订单';

CREATE TABLE `bwc_order_store_enter_method` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `method` tinyint(1) NOT NULL DEFAULT '0' COMMENT '进店方式：1app进店，2二维码进店，3小程序进店，4店铺名称进店',
  `platform` varchar(50) NOT NULL DEFAULT '' COMMENT '平台：ios,android,weixin-web,web',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11594264 DEFAULT CHARSET=utf8mb4 COMMENT='用户订单选择的进入方式';

CREATE TABLE `bwc_order_store_enter_method_record` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `method` tinyint(1) NOT NULL DEFAULT '0' COMMENT '进店方式：1app进店，2二维码进店，3小程序进店，4店铺名称进店',
  `platform` varchar(50) NOT NULL DEFAULT '' COMMENT '平台：ios,android,weixin-web,web',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16678343 DEFAULT CHARSET=utf8mb4 COMMENT='用户订单选择的进入方式记录表';

CREATE TABLE `bwc_order_submit_record` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `status` tinyint(3) NOT NULL DEFAULT '0' COMMENT '提交前状态',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `mark` varchar(50) NOT NULL DEFAULT '' COMMENT '标识',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '提交平台',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_no` (`order_no`,`data_state`,`latitude`,`longitude`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=237892788 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_submit_time` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id，bwc_order.id',
  `platform_id` int(11) NOT NULL DEFAULT '0' COMMENT '平台id，bwc_business_platform.id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT 'c用户id，bwc_user.id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_platform_id` (`platform_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=21534188 DEFAULT CHARSET=utf8mb4 COMMENT='用户订单提交时间表已提交状态';

CREATE TABLE `bwc_order_subsidy` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单补贴金额',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=72485 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_super_rebate_info` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户id，bwc_user.id',
  `order_id` int(11) NOT NULL COMMENT '订单id，bwc_order.id',
  `user_coupon_id` int(11) NOT NULL COMMENT '卡券id，bwc_user_coupon.id',
  `super_rebate_amount` decimal(10,2) NOT NULL COMMENT '超级返利金额',
  `super_rebate_rate` int(11) NOT NULL COMMENT '超级返利券返利额度(%)',
  `super_rebate_max_amount` decimal(10,2) NOT NULL COMMENT '超级返利券返利上限金额(元)',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_order_coupon` (`order_id`,`user_coupon_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=90268 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_tag` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `tag_value` tinyint(3) NOT NULL DEFAULT '0' COMMENT '订单标签；1神抢手',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1404 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_task_time_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `order_id` int(11) unsigned NOT NULL COMMENT 'bwc_order.id',
  `task_id` int(11) unsigned NOT NULL COMMENT 'bwc_task.id',
  `task_start_time` datetime NOT NULL COMMENT '活动开始时间',
  `task_end_time` datetime NOT NULL COMMENT '活动结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=23397 DEFAULT CHARSET=utf8mb4 COMMENT='订单报名对应多任务时间段表';

CREATE TABLE `bwc_order_third` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `user_identifier` varchar(20) NOT NULL DEFAULT '' COMMENT '给第三方平台的用户唯一标识',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `shop_id` varchar(150) NOT NULL DEFAULT '' COMMENT '店铺id',
  `sign_up_phone` varchar(11) NOT NULL DEFAULT '' COMMENT '报名手机号',
  `sign_up_id` varchar(255) NOT NULL DEFAULT '' COMMENT '报名 id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺地址',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺封面',
  `action_url` text COMMENT '进店链接',
  `commission` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '佣金金额',
  `real_charge` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `agent_income` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '代理收入',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `distance` double(10,2) NOT NULL DEFAULT '0.00' COMMENT '下单时的距离',
  `rebate_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返现金额',
  `order_status` int(11) NOT NULL DEFAULT '0' COMMENT '第三方订单状态',
  `failure_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '失败原因',
  `submit_status` int(11) NOT NULL DEFAULT '0' COMMENT '订单提交到第三方状态  0未提交; 1已提交',
  `task_start_time` varchar(20) NOT NULL DEFAULT '' COMMENT '开始时间，字符串',
  `task_end_time` varchar(20) NOT NULL DEFAULT '' COMMENT '结束时间，字符串',
  `task_requirement` varchar(255) NOT NULL DEFAULT '' COMMENT '活动要求',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_sign_up_id` (`sign_up_id`) USING BTREE,
  KEY `idx_user_id_shop_id` (`user_id`,`shop_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=484742 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_third_cancel_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `cancel_result` tinyint(11) NOT NULL DEFAULT '0' COMMENT '订单取消结果',
  `req_data` text COMMENT '请求参数',
  `resp_data` text COMMENT '响应结果',
  `excep_data` text COMMENT '异常数据',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=216843 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_third_failure_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `code` int(11) NOT NULL DEFAULT '0' COMMENT '第三方状态code',
  `failure_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '失败原因',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=47031 DEFAULT CHARSET=utf8mb4 COMMENT='第三方订单失败原因';

CREATE TABLE `bwc_order_time` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `submit_live_time` int(11) NOT NULL DEFAULT '0' COMMENT '提交订单的持续时间',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_order_limit` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否被限制，0表示未限制，1表示已限制',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=35744412 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_timeout_red_envelopes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id，bwc_order.id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'C用户id，bwc_user.id',
  `red_envelope_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '使用红包id，bwc_red_envelopes.id',
  `red_envelope_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '使用红包金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_red_envelope_id` (`red_envelope_id`)
) ENGINE=InnoDB AUTO_INCREMENT=136675 DEFAULT CHARSET=utf8mb4 COMMENT='用户订单超时取消红包表';

CREATE TABLE `bwc_order_tip` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT '0',
  `is_tip` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已经提示：0没有，1已提示',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13639442 DEFAULT CHARSET=utf8mb4 COMMENT='订单提示表，一个订单提示一次';

CREATE TABLE `bwc_order_user_delete` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `order_id` int(11) NOT NULL COMMENT '订单id，对应bwc_order.id',
  `user_id` int(11) NOT NULL COMMENT '用户id，bwc_user.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id_order_id` (`user_id`,`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=48182 DEFAULT CHARSET=utf8mb4 COMMENT='用户端订单删除记录表';

CREATE TABLE `bwc_order_verify` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `take_out_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '外卖订单号',
  `store_name` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺名',
  `real_money` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '实付金额',
  `order_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
  `order_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单状态',
  `is_click_verify` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否点击了验证按钮 0否，1是',
  `is_generated` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否生成了 0否，1是',
  `check_type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '订单检测类型，1需要接口检测; 2需要用户自主检测；8取消检测；9检测通过',
  `switch_check_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '切换审核方式：0：默认 1：接口检测 2：自主检测',
  `check_result` tinyint(3) NOT NULL DEFAULT '0' COMMENT '订单检测结果，0没有检测结果，1取消检测；2检测通过; 3 检测失败；检测完成',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '原因类型',
  `is_pre_order` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否预订单 1是; 2否',
  `task_out_order_images` varchar(1500) NOT NULL DEFAULT '' COMMENT '外卖订单截图',
  `deliver_type` varchar(255) NOT NULL DEFAULT '' COMMENT '准时宝',
  `deliver_time` varchar(255) NOT NULL DEFAULT '' COMMENT '配送方式(立即配送)',
  `order_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单原始检测类型 1用户自主检测并且通过',
  `version` varchar(255) NOT NULL DEFAULT '' COMMENT '订单版本',
  `is_server_proxy` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否服务端数据代理 0否 1是',
  `order_switch_way_ctrl` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单开关切换方式 0默认; 1开启; 2关闭',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_version_is_server_proxy_check_type` (`check_type`,`version`,`is_server_proxy`) USING BTREE,
  KEY `idx_order_id` (`order_id`,`check_type`,`order_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=28250234 DEFAULT CHARSET=utf8mb4 COMMENT='订单号校验表';

CREATE TABLE `bwc_order_video` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `video_url` varchar(255) NOT NULL DEFAULT '' COMMENT '上传的视频url',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=279168 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_video_admin` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `order_video_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单视频id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_order_id` (`order_id`,`order_video_id`,`admin_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_order_xc` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `xc_order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '小蚕订单id',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `order_log` text,
  `voucher_phase` tinyint(3) NOT NULL DEFAULT '0' COMMENT '提交阶段 0未提交; 1第一阶段，提交订单号; 2第二阶段，提交订单信息，反馈信息',
  `user_remark` varchar(255) NOT NULL DEFAULT '' COMMENT '用户备注',
  `kf_remark` varchar(255) NOT NULL DEFAULT '' COMMENT '客服备注',
  `platform_order_time` varchar(30) NOT NULL DEFAULT '' COMMENT '平台下单时间',
  `platform_order_status` tinyint(3) NOT NULL DEFAULT '0' COMMENT '平台订单状态； 0:订单为找到或未生成；1:已付款；2:已完成；3:取消或退款',
  `order_client_platform` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0：h5; 1: mini; 2: app',
  `upload_time` int(11) NOT NULL DEFAULT '0' COMMENT '上传时间',
  `reviewed_time` int(11) NOT NULL DEFAULT '0' COMMENT '审核时间',
  `first_submit_image_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '第一次提交订单图片是否成功 0：失败 1：成功',
  `promotion_order_result` tinyint(3) NOT NULL DEFAULT '0' COMMENT '订单识别结果',
  `promotion_order_evaluation_result` tinyint(3) NOT NULL DEFAULT '0' COMMENT '订单反馈识别结果',
  `platform_order_screenshot` varchar(1500) NOT NULL DEFAULT '' COMMENT '订单截图',
  `platform_evaluation_screenshot` varchar(1500) NOT NULL DEFAULT '' COMMENT '评价截图',
  `order_type` int(11) NOT NULL DEFAULT '0' COMMENT '订单类型；1:霸王餐订单',
  `timeout_time` int(11) NOT NULL DEFAULT '0' COMMENT '超时时间',
  `redirect_info` varchar(1500) NOT NULL DEFAULT '' COMMENT '跳转信息',
  `profit` int(11) NOT NULL DEFAULT '0',
  `ad_code` int(11) NOT NULL DEFAULT '0',
  `city_code` int(11) NOT NULL DEFAULT '0',
  `user_city_code` int(11) NOT NULL DEFAULT '0' COMMENT '用户城市',
  `bd_id` int(11) NOT NULL DEFAULT '0',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_xc_order_id` (`xc_order_id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3682988 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_pre_order_task_service_fee` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `service_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '等值服务费',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='使用预存单量的任务的服务费';

CREATE TABLE `bwc_promote_energy_goods` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `image_url` varchar(255) NOT NULL COMMENT '广告图',
  `goods_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商品id，bwc_energy_goods.id',
  `sort` int(11) NOT NULL DEFAULT '0' COMMENT '排序',
  `created_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '创建者，bwc_admin.id',
  `updated_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '更新者，bwc_admin.id',
  `data_state` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态：0正常1删除',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_goods_id` (`goods_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='能量站商品主推表';

CREATE TABLE `bwc_promoter_level` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '等级名称',
  `min_order_num` int(11) unsigned DEFAULT '0' COMMENT '单量门槛',
  `min_new_user_num` int(11) unsigned DEFAULT '0' COMMENT '拉新门槛',
  `monthly_condition_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '每月评级方式：0或，1且',
  `invite_leader_num` int(11) unsigned DEFAULT NULL COMMENT '邀请团长开通拉团员门槛',
  `commission_rate` decimal(10,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT '每单分成比例',
  `commission_fixed` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '每单固定分成',
  `new_user_first_order_fixed` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '新用户首单固定分成',
  `level` tinyint(2) NOT NULL DEFAULT '0' COMMENT '级别，0=默认 1 - 10级',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态：0正常，1删除',
  `create_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '创建人ID',
  `update_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '更新人ID',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COMMENT='推广员等级表';

CREATE TABLE `bwc_promotion` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '推广名称',
  `parent_promotion_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '父级id，bwc_parent_promotion.id',
  `commission_ratio` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '上级抽走比例',
  `new_user_first_order_fixed` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '新用户首单固定分成',
  `promoter_level_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广级别ID，关联bwc_promoter_level.id',
  `is_auto_level_up` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否自动升降级，0否 1是',
  `is_skip_level_month` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '本月不评级 0=否 1=是',
  `skip_level_until` date DEFAULT NULL COMMENT '不评级有效期，设置到某月最后一天',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `username` varchar(32) NOT NULL DEFAULT '' COMMENT '登录名',
  `password` varchar(32) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '密码',
  `salt` varchar(4) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '密码盐',
  `mark` varchar(20) NOT NULL DEFAULT '' COMMENT '推广mark',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 1渠道推广 2接口推广',
  `app_id` varchar(255) NOT NULL DEFAULT '' COMMENT '接口推广应用id',
  `app_key` varchar(255) NOT NULL DEFAULT '' COMMENT '接口推广应用key',
  `app_verification_message` varchar(255) NOT NULL DEFAULT '' COMMENT '推广接口验证信息',
  `percentage` decimal(10,5) unsigned NOT NULL DEFAULT '0.00000' COMMENT '每单分成比例',
  `reward` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '每单固定分成',
  `withdrawable_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '可提现余额',
  `freezing_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '冻结余额',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `artificial_freezing_balance` decimal(10,2) DEFAULT '0.00' COMMENT '人工冻结金额',
  `artificial_freezing_reason` varchar(50) DEFAULT NULL COMMENT '人工冻结原因',
  `identity_card_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '用户状态0正常1禁用',
  `new_yzh_sign_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '新版云账户是否签约',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `alipay_update_time` timestamp NULL DEFAULT NULL COMMENT '支付宝修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `mark` (`mark`) USING BTREE,
  KEY `idx_promoter_level_id` (`promoter_level_id`)
) ENGINE=InnoDB AUTO_INCREMENT=413 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_promotion_first_user_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单ID',
  `channel_promotion_id` int(11) unsigned DEFAULT '0' COMMENT '渠道推广id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_user_channel` (`user_id`,`channel_promotion_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=273 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_promotion_group` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL DEFAULT '' COMMENT '推广分组名称',
  `operate_id` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COMMENT='推广分组';

CREATE TABLE `bwc_promotion_group_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `promotion_id` int(11) NOT NULL DEFAULT '0' COMMENT '推广员id',
  `promotion_group_id` int(11) NOT NULL COMMENT '推广分组id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_promotion_group_relation` (`promotion_id`,`promotion_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1663 DEFAULT CHARSET=utf8mb4 COMMENT='推广员和分组的关联关系表';

CREATE TABLE `bwc_promotion_level_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `promotion_id` int(11) unsigned NOT NULL COMMENT '推广员ID，关联 bwc_promotion.id',
  `before_level_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '变更前等级ID，关联 bwc_promoter_level.id',
  `after_level_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '变更后等级ID，关联 bwc_promoter_level.id',
  `change_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '变更类型：1升级，2降级',
  `is_read` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已读：0未读，1已读',
  `order_id` bigint(20) unsigned DEFAULT NULL COMMENT '触发订单ID',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_promotion_id` (`promotion_id`),
  KEY `idx_before_level_id` (`before_level_id`),
  KEY `idx_after_level_id` (`after_level_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='推广员升降级记录表';

CREATE TABLE `bwc_promotion_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单ID',
  `type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '返佣类型：1=老的返佣类型，2=合伙人计划返佣',
  `task_id` int(11) unsigned DEFAULT '0' COMMENT '任务id',
  `user_id` int(1) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '订单编号',
  `channel_promotion_id` int(11) unsigned DEFAULT '0' COMMENT '渠道推广id',
  `channel_promotion_mark` varchar(20) NOT NULL DEFAULT '' COMMENT '渠道推广标识',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `task_rebate` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '中间人返点',
  `percentage` decimal(10,5) unsigned NOT NULL DEFAULT '0.00000' COMMENT '每单分成比例',
  `reward` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '每单固定分成',
  `profit` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '本单收益',
  `is_settlement` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否结算，1是2否',
  `is_new_user_first_order` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否是新用户首单：1是，0否',
  `parent_promotion_id` int(11) NOT NULL DEFAULT '0' COMMENT '父级推广id',
  `parent_commission_ratio` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '上级抽成比例',
  `parent_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '上级收益',
  `sum_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '上级下级总收益',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `task_id` (`task_id`) USING BTREE,
  KEY `order_id` (`order_id`) USING BTREE,
  KEY `idx_channel_promotion_id` (`channel_promotion_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=1350177 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_promotion_position` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `name` varchar(50) NOT NULL COMMENT '推广位名称',
  `promotion_mark` varchar(64) NOT NULL DEFAULT '' COMMENT '推广标识',
  `page_name` varchar(64) NOT NULL DEFAULT '' COMMENT '访问页面名称',
  `page_path` varchar(255) NOT NULL COMMENT '访问页面路径',
  `remark` varchar(100) NOT NULL DEFAULT '' COMMENT '备注',
  `is_use_official_channel_rule` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否使用官方渠道规则(0:否,1:是)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_mark` (`promotion_mark`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COMMENT='推广位表';

CREATE TABLE `bwc_promotion_position_user_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `promotion_position_id` int(11) NOT NULL DEFAULT '0' COMMENT '推广位id',
  `promotion_mark` varchar(64) NOT NULL DEFAULT '' COMMENT '推广标识',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_promotion_position_id` (`promotion_position_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5229 DEFAULT CHARSET=utf8mb4 COMMENT='推广位用户关联表';

CREATE TABLE `bwc_promotion_poster` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `poster_name` varchar(64) NOT NULL DEFAULT '' COMMENT '海报名称',
  `poster_img` varchar(500) NOT NULL DEFAULT '' COMMENT '海报图片链接',
  `nick_name_config` varchar(255) NOT NULL COMMENT '昵称配置',
  `qr_code_position_x` varchar(50) NOT NULL DEFAULT '' COMMENT '二维码X轴',
  `qr_code_position_y` varchar(50) NOT NULL DEFAULT '' COMMENT '二维码Y轴',
  `qr_code_width` varchar(50) NOT NULL DEFAULT '' COMMENT '二维码宽度',
  `qr_code_height` varchar(50) NOT NULL DEFAULT '' COMMENT '二维码高度',
  `sort` int(11) NOT NULL DEFAULT '999' COMMENT '排序 低到高排序',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COMMENT='推广海报表';

CREATE TABLE `bwc_promotion_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `promotion_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_middleman主键id',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '推广名称',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `username` varchar(32) NOT NULL DEFAULT '' COMMENT '登录名',
  `password` varchar(32) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '密码',
  `salt` varchar(4) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '密码盐',
  `mark` varchar(20) NOT NULL DEFAULT '' COMMENT '推广mark',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 1渠道推广 2接口推广',
  `app_id` varchar(255) NOT NULL DEFAULT '' COMMENT '接口推广应用id',
  `app_key` varchar(255) NOT NULL DEFAULT '' COMMENT '接口推广应用key',
  `app_verification_message` varchar(255) NOT NULL DEFAULT '' COMMENT '推广接口验证信息',
  `percentage` decimal(10,5) unsigned NOT NULL DEFAULT '0.00000' COMMENT '每单分成比例',
  `reward` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '每单固定分成',
  `withdrawable_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '可提现余额',
  `freezing_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '冻结余额',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `artificial_freezing_balance` decimal(10,2) DEFAULT '0.00' COMMENT '人工冻结金额',
  `artificial_freezing_reason` varchar(50) DEFAULT NULL COMMENT '人工冻结原因',
  `identity_card_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '用户状态0正常1禁用',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_promotion_snapshot_date` (`promotion_id`,`snapshot_date`) USING BTREE,
  KEY `idx_mobile` (`mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=31473 DEFAULT CHARSET=utf8mb4 COMMENT='cps渠道推广账户余额快照';

CREATE TABLE `bwc_promotion_statement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `promotion_id` bigint(20) DEFAULT NULL COMMENT '推广id',
  `type` tinyint(2) DEFAULT NULL COMMENT '流水类型枚举(1:订单佣金入账 2:订单佣金扣除 3:订单佣金扣除返还 4:提现扣除 5:提现失败返还 6:下级订单分成入账 7:下级订单分成扣除 8:下级订单分成扣除返还)',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '变动金额',
  `balance` decimal(18,2) DEFAULT NULL COMMENT '当前余额',
  `direction` tinyint(1) DEFAULT NULL COMMENT '(1为增加 0为减少)',
  `source_id` bigint(20) DEFAULT '0' COMMENT '流水来源id',
  `source_type` tinyint(2) DEFAULT NULL COMMENT '来源类型枚举(1:订单表 2:推广提现id)',
  `create_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `update_by` bigint(20) DEFAULT NULL COMMENT '修改人',
  `gmt_created` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `is_delete` tinyint(2) DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `promotion_id` (`promotion_id`),
  KEY `gmt_created` (`gmt_created`,`is_delete`)
) ENGINE=InnoDB AUTO_INCREMENT=521650 DEFAULT CHARSET=utf8mb4 COMMENT='推广余额流水表';

CREATE TABLE `bwc_promotion_withdrawal` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `promotion_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广人id',
  `promotion_name` varchar(50) DEFAULT NULL,
  `withdrawal_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '提现金额',
  `remaining_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '剩余金额',
  `taxation` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '代扣税费',
  `received_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '实际到账金额',
  `withdrawal_time` datetime DEFAULT NULL COMMENT '提现申请时间',
  `withdrawal_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '提现状态 1 申请中 2已打款 3已驳回 4打款中 5打款失败',
  `method_time` datetime DEFAULT NULL COMMENT '操作时间',
  `payment_person_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '打款人id',
  `payment_person` varchar(255) NOT NULL DEFAULT '' COMMENT '打款人',
  `withdrawl_method` tinyint(2) unsigned NOT NULL DEFAULT '1' COMMENT '提现方式1：支付宝打款 2：云账户打款',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `reject_reason` varchar(50) DEFAULT NULL COMMENT '驳回原因',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1036 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_promotion_withdrawal_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `withdrawal_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '提现id',
  `alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '用户支付宝账号',
  `alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `withdrawal_payment_no` varchar(100) NOT NULL DEFAULT '' COMMENT '订单编号',
  `withdrawal_payment_fail_reason` varchar(100) NOT NULL DEFAULT '' COMMENT '打款失败原因',
  `withdrawal_payment_trade_no` varchar(100) NOT NULL DEFAULT '' COMMENT '支付宝转账流水号',
  `withdrawal_payment_transfer_response` text COMMENT '转账的返回值',
  `withdrawal_payment_transfer_request` text COMMENT '转账的请求值',
  `withdrawal_payment_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '打款金额',
  `withdrawal_payment_time` datetime DEFAULT NULL COMMENT '打款时间',
  `payment_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '打款状态 1打款中 2已打款 3打款失败',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1036 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_promotion_withdrawal_yun_tax` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `promotion_withdrawal_id` int(11) NOT NULL COMMENT '提现表id',
  `user_real_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户实收金额，单位元，两位小数',
  `received_personal_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳个税，单位元，两位小数',
  `received_value_added_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳增值税，单位元，两位小数',
  `received_additional_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳附加税费，单位元，两位小数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_promotion_withdrawal_id` (`promotion_withdrawal_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=119 DEFAULT CHARSET=utf8mb4 COMMENT='提现云账户cps税率计算记录表';

CREATE TABLE `bwc_rebate` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `middleman_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '中间人id',
  `sale_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属销售id',
  `rebate` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返点',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `seller_id` (`seller_id`,`sale_id`) USING BTREE,
  KEY `idx_middleman_id` (`middleman_id`,`data_state`) USING BTREE,
  KEY `idx_rebate_data_state_sale_middleman` (`data_state`,`sale_id`,`middleman_id`) USING BTREE,
  KEY `idx_mid_sale_seller` (`middleman_id`,`sale_id`,`data_state`,`seller_id`)
) ENGINE=InnoDB AUTO_INCREMENT=94815 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_rebate_rule` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `rebate_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '活动类型 1固定次数，2除固定触发外全部触发',
  `amount_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '金额类型 1固定金额，2随机金额',
  `which_order` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '触发次数',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '奖励金额',
  `amount_rule` varchar(1500) NOT NULL DEFAULT '' COMMENT '金额随机规则',
  `start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `disable` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否禁用 0否1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_red_envelopes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `red_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '红包类型 1 定向红包 2 门店专享红包 3 活动专享红包 4:通用红包',
  `time_limit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '限时红包 1是2否',
  `red_amount` decimal(10,2) NOT NULL COMMENT '红包金额',
  `red_start_time` datetime DEFAULT NULL COMMENT '红包开始时间',
  `red_end_time` datetime DEFAULT NULL COMMENT '红包结束时间',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '门店id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `red_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1. 未使用 2. 已使用 4. 已撤销',
  `sender_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '投放人',
  `send_scene` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '投放场景\n1. 扣款补偿\n2. 激励核销\n3. 活动赠与\n4. 人工发放\n5. 新用户APP首单奖励\n6. 会员等级礼包\n7. 会员生日权益礼包\n8. 能量商城兑换\n9. 首次关注公众号赠送\n10. 自动任务赠送\n11. 会员红包天天领活动\n12. 会员红包天天领活动拉新奖励\n13. 订单取消\n14. 助力领现金活动\n15. 餐餐有返小程序抽奖获得\n16. 首页浏览得红包\n17. 订单助力加返\n18. 首单全额返\n19. 暗号绑定赠礼\n20. 新人完成3单奖励\n21. App见面礼\n22. App回归礼',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '红包备注',
  `template_id` int(11) NOT NULL DEFAULT '1' COMMENT '红包模板id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_store` (`user_id`,`store_id`,`red_status`,`red_start_time`),
  KEY `index_red_status_red_type_red_start_time` (`red_status`,`red_type`,`data_state`,`red_start_time`),
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_expired_red_envelopes` (`time_limit`,`red_end_time`,`red_status`,`data_state`,`user_id`) USING BTREE,
  KEY `idx_send_scene` (`send_scene`)
) ENGINE=InnoDB AUTO_INCREMENT=17695934 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_red_envelopes_applicable_platform` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `platform_abbreviation` varchar(32) NOT NULL DEFAULT '' COMMENT '平台简称（英文简写）同bwc_business_platform.platform_abbreviation',
  `show_name` varchar(32) NOT NULL DEFAULT '' COMMENT '展示名称',
  `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COMMENT='红包的适用平台表';

CREATE TABLE `bwc_red_envelopes_extra` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `red_envelopes_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户红包id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `is_new` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否新到账 0:否 1:是',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_red_envelopes_id` (`red_envelopes_id`),
  KEY `idx_user_is_new` (`user_id`,`is_new`)
) ENGINE=InnoDB AUTO_INCREMENT=390538 DEFAULT CHARSET=utf8mb4 COMMENT='用户红包扩展表';

CREATE TABLE `bwc_red_envelopes_link` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `red_name` varchar(22) NOT NULL DEFAULT '' COMMENT '红包名称',
  `red_link` varchar(255) NOT NULL DEFAULT '' COMMENT '红包链接',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_red_envelopes_sync` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `out_red_envelopes_id` varchar(64) NOT NULL DEFAULT '' COMMENT '外部红包id',
  `red_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `time_limit` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否有有效期 0否 1:是',
  `grant_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否发放 0否 1:是',
  `grant_time` datetime DEFAULT NULL COMMENT '发放事件',
  `source_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '红包来源 0:伴餐系统',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `wx_union_id` varchar(128) NOT NULL DEFAULT '' COMMENT '微信unionId',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_wx_union_id` (`wx_union_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3638 DEFAULT CHARSET=utf8mb4 COMMENT='外部红包同步表';

CREATE TABLE `bwc_red_envelopes_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `red_link_id` int(10) NOT NULL DEFAULT '0' COMMENT '红包链接id',
  `title` varchar(22) NOT NULL DEFAULT '' COMMENT '任务标题',
  `exec_time` datetime NOT NULL COMMENT '执行时间',
  `replace_area` varchar(255) NOT NULL DEFAULT '' COMMENT '替换区域， 逗号分隔的字符串',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '任务状态0待执行；1已完成',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_red_envelopes_template` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `name` varchar(32) NOT NULL DEFAULT '' COMMENT '名称',
  `send_scene` tinyint(1) NOT NULL DEFAULT '0' COMMENT '投放场景(同bwc_red_envelopes.send_scene)',
  `client` tinyint(1) NOT NULL DEFAULT '1' COMMENT '适用端(1:全部 2:app)',
  `threshold_max` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最大返现门槛',
  `is_no_threshold` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否无门槛(0:否 1:是)',
  `is_all_category` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否全品类适用(0:否 1:是)',
  `is_all_platform` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否适用全部平台bwc_red_envelopes_applicable_platform(0:否 1:是)',
  `is_lock` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否锁定无法修改(0:否 1:是)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COMMENT='红包模板表';

CREATE TABLE `bwc_red_envelopes_template_category_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `red_envelopes_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '红包模板id',
  `category_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺品类id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_template_id` (`red_envelopes_template_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COMMENT='红包模板-品类关联表';

CREATE TABLE `bwc_red_envelopes_template_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `group_name` varchar(64) NOT NULL DEFAULT '' COMMENT '组名称',
  `send_scene` tinyint(1) NOT NULL DEFAULT '0' COMMENT '投放场景(同bwc_red_envelopes.send_scene)',
  `red_amount_total` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '组内红包总金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='红包模板组表';

CREATE TABLE `bwc_red_envelopes_template_group_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `template_group_id` int(11) NOT NULL DEFAULT '0' COMMENT '红包模板组id',
  `template_id` int(11) NOT NULL DEFAULT '0' COMMENT '红包模板id',
  `red_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `validity_h` int(11) NOT NULL DEFAULT '0' COMMENT '有效期,单位小时(发放后多少小时过期,0永久有效)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COMMENT='红包模板和模板组关联表';

CREATE TABLE `bwc_red_envelopes_template_platform_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `red_envelopes_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '红包模板id',
  `platform_abbreviation` varchar(32) NOT NULL DEFAULT '' COMMENT '平台简称（英文简写）同bwc_business_platform.platform_abbreviation',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_template_id` (`red_envelopes_template_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=utf8mb4 COMMENT='红包模板-平台关联表';

CREATE TABLE `bwc_repurchase_card_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id，bwc_store.id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `store_enter_qr` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺的进店二维码',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '地址',
  `store_longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `store_latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `search_keyword` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺搜索关键词',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `task_start_time` datetime DEFAULT NULL COMMENT '活动开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '活动结束时间',
  `start_time` time DEFAULT NULL COMMENT '报名开始时间',
  `task_start_date` date DEFAULT NULL COMMENT '活动开始日期',
  `end_time` time DEFAULT NULL COMMENT '报名结束时间',
  `task_end_date` date DEFAULT NULL COMMENT '活动结束日期',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广人id，bwc_admin.id',
  `task_total_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务名额',
  `task_applicants_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '已报名人数',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要好评，1图文反馈3文字反馈2无需反馈（兼容以前数据）4无需图文',
  `is_machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否自动通过审核',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 bwc_business_platform.id',
  `data_state` tinyint(1) unsigned zerofill NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '任务状态 1进行中 2已关闭',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_end_time` (`data_state`,`task_end_time`,`task_start_time`) USING BTREE,
  KEY `idx_task_type` (`task_type`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE,
  KEY `idx_promoter_id` (`promoter_id`,`task_start_time`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=695 DEFAULT CHARSET=utf8mb4 COMMENT='复购卡活动表';

CREATE TABLE `bwc_repurchase_card_task_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `repurchase_card_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '复购卡任务id,bwc_repurchase_card_task.id',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作员id',
  `before_data` text NOT NULL COMMENT '修改前数据，json',
  `after_data` text NOT NULL COMMENT '修改后数据，json',
  `operation_ip` varchar(20) NOT NULL COMMENT '操作ip',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_repurchase_card_task_id` (`repurchase_card_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1268 DEFAULT CHARSET=utf8mb4 COMMENT='复购卡活动-修改记录表';

CREATE TABLE `bwc_repurchase_card_task_views` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务ID，bwc_repurchase_card_task.id',
  `stat_date` date DEFAULT NULL COMMENT '统计日期，按天聚合用',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id，bwc_store.id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 bwc_business_platform.id',
  `home_page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '主页展示量',
  `page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '浏览量',
  `browsing_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '浏览用户量',
  `registered_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数量',
  `registered_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户量',
  `task_start_time` datetime DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '报名结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_task_id_stat_date` (`task_id`,`stat_date`),
  KEY `idx_task_type` (`task_type`),
  KEY `idx_store_id` (`store_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40362 DEFAULT CHARSET=utf8mb4 COMMENT='复购卡活动-浏览记录表';

CREATE TABLE `bwc_role` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `role_name` varchar(50) NOT NULL DEFAULT '' COMMENT '角色名称',
  `level` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '角色级别',
  `disabled` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否禁用1是2否',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=93 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_role_authority` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_key` varchar(255) NOT NULL COMMENT '角色key',
  `auth_id` int(11) unsigned NOT NULL COMMENT '权限id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8;

CREATE TABLE `bwc_role_authority_range` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_authority_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '关联role_authority表id',
  `role_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '角色id',
  `authority_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '权限id',
  `range` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '1. 全部  2. 代理范围内 3. 代理范围内销售所属 4. 小组内销售所属 5. 个人所属',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `role_authority_id` (`role_authority_id`),
  KEY `role_id` (`role_id`,`authority_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1670 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_role_authority_temp` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '0',
  `role_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '角色id',
  `auth_id` int(11) unsigned NOT NULL COMMENT '权限id',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=576853 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_role_ext` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `role_id` int(10) NOT NULL DEFAULT '0' COMMENT '权限表id',
  `max_get_mobile_num` int(10) NOT NULL DEFAULT '0' COMMENT '最大查看脱敏手机号的次数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_role_id` (`role_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb4 COMMENT='权限的拓展表';

CREATE TABLE `bwc_role_range` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '角色id',
  `range` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '1. 全部  2. 代理范围内 3. 代理范围内销售所属 4. 小组内销售所属 5. 个人所属',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1695 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_secret_signal` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `signal_code` varchar(32) NOT NULL DEFAULT '' COMMENT '暗号',
  `scene_code` varchar(32) NOT NULL DEFAULT '' COMMENT '场景用途',
  `channel` varchar(32) NOT NULL DEFAULT '' COMMENT '推广渠道',
  `ext_params` varchar(512) NOT NULL DEFAULT '' COMMENT '扩展参数',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '生成暗号的用户id',
  `expire_time` datetime DEFAULT NULL COMMENT '失效时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_signal_code` (`signal_code`),
  KEY `idx_user_scene_channel` (`user_id`,`scene_code`,`signal_code`)
) ENGINE=InnoDB AUTO_INCREMENT=6834 DEFAULT CHARSET=utf8mb4 COMMENT='暗号记录表';

CREATE TABLE `bwc_secret_signal_bind_leader_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `secret_signal_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '暗号记录表id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员id',
  `user_promoter_id` int(11) NOT NULL DEFAULT '0' COMMENT '团长id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_secret_signal_id` (`secret_signal_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_promoter_id` (`user_promoter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3124 DEFAULT CHARSET=utf8mb4 COMMENT='暗号绑定团长记录表';

CREATE TABLE `bwc_seller` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `username` varchar(32) NOT NULL DEFAULT '' COMMENT '商家手机号',
  `password` varchar(32) CHARACTER SET utf8 NOT NULL COMMENT '密码',
  `salt` varchar(4) CHARACTER SET utf8 NOT NULL COMMENT '密码盐',
  `openid` varchar(50) NOT NULL DEFAULT '' COMMENT '微信公众号openid',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `middleman_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '中间人id',
  `seller_name` varchar(50) NOT NULL DEFAULT '' COMMENT '商家名称',
  `refund_period` decimal(11,1) unsigned NOT NULL DEFAULT '0.0' COMMENT '平均支付时长',
  `contact_name` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人姓名',
  `contact_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人手机号',
  `rebate_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返点',
  `last_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次登陆时间',
  `last_ip` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '上次登陆ip',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1启用 2禁用',
  `alipay_name` varchar(50) DEFAULT '' COMMENT '支付宝姓名',
  `alipay_account` varchar(50) DEFAULT '' COMMENT '支付宝账号',
  `can_withdrawal` tinyint(1) NOT NULL DEFAULT '1' COMMENT '商家能否提现：默认1可以提现，2不可以提现',
  `relive_switch` tinyint(4) NOT NULL DEFAULT '1' COMMENT '商家控制订单能否复活开关：1可以复活，0不能复活',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `parent_seller_id` int(11) DEFAULT NULL,
  `account_type` varchar(32) DEFAULT 'sub' COMMENT '账号类型:main=主账号，sub=子账号',
  `pre_order_switch` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否开启预售单量充值开关：1开启，2关闭',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_username` (`username`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`,`data_state`,`status`) USING BTREE,
  KEY `idx_parent_seller_id` (`parent_seller_id`),
  KEY `idx_account_type` (`account_type`)
) ENGINE=InnoDB AUTO_INCREMENT=364348 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_seller_20251204_bak` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `username` varchar(32) NOT NULL DEFAULT '' COMMENT '商家手机号',
  `password` varchar(32) CHARACTER SET utf8 NOT NULL COMMENT '密码',
  `salt` varchar(4) CHARACTER SET utf8 NOT NULL COMMENT '密码盐',
  `openid` varchar(50) NOT NULL DEFAULT '' COMMENT '微信公众号openid',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `middleman_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '中间人id',
  `seller_name` varchar(50) NOT NULL DEFAULT '' COMMENT '商家名称',
  `refund_period` decimal(11,1) unsigned NOT NULL DEFAULT '0.0' COMMENT '平均支付时长',
  `contact_name` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人姓名',
  `contact_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人手机号',
  `rebate_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返点',
  `last_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次登陆时间',
  `last_ip` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '上次登陆ip',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1启用 2禁用',
  `alipay_name` varchar(50) DEFAULT '' COMMENT '支付宝姓名',
  `alipay_account` varchar(50) DEFAULT '' COMMENT '支付宝账号',
  `relive_switch` tinyint(4) NOT NULL DEFAULT '1' COMMENT '商家控制订单能否复活开关：1可以复活，0不能复活',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `parent_seller_id` int(11) DEFAULT NULL,
  `account_type` varchar(32) DEFAULT 'sub' COMMENT '账号类型:main=主账号，sub=子账号',
  `pre_order_switch` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否开启预售单量充值开关：1开启，2关闭',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_username` (`username`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`,`data_state`,`status`) USING BTREE,
  KEY `idx_parent_seller_id` (`parent_seller_id`),
  KEY `idx_account_type` (`account_type`)
) ENGINE=InnoDB AUTO_INCREMENT=345868 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_seller_account_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `main_seller_id` int(11) unsigned NOT NULL COMMENT '主账号ID',
  `sub_seller_id` int(11) unsigned NOT NULL COMMENT '子账号ID',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态，0表示正常，1表示删除',
  `created_by` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_admin.id 管理员ID',
  `updated_by` int(11) DEFAULT NULL COMMENT 'bwc_admin.id 管理员ID',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_main_seller_id` (`main_seller_id`) USING BTREE,
  KEY `idx_sub_seller_id` (`sub_seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1340 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_id` tinyint(2) NOT NULL DEFAULT '0' COMMENT '平台id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `sale_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属销售',
  `bill_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '账单金额',
  `pre_order_volume_bill_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '预存单量金额',
  `receipt_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '到账金额',
  `bill_no` varchar(100) NOT NULL DEFAULT '' COMMENT '账单号',
  `pay_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '支付状态1.待支付 2.已支付',
  `pay_method` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '支付渠道 1.支付宝 2.微信 3.线下打款 4,首信易-支付宝 5.首信易-微信',
  `payment_time` datetime DEFAULT NULL COMMENT '商家支付时间',
  `pay_no` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方的支付单号',
  `callback_body` text COMMENT '回调body',
  `excel_url` varchar(1024) NOT NULL DEFAULT '',
  `version` tinyint(3) unsigned NOT NULL DEFAULT '2' COMMENT '账单版本',
  `more_pay` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '疑似多次付款 1是2否',
  `bill_fee_cashier` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '账单金额，出纳记录凭证用',
  `send_reminder_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '发送账单提醒次数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `tag_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '标记状态：0非坏账，1是坏账',
  `task_time` date DEFAULT NULL COMMENT '活动日期',
  `is_copy` tinyint(2) NOT NULL DEFAULT '0' COMMENT '1：已复制 0：未复制',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_create_time` (`sale_id`,`create_time`) USING BTREE,
  KEY `idx_create_time_status` (`create_time`,`pay_status`) USING BTREE,
  KEY `idx_seller_id_pay_status_agent_id` (`seller_id`,`pay_status`,`agent_id`,`data_state`),
  KEY `idx_bill_no` (`bill_no`,`data_state`),
  KEY `sale_id` (`sale_id`,`data_state`) USING BTREE,
  KEY `idx_pay_status_agent_id_sale_id` (`pay_status`,`agent_id`,`sale_id`),
  KEY `idx_agent_id` (`data_state`,`agent_id`,`platform_id`) USING BTREE,
  KEY `idx_payment_time` (`payment_time`,`data_state`,`agent_id`,`pay_method`) USING BTREE,
  KEY `idx_seller_id_pay_status_sale_id` (`pay_status`,`sale_id`,`data_state`,`seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11776597 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_seller_bill_bad_tag_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_bill_id` int(11) NOT NULL COMMENT '账单id， bwc_seller_bill.id',
  `admin_id` int(11) DEFAULT NULL COMMENT '操作人ID，bwc_admin.id',
  `admin_name` varchar(64) DEFAULT NULL COMMENT '操作人名称',
  `type` tinyint(2) unsigned DEFAULT '1' COMMENT '操作类型：1 标记为坏账、2 取消标记坏账、3 批量标记坏账、4批量取消标记坏账',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3090 DEFAULT CHARSET=utf8mb4 COMMENT='坏账标记日志记录表';

CREATE TABLE `bwc_seller_bill_change_status` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `seller_bill_id` int(11) NOT NULL DEFAULT '0' COMMENT '账单表id',
  `change_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '账单修改状态：0未修改，1有改账，2有改账被刷账',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '账单对应的任务id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_change_status` (`change_status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5261795 DEFAULT CHARSET=utf8mb4 COMMENT='商家账单修改/刷新状态表';

CREATE TABLE `bwc_seller_bill_extra` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `seller_bill_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家账单表id',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺表id',
  `bill_fee_extra` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '账单额外收取的费用',
  `bill_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '之前的账单金额，现在的活动费用',
  `bill_fee_total` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '商家要支付的账单总金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=658 DEFAULT CHARSET=utf8mb4 COMMENT='商家账单额外收取的费用';

CREATE TABLE `bwc_seller_bill_issue_order` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seller_bill_id` int(10) NOT NULL COMMENT '商家id',
  `order_id` int(10) NOT NULL COMMENT '订单id',
  `reason` varchar(100) NOT NULL DEFAULT '' COMMENT '扣款原因',
  `deduct_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1待追回，2已追回',
  `take_back_content` varchar(255) DEFAULT NULL COMMENT '追回描述',
  `take_back_image` varchar(500) DEFAULT NULL COMMENT '追回凭证',
  `take_back_admin_id` int(10) DEFAULT '0' COMMENT '追回人',
  `take_back_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '追回时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `seller_bill_id` (`seller_bill_id`) USING BTREE,
  KEY `order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18158 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_bill_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属账单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '平台支付单号',
  `bill_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '账单金额',
  `pay_method` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '4首信易-支付宝 5首信易-微信',
  `payment_mode_alias` varchar(50) NOT NULL DEFAULT '' COMMENT '支付方式代码',
  `receipt_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '到账金额',
  `pay_no` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方的支付单号',
  `payment_time` datetime DEFAULT NULL COMMENT '商家支付时间',
  `pay_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '支付状态1.待支付 2.已支付',
  `expiration_timestamp` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '过期时间戳',
  `request_body` text COMMENT '请求数据',
  `response_body` text COMMENT '返回数据',
  `callback_body` text COMMENT '回调数据',
  `request_raw` text COMMENT '发送原始数据',
  `response_raw` text COMMENT '返回原始数据（带header）',
  `callback_raw` text COMMENT '回调原始数据',
  `remark` text COMMENT '备注',
  `status` tinyint(1) unsigned DEFAULT '0' COMMENT '订单状态 1.正常 2.已撤销',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_bill_order_no` (`seller_bill_order_no`,`data_state`),
  KEY `idx_payment_time` (`payment_time`) USING BTREE,
  KEY `idx_pay_no` (`pay_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4514479 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_seller_bill_order_callback` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属账单id',
  `seller_bill_order_id` int(11) unsigned DEFAULT NULL COMMENT '付款订单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '平台支付单号',
  `callback_data` text COMMENT 'callback数据',
  `callback_raw` text COMMENT 'callback原始数据',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_bill_order_no` (`seller_bill_order_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4557327 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_seller_bill_order_callback_rele` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属账单id',
  `seller_bill_order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '付款订单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '平台支付单号',
  `seller_bill_order_back_id` int(10) NOT NULL,
  `seller_task_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家创建的任务id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_bill_order_no` (`seller_bill_order_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11041836 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_bill_order_mt` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '账单id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `id_seller_bill_id` (`seller_bill_id`),
  KEY `store_id` (`order_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7845247 DEFAULT CHARSET=utf8mb4 COMMENT='美团账单关联订单表';

CREATE TABLE `bwc_seller_bill_order_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `requestId` varchar(50) NOT NULL DEFAULT '' COMMENT '首信易三方编号',
  `url` varchar(255) NOT NULL DEFAULT '' COMMENT '请求地址',
  `params` json NOT NULL COMMENT '发起请求的参数',
  `response` json DEFAULT NULL COMMENT '返回的信息',
  `data_state` tinyint(1) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_requestId` (`requestId`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4063692 DEFAULT CHARSET=utf8mb4 COMMENT='发起第三方请求的日志列表';

CREATE TABLE `bwc_seller_bill_order_refund_ticket` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `requestId` varchar(80) NOT NULL DEFAULT '' COMMENT '三方交易单号，bwc_seller_bill_order里面的seller_bill_order_no',
  `params_data` json NOT NULL COMMENT '接收的数据',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '金额，单位元',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_request_id` (`requestId`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='三方首信易，提现成功以后，退票记录表';

CREATE TABLE `bwc_seller_bill_order_rele` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `agent_id` int(11) unsigned DEFAULT '0' COMMENT '代理id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '我们生成的账单id',
  `seller_bill_no` varchar(50) NOT NULL DEFAULT '' COMMENT '所属账单编号',
  `seller_bill_order_id` int(10) NOT NULL DEFAULT '0' COMMENT '第三方支付账单表id',
  `seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '平台支付单号',
  `seller_task_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家创建的任务id',
  `seller_withdrawal_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家提现记录id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '第三方订单类型：1账单，2提现到银行卡，3退款，4活动预支付 5充值 6预存单量充值',
  `pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '预存单量',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_bill_order_id` (`seller_bill_order_id`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE,
  KEY `idx_seller_bill_order_no` (`seller_bill_order_no`) USING BTREE,
  KEY `idx_seller_task_id` (`seller_task_id`) USING BTREE,
  KEY `idx_seller_withdrawal_id` (`seller_withdrawal_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11030179 DEFAULT CHARSET=utf8mb4 COMMENT='我们账单和支付账单的关联表';

CREATE TABLE `bwc_seller_bill_silk` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seller_bill_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家账单表id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务表id',
  `silk_task_id` int(11) NOT NULL COMMENT '小蚕任务表id',
  `old_bill_free` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '修改前账单金额',
  `bill_free` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '修改后的账单金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_seller_bill_id` (`seller_bill_id`),
  KEY `idx_silk_task_id` (`silk_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5780 DEFAULT CHARSET=utf8mb4 COMMENT='小蚕任务修改总金额以后关联我们账单表';

CREATE TABLE `bwc_seller_bill_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `seller_bill_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_seller_bill主键id',
  `platform_id` tinyint(2) NOT NULL DEFAULT '0' COMMENT '平台id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `sale_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属销售',
  `bill_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '账单金额',
  `receipt_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '到账金额',
  `bill_no` varchar(100) NOT NULL DEFAULT '' COMMENT '账单号',
  `pay_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '支付状态1.待支付 2.已支付',
  `bill_fee_cashier` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '账单金额，出纳记录凭证用',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_bill_no` (`bill_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5019930 DEFAULT CHARSET=utf8mb4 COMMENT='未结算账单余额快照';

CREATE TABLE `bwc_seller_bill_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '账单id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_activity_id` (`task_id`) USING BTREE,
  KEY `id_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11951350 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='商家账单活动关联表';

CREATE TABLE `bwc_seller_bill_task_change_bill_fee` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动id',
  `seller_bill_id` int(11) NOT NULL DEFAULT '0' COMMENT '账单表id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '操作账单金额类型：1晓晓平台扣款，2晓晓平台增加，3联盟平台扣款，4联盟平台增加',
  `amount` decimal(10,2) NOT NULL COMMENT '金额',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理后台操作人id，开放平台：-1',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7115 DEFAULT CHARSET=utf8mb4 COMMENT='账单金额修改记录表';

CREATE TABLE `bwc_seller_bill_url` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型：1商家账单，2店铺账单',
  `identification_id` int(10) NOT NULL DEFAULT '0' COMMENT '业务id',
  `search_billIds` json NOT NULL COMMENT '所有的账单id',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5643029 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_dynamic_adjust_price` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `is_open` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否打开 0否; 1是',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0默认; 1竞品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller` (`seller_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_follow_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家表id',
  `content` text NOT NULL COMMENT '跟进内容',
  `release_num` int(11) NOT NULL DEFAULT '0' COMMENT '商家放单次数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_create_by` (`create_by`)
) ENGINE=InnoDB AUTO_INCREMENT=26806 DEFAULT CHARSET=utf8mb4 COMMENT='商家跟进记录表';

CREATE TABLE `bwc_seller_follow_up_task` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `seller_id` bigint(20) unsigned NOT NULL COMMENT '商家ID，bwc_seller.id',
  `task_date` date DEFAULT NULL COMMENT '任务日期',
  `admin_id` bigint(20) unsigned DEFAULT NULL COMMENT '商务id，bwc_admin.id',
  `follow_up_time` datetime DEFAULT NULL COMMENT '跟进时间',
  `status` tinyint(3) unsigned DEFAULT '0' COMMENT '状态：0-未跟进，1-已跟进',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_admin_id` (`admin_id`),
  KEY `idx_task_date` (`task_date`)
) ENGINE=InnoDB AUTO_INCREMENT=10918645 DEFAULT CHARSET=utf8mb4 COMMENT='CRM商家跟进任务表';

CREATE TABLE `bwc_seller_franchise` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `advertisement_id` int(11) NOT NULL COMMENT '品牌，bwc_advertisement.id',
  `brand_name` varchar(255) NOT NULL COMMENT '品牌名称',
  `name` varchar(255) NOT NULL COMMENT '姓名',
  `mobile` varchar(50) NOT NULL COMMENT '联系电话',
  `seller_id` int(11) NOT NULL COMMENT '商家id，bwc_seller.id',
  `data_state` tinyint(4) unsigned NOT NULL DEFAULT '0' COMMENT '1：删除 0：正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_advertisement_id` (`advertisement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_info` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `seller_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家id',
  `avatar` varchar(300) NOT NULL DEFAULT '' COMMENT '头像',
  `available_money` decimal(10,2) NOT NULL DEFAULT '0.00',
  `freeze_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '冻结金额',
  `unpaid_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '未支付金额',
  `available_money_lkl` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '拉卡拉剩余余额',
  `freeze_money_lkl` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '拉卡拉冻结金额',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝姓名',
  `pay_password` varchar(32) NOT NULL DEFAULT '' COMMENT '支付密码',
  `bank_card_no` varchar(50) NOT NULL DEFAULT '' COMMENT '银行卡卡号',
  `bank_user_name` varchar(30) NOT NULL DEFAULT '' COMMENT '银行卡姓名',
  `bank_name` varchar(100) NOT NULL DEFAULT '' COMMENT '银行名字',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_seller_id` (`seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=59300 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_info_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `seller_info_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_seller_info主键id',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `available_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '可用金额',
  `freeze_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '冻结金额',
  `unpaid_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '未支付金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_seller_snapshot_date` (`seller_id`,`snapshot_date`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4172526 DEFAULT CHARSET=utf8mb4 COMMENT='商家余额快照';

CREATE TABLE `bwc_seller_money_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1收支记录，2提现记录，3预存单量',
  `record_desc` varchar(30) NOT NULL,
  `tip` varchar(500) NOT NULL DEFAULT '' COMMENT '充值/消费提示描述',
  `money_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1增加，2减少',
  `money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '金额',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  `pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '预存单量',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=48841 DEFAULT CHARSET=utf8mb4 COMMENT='商家充值/消费相关记录';

CREATE TABLE `bwc_seller_money_record_silk` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `silk_record_id` int(10) NOT NULL DEFAULT '0' COMMENT '小蚕记录表id',
  `xx_record_id` int(10) NOT NULL DEFAULT '0' COMMENT '晓晓商家余额变动记录id',
  `balance` int(10) NOT NULL DEFAULT '0' COMMENT '变动金额，单位分',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：1处理中，2处理成功，3处理失败',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_silk_record_id` (`silk_record_id`),
  KEY `idx_xx_record_id` (`xx_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1212 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_out_info` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `seller_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家id',
  `seller_out_id` varchar(50) NOT NULL DEFAULT '' COMMENT '商家对外的id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `seller_id` (`seller_id`) USING BTREE,
  KEY `seller_out_id` (`seller_out_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1297847 DEFAULT CHARSET=utf8mb4 COMMENT='商家能对外的业务表';

CREATE TABLE `bwc_seller_popup_setting` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id，bwc_seller.id',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '弹窗类型：1，首页新手引导弹窗 2：店铺新手引导弹窗',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1：开启 0：关闭',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_seller_id_type` (`seller_id`,`type`)
) ENGINE=InnoDB AUTO_INCREMENT=25717 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_pre_order_volume` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id，bwc_seller.id',
  `seller_bill_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_seller_bill_order.id',
  `price` decimal(10,2) DEFAULT '0.00' COMMENT '价值',
  `unit_price` decimal(10,2) DEFAULT '0.00' COMMENT '单价',
  `pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '总的预存单量',
  `available_pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '剩余预存单量',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态，0表示正常，1表示删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='商家预存单量购买记录表';

CREATE TABLE `bwc_seller_pre_order_volume_transaction` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id，bwc_seller.id',
  `seller_pre_order_volume_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_seller_pre_order_volume.id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_task.id任务id',
  `task_cycle_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_task_cycle_create.id循环任务',
  `seller_bill_order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_seller_bill_order.id',
  `pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '预存单量',
  `refund_pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '退款预存单量',
  `remaining_pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '剩余预存单量',
  `data_state` tinyint(4) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_seller_pre_order_volume_id` (`seller_pre_order_volume_id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_task_cycle_id` (`task_cycle_id`),
  KEY `idx_seller_bill_order` (`seller_bill_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商家预存单量消费记录表';

CREATE TABLE `bwc_seller_pre_pay_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_id` int(10) NOT NULL COMMENT '任务id',
  `seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '首信易支付订单编号',
  `lkl_id` int(11) DEFAULT NULL COMMENT '拉卡拉支付关联表id',
  `pre_pay_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '预支付金额',
  `pre_pay_time` datetime DEFAULT NULL COMMENT '预支付时间',
  `pre_pay_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '预支付状态 1 预支付中 2已支付 3支付失败',
  `is_cycle_task` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否循环发布任务 0否 1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_id` (`task_id`,`seller_bill_order_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=284792 DEFAULT CHARSET=utf8mb4 COMMENT='预支付记录表';

CREATE TABLE `bwc_seller_refund_money` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_id` int(10) NOT NULL COMMENT '任务id',
  `pre_pay_seller_bill_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '预支付发起的三方订单编号',
  `refund_money_seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '退款发起的三方编号',
  `refund_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '退款金额',
  `refund_time` datetime DEFAULT NULL COMMENT '退款时间',
  `refund_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '退款状态 1退款中 2已退款 3退款失败 4退款成功',
  `is_cycle_task` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否循环发布任务 0否 1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=175276 DEFAULT CHARSET=utf8mb4 COMMENT='退款记录表';

CREATE TABLE `bwc_seller_refund_money_back_lkl` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `lkl_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '拉卡拉id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `task_id` int(10) NOT NULL DEFAULT '0' COMMENT '任务id',
  `seller_bill_id` int(10) NOT NULL DEFAULT '0' COMMENT '账单表id',
  `pay_no` varchar(255) NOT NULL DEFAULT '' COMMENT '预支付发起的三方订单编号',
  `refund_money_seller_bill_order_no` varchar(50) NOT NULL DEFAULT '' COMMENT '退款发起的三方编号',
  `refund_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '退款金额',
  `refund_time` datetime DEFAULT NULL COMMENT '退款时间',
  `refund_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '退款状态 1退款中 2退款成功 3退款失败',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_lkl_id` (`lkl_id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_pay_no` (`pay_no`) USING BTREE,
  KEY `idx_seller_bill_id` (`seller_bill_id`) USING BTREE,
  KEY `idx_refund_money_seller_bill_order_no` (`refund_money_seller_bill_order_no`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='小蚕工单商家原路退款记录表';

CREATE TABLE `bwc_seller_remind` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `seller_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家id',
  `remind_num` int(10) NOT NULL DEFAULT '0' COMMENT '提醒次数（预留字段）',
  `remind_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '提醒类型：0默认（预留字段）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `seller_remind` (`seller_id`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=62284 DEFAULT CHARSET=utf8mb4 COMMENT='商家账单提醒表';

CREATE TABLE `bwc_seller_silk` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓bwc_seller表id',
  `silk_seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '小蚕对应的seller_id',
  `platform_uid` int(11) NOT NULL DEFAULT '0' COMMENT '小蚕平台id',
  `silk_id` varchar(100) NOT NULL DEFAULT '0' COMMENT '小蚕平台传递过来的silk_id',
  `silk_callback_data` json DEFAULT NULL COMMENT '小蚕返回的回调信息',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_seller_id` (`seller_id`) USING BTREE,
  KEY `idx_silk_seller_id` (`silk_seller_id`) USING BTREE,
  KEY `idx_silk_id` (`silk_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=352133 DEFAULT CHARSET=utf8mb4 COMMENT='晓晓活动关联小蚕活动id';

CREATE TABLE `bwc_seller_statistics` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seller_id` int(10) NOT NULL DEFAULT '0',
  `last_release_time` datetime DEFAULT NULL COMMENT '最近放单时间',
  `total_release_number` int(11) DEFAULT '0' COMMENT '全部放单次数',
  `total_seller_bill_fee` decimal(10,2) DEFAULT NULL COMMENT '全部账单金额',
  `consumption_interval_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '消费间隔得分',
  `consumption_frequency_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '消费频率得分',
  `consumption_amount_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '消费金额得分',
  `score_update_time` datetime DEFAULT NULL COMMENT '分数变更时间',
  `today_has_activity` tinyint(1) NOT NULL DEFAULT '0' COMMENT '今日是否放活动：0未放，1已放，每日0点更新',
  `follow_day` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最新一次跟进时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_seller_id` (`seller_id`) USING BTREE,
  KEY `idx_follow_day` (`follow_day`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=350263 DEFAULT CHARSET=utf8mb4 COMMENT='商家放单信息等统计';

CREATE TABLE `bwc_seller_tag` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `tag_name` varchar(64) NOT NULL DEFAULT '' COMMENT '标签名字',
  `tag_color` varchar(32) NOT NULL DEFAULT '' COMMENT '标签颜色',
  `tag_level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '标签等级 0:红色 1:橙色 2:蓝色 3:绿色 4:灰色',
  `tag_desc` varchar(256) NOT NULL DEFAULT '' COMMENT '标签说明',
  `rs_condition` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'rs条件 0:小于 1:大于',
  `fs_condition` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'fs条件 0:小于 1:大于',
  `ms_condition` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'ms条件 0:小于 1:大于',
  `spel_rule` varchar(1024) NOT NULL DEFAULT '' COMMENT 'spel规则表达式',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COMMENT='商家标签表';

CREATE TABLE `bwc_seller_tag_lost` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家表id',
  `reason_id` int(11) NOT NULL COMMENT '1店铺倒闭 2商家认为放单效果不好找竞对了 3封控原因不合作 4改使用官方霸王餐放单',
  `reason` text NOT NULL COMMENT '原因',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_seller_id` (`seller_id`)
) ENGINE=InnoDB AUTO_INCREMENT=289 DEFAULT CHARSET=utf8mb4 COMMENT='标记为流失用户表';

CREATE TABLE `bwc_seller_tag_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `seller_tag_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家标签id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_seller_tag_id` (`seller_tag_id`),
  KEY `idx_seller_id` (`seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=350139 DEFAULT CHARSET=utf8mb4 COMMENT='商家标签关联表';

CREATE TABLE `bwc_seller_third_user_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `identifier` varchar(128) NOT NULL DEFAULT '' COMMENT '用户唯一标识',
  `appid` varchar(50) NOT NULL DEFAULT '' COMMENT '第三方appid',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `operator_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '操作类型0商家1客服',
  `operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人id，根据operator_type指示，0表示记录seller_id, 1表示admin_id',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '拉黑原因',
  `remove_operator_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '移除操作类型0商家，1后台管理人员操作',
  `remove_operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '移除操作人id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_app_store` (`identifier`,`appid`,`store_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=68304 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_transaction` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `seller_id` bigint(20) NOT NULL COMMENT 'bwc_seller.id商家id',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '变动金额',
  `relation_type` int(11) NOT NULL COMMENT '类型，1：活动预付 2：预付返还 3：活动预付（循环发布任务） 4：预付返还（循环发布任务）',
  `relation_id` int(11) NOT NULL COMMENT '关联id，1，2关联的bwc_task.id，3，4关联bwc_task_cycle_create',
  `change_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1:增加, 2:减少',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0正常1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_relation_type_id` (`relation_type`,`relation_id`),
  KEY `idx_store_id` (`store_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8938 DEFAULT CHARSET=utf8mb4 COMMENT='商家账变记录';

CREATE TABLE `bwc_seller_user_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `user_nick` varchar(30) NOT NULL DEFAULT '' COMMENT '用户拉黑时的昵称',
  `user_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户拉黑时的手机号',
  `user_alipay_account` varchar(50) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `user_alipay_name` varchar(50) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `operator_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '操作类型0商家1客服',
  `operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人id，根据operator_type指示，0表示记录seller_id, 1表示admin_id',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '拉黑原因',
  `remove_operator_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '移除操作类型0商家，1后台管理人员操作',
  `remove_operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '移除操作人id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_store` (`user_id`,`store_id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1815752 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_seller_withdrawal` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id',
  `seller_name` varchar(50) DEFAULT NULL,
  `withdrawal_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '提现金额',
  `remaining_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '剩余金额',
  `withdrawal_time` datetime DEFAULT NULL COMMENT '提现申请时间',
  `withdrawal_status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '提现状态 1 申请中 2已打款 3已驳回 4打款中 5打款失败',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1474 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_settlement_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_code` varchar(255) NOT NULL DEFAULT '' COMMENT '订单码',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `order_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `order_status` tinyint(1) DEFAULT '0' COMMENT '1待支付2已支付-1已取消',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=80951 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_show_image_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT 'bwc_admin表对应的id',
  `biz_type` tinyint(10) NOT NULL DEFAULT '0' COMMENT '业务类型:1后台订单详情',
  `biz_id` int(10) NOT NULL DEFAULT '0' COMMENT '业务表id',
  `image_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '查看的图片地址',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1941033 DEFAULT CHARSET=utf8mb4 COMMENT='后台查看图片记录表';

CREATE TABLE `bwc_show_mobile_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT 'bwc_user表对应的id',
  `day` date DEFAULT NULL COMMENT '时间',
  `num` int(10) NOT NULL DEFAULT '0' COMMENT '查看的总次数',
  `seller_mobile_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看商家手机号次数',
  `middleman_mobile_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看中间人手机号次数',
  `middleman_alipay_account_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看中间人支付宝账号次数',
  `order_detail_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看订单详情数量',
  `order_audit_detail_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看订单审核详情数量',
  `user_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看新用户列表手机号',
  `user_list_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看用户列表手机号',
  `user_alipay_account_num` int(10) NOT NULL DEFAULT '0' COMMENT '查看用户列表支付宝账号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=121059 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_sms_channel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '短信渠道名称',
  `code` varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '系统编码',
  `enabled` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否开启',
  `config` text CHARACTER SET utf8 NOT NULL COMMENT '配置',
  `balance` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '剩余数量',
  `balance_unit` enum('条','元','欧元','比索','美元') CHARACTER SET utf8 NOT NULL DEFAULT '条' COMMENT '短信余额单位',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_sms_template` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '短信渠道id',
  `code` varchar(50) CHARACTER SET utf8 NOT NULL COMMENT '模板编码',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '模板名称',
  `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用 1是其他否',
  `config` text CHARACTER SET utf8 COMMENT '配置',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=132 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_store` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '商铺名称',
  `store_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1美团2饿了么',
  `cooperation_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '合作类型：1信息推广服务模式，2品牌推广服务模式（服务费总额增加 6%），3品牌推广服务模式（用户承担 1 元），4品牌推广服务模式（0 成本）',
  `contract_party` tinyint(1) NOT NULL DEFAULT '0' COMMENT '签约主体：1杭州晓晓惠点餐信息技术有限公司',
  `store_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺封面',
  `store_enter_qr` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺进店二维码',
  `store_link` varchar(255) NOT NULL DEFAULT '' COMMENT '商铺链接',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '商铺地址',
  `store_longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `store_latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `start_time` time DEFAULT NULL COMMENT '店铺营业开始时间',
  `end_time` time DEFAULT NULL COMMENT '店铺营业结束时间',
  `cate_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分类id',
  `cate` varchar(20) NOT NULL DEFAULT '' COMMENT '分类名称',
  `area_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '区域id',
  `area` varchar(20) NOT NULL DEFAULT '' COMMENT '区域名称',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属代理id',
  `area_ad_code` varchar(32) NOT NULL DEFAULT '0' COMMENT '所属区县code',
  `daily_user_task_number` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '同一用户每日可报名次数 0为不限制',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商户ID',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广员id',
  `promoter` varchar(20) NOT NULL DEFAULT '' COMMENT '推广员名称',
  `store_balance_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '商铺余额',
  `store_retention_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '商铺滞留金（用于发布任务时暂扣，任务结束后剩余金额返回）',
  `store_bond_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '店铺保证金',
  `user_registration_interval` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户报名间隔(天)',
  `applet_url` varchar(255) NOT NULL DEFAULT '' COMMENT '小程序跳转地址',
  `brand_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '大牌id，bwc_brand.id',
  `is_brand` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否大牌 1：是 0：否',
  `is_advance` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否允许提前抢单：1：是 0：否',
  `is_mark_invoice` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否标记开票，0否，1是',
  `is_recent` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否是最近的上新店铺',
  `first_task_date` date DEFAULT NULL COMMENT '店铺首次放单日期（取task_start_time对应的日期）',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '店铺状态0正常1禁用',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `store_name` (`store_name`,`agent_id`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`,`data_state`,`create_time`),
  KEY `idx_seller_id` (`seller_id`) USING BTREE,
  KEY `idx_promoter_id` (`promoter_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_brand_id` (`brand_id`),
  KEY `idx_is_mark_invoice` (`is_mark_invoice`) USING BTREE,
  KEY `idx_ area_ad_code` (`area_ad_code`) USING BTREE,
  KEY `idx_store_sort` (`agent_id`,`is_recent`) USING BTREE,
  KEY `idx_first_task_date` (`first_task_date`)
) ENGINE=InnoDB AUTO_INCREMENT=744880 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_area` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `area_name` varchar(20) NOT NULL DEFAULT '' COMMENT '区域名称',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '区域排序',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广员id',
  `promoter` varchar(20) NOT NULL DEFAULT '' COMMENT '推广员名称',
  `wechat_group_qr_code` varchar(1500) NOT NULL DEFAULT '' COMMENT '微信分享群二维码',
  `is_hidden` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否隐藏0否1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_cate` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `cate_name` varchar(20) NOT NULL DEFAULT '' COMMENT '分类名称',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '分类排序',
  `wechat_group_qr_code` varchar(255) NOT NULL DEFAULT '' COMMENT '微信群二维码',
  `is_hidden` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否隐藏0否1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_category` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(255) DEFAULT NULL COMMENT '品类名称',
  `description` text COMMENT '品类描述',
  `hot_time_frame` varchar(255) NOT NULL DEFAULT '' COMMENT '高峰时间段',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COMMENT='店铺品类';

CREATE TABLE `bwc_store_category_mz_mapping` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `mz_category_name` varchar(255) NOT NULL COMMENT '美赚品类名称',
  `mz_category_id` int(11) NOT NULL COMMENT '美赚品类ID',
  `xx_category_id` int(11) NOT NULL COMMENT '晓晓品类ID（关联bwc_store_category.id）',
  `xx_category_name` varchar(255) DEFAULT NULL COMMENT '晓晓品类名称（冗余存储，便于查询）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态：0正常 1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_xx_category_id` (`xx_category_id`),
  KEY `idx_mz_category_id` (`mz_category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COMMENT='美赚与晓晓品类映射表';

CREATE TABLE `bwc_store_category_peak_period` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_category_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺分类id',
  `peak_period` varchar(256) NOT NULL DEFAULT '' COMMENT '高峰期时段',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COMMENT='店铺分类高峰期';

CREATE TABLE `bwc_store_category_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `store_id` int(11) unsigned NOT NULL COMMENT '店铺ID，关联bwc_store.id',
  `category_id` int(11) unsigned NOT NULL COMMENT '品类ID，关联bwc_store_category.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_category_id` (`category_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1233629 DEFAULT CHARSET=utf8mb4 COMMENT='店铺与品类关联表';

CREATE TABLE `bwc_store_category_tag_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `store_id` int(11) unsigned NOT NULL COMMENT '店铺ID，关联bwc_store.id',
  `category_tag_id` int(11) unsigned NOT NULL COMMENT '品类标签ID，关联bwc_store_category_tag.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_category_tag_id` (`category_tag_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1419286 DEFAULT CHARSET=utf8mb4 COMMENT='店铺与品类标签关联表';

CREATE TABLE `bwc_store_change_promoter_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '类型：1修改店铺，2批量修改店铺，3一键移交店铺',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作员id',
  `before_promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '修改前的销售',
  `after_promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '修改后的销售',
  `operation_ip` varchar(20) NOT NULL DEFAULT '' COMMENT '操作ip',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_id` (`store_id`,`type`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=140127 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_clue` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_id` varchar(128) NOT NULL DEFAULT '' COMMENT '平台店铺id,非晓晓店铺id',
  `store_name` varchar(128) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `platform_code` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:美团 1:饿了么',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `total_quota` int(11) NOT NULL DEFAULT '0' COMMENT '总名额',
  `remaining_quota` int(11) NOT NULL DEFAULT '0' COMMENT '剩余名额',
  `city_name` varchar(64) NOT NULL DEFAULT '' COMMENT '城市名称',
  `region_name` varchar(256) NOT NULL DEFAULT '' COMMENT '省市区信息',
  `center_lat` varchar(20) NOT NULL DEFAULT '' COMMENT '中心点纬度',
  `center_lng` varchar(20) NOT NULL DEFAULT '' COMMENT '中心点经度',
  `center_address` varchar(256) NOT NULL DEFAULT '' COMMENT '中心点地址',
  `center_distance` int(11) NOT NULL DEFAULT '0' COMMENT '店铺距中心点距离,单位米',
  `ad_code` varchar(32) NOT NULL DEFAULT '' COMMENT '高德adCode',
  `batch_id` varchar(64) NOT NULL DEFAULT '' COMMENT '上传批次标识',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '上传人id',
  `match_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否匹配到我方店铺 0:未匹配 1:有 2:无',
  `source_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '来源类型 0:小蚕 1:歪卖',
  `seller_phone` varchar(32) NOT NULL DEFAULT '' COMMENT '商家手机号',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_store_name` (`store_name`) USING BTREE,
  KEY `idx_city_name` (`city_name`) USING BTREE,
  KEY `idx_region_name` (`region_name`) USING BTREE,
  KEY `idx_store_source` (`store_id`,`source_type`,`is_delete`) USING BTREE,
  KEY `idx_agent_admin_id` (`agent_id`,`admin_id`) USING BTREE,
  KEY `idx_ad_code` (`ad_code`,`is_delete`)
) ENGINE=InnoDB AUTO_INCREMENT=1536620 DEFAULT CHARSET=utf8mb4 COMMENT='店铺线索表';

CREATE TABLE `bwc_store_clue_reference` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_clue_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺线索表id',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `total_quota` int(11) NOT NULL DEFAULT '0' COMMENT '总名额',
  `remaining_quota` int(11) NOT NULL DEFAULT '0' COMMENT '剩余名额',
  `batch_id` varchar(64) NOT NULL DEFAULT '' COMMENT '上传批次标识',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '上传人id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_store_clue_id` (`store_clue_id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE,
  KEY `idx_store_clue_batch` (`store_clue_id`,`batch_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=106492763 DEFAULT CHARSET=utf8mb4 COMMENT='店铺线索上传关联表';

CREATE TABLE `bwc_store_clue_xx_store` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_clue_id` int(11) NOT NULL DEFAULT '0' COMMENT '线索id',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓店铺id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_store_clue_id` (`store_clue_id`),
  KEY `idx_store_id` (`store_id`)
) ENGINE=InnoDB AUTO_INCREMENT=295303 DEFAULT CHARSET=utf8mb4 COMMENT='店铺线索晓晓店铺关联表';

CREATE TABLE `bwc_store_contacts` (
  `id` int(11) unsigned NOT NULL COMMENT '主键',
  `contacts_name` varchar(50) NOT NULL DEFAULT '' COMMENT '联系人姓名',
  `contacts_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人电话',
  `contacts_wechat` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人微信号',
  `contacts_email` varchar(255) NOT NULL DEFAULT '' COMMENT '联系人电子邮箱',
  `contacts_gender` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '联系人性别 1男2女其他未知',
  `contacts_call` varchar(20) NOT NULL DEFAULT '' COMMENT '联系人称呼：例如（先生，女士，经理等）',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_dynamic_adjust_price` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `is_open` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否打开 0否; 1是',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0默认; 1竞品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store` (`store_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_error_report` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_user.id c用户id',
  `num` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '上报次数',
  `report_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上报时间',
  `store_error_report_type_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store_error_report_type.id 类型id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store.id 店铺id',
  `status` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '处理状态，0未处理1已处理',
  `handled_by` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_admin.id 处理人',
  `handled_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '处理时间',
  `data_state` tinyint(3) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_store_error_report_type_id` (`store_error_report_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=54562 DEFAULT CHARSET=utf8mb4 COMMENT='店铺错误信息上报';

CREATE TABLE `bwc_store_error_report_notice_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_error_report_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store_error_report.id 类型id',
  `store_error_report_type_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store_error_report_type.id 类型id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store.id 店铺id',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '推送的销售id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_msg_record` (`store_error_report_type_id`,`admin_id`,`gmt_created`,`is_delete`)
) ENGINE=InnoDB AUTO_INCREMENT=59574 DEFAULT CHARSET=utf8mb4 COMMENT='店铺错误信息上报通知记录表';

CREATE TABLE `bwc_store_error_report_type` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(255) DEFAULT NULL,
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COMMENT='店铺错误信息上报类型';

CREATE TABLE `bwc_store_error_report_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_user.id c用户id',
  `store_error_report_type_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store_error_report_type.id 类型id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_store.id 店铺id',
  `data_state` tinyint(3) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_store_error_report_type_id` (`store_error_report_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=42070 DEFAULT CHARSET=utf8mb4 COMMENT='店铺错误信息上报用户';

CREATE TABLE `bwc_store_goods` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `store_id` int(11) NOT NULL DEFAULT '0',
  `spu_tags` json DEFAULT NULL COMMENT '上传过来的热门商品json',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7816 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_invoice` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '金额',
  `channel` tinyint(1) NOT NULL DEFAULT '0' COMMENT '支付渠道：1晓晓惠点餐，2沪杭惠，3成都分公司',
  `start_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `end_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `remark` text NOT NULL COMMENT '备注',
  `pay_method` tinyint(1) NOT NULL DEFAULT '0' COMMENT '支付方式：1支付宝，2微信',
  `pay_no` varchar(50) NOT NULL DEFAULT '' COMMENT '商户订单号',
  `payment_time` datetime DEFAULT NULL COMMENT '商家支付时间',
  `pay_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '支付状态：0未支付，1待支付，2支付成功，3支付失败',
  `pay_remark` text COMMENT '支付失败信息',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_pay_no` (`pay_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=454 DEFAULT CHARSET=utf8mb4 COMMENT='店铺开票记录表';

CREATE TABLE `bwc_store_invoice_pay_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `store_id` int(11) NOT NULL DEFAULT '0',
  `invoice_id` int(11) NOT NULL DEFAULT '0',
  `bill_fee` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '账单金额',
  `pay_method` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1支付宝 2微信',
  `receipt_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '到账金额',
  `pay_no` varchar(255) NOT NULL DEFAULT '' COMMENT '商户订单号',
  `payment_time` datetime DEFAULT NULL COMMENT '商家支付时间',
  `pay_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '支付状态1.支付中 2.已支付，3支付失败',
  `pay_remark` text COMMENT '备注',
  `request_body` text COMMENT '请求数据',
  `response_body` text COMMENT '返回数据',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ invoice_id` (`invoice_id`) USING BTREE,
  KEY `idx_pay_no` (`pay_no`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=454 DEFAULT CHARSET=utf8mb4 COMMENT='开票三方支付订单表';

CREATE TABLE `bwc_store_invoice_seller_bill` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `invoice_id` int(11) NOT NULL DEFAULT '0' COMMENT '关联开票记录表',
  `seller_bill_id` int(11) NOT NULL DEFAULT '0' COMMENT '账单表id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_invoice_id` (`invoice_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=572 DEFAULT CHARSET=utf8mb4 COMMENT='开票记录关联账单表';

CREATE TABLE `bwc_store_link` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `tag` varchar(50) NOT NULL DEFAULT '' COMMENT '标签',
  `app_id` varchar(30) NOT NULL DEFAULT '' COMMENT 'appId',
  `original_id` varchar(30) NOT NULL DEFAULT '' COMMENT '原始id',
  `path` varchar(255) NOT NULL DEFAULT '' COMMENT '链接',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作员id',
  `before_data` text NOT NULL COMMENT '修改前数据，json',
  `after_data` text NOT NULL COMMENT '修改后数据，json',
  `operation_ip` varchar(20) NOT NULL COMMENT '操作ip',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=913758 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_relive_switch` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '店铺复活方式：1遵循中间人配置，2独立设置',
  `switch` tinyint(4) NOT NULL DEFAULT '1' COMMENT '独立设置开关：1开，0关',
  `data_state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COMMENT='店铺控制订单是否显示复活按钮';

CREATE TABLE `bwc_store_repo` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `store_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1美团2饿了么',
  `store_category` varchar(30) NOT NULL DEFAULT '' COMMENT '店铺分类',
  `store_id` varchar(50) NOT NULL DEFAULT '' COMMENT '美团或者饿了么店铺id',
  `ele_market_shop_id` varchar(50) NOT NULL DEFAULT '' COMMENT '饿了么商超跳转用的店铺id',
  `mtwm_poi_id` varchar(50) DEFAULT '' COMMENT '美团商家id',
  `wdb_store_id` varchar(50) NOT NULL DEFAULT '' COMMENT 'wdb店铺id',
  `vender_id` varchar(255) NOT NULL DEFAULT '' COMMENT '京东秒送venderId',
  `store_cover` varchar(1500) NOT NULL DEFAULT '' COMMENT '店铺封面',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '商铺地址',
  `store_longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `store_latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `average_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '店铺人均价',
  `delivery_time` int(10) NOT NULL DEFAULT '0' COMMENT '配送时长单位：分钟',
  `start_time` time DEFAULT NULL COMMENT '店铺营业开始时间',
  `end_time` time DEFAULT NULL COMMENT '店铺营业结束时间',
  `service_time` varchar(255) DEFAULT '',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属代理id',
  `area_ad_code` varchar(32) NOT NULL DEFAULT '0' COMMENT '所属区县code',
  `tag` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺标签，不同的标签进店链接不同',
  `link` varchar(255) NOT NULL DEFAULT '' COMMENT '进店链接',
  `ele_link` varchar(255) NOT NULL DEFAULT '' COMMENT '饿了么永久链接',
  `cos_link` varchar(1500) NOT NULL DEFAULT '' COMMENT 'cos链接',
  `store_phone` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺手机号',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注信息',
  `source_type` tinyint(3) NOT NULL DEFAULT '1' COMMENT '店铺来源类型 1 助手端上店; 2 管理后台上店',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_name` (`store_name`) USING BTREE,
  KEY `idx_mtwm_poi_id` (`mtwm_poi_id`) USING BTREE,
  KEY `idx_wdb_id` (`wdb_store_id`) USING BTREE,
  KEY `idx_store_type_id` (`store_type`)
) ENGINE=InnoDB AUTO_INCREMENT=416611 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_repo_ext` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `repo_id` int(11) NOT NULL DEFAULT '0',
  `recommend_goods` text NOT NULL,
  `spu_tags` json DEFAULT NULL COMMENT '上店助手传过来的热门商品json',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_repoId` (`repo_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=50912 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_repo_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `repo_id` int(11) NOT NULL DEFAULT '0' COMMENT '门店库id',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_all` (`store_id`,`repo_id`) USING BTREE,
  KEY `idx_repo_id` (`repo_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=482162 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_store_repo_sign_in` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '管理后台员工id',
  `in_store_name` varchar(100) NOT NULL DEFAULT '' COMMENT '签到的店铺名称',
  `in_address` varchar(100) NOT NULL DEFAULT '' COMMENT '签到的上报地址',
  `in_longitude` varchar(50) NOT NULL DEFAULT '' COMMENT '签到的经度',
  `in_latitude` varchar(50) NOT NULL DEFAULT '' COMMENT '签到的纬度',
  `in_city_code` varchar(50) NOT NULL DEFAULT '' COMMENT '签到的城市编码',
  `in_agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '签到的代理id',
  `in_images` varchar(300) NOT NULL DEFAULT '' COMMENT '签到上传的图片，多个用英文逗号分隔（,）',
  `in_create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '签到时间',
  `out_address` varchar(100) NOT NULL DEFAULT '' COMMENT '签退的上报地址',
  `out_longitude` varchar(50) NOT NULL DEFAULT '' COMMENT '签退的经度',
  `out_latitude` varchar(50) NOT NULL DEFAULT '' COMMENT '签退的纬度',
  `out_city_code` varchar(50) NOT NULL DEFAULT '' COMMENT '签退的城市编码',
  `out_agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '签退的代理id',
  `out_images` varchar(300) NOT NULL DEFAULT '' COMMENT '签退上传的图片，多个用英文逗号分隔（,）',
  `out_remark` varchar(300) NOT NULL DEFAULT '' COMMENT '签退备注',
  `out_create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '签退时间',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态：1未签退，2已完成',
  `data_state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_admin_id` (`admin_id`) USING BTREE,
  KEY `idx_in_create_time` (`in_create_time`) USING BTREE,
  KEY `idx_out_create_time` (`out_create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=596 DEFAULT CHARSET=utf8mb4 COMMENT='员工助手，员工签到签退纪录表';

CREATE TABLE `bwc_store_sale_limit` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `store_id` int(10) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `sale_id` int(10) NOT NULL DEFAULT '0' COMMENT '销售id',
  `limit_day` int(10) NOT NULL DEFAULT '0' COMMENT '未结算天数限制',
  `limit_money` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '未结算金额限制',
  `create_operate_id` int(10) NOT NULL DEFAULT '0' COMMENT '后台创建数据的admin_id',
  `delete_operate_id` int(10) NOT NULL DEFAULT '0' COMMENT '后台删除数据的admin_id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_store_id` (`store_id`,`data_state`) USING BTREE,
  KEY `idx_sale_id` (`sale_id`,`data_state`) USING BTREE,
  KEY `idx_create_time` (`create_time`,`data_state`) USING BTREE,
  KEY `idx_create_operate_id` (`create_operate_id`) USING BTREE,
  KEY `idx_delete_operate_id` (`delete_operate_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=59323 DEFAULT CHARSET=utf8mb4 COMMENT='店铺/销售发布任务的时候的限制';

CREATE TABLE `bwc_store_score` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_id` bigint(20) unsigned NOT NULL COMMENT '店铺ID',
  `verification_rate` decimal(5,4) NOT NULL DEFAULT '0.0000' COMMENT '核销率（近7日，0-1之间）',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_store_id` (`store_id`)
) ENGINE=InnoDB AUTO_INCREMENT=671355 DEFAULT CHARSET=utf8mb4 COMMENT='店铺评分表';

CREATE TABLE `bwc_store_silk` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓bwc_store表id',
  `silk_store_id` int(10) NOT NULL DEFAULT '0' COMMENT '小蚕对应的店铺id',
  `silk_platform_id` int(10) NOT NULL DEFAULT '0' COMMENT '小蚕对应的店铺平台类型',
  `silk_callback_data` json DEFAULT NULL COMMENT '小蚕返回的回调信息',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `idx_silk_store_id` (`silk_store_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=235387 DEFAULT CHARSET=utf8mb4 COMMENT='晓晓活动关联小蚕店铺id';

CREATE TABLE `bwc_store_statistics` (
  `id` int(11) unsigned NOT NULL COMMENT '主键',
  `click_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '点击量',
  `place_order_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单量',
  `completed_order_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单完成量',
  `task_releases_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务发布量',
  `cumulative_task_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '累计任务名额',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_subscribe_mp_wechat_prize` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT '名称',
  `type` tinyint(1) NOT NULL COMMENT '类型，1：系统卡券2：晓晓红包 3：晓晓能量',
  `quantity` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '数量',
  `coupon_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '卡券id，bwc_coupon_template.id',
  `red_envelope_price` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '晓晓红包金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  `created_by` int(11) DEFAULT NULL COMMENT '创建人，bwc_admin.id',
  `updated_by` int(11) DEFAULT NULL COMMENT '更新人，bwc_admin.id',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COMMENT='关注公众号奖励配置表';

CREATE TABLE `bwc_subscribe_mp_wechat_prize_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `openid` varchar(64) NOT NULL DEFAULT '' COMMENT '用户领取时的微信openid',
  `prize_id` int(11) NOT NULL DEFAULT '0' COMMENT '奖励id：bwc_subscribe_mp_wechat_prize.id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29769 DEFAULT CHARSET=utf8mb4 COMMENT='公众号绑定奖励领取记录';

CREATE TABLE `bwc_suggestion` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT 'C端用户id',
  `user_mobile` varchar(40) NOT NULL DEFAULT '' COMMENT '用户真实姓名',
  `type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '类型：1外卖订单，2食品问题，3商家问题，4商家订单，5售后服务，6活动相关，7程序bug，8建议，9其他',
  `suggestion` text NOT NULL COMMENT '投诉/意见/建议',
  `images` varchar(500) NOT NULL DEFAULT '' COMMENT '图片地址',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `app_version` varchar(50) NOT NULL DEFAULT '' COMMENT 'App的版本号',
  `is_deal` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否处理：默认1未处理，2已处理',
  `deal_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '标记处理时间',
  `deal_admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '处理人ID',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  `handle_content` text COMMENT '处理结果',
  `handle_images` varchar(1500) DEFAULT NULL COMMENT '处理截图',
  `follow_content` text COMMENT '跟进结果',
  `follow_images` varchar(1500) DEFAULT NULL COMMENT '跟进截图',
  `is_follow` tinyint(1) NOT NULL DEFAULT '1' COMMENT '跟进状态：1未跟进，2已跟进',
  `follow_admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '跟进人ID',
  `follow_time` timestamp NULL DEFAULT NULL COMMENT '跟进时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14907 DEFAULT CHARSET=utf8mb4 COMMENT='投诉建议表';

CREATE TABLE `bwc_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `show_store_name` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺展示名称',
  `search_keyword` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺搜索关键词',
  `cate_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分类id',
  `cate` varchar(255) NOT NULL DEFAULT '' COMMENT '分类名称',
  `area_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '区域id',
  `area` varchar(255) NOT NULL DEFAULT '' COMMENT '区域名称',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商户ID',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 1美团2饿了么',
  `store_enter_qr` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺的进店二维码',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '地址',
  `store_longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `store_latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广人id',
  `task_total_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务名额',
  `task_applicants_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '已报名人数',
  `task_start_time` datetime DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '报名结束时间',
  `task_tags` varchar(150) NOT NULL DEFAULT '' COMMENT '任务标签，用'',''分隔',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `task_rebate` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返点',
  `rush` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否抢购 1 非抢购 2抢购',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要好评，1图文反馈3文字反馈2无需反馈（兼容以前数据）4无需图文',
  `praise_demand` varchar(20) NOT NULL DEFAULT '3,30' COMMENT '反馈需求 逗号分隔，前面是图片数量，后面是文字数量。is_praise=1时生效',
  `is_machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否自动通过审核',
  `is_settlement` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否结算1是2否',
  `app_exclusive` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT 'app专享 1是2否',
  `new_user_exclusive` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '新用户专享 1是2否',
  `brand_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '大牌id，bwc_brand.id',
  `is_brand` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否大牌 1：是 0：否',
  `is_brand_coupon` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否需要大牌专享卡券：1：是 0：否',
  `brand_coupon_num` int(11) NOT NULL DEFAULT '0' COMMENT '大牌券数量',
  `is_advance` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否允许提前抢单：1：是 0：否',
  `vip_level` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '会员等级',
  `data_state` tinyint(1) unsigned zerofill NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `public_user_registration_interval` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户公共报名间隔(秒)',
  `bill_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '账单状态1未支付 2已支付',
  `settlement_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '任务状态 1进行中 2已关闭',
  `is_pre_pay` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否提前支付：1不是，2是但没付钱，3是且已支付',
  `pre_pay_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '预支付任务状态：1未处理，2已处理，3已作废',
  `pre_pay_method` tinyint(1) NOT NULL DEFAULT '0' COMMENT '提前预支付的方式：4首信易-支付宝，5首信易-微信，6晓晓钱包，8微信小程序',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `data_state` (`data_state`,`task_start_time`,`task_end_time`,`store_name`,`status`,`task_cover`,`task_type`,`store_longitude`,`store_latitude`,`task_total_quota`,`task_applicants_quota`,`is_praise`,`praise_demand`),
  KEY `client` (`task_start_time`,`data_state`,`status`,`store_id`,`store_name`,`task_cover`,`task_type`,`store_longitude`,`store_latitude`,`task_total_quota`,`task_applicants_quota`,`task_end_time`,`meal_price`,`cash_back_amount`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_agent_id_task_start_time` (`agent_id`,`data_state`,`task_start_time`),
  KEY `idx_agent_id` (`agent_id`,`task_end_time`,`task_start_time`,`is_pre_pay`) USING BTREE,
  KEY `idx_store_id` (`store_id`,`agent_id`,`data_state`,`promoter_id`) USING BTREE,
  KEY `idx_promoter_id` (`promoter_id`,`task_start_time`) USING BTREE,
  KEY `data_state_2` (`bill_status`,`is_pre_pay`,`task_applicants_quota`,`seller_id`,`promoter_id`) USING BTREE,
  KEY `idx_brand_id` (`brand_id`),
  KEY `idx_seller_create_time` (`seller_id`,`create_time`),
  KEY `idx_store_create_time` (`store_id`,`create_time`),
  KEY `idx_task_end_time` (`data_state`,`task_end_time`,`task_start_time`,`seller_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=17456013 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_admin_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '代理id',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_task_id` (`task_id`) USING BTREE,
  UNIQUE KEY `idx_task_agent_id` (`task_id`,`agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2109691 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_agent_billing_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `task_log_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务执行记录id',
  `source_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '任务类型 1:运营推送任务、运营短信任务  2:自动任务',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理商id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '类型 1:运营APP推送 2:运营短信 3:自动任务APP推送 4:自动任务短信',
  `amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '扣费金额',
  `task_log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '任务执行时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_task_log` (`is_delete`,`source_type`,`task_log_id`,`agent_id`,`task_log_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15152412 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_app_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_app_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '三方平台id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型 1禁用；2启用',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30331 DEFAULT CHARSET=utf8mb4 COMMENT='第三方对应城市开放表';

CREATE TABLE `bwc_task_app_agent_evaluate` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_app_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '三方平台id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型 1禁用；2启用',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_task_app_id` (`task_app_id`)
) ENGINE=InnoDB AUTO_INCREMENT=26153 DEFAULT CHARSET=utf8mb4 COMMENT='开放平台城市活动反馈配置表';

CREATE TABLE `bwc_task_app_credentials` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户表id',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台名称',
  `username` varchar(50) NOT NULL DEFAULT '' COMMENT '联系人姓名',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `code` varchar(20) NOT NULL DEFAULT '' COMMENT '标识',
  `appid` varchar(50) NOT NULL DEFAULT '' COMMENT 'appId',
  `config` json DEFAULT NULL COMMENT '私有化配置',
  `settlement_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '结算方式，1. 按比例 2. 扣除固定金额 3. 有最大限制金额的扣除利润',
  `commission_rebate_rate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返佣万分比',
  `commission_rebate_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返佣金额',
  `notify_url` varchar(256) NOT NULL DEFAULT '' COMMENT '三方回调地址',
  `deduction_notify_url` varchar(256) NOT NULL DEFAULT '' COMMENT '三方扣款回调通知地址',
  `not_auto_pass_order_notify` varchar(256) NOT NULL DEFAULT '' COMMENT '机审不自动通过订单推送url',
  `private_key` varchar(4096) NOT NULL DEFAULT '' COMMENT '三方私钥',
  `public_key` varchar(4096) NOT NULL DEFAULT '' COMMENT '三方公钥',
  `channel_code` varchar(32) NOT NULL DEFAULT '' COMMENT '渠道编码,涉及订单检测需要开发配置,不要随便修改',
  `secret_key` varchar(128) NOT NULL DEFAULT '' COMMENT '三方SDK密钥',
  `show_brand` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否展示大牌，1是2否',
  `show_high` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否展示高返现，1是2否',
  `show_commission` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否展示高返佣 1是2否',
  `task_delay_sign_up_minute` int(11) NOT NULL DEFAULT '60' COMMENT '默认一个小时,活动报名开始时间延迟时间 例如活动开始时间是8:30 三方可报名时间是9:30',
  `subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '补贴金额',
  `subsidy_agent` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否全部城市补贴 1:全部城市 2:指定城市',
  `can_audit` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否允许我方审核：1可以，2不可以',
  `is_open` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否打开：1打开，0关闭',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COMMENT='App端对接我们任务的第三方信息表';

CREATE TABLE `bwc_task_avg_pre_order_volume_price` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id，bwc_task.id',
  `task_cycle_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '循环任务id，bwc_task_cycle_create.id\n',
  `avg_pre_order_volume_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '平均预存单量价格',
  `data_state` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_task_cycle_id` (`task_cycle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务创建预存单量预设';

CREATE TABLE `bwc_task_cash_back_type` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型：默认按金额返现0，按比例返现1',
  `ratio` int(11) NOT NULL DEFAULT '0' COMMENT '注意这里是，万分比',
  `max_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最高返现金额',
  `service_fee` decimal(10,2) DEFAULT '0.00' COMMENT '城市服务费，对应agent表的sale_release_task_commission_fee和seller_release_task_commission_fee字段值',
  `gross_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '任务的每单毛利',
  `agent_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '差价',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11686 DEFAULT CHARSET=utf8mb4 COMMENT='任务关联表，用来控制任务按固定金额返现还是按比例返现';

CREATE TABLE `bwc_task_create` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `task_id` int(10) NOT NULL DEFAULT '0' COMMENT '任务表id',
  `operate_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '创建来源：1商家，2后台',
  `seller_id` int(10) NOT NULL DEFAULT '0' COMMENT '商家id',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '后台adminId',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16437892 DEFAULT CHARSET=utf8mb4 COMMENT='任务创建记录表';

CREATE TABLE `bwc_task_cycle_create` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `operator_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '发布人id',
  `operation_ip` varchar(20) NOT NULL COMMENT '操作ip',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `search_keyword` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺搜索关键词',
  `cate_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分类id',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广人id',
  `task_total_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务名额',
  `task_start_date` date DEFAULT NULL COMMENT '报名开始日期',
  `task_end_date` date DEFAULT NULL COMMENT '报名结束日期',
  `task_start_time` time DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` time DEFAULT NULL COMMENT '报名结束时间',
  `task_tags` varchar(150) NOT NULL DEFAULT '' COMMENT '任务标签，用'',''分隔',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要反馈，1是2否',
  `praise_demand` varchar(20) NOT NULL DEFAULT '3,30' COMMENT '反馈需求 逗号分隔，前面是图片数量，后面是文字数量。is_praise=1时生效',
  `is_machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否自动通过审核',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '任务状态 1进行中 2已关闭',
  `app_exclusive` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT 'app专享 1是2否',
  `new_user_exclusive` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '新用户专享 1是2否',
  `brand_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '大牌id，bwc_brand.id',
  `is_brand` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否大牌 1：是 0：否',
  `is_brand_coupon` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否需要大牌专享卡券：1：是 0：否',
  `brand_coupon_num` int(11) NOT NULL DEFAULT '0' COMMENT '大牌专享卡券数量',
  `is_advance` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否允许提前抢单：1：是 0：否',
  `vip_level` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '会员等级',
  `user_registration_interval` tinyint(2) NOT NULL DEFAULT '0' COMMENT '复购天数',
  `store_new_user_exclusive` tinyint(1) NOT NULL DEFAULT '2' COMMENT '门店新客专享：1是，2不是',
  `is_designation` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否指定套餐，1是2否',
  `designation` varchar(50) NOT NULL DEFAULT '' COMMENT '套餐名',
  `designation_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '套餐url',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_id` (`store_id`) USING BTREE,
  KEY `store` (`data_state`,`store_id`) USING BTREE,
  KEY `idx_brand_id` (`brand_id`),
  KEY `idx_task_end_date` (`task_end_date`,`task_end_time`) USING BTREE,
  KEY `idx_task_start_date` (`task_start_date`,`task_start_time`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=801553 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_task_cycle_create_everyday` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `cycle_create_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '循环创建任务id',
  `task_date` date DEFAULT NULL COMMENT '任务日期',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id，创建成功时存入',
  `success` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否成功 1是2否',
  `message` varchar(255) NOT NULL DEFAULT '' COMMENT '异常信息',
  `trace` text COMMENT '异常trace',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_date` (`task_date`) USING BTREE,
  KEY `idx_cycle_create_task_id` (`cycle_create_task_id`,`task_id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=9177368 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_task_cycle_create_ext` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cycle_create_task_id` int(11) NOT NULL DEFAULT '0',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型：默认按金额返现0，按比例返现1',
  `ratio` int(11) NOT NULL DEFAULT '0' COMMENT '注意这里是，万分比',
  `max_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最高返现金额',
  `task_commission_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '活动服务费，管理后台填写的值',
  `gross_profit` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '任务的每单毛利',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_cyc_task_id` (`cycle_create_task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=453 DEFAULT CHARSET=utf8mb4 COMMENT='任务关联表，用来控制任务按固定金额返现还是按比例返现';

CREATE TABLE `bwc_task_cycle_create_pre` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `is_pre_pay` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否提前支付：1不是，2是但没付钱，3是且已支付',
  `pre_pay_status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '预支付任务状态：1未处理，2已处理，3已作废',
  `pre_pay_method` tinyint(4) NOT NULL DEFAULT '0' COMMENT '提前预支付的方式：4首信易-支付宝，5首信易-微信，6晓晓钱包',
  `data_state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=801092 DEFAULT CHARSET=utf8mb4 COMMENT='循环发布任务预支付表';

CREATE TABLE `bwc_task_cycle_pre_order_volume_everyday` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `cycle_create_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '循环创建任务id',
  `task_date` date DEFAULT NULL COMMENT '任务日期',
  `seller_pre_order_volume_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_seller_pre_order_volume.id\n',
  `seller_pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_cycle_time_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_cycle_create_id` int(11) unsigned NOT NULL COMMENT 'bwc_task_cycle_create.id',
  `task_start_time` datetime NOT NULL COMMENT '活动开始时间',
  `task_end_time` datetime NOT NULL COMMENT '活动结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_task_cycle_create_id` (`task_cycle_create_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1111 DEFAULT CHARSET=utf8mb4 COMMENT='循环发布任务时间段表';

CREATE TABLE `bwc_task_dynamic_adjust_price_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `before_new_user_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '新用户调整前',
  `current_new_user_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '新用户当前',
  `before_old_user_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '老用户调整前',
  `current_old_user_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '老用户当前',
  `diff_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '调整额',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '补贴类型：1单活动补贴；2动态补贴；3竞对补贴',
  `adjust_way` tinyint(3) NOT NULL DEFAULT '0' COMMENT '调整方式，同代理',
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '管理员id，-1系统调整;',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_extra` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_task 表id',
  `cooperation_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '合作类型：1信息推广服务模式，2品牌推广服务模式（服务费总额增加 6%），3品牌推广服务模式（用户承担 1 元），4品牌推广服务模式（0 成本）',
  `contract_party` tinyint(1) NOT NULL COMMENT '签约主体：1杭州晓晓惠点餐信息技术有限公司',
  `data_state` tinyint(1) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=605201 DEFAULT CHARSET=utf8mb4 COMMENT='任务额外收取的费用';

CREATE TABLE `bwc_task_false_data` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `show_store_name` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺展示名称',
  `search_keyword` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺搜索关键词',
  `cate_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分类id',
  `cate` varchar(255) NOT NULL DEFAULT '' COMMENT '分类名称',
  `area_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '区域id',
  `area` varchar(255) NOT NULL DEFAULT '' COMMENT '区域名称',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商户ID',
  `task_cover` varchar(255) NOT NULL DEFAULT '' COMMENT '任务封面',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 1美团2饿了么',
  `store_enter_qr` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺的进店二维码',
  `store_address` varchar(255) NOT NULL DEFAULT '' COMMENT '地址',
  `store_longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `store_latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广人id',
  `task_total_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务名额',
  `task_applicants_quota` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '已报名人数',
  `task_start_time` datetime DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '报名结束时间',
  `task_tags` varchar(150) NOT NULL DEFAULT '' COMMENT '任务标签，用'',''分隔',
  `meal_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '餐标',
  `cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '返现价格',
  `task_receipt_price` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '接单价格',
  `task_rebate` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返点',
  `rush` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否抢购 1 非抢购 2抢购',
  `is_praise` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否需要好评，1图文反馈3文字反馈2无需反馈（兼容以前数据）4无需图文',
  `praise_demand` varchar(20) NOT NULL DEFAULT '3,30' COMMENT '反馈需求 逗号分隔，前面是图片数量，后面是文字数量。is_praise=1时生效',
  `is_machine_audit` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '是否自动通过审核',
  `is_settlement` tinyint(1) NOT NULL DEFAULT '2' COMMENT '是否结算1是2否',
  `app_exclusive` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT 'app专享 1是2否',
  `new_user_exclusive` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '新用户专享 1是2否',
  `brand_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '大牌id，bwc_brand.id',
  `is_brand` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否大牌 1：是 0：否',
  `is_brand_coupon` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否需要大牌专享卡券：1：是 0：否',
  `brand_coupon_num` int(11) NOT NULL DEFAULT '0' COMMENT '大牌券数量',
  `is_advance` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否允许提前抢单：1：是 0：否',
  `vip_level` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '会员等级',
  `data_state` tinyint(1) unsigned zerofill NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `public_user_registration_interval` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户公共报名间隔(秒)',
  `bill_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '账单状态1未支付 2已支付',
  `settlement_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '结算金额',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '任务状态 1进行中 2已关闭',
  `is_pre_pay` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否提前支付：1不是，2是但没付钱，3是且已支付',
  `pre_pay_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '预支付任务状态：1未处理，2已处理，3已作废',
  `pre_pay_method` tinyint(1) NOT NULL DEFAULT '0' COMMENT '提前预支付的方式：4首信易-支付宝，5首信易-微信，6晓晓钱包，8微信小程序',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COMMENT='任务记录-假数据表';

CREATE TABLE `bwc_task_group_buy` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `is_designation` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '是否指定套餐，1是2否',
  `designation` varchar(50) NOT NULL DEFAULT '' COMMENT '套餐名',
  `designation_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '套餐url',
  `dy_designation_params` varchar(4500) NOT NULL DEFAULT '' COMMENT '抖音转链参数',
  `data_state` tinyint(1) unsigned DEFAULT '0' COMMENT '数据状态0删除1正常',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6043314 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_task_pre_order_volume` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `seller_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '商家id，bwc_seller.id',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id，bwc_store.id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id，bwc_task.id',
  `task_cycle_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '循环任务id，bwc_task_cycle_create.id\n',
  `pre_order_volume` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '使用的预存单量',
  `service_fee` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '每单服务费',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_seller_id` (`seller_id`),
  KEY `idx_store_id` (`store_id`),
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_task_cycle_id` (`task_cycle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务创建预存单量预设';

CREATE TABLE `bwc_task_ratio` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `ratio` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务排序计算的比例',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5821412 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作员id',
  `before_data` text NOT NULL COMMENT '修改前数据，json',
  `after_data` text NOT NULL COMMENT '修改后数据，json',
  `operation_ip` varchar(20) NOT NULL COMMENT '操作ip',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `task_id` (`task_id`),
  KEY `admin_id` (`admin_id`),
  KEY `create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=15474779 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_registration_interval` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `task_id` int(10) NOT NULL COMMENT '任务id',
  `user_registration_interval` int(10) NOT NULL DEFAULT '0' COMMENT '复购天数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11237080 DEFAULT CHARSET=utf8mb4 COMMENT='任务表关联复购天数';

CREATE TABLE `bwc_task_silk` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓bwc_task表id',
  `silk_task_id` int(10) NOT NULL DEFAULT '0' COMMENT '小蚕对应的活动id',
  `silk_callback_data` json DEFAULT NULL COMMENT '小蚕返回的回调信息',
  `silk_task_payment_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '支付状态：0=无，1=未支付，2=已支付（对应 PromotionPayStatus 枚举）',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_silk_task_id` (`silk_task_id`) USING BTREE,
  KEY `idx_silk_task_payment_status` (`silk_task_payment_status`)
) ENGINE=InnoDB AUTO_INCREMENT=994657 DEFAULT CHARSET=utf8mb4 COMMENT='晓晓活动关联小蚕活动id';

CREATE TABLE `bwc_task_silk_repurchase` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓任务表id',
  `silk_task_id` int(11) NOT NULL DEFAULT '0' COMMENT '小蚕任务表id',
  `is_repurchase` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否复购：0不是复购活动，1是复购活动',
  `data_state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_silk_task_id` (`silk_task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=361584 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_task_sqs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0',
  `sqs_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '神抢手任务状态 0关闭; 1开启',
  `meal_name` varchar(255) NOT NULL DEFAULT '' COMMENT '套餐名称',
  `meal_link` varchar(255) NOT NULL DEFAULT '' COMMENT '套餐链接',
  `redirect_link` text COMMENT '跳转链接，json格式',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1177 DEFAULT CHARSET=utf8mb4 COMMENT='神抢手任务关联表';

CREATE TABLE `bwc_task_sqs_cycle_create` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cycle_create_task_id` int(11) NOT NULL DEFAULT '0',
  `sqs_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '启用状态 0关闭; 1开启',
  `meal_name` varchar(255) NOT NULL DEFAULT '' COMMENT '神抢手套餐名称',
  `meal_link` varchar(255) NOT NULL DEFAULT '' COMMENT '神抢手套餐链接',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_cyc_task_id` (`cycle_create_task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4 COMMENT='神抢手任务关联表';

CREATE TABLE `bwc_task_store_user_limit` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(10) NOT NULL DEFAULT '0' COMMENT '任务id',
  `store_user_limit` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否限制门店新用户下单：1限制，2不限制',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8932218 DEFAULT CHARSET=utf8mb4 COMMENT='任务关联门线新用户下单专享限制表';

CREATE TABLE `bwc_task_subsidy` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务表id',
  `new_user_subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '新用户补贴金额',
  `old_user_subsidy_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '老用户补贴金额',
  `dynamic_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '动态调整的金额',
  `jp_dynamic_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '竞对补贴',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9902 DEFAULT CHARSET=utf8mb4 COMMENT='关联任务表，单独设置每个任务的补贴金额';

CREATE TABLE `bwc_task_time_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_id` int(11) unsigned NOT NULL COMMENT 'bwc_task.id',
  `task_start_time` datetime NOT NULL COMMENT '活动开始时间',
  `task_end_time` datetime NOT NULL COMMENT '活动结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18903 DEFAULT CHARSET=utf8mb4 COMMENT='任务时间段表';

CREATE TABLE `bwc_task_views` (
  `id` int(11) unsigned NOT NULL COMMENT '主键',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型 1美团2饿了么',
  `promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广人id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理id',
  `home_page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '主页展示量',
  `page_views` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '浏览量',
  `browsing_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '浏览用户量',
  `registered_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数量',
  `registered_users_number` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户量',
  `task_start_time` datetime DEFAULT NULL COMMENT '报名开始时间',
  `task_end_time` datetime DEFAULT NULL COMMENT '报名结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_agent_id` (`agent_id`,`data_state`,`task_start_time`),
  KEY `idx_store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_third_blacklist` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `mobile` varchar(64) NOT NULL DEFAULT '' COMMENT '用户唯一标识',
  `appid` varchar(64) NOT NULL DEFAULT '' COMMENT '三方appid',
  `reason` varchar(256) NOT NULL DEFAULT '' COMMENT '拉黑原因',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_mobile` (`mobile`,`is_delete`),
  KEY `idx_app_mobile` (`appid`,`mobile`,`is_delete`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='三方平台拉黑表';

CREATE TABLE `bwc_third_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `identifier` varchar(128) NOT NULL DEFAULT '' COMMENT '唯一标识',
  `appid` varchar(50) NOT NULL DEFAULT '' COMMENT '第三方appid',
  `restricted` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否受限，1只能看无需好评',
  `is_black` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否拉黑 0否；1是',
  `is_high_quality` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否是好省优质用户 0:否 1:是',
  `is_blacklist` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否是好省黑名单用户 0:否 1:是',
  `operator_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`,`appid`)
) ENGINE=InnoDB AUTO_INCREMENT=912493 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_ticket` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `ticket_no` varchar(50) NOT NULL DEFAULT '' COMMENT '工单编号',
  `type` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单类型，关联工单类型表，可配置',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '工单状态，1待处理，2处理中，3已关闭，4已结单',
  `transfer` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否转派，1已转派，其他未转派',
  `remind_reply` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '提醒回复：0无提醒，1提醒提单人，2提醒处理人，3提醒结单',
  `close_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '关闭原因',
  `submitter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '提单人id',
  `current_handler_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '当前受理人',
  `store_name` varchar(50) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `store_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '店铺id',
  `task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `content` varchar(255) NOT NULL DEFAULT '' COMMENT '描述',
  `deduction_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `refund_amount` decimal(10,2) unsigned DEFAULT '0.00' COMMENT '商家退款',
  `alipay_name` varchar(50) DEFAULT '' COMMENT '商家支付宝姓名',
  `alipay_account` varchar(50) DEFAULT '' COMMENT '商家支付宝账号',
  `has_timed_out` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否超时，1是，其他否',
  `designated_handler_role` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '指定处理角色id',
  `submission_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '提单时间',
  `acceptance_time` timestamp NULL DEFAULT NULL COMMENT '受理时间',
  `finished_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `last_finished_time` timestamp NULL DEFAULT NULL COMMENT '最后一次完成时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_create_time` (`create_time`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_order_id` (`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=162658 DEFAULT CHARSET=utf8mb4 COMMENT='工单';

CREATE TABLE `bwc_ticket_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单城市',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17765 DEFAULT CHARSET=utf8mb4 COMMENT='工单城市表';

CREATE TABLE `bwc_ticket_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(255) NOT NULL DEFAULT '' COMMENT '配置名称',
  `key` varchar(255) NOT NULL DEFAULT '' COMMENT '配置key',
  `value` longtext NOT NULL COMMENT '配置value',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='工单配置表';

CREATE TABLE `bwc_ticket_disabled_role` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `role_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '禁止处理工单角色',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1036 DEFAULT CHARSET=utf8mb4 COMMENT='工单处理禁用角色表';

CREATE TABLE `bwc_ticket_handle_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `designated_handler_role` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作后指定受理角色',
  `handler_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '操作人',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '类型：1. 发起工单 2. 工单受理，3. 工单转派， 4. 工单结单，5. 工单关闭，6. 工单重新发起',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '操作备注',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `type` (`type`),
  KEY `idx_handler_id` (`ticket_id`,`handler_id`,`type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=702333 DEFAULT CHARSET=utf8mb4 COMMENT='工单处理记录表';

CREATE TABLE `bwc_ticket_image` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '关联类型：1. 关联工单，2. 关联工单流程',
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `ticket_tracking_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单流程id',
  `images_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '图片url',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=178653 DEFAULT CHARSET=utf8mb4 COMMENT='工单图片';

CREATE TABLE `bwc_ticket_order_resolution_method` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '关联类型：1. 关联工单，2. 关联工单流程',
  `resolution_method` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '新订单处理方案：0:已取消 1:无需取消 2:部分扣款 3:个人承担 4:公司承担 5:门店拉黑 6:已追回 7:未追回 8:负积分',
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `ticket_tracking_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单流程id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `ticket_tracking_id` (`ticket_tracking_id`),
  KEY `ticket_id` (`ticket_id`) USING BTREE,
  KEY `resolution_method` (`resolution_method`)
) ENGINE=InnoDB AUTO_INCREMENT=735623 DEFAULT CHARSET=utf8mb4 COMMENT='订单处理方案';

CREATE TABLE `bwc_ticket_order_resolution_method_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '类型名称',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '类型：1表示后台用的订单类型',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COMMENT='工单的订单类型：订单解决方法';

CREATE TABLE `bwc_ticket_refund_amount` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `ticket_tracking_id` int(11) NOT NULL COMMENT '工单跟进信息表id',
  `seller_id` int(11) NOT NULL DEFAULT '0' COMMENT '商家id',
  `seller_name` varchar(50) NOT NULL DEFAULT '' COMMENT '商家名称',
  `store_id` int(11) NOT NULL DEFAULT '0' COMMENT '店铺id',
  `store_name` varchar(80) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `task_id` int(11) NOT NULL DEFAULT '0' COMMENT '任务id',
  `task_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '任务活动时间',
  `order_id` int(11) NOT NULL DEFAULT '0' COMMENT '订单id',
  `agent_id` int(11) NOT NULL COMMENT '代理城市id',
  `refund_amount` decimal(10,2) NOT NULL COMMENT '退款金额',
  `alipay_name` varchar(50) NOT NULL DEFAULT '' COMMENT '支付宝姓名',
  `alipay_account` varchar(80) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `pay_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '打款状态：1打款中，2打款成功，3打款失败',
  `pay_desc` text COMMENT '打款描述',
  `pay_no` varchar(80) NOT NULL DEFAULT '' COMMENT '打款流水号',
  `pay_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '支付时间',
  `operator_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16625 DEFAULT CHARSET=utf8mb4 COMMENT='工单退款表';

CREATE TABLE `bwc_ticket_resolution_method` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '关联类型：1. 关联工单，2. 关联工单流程',
  `resolution_method` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '用户处理方案：0未处理，1禁用，2拉黑支付宝，3限制，4其它，5账号无需处理',
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `ticket_tracking_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单流程id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `ticket_tracking_id` (`ticket_tracking_id`),
  KEY `ticket_id` (`ticket_id`) USING BTREE,
  KEY `resolution_method` (`resolution_method`)
) ENGINE=InnoDB AUTO_INCREMENT=431389 DEFAULT CHARSET=utf8mb4 COMMENT='用户处理方案';

CREATE TABLE `bwc_ticket_tracking` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '提交类型：1提单人，2受理人，3系统信息，4修改工单，5工单提醒补充，6工单退款',
  `title` varchar(30) NOT NULL DEFAULT '' COMMENT '标题',
  `content` varchar(255) NOT NULL DEFAULT '' COMMENT '信息内容',
  `admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '回复人id，如果是系统信息，则为0',
  `deduction_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '扣款金额',
  `refund_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '商家退款',
  `refund_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '退款状态：1退款中，2退款成功，3退款失败',
  `alipay_name` varchar(50) DEFAULT '' COMMENT '商家支付宝姓名',
  `alipay_account` varchar(50) DEFAULT '' COMMENT '商家支付宝账号',
  `refund_desc` text COMMENT '退款失败原因',
  `ticket_type_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单类型id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_ticket_id` (`ticket_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=951049 DEFAULT CHARSET=utf8mb4 COMMENT='工单追踪表';

CREATE TABLE `bwc_ticket_type` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(255) DEFAULT NULL,
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COMMENT='工单类型';

CREATE TABLE `bwc_ticket_video` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '关联类型：1. 关联工单，2. 关联工单流程',
  `ticket_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单id',
  `ticket_tracking_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '工单流程id',
  `video_url` varchar(1500) NOT NULL DEFAULT '' COMMENT '视频url',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_ticket_id` (`ticket_id`),
  KEY `idx_ ticket_tracking_id` (`ticket_tracking_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1410 DEFAULT CHARSET=utf8mb4 COMMENT='工单视频';

CREATE TABLE `bwc_urban_activity` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(15) NOT NULL DEFAULT '' COMMENT '活动名称',
  `invite_group_type` int(1) unsigned NOT NULL DEFAULT '1' COMMENT '邀请进群链接类型 1. url、2. img',
  `invite_group_entry_link` varchar(1500) NOT NULL DEFAULT '' COMMENT '邀请进群链接',
  `sign_up_group_type` int(1) unsigned NOT NULL DEFAULT '1' COMMENT '报名进群链接类型 1. url、2. img',
  `sign_up_group_entry_link` varchar(1500) NOT NULL DEFAULT '' COMMENT '报名进群链接',
  `start_date` date DEFAULT NULL COMMENT '开始时间',
  `end_date` date DEFAULT NULL COMMENT '结束时间',
  `share_bg_img` varchar(1500) NOT NULL DEFAULT '' COMMENT '分享背景图URL',
  `share_bg_position` varchar(1500) NOT NULL DEFAULT '' COMMENT '分享背景图位置信息(json)',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1. 生效  2. 暂停',
  `share_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享人数',
  `register_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册人数',
  `cash_back_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现人数',
  `sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单人数',
  `order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单收益人数',
  `challenge_sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名挑战下单人数',
  `challenge_order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '挑战下单收益人数',
  `visits` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '访问量',
  `clicks_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '点击量',
  `sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名人数',
  `finish_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成人数',
  `sign_up_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数',
  `finish_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成数',
  `finish_rate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成率（万分比）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=68 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_agent` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `start_date` date DEFAULT NULL COMMENT '开始时间',
  `end_date` date DEFAULT NULL COMMENT '结束时间',
  `share_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享人数',
  `register_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册人数',
  `cash_back_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现人数',
  `sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单人数',
  `order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单收益人数',
  `challenge_sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名挑战下单人数',
  `challenge_order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '挑战下单收益人数',
  `visits` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '访问量',
  `clicks_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '点击量',
  `sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名人数',
  `finish_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成人数',
  `sign_up_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数',
  `finish_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成数',
  `finish_rate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成率（万分比）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4120 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_click` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户id',
  `click_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '点击次数',
  `click_date` date DEFAULT NULL COMMENT '点击日期',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `click_date` (`click_date`,`activity_agent_id`,`user_id`,`click_num`),
  KEY `idx_user_id` (`user_id`,`activity_agent_id`,`data_state`)
) ENGINE=InnoDB AUTO_INCREMENT=518539 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_daily_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `agent_name` varchar(50) NOT NULL DEFAULT '' COMMENT '城市名称',
  `date` date DEFAULT NULL COMMENT '日期',
  `share_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享数',
  `share_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享人数',
  `register_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册人数',
  `cash_back_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现人数',
  `order_sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单数',
  `order_sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单人数',
  `order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单收益人数',
  `challenge_sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名挑战下单数',
  `challenge_sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名挑战下单人数',
  `challenge_order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '挑战下单收益人数',
  `visits` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '访问量',
  `clicks_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '点击量',
  `sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名人数',
  `finish_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成人数',
  `sign_up_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数',
  `finish_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `date` (`date`,`activity_agent_id`),
  KEY `date_2` (`date`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27243 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_finished` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动任务id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '活动类型 1. 邀请 2. 下单数量 3. 下单挑战',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `reward_amount` decimal(10,2) NOT NULL COMMENT '奖励金额（金币）',
  `sign_up_date` date DEFAULT NULL COMMENT '活动报名日期',
  `finish_date` date DEFAULT NULL COMMENT '完成日期',
  `finished_time` datetime DEFAULT NULL COMMENT '完成时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`) USING BTREE,
  KEY `activity_id` (`activity_id`) USING BTREE,
  KEY `activity_task_id` (`activity_task_id`) USING BTREE,
  KEY `activity_agent_id` (`activity_agent_id`) USING BTREE,
  KEY `order_id` (`order_id`),
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `finished_date` (`finish_date`,`activity_agent_id`,`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=93824 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_invite_user_register` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `sign_up_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名id',
  `activity_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动任务id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `activity_user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动用户id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册用户id',
  `sign_up_date` date DEFAULT NULL COMMENT '活动报名日期',
  `register_date` date DEFAULT NULL COMMENT '注册日期',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1. 未完成 2. 已完成（这里只有为邀请人提升了进度才会标记已完成）',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`),
  KEY `agent_id` (`agent_id`),
  KEY `activity_agent_id` (`register_date`,`activity_agent_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=23442 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动任务id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `activity_sign_up_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动报名id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '活动类型 1. 邀请 2. 下单数量 3. 下单挑战',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单用户id',
  `activity_user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1. 已参与，2. 已完成，3. 已撤销',
  `finish_time` timestamp NULL DEFAULT NULL COMMENT '完成时间',
  `order_date` date DEFAULT NULL COMMENT '下单日期',
  `finish_date` date DEFAULT NULL COMMENT '完成日期',
  `order_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单来源 0:霸王餐订单 1:砍价捡漏订单',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`) USING BTREE,
  KEY `activity_id` (`activity_id`) USING BTREE,
  KEY `activity_task_id` (`activity_task_id`) USING BTREE,
  KEY `activity_agent_id` (`activity_agent_id`) USING BTREE,
  KEY `user_id` (`user_id`),
  KEY `order_id` (`order_id`),
  KEY `order_date` (`order_date`)
) ENGINE=InnoDB AUTO_INCREMENT=1330730 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_platform` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '子任务id',
  `platform_group` varchar(20) NOT NULL DEFAULT '' COMMENT '平台组',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`),
  KEY `activity_task_id` (`activity_task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COMMENT='活动平台组表';

CREATE TABLE `bwc_urban_activity_red_envelopes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动ID',
  `amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `end_time` datetime DEFAULT NULL COMMENT '红包结束时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_remind` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `switch_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:关闭 1:开启',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`) USING BTREE,
  KEY `idx_switch` (`switch_status`)
) ENGINE=InnoDB AUTO_INCREMENT=7223 DEFAULT CHARSET=utf8mb4 COMMENT='城市挑战赛下单提醒';

CREATE TABLE `bwc_urban_activity_sign_up` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动任务id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '活动类型 1. 邀请 2. 下单数量 3. 下单挑战',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名用户id',
  `target_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务目标数量',
  `current_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '当前任务进度',
  `duration_days` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务时长',
  `reward_amount` decimal(10,2) NOT NULL COMMENT '奖励金额（金币）',
  `sign_up_time` datetime DEFAULT NULL COMMENT '报名时间',
  `sign_up_date` date DEFAULT NULL COMMENT '报名日期',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1正常; 2禁用; 3放弃; 4完成',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `activity_id` (`activity_id`),
  KEY `activity_task_id` (`activity_task_id`),
  KEY `activity_agent_id` (`activity_agent_id`),
  KEY `user_id` (`user_id`),
  KEY `sign_up_date` (`sign_up_date`,`activity_agent_id`,`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=328012 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `title` varchar(15) NOT NULL DEFAULT '' COMMENT '活动标题',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '活动类型 1. 邀请 2. 下单数量 3. 下单挑战',
  `target_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '目标订单数量',
  `duration_days` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务时长',
  `reward_amount` decimal(10,2) NOT NULL COMMENT '奖励金额（金币）',
  `circular` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否循环报名，1是 其他否',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `activity_id` (`activity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=173 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_urban_activity_task_daily_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `activity_agent_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '城市活动id',
  `activity_task_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动子任务id',
  `daily_record_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '每日记录ID',
  `agent_name` varchar(50) NOT NULL DEFAULT '' COMMENT '城市名称',
  `date` date DEFAULT NULL COMMENT '日期',
  `share_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享数',
  `share_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分享人数',
  `register_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册人数',
  `cash_back_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '返现人数',
  `order_sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单数',
  `order_sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名下单人数',
  `order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '下单收益人数',
  `challenge_sign_up_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名挑战下单数',
  `challenge_sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名挑战下单人数',
  `challenge_order_revenue_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '挑战下单收益人数',
  `sign_up_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名人数',
  `finish_people_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成人数',
  `sign_up_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '报名数',
  `finish_total` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '完成数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `date` (`date`,`activity_agent_id`,`activity_task_id`) USING BTREE,
  KEY `date_2` (`date`) USING BTREE,
  KEY `activity_id` (`activity_id`) USING BTREE,
  KEY `daily_record_id` (`daily_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=54244 DEFAULT CHARSET=utf8mb4 COMMENT='每日记录子任务记录表';

CREATE TABLE `bwc_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `password` varchar(32) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '密码',
  `salt` varchar(4) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '密码盐',
  `user_nick` varchar(30) NOT NULL DEFAULT '' COMMENT '用户昵称',
  `user_avatar` varchar(1500) NOT NULL DEFAULT '' COMMENT '用户头像',
  `wechat_nick` varchar(100) NOT NULL DEFAULT '' COMMENT '用户微信昵称',
  `wechat_avatar` varchar(1500) NOT NULL DEFAULT '' COMMENT '用户微信头像',
  `user_session_key` varchar(255) NOT NULL DEFAULT '' COMMENT '微信小程序解密签名',
  `user_applet_open_id` varchar(255) NOT NULL DEFAULT '' COMMENT '用户微信小程序openid',
  `user_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `user_open_id` varchar(255) NOT NULL DEFAULT '' COMMENT '用户微信公众号openid',
  `user_unionid` varchar(255) NOT NULL DEFAULT '' COMMENT '微信授权唯一平台id',
  `user_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户积分',
  `user_gold` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户金币',
  `total_cash_back_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '累计返现金额',
  `total_rebate_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '累计推广奖励金额',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备id',
  `user_device_registration_id` varchar(60) NOT NULL DEFAULT '' COMMENT '极光推送的registration_id',
  `user_collection_qr_code` varchar(255) NOT NULL DEFAULT '' COMMENT '用户收款码',
  `user_promoter_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '推广员id',
  `user_promotion_code` varchar(255) NOT NULL DEFAULT '' COMMENT '推广码',
  `channel_promotion_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '渠道推广id',
  `user_promotion_qr_code` varchar(255) NOT NULL DEFAULT '' COMMENT '推广二位码',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `identity_card_id` int(10) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表',
  `user_login_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户上次登陆时间',
  `user_login_ip` varchar(20) NOT NULL DEFAULT '' COMMENT '用户上次登陆ip',
  `user_login_client` varchar(20) NOT NULL DEFAULT '' COMMENT '用户上次登陆设备 platform',
  `user_last_sign_up_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户上次下单时间',
  `user_first_sign_up_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户首次下单时间',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '用户状态0正常1禁用',
  `disable_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '禁用原因',
  `black_reason` varchar(255) NOT NULL DEFAULT '' COMMENT '拉黑原因',
  `app_order_reward` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '获取APP首单奖励 1. 可以获取  2无法获取',
  `first_register` tinyint(1) unsigned DEFAULT '1' COMMENT '是否首次注册，1是2否',
  `restricted` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '受限用户 1是2否',
  `restricted_distance` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否限制下单距离：1是，2否',
  `restricted_order_num` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否限制下单频率：1是，2否',
  `whitelist` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否是超级白名单用户：1不是，2是（可以不限制当日报名4次）',
  `distance_whitelist` tinyint(1) NOT NULL DEFAULT '1' COMMENT '下单距离限制：1限制查看50公里内的店铺，2不限制距离',
  `is_match_alipay_name` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否匹配自动拉黑规则里面的支付宝姓名拉黑：1是，2否',
  `is_match_lin_ping` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否匹配拉黑规则里面的临平团伙拉黑：1是，2否',
  `order_num` int(10) NOT NULL DEFAULT '0' COMMENT '用户的有效单量',
  `first_order_time` timestamp NULL DEFAULT NULL COMMENT '首单完成时间戳',
  `first_agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '首次下单的代理区域',
  `last_agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '上一次下单的代理区域',
  `rebate_effective_order_num` int(10) NOT NULL DEFAULT '0' COMMENT '邀请奖励有效单量，如果用户支付宝没填写，邀请奖励是0.01，单量不+1',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `gender` tinyint(1) DEFAULT '0' COMMENT '性别 0:保密 1:男  2:女',
  `energy_value` int(11) NOT NULL DEFAULT '0' COMMENT '用户能量值',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `general_num` int(10) NOT NULL DEFAULT '0' COMMENT '用户通用活动有效单量',
  `repurchase_card_num` int(10) NOT NULL DEFAULT '0' COMMENT '用户复购卡活动有效单量',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `user_mobile` (`user_mobile`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_user_alipay_account` (`user_alipay_account`) USING BTREE,
  KEY `idex_user_promoter_id` (`user_promoter_id`),
  KEY `user_nick` (`user_nick`) USING BTREE,
  KEY `idx_user_unionid` (`user_unionid`,`data_state`),
  KEY `idx_user_device_registration_id` (`user_device_registration_id`) USING BTREE,
  KEY `idx_first_agent_id` (`first_agent_id`,`order_num`) USING BTREE,
  KEY `idx_user_alipay_name` (`user_alipay_name`) USING BTREE,
  KEY `idx_user_device_cid` (`user_device_cid`,`data_state`) USING BTREE,
  KEY `idx_channel_promotion_id` (`channel_promotion_id`) USING BTREE,
  KEY `idx_identity_card_id` (`identity_card_id`) USING BTREE,
  KEY `idx_last_agent_id` (`last_agent_id`,`data_state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2782348 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_address_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) NOT NULL COMMENT '地址名称',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '详细地址',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id，bwc_user.id',
  `longitude` varchar(20) NOT NULL COMMENT '经度',
  `latitude` varchar(20) NOT NULL COMMENT '纬度',
  `city` varchar(255) NOT NULL COMMENT '城市',
  `ad_code` varchar(255) NOT NULL DEFAULT '' COMMENT '区编码',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_update_time` (`user_id`,`update_time`)
) ENGINE=InnoDB AUTO_INCREMENT=1778572 DEFAULT CHARSET=utf8mb4 COMMENT='用户历史地址表';

CREATE TABLE `bwc_user_agent` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户表id',
  `agent_id` int(10) NOT NULL DEFAULT '0' COMMENT '代理区域',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_data` (`data_state`,`agent_id`,`user_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`,`data_state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2116644 DEFAULT CHARSET=utf8mb4 COMMENT='用户和城市的关联关系，在哪个城市下单就记录';

CREATE TABLE `bwc_user_all_amount_cash` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `sign_up_time` datetime DEFAULT NULL COMMENT '报名时间',
  `expiration_time` datetime DEFAULT NULL COMMENT '截止时间',
  `max_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '最大返还金额',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态：0. 进行中; 1. 已完成; 2. 已过期',
  `red_envelope_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返还的红包金额',
  `type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '活动类型 1:老版本全额返 2:新版本全额返',
  `activity_order_finish_num` tinyint(2) NOT NULL DEFAULT '1' COMMENT '活动完成订单数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `order_id` (`order_id`),
  KEY `idx_sign_up_time` (`sign_up_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=383504 DEFAULT CHARSET=utf8mb4 COMMENT='首单全额返';

CREATE TABLE `bwc_user_all_amount_cash_finished_order` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`,`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=129336 DEFAULT CHARSET=utf8mb4 COMMENT='首单全额返关联已完成订单表';

CREATE TABLE `bwc_user_all_amount_cash_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `sign_up_time` datetime DEFAULT NULL COMMENT '报名时间',
  `max_amount` decimal(10,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '最大返还金额',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态：0. 进行中; 1. 已完成;',
  `red_envelope_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '返还的红包金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`,`order_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=126737 DEFAULT CHARSET=utf8mb4 COMMENT='首单全额返关联订单表';

CREATE TABLE `bwc_user_amount_snapshot` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `snapshot_date` date NOT NULL COMMENT '快照日期',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_user主键id',
  `user_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `user_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户积分',
  `user_gold` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户金币',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_snapshot_date` (`user_id`,`snapshot_date`) USING BTREE,
  KEY `idx_mobile` (`user_mobile`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=156554268 DEFAULT CHARSET=utf8mb4 COMMENT='用户积分余额,用户金币余额快照';

CREATE TABLE `bwc_user_blacklist_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作员对应的admin表id',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '后台被操作人id',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '操作类型：1拉黑支付宝，2解封支付宝，3拉黑微信，4解封微信',
  `reason` varchar(300) NOT NULL DEFAULT '' COMMENT '操作信息',
  `data` json NOT NULL COMMENT '数据json',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_admin_id` (`admin_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=25177 DEFAULT CHARSET=utf8mb4 COMMENT='用户相关拉黑日志表';

CREATE TABLE `bwc_user_category_tag_disable` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL COMMENT '用户id',
  `category_tag_id` int(11) unsigned NOT NULL COMMENT '品类标签id:bwc_category_tag.id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_category_tag_id` (`category_tag_id`),
  KEY `idx_store_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7593 DEFAULT CHARSET=utf8mb4 COMMENT='用户与标签屏蔽表';

CREATE TABLE `bwc_user_category_tag_relation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL COMMENT '用户id',
  `category_tag_id` int(11) unsigned NOT NULL COMMENT '品类标签id:bwc_category_tag.id',
  `order_number` int(11) NOT NULL DEFAULT '0' COMMENT '下单次数(下单+1)',
  `finish_number` int(11) NOT NULL DEFAULT '0' COMMENT '完成次数(完成订单就+1)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key_user_category_tag` (`user_id`,`category_tag_id`),
  KEY `idx_category_tag_id` (`category_tag_id`),
  KEY `idx_store_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9777265 DEFAULT CHARSET=utf8mb4 COMMENT='用户与标签关联表';

CREATE TABLE `bwc_user_change_mobile` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_user表id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '操作类型：1后台换绑，2用户换绑',
  `user_unionid` varchar(255) NOT NULL DEFAULT '' COMMENT '微信unionid',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '设备号',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `identity_card_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表id',
  `old_mobile` varchar(20) NOT NULL COMMENT '原先的手机号',
  `mobile` varchar(20) NOT NULL COMMENT '换绑以后的手机号',
  `op_id` int(11) NOT NULL DEFAULT '0' COMMENT '后台操作人id,用户端自己操作为-1',
  `data_state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_old_mobile` (`old_mobile`) USING BTREE,
  KEY `idx_mobile` (`mobile`),
  KEY `idx_user_ud` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4881 DEFAULT CHARSET=utf8mb4 COMMENT='客户端用户更换手机号';

CREATE TABLE `bwc_user_close_auth` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户表',
  `is_close` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否关闭个人实名：默认开启0，失败1',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：默认0，删除1',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COMMENT='用户是否单独关闭实名认证表';

CREATE TABLE `bwc_user_close_yun` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户表',
  `is_close` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否关闭个人云账户验证：默认开启0，失败1',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：默认0，删除1',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=616 DEFAULT CHARSET=utf8mb4 COMMENT='用户是否单独关闭云账户验证表';

CREATE TABLE `bwc_user_competitor_app` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `competitor_app` int(11) NOT NULL DEFAULT '0' COMMENT '竞对app，1：小蚕，2：歪麦，3：灰太狼，4：餐大大',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_id_competitor_app` (`user_id`,`competitor_app`)
) ENGINE=InnoDB AUTO_INCREMENT=777827 DEFAULT CHARSET=utf8mb4 COMMENT='用户竞对app安装表';

CREATE TABLE `bwc_user_coupon` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `time_limit` tinyint(1) NOT NULL DEFAULT '1' COMMENT '限时券 1是2否',
  `is_usage` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:未使用 1:已使用',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '券模板id',
  `coupon_type` int(11) NOT NULL DEFAULT '0' COMMENT '券类型 1:大牌专享券 2:提前抢单券 3:延迟上传券 4:超级免单券 5:超时复活券',
  `coupon_name` varchar(64) NOT NULL DEFAULT '' COMMENT '券名称',
  `coupon_no` varchar(64) NOT NULL DEFAULT '' COMMENT '券编号',
  `coupon_desc` varchar(500) NOT NULL DEFAULT '' COMMENT '券描述',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT '来源id',
  `source_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '来源类型 1:能量商城兑换 2:等级专属礼包 3:生日礼包 4:系统赠送 5:订单取消 6:首次关注公众号赠送 7:自动任务赠送 8:会员红包天天领活动 9助力领现金活动, 10首次提现送卡券包，11城市挑战赛 12订单助力加返',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `remark` varchar(255) NOT NULL COMMENT '备注',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id_coupon_type` (`user_id`,`coupon_type`),
  KEY `idx_expired_coupon` (`time_limit`,`is_usage`,`end_time`,`is_delete`,`user_id`) USING BTREE,
  KEY `idx_gmt_created` (`gmt_created`) USING BTREE,
  KEY `idx_source` (`source_type`,`source_id`,`is_usage`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=22132624 DEFAULT CHARSET=utf8mb4 COMMENT='用户优惠券';

CREATE TABLE `bwc_user_coupon_extra` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_coupon_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户优惠券id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `is_new` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否新到账 0:否 1:是',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_coupon_id` (`user_coupon_id`),
  KEY `idx_user_is_new` (`user_id`,`is_new`)
) ENGINE=InnoDB AUTO_INCREMENT=2551817 DEFAULT CHARSET=utf8mb4 COMMENT='用户优惠券扩展表';

CREATE TABLE `bwc_user_delivery_address` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '省(省市区都是bwc_customize_geofence.id)',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '市',
  `dist_id` int(11) NOT NULL DEFAULT '0' COMMENT '区',
  `consignee_name` varchar(20) NOT NULL DEFAULT '' COMMENT '收货人姓名',
  `mobile_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `full_address` varchar(500) NOT NULL DEFAULT '' COMMENT '详细地址(不含省市区)',
  `delivery_address` varchar(500) NOT NULL DEFAULT '' COMMENT '收货地址含省市区',
  `is_default` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '是否默认(0否,1是)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1635 DEFAULT CHARSET=utf8mb4 COMMENT='用户收货地址';

CREATE TABLE `bwc_user_device_registration` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `cid` varchar(64) NOT NULL DEFAULT '' COMMENT '设备id',
  `channel_id` int(11) NOT NULL DEFAULT '0' COMMENT 'app推送渠道id',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '设备平台(android,ios...)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_channel_id` (`channel_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2176730 DEFAULT CHARSET=utf8mb4 COMMENT='用户推送设备id表';

CREATE TABLE `bwc_user_ele_phone` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `ele_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=211660 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_energy_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `goods_id` int(11) NOT NULL DEFAULT '0' COMMENT '商品id',
  `serial_no` bigint(20) NOT NULL DEFAULT '0' COMMENT '流水号',
  `change_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:收入 1:支出',
  `source_type` int(11) NOT NULL DEFAULT '0' COMMENT '来源类型  1:每日签到 2:分享海报 3:观看视频 4:完成订单 5:要请团员注册 6:首次关注公众号赠送 21:能量商城兑换消耗 22:订单助力加返',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT '来源id',
  `energy_value` int(11) NOT NULL DEFAULT '0' COMMENT '变动能量',
  `after_energy` int(11) NOT NULL DEFAULT '0' COMMENT '变更后能量值',
  `mark` varchar(256) NOT NULL DEFAULT '' COMMENT '变更科目',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_created_delete` (`user_id`,`gmt_created`,`is_delete`) USING BTREE,
  KEY `idx_user_source_type_source_id_delete_energy` (`user_id`,`source_type`,`source_id`,`is_delete`,`energy_value`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=39738440 DEFAULT CHARSET=utf8mb4 COMMENT='用户能量变更记录表';

CREATE TABLE `bwc_user_ext` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `limit_self_mt` tinyint(1) NOT NULL DEFAULT '0' COMMENT '限制用户能否看见自营的美团数据 1限制; 2不限制',
  `is_first` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否首次风控',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `user_id` int(11) NOT NULL COMMENT '用户id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5700 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_favorite` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `platform_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '平台id，bwc_platform.id',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户ID，bwc_user.id',
  `store_id` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺ID',
  `store_name` varchar(64) NOT NULL DEFAULT '' COMMENT '店铺名称',
  `cover` varchar(255) NOT NULL DEFAULT '' COMMENT '店铺封面',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_user_favorite` (`platform_id`,`user_id`,`store_id`) USING BTREE,
  KEY `idx_store_id` (`store_id`)
) ENGINE=InnoDB AUTO_INCREMENT=155900 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_user_feedback_prompt` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'bwc_user.id C用户id',
  `last_feedback_prompt` timestamp NULL DEFAULT NULL COMMENT '上一次弹窗的时间',
  `feedback_click` tinyint(1) unsigned DEFAULT '0' COMMENT '用户点击：1，写好评，鼓励一下 2，反馈 3，下次再说',
  `platform` varchar(32) NOT NULL COMMENT '平台类型：安卓，IOS',
  `last_rating_prompt` timestamp NULL DEFAULT NULL COMMENT 'iOS 用户的评分弹窗的显示时间',
  `data_state` tinyint(4) unsigned DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=409438 DEFAULT CHARSET=utf8mb4 COMMENT='用户评价表';

CREATE TABLE `bwc_user_footprint` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `platform_abbr` varchar(32) NOT NULL COMMENT '平台',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id，bwc_user.id',
  `task_id` varchar(255) NOT NULL COMMENT '任务id',
  `store_id` int(11) DEFAULT NULL COMMENT '店铺id，bwc_store.id',
  `task_info` json DEFAULT NULL COMMENT '官方活动的信息',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_store_id` (`store_id`),
  KEY `idx_user_update_time` (`user_id`,`update_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=126538376 DEFAULT CHARSET=utf8mb4 COMMENT='用户足迹表';

CREATE TABLE `bwc_user_from` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0',
  `scene` varchar(255) NOT NULL DEFAULT '' COMMENT '场景：register注册',
  `from` varchar(255) NOT NULL DEFAULT '' COMMENT '来源：bck伴餐卡',
  `data_state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1318 DEFAULT CHARSET=utf8mb4 COMMENT='用户来源表';

CREATE TABLE `bwc_user_help_return_amount` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户表',
  `is_limit` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否限制用户助力：默认不限制0，限制1',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：默认0，删除1',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户是否是否限制用户助力表';

CREATE TABLE `bwc_user_identity_record` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '用户表id',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户表id',
  `real_name` varchar(50) NOT NULL DEFAULT '' COMMENT '实名姓名',
  `identity_no` varchar(80) NOT NULL DEFAULT '' COMMENT '加密的身份证',
  `identity_card_id` int(10) NOT NULL DEFAULT '0' COMMENT '对应的身份信息表id',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '操作类型：1用户主动清空实名信息，2管理后台清空用户实名信息，3调用云账户接口发现非签约状态清空实名信息，4绑定用户实名信息',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_identity_card_id` (`identity_card_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=294854 DEFAULT CHARSET=utf8mb4 COMMENT='用户变更实名认证身份证信息';

CREATE TABLE `bwc_user_intercept_whitelist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_user表id',
  `user_intercept_whitelist` tinyint(1) NOT NULL DEFAULT '0' COMMENT '开启/关闭北京骗返白名单，1关闭，2开启',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_member` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `member_count` int(11) NOT NULL DEFAULT '0' COMMENT '团员数量',
  `member_order_count` int(11) NOT NULL DEFAULT '0' COMMENT '团员订单数量',
  `blacklisted_member_count` int(11) NOT NULL DEFAULT '0' COMMENT '拉黑团员数量',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=343351 DEFAULT CHARSET=utf8mb4 COMMENT='用户团员信息';

CREATE TABLE `bwc_user_member_invite_click_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `member_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员id',
  `channel_type` varchar(32) NOT NULL DEFAULT '' COMMENT '渠道类型',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_member_user` (`user_id`,`member_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=20359 DEFAULT CHARSET=utf8mb4 COMMENT='团长激活团员邀请点击记录';

CREATE TABLE `bwc_user_member_order_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `member_order_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员订单id',
  `order_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员订单用户id',
  `order_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单来源 0:霸王餐订单 1:砍价捡漏订单',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_member_order` (`user_id`,`member_order_id`),
  KEY `idx_user_order_user` (`user_id`,`order_user_id`),
  KEY `idx_member_order_user_id` (`member_order_id`,`order_user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=28211408 DEFAULT CHARSET=utf8mb4 COMMENT='用户下级团员订单记录';

CREATE TABLE `bwc_user_member_sms` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `month` int(11) NOT NULL DEFAULT '0' COMMENT '月份',
  `batch_no` varchar(32) NOT NULL DEFAULT '' COMMENT '执行批次编号',
  `member_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员id',
  `member_user_mobile` varchar(32) NOT NULL DEFAULT '' COMMENT '团员手机号',
  `is_send` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否发送 0:未发送 1:已发送',
  `member_agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员注册代理id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_month` (`user_id`,`month`),
  KEY `idx_batch_no` (`batch_no`)
) ENGINE=InnoDB AUTO_INCREMENT=33262 DEFAULT CHARSET=utf8mb4 COMMENT='团长激活团员短信记录';

CREATE TABLE `bwc_user_member_user_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `member_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '团员用户id',
  `is_blacklisted` tinyint(1) NOT NULL DEFAULT '0' COMMENT '团员是都被拉黑 0:未拉黑 1:已拉黑',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_member_user` (`user_id`,`member_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1433586 DEFAULT CHARSET=utf8mb4 COMMENT='用户下级团员记录';

CREATE TABLE `bwc_user_mobile_check_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户表',
  `response` json DEFAULT NULL COMMENT '返回结果',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：默认0，删除1',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`,`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=164105 DEFAULT CHARSET=utf8mb4 COMMENT='用户手机号三要素认证记录';

CREATE TABLE `bwc_user_msg_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `msg_event_id` int(11) NOT NULL COMMENT '消息事件id 如果消息事件id为0则为免打扰开关0:关闭 1:开启',
  `config_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '配置开关 0:关闭 1:开启',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=64094 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='用户消息设置';

CREATE TABLE `bwc_user_mt_phone` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `mt_phone` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=934660 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_notice_permission` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `user_device_registration_id` varchar(60) NOT NULL DEFAULT '' COMMENT '极光推送的registration_id',
  `notice_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否打开推送权限 0:未打开 1:已打开',
  `channel_code` varchar(32) NOT NULL DEFAULT 'JPUSH' COMMENT '推送渠道',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_registration_id` (`user_device_registration_id`,`channel_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2348090 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_operation_auth` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0',
  `blacklist_all` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否拉黑所有关联信息：0否，1是',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`,`data_state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11820 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_operation_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作员对应的admin表id',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '后台被操作人id',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '操作类型：1用户绑定上级，2用户取消绑定上级，3禁用，4启用，5修改积分，6修改金币，7拉黑支付，8解封支付宝，9验证密码，10验证验证码',
  `msg` varchar(300) NOT NULL DEFAULT '' COMMENT '操作信息',
  `data` json NOT NULL COMMENT '修改之前的数据json',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  PRIMARY KEY (`id`),
  KEY `idx_admin_id` (`admin_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=329363 DEFAULT CHARSET=utf8mb4 COMMENT='用户相关操作日志表';

CREATE TABLE `bwc_user_order_switch_ctrl` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_switch_way_ctrl` tinyint(1) NOT NULL DEFAULT '0' COMMENT '订单开关切换方式 0默认; 1开启; 2关闭',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `user_id` int(11) NOT NULL COMMENT '用户id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=328 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_order_timeout_limit_rule_disable` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT 'bwc_user.id，C用户id',
  `created_by` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_admin.id 管理员id',
  `updated_by` int(11) DEFAULT NULL COMMENT 'bwc_admin.id 管理员id',
  `data_state` tinyint(4) NOT NULL DEFAULT '0',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='用户超时取消规则表';

CREATE TABLE `bwc_user_popup_setting` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id，bwc_user.id',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '弹窗类型：1-试吃官超级返弹窗，2-关注公众号不再提醒弹窗，5-通用活动详情正在进行中，6-复购卡活动详情正在进行中，7-新人专版首单完成提醒，8-新人专版第三单完成提醒，9-合伙人计划弹窗',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1：开启 0：关闭',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id_type` (`user_id`,`type`)
) ENGINE=InnoDB AUTO_INCREMENT=1149754 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_quantity_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `quantity` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '数额',
  `before_quantity` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '操作前数额',
  `after_quantity` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '操作后数额',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '管理员id',
  `currency_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '货币类型1积分2金币',
  `method_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '操作类型1订单通过增加 2提现减少 3提现驳回增加 4管理员扣除 5提现失败返回 6活动完成-下单返利 7活动完成-邀请返利 8订单取消扣除积分 9订单扣除积分 10订单扣除金币 11订单取消扣除团员奖励 12订单取消扣除下单返利活动奖励 13订单取消扣除邀请返利活动奖励 14订单增加积分 15订单增加金币 16订单恢复增加积分 17订单恢复增加团员奖励 18订单恢复增加下单返利活动奖励 19订单恢复增加邀请返利活动奖励 20助力领现金活动奖励 21助力加返活动奖励增加 22助力加返活动奖励扣除',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `order_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单id',
  `order_user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '订单所属用户',
  `withdrawal_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '提现申请id',
  `activity_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '活动id',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注信息，扣除备注扣除原因，及其他备注信息',
  `source_type` tinyint(1) NOT NULL DEFAULT '1' COMMENT '来源 1晓晓; 2砍价',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `home` (`user_id`,`quantity`,`currency_type`,`method_type`),
  KEY `currency_type` (`create_time`,`currency_type`,`method_type`,`order_id`,`quantity`,`user_id`,`order_user_id`,`withdrawal_id`) USING BTREE,
  KEY `idx_order_id` (`order_id`),
  KEY `idx_order_user_id` (`order_user_id`) USING BTREE,
  KEY `idx_withdrawal_id` (`withdrawal_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=79298129 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_register_source` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `register_source` varchar(50) NOT NULL COMMENT '注册来源，例如:\ngeneralActivity通用活动，\nrepurchaseCardActivity复购卡活动（新）\nleaderInvite#wechatFriend 暗号海报微信好友\nleaderInvite#wechatMoments 暗号海报微信朋友圈\nleaderInvite#xiaohongshu 暗号海报小红书\nleaderInvite#douyin 暗号海报抖音\nleaderInvite#weibo 暗号海报微博\nleaderInvite#mp-weixin 暗号海报微信小程序或h5\ncityChallenge#wechatFriend 暗号城市挑战赛微信好友\ncityChallenge#wechatMoments 暗号城市挑战赛微信朋友圈\ncityChallenge#xiaohongshu 暗号城市挑战赛小红书\ncityChallenge#douyin 暗号城市挑战赛抖音\ncityChallenge#weibo 暗号城市挑战赛微博\ncityChallenge#mp-weixin 暗号城市挑战赛微信小程序或h5\noldRepurchaseCardActivity复购卡活动（老）\nsaveBillShare省钱账单分享',
  `category` tinyint(3) NOT NULL DEFAULT '0' COMMENT '分类 1官方; 2 达人;',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_register_source` (`register_source`),
  KEY `idx_category` (`category`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2679953 DEFAULT CHARSET=utf8mb4 COMMENT='用户注册来源表';

CREATE TABLE `bwc_user_risk_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` int(11) NOT NULL DEFAULT '0' COMMENT '操作人id',
  `user_id` int(11) NOT NULL COMMENT '用户id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5698 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_score` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL COMMENT '用户id',
  `not_yun_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '非云账户积分总额',
  `yun_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '云账户积分总额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=804382 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_search_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `keyword` varchar(255) NOT NULL COMMENT '关键词',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id，bwc_user.id',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_update_time` (`user_id`,`update_time`)
) ENGINE=InnoDB AUTO_INCREMENT=25612356 DEFAULT CHARSET=utf8mb4 COMMENT='用户历史搜索表';

CREATE TABLE `bwc_user_sid` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL COMMENT '用户id',
  `red_link` varchar(255) NOT NULL DEFAULT '' COMMENT '红包链接',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2695739 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_sid_updater` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL COMMENT '用户id',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1998825 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_sign_in_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户表id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域',
  `province_code` varchar(40) NOT NULL DEFAULT '' COMMENT '省code',
  `city_code` varchar(40) NOT NULL DEFAULT '' COMMENT '市code',
  `district_code` varchar(40) NOT NULL DEFAULT '' COMMENT '区code',
  `town_code` varchar(40) NOT NULL DEFAULT '' COMMENT '街道code',
  `province` varchar(50) NOT NULL DEFAULT '' COMMENT '省',
  `city` varchar(50) NOT NULL DEFAULT '' COMMENT '市',
  `district` varchar(50) NOT NULL DEFAULT '' COMMENT '区',
  `township` varchar(50) NOT NULL DEFAULT '' COMMENT '街道',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '逆地址',
  `version` varchar(40) NOT NULL DEFAULT '' COMMENT '版本',
  `platform` varchar(40) NOT NULL DEFAULT '' COMMENT '来源：web网页，ios, android,wx-web',
  `user_device_cid` varchar(50) NOT NULL DEFAULT '' COMMENT '设备编号',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_agent_id` (`agent_id`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1295596 DEFAULT CHARSET=utf8mb4 COMMENT='用户注册记录表';

CREATE TABLE `bwc_user_sign_in_remind` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `switch_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:关闭 1:开启',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18209 DEFAULT CHARSET=utf8mb4 COMMENT='用户签到提醒配置';

CREATE TABLE `bwc_user_sign_yun` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户表',
  `is_sign` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否已经签约云账户：默认0没有签约，已经签约1',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：默认0，删除1',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=331343 DEFAULT CHARSET=utf8mb4 COMMENT='用户是否已经云账户签约';

CREATE TABLE `bwc_user_silk` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '晓晓 bwc_user 表 id（标记已同步）',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2636552 DEFAULT CHARSET=utf8mb4 COMMENT='用户已同步标记表';

CREATE TABLE `bwc_user_sync_score_raw_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `raw_log` text NOT NULL COMMENT '记录的原始数据',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '处理状态 1未处理; 2已处理; 3部分处理',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1906 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_sync_score_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `xc_record_id` int(11) NOT NULL DEFAULT '0' COMMENT 'xc变更日志记录',
  `raw_record_log` text NOT NULL COMMENT '记录的原始数据',
  `ref_id` int(11) NOT NULL DEFAULT '0' COMMENT '指向原始记录的id',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '处理状态 1未处理; 2已处理',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_record_id` (`user_id`,`xc_record_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1905 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_tag` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID，bwc_user.id',
  `type` tinyint(4) NOT NULL COMMENT '标签类型：1=流失用户，2=回访用户',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `last_revisit_time` timestamp NULL DEFAULT NULL COMMENT '最后回访时间',
  `lost_time` timestamp NULL DEFAULT NULL COMMENT '流失时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id_last_revisit_time` (`user_id`,`last_revisit_time`)
) ENGINE=InnoDB AUTO_INCREMENT=1937619 DEFAULT CHARSET=utf8mb4 COMMENT='用户标签关联表';

CREATE TABLE `bwc_user_unbind_identity` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_user表id',
  `user_unionid` varchar(255) NOT NULL DEFAULT '' COMMENT '微信unionid',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '设备号',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `identity_card_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表id',
  `user_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `user_redundancy` json NOT NULL COMMENT 'User表冗余信息',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14225 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_unbind_wechat` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_user表id',
  `user_unionid` varchar(255) NOT NULL DEFAULT '' COMMENT '微信unionid',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '设备号',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `identity_card_id` int(11) NOT NULL DEFAULT '0' COMMENT 'bwc_identity_card表id',
  `user_mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '用户手机号',
  `user_redundancy` json NOT NULL COMMENT 'User表冗余信息',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3053 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_user_upgrade_notice` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员等级id',
  `vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '会员等级',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:未通知 1:已通知',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_status_vip_level` (`user_id`,`status`,`vip_level`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=524460 DEFAULT CHARSET=utf8mb4 COMMENT='会员升级通知';

CREATE TABLE `bwc_user_version` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `version` int(10) unsigned NOT NULL DEFAULT '20041' COMMENT '版本号',
  `platform` varchar(20) NOT NULL DEFAULT '' COMMENT '登陆平台',
  `scene` varchar(128) NOT NULL DEFAULT '' COMMENT '场景值',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`,`version`,`scene`,`platform`) USING BTREE,
  KEY `idx_scene` (`scene`,`platform`,`version`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13240485 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_user_violation_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) NOT NULL DEFAULT '0' COMMENT '操作人',
  `admin_name` varchar(80) NOT NULL DEFAULT '' COMMENT '操作人姓名',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '被操作的用户',
  `level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '违规告警级别：1口头警告，2黄牌警告，3红牌拉黑',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '理由',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=55984 DEFAULT CHARSET=utf8mb4 COMMENT='用户违规操作日志表';

CREATE TABLE `bwc_user_vip_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员等级id',
  `vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '会员等级',
  `growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '会员成长值(不包含锁定成长值)',
  `lock_growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '锁定成长值',
  `order_growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '订单成长值(不包含锁定成长值)',
  `lock_order_growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '订单锁定成长值',
  `member_growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '团员成长值(不包含锁定成长值)',
  `lock_member_growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '团员锁定成长值',
  `order_num` int(11) NOT NULL DEFAULT '0' COMMENT '用户完成订单(不包含锁定订单)',
  `lock_order_num` int(11) NOT NULL DEFAULT '0' COMMENT '锁定订单',
  `member_num` int(11) NOT NULL DEFAULT '0' COMMENT '用户有效团员(不包含锁定团员)',
  `lock_member_num` int(11) NOT NULL DEFAULT '0' COMMENT '锁定团员',
  `admin_id` int(11) DEFAULT NULL COMMENT '客服id-bwc_admin表id',
  `lock_growth_value_update_time` timestamp NULL DEFAULT NULL COMMENT '锁定成长值上一次更新时间',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` bigint(20) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 大于0已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_id` (`user_id`,`is_delete`) USING BTREE,
  KEY `idx_vip_level_id` (`vip_level_id`) USING BTREE,
  KEY `idx_lock_update_time` (`lock_growth_value_update_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=444150 DEFAULT CHARSET=utf8mb4 COMMENT='用户会员表';

CREATE TABLE `bwc_user_visit_last_position` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) NOT NULL COMMENT '用户id',
  `agent_id` int(11) NOT NULL DEFAULT '0' COMMENT '代理区域id',
  `platform` varchar(255) NOT NULL DEFAULT '',
  `ip` varchar(255) NOT NULL DEFAULT '',
  `longitude` varchar(20) NOT NULL DEFAULT '' COMMENT '经度',
  `latitude` varchar(20) NOT NULL DEFAULT '' COMMENT '纬度',
  `user_device_cid` varchar(60) NOT NULL DEFAULT '' COMMENT '用户设备号',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id_device_cid` (`user_id`,`user_device_cid`) USING BTREE,
  KEY `idx_user_id_update_time` (`user_id`,`update_time`) USING BTREE,
  KEY `idx_update_time` (`update_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=877454 DEFAULT CHARSET=utf8mb4 COMMENT='用户app/h5首页最后一次访问位置';

CREATE TABLE `bwc_user_wechat_identity` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '用户id',
  `payee_name` varchar(50) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `app_id` varchar(50) NOT NULL DEFAULT '' COMMENT '微信应用appId',
  `open_id` varchar(50) NOT NULL DEFAULT '' COMMENT '对应应用和用户的openId',
  `union_id` varchar(50) NOT NULL DEFAULT '' COMMENT '开放平台unionId',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `app_id` (`app_id`,`open_id`) USING BTREE,
  KEY `union_id` (`union_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2465215 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE `bwc_user_wechat_mp_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `openid` varchar(64) NOT NULL COMMENT '微信openid',
  `wechat_nick` varchar(30) NOT NULL DEFAULT '' COMMENT '用户微信昵称',
  `scan_scene` varchar(32) DEFAULT NULL COMMENT '扫码场景值',
  `subscribe_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '关注状态（0未关注 1已关注）',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `openid` (`openid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1228837 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='用户微信公众号信息';

CREATE TABLE `bwc_vajra_cate` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `cate_name` varchar(20) NOT NULL COMMENT '分类名称',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '排序',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_vajra_district` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `cate_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '分类id',
  `vajra_icon` varchar(255) NOT NULL DEFAULT '' COMMENT '小图标链接',
  `vajra_title` varchar(20) NOT NULL DEFAULT '' COMMENT '金刚区标题',
  `vajra_logo_url` varchar(255) NOT NULL DEFAULT '' COMMENT '金刚区logo链接',
  `vajra_skip_config` varchar(1500) NOT NULL DEFAULT '' COMMENT '金刚区跳转配置',
  `skip_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '跳转类型 0不跳转 1展示图片 2内链跳转 3http链接 4跳转到小程序 5跳转到外部app',
  `hot` tinyint(1) unsigned NOT NULL DEFAULT '2' COMMENT '热门 1是2否',
  `application` varchar(20) NOT NULL DEFAULT '' COMMENT '客户端场景',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '状态 1显示 2禁用',
  `sort` int(11) unsigned NOT NULL DEFAULT '99' COMMENT '排序',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=169 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_version_compatible` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `version_name` varchar(30) NOT NULL DEFAULT '' COMMENT '版本名',
  `min_version` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '最低兼容版本',
  `version_desc` varchar(255) NOT NULL DEFAULT '' COMMENT '版本描述',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_vip_basic_equity` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `min_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '可享受最小会员等级id',
  `min_vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '可享受最小会员等级',
  `equity_name` varchar(32) NOT NULL DEFAULT '' COMMENT '权益名称',
  `equity_icon` varchar(200) NOT NULL DEFAULT '' COMMENT '权益图标链接',
  `equity_desc` varchar(200) NOT NULL DEFAULT '' COMMENT '权益简述',
  `equity_rule` varchar(200) NOT NULL DEFAULT '' COMMENT '等级要求',
  `equity_explain` varchar(200) NOT NULL DEFAULT '' COMMENT '权益说明',
  `image_url` varchar(200) NOT NULL DEFAULT '' COMMENT '图片链接',
  `image_mark` varchar(200) NOT NULL DEFAULT '' COMMENT '图片备注',
  `equity_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:优享客服 1:生日福利 2:提现秒到 3:优先审核',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COMMENT='会员基础权益';

CREATE TABLE `bwc_vip_basic_equity_item` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `basic_equity_id` int(11) NOT NULL DEFAULT '0' COMMENT '基础权益id',
  `gift_name` varchar(64) NOT NULL DEFAULT '' COMMENT '礼品名称',
  `gift_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1:优惠券 2:红包 3:晓晓能量',
  `gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '礼品数量',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '券模板id',
  `red_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包金额 gift_type=2时',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COMMENT='会员基础权益可领奖励';

CREATE TABLE `bwc_vip_basic_equity_receive` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `vip_basic_equity_item_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员基础权益可领奖励id',
  `receive_num` int(11) NOT NULL DEFAULT '0' COMMENT '领取数量',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_equity_item_is_delete` (`user_id`,`vip_basic_equity_item_id`,`is_delete`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=17195 DEFAULT CHARSET=utf8mb4 COMMENT='会员基础权益可领奖励领取记录';

CREATE TABLE `bwc_vip_daily_gift_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次配置id',
  `start_time` char(5) NOT NULL DEFAULT '00:00' COMMENT '场次开始时间默认00:00',
  `end_time` char(5) NOT NULL DEFAULT '23:59' COMMENT '场次结束时间默认23:59',
  `activity_date` date NOT NULL COMMENT '活动日期',
  `stop_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '活动停用状态(停止用户端不显示) 0:正常 1:已停用',
  `pause_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '活动暂停状态(暂停用户端显示已抢光) 0:正常 1:已暂停',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_config_id` (`activity_config_id`) USING BTREE,
  KEY `idx_client` (`activity_date`,`stop_status`,`is_delete`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=767 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领活动场次表';

CREATE TABLE `bwc_vip_daily_gift_activity_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `start_time` char(5) NOT NULL DEFAULT '00:00' COMMENT '场次开始时间默认00:00',
  `end_time` char(5) NOT NULL DEFAULT '23:59' COMMENT '场次结束时间默认23:59',
  `stop_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '停用状态 0:正常 1:已停用',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领活动场次配置';

CREATE TABLE `bwc_vip_daily_gift_activity_jackpot` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次配置id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次id',
  `activity_jackpot_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动奖池配置id',
  `jackpot_name` varchar(10) NOT NULL DEFAULT '' COMMENT '奖池名称',
  `min_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '最小会员等级id',
  `min_vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '最小会员等级',
  `max_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '最大会员等级id',
  `max_vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '最大会员等级',
  `min_random_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '红包最小随机金额',
  `max_random_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '红包最大随机金额',
  `show_client_sum_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '给用户的看红包总额',
  `show_client_sum_gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '给用户看奖品份数',
  `show_client_max_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '给用户看最大红包金额',
  `max_amount_record_id` int(11) NOT NULL DEFAULT '0' COMMENT '手气最佳recordId',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_config_id` (`activity_config_id`) USING BTREE,
  KEY `idx_activity_id` (`activity_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2299 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领奖池表';

CREATE TABLE `bwc_vip_daily_gift_activity_jackpot_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次配置id',
  `jackpot_name` varchar(10) NOT NULL DEFAULT '' COMMENT '奖池名称',
  `min_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '最小会员等级id',
  `min_vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '最小会员等级',
  `max_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '最大会员等级id',
  `max_vip_level` int(11) NOT NULL DEFAULT '0' COMMENT '最大会员等级',
  `gift_list_json` text NOT NULL COMMENT '奖池礼品配置json',
  `min_random_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '红包最小随机金额',
  `max_random_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '红包最大随机金额',
  `manual_amount_config` text NOT NULL COMMENT '手动红包配置json',
  `show_client_sum_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '给用户的看红包总额',
  `show_client_sum_gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '给用户看奖品份数',
  `show_client_max_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '给用户看最大红包金额',
  `random_amount_config` text NOT NULL COMMENT '随机红包配置json',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_config_id` (`activity_config_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领活动奖池配置表';

CREATE TABLE `bwc_vip_daily_gift_activity_jackpot_gift` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次配置id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次id',
  `activity_jackpot_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动奖池id',
  `activity_jackpot_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动奖池配置id',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '奖品类型 1:红包 2:优惠券',
  `red_amount` decimal(22,2) NOT NULL DEFAULT '0.00' COMMENT '红包最大预算金额',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '券模板id',
  `gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '奖品数量',
  `received_gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '已领取奖品数量',
  `received_red_amount` decimal(22,2) NOT NULL DEFAULT '0.00' COMMENT '已领取红包总金额',
  `used_gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '已使用礼品数量(已核销)',
  `used_red_amount` decimal(22,2) NOT NULL DEFAULT '0.00' COMMENT '已使用红包金额(已核销)',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_config_id` (`activity_config_id`) USING BTREE,
  KEY `idx_activity_id` (`activity_id`) USING BTREE,
  KEY `idx_activity_jackpot_config_id` (`activity_jackpot_config_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=12277 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领奖池奖品库存表';

CREATE TABLE `bwc_vip_daily_gift_invite_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_promoter_id` int(11) NOT NULL DEFAULT '0' COMMENT '推广用户id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `red_amount` decimal(22,2) NOT NULL DEFAULT '0.00' COMMENT '推广赠送红包金额',
  `is_read` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否已读(已读后不展示) 0:未读 1:已读',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_promoter` (`user_promoter_id`,`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领拉新红包奖励记录表';

CREATE TABLE `bwc_vip_daily_gift_manual_red_envelopes` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次配置id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次id',
  `activity_jackpot_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动奖池id',
  `red_amount` decimal(22,2) NOT NULL DEFAULT '0.00' COMMENT '单个红包金额',
  `gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '奖品数量',
  `received_gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '已领取奖品数量',
  `min_random_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '红包最小随机金额',
  `max_random_amount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT '红包最大随机金额',
  `red_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '红包类型 1:手动红包 2:随机红包',
  `priority_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否前几分钟优先抽 0:不优先抽 1 :优先抽',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_activity_jackpot_id` (`activity_jackpot_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3500 DEFAULT CHARSET=utf8mb4 COMMENT='会员红包天天领手动红包表';

CREATE TABLE `bwc_vip_daily_gift_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `activity_config_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次配置id',
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次id',
  `activity_jackpot_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次奖池id',
  `activity_jackpot_gift_id` int(11) NOT NULL DEFAULT '0' COMMENT '会员红包天天领活动场次奖池奖品库存id',
  `type` tinyint(2) NOT NULL DEFAULT '0' COMMENT '奖品类型 1:红包 2:优惠券',
  `red_amount` decimal(22,2) NOT NULL DEFAULT '0.00' COMMENT '红包总金额',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '券模板id',
  `gift_name` varchar(255) NOT NULL DEFAULT '' COMMENT '奖品名称冗余',
  `vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '领取时会员等级id',
  `is_used` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否已使用 0未使用  1:已使用',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `source_id` int(11) NOT NULL DEFAULT '0' COMMENT '奖品对应的来源id  类型为红包取红包表id  优惠券取卡券表id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_activity_config_id` (`activity_config_id`) USING BTREE,
  KEY `idx_source_id` (`source_id`,`type`)
) ENGINE=InnoDB AUTO_INCREMENT=91275 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_vip_gift` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '解锁礼包的会员等级id',
  `max_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '可享受最大会员等级id',
  `min_vip_level_id` int(11) NOT NULL DEFAULT '0' COMMENT '可享受最小会员等级id',
  `gift_num` int(11) NOT NULL DEFAULT '0' COMMENT '礼品数量',
  `gift_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1:优惠券 2:红包',
  `gift_name` varchar(64) NOT NULL DEFAULT '' COMMENT '礼品名称',
  `coupon_template_id` int(11) NOT NULL DEFAULT '0' COMMENT '券模板id',
  `red_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '红包金额',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8mb4 COMMENT='会员专属礼包';

CREATE TABLE `bwc_vip_gift_receive` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
  `vip_gift_id` int(11) NOT NULL DEFAULT '0' COMMENT '专属礼包id',
  `receive_num` int(11) NOT NULL DEFAULT '0' COMMENT '领取数量',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_gift_is_delete` (`user_id`,`vip_gift_id`,`is_delete`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11990490 DEFAULT CHARSET=utf8mb4 COMMENT='专属礼包领取记录';

CREATE TABLE `bwc_vip_level` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `level_value` int(11) NOT NULL DEFAULT '0' COMMENT '等级',
  `level_image` varchar(200) NOT NULL DEFAULT '' COMMENT '等级背景图片',
  `level_name` varchar(32) NOT NULL DEFAULT '' COMMENT '等级名称',
  `level_name_image` varchar(200) NOT NULL DEFAULT '' COMMENT '等级名称切图',
  `level_alias` varchar(32) NOT NULL DEFAULT '' COMMENT '等级别名',
  `growth_value` int(11) NOT NULL DEFAULT '0' COMMENT '最大成长值',
  `order_num` int(11) NOT NULL DEFAULT '0' COMMENT '最大完成订单数',
  `order_base_value` int(11) NOT NULL DEFAULT '0' COMMENT '订单成长基数',
  `member_num` int(11) NOT NULL DEFAULT '0' COMMENT '最大有效团员数',
  `member_base_value` int(11) NOT NULL DEFAULT '0' COMMENT '团员成长基数',
  `is_max_level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否是最大等级 0:否 1:是',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COMMENT='会员等级表';

CREATE TABLE `bwc_voice_channel` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT 'ai语音渠道名称',
  `code` varchar(100) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '系统编码',
  `enabled` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否开启',
  `config` text CHARACTER SET utf8 NOT NULL COMMENT '配置',
  `balance` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '剩余数量',
  `balance_unit` enum('条','元','欧元','比索','美元') CHARACTER SET utf8 NOT NULL DEFAULT '条' COMMENT '短信余额单位',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_voice_record` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `identification_id` varchar(60) NOT NULL DEFAULT '' COMMENT '能识别的业务id',
  `channel_id` int(10) NOT NULL DEFAULT '0' COMMENT '渠道id',
  `request_params` json DEFAULT NULL COMMENT '发起请求的参数',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：1发起请求，2发起请求成功，3发起请求失败',
  `callback_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '发起请求以后的结果：1成功，2拒绝接听，3接听异常',
  `error_msg` text COMMENT '请求失败原因',
  `sms_templateCode` varchar(80) DEFAULT '' COMMENT '发送短信的模版',
  `sms_error_msg` text COMMENT '发短信失败的原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `identification_channel` (`identification_id`,`channel_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=516605 DEFAULT CHARSET=utf8mb4 COMMENT='ai外呼的记录表';

CREATE TABLE `bwc_voice_template` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `channel_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'Ai外呼渠道id',
  `code` varchar(50) CHARACTER SET utf8 NOT NULL COMMENT '模板编码',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '模板名称',
  `enabled` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用 1是其他否',
  `config` text CHARACTER SET utf8 COMMENT '配置',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_wechat_blacklist` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_unionid` varchar(255) NOT NULL DEFAULT '' COMMENT '微信union_id\n',
  `reason` varchar(255) NOT NULL DEFAULT '' COMMENT '封号原因',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_unionid` (`user_unionid`,`data_state`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=32035 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_wechat_mp_auto_reply` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `keyword` varchar(255) NOT NULL DEFAULT '' COMMENT '关键字',
  `reply_content` varchar(500) NOT NULL COMMENT '自动回复内容',
  `type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '类型 1:自动回复  2:公众号按钮自动回复',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_key` (`keyword`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='微信公众号自动回复表';

CREATE TABLE `bwc_withdrawal` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '关联用户id',
  `user_nick` varchar(255) NOT NULL DEFAULT '' COMMENT '用户昵称',
  `user_phone` varchar(255) NOT NULL DEFAULT '' COMMENT '用户联系方式',
  `user_collection_qr_code` varchar(255) NOT NULL DEFAULT '' COMMENT '用户收款码',
  `user_alipay_account` varchar(255) NOT NULL DEFAULT '' COMMENT '支付宝账号',
  `user_alipay_name` varchar(255) NOT NULL DEFAULT '' COMMENT '收款人姓名',
  `user_wechat_app_id` varchar(50) NOT NULL DEFAULT '' COMMENT '收款商户绑定微信应用的APPID',
  `user_wechat_open_id` varchar(50) NOT NULL DEFAULT '' COMMENT '用户收款openid',
  `user_old_score` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT '用户原积分',
  `user_old_gold` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT '用户原金币',
  `user_withdrawal_score` decimal(15,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '用户提现积分',
  `user_withdrawal_gold` decimal(15,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '用户提现金币',
  `user_remaining_score` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT '用户剩余积分',
  `user_remaining_gold` decimal(15,2) NOT NULL DEFAULT '0.00' COMMENT '用户剩余金币',
  `withdrawal_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '申请类型 1积分 2金币',
  `user_withdrawal_time` datetime DEFAULT NULL COMMENT '用户提现申请时间',
  `payment_time` datetime DEFAULT NULL COMMENT '打款时间',
  `payment_person_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '打款人id',
  `payment_person` varchar(255) NOT NULL DEFAULT '' COMMENT '打款人',
  `withdrawal_status` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '提现状态 1 申请中 2已打款 3已驳回 4打款中 5打款失败 6已退回',
  `transfer_amount` decimal(15,2) unsigned NOT NULL DEFAULT '0.00' COMMENT '转账金额',
  `payment_channel` tinyint(3) unsigned DEFAULT '1' COMMENT '1云账户支付宝 2支付宝 5微信 6云账户微信',
  `withdrawal_order_no` varchar(255) NOT NULL DEFAULT '' COMMENT '提现订单号',
  `pay_no` varchar(255) NOT NULL DEFAULT '' COMMENT '第三方转账单号',
  `client_error_message` varchar(255) NOT NULL DEFAULT '' COMMENT '客户端显示失败原因',
  `transfer_status_desc` varchar(255) NOT NULL DEFAULT '' COMMENT '打款状态描述',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '数据状态0正常1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`,`withdrawal_type`) USING BTREE,
  KEY `idx_alipay_account` (`user_alipay_account`,`withdrawal_type`,`withdrawal_status`) USING BTREE,
  KEY `idx_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=21030319 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_withdrawal_day_amount` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `day` date NOT NULL COMMENT '日期',
  `withdrawal_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '提现总金额',
  `aqf_withdrawal_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '安全发提现总金额',
  `success_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '提现成功总金额',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_day` (`day`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=625 DEFAULT CHARSET=utf8mb4 COMMENT='提现总金额记录表';

CREATE TABLE `bwc_withdrawal_version` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `withdrawal_id` int(11) NOT NULL COMMENT '提现记录表id',
  `version` int(11) NOT NULL DEFAULT '0' COMMENT '提现时的版本号',
  `is_yun_open` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否打款到云账户积分：1是，0不是（默认）',
  `yun_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '云账户扣除积分',
  `not_yun_score` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '非云账户扣出积分',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_withdrawal_id` (`withdrawal_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14822580 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `bwc_withdrawal_yun_tax` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `withdrawal_id` int(11) NOT NULL COMMENT '提现表id',
  `user_real_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '用户实收金额，单位元，两位小数',
  `received_personal_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳个税，单位元，两位小数',
  `received_value_added_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳增值税，单位元，两位小数',
  `received_additional_tax` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '实纳附加税费，单位元，两位小数',
  `data_state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态：0正常，1删除',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_withdrawal_id` (`withdrawal_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=64359 DEFAULT CHARSET=utf8mb4 COMMENT='提现云账户税率计算记录表';

CREATE TABLE `bwc_work_wx_external_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `external_user_id` varchar(64) NOT NULL DEFAULT '' COMMENT '外部联系人的userid',
  `name` varchar(32) NOT NULL DEFAULT '' COMMENT '外部联系人的名称',
  `type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '外部联系人的类型，1表示该外部联系人是微信用户，2表示该外部联系人是企业微信用户',
  `union_id` varchar(64) NOT NULL DEFAULT '' COMMENT '微信unionid',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`external_user_id`) USING BTREE,
  KEY `idx_union_id` (`union_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=361911 DEFAULT CHARSET=utf8mb4 COMMENT='企微外部客户表';

CREATE TABLE `bwc_work_wx_external_user_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `work_wx_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '企微员工表id',
  `user_id` varchar(64) NOT NULL DEFAULT '' COMMENT '企微用户id',
  `work_wx_external_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '企微客户表id',
  `external_user_id` varchar(64) NOT NULL DEFAULT '' COMMENT '外部联系人的userid',
  `union_id` varchar(64) NOT NULL DEFAULT '' COMMENT '微信unionid',
  `follow_user_time` datetime NOT NULL COMMENT '添加企业成员的时间',
  `contact_delete_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '客户是否删除企微 0未删除 1已删除',
  `admin_delete_status` tinyint(2) NOT NULL DEFAULT '0' COMMENT '企微员工是否删除客户 0未删除 1已删除',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_union_id` (`union_id`) USING BTREE,
  KEY `idx_follow_user_time` (`follow_user_time`),
  KEY `idx_work_wx_external_user_id` (`work_wx_external_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=430409 DEFAULT CHARSET=utf8mb4 COMMENT='企业微信员工与客户关系表';

CREATE TABLE `bwc_work_wx_tag` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `tag_id` varchar(64) NOT NULL DEFAULT '' COMMENT '标签id',
  `tag_name` varchar(64) NOT NULL DEFAULT '' COMMENT '标签名称',
  `tag_group_id` varchar(64) NOT NULL DEFAULT '' COMMENT '标签分组id',
  `order` int(11) NOT NULL DEFAULT '0' COMMENT '排序',
  `tag_type` tinyint(2) NOT NULL DEFAULT '1' COMMENT '1:普通系统标签 2:自动任务未下单标签 3:自动任务能量无增加标签 4:自动任务未拉新团员标签',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_tag_id` (`tag_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=136 DEFAULT CHARSET=utf8mb4 COMMENT='企微标签表';

CREATE TABLE `bwc_work_wx_tag_external_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `tag_id` varchar(64) NOT NULL COMMENT '企微标签id',
  `external_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '外部用户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `iex_tag_id` (`tag_id`,`is_delete`) USING BTREE,
  KEY `idx_external_user_id` (`external_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=553049 DEFAULT CHARSET=utf8mb4 COMMENT='企微标签对应客户表';

CREATE TABLE `bwc_work_wx_tag_external_user_relation` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `tag_id` varchar(64) NOT NULL COMMENT '企微标签id',
  `external_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '外部用户id',
  `user_id` varchar(64) NOT NULL DEFAULT '' COMMENT '企微员工id',
  `external_id` varchar(64) NOT NULL DEFAULT '' COMMENT '企微的外部客户id',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `iex_tag_id` (`tag_id`,`is_delete`) USING BTREE,
  KEY `idx_external_user_id` (`external_user_id`),
  KEY `idx_check_exsist` (`tag_id`,`user_id`,`external_id`),
  KEY `idx_external_id` (`external_id`)
) ENGINE=InnoDB AUTO_INCREMENT=229970 DEFAULT CHARSET=utf8mb4 COMMENT='企微标签对应客户表';

CREATE TABLE `bwc_work_wx_tag_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `tag_group_id` varchar(64) NOT NULL DEFAULT '' COMMENT '标签分组id',
  `group_name` varchar(64) NOT NULL COMMENT '标签分组名称',
  `order` int(11) NOT NULL DEFAULT '0' COMMENT '排序',
  `is_system_group` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否是系统分组  0不是 1是',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COMMENT='企微标签分组表';

CREATE TABLE `bwc_work_wx_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `user_id` varchar(64) NOT NULL DEFAULT '' COMMENT '企微用户id',
  `name` varchar(32) NOT NULL DEFAULT '' COMMENT '企微名称',
  `mobile` varchar(20) NOT NULL DEFAULT '' COMMENT '手机号',
  `avatar` varchar(255) NOT NULL DEFAULT '' COMMENT '头像',
  `position` varchar(64) NOT NULL DEFAULT '' COMMENT '职位',
  `qr_code` varchar(255) NOT NULL DEFAULT '' COMMENT '二维码',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(2) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=749 DEFAULT CHARSET=utf8mb4 COMMENT='企微员工表';

CREATE TABLE `bwc_ws_message_record` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `batch_no` varchar(64) NOT NULL DEFAULT '' COMMENT '批次号',
  `message_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:系统通知 1:工单通知',
  `message_content` text NOT NULL COMMENT '消息内容',
  `read_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:未读 1:已读',
  `from_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '发送人id',
  `to_user_id` int(11) NOT NULL DEFAULT '0' COMMENT '接收人id',
  `extras` varchar(2000) NOT NULL DEFAULT '' COMMENT '扩展JSON信息',
  `push_status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:未推送 1:已推送',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_from_user_create_delete` (`from_user_id`,`gmt_created`,`is_delete`) USING BTREE,
  KEY `idx_to_user_create_delete` (`to_user_id`,`gmt_created`,`is_delete`) USING BTREE,
  KEY `idx_batch_no_delete` (`batch_no`,`is_delete`) USING BTREE,
  KEY `idx_to_user_push_status` (`to_user_id`,`push_status`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6136913 DEFAULT CHARSET=utf8mb4 COMMENT='websocket消息推送记录表';

CREATE TABLE `bwc_wx_code_params` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `link_url` varchar(32) NOT NULL DEFAULT '',
  `scene` varchar(32) NOT NULL DEFAULT '' COMMENT '小程序码scene参数',
  `params` varchar(2048) NOT NULL DEFAULT '' COMMENT '关联参数',
  `req_params` varchar(2048) NOT NULL DEFAULT '' COMMENT '生成小程序吗请求参数',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_scene` (`scene`),
  KEY `idx_link_url` (`link_url`)
) ENGINE=InnoDB AUTO_INCREMENT=263656 DEFAULT CHARSET=utf8mb4 COMMENT='微信小程序码scene参数映射表';

CREATE TABLE `bwc_xc_open_order_sync_fail_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `server_name` varchar(64) NOT NULL DEFAULT '' COMMENT '服务名',
  `msg_id` varchar(64) NOT NULL DEFAULT '' COMMENT '消息id',
  `msg_key` varchar(128) NOT NULL DEFAULT '' COMMENT '消息key',
  `msg_topic` varchar(64) NOT NULL DEFAULT '' COMMENT '消息topic',
  `msg_tag` varchar(64) NOT NULL DEFAULT '' COMMENT '消息tag',
  `msg_content` longtext COMMENT '消息内容',
  `consume_times` tinyint(1) NOT NULL DEFAULT '0' COMMENT '消费次数',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:成功 1:失败',
  `error_msg` varchar(512) DEFAULT '' COMMENT '失败原因',
  `create_by` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `update_by` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `gmt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_delete` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否删除 0未删除 1已删除',
  PRIMARY KEY (`id`),
  KEY `idx_msg_key` (`msg_key`),
  KEY `idx_status_gmt_created` (`status`,`gmt_created`)
) ENGINE=InnoDB AUTO_INCREMENT=87119 DEFAULT CHARSET=utf8mb4 COMMENT='小蚕订单同步失败记录表';

CREATE TABLE `channel` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `channelname` varchar(128) DEFAULT NULL COMMENT '渠道名称',
  `telphone` varchar(32) DEFAULT NULL COMMENT '电话号码',
  `qrcode` varchar(128) DEFAULT NULL COMMENT '渠道二维码',
  `isdelete` tinyint(4) DEFAULT NULL COMMENT '是否已删除 0正常 1已删除',
  `createtime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `commissiontype` tinyint(4) DEFAULT NULL COMMENT '返佣类型 1:按推荐人人数  2:按推荐人下单数量 3:按推荐商家的下单数量',
  `commissionprice` decimal(18,2) DEFAULT NULL COMMENT '每笔分佣金额 2：佣金',
  `agentid` int(11) DEFAULT NULL COMMENT '代理商id',
  `invitecode` varchar(36) DEFAULT NULL COMMENT '邀请码',
  `deduction` decimal(18,2) DEFAULT '0.00' COMMENT '扣钱金额',
  `secondecommission` decimal(18,2) DEFAULT '0.20' COMMENT '二级分佣',
  `firstorderflag` tinyint(4) DEFAULT '0' COMMENT '首单分佣配置(0:未开启首单分佣  1已开启首单分佣)',
  `flag` tinyint(4) DEFAULT '1' COMMENT '是否后台关闭分佣(0: 关闭  1:正常)',
  `group_id` int(11) DEFAULT '0' COMMENT '分组id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_type` (`commissiontype`) USING BTREE,
  KEY `idx_is_delete` (`isdelete`) USING BTREE,
  KEY `idx_agent_id` (`agentid`) USING BTREE,
  KEY `telphone` (`telphone`) USING BTREE,
  KEY `channelname` (`channelname`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=205050 DEFAULT CHARSET=utf8mb4 COMMENT='渠道表';

CREATE TABLE `chichigui_black` (
  `telphone` varchar(255) DEFAULT NULL,
  `lastreason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fuyang` (
  `id` varchar(255) DEFAULT NULL,
  `nick_name` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `upper_user_id` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `oauth_client_details` (
  `client_id` varchar(32) NOT NULL COMMENT '客户端ID',
  `resource_ids` varchar(256) DEFAULT NULL COMMENT '资源列表',
  `client_secret` varchar(256) DEFAULT NULL COMMENT '客户端密钥',
  `scope` varchar(256) DEFAULT NULL COMMENT '域',
  `authorized_grant_types` varchar(256) DEFAULT NULL COMMENT '认证类型',
  `web_server_redirect_uri` varchar(256) DEFAULT NULL COMMENT '重定向地址',
  `authorities` varchar(256) DEFAULT NULL COMMENT '角色列表',
  `access_token_validity` int(11) DEFAULT NULL COMMENT 'token 有效期',
  `refresh_token_validity` int(11) DEFAULT NULL COMMENT '刷新令牌有效期',
  `additional_information` varchar(4096) DEFAULT NULL COMMENT '令牌扩展字段JSON',
  `autoapprove` varchar(256) DEFAULT NULL COMMENT '是否自动放行',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新人',
  `create_user_id` int(11) DEFAULT NULL COMMENT '创建人id',
  `update_user_id` int(11) DEFAULT NULL COMMENT '更新人id',
  PRIMARY KEY (`client_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='终端信息表';

CREATE TABLE `sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键,自增',
  `salename` varchar(16) DEFAULT NULL COMMENT '销售人员名称',
  `phone` varchar(16) CHARACTER SET utf8 DEFAULT NULL COMMENT '销售手机号',
  `createid` int(11) DEFAULT NULL COMMENT '创建者',
  `isdelete` int(11) DEFAULT NULL COMMENT '0：正常 1：删除',
  `createtime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `agentid` int(11) DEFAULT NULL COMMENT '代理商编号',
  `leaderid` int(11) DEFAULT '0' COMMENT '组长id',
  `deductioncommission` tinyint(2) DEFAULT '0' COMMENT '是否扣除佣金给用户承担(0:不扣除  1:扣除)',
  `group_id` int(11) DEFAULT '0' COMMENT '分组id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `phone` (`phone`) USING BTREE,
  KEY `agentid` (`agentid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8mb4;

CREATE TABLE `shop` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键,自增',
  `shoplogo` longtext COMMENT '门店Logo',
  `shopname` varchar(512) DEFAULT NULL COMMENT '门店名称',
  `shopnamekeyword` varchar(16) DEFAULT NULL COMMENT '店铺关键字',
  `formername` varchar(512) DEFAULT NULL COMMENT '曾用名',
  `onecategory` int(11) DEFAULT NULL COMMENT '店铺分类',
  `platformtype` tinyint(4) DEFAULT '0' COMMENT '平台类型(默认0,1美团 2饿了么)',
  `priority` tinyint(4) DEFAULT '0' COMMENT '优先级(0:默认 1:优先反馈订单  2:优先纯订单)',
  `provinceid` varchar(128) DEFAULT NULL COMMENT '门店所在省',
  `cityid` varchar(128) DEFAULT NULL COMMENT '门店所在市',
  `distid` varchar(128) DEFAULT NULL COMMENT '门店所在区',
  `shopaddress` varchar(512) DEFAULT NULL COMMENT '门店地址',
  `linkmethod` varchar(32) DEFAULT NULL COMMENT '联系方式',
  `lat` varchar(128) DEFAULT NULL COMMENT '纬度',
  `lon` varchar(128) DEFAULT NULL COMMENT '经度',
  `isdelete` int(11) DEFAULT NULL COMMENT '0：正常 1：删除',
  `createtime` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `meituanurl` longtext COMMENT '美团URL',
  `elemourl` longtext COMMENT '饿了么URL',
  `isremove` int(11) DEFAULT NULL COMMENT '店铺是否关闭或禁用 0：正常 1：禁用',
  `channelid` int(11) DEFAULT '0' COMMENT '渠道',
  `salesid` int(11) DEFAULT '0' COMMENT '销售编号',
  `creator` int(11) DEFAULT NULL COMMENT '创建者编号',
  `sysmasterid` int(11) DEFAULT NULL COMMENT '修改者',
  `updatetime` timestamp NULL DEFAULT NULL COMMENT '修改时间',
  `istop` int(11) DEFAULT NULL COMMENT '是否置顶到首页',
  `agentid` int(11) DEFAULT NULL COMMENT '代理商编号',
  `prefix` varchar(64) DEFAULT NULL COMMENT '美团前缀',
  `elmprefix` varchar(64) DEFAULT NULL COMMENT '饿了么前缀',
  `commission` decimal(18,2) DEFAULT NULL COMMENT '活动佣金',
  `unsettledays` int(11) DEFAULT '0' COMMENT '未结算天数(默认为0  大于3天为逾期)',
  `bindchanneltime` timestamp NULL DEFAULT NULL COMMENT '绑定渠道时间',
  `mtqrcode` varchar(255) DEFAULT NULL COMMENT '美团店铺二维码',
  `elmqrcode` varchar(255) DEFAULT NULL COMMENT '饿了么店铺二维码',
  `createtype` tinyint(4) DEFAULT '1' COMMENT '创建类型(1:后台创建 2商家端创建)',
  `orderinterval` int(11) DEFAULT '1' COMMENT '用户下单的间隔时间(单位天)',
  `billquota` decimal(20,2) DEFAULT '2000.00' COMMENT '账单最大额度',
  `billdays` int(11) DEFAULT '3' COMMENT '账单最大天数',
  `contractor_id` int(11) DEFAULT '0' COMMENT '签约方id',
  `company_id` int(11) DEFAULT '0' COMMENT '绑定对应公司id',
  `salesvolume` int(11) DEFAULT '0' COMMENT '下单量',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_agent_id` (`agentid`) USING BTREE,
  KEY `idx_shopname` (`shopname`) USING BTREE,
  KEY `idx_is_remove` (`isremove`) USING BTREE,
  KEY `idx_channel_id` (`channelid`) USING BTREE,
  KEY `linkmethod` (`linkmethod`) USING BTREE,
  KEY `salesid` (`salesid`) USING BTREE,
  KEY `cityid` (`cityid`) USING BTREE,
  KEY `isdelete` (`isdelete`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=79108 DEFAULT CHARSET=utf8mb4 COMMENT='商家信息表';

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键,自增',
  `telphone` varchar(12) DEFAULT NULL COMMENT '会员手机号',
  `nickname` varchar(24) DEFAULT NULL COMMENT '会员昵称',
  `headportrait` varchar(128) DEFAULT NULL COMMENT '头像',
  `gender` int(11) DEFAULT NULL COMMENT '性别 1：男 2：女 0：未知',
  `province` longtext COMMENT '省',
  `city` longtext COMMENT '市',
  `dist` longtext COMMENT '区',
  `birthday` datetime DEFAULT NULL COMMENT '生日',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '钱包金额',
  `qrcode` longtext COMMENT '微信收款二维码',
  `headimg` longtext COMMENT '头像',
  `isforbid` int(11) DEFAULT NULL COMMENT '0：正常 1：禁用',
  `isdelete` int(11) DEFAULT NULL COMMENT '0：正常 1：删除',
  `createtime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `paypwd` longtext COMMENT '会员密码',
  `exprise` datetime DEFAULT NULL COMMENT '授权码过期时间',
  `wxopenid` varchar(30) DEFAULT NULL COMMENT '获取用户唯一标识',
  `channelid` int(11) DEFAULT NULL COMMENT '渠道id',
  `lastreason` longtext COMMENT '禁用原因',
  `lastreasonalipay` varchar(512) DEFAULT NULL COMMENT '支付宝封禁原因',
  `qrcodeali` longtext COMMENT '支付宝收款二维码',
  `userscommission` decimal(18,2) DEFAULT '0.00' COMMENT '用户分佣的金额',
  `aliname` varchar(512) DEFAULT NULL COMMENT '支付宝真实姓名',
  `aliphone` varchar(512) DEFAULT NULL COMMENT '支付宝收款手机号',
  `vipexprise` datetime DEFAULT NULL COMMENT 'vip过期时间',
  `channeltype` tinyint(4) DEFAULT '1' COMMENT '平台渠道类型 1:吃吃龟  2:蓝袋鼠',
  `deviceid` varchar(64) DEFAULT NULL COMMENT '设备码',
  `isactive` tinyint(4) DEFAULT '1' COMMENT '是否已激活(0未激活  1:已激活)',
  `substatus` tinyint(4) DEFAULT '0' COMMENT '关注状态(0:未关注  1:已关注)',
  `risklevel` tinyint(4) DEFAULT '0' COMMENT '风险等级 (0:正常用户 1:风险用户)',
  `riskreason` tinyint(4) DEFAULT '0' COMMENT '风险原因(枚举)',
  `lastip` varchar(32) DEFAULT NULL COMMENT '最后一次的ip(目前只有在上传订单时更新)',
  `unionid` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `idx_telphone` (`telphone`) USING BTREE,
  KEY `idx_channel_id` (`channelid`) USING BTREE,
  KEY `idx_del_forbid` (`isdelete`,`isforbid`) USING BTREE,
  KEY `nickname` (`nickname`) USING BTREE,
  KEY `wxopenid` (`wxopenid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=586290 DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

