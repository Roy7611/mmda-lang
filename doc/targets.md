# 目标端契约（Targets）

> **为什么有这份文档**：`PLAN.md` P6（代码生成）之前必须先冻结「生成物落在哪、对着什么契约生成」。
> 现状是「Java 的 `mmda-factory` 替 C# 写实体代码」，这正是 `doc/readme.md` 里 m 语言要替代的耦合。
> 本文实测日期 **2026-09-24**，命令与数字都可复现（见 §7）。

---

## 1. 三端的角色与边界

**不是「三语言底座」，是 2 个后端 + 1 个前端**：

| 端 | 位置 | 角色 | 与 m 语言的关系 |
| --- | --- | --- | --- |
| 后端 A（Java） | `D:\2026\java\mmda-core` | 元数据解释执行、DDL、接口/实体生成（`mmda-foundation/mmda-factory`） | 消费 IR；生成 Java 产物；实现能力契约 |
| 后端 B（C#） | `D:\2026\cs\MMDA\Mmda.Core` | 同层底座（.NET 10 + Dapper + MySQL + Redis + Blazor） | 消费 IR；生成 C# 产物；实现能力契约 |
| 前端（TS） | `D:\2026\ts\mmda`（`@mmda/core` + `vui*`/`rui*` 皮肤） | 渲染与交互，消费后端 HTTP 接口；**UI 的唯一实现**（后端不出 UI） | 消费 IR 的**呈现子集**（`MetaUi` / UiField / 类型 / 校验规则） |

**共契约的部分**：领域模型、元数据、校验规则、动作与状态机、事件、DDL/SQL 语义、国际化词条。
**不共契约的部分**：持久化实现、DI/事务、HTTP 栈、UI 渲染树——这些是语言本地的，m 语言只声明「要什么」，不规定「怎么做」。

---

## 2. 契约分三层，各归其位

| 层 | 内容 | 归属 | 产物 |
| --- | --- | --- | --- |
| **L1 元数据与领域模型** | record / enum / view / 字段 / 关系 / 模块 / 动作 / 事件声明 | **Rust 内核**（m 源 → IR → 校验 / 序列化 / 生成） | 三端各自的元数据加载代码 + 实体/枚举/类型/DDL |
| **L2 能力契约** | 元数据提供器、实体服务、仓库、查询 DSL、校验、动作执行、**事务边界、生命周期钩子（拦截点）**、**API 文档（OAS 3.1.0 原生生成 + 契约测试 + mock 数据；含 `decimal` / 超界整数用 `string` 的序列化约定）**、事件总线、**事件端点与数据流编排（底座 ESB；引擎可替换，语义对齐 Flink 模型）**、作业、消息、文件、缓存、租户、DDL、UI 渲染 | **各语言自己实现**，接口由生成器从 m 产出 | 三端各自的接口/抽象类 + 底座实现 |
| **L3 一致性验证** | 同一份 `.mmda` + 同一组用例，两端行为必须一致 | 各语言自己跑（Rust 内核提供用例与期望数据） | 一致性测试套件 = **「统一接口」的可执行定义** |

**结论**：Rust 统一的是 L1 与 L3 的**输入**；L2 统一不了实现，只能统一**契约形态 + 语义**。想要「Java 与 C# 接口方式一致」，手段是**生成器 + 一致性测试**，不是写一份接口文件让大家抄。

---

## 3. 能力标记（capability）与分档

> **已裁决（2026-09-24）：本草案的 capability 语法照此进语言。** 依据见 [`contracts-inventory.md`](contracts-inventory.md) §8（能力不对等是常态，必须显式声明）。

三端能力不对等是常态（见 §4）。规则：

1. m 源里**不写实现**，只声明能力开关与目标端：
   ```sql
   target java  capability events, jobs, file, ddl(8)
   target csharp capability events, jobs, scada, bi   // 无 file、无 ddl(postgres)
   target ts    capability ui(rendering), logic(validators)
   ```
