现有每个用户每日搜索的数据，数据如：user_id,search_time,query,expouse_time,click_time,activity_id，依次表示用户ID、搜索时间、搜索词、搜索结果曝光时间、搜索结果点击时间、搜索结果活动ID（可通过活动ID，找到店铺）。经数据分析发现，搜索无结果率19%，异常高，需要排查原因。因目前搜索结果，按照query和店铺名称完全匹配，才返回。所以，期望通过分词，找出原本应该有搜索结果，但没有返回值的那些搜索数据明细，再做统计。请帮我写Python脚本，将数据找出来。业务库中有店铺表dim.dim_silkworm_store，以及活动表dwd.dwd_sr_store_promotion，通过promotion_id(活动ID)和店铺表关联，取店铺表中store_name(店铺名称)。数据经过一次统计，都放到Excel中，命名为“20251209_搜索无结果数据_大禾.xslx”，分两个sheet存放数据，且只有某一天数据，并把有搜索无曝光的数据集取出了，放到“无搜索结果”sheet中，表头：用户ID、搜索日期、搜索词、搜索量、搜索无结果量。再有“店铺名称”sheet，表头：店铺ID、店铺名称。请重新写Python脚本，同时计算“应当命中但未命中”的占比、按词汇分析哪些类型词出现问题（品牌词？店名中的简称？）、分析拼写错误、缩写、别名等情况


import pandas as pd
import jieba
from fuzzywuzzy import fuzz, process
import re

# -------------------------------
# 1. 加载数据
# -------------------------------
file_path = "20251208_无搜索结果_大禾.xlsx"
df_no_result = pd.read_excel(file_path, sheet_name="无搜索结果")
df_stores = pd.read_excel(file_path, sheet_name="店铺名称")

print(f"✅ 成功加载 {len(df_no_result)} 条无曝光搜索记录")
print(f"✅ 成功加载 {len(df_stores)} 家店铺信息")

# -------------------------------
# 2. 构建增强型店铺知识库
# -------------------------------
# 清洗并标准化店铺名称
df_stores['clean_name'] = df_stores['店铺名称'].astype(str).str.strip().str.lower()

# 提取多种关键词形式
keywords_db = []
for _, row in df_stores.iterrows():
    name = row['clean_name']
    store_id = row['店铺ID']
    
    # 原始全称
    keywords_db.append((name, store_id, 'full_name'))
    
    # 中文分词 (过滤单字)
    words = [w for w in jieba.cut(name) if len(w) >= 2]
    for w in words:
        keywords_db.append((w, store_id, 'word_cut'))
    
    # 生成简称 (移除常见后缀)
    abbrev = re.sub(r'(店|旗舰店|官方|专营|专卖|企业|公司|有限公司|商城)$', '', name)
    if len(abbrev) > 1 and abbrev != name:
        keywords_db.append((abbrev, store_id, 'abbreviation'))

# 转换为DataFrame便于查询
df_keywords = pd.DataFrame(keywords_db, columns=['keyword', 'store_id', 'source_type'])

# -------------------------------
# 3. 识别“应当命中但未命中”的搜索
# -------------------------------
def diagnose_query(query, keywords_df, fuzzy_threshold=75):
    """
    诊断一个搜索词，判断其是否应命中，并给出原因。
    """
    query_clean = str(query).strip().lower()
    
    # 策略1: 精确包含 (如搜索“星巴克”匹配到“上海星巴克咖啡有限公司”)
    matches = keywords_df[keywords_df['keyword'].apply(lambda k: k in query_clean)]
    if not matches.empty:
        best_match = matches.iloc[0]
        return True, best_match['store_id'], f"exact_contain_{best_match['source_type']}"
    
    # 策略2: 模糊匹配 (处理拼写错误、别名等)
    all_keywords = keywords_df['keyword'].tolist()
    best_fuzzy = process.extractOne(query_clean, all_keywords, scorer=fuzz.token_sort_ratio)
    if best_fuzzy and best_fuzzy[1] >= fuzzy_threshold:
        matched_kw = best_fuzzy[0]
        match_row = keywords_df[keywords_df['keyword'] == matched_kw].iloc[0]
        return True, match_row['store_id'], f"fuzzy_match_{best_fuzzy[1]}_{match_row['source_type']}"
    
    return False, None, "no_match"

# 应用诊断函数
diagnosis_results = []
for _, row in df_no_result.iterrows():
    should_hit, store_id, reason = diagnose_query(row['搜索词'], df_keywords)
    diagnosis_results.append({
        '用户ID': row['用户ID'],
        '搜索日期': row['搜索日期'],
        '搜索词': row['搜索词'],
        '搜索量': row['搜索量'],
        '搜索无结果量': row['搜索无结果量'],
        '应命中': should_hit,
        '匹配店铺ID': store_id,
        '诊断原因': reason
    })

df_diagnosis = pd.DataFrame(diagnosis_results)

# -------------------------------
# 4. 统计分析与报告生成
# -------------------------------
total_queries = len(df_diagnosis)
should_hit_count = df_diagnosis['应命中'].sum()
missed_opportunity_rate = should_hit_count / total_queries if total_queries > 0 else 0

