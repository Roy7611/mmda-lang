# 语句、表达式与行为

> 本文接纳早期文档中「吸收其他语言的表达方式」与行为层设计，以及上一轮 `language/expressions.md`、`language/behaviors.md` 的内容（原文留档 `archive/2026-06/`）。

---

## 1. 声明与语句

```sql
var arr int[];              // 类型在右
declare b int[];            // declare 与 var 同义

var i int32[] = {0, 1, 2};
var r = range(30);
var s = r.slice(0, 10);     // 切片（C# 风格）
var s1 = r[2..];            // r[..3]、r[1..10]
var a = [0..20];            // range(20)
```

- 冒号 `:` 读作「是」（声明），等号 `=` 读作「等价」（赋值）。
- `*` 表示 0 或多个。

### 记录与元组

记录与元组都对应数据库中的一行，也是线性代数里的一维向量；与 `struct` 同义。**不需要 `class`**：对象只是文件/库中的实体，有 `struct` 足够。字段默认具备 getter/setter 语义，不写样板代码。计算字段用 `@Computed` 表达式；属性变更需要触发时用 `@trigger` 触发事件（`@Event`）。

```sql
var t (value int, name string) = (1, "OK");
```

### Map

`Map<K,V>` 视为 `record<K,V>`（二元组），第一个元素默认是 key。C# 的 `Dictionary` 是它的接口形态。

### 引用传递

只用 `&` 表示引用传递，不引入 `*` 传参这类歧义写法。

---

## 2. 表达式与模式匹配

### Lambda 与箭头

| 符号 | 用途 |
| --- | --- |
| `=>` | Lambda、映射、switch 臂 |
| `->` | **仅**状态转移 |

### switch 表达式（C# 风格）

```csharp
var s = expr switch {
    is string => 'a string',
    is int i when i > 0 => 'great',
    is Point p when p.x >= 0 && p.y >= 0 => 'positive position',
    _ => 'default'
};
```

相比 `switch/case/break/default`，逗号表达「停顿但不结束」，条件表达式贴近 SQL 的自然语言感。

### 类型判断与转换

```dart
var b = a is Number n;   // is 同时承担 typeof 与 instanceof
var c = a as Point?;     // as 转换；尾无 ? 则失败抛异常
```

> ⚠️ `as` 在声明（字段别名、join 别名）中是**起别名**，其他上下文是**类型转换**——同一关键字三种词义，见 [`errata.md`](../errata.md) 二-7。

### 空值（`null`）

- **只有一个空值 = `null`**（= SQL `NULL`）；**TS 的 `undefined` 视为同一空值、不进 m 语言**（[`datatypes.md`](datatypes.md) §1）；
- **比较**：`is null` / `is not null`（SQL 风格）；**`= null` / `<> null` = 校验期 error**（SQL 里最常见的一类静默错误，工具必须拦）；
- **三值逻辑沿用 SQL**：`1 = null` → **UNKNOWN**（不是 `false`）；`if` / `switch when` 条件遇 UNKNOWN 视为**不成立**（与 SQL `WHERE` 同口径）；
- ✔ **兜底函数（2026-09-26 定稿 —— 作者：「可以」）**：**`coalesce(a, b, …)` = 规范形态**（SQL 标准多参、≥ 2 参，取**第一个非 `null` 值**）；**`ifnull(a, b)` = 二元等价写法**（语料实测 `IFNULL(costPrice,0)`，保留；**两者只归一大小写、不互改写法** —— 语料里 `IFNULL` 在用的地方就让它继续用）；
- ✔ **结果可空性（写死，进一致性用例）**：**只要至少一个实参是非空类型，结果就是非空类型**（`coalesce(costPrice, 0)` ⇒ 非空 `decimal`）；**全部实参可空 ⇒ 结果可空**（`coalesce(a?, b?)` ⇒ `T?`）；**实参类型必须一致或可隐式提升**（`coalesce(int32, decimal(18,2))` 合法、`coalesce(int32, 'x')` = 校验期 error）；
- ✔ **`coalesce` 的方言映射**（由 Profile 声明，禁静默）：**`coalesce`** → MySQL / PostgreSQL / SQL Server / Oracle **都有原生 `COALESCE`**；**`ifnull`** → MySQL `IFNULL(a,b)`｜SQL Server `ISNULL(a,b)`｜Oracle `NVL(a,b)`｜PostgreSQL `COALESCE(a,b)`（[`errata.md`](../errata.md) §五-124）；
- **可空类型 = `T?`**：**`null` 只能给可空类型**（对非空类型赋 `null` / 比较 = 校验期 error）。

