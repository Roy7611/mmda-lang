# 运维与可观测性（运维篇）

> 版本 0.1 · 2026-09-24 · 真源：**运维面**（标准出口协议、自动打点、DevOps 流水线、配置管理、应急处理）
> **与相邻文档的分工**：本文管**怎么被观测、怎么被发布、怎么被应急**；[`quality.md`](quality.md) §2.3 管**指标清单与采集面**（本文不重列指标）；[`event_bus.md`](lang/event_bus.md) §12 管**总线采集面与总线 UI**；[`runtime.md`](runtime.md) §1 管**四层运行架构**（打点位置就是它）；[`api.md`](api.md) §7 管 API 契约与对账；[`vision.md`](vision.md) §5.3 已裁「部署方式不进语言层」。
> **已裁前提（沿用，不重开）**：① **微服务 / 容器化 / 热插拔 / 高可用 = 部署方式，语言层零新增**（判据：**凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍**）；② **API 边界 = module 边界 = 权限边界 = 文档分组边界**；③ **凭据只引用不落盘**（`mmda doctor` 自检）；④ **L2 国产化矩阵**（x86_64 + aarch64；验收麒麟 V10 SP3 / 统信 UOS V20；**离线交付包** + 校验和清单）；⑤ **OWASP ASVS L1 自动化子集进 `mmda quality gate` 硬门禁**，引用必须写版本号。

**作者口径（原话，2026-09-24）**：

> 「关于软件的可监测性，涉及到运维架构。也是我关注的一个重点！1. DevOp，如 jenkins 集成 2. 系统资源、微服务实例、网络、数据流量、报警推送等。」
> 「运维的角度会关注：软件生命周期（SLM），关注可用性、性能和安全性；发布自动化（DevOp）、配置管理；运行监控：基础设施、应用、数据；应急处理：问题定位、响应处理、分析 KPI」
> 「跟开源的 Zabbix，Prometheus，Open Falcon 等如何能集成，需要考虑。我想你单独落盘一份运维篇。」

**作者给的五层监控图（本文的骨架）**：

| 层 | 作者原图要点 |
| --- | --- |
| 客户端监控 | 用户行为信息、业务返回码、客户端性能、运营商、版本、操作系统 |
| 业务层监控 | 登录、注册、下单、支付 |
| 应用层监控 | URL 请求次数、service 请求数量、SQL 执行的结果、cache 的利用率、QPS |
| 系统层监控 | CPU 利用率、内存利用率、磁盘空间 |
| 网络层监控 | 网关流量情况、丢包率、错包率、连接数 |

---

## 0. 一句话与边界

**一句话**：MMDA 的运维面 = **元数据驱动的自动打点 + 标准出口协议 + 元数据即配置** —— **不造监控后端、不造采集 agent、不把监控写进语言**。运维栈是客户的，我们只保证**数据出得来、出得标准、能关联、能重放**。

**边界（反面清单）**：

| ❌ 不做 | 理由 |
| --- | --- |
| 不做中心化监控后端 / 时序库 / 告警引擎 | 社区已成熟（Prometheus / Zabbix / 夜莺）；自研等于多养一个产品，且客户的运维团队已有自己的栈 |
| 不把监控写进语言语法 | 判据（已裁）：能从 module / 数据模型 / 权限推导的，语言里不许再声明一遍——**指标口径从元数据推导**（§3.1） |
| 不绑定某一套监控栈 | 出口用**标准协议**（OpenMetrics 文本 / OTLP / SNMP），Prometheus、Zabbix、夜莺都能消费（§4） |
| 不做自研采集 agent | 系统层与网络层用社区采集器（node_exporter / Zabbix agent / SNMP / Categraf）；我们只出**应用侧出口** |
| 不做 AIOps 智能根因（首版） | 先把「可采集、可关联、可重放」做扎实；智能根因属增值插件（[`runtime.md`](runtime.md) §7） |
| **不采集业务明细数据** | 监控只出**指标 + 日志元数据**；业务明细按权限走 API/查询视图查，**不进监控库**（安全与合规，§8） |
| 不承诺「零配置可观测」 | 自动打点覆盖**三层**（业务 / 应用 / 数据）；系统层、网络层、客户端层需要客户或前端配合（§2） |

