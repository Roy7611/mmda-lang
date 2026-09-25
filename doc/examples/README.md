# m 语言示例（取自 mmda-mes 语料）

> **来源**：`E:\Dev\mmda-architect\examples\mmda-mes`（378 个语言文件的**语料真源**）。
> **语料即语法基线**（见 [`../errata.md`](../errata.md) §一 冲突 1/2/4/5），所以本目录**逐字照语料**，只做**一处**规范化改写：
> **`@PartitionID` → `@Partitioned`**（旧名已废，见 [`../records.md`](../records.md) §2.3；语料里 186 处旧写法待 `mmda migrate --rename` 迁移）。
>
> 作者要求：「拿 `base.Material` 及其相关的，`mes.Bom`、`mes.DailyReport`、`mes.Process` 这几个实体，按 m 语言的语法写出来我看看」。
> ⚠️ **`mes.Process` 在语料里没有同名实体**，最贴近的是 **`Operation`（工序）**（`opId` / `opCode` / `opName` / 工序组合类型 / 标准工时 / 所需资源 …），本目录按 `Operation` 出；若你指的是 `Routing`（工艺路线）或别的，说一声我换。

## 1. 文件 ↔ 语料源

| 示例 | 语料源（`examples/mmda-mes/`） | 说明 |
| --- | --- | --- |
| [`base/Material.mm`](base/Material.mm) | `data/models/base/Material.mm` | 物料（113 行，字段最多的示例） |
| [`base/MaterialCat.mm`](base/MaterialCat.mm) | `data/models/base/MaterialCat.mm` | 物料类别（被 `Material` 用 `@One` 引用） |
| [`mes/Bom.mm`](mes/Bom.mm) | `data/models/mes/Bom.mm` | 物料清单（含 `@Many items BomItem[+]`、跨模块 `@Ref base.Material(...)`） |
| [`mes/BomItem.mm`](mes/BomItem.mm) | `data/models/mes/BomItem.mm` | BOM 明细 |
| [`mes/DailyReport.mm`](mes/DailyReport.mm) | `data/models/mes/DailyReport.mm` | 日报（49 行，最小的完整示例） |
| [`mes/DailyReportEvent.mm`](mes/DailyReportEvent.mm) | `data/models/mes/DailyReportEvent.mm` | 日报事件（含复合主键 `@Id PK_...(reportId, itemId)`） |
| [`mes/Operation.mm`](mes/Operation.mm) | `data/models/mes/Operation.mm` | **工序 = 你说的 `Process`**（含 `@ForeignKey … references …`） |
| [`enums/MaterialType.me`](enums/MaterialType.me) / `CirculationSpeed.me` / `MaterialTracingMode.me` | `data/enums/base/*.me` | 枚举（`flags` 位枚举与普通枚举两种） |
| [`enums/BomStatus.me`](enums/BomStatus.me) / `BomUsage.me` / `DailyReportStatus.me` | `data/enums/mes/*.me` | 枚举（状态枚举值域与 STM 对齐） |
| [`stms/MaterialLifecycle.ms`](stms/MaterialLifecycle.ms) / [`BomApproval.ms`](stms/BomApproval.ms) / [`DailyReportLifecycle.ms`](stms/DailyReportLifecycle.ms) | `data/stms/{base,mes}/*.ms` | 状态机（`stm X on Record.status` + `action` + `transition`） |

## 2. 这批示例里能看到的语法（逐条给出处）

