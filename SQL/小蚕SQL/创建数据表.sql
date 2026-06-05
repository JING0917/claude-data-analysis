drop table if exists test.test_silkworm_lottery_my_prize_archive;

CREATE TABLE test.test_silkworm_lottery_my_prize_archive (
	auto_id bigint not null comment '自增ID',
	created_at datetime comment '创建时间',
	updated_at datetime comment '更新时间',
	deleted_at datetime comment '活动ID',
	source_created_at int comment '原表创建时间',
	source_updated_at int comment '原表更新时间',
	silk_id int comment '小蚕ID',
	prize_id int comment '奖品Id',
	city_code int comment '城市码',
	prize_name varchar(255) comment '奖品名称',
	icon varchar(512) comment '奖品图片',
	first_type int comment '一级类型 1: 业务奖品  2: 成本奖品 3: 权益奖品',
	second_type int comment '二级类型 1: 小蚕会员卡券 2: 大牌券 3: 蚕豆红包 4: 1000元京东E卡 5: 小蚕红包 6: 百元打车券 7: 特价活动券 8: 权益卡券优惠券',
	prize_value int comment '奖品数量 如果是蚕豆、红包、权益卡券类型为百分制',
	user_group int comment '用户组 1: 普通用户组 2: 疲劳用户组 3: 羊毛用户组',
	is_receive tinyint(1) comment '是否领取 0: 未知 1: 未领取 2: 已领取',
	is_value tinyint(1) comment '是否成本奖品 false: 不是 true: 是',
	extra string comment '奖品特殊字段',
	action_extra string comment '跳转链接参数',
	prize_type int comment '奖品类型 1: 幸运抽奖  2: 红包雨奖品',
	event_id int comment '活动id',
	red_pack_group string comment '奖品类型为小蚕红包组合时，小蚕红包组合信息',
	card_num int comment '奖品类型为「小蚕会员券」时,在开奖时发放对应数量卡券',
	red_pack_params string comment '奖品类型为探店/砍价红包时有值'
) ENGINE=OLAP
PRIMARY KEY(`auto_id`)
COMMENT "红包雨活动用户参与历史记录"
DISTRIBUTED BY HASH(`auto_id`)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);


筛选条件 
DATE_FORMAT(updated_at, '%Y-%m-%d') >= '${T-1}' and DATE_FORMAT(created_at, '%Y-%m-%d') <= '${T-1}'



drop table if exists dim.dim_silkworm_member;

CREATE TABLE if not exists dim.dim_silkworm_member (
auto_id bigint(20) NOT NULL COMMENT "自增ID",
user_id int(11) NOT NULL COMMENT "用户ID",
create_time datetime NULL COMMENT "创建时间",
update_time datetime NULL COMMENT "更新时间",
user_level int(11) NULL COMMENT "用户等级",
is_show_interests int(11) NULL COMMENT "是否展示用户兴趣(0:否,1:是)",
is_show_levelup_pupup int(11) NULL COMMENT "是否展示升级弹窗(0:否,1:是)",
month_time int(11) NULL COMMENT "月度时间",
advance_valid_order_num int(11) NULL COMMENT "超前有效订单量",
schedule_valid_order_num int(11) NULL COMMENT "预定有效订单量",
exclusive_valid_order_num int(11) NULL COMMENT "专享有效订单量",
instant_withdrawal_release_time datetime NULL COMMENT "秒提功能解封时间",
instant_audit_release_time datetime NULL COMMENT "秒审功能解封时间",
advance_order_release_time datetime NULL COMMENT "超前点单解封时间",
preorder_order_release_time datetime NULL COMMENT "预订单解封时间",
exclusive_order_release_time datetime NULL COMMENT "专享活动解封时间",
latest_levelup_time datetime NULL COMMENT "最近一次升级时间",
lastm_valid_order_num int(11) NULL COMMENT "上月有效订单量",
lastm_valid_team_user_num int(11) NULL COMMENT "上月邀请人数",
monthly_valid_order_num int(11) NULL COMMENT "月有效订单量",
monthly_valid_team_user_num int(11) NULL COMMENT "月邀请人数",
county_id int(11) NULL COMMENT "省份ID",
city_id int(11) NULL COMMENT "城市ID",
instant_audit_rights_time datetime NULL COMMENT "秒审权益时间",
latest_degrade_time datetime NULL COMMENT "最后一次降级时间",
if_show_degrade int(11) NULL COMMENT "是否展示降级(0: 否, 1:是)",
current_level_valid_order_num int(11) NULL COMMENT "当前等级已下订单数",
current_level_valid_team_user_num int(11) NULL COMMENT "当前等级已邀请新人数",
is_initialize_current_progress int(11) NULL COMMENT "是否已经初始化当前进度(0:未初始化,1:已初始化)",
vip_levelkeep_first_activate_time datetime NULL COMMENT "VIP保级第一次激活时间",
customized_blacked_status int comment '专版拉黑状态(1:已拉黑;0:未拉黑/解除拉黑)',
diroper_blacked_status int comment '直营拉黑状态(1:已拉黑;0:未拉黑/解除拉黑)',
last2m_growth_score int comment '近2月成长值',
last3m_growth_score int comment '近3月成长值',
levelkeep_growth_score int comment '保级成长值',
valid_newuser_num int comment '有效拉新用户量',
lvl_update_month int comment '等级更新的月份',
new_user_level int comment '新会员等级',
last_user_levele int comment '上一次会员等级',
is_plus int comment '是否plus会员(0:否;1:是)',
plus_activate_time datetime comment 'plus会员激活时间',
last_levelup_time datetime comment '上次升级时间',
last_degrade_time datetime comment '上次降级时间'
) ENGINE=OLAP
PRIMARY KEY(auto_id, user_id)
COMMENT "会员用户基础信息"
DISTRIBUTED BY HASH(auto_id, user_id)
ORDER BY(auto_id, user_id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);




