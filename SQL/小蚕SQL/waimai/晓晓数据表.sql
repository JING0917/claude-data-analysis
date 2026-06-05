-- 晓晓店铺数据表:dim.dim_dinedash_store（数据实时更新）
-- 字段名注释

"CREATE TABLE `dim_dinedash_store` (
  `id` bigint(20) NOT NULL COMMENT ""自增ID"",
  `created_at` datetime NULL COMMENT ""创建时间"",
  `updated_at` datetime NULL COMMENT ""更新时间"",
  `platform_uid` int(11) NOT NULL DEFAULT ""0"" COMMENT ""开放平台id"",
  `platform_user_id` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""平台侧商家id"",
  `platform_store_id` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""平台侧店铺id"",
  `silk_id` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""商家小蚕id"",
  `meituan_name` varchar(65533) NOT NULL DEFAULT """" COMMENT ""默认店铺名（美团）"",
  `eleme_name` varchar(65533) NOT NULL DEFAULT """" COMMENT ""饿了么店铺名"",
  `jd_name` varchar(65533) NOT NULL DEFAULT """" COMMENT ""京东店铺名"",
  `longitude` double NOT NULL DEFAULT ""0"" COMMENT ""经度"",
  `latitude` double NOT NULL DEFAULT ""0"" COMMENT ""纬度"",
  `province` varchar(65533) NOT NULL DEFAULT """" COMMENT ""省份"",
  `city` varchar(65533) NOT NULL DEFAULT """" COMMENT ""城市"",
  `district` varchar(65533) NOT NULL DEFAULT """" COMMENT ""区/县"",
  `address` varchar(65533) NOT NULL DEFAULT """" COMMENT ""地址"",
  `address_detail` varchar(65533) NOT NULL DEFAULT """" COMMENT ""详细地址"",
  `contact_name` varchar(65533) NOT NULL DEFAULT """" COMMENT ""联系人"",
  `contact_phone` varchar(65533) NOT NULL DEFAULT """" COMMENT ""联系电话"",
  `opening_hours` varchar(65533) NOT NULL DEFAULT """" COMMENT ""营业时间"",
  `license` varchar(65533) NOT NULL DEFAULT """" COMMENT ""营业执照"",
  `icon` varchar(65533) NOT NULL DEFAULT """" COMMENT ""店铺LOGO"",
  `brand` varchar(65533) NOT NULL DEFAULT """" COMMENT ""品牌名"",
  `create_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""创建时间（时间戳）"",
  `status` int(11) NOT NULL DEFAULT ""0"" COMMENT ""状态"",
  `reason` varchar(65533) NOT NULL DEFAULT """" COMMENT ""驳回原因"",
  `category_type` int(11) NOT NULL DEFAULT ""0"" COMMENT ""分类类型"",
  `category_sub_type` int(11) NOT NULL DEFAULT ""0"" COMMENT ""子分类类型"",
  `store_info` varchar(65533) NULL COMMENT ""店铺信息"",
  `admin_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""后台审核人ID"",
  `bd_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商务负责人ID"",
  `promotion_number` int(11) NOT NULL DEFAULT ""0"" COMMENT ""店铺活动数量"",
  `first_promotion_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""首次活动时间（时间戳）"",
  `last_promotion_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""最后活动发布时间（时间戳）"",
  `first_order_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""首次订单时间（时间戳）"",
  `ad_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""地区编码"",
  `city_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""城市编码"",
  `deleted_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""删除时间（时间戳）"",
  `store_brand_type` int(11) NOT NULL DEFAULT ""0"" COMMENT ""店铺品牌类型"",
  `delivery_mode` int(11) NOT NULL DEFAULT ""0"" COMMENT ""配送方式"",
  `category` varchar(65533) NULL COMMENT ""小蚕店铺分类""
) ENGINE=OLAP 
PRIMARY KEY(`id`)
COMMENT ""霸王餐店铺表""
DISTRIBUTED BY HASH(`id`)
PROPERTIES (
""compression"" = ""LZ4"",
""enable_persistent_index"" = ""true"",
""fast_schema_evolution"" = ""true"",
""replicated_storage"" = ""true"",
""replication_num"" = ""3""
);"


-- 晓晓活动数据表:dwd.dwd_dinedash_store_promotion（数据实时更新）
-- 字段名注释
"CREATE TABLE `dwd_dinedash_store_promotion` (
  `id` bigint(20) NOT NULL COMMENT ""自增ID"",
  `created_at` datetime NULL COMMENT ""创建时间"",
  `updated_at` datetime NULL COMMENT ""更新时间"",
  `silk_id` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""商家小蚕id"",
  `store_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""店铺ID"",
  `store_name` varchar(65533) NOT NULL DEFAULT """" COMMENT ""店铺名"",
  `longitude` double NOT NULL DEFAULT ""0"" COMMENT ""经度"",
  `latitude` double NOT NULL DEFAULT ""0"" COMMENT ""纬度"",
  `store_platform` int(11) NOT NULL DEFAULT ""0"" COMMENT ""三方平台"",
  `rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商家支付返利"",
  `order_money` int(11) NOT NULL DEFAULT ""0"" COMMENT ""订单金额要求"",
  `user_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""用户返积分"",
  `number` int(11) NOT NULL DEFAULT ""0"" COMMENT ""美团活动名额数量"",
  `left_number` int(11) NOT NULL DEFAULT ""0"" COMMENT ""美团剩余名额数量"",
  `joined_number` int(11) NOT NULL DEFAULT ""0"" COMMENT ""美团待上传数量"",
  `pending_number` int(11) NOT NULL DEFAULT ""0"" COMMENT ""美团待审核数量"",
  `completed_number` int(11) NOT NULL DEFAULT ""0"" COMMENT ""美团完成数量"",
  `estimated_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商家预计返利"",
  `actual_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商家实际支付返利金额"",
  `return_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""中途结算，返还余额"",
  `left_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""最终结算，结余"",
  `profit` int(11) NOT NULL DEFAULT ""0"" COMMENT ""利润"",
  `original_actual_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商家实际支付返利(后台计算所得)"",
  `modify_actual_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""修改商家实际支付返利"",
  `modify_actual_rebate_reason` varchar(65533) NOT NULL DEFAULT """" COMMENT ""修改实际返利原因"",
  `modify_actual_rebate_status` int(11) NOT NULL DEFAULT ""0"" COMMENT ""修改返利金额状态"",
  `start_date` varchar(65533) NOT NULL DEFAULT """" COMMENT ""活动开始日期"",
  `end_date` varchar(65533) NOT NULL DEFAULT """" COMMENT ""活动结束日期"",
  `start_time` varchar(65533) NOT NULL DEFAULT """" COMMENT ""活动开始时间"",
  `end_time` varchar(65533) NOT NULL DEFAULT """" COMMENT ""活动结束时间"",
  `start_timestamp` int(11) NOT NULL DEFAULT ""0"" COMMENT ""活动开始时间戳"",
  `end_timestamp` int(11) NOT NULL DEFAULT ""0"" COMMENT ""活动结束时间戳"",
  `rebate_condition` int(11) NOT NULL DEFAULT ""0"" COMMENT ""返利条件"",
  `rebate_condition_str` varchar(65533) NOT NULL DEFAULT """" COMMENT ""返利条件描述"",
  `promotion_extra` varchar(65533) NULL COMMENT ""参与活动条件"",
  `search_detail` varchar(65533) NULL COMMENT ""搜索详情"",
  `remark` varchar(65533) NOT NULL DEFAULT """" COMMENT ""活动外显备注"",
  `status` int(11) NOT NULL DEFAULT ""0"" COMMENT ""活动状态"",
  `pay_status` int(11) NOT NULL DEFAULT ""0"" COMMENT ""付款状态"",
  `pay_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""付款时间（时间戳）"",
  `pay_way` varchar(65533) NOT NULL DEFAULT """" COMMENT ""付款方式"",
  `reason` varchar(65533) NOT NULL DEFAULT """" COMMENT ""驳回原因"",
  `admin_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""后台创建人ID"",
  `bd_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商务负责人ID"",
  `ad_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""地区编码"",
  `city_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""城市编码"",
  `bd_remark` varchar(65533) NOT NULL DEFAULT """" COMMENT ""bd备注"",
  `bill_pics` varchar(65533) NULL COMMENT ""后台结账图片"",
  `bill_remark` varchar(65533) NOT NULL DEFAULT """" COMMENT ""后台结账备注"",
  `reduce_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""订单扣减金额"",
  `tags` varchar(65533) NULL COMMENT ""活动标签"",
  `audit_admin_id` int(11) NULL COMMENT ""后台审核人"",
  `invoice_type` int(11) NULL COMMENT ""发票类型"",
  `affiliate` int(11) NULL COMMENT ""发票关联公司"",
  `invoice_amount` int(11) NULL COMMENT ""商家支付发票金额""
) ENGINE=OLAP 
PRIMARY KEY(`id`)
COMMENT ""霸王餐店铺活动表""
DISTRIBUTED BY HASH(`id`)
PROPERTIES (
""compression"" = ""LZ4"",
""enable_persistent_index"" = ""true"",
""fast_schema_evolution"" = ""true"",
""replicated_storage"" = ""true"",
""replication_num"" = ""3""
);"


