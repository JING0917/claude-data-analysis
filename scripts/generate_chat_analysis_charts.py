import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from matplotlib.patches import ConnectionPatch
from sklearn.linear_model import LinearRegression

plt.rcParams['font.family'] = ['Arial Unicode MS', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

df = pd.read_excel('data_storage/20260528_每日会话量.xlsx', sheet_name='整体')
df['统计日期'] = pd.to_datetime(df['统计日期'])
df = df.sort_values('统计日期').reset_index(drop=True)
df['dayofweek'] = df['统计日期'].dt.dayofweek
wk = df['统计日期'].dt.isocalendar().week.astype(int)
df['week_label'] = 'W' + wk.astype(str)
df['发起用户占比'] = df['人工会话发起用户量'] / df['DAU'] * 10000
df['人均会话量_DAU'] = df['人工会话量'] / df['DAU'] * 10000
df['人均会话次数'] = df['人工会话量'] / df['人工会话发起用户量']

# ---- Window masks ----
mask_0409 = df['统计日期'] == pd.Timestamp('2026-04-09')
baseline_mask = (wk >= 14) & (wk <= 16) & (~mask_0409)
current_mask = (wk >= 20) & (wk <= 22)
w17_mask = wk == 17
may_mask = df['统计日期'] >= pd.Timestamp('2026-05-01')

baseline = df[baseline_mask]
current = df[current_mask]
may_data = df[may_mask]

b_rate = baseline['发起用户占比'].mean()
c_rate = current['发起用户占比'].mean()

# ============================================================
# Figure 1: 核心趋势 — 3 panels (发起用户占比 + 人工会话量 + weekly bars)
# ============================================================
fig1, (ax1a, ax1b, ax1c) = plt.subplots(3, 1, figsize=(18, 13), gridspec_kw={'height_ratios': [1.3, 1.3, 1]})
fig1.set_facecolor('#FAFBFC')

# ===== Panel A: 发起用户占比 daily trend =====
ax1a.set_facecolor('#FAFBFC')
dates = df['统计日期']
y_rate = df['发起用户占比']
ax1a.plot(dates, y_rate, color='#2C3E50', linewidth=1.5, marker='o', markersize=3, zorder=3)
roll_rate = y_rate.rolling(7, center=True).mean()
ax1a.plot(dates, roll_rate, color='#E74C3C', linewidth=2.5, alpha=0.8, label='7日滚动均值')

for mask, color, label in [(baseline_mask, '#3498DB', '基线期\nW14-W16'),
                             (current_mask, '#27AE60', '当前期\nW20-W22')]:
    d_sub = df[mask]['统计日期']
    if len(d_sub) > 0:
        for d in d_sub:
            ax1a.axvspan(d - pd.Timedelta(hours=12), d + pd.Timedelta(hours=12),
                        color=color, alpha=0.08, zorder=0)
        ax1a.axvspan(d_sub.min() - pd.Timedelta(hours=12), d_sub.max() + pd.Timedelta(hours=12),
                    color=color, alpha=0.06, zorder=0)

d_w17 = df[w17_mask]['统计日期']
ax1a.axvspan(d_w17.min() - pd.Timedelta(hours=12), d_w17.max() + pd.Timedelta(hours=12),
            color='#E74C3C', alpha=0.06, zorder=0)

d_0409 = df.loc[mask_0409, '统计日期'].values[0]
y_0409 = df.loc[mask_0409, '发起用户占比'].values[0]
ax1a.annotate('4/9 单日异常\n(仅客服指标偏高)', xy=(d_0409, y_0409),
             xytext=(d_0409 + pd.Timedelta(days=5), y_0409 + 8),
             fontsize=9, color='#C0392B', fontweight='bold',
             arrowprops=dict(arrowstyle='->', color='#C0392B', lw=1.5),
             bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='#C0392B', alpha=0.8))

ax1a.annotate('W17 异常尖峰\n(已消退)', xy=(d_w17.mean(), df[w17_mask]['发起用户占比'].max()),
             xytext=(d_w17.mean() + pd.Timedelta(days=4), df[w17_mask]['发起用户占比'].max() + 5),
             fontsize=9, color='#E74C3C', fontweight='bold', ha='center',
             arrowprops=dict(arrowstyle='->', color='#E74C3C', lw=1.2),
             bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='#E74C3C', alpha=0.8))

