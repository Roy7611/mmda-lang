# 用户体验（UX）

> 版本 **0.1** · 2026-09-24
> **真源归属**：本文管**体验目标与可判定判据**；**不管 UI 契约**（[presentation.md](presentation.md) §5.1）、**不管质量度量与门禁**（[quality.md](quality.md) §1.4 / §2）、**不管前端命名**（[naming.md](naming.md) §3.4）。
> **材料来源**：作者的 `D:\项目\UX`（`学习笔记.docx` 2,092 字 / 31 段 + 6 张图；`UX 广义.webp` / `UX 狭义.webp`；`设计心理学.pdf` 247 页扫描件）。**源材料不进仓**——理由与边界见 §9。
> **已裁前提（不重开）**：唯一 UI 通道 = `MetaUi` → mmda-vue；前端本地命名放宽；客户端监控首版只做 Web。

> 作者笔记原话（本文的全部结论都从这几句推出）：
> 「广义的用户体验设计，是包含了内容功能设计，信息架构设计，用户界面设计，交互设计，视觉设计，语言设计，动效设计，音效设计，在一定程度上涵盖了产品物理外观设计（工业设计），平面/包装设计，空间设计，服务流程设计等。它意味着一个高度交叉综合的领域，涉及到人与产品系统或服务发生关系并产生体验的所有触点。」
> 「用户体验设计的核心和本质，就是研究目标用户在特定场景下的思维方式和行为模式。」
> 「认知心理学（Cognitive Psychology）则是用户体验设计的理论基础和科学依据。」

---

## 0. 一句话与边界

**一句话**：UX 篇把「体验」从**审美判断**变成**工程可判定的信号**——每一条原则都落到「`MetaUi` 的哪项声明 / `mmda check` 的哪条信号 / 哪个视图」上，而不是落到「设计师觉得好不好看」。

| ❌ 不做 | 理由 |
| --- | --- |
| **不在语言层新增体验关键字** | 与既有裁决同口径（[runtime.md](runtime.md) §7、[event_bus.md](event_bus.md) §1.3「语言层零新增」）；体验信息都能从既有声明推导 |
| **不做第二套 UI 契约** | [presentation.md](presentation.md) §5.1 已裁：唯一通道 = `MetaUi` → mmda-vue |
| **不给审美设硬门禁** | 审美与产品判断属 **D 类**（只能人评，见 [quality.md](quality.md) §1.2）；把 D 类当门禁会拖累 A 类判定 |
| **不把源材料（书 / 第三方图）搬进仓** | 版权，见 §9 |
| **不引入 UX 专有量纲** | 度量与分级沿用 [quality.md](quality.md) 的 A/B/C/D 与三层度量，**不另造一套** |

---

## 1. 术语：先把 UX 与 Usability 分开

| 概念 | 定义与出处（笔记原文） | 在我们文档里怎么写 |
| --- | --- | --- |
| **可用性 Usability** | **1979 年**即有，比 UX 早；ISO 定义 = 「用户在特定环境下完成指定目标的效果、效率和满意度」（**ISO 9241-11**） | 只在**任务完成**语境用（表单能不能填完、流程能不能走通）；[quality.md](quality.md) §2 的性能/可用性阈值属此列 |
| **用户体验 UX** | 唐·诺曼 **1993** 年提出；「用户与产品、服务、设备或环境交互时各方面的体验和感受」——**范畴比可用性宽**，是外观呈现、功能组合、系统性能、交互行为的**综合结果** | 本文的统称 |
| **交互能力 Interaction capability** | **ISO/IEC 25010:2023** 的特性名（原 `usability`） | **质量模型专用词**，归属 [quality.md](quality.md) §1.4——**不要拿它当 UX 的同义词**（两代标准的命名对照见 `quality.md` §1.0/§1.1） |
| 相关学科 | **认知心理学** = 理论依据（记忆 / 注意 / 感知 / 知识表征 / 推理 / 创造力 / 问题解决）；**人体工学 Ergonomics** 与 **人因工程 Human Factors Engineering** = 研究人与机器、环境的相互作用与合理结合，达到**效率 / 安全 / 健康 / 舒适** | 前者支撑 §3 的设计判据；后者支撑 [quality.md](quality.md) §2.2 的性能阈值与中文验收单 |

