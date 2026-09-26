# 数据类型

> 合并早期 `datatypes.md` 与上一轮 `language/types.md`（原文留档 `archive/2026-06/`）。
> 立场：**逻辑类型语言无关**——元模型只存逻辑类型名/编码，跨语言与跨数据库的映射由 Codegen Profile / 方言表承载。

---


> ⚠️ **事故回填版（2026-09-26 18:43 事故）**：本文件被一次批量重写脚本清成 12 字节（`BOM + "undefined"`），**作者原稿（24,918 B）未找回**；此版 = **git `HEAD` 骨架 + 会话重放残片 + `errata.md` §六 抢救行** 回填，**§11.1–§11.3 标题为回填摘要、§11.4 / §11.5 / §14 为回填块**，请作者过目。

## 1. 写法约定

| 规则 | 写法 | 说明 |
| --- | --- | --- |
| 可空 | 后缀 `?` | `decimal?`、`bigint?`（采用 C# 的表达方式） |
| 长度 / 精度 | 括号参数 | `decimal(18,3)`、`varchar(100)`（采用数据库的表达方式） |
| 组合 | `decimal(18,3)?` | 可空、精度 18、小数 3 的定点小数 —— **`?` 在括号之后**（语料实测 `decimal(18, 3)?` **93 处**；`decimal?(18,3)` **0 命中**，见 `errata.md` 冲突 5） |
| **数值字面量** | 十 / `0x` 十六 / `0b` 二；`_` 分组；**大小写不敏感** | `10000`、`0x000F_FFFF`、`0X7f_ff`、`0b1010` 属**同一个数值层**：词法层直接产出**数值**，之后一律**按数值比较** —— **没有「位数 / 大小写规范化」这回事**（✔ 2026-09-25 作者：「范围的写法支持数学上开区间，闭区间的表达式……**你是一门语言，不是字符串解析**」；✔ **2026-09-26 作者：「八进制不要了」→ 不设八进制字面量**，词法器**不认** `0o755`（报 `M0101`），与 C# 一致） |
| 大小写 | **分三层**（见下） | ✔ 2026-09-26 收口：**① 关键字（语法骨架）= 严格小写**（`RECORD` / `SELECT` / `DEFAULT` ❌ error）；**② 内建类型名 / 注解名 / 约束名 = 大小写不敏感**（`BOOL` = `bool`、`BIGID` = `bigid`、`@COMPUTED` = `@Computed`、`INDEXED` = `indexed`）；**③ 标识符（对象名 / 字段名 / 枚举成员）= 严格敏感**，按 ](../naming.md)（类 PascalCase、字段 camelCase） |

> **大小写三层（✔ 2026-09-26 作者：「关键字统一小写吧，类似 C#，你举例的 `module, Module` 让我下了决心」）**：
>
> | 层 | 例子 | 大小写 | 依据 |
> | --- | --- | --- | --- |
> | **语法关键字** | `record` · `enum` · `view` · `stm` · `module` · `import` · `as` · `default` · `true` · `false` | **严格小写**（唯一形态） | 消除 `module` / `Module` 这类歧义 —— **严格小写 ⇒ 关键字只有一种写法，`Module` 反而变成合法标识符、零歧义** |
> | **词表项**（类型 / 注解 / 约束） | `uint32` · `BIGID` · `Date` · `@Computed` · `@Ref` · `indexed` · `readonly` · `unsigned` | **不敏感** | ✔ 2026-09-25 作者：「**类型一律大小写不敏感，包括那些约束，这个跟 SQL 类似**」 |
> | **标识符** | 对象名 / 字段名 / 枚举成员 / 模块名 | **敏感** | ✔ 2026-09-26 作者：「**标识符大小写敏感**」 |
>
> **判据一句话**：**长在语法结构上的字严格小写；长在词汇表里的字（查表命中）不敏感；用户起的名字敏感。**
>
> **两条配套**：① **标识符不得与关键字同形** —— 标识符位置出现关键字 → 解析期 **error `M0206`** + 改名建议（如 `moduleName`）；② **C# 的 `@` 逃逸在本语言不可用**（`@` 已被注解占用，`@record` 无意义）⇒ 只能改名，不能逃逸。**注：`Module`（PascalCase 对象名）合法**（严格小写 ⇒ 与 `module` 不等），`module`（全小写名）非法。

> ✔ **已裁（2026-09-25，取语料形态）**：**长度一律 `type(size)`、可空一律尾部 `?`** —— `varchar(80)?`、`char(11)?`、`decimal(18,3)?`；早期文档的 `varchar?[30]`、`char[11]`、`varchar?(30)` **标为历史、不进词法器**。**容量与可空各司其职**：`(size)` 管容量、`?` 管可空，不混进方括号（见 ](../errata.md) 冲突 5）。

> ✔ **空值只有 `null` 一个（✔ 2026-09-26 作者：「`null` = `NULL`，这个很特殊」「我把 TS 的 `undefined` 也认为是空值，就不进入 m 语言了」）—— 八条口径**：
>
> | # | 条款 | 口径 |
> | --- | --- | --- |
> | 1 | 唯一空值 | **`null`（= SQL `NULL`）**；**`undefined` 不进语言**（TS 的 `undefined` 与 `null` 视为同一空值，但 M 语言里**没有** `undefined` 这个词） |
> | 2 | 拼写 | **大小写不敏感**（`NULL` / `Null` / `null` 等价），进**保留表** |
> | 3 | 「无值」不是值 | `null` 是**缺值标记**、不是某个值 |
> | 4 | 比较 | **`is null` 合法**；**`= null` = error**（解析 / 校验期）；**`null = null` 不成立** |
> | 5 | 三值逻辑 | 沿 SQL 标准（`true` / `false` / `unknown`），与 [`statements.md`](statements.md) §2 同一口径 |
> | 6 | 缺省 | **可空字段不写 `default` ⇒ 默认 `null`**；**显式 `default null` 也认** |
> | 7 | 排序位置 | **空值排最前（`NULLS FIRST`）写死**；**不引入 `nulls first` / `nulls last` 关键字**（写了 = error，见 [`records.md`](records.md) §1.2） |
> | 8 | 两态 | **存储层与 IR 都表达「空」（两态）**；`coalesce(a, b, …)` = 规范形态、`ifnull(a, b)` = 二元等价写法（[`statements.md`](statements.md) §2） |
> ✔ **容量写法 = A（✔ 2026-09-26 作者：「1 A」）：维持 `type(size)`，不给 `[n]` 开口子** —— `char(10)` / `varchar(80)` / `decimal(18,3)` / `BitVector(8)`。**理由**：`[...]` 在本语言已有主（§10 数组 / 子表、`[+]` 基数、表达式层 `r[2..]` / `[0..20]`），`Foo[10]` 会**同时**读成「容量 10」与「10 个 Foo 的数组」；且 C# / Java / TS / Dart **都没有定长字符串类型**（`T name[N]` 是 C 的声明符、不是类型语法）。**`[n]` 连兼容糖也不做**（[`errata.md`](../errata.md) 冲突 5 / §五-121）。

---

## 2. 布尔

`bool` / `bit`；**语言层是 1 位的逻辑值**（`BitVector(1)` 是位序列，两者不同，见 §7）。

**布尔字面量 = `true` / `false`**（✔ 2026-09-26 二次裁定：「**布尔常量：true / false，TRUE / FALSE，True / False 大小写不敏感**」）：

