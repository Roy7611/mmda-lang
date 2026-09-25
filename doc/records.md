# 对象：Record、Field、Enum、View

> ✔ **语法形态已统一（2026-09-25，取语料形态）**：**以 `@` 注解制为基线** —— `@Ref Country(countryCode,fullName)`、`@One` / `@Many`、`@Computed`、`@Index`、`@Id`、`@State`；行为住**独立 `.ms`**（不内联进 record）。早期文档的 `ref X as y` / `indexed` / `unique` / `computed` / `@Action` 内联写法**标为历史、不进解析器**（见 [`errata.md`](errata.md) 冲突 1 与冲突 4，实测：381 文件里 `ref ` 与 `computed` **零命中**、`@Ref` 90 / `@Index` 117 / `@Id` 82）。
> 本文以「对象是什么、有哪些元素、各自什么语义」为主，示例优先给**实际语料形态**（381 个文件在用），早期文档形态在对照处标注。

---

## 1. 字段（Field）

### 1.1 语法

```sql
[注解行…]
名称 数据类型 [可空?] [限制关键字…] ,
```

- **注解行**（可选）：字段名上方一行或多行 `@Xxx`，见 [§3](#3-字段注解)。
- **名称**：字段名（camelCase；**命名总口径见 [`naming.md`](naming.md) §1**）。
- **数据类型**：见 [datatypes.md](datatypes.md)；后缀 `?` 表示可空（未写 `default` 时默认 `null`）。
- **限制关键字**：零个或多个，空格分隔；行末逗号 `,`。
- **文档注释**（`///`，可选）：写在被注释元素**上方、独占一行**（若该元素还有注解行，`///` 在注解行之上），格式 **`/// <label>`** 或 **`/// <label> : <description>`** —— 对应元数据的 **显示标签（`displayLabel`）** 与 **描述（`description`）**；三端 UI 标签、API 文档、生成的 Markdown 文档都从这里取。**注释一律写在被注释元素上方，不许写行尾。**

```sql
userId   uint64 identity generated readonly,
userName varchar(30) charset ascii,
createdAt timestamp? default now,
mobile   char(11) indexed,
orderDate date default now indexed future,
quantity decimal(18,3) positive,
```

### 1.2 限制关键字

> ✔ **约束关键字一律大小写不敏感**（`indexed` = `INDEXED`、`unique` = `UNIQUE`、`identity` = `IDENTITY`）——**与 SQL 一致**（✔ 2026-09-25 作者裁，见 [`datatypes.md`](datatypes.md) §2.1）。

| 关键字 | 含义 |
| --- | --- |
| `indexed` | 建索引 |
| `unique` | 唯一索引（隐含 `indexed`） |
| `identity` | 唯一标识；等价 `indexed` + `unique`；默认配 `readonly` |
| `partitioned` | **分区主键**（✔ 2026-09-25 新增，字段级）：与 `@Partitioned` 注解**同一件事**的两种形态 —— 行尾简写不带范围（用元对象的默认段）；`BIGID` = `uint64 identity partitioned` 就展开成它。**一个对象只能有一个 `partitioned` 字段** |
| `generated` | 生成列（DB 自增、或由 `@Computed` 公式映射） |
| `default` *value* | 默认值；`now` = 当前时间；位串可写 `b'0` |
| `charset` *name* | 字符编码：`ascii`、`utf` 等 |
| `unsigned` | 无符号数值 |
| `positive` / `negative` | 必须 > 0 / < 0（`positive` = `gt(0)`） |
| `future` / `past` | 日期时间：>= now / <= now |
| `readonly` | 用户不可改；`@Computed`、`generated` 恒只读 |
| `hidden` | UI 默认隐藏；外键为 `hidden` 时其 `@One` 导航默认 **lazy** |
| `writeonly` | 仅写（少见） |

> ✔ **已裁（2026-09-25）：约束按层级分两种形态**（作者原话：「**你还要区分字段级和表级约束**」「**字段级约束，直接在字段后面跟着，`indexed`、`unique` 什么的，简洁**」「**如果是两个字段建立一个索引，那就得单独定义了**」）：
>
> | 层级 | 形态 | 例子 |
> | --- | --- | --- |
> | **字段级** | **跟在字段行尾的裸关键字**（简洁、不占行） | `mobile char(11) indexed,`、`orderDate date default now indexed future,`、`addressId uint64 identity generated readonly,` |
> | **对象级 / 组合** | **写在 record 体末尾、单独具名声明**——**两个及以上字段建一个索引必须走这条** | `@Index IDX_changelog_key(refName,refKey)`、`@Index IDX_flowtrails(objName,objId,actTime)`、`@ForeignKey FK_…(…) ref …` |
>
> **实测（语料 378 个语言文件）**：行尾字段级约束 **`readonly` 1040 处 / `indexed` 491 处**；具名声明 **342 处**，其中 **2 列及以上 45 处**（2 列 32、3 列 12、4 列 1 —— 最长 `IDX_tool_asequip(asEquip,maintenancePlanId,planToMaintain,lastMaintained)`）。
> ✔ **已裁（2026-09-25 作者）**：**未定义的名字就是错，必须报错** —— 作者原话：「**posittive 写错了肯定要报错，语法都不对，你咋能过。你没有词法分析器吗？**」
>
> - **行尾关键字表 + 注解名表都是「语言关键字」，进词法分析器的 token 表**（`indexed` / `unique` / `identity` / `generated` / `readonly` / `default` / `charset` / `future` / `cancellable`… 与 `@Index` / `@Unique` / `@Id` / `@Ref` / `@One` / `@Many` / `@Computed` / `@Partitioned` / `@State` / `@Name` / `@Thumbnail`…）；
> - **拼错 / 未知名 → 解析期报错（error）**，报在 `<file>:<line>:<col>`（例：`quantity decimal(18,3) posittive` → `error: 未知约束关键字 posittive`）；
> - **因此不要「自定义约束名的扩展白名单」** —— 先前提的 `Profile` / `customProperties` 两种白名单方案 **作废**（没有「自定义关键字」这回事）；
> - **解析器位置**：`mmda-syntax`（**P2**：按内容首关键字判 partType、诊断带 `file:line:col`）—— **仓里目前还没有解析器实现，所以现阶段没有任何东西能拦住拼错**；这不是设计上的灰区，是 **P2 未开工**。
>
> **扩展名的白名单机制**（Profile 还是 `customProperties`）~~ → **作废**：关键字表封闭，没有「自定义约束名」这回事（见上）。另 §二-9 的「命名约束 vs 约束表达式 `#ge(0)`」仍待裁。

### 1.3 集合字段（`@Many`）

```sql
@Many
items OrderItem[+] readonly,
```

| 写法 | 基数 |
| --- | --- |
| `OrderItem[]` | 0~n（默认） |
| `OrderItem[*]` | 0~n（显式） |
| `OrderItem[+]` | 1~n |

`readonly` 表示子表对用户只读。

---

## 2. 字段注解总表

| 注解 | 语义 | 存储映射（元模型） |
| --- | --- | --- |
| `@One Entity as alias` | 一对一**导航**实体；按目标主键引用，显示遵循目标 `@Name`/`@Thumbnail` | Relation（`HAS_ONE`）/ 兼容 `enumSet: HAS_ONE … AS alias` |
| `@One Entity(cols…) as alias` | 显式指定主键 + 显示列 | 同上 |
| `@Ref Entity(cols…)` | 外键 + 显示列，**不**生成导航实体 | Relation；兼容 `REF …(cols…)` |
| `@Many` | 一对多；（可 `@Many eager`） | MetaRelation（默认 lazy） |
| `@State StmName` | 状态字段，下一行须为枚举；`default` 为初始状态 | 状态列 + STM 名 |
| `@Computed expr` | 计算字段；下一行为存储/展示类型 | `computed` + `formula` |
| `@Partitioned range` | 分区主键 realId 范围（多租户） | `partitionKey` + `minID`/`maxID` |
| `@Unique` | 分区内业务唯一编码（**非** DB unique index） | 列级 `uniqueKey` |
| `@Name` | 默认显示名（可多个） | `nameCol` |
| `@Thumbnail` | 列表缩略图 URL（唯一） | `thumbnailCol` |

### 2.1 加载策略（注解行尾）

| 注解 | 默认 |
| --- | --- |
| `@One` | eager（外键 `hidden` → lazy） |
| `@Many` | lazy |
| `@Ref` | eager |
| 显式 | 注解行尾加 `eager` / `lazy` |

### 2.2 `@Ref` 与 `@One` 的区别

| | `@Ref` | `@One` |
| --- | --- | --- |
| 语义 | 外键 + 显示用值对象 | 一对一导航实体（整实体） |
| 导航属性 | 无 | 有（如 `Order.customer`） |
| 列含义 | 主键 + 显示列 | 主键 + 默认显示列（可省） |
| 典型 UI | dropdown | searchBox |
| API 序列化 | ID + 显示标签 | 嵌套对象 |

### 2.3 `@Partitioned` 范围语法

`[min,max]`、`(min,max]`、`[..max]`、`[min..]`、`(0..]`；`[`/`(` 与 `]`/`)` 表示开闭；省略端点 = 该数据类型的默认最小/最大值。

多租户：**完整 ID（`BIGID`）= 高 28 位 tenantId + 低 36 位 realId**（✔ 2026-09-25 按作者给的常量与底座源码改正 —— **原写「高 16 位 / 低 48 位」是旧布局残留，已废**）：

```
MAX_TENANT_ID = 0x7FF_FFFF   // 高 28 位是租户 id（bit 63 恒 0）
MAX_REAL_ID   = 0xF_FFFF_FFFF // 低 36 位是实际 id
parseTenantID(id) = id >>> 36
```

**租户位 = 27 位有效**（`MAX_TENANT_ID = 0x7FF_FFFF`，bit 63 保留恒 0；✔ 作者 2026-09-25 确认「27位没错」）。`minID` / `maxID` 约束的是**低位 realId 的范围**（与租户位无关）——而且**是按对象领的区间**：语料统一写 `@Partitioned [10000,0x000F_FFFF]` + `addressId uint64 identity generated readonly,`，即「每个对象在 realId 空间里的一段」。`NO_TENANT_ID = 0`（平台公共数据）、`MIN_TENANT_ID = 1`。真源：`D:\2026\java` 的 `Tenancy.java:15-19 / 42-44 / 85-103`（`buildEntityID` / `getRealID` / `getMinID` / `getMaxID` / `isSameTenant`）；**组合主键的第一段是 partitionId**（`"partitionId.xxx"`，`parseTenantID(String)` 按 `.` 切分）。明细见 [`datatypes.md`](datatypes.md) §5。

**为什么分段：标识共享（Identity Sharing，✔ 2026-09-25 作者说明）** —— 作者原话：「**有时候我需要多个表 UNION 成视图，不想 id 冲突，所以分段**」。

- **目的**：一组**要 UNION 成一个视图**的表（如「人」= Tenant / Bank Account / Department / Employee / Partner / Contactor），各自在 realId 空间里领**互不重叠的一段** → UNION 之后**主键天然不冲突**，视图不需要额外加「来自哪张基础表」的标记列或前缀。
- **两级划分**：**租户位（高 28 位）决定「谁的」、段（`minID` / `maxID`）决定「哪个表的」**；两者合成才是完整的 `partitionId` 空间（`Tenancy.getMinEntityID` / `getMaxEntityID`）。
- **不做 UNION 的表可以共用默认段**：语料实测 **169 张表共用 `[10000, 0x000F_FFFF]`**；只有**标识共享组**内的表才显式细分。
- **语料实测与作者《标识共享》文档逐段吻合**：

| 标识共享组（视图族） | 表 | 段（作者文档） | 语料（旧名 `@PartitionID`） |
| --- | --- | --- | --- |
| 人 | Tenant / Bank Account | `0` – `0x7FF`（2047） | 语料未见（其余段逐一吻合） |
| 人 | Department 部门 | `0x800`（2048）– `0x7FFF`（32767） | `[2048, 32767]` ✔ |
| 人 | Employee 职员 | `0x8000`（32768）– `0x7F_FFFF`（8388607） | `[32768, 0x7fffff]` ✔ |
| 人 | Partner 贸易伙伴 | `0x80_0000` – `0x7FFF_FFFF` | `[0x800000, 0x7fffffff]` ✔ |
| 人 | Contactor 联系人 | `0x8000_0000` – `0xFFFF_FFFF` | `[0x80000000, 0xffffffff]` ✔ |
| 地 | Warehouse 仓库 | `0` – `0x7FF` | 语料未见 |
| 地 | ProductionLoc 生产地点 | — | `[0x10000, 0x1ffff]` |
| 地 | Project 项目现场 | — | `[0x800000, 0xffffffff]` |
| 物料 | Material 物料 / Sku | — | `[32768, 0x7fffff]` / `[0x800000, 0x7fffffff]` |
| 工装器具 | Equipment · Workstation / Tool | — | `[0x20000, 0x7ffff]` / `[0x80000, 0x7fffff]` |

- **作者文档里的六个标识共享组**：① **收付款方 Party**（贸易伙伴 / 联系人 / 分支机构 / 职员）+ **组织单元 Organization Unit**（Department / Partner）+ **人 Person**（Employee / Driver / Worker）；② **库存地点 Inventory Location**（Warehouse / Production Loc / Project）+ **运输地点 Transport Location**（仓库 / 工厂 / 交通站点 / 项目现场）；③ **工装器具**（物流搬运设备 Handling Equipment / 生产设备 Equipment / 工具 Tool / 运输车辆 Transport Vehicle）；④ **物料 Sku**（MaterialINSku = 物料 + Sku）；⑤ **可搬运物 Handlable**（穿梭车 / 搬运单元 Handling Unit 托盘·料箱 / 货柜 LicensePlate）；⑥ **生产计划任务 ProductionScheduleTask**（生产订单 ProductionOrder / 生产任务 ProductionTask）。
- **✔ 注解改名（2026-09-25 作者）**：**`@PartitionID` → `@Partitioned`**（作者原话：「**`@PartitionID` 改为 `@Partitioned`，字段级支持 `partitioned` 跟在后面**」）。

- **为什么改**：元对象上的属性**本来就叫 `partitioned`**（`MetaObject.partitioned`，DB 列也是 `partitioned`），注解跟属性同名 —— 一个概念只留一个名字；
- **两种形态**（同一件事）：**① 字段级行尾裸关键字 `partitioned`**（不带范围，简洁，与 `readonly` / `indexed` 同一风格）：`addressId uint64 identity generated readonly partitioned,`；**② 注解 `@Partitioned [min, max]`**（**带段范围**时用这个，独占一行在字段上方）；
- **旧名 `@PartitionID` 已废**：语料里 **186 处仍是旧写法**，属**待迁移**；m 语言解析器只认 `@Partitioned`（旧名 = 未知名 ✅ 按 §1.2 的封闭关键字表直接报错，提示改名）；
- **✔ 一次性迁移（2026-09-25 作者同意）**：**`mmda migrate --rename @PartitionID=@Partitioned`** —— 默认 **`--dry-run`**（只出「文件:行:列 + 改动」清单），**`--write`** 才落盘；**只动语言文件**（`.mm` / `.me` / `.ms` / `.mi` / `.mmda` …），不碰生成区与 KEEP 区；与 [`naming.md`](naming.md) §5 的命名迁移脚本**同一条线**，一并归 **P9**；
- **唯一性校验**：**一个对象只能有一个 `partitioned` 字段**（分区主键唯一）→ `mmda check` **error**。

**分段配置的归属（✔ 2026-09-25 作者）**：**分段在 `MetaObject` 上配置**（`minId` / `maxId`），**值是「真实 id」（realId）的范围——去掉租户标识之后的那部分**；字段上一行写的 `@Partitioned [min,max]` 是它在语言侧的声明形态，最终落到元对象的 `partitionKey` + `minID` / `maxID`（**范围写法**：闭区间 `[min,max]`、开区间 `(min,max)`、半开半闭、`..` 省略一侧如 `(0..]` / `[..max]` —— 完整表见 [`design-notes.md`](design-notes.md) §实体语义字段）。**类型侧**：`BIGID` = **`uint64 identity partitioned`**（见 [`datatypes.md`](datatypes.md) §5）。

**✔ 已裁（2026-09-25 作者）**：**段是架构师 / 设计师分配**（作者原话：「**段是架构师、设计师分配阿**」）—— **由人分配，工具不自动分配**；跨表 / 视图族的段规划属架构师，单表在既定段内落地属设计师（[`workflows.md`](workflows.md) §1）。

**✔ 已裁（2026-09-25 作者）**：**标识共享组放在视图声明处 —— 视图即组**（「**标识共享组在视图那里可否**」→ 可以，且语料已如此：`view person` / `view organizationunit` / `view materialnsku` / `view Maintainable`）—— 详见 §7。

**✔ 全部已裁（2026-09-25）**：**段重叠进 `mmda check` 硬门禁**（作者原话：「**同意进**」）—— 视图侧三条（列逐字段显式写 + `as` 对齐 / 基可以是视图 / 视图段可选）见 §7。**标识共享这块至此无待裁。**

---

## 3. 对象级约束

写在 record 体**末尾**（字段定义之后）—— **字段级约束不在这里重复；多字段建立的索引 / 唯一的键 / 外键 / 检查必须在此单独具名声明**（✔ 2026-09-25）：

```sql
@Id PK_orderitem(orderId, itemId),
@Index IDX_OrderItem_mat(materialId, unit),
@Index IDX_OrderItem_mat(orderId, materialId) unique,
@ForeignKey FK_orderitem_order(orderId) ref Order(orderId) on update cascade on delete set null,
@Check CHK_gift_check(gift switch{ 1 -> price == 0, _ -> price > 0}),
```

| 注解 | 说明 |
| --- | --- |
| `@Id (cols…)` / `@Id PK_tablename(cols…)` | 组合主键；单字段主键用 `identity` |
| `@Index IDX_…(cols…)` | 命名索引；后缀 `unique` = 唯一索引（落库） |
| `@ForeignKey FK_…(cols) ref Entity(cols)` | 外键；解析兼容 `references`；可选 `on update` / `on delete` |
| `@Check CHK_…(expr)` | 检查约束 |

**多列外键**：单列外键由子表 `@One`/`@Ref` 表达；多列用对象级 `@ForeignKey`，本地列与引用列一一对应：

```sql
record WarehouseLoc {
    @Ref Warehouse(whId, whName)
    whId long,
    locCode varchar(6),
    @Id PK_warehouseloc(whId, locCode),
}

record Pallet {
    palletId uint64 identity,
    whId? long,
    locCode varchar?(6),
    @ForeignKey FK_Pallet_WarehouseLoc(whId, locCode) ref WarehouseLoc(whId, locCode)
        on update cascade on delete set null,
}
```

**命名前缀约定**（逆向自 `information_schema`）：`PK_`、`FK_`、`IDX_`、`CHK_`、`PROC_`、`FUN_`、`TRG_`。

---

## 4. 完整示例：Order

```sql
/// 订单
record Order : IAuthorizable {
    orderId uint64 identity generated,

    orderDate date default now indexed future,

    orderNo varchar(15) charset ascii unique,

    /// 客户：下单的客户
    @One Partner(partnerId, partnerCode, partnerName) as customer
    customerId uint64 indexed,

    /// 订单状态
    @State OrderStatusChanged
    status OrderStatus default 0 indexed,

    /// 订单行
    @Many
    items OrderItem[+] readonly,

    /// 订单金额
    @Computed sum(amount of each items)
    totalAmount decimal?(19,4) unsigned,

    payedAmount decimal?(19,4) unsigned,

    paymentNo varchar?(64),

    /// 创建人
    @Ref User(userId,userName)
    creatorId uint64 readonly,

    createdAt timestamp default now readonly,
}
```

> ⚠️ `sum(amount of each items)` 是自然语言式聚合，词法边界待定（`errata.md` 二-10）。

---

## 5. OrderItem 示例（含对象级约束）

```sql
/// 订单行
record OrderItem {
    @One Order
    orderId uint64 hidden,

    itemId uint32,

    @One Material(materialId,materialCode,materialName) as material
    materialId uint64 indexed,

    gift bool default false,
    quantity decimal(18,3) positive,
    unit varchar(10),
    price decimal(18,4) unsigned,

    @Computed quantity*price
    amount decimal(19,4),

    @Id PK_orderitem(orderId, itemId),
    @Index IDX_OrderItem_mat(materialId, unit),
    @Index IDX_OrderItem_mat(orderId, materialId) unique,
    @Check CHK_gift_check(gift switch{ 1 -> price == 0, _ -> price > 0}),
}
```

---

## 6. Enum

> **枚举开发指南见 [`guide/enums.md`](guide/enums.md)**（模板 / 命名 / 注释 / 外观 / 自检 / 迁移 / 三端落地）。

```sql
/// 订单状态
enum OrderStatus : int {
    /// 新
    NEW = 0,
    /// 已付款
    PAYED = 1,
    /// 已取消
    CANCELED = 4,
}
```

位标志枚举：

```sql
/// 伙伴角色
enum PartnerRole : BitSet {
    /// 未知
    UNKNOWN  = b0000,
    /// 客户
    CUSTOMER = b0001,
    /// 供应商
    SUPPLIER = b0010,
    /// 承运商
    CARRIER  = b1000,
}
```

- 文本存储格式：`0;NEW;新|1;PAYED;已付款`（`@State` 的初始状态取第一个/`default` 指定项）。
- 枚举成员值可负（语料 `ABANDONED = -1`）。
- **成员文档注释（✔ 2026-09-25 作者裁定）**：同 §1.1 —— 格式 `/// <label>` 或 `/// <label> : <description>`（= 元数据的**显示标签**与**描述**，映射到 `MetaEnumMember`，见 [meta-model.md](meta-model.md) §6），**写在成员上方、独占一行**；**不许写行尾**（`NEW = 0,  /// 新` 不合规范；语料 `.me` 里的行尾写法待迁移）。

> ⚠️ **待裁决**：`b0000` 位字面量与 BitSet 底层宽度（定宽？加成员是否变更存储宽度），见 `errata.md` 二-5。

### 6.1 呈现注解：颜色与图标（✔ 2026-09-25 作者）

> **开发指引（怎么一步步写）见 [`guide/enums.md`](guide/enums.md)**；本节是规范条文。

**枚举声明上**（开关 + 默认值）：

| 注解 | 形态 | 含义 |
| --- | --- | --- |
| `@Colorized` | 无参 | **开颜色**（成员各自写 `@Color(role, shade?)`） |
| `@Colorized(role, shade?)` | 带默认色 | **开颜色 + 默认色**：成员没写 `@Color` 时用这个（`@Colorized(primary, 200)` = `primary` 色板的 **200 shade**） |
| `@Iconized` | **无参、不写括号** | **开图标 + 默认别名取成员名**（`DESIGN` → `design`，kebab-case；成员没写 `@Icon` 时用） |
| `@Iconized("<prefix>")` | 字符串 | **开图标 + 默认别名 = `<prefix>-<成员名 kebab>`**（如 `@Iconized("bom")` + `DESIGN` → `bom-design`） |

**成员上**（取值 / 覆盖）：

| 注解 | 取值 | 含义 |
| --- | --- | --- |
| `@Color(role, shade?)` | `role` = `primary` \| `secondary` \| `info` \| `success` \| `warning` \| `danger` \| **`gray`**；`shade` = **色板 shade（色阶）**（**封闭 10 档**：`50` / `100` / `200` / `300` / `400` / `500` / `600` / `700` / `800` / `900`） | 该成员的**主题色**（角色 + shade）；**省略 shade = `500`**（基准档） |
| `@Icon("alias")` | 图标**别名**字符串，如 `"cancel"` —— **完整别名** | 该成员要显示的图标；**显式写的就是最终别名，不再叠加 `@Iconized` 的前缀**；别名**不绑定具体图标库**，由各端主题映射 |

- **`gray` 是默认支持的角色**（第 7 个）—— 用于**黑白灰**（从 `gray-50` 到 `gray-900` 覆盖近白到近黑），不需要在主题里另配。

```sql
/// BOM状态
@Colorized(gray, 500)
@Iconized("bom")
enum BomStatus : int {
    /// 新
    @Color(info, 500)
    NEW = 0,
    /// 已起草 : 保存但未提交审核
    @Color(info, 200)
    DRAFTED = 1,
    /// 已审核
    @Color(success, 500)
    CERTIFIED = 2,
    /// 已批准
    @Color(success, 700)
    APPROVED = 4,
    /// 变更中
    @Color(warning, 500)
    REVISING = 5,
    /// 已弃用
    /// （颜色取枚举默认色 `gray-500`，图标取默认别名 `bom-abandoned`）
    ABANDONED = -1,
}
```

**作者手写样例**（[`examples/enums/BomUsage.me`](examples/enums/BomUsage.me)，2026-09-25）：`@Iconized("bom")` 开图标并给前缀 —— 成员**不写** `@Icon` 时默认得到 `bom-design`；成员**写了** `@Icon("design")` 则**就是 `design`**（`@Icon` 写的是**完整别名**，前缀只作用于默认）。⚠️ 因此该文件里 `DESIGN` 那行 `@Icon("design")` 会让图标变成 `design` 而不是 `bom-design` —— 想要 `bom-design` 就删掉那行。

- **开关在声明、取值在成员**：`@Colorized` / `@Iconized` 决定「这个枚举的成员**参不参与**颜色 / 图标渲染」，`@ColorRole` / `@Icon` 给成员**具体角色 / 别名**。
- **没开开关**：成员上的取值**不生效**（写了 → `mmda check` warning，不是 error）。
- **开了开关但成员缺值**：**先取声明上的默认值**（`@Colorized(role, shade)` 的默认色 / `@Iconized(default)` 或 `@Iconized("prefix")` 的默认别名）；**没有默认值又不写** → 该成员**该项不渲染**（不是错误；允许「只上色、不上图标」或个别成员留空）。
- **颜色是角色 + shade，不是色值**：`@Color(role, shade)` 只声明**语义角色**与**色板 shade（色阶）**（`200` = Material 色板第 3 档、`500` = 基准档），**具体色值来自主题**（Material Design + Theme Builder）——**模型层不写 `#RRGGBB`**。业务数据里「每行一个色」（如 `taskColor varchar(7)`、`bankColor`）是**数据**，不是呈现语义，两者不互相替代。
- **图标是别名不是库绑定**：`@Icon("cancel")` 的 `cancel` 是**逻辑别名**，三端各自映射（TS / Syncfusion、C# / FontAwesome、Flutter / Material Icons）——**模型层不写 `fas fa-x`**。
- **与 `///` 注释的分工**（一概念一主人）：`///` = **显示标签与描述**（`displayLabel` / `description`）；注解 = **呈现**（颜色 / 图标）。i18n 只管 `///` 那一边。
- **渲染口径**见 [`presentation.md`](presentation.md) §4.1；**元数据承载**见 [`meta-model.md`](meta-model.md) §6。

**✔ 细节 6 条已裁（2026-09-25，作者「其他都按你建议，除了图标别名是开放的」）**：

| # | 细节 | 裁决 |
| --- | --- | --- |
| 1 | 颜色角色集合 | **封闭**（`primary` / `secondary` / `info` / `success` / `warning` / `danger`；**2026-09-25 同日修正：再加 `gray` = 共 7 值，见 `errata` §五-64**），**不补** `light` / `dark`（明暗是主题切换的事，不是两个语义角色）；拼错 / 未知名 → **解析期 error** |
| 2 | 主题能否自定义角色 | **不能**：语言层写死 6 值，扩展只留在**皮肤变量**里（不新增角色名） |
| 3 | **图标别名清单** | **开放** —— 别名由**开发人员定义语义词**（不在语言层内置清单、**不进关键字表**，语言层只校验它是字符串字面量）；**映射在 UI 层**（主题 / 皮肤）；**没映射上 → 充其量不显示**（不报 error）；**能警告更好**（UI 层 / IDE 可给 warning / lint，**可选的、不阻塞生成**） |
| 4 | `@Icon` 是否只收别名 | **只收别名**（老实现模块图标的 `fas fa-sitemap fa-fw` 属旧实现，后续迁成别名） |
| 5 | 字段 / 视图能否覆盖成员颜色 | **暂不**：字段级不覆盖；视图级覆盖归 `ui/**/*.mi` |
| 6 | 缺开关却写取值 | **warning**（`mmda check` 出警告，不阻塞） |

> 一句话记：**颜色角色封闭（语言层校验）、图标别名开放（UI 层映射）** —— 前者要拼错即报错，后者允许开发人员自己造词、映射不上顶多不显示。

**✔ 5 条细节已裁（2026-09-25）**：① **`@Icon(x)` 写完整别名**（显式写的即最终别名，**前缀只作用于默认** —— 作者：「写完整别名，这样更灵活」）；② **默认别名 = 成员名转 kebab-case**（`DESIGN` → `design`，`RAW_MATERIAL` → `raw-material`）；③ **`@Colorized` 只负责给默认色板值**，成员 `@Color` 没写时**回落**到它（`@ColorRole` 归入 `@Color`）；④ **色板 shade（色阶）封闭 10 档 `50`–`900`，省略 shade = `500`**；⑤ **`@Iconized` 默认无前缀、不写括号**（`@Iconized` = 取成员名），与 `@Iconized("prefix")` 两种形态并存（**`@Iconized(default)` 写法作废**）。

---

## 7. View

```sql
view OrderItemV : OrderItem as it
    join Order as o on o.orderId = it.orderId
    left join Partner as p on p.partnerId = o.customerId
    where it.quantity > 0
{
    it.orderId,
    it.itemId,
    o.orderNo,
    p.partnerName as customerName,
    it.quantity,
    it.amount
}

view Person : Employee as e where e.status > 0
{
  e.empID as personID identity partitioned(1,1000),
  e.empName as personName
} 
union all Contactor as c
{
  c.contactorID as personID identity partitioned(1001,100000),
  c.contactorName as personName
}
```

> ⚠️ `as` 在三种上下文出现（字段别名 / join 别名 / 类型转换），见 `errata.md` 二-7。
> ⚠️ `where` 条件是**裸字符串**（现有 Java 实现存 `MetaView.whereCondition`），m 语言的目标是把它变成类型化表达式。

**✔ 视图与标识共享（2026-09-25 作者：「标识共享组在视图那里可否」→ 可以 —— 视图即组）**

**`:` 不是 SQL 的 FROM —— 是 C# 风格的「继承 / 实现」**（✔ 2026-09-25 作者原话：「**这个 `:` 类似 C# 的继承、实现，语义上是对 `person` 进行定义**」）：
**`:` 右端是「基」，视图 = 在这个基上「定义」出来的新东西**（**不是**查询投影）。

- `view OrderItemV : OrderItem as it` —— **基 = `OrderItem`**；`as it` 是**引用该基时的别名**（于是列引用写作 `it.orderId`）；
- `join Order as o on …` / `left join Partner as p on …` = **再挂上别的基**（横向、带关联条件）；`union Contactor as c` = **并列的基**（纵向、无关联条件）—— 两者都是「**这个定义由哪些基组成**」的写法；
- **语料证据**：24 个 `view` 里**唯一**带 `:` 的是 **`view Product : Bom { … }`**（`data/models/mes/Product.mm:2`），而 `Bom` 在 `Bom.mm:2` 是 **`record Bom`** → **基可以是 record**；其余 23 个 view 只写 `{ 列 }`（`union` / `join` / `from` **0 命中**）；
- 于是 **「基础表」= 这个定义里的「基」** —— 不需要新的声明位，**就在视图定义里**。

- **语料证据（四个组名就在语料里）**：`view person`（人）、`view organizationunit`（组织单元）、`view materialnsku`（物料 Sku）、`view Maintainable`（工装器具）
  —— `data/models/base/{Person,OrganizationUnit,MaterialNSku}.mm:2`、`data/models/mes/Maintainable.mm:2`。
- **语料形态**：`/// VIEW` + `view <名> { 列定义 }` —— **列直接写在视图里**（= 各基础表的**公共列**），语料 `union` / `from` **0 命中**；
  即**语料的 `view` 已经是 UNION 视图的结果形态，只是没写 `union` 子句**。
- **`Maintainable` 视图自带段**：`@Partitioned [10000,0x000F_FFFF]` + `equipId uint64 default 0 identity generated` → **视图本身是有主键、有段的第一公民**；而 `Person` 视图没有（现状不一致 → 待裁 ③）。
- ⚠️ **实现侧只有 join、还没有 UNION**：`MetaView.java:20-28` = 主表 `t` + `relatives`（join 关系）+ 列别名 + `whereCondition` / `orderBy`（`D:\2026\java\mmda-core\mmda-core-metadata\...\MetaView.java`）。
- **校验（✔ 2026-09-25 作者「同意进」）**：① 同组基础表的 `[min,max]` **两两不重叠**（重叠 = UNION 后主键必撞）→ **`mmda check` 硬门禁（error，生成期就拦，非 warning）**；② **一张表最多属于一个组**（它只有一段）；③ 基础表段落在 realId 空间内 —— ②③ 与 ① 是**同一批校验**，一起在 `mmda check` 里实现。
**✔ 三条已裁（2026-09-25 作者）**：

1. **列清单逐字段显式写出**：**每个基的字段都要写**（不许省略、不许自动推断）。**名字要对得上**；基之间列名不一致时**用 `as` 对齐** —— 作者原话：「**每个表的字段都要写，并且名字要对的上，用 `as`，或者你模仿 SQL**」→ **对齐规矩照 SQL**（列按**位置**对齐；视图列名由别名决定，与 SQL 的 `UNION` 一致）。
2. **基可以是视图** → 继承链允许：`view party : person`（段校验按**叶子表**做）。
3. **视图可以有段，但大多没必要** —— 作者原话：「**视图可以要段，大多情况不更新，没必要段**」→ 段对视图**可选**：**只读视图（大多数）不写段**；只有确实需要区间的视图才声明 `@Partitioned`（语料里 `Product` / `Maintainable` 带、`person` 不带，正是这个意思）。

---

## 8. Record 与 objType 的对应

| M 语言特征 | objType |
| --- | --- |
| 仅 record | `T` |
| + Action | `TA` |
| + Action + Flow/审计 | `TAF` |
| view | `V` / `VAF` |

---

## 9. 与元模型/旧实现的映射

| M 语言 | 元模型元素 | 旧 Java 结构 |
| --- | --- | --- |
| `record` | Record | `MetaObject`（`objType=T`） |
| 字段 | Field | `MetaCol` |
| `@One` / `@Ref` / 旧 `HAS_ONE` / `REF` | Relation | `MetaRelation` / `MetaCol.enumSet` |
| `@Many` | Relation | `MetaRelation`（`relationType=2`） |
| `enum` | Enum（`baseType`、`bitwise`、`values`） | `MetaEnum` / `MetaEnumMember` |
| `view` | View | `MetaView`（`whereCondition`、`orderBy`、`relatives`） |
| 对象级 `@Id/@Index/@ForeignKey/@Check` | 约束 | `MetaIndex`/`MetaForeignKey`/`MetaCheck` |

完整元模型见 [meta-model.md](meta-model.md)；旧库表名映射见 [legacy/java-factory.md](legacy/java-factory.md)。

---

## 10. 相关

- [datatypes.md](datatypes.md) — 类型
- [statements.md](statements.md) — 表达式、行为与状态机
- [meta-model.md](meta-model.md) — 元模型
- [errata.md](errata.md) — 待裁决
