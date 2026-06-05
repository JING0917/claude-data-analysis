"""
验证脚本 — 三个补充验证：
1. 时间分割验证：3月训练 → 4月、5月验证
2. Logistic 诊断：VIF、Pseudo R²、OR 95% CI
3. 决策树 R² 报告
"""
import pandas as pd
import numpy as np
from scipy.stats import spearmanr
from sklearn.tree import DecisionTreeRegressor
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import r2_score
import warnings
warnings.filterwarnings('ignore')

df = pd.read_pickle('data/analysis_step1_cleaned.pkl')
df['已售名额'] = df['活动名额'] - df['剩余活动名额']
df['售罄率'] = df['已售名额'] / df['活动名额']
df['人均活动名额'] = df['活动名额'] / df['活动数']

# 名额分层
bins = [0, 2.5, 5, 10, 20, 60]
labels = ['≤2.5', '2.5-5', '5-10', '10-20', '>20']
df['名额分层'] = pd.cut(df['人均活动名额'], bins=bins, labels=labels, right=True)

print("=" * 70)
print("验证1：时间分割 — 3月训练，4月、5月验证品类效应稳定性")
print("=" * 70)

model_df = df[['商家评分', '起送价_clean', '品类_大类', '是否周末', '是否节假日_num',
               '已售名额', '人均活动名额', '月份']].dropna().copy()
model_df['品类_美食'] = (model_df['品类_大类'] == '美食').astype(int)
model_df['是否开单'] = (model_df['已售名额'] > 0).astype(int)

X_cols = ['商家评分', '起送价_clean', '品类_美食', '是否周末', '是否节假日_num']
feat_names = ['商家评分', '起送价', '品类_美食', '周末', '节假日']

# --- 全样本 Logistic (baseline) ---
X_all = model_df[X_cols].values
y_all = model_df['是否开单'].values
lr_all = LogisticRegression(max_iter=1000, random_state=42).fit(X_all, y_all)

print("\n全样本 (3-5月) OR:")
for name, coef in zip(feat_names, lr_all.coef_[0]):
    print(f"  {name}: OR={np.exp(coef):.4f}")

# --- 3月训练，4月验证 ---
train_mar = model_df[model_df['月份'] == 3]
test_apr = model_df[model_df['月份'] == 4]
test_may = model_df[model_df['月份'] == 5]

lr_mar = LogisticRegression(max_iter=1000, random_state=42).fit(
    train_mar[X_cols].values, train_mar['是否开单'].values)

print(f"\n3月训练 → 4月验证 (n_train={len(train_mar)}, n_test={len(test_apr)}):")
for name, coef in zip(feat_names, lr_mar.coef_[0]):
    print(f"  {name}: OR={np.exp(coef):.4f}")

# 在4月数据上评估
y_apr_pred = lr_mar.predict_proba(test_apr[X_cols].values)[:, 1]
y_apr_true = test_apr['是否开单'].values

# 按预测概率分10组，看实际开单率
test_apr_copy = test_apr.copy()
test_apr_copy['pred_prob'] = y_apr_pred
test_apr_copy['decile'] = pd.qcut(y_apr_pred, q=10, labels=False, duplicates='drop')

print("\n  4月数据 — 预测分位 × 实际开单率 (校准检查):")
for d in sorted(test_apr_copy['decile'].unique()):
    sub = test_apr_copy[test_apr_copy['decile'] == d]
    food_pct = sub['品类_美食'].mean()
    print(f"    分位{d}: 实际开单率={sub['是否开单'].mean():.3f}, n={len(sub)}, 美食占比={food_pct:.1%}")

# 4月 AUC
from sklearn.metrics import roc_auc_score
auc_apr = roc_auc_score(y_apr_true, y_apr_pred)
print(f"\n  4月 AUC: {auc_apr:.4f}")

# --- 3月训练，5月验证 ---
print(f"\n3月训练 → 5月验证 (n_train={len(train_mar)}, n_test={len(test_may)}):")
y_may_pred = lr_mar.predict_proba(test_may[X_cols].values)[:, 1]
y_may_true = test_may['是否开单'].values

test_may_copy = test_may.copy()
test_may_copy['pred_prob'] = y_may_pred
test_may_copy['decile'] = pd.qcut(y_may_pred, q=10, labels=False, duplicates='drop')

print("\n  5月数据 — 预测分位 × 实际开单率 (校准检查):")
for d in sorted(test_may_copy['decile'].unique()):
    sub = test_may_copy[test_may_copy['decile'] == d]
    food_pct = sub['品类_美食'].mean()
    print(f"    分位{d}: 实际开单率={sub['是否开单'].mean():.3f}, n={len(sub)}, 美食占比={food_pct:.1%}")

auc_may = roc_auc_score(y_may_true, y_may_pred)
print(f"\n  5月 AUC: {auc_may:.4f}")

# 品类效应按月稳定性
print("\n品类效应按月稳定性 (各月单独 Logistic OR):")
for month, mname in [(3, '3月'), (4, '4月'), (5, '5月')]:
    sub = model_df[model_df['月份'] == month]
    lr_m = LogisticRegression(max_iter=1000, random_state=42).fit(
        sub[X_cols].values, sub['是否开单'].values)
    or_food = np.exp(lr_m.coef_[0][2])
    or_rating = np.exp(lr_m.coef_[0][0])
    print(f"  {mname}: 品类OR={or_food:.3f}, 评分OR={or_rating:.3f}, n={len(sub)}")

# ============================================================
print("\n" + "=" * 70)
print("验证2：Logistic 诊断 — VIF, Pseudo R², OR 95% CI")
print("=" * 70)