---

## 2. 体验四层（环）：Utility → Usability → Desirability → Brand Experience

来源：作者笔记里的四层圆（配图出自 **User Experience 2008, nnGroup Conference Amsterdam**）。四层自述（原文）：

| 层 | 自述 | 在我们这里由谁负责 | 在哪判定 |
| --- | --- | --- | --- |
| **Utility 有用** | It is useful to me. It meets my needs. | **元数据与用例的覆盖面**（需求 → `Record`/`Action`/`Role`） | [requirements.md](requirements.md) 追溯链、[testing.md](testing.md) 覆盖率 |
| **Usability 可用** | I am able to use the product easily. | **生成物的默认行为**（五视图、字段可见性、校验与错误恢复） | [presentation.md](presentation.md) §2、[quality.md](quality.md) §1.4 |
| **Desirability 合意** | I like the way the product looks and feels. | **皮肤（`vui*` / `rui*`）与主题**——前端自由 | [presentation.md](presentation.md) §5.1 界限 2 |
| **Brand Experience 品牌体验** | My overall feeling about the brand/product is good. | **同一份真源带来的产品一致性** | [targets.md](targets.md) §5 跨端一致性测试 |

**两条推论（可直接用的判据）**：

1. **四层是包含关系**：内层不成立，外层无意义——**生成器必须先把 Utility / Usability 做对**（功能与字段齐全、校验与错误消息齐全、状态反馈齐全），Desirability 才交给皮肤。首版不承诺「好看」，承诺「有用 + 可用」。
2. **品牌体验不靠统一 UI 库，靠统一真源**：skin 可以换（[presentation.md](presentation.md) §5.1），但字段名、枚举标签、视图语义、错误消息、动作命名**只有一份**（[naming.md](naming.md) §2 契约名清单）——**一致性来自元数据，不来自组件库**。这也是「不做第二套 UI 契约」的体验侧理由。

---

## 3. 理论基座：认知心理学与人因 → 五条可落地的设计判据

诺曼的概念（示能、意符、映射、反馈、概念模型、人的差错）**照着看不是玄学，每条都能翻成我们的声明**：

| 概念 | 通俗说法 | MMDA 里对应什么（判据） |
| --- | --- | --- |
| **示能 Affordance + 意符 Signifier** | 一个东西「看起来能怎么用」与「实际能怎么用」必须一致 | 字段**能不能改**只由声明决定（`readOnly` / `hidden` / `lockIf`）；**皮肤不许自行改变可编辑性**——「看着能改其实改不了」是最经典的事故 |
| **映射 Mapping** | 控制与结果的位置/顺序要自然对应 | 字段顺序与分组 = `groupLabel`（[presentation.md](presentation.md) §3）+ 关系布局顺序 `relationIdx`（[meta-model.md](meta-model.md)） |
| **反馈 Feedback** | 每个动作后必须有可见变化 | `Action` 元数据 + 事件链（[event_bus.md](event_bus.md)）；运行期看 [operations.md](operations.md) §3 的 `traceId`/`eventId`/`correlationId` |
| **概念模型 Conceptual model** | 用户脑中的模型要与系统模型一致 | 术语唯一（[glossary.md](glossary.md) §3.1/§3.2）；**一个概念一个主人** |
| **人的差错 Human error** | 差错多是设计造成的，不是人笨 | **错误预防优于错误提示**：必填/范围/唯一/非法状态迁移在**声明层**表达（[records.md](records.md)、[statements.md](statements.md)、`.ms`），让生成物**默认可拦**；提示文案只是兜底 |

