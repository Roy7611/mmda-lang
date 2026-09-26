# 术语表

> 合并上一轮 `glossary.md`（原文留档 `archive/2026-06/`）并补充当前技术栈术语。

## 1. 架构与元模型

| 术语 | 英文 | 说明 |
| --- | --- | --- |
| 元模型 | Meta-Model | 描述系统结构的模型，语言无关；见 [meta-model.md](lang/meta-model.md |
| 元对象 | MetaObject / Record | 实体或视图的逻辑定义 |
| 元列 | MetaCol / Field | 字段：类型、约束、关系引用 |
| 元关系 | MetaRelation | 实体间一对多等导航关系 |
| 显示标签 | `label` | 元数据里「给人看的标题」的**唯一属性名与 JSON 键**（✔ 2026-09-25 作者裁 B；**旧实现列名 `displayLabel`**）；枚举成员同叫 `label`，**字符串表示第 3 段的段名也是 `label`**（⤴ 2026-09-26 作者：「**text => label**」；旧实现里叫 `text`）；见 [meta-model.md](lang/meta-model.md §6 |
| 元数据切片 | `locale` | **元数据 JSON 顶层字段**：**一份 JSON = 一个 locale** —— `label` / 成员 `label` 都是该 locale 的**最终值**（缺译文回落项目 `defaultLocale`）；**词条（Model i18n）通道按它分片、客户端按它缓存**（⤴ 2026-09-26 作者：「**加一个locale属性，这才是输出的json最终形式**」）；串的第 3 段 `label` 则是 **locale 无关形态**、存项目 `defaultLocale` 标签（⤴ 作者：「**2 defaultLocale**」）；见 [meta-model.md](lang/meta-model.md §6.2 |
| 文档注释 | `description` / comments | 设计源的文档信息（`/// <label> : <description>` 的后半段）：**不进 JSON、不进业务载荷**，同 SQL `COMMENT ON` 的语义**另存 comments 层**（**✔ 载体 = A**：生成 DDL 时落数据库 `COMMENT ON`，B 不采用；⤴ 第一百一十八轮作者：「**1A**」）；见 [meta-model.md](lang/meta-model.md §6.3 |
| 子系统 | Subsystem | 业务域顶层划分，如 MES、WMS |
| 模块 | Module | 子系统下的功能分组 |
| 功能 | Feature | 可独立交付的功能单元，通常绑定一个 Record |
| 模块操作 | ModuleAction / Action | 业务动作，常含状态转移 |
| 模块流程 | ModuleFlow | Action 之间的编排（多步流程） |
| 状态转移 | Status Transition | `NEW->APPROVED` 等形式的状态机边 |
| STM 图 | State Transition Machine | 状态机图，Action 的可视化 |
| E-R 图 | Entity-Relationship | 实体关系图，Record 的可视化 |
| DFD | Data Flow Diagram | 数据流图，事件/处理过程的可视化 |
| IR | Intermediate Representation | 元模型的中间表示，跨语言边界（FlatBuffers） |

## 2. 语言与文件

| 术语 | 说明 |
| --- | --- |
| m 语言 | 元模型文本语法；Monaco 语言 id `m-lang`，MIME `text/x-m-lang` |
| M 语言分片 | `.ma` `.mm` `.me` `.ms` `.mr` `.mc` `.mf` `.mb` `.mi` —— 按类型的语言文件 |
| MMDA 项目 | SSOT：根 `{projectCode}.mmda` 清单 + `biz/` `data/` `flow/` `ui/`；见 [project.md](lang/project.md |
| 项目清单 | 根目录 `{projectCode}.mmda`（JSON），非语言模型 |
| 工作区 | 展开目录，日常编辑与 git/svn（推荐形态） |
| 归档包 | `.mmdax` —— ZIP 容器，与工作区路径 1:1，便于分发 |
| Part | 包内一个文件或逻辑单元；含 role 与 partType |
| SSOT | Single Source of Truth：设计真相源（工作区为主，包为交换形态） |
| enumSet | 字段上嵌入的关系/枚举 DSL（**旧实现的存储层表示**，语言里已升级为 `@One`/`@Ref`/`@State` 注解） |
| 字符串表示（旧列名 `enumString`） | `MetaEnum.toString()` / `fromString()` 的成员串（**不是 JSON 字段**）：老格式 `value;name;label`，✔ 2026-09-25 扩展为 `value;name;label;color;icon`（**第 3 段段名 = `label`**，⤴ 2026-09-26 作者：「**text => label**」）（后 2 段可省、空段 = 未声明；**颜色段 = `<role>-<shade>`**，如 `info-500`）——⚠️ 老运行时 `split(';',3)` 会把第 3 段吞成整串，故扩展段只在用外观注解时产出、需与同代内核配套 |
| 表达式层（Expression） | **纯函数**（字段默认值 / `@Computed` / `lockIf`·`hideIf`·`requiredIf` / Validator 条件）——无副作用、无 IO、可重复求值（✔ 已裁 1A） |
| 脚本层（Script） | **拦截点与 `canDo` 里写的受限 m 脚本**——**可读可写 Entity、可跨模块**，由 Rust 内核求值、能力=内核函数（✔ 已裁 2026-09-24 A）；**仍禁任意 IO / 反射 / 随机与时间依赖**，见 [`runtime.md`](runtime.md) §4.5 / §4.6 |
| 能力函数（capability function） | 脚本能用的一项能力 = **内核提供的一个函数**（`script.<域>.<动作>`）；项目用 `capability` 声明后才可用，未声明即生成期报错 |

## 3. 行为与事件

| 术语 | 说明 |
| --- | --- |
| Design Change Log | **设计期**变更日志（元数据 diff）；存于 `changelog/*.json` |
| Domain Event | **运行时**领域事件（与 Design Change Log 严格区分） |
| FlowTrail | 实体实例上的动作/状态变更轨迹 |
| Channel | 事件频道（`channel sales.events { … }`） |
| Subscription | 事件订阅（handler / filter / delivery / retry） |
| Delivery | 投递语义：`at-most-once` / `at-least-once` / `exactly-once` |
| 事件底座 | Java / C# 各自实现的事件总线与可靠投递实现（语言只声明接口） |

### 3.1 事件与集成（唯一命名，✔ 2026-09-24 裁）

> **本节是命名真源**：其他文档一律以此为准；[`event_bus.md`](lang/event_bus.md 只讲这些概念**在流上站哪个位置**。
> **两条判据**：① 一个概念只留一个名字；② 同一个名字不许指两件事（发现撞车就改，见文末）。
> **取舍原则（作者 2026-09-24 原话）**：认同 **Validator / Converter / Filter / Aggregator / Endpoint / Channel** 与 **EventSource**；**「我不用 Transformer，免得与那个 AI 的 Transformer 架构混淆」**。

| 位置 | 统一名 | 定义 | **禁用别名（曾混用/易误解）** |
| --- | --- | --- | --- |
| 流的入口 | **EventSource（事件源）** | 产生事件/数据的源头；实现按 `kind` 区分：设备源 · 定时源（Tick）· 回调源（Webhook）· 库变更源（CDC/轮询）· 文件源 · 消息源 · 进程内事件源 | ~~Source~~ · ~~Input~~ · ~~Inbound Adapter~~ · ~~Trigger（降为 EventSource 的配置项 `on`）~~ |
| 流的出口 | **EventSink（数据汇）**（**✔ 2026-09-24 裁：正式名由 `Sink` 改为 `EventSink`，与 `EventSource` 对称，见 [`event_bus.md`](lang/event_bus.md §15-8**） | 投递方式**三种（属性，不是三个概念）**：**写入 Write · 推送 Push · 调用 Call**。**用法纪律**：契约、生成物、正文首次出现一律 `EventSink`；**引用 Flink / Kafka 官方词时保留 `Sink`**（那是它们的名字） | ~~Output~~ · ~~Target~~ · ~~Outbound Adapter~~ |
| 连接单元 | **Endpoint（端点）** | 一条连接的**配置单元**：协议 / 地址 / 凭据引用 / 幂等键 / 重试 / 限流 / 保留期；分**入端点**与**出端点**。**✔ 2026-09-24 补定义**：**端点 = API + 集成定义**——在 API 之上再加**数据转化（Converter / DataMapper 映射）、过滤（Filter / Validator）、投递方式（Write / Push / Call）、触发与重试、对账**；**不改 API 的业务语义**（作者原话「端点是要在 API 的基础上增加定义数据的转化、过滤规则的」，[`event_bus.md`](lang/event_bus.md §6 / §15-9） | ~~Adapter（Channel Adapter）~~ |
| 连接实现 | **Connector（连接器）** | 端点的**实现**（内置或插件提供：Kafka · RabbitMQ · OPC-UA · 文件 · HTTP …） | —（与 Endpoint 别混：**配置 vs 实现**） |
| 传输 | **Channel（通道）** | 端点与处理器之间的传输；投递语义 = **点对点（队列）/ 发布订阅（主题）**；`transport` = `memory` · `redis` · `rabbitmq` · `kafka` · `db`（**跨进程/跨系统集成走消息平台**） | ~~Queue / Topic~~（只作投递语义的修饰，不作概念名） |
| 处理（上位词） | **Processor（处理器）** | 流中间节点的统称 | ~~Transformation~~ · ~~Transform~~ · ~~Map~~ · ~~Compute（并入 Converter）~~ |
| 处理·校验 | **Validator（校验器）** | 必填 / 类型 / 长度 / 枚举 / 正则 / 跨字段；不通过 → 拦截 + 进失败队列 | ~~Validation（作概念名）~~ |
| 处理·转换 | **Converter（转换器）** | 字段映射、单位换算、编码与格式转换、计算；**配置面 = DataMapper**（既有概念：`.mc` / `flow/converters/`） | **~~Transformer~~（与 AI 的 Transformer 架构混淆，作者明确不用）** |
| 处理·过滤 | **Filter（过滤器）** | 丢弃 / 放行（可计数） | — |
| 处理·聚合 | **Aggregator（聚合器）** | 多条 → 一条（含窗口内聚合） | ~~Reduce~~ · ~~Collect~~ |
| 处理·拆分 | **Splitter（拆分器）** | 一条 → 多条（与 Aggregator 对称） | ~~Explode~~ · ~~FlatMap~~ |
| 处理·路由 | **Router（路由器）** | 条件分支 / 按类型路由 | ~~Branch（并入 Router）~~ |
| 配置面 | **DataMapper（数据映射器）** | 字段级映射 + 校验/转换/计算规则的**声明处**（数据映射图）；**不是流上的节点** | ~~Mapping Engine~~ · ~~ETL 映射器~~ |
| 编排 | **DataFlow（数据流）** | 数据的流转图（节点图 / 数据流图 / 数据映射图）；**与 ModuleFlow（人的审批流转）严格区分** | ~~Workflow~~（那是 ModuleFlow） · ~~ETL Job~~ |
| 事件面角色 | **Publisher / Subscriber（发布者 / 订阅者）** | MMDA 文档的**统一用词**（业务语义，`subscribe` 就是它） | ~~Producer / Consumer~~（**仅**描述外部系统或中间件时用） |
| 代码实现 | **Handler（处理器实现）** | KEEP 区里真正写代码的地方；订阅生成的接口名沿用 `handler Xxx`（[`events.md`](lang/events.md §3） | ~~ProcessorImpl~~ |
| 可靠性机制 | **Outbox（事务性发件箱）** · **幂等键 `eventId`** · **失败队列（Dead Letter）** · **重放（Replay）** | 机制名，不是节点 | ~~消息表~~ · ~~重试表~~ |

> ⚠️ **两处撞车（✔ 2026-09-24 均已裁，见 [`event_bus.md`](lang/event_bus.md §15-8/9）**：① **「端点」**——[`api.md`](api.md) 里指 **HTTP 接口**（由 module 推导），本文指**集成连接点**；**已裁规则（§15-9 取 A）**：**接口一律写「API / 接口」，集成连接一律写「端点」**（要强调时写「集成端点」）。② **「触发器」**——`@trigger`（记录级数据库触发器，[`records.md`](lang/records.md）与「事件源」同词；规则：`@trigger` 保留，**Trigger 不再作独立概念名**。

### 3.2 易混淆概念辨析（四对 + `stream`，✔ 2026-09-24 裁）

> **为什么要单独列**：这几对词在别的框架里都叫得通，**混着用不会报错，却会让程序员对不上号**。规则是唯一的：**左边是我们用的词，右边是不许当同义词替换的词。**

#### 3.2.1 `publish` / `subscribe` ↔ `produce` / `consume`

| | **publish / subscribe（发布 / 订阅）** | **produce / consume（生产 / 消费）** |
| --- | --- | --- |
| 视角 | **业务**：这个事件对**谁可见** | **传输**：这条消息**写给谁** |
| 基数 | **一对多**——**订阅关系决定可见范围** | **一对一**——一条消息被一个消费者取走（多个消费者是**分工**，不是广播） |
| 角色 | **Publisher / Subscriber** | **Producer / Consumer** |
| 有无业务语义 | Subscriber **有**：订阅了哪个事件、交给哪个 Handler（[`events.md`](lang/events.md §3） | Consumer **可以没有**：搬运、审计、转发也算 |
| 我们怎么用 | **文档统一用这一组**（语言层的 `subscribe` 就是它） | **只在描述中间件（Kafka / RabbitMQ / Redis）的 API 与配置时用** |

**不变量**：**一个事件 → N 条消息 → N 个订阅者**（同一事件可投影成多条消息：不同协议、不同载荷）；**每个订阅者的消费互相独立**——一个订阅者慢、甚至没有，都不影响别人，事件照样成立。
**一句话**：`publish / subscribe` 管「**谁看得见**」，`produce / consume` 管「**谁读走了**」。

#### 3.2.2 `channel` ↔ `pipe`

| **Channel（通道）** | **Pipe（管道）** |
| --- | --- |
| **MMDA 的正式概念**（见 §3.1「传输」行） | **外部系统词汇，不进 MMDA 术语** |
| **有投递语义**：点对点（队列）/ 发布订阅（主题） | 只有「单向 + 背压」的流 |
| 可持久、可多订阅者、可跨进程（`transport` = `memory` / `redis` / `rabbitmq` / `kafka` / `db`） | 一般是内存、单连接：Unix 管道、shell `\|`、Node `stream.pipe`、Go `chan` |
| **名字唯一**，不许有同义词 | 非要用，必须写明是**外部机制**（如「Unix 管道」） |

**为什么不用 Pipe**：① 与 Channel **叠概念**（违反「一个概念只留一个主人」）；② 程序员对 Pipe 的既有联想**全部撞车**——shell 管道（进程间）、**Angular 的 `\|` 管道（那是转换器，直接撞我们的 `Converter`）**、Node `stream.pipe`（连接流）、Go `chan`（语言级队列）。**流的形状**已由 Channel 的投递语义 + Processor 表达，加一个 `Pipe` 只会多一个同义词。

#### 3.2.3 `inbound` / `outbound` ↔ `inbox` / `outbox`

| **inbound / outbound（入 / 出）** | **inbox / outbox（收件箱 / 发件箱）** |
| --- | --- |
| 是**方向**（相对本系统边界）：**入端点**（EventSource 侧）/ **出端点**（EventSink 侧） | 是**表**（机构）：**记录集**，要落库 |
| 端点的**属性** | **可靠性的落点** |
| **不落库** | 与业务数据**同一个本地事务**（Outbox） |
| 说「数据从哪来、到哪去」时用它 | 说「**不丢 / 不重**」时用它 |
| 另有**入参 / 出参**（params）——那是**参数方向**，别拿它当端点方向 | — |

**不变量（请背下来）**：**Outbox 保「不丢」，Inbox 保「不重」**。

- **Outbox（事务性发件箱）** = 业务事务里**同事务**写一行待发记录，提交后由投递器发出（[`event_bus.md`](lang/event_bus.md §9.2）；
- **Inbox（去重表）** = 收到消息时按 **`eventId`** 落一行，重复投递直接丢弃（幂等）——它是「**至少一次 + 幂等 = 业务上的 exactly-once**」的另一半（[`event_bus.md`](lang/event_bus.md §9.3）。

**命名保留**：`Inbox` / `Outbox` 是**行业固定词**（Transactional Outbox Pattern），**不许改成 `SendBox` / `ReceiveBox` 之类自造词**；与邮件客户端的「收件箱 / 发件箱」**同义**，不构成撞车。

#### 3.2.4 速查：别混用

| 你听到的词 | MMDA 里叫什么 | 别混成 |
| --- | --- | --- |
| pub / sub | **Publisher / Subscriber** + `subscribe` 声明 | Producer / Consumer |
| produce / consume、send / receive | **传输实现细节**（中间件的 API 与配置） | 业务角色名 |
| channel | **Channel（通道）**，有投递语义 | Pipe、Queue、Topic、Stream |
| pipe | 外部机制（必须写明） | Channel |
| inbound / outbound | **入端点 / 出端点**（方向） | Inbox / Outbox |
| inbox / outbox | **Inbox（去重表）/ Outbox（发件箱）**（机构，落库） | 入 / 出方向 |
| stream | **流**（`DataFlow` 的口语说法）；指具体中间件时写其名（Kafka / Redis Stream） | Channel（Channel 是逻辑传输，Stream 是实现） |

> **标识符与生成代码怎么写**（接口 `I` 前缀、实现类**禁 `Impl`**、类与对象 Pascal、字段与属性 camel、其余尊重各端习惯）**见 [`naming.md`](naming.md)**——本节管「词」，`naming.md` 管「怎么写」。

## 4. 交付与工具

| 术语 | 说明 |
| --- | --- |
| KEEP 区 | 生成代码中允许手写的区域（`~KEEP PARTS BEGIN/END`） |
| GENERATED 区 | 工具生成、再生成时覆盖的区域（`~GENERATED PARTS BEGIN/END`） |
| Codegen Profile | 一套代码生成目标与模板配置（`codegen/profiles/*.yaml`） |
| 代码工厂 | 现有 Java 实现 `mmda-factory`（11713 行），将由 Rust 重写 |
| Code Builder | 生成器基类家族（`JavaCodeBuilder`、`TsEntityCodeBuilder` …） |
| 反向导入 | 元数据库 → 项目文件（`mmda import --db`） |
| Vibe & Spec | 先 Spec 设计、再交给 AI 实现的协作模式 |
| MCP | Model Context Protocol，AI 调用工具的接口面 |

## 5. 编码与映射

| 术语 | 说明 |
| --- | --- |
| objType | Record 种类：`T` 表/实体 · `V` 视图 · `TA` 带 Action · `TAF` 带 Action 与 Flow/审计 · `VAF` 带 Action 与 Flow 的视图 |
| moduleType | Module 层级：`0` Subsystem（`M`）· `1` Module（`M.01`）· `2` Feature（`M.03.001`） |
| relationType | `1` HAS_ONE · `2` HAS_MANY |
| FieldRef 前缀 | `ENUM` 枚举引用 · `ENUMS` 位标志枚举（BitVector）· `REF` 引用（值对象）· `HAS_ONE` 一对一导航 |
| **位向量** | **`BitVector(n)`**（**规范名**，✔ 2026-09-26 作者：「**用 BitVector，BitSet, BitArray 别名**」）；**别名 = `BitSet` / `BitSet(n)` / `BitArray`**（输入兼容，`mmda fmt` 归一）、**后缀式 `BitVector8`…`BitVector64`** ≡ `BitVector(8)`…`BitVector(64)`。`n` = **位数**（8 的倍数 = 整数字节、默认 8、上限 128）；真源 `DataType.BIT_VECTOR`(129)；见 [`datatypes.md`](lang/datatypes.md §7 |
| 分区键 PK | Partition Key：文档 COMMENT 的 PK；多租户 BIGINT 字段，常与主键同列 |
| 唯一键 UK | Unique Key：租户内业务唯一，如工号 `empNo` |
| `.m` | **纯脚本文件**的扩展名（✔ 2026-09-25）：模型之外的脚本程序（拦截器 / 钩子体 / 可复用函数），**与它服务的对象同目录**，可用 `import` 引到别的文件里复用；模型仍用分片族（`.mm` / `.me` / `.ms` …） |
| view（视图） | **定义式，不是查询式**：`view X : B { 列 }` 的 **`:` 是 C# 风格的继承 / 实现**，语义 = **对 `X` 进行定义**（`B` 是基，可以是 `record`，见语料 `view Product : Bom`）；`as` = 引用该基的别名，`join` / `union` = 再挂别的基（横向 / 纵向）；**列清单逐字段显式写出**（每个基的字段都要写、名字对得上，不一致用 `as` 对齐，对齐规矩照 SQL）；**基可以是 `record` 或另一个 `view`**；**段对视图可选 —— 只读视图（大多数）不写段** |
| `@Colorized` / `@Iconized` | **枚举的呈现开关 + 默认值**（✔ 2026-09-25）：写在**枚举声明**上；`@Colorized(role, shade?)` 只负责给**默认色**（成员 `@Color` 缺省时回落）、`@Iconized`（**无参、不写括号**）默认别名 = **成员名 kebab**、`@Iconized("bom")` 默认别名 = **前缀 + 成员名 kebab**（`bom-design`）；成员不写就用默认，没默认才不渲染 |
| `@Color(role, shade?)` | **枚举成员的主题色**（✔ 2026-09-25；原 `@ColorRole(role)` 写法并入）：**封闭 7 值** `primary` / `secondary` / `info` / `success` / `warning` / `danger` / `gray`（含**默认支持的黑白灰**；语言层校验，拼错 = 解析期 error）+ **色板 shade（色阶）**（**封闭 10 档** `50`–`900`，**省略 = `500`**）；**只给角色与 shade、不给色值**（色值来自主题令牌，模型层不写 `#RRGGBB`） |
| `@Icon("alias")` | **枚举成员的图标别名**（✔ 2026-09-25）：逻辑别名（如 `"cancel"`）—— **完整别名**（显式写的即最终别名，不叠前缀）；**开放**，语义词由**开发人员自定义**，语言层只校验是字符串；**不绑定图标库**，映射在 **UI 层**（主题 / 皮肤）；**没映射上顶多不显示**（可选 warning，不报错） |
| `@Partitioned` / `partitioned` | **分区主键**（✔ 2026-09-25 由 `@PartitionID` 改名）：**字段级行尾 `partitioned`**（不带范围）／ **注解 `@Partitioned [min,max]`**（带段范围）—— 与元对象属性 `MetaObject.partitioned` 同名；一个对象只能有一个 |
| 基础表（base table） | **UNION 进某个视图的那几张表**（视图的组成表）—— 「标识共享组」即一个视图的基础表集合；SQL 现成词，不用「成员表 / 来源表」 |
| 标识共享（Identity Sharing） | **一组要 UNION 成同一个视图的表，在 realId 空间里各领一个互不重叠的段**（`@Partitioned [min,max]` 声明），使 UNION 后的主键天然不冲突（✔ 2026-09-25 作者说明；段划分与六个组见 [`records.md`](lang/records.md §2.3） |
| `BIGID` | **自有整数类型（文档用名）**：本身即 partitionID（分区主键）—— **高 28 位字段 = tenantId（27 位有效，`0x7FF_FFFF`，bit 63 保留恒 0）+ 低 36 位 realId**（解析 `>>> 36`；`0` = 无租户，`1` 起为真实租户；realId 由分布式 ID 生成、底座合成）。**语料写法 = `@Partitioned [min,max]` + `uint64 identity`**，见 [`datatypes.md`](lang/datatypes.md §5 |
| customProperties | API 中 REF/ENUM 的显示标签扩展 |
| MetaUiField | UI 呈现：formatter、editor、renderer |
| UiLogic | 前端模块交互逻辑（beforeEdit 等钩子） |
| MetadataGenerator | 从 DDL 逆向 MetaObject/MetaCol 的工具 |

## 6. 文件扩展名（formatVersion 2.0）

| 扩展名 | 目录 | 内容 |
| --- | --- | --- |
| `.mmda` | 根 | 项目清单（仅 `{projectCode}.mmda`）⚠️ 与决策 B8 冲突，见 [errata.md](errata.md) 冲突 3 |
| `.ma` | `biz/` | 子系统 Module 树 |
| `.mm` | `data/models/` | Record / View |
| `.me` | `data/enums/` | Enum |
| `.ms` | `data/stms/` | STM |
| `.mr` | `flow/roles/` | Role / Auth |
| `.mc` | `flow/converters/` | Converter |
| `.mf` | `flow/` | **数据流（DataFlow）**：节点图 / 数据流图 / 数据映射图（✔ 2026-09-24 改判） |
| `.mb` | `flow/` | **跨模块流程（BPMN）**（✔ 2026-09-24 新增） |
| `.mi` | `ui/` | 定制 UI（五视图） |
| `*.g` | 与 SSOT 同目录 | 图形投影（布局/样式） |
| `.mmdax` | — | ZIP 归档包 |
