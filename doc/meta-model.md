# 元模型

> 合并上一轮 `architect/meta-model.md`（原文留档 `archive/2026-06/architect/meta-model.md`）。
> 元模型是 MMDA 的**语言无关逻辑层**：可序列化为 JSON/FlatBuffers/存库，也可投影为语言文本或图形。
> 落地口径：元模型 → **IR（FlatBuffers，见 `..\PLAN.md` §3.5）** → 各宿主加载（Java / C# / TS）。

---

## 1. 总体结构

```
Schema ──┬── Record ──┬── Field ── FieldRef(Enum|Relation)
         │            ├── Relation
         │            └── Action ── FlowEdge
         └── Enum ── EnumValue

Module(树) ── 绑定 Record、拥有 Action
Event ── Subscription ── Channel
Field ──(呈现层)── UiField
项目 ── DesignChangeLog（设计期，≠ 领域事件）
```

---

## 2. Schema（逻辑库）

业务域的数据边界，如 `base`、`mes`、`wms`。

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `schemaCode` | string | 唯一标识，如 `mes` |
| `displayLabel` | string | 显示名 |
| `systemCode` | char(1) | 子系统编码字母，如 `M` |
| `namespace` | string | 生成代码的命名空间 |
| `description` | string | 说明 |

---

## 3. Record（元对象）

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `schemaCode` | string | 所属 Schema |
| `name` | string | 对象名，如 `Order` |
| `displayLabel` | string | 显示名 |
| `objType` | enum | `T` \| `V` \| `TA` \| `TAF` \| `VAF` |
| `uniqueKey` | string? | 业务唯一字段名 |
| `nameCol` | string? | 显示名称字段 |
| `partitionKey` | string? | 分区主键字段（`@Partitioned` 所在列） |
| `partitioned` | bool | **分区标记**：有 `@Partitioned` 即为 `true`；`BIGID` = `uint64 identity partitioned`；物理表分区 + 按租户 / 段隔离查询（`MetaObject.partitioned`） |
| `minID` / `maxID` | int? | **分段**：该表在**标识共享组**里领的段，取值为 **realId（真实 id，去掉租户标识后的那部分）**下限/上限；**由架构师 / 设计师分配**（工具不自动分配，见 [`workflows.md`](workflows.md) §1）；空 = 类型默认值 |
| `parentIdCol` | string? | 树形父键 |
| `superName` | string? | 继承基类 Record |
| `extendType` | enum | `NONE` \| `EXTENDS` \| `INHERITS` |
| `fixedFilter` | 子类型/视图固定过滤；**在列表视图上呈现为顶端页签**，习惯把状态字段（如「组建中 / 运作中 / 已关闭」）作为固定过滤器 |
| `description` | string? | 文档 |

`objType` 语义：`T` 持久化实体；`V` 只读视图；`TA` 实体 + Action；`TAF` 实体 + Action + Flow/审计；`VAF` 视图 + Action + Flow。

**多租户**：`partitionKey` 指向带 `@Partitioned` 的主键列；**完整 ID = 高 28 位 tenantId（27 位有效）+ 低 36 位 realId**（`records.md` §2.3）；**分段 `minID` / `maxID` 在本对象上配置，取值是 realId（真实 id —— 去掉租户标识之后的那部分）范围**。

---

