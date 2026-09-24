# 事件总线与集成编排（底座 ESB 能力）

> 版本 0.1 · 2026-09-24 · 真源：**运行时与集成面**（总线、端点、数据流编排、一致性、运维）
> **与 [`events.md`](events.md) 的分工**：`events.md` 管**语言面**（`event` / `channel` / `subscribe` 的声明与语义）；本文管**运行时与集成面**（总线怎么装、端点怎么配、数据流怎么编、一致性怎么保、怎么监控）。`events.md` §「事件总线 / 事件流 / 事件过滤器 / 日志 / 可靠计算」几节讲的是**机制需求**，其**实现口径以本文为准**。
> **已裁前提（沿用，不在本文重开）**：① **B3 —— 事件层由 Java / C# 各自实现底座，m 语言只抽象接口**（[`..\PLAN.md`](..\PLAN.md) §0）；② **内核（Rust）不重造总线**（`..\PLAN.md` §1.2 反面清单：「❌ 事件总线、重放、Exactly Once 由 Java/C# 底座实现」）；③ **微服务 / 容器化 / 热插拔 = 部署方式，不进语言层**（[`vision.md`](vision.md) §5.3）；④ **API 边界 = module 边界 = 权限边界 = 文档分组边界**（[`api.md`](api.md) §1.1）；⑤ **业务功能模块插件 = `module`，不新造概念**（[`runtime.md`](runtime.md) §7）。

**作者口径（原话，2026-09-24）**：

> 「现在说说事件编程和消息驱动架构，这个涉及消息总线，事件流。我一直想让 mmda 底座提供 ESB 的能力，将最终的集成能力大幅提升，减少集成成本。最终效果是**只要配置就能基本覆盖 80% 的 API 接口集成**。」
> 「底层传输的都是数据，本质还是数据流」「**API 是端点，可配置接入**」「**可定制插件，提交运行，待解决多租户问题，借助插件体系增加扩展点，发布事件**」「**外部 Endpoint 可配置，事件能通知外部系统**」「**入/出可监控、有日志，有自己的 UI**」「**数据转换可借助 DataMapper 实现可配置**（关于数据的校验、过滤、转换、计算后面单独讨论）」「**需要可编排**，例如到货通知，去抓取没有的物料信息…」
> 「java 里我看好 Flink：有 RocksDb，有 Time Window 和 Watermark，做到 Exactly Once，而 Spring Integration 需要自己管 Message Store。」
> 「**Event → Message → 数据 Data**，事件会发送消息，消息附带数据 Payload，这个概念是我们的理解。」「事件总线是 mmda 底座的重要能力，能把内部和外部的 API 接口配置成端点 Endpoint，通过**图形化的节点图、数据流图、数据映射图**来定义数据流（DataFlow），即 API 的编排能力。」「我更偏向 Flink 的概念，适合未来开发 IOT、实时数据流监控等。」

---

## 0. 一句话与边界

**一句话**：MMDA 的 ESB 不是「再装一个总线中间件」，而是**把 module 边界自动变成端点、把集成逻辑变成可评审的数据流图**——端点是**推导物**，编排是**图**，总线是**底座能力**。

**边界（反面清单，防止 ESB 变成第二个真源）**：

| ❌ 不做 | 理由 |
| --- | --- |
| 不做中心化服务注册 + 治理 ESB（传统 XML 总线那一套） | 端点从 module 边界**推导**，注册表是**产物**；真源仍是项目目录 |
| 不把集成逻辑写进语言语法 | 判据（已裁）：**凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍**；编排是**新增信息**，落**图与配置**，不落核心语法（§7.2） |
| 不让外部工具（YApi / Apifox / Swagger / Postman collection）成为真源 | 已裁（[`api.md`](api.md) §7）：**外部 collection 不进真源**，只作**消费者与对账对象** |
| 不承诺「零代码覆盖一切」 | 目标是**覆盖率指标**（§3），有明确的**必须写代码**清单（§3.3） |
| 不在 Rust 内核里实现运行时 | 内核只产**契约与 IR**；装载与执行在各端底座（§4.3） |

---

## 1. 概念模型：Event → Message → Data

作者给的三层是本节的骨架，且**与既有标准对齐**（不自造词）：

| 层 | 是什么 | 谁定义 | 形态 |
| --- | --- | --- | --- |
| **Event** 事件 | **业务上「发生了一件事」**——语言层可声明、可建模、可被业务方读懂 | m 语言的 `event` 声明（[`events.md`](events.md) §「事件 M 语言声明」） | 事件名 + Type + Timestamp + Source + Lifecycle + Payload 投影 |
| **Message** 消息 | **传输单元**——总线只认它（Spring Integration 的 `Message` = **Header + Payload**，本文沿用该结构，不自造） | 运行时：由事件**投递时生成** | Header（`messageId` / `eventId` / `tenant` / `correlationId` / `traceId` / `occurredAt` / `contentType` / `delivery` / `retryCount`）+ Payload |
| **Data** 数据 | **载荷本体**——就是数据模型里的字段值（含映射后的外部形态） | 元数据：Record / View / Enum（[`records.md`](records.md)） | JSON / 行集 / 文件块 / 设备帧 |

**关键不变量**：

