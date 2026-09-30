# 用例落库：`MetaTest`（元对象存储）

> **为什么有这篇**：[`test.md`](test.md) 定下「**测试用例进 m 语言**」（partType `test` / `suite`，住 `tests/`），[`../testing.md`](../testing.md) §9.1 定下「**进库（分类 / 集合 / 状态）+ 进 IDE**」。✔ **2026-09-28 作者已裁「意图进库 = 元对象路线」**（落内核 `Meta*` 族，业务表降为投影，解 [`../examples/alm/差异对照.md`](../examples/alm/差异对照.md) D0 = A）——**本篇把同一路线套到用例上**：语言子句逐条推成表结构，让「进语言 → 进库 → 进 IDE」三面同源。
> **v2 增量（2026-09-29 二轮，随 [`test.md`](test.md) v2）**：① **锚 `module` / `feature` / `unit`** 取代 `req` / `covers`（`MetaTestReq` / `MetaTestCover` 作废 ⇒ 改 `MetaTestAnchor` 视图）；② `kind` 单列**改 `MetaTestKind` 关联表**（`kinds` 多维标签）；③ **`suite` 成一等实体**（`MetaTestSuite` 带**选择器**列 + `MetaTestSuiteMember` 物化成员）；④ 新增 **`MetaTestAddr`**（三段里引用的 `addr` 反转索引，`--impact` 的精细面）与 **`harness` 四列**（单元测试对接框架）。
> **v3 增量（2026-09-29 三轮，随 [`test.md`](test.md) v3）**：正文三段关键字取 BDD **`given` / `when` / `then`**（可执行 DSL，取代 v2 的 `input` / `steps` / `output`；`when` 行序即步序、`then` 无 `expect`、被测对象构造归 `given` 的 `subject`）；**`MetaTest` 三列取语言同名 `given` / `when` / `then`**（**`when` / `then` 是 SQL 保留字 ⇒ 元库 DDL 必须加引号**），投影 `mmda_alm` 仍用 `preCondition` / `inputData` / `expectedResult`（§10-13）。
> **v4（2026-09-29 四轮 · 作者裁）**：**`mmda_alm` 仅作参考，不再作为投影目标，将来废除**（作者原话：「**mmda_alm仅仅给你作参考，不用投影，以后废除了**」）。落库只留**一层**：`tests/*.m` →（`mmda build`）→ 内核 **`MetaTest` 族**——它是**唯一落库真源**；**§8 的库侧逐列对照降为「参考」**（仅供看懂旧库现状 / 评估迁移，**不进 `mmda check` 门禁**）；**执行面**仍只落 `MetaTestRun`。
> **v5 增量（2026-09-30 五轮，随 [`test.md`](test.md) v5）**：① **新增 `face` 列**（`UI` / `API`，前端交互 vs 后端接口，**必填**）并与 `driver` 配对；② `driver` 值域改 **`E2E` / `HTTP` / `HOOKS` / `MANUAL`**（取消 `AUTO`）；③ `phase` 四档改 **`FEATURE` / `INTEGRATION` / `SYSTEM` / `UAT`**（取消 `UNIT`）；④ **删除 `unitRef` 列与 `harness` 四列（`framework` / `language` / `emitAt` / `attachPath`）**——**单元测试退出 m 语言**（用 JUnit / xUnit / vitest 原生写），落库不再有单测生成物面；⑤ `MetaTestSuiteSelector.field` 增 **`FACE`**；⑥ `MetaTestAddr.face` 列**改名 `surface`**（避免与新的 `face` 子句撞名），值域去 `UNIT`。
> **取材**：[`test.md`](test.md) §1–§10 的子句 + [`../testing.md`](../testing.md) §0.1 / §5 / §6.2 / §9.1 + 库侧实测 DDL（**仅参考、非投影目标**；`mmda_alm.testcase` **24 列** / `teststep` / `testcasedependency` / `testtype` **20 行两级树** / `bug` **18 列**，本机 `127.0.0.1:3306`；**21 张表里无任何 Suite 表**）+ legacy 元库族命名（[`legacy/java-factory.md`](../legacy/java-factory.md)）。
> **三条不变量**（与 [`intent-store.md`](intent-store.md) §0 逐条同源）：
> ① **文件是真源、库是产物** —— `tests/*.m` 可整目录重建 `MetaTest` 族（**唯一落库面**；`mmda_alm` 仅参考、将废除）（[`../../PLAN.md`](../../PLAN.md) §0 A4、[`project.md`](project.md) §0）；
> ② **库不引入语言面没有的概念** —— 每一列都能指回一条子句，指不回去的列不进元对象；
> ③ **值域存语言里的符号名**（`UAT` / `SMOKE` / `GOLD` / `HOOKS`…），**不存 tinyint 序号**（收口库侧 L7 / L8）。
> **一条本篇特有的划界**：**声明面进元对象，执行面不进**（[`test.md`](test.md) §0.2）——造出来的真实数据、`actualResult` / `PASS` / `FAIL` / 耗时 / 目标端**只落 `MetaTestRun`**。
> **状态**：**草案 v5（2026-09-30 五轮；二 / 三 / 四轮口径不变）**；**未裁定项见 §10**。
> **联动**：[`test.md`](test.md)（语言面唯一规范）· [`intent-store.md`](intent-store.md)（同一路线的先例）· [`../examples/alm/差异对照-测试与缺陷.md`](../examples/alm/差异对照-测试与缺陷.md)（T / B / L 条目与勾选区）。

