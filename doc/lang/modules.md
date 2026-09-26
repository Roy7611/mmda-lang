# 模块树、Role 与权限

> **定位（✔ 2026-09-26 作者批注：「开，但是整到新目录里去」）**：把**模块树（业务架构）**、**Role / 权限**、**跨模块流程**三条的**语义**收到一处。
>
> **不重复定义**：语法形态与目录布局的真源仍是 [`project.md`](project.md) §1.1（导航分区 → 阶段 / 目录 / partType）与 §3.1（模块树语法）；本篇只写**语义与约束**并给指针 —— 两处口径不得漂移。
>
> ⚠️ **本篇由助手按真源合并而成（原缺口：这三条散在 `project.md` / `meta-model.md` / `naming.md`，没有独立规范篇），请作者过目。**

---

## 1. 两种节点：`subsystem` / `module`

- **一文件 = 一棵子树**（[`project.md`](project.md) §3.1）：`subsystem mes in Erp { … }` 里包 `module M.03 Production { … }`。
- **`partType` 由正文首关键字判定**（[`project.md`](project.md) §1.2）：`subsystem` / `module` ⇒ 模块树；**文件后缀恒为 `*.m`**（旧 `.ma` 已作废、读作 `.m`）。
- 模块**可嵌套**子模块（语料示例两层；**深度未设上限**）。
- 落点：`models/modules/`（推荐目录，**目录自由** —— 见 §3）。

## 2. 模块编号

- 编号形态 `M.01` / `M.03.032`；**编号是 S1 → S2 的锚**：`requirement` 的 `@Feature M.01.001` 按编号找模块节点（[`project.md`](project.md) §1.3）。
- **编号不是路径**：移动 / 重命名目录**不改编号**，引用一律按**符号名 / 编号**解析（[`project.md`](project.md) §1.3）。
- 命名与权限码沿用既有（[`naming.md`](../naming.md)：模块编号 `M.01` · 权限码 `B` · 端点 id）。

## 3. 模块挂三样东西（一律按符号名，不写路径）

| 槽 | 写法 | 指向 |
| --- | --- | --- |
| `model:` | `model: Bom` | 同名的 `record` / `view` part |
| `ui:` | `ui: { editor: BomEditor, index: BomList }` | 同名的 `ui` part |
| `flow:` | `flow: mes-operate` | 同名的 `flow` part |

- 解引用走**符号名**（[`project.md`](project.md) §1.3）⇒ **目录自由**、移动 / 重组不改语义。
- 模块**不是 record**：模块槽不参与落库；需要多值的字段一律走**子表**（[`records.md`](records.md) §1.3 / [`datatypes.md`](datatypes.md) §10）。

## 4. Role 与权限

- **Role 的能力范围（声明）在语言里**；**谁持有哪个 Role** 在 **IDE 项目管理**里配置（[`meta-model.md`](meta-model.md) §Role、[`workflows.md`](../workflows.md) §1.2）—— 语言层不记「谁持有」。
- 操作权限 = **`allowOps` 位掩码**（[`meta-model.md`](meta-model.md):319）；权限码沿用既有单字母（`B`…，[`naming.md`](../naming.md)）。
- **装载期做冲突检测**（同名 Role / 权限码 / 端点 id 冲突 = 装载期报错，[`naming.md`](../naming.md)）。
- ⏳ **待裁**：**岗位 → Role 的映射规则**（一个岗位可对应多个 Role？[`meta-model.md`](meta-model.md):335 已登记）。

## 5. 跨模块流程

- partType = **`bpmn`**，落 `models/bpml/`（**目录名待裁**：建议改 `bpmn/`，[`project.md`](project.md) §11-④）；旧后缀 `.mb` 已作废（**读作 `.m`**）。
- **与模块内数据流分工**：`flow`（旧 `.mf`）= 模块内数据流；`bpmn`（旧 `.mb`）= **跨模块流程**。
- 运行时与集成面（Endpoint / DataFlow 三图 / Outbox / 引擎 `embedded` 默认）见 [`event_bus.md`](event_bus.md) 与 [`events.md`](events.md)。
- ⏳ **待裁**：图形投影的后缀与格式（`{SSOT}.g` 形态，[`project.md`](project.md) §11-①）。

## 6. 分工表（谁是哪个主题的真源）

| 主题 | 真源 |
| --- | --- |
| 目录 / 阶段 / partType / 文件后缀 | [`project.md`](project.md) §1.1–§1.4 |
| 模块树语法与示例 | [`project.md`](project.md) §3.1 |
| Role / 权限 / `allowOps` 元模型 | [`meta-model.md`](meta-model.md) §Role |
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
