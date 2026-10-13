# 模块树、Role 与权限

> **定位（✔ 2026-09-26 作者批注：「开，但是整到新目录里去」）**：把**模块树（业务架构）**、**Role / 权限**、**跨模块流程**三条的**语义**收到一处。
>
> **不重复定义**：语法形态与目录布局的真源仍是 [`project.md`](project.md) §1.1（导航分区 → 阶段 / 目录 / partType）与 §3.1（模块树语法）；本篇只写**语义与约束**并给指针 —— 两处口径不得漂移。
>
> ⚠️ **本篇由助手按真源合并而成（原缺口：这三条散在 `project.md` / `meta-model.md` / `naming.md`，没有独立规范篇），请作者过目。**

---

## 1. 三种节点：`system` / `module` / `feature`（**硬三级**）

- **一文件 = 一棵子树**（[`project.md`](project.md) §3.1）：`system … { … }` 里包 `module … { … }`，`module` 里包 `feature …`。
- **硬三级**（✔ 2026-10-13）：**级别由关键字定** —— `system` → `module` → `feature`，**不再有更深嵌套**；对应元模型的 `moduleType` `0` / `1` / `2`（**由关键字推导**，见 [`meta-model.md`](meta-model.md) §8）。
- **`partType` 由正文首关键字判定**（[`project.md`](project.md) §1.2）：`system` / `module` / `feature` ⇒ 模块树；**文件后缀恒为 `*.m`**（旧 `.ma` 作废、读作 `.m`；**旧关键字 `subsystem` 一律读作 `system`**）。
- 落点：`models/modules/`（推荐目录，**目录自由** —— 见 §3）。

## 2. 模块编号

- 形态 `M` / `M.01` / `M.03.001`（**段数 = 级别数**、**由父段拼接**）：一级给字母根段、二级两位序号、三级三位序号。
- **编号是身份、不是排序号**：数据库按 `moduleCode` 引用（[`meta-model.md`](meta-model.md) §8）、`test` 的 `module` / `feature` 锚按编号（[`test.md`](test.md) §2.1）、`operationId` 亦然。⚠️ 所以**别拿编号当序号调**；要单独改菜单顺序，写可选的 `order:`（§3）。
- ⚠️ **模块编号不是意图编号的一部分**（✔ 2026-09-28）：`intent` 先于模块树存在，编号是纯序号 `INT-<NNN>`；**模块归属由 S2 侧 `satisfies INT-…` / `satisfies UC-…` 回指算出**（[`intent.md`](intent.md) §0 / §5、[`project.md`](project.md) §1.3）。
- **编号不是路径**：移动 / 重命名目录**不改编号**，引用一律按**编号 / 符号名**解析（[`project.md`](project.md) §1.3）。
- 命名与权限码沿用既有（[`naming.md`](../naming.md)：模块编号 `M.01` · 权限码 `B` · 端点 id）。

## 3. 节点属性槽

**声明头只写编号**；显示名与描述由 `///` 给，其余一切走槽。**槽里一律按符号名引用，不写路径**。

| 槽 | 适用 | 写法 | 说明 |
| --- | --- | --- | --- |
| `model:` | `module` / `feature` | `model: Bom` | 按**符号名**引用同名 `record` / `view` part（**显式写** —— 头部只有编号，没有可默认的名字） |
| `ui:` | `module` / `feature` | `ui: { editor: BomEditor, index: BomList }` | 自定义五视图 part |
| `flow:` | `module` / `feature` | `flow: mes-operate` | 模块内数据流 part（跨模块流程走 `bpmn`，见 §5） |
| `sops` | 三级皆可 | `sops: ALL` | **本节点开放的标准操作位枚举**（词表见 §3.1）；**逐节点显式写、不继承、无缺省** —— 角色权限页据此判断该节点出不出勾选框 |
| `route` | 三级皆可 | `route: 'schedule'` | **前端路由的局段**（全路径由父段拼接派生）；省略 = 由绑定的资源名派生；**推不出或需覆盖时才写**（API 路径与它同源，另见 [`api.md`](../api.md) §8.2-2） |
| `order` | 三级皆可 | `order: 10` | **同级排序键**（整数、可选）；省略 = 按编号；写了则先按 `order` 升序、同值再按编号 —— 让「调顺序」不必动编号 |
| `icon` | `system` / `module` | `icon: 'fas fa-sitemap fa-fw'` | 菜单图标（旧实现原值；别名化见 [`errata.md`](../errata.md) §五-63） |
| `version` / `releaseAt` | `system` / `module` | `version: 1` · `releaseAt: '2026-01-31 10:00:00'` | 模块自身的**版本与发布时间**（设计期元数据）；**不是**接口契约的稳定度 / 版本（[`api.md`](../api.md) §1.2） |

