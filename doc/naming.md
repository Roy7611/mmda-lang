# 命名约定（标识符与生成代码）

> 版本 0.1 · 2026-09-24 · 真源：**命名约定**（语言内标识符 + 三端生成代码 + 跨端契约名）
> **与相邻文档的分工**：[`glossary.md`](glossary.md) 管「**词**」（同一概念只留一个名字）；**本文管「标识符怎么写」**。[`records.md`](records.md) 管字段语法、[`project.md`](project.md) 管文件与目录、[`targets.md`](targets.md) 管各端能力、[`api.md`](api.md) 管 API 契约、[`operations.md`](operations.md) §3.1 管指标名、[`ide/i18n.md`](ide/i18n.md) 管 i18n key。
> **既有散落口径收拢于本文**：`records.md`（字段 camelCase）、`project.md`（类型 PascalCase）、`templates/conventions.template.md`、`ai/vibe-spec.md`——**以本文为准**，那几处保留为指针。

**作者口径（原话，2026-09-24）**：

> 「还有一点约定，**接口全部 I 开头**，像 Java 那种**以 `Impl` 结尾的有点啰嗦**。**类和对象都是 Pascal 命名，字段、属性都是小写开头的 camel 命名**，**其他的可以尊重 java、c# 和不同编程语言的习惯**。」

---

## 0. 一句话与边界

**一句话**：**跨端契约名统一（一份真源、三端逐字同形，含常量与枚举成员）；语言本地习惯尊重（方法、包、命名空间、文件名、SQL 标识符）。**

**两条判据（判定任何一个名字时先问这个）**：

| 判据 | 含义 | 后果 |
| --- | --- | --- |
| ① **进契约的名字三端必须逐字一致** | 类型名 / 字段与属性名 / 枚举成员 / 事件名 / 消息头 / JSON 字段 / 指标名 / i18n key | 不一致 = **契约破**（契约测试必须抓到） |
| ② **不进契约的名字随本地习惯** | 方法名 / 局部变量 / 包与命名空间 / 文件名 | 各端生成器按本地惯例产出，**不算差异** |

> 这条边界就是「尊重 java / c# 的习惯」的**可执行版本**：不是「看着像就行」，而是**契约处零差异、实现处随习惯**。
>
> **两类例外**（不进 HTTP 契约，但**有硬要求**，不交给本地习惯）：**常量与枚举成员**（§1，三端统一 `UPPER_SNAKE`）、**数据库标识符**（§3.3，表与视图 = 类名 PascalCase、列 = 属性名 camelCase，**逐字同模型名**）。

---

## 1. 硬规则（✔ 2026-09-24 裁，§1 与 §2 的契约名**零端差异**）

