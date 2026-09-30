# 意图落库：`MetaIntent`（元对象存储）

> **为什么有这篇**：[`intent.md`](intent.md) 定下「**intent 是最先的产物**」与「**意图是元语言要素**」（与 `record` / `enum` / `stm` / `role` 同级）；✔ **2026-09-28 裁定「意图进库 = 元对象路线」（解 [`examples/alm/差异对照.md`](../examples/alm/差异对照.md) D0 = A）**——落内核 `Meta*` 族（**⤴ 2026-09-29 四轮：`mmda_alm` 仅参考、将废除，不再投影**）。本篇把**语言子句逐条推成表结构**，让「进语言 → 进库 → 进 IDE」三面同源。
> **取材**：[`intent.md`](intent.md) §1 / §2 / §4 / §5 / §6 的子句 + 库侧实测 DDL（**仅参考、非投影目标**；`mmda_alm`，本机 `127.0.0.1:3306`，29 列）+ legacy 元库表（[`legacy/java-factory.md`](../legacy/java-factory.md) §Legacy 元库表映射）。
> **三条不变量**（后面所有表的判据都从这里来）：
> ① **文件是真源、库是产物**（[`../../PLAN.md`](../../PLAN.md) §0 A4、[`project.md`](project.md) §0）——库里的意图行**可以整表删掉、由 `.m` 重建**；
> ② **库不引入语言面没有的概念**——每一列都能指回一条子句，指不回去的列不进元对象；
> ③ **值域存语言里的符号名**（`BUSINESS`、`IMPORTANT`、`NORMAL`…），**不存 tinyint 序号**——序号是实现细节，收口库侧不一致 **L7 / L8**。
> **✔ 裁定（见 §8）**：**命名取 B** ⇒ `MetaIntent`（Pascal，同 legacy `MetaObject` 族，**全局统一 `Meta*`**）· **审计 7 件套 / `status` / `moduleCode` 一律不进元对象**（2026-09-28）· **正文取双列** ⇒ `why` / `what` 各一列落主表，**不建子表**（**⤴ 2026-09-29 改裁**，取代 2026-09-28 的「行子表」）。
> 状态：**草案（2026-09-28 立；同日命名 / 审计两项已裁、正文口径 2026-09-29 改裁为双列，见 §8）**。**⤴ 2026-09-29 四轮：应用侧投影层（`mmda_alm`）废除，本篇只规范内核 `MetaIntent` 族。**
> 联动：[`intent.md`](intent.md)（**语言面唯一规范**）· [`../requirements.md`](../requirements.md) §2.2 · [`../testing.md`](../testing.md) §9.1（`MetaTest` 族）· [`../legacy/java-factory.md`](../legacy/java-factory.md) · [`../examples/alm/差异对照.md`](../examples/alm/差异对照.md)（D0–D16 / L1–L11）。

---

## 0. 定位：两层同源（文件真源 → 内核元对象）

```text
intents/*.m ──(mmda build)──▶ MetaIntent 表族        （mmda_alm.requirement —— 仅参考，将废除）
   ▲ 真源                          ▲ 内核元存储（唯一落库面）        ✗ 不再是投影目标
   git 版本控制                    mmda check 的意图门禁落点
```

| 面 | 角色 | 说明 |
| --- | --- | --- |
| `.m` 文件 | **真源** | 唯一可写面；进 git，走 [`workflows.md`](../workflows.md) §12 的审签 |
| `Meta*` 表 | **产物** | 由文件构建；`mmda check` 的意图门禁、`mmda trace INT-…` 的反向索引都建在这里 |
| ~~`mmda_alm.requirement`~~ | **仅参考（将废除）** | 旧 ALM 应用的业务表（含排程、状态、审计 7 件套）；**⤴ 2026-09-29 四轮：不再投影、不是真源**——构建产物只有上一层 |

