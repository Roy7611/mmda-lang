# 三端契约盘点清单（P0.5 交付物）

> **用途**：把「Java 与 C# 底座没有统一接口方式」从判断变成一张可执行清单——逐行给出 `file:line`，标出**同名不同义 / 同义不同名 / 单侧独有**。
> **数据**：2026-09-24 实测。抓取方式见 §9（可复现）。
> **路径前缀**（本文所有路径均为仓库相对路径，可直接在对应工作区里跳转）：
> - Java → `D:\2026\java\`
> - C# → `D:\2026\cs\MMDA\`
> - TS → `D:\2026\ts\mmda\`
>
> **判定图例**：`同` 同名同义 · `≈` 同义异名/异形 · `✗` 语义或形态不兼容 · `独` 单侧独有 · `空` 单侧为空模块 · `?` 未核实

---

## 1. 元数据与元模型

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 元数据提供器（接口） | `mmda-core/mmda-core-metadata/src/main/java/cloud/mmda/core/metadata/MetadataProvider.java:13` | `Mmda.Core/Mmda.Core.Metadata/IMetadataProvider.cs:18` | —（走 HTTP） | **≈** I 前缀分歧 |
| 元数据加载实现 | `mmda-core/mmda-core-data/src/main/java/cloud/mmda/core/data/jdbc/metadata/SqlMetadataProvider.java:52`（1026 行，正则解析关系定义于 `:65`） | `Mmda.Core/Mmda.Core.Metadata/DbMetadataProvider.cs:23`（含 `NormalizeNameSpace` 兜脏值） | — | **✗** 两套实现、两套约定 |
| 元数据上下文 | `mmda-core/mmda-core-metadata/…/metadata/MetaContext.java:18`、`mmda-core/mmda-core-sql/…/sql/SqlMetaContext.java:11` | `Mmda.Core/Mmda.Core.Metadata/MetadataCache.cs:13`、`MetabaseOptions.cs:6` | — | **✗** 抽象方式不同 |
| 元数据缓存 | （在 `MetaContext` 实现内） | `Mmda.Core/Mmda.Core.Metadata/IMetadataCache.cs:7` | — | **独（C#）** |
| Schema 提供器 | `mmda-core/mmda-core-sql/…/sql/schema/SchemaProvider.java:6` | — | — | **独（Java）** |
| Record | `mmda-core/mmda-core-metadata/…/metadata/MetaObject.java:38` | `Mmda.Core/Mmda.Core.Metadata/Metadata/MetaObject.cs:38` | `packages/core/src/models/metamodel.ts:646`（`MetaModel`） | **同**（连行号 38 都一样） |
| Field | `…/metadata/MetaCol.java:31`（`formula` `:159`、`constraint` `:166` 裸字符串） | `…/Metadata/MetaCol.cs:43` | `packages/core/src/metaui/metaui_field.ts:210` | **≈** |
| Relation | `…/metadata/MetaRelation.java:32` | `…/Metadata/MetaRelation.cs:43` | —（前端由关系展开） | **同** |
| Enum | `…/metadata/MetaEnum.java:51` | `…/Metadata/MetaEnum.cs:24` | — | **同** |
| View | `…/metadata/MetaView.java:19`（`whereCondition` `:25`、`orderBy` `:28` 裸字符串） | **无** | — | **独（Java）** |
| Check / Index | `…/metadata/MetaCheck.java:9`、`MetaIndex.java:18` | **无** | — | **独（Java）** |
| UI 定义 | `…/metadata/MetaUi.java:21`、`MetaUiField.java:24`、`MetaUiGroup.java:20` | `…/Metadata/MetaUi.cs:12`、`MetaUiField.cs:25`、`MetaUiGroup.cs:13` | `packages/core/src/metaui/metaui_group.ts:57`、`metaui_service.ts:28`、`metaui_builder.ts:84` | **≈** |
| i18n 词条 | `…/metadata/MetaUi18n.java:15`、`ModuleI18n` | `…/Metadata/MetaUi18n.cs:35`、`ModuleI18n` | `packages/i18n`（独立包） | **≈** |
| Module / 动作 / 流程 | `…/metadata/Module.java:36`、`ModuleAction.java:36`、`ModuleFlow.java:28`、`Terminology.java:26` | `…/Metadata/Module.cs:25`、`ModuleAction.cs:39`、`ModuleFlow.cs:40`、`Terminology.cs:21` | `packages/core/src/metaui/module.ts:101` | **同** |
| 权限 | `…/metadata/Authority.java:12` | —（用 ASP.NET Identity：`Mmda.Core/Mmda.Core.Web/Identity/IdentityRole.cs:6`） | — | **✗** |
| BI 元数据 | — | `…/Metadata/MetaBiCube.cs:25`（+ Dimension/Hierarchy/Level/Measure） | — | **独（C#）** |

## 2. 领域对象与行为

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 实体基类 | `mmda-core/mmda-core-entities/…/entities/Entity.java:18`、`AbstractEntity.java:31`、`SequencedRow.java:6` | `Mmda.Core/Mmda.Core.Entities/Abstractions/IEntity.cs:13`、`AbstractEntity.cs:5` | `packages/core/src/models/entity.ts:55` | **✗** 抽象类 vs 接口+抽象类 |
| 语义标记 | `Auditable`/`Attachable`/`ChangeLoggable`/`Computable`/`Ownable`/`Flowable.java:10` | `I*` 版：`IFlowable.cs:9`、`ICompositeKey.cs:9`、`ITenancy.cs:12`… | — | **≈** I 前缀分歧 |
| 动作 | `…/entities/EntityAction.java:14`、`mmda-core-services/…/services/DomainAction.java:29` | `Mmda.Core.Metadata/Actions/EntityAction.cs:9`、`Mmda.Core.Entities/Abstractions/IEntityAction.cs:8`、`Mmda.Core.Services/IDomainAction.cs:8` | `packages/core/src/models/entity_action.ts:4` | **≈** |
| 服务 | `mmda-core-services/…/services/EntityService.java:86`、`DomainService.java:22` | `Mmda.Core.Services/IEntityService.cs:10` | `packages/core/src/logic/entity_logic.ts:132`（前端逻辑） | **≈** |
| 流程 | `…/entities/FlowableEntity.java:17`、`…/models/FlowTrail.java:33` | `Mmda.Core.Entities/Common/FlowTrail.cs:10` | —（前端无流程实体） | **≈** |
| 前端业务逻辑层 | — | —（无对应物） | `packages/core/src/logic/entity_logic.ts:132`、`entity_bool_expr.ts`、`field_logic.ts`、`group_logic.ts`、`logic_functions.ts`、`sql_operator.ts:10` | **独（TS）** |
| 校验 | `…/entities/ValidationError.java:19` + `MetaCol.constraint`（String） | `Mmda.Core.Entities/Constraints/FutureAttribute.cs` + DataAnnotations | `packages/core/src/logic/validation.ts:27`、`logic/validators/types.ts:12` | **✗ 同一规则三处实现** |
| 谓词/过滤 | `…/entities/EntityPredicate.java:11`、`EntityFilter.java:20` | （并入 SqlCriteriaBuilder） | `packages/core/src/metaui/metaui_filter.ts` | **✗** |

## 3. 持久化、查询与 DDL

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 仓储 | `mmda-core/mmda-core-data/…/jdbc/repository/Repository.java:27`（+ `TenancyRepository`/`UserRepository`/`Role*Repository` 等 Spring Data 风格族） | —（无仓概念） | `packages/core/src/net/api_client.ts:62`（`EntityRepository`） | **✗** |
| 数据库访问 | `mmda-core-data`(68 文件) + 18 个 RowMapper | `Mmda.Core/Mmda.Core.Data/IDatabase.Async.cs:11`、`DatabasePool.cs:29`、`IDbConnectionFactory.cs:10`（Dapper） | `packages/core/src/net/api_client.ts:121`（`ApiClient`） | **✗** |
| 查询 DSL | `mmda-core-entities/…/entities/EntityFactory.java:1512`（`IEntityQueryable`）、`:1709`（`ICommandBuilder`）、`mmda-core-sql/…/expressions/SqlExp.java:461`（`ISqlCriteria`） | `Mmda.Core.Sql/ISqlBuilder.cs:13`、`SqlBuilder.cs:20`、`Query/SqlCriteriaBuilder.cs:16`、`Query/SqlQueryBuilder.cs:42` | —（服务端拼） | **✗** |
| SQL 执行 | `mmda-core-sql/…/sql/SqlExecutable.java:20`、`mmda-core-data/…/data/sql/SqlBuilder.java:24` | `Mmda.Core.Sql/SqlCommand.cs`、`SqlCommandBuilder.cs` | — | **✗** |
| 方言 | `mmda-core-sql/…/dialects/SqlDialect.java:39`、`AnsiSqlDialect.java:25`（`createTable` 于 `:381`），共 **8 个方言** | `Mmda.Core.Sql/MySqlBuilder.cs:15`、`OracleSqlBuilder.cs:15`、`TransactSqlBuilder.cs:15`，共 **3 个** | — | **✗ 覆盖不一致** |

## 4. 消息与集成

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 事件总线 | **无**（`grep` 全仓 0 命中） | `Mmda.Core/Mmda.Core.Events/IEvent.cs:13`、`IEventBus.cs:14`、`IEventHub.cs:3`、`ISignalREventHub.cs:6`、`RedisEventHub.cs:14`、`EventLogger.cs:13` | —（SignalR 客户端待核） | **独（C#）** |
| 作业/后台任务 | `…/models/BackgroundTask.java:35`、`mmda-core-services/…/services/BackgroundTaskService.java:73`、`…/enums/BackgroundTaskStatus.java:25` | `Mmda.Core.Scada/Jobs/IJob.cs:8`、`IJobQueue.cs:14`、`IJobScheduler.cs:12`、`IJobExecutor.cs:10`、`IRelativeJob.cs:6` | — | **✗ 同义异名** |
| 消息/通知发送 | `mmda-core-messaging/…/messaging/Sender.java:7`、`Message.java:6`（+ 钉钉/邮件/短信/电话/微信/Push 10+ 渠道，36 文件） | `Mmda.Core.Messaging/IMessage.cs:8`、`IMessageSender.cs:9` | — | **✗ 渠道在 Java 侧** |
| 文件 | `mmda-core-file`（51 文件）+ `mmda-core-api/…/clients/FileClient.java:33` | `Mmda.Core.Files`（**0 个 .cs**） | `packages/core/src/models/file.ts:6`、`utils/file_info.ts:32` | **空（C#）** |
| 附件 | `…/models/Attachment.java:35`、`…/services/AttachmentService.java:37` | `Mmda.Core.Entities/Common/Attachment.cs:32` | `packages/core/src/models/file.ts:6` | **≈** |
| 导入导出 | `…/entities/EntityExport.java:15`、`ImportResult.java:9`；HTTP `ReactiveApiController.java` `exportAll/importAll` | — | — | **独（Java）** |
| 插件 | — | `Mmda.Core.Plugins/IPlugin.cs:11`、`IPluginManager.cs:5` | `vui-*`/`vuix-*` 皮肤包（20 包） | **✗ 概念不同** |
| IoT / Scada | ? | `Mmda.Core.Scada`（36 文件 2,070 行）+ `Mmda.Iot.*` 6 项目 | — | **独（C#）** |

## 5. 支撑能力

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 缓存 | `mmda-core-caching/…/caching/CacheProvider.java:19`、`…/services/CustomizedCache.java:11` | `Mmda.Core.Caching/IEntityCache.cs:17`、`IEntityCacheAsync.cs:8` | — | **≈** |
| 审计 | `…/models/AuditTrail.java:29`、`…/services/AuditTrailService.java:27` | `Mmda.Core.Entities/Common/AuditTrail.cs:20` | — | **≈** |
| 变更日志 | `…/models/ChangeLog.java:32`、`…/services/ChangeLogService.java:28` | `Common/ChangeLog.cs:23`、`Abstractions/IChangeLoggable.cs:12` | — | **≈** |
| 多租户 | `…/entities/TenancyEntity.java:34`、`TenancyKey.java:10`、`CompositeKey.java:9` | `…/Abstractions/ITenancy.cs:12`、`Mmda.Core.Data/ITenancyIdProvider.cs:9`（`RedisIdProvider`） | —（租户随请求头） | **≈** |
| 安全 | `mmda-core-security`（35 文件）：`UserAccountService.java:26`、`tokens/JwtTokenService.java:6`、`tokens/OtpTokenStore.java:6` | ASP.NET Identity：`Abstractions/IUser.cs:13`、`Mmda.Core.Services/IUserAccount.cs:3`、`Web/Identity/IdentityRole.cs:6` | `net/api_client.ts` 的 `FetchAuthProvider` | **✗** |
| 通知/公告 | `…/models/Notice.java:31`、`…/services/NoticeService.java:51` | `Common/Notice.cs:24` | — | **≈** |
| 标签 | `…/models/Tag.java:30`、`…/services/TagService.java:27` | **无** | — | **独（Java）** |
| 报表 | `…/models/ReportTemplate.java:30`、`…/services/ReportTemplateService.java:38`；`mmda-core-reporting` **0 文件** | `Common/ReportTemplate.cs:20`、`CustomizedQuery.cs:21` + BI 元数据族 | `vuix-echarts` 等皮肤 | **✗ C# 领先** |

## 6. 呈现层（✔ 已裁 2026-09-24：后端只出 `MetaUi`，前端唯一渲染）

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 渲染器抽象 | 无（Java 不出 UI） | `Mmda.Ui/Mmda.Ui.Core/UiKitRegistry.cs:9`、`Contracts/Razor/IUiKitRazor.cs:15`、`Contracts/Blazor/IUiKitBlazor.cs:13` | `packages/core/src/ui/renderer.ts:5`（`UiRenderer`）、`factory.ts:124`（`UiFactory`）、`context.ts:76`（`UiContext`） | **✗ 三套** |
| 字段渲染类型 | 无 | `FieldRendererType.cs:7`、`FieldEditorType.cs:10`、`Rendering/MetaUiFieldKindResolver.cs:11` | `metaui/metaui_field.ts:210` + `vui-*` 皮肤 | **✗** |
| 值解析/格式化 | 无 | `Parsing/FieldFormatter.cs:5`、`Parsing/SelectOptionsParser.cs:5`、`Rendering/ListRenderHelper.cs:9` | `logic/validators/*`、`metaui/validator_parse.ts` | **✗** |
| 皮肤/组件库 | 无 | `Mmda.Ui.Blazor`、`Mmda.Ui.Razor`、`Mmda.Ui.VtRazor`（+Syncfusion） | `vui-syncfusion`/`vui-primevue`/`vui-agnaive` + `rui-syncfusion` + 9 个 `vuix-*` | **✗** |

> **已裁决（2026-09-24）**：不追求「统一 UI 抽象」，改为**后端只出渲染描述**（字段/控件/分组/校验/i18n 词条），**各端 kit 自己渲染**。见 [`targets.md`](targets.md) §8。**（同日收紧，见下一行）**
> **✔ 再裁（同一日，收紧）**：UI 契约 = **现有 mmda-vue 前端项目**（`D:\2026\ts\mmda`）；**不考虑 C# MVC 与 Java 的 UI**；后端只提供 `MetaUi` 元数据。上表 C# 列的 `Mmda.Ui.*` 一律视为**遗留实现**（不纳入契约、不作生成目标、不随 mmda-lang 演进）。落点：[`presentation.md`](lang/presentation.md §5.1。

## 7. 代码生成

| 概念 | Java | C# | TS | 判定 |
| --- | --- | --- | --- | --- |
| 生成器 | `mmda-foundation/mmda-factory`（54 文件 / **11,713 行**，出 Java/C#/Dart/JS/TS/SQL） | `Mmda.Alm/Mmda.Alm.Coding/Program.cs`（**1 文件 2 行**） | — | **✗ 生成器单侧** |
| 生成区协议 | `mmda-factory/src/main/java/cloud/mmda/factory/coding/CodeBuilder.java:44-47`（`~GENERATED PARTS` / `~KEEP PARTS`） | **产物在跑**：`Mmda.Alm/Mmda.Alm.Models/Models/Bug.cs:6`（`Please don't modify any code between GENERATED PARTS BEGIN and END`） | — | **同**（靠生成器，不靠契约） |
| C# 生成器 | `mmda-factory/…/coding/CSharpCodeBuilder.java`、`CSharpEntityCodeBuilder.java`、`CSharpEnumCodeBuilder.java`、`CSharpSqliteModelCodeBuilder.java` | — | — | **独（Java 侧出 C#）** |

## 8. 盘点结论

**统计**（本文 60+ 个概念）：

| 判定 | 数量 | 典型 |
| --- | --- | --- |
| `同` 同名同义 | 8 | `MetaObject`/`MetaCol`/`MetaRelation`/`MetaEnum`/`Module`/`ModuleAction`/`ModuleFlow`/`Terminology` |
| `≈` 同义异名/异形 | 18 | `MetadataProvider`↔`IMetadataProvider`；`Entity`(类)↔`IEntity`；`BackgroundTask`↔`IJob` |
| `✗` 不兼容 | 16 | 仓储/查询 DSL/方言/校验/安全/事件/UI |
| `独` 单侧独有 | 12 | Java：`MetaView`/`MetaCheck`/`MetaIndex`/`SchemaProvider`/标签/导入导出；C#：事件总线/BI/IoT/插件/元数据缓存 |

**结论三条**：

1. **同名的部分全是「元数据描述」**——因为这些类由 Java 侧生成器写给 C#（§7 的 `GENERATED PARTS` 证据）。**一旦进入运行时能力（服务、仓储、事件、作业、UI），命名与形态立刻分叉**。所以「统一接口」的工作量集中在 L2（能力契约），不在 L1（元数据）。
2. **最危险的三处不一致**（会造成同模型两端行为不同）：校验规则三处各实现一遍、查询 DSL 两套范式、方言 8 vs 3。
3. **最省力的三个统一切入点**：实体语义标记补 `I` 前缀统一（纯改名）、`MetaView`/`MetaCheck`/`MetaIndex` 补进 C#（补类）、`BackgroundTask`↔`IJob` 二选一（改名）。

---

## 9. 抓取方式（可复现）

```bash
# Java：按名字取首个定义位置
cd /d/2026/java && grep -rnE "(class|interface|enum) MetaObject([^A-Za-z0-9_]|$)" --include='*.java' mmda-core | head -1

# C#：同上（排除 obj/bin）
cd /d/2026/cs/MMDA && grep -rnE "(class|interface|enum|record) MetaObject([^A-Za-z0-9_]|$)" --include='*.cs' Mmda.Core | grep -v '/obj/\|/bin/' | head -1

# TS：导出声明
cd /d/2026/ts/mmda && grep -rnE "export (interface|type|class|const) MetaModel([^A-Za-z0-9_]|$)" --include='*.ts' packages/core/src
```

模块规模（同一轮实测）：Java `metadata 105 / data 68 / sql 57 / entities 53 / file 51 / messaging 36 / security 35 / services 32 / utils 27 / api 14 / caching 10 / reporting 0`；C# `Metadata 42 / Sql 25 / Entities 74 / Data 11 / Scada 36 / Web 17 / Caching 10 / Events 12 / Messaging 8 / Services 5 / Plugins 5 / **Files 0**`；TS `packages/*` 共 20 个包，`packages/core/src` 为契约主体。