drop table if exists test.test_sr_silkworm_agency_agency_earning_record;

CREATE TABLE test.test_sr_silkworm_agency_agency_earning_record (
	auto_id bigint not null comment '自增ID',
	created_at datetime comment '创建时间',
	updated_at datetime comment '更新时间',
	silk_id int comment '经纪人ID',
	store_id int comment '店铺ID',
	promotion_id int comment '活动ID',
	complete_num int comment '完成数量',
	create_time int comment '创建时间',
	agency_fee int comment '经纪人收益',
	remark varchar(256) comment '备注',
	record_type int comment '记录类型',
	withdraw_channel int comment '提现渠道',
	order_sn varchar(128) comment '提现订单号',
	bd_fee int comment 'bd收益',
	bd_id int comment 'bd_id',
	team_id int comment 'team_id',
	reason varchar(256) comment '扣减原因',
	withdraw_status int comment '提现记录状态',
	withdraw_fail_reason varchar(256) comment '提现失败原因',
	left_balance int comment '剩余金额',
	admin_id int comment '操作人，扣减返还操作需要',
	rp_id varchar(64) comment '提现ID',
	withdraw_account varchar(64) comment '支付宝提现账号',
	total_quota_num int comment '总份额'
) ENGINE=OLAP
PRIMARY KEY(`auto_id`)
COMMENT "经纪人收支记录"
DISTRIBUTED BY HASH(`auto_id`)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);



drop table if exists test.test_sr_silkworm_agency_merchant_agency;

CREATE TABLE test.test_sr_silkworm_agency_merchant_agency (
	auto_id bigint not null comment '自增ID',
	created_at datetime comment '创建时间',
	updated_at datetime comment '更新时间',
	silk_id int comment '经纪人ID',
	bd_id int comment 'bdId',
	team_id int comment '团队id',
	name varchar(64) comment '经纪人名称',
	id_card varchar(64) comment '经纪人身份证',
	card_pic_front varchar(128) comment '身份证正面',
	card_pic_back varchar(128) comment '身份证反面',
	phone varchar(64) comment '手机号',
	agency_type int comment '代理属性',
	agency_type_second tinyint comment '经纪人二级属性 1：个人工作室，2：竞对，3：美饿京经理，4：相关业务个人，5：品牌代运营，6：散店代运营，7：招商公司，8：个人，9：分公司，10：总部',
	agency_classification tinyint comment '经纪人类型 1：个人，2：个体工商户，3：有限公司',
	sign_status tinyint comment '签约状态 0：未签约，1：签约中，2：已签约，3：已解约',
	sign_process_id bigint comment '签约流程ID',
	wechat_account varchar(128) comment '经纪人微信号',
	additional_remarks varchar(512) comment '补充说明',
	business_license varchar(255) comment '合作信息-营业执照',
	cooper_company_name varchar(64) comment '合作信息-企业名称',
	cooper_usci varchar(64) comment '合作信息-统一社会信用代码',
	cooper_corporation varchar(32) comment '合作信息-法人',
	cooper_register_address varchar(64) comment '合作信息-注册地址',
	payee_name varchar(32) comment '收款方姓名',
	payee_account varchar(32) comment '收款方账号',
	payee_bank varchar(32) comment '收款方开户行',
	contract_no varchar(128) comment '合同编号',
	contract_start_time datetime comment '合同开始时间',
	contract_end_time datetime comment '合同结束时间',
	company_name varchar(128) comment '公司名称',
	company_position varchar(64) comment '职位',
	least_new_store int comment '保底新增店铺',
	least_new_quota int comment '保底份额',
	audit_pic varchar(512) comment '申请图片',
	status int comment '经纪人状态',
	create_time int comment '创建时间',
	audit_time int comment '提交审核时间',
	audit_end_time int comment '审核结束时间',
	remark varchar(256) comment '备注',
	if_del int comment '是否删除',
	admin_id int comment '创建人',
	audit_admin_id int comment '审核人',
	balance int comment '账户余额',
	profit_limit_less int comment '小于 30 的利润限制',
	profit_limit_greater int comment '大于 30 的利润限制',
	if_sign_cloud_pay int comment '签约云支付',
	withdraw_amount int comment '提现总金额',
	freeze_balance int comment '冻结金额',
	freeze_account int comment '冻结账户,不能提现',
	day_withdraw_amount int comment '日提现金额',
	month_withdraw_amount int comment '日提现金额',
	withdraw_count int comment '当日提现次数',
	last_withdraw_time int comment '最后一次提现时间',
	limit_withdraw int comment '限制提现 0 正常，1限制',
	notes varchar(512) comment '新备注',
	attach_list STRING comment '附件列表'
) ENGINE=OLAP
PRIMARY KEY(`auto_id`)
COMMENT "签约经纪人"
DISTRIBUTED BY HASH(`auto_id`)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);







drop table if exists dwd.dwd_sr_store_silkworm_agent_account;