| 对象 | 规则 | 例子 | 备注 |
| --- | --- | --- | --- |
| **接口** | **`I` 开头 + PascalCase** | `IMaterialService`、`IEventBus`、`IDialect` | **三端统一，含 TS**（TS 也加 `I`，否则跨端不同名） |
| **实现类** | **业务名本身，禁止 `Impl` 后缀** | `IMaterialService` → `MaterialService` | Java / C# / TS 都合法（接口带 `I`，实现用业务名不冲突） |
| **多种实现** | **限定词**（别用 `Impl` 或数字） | `AnsiSqlDialect` · `MySqlDialect` · `PostgreSqlDialect` · `DmDialect` · `KingbaseDialect` | 8 个 SQL 方言同构；**禁止** `AnsiSqlDialectImpl` |
| **类 / 对象 / 枚举 / 视图 / 事件** | **PascalCase** | `Material` · `OrderStatus` · `OrderDetail` · `GoodsArrived` | 对应 `Record` / `Enum` / `View` / `event` |
| **字段 / 属性** | **camelCase（小写开头）** | `materialCode` · `createdAt` · `isDeleted` | **含 C# 属性**（代价见 §3.2） |
| **枚举成员** | **`UPPER_SNAKE`（全大写，单词间 `_`）** | `OrderStatus.DRAFT` · `OrderStatus.RELEASED` · `YesNo.YES` | 成员名进载荷 → 属**契约名**，**三端一致**（✔ 2026-09-24 作者补充） |
| **常量** | **`UPPER_SNAKE`（全大写，单词间 `_`）** | `MAX_RETRY_COUNT` · `DEFAULT_PAGE_SIZE` | **三端一致**（不随各端习惯，✔ 2026-09-24 作者补充） |
| **生成的 Handler 接口** | **`I` + 事件名 + `Handler`** | `event GoodsArrived` → 接口 `IGoodsArrivedHandler`，KEEP 区实现 `GoodsArrivedHandler` | [`events.md`](events.md) §3 的接口名由此统一（原记「由 Profile 模板决定」→ 模板可定缀合，**不得违反本文 §1**） |
| **数据库标识符** | **与模型同名，不转写**：表 / 视图 = **类名 PascalCase** · 列 = **属性名 camelCase** | `Record Material` → 表 `Material`、列 `materialCode`；`View MaterialStock` → 视图 `MaterialStock` | ✔ 2026-09-24 作者裁（原话「**sql 字段命名同属性，表名同类名，视图也是和表一样，便于 orm 的一致性**」）；**引号与前置条件见 §3.3** |

**为什么禁止 `Impl`**（写清理由，别只留禁令）：

1. **不携带信息**——接口已由 `I` 前缀标识，「实现」由「谁被注册」决定，后缀是噪音；
2. **二次撞车**——`IMaterialService` + `MaterialServiceImpl` 里 `Service` 出现两遍，读起来像拼写错误；
3. **必生同义异名**——一旦出现第二种实现就会长出 `XImpl` / `XImpl2` / `XRealImpl`：**同义异名正是我们要消灭的东西**（[`glossary.md`](glossary.md) §3.1 判据②）；
4. **替代手段已够**——限定词（`MySqlDialect`）+ 工厂 / 注册表（`DialectRegistry`）能表达一切实现差异。

> **不溯及既往**：既有代码与 KEEP 区**不强制改名**（避免无收益的大规模改动）；约束对象 = **生成物 + 新代码**。

---

## 2. 契约名清单（三端必须逐字一致，一致性测试要查）

| 契约面 | 规则 | 真源 / 生成方 | 一致性怎么查 |
| --- | --- | --- | --- |
| 类型名（Record / Enum / View） | PascalCase，**与 m 语言声明同名** | 内核 IR → 三端生成器 | 标识符对账（§5） |
| 字段 / 属性名 | camelCase，与声明同名 | 同上 | 同上 |
| 枚举成员 | **`UPPER_SNAKE`**（按名序列化时，载荷里就是 `DRAFT` 这样的字符串） | 同上 | 同上 |
| 常量 | **`UPPER_SNAKE`**（三端一致） | 同上 | 同上 |
| **事件名** | PascalCase，与 `event` 声明同名 | [`events.md`](events.md) | 三端事件名对账 |
| **消息头** | camelCase | [`event_bus.md`](event_bus.md) §1（`eventId` · `occurredAt` · `tenant` · `traceId`） | 头字段对账 |
| **JSON 字段（载荷）** | **= 字段 / 属性名原样（camelCase），不做二次转换** | 序列化契约（[`api.md`](api.md)） | 契约测试 |
| **API 路径与 `operationId`** | 属 [`api.md`](api.md) §8.2-②⑫（**路径命名规范待裁，本文不拍**）；本文明令：**路径段与 `operationId` 也不许出现 `Impl`** | [`api.md`](api.md) | 契约测试 |
| **指标名** | `mmda_<域>_<对象>_<计量>`（已在 [`operations.md`](operations.md) §3.1） | 自动打点 | 指标名清单对账 |
| **i18n key** | 见 [`ide/i18n.md`](ide/i18n.md)（Shell 与模型双层 key） | 设计器 | — |
| **模块 / 权限码 / 端点 id** | 沿用既有（`M.01` · `B` · 端点 id）——见 [`project.md`](project.md)、[`event_bus.md`](event_bus.md) §6 | — | 装载期冲突检测已有 |
| **数据库标识符（表 / 视图 / 列）** | **= 模型名逐字一致**（表与视图 PascalCase、列 camelCase，**不转写、不加前缀**） | 内核 IR → DDL 生成器（各方言） | **生成 DDL 的标识符逐字对账**（§3.3、[`targets.md`](targets.md) §5） |