---

## 0. 定位：两层同源（文件真源 → 内核元对象）

```text
tests/*.m ──(mmda build)──▶ MetaTest 表族          （mmda_alm.testcase —— 仅参考，将废除）
   ▲ 真源                        ▲ 内核元存储（唯一落库面）        ✗ 不再是投影目标
   git 版本控制                  mmda check 的用例门禁落点
```

| 面 | 角色 | 说明 |
| --- | --- | --- |
| `tests/*.m` | **真源** | 唯一可写面；进 git，审签走 [`../workflows.md`](../workflows.md) §1.3 权限。**三段的执行靠解析真源的 AST，不靠下面这几张表** |
| `Meta*` 表 | **产物** | 由文件构建；`mmda check` 的用例门禁、`mmda trace TC-…`、`--impact` 的反向索引都建在这里 |
| ~~`mmda_alm.testcase`~~ | **仅参考（将废除）** | 旧 ALM 应用的业务表（含执行态、审计 7 件套）；**v4：不再投影、不进 `mmda check`、不是真源**——构建产物只有上一层 |

> **为什么与 [`intent-store.md`](intent-store.md) 结构同形**：两者是**同一条路线**（文件真源 → 内核元对象；应用投影层已随 `mmda_alm` 废除，v4），差别只在**语言子句不同**。结构同形使「元对象落库」这件事只有一个心智模型。

---

## 1. 命名（承 [`intent-store.md`](intent-store.md) §1：`Meta*` Pascal 族）

| 对象 | 名称 | 依据 |
| --- | --- | --- |
| 主表 | **`MetaTest`** | 同 `MetaIntent` 族；✔ 2026-09-28 已裁「元库命名取 `Meta*` Pascal」（[`intent-store.md`](intent-store.md) §1） |
| 类别标签（M:N） | **`MetaTestKind`** | v2：`kinds` 是多维标签（[`test.md`](test.md) §2.2），单列装不下 |
| 引用索引 | **`MetaTestAddr`** | v2：三段里的 `addr`（`view` / `api` / `record` / `event` / `role`；**v5 去掉 `unit` 面**）反转索引 |
| 备选场景 | **`MetaTestAlt`** | 见 §3 |
| 集合 | **`MetaTestSuite`**（含选择器）+ **`MetaTestSuiteMember`**（M:N，**物化成员**） | v2：[`test.md`](test.md) §4（集合是一等实体） |
| 执行历史 | **`MetaTestRun`** | [`../testing.md`](../testing.md) §9.1（拟名 `MetaTestRun` 已在本仓登记） |
| 关联表 | **`MetaTestDependency`** / **`MetaTestTag`** / **`MetaTestReview`** | 同族 |
| ~~作废~~ | ~~`MetaTestReq`~~ / ~~`MetaTestCover`~~ | v2：[`test.md`](test.md) §0.3 追溯改走 `module`，`req` / `covers` 不存在 |
| 缺陷（若裁 A，见 §7） | `MetaDefect` | 同族 |
| 列 / 主键 / 唯一 / 外键 / 索引 | `camelCase` / `PK_MetaTest` / `UQ_MetaTest_testNo` / `FK_MetaTest_*` / `IDX_MetaTest_*` | [`naming.md`](../naming.md) §3.3 |