> **为什么元对象与「某个应用的扩展列」要分开**（⤴ 四轮改写）：D14 的排程字段（`manDays` / `expected*` / `actual*`）与 D5 的状态机是 **ALM 应用的业务数据**，进元对象会把「语言要素」与「某个应用的业务字段」绑死；分清后 `MetaIntent` 跨项目通用——**这份扩展列随 `mmda_alm` 废除，理由仍然成立**（下一个个应用照样有自己的列）。
> **为什么只有一张主表**：一个 intent 就描述**一个 `what` 与一个 `why`**——`why` / `what` 是**这一行自己的两个值**，不是有独立身份、会被别处引用的实体 ⇒ 建成子表只是凭空多一次 join、多一组 FK 与级联（详见 §3）。

---

## 1. 命名（✔ 2026-09-28 裁 B：`Meta*` Pascal 族）

| 对象 | 名称 | 依据 |
| --- | --- | --- |
| 主表 | **`MetaIntent`** | ✔ 裁 B——同 legacy 元库族（`MetaObject` / `MetaCol` / `MetaRelation` / `MetaEnum`） |
| 关联表 | **`MetaIntentDependency`** / **`MetaIntentTag`** | 同族；见 §4 |
| 用例表 | **`MetaUseCase`** | 同族；见 §5 |
| 列 | `camelCase` | 同 [`naming.md`](../naming.md) §3.3 的列口径（`intentNo` / `parentIntentID`…） |
| 主键 | `PK_MetaIntent` | 建议前缀，[`naming.md`](../naming.md) §3.3 |
| 唯一约束 | `UQ_MetaIntent_intentNo` | 同上 |
| 外键 | `FK_MetaIntent_parent` / `FK_MetaIntent_role` | `FK_<本表>_<被引>`，同上 |
| 索引 | `IDX_MetaIntent_subject` 等 | `IDX_<表>_<列…>`，同上 |

**为什么取 B（Pascal）而不是 `meta_*` 小写前缀**：

- legacy 元库（`mmda_metadata`）就是 **Pascal 前缀族**（`MetaObject` / `MetaCol` / `MetaRelation` / `MetaEnum`，[`legacy/java-factory.md`](../legacy/java-factory.md)）⇒ 取 B 是**沿用既有族名**，不新造命名体系；
- 与 [`naming.md`](../naming.md) §3.3「**表 = 模型名 PascalCase、列 = 属性名 camelCase**」**同形**——内核元库**不再例外**，`MetaIntent` 与 `intentID` / `intentNo` 的关系和应用表完全一致（`MetaObject` ↔ `objectId` 同理）；
- 前缀全大写 + 前缀后照抄模型名（`Meta` + `Intent`）——与 `IDX_` / `FK_` 前缀的写法同一规则。

**全局统一（本条裁定的连带）**：[`../testing.md`](../testing.md) §9.1 原来写的 `meta_test` / `meta_test_suite` / `meta_test_run` **同步改名**为 **`MetaTest` / `MetaTestSuite` / `MetaTestRun`**——元库命名只有一套。

**方言与引号（取 B 后这条从「建议」变成「必须」）**：表名含大写 ⇒ **必须**由 `Dialect` 加引号（[`naming.md`](../naming.md) §3.3 前置条件 1），且 **MySQL 必须 `lower_case_table_names=0`**（前置条件 2；Windows 默认 1 会把 `MetaIntent` 折成 `metaintent`）——`meta_intent` 那种全小写写法原本免疫，取 B 后**这条前置条件照旧适用、不能省**。列名 `intentNo` / `parentIntentID` 的大小写敏感与前置条件 4（ORM 关掉 `camelCase → snake_case` 转换）**一并适用**。

---

## 2. 主表 `MetaIntent`

### 2.1 列清单（每一列都指回一条语言子句）

