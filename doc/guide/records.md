# 对象建模（Record）开发指南

> **面向**：建模的架构师 / 设计师 + 写业务代码的程序员。
> **分工**：本页讲「**怎么写**」（照着做的 how-to、例子优先）；**「是什么」在规范篇** —— 语言定义、逐条裁定与出处见 [`../lang/records.md`](../lang/records.md)（作者 2026-09-26 裁定：`guide/` 是程序员视角手册、**非规范**，有矛盾回 [`errata.md`](../errata.md)）。
> **真源**：类型 [`../lang/datatypes.md`](../lang/datatypes.md) · 元模型 [`../lang/meta-model.md`](../lang/meta-model.md) · 呈现 [`../lang/presentation.md`](../lang/presentation.md) · 命名 [`naming.md`](../naming.md) · 枚举另见 [`enums.md`](enums.md) · 上手 [`quickstart.md`](quickstart.md)。
> **实例**：[`../examples/`](../examples/)（`Order` / `OrderItem` / `Material` / `Bom` / `BomItem` …），真实语料 `E:\Dev\mmda-architect\examples\mmda-mes`（378 个语言文件）。
>
> ⚠️ **本页由助手按规范篇派生**（原页在 2026-09-26 18:43 事故中损坏，38,209 B 未找回）—— 结构是我拟的，语义逐条对规范篇，**请作者过目**。

---

## 1. 一分钟模板（复制即用）

```sql
/// 订单
record Order : IAuthorizable {
    orderId int64 identity generated,

    orderDate date default now indexed future,
    orderNo varchar(15) charset ascii unique,

    /// 客户：下单的客户
    @One Partner(partnerId, partnerCode, partnerName) as customer
    customerId int64 indexed,

    /// 订单状态
    @State OrderStatusChanged
    status OrderStatus default 0 indexed,

    /// 订单行
    @Many
    items OrderItem[+] readonly,

    /// 订单金额
    @Computed sum(amount of each items)
    totalAmount decimal?(19,4) unsigned,

    /// 创建人
    @Ref User(userId,userName)
    creatorId int64 readonly,

    createdAt timestamp default now readonly,
}
```

**开工前记住四条**：

1. **一行一个字段**：`[注解行…] 名称 类型[?] [行尾关键字…] ,` —— **行末逗号必须写**。
2. **`?` = 可空**；既没写 `?` 又没写 `default` ⇒ **用户必须输入**（不是「默认空」）。
3. **`@Xxx` 注解写在字段的上一行，`///` 注释写在注解之上**，都**独占一行**（不许写行尾）。
4. **没有「字段级数组」**：多值一律**子表**（见 §5）。

---

## 2. 为什么这么写：三条原则

作者立场（✔ 2026-09-26）：「**我用 record 来进行数据建模**」。

| # | 原则 | 对你写代码意味着什么 |
| --- | --- | --- |
| 1 | **一份 record 多端同形落地**：数据库（DDL）· JSON（载荷）· 实体类（C# / Java；Rust 等 = 预留宿主）· FlatBuffers | 正向生成**无缝、ORM 零映射** —— 改一处模型，四端同步改 |
| 2 | **字段（Field）＝ 属性 ＝ JSON key ＝ 列名** | 「一个字段只有一个名字」，三端逐字一致 —— 所以表名 = 类名、列名 = 属性名，**JPA 不用 `@Column`、EF 不用 `HasColumnName`** |
| 3 | **一切皆 byte**：每个逻辑类型都有**确定的字节表示** | 任何类型都能回答「占几字节、怎么摆位、怎么序列化」（见 [`../lang/datatypes.md`](../lang/datatypes.md) §11.4 的 8 轴） |

> **「无缝」是单向的**：**正向**（record → DDL / JSON / 实体类 / FlatBuffers）无缝、无损；**反向**（DB → record）有损，只做 best-effort + 警告。逻辑类型是唯一真源、目标类型是投影 —— **别指望从 `varchar(80)` 反推出当初写的哪个类型**。

---

## 3. 字段怎么写

```sql
[注解行…]                       // 可选，0..n 行
名称 数据类型 [可空?] [限制关键字…] ,
```

```sql
userId    int64 identity generated readonly,
userName  varchar(30) charset ascii,
createdAt timestamp? default now,
mobile    char(11) indexed,
orderDate date default now indexed future,
quantity  decimal(18,3) positive,
```

**行尾关键字**（大小写不敏感，与 SQL 一致；**拼错 = 解析期 error**，不是警告）：