---

## 2. 主表 `MetaTest`：列 ↔ 语言子句逐条对

| 列 | 类型 | 来源子句 | 说明 / 门禁 |
| --- | --- | --- | --- |
| `testID` | bigint | （内核签发） | PK；**与 `TC-<NNN>` 解耦**（编号是人读锚，主键是机器锚） |
| `testNo` | varchar(32) | `test TC-<NNN>` | **NOT NULL + UNIQUE**（收 L13：库 `testCaseNo` 只有普通索引） |
| `label` | varchar(255) | `/// <label>` | NOT NULL；**中文验收单由它生成**（[`../testing.md`](../testing.md) §5-②） |
| `description` | varchar(1024) | `/// … : <description>` | 可空 |
| `moduleCode` | varchar(32) | `module M.03` | **NOT NULL**（v2 的**主锚**）；必须是 `moduleType=1` 的节点 ⇒ 否则 error |
| `featureCode` | varchar(32) | `feature M.03.002` | 可空；写了必须是该 `moduleCode` 的子节点 ⇒ 否则 error |
| `phase` | varchar(16) | `phase` | NOT NULL；CHECK ∈ `FEATURE` / `INTEGRATION` / `SYSTEM` / `UAT`（**v5 去 `UNIT`**） |
| ~~`kind`~~ → **`MetaTestKind.kind`** | varchar(24) | `kinds { … }` | v2：条数 ≥1；CHECK ∈ 封闭词表；**目标维度恰好 1 条**（[`test.md`](test.md) §2.2） |
| `source` | varchar(12) | `source` | NOT NULL；CHECK ∈ `MECHANICAL` / `SNAPSHOT` / `AI` / `MANUAL` |
| `level` | varchar(8) | `level` | NOT NULL；CHECK ∈ `GOLD` / `NORMAL` / `DRAFT`；默认按 `source` 推（AI ⇒ DRAFT） |
| `face` | varchar(8) | `face` | NOT NULL；CHECK ∈ `UI` / `API`（v5 新增）；**与 `driver` 必须配对** ⇒ 否则 error |
| `env` | varchar(8) | `env` | 可空；CHECK ∈ `DEV` / `TEST` / `PROD` |
| `importance` | varchar(16) | `importance` | 可空；同 `MetaIntent.importance` 值域（**一处枚举，两处复用**） |
| `priority` | varchar(16) | `priority` | 可空；同 `MetaIntent.urgency` 值域 |
| `given` | text | `given { … }` | NOT NULL；**列内一条指令一行**（保序） |
| `when` | text | `when { … }` | NOT NULL；**行序 = 步骤序**（行号即 `teststep.testStepID`，v3 不再写 `step <n>`；`when` 是 SQL 保留字 ⇒ **DDL 必须加引号**） |
| `then` | text | `then { … }` | NOT NULL；列内一条一行；**`then` 是 SQL 保留字**（MySQL / PostgreSQL 的 `CASE … THEN`）⇒ **列名必须加引号** |
| `lifecycle` | varchar(12) | （**工具态，不在文件**） | NOT NULL，默认 `DRAFT`；CHECK ∈ `DRAFT` / `REVIEWED` / `FROZEN` / `DEPRECATED`（[`test.md`](test.md) §11 T-11） |
| `revision` | int | （库自留） | NOT NULL 默认 0；**元对象只留这一个是「版本」，其余由 git 承载**（同 D13 口径） |

> **为什么 `when` 的顺序就是步骤顺序**：`teststep.testStepID` 是**序**不是**身份**（[`test.md`](test.md) §3.2）——有序列表落一列（一条一行）即可保序，不需要子表；v3 把序号从语言里拿掉（行号即序号），**投影层按行序回填 `testStepID`**。
> **为什么 `lifecycle` 在元对象却不进文件**：它是**工具管的态**（[`../testing.md`](../testing.md) §11-13），文件里由 `baseline/<版本>` 与 `reviewedBy` 表达；落库是为了 IDE 看板能查（[`../testing.md`](../testing.md) §8.1）。

