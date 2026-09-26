# 运行架构（Runtime）

> **为什么有这篇**：`doc/` 里已有**语言**（模型怎么写）、**目标端契约**（三端能力矩阵）、**架构评估**（设计期静态规则），缺一层——**系统跑起来时，请求在哪儿被拦、事务在哪儿开、缓存从哪儿过、装配谁来干**。这篇是「运行架构」，来源是作者 2026-09 的**概念设计图**（《分层架构》）。
> **图的定位**：**概念设计、属运行架构（runtime）**，不是代码现状的快照——图给的是**设计思路**：`Controller` = API 开放，`Service` = 商业逻辑，`Repository` = 数据读写层，**缓存 = 横切面**。
> 状态：草案（2026-09-24）· 联动 [`architecture-review.md`](architecture-review.md)（§2.5 把本文的层边界变成可机检规则）、[`targets.md`](targets.md)（L2 能力契约：事务 / 钩子 / 缓存）、[`events.md`](lang/events.md)（`after*` 钩子的幂等）、[`meta-model.md`](lang/meta-model.md)（Action / 视图）、[`ide/plugins.md`](ide/plugins.md)（程序员定制区）。

---

## 0. 一句话

**请求从上往下走一遍，返回从下往上走一遍**：进入时 Controller 做三件事（**认证 / 授权 → 数据合法性校验 → 默认值设置**），Service 开事务并执行商业逻辑，Repository 只做 CRUD；返回时 Service 做**关联对象、枚举和引用属性组装**，Controller 做**聚合**再回给客户端；**缓存是横切面**，Controller 与 Service 两侧直达（图中 `reactive` 双向），不绕 Repository。

```
客户端 ──请求──► Controller ──► Service ──► Repository ──► 存储
   ▲  认证/授权      ▲                 ▲
   │  校验/默认值    │  Before 拦截点   │
   │                │  ┌─ 事务 ─────┐  │
   │                │  │ 商业逻辑   │  │
   │                │  └────────────┘  │
   │                │  After 拦截点    │   CRUD
   │                └── 关联对象/枚举/引用属性组装
   └── 聚合 ◄────────────────────────────────
        ╚══════════ 缓存（横切 · CacheProvider · reactive）══════════╝
```

---

## 1. 四层的职责（每层只干一件事）

| 层 | 职责 | 不做什么 | 语言里的对应物 |
| --- | --- | --- | --- |
| **Controller** | **API 开放**：认证 / 授权、数据合法性校验、默认值设置、返回聚合；**对外契约（API）怎么定义与出文档见 [`api.md`](api.md)** | ❌ 不写商业规则；❌ **不得直接访问 Repository** | 视图（`ui/**/*.mi`）+ Role 的能力范围（[`meta-model.md`](lang/meta-model.md) §8.1） |
| **Service** | **商业逻辑**：事务边界、业务规则、流程编排、返回前的**组装** | ❌ 不拼 SQL；❌ 不关心 HTTP 形态 | Action（`statements.md`）、STM、Converter、`.mf` 流程 |
| **Repository** | **数据读写**：CRUD、条件构造、方言适配 | ❌ 不含业务规则（存储级钩子只做数据整形） | `@Ref`/`@Many` 关系 + DDL/方言（`targets.md`） |
| **缓存** | **横切面**：读加速、失效、租户隔离 | ❌ 不承载唯一真源；❌ 不作为第二数据源 | capability `cache`（[`targets.md`](targets.md)） |

> **设计期可算的推论**：既然「进入路径上的三件事」在 MMDA 里都是**声明**（Role 的能力范围、字段约束、字段默认值），Controller 层就**没有手写业务代码的位置**——它是生成物。这正是评估规则 ARCH-107 要守的边界。

---

## 2. 两条路径（进入 / 返回）

| 阶段 | Controller | Service | Repository |
| --- | --- | --- | --- |
| **进入** | ① 认证 / 授权（Role × 模块 × Action × 数据范围）② 数据合法性校验（字段约束）③ 默认值设置（字段 default） | ④ Before 拦截点 ⑤ **开事务** ⑥ 商业逻辑（Action / 流程节点 / 转换器）⑦ After 拦截点 ⑧ 提交 | ⑨ CRUD（含租户过滤） |
| **返回** | ⑫ 聚合（多对象 → 一个响应） | ⑪ 关联对象、枚举和引用属性组装 | ⑩ 行 → 对象 |

**两条路径各有一件事必须由元数据驱动**：

- **进入的 ①②③**：声明在元数据里，生成器统一生成到进入路径上——**三端必须一致**（一致性测试的天然样本）。
- **返回的 ⑪⑫（组装 / 聚合）**：关系已在元数据里声明（`@Ref`/`@One`/`@Many` + Converter），**装配代码必须是生成物**，不允许逐模块手写（当前三端都没有专门的装配类，见 §6 现状）。

---

## 3. 事务边界（图的读法：事务夹在两个拦截点中间）

图把「**事务**」与「**业务逻辑**」画在 Service 的同一个块里，上下夹着 Before / After 拦截器——这条不是画法，**是语义**：

| 位置 | 事务语义 | 允许做什么 | 不允许做什么 |
| --- | --- | --- | --- |
| `before*`（事务**内**） | 与业务逻辑同一事务 | 改值、补默认、拒单（返回校验错误）、写审计 | 发消息 / 调外部系统（会因回滚而说谎） |
| `after*`（事务**提交后**） | 事务外，**必须幂等** | 发事件、通知、写日志、清缓存、触发后续流程 | 改当前业务数据（改了不会回滚） |

> **这条口径消灭了现有实现的命名漂移**：Java 的 `afterInserted()` / `afterUpdated()`（`EntityService.java:388/658`）与 TS 的 `afterSave()`（`entity_logic.ts:185`）**语义不同人不同写**；统一后它们都属「提交后的 `after` 点」——**名字可以各省，语义必须一样**，三端一致性用例据此断言。

