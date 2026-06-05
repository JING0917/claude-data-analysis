数据集sell_info，表头：
下单日期（下单指报名）
时点（每个小时时间点，如9，表示早上9点0分到9点59分之间）
是否节假日
用户ID
是否新注册用户
是否新用户（新用户指观察时，未产生过有效单用户）
是否风控
城市线级
城市
区县
活动ID -- 非自营活动会被剔除
品类
是否自营
是否需评价
活动曝光位置
活动与用户距离（单位:米）
餐标区间（下单门槛金额和下单返现金额拼接，如“满20返10”）
下单门槛金额
下单返现金额
返现比例（下单返现金额/下单门槛金额）
报名时活动剩余名额
全站曝光量
主页feed流曝光量
搜索feed流曝光量
用户近7日有效单偏好品类
用户近30日有效单偏好品类
用户近7日有效单支付金额
用户近30日有效单支付金额
用户近7日有效单到手价（到手价=支付金额-返现金额）
用户近30日有效单到手价（到手价=支付金额-返现金额）
用户7日内复购率（统计周期内有复购行为的用户量/统计周期内有首单的用户量）
用户30日内复购率（统计周期内有复购行为的用户量/统计周期内有首单的用户量）
是否有待使用红包
用户待使用红包金额（优先面额最大，面额一致时选临期）
店铺报名率（报名量/活动名额）
店铺取消率（取消量/活动名额）
是否下单（下单指报名）
是否有效单


需要剔除虚假订单（虚假是后置识别，下单时无法剔除，对用户已风控，风控用户不能下单。应该做的是增加羊毛用户识别）

每日200万条数据左右。数据中，“是否下单（下单指报名）”、“是否有效单”，分别是两个因变量，请通过给到的数据，给出合适的模型和在jupyter执行的Python脚本，分别做分析，脚本中需要包含相关矩阵的逻辑。




========================================================================================== START
#******************************************************************#
## author: dahe
## create_time: 2026-01-08 11:54:26
## 适配环境：WeData（低资源占用版）+ pandas 1.1.5 + scikit-learn 0.24.2
## 核心功能：7天大数据量（每日5000万行）下单影响因素建模 + StarRocks直连
## 核心优化：最小内存/CPU占用，兼容其他任务并行运行 固定自然周（排除元旦）+ 保留负样本 + 最小资源占用
## 关键修复：1. 修复NameError（dwd未定义） 2. 修复pandas 1.1.5 category dtype兼容问题 3. 修复Categorical新类别赋值错误 4. 修复数据库字段不匹配（移除abs_correlation写入）5. 修复sklearn 0.24.2不兼容max_categories参数 6. 修复OneHotEncoder drop与handle_unknown参数冲突 7. 修复Decimal与str类型混合导致的编码错误 8. 适配sklearn 0.24.2的get_feature_names API（替代get_feature_names_out）9. 修复np.where广播维度不匹配错误 10. 修复SQL关键字冲突（explain字段加反引号）11. 新增表存在性检查+自动创建逻辑 12. 修复StarRocks DUPLICATE KEY列位置错误（主键列必须在字段最前面）13. 移除StarRocks旧版本不支持的replication_allocation属性，改用兼容的replication_num
#******************************************************************#

############################# 以下是线下回归逻辑 本身存在场景局限性

import sys
import mysql.connector
import gc
import warnings
import numpy as np
import pandas as pd
import psutil
import matplotlib.pyplot as plt
from scipy.stats import chi2_contingency
from datetime import datetime, timedelta
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import LinearRegression
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error
from sklearn.feature_selection import VarianceThreshold
# 新增Decimal类型处理
from decimal import Decimal
# 新增sklearn版本检测
import sklearn

# ========== 核心修改1：适配WeData日志捕获 ==========
# 强制刷新stdout，确保WeData能捕获所有print输出
def print_with_flush(msg):
    """带强制刷新的打印函数（适配WeData日志）"""
    print(msg)
    sys.stdout.flush()  # 强制刷新输出流

# 关闭matplotlib警告（低资源适配）
plt.rcParams['font.sans-serif'] = ['DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
plt.ioff()  # 关闭交互式绘图，节省内存

# ====================== 低资源核心配置 =======================
# StarRocks连接参数（复用）
SR_CONFIG = {
    "host": "172.17.64.45",
    "port": 9030,
    "user": "root",
    "password": "O8dtIJ6^KD!Xf8E",
    "buffered": False  # 关闭缓冲，减少内存
}

# 资源严控配置（核心优化点）
TARGET_COL = "order_num"                # 因变量：下单量
DIMENSION_COLS = [                      # 维度特征（类别型）- 新增expouse_hr
    "client_level", "gender", "city_name", 
    "county_name", "cate1_name", "cate2_name", "expouse_hr"
]
EXCLUDE_COLS = ["expouse_time", "user_id"]  # 排除冗余字段（保留expouse_hr）
SAMPLE_RATIO = 0.005                    # 0.5%采样（大幅减少数据量）
CHUNK_SIZE = 3000                       # 分块读取行数（降低单次内存占用）
BATCH_SIZE = 1000                       # 批量写入批次（减少写入内存）
MAX_MEMORY_GB = 8                       # 内存上限（避让其他任务）
CPU_THREADS = 1                         # 建模仅用1核（避免抢占CPU）

# 固定自然周配置（2025-12-08至2025-12-14）
WEEK_START = "2025-12-08"
WEEK_END = "2025-12-14"

# 表名配置（确认表名正确性）
RESULT_TABLE = "dwd.dwd_sr_order_feature_contrib"  
CORR_RESULT_TABLE = "dwd.dwd_sr_order_correlation_matrix"  # 相关矩阵结果表
TARGET_TABLE = "dwd.dwd_sr_store_order_factor"  # 目标表名常量，避免硬编码错误

# 数据库字段过滤配置（核心修复：只保留目标表存在的字段）
# 相关矩阵表允许的字段列表（移除abs_correlation）
CORR_ALLOWED_COLS = [
    "feature_name", "feature_type", "correlation_type", 
    "correlation_value", "p_value", "feature_category", 
    "week_range", "create_date"
]

# 环境适配（关闭冗余功能）
warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)
pd.set_option('mode.chained_assignment', None)
pd.set_option('memory_usage', 'deep')  # 监控DataFrame内存