### 2.1 `MetaTestAddr`：三段引用索引（v2 新增）

| 列 | 说明 |
| --- | --- |
| `testID` + `block`（`GIVEN` / `WHEN` / `THEN` / `ALT`）+ `seq` | 复合 PK（v3 取 BDD 块名） |
| `surface` | `VIEW` / `API` / `RECORD` / `EVENT` / `ROLE`（v5 由 `face` 改名 `surface`，去掉 `UNIT` 面） |
| `addr` | 解析后的寻址串（如 `view ProductionOrderList.rows.status`） |
| `resolved` | 解析结果标识（`M.03.002` / `ProductionOrder.status` / 端点 id…） |

> **为什么要有它**：v2 的**归属锚只到 module**（粗），但 `--impact` 要回答的是**精细问题**——「改 `ProductionOrder.status` 会挂哪些用例？」「这条 `view` / 这个 `api` 端点被谁验着？」。这张表由 `mmda build` **从三段里扫出来**（**不是真源**，可随时重建），让「锚粗 + 引用细」两个精度同时存在：**归属稳定、影响精确**。

---

## 3. 正文落法：三段三列 + `alt` 一张子表

| 选项 | 形态 | 评价 |
| --- | --- | --- |
| **A**（推荐） | `given` / `when` / `then` **各一列** `text`（列内一条指令一行）；`alt` 建 **`MetaTestAlt`** 子表（`testID` + `seq` + `sceneName` + `given` / `when` / `then` 三列） | 三段是**这一行自己的三个值**（同 `MetaIntent.why` / `what` 的道理）；`alt` 是**有序 + 有名 + 多组**，有独立身份 ⇒ 建子表名正言顺 |
| B | 全建子表 `MetaTestStep`（`seq` + `block` + `verb` + `text`） | 指令变成一行，join 次数多；**执行要的 AST 本来就从 .m 解析**，子表只是给 IDE 查询用 |
| C | 全落一列（Markdown 式小标题拼串） | **反对**：库内不可查询、不可对账，覆盖算法失去输入 |

**为什么 `alt` 与主体不同待遇**：主体三段是**必填、各一列**（结构固定）；`alt` 是**可选、可多组、每组有名**（`alt "无命中" { … }`）——「有名字的多组」= 有独立身份的实体，才是子表的判据（同 [`intent-store.md`](intent-store.md) §0 的「为什么只有一张主表」）。

**执行面一律不进本表**（[`test.md`](test.md) §3.6）：造出的数据、`actualResult` / 结果 / 耗时 / 目标端 → §5。

---

## 4. 集合 `MetaTestSuite` / `MetaTestSuiteMember`（v2 改版）

| 表 | 列 | 说明 |
| --- | --- | --- |
| `MetaTestSuite` | `suiteCode`（PK，如 `SUITE-UAT-CORE`）/ `label` / `description` / `runWhen`（`BUILD` / `DAILY` / `MILESTONE` / `DELIVERY`） | 集合**声明**（[`test.md`](test.md) §1.2） |
| `MetaTestSuiteSelector` | `suiteCode` + `field`（`PHASE` / `FACE` / `KINDS` / `MODULE` / `FEATURE` / `SOURCE` / `LEVEL` / `DRIVER` / `ENV` / `TAG`）+ `value` | **成员规则**（v2 新增：成员由选择器算出，不再靠人维护清单；**v5 增 `FACE`**） |
| `MetaTestSuiteInclude` / `MetaTestSuiteExclude` | `suiteCode` + `testNo` | 白名单 / 黑名单（例外） |
| `MetaTestSuiteSubset` | `suiteCode` + `ofSuiteCode` | 集合包含关系（`SUITE-SMOKE ⊆ SUITE-UAT-CORE`） |
| `MetaTestSuiteMember` | `testID` + `suiteCode`（复合 PK） | **物化成员**：`mmda build` 按选择器 + 白黑名单算出来（**产物，不是真源**） |

**门禁**（[`test.md`](test.md) §10-14/15，✔ 已裁 [`../testing.md`](../testing.md) §9.1 可机检 2/3）：`SUITE-SMOKE ⊆ SUITE-UAT-CORE`（**error**）；`phase UAT` 的用例至少落一个 `runWhen DELIVERY` 的集合（**error**）；集合不留孤儿（warning）。

