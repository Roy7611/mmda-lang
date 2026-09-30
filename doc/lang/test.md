# 测试用例：Test（可执行声明 · 集合 · 分层）

> **为什么有这篇**：[`../testing.md`](../testing.md) 已裁「**用例进语言（`*.m`，住 `tests/`）+ 进库（分类 / 集合 / 状态）+ 进 IDE（SDLC 全生命周期）**」，并给了三个管理维度（分类 / 集合 / 状态，§9.1）；但**用例的语法形态一直挂着**（[`../testing.md`](../testing.md) §11 待裁第 9 条「随语法专题」）。本篇把「**测试用例怎么写进 m 语言**」定成**语言面唯一规范**：子句表 / 执行体三段 / 集合 / 编号 / 回指 / 门禁。
> **v3（2026-09-29 三轮 · 作者改语法结构）**：**正文三段改用 BDD 关键字 `given` / `when` / `then`，但仍是可执行 DSL** —— `given` 给出**上下文与输入**、`when` 记录**你干了什么**、`then` 声明**就会有……**；每行都是封闭指令（造数 / 动作 / 断言三套词表），由底座造数 / 驱动 / 判定三支座执行，**不是散文**（§3）。同步收紧三处：**`when` 不写 `step <n>`**、**`then` 不写 `expect`**（块名已声明期望，断言词与寻址面 disjoint，`emitted` 取代 `event` 作断言词）、**被测对象构造归 `given` 的 `subject`**。（**v5 修订**：`harness` 整段废除，见 §6；`subject` 只留给 `face API` + `driver HOOKS` 直调时用。）
> **v5（2026-09-30 五轮 · 作者改范围）**：**单元测试不进 m 语言**（JUnit / xUnit / vitest 已经很成熟，没必要另立一套语法；`phase UNIT` / `unit` 锚 / `harness` / `attach` / 指令→代码映射表 / `mmda test-gen` 全部取消）；m 语言的管辖范围收窄为 **feature / module 级功能验证** —— 因为**前后端分离**，功能用例分两个**面**：**`face UI`**（前端交互语法：`open` / `press` / `set` / `call view …` / `wait`）与 **`face API`**（后端接口测试：`call api …` / `hook …` / OAS 契约断言）；这些功能用例再**组合成 `suite`**（UAT / 冒烟 …，§4）。
> ① **用例集合成为一等实体 `suite`**（新 partType；成员由**集合侧的选择器**算出，用例侧不再写「我属于哪个集合」）；
> ② **每条用例必须可执行**——由**底座（CLI / API）**支撑**造数 → 驱动 → 判定**三个支座，因此正文三段（现为 `given` / `when` / `then`）必须有**严格语法**（封闭指令词表），**写不出可执行形态的用例没有意义**；
> ③ 功能测试**以 UAT 为终极目标**，`kind` 单值**改为 `kinds` 多维标签**；**冒烟是 UAT 的子集**，靠标签 + 集合选择器表达；
> ④ 用例**挂 module**（UAT → 二级 Module 集成 → Feature 功能三级分解），**intent 经「其 module」反查全部用例**——**intent 阶段没有数据模型，写不出输入与输出，可执行用例在 S1 不可能成立**（故 **v1 的 `req:` / `covers:` 必写被作废**，见 §0.3 / §8）；
> ⑤ **单元测试不进本语言**（v5 修订，取代 v3 的「对接成熟框架」）：JUnit / xUnit / vitest 已经很成熟，**没必要在 m 语言里另立一套** —— ~~`phase UNIT`~~ / ~~`unit` 锚~~ / ~~`harness`~~ / ~~`attach`~~ / ~~指令→代码映射表~~ / ~~`mmda test-gen`~~ 全部取消（§6）；m 语言只管辖 **feature / module 级功能验证** —— 因为前后端分离，功能用例分 **`face UI`**（前端交互）与 **`face API`**（后端接口）两个面（§2.2 / §3）。
> **v1 中被本篇作废的两处**：`kind`（单值）→ **`kinds`（多维标签）**；`suite`（用例上的标签）→ **`suite` 声明（集合侧选择器）**。
> **取材**：[`../testing.md`](../testing.md) §0.1 / §0.2 / §1 / §5 / §6.2 / §9 / §9.1 + [`intent.md`](intent.md) §4 / §6 + [`modules.md`](modules.md) §1 / §2 + [`../requirements.md`](../requirements.md) §2.1（模块三级 System·Module·Feature）+ 库侧实测（**仅参考、非投影目标**；`mmda_alm.testcase` 24 列 / `teststep` / `testcasedependency` / `testtype` 20 行两级树 / `bug` 18 列，本机 `127.0.0.1:3306`；**库侧无任何 Suite 表**）。
> **状态**：**草案 v5（2026-09-30 五轮立；v1 的两处作废不变）**。**除已标注 ✔ 的外，本篇子句一律为提案，待作者裁定**（§11 议题台账）。
> **联动**：[`test-store.md`](test-store.md)（落库：`MetaTest` 族——**唯一落库面**；~~与 `mmda_alm` 的投影映射~~ 已废除）· [`../examples/alm/差异对照-测试与缺陷.md`](../examples/alm/差异对照-测试与缺陷.md)（库侧实测逐条差异 + 勾选区）· [`../examples/alm/TC-000045.m`](../examples/alm/TC-000045.m) · [`../examples/alm/SUITE-UAT-CORE.m`](../examples/alm/SUITE-UAT-CORE.m)（示例）。

---

## 0. 定位：最晚的**声明类**产物

| 站 | 产物 | 谁写 | 它能否引用别的产物 |
| --- | --- | --- | --- |
| S1 | `intent`（Why / What） | 业务 + 架构师 | **不能**（[`intent.md`](intent.md) §0 推论 1） |
| S1 | `usecase`（`UC-…`，USER 意图的细化） | 设计师 | 只能引用上游（`usecase UC-… : INT-…`） |
| S2 | 模块树（System / Module / **Feature**）与建模声明点 | 架构师 + 设计师 | 向上 `satisfies UC-…` / `satisfies INT-…`；`model:` / `ui:` / `flow:` 挂模块 |
| **S3** | **`test`（`TC-…`）+ `suite`（`SUITE-…`）** | 设计师 + 业务 + AI | **必须挂 `module`**（本体的锚）；**不得引用下游**（生成物、运行指标、缺陷） |

**与 intent 的方向恰好相反，这是本篇所有规则的理由**：

- intent **不能**引用下游 —— 签发意图时下游还不存在（[`intent.md`](intent.md) §0）；
- `test` **必须**挂在上游的**模块树**上 —— 没有归属的用例**什么都不验**（[`../testing.md`](../testing.md) §0-2：标 orphan、不计覆盖率、CI 报警）。这是「用例很多但什么都没验」的唯一机械防线。

**三条不变量**（承 [`test-store.md`](test-store.md) §0，与 [`intent-store.md`](intent-store.md) 同源）：

1. **文件是真源、库是产物** —— `tests/*.m` 可整目录重建 `MetaTest` 族（**唯一落库面**；应用侧 `mmda_alm` 仅参考、将废除）；
2. **库不引入语言面没有的概念** —— 每一列都能指回一条子句；
3. **值域存符号名**（`UAT` / `PASS` / `HOOKS`…），**不存 tinyint 序号**（收口库侧 L 类不一致）。

### 0.1 一条硬门槛：**不可执行的用例没有意义**

> **作者口径（2026-09-29 二轮）**：「**每一个 test 都得是可执行的**，mmda 框架底座支撑（通过 cli / api）输入数据生成、操作步骤自动化、结果的自动判定，**不能执行的没有意义**，因此需要对输入、执行、输出三个进行 m 语言的语法严格定义。」

