# 数据类型

> 合并早期 `datatypes.md` 与上一轮 `language/types.md`（原文留档 `archive/2026-06/`）。
> 立场：**逻辑类型语言无关**——元模型只存逻辑类型名/编码，跨语言与跨数据库的映射由 Codegen Profile / 方言表承载。

---

## 1. 写法约定

| 规则 | 写法 | 说明 |
| --- | --- | --- |
| 可空 | 后缀 `?` | `decimal?`、`bigint?`（采用 C# 的表达方式） |
| 长度 / 精度 | 括号参数 | `decimal(18,3)`、`varchar(100)`（采用数据库的表达方式） |
| 组合 | `decimal?(18,3)` | 可空、精度 18、小数 3 的定点小数 |
| 大小写 | **不敏感** | **类型名与约束名一律大小写不敏感**：`BYTE` = `Byte` = `byte`、`BIGID` = `bigid`、`indexed` = `INDEXED`、`@Ref` = `@ref` —— ✔ 2026-09-25 作者裁：「**类型一律大小写不敏感，包括那些约束，这个跟 SQL 类似**」；**标识符（对象名 / 字段名）不在其列**，按 [`naming.md`](naming.md) 的大小写约定（类 PascalCase、字段 camelCase） |

> ✔ **已裁（2026-09-25，取语料形态）**：**长度一律 `type(size)`、可空一律尾部 `?`** —— `varchar(80)?`、`char(11)?`、`decimal(18,3)?`；早期文档的 `varchar?[30]`、`char[11]`、`varchar?(30)` **标为历史、不进词法器**。**容量与可空各司其职**：`(size)` 管容量、`?` 管可空，不混进方括号（见 [`errata.md`](errata.md) 冲突 5）。

---

## 2. 布尔

`bool` / `bit`；常量 `true` / `1`、`false` / `0`。

---

## 3. 整型

吸取 Rust / C# 的习惯，兼顾 PLC 场景（设备侧常用 `byte` / `WORD` / `DWORD` / `LWORD`）。

### 无符号（以 u 开头）

| 类型 | 别名 | 位宽 | 典型数据库类型 |
| --- | --- | --- | --- |
| `uint8` | `u8`、`byte` | 8 | `tinyint unsigned` |
| `uint16` | `u16`、`ushort`、`WORD` | 16 | `smallint unsigned` |
| `uint24` | — | 24 | `mediumint unsigned` |
| `uint32` | `u32`、`uint`、`DWORD` | 32 | `int unsigned` |
| `uint64` | `u64`、`ulong`、`LWORD` | 64 | `bigint unsigned` |
| `uint128` | `u128` | 128 | 未来支持（Rust 有该类型） |

### 有符号（以 i 开头）

| 类型 | 别名 | 位宽 | 典型数据库类型 |
| --- | --- | --- | --- |
| `int8` | `i8`、`sbyte` | 8 | `tinyint` |
| `int16` | `i16`、`short` | 16 | `smallint` |
| `int24` | — | 24 | `mediumint` |
| `int32` | `i32`、`int` | 32 | `integer` |
| `int64` | `i64`、`long` | 64 | `bigint` |
| `int128` | `i128` | 128 | 未来支持 |

> ⚠️ 无符号有两套写法并存：前缀式 `uint64` 与后缀式 `decimal(19,4) unsigned`，见 `errata.md` 二-8。

---

## 4. 小数

| 类型 | 说明 |
| --- | --- |
| `decimal` / `numeric` | 定点小数，可定义 (`precision`, `scale`) |
| `float` | 32 位浮点（`f32`） |
| `double` | 64 位浮点（`f64`） |
| `real` | 支持科学计数法表示的浮点 |
| `money` | 货币（Profile 可映射为 `decimal(19,4)`） |

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

---

## 6. 字符串