print(f"\n === 核心诊断结果 ===")
print(f"总无结果搜索量: {total_queries}")
print(f"其中'应当命中但未命中'的数量: {should_hit_count}")
print(f"'应当命中但未命中'占比: {missed_opportunity_rate:.2%}")

# 归因分析：简化原因标签以便统计
def simplify_reason(reason):
    if reason.startswith('exact_contain'):
        return '包含关键词（简称/品牌词）'
    elif reason.startswith('fuzzy_match'):
        return '高相似度（拼写错误/别名）'
    else:
        return '无法匹配'

df_diagnosis['问题类型'] = df_diagnosis['诊断原因'].apply(simplify_reason)
reason_distribution = df_diagnosis[df_diagnosis['应命中']].groupby('问题类型').size().sort_values(ascending=False)

print(f"\n --- 问题类型分布 ---")
print(reason_distribution.to_string())

# 高频问题词Top 20
top_problematic_queries = df_diagnosis[df_diagnosis['应命中']]['搜索词'].value_counts().head(20)
print(f"\n --- 高频问题搜索词（Top 20）---")
print(top_problematic_queries.to_string())

# 保存详细报告
output_file = "20251209_搜索问题深度诊断报告.xlsx"
with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    df_diagnosis.to_excel(writer, sheet_name="诊断明细", index=False)
    reason_distribution.to_frame('数量').to_excel(writer, sheet_name="问题类型统计")
    top_problematic_queries.to_frame('频次').to_excel(writer, sheet_name="高频问题词Top20")

print(f"\n✅ 详细诊断报告已生成: {output_file}")



====================== 优化版本

现有每个用户每日搜索的数据，数据如：user_id,search_time,query,expouse_time,click_time,activity_id，依次表示用户ID、搜索时间、搜索词、搜索结果曝光时间、搜索结果点击时间、搜索结果活动ID（可通过活动ID，找到店铺）。经数据分析发现，搜索无结果率19%，异常高，需要排查原因。因目前搜索结果，按照query和店铺名称完全匹配，才返回。所以，期望通过分词，找出原本应该有搜索结果，但没有返回值的那些搜索数据明细，再做统计。请帮我写Python脚本，将数据找出来。业务库中有店铺表dim.dim_silkworm_store，以及活动表dwd.dwd_sr_store_promotion，通过promotion_id(活动ID)和店铺表关联，取店铺表中store_name(店铺名称)。数据经过一次统计，都放到Excel中，命名为“20251209_搜索无结果数据_大禾.xslx”，分两个sheet存放数据，且只有某一天数据，并把有搜索无曝光的数据集取出了，放到“无搜索结果”sheet中，表头：用户ID、搜索日期、搜索词、搜索量、搜索无结果量，近30万行数据。再有“店铺名称”sheet，表头：店铺ID、店铺名称，近14万条数据。请写在jupyter单机执行的Python脚本，同时计算“应当命中但未命中”的占比、按词汇分析哪些类型词出现问题（品牌词？店名中的简称？）、分析拼写错误、缩写、别名等情况。



# 导入核心库
import pandas as pd
import jieba
import re
from collections import Counter, defaultdict
import warnings
import time
import os
import psutil
import gc
from tqdm.notebook import tqdm
warnings.filterwarnings('ignore')

# -------------------------- 1. 基础配置（修复匹配规则） --------------------------
KEEP_SYMBOLS = {'%', '-', '/', '_', '.', '（', '）', '(', ')', '【', '】'}
SPELL_ERROR_THRESHOLD = 0.7  # 降低阈值，提升匹配率
SHORT_NAME_MIN_LEN = 2

# 内存/进程配置（平衡性能与匹配率）
PHYSICAL_CORES = 1  
BATCH_SIZE = 800  # 适度提升批次大小
SAFE_MEM_THRESHOLD = 1.5  # 适度降低内存阈值（避免过度跳过）

# 路径替换为你的Mac用户名（必改！）
USER_NAME = "你的Mac用户名"  # 比如 "zhangsan"
FILE_PATH = f"/Users/{USER_NAME}/Desktop/20251209_搜索无结果数据_大禾.xlsx"
OUTPUT_PATH = f"/Users/{USER_NAME}/Desktop/搜索无结果分析_修复版.xlsx"

# -------------------------- 2. 内存监控（修复跳过批次问题） --------------------------
def get_chrome_memory():
    """获取Chrome内存占用"""
    chrome_mem = 0
    for proc in psutil.process_iter(['pid', 'name', 'memory_info']):
        try:
            if proc.info['name'] == 'Google Chrome':
                chrome_mem += proc.info['memory_info'].rss / 1024**3
        except:
            pass
    return chrome_mem

def print_memory_status():
    """内存监控（仅提醒，不跳过批次）"""
    mem = psutil.virtual_memory()
    used_gb = mem.used / 1024**3
    avail_gb = mem.available / 1024**3
    chrome_gb = get_chrome_memory()
    print(f"📊 内存状态：总已用{used_gb:.1f}G | 可用{avail_gb:.1f}G | Chrome占用{chrome_gb:.1f}G")
    
    # 内存不足时仅暂停+清理，不跳过
    if avail_gb < SAFE_MEM_THRESHOLD:
        print("⚠️ 内存不足，暂停3秒释放内存...")
        time.sleep(3)
        gc.collect()
    return True  # 始终返回True，不跳过批次