| 支座 | 环节 | 底座动作（CLI / API） | 语言侧对应 |
| --- | --- | --- | --- |
| **造数** | **输入** | `mmda test --gen-data TC-…`（写库 / 起 mock / 备夹具） | **`given` 块**（§3.1） |
| **驱动** | **执行** | `mmda test --run TC-… --face <UI\|API> --driver <通道>`（UI = 真前端 / 浏览器；API = 真发请求 / 三端 hooks 直调） | **`when` 块**（§3.2） |
| **判定** | **输出** | `mmda test --assert TC-…`（实际结果 vs 断言；判定源 = 声明 + 冻结基线，**AI 只出诊断**，[`../testing.md`](../testing.md) §0-3） | **`then` 块**（§3.3） |

**三条推论**：

1. **正文三段是封闭指令词表，不是散文** —— 词表外的写法 `mmda check` 出 error（§3.5）。自由文本无法生成、无法驱动、无法判定。
2. **执行态不进文件**（§0.2）—— 造出来的数据、跑出来的结果、耗时、目标端**只落库**。
3. **真的无法机械化时**，只能 `driver MANUAL` 且正文写 `manual` 步骤；这类用例**不进 `GOLD`、不计入验收覆盖率**（[`../testing.md`](../testing.md) §6.2 分层）——**这是「不能执行」的唯一出口，且要付代价**。

### 0.2 声明面 / 执行面（**执行态不进文件**）

| 面 | 内容 | 住哪 | 变不变 |
| --- | --- | --- | --- |
| **声明面** | `module` / `feature` / `phase` / `face` / `kinds` / `given` / `when` / `then` / 审签 / 集合成员规则 | **`tests/*.m`（真源）** | 只在**模型或需求变更**时变（[`../testing.md`](../testing.md) §5「变更后的重算」） |
| **执行面** | 通过 / 失败 / 阻塞 / 过期、实际结果、耗时、跑在哪个端、造数落库后的真实主键 | **只在库**（`MetaTestRun`；[`test-store.md`](test-store.md) §5） | 每次跑都变 |

> 库侧 `testcase.actualResult` / `testcase.status`（`NOT_TEST` / `PASS` / `FAILED`）正属于**执行面**——它们不该出现在静态用例表上（差异 **T15**）。声明面与执行面分开，`--impact` 的「期望值要改」才与「这次跑挂了」互不污染。

### 0.3 追溯方向：**intent → module → test**（v1 的 `req:` 作废）

> **作者口径（2026-09-29 二轮）**：「**测试主要挂 module，而 intent 意图由一个或者多个 module 实现，这样 intent 通过其 module 追溯到所有的测试用例**。**因为在 intent 阶段没有实际的数据模型，难以定义测试用例的输入和输出，可执行的 test 没法定义**。」

```text
INT-000123 ──satisfies──▶ module M.03 ──┬─▶ feature M.03.002 ─▶ 功能验证的两个面（face UI / face API）
（S1，无模块树、无数据模型）  （S2）      │
                                        └──▶ test TC-000045（test 侧只写 module / feature）
```

| 边 | 写在哪 | 语法 |
| --- | --- | --- |
| module → intent | **建模侧** | `satisfies INT-…` / `satisfies UC-…`（[`intent.md`](intent.md) §4 ✔ 已裁，不新增机制） |
| test → module | **test 侧** | `module M.03`（**必填**）· `feature M.03.002`（`phase FEATURE` 必填） |
| intent → 全部用例 | **内核索引** | `mmda trace INT-…`（intent → satisfies → module → 其下全部 `test`） |
| ~~test → intent~~ | **作废** | ~~`req: INT-…`~~ —— 意图与用例之间**不再有直接边**，避免模块重构后用例文件跟着 churn |

**由此得到的两条口径（与 v1 相反）**：

1. **`test` 不写 `req:` / `covers:`** —— 归属与覆盖都由 `module` / `feature` 锚 + 内核索引算出。**「一条用例必须可追溯」的门禁不变**（[`../testing.md`](../testing.md) §0-2），判据由「`req` 或 `covers` 非空」改为「**`module` 指向真实存在的模块树节点**」。同名子句 `req:` / `covers:` 若出现 = 装载期 error（§3.7 判据 2）。
2. **UAT 分两个时点**（⚠️ 需作者确认，§11 T-1）：**验收准则**在 S1 出（文字 + `intent` 的 `what`，进需求基线）；**可执行 UAT**在 S2 出（此时才有模块与数据模型可锚）。[`../testing.md`](../testing.md) §0.1「UAT 需求完成后立即出**且必须可执行**」按此拆解——**「立即出」的是准则，「可执行」的形态在模块树成形后落地**。

---

## 1. 语法总览

### 1.1 `test`

```sql
/// <label> : <description>
test <TC-编号> {
    <锚子句…>          // module（必填）/ feature（phase FEATURE 必填）
    <分类子句…>        // phase（必填）/ face（必填）/ kinds（必填 ≥1）
    <管理子句…>        // source / level / driver / env / importance / priority / depends / tag / reviewedBy

    given { <上下文与输入：造数指令…> }
    when  { <剧情：动作指令…> }
    then  { <结果：断言指令…> }

    alt "<备选场景名>" {      // 完整的 GWT 三连（可任选子集覆盖，未写的继承主体）
        given { … }
        when  { … }
        then  { … }
    }
}
```

### 1.2 `suite`

```sql
/// <label> : <description>
suite <SUITE-符号名> {
    select { <选择器…> }        // 成员规则（声明式：phase / face / kinds / module / feature / source / level / driver / env / tag）
    include { <TC-…> }          // 白名单（例外，可省）
    exclude { <TC-…> }          // 黑名单（例外，可省）
    subset <SUITE-符号名>       // 集合间关系（本集合 ⊆ 目标集合）
    runWhen BUILD | DAILY | MILESTONE | DELIVERY
}
```

### 1.3 文件形态

| 项 | 规则 | 依据 |
| --- | --- | --- |
| 文件 | `*.m`（唯一后缀），**首关键字判 partType**：`test` / `suite` | [`project.md`](project.md) §1.2 / §5 ✔ 已裁 |
| 住哪 | 阶段根 **`tests/`**（推荐非硬规则）；集合推荐 `tests/suites/`；目录自由、**文件名不影响语义** | [`project.md`](project.md) §1.2 / §1.3 ✔ 已裁 |
| 粒度 | **一文件可放多条 `test` / 多条 `suite`**（与 `record` / `intent` 同一条规则） | [`project.md`](project.md) §6 ✔ 已裁 |
| label | `/// <label> : <description>` —— `label` = 业务可读标题（**中文验收单由它生成**），`description` 可选 | 同 `intent` / `record`（收差异 T18） |
| 编号 | `test` → **`TC-<NNN>`**（内核签发）；`suite` → **`SUITE-<符号名>`**（人起、内核查重，§7） | §7 |
| 正文 | **一行一条指令**、句末逗号；**暂时不要多行字面量** | 同 [`intent.md`](intent.md) §2.3 ✔ 已裁 |
| 大小写 | 关键字与枚举取值**一律大写**；小写由 `mmda fmt` 归一 | 同 §2.2 |
---

## 2. test 子句参考

### 2.1 锚子句：`module` + `feature`（**归属锚 module、功能锚 feature**）

| 子句 | 取值 | 指向 | 门禁 |
| --- | --- | --- | --- |
| `module` | 模块编号 `M.03`（`moduleType = 1` 的节点） | **二级 Module** —— 用例的**主锚**（[`modules.md`](modules.md) §1 / §2） | **必填**；指向不存在的模块 = **error** |
| `feature` | `M.03.002`（`moduleType = 2` 的节点） | 模块内的 **Feature** —— 功能测试的落点 | 可选；写了则**必须是该 module 的子节点** = error |
| ~~`unit`~~ | ~~`"<Type>.<成员>"`~~（如 `"ProductionOrderService.filter"`） | ~~**函数级**被测对象（Feature 内的实现单元）~~ | **v5 取消** —— 单元测试不进 m 语言，用 JUnit / xUnit / vitest 原生写（§6） |