| 关键字 | 什么时候用 |
| --- | --- |
| `indexed` / `unique` | 单列索引 / 唯一索引（`unique` 隐含 `indexed`） |
| `identity` | 主键自增；等价 `indexed` + `unique`，默认配 `readonly`。**可写起点步长 `identity(1000, 1)`，不写 = `(1, 1)`** |
| `partitioned` | 分区主键（多租户），一个对象**只能有一个** —— 见 §8 |
| `generated` | **存储层生成**（DB 计算列 / 自增列）。与 `@Computed` 分工：`generated` = 数据库算，`@Computed` = 语言层表达式 |
| `default` *v* | 默认值。`now` = 当前时间；布尔 = `true` / `false`（大小写不敏感，`1` / `0` 等价）；**枚举写成员名 `default NONE` 或成员值 `default 0` 都认**；位串见 [`../lang/datatypes.md`](../lang/datatypes.md) §7 |
| `charset` *name* | `ascii` / `utf` … |
| `unsigned` / `positive` / `negative` | 无符号 / 必须 > 0 / 必须 < 0 |
| `future` / `past` | 日期时间必须 ≥ now / ≤ now |
| `readonly` / `hidden` / `writeonly` | 用户不可改 / UI 默认隐藏 / 仅写（`hidden` 的外键，其 `@One` 导航默认变 lazy） |

**注释与标签**：`/// <label>` 或 `/// <label> : <description>`。

- `label` = **显示标签**，进元数据 JSON 并**另走词条（i18n）**通道（按 locale 分片，一份一个 `locale`）；
- `description` = **文档注释**，**不进任何 JSON** —— 由内核抽到 **comments 层**另行存储（生成 DDL 时落数据库注释），只供 `mmda doc` / IDE 看。

**别嵌套 record**：字段类型只能是标量 / 枚举 / 位向量 —— **没有值对象**，组合一律走**子表**或**引用**（见 [`../lang/datatypes.md`](../lang/datatypes.md) §10）。

---

## 4. 约束写在哪：字段级 vs 对象级

| 层级 | 形态 | 例子 |
| --- | --- | --- |
| **字段级** | **字段行尾的裸关键字**（简洁、不占行） | `mobile char(11) indexed,` · `quantity decimal(18,3) positive,` |
| **对象级 / 组合** | **record 体末尾单独具名声明**。**两个及以上字段建一个索引，必须走这条** | `@Index IDX_OrderItem_mat(materialId, unit),` |

> **未定义的名字就是错，必须报错**（作者原话：「`posittive` 写错了肯定要报错」）—— 关键字表**封闭**，没有「自定义约束名」这回事；解析器报 `<file>:<line>:<col>`。

---

## 5. 关系：`@Ref` / `@One` / `@Many` 三选一

| | `@Ref` | `@One` |
| --- | --- | --- |
| 语义 | **外键 + 显示用值对象** | **一对一导航实体**（整实体） |
| 导航属性 | 无 | 有（如 `Order.customer`） |
| 典型 UI | dropdown | searchBox |
| API 序列化 | ID + 显示标签 | 嵌套对象 |
| 默认加载 | eager | eager（外键 `hidden` 时 lazy） |

```sql
/// 客户
@One Partner(partnerId, partnerCode, partnerName) as customer
customerId int64 indexed,

/// 创建人（只要 ID + 名字，不要导航）
@Ref User(userId,userName)
creatorId int64 readonly,
```

- 括号里是「主键 + 显示列」；`as customer` 是**导航属性名**（只 `@One` 有）。
- 加载策略写在**注解行尾**：`@Many lazy` / `@One eager`（`@Many` 默认 lazy）；加载策略影响生成代码是否附带 join，与「要不要索引」无关。

**子表（一对多）**：

```sql
@Many
items OrderItem[+] readonly,
```

| 写法 | 基数 |
| --- | --- |
| `OrderItem[]` | 0~n（默认） |
| `OrderItem[*]` | 0~n（显式） |
| `OrderItem[+]` | 1~n |

`readonly` = 子表对用户只读。**子表就是「关系数据库里怎么落地」的答案** —— 多值不塞数组列。

---

## 6. 对象级约束：四种

```sql
record OrderItem {
    orderId int64 hidden,
    itemId uint32,
    materialId int64 indexed,
    quantity decimal(18,3) positive,
    gift bool default false,
    price decimal(18,4) unsigned,

    @Computed quantity*price
    amount decimal(19,4),

    @Id PK_orderitem(orderId, itemId),
    @Index IDX_OrderItem_mat(materialId, unit),
    @Index IDX_OrderItem_mat(orderId, materialId) unique,
    @Check CHK_gift_check(gift switch{ 1 -> price == 0, _ -> price > 0}),
}
```