| 写法 | 结果 | 级别 |
| --- | --- | --- |
| `true` / `false` | **规范形态**（`mmda fmt` 归一写这个） | ✅ |
| `TRUE` / `FALSE` / `True` / `False` | 等价 `true` / `false` | ✅ **大小写不敏感**（作者原话：「因为我也不可能将他们作为它用」） |
| `1` / `0` | 等价 `true` / `false` | ✅ 合法（**兼容数据库 `bit` 的 `1` / `0` 定义、我们要考虑存储**；`mmda fmt` 归一为 `true` / `false`） |
| `2` / `-1` 等非 0 / 1 数值 | ❌ | **error `M0102`**（语言不猜） |
| `b'0` / `b'1`（MySQL 默认值语法） | ❌ | **不要**（作者 2026-09-26：「`b'0` / `b'1` 是 MySQL 的默认值语法，不要」） |

> ✔ **存储（✔ 2026-09-26 作者：「兼容数据库的 `bit` 1/0 定义，我们要考虑存储」）**：**厂商落地各异** —— MySQL `BOOL` 的 DDL 出 **`BIT(1)`**（值 1 / 0）、SQL Server 有 `BIT`、Oracle 无布尔（走 `NUMBER(1)` / `CHAR(1)`）、PostgreSQL 有原生 `boolean`、达梦等自有形态 ⇒ `bool` 的 **`STORAGE_BITS` = 1 位（逻辑）**，具体形态**由方言回答、mmda 只做转义**（§11.4 说明 4）。

---

## 3. 整型

吸取 Rust / C# 的习惯，兼顾 PLC 场景（设备侧常用 `byte` / `WORD` / `DWORD` / `LWORD`）。

### 无符号（以 u 开头）

| 类型 | 别名 | 位宽 | 典型数据库类型 |
| --- | --- | --- | --- |
| `uint8` | `u8`、`byte` | 8 | `tinyint unsigned` |
| `uint16` | `u16`、`ushort`、`WORD` | 16 | `smallint unsigned` |
| `uint32` | `u32`、`uint`、`DWORD` | 32 | `int unsigned` |
| `uint64` | `u64`、`ulong`、`LWORD` | 64 | `bigint unsigned` |
| `uint128` | `u128` | 128 | 未来支持（Rust 有该类型） |

### 有符号（以 i 开头）

| 类型 | 别名 | 位宽 | 典型数据库类型 |
| --- | --- | --- | --- |
| `int8` | `i8`、`sbyte` | 8 | `tinyint` |
| `int16` | `i16`、`short` | 16 | `smallint` |
| `int32` | `i32`、`int` | 32 | `integer` |
| `int64` | `i64`、`long` | 64 | `bigint` |
| `int128` | `i128` | 128 | 未来支持 |

> ⚠️ 无符号有两套写法并存：前缀式 `uint64` 与后缀式 `decimal(19,4) unsigned`，见 `errata.md` 二-8。

> ✔ **24 位整型已取消（✔ 2026-09-26 作者：「取消 24 位的整型，没啥用」）**：`uint24` / `int24`（及现实现的 `fixedBytes(3)`）**从类型表移除**；**位宽只有 8 / 16 / 32 / 64（+ 未来 128）** —— 需要 24 位请用 `BitVector(24)`（§7）。表内两行已删。
>
> ✔ **`BIGID` = `int64 identity partitioned`（✔ 2026-09-26 作者：「bigid = int64 identity partitioned」）**：**`uint64` 已迁 `int64`** —— 原因是 **Java 没有 `ulong`**（✔ 作者：「外键也要（受限于 java 无 ulong）」）⇒ **`BIGID` / 主键 / 外键一律 `int64`**；FlatBuffers 有原生 `uint64`，用不用是**宿主投影**的事（§11.5）。**分区位布局**（高 28 位 tenantId 含 27 位有效 + 低 36 位 realId）见 §6 末。

---

## 4. 小数

| 类型 | 说明 |
| --- | --- |
| `decimal` / `numeric` | 定点小数，可定义 (`precision`, `scale`) |
| `float` / `float32` / `f32` | 32 位浮点（三写法同义，见下） |
| `double` / `float64` / `f64` | 64 位浮点（三写法同义，见下） |
| `real` | 支持科学计数法表示的浮点 |
| `money` | **`decimal` 家族别名，规范容量 = `decimal(20,4)`**（见下） |

> ✔ **`money` = `decimal` 家族的别名（✔ 2026-09-26 作者：「`money` = `decimal(20,4)`，只是个别名而已」）**：**规范容量 = `decimal(20,4)`**（不是 `(19,4)`；与现实现 Java / MySQL `DECIMAL(20,4)` 一致 ⇒ 原记的「实现漂移」消解）；**有原生 `money` 的库（PostgreSQL）用原生，否则映射 `decimal(20,4)`**。
>
> ✔ **浮点别名定稿（✔ 2026-09-26 作者：「`float` = `float32` = `f32`，向量 `FloatVector` = `Float32Vector`；`double` = `float64` = `f64`，向量 `Float64Vector`」）**：**`float` = `float32` = `f32`**、**`double` = `float64` = `f64`**（规范拼写取短名，`mmda fmt` 归一）；**没有 `f8` / `f16`**（原始文档里也不存在）。
>
> ✔ **浮点向量（AI / GPU / 几何共用）**：**规范名 `Float32Vector(n)` / `Float64Vector(n)`**（别名 **`FloatVector(n)` ≡ `Float32Vector(n)`**）；**`n` = 元素个数**（≠ `BitVector(n)` 的**位**数）、**是定长值类型、不是数组语法**（§10 不适用）、**元素序 = 下标 0 起连续（写死）**、**字节序 = 小端（写死）**；DB 无通行原生 ⇒ 默认 `BINARY(4n)` / `BINARY(8n)`（§11.4 / §11.5）。
>
> ✔ **舍入交存储层（✔ 2026-09-26 作者：「这个存储层自己有实现配置吧，比如 `decimal(18,2)` 我存入 0.345，数据库不会报错阿」）**：**语言层不设舍入轴、不判「超 `scale`」为 error** —— `decimal(18,2)` 存 `0.345` 由**存储层**按各自配置舍入（助手原提案「HALF_UP + error」**撤回**）；**真正的越界 = 整数位装不下** ⇒ 走 §11.4 四轴托底（禁静默，`M07xx`）。

---

## 5. 日期与时间

| 类型 | 说明 |
| --- | --- |
| `Date` | 年、月、日 |
| `Time` | 时、分、秒与小数；`precision` 0–7 |
| `DateTime` | 日期 + 时间；`precision` 0–9，默认 0 |
| `DateTimeOffset` | 带 UTC 偏移 |
| `DateTimeZoned` | 带偏移与时区 ID |
| `Timestamp` | 时间戳，等价 `DateTime(9)`，默认 `precision` 9 |

**时区**：本质是数据转换。存储时指定一个时区（应用中统一为 UTC 或本地时区），客户端显示时按需转换。

> ✔ **时区口径（✔ 2026-09-26 作者：「只有这两种带偏移和时区，其他都是存服务器本地时间」）**：**只有 `DateTimeOffset` / `DateTimeZoned` 带偏移 / 时区**；**`Date` / `Time` / `DateTime` / `Timestamp` = 服务器本地时间**（无时区语义、**不做 UTC 强制度**）；跨时区传递必须用带偏移 / 带时区的两种。助手原提案「存储一律 UTC」**撤回**（[`errata.md`](../errata.md) §五-117）。

---

## 6. 字符串

| 类型 | 说明 |
| --- | --- |
| `char` / `varchar` | 单字节；可定义 `size`（每字符单字节） |
| `nchar` / `nvarchar` | Unicode；可定义 `size` 与 `charset` |
| `string` | 等价 `nvarchar(255)` |
| `BitStr` | 位串，字符只能包含 `0`/`1`（如 `01011100`），等价 `BitStream` |
| `uuid` | 128 位通用唯一标识 |