**跨模块怎么办（✔ 已裁 2026-09-24，§9-7）**：**默认「同模块同事务、跨模块新事务」**（避免长事务把锁跨到别的模块）；**跨模块一致性走事件补偿**（[`events.md`](lang/events.md)）。作者原话：「同意，**比如 2 阶段提交或者分布式事务，这个具体实现**」——**2PC / 分布式事务属实现层选项，不在语言层承诺**（模型里写不出来，实现可按部署形态选）。

---

## 4. 拦截点（✔ 上升到语言层：统一语义 + 固定模式）

### 4.1 现状（实测：三层都有挂点，但命名与粒度不一致）

| 端 | 层 | 钩子（实测） |
| --- | --- | --- |
| Java | Controller | `ReactiveEntityController.java:1292 beforeQuery` |
| Java | Service | `EntityService.java:337 beforeValidate`、`:378 beforeInsert`、`:388 afterInserted`、`:477 beforeDelete`、`:484 afterDeleted`、`:650 beforeUpdate`、`:658 afterUpdated`、`:878 afterGot`、`:2433 beforeImportValidate`（应用点 `:696`、`:702`） |
| Java | Repository | `EntityRepository.java:509 beforeInsert`、`:1518 beforeUpdate`；`TenancyEntityRepository.java:184`（租户版） |
| Java | 实体自身 | `RoleModuleAuth.java:274 beforeSave()` |
| TS | Logic | `packages/core/src/logic/entity_logic.ts:68 beforeView(viewType)`（由视图类型推钩子名）、`:171 beforeLoad`、`:175 beforeValidate`、`:183 beforeSave`、`:185 afterSave`、`:187 beforeImport`、`:191 beforePrint`、`:195 beforeUpload`、`:199 beforeAction`、`:201 afterAction`、`:203 beforeDelete`、`:207 beforeDeleteAll`、`:211 beforeResetFilters` |

**三处不一致**：① 时态命名（`afterInserted` vs `afterSave`）；② 粒度（Service 按 CRUD 原语、TS 按视图与动作）；③ **层归属没有规矩**——同一个「保存前」在三层都可能有挂点。

### 4.2 统一语义：`before` / `after` × **生命周期点**（封闭枚举）

**规则：生命周期点是语言规定的封闭集合，不许自定义名字**（否则三端漂移、无法做一致性测试；命名注册表在校验期强制，[`architecture-review.md`](architecture-review.md) ARCH-402）。

| 生命周期点 | 语义（= 时机） | 归属层 | 现有实现对应 |
| --- | --- | --- | --- |
| `load` | 进入视图、取数前 | Service | TS `beforeLoad` |
| `search` | 列表查询前（条件/过滤） | Service | TS `beforeView('search')`、Java `beforeQuery` |
| `edit` | 进入编辑/初始化表单 | Service | TS `beforeView('edit')` |
| `validate` | 约束校验（**在事务内**） | Service | Java `beforeValidate`、TS `beforeValidate` |
| `save` | 落库前 / 提交后（insert 与 update **语言语义上合并**为一个点） | Service | Java `beforeInsert`/`afterInserted`/`beforeUpdate`/`afterUpdated`、TS `beforeSave`/`afterSave` |
| `delete` | 删除前 / 提交后（含批量） | Service | Java `beforeDelete`/`afterDeleted`、TS `beforeDelete`/`beforeDeleteAll` |
| `got` | 读回后、**装配前** | Service | Java `afterGot` |
| `action` | 自定义 Action 执行前后；**「能不能执行」的判断统一走 `canDo`** | Service | TS `beforeAction`/`afterAction`；**准入函数：TS `EntityAction.canDo`（现名）、Java/C# `canExecute`（✔ 2026-09-24：三端将统一为 `canDo`）** |
| `import` / `print` / `upload` | 导入 / 打印 / 上传 | Service | TS `beforeImport`/`beforePrint`/`beforeUpload` |
| `store` | 存储级（SQL 整形、审计列） | **Repository（✔ 2026-09-24 已裁取 A：**不对设计师开放**——只给程序员 KEEP 区 + 显式勾选 + 评审清单可见，§9-4 / §4.4）** | Java `EntityRepository` 的两个钩子 |

> 语境里的一切都是 `before<点>` / `after<点>`（如 `beforeSave` / `afterDelete`）——**复用现有命名，不造新词**。
> ✔ **两个「钩子的家」分清楚（2026-09-24，作者补充原话：「实际上 service 层也有钩子，是给业务逻辑用的」）**：**`beforeXxx` / `afterXxx` 住 Service**（业务逻辑，与业务同一事务，§3）；**`store` 级钩子住 Repository**（存储语义，见 §4.4——**已裁不开放**）。**钩子里能写什么**见 §4.5 / §4.6（✔ 已裁 2026-09-24：受限 m 脚本 + 能力 = 内核函数）。

**封闭枚举与 Action 的准入（✔ 已裁 2026-09-24，§9-1 / §9-2 / §9-3）**：作者原话：「ts 实际上可以自定义，例如 `beforeAction` 可以自动看 ‘submit’ 有没有 `beforeSubmit`，**但是 java/c# 我不想用反射**，所以程序都写在 action 里面，专门有一个 `canExecute` 函数。**后面统一**，现在前端 `EntityAction` 里面有 `canDo` 函数，**后续重构统一 `canDo` 函数，然后支持 m 语言写逻辑**，其他还是固定，例如 `beforeDelete`」。

- **标准点就是 `beforeXxx` / `afterXxx` 那几个——不要新增**（§9-2）；新增点只能走语言版本；
- **Action 不走 `beforeXxx`，走 `canDo` 拦截**——「这一步能不能执行」的统一入口；
- **三端一致化的动作**（重构项）：TS 现状 = `EntityAction.canDo`（并会**按名自动探测** `beforeSubmit` 这类名字）；**Java / C# 不用反射**（按名探测在 JVM/.NET 上代价大且易错），现状把逻辑写在 action 内、准入用 `canExecute`。**统一方向 = 三端都叫 `canDo`，并支持用 m 语言写逻辑**；**TS 的「按名探测」是 TS 侧实现细节，不进三端契约**。
- **其余点保持固定**（如 `beforeDelete`）。

