# 需求工程与需求过程（Requirements）

> **为什么有这篇**：m 语言的用户里有架构师、设计师、AI Agent、程序员，也有「通过 AI 开发可落地系统」的业务人员——**入口都是需求**。本文固定 MMDA 对需求过程的口径：**不替代需求工程方法论，但把需求产物变成一等对象（语言关键字 `intent`，编号 `INT-<NNN>`）并接进同一份真源**，让"需求偏差"从靠人盯变成**可机检的追溯链**。**语言面的唯一规范是 [`lang/intent.md`](lang/intent.md)**，本篇讲需求工程侧（谁写、怎么签、落点、门禁）。
> **来源**：作者 2026-09 随想录（原文留档 [`archive/2026-09/随想录.md`](archive/2026-09/随想录.md)）+ SERU 需求方法论（徐峰《软件需求最佳实践》笔记）+ **Anthropic《The AI-Native SDLC Playbook》**（Claude Academy 课程，14 课；本节引文取自该课程，逐字整理见 <https://github.com/yibie/ai-native-sdlc-playbook>）——它的 intent / spec 与本篇需求阶段的关系见 §4.2。
> 状态：草案（**2026-09-28 二轮裁定（取代本文原「三层需求」口径）：需求侧收为两档（`layer BUSINESS` / `USER`）、语言关键字 `intent`、编号 `INT-<NNN>`（模块段作废）、`subject` 必填、BUSINESS 不得直挂 usecase——以 [`lang/intent.md`](lang/intent.md) 为准；§0 / §2 / §2.1 / §2.2 / §3 / §5 / §7 已按此回改**；2026-09-24 立；**2026-09-25 作者补充**：需求即元对象（进语言 / 进库 / 进 IDE）、需求调研清单、why 与 what 不拆两个阶段、与 AI 原生 SDLC 的分界；**同日后半：语言文件后缀统一 `.m`、需求住阶段根 `intents/`**——见 [`project.md`](lang/project.md) §1 / §11 与 [`workflows-phase.md`](workflows-phase.md) §3）。联动：[`lang/intent.md`](lang/intent.md)（**语言面唯一规范**）、[`workflows.md`](workflows.md)（谁写、怎么签）、[`testing.md`](testing.md)（用例与追溯）、[`quality.md`](quality.md)（需求覆盖门禁、追溯链）、[`ide/specification.md`](ide/specification.md) §4.2（用例与需求条目）、[`readme.md`](readme.md) §8（与低代码的区别）。

---

## 0. 一句话立场

需求在 MMDA 里**各有落点**，而不是散在文档里：**业务需求 / 用户需求 → `intent`**（`layer BUSINESS` / `USER`，语言关键字 `intent`，编号 `INT-<NNN>`；USER 层必须声明 `role` 并由 **`usecase`** 细化）；**功能需求 → 不进 intent**，由 **S2 建模声明点**承载（字段、约束、状态机、Action、页面、接口——它们已是 How 的形状，经 `satisfies` 回指上来）；**非功能需求 → Profile 的 `quality.targets`**。**需求侧只有两档**，原第三档「功能」已归建模（§2.1、[`lang/intent.md`](lang/intent.md) §8）。

> **为什么收成两档**：**intent 是最先产生的产物**——先于模块树、模型与用例集。签发意图时模块树还不存在，所以「功能需求」不可能是意图的一档（它已经是 How 的形状）。详见 [`lang/intent.md`](lang/intent.md) §0 的三条推论。

**SRS（软件需求规格书）不再是"一份 Word"，而是"项目真源 + 可导出文档"**；评价需求的四标准（清楚 / 完整 / 一致 / 可测试）**不再只靠评审，而是各有机械可查的信号**（§3）。

> **✔ 2026-09-25 作者口径（why 与 what 不拆两个阶段）**：**需求阶段就是「搞清楚为什么和做什么」**——原话「你总是问他为什么要做，价值在哪里，然后要做成什么样、达到什么效果」「哪怕你跟 AI 对话，除了专业的工程师，一般人不会知道先写一个 intent.md，再写一个 spec.md」。因此 MMDA 里 **why 与 what 是同一条需求的两个必填面**，不是两个流程节点、也不是两个文件（与 AI 原生 SDLC playbook 的 intent / spec 对照见 §4.2）。

---

## 1. 需求为什么难（问题陈述）

