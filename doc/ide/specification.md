# MMDA-Architect 工具规格

> 版本 0.1 · 草案

## 1. 产品定位

**MMDA-Architect**（么么哒架构师）是面向**软件架构师**的桌面设计工具，用于：

1. 在 **MMDA 规范**约束下进行架构建模（业务分解、数据模型、状态机、事件流）；
2. 维护 **语言无关** 的元模型项目（`.mmda`）；
3. **快速生成可运行原型**（数据库脚本、API 骨架、UI 骨架、示例数据）；
4. 作为 **AI 编程的工具宿主**，通过 MCP/CLI 暴露稳定接口。

Architect **不是**运行时框架，**不绑定** Java 或其他实现语言。

## 2. 用户与场景

| 用户 | 典型场景 |
|------|----------|
| 软件架构师 | 设计 MES/WMS 域模型、模块树、订单/BOM 状态机 |
| 领域专家 | 参与 E-R 与 STM 评审，修改 M语言 |
| 开发工程师 | 从原型出发，在 KEEP 区实现业务逻辑 |
| AI Agent | 读取/修改项目、校验、触发生成、解释架构 |

## 3. 目标与非目标

### 3.1 目标

- 图形 + 文本双通道编辑，**SSOT 为 MMDA 项目**（默认展开目录；可选 `.mmdax` 归档包交换）
- 支持 L1/L2/L3 三层元模型（见 [meta-model.md](../meta-model.md)）
- 内置校验器（命名、关系、状态机、类型映射）
- 可插拔 **Codegen Profile** 生成多语言/多栈原型
- **Design Change Log**：每次保存可回溯、可撤销
- Git 集成（项目目录即仓库）
- **AI Tools**：见 [../ai/tools.md](../ai/tools.md)

### 3.2 非目标（当前版本不做）

- 完整 IDE / 调试器 / 生产部署编排
- 替代 BPMN 的全功能流程引擎设计器
- 绑定单一数据库或单一后端语言
- 在线多人实时协作（可后续扩展）

## 4. 功能规格

### 4.1 项目管理

| 功能 | 说明 |
|------|------|
| 新建/打开/关闭项目 | 工作区目录或 `.mmdax` 包（open 时解压到缓存） |
| Schema 管理 | 逻辑库划分（如 `base`、`mes`、`wms`） |
| 打包/解包 | `mmda pack` / `mmda unpack`；目录 ↔ `.mmdax` |
| 导入/导出 | JSON、M语言 打包；可选从 legacy 元数据库导入 |
| 校验 | 全项目或单文件校验，输出错误/警告列表 |
| 变更日志 | append-only event log，支持时间线回溯 |

### 4.2 架构设计（L1）

| 功能 | 图形/编辑器 | 元模型 |
|------|-------------|--------|
| 子系统划分 | 树形导航 | `Subsystem` / `Module(type=0)` |
| 模块分组 | 树形导航 | `Module(type=1)` |
| 功能特征 | 功能列表，绑定实体 | `Module(type=2)` + `objRef` |
| 用例（可选） | Use Case 图 | `UseCase`（Phase 2，见 [`../requirements.md`](../requirements.md) §4） |
| 需求条目（可选） | 与用例/功能关联 | `Requirement`（Phase 2，形态待裁 → [`../requirements.md`](../requirements.md) §7-1） |

### 4.3 数据架构（L2）

| 功能 | 图形 | 元模型 |
|------|------|--------|
| E-R 设计 | 实体关系图 | `Record`、`Field`、`Relation` |
| 类型与约束 | 属性面板 | `DataType`、nullable、default、check |
| 枚举 / 位枚举 | 枚举编辑器 | `Enum`、`bitwise` |
| 视图 | SQL 风格或图形 | `View` |
| 继承 / 子类型 | 泛化箭头 | `superName`、`fixedFilter` |
| 计算字段 | 表达式编辑器 | `computed`、`formula` |

### 4.4 行为架构（L2/L3）

| 功能 | 图形 | 元模型 |
|------|------|--------|
| 状态机 STM | 状态图 | `@State` + `Action.statusTransition` |
| 业务动作 | 转换上的标签 | `ModuleAction` |
| 多步流程 | 流程图 | `ModuleFlow` |
| 事件声明 | 事件目录 | `Event` |
| 订阅与过滤 | DFD / 订阅图 | `Subscriber`、`Channel`、`Filter` |