| 列 | 类型 | 来源子句 | 约束 |
| --- | --- | --- | --- |
| `intentID` | `bigint` | — | **PK**，代理键（内核生成，**不含语义**） |
| `intentNo` | `varchar(16)` | [`intent.md`](intent.md) §5 | **NOT NULL + UNIQUE**（`INT-<NNN>`；解 D6 / 补 L3） |
| `layer` | `varchar(16)` | §2.1 | **NOT NULL**；`BUSINESS` 或 `USER` |
| `subject` | `varchar(64)` | §2.2 `subject` | **NOT NULL**（S1 分组轴；S2 细化为 System / Module） |
| `roleCode` | `varchar(64)` | §2.2 `role` | NULL，但 **`layer='USER'` 时 NOT NULL**；REF `Role.roleCode`（[`meta-model.md`](meta-model.md) §8.1） |
| `kanoType` | `varchar(16)` | §2.2 `type` | NULL；`BASIC` / `DESIRED` / `ATTRACTIVE` / `INDIFFERENT` / `UNDESIRED` |
| `importance` | `varchar(20)` | §2.2 `importance` | NULL；`UNKNOWN` / `IMPORTANT` / `VERY_IMPORTANT` |
| `urgency` | `varchar(20)` | §2.2 `urgency` | NULL；`NORMAL` / `SENIOR` / `URGENT` |
| `parentIntentID` | `bigint` | §2.2 `parent` | NULL；**自引用** REF `MetaIntent`；**只允许 BUSINESS ← USER**（层校验在服务层，见 §7） |
| `label` | `varchar(255)` | `/// <label> : …`（[`records.md`](records.md) §6） | NULL；显示标签 |
| **`why`** | **`text`** | §2.3 `why` 块 | **NOT NULL**；**列内一行 = 语言面的一个分条**，**1–5 行**（§3） |
| **`what`** | **`text`** | §2.3 `what` 块 | **NOT NULL**；**恰好 1 行**（✔ 2026-09-29：`what` 只能 1 条） |
| `revision` | `int` | §5 / D15 | **NOT NULL DEFAULT 0**；单调递增 |

**不进主表的列（每条都对应一条已裁裁定）**：

| 不进的列 | 理由 | 落点 |
| --- | --- | --- |
| `moduleCode` / `requirementmodule` | 归属由 **S2 侧 `satisfies` 回指**算出，不存 ⇒ 避免两处真源（D3）；✔ 2026-09-28 裁「不进」 | 建模侧 / 内核索引 |
| `status` | 状态与迁移是 **`stm` 的领域**（D5）；语言面**没有状态子句**；✔ 裁「不进」 | ALM 投影侧自留 |
| `deptID` / `creatorID` / `createDate` / `lastModifierID` / `lastModified` / `ownerID` / `ownerDeptID` | 审计 7 件套是**应用业务数据**（D13），且**文件侧由 git 承载**；✔ 裁「不进」，元对象只留 `revision` | ALM 投影侧 / git |
| `manDays` / `expectedStart` / `expectedFinish` / `expectedPeriod` / `taskColor` / `constraintType` / `constraintDate` / `actualStart` / `actualFinish` / `actualPeriod` | 排程 / 计划（D14）：更像 `mmda_pm` 域，**确认不进意图元对象** | ALM / PM 应用侧 |
| 独立的 `why` / `what` 表 | **✔ 2026-09-29 改裁**：一个 intent 就一个 `why` / 一个 `what` ⇒ 落**两列**，不建子表（§3） | — |
| `requirementType` 的 tinyint 序号 | 值域存符号名（不变量 ③）⇒ 改名 `kanoType` | — |
| `requirementTitle` / `requirementDesc` 的 `NOT NULL` | 正文由 **`why` / `what` 两列**承载（§3） | — |

### 2.2 DDL 骨架（MySQL 方言示意，**未定稿**）

```sql
CREATE TABLE `MetaIntent` (
  `intentID`       BIGINT       NOT NULL,
  `intentNo`       VARCHAR(16)  NOT NULL,
  `layer`          VARCHAR(16)  NOT NULL,
  `subject`        VARCHAR(64)  NOT NULL,
  `roleCode`       VARCHAR(64)  NULL,
  `kanoType`       VARCHAR(16)  NULL,
  `importance`     VARCHAR(20)  NULL,
  `urgency`        VARCHAR(20)  NULL,
  `parentIntentID` BIGINT       NULL,
  `label`          VARCHAR(255) NULL,
  `why`            TEXT         NOT NULL,
  `what`           TEXT         NOT NULL,
  `revision`       INT          NOT NULL DEFAULT 0,
  CONSTRAINT `PK_MetaIntent`          PRIMARY KEY (`intentID`),
  CONSTRAINT `UQ_MetaIntent_intentNo` UNIQUE (`intentNo`),
  CONSTRAINT `FK_MetaIntent_parent`   FOREIGN KEY (`parentIntentID`) REFERENCES `MetaIntent` (`intentID`),
  CONSTRAINT `FK_MetaIntent_role`     FOREIGN KEY (`roleCode`)       REFERENCES `Role` (`roleCode`),
  CONSTRAINT `CK_MetaIntent_layer`    CHECK (`layer` IN ('BUSINESS','USER')),
  CONSTRAINT `CK_MetaIntent_role`     CHECK (`layer` <> 'USER' OR `roleCode` IS NOT NULL)
);
CREATE INDEX `IDX_MetaIntent_subject` ON `MetaIntent` (`subject`);
```

