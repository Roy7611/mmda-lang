# ALM 意图（Intent）示例

> **回答的问题**：`intent` 怎么写、怎么经 `usecase` 细化、怎么与建模和测试衔接。
> **真源**：[`doc/lang/intent.md`](../../lang/intent.md)（**语言面，唯一规范**）· [`doc/requirements.md`](../../requirements.md) · [`doc/testing.md`](../../testing.md) · [`doc/lang/project.md`](../../lang/project.md) · [`doc/ide/graph-files.md`](../../ide/graph-files.md)。
> 本目录是**示例**，不是规范；冲突时以规范篇为准。

---

## 0. 定位：intent 最先

✔ **2026-09-28 作者裁定**：**intent 是最先产生的产物**，先于模块树、模型、用例集与一切交付物；关键字 **`intent`**；**`layer` 只保留 `BUSINESS` / `USER` 两档**（BUSINESS = 较宏观的业务目标）；**USER 层必须声明 `role`，并可经 `usecase` 细化**（m 语言描述 / UML 可图形化 / 经 UAT 验证）；**UAT 挂在 intent 上**；**`subject` 必填**（SERU 的 Subject Area，关键字由 `area` 改叫 `subject`）；**BUSINESS 不得直接挂 `usecase`**；**How 黑名单词表暂时不考虑**。

由此三条硬性推论（详见 [`doc/lang/intent.md`](../../lang/intent.md) §0）：

1. intent **不写 `feature` / `satisfiedBy` / `accept`** —— 模块树是 S2 的产物，签发意图时还不存在；
2. 编号是**纯序号 `INT-<NNN>`**（`REQ-<模块编码>-<NNN>` 已作废）；
3. 可追溯由**下游回指**实现：`parent INT-…`、`usecase … : INT-…`、建模 `satisfies UC-…`、**UAT 用例挂 `module`**（建模侧 `satisfies INT-…`，intent 经 `mmda trace INT-…` 反查；**v5 起 `req:` 作废**，见 [`../../lang/test.md`](../../lang/test.md) §0.3）。

---

## 1. 两档分层与细化链

| `layer` | 是什么 | 门禁 |
| --- | --- | --- |
| `BUSINESS` | **较宏观的业务目标**（为谁解决什么问题、不解决会怎样） | 必须被 **≥1 条 USER 意图**以 `parent` 细化；**不得直接挂 `usecase`** |
| `USER` | 关键用户的**一个可观察结果** | **必须声明 `role`**；必须 **≥1 条 `usecase`** 细化；必须 **≥1 条 UAT**（归属其 `module`，由 `mmda trace INT-…` 反查） |

**功能需求不进 intent**——字段 / 约束 / Action / 状态迁移已是 How 的形状，由 S2 **建模声明点**承载，经 `satisfies` 回指上来。

```
BUSINESS intent ──parent(拆解)──▶ USER intent ──:(细化)──▶ usecase ──satisfies──▶ 建模声明点
                              └──module(挂 module)──▶ UAT 用例（intent 经 module 反查）
```

---

## 2. BUSINESS 意图

`INT-000100.m`（宏观目标，**不写 `role`、不挂 usecase/UAT**）：

```sql
/// 生产排程可视化 : 让计划员摆脱纸质台账，排产结果实时可见
intent INT-000100 {
    layer      BUSINESS
    subject    "生产执行"
    type       BASIC
    importance VERY_IMPORTANT
    urgency    SENIOR
    tag        "排程"

    why {
        "计划排程靠纸质台账与口头传递，变更后下游不知道；",
        "排产结果不可见，导致停机与交期延误频繁发生。",
    }
    what {
        "计划员能实时看到排产结果与变更；",
        "下游车间在同一处看到与自己相关的排程。",
    }
}
```

## 3. USER 意图

`INT-000123.m`（**必须写 `role`**，用 `parent` 回指 BUSINESS 意图）：