---

## 3. 「尊重各端习惯」的边界（§3 清单内的差异**不算违约**）

### 3.1 随本地习惯的清单

| 对象 | Java | C# | TS | 备注 |
| --- | --- | --- | --- | --- |
| 方法名 | `camelCase` | `PascalCase` | `camelCase` | 各端惯例（作者原话「其他尊重习惯」） |
| 常量 | **`UPPER_SNAKE`** | **`UPPER_SNAKE`** | **`UPPER_SNAKE`** | **三端统一，不随各端习惯**（✔ 2026-09-24 作者补充） |
| 包 / 命名空间 | `com.x.y`（小写点分） | `X.Y`（Pascal 点分） | 模块路径 | 不进契约 |
| 文件名 | 一公共类型一文件 | 同名文件 | 脚手架惯例 | 见 [`project.md`](project.md)（`*.mm` 一对象一文件） |
| 局部变量 / 参数 | `camelCase` | `camelCase` | `camelCase` | — |
| 泛型参数 | `T` / `TKey` | 同 Java | 同 Java | — |

> **SQL 标识符不在本清单**（✔ 2026-09-24 改判）：表 / 视图 / 列**属硬规则**（表与视图 = 类名、列 = 属性名），见 **§3.3**。

### 3.2 C# 属性的代价（必须写清，别装作没有）

C# 社区惯例是**属性 PascalCase**（`public string MaterialCode { get; set; }`），本文按作者裁决统一为 **camelCase**：

| 代价 | 收益（更大） |
| --- | --- |
| 生成的 C# 代码「不像手写 C#」，工具/审查会按惯例提示 | **三端同名**——一眼对得上、序列化无需改名映射、契约测试无需对照表 |
| 与 C# 团队的既有代码风格不一致 | 与 JSON 载荷（camelCase）**天然一致**，序列化配置零意外 |

**放宽口子**：若要放宽，只能放宽到「C# 属性 Pascal + **显式序列化别名**」，且必须同步放宽 JSON 契约（**不建议**，等于给契约加第二套名字）。列待裁 3。

---

### 3.3 数据库标识符（✔ 2026-09-24 作者裁：**便于 ORM 的一致性**）

**作者原话**：「**sql 字段命名同属性，表名同类名，视图也是和表一样，便于 orm 的一致性**」。

| 对象 | 规则 | 例 |
| --- | --- | --- |
| **表** | **= `Record` 名（PascalCase）**，**不转写、不加前缀** | `Record Material` → `CREATE TABLE "Material"` |
| **列** | **= 属性名（camelCase）** | `materialCode` → `"materialCode"` |
| **视图** | **同表规则**（= `View` 名 PascalCase） | `View MaterialStock` → `"MaterialStock"` |
| 主键 / 外键 / 索引 / 唯一约束名 | **待裁 8**（建议 `PK_` / `FK_` / `IX_` / `UX_` + 表名 + 列名） | `IX_Material_materialCode` |

**代价与前置条件（「便于 ORM 一致性」要付的账，必须与规则一起落地）**：

