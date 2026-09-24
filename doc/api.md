# API 契约（语言层面的 API 定义与集成）

> **一句话**：**API 不是新的一层声明，而是「模块分解 + Feature + 视图 + Action + Role + 字段约束」的派生物**。语言层只需要补**两样最小声明**（暴露边界、稳定度/版本），OpenAPI 文档是**产物**，YApi / Apifox / Swagger / Postman 是**消费者**。
> **为什么这么定**：与「用例是派生物」「装配是派生物」同一条原则——**同一份声明长出多个产物**；也与「DB 降级为产物/缓存」同一原则——**不允许出现第二真源**。
> 状态：草案（2026-09-24）· 联动 [`runtime.md`](runtime.md)（Controller = API 开放 / 进入路径）、[`meta-model.md`](meta-model.md)（Module / Feature / Action / Role）、[`presentation.md`](presentation.md)（五视图）、[`testing.md`](testing.md)（用例来源与契约测试）、[`targets.md`](targets.md)（三端文档插件挂接）、[`quality.md`](quality.md)（运维面指标）。

---

## 1. 语言层怎么"定义" API：从已有声明推导

**不新增 `api { … }` 顶层块**——模块分解完成之后，API 的绝大部分已经**隐含存在**了：

| 已有声明 | 推导出的 API 元素 | 实测依据 |
| --- | --- | --- |
| **Module 树**（`M.03.001` Subsystem / Module / Feature） | **路径前缀 + 文档分组（tag）**；模块边界 = API 边界 | 手写控制器用资源名做前缀（`mmda-mes` 里 `@RequestMapping("/AlternativeStrategies")`），**没有模块段** → 推导规则要补模块前缀 |
| **Feature 绑定的 Record**（`recordRef`） | **资源（resource）+ schema**（字段 / 类型 / 约束 / 默认值） | `MetaUiField` 已含 dataType / nullable / maxLength / 分组 |
| **五视图**（index / editor / details / search / report） | **CRUD 端点模板** | 实测模板在各模块**一模一样**：`POST /create`、`GET ""`（列表）、`GET /{id}`、`POST /save`、`POST /{id}/delete`、`POST /deleteAll`（`/AlternativeStrategies` 与 `/BackgroundTasks` 逐字相同） |
| **Action**（`moduleCode` + `actionName` + `statusTransition` + 守卫） | **操作端点** `POST /{Resource}/{id}/{action}`（审批、作废…）；守卫 → 前置条件与错误码 | `statements.md` 的 Action 声明 |
| **查询参数形态** | 分页 / 排序 / 过滤参数 | `mmda-core-api/.../web/SearchParam.java:7-10`：`pageSize` / `pageNo` / `sorts`（+ filters） |
| **字段约束 / 默认值** | OpenAPI `schema` 的 `required` / `maxLength` / `enum` / `default` / `format` | 约束即校验，无需二次声明 |
| **STM 状态机** | 合法状态转移的**可判定前置**（非法转移 → 404/409 的契约） | `meta-model.md` §Action 的 `statusTransition` |
| **Role**（`auth module` / `actions` / `scope`） | **securitySchemes + scopes + 每端点的授权要求** | [`meta-model.md`](meta-model.md) §8.1 |
| **事件**（`events.md`） | 对外通知：webhook / SSE / SignalR 的回调描述 | Java 无总线、C# 有 `IEventBus`（[`targets.md`](targets.md)） |
| **capability**（`targets.md` §3） | 各端**文档插件的挂接**（Java springdoc / C# Swashbuckle / TS 只消费） | C# 已在 `Mmda.Iot/Mmda.Iot.Server/Mmda.Iot.Server.csproj:20` 装 `Swashbuckle.AspNetCore 6.9.0` |

### 1.1 module 边界 = API 边界 = 权限边界（插件不得侵入语言）

**这是本篇的第一原则**：语言只定义 **module（边界）+ 数据模型（schema）+ 权限（谁能调）**，三者一确定，**该开放哪些 API 就已经约定了**。

**为什么是硬的（不是设计口味）**：`Role` 的授权是**按 module 授的**（`auth module` / `actions` / `scope`，[`meta-model.md`](meta-model.md) §8.1），模块/功能节点上还有 `sops` 操作位掩码决定开放什么操作，加上 ARCH-104（数据所有权唯一）与 ARCH-106（无孤立模块）——四条合起来推出：

> **module 边界 = API 边界 = 权限边界 = 文档分组边界，四个边界一个来源。**
>
> 推论：**没有 module 归属的元对象 = 没有授权对象 = 结构上不可开放**（不是我选择不开放，是权限模型不允许）。

**插件的两条边界**（YApi / Apifox / Swagger / Postman 都适用）：

| | 允许 | 禁止 |
| --- | --- | --- |
| 读 | **读产物**：OpenAPI 文件、`MetaUi` 元数据、元数据快照 | —— |
| 报 | **报对账**：把外部工具里的改动 diff 成报告，转成「待回收的需求」走正常流程 | —— |
| 写 | —— | **写语言文件 / 元数据**；**把工具概念写进语法**（不因为 Apifox 有"目录"就发明分组语法，不因为 Swagger 有 `tag` 就要求声明 tag——tag 由 module 树推导） |

> **判据一句话**：**凡能从 module / 数据模型 / 权限推导出来的，语言里不许再声明一遍。**（与「一个概念只留一个主人」同源）

**无 module 归属的元对象怎么办**（作者语：「我还没想清楚」→ 以下是现行惯例的实测口径）：