### 4.3 固定模式：设计师配置 + 程序员定制

| 谁 | 干什么 | 在哪 |
| --- | --- | --- |
| **架构师 / 设计师** | **配置**：选生命周期点、顺序、生效条件（角色 / 视图 / 状态） | IDE 设计器（图形 + 清单），产物是**声明** |
| **程序员** | **定制**：实现钩子体（Java / C# / TS 三端各自的语言） | **KEEP 区 + 插件**（[`ide/plugins.md`](ide/plugins.md)），"生成一次、不再覆盖" |
| **AI Agent** | 提议钩子骨架与用例，**不签字**（[`workflows.md`](workflows.md) §6 三道闸） | 同代码路径 |

**为什么这样切**：钩子是**业务规则挂载点**（设计师能说明白"什么时候要拦一下"），但**实现必然是代码**（程序员写）——两边都别越界：**设计师不写代码，程序员不改声明**。

### 4.4 `store` 级钩子是什么（✔ 已裁 2026-09-24：**取 A 不开放**）

> 作者回「**没明白啥意思**」→ 本节解释后重问 → **作者取 A**（2026-09-24）。

上面那张表里 `store` 与其它点**不是一类东西**——其它点问的是「**业务上要不要拦一下**」，`store` 问的是「**这条 SQL 要不要改一下**」：

| | 其它点（`beforeInsert` / `afterUpdate` …） | `store` 级钩子 |
| --- | --- | --- |
| 说的是什么 | **业务语义**：「插入前补个默认值 / 不满足条件就拒单」 | **存储语义**：「这条 `INSERT` 语句的列要不要动 / `WHERE` 要不要加条件 / 审计列怎么填」 |
| 住在哪 | Service（与业务逻辑同一事务，§3） | **Repository**（真正生成 SQL 的层，Java 现状 `EntityRepository.java:509 beforeInsert`、`:1518 beforeUpdate`） |
| 谁看得懂 | 设计师能说明白 | **只有懂 SQL 与表结构的人能改** |

**现在的问题**：模型声明、`@Ref`、枚举、视图已经能推出绝大多数 SQL（§6 装配、[`meta-model.md`](lang/meta-model.md)、[`records.md`](lang/records.md)），`store` 钩子**只在改不动模型、又必须改 SQL 时**才用（历史表列名不一致、特殊索引提示、审计列来源特殊）。**给它开放出去** = 允许在声明之外偷偷改库行为，[`quality.md`](quality.md) 的 L3「生成 DDL / SQL 逐字对账」就会失真。

**所以本条的选项只有两种**：**A 不开放**——只给程序员（KEEP 区代码），且走**显式勾选**、在评审清单里可见；**B 开放给设计师**——那就要给 `store` 钩子加一套声明语法与校验（成本高、收益低）。

**✔ 已裁（2026-09-24，作者取 A）**：**`store` 级钩子不对设计师开放**——只给程序员（KEEP 区代码），走**显式勾选**、**评审清单可见**；**模型侧与语言侧不提供 `store` 钩子的声明语法**（不给它开第二真源，[`quality.md`](quality.md) L3 的「DDL / SQL 逐字对账」得以保持）。

---

### 4.5 钩子里能写什么：声明式 / 受限脚本 / 宿主代码（✔ 已裁 2026-09-24：**取 A，并放开跨模块与全 Entity 访问**）

> 作者原话：「**实际上 service 层也有钩子，是给业务逻辑用的**。我原先想能否有**脚本执行引擎**，嵌入到 java、c# 后台，能够写一些简单的脚本，**起到类似数据库的触发器的作用**。技术上有没有可能？**数据库的触发器没有可移植性，换数据库就废了**」→ 助手给 A／B／C 三档与技术事实 → **作者取 A**，并补口径：「**2要允许跨模块调用，能访问所有 Entity，例如查询，条件更新，删，能力我可以不断增加，都是函数**」。

**✔ 已裁（取 A）**：**脚本 = m 语言的受限子集，由 Rust 内核解析求值**，三端经 **P6 嵌入通道**（Panama / P-Invoke + WASM，[`PLAN.md`](../PLAN.md) §4）调用。**不引入宿主脚本引擎**——硬事实：**Nashorn 已随 JDK 15 移除**[^jep372]；GraalJS 有 Maven 包但**官方口径是 stock JVM 不受支持**[^graaljs]（与 L2 的毕昇 JDK 21 基线冲突）；.NET 侧 Roslyn Scripting / Jint / ClearScript 的「执行限额」**不是隔离边界**[^jint]。更要紧的是：宿主引擎 = **同一个钩子三端各写一遍**，语义漂移无法静态发现。

**2026-09-24 重申**：在评估 **Java Compiler API / Roslyn**（§4.6（3））的**双端实测**之后，作者再次确认「**维持 A**」——**不用宿主语言当脚本语言**。

**作者补充的三条口径（本轮定）**：

| # | 口径 | 落法 |
| --- | --- | --- |
| 1 | **允许跨模块调用** | 脚本可按模块调用任意 module 的**声明接口**；**事务按已裁规则走**（§3 / §9-7）：**同模块同事务、跨模块新事务**——脚本里跨模块写**不与本模块同一事务**，要最终一致就靠事件补偿（[`event_bus.md`](lang/event_bus.md) §9.3 Outbox） |
| 2 | **能访问所有 Entity**：查询 / 条件更新 / 删除 | 统一经**内核代理**（`EntityFactory` / `Repository` 的脚本面，§6）：**读**走查询函数，**写**走「条件更新 / 条件删除」（带结构化条件的受控形态）——**不生成裸 SQL、不拼字符串字段名**，与「消灭手写 SQL 与字符串字段名」（§6/§8）同一条纪律 |
| 3 | **能力可以不断增加，都是函数** | **能力 = 内核提供的函数（host functions）**，逐条登记在 **§4.6**；项目用 `capability` 声明用到哪些，**未声明就用 → 生成期报错** |

**两层要分清（红线）**——这与已裁的 **1A（表达式层纯函数）**不矛盾，是**两套东西**：