> **为什么集合要有表 + 选择器，而不是只留标签串**：① `smoke ⊆ uat` 这类**集合间关系**只有把集合当实体才可判定；② **成员随模型自动重算**——新加一条 `phase UAT` 用例，`select { phase UAT }` 的集合自动收编，不用回头改集合文件（`tags` 式的双份真源必然漂移，收 D12 同款问题）。

---

## 5. 执行历史 `MetaTestRun`（**执行面唯一落点**）

| 列 | 说明 |
| --- | --- |
| `runID` | PK |
| `testNo` | 指向 `MetaTest.testNo`（**不用 testID**：执行记录要能跨基线版本回溯，编号是稳定锚） |
| `target` | 目标端（`JAVA` / `CSHARP` / `TS` / `RUST`，对应 `mmda test --target`） |
| `driver` | 本次实际走的通道（`E2E` / `HTTP` / `HOOKS` / `MANUAL`，可与声明不同——声明是默认值） |
| `result` | `NOT_RUN` / `PASS` / `FAIL` / `BLOCKED` / `STALE`（✔ 已裁 [`../testing.md`](../testing.md) §9.1） |
| `actualResult` | 实际结果（**库 `testcase.actualResult` 的正确归宿**，差异 T15） |
| `inputRef` | 本次造数落库后的**真实主键 / 夹具指纹**（声明里的 `input` 是期望形态，这里是实跑形态） |
| `startedAt` / `durationMs` | 时间与耗时 |
| `failureReason` | 失败原因（AI 可在此出诊断报告，判定仍由基线给，[`../testing.md`](../testing.md) §0-3） |
| `baselineVersion` | 跑的是哪个冻结基线（[`../testing.md`](../testing.md) §5） |

**为什么执行面必须单独一张表**：① 一条用例**要跑很多次**（每日 / 里程碑 / 三端），静态表存不下历史；② 「状态」是**跑出来的**，不是**写出来的**——混进静态表会让「用例被改了」与「用例跑挂了」两类事件互相覆盖（`--impact` 的 `STALE` 与执行 `FAIL` 因此分不清）。

---

## 6. 审签 `MetaTestReview`

| 列 | 说明 |
| --- | --- |
| `testNo` | 指向用例 |
| `role` | `BUSINESS` / `DESIGNER`（✔ 已裁双签口径，[`../testing.md`](../testing.md) §11-3） |
| `reviewerID` / `reviewedAt` | 签字人与时间（留痕，可写进 `changelog`，同 [`../testing.md`](../testing.md) §5 的验收凭证口径） |
| `revision` | 签的是哪个修订（改了就失效，须重签） |

**门禁对应**（[`test.md`](test.md) §10-11）：`phase UAT` 与 `source AI` 的用例，**双签齐**才能把 `lifecycle` 从 `DRAFT` 迁到 `REVIEWED`；只有 `GOLD` 进 `baseline/`。

---

## 7. 缺陷落点（取决于总闸 B0，[`test.md`](test.md) §9）

| 若裁 | 落法 |
| --- | --- |
| **B**（助手建议） | 缺陷 = 应用侧 `record Defect` + `stm DefectStatus`（S2 建模，住 ALM 应用模型）；**元对象侧只建反向索引**：`Defect.testCaseNo : TC-…` ⇒ 用 `MetaTest`（→ `moduleCode` → `satisfies`）反查，支撑 [`../testing.md`](../testing.md) §6.1「缺陷回溯覆盖」。v2 **不再需要** `Defect.req`（[`test.md`](test.md) §0.3） |
| **A** | 新增元对象 `MetaDefect`（`defectNo` `BUG-<NNN>` / `label` / `description` / `severity` / `urgency` / `testNo` / `stepNo` / `moduleCode` / `foundIn`），`bug.status` 由 `stm` 声明承载 |
| **C** | 不表态；库侧断链维持现状（差异 **B4** / L10），**不推荐** |

---

## 8. 附：与 `mmda_alm` 的对照（**仅参考，不再投影**）