1. **事件是业务语义，消息是部署语义**：同一个事件可以被多个 Channel 投递成多条消息（不同协议、不同 payload 投影）——**事件与消息是 1:N**，作者原话「事件会发送消息，消息附带数据 Payload」正是这个意思。
2. **Payload 是数据模型的投影**，不是手写 DTO：投影字段来自 `payload { ... }` 子句（已裁：不造 DTO 概念，见 [`api.md`](api.md) §1）。
3. **幂等键 = `eventId`**：所有汇端（`EventSink`）的幂等都靠它，**这是 exactly-once 口径的落点**（§9.3）。

### 1.1 术语统一（先读这一节，别让名字骗了你）

**命名真源 = [`glossary.md`](glossary.md) §3.1**（作者 2026-09-24 裁：认同 `Validator` / `Converter` / `Filter` / `Aggregator` / `Endpoint` / `Channel` / `EventSource`；**「我不用 Transformer，免得与那个 AI 的 Transformer 架构混淆」**）。本节只讲**这些名字站在流的哪个位置**：

```
EventSource ──▶ Channel ──▶ Processor ──▶ Channel ──▶ EventSink
  事件源          通道       Validator                 数据汇
  (入端点)                   Converter                 (出端点)
                             Filter
                             Aggregator
                             Router / Splitter
        ↑                          ↑                       ↑
   Endpoint(入)  ── 配置 ←── DataMapper（字段级映射，不是节点）──  Endpoint(出)
```

| 你从别处学到的词 | MMDA 里叫什么 | 为什么 |
| --- | --- | --- |
| Flink `Source` / SI `Inbound Channel Adapter` | **EventSource（事件源）** | 入口永远是「产生了什么事件」；实现按 `kind`（设备/定时/回调/CDC/文件/消息/进程内）分 |
| Flink `Transformation` | **Processor（处理器）** 的四个具体类 | 一个含糊的上位词不如四个能配置的节点：**Validator / Converter / Filter / Aggregator**（+ Router / Splitter） |
| SI `Transformer` | **Converter（转换器）** | **Transformer 与 AI 的 Transformer 冲突**；且 Converter 在 MMDA 里**本来就有**（`.mc` / `flow/converters/`） |
| SI `Channel Adapter` | **Endpoint（端点）** | Adapter 词太泛（UI 适配器、图形适配器都叫 Adapter）；端点同时是**配置单元** |
| Flink `Sink` / SI `Outbound Channel Adapter` | **EventSink（数据汇）**（**✔ 已裁 §15-8：正式名由 `Sink` 改为 `EventSink`，与 `EventSource` 对称**） | 你原话「数据沉淀、存储、再推送」→ 三种**投递方式**（Write / Push / Call），不是三个概念 |
| Spring 的 `Message Channel` / Kafka Topic | **Channel（通道）** | 队列/主题只是它的**投递语义**，不另立概念 |
| ETL 的「映射 / 转换规则」 | **DataMapper（数据映射器）** | 它是**配置面**（数据映射图），**不是节点**——配给 Converter / Validator 用 |

> ⚠️ **四对最容易混的概念另见 [`glossary.md`](glossary.md) §3.2**：`publish/subscribe` ↔ `produce/consume`（业务可见性 vs 传输拿走）、`channel` ↔ `pipe`（我们只用 Channel）、`inbound/outbound` ↔ **`inbox/outbox`**（方向 vs 落库的机构）、`stream`。

---

## 2. 三类集成——本质都是数据流

作者原话「底层传输的都是数据，本质还是数据流」；三类集成的差别只在于**流的形状**：

| 类 | 一句话 | 典型场景 | 载体（既有机制） | 真源落点 |
| --- | --- | --- | --- | --- |
| **数据集成** | **基础数据同步**：表 → 表，少逻辑、要准 | 主数据下发（物料 / 客户 / 组织）到各车间库；车间产出回总部 | 数据模型 + 映射 + `@trigger`；外部库走 DB/CDC 端点 | `data/models/*.mm` + DataFlow 图 |
| **流程集成** | **事件流带数据**：状态变化驱动下一步 | 到货 → 质检 → 上架；设备动作完成 → 报工 | `event` / `channel` / `subscribe`（[`events.md`](events.md)）+ ModuleFlow | `flow/*.mf` + 图 |
| **接口集成** | **接口调用**：编排外部/内部 API | 缺料时调供应商/集团 ERP 的物料接口；调用外部物流轨迹 | [`api.md`](api.md) 的端点（内部）+ 外部端点适配器 | API 契约 + DataFlow 图 |

三者**共用同一套运行时**（通道、状态、重试、监控），差别只在**节点类型**（`Data` 节点 / `Event` 节点 / `Call` 节点，§7.3）——这是「一套东西」而不是三个子产品的原因。

---

## 3. 目标与可测指标

### 3.1 「80% 配置化」怎么算

口径与 [`quality.md`](quality.md) §3.1（业务可测指标，**只进报告不进硬门禁**）一致：

| 指标 | 定义 | 首版目标 |
| --- | --- | --- |
| **配置化集成覆盖率** | 端点中**零手写代码**完成接入的占比 = 免代码端点数 / 总端点数 | **≥ 80%**（作者原话定档） |
| **编排落图率** | 数据流中**在图上有定义**（非散落代码）的占比 | ≥ 90% |
| **映射复用率** | DataMapper 映射被复用的次数 / 映射总数 | 越高越好（趋势项） |
| **新增一个集成的时间** | 从「有外部接口文档」到「跑通并进监控」的工时 | 目标 **≤ 1 人日**（对照项：现有手写方式） |

### 3.2 内部/外部端点的「配置」含义不同（重要）