| | **表达式层（Expression）** | **脚本层（Script）** |
| --- | --- | --- |
| 住哪 | 字段默认值 / `@Computed` / `lockIf`·`hideIf`·`requiredIf` / Validator 条件 | 拦截点（`beforeXxx` / `afterXxx`）与 Action 的 `canDo` |
| 是否纯函数 | **是**（无副作用、无 IO、无随机与时间依赖；可重复求值） | **否**（可读可写 Entity、可跨模块） |
| 为什么 | 可推导、可静态判定、可重复 | 有副作用 → **必须显式写出来、必须可审计、可回放** |

**脚本层仍然禁的东西**（不因为「能写数据」而放开）：**任意 IO**（文件系统 / 网络 / 进程 / 线程）、**反射与动态求值**、**随机与时间依赖**（要时间只能取内核给的 `now()`）。理由：这三样一放开，**沙箱、静态校验、三端一致**同时崩掉——那才是「嵌入一个 JS 引擎」的代价。

**语言层新增 = 0**：脚本块**不需要新关键字**，它挂在既有的拦截点与 Action 上；**脚本块的语法形态属语法专题**，另开讨论（[`PLAN.md`](../PLAN.md) §6.1）。

**✔ 已裁（2026-09-24，作者取 C）：脚本的运行身份 = 默认继承调用者 + 允许声明 `runAs: system`** —— 脚本里读写的权限按谁算：

- **默认 = 继承调用者**：脚本以**触发它的那个调用者**的权限与数据范围运行，越权同样被拒（安全默认，与 OWASP ASVS 的访问控制项一致）；
- **可选 `runAs: system`**：给**无调用者**的场景用（定时任务 / 事件消费者 / 系统钩子）——声明**必须进评审清单可见**、**`mmda check` 出 warning**（不是错误）；
- **身份枚举封闭**：**只有 `caller`（默认）与 `system` 两种，不许自定义身份**（自定义身份 = 绕过权限的通用后门）；
- **`system` 的边界**：**不受对象级 / 数据范围限制，但仍受功能开关与审计**——**所有脚本写入必须记 `actor`**（`caller` 场景记调用者身份；`system` 场景记 `system:<脚本名>`）[`operations.md`](operations.md)；
- **与多租户一致**：`system` 身份下**租户键仍然必须存在**（继承上下文租户或声明固定租户），与 §10「共享执行 + 租户键」同一条规矩。

### 4.6 脚本能力清单：一个能力 = 一个内核函数（⏳ 首版清单待增补）

**机制（✔ 已裁 2026-09-24）**：脚本能用的每一项能力**都是内核提供的一个函数**，逐条登记、逐条可查；**项目必须用 `capability` 声明用到哪些**，**未声明的调用在生成期报错**（与 `capability` 既有机制同一条路，[`targets.md`](targets.md) §5）；**新增能力 = 内核版本升级 + 本清单追加**，**不改语言语法**（作者口径：「**能力我可以不断增加，都是函数**」）。

**命名**：能力函数形如 **`script.<域>.<动作>`**（`script.` 前缀一眼可辨、grep 得到；域内动作用小写 camel，遵循 [`naming.md`](naming.md)）。

**首版起始清单（⏳ 作者增补）**：

| 域 | 函数（起始项） | 说明 |
| --- | --- | --- |
| 查询 | `script.entity.get(模块, 对象, id)`、`script.entity.query(模块, 对象, 条件)` | **条件是结构化的**（走元数据约束），**不接收裸 SQL 字符串** |
| 写入 | `script.entity.create(…)`、`script.entity.update(…)`、`script.entity.updateWhere(…)`、`script.entity.delete(…)`、`script.entity.deleteWhere(…)` | **条件更新 / 条件删除**是作者明确要的（「条件更新，删」） |
| 上下文 | `script.ctx.caller()`、`script.ctx.tenant()`、`script.ctx.now()` | 身份 / 租户 / **时间只能从这里取**（禁自己拿时间与线程上下文） |
| 事件 | `script.event.publish(事件, 载荷)` | 走 **Outbox**（与业务同一事务，[`event_bus.md`](lang/event_bus.md) §9.3） |
| 日志 | `script.log.info(…)` / `script.log.debug(…)` | 进日志与 trace，供运维面消费（[`operations.md`](operations.md)） |

**约束（不变）**：能力清单**只增不改名**（改名 = 破坏性变更，走语言版本）；**跨模块调用**按 §4.5 口径（**跨模块 = 新事务**）；**某项能力在某端不具备时**，`capability` 声明与三端一致性测试必须能在生成期发现（[`targets.md`](targets.md) §5）。

#### 查询形态与兜底层（**✔ 已裁 2026-09-24**：1）类 SQL 归 m 语言未来语法、2）兜底层 = KEEP 区、3）A′ 不做脚本语言）

**1）类 SQL 查询块**（**✔ 已裁 2026-09-24：方向 = 将来可能作为 m 语言自身的查询语法、由内核解析编译；不做「宿主 SQL 包翻译层」；首版不进；语法形态归语法专题**）—— 作者原话：「**还有一种可能，给上下文后，写类 SQL 的语句，然后 C#, java 都有 sql 包，能自动翻译执行，也是很好**」；裁决原话：「**维持A, m语言，未来如果支持类SQL语法也是有可能的**」。
两条路线：

- **路线 1（助手建议）**：**类 SQL 由内核解析 → 内核编译成方言 SQL → 宿主只执行**（JDBC / ADO.NET 只作通道）。
  好处：三端一致由内核保证；L3「DDL / SQL 逐字对账」天然成立（**最终 SQL 在内核手里**）；方言仍走既有 DDL 方言层。