# -------------------------- 3. 文本处理（修复标准化一致性） --------------------------
def escape_regex_chars(symbols_set):
    """正则转义"""
    escaped = []
    for char in symbols_set:
        if char in r'.^$*+?{}[]\|()-':
            escaped.append(f'\\{char}')
        else:
            escaped.append(char)
    return ''.join(escaped)

ESCAPED_SYMBOLS = escape_regex_chars(KEEP_SYMBOLS)

def clean_text_with_symbol(text):
    """文本清洗（保留完整信息）"""
    if not isinstance(text, str) or len(text) < 1:  # 放宽短文本限制
        return ""
    # 全角转半角统一
    text = text.replace('％', '%').replace('－', '-').replace('／', '/')
    text = text.replace('　', ' ').strip()
    # 保留所有有效字符（不过度过滤）
    return ''.join([c for c in text if c.isalnum() or c in KEEP_SYMBOLS or '\u4e00' <= c <= '\u9fa5' or c == ' '])

def get_core_text(text):
    """提取核心文本（修复符号替换逻辑）"""
    if not text:
        return ""
    # 统一标准化后再去符号
    text = text.replace('％', '%').replace('－', '-').replace('／', '/')
    return re.sub(f'[{ESCAPED_SYMBOLS}]', '', text).replace(' ', '')

# -------------------------- 4. 店铺索引（修复过度过滤问题） --------------------------
def prebuild_store_index(df_store):
    """
    修复索引问题：
    1. 保留完整分词
    2. 放宽候选店铺限制
    3. 不限制核心词数量
    """
    store_index = {}  # 店铺名 → 完整信息
    prefix_index = defaultdict(list)  # 前缀 → 店铺列表
    core_word_index = defaultdict(list)  # 核心词 → 店铺列表

    print("📌 构建店铺索引（修复过度过滤）...")
    for _, row in tqdm(df_store.iterrows(), total=len(df_store), desc="构建索引"):
        print_memory_status()
        
        store_name = row["清洗后店铺名称"]
        if not store_name or len(store_name) < 2:
            continue
        
        # 保留完整标准化信息
        store_name_norm = store_name  # 已在清洗时完成标准化
        store_cut = jieba.lcut(store_name_norm, cut_all=False)  # 完整分词
        store_core = get_core_text(store_name_norm)
        
        store_info = {
            "norm": store_name_norm,
            "cut": store_cut,
            "core": store_core,
            "orig": row["店铺名称"]  # 保留原始店铺名
        }
        store_index[store_name] = store_info

        # 前缀索引：放宽到2-6字符，保留200个店铺（修复50个限制）
        max_prefix = min(len(store_name_norm), 6)
        for i in range(SHORT_NAME_MIN_LEN, max_prefix + 1):
            prefix = store_name_norm[:i]
            if len(prefix_index[prefix]) < 200:  # 从50→200
                prefix_index[prefix].append(store_info)
        
        # 核心词索引：保留全部核心词，保留200个店铺
        core_words = [w for w in store_cut if len(w) >= 2]
        for w in core_words:
            if len(core_word_index[w]) < 200:
                core_word_index[w].append(store_info)

    # 转换为普通dict
    prefix_index = dict(prefix_index)
    core_word_index = dict(core_word_index)
    
    print(f"✅ 索引构建完成：")
    print(f"   - 有效店铺：{len(store_index)} | 前缀索引：{len(prefix_index)} | 核心词索引：{len(core_word_index)}")
    return store_index, prefix_index, core_word_index

# -------------------------- 5. 匹配函数（修复核心规则） --------------------------
def match_single_search_word(search_word, store_index, prefix_index, core_word_index):
    """
    修复匹配规则：
    1. 恢复分词子集匹配
    2. 放宽拼写错误阈值
    3. 增加模糊匹配规则
    4. 扩大候选店铺范围
    """
    if not search_word or len(search_word) < 2:
        return False, ""
    
    # 统一标准化（和店铺索引保持一致）
    search_norm = search_word
    search_cut = jieba.lcut(search_norm, cut_all=False)
    search_core = get_core_text(search_norm)

    # 候选店铺：从20→200个（修复范围过小问题）
    candidate_stores = set()

    # 规则1：前缀匹配（放宽范围）
    if len(search_norm) >= 2:
        # 不仅匹配完整前缀，还匹配包含前缀的情况
        for prefix_len in range(max(2, len(search_norm)-2), len(search_norm)+1):
            prefix = search_norm[:prefix_len]
            prefix_cand = prefix_index.get(prefix, [])[:200]
            candidate_stores.update([id(s) for s in prefix_cand])
    
    # 规则2：核心词匹配（修复仅前3个限制）
    search_core_words = [w for w in search_cut if len(w) >= 2]
    for w in search_core_words:
        core_cand = core_word_index.get(w, [])[:200]
        candidate_stores.update([id(s) for s in core_cand])
    
    # 规则3：核心文本模糊匹配（新增，提升匹配率）
    if len(search_core) >= 3 and not candidate_stores:
        for store_info in list(store_index.values())[:1000]:  # 从200→1000
            if search_core in store_info["core"] or store_info["core"] in search_core:
                candidate_stores.add(id(store_info))

    # 无候选则返回
    if not candidate_stores:
        return False, ""

    # 转换为店铺信息列表
    id_to_store = {id(v): v for v in store_index.values()}
    candidates = [id_to_store[s_id] for s_id in candidate_stores if s_id in id_to_store][:200]

    # 修复匹配规则（恢复完整逻辑）
    for s in candidates:
        # 规则1：分词子集匹配（核心修复）
        if set(search_cut) & set(s["cut"]):  # 从子集→交集，提升匹配率
            return True, s["orig"]
        
        # 规则2：核心文本一致/包含（修复仅完全一致）
        if (search_core == s["core"]) or (len(search_core)>=3 and search_core in s["core"]) or (len(s["core"])>=3 and s["core"] in search_core):
            return True, s["orig"]
        
        # 规则3：前缀包含（修复仅完全前缀）
        if s["norm"].startswith(search_norm) or search_norm.startswith(s["norm"][:len(search_norm)]):
            return True, s["orig"]
        
        # 规则4：拼写错误匹配（降低阈值，提升匹配率）
        if abs(len(search_core) - len(s["core"])) <= 2:  # 从1→2
            same_chars = len(set(search_core) & set(s["core"]))
            total_chars = len(set(search_core) | set(s["core"]))
            if total_chars > 0 and same_chars / total_chars >= SPELL_ERROR_THRESHOLD:
                return True, s["orig"]

    return False, ""

