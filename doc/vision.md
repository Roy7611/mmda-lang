# 愿景与目标（Vision）—— 为什么要做 m 语言与 MMDA

> **状态**：✔ 已裁（2026-09-24）。作者给出四层目标（商业 / 技术 / 用户 / 架构）并逐条拍板，本文是其**真源**。
> 本文回答「**为什么做**」；**工程目标与非目标**在 [`..\PLAN.md`](..\PLAN.md) §1；**语言定位与设计原则**在 [`readme.md`](readme.md) §1–§2；**质量口径**在 [`quality.md`](quality.md)。
> 四层目标里，凡已落到具体机制的都给出文档指针；**仍未裁决的 5 条集中在 §8**。

---

## 0. 思想源头：没有银弹（essence vs accidents）

Brooks（《No Silver Bullet》，1986）把软件技术的困难分成两种：**本质困难**（essence——构造复杂的概念设计构想）与**偶然困难**（accidents——把设计表示成语言、并验证表示是否保真的劳动）：

> "Fashioning complex conceptual constructs is the essence; accidental tasks arise in representing the constructs in language."

MMDA 的落法就是压缩这一半：**元数据定义一次，Java / C# / TS / DDL / OAS / 用例都是产物**——人力集中在**本质困难**（业务逻辑、架构决策、数据与流程设计），而不是把设计翻译给三端语言。（同一立场的早期表述见 `archive/2026-06/overview.md`。）

---

## 1. 一句话

数字化交付的现实是：**架构画在图上、契约写在文档里、实现在代码中**，三份东西靠人同步——一变就散。

MMDA 的主张是：把「设计与实现之间的契约」变成**机器可读、可执行、可校验、可回滚的唯一真源**（[`readme.md`](readme.md) §7）。m 语言是写这份契约的语言，MMDA 是跑这份契约的框架：**契约写一遍，Java / C# / TS 三端各自成立**。

---

## 2. 商业层面（To Boss）

| 目标 | 对 MMDA 的要求 | 落地机制 | 现状 |
| --- | --- | --- | --- |
| 开放源码 | 许可边界清晰、第三方能集成 | **open core**（§5.1）：规范 + 内核 + IDE 壳 + 三端薄适配开源；算法库 / 行业包 / SaaS 闭源 | ✔ 规范文本已公开（`github.com/Roy7611/mmda-lang`）；内核仓尚未建立 |
| 协同 | 多角色在同一真源上协作且可评审 | 一对象一文件 + git/svn 细粒度版本控制（[`project.md`](project.md)）；五类职责写入边界与交接协议（[`workflows.md`](workflows.md)）；变更分级 L0–L3 | ✔ 已裁 |
| 共赢 | 第三方能扩展而不被平台锁定 | 生成源码、产物不依赖 MMDA 才能跑（[`readme.md`](readme.md) §7）；**插件市场**（[`ide/plugins.md`](ide/plugins.md) §9，**⏸ 2026-09-24 起暂缓：目前不考虑收费和市场**）——**插件 = 用户自研的业务功能模块**（主形态，真源 [`runtime.md`](runtime.md) §7：`jar`/`dll`/npm + 清单 + 冲突检测，**插件就是 module，语言层零新增**），市场同时是**闭源行业包 / 算法库的合法分发渠道**与伙伴体系载体；**设计阶段原生支持插件式开发**（[`ide/plugins.md`](ide/plugins.md) §8 五条可检判据）；**IDE 插件为次**（支持更好，不做首版承诺）；插件不改语言（[`api.md`](api.md) §1.1） | ✔ 已裁（2026-09-24：**做市场**；主形态已纠正为业务功能模块插件） |
| 降成本 | 可测量，不停在口号 | 四个可测指标见 §6，落 [`quality.md`](quality.md) §3.1 | 🟡 指标已定，待采集 |

---

## 3. 技术层面（To CTO）

| 目标 | 对 MMDA 的要求 | 落地机制 | 现状 |
| --- | --- | --- | --- |
| 开放源码 | 内核可审计、可替换，无黑盒 | 同 §5.1；**内核与宿主分离**（Rust 内核 + 三端薄适配），规范公开使第三方可自行实现宿主 | ✔ 已裁 |
| 易定制 | 定制走声明，不改生成器 | Codegen Profile + capability 分档（[`targets.md`](targets.md) §3）；模式与权限在 IDE 项目管理里配置（默认单人模式） | ✔ 已裁 |
| 易运维 | 运行期行为可声明、可观测 | 拦截点上升到语言层、事务边界明确（[`runtime.md`](runtime.md)）；缓存是横切面；运行期 14 项指标（[`quality.md`](quality.md) §2.3） | ✔ 已裁 |
| 支持国产化 | 数据层 / 运行层 / 界面层三级都要能落地 | 见 §5.2（✔ 已裁为**全三级承诺**） | 🟡 L1 已有底座；L2 此前零口径；L3 靠自研皮肤 |
| 微服务 / 容器化 / 热插拔 / 高可用 | **只是部署方式，语言层零新增** | 见 §5.3（✔ 2026-09-24 拍定） | 🟡 待落 P5 / P8 |

