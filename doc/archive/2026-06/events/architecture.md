# 事件驱动架构

IoT 与 MES 需要监听设备状态与作业任务；状态变化或动作完成时发布事件，由 Handler 执行业务逻辑。  
事件总线（Event Bus）粘合组件；订阅方可按主题、类型、地理位置等**过滤**感兴趣的事件。  
事件处理应**异步**，避免阻塞系统响应。

从架构维度，**事件流必须可图形化**（DFD），使隐藏在代码中的逻辑可维护、可修改。

## 1. 优势

1. **松耦合**：发布者与订阅者仅通过事件媒介交互。
2. **异步性**：发布者不等待处理结果。
3. **核心模型**：观察者模式在架构层的应用。

## 2. 参考标准

- [SDL](https://creately.com/guides/what-is-a-sdl-diagram/) — 实时事件驱动系统
- IEC 61499 — 工业自动化事件驱动
- UML 状态图 — 事件驱动状态切换
- [AsyncAPI](https://www.asyncapi.com/)
- [Event-Driven Architecture](https://martinfowler.com/eaaDev/EventCollaboration.html)

## 3. 消息 vs 事件

事件与消息都是数据；事件通过消息传递。

| 概念 | 侧重 |
|------|------|
| Message | 技术层：Sender/Receiver、Producer/Consumer |
| Event | 业务层：Publisher/Subscriber、「发生了什么」 |

MMDA **基于事件建模，基于消息实现**。

典型链路：

```
Event / 定时 Tick
  → Trigger
  → Message → Channel
  → Consumer → Handler (Service)
```

## 4. 经典模式

### 4.1 消息驱动

- **Endpoint / Sink**：沉淀、存储、推送
- **Trigger**：事件源（Event Source）

### 4.2 领域事件溯源（Domain Event Sourcing）

运行时状态变更序列化为**领域事件日志**，支持重播。  
重播需记录变更前快照与增量，保证**幂等**。

> 与 **Design Change Log**（设计时元数据变更）严格区分。

### 4.3 事件协同（Event Collaboration）

组件状态变更时发布事件，新消费者可独立接入，不影响原有配置。

## 5. Event 结构

| 字段 | 说明 |
|------|------|
| Id | 唯一标识 |
| Type | 事件类型 |
| Timestamp | 发生时间 |
| Lifecycle | 过期策略（如托盘离开即销毁） |
| Source | 生产者：应用、定时器、设备 |
| Message | 人类可读描述 |
| Payload | 关联数据 |

## 6. Event Bus

- **路由**：按类型、主题、过滤器分发
- **Event Queue / Stream**：队列或流式（RabbitMQ、Flink 等）
- **Filter + Time Window**：限流、去重（如托盘进入事件不可重复）
- **Event Log**：查询、监控、重播
- **可靠投递**：Exactly Once、失败队列、重试、超时、人工重播

## 7. 术语分层

| 术语 | 层级 | 关注点 |
|------|------|--------|
| Subscriber | 业务/主题 | Receive、Match、路由规则 |
| Consumer | 消息配置 | 频道订阅 |
| Listener / Handler | 代码实现 | 类型安全、回调、事务 |

## 8. Action 与 Event

架构设计阶段在 Record 上定义 `@Action`；动作可触发 `@Event`。  
Handler **实现**留给工程师或 AI；Architect 生成接口骨架。

## 9. MES / 物流场景

- 托盘抵达：触发一次且仅一次入库动作
- 状态变化：系统重启不丢失
- 上位机漏脉冲：可模拟补发事件

## 10. 相关

- [language.md](language.md) — M语言 事件声明
- [../language/behaviors.md](../language/behaviors.md)
- [../architect/diagrams.md](../architect/diagrams.md)