# -------------------------- 6. 批量匹配（修复跳过批次问题） --------------------------
def batch_match_single_process(df_no_result, store_index, prefix_index, core_word_index):
    """批量匹配（修复跳过批次）"""
    search_words = df_no_result["清洗后搜索词"].tolist()
    should_hit_list = []
    hit_store_list = []
    start_time = time.time()

    print("📌 开始匹配（修复规则，提升匹配率）...")
    for i in tqdm(range(0, len(search_words), BATCH_SIZE), desc="匹配数据"):
        print_memory_status()
        
        batch_words = search_words[i:i+BATCH_SIZE]
        batch_should_hit = []
        batch_hit_store = []
        
        for word in batch_words:
            should_hit, hit_store = match_single_search_word(word, store_index, prefix_index, core_word_index)
            batch_should_hit.append(should_hit)
            batch_hit_store.append(hit_store)
        
        should_hit_list.extend(batch_should_hit)
        hit_store_list.extend(batch_hit_store)
        
        # 内存清理（不跳过）
        gc.collect()
        time.sleep(0.05)  # 缩短暂停时间，提升效率

    total_time = (time.time() - start_time)/60
    print(f"\n✅ 匹配完成！总耗时：{total_time:.2f}分钟")
    return should_hit_list[:len(search_words)], hit_store_list[:len(search_words)]