---

## 1. 运维视角的四件事（对齐作者口径）

| 作者口径 | 关注点 | 判定指标（可算） | 落点 |
| --- | --- | --- | --- |
| **软件生命周期（SLM）** | 可用性、性能、安全性 | 可用性（成功请求 / 总请求）、SLO 达成率、性能分位（P50/P95/P99）、安全门禁通过项 | [`quality.md`](quality.md) §2.3 采集面 + §3.2 ASVS 门禁；本文 §3、§8 |
| **发布自动化（DevOps）** | 发布频率、可回滚、可追溯 | 部署频率、变更前置时间、变更失败率、回滚率（DORA 四指标） | 本文 §5；[`PLAN.md`](..\PLAN.md) §4 P5/P9 |
| **配置管理** | 环境差异、漂移、凭据 | 配置漂移数（生效版本 ≠ git 提交哈希）、明文凭据数（必须 0） | 本文 §6；[`runtime.md`](runtime.md) `RuntimeProfile` |
| **运行监控** | 基础设施、应用、数据 | 五层中的可自动采集项覆盖率 | 本文 §2、§4；[`quality.md`](quality.md) §2.3 |
| **应急处理** | 问题定位、响应处理、KPI | MTTR / MTBF、告警真阳性率、重放成功率 | 本文 §7 |

---

## 2. 五层监控模型：谁采、从哪来、我们出什么

**这是本文最重要的一张表**——它决定了每一层的责任归属，也决定我们**只做中间三层**。

| 层（作者图） | 采集方 | 指标从哪来 | **MMDA 出什么** |
| --- | --- | --- | --- |
| **客户端监控** | **前端 / 移动端 SDK**（不由底座采） | 浏览器与端侧运行时 | **口径 + 埋点清单**（从元数据给）：页面 / 视图名取五视图与路由、业务返回码取 API 契约的 `status` 与错误码、性能取 Web Vitals（LCP / INP / CLS）；**运营商与地域靠离线 IP 库**（ip2region 类）解析，**不依赖在线服务**（离线交付要求） |
| **业务层监控** | **底座自动**（零打点） | `Action` 元数据 + 事件声明 | `mmda_action_total{module,action,result}`、`mmda_event_published_total{module,event}` —— **登录 / 注册 / 下单 / 支付就是 Action**，不需要程序员埋点 |
| **应用层监控** | **底座自动** | [`runtime.md`](runtime.md) §1 四层 | API → `mmda_api_requests_total{module,endpoint,method,status}`；Service → `mmda_action_duration_seconds`；Repository → `mmda_sql_duration_seconds{module,repository,op}` + 慢查询计数；缓存 → `mmda_cache_requests_total{module,name,result}`（QPS 由 `_total` 求导） |
| **系统层监控** | **外部采集器**（node_exporter / Zabbix agent / Categraf） | 宿主机 | **底座不管**；只要求：**同机打 `tenant` / `service` 标签** + **统一时间源（NTP）**，否则指标无法与业务指标对齐 |
| **网络层监控** | **外部采集器**（SNMP exporter / 网关自带 Prometheus 出口 / Zabbix SNMP） | 网关、交换机、链路 | 底座只出**端点侧**：入/出端点连接数、重试次数、退避次数、积压与失败队列长度（[`event_bus.md`](lang/event_bus.md) §12.1），**丢包率 / 错包率属网络设备，不归我们** |

**三条可判定边界（写进运维手册）**：

- **底座负责中间三层，另外两层交给外部**——这条边界不模糊，避免「什么都想自己采」；
- **时间源必须统一**（NTP）且**所有指标同机打 `tenant` / `service`**——否则跨层关联（业务 → 应用 → 系统）做不出来；
- **客户端层首版只做 Web**（唯一渲染方 = mmda-vue）；移动端 Flutter 排后（✔ **已裁 2026-09-24，8A**）。

---

