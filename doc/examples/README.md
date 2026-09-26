# m 语言示例（取自 mmda-mes 语料）

> **来源**：`E:\Dev\mmda-architect\examples\mmda-mes`（378 个语言文件的**语料真源**）。
> **语料即语法基线**（见 [`../errata.md`](../errata.md) §一 冲突 1/2/4/5），所以本目录**逐字照语料**，只做**两处**规范化改写：
> ① **`@PartitionID` → `@Partitioned`**（旧名已废，见 [`../records.md`](../lang/records.md) §2.3；语料里 186 处旧写法待 `mmda migrate --rename` 迁移）。
> ② **`@Ref Xxx(col,displayLabel)` → `@Ref Xxx(col,label)`**（✔ 2026-09-25 作者裁 B：「显示标签」统一 `label`；**只重构设计**——外部语料与三端老代码仍写 `displayLabel`，见 [`../errata.md`](../errata.md) §五-78 / §三-42）。
>
> 作者要求：「拿 `base.Material` 及其相关的，`mes.Bom`、`mes.DailyReport`、`mes.Process` 这几个实体，按 m 语言的语法写出来我看看」。
> ✔ **`mes.Process` = `Routing`（工艺路线）** —— 作者 2026-09-25 确认「**是Routing**」，本目录以 [`mes/Routing.mm`](mes/Routing.mm) 为准；
> 其**子项 `Operation`（工序）**由 `Routing` 用 `@Many` 挂上（`operations Operation[+] readonly,`），故一并保留。

## 1. 文件 ↔ 语料源

| 示例 | 语料源（`examples/mmda-mes/`） | 说明 |
| --- | --- | --- |
| [`base/Material.mm`](base/Material.mm) | `data/models/base/Material.mm` | 物料（113 行，字段最多的示例） |
| [`base/MaterialCat.mm`](base/MaterialCat.mm) | `data/models/base/MaterialCat.mm` | 物料类别（被 `Material` 用 `@One` 引用） |
| [`mes/Bom.mm`](mes/Bom.mm) | `data/models/mes/Bom.mm` | 物料清单（含 `@Many items BomItem[+]`、跨模块 `@Ref base.Material(...)`） |
| [`mes/BomItem.mm`](mes/BomItem.mm) | `data/models/mes/BomItem.mm` | BOM 明细 |
| [`mes/DailyReport.mm`](mes/DailyReport.mm) | `data/models/mes/DailyReport.mm` | 日报（49 行，最小的完整示例） |
| [`mes/DailyReportEvent.mm`](mes/DailyReportEvent.mm) | `data/models/mes/DailyReportEvent.mm` | 日报事件（含复合主键 `@Id PK_...(reportId, itemId)`） |
| [`mes/Routing.mm`](mes/Routing.mm) | `data/models/mes/Routing.mm` | **工艺路线 = 你说的 `Process`**（55 行；`@Many operations Operation[+]` 挂工序、`@Many operationFlows`、`@Many lines`） |
| [`mes/Operation.mm`](mes/Operation.mm) | `data/models/mes/Operation.mm` | 工序（`Routing` 的子项；含 `@ForeignKey … references Routing(routingId)`） |
| [`enums/MaterialType.me`](enums/MaterialType.me) / `CirculationSpeed.me` / `MaterialTracingMode.me` | `data/enums/base/*.me` | 枚举（`flags` 位枚举与普通枚举两种） |
| [`enums/BomStatus.me`](enums/BomStatus.me) / `BomUsage.me` / `DailyReportStatus.me` / `RoutingType.me` | `data/enums/mes/*.me` | 枚举（状态枚举值域与 STM 对齐） |
| [`stms/MaterialLifecycle.ms`](stms/MaterialLifecycle.ms) / [`BomApproval.ms`](stms/BomApproval.ms) / [`DailyReportLifecycle.ms`](stms/DailyReportLifecycle.ms) / [`RoutingLifecycle.ms`](stms/RoutingLifecycle.ms) | `data/stms/{base,mes}/*.ms` | 状态机（`stm X on Record.status` + `action` + `transition`） |

## 2. 这批示例里能看到的语法（逐条给出处）