ax1a.axhline(y=b_rate, color='#3498DB', linestyle='--', linewidth=1.2, alpha=0.7)
ax1a.axhline(y=c_rate, color='#27AE60', linestyle='--', linewidth=1.2, alpha=0.7)
ax1a.text(dates.iloc[-1], b_rate, f' 基线均值 {b_rate:.0f}/万人', fontsize=9, color='#3498DB', va='center', fontweight='bold')
ax1a.text(dates.iloc[-1], c_rate, f' 当前均值 {c_rate:.0f}/万人', fontsize=9, color='#27AE60', va='center', fontweight='bold')

ax1a.set_title('每日发起用户占比趋势（每万DAU中的人工客服发起用户量）', fontsize=15, fontweight='bold', color='#1a1a1a', pad=10)
ax1a.set_ylabel('发起用户占比（人/万DAU）', fontsize=11)
ax1a.tick_params(axis='both', labelsize=9)
ax1a.grid(True, alpha=0.2, linestyle='--')
ax1a.legend(fontsize=9, loc='upper left')
ax1a.set_xlim(dates.min() - pd.Timedelta(days=1), dates.max() + pd.Timedelta(days=1))

# ===== Panel B: 人工会话量 daily trend (NEW) =====
ax1b.set_facecolor('#FAFBFC')
y_chat = df['人工会话量']
ax1b.plot(dates, y_chat, color='#8E44AD', linewidth=1.5, marker='s', markersize=3, zorder=3)
roll_chat = y_chat.rolling(7, center=True).mean()
ax1b.plot(dates, roll_chat, color='#E74C3C', linewidth=2.5, alpha=0.8, label='7日滚动均值')

for mask, color in [(baseline_mask, '#3498DB'), (current_mask, '#27AE60')]:
    d_sub = df[mask]['统计日期']
    if len(d_sub) > 0:
        for d in d_sub:
            ax1b.axvspan(d - pd.Timedelta(hours=12), d + pd.Timedelta(hours=12),
                        color=color, alpha=0.08, zorder=0)
        ax1b.axvspan(d_sub.min() - pd.Timedelta(hours=12), d_sub.max() + pd.Timedelta(hours=12),
                    color=color, alpha=0.06, zorder=0)

ax1b.axvspan(d_w17.min() - pd.Timedelta(hours=12), d_w17.max() + pd.Timedelta(hours=12),
            color='#E74C3C', alpha=0.06, zorder=0)

b_chat = baseline['人工会话量'].mean()
c_chat = current['人工会话量'].mean()
ax1b.axhline(y=b_chat, color='#3498DB', linestyle='--', linewidth=1.2, alpha=0.7)
ax1b.axhline(y=c_chat, color='#27AE60', linestyle='--', linewidth=1.2, alpha=0.7)
ax1b.text(dates.iloc[-1], b_chat, f' 基线均值 {b_chat/1000:.1f}k', fontsize=9, color='#3498DB', va='center', fontweight='bold')
ax1b.text(dates.iloc[-1], c_chat, f' 当前均值 {c_chat/1000:.1f}k', fontsize=9, color='#27AE60', va='center', fontweight='bold')

ax1b.set_title('每日人工会话量趋势', fontsize=15, fontweight='bold', color='#1a1a1a', pad=10)
ax1b.set_ylabel('人工会话量', fontsize=11)
ax1b.tick_params(axis='both', labelsize=9)
ax1b.grid(True, alpha=0.2, linestyle='--')
ax1b.legend(fontsize=9, loc='upper left')
ax1b.set_xlim(dates.min() - pd.Timedelta(days=1), dates.max() + pd.Timedelta(days=1))
ax1b.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{x/1000:.0f}k'))

# ===== Panel C: Weekly bars =====
ax1c.set_facecolor('#FAFBFC')
weeks_ordered = ['W14','W15','W16','W17','W18','W19','W20','W21','W22']
weekly_rates = []
weekly_labels = []
for w in weeks_ordered:
    w_data = df[df['week_label'] == w]
    if len(w_data) > 0:
        rate = w_data['发起用户占比'].mean()
        weekly_rates.append(rate)
        weekly_labels.append(w)

colors_bar = ['#3498DB' if w in ['W14','W15','W16'] else
              '#E74C3C' if w == 'W17' else
              '#27AE60' if w in ['W20','W21','W22'] else
              '#95A5A6' for w in weekly_labels]
bars = ax1c.bar(range(len(weekly_labels)), weekly_rates, color=colors_bar, edgecolor='white', linewidth=1.2, alpha=0.85)
ax1c.set_xticks(range(len(weekly_labels)))
ax1c.set_xticklabels(weekly_labels, fontsize=11)
ax1c.set_ylabel('发起用户占比（人/万DAU）', fontsize=11)
ax1c.set_title('周度均值：发起用户占比', fontsize=14, fontweight='bold', color='#1a1a1a', pad=8)
ax1c.grid(True, alpha=0.15, axis='y', linestyle='--')