### 4.5 呈现架构（可选层）

| 功能 | 说明 |
|------|------|
| UI 字段元数据 | `UiField`：editor、formatter、validation |
| i18n | 标签多语言 |
| 列表/表单布局 | 与 Feature 绑定 |

### 4.6 代码生成与原型

| 功能 | 说明 |
|------|------|
| Codegen Profile | 声明目标栈、输出目录、模板集 |
| 生成物 | DDL、Entity、Repository、Service、API、UI 骨架 |
| 增量生成 | `GENERATED` 区覆盖，`KEEP` 区保留 |
| 一键原型 | Schema 迁移 + 启动配置 + 种子数据 |
| 生成报告 | 文件清单、diff、警告 |

默认 Profile 示例：

| Profile ID | 输出 |
|------------|------|
| `prototype-sqlite` | SQLite DDL + 种子数据 |
| `prototype-api-rust` | Rust + axum 骨架（示例） |
| `prototype-api-ts` | TypeScript + 路由骨架 |
| `prototype-ui-vue` | Vue 列表/表单骨架 |

具体 Profile 由插件注册，规范只定义 **接口契约**。

### 4.7 版本控制

| 功能 | 说明 |
|------|------|
| Design Change Log | 本地 event log（`changelog/`） |
| Git | 项目目录 `.git` 常规集成 |
| SVN | Phase 2 可选 |

### 4.8 建模域清单（设计器要覆盖什么）

来源：作者随想录（原文 [`../archive/2026-09/随想录.md`](../archive/2026-09/随想录.md)）。这份清单回答「**一个业务人员/架构师要把系统建出来，设计器必须提供哪些建模动作**」，逐项标注现状与缺口——**缺口项就是设计器还没规划到的部分**。

