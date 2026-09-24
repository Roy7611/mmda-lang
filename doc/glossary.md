# 术语表

> 合并上一轮 `glossary.md`（原文留档 `archive/2026-06/`）并补充当前技术栈术语。

## 1. 架构与元模型

| 术语 | 英文 | 说明 |
| --- | --- | --- |
| 元模型 | Meta-Model | 描述系统结构的模型，语言无关；见 [meta-model.md](meta-model.md) |
| 元对象 | MetaObject / Record | 实体或视图的逻辑定义 |
| 元列 | MetaCol / Field | 字段：类型、约束、关系引用 |
| 元关系 | MetaRelation | 实体间一对多等导航关系 |
| 子系统 | Subsystem | 业务域顶层划分，如 MES、WMS |
| 模块 | Module | 子系统下的功能分组 |
| 功能 | Feature | 可独立交付的功能单元，通常绑定一个 Record |
| 模块操作 | ModuleAction / Action | 业务动作，常含状态转移 |
| 模块流程 | ModuleFlow | Action 之间的编排（多步流程） |
| 状态转移 | Status Transition | `NEW->APPROVED` 等形式的状态机边 |
| STM 图 | State Transition Machine | 状态机图，Action 的可视化 |
| E-R 图 | Entity-Relationship | 实体关系图，Record 的可视化 |
| DFD | Data Flow Diagram | 数据流图，事件/处理过程的可视化 |
| IR | Intermediate Representation | 元模型的中间表示，跨语言边界（FlatBuffers） |

## 2. 语言与文件

| 术语 | 说明 |
| --- | --- |
| m 语言 | 元模型文本语法；Monaco 语言 id `m-lang`，MIME `text/x-m-lang` |
| M 语言分片 | `.ma` `.mm` `.me` `.ms` `.mr` `.mc` `.mf` `.mi` —— 按类型的语言文件 |
| MMDA 项目 | SSOT：根 `{projectCode}.mmda` 清单 + `biz/` `data/` `flow/` `ui/`；见 [project.md](project.md) |
| 项目清单 | 根目录 `{projectCode}.mmda`（JSON），非语言模型 |
| 工作区 | 展开目录，日常编辑与 git/svn（推荐形态） |
| 归档包 | `.mmdax` —— ZIP 容器，与工作区路径 1:1，便于分发 |
| Part | 包内一个文件或逻辑单元；含 role 与 partType |
| SSOT | Single Source of Truth：设计真相源（工作区为主，包为交换形态） |
| enumSet | 字段上嵌入的关系/枚举 DSL（**旧实现的存储层表示**，语言里已升级为 `@One`/`@Ref`/`@State` 注解） |
| 语料 / corpus | 从真实元数据库反向导出的项目文件（当前 381 个），用作解析器回归集 |

## 3. 行为与事件

| 术语 | 说明 |
| --- | --- |
| Design Change Log | **设计期**变更日志（元数据 diff）；存于 `changelog/*.json` |
| Domain Event | **运行时**领域事件（与 Design Change Log 严格区分） |
| FlowTrail | 实体实例上的动作/状态变更轨迹 |
| Channel | 事件频道（`channel sales.events { … }`） |
| Subscription | 事件订阅（handler / filter / delivery / retry） |
| Delivery | 投递语义：`at-most-once` / `at-least-once` / `exactly-once` |
| 事件底座 | Java / C# 各自实现的事件总线与可靠投递实现（语言只声明接口） |

## 4. 交付与工具

| 术语 | 说明 |
| --- | --- |
| KEEP 区 | 生成代码中允许手写的区域（`~KEEP PARTS BEGIN/END`） |
| GENERATED 区 | 工具生成、再生成时覆盖的区域（`~GENERATED PARTS BEGIN/END`） |
| Codegen Profile | 一套代码生成目标与模板配置（`codegen/profiles/*.yaml`） |
| 代码工厂 | 现有 Java 实现 `mmda-factory`（11713 行），将由 Rust 重写 |
| Code Builder | 生成器基类家族（`JavaCodeBuilder`、`TsEntityCodeBuilder` …） |
| 反向导入 | 元数据库 → 项目文件（`mmda import --db`） |
| Vibe & Spec | 先 Spec 设计、再交给 AI 实现的协作模式 |
| MCP | Model Context Protocol，AI 调用工具的接口面 |

## 5. 编码与映射

| 术语 | 说明 |
| --- | --- |
| objType | Record 种类：`T` 表/实体 · `V` 视图 · `TA` 带 Action · `TAF` 带 Action 与 Flow/审计 · `VAF` 带 Action 与 Flow 的视图 |
| moduleType | Module 层级：`0` Subsystem（`M`）· `1` Module（`M.01`）· `2` Feature（`M.03.001`） |
| relationType | `1` HAS_ONE · `2` HAS_MANY |
| FieldRef 前缀 | `ENUM` 枚举引用 · `ENUMS` 位标志枚举（BitSet）· `REF` 引用（值对象）· `HAS_ONE` 一对一导航 |
| 分区键 PK | Partition Key：文档 COMMENT 的 PK；多租户 BIGINT 字段，常与主键同列 |
| 唯一键 UK | Unique Key：租户内业务唯一，如工号 `empNo` |
| customProperties | API 中 REF/ENUM 的显示标签扩展 |
| MetaUiField | UI 呈现：formatter、editor、renderer |
| UiLogic | 前端模块交互逻辑（beforeEdit 等钩子） |
| MetadataGenerator | 从 DDL 逆向 MetaObject/MetaCol 的工具 |

## 6. 文件扩展名（formatVersion 2.0）

| 扩展名 | 目录 | 内容 |
| --- | --- | --- |
| `.mmda` | 根 | 项目清单（仅 `{projectCode}.mmda`）⚠️ 与决策 B8 冲突，见 [errata.md](errata.md) 冲突 3 |
| `.ma` | `biz/` | 子系统 Module 树 |
| `.mm` | `data/models/` | Record / View |
| `.me` | `data/enums/` | Enum |
| `.ms` | `data/stms/` | STM |
| `.mr` | `flow/roles/` | Role / Auth |
| `.mc` | `flow/converters/` | Converter |
| `.mf` | `flow/` | 跨模块 Flow / BPMN |
| `.mi` | `ui/` | 定制 UI（五视图） |
| `*.g` | 与 SSOT 同目录 | 图形投影（布局/样式） |
| `.mmdax` | — | ZIP 归档包 |