## 4. Field（元列）

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `name` | string | 字段名 |
| `displayLabel` | string | 显示名 |
| `dataType` | DataTypeRef | 逻辑类型 |
| `nullable` | bool | 可空（语言里的 `?`） |
| `isKey` | bool | 主键成员 |
| `isGenerated` | bool | 自增/生成 |
| `maxLength` | int? | 字符串长度 |
| `precision` / `scale` | int? | 小数精度 |
| `unsigned` | bool | 无符号 |
| `defaultVal` | string? | 默认值表达式（`current_timestamp()` → `now`） |
| `computed` | bool | 是否计算列 |
| `formula` | string? | 计算公式 |
| `constraint` | string? | 检查约束；可编码 `positive`/`future`/`indexed` 等语言限制 |
| `readOnly` | bool | 只读 |
| `fieldRef` | FieldRef? | 枚举/关系（旧实现存 `enumSet` 字符串） |
| `groupLabel` | string? | UI 表单分组（`a1`、`s9`） |
| `listed` | bool | 列表默认显示 |
| `filterable` | bool | 可过滤 |
| `hidden` | bool | UI 默认隐藏；关联外键 `hidden` → `@One` 默认 lazy |
| `colIndex` | int | 排序 |
| `uniqueKey` | bool | 分区内业务唯一（`@Unique`） |
| `nameCol` / `thumbnailCol` | bool | 默认显示名 / 缩略图（`@Name` / `@Thumbnail`） |

### 4.1 语言限制关键字 → 元模型

| 语言 | 元模型/库 |
| --- | --- |
| `indexed` | 索引（或 `constraint`） |
| `unique` | DB 唯一（`constraint`）；`@Unique` 是 `uniqueKey` 业务语义 |
| `identity` / `generated` | `isKey` + 单主键 `*Id`，或 `isGenerated` |
| `default` | `defaultVal` |
| `charset` | `dataType`（`char`→ascii、`nvarchar`→utf） |
| `unsigned` | `isUnsigned` |
| `positive` / `negative` / `future` / `past` | `constraint` |
| `readonly` | `readOnly`；`@Computed` 恒只读 |
| `hidden` | `hidden` |
| `?` | `nullable` |

### 4.2 字段注解 → 元模型

| 注解 | 存储等价（旧 `enumSet`） | 语义 |
| --- | --- | --- |
| `@One Entity(cols…) as alias` | `HAS_ONE …(cols…) AS alias` | 一对一导航（整实体） |
| `@Ref Entity(cols…)` | `REF …(cols…)` | 外键 + 显示列，无导航 |
| `@Many` | `MetaRelation` | 一对多 |
| `@State Stm` | 状态列 + STM | 枚举字段 + 状态机名 |
| `@Computed` | `computed` + `formula` | 计算列 |
| `@Partitioned range` | `partitionKey` + `minID`/`maxID` | 分区 realId 范围 |
| `@Unique` | 列级 `uniqueKey` | 分区内业务唯一 |
| `@Name` / `@Thumbnail` | `nameCol` / `thumbnailCol` | 显示名 / 缩略图 |

解析规则：`ENUM`/`ENUMS` → 引用 Enum（`ENUMS` = BitSet）；`REF`/`HAS_ONE`/`@Ref`/`@One` → Relation（`joinOn: remoteKey=@localKey`）。

### 4.3 `@One` 与 `@Ref`

关联列列表 `Entity(col1,col2,…)`：**col1** 为对方主键（join 本 record 外键），**col2…** 为默认显示列。

| | `@Ref` | `@One` |
| --- | --- | --- |
| 语义 | 外键 + 显示用值对象 | 一对一导航实体 |
| 导航属性 | 无 | 有（`Order.customer`） |
| 典型 UI | dropdown | searchBox |
| API | ID + 显示标签 | 嵌套对象 |
| 加载策略 | — | 尾 `eager`/`lazy`；默认 `@One` eager、`@Many` lazy、`@Ref` eager |

---

## 5. Relation（元关系）

| 属性 | 说明 |
| --- | --- |
| `name` | 关系名，如 `items`（作为主表实体的属性名） |
| `displayLabel` | 显示标题（子表/子网格的标题） |
| `relationIdx` | **UI 布局顺序**（旧版手册的 `relationIdx`：跟界面内子表/页签的先后有关；与 Field 的 `colIndex` 不同层） |
| `relationType` | `HAS_ONE`(1) / `HAS_MANY`(2) |
| `relativeRecord` | 子实体 |
| `joinOn` | 连接条件 |
| `canHave` | 子类型条件表达式 |
| `fetchMode` | 加载策略（语言尾 `eager`/`lazy`） |
| `defaultFilter` / `defaultSort` | 默认查询 |

