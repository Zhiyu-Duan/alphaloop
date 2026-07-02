# OpenOrder · AlphaLoop 的记忆层

### 让每一次投研对话都变成可持续复利的本地 wiki。

**OpenOrder 是 [AlphaLoop](../../README.md) 的一个子 skill，负责「读+写」跨会话研究知识库**——把每次对话的结论、验真结果、决策自动写进你本地的 markdown wiki，越攒越厚。

```
                                    ┌─────────────┐
                                    │  你的研究   │
                                    │  持续复利   │
                                    └──────▲──────┘
                                           │
   ───►  财报       ──┐                    │
   ───►  新闻       ──┤                    │
   ───►  filing     ──┼──►  AI Agent  ─────┤
   ───►  推文/研报  ──┤       ▲            │
   ───►  对话结论   ──┘       │            │
                              │            │
                        openorder skill    │
                              │            │
                       ┌──────▼──────┐     │
                       │  Wiki       │─────┘
                       │  ~/openorder/│
                       │  (markdown)  │
                       └─────────────┘
```

---

## 它解决什么

投研的一个通病：

> 读一份 Goldman 研报，扫 5 条推文，听一段 podcast，看一次财报会。**下周忘掉 90%**。再来一遍。

大多数"AI for research"工具把你更深地推进这个循环——PDF 传给 NotebookLM、结论问 ChatGPT，答案不错，然后**蒸发在聊天记录里**。下周你又拿同样的资料重新推一遍同样的 thesis。

**这不是研究，是很贵的遗忘**。

## 它的思路

openorder 让 AI Agent **维护一份关于你研究领域的持久 wiki**——公司、行业、框架、财报、thesis——并**每次对话都更新**。

```
你：   "MSFT 刚说的 capex 是啥意思？"
Agent：[读 INDEX.md → companies/MSFT.md → 作答]
       [识别到新财报 → 更新 MSFT 档]
       [追加 log.md："2026-05-08 ingest | MSFT FY26 Q3 capex 指引"]

你：   "对 NVDA 有啥影响？"
Agent：[wiki 里已知 NVDA 是 MSFT AI capex 的 25% → 交叉引用 → 双档同步更新]
```

你的知识**复利**。Wiki 每次对话都变得更丰厚。同样的问题不用问两次。

> *"The wiki is a persistent, compounding artifact. The cross-references are already there. The contradictions have already been flagged. The synthesis already reflects everything you've read."*
> — Andrej Karpathy, [LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)

openorder 是这个模式的一个生产就绪实现——针对投研专门配了触发关键词，并作为 AlphaLoop 的记忆层，与验真、行情、建仓归因等子 skill 联动。

---

## 快速开始

openorder 不是独立仓库，它随 [AlphaLoop](../../README.md) 一起分发。在 alphaloop 根目录：

```bash
git clone https://github.com/realnaka/alphaloop.git
cd alphaloop
./install.sh
```

安装脚本会：
1. 检测你装了哪些 AI Agent（Claude Code、Cursor、Codex CLI、Hermes、OpenCode、OpenClaw）
2. 把整个 skills 目录（含 openorder）符号链接到每个 Agent 的对应位置
3. 在 `~/openorder/` 初始化一个空 wiki，含 `INDEX.md`、`log.md`、`raw/` 和模板
4. 在 wiki 目录跑 `git init`，免费给你版本历史

**然后随便开一个 Agent**，问：

> *"NVDA 现在多少钱，最新 thesis 是啥？"*

skill 自动触发，Agent 读你的 wiki、作答、把新洞见写回。

---

## 5 个操作

| 操作 | 什么时候跑 | 干什么 |
|---|---|---|
| **READ** | 每次提到 ticker / 行业 / 框架 | Agent 先读 `INDEX.md`，再钻到相关文件才作答 |
| **INGEST** | 你贴 URL / 财报 / 推文 | 5 步流：抓全文 → 存 `raw/` → 抽实体 → 更新 wiki → 追加 `log.md` |
| **WRITE** | 对话产生新洞见 | Agent 更新公司档 / 框架 / 组合，全部打时间戳 |
| **LOG** | 每次写必附 | append-only `log.md` → `grep "^## \[" log.md` 秒查时间线 |
| **LINT** | 你说 "lint wiki" 或每月定期 | 体检报告：矛盾、过时数据、孤儿文件、缺页、数据洞 |

完整规格见 [`SKILL.md`](SKILL.md)。

---

## 三层架构

```
~/openorder/
│
├── raw/                       ← 第 1 层：immutable 一手源
│   ├── earnings/                财报电话会 / 8-K
│   ├── articles/                推文 / 博客 / 研报
│   ├── filings/                 SEC PDF
│   └── research-notes/          对话过程中的原始笔记
│
├── INDEX.md                   ← 第 2 层：你的 wiki（LLM 维护）
├── log.md
├── companies/{TICKER}.md
├── industries/{NAME}/
├── frameworks/{NAME}.md
├── earnings/{TICKER}-{Q}.md
├── portfolios/{NAME}.md
└── templates/

alphaloop/skills/openorder/    ← 第 3 层：规则（本目录）
└── SKILL.md
```

**为什么要三层？**
- **Raw 神圣不可改**：你永远可以从 raw 重推 wiki
- **Wiki 可变**：随理解演进不断改写
- **Schema 可移植**：5 秒装到任何 Agent 上

---

## 跨 Agent 兼容

openorder **不绑定单一 Agent**。同一份 skill、同一个 wiki、同一批数据，在你用的任何 Agent 里一致。