> **v4**：本节**不是投影规范**——`mmda_alm` 仅作参考、将来废除。下面逐表对照的用途只剩两个：**看懂旧库现状**、**评估将来要不要迁移**；「处置」列里的「映射」「改一对多」等词是**若真要迁移**的动作，**不进 `mmda check` 门禁、不构成本轮工作量**。

### 8.1 `testcase`（24 列）

| 库列 | 处置 | 映射 / 理由 |
| --- | --- | --- |
| `testCaseID` | 映射 | ← `MetaTest.testID`（投影层自增） |
| `testCaseNo` varchar(30) | 映射 | ← `testNo`（**补 UNIQUE**，收 L13；长度 30 → 32） |
| `testPhase` tinyint | 映射 | ← `phase`（符号名 ↔ 序号由投影层转；序号不再是真源，收 L8） |
| `testTypeID` FK→`testtype`（**单值**） | **改一对多** | ← `MetaTestKind`（`kinds` 多标签）；应用自定义类型仍经 `TestType`（§8.4；收 T2 / **T20**） |
| `testCaseDescription` | 映射 | ← `label` + `description`（收 T18 / 同 D9 口径） |
| `moduleCode` | **反推** | 元对象侧已有 `moduleCode`（v2 的锚）⇒ **投影层直抄**；`featureCode` 库侧无落点，收 **T21** |
| `importance` / `priority` | 映射 | ← `importance` / `priority`（同名；收 L7 / L8） |
| `environment` | 映射 | ← `env` |
| `manual` bit(1) | 映射 | ← `driver = MANUAL`（**语义重定位**：`driver` 是「怎么跑」，收 T19） |
| `preCondition` / `inputData` | 映射 | ← `given`（投影层按指令切分：`user` / `ref` / 前置类 → `preCondition`，`data` / `mock` / `file` / `subject` / `seed` → `inputData`） |
| `expectedResult` | 映射 | ← `then` |
| `actualResult` | **执行面** | **不进元对象** ⇒ `MetaTestRun.actualResult`（收 T15） |
| `status` smallint | **执行面** | **不进元对象** ⇒ `MetaTestRun.result`；生命周期态走 `MetaTest.lifecycle`（收 T15 / T10） |
| `tags` | 映射 | ← `MetaTestTag`（库侧逗号串与 `tag` 表两份真源在投影层收敛，同 D12） |
| `revision` | 映射 | 同名 |
| `deptID` / `creatorID` / `createDate` / `lastModifierID` / `lastModified` / `ownerID` / `ownerDeptID` | **应用自留** | 审计 7 件套不进元对象（同 D13） |
| **（缺）** | **新增投影面** | `face` / `kinds`（→ `MetaTestKind`）、`driver` / `source` / `level` / `reviewedBy` / `suite` 成员（→ 相应表）**在库侧没有等价列**（收 T7 / T11 / T13 / T20） |

### 8.2 `teststep` / `testcasedependency`

| 库对象 | 处置 | 说明 |
| --- | --- | --- |
| `teststep.testCaseID` + `testStepID` | 映射 | ← `MetaTest.testID` + **`when` 的行序**（v3：**行号即步序**，语言里不写 `step <n>`） |
| `teststep.desctiption` | 映射 | ← `when` 行；**列名拼写错**（`desctiption`），收 **L14** |
| `teststep.testScript` | **执行面** | 不进元对象 ⇒ 测试代码（由底座驱动 / 判定，**v5 起不由 m 语言生成**）+ `MetaTestRun`（收 T6） |
| `testcasedependency.testCaseID` / `preTestCaseID` | 映射 | ← `MetaTestDependency` |
| 注释里的 `TestCase(…,testCaseTitle)` | **不存在** | 表 `testcase` **没有 `testCaseTitle` 列**（收 **L12**） |
| `FK_pre_testcase` 只有 `ON UPDATE CASCADE` | 收 **L19** | 缺 `ON DELETE` 规则 ⇒ 删前置用例会报错，与 `FK_dependency_testcase`（`ON DELETE CASCADE`）不对称 |

### 8.3 分区段

`teststep`（`testCaseID` 首段）与 `testcasedependency`（`testCaseID` 首段）**均未登记分区段**——收 **L18**（同 [`差异对照.md`](../examples/alm/差异对照.md) L11 的处理：分区段随元对象定，投影层补）。