旧实现的关键点：这些定义在库里是**一个用正则解析的字符串**（`relationType relativeObj(cols) AS name WHERE(…) GROUP BY x SHAPE LIST READONLY ONETIME`，见 `D:\2026\java\mmda-core\mmda-core-data\...\SqlMetadataProvider.java:65`）——m 语言要把它变成一等公民的结构。

---

## 6. Enum

| 属性 | 说明 |
| --- | --- |
| `name` | 如 `OrderStatus` |
| `baseType` | `int` \| `BitSet` |
| `bitwise` | 是否位标志 |
| `colorized` | 是否**开颜色**（`@Colorized`，✔ 2026-09-25） |
| `colorRole?` / `colorShade?` | **默认色**（`@Colorized(role, shade)`，枚举级默认；shade = Material 色板档位） |
| `iconized` | 是否**开图标**（`@Iconized`，✔ 2026-09-25） |
| `iconPrefix?` | **默认别名前缀**（`@Iconized("bom")` → `bom-design`）；`@Iconized`（无参）= 空（默认别名取**成员名 kebab**） |
| `values` | `{ code, value, label, colorRole?, colorShade?, icon? }[]`（`colorRole` / `colorShade` = 成员 `@Color(role, shade?)`；`icon` = `@Icon("alias")`） |

文本存储格式：`0;NEW;新|1;PAYED;已付款`（位枚举：`0;UNKNOWN;-|1;CUSTOMER;客户|…`）。

> ⚠️ **旧实现无颜色 / 图标列**（Java `MetaEnum`：`enumClass` / `displayLabel` / `namespace` / `enumString` / `dataType` / `bitwise`；`MetaEnumMember`：`value` / `name` / `text`）→ 生成期**新增** `colorized` / `colorRole` / `colorShade` / `iconized` / `iconPrefix` 与成员的 `colorRole` / `colorShade` / `icon` 列；`enumString` **保持兼容**、不塞颜色图标（按 4A：DB 元数据是**产物**，加列不受老库约束）。


### 6.1 字符串表示（`enumString`）的扩展段（✔ 2026-09-25 设计）

**老格式**（旧实现，3 段）：

```
value ; name ; text    ← 成员之间用 | 分隔
0;NEW;新|1;PAYED;已付款|4;CANCELED;已取消
```

**扩展格式**（**在末尾追加 2 段，前 3 段含义与顺序不变**）：

```
value ; name ; text ; color ; icon
```

| 段 | 名 | 取值 | 可否省 |
| --- | --- | --- | --- |
| 1 | `value` | 整数（位枚举为位值） | 不可省 |
| 2 | `name` | 成员名（`UPPER_SNAKE`） | 不可省 |
| 3 | `text` | 显示标签（对应 `///`） | 不可省（沿用老规则：不足 3 段 = 解析错误） |
| 4 | `color` | **`<role>` 或 `<role>-<shade>`**（如 `info` / `info-500`）：`role` 取 7 值之一，`shade` 取 10 档之一，`-` 连接 | 可省（= 未声明）；**只写 `-500`（无 role）= error** |
| 5 | `icon` | 图标**别名**（完整别名） | 可省（= 未声明） |

**写法示例**：

```
0;NEW;新;info-500;bom-new        ← 有色有图标
1;DRAFTED;已起草;info-200        ← 有色（200）、无图标（尾随空段可省）
2;CERTIFIED;已审核;;bom-verified ← 只有图标（空段占位）
3;APPROVED;已批准;success        ← 有色、省略 shade（按 `500`）
5;ABANDONED;已弃用               ← 都没有 → 与老格式完全一致
```

**规则**：

