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
| `save` | 落库前 / 提交后（insert 与 update **合并**为一个点） | Service | Java `beforeInsert`/`afterInserted`/`beforeUpdate`/`afterUpdated`、TS `beforeSave`/`afterSave` |
| `delete` | 删除前 / 提交后（含批量） | Service | Java `beforeDelete`/`afterDeleted`、TS `beforeDelete`/`beforeDeleteAll` |
| `got` | 读回后、**装配前** | Service | Java `afterGot` |
| `action` | 自定义 Action 执行前后 | Service | TS `beforeAction`/`afterAction` |
| `import` / `print` / `upload` | 导入 / 打印 / 上传 | Service | TS `beforeImport`/`beforePrint`/`beforeUpload` |
| `store` | 存储级（SQL 整形、审计列） | **Repository（不对设计师开放）** | Java `EntityRepository` 的两个钩子 |

> 语境里的一切都是 `before<点>` / `after<点>`（如 `beforeSave` / `afterDelete`）——**复用现有命名，不造新词**。

### 4.3 固定模式：设计师配置 + 程序员定制

| 谁 | 干什么 | 在哪 |
| --- | --- | --- |
| **架构师 / 设计师** | **配置**：选生命周期点、顺序、生效条件（角色 / 视图 / 状态） | IDE 设计器（图形 + 清单），产物是**声明** |
| **程序员** | **定制**：实现钩子体（Java / C# / TS 三端各自的语言） | **KEEP 区 + 插件**（[`ide/plugins.md`](ide/plugins.md)），"生成一次、不再覆盖" |
| **AI Agent** | 提议钩子骨架与用例，**不签字**（[`workflows.md`](workflows.md) §6 三道闸） | 同代码路径 |

**为什么这样切**：钩子是**业务规则挂载点**（设计师能说明白"什么时候要拦一下"），但**实现必然是代码**（程序员写）——两边都别越界：**设计师不写代码，程序员不改声明**。

---

## 5. 缓存是横切面（不是第五层）

实测与图一致：`mmda-core-caching/` 提供 `CacheProvider.java`、`ReactiveCacheProvider.java`、`CachePolicy.java` + Redis 四个实现（`EntityCacheProvider`、`ReactiveEntityCacheProvider`、**`TenancyEntityCacheProvider`/`ReactiveTenancyEntityCacheProvider`**——已带租户隔离）。

| 规则 | 内容 |
| --- | --- |
| **单点出口** | 任何层取缓存**只能经 `CacheProvider`**（禁止各自 `new` 缓存、禁自建 Map 缓存）——ARCH-108 |
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

---

## 7. 现状与缺口（实测）

| 事项 | 现状 | 缺口 |
| --- | --- | --- |
| 分层落地 | Java：`mmda-core-api`（Controller）/ `mmda-core-services`（Service 32 文件）/ `mmda-core-data`（`Repository.java`、`EntityRepository.java`）/ `mmda-core-caching` | 层边界没有规则守着（§2.5 的 ARCH-107…） |
| **业务 Controller** | **手写**：`mmda-mes` 74 个、`mmda-crm` 16、`mmda-hrm` 9、`mmda-foundation` 3 | 进入路径三件事应按声明生成 → 业务 Controller 应逐步消失 |
| **`EntityFactory`** | 新 Java 代码引入 `mmda-core-entities/…/EntityFactory.java` + `mmda-base/mmda-base-repository/…/BaseEntityFactory.java` | **与 core 的 Repository 模式并存、尚未融合**（两套数据访问路径）→ 待裁 |
| 拦截点 | 三层都有挂点、命名不一（§4.1） | 未上升到语言、无封闭枚举、无事外/事内语义（§3、§4） |
| 缓存 | `CacheProvider` + reactive + 租户实现齐备 | 未进 capability 契约的行为描述（键/失效/可观测） |
| 装配 / 聚合 | 无专门装配类 | 未确认为生成物 |

---

## 8. 待裁

| # | 议题 | 建议 |
| --- | --- | --- |
| 1 | **拦截点的语言声明形态**（语法）——挂在 Action 上、挂在视图上，还是独立的 `hooks` 段 | 挂在 **Action / 视图**上（复用已有元素，不新造顶层块）；语法在语法专题定 |
| 2 | **生命周期点是否封闭枚举**（§4.2 那张表能否自定义） | **封闭**；新增点走语言版本 + 校验期拒绝未注册名 |
| 3 | **`save` 是否合并 insert/update** | 合并（对设计师是"保存"一件事）；三端实现内部自行区分 |
| 4 | **存储级钩子（`store`）是否对设计师开放** | 不开放，仅程序员（SQL 语义不是业务语义） |
| 5 | **缓存策略（TTL / 失效）写哪**：Profile 还是模型 | 写 **Profile**（运行期/环境相关，属部署档），模型里只声明"哪些读路径要缓存" |
| 6 | **`EntityFactory` 与 `Repository` 的关系** | 需要一次专门对账：二者是**替换关系**（新代码换掉旧模式）还是**分层关系**（Factory 出对象、Repository 出数据） |
| 7 | **事务传播规则**（流程跨模块调用时事务怎么传） | 默认**同模块同事务、跨模块新事务**（避免长事务锁跨模块），跨模块一致性走事件补偿（[`events.md`](events.md)） |