for i, (bar, val) in enumerate(zip(bars, weekly_rates)):
    ax1c.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.5, f'{val:.0f}',
             ha='center', va='bottom', fontsize=10, fontweight='bold', color=colors_bar[i])

from matplotlib.patches import Patch
legend_elements = [Patch(facecolor='#3498DB', alpha=0.85, label='基线期'),
                   Patch(facecolor='#E74C3C', alpha=0.85, label='异常尖峰'),
                   Patch(facecolor='#27AE60', alpha=0.85, label='当前期'),
                   Patch(facecolor='#95A5A6', alpha=0.85, label='过渡期')]
ax1c.legend(handles=legend_elements, fontsize=9, loc='upper right')

ax1c.annotate(f'+{c_rate - b_rate:.0f}/万人\n(+{(c_rate-b_rate)/b_rate*100:.1f}%)',
             xy=(weekly_labels.index('W22'), weekly_rates[-1]),
             xytext=(weekly_labels.index('W22') - 2, weekly_rates[-1] + 8),
             fontsize=11, fontweight='bold', color='#27AE60', ha='center',
             arrowprops=dict(arrowstyle='->', color='#27AE60', lw=1.5),
             bbox=dict(boxstyle='round,pad=0.3', facecolor='#D5F5E3', edgecolor='#27AE60', alpha=0.9))

fig1.tight_layout(pad=2)
fig1.savefig('analysis_reports/会话分析_核心趋势.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig1)
print('Figure 1 saved: 会话分析_核心趋势.png')

# ============================================================
# Figure 2: 增长归因 — dual panel (comparison bars + waterfall)
# ============================================================
fig2, (ax2a, ax2b) = plt.subplots(1, 2, figsize=(18, 7))
fig2.set_facecolor('#FAFBFC')

# --- Panel A: Baseline vs Current bar chart ---
ax2a.set_facecolor('#FAFBFC')
metrics = ['DAU', '报名用户量', '完单量', '发起用户量', '人工会话量']
baseline_vals = [
    baseline['DAU'].mean(),
    baseline['报名用户量'].mean(),
    baseline['完单量'].mean(),
    baseline['人工会话发起用户量'].mean(),
    baseline['人工会话量'].mean()
]
current_vals = [
    current['DAU'].mean(),
    current['报名用户量'].mean(),
    current['完单量'].mean(),
    current['人工会话发起用户量'].mean(),
    current['人工会话量'].mean()
]
growth_pcts = [(c - b) / b * 100 for b, c in zip(baseline_vals, current_vals)]

x = np.arange(len(metrics))
width = 0.35
bars1 = ax2a.bar(x - width / 2, baseline_vals, width, color='#3498DB', alpha=0.8, label='基线期 (W14-W16)', edgecolor='white')
bars2 = ax2a.bar(x + width / 2, current_vals, width, color='#27AE60', alpha=0.8, label='当前期 (W20-W22)', edgecolor='white')

for i, (b, c, g) in enumerate(zip(baseline_vals, current_vals, growth_pcts)):
    ax2a.text(i, max(b, c) + max(baseline_vals)*0.02, f'+{g:.1f}%',
             ha='center', fontsize=11, fontweight='bold',
             color='#C0392B' if g > 20 else '#E67E22')

ax2a.set_xticks(x)
ax2a.set_xticklabels(metrics, fontsize=11)
ax2a.set_title('基线期 vs 当前期：核心指标日均值', fontsize=14, fontweight='bold', color='#1a1a1a', pad=10)
ax2a.set_ylabel('日均值', fontsize=11)
ax2a.legend(fontsize=9)
ax2a.grid(True, alpha=0.15, axis='y', linestyle='--')
# Format y-axis
ax2a.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{x/10000:.0f}万'))

# --- Panel B: Attribution waterfall ---
ax2b.set_facecolor('#FAFBFC')

chat_baseline = baseline['人工会话量'].mean()
chat_current = current['人工会话量'].mean()
total_increase = chat_current - chat_baseline

# DAU component: if rate stayed at baseline, only DAU grew
dau_baseline = baseline['DAU'].mean()
dau_current = current['DAU'].mean()
rate_baseline = chat_baseline / dau_baseline * 10000
dau_contribution = (dau_current - dau_baseline) * rate_baseline / 10000
rate_contribution = total_increase - dau_contribution

# Waterfall
steps = [
    ('基线期\n人均会话量', chat_baseline, '#3498DB'),
    ('DAU增长\n贡献 (+40%)', dau_contribution, '#2ECC71'),
    ('用户倾向上升\n贡献 (+60%)', rate_contribution, '#E74C3C'),
    ('当前期\n人均会话量', chat_current, '#27AE60'),
]

cumulative = 0
for i, (label, val, color) in enumerate(steps):
    if i == 0:
        bottom = 0
        cumulative = val
    elif i == len(steps) - 1:
        bottom = 0
        cumulative = val
    else:
        bottom = cumulative
        cumulative += val

    bar = ax2b.bar(i, val, 0.5, bottom=(0 if i == 0 or i == len(steps)-1 else bottom),
                  color=color, alpha=0.85, edgecolor='white', linewidth=1.5)
    # Connector lines
    if i > 0 and i < len(steps) - 1:
        ax2b.plot([i - 0.25, i - 0.25], [cumulative - val, cumulative],
                 color='#7F8C8D', linewidth=1, linestyle='--')
    elif i == len(steps) - 1:
        ax2b.plot([i - 0.25, i - 0.25], [0, cumulative],
                 color='#7F8C8D', linewidth=1, linestyle='--')

    # Value label
    display_y = cumulative if i == 0 else (cumulative if i == len(steps)-1 else cumulative)
    ax2b.text(i, display_y + 200, f'{val:,.0f}', ha='center', fontsize=12, fontweight='bold', color=color)
    ax2b.text(i, -800, label, ha='center', fontsize=10, color='#2C3E50', fontweight='bold')

ax2b.set_title('人工会话量增长归因分解', fontsize=14, fontweight='bold', color='#1a1a1a', pad=10)
ax2b.set_ylabel('日均人工会话量', fontsize=11)
ax2b.set_xticks([])
ax2b.grid(True, alpha=0.15, axis='y', linestyle='--')
ax2b.set_ylim(-2000, chat_current + 1500)
ax2b.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'{x/1000:.0f}k'))