- **鸿沟是客观存在的**：业务人员口述或笔述的需求常常**不完整、没想好**；IT 人员**不懂业务**，理解不准确、会遗漏；加上沟通过程的**信息损耗** → 需求偏差。这正是系统分析师这个角色的价值所在（业务知识 + 技术知识 + 沟通能力）。
- **所以需求过程注定多次反复**：耗时间、耗人力、耗成本，是一个复杂过程。
- **代价随阶段指数放大**：需求阶段花 1 个单位时间能改正的错误，拖到设计阶段约 5 倍、编码约 10 倍、测试 20–50 倍、运行与维护阶段可达 200 倍。
- **只有两条出路**：① 跨专业复合型人才（既懂业务又有高水平 IT 能力）把沟通成本省掉；② 用方法论 + 工具把损耗降下来。**MMDA 做第 ② 条，并且让第 ① 类人一个人也能跑完全程**——这与 [`workflows.md`](workflows.md) §1 的「五类职责是帽子、不按岗位划分」是同一件事：**帽子只决定签字，不决定能否写**。

---

## 2. 需求两档 × 落点 → MMDA 落点

| 需求档 / 类型 | 传统产物 | MMDA 落点 | 谁写（帽子） | 验收信号 |
| --- | --- | --- | --- | --- |
| **业务需求**（`layer BUSINESS`；业务事件、业务实体、业务规则、问题列表、目标与范围） | 项目视图 / 范围文档 | **`intents/INT-*.m` 的 `intent`（`layer BUSINESS`）** + `subject`（业务主题域，S1 分组轴）+ Profile 里的质量目标 | 架构师 | `subject` 非空；100% 被 ≥1 条 USER 意图以 `parent` 细化；**不得直接挂 `usecase`** |
| **关键用户（角色 / Role）** | 关键用户清单（SERU 要求**在需求阶段就识别关键用户**；RUP 里是 Actor） | **USER 层 intent 必填的 `role`** + **`intents/roles/*.m`**（与 `models/modules/*.m` 的模块分解**同级**，[`meta-model.md`](lang/meta-model.md) §8.1） | 架构师 + 业务专家 | 每个 USER 意图有 `role`；每个用例有触发者；无孤立角色（每个 Role 至少关联一个 Action） |
| **用户需求**（`layer USER`） | 用例文档（Use Case） | **`intents/INT-*.m` 的 `intent`（`layer USER`，必填 `role`）** + **`usecase` 细化**（`usecase UC-… : INT-…`，住 `intents/`） | 设计师 | 100% 有 `role`；≥1 条 `usecase` 细化；≥1 条 UAT 用 `req: INT-…` 回指；零 orphan |
| **功能需求**（**不进 intent**） | SRS 的功能章节 | **S2 建模声明点**：`models/objects/*.m` 字段与约束、`@Computed`、Converter、Action、stm 迁移、页面、接口——经 `satisfies` 回指 | 设计师 | 100% 有 `satisfies`（指向 usecase 或 intent）；字段级机械用例覆盖 100% |
| **非功能需求** | SRS 的非功能章节 | Profile `quality.targets`（性能 / 可靠性阈值，[`quality.md`](quality.md) §2.2）+ capability 声明 | 架构师 | 目标值缺失本身即 A 类不合格（[`quality.md`](quality.md) §1.2） |
| **设计约束** | SRS 的约束条目 | capability / `protection` / 方言表 / `conventions.md` | 架构师 | 声明与生成物一致（一致性测试，[`targets.md`](targets.md) §5） |

> 读法：**文档（需求）与模型（设计）不是两份东西**——需求是 `intent`（Why / What），模型是它的展开（How）。可追溯靠**下游单向回指**（`parent` / `usecase : INT-…` / `satisfies` / UAT `req: INT-…`），反向索引由内核算（`mmda trace INT-…`）。这样"需求变了"必然触发影响面计算，而不是靠人记得去改文档。详见 [`lang/intent.md`](lang/intent.md) §4。

> **惯例（✔ 已裁 2026-09-24）**：**关键用户即角色（Role）在需求阶段识别**——因此到了架构设计阶段，**Role 与 Module 分解同等重要**，两者都进 m 语言。**组织架构 / 岗位 / 职员是「数据」**（普通 `Record` + 关系），是角色的**实例来源**，不是同一层的东西。详见 [`meta-model.md`](lang/meta-model.md) §8.1。

### 2.1 需求两档 ↔ 模块三级（System / Module / Feature）· 功能层归建模

