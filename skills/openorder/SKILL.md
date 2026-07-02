---
name: openorder
description: AlphaLoop 的记忆层——把每一次投研对话固化成本地 markdown wiki，跨会话复利你的研究结论。任何一次触发 ticker（美股/港股/A股/台股/日韩/加密）、公司名、行业主题（半导体/AI infra/光模块/HBM/储能/生物医药等）、投资框架（护城河/卡脖子/估值/组合/产业链）、财报或指引、显式操作（"ingest""lint wiki""归档""记入研究"）时，都应把它当作触发点。触发后**第一动作 MUST 是 Read INDEX.md**，然后按需 Read 相关子档、用 wiki 内容作答、并把新洞见回写。跨会话、跨项目、可读可写。灵感来自 Andrej Karpathy 的 LLM Wiki 模式。
metadata:
  storageRoot: "${OPENORDER_HOME:-$HOME/openorder}"
  parent: "alphaloop"
  inspiredBy: "https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f"
  domain: "investment-research"
  customizable: true
---

# OpenOrder（AlphaLoop 记忆层 · 投研 wiki）

> **一句话**：把每次对话的结论、验真结果、决策落成本地 markdown，让研究成果跨会话复利。
>
> 本 skill 是 AlphaLoop 编排器（[`../../SKILL.md`](../../SKILL.md)）的**记忆层**。三条铁律里的第三条——「结论必须回写 openorder」——就是它的入口。姊妹 skill：验真走 [`claim-verification`](../claim-verification/SKILL.md)；行情走 [`stock-data-fetch`](../stock-data-fetch/SKILL.md)；领域框架范例见 [`strategic-materials`](../strategic-materials/SKILL.md)；建仓归因走 [`trade-journal`](../trade-journal/SKILL.md)；工具失败纪律见 [`agent-tool-escalation`](../agent-tool-escalation/SKILL.md)。

## 1. 核心使命

按照 [Karpathy LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)：

- Agent 是**维护者**，人是**方向出题人 + 源头把关人**
- 知识**编译一次、持续保鲜**，不在每次对话里重新推导
- Wiki 是**持续复利的资产**，每次对话都让它变聪明

任何触及 ticker / 行业 / 财报 / 框架的对话都 MUST 走一遍：

```
READ → REASON → WRITE → LOG → （定期）LINT
 ↓        ↓        ↓       ↓            ↓
先查     结合     写回     追加        体检：
既有     实时+    新洞见   时间线      矛盾/空洞/
知识     历史              （append）  过时
```

---

## 2. 三层架构

```
${OPENORDER_HOME}/
│
├── raw/                        ← 第 1 层：一手源（immutable，只读）
│   ├── earnings/                  财报电话会 / 8-K
│   ├── articles/                  文章 / 推文 / 博客
│   ├── filings/                   SEC 10-K/10-Q PDF
│   ├── research-notes/            对话过程中的原始笔记
│   └── README.md
│
├── [Wiki 层]                    ← 第 2 层：Wiki（LLM 主要维护对象）
│   ├── INDEX.md                   📌 内容索引（永远先读它）
│   ├── log.md                     📌 时间线日志（append-only）
│   ├── README.md
│   ├── companies/{TICKER}.md      公司档案
│   ├── industries/{NAME}/         行业深度
│   ├── frameworks/{NAME}.md       投资框架
│   ├── earnings/{TICKER}-{Q}.md   财报深挖
│   ├── portfolios/{NAME}.md       组合 / 建仓记录
│   └── templates/                 新增页面用的模板
│
└── [Schema 层]                  ← 第 3 层：规则（就是本文件）
    ~/.claude/skills/openorder/SKILL.md（或其他 agent 对应位置）
```

**分层铁律**：
- **Raw 不可变**：只允许追加 metadata 头，禁止改内容
- **Raw 必须转化成 wiki**：每个 raw 文件必须至少触发一次 wiki 更新，否则是死数据
- **Wiki 引用 Raw**：用相对路径 `[source](../raw/earnings/{TICKER}-{Q}.txt)`
- **Schema 统管一切**：所有规则都在本文件

---

## 3. 强制触发场景

### 🟢 MUST 触发（不用用户提醒）

出现下列任一时，**第一动作 MUST 是 `Read ${OPENORDER_HOME}/INDEX.md`**：

#### 3.1 Ticker / 公司名
- 任何股票代码：美股（4 字母）、港股（4-5 位数字）、A 股（6 位 + .SZ/.SH）、台股（.TW/.TWO）、日股（.JP）、韩股等
- 任何公司名（中英文都算）
- 加密：任何 token（BTC/ETH/SOL/…）或协议名