| 对象类型 | 语料实例（`examples/mmda-mes`） | 归属 | API |
| --- | --- | --- | --- |
| 业务对象 | `data/models/mes/*`（**138 个**） | 所属业务模块的 Feature（节点 `model` 字段绑定） | 按 `sops` 开放 CRUD |
| **共享主数据** | `Bank` / `Carrier` / `Country` / `CurrencyUnit` | **基础模块 `Base`**（`biz/base.ma`：`id: B`、`db: base`、**模块级 `sops: READ`**、子节点按需 `CRUD`，如 `B.01.001 Department`） | 模块级只读 + 子节点按需 |
| 枚举 | `.me` | **不需要归属** | **无端点**——枚举值随视图 / `MetaUi` 下发，前端不必单独取 |
| 从属对象 | `Address` / `Contactor` | 不单独归属（挂在主对象关系上） | 无端点（随主对象装配，[`runtime.md`](runtime.md) §6） |
| 技术对象 | `AuditTrail` / `Attachment` / `BackgroundTask` | 不对外 | 默认 `internal`（运维可见、业务不可见） |
| 平台对象 | 用户 / 角色 / 租户 | 平台模块 | 独立端点，受权限保护 |

**三条结论**：① **枚举"无归属"根本不是问题**（它本来就不该有独立端点）；② 真正需要 `internal` 默认值的只有「从属对象」与「技术对象」两类；③ **默认不开放**：没有 owner module 的 Record 不出 API——规则化为 **ARCH-111**（[`architecture-review.md`](architecture-review.md) §2.1）。

**基础模块与 `sops` 的映射（✔ 已裁 2026-09-24，§8.2-9）**：基础模块**沿用语料名 `Base`**（不改成 `base`/`platform`）；`sops` → OpenAPI 权限：**`READ` → 只出读端点**（GET 类）**、`CRUD` → 全出**（读 + 写 + Action）。**作者此前记在此条上的「还没想清楚」随之清掉。**

### 1.2 语言层只需补两样（最小新增）

| 声明 | 作用 | 形态（草案，待语法专题） |
| --- | --- | --- |
| **暴露边界** `expose` | 哪些 Feature / Action **对外**成为 API：`public` / `internal` / `none` | 声明在 Feature 或 Action 上；**✔ 已裁 2026-09-24：默认 `internal`**，显式 `expose` 才对外（内部模块不会因为存在就变成公开 API，与「跨模块只走声明接口」同源；见 §8.2-1） |
| **稳定度与版本** | `stable` / `beta` / `deprecated` + `since` / `sunset` | 驱动 OpenAPI 的 `deprecated` 标记、网关告警与退役倒计时。**✔ 已裁 2026-09-24：进语言**（三端与网关都要读；见 §8.2-3） |
| （可选）**路径覆盖** | 少数需要自定义 `path` 的场景 | 默认由模块树推导；覆盖属于例外，要写理由 |
| （可选）**对外契约名** | 不把内部命名暴露给外部 | 复用 `Terminology`（[`architecture-review.md`](architecture-review.md) ARCH-401）的术语表 |

**不新增的东西**：① 不造 `api` 顶层块；② 不造「DTO / VO」概念——**Record + 视图投影就是 schema**；③ 不在语言里写任何工具名（YApi / Apifox 只出现在集成文档与生成配置里）。

---

## 2. 设计面：文档生成与 IDE

| 事项 | 口径 |
| --- | --- |
| **谁生成** | **Rust 内核**（它掌握全部声明）→ **OpenAPI 3.1**（JSON + YAML 各一份）；**每项目一份 + 每模块一份**（便于按模块交付给外包/合作方） |
| 产物位置 | `generated/<target>/openapi/`（generated 区，KEEP 边界规则不变——[`project.md`](project.md)） |
| **契约测试** | 三端生成的 Controller **实际行为 vs 生成的 OpenAPI schema** → 一致性测试的 **API 维度**（现有 L3 一致性 + UI 维度只测 TS，这里补第三维） |
| **IDE（设计期）** | 模块树旁挂 **API 面板**：按模块看端点清单、看某个声明影响哪些 API、与基线 diff（API 变更影响面） |
| 命令面（草案） | `mmda api export --format openapi3`、`mmda api diff --baseline`、`mmda api check`（契约测试）；**✔ 已裁 2026-09-24：独立子命令**，不与 `mmda generate` 合并（导出与生成是两个动作，CI 可分开跑；见 §8.2-5） |
| 与「契约先行」的关系 | MMDA 比 contract-first **更前一层**：先有元数据（模块/对象/视图/角色），OpenAPI 是它的投影；**手改 OpenAPI 不回写**（§7） |

---

## 3. 与 OAS 3.1.0 的逐条对齐（"原生支持"的落点）

> **裁决（2026-09-24，作者）**：OpenAPI **有参考标准 → 必须原生支持**，基准 = **OAS 3.1.0**。
> 人读规范：`https://spec.openapis.org.cn/oas/v3.1.0.html`（中文镜像，`#operation-object-example` 等锚点可用）。
> 机器可读：官方 JSON Schema `https://spec.openapis.org/oas/3.1/schema/2022-10-07`（**实测 HTTP 200**）、Schema 方言 `https://spec.openapis.org/oas/3.1/dialect/base`（**实测 200**）。
> ⚠️ 实测提醒：`.cn` 镜像**只提供 HTML 规范**，其 `/oas/3.1/dialect/base` 不可解析（curl 返回 000）——**校验与 `jsonSchemaDialect` 一律用 `spec.openapis.org` 的地址**。

### 3.1 "原生支持"的四条判据（可验证，不是口号）