> **作者问题（2026-09-25）**：「我要对需求进行管理，分三层：业务、用户、功能，对应我之后的模块分解：System, Module, Feature，你觉得是否可行？」——**判断：可行，而且比传统需求文档更严**；但对应关系不是 1:1，而是**「逐层细化 + 归属」**。
> **✔ 2026-09-28 二轮裁定**：需求侧**只留两档**（业务 / 用户）；原第三档「功能需求」**不进 intent**——`intent` 先于模块树存在，功能需求已是 How 的形状，由 S2 建模声明点承载。规范见 [`lang/intent.md`](lang/intent.md) §2.1 / §8。

| 需求档 | 归属节点（由 S2 侧 `satisfies` 回指得出） | 粒度判据 | 谁签 | 覆盖率门禁 |
| --- | --- | --- | --- | --- |
| **业务需求**（`layer BUSINESS`） | **System**（`models/modules/*.m` 顶层，编号如 `M`）或 **Module** | 一条 = 一个业务主题域（`subject`）/ 业务事件 / 业务规则，回答「为谁解决什么问题、不解决会怎样」 | 架构师 + 业务 | 100% 有 `subject`；100% 被 ≥1 条 USER 意图以 `parent` 细化 |
| **用户需求**（`layer USER`） | **Module**（`M.01`）或 **Feature**（`M.01.001`）+ **Role** | 一条 = 一个关键用户的一个可观察结果，由 `usecase` 细化 | 设计师 + 业务 | 100% 有 `role`（触发者）、≥1 条 `usecase`、≥1 条 UAT（`req: INT-…`） |
| **功能需求**（**不进 intent**） | **Feature** → 具体声明点 | 一条 = 一处可判定契约（字段 / 约束 / Action / 迁移 / 界面元素） | 设计师 | 100% 有 `satisfies` 回指（UC 或 INT）；用例覆盖 ≥ 90%（[`testing.md`](testing.md) §6） |

**为什么不是 1:1**：一个 System 通常由多条业务需求共同支撑（N:1），一条业务需求往往落到多个 Feature（1:N）——**强做 1:1 会在第一次跨模块业务事件上破功**。所以「对应」的真实含义是：**每条需求必须有归属节点，归属由 S2 侧的 `satisfies` 回指算出**——`BUSINESS → System / Module`、`USER → Module / Feature`；这正是可机检的部分（`mmda check` 出 error，[`lang/intent.md`](lang/intent.md) §7-12）。

**与既有口径的一致性**：SERU 的 `S`（Subject Area，按业务区划分解）现在是 **intent 的必填子句 `subject`**，S2 建模时由它细化为 System / Module。**需求编号不能再挂模块编码**（`REQ-<模块编码>-<NNN>` 作废，改纯序号 `INT-<NNN>`）——因为 intent 签发时模块树还不存在；模块归属改由 `satisfies` 回指得出，**不做「迁模块即换号」**。

**命名现状（撞名，待裁）**：三级模块在同一份规范里有两个叫法——[`meta-model.md`](lang/meta-model.md) §8 与 [`glossary.md`](glossary.md) §4 用**一个元素 + `moduleType` 0/1/2**（`0` Subsystem / `1` Module / `2` Feature），[`ide/workflow.md`](ide/workflow.md) 第 1 步写「系统（App）→ 模块 → 功能特征」，[`readme.md`](readme.md) §3 写 `Subsystem / Module / Feature`；作者口径是 **System / Module / Feature** → 见 §7-10。

### 2.2 需求是元对象：进语言、进库、进 IDE

> **✔ 2026-09-25 作者口径**：原话「**我的想法是 m 语言中对需求建模，可以存在我的数据库里，像元对象一样，我能用 m 语言描述它们，IDE 能图形化、表格化管理它们，包括 CRUD、变更管理、进度状态跟踪等**」。

