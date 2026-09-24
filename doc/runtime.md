# 运行架构（Runtime）

> **为什么有这篇**：`doc/` 里已有**语言**（模型怎么写）、**目标端契约**（三端能力矩阵）、**架构评估**（设计期静态规则），缺一层——**系统跑起来时，请求在哪儿被拦、事务在哪儿开、缓存从哪儿过、装配谁来干**。这篇是「运行架构」，来源是作者 2026-09 的**概念设计图**（《分层架构》）。
> **图的定位**：**概念设计、属运行架构（runtime）**，不是代码现状的快照——图给的是**设计思路**：`Controller` = API 开放，`Service` = 商业逻辑，`Repository` = 数据读写层，**缓存 = 横切面**。
> 状态：草案（2026-09-24）· 联动 [`architecture-review.md`](architecture-review.md)（§2.5 把本文的层边界变成可机检规则）、[`targets.md`](targets.md)（L2 能力契约：事务 / 钩子 / 缓存）、[`events.md`](events.md)（`after*` 钩子的幂等）、[`meta-model.md`](meta-model.md)（Action / 视图）、[`ide/plugins.md`](ide/plugins.md)（程序员定制区）。

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
| **Controller** | **API 开放**：认证 / 授权、数据合法性校验、默认值设置、返回聚合；**对外契约（API）怎么定义与出文档见 [`api.md`](api.md)** | ❌ 不写商业规则；❌ **不得直接访问 Repository** | 视图（`ui/**/*.mi`）+ Role 的能力范围（[`meta-model.md`](meta-model.md) §8.1） |
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

**跨模块怎么办（✔ 已裁 2026-09-24，§9-7）**：**默认「同模块同事务、跨模块新事务」**（避免长事务把锁跨到别的模块）；**跨模块一致性走事件补偿**（[`events.md`](events.md)）。作者原话：「同意，**比如 2 阶段提交或者分布式事务，这个具体实现**」——**2PC / 分布式事务属实现层选项，不在语言层承诺**（模型里写不出来，实现可按部署形态选）。

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
| `store` | 存储级（SQL 整形、审计列） | **Repository（⏳ 是否对设计师开放仍待裁，§9-4 / §4.4）** | Java `EntityRepository` 的两个钩子 |

> 语境里的一切都是 `before<点>` / `after<点>`（如 `beforeSave` / `afterDelete`）——**复用现有命名，不造新词**。

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

### 4.4 `store` 级钩子是什么（⏳ §9-4 待裁，作者回「没明白啥意思」）

上面那张表里 `store` 与其它点**不是一类东西**——其它点问的是「**业务上要不要拦一下**」，`store` 问的是「**这条 SQL 要不要改一下**」：

| | 其它点（`beforeInsert` / `afterUpdate` …） | `store` 级钩子 |
| --- | --- | --- |
| 说的是什么 | **业务语义**：「插入前补个默认值 / 不满足条件就拒单」 | **存储语义**：「这条 `INSERT` 语句的列要不要动 / `WHERE` 要不要加条件 / 审计列怎么填」 |
| 住在哪 | Service（与业务逻辑同一事务，§3） | **Repository**（真正生成 SQL 的层，Java 现状 `EntityRepository.java:509 beforeInsert`、`:1518 beforeUpdate`） |
| 谁看得懂 | 设计师能说明白 | **只有懂 SQL 与表结构的人能改** |

**现在的问题**：模型声明、`@Ref`、枚举、视图已经能推出绝大多数 SQL（§6 装配、[`meta-model.md`](meta-model.md)、[`records.md`](records.md)），`store` 钩子**只在改不动模型、又必须改 SQL 时**才用（历史表列名不一致、特殊索引提示、审计列来源特殊）。**给它开放出去** = 允许在声明之外偷偷改库行为，[`quality.md`](quality.md) 的 L3「生成 DDL / SQL 逐字对账」就会失真。

**所以本条的选项只有两种**：**A（建议）不开放**——只给程序员（KEEP 区代码），且走**显式勾选**、在评审清单里可见；**B 开放给设计师**——那就要给 `store` 钩子加一套声明语法与校验（成本高、收益低）。**你选 A 还是 B？**

---

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
- **跨插件调用 = 跨 module 调用**：事务传播按 §9-7（默认同模块同事务、**跨模块新事务**），跨插件一致性走事件补偿（[`events.md`](events.md)）。
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
| 4 | 存储级钩子（`store`）是否对设计师开放 | ⏳ **仍待裁** —— 作者回「**没明白啥意思**」，需先解释（已写 §4.4，**A 不开放 / B 开放**两选）再重问 | §4.4、§4.2 |
| 5 | 缓存策略（TTL / 失效）写哪 | **设计里可声明默认策略**（模型侧），**语言级定义后续再加**；**允许程序员用 Profile 重写** | §5 |
| 6 | `EntityFactory` 与 `Repository` 的关系 | **两个都要、分层不替换**：`EntityFactory` 更像 .NET EF（出对象 / 组装查询），`Repository` **可基于 `EntityFactory` 实现**（javaer 更习惯）；**硬目标 = 消灭手写 SQL 语句与手写字符串字段名** | §6、§8 |
| 7 | 事务传播规则 | **默认同模块同事务、跨模块新事务**；跨模块一致性走事件补偿；**2PC / 分布式事务属具体实现**（不排除、不在语言层承诺） | §3、§7.4 |
| 8 | 插件隔离级别 | **首版进程内 + 命名空间与冲突检测**（classloader / `AssemblyLoadContext` 属实现细节）；**进程级隔离留给「不可信第三方插件」** | §7.4 |
| 9 | 插件与 module 的粒度 | **一插件可多 module**；**一个 module 只属一个插件** | §7.2、§7.3 |
| 10 | 数据模型扩展边界 | **不允许给他人表加字段**（走主仓 MR）；用**扩展表 `xxx_ext`（一对一）**代替；**具体设计待细化**（作者：「这个得详细设计」） | §7.3 |

> **与事件总线那一侧的接口**：[`event_bus.md`](event_bus.md) §15-5「**多租户隔离档**」（A 共享执行 + 租户键 / B 每租户独立作业 / C 每租户独立环境）**与本条（§9-8 插件隔离级别）不是同一件事**——§9-8 管的是**进程内 vs 进程外**，§15-5 管的是**数据面租户隔离档**；后者**仍未裁**。