```sql
/// 生产订单按状态筛选 : 计划员需要按状态快速定位待排产单据
intent INT-000123 {
    layer      USER
    role       Planner              // 触发者（USER 层必填）
    subject    "生产执行"
    type       DESIRED
    importance IMPORTANT
    urgency    URGENT
    tag        "订单", "筛选"

    why {
        "计划员在 400+ 待排单据里逐页翻找，平均 6 分钟才定位一张；",
        "漏排直接造成停机，单次停线损失远高于筛选功能的成本。",
    }
    what {
        "计划员能按状态把生产订单列表收敛到自己关心的那一批；",
        "一眼看到命中数量，空结果有明确提示。",
    }

    parent  INT-000100
    depends INT-000118
}
```

## 4. 用例：USER 意图的细化

`UC-000045.m` —— 用 `:` 回指它细化的 USER 意图：

```sql
usecase UC-000045 : INT-000123 {
    actor Planner                   // 必须与 intent 的 role 一致
    pre   "计划员已登录，且有权查看生产订单列表"
    main {
        "计划员打开生产订单列表；",
        "选择状态筛选条件；",
        "系统呈现该状态下的订单，并显示命中数量。",
    }
    alt "无命中" {
        "系统显示空结果提示，并保留已选的筛选条件。",
    }
    outcome "列表呈现筛选后的订单集合"
}
```

usecase 的三个面：**描述**（m 语言，本篇示例）· **图形化**（UML 用例图 / 活动图，布局住 `UC-000045.g`，图形是**投影**；适配器 `mmda.designer.muc-uml` / `graphKind: muc-uml`，见 [`doc/ide/diagram-adapters.md`](../../ide/diagram-adapters.md) §7）· **验证**（UAT 用例挂 `module` / `feature`，经 `module` 的 `satisfies` 反查到 intent；**v5 起 `covers:` 作废**）。

---

## 5. 本目录文件

| 文件 | 内容 |
| --- | --- |
| `INT-000100.m` | **BUSINESS 意图**（宏观业务目标） |
| `INT-000123.m` | **USER 意图**（含 `role`，`parent` 回指 BUSINESS） |
| `UC-000045.m` | **用例**：USER 意图的细化，`:` 回指 intent |
| `TC-000045.m` | **UAT 用例**（`TC-000045`，`face UI` / `driver E2E`）+ **功能用例**（`TC-000046`，`face API` / `driver HTTP`）+ **机械用例**（`TC-000047`，边界，`face API`）：**v5 形态**（锚 `module` / `feature`，**`face` 分前后端**，正文 **`given` / `when` / `then`** 可执行 DSL：上下文与输入 / 你干了什么 / 就会有……），见 [`../../lang/test.md`](../../lang/test.md)。**单元测试已退出 m 语言**（用 JUnit / xUnit / vitest 原生写） |
| `SUITE-UAT-CORE.m` | **集合声明**（v2 新增）：`SUITE-UAT-CORE`（`select { phase UAT }`）+ `SUITE-SMOKE`（**`subset SUITE-UAT-CORE`**）+ `SUITE-REGRESSION` + `SUITE-M03-INTEGRATION`；**v5 增** `SUITE-UAT-UI` / `SUITE-UAT-API`（按 `face` 分前后端，均 `subset SUITE-UAT-CORE`） |
| `差异对照.md` | 标准侧 vs 库侧（`mmda_alm.requirement`）逐条差异 + 勾选区（**⤴ 四轮：库侧仅参考，将废除**） |
| `差异对照-测试与缺陷.md` | 标准侧 vs 库侧（`mmda_alm` 的 `testcase` / `teststep` / `testcasedependency` / `testtype` / `bug`）逐条差异 + 勾选区（**T / B / L** 编号；**⤴ 四轮：库侧仅参考，将废除**）；姊妹篇 = [`差异对照.md`](差异对照.md) |
| `app-model/` | **仅参考**（**⤴ 四轮：`mmda_alm` 将废除，这一层是留给将来迁移的样本**）：库现状的复刻 —— 需求侧（`record Requirement` + 枚举 + 关联表）与**测试 / 缺陷侧**（`TestCase` / `TestStep` / `TestCaseDependency` / `TestType` / `Bug` + 枚举）。⚠️ **都不是标准写法**（`record` 描述需求 / 用例 = 把语言要素降级成应用数据） |

