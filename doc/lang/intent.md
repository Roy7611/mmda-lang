# 意图：Intent（Why / What）

> **为什么有这篇**：**intent 是最先产生的产物——先于模块树、模型、用例集与一切交付物**。因此它既要自足（不暴露任何下游产物的存在），又要能被下游**单向回指**，从而前后可追溯、可关联。
> **来源**：✔ **2026-09-28 作者裁定**——关键字用 **`intent`**（不用 `requirement`）；**intent 先于所有其他产物**；**`why` / `what` 分条**；**`layer` 只保留 `BUSINESS` / `USER` 两档**（BUSINESS = 较宏观的业务目标）；**USER 层必须声明 `role`，并可经 `usecase` 细化**（usecase 可用 m 语言描述、可 UML 图形化、可经 UAT 验证）；**UAT 挂在 intent 上**；本篇**新开**。
> **来源（同日二轮裁定）**：`area` **要**，关键字改叫 **`subject`**（**必填**，SERU 的 Subject Area）；**`BUSINESS` 不允许直接挂 `usecase`**（必须先拆成 `USER` 意图）；**BUSINESS / USER 两档之外不再有第三档**；**usecase 的 UML 图形适配器已登记**（[`ide/diagram-adapters.md`](../ide/diagram-adapters.md) §7）；**How 黑名单词表暂时不考虑**（§9-6）；[`requirements.md`](../requirements.md) **已按本篇回改**。
> **来源（同日三轮裁定）**：**粒度 = 一文件可放多条 `intent`**（与 `record` 同：一文件一条是推荐、非硬规则），**同文件内相互引用不写 `import`**、跨文件用 `import`；**暂时不要多行字面量**（`why` / `what` 就用短句列表 + `"…"`）；**建模侧回指 `satisfies UC-…` 与 `satisfies INT-…` 都允许**（一条声明点至少一处回指）；**意图进库走元对象路线**（`Meta*` 族，不落 `mmda_alm.requirement` 业务表；**⤴ 2026-09-29 四轮：`mmda_alm` 仅参考、将废除，不再有投影层**）。
> **来源（2026-09-29 补裁）**：**正文落库取双列**——`why` / `what` 各一列落主表 `MetaIntent`（`text`，**一条一行**），**不建 `MetaIntentWhy` / `MetaIntentWhat` 子表**（一个 intent 就描述一个 `why` / 一个 `what`）；**语言面的分条语义不变**（仍是短句列表，只是落进一列）。落点：[`intent-store.md`](intent-store.md) §3 / §8。
> **来源（2026-09-29 裁）**：**`what` 恰好 1 条**（作者：「what 我觉得只能 1 条」）、**`why` 最多 5 条**（作者：「why 允许最多 5 条」）——超限 = **该拆 intent**，不是放宽阈值；**单条 ≤ 255 字符**（作者：「255」）（§2.3 / §2.3.1）。
> 联动：[`requirements.md`](../requirements.md)（需求工程 · SERU）· [`project.md`](project.md)（首关键字 / 目录 / 四阶段）· [`modules.md`](modules.md)（模块树，S2）· [`testing.md`](../testing.md)（UAT 与追溯）· [`ide/graph-files.md`](../ide/graph-files.md)（图形是投影）· [`ide/diagram-adapters.md`](../ide/diagram-adapters.md)（usecase 的 UML 适配器）。
> 状态：**草案（2026-09-28 立；同日二轮裁定后 [`requirements.md`](../requirements.md) §2 / §5 / §7 已同步）**。

---

## 0. 定位：最先的产物

| 时间面 | 产物 | 谁写 |
| --- | --- | --- |
| **0（最先）** | **`intent`** —— 意图：Why / What（`BUSINESS` / `USER` 两档） | 业务 + 架构师 |
| 1 | `usecase` —— 用例：把 **USER 层**意图细化为「一段交互与其结果」 | 设计师 |
| 2 | 建模（S2）—— 模块树 / record / stm / flow / ui / api：定义 **How**，产出 spec | 架构师 + 设计师 |
| 3 | 验收（S3）—— UAT 用例：把 `what` 变成可执行断言（**挂回 intent**） | 设计师 + 业务 |
| 4 | 交付（S4）—— 生成物 + Profile | 底座 / AI |