### 运算符与优先级（⏳ 提案 —— 待裁；口径 = 语料实测）

**语料实测**（`E:\Dev\mmda-architect\examples\mmda-mes\data\models`，**215 个语言文件 / `@Computed` 75 处**）：真实出现的运算符只有 **`*` `/` `+` `-` `(` `)` `<` `>`** 与 **`and` / `or` / `is null` / `is not null`**；**没有** `&&` / `||` / `==` / `!=` / `?: ` / `%` / 位运算 / `like`。⇒ 本表**以语料为基线**，符号类运算符按「不引入」处理（要引入的必须由作者裁）。

| 级别 | 运算符 | 结合性 | 助手提案 / 备注 |
| --- | --- | --- | --- |
| 1（最高） | 一元 `-` `+` `not` `~` | 右 | `~` 只对整型 / `BitVector` 合法 |
| 2 | `*` `/` `%` | 左 | `%` = 取余（符号跟**被除数**，SQL 标准口径） |
| 3 | `+` `-` | 左 | **`+` 不做字符串拼接**（拼接只走 `concat` / `concat_ws`） |
| 4 | `<<` `>>` | 左 | 只对整型 / `BitVector` 合法；**移位量 ≥ 位宽 = error**（不静默回绕） |
| 5 | `&` | 左 | 位与（整型 / `BitVector`） |
| 6 | `^` | 左 | 位异或 —— ⚠️ **各库语义不同**（PG 的 `^` 是幂），必须由 Profile 声明 |
| 7 | `\|` | 左 | 位或（本表里写成 `\|` 只是转义；源码就是 `\|`） |
| 8 | `<` `<=` `>` `>=` `=` `<>` `is null` `is not null` | **不可链式** | `a < b < c` = 语法错误（要求显式 `and`）；`=` 唯一 |
| 9 | `not` | 右 | |
| 10 | `and` | 左 | **保证短路**（校验器里常写 `x is not null and x > 0`，必须能靠短路保安全） |
| 11（最低） | `or` | 左 | |
| 条件 | `case when … end` / `expr switch { … }` | — | 见下节；**不引入 `?:`** |

**写法总口径（提案）**：

- **布尔 = `and` / `or` / `not`（词，小写不敏感）**；**不引入 `&&` / `||` / `!`** —— `&` 要留给位与、`|` 要留给位或，符号逻辑运算符会让「`a | b` 是位或还是逻辑或」变成靠类型猜；语料 **0 处**用符号。
- **相等 = `=`**（SQL 风格）；**不引入 `==`**；**`!=` 作输入别名**（`mmda fmt` 归一 `<>`）。
- **字符串拼接 = `concat(a, b, …)` / `concat_ws(sep, …)`**（语料实证）；**`+` 不拼接、`||` 不拼接**（`||` 在 SQL 是拼接、在 C 系是逻辑或 —— 一个符号两种语义，必须回避）。
- **空值兜底 = `coalesce` / `ifnull`**（✔ 已裁，§2 上一小节）；**不引入 `??`**。
- **数值提升沿 C# / Java 口径**（`int32 → int64 → decimal → double`），**不做字符串 ↔ 数字的隐式转换**（`'x' + 1` = 校验期 error；要拼写 `concat('x', 1)`）。

**除零 / 溢出 / 精度（提案）**：

- **整数除零 = 运行期 error**（不返回 0、不返回 NULL）；**`decimal` 除零 = error**；**`float` / `double` 除零 = `±Inf` / `NaN`**（IEEE 754，不报错 —— 与 `datatypes.md` §4 的浮点口径一致）；
- **整数溢出 = error**（不静默回绕，与「轴越界 = error」同口径）；
- `decimal` 乘法 / 除法的 `scale` 由语言层按 SQL 口径推导（`a*b` 的 scale = 两者之和），**超 `precision` 后如何落库 = 存储层行为**（✔ 已裁：舍入交存储层，§五-118）。