- **内部端点**：**零配置**——module 边界 + `expose` 一裁，端点自动成立（[`api.md`](api.md) §1.1）。
- **外部端点**：**要配置**——地址、协议、认证、映射、对账。
- **结论**：覆盖率的分母主要是**外部端点**（内部端点是白送的）。这也是「减少集成成本」的真实战场。

### 3.3 必须写代码的清单（诚实边界）

以下**不承诺免代码**，只能给**空实现 + KEEP 区**：① 复杂业务规则（多表联合判断）；② 厂家私有协议二进制解析；③ 需要人工判断的审批；④ 需要事务性保证但外部系统不支持的场景（要写补偿逻辑）；⑤ 性能临界路径（要手写批处理）。

---

## 4. 参考架构

### 4.1 分层

```
┌── 控制面（设计期 + 运行期）───────────────────────────────┐
│ 设计：节点图 / 数据流图 / 数据映射图（*.mf.g 多 sheet）    │
│ 运行：总线拓扑面板 · 端点管理 · 监控 · 失败队列与重放      │  ← 作者要求「有自己的 UI」
└──────────────────────────────────────────────────────────┘
┌── 契约层（内核，Rust）───────────────────────────────────┐
│ m 声明 → IR：Event / Channel / Subscription / Endpoint /  │
│ DataFlow 图 / Mapping / Delivery 语义                     │
│ 产出：OAS 3.1（请求-响应端点） + AsyncAPI 3.1（事件端点） │
└──────────────────────────────────────────────────────────┘
┌── 执行层（各端底座：Java / C#）──────────────────────────┐
│ 端点（EventSource/EventSink）→ Channel → 算子（Filter/   │
│ Join/Aggregate/Window/Branch/Call）→ 状态与检查点 → 汇端  │
└──────────────────────────────────────────────────────────┘
┌── 存储 ──────────────────────────────────────────────────┐
│ 事件日志（Event Log）· 状态/检查点 · 失败队列（Dead Letter）│
│ 映射与配置 · 血缘与追溯                                   │
└──────────────────────────────────────────────────────────┘
```

### 4.2 与既有四层运行架构的关系

[`runtime.md`](runtime.md) §1 的四层（Controller / Service / Repository / 缓存）**不变**，总线**不插进业务调用链**，而是**围绕它**：

- **发布**：Service 提交事务时写 **Outbox**（同库同事务），由投递器发到 Channel（§9.2）——**业务代码不感知总线**。
- **订阅**：总线回调 Service / Handler（生成接口 + KEEP 区实现，[`events.md`](events.md) §3）。
- **拦截点**：`after*`（提交后、幂等）是**业务内**的钩子；消息投递是**跨进程**的，二者**不许互相冒充**（[`runtime.md`](runtime.md) §3 事务边界已裁：跨进程后「事务夹在 before/after 中间」不成立）。

### 4.3 三层职责（谁拥有什么）

| 层 | 拥有 | 不拥有 | 原因 |
| --- | --- | --- | --- |
| **语言/契约层（内核）** | 事件、通道、订阅、端点、数据流的**声明与语义**；IR；OAS/AsyncAPI 产物；校验 | **不实现运行时**（不连库、不发消息） | 已裁：内核不重造总线（`..\PLAN.md` §1.2） |
| **执行层（底座）** | 装载、连接、投递、重试、状态、检查点、监控埋点 | **不定义语义**（语义以 IR 为准） | B3：两端各自实现、接口由生成器产出 |
| **配置面（Profile）** | 环境相关：地址、凭据引用、并发、批次、保留期 | **不进语言真源** | 同一份设计跑多环境（[`project.md`](project.md) 多租户 / Profile 口径） |

---

## 5. ★ 引擎选型（本文最关键的裁决）

### 5.1 作者的两个候选，各自能给你什么

| 维度 | **Spring Integration** | **Apache Flink** |
| --- | --- | --- |
| 形态 | **进程内集成框架**（pipes-and-filters） | **独立流计算集群**（Client → JobManager → TaskManager/TaskSlot） |
| 消息模型 | `Message` = **Header + Payload**；`Message Channel`；**Message Endpoint**（`Service Activator`、`Transformer`、`Filter`、`Router`、`Aggregator`、`Splitter` **都算 Endpoint**）（**这些是 Spring 的词**，MMDA 对应名见 §1.1） | DataStream / Table-SQL / ProcessFunction |
| 哲学（你可以直接用的部分） | **生产者与消费者不硬编码，靠配置**；「你要写的代码都在 `MessageHandler` 里面」——**商业逻辑与集成逻辑关注点分离** | **状态（State）+ 事件时间（Event Time）/ 水位线（Watermark）+ 窗口（Window）+ 检查点（Checkpoint）** |
| 持久化 | **要自己接 `MessageStore`**（作者原话痛点） | 状态后端（Memory / **RocksDB** + 增量检查点）、检查点落持久存储 |
| 一致性 | 需自行组合（事务同步 + 幂等 + 存储） | 检查点 + **两阶段提交 Sink**（`TwoPhaseCommitSinkFunction`）→ 声称端到端 Exactly-once |
| 时间语义 | 无 | **Event Time / Watermark / Window**（IOT 的命门：乱序到达的传感器数据） |
| 语言面 | JVM（Spring 生态） | **JVM（Java/Scala）+ Python（PyFlink）**；**没有 .NET 实现** |

### 5.2 两个硬事实（决定了选型不能是「直接选 Flink」）

