# 06 代码生成与二次开发（定制点载体）

> **已裁（✔ 2026-09-26 作者）**：退役 `~GENERATED PARTS` / `~KEEP PARTS`（**选 A**）；定制点按「谁写、写什么」分家；**否决生成内部类**。
> 依据：本轮作者三条原话（见 §1）+ 既有口径 `PLAN.md` §6.3-30 / §6.3-34、[`../doc/runtime.md`](../doc/runtime.md) §4.2–§4.7。

## 1. 定案（作者 2026-09-26）

| # | 决定 | 作者原话要点 |
| --- | --- | --- |
| **C1** | **退役 `~GENERATED PARTS` / `~KEEP PARTS`**（上一轮的 A 档）：生成物**整文件覆盖、可再生、可校验**；二次开发走**独立的第二载体** | 「选A」 |
| **C2** | **两类定制点分家**：标准 `beforeXxx`/`afterXxx` **用 m 语言在 IDE 里写**（操作**当前实体模型与关联数据**）；**Action 业务逻辑**抽象成 **`IAction` 接口**，程序员实现，**底座提供扩展点注入** | 「那些标准的 beforeXxx/afterXxx 我期望是能用标准的 m 语言在 IDE 里面就写……而 action 要程序员写业务逻辑，代码量较多，可以抽象出 IAction 接口，程序员去实现，然后底座有扩展点让他们注入即可」 |
| **C3** | **否决生成内部类** | 「我之前的 java 生成了内部类，跟 service 混在一起不好，也难以维护」 |
| **C4** | **状态转换定死**：`beforeAction` / `afterAction` 由**设计师在状态转换中定义**，程序员**只能填业务逻辑部分** | 「状态转换已经定死，也就是 beforeAction/afterAction 已经由设计师在状态转换中定义死了，程序员只能处理业务逻辑部分」 |
| **C5** | **目标 = CRUD 也走 m 语言**（IDE 里写）→ 生成 Java / C# → 借助 **`EntityFactory`** 的能力执行 → 手写 Java/C# 的面积继续缩小 | 「我最理想的是，CRUD 的程序都能通过 m 语言在 IDE 里面写，最后生成 java, c#，借助 EntityFactory 提供的能力执行」 |
| **C6** | Action 实现类**与 service 同包附带生成脚手架**，供程序员改写 | 「例如 ProductionOrderService 是生成物，可能在同目录下附带生成 `SubmitAction<ProductionOrder>`、`ApproveAction<ProductionOrder>` 等让程序员改写」 |

## 2. 产出物形状（Java 示例）

**Java —— 每实体一个目录**（✔ 2026-09-26 作者 D18：受 Java「包 ↔ 目录」约定所限，扁平命名要改）：

```
services/ProductionOrder/          ← 目录名 = 实体名（= 包名末段）
  Service.java                     ← 生成物：整文件覆盖，头带生成指纹
  SubmitAction.java                ← 生成脚手架（extends ActionBase<ProductionOrder>）
  ApproveAction.java               ← 生成脚手架（同上）
  ServiceExt.java                  ← 手写物：生成器永不覆盖（D20：**大部分场景不需要**）
```

**C# —— 同构目录**（namespace 可扁平，但**目录同构**便于两端对照）：

```
Services/ProductionOrder/
  Service.cs                       ← 生成物
  ServiceExt.cs                    ← 手写物：`partial class Service`（D18：命名两端统一为 `ServiceExt`）
  SubmitAction.cs / ApproveAction.cs
```

> **旧布局作废**：`services/ProductionOrderService.java` 这种"实体名拼进类名"的扁平写法**退役**（Java 一个文件一个 public 类 + 包必须对上目录 ⇒ 想"同一实体的东西放一起"就只能目录化）。

**判定生成物 vs 手写物 —— 不用文件内标记，用「生成清单 + 指纹」**：