**方言陷阱（交 Profile + 一致性用例）**：`^` 在 PG 是幂、MySQL / SQL Server 是异或；`concat` 遇 `null`：**MySQL 返回 NULL**、Oracle / PG 当空串（**提案：语言层定「当空串」**，MySQL 侧由投影器包 `COALESCE`，否则 AI 生成的拼接公式在 MySQL 上整行变 NULL）；`%` 对负数的符号；整数 `/` 在部分库是整除。

### `case when` 与 `switch`（⏳ 一条待裁）

语料实证：`@Computed case when expectedOutput > 0 then actualOutput / expectedOutput else NULL end`（2 处）⇒ **`case` 必须在**，并与本文件上面已文档化的 C# 风格 **`switch` 表达式**并存（语义等价、`mmda fmt` **不互改**）。

- **`case`（搜索式）**：`case when <cond> then <expr> … else <expr> end`；**无 `else` ⇒ 默认 `null`**（SQL 口径）；**不引入「简单 case」**（`case x when 1 then …` —— 与搜索式重复，且容易和枚举比较混淆）。
- **`switch`**：`expr switch { is <type> <var> when <cond> => <expr>, _ => <default> }`（已文档化）。
- ⏳ **待裁（本专题唯一一条语法字裁决）**：`case` / `when` / `then` / `else` / `end` 这五个字算**语法关键字（严格小写）**，还是与 `true` / `false` 同档**大小写不敏感**（进保留表）？语料是从 MySQL 迁移来的、大写很常见；**助手推荐后者（不敏感）** —— 理由：它们**不可能被当标识符用**，硬报错只会制造无意义的迁移成本（与布尔字面量同一条判据）。

### 函数族与单位（⏳ 提案 —— 待裁）

**三层名字（本专题核心口径）**：

1. **语言层规范名**（提案，语言无关）：`coalesce` / `ifnull`、`concat` / `concat_ws`、`dateDiff(unit, a, b)`、`toDays(d)`、`timeToSec(t)`、`now()` / `today()`、`abs` / `round` / `floor` / `ceil`、`len` / `substr` / `upper` / `lower` / `trim`、聚合 `sum` / `avg` / `min` / `max` / `count`；
2. **语料实测的输入别名**（照抄 MySQL / 驼峰名，必须继续可用）：`timestampdiff` ≡ `dateDiff`、`to_days` ≡ `toDays`、`time_to_sec` ≡ `timeToSec`；
3. **各方言 / 宿主映射**（Profile 声明）：`ifnull` → MySQL `IFNULL`（**Java 侧已有方言钩子**：`MySqlMetadataProvider.java:63` `isNullFuncName()` 返回 `"IFNULL"`）｜SQL Server `ISNULL`｜Oracle `NVL`｜PG `COALESCE`；`dateDiff(MINUTE, a, b)` → MySQL `TIMESTAMPDIFF(MINUTE,a,b)`｜SQL Server `DATEDIFF(minute,a,b)`｜Oracle `(b-a)*1440`｜PG `EXTRACT(EPOCH FROM (b-a))/60`。

⚠️ **勘验结论：现在已经是「一个函数三套名」** —— Java 宿主实现（`Computable.java:22-60`）给的是 `concat` / `join` / `isnull` / `computeDays` / `computeHours`，语料写的是 `concat_ws` / `ifnull` / `to_days` / `timestampdiff`，方言侧又是 `IFNULL` / `TIMESTAMPDIFF` ⇒ **规范名必须一次定死**，否则这条漂移会一直跟着我们（与「逻辑类型语言无关」同一条立场）。

**单位字面量（语料实证）**：`timestampdiff(MINUTE, actTime, consumedTime)` —— 单位是**裸标识符、不是字符串**。提案：**单位 = 封闭小集合** `SECOND` / `MINUTE` / `HOUR` / `DAY` / `WEEK` / `MONTH` / `YEAR`（**不敏感、不加引号**）；语义写死：`DAY` / `WEEK` = 真实时长（24h × n），**`MONTH` / `YEAR` = 日历差**（`2024-01-31 → 2024-02-29` = 1 个月）—— 各库 `TIMESTAMPDIFF` / `DATEDIFF` 的差异由 Profile 对齐，**进一致性用例**。