1. **Flink 的运行时是 JVM 集群**，官方只有 Java/Scala 与 Python 面，**没有 .NET/C# 实现** → 若把 Flink 定为**底座唯一引擎**，**C# 底座就没有对应实现**，直接违反已裁的 **B3（Java / C# 各自实现底座，m 只抽象接口）**，也违背你做 mmda-lang 的初衷（**统一 Java 与 C# 底座的接口方式**）。
2. **我们的底座是「随业务系统部署的库」，不是独立集群**：Flink 需要 JobManager/TaskManager 集群 + 检查点存储（HDFS/S3 类），而 MMDA 的交付形态是**应用自带底座**（[`vision.md`](vision.md) §5.3）。**把 Flink 塞进每个业务系统是不现实的**；反过来，**没有状态与时间语义的进程内框架**（Spring Integration 那一档）又给不了你要的 Watermark / Window / Exactly-once。

### 5.3 裁决：**借 Flink 的语义，不绑 Flink 的运行时**

| 选项 | 内容 | 代价 | 我的建议 |
| --- | --- | --- | --- |
| **A** | **内嵌轻量执行器**：随应用部署；状态落底座库表 / Redis，检查点增量快照；窗口与水位线由调度器推进；语义**逐条对齐 Flink 模型** | 单机吞吐有上限（万级事件/秒量级需实测）；无可视化作业管理 | ★ **首版取 A**（P8 落地） |
| **B** | **Flink 集群作可选后端**：`RuntimeProfile.engine = flink`，面向 IOT / 实时大吞吐；Java 侧直连，C# 侧经 Kafka/HTTP 桥接 | 部署重、运维成本高、C# 侧只能当客户端 | **留口子，P10 之后再评估**（有真实 IOT 客户再上） |
| **C** | C# 侧用第三方消息框架（NServiceBus / Rebus / Brighter / CAP）作执行层 | 这些是**消息总线框架**，无流式状态与时间语义；且引入第三方商业/生态依赖（NServiceBus 是商业授权） | ❌ **不取**（只作「接口集成」类的候选实现细节，不作引擎） |

**✔ 已裁 2026-09-24（§15-1 取 A）**：首版执行层 = **内嵌轻量执行器**（随应用部署、语义逐条对齐 Flink）；`flink` 集群留 **P10** 口子；**第三方消息框架（选项 C：NServiceBus / CAP 等）不做**。

**落法**：**引擎可替换**——内核 IR 定义语义，执行层通过 **Engine SPI** 接入（`RuntimeProfile.engine`：`embedded`｜`flink`｜…）。这样「先能跑、后能扛」不用改设计。**语义清单（必须与 Flink 一致，逐条可测）**：

| 语义 | 我们的对应物 | 首版（A）怎么实现 |
| --- | --- | --- |
| **State** | 算子本地状态（去重集、会话、累计量） | 底座库表 / Redis；键 = `tenant + flowId + key` |
| **Event Time** | 事件发生时间（`event.Timestamp`），**不是处理时间** | 由 Header `occurredAt` 承载 |
| **Watermark** | 「时间已到哪」的推进标记 | 由调度器按 `max(occurredAt) - allowedLateness` 推进（迟到阈值可配） |
| **Window** | 滚动 / 滑动 / 会话窗（限流、聚合、超时判定） | 调度器 + 状态表实现；事件过滤器「限流」即滚动窗（[`events.md`](events.md) 已提） |
| **Checkpoint** | 状态快照 | 增量快照到状态表（记录偏移与去重键水位） |
| **Exactly-once** | **口径见 §9.3**（状态 exactly-once + 汇端幂等） | Outbox + 幂等键 + 状态快照 |
| **Backpressure / 失败队列** | 反压与死信 | 通道水位 + 失败队列 + 重放（[`events.md`](events.md) §可靠计算） |

---

## 6. 端点（Endpoint）

作者原话「**API 是端点，可配置接入**」；**✔ 2026-09-24 补定义（§15-9）**——作者原话「**端点是要在 API 的基础上增加定义数据的转化、过滤规则的**」：

> **端点（Endpoint）= API + 集成定义**。API 是 module 边界推导出的**业务语义接口**（`expose` 决定对外与否）；**端点是在它之上再加一层集成声明**：**数据转化**（Converter + DataMapper 映射）、**过滤**（Filter / Validator）、**投递方式**（Write / Push / Call）、**触发与重试、对账**。边界：**端点不许改 API 的业务语义，也不许在端点里另立业务规则**（那是 Service 的事）。术语用法照 §15-9：**HTTP 接口一律写「API / 接口」，集成连接一律写「端点」**（强调时写「集成端点」）。

端点三类来源：

| 来源 | 定义 | 配置量 | 举例 |
| --- | --- | --- | --- |
| **内部端点** | module 边界 + `expose` 推导出的 API | **零**（白送） | 订单模块的 `POST /orders`、查询视图、Action |
| **外部端点** | 外部系统的接口/表/文件/消息 | **要配**（地址、认证、映射、重试、对账） | 集团 ERP 物料接口、供应商 WebService、车间 PLC/OPC-UA、Kafka、FTP |
| **底座端点** | 平台内置的源与汇 | 少量 | 定时器（Tick）、本地库表、文件、邮件/短信/钉钉（已有通知器可复用）、SignalR |