- **路线 2**：**交给宿主 SQL 包翻译**（Java jOOQ / Spring Data JPA；C# EF Core / SqlSugar）。**代价（已核）**：
  ① **jOOQ 开源版只覆盖开源库**（PostgreSQL / MySQL / SQLite …）——**SQL Server、Oracle、Db2 与达梦、金仓等不在其列**，
  商业数据库与部分特性需 Express / Professional / Enterprise（**99 / 399 / 799 €**）；
  ② **两侧现有 ORM 并不同构**：**Java 底座现状 = Spring Data JPA**（11 个模块 pom 命中）、**C# 底座现状 = Dapper 2.1.35**（14 处 `PackageReference`）——
  **Dapper 是「字符串 SQL + 对象映射」，根本没有查询 DSL 翻译能力**；要用翻译就得换 EF Core / SqlSugar（新依赖、新语义、新方言行为）。
  ③ 于是「同一段类 SQL、两端各自翻译一遍」= **把「三端不统一」固化下来**，与 mmda-lang 的初衷（**统一 Java 与 C# 底座的接口方式**）相反。

**范围建议**：类 SQL **只用于只读查询**（join / 聚合 / 子查询 / 报表取数）；**写入仍走 `script.entity.*`**（要审计、行数上限、权限上下文）。

**2）兜底层：注入 `EntityFactory` / `Repository`，直接写 Java / C#**（**✔ 已裁 2026-09-24：定位 = KEEP 区兜底层，采纳助手建议档**）—— 作者原话：「**或者干脆注入 EntityFactory，直接 java/c# 写**」。
**这不是第三档脚本方案**，而是**已经定下的 KEEP 区宿主代码**（§4.2 注 + 已裁 §9-6「`EntityFactory` + `Repository` 两层、目标消灭手写 SQL 语句与手写字符串字段名」）。
口径：**注入的入口必须是接口**（面向 `IEntityFactory` / `IRepository` 编程，**不向下转型**到运行时类）、**禁止手写 SQL 字符串与字符串字段名**、**钩子实现进评审清单可见**。
定位 = **脚本的逃生门**（复杂逻辑 / 性能敏感 / 要用宿主生态与原生调试）—— **脚本不追求万能**，写不动的下沉到宿主代码。

**分层结论（✔ 已裁口径）**：声明式（表达式层，纯函数）→ 轻量逻辑（受限脚本 A）→ 查询（类 SQL，**将来可能成为 m 语言语法**）→ 复杂逻辑（KEEP 区宿主代码）。
**四档各就各位，不是四选一。**

**3）宿主语言运行期编译（A′，作者 2026-09-24 追加）**（**✔ 已裁 2026-09-24：不做钩子脚本语言**——随「维持 A」定案；**保留为 KEEP 区扩展的运行期加载方式、P6 之后的候选**）—— 作者原话：「**Java Compiler API**」「**Roslyn / DLR**」，即**脚本语言 = 宿主语言本身**（Java 片段 / C# 片段），运行期 in-memory 编译后加载执行。

**本机实测（不是推测）**：

| 项 | JDK 17（Liberica） | **JDK 21（L2 基线）** |
| --- | --- | --- |
| `ToolProvider.getSystemJavaCompiler()` | `com.sun.tools.javac.api.JavacTool` | 同（**纯 JRE 时为 `null`**） |
| 内存内编译一个小脚本（3 轮） | 30 / 22 / 19 ms | **34 / 23 / 24 ms** |
| 字节码 / 调用 | 318 B，`Hook.run(21) = 42` | 同 |
| **脚本能否读环境变量** | **能**（PATH 长度 4292） | **能** |
| **脚本能否列宿主目录** | **能**（user.home 169 项） | **能** |
| **脚本能否拿进程号 / 起进程** | **能**（`ProcessHandle` + `Runtime.exec("cmd /c echo")` 成功） | **能** |
| **C# / Roslyn**（.NET 10.0.12，Roslyn 5.3.0） | 冷编译 **344 ms**、热编译 **31 ms**（2048 B，`Hook.Run(21)=42`）；脚本同样**能读环境变量、能列目录、能拿进程号、能 `Process.Start("cmd /c echo")`**（实测打印出 `hi`）；`Assembly.Load(byte[])` 进默认上下文 = **不能卸载、无隔离** | |

**结论**：**编译 20~30 ms（Java）/ 31 ms（C# 热）完全可用，问题不在性能，在于「编译出来的脚本与宿主代码完全同权」**——文件、环境、进程、网络、反射全都能碰；
**Java 21 上没有 SecurityManager 可用**（JEP 411 已弃用），所以 **A′ = 没有沙箱**；Roslyn 侧同理（`AssemblyLoadContext` 是**加载隔离**、不是安全边界；
且 **Roslyn scripting API 官方不承诺生产支持，官方支持的是编译器 API**）。**另**：**DLR 不是脚本引擎**（表达式树 + 动态调用点缓存，是给语言实现者用的运行时层，IronPython / IronRuby 已停滞）——要用 DLR 仍得嵌第三方语言，即回到 B 档。

**A′ 的代价清单**：① **三端各写一遍**（脚本 = Java 片段 → C# 端得重写一份）——**与 mmda-lang 的初衷（统一 Java 与 C# 底座接口方式）相冲**；
② **脚本进不了元数据静态校验**（无字段名 / 类型检查，除非另写分析器），**生成器与设计器看不见钩子逻辑**，L3 逐字对账覆盖不到；
③ **依赖完整 JDK**（`getSystemJavaCompiler()` 在纯 JRE 上为 `null`）；**每次改脚本都要新 ClassLoader**（不池化 = metaspace 泄漏，已知坑）；
④ **明文可反编译**——与「核心算法下沉 Rust」的保护方向相反。

**助手建议的定位（若采纳）**：**A′ 不是「钩子脚本的语言」，而是 KEEP 区宿主扩展的「运行期加载方式」** ——
即「注入 `EntityFactory` / `Repository` 直接写」的**热更版本**（构建期编译 = 现在的 KEEP 区宿主代码；运行期编译 = 不打版就能改），
**适用场景只有「客户现场要改的复杂逻辑、必须用 Java / C# 写」**（MES 现场适配、报表口径）。纪律：**走 KEEP 区**（进评审清单、独立版本、**不进元数据真源**）、
**独立 ClassLoader / `AssemblyLoadContext` 做加载隔离**（诚实口径：**这不是安全边界**，靠**信任 + 进程 / 模块边界**）、**编译期做引用白名单校验**、明确「**这是信任代码，不是沙箱代码**」。