# ====================== 新增：表存在性检查+自动创建逻辑（修复StarRocks旧版本属性兼容）======================
def check_and_create_table(conn, table_name):
    """
    检查指定表是否存在，若不存在则自动创建（适配StarRocks旧版本：移除replication_allocation，改用replication_num）
    参数：
        conn: StarRocks数据库连接
        table_name: 完整表名（如dwd.dwd_sr_order_feature_contrib）
    返回：
        bool: True-表存在/创建成功，False-创建失败
    """
    print_with_flush(f"\n【表检查】开始检查表 {table_name} 是否存在...")
    cursor = conn.cursor()
    
    # 拆分库名和表名
    if '.' in table_name:
        db_name, tb_name = table_name.split('.', 1)
    else:
        db_name = 'dwd'
        tb_name = table_name
    
    try:
        # 1. 检查表是否存在
        check_sql = f"""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = '{db_name}' AND table_name = '{tb_name}'
        """
        cursor.execute(check_sql)
        result = cursor.fetchone()
        
        if result:
            print_with_flush(f"✅ 表 {table_name} 已存在")
            return True
        
        # 2. 表不存在，自动创建（核心修复：1. 主键列放最前 2. 移除不兼容属性 3. 改用replication_num）
        print_with_flush(f"⚠️ 表 {table_name} 不存在，开始自动创建...")
        
        # 定义表结构（适配StarRocks旧版本语法）
        if tb_name == 'dwd_sr_order_feature_contrib':
            # 特征贡献度表创建语句（兼容旧版本：移除replication_allocation，改用replication_num=1）
            create_sql = f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                `feature_name` VARCHAR(255) COMMENT '特征名称',
                `create_date` DATE COMMENT '创建日期',
                `contribution` FLOAT COMMENT '贡献度值',
                `feature_type` VARCHAR(50) COMMENT '特征类型（数值型/类别型）',
                `explain` VARCHAR(255) COMMENT '贡献度解释',
                `sample_ratio` FLOAT COMMENT '采样比例',
                `week_range` VARCHAR(50) COMMENT '数据周范围'
            ) ENGINE=OLAP 
            DUPLICATE KEY(`feature_name`, `create_date`)
            COMMENT '下单影响因素特征贡献度表'
            DISTRIBUTED BY HASH(`feature_name`) BUCKETS 10
            PROPERTIES (
                "replication_num" = "1",
                "storage_format" = "DEFAULT"
            );
            """
        elif tb_name == 'dwd_sr_order_correlation_matrix':
            # 相关矩阵表创建语句（兼容旧版本）
            create_sql = f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                `feature_name` VARCHAR(255) COMMENT '特征名称',
                `create_date` DATE COMMENT '创建日期',
                `feature_type` VARCHAR(50) COMMENT '特征类型',
                `correlation_type` VARCHAR(50) COMMENT '相关性类型',
                `correlation_value` FLOAT COMMENT '相关性值',
                `p_value` FLOAT COMMENT 'P值',
                `feature_category` VARCHAR(50) COMMENT '特征分类',
                `week_range` VARCHAR(50) COMMENT '数据周范围'
            ) ENGINE=OLAP 
            DUPLICATE KEY(`feature_name`, `create_date`)
            COMMENT '下单影响因素相关矩阵表'
            DISTRIBUTED BY HASH(`feature_name`) BUCKETS 10
            PROPERTIES (
                "replication_num" = "1",
                "storage_format" = "DEFAULT"
            );
            """
        else:
            print_with_flush(f"❌ 不支持自动创建表 {table_name}，请手动创建")
            return False
        
        # 执行创建语句
        cursor.execute(create_sql)
        conn.commit()
        print_with_flush(f"✅ 表 {table_name} 自动创建成功")
        return True
        
    except Exception as e:
        print_with_flush(f"❌ 表检查/创建失败：{str(e)}")
        conn.rollback()
        return False
    finally:
        cursor.close()

# ====================== 工具函数（资源严控+相关矩阵+日志适配）======================
def monitor_memory(prefix=""):
    """严控内存，超限立即GC+告警（适配WeData日志）"""
    mem = psutil.virtual_memory()
    used_gb = round(mem.used / 1024 / 1024 / 1024, 2)
    print_with_flush(f"【低资源监控】{prefix} - 已用：{used_gb}GB / 上限：{MAX_MEMORY_GB}GB")
    
    if used_gb >= MAX_MEMORY_GB * 0.9:  # 达90%即触发GC
        print_with_flush(f"【内存预警】接近上限，强制GC...")
        gc.collect()
        used_gb_after = round(psutil.virtual_memory().used / 1024 / 1024 / 1024, 2)
        print_with_flush(f"【低资源监控】GC后已用：{used_gb_after}GB")
    
    return used_gb

def cramers_v(x, y):
    """
    计算Cramer's V系数（类别特征与因变量的关联度），适配低资源
    参数：x-类别特征，y-因变量（order_num）
    返回：Cramer's V系数（0~1，越大关联度越高）
    """
    # 构建列联表（低内存版本）
    contingency = pd.crosstab(x, y, dropna=False)
    # 卡方检验
    chi2, p, dof, expected = chi2_contingency(contingency)
    # 计算Cramer's V
    n = contingency.sum().sum()
    phi2 = chi2 / n
    r, k = contingency.shape
    phi2corr = max(0, phi2 - ((k-1)*(r-1))/(n-1))
    rcorr = r - ((r-1)**2)/(n-1)
    kcorr = k - ((k-1)**2)/(n-1)
    cramers_v = np.sqrt(phi2corr / min((kcorr-1), (rcorr-1)))
    # 释放列联表内存
    del contingency, chi2, expected
    gc.collect()
    return round(cramers_v, 4), round(p, 4)

