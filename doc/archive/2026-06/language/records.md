# Record、Enum 与 View

## 1. 字段（Field）

### 1.1 语法

```sql
[annotations]
name dataType constraints,
```

- **annotations**（可选）：字段名上方一行或多行注解，见 [§2](#2-字段注解)。
- **name**：字段名（camelCase）。
- **dataType**：逻辑类型；后缀 `?` 表示可空（未指定 `default` 时默认值为 `null`）。
- **constraints**：零个或多个限制关键字，空格分隔；行末英文逗号 `,`。

```sql
userId bigint unsigned identity generated,
userName varchar?(30) charset ascii,
createdAt timestamp? default now,
mobile char(11) indexed,
orderDate date default now indexed future,
quantity decimal(18,3) positive,
```

### 1.2 限制关键字

| 关键字 | 含义 |
|--------|------|
| `indexed` | 索引 |
| `unique` | 唯一索引（隐含 `indexed`） |
| `identity` | 唯一标识；等价 `indexed` + `unique` |
| `default` *value* | 默认值；`now` = 当前时间 |
| `charset` *name* | 字符编码：`ascii`、`utf` 等 |
| `unsigned` | 无符号数值 |
| `positive` | 必须 &gt; 0 |
| `negative` | 必须 &lt; 0 |
| `future` | 日期/时间：值 &gt;= now |
| `past` | 日期/时间：值 &lt;= now |
| `readonly` | 用户不可改；`@Computed` / `generated` 恒只读 |
| `generated` | 生成列（如 DB 自增）；`@Computed` 公式可映射为 SQL |
| `hidden` | UI 隐藏；关联外键为 `hidden` 时，`@One` 导航默认 **lazy**（非 eager） |
| `writeonly` | 仅写（少见） |
| `#(...)` | 检查约束 / 正则 |

**可空与默认**：`varchar?` 无 `default` → 默认 `null`；`timestamp default now` 非空且默认当前时间。

### 1.3 `@Many` 集合字段

`@Many` 单独一行，下一行定义集合属性：

```sql
@Many
items OrderItem[+] readonly,
```

| 类型写法 | 基数 |
|----------|------|
| `OrderItem[]` | 0~n（默认 `*`，括号内可空） |
| `OrderItem[*]` | 0~n（显式） |
| `OrderItem[+]` | 1~n |

集合行同样遵循 `name dataType constraints,`；`readonly` 表示子表对用户只读。

## 2. 字段注解

关系、状态与计算列在 **字段行上方** 用注解声明：

| 注解 | 语义 |
|------|------|
| `@One Entity as alias` | 简写：按目标主键引用，显示遵循目标 `@Name`/`@Thumbnail` |
| `@One Entity(col1,col2,…) as alias` | 显式指定主键 + 显示列 |
| `@Many` | 一对多；下一行 `name ChildEntity[]` / `[+]` / `[*]`；默认 **lazy**，可 `@Many eager` |
| `@Ref Entity(col1,col2,…)` | 引用；外键 + 显示列，**不**生成导航实体 |
| `@State StmName` | 状态字段；下一行须为枚举，`default` 为 STM 初始状态 |
| `@Computed expr` | 计算字段；下一行为存储/展示类型 |

`@One` 简写（`@One Partner as customer`）：通过 `Partner.partnerId` 引用，UI 显示使用 `Partner` 的 `@Name`/`@Thumbnail` 定义。显式括号形式用于覆盖默认显示列。

### 实体语义字段

| 注解 | 说明 |
|------|------|
| `@PartitionID range` | 分区主键 realId → `MetaObject.partitionKey` + `minID`/`maxID` |
| `@Unique` | 分区内业务唯一编码（非 DB unique index） |
| `@Name` | 默认显示名（可多个） |
| `@Thumbnail` | 列表缩略图 URL（唯一） |

**`@PartitionID` 范围**：`[min,max]`、`(min,max]`、`[..max]`、`[min..]`、`(0..]` 等；`[`/`(` 与 `]`/`)` 表示开闭；省略 `min`/`max` 表示该字段数据类型的默认最小/最大值。

见 [meta-model.md](../../../lang/meta-model.md 中 MetaCol 映射。

**加载策略**（注解行尾 `eager` / `lazy`）：

| 注解 | 默认 |
|------|------|
| `@One` | eager（外键 `hidden` → lazy） |
| `@Many` | lazy |
| `@Ref` | eager |

`@One` 与 `@Ref`：前者声明可导航的一对一实体；后者仅外键 + 显示列，无导航属性。未写 `eager`/`lazy` 时使用上表默认，数据访问层可再覆盖。

## 3. 完整示例：Order

```sql
/// 订单
record Order : IAuthorizable {
    orderId uint64 identity generated,

    orderDate date default now indexed future,

    orderNo varchar(15) charset ascii unique,

    /// 客户：下单的客户
    @One Partner(partnerId, partnerCode, partnerName) as customer
    customerId bigint indexed,

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
    creatorId bigint readonly,

    createdAt timestamp default now readonly,
}
```

## 4. Enum

```sql
enum OrderStatus : int {
    NEW = 0,
    PAYED = 1,
    CANCELED = 4,
}
```

### 位标志枚举

```sql
enum PartnerRole : BitSet {
    UNKNOWN     = b0000,
    CUSTOMER    = b0001,
    SUPPLIER    = b0010,
}
```

存储格式（元模型）：`0;UNKNOWN;-|1;CUSTOMER;客户|...`

## 5. 关系小结

| 注解 | 导航属性 | 典型 UI |
|------|----------|---------|
| `@One … as x` | 有（`entity.x`） | searchBox |
| `@Ref …(cols)` | 无 | dropdown / 标签 |
| `@Many` | 集合字段 | 子表 / 子网格 |

Legacy `enumSet`（逆向兼容）：

```
REF User(userID, userName)
HAS_ONE Partner(partnerID, partnerCode, partnerName) AS customer
```

## 6. 对象级约束

对象级注解写在 record 体**末尾**（字段定义之后），映射数据库主键、索引与检查约束：

```sql
@Id PK_orderitem(orderId, itemId),
@Index IDX_OrderItem_mat(materialId, unit),
@Index IDX_OrderItem_mat(orderId, materialId) unique,
@ForeignKey FK_orderitem_order(orderId) ref Order(orderId),
@Check CHK_gift_check(gift switch{ 1 -> price == 0, _ -> price > 0}),
```

| 注解 | 说明 |
|------|------|
| `@Id (cols…)` / `@Id PK_tablename(cols…)` | 组合主键；单字段主键用 `identity` |
| `@Index IDX_…(cols…)` | 命名索引；后缀 `unique` 表示唯一索引（落库） |
| `@ForeignKey FK_…(cols) ref Entity(cols)` | 外键；解析兼容 `references`；可选 `on update` / `on delete` |
| `@Check CHK_…(expr)` | 检查约束 |

字段 `@Unique` 为业务语义（分区内唯一），不生成 DB unique index。存储唯一请用 `@Index … unique`。`hidden` 表示 UI 不展示该列。

**一对多双向导航**：主表 `@Many items Child[+]` 与子表 `@One Parent` + 外键列成对出现；join 为主表主键 = 子表外键。单列外键由子表 `@One`/`@Ref` 表达；**多列外键**在对象级用 `@ForeignKey`，本地列与引用列一一对应：

```sql
record WarehouseLoc {
    @Ref Warehouse(whId, whName)
    whId long,
    locCode varchar(6),
    @Id PK_warehouseloc(whId, locCode),
};

record Pallet {
    palletId bigid identity,
    whId? long,
    locCode varchar?(6),
    @ForeignKey FK_Pallet_WarehouseLoc(whId, locCode) ref WarehouseLoc(whId, locCode) on update cascade on delete set null,
};
```

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

## 8. OrderItem 示例

```sql
/// 订单项
record OrderItem {
    @One Order
    orderId bigint hidden,

    itemId uint32,

    @One Material(materialId,materialCode,materialName) as material
    materialId ulong indexed,

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

## 9. objType 与 M语言 的对应

| M语言 特征 | 建议 objType |
|-----------|--------------|
| 仅 record | T |
| + @Action | TA |
| + FlowTrail / 多步流程 | TAF |
| view | V / VAF |

## 10. 相关

- [types.md](types.md)
- [behaviors.md](behaviors.md)
- [../architect/meta-model.md](../../../lang/meta-model.md
