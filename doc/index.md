# MMDA 文档索引

> 本目录是 **m 语言与 MMDA 元模型的规范真源**，以 `doc/` 为根。
> 2026-09-24 把 `E:\Dev\mmda-architect` 一轮尝试中有价值的文档并入；被合并的原文留档在 [`archive/2026-06/`](archive/2026-06/)，便于逐条 diff 校验没有丢内容。作者 2026-09 的随想录原文留档在 [`archive/2026-09/`](archive/2026-09/)。
> **尚未裁决的口径冲突集中在 [`errata.md`](errata.md)** —— 写解析器前必须先看它。
> **目标端（后端 Java / C# + 前端 TS）的契约与能力矩阵在 [`targets.md`](targets.md)** —— 写生成器前必须先看它。

## 阅读顺序

| # | 文档 | 内容 |
| --- | --- | --- |
| 1 | [vision.md](vision.md) | **愿景与目标**（为什么做 m 与 MMDA）：商业 / 技术 / 用户 / 架构四层目标与逐条机制、**open core 边界与许可（全栈 MIT）**、**国产化三级承诺**、部署方式口径、业务可测指标、待裁 |
| 2 | [readme.md](readme.md) | 语言规范总览：定位、设计原则、吸收哪些语言的什么、导读 |
| 3 | [datatypes.md](datatypes.md) | 数据类型全集与跨语言/跨数据库映射 |
| 4 | [records.md](records.md) | 对象：字段、限制关键字、关系注解、对象级约束、Enum、View |
| 5 | [statements.md](statements.md) | 语句与表达式：声明、切片、模式匹配、约束表达式、行为与状态机 |
| 6 | [events.md](events.md) | 事件驱动架构 + 事件声明语法（event / channel / subscribe）——**语言面真源** |
| 7 | [event_bus.md](event_bus.md) | **事件总线与集成编排（底座 ESB 能力）**——**运行时与集成面真源**：概念模型 Event → Message → Data、三类集成、端点、DataFlow 三张图、DataMapper、时间与状态语义、Outbox、多租户、监控 UI、**引擎选型（语义对齐 Flink、运行时可替换）** |
| 8 | [presentation.md](presentation.md) | 呈现层：UiField、分组、i18n、五视图 |
| 9 | [meta-model.md](meta-model.md) | 元模型元素（L1/L2/L3）与到旧实现结构的映射 |
| 10 | [project.md](project.md) | 项目格式：目录、扩展名、清单、变更日志、归档、多租户 |
| 11 | [targets.md](targets.md) | **目标端契约**：2 后端 + 1 前端的能力矩阵、capability 分档、一致性测试口径 |
| 12 | [contracts-inventory.md](contracts-inventory.md) | **三端契约盘点清单**（P0.5 交付物）：60+ 概念逐行 `file:line`，标出同名同义 / 同义异名 / 不兼容 / 单侧独有 |
| 13 | [protection.md](protection.md) | **算法与知识产权保护**（草案）：native 边界判据、三端交付形态、Rust 加固清单、许可与法务 |
| 14 | [requirements.md](requirements.md) | **需求工程**：三层需求 → MMDA 落点、**优秀需求四标准各自对应的机械信号**、SERU 四要素、需求管理四步、SRS 形态与追溯链 |
| 15 | [workflows.md](workflows.md) | **角色与工作流**：五类用户的写入边界、交接协议、变更分级、AI Agent 协议与业务人员路径 |
| 16 | [testing.md](testing.md) | **测试与验收**：从架构/设计声明机械生成用例、AI 生成用例人审、三层验收物、覆盖率与变异测试 |
| 17 | [quality.md](quality.md) | **质量模型与自动评估**：ISO/IEC 25010 九特性 → MMDA 可自动信号、A/B/C/D 可判定性分级、三层度量与加权聚合、默认阈值基线、**OWASP ASVS 门禁口径**、IDE 全生命周期能力 |
| 18 | [architecture-review.md](architecture-review.md) | **架构评估**：分层/循环/数据所有权硬规则、Martin 度量（I/A/D）、**SOLID 操作化**、打分模型、建议模板、评审仪式 |
| 19 | [runtime.md](runtime.md) | **运行架构**：四层职责（Controller = API 开放 / Service = 商业逻辑 / Repository = 数据读写 / 缓存 = 横切面）、进入与返回两条路径、**事务边界**、**拦截点统一语义**（设计师配置 + 程序员定制）、装配与聚合、**业务功能模块插件（§7）** |
| 20 | [api.md](api.md) | **API 契约**：API 由声明推导（Module/Feature/视图/Action/Role/约束）、语言层只补 `expose` 与稳定度、OpenAPI 生成与契约测试、设计/测试/运维三面、与 YApi/Apifox/Swagger 的**单向**互动 |
| 21 | [glossary.md](glossary.md) | 术语表（**§3.1 = 事件与集成的唯一命名**：EventSource / Sink / Endpoint / Connector / Channel / Processor 与**禁用别名**） |
| 22 | [errata.md](errata.md) | 待裁决口径与校勘记录（§五 记录**已裁决**项） |

## 工具与 IDE