def calculate_correlation_matrix(df):
    """
    计算相关矩阵：
    1. 数值特征 ↔ 因变量（皮尔逊相关系数）
    2. 维度特征（类别） ↔ 因变量（Cramer's V系数）- 包含expouse_hr
    参数：df-清洗后的完整数据
    返回：相关矩阵结果DataFrame（仅包含目标表允许的字段）
    """
    print_with_flush("\n【相关矩阵分析】开始计算特征与order_num的相关性...")
    monitor_memory("相关矩阵计算前")
    
    # 1. 拆分特征类型
    # 数值特征（排除因变量、维度特征、冗余字段）
    num_features = df.select_dtypes(include=['int64', 'float64', 'int32', 'float16']).columns.tolist()
    num_features = [col for col in num_features if col not in [TARGET_COL] + EXCLUDE_COLS]
    # 维度特征（指定的7个类别字段，含expouse_hr）
    dim_features = DIMENSION_COLS.copy()
    # 其他类别特征（非维度、非冗余）
    other_cat_features = [
        col for col in df.select_dtypes(include=['category', 'object']).columns.tolist()
        if col not in dim_features + [TARGET_COL] + EXCLUDE_COLS
    ]

    # 2. 计算数值特征与因变量的皮尔逊相关
    corr_results = []
    if num_features:
        print_with_flush(f"【相关矩阵】计算{len(num_features)}个数值特征与order_num的皮尔逊相关...")
        for col in num_features:
            # 过滤缺失值（低内存）
            valid_data = df[[col, TARGET_COL]].dropna()
            if len(valid_data) < 100:  # 样本量不足跳过
                continue
            # 计算皮尔逊相关
            corr = valid_data[col].corr(valid_data[TARGET_COL])
            corr_results.append({
                "feature_name": col,
                "feature_type": "数值型",
                "correlation_type": "皮尔逊相关系数",
                "correlation_value": round(corr, 4),
                "p_value": None,
                "feature_category": "影响特征",
                "week_range": f"{WEEK_START}~{WEEK_END}",
                "create_date": datetime.now().strftime("%Y-%m-%d")
            })
            del valid_data
            gc.collect()

    # 3. 计算维度特征与因变量的Cramer's V（含expouse_hr）
    if dim_features:
        print_with_flush(f"【相关矩阵】计算{len(dim_features)}个维度特征（含expouse_hr）与order_num的Cramer's V...")
        for col in dim_features:
            # 过滤缺失值（低内存）
            valid_data = df[[col, TARGET_COL]].dropna()
            if len(valid_data) < 100:  # 样本量不足跳过
                continue
            # 计算Cramer's V
            cramers_v_val, p_val = cramers_v(valid_data[col], valid_data[TARGET_COL])
            corr_results.append({
                "feature_name": col,
                "feature_type": "类别型（维度）",
                "correlation_type": "Cramer's V系数",
                "correlation_value": cramers_v_val,
                "p_value": p_val,
                "feature_category": "维度特征",
                "week_range": f"{WEEK_START}~{WEEK_END}",
                "create_date": datetime.now().strftime("%Y-%m-%d")
            })
            del valid_data
            gc.collect()

    # 4. 计算其他类别特征与因变量的Cramer's V
    if other_cat_features:
        print_with_flush(f"【相关矩阵】计算{len(other_cat_features)}个其他类别特征与order_num的Cramer's V...")
        for col in other_cat_features:
            # 过滤缺失值（低内存）
            valid_data = df[[col, TARGET_COL]].dropna()
            if len(valid_data) < 100:  # 样本量不足跳过
                continue
            # 计算Cramer's V
            cramers_v_val, p_val = cramers_v(valid_data[col], valid_data[TARGET_COL])
            corr_results.append({
                "feature_name": col,
                "feature_type": "类别型（影响特征）",
                "correlation_type": "Cramer's V系数",
                "correlation_value": cramers_v_val,
                "p_value": p_val,
                "feature_category": "影响特征",
                "week_range": f"{WEEK_START}~{WEEK_END}",
                "create_date": datetime.now().strftime("%Y-%m-%d")
            })
            del valid_data
            gc.collect()

    # 5. 构建结果DataFrame
    corr_df = pd.DataFrame(corr_results)
    if not corr_df.empty:
        # 步骤1：添加临时排序列（仅用于排序，不写入数据库）
        corr_df['abs_correlation'] = corr_df['correlation_value'].abs()
        # 步骤2：按相关度绝对值排序（从高到低）
        corr_df = corr_df.sort_values('abs_correlation', ascending=False, ignore_index=True)
        # 步骤3：删除临时排序列（核心修复：避免写入不存在的字段）
        corr_df = corr_df.drop(columns=['abs_correlation'])
        # 步骤4：仅保留目标表允许的字段
        corr_df = corr_df[CORR_ALLOWED_COLS]
        
        # 输出TOP10相关特征
        print_with_flush("\n【相关矩阵】TOP10高相关特征：")
        print_with_flush(corr_df.head(10)[['feature_name', 'feature_type', 'correlation_value']].to_string(index=False))
        
        # 生成相关矩阵可视化（低资源版，可选保存）
        try:
            # 临时恢复abs_correlation用于绘图
            corr_df_plot = corr_df.copy()
            corr_df_plot['abs_correlation'] = corr_df_plot['correlation_value'].abs()
            plot_correlation_matrix(corr_df_plot)
            del corr_df_plot
        except Exception as e:
            print_with_flush(f"【相关矩阵】可视化生成失败（不影响核心逻辑）：{str(e)}")
    else:
        raise ValueError("【相关矩阵】无有效特征可计算相关性")

    monitor_memory("相关矩阵计算后")
    return corr_df

def plot_correlation_matrix(corr_df):
    """
    生成低资源版相关矩阵可视化图（TOP15特征）
    参数：corr_df-包含abs_correlation的相关矩阵结果
    """
    print_with_flush("\n【相关矩阵】生成可视化图（TOP15特征）...")
    # 仅取TOP15特征（控内存）
    top_corr = corr_df.head(15).copy()
    # 绘图（极简风格）
    fig, ax = plt.subplots(figsize=(10, 8))
    # 颜色映射
    colors = ['#ff6b6b' if x < 0 else '#4ecdc4' for x in top_corr['correlation_value']]
    # 绘制横向条形图
    bars = ax.barh(
        top_corr['feature_name'][::-1], 
        top_corr['correlation_value'][::-1],
        color=colors[::-1],
        alpha=0.8
    )
    # 添加数值标签
    for bar in bars:
        width = bar.get_width()
        ax.text(
            width + (0.01 if width >=0 else -0.01),
            bar.get_y() + bar.get_height()/2,
            f"{width:.4f}",
            ha='left' if width >=0 else 'right',
            va='center',
            fontsize=8
        )
    # 图表配置（低资源）
    ax.set_xlabel('Correlation Value', fontsize=10)
    ax.set_title(f'Feature vs Order_Num Correlation (TOP15)\n{WEEK_START}~{WEEK_END}', fontsize=12)
    ax.axvline(x=0, color='black', linestyle='-', linewidth=0.5)
    plt.tight_layout()
    # 保存图片（低分辨率，控内存）
    plt.savefig(
        f'correlation_matrix_{WEEK_START}_{WEEK_END}.png',
        dpi=100,
        bbox_inches='tight'
    )
    plt.close(fig)  # 立即关闭画布，释放内存
    del fig, ax, top_corr
    gc.collect()
    print_with_flush(f"【相关矩阵】可视化图已保存为：correlation_matrix_{WEEK_START}_{WEEK_END}.png")