CREATE TABLE dwd.dwd_sr_store_silkworm_agent_account (
	dt date not null comment '分区日期',
	auto_id bigint not null comment '自增ID',
	create_time datetime comment '创建时间',
	update_time datetime comment '更新时间',
	agent_id int comment '经纪人ID',
	bd_id int comment '商务ID',
	team_id int comment '团队ID',
	agent_realname varchar(64) comment '经纪人姓名',
	agent_id_num varchar(64) comment '经纪人身份证号',
	id_front_pic_url varchar(128) comment '经纪人身份证正面图片URL',
	id_back_pic_url varchar(128) comment '经纪人身份证背面图片URL',
	phone varchar(64) comment '经纪人手机号',
	agent_type int comment '经纪人类型(0:个人中介;1:品牌方;2:代运营公司)',
	agent_subtype int comment '经纪人子类型(0:未知;1:个人工作室;2:竞对;3:美饿京经理;4:相关业务个人;5:品牌代运营;6:散店代运营;7:招商公司;8:个人;9:分公司;10:总部)',
	agent_cls int comment '经纪人分类(0:未知;1:个人;2:个体户;3:公司)',
	sign_status int comment '签约状态(0:未签约;1:签约中;2:已签约;3:已解约;98:未签约)',
	sign_process_id int comment '签约流程ID',
	agent_wechat_id varchar(128) comment '经纪人微信号',
	extra_remark varchar(512) comment '补充说明',
	agent_license_pic_url varchar(255) comment '经纪人营业执照图片URL',
	agent_company varchar(64) comment '经纪人公司名称',
	agent_unified_social_credit_id varchar(64) comment '经纪人统一社会信用代码',
	agent_legal_person varchar(32) comment '经纪人法人',
	agent_register_address varchar(64) comment '经纪人注册地址',
	payee_name varchar(32) comment '收款方姓名',
	payee_account varchar(32) comment '收款方账号',
	payee_bank varchar(32) comment '收款方开户行',
	contract_no varchar(128) comment '合同编号',
	contract_begin_time datetime comment '合同开始时间',
	contract_end_time datetime comment '合同结束时间',
	company_name varchar(128) comment '公司名称',
	company_position varchar(64) comment '职位',
	guarantee_newstore_num int comment '保底新增店铺',
	guarantee_quota int comment '保底份额',
	audit_pic_url varchar(512) comment '申请图片URL',
	status int comment '经纪人状态(0:待审核;1:审核通过;2:审核驳回;3:取消经纪人)',
	create_time2 datetime comment '创建时间',
	audit_time datetime comment '提交审核时间',
	audit_finish_time datetime comment '审核完成时间',
	remark varchar(256) comment '备注',
	is_del int comment '是否删除(0:否;1:是)',
	creator_id int comment '创建人ID',
	auditor_id int comment '审核人ID',
	account_balance decimal(12,2) comment '账户余额(元)',
	profit_limit_less int comment '小于 30 的利润限制',
	profit_limit_greater int comment '大于 30 的利润限制',
	is_sign_cloud_payment int comment '是否签约云支付(0:否;1:是)',
	withdrawal_amt decimal(12,2) comment '提现金额(元)',
	frozen_amt decimal(12,2) comment '冻结金额(元)',
	is_frozen_account int comment '是否冻结账户(0:否;1:是)',
	daily_withdrawal_amt int comment '日提现金额',
	monthly_withdrawal_amt int comment '月提现金额',
	currentday_withdrawal_cnt int comment '当日提现次数',
	latest_withdrawal_time datetime comment '最近一次提现时间',
	is_limit_withdrawal int comment '是否限制提现(0:否;1:是)',
	new_remarks varchar(512) comment '新备注',
	attachment_list varchar(65533) comment '附件列表'
) ENGINE=OLAP
PRIMARY KEY(dt,auto_id)
COMMENT "外卖经纪人账户"
DISTRIBUTED BY HASH(dt,auto_id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);




drop table if exists dwd.dwd_sr_user_block_record;

CREATE TABLE dwd.dwd_sr_user_block_record (
	auto_id bigint not null comment '自增ID',
	user_id int comment '用户ID',
	create_time datetime comment '创建时间',
	update_time datetime comment '更新时间',
	block_type int comment '拉黑类型(1:直营;2:专版)',
	remark varchar(512) comment '备注',
	operator_id int comment '操作人ID',
	duration int comment '时长(单位:秒;-1:永久拉黑)',
	status int comment '状态(2:解除拉黑;1:拉黑)'
) ENGINE=OLAP
UNIQUE KEY(auto_id,user_id)
COMMENT "用户拉黑记录"
DISTRIBUTED BY HASH(auto_id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "2"
);


drop table if exists dwd.dwd_sr_order_ai_call_log;

CREATE TABLE if not exists dwd.dwd_sr_order_ai_call_log (
	auto_id bigint not null comment '自增ID',
	create_time datetime comment '创建时间',
	update_time datetime comment '更新时间',
	user_id int comment '用户ID',
	phone varchar(15) comment '手机号',
	order_id varchar(50) comment '订单ID',
	call_status int comment '通话状态(0:成功;1:内部错误;2:参数错误)',
	push_info varchar(65533) comment '推送信息',
	source_type int comment '渠道类型(0:超时;1:复活;2:拒绝)',
	bwc_type int comment '霸王餐类型(0:站内;1:专版)'
) ENGINE=OLAP
PRIMARY KEY(auto_id,create_time)
COMMENT "AI外呼订单记录"
DISTRIBUTED BY HASH(auto_id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "3"
);


ALTER TABLE table_name CHANGE COLUMN column_name column_name data_type COMMENT 'new_comment';

drop table if exists temp.temp_sr_ad_marketing_automation_envelope_coupons_log;