| 面 | 口径 | 依据 / 落点 |
| --- | --- | --- |
| **进语言** | 意图（与用例）是**一等声明**，与 `record` / `enum` / `stm` / `role` 同级；**就是普通 `.m` 文件**（语言文件后缀统一，2026-09-25），首关键字 **`intent`** / `usecase` 判 partType，住**阶段根 `intents/`**；`intent` 是**最先的产物**——**不写 `feature` / `satisfiedBy` / `accept`**（模块树是 S2 的产物） | 语言面规范 = [`lang/intent.md`](lang/intent.md)（**唯一真源**：语法 / 门禁 / 编号 / 单向回指）；与「Role 进语言」（[`meta-model.md`](lang/meta-model.md) §8.1）同一层级逻辑；目录见 [`project.md`](lang/project.md) §1；**粒度 ✔ 已裁（2026-09-28，§7-7）**：与 `record` 同——**一文件可放多条 `intent`**（一文件一条是推荐、非硬规则），同文件内引用不写 `import`、跨文件用 `import`（[`runtime.md`](runtime.md) §4.7） |
| **进库** | ✔ **走元对象路线（2026-09-28 裁，解 D0 = A）**：落内核 **`Meta*` 族**（拟 `MetaIntent` + 关联表），供运行时与 IDE 直读；**不落** `mmda_alm.requirement` 业务表（**⤴ 2026-09-29 四轮：该库仅作参考、将废除，「投影 / 缓存」随之取消**；参见 [`examples/alm/差异对照.md`](examples/alm/差异对照.md) D0）；**表结构设计 = [`lang/intent-store.md`](lang/intent-store.md)**（列 ↔ 语言子句逐条对；与 `requirement` 的对照**降为参考**；草案 v4） | ⚠️ **单向流不变**：文件（git）是真源，库里的意图是**产物 / 缓存**（[`PLAN.md`](../PLAN.md) §3.2、[`project.md`](lang/project.md) §0）。运行期在库里改了意图 → **必须回写文件并进版本控制**（[`workflows.md`](workflows.md) §2 第三个时间面）；**写入口仍待裁**（§7-11） |
| **进 IDE** | 图形化（需求树 / 追溯矩阵 / 用例图）+ **表格化**（需求清单：层 / 优先级 / 状态 / 归属 / 覆盖 / 验收）+ CRUD + 变更管理（走变更分级 L0–L3）+ 进度状态跟踪 | [`quality.md`](quality.md) §5 的「需求矩阵」面板、[`ide/specification.md`](ide/specification.md) §4.2 |
| **双格式** | **人写人审走文本声明，AI 与工具走 IR / JSON**——同一份内容两条通道，做法同 `MetaEnum` 的 `toString` / `toJson`（[`meta-model.md`](lang/meta-model.md) §6.1） | 作者要求「**AI 和人类都能理解的格式都要**」 |
| **验收面** | 每条 **USER 意图**必须带**可执行的验收准则**（UAT 用例，用 `req: INT-…` 回指），随**意图基线**一起冻结；**没有可执行 UAT 的意图 = 还没说完**（`mmda check` error） | UAT 的地位 / 时点 / 执行通道见 [`testing.md`](testing.md) §0.1 / §9.1；0 站产物见 [`workflows-phase.md`](workflows-phase.md) §3；门禁清单见 [`lang/intent.md`](lang/intent.md) §6 / §7 |
| **自动编号** | **`INT-<NNN>`**（意图）/ **`UC-<NNN>`**（用例）——**纯序号，不含模块段**（`REQ-<模块编码>-<NNN>` 已作废）；**内核生成，人不手写、AI 不编**；单调、不复用、不重排；**层次 / 优先级 / 标题 / 模块不进编号**（会变的东西不进主键）；**不做「迁模块即换号」** | 口径见 [`lang/intent.md`](lang/intent.md) §5；`INT-` 已被 [`testing.md`](testing.md) §9.1（`kind: uat` 的 `req: INT-…`）与 [`api.md`](api.md) §6（「待回收的需求（`INT-x` → 声明 → 用例）」）两处引用锁定 |

---

## 3. 优秀需求的四标准 → 逐条给机械信号

传统上这四个标准靠**评审**保证（分层次、分内容）。在 MMDA 里可以各自落到一条**可自动算的信号**上——这是本文最重要的一张表：

| 标准 | 传统做法 | MMDA 可机械检查的信号 | 等级 |
| --- | --- | --- | --- |
| **清楚** Clear | 评审、不得有歧义 | 术语唯一（[`architecture-review.md`](architecture-review.md) ARCH-401 `Terminology` 复用率）；每个字段有中文标签；命名注册表；无未定义约束（[`errata.md`](errata.md) 语法待裁 1） | A |
| **完整** Complete | 分层评审（高层 / 中层 / 操作层） | 每条 USER 意图（`INT-…`）有 ≥1 `usecase` + ≥1 模型声明 + ≥1 UAT；字段 / 迁移 / 权限 / 能力四维覆盖 100%（[`testing.md`](testing.md) §6） | A / B |
| **一致** Consistent | 交叉核对 | 无循环依赖、无重复定义、跨模块引用只走声明接口、枚举 vs 字典表不混用（ARCH-102 / 105 / 204 / 402） | A |
| **可测试** Testable | 编写验收准则 | 机械用例可生成率；变异存活率 ≤ 10%（[`testing.md`](testing.md) §7） | A / B |
| **可跟踪** Traceable | 人工维护跟踪矩阵 | 追溯链 `INT-…` → usecase → 声明点 → 生成物 → 运行指标 → 缺陷 → 回归用例（[`quality.md`](quality.md) §5） | A |
| **可修改** Modifiable | 影响面分析 | `mmda diff --impact` 的对象数与变更级别 L0–L3（[`workflows.md`](workflows.md) §8） | A |

