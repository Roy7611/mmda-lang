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

> ⚠️ `as` 在声明（字段别名、join 别名）中是**起别名**，其他上下文是**类型转换**——同一关键字三种词义，见 [`errata.md`](errata.md) 二-7。

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

> ⚠️ 行为是**内联在 record** 还是**独立 `.ms` 文件**（`data/stms/*.ms`），两批文档分叉，见 `errata.md` 冲突 4。

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

规范只要求**可追踪到 Action 元数据**，接口名由 Profile 模板决定——**模板可定缀合方式，但不得违反 [`naming.md`](naming.md) §1**（接口 `I` 前缀、实现类禁 `Impl`、契约名三端一致）。

---

## 6. 相关

- [records.md](records.md) — 对象与字段
- [events.md](events.md) — 事件声明与事件驱动架构
- [meta-model.md](meta-model.md) — Action / FlowEdge 元模型
- [errata.md](errata.md) — 待裁决