语义上字符串即 `char[]` / `nchar[]`：`size` ≥ 1，默认最大容量 **2000**（可由 Profile 调整）；可指定字符编码 `charset`。

> ✔ **已裁（2026-09-25）：`BIGID` 既不是 `bigint` 的别名、也不是错字 —— 它是自有类型**（位布局同日补定：**高 28 位 tenantId + 低 36 位 realId**，见本节末）：**本身即 partitionID（分区主键），高位存 tenantId**（作者原话：「**另外 bigid 是我们特有的定义，就是指本身是 partitionID，高位存 tenantId**」）。与 `@Partitioned` / `MetaObject.partitionKey` / `minID`·`maxID`（[`meta-model.md`](meta-model.md) §5、](../design-notes.md) §8.3）同属**多租户主键**机制。**位布局（✔ 2026-09-25 已定）**：**高 28 位 = tenantId、低 36 位 = realId** ——
>
> ```
> MAX_TENANT_ID = 0x7FF_FFFF    // 高 28 位是租户 id（上限 2^27−1 → bit 63 恒 0、ID 恒为正 long）
> MAX_REAL_ID   = 0xF_FFFF_FFFF // 低 36 位是实际 id（上限 2^36−1 ≈ 687 亿）
> parseTenantID(partitionId) = partitionId >>> 36
> buildEntityID(tenantId, realId) = ((tenantId & MAX_TENANT_ID) << 36) + (realId & MAX_REAL_ID)
> ```
>
> **0 = 无租户**（`NO_TENANT_ID = 0`，平台公共数据）、`MIN_TENANT_ID = 1`；**realId 由分布式唯一 ID 生成器产出、由底座合成完整 ID**（不是数据库生成）。**生成方**：底座 / 应用侧（`buildEntityID`），**不是 DB**。**真源 = 现行实现（新库）`D:\2026\java`**（✔ 2026-09-25 作者澄清：「**`D:\2026` 的是新的**」）：`Tenancy.java:15-19 / 42-44 / 85-103`、入库点 `056ef96`（mmda-core 5.0.0）。新库 `Tenancy.java:17` 的注释**已写「高 27 位是租户 id」**（与作者裁定一致）。**老库 = `D:\Java\mmda`**（作者给的路径；**非 git 仓**，多模块工程）；相关的 `partitionKey` / `minID` / `maxID` 见 [`meta-model.md`](meta-model.md) §5 与 ](../design-notes.md) §7.2。**底座落地用例（同一份扫描实测）**：`TenancyEntityRepository.java:100 / :552 / :585` 与 `SqlQuery.java:1270` 都走 **`Tenancy.buildEntityID(...)`** 合成与过滤实体 ID（配合 `getMinEntityID` / `getMaxEntityID` 做**分区范围查询**）—— 即 **`BIGID` 不只是主键类型，也是多租户查询的过滤口径**（租户维度的隔离直接落在主键高 28 位上）。**✔ 租户位宽已确认（2026-09-25，作者原话：「27位没错」）**：**高 28 位字段中 27 位有效（`MAX_TENANT_ID = 0x7FF_FFFF` = 134,217,727，bit 63 保留恒 0）** —— 不是笔误，ID 恒为正 `long`。**旧布局（16+48）的真源找到了 = 老库 `D:\Java\mmda`**：`mmda-core\mmda-core-entities\...\Tenancy.java:14` `short MAX_TENANT_ID = 0x7FFF`（**15 位有效值域**，注释称 16 位）、`:39` `partitionID >>> 48`、`:82-83` `entityID = tenantID & MAX_TENANT_ID; return (entityID << 48) + (id & 0xFFFF_FFFF_FFFFL)`（**低 48 位 realId**）、`:78` javadoc 同样写「48bits 实际的 id」。**新库改成了 28+36（`>>> 36` / `<< 36`），但 `Tenancy.java:82` 的 javadoc 与 `:27` 的注释漏改** —— 两处都是老库抄过来的话术，**以常量为准**（建议改，助手未动 Java 仓）。
>
> **语料形态与 `BIGID` 的关系（实测补正）**：`BIGID` 这个名字**只出现在早期文档**（全语料 case-insensitive `bigid` **0 命中**）；语料写的是 ——
>
> ```
> record Address {
>     @Partitioned [10000,0x000F_FFFF]      // 独占一行（字段级注解）
>     addressId uint64 identity generated readonly,
> ```
>
> 即 **分区主键 = 带 `@Partitioned` 的 `uint64 identity` 字段**（语料 `uint64 identity` **102 处**、`identity generated` 16 处；**注意：语料里的注解写的还是旧名 `@PartitionID`（186 处）**，见 [`records.md`](records.md) §2.3 的改名说明）；`[min, max]` 是**该对象在 realId 空间里领的区间**（示例统一为 `[10000, 0x000F_FFFF]`，186 个文件）—— 与 `MetaObject.minID`/`maxID`、`getMinEntityID`/`getMaxEntityID` 一一对应，**realId 不是整段给一个租户，而是每个对象领一段**。**为什么要分段 = 标识共享**（作者原话「**有时候我需要多个表 UNION 成视图，不想 id 冲突，所以分段**」）：一组要 UNION 成视图的表各领一段 → 视图主键天然不冲突；段划分、六个标识共享组与语料逐段对照见 [`records.md`](records.md) §2.3；**组就声明在视图处（视图即组）**，见同文件 §7。**✔ 已裁（2026-09-25，作者）**：**`BIGID` 保留为语言类型**，**等价于 `int64 identity partitioned`（✔ 2026-09-26 作者裁定 `uint64` 迁 `int64`，因 Java 无 `ulong`，见 §3）**——
>
> - `uint64` = 类型；`identity` = 由底座生成（分布式唯一 ID）；
> - **`partitioned` = 分区标记**（既有元对象属性 `MetaObject.partitioned`：**物理表分区 + 按租户 / 段隔离查询**）；
> - **分段（`minId` / `maxId`）不在字段上逐表写死，而是在元对象上配置** —— 即 `MetaObject.minID` / `maxID`（[`meta-model.md`](meta-model.md) §5）；
> - **`minId` / `maxId` 是「真实 id」（realId）的范围** —— **去掉租户标识之后的那部分**（比较前先 `getRealID(id) = id & MAX_REAL_ID`，`Tenancy.java:95-97`）。
>
> **段的分配主体 = 架构师 / 设计师**（✔ 2026-09-25 作者：「**段是架构师、设计师分配阿**」）—— 工具只校验不自动分配，见 [`records.md`](records.md) §2.3 与 ](../workflows.md) §1。
>
> 因此语料那两行（**原文用旧名**：`@PartitionID [10000,0x000F_FFFF]` + `addressId uint64 identity generated readonly,`）与 M 语言的 `BIGID` **是同一件事的两种写法**；✔ **大小写敏感面同日已裁（2026-09-25，作者：「类型一律大小写不敏感，包括那些约束，这个跟 SQL 类似」）**：**类型名与约束名一律大小写不敏感**（`BIGID` = `bigid`、`indexed` = `INDEXED`），**标识符（Record / 字段 / 枚举成员）仍大小写敏感**（](../naming.md) §1）—— **`errata.md` §二-6 至此清零**。