| # | 前置条件 | 不做会怎样 |
| --- | --- | --- |
| 1 | **DDL 一律加方言引号**（由 `Dialect` 的引号能力产出：PostgreSQL / 金仓 / 达梦 / Oracle 用 `"`、MySQL 用反引号、SQL Server 用 `[ ]`） | **不加引号的标识符会被数据库改大小写**：PostgreSQL **折成小写**（官方文档 §4.1.1 Lexical Structure）、Oracle 与 SQL Server **折成大写**——只有加引号才保住 `Material` / `materialCode` |
| 2 | **MySQL 必须 `lower_case_table_names=0`**（大小写敏感）：Linux 默认 0 ✓，**Windows 默认 1（强制小写）、macOS 默认 2（存为小写）** | 这两种实例上 `Material` 变成 `material`，**与模型名不再逐字一致**：开发机「跑得通但名字变了」，DDL 对账假报差异 |
| 3 | **达梦的 `CASE_SENSITIVE` 在 Profile 里显式声明** | 同一个库出现两套大小写行为 |
| 4 | **ORM 侧显式关掉「camelCase → snake_case」自动转换**：Spring Boot / Hibernate 默认的 `SpringPhysicalNamingStrategy` **会把 `materialCode` 转成 `material_code`** → Profile 生成物必须覆盖为 `PhysicalNamingStrategyStandardImpl` + `hibernate.globally_quoted_identifiers=true`；EF Core 的属性名 = 列名**天然一致**（表名配 `ToTable`）；TS 侧（Prisma 等）按生成物显式 `@map` | 出现「表名对了、列名找不到」：JPA 去找 `material_code`，库里有 `"materialCode"` |

**代价（写清，不只写收益）**：手写 SQL / BI 工具 / 临时查询**处处要带引号**（`SELECT "materialCode" FROM "Material"`），漏引号在 PostgreSQL 上直接报 `column "materialcode" does not exist`；`snake_case` 那种「随手写」的便利没有了。

**收益**：**表名 = 类名、列名 = 属性名 → ORM 零映射**（JPA 不用 `@Table` / `@Column`，EF 不用 `HasColumnName`）、JSON 载荷名与列名同形、**DDL 与模型可以逐字对账**（L3 增一项，见 [`targets.md`](targets.md) §5）。

**`mmda doctor` 增一项自检**：连目标库时读 MySQL 的 `lower_case_table_names`、并对各方言各跑一次「带引号 / 不带引号」的标识符探测，**行为不一致即 error**（与 [`operations.md`](operations.md) §10 的 doctor 清单合并登记）。

---

## 4. 生成器与 Profile 的责任（可判定）

- **三端生成器（[`PLAN.md`](..\PLAN.md) P6）必须按本文产出标识符**；§1 / §2 的契约名**不许有端开关**（否则契约会漂）；
- **Profile 能改的只有 §3 清单**（方法名、包、文件名这类本地风格）+ 模板的**缀合方式**；**不能改 `I` 前缀与「禁 `Impl`」，也不能改常量与枚举成员的 `UPPER_SNAKE`（属 §1）**；
- [`statements.md`](statements.md) 原记「接口名由 Profile 模板决定」→ **补充**：模板可定缀合，**不得违反 [`naming.md`](naming.md) §1**；
- 一致性测试（**P9**）**增一项：标识符一致性**——三端产物的类型名 / 属性名 / 事件名 / 消息头名**逐字对账**，进 L3 套件（与 [`targets.md`](targets.md) §5 同口径）。

---

## 5. 检查与落点

| 落点 | 动作 |
| --- | --- |
| `mmda check` | 新增命名检查：声明名不符合 §1（Pascal / camel 误用、`Impl` 后缀、接口缺 `I`）→ 默认 **warning**（强度待裁 2）；**只查生成物与新声明**，不查既有代码 |
| 设计器（[`ide/specification.md`](ide/specification.md)） | 新建对象 / 字段时按本文**预置大小写**并在重命名时提示影响面 |
| 代码评审清单（[`architecture-review.md`](architecture-review.md)） | 加一条：**生成物里出现 `Impl` 或接口缺 `I` 即退回**（生成器 bug，不是风格问题） |
| 模板资产（[`templates/conventions.template.md`](templates/conventions.template.md)） | 保留，作为项目侧约定模板；**真源仍是本文** |