**聚合与逐项运算的文法（并入 `errata.md` §二-10 的 ⏳）**：自然语言式 `sum(amount of each items)` **语料 0 命中**；提案 = **`sum(items.amount)` / `avg(items.quantity)` / `count(items)`**（点号 = 子表导航，与 §10 子表 + 导航集合名同源），**不引入 `of each`**；**聚合只允许出现在 `@Computed` / 视图 / 查询层**，普通字段表达式里出现 = 校验期 error。

**`now()` / `today()`**：返回**服务器本地时间**（与 `datatypes.md` §5 的时区口径一致 —— 只有 `DateTimeOffset` / `DateTimeZoned` 才带时区语义）。

### 排序（`order by`）（⏳ 提案 —— 待裁）

**现状（勘验）**：语言层**没有**排序语法（本文件 0 命中）；排序只活在运行时参数里 —— `SearchParam`（`pageNo` / `pageSize` / `sorts`，`mmda-core-api/.../web/SearchParam.java:7-10`）+ `Sort.Order = ASC / DESC` + 链式 `thenSorts`（`.../data/pagination/Sort.java` 实测）⇒ **视图 / 列表没有默认排序声明**，全靠前端传参。

**提案（三件套）**：

1. **视图 / 列表的默认排序 = 语言层声明**：视图体尾部 **`order by <expr> [asc | desc], …`**（小写关键字、与 SQL 一致；`asc` 可省、默认 `asc`）；
2. **运行时 `sorts` 参数 = 覆盖默认排序**（不叠加）：两边口径同源（都能写字段名 / 带 `asc` / `desc`；运行时是**数据**、默认排序是**声明**）；
3. **稳定排序（写死，进一致性用例）**：**语言层未显式指定 tiebreaker 时，实现必须在末尾追加主键升序** —— 否则分页会出现「同一行出现在两页 / 某行凭空消失」；这条对 AI 生成的列表页尤其重要。

**已裁的两条（本小节只是落地）**：**空值位置 = 写死「排最前」`NULLS FIRST`、不引入 `nulls` 关键字**（§五-125）；**大小写 / 重音比较（collation）交 Profile**（§五-122）。

**方言映射**：Oracle / PostgreSQL **原生** `NULLS FIRST`；**MySQL / SQL Server 没有该语法** ⇒ 投影器改写 `order by col asc` → `order by col is null desc, col asc`（`desc` 同理），**索引侧必须声明忽略或降级**（`M07xx`，禁静默）。


---

## 3. 注释与文档

| 形式 | 用途 |
| --- | --- |
| `///` | 文档注释（支持 Markdown），解释其后续元素 |
| `//` | 单行注释 |
| `/* */` | 行内说明（如解释某段调用的参数） |

- 文档里**不自造标记**：引用用 `[title](url)` 或 `[funcName]`，加粗用 `*加粗*` 或 `<strong>`（前者更简洁）。
- 文档区节用注解风格（`@remarks`、`@param`），比 C# 的 XML 简洁，与 Java 一致而更轻。
- 早期设计里把中文标签直接写进语法（如 `@Action 付款:给新订单付款`）——**建议一律走 `///` 文档注释**，见 `errata.md` 二-4。

---

## 4. 约束表达式

```sql
#ge(0)
#(d{11})
#(name@host.com)
#future
```

校验器按内置规则库解析；自定义规则在 Codegen Profile 扩展。

> ⚠️ 这套 `#` 前缀机制与命名约束关键字（`positive`、`future`、`indexed`）是否同义/并存，见 `errata.md` 二-9。

---

## 5. 行为：状态、动作与事件

行为架构描述**实体能做什么、状态如何变化、触发什么事件**，对应元模型的 `Action`（ModuleAction）、`FlowEdge`（ModuleFlow）与 Event 声明。

### 5.1 `@State`

```sql
record Order {
    @State OrderStatusChanged
    status OrderStatus default NEW indexed,
}
```

- 状态字段绑定枚举；STM 图与 `@State` 字段 + 枚举双向对应。
- 运行时变更写入 FlowTrail（若启用）。