---

## 4. 用户层面（To User）

| 目标 | 对 MMDA 的要求 | 落地机制 | 现状 |
| --- | --- | --- | --- |
| 易用 | 默认零配置可用，定制全部显式 | 默认单人模式（模式与权限在 IDE 项目管理里配）；capability 默认关；Profile 只做覆盖，不改默认值 | ✔ 已裁 |
| 轻松 | 重复劳动交给机器 | 用例从声明**机械生成**（[`testing.md`](testing.md)）；DDL / 代码 / OpenAPI / 文档 / mock 都是**产物** | ✔ 已裁 |
| AI 赋能 | AI 有稳定接口，也有明确边界 | MCP 与 CLI 工具面（[`ai/tools.md`](ai/tools.md)）；AI 造数两层 + 四条护栏（[`testing.md`](testing.md) §4.3）；**AI 只提议，不签字**（[`workflows.md`](workflows.md)） | ✔ 已裁 |
| 容易二开 | 扩展点在元数据与插件，不在源码分叉 | 插件体系（[`ide/plugins.md`](ide/plugins.md)）、前端 `vuix-*` 插件、语言层的 `expose` 与 Action | ✔ 已裁 |

---

## 5. 架构层面

### 5.1 开放源码的边界与许可（✔ 2026-09-24，取 A）

| 资产 | 开源 / 闭源 | 许可 | 理由 |
| --- | --- | --- | --- |
| m 语言规范（本仓 `doc/`、`PLAN.md`） | **开源** | MIT（现状，见 `LICENSE`） | 契约公开是生态的前提；备选 CC-BY-4.0（要求署名）**未采用**，见 §8-1 |
| Rust 内核 / 三端薄适配 / IDE 壳 | **开源** | **MIT（✔ 2026-09-24：核心平台统一 MIT）**——与规范同一份许可，**全栈一个许可**，集成方零摩擦。代价要清楚：MIT **不带专利授权与商标条款**（原记 Apache-2.0），商标靠 README / 官网声明，专利风险靠防御性公开 | 可审计、可替换、可被集成——这是 To CTO 的核心诉求 |
| 算法库（如 `logistics-scheduler`） | **闭源** | 商业许可 + 许可绑定（在线激活 / 离线授权 / 加密狗 / 调用计量） | 算法体不进交付仓，见 [`protection.md`](protection.md) §4、§7 |
| 行业业务包 / 模板 / SaaS | **闭源** | 商业许可 | 计费形态见 [`protection.md`](protection.md) §8 |

**与现有资产的冲突（必须记住）**：`D:\2026\java` 与 `D:\2026\cs\MMDA` 的现有代码是 **PROPRIETARY / CONFIDENTIAL** 版权头（证据：`mmda-core/mmda-core-metadata/src/main/java/cloud/mmda/core/metadata/MetaDb.java:3`「MMDA.CLOUD PROPRIETARY/CONFIDENTIAL」）。

→ 结论：**开源的是规范与新内核，不是这两套既有实现**。既有实现只作**对照与回填来源**（[`contracts-inventory.md`](contracts-inventory.md)），不随本体开源；若未来要把某段既有代码开源，必须逐文件确认权属与版权头。

### 5.2 国产化三级承诺（✔ 2026-09-24，取 C：**全三级**）

| 级 | 范围 | 现状与缺口 | 验收口径 |
| --- | --- | --- | --- |
| **L1 数据层** | 国产数据库：达梦 / 人大金仓 / OceanBase / openGauss | 🟡 **Java 侧已有底座**：`mmda-core-sql/.../sql/dialects/` 8 个方言类含 `DmDialect`（达梦）与 `KingbaseDialect`（人大金仓，继承 PG）；`MetaDataType.java:209/213/220/224` 有 `kingbaseType`/`kingbaseName` 与达梦原生类型字段。**C# / TS 侧未核**；m 语言的方言表待建（[`PLAN.md`](..\PLAN.md) §3.6） | 同一份模型在三端生成的 DDL 规范化文本一致（[`targets.md`](targets.md) §5） |
| **L2 运行层** | 国产 OS + 国产 CPU + JDK 国产发行版 | ✔ **已裁（2026-09-24，取 1A 2A 3A 4A 5A）**：目标矩阵见 §5.2.1——双架构、双 OS 基线、毕昇优先、**设计器不进国产 OS**、离线交付 | 在目标 OS + CPU 上跑通内核与三端一致性套件 |
| **L3 界面层** | 至少一套**无商业控件**的皮肤 | 🟡 现皮肤 `vui-syncfusion` 依赖 30 个 `@syncfusion/ej2-*@34.2.2`（`packages/vui-syncfusion/package.json:84-109`，海外商业授权） | 自研国产皮肤在无商业控件下跑通主要场景（列表 / 表单 / 树 / 图表） |

