# 01 技术栈与内核架构

> 结论先行，理由在后。**待裁项见 [`05-decisions.md`](05-decisions.md) 的 D1 / D2 / D4。**

## 0. 定位（术语纪律，✔ 作者 2026-09-26 提问：**我们的定位是 m 语言的 transpiler 对吗？**）

**答：对一半 —— transpile 是我们后端的一个动作，不是整体定位。**

**事实**：本仓 `transpile*` **0 命中**；既有口径是 [`../PLAN.md`](../PLAN.md):15「**定位：架构/设计 DSL 为主**」+ :28「**m 同时是元数据真源与跨语言契约真源**」+ :54「一个 Rust 内核：**解析、校验、变更日志、DDL、代码生成、包归档**」。

### 0.1 词义辨析（一个概念只留一个主人）

| 词 | 准确含义 | 我们用不用 |
| --- | --- | --- |
| **transpiler**（源到源） | 同抽象层次的机械翻译，通常 1:1（TS→JS、CoffeeScript→JS）；业界隐含"无校验、纯替换" | ⚠️ **只用于描述后端那一步**（m → Java/C#/TS/SQL）；**不作整体定位** |
| **compiler**（编译器） | 前端解析 → 语义分析 → IR → 后端生成（**目标语言是源码不冲突**：TS 编译器也输出 JS） | ✅ **主词** |
| **code generator / emitter**（代码生成器） | 从模型/规范产出代码，每端一个 | ✅ 用（也是你一直用的词） |
| **DSL / DSML** | 领域特定（建模）语言 | ✅ M 的定性（`PLAN.md`:15 原话「架构/设计 DSL 为主」） |
| **validator / linter** | 静态检查与硬门禁 | ✅ 用（`mmda check`） |
| **language server** | LSP 面（诊断/跳转/补全/格式化） | ✅ 用（M7） |
| **evaluator / VM** | 求值（受限脚本） | ✅ 用（P6，Rust 内核求值） |
| **toolchain / CLI** | 工具全家 | ✅ 用（`mmda check / gen / fmt / migrate / doc / diagram / doctor / ops`） |

### 0.2 我们实际做的六件事（哪件才是 transpile）

| # | 做什么 | 是 transpile 吗 |
| --- | --- | --- |
| 1 | 解析 + 校验（硬门禁：段不重叠、import、唯一性、命名） | ❌ 编译前端 + **静态检查** |
| 2 | **元数据产物**（`MetaObject` / `MetaUi` JSON、`mmda-metadata`） | ❌ **编译成数据**，不是源到源 |
| 3 | 三端源码 + DDL 生成 | ✅ **transpile 语义（后端的一段）** |
| 4 | 文档 / 图形出口（Markdown、Mermaid、PlantUML） | ❌ codegen，**目标是文档不是源码** |
| 5 | 语言服务（LSP）+ 迁移 / 格式化（`migrate` / `fmt`） | ❌ 语言服务 + source-to-source **重构**（近亲，不同目的） |
| 6 | 脚本求值（P6） | ❌ **解释器 / VM** |

### 0.3 一句话定位（按场合）

- **对内/技术**：**M 语言的编译器与代码生成器** —— 内核做「解析、校验、IR、生成、包归档」（[`../PLAN.md`](../PLAN.md):54 已这么写）。
- **对外/产品**：**元数据编译器** —— 输入是**元数据真源**，输出是 **三端代码 + 数据库结构 + 元数据产物 + 文档/图形**。
- **描述那一步时**才说 "**source-to-source（transpile）**"。

### 0.4 为什么不把定位钉在 transpiler（三条）

1. **语义太窄**：它暗示"无校验、1:1 机械替换"，而**门禁与语义检查正是我们的主要价值**；
2. **旧印象风险**：会让外部以为"就是模板生成" —— 恰好是 `mmda-factory` 的旧印象，而你要的是**语言**；
3. **漏掉输出面**：输出不止源码（还有元数据 / DDL / 文档 / 图形），这些不是"翻译到另一门语言"。

## 1. 一句话

**Rust 单实现**（对外只出 C ABI + WASM）；**手写 lexer + 手写递归下降 + Pratt**；**无损 CST + 强类型 AST 两棵树**；位置用**字节偏移**；诊断带**码 + span + 修复建议**；生成走 **IR + 各端 emitter**；IDE 只做壳（LSP 客户端 + Monaco）。

