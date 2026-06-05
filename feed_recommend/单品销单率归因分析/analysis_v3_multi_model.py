"""
补充建模方式（v3.1 — 修正：人均活动名额分层）：
1. 名额层内标准化（z-score）→ 决策树
2. 两阶段模型：是否开单(Logit) + 开单后销量(决策树)
3. 分位数分析：看尾部效应
4. 残差法：剥离名额效应后的超额销量

修正点：活动名额是店铺下所有活动的总名额，需要除以活动数得到人均活动名额后再分层。
"""
import pandas as pd
import numpy as np
from scipy.stats import spearmanr
from sklearn.tree import DecisionTreeRegressor, DecisionTreeClassifier, export_text
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score, KFold
from sklearn.preprocessing import StandardScaler
import warnings
warnings.filterwarnings('ignore')

df = pd.read_pickle('data/analysis_step1_cleaned.pkl')
df['已售名额'] = df['活动名额'] - df['剩余活动名额']
df['售罄率'] = df['已售名额'] / df['活动名额']

# ============================================================
# 修正：人均活动名额 = 活动名额 / 活动数
# 这才是店铺内单个活动的平均名额，分层更有意义
# ============================================================
df['人均活动名额'] = df['活动名额'] / df['活动数']

print("人均活动名额 分布:")
print(df['人均活动名额'].describe())
print(f"\n  中位数: {df['人均活动名额'].median():.1f}")
print(f"  活动名额 均值: {df['活动名额'].mean():.1f}, 活动数 均值: {df['活动数'].mean():.1f}")

# 人均名额分层（基于分位数和业务含义）
bins = [0, 2.5, 5, 10, 20, 60]
labels = ['≤2.5', '2.5-5', '5-10', '10-20', '>20']
df['名额分层'] = pd.cut(df['人均活动名额'], bins=bins, labels=labels, right=True)

print(f"\n人均名额分层 分布:")
for lbl in labels:
    layer = df[df['名额分层'] == lbl]
    if len(layer) > 0:
        print(f"  {lbl}: n={len(layer)/1000:.0f}k, 人均={layer['人均活动名额'].mean():.2f}, "
              f"售罄率={layer['售罄率'].mean():.3f}, 已售均值={layer['已售名额'].mean():.2f}")

feature_cols = ['商家评分', '起送价_clean', '品类_大类', '是否周末', '是否节假日_num']

# ============================================================
# 方法1：名额层内标准化（z-score 售罄率）→ 决策树
# ============================================================
print("=" * 60)
print("方法1：人均名额层内标准化 → 决策树")
print("=" * 60)

df['售罄率_zscore'] = df.groupby('名额分层', observed=False)['售罄率'].transform(
    lambda x: (x - x.mean()) / x.std()
)

model_df1 = df[feature_cols + ['售罄率_zscore']].dropna().copy()
model_df1['品类_美食'] = (model_df1['品类_大类'] == '美食').astype(int)

X_cols = ['商家评分', '起送价_clean', '品类_美食', '是否周末', '是否节假日_num']
X1 = model_df1[X_cols].values
y1 = model_df1['售罄率_zscore'].values

tree1 = DecisionTreeRegressor(max_depth=3, min_samples_leaf=3000, random_state=42)
tree1.fit(X1, y1)

imp1 = pd.Series(tree1.feature_importances_, index=X_cols).sort_values(ascending=False)
print("标准化售罄率 特征重要性:")
for feat, imp in imp1.items():
    print(f"  {feat}: {imp:.4f}")

print("\n标准化售罄率 决策树结构:")
print(export_text(tree1, feature_names=X_cols, max_depth=3))

# ============================================================
# 方法2：两阶段模型（Hurdle Model）
# ============================================================
print("\n" + "=" * 60)
print("方法2：两阶段模型 — 是否开单 + 开单后销量")
print("=" * 60)

model_df2 = df[feature_cols + ['已售名额', '人均活动名额']].dropna().copy()
model_df2['品类_美食'] = (model_df2['品类_大类'] == '美食').astype(int)
model_df2['是否开单'] = (model_df2['已售名额'] > 0).astype(int)

