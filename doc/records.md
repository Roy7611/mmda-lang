# 对象：Record、Field、Enum、View

> 语法形态有两批来源，**未统一**，见 [`errata.md`](errata.md) 冲突 1 与冲突 4。
> 本文以「对象是什么、有哪些元素、各自什么语义」为主，示例优先给**实际语料形态**（381 个文件在用），早期文档形态在对照处标注。

---

## 1. 字段（Field）

### 1.1 语法

```sql
[注解行…]
名称 数据类型 [可空?] [限制关键字…] ,
```

- **注解行**（可选）：字段名上方一行或多行 `@Xxx`，见 [§3](#3-字段注解)。
- **名称**：字段名（camelCase）。
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

> ⚠️ **待裁决**：这些是**自定义命名约束**（未定义就静默通过 = 灰区，见 `errata.md` 二-1）；它们与 `#ge(0)`、`#(d{11})` 形式的**约束表达式**是两套机制还是同义，见 `errata.md` 二-9。

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

多租户：完整 ID 高 16 位为 tenantId、低 48 位为 realId，`minID`/`maxID` 约束 realId 范围。

---

## 3. 对象级约束

写在 record 体**末尾**（字段定义之后）：

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
