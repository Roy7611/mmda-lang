# 架构师工作流

> 版本 0.4 · 与 Architect UI 六步导航对齐  
> 完整示例与 M语言 片段见仓库根目录 [mmda-workflow.md](../design-notes.md)（设计笔记 SSOT）
> **本文是工具视角（UI 六步导航）；五类角色（架构师 / 设计师 / 程序员 / AI Agent / 业务人员）的分工、写入边界、交接与变更分级见 [../workflows.md](../workflows.md)。**

在需求已明确的前提下，架构师在 MMDA-Architect 中按 **业务 → 数据 → 流程架构 → 交互设计 → 交付** 的顺序建模。左侧 **架构导航树** 与右侧 **属性面板** 随所选节点切换；中央编辑区支持 **菜单树 / 架构图 / M语言 / 设计图** 多 Tab。

## 1. 总览

```mermaid
flowchart LR
  P[1 项目] --> B[2 业务架构]
  B --> D[3 数据架构]
  D --> F[4 流程架构]
  F --> I[5 交互设计]
  I --> V[6 交付]
```

| 步骤 | UI 导航 | 架构师活动 | 主要资产 |
|------|---------|------------|----------|
| **1 项目** | 欢迎页 | 新建 / 打开工作区或 `.mmdax` | 根目录 `{projectCode}.mmda` |
| **2 业务架构** | 导航树 · 业务架构 | 子系统 Module 树、功能架构图 | `biz/*.ma` |
| **3 数据架构** | 导航树 · 数据架构 | Record / Enum / E-R；STM 独立文件 | `data/models/*.mm`、`data/enums/*.me`、`data/stms/*.ms` |
| **4 流程架构** | 导航树 · 流程架构 | **角色权限** → Converter、STM、BPMN | `flow/roles/*.mr`、`flow/converters/*.mc`、`flow/*.mf`、`flow/*.mb` |
| **5 交互设计** | 导航树 · 交互设计 | Feature 引用定制视图 | `ui/**/*.mi` |
| **6 交付** | 运行活动栏 | Codegen Profile、`mmda validate` / `generate` | `codegen/profiles/`、`generated/` |

**原则**：数据与行为在 **Record + STM** 中定义，不在 Module 内嵌 Action；Module 通过 `model` 引用元对象；交互设计通过 `ui` 块引用定制视图（默认框架按元数据生成 CRUD）。

## 2. 业务架构

### 2.1 菜单树

三级结构：**系统（App）→ 模块 → 功能特征（Feature）**。编码即使用顺序（如 HR → H.01 招聘 → H.01.001 面试）。

工具提供：

- **树形菜单编辑器**（`modules/modules.yaml` 或未来 Module（.ma））
- **功能架构图**（圆角矩形 = 模块，内嵌矩形 = Feature；与菜单树双视图同步）

### 2.2 Module 元数据（摘要）

| 字段 | 说明 |
|------|------|
| `id` | 模块编码（原 moduleCode） |
| `sops` | 标准操作位枚举：READ / CRUD / … |
| `model` | 绑定的 Record；有 model 则打开其 STM |
| `ui` | 可选定制：index / editor / details / search / report（在 **交互设计** 步骤配置） |

点击树节点 → **属性面板** 编辑上述字段。详见 [meta-model.md](../lang/meta-model.md) 与根目录设计笔记中的 TypeScript 示例。

## 3. 数据架构

### 3.1 左侧导航结构

```
数据架构
├── 枚举          → Enum 编辑器；@State 枚举可进 STM
└── 对象          → Record M语言 / E-R 图
```

### 3.2 Record 与 STM 分离

- **Record / Enum**：字段、关系、约束、计算属性（M语言）
- **STM**：`stm Name on Record.field { action … transition … }`  
  状态来自 `@State` 枚举；Action 驱动转换与 exit 事件

对象级行为在 STM 中设计；跨对象编排见 §4.3 工作流。

## 4. 流程架构

流程架构是独立工作流步骤，内部按 **先权限、后行为** 的顺序展开。

### 4.1 角色权限（第一步）

在进入 STM / Converter / BPMN 之前，先定义谁可以做什么：

- **role**：业务角色（市场专员、销售经理…）
- **auth module**：模块访问；**actions** 子句：Action 级授权
- **scope**：OWNER / WORKGROUP / DEPARTMENT / ALL

实体通过 `IAuthorizable` 约定 `creatorId`、`ownerId` 等字段支撑数据范围。资产目录：`flow/roles/*.mr`（见 [doc/lang/project.md](../lang/project.md)）。

### 4.2 数据流与单对象行为

| 子类 | 图形 / 编辑器 | M语言 |
|------|---------------|------|
| **数据流** | 节点图 / DFD / 数据映射图、Converter 映射 | `flow/*.mf`（+ `flow/converters/*.mc`） |
| **单对象行为** | STM 图 | `data/stms/*.ms` |

### 4.3 工作流（跨模块）

| 子类 | 图形 / 编辑器 | M语言 |
|------|---------------|------|
| **工作流** | BPMN（池 / 活动 / 网关） | `flow/*.mb` |

BPMN 术语对应：顺序流 `->`、消息流 `-->`；活动分 User / Manual / Service Task 等（与 Action 分类对齐）。

### 4.4 导航树结构

```
流程架构
├── 角色权限      → role / auth / scope（Phase 2）
├── 数据流 · Converter
├── STM · {Record}
└── 工作流 · BPMN
```

## 5. 交互设计

交互设计是对 **业务 / 数据 / 流程** 三类架构的补充，排在流程架构之后、交付之前。

导航树 **交互设计** 节点列出 Feature 引用的定制视图（如 `InterviewEditor`）。默认框架按元数据生成 CRUD；`ui` 块覆盖标准五视图（列表 / 编辑 / 详情 / 搜索 / 报表）。

```
交互设计
└── 定制视图      → index / editor / details / search / report（Phase 2）
```

## 6. 与 UI Shell 的映射

| 壳层区域 | 工作流阶段 |
|----------|------------|
| WorkflowRail 1–6 | 上表六步 |
| 架构导航树 | §2–§5 分区 |
| EditorArea Tab | 菜单 YAML / 功能架构图 / M语言 / E-R / STM / BPMN / 视图 |
| PropertyPanel | 当前 Module / Record / Action 属性 |
| BottomPanel | validate / generate 输出 |

实现状态见 [ui-shell.md](ui-shell.md)。

## 7. 相关文档

- [meta-model.md](../lang/meta-model.md)
- [diagrams.md](diagrams.md)
- [language/behaviors.md](../lang/statements.md)
- [events/architecture.md](../lang/events.md)
- [project-format.md](../lang/project.md)
