"""
修正版分析：
- 目标变量：已售名额（= 活动名额 - 剩余活动名额）
- 控制变量：活动名额（分层 + offset）
- 待评估特征：商家评分、起送价、品类、城市、活动数、节假日、周末
"""
import pandas as pd
import numpy as np
from scipy.stats import spearmanr, kruskal, mannwhitneyu
from sklearn.tree import DecisionTreeRegressor
from sklearn.model_selection import KFold
from sklearn.preprocessing import LabelEncoder
import warnings
warnings.filterwarnings('ignore')

df = pd.read_pickle('data/analysis_step1_cleaned.pkl')

# ============================================================
# 构造正确目标
# ============================================================
df['已售名额'] = df['活动名额'] - df['剩余活动名额']

# 售罄率（与销单率同义，避免误解）
df['售罄率'] = df['已售名额'] / df['活动名额']

print("目标变量: 已售名额 (= 活动名额 - 剩余活动名额)")
print(f"  均值: {df['已售名额'].mean():.2f}, 中位数: {df['已售名额'].median():.0f}")
print(f"  0销量占比: {(df['已售名额']==0).mean()*100:.1f}%")
print(f"  售罄率均值: {df['售罄率'].mean():.3f}")

# ============================================================
# 名额分层定义
# ============================================================
bins = [1, 3, 5, 8, 10, 15, 30, 200]
labels = ['1-2', '3-4', '5-7', '8-9', '10-14', '15-29', '30+']
df['名额分层'] = pd.cut(df['活动名额'], bins=bins, labels=labels, right=True)

print(f"\n各层分布:")
for lbl in labels:
    layer = df[df['名额分层'] == lbl]
    if len(layer) > 0:
        print(f"  {lbl}: n={len(layer)/1000:.0f}k, 售罄率均值={layer['售罄率'].mean():.3f}, "
              f"已售名额均值={layer['已售名额'].mean():.2f}, 活动名额均值={layer['活动名额'].mean():.2f}")

# ============================================================
# 第一层：分层内对比 —— 名额层内，高售 vs 低售
# ============================================================
print("\n" + "=" * 60)
print("第一层：名额分层内，高售 vs 低售特征对比")
print("=" * 60)

num_features = ['商家评分', '起送价_clean', '活动数']
cat_features = ['品类_大类', '是否周末', '是否节假日']

# 数值特征：层内 Mann-Whitney U 检验 + 均值差
print("\n[1a] 数值特征 — 分层内高售(>p50) vs 低售(≤p50) 均值差：")

layer_results = {}
for feat in num_features + cat_features:
    layer_results[feat] = []

for layer_name in labels:
    layer = df[df['名额分层'] == layer_name]
    if len(layer) < 100:
        continue
    median_sold = layer['已售名额'].median()
    if median_sold == 0:
        # 如果层内中位数为0，用均值二分
        mean_sold = layer['已售名额'].mean()
        high = layer[layer['已售名额'] >= mean_sold]
        low = layer[layer['已售名额'] < mean_sold]
    else:
        high = layer[layer['已售名额'] > median_sold]
        low = layer[layer['已售名额'] <= median_sold]

    for feat in num_features:
        h_mean = high[feat].mean()
        l_mean = low[feat].mean()
        diff = h_mean - l_mean
        _, p = mannwhitneyu(high[feat].dropna(), low[feat].dropna(), alternative='two-sided')
        layer_results[feat].append({
            'layer': layer_name, '高售均值': round(h_mean, 3), '低售均值': round(l_mean, 3),
            '差值': round(diff, 3), 'p值': p, '方向': '高>低' if diff > 0 else '低>高'
        })

    for feat in cat_features:
        high_rate = (high[feat] == 1).mean() if feat in ['是否周末', '是否节假日'] else (high[feat] == '美食').mean()
        low_rate = (low[feat] == 1).mean() if feat in ['是否周末', '是否节假日'] else (low[feat] == '美食').mean()
        diff = high_rate - low_rate
        layer_results[feat].append({
            'layer': layer_name, '高售占比': round(high_rate, 3), '低售占比': round(low_rate, 3),
            '差值': round(diff, 3), '方向': '高>低' if diff > 0 else '低>高'
        })