### 8.4 `testtype`（20 行，两级树）

| 库对象 | 处置 | 说明 |
| --- | --- | --- |
| `testTypeID` / `testTypeName` / `description` / `superTestTypeID` | **应用自留** | 应用侧 `record TestType`；`kinds` 是**内核封闭词表**，两者不混（收 L7 的「枚举与字典表口径不统一」） |
| 树**第二层**（单元 / 集成 / 系统 / 验收） | **合并入 `phase`** | 与 `testcase.testPhase` **是同一个东西的两份表达**（收 **T16** / 差异 T2） |
| 树**第一层**（功能 / 非功能） | **并入 `kinds` 的目标维度** | 不另立轴（[`test.md`](test.md) §2.2；收 T2） |
| 各叶子（白盒 / 冒烟 / 性能…） | **映射 `kinds` 标签** | 库侧 20 行叶子与 `kinds` 词表**多对一**；投影层做映射表 |
| `superTestTypeID` **无外键** | 收 **L16** | 自引用树无 FK 约束 |

### 8.5 `bug`（18 列）

| 库列 | 处置 | 映射 / 理由 |
| --- | --- | --- |
| `bugID` | 映射 | ← `Defect.id` |
| `bugTitle` / `bugDetails` | 映射 | ← `label` / `description`（收 T18 / 同 D9） |
| `urgency` | 映射 | ← 同名（与用例 / 意图共用值域） |
| `severity` | 映射 | ← `Severity`（`UNDEFINED` / `MINOR` / `MEDIUM` / `CRITICAL` / `FATAL`）——**两个正交轴：严重性 × 紧急性**，建议进标准（收 **B2**） |
| `status`（7 态） | 映射 | ← `stm DefectStatus`（收 **B5** / 同 D5 口径：**状态归 `stm`**） |
| `moduleCode` | **反推** | 缺陷归 module（与应用用例同一锚） |
| `moduleVersion` | 映射 | ← `foundIn: <baseline 版本>`（建议进标准，收 **B3**） |
| `tags` | 映射 | ← `DefectTag`（同 D12） |
| `deptID` … `lastModified` | **应用自留** | 审计 7 件套（同 D13） |
| `testCaseID` / `testStepID` | 映射 | ← `Defect.testCaseNo : TC-…` + `stepNo`；**补外键**（收 **L17**） |
| **（缺 `requirementID`）** | **经 module 反查** | v2 不再补 `requirementID` 列：`Defect → TC-… → moduleCode → satisfies → INT-…` 链已闭合（收 **B4**，[`test.md`](test.md) §0.3） |

---

## 9. 门禁（表级 ↔ [`test.md`](test.md) §10 逐条对应）

| # | 检查 | 落点 | 等级 |
| --- | --- | --- | --- |
| 1 | `testNo` NOT NULL + UNIQUE | 表级 | error |
| 2 | `moduleCode` NOT NULL；`featureCode` 是 `moduleCode` 的子节点；**`phase = FEATURE` ⇒ `featureCode` 非空** | 表级 + 服务层 | error |
| 3 | `phase` / `face` / `source` / `level` / `driver` / `env` 取值合法（CHECK）；**`face` × `driver` 配对** | 表级 + 服务层 | error |
| 4 | `MetaTestKind` 条数 ≥1、词表内、**目标维度恰好 1 条** | 表级 + 查询 | error |
| 5 | 三段非空（`given` / `when` / `then` 去空行后各 ≥1） | 表级 + 查询 | error |
| 6 | `phase = UAT` 或 `source = AI` ⇒ `MetaTestReview` 双签齐（BUSINESS + DESIGNER） | 查询 | error |
| 7 | 每条 USER intent 的归属 module 下 ≥1 条 `phase = UAT` 用例 | 查询（跨 `MetaTest` × `MetaModule` × `MetaIntent`） | error |
| 8 | `SUITE-SMOKE ⊆ SUITE-UAT-CORE`；`phase UAT` 用例至少落一个 `DELIVERY` 集合；集合无孤儿 | 查询 | error / warning |
| 9 | `MetaTestAddr.surface` / `addr` 能解析（`view` / `api` / `record` / `event` / `role`） | 服务层 | error |
| 10 | `MetaTestDependency` 无环 | 服务层 | error |
| 11 | 执行态记号不得出现在 `MetaTest`（`actualResult` / `result` / `target` 列**不存在**于本表） | 表级（**列存在即违规**） | error |
| 12 | 迁移合法：`DRAFT → REVIEWED → FROZEN → DEPRECATED`（不许跳级、不许回退） | 服务层 | error |
| 13 | 单条指令长度 ≤ 255 字符（三列按行计） | 表级 + 查询 | error |