```
                    ┌──────────────── 宿主（薄）────────────────┐
  VS Code / Tauri   │ LSP 客户端 · Monaco 高亮 · `*.g` 图形通道  │
                    └───────────────▲─────────────────────────┘
                                    │ LSP (JSON-RPC)
  ┌─────────────────────────────────┴──────────────────────────────┐
  │  m-lsp      诊断 / 跳转 / 补全 / 格式化                        │
  │  m-cli      check · gen · fmt · parse --trace · 项目清单        │
  ├────────────────────────────────────────────────────────────────┤
  │  m-check    符号表 · import 图 · 类型解析 · 硬门禁              │
  │  m-model    typed AST / 元模型（与 doc/lang/meta-model.md 一一对应） │
  │  m-syntax   lexer · parser · CST · 诊断（唯一不依赖第三方的层） │
  ├────────────────────────────────────────────────────────────────┤
  │  m-codegen  IR + Java / C# / TS / DDL emitter（区段保留）       │
  └────────────────────────────────────────────────────────────────┘
```

## 2. 选型逐项（含"不用什么、为什么"）

| 层 | 选型 | 不用什么 / 为什么 |
| --- | --- | --- |
| 内核语言 | **Rust 单实现**，对外 **C ABI（cdylib）+ WASM** | 不用 C 手写、不做 C+Rust 双实现：两套语义必然漂移（[`../PLAN.md`](../PLAN.md) §工程目标） |
| 词法/语法 | **手写 lexer + 手写递归下降 + Pratt 表达式** | **ANTLR**：本仓两次教训（672 行 `.g4` 全废 / 59,020 行生成类在删），且生成代码不可读、错误恢复与诊断不可控、增量难做。**pest / chumsky / winnow（组合子）**：错误恢复弱、行列定位难定制、类型体操后期失控。**tree-sitter 当主解析器**：它是高亮工具，语义校验与生成要的是带类型的 AST（可作为 Monaco 高亮加速器，不入主链路） |
| 语法树 | **无损 CST（保留全部 token、空白、CRLF）+ typed AST** | 只留 AST：注释、原始写法（`@Partitioned [0x80000000..]` 这种）与 CRLF 全丢 → 图形↔文本双向编辑、格式化必炸。语料实测 CRLF + UTF-8 无 BOM，**逐字节还原是硬要求**（[`02-parser.md`](02-parser.md) §1） |
| 增量 | **M0–M4 全量**；**M6 文件级增量**（脏文件 + 依赖图） | 不上红绿树 + salsa：M 语言单个文件小、项目 372 文件，红绿树的复杂度换不来收益；接口留升级路径即可（D2） |
| 位置 | **`TextRange`（字节偏移 u32 区间）+ `LineIndex` 换算 `file:line:col`** | 不存行/列：改一行即全文件失效；偏移换算天然满足「报告必须可点击」 |
| 诊断 | 结构 = `code`（`M0xxx`）+ `severity` + `span` + 主/次标签 + 修复建议 | 不许「解析失败」这类无定位报错；错误码分段见 D7 |
| 代码生成 | **IR（与语言解耦）+ 三端 + DDL emitter**；**退役 `~GENERATED PARTS` / `~KEEP PARTS`**（✔ 2026-09-26 作者选 A）：生成物**整文件覆盖** + **生成清单 `gen-manifest.json` + 指纹**校验（`mmda gen --check`）；二次开发走**独立手写物**（`XxxExt` / Action 实现类） | 现状 `mmda-foundation/mmda-factory`（54 文件 / 11,713 行五栈手写 StringBuilder）契约沿用、实现重写；C# 侧已事实上如此（338 个生成文件只有生成区、239 个 partial 分片）——见 [`06-codegen.md`](06-codegen.md) |
| 方言差异 | **数据表驱动**，编译期生成 Rust 映射 | 不写三份手写实现（Java 8 方言 + C# 3 方言 + N 方言必漂移，[`../PLAN.md`](../PLAN.md) §3.3） |
| LSP | `tower-lsp`；语言 id `m-lang` | 不自造 JSON-RPC 协议层 |
| 测试 | `cargo test` + `insta` 快照 + **规范用例集（正例 + 反例，唯一基准）** + UI 测试（内嵌期望诊断）；语料只做**冒烟**与**漂移报告** | 见 [`04-verification.md`](04-verification.md) |

## 3. crate 划分（依赖单向、越下层越稳）

| crate | 职责 | 依赖 | 里程碑 |
| --- | --- | --- | --- |
| `m-syntax` | lexer · parser · CST · 诊断 · `TextRange` / `LineIndex` | **无第三方解析库**；仅 `memchr` 级别工具 | M1–M2 |
| `m-model` | typed AST / 元模型，**逐条对应 [`../doc/lang/meta-model.md`](../doc/lang/meta-model.md)** | `m-syntax` | M3 |
| `m-check` | 符号表 · import 图 · 类型解析 · 硬门禁规则集 | `m-model` | M3 |
| `m-codegen` | IR + Java / C# / TS / DDL emitter + 区段保留 | `m-check` | M4 |
| `m-cli` | `m check` · `m gen` · `m fmt` · `m parse --trace` · SARIF/JSON 输出 | 上面全部 | M5 |
| `m-lsp` | LSP 面（诊断 / 跳转 / 补全 / 格式化） | `m-check` · `m-codegen` | M7 |
| `m-driver` | 项目装载（`.mmda` 清单 = JSON，实测）、缓存与增量调度 | `m-check` | M5–M6 |