#### 3.2 行业 / 主题关键词
以下为默认覆盖（AI/硬科技/能源），换域时替换：
- **半导体**：foundry、fab、EUV、光刻、先进封装、CoWoS、chiplet
- **AI 基建**：hyperscaler capex、data center、scale-out/up、NVLink、InfiniBand
- **光通信**：CPO、CW laser、EML、DFB、VCSEL、InP、SiPh、光模块
- **存储**：HBM、HBM3E、HBM4、DDR5
- **能源 / 储能**：SOFC、燃料电池、BESS、钠电、长时储能
- **加密**：L1/L2、DeFi、perp DEX、稳定币、restaking
- *（自定义领域请扩展，见 [`docs/customize.md`](docs/customize.md)）*

#### 3.3 框架 / 方法论关键词
- 卡脖子、瓶颈、护城河、产业链、价值链
- super-cycle、供给受限、结构性短缺
- 目标价、估值、P/E、EV/EBITDA、DCF
- thesis、conviction、base/bull/bear case、多头 / 空头

#### 3.4 财报 / 财务关键词
- 财报、指引、beat/miss、transcript、8-K、10-Q、10-K、FY/CY 季度
- 任何具体指标（营收、毛利、EPS、capex、backlog、库存）挂在公司名上

#### 3.5 交易 / 组合关键词
- "买/卖/加/减/建仓/减仓/对冲/做空"
- "仓位、权重、组合、basket"

#### 3.6 显式操作
- **Ingest**："读一下这篇""ingest""归档""存这条源"
- **Lint**："lint wiki""体检""找矛盾""自审"
- **Query**：任何常规提问（默认模式）

### 🟡 建议触发
- "产业链""上下游""picks and shovels"
- "AI 受益""二阶导"
- 任何"X vs Y"对比

---

## 4. Operation 1 · READ（每次必做）

```
触发 → Read INDEX.md（强制，~5s）
    ↓
按相关度进一步 Read：
    ├── 公司类问题 → companies/{TICKER}.md
    ├── 行业类问题 → industries/{NAME}/README.md
    ├── 框架类问题 → frameworks/{NAME}.md
    ├── 历史财报   → earnings/{TICKER}-{Q}.md
    ├── 组合       → portfolios/{NAME}.md
    └── 时间线     → log.md（倒序）
    ↓
作答时：
    1. 标注信息时间戳（"基于 YYYY-MM-DD 的数据"）
    2. 引用具体文件（"见 companies/{TICKER}.md"）
    3. 数据过期 → 走 stock-data-fetch / WebSearch 现取
```

---

## 5. Operation 2 · INGEST（用户丢来新源）

**触发**：用户贴 URL、发推文/文章、说"读一下""ingest""归档"。

**标准 5 步**：

```
Step 1. 抓全文
   ├── URL：WebFetch / 浏览器 MCP
   ├── 推文：浏览器 MCP
   ├── 财报：从 filing 或 SEC 直链
   └── 写到 raw/<subdir>/（immutable，只加 metadata 头）

Step 2. 抽取实体 + 关键发现
   ├── 涉及哪些公司？（wiki 里有 / 新增）
   ├── 涉及哪些行业 / 概念？
   ├── 关键数字、金句、矛盾点
   └── 与用户确认要重点强调什么

Step 3. 更新 Wiki（可能牵动 10-15 个文件）
   ├── 新公司 → 用 templates/company-template.md 建档
   ├── 老公司 → 更新"分析日志"、修订 bull/bear、调分
   ├── 行业页 → 追加"事件跟踪"条目
   ├── 框架   → 若被验证 / 被挑战，更新对应 framework 文件
   └── 每个文件：顶部 "Last updated" + 底部 changelog

Step 4. 追加 log.md（强制）
   ## [YYYY-MM-DD HH:MM] ingest | {title}
   - Source: raw/.../{file}
   - Key findings: ...
   - Files touched: companies/X.md, industries/Y.md, ...

Step 5. 更新 INDEX.md
   ├── 顶部 "Last updated"
   ├── "Wiki 导航"表（若新增文件）
   └── 底部 "更新历史"
```

**Ingest 后**必须告诉用户：
- 改了哪些文件（方便他在 Obsidian 里 review）
- 有没有需要他决策的新发现

---

## 6. Operation 3 · WRITE（对话产生新洞见）

### 6.1 什么时候必写