**端点契约（每个端点必须声明，缺项即校验失败）**：`id` / **`kind`（实现）** 与 **Connector（端点的实现：内置或插件提供，如 Kafka / RabbitMQ / OPC-UA / HTTP / 文件）** / 方向（**入端点｜出端点**——**入/出是方向，不是 Inbox/Outbox**，辨析见 [`glossary.md`](glossary.md) §3.2.3）/ 协议 / 地址与凭据**引用**（引用环境变量或密钥库，**明文口令不得入库**——与仓治理同口径）/ 数据形态（`record`｜`view`｜`json`｜`rowset`｜`file`）/ **幂等键**（默认 `eventId`）/ 超时 / 重试与退避 / 限流 / 熔断 / 保留期 / `lifecycle`。

**边界（已裁，别越）**：

- **✔ 已裁 2026-09-24（§15-2 取 B）**：外部端点的定义**反向导入成语言声明**——走的是 [`api.md`](api.md) §6 已裁的同一条路：**先出导入报告 + 骨架、人审后入真源**。与「外部 collection 不进真源」**不冲突**：外部工具里的 collection **本身仍不是真源**，进真源的只有**人审通过的导入结果**；外部系统的变化**不自动跟随**，靠**再导入 + `mmda diff`** 跟进。对账口径不变（`api.md` §7：导出 ✅ / 逆向导入 ✅ / **回写 ❌** / 对账 ✅）；
- 内部端点**不许**在端点配置里「再声明一遍」——它由 module 推导，配置只能调**暴露开关与限流**这类环境参数。

---

## 7. 数据流（DataFlow）与三张图

作者原话：「通过**图形化的节点图、数据流图、数据映射图**来定义数据流（DataFlow），即 **API 的编排能力**」。

### 7.1 三张图的分工

| 图 | 回答什么 | 粒度 | 图的读者 |
| --- | --- | --- | --- |
| **节点图**（拓扑） | 有哪些端点/算子，怎么连 | 流程级 | 架构师、运维 |
| **数据流图**（DFD） | 数据从哪来、经过谁、到哪去（含外部实体与数据存储） | 流程级 | 架构师、设计师 |
| **数据映射图** | 上游字段 → 下游字段（含转换与计算） | **字段级** | 设计师、实施 |

### 7.2 落文件：**复用 `flow/*.mf`，不新造文件类型**

既有事实：`flow/*.mf` + `*.mf.g` **已经支持多 sheet**（`mf-dfd` 数据流图 sheet、`mf-bpmn` 流程 sheet，见 [`ide/graph-files.md`](ide/graph-files.md) §4.5、[`ide/diagrams.md`](ide/diagrams.md) §4）。
→ **DataFlow 的图元 = `*.mf.g` 新增两个 view 种类**（`mf-flow` 节点图、`mf-map` 数据映射图），**不新增扩展名、不新增顶层概念**。

**语言层新增 = 0**：`event` / `channel` / `subscribe` 已能声明（[`events.md`](events.md)）；编排属于**元数据图**（可推导的部分零声明，编排是新增信息，落图不落语法）。

### 7.3 节点类型（算子清单，收敛到标准词汇）

| 类 | 节点（统一名，见 [`glossary.md`](glossary.md) §3.1） | 说明 | 外部对应词（**只作对照，不进 MMDA 文档**） |
| --- | --- | --- | --- |
| 入口 | **EventSource（事件源）** | 流从这里开始；`kind` = 设备源 · 定时源 · 回调源 · 库变更源 · 文件源 · 消息源 · 进程内事件源 | Flink `Source` / SI `Inbound Adapter` |
| 处理 | **Validator** · **Converter** · **Filter** · **Aggregator** | 作者认同的四类算子；**Converter 覆盖字段映射/换算/格式/计算**（配置面 = DataMapper） | Flink `Transformation` / SI `Transformer`·`Filter`·`Aggregator` |
| 处理（编排） | **Router（路由器）** · **Splitter（拆分器）** | 条件分支/按类型路由；拆分（一条 → 多条，与 Aggregator 对称） | SI `Message Router` / `Splitter` |
| 动作 | **Call（调内部 API/Action）** · **Await（等人或等外部回调）** · **Publish（发事件）** | 通道内的动作与人工等待；`Call` 就是调 module 推导出来的 API | SI `Service Activator` |
| 出口 | **EventSink（数据汇）**（**✔ §15-8 正式名**） | 三种**投递方式**（属性）：**Write 写入 · Push 推送 · Call 调用** | Flink `Sink` / SI `Outbound Adapter` |

**「到货通知 → 抓取没有的物料信息」作者例（落图后长这样）**：

```
EventSource(到货事件 WMS.GoodsArrived)
  → Converter(取到货行明细 payload.lines)        ← 数据映射图：外部报文 → 本地字段
  → Call(查本地物料主数据 by materialCode)       ← Call = 调 module 推导出的 API
  → Router(存在?)
       ├─ 否 → Call(查集团 ERP / 供应商接口)
       │        → Validator(必填 / 单位 / 编码规则)
       │        → Converter(外部报文 → 本地物料字段)
       │        → EventSink(Write: 新建物料主数据 + 出入库台账)
       │        → Publish(事件 MaterialMasterCreated)   ← 「借助插件体系增加扩展点，发布事件」
       │        → EventSink(Push: ERP 回执 / 车间看板)
       └─ 是 → Call(取库存) → Router(低于安全库存?) → 是 → Call(生成请购单 Action) → EventSink(Push: 主管)
  → EventSink(Write: 到货记录)
  → Publish(事件 GoodsArrivedProcessed)
```

**这条流水线里没有一行手写代码**——这正是「配置化覆盖 80%」的样子；写代码的只有 `Call` 到外部接口时的**签名/协议细节**（KEEP 区）。

### 7.4 图的运行语义（别把图当文档）

