import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from datetime import datetime

plt.rcParams['font.family'] = ['Arial Unicode MS', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

# ============================================================
# Figure 5: 分析时间窗口 — Gantt-style timeline
# ============================================================
fig5, ax5 = plt.subplots(1, 1, figsize=(16, 4.5))
fig5.set_facecolor('#FAFBFC')
ax5.set_facecolor('#FAFBFC')

windows = [
    ('W14', '04/01', '04/05', 0, '基线期'),
    ('W15', '04/06', '04/12', 1, '基线期'),
    ('W16', '04/13', '04/19', 2, '基线期'),
    ('W17', '04/20', '04/26', 3, '异常尖峰\n(已消退)'),
    ('W18', '04/27', '05/03', 4, '五一假期'),
    ('W19', '05/04', '05/10', 5, '过渡期'),
    ('W20', '05/11', '05/17', 6, '当前期'),
    ('W21', '05/18', '05/24', 7, '当前期'),
    ('W22', '05/25', '05/27', 8, '当前期\n(3天)'),
]

color_map = {
    '基线期': '#3498DB',
    '异常尖峰\n(已消退)': '#E74C3C',
    '五一假期': '#F39C12',
    '过渡期': '#95A5A6',
    '当前期': '#27AE60',
    '当前期\n(3天)': '#27AE60',
}

bar_height = 0.45
y_pos = 1.5

for name, start, end, idx, category in windows:
    x_start = idx * 1.05
    x_len = 0.85
    color = color_map.get(category, '#95A5A6')
    alpha = 0.3 if category in ['异常尖峰\n(已消退)', '五一假期'] else 0.85

    rect = FancyBboxPatch((x_start, y_pos - bar_height / 2), x_len, bar_height,
                          boxstyle='round,pad=0.06', facecolor=color, edgecolor=color,
                          linewidth=2, alpha=alpha)
    ax5.add_patch(rect)
    ax5.text(x_start + x_len / 2, y_pos, name, ha='center', va='center',
             fontsize=11, fontweight='bold', color='white' if alpha > 0.5 else color)
    ax5.text(x_start + x_len / 2, y_pos - 0.65, f'{start}~{end}', ha='center', va='center',
             fontsize=8, color='#555555')

# Category labels above
cat_positions = {}
for name, start, end, idx, category in windows:
    if category not in cat_positions:
        cat_positions[category] = []
    cat_positions[category].append(idx)

# Legend on top
legend_items = [
    ('基线期 (W14-W16)', '#3498DB'),
    ('异常尖峰 (W17)', '#E74C3C'),
    ('假期扰动 (W18)', '#F39C12'),
    ('过渡期 (W19)', '#95A5A6'),
    ('当前期 (W20-W22)', '#27AE60'),
]
for i, (label, color) in enumerate(legend_items):
    ax5.text(1.2 + i * 2.6, 2.9, label, fontsize=9, ha='center', va='center',
             color=color, fontweight='bold',
             bbox=dict(boxstyle='round,pad=0.25', facecolor='white', edgecolor=color, alpha=0.7))

# Core comparison annotation
ax5.annotate('', xy=(6.5, y_pos + 0.9), xytext=(1.5, y_pos + 0.9),
            arrowprops=dict(arrowstyle='<->', color='#2C3E50', lw=2.5))
ax5.text(4.0, y_pos + 1.25, '核心对比：基线期 vs 当前期', ha='center', fontsize=11,
         fontweight='bold', color='#2C3E50',
         bbox=dict(boxstyle='round,pad=0.3', facecolor='#F5F5F5', edgecolor='#2C3E50', alpha=0.85))

# April/May dividers
ax5.axvline(x=3.5, color='#BDC3C7', linewidth=1, linestyle='--', alpha=0.5)
ax5.text(3.5, y_pos - 1.0, '← 4月  |  5月 →', ha='center', fontsize=9, color='#888888')

ax5.set_xlim(-0.3, 9.3)
ax5.set_ylim(0.3, 3.3)
ax5.axis('off')
ax5.set_title('分析时间窗口', fontsize=15, fontweight='bold', color='#1a1a1a', pad=12)

fig5.tight_layout(pad=1)
fig5.savefig('analysis_reports/会话分析_时间窗口.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig5)
print('Figure 5 saved: 会话分析_时间窗口.png')

# ============================================================
# Figure 6: 验证结果汇总 — visual summary cards
# ============================================================
fig6, ax6 = plt.subplots(1, 1, figsize=(16, 3.5))
fig6.set_facecolor('#FAFBFC')
ax6.set_facecolor('#FAFBFC')
ax6.set_xlim(0, 16)
ax6.set_ylim(0, 3.5)
ax6.axis('off')

verifications = [
    {'title': '增幅是否稳定', 'method': 'Bootstrap ×10,000次',
     'result': '95%CI [0.12pp, 0.18pp]\n全部 > 0', 'verdict': '✓ 信号真实', 'color': '#27AE60'},
    {'title': '近期有无突变', 'method': '回归残差检验',
     'result': '最近7天 |偏差| 均 < 1σ\n无单日异常', 'verdict': '✓ 缓慢爬坡', 'color': '#27AE60'},
    {'title': '有无结构断裂', 'method': 'Chow检验 (排除W17)',
     'result': 'F=0.66, p=0.52\n不显著', 'verdict': '✓ 无断崖变化', 'color': '#27AE60'},
    {'title': '是否星期假象', 'method': '星期分层 + 反事实推演',
     'result': '七天全部上升\n反事实≠实际', 'verdict': '✓ 排除假象', 'color': '#27AE60'},
    {'title': '人均次数是否异常', 'method': '变异系数 (CV)',
     'result': 'CV=0.61%, 极稳定\n≈1.1条/人/天', 'verdict': '✓ 业务常态', 'color': '#27AE60'},
]

card_w = 2.8
card_h = 2.6
spacing = (16 - 0.5 - len(verifications) * card_w) / (len(verifications) - 1) if len(verifications) > 1 else 3

for i, v in enumerate(verifications):
    x = 0.5 + i * (card_w + spacing)
    y_bottom = 0.4

    rect = FancyBboxPatch((x, y_bottom), card_w, card_h,
                          boxstyle='round,pad=0.25', facecolor='white',
                          edgecolor=v['color'], linewidth=2.5, alpha=0.92)
    ax6.add_patch(rect)

    # Verdict badge at top
    ax6.text(x + card_w / 2, y_bottom + card_h - 0.25, v['verdict'],
             ha='center', va='center', fontsize=10, fontweight='bold', color='white',
             bbox=dict(boxstyle='round,pad=0.25', facecolor=v['color'], edgecolor=v['color']))

    # Title
    ax6.text(x + card_w / 2, y_bottom + card_h - 0.85, v['title'],
             ha='center', va='center', fontsize=12, fontweight='bold', color='#1a1a1a')

    # Method
    ax6.text(x + card_w / 2, y_bottom + card_h - 1.3, v['method'],
             ha='center', va='center', fontsize=8, color='#888888')

    # Result
    ax6.text(x + card_w / 2, y_bottom + 0.75, v['result'],
             ha='center', va='center', fontsize=9, color='#555555',
             bbox=dict(boxstyle='round,pad=0.3', facecolor='#F8F9FA', edgecolor='#E0E0E0', alpha=0.8))

    ax6.text(x + card_w / 2, y_bottom + 0.15, f'{i+1}/5', ha='center', va='center',
             fontsize=7, color='#AAAAAA')

ax6.set_title('五项验证全部通过', fontsize=15, fontweight='bold', color='#1a1a1a', pad=10)

fig6.tight_layout(pad=1)
fig6.savefig('analysis_reports/会话分析_验证汇总.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig6)
print('Figure 6 saved: 会话分析_验证汇总.png')

print('Additional charts generated successfully.')

# ============================================================
# Figure 7: 结束类型归因 — horizontal bar chart
# ============================================================
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

plt.rcParams['font.family'] = ['Arial Unicode MS', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

df = pd.read_excel('data_storage/20260528_每日会话量.xlsx', sheet_name='结束类型_分列')
df['统计日期'] = pd.to_datetime(df['统计日期'])
wk = df['统计日期'].dt.isocalendar().week.astype(int)
mask_0409 = df['统计日期'] == pd.Timestamp('2026-04-09')

baseline = df[(wk >= 14) & (wk <= 16) & (~mask_0409.values)]
current = df[(wk >= 20) & (wk <= 22)]
n_days_base = baseline['统计日期'].nunique()
n_days_curr = current['统计日期'].nunique()

# Aggregate at level-1, compute daily avg and contribution
b1 = baseline.groupby('一级结束类型')['人工会话量'].sum() / n_days_base
c1 = current.groupby('一级结束类型')['人工会话量'].sum() / n_days_curr

total_inc = c1.sum() - b1.sum()

all_cats = set(b1.index) | set(c1.index)
items = []
for cat in all_cats:
    b = b1.get(cat, 0)
    c = c1.get(cat, 0)
    d = c - b
    pct = d / total_inc * 100 if total_inc > 0 else 0
    items.append((cat, b, c, d, pct))

items.sort(key=lambda x: x[3], reverse=True)

# Top 12 gainers + aggregate the rest
top_n = 12
top_items = items[:top_n]

fig7, ax7 = plt.subplots(1, 1, figsize=(14, 7))
fig7.set_facecolor('#FAFBFC')
ax7.set_facecolor('#FAFBFC')

cats_labels = [it[0] for it in reversed(top_items)]
deltas = [it[4] for it in reversed(top_items)]
abs_deltas = [it[3] for it in reversed(top_items)]
baselines_v = [it[1] for it in reversed(top_items)]
currents_v = [it[2] for it in reversed(top_items)]

y_pos = range(len(cats_labels))
colors_bar = ['#E74C3C' if d > 10 else '#E67E22' if d > 3 else '#3498DB' for d in deltas]

bars = ax7.barh(y_pos, deltas, color=colors_bar, edgecolor='white', linewidth=1.2, alpha=0.85, height=0.65)

for i, (bar, d, pct, b, c) in enumerate(zip(bars, deltas, deltas, baselines_v, currents_v)):
    ax7.text(bar.get_width() + 0.5, bar.get_y() + bar.get_height() / 2,
             '%+.0f条/天 (%+.1f%%)  |  %.0f → %.0f' % (abs_deltas[len(cats_labels)-1-i], pct, b, c),
             va='center', fontsize=9, color='#2C3E50')

ax7.set_yticks(y_pos)
ax7.set_yticklabels(cats_labels, fontsize=11)
ax7.set_xlabel('贡献占比 (%)', fontsize=12)
ax7.set_title('人工会话量增量归因：按一级结束类型拆分', fontsize=15, fontweight='bold', color='#1a1a1a', pad=12)
ax7.axvline(x=0, color='#7F8C8D', linewidth=1)
ax7.grid(True, alpha=0.15, axis='x', linestyle='--')
ax7.set_xlim(min(deltas) - 5, max(deltas) + 8)

fig7.tight_layout(pad=1)
fig7.savefig('analysis_reports/会话分析_结束类型归因.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig7)
print('Figure 7 saved: 会话分析_结束类型归因.png')