**纪律**：`m-syntax` 不许依赖任何"理解 M 语义"的东西；`m-model` 不许依赖生成器；反向依赖一律视为缺陷。

## 4. 借鉴清单（专业视角，逐条说"借鉴什么 / 不借鉴什么"）

| 来源 | 借鉴 | 不借鉴 |
| --- | --- | --- |
| **rust-analyzer** | 无损语法树 + `TextRange` 偏移 + `LineIndex` + 文件级增量 + LSP 分层（vfs → syntax → hir） | 早期就上红绿树 + salsa（我们规模不需要） |
| **rustc** | 诊断系统（错误码 / 主次标签 / 修复建议）、`//~ ERROR` 式 **UI 测试**、每规则配反例 | 内部中间表示层数（MIR/HIR 多层对我们过重） |
| **Roslyn (C#)** | 「语法 → 语义 → 生成」三段 API 面；**生成区段保留**（`~GENERATED PARTS` 精神的祖师爷）；补全用语义信息而非字面量匹配 | 用 C# 写内核（已裁 Rust 单实现） |
| **TypeScript** | **宽松解析**（语法正确就能出树，语义错误不阻断）、IDE 优先的错误恢复、`.d.ts` 式"契约与实现分离"（我们用 `*.g`） | 牺牲严格性的历史包袱（`any` 式逃生门） |
| **swift-syntax / Dart analyzer** | 库与工具分离、增量重解析的脏文件边界 | 大而全的单仓结构 |
| **LLVM lit / rustc UI test** | 文件内嵌期望输出（`//~ ERROR M0203 at 3:14`），**改一行就回归** | 外部庞大测试框架依赖 |
| **tree-sitter** | 高亮语法（可选、只进 Monaco） | 当语义解析器 |
| **ANTLR4** | 语法文件的**可读文档价值**（我们改用 `doc/` 规范原文承担） | 生成式解析器整条路线 |

## 5. LLM 在实现里的位置（**边界**）

| 能交给 AI 做 | 不许 AI 单独定 |
| --- | --- |
| 写用例与 fixture、写测试数据生成器、写样板代码、查 API/文档、把规范条文翻成 `m-check` 的规则骨架 | 架构分层、语言语义、错误码体系、crate 边界、性能取舍 |
| 机械重构（改名、抽函数），**前提是快照 diff 能证明行为不变** | 在没有反例用例的情况下宣布"支持某语法" |
| 从 `doc/*.md` 提取检查清单 | 引入 `doc/` 里不存在的概念（发现即删） |

**每个 AI 产出必须过 [`04-verification.md`](04-verification.md) 的三条判据**；过不了就是没做。

## 6. 明确不做（首版）

1. 不引入任何语法生成器（ANTLR / pest / 组合子）进主链路。
2. 不做红绿树 + salsa 增量；不做并行解析（372 文件单线程够）。
3. 不做解释执行 / 求值器（[`../doc/runtime.md`](../doc/runtime.md) 的脚本求值属 P6，另立计划）。
4. 不做 UI：IDE 只做壳，逻辑全在内核（M7）。
5. 不做"兼容旧实现"：旧仓代码不复用，只复用 CLI 命令形态（`open / validate / list-records / pack / unpack`）。
6. 不在本仓（`mmda-lang`，docs-only）里塞实现 —— 除非 D4 拍 B。
7. **不用 `~KEEP PARTS` 保留岛承载二次开发**（退役，见 [`06-codegen.md`](06-codegen.md)）；**不生成内部类**（✔ 2026-09-26 作者：「跟 service 混在一起不好，也难以维护」）。

## 7. 性能目标（**目标值，待实测校准后写死为回归阈值**）

| 场景 | 目标 | 备注 |
| --- | --- | --- |
| 全量 parse **372 文件规模**（**只作负载，不作正确性基准**） | < 1.0 s（release，单线程） | M2 起纳入 CI 阈值 |
| 全量 `m check`（同规模） | < 2.0 s | M3 起 |
| 单文件增量重解析 + 重检查 | < 50 ms | M6 起 |
| 单文件 < 2,000 行时 LSP 响应 | < 100 ms | M7 起 |

## 8. 相关

- [`02-parser.md`](02-parser.md) · [`03-milestones.md`](03-milestones.md) · [`04-verification.md`](04-verification.md) · [`05-decisions.md`](05-decisions.md)
- 真源：[`../doc/index.md`](../doc/index.md) · [`../doc/lang/meta-model.md`](../doc/lang/meta-model.md) · [`../PLAN.md`](../PLAN.md)
