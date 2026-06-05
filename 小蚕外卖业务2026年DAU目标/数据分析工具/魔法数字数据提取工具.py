#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小蚕魔法数字分析数据提取工具
支持从StarRocks数据库提取用户行为数据，用于魔法数字分析

使用说明:
1. 安装依赖: pip install pandas numpy pymysql
2. 根据实际数据库结构修改SQL查询中的表名和字段名
3. 运行脚本: python magic_number_data_extractor.py

注意事项:
- 大数据量时建议添加LIMIT限制
- 导出文件可能较大，确保磁盘空间充足
- 数据库密码等敏感信息请妥善保管
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import pymysql
import warnings
import sys
import os
import json
import argparse
from typing import Dict, List, Optional, Tuple, Any

warnings.filterwarnings('ignore')

# StarRocks数据库配置（请根据实际情况修改）
SR_CONFIG = {
    "host": "172.17.64.45",
    "port": 9030,
    "user": "root",
    "password": "O8dtIJ6^KD!Xf8E",
    "database": "xiaocan_db",  # 数据库名，请修改为实际的数据库名
    "charset": "utf8mb4",
    "buffered": True,
    "connection_timeout": 300,
    "autocommit": True
}

class MagicNumberDataExtractor:
    """魔法数字分析数据提取器"""

    def __init__(self, config: Dict = None):
        """初始化数据库连接配置"""
        self.config = config or SR_CONFIG
        self.connection = None
        self.cursor = None

    def connect(self) -> bool:
        """连接StarRocks数据库"""
        try:
            self.connection = pymysql.connect(**self.config)
            self.cursor = self.connection.cursor()
            print(f"✅ 成功连接到StarRocks数据库: {self.config['host']}:{self.config['port']}")
            print(f"   数据库: {self.config.get('database', '未指定')}")
            return True
        except pymysql.Error as e:
            print(f"❌ 数据库连接失败: {e}")
            print("   请检查:")
            print(f"   1. 网络连接是否正常")
            print(f"   2. 主机地址和端口是否正确: {self.config['host']}:{self.config['port']}")
            print(f"   3. 用户名和密码是否正确")
            print(f"   4. 数据库是否存在: {self.config.get('database', '未指定')}")
            return False
        except Exception as e:
            print(f"❌ 连接过程中发生未知错误: {e}")
            return False

    def disconnect(self):
        """断开数据库连接"""
        try:
            if self.cursor:
                self.cursor.close()
            if self.connection:
                self.connection.close()
            print("✅ 数据库连接已关闭")
        except Exception as e:
            print(f"⚠️  断开连接时发生错误: {e}")

    def test_connection(self) -> bool:
        """测试数据库连接和基本查询"""
        try:
            if not self.connect():
                return False

            # 测试查询
            test_query = "SELECT 1 as test_value"
            self.cursor.execute(test_query)
            result = self.cursor.fetchone()

            if result and result[0] == 1:
                print("✅ 数据库连接测试通过")
                return True
            else:
                print("❌ 数据库连接测试失败")
                return False

        except Exception as e:
            print(f"❌ 数据库连接测试失败: {e}")
            return False
        finally:
            self.disconnect()

    def get_database_info(self) -> Dict[str, Any]:
        """获取数据库基本信息"""
        try:
            if not self.connect():
                return {}

            info = {}

            # 获取数据库版本
            self.cursor.execute("SELECT VERSION()")
            info['version'] = self.cursor.fetchone()[0]

            # 获取所有表
            self.cursor.execute("""
                SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, CREATE_TIME
                FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = %s
                ORDER BY TABLE_ROWS DESC
                LIMIT 20
            """, (self.config['database'],))

            tables = []
            for row in self.cursor.fetchall():
                tables.append({
                    'table_name': row[0],
                    'table_rows': row[1],
                    'data_length_mb': round(row[2] / (1024*1024), 2) if row[2] else 0,
                    'create_time': row[3]
                })
            info['tables'] = tables

            print(f"📊 数据库信息:")
            print(f"   版本: {info.get('version', '未知')}")
            print(f"   前20个表:")
            for table in tables[:5]:  # 只显示前5个
                print(f"     - {table['table_name']}: {table['table_rows']:,} 行")
            if len(tables) > 5:
                print(f"     ... 还有 {len(tables) - 5} 个表")

            return info

        except Exception as e:
            print(f"⚠️  获取数据库信息失败: {e}")
            return {}
        finally:
            self.disconnect()

    def get_table_columns(self, table_name: str) -> List[Dict]:
        """获取表的列信息"""
        try:
            if not self.connect():
                return []

            query = """
                SELECT
                    COLUMN_NAME,
                    DATA_TYPE,
                    IS_NULLABLE,
                    COLUMN_COMMENT,
                    COLUMN_TYPE
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = %s
                AND TABLE_NAME = %s
                ORDER BY ORDINAL_POSITION
            """

            self.cursor.execute(query, (self.config['database'], table_name))
            columns = []

            for row in self.cursor.fetchall():
                columns.append({
                    'name': row[0],
                    'type': row[1],
                    'nullable': row[2],
                    'comment': row[3] or '',
                    'full_type': row[4]
                })

            print(f"📋 表 '{table_name}' 的列信息 ({len(columns)} 列):")
            for col in columns[:10]:  # 只显示前10列
                print(f"     - {col['name']}: {col['type']} ({col['comment']})")
            if len(columns) > 10:
                print(f"     ... 还有 {len(columns) - 10} 列")

            return columns

        except Exception as e:
            print(f"❌ 获取表 '{table_name}' 列信息失败: {e}")
            return []
        finally:
            self.disconnect()

    def estimate_data_volume(self, start_date: str, end_date: str,
                           sample_days: int = 7) -> Dict[str, Any]:
        """估算数据量"""
        try:
            if not self.connect():
                return {}

            # 计算样本日期范围
            sample_end = end_date
            sample_start = (datetime.strptime(sample_end, "%Y-%m-%d") -
                          timedelta(days=sample_days-1)).strftime("%Y-%m-%d")

            print(f"📈 数据量估算 (基于样本日期 {sample_start} 到 {sample_end})")

            # 估算用户行为表数据量
            behavior_query = f"""
                SELECT
                    COUNT(DISTINCT user_id) as unique_users,
                    COUNT(*) as total_records,
                    COUNT(DISTINCT DATE(event_time)) as active_days
                FROM user_behavior_log
                WHERE event_time BETWEEN '{sample_start}' AND '{sample_end}'
                AND user_id IS NOT NULL
            """

            self.cursor.execute(behavior_query)
            behavior_stats = self.cursor.fetchone()

            if behavior_stats:
                unique_users, total_records, active_days = behavior_stats

                # 估算完整时间段的数据量
                total_days = (datetime.strptime(end_date, "%Y-%m-%d") -
                            datetime.strptime(start_date, "%Y-%m-%d")).days + 1

                estimated_total_users = unique_users * (total_days / sample_days)
                estimated_total_records = total_records * (total_days / sample_days)

                stats = {
                    'sample_period': {
                        'start': sample_start,
                        'end': sample_end,
                        'days': sample_days
                    },
                    'sample_stats': {
                        'unique_users': unique_users,
                        'total_records': total_records,
                        'active_days': active_days
                    },
                    'estimated_full_period': {
                        'start': start_date,
                        'end': end_date,
                        'days': total_days,
                        'estimated_unique_users': int(estimated_total_users),
                        'estimated_total_records': int(estimated_total_records)
                    },
                    'recommendation': ''
                }

                # 根据数据量给出建议
                if estimated_total_records < 100000:
                    stats['recommendation'] = '数据量较小，可直接全量导出'
                elif estimated_total_records < 1000000:
                    stats['recommendation'] = '数据量中等，建议使用分页查询'
                else:
                    stats['recommendation'] = '数据量较大，建议抽样或分批次处理'

                print(f"    样本数据:")
                print(f"      唯一用户数: {unique_users:,}")
                print(f"      总记录数: {total_records:,}")
                print(f"      活跃天数: {active_days}")
                print(f"    完整时间段估算 ({total_days} 天):")
                print(f"      估算唯一用户数: {int(estimated_total_users):,}")
                print(f"      估算总记录数: {int(estimated_total_records):,}")
                print(f"    建议: {stats['recommendation']}")

                return stats
            else:
                print("⚠️  无法获取样本数据统计")
                return {}

        except Exception as e:
            print(f"❌ 数据量估算失败: {e}")
            print("   请检查表名 'user_behavior_log' 和字段名 'event_time', 'user_id' 是否正确")
            return {}
        finally:
            self.disconnect()

    def extract_user_behavior_sample(self, start_date: str, end_date: str,
                                   limit: int = 1000) -> pd.DataFrame:
        """提取用户行为数据样本（简化版查询，用于测试）"""
        try:
            if not self.connect():
                return pd.DataFrame()

            print(f"🔍 提取数据样本 ({start_date} 到 {end_date}, 限制 {limit} 行)")

            # 简化的查询语句（需要根据实际表结构调整）
            sample_query = f"""
                -- 用户行为数据样本查询
                -- 注意：需要根据实际表结构修改字段名和表名
                SELECT
                    u.user_id,
                    u.register_time,
                    u.user_type,
                    u.city,
                    COUNT(DISTINCT b.event_id) as event_count,
                    COUNT(DISTINCT CASE WHEN b.event_type = 'view' THEN b.event_id END) as view_count,
                    COUNT(DISTINCT CASE WHEN b.event_type = 'click' THEN b.event_id END) as click_count,
                    MIN(b.event_time) as first_event_time,
                    MAX(b.event_time) as last_event_time
                FROM user_info u
                LEFT JOIN user_behavior_log b ON u.user_id = b.user_id
                    AND b.event_time BETWEEN '{start_date}' AND '{end_date}'
                WHERE u.register_time IS NOT NULL
                GROUP BY u.user_id, u.register_time, u.user_type, u.city
                LIMIT {limit}
            """

            start_time = datetime.now()
            self.cursor.execute(sample_query)

            # 获取列名
            column_names = [desc[0] for desc in self.cursor.description]

            # 获取数据
            data = self.cursor.fetchall()

            # 转换为DataFrame
            df = pd.DataFrame(data, columns=column_names)

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            print(f"✅ 样本数据提取完成!")
            print(f"   提取行数: {len(df):,}")
            print(f"   提取列数: {len(column_names)}")
            print(f"   耗时: {duration:.2f} 秒")

            if not df.empty:
                print(f"\n📋 数据预览:")
                print(df.head().to_string())

            return df

        except Exception as e:
            print(f"❌ 样本数据提取失败: {e}")
            print("   请检查表结构和SQL语法")
            import traceback
            traceback.print_exc()
            return pd.DataFrame()
        finally:
            self.disconnect()

    def extract_full_behavior_data(self, start_date: str, end_date: str,
                                 page_size: int = 10000) -> pd.DataFrame:
        """提取完整的用户行为数据（分页查询，适用于大数据量）"""
        try:
            if not self.connect():
                return pd.DataFrame()

            print(f"🔍 开始提取完整数据 ({start_date} 到 {end_date})")
            print(f"   使用分页查询，每页 {page_size} 行")

            all_data = []
            page = 0

            while True:
                offset = page * page_size

                # 分页查询（需要根据实际表结构调整）
                page_query = f"""
                    SELECT
                        u.user_id,
                        u.register_date,
                        u.user_type,
                        u.city,
                        u.campus_company,
                        u.age_group,
                        u.gender,
                        u.device_type,

                        -- 行为指标（最近30天）
                        COALESCE(b.detail_views, 0) as detail_page_views,
                        COALESCE(b.product_clicks, 0) as product_clicks,
                        COALESCE(b.filter_uses, 0) as filter_uses,
                        COALESCE(b.search_counts, 0) as search_counts,
                        COALESCE(b.session_count, 0) as session_count,
                        COALESCE(b.avg_session_duration, 0) as avg_session_duration,

                        -- 订单指标
                        COALESCE(o.total_orders, 0) as total_orders,
                        COALESCE(o.successful_orders, 0) as successful_orders,
                        COALESCE(o.total_saved_amount, 0) as total_saved_amount,

                        -- 留存状态（示例字段，需要根据实际情况调整）
                        COALESCE(r.day2_active, 0) as day2_retained,
                        COALESCE(r.day7_active, 0) as day7_retained,
                        COALESCE(r.day30_active, 0) as day30_retained,
                        COALESCE(r.current_active, 0) as current_active

                    FROM user_info u

                    -- 用户行为聚合（需要根据实际情况创建或调整）
                    LEFT JOIN (
                        SELECT
                            user_id,
                            COUNT(DISTINCT CASE WHEN event_type = 'view_detail' THEN event_id END) as detail_views,
                            COUNT(DISTINCT CASE WHEN event_type = 'click_product' THEN event_id END) as product_clicks,
                            COUNT(DISTINCT CASE WHEN event_type = 'use_filter' THEN event_id END) as filter_uses,
                            COUNT(DISTINCT CASE WHEN event_type = 'search' THEN event_id END) as search_counts,
                            COUNT(DISTINCT session_id) as session_count,
                            AVG(session_duration) as avg_session_duration
                        FROM user_behavior_log
                        WHERE event_time BETWEEN '{start_date}' AND '{end_date}'
                        GROUP BY user_id
                    ) b ON u.user_id = b.user_id

                    -- 订单聚合（需要根据实际情况调整）
                    LEFT JOIN (
                        SELECT
                            user_id,
                            COUNT(DISTINCT order_id) as total_orders,
                            COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END) as successful_orders,
                            SUM(saved_amount) as total_saved_amount
                        FROM order_info
                        WHERE order_date BETWEEN '{start_date}' AND '{end_date}'
                        GROUP BY user_id
                    ) o ON u.user_id = o.user_id

                    -- 留存状态（需要根据实际情况调整）
                    LEFT JOIN (
                        SELECT
                            user_id,
                            MAX(CASE WHEN retention_day = 2 AND is_active = 1 THEN 1 ELSE 0 END) as day2_active,
                            MAX(CASE WHEN retention_day = 7 AND is_active = 1 THEN 1 ELSE 0 END) as day7_active,
                            MAX(CASE WHEN retention_day = 30 AND is_active = 1 THEN 1 ELSE 0 END) as day30_active,
                            MAX(CASE WHEN last_active_date >= DATE_SUB('{end_date}', INTERVAL 7 DAY) THEN 1 ELSE 0 END) as current_active
                        FROM user_retention
                        WHERE retention_date BETWEEN '{start_date}' AND '{end_date}'
                        GROUP BY user_id
                    ) r ON u.user_id = r.user_id

                    WHERE u.register_date IS NOT NULL
                    ORDER BY u.user_id
                    LIMIT {page_size} OFFSET {offset}
                """

                print(f"   正在提取第 {page + 1} 页...")
                self.cursor.execute(page_query)

                # 如果是第一页，获取列名
                if page == 0:
                    column_names = [desc[0] for desc in self.cursor.description]

                # 获取当前页数据
                page_data = self.cursor.fetchall()

                if not page_data:
                    break  # 没有更多数据

                all_data.extend(page_data)
                print(f"     已提取 {len(page_data)} 行，累计 {len(all_data):,} 行")

                # 如果返回的数据少于page_size，说明是最后一页
                if len(page_data) < page_size:
                    break

                page += 1

            if not all_data:
                print("⚠️  未提取到数据")
                return pd.DataFrame()

            # 转换为DataFrame
            df = pd.DataFrame(all_data, columns=column_names)

            print(f"✅ 完整数据提取完成!")
            print(f"   总行数: {len(df):,}")
            print(f"   总列数: {len(column_names)}")

            return df

        except Exception as e:
            print(f"❌ 完整数据提取失败: {e}")
            import traceback
            traceback.print_exc()
            return pd.DataFrame()
        finally:
            self.disconnect()

    def calculate_magic_numbers(self, df: pd.DataFrame) -> pd.DataFrame:
        """计算魔法数字相关指标"""
        if df.empty:
            print("⚠️  数据为空，无法计算魔法数字")
            return df

        print("🧮 计算魔法数字指标...")

        try:
            # 复制数据框避免修改原数据
            result_df = df.copy()

            # 魔法数字阈值定义
            MAGIC_NUMBER_THRESHOLDS = {
                'detail_page_views': 5,    # 详情页查看≥5次
                'product_clicks': 8,       # 商品点击≥8次
                'filter_uses': 3,          # 筛选使用≥3次
                'search_counts': 3         # 搜索行为≥3次
            }

            # 确保必要的列存在
            required_cols = list(MAGIC_NUMBER_THRESHOLDS.keys())
            missing_cols = [col for col in required_cols if col not in result_df.columns]

            if missing_cols:
                print(f"⚠️  缺少必要的列: {missing_cols}")
                print("   将使用默认值0")
                for col in missing_cols:
                    result_df[col] = 0

            # 计算魔法数字达成状态
            result_df['magic_number_1'] = (result_df['detail_page_views'] >= MAGIC_NUMBER_THRESHOLDS['detail_page_views']).astype(int)
            result_df['magic_number_2'] = (result_df['product_clicks'] >= MAGIC_NUMBER_THRESHOLDS['product_clicks']).astype(int)
            result_df['magic_number_3'] = (result_df['filter_uses'] >= MAGIC_NUMBER_THRESHOLDS['filter_uses']).astype(int)
            result_df['magic_number_4'] = (result_df['search_counts'] >= MAGIC_NUMBER_THRESHOLDS['search_counts']).astype(int)

            # 计算达成魔法数字个数
            magic_number_cols = ['magic_number_1', 'magic_number_2', 'magic_number_3', 'magic_number_4']
            result_df['magic_number_combo'] = result_df[magic_number_cols].sum(axis=1)

            # 计算魔法数字等级
            def assign_magic_tier(combo):
                if combo == 0:
                    return '未达成'
                elif combo == 1:
                    return '青铜'
                elif combo == 2:
                    return '白银'
                elif combo == 3:
                    return '黄金'
                else:  # combo == 4
                    return '钻石'

            result_df['magic_number_tier'] = result_df['magic_number_combo'].apply(assign_magic_tier)

            # 计算衍生指标（如果相关列存在）
            if 'successful_orders' in result_df.columns and 'total_orders' in result_df.columns:
                result_df['order_success_rate'] = result_df.apply(
                    lambda row: row['successful_orders'] / row['total_orders'] if row['total_orders'] > 0 else 0,
                    axis=1
                )

            if 'total_saved_amount' in result_df.columns and 'successful_orders' in result_df.columns:
                result_df['avg_saving_per_order'] = result_df.apply(
                    lambda row: row['total_saved_amount'] / row['successful_orders'] if row['successful_orders'] > 0 else 0,
                    axis=1
                )

            # 添加分析周期信息
            result_df['analysis_period_start'] = result_df.get('analysis_period_start', '2026-01-01')
            result_df['analysis_period_end'] = result_df.get('analysis_period_end', '2026-01-31')
            result_df['data_extraction_date'] = datetime.now().strftime("%Y-%m-%d")

            # 统计魔法数字达成情况
            print(f"✅ 魔法数字计算完成!")
            print(f"   总用户数: {len(result_df):,}")

            if magic_number_cols[0] in result_df.columns:
                print(f"   魔法数字达成情况:")
                for i, col in enumerate(magic_number_cols, 1):
                    if col in result_df.columns:
                        achieved = result_df[col].sum()
                        total = len(result_df)
                        percentage = (achieved / total * 100) if total > 0 else 0
                        print(f"     - 魔法数字{i}: {achieved:,}/{total:,} ({percentage:.1f}%)")

            if 'magic_number_tier' in result_df.columns:
                print(f"   魔法数字等级分布:")
                tier_counts = result_df['magic_number_tier'].value_counts()
                for tier, count in tier_counts.items():
                    percentage = (count / len(result_df) * 100)
                    print(f"     - {tier}: {count:,} ({percentage:.1f}%)")

            return result_df

        except Exception as e:
            print(f"❌ 魔法数字计算失败: {e}")
            import traceback
            traceback.print_exc()
            return df

    def export_to_csv(self, df: pd.DataFrame, filename: str,
                     output_dir: str = "output") -> Tuple[bool, str]:
        """导出数据到CSV文件"""
        if df.empty:
            print("⚠️  数据为空，无法导出")
            return False, ""

        try:
            # 确保输出目录存在
            os.makedirs(output_dir, exist_ok=True)

            # 完整文件路径
            if not filename.endswith('.csv'):
                filename += '.csv'
            filepath = os.path.join(output_dir, filename)

            # 导出到CSV（使用utf-8-sig编码支持中文）
            df.to_csv(filepath, index=False, encoding='utf-8-sig')

            # 获取文件大小
            file_size = os.path.getsize(filepath) / (1024 * 1024)  # MB

            print(f"💾 数据导出完成!")
            print(f"   文件路径: {filepath}")
            print(f"   文件大小: {file_size:.2f} MB")
            print(f"   数据行数: {len(df):,}")
            print(f"   数据列数: {len(df.columns)}")

            # 显示前几列信息
            print(f"\n📋 数据列信息:")
            for i, col in enumerate(df.columns[:15], 1):
                print(f"    {i:2d}. {col}")
            if len(df.columns) > 15:
                print(f"    ... 还有 {len(df.columns) - 15} 列")

            return True, filepath

        except Exception as e:
            print(f"❌ 数据导出失败: {e}")
            return False, ""

    def generate_summary_report(self, df: pd.DataFrame,
                              output_dir: str = "output") -> Dict[str, Any]:
        """生成数据摘要报告"""
        if df.empty:
            print("⚠️  数据为空，无法生成报告")
            return {}

        try:
            report = {
                'extraction_time': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                'total_users': len(df),
                'columns_count': len(df.columns),
                'basic_stats': {},
                'magic_number_stats': {},
                'retention_stats': {},
                'recommendations': []
            }

            # 基础统计
            if 'user_type' in df.columns:
                report['basic_stats']['user_type_dist'] = df['user_type'].value_counts().to_dict()

            if 'city' in df.columns:
                report['basic_stats']['top_cities'] = df['city'].value_counts().head(10).to_dict()

            if 'register_date' in df.columns:
                try:
                    df['register_date'] = pd.to_datetime(df['register_date'])
                    report['basic_stats']['registration_trend'] = {
                        'min_date': df['register_date'].min().strftime("%Y-%m-%d"),
                        'max_date': df['register_date'].max().strftime("%Y-%m-%d"),
                        'avg_days_since_registration': (datetime.now() - df['register_date']).dt.days.mean()
                    }
                except:
                    pass

            # 魔法数字统计
            magic_cols = ['magic_number_1', 'magic_number_2', 'magic_number_3', 'magic_number_4']
            if all(col in df.columns for col in magic_cols):
                report['magic_number_stats']['achievement_rates'] = {}
                for i, col in enumerate(magic_cols, 1):
                    rate = df[col].mean()
                    report['magic_number_stats']['achievement_rates'][f'magic_number_{i}'] = rate

                if 'magic_number_combo' in df.columns:
                    report['magic_number_stats']['avg_combo'] = df['magic_number_combo'].mean()
                    report['magic_number_stats']['combo_distribution'] = df['magic_number_combo'].value_counts().sort_index().to_dict()

                if 'magic_number_tier' in df.columns:
                    report['magic_number_stats']['tier_distribution'] = df['magic_number_tier'].value_counts().to_dict()

            # 留存统计
            retention_cols = ['day2_retained', 'day7_retained', 'day30_retained']
            for col in retention_cols:
                if col in df.columns:
                    report['retention_stats'][col] = df[col].mean()

            # 行为指标统计
            behavior_cols = ['detail_page_views', 'product_clicks', 'filter_uses', 'search_counts']
            for col in behavior_cols:
                if col in df.columns:
                    report['basic_stats'][f'avg_{col}'] = df[col].mean()
                    report['basic_stats'][f'max_{col}'] = df[col].max()

            # 生成建议
            if 'magic_number_combo' in df.columns:
                avg_combo = df['magic_number_combo'].mean()
                if avg_combo < 1:
                    report['recommendations'].append("魔法数字达成率较低，建议优化用户引导")
                elif avg_combo < 2:
                    report['recommendations'].append("魔法数字达成率中等，有提升空间")
                else:
                    report['recommendations'].append("魔法数字达成率良好，可考虑提升阈值")

            if 'day2_retained' in df.columns:
                day2_retention = df['day2_retained'].mean()
                if day2_retention < 0.3:
                    report['recommendations'].append("次日留存率较低，需重点关注新用户体验")
                elif day2_retention < 0.5:
                    report['recommendations'].append("次日留存率中等，可优化激活流程")

            # 保存报告到JSON文件
            report_file = os.path.join(output_dir, f"数据摘要报告_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(report, f, ensure_ascii=False, indent=2)

            print(f"📊 数据摘要报告已保存: {report_file}")

            # 打印简要报告
            print("\n" + "="*60)
            print("📈 数据摘要报告")
            print("="*60)
            print(f"总用户数: {report['total_users']:,}")
            print(f"数据列数: {report['columns_count']}")

            if 'basic_stats' in report and 'user_type_dist' in report['basic_stats']:
                print(f"\n用户类型分布:")
                for user_type, count in report['basic_stats']['user_type_dist'].items():
                    percentage = (count / report['total_users'] * 100)
                    print(f"  - {user_type}: {count:,} ({percentage:.1f}%)")

            if 'magic_number_stats' in report and 'achievement_rates' in report['magic_number_stats']:
                print(f"\n魔法数字达成率:")
                for i in range(1, 5):
                    key = f'magic_number_{i}'
                    if key in report['magic_number_stats']['achievement_rates']:
                        rate = report['magic_number_stats']['achievement_rates'][key]
                        print(f"  - 魔法数字{i}: {rate:.2%}")

            if 'retention_stats' in report:
                print(f"\n留存率:")
                for period, rate in report['retention_stats'].items():
                    print(f"  - {period}: {rate:.2%}")

            if report['recommendations']:
                print(f"\n💡 建议:")
                for i, rec in enumerate(report['recommendations'], 1):
                    print(f"  {i}. {rec}")

            return report

        except Exception as e:
            print(f"❌ 生成摘要报告失败: {e}")
            return {}

    def run_full_pipeline(self, start_date: str, end_date: str,
                         mode: str = "sample",
                         limit: int = 10000,
                         export: bool = True) -> pd.DataFrame:
        """运行完整的数据提取流程"""
        print("="*70)
        print("🚀 小蚕魔法数字分析数据提取流程")
        print("="*70)

        df = pd.DataFrame()

        try:
            # 步骤1: 测试连接
            print("\n1️⃣ 测试数据库连接...")
            if not self.test_connection():
                print("❌ 数据库连接测试失败，终止流程")
                return df

            # 步骤2: 获取数据库信息
            print("\n2️⃣ 获取数据库信息...")
            db_info = self.get_database_info()

            # 步骤3: 估算数据量
            print("\n3️⃣ 估算数据量...")
            volume_estimate = self.estimate_data_volume(start_date, end_date)

            if not volume_estimate:
                print("⚠️  数据量估算失败，继续执行...")

            # 步骤4: 提取数据
            print(f"\n4️⃣ 提取数据 (模式: {mode})...")
            if mode == "sample":
                df = self.extract_user_behavior_sample(start_date, end_date, limit)
            elif mode == "full":
                df = self.extract_full_behavior_data(start_date, end_date)
            else:
                print(f"❌ 未知模式: {mode}")
                return df

            if df.empty:
                print("❌ 数据提取失败，终止流程")
                return df

            # 步骤5: 计算魔法数字
            print("\n5️⃣ 计算魔法数字指标...")
            df = self.calculate_magic_numbers(df)

            # 步骤6: 导出数据
            if export and not df.empty:
                print("\n6️⃣ 导出数据...")
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"小蚕魔法数字数据_{start_date}_to_{end_date}_{timestamp}.csv"

                success, filepath = self.export_to_csv(df, filename)
                if success:
                    print(f"✅ 数据已导出到: {filepath}")

                    # 步骤7: 生成摘要报告
                    print("\n7️⃣ 生成数据摘要报告...")
                    self.generate_summary_report(df)

            print("\n🎉 数据提取流程完成!")
            print(f"   共处理 {len(df):,} 条用户记录")

            return df

        except KeyboardInterrupt:
            print("\n⚠️  用户中断流程")
            return df
        except Exception as e:
            print(f"\n❌ 流程执行失败: {e}")
            import traceback
            traceback.print_exc()
            return df


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description='小蚕魔法数字分析数据提取工具')

    parser.add_argument('--start-date', type=str, default='2026-02-01',
                       help='分析开始日期 (格式: YYYY-MM-DD)')
    parser.add_argument('--end-date', type=str, default='2026-02-28',
                       help='分析结束日期 (格式: YYYY-MM-DD)')
    parser.add_argument('--mode', type=str, choices=['sample', 'full'], default='sample',
                       help='提取模式: sample(样本) 或 full(完整)')
    parser.add_argument('--limit', type=int, default=10000,
                       help='样本模式下的数据行数限制')
    parser.add_argument('--no-export', action='store_true',
                       help='不导出数据文件')
    parser.add_argument('--test-connection', action='store_true',
                       help='仅测试数据库连接')
    parser.add_argument('--estimate-volume', action='store_true',
                       help='仅估算数据量')
    parser.add_argument('--get-tables', action='store_true',
                       help='获取数据库表信息')
    parser.add_argument('--table-name', type=str,
                       help='指定表名获取列信息')

    return parser.parse_args()


