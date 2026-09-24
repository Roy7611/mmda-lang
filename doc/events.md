# 事件驱动架构

> 早期 `events.md` 全文保留（本文主体），并并入上一轮 `events/language.md` 的事件声明语法与 `events/architecture.md` 的要点（原文留档 `archive/2026-06/events/`）。
> **分工（2026-09-24）**：本文 = **语言面真源**（事件的声明、订阅语义、重放与幂等的**需求**）；**运行时与集成面真源 = [`event_bus.md`](event_bus.md)**（总线怎么装、端点怎么配、数据流怎么编、一致性怎么保、怎么监控、多租户怎么隔离）。本文 §「事件总线 / 事件流 / 事件过滤器 / 日志 / 可靠计算」讲的是**机制需求**，其**实现口径以 `event_bus.md` 为准**。

IOT 和 MES 项目中需要监听设备状态和作业任务状态，当状态改变或者设备动作完成时触发一个事件，然后执行动作。
动作可以封装为一个事件处理函数（Event Handler），执行相应的业务逻辑。

我们需要一个事件总线（Event Bus），负责粘合不同组件之间的通信。一个事件监听者组件可能只关心某个主题的事件，
甚至只关心某个地理位置点发生的事件，因此事件的发布和订阅需要加过滤条件，让监听者只接收它感兴趣的事件。

事件要支持异步和多线程，不能因为阻塞使得系统响应下降。

从架构的维度考虑，事件流需要能使用图形表达出整个系统的逻辑，隐藏在代码中的复杂性能够在设计图中一目了然。
增加系统的可维护性和可修改性。

事件驱动架构的优势：

1. **松耦合**：发布者和订阅者彼此不知晓对方存在，只通过事件媒介交互，系统易于扩展和维护。
2. **异步性**：事件的触发和处理通常是异步的，发布者发出事件后无需等待处理结果即可继续执行。
3. **核心模型**：本质是观察者模式在架构层面的应用。

参考标准：