| 类型 | 说明 |
| --- | --- |
| `char` / `varchar` | 单字节；可定义 `size`（每字符单字节） |
| `nchar` / `nvarchar` | Unicode；可定义 `size` 与 `charset` |
| `string` | 等价 `nvarchar(255)` |
| `BitStr` | 位串，字符只能包含 `0`/`1`（如 `01011100`），等价 `BitStream` |
| `uuid` | 128 位通用唯一标识 |
| `inet4` / `inet6` | IP 地址 |

语义上字符串即 `char[]` / `nchar[]`：`size` ≥ 1，默认最大容量 **2000**（可由 Profile 调整）；可指定字符编码 `charset`。

> ✔ **已裁（2026-09-25）：`BIGID` 既不是 `bigint` 的别名、也不是错字 —— 它是自有类型**（位布局同日补定：**高 28 位 tenantId + 低 36 位 realId**，见本节末）：**本身即 partitionID（分区主键），高位存 tenantId**（作者原话：「**另外 bigid 是我们特有的定义，就是指本身是 partitionID，高位存 tenantId**」）。与 `@PartitionID` / `MetaObject.partitionKey` / `minID`·`maxID`（[`meta-model.md`](meta-model.md) §5、[`design-notes.md`](design-notes.md) §8.3）同属**多租户主键**机制。**位布局（✔ 2026-09-25 已定）**：**高 28 位 = tenantId、低 36 位 = realId** ——
>
> ```
> MAX_TENANT_ID = 0x7FF_FFFF    // 高 28 位是租户 id（上限 2^27−1 → bit 63 恒 0、ID 恒为正 long）
> MAX_REAL_ID   = 0xF_FFFF_FFFF // 低 36 位是实际 id（上限 2^36−1 ≈ 687 亿）
> parseTenantID(partitionId) = partitionId >>> 36
> buildEntityID(tenantId, realId) = ((tenantId & MAX_TENANT_ID) << 36) + (realId & MAX_REAL_ID)
> ```
>
> **0 = 无租户**（`NO_TENANT_ID = 0`，平台公共数据）、`MIN_TENANT_ID = 1`；**realId 由分布式唯一 ID 生成器产出、由底座合成完整 ID**（不是数据库生成）。**生成方**：底座 / 应用侧（`buildEntityID`），**不是 DB**。**真源**：`D:\2026\java` 的 `Tenancy.java:15-19 / 42-44 / 85-103`；相关的 `partitionKey` / `minID` / `maxID` 见 [`meta-model.md`](meta-model.md) §5 与 [`design-notes.md`](design-notes.md) §7.2。**底座落地用例（同一份扫描实测）**：`TenancyEntityRepository.java:100 / :552 / :585` 与 `SqlQuery.java:1270` 都走 **`Tenancy.buildEntityID(...)`** 合成与过滤实体 ID（配合 `getMinEntityID` / `getMaxEntityID` 做**分区范围查询**）—— 即 **`BIGID` 不只是主键类型，也是多租户查询的过滤口径**（租户维度的隔离直接落在主键高 28 位上）。**✔ 租户位宽已确认（2026-09-25，作者原话：「27位没错」）**：**高 28 位字段中 27 位有效（`MAX_TENANT_ID = 0x7FF_FFFF` = 134,217,727，bit 63 保留恒 0）** —— 不是笔误，ID 恒为正 `long`。旧 javadoc 里的「48bits 实际的 id」= 16+48 旧布局残留，**以常量为准**。
>
> **语料形态与 `BIGID` 的关系（实测补正）**：`BIGID` 这个名字**只出现在早期文档**（全语料 case-insensitive `bigid` **0 命中**）；语料写的是 ——
>
> ```
> record Address {
>     @PartitionID [10000,0x000F_FFFF]      // 独占一行（字段级注解）
>     addressId uint64 identity generated readonly,
> ```
>
> 即 **分区主键 = 带 `@PartitionID` 的 `uint64 identity` 字段**（语料 `uint64 identity` **102 处**、`identity generated` 16 处）；`[min, max]` 是**该对象在 realId 空间里领的区间**（示例统一为 `[10000, 0x000F_FFFF]`，186 个文件）—— 与 `MetaObject.minID`/`maxID`、`getMinEntityID`/`getMaxEntityID` 一一对应，**realId 不是整段给一个租户，而是每个对象领一段**。**为什么要分段 = 标识共享**（作者原话「**有时候我需要多个表 UNION 成视图，不想 id 冲突，所以分段**」）：一组要 UNION 成视图的表各领一段 → 视图主键天然不冲突；段划分、六个标识共享组与语料逐段对照见 [`records.md`](records.md) §2.3。**✔ 已裁（2026-09-25，作者）**：**`BIGID` 保留为语言类型**，**等价于 `uint64 identity partitioned`**——
>
> - `uint64` = 类型；`identity` = 由底座生成（分布式唯一 ID）；
> - **`partitioned` = 分区标记**（既有元对象属性 `MetaObject.partitioned`：**物理表分区 + 按租户 / 段隔离查询**）；
> - **分段（`minId` / `maxId`）不在字段上逐表写死，而是在元对象上配置** —— 即 `MetaObject.minID` / `maxID`（[`meta-model.md`](meta-model.md) §5）；
> - **`minId` / `maxId` 是「真实 id」（realId）的范围** —— **去掉租户标识之后的那部分**（比较前先 `getRealID(id) = id & MAX_REAL_ID`，`Tenancy.java:95-97`）。
>
> **段的分配主体 = 架构师 / 设计师**（✔ 2026-09-25 作者：「**段是架构师、设计师分配阿**」）—— 工具只校验不自动分配，见 [`records.md`](records.md) §2.3 与 [`workflows.md`](workflows.md) §1。
>
> 因此语料那两行（`@PartitionID [10000,0x000F_FFFF]` + `addressId uint64 identity generated readonly,`）与 M 语言的 `BIGID` **是同一件事的两种写法**；**⏳ 仍待你定**：只剩**大小写敏感面**（类型名不敏感 / 标识符敏感，助手建议类型名不敏感）。—— 见 [`errata.md`](errata.md) §二-6。