> **表级只管「单行自洽」，跨行关系（覆盖 / 集合包含 / 环 / 迁移 / 寻址解析）一律走服务层**——同 [`intent-store.md`](intent-store.md) §7 的口径。

---

## 10. 裁定台账（⏳ **全部待裁**）

| # | 议题 | 助手建议 |
| --- | --- | --- |
| 1 | 正文落法：三列 + `alt` 子表 vs 全子表 vs 全一列 | **A：三列 + `MetaTestAlt`**（§3） |
| 2 | 执行面是否单独一张 `MetaTestRun`（库 `actualResult` / `status` 迁出） | **是**（§5，收 T15） |
| 3 | `lifecycle` 进元对象还是只进 IDE 配置 | **进元对象**（IDE 看板要可查，[`../testing.md`](../testing.md) §8.1） |
| 4 | 集合：建表 + 选择器 + 物化成员（vs 只留标签串） | **建表 + 选择器**（`smoke ⊆ uat` 与「成员自动重算」都要求它，§4 / 收 T10） |
| 5 | `kind` 单列改 `MetaTestKind` 关联表 | **改**（v2 的 `kinds` 是多维标签，单列装不下，§2） |
| 6 | 要不要 `MetaTestAddr`（三段引用反转索引） | **要**（锚只到 module，精细影响面靠它，§2.1） |
| 7 | `req` / `covers` 关联表是否删除 | **删除**（v2 追溯改走 `module`；保留即双份真源，§1 / [`test.md`](test.md) §0.3） |
| ~~8~~ | ~~`harness` 四列落主表 vs 另建 `MetaTestHarness`~~（**v5 作废**：单元测试退出 m 语言，§2） | — |
| ~~9~~ | ~~`${库} 单测生成物` 的落点与只读约束（`generated/` vs 目标端源码树）~~（**v5 作废**：不再由 `test` 声明生成单测代码，§8.1） | — |
| 10 | 审签是否单独一张 `MetaTestReview` | **建表**（双签 + 修订绑定，§6） |
| 11 | 缺陷落点（总闸 B0 的落库面） | **B**：应用侧 `record Defect`，元对象只做反向索引（§7） |
| 12 | 写入口（只允许改文件 / 库直改必须回写） | **只允许改文件**（同 [`../testing.md`](../testing.md) §11-15 建议） |
| 13 | 三段列名取 `given` / `when` / `then`（其中 **`when` / `then` 是 SQL 保留字**） vs 改用免引号的名字 | **取语言同名**（不变量 ②：列能指回子句优先）⇒ 元库 DDL **必须加引号**；~~投影到 `mmda_alm` 用 `preCondition` / `inputData` / `expectedResult`~~（**v4：不再投影**，该动机随之消失，但「加引号」结论保留） |

---

## 相关

- 语言面：[`test.md`](test.md)（**唯一规范**：`test` / `suite` / `TC-…` / module 锚 / **phase × face × kinds** / **given · when · then** / 门禁）
- 测试总篇：[`../testing.md`](../testing.md) §0.1 / §0.2 / §5 / §6.2 / §8.1 / §9.1
- 同行先例：[`intent-store.md`](intent-store.md)（`MetaIntent` 族，D0 = A 的落地篇）
- 库侧实测与差异（**仅参考**）：[`../examples/alm/差异对照-测试与缺陷.md`](../examples/alm/差异对照-测试与缺陷.md)（T1–T25 / B0–B6 / L12–L20）
- 上游：[`intent.md`](intent.md) §4 / §6 · [`modules.md`](modules.md) §1–§3 · [`../requirements.md`](../requirements.md) §2.1 / §2.2 / §7-11
- 命名：[`naming.md`](../naming.md) §3.3 · 追溯链：[`../quality.md`](../quality.md) §5