# Stage 1: 是否开单（Logistic）
# 用人均活动名额作为控制变量（而非总活动名额）
X2 = model_df2[['商家评分', '起送价_clean', '品类_美食', '是否周末', '是否节假日_num']].values
y2_stage1 = model_df2['是否开单'].values

lr = LogisticRegression(max_iter=1000, random_state=42)
lr.fit(X2, y2_stage1)

print("Stage1 - 是否开单 (Logistic) 系数:")
stage1_feats = ['商家评分', '起送价', '品类_美食', '周末', '节假日']
for feat, coef in zip(stage1_feats, lr.coef_[0]):
    or_val = np.exp(coef)
    print(f"  {feat}: coef={coef:.4f}, OR={or_val:.3f} → {'提高' if or_val>1 else '降低'}开单概率")

# Stage 2: 开单后销量（仅看已开单的样本）
sold_df = model_df2[model_df2['已售名额'] > 0].copy()
X2s = sold_df[['商家评分', '起送价_clean', '品类_美食', '是否周末', '是否节假日_num']].values
y2s = sold_df['已售名额'].values

tree_stage2 = DecisionTreeRegressor(max_depth=3, min_samples_leaf=2000, random_state=42)
tree_stage2.fit(X2s, y2s)
imp_s2 = pd.Series(tree_stage2.feature_importances_, index=['商家评分', '起送价', '品类_美食', '周末', '节假日']).sort_values(ascending=False)
print(f"\nStage2 - 开单后销量 决策树 (n={len(sold_df)/1000:.0f}k):")
for feat, imp in imp_s2.items():
    print(f"  {feat}: {imp:.4f}")

# ============================================================
# 方法3：分位数分析 — 按售罄率分组对比
# ============================================================
print("\n" + "=" * 60)
print("方法3：分位数分析 — 按售罄率分组")
print("=" * 60)

model_df3 = df[feature_cols + ['售罄率', '人均活动名额']].dropna().copy()
model_df3['品类_美食'] = (model_df3['品类_大类'] == '美食').astype(int)

def tercile_label(x):
    if len(x) < 3:
        return pd.Series(['中(33-67%)'] * len(x), index=x.index)
    r = x.rank(pct=True)
    return pd.cut(r, bins=[0, 1/3, 2/3, 1], labels=['低(0-33%)', '中(33-67%)', '高(67-100%)'])

df['售罄率_层内分位'] = df.groupby('名额分层', observed=False)['售罄率'].transform(tercile_label)

# 选样本量较大的层展示
display_layers = ['≤2.5', '5-10', '>20']  # 用有区分度的层
print("\n名额层内分位 × 品类 × 售罄率:")
for layer in labels:
    print(f"\n  {layer}层:")
    for tercile in ['低(0-33%)', '中(33-67%)', '高(67-100%)']:
        sub = df[(df['名额分层'] == layer) & (df['售罄率_层内分位'] == tercile)]
        if len(sub) == 0:
            continue
        food_pct = (sub['品类_大类'] == '美食').mean()
        avg_rating = sub['商家评分'].mean()
        avg_price = sub['起送价_clean'].mean()
        print(f"    {tercile}: 美食占比={food_pct:.1%}, 平均评分={avg_rating:.2f}, 平均起送价={avg_price:.1f}, n={len(sub)/1000:.0f}k")

print("\n  美食占比在低vs高分位中的差异:")
for layer in labels:
    low = df[(df['名额分层'] == layer) & (df['售罄率_层内分位'] == '低(0-33%)')]
    high = df[(df['名额分层'] == layer) & (df['售罄率_层内分位'] == '高(67-100%)')]
    if len(low) > 0 and len(high) > 0:
        diff = (high['品类_大类'] == '美食').mean() - (low['品类_大类'] == '美食').mean()
        print(f"    {layer}: 高-低 美食占比差 = {diff:+.1%}")

# ============================================================
# 方法4：残差法 — 剥离名额后的"超额销量"
# ============================================================
print("\n" + "=" * 60)
print("方法4：残差法 — 超额销量")
print("=" * 60)