---

## 6. 待裁（A / B / C + 我的建议）

| # | 待裁 | 选项 | 建议 |
| --- | --- | --- | --- |
| 1 | ~~**枚举成员风格**（三端是否统一）~~ → **✔ 已裁（2026-09-24 作者补充）：`UPPER_SNAKE`，单词间 `_` 隔开，三端一致** | ~~A PascalCase~~ ／ **B `UPPER_SNAKE`** ✔ ／ ~~C 随各端~~ | **取 B**（与「常量」同一条规则；载荷里按名序列化就是 `DRAFT` 这样的字符串） |
| 2 | **命名违规的检查强度** | A warning（不阻断）／ B error（`mmda check` 失败）／ C 仅 IDE 提示 | **2A**（起步 warning，P9 后再评估升级——与「新增门禁要谨慎」的一贯口径一致） |
| 3 | **C# 属性是否放宽为 PascalCase** | A 不放宽（保持 camel，跨端同名）／ B 放宽 + 序列化别名 ／ C 按项目 Profile 开关 | **3A**（§3.2 的代价分析：收益是跨端同名，代价只是「不像手写 C#」） |
| 4 | 方法名是否也统一 | A 随各端（Java camel / C# Pascal）／ B 全 camel ／ C 全 Pascal | **4A**（作者原话「其他尊重习惯」） |
| 5 | ~~**数据库标识符**（表 / 列）~~ → **✔ 已裁（2026-09-24 作者）：表 / 视图 = 类名 PascalCase、列 = 属性名 camelCase、视图同表规则，逐字同模型名（便于 ORM 一致性）——见 §1 / §2 / §3.3** | ~~A `snake_case` 转写~~ ／ **B 与模型同名** ✔（作者口径比 B 更彻底：列也是 camel）／ ~~C 交 Dialect 决定~~ | **取 B+**（本文原建议 5A 被否；**代价 = 处处要加引号 + MySQL 须 `lower_case_table_names=0` + ORM 须关自动转写**，见 §3.3） |
| 6 | **既有代码 / KEEP 区的 `Impl`** 是否清理 | A 不强制（只约束生成物与新代码）／ B 提供迁移脚本 ／ C 硬禁并全量改造 | **6A**（B 可作可选工具，C 无收益） |
| 7 | 命名约定是否进硬门禁 | A 不进（warning）／ B 进 `mmda quality gate` | **7A**（与 §6-2 同一件事，合并裁决） |
| 8 | **主键 / 外键 / 索引 / 唯一约束名格式**（表 / 列已裁，这类名字尚未拍） | A `PK_<表>` / `FK_<表>_<列>` / `IX_<表>_<列>` / `UX_<表>_<列>`（大写前缀 + 模型名原样）／ B `<表>_pkey` 等数据库默认名 ／ C 交 Dialect 决定 | **8A**（与表 / 列同风格：**前缀大写、模型名原样不转写**，便于人工定位与 DDL 对账） |

---

## 7. 相关

- 术语唯一命名：[`glossary.md`](glossary.md) §3.1（词）· §3.2（易混淆辨析）
- 字段语法与命名：[`records.md`](records.md) §1.1
- 文件与目录命名：[`project.md`](project.md)（一对象一文件、文件名 = 主符号名）
- 三端契约与一致性口径：[`targets.md`](targets.md) §2、§5
- API 路径与 `operationId`：[`api.md`](api.md) §8.2-②⑫
- 指标名：[`operations.md`](operations.md) §3.1
- 事件与消息头：[`events.md`](events.md) §3、[`event_bus.md`](event_bus.md) §1
- 阶段落点：[`PLAN.md`](..\PLAN.md) §4（P6 生成器 / P9 一致性套件）