**层级与被测粒度**（作者口径 ④，§5 展开）：

| 层 | 挂什么锚 | `phase` | 展开的是 | 在本语言？ |
| --- | --- | --- | --- | --- |
| **UAT** | `module`（可加 `feature`） | `UAT` | 端到端业务场景（终极目标） | ✔ |
| **系统 · 端到端** | `module`（可加 `feature`） | `SYSTEM` | 跨 feature / 跨端的系统行为 | ✔ |
| **二级 Module 集成** | `module` | `INTEGRATION` | 模块边界与跨模块 / 跨端一致 | ✔ |
| **Feature 功能** | `module` + `feature` + `face` | `FEATURE` | 单个功能特征在前端 / 后端的行为 | ✔ **主场** |
| ~~**函数单元**~~ | ~~`module` + `feature` + `unit`~~ | ~~`UNIT`~~ | ~~Feature 内某个函数 / 方法的输入输出~~ | ✘ 用 JUnit / xUnit / vitest 原生（§6） |

> **锚在 module、验在 feature、面靠 face**：intent 的归属由 `satisfies` 算出（`USER → Module / Feature`，[`../requirements.md`](../requirements.md) §2.1），**Module 是 intent 与实现之间的稳定交汇点**，Feature 太细（会随重构移动）——所以**归属锚只到 module**（`module` 必填）。但**功能验证的对象是 feature**：故 `phase FEATURE` 的用例**必须**写 `feature`，并**必须**声明 `face`（`UI` / `API`）说清验的是前端交互还是后端接口。**锚求稳定、验求精确，两者分开**——与「会变的东西不进主键」（[`intent.md`](intent.md) §5）同一条道理。

### 2.2 分类子句：`phase` × `face` × `kinds`（**face 分前后端、kinds 是多维标签**）

| 子句 | 取值 | 回答什么 | 门禁 |
| --- | --- | --- | --- |
| `phase` | `FEATURE` / `INTEGRATION` / `SYSTEM` / `UAT` | **在哪一层做**（粒度，四档封闭；**v5 取消 `UNIT`**，见 §6） | 必填；枚举封闭 = error |
| `face` | `UI` / `API` | **验哪个面**（`UI` = 前端交互 / `API` = 后端接口；**前后端分离在语言里的落点**） | 必填；枚举封闭 = error；**与 `driver` 必须配对**（下表）= error |
| `kinds` | **标签集合**，`{ … }` 里一行一个（或逗号分隔） | **用什么方法 / 属于哪一类非功能 / 一致性**（**v5 删「通道」维度**） | 必填 **≥1**；枚举封闭 = error；**目标维度恰好 1 个** = error |

**`face` × `driver` 配对**（矩阵外的组合 = error；`driver` 值域见 §2.3，`when` 动作见 §3.2）：

| `face` | 允许的 `driver` | 语汇（§3.2） |
| --- | --- | --- |
| `UI` | `E2E`（真前端 / 浏览器自动跑） / `MANUAL`（人工点） | `open` / `press` / `set view …` / `call view …` / `wait` |
| `API` | `HTTP`（真发请求，验契约与端到端行为） / `HOOKS`（三端拦截点直调，快而细） / `MANUAL` | `call api …` / `set …` / `hook …` / `wait` |

**`kinds` 的封闭词表（按维度分组，2026-09-29 二轮改版）**：

| 维度 | 标签 | 基数规则 |
| --- | --- | --- |
| **目标** | `FUNCTIONAL` / `NON_FUNCTIONAL` | **恰好 1 个** |
| **方法** | `WHITE_BOX` / `GRAY_BOX` / `BLACK_BOX` | ≤ 1 个 |
| **强度** | `SMOKE` / `REGRESSION` | 0..n |
| **非功能** | `PERF` / `LOAD` / `STRESS` / `SOAK` / `SCALABILITY` / `SECURITY` / `PENETRATION` / `USABILITY` / `COMPATIBILITY` | 0..n（且仅当目标为 `NON_FUNCTIONAL`） |
| **一致性** | `CONFORMANCE` | 0..n |

**四条规则**：

1. **`phase` / `face` / `kinds` 三者不互相蕴含** —— `phase` 是**层次**（在哪做）、`face` 是**面**（验前端还是后端）、`kinds` 是**性质**（用什么方法、是否非功能）；同一条 `phase UAT · face UI` 的用例可以同时是 `{ FUNCTIONAL, BLACK_BOX, SMOKE }`。**v5 删掉了 `kinds` 的「通道」维度**（~~`UI`~~ / ~~`API`~~ / ~~`E2E`~~ / ~~`HOOKS`~~）——通道已由 `face` + `driver` 表达，标签再写一份就是双份真源。
2. **`SMOKE` 只是标签，不是独立一类** —— **冒烟 = UAT 的子集**（`SUITE-SMOKE ⊆ SUITE-UAT-CORE`，§4.2），由集合侧的选择器 `kinds { SMOKE }` 选出（✔ 已裁 [`../testing.md`](../testing.md) §9.1 可机检 2）。
3. **`CONFORMANCE` 承载「声明与生成物的一致」**：capability 三端一致（[`../targets.md`](../targets.md) §5）、OAS 契约双向对账（[`../api.md`](../api.md) §3.1）、方言 / 保护声明一致（[`../protection.md`](../protection.md)）——它既不是功能也不是性能，必须有自己的标签。
4. **封闭枚举 + 可扩展类型**：`kinds` 是**内核封闭词表**（保证门禁可判定）；应用要自加类型（如「工装测试」）走**应用侧 `TestType` 记录**（库侧 `testtype` 树，[`test-store.md`](test-store.md) §8），**不改语言词表**——与「枚举即真源、字典表是应用数据」一致（收库侧 L7）。

> **对 v1 的改动**：v1 的 `kind`（单值）里 `uat` / `integration` / `functional` 混在一个平铺枚举里；现在 **`uat` / `integration` 归 `phase`**（库侧 `testPhase` 与 `testtype` 树第二层重复表达同一件事，差异 **T16**），**`functional` 归 `kinds` 的目标维度**。库侧 `testcase.testTypeID`（单外键）因此**要改成一对多**（§4.3 / 差异 **T20**）。

### 2.3 管理子句

| 子句 | 取值 | 语义 | 门禁 |
| --- | --- | --- | --- |
| `source` | `MECHANICAL` / `SNAPSHOT` / `AI` / `MANUAL` | **谁生成的**（决定审签强度，✔ 已裁 [`../testing.md`](../testing.md) §1） | 必填 |
| `level` | `GOLD` / `NORMAL` / `DRAFT` | **三条分层**（✔ 已裁 [`../testing.md`](../testing.md) §6.2）：只有 `GOLD` 算交付硬门禁 | 可选，默认 `DRAFT`（AI 生成）/ `NORMAL`（机械 / 手写） |
| `driver` | `E2E` / `HTTP` / `HOOKS` / `MANUAL` | **怎么跑**（决定 `when` 允许的指令，§3.2；**必须与 `face` 配对**，§2.2） | 必填；枚举封闭 = error；`MANUAL` 不得为 `GOLD` = error |
| `env` | `DEV` / `TEST` / `PROD` | 跑在哪个环境（性能阈值按环境分档，✔ 已裁 [`../testing.md`](../testing.md) §11-6） | 可选；收库侧同名列 |
| `importance` / `priority` | 同 [`intent.md`](intent.md) §2.2（`UNKNOWN` / `IMPORTANT` / `VERY_IMPORTANT`；`NORMAL` / `SENIOR` / `URGENT`） | 两维优先级（**单维表达不了「重要但不急」**） | 可选；**与 intent 同名同值域** |
| `depends` | `TC-…` 列表 | 前置用例（库 `testcasedependency`） | 环检测 = error |
| `tag` | 字符串列表 | 自由标签（库 `tags` 逗号串，同差异 D12）；**`kinds` 装语义分类，`tag` 装人的检索引子，两者不混** | 可选 |
| `reviewedBy` | `{ business: "张三", designer: "李四" }` | **双签留痕** | `source AI` **必填**；`phase UAT` **必填**（✔ 已裁） |