**三条推论（本篇的设计全由它推出）**：

1. **intent 不能引用下游产物**：模块树是 S2 的产物，签发意图时还不存在 ⇒ intent **不写 `@Feature` / `satisfiedBy` / `accept`**。
2. **编号不能含模块段**：`REQ-<模块编码>-<NNN>` 要求签发时已知模块编码 ⇒ 作废；改**纯序号** `INT-<NNN>`（**解 [`requirements.md`](../requirements.md) §7-8**）。
3. **可追溯 = 下游回指 + 内核索引**（§4）——与 [`testing.md`](../testing.md) §9.1「UAT 用 `req:` 回指需求」**同一方向**。

> **为什么不让 intent 自己写指针**：那会让最先的产物依赖最晚的产物，且建模一重构就得回头改已冻结的意图文件（两份真源 + 反复 churn）。**下游指向上游，上游保持稳定。**

---

## 1. 语法

```sql
/// <label> : <description>
intent <INT-编号> {
    <分类轴子句…>
    why  { "…", "…", }
    what { "…", "…", }
}
```

| 项 | 规则 |
| --- | --- |
| 文件 | `*.m`（唯一后缀），**首关键字 `intent` 判定 partType**（[`project.md`](project.md) §1） |
| 粒度 | **一文件可放多条 `intent`**（✔ 2026-09-28）——与 `record` 同一条规则：**一文件一条是推荐、非硬规则**（同 [`workflows.md`](../workflows.md) §6「一对象一文件，推荐非硬规则」）；**同文件内相互引用不写 `import`**，跨文件引用用 `import`（[`runtime.md`](../runtime.md) §4.7） |
| 目录 | 住阶段根 **`intents/`**（可用子目录分组）；**文件名自由**（推荐按主题 / 模块命名），编号写在声明里（`INT-<NNN>`），**不要求文件名 = 编号** |
| 体 | **一行一条、行末逗号必须写**（与 `record` 体同一书写习惯） |
| 块 | `why` / `what` 用 `{ … }`；块内一句一条、行末逗号 |
| 字符串 | 与既有 `"…"` / `'…'` 字面量一致；✔ **2026-09-28 裁定：暂时不要多行字面量**（`why` / `what` 就用短句列表 + `"…"`，一条一句） |
| 关键字 | **封闭清单**：`layer` `role` `subject` `type` `importance` `urgency` `tag` `parent` `depends` `why` `what`；拼错 = **解析期 error** |
| 条数 / 长度 | 一句话一条；**`what` 恰好 1 条**、**`why` 1–5 条**（✔ 2026-09-29 裁）、**单条 ≤ 255 字符**（✔ 2026-09-29 裁）——见 §2.3.1 |

---

## 2. 子句参考

### 2.1 层次 `layer`：只两档

| 取值 | 是什么 | 粒度判据 | 例子 |
| --- | --- | --- | --- |
| `BUSINESS` | **较宏观的业务目标** | 一条 = 一个业务区划 / 业务事件 / 业务规则，回答「为谁解决什么问题、不解决会怎样」 | 「生产排程可视化，让计划员不再靠纸质台账」 |
| `USER` | 关键用户在一段流程里要做成的事 | 一条 = 一个 Role 的一个可观察结果 | 「计划员能按状态筛选生产订单」 |

- **两档之间的关系 = 拆解**：`BUSINESS` 意图由一条或多条 `USER` 意图支撑（`USER` 侧写 `parent INT-…` 回指）。**不是 1:1**——一个宏观目标通常拆成多条用户意图。
- **细化的方向**：`BUSINESS --拆解--> USER --usecase 细化--> 建模声明点`。
- **BUSINESS 不得直接挂 `usecase`**（✔ 2026-09-28 裁定）：细化链必须**逐层走**——宏观目标先拆成 `USER` 意图，再由 `USER` 意图接 usecase。BUSINESS 直接挂 = 「它其实该拆」的信号，`mmda check` 出 error（§7-8）。
- ⚠️ **功能层不再是一档**：字段 / 约束 / Action / 状态迁移这类「功能需求」**不属于 intent**（它们已是 How 的形状），由 S2 建模声明点承载，经 `satisfies` 回指上来（§4、§8）。

