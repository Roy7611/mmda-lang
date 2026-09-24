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
| 大小写 | 不敏感 | `BYTE` = `Byte` = `byte` |

> ⚠️ **待裁决**：早期文档还出现过 `varchar?[30]`、`char[11]` 两种方括号写法，与实际语料的 `varchar(80)` 不一致。建议统一为 `type(size)` + 尾部 `?`（`varchar(80)?`），见 [`errata.md`](errata.md) 冲突 5。

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

> ⚠️ `BIGID`（早期文档与语料均出现）是 `bigint` 的别名还是错字，待裁决，见 `errata.md` 二-6。

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