| 机制 | 做法 |
| --- | --- |
| **生成清单** | 每次生成产出 `gen-manifest.json`：`{ 文件路径, 产物类别(generated/scaffold), 指纹(源码 hash 或 元数据 hash), 生成器版本 }` —— **它才是"这文件归谁"的真源** |
| **生成物** | 在清单里标 `generated`：**整文件覆盖**；头注释带 `GENERATED — DO NOT EDIT` + 指纹 + 生成器版本 |
| **脚手架** | 标 `scaffold`：**首次生成；文件已存在则跳过**（`--force` 才覆盖）—— 这就是 action 实现类的"给你改写"语义 |
| **手写物** | **不在清单里** ⇒ 生成器永不触碰 |
| **校验** | `mmda gen --check`：① 生成物指纹与元数据一致（**被手改即报错**）；② 清单与实际文件集合一致（多余/缺失都报）；③ 元数据破坏性变更 → 列出**受影响的手写实现类** |

**Action 脚手架带 `TODO` 提醒**（✔ 2026-09-26 作者 D16 取 i：「**同时提醒程序员要实现的 TODO，有这个作用**」）：

```java
// TODO(mmda): 实现 Submit 的业务逻辑（状态转换与准入由元数据定死，见 .ms 状态机）
@Override protected void execute(ProductionOrder ctx) {
    // TODO(mmda): ...
}
```
- `TODO` 统一前缀 **`TODO(mmda):`** ⇒ 工具可收集：`mmda check` 出 **warning「N 个 Action 未实现」**、IDE 出**面板清单**（谁没写一目了然）—— 脚手架从"空文件"升级为**任务清单**。

**Action 的落地形态**（Java 不能写"具名的泛型实例类型"，故二选一，见 D16）：
- **形态 i（建议）**：底座出泛型基类 `ActionBase<TEntity>`，生成器为每个实体的每个 action 产出**具体子类脚手架**（`class SubmitAction extends ActionBase<ProductionOrder>`），程序员在 `execute()` 里写业务逻辑；
- **形态 ii**：不生成类，只在装配代码里 `new ActionBase<>(ProductionOrder.class)`，需要定制时再手工建子类（更轻，但没有"同目录附带生成"的引导作用）。

**契约已有草稿（本次定稿的基础）**：[`../doc/design-notes.md`](../doc/design-notes.md):505 的 `IAction<TContext>` —— `context()` / `canExecute()` / `execute()` / `transition()` / `exit()`，配底座 `doAction()` 编排：开事务 → `canExecute()` 不过即抛 → `execute()` → `transition()` → `exit()` 抛事件。
**分工照 C4**：`canExecute()`（准入）与 `execute()`（业务逻辑）是**程序员的部分**；`transition()` / `exit()` 属**定死部分**（由状态转换与事件驱动，生成物/底座编排，程序员改不了）。

**谁编排顺序**：底座按**状态转换**（来自 `.ms` / `@State`）编排 `canDo → beforeAction → execute → afterAction`；**生成物只生成调用点**，程序员改不了顺序（这就是 C4"定死"的实现方式）。

## 3. 三类定制点的载体（对齐既有口径）

| 定制点 | 谁写 | 载体 | 依据 |
| --- | --- | --- | --- |
| `beforeXxx` / `afterXxx`（标准生命周期） | 设计师声明 + 程序员填逻辑 | **m 语言内联**（IDE 里写，内核求值）；只能操作**当前实体与关联数据** | C2；[`../PLAN.md`](../PLAN.md) §6.3-34（受限脚本 = **m 语言受限子集、Rust 内核求值**）、[`../doc/runtime.md`](../doc/runtime.md) §4.2 / §4.5 / §4.6 |
| Action 准入 | 程序员 | **`canDo`**（不用反射，三端统一） | [`../PLAN.md`](../PLAN.md) §6.3-30 ①；[`../doc/runtime.md`](../doc/runtime.md) §4.2 |
| **Action 业务逻辑** | 程序员 | **`IAction` 实现类**（生成脚手架，之后归程序员） | C2 / C6 |
| 状态转换与顺序 | **设计师**（m / `.ms`） | 生成物只调用，**程序员的实现类改不了** | C4；[`../doc/lang/records.md`](../doc/lang/records.md) `@State`、[`../doc/lang/meta-model.md`](../doc/lang/meta-model.md) |
| CRUD（增删改查/列表/表单） | 设计师（m / view） | 生成 Java / C#，**经 `EntityFactory` 执行**；**禁手写 SQL 与字符串字段名** | C5；[`../PLAN.md`](../PLAN.md) §6.3-30 ⑥ |
| 实体/服务级增量（给生成的服务加辅助方法） | 程序员 | **`ServiceExt`**（同目录手写物） | **D18 / D20：大部分场景不需要**（CRUD 走 m、钩子走 m 内联、重逻辑走 `IAction`），保留给少数"加个私有辅助方法"的需求 |