CREATE TABLE if not exists `temp.temp_sr_ad_marketing_automation_envelope_coupons_log` (
  `id` bigint NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `plan_id` bigint DEFAULT NULL,
  `experiment_group_id` bigint DEFAULT NULL,
  `type` bigint DEFAULT NULL,
  `envelope_type` bigint DEFAULT NULL,
  `envelope_id` bigint DEFAULT NULL,
  `threshold_type` bigint DEFAULT NULL,
  `envelope_threshold` varchar(255) DEFAULT NULL,
  `discount` varchar(255) DEFAULT NULL,
  `discount_amount` varchar(255) DEFAULT NULL,
  `envelope_amount` varchar(255) DEFAULT NULL,
  `envelope_count` bigint DEFAULT NULL,
  `create_user` varchar(255) DEFAULT NULL,
  `update_user` varchar(255) DEFAULT NULL,
  `create_id` bigint DEFAULT NULL,
  `update_id` bigint DEFAULT NULL,
  `is_del` int DEFAULT NULL,
  `user_red_pack_id` bigint DEFAULT NULL,
  `record_id` bigint DEFAULT NULL,
  `silk_id` bigint DEFAULT NULL,
  `coupons_id` bigint DEFAULT NULL,
  `event_id` bigint DEFAULT NULL COMMENT '事件ID'
) ENGINE=OLAP
PRIMARY KEY(id)
COMMENT "MA策略红包触达日志"
DISTRIBUTED BY HASH(id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "3"
);


drop table if exists temp.temp_sr_ad_marketing_automation_envelope_coupons;

CREATE TABLE if not exists `temp.temp_sr_ad_marketing_automation_envelope_coupons` (
  `id` bigint NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `plan_id` bigint DEFAULT NULL,
  `experiment_group_id` bigint DEFAULT NULL,
  `type` bigint DEFAULT NULL,
  `is_sign` bigint DEFAULT NULL,
  `sign_value` varchar(255) DEFAULT NULL,
  `envelope_type` bigint DEFAULT NULL,
  `envelope_id` bigint DEFAULT NULL,
  `threshold_type` bigint DEFAULT NULL,
  `envelope_threshold` varchar(255) DEFAULT NULL,
  `discount` varchar(255) DEFAULT NULL,
  `discount_amount` varchar(255) DEFAULT NULL,
  `envelope_amount_type` bigint DEFAULT NULL,
  `envelope_amount_min` varchar(255) DEFAULT NULL,
  `envelope_amount_max` varchar(255) DEFAULT NULL,
  `envelope_count_type` bigint DEFAULT NULL,
  `envelope_count_min` bigint DEFAULT NULL,
  `envelope_count_max` bigint DEFAULT NULL,
  `day_limit` bigint DEFAULT NULL,
  `day_surplus_count` bigint DEFAULT NULL,
  `total_count` bigint DEFAULT NULL,
  `day_total_surplus_count` bigint DEFAULT NULL,
  `create_user` varchar(255) DEFAULT NULL,
  `update_user` varchar(255) DEFAULT NULL,
  `create_id` bigint DEFAULT NULL,
  `update_id` bigint DEFAULT NULL,
  `is_del` int DEFAULT NULL
  ) ENGINE=OLAP
PRIMARY KEY(id)
COMMENT "MA策略红包"
DISTRIBUTED BY HASH(id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "3"
);
















ALTER TABLE dwd.dwd_sr_order_ai_call_log
MODIFY COLUMN call_status int COMMENT '通话状态(0:已拨打;1:已接通;2:失败)';


ALTER TABLE dim.dim_silkworm_redpack
ADD COLUMN interior_name varchar(64) COMMENT '内部名称';




drop table if exists dim.dim_silkworm_redpack;

CREATE TABLE if not exists dim.dim_silkworm_redpack(
`redpacket_id` bigint(20) NOT NULL COMMENT "红包ID",
`create_time` datetime NULL COMMENT "创建时间",
`update_time` datetime NULL COMMENT "更新时间",
`delete_time` datetime NULL COMMENT "删除时间",
`redpacket_name` varchar(65533) NULL COMMENT "红包名称",
`redpacket_desc` varchar(65533) NULL COMMENT "红包说明",
`begin_time` varchar(65533) NULL COMMENT "红包有效期开始时间(默认0:表示动态有效期,非0:表示固定有效期)",
`end_time` varchar(65533) NULL COMMENT "红包有效期结束时间(当begin_time等于0,是动态有效期时间跨度,反之是固定有效期结束时间)",
`redpacket_type` int(11) NULL COMMENT "红包类型(1:小蚕红包,2:拼手气红包,3:红包雨抽奖,4:积分兑换,5:用户召回活动,6:会员限时升级礼包,7:会员每日红包活动,8:挑战赛,9:抽奖活动,10:春节签到领红包(已下线),11:淘趣用户注册领取红包,12:嗨皮用户注册领取红包,13:新用户下单奖励红包,14:社群晒图,15:团长包红包,16:工单发放红包,17:探店单单返发放红包,18:MA发红包,20:周年庆每日领红包,21:周年庆猜一猜)",
`validterm_type` int(11) NULL COMMENT "有效期类型(1;固定有效期,2:动态有效期)",
`use_type` int(11) NULL COMMENT "使用类型(1:有门槛,2:无门槛)",
`redpacket_status` int(11) NULL COMMENT "红包状态(1:上线,2:下线)",
`rebate_threshold` decimal(12, 2) NULL COMMENT "返利门槛值",
`is_use_limit` int(11) NULL COMMENT "是否有使用限制(0:否,1:是)",
`redpacket_tag_url` varchar(65533) NULL COMMENT "红包标签URL",
`redpacket_jump_url` varchar(65533) NULL COMMENT "红包跳转URL",
`redpacket_cover_url` varchar(65533) NULL COMMENT "红包封面URL",
`creator_id` int(11) NULL COMMENT "创建人ID",
`creator_name` varchar(65533) NULL COMMENT "创建人姓名",
`latest_editor_id` int(11) NULL COMMENT "最近一次编辑人ID",
`latest_editor_name` varchar(65533) NULL COMMENT "最近一次编辑人姓名",
`business_type` int(11) NULL COMMENT "业务线(0:霸王餐;1:砍价;2:探店)",
`discount_type` int(11) NULL COMMENT "折扣类型(0:具体金额;1:打折)",
`interior_name` varchar(64) COMMENT '内部名称'
) ENGINE=OLAP 
PRIMARY KEY(`redpacket_id`)
COMMENT "蚕豆红包"
DISTRIBUTED BY HASH(`redpacket_id`)
ORDER BY(`redpacket_id`)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"labels.location" = "*",
"replicated_storage" = "true",
"replication_num" = "3"
);