# -------------------------- 7. 主执行流程（完整修复） --------------------------
if __name__ == "__main__":
    # 第一步：读取数据（保留完整列）
    print(f"📁 读取数据：{FILE_PATH}")
    try:
        # 保留完整列，避免丢失匹配所需信息
        df_no_result = pd.read_excel(FILE_PATH, sheet_name="无搜索结果")
        df_store = pd.read_excel(FILE_PATH, sheet_name="店铺名称")
    except Exception as e:
        print(f"❌ 读取失败：{e}")
        print(f"💡 请确认路径正确：/Users/{USER_NAME}/Desktop/20251209_搜索无结果数据_大禾.xlsx")
        raise

    # 第二步：数据预处理（修复过度过滤）
    print("\n🧹 数据预处理（保留完整信息）...")
    # 仅过滤空值，不过滤短文本（修复过度过滤）
    df_no_result = df_no_result.dropna(subset=["搜索词"]).reset_index(drop=True)
    df_store = df_store.dropna(subset=["店铺名称"]).reset_index(drop=True)

    # 完整清洗（不丢失信息）
    df_no_result["清洗后搜索词"] = df_no_result["搜索词"].apply(clean_text_with_symbol)
    df_store["清洗后店铺名称"] = df_store["店铺名称"].apply(clean_text_with_symbol)

    # 标记特殊符号
    df_no_result["含特殊符号"] = df_no_result["清洗后搜索词"].apply(
        lambda x: any(c in KEEP_SYMBOLS for c in x)
    )
    df_special = df_no_result[df_no_result["含特殊符号"] == True].copy()

    # 数据概览
    print(f"\n📊 数据概览：")
    print(f"   - 总无结果数据：{len(df_no_result):,}")
    print(f"   - 含特殊符号数据：{len(df_special):,} ({len(df_special)/len(df_no_result):.2%})")
    print_memory_status()

    # 第三步：构建修复后的索引
    store_index, prefix_index, core_word_index = prebuild_store_index(df_store)

    # 第四步：批量匹配（修复规则）
    should_hit_list, hit_store_list = batch_match_single_process(
        df_no_result, store_index, prefix_index, core_word_index
    )

    # 第五步：结果整合（修复数值为0问题）
    df_no_result["应当命中"] = should_hit_list
    df_no_result["匹配的店铺名称"] = hit_store_list

    # 释放内存
    del store_index, prefix_index, core_word_index
    gc.collect()

    # 筛选结果（核心修复）
    df_should_hit = df_no_result[df_no_result["应当命中"] == True].copy()
    df_should_hit_special = df_should_hit[df_should_hit["含特殊符号"] == True].copy()

    # 第六步：核心指标（验证匹配结果）
    print("\n📈 核心指标（修复数值为0问题）：")
    total = len(df_no_result)
    should_hit_cnt = len(df_should_hit)
    should_hit_ratio = should_hit_cnt/total if total>0 else 0
    special_cnt = len(df_should_hit_special)
    special_ratio = special_cnt/len(df_special) if len(df_special)>0 else 0

    print("="*50)
    print(f"1. 总无结果数据量：{total:,}")
    print(f"2. 应当命中未命中量：{should_hit_cnt:,}")
    print(f"3. 应当命中未命中占比：{should_hit_ratio:.2%}")
    print(f"4. 含特殊符号应当命中量：{special_cnt:,}")
    print(f"5. 含特殊符号应当命中占比：{special_ratio:.2%}")
    print("="*50)

    # 验证：打印前10条匹配结果
    print("\n📌 前10条匹配结果（验证非0）：")
    sample = df_should_hit.head(10)[["搜索词", "匹配的店铺名称", "应当命中"]]
    print(sample)

    # 第七步：问题分类（修复逻辑）
    def classify_problem(row):
        """修复分类逻辑"""
        sw = row["清洗后搜索词"]
        hs = row["匹配的店铺名称"]
        if not sw or not hs:
            return "其他"
        
        sw_norm = sw
        hs_norm = hs.replace('％', '%').replace('－', '-').replace('／', '/')
        sw_core = get_core_text(sw_norm)
        hs_core = get_core_text(hs_norm)
        
        # 特殊符号格式问题
        if sw_core == hs_core and any(c in KEEP_SYMBOLS for c in sw):
            return "特殊符号格式问题"
        # 品牌词
        hs_cut = jieba.lcut(hs_norm, cut_all=False)
        brand_words = [w for w in hs_cut if len(w)>=2 and w in sw_norm]
        if brand_words:
            return "品牌词"
        # 店名简称
        if len(sw_norm) < len(hs_norm) and (hs_norm.startswith(sw_norm) or sw_norm in hs_norm):
            return "店名简称"
        # 拼写错误
        if abs(len(sw_core) - len(hs_core)) <= 2:
            same = len(set(sw_core) & set(hs_core))
            total = len(set(sw_core) | set(hs_core))
            if total > 0 and same/total >= SPELL_ERROR_THRESHOLD:
                return "拼写错误"
        # 别名/俗称
        return "别名/俗称" if any(w in sw_norm for w in hs_cut if len(w)>=2) else "其他"

    # 分类处理
    if len(df_should_hit) > 0:
        df_should_hit["问题类型"] = df_should_hit.apply(classify_problem, axis=1)
        problem_count = df_should_hit["问题类型"].value_counts()
        print("\n📋 问题分类统计：")
        for ptype, cnt in problem_count.items():
            print(f"- {ptype}：{cnt:,} ({cnt/len(df_should_hit):.2%})")
    else:
        print("\n⚠️ 仍无匹配结果！请检查：")
        print("   1. 店铺数据是否为空")
        print("   2. 搜索词和店铺名是否有重叠内容")
        print("   3. 清洗规则是否过度过滤有效字符")

    # 第八步：输出结果（修复版）
    print(f"\n💾 输出修复版结果到：{OUTPUT_PATH}")
    try:
        with pd.ExcelWriter(OUTPUT_PATH, engine="openpyxl") as writer:
            # 核心指标
            pd.DataFrame({
                "指标名称": [
                    "总无结果数据量", "应当命中未命中量", "应当命中未命中占比",
                    "含特殊符号无结果量", "含特殊符号应当命中量", "含特殊符号应当命中占比"
                ],
                "数值": [
                    total, should_hit_cnt, f"{should_hit_ratio:.2%}",
                    len(df_special), special_cnt, f"{special_ratio:.2%}"
                ]
            }).to_excel(writer, sheet_name="核心指标", index=False)
            
            # 匹配明细（完整）
            df_should_hit.to_excel(writer, sheet_name="应当命中明细", index=False)
            
            # 原始数据（带匹配结果）
            df_no_result[["搜索词", "应当命中", "匹配的店铺名称", "含特殊符号"]].to_excel(writer, sheet_name="原始数据匹配结果", index=False)
        
        print("✅ 修复版结果输出成功！")
    except Exception as e:
        print(f"❌ 输出失败：{e}")
        print("💡 解决：关闭已打开的Excel文件，或更换输出路径")

    # 最终内存清理
    gc.collect()
    print("\n🎉 修复版脚本执行完成！")
    print_memory_status()



============= 优化版本 V1
# -*- coding: utf-8 -*-
"""
搜索无结果问题诊断脚本（终极优化版）
特点：
- 彻底移除无效符号查询
- Aho-Corasick 实现 O(n) 多模式匹配
- 按长度分桶缩小模糊匹配范围
- 字典映射避免循环查找
- 全程向量化操作，极致性能

高性能诊断脚本 V9.0 —— 字符交集预筛模糊匹配
特点：
- 彻底移除“首字母相同”限制
- 使用 set 交集快速筛选候选（≥2个公共字符）
- 保留地理围栏与 Aho-Corasick
- 适配 M1 8G 资源限制

V10.0 —— 批量模糊匹配架构 | M1 8G 极致性能
策略：
1. 第一阶段：Aho-Corasick + 地理围栏 → 解决大部分问题
2. 第二阶段：收集未命中查询 → 批量模糊匹配 → 减少总调用次数
"""