| 语法 | 示例行 | 出处 |
| --- | --- | --- |
| 记录体：`record X { … }` + `///` 文档注释（**注释即文档**，`0;CODE;标签` 是枚举值域说明） | `record Material {` | `base/Material.mm:2` |
| **分区主键注解（带段范围）**：`@Partitioned [min,max]` 独占一行、写在字段上方 | `@Partitioned [32768,0x7fffff]` + `materialId int64 identity generated readonly hidden,` | `base/Material.mm:4-5` |
| **字段级行尾关键字**：`identity generated readonly hidden` / `indexed` / `readonly` / `unsigned` / `default 0` / `default now` / `default false` | `status UsageStatus default 0 indexed readonly,` | `base/Material.mm:75` |
| 类型与可空：`varchar(30)`、`varchar(255)?`、`decimal(18, 3)? unsigned`、`int32 unsigned`、`timestamp? default now` | `qcRatio decimal(18, 2) unsigned default 0.00,` | `base/Material.mm:56` |
| **布尔默认值**：`bool default false`（规范形态；**大小写不敏感**，`default FALSE` / `default True` 也合法；~~`b'0` / `b'1`~~ 已作废 —— MySQL 默认值语法，语料 93 处待迁移。⚠️ 作废的只是**作布尔值**的形态；`b'0110'` 仍是 `BitStr` 位串字面量） | `featuredSku bool default false,` | `base/Material.mm:58` |
| 单值注解：`@Unique` / `@Name` / `@Thumbnail` / `@State XxxLifecycle` | `@Name` + `materialName varchar(100),` | `base/Material.mm:18-19` |
| **计算列**：`@Computed <表达式>`（独占一行，载荷是表达式） | `@Computed concat_ws(' ',brand,materialName,specs,…)` | `base/Material.mm:21` |
| **一对一 + 别名**：`@One X(a,b) as alias`；**跨模块**写 `@One base.X(...)` | `@One MaterialCat(categoryId,categoryName,parentCatId) as category` | `base/Material.mm:9`、`mes/Bom.mm:24` |
| **引用**：`@Ref X(a,b)`（生成导航属性） | `@Ref User(userId,userName)` | `base/Material.mm:85` |
| **一对多集合**：`@Many` + 字段行尾 `[+]` | `@Many` / `features MaterialFeature[+] readonly,`；`operations Operation[+] readonly,`（`Routing` 挂工序） | `base/Material.mm:99-100`、`mes/Routing.mm:46-51` |
| **复合主键**：`@Id PK_xxx(col1, col2),` | `@Id PK_dailyreportevent(reportId, itemId),` | `mes/DailyReportEvent.mm:31` |
| **索引**：`@Index IDX_xxx(cols),`（组合索引必须具名声明） | `@Index IDX_bom_group(bomGroup,refBomId),` | `mes/Bom.mm:109` |
| **外键**：`@ForeignKey FK_xxx(col) references X(col),` | `@ForeignKey FK_operation_routing(routingId) references Routing(routingId),` | `mes/Operation.mm:67` |
| **文档注释规范**：`/// <label>` 或 `/// <label> : <description>`（= 元数据的**显示标签 + 描述**），**写在被注释元素上方独占一行**、**不许写行尾** | `/// 新` + `NEW = 0,` | `enums/BomStatus.me:3-4`、[`../records.md`](../lang/records.md) §1.1 / §6 |
| 枚举：`enum X : int flags { … }`（`flags` = 位枚举）+ 成员注释在**上一行** | `enum MaterialType : int flags {` / `/// 劳动技能` + `LABOR_SKILL = 0,` | `enums/MaterialType.me:2-4` |
| 状态机：`stm X on Record.status { action a { transition A,B->C, } }`（`*` = 任意状态） | `stm BomApproval on Bom.status {` | `stms/BomApproval.ms:2` |

## 3. 等价简写：字段级 `partitioned`（2026-09-25 新裁）

作者裁定 **`partitioned` 可作字段级行尾裸关键字**（不带范围 → 用元对象默认段），所以下面两种写法**等价**：

```m
/// 物料标识
@Partitioned [32768,0x7fffff]
materialId int64 identity generated readonly hidden,
```

```m
/// 物料标识: 需要用元对象默认段时，直接跟在字段后面
materialId int64 identity generated readonly hidden partitioned,
```

`BIGID` = `int64 identity partitioned`（⤴ 2026-09-26 更正，原写 `uint64`）也是同一件事的展开式（上面带 `@Partitioned [min,max]` 的那行是语料旧写法，**A2 已裁：示例集已迁 `int64`、外部语料待迁**）（见 [`../datatypes.md`](../lang/datatypes.md) §3）。

### 3.1 演示：枚举的颜色与图标（规范新增，语料里还没有）

[`../records.md`](../lang/records.md) §6.1 裁定的外观注解（2026-09-25），**语料 `.me` 文件里目前一处都没有**，这里只做演示：