CREATE TABLE  if not exists ads.ads_sr_traffic_dau_d(
	`statistics_date`  DATE  NOT NULL COMMENT '统计日期',
	`cate2_index` varchar(30) NOT NULL COMMENT '二级指标',
	`sub_cate2_index` varchar(30) NOT NULL COMMENT '次二级指标',
	`sub_cate2_index_value` decimal(12,5) NOT NULL COMMENT '次二级指标值'
) ENGINE=OLAP
PRIMARY KEY (statistics_date,cate2_index,sub_cate2_index)
COMMENT "分日DAU构成"
DISTRIBUTED BY HASH(statistics_date)
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "replicated_storage" = "true",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);




CREATE TABLE IF NOT EXISTS ads.ads_sr_user_signup_usernum_d
(
    `dt`  DATE    NOT NULL COMMENT '日期',
    `register_user_num` BIGINT NOT NULL COMMENT '注册用户量',
    `acc_signup_user_num` BIGINT NOT NULL COMMENT '累计注册用户量',
    `acc_above4ord_user_num` BIGINT NOT NULL COMMENT '累计完单4单及以上用户量'
)
ENGINE=OLAP
PRIMARY KEY (dt)
COMMENT "每日累计注册用户量"
DISTRIBUTED BY HASH(dt)
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "replicated_storage" = "true",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);



drop table if exists dwd.dwd_sr_store_merchant_bill_push;

CREATE TABLE if not exists dwd.dwd_sr_store_merchant_bill_push (
	auto_id bigint not null comment '自增ID',
	create_time datetime comment '创建时间',
	update_time datetime comment '更新时间',
	wework_contact_id bigint comment '企微联系关系关系ID',
	bd_id bigint comment '商务ID',
	contact_id bigint comment '企微关联ID(vid/gid)',
	push_status int comment '推送状态(0:待推送;1:推送中;2:推送成功;3:推送失败)',
	push_unique_id varchar(16) comment '推送ID',
	fail_reason varchar(512) comment '推送失败原因',
	content json comment '发送内容',
	push_date date comment '推送日期',
	is_reminder int comment '是否催单(0:否;1:是)',
	bd_vid bigint comment '商务vid'
)
ENGINE=OLAP
PRIMARY KEY (auto_id)
COMMENT "商家结算单推送"
DISTRIBUTED BY HASH(dt)
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "replicated_storage" = "true",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);







drop table if exists temp.temp_sr_silkworm_explore_merchant_refusal_receive;

CREATE TABLE temp.temp_sr_silkworm_explore_merchant_refusal_receive (
  `auto_id` bigint NOT NULL COMMENT '主键ID',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `updated_at` datetime NOT NULL COMMENT '更新时间',
  `initiator` bigint NOT NULL DEFAULT '0' COMMENT '发起人',
  `admin_id` int NOT NULL DEFAULT '0' COMMENT '操作人id',
  `promotion_id` bigint NOT NULL DEFAULT '0' COMMENT '活动id',
  `bd_receiver` bigint NOT NULL DEFAULT '0' COMMENT 'bd受理人',
  `bd_superiors` bigint NOT NULL DEFAULT '0' COMMENT 'bd受理人上两级',
  `bd_team_id` bigint NOT NULL DEFAULT '0' COMMENT 'bd团队',
  `bd_team_name` varchar(20) NOT NULL DEFAULT '' COMMENT 'bd团队',
  `processing_time` bigint NOT NULL DEFAULT '0' COMMENT '受理时间',
  `legal_affairs_receiver` bigint NOT NULL DEFAULT '0' COMMENT '法务受理人',
  `decrement_receiver` bigint NOT NULL DEFAULT '0' COMMENT '减量受理人',
  `remark` varchar(300) NOT NULL DEFAULT '' COMMENT '备注',
  `transferee` bigint NOT NULL DEFAULT '0' COMMENT '转交人',
  `transferee_time` bigint NOT NULL DEFAULT '0' COMMENT '转交时间',
  `return_bd` bigint NOT NULL DEFAULT '0' COMMENT '退还人',
  `return_time` bigint NOT NULL DEFAULT '0' COMMENT '退还时间',
  `merchant_silk_id` int NOT NULL DEFAULT '0' COMMENT '商家id',
  `business_type` bigint NOT NULL DEFAULT '0' COMMENT '业务类型 1 砍价,2 探店',
  `contract_id` bigint NOT NULL DEFAULT '0' COMMENT '合约id',
  `processing_scheme` bigint NOT NULL DEFAULT '0' COMMENT '处理方案 1继续合作 2停止合作 3减量合作 4系统超时',
  `verify_end_time` bigint NOT NULL DEFAULT '0' COMMENT '核实结束时间',
  `processing_stage` bigint NOT NULL DEFAULT '0' COMMENT '处理阶段 1合作确认阶段，2法务违约处理阶段，3减量合作处理阶段，4已完结',
  `store_id` json NOT NULL COMMENT '店铺id',
  `proof` json NOT NULL COMMENT '沟通凭证',
  `tag` bigint NOT NULL DEFAULT '0' COMMENT '标签 1转交 2退还',
  `status` int NOT NULL DEFAULT '0' COMMENT '状态：1进行中 2已结束',
  `reason` varchar(300) NOT NULL DEFAULT '' COMMENT '商家不合作原因',
  `is_prosecute` int NOT NULL DEFAULT '0' COMMENT '状态：1符合，2不符合',
  `store_type` int NOT NULL DEFAULT '0' COMMENT '门店类型 1单门店 2连锁门店',
  `ad_confirm_id` int NOT NULL DEFAULT '0' COMMENT '广告投放确认人id',
  `ad_confirm_status` int NOT NULL DEFAULT '0' COMMENT '广告投放确认状态：0未确认 1已确认',
  `talent_confirm_id` int NOT NULL DEFAULT '0' COMMENT '达人商单确认人id',
  `talent_confirm_status` int NOT NULL DEFAULT '0' COMMENT '达人商单确认状态：0未确认 1已确认'
) 
ENGINE=OLAP
PRIMARY KEY (auto_id)
COMMENT "商家拒收处理表"
DISTRIBUTED BY HASH(auto_id)
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "replicated_storage" = "true",
    "enable_persistent_index" = "false",
    "compression" = "LZ4"
);