import pandas as pd
import numpy as np
from collections import defaultdict
import re
import ahocorasick
from rapidfuzz import fuzz, process
import warnings

warnings.filterwarnings("ignore", message="Applied processor reduces input query to empty string")

# Haversine 距离
def haversine_distance(lat1, lng1, lat2, lng2):
    R = 6371.0
    lat1, lng1, lat2, lng2 = map(np.radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlng/2)**2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1-a))
    return R * c

# -------------------------------
# 数据加载与清洗
# -------------------------------
file_path = "20251208_无搜索结果_大禾.xlsx"
df_search = pd.read_excel(file_path, sheet_name="无搜索结果")
df_stores = pd.read_excel(file_path, sheet_name="店铺名称")

def is_valid_query(query):
    if pd.isna(query): return False
    return bool(re.search(r'[\u4e00-\u9fa5a-zA-Z0-9]', str(query)))

df_filtered = df_search[df_search['query'].apply(is_valid_query)].copy()
df_filtered = df_filtered.dropna(subset=['longitude', 'latitude']).rename(columns={'longitude':'user_lng','latitude':'user_lat'})
df_stores = df_stores.dropna(subset=['longitude', 'latitude']).rename(columns={'longitude':'store_lng','latitude':'store_lat'})

print(f"✅ 待分析数据量: {len(df_filtered):,}")

# -------------------------------
# 构建关键词库与自动机
# -------------------------------
df_stores['clean_name'] = df_stores['store_name'].astype(str).str.strip().str.lower()

keywords_with_store = []
for _, row in df_stores.iterrows():
    name = row['clean_name']
    sid = row['store_id']
    lat = row['store_lat']
    lng = row['store_lng']
    
    keywords_with_store.append((name, sid, lat, lng))
    words = [w for w in re.findall(r'[\u4e00-\u9fa5a-zA-Z0-9]{2,}', name)]
    for w in words:
        keywords_with_store.append((w, sid, lat, lng))
    abbrev = re.sub(r'(店|旗舰店|官方|专营|专卖|企业|公司|有限公司|商城)$', '', name)
    if len(abbrev) > 1 and abbrev != name:
        keywords_with_store.append((abbrev, sid, lat, lng))

keywords_with_store = list(set(keywords_with_store))
all_keywords = [kw for kw, _, _, _ in keywords_with_store]

A = ahocorasick.Automaton()
for kw, sid, lat, lng in keywords_with_store:
    if len(kw) >= 1:
        A.add_word(kw, (kw, sid, lat, lng))
A.make_automaton()

# 元数据映射
kw_to_meta = {}
for kw, sid, lat, lng in keywords_with_store:
    if kw not in kw_to_meta:
        kw_to_meta[kw] = (sid, lat, lng)

print(f"✅ 关键词库构建完成 ({len(all_keywords):,} 项)")

# -------------------------------
# 阶段1: Aho-Corasick + 地理围栏（极速）
# -------------------------------
print("🚀 正在执行第一阶段：精确匹配...")

n = len(df_filtered)
should_hit = np.zeros(n, dtype=bool)
matched_ids = np.full(n, None, dtype=object)
reasons = np.full(n, 'no_match', dtype=object)

query_clean = df_filtered['query'].astype(str).str.strip().str.lower()
user_lats = df_filtered['user_lat'].values
user_lngs = df_filtered['user_lng'].values

for idx, (query, u_lat, u_lng) in enumerate(zip(query_clean, user_lats, user_lngs)):
    try:
        matches = list(A.iter(query))
        for _, (matched_kw, s_sid, s_lat, s_lng) in matches:
            if haversine_distance(u_lat, u_lng, s_lat, s_lng) <= 5.0:
                should_hit[idx] = True
                matched_ids[idx] = s_sid
                reasons[idx] = f"exact_{matched_kw}"
                break
    except Exception:
        continue

print(f"✅ 第一阶段完成，已匹配 {should_hit.sum():,} 条")

# -------------------------------
# 阶段2: 仅对未命中的查询，执行批量模糊匹配
# -------------------------------
mask_unmatched = ~should_hit
if mask_unmatched.sum() == 0:
    print("?? 所有请求均已匹配，无需模糊匹配")