| 触发事件 | 必须写什么 |
|---|---|
| 用户提到**未建档公司** | 立即用 template 建 `companies/{TICKER}.md` |
| **新财报**发布 / 被讨论 | 建 `earnings/{TICKER}-{Q}.md` + 更新公司档 |
| 对话产生**新洞见 / 新分析** | 追加到相关文件的"分析日志" + log.md + INDEX.md |
| 用户**做了交易**（buy/sell） | 建 / 更新 `portfolios/{NAME}.md` + log.md（配合 [`trade-journal`](../trade-journal/SKILL.md)） |
| **行业变动**（并购、合作、新品） | 更新 `industries/{NAME}/README.md` 的"事件跟踪" |
| **框架被验证 / 被修订** | 更新对应 `frameworks/` 文件 + log.md |

### 6.2 写作规则

#### 必备 metadata
- 文件顶部：`> **Last updated**: YYYY-MM-DD`
- 文件底部：changelog（新在最前）
- INDEX.md：更新历史 + todos
- log.md：追加一条

#### 写作风格
- **具体数据**：不是"营收增长强劲"，而是"营收 $1.81B（+27% YoY）"
- **标注来源**：不是"分析师觉得"，而是"GS 2026/3 报告"或"CEO 在 Q3 FY26 电话会说"，附 raw 路径
- **标记假设**：模型预测必须写"假设 X 条件成立"
- **多空平衡**：任何公司档 MUST 有多头 + 空头两块

#### 命名规范
- 公司：`companies/{TICKER}.md`（例：`AAPL.md`、`0700-HK.md`、`688012-SH.md`）
- 财报：`earnings/{TICKER}-{QUARTER}.md`（例：`AAPL-Q1-FY26.md`）
- 行业：`industries/{NAME}/README.md`
- 框架：`frameworks/{NAME}.md`（kebab-case）
- 组合：`portfolios/{NAME}-{DATE}.md`
- Raw：见 `raw/README.md`

### 6.3 模板
见 `examples/company-template.md`、`examples/earnings-template.md`。安装时会拷贝到 `${OPENORDER_HOME}/templates/`。

---

## 7. Operation 4 · LOG（每次写必附）

**位置**：`${OPENORDER_HOME}/log.md`

**格式**（沿用 Karpathy 约定——统一前缀便于 grep）：

```markdown
## [YYYY-MM-DD HH:MM] {action} | {一句话摘要}
- Trigger: {用户 prompt 或事件}
- Files touched: {file1}, {file2}, ...
- Key findings/decisions: {1-3 行}
- Raw source: {若有，附路径}
```

`action` 取值：
- `ingest` — 新源被吸收
- `query` — 用户 Q&A（只在产生新洞见时记）
- `lint` — 体检
- `decision` — 实际交易决策
- `revise` — 修正旧 thesis
- `framework` — 框架更新

**追加方式**：在 `# Wiki Activity Log` 标题下方 StrReplace 插入（新的在最上）。

**好处**：`grep "^## \[" log.md | tail -10` 秒查最近动作。

---

## 8. Operation 5 · LINT（定期或显式）

**触发**：用户说"lint wiki""体检""找矛盾"，或每月主动提议。

**5 项检查**：

### 8.1 矛盾
- 同一公司在 `companies/X.md` 和 `portfolios/Y.md` 的目标价 / 评级冲突？
- 行业 ranking 在 `industries/.../README.md` 与 `frameworks/.../*.md` 分数冲突？
- 同一指标在多份 `earnings/` 文件里对不上？

### 8.2 过时
- 公司档 `Last updated` 早于最新财报 → 标待更新
- 财报文件 >90 天但催化剂已过 → 需不需要新一份？

### 8.3 孤儿
- `companies/` 里的文件没被任何 portfolio / framework / industry 引用？
- Raw 源没对应 wiki 更新？

### 8.4 缺页
- 某公司 / 概念被**多次提及**但没档（如"Anritsu 出现 5 次但没 `companies/Anritsu.md`"）？
- 催化剂表里"YYYY/MM 看 X" — 日期过了但没跟进？

### 8.5 数据洞
- 公司超过 30 天没刷新
- 行业没有价值链 mermaid 图

**Lint 输出**：一份 markdown 报告，列出问题 + 建议动作。**不自动改文件**——由用户决定。

---

## 9. 特殊场景

### 9.1 未建档公司
1. WebSearch 拉最新财务 + 行业地位
2. 用 `templates/company-template.md` 建 `companies/{TICKER}.md`
3. 加进 INDEX.md
4. log.md 追加 ingest 记录
5. 回答用户