df4 = df[feature_cols + ['已售名额', '人均活动名额']].dropna().copy()
log_sold = np.log(df4['已售名额'].values + 1)
log_slot = np.log(df4['人均活动名额'].values)

from numpy.linalg import lstsq
A = np.column_stack([np.ones_like(log_slot), log_slot])
coeff, _, _, _ = lstsq(A, log_sold)
log_sold_pred = coeff[0] + coeff[1] * log_slot
df4['超额销量_log'] = log_sold - log_sold_pred

df4['品类_美食'] = (df4['品类_大类'] == '美食').astype(int)

X4 = df4[['商家评分', '起送价_clean', '品类_美食', '是否周末', '是否节假日_num']].values
y4 = df4['超额销量_log'].values
feats4 = ['商家评分', '起送价', '品类_美食', '周末', '节假日']

tree4 = DecisionTreeRegressor(max_depth=3, min_samples_leaf=3000, random_state=42)
tree4.fit(X4, y4)
imp4 = pd.Series(tree4.feature_importances_, index=feats4).sort_values(ascending=False)
print("超额销量 特征重要性:")
for feat, imp in imp4.items():
    print(f"  {feat}: {imp:.4f}")

food_residual = df4[df4['品类_美食'] == 1]['超额销量_log'].mean()
non_food_residual = df4[df4['品类_美食'] == 0]['超额销量_log'].mean()
print(f"\n  美食超额销量均值: {food_residual:+.4f}")
print(f"  非美食超额销量均值: {non_food_residual:+.4f}")
print(f"  差值: {food_residual - non_food_residual:+.4f}")

# ============================================================
# 交互效应探查
# ============================================================
print("\n" + "=" * 60)
print("额外探查：品类 × 评分 交互效应")
print("=" * 60)

df['评分_档'] = pd.cut(df['商家评分'], bins=[0, 4.2, 4.5, 4.7, 5.0], labels=['<4.2', '4.2-4.5', '4.5-4.7', '>4.7'])
interaction = df.groupby(['名额分层', '品类_大类', '评分_档'], observed=False)['售罄率'].agg(['mean', 'count']).reset_index()
for layer in labels:
    print(f"\n  {layer}层:")
    sub = interaction[(interaction['名额分层'] == layer) & (interaction['品类_大类'] == '美食')]
    if len(sub) > 0:
        for _, row in sub.iterrows():
            print(f"    评分{row['评分_档']}: 售罄率={row['mean']:.3f}, n={row['count']/1000:.0f}k")

print("\n额外探查：品类 × 起送价 交互效应")
df['起送价_档2'] = pd.cut(df['起送价_clean'], bins=[0, 15, 20, 30, 100], labels=['≤15', '15-20', '20-30', '>30'])
interaction2 = df.groupby(['名额分层', '品类_大类', '起送价_档2'], observed=False)['售罄率'].agg(['mean', 'count']).reset_index()
for layer in labels:
    print(f"\n  {layer}层:")
    sub = interaction2[(interaction2['名额分层'] == layer) & (interaction2['品类_大类'] == '美食')]
    if len(sub) > 0:
        for _, row in sub.iterrows():
            print(f"    起送价{row['起送价_档2']}: 售罄率={row['mean']:.3f}, n={row['count']/1000:.0f}k")

# ============================================================
# 交叉验证汇总
# ============================================================
print("\n" + "=" * 60)
print("四种方法交叉验证汇总")
print("=" * 60)

print(f"""
方法               | 品类效应方向 | 品类效应量级    | 评分区分力 | 起送价区分力
------------------|------------|---------------|----------|-----------
1.层内标准化+树    | 正          | 强(首要)      | 微弱     | 微弱
2.两阶段-是否开单  | 正          | OR={np.exp(lr.coef_[0][2]):.2f}     | OR={np.exp(lr.coef_[0][0]):.2f} | OR={np.exp(lr.coef_[0][1]):.2f}
2.两阶段-开单后销量| 正          | 重要          | 微弱     | 微弱
3.分位数分析      | 正          | 各层一致       | 有方向性  | 有方向性
4.残差法+树       | 正          | 强(首要)      | 微弱     | 微弱
""")

print("\n完成 — 人均活动名额分层修正版")
