# m 语言（MMDA 元模型驱动架构语言）— 落地计划

> v1.14 · 2026-09-24
> 语言规范草稿在 `doc/`；**前一轮尝试的全部资产在 `E:\Dev\mmda-architect`**（见 §2.3）。
> 已拍定决策见 §0，未决项见 §6，**2026-09-24 的九条新裁决见 §6.3**。
> 语法细节按你的要求**另开专题逐个讨论**，本文只固定工程与架构口径。
> **目标端契约**见 [`doc/targets.md`](doc/targets.md)，**逐行对照清单**见 [`doc/contracts-inventory.md`](doc/contracts-inventory.md) —— 两者是 P6 的前置。

---

## 0. 决策台账

| # | 决策 | 含义 |
| --- | --- | --- |
| A1 | 定位：**架构/设计 DSL 为主** | 声明层是主体；表达式层受限且纯函数；业务逻辑仍写 Java/C#/TS |
| A2 | 实现：**Rust 单实现 + C ABI / WASM 两个面** | C 只出现在对外头文件 |
| A3 | 第一步：**元数据 → 项目文件的反向导出器** | 先要「打印器」不要 parser |
| A4 | **数据库降级为部署目标与运行时缓存** | 文件（git/svn）是 SSOT；库仍用于运行时改配置、批量改、部署 |
| B1 | **`mmda-factory` 用 Rust 重写**，m 语言可生成 TS / Java / C# 等 | 从「接管输入」升级为「重写生成器」 |
| B2 | 元数据**既可存文件也可存库** | 文件便于转换/拷贝/导入导出；IDE 要支持**多语言映射编辑**（VS 资源编辑器式）；元数据要**细粒度版本控制**并集成 git/svn |
| B3 | **事件层由 Java / C# 各自实现底座** | m 只抽象接口：声明领域事件、可写脚本、生成各语言实现 |
| B4 | 多租户差异：**分文件 include**，为特定租户定义扩展文件 | 复用项目清单现有 `items[]` include 机制，不新增概念 |
| B5 | 跨语言 IR：**先实现 FlatBuffers**，另两种格式后置 | protobuf / CBOR+CDDL 保留为可插拔编码 |
| B6 | 宿主目标语言：**Java、C#、TS** | 但角色不同：Java / C# 是**后端底座**，TS 是**前端运行时**（见 §2.5、§3.4） |
| B7 | **DDL 与跨数据库方言生成放在 Rust 里做** | 不再依赖 Java 侧渲染 |
| B8 | 语言文件后缀 **`*.mmda`**（原案） | **✔ 已裁决（§6.3-1）**：改为**保族 + 解析器按内容首关键字判 partType**，`.mmda` 只表示项目清单 |
| — | 删除 `D:\2026\java\mmda-lang\` | 已完成，归档在 `%LOCALAPPDATA%\hermes\cache\archive\java-mmda-lang-2026-09-24\` |
| — | 新定位：**m 同时是元数据真源与跨语言契约真源** | 起因：Java 与 C# 两套底座「没有统一接口方式」（见 §2.5、§3.10） |
| — | ✔ capability 语法 / UI 契约 / 一致性测试归属 | 2026-09-24 裁决，见 §6.3-2/3/4 |
| — | ✔ P0.5 契约盘点已完成 | 交付物 `doc/contracts-inventory.md`（60+ 概念逐行 `file:line`） |
| ✔ 2026-09-24 | **建仓并接入远端** `github.com/Roy7611/mmda-lang`（**公开仓**，MIT）；首提交 `0679a30` 推入（57 文件 / doc 9,353 行） | 作者建远端后落定；**行尾 CRLF、许可 MIT 两项待你确认**（§7） |

---

## 1. 目标与非目标

### 1.1 目标

1. 一门声明式语言：描述存储架构、数据流设计、事件与行为，产出**语言无关的元模型 AST/IR**。
2. `.mmda` 项目（展开目录）是**唯一真源**：进 git/svn、可 review、可合并、可细粒度回溯。
3. **m 是跨语言契约的真源**：元数据、领域模型、校验规则、动作与事件语义只写一遍，各端从同一份源生成、按同一组用例验证一致（`doc/targets.md`）。
4. 一个 Rust 内核：解析、校验、变更日志、DDL、代码生成、包归档（`pack/unpack`）。
5. IR 可被 **Java / C# / TS** 宿主加载：元数据在宿主内可加载、校验、求值。
6. 一个 IDE（Tauri + Vue，前一轮已有壳）：**图形与脚本两条等价编辑通道**、多语言映射编辑、AI 可调用（MCP/CLI）。

### 1.2 非目标（明确不做）

- ❌ 不做通用编程语言（无标准库/GC/IO 运行时）；业务逻辑写在 Java / C# / TS。
- ❌ **不用 Rust 统一业务实现**：事务、ORM、DI、HTTP、序列化、事件投递都是语言本地的；Rust 统一的是元数据与契约描述（L1）与一致性验证的输入（L3），不是 L2 的实现（`doc/targets.md` §2）。
- ❌ 不引入 ANTLR / 语法生成器。本仓两次教训：`mmda-lang/` 672 行 `.g4` 全废；`mmda-core-sql` 的 3 个 `.g4` + 12 个生成类（59020 行）正在被删除。
- ❌ 不用 C 手写内核；不做 C + Rust 双实现（两套语义必然漂移）。
- ❌ 不做「文件与库互为真源」：库是产物/缓存，库侧编辑必须经 §3.2 的回写通道回到文件。
- ❌ 事件总线、重放、Exactly Once 由 Java/C# 底座实现（`doc/events.md:97-102` 的机制不在 Rust 内核里重造）。
- ❌ 不做后端 UI（§6.3-3 → **同日收紧为 §6.2-19**）：**UI 契约 = 现有 mmda-vue 前端项目**，不考虑 C# MVC 与 Java 的 UI，**后端只产出 `MetaUi` 元数据**。

---

## 2. 资产与现状（实测 2026-09-24）

### 2.1 `D:\2026\rust`（本轮起点 + 文档合并结果）

| 内容 | 状态 |
| --- | --- |
| 早期根文档 `readme.md` / `datatypes.md` / `events.md` | 2026-06 的早期设计，**已作为根保留并合并扩展** |
| 早期空壳 `statements.md`（8 字节）/ `presentation.md`（0 字节） | **已补齐**：语句/表达式/行为、呈现层（UiField/i18n/五视图/渲染契约） |
| 本轮新增根文档 | `index.md`、`records.md`、`meta-model.md`、`project.md`、`glossary.md`、`errata.md`、`targets.md`、`contracts-inventory.md` |
| 迁入的分支文档 | `doc/ide/`（8 篇工具与 IDE 规格）、`doc/ai/`（2 篇）、`doc/legacy/`（4 篇）、`doc/guide/`、`doc/templates/`、`doc/design-notes.md`（原 36 KB 设计笔记） |
| 留档 | `doc/archive/2026-06/`（13 篇被合并的原文，可 diff 校验未丢内容） |
| `IDEA.md` | 一行：「MMDA 元模型驱动架构语言」 |
| 版本控制 | ✔ **已接入 git**：远端 `github.com/Roy7611/mmda-lang`（**公开仓**，MIT），本地 `main` 与 `origin/main` 同步（首提交 `0679a30`） |

### 2.2 `D:\2026\java`（后端 A：现有运行时与服务端）

| 事实 | 证据 |
| --- | --- |
| 元数据真源 = 库中 18 张表 | `mmda-core/mmda-core-data/src/main/java/cloud/mmda/core/data/jdbc/metadata/mappers/` 18 个 RowMapper（MetaDb/MetaObject/MetaCol/MetaDataType/MetaEnum/MetaRelation/MetaUi/MetaUiField/MetaUi18n/MetaUiFieldI18n(t) + Module/ModuleAction/ModuleAuth/ModuleFlow/ModuleI18n/ModuleSkewer/Terminology） |
| 加载器 | `SqlMetadataProvider.java`（1026 行）；`:222` `select * from <metadataDb>.<Table>`、`:238` MetaCol、`:244` MetaRelation、`:534` MetaCol ⨝ MetaUiField |
| **元数据里已有「字符串迷你语言」** | `SqlMetadataProvider.java:65` 用正则解析关系定义：`relationType relativeObj(cols) AS name WHERE (…) GROUP BY x SHAPE LIST READONLY ONETIME` ← m 语言要顶掉的首个对象 |
| 元模型对象 | `mmda-core-metadata` 105 个 java 文件；`MetaObject`/`MetaCol`/`MetaRelation`/`MetaEnum`/`MetaCheck`/`MetaIndex`/`MetaUi*` |
| 模块与规模 | api 14 / caching 10 / data 68 / entities 53 / file 51 / messaging 36 / metadata 105 / security 35 / services 32 / sql 57 / utils 27；**reporting 0（空模块）** |
| 裸字符串表达式（灰区） | `MetaCol.java:159 formula`、`:166 constraint`；`MetaView.java:25 whereCondition`、`:28 orderBy` |
| 代码生成器 | `mmda-foundation/mmda-factory`：54 文件、**11713 行**手写 StringBuilder 生成器（Java/C#/Dart/JS/TS/SQL 五栈）；`CodeBuilder.java:44-47` 的 `~GENERATED PARTS` / `~KEEP PARTS`；`CodeFileWriter.java:57-86` 只替换生成区、保留手写区 |
| 生成器未接线 | 全仓仅 `mmda-foundation/pom.xml:17` 的 `<module>` 引用，无模块依赖 |
| 元数据生成元数据 | `mmda-factory/.../metadata/MetaUiGenerator.java:319/376/418` 直接 `insert into metauifield / MetaUiFieldI18n / MetaUi18n`（硬编码 MySQL 语句） |
| DDL 能力有两处 | `mmda-core-sql/.../dialects/` 8 个方言，入口 `AnsiSqlDialect.java:381 createTable(...)`；另有 factory 的 4 个 `SqlTableCreator` |
| **无事件总线** | `grep -rln 'class EventBus\|interface IEventBus\|@Event' --include='*.java' mmda-core` → **0 命中**；`mmda-core-messaging` 36 文件全是通知发送器（钉钉/邮件/短信/电话/微信/Push） |
| HTTP 通道 | `ReactiveApiController.java:246` `/metaUi`、`:255` `/metaUiPack`、`:278-308` `exportAll/importAll` |
| 前端消费 | `D:\2026\ts\mmda\packages\core\src\models\metamodel.ts`（693 行）+ `src\metaui/*` |

### 2.3 `E:\Dev\mmda-architect`（**前一轮尝试，能跑，不是空壳**）

| 内容 | 实测 |
| --- | --- |
| Rust 工作区 | `crates/mmda-core`（`project/model/lang/package/validate/error`，1556 行）+ `crates/mmda-cli`（143 行）= **1699 行** |
| CLI | `mmda open / validate / list-records / pack / unpack`（`crates/mmda-cli/src/main.rs`） |
| 归档格式 | `.mmdax` = ZIP（`package.rs` 493 行），目录 ↔ 包 1:1 |
| 规范文档 | `doc/` **35 篇**（已并入本仓 `doc/`，原文留档 `doc/archive/2026-06/`）+ 根 `mmda-workflow.md`（36 KB → 本仓 `doc/design-notes.md`） |
| 项目格式 | **formatVersion 2.0**：工作区目录 + `{projectCode}.mmda` 清单（JSON）+ 一对象一文件（`doc/project.md`，403 行原文） |
| 扩展名族 | `.mmda`(清单) `.ma`(模块) `.mm`(record/view) `.me`(enum) `.ms`(STM) `.mr`(role) `.mc`(converter) `.mf`(flow) `.mi`(UI) `*.g`(图形投影) `.mmdax`(归档) |
| 真实语料 | `examples/mmda-mes/`：**381 个文件** —— 215 `.mm`、113 `.me`、41 `.ms`、2 `.ma`、2 `.ma.g`、1 `.mi`、1 `.mmda`、`changelog/000001.json`、`codegen/profiles/*.yaml` |
| 反向导出工具 | `tools/reverse_mmda_project.py`（**1196 行 Python**，直连 `mmda_metadata` MySQL 生成上述语料）+ `inspect_metadata.py`(156) + `_inspect_fk.py`(16) |
| IDE 壳 | `apps/architect-desktop`（Tauri）+ `apps/architect-ui`（Vue 3 + Syncfusion），六步工作流 |
| 版本控制 | **该目录不是 git 仓库**（只有 `.gitignore`） |
| 变更日志 | `changelog/000001.json`：`seq/at/author/refKind/refKey/changes[]` |

### 2.4 ⚠️ 五处已存在的口径冲突（集中记录在 [`doc/errata.md`](doc/errata.md)）

| # | 冲突 | 状态 |
| --- | --- | --- |
| 1 | **语法两套**：早期文档形态 vs 实际语料形态。`doc/readme.md:64` `ref Partner as customer`、`:41` `indexed #(d{11})`、`:84` `@Action pay(NEW->PAYED)`；语料 `data/models/base/Address.mm` 用 `@Ref Country(countryCode,fullName)`、`@PartitionID [10000,0x000F_FFFF]`。语料统计：`@Ref` 90 文件、`@Many` 48、`@Computed` 28、`@State` 41、`@Index` 117、`@Id` 82；而 `ref ` **0**、`computed` **0**、`@Action` **0**、`#ge(` **0** | **待裁**（P2 开工前必须定） |
| 2 | **`.ma` 是 JSON 还是 M 语言**：旧文档说「所有 `.ma`–`.mi` 文件正文为 M语言方言」（`subsystem mes in Erp { module M.03 … }`）；实际 `examples/mmda-mes/biz/mes.ma` 是 **JSON**（`{"name":"Mes","$schema":"https://mmda.dev/schemas/ma-module/v1",…}`） | **待裁** |
| 3 | **`.mmda` 后缀已被占用**：现有设计里 `.mmda` = 项目清单（JSON），语言分片是 `.mm/.me/.ms/.mi`；B8 要求「语言文件 `*.mmda`」与之冲突 | **✔ 已裁**：保族 + 内容首关键字判 partType（§6.3-1） |
| 4 | **动作/事件形态两套**：`doc/readme.md:84` `@Action pay(NEW->PAYED)`；语料用 `.ms`：`stm BomApproval on Bom.status { action approve { transition CERTIFIED->APPROVED, } }`（`data/stms/mes/BomApproval.ms`），`@Action` 在语料 0 命中 | **待裁** |
| 5 | **字符串长度/可空的四种写法**：`varchar?[30]`、`varchar(15)`、`varchar?(30)`、语料 `varchar(80)` | **待裁**（建议 `type(size)` + 尾 `?`） |

### 2.5 `D:\2026\cs\MMDA`（后端 B：C# 底座）

| 事实 | 实测 |
| --- | --- |
| 规模 | **762 个 `.cs` / 70,831 行**，.NET 10 + Dapper + MySQL 8 + Redis 7 + Blazor；`MMDA.slnx`（VS 2026） |
| 版本控制 | 外层是 **SVN 工作副本**（`.svn/`），但 `Mmda.Core/` 内**嵌了一个独立 git 仓**（3 个提交，最新 `79682cb Import Mmda.Core .NET 10 source tree`） |
| 模块 | `Mmda.Core`：Metadata 42 文件 4,928 行 / Sql 25 文件 3,635 行 / Entities 74 文件 3,584 行 / Data 11 文件 2,211 行 / Scada 2,070 行 / Web 1,059 行 / Caching 944 / Events 12 文件 664 / Messaging 562 / Services 343 / Plugins 226；**Files 0 个 `.cs`（空壳）** |
| 元数据类名 | 与 Java **同名**：`MetaObject`/`MetaCol`/`MetaRelation`/`MetaEnum`/`MetaUi`/`MetaUiField`/`MetaUi18n`/`MetaUiGroup`/`MetaDataType`/`MetaDb`/`Module`/`ModuleAction`/`ModuleFlow`/`Terminology`/`EntityAction`，另有 BI 族 `MetaBiCube/Dimension/Hierarchy/Level/Measure`；接口 `IMetadataProvider`/`IMetadataCache`，实现 `DbMetadataProvider` + `MetabaseOptions` |
| **有事件总线** | `IEvent`/`IEventBus`/`IEventHub`/`ISignalREventHub`/`RedisEventHub`/`EventLogger` + DI 扩展 + SignalR 宿主；IoT 侧 `Mmda.Iot.Scada/Events/ScadaEventBus.cs` 已在用 |
| UI 契约（**遗留**，不纳入契约） | `Mmda.Ui.Core` 612 行：`IUiKitRazor`/`IUiKitBlazor`/`UiKitRegistry`/`FieldRendererType`/`FieldEditorType`/`FieldFormatter`/`MetaUiFieldKindResolver`；`Mmda.Ui.*` 含 Blazor / Razor / VtRazor（+Syncfusion） |
| DDL 方言 | 只有 3 个：`MySqlBuilder`/`OracleSqlBuilder`/`TransactSqlBuilder`（Java 是 8） |
| 通知 | `IMessage`/`IMessageSender`（Java 侧 10+ 具体渠道） |
| 作业 | `IJob`/`IJobQueue`/`IJobScheduler`/`IJobExecutor`/`IRelativeJob`（Java 侧叫 `BackgroundTask*`） |
| IoT/Scada | `Mmda.Iot.*` 6 个项目（Modbus / Plc / Scada / Automation / Server）+ `Mmda.Core.Scada` |
| **实体是 Java 生成的** | `Mmda.Alm/Mmda.Alm.Models/Models/Bug.cs:6` 头：`Please don't modify any code between GENERATED PARTS BEGIN and END` ← 与 Java `mmda-factory` 的 `CodeBuilder.java` 同一协议；生成器是 Java 侧的 `CSharpCodeBuilder`/`CSharpEntityCodeBuilder`/`CSharpEnumCodeBuilder`/`CSharpSqliteModelCodeBuilder`；`Mmda.Alm.Coding` 本身只有 1 文件 2 行（空） |
| 元数据读取漂移 | 该仓 README：`MetaObject.nameSpace` 仍可能为 `cloud.mmda.base.models` 等小写形式，运行时由 `DbMetadataProvider.NormalizeNameSpace` 自动映射 → **同一张元数据库、两套约定，已在运行时打补丁** |

**结论**：两端「看起来同构」不是契约的功劳，是**生成器的功劳**（Java 生成 C# 实体）。一旦 C# 侧自己动手（Events、Jobs、BI、Scada），词汇立刻分叉——这正是 §3.10 要解决的问题。逐行盘点见 [`doc/contracts-inventory.md`](doc/contracts-inventory.md)：60+ 概念里 `同` 8 项、`≈` 18 项、`✗` 16 项、`独` 12 项。

---

## 3. 架构

### 3.1 存储形态：文件是 SSOT，库是部署目标

```
        编辑期 ─────────────────────────────────────────────┐
  .mmda 项目目录（git/svn，一对象一文件，细粒度 diff）        │
        │  mmda parse / validate / fmt                      │
        ▼                                                   │
   元模型 AST ──▶ IR（FlatBuffers，B5）                      │
        │ emit                          ▲                   │
        ▼                               │ import --db（回写）│
  ┌────────────────────────────────────────────────────────┐
  │ ① 元数据库（部署目标 / 运行时缓存 / 批量改配置）        │
  │ ② DDL（各数据库方言，B7）                               │
  │ ③ 代码骨架（Java / C# / TS，B1）                        │
  │ ④ 图形投影 *.g、文档、i18n                              │
  └────────────────────────────────────────────────────────┘
```

- **文件形态**支持转换、拷贝、导入导出、评审、AI 读写（B2 原话）。
- **库形态**支持运行时改配置、批量改、部署（B2 原话）。
- 一对象一文件已由现行格式给出（`doc/project.md` §6），天然契合「细粒度版本控制 + git/svn」。

### 3.2 库 → 文件的回写通道（调和 A4 与 B2）

库允许改，但**改了必须回到文件并进版本控制**，否则漂移重现：

1. `mmda import --db`：库 → 项目文件，带 `diff` 预览与逐对象对账。
2. 每次回写追加 `changelog/NNNNNN.json`（现有结构 `seq/at/author/refKey/changes[]`），使「谁改的、改了哪个对象」可追溯。
3. CI/保存时门禁：库状态与项目文件 `checksum`（`doc/project.md` 的 `parts[].checksum`）不一致即报错。

### 3.3 Rust 工作区（在 `mmda-core` 上扩展，不从零）

| crate | 职责 | 现状 |
| --- | --- | --- |
| `mmda-core` | 项目加载、AST、模型、校验、变更日志、包归档 | 已有 1556 行，需扩解析与模型 |
| `mmda-syntax`（新） | 词法/语法/AST/span 诊断；**按内容首关键字判 partType**（§6.3-1），扩展名仅作提示与图标 | 待建（`lang.rs` 仅 192 行，只够骨架） |
| `mmda-ir`（新） | IR + FlatBuffers schema（B5） | 待建 |
| `mmda-emit-ddl`（新） | 各数据库方言 DDL（B7） | 待建；与 Java 8 方言 + C# 3 方言对账 |
| `mmda-codegen`（新） | 重写 `mmda-factory`：Java / C# / TS（+Dart/JS 后备），保留 GENERATED/KEEP 协议；**按目标 capability 分档**（§6.3-2） | 待建；旧实现 11713 行可当规格 |
| `mmda-import`（新） | `--db` 反向导入（Rust 重写 1196 行 Python） | 待建 |
| `mmda-test`（新） | 一致性测试驱动：`mmda test --target java,csharp,ts`（§6.3-4） | 待建，P9 |
| `mmda-abi`（新） | C ABI（cdylib）+ WASM：`parse/check/emit/eval` + 诊断 | 待建，P4 |
| `mmda-cli` | `open/validate/list-records/pack/unpack/import/generate/fmt/test` | 已有 143 行 |
| `mmda-mcp`（后置） | MCP 工具 `mmda_validate` / `mmda_generate`（`doc/ai/tools.md` 已规划） | 待建 |

### 3.4 三个宿主的落地形态（B6）

| 宿主 | 角色 | 加载 IR 的方式 | 消费方 |
| --- | --- | --- | --- |
| Java（后端 A） | 元数据解释执行 + DDL + 出码 | Panama（`java.lang.foreign`，JDK 21 起）优先，JNI 退路 | `mmda-core-metadata` 的 `MetaObject`/`MetaContext`；`MetadataProvider` 换源 |
| C#（后端 B） | **已有底座**（`D:\2026\cs\MMDA`，70,831 行） | C ABI（P/Invoke） | `Mmda.Core.Metadata` 的 `MetaObject` 等（与 Java 同名）；`IMetadataProvider` 换源 |
| TS（前端） | **前端运行时**，不是后端底座 | WASM（`wasm-bindgen` / `wasm32-unknown-unknown`） | `@mmda/core` 的 `metamodel.ts` 同形对象 + `metaui/*` + `ui/UiRenderer` |

⭐ 纠正口径：不是「三种语言各有一个对等底座」。**后端底座是 Java 与 C# 两个**（各自实现元数据加载、持久化、事件），**TS 是消费后端 HTTP 契约的前端**（`@mmda/core` + `vui*`(Vue) + `rui*`(React) + 9 个 `vuix-*` 插件，共 20 个包）。
→ 生成目标是「2 后端 + 1 前端」三类产物；契约矩阵与能力分档见 `doc/targets.md`。

**✔ 再收紧（2026-09-24）**：**UI 契约 = 现有 mmda-vue 前端项目**（`D:\2026\ts\mmda`）；**不考虑 C# MVC 与 Java 的 UI**；**后端（Java / C#）只产出 `MetaUi` 元数据**（Java `MetaUi.java` 族 / C# `MetaUi.cs` 族），`Mmda.Ui.*` 与任何后端 UI 尝试列为**遗留实现**（不纳入契约、不作生成目标）。落点：[`doc/presentation.md`](doc/presentation.md) §5.1。

### 3.5 IR 与二进制（B5）

- FlatBuffers 先行：schema 化、零拷贝、三语言都有官方运行时。
- IR 版本号写进 schema，IDE/宿主据此判兼容。
- protobuf / CBOR+CDDL 保留为可插拔编码，`mmda-abi` 只暴露「解析/校验/编译/求值」四动词 + 诊断数组。

### 3.6 DDL（B7）

- 方言差异用**数据表**描述（m 语言或项目内声明文件），编译期生成 Rust 映射，避免「Java 8 方言 + C# 3 方言 + Rust N 方言」三份手写实现漂移。
- 与 `AnsiSqlDialect.java:381 createTable` / 4 个 `SqlTableCreator` / C# `MySqlBuilder`/`OracleSqlBuilder`/`TransactSqlBuilder` 逐条对账（P5 验收）。

### 3.7 事件层（B3）——两侧起点不对等

实测：**C# 有总线**（`IEventBus`/`RedisEventHub`/`ISignalREventHub`/`EventLogger`，IoT 侧已在用），**Java 侧连概念都没有**（`mmda-core-messaging` 只是通知发送器）。

因此顺序调整：**先由 m 语言冻结事件契约（声明 + 投递语义 + 重放/Exactly Once 口径），再让 Java 按契约补齐、C# 按契约对齐**——不要以任何一侧的现有实现为事实标准，否则 Java 侧会被 C# 的实现细节绑架。

- m 只声明：`event`、`channel`、`subscriber`、`action`、状态机（现有 `.ms` 形态）。
- 语言层归 `doc/events.md`。
- 生成物：两侧的接口 + 实现骨架 + 一致性用例（`doc/targets.md` §5 第 4 项）。

### 3.8 多租户 / 多环境（B4）

复用项目清单的 `items[]`（VS ItemGroup 风格 include/exclude）与「按模块拆文件」机制：租户/环境差异 = 额外 include 文件（如 `data/models/{tenant}/X.mm`），不新增语言概念。

### 3.9 IDE 需求输入（B2 → P7）

- **多语言映射编辑**：对象的标签/翻译/UiField（`MetaUi18n`、`MetaUiFieldI18n`）与各栈生成目标并排编辑，形态参考 VS 资源编辑器。
- **细粒度版本控制**：一对象一文件 + `changelog/` + git 原生集成；svn 无本地暂存与合并模型，需专门设计（§6.2-5）。
- **图形与脚本是两条等价通道**：语义 SSOT 唯一（AST/IR），文本与图形都是它的视图、双向等价；只有布局（位置/颜色/路由）存 `*.g`。图形编辑产生 AST patch，再 emit 回语言文本——**不是「图形是语言的投影」**（该表述已在文档合并轮修正）。
- **按角色验收 IDE**：P7 的可用性判据按 [`doc/workflows.md`](doc/workflows.md) 的五类角色路径走（架构师 7 步 / 设计师 8 步 / 程序员 6 步 / AI Agent 三道闸协议 / 业务人员经 AI 审语义）；`.cursor/rules` 与 `conventions.md` 承载 AI 的允许-禁止清单。
- **全生命周期而非编辑器**：IDE 覆盖需求 → 架构 → 设计 → 编码 → 测试 → 验收 → 运维 → 退役八个阶段，每段有入口、证据物与门禁，并靠**追溯链**串起来（详见 [`doc/quality.md`](doc/quality.md) §5；面板清单可直接当 P7 验收项）。

### 3.10 契约分层与一致性

| 层 | 内容 | 归属 | 产物 |
| --- | --- | --- | --- |
| **L1** 元数据与领域模型 | record / enum / view / 字段 / 关系 / 模块 / 动作 / 事件声明 | **Rust 内核**（m → IR → 校验/序列化/生成） | 各端元数据加载代码 + 实体/枚举/类型/DDL |
| **L2** 能力契约 | 元数据提供器、实体服务、仓库、查询 DSL、校验、动作执行、事件总线、作业、消息、文件、缓存、租户、DDL、UI 渲染 | **各语言自己实现**，接口由生成器产出 | 各端接口 + 底座实现 |
| **L3** 一致性验证 | 同一份 `.mmda` + 同一组用例，各端行为必须一致 | **Rust 内核统一驱动**（§6.3-4） | 一致性测试套件 = 「统一接口」的可执行定义 |

- **能力不对等用 capability 声明**（已裁决，§6.3-2），缺失即生成期报错，不静默降级。
- 盘点事实（60+ 概念，逐行 `file:line`）：[`doc/contracts-inventory.md`](doc/contracts-inventory.md)。

### 3.11 测试与验收（AI 时代的能力要求）

- **用例从声明长出来**：字段类型/长度/可空、唯一与主键、`@Ref` 引用、STM 迁移图、`role × action × scope`、流程网关、Converter 映射、capability —— 全是可判定契约，`mmda test-gen` 能**机械生成**（不需要 AI）；只有声明不出来的业务语义才用 AI 生成草稿。
- **AI 生成 → 人审用例 → 冻结为验收标准**：审的是**用例**（业务人员看中文验收单、设计师看可测性），不是审代码；AI 用例必须带 `reviewedBy` 才计入验收；AI 不得自评通过、不得改已冻结的基线。
- **三层验收物**：① 可执行用例（`mmda test --target java,csharp,ts`）② 中文验收单（`mmda accept`，业务签字）③ 契约快照差异（架构师确认变更是有意的）。
- **覆盖率按声明维度算**（字段 / 迁移 / 权限 / 能力 100%，需求 ≥ 90%），并用**变异测试**反查用例有效性（存活变异 = 用例缺口 → 自动回填草稿）。
- 详规见 [`doc/testing.md`](doc/testing.md)；阶段落点：把 P9 从「一致性套件」扩为「一致性 + 验收」（§4），且机械用例的生成能力**随 P2/P3 的校验规则一起长**，不等到 P9。
- **AI 增强能力**（[`doc/testing.md`](doc/testing.md) §4.1 / §6.1 / §6.2）：用例生成、测试数据工厂、用例自愈、失败诊断、用例优先级、属性/模糊测试、变异回填、**用例质量评分**（黄金/普通/草稿分层）、覆盖率看板（含**变更覆盖**与**缺陷回溯覆盖**）、中文验收单生成——共 10 项。护栏：AI 只能提议、产出必须带出处、质量分与覆盖率**不作验收依据**；**首版只上纯机械四项**（孤儿检测、变更覆盖、弱断言检测、变异），AI 项后置（它们需要这四项当裁判）。

### 3.12 质量模型与自动评估

- **骨架**：ISO/IEC 25010（2023 版 9 特性：功能适合性 / 性能效率 / 兼容性 / 交互能力 / 可靠性 / 安全性 / 可维护性 / 灵活性 / 安全），把它逐项映射到**元模型里真能算出来的信号**（例：视图字段有没有 `@Index`、`@Many` 是否出现在列表视图、敏感字段是否被打进列表/导出、不可逆迁移是否有二次确认声明）。
- **可判定性分级 A/B/C/D** 是核心机制：A 设计期静态、B 生成后可判定、**C 运行期实测、D 只能人评**；A/B 进硬门禁，C 进发布前仪式，D 进 AI 报告 + 人签字，并持续把 D 往 A/B 迁移（质量目标值必须写成可判定声明，否则不算验收标准）。
- **定量层（本轮补，[`doc/quality.md`](doc/quality.md) §2.1）**：**三层度量模型**（可算信号 → 子特性算术平均 → 特性加权平均 → 综合 `V`）+ **特征根法（AHP）权重**，来源 2007 年期刊论文《基于量化指标分析的软件质量度量方法》；**权重是 Profile 资产（判断矩阵一并留档）、D 类不进加权、`V` 只进趋势不进硬门禁**。
- **默认阈值基线（本轮补，§2.2）**：可用性 ≥ 99.9%、MTTF ≥ 10 天、MTTR ≤ 30 分钟、MTBF ≥ 10 天/次、响应均值 ≤ 5 s、并发 ≥ 500（单机）/ 800（双机）、TPS ≥ 80，**按环境分档**；运行期 **14 项指标**映射三个采集面（§2.3）。
- **AI 时代的 review 分层**：L0 机器（必过）→ L1 AI（**可验证的阻塞，不可验证的只提示**，附可复现证据并统计采纳率）→ L2 人签字；变更级别决定跑哪几层。
- **IDE 全生命周期**：需求 → 架构 → 设计 → 编码 → 测试 → 验收 → 运维（运行期回写对账、度量回流）→ 演进/退役，**追溯链不断**（`REQ-x` → 模型声明 → 用例 → 生成物 → 运行指标 → 缺陷 → 回归用例）；P7 的验收项含 quality.md §5 的面板清单（质量雷达、影响面、对账面板、退役扫描等）。
- 详规见 [`doc/quality.md`](doc/quality.md)。

### 3.13 架构评估（打分与建议）

- **标准骨架**：ISO/IEC/IEEE 42010:2022（关注点 → 视角 → 视图）、ISO/IEC 25010（质量特性）、Robert C. Martin 的包度量（`I`/`A`/`D = |A+I−1|`）、SOLID、ATAM 的场景走查。
- **MMDA 的杠杆**：架构是声明的，所以分层单向、循环依赖、数据所有权、SOLID 的静态部分**在设计期就能算**（ARCH-101…503 规则集，含目标端类型名黑名单扫描——最便宜、最能挡架构泄漏）。
- **打分不玄学**：硬规则只出 pass/fail + 违规清单（**门禁只认这些**），有界分给 🟢/🟡/🔴，历史信号只进趋势；**总分仅用于趋势，不允许只给总分**。
- **建议必须可执行**：规则号 → 证据（`file:line`）→ 依据 → 改法 → 影响面 → 变更级别；AI 出建议与反例、**不评分**，架构师签字，例外登记白名单 + 到期复审。
- **时点**：架构基线冻结（全量）、每次 L2/L3 变更（增量）、迭代（趋势）、发布前（并入质量报告）；**首版硬门禁（✔ 已裁）** = ARCH-101 / 102 / 104 / 105 + 302 / 304 / 305，ARCH-2xx 先告警一个迭代、ARCH-5xx 只进看板。
- 详规见 [`doc/architecture-review.md`](doc/architecture-review.md)。

---

### 3.14 需求工程（需求过程怎么进真源）

- **立场**：m 语言**不替代需求工程方法论**，但把需求产物变成**一等对象**（`REQ-x`）并接进同一份真源——这样"需求变了"必然触发影响面计算，而不是靠人记得去改文档。
- **三层需求 → 落点**：业务需求 → `biz/*.ma` 模块树 + Feature + 质量目标；用户需求 → 流程活动 / Action / 页面（用例视角）；功能需求 → 字段与约束；非功能需求 → Profile `quality.targets`（§3.12 §2.2）；设计约束 → capability / `protection` / `conventions.md`。
- **优秀需求四标准（清楚 / 完整 / 一致 / 可测试，另有可跟踪 / 可修改）各自对应一条机械信号**：术语唯一 → ARCH-401；完整 → `REQ-x` 与四维覆盖率；一致 → 循环依赖 / 重复定义 / 跨模块接口；可测试 → 机械用例可生成率 + 变异存活率；可跟踪 → 追溯链（`REQ-x` → 声明 → 用例 → 生成物 → 运行指标 → 缺陷 → 回归用例）；可修改 → `diff --impact` 的变更级别。**这是把"需求质量"从评审变成可自动评估的地方。**
- **需求管理四步**（划分标准 → 基线 → 变更 → 跟踪）分别落在：`REQ-x` 规则、一对象一文件 + `changelog` + git、变更分级 L0–L3、orphan 检测与追溯链。
- **SRS 的形态**：真源是项目文件，**SRS 是可导出的视图**（形态与基线冻结方式待裁，见 §6.2 第 21 条）。
- 详规见 [`doc/requirements.md`](doc/requirements.md)；原文留档 [`doc/archive/2026-09/随想录.md`](doc/archive/2026-09/随想录.md)。

### 3.15 设计器建模域与宿主形态

- **建模域清单**（随想录的"异想天开"，逐项对齐现状/缺口）：系统模块分解（= SERU 的 `S`，**并与 Role 并列**——见下）、组织架构建模（组织架构图 / 岗位矩阵 / 职员清单 → **是数据**）、业务对象建模（局部 ER）、业务主题建模（为 BI 提供数据源）、给模块设数据模型（首页过滤器与展现器）、业务流程建模（BPMN 图形输入 → 生成代码插件式加载 → Action 串联 DFD → STM 自动改状态）、UI 设计（Material 配色 / ColorRole、Field Set 分组 + 按类型自动生成呈现器）、数据可视化（自定义报表 + BI 看板，ClickHouse）、生成→编译→打包发布（DevOps）、变更轨迹与版本控制、绘图工具清单（ER/数据/流程/表单/BI/脚本/代码生成）。
- 逐项现状与缺口表：见 [`doc/ide/specification.md`](doc/ide/specification.md) §4.8。
- **必须裁的张力（宿主形态）** → **✔ 已裁（2026-09-24）：独立壳优先**（Tauri + Vue 3 + Syncfusion）；VS Code / IDEA 插件作为**后续可选宿主**，内核（`mmda-core`）与图形接口按"宿主可替换"设计（LSP 面 + `*.g` 布局/语义分离），**但不并行开工两套宿主**。见 §6.2 第 22 条、[`doc/ide/specification.md`](doc/ide/specification.md) §4.9。
- **Role 与 Module 同级（✔ 已裁 2026-09-24）**：**关键用户在需求阶段识别（关键用户即角色 Role）→ 架构设计时 Role 与 Module 分解同等重要，两者都进 m 语言**（`flow/roles/*.mr` vs `biz/*.ma`）——元模型条目见 [`doc/meta-model.md`](doc/meta-model.md) §8.1；**组织架构 / 岗位 / 职员是「数据」**，是角色的实例来源（设计元素 vs 数据实例，两层不混）。见 §6.3 第 8 条。
- **已裁的范围问题**：**组织架构 / 岗位 / 职员是「数据」**（普通 Record + 关系，不新增元模型元素）；**Role（关键用户）是语言元素、与 Module 分解同级**（需求阶段识别关键用户 → 架构设计时两者同等重要，[`doc/meta-model.md`](doc/meta-model.md) §8.1）；**BI 要有元数据、架构师要能建模**（属元模型），但既有 `MetaBiCube` 不成熟 → **具体形态与是否移植容后再议**。见 §6.2 第 23 条、§6.3 第 6/7/8 条。

---

### 3.16 运行架构（请求怎么走、钩子挂在哪、事务在哪开）

- **四层职责**（作者《分层架构》概念设计图，[`doc/runtime.md`](doc/runtime.md) §1）：**`Controller` = API 开放**（认证 / 授权 → 数据合法性校验 → 默认值设置）、**`Service` = 商业逻辑**（事务 + 业务规则 + 返回前组装）、**`Repository` = 数据读写层**（只 CRUD + 方言）、**缓存 = 横切面**（`CacheProvider`，两侧直达、`reactive` 双向，不绕 Repository）。
- **两条路径**：进入 = 三件事 + Before 拦截点 + 事务 + 商业逻辑 + After 拦截点 + CRUD；返回 = 行→对象 → **关联对象、枚举和引用属性组装**（Service）→ **聚合**（Controller）。
- **进入路径的三件事在 MMDA 里是「声明」**（Role 的能力范围 / 字段约束 / 字段默认值），Controller 只是执行点 → 业务 Controller 应是生成物（现状仍是手写：`mmda-mes` 74 / `crm` 16 / `hrm` 9 / `foundation` 3）。
- **拦截点上升到语言（新）**：`before` / `after` × **封闭的生命周期点**（`load`/`search`/`edit`/`validate`/`save`/`delete`/`got`/`action`/`import`/`print`/`upload`/`store`）；**`before*` 在事务内、`after*` 在提交后且必须幂等**；固定模式 = **设计师配置（选点、顺序、条件）+ 程序员定制（KEEP 区实现）+ AI 只提议**。
- **钩子实测现状**（三端都有挂点、命名与粒度不一）：Java `EntityService.java:337/378/388/477/484/650/658/878/2433`、Controller `beforeQuery:1292`、Repository `EntityRepository.java:509/1518`；TS `logic/entity_logic.ts:171/175/183/185/187/191/195/199/201/203/207/211`。统一口径见 [`doc/runtime.md`](doc/runtime.md) §4。
- **规则化**：[`doc/architecture-review.md`](doc/architecture-review.md) §2.1b 新增 **ARCH-107（Controller 不得直连 Repository）/ 108（缓存单点出口 + 键含租户）/ 109（钩子只挂封闭点）/ 110（装配与聚合必须是生成物）**——**首版不进硬门禁**，先 🟡 告警一个迭代。
- **未融合项**：新 Java 代码引入 `EntityFactory`（`mmda-core-entities/…/EntityFactory.java`、`mmda-base/mmda-base-repository/…/BaseEntityFactory.java`），与 core 的 `Repository` 模式**并存**，待裁（§6.2-24）。

---

### 3.17 API 契约（语言层面怎么定义 API 与对接 API 管理工具）

- **核心口径**：**API 不是新一层声明，而是「模块分解 + Feature + 视图 + Action + Role + 字段约束」的派生物**——与「用例是派生物」「装配是派生物」同一条原则；也因此**不允许外部工具成为第二真源**（与 §3.2「DB 降级为产物/缓存」同一原则）。
- **推导映射**（详表见 [`doc/api.md`](doc/api.md) §1）：Module 树 → 路径前缀与文档分组；Feature 的 `recordRef` → 资源与 schema；五视图 → CRUD 端点模板；Action → `POST /{Resource}/{id}/{action}`；`SearchParam` → 分页/排序/过滤；字段约束 → `required`/`maxLength`/`enum`/`default`；STM → 合法转移的可判定前置；Role → securitySchemes + scopes；事件 → webhook 回调。
- **语言层只补两样**（最小新增）：**暴露边界 `expose`**（`public`/`internal`/`none`，**建议默认 `internal`**）+ **稳定度与版本**（`stable`/`beta`/`deprecated` + `since`/`sunset`）；另可选「路径覆盖」与「对外契约名」（复用 `Terminology`）。**不造 `api` 顶层块、不造 DTO/VO 概念**（Record + 视图投影就是 schema）。
- **文档生成**：**Rust 内核**出 **OpenAPI 3.1**（项目一份 + 每模块一份）→ `generated/<target>/openapi/`；**契约测试**（三端实际行为 vs OpenAPI schema）成为一致性测试的 **API 维度**（补齐 L3）：命令面 `mmda api export/diff/check`（草案）。
- **设计 / 测试 / 运维三面**：设计期 IDE 出 API 面板（模块树旁看端点清单与影响面）；测试期由 OpenAPI 出机械用例 + mock（前端并行开发），Postman/Apifox collection 只作补充；运维期**网关做粗粒度、Controller 做细粒度**，端点指标进质量看板，`deprecated` 调用量 = 退役倒计时。
- **与外部工具的单向互动**：导出 ✅（YApi / Apifox / Swagger UI / Postman / 网关配置）、逆向导入 ✅（遗留系统接入，人审后入真源）、**回写 ❌**（杜绝第二真源）、对账 ✅（diff 成「待回收的需求」走正常流程）。
- **第一原则（✔ 已裁 2026-09-24）：module 边界 = API 边界 = 权限边界**——权限按 module 授予（`Role.auth module`/`actions`/`scope`）+ `sops` 操作位掩码 + ARCH-104/106 ⇒ **无归属的元对象结构上不可开放**；**插件不侵入语言**（只许读产物 + 报对账；禁止写元数据、禁止把工具概念写进语法），判据「**凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍**」；**无归属对象默认不开放**，共享基础数据归属基础模块（语料 `Base`：`biz/base.ma` 用节点 `model` 绑定 `data/models/base/` 的 **77 个**对象，模块级 `sops: READ`）。余项（基础模块固定名、`sops` → OpenAPI 权限映射）留在 §6.2-25 第 9 条。
- **OpenAPI 原生支持（✔ 已裁 2026-09-24）**：**以 OAS 3.1.0 为基准原生支持**（人读 `https://spec.openapis.org.cn/oas/v3.1.0.html`；机器校验用官方 Schema `https://spec.openapis.org/oas/3.1/schema/2022-10-07`（实测 200）+ 方言 `…/oas/3.1/dialect/base`（实测 200）；`.cn` 镜像只有 HTML）。逐条对齐见 [`doc/api.md`](doc/api.md) §3：**四条判据**（内核一等后端 / 过官方 Schema 校验 / 契约测试双向对账 / 语言层不出现 OAS 术语）、根对象与 30 个 OAS 对象的来源、**Operation 12 字段逐条**、五视图→端点与状态码、**逻辑类型 → JSON Schema 2020-12 映射**（3.1 差异点：`nullable` 移除改用 `type` 数组、`contentEncoding` 替代 `format: byte`、`webhooks` 原生、`info.summary` / `license.identifier` 新增）、security/scopes、`x-mmda-*` 溯源指针、**首版覆盖 23 + 按需 5 + 不做 2 = 30**。
- **AI 造数（✔ 已裁 2026-09-24）**：**API 测试借助 AI 自动生成 mock 数据**（"撰写测试用例的提速手段"）——**两层造数**：机械层（引用图拓扑排序、枚举、边界值、可达状态，**零 AI**、可复现、进基线）+ AI 语义层（中文业务数据、跨字段联动、刁钻样本）。**护栏四条**：AI 不得发明结构、每条数据过 schema + 约束双校验、固定种子 + provenance、**AI 造数是输入层（不需双签）、AI 断言仍需双签**。落点 [`doc/testing.md`](doc/testing.md) §4.3、[`doc/api.md`](doc/api.md) §3.9。
- **现状（实测）**：**三端都没有 API 文档能力**（Java 无 springdoc/swagger、`@Operation/@Tag` 0 个；C# 装了 `Swashbuckle.AspNetCore 6.9.0` 但 0 注解；TS 无生成）；端点模板在手写代码里**逐字重复**（`/create`、`GET ""`、`/{id}`、`/save`、`/{id}/delete`、`/deleteAll`）；无任何 API 元数据类。

---

## 4. 阶段计划

| 阶段 | 交付 | 验收（可执行） | 规模 |
| --- | --- | --- | --- |
| **P0** 基线整合 | ① 决定两个仓的关系（§6.2-1）；② ~~`git init`~~ → **✔ 已完成**（2026-09-24 建仓并首推 `0679a30`）；③ 选定语法基线（§2.4-1） | 可 `cargo test`；`mmda validate examples/mmda-mes` 跑通 | 小 |
| **P0.5** 契约盘点 | ✔ **本轮完成**：三端类/接口对照清单 + 能力矩阵 → [`doc/targets.md`](doc/targets.md)、[`doc/contracts-inventory.md`](doc/contracts-inventory.md) | 清单逐行有 `file:line` 证据（已完成）；能力矩阵已确认（§6.3-2/3/4） | 中 |
| **P1** 反向导入 Rust 化 | `mmda import --db`：库 → 项目文件（替换 1196 行 Python） | 结果与 `examples/mmda-mes` **逐文件 diff = 0**（除时间戳） | 中 |
| **P2** 解析器 | `mmda-syntax`：按内容首关键字判 partType；诊断 `<file>:<line>:<col>` | 381 个语料文件解析 **0 error**；错误用例能定位 | 大 |
| **P3** 语义与校验 | 引用解析（`@Ref` 目标存在）、类型/长度、命名约束注册表、环检测、跨目录引用 | 现有语料 `validate` 0 error；构造反例逐条报错 | 中 |
| **P4** IR + 宿主加载 | `mmda-ir` FlatBuffers；`mmda-abi`；Java 宿主先接（`MetaObject` 换源），C# 跟进 | IR 喂 Java/C#，加载结果与库直读**逐字段一致** | 大 |
| **P5** DDL | `mmda-emit-ddl`：MySQL/PostgreSQL/SQLServer/SQLite/Oracle/DM/Kingbase/Ansi | 与 Java 8 方言 + C# 3 方言产出逐条对账，差异列表化并裁决 | 中 |
| **P6** 代码生成 | `mmda-codegen` 重写 `mmda-factory`：Java / C# / TS（+Dart/JS），**按 capability 分档** | 前置：`doc/targets.md` + `doc/contracts-inventory.md`；Java/C# 产物与旧 factory 等价；KEEP 区不被覆盖（有回归用例） | 大 |
| **P7** IDE | 现有 Tauri + Vue 壳 + Monaco（语言 id `m-lang`）+ LSP + 图形通道 + 多语言映射编辑器 + git/svn | 跳转、补全、诊断、图形/文本双向编辑、多语言并排编辑可用 | 大 |
| **P8** 事件层 | m 事件契约冻结 → Java 补齐总线 / C# 对齐 | 事件声明生成的接口在两侧底座可编译运行，一致性用例通过 | 大 |
| **P9** 一致性套件与验收 | `mmda-test`：**用例从声明机械生成 + AI 生成人审**（[`doc/testing.md`](doc/testing.md)），跨端跑（`mmda test --target java,csharp,ts`）、影响面（`--impact`）、变异（`--mutate`）、中文验收单（`mmda accept --lang zh`） | 第一批用例（长度/引用/迁移矩阵/权限矩阵/租户/DDL/事件）三端结果一致；覆盖率（字段/迁移/权限/能力 100%）与变异存活率达标；验收单可签字 | 中 |

**顺序**：P0 → P1→P2→P3 是「语言自洽」的最短闭环；P4 先做业务最急的宿主（Java）；P5 / P9 可并行给人（P6 以 P0.5 为门禁）；P7、P8 最后，且**不要并行开**。

**测试前置**：机械用例的生成能力**不是 P9 才做**——P2/P3 的校验规则**就是**断言的来源（规则写好即可产出用例），P5 的方言对账与 P6 的 KEEP 区回归都复用同一套用例；P9 只负责补上「三端跑同一批用例 + 影响面 + 变异 + 验收单」。

---

## 5. 仓库与目录

`D:\2026\rust`（语言、工具与文档内核）：

```
PLAN.md                     落地计划（本文件）
doc/                        规范真源（根 = 语言规范；分支见下）
  ├── index.md              文档索引与阅读顺序
  ├── readme.md             语言规范总览（定位与设计原则）
  ├── datatypes.md          数据类型
  ├── records.md            对象：Record / Field / Enum / View
  ├── statements.md         语句、表达式、行为与状态机
  ├── events.md             事件驱动架构 + 事件声明语法
  ├── presentation.md       呈现层：UiField / 分组 / i18n / 五视图 / 渲染契约
  ├── meta-model.md         元模型元素与到旧实现的映射
  ├── project.md            项目格式（目录、扩展名、清单、changelog、归档）
  ├── targets.md            三端契约与能力矩阵（P0.5/P6 前置）
  ├── contracts-inventory.md 三端契约盘点清单（逐行 file:line）
  ├── requirements.md       需求工程（三层需求、优秀需求四标准的机械信号、SERU 四要素、需求管理与 SRS 形态）
  ├── protection.md         算法与知识产权保护（草案）
  ├── workflows.md          角色与工作流（五类用户的边界、交接、变更分级）
  ├── testing.md            测试与验收（用例生成、验收标准、覆盖率与变异）
  ├── quality.md            质量模型与自动评估（25010 九维、A/B/C/D 分级、三层度量与加权聚合、默认阈值基线、AI review 分层）
  ├── architecture-review.md 架构评估（分层/循环/所有权硬规则、Martin 度量、SOLID 操作化；§2.1b 运行时分层 ARCH-107…110）
  ├── runtime.md            运行架构（四层职责、进入/返回两条路径、事务边界、拦截点统一语义、缓存横切面、装配与聚合）
  ├── api.md                API 契约（API 由声明推导、语言层只补暴露边界与稳定度、OpenAPI 生成与契约测试、与 YApi/Apifox/Swagger 的单向互动）
  ├── glossary.md           术语表
  ├── errata.md             待裁决口径与校勘
  ├── design-notes.md       设计笔记（原 mmda-workflow.md）
  ├── ide/                  工具与 IDE 规格（自 architect 原样迁入）
  ├── ai/                   MCP 工具面与 Vibe & Spec
  ├── legacy/               旧 Java 实现对照
  ├── guide/                快速上手
  ├── templates/            项目约定模板
  └── archive/2026-06/      被合并的原文留档（可 diff 校验未丢内容）
crates/                     §3.3 的 Rust 工作区
apps/                       IDE（Tauri + Vue，可从 architect 迁入）
examples/mmda-mes/          真实语料（381 文件，parser 回归集）
tests/golden/               AST / IR golden 快照
tests/roundtrip/            项目 ↔ 库 对账脚本
tools/                      方言/类型映射数据表
```

`.mmda` 项目自身的目录结构沿用 [doc/project.md](doc/project.md) §1（`biz/ data/ flow/ ui/ codegen/ changelog/ generated/`）。

**相关仓（不由本计划改动）**：`D:\2026\java`（后端 A，git）、`D:\2026\cs\MMDA`（后端 B，SVN 工作副本 + `Mmda.Core/` 嵌套 git）、`D:\2026\ts\mmda`（前端，git）、`E:\Dev\mmda-architect`（前一轮，**无版本控制**）。

---

## 6. 待裁决

### 6.1 语法专题（你已定：另开专题逐个讨论）

- 口径冲突与待裁决清单**已集中到 [`doc/errata.md`](doc/errata.md)**：五处结构性冲突（冲突 3 已裁）+ 十条语法细项。
- 本计划只固定一条：**P2 开工前必须选定语法基线**（errata 冲突 1 的文档形态 vs 语料形态），否则 381 个文件无法当回归集。

### 6.2 工程与架构未决项

1. **仓库关系**：`E:\Dev\mmda-architect`（Rust 内核 + IDE 壳 + 381 文件语料）与 `D:\2026\rust`（规范 + 计划 + 已迁入的文档）是合并成一个仓，还是「`rust` = 语言内核与规范，architect = IDE 壳，内核作为依赖」？
2. ~~**`.mmda` 后缀**~~ → **✔ 已裁决，见 §6.3-1**。
3. **`.ma` 正文形态**：见 errata 冲突 2（JSON vs 语言 DSL），以及「哪些 part 是 JSON、哪些是语言文本」的界限。
4. **留档的处置**：`doc/archive/2026-06/` 是否需要长期保留（用于 diff 与追溯），还是在 P0 定完仓库关系后随 architect 仓一并归档。
5. **svn 集成的具体形态**：git 有本地提交/分支/合并可承载「细粒度版本控制」；svn 无本地暂存且合并体验差。是否为 svn 定义「changelog 为准、文件为辅」的弱集成？
6. **旧 `mmda_metadata` 库的连接**：`tools/reverse_mmda_project.py:27` 写死 `127.0.0.1:3306 root/<口令见本地环境>`（**原文曾明文写出口令，公开仓脱敏**）。P1/P4 对账需要这个库或一份 dump；是否改环境变量并给我一份 dump？（C# 侧 `Db/mmda_metadata-local.sql` 可能已是一份可用建库脚本。）
7. **TS 定位**（已修正）：TS 是**前端运行时**（`@mmda/core` + `vui*` Vue + `rui*` React 皮肤），不是后端底座。待定的是：前端要不要 WASM 宿主在浏览器直接跑 IR（离线校验/预览），还是只消费后端 HTTP + 生成的类型？
8. **C# 底座的能力缺口补齐顺序**（原「有没有底座」已解决：有，70,831 行）：`Mmda.Core.Files` 空壳、DDL 只有 3 方言、而 BI/Scada 反而是 C# 领先。capability 分档已裁（§6.3-2），待定的是**先补 File 还是先补 DDL 方言**。
9. **`generated/` 与 KEEP 区的边界**：用户在 KEEP 区写的业务代码不应被 IR 覆盖，也不该反向进 `.m`；需要明确规则。
10. **MCP 工具面**（`doc/ai/tools.md` 已规划）何时冻结：它决定 AI 会话如何读写项目、触发生成。
11. ~~**能力标记（capability）语法**~~ → **✔ 已裁决，见 §6.3-2**。
12. ~~**一致性测试跑在哪**~~ → **✔ 已裁决，见 §6.3-4**。
13. **C# 仓的版本控制**：`D:\2026\cs\MMDA` 是 SVN 工作副本、`Mmda.Core/` 内嵌独立 git 仓。mmda-lang 的产物要落进它，需要先定「生成物进哪个 VCS、怎么避免双份历史」（B2 要求 git/svn 都支持，这里正好是现实样本）。
14. **算法保护档与 native 边界**：算法是否按 [`doc/protection.md`](doc/protection.md) 下沉 native（`algorithm` / `protection` / `license` 声明，以及行为里引用 native 的语法），哪些算法必须服务化、哪些走 native 库。该问由「Java/C# 易被反编译」提出，牵动 m 语言语法（errata 语法待裁项 11）。
15. **角色权限与变更分级**：五类职责的写入边界、AI 可自动合入的级别（L0/L1）、破坏性变更的兼容期策略（双写/灰度/回填）、运行期回写的签字人——见 [`doc/workflows.md`](doc/workflows.md) §12（第 6 条「模式与权限」已裁 → §1.2）。
16. ~~**测试与验收口径**~~ → **✔ 已裁（2026-09-24）**：`.mt` 进语言族、覆盖率门禁（100%/≥90%）、AI 用例双签、变异跑频与阈值、中文验收单作为验收凭证——见 [`doc/testing.md`](doc/testing.md) §11 已裁表。该节余下 3 条待裁：AI 增强能力的实施顺序、AI 效果度量口径、`.mt` 正式语法（随语法专题）。
17. **质量面的口径**：质量目标值写哪里（Profile vs 模型）、首版 `quality gate` 覆盖范围、AI Reviewer 采纳率阈值与降权规则、质量报告是否作为交付物、safety 类声明（危险动作/不可逆迁移/fail-safe）是否要独立语法——见 [`doc/quality.md`](doc/quality.md) §7（**8 条待裁**，含本轮补的**加权口径**与**默认阈值基线**两条）。
18. ~~**架构评估的口径**~~ → **✔ 已裁（2026-09-24）第 1、2 项**：首版硬门禁 = **ARCH-101/102/104/105 + 302/304/305**（ARCH-2xx 先告警、5xx 只进看板）；**抽象度 `A` = 对外契约数 /（对外契约数 + 具体对象数）**。余 3 项（阈值取值、例外白名单形态、ATAM 场景是否进项目）按建议值先行，阈值可配——见 [`doc/architecture-review.md`](doc/architecture-review.md) §8。
19. ~~**UI 契约**~~ → **✔ 已裁（2026-09-24）**：**UI 契约 = 现有 mmda-vue 前端项目**，不考虑 C# MVC 与 Java 的 UI，后端只提供 `MetaUi` 元数据（见 §3.4 收紧段、[`doc/presentation.md`](doc/presentation.md) §5.1、[`doc/targets.md`](doc/targets.md) §8-4）。**补裁**：前端 kit **`vui`（Vue）与 `rui`（React）都可选**、随技术人员喜好（自定义前端 UI 插件时按熟悉度挑），不构成两套 UI 契约。
20. **质量加权与阈值基线**：是否正式用**特征根法（AHP）**算权重、权重放 Profile 还是项目文件、综合分 `V` 是否进质量报告封面、[`doc/quality.md`](doc/quality.md) §2.2 默认基线是否随模板下发与**按环境分档**怎么落地——见 [`doc/quality.md`](doc/quality.md) §7-7 / §7-8。
21. **需求条目的形态**：`REQ-x` 进语言还是 IDE 侧清单、用例（`UseCase`）是否上图形、SRS 导出形态与基线冻结方式、需求覆盖门禁是否分层次——见 [`doc/requirements.md`](doc/requirements.md) §7（6 条待裁，含与「业务人员经 AI 提需求」路径的衔接）。
22. ~~**设计器的宿主形态**~~ → **✔ 已裁（2026-09-24）**：**独立壳优先**（Tauri + Vue 3 + Syncfusion）；**VS Code / IDEA 插件作为后续可选宿主**——内核与图形接口按「宿主可替换」设计（LSP 面 + `*.g` 布局/语义分离），但**不并行开工两套宿主**。见 [`doc/ide/specification.md`](doc/ide/specification.md) §4.9。
23. **随想录带来的范围问题**（[`doc/ide/specification.md`](doc/ide/specification.md) §4.8 的缺口列；**其中两项已裁**）：~~组织架构 / 岗位 / 职员是否进语言~~ → **✔ 是「数据」**（普通 `Record` + 关系，不新增元模型元素；设计器出图形化输入，产物是数据模型文件）；~~报表与 BI 的归属~~ → **✔ 方向已裁：BI 要有元数据、最终让架构设计师能建模**（属元模型），**但既有 `MetaBiCube` 很不成熟 → 具体形态与是否移植「容后再议」**（ClickHouse 是否默认分析存储同此）。**余下待裁**：层级菜单是**声明还是投影**、首页过滤器与展现器同五视图的关系、UI 配色 **ColorRole 是否进元数据**、局部 ER 与全局 ER 的合并规则、**BPMN XML 互转**、**发布链路**（CI/DevOps 对接）、**岗位 → Role 的映射规则**（**Role 本身已裁为语言元素，见 §6.3-8**）。
24. **运行架构的落法**（[`doc/runtime.md`](doc/runtime.md) §8，**7 条**）：① 拦截点声明的语法形态（挂 Action / 视图 / 独立 `hooks` 段）；② 生命周期点是否**封闭枚举**（建议封闭）；③ `save` 是否合并 insert/update（建议合并）；④ 存储级钩子（`store`）是否对设计师开放（建议不开放）；⑤ 缓存策略（TTL/失效）写 Profile 还是模型（建议 Profile）；⑥ **`EntityFactory` 与 `Repository` 的关系**（新 Java 代码两套并存，未融合）；⑦ **事务传播规则**（跨模块调用时事务怎么传）。
25. **API 契约的落法**（[`doc/api.md`](doc/api.md) §8，**16 条，其中 4 条已裁（见 §6.3-11）**）：① 暴露边界默认值（建议默认 `internal`）；② 路径推导规则（建议 `/模块路径/资源`）与命名规范；③ 稳定度标记语法与 `since`/`sunset`；④ OpenAPI 版本（建议 3.1）与扩展字段白名单；⑤ 命令面（`mmda api export/diff/check` 是否并入 `mmda generate`）；⑥ Mock 归属（IDE 内置 vs 外部工具）；⑦ 网关与 Controller 的认证分工；⑧ 逆向导入的产出形态（先出报告 + 骨架，人审后入真源）；⑨ **基础模块的固定名与 `sops` → OpenAPI 权限映射**（语料用 `Base`；`READ` → 只出读端点、`CRUD` → 全出）——**这一条是作者"还没想清楚"的那部分，先只记待裁、不拍**；~~⑩ 存量路径兼容~~ → **✔ 已裁：取 A 方案**（REST 语义 + `legacyPathStyle` 兼容开关，迁移期双版本并存）；~~⑪ `decimal` / `int64` / `Timestamp` 的 JSON 表示~~ → **✔ 已裁：精度优先**（`decimal`/`money` → `string` + `pattern`；超 JS 安全整数的 `int64`/`uint64` → `string`；`Timestamp` → `date-time`），**三端序列化必须一致**；⑫ **`operationId` 命名规则**（`<moduleId>_<feature>_<op>`，ASCII、唯一）；⑬ **scope 命名与授权粒度**；⑭ **`webhooks` 首版做不做**；~~⑮ 官方 Schema 校验与契约测试是否进硬门禁~~ → **✔ 已裁：进**（B 级，失败即阻断 CI）；~~⑯ AI 造数的样本固化范围~~ → **✔ 已裁：要固化**（种子 + provenance 进版本控制；默认只进 mock 与开发期，断言不由 AI 造数产生）。

### 6.3 ✔ 已裁决（2026-09-24）

| # | 裁决 | 落点 |
| --- | --- | --- |
| 1 | **`.mmda` 后缀**：保持扩展名族（`.ma/.mm/.me/.ms/.mr/.mc/.mf/.mi`），`.mmda` 只表示项目清单；**解析器按内容首关键字判 partType**，扩展名仅作约定/图标/文件关联 | `doc/errata.md` 冲突 3、`doc/project.md` 抬头、§3.3 `mmda-syntax` |
| 2 | **capability 语法**：按 `doc/targets.md` §3 草案进语言（`target csharp capability events, jobs, scada, bi`），语言用到而目标未声明的能力 → **生成期报错**，不静默降级、不生成空方法 | `doc/targets.md` §3、§3.10、P6 |
| 3 | **UI 契约**：后端**只出 `MetaUi` 元数据**（字段/控件/分组/校验/i18n 词条），渲染描述里不许出现框架专属概念；**✔ 同日收紧（§6.2-19）**：UI 契约 = **现有 mmda-vue 前端项目**，不考虑 C# MVC 与 Java 的 UI，C# `Mmda.Ui.*` 为遗留实现 | `doc/presentation.md` §5.1、§1.2 非目标 |
| 4 | **一致性测试由 Rust 内核统一驱动**：`mmda test --target java,csharp,ts`，用例由内核生成，避免出现第三份「测试方言」 | §3.10 L3、§3.3 `mmda-test`、P9 |
| 5 | **设计器宿主形态**：**独立壳优先**（Tauri + Vue 3 + Syncfusion）；VS Code / IDEA 插件为**后续可选宿主**，内核与图形接口按「宿主可替换」设计，但不并行开工两套宿主 | §3.15、[`doc/ide/specification.md`](doc/ide/specification.md) §4.9、§6.2-22 |
| 6 | **组织架构建模**：**组织架构 / 岗位 / 职员是「数据」**（普通 `Record` + 关系，不新增元模型元素）；设计器只提供图形化输入与清单导入，产物是数据模型文件 | §3.15、[`doc/ide/specification.md`](doc/ide/specification.md) §4.8 域 2、[`doc/errata.md`](doc/errata.md) §五-10 |
| 7 | **BI 元数据**：**BI 要有元数据、最终让架构设计师能建模**（属元模型）——方向已裁；**既有 `MetaBiCube` 不成熟 → 形态与移植「容后再议」**（ClickHouse 同此） | §3.15、[`doc/ide/specification.md`](doc/ide/specification.md) §4.8 域 4/8、§6.2-23 |
| 8 | **Role 与 Module 同级**：**Role（关键用户）是架构设计元素、进 m 语言**（`flow/roles/*.mr`）——**需求阶段识别关键用户**（RUP 的 Actor），架构设计时 Role 与 Module 分解**同等重要**；**组织架构 / 岗位 / 职员仍是「数据」**，是角色的实例来源（设计元素 vs 数据实例，两层不混）。余：**岗位 → Role 的映射规则**待裁 | §3.15、[`doc/meta-model.md`](doc/meta-model.md) §8.1、[`doc/requirements.md`](doc/requirements.md) §2、[`doc/errata.md`](doc/errata.md) §五-12 |
| 9 | **运行架构口径 + 拦截点上升到语言**：**`Controller` = API 开放 / `Service` = 商业逻辑 / `Repository` = 数据读写 / 缓存 = 横切面**（概念设计已确认）；**事务夹在 Before / After 拦截点中间**（`before*` 事务内、`after*` 提交后必须幂等）；**拦截点进语言**——`before`/`after` × **封闭生命周期点**，**设计师配置 + 程序员定制**（KEEP 区）为固定模式；进入路径三件事（认证授权/校验/默认值）是**声明**、Controller 是执行点；**装配与聚合是生成物**。余：声明形态（挂 Action / 视图 / 独立段）与是否封闭枚举待语法专题（§6.2-24、[`doc/runtime.md`](doc/runtime.md) §8） | §3.16、[`doc/runtime.md`](doc/runtime.md)、[`doc/architecture-review.md`](doc/architecture-review.md) §2.1b、[`doc/errata.md`](doc/errata.md) §五-13 |
| 10 | **API 边界 = module 边界（插件不侵入语言）**：**module 边界 = API 边界 = 权限边界 = 文档分组边界**（四者一个来源——权限按 module 授予，故无归属元对象结构上不可开放）；**插件只许读产物 + 报对账，禁止写元数据、禁止把工具概念写进语法**；判据「凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍」；**无归属的元对象默认不开放**（枚举不需要归属、从属/技术对象默认 `internal`、共享基础数据归属基础模块 `Base`——语料实测 `data/models/base/` 77 个对象由 `biz/base.ma` 绑定） | §3.17、[`doc/api.md`](doc/api.md) §1.1、[`doc/architecture-review.md`](doc/architecture-review.md) §2.1（**ARCH-111**）、[`doc/errata.md`](doc/errata.md) §五-14 |
| 11 | **API 契约四条落定**（作者回「1. REST语义 / 2. 按你建议 / 3. 进 / 4. 要」）：① **存量路径取 A 方案**——生成物用 **REST 语义**（POST 创建 / PUT 更新 / DELETE 删除 + `/{模块路径}/{资源}` 前缀），**同时给 `legacyPathStyle: true` 保留 `POST /save` 等老路径**，迁移期双版本并存、老路径标 `deprecated` + `sunset`；② **序列化取「精度优先」**——`decimal(p,s)` / `numeric` / `money` → **`string` + `pattern`**（TS 端也生成 `string`，不是 `number`），`int64` / `uint64` 超 JS 安全整数范围时用 `string`，`Timestamp` → `string` + `format: date-time`；**三端序列化必须一致**（进 capability 一致性用例）；③ **官方 Schema 校验与契约测试进硬门禁**（B 级，`mmda api check` 失败即阻断 CI）；④ **AI 造数的样本要固化**——种子 + provenance 进版本控制、过 schema + 约束双校验，**默认只进 mock 与开发期**，断言不由 AI 造数产生 | §3.17、[`doc/api.md`](doc/api.md) §3.1-2 / §3.4 / §3.5 / §3.9 / §8.1、[`doc/targets.md`](doc/targets.md) L2、[`doc/errata.md`](doc/errata.md) §五-16 |

---

## 7. 风险与反例

| 风险 | 表现 | 对策 |
| --- | --- | --- |
| 语法基线不定就写解析器 | 381 个语料文件解析不了，回归集作废 | P0 先裁决 §2.4-1 |
| 语法两套并存 | 文档与语料各写一套，工具与 AI 各按一套 | 规范单一真源，另一套标注历史 |
| 双向真源 | 库改了、文件没跟上 | §3.2 回写通道 + checksum 门禁 |
| **底座能力不对等** | 生成器对 C# 出了事件/文件代码，而 C# 侧没有对应实现（或 Java 侧没有事件总线） | capability 分档 + 生成期报错（§6.3-2），不静默降级 |
| **契约只写在文档里** | 「统一接口」变成口号，两端继续各写各的 | 盘点已完成（`contracts-inventory.md`）；L3 一致性套件当门禁（§6.3-4、P9），三端行为不一致不许合入底座仓 |
| 重复实现 | Rust 与 Java/C# 各写一份 DDL / 类型映射 | 映射表数据化，编译期出代码（§3.6） |
| 生成物伤手写代码 | KEEP 区被覆盖 | 沿袭 `~KEEP PARTS` 协议（C# 产物里已在跑） |
| 表达式不纯 | 事件重放不可行（`doc/events.md:97-102`） | 表达式禁 IO/赋值/随机/时间依赖 |
| 范围爆炸 | 同时做语言 + IR + 三宿主 + DDL + 代码生成 + IDE | 按 §4 串行推进，一次只开一个阶段 |
| ~~无版本控制~~ | ✔ **规范仓已缓解**（`0679a30` 入 git）；**但 `E:\Dev\mmda-architect`（1,699 行 Rust + 381 文件语料）仍无版本控制** | 把 architect 纳入版本控制（P0 决定仓库关系时一并做） |

---

## 8. 验证与回滚

```bash
# 内核自检
cargo test
cargo run -p mmda-cli -- validate examples/mmda-mes

# P1 对账：库 → 项目文件，应逐文件一致
cargo run -p mmda-cli -- import --db --out examples/mmda-mes-regen
diff -r examples/mmda-mes examples/mmda-mes-regen

# P2 解析全部语料
cargo run -p mmda-cli -- parse examples/mmda-mes --ast-json --deny-warnings

# P4 Java 宿主对账（本机入口）
~/AppData/Local/hermes/bin/mmda-mvn.sh -C /d/2026/java/mmda-core -o -pl mmda-core-data -am test

# P4 C# 宿主对账
dotnet test "D:/2026/cs/MMDA/Tests/Mmda.Core.Data.Test/Mmda.Core.Data.Test.csproj"

# P9 一致性：三端跑同一组用例
cargo run -p mmda-cli -- test --target java,csharp,ts --cases examples/mmda-mes/tests
```

**回滚**：`D:\2026\rust` **已接入 git**（公开仓 `github.com/Roy7611/mmda-lang`，首提交 `0679a30`），每阶段一个分支/标签；`E:\Dev\mmda-architect` 在 P0 决定仓库关系前**不动它**；`D:\2026\java` 在 P4 之前只增不改（唯一的既有改动是删除已归档的 `mmda-lang/`）；`D:\2026\cs\MMDA` **本阶段只读不写**。

---

## 9. 变更记录

- v0.1（2026-09-24）：初稿，基于 `doc/` + `D:\2026\java` 实测。
- v0.2（2026-09-24）：纳入 B1–B8 决策；纳入 `E:\Dev\mmda-architect` 实测（1699 行 Rust、35 篇文档、381 文件语料、1196 行 Python 反向工具）；新增 §2.4 四处口径冲突与 §6.2 十条未决项。
- v0.3（2026-09-24）：**文档合并**——以 `doc/` 为根，并入 `E:\Dev\mmda-architect` 的有效内容：语言类文档合并进根文档（`records.md`/`statements.md`/`presentation.md` 新写，`readme.md`/`datatypes.md`/`events.md` 扩写），工具与 IDE 类原样迁入 `doc/ide/`，新增 `doc/index.md`、`doc/meta-model.md`、`doc/project.md`、`doc/glossary.md`、`doc/errata.md`，被合并原文留档 `doc/archive/2026-06/`（13 篇）；§5 目录结构与 §6.1/§6.2 相应更新。
- v0.4（2026-09-24）：**补入 C# 后端实测与契约口径**——新增 §2.5（`D:\2026\cs\MMDA`：762 文件 / 70,831 行、模块与同名 `Meta*` 类、Events/UI/Sql 能力、`Mmda.Core/` 嵌套 git）；新增 §3.10 契约三层（L1/L2/L3）与 capability 分档；§1.1 目标补入「m 是跨语言契约真源」；§1.2 明确「不用 Rust 统一业务实现」；纠正 §3.4「三种语言对等底座」为**2 后端 + 1 前端**；§3.6/§3.7 补 C# 方言与事件起点不对等；§4 新增 **P0.5 契约盘点**并把 `doc/targets.md` 设为 P6 门禁；§6.2 改写第 7/8 条、新增第 11–13 条；§7 增补两条风险；新增文档 [`doc/targets.md`](doc/targets.md)。
- v0.5（2026-09-24）：**三条裁决落地 + P0.5 完成**——新增 §6.3（`.mmda` 保族 + 内容首关键字判 partType、capability 语法进语言、UI 契约改出渲染描述、一致性测试由 Rust 内核驱动）；§0 台账、§2.1（文档清单）、§2.4（改为五处冲突 + 状态列）、§3.3（`mmda-syntax` 判定规则、新增 `mmda-test`）、§3.10、§4（P0.5 标完成、新增 P9）、§6.2（2/11/12 划掉）、§7（两条风险对策更新）、§8（新增 `mmda test`）同步；新增文档 [`doc/contracts-inventory.md`](doc/contracts-inventory.md)（60+ 概念逐行 `file:line` 的三端契约盘点）；同步 `doc/errata.md`（冲突 3 转已裁 + §五 裁决记录）、`doc/project.md`、`doc/presentation.md` §5.1、`doc/targets.md` §3/§8、`doc/index.md`。
- v0.6（2026-09-24）：**算法与知识产权保护（草案）**——新增 [`doc/protection.md`](doc/protection.md)（Java/C# 反编译风险与工具、保护强度谱、算法 vs 集成四条判据、三端 native 交付形态、Rust 加固清单、许可与法务、反面清单与验收命令）；`doc/targets.md` 新增 §3.1 算法宿主 capability 与对照矩阵「算法/重计算载体」行；`doc/errata.md` 语法待裁清单新增第 11 项（native 节点声明）；§5 目录与 §6.2 新增第 14 条（保护档与服务化范围待裁）。
- v0.7（2026-09-24）：**角色与工作流**——新增 [`doc/workflows.md`](doc/workflows.md)（五类角色定义与**写入权限矩阵**、三个时间面的 owner、架构师 7 步 / 设计师 8 步 / 程序员 6 步的逐步输入-产物-门禁、**AI Agent 三道闸协议**与批量作业要求、**业务人员经 AI 的路径**与三条红线、**变更分级 L0–L3**、交接协议、端到端示例）；`doc/ide/workflow.md` 加「工具视角 vs 角色视角」交叉说明；`doc/index.md` 阅读顺序插入；§3.9 补「按角色验收 IDE」；§5 目录与 §6.2 新增第 15 条（角色权限与变更分级待裁）。
- v0.8（2026-09-24）：**职责不按岗位划分**——`doc/workflows.md` §1 改为「五类**职责（帽子）**」，明确同一人可兼任（业务专家 + 技术全包），帽子只决定**签字**、不决定能否写；新增 §1.1 **三种工作模式**（单人 / 结对 / 团队：**门禁一项不减，只裁剪签字人数**，单人模式的 L2/L3 用「AI 对抗复核 + 冷却期 + 回滚演练」替代第二双眼睛）、§1.2 帽子决定 IDE 视角而非登录权限、§1.3 矩阵读法改为「这类文件被改动时必须满足什么条件」；§8 变更分级改为「必须留下的证据 + 按模式分列的签字要求」；§6.2 三道闸的第三闸改为签字（含模式差异）；§12 新增第 6 条（模式默认配置，建议默认单人模式）。
- v0.9（2026-09-24）：**测试与验收（AI 时代）**——新增 [`doc/testing.md`](doc/testing.md)（用例是派生物、四类来源与审签、架构阶段可生成的权限/流程/能力用例、设计阶段可生成的字段/引用/迁移矩阵用例、AI 生成用例 + 人工审核的防幻觉三条禁令、三层验收物与 baseline 机制、按声明维度算覆盖率、变异测试反查有效性、工具面与用例文件形态草案）；`doc/workflows.md` §1.2 依裁决重写（**模式与权限在 IDE 项目管理里配置，导航与写入边界按角色权限限制**，「一人到底」= 多项角色授予同一账号）、§9 交接协议增加「用例与基线」、§11 关系表增加 `testing.md`、§12 第 6 条转已裁并新增第 7 条；§3.11 新增「测试与验收」；§4 的 P9 扩为「一致性套件与验收」（新增 `--impact`/`--mutate`/`accept`）并补「测试前置」段；§5 目录、§6.2 第 15/16 条同步。
- v1.0（2026-09-24）：**AI 增强的测试能力 + 验收口径裁决**——`.mt` 进语言族、覆盖率门禁（字段/迁移/权限/能力 100%、需求 ≥ 90%）、AI 用例业务 + 设计师双签、变异里程碑 + 每日（存活 ≤ 10%）、中文验收单作为验收凭证（[`doc/testing.md`](doc/testing.md) §11 转「已裁」表）；`testing.md` 新增 §4.1 **AI 增强能力总表**（10 项）、§4.2 六条护栏、§6.1 三个覆盖维度（变更覆盖 / 缺陷回溯覆盖 / 分支覆盖）、§6.2 **用例质量评估**（7 维）+ 三层分层（黄金 / 普通 / 草稿）；§3.11 补「AI 增强能力」；`doc/errata.md` §五 新增第 6 条、语法待裁新增第 12 项（`.mt` 语法形态）；§6.2 第 16 条转已裁。
- v1.1（2026-09-24）：**质量模型与自动评估 + 全生命周期**——新增 [`doc/quality.md`](doc/quality.md)（**ISO/IEC 25010 2023 九特性**逐项映射到 MMDA 可自动算的信号、**A/B/C/D 可判定性分级**与「把 D 变 A/B」的迁移做法、`quality report/gate/diff` 工具面、**AI 时代 review 分层**（L0 机器 / L1 AI 可验证才阻塞 / L2 人签字）+ AI review 三种高价值用法（反向/对抗/历史）、**IDE 全生命周期八阶段表**与面板清单）；`doc/testing.md` 验收物增补第 ④ 项「质量报告」、§10 关系表与 §11 待裁第 10 条；`doc/workflows.md` §8 补 review 分层表、§11/§12 同步；`doc/project.md` 落 `.mt` 与 `tests/`（前一轮）；§3.12 新增「质量模型与自动评估」、§3.9 补「全生命周期而非编辑器」、§5 目录、§6.2 第 17 条。
- v1.2（2026-09-24）：**架构评估（打分与建议）**——新增 [`doc/architecture-review.md`](doc/architecture-review.md)（**ISO/IEC/IEEE 42010:2022** 的关注点/视角映射与缺口清单、**ARCH-101…503 规则集**（分层与依赖硬规则、Martin 度量 `I`/`A`/`D`、**SOLID 逐条操作化**、术语一致、变更面）、**打分模型**（硬规则出清单、有界分给 🟢/🟡/🔴、总分仅趋势）、**建议模板**（规则号→证据→依据→改法→影响面→级别）与三个真实例、评审仪式与首版门禁建议、`mmda arch report/gate/diff/recommend`）；`doc/quality.md` 可维护性增「结构合规」行并接入关系/待裁；`doc/testing.md` 验收物 ④ 含架构评估；`doc/workflows.md` 架构师第 7 步门禁、§11/§12；[`doc/ai/tools.md`](doc/ai/tools.md) 新增 §2.6 质量与架构评估工具面；§3.13 新增「架构评估」、§5 目录、§6.2 第 18 条。
- v1.3（2026-09-24）：**架构评估口径裁决**——首版架构硬门禁 = **ARCH-101/102/104/105 + 302/304/305**（ARCH-2xx 先告警一个迭代、5xx 只进看板）；**抽象度 `A` 的定义裁为「对外契约数 /（对外契约数 + 具体对象数）」**（契约 = Action + 视图 + 被外部引用的 Record/Enum）——`architecture-review.md` §5/§2.2 转已裁、§8 拆为「裁决记录 + 待裁（余 3 项按建议值先行）」；`doc/errata.md` §五 新增第 7 条、校勘记录第八轮；`doc/quality.md` §7-6、`doc/workflows.md` §12-9 同步；§3.13 门禁句、§6.2 第 18 条同步。
- v1.4（2026-09-24）：**UI 契约收紧为单一前端**——**UI 契约 = 现有 mmda-vue 前端项目**（`D:\2026\ts\mmda`）；**不考虑 C# MVC 与 Java 的 UI**；**后端只提供 `MetaUi` 元数据**。`doc/presentation.md` §5.1 重写（含三端 `MetaUi` 实测 `file:line`、三条界限、`capability ui` 只在 ts 声明）；`doc/targets.md` §1/§4（新增「MetaUi 元数据（UI 契约本体）」行、UI 渲染契约行转已裁）/§6/§8-4；`doc/contracts-inventory.md` §6 抬头与再裁说明；`doc/workflows.md` §1.3/§4-6；`doc/quality.md` 交互能力行；`doc/architecture-review.md` ARCH-103 明确 UI 层；§3.4 收紧段、§6.2 第 19 条；`doc/errata.md` §五 第 8 条、校勘记录第九轮。
- v1.5（2026-09-24）：**质量定量层与阈值基线（吸收内部资料）**——用户提供 `D:\项目\2026 mmda\软件质量.pptx` 与《基于量化指标分析的软件质量度量方法》（2007 年《北京化工大学学报》扫描件，OCR 后逐页核读）：[`doc/quality.md`](doc/quality.md) 新增 **§1.0 标准谱系**（ISO/IEC 9126:1991 → 25010:2011 → 25010:2023 命名对照）、**§2.1 三层度量模型与加权聚合**（度量元 → 子特性 → 特性 → 综合公式、**特征根法 AHP 权重**、论文算例 `V_c2 = 0.648`、三条收窄：权重是 Profile 资产 / D 类不进加权 / `V` 只进趋势不进硬门禁）、**§2.2 默认质量目标基线**（可用性 ≥ 99.9%、MTTF ≥ 10 天、MTTR ≤ 30 分钟、MTBF ≥ 10 天/次、响应均值 ≤ 5 s、并发 ≥ 500·800、TPS ≥ 80，按环境分档）、**§2.3 运行期 14 项指标**与三个采集面；§1.2/§1.5 补交叉引用、§7 新增 2 条待裁、§8 补三条来源；[`doc/testing.md`](doc/testing.md) §11-6 性能用例阈值指向 `quality.md` §2.2；§3.12 补定量层与阈值基线、§5 目录、§6.2 第 17/20 条；`doc/errata.md` 校勘记录第十轮。**同轮补裁（第十一轮）**：前端 kit **`vui`（Vue）与 `rui`（React）都可选**、随技术人员喜好（自定义 UI 插件场景按熟悉度挑），不构成两套 UI 契约。
- v1.6（2026-09-24）：**随想录归档 + 需求工程与设计器建模域两篇落成**——用户提供《MMDA 随想录》（原文留档 [`doc/archive/2026-09/随想录.md`](doc/archive/2026-09/随想录.md)）：新增 [`doc/requirements.md`](doc/requirements.md)（**需求为什么难**与代价放大比例、**三层需求 → MMDA 落点**表、**优秀需求四标准各自对应一条机械信号**（清楚/完整/一致/可测试 + 可跟踪/可修改）、**SERU 四要素（S/E/R/U）映射**、**需求管理四步 → 已有机制**、SRS 形态与 6 条待裁）；[`doc/readme.md`](doc/readme.md) 新增 §7 **与低代码的区别**（逐条回答"低代码为什么不被看好"）；[`doc/ide/specification.md`](doc/ide/specification.md) 新增 §4.8 **建模域清单（11 域，逐项标现状/缺口）**与 §4.9 **宿主形态张力**（独立壳 vs VS Code/IDEA 插件）；§3.14/§3.15 新增两节、§5 目录、§6.2 第 21/22/23 条；`doc/errata.md` §三 增 11 条工程待裁、校勘记录第十二轮；`doc/index.md` 阅读顺序与索引同步。
- v1.7（2026-09-24）：**随想录三问裁定**（用户：「独立壳优先」「组织架构是数据」「BI 要有元数据、最终让架构设计师能建模，但 MetaBiCube 很不成熟，容后再议」）——§3.15 宿主形态与范围问题转已裁、§6.2 第 22 条已裁 / 第 23 条两项已裁 + 余下待裁清单、§6.3 新增第 5/6/7 条；`doc/ide/specification.md` §4.9 改已裁（独立壳优先 + 两条随之确定的口径）、§4.8 域 2/4/8/10 更新、§4.9 表格加「结论」列；`doc/errata.md` §五 新增第 9/10/11 条、§三 第 9/10/14 条转已裁、校勘第十三轮；`doc/index.md` 规范版本升 0.5。
- v1.8（2026-09-24）：**Role 进语言（与 Module 同级）**——用户：「组织架构虽然是数据，但对于业务流程来说是必须的；惯例是在需求阶段就识别关键用户即角色（Role），因此架构设计时 Role 作为和 Module 分解同等重要的设计，进 mmda-lang 语言」。落点：[`doc/meta-model.md`](doc/meta-model.md) **新增 §8.1**（属性表 / 为什么同级 / 与「权限在 IDE 配置」的关系）、[`doc/requirements.md`](doc/requirements.md) §2 新增「关键用户（角色 / Role）」行 + 惯例补注、[`doc/project.md`](doc/project.md) §3 `.mr` 行、[`doc/architecture-review.md`](doc/architecture-review.md) 关注点表、[`doc/workflows.md`](doc/workflows.md) §1.2、[`doc/ide/specification.md`](doc/ide/specification.md) §4.8 域 2 改「两层分治」；§3.15、§6.2-23、§6.3 第 8 条、变更记录；`doc/errata.md` §五 第 12 条 + 校勘第十四轮；`doc/index.md` 规范版本升 0.6。
- v1.9（2026-09-24）：**运行架构落成（吸收作者《分层架构》概念设计图）**——新增 [`doc/runtime.md`](doc/runtime.md)（**四层职责**：Controller = API 开放 / Service = 商业逻辑 / Repository = 数据读写 / **缓存 = 横切面**；**两条路径**；**事务夹在 Before / After 拦截点中间**；**拦截点上升到语言**：`before`/`after` × 封闭生命周期点 + 设计师配置/程序员定制；缓存单点出口；装配与聚合是生成物；现状缺口：业务 Controller 手写 74/16/9/3、`EntityFactory` 未融合 Repository）；[`doc/architecture-review.md`](doc/architecture-review.md) 新增 **§2.1b ARCH-107…110**（首版不进硬门禁）；[`doc/targets.md`](doc/targets.md) L2 补事务与钩子、能力矩阵新增「生命周期钩子」行；§3.16 新增、§5 目录、§6.2 第 24 条、§6.3 第 9 条、变更记录；`doc/errata.md` §五 第 13 条 + §三 第 20/21/22 条 + 校勘第十五轮；`doc/index.md` 阅读顺序插入与版本升 0.7。
- v1.10（2026-09-24）：**API 契约落成（语言层面怎么定义 API + 对接 API 管理工具）**——新增 [`doc/api.md`](doc/api.md)：**API 由「模块分解 + Feature + 视图 + Action + Role + 字段约束」推导**（不造 `api` 顶层块、不造 DTO 概念）、语言层只补**暴露边界 `expose`** 与**稳定度/版本**、OpenAPI 3.1 由 Rust 内核生成 + **契约测试（一致性测试的 API 维度）**、设计/测试/运维三面口径（API 面板、机械用例 + Mock、**网关粗粒度 vs Controller 细粒度**、`deprecated` 调用量作退役倒计时）、与外部工具**单向互动**（导出 ✅ / 逆向导入 ✅ / **回写 ❌** / 对账 ✅）、实测现状（三端 API 文档能力全缺、端点模板逐字重复）、**8 条待裁**；[`doc/runtime.md`](doc/runtime.md) §1 Controller 行交叉引用；[`doc/targets.md`](doc/targets.md) L2 补「API 文档（OpenAPI 生成与契约测试）」+ 能力矩阵新增「API 文档 / OpenAPI」行；[`doc/testing.md`](doc/testing.md) §10 关系表补一行；§3.17 新增、§5 目录、§6.2 第 25 条、变更记录；`doc/errata.md` §三 第 23 条 + 校勘第十六轮；`doc/index.md` 阅读顺序与版本 0.8。
- v1.11（2026-09-24）：**API 边界 = module 边界（插件不侵入语言）**——[`doc/api.md`](doc/api.md) 新增 **§1.1 第一原则**（module 边界 = API 边界 = 权限边界 = 文档分组边界；权限按 module 授予 ⇒ 无归属元对象结构上不可开放）、**插件两条边界**（只许读产物/报对账；禁止写元数据、禁止工具概念进语法）与**判据**（凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍）、**无归属元对象的六类决策表**（业务对象 / 共享主数据→基础模块 `Base` / 枚举不需归属 / 从属对象 / 技术对象默认 `internal` / 平台对象，实测 `data/models/base/` 77 个 + `mes/` 138 个）；§6 补「无归属对象」实测行、§7 补第 9 条待裁（基础模块固定名与 `sops` → OpenAPI 权限映射）；[`doc/architecture-review.md`](doc/architecture-review.md) §2.1 新增 **ARCH-111**；§3.17 补第一原则、§6.2-25 补第 9 条、§6.3 第 10 条、变更记录；`doc/errata.md` §五 第 14 条 + 校勘第十七轮；`doc/index.md` 版本升 0.9。
- v1.12（2026-09-24）：**OpenAPI 原生支持（OAS 3.1.0 基准）+ AI 造数**——[`doc/api.md`](doc/api.md) **新增 §3 与 OAS 3.1.0 的逐条对齐**（四条判据：内核一等后端 / 过官方 Schema 校验 / 契约测试双向对账 / 语言层不出现 OAS 术语；根对象与 30 个 OAS 对象逐字段来源；**Operation 12 字段**（`#operation-object-example`）；五视图 / Action → 端点与状态码（含非法转移 409）；**逻辑类型 → JSON Schema 2020-12 映射**（实测 3.1 差异：`nullable` 全文 0 次、`contentEncoding` 替代 `format: byte`、`webhooks` 原生、`info.summary`/`license.identifier`）；securityScopes 与 `x-mmda-*` 溯源指针；**覆盖度自检 23 + 5 + 2 = 30**）、**§3.9 Mock 数据两层造数**（机械层零 AI + AI 语义层；护栏：不得发明结构 / 过双校验 / 种子与 provenance / 造数不需双签而断言必须双签）；§8 待裁 9 → **16 条**（新增存量路径兼容、`decimal` JSON 表示、`operationId`、scope、`webhooks`、官方 Schema 校验进门禁、AI 造数固化）；[`doc/testing.md`](doc/testing.md) **新增 §4.3**（Mock 数据生成）+ §8 命令面 `mmda mock` + MCP `mmda_mock_gen` + §10/§11 指针；[`doc/ai/tools.md`](doc/ai/tools.md) §2.4 补 `mmda_api_export`/`mmda_api_check`、§2.5 补 `mmda_mock_gen` 与造数边界；[`doc/targets.md`](doc/targets.md) L2 与能力矩阵补 OAS 3.1.0 原生 + mock 造数；本文件 §3.17 补两条已裁、§6.2-25 补第 ⑩–⑯ 条、§6.3-10 补充；变更记录；`doc/errata.md` §五 第 15 条 + §三 第 23 条更新 + 校勘第十八轮；`doc/index.md` 版本升 0.10。
- v1.13（2026-09-24）：**API 契约四条落定**（作者：「1. REST语义 / 2. 按你建议 / 3. 进 / 4. 要」）——① **存量路径取 A 方案**（REST 语义 + `legacyPathStyle` 兼容开关，迁移期双版本并存）；② **序列化精度优先**（`decimal`/`money` → `string` + `pattern`，超 JS 安全整数的 `int64`/`uint64` → `string`，`Timestamp` → `date-time`，三端一致）；③ **官方 Schema 校验 + 契约测试进硬门禁**；④ **AI 造数样本固化**（种子 + provenance 进版本控制）。落点：[`doc/api.md`](doc/api.md) §3.1-2 判据 2、§3.4 存量冲突改写、§3.5 类型映射三条、§3.9 护栏 3、**§8 重构成「8.1 已裁 / 8.2 待裁」**（待裁 16 → 12 条）；[`doc/testing.md`](doc/testing.md) §4.3 护栏 3；本文件 §6.2 第 25 条标已裁 4 条、§6.3 新增第 11 条、变更记录；`doc/errata.md` §五 第 16 条 + §三 第 23 条 + 校勘第十九轮；`doc/index.md` 版本升 0.11。
- v1.14（2026-09-24）：**仓重命名 `D:\2026\c` → `D:\2026\rust` + 规范真源入 git**（作者原话：「把 D:\2026\c 重命名为 D:\2026\rust，我当时想着用 c 语言。然后也改下现在项目的路径配置」——**命名理由是最初想做 C 语言，后定为 Rust 单实现**）。落点：① **全仓与相关工程配置的路径引用同步**（本文件 4 处、[`doc/protection.md`](doc/protection.md) 算法仓路径 1 处、[`doc/errata.md`](doc/errata.md) 校勘一轮记录 1 处；仓外：技能 `mmda-lang-development` 21 处、`mmda-lang-spec-repo` 6 处、探针脚本 9 个文件 12 处，共 **46 处**）；② 台账改为已落状态——§0 `git init` 行、§2.1「版本控制」行、§4 P0 第 ② 项、§7 风险表「无版本控制」行、§8 回滚段，均改记 **远端 `github.com/Roy7611/mmda-lang`（公开仓，MIT）首提交 `0679a30`**；③ §6.2-1 散文中仓名 `c` → `rust`；④ `doc/errata.md` 校勘第二十轮；`doc/index.md` 版本升 0.12（**无规范内容变更，仅仓路径与台账**）。