## 3. 三支柱：Metrics / Logs / Traces

> 用程序员的熟词，不自造概念（[`glossary.md`](glossary.md) §3.1 判据）。

### 3.1 Metrics（指标）——「零打点」从哪来

**指标命名规范**（唯一口径）：`mmda_<域>_<对象>_<计量>`；单位与类型后缀按 OpenMetrics 惯例（`_seconds` / `_bytes` / `_total` 计数）；**标签只放低基数维度**。

| 域 | 指标（示例） | 来源（**这就是零打点**） |
| --- | --- | --- |
| 业务 | `mmda_action_total{module,action,result}` | `Action` 元数据 |
| 业务 | `mmda_event_published_total{module,event}` · `mmda_event_consumed_total{module,event,result}` | `event` / `subscribe` 声明 |
| 应用 | `mmda_api_requests_total{module,endpoint,method,status}` | API = module 推导（[`api.md`](api.md)） |
| 应用 | `mmda_action_duration_seconds{module,action}` | Service 层（`runtime.md` §1） |
| 数据 | `mmda_sql_duration_seconds{module,repository,op}` · `mmda_slow_query_total{module,repository}` | Repository 层 |
| 数据 | `mmda_cache_requests_total{module,name,result}` | 缓存横切面 |
| 集成 | 入 / 流 / 出 / 可靠 / 租户五组 | [`event_bus.md`](lang/event_bus.md) **§12.1**（不在此重列） |
| 可靠性 | `mmda_outbox_pending` · `mmda_inbox_duplicated_total` · `mmda_dead_letter_size` | Outbox / Inbox / 失败队列（[`glossary.md`](glossary.md) §3.2.3） |

**高基数铁律（会毁掉监控库的一条）**：

- 标签**只允许**低基数维度：`tenant` · `module` · `endpoint` · `action` · `result` · `status` · `target` · `repository`；
- **禁止**把 `id` / 单据号 / 用户标识 / `traceId` / `eventId` / `correlationId` 放进标签——**明细走日志与链路**（§3.2 / §3.3），监控库只放聚合。
- 理由：时序库的标签基数 = 时间线数量，一张订单一个标签会让监控库当场爆掉（运维排障第一类事故）。

### 3.2 Logs（日志）

- **结构化 JSON，一行一事件**；必带字段：`ts` · `level` · `tenant` · `module` · `traceId` · `eventId` · `endpoint` · `msg`；
- **`eventId` 与 Outbox / Inbox 对账贯通**（[`event_bus.md`](lang/event_bus.md) §9.2/§9.3）：日志能直接对上「这条消息到底发出去没有、是否被去重」；
- **敏感字段按元数据标记脱敏**（字段标记已裁，[`api.md`](api.md) 序列化口径同源）；
- 出口：**OTLP 优先**（§4），syslog / Kafka 为可选；**默认不落公网**。

### 3.3 Traces（链路）

- 以 **W3C `traceparent`** 为标准头，跨进程与中间件透传（不自造头）；
- **诚实边界（必须写清）**：事件驱动链路在 **Outbox 投递处天然断开**——上游是「业务事务」，下游是「消息消费」，不是一个进程调用。要续链，靠**关联键**而不是魔法：

| 键 | 含义 | 谁生成 |
| --- | --- | --- |
| `traceId` | **一次请求**的调用链（W3C `traceparent`） | 入口（网关 / Controller） |
| `eventId` | **一次事件**（幂等键、Outbox / Inbox 对账键） | 发布方 |
| `correlationId` | **一次业务操作**触发的多条消息 / 多次调用 | 发起方（跨事件续链用这个） |

> 一句话：`traceId` 管一次请求、`eventId` 管一次事件、`correlationId` 管一串因果。

---

## 4. 与开源监控栈的集成（作者点名 Prometheus / Zabbix / Open-Falcon）

**总原则**：**我们只出标准出口；选哪套栈是客户的事**。所以集成的正确打开方式是「**出口协议 + 模板资产**」，而不是「为每个产品写一个适配器」。

### 4.1 四个标准出口