### 2.2 其余分类轴

| 子句 | 取值 | 语义 | 门禁 |
| --- | --- | --- | --- |
| `role` | 关键用户（Role 名） | 触发者（SERU / RUP 的 Actor） | **USER 层必填**；必须是已声明的 Role；无孤立 Role |
| `subject` | 业务主题域（SERU 的 Subject Area，自由文本） | S1 期的分组轴（一条 = 一档业务区划）；S2 建模时细化为 System / Module | **必填**（✔ 2026-09-28 裁定；关键字由 `area` 改叫 `subject`） |
| `type` | `BASIC` / `DESIRED` / `ATTRACTIVE` / `INDIFFERENT` / `UNDESIRED` | **Kano 价值分类** | 可选；与 `layer` **正交**（一个是「谁的需求」，一个是「对谁的价值」） |
| `importance` | `UNKNOWN` / `IMPORTANT` / `VERY_IMPORTANT` | 重要性 | 可选 |
| `urgency` | `NORMAL` / `SENIOR` / `URGENT` | 紧急性 | 可选 |
| `tag` | 字符串列表 | 标签 | 可选 |
| `parent` | `INT-…` | 拆解来源（**同层引用**，允许） | 环检测 = error |
| `depends` | `INT-…` 列表 | 前置依赖（**同层引用**，允许） | 环检测 = error |

> **只允许同层引用**：intent 体内**不得**出现指向 usecase / 建模物 / UAT 的引用（§3 判据 1）。
> **BUSINESS 不挂 usecase**：细化必须逐层（`BUSINESS → USER → usecase`）——`BUSINESS` 体内出现 `usecase` 回指即 error（§7-8）。
> **两维优先级**：`importance` × `urgency`（单维表达不了「重要但不急」）；二者正是库列 `importance` / `urgency` 的来源（[`差异对照.md`](../examples/alm/差异对照.md) D4）。
> **非功能意图**：正文**不写数值阈值**，只声明目标；阈值住 Profile `quality.targets`（[`requirements.md`](../requirements.md) §0）。

### 2.3 正文：`why` 分条 / `what` 一条

```sql
why {
    "计划员在 400+ 待排单据里逐页翻找，平均 6 分钟才定位一张；",
    "漏排直接造成停机，单次停线损失远高于筛选功能的成本。",
}
what {
    "计划员能按状态把生产订单列表收敛到自己关心的那一批。",
}
```

| | `why` | `what` |
| --- | --- | --- |
| **条数** | **1–5 条**（✔ 2026-09-29 裁） | **恰好 1 条**（✔ 2026-09-29 裁） |
| 回答 | 为什么做：谁的问题、代价、不做的后果 | 做成什么样：**一个可观察的结果** |
| 判据 | 通篇不出现解决方案 | **这一条能被至少一条 UAT 断言判定** |

**为什么 `what` 恰好一条**：`what` = **这条 intent 要做成的那一件事**。一旦要写第二条，说明那是**两个结果** ⇒ 它们本来就是**两个 intent**（或 1 intent + 2 usecase）——**条数不是容量，是粒度信号：`what` 超过 1 条 = 该拆 intent**。
**为什么 `why` 仍分条（1–5 条）**：理由是**枚举**（成本 / 风险 / 合规 / 体验 / 不改的后果），彼此并列、不各自挂断言；分条换来**逐条砍**（Kano `ATTRACTIVE` 整条砍掉、diff 干净）与**按条签字**。
**why 与 what 不拆成两个阶段、两个文件**（[`requirements.md`](../requirements.md) §0 作者口径）——它们是**同一条 intent 的两个必填面**。
**落库就落这两列**（✔ 2026-09-29 补裁）：MetaIntent.why / MetaIntent.what 各一列 `text`，**列内一条一行**（`why` 行数 = 分条数；`what` 恒为 1 行）——**不建子表**，理由与代价见 [intent-store.md](intent-store.md) §3。