2. 生成器发现「语言用到的事件能力，目标未声明」→ **生成期报错**（不是静默降级、不是生成空方法）。
3. 底座补齐能力后，改一行 capability 即可开闸——**能力矩阵是唯一开关点**，不许在模板里写 `if (target == "csharp")` 这类散落条件。

### 3.1 算法宿主（草案，见 [`protection.md`](protection.md)）

核心算法（例如物流调度）**不放 Java/C#**：`.class` / IL 带完整元数据，反编译可还原接近源码的结构。capability 因此增加一档「算法宿主」：

```sql
target java   capability algorithm(logistics-scheduler: native, abi: c)
target csharp capability algorithm(logistics-scheduler: native, abi: c)
target ts     capability algorithm(logistics-scheduler: wasm, scope: check-only)
```

语义：语言只声明**算法契约**（输入/输出结构 + 约束字段 + 保护档），**算法体在 Rust 仓、不进任何交付仓**；三端只生成薄适配（Panama / P/Invoke / WASM 加载器）+ 许可校验骨架，跨边界传参直接用 FlatBuffers（B5）。保护等级同样是声明项（`protection native-stripped, license(...)`），不散落在模板里。详见 [`protection.md`](protection.md)。

---

## 4. 三端能力对照矩阵（实测）

图例：`✓` 有 · `≈` 同义异名/异形 · `-` 该端无 · `?` 本次未核实