### 3.1 实现类怎么被找到（✔ 2026-09-26 作者 D17：**约定优先，不用声明**）

> 作者原话：「**m 语言中 action Submit，就代表默认是 SubmitAction，默认不用再指定了，比如 ProductionOrder 里面的状态机设计了 submit 操作，那么 java/c# 就得有 class SubmitAction<ProductionOrder>**」。

| 规则 | 内容 |
| --- | --- |
| **默认命名** | 语言里 `ProductionOrder` 的状态机声明了 `submit` 操作 ⇒ 实现类**默认**就是 `ProductionOrder/SubmitAction`（**不需要**任何 `impl:` 声明） |
| **显式覆盖** | 只有偏离约定时才声明（`impl:`），**属例外不是常态** |
| **生成器据此生成显式装配代码** | 因为名字是**推导出来的**，生成器知道该装配谁 ⇒ **零反射、零手写登记** |
| **缺实现类 = 错** | 状态机声明了 `submit` 但 `SubmitAction` 不存在 → **`mmda check` error**（生成期就拦，不留到运行期） |

## 4. 底座必须提供的能力（否则以上形态不成立）

1. **`IAction` / `ActionBase<TEntity>` 契约**：`canDo` / `beforeAction` / `execute` / `afterAction` 的**调用序由底座编排**，序来自状态转换。
2. **扩展点注入（零反射）**：作者既定口径是「java/c# 我不想用反射」（[`../PLAN.md`](../PLAN.md) §6.3-30 ①）——
   - **建议**：在 m 语言里**声明绑定**（如 `action Submit { impl: SubmitAction }`），**生成器据此生成显式装配代码** ⇒ 零反射、零手写注册、删实现类即报错；
   - 备选：生成一个手写注册类（`ProductionOrderActions.java`，脚手架），程序员在里面登记实现类 —— 无反射但**多一处手写登记**（见 D17）。
3. **`EntityFactory` 能力面**：查询 / 条件更新 / 删除（`../PLAN.md` §6.3-30 ⑥ 的硬目标：消灭手写 SQL 与字符串字段名）。
4. **受限脚本内核求值通道**：m 内联钩子要**内核求值**（Rust + P6 嵌入通道 Panama / P-Invoke + WASM），这是 M8 / P6 的依赖 —— **排期见 D19**。

## 5. 依赖与分期（重要：m 内联钩子有前置）

| 阶段 | 钩子能做到什么 | 前置 |
| --- | --- | --- |
| **首版（M4–M5）** | 语言层**可声明**钩子；**声明式子集**（字段赋值 / 默认值 / 必填 / 条件校验这类能被元数据表达的）直接生效；生成物生成**调用点 + 骨架** | 无 |
| **内核求值就绪（M8 / P6 后）** | 完整 **m 内联体**（对当前实体与关联数据的操作、条件、计算）由内核求值执行 | 受限脚本运行通道 |

**不建议的过渡**：把 m 内联体**转译成 Java/C# 代码** —— 那会出现"内核语义 vs 生成代码语义"两套实现，必然漂移（与"Rust 单实现"的初衷相反）。