**这张表就是 MMDA 对"需求质量"的答案**：四标准不再是"评出来的"，而是"算出来的"。没写成声明的质量要求等于没有验收标准（[`quality.md`](quality.md) §0 原则 1）。

---

## 4. 需求方法论与调研输入（SERU · 调研清单 · AI 原生 SDLC）

SERU 是需求方法论（S / E / R / U 四要素），**遗留系统项目同样适用**：在 S 层判断"这是一个新主题域，还是对某些既有主题域产生影响"；在 E 层判断"新添或修改了哪些业务事件"。

| 要素 | 原意 | MMDA 落点 | 现状 |
| --- | --- | --- | --- |
| **S** Subject Area | 按**业务区划**分解系统（强调业务分析，不是功能分解），使各部分业务上相对独立、降低耦合 | **两段落点**：S1 = **intent 的必填子句 `subject`**；S2 = `models/modules/*.m` 的模块树（System / Module / Feature）+ 系统逻辑架构图 + 层级菜单 | **已有**（[`lang/intent.md`](lang/intent.md) §2.2、[`readme.md`](readme.md) §3 L1、[`ide/workflow.md`](ide/workflow.md) 第 1 步） |
| **E** Event | **业务事件是流程的起点**；通过事件找到流程，把不同场景串接起来 | `models/flows/*.m` 的流程节点 + [`events.md`](lang/events.md) 的事件声明 | **已有** |
| **R** Report | 从**管控点**出发（从意图出发）确定报表类型，再细化到具体报表项 | 视图 / 报表 / 看板：语言侧只声明**数据源与主题**，报表与 BI 归 IDE 工具面（**见 §7 待裁 3**） | **部分**（呈现层五视图；BI 元数据族目前只在 C# 侧，见 [`contracts-inventory.md`](contracts-inventory.md) §5 报表行） |
| **U** Use Case | 用例是**需求组织的最小单位**，强调用户视角而非功能分解 | **`usecase` 一等 partType**（`usecase UC-… : INT-…`，住 `intents/`）+ UML 图形投影 + feature/action 实现 | ✔ **已裁（2026-09-28）进语言并上图形**（[`lang/intent.md`](lang/intent.md) §4.1、[`ide/diagram-adapters.md`](ide/diagram-adapters.md) §7） |

**SERU 的需求开发过程与任务集**（四阶段 20+3 个任务、一般 3 次循环出合格产物）与我们的映射：需求定义（目标/范围）→ 模块树与质量目标；梳理脉络（流程/用例/领域模型）→ 流程 + STM + 局部 ER；填充细节（功能/数据/报表/接口/质量场景/约束）→ 字段约束 + View + capability/Profile。**验收侧对应**：[`testing.md`](testing.md) 的用例生成与 [`quality.md`](quality.md) 的可判定信号。

### 4.1 需求调研清单（作者老套路 → 可机检落点）

> **✔ 2026-09-25 作者口径**：原话「**我的老套路通常会搞清楚客户的组织架构、关键用户以及他们的责权、工作流程和关键控制点、收集日常的工作表格和汇报需要的报表，调研清楚其中的每一项数据的来龙去脉。为我下一阶段的架构、设计、建模、开发打下基础**」。

这张表把「调研什么」变成「调研完必须留下什么声明」——**调研没有落成声明的，等于没调研**（[`quality.md`](quality.md) §0 原则 1）：