- **`source` 与 `driver` 必须分开**：`source` 答「谁写的」，`driver` 答「怎么跑」。UAT 的默认通道是 **API 面 hooks 驱动 + 少量 UI 面 e2e**（✔ 已裁 [`../testing.md`](../testing.md) §11-14），这与 `source AI` 完全可以共存；**库侧 `manual` bit 位（人工测试）归 `driver = MANUAL`**（收差异 **T19** / **T4**）。
- **`reviewedBy` 的双签口径**（✔ 已裁 [`../testing.md`](../testing.md) §11-3）：**业务（业务对不对）+ 设计师（能不能测）**；单人模式 self-approve + AI 对抗复核。
---

## 3. 执行体三段：`given` / `when` / `then`（**可执行 DSL**）

> **这是本篇 v3 的核心**：三段**不是散文**，是**三套封闭指令**——关键字取 BDD 的 `given` / `when` / `then` 心智模型，但每一行都必须**可解析、可造数、可驱动、可判定**：
>
> | 段 | 一句话 | 装什么 | 谁执行 |
> | --- | --- | --- | --- |
> | **`given`** | **给出上下文与输入**（谁在场、有什么数据、外部依赖怎么答） | 造数指令 | 底座 `mmda test --gen-data` |
> | **`when`** | **当你干了什么**（动作序列） | 动作指令 | 底座 `mmda test --run --face <UI\|API> --driver <通道>` |
> | **`then`** | **就会有……**（结果、副作用、拒绝、阈值） | 断言指令 | 底座 `mmda test --assert` |
>
> **词表由内核维护**，词表外的写法 `mmda check` 出 error。三段写的都是**期望的形态**；**造出来的真实数据、跑出来的实际结果只落库**（§0.2）。
> **行序即顺序**：三段的行号就是执行 / 断言顺序（`teststep.testStepID` = `when` 的行序），**不写 `step 1` 这种序号**。
> **行尾说明（可省）**：任意指令行可带尾随 `/// <中文说明>` —— 只进中文验收单，**不参与执行**（[`../testing.md`](../testing.md) §5-②）。

### 3.1 `given` —— 给出上下文与输入（造数）

| 指令 | 形态 | 语义 | 由谁执行 |
| --- | --- | --- | --- |
| `user` | `user <别名> : role <ROLE> [, loggedIn]` | 会话主体（以谁的身份跑） | 三端会话注入 |
| `data` | `data <别名> : record <Record> { <字段> : <值> [\| count <n>], … }` | **造数**（显式字段；`count` = 造 n 条同形记录） | `--gen-data`：写库 / 起 mock |
| `ref` | `ref <别名> : record <Record> where <表达式> [take <n>]` | **引用既有数据**（不造新数据，按条件选取） | 查询解析 |
| `mock` | `mock <别名> : <协议> <目标> respond <值> [code <码>] [delay <ms>]` | 外部依赖桩（第三方 / 未实现端） | mock server（[`../api.md`](../api.md) §8-6 / §8-16） |
| `file` | `file <别名> : "<路径>" [as <媒体类型>]` | 附件 / 媒体夹具 | 资产装载 |
| `subject` | `subject <别名> : <Type>(<实参>)` | **被测对象**（`face API` + `driver HOOKS` 时直接构造三端对象直调；`<Type>` 由 `module` / `feature` 的建模声明解析）。声明后，`when` / `then` 里可直接写 `<别名>.<成员>` | `--run`：驱动层构造 |
| `seed` | `seed <整数>` | **随机种子**（保证可重放，[`../testing.md`](../testing.md) §6.2-3） | 造数器 |

**取值形态（封闭）**：字面量（`3` / `"RELEASED"` / `true` / `null`）、列表 `[ … ]`、区间 `1..10`、生成器 `gen(<生成器>)`（清单由内核给，如 `gen(seq)` / `gen(uuid)` / `gen(word 8)`）。

```sql
    given {
        user  planner : role PLANNER, loggedIn
        data  orders  : record ProductionOrder {
            status : RELEASED | count 3
            status : CREATED  | count 2
        }
        mock  tax   : http POST https://tax.example/api/calc respond { rate: 0.13 } code 200
        seed  20260929
    }
```

### 3.2 `when` —— 当你干了什么（动作序列）

| 动作 | 形态 | 语义 | 允许的 `driver`（按 `face`） |
| --- | --- | --- | --- |
| `open` | `open <面> <符号>` | 打开界面 / 进入场景（`face UI`） | `UI`：`E2E` / `MANUAL` |
| `set` | `set <地址> = <表达式>` | 赋值（界面字段 / 筛选条件 / 请求参数） | `UI`：`E2E` / `MANUAL`；`API`：`HTTP` / `HOOKS` / `MANUAL` |
| `call` | `call <地址>[(<实参>)] [as <别名>]` | **调用**（`api` 端点 / `<Action>` 模块动作 / `view` 界面动作）；**`as <别名>` 绑定返回值**（供 `then` 断言——要引用返回值就必须写） | `UI`：`E2E` / `MANUAL`；`API`：`HTTP` / `HOOKS` / `MANUAL` |
| `press` | `press <地址>` | 点击 / 提交（界面动作，`face UI`） | `UI`：`E2E` / `MANUAL` |
| `wait` | `wait <时长>` ／ `wait <地址> <算子> <值>` | 等待 / 同步点 | 全部 `driver` |
| `hook` | `hook <拦截点> <地址>` | **三端拦截点**（`beforeView` / `beforeXxx` / `afterXxx`，封闭枚举见 [`../runtime.md`](../runtime.md) §4.2；`face API` 专用） | `API`：`HOOKS` |
| `manual` | `manual "<操作说明>"` | 人工步骤（**唯一不可机械化的出口**） | `MANUAL` |

**`face` × `driver` × 动作矩阵**（矩阵外的组合 = error）：

| 动作 | `UI`+`E2E` | `UI`+`MANUAL` | `API`+`HTTP` | `API`+`HOOKS` | `API`+`MANUAL` |
| --- | --- | --- | --- | --- | --- |
| `open` / `press` | ✓ | ✓ | — | — | — |
| `set view …` | ✓ | ✓ | — | — | — |
| `call view …` | ✓ | ✓ | — | — | — |
| `call api …` / `call <Action>` | — | — | ✓ | ✓ | ✓ |
| `hook …` | — | — | — | ✓ | — |
| `wait` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `manual` | — | ✓ | — | — | ✓ |

```sql
    when {
        hook  beforeView ProductionOrderList   /// 计划员打开生产订单列表
        set   view ProductionOrderList.filter.status = RELEASED  /// 选择状态 = RELEASED
        call  view ProductionOrderList.search  /// 提交筛选
        wait  view ProductionOrderList.rows == 3
    }
```

### 3.3 `then` —— 就会有……（断言）

**块名已经声明了「期望」，所以 `then` 行里不写 `expect`**：一行以**断言词**开头就是那条断言；否则整行是一个**值断言** `<地址> <算子> <值>`。

