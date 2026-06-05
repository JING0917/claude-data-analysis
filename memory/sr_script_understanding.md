---
name: 小蚕SQL脚本理解
description: 对20250901_manuscript.sql脚本中业务逻辑、数据表和指标的综合理解
type: project
---

# StarRocks SQL脚本分析总结

## 脚本概述
文件名：20250901_manuscript.sql
文件位置：[SQL/小蚕SQL/20250901_manuscript.sql](SQL/小蚕SQL/20250901_manuscript.sql)
内容：综合业务分析脚本，包含多个独立查询模块，用于日常数据分析和监控

## 主要业务模块

### 1. 营销活动分析
#### 1.1 复活券支出统计
- **业务目的**：统计复活券的发放、使用、订单和补贴金额
- **涉及表**：
  - `test.test_sr_ad_marketing_automation_strategy_exec_log`（策略执行日志）
  - `dwd.dwd_sr_market_rights_card`（权益卡使用记录）
  - `dwd.dwd_sr_order_promotion_order`（促销订单）
- **关键字段**：
  - `strategy_id`（策略ID，如3446）
  - `silk_id`/`user_id`（用户ID）
  - `key_id`（卡券key，关联订单）
  - `card_id=74`（复活券类型）
- **输出指标**：
  - 发放成功数、使用数、复活券订单数、补贴金额

#### 1.2 幸运抽奖分析
- **业务目的**：分析免费开红包活动的中奖情况
- **涉及表**：`dwd.dwd_sr_market_rpd_lottery_winning_record`
- **关键字段**：
  - `gift_name`（奖品名称）
  - `gift_value_type`（1=业务奖品, 2=成本奖品, 3=权益奖品）
  - `gift_value_subtype`（奖品子类型，1-11对应不同类型）
  - `user_group_type`（1=普通用户, 2=疲劳用户, 3=羊毛用户）
  - `is_get`（是否领取，2=已领取）
- **输出指标**：
  - 中奖次数、总抽奖次数、中奖率（按月份、奖品、用户类型）

### 2. 用户行为分析
#### 2.1 砍价首页实验分析
- **业务目的**：A/B测试分析，对比实验组（到店小程序）vs对照组（Android/iOS）
- **涉及表**：`dwd.dwd_sr_traffic_sensor_event_log_realtime`
- **关键字段**：
  - `platform_type`（平台类型，用于分组：'到店小程序'=实验组，其他=对照组）
  - `event`（事件：'Instore_Homepage_Feed_Activity_Ex'曝光，'Instore_Homepage_Feed_Activity_Click'点击）
  - `page_name='砍价首页'`
  - `distinct_id`（用户ID，正则`^[0-9]{1,10}$`过滤）
  - `activity_id`（活动ID）
- **输出指标**：
  - 曝光量、曝光用户量、点击量、点击用户量
  - 支付订单量、支付金额、支付用户量
  - 核销订单量、核销用户量

#### 2.2 用户访问分析
- **设备品牌分布**：基于`$brand`字段统计
- **操作系统分布**：基于`$os`字段统计
- **用户ID过滤**：`distinct_id regexp '^[0-9]{1,10}$'`（1-10位纯数字）
- **时间范围**：通常近7天（`date_sub(current_date(),interval 7 DAY)`）

### 3. 订单与销售分析
#### 3.1 月销单统计
- **业务目的**：按城市、品类、平台统计月度销售数据
- **涉及表**：未明确（从字段推断为聚合表）
- **关键维度**：
  - 城市、区县
  - 品类：cate1（1=早餐,2=正餐,3=下午茶,4=晚餐,5=夜宵,6=零售）
  - 品类：cate2（1=包子粥铺,2=快餐简餐,3=甜品饮品,4=炸串小吃,5=火锅烧烤,6=汉堡西餐,7=零售,8=水果鲜花,9=成人用品）
  - 店铺平台（store_platform）
  - 餐标（mlabel）
- **输出指标**：
  - 活动数、活动名额（美团/饿了么/京东/总计）
  - 订单量（全站报名/有效）
  - 利润、实际返现金额、红包金额
  - 手动取消订单量

#### 3.2 外卖累计订单分布
- **业务目的**：分析用户历史有效订单量的分布
- **涉及表**：`dim.dim_silkworm_user`
- **关键字段**：`accu_valid_order_num`（累计有效订单数）
- **统计方法**：使用`percentile_cont`计算分位数（10%、20%...90%）

### 4. DAU与用户活跃分析
#### 4.1 基础DAU统计
- **涉及表**：`dws.dws_sr_user_login_d`
- **关键字段**：
  - `statistics_date`（统计日期）
  - `view_uids`（bitmap类型，活跃用户ID集合）
  - `city_name`、`county_name`（城市、区县）
- **函数**：`bitmap_union_count()`聚合bitmap
- **时间范围**：硬编码或参数化

#### 4.2 注册时间间隔DAU
- **业务目的**：按用户注册时间分群统计活跃度
- **用户分群**：
  - 当日注册用户、1-7天内、8-14天内、15-30天内
  - 31-60天、61-90天、91-180天、181-270天、271-365天、365天以上
- **技术方法**：`unnest_bitmap()`展开bitmap，`date_diff()`计算天数差

### 5. 商家与店铺分析
#### 5.1 近3个月未发活动商家
- **业务目的**：识别长时间未发布活动的商家
- **涉及表**：
  - `dim.dim_silkworm_merchant`（商家维度表）
  - `dwd.dwd_sr_store_promotion`（店铺活动表）
  - `dim.dim_silkworm_store`（店铺维度表）