- **空段允许**（`;;` = 未声明）；**尾随空段可省**；段内**禁止出现 `;` 与 `|`**（`mmda check` error —— 与老格式同一限制，不做转义）。
- **未声明 = 回落**：成员段为空时按枚举级默认解析（`color` → `@Colorized(role, shade?)`；`icon` → `@Iconized` / `@Iconized("prefix")`）。
- **颜色段写法**：`<role>`（省略 shade = `500`）或 `<role>-<shade>`（如 `info-500`）；`role` 拼错 / 不在 7 值、`shade` 不在 10 档、只有 `-500` 没 role → **`mmda check` error**。
- **枚举级信息不进串**：`colorized` / `iconized` / 默认色 / `iconPrefix` 是 `MetaEnum` 的属性（见下方 §6.2），串只描述**成员**。
- **老格式（3 段）永远合法** —— 不用外观注解的枚举，串与旧实现逐字一致。

> ⚠️ **兼容性硬事实（必须知道）**：旧实现按 `split(';', 3)` 解析（`MetaEnumMember.parse()`，新库 `D:\2026\java\mmda-core\mmda-core-metadata\…\MetaEnumMember.java:69`）——**第 3 段会吞掉后面所有内容**，所以老运行时读扩展串会把 `text` 读成 `新;info-500;bom-new`（**静默错标，不报错**）。
> 因此：① 扩展段**只在枚举用了外观注解时才产出**（老项目零影响）；② **同一份元数据必须与同一代内核/运行时配套**（按 4A：DB 元数据是**产物**，随内核重新生成）；③ 需要写回老格式时走 `mmda migrate --drop-enum-style`（或打包时 `mmda pack --compat 1.x`，丢弃外观、只留 3 段）。

### 6.2 元数据 JSON 形态（✔ 2026-09-25 设计）

`MetaEnum` 对外的 JSON（**字段名沿用既有列名、camelCase**；★ = 本轮新增）：

上例的 `enumString` 是**原始声明**：`CERTIFIED` 只声明了角色（`success`，省略 shade → 已解析为 `500`）、`ABANDONED` 什么都没声明（全靠回落），所以串里分别是 `success` 和空 —— 而 `members[]` 里两者都是回落后的**最终值**。

```json
{
  "enumClass": "BomStatus",
  "displayLabel": "BOM状态",
  "namespace": null,
  "dataType": "int",
  "bitwise": false,
  "enumString": "0;NEW;新;info-500;bom-new|1;DRAFTED;已起草;info-200|2;CERTIFIED;已审核;success|5;ABANDONED;已弃用",
  "colorized": true,
  "colorRole": "gray",
  "colorShade": 500,
  "iconized": true,
  "iconPrefix": "bom",
  "members": [
    { "value": 0, "name": "NEW",       "text": "新",     "colorRole": "info",    "colorShade": 500, "icon": "bom-new" },
    { "value": 1, "name": "DRAFTED",   "text": "已起草", "colorRole": "info",    "colorShade": 200, "icon": "bom-drafted" },
    { "value": 2, "name": "CERTIFIED", "text": "已审核", "colorRole": "success", "colorShade": 500, "icon": "bom-certified" },
    { "value": 5, "name": "ABANDONED", "text": "已弃用", "colorRole": "gray",    "colorShade": 500, "icon": "bom-abandoned" }
  ]
}
```

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `enumClass` / `displayLabel` / `namespace` / `dataType` / `bitwise` | 既有 | 与旧实现同义 |
| `enumString` | string | **原始声明的扩展串**（未声明处留空）—— IDE 据此知道「哪些是显式、哪些走默认」 |
| ★ `colorized` / `iconized` | bool | 开关（对应 `@Colorized` / `@Iconized`） |
| ★ `colorRole` / `colorShade` | string / int | 枚举级**默认色**（`@Colorized(role, shade?)`，无默认时为 `null`） |
| ★ `iconPrefix` | string? | `@Iconized("bom")` 的前缀；`@Iconized`（无参）为 `null` |
| ★ `members[]` | array | 每项 `{ value, name, text, colorRole, colorShade, icon }` —— **已解析回落后的最终值**；未开开关 / 无默认且未声明时为 `null` |