| # | 建模域 | 随想录的要求 | 现状 | 缺口 / 待裁 |
| --- | --- | --- | --- | --- |
| 1 | **系统模块分解** | 即 SERU 的 `S`：系统逻辑架构图 + 层级菜单 | 模块三级树、功能架构图（[`workflow.md`](workflow.md) 第 1 步、[`../design-notes.md`](../design-notes.md)） | 层级菜单是**声明**还是**投影**？（待裁） |
| 2 | **组织架构建模** | 图形化输入组织架构图、岗位矩阵图，导入职员清单；用**最佳实践/标杆模板**加速建模 | 旧实现有「岗位」概念（`design-notes.md` 的 `H.02.002 岗位`）、`flow/roles/*.mr` | **✔ 已裁（2026-09-24）两层分治**：**Role（关键用户）是语言元素、与 Module 分解同级**（需求阶段识别关键用户 → 架构设计时 Role 与 Module 同等重要，[`../meta-model.md`](../meta-model.md) §8.1）；**组织架构 / 岗位 / 职员是「数据」**（普通 `Record` + 关系，部门树 / 岗位 / 任职，**不新增元模型元素**），是角色的实例来源。设计器提供图形化输入（组织架构图 / 岗位矩阵图）与职员清单导入，**产物是数据模型文件**。余：**岗位 → Role 的映射规则**待裁（一个岗位可对应多个 Role） |
| 3 | **业务对象建模** | 元数据编辑，**针对模块小范围**定义局部数据模型（ER 图） | E-R 图 ↔ AST 双向、`data/models/**`（§4.3、[`diagrams.md`](diagrams.md) §2） | 局部（模块级）ER 与全局 ER 的合并规则 |
| 4 | **业务主题建模** | 为 BI 提供数据源；**枚举可定义为维度，生成固定维度模型** | 呈现层五视图（[`../presentation.md`](../presentation.md)） | **✔ 方向已裁（2026-09-24）：BI 要有元数据、架构师要能建模**（本域属元模型）；**`MetaBiCube` 族目前只在 C# 侧且不成熟 → 回填语言的具体形态「容后再议」**。可先落：枚举 → 维度 |
| 5 | **给模块设置数据模型** | 首页过滤器、展现器（Index、Report、Dashboard、CRUD） | 五视图（list/form/…）、Feature 绑定 | 「首页过滤器 / 展现器」与「视图」是不是同一件事？需要一个主人（待裁） |
| 6 | **业务流程建模** | ① 图形化输入 BPMN，选输入数据源、转换器、映射、事件、任务节点与输出；② 节点任务与事件**生成代码、插件式加载**；③ 角色由岗位生成；④ Action 串联模块间数据流（DFD）；⑤ 给数据模型设状态机，**流程自动改模型状态** | ① `flow/*.mf` + DFD/BPMN 多 sheet（[`diagrams.md`](diagrams.md) §4、[`graph-files.md`](graph-files.md) §4.5）；② KEEP 区 + 插件（[`plugins.md`](plugins.md)）；④⑤ STM 与 Converter（[`../statements.md`](../statements.md)、[`../events.md`](../events.md)）；⑥ **数据流编排（底座 ESB）** = [`../event_bus.md`](../event_bus.md) §7（节点图 / 数据流图 / 数据映射图三张图；拟在 `*.mf.g` 增 `mf-flow` / `mf-map` view 种类，**待裁**）+ DataMapper（同文 §8） | **BPMN XML 互转**（与 BPMN 工具集成，`design-notes.md` 已提）；「角色由岗位生成」（域 2） |
| 7 | **UI 设计** | ① 配色方案采用 Material Design，支持 Theme Builder，**ColorRole 作为可视化建模的基础**；② **Field Set 对 Field 分组**，按数据类型**自动生成默认的呈现器与编辑器** | ② 已有：字段分组 `groupLabel`、`UiField` 的 editor/formatter 与默认值策略（[`../presentation.md`](../presentation.md)） | **新增**：配色/ColorRole 进不进元数据（设计器级 vs 模型级）（待裁）；参考实现 <https://github.com/material-foundation/material-color-utilities>（Apache-2.0，TypeScript 可用） |
| 8 | **数据可视化** | ① 自定义报表工具（数据源、关联关系、过滤参数、查询条件、结果展现）；② BI 看板设计工具（布局、KPI 数据资产、底层 ClickHouse，学习 Power BI / Tableau） | 报表/BI 目前只在 C# 侧有元数据族，Java 的 `mmda-core-reporting` **0 文件**（[`../contracts-inventory.md`](../contracts-inventory.md) §5） | **✔ 方向已裁（2026-09-24）：BI 要有元数据，最终让架构设计师能建模**（属**元模型**范畴，不是纯 IDE 工具面）；**但既有 `MetaBiCube/Dimension/Hierarchy/Level/Measure` 很不成熟 → 具体形态与是否移植「容后再议」**；ClickHouse 是否作默认分析存储随之后议。可先落：**枚举 → 维度**、固定维度模型 |
| 9 | **生成 → 编译 → 打包发布** | 上面几步走完即可生成源码、自动编译、打包发布（结合 DevOps） | 生成器（[`../targets.md`](../targets.md) §3、[`../PLAN.md`](../../PLAN.md) §3.3）；打包 `.mmdax`（`mmda pack`） | **发布链路**（CI/DevOps 对接、部署形态）尚无专篇 |
| 10 | **变更轨迹与版本控制** | 每次修改自动记录变更轨迹，结合源码管理实现版本控制 → **可回滚设计**；因此设计必须**用文件存储** | 已有：一对象一文件、`changelog/`、Git 集成（§4.7、[`../project.md`](../project.md)） | **✔ 已裁：宿主=独立桌面壳，文件存储（随想录的"VS Code/IDEA 插件"列为后续可选宿主）**——见 §4.9 |
| 11 | **绘图工具** | ER、数据、流程、表单、BI、脚本、代码生成 | E-R、STM、DFD/BPMN、模块树（[`diagrams.md`](diagrams.md) §1） | **表单设计器**（可视化表单布局）、**BI 看图器**、**脚本编辑器**（`mmda` 脚本） |

### 4.9 设计器宿主形态（✔ 已裁 2026-09-24：独立壳优先）

随想录的落点是「**设计工具开发为 VS Code 插件或者 IDEA 的插件**」，而上一轮规格写的是**独立桌面壳**（Tauri + Vue 3 + Syncfusion，§5）。**已裁：独立壳优先。**

| 形态 | 优点 | 代价 | 结论 |
| --- | --- | --- | --- |
| **独立桌面壳**（Tauri + Vue 3 + Syncfusion） | 图形能力自由（Syncfusion Diagram）、界面完全可控；不依赖宿主版本 | 要自己造编辑器/终端/Git 面板 | **✔ 优先交付**（本阶段唯一在做的宿主） |
| IDE 插件（VS Code / IDEA） | 复用编辑/终端/Git/调试；真源是文件 → 插件天然适配；零安装成本 | 图形能力受宿主限制；两套宿主要双份适配 | **后续可选宿主**，不并行开工 |