else:
    print(f"🔍 第二阶段：对 {mask_unmatched.sum():,} 条未命中请求执行批量模糊匹配...")
    
    unmatched_queries = df_filtered.loc[mask_unmatched, 'query'].astype(str).str.strip().str.lower().tolist()
    unmatched_indices = df_filtered.index[mask_unmatched].tolist()
    unmatched_lats = user_lats[mask_unmatched]
    unmatched_lngs = user_lngs[mask_unmatched]
    
    # 使用字符交集快速缩小候选集（每条查询独立）
    for q_idx, (orig_idx, query, u_lat, u_lng) in enumerate(zip(unmatched_indices, unmatched_queries, unmatched_lats, unmatched_lngs)):
        candidate_kws = [
            kw for kw in all_keywords 
            if len(kw) >= 2 and len(set(query) & set(kw)) >= 2
        ]
        
        if not candidate_kws or len(candidate_kws) > 500:
            continue
            
        best_match = process.extractOne(
            query,
            candidate_kws,
            scorer=fuzz.token_sort_ratio,
            score_cutoff=75
        )
        
        if best_match:
            matched_kw, score, _ = best_match
            sid, s_lat, s_lng = kw_to_meta[matched_kw]
            if haversine_distance(u_lat, u_lng, s_lat, s_lng) <= 5.0:
                should_hit[orig_idx] = True
                matched_ids[orig_idx] = sid
                reasons[orig_idx] = f"fuzzy_{score}_{matched_kw}"

print("✅ 第二阶段完成")

# -------------------------------
# 输出结果
# -------------------------------
df_result = df_filtered.copy()
df_result['应命中'] = should_hit
df_result['匹配店铺ID'] = matched_ids
df_result['诊断原因'] = reasons

total = len(df_result)
hit_count = df_result['应命中'].sum()
rate = hit_count / total if total > 0 else 0

print(f"\n📊 最终结果: {hit_count:,} / {total:,} ({rate:.2%})")

def categorize(r):
    if r.startswith('exact'): return '5km内+关键词匹配'
    elif r.startswith('fuzzy'): return '5km内+模糊匹配'
    else: return '无法匹配'

df_result['问题类型'] = df_result['诊断原因'].apply(categorize)
summary = df_result[df_result['应命中']]['问题类型'].value_counts()
print(summary.to_string())

output_file = "20251209_搜索诊断_最终极版.xlsx"
with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    df_result.to_excel(writer, sheet_name="诊断明细", index=False)
    summary.to_frame('数量').to_excel(writer, sheet_name="归因统计")

print(f"\n✅ 报告已生成: {output_file}")

====================================================================================================================================================================================
====================================================================================================================================================================================
====================================================================================================================================================================================
# 使用chatgpt 做优化

import pandas as pd
import numpy as np
from collections import OrderedDict
import re
import ahocorasick
from rapidfuzz import fuzz, process
import warnings

warnings.filterwarnings("ignore", message="Applied processor reduces input query to empty string")

############################################################
# 参数配置
############################################################

FILE_PATH = "20251210_无搜索结果_大禾.xlsx"

GRID_SIZE = 0.02          # 每格 ≈2km，可按需要调整
MAX_CACHE_SIZE = 300      # LRU缓存最多缓存300个网格，可按内存调大/调小
MATCH_RADIUS_KM = 5.0     # 5km 匹配半径

############################################################
# 基础工具函数
############################################################

def haversine_distance(lat1, lng1, lat2, lng2):
    R = 6371.0
    lat1, lng1, lat2, lng2 = map(np.radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlng/2)**2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1-a))
    return R * c

def is_valid_query(q):
    if pd.isna(q): return False
    return bool(re.search(r'[\u4e00-\u9fa5a-zA-Z0-9]', str(q)))