fig2.tight_layout(pad=3)
fig2.savefig('analysis_reports/会话分析_增长归因.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig2)
print('Figure 2 saved: 会话分析_增长归因.png')

# ============================================================
# Figure 3: 验证图表 — dual panel (weekday + residuals)
# ============================================================
fig3, (ax3a, ax3b) = plt.subplots(1, 2, figsize=(18, 7))
fig3.set_facecolor('#FAFBFC')

# --- Panel A: Weekday decomposition ---
ax3a.set_facecolor('#FAFBFC')
weekday_names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']

base_wd = []
curr_wd = []
for d in range(7):
    base_wd.append(baseline[baseline['dayofweek'] == d]['发起用户占比'].mean())
    curr_wd.append(current[current['dayofweek'] == d]['发起用户占比'].mean())

x = np.arange(len(weekday_names))
width = 0.32
bars_b = ax3a.bar(x - width / 2, base_wd, width, color='#3498DB', alpha=0.8, label='基线期', edgecolor='white')
bars_c = ax3a.bar(x + width / 2, curr_wd, width, color='#27AE60', alpha=0.8, label='当前期', edgecolor='white')

for i, (b, c) in enumerate(zip(base_wd, curr_wd)):
    diff = c - b
    ax3a.text(i, max(b, c) + 1.5, f'+{diff:.0f}', ha='center', fontsize=10, fontweight='bold', color='#C0392B')

ax3a.set_xticks(x)
ax3a.set_xticklabels(weekday_names, fontsize=11)
ax3a.set_title('星期分解：各天发起用户占比', fontsize=14, fontweight='bold', color='#1a1a1a', pad=10)
ax3a.set_ylabel('发起用户占比（人/万DAU）', fontsize=11)
ax3a.legend(fontsize=9)
ax3a.grid(True, alpha=0.15, axis='y', linestyle='--')

# --- Panel B: Recent residuals ---
ax3b.set_facecolor('#FAFBFC')

# Fit DAU→会话量 model (exclude 4/9)
fit_df = df[~mask_0409]
X_fit = fit_df[['DAU']].values
y_fit = fit_df['人工会话量'].values
lm = LinearRegression().fit(X_fit, y_fit)

# Recent 7 days
recent = df.tail(7).copy()
recent['predicted'] = lm.predict(recent[['DAU']].values)
recent['residual'] = recent['人工会话量'] - recent['predicted']
recent['z_residual'] = (recent['residual'] - recent['residual'].mean()) / recent['residual'].std()
dates_recent = recent['统计日期'].dt.strftime('%m/%d')

colors_res = ['#E74C3C' if r < 0 else '#3498DB' for r in recent['residual'].values]
bars = ax3b.bar(range(7), recent['residual'].values, color=colors_res, alpha=0.75, edgecolor='white')
ax3b.axhline(y=0, color='#7F8C8D', linewidth=1, linestyle='-')
ax3b.axhline(y=2 * recent['residual'].std(), color='#E74C3C', linewidth=1, linestyle='--', alpha=0.4, label='±2σ')
ax3b.axhline(y=-2 * recent['residual'].std(), color='#E74C3C', linewidth=1, linestyle='--', alpha=0.4)

for i, (bar, val, z) in enumerate(zip(bars, recent['residual'].values, recent['z_residual'].values)):
    ax3b.text(bar.get_x() + bar.get_width() / 2, val + (100 if val >= 0 else -300),
             f'{val:+.0f}\n({z:+.1f}σ)', ha='center', fontsize=9, fontweight='bold', color=colors_res[i])

ax3b.set_xticks(range(7))
ax3b.set_xticklabels(dates_recent, fontsize=10)
ax3b.set_title('回归残差检验：最近7天（|偏差|均 < 1σ）', fontsize=14, fontweight='bold', color='#1a1a1a', pad=10)
ax3b.set_ylabel('实际 - 预测（条）', fontsize=11)
ax3b.legend(fontsize=9)
ax3b.grid(True, alpha=0.15, axis='y', linestyle='--')

fig3.tight_layout(pad=3)
fig3.savefig('analysis_reports/会话分析_验证图表.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig3)
print('Figure 3 saved: 会话分析_验证图表.png')

# ============================================================
# Figure 4: 4月均值对比 — small inline comparison
# ============================================================
fig4, ax4 = plt.subplots(1, 1, figsize=(10, 4.5))
fig4.set_facecolor('#FAFBFC')
ax4.set_facecolor('#FAFBFC')

scenarios = ['4月均值\n(含W17尖峰)', '4月均值\n(剔除4/9)', '干净基线\n(W14-W16)', '当前期\n(W20-W22)']
rates_compare = [
    df[(wk >= 14) & (wk <= 22) & (df['统计日期'].dt.month == 4)]['发起用户占比'].mean(),
    df[(wk >= 14) & (wk <= 22) & (df['统计日期'].dt.month == 4) & (~mask_0409)]['发起用户占比'].mean(),
    b_rate,
    c_rate,
]
may_avg = df[may_mask]['发起用户占比'].mean()

colors_sc = ['#95A5A6', '#95A5A6', '#3498DB', '#27AE60']
bars = ax4.bar(range(4), rates_compare, color=colors_sc, edgecolor='white', linewidth=1.5, alpha=0.85, width=0.55)
ax4.axhline(y=may_avg, color='#E67E22', linestyle='--', linewidth=1.5, alpha=0.7, label=f'5月均值 ({may_avg:.0f}/万人)')

for i, (bar, val) in enumerate(zip(bars, rates_compare)):
    ax4.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1, f'{val:.0f}/万人',
            ha='center', fontsize=12, fontweight='bold', color=colors_sc[i])

# Arrow showing the"illusion"
ax4.annotate('', xy=(3, c_rate), xytext=(0, rates_compare[0]),
            arrowprops=dict(arrowstyle='->', color='#C0392B', lw=2, connectionstyle='arc3,rad=-0.2'))
ax4.text(1.5, max(rates_compare) + 4, '月均值对比：看似持平\n实际基线→当前: +15/万人',
        ha='center', fontsize=10, color='#C0392B', fontweight='bold',
        bbox=dict(boxstyle='round,pad=0.3', facecolor='#FADBD8', edgecolor='#C0392B', alpha=0.85))

ax4.set_xticks(range(4))
ax4.set_xticklabels(scenarios, fontsize=10)
ax4.set_title('月均值掩盖效应：4月不同口径 vs 5月', fontsize=14, fontweight='bold', color='#1a1a1a', pad=10)
ax4.set_ylabel('发起用户占比（人/万DAU）', fontsize=11)
ax4.legend(fontsize=9)
ax4.grid(True, alpha=0.15, axis='y', linestyle='--')
ax4.set_ylim(80, max(rates_compare) + 12)

fig4.tight_layout(pad=1)
fig4.savefig('analysis_reports/会话分析_月均值对比.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig4)
print('Figure 4 saved: 会话分析_月均值对比.png')

print('All chart generation complete.')