**归因原则（来自《设计心理学》序里的核电事故研究）**：诺曼写三哩岛核电站事故——事故责任**不在操作员，而在控制室的设计**（仪表盘不合理，像是**有意**诱发操作错误）。**工程对应**：把「用户点错了 / 填错了」当成**设计缺陷**追一遍——视图是否给了歧义、流程是否可逆、权限是否清楚；与 [operations.md](operations.md) 的**告警四项规范**（现象 / 影响面 / 第一个排查动作 / 可行动作）是同一种精神：**让人能做对的事，而不是怪人做错。**

---

## 4. 尼尔森十大原则 → MMDA 可判定检查清单（本文核心）

作者的笔记里逐条列了中英对照（来源 `nngroup.com/articles/ten-usability-heuristics/`）。这边把它**对着我们的生成物**过一遍——**等级沿用 [quality.md](quality.md) §1.2 的 A/B/C/D**（A 可自动 / B 可半自动 / C 需实测 / D 只能人评）：

| # | 原则 | 在 MMDA 生成物里的体现 | 主要判据落点 | 等级 |
| --- | --- | --- | --- | --- |
| 1 | 状态可见（Visibility of system status） | 动作后有状态变化与提示；列表页用 `fixedFilter` 做**状态页签**；单据状态列不隐藏 | `Action` 元数据、[meta-model.md](meta-model.md) `fixedFilter`、[event_bus.md](event_bus.md) 通知器 | A |
| 2 | 环境贴切（Match between system and the real world） | 界面用**业务词**：`label`、枚举标签、i18n 词条齐全（不用数据库缩写、不用拼音） | [presentation.md](presentation.md) §5 i18n、[naming.md](naming.md) §2（i18n key） | A |
| 3 | 用户可控（User control and freedom） | 破坏性动作**二次确认**；流程可逆（STM 允许回退的状态迁移）；草稿态 | [quality.md](quality.md) §1.4「用户差错防护」、`.ms` 状态机 | A / B |
| 4 | 一致性（Consistency and standards） | 同一动作跨模块同名、同一含义同一标签；日期/小数格式统一（`formatter` = `D` / `N3`） | [naming.md](naming.md) §1/§2、[presentation.md](presentation.md) §2 | A |
| 5 | 防错（Error prevention） | 约束写在**声明层**（必填、范围、唯一、长度）→ 生成物两侧（前端 + 服务端）**同时**拦截 | [records.md](records.md) 约束、[api.md](api.md) §3.5 | A |
| 6 | 识别优于记忆（Recognition rather than recall） | 引用字段给**下拉 / `searchBox`**（别让用户手输 ID）；枚举给标签；空值给 `nullDisplayText` | [presentation.md](presentation.md) §4、§2 | A |
| 7 | 灵活高效（Flexibility and efficiency of use） | 默认值（`.mm` 的 `default` / 库侧 `DF_`）、批量动作、保存的查询条件（`search` 视图） | [naming.md](naming.md) §3.3、[presentation.md](presentation.md) §1 | B |
| 8 | 优美简约（Aesthetic and minimalist design） | 列表**列数与分组有上限意识**（`listed` / `groupLabel`）；隐藏字段**根本不投影**进载荷 | [api.md](api.md) §3.5、[meta-model.md](meta-model.md) | B |
| 9 | 容错（Help users recognize, diagnose, and recover from errors） | 错误消息 = **模板 + 字段级 `validationRules`**，且**服务端与呈现侧同源**（同一约束生成两处，不手写两份） | 本表 #5、[quality.md](quality.md) §1.4 | A |
| 10 | 人性化帮助（Help and documentation） | `tooltip` / `placeholder` / `///` 文档 → 帮助面板与 API 文档**同源** | [presentation.md](presentation.md) §2、[api.md](api.md) | B |

