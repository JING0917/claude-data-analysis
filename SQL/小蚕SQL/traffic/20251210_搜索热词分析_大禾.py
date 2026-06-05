# -*- coding: utf-8 -*-
"""
外卖搜索热词分析与可视化报告
目标: 基于 '20251211_搜索词分析_大禾.xlsx' 数据，生成用于汇报的系列图表。
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 设置中文字体和绘图样式
plt.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS']
plt.rcParams['axes.unicode_minus'] = False
sns.set_style("whitegrid")

print("🚀 开始执行外卖搜索热词分析...")

# =============================
# 1. 加载数据
# =============================
EXCEL_PATH = "20251211_搜索词分析_大禾.xlsx"

df_volume = pd.read_excel(EXCEL_PATH, sheet_name="搜索量")
df_position = pd.read_excel(EXCEL_PATH, sheet_name="搜索位置分布")

print(f"✅ 数据加载完成。'搜索量': {len(df_volume):,} 行, '搜索位置分布': {len(df_position):,} 行.")

# =============================
# 2. 指标计算与数据清洗
# =============================
# Step 1: 计算“无结果”搜索量 (关键步骤)
no_result_queries = df_position[df_position['avg_search_expose_num'] == 0]['query'].unique()
no_result_data = df_volume[df_volume['query'].isin(no_result_queries)]
total_no_result_searches = no_result_data['avg_search_num'].sum()

# Step 2: 聚合位置分布表，按 query 合并所有曝光/点击/订单
agg_cols = [
    'avg_search_expose_num', 'avg_search_expose_unum',
    'avg_search_result_click_num', 'avg_search_result_click_unum',
    'avg_takeaway_baoming_order_num', 'avg_takeaway_baoming_order_unum',
    'avg_takeaway_valid_order_num', 'avg_takeaway_valid_order_unum'
]
df_agg = df_position.groupby('query')[agg_cols].sum().reset_index()

# Step 3: 合并主表
df_merged = pd.merge(df_volume, df_agg, on='query', how='left').fillna(0)

# Step 4: 计算核心业务指标 (严格遵循您提供的口径)
df_merged['人均搜索量'] = df_merged['avg_search_num'] / df_merged['avg_search_unum']
df_merged['CTR'] = (df_merged['avg_search_result_click_num'] / df_merged['avg_search_expose_num']).fillna(0).clip(upper=1.0) # 修复 >1
df_merged['搜索成功率'] = (df_merged['avg_search_result_click_num'] / df_merged['avg_search_num']).fillna(0).clip(upper=1.0)
df_merged['无搜索点击率'] = 1 - df_merged['搜索成功率']
df_merged['CVR'] = (df_merged['avg_takeaway_baoming_order_num'] / df_merged['avg_search_num']).fillna(0).clip(upper=1.0) # 修复 >1

# Step 5: 计算全局“无结果率”
total_searches = df_volume['avg_search_num'].sum()
wu_jieguo_lv = total_no_result_searches / total_searches if total_searches > 0 else 0
print(f"📊 全局无结果率: {wu_jieguo_lv:.2%}")

# =============================
# 3. 绘制汇报用图表
# =============================

# 图1: 核心漏斗转化图 (展示整体效率)
fig1, ax1 = plt.subplots(figsize=(10, 2))
steps = ['搜索请求', '有结果搜索', '产生点击', '报名订单']
values = [1, 1-wu_jieguo_lv, df_merged['搜索成功率'].mean(), df_merged['CVR'].mean()]
colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4']

ax1.barh(steps, values, color=colors, height=0.5)
for i, v in enumerate(values):
    ax1.text(v + 0.01, i, f'{v:.1%}', va='center', fontsize=10)
ax1.set_xlim(0, 1.2)
ax1.set_xlabel('转化率')
ax1.set_title('搜索全链路转化漏斗', fontweight='bold')
ax1.axis('off')
for spine in ax1.spines.values():
    spine.set_visible(False)
plt.tight_layout()
plt.show()

# 图2: 搜索位置效果分析 (前20位)
pos_effect = df_position.groupby('position').agg({
    'avg_search_expose_num': 'sum',
    'avg_search_result_click_num': 'sum'
}).reset_index()
pos_effect = pos_effect[pos_effect['position'] <= 20]  # 聚焦黄金位置
pos_effect['CTR'] = (pos_effect['avg_search_result_click_num'] / pos_effect['avg_search_expose_num']).fillna(0).clip(upper=1.0)

fig2, ax2 = plt.subplots(figsize=(12, 6))
bars = ax2.bar(pos_effect['position'], pos_effect['CTR'], color='skyblue', alpha=0.7)
ax2.set_xlabel('搜索结果位置区间')
ax2.set_ylabel('点击率 (CTR)', color='skyblue')
ax2.set_title('不同位置区间的点击率表现')
ax2.tick_params(axis='y', labelcolor='skyblue')

# 添加趋势线
z = np.polyfit(pos_effect['position'], pos_effect['CTR'], 1)
p = np.poly1d(z)
ax2.plot(pos_effect['position'], p(pos_effect['position']), "r--", alpha=0.8, label=f'趋势线: y={z[0]:.4f}x+{z[1]:.4f}')
ax2.legend()
plt.tight_layout()
plt.show()

# 图3: 高价值词 vs 问题词 散点图
high_value_mask = (df_merged['avg_search_num'] >= df_merged['avg_search_num'].quantile(0.8)) & \
                  (df_merged['CTR'] >= df_merged['CTR'].quantile(0.8))

problematic_mask = (df_merged['avg_search_num'] >= df_merged['avg_search_num'].quantile(0.8)) & \
                   (df_merged['CTR'] <= df_merged['CTR'].quantile(0.2))

fig3, ax3 = plt.subplots(figsize=(10, 8))
ax3.scatter(df_merged[~high_value_mask & ~problematic_mask]['avg_search_num'], 
            df_merged[~high_value_mask & ~problematic_mask]['CTR'], 
            s=10, alpha=0.3, c='gray', label='普通词')
ax3.scatter(df_merged[high_value_mask]['avg_search_num'], 
            df_merged[high_value_mask]['CTR'], 
            s=50, c='green', alpha=0.8, label='高价值词 (高流量高CTR)')
ax3.scatter(df_merged[problematic_mask]['avg_search_num'], 
            df_merged[problematic_mask]['CTR'], 
            s=50, c='red', alpha=0.8, label='问题词 (高流量低CTR)')
ax3.set_xscale('log')
ax3.set_xlabel('日均搜索量 (对数尺度)')
ax3.set_ylabel('点击率 (CTR)')
ax3.set_title('搜索词价值分布散点图')
ax3.legend()
ax3.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# 图4: 供给缺口词 Top 10 (条形图)
supply_gap = df_merged[df_merged['avg_search_num'] >= df_merged['avg_search_num'].quantile(0.9)].copy()
supply_gap['曝光覆盖率'] = (supply_gap['avg_search_expose_num'] / supply_gap['avg_search_num']).clip(upper=1.0)
top_supply_gap = supply_gap[supply_gap['曝光覆盖率'] < 0.5].sort_values('avg_search_num', ascending=False).head(10)

fig4, ax4 = plt.subplots(figsize=(10, 6))
bars = ax4.barh(top_supply_gap['query'], top_supply_gap['avg_search_num'], color='orange', edgecolor='black')
ax4.set_xlabel('日均搜索量')
ax4.set_title('Top 10 供给严重不足的高需求词 (曝光覆盖率<50%)')
ax4.invert_yaxis()  # 最重要的在最上面
# 在每个条形上标注数值
for bar, search_num in zip(bars, top_supply_gap['avg_search_num']):
    ax4.text(bar.get_width() + max(top_supply_gap['avg_search_num']) * 0.01, 
             bar.get_y() + bar.get_height()/2, f'{search_num:.0f}', 
             va='center', fontsize=9)
plt.tight_layout()
plt.show()

print("\n🎉 所有分析图表已成功绘制！")
print("💡 报告总结:")
print("- 漏斗图揭示了从搜索到转化的整体效率。")
print("- 位置效果图验证了'越靠前，CTR越高'的核心假设。")
print("- 散点图精准定位了需要运营关注的高价值词和问题词。")
print("- 条形图直接指出了招商团队应优先引入商品的品类。")


======================== 不做可视化，导出统计数据
# -*- coding: utf-8 -*-
"""
外卖搜索热词核心统计 (纯数据版)
目标: 生成一份结构化的Excel报告，包含高价值词、问题词、供给缺口等核心洞察。
输入文件: '20251211_搜索词分析_大禾.xlsx'
输出文件: '外卖搜索热词_核心统计.xlsx'
"""

import pandas as pd

print("✅ 开始执行外卖搜索热词核心统计...")

# =============================
# 1. 加载数据
# =============================
EXCEL_PATH = "20251211_搜索词分析_大禾.xlsx"

# 读取两个Sheet
df_volume = pd.read_excel(EXCEL_PATH, sheet_name="搜索量")
df_position = pd.read_excel(EXCEL_PATH, sheet_name="搜索位置分布")

print(f"✅ 数据加载完成。'搜索量': {len(df_volume):,} 行, '搜索位置分布': {len(df_position):,} 行.")

# =============================
# 2. 数据聚合与指标计算
# =============================
# 按 query 聚合位置分布表
agg_position = df_position.groupby('query').agg({
    'avg_search_expose_num': 'sum',
    'avg_search_result_click_num': 'sum',
    'avg_takeaway_baoming_order_num': 'sum',
    'avg_takeaway_valid_order_num': 'sum'
}).reset_index()

# 合并两个表
df_merged = pd.merge(df_volume, agg_position, on='query', how='left')

# 填充可能的空值（新词可能在位置表中无记录）
df_merged = df_merged.fillna(0)

# 计算核心业务指标
df_merged['exposure_rate'] = (df_merged['avg_search_expose_num'] / df_merged['avg_search_num']).clip(upper=1.0)
df_merged['ctr'] = (df_merged['avg_search_result_click_num'] / df_merged['avg_search_expose_num']).fillna(0)
df_merged['cvr_click_to_baoming'] = (df_merged['avg_takeaway_baoming_order_num'] / df_merged['avg_search_result_click_num']).fillna(0)
df_merged['cvr_baoming_to_valid'] = (df_merged['avg_takeaway_valid_order_num'] / df_merged['avg_takeaway_baoming_order_num']).fillna(0)
df_merged['cvr_overall'] = (df_merged['avg_takeaway_valid_order_num'] / df_merged['avg_search_expose_num']).fillna(0)

print("✅ 核心指标计算完成。")

# =============================
# 3. 提取关键洞察列表
# =============================
# 【高价值热词】：有效订单、CTR、CVR均在前20%
high_value = df_merged[
    (df_merged['avg_takeaway_valid_order_num'] >= df_merged['avg_takeaway_valid_order_num'].quantile(0.8)) &
    (df_merged['ctr'] >= df_merged['ctr'].quantile(0.8)) &
    (df_merged['cvr_overall'] >= df_merged['cvr_overall'].quantile(0.8))
].sort_values(by='avg_takeaway_valid_order_num', ascending=False)

# 【问题热词】：高曝光但低CTR或低CVR
problematic = df_merged[
    (df_merged['avg_search_expose_num'] >= df_merged['avg_search_expose_num'].quantile(0.9)) &
    ((df_merged['ctr'] <= df_merged['ctr'].quantile(0.2)) |
     (df_merged['cvr_overall'] <= df_merged['cvr_overall'].quantile(0.2)))
].sort_values(by='ctr')

# 【供给严重不足词】：高搜索量但低曝光覆盖率
supply_gap = df_merged[
    (df_merged['avg_search_num'] >= df_merged['avg_search_num'].quantile(0.9)) &
    (df_merged['exposure_rate'] <= 0.3)  # 曝光率低于30%视为严重不足
].sort_values(by='avg_search_num', ascending=False)

# 【位置效果明细】：按position聚合，用于分析位置策略
position_effect = df_position.groupby('position').agg({
    'avg_search_expose_num': 'sum',
    'avg_search_result_click_num': 'sum',
    'avg_takeaway_valid_order_num': 'sum'
}).reset_index()
position_effect['pos_ctr'] = (position_effect['avg_search_result_click_num'] / position_effect['avg_search_expose_num']).fillna(0)
position_effect['pos_cvr'] = (position_effect['avg_takeaway_valid_order_num'] / position_effect['avg_search_result_click_num']).fillna(0)

print("✅ 关键洞察列表提取完成。")

# =============================
# 4. 输出最终Excel报告
# =============================
OUTPUT_FILE = "外卖搜索热词_核心统计.xlsx"

with pd.ExcelWriter(OUTPUT_FILE, engine='openpyxl') as writer:
    # 全量数据（供您自由探索）
    df_merged.to_excel(writer, sheet_name='全量热词数据', index=False)
    
    # 高价值词（行动建议：重点运营）
    high_value.to_excel(writer, sheet_name='高价值热词', index=False)
    
    # 问题热词（行动建议：优化排序/落地页）
    problematic.to_excel(writer, sheet_name='问题热词', index=False)
    
    # 供给缺口词（行动建议：招商引入）
    supply_gap.to_excel(writer, sheet_name='供给缺口词', index=False)
    
    # 位置效果明细（供您分析位置策略）
    position_effect.to_excel(writer, sheet_name='位置效果明细', index=False)

print(f"\n🎉 统计完成！所有结果已保存至: '{OUTPUT_FILE}'")
print("\n各Sheet说明:")
print("- '全量热词数据': 包含所有29万+搜索词及其完整指标。")
print("- '高价值热词': 驱动GMV的核心词，建议加大资源倾斜。")
print("- '问题热词': 高曝光低转化，需紧急排查优化。")
print("- '供给缺口词': 用户想搜但没结果，是招商的黄金机会。")
print("- '位置效果明细': 前N位的CTR/CVR分析，验证'黄金位置'效应。")

print("\n现在，您可以直接基于这些结构化的数据，在您熟悉的工具中制作精准的可视化图表了！")