| 出口 | 协议 / 形态 | 谁消费 |
| --- | --- | --- |
| **指标** | **OpenMetrics 文本**（Prometheus exposition 格式，拉模型）`/metrics` | Prometheus · 夜莺 · **Zabbix**（HTTP agent 主项 + Prometheus pattern 依赖项，官方支持）· VictoriaMetrics · Thanos —— **✔ 已裁 1A：这是首版唯一「必需」的出口** |
| **遥测（可选）** | **OTLP 1.11.0**（trace / metric / log 三信号均已 stable） | OpenTelemetry Collector → 任意后端（**✔ 1A：可选，不与 `/metrics` 并列**） |
| **告警规则** | **规则文件 / 模板**（Prometheus rule、Zabbix 模板 XML） | 对方告警引擎（Alertmanager / Zabbix）加载——**我们不自己发告警** |
| **推送（可选）** | **Zabbix trapper**（`zabbix_sender`）· Kafka · syslog | 无拉取能力的网络区的场景（**✔ 已裁 3A：作为「口子」保留，不主动做内容**） |

### 4.2 三家对照（要做的 / 不做的）

| 开源件 | 集成路径 | **我们要做的** | **我们不做的** |
| --- | --- | --- | --- |
| **Prometheus** | 拉 `/metrics`；批量作业走 Pushgateway | 内置 exporter 端点（含 `tenant` / `module` 标签）· **版本化官方 dashboard JSON** · **告警规则文件** | **不内置 Prometheus 本身**（离线交付包可选附，§9）；不自建时序库 |
| **Zabbix** | ① **HTTP agent 主项 + Prometheus pattern 依赖项**抓 `/metrics`（官方文档支持）② **trapper 推送**（`zabbix_sender`）作补充（**✔ 已裁 3A：留口子**） | 出**版本化 Zabbix 模板 XML**（含监控项 / 触发器 / 发现规则） | **不做 Zabbix agent 插件**（不绑 C / Go 写的 agent 模块）；不重复实现 Zabbix 的告警与依赖 |
| **Open-Falcon** | 社区已转向**夜莺（n9e）**；接入路径 = ① 夜莺的 **Prometheus-Like 数据源 / Remote Write**（Categraf 即走此路）② **JSON 推送**最低成本兼容 | 保证 `/metrics` 与标准格式完备（**兼容即接入**）；如客户仍在 Open-Falcon，出**推送格式说明**——**✔ 已裁 4A：只做 Prometheus 兼容，不做 JSON 推送适配器** | **不做 falcon-agent 协议的第一优先**（已停更一代的技术，不投入适配器） |
| Grafana | 直接消费 Prometheus / Loki / Tempo | 版本化 dashboard JSON（随内核版本发布） | 不写死面板、不内嵌 Grafana |
| 网络 / 硬件 | SNMP exporter、IPMI / Redfish | —（交给客户运维栈） | 不做网络与硬件采集 |

### 4.3 告警不重复造

- **告警通道复用既有通知器**（邮件 / 短信 / 钉钉，Java 侧 `mmda-core-messaging` 已有 36 个通知器）；
- **路由 / 去重 / 抑制 / 静默** 交给 Alertmanager 或 Zabbix（这是它们的专业）；
- 我们只提供**告警内容规范**（每条告警必须带四项）：**现象**（哪条指标、什么阈值）· **影响面**（哪个 module / 端点 / 租户）· **第一个排查动作**（看哪张图 / 哪条命令）· **可行动作**（重放命令 / 回滚点 / runbook 链接）。**没有这四项的告警不许上生产**。

---

## 5. DevOps 与流水线（作者点名 Jenkins）

### 5.1 流水线阶段（与 [`PLAN.md`](..\PLAN.md) §4 的阶段对齐）