| 能力域 | Java（`mmda-core`） | C#（`Mmda.Core`） | TS（`@mmda/core`） | 状态 |
| --- | --- | --- | --- | --- |
| 元数据提供器 | `MetadataProvider`、`DbMetadataProvider`、`MetaContext`、`SqlMetaContext` | `IMetadataProvider`、`IMetadataCache`、`DbMetadataProvider`、`MetabaseOptions` | `metamodel.ts`（仅类型，数据来自后端） | **≈**：Java 无 `I` 前缀 |
| 元数据模型 | `MetaObject`/`MetaCol`/`MetaRelation`/`MetaEnum`/`MetaView`/`MetaUi*`/`Module*`/`Terminology`（105 文件） | 同名子集（42 文件）+ `MetaBiCube/Dimension/Hierarchy/Level/Measure` | `metaui/metaui_field.ts` 等 | **≈ 但覆盖面不同**：C# 少一半类名，多 BI 族 |
| 实体基类 | `Entity<K>`（抽象类）、`AbstractEntity`、`SequencedRow` | `IEntity`、`AbstractEntity` | `models/entity.ts` | **≈ 异形**：类继承 vs 接口 |
| 实体语义标记 | `Auditable`/`Attachable`/`ChangeLoggable`/`Computable`/`Ownable`/`Flowable`/`CompositeKey` | `IAuditable`/`IAttachable`/`IChangeLoggable`/`IComputable`/`IOwnable`/`IFlowable`/`ICompositeKey` | （前端不体现） | **≈ 命名分歧**：一个带 `I`、一个不带 |
| 实体服务/动作 | `EntityService`、`DomainService<T,K>`、`DomainAction<T,K>`、`EntityAction`、`FlowableEntityService` | `IEntityService`、`IDomainAction`、`IEntityAction` | `entity_action.ts`、`logic/entity_logic.ts` | **≈** |
| **生命周期钩子（拦截点）** | `EntityService.java` 的 `beforeValidate:337`/`beforeInsert:378`/`afterInserted:388`/`beforeUpdate:650`/`afterUpdated:658`/`afterGot:878`/`beforeImportValidate:2433`；Controller `beforeQuery:1292`；Repository `EntityRepository.java:509/1518`（+ 租户版） | （`IEntityService` 同族待核） | `logic/entity_logic.ts:171 beforeLoad`/`:175 beforeValidate`/`:183 beforeSave`/`:185 afterSave`/`:199 beforeAction`/`:201 afterAction`/`:207 beforeDeleteAll` | **✗ 命名与粒度不一**（统一口径见 [`runtime.md`](runtime.md) §4） |
| **API 文档 / OpenAPI** | **无**（`pom.xml` 无 springdoc/springfox/swagger；`@Operation/@Tag/@Api` **0 个**） | `Swashbuckle.AspNetCore 6.9.0` 已引入（`Mmda.Iot/Mmda.Iot.Server/Mmda.Iot.Server.csproj:20`），但**0 处注解使用** | - | **✗ 三端都缺**：口径见 [`api.md`](api.md)——**OAS 3.1.0 原生生成**（内核一等后端，过官方 Schema 校验，不靠注解）+ **mock 数据两层造数**（机械 + AI），工具只做消费者 |
| 持久化 | Spring Data 风格 `Repository<T,K>` 接口族（`TenancyRepository`/`UserRepository`/…）+ `data`(68 文件) 与 RowMapper | 手写 `Database`/`IDatabase`/`DatabasePool`（Dapper）+ `IDbConnectionFactory` | `net/api_client.ts`（只走 HTTP） | **✗ 两套范式** |
| 查询 DSL | `IEntityQueryable`/`IEntitySource`/`IEntityFilter`/`IQueryWhere`/`ISqlCriteria`/`ICommandBuilder`/`IUpdateSetter`（57 文件 `sql` 模块） | `ISqlBuilder`/`SqlQueryBuilder`/`SqlCriteriaBuilder`/`SqlCommandBuilder` | `metaui/metaui_filter.ts` | **✗ 完全不同** |
| DDL / 方言 | `dialects/` **8 个**（`AnsiSqlDialect` 为基） | `Sql` 模块 **3 个**（MySql / Oracle / TransactSql） | - | **✗ 覆盖不一致** |
| 事件 | **无**（`grep 'class EventBus\|interface IEventBus\|@Event'` 0 命中） | `IEvent`/`IEventBus`/`IEventHub`/`ISignalREventHub`/`RedisEventHub`/`EventLogger`（12 文件），IoT 侧 `ScadaEventBus` 在用 | - | **✗ 单侧独有** |
| 异步作业 | `BackgroundTask`/`BackgroundTaskStatus`/`BackgroundTaskService` | `IJob`/`IJobQueue`/`IJobScheduler`/`IJobExecutor`/`IRelativeJob` | - | **✗ 同义异名** |
| 消息通知 | `Sender<T>` + 钉钉/邮件/短信/阿里云电话/微信/Push 等 10+ 渠道（36 文件） | `IMessage`/`IMessageSender`（实现覆盖 `?`） | - | **?** |
| 文件 | `mmda-core-file` **51 文件**（`FileClient`、`AttachmentService`、`ImportResult`） | `Mmda.Core.Files` **0 个 .cs（空壳）** | `models/file.ts` | **✗ 单侧缺失** |
| 缓存 | `CacheProvider`/`ReactiveCacheProvider`/`CachePolicy` + Redis 四实现（含 **`TenancyEntityCacheProvider` 租户版**）/`CustomizedCache(Service)` | `IEntityCache`/`IEntityCacheAsync` + `Caching`(10 文件) | - | **≈**；作为**横切面**的用法与单点出口规则见 [`runtime.md`](runtime.md) §5 |
| 审计与变更 | `AuditTrail`/`ChangeLog`/`FieldChange`/`ChangeWrapper`/`ChangeLogService` | `AuditTrail`/`ChangeLog`/`IChangeLoggable`/`FlowTrail` | - | **≈** |
| 安全/权限 | `mmda-core-security` 35 文件（`JwtTokenService`、`OtpTokenStore`、`Authority`、`Role*Repository`、`RoleDataAuth`/`RoleUiAuth`） | `IUser`/`IUserAccount`/`IdentityRole` + ASP.NET Identity | `net/api_client.ts` 里的 `FetchAuthProvider` | **? 未对齐** |
| 多租户 | `Tenancy`/`TenancyKey`/`CompositeTenancyKey`/`TenancyEntity`/`TenancyRepository` | `ITenancy`/`ITenancyIdProvider`/`RedisIdProvider` | `TenancyKey` | **≈** |
| 报表 / BI | `mmda-core-reporting` **0 文件**（模块空）；`ReportTemplate` 在 entities 里 | `ReportTemplate`、`CustomizedQuery`、`MetaBiCube/Dimension/Hierarchy/Level/Measure` | `vuix-echarts` 等皮肤 | **✗ C# 领先** |
| 校验规则 | `MetaCol.constraint`(String) + `ValidationError` | `Constraints/*Attribute` + DataAnnotations | `logic/validators/*`（number/string/datetime/collection/registry） | **✗ 同一份规则三处实现** |
| **MetaUi 元数据（UI 契约本体）** | `MetaUi.java:21`/`MetaUiField.java:24`/`MetaUiGroup.java:20`/`MetaUi18n.java:15` + 4 个 RowMapper | `MetaUi.cs:12`/`MetaUiField.cs:25`/`MetaUiGroup.cs:13`/`MetaUi18n.cs:35` | `packages/core/src/metaui/*`（8 文件 **2,626 行**） | **✔ 契约本体：后端产出、前端唯一消费** |
| UI 渲染契约 | 无（Java 不出 UI） | `Mmda.Ui.Core`：`IUiKitRazor`/`IUiKitBlazor`/`UiKitRegistry`/`FieldRendererType`/`FieldEditorType`/`FieldFormatter`/`MetaUiFieldKindResolver` | `@mmda/core` 的 `ui/renderer.ts:5`/`ui/factory.ts:124`/`ui/context.ts:76` + `vui*`(Vue) + `rui*`(React) | **✔ 已裁：只保留 TS 前端**（C# `Mmda.Ui.*` 为遗留实现） |
| IoT / Scada | `?` | `Mmda.Core.Scada` 36 文件 + `Mmda.Iot.*` 6 项目（Modbus / PLC / Scada / Automation） | - | **? 疑单侧** |
| 插件 | `?` | `IPlugin`/`IPluginManager`/`Plugins`(226 行) | `vuix-*`/`vui-*` 皮肤包 | **概念不同**：后端插件 vs 前端皮肤 |
| 代码生成 | `mmda-foundation/mmda-factory` 54 文件 / **11,713 行**（出 Java、C#、Dart、JS、TS、SQL） | `Mmda.Alm.Coding` **1 文件 2 行（空）** | - | **✗ 生成器单侧** |
| **算法 / 重计算载体** | 与业务代码同程序集（JVM 字节码，可反编译） | 同（IL，可反编译） | 前端包内（JS，可读） | **✗ 三端都无 native 边界** → 见 [`protection.md`](protection.md) |
| 元数据存储 | MySQL `mmda_metadata` 库（18 张 `meta_*` 表，`SqlMetadataProvider` 读取） | 同一库（`DbMetadataProvider`），README 明示需 `NormalizeNameSpace` 兜 `cloud.mmda.base.models` 之类小写脏值 | - | **✗ 同一真源两套约定，已在运行时打补丁** |