| # | 调研项 | 传统产物 | MMDA 落点 | 调研完成的判据（可机检） |
| --- | --- | --- | --- | --- |
| 0 | **业务目标与范围**（要解决什么问题、不解决会怎样） | 项目视图 / 范围文档 | **`intent`（`layer BUSINESS`）**：`subject` + `why` / `what`（[`lang/intent.md`](lang/intent.md) §2） | 每条已有 `subject` 与 ≥1 条 `why` / `what`；BUSINESS 100% 被 ≥1 条 USER 以 `parent` 细化 |
| 1 | **组织架构** | 组织架构图 / 岗位矩阵 | **数据**：部门树 / 岗位 / 任职的 `Record` + 关系（不新增元模型元素） | 组织树无环；岗位 → Role 的映射齐（该映射规则见 [`meta-model.md`](lang/meta-model.md) §8.1 余项） |
| 2 | **关键用户与责权** | 关键用户清单 | `flow/roles/*.mr`（`role` + `auth module` / `actions` / `scope`） | 每个 Role ≥ 1 个 Action；每个 Action 有授权角色；数据范围字段齐（`creatorId` / `ownerId`） |
| 3 | **工作流程与关键控制点** | 流程图 / 审批矩阵 | `flow/*.mb`（BPMN 池 / 活动 / 网关）+ `data/stms/*.ms`（状态与迁移）+ Action 守卫 | 每条流有触发者与结果事件、无孤立节点；**每个控制点都有一条可判定的校验声明**（约束 / 守卫 / 权限） |
| 4 | **日常工作表格（单据）** | 表格样本 / 单据样张 | `Record` + 字段约束 + 五视图（`ui/**/*.m`） | 每张单据的字段 × 必填 × 边界用例覆盖 100%（[`testing.md`](testing.md) §6） |
| 5 | **汇报报表** | 报表样张 | 视图 / BI：语言侧只声明**数据源与主题**（报表归属见 §7-3） | 每个报表能指到数据源与度量口径（无「手算」项） |
| 6 | **每一项数据的来龙去脉** | 数据字典 / 手工台账 | **字段级血缘**：来源（录入 / 引用 / 计算 / 外部导入）+ 去向（谁读 / 哪些报表 / 哪些下游）+ 约束 | **数据血缘矩阵**：每个字段一条链；断链（无来源或无去向）出 warning |

> 第 6 条是这张表里最容易漏、也最值钱的一条：它把「数据字典」从一份文档变成**可查的链**，而链的两端正好接上已有的机制——来源侧是 `@Computed` / `@Ref` / Converter，去向侧是视图、报表、事件与 API（[`api.md`](api.md) §1、[`event_bus.md`](lang/event_bus.md) §8）。**「数据的来龙去脉」不落成链，需求阶段就只剩下文档。**

### 4.2 与 AI 原生 SDLC（intent / spec）的关系

**来源**：Anthropic《The AI-Native SDLC Playbook》（Claude Academy，14 课）。它的六个阶段是 **Plan / Design / Build / Test / Deploy / Maintain**，与本仓四站主干（[`workflows-phase.md`](workflows-phase.md) §3）的对照：它的 Plan + Design = 我们的 **0 站（意图）+ 1 站（模型）**；Build = 2 站；Test = **验证腿**；Deploy = 3 站；Maintain = **运行腿**。

它给两样东西起了新名字。我们的判定是**采纳意图、不采纳文件形态**：

| 它的东西 | 它的原文口径 | 我们的落法 |
| --- | --- | --- |
| **intent.md** | 「a short version-controlled file that states **what is wanted, why, and under which constraints**」；模板字段 = Problem / Proposed outcome / Affected users and systems / Constraints / Open questions | **采纳 `intent` 这个概念本身，并把它升格为 m 语言的关键字**：住 `intents/` 的 `*.m` 声明，**不是 `.md`**（一文件可放多条，与 `record` 同——✔ 2026-09-28）。它的三样（What / Why / Constraints）**正是 intent 的必填面**：`what` / `why` / `subject` + Profile 阈值；模板五字段逐一映射到 intent 子句与 §4.1 的调研项。见 [`lang/intent.md`](lang/intent.md) |
| **spec.md** | Stage 2 由 Claude 从 intent.md 产出 requirements and design spec；产品负责人**审而不写** | 它把**需求与设计合成一份 spec**；我们**分开**——需求住 0 站（`intent` + `usecase`）、设计住 1 站（S2 建模声明点，产出 spec；作者口径：需求阶段只到「为什么 + 做什么」） |
| **是否拆两个阶段** | 它分了 Stage 1（Plan）/ Stage 2（Design），但同一课里自己也写着「**Both phases happen in a single prompted session**」 | **不拆**：作者口径见 §0——**why 与 what 是同一条需求的两个必填面**，不是两次交付 |
| **它的治理证据** | intent.md 的作者 + 时间戳 + 修订历史；**accept / reject 记录为合并或关闭的评审**；lagging 指标 = 采纳存活率、intent 在首个 spec 之后的改动次数 | 我们的对应物：`Status` 从 `candidate` → `confirmed` 的状态迁移 + `changelog/` + **候选需求采纳率 / 需求确认后的改动次数**（IDE 面板即可算） |