- **`///` = label + description**（✔ 2026-10-13）：首段（`:` 前）= **label**、其余 = **description**。模块族**不落数据库表**（在元数据里是一条 module 记录）⇒ **它的 `///` 进 module 元数据、可 i18n**；这与**对象 / 字段**的 `///`（→ DB `COMMENT`、单语言）**不是一回事**（适用范围见 [`meta-model.md`](meta-model.md) §6.3）。
- 模块**不是 record**：模块槽不参与落库；需要多值的字段一律走**子表**（[`records.md`](records.md) §1.3 / [`datatypes.md`](datatypes.md) §10）。
- **测试也挂 module**（✔ 作者 2026-09-29 二轮口径）：用例声明 `module M.03`（+ `feature M.03.002`）——**测试主要挂二级 Module**，逐级分解为「System 集成 → Module → Feature 功能」；**intent 经其 module 反查全部用例**（`mmda trace INT-…`）。故模块树不只是结构，也是**验收与回归的归属轴**；真源 = [`test.md`](test.md) §2.1 / §5。

### 3.1 `sops` 词表（标准操作位枚举）

| 位 | 名 | 义 |
| --- | --- | --- |
| `0` | `NONE` | 无 —— 该节点不开放任何操作（权限页不出勾选框） |
| `1` | `READ` | 读取（有 Overview 看板） |
| `2` | `EDIT` | 编辑 |
| `4` | `CREATE` | 创建 |
| `8` | `DELETE` | 删除 |
| `15` | `CRUD` | = `READ` \| `EDIT` \| `CREATE` \| `DELETE` |
| `16` | `REPORT` | 报告（**取代旧 `PRINT`** —— ✔ 2026-10-13） |
| `32` | `IMPORT` | 批量导入 |
| `64` | `EXPORT` | 批量导出 |
| `127` | `ALL` | 所有 |

- 词表源头 = [`design-notes.md`](../design-notes.md) 的位枚举（旧实现写在模块对象上，字段名就是 `sops`）；**元模型列名同样归一为 `sops`**（旧列名 `allowOps` 仅作历史对照 —— 与 [`naming.md`](../naming.md) 第 77 行「元数据属性名与语言侧名一致」同口径）。
- 组合写 `|`（`sops: CRUD | REPORT`）；**逐节点写、不继承**。`sops` → OpenAPI 权限的映射：`READ` → **只出读端点**、`CRUD` → **全出**（[`api.md`](../api.md) §1.1）。

## 4. Role 与权限

- **Role 的能力范围（声明）在语言里**；**谁持有哪个 Role** 在 **IDE 项目管理**里配置（[`meta-model.md`](meta-model.md) §Role、[`workflows.md`](../workflows.md) §1.2）—— 语言层不记「谁持有」。
- 操作权限 = **`sops` 位掩码**（词表见 §3.1；元模型列名归一为 `sops`，见 [`meta-model.md`](meta-model.md) §8）；权限码沿用既有单字母（`B`…，[`naming.md`](../naming.md)）。
- **装载期做冲突检测**（同名 Role / 权限码 / 端点 id 冲突 = 装载期报错，[`naming.md`](../naming.md)）。
- ⏳ **待裁**：**岗位 → Role 的映射规则**（一个岗位可对应多个 Role？[`meta-model.md`](meta-model.md):335 已登记）。

## 5. 跨模块流程

- partType = **`bpmn`**，落 `models/bpml/`（**目录名待裁**：建议改 `bpmn/`，[`project.md`](project.md) §11-④）；旧后缀 `.mb` 已作废（**读作 `.m`**）。
- **与模块内数据流分工**：`flow`（旧 `.mf`，读作 `.m`）= 模块内数据流；`bpmn`（旧 `.mb`，读作 `.m`）= **跨模块流程**。
- 运行时与集成面（Endpoint / DataFlow 三图 / Outbox / 引擎 `embedded` 默认）见 [`event_bus.md`](event_bus.md) 与 [`events.md`](events.md)。
- ⏳ **待裁**：图形投影的后缀与格式（`{SSOT}.g` 形态，[`project.md`](project.md) §11-①）。

## 6. 分工表（谁是哪个主题的真源）

| 主题 | 真源 |
| --- | --- |
| 目录 / 阶段 / partType / 文件后缀 | [`project.md`](project.md) §1.1–§1.4 |
| 模块树语法与示例 | [`project.md`](project.md) §3.1 |
| Role / 权限 | [`meta-model.md`](meta-model.md) §Role |
| `sops` 词表（标准操作位枚举） | 本篇 §3.1 |
| 编号与命名约定 | [`naming.md`](../naming.md) |
| 对象 / 字段 / 枚举 | [`records.md`](records.md) |
| 事件与集成 | [`events.md`](events.md) · [`event_bus.md`](event_bus.md) |
| 四阶段流程与页面 | [`workflows-phase.md`](../workflows-phase.md) · [`workflows.md`](../workflows.md) |

## 7. 相关

- [`project.md`](project.md) — 项目格式（目录 / 后缀 / partType）
- [`records.md`](records.md) — 对象与字段
- [`meta-model.md`](meta-model.md) — 元模型（Role / Relation / Action）
- [`event_bus.md`](event_bus.md) — 事件总线与集成编排
- [`errata.md`](../errata.md) — 待裁决与校勘