> ✔ **`string` 是别名（✔ 2026-09-26 作者：「`string` = `nvarchar(255)`，你把 `string` 理解为类型别名，兼容程序化语言定义」）**：**`string` ≡ `nvarchar(255)`** —— 有 `nvarchar` 就用 `nvarchar`，别名只为让 C# / Java / TS 开发者一眼认得。
>
> ✔ **`MAX_LENGTH` 的单位随类型（✔ 2026-09-26 作者：「`maxLength` 还涉及是字节还是字符，例如 `char(10)` 这个 10 是字符数，`nchar(10)` 是 10 个 unicode 字符，而 `binary(10)` 这个就是字节数，单位不同」）**：`char` / `nchar` / `varchar` / `nvarchar` / `BitStr` = **字符数**；`binary` / `blob` / `ByteStream` = **字节数** —— 轴上**必须带单位语义**，方言投影器不许把「字符数」与「字节数」混算（§11.4 说明 5）。
>
> ✔ **`BitStr` 是字符类型、字面量 = `b'0110'`（✔ 2026-09-26 作者：「`BitStr` 长度是字符数没错，它本身是字符类型，说得通」「`b'0110'` 我认为很好阿，跟普通字符串区分开来」）**：`BitStr(n)` 的 **`n` = 字符数**（不是位数，别与 `BitVector(n)` 混）；**字面量 = `b'0110'`**（如 `default b'0110'`）；落地 = `VARCHAR(n)`（`DataTypeHandler.BIT_STR`）；**非 8 倍数的 `BIT(M)` 反查落点就是它**（§7）。
>
> ✔ **`inet4` / `inet6` 不作为类型（✔ 2026-09-26 作者：「这个不作为类型，在校验器里支持即可」）**：从类型表**移除**，改由**框架层校验器**（Validator）+ `varchar(45)` 承担；`STORAGE_BITS` 行作废。
>
> ✔ **`uuid` 口径（✔ 2026-09-26 作者：「你实现最方便去考虑，对我来说，就是个 36 位的字符串，有唯一性，希望支持按时间序列排序的，c# 好像有」）**：**语言层 / DDL 默认 = `CHAR(36)`**、**生成默认 v7（时间有序）**（v4 允许）；**IR / FlatBuffers = `[ubyte:16]`**（§11.5 效率优先）—— 文本 36 与 16 字节**是各端投影、不是两种类型**。

---

## 7. 位集合与二进制

**规范类型 = `BitVector(n)`**（✔ 2026-09-26 作者定义：「**BitSet(n) 可加长度明确定义，n 是 8 的倍数，BitSet 默认就是 8 位，最大 128**」；引文里的 `BitSet(n)` 是作者当日原话、**逐字保留**）：

✔ **2026-09-26 定名（作者：「**用 BitVector，BitSet, BitArray 别名**」）**：**规范名 = `BitVector(n)`**；**`BitSet`（含 `BitSet(n)`）/ `BitArray` = 别名**；**后缀式 `BitVector8`…`BitVector64` ≡ `BitVector(8)`…`BitVector(64)`**；`mmda fmt` **一律归一写 `BitVector(n)`**（C# `BitArray` / Java `java.util.BitSet` 的差异 = **宿主投影**，§11.3-2）。

**⚠️ 计量口径 = 数「位（bit）」（✔ 2026-09-26 作者追认：「**这个 `n` 是按字节，为了不误解也可以改为按位计数，那么它就跟 `bit(n)` 一样的意思了**」）**：`n` **一律是位数** —— `BitVector(8)` = **8 位 = 1 字节**（**不是 8 字节**）；**要按字节思考就写 `BitVector(b*8)`**（`b` 字节 ⇒ `b*8` 位 —— 作者原话：「**所以我们只有 `bit`, `bitset(n*8)`，理解？**」）。**为什么 `n` 限 8 的倍数**：位宽 = **整数个字节**，作者原话：「**你来一个 `bit(3)`，实际上计算机底层肯定也是对齐拿 8 位来运算**」。**`BitStr` 的 `n` 则数「字符」（它是字符类型，见 §6）**，两者别混。

| 写法 | 语义 |
| --- | --- |
| `BitVector` / `BitVector(8)` | **默认 8 位（= 1 字节）** |
| `BitVector(16)` / `BitVector(24)` … `BitVector(128)` | `n` = **位数**；**必须是 8 的倍数**（= 整数字节），**上限 128 位（= 16 字节）** |
- **别名归一 ✔（2026-09-26 作者：「**用 BitVector，BitSet, BitArray 别名**」）**：**规范名 = `BitVector(n)`**（真源 `DataType.BIT_VECTOR`(129)，唯一）；**`BitSet(n)` / `BitArray` = 别名**（**只作输入兼容**，`mmda fmt` 归一写 `BitVector(n)`）；**`BitVector8`…`BitVector64` = 后缀式兼容写法**（✔ 2026-09-26 作者：「**留着**」—— **保留**、不删）≡ `BitVector(8)`…`BitVector(64)`。**不再新增第四个名字**；**C# `BitArray` / `BitVector32`、Java `java.util.BitSet` 的差异 = 宿主投影**（§11.3-2 每端一个薄投影器），**不进语言层**。
| `BitSet` / `BitSet(n)` / `BitArray` | **别名** ≡ `BitVector` / `BitVector(8)` / `BitVector(n)`（**输入兼容写法**；`mmda fmt` 归一为 `BitVector(n)`） |

- **非 8 倍数怎么办（✔ 2026-09-26 作者：「非 8 倍数在存储时难实现，不认，使用 `BitStr(n)`」）**：**不认**作 `BitVector`（位宽必须是整数字节）；**`mmda import --db` 反查 `BIT(M)`**：`M = 1` → `bool`；`M` 为 **8 的倍数** → `BitVector(M)`（`M` = **位数**）；**其余 `M` → `BitStr(M)`**（文本位串，落地 `VARCHAR(M)`）—— **不报降级**。
- **`0b…` 位字面量（✔ 2026-09-26 作者：「多位置统一写 `0b1010`」）**：多位位串**统一用二进制数值字面量 `0b…`**（`BitVector(8)` 的 `0000_1010` 写 `0b0000_1010`）；**不足 8 位的字面量底层按 8 位存储**；早期文档的 `b0000` 形式**作废**。
- **加成员不改宽度**：`n` 由声明**显式给定**、**不按成员数推断** ⇒ 加成员不会悄悄改变存储宽度。
- **`BitStr` 不是 `BitVector`**：前者是**字符类型**（`n` 数**字符**、字面量 `b'0110'`、落地 `VARCHAR`）、后者是**位序列**（`n` 数**位**、落地 `BIT` / `BINARY`）—— 见 §6 / §11.4。

---

## 8. 大对象与结构化

| 类型 | 说明 |
| --- | --- |
| `blob` / `byteArray` | 二进制（图片、文件） |
| `json` / `jsonb` | JSON 文本 / 二进制 |
| `clob` / `text` | 文本大对象（`tiny/medium/long text` 由 Profile 映射） |

对象可带 `mediaType` / `format` 提示（如 `image/png`）。

> ✔ **`json` 首版不 schema 化（✔ 2026-09-26 作者：「同意」）**：**不做内联 schema / 生成列**；**可声明路径索引**（GIN / 表达式索引由方言，落地下一步）。

---

## 9. 流（Stream）

数据流分为字节流与字符流：

| 类型 | 写法 | 等价 |
| --- | --- | --- |
| `ByteStream` | `byte*` | `Blob` |
| `CharStream` | `char*` | `Clob` |
| `NCharStream` | `nchar*` | `NClob` |

> ✔ **流的定位（✔ 2026-09-26 作者：「这个我很少用，只是兼容考虑」）**：**只作兼容**，不进首版核心链路。

---

## 10. 数组

**数组 = 子表**（✔ 2026-09-26 作者：「**不允许定义枚举标量的数组类型的字段，只有子表**」「**不要嵌套！不然你在关系数据库里怎么落地？**」）：