DROP TABLE IF EXISTS dim.dim_silkworm_rights_card;

CREATE TABLE IF NOT EXISTS dim.dim_silkworm_rights_card (
	card_id int comment '券ID',
	create_time datetime comment '创建时间',
	update_time datetime comment '更新时间',
	card_type int comment '券类型:(0:饭票,1:超前点单,2:1小时延时券,3:大牌专享券,4:半小时延时券,5:先享现金券,6:修改订单号券,7:订单复活券,8:VIP额外返利券,9:探店券,10:公益卡;11:探店砍价券;12:超前点单券-探店券;13:定向大牌券;14:免单券;15:免审券)',
	card_name varchar(128) comment '卡券名称',
	card_desc varchar(256) comment '卡券描述',
	card_pic_url varchar(256) comment '卡券图片URL',
	expire_type int comment '到期类型(0:当日过期;1:本周过期;2:本月过期;3:本年过期;4:特定时间后过期)',
	valid_secs int comment '有效期限(单位:秒,配合create_time使用)',
	creator_id int comment '后台创建人ID',
	card_limit json comment '卡券限制(extra_silk_radio:额外返利比例;dx_brands:定向大牌列表;bind_key_ids:绑定的key_id,比如活动id等;bind_promotion:绑定的活动名,可以创建卡券的时候设置,并且在使用的时候校验;categories:绑定品类列表)'
) ENGINE=OLAP 
PRIMARY KEY(card_id)
COMMENT "小蚕卡券"
DISTRIBUTED BY HASH(card_id)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4",
    "enable_persistent_index" = "true"
);





drop table if exists dws.dws_sr_traffic_homepage_mix_ascribe_d;

CREATE TABLE if not exists dws.dws_sr_traffic_homepage_mix_ascribe_d (
	statistics_date date not null comment '统计日期',
	county_id int not null comment '区县ID',
	platform_name varchar(20) not null comment '平台名称',
	app_version varchar(20) not null comment '版本',
	activity_type varchar(20) not null comment '活动类型',
	promotion_id int not null comment '活动ID',
	expouse_num bigint comment '曝光量',
	expouse_uids bitmap comment '曝光用户列表',
	clc_num bigint comment '点击量',
	clc_uids bitmap comment '点击用户列表',
	detailpage_pv bigint comment '详情页PV',
	detailpage_view_uids bitmap comment '详情页浏览用户列表',
	baoming_order_num bigint comment '小蚕报名订单量',
	baoming_uids bitmap comment '小蚕报名用户列表',
	valid_order_num bigint comment '小蚕有效订单量',
	valid_uids bitmap comment '小蚕有效用户列表',
	xx_baoming_order_num bigint comment '晓晓报名订单量',
	xx_baoming_uids bitmap comment '晓晓报名用户列表',
	xx_valid_order_num bigint comment '晓晓有效订单量',
	xx_valid_uids bitmap comment '晓晓有效用户列表'
)
ENGINE=OLAP
PRIMARY KEY (statistics_date,county_id,platform_name,app_version,activity_type,promotion_id)
COMMENT "首页融合归因日数据"
DISTRIBUTED BY HASH(statistics_date,)
PROPERTIES (
    "replication_num" = "3",
    "compression" = "LZ4"
);




select 
		  statistics_date,
		  sum(expouse_num) '曝光量',
		  bitmap_union_count(expouse_uids) '曝光用户量',
		  sum(clc_num) '点击量',
		  bitmap_union_count(clc_uids) '点击用户量',
		  sum(detailpage_pv) '详情页PV',
		  bitmap_union_count(detailpage_view_uids) '详情页浏览用户量',
		  sum(baoming_order_num) '小蚕报名订单量',
		  bitmap_union_count(baoming_uids) '小蚕报名用户量',
		  sum(valid_order_num) '小蚕有效订单量',
		  bitmap_union_count(valid_uids) '小蚕有效用户量',
		  sum(xx_baoming_order_num) '晓晓报名订单量',
		  bitmap_union_count(xx_baoming_uids) '晓晓报名用户量',
		  sum(xx_valid_order_num) '晓晓有效订单量',
		  bitmap_union_count(xx_valid_uids) '晓晓有效用户量'
from dws.dws_sr_traffic_homepage_mix_ascribe_d
where statistics_date='2025-12-23'
group by 1;



drop table if exists dwd.dwd_sr_market_user_pack;