**最关键的一条证据**：C# `Mmda.Alm\Models/Models/Bug.cs` 头部写着

```
Please don't modify any code between GENERATED PARTS BEGIN and END
```

而生成器在 Java 侧（`CodeBuilder.java` 的 `KEEP PARTS`/`GENERATED PARTS` 协议 + `CSharpCodeBuilder` / `CSharpEntityCodeBuilder` / `CSharpEnumCodeBuilder` / `CSharpSqliteModelCodeBuilder`）。
**即：C# 的实体是 Java 生成给它的。两端"看起来同构"不是契约的功劳，是生成器的功劳**——一自己动手（Events）词汇就分叉了。

---

## 5. 一致性测试口径（L3）

定义「统一」的唯一可执行方式：

1. **输入**：一份 `.mmda` 项目（含模型、动作、事件、校验、DDL 期望）。
2. **用例集**：由 Rust 内核生成，纯数据驱动（JSON/FlatBuffers），不写各语言手写断言。
3. **判定**：同一用例在三端跑，**产物必须一致**——字段序列化、校验错误码、状态转移的合法/非法结果、事件投递次数与顺序、生成 DDL 的规范化文本、多租户隔离的数据可见性、**标识符命名（类型名 / 属性名 / 事件名 / 消息头名逐字对账，口径见 [`naming.md`](naming.md) §2）**。
4. **门禁**：一致性套件不过 → 不许合入底座仓（Java `D:\2026\java`、C# `D:\2026\cs\MMDA`）。