| 断言词 | 形态 | 例 | 适用 `kinds` |
| --- | --- | --- | --- |
| （无词）**值断言** | `<地址> <算子> <值>` | `record ProductionOrder.status == RELEASED` | 全部 |
| `every` | `every <地址> <算子> <值>` | `every view List.rows.status == RELEASED` | 全部 |
| `size` | `size <地址> <算子> <n>` | `size view List.rows == 3` | 全部 |
| `exists` | `exists <地址> where <表达式>` | `exists record Order where code == "SO-1"` | 全部 |
| `throws` | `throws <地址> == <错误码>` | `throws call ProductionOrder.release == M0401` | `FUNCTIONAL` |
| `changed` / `unchanged` | `unchanged <地址>` | `unchanged record Order.status` | 全部 |
| `emitted` | `emitted <事件> [count <n>]` | `emitted ProductionOrder.released count 1` | 全部 |
| `denied` | `denied <地址> for role <ROLE>` | `denied call ProductionOrder.release for role VIEWER` | `SECURITY` |
| `oas` | `oas <端点> matches <契约>` | `oas GET /api/mes/Orders matches OAS` | `CONFORMANCE` |
| `capability` | `capability <目标端> consistent` | `capability TS consistent` | `CONFORMANCE` |
| `within` | `within <地址> <统计量> <算子> <数值>` | `within api POST /api/mes/Orders p95 <= 500ms` | `NON_FUNCTIONAL` |

**算子 `op`（封闭）**：`==` / `!=` / `>` / `>=` / `<` / `<=` / `~=`（正则） / `contains` / `startsWith` / `in`。

```sql
    then {
        every view ProductionOrderList.rows.status == RELEASED
        size  view ProductionOrderList.rows == 3
        view ProductionOrderList.total == 3
    }
```

> **为什么断言词与寻址面不重叠**：「事件」在 `then` 里改用 **`emitted`**（而不是 `event`）——`event` 是寻址面（`event ProductionOrder.released`），若同时当断言词就有歧义。**词表 disjoint 是可解析的前提**（v3 相对 v2 的一处收紧）。

**反例纪律（✔ 已裁）**：**弱断言 = warning** —— `then` 行没有具体值、错误码或状态（[`../testing.md`](../testing.md) §6.2-2）；权限与非法迁移的用例**必须**有 `denied` / `throws`（[`../testing.md`](../testing.md) §6「含拒绝路径」）。

### 3.4 `alt` —— 备选 / 拒绝路径（**完整的 GWT 三连**）

`alt "<场景名>"` 里是**同一套 `given` / `when` / `then`**，**可任选子集**（未写的段继承主体）；`alt` 的行同样必须可执行。

```sql
    alt "无命中" {
        given {
            data orders : record ProductionOrder { status : CREATED | count 2 }
        }
        when {
            call view ProductionOrderList.search
        }
        then {
            size      view ProductionOrderList.rows == 0
            unchanged view ProductionOrderList.filter.status
        }
    }
```

### 3.5 寻址语法 `addr`（三段共用）

```text
<面> <符号名>[.<成员>][.<子成员>]     // ① 声明面寻址 —— 见下表
<别名>[.<成员>]                       // ② 别名寻址 —— given 的 data / ref / mock / file / subject，或 when 的 `call … as <别名>`
面 ∈ view | api | record | event | role
```

| 面 | 形态 | 例 |
| --- | --- | --- |
| `view` | `view <View>[.<成员>]` | `view ProductionOrderList.filter.status` |
| `api` | `api <方法> <路径>` | `api POST /api/mes/ProductionOrders` |
| `record` | `record <Record>.<字段>` | `record ProductionOrder.status` |
| `event` | `event <事件名>` | `event ProductionOrder.released` |
| `role` | `role <ROLE>` | `role VIEWER` |

**别名规则**：别名**就地声明**（`given` 的造数 / 夹具，或 `when` 的 `call … as`），段内唯一、**不跨用例**（`alt` 继承主体已声明的别名）；**未声明的别名 = error**（同未解析的 `addr`）。

**解析规则**：`view` / `record` / `event` / `role` 由 S2 声明解析；`api` 由 API 契约解析。**三段里出现无法解析的 `addr` = error**（否则「可执行」是空话）。

### 3.6 不写什么（机械判据）

| # | 判据 | 等级 |
| --- | --- | --- |
| 1 | **不写执行态**：`actualResult` / `pass` / `fail` / 耗时 / 跑在哪个端 | error |
| 2 | **不写归属反指**：`req:` / `covers:` / `moduleCode`（归属由 `module` / `feature` 正向锚定，§0.3） | error |
| 3 | **不写审计**：`revision` / 创建人 / 修改人 / 部门（git 承载；旧库 7 件套**仅历史参考**，差异 D13） | error |
| 4 | **不写缺陷指针**：缺陷是运行期产物，链在库侧（§9） | error |
| 5 | **不写自由文本段落**：三段里出现词表外的动词 / 断言词 | error |
| 6 | **不写序号**：`when` 里写 `step 1`（行序即顺序，§3 前言） | error |
| 7 | **不写运行期依赖**：真实时间、随机数、上一条用例的副作用（`seed` 除外） | warning |
| 8 | **不写第二步的实现细节**：三段里出现代码片段 / SQL / 脚本正文（那是实现仓的事，§6） | error |
## 4. `suite`：用例集合成为一等实体

> **作者口径（2026-09-29 二轮）**：「**test case 集合成为 test suite**」「功能测试**以 UAT 为终极目标**，一般**建立一个 test suite**，**冒烟测试是 UAT 子集**。」

**集合是真源里的一等声明**（partType `suite`），不是用例上的标签；**成员只由集合侧算出**：

| 机制 | 形态 | 说明 |
| --- | --- | --- |
| **选择器** | `select { phase UAT }` / `select { face API }` / `select { kinds { FUNCTIONAL, SMOKE } }` / `select { module M.03 }` | **成员规则**（声明式）：字段与用例子句同名同值域（`phase` / `face` / `kinds` / `module` / `feature` / `source` / `level` / `driver` / `env` / `tag`），多个条件 = **与**（AND） |
| **白名单** | `include { TC-000045 }` | 例外加进来（选择器算不到的） |
| **黑名单** | `exclude { TC-000052 }` | 例外踢出去（选择器算进来但不该在的） |
| **集合关系** | `subset <SUITE-…>` | 本集合 ⊆ 目标集合（**成员包含关系**，不是标签包含） |
| **跑频** | `runWhen BUILD` / `DAILY` / `MILESTONE` / `DELIVERY` | 「什么时候跑它」（[`../testing.md`](../testing.md) §0.2） |

**为什么成员规则放在集合侧（而不是用例侧写 `suite: "…"`）**：

1. **集合间关系需要实体** —— `SUITE-SMOKE ⊆ SUITE-UAT-CORE` 这类**包含关系**只有把集合当实体才可判定（纯逗号串只能人肉检索，收库侧 `tags` 同款问题）；
2. **成员随模型自动重算** —— 新加一条 `phase UAT` 的用例，`select { phase UAT }` 的集合**自动收编**，不用回头改集合文件（`tags` 式的双份真源必然漂移）；
3. **一个真源** —— 用例侧不再写 `suite` 子句（写了 = error，§3.6 判据 2 同款），避免「集合说在、用例说不在」。

### 4.1 UAT 是终极集合，冒烟是它的子集

```sql
/// UAT 验收集 : 项目交付验收的唯一依据
suite SUITE-UAT-CORE {
    select  { phase UAT }
    runWhen DELIVERY
}

/// 冒烟 : UAT 的最小可交付子集（主干路径，建议 ≤ 20 条）
suite SUITE-SMOKE {
    select  { kinds { SMOKE } }
    subset  SUITE-UAT-CORE        // 门禁：冒烟必须 ⊆ UAT
    runWhen BUILD
}

/// 回归 : 全部 GOLD 用例（含非 UAT 分层）
suite SUITE-REGRESSION {
    select  { level GOLD }
    runWhen DAILY
}
```