import statsmodels.api as sm

X_sm = sm.add_constant(model_df[X_cols])
y_sm = model_df['是否开单']

logit_model = sm.Logit(y_sm, X_sm).fit(disp=False)
print(logit_model.summary2())

# VIF (直接用原始X，不包含const)
from statsmodels.stats.outliers_influence import variance_inflation_factor
X_vif_raw = model_df[X_cols].values
vif_values = [variance_inflation_factor(X_vif_raw, i) for i in range(X_vif_raw.shape[1])]
vif_df = pd.DataFrame({'特征': feat_names, 'VIF': [f"{v:.2f}" for v in vif_values]})
print("\nVIF (多重共线性检查，>10 为严重，二值变量VIF偏高属正常):")
print(vif_df.to_string(index=False))

# ============================================================
print("\n" + "=" * 70)
print("验证3：所有决策树 R² 报告")
print("=" * 70)

feature_cols = ['商家评分', '起送价_clean', '品类_大类', '是否周末', '是否节假日_num']

# --- 方法1：标准化售罄率 决策树 ---
df['售罄率_zscore'] = df.groupby('名额分层', observed=False)['售罄率'].transform(
    lambda x: (x - x.mean()) / x.std())

model_df1 = df[feature_cols + ['售罄率_zscore']].dropna().copy()
model_df1['品类_美食'] = (model_df1['品类_大类'] == '美食').astype(int)

X1_feats = ['商家评分', '起送价_clean', '品类_美食', '是否周末', '是否节假日_num']
X1 = model_df1[X1_feats].values
y1 = model_df1['售罄率_zscore'].values

tree1 = DecisionTreeRegressor(max_depth=3, min_samples_leaf=3000, random_state=42)
tree1.fit(X1, y1)
r2_1 = r2_score(y1, tree1.predict(X1))
print(f"方法① 标准化树: R²={r2_1:.4f}")

# --- 方法2 Stage 2：开单后销量 ---
model_df2 = df[feature_cols + ['已售名额']].dropna().copy()
model_df2['品类_美食'] = (model_df2['品类_大类'] == '美食').astype(int)
model_df2['是否开单'] = (model_df2['已售名额'] > 0).astype(int)

sold_df = model_df2[model_df2['已售名额'] > 0].copy()
X2s = sold_df[X1_feats].values
y2s = sold_df['已售名额'].values

tree_s2 = DecisionTreeRegressor(max_depth=3, min_samples_leaf=2000, random_state=42)
tree_s2.fit(X2s, y2s)
r2_2 = r2_score(y2s, tree_s2.predict(X2s))
print(f"方法② Stage2 开单后销量树: R²={r2_2:.4f}")

# --- 方法4：残差树 ---
df4 = df[feature_cols + ['已售名额', '人均活动名额']].dropna().copy()
log_sold = np.log(df4['已售名额'].values + 1)
log_slot = np.log(df4['人均活动名额'].values)

from numpy.linalg import lstsq
A = np.column_stack([np.ones_like(log_slot), log_slot])
coeff, _, _, _ = lstsq(A, log_sold)
log_sold_pred = coeff[0] + coeff[1] * log_slot
df4['超额销量_log'] = log_sold - log_sold_pred
df4['品类_美食'] = (df4['品类_大类'] == '美食').astype(int)

X4 = df4[X1_feats].values
y4 = df4['超额销量_log'].values

tree4 = DecisionTreeRegressor(max_depth=3, min_samples_leaf=3000, random_state=42)
tree4.fit(X4, y4)
r2_4 = r2_score(y4, tree4.predict(X4))
print(f"方法④ 残差树: R²={r2_4:.4f}")

# --- 品类-only 的 R² 参考 ---
# 用仅含品类的 Logistic 看伪 R²
X_food_only = sm.add_constant(model_df[['品类_美食']])
logit_food = sm.Logit(y_sm, X_food_only).fit(disp=False)
print(f"\n仅品类 Logistic — Pseudo R²={logit_food.prsquared:.4f}")

# 品类对销量的直接区分力（不控制任何变量）
food_rates = model_df.groupby('品类_美食')['是否开单'].mean()
print(f"  美食开单率: {food_rates.get(1, 0):.1%}")
print(f"  非美食开单率: {food_rates.get(0, 0):.1%}")
print(f"  原始差异: {food_rates.get(1, 0) - food_rates.get(0, 0):.1%}")

# ============================================================
print("\n" + "=" * 70)
print("补充：评分与起送价的非线性检查")
print("=" * 70)

# 检查评分是否有阈值效应（超过某个值后不再递增）
for layer in labels:
    sub = df[(df['名额分层'] == layer) & (df['品类_大类'] == '美食')]
    if len(sub) < 1000:
        continue
    # 细分评分档
    fine_bins = [0, 4.0, 4.2, 4.4, 4.5, 4.6, 4.7, 4.8, 5.0]
    fine_labels = ['<4.0', '4.0-4.2', '4.2-4.4', '4.5', '4.6', '4.7', '4.8', '>4.8']
    sub_copy = sub.copy()
    sub_copy['评分_细档'] = pd.cut(sub_copy['商家评分'], bins=fine_bins, labels=fine_labels)
    rates = sub_copy.groupby('评分_细档', observed=False)['售罄率'].mean()
    mono = rates.is_monotonic_increasing
    print(f"  {layer}: 细评分单调={mono}, 最低档={rates.iloc[0]:.3f}, 最高档={rates.iloc[-1]:.3f}")

print("\n完成 — 三个验证全部结束")