#### 2.3.1 条数与长度上限（✔ 2026-09-29 已裁）

作者提问（原话）：「**why / what 写多条？有利有弊，多条说明分解的不够细，容易混在一起。写单条可能会变回大段文本，回到 Word 文档的老样子**」——**两头都怕**。✔ **裁决：把「条数」从容量问题变成粒度信号，用「长度」堵住另一头。**

| 项 | 规则 | 等级 |
| --- | --- | --- |
| **`what` 条数** | **恰好 1 条**（✔ 2026-09-29 裁：只能 1 条） | error |
| **`why` 条数** | **1–5 条**（✔ 2026-09-29 裁：最多 5 条） | ≥ 6 条 error |
| **单条长度** | **一句话、≤ 255 字符**（中文按字符计）——防「单条膨胀成大段」 | error（✔ 2026-09-29 裁） |
| **反向判据** | `what` 只有 1 条却挂了 **≥ 3 条 UAT** ⇒ 它在偷偷装多个结果，该拆 | warning |

**超限的提示是「该拆 intent / 该拆句」，不是放宽阈值**：
- `what` 要写第二条 ⇒ 那是**第二个结果** ⇒ 拆成第二条 intent（USER 层，`parent` 回指同一个 BUSINESS）；这也是 `what` = 1 条的直接理由（§2.3）；
- `why` 要写第六条 ⇒ 要么这条 intent 太大，要么理由在重复；
- 单条超 255 字符 ⇒ 先拆句；拆不动 ⇒ 它其实是两条理由 / 两个结果。

**为什么 `why` 比 `what` 宽**：`what` 是**结果**——唯一，且要挂 UAT 断言；`why` 是**理由枚举**——成本 / 风险 / 合规 / 体验 / 不改的后果各占一条，并列且不挂断言，5 条够用。
**阈值可调**：登记在 §9-11（改数只改这一处，机制不动）。

---

## 3. 不写 How：机械判据

意图掺 How 就与建模形成两份真源，改建模会漏掉意图，追溯立刻失效。三条机检：

| # | 判据 | 等级 |
| --- | --- | --- |
| 1 | **引用封闭**：intent 体内只允许同层引用（`parent` / `depends` → `INT-…`）；出现指向建模物 / usecase / UAT 的引用 ⇒ error | error |
| 2 | **词法黑名单**：`why` / `what` 文本里出现实现性记号（`record` `table` `varchar` `REST` `GET` `/api/`，以及已知字段名 / 文件路径）⇒ error | error |
| 3 | **粒度**：**`what` 恰好 1 条**、`why` 1–5 条、单条 ≤ 255 字符（§2.3.1，✔ 2026-09-29）；一条里出现多个互不依赖的验收点 ⇒ **该拆 intent** | error |

> 判据 2 依赖一份**黑名单词表**；✔ **2026-09-28 裁定：暂时不考虑**（§9-6）⇒ 现阶段由**判据 1（引用封闭）+ 判据 3（粒度）**兜住，掺 How 的文本靠评审与「新增词表即升级为机检」补齐。

---

## 4. 衔接：intent → usecase → 建模 → 用例（**单向回指**）

```
BUSINESS intent（宏观业务目标）
   ▲ parent（拆解回指）
USER intent（必须声明 role）
   ▲ :（细化回指）                    ▲ req:（UAT 挂 intent）
usecase  ── satisfies ──▶ 建模声明点（S2，功能需求的真正承载者）
（S1 细化 / UML 可图形化）      record · field · action · stm · view · api
```