# ====================== 核心修改：移除视图，直接查询目标表（修复NameError）======================
def build_weekly_sql(sample_ratio):
    """
    直接构建查询dwd.dwd_sr_store_order_factor的SQL，无任何视图逻辑
    使用用户指定的原始SQL，新增采样和行数限制
    """
    query_sql = f"""
SELECT 
    expouse_time,
    hour(expouse_time) as expouse_hr,
    promotion_id,
    position,
    is_workday,
    user_id,
    client_level,
    gender,
    register_days,
    visit_days,
    last30d_visit_days,
    last30d_finish_avg_pay_amt,
    city_name,
    county_name,
    cate1_name,
    cate2_name,
    store_platform,
    store_type,
    store_brand_type,
    is_need_rating,
    promotion_rebate_type,
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    mlabel,
    promotion_quota,
    order_num
FROM {TARGET_TABLE}
WHERE date(expouse_time) between '{WEEK_START}' AND '{WEEK_END}'
  AND RAND() <= {sample_ratio}
LIMIT 350000;
    """
    return query_sql  # 仅返回查询SQL，无视图SQL

def read_weekly_data(conn, sample_ratio):
    """
    直接读取dwd.dwd_sr_store_order_factor表数据，移除所有视图相关逻辑
    修复NameError：将表名作为字符串/常量，而非变量插值
    """
    # 修复点1：表名作为字符串，不再用{dwd.dwd_sr_store_order_factor}插值
    print_with_flush(f"\n【数据读取】开始读取{TARGET_TABLE}表数据：{WEEK_START} 至 {WEEK_END}")
    query_sql = build_weekly_sql(sample_ratio)
    cursor = None  # 初始化cursor为None，避免异常时未定义
    
    try:
        cursor = conn.cursor()
        
        # 直接执行数据查询SQL（无视图创建步骤）
        print_with_flush(f"【SQL执行】开始查询{TARGET_TABLE}表...")
        cursor.execute(query_sql)
        column_names = [desc[0] for desc in cursor.description]
        print_with_flush(f"【SQL执行成功】返回字段数：{len(column_names)}，字段列表：{column_names}")
    
        # 分块读取逻辑（保留低资源优化）
        weekly_chunks = []
        total_rows = 0
        while True:
            monitor_memory(f"读取第{len(weekly_chunks)+1}块")
            rows = cursor.fetchmany(CHUNK_SIZE)
            if not rows:
                break
            df_chunk = pd.DataFrame(rows, columns=column_names)
            weekly_chunks.append(df_chunk)
            total_rows += len(df_chunk)
            if len(weekly_chunks) % 5 == 0:
                gc.collect()
    
        if not weekly_chunks:
            raise ValueError(f"【数据读取】{WEEK_START} 至 {WEEK_END} 无有效数据")
    
        final_df = pd.concat(weekly_chunks, ignore_index=True)
        
        # 统计正负样本（验证负样本保留）
        pos_sample = len(final_df[final_df[TARGET_COL] > 0])
        neg_sample = len(final_df[final_df[TARGET_COL] == 0])
        print_with_flush(f"【数据读取】完成：{len(final_df):,}行（正样本：{pos_sample:,}，负样本：{neg_sample:,} | 内存：{final_df.memory_usage(deep=True).sum()/1024/1024:.2f}MB）")
        # 验证维度字段（含expouse_hr）
        dim_cols_check = [col for col in DIMENSION_COLS if col in final_df.columns]
        print_with_flush(f"【字段验证】维度字段读取：{dim_cols_check}（共{len(dim_cols_check)}/7个）")
        # 验证expouse_hr字段
        hr_count = final_df['expouse_hr'].nunique()
        print_with_flush(f"【字段验证】expouse_hr字段共读取{hr_count}个不同小时值，字段有效")
    
        # 释放临时资源
        del weekly_chunks
        gc.collect()
        monitor_memory("数据读取完成")
        return final_df
    
    except Exception as e:
        print_with_flush(f"【数据读取失败】{str(e)}")
        raise e
    finally:
        # 修复cursor.closed错误：改用try-except安全关闭，不判断closed属性
        if cursor:
            try:
                cursor.close()
                print_with_flush("【资源释放】cursor已关闭")
            except Exception as e:
                print_with_flush(f"【资源警告】关闭cursor失败：{str(e)}")