for feat in num_features:
    diffs = [r['差值'] for r in layer_results[feat]]
    consistent = all(d > 0 for d in diffs) or all(d < 0 for d in diffs)
    avg_diff = np.mean(diffs)
    print(f"  {feat}: 平均差值={avg_diff:+.4f}, 各层方向一致={consistent}, 各层差值={[f'{d:+.3f}' for d in diffs]}")

for feat in cat_features:
    diffs = [r['差值'] for r in layer_results[feat]]
    consistent = all(d > 0 for d in diffs) or all(d < 0 for d in diffs)
    avg_diff = np.mean(diffs)
    print(f"  {feat}: 平均差值={avg_diff:+.4f}, 各层方向一致={consistent}, 各层差值={[f'{d:+.3f}' for d in diffs]}")

# 品类详细
print("\n[1b] 品类 — 分层内美食 vs 非美食 售罄率对比:")
for layer_name in labels:
    layer = df[df['名额分层'] == layer_name]
    if len(layer) < 100:
        continue
    food = layer[layer['品类_大类'] == '美食']
    non_food = layer[layer['品类_大类'] != '美食']
    if len(food) > 100 and len(non_food) > 100:
        print(f"  {layer_name}: 美食={food['售罄率'].mean():.3f} (n={len(food)/1000:.0f}k), "
              f"非美食={non_food['售罄率'].mean():.3f} (n={len(non_food)/1000:.0f}k), "
              f"差值={food['售罄率'].mean() - non_food['售罄率'].mean():+.3f}")

# 城市详细
print("\n[1c] 城市 — 分层内有足够样本的城市对比:")
# 选样本量 top10 城市
top_cities = df.groupby('城市').size().nlargest(10).index
for layer_name in labels:
    layer = df[df['名额分层'] == layer_name]
    if len(layer) < 100:
        continue
    city_rates = {}
    for city in top_cities:
        cdata = layer[layer['城市'] == city]
        if len(cdata) >= 200:
            city_rates[city] = cdata['售罄率'].mean()
    if len(city_rates) >= 3:
        sorted_cities = sorted(city_rates.items(), key=lambda x: x[1], reverse=True)
        best, worse = sorted_cities[0], sorted_cities[-1]
        print(f"  {layer_name}: 最高={best[0]}({best[1]:.3f}), 最低={worse[0]}({worse[1]:.3f}), 差值={best[1]-worse[1]:+.3f}")

# ============================================================
# 第二层：控制名额后的回归（Poisson + offset）
# ============================================================
print("\n" + "=" * 60)
print("第二层：回归分析（Poisson GLM + log(活动名额) offset）")
print("=" * 60)

import statsmodels.api as sm

feat_cols = ['商家评分', '起送价_clean', '活动数', '是否节假日_num', '是否周末', '品类_大类']
model_df = df[feat_cols + ['活动名额', '已售名额']].dropna().copy()
model_df['品类_美食'] = (model_df['品类_大类'] == '美食').astype(int)
model_df['log_名额'] = np.log(model_df['活动名额'])

X_feats = ['商家评分', '起送价_clean', '活动数', '是否节假日_num', '是否周末', '品类_美食']
X = sm.add_constant(model_df[X_feats])
y = model_df['已售名额']
offset = model_df['log_名额']

poisson_model = sm.GLM(y, X, family=sm.families.Poisson(), offset=offset).fit()
print(poisson_model.summary().tables[1])

# 边际效应
print("\n[2a] 边际效应（exp(coef) = 乘数效应）:")
for feat, coef in zip(['const'] + X_feats, poisson_model.params):
    exp_coef = np.exp(coef)
    print(f"  {feat}: coef={coef:.4f}, exp(coef)={exp_coef:.4f} "
          f"→ 该特征+1单位 → 已售名额×{exp_coef:.3f}")

# ============================================================
# 第三层：决策树（带控制变量）
# ============================================================
print("\n" + "=" * 60)
print("第三层：决策树 — 加入活动名额作为特征后看剩余特征重要性")
print("=" * 60)

tree_df = df[['商家评分', '起送价_clean', '活动数', '是否节假日_num', '是否周末',
               '品类_大类', '城市', '活动名额', '已售名额']].dropna().copy()
tree_df = pd.get_dummies(tree_df, columns=['品类_大类', '城市'], drop_first=False)

all_feats = [c for c in tree_df.columns if c not in ['已售名额']]
X_tree = tree_df[all_feats].values
y_tree = tree_df['已售名额'].values
feat_names_tree = list(all_feats)

