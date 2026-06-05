================ 数据探查
-- 小程序、h5正常，不带单位 APP端有单位km m均有，km数据值多半不准，有大于100的值。
-- activity_id、distance有null值
select platform_name,distance from ods.ods_sr_traffic_event_log where dt='2024-09-09' and distance is not null group by 1,2;

select platform_name,activity_id,distance from ods.ods_sr_traffic_event_log where dt='2024-09-09' and distance is not null  limit 10;

-- 是否活动ID有值时，距离无值（是），反之也存在。

select platform_name,activity_id,distance from ods.ods_sr_traffic_event_log where dt='2024-09-09' and activity_id is not null and distance is null limit 10;

select 
     replace(replace(distance,'km',''),'m','') as distance
from ods.ods_sr_traffic_event_log
where dt='2024-09-09' 
    and activity_id regexp '^[1-9]{1,8}$'
    and distance regexp 'KM|Km|kM|km'
group by 1;


-- 活动与用户距离
select
    activity_id,
    average(distance) as avg_distacne
from (select 
            user_id,
            activity_id,
            case when distance regexp 'km' then cast(replace(distance,'km','') as int)*1000 as distance
        from ods.ods_sr_traffic_event_log
        where dt='2024-09-09' 
            and activity_id regexp '^[1-9]{1,8}$'
            and distance is not null
        group by 1,2,3
    ) a


-- 带单位距离数据占比
select 
    dt,
     count(*) as tot,
     count(if(distance regexp 'km|m',event_time,null)) as valid_cnt,
     count(if(distance regexp 'km|m',event_time,null))/count(*) as rate
from ods.ods_sr_traffic_event_log
where dt between '2024-09-01' and '2024-09-10' 
    and activity_id regexp '^[1-9]{1,8}$'
group by 1
;








-- 查看活动
-- 无论返利餐还是霸王餐，都有返利比例>1的活动
-- 餐标：当返利门槛是0时，返利比例无法计算，使用中要剔除该部分数据，需要看下这部分订单的占比，再看是否适合剔除
select promotion_rebate_type, -- 0:霸王餐,1:返利餐
    status,
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as mlabel_threshold_amt, -- 餐标门槛
    if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating -- 是否需要评价 1:是,0:否
from dwd.dwd_sr_store_promotion
where dt between '2024-09-01' and '2024-09-10'
                and begin_date between '2024-09-01' and '2024-09-01'
                and status in (1,4,5)
group by 1,2,3,4,5,6,7,8,9,10,11
;


-- 门槛金额为0的活动，不存在
-- select
--     *
-- from
-- (select promotion_rebate_type,
--     status,
--     meituan_mlabel_threshold_amt,
--     meituan_mlabel_rebate_amt,
--     eleme_mlabel_threshold_amt,
--     eleme_mlabel_rebate_amt,
--     if(meituan_mlabel_threshold_amt=0,eleme_mlabel_threshold_amt,meituan_mlabel_threshold_amt) as mlabel_threshold_amt,
--     if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as mlabel_rebate_amt
-- from dwd.dwd_sr_store_promotion
-- where dt between '2024-08-01' and '2024-09-10'
--                 and begin_date between '2024-08-01' and '2024-09-01'
--                 and status in (1,4,5)
-- group by 1,2,3,4,5,6,7,8
-- ) toa
-- where mlabel_threshold_amt=0

==================================== 正式取数