```sql
/// BOM状态
@Colorized(gray, 500)      // 开颜色 + 默认色 = gray 色板 500 shade
@Iconized("bom")           // 开图标 + 默认别名前缀 = bom
enum BomStatus : int {
    /// 新
    @Color(info, 500)      // 覆盖默认色
    NEW = 0,
    /// 已审核
    @Color(success, 500)
    CERTIFIED = 2,
    /// 已弃用
    /// （颜色取默认 `gray-500`，图标取默认别名 `bom-abandoned`）
    ABANDONED = -1,
}
```

**作者手写样例**见 [`enums/BomUsage.me`](enums/BomUsage.me)（2026-09-25 作者改）：`@Iconized("bom")` 开图标并给前缀 —— **不写** `@Icon` 时默认得到 `bom-design`；**写了** `@Icon("design")` 就是 `design`（`@Icon` 写**完整别名**、不叠前缀）。

要点：**开关 + 默认值在枚举声明**（`@Colorized(role, shade?)` / `@Iconized` 或 `@Iconized("prefix")`）、**取值在成员**（`@Color(role, shade?)` / `@Icon("alias")`）；颜色是**语义角色 + 色板 shade（色阶）**（封闭 10 档 `50`–`900`，省略 = `500`；色值来自主题，`gray` 默认支持黑白灰）、图标是**逻辑别名**（完整别名、三端各自映射）；**成员缺值先回落默认值**，没默认才不渲染。

## 4. 写示例时顺手查出来的四件事

1. **`Material` 显式写了段 `[32768,0x7fffff]`**（与 `Employee` 同值；其余 **169** 张表用默认 `[10000,0x000F_FFFF]`）—— ⚠️ **这本身不构成冲突**：realId 是**每张表自己的 identity 序**（`identity generated`），**物料 1 与职员 1 各归各、跨表重复完全正常**；段（`minId` / `maxId`）只在**要 UNION 成一个视图的那组表之间**才有语义，硬门禁也只查**同组**（见 [`../records.md`](../lang/records.md) §2.3 / §7、`errata` §五-52）。
   **中性观察**：不在任何组里的表写不写范围、写了是否起作用，规范暂未硬性规定（可考虑建议：不在组里就统一用默认段或字段级行尾 `partitioned`）。
2. **段范围写法有 12 种** → **✔ 2026-09-25 作者已裁：不是语法问题** —— **区间是数学区间表达式**（`[a,b]` / `(a,b)` / 半开半闭）+ **C# 风格 `..` 区间运算符**（`a..b` / `..b` / `a..`，**不是「省略式」**）；**端点是数值字面量**（十 / `0x` / `0b`、`_` 分组、大小写不敏感；**八进制已撤**），词法层产出**数值**、**按值比较** → **没有「hex 位数 / 大小写规范化」这回事**；只有「某些表的段值本身与同组表错位」才是数据问题，归**同组不重叠**硬门禁（见 [`../errata.md`](../errata.md) §二-14）。
3. **`b'0` / `b'1`（85 + 8 处）是逆向工程期的偏移 → 现已作废**（✔ 2026-09-26 作者：「`b'0` / `b'1` 是 MySQL 的默认值语法，**不要**」）—— ⚠️ 作废范围 = **「作布尔值」与「不带引号」的形态**；**`b'0110'` 作为 `BitStr` 的位串字面量仍合法**（✔ 2026-09-26 二次裁定，见 [`../datatypes.md`](../lang/datatypes.md) §7）。**规范形态 = `true` / `false`（大小写不敏感；或 `1` / `0`）**，与早期文档 `archive/2026-06/language/types.md:14` 一致。**示例集 5 个文件 9 处已改**，语料 93 处待迁移（见 [`../guide/records.md`](../lang/records.md) §13）。
4. **语料枚举成员注释全是行尾写法**（本示例集 7 个 `.me` 就有 **33 处**）—— 与作者 2026-09-25 裁定的「**注释写在成员上方**」不一致，属**语料待迁移**（可比照 `@PartitionID` → `@Partitioned` 的 `mmda migrate --rename` 机制）；本示例集**已按规范改成上一行**。

## 5. 相关

- [`../records.md`](../lang/records.md) — 记录 / 视图 / 约束的规范正文
- [`../datatypes.md`](../lang/datatypes.md) — 类型与 `BIGID` 位布局
- [`../statements.md`](../lang/statements.md) — 行为与状态机
- [`../ide/diagrams.md`](../ide/diagrams.md) §10 — 这些实体还能导成 Mermaid / PlantUML 图并嵌进 md