1. [SDL](https://creately.com/guides/what-is-a-sdl-diagram/) 是一种用于描述复杂、实时、事件驱动系统行为的标准化图形语言，提供状态、信号（消息）、过程等标准化符号。
2. IEC 61499 标准 —— 看「工业自动化领域的事件驱动」。
3. UML 状态图看「事件如何改变状态」，用于描述一个实体如何根据事件在不同状态间切换。核心元素为状态（如「待支付」「已支付」）、转移（触发状态变化的事件）和动作。
4. [AsyncAPI](https://www.asyncapi.com/en)
5. [事件驱动架构](https://rk.51cto.com/article/513836.html)

## 经典模式

### 消息驱动架构

其实事件、消息都是数据，事件需要通过消息传递数据，底层都是数据流（Data Flow）。

消息（Message）有发送者（Sender）和接收者（Receiver），生产者（Producer）和消费者（Consumer），而事件（Event）有发布者（Publisher）和订阅者（Subscriber），两者类同。
消息更偏向于技术层面，而事件理解为发生一件什么事，更能在业务层面沟通和建模，因此我们基于事件架构驱动建模，基于消息实现。

消息和事件都可使用生产者（Producer）和消费者（Consumer）模式，按数据流的角度理解（**术语统一见 [`glossary.md`](glossary.md) §3.1 与 [`event_bus.md`](event_bus.md) §1.1**：MMDA 文档**统一用 Publisher / Subscriber**，Producer / Consumer 只在描述外部系统与中间件时使用）：

- 发生一个事件（Event）或者定时事件
- 触发（Trigger）一次消息（Message）传递，触发方是消息生产者（Producer）
- 至某个频道（Channel）
- 消费者（Consumer）订阅了某个频道（Channel），收到消息转交 Handler（例如某个 Service）进行业务处理
- 消费者本身是一个**端点（Endpoint）**

消息有如下概念（✔ 2026-09-24 术语统一，见 [`glossary.md`](glossary.md) §3.1）：

- **EventSource（事件源）**——流的入口；原本这里写的「触发器 Trigger 是一个事件源」已改为：**Trigger 降为 EventSource 的配置项 `on`**（`@trigger` 那个记录级数据库触发器是另一回事，别混）
- **Sink（数据汇）**——流的出口，三种投递方式：**写入 Write · 推送 Push · 调用 Call**（原来写成「端点（Sink / Endpoint）」把两个概念叠在一起了，已拆开：**Endpoint 是配置单元，EventSource / Sink 是它在图上的两个方向**）
- 处理节点统称 **Processor（处理器）**：**Validator / Converter / Filter / Aggregator**（+ Router / Splitter）——**不用 Transformer**（免得与 AI 的 Transformer 混淆）

### 事件溯源（Event Sourcing）

从软件架构的角度，事件溯源 [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html) 用来追溯一个应用程序的状态改变全过程，
将每一个状态改变封装为一个事件日志（Event Log），你可以记录应用程序对象如何抵达当前状态的全部历史。

如果考虑事件重播（Event Replay），那么事件上下文需要记录事件发生前的数据和变化的部分，例如一个账户增加了 10 元，那么需要知道账户的原值，
这样可以判断这个事件重播的前提条件，使得事件处理具备幂等性。

### 事件协同（Event Collaboration）

事件协同 [Event Collaboration](https://martinfowler.com/eaaDev/EventCollaboration.html) 指各个组件在内部状态改变时发送事件来相互通信和协作。
它的优势是使得组件之间极度松耦合，哪怕增加了新的事件消费者，不影响原先的配置和实现。

## 事件（Event）

一个事件包含唯一标识、类型、时间、事件源、消息和其他关联数据（Payload），事件的发生源于状态改变或者定时器（例如 Tick 事件）。

- Id 事件的唯一标识
- Type 事件类型，通常在编程语言中定义一个实现 Event 接口的具体类
- Timestamp 事件发生的时间点
- Lifecycle 事件的生命周期定义事件过期策略，避免在总线中过渡阻塞
- **EventSource 事件源**（原名「Source 事件的生产者或者叫触发器（Trigger）」，✔ 2026-09-24 按术语统一改名）：可以是不同的应用程序、服务、定时器、外部系统或物理设备
- Message 事件的消息描述
- Payload 关联的数据

每个事件有生命周期，过期则自动忽略，避免在总线中过渡阻塞。支持自动化物流的托盘进入触发事件、退出后事件销毁。

## 事件总线（Event Bus）

> ⚙️ **实现口径见 [`event_bus.md`](event_bus.md)**：本节及以下各节是**机制需求**（要什么），`event_bus.md` 给**架构与选型**（怎么做：概念模型 Event → Message → Data、三类集成、端点、数据流编排三张图、状态与时间语义、Outbox、多租户、监控 UI、**引擎可替换**）。**引擎裁决见其 §5**，结论：**借 Flink 的语义，不绑 Flink 的运行时**（作者原话「我更偏向 Flink 的概念」）。

组件发布事件和订阅事件都是与事件总线打交道，事件总线负责事件路由（Event Routing），将事件从发布者传递给订阅者，因此它是一个 Event Router。
事件订阅者是一个事件监听器（Event Listener）和事件处理器（Event Handler）的代码实现。在我们的术语中：

- 订阅者（Subscriber）在逻辑架构（业务/主题）层，核心动作是接收（Receive）、匹配（Match），关注路由规则、通配符过滤
- 消费者（Consumer）更偏向于消息驱动架构的概念，通常在配置中出现
- 监听器（Listener）& 处理器（Handler）在代码实现层，更关注类型安全、上下文传递、事务同步，核心动作为回调（Callback）、响应（React）

事件总线维护许多事件队列（Event Queue）或者多个事件流（Event Stream），根据事件类型、主题和事件过滤器分发事件给订阅者。

### 事件流（Event Stream）

流式计算支持或者传统的消息队列，例如 RabbitMQ、Flink 等。

### 事件过滤器（Event Filter）

有时候我们需要控制事件的可重复频率，例如总线中已经存在托盘进入事件，则不允许重复发布同类事件，在事件总线中定义策略，哪怕发布者发布了事件，
事件总线也将过滤此类事件忽略它。

事件限流需要事件过滤器和时间窗（Time Window），类似 Flink 中的流式计算，因此事件总线中会配置许多过滤器。

### 日志（Event Log）

事件总线具有日志和监控功能，日志使得应用程序事件具备可查询、监控、重播的能力，便于审计和排错。

### 可靠计算

事件发布者常常需要等待订阅者的处理结果，例如托盘抵达某个位置，必须成功处理，否则就会阻塞物流。
你必须确保事件数据 Exactly Once 成功传递，并且事件订阅者成功处理，若不成功则有待重试，超时报警等，最后可能需要人工干预事件重播。

注：Flink 有 `RocksDb`，可做到 Exactly Once。

## 事件订阅者（Event Subscriber）

### 动作（Action）

订阅者监听到事件后，进入处理阶段。因此是配置阶段（Subscribe），运行阶段（Listen & Handle）付诸行动（Action）。
Action 是架构设计层概念，出现什么事件执行什么动作，而 Command 是实现方式。

在设计时，定义可对每个对象执行各种动作，例如可支付订单，取消订单，因此我们在 `Order` 对象中提供 `pay` 和 `cancel` 操作，
我们将这两个 action 封装为业务逻辑，当然可采用 command 模式实现，使得你的业务处理过程可追溯、可逆。

至于在 `pay` 动作中需要执行哪些操作，有什么业务逻辑，留给程序员实现。架构设计阶段只定义此接口，留给工程师和 AI 的是如何实现这个接口。
这样我们可生成接口的定义，例如 `PayOrderAction`、`CancelOrderAction`。

### 回调和处理结果

如何做到 Exactly Once Callback？重试，超时控制，因此需要事件总线支持失败队列机制。
失败队列使得未处理事件能够重播，根据处理前提条件自动选择放弃还是重试，确保最终一致性和业务逻辑正确性。

物流场景：

- 托盘抵达即触发一次并且只能一次入库动作，如何可靠执行？
- 状态变化怎么捕捉而不丢失，哪怕系统重启？
- 上位机可能错过脉冲信号，系统要能模拟，触发一个事件。

---

## 事件 M 语言声明（Phase 2）

> 来源：上一轮 `events/language.md`。
> **边界（已定，`..\PLAN.md` 决策 B3）**：语言只做**声明与接口抽象**；事件总线、重放、Exactly Once 由 Java / C# 各自实现的底座承担。
> **补充（2026-09-24）**：`delivery` / `lifecycle` / `retry` 的**运行时语义**、`channel` 的 **transport 选型**、端点（内部 module 端点 / 外部端点）的**配置形态**、以及数据流的**图形化编排**（节点图 / 数据流图 / 数据映射图）见 [`event_bus.md`](event_bus.md) §6–§9；语言层**不新增**编排概念（判据：能从 module / 数据模型推导的不再声明，编排落图不落语法）。

### 1. 事件定义

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
| --- | --- |
| `source` | 事件源 Record / 字段 |
| `on transition` | 绑定 Action 或状态转移 |
| `payload` | 载荷字段投影 |
| `lifecycle` | 过期策略 |

也可由 Record 内联声明：

```sql
@Event(OrderPayed)
pay(NEW -> PAYED),
```

### 2. 频道（Channel）

```sql
channel sales.events {
    schema mes
    transport memory          // memory | redis | rabbitmq | ...
}
```

### 3. 订阅（Subscribe）

```sql
subscribe OnOrderPayed on OrderPayed via sales.events {
    handler UpdateInventory
    filter type = OrderPayed
    delivery at-least-once
    retry 3 timeout 30s
}
```

| 子句 | 说明 |
| --- | --- |
| `handler` | 处理逻辑名（生成接口，非持久化类） |
| `filter` | 事件过滤器 |
| `delivery` | `at-most-once` / `at-least-once` / `exactly-once` |
| `retry` / `timeout` | 可靠投递 |

### 4. 与 ModuleFlow 的关系

```
Action (STM 边)
  → 可选发布 Event
  → ModuleFlow 定义下一 Action（人工审批链）
  → Subscribe 触发跨模块 Handler
```

### 5. 元模型映射与 Codegen

| 语言声明 | 元模型 | Codegen 产出（Profile 示例） |
| --- | --- | --- |
| `event X` | `Event` | 事件 DTO、AsyncAPI 描述 |
| `channel C` | `Channel` | 总线 / 中间件配置 stub |
| `subscribe S` | `Subscription` | Handler 接口 + 空实现 |
| `handler H` | 生成目标名 | KEEP 区待实现 |

> ⚠️ **表达式纯度要求**：事件要能重放（见本文「可靠计算」），因此参与事件处理的表达式必须是**纯函数**——禁 IO、禁赋值、禁随机、禁隐式时间依赖，保证同一输入重复求值结果一致。

---

## 相关

- [event_bus.md](event_bus.md) — **事件总线与集成编排（底座 ESB 能力）**：概念模型 Event → Message → Data、三类集成、端点、DataFlow 三张图、DataMapper、时间与状态语义、Outbox、多租户、监控 UI、引擎选型
- [statements.md](statements.md) — 行为与状态机（`@State` / `@Action` / STM / ModuleFlow）
- [meta-model.md](meta-model.md) — Event / Channel / Subscription 元模型
- [ide/diagrams.md](ide/diagrams.md) — DFD 图形投影
