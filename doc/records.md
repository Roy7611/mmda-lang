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
> **仍未定**：**两套名字表都要封闭**（行尾关键字表 + 注解名表；未知名 / 拼错 → `mmda check` 报错），扩展名的白名单机制待定（Profile 还是 `customProperties`）；另 §二-9 的「命名约束 vs 约束表达式 `#ge(0)`」仍待裁。

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
| `@PartitionID range` | 分区主键 realId 范围（多租户） | `partitionKey` + `minID`/`maxID` |
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

### 2.3 `@PartitionID` 范围语法

`[min,max]`、`(min,max]`、`[..max]`、`[min..]`、`(0..]`；`[`/`(` 与 `]`/`)` 表示开闭；省略端点 = 该数据类型的默认最小/最大值。

多租户：**完整 ID（`BIGID`）= 高 28 位 tenantId + 低 36 位 realId**（✔ 2026-09-25 按作者给的常量与底座源码改正 —— **原写「高 16 位 / 低 48 位」是旧布局残留，已废**）：

```
MAX_TENANT_ID = 0x7FF_FFFF   // 高 28 位是租户 id（bit 63 恒 0）
MAX_REAL_ID   = 0xF_FFFF_FFFF // 低 36 位是实际 id
parseTenantID(id) = id >>> 36
```

**租户位 = 27 位有效**（`MAX_TENANT_ID = 0x7FF_FFFF`，bit 63 保留恒 0；✔ 作者 2026-09-25 确认「27位没错」）。`minID` / `maxID` 约束的是**低位 realId 的范围**（与租户位无关）——而且**是按对象领的区间**：语料统一写 `@PartitionID [10000,0x000F_FFFF]` + `addressId uint64 identity generated readonly,`，即「每个对象在 realId 空间里的一段」。`NO_TENANT_ID = 0`（平台公共数据）、`MIN_TENANT_ID = 1`。真源：`D:\2026\java` 的 `Tenancy.java:15-19 / 42-44 / 85-103`（`buildEntityID` / `getRealID` / `getMinID` / `getMaxID` / `isSameTenant`）；**组合主键的第一段是 partitionId**（`"partitionId.xxx"`，`parseTenantID(String)` 按 `.` 切分）。明细见 [`datatypes.md`](datatypes.md) §5。

**为什么分段：标识共享（Identity Sharing，✔ 2026-09-25 作者说明）** —— 作者原话：「**有时候我需要多个表 UNION 成视图，不想 id 冲突，所以分段**」。

- **目的**：一组**要 UNION 成一个视图**的表（如「人」= Tenant / Bank Account / Department / Employee / Partner / Contactor），各自在 realId 空间里领**互不重叠的一段** → UNION 之后**主键天然不冲突**，视图不需要额外加「来源表」列或前缀。
- **两级划分**：**租户位（高 28 位）决定「谁的」、段（`minID` / `maxID`）决定「哪个表的」**；两者合成才是完整的 `partitionId` 空间（`Tenancy.getMinEntityID` / `getMaxEntityID`）。
- **不做 UNION 的表可以共用默认段**：语料实测 **169 张表共用 `[10000, 0x000F_FFFF]`**；只有**标识共享组**内的表才显式细分。
- **语料实测与作者《标识共享》文档逐段吻合**：

| 标识共享组（视图族） | 表 | 段（作者文档） | 语料 `@PartitionID` |
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
- **分段配置的归属（✔ 2026-09-25 作者）**：**分段在 `MetaObject` 上配置**（`minId` / `maxId`），**值是「真实 id」（realId）的范围——去掉租户标识之后的那部分**；字段上一行写的 `@PartitionID [min,max]` 是它在语言侧的声明形态，最终落到元对象的 `partitionKey` + `minID` / `maxID`（**范围写法**：闭区间 `[min,max]`、开区间 `(min,max)`、半开半闭、`..` 省略一侧如 `(0..]` / `[..max]` —— 完整表见 [`design-notes.md`](design-notes.md) §实体语义字段）。**类型侧**：`BIGID` = **`uint64 identity partitioned`**（见 [`datatypes.md`](datatypes.md) §5）。

**✔ 已裁（2026-09-25 作者）**：**段是架构师 / 设计师分配**（作者原话：「**段是架构师、设计师分配阿**」）—— **由人分配，工具不自动分配**；跨表 / 视图族的段规划属架构师，单表在既定段内落地属设计师（[`workflows.md`](workflows.md) §1）。

**⏳ 待裁三条**：① 是否需要**显式声明「标识共享组」**（把表归组，工具据此校验段不重叠并生成 UNION 视图）？② **段重叠**是否进 `mmda check` 硬门禁？③ **UNION 视图在语言里怎么写**（`view` 的形态）。

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

```sql
/// 订单状态
enum OrderStatus : int {
    NEW = 0,
    PAYED = 1,
    CANCELED = 4,
}
```

位标志枚举：

```sql
/// 伙伴角色
enum PartnerRole : BitSet {
    UNKNOWN  = b0000,
    CUSTOMER = b0001,
    SUPPLIER = b0010,
    CARRIER  = b1000,
}
```

- 文本存储格式：`0;NEW;新|1;PAYED;已付款`（`@State` 的初始状态取第一个/`default` 指定项）。
- 枚举成员值可负（语料 `ABANDONED = -1`）。
- 成员描述可写行尾 `/// 新` 或块注释形式的文档注释。

> ⚠️ **待裁决**：`b0000` 位字面量与 BitSet 底层宽度（定宽？加成员是否变更存储宽度），见 `errata.md` 二-5。

---

## 7. View

> ✔ **视图与标识共享（2026-09-25）**：多表 **UNION** 成视图时**主键不冲突**靠 §2.3 的**分段**保证 —— 同一视图族的表各领一个不重叠的 realId 段，故视图**不需要额外加「来源表」列**。

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
```

> ⚠️ `as` 在三种上下文出现（字段别名 / join 别名 / 类型转换），见 `errata.md` 二-7。
> ⚠️ `where` 条件是**裸字符串**（现有 Java 实现存 `MetaView.whereCondition`），m 语言的目标是把它变成类型化表达式。

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
