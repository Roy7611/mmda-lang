# 事件 M语言 声明

> Phase 2 语法 · 与 Record 行为层衔接

## 1. 事件定义

```sql
event OrderPayed {
    source Order.status
    on transition NEW -> PAYED
    payload {
        orderId,
        orderNo,
        totalAmount,
        customerId
    }
    lifecycle duration 24h
}
```

| 子句 | 说明 |
|------|------|
| `source` | 事件源 Record/字段 |
| `on transition` | 绑定 Action 或状态转移 |
| `payload` | 载荷字段投影 |
| `lifecycle` | 过期策略 |

也可由 Record 内联声明：

```sql
@Event(OrderPayed)
pay(NEW -> PAYED),
```

## 2. 频道（Channel）

```sql
channel sales.events {
    schema mes
    transport memory          // memory | redis | rabbitmq | ...
}
```

## 3. 订阅（Subscribe）

```sql
subscribe OnOrderPayed on OrderPayed via sales.events {
    handler UpdateInventory
    filter type = OrderPayed
    delivery at-least-once
    retry 3 timeout 30s
}
```

| 子句 | 说明 |
|------|------|
| `handler` | 处理逻辑名（生成接口） |
| `filter` | 事件过滤器 |
| `delivery` | `at-most-once` / `at-least-once` / `exactly-once` |
| `retry` / `timeout` | 可靠投递 |

## 4. 与 ModuleFlow 的关系

```
Action (STM 边)
  → 可选发布 Event
  → ModuleFlow 定义下一 Action（人工审批链）
  → Subscribe 触发跨模块 Handler
```

## 5. 元模型映射

| M语言 | 元模型 |
|------|--------|
| `event X` | `Event` |
| `channel C` | `Channel` |
| `subscribe S` | `Subscription` |
| `handler H` | 生成目标名，非持久化类 |

## 6. Codegen 产出（Profile 示例）

- AsyncAPI 描述文件
- 事件 DTO 类
- Handler 接口 + 空实现
- 内存总线或消息中间件配置 stub

## 7. 相关

- [architecture.md](architecture.md)
- [../language/behaviors.md](../language/behaviors.md)