CREATE TABLE if not exists dwd.dwd_sr_market_user_pack (
  `auto_id` bigint(20) NOT NULL COMMENT '自增ID',
  `dt` date NOT NULL COMMENT '日期',
  `create_time` datetime NULL COMMENT '创建时间',
  `update_time` datetime NULL COMMENT '更新时间',
  `user_id` int(11) NULL COMMENT '用户ID',
  `pack_id` int(11) NULL COMMENT '礼包ID',
  `city_id` int(11) NULL COMMENT '城市ID(4位)',
  `pack_name` varchar(256) NULL COMMENT '礼包名称',
  `pack_desc` varchar(256) NULL COMMENT '礼包描述',
  `pack_type` int(11) NULL COMMENT '礼包类型(0:新人注册;1:未完单;2:未登录;3:vip3;4:vip4;5:vip5;6:指定礼包;7:加群礼包;8:vip1;9:vip2;10:指定页面礼包;11:限时升级礼包;12:vip6;13:vip2plus;14:vip3plus;15:vip4plus;16:vip5plus;17:vip6plus;18:升级到vip2升级礼包;19:升级到vip3升级礼包;20:升级到vip4升级礼包;21:升级到vip5升级礼包;22:升级到vip6升级礼包;23:升级到vip2plus升级礼包;24:升级到vip3plus升级礼包;25:升级到vip4plus升级礼包;26:升级到vip5plus升级礼包;27:升级到vip6plus升级礼包)',
  `pack_icon_url` varchar(256) NULL COMMENT '礼包图片地址',
  `pack_detail` varchar(50000) NULL COMMENT '礼包商品',
  `get_time` datetime NULL COMMENT '领取时间',
  `is_get` int(11) NULL COMMENT '是否可领取(0:不可领取1:可领取)',
  `got_time` datetime NULL COMMENT '已领取时间',
  `city_group_id` int(11) NULL COMMENT '城市组',
  `pack_level` int(11) NULL COMMENT '礼包等级',
  `pack_productid_list` varchar(50000) NULL COMMENT '礼包商品ID列表',
  `show_time` datetime NULL COMMENT '前端展示领取动画时间',
  `pack_invalid_time` datetime NULL COMMENT '礼包失效时间'
) ENGINE=OLAP 
PRIMARY KEY(`auto_id`, `dt`)
COMMENT '用户礼包'
PARTITION BY date_trunc('year', dt)
DISTRIBUTED BY HASH(`auto_id`, `dt`)
PROPERTIES (
'compression' = 'LZ4',
'enable_persistent_index' = 'true',
'fast_schema_evolution' = 'true',
'replicated_storage' = 'true',
'replication_num' = '3'
);





drop table if exists dwd.dwd_sr_silkworm_explore_note_reward;

CREATE TABLE dwd.dwd_sr_silkworm_explore_note_reward (
		auto_id bigint not null comment '自增ID',
		create_time datetime comment '创建时间',
		update_time datetime comment '更新时间',
		activity_code varchar(64) comment '活动编码',
		order_id varchar(256) comment '订单号',
		user_id int comment '用户ID',
		promotion_id int comment '活动ID',
		note_auto_id int comment '笔记自增ID(和笔记上传记录表自增ID关联)',
		is_fit_activity int comment '笔记是否符合活动(0:否;1:是)',
		topic_match_type int comment '话题匹配方式(0:无;1:APP精确;2:OCR模糊)',
		quality_tag_id int comment '笔记得分tag',
		rdp_status int comment '红包状态(0:未发;1:发放中;2:已发;3:失败)',
		rdp_grant_time datetime comment '红包发放时间',
		rdp_template_id int comment '红包模板ID',
		rdp_amt decimal(12,2) comment '红包金额',
		rdp_record_id int comment '红包明细ID',
		good_reward_status int comment '良好奖励状态(0:未发;1:发放中;2:已发;3:失败)',
		good_reward_time datetime comment '良好奖励发放时间',
		good_reward_card_template_id int comment '良好奖励卡模板ID',
		good_reward_user_card_id int comment '良好奖励用户卡ID',
		excellent_reward_status int comment '良好奖励状态(0:未发;1:发放中;2:已发;3:失败)',
		excellent_reward_time datetime comment '良好奖励发放时间',
		excellent_reward_card_template_id int comment '良好奖励卡模板ID',
		excellent_reward_user_card_id int comment '良好奖励用户卡ID',
		badnote_message_status int comment '差笔记站内信状态(0:未发;1:发放中;2:已发;3:失败)',
		badnote_message_send_time datetime comment '差笔记站内信发送时间'
) ENGINE=OLAP
PRIMARY KEY(`auto_id`)
COMMENT "探店活动笔记奖励"
DISTRIBUTED BY HASH(`auto_id`)
PROPERTIES (
'compression' = 'LZ4',
'enable_persistent_index' = 'true',
'fast_schema_evolution' = 'true',
'replicated_storage' = 'true',
'replication_num' = '3'
);






drop table if exists ads.ads_sr_market_explore_excellent_note_statis_d;