| 集合 | 成员来源 | 门禁 |
| --- | --- | --- |
| `SUITE-UAT-CORE` | 全部 `phase UAT` 用例 | **`phase UAT` 的用例必须至少落在一个 `runWhen DELIVERY` 的集合** = error（验收依据不许漏网） |
| `SUITE-SMOKE` | `kinds { SMOKE }` | **`subset SUITE-UAT-CORE`** = error（✔ 已裁 [`../testing.md`](../testing.md) §9.1 可机检 2） |
| 其他（回归 / 每日 / 里程碑 / 单模块） | 自由组合选择器 | **不留孤儿**：空集合、或只含 `deprecated` 用例 = warning（✔ 已裁 §9.1 可机检 3） |

### 4.2 与旧库侧的对照（**仅参考**）

**旧库侧没有任何 Suite 表**（实测 `mmda_alm` 21 张表，无 `testsuite*`；**仅参考**——该库将废除）⇒ 集合需要**新增元对象**：`MetaTestSuite`（集合声明）+ `MetaTestSuiteMember`（**由 `mmda build` 按选择器算出的物化成员**）。落法见 [`test-store.md`](test-store.md) §4；差异 **T10** 由 v1 的「用例上留标签」改为 v2 的「**集合建表 + 声明式选择器**」。

---

## 5. 分层分解：UAT → System → Module → Feature（**函数层不在此**）

> **作者口径（2026-09-29 二轮）**：「围绕 UAT 目标，**逐层级分解**二级 module 的集成测试、单个 feature 的功能测试、以及 feature 中单元测试**对函数级的验证**。」（**v5 修订**：函数级那一层**退出本语言**，改用 JUnit / xUnit / vitest 原生写，见 §6。）

```text
        phase UAT          module M.03 ────────────────▶ UAT 用例（终极目标，挂 module 即可）
             ▲
             │ 分解
        phase SYSTEM       module M.03（+ feature）──────▶ 系统 / 端到端（跨 feature / 跨端一致）
             ▲
             │ 分解
        phase INTEGRATION  module M.03 ────────────────▶ 二级 Module 集成（跨模块 / 跨端一致）
             ▲
             │ 分解
        phase FEATURE      module M.03 + feature M.03.002 ▶ Feature 功能（本语言主场：face UI / face API）
        ─────────────────────────────────────────────────
        函数单元              JUnit / xUnit / vitest 原生   ▶ 不进本语言（§6）
```

| 层 | 必写锚 | `face` | 典型 `kinds` | 典型 `driver` | 覆盖门禁 |
| --- | --- | --- | --- | --- | --- |
| **UAT** | `module` | `UI` / `API` | `{ FUNCTIONAL, BLACK_BOX, SMOKE }` | `E2E` / `HOOKS` / `MANUAL` | 每条 USER intent 的归属 module 下 ≥1 条 UAT 用例 = error（[`intent.md`](intent.md) §7-6 的 v2 形态） |
| **系统 / 端到端** | `module` | `UI` / `API` | `{ FUNCTIONAL, BLACK_BOX }` | `E2E` / `HTTP` | 跨 feature 的关键路径 ≥1 条 = warning |
| **集成** | `module` | `API`（多数） | `{ FUNCTIONAL\|NON_FUNCTIONAL, GRAY_BOX }` | `HTTP` / `HOOKS` | 每个 `moduleType=1` 的模块 ≥1 条 = warning |
| **功能** | `module` + `feature` | `UI` / `API` | `{ FUNCTIONAL, WHITE_BOX\|GRAY_BOX\|BLACK_BOX }` | `E2E` / `HTTP` / `HOOKS` | 每个 `moduleType=2` 的 Feature ≥1 条 = warning |
| ~~**单元**~~ | ~~`module` + `feature` + `unit`~~ | — | ~~`{ FUNCTIONAL, WHITE_BOX }`~~ | — | **不在本语言**：用 JUnit / xUnit / vitest 原生（§6） |

**三条纪律**：

1. **向上不全量重复** —— feature 用例**不需要**再抄一遍 UAT 场景；`mmda trace INT-…` 会沿 `intent → module → 下辖全部用例` 一次带出（这正是「挂 module」的收益）。
2. **锚点粒度决定测试粒度** —— `phase FEATURE` 必须写 `feature`（§2.1），且 `feature` 必须是该 `module` 的子节点；**任何用例都必须声明 `face`**。**锚写错 = 覆盖算错**。
3. **分解到哪一层由风险决定** —— 不是「每层都要有」；但**每条 USER intent 必须有 UAT**（✔ 已裁），其余层按 `mmda check` 的覆盖报告裁量（warning）。

---

## 6. 单元测试不进 m 语言 —— 用成熟框架原生写

> **作者口径（2026-09-30 五轮）**：「单元测试使用 junit, xunit, vitest 等已经很成熟，**没必要在 m 语言中另外定义一套语法**。我们**着重在 feature module 上的功能验证**。」本节由 v3 的「对接成熟框架 + `harness` 子句 + 指令 → 代码映射表 + `attach` 寄生」**整段替换**。

**边界（一句话）**：**m 语言只管 feature / module 级功能验证**（`phase FEATURE` / `INTEGRATION` / `SYSTEM` / `UAT`，`face UI` / `face API`）；**函数级单元测试留在实现仓，用 JUnit / xUnit / vitest 原生写**——m 语言不生成、不解析、不登记。

| v3 的什么 | v5 的处置 | 为什么 |
| --- | --- | --- |
| `phase UNIT` | **取消**（`phase` 四档：`FEATURE` / `INTEGRATION` / `SYSTEM` / `UAT`） | 单元测试不在管辖范围，就不该有对应的阶段档 |
| `unit "<Type>.<成员>"` 锚 | **取消**（§2.1 划掉） | 函数名会随实现改名，语言侧无法可靠解析 |
| `harness { framework / language / at / import / setup }` | **取消** | 「用哪个框架跑单测」是实现仓的构建配置，不是声明面的事 |
| `attach "<路径>"` 寄生模式 | **取消** | 半进半不进的双份真源（见下「回写」） |
| §6.2 指令 → 代码生成映射表（vitest / JUnit / NUnit） | **取消** | 成熟框架语法已稳定，再维护一张 1:1 映射表是纯负担 |
| `mmda test-gen --to <框架>` | **取消** | 同上；机械生成的入口收窄为「按 `module` / `feature` 批量起 `test` 骨架」（`source MECHANICAL`，§7） |
| `mmda test-import --from <框架> <文件>` | **保留为可选入口**（⏳ 见 §11 T-17） | 从既有单测反向捞「哪些 feature 已被验过」仍有用；产出的是**待审的 `test` 骨架**，不是单测代码 |

**三条后果**：

1. **`.m` 里不出现代码形态** —— 旧 `harness.import` / `harness.setup`（v3 里唯一允许出现「目标语言原样片段」的地方）随本节一起废除；三段里出现代码片段 / SQL / 脚本正文一律 error（§3.6 判据 8）。
2. **`generated/` 不再由 `test` 声明驱动** —— 测试代码不由 `mmda generate` 产出；`generated/` 里只有模型 / 界面 / API 的生成物（[`../project.md`](project.md) §6）。
3. **覆盖率口径跟着变** —— v3 的「按函数计覆盖率」作废；m 语言的覆盖率只算 **feature / module 层**（[`../testing.md`](../testing.md) §6），函数级覆盖率归实现仓自己的单测报告。