> `app-model/` 里的 `Requirement.m` 等 **不得**当作 intent 的标准写法——用 `record` 描述需求，等于把语言要素降级成应用数据。

---

## 6. 已裁与仍待裁

**✔ 已裁（2026-09-28，三轮全部落地）**：`subject` **要**（必填）；BUSINESS **不得**直挂 usecase；**UAT 挂 intent**；usecase 的 UML 适配器**已登记**（`muc-uml`）；**How 黑名单词表暂时不考虑**；**粒度 = 一文件可放多条 `intent`**（与 `record` 同，可 `import` / 相互引用）；**暂时不要多行字面量**（`why` / `what` 用短句列表）；**建模侧回指 `satisfies UC-…` / `satisfies INT-…` 都允许**；**进库 = 元对象 `Meta*`（`MetaIntent` 表族）**（[`差异对照.md`](差异对照.md) **D0 = A**；**⤴ 四轮：`mmda_alm` 仅参考、将废除，「降为投影」取消**）。

**仍待裁**：见 [`doc/lang/intent.md`](../../lang/intent.md) §9 与 [`差异对照.md`](差异对照.md)（D1–D16 + L1–L11 中未打勾项）；与本示例直接相关的只剩 **SRS 导出形态与基线冻结**、**意图进库的写入口**（§7-11）。

**测试 / 缺陷侧（2026-09-29 追加；同日二轮 v2、三轮 v3、五轮 v5）**：用例进 m 语言的形态已起草为 [`../../lang/test.md`](../../lang/test.md) **v5**（示例见 [`TC-000045.m`](TC-000045.m) 与 [`SUITE-UAT-CORE.m`](SUITE-UAT-CORE.m)），落库见 [`../../lang/test-store.md`](../../lang/test-store.md) **v5**（**唯一落库面 = 内核 `MetaTest` 族**；`mmda_alm` 仅参考、将废除），库侧实测差异见 [`差异对照-测试与缺陷.md`](差异对照-测试与缺陷.md)（**§⑤ 为二轮新增 T20–T25**）——**两道总闸仍待裁**：**T0**（用例的本质 = 元对象 vs 应用业务表）与 **B0**（缺陷进不进语言，建议 = 应用侧 `record Defect` + `stm DefectStatus`）。
> **二轮五条**（作者 2026-09-29）：用例集合成为一等实体 `suite` / 每条用例必须可执行（**`given` · `when` · `then` 三段可执行 DSL**，底座造数·驱动·判定）/ `kind` → `kinds` 多维标签且**冒烟 ⊆ UAT** / 用例**挂 module** 而 intent 经 module 反查（`req` · `covers` 作废）/ 单元测试**对接 vitest · JUnit · NUnit**（`harness` + 代码生成映射）。
> **三轮（2026-09-29）**：三段关键字改用 BDD **`given` / `when` / `then`**（`given` 上下文与输入 / `when` 你干了什么 / `then` 就会有……），**仍是封闭指令词表**、仍由底座造数·驱动·判定三支座执行；v2 的 `input` / `steps` / `output` 作废；**`when` 不写序号、`then` 不写 `expect`**。
> **五轮（2026-09-30）**：**单元测试退出 m 语言**（JUnit / xUnit / vitest 已成熟，不另立语法）——~~`phase UNIT`~~ / ~~`unit` 锚~~ / ~~`harness`~~ / ~~`attach`~~ / ~~指令→代码映射表~~ / ~~`mmda test-gen`~~ 全废；m 语言只管 **feature / module 级功能验证**，因**前后端分离**新增 **`face`** 子句（**`UI`** 前端交互 / **`API`** 后端接口），`driver` 值域改为 **`E2E` / `HTTP` / `HOOKS` / `MANUAL`** 并与 `face` 配对，`kinds` 删「通道」维度；`phase` 四档 = `FEATURE` / `INTEGRATION` / `SYSTEM` / `UAT`（见 [`../../lang/test.md`](../../lang/test.md) §2 / §3 / §6）。