> **这张表的用法**：#1/#2/#4/#5/#6/#9 是 **A 类**（能从声明机械判定，能进 `mmda check` 信号集）；#7/#8/#10 是 **B 类**（半自动，出清单由人确认）；**没有一条是 D 类**——凡是「只能靠感觉」的，本文一律不写进这张表（审美走 §2 的 Desirability 层，归皮肤）。
> **生效强度（✔ 已裁 2026-09-24，作者取 B）**：**A 类子集进 `mmda check`，出 warning、不阻断、不进 `mmda quality gate`**（与 [naming.md](naming.md) §5 的命名检查同档）。
> **两个「等级」不是一回事，别混**：表中 A/B 列是 [quality.md](quality.md) §1.2 的**可判定性分级**（A 可自动判定 / B 可半自动）；「warning」说的是**检查强度**。落地口径：**表内 A 类那 6 条进 `mmda check` 断言集；B 类 4 条进报告清单**（半自动，出清单由人确认）。

---

## 5. 用户旅程（UCD 六阶段）→ 我们的五阶段

UCD 循环图（作者笔记配图）六节点：**Project start → User research and analysis → Concept design → Detailed design → User testing of prototypes → Develop and measure → Project launch**，中心是 **User-Centered Design**。**UCD 思想就一句话：在设计开发产品的每一个步骤中，都要把用户列入考虑范围。**

对照 [guide/quickstart.md](guide/quickstart.md) §0 的五阶段：

| UCD 六节点 | 我们的五阶段 | 说明 |
| --- | --- | --- |
| User research and analysis | **需求** | 关键用户 = `Role`（[requirements.md](requirements.md)、`.mr`） |
| Concept design + Detailed design | **设计** | 三类架构 + 交互设计（`ui/**/*.mi`） |
| (Concept/Detailed 的产物) | **原型自动生成** | 我们比 UCD 多的一步：**设计直接产出可跑原型** |
| Develop and measure | **逻辑实现**（KEEP 区）+ 运行期观测 | [runtime.md](runtime.md)、[operations.md](operations.md) |
| User testing of prototypes | **测试** | `.mt` 用例 + 中文验收单 |
| Project launch | **交付** | 离线包 + `mmda doctor` |
| **Develop and measure 的「measure」回路** | **✔ 已裁（2026-09-24 取 B）** | UCD 是**闭环**：上线度量要回流到下一轮研究。**裁决 = 回流进 `mmda check` 出 warning**——但注意回流是两半，见下表后的落地口径 |

**回流怎么落地（1B 的两半，写实）**：

| 一半 | 内容 | 落点 |
| --- | --- | --- |
| **静态可判定的一半** | 监控与诊断出口的**声明是否存在**（`/metrics` 等）、关键 `Action` 是否有元数据、端点是否声明了鉴权与只绑内网 | **`mmda check` 出 warning**（口径见 [operations.md](operations.md) §4/§8） |
| **运行期的一半** | 任务完成率、校验失败 top N、最常放弃的操作——**只能实测**（[quality.md](quality.md) 的 C 类） | **`mmda ops` 出清单 → 喂需求与设计评审**；**不许写成 `mmda check` 的静态断言**（那就是拿环境数据当构建门禁） |

**前提（本裁决的依赖）**：`mmda ops` 必须先落地——[operations.md](operations.md) §11-5（助手建议 **5A** 进 P9）。**`mmda ops` 不进首版，这条回流就只能是纸面约定。**

**MVP 金字塔（作者笔记配图）**：`Functional（功能）→ Reliable（可靠）→ Usable（可用）→ Emotional design（情感）`。
**我们的承诺面 = 下面三层**（功能、可靠、可用——全部可自动判定）；**Emotional design 归皮肤/品牌**，不进规范承诺（与 §2 的「首版不承诺好看」一致）。**Lean UX 的 MVP 语义也吃这一条**：MVP 不是「砍功能的借口」，是**金字塔下三层必须齐**——功能不全、不可靠的「MVP」不是 MVP。

---

## 6. 传统 UX / Lean UX / Agile UX：三者不是三种流程，是同一真源上的三种节奏