**第一批必过用例（建议顺序）**：CRUD → 校验错误码 → 状态转移（含非法转移拒绝）→ 动作执行与副作用顺序 → 租户隔离 → DDL 规范化 → 事件投递（Java 补齐总线后）。

---

## 6. 建议的统一顺序（把差距变成有先后的清单）

| 优先 | 统一项 | 理由 |
| --- | --- | --- |
| 1 | 元数据模型类名与字段（`MetaObject`/`MetaCol`/…） | 三端已在用同名类，只差字段级对齐；是 IR 的落点 |
| 2 | 实体语义标记命名（`Auditable` vs `IAuditable`） | 纯命名，改动小，马上消除「同义异名」 |
| 3 | 校验规则（`constraint` / Attribute / validators） | 现在三处实现，是**最可能出现行为不一致**的地方 |
| 4 | 事件声明与投递语义 | C# 有实现、Java 是空白，正好按新契约做（不要各自造） |
| 5 | 查询 DSL / 持久化 | 范式差异最大、成本最高，放在有 IR 之后 |
| 6 | UI 渲染契约 | **✔ 已裁两次（2026-09-24）**：先定「后端只出渲染描述、各端 kit 自己渲染」，再收紧为「**UI 契约 = 现有 mmda-vue 前端项目**；不考虑 C# MVC 与 Java 的 UI；后端只提供 `MetaUi` 元数据」——见 §8-2/§8-4；C# `Mmda.Ui.*` 列为遗留 |
| 7 | 报表与 BI | C# 领先，Java 空模块，可由 C# 先出契约再回填 Java |

---

## 7. 数据来源（可复现）

本次实测命令（Windows git-bash）：

- C#：`find D:/2026/cs/MMDA -name '*.cs' -not -path '*/obj/*' -not -path '*/bin/*' -exec cat {} + | wc -l` → **70,831 行 / 762 文件**
- C#：`find Mmda.Core -name 'I*.cs'` → 45 个接口；`head -22 Mmda.Alm/Mmda.Alm.Models/Models/Bug.cs` → `GENERATED PARTS BEGIN`
- Java：`for d in mmda-core/*/; do find $d -name '*.java' | wc -l; done` → metadata 105 / data 68 / sql 57 / entities 53 / file 51 / messaging 36 / security 35 / services 32 / utils 27 / api 14 / caching 10 / **reporting 0**
- Java：`grep -rh 'public interface' --include='*.java' mmda-core` → 见 §4 各行
- Java：`grep -rln 'class EventBus\|interface IEventBus\|@Event' --include='*.java' mmda-core` → **空**
- TS：`for p in packages/*/package.json; do grep -m1 '"name"' $p; done` → 20 个包；`packages/core/src` 结构见 §4

---

## 8. ✔ 已裁决（2026-09-24）

三条已于 2026-09-24 拍定，逐行盘点依据见 [`contracts-inventory.md`](contracts-inventory.md) §8：