with t1 as (
select
    store_promotion_id,
    a.store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type,
    sub_category_type,
    store_brand_type,
    delivery_type,
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end as mlabel, -- 餐标
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    sum(promotion_quota) over(partition by case when promotion_rebate_type=0 then concat('满',mlabel_threshold_amt,'返',mlabel_rebate_amt)
        when promotion_rebate_type=1 then concat('最高返',mlabel_rebate_amt)
    else '其他' end) as acc_promotion_quota -- 累计活动名额
from (
select 
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    meituan_order_amt,
    meituan_mlabel_rebate_amt,
    eleme_order_amt,
    eleme_mlabel_rebate_amt,
    cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
    cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
    (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
    /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
    as rebate_rate, -- 返现比例
    if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
    if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
    meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion -- 0:否,1:是
from dwd.dwd_sr_store_promotion
where dt between '2024-06-20' and '2024-07-01'
                and begin_date between '2024-07-01' and '2024-07-01'
                and status in (1,4,5)
     ) a
left join
-- 店铺维表
(select
    store_id,
    case 
        when category_type = 1 then '早餐'
        when category_type = 2 then '正餐'
        when category_type = 3 then '下午茶'
        when category_type = 4 then '晚餐'
        when category_type = 5 then '夜宵'
        when category_type = 6 then '零售'
    else '其他' end as category_type,
    case 
        when sub_category_type = 1 then '包子粥铺'
        when sub_category_type = 2 then '快餐简餐'
        when sub_category_type = 3 then '甜品饮品'
        when sub_category_type = 4 then '炸串小吃'
        when sub_category_type = 5 then '火锅烧烤'
        when sub_category_type = 6 then '汉堡西餐'
        when sub_category_type = 7 then '零售'
        when sub_category_type = 8 then '水果鲜花'
        when sub_category_type = 9 then '成人用品'
    else '其他' end as sub_category_type,
    case when store_brand_type=1 then '大牌'
        when store_brand_type=0 then '普通'
    else '其他' end as store_brand_type,
    case when delivery_type=0 then '美团配送'
        when delivery_type=1 then '商家自配送'
    else '其他' end as delivery_type
from dim.dim_silkworm_store
where status=1) b
on a.store_id=b.store_id
            ),

-- 订单
t2 as (
select
    store_promotion_id,
    count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
    count(auto_id) as order_num -- 订单量
from dwd.dwd_sr_order_promotion_order
where cast(dt as string) between '2024-06-29' and '2024-07-01'
    and substr(order_time,1,10) between '2024-07-01' and '2024-07-01'
    and store_promotion_id>0
group by 1
)



select
    store_promotion_id,
    store_id,
    promotion_rebate_type, -- 0:霸王餐,1:返利餐
    category_type,
    sub_category_type,
    store_brand_type,
    delivery_type,
    mlabel,
    rebate_rate, -- 返现比例
    promotion_quota, -- 活动名额
    is_threshold, -- 是否有门槛 1:是,0:否
    is_need_rating, -- 是否需要评价 1:是,0:否
    is_virtual, -- 0:否,1:是
    is_miaosha, -- 0:否,1:是
    is_private, -- 0:否,1:是
    is_vip_exclusive, -- 0:否,1:是
    is_youzhi_promotion, -- 0:否,1:是
    acc_promotion_quota, -- 累计活动名额
    promotion_quota/acc_promotion_quota as quota_rate,
    order_num, -- 下单量
    valid_order_num, -- 有效下单量
    acc_order_num, -- 累计下单量
    acc_valid_order_num, -- 累计有效下单量
    order_num/acc_order_num as order_rate,
    valid_order_num/acc_valid_order_num as valid_order_rate,
    if(coalesce(order_num/promotion_quota,0)>1,1,coalesce(order_num/promotion_quota,0)) as xd_rate,
    if(coalesce(valid_order_num/promotion_quota,0)>1,1,coalesce(valid_order_num/promotion_quota,0)) as valid_xd_rate
from (
select
    t1.store_promotion_id,
    t1.store_id,
    t1.promotion_rebate_type, -- 0:霸王餐,1:返利餐
    t1.category_type,
    t1.sub_category_type,
    t1.store_brand_type,
    t1.delivery_type,
    t1.mlabel,
    t1.rebate_rate, -- 返现比例
    t1.promotion_quota, -- 活动名额
    t1.is_threshold, -- 是否有门槛 1:是,0:否
    t1.is_need_rating, -- 是否需要评价 1:是,0:否
    t1.is_virtual, -- 0:否,1:是
    t1.is_miaosha, -- 0:否,1:是
    t1.is_private, -- 0:否,1:是
    t1.is_vip_exclusive, -- 0:否,1:是
    t1.is_youzhi_promotion, -- 0:否,1:是
    t1.acc_promotion_quota, -- 累计活动名额
    t1.promotion_quota/t1.acc_promotion_quota as quota_rate,
    order_num, -- 下单量
    valid_order_num, -- 有效下单量
    sum(order_num) over(partition by mlabel order by mlabel) as acc_order_num, -- 累计下单量
    sum(valid_order_num) over(partition by mlabel order by mlabel) as acc_valid_order_num -- 累计有效下单量
from t1
left join t2 on t1.store_promotion_id=t2.store_promotion_id
) a
;





-- -- 查看销单率和有效销单率>1数据
-- store_promotion_id
-- 25164683,
-- 25168478,
-- 25193842,
-- 25200039,
-- 25184073,
-- 25149421,
-- 25182193,
-- 25160882,
-- 25145889


-- select 
--     store_promotion_id,
--     store_id,
--     promotion_rebate_type, -- 0:霸王餐,1:返利餐
--     meituan_order_amt,
--     meituan_mlabel_rebate_amt,
--     eleme_order_amt,
--     eleme_mlabel_rebate_amt,
--     cast(cast(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt) as int) as string) as mlabel_threshold_amt, -- 餐标门槛
--     cast(cast(if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt) as int) as string) as mlabel_rebate_amt, -- 餐标返利
--     (if(meituan_mlabel_rebate_amt=0,eleme_mlabel_rebate_amt,meituan_mlabel_rebate_amt))
--     /(if(meituan_order_amt=0,eleme_order_amt,meituan_order_amt))
--     as rebate_rate, -- 返现比例
--     if(meituan_order_amt<>0 or eleme_order_amt<>0,1,0) is_threshold, -- 是否有门槛 1:是,0:否
--     if(rebate_condition_desc regexp '用餐反馈',1,0) is_need_rating, -- 是否需要评价 1:是,0:否
--     meituan_promotion_quota+eleme_promotion_quota as promotion_quota, -- 活动名额
--     is_virtual, -- 0:否,1:是
--     is_miaosha, -- 0:否,1:是
--     is_private, -- 0:否,1:是
--     is_vip_exclusive, -- 0:否,1:是
--     is_youzhi_promotion -- 0:否,1:是
-- from dwd.dwd_sr_store_promotion
-- where dt between '2024-06-01' and '2024-07-31'
--                 and begin_date between '2024-07-01' and '2024-07-31'
--                 and status in (1,4,5)
--                 and store_promotion_id in (
-- 25164683,
-- 25168478,
-- 25193842,
-- 25200039,
-- 25184073,
-- 25149421,
-- 25182193,
-- 25160882,
-- 25145889)