**一句话**：它解决的是「**人只写意图，其余交给 Agent**」；我们要多做一步——**意图必须变成可机检、可追溯、可生成用例的声明**。所以它的 `.md` 换成意图文件族（语言关键字 `intent` + `usecase`），它的「评审」换成**三道闸 + 签字**（[`workflows.md`](workflows.md) §6.2）。

---

## 5. 需求管理四步 → 已有机制对照

| SERU 建议的改进四步 | MMDA 已有机制 | 落点 |
| --- | --- | --- |
| ① 统一明确的需求项**划分标准** | **需求两档**（`layer BUSINESS` / `USER`）+ 语言关键字 `intent` + 归属节点（System / Module / Feature，由 `satisfies` 回指算出）+ **`INT-<NNN>` 纯序号**自动编号（见 §2.1 / §2.2）；**粒度 = 一文件可放多条 `intent`**（§7-7，与 `record` 同） | 本文 §2.1 / §2.2、[`lang/intent.md`](lang/intent.md)、[`project.md`](lang/project.md) |
| ② 引入**基线管理** | 项目真源（一对象一文件）+ `changelog/` + git/svn；“基线”机制 | [`project.md`](lang/project.md)、[`testing.md`](testing.md) §5 |
| ③ 引入**变更管理** | 变更分级 L0–L3 + 按模式分列的签字要求 | [`workflows.md`](workflows.md) §8 |
| ④ 引入**需求跟踪** | 追溯链 + orphan 检测（不可追溯的用例不计覆盖率、CI 报警） | [`testing.md`](testing.md) §1.2、[`quality.md`](quality.md) §5 |

**需求验证的关键手段是评审**（分层次、分内容，早期尽量暴露问题）——MMDA 的对应物是 **review 三层**（[`quality.md`](quality.md) §4）：**能机检的先机检（L0 必过）→ AI 只做可证伪的提示（L1 可验证才阻塞）→ 人只做价值取舍与签字（L2）**。

---

## 6. SRS 在 MMDA 里的形态（待裁）

传统 SRS = 一份图文文档（UML 用例图、数据流图等）。MMDA 的形态是：**真源是项目文件，SRS 是可导出的视图**。要裁三件事：

1. **导出形态与章节映射**：Markdown（默认）/ Word（模板）/ PDF；哪个元素进哪一章（`intent`（`layer BUSINESS`）→ 业务需求章节；`intent`（`layer USER`）+ `usecase` → 用户需求章节；模块树 → 范围章节；Record → 数据章节；STM → 行为章节；质量目标 → 非功能章节；建模声明点 → 功能章节）。
2. **图表怎么进 SRS**：图形是**投影**（[`ide/graph-files.md`](ide/graph-files.md) 的 `*.g` 只存布局），导出时要不要渲染图（渲染则依赖图形引擎，导出即重放布局）。
3. **SRS 的基线冻结方式**：按版本打 tag，还是按 `baseline` 快照（[`testing.md`](testing.md) §5）。

---

## 7. 待裁