| # | 判据 | 怎么验 |
| --- | --- | --- |
| 1 | **生成器是内核一等后端**：`mmda generate --target openapi`（与 java / csharp / ts 同级），**直接读 IR**，不经任何注解反射 | 三端实测：Java 无 springdoc/swagger 依赖、C# 有 `Swashbuckle` 但 **0 注解** → **不靠注解也能出全量文档**（§7） |
| 2 | **产物过官方 Schema 校验**：根 `openapi: "3.1.0"`、`jsonSchemaDialect` 指向 OAS 方言，整份文档通过官方 JSON Schema | ✔ **已裁（2026-09-24）：进硬门禁**——CI 一条命令，失败即阻断（与 §4 契约测试同一套，B 级可判定） |
| 3 | **契约测试双向对账**：三端实际行为（状态码 / 响应 schema / 必填 / 枚举 / security）vs 生成的文档 | 一致性测试的 **API 维度**（§4） |
| 4 | **语言层不出现 OAS 术语**：没有 `tags` / `operationId` / `paths` / `schema` 这些词——它们全是投影；语言只多声明**暴露边界**与**稳定度**（§1.2） | 语法审查（"原生"≠"把标准抄进语法"） |

> 判据 1 与 §1.1 互为里外：**内核原生生成 ⇒ 不需要插件 ⇒ 插件只剩消费角色**。

### 3.2 根对象与公共对象（逐字段）

OAS 3.1 共 **30 个对象**（实测清单 4.8.1–4.8.30）。根对象与公共对象的来源：