**那「已手写的单测」怎么与追溯挂钩**：**回写** —— 补一条 `test`，锚 `module` + `feature`、声明 `face`，正文三段写成可执行形式（首选）；**没有「只登记不写正文」这条路**（v3 的 `attach` 已废除）。回写后的用例按 `source MECHANICAL` / `MANUAL` 计，**写得不出可执行形态的按 `level DRAFT` 计、不进 `GOLD`**（§0.1 推论 3）。

> **指针**：[`../testing.md`](../testing.md) §11-18（原「`given` / `when` / `then` 三段封闭词表 + harness 对接框架清单」）按本节修订为「三段封闭词表 + **单元测试用原生框架**」；[`test-store.md`](test-store.md) §2 的 `MetaTest` 列同步**删掉 `harness` 相关四列**。
---

## 7. 编号

| 项 | `test` | `suite` |
| --- | --- | --- |
| 形态 | **`TC-<NNN>`** —— **纯序号，不含阶段 / 类型 / 模块 / 层级段** | **`SUITE-<符号名>`**（ASCII 大写 + 短横线，如 `SUITE-UAT-CORE`） |
| 签发 | **内核生成，人不手写、AI 不编**；单调、不复用、不重排 | **人起，内核查重**（集合数量少、要在命令行与门禁里直呼：`mmda test --suite SUITE-SMOKE`） |
| 不进编号 | `phase` / `face` / `kinds` / `module` / `feature` / `source` | `runWhen` / 成员（成员是算出来的） |
| 库侧 | 收口 `testCaseNo varchar(30)` **无唯一索引**（差异 **L13**） | **库侧无对应表** ⇒ 新增 `MetaTestSuite`（差异 **T10**） |

> **与 `INT-…` / `UC-…` 同源**（[`intent.md`](intent.md) §5）：`TC-…` 是**内核签发的稳定锚**，追溯链（§8）与执行历史（`MetaTestRun` 跨基线回溯）都靠它连接。机械生成的用例同样入序号池（`source MECHANICAL` 的编号由批量入口申请）。

---

## 8. 追溯链与三个消费方

```text
INT-000100 ─▶ INT-000123 ─▶ UC-000045 ─▶ 建模声明点（record / field / action / stm / view / api）
   （S1：无模块树、无数据模型 ⇒ 写不出可执行用例）        ▲
                                                        │ satisfies
                                                        │
                              module M.03 ◀── module: ── test TC-000045（S2/S3）
                                 │                          │
                    feature M.03.002（face UI / API）        └─▶ 执行 ─▶ 缺陷 ─▶ 回归用例（库侧回指，§9）
```

| 边 | 写在哪 | 语法 |
| --- | --- | --- |
| intent → 建模 | **建模侧** | `satisfies UC-…` / `satisfies INT-…` |
| **test → module** | **test 侧** | `module M.03`（必填）· `feature M.03.002`（`phase FEATURE` 必填）· `face UI\|API` |
| intent → 全部用例 | **内核索引** | `mmda trace INT-…`（→ satisfies → module → 下辖全部用例） |
| test → 集合 | **集合侧** | `suite` 的 `select` / `include` / `exclude`（§4） |
| test → 执行 → 缺陷 | **库侧**，不写声明 | `MetaTestRun` / `MetaDefect`（§9） |

**三个消费方**（同 [`intent.md`](intent.md) §4）：

1. **`mmda diff --impact`** —— 改声明点 ⇒ 命中模块 ⇒ 命中该模块全部用例 ⇒ 命中意图 ⇒ 变更级别 L0–L3；改模块边界 ⇒ 同样命中（**这正是锚在 module 的收益**）；
2. **覆盖门禁** —— 分层覆盖（`phase` 四档）+ 集合包含关系（§10）；
3. **AI 取上下文** —— `spec` + 命中的 `given` / `when` / `then` + `Profile`（AI 只出诊断与候选，判定仍由声明与基线给，[`../testing.md`](../testing.md) §0-3）。

---

## 9. 缺陷（Defect）：进不进语言？ ⏳ **总闸 B0**

旧库侧 `mmda_alm.bug` 有 **18 列**（**仅参考**——该库将废除）：`bugTitle` / `bugDetails` / `urgency` / `severity` / `status`（7 态）/ `moduleCode` / `moduleVersion` / `tags` / 审计 7 件套 / **`testCaseID` / `testStepID`**（源用例 / 步骤，**无外键**）。标准侧目前**只在追溯链上有一个节点名**（[`../quality.md`](../quality.md) §5、[`../testing.md`](../testing.md) §6.1「缺陷回溯覆盖」），**没有任何语言要素**。

| 选项 | 形态 | 代价 |
| --- | --- | --- |
| **A** | **`defect` 进语言**（新 partType + `BUG-<NNN>` 编号 + `MetaDefect` 元对象） | 缺陷是**运行期产物**（谁发现、何时、哪个环境），量大且随每次回归增长；进语言 = 让「声明面」装「运行面」 |
| **B**（助手建议） | **普通 `record Defect` + `stm DefectStatus`**（S2 建模，住 ALM 应用模型；语言层只提供**编号引用**语法：`testCaseNo : TC-…`） | 缺陷不再是内核一等要素；但追溯链仍闭合（缺陷 → 用例 → module → 需求） |
| **C** | 照现状：纯库侧业务表，标准不表态 | 「需求 → 缺陷」在库侧断链（差异 **B4** / L10）维持现状 |

**建议 B 的三条理由**：

1. 缺陷有**真实的业务生命周期**（`NEW` → `OPEN` → `FIXED` → `REOPEN` → `CLOSED`；旁支 `REJECTED` / `ABANDON`）⇒ 按 D5 口径「**状态归 `stm`**」，它天然是一个 `record` + `stm`，而不是新关键字；
2. **先例一致**：「组织架构 / 岗位 / 职员是**数据**」（[`meta-model.md`](meta-model.md) §8.1）、BI 元数据「属元模型范畴但形态容后」（errata §五-11）——**应用业务对象进 `record`，不进语言**；
3. **追溯靠引用而不是靠新元素**：`Defect.testCaseNo : TC-…` 指向语言要素编号，**需求侧不必再写 `req`**——缺陷 → 用例 → `module` → `satisfies` → 需求，链已闭合（v1 曾建议 `Defect.req : INT-…`，**v2 不再需要**，§0.3）。

> **无论 A / B，两件库侧的事都要修**：`bug.testCaseID` / `testStepID` **补外键**（差异 **L17**）；`bug` **补需求可达性**（差异 **B4**，同 L10）——否则「需求 → 用例 → 缺陷 → 回归」这条链在库侧永远是断的。

---

## 10. 门禁汇总

