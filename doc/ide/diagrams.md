# 图形与元模型映射

Architect 中的图形是元模型的**视图**，不是独立数据源。图形编辑产生 AST Patch，写入 `.mmda` 项目中的 M 语言 SSOT；**布局与样式**写入 `{SSOT}.g` 文件（见 [graph-files.md](graph-files.md)）。

## 1. 映射总表

| 图形 | 元模型元素 | SSOT 表示 |
|------|------------|-----------|
| 子系统/模块树 | `Module` (type 0/1/2) | `modules/*.yaml` 或 M语言 `@module` |
| E-R 图 | `Record`、`Field`、`Relation` | `models/*.mmda` |
| STM 状态图 | `Enum` + `Action.statusTransition` | `models/*.mmda` + `actions/*.yaml` |
| DFD 数据流图 | `Event`、`Channel`、`Subscriber` | `events/*.mmda` |
| 用例图 | `UseCase`（Phase 2） | `usecases/*.yaml` |

## 2. E-R 图

### 2.1 节点

- **实体节点** ↔ `Record`（objType T/TA/TAF）
- **视图节点** ↔ `Record`（objType V/VAF）
- **属性** ↔ `Field`
- **PK/UK** ↔ `@Id`、`uniqueKey`、Field 上的 `indexed`/`unique`

### 2.2 边

| 图形边 | 元模型 |
|--------|--------|
| 1:N 组合 | `Relation` (HAS_MANY) 或 `@Many` |
| N:1 引用 | `Field.fieldRef` = `REF` / `HAS_ONE` |
| 继承 | `superName` + `extendType` |

### 2.3 同步规则

- 图上新建实体 → 创建 `Record` + 默认主键 Field
- 图上连 1:N → 若子表无 FK，则添加 Field + `Relation`
- 删除边 → 可选保留 FK 或标记 orphan 警告
- 文本 M语言 修改 → 图形增量刷新（布局从 `.g` 保留）
- 拖动画布 → 仅更新 `{SSOT}.g`，不修改 `.mm` / `.ma` 等

## 3. STM 状态图

### 3.1 绑定规则

> **STM 图绑定到带 `@State` 的 Record 及其 Feature Module。**

- **状态节点** ↔ `status` 字段引用的 `Enum` 各值
- **转换边** ↔ `Action`，标签 = `displayLabel`，守卫 = `executableExpression`
- **边上文字** ↔ `statusTransition` 解析结果

### 3.2 示例（BOM 审批）

```
[NEW] --submit--> [DRAFTED] --certify--> [CERTIFIED] --approve--> [APPROVED]
                      ^                                                    |
                      |---------------- disapprove -----------------------|
[APPROVED] --alter--> [REVISING] --cancelAlter--> [APPROVED]
[*] --abandon--> [ABANDONED]
```

对应 Action：

| actionName | statusTransition |
|------------|------------------|
| submit | `NEW=>DRAFTED` |
| certify | `DRAFTED=>CERTIFIED` |
| approve | `CERTIFIED=>APPROVED` |
| disapprove | `DRAFTED,CERTIFIED=>NEW` |
| alter | `APPROVED=>REVISING` |
| cancelAlter | `REVISING=>APPROVED` |
| abandon | `*=>ABANDONED` |

### 3.3 与 M语言 互转

Lang:

```sql
@State
status BomStatus default NEW,

@Action submit: 提交
submit(NEW -> DRAFTED),
```

STM 图与 M语言 文本共享同一 AST；禁止维护两套状态定义。

## 4. DFD 数据流图

### 4.1 元素映射

| DFD | 元模型 | MMDA 统一名（[`../glossary.md`](../glossary.md) §3.1） |
|-----|--------|--------|
| 外部实体 | 外部系统 / 设备 `Record` 或占位 | **EventSource（事件源）**（入）/ **EventSink（数据汇）**（出） |
| 处理过程 | `Action` / `Event Handler` | **Processor（处理器）**：`Validator` / `Converter` / `Filter` / `Aggregator` / `Router` / `Splitter` |
| 数据存储 | `Record` | `Record`（同时是 `EventSink(Write)` 的落点） |
| 数据流 | `Event` + Payload 字段 | `Event` + `Payload`（走 `Channel`） |
| 通道 | `Channel` | `Channel`（点对点 / 发布订阅是它的投递语义） |

### 4.2 与事件架构的关系

DFD 侧重**跨模块数据流**；STM 侧重**单实体生命周期**。  
`Action` 触发 `Event`，`Subscriber` 连接下游处理，在 DFD 上表现为流。

## 5. 模块树（L1）

```
M  项目制造运营          [Subsystem, type=0]
├── M.01  工厂模型       [Module, type=1]
│   ├── M.01.032  BOM表  [Feature, type=2] → Record Bom
│   └── M.01.030  工艺路线
└── M.03  生产执行
    └── M.03.001  生产订单 → Record ProductionOrder
```

树节点拖拽排序 → 更新 `moduleCode`（需冲突检测）。

## 6. 用例图（Phase 2）