作者笔记里的三圆图（@andersramsay / UX London 2012）与 Lean vs Agile 对照图：

| 派别 | 核心问题 | 关键词 |
| --- | --- | --- |
| **Traditional UX** | What are we making? | Design, Usability |
| **Lean UX** | Are we making the right thing? | Measuring, validating product/market fit；MVP、Funnel Analysis、Talking with Customers、Solving problems、Learning Loop |
| **Agile UX** | How do we make it? | Collaboration, Delivery；Sprints、Owners、Kanban、Scrum、Iteration 0、Retrospectives |

**重叠区** = 「iterative approach applied to a dynamic environment」（作者笔记里标注为 buzz words 集中区）。

**MMDA 的答案（可判定）**：三者的组织方式不同，但**只要真源是平台数据库里的图形模型，三者就会互相覆盖**（Lean 要快速试错、Agile 要每迭代交付、传统 UX 要全局一致性）。我们的机制性回答是 [readme.md](readme.md) §7 那条的延长线：

- **Lean 的快速试错** → 改 `.mmda` + 重新生成（文本 diff + 可回滚），试错成本 = 一次生成；
- **Agile 的每迭代交付** → `mmda generate` 出骨架 / 接口 / DDL，业务逻辑在 KEEP 区按迭代填；
- **传统 UX 的一致性** → 契约三层 + 跨端一致性测试（[targets.md](targets.md) §5）。
- **`Product-Market Fit`（笔记原话「通过对 MVP 的不断验证和设计迭代，最终达到产品与市场的匹配」）**：我们的可测代理 = [vision.md](vision.md) §6 的业务可测指标（**只进报告不进硬门禁**）。

---

## 7. 服务设计（多触点旅程）：承认它，但不进语言

笔记原话：「如果说产品设计是解决单一触点的问题，服务设计则是要关注包含多个触点的整个服务流程」「要像做服务一样做产品，从真实的生活场景出发，分析用户接触产品的整个旅程中的痛点并发掘设计机会」。

- **现状已覆盖的可执行部分**：`Role`（谁）+ 流程建模（`*.mf`）+ 事件链（[event_bus.md](event_bus.md)）+ 五层监控（[operations.md](operations.md) §1）。
- **不做**：**不新增 `journey` / `touchpoint` 一类元模型元素**——语言层零新增是既有裁决，且「旅程」目前是**分析工具**（画给人看），不是可执行契约；要画就画在设计器插件或外部工具里（只读产物，不进真源，口径同 [ide/plugins.md](ide/plugins.md)）。
- 落点待定：见 §11-4。

**✔ 已裁（2026-09-24 作者取 4A + B）**：**不进语言与元模型**（多触点仍用 `Role` + 流程 + 事件表达），**同时在设计器插件侧留只读「旅程视图」扩展点**——落 [ide/plugins.md](ide/plugins.md) §10 的扩展点规划，**只读展示面、不进真源、不改语言层**。

---

## 8. 包容性与无障碍（Inclusivity / Accessibility）

[quality.md](quality.md) §1.4「包容性」已有 B 级信号（多语言词条完整度；主题/无障碍属性如 alt、尺寸单位声明检查）。本文补**能机械判定的三条**：

| 检查 | 判据 | 落点 |
| --- | --- | --- |
| **语义标签不缺** | 每个可编辑字段都有 `label`（i18n 词条无缺失，含非默认 locale） | [presentation.md](presentation.md) §5、[quality.md](quality.md) §1.4 |
| **键盘可达与焦点顺序** | 焦点顺序 = 视图字段顺序（`groupLabel` 分组序号 + 字段声明顺序）——**顺序本身是契约，不是皮肤自由** | [presentation.md](presentation.md) §3 |
| **错误可被读屏** | 错误消息是**文本**（有词条 key），不是纯图标/颜色语义 | 本表上行 + [quality.md](quality.md) §1.4 |
| 对比度 / 焦点可见 / 动效 | **皮肤侧**（`vui*` / `rui*` 各自负责） | 不在后端契约面 |