def ultra_clean_data(df, target_col):
    """极致内存压缩：类型最小化+特征合并（保留负样本，兼容expouse_hr维度）
    核心修复：
    1. 适配pandas 1.1.5的Categorical新类别赋值逻辑
    2. 新增Decimal类型检测和转换，确保所有类别字段类型统一为字符串
    """
    print_with_flush("\n【数据清洗】开始（内存压缩+保留负样本+兼容expouse_hr）...")
    monitor_memory("清洗前")
    total_rows_before = len(df)

    # ========== 核心修复7：Decimal类型统一转换为字符串 ==========
    print_with_flush("【类型统一】检测并转换Decimal类型为字符串...")
    # 遍历所有列，检测并转换Decimal类型
    for col in df.columns:
        # 跳过数值特征列（保留数值类型）
        if col in df.select_dtypes(include=['int64', 'float64', 'int32', 'float16']).columns:
            continue
        
        # 检测列中是否有Decimal类型值
        has_decimal = False
        for val in df[col].dropna().head(100):  # 抽样检测，节省内存
            if isinstance(val, Decimal):
                has_decimal = True
                break
        
        if has_decimal:
            # 转换Decimal为字符串，同时保留其他值的类型
            df[col] = df[col].apply(lambda x: str(x) if isinstance(x, Decimal) else x)
            print_with_flush(f"【类型统一】{col}列包含Decimal类型，已转换为字符串")
    
    # 1. 类型极致压缩（用最小数据类型）
    num_cols = df.select_dtypes(include=['int64', 'float64']).columns.tolist()
    for col in num_cols:
        if df[col].dtype == 'int64':
            df[col] = pd.to_numeric(df[col], downcast='integer')  # 最小整数类型
        elif df[col].dtype == 'float64':
            df[col] = df[col].astype(np.float16)  # float16省内存

    # 2. 类别特征处理（核心修复：先替换值，再转Categorical，避免新类别报错）
    # 先收集所有需要处理的类别字段（包含expouse_hr）
    cat_cols_to_process = []
    
    # 处理expouse_hr：先转为字符串（避免数值类型问题），暂不转Categorical
    if 'expouse_hr' in df.columns:
        if pd.api.types.is_numeric_dtype(df['expouse_hr']):
            df['expouse_hr'] = df['expouse_hr'].astype(str)
            cat_cols_to_process.append('expouse_hr')
    
    # 收集所有object类型的类别字段
    cat_cols_to_process += df.select_dtypes(include=['object']).columns.tolist()
    # 去重（避免expouse_hr重复）
    cat_cols_to_process = list(set(cat_cols_to_process))
    
    # 对每个类别字段：先替换低频值为'Other'，再转Categorical（核心修复）
    for col in cat_cols_to_process:
        # 步骤1：计算高频类别（前15个）
        top_cats = df[col].value_counts().head(15).index.tolist()
        # 步骤2：先替换低频值为'Other'（此时还是object类型，无类别限制）
        df[col] = df[col].where(df[col].isin(top_cats), 'Other')
        # 步骤3：获取所有唯一值（包含'Other'），再转Categorical
        all_unique_vals = df[col].unique().tolist()
        df[col] = pd.Categorical(df[col], categories=all_unique_vals)

    # 仅过滤target_col<0的异常值，保留0值负样本
    df = df[df[target_col] >= 0]

    # 3. 缺失值填充（极简逻辑）
    # 数值型缺失用中位数填充
    num_fill = df.median(numeric_only=True)
    df = df.fillna(num_fill)
    # 类别型缺失用众数填充
    for col in cat_cols_to_process:
        if df[col].isnull().any():
            mode_val = df[col].mode().iloc[0]
            df[col] = df[col].fillna(mode_val)

    # 4. 重置索引+强制GC
    df = df.reset_index(drop=True)
    gc.collect()
    monitor_memory("清洗后")

    # 清洗后正负样本统计
    clean_pos = len(df[df[target_col] > 0])
    clean_neg = len(df[df[target_col] == 0])
    clean_rate = round((1 - len(df)/total_rows_before)*100, 2)
    print_with_flush(f"【数据清洗】完成：{len(df):,}行（正样本：{clean_pos:,}，负样本：{clean_neg:,} | 清洗率：{clean_rate}% | 内存：{df.memory_usage(deep=True).sum()/1024/1024:.2f}MB）")
    return df

# ====================== 核心优化：CPU/内存避让建模（兼容expouse_hr维度）======================
def get_ohe_feature_names(ohe, feature_names):
    """
    适配不同版本sklearn的OneHotEncoder特征名获取方法
    sklearn < 1.0: get_feature_names()
    sklearn >= 1.0: get_feature_names_out()
    """
    sklearn_version = sklearn.__version__
    print_with_flush(f"【版本适配】检测到sklearn版本：{sklearn_version}")
    
    try:
        # 优先尝试新版本API
        if hasattr(ohe, 'get_feature_names_out'):
            return ohe.get_feature_names_out(feature_names)
        else:
            # 适配旧版本API
            return ohe.get_feature_names(feature_names)
    except Exception as e:
        # 终极兼容：手动生成特征名
        print_with_flush(f"【版本适配】自动生成特征名（兼容模式）：{str(e)}")
        feature_names_list = []
        for i, feat in enumerate(feature_names):
            categories = ohe.categories_[i]
            feature_names_list += [f"{feat}_{cat}" for cat in categories]
        return feature_names_list

def high_perf_model(df, target_col, exclude_cols):
    """仅用1核+最小特征维度，避免抢占CPU，适配expouse_hr维度
    核心修复：
    1. 移除sklearn 0.24.2不支持的max_categories参数 
    2. 移除drop="first"避免与handle_unknown冲突
    3. 适配低版本sklearn的OneHotEncoder特征名获取方法（get_feature_names替代get_feature_names_out）
    """
    print_with_flush("\n【模型训练】开始（低资源模式+兼容expouse_hr维度）...")
    monitor_memory("建模前")

    # 1. 筛选字段（保留expouse_hr作为维度特征）
    X_cols = [col for col in df.columns if col not in exclude_cols + [target_col]]
    X = df[X_cols]  # 不复制，用视图减少内存
    y = df[target_col]

    # 2. 区分类别/数值特征（包含expouse_hr）
    X_cat_cols = X.select_dtypes(include=['category', 'object']).columns.tolist()
    X_num_cols = X.select_dtypes(include=['int64', 'float16', 'int32']).columns.tolist()
    print_with_flush(f"【模型训练】类别特征：{len(X_cat_cols)}个（含expouse_hr），数值特征：{len(X_num_cols)}个")

    # 3. 特征筛选（仅保留高方差特征，替代drop="first"避免共线性）
    vt = VarianceThreshold(threshold=0.05)  # 提高阈值，减少特征
    if X_num_cols:
        X_num = vt.fit_transform(X[X_num_cols])
        X_num_cols = [X_num_cols[i] for i in vt.get_support(indices=True)]

    # 4. 预处理管道（仅用1核+最小维度）
    # 构建transformers列表，避免空特征导致错误
    transformers = []
    if X_num_cols:
        transformers.append(("num", StandardScaler(), X_num_cols))
    if X_cat_cols:
        # 核心修复1：移除max_categories参数（sklearn 0.24.2不支持）
        # 核心修复2：移除drop="first"参数，避免与handle_unknown="ignore"冲突
        # 类别数限制已在数据清洗阶段完成（仅保留前15个高频类别）
        # 共线性问题通过特征筛选（VarianceThreshold）解决
        transformers.append(("cat", OneHotEncoder(
            sparse=True,          # 0.24.2版本兼容sparse参数
            handle_unknown="ignore"  # 忽略未知类别，避免报错
        ), X_cat_cols))
    
    preprocessor = ColumnTransformer(
        transformers=transformers,
        sparse_threshold=0.3,
        n_jobs=CPU_THREADS  # 仅用1核，避让其他任务
    )

    # 5. 模型管道（仅用1核）
    model_pipeline = Pipeline([
        ("preprocessor", preprocessor),
        ("regressor", LinearRegression(n_jobs=CPU_THREADS))
    ])

    # 6. 分层采样拆分训练集（保证正负样本比例）
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.15, random_state=42, 
        stratify=y.apply(lambda x: 1 if x>0 else 0)
    )

    # 7. 训练模型
    model_pipeline.fit(X_train, y_train)

    # 8. 轻量评估
    y_pred = model_pipeline.predict(X_test)
    r2 = r2_score(y_test, y_pred)
    mae = mean_absolute_error(y_test, y_pred)
    print_with_flush(f"【模型训练】完成 - R²：{r2:.4f}，MAE：{mae:.2f}")

    # 9. 提取特征名（核心修复8：适配低版本sklearn API）
    feature_names = []
    if X_num_cols:
        feature_names += X_num_cols
    if X_cat_cols:
        ohe = model_pipeline.named_steps['preprocessor'].named_transformers_['cat']
        # 核心修复：使用兼容函数获取特征名
        feature_names += get_ohe_feature_names(ohe, X_cat_cols).tolist()

    # 释放模型内存
    gc.collect()
    monitor_memory("建模后")
    return model_pipeline, feature_names, X_num_cols, X_cat_cols, r2