[^jep372]: JEP 372: Remove the Nashorn JavaScript Engine — JDK 15。
[^graaljs]: GraalJS Maven artifacts `org.graalvm.polyglot:polyglot` / `:js`；官方文档 "Run GraalJS on a Stock JDK" 明确 stock JVM 非受支持路径。
[^jint]: .NET 侧：`Microsoft.CodeAnalysis.CSharp.Scripting`（Roslyn）、Jint（纯托管 JS，含 `PrepareScript` 复用与执行限额）、ClearScript（V8）；Jint 文档声明其配置复用「**不是隔离边界**」。


### 4.7 脚本文件（`.m`）与 `import`（✔ 2026-09-25 作者）

**✔ 已裁**：**模型之外的脚本程序单独成文件，扩展名 `.m`**；**与它服务的对象放在同一个目录**（例：`data/models/mes/Order.mm` 的记录，其 `beforeXxx` / `afterXxx` 拦截器放 `data/models/mes/Order.m`）；**`.m` 里的程序可以 `import` 到别的文件里使用**（脚本是可复用单元，不是只能内嵌在模型里）。

- **判据**（与 [`project.md`](lang/project.md) §1 同口径）：**模型分片文件**（`.mm` / `.me` / `.ms` / …）正文首关键字能判出 partType；**`.m` 正文是脚本**（语句序列，没有 partType）—— 因此**扩展名不承担类型判据，内容承担**；
- **同目录 = 默认配对**：脚本文件与模型文件同目录、可通过命名与对象对应（**命名与配对的精确形态 ⏳ 待点头**：`<对象>.m` 同名配对（推荐，一眼配对）或脚本内显式声明挂到哪个对象 / 哪个事件）；
- **`import` 语义（草案形态 ⏳ 待点头）**：文件头 `import "./common.m";`（相对路径、可多行）—— 被引文件的**顶层声明**（具名函数 / 常量）进入当前文件作用域；**只允许 import `.m` 文件**（模型不是可 import 的东西）；**重名冲突 = 报错**（不做别名机制）、**循环 import = 报错**；
- **两种容器，一套语法**：内嵌脚本块（§4.5）与独立 `.m` 文件用的是**同一套表达式 / 语句语法**；独立文件用于**会被复用或较长的拦截器**，内嵌块用于**一次性的短逻辑**；
- **⚠️ 同名提示**：§4.6 能力清单里的 `import` 是**业务动作名**（「导入」动作的钩子 `beforeImport`），与本节的**语言级 `import` 语句**同字不同域（一个在能力表 / 脚本上下文里，一个在文件头）—— 是否需要更名以免歧义 ⏳ 待点头。

## 5. 缓存是横切面（不是第五层）

实测与图一致：`mmda-core-caching/` 提供 `CacheProvider.java`、`ReactiveCacheProvider.java`、`CachePolicy.java` + Redis 四个实现（`EntityCacheProvider`、`ReactiveEntityCacheProvider`、**`TenancyEntityCacheProvider`/`ReactiveTenancyEntityCacheProvider`**——已带租户隔离）。

| 规则 | 内容 |
| --- | --- |
| **单点出口** | 任何层取缓存**只能经 `CacheProvider`**（禁止各自 `new` 缓存、禁自建 Map 缓存）——ARCH-108 |
| **策略写哪（✔ 已裁 2026-09-24，§9-5）** | **设计里可以声明「默认策略」**（模型侧声明默认 TTL / 失效点），**语言级定义后续再加**（不阻塞首版）；**允许程序员用 Profile 重写**（部署/环境相关，Profile 优先）——作者原话：「缓存策略在设计里可以声明默认策略，后面加语言级定义。但是允许程序员重写 Profile」 |
| **键含租户** | 缓存键必须含租户维度（多租户项目的默认要求），失效按租户/对象/模块三级 |
| **不进真源** | 缓存不是第二真源（[`PLAN.md`](../PLAN.md) §3.2 同一口径：库与缓存都是产物）；**对账以文件与存储为准** |
| **可观测** | 命中率、失效次数、穿透告警进质量看板（[`quality.md`](quality.md) §2.3 运行期指标） |

---

## 6. 装配与聚合（图的返回路径）

| 环节 | 层 | 谁做 |
| --- | --- | --- |
| 行 → 对象 | Repository | 生成（RowMapper 类映射） |
| **关联对象、枚举和引用属性组装** | Service | **元数据驱动生成**：`@Ref`/`@Many`/枚举声明 → 生成装配（含 N+1 防护，ARCH-303） |
| **聚合** | Controller | **视图声明驱动**：一个响应要哪些对象、哪些字段，由视图/接口声明决定 |

**为什么必须生成**：关系与视图都在元数据里声明过，手写装配 = 同一件事三端各写一遍（现状：Java/C#/TS 都没有专门的装配层，散在 Service/Repository 里）。**"装配是派生物"与"用例是派生物"是同一条原则。**

**数据访问的两层：`EntityFactory` 与 `Repository`（✔ 已裁 2026-09-24，§9-6）**：作者原话：「**`EntityFactory` / `Repository` 都要**，前者更像 .Net EF，后者可基于 `EntityFactory` 实现，javaer 更习惯。**目标是消灭手写 SQL 语句，手写字符串字段名**」。

| 层 | 定位 | 关系 |
| --- | --- | --- |
| **`EntityFactory`** | 更像 .NET EF：按元数据出对象、组装查询（类型安全、无字符串字段名） | **底座能力**（新 Java 代码已引入 `mmda-core-entities` + `mmda-base-repository/BaseEntityFactory`） |
| **`Repository`** | javaer 的习惯形态（`findById` / `save` / `query`……） | **可基于 `EntityFactory` 实现**——两个都要、**分层而非替换** |