**作者口径（原话，2026-09-24）**：「国产化，我会实现一个，例如 naive + 别的表格插件，syncfusion 只是一个选项」。

→ 落法：UI kit 是前端自己的事（[`presentation.md`](presentation.md) §5.1），**换皮肤不构成第二套 UI 契约**（契约边界只到 `MetaUi`）；Syncfusion 从「唯一皮肤」降为**可选皮肤之一**，与 `vui` / `rui` / `vui-agnaive` 等并列。

### 5.2.1 L2 目标矩阵（✔ 已裁 2026-09-24，作者取 `1A 2A 3A 4A 5A`）

**五条正交决策与选择**：

| # | 决策 | 采纳 | 内容 | 依据（实测/出处） |
| --- | --- | --- | --- | --- |
| 1 | CPU 承诺面 | **A：x86_64 + aarch64 双架构** | 海光 / 兆芯（x86_64）+ 鲲鹏 / 飞腾（aarch64）；**龙芯只承诺「内核交叉编译通过 + 给构建说明」，不进验收矩阵**；申威不承诺 | Rust `x86_64-unknown-linux-gnu` / `aarch64-unknown-linux-gnu` 都是官方目标；`loongarch64-unknown-linux-gnu` 虽已是 **Tier 2 with host tools**（要求 kernel ≥5.19、glibc ≥2.36、LSX），但 **`loongson/jdk21u` 是龙芯自维护分支**、**.NET 官方 supported-os 表不含 LoongArch**（RID 目录里有 `linux-loongarch64`，属社区级）——C# 端在龙芯上无官方支持 |
| 2 | OS 清单 | **A** | **验收**：银河麒麟 V10 SP3 服务器版（x86_64 + aarch64）、统信 UOS 服务器版 V20；**CI 基线**：openEuler LTS（开源免费，且是麒麟 / 统信的上游根社区） | 客户现场以麒麟 / 统信为主；openEuler 作基线免授权费 |
| 3 | JDK 发行版 | **A** | **毕昇 JDK 21（AArch64 / x86_64）+ 上游 OpenJDK 21 兜底**；腾讯 Kona / 阿里 Dragonwell / 龙芯 JDK 只在文档里列「已知可替换」，**不进验收矩阵** | 毕昇 JDK 21 官方只出 Linux/AArch64 与 Linux/x86_64 两个平台（openEuler 镜像仓 README 原话） |
| 4 | 设计器是否承诺国产 OS | **A：不承诺** | **L2 只承诺「运行时 + 内核 CLI」跑在国产 OS/CPU**；设计器（Tauri 壳）仍在 Windows / macOS / Linux-x86 上运行；麒麟 / 统信桌面版的 WebKitGTK / 字体 / 输入法 / deb·rpm 打包**不进首版** | 设计器是开发机工具而非交付物；见 [`ide/specification.md`](ide/specification.md) §4.9 |
| 5 | 交付与构建形态 | **A** | **离线交付包**：生成物 + 交叉编译产物（`x86_64` / `aarch64` 各一套）+ 国产 OS 基础镜像的 `Dockerfile` + `docker save` 的 tar + 校验和清单；配 **`mmda doctor`** 自检（内核版本 / glibc / 架构 / JDK） | 信创现场多为内网隔离，不能指望在线拉镜像与 yum 源 |

**验收口径（不说口头承诺）**：

1. 在目标 OS + CPU 上跑通 **`mmda test --target java,csharp,ts`** 三端一致性套件，且同一份模型生成的 DDL 规范化文本一致（[`targets.md`](targets.md) §5）；
2. **架构支持等级写进 capability 声明**——例如将来若把龙芯纳入，C# 端必须显式声明 `community` 等级，**不许用「支持国产化」一句话带过**；
3. 构建与验收腿：CI 跑 **x86_64 + aarch64** 两套；`mmda doctor` 在两种架构上都给出绿色结论。