| # | 阶段 | 命令 / 动作 | 产出 | 失败即停 |
| --- | --- | --- | --- | --- |
| 1 | 元数据校验 | `mmda check` | 校验报告（规则来源 = P2/P3 的校验器） | ✔ |
| 2 | 代码与契约生成 | `mmda emit ddl` / `emit code` / `emit api` | DDL、三端骨架、`openapi.json` / `asyncapi.json` | ✔ |
| 3 | 编译 | 各端原生工具链 | 制品 | ✔ |
| 4 | 测试 | `mmda test --target java,csharp,ts` | **JUnit XML** | ✔ |
| 5 | 契约测试 | OAS 3.1 **官方 Schema** 校验 + 双向对账 | 契约测试报告 | ✔ |
| 6 | 质量门禁 | `mmda quality gate`（含 **OWASP ASVS L1 自动化子集**） | 门禁结论 + 报告 | ✔ |
| 7 | 打包 | 生成物 + `Dockerfile` / k8s 骨架 + **SHA256SUMS** | 交付包 `*.tar.gz` | ✔ |
| 8 | 发布 | 灰度 → 全量；**回滚点 = 上一版制品 + 元数据提交哈希** | 发布记录 | — |

### 5.2 给 CI 的输出契约（**必须机器可读**，否则集成就得写胶水）

| 产物 | 格式 | 消费方 |
| --- | --- | --- |
| 测试结果 | **JUnit XML** | Jenkins `junit` 步骤（原生） |
| 静态分析 / 架构规则 | **SARIF** | Jenkins **Warnings Next Generation** |
| 质量报告 | `quality-report.json`（九维 × 子特性 + 证据位置） | 报告页 / 历史趋势 |
| 变更影响 | `mmda diff`（元数据 diff → 影响的 **API / 表 / 端点 / 用例**） | 评审与发布审批 |
| 契约 | `openapi.json` · `asyncapi.json` + 契约测试报告 | 网关、文档、客户端 |
| 交付包 | `*.tar.gz` + `SHA256SUMS` | 离线交付（L2 已裁） |
| **构建元数据** | 内核版本 · 元数据提交哈希 · 目标端矩阵 · 生成时间 | **进制品清单**（可追溯：产物 ↔ 元数据版本必须能反查） |

### 5.3 Jenkins 集成形态（三种，**都不需要私有插件**）

| 形态 | 做法 | 适用 |
| --- | --- | --- |
| **A. 只用 CLI** | Jenkinsfile 里 `sh 'mmda ...'` | **首版推荐**（零插件、零绑定） |
| B. 共享库（Shared Library） | 封装成 `mmdaPipeline(...)` 步骤 | 多项目统一流水线 |
| C. 容器化 agent | 流水线跑在我们发布的构建镜像里（离线交付包内含） | 环境一致性、离线环境 |

- **硬口径：零私有 Jenkins 插件。** 同一套 CLI 必须在 GitLab CI / 任意流水线平台同样能跑——**工具链不绑 CI**（与「不造自研 agent」同一立场）。

---

## 6. 配置管理（元数据即配置）

- **唯一真源 = `*.mmda` 元数据（git）** → IR → 生成物 + `RuntimeProfile`；**环境差异只进 Profile**（同代码多环境），**不靠元数据分支**；
- 环境差异项清单：连接与端点地址 · 限流 / 熔断阈值 · 日志级别 · **监控出口开关** · 密钥引用名；
- **凭据只引用不落盘**（环境变量 / 密钥库；`mmda doctor` 自检项；公开仓更不允许明文）；
- 变更流程：**元数据 MR → 校验 + 影响面（`mmda diff`）→ 生成物 diff → 评审 → 灰度 → 回滚点**；
- **配置漂移检测（可判定）**：运行期**生效版本**（内核版本 + 元数据提交哈希 + Profile 名）必须能查到，与 git 不一致即告警。这是「元数据是唯一真源」在运维面的落点，也是 §7 定位路径的第 4 步。

---

## 7. 应急处理：定位 / 响应 / KPI

### 7.1 三个关联键

见 §3.3：`traceId`（一次请求）· `eventId`（一次事件）· `correlationId`（一串因果）。**三者必须进日志与告警**，否则跨层定位无从下手。

### 7.2 定位路径（SOP：从告警到根因）

