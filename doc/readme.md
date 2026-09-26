# m 语言规范（总览）

> 本文是语言规范的**入口与设计原则**；语法细则在分篇文档里，不要在这里堆细则。
> 分篇：[datatypes.md](lang/datatypes.md)（类型）、[records.md](lang/records.md)（对象）、[statements.md](lang/statements.md)（表达式与行为）、[events.md](lang/events.md)（事件）、[event_bus.md](lang/event_bus.md)（事件总线与集成编排）、[presentation.md](lang/presentation.md)（呈现）、[meta-model.md](lang/meta-model.md)（元模型）、[project.md](lang/project.md)（项目格式）。
> 未裁决的口径见 [errata.md](errata.md)；工具与 IDE 见 [index.md](index.md#工具与-ide)。
> **愿景与四层目标（为什么做 m 与 MMDA：商业 / 技术 / 用户 / 架构）见 [vision.md](vision.md)**；本文只管**语言本身**。
> **运维与可观测性（DevOps 流水线、监控出口、配置管理、应急处理）见 [operations.md](operations.md)**。
> **上手（五阶段全貌 / 八步实操 / DDL 注释 → `.m` / 配置面速查 / 定制点全景）见 [guide/quickstart.md](guide/quickstart.md)**；**命名约定**见 [naming.md](naming.md)；**用户体验（UX 判据与十原则检查清单）见 [ux.md](ux.md)**。
> **文档分工（作者 2026-09-26 裁定）**：**`doc/` 各篇 = 唯一语言规范真源**；[`guide/`](guide/) 是**程序员视角开发手册（非规范）** —— 只讲「照着怎么做」，**不许与规范冲突、不引入新口径**（有矛盾回 [`errata.md`](errata.md) 开条）。

---

## 1. 是什么

`m` 语言（**MMDA 元模型驱动架构语言**）融合 `SQL`、`C#`、`Java`、`Rust` 的优势语法，是一门**架构、设计**语言（并含受限的表达式层），用于描述：

- **系统架构**：一切围绕数据——数据**存储**架构、数据**呈现**架构、数据**计算**架构；
- **系统设计**：主要是数据流的设计——读、写、校验、映射、转化、解析、聚合、呈现；
- **事件编程**：数据变化监听、触发器；
- **更靠近实现**：支持数据库迁移、多语言转译（生成 Java / C# / TS 等）；
- **Vibe & Spec 编程**：设计好直接交给 AI 实现。

**边界（重要）**：m 是**声明式 DSL + 受限的纯函数表达式层**，不是通用编程语言。业务逻辑仍由工程师或 AI 用 Java / C# / TS 在 KEEP 区实现——这一条与「架构阶段只定义接口」是同一个决定（见 [events.md](lang/events.md) 的「动作（Action）」一节）。

## 2. 设计原则

1. **一切围绕数据**：存储、呈现、计算、事件描述在同一套元模型里。
2. **单一真源（SSOT）**：项目目录（展开目录）是设计真源；归档包（`.mmdax`）是交换形态；图形是投影。
3. **语言无关**：元模型不绑定编程语言与数据库，跨语言/跨库映射由 Codegen Profile 与方言表承载。
4. **设计可运行**：输出可启动的原型，不只是文档。
5. **变更可追溯**：设计变更日志（Design Change Log）与运行时领域事件（Domain Event）**分开**。
6. **AI 可调用**：项目与工具通过 CLI / MCP 暴露稳定接口。
7. **表达式纯净**：参与存储下推与事件重放的表达式必须纯函数（无 IO、确定性），否则重放不可行。

## 3. 层次（L1 / L2 / L3）

```
L1 业务架构   Subsystem / Module / Feature        `models/modules/`（需求与角色在 `intents/`）
L2 领域模型   Record / Field / Relation / Enum / View / STM   `models/objects|enums|stms/`
L3 事件与集成 Event / Channel / Subscriber         `models/flows/`、事件声明（总线与编排见 [event_bus.md](lang/event_bus.md)）
```

## 4. 最小全貌示例

```sql
/// 订单
record Order {
    orderId int64 identity generated,

    orderDate date default now indexed future,

    orderNo varchar(15) charset ascii unique,

    /// 客户
    @One Partner(partnerId, partnerCode, partnerName) as customer
    customerId int64 indexed,

    /// 订单状态
    @State OrderStatusChanged
    status OrderStatus default 0 indexed,

    /// 订单行
    @Many
    items OrderItem[+] readonly,

    /// 总金额
    @Computed sum(amount of each items)
    totalAmount decimal?(19,4) unsigned,

    @Id PK_order(orderId),
}

/// 订单状态
enum OrderStatus : int {
    NEW = 0,
    PAYED = 1,
    CANCELED = 4,
}
```

## 5. 吸收其他语言的什么，为什么

我们喜欢 `Java`、`C#`、`Rust`、`Go`、`Dart` 和 `TS`，但追求**简单、自然**的表达方式。以下是取舍的理由（语法细则见 [statements.md](lang/statements.md)）：

| 主题 | 采纳 | 理由 |
| --- | --- | --- |
| 可空与精度 | C# 的 `?` + 数据库的 `(size)`/`(precision,scale)` | 存储要精确，可空要简洁：`decimal?(19,4)` |
| 整型 | Rust/C# 习惯 + PLC 词汇（`byte`/`WORD`/`DWORD`/`LWORD`） | 领域里设备词汇天然存在，不该翻译 |
| 记录 | `record` / `tuple` / `struct`，**不用 `class`** | 对象是库/文件中的实体，不是内存 OO 类；字段默认可写，不写样板 getter/setter |
| Map | 视为 `record<K,V>`（二元 tuple，首元素为 key） | 一个概念一个主人，不为 Map 另造类型 |
| 箭头 | `=>` 表达 lambda/映射；`->` **只**表达状态转移 | 两种语义分家，读代码时不用猜 |
| 模式匹配 | C# 的 `switch` 表达式 + `when`（**语料另有 SQL 风格 `case when … end`，两者并存**） | 逗号表示「停顿但未结束」，贴近自然语言；`case` 家族为**迁移兼容**保留（字档待裁，见 [statements.md](lang/statements.md) §2） |
| 类型判断 | `is`（同时承担 `typeof`/`instanceof`）、`as`（转换） | 比 `instanceof` + 强转简洁 |
| 引用传递 | 只用 `&` | `*` 传参歧义太大 |
| 文档 | `///` + Markdown，区节用 `@param`/`@remarks` | 不自造文档标记；`[title](url)`、`[func]` 的表达最自然 |
| 计算与触发器 | `@Computed` 表达式 + `@trigger`（before/after） | 期望借元编程生成各库方言的 `trigger`/`procedure`/`function`——数据库脚本天然高效、便于修改 |

## 6. 语言全貌关系

```
.mmda 项目（SSOT；**目录自由，四根为默认**）
    ├── intents/               S1 意图：requirement / usecase / role / uat
    ├── models/modules/        业务架构（subsystem / module）
    ├── models/objects|enums|stms/    record / view、enum、stm
    ├── models/flows|bpml|ui|converters/   flow、bpmn、ui、converter
    ├── tests/                 S3 验收：test（+ baseline/）
    └── delivery/              S4 交付：profile / deploy
        ↕ parse / emit
    元模型 AST / IR（语言无关）
> **布局口径（✔ 2026-09-25）**：**目录自由、四根为默认**；**语言文件统一 `*.m`**（partType 由**正文首关键字**判定，路径与后缀不参与）；语料旧布局（`data/models/*.mm` / `data/enums/*.me` / `data/stms/*.ms` / `flow/*.mf` / `ui/**/*.mi`）见 [project.md](lang/project.md) §11 迁移。
        ↕
    IDE 图形视图 · 数据库 · DDL · 代码骨架 · 文档
```

## 7. 与低代码的区别（为什么不是又一个低代码平台）

「低代码平台有价值吗？为什么好多人不看好？」——随想录里的这个追问，值得正面回答，因为它决定 m 语言的定位。**低代码被质疑的从来不是"少写代码"，而是这几件事**：

| 低代码被诟病的地方 | 根因 | MMDA 的答案 |
| --- | --- | --- |
| 平台锁定，跑不出这个平台 | 元数据与应用都在厂商的运行时里解释执行 | **生成源码**（Java / C# / TS），产物不依赖 MMDA 才能跑；生成的代码进你们自己的仓库 |
| 生成物不可控、没法精细改 | 生成区与手写区混在一起，改了下次就被覆盖 | **`GENERATED` / `KEEP` 区协议**（[`targets.md`](targets.md) §4 的关键证据：C# 侧头部就写着"GENERATED PARTS 之间别改"） |
| 复杂的撑不住，最后还得写代码 | 定位是"替代程序员"而不是"承接设计" | 我们**不替代业务逻辑**：m 只声明架构与设计，逻辑在 KEEP 区用 Java/C#/TS 写（[`readme.md`](readme.md) §1 边界） |
| 业务人员其实还是不会用 | 用"人人都是开发者"当卖点，回避了业务语义本身没想清的问题 | **承认鸿沟**：入口是需求工程，业务人员经 AI 提需求、设计师落盘（[`requirements.md`](requirements.md) §5、[`workflows.md`](workflows.md) §7） |
| 变更不可追溯、回滚靠备份 | 图形模型存在平台数据库里 | **真源是文本文件**（一对象一文件）+ `changelog` + git/svn，**粒度到对象**，可 diff 可回滚可评审 |
| 无法与现有工程体系共存 | 自建一套 IDE、一套流水线 | **只做设计侧**：LSP/CLI/MCP 接口，别的交给现有 IDE、CI 与 DevOps（[`ai/tools.md`](ai/tools.md)） |
| 多端不一致，说法靠嘴 | 没有"统一"的可执行定义 | **契约三层 + 跨端一致性测试**：同一份 `.mmda` 与同一组用例，三端结果必须一致（[`targets.md`](targets.md) §5） |
| 只画图不产出，或只产出不画图 | 图形与文本各管一段 | **图形是并列双前端，AST/元模型是唯一真源**，`*.g` 只存布局 |

一句话：**低代码卖的是"免开发"，MMDA 卖的是"把设计与实现之间的契约变成可执行、可校验、可回滚的真源"**——设计仍然是工程师与架构师的设计，只是它第一次变成了机器能读懂的东西（这也是 AI Agent 能当实现者的前提）。

## 8. 相关

- [index.md](index.md) — 全部文档索引
- [errata.md](errata.md) — 待裁决口径（**写解析器前必读**）
- [meta-model.md](lang/meta-model.md) · [project.md](lang/project.md)
- `..\PLAN.md` — 落地计划（决策、阶段、验收）