基线强度（是否上 WCAG 2.2 AA 的自动化子集）见 **§11-3**。

**✔ 已裁（2026-09-24 作者取 B）**：上表三条**进 `mmda check` 出 warning（不阻断、不进 `mmda quality gate`）**，基线 = **WCAG 2.2 AA 的可自动化子集**；**对比度 / 焦点可见 / 动效等视觉项不进契约、留皮肤**（换皮肤不构成契约破坏，同 [presentation.md](presentation.md) §5.1）。

---

## 9. 一手材料与版权（重要）

| 来源 | 是什么 | 是否进仓 | 处理方式 |
| --- | --- | --- | --- |
| `D:\项目\UX\学习笔记.docx` | 作者学习笔记：2,092 字 / 31 段 + **6 张内嵌图**（UX 四层环、UCD 循环、Lean/Agile 三圆、Lean vs Agile 对照、MVP 金字塔、狭义 UX 维恩） | ❌ **不进仓** | 本篇按要点转写；**图来自第三方**（下图注）且带知乎水印 |
| `UX 广义.webp` | **UX 学科交叉大图**（Interaction Design 在中心，外围 Visual/Information/Motion/Sound/Scenario Design、Information Architecture、Human Factors、HCI…，再外圈是 Architecture / Industrial Design / Ergonomics / Psychology / Cognitive Science / Sociology / Marketing / Engineering 等学科） | ❌ | 图注原文：`Copyright envii precisely (2009). Based on the Discipline of User Experience Diagram (Saffer)` —— **第三方版权**，只记出处（`kickerstudio.com/blog/2008/12/the-disciplines-of-user-experience/`） |
| `UX 狭义.webp` | **狭义 UX 维恩图**：`visual design` / `content strategy` / `information architecture` / `interaction design` / `user research & usability` / `front-end development` 六个圆，交集 = **UX**（与笔记配图 image1 同一张） | ❌ | 同上（第三方） |
| `设计心理学.pdf` | **247 页扫描件**：中信出版社 **2003.10 第 1 版**，[美] **唐纳德·A·诺曼** 著 / **梅琼** 译，ISBN **7-80073-925-2**；原书 *The Design of Everyday Things*，版权页明写 **Copyright © 2002 Donald A. Norman / ALL RIGHTS RESERVED** | ❌ **不摘录正文、不复制图** | **只在 §10 读书清单里引用概念名**；正文引用一律转述 |

**规则（写进约定，后续别再问）**：**只有作者本人绘制/拍摄的图才进 `doc/assets/`**（例：`guide/quickstart.md` 用的三张 2023 原图）；**第三方图与书籍内容一律只记出处、只转述要点**。公开仓（MIT）尤其不能夹带他人版权内容。

---

## 10. 读书清单（理论基座）

| 材料 | 定位 | 用来回答什么问题 |
| --- | --- | --- |
| 《设计心理学》Norman（中信 2003 / 原书 2002 修订版，*The Design of Everyday Things*） | 认知心理学基座：示能 / 意符 / 映射 / 反馈 / 概念模型 / **人的差错** | 为什么「声明」比「暗示」可靠；为什么错误要归因到设计（§3） |
| 尼尔森《可用性工程》 + **nngroup 十大原则**（`nngroup.com/articles/ten-usability-heuristics/`） | 启发式评估清单 | §4 那张表的来源（我们从「人评清单」改造成「可判定信号清单」） |
| ISO 9241-11（可用性定义）· ISO/IEC 25010:2023（交互能力） | 标准口径 | §1 术语；[quality.md](quality.md) §1.0–§1.4 的命名对照 |
| Agile UX / Lean UX 相关材料（@andersramsay 等） | 流程节奏 | §6 三种节奏 → 同一真源 |