## 6. 三端对照（统一命名，避免"合法的 KEEP 区"）

| | Java | C# | TS |
| --- | --- | --- | --- |
| 生成物 | `XxxService.java`（整文件覆盖） | `XxxService.cs` | `xxxService.ts` |
| 手写物 | `ServiceExt.java` · `SubmitAction.java` | `ServiceExt.cs`（`partial class Service`；**两端命名统一**，✔ D18） | `serviceExt.ts` |
| 状态转换 | 生成物只调用 | 同 | 同 |
| 归属判定 | `gen-manifest.json` + 指纹 | 同 | 同 |

> **注（实测 2026-09-26，含对上一轮说法的更正）**：C# 侧 **338 个生成文件带 `GENERATED PARTS` 标记、`KEEP PARTS` **0** 个**（证据：`D:/2026/cs/MMDA/Mmda.Alm/Mmda.Alm.Models/Models/Bug.cs:6` 版权头里的 "Please don't modify any code between GENERATED PARTS BEGIN and END"），另有 **239 个 `partial class` 分片、0 个命名约定**。
> 结论：**C# 侧早就在跑"生成区 + 独立手写分片"这个模型**（只有生成区、没有保留岛），**缺的只是命名约定**（统一 `Xxx.Custom.cs`，见 D18）。所以本轮选 A 不是"新发明"，而是**把 C# 已经这样跑的事实规范化，并让 Java 对齐它**。

## 7. 存量 KEEP 区的退役路径

1. **新增**：新模型一律不产保留区（生成清单 + 指纹）；
2. **抽取**：一次性脚本把存量保留区内容搬到 `XxxExt` / Action 实现类（成对文件，输出 diff 供人审）；
3. **顺序**：谁动谁搬（优先 `git log` 近期改过的文件）；
4. **过渡**：`mmda gen --check` 对存量先 **warning**、一个版本周期后升 **error**；
5. **回滚**：保留 `--keep-parts` 兼容开关一个版本周期。

## 8. 本轮已裁（✔ 2026-09-26 作者）

| # | 裁定 |
| --- | --- |
| **D16** | 取 **i**：生成 `class SubmitAction extends ActionBase<ProductionOrder>` 具体子类**脚手架**，**并带 `TODO(mmda):` 提醒**（工具可收集未实现的 Action） |
| **D17** | **约定优先**：`action Submit` ⇒ 默认实现类 `SubmitAction`，**不再显式指定**；生成器据此产出**显式装配代码**（零反射）；缺实现类 = `mmda check` error |
| **D18** | 目录化 + 两端命名统一：**每实体一目录**；`Service.java`（生成）/ `SubmitAction.java`（脚手架）/ `ServiceExt.java`（手写，少用）；C# 同构 `Service.cs` / `ServiceExt.cs`（partial） |
| **D19** | 取 **A**：首版只吃**声明式子集**，内核求值通道（M8 / P6）就绪后开完整 m 内联 |
| **D20** | 取 **A**：`Ext` **大部分不需要**（定制口 = m 内联钩子 + `IAction` 实现类），保留 `ServiceExt` 给少数场景 |

**下一批待拍**：多租户插件 5 条（**D21–D25**）→ 见 [`07-plugins-multitenant.md`](07-plugins-multitenant.md) 与 [`05-decisions.md`](05-decisions.md)。

## 9. 相关

[`01-stack.md`](01-stack.md) · [`02-parser.md`](02-parser.md) · [`03-milestones.md`](03-milestones.md) · [`04-verification.md`](04-verification.md) · [`05-decisions.md`](05-decisions.md)
· 真源：[`../doc/runtime.md`](../doc/runtime.md) §4 · [`../doc/design-notes.md`](../doc/design-notes.md):505（`IAction` 草稿）· [`../doc/ai/tools.md`](../doc/ai/tools.md)（KEEP 边界的现有口径，待改）· [`../PLAN.md`](../PLAN.md) §6.3-30 / §6.3-34