| 注解 | 说明 |
| --- | --- |
| `@Id (cols…)` / `@Id PK_表名(cols…)` | **组合主键**；单字段主键用行尾 `identity` |
| `@Index IDX_…(cols…)` | 命名索引；**列级可带 `asc` / `desc`**（不写 = `asc`）：`@Index IDX_x(createdAt desc, status)`。**空值位置语言层写死「排最前」（`NULLS FIRST`）**，不引入 `nulls first` / `nulls last` 关键字（写了 = error） |
| `@ForeignKey FK_…(cols) ref Entity(cols)` | 外键；可选 `on update …` / `on delete …`（`cascade` / `set null`） |
| `@Check CHK_…(expr)` | 检查约束 |

**多列外键**：单列外键由子表的 `@One` / `@Ref` 表达；**多列必须用对象级 `@ForeignKey`**，本地列与引用列一一对应：

```sql
record Pallet {
    palletId int64 identity,
    whId? long,
    locCode varchar?(6),
    @ForeignKey FK_Pallet_WarehouseLoc(whId, locCode) ref WarehouseLoc(whId, locCode)
        on update cascade on delete set null,
}
```

**命名前缀约定**：`PK_` / `FK_` / `IDX_` / `CHK_` / `PROC_` / `FUN_` / `TRG_`。

---

## 7. 状态字段与枚举

```sql
/// 订单状态
@State OrderStatusChanged
status OrderStatus default 0 indexed,
```

- `@State <状态机名>` 写在**枚举字段上一行**，**下一行必须是枚举类型**；`default` = **初始状态**。状态机本体（`stm`）住**独立文件**（`models/stms/*.m`），**不内联进 record**。
- **枚举存储 = 整型**（取能装下全部成员值的最小整型），**语言层一律写成员名**：定义 `NONE = 0`，那么 `default 0` 与 `default NONE` **都认**（`mmda fmt` 归一写成成员名）。**`NONE = 0` 不是空值**（空值只有 `null`）。
- **位标志枚举**：`enum PartnerRole : BitVector { UNKNOWN = 0b0000, CUSTOMER = 0b0001, … }` —— 规范名 `BitVector(n)`（`n` = 位数，8 的倍数，默认 8）；字面量统一 `0b…`；`default` 可写组合值（`default 3` = `1|2`，保留数值）。见 [`../lang/datatypes.md`](../lang/datatypes.md) §7。
- **颜色 / 图标**（`@Colorized` / `@Iconized` / `@Color` / `@Icon`）**走元数据、不走词条**（语言无关，不翻译）—— 一步步怎么写见 [`enums.md`](enums.md)。

---

## 8. 主键、分区与多租户

- **单表主键**：`orderId int64 identity generated,` —— `identity` 已隐含唯一 + 索引。
- **分区主键（多租户）**：**字段级** `partitioned` 是简写（用对象默认段），**带范围**才用注解：

```sql
@Partitioned [10000, 0x000F_FFFF]
addressId int64 identity generated readonly,
```

- 范围写法：`[min,max]` / `(min,max)` / `[..max]` / `(min..]`；省略端点 = 该类型的默认最小 / 最大值。
- **完整 ID（`BIGID`）= `int64 identity partitioned`** —— 展开就是上面那两行。布局：**高 28 位 = 租户 id（有效 27 位）＋ 低 36 位 = realId**；`minID` / `maxID` 约束的是**低位 realId** 的范围。
- **段（段 = `minID`–`maxID`）由架构师 / 设计师分配**，工具不自动分；**不做 UNION 的表共用默认段**（语料 169 张表共用 `[10000, 0x000F_FFFF]`）。
- **为什么要分段**：**标识共享**（作者：「有时候我需要多个表 UNION 成视图，不想 id 冲突，所以分段」）—— 一组要 UNION 成一个视图的表，各领**互不重叠**的一段，UNION 后主键天然不冲突。
- **标识共享组放在视图声明处 —— 视图即组**（`view person` / `view materialnsku` …）。
- **门禁**：同组基础表的段**两两不重叠**（重叠 = UNION 必撞）＋ **一张表最多属于一个组**，都是 `mmda check` 的 **error**（生成期就拦）。

---

## 9. 视图怎么写

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

