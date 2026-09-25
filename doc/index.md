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
| 21 | [operations.md](operations.md) | **运维与可观测性（运维篇）**：五层监控模型（客户端 / 业务 / 应用 / 系统 / 网络）与责任归属、**元数据驱动的自动打点（零手写）**、三支柱 Metrics·Logs·Traces 与三个关联键、**与 Prometheus / Zabbix / Open-Falcon·夜莺的集成（只出标准出口 + 模板资产）**、DevOps 流水线与 Jenkins 集成、CI 输出契约、配置管理与漂移检测、应急 SOP 与 KPI、运维面安全、多租户与离线 |
| 22 | [ux.md](ux.md) | **用户体验（UX）**：UX 与 Usability 之分（ISO 9241-11 vs 诺曼 1993）、**体验四层环**（Utility → Usability → Desirability → Brand Experience）、认知心理学与人因的**五条设计判据**（示能/意符/映射/反馈/人的差错）、**尼尔森十大原则 → A/B 类可判定信号清单**、UCD 六阶段与 **MVP 金字塔**（承诺下三层）、传统/Lean/Agile UX 三方对照、服务设计边界、**包容性三条可判定检查**、**一手材料与版权边界**、待裁 4 条 |
| 23 | [glossary.md](glossary.md) | 术语表（**§3.1 = 事件与集成的唯一命名**：EventSource / EventSink / Endpoint / Connector / Channel / Processor 与**禁用别名**；**§3.2 = 易混淆概念辨析**：pub/sub ↔ produce/consume、channel ↔ pipe、**inbound/outbound ↔ inbox/outbox**） |
| 24 | [naming.md](naming.md) | **命名约定**：接口 **`I` 前缀**、实现类**禁 `Impl`**、类与对象 **PascalCase**、字段与属性 **camelCase（含 C#）**、其余**尊重各端习惯**；**契约名三端逐字一致**的清单与一致性查法；生成器 / Profile 的责任边界 | 
| 25 | [errata.md](errata.md) | 待裁决口径与校勘记录（§五 记录**已裁决**项） |
| 26 | [guide/enums.md](guide/enums.md) | **枚举开发指南**（照着写：模板 → 注释 → 外观 → 自检 → 迁移） |
| 27 | [examples/README.md](examples/README.md) | **m 语言示例**（取自 `mmda-mes` 语料的 `Material` / `Bom` / `DailyReport` / `Operation` 及其枚举、状态机；语料即基线 + 字段级 `partitioned` 等价简写） |

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
| [guide/quickstart.md](guide/quickstart.md) | **快速上手**：五阶段全貌（含流程图）、八步实操、DDL 注释 → `.m`、命令（含旧版对照）、**元数据配置面速查**、**载荷形态**、**定制点全景**、常见坑 |
| [guide/enums.md](guide/enums.md) | **枚举开发指南**：一分钟模板、命名与文件、注释规范（`/// label : description`，写在上一行）、值域与位枚举、`@State` 与状态机、**外观注解**（颜色 `@Colorized` / `@Color` + 7 角色 + 封闭 10 档 shade；图标 `@Iconized` / `@Icon` 完整别名）、回落规则表、自检清单、常见坑、迁移、三端落地 |
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