- **筛选条件**：
  - 商家状态正常（`status=0`, `is_logff=0`）
  - 手机号有效（`length(phone)=11`, `NOT LIKE '%*%'`）
  - 最近90天无活动（`begin_date`在90天内无记录）
  - 有店铺信息（`store_name_list IS NOT NULL`）
- **输出**：商家ID、昵称、真实姓名、注册时间、手机号、店铺列表、地理位置

#### 5.2 店铺品类提取
- **技术难点**：JSON嵌套解析
- **字段路径**：`xc_category` → `$.tag_name` → 数组第0个 → `$.tag_name` → `$.category1`/`$.category2`
- **函数**：`get_json_object()`, `parse_json()`

### 6. 其他专项分析
#### 6.1 AI电话外呼效果
- **涉及表**：
  - `temp.temp_user_ai_phone_call_record`（外呼记录）
  - `dwd.dwd_sr_order_promotion_order`（订单表）
- **关键字段**：
  - `call_status`（1=接通, 2=未接通）
  - `channel`（0=超时, 1=复活, 2=拒绝）
  - `order_status`（2,8=完单状态）
- **输出指标**：
  - 呼叫总量、通知人数
  - 未接通人数、未接通且完单人数
  - 接通人数、接通且完单人数

#### 6.2 商务团队销单统计
- **涉及表**：`dwd.dwd_sr_store_promotion`
- **关键字段**：
  - `bd_id`（商务ID）
  - `status`（1,4,5=有效状态）
  - 平台配额：`meituan_promotion_quota`, `eleme_promotion_quota`, `jd_promotion_quota`
  - 完成数：`meituan_finished_num`, `eleme_finished_num`, `jd_finished_num`

## 常用表结构总结

### 核心事实表
1. **dwd.dwd_sr_traffic_sensor_event_log_realtime**
   - 埋点事件实时表
   - 关键字段：`time`, `event`, `distinct_id`, `properties`（JSON）
   - 常用JSON路径：`$.platform_type`, `$.$brand`, `$.$os`, `$.page_name`, `$.activity_id`

2. **dwd.dwd_sr_order_promotion_order**
   - 促销订单表
   - 关键字段：`order_id`, `user_id`, `store_promotion_id`, `pay_amt`, `pay_time`, `verify_time`, `order_status`
   - 订单状态：`2`和`8`表示有效订单

3. **dwd.dwd_sr_store_promotion**
   - 店铺活动表
   - 关键字段：`store_id`, `merchant_id`, `bd_id`, `begin_date`, `status`, 各平台配额和完成数

### 核心维度表
1. **dim.dim_silkworm_user**
   - 用户维度表
   - 关键字段：`user_id`, `register_time`, `city_name`, `bind_interior_staff_wework_id`, `accu_valid_order_num`

2. **dim.dim_silkworm_store**
   - 店铺维度表
   - 关键字段：`store_id`, `store_name`, `merchant_id`, `city_name`, `district_name`, `xc_category`

3. **dim.dim_silkworm_merchant**
   - 商家维度表
   - 关键字段：`merchant_id`, `merchant_nickname`, `merchant_real_name`, `register_time`, `phone`, `status`

### 聚合表
1. **dws.dws_sr_user_login_d**
   - 用户登录日聚合表
   - 关键字段：`statistics_date`, `city_name`, `county_name`, `view_uids`（bitmap）

2. **dws.dws_sr_store_takeawaypro_statis_d**
   - 店铺外卖活动日统计表
   - 关键字段：`city_name`, `promotion_quota`, `valid_order_num`

## 常用技术模式

### 1. 用户ID处理
```sql
-- 标准过滤：1-10位纯数字用户ID
distinct_id regexp '^[0-9]{1,10}$'

-- 订单ID处理（去前缀）
concat('单',order_id) -- 添加前缀
right(order_id,9) -- 取后9位
cast(right(order_id,9) AS int) -- 转整数
```

### 2. JSON字段提取
```sql
-- 简单提取
get_json_string(properties, '$.platform_type')

-- 复杂嵌套提取（店铺品类）
get_json_object(
    parse_json(get_json_object(get_json_object(parse_json(get_json_object(xc_category, '$.tag_name')), '$[0]'), '$.tag_name')),
    '$.category1'
)
```

### 3. 时间处理
```sql
-- 日期格式化
date_format(time, '%Y-%m-%d')
date_format(time, '%Y-%m-%d %H:00:00') -- 小时级

-- 时间范围
BETWEEN '${begin_date}' AND '${end_date}'
BETWEEN date_sub(current_date(),interval 7 DAY) AND date_sub(current_date(),interval 1 DAY)

-- 月份截断
DATE_TRUNC('month', '${begin_date}')
```

### 4. 分群统计
```sql
-- 注册时间分群
CASE
    WHEN diff_days=0 THEN '当日注册用户'
    WHEN diff_days>0 AND diff_days<=7 THEN '1-7天内注册用户'
    -- ...更多分组
END user_type

-- 平台实验分组
IF(platform_type = '到店小程序', '实验组', '对照组') exp_name
```

### 5. Bitmap处理
```sql
-- 聚合bitmap计数
bitmap_union_count(view_uids)

-- 展开bitmap
unnest_bitmap(view_uids) AS uid
```

## 参数使用模式
脚本中使用的参数：
- `${begin_date}`: 开始日期
- `${end_date}`: 结束日期  
- `${T-1}`: 前一天
- 硬编码日期：'2025-09-18'等

## 如何快速提供指标SQL
当用户请求特定指标时，基于此理解：
1. 识别指标所属的业务模块
2. 找到对应的表结构和字段
3. 应用相关的过滤条件和分组逻辑
4. 根据需求调整时间范围和参数
5. 输出符合原脚本风格的SQL