- 图**编译成 IR 的数据流**（内核产出，执行层装载）——图与代码同源，**改图即改运行**；
- 每个节点有 **ID + 血缘**（进出字段级），失败与监控**定位到节点**（§12）；
- **子流程**（`SubFlow`）可复用：跨模块的一致性补偿链就是一个 SubFlow（[`runtime.md`](runtime.md) 事务传播：跨模块走事件补偿）。

---

## 8. 数据映射（DataMapper）

作者原话：「数据转换可借助 DataMapper 实现可配置（关于数据的**校验、过滤、转换、计算**后面单独讨论）」→ 本文**只定契约，细则另开专文**：

| 算子类 | 输入 | 输出 | 首版能力 |
| --- | --- | --- | --- |
| **校验** Validate | 上游字段 | 通过 / 拦截（报错项 + 定位） | 必填、类型、长度、枚举、正则、跨字段约束（复用 [`records.md`](records.md) 约束关键字） |
| **过滤** Filter | 行/消息 | 通过 / 丢弃（可计数） | 条件表达式（纯函数） |
| **转换** Transform | 字段值 | 新值 | 单位换算、编码映射、日期格式、枚举映射、拆合字段、JSON ↔ 行集 |
| **计算** Compute | 多字段 | 计算结果 | 四则、聚合、表达式（复用 `@Computed` 的表达式层） |

**硬约束**：参与事件重放与存储下推的表达式**必须是纯函数**（无 IO、无随机、无隐式时间依赖）——已裁（[`readme.md`](readme.md) §2 原则 7、[`events.md`](events.md) 纯度要求）。

**映射图 = 字段级可 diff 的资产**：一进一出两个形态（本地 Record ↔ 外部报文），中间是映射规则；对外部报文用 **JSON Schema / XSD** 描述（**✔ 已裁 2026-09-24，§15-7 取 A：可含外部报文形态**，外部形态**不进语言真源**，作适配资产）。

---

## 9. 时间、状态与一致性

### 9.1 时间语义（IOT 的命门）

- **事件时间**（`occurredAt`，设备/业务发生时刻）与**处理时间**（底座收到时刻）**分开记录**；
- **水位线**按 `max(occurredAt) − allowedLateness` 推进，迟到数据进**侧输出/迟到队列**（可配丢弃或补算）——**✔ 已裁 2026-09-24（§15-6 取 A：迟到兜底是默认策略）**；
- 首版支持的窗口：**滚动 / 滑动 / 会话**三种（够覆盖限流、聚合、超时判定）。

### 9.2 可靠发布：**Outbox（事务性发件箱）**

「业务写库成功但消息丢了」是集成里最常见的一类脏数据。唯一正解是标准做法 **Transactional Outbox**：

1. 业务事务内，除了业务表，**同事务写一行 `outbox`**（事件 Id、类型、Payload 引用、目标 Channel）；
2. 事务提交后，**投递器**扫 outbox → 发到 Channel → 标记已投递（**至少一次**）；
3. 消费端按 **`eventId` 幂等**去重。

这样「**after\* 提交后幂等**」的既有裁决（[`runtime.md`](runtime.md) §3）与总线**天然咬合**，业务代码不感知总线。

### 9.3 Exactly-once 的现实口径（要写清楚，别吹）

| 层 | 能保证什么 | 靠什么 |
| --- | --- | --- |
| **状态**（算子内部） | **Exactly-once** | 增量检查点 + 恢复时回放 |
| **通道** | 至少一次 | Outbox + 确认 + 重试 |
| **汇端（内部库表）** | **Exactly-once**（等效） | 同库事务 + `eventId` 唯一键 |
| **汇端（外部系统）** | **最多到「至少一次 + 幂等」** | 外部系统支持事务/幂等键时用 `TwoPhaseCommit` 语义（Flink 的 `TwoPhaseCommitSinkFunction` 是参照）；否则必须要求对方提供幂等键，**否则只能人工对账** |
| **端到端**（**✔ 已裁 §15-4 取 A：只写这一档，不吹全链**） | **「状态 exactly-once + 汇端幂等」= 业务上的 exactly-once** | 不承诺「任何外部系统都 exactly-once」——这是物理限制，不是实现偷懒 |

**把两个词记牢（辨析见 [`glossary.md`](glossary.md) §3.2.3）**：**Outbox 保「不丢」（发），Inbox 保「不重」（收）**。发侧的唯一正解是 §9.2 的 Outbox；**收侧对应物是 Inbox（去重表）**——按 `eventId` 落行、重复即丢。两者相加才是上表最后一行那句「业务上的 exactly-once」，**只有一个都不成立**。

### 9.4 失败与重放

**失败队列（Dead Letter）+ 重放**是硬需求（[`events.md`](events.md) §回调和处理结果）：失败事件带**来源节点 + 错误 + 尝试次数**，支持 ①自动重试（退避）② 丢弃（记审计）③ **人工重放**（重放前校验前提条件，重放走同一幂等键）。

---

## 10. 多租户（作者点名「待解决」）

总线在多租户下的四件事，按隔离强度三档：

| 档 | 内容 | 成本 | 建议 |
| --- | --- | --- | --- |
| **A 共享执行 + 租户键** | 同一作业，所有流/状态/队列按 `tenant` 分区键隔离；通道名带租户前缀 | 低 | ★ **首版取 A（✔ 已裁 2026-09-24，§15-5）** |
| **B 每租户独立作业** | 数据流按租户实例化，配额与限流按租户 | 中 | 大客户可选 |
| **C 每租户独立运行环境** | 独立库/独立进程（信创私有化常见） | 高 | 私有化交付时用 |