| 字段形态 | 是否允许 | 落地 |
| --- | --- | --- |
| `T[]` 且 `T` = record | ✅ **允许** | **子表**（1:N 外键反向引用 + `@Index`）—— 这是本语言**唯一**的「数组字段」 |
| `T[]` 且 `T` = 枚举 / 标量 | ❌ **不允许** | **解析期 error**（`M0102` 同族，码位待补 §14）。标量多值请用 `BitVector` / `BitStr`（§7）或子表 |
| 嵌套 record（值对象） | ❌ **不允许** | **解析期 error** —— 关系库里落不下（作者：「不要嵌套！」） |

**为什么**：M 语言的字段**只有一条落库路径**（列 / 子表），**数组没有自己的类型轴**（§11.4 `T[]` 行）——**基数是声明层的事**，`T[]` 必须先能被翻译成一张表。

**写法**（表达式层，已定）：

```sql
var arr int[];
var s = r[2..];     // 切片
var a = [0..20];    // range
```

> ✔ **修订（2026-09-26）**：早先说「数组三类都允许（record / 枚举 / 标量）」**作废**，以本表为准；**子表是唯一的数组形态**。

---

## 11. 跨语言与跨数据库映射

元模型只存 `dataType` 的编码或名称；映射表由 **Codegen Profile / 方言表**携带。

| 逻辑类型 | C# | Java | Rust | PostgreSQL |
| --- | --- | --- | --- | --- |
| `uint32` | `uint` | `long` | `u32` | `integer` |
| `decimal(18,3)` | `decimal` | `BigDecimal` | `rust_decimal` | `decimal` |
| `string` | `string` | `String` | `String` | `varchar` |
| `bool` | `bool` | `boolean` | `bool` | `boolean` |

**落地约定（`..\PLAN.md` §3.6）**：映射表用**数据**描述（语言内声明或项目内数据文件），编译期生成 Rust / Java / TS 三份映射，禁止各处手写——现有实现已有 Java（`MetaDataType` + 8 个方言）与 TS 各一份，Rust 再来一份就是三处漂移。

---

### 11.1 轴 = 语言层声明（不是一张映射表）

**跨端映射 = 8 个「类型轴」+ 各端一个薄投影器**（✔ 2026-09-26 作者：「把它从 Java 的 enum 提到内核（语言层）」）：轴定义在**语言层 / 元数据层**（真源 = Java `DataTypeAttribute` 的位标志 `1 << bit`，提到内核）；**方言逐一向这 8 个轴作答**（支持 / 怎么投影 / 怎么降级）。**封闭 8 轴**：`MAX_LENGTH` · `PRECISION` · `SCALE` · `TYPE_HANDLER` · `VALUE_RANGE` · `AUTO_INCR` · `STORAGE_BITS` · `UDT`。

### 11.2 每端一个薄投影器

同一逻辑类型在**每个宿主 / 格式**各有一个薄投影（C# `BitArray` / Java `java.util.BitSet` 的差异就落在这里），**不进语言层**。

### 11.3 降级必须声明（禁静默）

「目标端表达不了」（上限更小 / 精度不足 / 无 unsigned …）= **降级** ⇒ 每端声明 + 内核 `M07xx` warning + Profile 可关；**轴越界 ≠ 降级**（轴越界是**校验失败**，见 §11.4 四轴）。

> ⚠️ **回填说明**：§11.1–§11.3 的小标题在 18:43 事故中随原稿丢失，此处按正文引用与 `errata.md` §六 抢救行**回填摘要**；**§11.4 / §11.5 为完整回填块**，请作者过目。
### 11.4 类型 × 8 轴（语言层声明，回填块）

**六条说明**：

