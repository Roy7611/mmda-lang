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
| 外部实体 | 外部系统 / 设备 `Record` 或占位 | **EventSource（事件源）**（入）/ **Sink（数据汇）**（出） |
| 处理过程 | `Action` / `Event Handler` | **Processor（处理器）**：`Validator` / `Converter` / `Filter` / `Aggregator` / `Router` / `Splitter` |
| 数据存储 | `Record` | `Record`（同时是 `Sink(Write)` 的落点） |
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
| `flow/*.mf` | `*.mf.g`（多 sheet） | `mf-dfd` / `mf-bpmn` |
| `ui/**/*.mi` | 无 | — |

详见 [graph-files.md](graph-files.md)。

## 10. 相关文档

- [graph-files.md](graph-files.md) — `*.g` 格式与 syncRef
- [meta-model.md](../meta-model.md)
- [language/behaviors.md](../statements.md)
- [events/architecture.md](../events.md)