def calculate_contribution_optimized(model, df, X_num_cols, X_cat_cols):
    """仅取TOP20特征，减少结果数据量，适配expouse_hr维度
    核心修复：
    1. 适配低版本sklearn的OneHotEncoder特征名获取方法
    2. 修复np.where广播维度不匹配错误（改用列表推导式构建explain字段）
    """
    print_with_flush("\n【贡献度计算】开始（极简模式）...")
    monitor_memory("计算前")

    # 获取模型组件，增加存在性判断
    coef = model.named_steps['regressor'].coef_
    scaler = None
    ohe = None
    if X_num_cols:
        scaler = model.named_steps['preprocessor'].named_transformers_['num']
    if X_cat_cols:
        ohe = model.named_steps['preprocessor'].named_transformers_['cat']

    # 拼接特征名（核心修复：使用兼容函数）
    feature_names = []
    if X_num_cols:
        feature_names += X_num_cols
    if X_cat_cols and ohe:
        feature_names += get_ohe_feature_names(ohe, X_cat_cols).tolist()

    # 计算贡献度（float16省内存）
    contribution = np.zeros(len(feature_names), dtype=np.float16)
    if X_num_cols and scaler:
        num_mean = df[X_num_cols].mean().values
        num_scale = scaler.scale_
        num_scale[num_scale == 0] = 1e-8
        percent_1_change = 0.01 * num_mean
        std_change = percent_1_change / num_scale
        # 确保维度匹配：只赋值对应长度的数值特征贡献度
        num_feat_len = len(X_num_cols)
        contribution[:num_feat_len] = coef[:num_feat_len] * std_change
    if X_cat_cols:
        start_idx = len(X_num_cols) if X_num_cols else 0
        # 确保维度匹配：只赋值对应长度的类别特征贡献度
        cat_feat_len = len(feature_names) - start_idx
        contribution[start_idx:] = coef[start_idx:start_idx+cat_feat_len]

    # ========== 核心修复9：修复np.where广播维度不匹配错误 ==========
    # 替换np.where为列表推导式，逐个生成解释文本，确保维度完全匹配
    explain_list = []
    # 先构建数值特征的解释文本列表
    num_explain = [f"增1%→下单{round(c,4)}" for c in contribution[:len(X_num_cols)]] if len(X_num_cols) > 0 else []
    # 构建类别特征的解释文本列表
    cat_explain = [f"类别差→下单{round(c,4)}" for c in contribution[len(X_num_cols):]] if (len(feature_names) - len(X_num_cols)) > 0 else []
    # 合并解释文本（确保总长度和feature_names一致）
    explain_list = num_explain + cat_explain
    
    # 确保解释文本长度和特征名长度一致（兜底处理）
    if len(explain_list) < len(feature_names):
        # 补充缺失的解释文本
        explain_list += [f"未知→下单{round(c,4)}" for c in contribution[len(explain_list):]]
    elif len(explain_list) > len(feature_names):
        # 截断过长的解释文本
        explain_list = explain_list[:len(feature_names)]

    # 构建结果（仅TOP20）
    contrib_df = pd.DataFrame({
        "feature_name": feature_names,
        "contribution": contribution,
        "abs_contribution": np.abs(contribution),
        "feature_type": ["数值型" if feat in X_num_cols else "类别型" for feat in feature_names],
        "explain": explain_list,  # 使用修复后的解释列表
        "create_date": datetime.now().strftime("%Y-%m-%d"),
        "sample_ratio": SAMPLE_RATIO,
        "week_range": f"{WEEK_START}~{WEEK_END}"
    }).sort_values("abs_contribution", ascending=False, inplace=False).head(20).reset_index(drop=True)

    # 核心修复：删除临时排序列（如果贡献度表也没有该字段）
    # 如需保留abs_contribution，需确认表结构；否则删除
    if 'abs_contribution' in contrib_df.columns:
        # 检查贡献度表是否有该字段，若无则删除
        # 这里默认删除，如需保留请根据实际表结构调整
        contrib_df = contrib_df.drop(columns=['abs_contribution'])

    # 释放内存
    del coef, contribution, explain_list, num_explain, cat_explain
    gc.collect()
    monitor_memory("计算后")
    print_with_flush(f"【贡献度计算】完成：TOP1特征：{contrib_df.iloc[0]['feature_name']}")
    return contrib_df

