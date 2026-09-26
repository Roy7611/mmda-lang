# 行为：状态、动作与事件

## 1. 概述

行为架构描述**实体能做什么、状态如何变化、触发什么事件**。  
在元模型中主要对应 `Action`（ModuleAction）、`FlowEdge`（ModuleFlow）与 Event 声明。

## 2. @State

标记状态字段，绑定枚举类型：

```sql
record Order {
    @State OrderStatusChanged
    status OrderStatus default NEW indexed,
}
```

- STM 图 ↔ `@State` 字段 + 其 Enum
- 运行时变更写入 FlowTrail（若启用）

## 3. @Action

声明业务动作与状态转移：

```sql
@Action 付款: 给新订单付款
pay(NEW -> PAYED),

@Action 取消: 取消未付款订单
cancel(NEW -> CANCELED) if cancellable,
```

### statusTransition 语法

| 形式 | 示例 |
|------|------|
| 单源单目标 | `NEW -> PAYED` 或 `NEW=>PAYED` |
| 多源 | `NEW, DRAFT -> SUBMITTED` |
| 任意源 | `* -> ABANDONED` |
| 否定 | `!(FINISHED, CANCELED) -> CANCELED` |
| 不变状态 | `NEW -> NEW` |

箭头 `->` 专用于状态转移（区别于 lambda 的 `=>`）。

### 与 Module 的绑定

Feature 模块（如 `M.03.001` 生产订单）下的 Action 列表与 Record 上的 `@Action` 应对齐；Architect 校验二者一致。

## 4. @Transaction 与 @Event

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
|------|------|
| `@Transaction` | 动作在事务中执行 |
| `@Event(Name)` | 成功后发布领域事件 |

架构阶段只定义**接口与事件名**；Handler 实现由工程师或 AI 在 KEEP 区完成。

## 5. @Computed 与 @trigger

```sql
@Computed quantity * price
amount decimal(19,4),
```

- `@Computed`：计算字段，可生成 DB 计算列或应用层公式
- `@trigger`（Phase 2）：字段变更前/后触发事件，可生成 DB trigger

## 6. ModuleFlow（多步流程）

单 Action 不足时，用 Flow 编排：

```yaml
# actions/mes/M.01.032.flow.yaml（示例）
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

## 7. 权限与可执行条件

Action 元数据：

| 字段 | 说明 |
|------|------|
| `executableExpression` | 是否可执行（守卫） |
| `incomingTokensRequired` | 流程 token |
| `ownerOnly` | 仅所有者 |
| `allowOps` | 模块级 CRUD 位掩码 |

## 8. Codegen 约定

| 元数据模式 | 生成接口示例（Profile 自定语言） |
|------------|----------------------------------|
| `@Action pay` | `PayOrderAction` / `doPay()` |
| `@Event(OrderPayed)` | 事件类 + 订阅接口 |
| `@State` + FlowTrail | `FlowableEntity<Status>` 类能力 |

接口名由 Profile 模板决定，规范只要求**可追踪到 Action 元数据**。

## 9. 相关

- [../architect/diagrams.md](../architect/diagrams.md) — STM 图
- [../events/language.md](../events/language.md) — 事件声明
- [records.md](../../../lang/records.md)