1. **看采集面**：哪一层异常（客户端 / 业务 / 应用 / 数据 / 系统 / 网络）；
2. **看失败队列与重放记录**：失败事件带来源节点 + 错误 + 尝试次数（[`event_bus.md`](lang/event_bus.md) §9.4）；
3. **按 `traceId` / `correlationId` 取链路**（事件断链处用 `correlationId` 续）；
4. **看变更**：最近一次元数据 / 生成物 / Profile 变更（漂移检测结果）；
5. **止损**：熔断 / 限流 / 降级 / 切端点（配置项，不需要改代码）；
6. **恢复**：重放（同一幂等键，重放前校验前提条件）或回滚（上一版制品 + 元数据哈希）；
7. **复盘**：进 KPI，产出「告警是否有效 + SOP 是否需要改」。

### 7.3 响应分级与 KPI

- **分级**：P1（核心业务不可用、无替代路径）→ P4（体验问题），判据 = **影响面 × 是否有替代路径**；
- **KPI**：**DORA 四指标**（部署频率 / 变更前置时间 / 变更失败率 / 恢复时长）+ **MTTR / MTBF** + **告警质量**（真阳性率、噪声率、平均确认时长）+ **重放成功率**；
- **口径**：KPI **只进报告、不进硬门禁**（与 [`quality.md`](quality.md) §3.1 同口径）。

---

## 8. 安全（运维面本身就是攻击面）

| 项 | 口径 |
| --- | --- |
| **监控端点** | `/metrics` · `/health` · 诊断端点 **默认只绑内网 / 回环 + 必须鉴权**（ASVS L1 认证与会话 / 访问控制类目，**进硬门禁**） |
| **多租户** | 指标带 `tenant` 标签；**查询侧隔离**；监控库不许成为跨租户数据泄露通道（与 [`event_bus.md`](lang/event_bus.md) §10 三档一致） |
| **审计** | 谁重放了事件、谁改了配置、谁看了哪个租户的指标——**重放与配置变更必须留审计** |
| **合规** | **不采集业务明细**（§0）；敏感字段按元数据标记脱敏；**引用 OWASP ASVS 必须写版本号**（既有口径） |
| **默认不外发** | 指标与日志**默认不出公网**；云托管监控为可选开关，需显式开启并写进交付说明 |

---

## 9. 多租户 / 国产化 / 离线

- **多租户三档**（与 [`event_bus.md`](lang/event_bus.md) §10 同一件事）：**A 共享采集 + `tenant` 标签**（**✔ 已裁 2026-09-24：`event_bus.md` §15-5 取 A，本条随之收口**）／ B 每租户独立监控实例 ／ C 每租户独立环境（按客户）；
- **国产化**：监控栈必须**可离线部署**（镜像 tar + 离线规则 / 模板文件）；采集器架构矩阵 = **x86_64 + aarch64**（与 L2 矩阵一致），**龙芯不承诺**；验收 OS（麒麟 V10 SP3 / 统信 UOS V20）上跑通即算；
- **离线交付包附带**（✔ 已裁 2026-09-24，**2A**）：Prometheus / node_exporter / Zabbix agent 的镜像或二进制 + 官方 dashboard JSON + 规则文件——**可选启用、默认不开**（不算「内置」）；
- **`mmda doctor`** 现四项（内核版本 / glibc / 架构 / JDK）→ **✔ 已裁 2026-09-24（7A）：扩为六项**——+ **时间源一致性**、+ **监控出口可达性**。

---

## 10. 阶段落点（不新增独立阶段）

| 能力 | 阶段 | 验收 |
| --- | --- | --- |
| 自动打点清单 + `/metrics` 出口 | **P6**（生成物）+ **P9**（验收） | 生成一次即出指标，**零手写打点** |
| 总线采集面（入 / 流 / 出 / 可靠 / 租户） | **P8** | 到货例跑起来，五组指标都有数 |
| CI 输出契约（JUnit / SARIF / quality-report / diff）+ 门禁 | **P9** | Jenkins 只用 CLI 即跑通全流水线 |
| 离线交付包 + `doctor` | **L2（已裁）** | 离线环境装得上、自检能过 |
| 运维诊断命令 `mmda ops`（只读） | **P9**（✔ **已裁 5A：进首版**） | 采集面 / 失败队列 / 对账差异 / 生效版本四项可查 |
| 运维 UI（壳里的运维域） | **P7**（[`ide/specification.md`](ide/specification.md)） | 与 [`event_bus.md`](lang/event_bus.md) §12.2 同一面板规划 |