# ====================== 结果写入（低资源+相关矩阵+SQL关键字修复）======================
def batch_insert_optimized(conn, df, result_table, batch_size):
    """通用小批次写入函数（适配贡献度/相关矩阵结果）
    核心修复10：为所有字段名添加反引号（`），避免SQL关键字冲突（如explain）
    """
    print_with_flush(f"\n【结果写入】开始写入{result_table}（小批次模式）...")
    cursor = conn.cursor()
    total_batches = (len(df) + batch_size - 1) // batch_size
    success_count = 0

    for batch_idx in range(total_batches):
        start = batch_idx * batch_size
        end = start + batch_size
        batch_data = df.iloc[start:end]

        if batch_data.empty:
            continue

        # 适配NULL值（p_value可能为None）
        batch_data = batch_data.where(pd.notnull(batch_data), None)
        
        # ========== 核心修复：字段名添加反引号，避免关键字冲突 ==========
        # 为每个字段名添加反引号（`），例如 explain → `explain`
        quoted_columns = [f"`{col}`" for col in batch_data.columns]
        columns = ", ".join(quoted_columns)
        placeholders = ", ".join(["%s"] * len(batch_data.columns))
        values = [tuple(row) for row in batch_data.values]
        insert_sql = f"INSERT INTO {result_table} ({columns}) VALUES ({placeholders})"

        try:
            cursor.executemany(insert_sql, values)
            conn.commit()
            success_count += len(batch_data)
            print_with_flush(f"【结果写入】第{batch_idx+1}/{total_batches}批成功，写入{len(batch_data)}条")
        except Exception as e:
            conn.rollback()
            print_with_flush(f"【结果写入】第{batch_idx+1}批失败：{str(e)}")
            raise e

    cursor.close()
    print_with_flush(f"【结果写入】完成：总计写入{success_count}条到{result_table}")