def main():
    """主函数"""
    args = parse_arguments()

    extractor = MagicNumberDataExtractor()

    # 根据参数执行相应操作
    if args.test_connection:
        extractor.test_connection()
        return

    if args.estimate_volume:
        extractor.estimate_data_volume(args.start_date, args.end_date)
        return

    if args.get_tables:
        extractor.get_database_info()
        return

    if args.table_name:
        extractor.get_table_columns(args.table_name)
        return

    # 运行完整流程
    df = extractor.run_full_pipeline(
        start_date=args.start_date,
        end_date=args.end_date,
        mode=args.mode,
        limit=args.limit,
        export=not args.no_export
    )

    # 如果数据提取成功且没有导出，显示数据信息
    if not df.empty and args.no_export:
        print(f"\n📋 提取的数据信息:")
        print(f"   形状: {df.shape[0]} 行 × {df.shape[1]} 列")
        print(f"   内存使用: {df.memory_usage(deep=True).sum() / (1024*1024):.2f} MB")
        print(f"\n前5行数据:")
        print(df.head().to_string())

        # 显示魔法数字达成情况
        if 'magic_number_combo' in df.columns:
            print(f"\n魔法数字达成情况:")
            print(f"   平均达成个数: {df['magic_number_combo'].mean():.2f}")
            print(f"   达成分布:")
            for i in range(5):
                count = (df['magic_number_combo'] == i).sum()
                percentage = (count / len(df) * 100)
                print(f"     - 达成{i}个: {count:,} ({percentage:.1f}%)")


if __name__ == "__main__":
    main()