> 作者笔记正文**写到「以人为本的角度去思考，就是：始终告诉我在哪里、」处中断**（半成品）。这一条如果要接着写完，建议落在 §4 的 #1（状态可见）与 #9（容错）之间——**「我在哪 / 我能做什么 / 我刚做了什么 / 下一步是什么」**四个问句正好是 #1、#7、#3、#10 的口语版。

---

## 11. 已裁（4 条，✔ 2026-09-24 作者取 `1B 2B 3B 4A+B`）

**结果**：**1B** 度量回流进 `mmda check` 出 warning（**作者未采纳助手建议的 1A**；`mmda ops` 为其前置 —— **✔ 2026-09-24 该前置已满足**：[`operations.md`](operations.md) §11-5 取 **5A**，`mmda ops` 进首版）· **2B** 十原则的 A 类子集进 `mmda check` 出 warning · **3B** 无障碍可自动化子集出 warning · **4A+B** 旅程不进语言与元模型 + 设计器插件留只读「旅程视图」扩展点。

下表**保留原选项与理由**，供复核（照例：已裁项的回改要另开一轮，别静默改写）。

| # | 议题 | 选项 | 建议与理由 |
| --- | --- | --- | --- |
| 1 | **上线后度量的回流腿**（UCD 的 measure 闭环） | A **把 `mmda ops` 的只读诊断指标（任务完成率、校验失败 top N、最常放弃的操作）做成需求与设计评审的输入清单，只进报告** ／ B 进 `mmda check` 出 warning ／ C 不做，保持单向流程 | **1A**：度量是「回来的信息」，不是门禁；与 DORA 四指标同档（只进报告不进硬门禁）。**代价**：需要 `mmda ops` 先落地（[operations.md](operations.md) §11-5） |
| 2 | **§4 十原则清单的生效强度** | A 只进 `quality-report.json` 报告项 ／ B **A 类子集进 `mmda check` 出 warning（不阻断）** ／ C 择条进 `mmda quality gate` 硬门禁 | **2B**：与 [naming.md](naming.md) §5 的命名检查同档（warning 不阻断）；**门禁应先有 A 类信号再有判定**，直接上 C 会把体验问题变成发布阻塞项 |
| 3 | **无障碍基线** | A 只声明「以 WCAG 2.2 AA 为目标」并出报告 ／ B **AA 的可自动化子集（语义标签 / 焦点顺序 / 错误文本）进 `mmda check` 出 warning** ／ C 进硬门禁 | **3B**：§8 表里那三条本来就藏在既有声明里（`label`、字段顺序、校验词条），**零额外建模成本**；对比度等视觉项留皮肤，不进契约 |
| 4 | **服务设计「旅程」的建模位置** | A 不进语言与元模型（用 `Role` + 流程 + 事件表达） ／ B **A + 在设计器插件侧留「旅程视图」口子**（只读产物、不进真源） ／ C 新增元模型元素 | **4A + B**：语言层零新增不能破；旅程图作为**设计器插件**的展示面是合规的（[ide/plugins.md](ide/plugins.md) §8–§13） |

---

## 12. 相关

- [presentation.md](presentation.md) — UI 契约（`MetaUi`、五视图、UiField）与视图钩子
- [quality.md](quality.md) — 交互能力子特性、A/B/C/D 分级、阈值基线（**强度与门禁的真源**）
- [requirements.md](requirements.md) — 关键用户 `Role` 与需求追溯链
- [guide/quickstart.md](guide/quickstart.md) §0 — 五阶段全貌（本文 §5 的对照对象）
- [naming.md](naming.md) §2/§3.4 — 契约名清单与前端本地命名
- [operations.md](operations.md) — 运行期观测与诊断出口（本文 §5 闭环所需的「回流」来源）
- [ide/plugins.md](ide/plugins.md) — 设计器插件（旅程视图等只读展示面的落点）
- [glossary.md](glossary.md) — 术语表（词的真源）
- `..\PLAN.md` — 落地计划与阶段