> **CHECK 表达不了的两条**（⇒ 服务层 / `mmda check`，§7）：① `parentIntentID` 指向的行必须是 `layer='BUSINESS'`；② 同层 `depends` 环检测。

---

## 3. 正文：`why` / `what` 落两列（✔ 2026-09-29 改裁：不建子表）

> **⤴ 改裁**：2026-09-28 曾拟「行子表」（`MetaIntentWhy` / `MetaIntentWhat`）；**2026-09-29 作者裁定：不要子表——一个 intent 就描述一个 `what` / 一个 `why`**。两列落主表，子表作废。

| | |
| --- | --- |
| **形态** | `MetaIntent.why` / `MetaIntent.what`，各 `text`、**NOT NULL** |
| **与语言面 `{ … }` 块的关系** | 语言面的 `why { "a", "b" }` **仍是分条列表**（[`intent.md`](intent.md) §2.3 的四条理由不变）；落库时**一条一行**写进同一列（`\n` 分隔）⇒ 正文的**行数 = 分条数**，`mmda check` 按行判定「非空、≥1 条」；**行数受条数上限约束**（**`what` 恰好 1 行** / **`why` 1–5 行**、单条 ≤ 255 字符——[`intent.md`](intent.md) §2.3.1，✔ 2026-09-29） |
| **为什么不要子表** | 子表的语义是「有独立身份、可被别处引用、需 FK / 级联」；而 `why` / `what` **只属于这一行**、不被任何别处引用 ⇒ 建子表只剩代价（多一次 join、多一组 PK/FK、多两张表的迁移与权限） |
| **代价（写清）** | ① **行级独立检索变弱**——SQL 里按「某一条 `what`」过滤要额外拆行（`mmda` 侧在索引里拆，不靠 SQL）；② 列内换行是**约定**不是约束 ⇒ 值里若混入多余空行，表现为「多一条分条」，由 `mmda check`（去空行）兜住 |

**列型为什么不窄化**：单条上限 **255 字符**（✔ 2026-09-29 裁，[`intent.md`](intent.md) §2.3.1）正好是 `varchar(255)` 的量级——`what` 恒 1 行 ⇒ 窄化成 `varchar(255)` 也够；但**上限由 `mmda check` 判、不由列型判**（列型只兜底，写进库不等于合规），且 `why` 1–5 行要更长 ⇒ 两列一律留 **`text`**，不为 2 列斤斤计较。
**备选（未采纳，留档）**：`whyJson` / `whatJson` JSON 数组列——机器可读更规整，但把正文塞进 JSON 会让「按行判定」与 DB 端直读都变绕；`whyText` 逗号串则回到「一段话」，不表。

---

## 4. 关联表：依赖 / 标签

| 表 | 列 | 来源 | 说明 |
| --- | --- | --- | --- |
| **`MetaIntentDependency`** | `intentID` + `preIntentID`（复合 PK） | §2.2 `depends` | 自引用 M:N（收 D10）；环检测在服务层 |
| **`MetaIntentTag`** | `intentID` + `tagName` | §2.2 `tag` | 若标签做成**跨对象通用能力**（D12 待裁）⇒ 与通用 `Tag` 表统一，否则只在本表内 |