**三条随之确定的口径**：

1. **内核与图形接口按「宿主可替换」来设计**——`mmda-core`（Rust）+ **LSP 面** + 图形 Webview；`*.g` 已做到布局与语义分离，正是为了让同一份模型能在壳里、也能在编辑器里画。**但接口可替换 ≠ 现在就并行做两套宿主**。
2. **谁是宿主不影响语言与契约**：真源是文件（[`../project.md`](../project.md)）、契约到 `MetaUi` 为止（[`../presentation.md`](../presentation.md) §5.1）——所以将来加插件宿主是**增量**，不是返工。
3. **设计器宿主**：**不承诺国产 OS（✔ 2026-09-24）**——国产化 L2 只承诺**运行时 + 内核 CLI** 跑在国产 OS/CPU 上，设计器仍在 Windows / macOS / Linux-x86 上运行；麒麟 / 统信**桌面版**的 WebKitGTK、字体、输入法适配与 deb / rpm 打包**不进首版**（理由与矩阵见 [`../vision.md`](../vision.md) §5.2.1 第 4 条）。

---

## 5. 技术架构（Architect 自身）

| 层 | 选型（README 约定，可演进） |
|----|------------------------------|
| 桌面壳 | Tauri |
| UI | Vue 3 + Syncfusion（Diagram 等） |
| 核心引擎 | Rust：`mmda-core`（解析、元模型、校验、变更日志） |
| 存储 | 项目文件（SQLite 可选作索引）；非运行时 MySQL 依赖 |
| 异步 | tokio |
| AI 接口 | MCP Server + `mmda` CLI |

```
┌─────────────────────────────────────┐
│  Vue UI（Diagram、Tree、Monaco）     │
├─────────────────────────────────────┤
│  Tauri Commands                      │
├─────────────────────────────────────┤
│  Rust Core                           │
│  · project · ast · validate          │
│  · changelog · codegen orchestrator  │
│  · mcp tools                         │
├─────────────────────────────────────┤
│  .mmda 项目文件 / Codegen 插件进程   │
└─────────────────────────────────────┘
```

## 6. MVP 范围（Phase 1）

**目标**：架构师能在 1 天内从空白项目得到可运行的 CRUD + 状态机原型。

| 包含 | 不包含 |
|------|--------|
| 项目 CRUD、M语言 文本编辑 | Use Case 图 |
| Module 三级树 | ModuleFlow 图形 |
| Record / Enum / Field / Relation | 完整 DFD 编辑器 |
| E-R 图 ↔ AST 双向同步（基础） | 多租户 xmeta |
| STM 图 ↔ Action 双向同步 | 全部 Codegen Profile |
| 校验器（核心规则） | SVN |
| Design Change Log | |
| `prototype-sqlite` + 一种 API Profile | |
| MCP 工具：read/write/validate/generate | |

**参考样例项目**：内置 `examples/mmda-mes`（Bom / ProductionOrder / Partner / Material + STM）。

## 7. 阶段规划

| 阶段 | 主题 | 交付 |
|------|------|------|
| Phase 1 | 建模 + Lang + 基础图 + 原型 | MVP |
| Phase 1.5 | `mmda pack` / `unpack`、`.mmdax` | 归档交换 |
| Phase 2 | ModuleFlow、Event 语言、DFD、UI 元数据 | 完整 L3 |
| Phase 3 | AI 深度集成、Profile 市场、legacy 导入 | 生态 |

## 8. 成功标准

1. 架构师仅通过 Architect + M语言 完成 `examples/mmda-mes` 同级设计，无需手写 DDL。
2. 生成的原型可本地启动并完成 CRUD + 至少一个状态转移 Action。
3. Cursor 通过 MCP 调用 `mmda_validate` / `mmda_generate` 无歧义完成一轮迭代。
4. 规范文档与工具行为一致；SSOT 为 MMDA 项目（工作区目录；`.mmdax` 为等价交换形态）。

## 9. 相关文档

- [meta-model.md](../meta-model.md)
- [diagrams.md](diagrams.md)
- [project-format.md](../project.md)
- [../readme.md](../readme.md)
- [../ai/tools.md](../ai/tools.md)
