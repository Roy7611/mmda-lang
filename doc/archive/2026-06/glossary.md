# 术语表

| 术语 | 英文 | 说明 |
|------|------|------|
| 元模型 | Meta-Model | 描述系统结构的模型，语言无关 |
| 元对象 | MetaObject / Record | 实体或视图的逻辑定义 |
| 元列 | MetaCol / Field | 字段：类型、约束、关系引用 |
| 元关系 | MetaRelation | 实体间一对多等导航关系 |
| 子系统 | Subsystem | 业务域顶层划分，如 MES、WMS |
| 模块 | Module | 子系统下的功能分组 |
| 功能 | Feature | 可独立交付的功能单元，通常绑定一个 Record |
| 模块操作 | ModuleAction / Action | 业务动作，常含状态转移 |
| 模块流程 | ModuleFlow | Action 之间的编排（多步流程） |
| 状态转移 | Status Transition | `NEW=>APPROVED` 等形式的状态机边 |
| STM 图 | State Transition Machine | 状态机图，Action 的可视化 |
| E-R 图 | Entity-Relationship | 实体关系图，Record 的可视化 |
| DFD | Data Flow Diagram | 数据流图，事件/处理过程的可视化 |
| M语言 | M language | 元模型文本语法（`.ma`–`.mi`；Monaco id: `m-lang`） |
| enumSet | — | 字段上嵌入的关系/枚举 DSL（存储层表示） |
| Codegen Profile | 代码生成配置 | 一套代码生成目标与模板配置 |
| MMDA 项目 | MMDA Project | SSOT：根 `{projectCode}.mmda` + `biz/` `data/` `flow/` `ui/`（见 project-format.md v2） |
| 项目清单 | Project manifest | 根目录 `{projectCode}.mmda`（JSON），非 M语言 模型 |
| M语言 分片 | M language part file | `.ma` `.mm` `.me` `.ms` `.mr` `.mc` `.mf` `.mi` — 按类型的 M语言 方言 |
| M语言 源文件 | — | format 2.0：`data/models/*.mm` 等；Legacy：`models/**/*.mmda` |
| 工作区 | directory | 展开目录，日常编辑与 Git |
| 归档包 | `.mmdax` archive | ZIP 容器，与工作区路径 1:1，便于分发 |
| Part | — | 包内一个文件或逻辑单元；含 role 与 partType |
| SSOT | Single Source of Truth | 元模型设计真相源（工作区为主，包为交换形态） |
| Design Change Log | — | 设计时变更日志（元数据 diff） |
| Domain Event | — | 运行时领域事件（与 Design Change Log 区分） |
| FlowTrail | — | 实体实例上的动作/状态变更轨迹 |
| Vibe & Spec | — | 先 Spec 设计再交给 AI 实现的协作模式 |
| KEEP 区 | — | 生成代码中允许手写的区域 |
| GENERATED 区 | — | 工具生成、再生成时覆盖的区域 |
| 分区键 PK | Partition Key | 文档中 COMMENT 的 PK；多租户 BIGINT 字段，常与主键同列 |
| 唯一键 UK | Unique Key | 租户内业务唯一，如工号 empNo |
| customProperties | — | API 中 REF/ENUM 的显示标签扩展 |
| MetaUiField | — | UI 呈现：formatter、editor、renderer |
| UiLogic | — | 前端模块交互逻辑（beforeEdit 等） |
| 代码工厂 | Code Factory | mmda-factory / Codegen Profile |
| MetadataGenerator | — | 从 DDL 逆向 MetaObject/MetaCol |

## objType 编码（Record 种类）

| 编码 | 含义 |
|------|------|
| T | 表/实体（Table） |
| V | 视图（View） |
| TA | 带 Action 的实体 |
| TAF | 带 Action 与 Flow/审计的实体 |
| VAF | 带 Action 与 Flow 的视图 |

## Module 层级（moduleType）

| 值 | 层级 | 编码示例 |
|----|------|----------|
| 0 | Subsystem | `M`（制造）、`W`（仓储） |
| 1 | Module | `M.01`（工厂模型） |
| 2 | Feature | `M.03.001`（生产订单） |

## 关系 DSL 前缀（enumSet / FieldRef）

| 前缀 | 含义 |
|------|------|
| `ENUM` | 枚举引用 |
| `ENUMS` | 位标志枚举（BitSet） |
| `REF` | 引用（值对象，不加载整实体） |
| `@One` | 一对一导航；`@One Entity as alias` 简写按目标 `@Name` 显示 |
| `@Ref` | 外键引用（显示用，无导航实体） |
| `@Many` | 一对多集合 |
| `@State` | 状态字段（枚举 + 状态机） |
| `@Computed` | 计算字段 |
| `@PartitionID` | 分区主键 realId 范围 → `MetaObject.partitionKey` + `minID`/`maxID` |
| `@Unique` | 分区内业务唯一编码（**业务层**；不生成 DB unique index） |
| `@Name` | 默认显示名（可多个） |
| `@Thumbnail` | 列表缩略图 |

## 文件扩展名（formatVersion 2.0）

| 扩展名 | 目录 | 内容 |
|--------|------|------|
| `.mmda` | 根 | 项目清单（仅 `{projectCode}.mmda`） |
| `.ma` | `biz/` | 子系统 Module 树 |
| `.mm` | `data/models/` | Record / View |
| `.me` | `data/enums/` | Enum |
| `.ms` | `data/stms/` | STM |
| `.mr` | `flow/roles/` | Role / Auth |
| `.mc` | `flow/converters/` | Converter |
| `.mf` | `flow/` | 跨模块 Flow / BPMN |
| `.mi` | `ui/` | 定制 UI |
| `.mmdax` | — | ZIP 归档包 |

## relationType（MetaRelation）

| 值 | 含义 |
|----|------|
| 1 | HAS_ONE |
| 2 | HAS_MANY |