| 语法 | 示例行 | 出处 |
| --- | --- | --- |
| 记录体：`record X { … }` + `///` 文档注释（**注释即文档**，`0;CODE;标签` 是枚举值域说明） | `record Material {` | `base/Material.mm:2` |
| **分区主键注解（带段范围）**：`@Partitioned [min,max]` 独占一行、写在字段上方 | `@Partitioned [32768,0x7fffff]` + `materialId uint64 identity generated readonly hidden,` | `base/Material.mm:4-5` |
| **字段级行尾关键字**：`identity generated readonly hidden` / `indexed` / `readonly` / `unsigned` / `default 0` / `default now` / `default b'0` | `status UsageStatus default 0 indexed readonly,` | `base/Material.mm:75` |
| 类型与可空：`varchar(30)`、`varchar(255)?`、`decimal(18, 3)? unsigned`、`int32 unsigned`、`timestamp? default now` | `qcRatio decimal(18, 2) unsigned default 0.00,` | `base/Material.mm:56` |
| **位字面量**：`bool default b'0`（`b'0` / `b'1`，语料 85 + 8 处） | `featuredSku bool default b'0,` | `base/Material.mm:58` |
| 单值注解：`@Unique` / `@Name` / `@Thumbnail` / `@State XxxLifecycle` | `@Name` + `materialName varchar(100),` | `base/Material.mm:18-19` |
| **计算列**：`@Computed <表达式>`（独占一行，载荷是表达式） | `@Computed concat_ws(' ',brand,materialName,specs,…)` | `base/Material.mm:21` |
| **一对一 + 别名**：`@One X(a,b) as alias`；**跨模块**写 `@One base.X(...)` | `@One MaterialCat(categoryId,categoryName,parentCatId) as category` | `base/Material.mm:9`、`mes/Bom.mm:24` |
| **引用**：`@Ref X(a,b)`（生成导航属性） | `@Ref User(userId,userName)` | `base/Material.mm:85` |
| **一对多集合**：`@Many` + 字段行尾 `[+]` | `@Many` / `features MaterialFeature[+] readonly,` | `base/Material.mm:99-100` |
| **复合主键**：`@Id PK_xxx(col1, col2),` | `@Id PK_dailyreportevent(reportId, itemId),` | `mes/DailyReportEvent.mm:31` |
| **索引**：`@Index IDX_xxx(cols),`（组合索引必须具名声明） | `@Index IDX_bom_group(bomGroup,refBomId),` | `mes/Bom.mm:109` |
| **外键**：`@ForeignKey FK_xxx(col) references X(col),` | `@ForeignKey FK_operation_routing(routingId) references Routing(routingId),` | `mes/Operation.mm:67` |
| 枚举：`enum X : int flags { A = 0, /// 文档 }`（`flags` = 位枚举） | `enum MaterialType : int flags {` | `enums/MaterialType.me:2` |
| 状态机：`stm X on Record.status { action a { transition A,B->C, } }`（`*` = 任意状态） | `stm BomApproval on Bom.status {` | `stms/BomApproval.ms:2` |

## 3. 等价简写：字段级 `partitioned`（2026-09-25 新裁）

作者裁定 **`partitioned` 可作字段级行尾裸关键字**（不带范围 → 用元对象默认段），所以下面两种写法**等价**：

```m
/// 物料标识
@Partitioned [32768,0x7fffff]
materialId uint64 identity generated readonly hidden,
```

```m
/// 物料标识: 需要用元对象默认段时，直接跟在字段后面
materialId uint64 identity generated readonly hidden partitioned,
```

`BIGID` = `uint64 identity partitioned` 也是同一件事的展开式（见 [`../datatypes.md`](../datatypes.md) §5）。

## 4. 写示例时顺手查出来的三件事

1. **`Material` 与 `Employee` 共用同一个段 `[32768,0x7fffff]`** —— 语料里只有这两张表用这个段（其余 **169** 张用默认 `[10000,0x000F_FFFF]`）。要么它们确实属于**同一个标识共享组**，要么是**笔误**。按 §五-52 的**段重叠硬门禁**（同组之外的段两两不得重叠、重叠 = error），**建议核对**。
2. **段范围写法不统一**：语料里同时出现 `[10000,0x000F_FFFF]`、`[32768,0x7fffff]`、`[..0x7ffffff]`、`[0x80000000..]`（`..` 省略式）、`[0x8000000,0x7fffffff]`（hex 与 `0x800000` 位数不一致）→ **语法待裁**：段范围是否允许 `..` 省略式、hex 是否规范化（大小写/位数）。
3. **位字面量 `b'0` / `b'1` 确实在用**（85 + 8 处）—— 台账里早前写的「`b[01]{4,}` 0 命中」是**我的检索模式写错**（真实形态是 `b'0`），已在 [`../errata.md`](../errata.md) §二-5 回正。

## 5. 相关

- [`../records.md`](../records.md) — 记录 / 视图 / 约束的规范正文
- [`../datatypes.md`](../datatypes.md) — 类型与 `BIGID` 位布局
- [`../statements.md`](../statements.md) — 行为与状态机
- [`../ide/diagrams.md`](../ide/diagrams.md) §10 — 这些实体还能导成 Mermaid / PlantUML 图并嵌进 md