### 5.2 `@Action`（早期文档形态）

```sql
@Action 付款: 给新订单付款
pay(NEW -> PAYED),

@Action 取消: 取消未付款订单
cancel(NEW -> CANCELED) if cancellable,
```

状态转移写法：

| 形式 | 示例 |
| --- | --- |
| 单源单目标 | `NEW -> PAYED` |
| 多源 | `NEW, DRAFT -> SUBMITTED` |
| 任意源 | `* -> ABANDONED` |
| 否定 | `!(FINISHED, CANCELED) -> CANCELED` |
| 不变 | `NEW -> NEW` |

Feature 模块（如 `M.03.001`）下的 Action 列表应与 Record 上的 `@Action` 对齐，校验器检查一致性。

### 5.3 STM 文件形态（实际语料）

```sql
/// Bom 生命周期
stm BomApproval on Bom.status {
    /// 批准
    action approve {
        transition CERTIFIED->APPROVED,
    }
    /// 弃用
    action abandon {
        transition *->ABANDONED,
    }
}
```

> ✔ **已裁（2026-09-25，取语料形态）**：**行为住独立 `.ms` 文件**（`data/stms/<模块>/<对象>.ms`，`stm BomApproval on Bom.status { action approve { transition CERTIFIED->APPROVED } }`），**不内联进 record**（见 [`errata.md`](../errata.md) 冲突 4）。理由：与「一对象一文件 + 细粒度版本控制」一致，状态图可单独图形编辑；381 文件语料已是此形态、零迁移。

### 5.4 `@Transaction` 与 `@Event`

```sql
record Order {
    @State OrderStatusChanged
    status OrderStatus default NEW,

    @Transaction
    @Event(OrderPayed)
    pay(NEW -> PAYED),
}
```

| 注解 | 含义 |
| --- | --- |
| `@Transaction` | 动作在事务中执行 |
| `@Event(Name)` | 成功后发布领域事件 |

**架构阶段只定义接口与事件名**，Handler 实现留给工程师或 AI 在 KEEP 区完成。

### 5.5 `@Computed` 与 `@trigger`

```sql
@Computed quantity * price
amount decimal(19,4),
```

- `@Computed`：计算字段，可生成 DB 计算列或应用层公式。
- `@trigger`（Phase 2）：字段变更前/后触发，可生成 DB trigger（数据库脚本天然高效、便于修改，且能借元编程生成各库方言的 `trigger`/`procedure`/`function`）。

> ⚠️ `@Computed` 的公式入口有两处写法（注解自带 vs constraint vs 行尾注释），见 `errata.md` 二-2。

### 5.6 ModuleFlow（多步流程）

单 Action 不足时用 Flow 编排：

```yaml
flows:
  - flowCode: bom-approve
    edges:
      - action: submit
        next: certify
      - action: certify
        next: approve
      - action: approve
        next: null
```

元模型字段：`actionCode`、`nextActionCode`、`sopDuration`、`multiplicity`、`fallback`。

### 5.7 权限与可执行条件

| 字段 | 说明 |
| --- | --- |
| `executableExpression` | 是否可执行（守卫） |
| `incomingTokensRequired` | 流程 token |
| `ownerOnly` | 仅所有者 |
| `allowOps` | 模块级 CRUD 位掩码 |

### 5.8 Codegen 约定

| 元数据 | 生成接口示例（语言由 Profile 定） |
| --- | --- |
| `@Action pay` | `PayOrderAction` / `doPay()` |
| `@Event(OrderPayed)` | 事件类 + 订阅接口 |
| `@State` + FlowTrail | `FlowableEntity<Status>` 类能力 |

规范只要求**可追踪到 Action 元数据**，接口名由 Profile 模板决定——**模板可定缀合方式，但不得违反 [`naming.md`](../naming.md) §1**（接口 `I` 前缀、实现类禁 `Impl`、契约名三端一致）。

---

## 6. 相关

- [records.md](records.md) — 对象与字段
- [events.md](events.md) — 事件声明与事件驱动架构
- [meta-model.md](meta-model.md) — Action / FlowEdge 元模型
- [errata.md](../errata.md) — 待裁决