**硬目标（写进验收）**：**消灭手写 SQL 语句与手写字符串字段名**——查询条件由元数据 + 强类型表达式生成，字段名不再以字符串字面量出现在业务代码里（现状 `EntityRepository.java:509/1518` 这类手写 SQL 路径逐步收缩）。

---

## 7. 业务功能模块插件（✔ 2026-09-24：**插件的主形态**）

**作者口径（原话，2026-09-24）**：「**我说的插件是支持用户自己开发业务功能模块，至于 IDE 插件对他们没那么重要，支持更好**」。

**2026-09-24 补充口径（两条，作者原话）**：① 「**业务插件是指用户用 java, c#, ts 做的**」——插件由用户用**三端原生代码**（Java / C# / TS）实现，**不是用 m 语言或脚本写的**（m 只声明它的接入点与权限）；② 「**目前不考虑收费和市场**」——**不做收费、不做插件市场**，[`ide/plugins.md`](ide/plugins.md) §9 的市场机制**只留方向**。

### 7.1 与既有概念对齐（不新造概念）

业务功能模块插件**就是 `module`**，不是新概念：

| 已裁口径 | 与插件的关系 |
| --- | --- |
| **`module` 是一等边界**：API 边界 = 权限边界 = 文档分组边界（[`api.md`](api.md) §1.1） | 插件自带端点与 `sops`，边界与 module 一致，**语言层无需新增任何声明** |
| **热插拔 = module 粒度**（[`vision.md`](vision.md) §5.3） | 「装 / 卸一个业务插件」= 装 / 卸一个 module，判据既有 |
| **KEEP 区**（本文 §6、[`targets.md`](targets.md)）：生成一次不再覆盖 | 插件的**程序员定制代码住 KEEP 区**，平台升级不覆盖 |
| **插件只读产物 + 报对账、禁写语言文件**（[`api.md`](api.md) §1.1） | 那是对 **IDE 插件**立的边界；业务插件改的是**自己的源码区**（KEEP 区），不是元数据 |

### 7.2 包形态（按目标端）

| 目标端 | 形态 | 装载机制 |
| --- | --- | --- |
| Java | `jar`（含 KEEP 区代码 + 清单） | Spring bean 扫描 / `ServiceLoader`（隔离级别见 §9-8） |
| C# | `dll`（程序集） | 程序集加载（`AssemblyLoadContext` 隔离级别见 §9-8） |
| TS | npm 包（ESM） | 与前端 `vuix-*` 插件同机制 |

**清单 `mmda-plugin.json`**（一插件一清单，随包走）：

```json
{
  "id": "com.customer.wms",
  "version": "1.4.0",
  "kernel": ">=0.3 <1.0",
  "modules": ["wms", "wms.stock"],
  "requires": ["base", "com.vendor.erp@^2"],
  "capabilities": ["db:migrate", "event:subscribe", "api:publish"],
  "signature": "…",
  "publisher": "com.customer",
  "license": "commercial"
}
```

### 7.3 数据模型规则（硬约束，防插件互踩）

1. **可以**：在自己的 module 内新建表 / 字段 / 枚举 / 视图 / 权限 / Action / 流程，并带自己的迁移（复用既有迁移矩阵）。
2. **不可以**：改他人 module 的表结构或语义——要改走主仓变更（MR + 语言级迁移），**不给「插件偷偷给别人的表加字段」的口子**（✔ **已裁 2026-09-24，§9-10**：**不允许**；替代手段 = **扩展表 `xxx_ext`（一对一）**；**具体设计待细化**——作者原话「同意，这个得详细设计」）。
3. **跨插件引用**：走 `requires` 声明 + 对方 **API / 查询契约 / 事件订阅**；**不许直接读写对方库表**。
4. **冲突检测**：装载期检查 module id、表名、端点、权限码、事件名是否撞车——**冲突即拒载**，不静默覆盖。

### 7.4 装载与运行语义

- **装载时机**：平台启动装载 + 运行期热装载（module 粒度，与 §5.3「热插拔」同判据）。
- **隔离级别（✔ 已裁 2026-09-24，§9-8）**：**首版进程内 + 命名空间与冲突检测**（Java 侧独立 classloader / C# 侧 `AssemblyLoadContext` 都属实现细节，语言层不规定）；**进程级隔离留给「不可信第三方插件」场景**（与 [`ide/plugins.md`](ide/plugins.md) §12 的内核侧 sidecar 是一套思路）。**一个插件可含多个 module，一个 module 只属一个插件**（✔ §9-9）。
- **跨插件调用 = 跨 module 调用**：事务传播按 §9-7（默认同模块同事务、**跨模块新事务**），跨插件一致性走事件补偿（[`events.md`](lang/events.md)）。
- **升级不丢**：平台升级不覆盖 KEEP 区（有回归用例）；插件升级走迁移矩阵；**内核版本不满足则拒载**并给可行动提示（与 [`ide/plugins.md`](ide/plugins.md) §9.4 同一套兼容矩阵）。
- **签名与许可**：与市场机制共用（三级签名）；闭源行业包 / 算法库**以插件形态分发**（[`protection.md`](protection.md) §7.1）。

### 7.5 二开链路（「容易二开」的落地）

拿到生成物 + KEEP 区 → 客户 / 伙伴写业务插件（自己的 module）→ 打包（`jar` / `dll` / npm）→ 装入（本地目录 / 企业私有市场）→ **平台升级不丢，与官方 module 同权**。

### 7.6 与 IDE 插件的关系

| | **业务功能模块插件（主）** | IDE / 设计器插件（次） |
| --- | --- | --- |
| 扩展什么 | **运行时业务能力**（module：数据 + 权限 + API + 流程） | 设计工具本身（面板、图形、导入导出、模板包、**附加校验**） |
| 谁写 | 客户 / 实施方 / 伙伴的业务开发 | 工具开发者 |
| 载体 | 平台装载（`jar` / `dll` / npm） | 壳的扩展宿主（TS / Vue） |
| 优先级 | **主形态**（P4 之后即可装） | **支持更好，不做首版承诺**（[`ide/plugins.md`](ide/plugins.md) §12） |