CREATE TABLE ads.ads_sr_market_explore_excellent_note_statis_d (
		statistics_date date comment '统计日期',
		city_name varchar(100) comment '城市',
		user_type varchar(10) comment '用户类型',
		pv int comment 'PV',
		uv int comment 'UV',
		note_user_num int comment '参与用户量',
		finord_num int comment '完单量',
		youzhi_note_num int comment '优质笔记数',
		pubnote_num int comment '发布笔记数',
		excellent_note_num int comment '优秀笔记数',
		good_note_num int comment '良好笔记数',
		normal_note_num int comment '普通笔记数',
		excellent_note_user_num int comment '优秀创作者数',
		first_excellent_note_user_num int comment '新优秀创作者数',
		finord_user_num int comment '新用户数',
		explore_uv int comment '探店UV',
		baoming_user_num int comment '下单用户量',
		verify_user_num int comment '核销用户量',
		pubnote_user_num int comment '发布笔记用户量',
		youzhi_note_user_num int comment '优质笔记用户量',
		rdp_grant_num int comment '红包发放量',
		rdp_used_num int comment '红包使用量',
		rdp_used_amt decimal(12,2) comment '红包使用金额',
		excellen_grant_num int comment '优秀免单卡发放量',
		good_grant_num int comment '良好免单卡发放量',
		excellen_used_num int comment '优秀免单卡使用量',
		good_used_num int comment '良好免单卡使用量',
		excellen_used_amt decimal(12,2) comment '优秀免单卡使用金额',
		good_used_amt decimal(12,2) comment '良好免单卡使用金额',
		excellen_verify_amt decimal(12,2) comment '优秀免单卡核销金额',
		good_verify_am decimal(12,2) comment '良好免单卡核销金额'

) ENGINE=OLAP
PRIMARY KEY(statistics_date,city_name,user_type)
COMMENT "探店好笔记活动日数据"
DISTRIBUTED BY HASH(statistics_date)
PROPERTIES (
'compression' = 'LZ4',
'enable_persistent_index' = 'true',
'fast_schema_evolution' = 'true',
'replicated_storage' = 'true',
'replication_num' = '3'
);



drop table if exists dwd.dwd_sr_user_candou_exchange_record;

CREATE TABLE dwd.dwd_sr_user_candou_exchange_record (
		auto_id bigint not null comment '自增ID',
		create_time datetime comment '创建时间',
		update_time datetime comment '更新时间',
		user_id int comment '用户ID',
		exchange_id varchar(256) comment '兑换记录唯一凭证',
		fulu_order_id varchar(256) comment '福禄订单ID',
		product_id bigint comment '商品ID',
		amt decimal(12,2) comment '兑换金额',
		fail_reason varchar(256) comment '兑换失败原因',
		card_type int comment '卡类型(0:普通卡密;1:二维码;2:短链.当商品类型是卡密时,卡类型只会是0,不会出现1和2;只有当商品类型是直充时,才会出现这三种类型)',
		card_no varchar(256) comment '兑换卡号',
		card_pwd varchar(256) comment '兑换卡密',
		exg_deadline_time datetime comment '兑换截止时间',
		exg_create_time datetime comment '兑换创建时间',
		exg_finish_time datetime comment '兑换完成时间',
		status int comment '兑换状态(1:兑换中;2:充值成功;3:充值失败)',
		sr_id bigint comment '蚕豆扣款记录唯一凭证,退款时使用'
) ENGINE=OLAP
PRIMARY KEY(`auto_id`)
COMMENT "用户蚕豆兑换记录"
DISTRIBUTED BY HASH(`auto_id`)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "3"
);







drop table if exists dim.dim_candou_exchange_product;

CREATE TABLE if not exists dim.dim_candou_exchange_product (
		product_id bigint comment '商品ID',
		create_time datetime comment '创建时间',
		update_time datetime comment '更新时间',
		fulu_product_id int comment '福禄商品ID',
		product_name varchar(128) comment '商品名称',
		product_icon_pic_url varchar(128) comment '商品图标',
		product_amt decimal(12,2) comment '商品金额',
		status int comment '商品状态(1:在线)',
		weight int comment '商品权重排序'
) ENGINE=OLAP
PRIMARY KEY(product_id)
COMMENT "蚕豆兑换商品"
DISTRIBUTED BY HASH(product_id)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "3"
);





CREATE TABLE ads_sr_traffic_monitor_h (
  `stat_hour` datetime NOT NULL COMMENT "统计小时（精确到小时）",
  `event` varchar(300) NOT NULL COMMENT "事件名称",
  `platform_name` varchar(50) NOT NULL COMMENT "平台名称（Android/iOS/H5/微信小程序）",
  `app_version` varchar(25) NOT NULL COMMENT "应用版本",
  `event_count` bigint(20) NOT NULL COMMENT "事件数量",
  `user_count` bigint(20) NOT NULL COMMENT "用户数（去重）",
  `prev_day_count` bigint(20) NULL COMMENT "昨日同时段事件数量",
  `prev_week_count` bigint(20) NULL COMMENT "上周同日同时段事件数量",
  `day_over_day_change_rate` decimal(8, 2) NULL COMMENT "天环比变化率（百分比）",
  `week_over_week_change_rate` decimal(8, 2) NULL COMMENT "周环比变化率（百分比）",
  `day_alert_level` varchar(20) NULL COMMENT "天环比告警级别（P1危险/P2严重/P3异常/无对比数据）",
  `week_alert_level` varchar(20) NULL COMMENT "周环比告警级别（P1危险/P2严重/P3异常/无对比数据）",
  `final_alert_level` varchar(20) NULL COMMENT "综合告警级别（P1危险/P2严重/P3异常/无对比数据）",
  `missing_keywords_count` bigint(20) NULL COMMENT "搜索关键词缺失数量（仅搜索事件有效）",
  `missing_keywords_ratio` decimal(8, 2) NULL COMMENT "搜索关键词缺失率（百分比）",
  `missing_alert_level` varchar(20) NULL COMMENT "缺失值告警级别（P1危险/P2严重/P3异常/正常）",
  `create_time` datetime NOT NULL COMMENT "数据创建时间"
) ENGINE=OLAP 
PRIMARY KEY(`stat_hour`, `event`, `platform_name`, `app_version`)
COMMENT "埋点质量监控小时表"
DISTRIBUTED BY HASH(`stat_hour`, `event`)
PROPERTIES (
"compression" = "LZ4",
"enable_persistent_index" = "true",
"fast_schema_evolution" = "false",
"replicated_storage" = "true",
"replication_num" = "3"
);