### 9.2 数据过时
1. WebSearch 拉最新
2. 更新文件 + INDEX.md 时间戳
3. changelog 写："YYYY-MM-DD: 数据从 X 更新为 Y"
4. log.md 追加 revise 记录

### 9.3 新数据与旧结论冲突
1. **新数据胜出**
2. changelog 写明冲突原因
3. 若 thesis 错了 → 修订多头 / 空头论点
4. log.md 追加 revise 记录

### 9.4 真实交易发生
1. 建 / 更新 `portfolios/{NAME}.md`
2. 记：进 / 出价、仓位、时间、逻辑
3. log.md 追加 decision 记录
4. INDEX.md 加一条"复盘提醒"todo
5. 触发 [`trade-journal`](../trade-journal/SKILL.md) 记 **来源框架**（闭合反馈环）

---

## 10. 结束前自检

任何触碰股票 / 行业的对话收尾前过一遍：

- [ ] 我读 INDEX.md 了吗？
- [ ] 我读相关公司档了吗？
- [ ] 我用 wiki 内容作答了吗？
- [ ] 有没有新数据 / 新洞见要回写？
- [ ] 有没有一手源要 ingest？
- [ ] log.md 需要新条目吗？
- [ ] INDEX.md 要更新吗？
- [ ] 有新 todo 吗？

**任一为「否但应为是」→ 现在补做**。

---

## 11. Anti-patterns（红线）

### ❌ 1. 不读 wiki 就答
**错**："AAPL 是消费硬件公司…"（凭记忆）
**对**：Read INDEX.md → Read companies/AAPL.md → 基于 wiki 作答

### ❌ 2. 读了不回写
**错**：用旧数据答完就走
**对**：产生新结论 → 追加到文件 + log.md + INDEX.md

### ❌ 3. 建文件不更新 INDEX
**错**：建了 `companies/NEW.md` 但 INDEX.md 不变
**对**：每个新文件 → 更新 INDEX 导航表 + log.md

### ❌ 4. 数据没时间戳
**错**："营收 +20% YoY"（哪个季度？）
**对**："Q3 FY26 营收 $1.81B（+20.5% YoY），YYYY-MM-DD 公布"

### ❌ 5. 只写多头
**错**：只列利好
**对**：任何公司档 MUST 有 bear case

### ❌ 6. Ingest 跳过 Raw
**错**：把文章总结直接写进 wiki，不留原文
**对**：先 `raw/articles/{date}-{slug}.md`，wiki 引用它

### ❌ 7. 改 wiki 不写 log.md
**错**：改了 5 个文件，log.md 一动没动
**对**：每次写操作 MUST 追加 log.md（哪怕一行）

---

## 12. 自定义（迁移到其他领域）

OpenOrder 默认领域是**投资研究**。要迁到别的领域：

1. **改本文件第 3 节**触发关键词，换成你领域的
2. **改 `examples/` 模板**，换实体类型（药物 pipeline / 协议 / 房产 / 论文）
3. **改 `frameworks/`** 匹配你的打分方法
4. **保持第 2/4/5/6/7/8 节不变**——这些是领域无关的操作

见 [`docs/customize.md`](docs/customize.md)：加密 / 生物医药 / 房产 / 学术文献 / 团队知识库示例。

---

## 13. 外部工具集成

| 工具 | 作用 | Agent 怎么用 |
|---|---|---|
| **本地 markdown**（本 wiki） | 主存储 | Read / Grep / Glob |
| **git** | 版本 + 协作 | `git log` + 自动 commit |
| **Obsidian** | 可视化 + 双链 | vault → `${OPENORDER_HOME}` |
| **WebSearch / 浏览器 MCP** | 实时数据 + ingest | 标准工具 |
| [`stock-data-fetch`](../stock-data-fetch/SKILL.md) | 现取行情 | 写公司档 / 组合前 |
| [`claim-verification`](../claim-verification/SKILL.md) | 验真 | 落档前先给声明打 ✅🟡🔴⚠️ |

---

## 14. 版本

| 版本 | 变更 |
|---|---|
| v1.0 | 首次开源，随 AlphaLoop 一起 |

---

## 15. 致谢

三层架构（Raw / Wiki / Schema）、`log.md` 时间线、Lint 操作、Ingest 流程直接来自 Andrej Karpathy 的 **LLM Wiki 模式**：
<https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>

投研领域框架、卡脖子式打分方法、与 AlphaLoop 其他子 skill 的接线是 OpenOrder 的原创。

License: MIT，见 [`../../LICENSE`](../../LICENSE)。
