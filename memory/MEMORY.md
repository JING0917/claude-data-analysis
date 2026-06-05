# Project Memory

## Project Overview
Claude Data Analysis Assistant - intelligent data analysis platform using Claude Code sub-agents and slash commands.

## Key Directories
- `.claude/`: Configuration files (agents, commands, hooks, settings)
- `data_storage/`: Data files (CSV, JSON, Excel, etc.)
- `visualizations/`: Generated charts and plots (may not exist yet)
- `examples/`: Example datasets and workflows
- `docs/`: Documentation

## Data Files
- `house.csv`: Housing dataset (first seen 2026-03-16)
- `20260107_外卖下单明细V2.xlsx`: Takeout order dataset (82MB, 19 features, analyzed 2026-03-16)

## User Preferences
- Reports and documentation in Chinese
- Visualization fonts need Chinese support
- Detailed analysis code and documentation should be saved in project

## Analysis History
### 2026-03-16: House Price Factors Analysis
- Dataset: house.csv (100 samples, 13 features)
- Analysis type: Predictive/factor analysis
- Key findings:
  - Strongest positive correlations: 面积(r=0.974), 卫生间数(r=0.948), 房间数(r=0.931)
  - Strongest negative correlations: 地铁距离(r=-0.825), 商场距离(r=-0.824), 学校距离(r=-0.805)
  - Categorical impacts: 豪华装修(471.4%溢价), 南向(198.6%溢价), 豪华小区(359.7%溢价)
- Generated files:
  - Analysis reports: house_price_analysis_summary.md, house_price_factors.md
  - Statistical data: house_stats.csv, house_correlations.csv
  - Visualizations: 8 PNG files in visualizations/ directory
  - Code: house_price_analysis.py, house_price_visualization.py

### 2026-03-16: Takeout Order Factors Analysis
- Dataset: 20260107_外卖下单明细V2.xlsx (82MB, 19 features, large dataset)
- Analysis type: Predictive/factor analysis (target: 下单量)
- Key findings:
  - Strongest positive correlation: 曝光用户量(r=0.996), 商品库存(r=0.568), 曝光量(r=0.306)
  - Inventory issues: 59% of products have stockout risk
  - Geographic concentration: TOP 10 cities account for 47.9% of orders
  - Best categories: Fast food (69% of total orders)
  - Best platform: JD.com (average 5.36 orders)
- Generated files:
  - Analysis reports: takeout_order_factors.md, takeout_analysis_summary.md
  - Statistical data: takeout_stats.csv
  - Recommendations: visualization_recommendations.md, modeling_recommendations.md
  - Code: analyze_takeout_data_fixed.py