**阶段落点**：交叉编译与容器基座随 **P5**（DDL 与生成物）、国产 OS/CPU 的验收腿随 **P9**（一致性套件与验收）——见 [`..\PLAN.md`](..\PLAN.md) §4。

### 5.3 部署方式（微服务 · 容器化 · 热插拔 · 高可用）——语言层零新增（✔ 2026-09-24）

判据沿用 [`api.md`](api.md) §1.1：**「凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍」**。
`module` 已是一等边界（API = 权限 = 文档 = 模块同一来源），因此「哪个 module 独立部署」是**部署期决策，不是设计概念**——语言层一个概念都不加。

| 目标 | 机制 |
| --- | --- |
| 微服务 | **Profile 的部署拓扑视图**：同一份元数据既可出单体拓扑，也可出微服务拓扑；服务边界 = module 边界 |
| 容器化 | P5 代码生成的一个后端：产出 `Dockerfile` + `compose` / `k8s` 骨架；**内核不做编排引擎**（只产出，不管运行） |
| 热插拔 | module 粒度：元数据热加载，或重新生成 + 滚动重启 |
| 高可用 | 交给部署拓扑 + 三端运行时：API 无状态、会话外置、`after*` 钩子必须幂等（[`runtime.md`](runtime.md)） |

**阶段安排**：**P5 只出「单体拓扑 + Dockerfile」**；微服务拓扑留 **P8** 单独裁——因为「事务夹在 before / after 拦截点中间」是已裁语义（[`runtime.md`](runtime.md)），**跨进程后该语义会变**，必须先裁事务传播规则再落拓扑。

### 5.4 其余架构目标（已有落点）

| 目标 | 现状 | 落点 |
| --- | --- | --- |
| 分层 | ✔ 已裁 | [`runtime.md`](runtime.md)：Controller = API 开放 / Service = 商业逻辑 / Repository = 数据读写 / 缓存 = 横切面 |
| 多租户 | ✔ 已裁且三端有实现 | [`meta-model.md`](meta-model.md)（`partitionKey` / `@PartitionID`）、[`project.md`](project.md) §2.1（分文件 include）、[`api.md`](api.md) §3.2（Server Variable）、[`runtime.md`](runtime.md)（缓存键含租户）、[`targets.md`](targets.md) §4（三端 Tenancy ≈） |
| 热插拔模块化 | ✔ 见 §5.3（module 粒度） | module 边界四合一（[`api.md`](api.md) §1.1） |
| 高性能 | ✔ 机制已定 | 生成原生代码、表达式下推到存储、`@Computed` / `@trigger` 生成库侧 `trigger` / `procedure`（[`readme.md`](readme.md) §5）；性能效率信号见 [`quality.md`](quality.md) §1.2 |
| 安全、防黑客 | ✔ 基准已裁 | [`quality.md`](quality.md) §1.6（安全性）与 **§3.2（OWASP ASVS 门禁口径）**、[`api.md`](api.md) §3.6（scope）、ARCH-111（[`architecture-review.md`](architecture-review.md)）；**ASVS L1 自动化子集进硬门禁、Top 10 作报告项** |
| 可靠性 | ✔ 机制已定 | [`quality.md`](quality.md) §1.5 + 事务边界与 `after*` 幂等（[`runtime.md`](runtime.md)） |
| 跨平台 | 🟡 L2 覆盖国产 OS / CPU；桌面为独立壳（Tauri） | [`ide/specification.md`](ide/specification.md) §4.9；§5.2 L2 |
| 多端、多语言 | 🟡 三端与三语言已裁；**移动端宿主已裁方向 = Flutter** | [`targets.md`](targets.md)（2 后端 + 1 前端）、`locales: [zh, zh-Hant, en]`（[`project.md`](project.md)）；移动端宿主 = **Flutter**（Dart 端，排 P8 之后），**首版不做**；`MetaUi` 第二渲染方的口径见 §8-6 |

---

## 6. 商业目标的可测指标（✔ 2026-09-24 同意，落 [`quality.md`](quality.md) §3.1）

「降成本 / 轻松 / 易用」必须有数字，否则对管理层无法举证。

| 指标 | 定义 | 采集方式 |
| --- | --- | --- |
| **生成覆盖率** | 产出物里可从模型生成、无需手写的行数占比 | 生成物中 `GENERATED` 区行数 / 总行数 |
| **变更成本** | 改一处模型 → 三端同步所需的**手工改动行数**与耗时 | 变更前后 diff 统计（越接近 0 越好） |
| **上手时间** | 业务人员经 AI 到「首个可用原型」的耗时 | 试点记录（[`workflows.md`](workflows.md) 业务人员路径） |
| **模板复用率** | 跨项目复用的 module / 模板数占比 | 仓内统计（[`templates/`](templates/conventions.template.md)） |