- m 语言规范：草案 **0.75**（2026-09-25：**术语调整：色板档位值 = `shade`**（`@Colorized(role, shade?)` / `@Color(role, shade?)`；元数据列 **`colorShade`**，原 `colorDepth` 作废）；**新增 [`guide/enums.md`](guide/enums.md) 枚举开发指南**（把本轮枚举的四批裁决整理成照着做的 how-to：模板 / 注释规范 / 颜色 7 角色 + 10 档 shade / 图标完整别名与默认别名 / 回落规则 / 自检 / 迁移 / 三端落地）；**枚举默认别名 5 条细节收口**（`@Icon(x)` = **完整别名**、默认别名 = 成员名 **kebab**、`@Colorized` 只给默认色板值 + 成员 `@Color` 回落、色板 shade（色阶）**封闭 10 档** `50`–`900` 省略 = `500`、**`@Iconized` 不写括号**取成员名）；**枚举默认色 / 默认别名 / `gray`**（`@Colorized(primary, 200)` 默认色、`@Iconized(default)` 默认别名取成员名、`@Iconized("bom")` 前缀 → `bom-design`、成员 `@Color(role, shade?)`、角色含 **`gray`** 共 7 值）；**枚举外观注解 6 条细节收口**（颜色角色**封闭 6 值**、主题不新增角色、**图标别名开放**由开发人员定义语义词 + UI 层映射 + 没映射上顶多不显示）；**枚举外观注解**（`@Colorized` / `@Iconized` 开关 + 成员 `@ColorRole` / `@Icon("alias")` 取值；颜色 = 角色不是色值、图标 = 别名不是库绑定）；**文档注释规范**（`/// <label> : <description>` = 显示标签 + 描述，写在元素上方、不许行尾；示例集 `.me` 33 处已迁移）+ **段口径澄清**（realId 跨表重复正常，段只在同组内有语义）；示例集补 **`Routing`（工艺路线）= 你说的 `mes.Process`**（`Operation` 为其子项）；**新增 [`examples/`](examples/README.md) 示例集**（16 个文件取自 `mmda-mes` 语料，逐字照语料、只改 `@PartitionID` → `@Partitioned`）+ 实测发现三项（共用段 / 段范围 5 种写法 / `b'0` 位字面量）：**文档与图形出口 5 条细节已裁**（`mmda doc` + `mmda diagram`；首版 Mermaid + PlantUML；每对象一节 + `--with ui,tests`；固定骨架 + 模板可覆盖；不反哺布局）：**代码与图 → Markdown 文档 + Mermaid / PlantUML 源码（可嵌 md）**：`ide/diagrams.md` §10 + `targets.md` §9（两出口、不造新图语言、只出不进、`diff = 0` 进 P9、图种映射表）：**`errata.md` 全篇再盘清滞后**（§二 逐行补语料实测 + 假出处回正 + 已裁压缩成指针；§三 修编号重复与残留矛盾；`@Computed` 处数回正 75/28 文件）：**纯脚本文件 = `.m`**（模型之外单独成文件、**与对象同目录**、可 `import` 复用；`runtime.md` §4.7）+ 撤销扩展名族误改（`df4dc99`）：**撤销对扩展名族的误改**（`df4dc99` = revert `d67fe7e`，分片族原样保留）+ 登记待裁「**拦截器 / 钩子这类纯脚本是否用 `.m`**」（§二-13）：合并 → 补入 C# 后端实测与目标端契约 → 三条裁决落地 + P0.5 契约盘点 → 架构评估 → UI 契约收紧 → 质量定量层 → 需求工程与设计器建模域 → 宿主形态 / 组织架构是数据 / BI 元数据方向三裁 → Role 进语言（与 Module 同级） → 运行架构与拦截点上升到语言 → API 契约与 API 管理集成 → API 边界 = module 边界（插件不侵入语言） → OAS 3.1.0 原生支持 + AI 造数 → **API 契约四条落定（REST 语义 / 精度优先序列化 / 官方 Schema 门禁 / AI 造数固化）** → **仓重命名 `D:\2026\c` → `D:\2026\rust` 并接入 git（无规范内容变更，仅仓路径与台账）** → **愿景与四层目标落成 [`vision.md`](vision.md)（open core 边界 / 国产化全三级 / 部署方式只作部署方式 / 业务可测指标）** → **L2 国产化目标矩阵落定（x86_64 + aarch64 / 麒麟·统信验收 + openEuler 基线 / 毕昇 JDK 21 / 设计器不进国产 OS / 离线交付）** → **共赢落成插件市场 + 设计阶段原生支持插件式开发（[`ide/plugins.md`](ide/plugins.md) §8–§12）** → **插件主形态纠正为「业务功能模块插件」（[`runtime.md`](runtime.md) §7）+ 核心平台统一 MIT + 移动端 Flutter + OWASP ASVS 进硬门禁（[`quality.md`](quality.md) §3.2）** → **事件总线与集成编排落成（[`event_bus.md`](event_bus.md)：底座 ESB、概念模型 Event → Message → Data、DataFlow 三张图、引擎语义对齐 Flink 而运行时可替换）** → **事件与集成的术语统一（[`glossary.md`](glossary.md) §3.1：EventSource / Sink / Endpoint / Connector / Channel / Processor，禁用 Transformer 等别名）** → **易混淆概念辨析（[`glossary.md`](glossary.md) §3.2：`pub/sub` ↔ `produce/consume`、`channel` ↔ `pipe`、`inbound/outbound` ↔ `inbox/outbox`；**Outbox 保「不丢」、Inbox 保「不重」**）** → **运维篇落成（[`operations.md`](operations.md)：五层监控模型 / 零手写打点 / 标准出口 Prometheus·Zabbix·夜莺 / DevOps 与 Jenkins / 应急 SOP）** → **命名约定（[`naming.md`](naming.md)：接口 `I` 前缀 / 实现类禁 `Impl` / 类与对象 Pascal / 字段与属性 camel / 其余尊重各端习惯，契约名三端逐字一致）** → **命名约定补裁：常量与枚举成员 `UPPER_SNAKE`（全大写、单词间 `_`）** → **数据库标识符 = 模型名（表/视图 = 类名 Pascal、列 = 属性名 camel，便于 ORM 一致性；代价 = 处处加引号 + MySQL 须 `lower_case_table_names=0`）** → **命名约定 6 条收口（检查强度 warning / C# 属性不放宽 / 方法名随各端 / 既有 `Impl` 出迁移脚本 / 不进硬门禁 / 约束与索引名不做硬约束、建议前缀 `IDX_`·`FUNC_`·`PROC_`）——命名篇待裁清零** → **前端与 Flutter 的本地命名尊重生态：组件名 / 文件名 / **CSS BEM** / 资源名允许 `-` 与 `_`（但不进契约，`MetaUi` 与载荷名不变）** → **约束与索引名前缀建议补齐（主键 `PK_`·外键 `FK_`·默认值 `DF_`·索引 `IDX_`·函数 `FUNC_`·存储过程 `PROC_`，全为建议；须显式 `CONSTRAINT` 命名）** → **旧版《MMDA 快速上手》精华并入上手篇（[`guide/quickstart.md`](guide/quickstart.md) 扩为 §0–§12，新增 `doc/assets/`）** → **旧版手册并入后的三条议题裁决：前端工程目录约定不算规范内容 / 五视图钩子补 `beforeSearch`（`report` 暂不设）/ `customProperties.$<字段名>` 保留进契约** → **新增体验篇 [`ux.md`](ux.md)（体验四层环 / 认知心理学五条判据 / 尼尔森十原则 → A/B 可判定信号 / UCD 与 MVP 金字塔 / Lean·Agile UX 三方对照 / 包容性三条检查 / 版权边界）** → **体验面四条裁决（作者取 `1B 2B 3B 4A+B`：度量回流、十原则 A 类子集、无障碍可自动化子集都进 `mmda check` 出 warning；服务设计旅程留在设计器插件侧只读展示）** → **API 契约 16 条全部裁决（路径 = `/api/<模块小写>/<模型名复数>`（即 `GET /api/mes/WorkOrders` 复数形态）、`operationId` = `moduleName_featureName_op`、scope = 模块权限 + Action 权限、`expose` 默认 `internal`、稳定度进语言、**`webhooks` 取 B 首版不做**（对外事件走拉取式端点））** → **运行架构 10 条裁决（拦截点挂 Action/视图、**Action 准入统一 `canDo` 且三端支持 m 语言写逻辑**、生命周期点封闭枚举、`save` 语义合并但服务端保留 `insert`/`update`、缓存策略设计可声明默认可 Profile 重写、**`EntityFactory` + `Repository` 两层且目标消灭手写 SQL 与字符串字段名**、跨模块新事务、插件首版进程内隔离、一插件多 module、不许给他人表加字段；10 条全部已裁——`store` 钩子于同日补裁取 A）** → **运维面 8 条裁决（作者取 `1A 2A 3A 4A 5A 6A 7A 8A`：`/metrics` 为唯一必需出口、交付包附镜像默认不开、Zabbix 只出模板 + trapper 口子、只做 Prometheus 兼容、**`mmda ops` 只读诊断进首版**（同时清掉 `ux.md` 1B 的前置）、**P9 扩为「一致性 + 验收 + 运维出口」**、`mmda doctor` 扩为六项、客户端首版只做 Web）** → **事件总线 9 条裁决（作者取 `1A 2B 4A 5A 6A 7A 8C 9A`：执行层 = 内嵌轻量执行器、**外部端点定义反向导入成语言声明**、端到端只写「状态 exactly-once + 汇端幂等」、多租户 = 共享执行 + 租户键、迟到进侧队列、映射可含外部报文形态、**`Sink` 正式名改为 `EventSink`**、**端点 = API + 集成定义**）** → **扩展名职责重划（作者原话「我想把 `.mf` 给数据流图用，跨模块流程 `.mb`」：**`.mf` = 数据流 DataFlow**（节点图 / DFD / 数据映射图）、**`.mb` = 跨模块流程 BPMN**、`.g` 族扩为 `{ma, mm, ms, mf, mb}`）** → **运行架构 §9-4 补裁（取 A：`store` 级钩子不对设计师开放，§9 十条至此全部已裁）+ 新开待裁「嵌入式脚本执行引擎」（A 受限 m 脚本经 Rust 内核求值 ／ B 宿主脚本引擎 ／ C 不做脚本；技术事实已核入 `runtime.md` §4.5）** → **嵌入式脚本执行引擎落定（作者取 A + 三条口径：脚本 = m 语言受限子集、Rust 内核求值、走 P6 嵌入通道；**允许跨模块调用**（跨模块 = 新事务）、**可访问所有 Entity**（查询 / 条件更新 / 删除，经内核代理）、**能力 = 内核函数**（`script.<域>.<动作>` + `capability` 声明制，`runtime.md` §4.6）；表达式层仍纯函数）** → **脚本的查询形态与兜底层登记为待裁（类 SQL 查询块：**内核编译**（建议，只读）vs **宿主 SQL 包翻译**（已核：jOOQ 开源版不含达梦 / 金仓；Java 现状 Spring Data JPA、C# 现状 **Dapper 2.1.35** 无查询 DSL）；**注入 `EntityFactory` 直写宿主代码 = KEEP 区兜底层**）** → **宿主语言运行期编译（A′：Java Compiler API / Roslyn）登记为待裁 + 双端实测**（JDK 17 / JDK 21 内存编译 19~34 ms、.NET 10 + Roslyn 5.3 冷 344 ms / 热 31 ms；**脚本能读环境、列目录、拿进程号、起进程 → 无沙箱**；建议定位为 KEEP 区扩展的运行期加载，不做钩子脚本语言）** → **脚本语言维持 A + 类 SQL 归入 m 语言未来语法（内核解析编译、不做宿主 SQL 包翻译层、首版不进）+ 兜底层 = KEEP 区 + A′ 不做脚本语言**（作者原话「维持A, m语言，未来如果支持类SQL语法也是有可能的」）** → **脚本运行身份取 C（默认继承调用者 + 可选 `runAs: system`，声明进评审清单 + `mmda check` warning；身份枚举封闭 `caller`/`system`；`system` 不受数据范围但仍受功能开关与审计、写入必须记 `actor`；租户键仍必须有）——脚本引擎议题至此全部清零** → **API 2c 取 1A 2A（`/api` 前缀按模块 `moduleUrl` 配置、复数遵循英文单词、前后端已实现）；补：插件 = 用户用 Java / C# / TS 原生代码做、**不做收费与市场**（§9 改判 ⏸）；Flutter 已有早期实现、版次延后** → **语法基线取语料形态**：**`@` 注解制**（冲突 1）、**`.ma` = JSON 而 `.mm` / `.me` / `.ms` / `.mi` = M 语言文本**（冲突 2，实测 215 / 113 / 41 / 1 全文本）、**行为住独立 `.ms`**（冲突 4）、**`type(size)` + 尾 `?` 即 `varchar(80)?`**（冲突 5）；**`BIGID` = 自有类型（本身即 partitionID、高位存 tenantId）**——**P2 语法基线闸门解除，381 文件可直接当回归集** → **内核侧插件取 B = WASM 组件（wasmtime + component model；A sidecar 降备选、C dylib 仍限官方内置）**；**约束按层级分两种形态（字段级 = 字段行尾裸关键字 `indexed` / `unique`…；对象级 / 组合 = record 体末尾单独具名声明，两字段以上建索引必须走这条）**；**`BIGID` 位布局定死：高 28 位 tenantId（`0x7FF_FFFF`，bit 63 恒 0）+ 低 36 位 realId（`0xF_FFFF_FFFF`），解析 `>>> 36`，`0` = 无租户，realId 由分布式 ID 生成、底座合成（不是 DB）** → **租户位 27 位确认（`0x7FF_FFFF` 不是笔误；bit 63 保留恒 0，ID 恒为正）+ 语料形态实测：`BIGID` 这个名字语料里 0 命中，语料写 `@PartitionID [10000,0x000F_FFFF]` + `uint64 identity generated readonly`（102 处），`[min,max]` 是该对象在 realId 空间领的区间（每对象领一段，不是整段给租户）** → **标识共享（Identity Sharing）机制落定**：**一组要 UNION 成同一视图的表各领一个互不重叠的段**（目的是 UNION 后主键不冲突、视图不用「来自哪张基础表」的标记列）；**租户位决定「谁的」、段决定「哪个表的」**；**169 张不做 UNION 的表共用默认段 `[10000, 0x000F_FFFF]`**；六个标识共享组（Party·Organization Unit·Person / Inventory·Transport Location / 工装器具 / MaterialINSku / Handlable / ProductionScheduleTask）与语料逐段对照见 `records.md` §2. → **`BIGID` 定为语言类型（等价 `uint64 identity partitioned`），分段在 `MetaObject` 上配置 `minId`/`maxId`，取值是 realId（真 id 去掉租户标识后的那部分）范围**；**类型名与约束名一律大小写不敏感（跟 SQL 类似），标识符仍大小写敏感**；同轮修掉 `meta-model.md` / `quickstart.md` 的「高 16 位 / 低 48 位」旧布局残 → **段的分配主体 = 架构师 / 设计师（由人分配，工具不自动分配；跨表 / 视图族的段规划属架构师、单表在既定段内落地属设计师）** → **标识共享组 = 视图声明（视图即组）：语料里 `view person` / `organizationunit` / `materialnsku` / `Maintainable` 就是四个组；补上 UNION 基础表后可机器校验「同组段不重叠 / 一表最多属一组」，待裁三点（基础表一律不新声明位：**基础表 = 视图定义里 `join` / `union` 子句中的表**；待裁收敛为**继承语义下三条**（多个基的列合并 / 冲突规则、基能否是视图、视图自身要不要段）** → **视图的 `:` = C# 风格的继承 / 实现（作者澄清：「语义上是对 `person` 进行定义」）：`:` 右端是基，视图 = 在基上定义出来的新东西；语料唯一带 `:` 的是 `view Product : Bom`（`Bom` 是 record，⇒ 基可以是 record）** → **视图定义规则三条已裁：列清单逐字段显式写 + 名字对不上用 `as` 对齐（规矩照 SQL）／ 基可以是视图（继承链）／ 视图的段可选 —— 只读视图（大多数）不写段** → **段重叠进 `mmda check` 硬门禁（error、生成期拦）：同组基础表段两两不重叠 + 一张表最多属一个组 + 段落在 realId 空间内 → 标识共享议题清零** → **未知名 = 解析期 error：行尾关键字与注解名都进词法分析器 token 表（拼错带 `file:line:col` 报错），`Profile`/`customProperties` 白名单方案作废；解析器 = P2 `mmda-syntax`（尚未实现）** → **仓库加 `.gitattributes`（`* text=auto eol=lf`，零行尾变更）** → **取证口径回正：`D:\2026\java` = 现行实现（新库，入库点 `056ef96`）；老库在 `D:\Java`**，**老库 = `D:\Java\mmda`**（16+48 旧布局的真源：老库 `Tenancy.java:14` `0x7FFF` / `:39` `>>> 48` / `:82-83` `<< 48`） → **注解改名 `@PartitionID` → `@Partitioned`：与元对象属性 `partitioned` 同名；字段级支持行尾 `partitioned`（不带范围，`BIGID` = `uint64 identity partitioned` 的展开式）；旧名已废（语料 186 处待迁移，见旧名即解析期 error）；一个对象只能有一个 `partitioned` 字段 → `mmda check` error** → **旧名一次性迁移：`mmda migrate --rename @PartitionID=@Partitioned`（默认 dry-run 出清单、`--write` 落盘；只动语言文件；与 `naming.md` §5 命名迁移合并，归 P9）** → **术语统一：`成员表`/`来源表` → `基础表`（base table，即 UNION 进视图的那几张表）**；同轮修掉 `meta-model.md` / `quickstart.md` 的「高 16 位 / 低 48 位」旧布局残留**）
- 上一轮规范：草案 0.1（2026-06，`archive/2026-06/`）