| OAS 字段 | 我们的来源 | 备注 |
| --- | --- | --- |
| `openapi`（**必需**） | 生成常量 `"3.1.0"` | 规范明确它与 API 的 `info.version` **无关** |
| `info`（**必需**） | 项目清单 `*.mmda` | `title`=项目名、`version`=项目版本、`description`=项目 `doc`（CommonMark）、`summary`（3.1 新增）、`contact`（name/url/email）、`license`（name/**identifier**（3.1 新增 SPDX）/url）、`termsOfService` |
| `jsonSchemaDialect` | 常量 OAS 方言 URI | 见 §3 抬头 |
| `servers` | **Profile 的环境段**（dev/test/prod 各一个 Server 对象：`url` 必需 / `description` / `variables`） | 多租户：用 **Server Variable**（`{tenant}`）或每租户一份文档 |
| `paths`（Paths：`/{path}` → Path Item） | **module 树 × Feature × 五视图 × Action** | 核心，见 §3.3 |
| `webhooks`（Map[名称 → Path Item]，**3.1 新增**） | **`events.md` 的领域事件** | 规范原文：描述"由 API 调用以外的其他方式（如带外注册）发起的请求"——**正好是领域事件的语义**；与 `callbacks` 密切相关 |
| `components`（10 个 Map） | `schemas`←Record + 视图投影；`parameters`←`SearchParam`；`responses`←统一错误；`examples`←**`.mt` 用例样本 + AI 造数**（§3.9）；`securitySchemes`←Role 的认证方式；`headers`←租户 / TraceId；其余（`links`/`callbacks`/`pathItems`）按需 | **不造 DTO**（§1.2） |
| `security` | Profile 默认认证；端点级覆盖 ← Role | §3.6 |
| `tags`（Tag：`name` 必需 / `description` / `externalDocs`） | **module 树路径**（如 `mes/工单管理`） | tag 名由模块 label 出，**不由作者另起** |
| `externalDocs`（`url` 必需） | 可选，指向项目文档站 | |
| 多文档拆分 | `Reference` 对象 + `$ref`（3.1 允许 `summary`/`description` 覆盖），相对引用按规范 §4.6 解析 | **每模块一份 + 根一份**（§2 产物布局）；规范建议根文件命名 `openapi.json` / `openapi.yaml`（§4.3）→ 沿用，根文件用 `$ref` 连各模块 |

> **文档有效性硬约束**（规范 §3.1）：OpenAPI 文档**必须至少含 `paths` / `components` / `webhooks` 之一**；`paths` 的键必须以 `/` 开头；**路径模板里的每个 `{var}` 必须在 Path Item 或其 Operation 的 `parameters` 里有对应 path 参数**（§3.2）——所以生成器必须**成对**产出路径与参数，否则校验直接失败（这条天然防住"路径与参数两处漂移"）。

### 3.3 Operation 对象 12 个字段逐条（`#operation-object-example`）

| OAS 字段 | 来源 | 示例 | 状态 |
| --- | --- | --- | --- |
| `tags` | Feature 的祖先模块路径 | `["mes/工单管理"]` | 推导 |
| `summary` | Feature / Record 的 `label` | 工单 | 推导（中文 label 直接出） |
| `description` | `doc` 字段原文（CommonMark） | … | 推导 |
| `externalDocs` | 可选 | 模块文档 URL | 可选 |
| `operationId` | **`<moduleName>_<featureName>_<op>`**（✔ 已裁 2026-09-24，作者原话「我希望是 `moduleName_featureName_op`」） | `mes_WorkOrder_create` | **✔ 已裁**：ASCII、不含中文、同项目内唯一（`mmda check` 校验）；**SDK 与客户端代码依赖它，必须稳定**；**字形 = 模块名照抄模块段（小写）、Feature 名照抄模型名（Pascal）**，随 §8.2-2c 一并定稿 |
| `parameters` | 路径参数 `{id}` + 查询（`SearchParam`：`pageNo`/`pageSize`/`sorts`/filters）+ 头部（`X-Tenant`、`traceparent`） | | 推导 + 待裁（filters 编码） |
| `requestBody` | `editor` 视图的字段投影 → `application/json`（`content` 必需；`required` 由表单必填推导，默认 `false`） | | 推导 |
| `responses` | 统一响应封装（Profile 决定 `raw` 还是 `{code,data,msg}`）+ 各状态码（§3.4） | | 需 Profile 声明 |
| `callbacks` | 事件 → 操作级回调（与 `webhooks` 同源） | | 首版不做 |
| `deprecated` | **稳定度声明** | | **语言层新增**（§1.2） |
| `security` | Role 授权（`auth module` / `actions` / `scope`）→ scopes | `[{bearerAuth: ["mes.workorder:read"]}]` | 推导（§3.6） |
| `servers` | 一般省略（用根级） | | — |

### 3.4 五视图 / Action → 端点与状态码

**路径形态（✔ 已裁 2026-09-24，§8.2-2 / 2b）**：下表里的 `/{模块路径}/{资源}` 一律写成 **`/api/<模块小写>/<模型名复数>`**——**作者原话：「我现在 api 是：`GET /api/mes/WorkOrders` 复数形式」**。例：`GET /api/mes/WorkOrders`、`PUT /api/mes/WorkOrders/{id}`、`POST /api/mes/WorkOrders/{id}/approve`。**残余细则 2c**（未定不许进生成器）：`/api` 写死还是 Profile 可配、复数变形规则（§8.2-2）。

| m 声明 | 端点 | 方法 | 成功码 | 说明 |
| --- | --- | --- | --- | --- |
| `index` / `search` | `/{模块路径}/{资源}` | GET | 200 | 分页 + 排序 + 过滤（`SearchParam`） |
| `details` | `/{模块路径}/{资源}/{id}` | GET | 200 / 404 | |
| `editor`（新建） | `/{模块路径}/{资源}` | POST | 201 + `Location` | |
| `editor`（编辑） | `/{模块路径}/{资源}/{id}` | PUT | 200 | |
| `delete` | `/{模块路径}/{资源}/{id}` | DELETE | 204 | 软删由 Profile 决定 |
| `deleteAll` | `/{模块路径}/{资源}/deleteAll` | POST | 200 | 危险操作（`x-mmda-dangerous`） |
| 导入 / 打印 / 上传 | `/{模块路径}/{资源}/{op}` | POST | 200 / 202 | `multipart/form-data`（对上 Media Type / Encoding 对象） |
| **Action** | `/{模块路径}/{资源}/{id}/{action}` | POST | 200 / **409** | 非法状态转移 → 409（STM 是契约的一部分） |
| 校验失败 | — | — | 400 | 字段级错误（与元数据约束同源） |
| 未认证 / 越权 | — | — | 401 / 403 | 拒绝路径**必须有用例**（[`testing.md`](testing.md) §2） |
| 并发冲突 / 唯一冲突 | — | — | 409 | |

**与存量手写代码的冲突（✔ 已裁 2026-09-24：取 A 方案）**：现有三端模板一律 `POST /save`、`GET ""` 取列表、`POST /{id}/delete`，**既不符合 REST 语义也没有模块前缀**。裁决：

- **生成物用 REST 语义**（POST 创建 / PUT 更新 / DELETE 删除 + `/api/{模块}/{资源复数}` 前缀）——上表即最终形态；
- **路径两段与字形（✔ 已裁 2026-09-24，§8.2-2 / 2b）**：第一段 = **模块（service）**、第二段 = **资源（repository / Record）**——**作者原话：「我们是 `/service/repository`」**；**字形 = 复数形式**（作者原话：「我现在 api 是：`GET /api/mes/WorkOrders` 复数形式」）= **`/api/<模块小写>/<模型名复数>`**（模块段小写 `mes`、资源段模型名原样 + 英语复数）。**⚠️ 残余 2c：`/api` 前缀写死还是 Profile 可配（建议 Profile `apiPrefix` 默认 `/api`、网关可剥）+ 复数变形规则（建议英语常规 `+s`／`ies`／`es`，**只加后缀不转写**，逆向去 `s` 即回模型名；不可复数化的名用模型原形并允许端点显式覆盖）**——见 §8.2-2；
- **同时提供 Profile 开关 `legacyPathStyle: true`**，保留 `POST /save`、`GET ""`、`POST /{id}/delete` 老路径，**迁移期双版本并存**（复用 §6 的稳定度机制：老路径标 `deprecated` + `sunset`，调用量归零后移除）；
- 存量为 B/C 两案（照抄历史包袱 / 只出新路径破坏现有集成）**不采用**。

### 3.5 Schema 对象：MMDA 逻辑类型 → JSON Schema 2020-12

Schema 对象 = **JSON Schema 2020-12 的超集**（OAS 方言 `https://spec.openapis.org/oas/3.1/dialect/base`）+ OAS 专有字段 `discriminator` / `xml` / `externalDocs` / `example`；`integer` 定义为"没有小数部分或指数部分的 JSON 数字"；OAS 另有 `format`：`int32` / `int64` / `float` / `double` / `password`。

| 逻辑类型（[`datatypes.md`](datatypes.md)） | JSON Schema | 备注 |
| --- | --- | --- |
| `bool` / `bit` | `boolean` | |
| `int8` / `int16` / `int24` | `integer` + `format: int32` | 范围用 `minimum` / `maximum` |
| `int32` | `integer` + `int32` | |
| `int64` | `integer` + `int64`；**超出 JS 安全整数范围时序列化为 `string`** | ✔ 已裁（2026-09-24）：**精度优先**——TS 端不丢精度，三端序列化一致 |
| `uint32` / `uint64` | `integer` + `int64`；**超界值同样用 `string`** | 同上 |
| `decimal(p,s)` / `numeric` / `money` | **`string`** + `pattern`（小数位 ≤ s） | ✔ 已裁：**精度优先**——不用 `number`（丢精度）；三端生成 `string`/`BigDecimal`，**不是 TS `number`** |
| `float` / `double` / `real` | `number` + `float` / `double` | |
| `Date` | `string` + `format: date` | |
| `Time` | `string` + `format: time` | |
| `DateTime` | `string` + `format: date-time` | |
| `DateTimeOffset` / `DateTimeZoned` | `string` + `date-time` | 偏移量在值里 |
| `Timestamp` | `string` + `format: date-time` | ✔ 已裁：不用 epoch 整数（可读性与跨端一致性优先） |
| `char` / `varchar` / `nchar` / `nvarchar` / `string` | `string` + `maxLength` / `minLength` | `charset` 不进 schema（传输层 UTF-8） |
| `uuid` | `string` + `format: uuid` | |
| `inet4` / `inet6` | `string` + `format: ipv4` / `ipv6` | |
| `BitStr` | `string` + `pattern: ^[01]*$` | |
| `BitVector8…64` / `BitSet` | `integer` + `minimum: 0` + `maximum: 2^N-1` | 位标志语义 → 待裁 |
| `blob` / `byteArray` | `string` + **`contentEncoding: base64`** | **3.1 与 3.0 的差异**：规范原文"与 3.0 相反，`format` 对内容编码没有影响"；大文件走 `multipart/form-data` 不 base64 |
| `json` / `jsonb` | 无类型约束（任意） | |
| `clob` / `text` | `string`（不给 `maxLength`） | |
| 可空 `?` | **`type: [T, "null"]`** | **3.1 的写法**：`nullable` 关键字已从规范移除（**实测：3.1 全文 `nullable` 出现 0 次**） |
| 必填 | `required: [...]` | 与 Record 的必填同源 |
| 默认值 | `default` | |
| 枚举 `.me` | `enum: [...]` + `x-mmda-enum: <EnumName>` | 位标志枚举 → 待裁 |
| 引用 `@Ref` / `REF x(...)` | `$ref: "#/components/schemas/<Record>"`（跨模块用相对 `$ref`） | **引用投影**（`REF User(userId,userName)`）→ 生成精简 schema，不返回整对象 |
| **`@Ref` / 枚举的显示标签** | **`customProperties: { "$<字段名>": <标签> }`**（对象级附加属性；标签随 locale 变） | **✔ 已裁（2026-09-24）保留**——旧实现与新前端都已依赖该形态，**改约定动作太大**；**不另开 `xxxLabel` 投影字段**（同一事实只在契约里写一处） |
| 数组 | `array` + `items` | |
| **视图投影** | 每视图独立 schema（`WorkOrder_index` / `WorkOrder_editor` / …）；`details` 视图全 `readOnly: true` | **不造 DTO**（§1.2） |
| 隐藏 / 只读字段 | 隐藏字段**根本不投影**；只读字段出 `readOnly: true` | 与 `MetaUi` 同一套可见性规则 |
| STM 状态机 | 有子类型时 `oneOf` + `discriminator`；**非法转移不进 schema**，进 409 的响应描述 | |
| 多租户 / 行级数据范围 | **不进 schema**，用 `x-mmda-scope` | schema 只描述形状，不描述可见性 |

**`example` 的来源**：`.mt` 用例里的样本 + AI 造数（§3.9）→ `components.examples` 与端点级 `example`。**用例是派生物 ⇒ 例值也是派生物**。

### 3.6 Security Scheme / Security Requirement

| 事项 | 口径 |
| --- | --- |
| 认证方式 ← Profile | `type: http` + `scheme: bearer` + `bearerFormat: JWT`（首选，贴合三端现状）；或 `type: oauth2` + `flows`（`authorizationUrl` / `tokenUrl` / `refreshUrl` + `scopes`）；或 `type: openIdConnect` + `openIdConnectUrl` |
| **scope 命名** | **`<模块路径>:<操作>`**（`mes.workorder:read`、`mes.workorder:approve`）——由 module 树 + `sops` **机械生成**，与 `tags` 同理，**不由作者起名**。**✔ 已裁 2026-09-24（粒度）：按现状 = 模块权限 + Action 权限**——**module 出读 / 写 scope，Action 出专属 scope，Feature 级不出 scope**（见 §8.2-13） |
| 端点级 `security` | `[{<scheme>: ["<scope>", …]}]` ← Role 的 `auth module` + `actions` + `scope` |
| Security Requirement 语义 | `Map<方案名, [scope]>`：**同一 map 内多方案 = AND，数组内多对象 = OR** → 我们**只用单方案 + 多 scope**，避免歧义 |
| OAS 表达不了的两件事 | ① **行级数据范围**（"只能看本部门工单"）→ `x-mmda-scope`；② **状态转移权限**（"只有 X 状态能审批"）→ `x-mmda-transition`；**两者都必须进契约测试**（越权用例，[`testing.md`](testing.md) §2） |

### 3.7 规范扩展 `x-`（"投影"与"第二真源"的分水岭）

每个 Operation / schema / 参数带**溯源指针**：

`x-mmda-module: M.03.001`、`x-mmda-feature: F.0007`、`x-mmda-record: WorkOrder`、`x-mmda-view: index`、`x-mmda-action: Approve`、**`x-mmda-src: biz/mes.ma:124`**（IDE 里从 OpenAPI 一键跳回 m 源码）、`x-mmda-scope`、`x-mmda-transition`、`x-mmda-dangerous`、`x-mmda-generated: ai:model@时间`（§3.9 造数）。

规则：**`x-mmda-*` 只由生成器出**；`x-yapi-*` / `x-apifox-*` 只允许外部工具在它们自己那份里加，**不得回写**（§6）。

### 3.8 首版覆盖度自检（防"号称原生支持、实际只出了 `paths`"）

| 分类 | 对象（30 个中的） | 数量 |
| --- | --- | --- |
| **首版生成** | OpenAPI / Info / Contact / License / Server / Server Variable / Components / Paths / Path Item / Operation / External Documentation / Parameter / Request Body / Media Type / Responses / Response / Header / Tag / Reference / Schema / Example / Security Scheme / Security Requirement | **23** |
| **按需生成** | Encoding（仅 `multipart/form-data`）、Discriminator（仅子类型）、OAuth Flows / OAuth Flow（仅 OAuth2 认证）、XML（不做） | **5** |
| **首版不做** | Callback、Link（事件先用顶层 `webhooks` 表达） | **2** |

**验收**：① 生成文档 **100% 通过官方 Schema 校验**；② 上表每一类都要能指出**推导来源**（§3.2–§3.6 的表），**指出不出来的就不生成**；③ 契约测试（§4）覆盖所有生成端点。

### 3.9 Mock 数据：机械打底 + **AI 填语义**（撰写用例与联调的提速手段）

> **裁决（2026-09-24，作者）**："API 测试要能借助 AI 的能力自动生成 mock 数据，这是撰写用例与联调的提速手段。"

**Mock 的归属（✔ 已裁 2026-09-24，§8.2-6）**：**IDE 内置**（开发期即时可用，不依赖外部服务）；**外部工具只做展示与协作**（导出 ✅ / 回写 ❌，见 §6）。

**关键切分：结构由 schema 定，数据分两层造**——

| 层 | 谁来做 | 造什么 | 特点 |
| --- | --- | --- | --- |
| **① 机械层（确定型）** | Rust 内核，**零 AI** | 引用图拓扑排序后逐表造数（满足外键）；枚举取值、必填、长度 / 精度 / 范围的 min / max / min-1 / max+1；日期与时区边界；状态机的**可达状态** | **可复现**（固定种子）、可进基线、是契约测试的地基 |
| **② AI 层（语义层）** | AI Agent | 中文公司名 / 物料名 / 部门与岗位、数量与金额的业务合理组合、**跨字段联动**（"已审批的工单必有审批人与时间"）、**刁钻样本**（越界、null、超长、时区跨日、`decimal` 精度末位、并发重复键） | 让用例**读得懂、审得动**；也是杀死变异体的输入来源 |

**AI 造数的四条护栏**（与 [`testing.md`](testing.md) §4.2 同源，这里是数据专条）：

1. **AI 不得发明结构**：字段名、枚举值、状态名**只能取自声明**——出现声明里没有的值**直接判废**（不是"提醒"，是丢弃）。
2. **造出的每条数据必须过两道校验**：JSON Schema（由 §3.5 生成）+ 元数据约束（`constraint` / `formula` / 唯一键 / 引用完整性）。**不过校验的数据不许进基线**——否则 mock 数据会污染契约测试。
3. **可复现**：固定随机种子 + 记录 **provenance**（`x-mmda-generated: ai:<model>@<ts>`、提示词版本、种子）——✔ **已裁（2026-09-24）：种子与 provenance 随数据一起进版本控制（固化）**；否则回归时复现不了失败，"AI 造的数"就变成不可审计输入。
4. **AI 造数不是断言**：数据是**输入层**，AI 在此可以放开（这正是不需要双签的原因）；**断言与基线仍然只能由声明 + 人签字决定**（[`testing.md`](testing.md) §4.2-1）。

**用途三面**：① **提速写用例**——先有数据再写期望值，比"边想数据边写断言"快一个量级；② **Mock server**（§4）——前端 `vui` / `rui` 与第三方在真接口就绪前并行开发；③ **演示与培训**——同一份声明长出可演示的假数据，不碰真库。

**命令面（草案）**：`mmda mock --from meta --ai --seed <n> --out generated/<target>/mock/`；`mmda mock serve`（起 mock server，返回合 schema 与约束的数据）。

**与"用例是派生物"的衔接**：数据是派生物、断言是派生物 ⇒ **`examples` 也是派生物**（§3.5 末）；唯独**业务流程语义**来自需求（`REQ-x`）与业务人员签字，这三者别混。

---

## 4. 测试面

| 事项 | 口径 |
| --- | --- |
| **用例来源（新增一类）** | OpenAPI → **机械用例**：每端点 × 角色（Role）× 边界（缺参 / 越权 / 非法状态转移 / 分页边界 / 并发）。用例仍是**派生物**（[`testing.md`](testing.md) §1） |
| **契约测试** | 响应必须符合 schema（字段类型/必填/枚举），否则失败——**B 级**（生成后可判定），可进质量门禁 |
| **Mock server** | 由 OpenAPI 起 mock（前端 `vui`/`rui` 与第三方并行开发、演示、联调）；归属（IDE 内置 vs 外部工具）待裁；**数据来源 = 机械打底 + AI 填语义**（§3.9） |
| **外部工具用例** | Postman / Apifox 的 collection 可**导入作补充**，状态是「外部用例」：不进真源、不参与门禁，除非回写成 `.mt` |
| 性能 / 安全 | 阈值挂到端点（[`quality.md`](quality.md) §2.2）：响应均值 ≤ 5 s、并发 ≥ 500/800、TPS ≥ 80；越权用例属安全维度 |

---

## 5. 运维面

| 事项 | 口径 |
| --- | --- |
| **网关 vs Controller 边界** | **网关做粗粒度**（TLS、限流、IP/黑名单、统一凭证校验、流量镜像）；**Controller 做细粒度**（Role × module × action × scope 的数据范围）——**两边不重复实现**（与 [`runtime.md`](runtime.md) §1 的进入路径对齐）。**✔ 已裁 2026-09-24（§8.2-7）** |
| **可观测** | 每端点的延迟 / 错误率 / 调用量进质量看板（[`quality.md`](quality.md) §2.3）；**`deprecated` 端点的调用量 = 退役倒计时依据** |
| **变更审计** | API diff 进 `changelog/` + 影响面（[`workflows.md`](workflows.md) §8 的 L0–L3）；**破坏性变更必须有双版本并存期** |
| **退役** | `stable → deprecated → sunset` 三段，与 IDE 全生命周期的「退役」阶段对齐（[`quality.md`](quality.md) §5） |
| 文档发布 | 生成的 OpenAPI 可由 CI 推向文档站点/Swagger UI（也可推到 YApi/Apifox 做展示层） |

---

## 6. 与外部工具的互动（关键：**单向**）

| 方向 | 允许？ | 说明 |
| --- | --- | --- |
| **导出** | ✅ | MMDA → OpenAPI → **YApi / Apifox / Swagger UI / Postman / 网关配置**（它们都是消费者） |
| **导入（逆向）** | ✅ 作为「接入」能力 | 从既有 OpenAPI **生成初始模块骨架**（遗留系统接入场景）——与 P4 的 DB→`.mmda` 反向导出同族，**一次性**且结果进真源后由人审。**✔ 已裁 2026-09-24（§8.2-8）：产出 = 先出「导入报告 + 骨架」，人审后入真源**，不直接写 `biz/*.ma` |
| **回写** | ❌ | 在 YApi / Apifox 里改的接口**不能自动回流**——否则出现**第二真源**（与「DB 降级为产物/缓存」同一原则，[`PLAN.md`](../PLAN.md) §3.2） |
| **对账** | ✅ | 把外部改动 **diff 出来**，转成「待回收的需求」走正常流程（`REQ-x` → 声明 → 用例），不直接改模型 |
| 工具扩展字段 | ⚠️ 只出 | `x-yapi-*` / `x-apifox-*` 只允许出现在 **generated 区**的输出里，不回写模型 |

> **为什么坚持单向**：外部 API 工具是**展示与协作层**（评审、mock、联调、文档门户），不是编辑真源的地方。一旦双向，模型与文档必然漂移，而漂移在 API 层最贵——**前端和第三方已经在按它写代码了**。

---

## 7. 现状与缺口（实测）

| 事项 | 现状 | 缺口 |
| --- | --- | --- |
| **API 文档能力** | **三端都没有**：Java 无 springdoc/springfox/swagger 依赖（`grep springdoc\|springfox\|swagger --include=pom.xml` 仅 2 处命中，**都是阿里云短信 OpenAPI 文档注释**，非依赖）、`@Operation/@Tag/@Api` **0 个文件**；C# 装了 `Swashbuckle.AspNetCore 6.9.0`（`Mmda.Iot/Mmda.Iot.Server/Mmda.Iot.Server.csproj:20`）但**0 处注解使用**（`OpenApiOperation`/`SwaggerOperation`/`[Produces` 均 0）；TS 无 openapi 代码生成 | 从 IR 生成 OpenAPI（本文件 §2） |
| **端点模板** | **手写但逐字重复**：`/create`、`GET ""`、`GET /{id}`、`/save`、`/{id}/delete`、`/deleteAll` 在 `mmda-mes` 的多个控制器里完全相同 | 模板应为生成物；业务 Controller 逐步消失 |
| 查询参数 | `SearchParam`（`pageNo`/`pageSize`/`sorts`）已有形态（`mmda-core-api/.../web/SearchParam.java:7-10`） | 未与元数据的过滤/排序声明打通 |
| 路径前缀 | 手写用资源名 PascalCase（`/AlternativeStrategies`），**无模块前缀** | 推导规则要定模块段与命名规范 |
| API 元数据类 | **三端 0 个**（`grep -rn 'MetaApi\|ApiDoc\|ApiSpec\|OpenApi' --include=*.java/--include=*.cs` 在 `D:\2026\java` 与 `D:\2026\cs\MMDA` 均 0 命中；TS 同） | 是否需要"接口/端点"作为元模型元素（**建议：不新增**，全部推导） |
| **无归属对象** | 实测：**共享基础数据已归属 `Base` 模块**（`data/models/base/` **77 个** `.mm` 被 `biz/base.ma` 用节点 `model` 绑定，29 处）；`data/models/mes/` 138 个归业务模块 | 默认不开放（无 owner module = 无授权对象）；从属 / 技术对象默认 `internal`（§1.1） |
| 通用 API | `mmda-core-api/.../ReactiveApiController.java`（399 行、23 处 Mapping）只服务元数据面 | 业务端点未纳入同一生成体系 |

---

## 8. 裁决记录与待裁

### 8.1 ✔ 已裁（2026-09-24）

| # | 议题 | 裁决 | 落点 |
| --- | --- | --- | --- |
| 10 | **存量路径兼容** | **取 A 方案**：生成物用 **REST 语义**（POST 创建 / PUT 更新 / DELETE 删除 + `/{模块路径}/{资源}` 前缀）；同时给 Profile 开关 `legacyPathStyle: true` 保留 `POST /save` 等老路径，**迁移期双版本并存**（老路径标 `deprecated` + `sunset`，调用量归零后移除） | §3.4 |
| 11 | **`decimal` / `int64` / `Timestamp` 的 JSON 表示** | **精度优先**：`decimal(p,s)` / `numeric` / `money` → **`string` + `pattern`**（TS 端生成 `string`，不是 `number`）；`int64` / `uint64` **超出 JS 安全整数范围时用 `string`**；`Timestamp` → `string` + `format: date-time`（不用 epoch 整数）。**三端序列化必须一致**，进 capability 一致性用例 | §3.5、[`targets.md`](targets.md) L2 |
| 15 | **官方 Schema 校验与契约测试是否进硬门禁** | **进**（B 级：生成后可判定）；`mmda api check` 失败即阻断 CI | §3.1-2、§4 |
| 16 | **AI 造数的样本固化范围** | **要固化**：进基线的 AI 样本必须把**种子 + provenance 一并进版本控制**（能重建同一次造数）且过 schema + 约束双校验；**默认 AI 数据只进 mock 与开发期**，断言始终不由 AI 造数产生 | §3.9、[`testing.md`](testing.md) §4.3 |

### 8.2 ✔ 已裁（2026-09-24，作者逐条取定）

> 作者原话：「**1. 同意你的建议 / 2. 同意你的建议，/模块路径/资源，我们是 /service/repository / 3.–9. 同意 / 12. 我希望是 moduleName_featureName_op / 13. 这个我们已经实现，按照现状来，模块权限，Action 权限 / 14. 不明白**」

| # | 议题 | 裁决（2026-09-24） | 落点 |
| --- | --- | --- | --- |
| 1 | 暴露边界的默认值 | **默认 `internal`**，显式 `expose` 才对外（内部实现不会因为存在就变成契约） | §1.2、§1.1 |
| 2 | 路径推导规则 | **`/<模块路径>/<资源>`**；**作者补充：「我们是 `/service/repository`」= 第一段是模块（service）、第二段是资源（repository / Record）**。**✔ 已裁 2026-09-24（字形取 2b）：「复数形式」**——**作者原话：「我现在 api 是：`GET /api/mes/WorkOrders` 复数形式」**：① **`/api` 入口前缀**（现状保留）；② **模块段小写**（`mes`）；③ **资源段 = 模型名原样 + 英语复数**（`WorkOrder` → `WorkOrders`）。**⚠️ 残余细则 2c（未定不许进生成器）**：`/api` 写死还是 Profile 可配（建议 `apiPrefix` 默认 `/api`、网关可剥）+ 复数变形规则（建议英语常规 `+s`／`ies`／`es`、**只加后缀不转写**、不可复数化的名用原形 + 端点显式覆盖） | §3.4 |
| 3 | 稳定度标记语法与 `since` / `sunset` | **进语言**（`stable` / `beta` / `deprecated` + `since` / `sunset`；三端与网关都要读） | §1.2、§5 |
| 4 | OpenAPI 版本与扩展字段白名单 | **3.1**；扩展字段**只允许 `x-mmda-*` 出**，`x-yapi-*` / `x-apifox-*` 由外部工具在导入时自加 | §3、§7 |
| 5 | 命令面 | **独立子命令**（`mmda api export/diff/check` 不并入 `mmda generate`，便于 CI 分开跑） | §2、§4 |
| 6 | Mock 归属 | **IDE 内置**（开发期即时用）；外部工具做展示与协作 | §3.9、§6 |
| 7 | 网关边界 | **分工**：网关做粗粒度凭证校验，Controller 做细粒度 Role/scope | §5、§4 |
| 8 | 导入（逆向）的产出 | **先出报告 + 骨架，人审后入真源**（与 P4 反向导出同一工作方式） | §6 |
| 9 | 基础模块固定名与 `sops` → 权限映射 | **沿用 `Base`**（语料名）；`READ` → **只出读端点**、`CRUD` → **全出** —— **作者此前「还没想清楚」的那部分随本条清掉** | §1.1、§3.6 |
| 12 | `operationId` 命名规则 | **`moduleName_featureName_op`**（作者原话「我希望是 `moduleName_featureName_op`」）——ASCII、不含中文、同项目内唯一（`mmda check` 校验）；**SDK 与客户端代码依赖它，必须稳定**；**字形 = 模块名照抄模块段（小写）、Feature 名照抄模型名（Pascal）**，例 `mes_WorkOrder_create`（随 2c 一并定稿） | §3.3 |
| 13 | scope 命名与授权粒度 | **按现状 = 模块权限 + Action 权限**（作者原话「这个我们已经实现，按照现状来，模块权限，Action 权限」）：**module 出读 / 写 scope，Action 出专属 scope，Feature 级不出 scope** | §3.6 |
| 14 | `webhooks` 首版做不做 | **✔ 已裁 2026-09-24：取 B —— 首版不带 `webhooks`**。作者口径：「**webhooks `GET /events/mes/WorkOrders` 这样的习惯，我选择 B**」——对外事件**仍走拉取式端点**（`GET /events/<模块>/<资源复数>`），**生成的 OpenAPI 里不声明回调段**；`webhooks` 本体与「订阅 / 重试 / 签名」语义**留到 [`event_bus.md`](event_bus.md) §15 一起裁**，不进首版承诺 | §3.8、[`event_bus.md`](event_bus.md) §15 |