**必须在首版就做对的**（否则后期改不动）：① 每条消息 Header **必带 `tenant`**；② 状态与幂等键**都以 `tenant` 为前缀**；③ 通道/端点/映射的**命名空间按租户**；④ **插件装载按租户**（租户 A 的插件不许影响租户 B）——与 [`runtime.md`](runtime.md) §9-8（插件隔离级别）**同一个待裁项**，别开两个口子。

---

## 11. 插件与扩展点（作者原话：借助插件体系增加扩展点，发布事件）

插件**就是业务功能模块插件**（已裁，[`runtime.md`](runtime.md) §7），总线给它的扩展点是**三类**：

| 扩展点 | 插件里是什么 | 清单声明示例 |
| --- | --- | --- |
| **Connector**（源/汇） | 自定义端点实现（私有协议、行业设备） | `capabilities: ["bus.connector", "io.net"]` |
| **Function**（算子） | 自定义校验收/转换器（**纯函数**，可进映射图） | `capabilities: ["bus.function"]` |
| **Panel**（运维面板） | 总线监控的自定义面板（如设备看板） | `capabilities: ["ide.panel"]`，见 [`ide/plugins.md`](ide/plugins.md) §10 |

**发布事件**：插件在自己 module 内 `Publish` 事件**无需特权**（就是跨 module 调用的一种）；**订阅他人事件**按权限授予（scope）——与「插件不许改他人数据模型」同一条硬约束（[`runtime.md`](runtime.md) §7.3）。

**红线（沿用已裁口径）**：插件**不许**写语言文件（内核按后缀拒绝 + 审计）、不许成为第二真源、校验只出 `warning`/`suggestion`。

---

## 12. 可观测性与 UI（作者原话：入/出可监控、有日志、有自己的 UI）

> **运维面（标准出口协议、DevOps 流水线、配置管理、应急处理）见 [`operations.md`](operations.md)**；本节只讲**总线自己的采集面与面板**。

### 12.1 指标（进 [`quality.md`](quality.md) §2.3 运行期指标族）

| 面 | 指标 |
| --- | --- |
| **入** | 接收速率、解码失败率、迟到率（水位线差值）、积压 |
| **流** | 各节点吞吐、**节点级失败率**、算子状态大小、检查点耗时与频率 |
| **出** | 投递成功率、**端到端时延**（P50/P95/P99）、外部端点响应时间、重试次数 |
| **可靠** | 失败队列长度、重放次数、幂等命中数（去重量）、对账差异数 |
| **租户** | 按租户的吞吐与配额使用 |

### 12.2 UI（壳里的一个域）

| 面板 | 内容 |
| --- | --- |
| **总线拓扑** | 端点 → 通道 → 算子的实时图（带健康色与积压数字） |
| **端点管理** | 外部端点配置、连通性测试、凭据引用状态 |
| **运行监控** | 上述指标看板 + 按租户下钻 |
| **失败队列与重放** | 失败事件列表（节点定位 + 错误 + Payload 预览）、单条/批量重放、审计留痕 |
| **对账** | 与外部系统的契约快照比对差异（[`api.md`](api.md) §7 对账面） |

### 12.3 CLI / MCP

`mmda bus list|endpoints|stats|trace|replay|dead-letter`；MCP 侧同名工具（按 [`ai/tools.md`](ai/tools.md) 风格，AI 可读监控、**重放属写操作需确认**）。

---

## 13. 与传统 ESB / 集成平台的差异（要能一句话说清）

| 传统 ESB / iPaaS | MMDA |
| --- | --- |
| 先有总线，再往里注册服务 | **先有 module 边界，端点自动成立**，总线是底座的固有能力 |
| 集成逻辑写在总线里（黑盒、不可 diff） | 集成逻辑是**图**（`*.mf.g`），与设计同源、**可 diff 可评审可回滚** |
| 映射靠拖拽，产物是平台私有的 | 映射是**字段级资产**，与数据模型同源 |
| 数据模型另建一份 | **同一份元数据**：数据模型、API、事件、UI 都从它推导 |
| 与开发体系割裂 | 生成物进你们自己的仓库 + KEEP 区协议（[`readme.md`](readme.md) §7） |

---

## 14. 阶段落点

| 阶段 | 交付 | 验收 |
| --- | --- | --- |
| **P8**（现「事件层」→ 扩为「**事件层与总线**」） | 语义对齐 Flink 模型（State/Event Time/Watermark/Window/Checkpoint）的内嵌执行器 + Outbox + 失败队列 + 三张图的 view 种类 + AsyncAPI 3.1 产物 | ① 事件声明生成的接口**在 Java 与 C# 两侧底座可编译运行**（补齐 Java 侧空白——C# 已有 `IEventBus`/`RedisEventHub`/`SignalR`，Java 侧 `mmda-core-messaging` 只有通知器）；② 一致性用例：同一批事件两端结果一致；③ 到货例（§7.3）跑通且**零手写代码**；④ 幂等与重放用例 |
| **P9** | 一致性套件加**事件维度**（跨端事件一致性）+ 总线指标进质量报告 | 指标可采、可报告 |
| **P10**（新，可选） | `RuntimeProfile.engine = flink` 可选后端 + C# 桥接 | 真实 IOT 场景压测达标后再开 |