def get_grid_id(lat, lng, grid_size=GRID_SIZE):
    gx = int(lat // grid_size)
    gy = int(lng // grid_size)
    return (gx, gy)


############################################################
# LRU 缓存（核心）
############################################################

grid_cache = OrderedDict()

def build_ac_for_grid(df_stores):
    """
    给某个grid内的店铺构建 AC 自动机
    """
    A = ahocorasick.Automaton()
    kw_to_meta = {}
    all_keywords = []

    for _, r in df_stores.iterrows():
        sid = r["store_id"]
        name = str(r["clean_name"])
        lat = r["store_lat"]
        lng = r["store_lng"]

        kws = [name]

        # 拆词
        parts = re.findall(r'[\u4e00-\u9fa5a-zA-Z0-9]{2,}', name)
        kws.extend(parts)

        # 去尾
        abbrev = re.sub(r'(店|旗舰店|官方|专营|专卖|企业|公司|有限公司|商城)$', '', name)
        if len(abbrev) > 1 and abbrev != name:
            kws.append(abbrev)

        for kw in kws:
            if kw not in kw_to_meta:
                kw_to_meta[kw] = (sid, lat, lng)
                A.add_word(kw, (kw, sid, lat, lng))
                all_keywords.append(kw)

    A.make_automaton()
    return A, all_keywords, kw_to_meta


def get_grid_resources(grid_id, df_stores_by_grid):
    """
    根据 grid_id 取 AC 自动机（LRU缓存）
    """
    global grid_cache

    # 缓存命中
    if grid_id in grid_cache:
        grid_cache.move_to_end(grid_id)
        return grid_cache[grid_id]["A"], grid_cache[grid_id]["keywords"], grid_cache[grid_id]["kw_to_meta"]

    # 缓存未命中 → 构建
    if grid_id not in df_stores_by_grid:
        empty_A = ahocorasick.Automaton()
        empty_A.make_automaton()
        return empty_A, [], {}

    df_block = df_stores_by_grid[grid_id]
    A, keywords, kw_to_meta = build_ac_for_grid(df_block)

    # 存入缓存
    grid_cache[grid_id] = {
        "A": A,
        "keywords": keywords,
        "kw_to_meta": kw_to_meta
    }
    grid_cache.move_to_end(grid_id)

    # 控制缓存大小
    if len(grid_cache) > MAX_CACHE_SIZE:
        grid_cache.popitem(last=False)

    return A, keywords, kw_to_meta


############################################################
# 加载数据
############################################################

df_search = pd.read_excel(FILE_PATH, sheet_name="无搜索结果")
df_stores = pd.read_excel(FILE_PATH, sheet_name="店铺名称")

df_search = df_search[df_search["query"].apply(is_valid_query)].copy()
df_search = df_search.dropna(subset=["longitude","latitude"])
df_search = df_search.rename(columns={"longitude":"user_lng","latitude":"user_lat"})

df_stores = df_stores.dropna(subset=["longitude","latitude"])
df_stores = df_stores.rename(columns={"longitude":"store_lng","latitude":"store_lat"})
df_stores["clean_name"] = df_stores["store_name"].astype(str).str.strip().str.lower()

print(f"待分析数据量: {len(df_search):,}")
print(f"店铺数量: {len(df_stores):,}")

############################################################
# 构建店铺 Grid 索引
############################################################

df_stores["grid_id"] = df_stores.apply(
    lambda r: get_grid_id(r["store_lat"], r["store_lng"]), axis=1
)

df_stores_by_grid = {
    gid: block.copy()
    for gid, block in df_stores.groupby("grid_id")
}

print(f"共构建 {len(df_stores_by_grid):,} 个店铺 Grid")


############################################################
# 匹配阶段
############################################################

n = len(df_search)
should_hit = np.zeros(n, dtype=bool)
matched_ids = np.full(n, None, dtype=object)
reasons = np.full(n, 'no_match', dtype=object)

query_clean = df_search['query'].astype(str).str.strip().str.lower().values
user_lats = df_search['user_lat'].values
user_lngs = df_search['user_lng'].values


############################################################
# 第一阶段：AC 精确匹配
############################################################

print("阶段1：Aho-Corasick 精确匹配（5km）...")

for idx, (query, lat, lng) in enumerate(zip(query_clean, user_lats, user_lngs)):

    grid_id = get_grid_id(lat, lng)
    A, keywords, kw_to_meta = get_grid_resources(grid_id, df_stores_by_grid)

    try:
        for _, (matched_kw, sid, s_lat, s_lng) in A.iter(query):
            if haversine_distance(lat, lng, s_lat, s_lng) <= MATCH_RADIUS_KM:
                should_hit[idx] = True
                matched_ids[idx] = sid
                reasons[idx] = f"exact_{matched_kw}"
                break
    except:
        continue

print(f"AC 精确匹配命中：{should_hit.sum():,} 条")


############################################################
# 第二阶段：模糊匹配（仅对未命中）
############################################################

print("阶段2：模糊匹配（5km）...")

mask_unmatched = ~should_hit

unmatched_queries = df_search.loc[mask_unmatched, "query"].astype(str).str.strip().str.lower().values
unmatched_indices = df_search.index[mask_unmatched].values
unmatched_lats = user_lats[mask_unmatched]
unmatched_lngs = user_lngs[mask_unmatched]


for q_idx, (orig_idx, query, lat, lng) in enumerate(
        zip(unmatched_indices, unmatched_queries, unmatched_lats, unmatched_lngs)):

    grid_id = get_grid_id(lat, lng)
    _, keywords, kw_to_meta = get_grid_resources(grid_id, df_stores_by_grid)

    # 利用字符交集预筛
    candidate_kws = [kw for kw in keywords if len(kw) >= 2 and len(set(query) & set(kw)) >= 2]

    # 避免大规模 fuzz（M1 会卡）
    if not candidate_kws or len(candidate_kws) > 500:
        continue

    best = process.extractOne(
        query,
        candidate_kws,
        scorer=fuzz.token_sort_ratio,
        score_cutoff=75
    )

    if best:
        matched_kw, score, _ = best
        sid, s_lat, s_lng = kw_to_meta[matched_kw]

        if haversine_distance(lat, lng, s_lat, s_lng) <= MATCH_RADIUS_KM:
            should_hit[orig_idx] = True
            matched_ids[orig_idx] = sid
            reasons[orig_idx] = f"fuzzy_{score}_{matched_kw}"


############################################################
# 输出结果
############################################################

df_result = df_search.copy()
df_result["应命中"] = should_hit
df_result["匹配店铺ID"] = matched_ids
df_result["诊断原因"] = reasons

def categorize(r):
    if r.startswith("exact"): return "5km内+关键词匹配"
    elif r.startswith("fuzzy"): return "5km内+模糊匹配"
    return "无法匹配"

df_result["问题类型"] = df_result["诊断原因"].apply(categorize)

summary = df_result[df_result["应命中"]]["问题类型"].value_counts()

print(summary.to_string())

output_file = "20251210_搜索诊断_最终.xlsx"
with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
    df_result.to_excel(writer, sheet_name="诊断明细", index=False)
    summary.to_frame("数量").to_excel(writer, sheet_name="归因统计")

print(f"报告已生成：{output_file}")