| # | 议题 | 建议 |
| --- | --- | --- |
| 1 | ~~`REQ-x` 进语言还是 IDE 侧清单~~ → **✔ 已裁（2026-09-25）：进语言**（一等声明，与 `record` / `enum` / `stm` / `role` 同级；进库与 IDE 管理面见 §2.2） | —— |
| 2 | ~~用例（`UseCase`）是否进语言并上图形~~ | ✔ **已裁（2026-09-28）**：**进**——`usecase` 是一等 partType（`usecase UC-… : INT-…`，住 `intents/`）；图形 = **UML 用例图 / 活动图**投影（适配器 `mmda.designer.muc-uml`，[`lang/intent.md`](lang/intent.md) §4.1） |
| 3 | 报表与 BI 的归属（进语言核心 / IDE 工具面 / 移植 C# 的 `MetaBi*`） | 建议**不进语言核心**：语言只声明数据源与业务主题，报表与看板做成 IDE 工具面（[`ide/specification.md`](ide/specification.md) §4.8 域 8） |
| 4 | SRS 导出形态（§6） | 建议默认 Markdown、Word 由模板生成；图表按 `*.g` 布局渲染 |
| 5 | 需求覆盖门禁是否分层次 | ✔ **已裁（2026-09-28）**：**按档分两档**——BUSINESS 100% 被 ≥1 条 USER 以 `parent` 细化；USER 100% 有 `role`、≥1 条 `usecase`、≥1 条 UAT；功能声明点的用例覆盖 ≥ 90%（[`lang/intent.md`](lang/intent.md) §7、[`testing.md`](testing.md) §6） |
| 6 | 需求条目与「业务人员通过 AI 提需求」路径怎么衔接 | 建议：业务人员的话经 AI 转成**候选需求条目 + 候选模型差异**，由设计师落盘（[`workflows.md`](workflows.md) §7 三条红线不变） |
| 7 | ~~需求文件的后缀与粒度~~ → **✔ 全部已裁**：后缀 **`.m`**（2026-09-25；`.mr` 连同整个分片族作废）；**粒度（2026-09-28）= 一文件可放多条 `intent`**，与 `record` 同（一文件一条是**推荐、非硬规则**；同文件内相互引用不写 `import`，跨文件用 `import`；文件名自由，编号写在声明里） | [`lang/intent.md`](lang/intent.md) §1、[`project.md`](lang/project.md) §6 |
| 8 | ~~`REQ` 编号是否含模块编码段~~ | ✔ **已裁（2026-09-28）**：**不含**——改**纯序号 `INT-<NNN>`**（用例 `UC-<NNN>`）。intent 签发时模块树还不存在；模块归属由 S2 侧 `satisfies` 回指得出，**不做「迁模块即换号」**（[`lang/intent.md`](lang/intent.md) §5） |
| 9 | ~~三层需求 ↔ System / Module / Feature 的对应形态~~ | ✔ **已裁（2026-09-28）**：需求侧**两档**（`BUSINESS` → System / Module；`USER` → Module / Feature）+ **功能层归建模**；归属由 `satisfies` 回指算出，进 `mmda check` 出 error；**不做 1:1 映射**（§2.1、[`lang/intent.md`](lang/intent.md) §7-12） |
| 10 | 模块三级的命名统一：元模型现为一个 `Module` + `moduleType` 0/1/2（[`glossary.md`](glossary.md) §4、[`meta-model.md`](lang/meta-model.md) §8）／ 作者口径为 **System / Module / Feature** | 建议**三级各给一个名字**（System / Module / Feature），`moduleType` 保留为内部编码；`ide/workflow.md` 的「系统（App）」与 `readme.md` 的 `Subsystem` 一并对齐 |
| 11 | 需求进库的写入口：IDE 的 CRUD 是「改文件 + 回写库」还是允许直改库 | 建议**只允许改文件**（真源唯一）；库直改只作运维应急且必须回写（[`workflows.md`](workflows.md) §2、§12-4） |

---

## 8. 来源

- 作者随想录（原文，未改写）：[`archive/2026-09/随想录.md`](archive/2026-09/随想录.md)
- 《什么是软件需求》<https://zhuanlan.zhihu.com/p/81261956> —— 需求的三层次 / 三类型、优秀需求的四标准、需求工程两个过程域、需求开发四活动与三次循环、需求管理四步、需求分析人员技能构成、SERU 过程框架全景图。
- 《软件需求最佳实践》笔记 <https://zhuanlan.zhihu.com/p/81057538> —— SERU 四要素（S/E/R/U）与「四阶段 20+3 个工作任务集」。系列文章见该文末尾链接；SERU 出自**徐峰**老师的软件需求最佳实践课程。
- 需求阶段错误代价的放大比例：见上第 1 篇（知乎笔记转引）。
- Anthropic《The AI-Native SDLC Playbook》（Claude Academy，14 课）<https://academy.claude.com/courses/ai-native-sdlc-playbook> —— AI 原生 SDLC 的六阶段（Plan / Design / Build / Test / Deploy / Maintain）、`intent.md` 模板（Problem / Proposed outcome / Affected users and systems / Constraints / Open questions）、「requirements and design 在同一次会话里产出」、治理证据与采纳存活率指标。本文 §4.2 的对照即据此；中英对照全文（第三方整理）<https://github.com/yibie/ai-native-sdlc-playbook>。