1. **`AUTO_INCR` 保留（数据库普遍支持）**（✔ 2026-09-26 作者：「**auto_incr 数据库一般支持，所以放着**」）：现在实测虽只有 `SERIAL` 的厂商类型字符串里出现 `BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE`、语言层 0 处显式使用，但**它是普遍可投影的轴** ⇒ **留在封闭清单里**（`BIGID` / `identity generated` 就是它的语言层写法）。**`UDT` 首版不用**（留位给扩展；✔ 2026-09-26 作者：「**本意是 UDT，用户定义类型，改为 UDT 吧**」）。
2. **方言必须逐一向这 8 个轴作答**（支持 / 怎么投影 / 怎么降级，§11.3-3）。本表是**语言层声明**，不是方言答案：方言可以「多」（补 `VALUE_RANGE`、绑 `TYPE_HANDLER`），不能「缺」—— 缺就是降级，必须声明。
3. **`BitVector(n)` 的位宽走 `STORAGE_BITS`、`BitStr` 的长度走 `MAX_LENGTH`**，二者别混（**且 `BitVector(n)` 的 `n` 数位、`BitStr(n)` 的 `n` 数字符**，§7）：现实现把 MySQL `BIT(M)` 的位宽算进了 `maxLength`（`MySqlDataTypes.java:34`），**这是本表纠正的第一处已知漂移**。
4. **`bool` 与 `BitVector(n)` 在 DB 侧都碰 `BIT`，但落点不同**（✔ 2026-09-26 作者：「兼容数据库的 bit 1/0 定义，我们要考虑存储」）：实现里 **MySQL `BOOL` 的 DDL = `BIT(1)`**（值 1/0），而 **MySQL 的 `BIT` / `BIT(M)` 类型映射到 `BIT_VECTOR`**（`make(BIT_VECTOR,"BIT", maxLength(1..64，默认 1))`）= 我们的 `BitVector(n)`，**不是 `bool`**。⇒ **反查（`mmda import --db`）见 `BIT(M)` 的落点（✔ 2026-09-26 作者：「**非 8 倍数在存储时难实现，不认，使用 `BitStr(n)`**」）**：`M = 1` → **`bool`**；`M` 为 **8 的倍数** → **`BitVector(M)`**（`M` 是**位数**）；**其余 `M`（2–7、非 8 的倍数）→ `BitStr(M)`**（文本位串，落地 `VARCHAR(M)`）—— **不认**作 `BitVector`（非 8 倍数位宽存储上难实现），**也不报降级**。
5. **`MAX_LENGTH` 的单位随类型**（✔ 2026-09-26 作者：「**`maxLength` 还涉及是字节还是字符，例如 `char(10)` 这个 10 是字符数，`nchar(10)` 是 10 个 unicode 字符，而 `binary(10)` 这个就是字节数，单位不同**」）：`char` / `nchar` / `varchar` / `nvarchar` / `BitStr` = **字符数**；`binary` / `blob` / `ByteStream` = **字节数** —— 轴上**必须带单位语义**，方言投影器不许把「字符数」跟「字节数」混算（`varchar(n)` 落地时要按 `charset` 换算字节上限）。
| 逻辑类型 | MAX_LENGTH | PRECISION | SCALE | TYPE_HANDLER | VALUE_RANGE | AUTO_INCR | STORAGE_BITS | UDT | 现实现（Java 侧）实测 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `bool` / `bit` | — | — | — | — | ● | — | ● | — | `BOOL` = `valueRange(0,1)`；**`STORAGE_BITS` = 1 位（逻辑布尔）** —— **MySQL DDL 出 `BIT(1)`、存 1 / 0**（`MySqlDataTypes.java:49`）；**厂商落地各异**（`bool` / `BIT(1)` / 达梦自有形态 —— `BIT(1)` 里的「1」既是长度也当位宽，**是存储实现的事**），**由方言回答、mmda 只做转义**（见说明 4） |
| `uint8`…`uint64` / `int8`…`int64` | — | — | — | — | ● | ○ | ● | — | `valueRange(…)` + `fixedBytes(1/2/4/8)` ⇒ **`STORAGE_BITS` = 8 / 16 / 32 / 64**（`fixedBytes(8)` ≡ `fixedBits(64)`，**纯计量单位换算**）；现实现另有 `uint24` / `int24` = `fixedBytes(3)`，**已取消**（§3） |
| `uint128` / `int128`（未来） | — | — | — | — | ● | ○ | ● | — | 实现里没有（仅 Rust 有）⇒ **`STORAGE_BITS` = 128** |
| `decimal` / `numeric` | — | ● | ● | — | ○ | — | — | — | `precision(0,65)` + `scale(0,30)`；**变长十进制 ⇒ 不声明固定 `STORAGE_BITS`** |
| `money` | — | ● | ● | — | ○ | — | — | — | = `DECIMAL(20,4)`（`DECIMAL.as(MONEY,…)`）—— **`decimal` 家族别名**（有原生用原生，否则 `decimal(19,4)`） |
| `float` / `float32` / `f32` / `real` | — | — | — | — | ● | — | ● | — | `valueRange(…)` + `fixedBytes(4)` ⇒ **32 位**；**MySQL 里 `REAL` 就是 `FLOAT`** |
| `double` / `float64` / `f64` | — | — | — | — | ● | — | ● | — | `valueRange(…)` + `fixedBytes(8)` ⇒ **64 位** |
| `Float32Vector(n)` / `Float64Vector(n)`（别名 `FloatVector` ≡ `Float32Vector`） | ●（**元素个数**） | — | — | — | ○ | — | ●（**元素位宽** 32 / 64） | — | **语言层新类型（2026-09-26 定稿；Java 实现里没有）**：`MAX_LENGTH` = **元素个数**、`STORAGE_BITS` = **元素位宽 × 元素个数**；**定长值类型、不是数组 ⇒ §10 不适用**；DB 无通行原生 ⇒ 默认 `BINARY(4n)` / `BINARY(8n)` |
| `char` / `nchar` | ●（**字符数**） | — | — | — | ○ | — | ○ | — | `maxLength(0..255，默认 10)`；**`nchar(10)` = 10 个 Unicode 字符**；**位宽 = 长度 × 每字符字节数**（由 `charset` 定，方言回答） |
| `varchar` / `nvarchar` | ●（**字符数**） | — | — | — | ○ | — | ○ | — | `maxLength(0..65535，默认 50)`；上限交方言投影器（§6） |
| `string` | ●（**字符数**，= 255） | — | — | — | — | — | — | — | ≡ `nvarchar(255)` 类型别名（B2） |
| `BitStr` / `BitStr(n)`（文本位串） | ●（**字符数** = 位串长度） | — | — | — | — | — | ○ | — | **`BIT_STRING`(38) = `VARCHAR.as(BIT_STRING)`** ⇒ 带 `MAX_LENGTH`；`DataTypeHandler.BIT_STR`。**`BitStr(n)` 的长度 = 位串字符数（不是位数）**，也是**反查非 8 倍数 `BIT(M)` 的落点**（说明 4）；**字面量 = `b'0110'`** |
| `BitVector(n)`（**规范名**；别名 `BitSet` / `BitArray`、后缀式 `BitVector8`…`BitVector64`） | — | — | — | — | ○ | — | ● | — | **`STORAGE_BITS` = `n` 位**（`n` 为 8 的倍数、默认 8、上限 128；**`n` 走 `STORAGE_BITS` 不走 `MAX_LENGTH`**）—— ⚠️ 现实现把位宽挂在 `maxLength(1..64，默认 1)` 上（MySQL `BIT`），**漂移，语言层纠正为 `STORAGE_BITS`**；`BitVector8`…`64` ≡ `BitVector(8)`…`BitVector(64)`（**都是位数**） |
| `uuid` | — | — | — | — | — | — | ● | — | `STORAGE_BITS` = **128 位（逻辑）**；**DDL 默认 = `CHAR(36)`**（✔ 2026-09-26 作者：「就是个 36 位的字符串」；现实现 `CHAR.as(UUID,"CHAR(36)", fixedBytes(36))` 与此一致）、**生成默认 v7（时间有序）**；方言可改 `BINARY(16)` / `RAW(16)`；**IR 侧 = `[ubyte:16]`**（§11.5） |
| ~~`inet4` / `inet6`~~ | — | — | — | — | ~~○~~ | — | ~~●~~ | — | **不作类型（✔ 2026-09-26 作者：「这个不作为类型，在校验器里支持即可」）** ⇒ 从类型表移除、`STORAGE_BITS` 行作废，改由**框架层校验器**（Validator 层）+ `varchar(45)` 承担（§6 / [`glossary.md`](../glossary.md)） |
| `Date` | — | — | — | — | ● | — | ● | — | `fixedBytes(3)` + `dateBetween(…)` ⇒ **24 位** |
| `Time` | — | ● | — | — | ● | — | ● | — | `maxPrecision(6)` + `inBytes(3,6)` + 值域 ⇒ **24–48 位** |
| `DateTime` / `Timestamp` / `DateTimeOffset` / `DateTimeZoned` | — | ● | — | — | ● | — | ● | — | `maxPrecision(6)` + `inBytes(4,8)` + 值域 ⇒ **32–64 位** |
| `blob` / `byteArray` | ●（**字节数**） | — | — | ○ | — | — | ○ | — | `BLOB` = `maxLength(65535)`；`BINARY` = `maxLength(0..255，默认 1)` —— **这里的数是字节** |
| `clob` / `text` / `nclob` | ●（**字符数**） | — | — | ○ | — | — | — | — | `TEXT` / `LONGTEXT` = `maxLength(…)` |
| `json` / `jsonb` | ●（**字符数**） | — | — | ● | — | — | — | — | `LONGTEXT.as(JSON)`；`TYPE_HANDLER` = 序列化 / 反序列化 |
| `ByteStream` / `CharStream` / `NCharStream` | ● | — | — | ● | — | — | ● | — | `VARBINARY` = `BYTE_STREAM` + 处理器 ⇒ 位宽由方言 |
| `BIGID` | — | — | — | — | ○ | ● | ● | — | ≡ `int64 identity partitioned`：`AUTO_INCR`（identity）+ `STORAGE_BITS` = **64 位**；`VALUE_RANGE`（段）在**元对象**上，不在字段上 |
| `T[]`（数组） | — | — | — | — | — | — | — | — | **数组没有类型轴**：基数是**声明层**的（§10）；**元素只允许 record ⇒ 子表**（枚举 / 标量数组字段 = 解析期 error，✔ 2026-09-26 作者；**⤴ 修订**早先「三类都允许」） |
| # | 轴 | 含义 | 例子 |
| --- | --- | --- | --- |
| 0 | `MAX_LENGTH` | 容量 / 长度 —— **单位随类型**（`char` / `nchar` / `varchar` / `nvarchar` / `BitStr` = **字符数**；`binary` / `blob` / `ByteStream` = **字节数**）—— **校验托底** | `varchar(100)`、`BitStr(12)` |
| 1 | `PRECISION` | 精度（数值 / 时间）—— **校验托底** | `decimal(18,3)`、`DateTime(3)` |
| 2 | `SCALE` | 小数位 —— **校验托底** | `decimal(18,3)` |
| 3 | `TYPE_HANDLER` | 序列化 / 反序列化处理器 | `blob`、`json` |
| 4 | `VALUE_RANGE` | 值域 `(min,max)` —— **校验托底** | 段范围、CHECK |
| 5 | `AUTO_INCR` | 自增 / 由底座生成（**数据库普遍支持，保留**） | `identity generated` |
| 6 | `STORAGE_BITS` | **存储位宽（bit）** —— 定长位宽；字节数 = 位宽 ÷ 8 | `uint64` = 64、`BitVector(n)` = n、`uuid` = 128 |
| 7 | `UDT` | **用户定义类型**（user-defined type）—— 扩展位（预留，首版不用） | — |