| # | 检查 | 等级 | 依据 |
| --- | --- | --- | --- |
| 1 | **锚**：`module` 必填且指向存在的模块节点 | **error** | §2.1 |
| 2 | `feature` 必须是 `module` 的子节点；**`phase FEATURE` 必须写 `feature`** | **error** | §2.1 / §2.2 |
| 3 | `phase` 必填且封闭枚举；**`face` 必填且封闭枚举**；`kinds` ≥1 且封闭；**目标维度恰好 1 个** | **error** | §2.2 |
| 4 | **`face` × `driver` 配对**：矩阵外的组合（`UI`→`E2E`/`MANUAL`；`API`→`HTTP`/`HOOKS`/`MANUAL`） | **error** | §2.2 / §2.3 |
| 5 | `driver` 必填；`MANUAL` 不得为 `GOLD` | **error** | §2.3 / §0.1 |
| 6 | **三段齐全**：`given` / `when` / `then` **各 ≥ 1 条指令** | **error** | §3（「不可执行 = 无意义」） |
| 7 | **词表封闭**：三段指令 / 判定词 / 算子 / 寻址面 全在词表内 | **error** | §3.1–§3.5 |
| 8 | **寻址可解析**：`view` / `record` / `event` / `role` / `api` 能解析到实体 | **error** | §3.5 |
| 9 | **`face` × `driver` × 动作矩阵**外的组合 | **error** | §3.2 |
| 10 | `phase UAT` 必须有 `reviewedBy` 双签；`source AI` 必须有双签 | **error** | ✔ [`../testing.md`](../testing.md) §9.1 可机检 1 / §1 |
| 11 | 每条 USER intent 的归属 module 下 **≥1 条 `phase UAT`** 用例 | **error** | §5（[`intent.md`](intent.md) §7-6 的 v2 形态） |
| 12 | 每个 `moduleType=1` 模块 ≥1 条集成用例；每个 `moduleType=2` 的 Feature ≥1 条功能用例 | warning | §5 |
| 13 | **`SUITE-SMOKE ⊆ SUITE-UAT-CORE`**；`phase UAT` 用例至少落一个 `DELIVERY` 集合 | **error** | §4.1（✔ 已裁 §9.1 可机检 2） |
| 14 | 集合不留孤儿（空集合 / 只含 `deprecated` 用例） | warning | §4.1（✔ 已裁 §9.1 可机检 3） |
| 15 | 弱断言：`then` 行无具体值 / 错误码 / 状态 | warning | [`../testing.md`](../testing.md) §6.2-2 |
| 16 | `depends` 无环 | **error** | §2.3 |
| 17 | 执行态记号 / 归属反指 / 审计 / 缺陷指针出现在文件里（§3.6 判据 1–4） | **error** | §3.6 |
| 18 | **三段里出现代码片段 / SQL / 脚本正文**（§3.6 判据 8） | **error** | §3.6 / §6 |
| 19 | 无对应声明的 `MECHANICAL` 用例（生成源已消失） | warning | §11 T-9 |

---

## 11. 议题台账（⏳ **待裁**）

| # | 议题 | 助手建议 | 对应差异 |
| --- | --- | --- | --- |
| T-1 | **UAT 的两个时点**：S1 出「验收准则（文字）」、S2 出「可执行 UAT」，是否成立（即承认 `../testing.md` §0.1「必须可执行」需按分层落地） | 成立；否则 S1 无法写出可执行用例（**作者口径 ④ 的直接推论**） | — |
| T-2 | **`req:` / `covers:` 彻底作废**（追溯只走 `module`），还是保留为「可选人工加注」 | **彻底作废**（双份真源必漂移）；需要时由 `mmda trace` 反查 | T12 / T13 |
| T-3 | **`phase` × `face` × `kinds` 三轴**（`phase` 取 `FEATURE/INTEGRATION/SYSTEM/UAT`、`face` 取 `UI/API`、`kinds` 五维标签） | 按 §2.2；库 `testPhase` 与 `testtype` 树第二层合并为 `phase` 一轴 | T16 / T20 |
| T-4 | **`kinds` 的维度与基数规则**（目标维度恰好 1、方法维度 ≤1） | 按 §2.2 表 | T9 |
| T-5 | **`suite` 成一等实体**（新 partType + 集合侧选择器） | 按 §4；用例侧写 `suite` = error | T10 |
| T-13 | **三段关键字用 BDD 的 `given` / `when` / `then`**（v3，取代 v2 的 `input` / `steps` / `output` 与 v1 的散文三句） | 按 §3；`when` 无序号、`then` 无 `expect`、`subject` 归 `given` | — |
| T-6 | **`given` / `when` / `then` 三段的指令词表**（`given` 7 / `when` 7 / `then` 11）首版范围；**断言词去掉 `expect`、`emitted` 取代 `event`**；**v5：各行「允许的 driver」列按 `face` 重排** | 按 §3 全上（少一条就等于留一个散文口子） | T5 / T6 |
| ~~T-7~~ | ~~`unit` 符号解析的时机~~（**v5 作废**：单元测试退出本语言，§6） | — | — |
| ~~T-8~~ | ~~`attach` 寄生模式是否允许~~（**v5 作废**：改为「回写」，§6） | — | — |
| T-9 | **机械用例的语言形态**：是否落文件、是否入同一 `TC` 池 | 落文件（`source MECHANICAL`）、入同一序号池（批量申请） | T1 / T13 |
| T-10 | **`driver` 轴**与库 `manual` 的收口（**v5 改值域**：`E2E` / `HTTP` / `HOOKS` / `MANUAL`，取消 `AUTO`；与 `face` 配对） | 按 §2.3 值域 + §2.2 配对表；库 `manual` 位归 `driver = MANUAL` | T19 / T4 |
| T-11 | **落库表名与写入口** | `MetaTest` 族（Pascal，同 `MetaIntent`）；**只允许改文件**，库直改必须回写 | T11 / T15 |
| T-12 | **缺陷是否进语言**（总闸 B0） | **B**：应用侧 `record Defect` + `stm DefectStatus`，语言只提供编号引用 | B0 |
| T-14 | **`face` 轴两值（`UI` / `API`）是否够** —— 是否需要 `BOTH`（同一条用例同时验前后端）或显式的「端到端」面 | 先定两值；跨端一次验的诉求由「`face UI` 的 UAT 用例 + `then` 里反查 `api`」覆盖，不新增 `BOTH` | — |
| T-15 | **`driver` 值域与 `face` 配对表**（`UI`→`E2E`/`MANUAL`；`API`→`HTTP`/`HOOKS`/`MANUAL`） | 按 §2.2 配对表；`HTTP` = 真发请求、`HOOKS` = 三端拦截点直调 | T10 / T19 |
| T-16 | **单元测试退出本语言**（~~`phase UNIT`~~ / ~~`unit` 锚~~ / ~~`harness`~~ / ~~`attach`~~ / ~~指令→代码映射表~~ / ~~`mmda test-gen`~~ 全废）—— m 语言只管 feature / module 功能验证 | 按 §6；单元测试用 JUnit / xUnit / vitest 原生写 | T5 / T6 / T7 |
| T-17 | **`mmda test-import --from <框架> <文件>`**（从既有单测反向捞「哪些 feature 已验」）是否保留 | 保留为**可选入口**，产出待审的 `test` 骨架（`source MECHANICAL`），不自动进真源 | T1 / T13 |

---

## 相关

- 测试总篇：[`../testing.md`](../testing.md)（§0.1 UAT / §0.2 类型展开 / §1 来源与审签 / §5 三层验收物 / §6 覆盖率 / §9.1 三维度——**管理面真源**）
- 落库：[`test-store.md`](test-store.md)（`MetaTest` 族——**唯一落库面**；~~与 `mmda_alm` 五表的投影映射~~ 已随该库废除，只留参考对照）
- 库侧实测与差异：[`../examples/alm/差异对照-测试与缺陷.md`](../examples/alm/差异对照-测试与缺陷.md)（T1–T25 / B0–B6 / L12–L20）
- 示例：[`../examples/alm/TC-000045.m`](../examples/alm/TC-000045.m)（UAT 面 + 功能面）· [`../examples/alm/SUITE-UAT-CORE.m`](../examples/alm/SUITE-UAT-CORE.m)（集合）
- 上游语言面：[`intent.md`](intent.md)（§4 回指 · §6 与测试的关联 · §7 门禁）· [`modules.md`](modules.md)（§1 两种节点 · §2 模块编号 · §3 模块挂什么）· [`project.md`](project.md)（§1.2 首关键字清单含 `test` / `suite`）
- 质量与追溯：[`../quality.md`](../quality.md) §5 追溯链 · [`../requirements.md`](../requirements.md) §2.1（模块三级）· §2.2 / §7-11（写入口）