| Agent | 机制 | AlphaLoop `install.sh` 自动装 |
|---|---|---|
| **[Claude Code](https://claude.ai/code)**（Anthropic） | `SKILL.md`（原生） | ✅ |
| **[Cursor](https://cursor.com)**（IDE + CLI） | `SKILL.md`（兼容） | ✅ |
| **[Codex CLI](https://github.com/openai/codex)**（OpenAI） | `SKILL.md` + `AGENTS.md` | ✅ |
| **[Hermes Agent](https://github.com/NousResearch/hermes-agent)**（NousResearch） | `AGENTS.md` + `~/.hermes/skills/` | ✅ |
| **[OpenCode](https://opencode.ai)**（sst） | `AGENTS.md` | ✅ |
| **[OpenClaw](https://github.com/openclaw)** | `AGENTS.md` | ✅ |
| **[Aider](https://aider.chat)** | `CONVENTIONS.md`（per-project） | ⚠️ 手工 |
| **[Cline](https://github.com/cline/cline) / [Roo Code](https://github.com/RooVetGit/Roo-Cline)** | `.clinerules`（per-project） | ⚠️ 手工 |
| **任何支持 `AGENTS.md` 的** | `AGENTS.md` | ✅（via `~/.config/<agent>/`） |

细节：[`docs/compatibility.md`](docs/compatibility.md)。

---

## 为什么胜过 RAG / NotebookLM / ChatGPT-with-files

| | openorder | RAG / NotebookLM |
|---|---|---|
| **知识累积** | ✅ 每次对话 wiki 变厚 | ❌ 每次查询重新推导 |
| **跨源综合** | ✅ 预计算，存在 wiki 里 | ❌ 每次重新发现 |
| **矛盾跟踪** | ✅ 在 wiki 里被标记、被 log | ❌ 会话之间丢掉 |
| **thesis 演进** | ✅ 多头 / 空头随学习更新 | ❌ 卡在上传那一刻 |
| **跨 Agent 通用** | ✅ 同一 wiki 走 Claude/Cursor/Codex 等 | ❌ 锁定单一产品 |
| **版本历史** | ✅ 开箱即用的 git | ❌ 黑盒 |
| **隐私** | ✅ 100% 本地 markdown | ⚠️ 云上传 |
| **成本** | ✅ 免费（用你现有 Agent 的 key） | 💲 每款单独订阅 |

---

## 与 AlphaLoop 其他子 skill 的联动

openorder 不是孤岛，它是 AlphaLoop 编排器（[`../../SKILL.md`](../../SKILL.md)）里的**记忆层**。典型闭环：

1. 用户丢来一段逻辑 / 推文 / 研报
2. [`claim-verification`](../claim-verification/SKILL.md) 拆条溯源，逐条打 ✅🟡🔴⚠️
3. [`stock-data-fetch`](../stock-data-fetch/SKILL.md) 现取行情
4. [`strategic-materials`](../strategic-materials/SKILL.md) 或你自己的框架挑受益标的
5. **openorder 把整条结论、核验矩阵、个股清单落档**——这就是"读了不写=白做"的位置
6. 若真下单，[`trade-journal`](../trade-journal/SKILL.md) 记入建仓表并绑定**来源框架**，让反馈闭环成立

---

## 典型场景

- **个人投资者**——覆盖 30 支股票池，多头 / 空头随财报同步更新
- **买方分析师**——维护"结构性做空"档，附有源的空头论点和 conviction 分
- **卖方研究员**——维护实时行业地图，同行对比表自动刷新
- **加密研究者**——追踪 50 个协议的 TVL、治理、tokenomics 变动
- **家办 / 投资俱乐部**——通过私有 GitHub repo 与队友共享 wiki

---

## 换到你自己的领域

openorder 默认领域是投研，但架构是通用的。要迁：

1. 改 [`SKILL.md`](SKILL.md) 第 3 节的触发关键词
2. 改 [`examples/company-template.md`](examples/company-template.md) 匹配你的实体（药 pipeline / 房产 / DeFi 协议 / 学术论文）
3. 改 [`examples/INDEX.example.md`](examples/INDEX.example.md) 匹配你的分类

见 [`docs/customize.md`](docs/customize.md) 里加密 / 生物 / 房产 / 学术文献的示例。

也可以参考 AlphaLoop 根目录的 [`docs/customize.md`](../../docs/customize.md)——里面讲怎么改整套流程（不止 wiki）。

---

## 本仓库不包含什么

- **真实研究数据**：你的 wiki 在本地 `~/openorder/`，永远不进这个公开仓库
- **具体公司 / 行业观点**
- **遥测 / 分析 / 联网调用**
- **写死的打分方法**：只有抽象骨架，具体方法由你自己带

---

## Roadmap

- [ ] `examples/` 覆盖非投研领域（加密、生物医药）
- [ ] 可选 `git-sync` hook 支持多机 / 团队
- [ ] VS Code / Obsidian 插件做可视化浏览
- [ ] `openorder lint` CLI（跳过 Agent 直接跑）
- [ ] 结合财报日历的定期新鲜度 CI 模板

PR 欢迎。见 [`AGENTS.md`](AGENTS.md)。

---

## 致谢

openorder 的三层架构、`log.md` 时间线、Lint 操作、Ingest 流程是 **Andrej Karpathy [LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)**（2026）的直接实现。

投研领域框架、跨 Agent 安装脚手架、随 AlphaLoop 打包的模板是 openorder / AlphaLoop 原创。

模式本身可追溯到 **Vannevar Bush 的 Memex**（1945）——一个私人策展的知识库，文档之间有联想路径。Bush 解决不了的维护问题，LLM 解决了。

细节见 [`docs/credits.md`](docs/credits.md)。

---

## License

MIT，见 [`../../LICENSE`](../../LICENSE)。