> **为什么这两张是表、`why` / `what` 不是**：`depends` 是 **intent ↔ intent 的边**（多对多、需被反查），标签要按 `tagName` 做集合查询——它们**天然需要索引与 join**；`why` / `what` 是**单行自带的两个文本值**，没有任何跨行查询需求（§3）。**判据 = 有没有独立的查询身份**。
> **`parent` 与 `depends` 的分工**：`parent` = **拆解**（BUSINESS ← USER，层级边，落 `parentIntentID` 列）；`depends` = **前置依赖**（同层排序，排程与「前置意图未完成」守卫用）——**两种边**：层级边是一列，依赖边是一张表。

---

## 5. `usecase`（`UC-…`）落表：`MetaUseCase`

`usecase` 是**与 `intent` 平级的 partType**（[`intent.md`](intent.md) §4.1），因此**不塞进 `MetaIntent`**，自己一张表：

| 列 | 说明 |
| --- | --- |
| `usecaseID` / `usecaseNo` | PK / `UC-<NNN>` UNIQUE |
| `intentID` | **细化回指**（`usecase UC-… : INT-…`）⇒ 让 §7-5「每条 USER intent ≥1 usecase 细化」成为**一条 join** |
| `actorCode` | `actor` 子句（REF `Role`） |
| `pre` / `outcome` | 前置 / 结果（**列**，口径同 §3；`pre` 若在语言面是多条，按「一条一行」落一列） |
| `label` / `revision` | 同 §2.1 |

场景步骤（`main` / `alt`）与 UML 布局 `{UC}.g` **不在本文范围**，待 `usecase` 语言面单独立篇。

---

## 6. 附：与 `mmda_alm.requirement` 的对照（**仅参考，不再投影**）

> **⤴ 2026-09-29 四轮**：`mmda_alm` 仅作参考、将来废除，**本节不是投影规范**。逐列对照只用于**看懂旧库现状 / 评估迁移**；「处置」列是**若真要迁移**的动作，**不进 `mmda check` 门禁**。

| `mmda_alm.requirement` 列 | 处置 | 映射 / 理由 |
| --- | --- | --- |
| `requirementID` | **投影侧自留** | ALM 自己的代理键；与 `intentID` 的对应关系走 `requirementNo` |
| `requirementNo` | **映射** | `← intentNo`；投影侧补 **UNIQUE**（收 L3） |
| `requirementTitle` | **映射（待裁 D9）** | `← label`（D9 若裁 A，正文也进载荷） |
| `requirementDesc` | **映射（只读）** | `← why` + `what` 两列合并渲染（**投影是给人看的，不是回写真源**） |
| `requirementType` | **映射** | `← kanoType`（符号名 ↔ 序号由投影层转；库侧序号不再是真源） |
| `importance` / `urgency` | **映射** | 同名 |
| `parentRequirementID` | **映射** | `← parentIntentID` |
| `status` | **ALM 自留** | D5：状态归 `stm`；ALM 的应用状态**不回写**元对象 |
| `tags` | **映射** | `← MetaIntentTag`；库侧逗号串与 `Tag` 表的**两份真源**（D12）在投影层收敛为一份 |
| `revision` | **映射** | 同名 |
| `moduleCode` / `requirementmodule` | **ALM 自留（只读）** | D3：归属由建模侧 `satisfies` 算出后**下推**到投影，不回写 |
| `manDays` / `expected*` / `actual*` / `taskColor` / `constraint*` | **ALM 自留** | D14：排程 / 计划，不进意图元对象 |
| 审计 7 件套 | **ALM 自留** | D13：应用业务数据（元对象只留 `revision`，文件侧由 git 承载） |

**连带收口的库侧不一致**（**仅参考**，随 `mmda_alm` 废除而失效；保留以备将来迁移）：L3（补 unique）、L4（字符集——重建时统一 `utf8mb4`）、L5（`status` 补 `NOT NULL`）、L7 / L8（符号名取代序号）、L9（补外键）、L11（分区段随元对象定）。

---

## 7. 门禁（表级 ↔ [`intent.md`](intent.md) §7 逐条对应）