**三条口径**：

1. **串里颜色是一段、JSON 里拆两个字段** —— 串写 `info-500`（紧凑、可读）；JSON 给 `"colorRole": "info", "colorShade": 500`（前端按 role 查主题、按 shade 取令牌，不必再解析字符串）。
2. **`enumString` 存原始、`members[]` 存最终** —— 一处判读「显式还是默认」（IDE 属性面板要显示留空状态），一处直接拿来渲染（三端不必重算回落）。
3. **外观随 `MetaEnum` 下发一次，不进业务数据**：记录载荷里枚举字段照旧是成员名（`"status": "CERTIFIED"`）+ `customProperties.$status` 显示标签（[`guide/quickstart.md`](guide/quickstart.md) §8）—— **颜色 / 图标不逐条下发**，渲染方按值查 `MetaEnum.members` 即可。

**校验（`mmda check`）**：段内 `;` `|` = error；`colorShade` 无 `colorRole` = error；`colorRole` / `colorShade` 越界（不在 7 值 / 10 档内）= error。

---

## 7. View

基于 Record 的投影：`relatives`（join 的 Record 集合）、`colAliasMap`、`whereCondition`、`orderBy`、字段列表。
语言形态见 [records.md](records.md#7-view)。

> ⚠️ `whereCondition` / `orderBy` 在旧实现里是**裸字符串**；m 语言目标是类型化表达式（纯函数，禁 IO）。

---

## 8. Module（功能架构树）

| 属性 | 说明 |
| --- | --- |
| `moduleCode` | 层级编码，如 `M.03.001` |
| `moduleLabel` | 显示名 |
| `moduleType` | `0` Subsystem / `1` Module / `2` Feature |
| `schemaCode` | 关联 Schema |
| `recordRef` | Feature 绑定的 Record（type=2） |
| `moduleUrl` | 路由/入口 —— **API 路径的前缀 / 入口段按它派生**（✔ 2026-09-24，见 [`api.md`](api.md) §8.2-2c） |
| `allowOps` | 操作权限位掩码 |
| `defaultFilter` / `defaultSort` | 列表默认 |

### 8.1 Role（关键用户 · **与 Module 同级**）

> **✔ 已裁（2026-09-24）**：**Role 是架构设计元素，进 m 语言，地位与 Module 分解同级**（`flow/roles/*.mr`）。**组织架构 / 岗位 / 职员仍是「数据」**（普通 `Record` + 关系）——两者不在同一层：**Role 来自需求阶段识别的关键用户**（SERU 的需求过程里就要求识别关键用户，即 RUP 的 Actor），组织架构数据是它的**实例来源**。

| 属性 | 说明 |
| --- | --- |
| `roleCode` / `roleName` | 角色标识与显示名 |
| `auth module` | 可见 / 可操作的模块与 Feature（按 `moduleCode`） |
| `actions` | 该角色可执行的 Action 集合 |
| `scope` | 数据范围（本人 / 本部门 / 全部，或按组织架构字段） |

**为什么与 Module 同级**：模块分解回答「系统分成什么」，角色回答「谁在用、谁能做什么」——两者共同决定**导航**、**写入边界**与**流程节点的执行人**（见 [`architecture-review.md`](architecture-review.md) 的关注点表、[`workflows.md`](workflows.md) §1.2）。**必须在需求阶段识别关键用户**，否则会出现"系统做完了才发现漏了一类用户"。

**与「权限在 IDE 配置」的关系**：**Role 的存在与能力范围声明在语言里**（本节的 `.mr` 文件）；**谁持有哪个 Role** 才是 IDE 项目管理里配置的（[`workflows.md`](workflows.md) §1.2）。余一项待裁：**岗位 → Role 的映射规则**（一个岗位可对应多个 Role）。

---

## 9. Action（ModuleAction）

| 属性 | 说明 |
| --- | --- |
| `moduleCode` | 所属 Feature |
| `actionName` | 机器名，如 `approve` |
| `displayLabel` | 按钮标签 |
| `statusTransition` | 状态转移 DSL |
| `executableExpression` | 前置条件（守卫） |
| `incomingTokensRequired` | 流程 token 数 |
| `promptType` | 交互提示类型 |
| `description` | 说明 |

`statusTransition` DSL：`NEW=>APPROVED`、`NEW,DRAFT=>USED`、`*=>ABANDONED`、`!(FINISHED,CANCELED)=>CANCELED`、`NEW=>NEW`。

---

## 10. FlowEdge（ModuleFlow）

| 属性 | 说明 |
| --- | --- |
| `flowCode` | 流程标识 |
| `actionCode` / `nextActionCode` | 当前/后继 Action |
| `importance` / `urgency` | 优先级 |
| `sopDuration` | 标准工时（分钟） |
| `multiplicity` | 并发度 |
| `fallback` | 是否回退边 |

---

## 11. Event 与 Subscription

| 属性 | 说明 |
| --- | --- |
| `Event` | `id`、`type`、`source`、`payload`、`lifecycle` |
| `Channel` | `name`、`schema`、`transport`（memory/redis/rabbitmq…） |
| `Subscription` | `handler`、`filter`、`delivery`、`retry`、`timeout` |

声明语法见 [events.md](events.md#事件-m-语言声明phase-2)。

---

## 12. UiField（呈现层，可选）

与 Field 分离的 UI 元数据：`formatter`、`align`、`renderer`、`editor`、`placeholder`、`listSize`、`sortable` 等。
详见 [presentation.md](presentation.md)。

---

## 13. Design Change Log

| 属性 | 说明 |
| --- | --- |
| `logId` | 递增 ID |
| `timestamp` | 时间 |
| `eventType` | `RecordAdded`、`FieldRenamed` … |
| `refName` / `refKey` | 对象类型 / 对象键 |
| `difference` | JSON Patch 或自定义 diff |
| `prevLogId` | 链表 |
| `undone` | 是否已撤销 |

文件形态见 [project.md](project.md#8-变更日志-changelog)。**Design Change Log ≠ Domain Event Sourcing**。

---

## 14. 能力推断（Codegen 约定，非硬约束）

| 条件 | 推断能力 |
| --- | --- |
| 有 `status` 枚举 + `ownerID` + `partitionKey` | Flowable |
| 有 `creatorID`、`createDate`、`lastModified` | Auditable |
| 有 `ownerID`、`ownerDeptID` | Ownable |
| 有 `changeLogID` | ChangeLoggable |
| 有 `computed` 字段 | Computable |

---

## 15. 与现有实现的对应

| 元模型 | Java（`mmda-core-metadata`） | TS（`@mmda/core`） | 旧库表 |
| --- | --- | --- | --- |
| Schema | `MetaDb` | 同形对象 | `MetaDb` |
| Record | `MetaObject` | `metamodel.ts` | `MetaObject` |
| Field | `MetaCol` | — | `MetaCol` |
| Relation | `MetaRelation` | — | `MetaRelation` |
| Enum | `MetaEnum` / `MetaEnumMember` | — | `MetaEnum` |
| View | `MetaView` | — | （视图表） |
| Module / Action / Flow | `Module*` | — | `Module*` |
| 约束 | `MetaIndex`/`MetaForeignKey`/`MetaCheck` | — | 同表族 |
| UiField | `MetaUiField` / `MetaUi18n` | `src/metaui/*` | 同表族 |
| 数据类型 | `MetaDataType` | — | `MetaDataType` |

表名与列名的完整对照见 [legacy/java-factory.md](legacy/java-factory.md)。

---

## 16. 相关

- [records.md](records.md) — 语言层面的对象定义
- [project.md](project.md) — 项目与文件承载
- [legacy/java-factory.md](legacy/java-factory.md) — 旧库表映射
- `..\PLAN.md` — IR 与宿主加载的落地口径