> **✔ 已裁 2026-09-24（6A）**：把 **P9 扩为「一致性 + 验收 + 运维出口」**（**不新增 P11**），避免战线拉长；`mmda ops` 只读诊断随 P9 交付（5A）。

---

## 11. ✔ 已裁（2026-09-24，作者取 `1A 2A 3A 4A 5A 6A 7A 8A`）

> 作者原话：「**1 A, 2A, 3A, 4A, 5A, 6A,7A, 8A**」——**八条全部取建议档**。

| # | 议题 | 裁决（2026-09-24） | 落点 |
| --- | --- | --- | --- |
| 1 | 首版唯一必需的监控出口 | **1A**：**`/metrics`（OpenMetrics 文本，拉模型）必需**；**OTLP 可选**；三出口不并列 | §4.1 |
| 2 | 交付包是否附监控后端与采集器镜像 | **2A**：**附**（Prometheus / node_exporter / Zabbix agent 镜像或二进制 + dashboard JSON + 规则文件），**可选启用、默认不开**（离线交付是硬要求） | §9 |
| 3 | Zabbix 侧形态 | **3A**：**只出模板 XML + 让 Zabbix 抓 `/metrics`**（HTTP agent 主项 + Prometheus pattern 依赖项）；**保留 trapper 推送的口子**（无拉取能力的网络区） | §4.2 |
| 4 | Open-Falcon 兼容优先级 | **4A**：**只做 Prometheus 兼容**（客户经夜莺 n9e / 兼容层消费）；**不做 JSON 推送适配器**（留文档级说明即可） | §4.2 |
| 5 | `mmda ops` 只读诊断是否进首版 | **5A**：**进首版（P9）**——**这条同时清掉了 [`ux.md`](ux.md) 1B 的前置**：体验度量的回流腿有数据来源，不再是纸面约定 | §10、[`ux.md`](ux.md) §5 |
| 6 | P9 是否扩为「一致性 + 验收 + 运维出口」 | **6A**：**扩**（**不新增 P11**）——P9 = 一致性 + 验收 + **运维出口（模板资产）+ `mmda ops` 诊断** | §10、[`PLAN.md`](..\PLAN.md) §4 |
| 7 | `mmda doctor` 是否加「时间源一致性 + 监控出口可达性」 | **7A**：**加**（`mmda doctor` 由四项扩为六项；两条都是现场踩过的坑） | §9 |
| 8 | 客户端监控首版范围 | **8A**：**只做 Web**（mmda-vue：Web Vitals + Action 埋点）；Flutter 排 P8 之后（与移动端裁决一致） | §2 |

---

## 12. 相关

- 指标清单与采集面：[`quality.md`](quality.md) **§2.3**（14 项 + 总线采集面）
- 总线采集面与 UI：[`event_bus.md`](lang/event_bus.md) **§12**（§12.1 指标 / §12.2 UI / §12.3 CLI·MCP）
- 四层运行架构（打点位置）：[`runtime.md`](runtime.md) §1；拦截点 §3
- API 契约与对账：[`api.md`](api.md) §7；序列化与字段标记（脱敏源）
- 质量门禁与 ASVS：[`quality.md`](quality.md) §3、§3.2
- 部署方式（不进语言层）与 L2 矩阵：[`vision.md`](vision.md) §5.2.1、§5.3
- 阶段与验收：[`PLAN.md`](..\PLAN.md) §4（P5 / P6 / P8 / P9 + L2 验收腿）、§6.3
- 术语（唯一命名）：[`glossary.md`](glossary.md) §3.1、§3.2
- 待裁台账：[`errata.md`](errata.md) §三