view Person : Employee as e
{
  e.empID as personID,
  e.empName as personName
}
union all Contactor as c
{
  c.contactorID as personID,
  c.contactorName as personName
}
```

**`:` 右端不是 SQL 的 FROM，是「基」** —— C# 风格的**继承 / 实现**（作者：「这个 `:` 类似 C# 的继承、实现，语义上是对 `person` 进行定义」）：

- `view OrderItemV : OrderItem as it` —— 基 = `OrderItem`，`as it` 是**引用该基时的别名**（列写作 `it.orderId`）；
- `join … on …` / `left join …` = **再挂上别的基**；`union all X as y` = **并列的基**（纵向合并）；
- **基可以是 `view`**（继承链允许，如 `view party : person`），段校验按**叶子表**做。

**三条规矩**：

1. **列清单逐字段显式写出**，名字要对得上；各基之间列名不一致时**用 `as` 对齐** —— **对齐规矩照 SQL**（列按**位置**对齐，视图列名由别名决定，同 SQL 的 `UNION`）。
2. **视图可以有段，但大多没必要**（只读视图不写 `@Partitioned`）。
3. 段重叠校验按上面的门禁走。

> ⏳ 两个已知待办：`where` 条件目前是**裸字符串**，目标态要变成**类型化表达式**；视图图形的后缀 / 格式待裁。

---

## 10. 自检清单（提交前）

- [ ] 每行字段结尾**有逗号**，`@` 注解与 `///` 注释**都独占一行、写在被注释元素上方**。
- [ ] 主键：单列用 `identity`，多列用 `@Id PK_…(…)`；**每张表有且只有一个 `partitioned` 字段**（有分区时）。
- [ ] `?` 与 `default` 的搭配是**你想要**的：不写 `?` 就是**必填**。
- [ ] 多值字段走**子表**（`@Many`），不是数组列。
- [ ] 两个及以上字段的索引 / 唯一 / 外键，**都写在对象级具名声明**里。
- [ ] 行尾关键字**没有拼错**（拼错 = error；词法表封闭）。
- [ ] `///` 里 `label` 写好了；**要显示的描述才写 ` : description`**（它不进 JSON）。
- [ ] 关系选了正确的工具：要**导航实体**用 `@One`，只要**外键 + 显示值**用 `@Ref`。
- [ ] 视图列**逐字段显式写**、跨基列名用 `as` 对齐。
- [ ] 跑过 `mmda check`（段重叠 / 同名 / 关键字都是它的活）。

---

## 11. 常见坑

| 坑 | 后果 | 正确姿势 |
| --- | --- | --- |
| 想「加个数组字段」存多值 | 语言不允许（只有子表） | 建子表 + `@Many` |
| 想嵌套一个「地址 record」 | 关系库里落不了地 | 用**子表**或 `@Ref` 引用 |
| 非空字段不写 `default` 以为是「默认空」 | 用户被要求必填 | 要么写 `?`，要么给 `default`，要么承认它必填 |
| `= null` / `<> null` 判断空 | **校验期 error** | 用 `is null` / `is not null` |
| 期望 `1 = null` 为 false | 它是 **UNKNOWN**（SQL 三值逻辑） | 用 `coalesce(...)` 兜底 |
| 两个字段建一个索引却写了行尾 | 表达不出来 | 对象级 `@Index IDX_…(a, b)` |
| 写了 `nulls last` | 解析期 error | 空值位置语言层写死**排最前** |
| 在模型里写 `#RRGGBB` 或 `fas fa-x` | 越界（模型层不管色值 / 图标库） | 写**角色 + shade** / **逻辑别名** |
| 指望 `@Colorized` / `@Iconized` 的文本翻译 | 走不了词条 | 要翻译的只有 `label` |

---

## 12. 相关

- [`../lang/records.md`](../lang/records.md) — **规范真源**（语法、逐条裁定与出处）
- [`../lang/datatypes.md`](../lang/datatypes.md) — 类型、8 轴、`BitVector` / `BitStr`、数组 = 子表
- [`../lang/statements.md`](../lang/statements.md) — 表达式、行为与状态机
- [`../lang/meta-model.md`](../lang/meta-model.md) — 元模型（Record / Field / Relation / View）
- [`../lang/presentation.md`](../lang/presentation.md) — 呈现（三通道分工）
- [`enums.md`](enums.md) — 枚举开发指南 · [`quickstart.md`](quickstart.md) — 五阶段上手
- [`naming.md`](../naming.md) — 命名约定 · [`../errata.md`](../errata.md) — 待裁决与校勘