| 文档 | 内容 |
| --- | --- |
| [ide/specification.md](ide/specification.md) | Architect 工具规格（定位、MVP、Codegen Profile）；**§4.8 建模域清单（11 域，逐项标现状/缺口）**、§4.9 宿主形态（独立壳 vs VS Code/IDEA 插件） |
| [ide/workflow.md](ide/workflow.md) | 架构师六步工作流与导航树 |
| [ide/ui-shell.md](ide/ui-shell.md) | 主界面布局框架与 Host 抽象 |
| [ide/plugins.md](ide/plugins.md) | 插件 API、扩展点、**插件市场**与**设计阶段原生支持**（§8–§12） |
| [ide/diagrams.md](ide/diagrams.md) | E-R / STM / DFD / 模块树与元模型映射 |
| [ide/diagram-adapters.md](ide/diagram-adapters.md) | 图形引擎适配器接口 |
| [ide/graph-files.md](ide/graph-files.md) | 图形投影文件 `*.g` 的格式（含 `.mf.g` DFD/BPMN 多 sheet） |
| [ide/i18n.md](ide/i18n.md) | Shell 与模型双层国际化 |
| [design-notes.md](design-notes.md) | 设计笔记（原 `mmda-workflow.md`，含业务/数据/流程/交互各层 M语言 示例） |

## AI 协作

| 文档 | 内容 |
| --- | --- |
| [ai/tools.md](ai/tools.md) | MCP 工具面与 CLI |
| [ai/vibe-spec.md](ai/vibe-spec.md) | Vibe & Spec 协作流程与约定模板 |

## 参考与对照

| 文档 | 内容 |
| --- | --- |
| [guide/quickstart.md](guide/quickstart.md) | 快速上手 |
| [legacy/README.md](legacy/README.md) | 旧 Java 实现对照（非真源） |
| [legacy/java-factory.md](legacy/java-factory.md) | `mmda meta/java/vui` 与元库表映射 |
| [legacy/runtime-java.md](legacy/runtime-java.md) | Java 版 Repository / SqlBuilder / UiLogic |
| [legacy/import-from-ddl.md](legacy/import-from-ddl.md) | 从 DDL COMMENT 逆向元数据 |
| [templates/conventions.template.md](templates/conventions.template.md) | 项目约定模板 |
| [archive/2026-09/随想录.md](archive/2026-09/随想录.md) | 作者 2026-09 随想录**原文**（未改写；落地口径见 `requirements.md` 与 `ide/specification.md` §4.8） |

## 相关仓库与落地计划

| 位置 | 内容 |
| --- | --- |
| [`..\PLAN.md`](..\PLAN.md) | **落地计划**（决策台账、阶段 P0–P10、验收、回滚） |
| `E:\Dev\mmda-architect` | 上一轮尝试：Rust 内核 1699 行、IDE 壳（Tauri + Vue）、381 文件真实语料、Python 反向工具（**无版本控制**） |
| `D:\2026\java` | **后端 A（Java）**：元数据 18 张表、8 个 DDL 方言、`mmda-factory` 生成器 11713 行；**无事件总线**（`mmda-core-messaging` 全是通知器） |
| `D:\2026\cs\MMDA` | **后端 B（C#）**：762 `.cs` / 70,831 行，模块与 `Meta*` 类名和 Java 同构，**有** `IEventBus`/RedisEventHub/SignalR、`Mmda.Ui.*`（**遗留，不纳入 UI 契约**）、`Mmda.Iot.*`；SVN 工作副本 + `Mmda.Core/` 嵌套 git |
| `D:\2026\ts\mmda` | **前端运行时（TS）**：`@mmda/core`（`metamodel.ts`、`metaui/*`、`logic/validators/*`）+ `vui*`(Vue) / `rui*`(React) 皮肤，共 20 个包 |

## 规范版本

- m 语言规范：草案 **0.18**（2026-09-24：合并 → 补入 C# 后端实测与目标端契约 → 三条裁决落地 + P0.5 契约盘点 → 架构评估 → UI 契约收紧 → 质量定量层 → 需求工程与设计器建模域 → 宿主形态 / 组织架构是数据 / BI 元数据方向三裁 → Role 进语言（与 Module 同级） → 运行架构与拦截点上升到语言 → API 契约与 API 管理集成 → API 边界 = module 边界（插件不侵入语言） → OAS 3.1.0 原生支持 + AI 造数 → **API 契约四条落定（REST 语义 / 精度优先序列化 / 官方 Schema 门禁 / AI 造数固化）** → **仓重命名 `D:\2026\c` → `D:\2026\rust` 并接入 git（无规范内容变更，仅仓路径与台账）** → **愿景与四层目标落成 [`vision.md`](vision.md)（open core 边界 / 国产化全三级 / 部署方式只作部署方式 / 业务可测指标）** → **L2 国产化目标矩阵落定（x86_64 + aarch64 / 麒麟·统信验收 + openEuler 基线 / 毕昇 JDK 21 / 设计器不进国产 OS / 离线交付）** → **共赢落成插件市场 + 设计阶段原生支持插件式开发（[`ide/plugins.md`](ide/plugins.md) §8–§12）** → **插件主形态纠正为「业务功能模块插件」（[`runtime.md`](runtime.md) §7）+ 核心平台统一 MIT + 移动端 Flutter + OWASP ASVS 进硬门禁（[`quality.md`](quality.md) §3.2）** → **事件总线与集成编排落成（[`event_bus.md`](event_bus.md)：底座 ESB、概念模型 Event → Message → Data、DataFlow 三张图、引擎语义对齐 Flink 而运行时可替换）** → **事件与集成的术语统一（[`glossary.md`](glossary.md) §3.1：EventSource / Sink / Endpoint / Connector / Channel / Processor，禁用 Transformer 等别名）**）
- 上一轮规范：草案 0.1（2026-06，`archive/2026-06/`）