| 边 | 写在哪 | 语法 | 例 |
| --- | --- | --- | --- |
| BUSINESS → USER | **USER 侧** | `parent INT-…` | `INT-000123 → parent INT-000100` |
| USER → usecase | **usecase 侧** | `usecase UC-… : INT-…` | [`UC-000045.m`](../examples/alm/UC-000045.m) |
| usecase / intent → 建模 | **建模侧** | **`satisfies UC-…` 与 `satisfies INT-…` 都允许**（✔ 2026-09-28）——一条声明点**至少一处回指**（就近优先回指 usecase，跳过 usecase 时直接回指 intent） | `record ProductionOrder { … satisfies UC-000045 }` |
| intent → 验收 | **UAT 侧** | `req: INT-…`（必写）+ `covers: UC-…`（可选） | [`testing.md`](../testing.md) §9.1 已裁 |
| 反向（意图 → 全部下游） | **内核索引**，不写声明 | `mmda trace INT-…` | 覆盖门禁 / `mmda diff --impact` / AI 取上下文 |

**内核维护的正向索引**：

```
INT-000100 ─▶ INT-000123 ─▶ UC-000045 ─▶ ProductionOrder.status / UISalesOrderList.filter
                                       └─▶ UAT 用例（req: INT-000123）
```

**三个消费方**：① `mmda diff --impact`（改声明点 ⇒ 命中用例 ⇒ 命中意图 ⇒ 带出回归用例集与变更级别 L0–L3）；② 覆盖门禁（§7）；③ AI 取上下文（`spec` + 命中的 `why/what` + 该意图的 UAT + `Profile`，按索引反查、token 可控）。

### 4.1 usecase 的三个面

| 面 | 通道 | 说明 |
| --- | --- | --- |
| **描述** | m 语言声明（`usecase`，partType） | 触发者 `actor` / 前置 `pre` / 主场景 `main` / 备选 `alt` / 结果 `outcome`；**仍不含 How** |
| **图形化** | **UML 投影** | 图形是**投影**（[`ide/graph-files.md`](../ide/graph-files.md)）：布局住 `{UC}.g`，图形类型 = **UML 用例图 / 活动图**；适配器已登记 = `mmda.designer.muc-uml` / `graphKind: muc-uml`（[`ide/diagram-adapters.md`](../ide/diagram-adapters.md) §7） |
| **验证** | UAT | **UAT 挂在 intent 上**（`req: INT-…`）；UAT 可选 `covers: UC-…` 指到具体用例场景，从而用例也被覆盖 |

---

## 5. 编号

| 项 | 口径 |
| --- | --- |
| 形态 | `INT-<NNN>`（intent）/ `UC-<NNN>`（usecase）——**纯序号，不含模块段** |
| 签发 | **内核生成，人不手写、AI 不编**；单调、不复用、不重排 |
| 不进编号 | 层次 / 优先级 / 标题 / 模块（**会变的东西不进主键**） |
| 为什么去掉模块段 | intent 签发时**模块树还不存在**（§0 推论 2）；模块归属由 S2 侧 `satisfies` 回指得出；**不做「迁模块即换号」**（会断追溯链） |

---

## 6. 与测试的关联（可验证）

✔ **已裁（2026-09-28）**：**UAT 挂在 intent 上**（不挂在 usecase 上）——「意图基线 = intent + 可执行 UAT」这条口径不变；usecase 是细化的中间层，UAT 用可选的 `covers: UC-…` 把用例一并覆盖。

| 规则 | 等级 |
| --- | --- |
| 每条 **USER** intent 必须有 **≥1 条 UAT** 用 `req: INT-…` 回指 | **error** |
| UAT 用 `req:` / `covers:` 可追溯；无法追溯的用例标 orphan、不计覆盖率 | error / warning（[`testing.md`](../testing.md) §1） |
| `kind: uat` 的用例 `reviewedBy` 非空 | error（[`testing.md`](../testing.md) §9.1） |
| UAT **需求完成即出**、随**意图基线**冻结 | 流程门禁（[`testing.md`](../testing.md) §0.1） |
| 追溯链 `BUSINESS → USER → UC → 声明点 → 生成物 → 运行指标 → 缺陷 → 回归用例` | 覆盖报告（[`quality.md`](../quality.md) §5） |