# 不限制名额的深度，让它自然分裂
tree_v2 = DecisionTreeRegressor(max_depth=4, min_samples_leaf=3000, random_state=42)
tree_v2.fit(X_tree, y_tree)

importances_v2 = pd.Series(tree_v2.feature_importances_, index=feat_names_tree).sort_values(ascending=False)
print("特征重要性 Top 15:")
for feat, imp in importances_v2.head(15).items():
    print(f"  {feat}: {imp:.4f}")

# 看活动名额占多少，其余特征占多少
slot_imps = sum(v for k, v in importances_v2.items() if '活动名额' in k)
other_imps = importances_v2[~importances_v2.index.str.contains('活动名额')].head(10)
print(f"\n  活动名额合计重要性: {slot_imps:.4f}")
print(f"  其余特征Top10合计: {other_imps.sum():.4f}")
print(f"\n  其余特征Top10:")
for feat, imp in other_imps.items():
    print(f"    {feat}: {imp:.4f}")

# 控制名额后，看其余特征的区分力
# 在名额≤8.5的层内单独跑树
small_slot = tree_df[tree_df['活动名额'] <= 8.5].copy()
small_feats = [c for c in all_feats if c != '活动名额']  # 去掉名额
X_small = small_slot[small_feats].values
y_small = small_slot['已售名额'].values
tree_small = DecisionTreeRegressor(max_depth=3, min_samples_leaf=3000, random_state=42)
tree_small.fit(X_small, y_small)
imp_small = pd.Series(tree_small.feature_importances_, index=small_feats).sort_values(ascending=False)
print(f"\n  名额≤8.5层内特征重要性 (控制名额后):")
for feat, imp in imp_small.head(10).items():
    print(f"    {feat}: {imp:.4f}")

# ============================================================
# 稳健性检查
# ============================================================
print("\n" + "=" * 60)
print("稳健性：名额层内稳定性")
print("=" * 60)

# 3月 vs 4月，在各名额层内比较品类效应
print("\n  品类（美食vs非美食）在各层各月的售罄率差异:")
for layer_name in labels:
    for month, mname in [(3, '3月'), (4, '4月'), (5, '5月')]:
        layer = df[(df['名额分层'] == layer_name) & (df['月份'] == month)]
        if len(layer) < 200:
            continue
        food = layer[layer['品类_大类'] == '美食']['售罄率'].mean()
        non_food = layer[layer['品类_大类'] != '美食']['售罄率'].mean()
        if not pd.isna(food) and not pd.isna(non_food):
            print(f"    {layer_name} {mname}: 美食={food:.3f}, 非美食={non_food:.3f}, 差值={food-non_food:+.3f}")

# ============================================================
# 结论总结
# ============================================================
print("\n" + "=" * 60)
print("结论")
print("=" * 60)

# 计算品类效应的量级
food_effect = df.groupby(['名额分层', '品类_大类'])['售罄率'].mean().unstack()
if '美食' in food_effect.columns and '非美食' in food_effect.columns:
    food_diff = (food_effect['美食'] - food_effect['非美食']).mean()
    print(f"品类效应（名额控制后）: 美食比非美食售罄率高 {food_diff:.1%}")

# 计算起送价的效应量级
for layer_name in labels:
    layer = df[df['名额分层'] == layer_name]
    if len(layer) < 100:
        continue
    median_price = layer['起送价_clean'].median()
    low_price = layer[layer['起送价_clean'] <= median_price]['售罄率'].mean()
    high_price = layer[layer['起送价_clean'] > median_price]['售罄率'].mean()
    # Only print first 3 layers to avoid spam
    if labels.index(layer_name) < 3:
        print(f"起送价效应 {layer_name}: 低起送价={low_price:.3f}, 高起送价={high_price:.3f}, 差值={low_price-high_price:+.3f}")

print("\n分析完成。保存结果。")
import pickle
results_v2 = {
    'layer_results': layer_results,
    'poisson_summary': str(poisson_model.summary()),
    'poisson_params': poisson_model.params.to_dict(),
    'tree_importances_v2': importances_v2.to_dict(),
    'tree_small_imp': imp_small.to_dict(),
    'food_effect': food_effect.to_dict() if 'food_effect' in dir() else None
}
with open('output/analysis_v2_results.pkl', 'wb') as f:
    pickle.dump(results_v2, f)