✔ **2026-09-26 作者：「把它从 Java 的 enum 提到内核（语言层）」** —— 这 8 个轴现状是 **Java 私货**（`D:\2026\java\mmda-core\mmda-core-metadata\...\enums\DataTypeAttribute.java`，位标志 `1 << bit`）。**提到语言层 ⇒ 成为类型系统的一部分**：① **每个逻辑类型声明适用哪些轴**（`varchar` = `MAX_LENGTH`；`decimal` = `PRECISION` + `SCALE`；`BitVector(n)` = `STORAGE_BITS`；`identity` 字段 = `AUTO_INCR`）；② **每个方言必须逐一回答这 8 个轴**（支持 / 怎么投影 / 怎么降级）。

> ✔ **四轴 = 校验托底，不只是映射提示（✔ 2026-09-26 作者：「8 轴中 `MAX_LENGTH` / `PRECISION` / `SCALE` / `VALUE_RANGE` 其实也起到 validator 的托底作用 —— 你超出这个范围，是存不进去的，或者数据库存储会自动截断」）**：这四轴是**语言层 / 元数据层的校验契约** ⇒ **越界 = 校验失败（解析 / 校验期 error），语言层绝不静默截断**；**只有「目标端表达不了」（上限更小、精度不足、无 unsigned …）才走降级**（§11.3-3：每端声明 + 内核 `M07xx` warning + Profile 可关）。「存不进去 / 自动截断」是**没说清降级时的坏结果，不是设计口径**。

> ✔ **轴 6 由 `BYTE_RANGE` 改名 `STORAGE_BITS`，量纲 = 位（✔ 2026-09-26 作者：「`byte_range` 实际我想用 `storage_bits` 用来搞清楚底层存储，因为 bit 类型数据库的实现不一样，可能不是 8 位，`byte_range` 无法覆盖……`fixedBytes(8)` = `fixedBits(64)`，仅仅存储计量单位转换而已」）**：**轴值一律写位（bit）**，需要字节就 **÷8**（`fixedBytes(8)` ≡ `fixedBits(64)`）；**`bit` 在语言层概念里就是 1 位**，具体是 `bool` / `BIT(1)` / 达梦等哪一形态**是底层实现的事**（作者在 Java 代码里注释了各数据库官方文档参考）—— **mmda 只做转义，合适就好**（作者原话）。

### 11.5 FlatBuffers 投影（B5 首版 IR）—— **性能 / 效率优先**

> ✔ **方向（2026-09-26 作者授权）**：作者原话「**flatbuffers的映射细则我没想，性能和效率优先，你觉得呢**」⇒ **FlatBuffers 投影的第一判据 = 性能 / 效率**（零拷贝、可原地读、少一次分配、少一层类型字节）；**可读性不是它的活**（可读性交给 JSON / `mmda fmt` / IDE）。**细则 = 下表（✔ 2026-09-26 作者「同意」定案）**；**JSON / OAS 侧的口径见 [`api.md`](../api.md) §3.5** —— 两条投影、**一个真源**（逻辑类型）。

| 逻辑类型 | FlatBuffers 形态 | 口径 / 理由 |
| --- | --- | --- |
| `bool` / `bit` | `bool` | 1 字节；存 1 / 0，与 §2 同源 —— ⚠️ **IR 的 1 字节 ≠ `STORAGE_BITS` 的 1 位**（存储位宽见 §11.1 / §11.4，IR 形态见本表） |
| `int8`…`int32` / `uint8`…`uint32` | 同名标量 | 一一对应，零转换 |
| `uint64` | `uint64` | **FlatBuffers 有原生 `uint64`** ⇒ 不受「Java 无 ulong」的约束（那是**宿主投影**的活，见 §11.3-2） |
| `int64` / `BIGID` / ID 与外键 | `int64` | 与 §3 定案一致（`uint64 identity` 已迁 `int64`） |
| `uint128` / `int128`（未来） | `struct{u64 lo, u64 hi}` | 预留；字节序随 FlatBuffers（小端） |
| `decimal(p,s)` / `numeric` / `money` | **`p ≤ 18`：`long`（scaled int64，值 × 10^s）**；`p > 18`：`string` | **性能 = 定长可算、零分配** ⇒ 与 **JSON 的 `string` 口径不同**（[`api.md`](../api.md) §3.5 精度优先）；**两条口径都必须写进 Profile 显式声明** |
| `float` / `float32` / `f32` / `real` | `float` | 32 位；三写法同义（§4） |
> ✔ **两条写法专题收口（2026-09-26 作者：「1 A, 2 用 BitVector，BitSet, BitArray 别名」）**：① **容量写法 ✔ = A：维持 `type(size)`**（`char(10)` / `varchar(80)`）—— **不开 `[n]` 口子**（连兼容糖也不做），见 §1；② **位向量规范名 ✔ = `BitVector(n)`**，**`BitSet` / `BitArray` 作别名**，见 §7。上一轮两条 ⏳ 就此关闭（[`errata.md`](../errata.md) §二-16 / §二-17 转 ✔，校勘第一百二十三轮）。
> ✔ **后缀式位向量保留（2026-09-26 作者：「留着」）**：`BitVector8`…`BitVector64` 作为**后缀式兼容写法**保留（≡ `BitVector(8)`…`BitVector(64)`，`n` 都是**位数**），**`mmda fmt` 仍归一写 `BitVector(n)`** —— 与 §7 定名同一口径，本轮把这条落成**显式裁定**（[`errata.md`](../errata.md) §二-17 ⤴ / §五-112）。**同时登记一条 ⏳ 提案**：`FloatVector` / `f32` / `f64`（见 §4 ⏳ 块、[`errata.md`](../errata.md) §二-18 —— **⤴ 同日已定稿，见下一行**）—— **勘验已给作者：原始文档里没有 `f8` / `f16` / `f32` / `f64` 别名**。
> ✔ **浮点标量与浮点向量定稿（2026-09-26 作者：「float = float32 = f32, 向量FloatVector=Float32Vector；double = float64 = f64，向量Float64Vector」+「其他同意你的观点」）**：`float` = `float32` = `f32`、`double` = `float64` = `f64`（**规范拼写取短名**，别名 `mmda fmt` 归一）；**向量 = `Float32Vector(n)` / `Float64Vector(n)`**（别名 `FloatVector(n)` ≡ `Float32Vector(n)`）—— **`n` = 元素个数**（≠ `BitVector(n)` 的位宽）、**是定长值类型、不是数组语法**、DB 默认 `BINARY(4n)` / `BINARY(8n)`；见 §4 / §11.4（说明 6）/ §11.5。**唯一余项 ⏳ = 端序**（[`errata.md`](../errata.md) §二-19：助手立场 = 语言层不设端序轴、格式写死小端、**外部协议端序进端点 / 连接器配置**）。