| # | 议题 | 裁决 |
| --- | --- | --- |
| 1 | **能力标记语法** | **按 §3 草案进语言**。能力是显式声明，生成器按声明分档；语言用到而目标未声明的能力 → **生成期报错**（不静默降级、不生成空方法）。 |
| 2 | **UI 契约** | **不统一 UI 抽象**：后端只出**渲染描述**（字段/控件/分组/校验提示/i18n 词条），各端 kit 自己渲染（C# `Mmda.Ui.*`、TS `vui-*`/`rui-*`）。渲染描述里不许出现框架专属概念。落点：`presentation.md` §5.1。**（同日收紧，见本表第 4 条）** |
| 3 | **一致性测试跑在哪** | **由 Rust 内核统一驱动**（`mmda test --target java,csharp,ts`），用例由内核生成、纯数据驱动。理由：裁决与运行在同一处，避免出现第三份「测试方言」。落点：`PLAN.md` P9 / `mmda-test` crate。 |
| 4 | **UI 契约（收紧）** | **UI 契约 = 现有 mmda-vue 前端项目**（`D:\2026\ts\mmda`）；**不考虑 C# MVC 与 Java 的 UI**；**后端只提供 `MetaUi` 元数据**（Java `MetaUi.java` 族 / C# `MetaUi.cs` 族，各一份薄适配）。UI kit 不进后端契约、不进 m 语言；一致性测试的 UI 维度只测 TS 侧；`capability ui` 只在 `target ts` 声明。落点：`presentation.md` §5.1、本文 §4。 |
| 5 | **愿景四裁（对目标端的影响）** | ① **open core**：规范 + 内核 + IDE 壳 + 三端薄适配开源（**全栈 MIT**，✔ 2026-09-24 由「规范 MIT / 内核 Apache-2.0」统一为 MIT），算法库与行业包闭源；② **国产化全三级承诺**（L1 数据层方言 / L2 国产 OS 与 CPU / L3 无商业控件皮肤），与本文 `capability` 机制**正交**——capability 管「目标端支持什么」，国产化管「跑在什么基础设施上」；③ **微服务 / 容器化 / 热插拔 / 高可用只是部署方式**，语言层零新增，P5 只出单体拓扑 + `Dockerfile`，微服务拓扑留 P8；④ **Syncfusion 只是可选皮肤**，自研国产皮肤（naive-ui + 表格插件）与 `vui` / `rui` 并列。**L2 目标矩阵亦已裁**：x86_64 + aarch64 双架构（海光 / 兆芯 + 鲲鹏 / 飞腾；龙芯不进验收矩阵）、验收 OS = 麒麟 V10 SP3 + 统信 UOS V20（CI 基线 openEuler LTS）、JDK = 毕昇 21 + 上游 OpenJDK 21、**设计器不进国产 OS**、交付 = 离线包 + `mmda doctor`——见 [`vision.md`](vision.md) §5.2.1。落点：[`vision.md`](vision.md) §5。 |

| 6 | **移动端 = Flutter（✔ 2026-09-24 方向已裁）** | 移动端宿主走 **Flutter**（Dart 生成物，与 P6 的「+Dart/JS」一致；不做响应式 Web 与小程序路线）。**对本文件的冲击**：`MetaUi` 将出现**第二个渲染方**（Flutter），本文第 4 条「`capability ui` 只在 `target ts` 声明」需重开——见 [`vision.md`](vision.md) §8-6、[`errata.md`](errata.md) §三-26。**首版仍不做移动端**，排 P8 之后。 |

已随之落到各处的连带改动：§6 的统一顺序里第 6 项（UI 渲染契约）两次收紧后**不再是"要不要统一"也不是"渲染描述里放什么字段"，而是「`MetaUi` 里放什么字段」**——因为渲染方只剩一个（mmda-vue）。**注：本条已因移动端 Flutter 方向（本表第 6 条）待重开——将来 `MetaUi` 会有第二个渲染方。**
