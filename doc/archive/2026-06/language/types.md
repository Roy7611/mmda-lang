# 数据类型

MMDA 逻辑类型**语言无关**。各 Codegen Profile 通过 `DataType` 映射表转换为目标语言与数据库方言。

## 1. 写法约定

- **可空**：后缀 `?`，如 `decimal?`、`bigint?`
- **存储精度**：括号参数，如 `decimal(18,3)`、`varchar(100)`
- **组合**：`decimal?(18,3)` 表示可空、精度 18、小数 3 的定点数
- **大小写**：类型名不敏感（`BYTE` = `byte`）

## 2. 布尔

`bool` / `bit`，常量：`true`/`1`、`false`/`0`

## 3. 整型

兼顾 Rust/C# 与 PLC 习惯。

### 无符号

| 类型 | 别名 | 典型 DB |
|------|------|---------|
| uint8 | byte, u8 | tinyint unsigned |
| uint16 | WORD, u16 | smallint unsigned |
| uint24 | — | mediumint unsigned |
| uint32 | DWORD, uint | int unsigned |
| uint64 | LWORD, ulong | bigint unsigned |
| uint128 | u128 | 未来支持 |

### 有符号

| 类型 | 别名 | 典型 DB |
|------|------|---------|
| int8 | sbyte, i8 | tinyint |
| int16 | short, i16 | smallint |
| int24 | — | mediumint |
| int32 | int, i32 | integer |
| int64 | long, i64 | bigint |
| int128 | i128 | 未来支持 |

## 4. 小数

| 类型 | 说明 |
|------|------|
| decimal / numeric | 可指定 precision、scale |
| float | 32 位浮点 |
| double | 64 位浮点 |
| real | 科学计数法浮点 |
| money | 货币（Profile 可映射为 decimal(19,4)） |

## 5. 日期与时间

| 类型 | 说明 |
|------|------|
| Date | 年、月、日（yyyy-MM-dd） |
| Time | 时、分、秒；precision 0–7（小数秒） |
| DateTime | 日期+时间；precision 默认 0 |
| DateTimeOffset | 带 UTC 偏移的日期时间 |
| DateTimeZoned | 带偏移与时区 ID |
| Timestamp | 时间戳；precision 0–9（默认 9） |

**时区**：存储统一 UTC 或项目约定时区；展示层转换。

## 6. 字符串与网络类型

| 类型 | 说明 |
|------|------|
| char / varchar | 单字节；size、charset |
| nchar / nvarchar | Unicode |
| string | 等价 `nvarchar(255)` |
| BitStr | 位串 `0`/`1` |
| uuid | 128 位通用唯一标识 |
| inet4 / inet6 | IP 地址 |

字符串语义：`char[]` / `nchar[]`，`size` ≥ 1，默认 max 2000（Profile 可调整）。

## 7. 位集合与二进制

| 类型 | 说明 |
|------|------|
| BitSet / BitVector / BitArray | 位序列；设备场景常用 |
| BitVector8 ~ BitVector64 | 固定宽度位向量 |
| byte | 无符号字节，同 uint8 |

整型在 PLC/IoT 场景可视为 BitVector / BitArray 的底层存储。

## 8. 大对象与结构化对象

| 类型 | 说明 |
|------|------|
| blob / byteArray | 二进制（图片、文件） |
| jsonb / json | JSON 二进制或文本 |
| clob / text | 文本大对象（tiny/medium/long text 由 Profile 映射） |

对象可带 `mediaType` / `format` 提示（如 `image/png`）。

## 9. 流（Stream）

| 类型 | 等价 |
|------|------|
| ByteStream / byte* | Blob |
| CharStream / char* | Clob |
| NCharStream / nchar* | NClob |

## 10. 数组与切片（Phase 2）

```sql
var arr int[];
var s = r[2..];    // 切片
var a = [0..20];   // range
```

Record 字段上的数组语法在 Phase 2 规范化。

## 11. 跨语言映射（示例）

逻辑类型 → 映射由 Codegen Profile 携带，元模型只存 `dataType` 编码或名称。

| 逻辑 | C# | Java | Rust | PostgreSQL |
|------|----|----|------|------------|
| uint32 | uint | long | u32 | integer |
| decimal(18,3) | decimal | BigDecimal | rust_decimal | decimal |
| string | string | String | String | varchar |
| bool | bool | boolean | bool | boolean |

完整映射表存于项目 `schemas/datatypes.json` 或 Profile 包内。

## 12. FieldRef 中的类型

关系 DSL 不引入新类型，只引用 Record/Enum：

```
ENUM OrderStatus
ENUMS PartnerRole
REF User(userID, userName)
```

见 [records.md](../../../lang/records.md)。