| # | 检查 | 落点 | 等级 |
| --- | --- | --- | --- |
| 1 | `layer` 取值合法（CHECK） | 表级 | error |
| 2 | `subject` 非空（NOT NULL） | 表级 | error |
| 3 | `why` **1–5 行**、`what` **恰好 1 行**、两列均非空（NOT NULL + 去空行后计数） | 表级 + 查询 | error |
| 4 | USER ⇒ `roleCode` 非空（CHECK）+ role 存在（FK） | 表级 | error |
| 5 | 每条 USER intent ≥ 1 usecase 细化（§5 `intentID` join） | 查询 | error |
| 6 | 每条 USER intent ≥ 1 UAT 回指（[`../testing.md`](../testing.md) §9.1 的 `MetaTest.reqIntentNo`） | 查询 | error |
| 7 | 每条 BUSINESS ≥ 1 条 USER 以 `parent` 细化 | 查询 | error |
| 8 | BUSINESS 不得挂 usecase（`layer='BUSINESS'` 且被 usecase 引用 ⇒ error） | 查询 | error |
| 9 | `parent` / `depends` 无环 | 服务层 | error |
| 10 | 正文无实现性记号（[`intent.md`](intent.md) §3 判据 1 / 3） | `mmda check` 静态面，**非表级** | error |
| 11 | 反向 orphan（无意图支撑的建模声明点） | 内核索引 | warning |
| 12 | 层号 = 归属节点层级（BUSINESS → System / Module；USER → Module / Feature） | 内核索引 | error |

> **表级只管「单行自洽」，跨行关系（层序 / 环 / 覆盖）一律走服务层**——SQL 的 CHECK 表达不了，硬塞触发器会把门禁拆到两处。

---

## 8. 裁定台账（三项 + 一次改裁）

| # | 议题 | 裁定 | 影响 |
| --- | --- | --- | --- |
| 1 | **元库命名**：`meta_intent`（snake 前缀）vs `MetaIntent`（Pascal，同 legacy `MetaObject`） | ✔ **取 B：`Meta*` Pascal 族**（2026-09-28） | 本篇全表改名；[`../testing.md`](../testing.md) §9.1 的 `meta_test` 族 → `MetaTest` / `MetaTestSuite` / `MetaTestRun`；[`../requirements.md`](../requirements.md) §2.2、[`intent.md`](intent.md) §9-10、[`../examples/alm/差异对照.md`](../examples/alm/差异对照.md)、[`naming.md`](../naming.md) §3.3 一并统一 |
| 2 | **正文落法** | ✔ **取双列**（**2026-09-29 改裁**）：`why` / `what` 各一列落主表，**不建子表**；列内**一条一行** | 取代 2026-09-28 的「行子表」（`MetaIntentWhy` / `MetaIntentWhat` 作废）；[`intent.md`](intent.md) §2.3 的分条语义**不退场**（仍是短句列表，只是落一列） |
| 3 | **审计 7 件套 / `status` / `moduleCode` 要不要进元对象** | ✔ **不进**（2026-09-28） | 三者分别是应用业务数据（D13）、状态机领域（D5）、建模侧回指（D3）；进 = 引入语言面没有的概念，破不变量 ② |
| 4 | **`why` / `what` 的条数** | ✔ **`what` 恰好 1 条、`why` 1–5 条**（2026-09-29） | 落库即 `why` 1–5 行 / `what` 恒 1 行（§3）；**条数 = 粒度信号**，超限 = 该拆 intent（[`intent.md`](intent.md) §2.3.1 / §7-3 / §7-13） |

---

## 9. 相关

- 语言面：[`intent.md`](intent.md)（**唯一规范**：`layer` / `subject` / `role` / `why` / `what` / 编号 / 门禁）
- 需求工程：[`../requirements.md`](../requirements.md) §2.2（进语言 / 进库 / 进 IDE）· §7-11（**写入口待裁**）
- 测试：[`../testing.md`](../testing.md) §9.1（`MetaTest` 族与 UAT 回指 `req: INT-…`）
- 对照与实测：[`../examples/alm/差异对照.md`](../examples/alm/差异对照.md)（D0–D16 / L1–L11）· [`../legacy/java-factory.md`](../legacy/java-factory.md)（legacy `Meta*` 元库）
- 命名：[`naming.md`](../naming.md) §3.3（表 = 模型名 PascalCase、列 = 属性名 camelCase 与前置条件）