- **Actor** ↔ 角色/外部系统
- **Use Case** ↔ `UseCase` 元素，链接到 Feature
- **include/extend** ↔ 用例关系表

## 7. 图形编辑 UX 原则

1. **选中图形即选中 AST 节点**，属性面板编辑 SSOT。
2. 不允许图形有无对应的元模型元素（孤立装饰除外）。
3. 校验错误在图形上标注（如非法状态转移）。
4. 支持「仅文本模式」：禁用图形，仅 Monaco 编辑 M语言。

## 9. `*.g` 伴生投影

| SSOT | 投影 | graphKind |
|------|------|-----------|
| `biz/*.ma` | `*.ma.g` | `ma-module` |
| `data/models/**/*.mm` | `*.mm.g` | `mm-er` |
| `data/stms/**/*.ms` | `*.ms.g` | `ms-stm` |
| `flow/*.mf` | `*.mf.g`（多 sheet） | `mf-flow` / `mf-dfd` / `mf-map` |
| `flow/*.mb` | `*.mb.g` | `mb-bpmn` |
| `ui/**/*.mi` | 无 | — |

详见 [graph-files.md](graph-files.md)。

## 10. 文本图格式导出与 Markdown 嵌入（✔ 2026-09-25 方向已裁）

> 作者原话：「**我希望我的代码、图最终能生成文档 md，类似 plantuml、mermaid 这些标准，或者我能输出他们的格式，然后嵌入 md**」。

**✔ 方向已裁**：**两个出口** —— ① **模型文档（Markdown）**；② **图的文本格式源码**（Mermaid / PlantUML / D2 / Graphviz dot），**可直接嵌进 md**（GitHub / GitLab / VS Code / Obsidian 原生渲染 Mermaid；PlantUML 需渲染服务或插件）。

**不造新图语言**：图永远是**投影**（既有权：**语义在语言文件、位置与样式在 `{SSOT}.g`**）。文本格式导出器与 Syncfusion 适配器**同层并列**——都是 `DiagramDocument` / `GraphDocument` 的**可替换渲染 / 导出实现**（见 [diagram-adapters.md](diagram-adapters.md) §1）。

### 10.1 图种 → 文本格式映射（草案）

| 图形 | graphKind | Mermaid | PlantUML | 备注 |
| --- | --- | --- | --- | --- |
| E-R 图 | `mm-er` | `erDiagram` | 类图 `entity` | 字段 / 主键 / 外键 / 关系基数 |
| STM 状态图 | `ms-stm` | `stateDiagram-v2` | `state` | 状态 / 事件 / 守卫 / 动作 |
| 模块树（L1） | `ma-module` | `flowchart` 或 `mindmap` | `wbs` / `component` | 层级结构 |
| DFD 数据流 | `mf-dfd` | `flowchart` | `activity` | 进程 / 存储 / 数据流 |
| 跨模块流程 | `mb-bpmn` | `flowchart`（泳道近似） | `activity` | **BPMN 2.0 XML 是另一条线** |
| 数据映射 | `mf-map` | 表格优先 | 表格优先 | 本源映射用表格比图清楚 |
| 用例图 | Phase 2 | `flowchart` | `usecase` | 见 §6 |

### 10.2 只出不进（与 BPMN 的区别）

- **Mermaid / PlantUML / D2 / dot：只导出** —— 文本产物**不回读**成模型（不是第二个真源，改图永远在设计器里改语义）。
- **BPMN 2.0 XML 是唯一可考虑双向的标准**（与外部 BPMN 工具集成，见 [`../errata.md`](../errata.md) §三-16，仍待裁）。

### 10.3 产物属性与验收

- 产物落在**生成区**（可复现、不手改）；**diff = 0** 是 P9 一致性验收的一部分（与 DDL / 接口骨架 / TS 同一套口径）。
- 文档与图**由内核统一产出**（Rust 侧），与 `mmda test --target java,csharp,ts` 的「内核统一驱动」同一条路线；三端骨架不重复实现。
- **文档 = 元数据的投影**：对象 / 字段 / 约束 / 关系 / 状态机 / 视图 / 用例逐项从元数据读，**不另写一份**。

### 10.4 ⏳ 待裁（细节）

1. **命令面**：`mmda doc`（文档）+ `mmda diagram`（图）两条，还是统一 `mmda export --doc` / `--diagram`？
2. **首版格式集合**：Mermaid **必做**（GitHub 原生渲染）；PlantUML / D2 / dot 的取舍？
3. **文档结构**：每对象一节 + 字段表 + 关系图？是否含 UI 五视图与验收用例？是否要一页总览？
4. **模板可否自定义**（模板文件 vs 固定骨架）——固定骨架省事、可自定义更灵活。
5. **导出图能否反哺布局**：作为新画布的初始布局，而不只是看图。

## 11. 相关文档

- [graph-files.md](graph-files.md) — `*.g` 格式与 syncRef
- [meta-model.md](../meta-model.md)
- [language/behaviors.md](../statements.md)
- [events/architecture.md](../events.md)