**共用机制**：清单、签名、兼容矩阵、市场（[`ide/plugins.md`](ide/plugins.md) §9）——**一个市场，两类插件**。

---

## 8. 现状与缺口（实测）

| 事项 | 现状 | 缺口 |
| --- | --- | --- |
| 分层落地 | Java：`mmda-core-api`（Controller）/ `mmda-core-services`（Service 32 文件）/ `mmda-core-data`（`Repository.java`、`EntityRepository.java`）/ `mmda-core-caching` | 层边界没有规则守着（§2.5 的 ARCH-107…） |
| **业务 Controller** | **手写**：`mmda-mes` 74 个、`mmda-crm` 16、`mmda-hrm` 9、`mmda-foundation` 3 | 进入路径三件事应按声明生成 → 业务 Controller 应逐步消失 |
| **`EntityFactory`** | 新 Java 代码引入 `mmda-core-entities/…/EntityFactory.java` + `mmda-base/mmda-base-repository/…/BaseEntityFactory.java` | ~~与 core 的 Repository 模式并存、尚未融合~~ → **✔ 已裁 2026-09-24（§9-6）：两个都要、分层不替换**——`EntityFactory` 出对象/查询（类 .NET EF），`Repository` 可基于它实现（javaer 习惯）；**硬目标 = 消灭手写 SQL 与手写字符串字段名**（§6） |
| 拦截点 | 三层都有挂点、命名不一（§4.1） | 未上升到语言、无封闭枚举、无事外/事内语义（§3、§4） |
| 缓存 | `CacheProvider` + reactive + 租户实现齐备 | 未进 capability 契约的行为描述（键/失效/可观测） |
| 装配 / 聚合 | 无专门装配类 | 未确认为生成物 |

---

## 9. ✔ 已裁（2026-09-24，作者逐条取定；仅第 4 条待说明）

> 作者原话：「1. ts 实际上可以自定义，例如 beforeAction 可以自动看'submit'有没有 beforeSubmit，**但是 java/c# 我不想用反射**，所以程序都写在 action 里面，专门有一个 canExecute 函数。**后面统一**，现在前端 EntityAction 里面有 canDo 函数，**后续重构统一 canDo 函数，然后支持 m 语言写逻辑**，其他还是固定，例如 beforeDelete / 2. **不要新增**，标准的几个定了 beforeXxx/afterXxx，**action 走 canDo 拦截** / 3. **save 只提供给程序员方便，但是 insert, update 在服务器端还是得有** / 4. 没明白啥意思 / 5. **缓存策略在设计里可以声明默认策略，后面加语言级定义。但是允许程序员重写 Profile** / 6. **EntityFactory / Repository 都要**，前者更像 .Net EF，后者可基于 EntityFactory 实现，javaer 更习惯。**目标是消灭手写 SQL 语句，手写字符串字段名** / 7. 同意，比如 2 阶段提交或者分布式事务，这个具体实现 / 8. 可以 / 9. 同意 / 10. 同意，这个得详细设计」

| # | 议题 | 裁决（2026-09-24） | 落点 |
| --- | --- | --- | --- |
| 1 | 拦截点的语言声明形态（语法） | 挂在 **Action / 视图**上（不新造顶层 `hooks` 块）；**Action 的拦截走 `canDo`**，其余点固定 `beforeXxx`/`afterXxx`；**三端统一为 `canDo` 并支持用 m 语言写逻辑**（重构项；**Java/C# 不用反射**，TS 现状的「按名探测」不进契约） | §4.2 |
| 2 | 生命周期点是否封闭枚举 | **封闭**：标准点就是那几个 `beforeXxx` / `afterXxx`，**不要新增**；新增点走语言版本；**Action 不走 `beforeXxx`、走 `canDo`** | §4.2 |
| 3 | `save` 是否合并 insert / update | **语言语义上合并**（声明面是「保存」一件事）；**服务端仍必须有 `insert` / `update` 两个操作**——`save` 只是**给程序员的便利门面** | §4.2 |
| 4 | 存储级钩子（`store`）是否对设计师开放 | **✔ 已裁（2026-09-24，作者取 A）**：**不开放**——只给程序员（KEEP 区代码）+ 显式勾选 + 评审清单可见；**语言/模型侧不给 `store` 钩子声明语法**（作者先回「没明白啥意思」，解释见 §4.4 后取 A） | §4.4、§4.2 |
| 5 | 缓存策略（TTL / 失效）写哪 | **设计里可声明默认策略**（模型侧），**语言级定义后续再加**；**允许程序员用 Profile 重写** | §5 |
| 6 | `EntityFactory` 与 `Repository` 的关系 | **两个都要、分层不替换**：`EntityFactory` 更像 .NET EF（出对象 / 组装查询），`Repository` **可基于 `EntityFactory` 实现**（javaer 更习惯）；**硬目标 = 消灭手写 SQL 语句与手写字符串字段名** | §6、§8 |
| 7 | 事务传播规则 | **默认同模块同事务、跨模块新事务**；跨模块一致性走事件补偿；**2PC / 分布式事务属具体实现**（不排除、不在语言层承诺） | §3、§7.4 |
| 8 | 插件隔离级别 | **首版进程内 + 命名空间与冲突检测**（classloader / `AssemblyLoadContext` 属实现细节）；**进程级隔离留给「不可信第三方插件」** | §7.4 |
| 9 | 插件与 module 的粒度 | **一插件可多 module**；**一个 module 只属一个插件** | §7.2、§7.3 |
| 10 | 数据模型扩展边界 | **不允许给他人表加字段**（走主仓 MR）；用**扩展表 `xxx_ext`（一对一）**代替；**具体设计待细化**（作者：「这个得详细设计」） | §7.3 |

> **与事件总线那一侧的接口**：[`event_bus.md`](lang/event_bus.md) §15-5「**多租户隔离档**」（A 共享执行 + 租户键 / B 每租户独立作业 / C 每租户独立环境）**与本条（§9-8 插件隔离级别）不是同一件事**——§9-8 管的是**进程内 vs 进程外**，§15-5 管的是**数据面租户隔离档**；后者**仍未裁**。