-- 晓晓订单数据表:dwd.dwd_dinedash_promotion_order（数据实时更新）
-- 字段名注释
"CREATE TABLE `dwd_dinedash_promotion_order` (
  `created_at` datetime NOT NULL COMMENT ""创建时间"",
  `id` bigint(20) NOT NULL COMMENT ""自增ID"",
  `updated_at` datetime NULL COMMENT ""更新时间"",
  `order_id_str` varchar(65533) NOT NULL DEFAULT """" COMMENT ""订单字符串ID"",
  `order_log` varchar(65533) NULL COMMENT ""订单日志"",
  `silk_id` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""用户小蚕id"",
  `merchant_silk_id` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""商家小蚕id"",
  `store_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""店铺ID"",
  `promotion_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""活动ID"",
  `store_platform` int(11) NOT NULL DEFAULT ""0"" COMMENT ""店铺所属平台"",
  `rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商家返利"",
  `order_money` int(11) NOT NULL DEFAULT ""0"" COMMENT ""平台订单金额要求"",
  `user_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""用户返最终积分"",
  `original_user_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""用户返原始积分"",
  `reduce_user_rebate` int(11) NOT NULL DEFAULT ""0"" COMMENT ""用户扣除积分"",
  `order_time` bigint(20) NOT NULL DEFAULT ""0"" COMMENT ""下单时间（时间戳）"",
  `rebate_condition` int(11) NOT NULL DEFAULT ""0"" COMMENT ""返利条件"",
  `rebate_condition_str` varchar(65533) NOT NULL DEFAULT """" COMMENT ""返利条件描述"",
  `platform_order_id` varchar(65533) NOT NULL DEFAULT """" COMMENT ""平台订单id"",
  `platform_order_time` varchar(65533) NOT NULL DEFAULT """" COMMENT ""平台订单下单时间"",
  `platform_order_total_price` double NOT NULL DEFAULT ""0"" COMMENT ""平台订单下单金额"",
  `platform_order_store_name` varchar(65533) NOT NULL DEFAULT """" COMMENT ""平台订单店铺名"",
  `platform_order_status` int(11) NOT NULL DEFAULT ""0"" COMMENT ""平台订单状态"",
  `platform_order_screenshot` varchar(65533) NULL COMMENT ""平台订单截图"",
  `platform_evaluation_screenshot` varchar(65533) NULL COMMENT ""平台评价截图"",
  `order_client_platform` int(11) NOT NULL DEFAULT ""0"" COMMENT ""下单平台"",
  `upload_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""用户上传时间（时间戳）"",
  `reviewed_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""审核完成时间（时间戳）"",
  `platform_pic_ocr_result` varchar(65533) NULL COMMENT ""订单截图OCR识别结果"",
  `if_platform_pic_check_success` int(11) NOT NULL DEFAULT ""0"" COMMENT ""是否订单识别成功（0-否，1-是）"",
  `evaluation_pic_ocr_result` varchar(65533) NULL COMMENT ""评价截图OCR识别结果"",
  `if_evaluation_pic_check_success` int(11) NOT NULL DEFAULT ""0"" COMMENT ""是否评价截图识别成功（0-否，1-是）"",
  `platform_order_detail` varchar(65533) NULL COMMENT ""平台订单详情"",
  `order_process_detail` varchar(65533) NULL COMMENT ""订单流程详情"",
  `order_type` int(11) NOT NULL DEFAULT ""0"" COMMENT ""订单类型"",
  `status` int(11) NOT NULL DEFAULT ""0"" COMMENT ""订单状态"",
  `timeout_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""超时时间（时间戳）"",
  `broker_msg_id` varchar(65533) NOT NULL DEFAULT """" COMMENT ""超时消息ID"",
  `notify_time` int(11) NOT NULL DEFAULT ""0"" COMMENT ""提醒时间（时间戳）"",
  `opr_broker_msg_id` varchar(65533) NOT NULL DEFAULT """" COMMENT ""操作消息ID"",
  `user_remark` varchar(65533) NOT NULL DEFAULT """" COMMENT ""用户备注"",
  `reason` varchar(65533) NOT NULL DEFAULT """" COMMENT ""驳回原因"",
  `modify_reason` varchar(65533) NOT NULL DEFAULT """" COMMENT ""修改积分原因"",
  `admin_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""后台审核人ID"",
  `profit` int(11) NOT NULL DEFAULT ""0"" COMMENT ""订单利润"",
  `ad_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""地区编码"",
  `city_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""城市编码"",
  `user_city_code` int(11) NOT NULL DEFAULT ""0"" COMMENT ""用户所在城市编码"",
  `bd_id` int(11) NOT NULL DEFAULT ""0"" COMMENT ""商务负责人ID"",
  `kf_remark` varchar(65533) NOT NULL DEFAULT """" COMMENT ""客服备注"",
  `if_user_deleted` int(11) NOT NULL DEFAULT ""0"" COMMENT ""是否用户侧删除（0-否，1-是）""
) ENGINE=OLAP 
PRIMARY KEY(`created_at`, `id`)
COMMENT ""霸王餐活动订单表""
DISTRIBUTED BY HASH(`id`)
PROPERTIES (
""compression"" = ""LZ4"",
""enable_persistent_index"" = ""true"",
""fast_schema_evolution"" = ""true"",
""replicated_storage"" = ""true"",
""replication_num"" = ""3""
);"