---

## 7. 门禁汇总（按层分档）

| # | 检查 | 适用层 | 等级 |
| --- | --- | --- | --- |
| 1 | `layer` 必填且取值合法（`BUSINESS` / `USER`） | 全部 | error |
| 2 | `subject` 必填（S1 分组轴；S2 由它细化为 System / Module） | 全部 | error |
| 3 | `why` **1–5 条**、`what` **恰好 1 条**、两者均非空 | 全部 | error |
| 4 | **必须声明 `role`**，且 role 是已声明的角色 | **USER** | error |
| 5 | **至少一条 `usecase` 细化本 intent**（`… : INT-…`） | **USER** | error |
| 6 | **至少一条 UAT 用 `req:` 回指本 intent** | **USER** | error |
| 7 | **至少一条 USER intent 以 `parent` 细化本 intent** | **BUSINESS** | error（否则宏观目标没有落点） |
| 8 | **不得直接挂 `usecase`**（细化必须逐层 `BUSINESS → USER → usecase`） | **BUSINESS** | error |
| 9 | `parent` / `depends` 无环 | 全部 | error |
| 10 | 正文无实现性记号（§3 判据 1 / 3；判据 2 的词表**暂缓**，见 §9-6） | 全部 | error |
| 11 | 反向 orphan：无任何意图支撑的建模声明点 | — | warning（白名单可豁免技术性实现） |
| 12 | 「层号 = 归属节点层级」：由 S2 侧 `satisfies` 回指算出（BUSINESS → System / Module；USER → Module / Feature） | — | error |
| 13 | **条数 / 长度**：**`what` = 1 条**、**`why` ≤ 5 条**（✔ 2026-09-29 裁）、单条 ≤ 255 字符（✔ 2026-09-29 裁）；超限的提示是**该拆 intent / 该拆句**，不是放宽阈值（§2.3.1） | 全部 | error |

---

## 8. 与「需求层次」的对应（业务 / 用户 / 功能）

| 需求层次 | 产物 | 说明 |
| --- | --- | --- |
| **业务需求** | `intent`（`layer BUSINESS`） | 较宏观的业务目标；回答「为谁解决什么问题」 |
| **用户需求** | `intent`（`layer USER`）+ **`usecase`** 细化 | 一条 = 一个关键用户的一个可观察结果；必须声明 `role` |
| **功能需求** | **不进 intent**：由 S2 **建模声明点**承载（字段 / 约束 / Action / 状态迁移 / 页面 / 接口），经 `satisfies` 回指到 usecase 与 intent | 在「intent 最先」的前提下，功能层已是 How 的形状 ⇒ 归建模 |

> 这张表取代 [`requirements.md`](../requirements.md) §2.1 的「三层需求 ↔ 模块三级」1:1 倾向：**需求侧两档 + 建模侧承载功能层**。

---

## 9. 议题台账（10 项：9 已裁 + 1 缓议）