-- select
--     store_promotion_id,
--     count(if(order_status in (2,8),auto_id,null)) as valid_order_num, -- 有效订单量
--     count(auto_id) as order_num -- 订单量
-- from dwd.dwd_sr_order_promotion_order
-- where cast(dt as string) between '2024-06-01' and '2024-07-31'
--     and substr(order_time,1,10) between '2024-07-01' and '2024-07-31'
--     and store_promotion_id in (
-- 25164683,
-- 25168478,
-- 25193842,
-- 25200039,
-- 25184073,
-- 25149421,
-- 25182193,
-- 25160882,
-- 25145889)
-- group by 1


import pandas as pd  
  
# 读取Excel文件  
# 假设Excel文件名为'data.xlsx'，并且数据在第一个工作表上  
file_path = '20240918下单转化数据.xlsx'  
df = pd.read_excel(file_path, engine='openpyxl')  
  
# 假设我们要计算第1列（索引从0开始）与第3列、第5列和第10列之间的相关性  
# 你可以根据需要修改这些列索引  
target_column_index = 0  # 目标列索引，例如第1列  
columns_to_compare = [2, 4, 9]  # 要比较的列索引列表，例如第3列、第5列和第10列  
  
# 使用Pandas的corr()方法计算相关性  
# 注意：corr()默认计算的是皮尔逊相关系数，对于非数值型数据需要先进行转换  
# 这里假设所有列都是数值型  
  
# 创建一个包含目标列和要比较列的DataFrame  
subset_df = df.iloc[:, [target_column_index] + columns_to_compare]  
  
# 计算相关性  
correlation_matrix = subset_df.corr()  
  
# 打印相关性矩阵  
print(correlation_matrix)  
  
# 如果你只对目标列与每个比较列之间的相关性感兴趣，可以单独提取  
for col in columns_to_compare:  
    correlation_value = correlation_matrix.iloc[target_column_index, col]  
    print(f"Column {target_column_index+1} 与 Column {col+1} 的相关性为: {correlation_value}")


# 将相关性矩阵保存为新的Excel文件  
output_file_path = 'correlation_matrix.xlsx'  # 输出文件的路径  
with pd.ExcelWriter(output_file_path, engine='openpyxl') as writer:  
    correlation_matrix.to_excel(writer, sheet_name='Sheet1', index=True)  # index=True表示保留行索引作为单独的一列  
  
print(f'相关性矩阵已保存到 {output_file_path}')





-- 逻辑回归
import pandas as pd  
from sklearn.model_selection import train_test_split  
from sklearn.linear_model import LogisticRegression  
from sklearn.metrics import accuracy_score


# 假设df是你的DataFrame  
# 查看前几行数据确认列名  
print(df.head())  
  
# 分离特征和目标变量  
X = df.drop('target', axis=1)  # 假设除了'target'之外的所有列都是特征  
y = df['target']  
  
# 划分训练集和测试集（可选，但推荐）  
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 创建逻辑回归模型实例  
model = LogisticRegression()  
  
# 训练模型  
model.fit(X_train, y_train)

# 查看系数  
coefficients = model.coef_  
print("Coefficients:", coefficients)  
  
# 如果只有一个类别（二分类问题），coef_将是一个二维数组，其中第一个数组包含系数  
if coefficients.ndim == 2:  
    coefficients = coefficients[0]  
  
# 将系数与特征名称对应起来  
feature_names = X_train.columns  
for coef, feature in zip(coefficients, feature_names):  
    print(f"{feature}: {coef}")

# 使用测试集进行预测  
y_pred = model.predict(X_test)  
  
# 计算准确率  
accuracy = accuracy_score(y_test, y_pred)  
print(f"Accuracy: {accuracy:.2f}")

















