**不进硬门禁**：这四项是管理面指标（对应 [`quality.md`](quality.md) 的 C / D 类），只进报告与趋势，不阻塞发布。

---

## 7. 与现有文档的关系

| 文档 | 管什么 |
| --- | --- |
| 本文 `vision.md` | **为什么做**（四层目标与裁决） |
| [`..\PLAN.md`](..\PLAN.md) §1 | 工程目标、非目标、阶段与验收 |
| [`readme.md`](readme.md) | 语言是什么、设计原则、与低代码的区别 |
| [`quality.md`](quality.md) | 质量特性、可判定性分级、报告与门禁（含 §3.1 业务指标） |
| [`architecture-review.md`](architecture-review.md) | 架构规则与打分（ARCH-1xx…5xx） |
| [`protection.md`](protection.md) | 算法保护与许可（open core 的闭源那一半） |
| [`workflows.md`](workflows.md) | 谁在什么阶段做什么、谁能改什么 |

---

## 8. 待裁（原 5 条**已全部裁决**；余为新开的 2 条——`MetaUi` 第二渲染方、移动端是否进首版）

| # | 议题 | 我的建议 |
| --- | --- | --- |
| 1 | ~~规范文本许可最终选型（MIT vs CC-BY-4.0）~~ → **✔ 已裁 2026-09-24：核心平台统一 MIT** | 余（体制侧，非技术）：MIT **不带专利授权与商标条款**——商标靠 README / 官网声明，专利靠防御性公开与自有布局，见 §5.1 |
| 2 | ~~移动端（多端）宿主形态（独立壳移动版 / 响应式 Web / 小程序）~~ → **✔ 已裁方向 2026-09-24：Flutter**（Dart 端） | 首版不做（先 Web + 桌面 Tauri），排 P8 之后 |
| 3 | ~~安全目标是否引入 OWASP ASVS / Top 10~~ → **✔ 已裁 2026-09-24：ASVS 进入硬门禁** | ASVS **L1 自动化子集**进 `mmda quality gate`、L2·L3 与人工渗透不进、**Top 10 作报告项**，口径见 [`quality.md`](quality.md) §3.2 |
| 4 | ~~L2 国产化的**目标矩阵清单**~~ → **✔ 已裁 2026-09-24（`1A 2A 3A 4A 5A`），矩阵见 §5.2.1** | 余：**龙芯（LoongArch）何时纳入生产验收**、**申威是否需要**——等客户点名再开 |
| 5 | ~~「共赢」是否落成**插件市场 / 伙伴体系**~~ → **✔ 已裁 2026-09-24：做插件市场、留口子、设计阶段原生支持插件式开发**；**⚠️ 同日再收口：市场与收费暂缓**（作者原话「目前不考虑收费和市场」）——**「留口子」= 设计阶段原生支持插件式开发**（[`runtime.md`](runtime.md) §7 + [`ide/plugins.md`](ide/plugins.md) §8），**市场机制只留方向、不进首版** | 落点 [`ide/plugins.md`](ide/plugins.md) §8–§9 + **[`runtime.md`](runtime.md) §7（主形态 = 业务功能模块插件）**。余（⏳ 见 [`errata.md`](errata.md) §三-25）：**内核侧插件的加载形态**（sidecar / WASM / dylib）、**商业条款**（分成、伙伴分级） |
| 6 | **`MetaUi` 是否接纳第二个渲染方**（移动端 Flutter）——现有口径是「UI 契约 = mmda-vue、`capability ui` 只在 `target ts`」（[`targets.md`](targets.md) §8-4） | 建议**接纳**：Flutter 作第二渲染方（新增 `target flutter`），**UI kit 仍不进后端契约、不进语言**；`targets.md` §8-4 的「只 ts」改成「ts + flutter」；一致性测试的 UI 维度**仍只测一个渲染方**（避免双份 UI 用例） |
| 7 | **移动端是否进首版承诺**（宿主已定 Flutter） | 首版**不做**（先 Web + 桌面）；Flutter 排在 **P8 之后**作为独立 `target`，届时先补 `target flutter` 的 `MetaUi` 渲染验证 |

---

## 9. 相关

- [`..\PLAN.md`](..\PLAN.md) — 落地计划（决策台账 §0、目标 §1、阶段 §4、待裁 §6）
- [`readme.md`](readme.md) — 语言规范总览
- [`index.md`](index.md) — 全部文档索引
- [`errata.md`](errata.md) — 待裁决口径与校勘（§五 是**已裁**记录）