---

## 7. 位集合与二进制

| 类型 | 说明 |
| --- | --- |
| `BitSet` / `BitVector` / `BitArray` | 位序列，三者类似；设备中常把 `byte`、`word` 当位元序列用，因此有 `BitVector8` ~ `BitVector64` |
| `byte` | 无符号字节，等价 `uint8` |

整型在 PLC / IoT 场景可视为 `BitVector` / `BitArray` 的底层存储。

> ⚠️ BitSet 的底层宽度、`b0000` 位字面量、加成员是否变更存储宽度，待裁决，见 `errata.md` 二-5。

---

## 8. 大对象与结构化

| 类型 | 说明 |
| --- | --- |
| `blob` / `byteArray` | 二进制（图片、文件） |
| `json` / `jsonb` | JSON 文本 / 二进制 |
| `clob` / `text` | 文本大对象（`tiny/medium/long text` 由 Profile 映射） |

对象可带 `mediaType` / `format` 提示（如 `image/png`）。

---

## 9. 流（Stream）

数据流分为字节流与字符流：

| 类型 | 写法 | 等价 |
| --- | --- | --- |
| `ByteStream` | `byte*` | `Blob` |
| `CharStream` | `char*` | `Clob` |
| `NCharStream` | `nchar*` | `NClob` |

---

## 10. 数组

```sql
var arr int[];
var s = r[2..];     // 切片
var a = [0..20];    // range
```

Record 字段上的数组语法尚未规范化（详见 [statements.md](statements.md)）。

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

## 12. 关系与枚举不做新类型

关系 DSL 只引用 Record / Enum，不引入新类型：

```
ENUM OrderStatus
ENUMS PartnerRole      // 位标志枚举
REF User(userId, userName)
HAS_ONE Partner(partnerId, partnerCode, partnerName) AS customer
```

数据类型大小写不敏感；**标识符是否敏感尚未定义** → 待裁决（`errata.md` 二-6）。

---

## 13. 相关

- [records.md](records.md) — 字段与对象
- [meta-model.md](meta-model.md) — Field 元模型
- [errata.md](errata.md) — 待裁决