**依赖**：P8 依赖 P4（IR + 宿主加载）与 P6（代码生成出 Handler 接口）；**总线不是 P8 从零开始**——C# 侧有既有实现可对齐（`IEvent.cs` / `IEventBus.cs` / `IEventHub.cs` / `ISignalREventHub.cs` / `RedisEventHub.cs` / `EventLogger.cs`，见 [`contracts-inventory.md`](contracts-inventory.md) §4），**Java 侧是真空白**（`mmda-core-messaging` 36 个文件全是通知发送器：钉钉/邮件/短信/电话/微信/Push）。

---

## 15. ✔ 已裁（2026-09-24；**仅第 3 条待定**）

> 作者原话：「**1A, 2B, 4A, 5A, 6A,7A,8C, 9A端点是要在API的基础上增加定义数据的转化、过滤规则的**」+「**3 待定**」。

| # | 议题 | 裁决（2026-09-24） | 落点 |
| --- | --- | --- | --- |
| 1 | **执行层引擎**（本文最重） | **1A**：**内嵌轻量执行器**（语义逐条对齐 Flink）——随应用部署；`flink` 集群留 **P10** 口子；**第三方消息框架（C）不做** | §5.3、§9.1 |
| 2 | **外部端点的定义存哪** | **2B**：**反向导入成语言声明**（**与 2A 相对的取法**）。口径见 §6：外部工具里的 collection **仍不是真源**，进入真源只走**单向反向导入（报告 + 骨架 + 人审后入库）**那条已被 API 契约裁定的路；导入后的端点声明**是语言层产物**，外部系统变化靠**再导入 + diff** 跟进（**不自动跟随**） | §6、[`api.md`](api.md) §6 |
| 3 | **数据流的图元落点** | **⏳ 待定**（A `*.mf.g` 新增 `mf-flow` / `mf-map` view 种类／B 新文件类型 `*.mx`／C 只放 Profile）——**未定不许进生成器** | §7.2 |
| 4 | **端到端一致性承诺写到哪一档** | **4A**：**「状态 exactly-once + 汇端幂等」= 业务上的 exactly-once**（诚实档）；不宣称全链、不止步于至少一次 | §9.3 |
| 5 | **多租户隔离档** | **5A**：**共享执行 + 租户键**（`tenant` 进 Header、状态与幂等键带租户前缀、命名空间按租户）；**B / C 按客户**（大客户与私有化交付时用）。**本条的裁决同时收口了 [`operations.md`](operations.md) §9 的同一三档** | §10、[`operations.md`](operations.md) §9 |
| 6 | **水位线与迟到数据默认策略** | **6A**：**迟到进侧输出 / 迟到队列**（可配丢弃或补算），水位线 = `max(occurredAt) − allowedLateness` | §9.1 |
| 7 | **数据映射可否含外部报文形态** | **7A**：**可含**（JSON Schema / XSD），作**适配资产**、**不进语言真源** | §7.2 / §8 |
| 8 | **Sink 的正式名** | **8C**：**`EventSink`**（与 `EventSource` 对称，作者未采纳助手建议的 8A）。**用法纪律**：契约、生成物与正文首次出现一律 `EventSink`；**引用 Flink / Kafka 官方词时保留 `Sink`**（那是它们的名字，不是我们的概念） | [`glossary.md`](glossary.md) §3.1、§1.1 / §7.3 |
| 9 | **「端点」的限定规则** | **9A**：**HTTP 接口写「API / 接口」、集成连接写「端点」**（强调时「集成端点」）；**并补一层实义**（作者原话）——「**端点是要在 API 的基础上增加定义数据的转化、过滤规则的**」→ **端点 = API + 集成定义**（转化 / 过滤 / 投递方式 / 触发与重试），**不改 API 的业务语义** | §6、[`glossary.md`](glossary.md) §3.1 |

**与既有待裁的交叉**：`runtime.md` §9-8（**插件隔离级别**）**已裁**（首版进程内 + 命名空间与冲突检测），与本文 §10 的多租户隔离档**不是同一件事**（一个管进程内外、一个管数据面），**两条现已各自收口**。商业条款（分成 / 伙伴分级）不进技术契约。

---

## 16. 相关

- [`events.md`](events.md) — **语言面真源**：事件声明、订阅语义、失败队列需求（机制实现以本文为准）
- [`runtime.md`](runtime.md) — 四层职责、**事务边界**（§3）、拦截点（§4）、**业务功能模块插件**（§7）、待裁（§9）
- [`api.md`](api.md) — API 契约、OAS 3.1.0 原生、**与外部工具单向互动**（§7）、待裁清单（§8.2）
- [`statements.md`](statements.md) / [`records.md`](records.md) — STM、`@trigger`、约束关键字（DataMapper 复用）
- [`ide/diagrams.md`](ide/diagrams.md) §4 / [`ide/graph-files.md`](ide/graph-files.md) §4.5 — DFD 语义映射与 `.mf.g` 多 sheet
- [`ide/specification.md`](ide/specification.md) §4.8 域 6 — 业务流程建模域（BPMN / DFD / 映射）
- [`ide/plugins.md`](ide/plugins.md) §10 — 扩展点清单；[`quality.md`](quality.md) §2.3 / §3.1 — 运行期指标与业务指标
- [`contracts-inventory.md`](contracts-inventory.md) §4 — 两端消息与集成能力实测（**C# 有、Java 无**）
- [`vision.md`](vision.md) §5.3 — 部署方式口径（微服务 / 容器化 / 高可用只是部署支持）；`..\PLAN.md` §4 — 阶段计划