| # | 议题 | 状态 / 建议 |
| --- | --- | --- |
| 1 | ~~`layer` 是否保留第三档 `FUNCTIONAL`~~ | ✔ **已裁（2026-09-28）**：只留 `BUSINESS` / `USER`；功能需求由建模声明点承载 |
| 2 | ~~UAT 挂 intent 还是 usecase~~ | ✔ **已裁（2026-09-28）**：**挂 intent**；usecase 用 `covers:` 可选覆盖 |
| 3 | ~~`area` 是否需要~~ | ✔ **已裁（2026-09-28）**：**要**，关键字为 **`subject`**（SERU 的 Subject Area），且**必填**；S2 由它细化为 System / Module |
| 4 | ~~BUSINESS 能否直接挂 usecase~~ | ✔ **已裁（2026-09-28）**：**不允许**——宏观目标必须先拆成 `USER` 意图（逐层细化，§7-8） |
| 5 | ~~多行字面量与 `why` / `what` 形态~~ | ✔ **已裁（2026-09-28）**：**暂时不要多行字面量**——`why` / `what` 用短句列表 + `"…"`，一条一句、行末逗号；长文本需求（评审体验）待将来另议 |
| 6 | **How 黑名单词表** | ⏸ **2026-09-28 裁定：暂时不考虑**（先靠引用封闭 + 粒度两条机检 + 评审兜住；词表可后补并随即升级为机检） |
| 7 | ~~建模侧回指关键字~~ | ✔ **已裁（2026-09-28）**：**`satisfies UC-…` 与 `satisfies INT-…` 都允许**；一条声明点**至少一处回指**（§4） |
| 8 | ~~usecase 的 UML 图形适配器条目~~ | ✔ **已裁（2026-09-28）**：图形类型 = UML 用例图 / 活动图；布局文件 `{UC}.g`；适配器 `mmda.designer.muc-uml` 已进 [`ide/diagram-adapters.md`](../ide/diagram-adapters.md) §7 |
| 9 | ~~`requirements.md` 的回改范围~~ | ✔ **已办（2026-09-28）**：§0 / §2 / §2.1 / §2.2 / §5 / §7 已按本篇回改（`requirement` → `intent`、三层收两档、`REQ-` → `INT-`） |
| 10 | ~~意图进库的落点（元对象 vs 业务表）~~ | ✔ **已裁（2026-09-28）**：走**元对象路线**——落内核 `Meta*` 族（拟 `MetaIntent` + 关联表），**不落** `mmda_alm.requirement` 业务表（**⤴ 四轮：该库仅参考、将废除，「投影 / 缓存」也随之取消**）；解 [`examples/alm/差异对照.md`](../examples/alm/差异对照.md) **D0 = A**；**表结构设计 = [`intent-store.md`](intent-store.md)（草案；§8 命名 / 审计两项已裁 · 2026-09-28，正文口径 **2026-09-29 改裁为双列**）** |
| 11 | ~~`why` / `what` 的条数与长度上限~~ | ✔ **已裁（2026-09-29）**：**`what` 恰好 1 条**、**`why` 1–5 条**；**条数 = 粒度信号，超限即「该拆 intent」**；**单条 ≤ 255 字符**（✔ 2026-09-29 裁）。见 §2.3 / §2.3.1 / §3 判据 3 / §7-3 / §7-13 |

---

## 相关

- 示例：[`examples/alm/README.md`](../examples/alm/README.md) · [`INT-000100.m`](../examples/alm/INT-000100.m)（BUSINESS）· [`INT-000123.m`](../examples/alm/INT-000123.m)（USER）· [`UC-000045.m`](../examples/alm/UC-000045.m)（usecase）
- 库侧差异：[`examples/alm/差异对照.md`](../examples/alm/差异对照.md)（D0–D16 + L1–L11）· 旧写法旁证：[`examples/alm/app-model/`](../examples/alm/app-model/)（**不是需求的写法**，仅作对照）
- [`requirements.md`](../requirements.md) — 需求工程（**已按本篇回改**）· [`project.md`](project.md) — 首关键字清单、`intents/` 目录、四阶段 · [`testing.md`](../testing.md) — UAT 与追溯链
- [`ide/diagram-adapters.md`](../ide/diagram-adapters.md) §7 — usecase 的 UML 图形适配器（`muc-uml`）· [`ide/graph-files.md`](../ide/graph-files.md) — `{UC}.g` 布局投影
- [`intent-store.md`](intent-store.md) — **意图落库（`MetaIntent` 元对象表族）**：列 ↔ 语言子句逐条对、**正文双列**（`why` / `what`，不建子表）、关联表形态、~~与 `mmda_alm.requirement` 的投影映射~~（**⤴ 四轮废除**，降为参考对照）、表级门禁（D0 = A 的落地篇；三项均已裁：命名取 `Meta*` Pascal 族（`MetaIntent`）、审计与状态不进（2026-09-28）；正文 **⤴ 2026-09-29 改裁为双列**（不建子表））