| `double` / `float64` / `f64` | `double` | 64 位；三写法同义（§4） |
| `Float32Vector(n)` / `Float64Vector(n)`（别名 `FloatVector(n)` ≡ `Float32Vector(n)`） | `vector<float>` / `vector<double>` | **元素序 = 下标 0 起、连续（写死）**；**字节序 = 小端**（FlatBuffers 格式本身即小端；大端宿主由生成代码字节交换）；见 §4 ⑥（✔ 已裁）|
| `Date` | `int32`（UTC 日序） | 定长 4 字节（DB 侧的 `fixedBytes(3)` 是**存储**口径，不是 IR 口径） |
| `Time` | `int64`（当日纳秒） | 定长、可比较 |
| `DateTime` / `Timestamp` | `int64` epoch（单位进 schema） | **IR 走 epoch 整数**；JSON 侧仍 `string`（[`api.md`](../api.md) §3.5 已裁：可读性优先） |
| `DateTimeOffset` / `DateTimeZoned` | `int64` epoch + `int16` 偏移（分钟） | 偏移只在有语义的类型上带（不污染 `DateTime`） |
| `char(n)` / `varchar(n)` / `nvarchar(n)` / `string` / `clob` / `text` / `json` / `jsonb` | `string` | UTF-8；**`nvarchar` 不做区分**；长度约束由 schema 外的校验规则带（FlatBuffers 无 `maxLength`） |
| `BitStr(n)` | `string`（`^[01]*$`） | 与 [`api.md`](../api.md) §3.5 同口径；**不打包成位**（保住 `b'0110'` 字面量的可读、免位序之争） |
| `BitVector(n)` | `uint64`（`n ≤ 64`）；`vector<uint64>`（`n > 64`） | **位序 = LSB-first（写死，进一致性用例）**；`n` = **位数**（8 的倍数 = 整数字节、默认 8、上限 128 位；§7）；`n ≤ 64` = **一个 `uint64`** |
| `uuid` | `[ubyte:16]`（RFC 4122 字节序） | 定长、零分配；**✔ 已裁：不用 `struct{u64 low, u64 high}`**；**字节序 = RFC 4122（大端文本序）写死，进一致性用例** |
| `blob` / `byteArray` / `ByteStream` | `vector<ubyte>` | 大文件不走 IR（[`api.md`](../api.md) §3.5：`multipart/form-data`） |
| `inet4` / `inet6` | `[ubyte:4]` / `[ubyte:16]` | 定长；不带文本 |
| 枚举（`.me`） | 原生 `enum`（底层 `int8` / `int32`，取**最小能装下全部成员值**的整型） | 默认 `0 = NONE`（§12 已裁）⇒ **默认值不占数据**；**位标志枚举 = 底层整型 + 语义注释**（FlatBuffers 无 `[Flags]`） |
| `T?`（可空） | **`table` 字段**（vtable 存在位 = 天然可空、零成本）；定长 `struct` 无空位 | **默认「能 table 就 table」**；只有「定长 + 全必填 + 纯值」的叶子才 `struct` |
| `T[]`（子表） | `vector of tables`（偏移向量） | 值数组已取消（§10）⇒ 无别的分支 |
| record（根 / 子表） | `table` | 字段名 = record 字段名（[`naming.md`](../naming.md) §1 契约名零端差异）；字段**只追加、不删不改号** |

**几条性能点（先立，不逐格点头也成立）**：

1. **`table` 是默认，`struct` 是例外**：`struct` 无 vtable、可原地零拷贝，但**不可空、不可加字段、不可变长**；IR 是长期演进的契约 ⇒ **默认 `table`**。
2. **不用 `union`**：多一个类型字节 + 一个偏移，而本语言的层级只有 record / 枚举 ⇒ 用不上；需要区分时由业务字段自己带。
3. **不开便利层**：`--gen-object-api` / 反射 / `flatc --json` **不进生产链路**（分配 + 反射 = 反性能）；IR 的读者是**生成的宿主代码**。
4. **schema 纪律**：`file_identifier` + IR 版本号（承 §3.5）；**字段只追加**。
5. **两处「隐含约定」必须落成用例**：`BitVector` 的 **LSB-first**、`uuid` 的**字节序** —— 否则三端各按自己习惯解释。

6. **✔ 端序 = 小端（语言层写死；2026-09-26 已裁）**：IR 里的整数 / 浮点字节序由 FlatBuffers 格式规定为**小端**（本表 §11.5 `uint128` 行早已如此），**大端平台（s390x 等）由生成代码在边界字节交换** ⇒ **语言层不设「端序轴」**；**外部协议（Modbus / S7 / OPC UA…）的端序不是类型的事**，落**端点的 `byteOrder` 声明**（见 §4 ⑥ 与 [`event_bus.md`](/event_bus.md §6）。

**✔ 两格已裁（2026-09-26 作者「同意」）**：① **`uuid` = `[ubyte:16]`**（RFC 4122 字节序）；② **`decimal` 用 scaled `int64`** —— 与 JSON 的 `string` 不一致**是设计如此**（IR 效率优先 / JSON 精度优先），**两条口径都在 Profile 显式声明**。


## 12. 关系与枚举不做新类型

关系 DSL 只引用 Record / Enum，不引入新类型：

```
ENUM OrderStatus
ENUMS PartnerRole      // 位标志枚举
REF User(userId, userName)
HAS_ONE Partner(partnerId, partnerCode, partnerName) AS customer
```

数据类型名与约束名**大小写不敏感**（`BIGID` = `bigid`、`indexed` = `INDEXED`）；**标识符（Record / 字段 / 枚举成员）严格大小写敏感**，按 [`naming.md`](../naming.md)（✔ 2026-09-26 已裁，「`errata.md` 二-6」清零，见 §1）。

> ✔ **枚举在存储层 = 整型（✔ 2026-09-26 作者：「枚举在存储层我们是存储的整型值，不是字符串，我考虑节约空间」）**：DB 里存**整数值**（取能装下全部成员值的最小整型）；**语言层绝不写 `1` / `2` / `3`，一律写成员名**（✔ 作者：「但是到了语言层面，肯定不能写 1，2，3，要用 enum」）。
>
> ✔ **`default` 认两态（✔ 2026-09-26 作者：「定义的时候 `NONE = 0`，那么 `default 0` / `default NONE` 你能不能都认？」→ **都认**）**：`default 0` 与 `default NONE` **都认**（等价；`mmda fmt` 归一写成员名 `default NONE`）；**`NONE = 0` 是本语言约定**（`MetaEnumMember` 默认 `0`）。
>
> ✔ **呈现串 = `value;name;label;color;icon`（✔ 2026-09-26 作者：「`text` => `label`」）**：枚举成员呈现串第 3 段段名 = **`label`**（不是 `text`）；**`label` / `color` / `icon` 是呈现信息、不进业务数据**；**`description` 不进 JSON**（改走**类似 SQL 注释的存储侧注释**）；元数据 JSON 顶层带 **`locale`**、按 locale 分片（见 [`enums.md`](../guide/enums.md)）。

---

## 13. 相关

- [records.md](records.md) — 字段与对象
- [meta-model.md](meta-model.md) — Field 元模型
- ](../errata.md) — 待裁决

## 14. 诊断码（末节码表 —— 载体已定、码位后一步）

> ✔ **载体（2026-09-26 作者批注：「末节码表」）**：码表**放本文件末节**（不另开 `doc/diagnostics.md`）；**码位编号后一步再细化**（作者：「**诊断码后一步，我还没能搞这么细**」—— 见 §11.4 尾注四）。
>
> **现文已引用的码（暂定，未定稿）**：

| 码 | 含义 | 现状 |
| --- | --- | --- |
| `M0101` | 非法数值字面量（原八进制 `0o755` 已撤） | 暂定（§1 / §3 / §11.4 尾注四） |
| `M0102` | 布尔字面量非 `0` / `1` | 暂定（§2） |
| `M0206` | 标识符与关键字同形（含 `@` 逃逸不可用） | 暂定（§1） |
| `M07xx` | 目标端表达不了的**降级**（Profile 可关；≠ 轴越界） | 区间（§11.3-3） |
| （待补） | 枚举 / 标量数组字段 → 解析期 error | 待定（§10 / §11.4 尾注二） |
| （待补） | `BitVector(n)` 的 `n` 非 8 的倍数 / 超上限 128 | 待定（§7） |
| （待补） | 对非空类型写 `null` / `= null` | 待定（§1 / [`statements.md`](/statements.md §2） |