# ====================== 主函数（低资源入口+相关矩阵+日志适配+表检查）======================
def main():
    # 启动标记
    print_with_flush(f"===== 脚本开始执行（直接读取{TARGET_TABLE}表）=====")
    print_with_flush(f"执行时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    conn = None
    try:
        # 1. 轻量连接
        print_with_flush("\n【数据库连接】开始连接StarRocks...")
        conn = mysql.connector.connect(**SR_CONFIG)
        conn.autocommit = False
        print_with_flush("✅ StarRocks轻量连接成功")

        # ========== 新增：表存在性检查+自动创建 ==========
        # 检查并创建相关矩阵表
        if not check_and_create_table(conn, CORR_RESULT_TABLE):
            raise Exception(f"【表创建失败】无法创建/访问表 {CORR_RESULT_TABLE}")
        # 检查并创建特征贡献度表
        if not check_and_create_table(conn, RESULT_TABLE):
            raise Exception(f"【表创建失败】无法创建/访问表 {RESULT_TABLE}")

        # 2. 读取数据（直接从目标表读取，无视图）
        df_raw = read_weekly_data(conn, SAMPLE_RATIO)

        # 3. 清洗数据（兼容expouse_hr维度+类型统一）
        df_clean = ultra_clean_data(df_raw, TARGET_COL)
        del df_raw  # 立即释放原始数据内存
        gc.collect()

        # 4. 计算相关矩阵（含expouse_hr维度分析）
        corr_df = calculate_correlation_matrix(df_clean)
        # 写入相关矩阵结果
        batch_insert_optimized(conn, corr_df, CORR_RESULT_TABLE, BATCH_SIZE)
        del corr_df  # 释放相关矩阵内存
        gc.collect()

        # 5. 建模（兼容expouse_hr维度）
        model, feature_names, X_num_cols, X_cat_cols, r2 = high_perf_model(
            df_clean, TARGET_COL, EXCLUDE_COLS
        )

        # 6. 计算贡献度（仅TOP20）
        contrib_df = calculate_contribution_optimized(
            model, df_clean, X_num_cols, X_cat_cols
        )
        del df_clean  # 释放清洗后数据内存
        gc.collect()

        # 7. 写入贡献度结果
        batch_insert_optimized(conn, contrib_df, RESULT_TABLE, BATCH_SIZE)

        # 8. 任务总结
        print_with_flush("\n" + "="*60)
        print_with_flush(f"📊 低资源任务完成（{WEEK_START}~{WEEK_END} + expouse_hr维度分析）")
        print_with_flush(f"相关矩阵：已写入{CORR_RESULT_TABLE}")
        print_with_flush(f"特征贡献度：{len(contrib_df):,}条，已写入{RESULT_TABLE}")
        print_with_flush(f"模型R²：{r2:.4f}")
        print_with_flush(f"当前内存：{monitor_memory('任务完成')}GB")
        print_with_flush("="*60)

    except Exception as e:
        # 异常详情打印
        print_with_flush(f"❌ 任务失败：{str(e)}")
        print_with_flush(f"异常类型：{type(e).__name__}")
        print_with_flush(f"异常详情：{repr(e)}")
        if conn:
            try:
                conn.rollback()
                print_with_flush("【事务回滚】执行回滚成功")
            except Exception as rollback_e:
                print_with_flush(f"【回滚警告】回滚失败：{str(rollback_e)}")
        raise e

    finally:
        # 强制释放所有资源
        gc.collect()
        if conn and conn.is_connected():
            conn.close()
            print_with_flush("✅ 数据库连接已关闭")
        print_with_flush("✅ 所有资源已释放")
        print_with_flush("===== 脚本执行结束 =====")

# ====================== 低资源执行入口 =======================
if "__main__" == __name__:
    gc.collect()  # 启动前清空内存
    main()


========================================================================================== FINISH
# result

【数据读取】完成：350,000行（正样本：8,601，负样本：341,399 | 内存：444.88MB）
【字段验证】维度字段读取：['client_level', 'gender', 'city_name', 'county_name', 'cate1_name', 'cate2_name', 'expouse_hr']（共7/7个）
【字段验证】expouse_hr字段共读取24个不同小时值，字段有效

【数据清洗】完成：350,000行（正样本：8,601，负样本：341,399 | 清洗率：0.0% | 内存：14.71MB）

【相关矩阵分析】开始计算特征与order_num的相关性...
【低资源监控】相关矩阵计算前 - 已用：6.79GB / 上限：8GB
【相关矩阵】计算5个数值特征与order_num的皮尔逊相关...
【相关矩阵】计算7个维度特征（含expouse_hr）与order_num的Cramer's V...
【相关矩阵】计算8个其他类别特征与order_num的Cramer's V...

【相关矩阵】TOP10高相关特征：
               feature_name feature_type  correlation_value
                 cate1_name      类别型（维度）             0.0455
                 cate2_name      类别型（维度）             0.0444
                     mlabel    类别型（影响特征）             0.0416
       mlabel_threshold_amt    类别型（影响特征）             0.0365
          mlabel_rebate_amt    类别型（影响特征）             0.0309
                 expouse_hr      类别型（维度）             0.0227
                     gender      类别型（维度）             0.0207
 last30d_finish_avg_pay_amt    类别型（影响特征）             0.0207
                  city_name      类别型（维度）             0.0174
                county_name      类别型（维度）             0.0166



============================= 改进意见
需要纠正：
1）正样本采样不足，按照曝光到下单1.2%的转化率来看，每日3000万条曝光数据，正样本采集在360000行，但正样本只有8601条，采样严重偏差。
2）限制维度字段，expouse_hr,city_name, county_name, cate1_name, cate2_name。在维度下做逻辑回归，逐步剔除特征，得到特征重要性和回归模型公式，需要打印出公式，检验模型和系数显著性。

expouse_hr,city_name, county_name, cate1_name, cate2_name字段为维度，is_order为因变量，在维度下做逻辑回归，逐步剔除特征，得到特征重要性和回归模型公式，需要打印出公式，检验模型和系数显著性。


################ 以下为改进意见后逻辑回归








按照给到的SQL取数，order_num已转为is_order,以便做分类。限制维度字段，expouse_hr,city_name, county_name, cate1_name, cate2_name，排除promotion_id、user_id字段，其他作为特征进行带入，做逻辑回归，其他要求和上一个提问一致。

SELECT 
    expouse_time,
    hour(expouse_time) as expouse_hr,
    promotion_id,
    position,
    is_workday,
    user_id,
    client_level,
    gender,
    register_days,
    visit_days,
    last30d_visit_days,
    last30d_finish_avg_pay_amt,
    city_name,
    county_name,
    cate1_name,
    cate2_name,
    store_platform,
    store_type,
    store_brand_type,
    is_need_rating,
    mlabel_threshold_amt,
    mlabel_rebate_amt,
    mlabel_rebate_amt/mlabel_threshold_amt as rebate_ratio, -- 返现比例
    promotion_quota,
    order_num as is_order
FROM dwd.dwd_sr_store_order_factor
WHERE date(expouse_time) between '2025-12-08' AND '2025-12-14'
  and promotion_rebate_type=0
  and mlabel_threshold_amt is not null
  and mlabel_threshold_amt<>0



============================= 逻辑回归结果
【样本分布】原始数据 - 总样本：80,000 | 正样本(下单)：1,683(2.10%) | 负样本(未下单)：78,317(97.90%) | 正负比：1:46.5
【数据准备完成】最终维度：(80000, 21)

【模型训练】逻辑回归+特征选择+样本平衡...
【样本分布】拆分后训练集 - 总样本：64,000 | 正样本(下单)：1,346(2.10%) | 负样本(未下单)：62,654(97.90%) | 正负比：1:46.5
【样本分布】拆分后测试集（原始分布） - 总样本：16,000 | 正样本(下单)：337(2.11%) | 负样本(未下单)：15,663(97.89%) | 正负比：1:46.5

【样本平衡】开始处理训练集样本不平衡（纯原生Python实现）...
【样本分布】平衡后训练集 - 总样本：93,981 | 正样本(下单)：31,327(33.33%) | 负样本(未下单)：62,654(66.67%) | 正负比：1:2.0

【阈值搜索】开始网格搜索最优预测阈值（范围：[0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5]）...
【阈值搜索结果】
  阈值0.10 - 准确率：0.0422 | 召回率：1.0000 | 精确率：0.0215 | F1：0.0421
  阈值0.15 - 准确率：0.0612 | 召回率：0.9970 | 精确率：0.0219 | F1：0.0428
  阈值0.20 - 准确率：0.0840 | 召回率：0.9881 | 精确率：0.0222 | F1：0.0435
  阈值0.25 - 准确率：0.1142 | 召回率：0.9733 | 精确率：0.0226 | F1：0.0442
  阈值0.30 - 准确率：0.1545 | 召回率：0.9555 | 精确率：0.0233 | F1：0.0454
  阈值0.35 - 准确率：0.2099 | 召回率：0.9169 | 精确率：0.0239 | F1：0.0466
  阈值0.40 - 准确率：0.2927 | 召回率：0.8694 | 精确率：0.0253 | F1：0.0492
  阈值0.45 - 准确率：0.4232 | 召回率：0.8190 | 精确率：0.0292 | F1：0.0564
  阈值0.50 - 准确率：0.6018 | 召回率：0.6736 | 精确率：0.0350 | F1：0.0665
【最优阈值】选择0.50 - F1=0.0665（核心优化指标）

【模型评估结果（最优阈值）】
  AUC：0.677
  ACCURACY：0.6018
  RECALL：0.6736
  PRECISION：0.035
  F1：0.0665
  BEST_THRESHOLD：0.5

【逻辑回归方程】
  ln(P/(1-P)) = -0.207616 - 0.576907·position + 0.242925·last30d_finish_avg_pay_amt - 0.273159·mlabel_threshold_amt + 0.320156·promotion_quota

【系数显著性检验（z检验）】
                    feature coefficient std_error     z_score   p_value ci_lower_95% ci_upper_95% is_significant
                        截距项   -0.207616  0.007219  -28.760513  0.000000    -0.221765    -0.193468              是
                   position   -0.576907  0.010181  -56.662529  0.000000    -0.596863    -0.556952              是
 last30d_finish_avg_pay_amt    0.242925  0.013902   17.473734  0.000000     0.215677     0.270172              是
       mlabel_threshold_amt   -0.273159  0.009634  -28.354648  0.000000    -0.292041    -0.254277              是
            promotion_quota    0.320156  0.007205   44.434256  0.000000     0.306034     0.334278              是

  显著性水平α = 0.05
  显著特征数量：5/5

【回归方程整体显著性检验（似然比检验）】
  完整模型对数似然值：-61052.680295
  空模型对数似然值：-65142.665176
  似然比统计量（χ²）：8179.969762
  自由度：4
  p值：0.000000
  显著性水平α = 0.05
  方程整体显著：是

【特征重要性Top10】
               feature_name  feature_value  importance_score
                   position      -0.576907          0.576907
            promotion_quota       0.320156          0.320156
       mlabel_threshold_amt      -0.273159          0.273159
 last30d_finish_avg_pay_amt       0.242925          0.242925

【结果写入】开始写入特征贡献度数据...

【表结构查询】查询dwd.dwd_sr_order_feature_contrib的字段信息...
【表结构查询】dwd.dwd_sr_order_feature_contrib 字段列表：['feature_name', 'create_date', 'contribution', 'feature_type', 'explain', 'sample_ratio', 'week_range']
【字段匹配】将写入字段：['feature_name', 'create_date']
【结果写入成功】共写入4条数据


































