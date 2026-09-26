# 项目格式

> 改编自上一轮 `architect/project-format.md`（formatVersion 2.0，原文留档 `archive/2026-06/architect/project-format.md`）。
> **✔ 2026-09-25 作者裁定（推翻 2026-09-24 的「分片族」）**：① **语言文件统一 `*.m`**——partType **只由内容判定**，不由后缀判定（原口径的「首关键字判 partType」正式成为唯一判据）；② **目录不再规定死**——有 `.mmda` 项目文件，可**按个人习惯建立任何目录**管理，规范**只推荐最佳实践**；但**守住四阶段，文件不要乱**：默认四个根目录 `intents/` `models/` `tests/` `delivery/`；③ **原来用 JSON 写的文件统一改为 M 语言格式**（具体描述格式后定）。
> ⚠️ **读本文的换算规则**：本文其余章节里出现的 `.ma` `.mm` `.me` `.ms` `.mr` `.mc` `.mf` `.mb` `.mi` `.mt`，在目标态**一律读作 `.m`**（旧分片后缀已作废，仅迁移期需读，见 §11）。

---

## 0. 双形态与术语

| 术语 | 含义 |
| --- | --- |
| **MMDA 项目** | 工作区目录 + 根清单 `{projectCode}.mmda` + 四个阶段根目录（§1） |
| **M 语言源文件** | **`*.m`（唯一后缀）**——里面写什么由**首关键字**决定（`subsystem` / `module` / `record` / `view` / `enum` / `stm` / `role` / `converter` / `flow` / `bpmn` / `ui` / `requirement` / `usecase` / `test` / `profile`）；**不再按类型分片**（✔ 2026-09-25 作者） |
| ~~**纯脚本文件（`.m`）**~~ | **不再单列**：脚本与模型同属 `.m`（`import` 复用规则不变）；本条原为「脚本用 `.m`」的特例，因全局统一而消失——但**派生一条新问题**（同名冲突，见 §6 / §11-⑤） |
| **项目清单** | 根目录 `{projectCode}.mmda` —— **整个项目的描述文件**；**目标态 = M 语言格式**（✔ 2026-09-25 作者：「原来有写文件是 json 格式，我觉得要统一为 m 语言格式，后面定具体描述格式」→ §11） |
| **工作区（directory）** | 展开目录，Git/SVN 与 AI 友好，**日常 SSOT** |
| **归档包（archive）** | `{projectCode}.mmdax` —— ZIP，内部路径与工作区 1:1 |

```
工作区目录 ──mmda pack──▶ .mmdax 归档包
    ▲                          │
    └──────mmda unpack─────────┘

工作区 ──parse/validate──▶ 元模型 AST ──▶ IR ──▶ (库 / DDL / 代码 / 图形投影)
```

**存储形态的两条腿（决策 A4 + B2）**：文件是设计期真源（便于转换、拷贝、导入导出、评审）；数据库是部署目标与运行时缓存（便于运行时改配置、批量改）。库侧改动必须经反向导入回到文件并进版本控制，见 `..\PLAN.md` §3.2。

---

## 1. 工作区目录

```
erp/
├── erp.mmda                    # 项目清单（§2）：登记模块与包含项；**目录怎么组织由它兜底**
├── README.md
│
├── intents/                    # S1 意图：why / what（人类参与最多）
│   ├── M.01.001-007.m          #   requirement（@Layer / @Priority / @Status / @Feature）
│   ├── roles/SalesMan.m        #   role + 权限声明（原 `flow/roles/*.mr`）
│   └── uat/M.01.001.uat.m      #   验收准则（可执行 UAT，随需求基线冻结，[`testing.md`](../testing.md) §0.1）
│
├── models/                     # S2 建模：how（模块分解 / 动作 / 数据 / 状态 / 流程 / UI，全是 .m）
│   ├── modules/erp.m           #   模块树（原 `biz/*.ma`）
│   ├── objects/Order.m         #   record / view（一对象一文件）
│   ├── enums/OrderStatus.m     #   enum
│   ├── stms/OrderFlow.m        #   stm（行为 SSOT）
│   ├── converters/AsnToReceipt.m
│   ├── flows/mes.m             #   数据流（DataFlow）：节点图 / DFD / 数据映射图
│   ├── bpml/mes.m              #   跨模块流程（BPMN）—— 目录名待裁（§11）
│   ├── ui/BomEditor.m          #   定制五视图
│   ├── Order.g                 #   图形投影（同目录同名 + `.g`；目标态 m 格式，§11）
│   └── Order.hook.m            #   脚本（拦截器 / 钩子体；可 `import` 复用）——命名规则待裁（§11-⑤）
│
├── tests/                      # S3 验收：用例 + 冻结基线
│   ├── order/Order.m           #   用例（covers / req / source / kind / suite / reviewedBy）
│   └── baseline/               #   冻结基线（按版本，作为验收标准，[`testing.md`](../testing.md) §5）
│
├── delivery/                   # S4 交付：交付物与部署（**运维在四阶段之外**，[`workflows-phase.md`](../workflows-phase.md) §3.2）
│   ├── profiles/prototype-sqlite.m   # Codegen Profile（原 `codegen/profiles/*.yaml`）
│   └── deploy/                       # 部署配置与交付清单（镜像 / 发布参数 / 版本）
│
├── doc/                        # 设计文档、评审纪要（Markdown）
├── generated/                  # 生成物（默认不打包）
├── changelog/                  # 设计变更日志（目标态 m 格式，§11）
└── .cursor/rules               # 工具链（可选，不默认打包）
```

**目录不是规定，只是推荐**（作者口径 2026-09-25：「原来对存放目录也规定太死，捆绑了人类和 AI 的手脚……可以按个人习惯建立任何目录去管理，我们只推荐最佳实践」）：

| 规则 | 内容 |
| --- | --- |
| **硬约束（只有一条）** | **语言文件属于哪个阶段，就看它落在哪个阶段根**——`intents/` / `models/` / `tests/` / `delivery/`。四根是**默认**，**守的是「文件不要乱」，不是目录名本身**（能否改名 / 嵌套，见 §11-⑥） |
| **推荐** | 上面的子目录布局（IDE 的「新建需求 / 新建对象 / 新建用例 / 新建 Profile」默认落这里） |
| **自由** | 其余随个人习惯与 AI 便好（按子系统再分一层、扁平化、按模块拆仓都行） |
| **目录不承担语义** | partType 由**正文首关键字**判定，**路径与后缀都不参与**；移动 / 重命名不改变语义 |

### 1.1 导航分区与目录对应

| 导航分区（IDE 侧不变） | 落到哪一阶段 | 推荐目录（最佳实践） | partType（正文首关键字） |
| --- | --- | --- | --- |
| 需求 / 用例 | **S1 意图** | `intents/` | `requirement` / `usecase` |
| 角色与权限 | **S1 意图** | `intents/roles/` | `role` |
| 业务架构 · 模块树 | **S2 建模** | `models/modules/` | `subsystem` / `module` |
| 数据架构 · 对象 | **S2 建模** | `models/objects/` | `record` / `view` |
| 数据架构 · 枚举 | **S2 建模** | `models/enums/` | `enum` |
| 数据架构 · STM | **S2 建模** | `models/stms/` | `stm` |
| 流程架构 · 数据转换 | **S2 建模** | `models/converters/` | `converter` |
| 流程架构 · 数据流 | **S2 建模** | `models/flows/` | `flow` |
| 流程架构 · 跨模块流程 | **S2 建模** | `models/bpml/`（目录名待裁） | `bpmn` |
| 交互设计 | **S2 建模** | `models/ui/` | `ui` |
| 测试与验收 | **S3 验收** | `tests/`（`tests/baseline/` = 冻结基线） | `test` |
| 交付（Profile / 部署配置） | **S4 交付** | `delivery/` | `profile` / `deploy` |

> **运维不在四阶段内**（✔ 2026-09-25 作者）：IDE 不提供运维能力，运维由底座集成监控平台；运维日志与报告发起下一轮迭代（[`workflows-phase.md`](../workflows-phase.md) §3.2 / §3.5）。

> 四个阶段与阶段根目录的口径见 [`workflows-phase.md`](../workflows-phase.md) §3。

### 1.2 文件类型总表（**目标态**）

| 文件 | 后缀 | partType | 说明 |
| --- | --- | --- | --- |
| **M 语言源文件** | **`.m`（唯一）** | **由正文首关键字判定**：`subsystem` / `module` / `record` / `view` / `enum` / `stm` / `role` / `converter` / `flow` / `bpmn` / `ui` / `requirement` / `usecase` / `test` / `profile` | 全部**声明与脚本**（含需求、用例、角色、图形语义）——**一种文件承载所有 partType**（✔ 2026-09-25 作者：「既然通过 partType 可以识别元素类型，没必要那么多扩展名」） |
| **图形投影** | `{SSOT}.g` | `graph` | 布局 / 颜色 / 路由；**目标态 = M 语言格式**（具体描述格式待裁 → §11-①） |
| **项目清单** | `{projectCode}.mmda` | `project` | 根目录有且仅有一个；**目标态 = M 语言格式**（格式待裁 → §11-②） |
| **变更日志** | `changelog/*` | `changelog` | 目标态 = M 语言格式（格式待裁 → §11-②） |
| **Codegen Profile** | `delivery/profiles/*.m` | `codegen-profile` | 原 YAML；目标态 = M 语言格式（格式待裁 → §11-②） |
| **文档** | `.md` | `doc` | 规范 / 纪要，非语言文件 |
| **归档包** | `.mmdax` | `archive` | ZIP 容器，内部路径与工作区 1:1（**不改格式**——它是容器，不是「写法」） |

**旧分片后缀（✔ 2026-09-25 作废，仅迁移期需读）**：`.ma`（模块树）、`.mm`（对象）、`.me`（枚举）、`.ms`（STM）、`.mr`（角色）、`.mc`（转换器）、`.mf`（数据流）、`.mb`（BPMN）、`.mi`（UI）、`.mt`（用例）、`*.{ma,mm,ms,mf,mb}.g`（图形）。迁移见 §11。

> ✔ **被本条推翻的三条旧裁决**：~~冲突 3「`.mmda` 只表示项目清单、语言分片保族」（2026-09-24）~~、~~冲突 2「`.ma` = JSON、其余为文本」（2026-09-25 上午）~~、~~「`.mt` 进语言族」（2026-09-24，[`errata.md`](../errata.md) §五-6）~~ —— 三条均被「统一 `*.m`」作废；**保留的只有原口径的一半**：**partType 由内容首关键字判定**。

> ✔ 冲突 3 **已裁**（2026-09-24）：`.mmda` 只表示项目清单，语言分片**保族**，`.mt` 同族（见 [`errata.md`](../errata.md) §五-1、§五-6）。
> ✔ 冲突 2 **已裁（2026-09-25，取语料形态）**：**`.ma` 正文 = JSON**（模块树，设计器产出，`$schema = …/ma-module/v1`）；**`.mm` / `.me` / `.ms` / `.mi` = M 语言文本**。实测（`E:\Dev\mmda-architect\examples\mmda-mes`，378 个语言文件）：`.mm` 215 / `.me` 113 / `.ms` 41 / `.mi` 1 **全部文本**，`.ma` 2 **全部 JSON**，`*.g`（图布局）与 `.mmda`（清单）同属 JSON。**判据：人写与评审的走 M 语言文本（可 diff、可图形编辑）；设计器产出的结构性文件走 JSON**（见 [`errata.md`](../errata.md) 冲突 2）。
> ✔ **2026-09-24 扩裁（作者原话：「我想把 `.mf` 给数据流图用，跨模块流程 `.mb`」）**：**`.mf` = 数据流（DataFlow，含节点图 / 数据流图 / 数据映射图）**；**`.mb` = 跨模块流程（BPMN）**——两者职责对调/新立，`.g` 族随之扩为 `{ma, mm, ms, mf, mb}`（见 [`errata.md`](../errata.md) §五-34）。

### 1.3 跨目录引用规则

**不绑路径**——引用一律走**符号名**，由解析器按项目索引（`.mmda` 登记 + 目录扫描）解析。**这是「目录自由」的技术前提**（也是原口径「partType 由内容判定」的必然推论）：移动 / 重命名 / 重组目录**不改变语义**。

| 引用形态 | 目标 |
| --- | --- |
| 模块树里的 `model:` / `ui:` / `flow:` | 按**符号名**找同名 part（`Order` / `BomEditor` / `mes-operate`），**不写路径** |
| Feature 行为 | 按 `@State OrderFlow` 找同名 `stm` part |
| 枚举 | `Order.status : OrderStatus` → 找同名 `enum` part |
| `requirement` 的 `@Feature M.01.001` | 按模块编号找模块节点（**S1 → S2 的锚**） |
| `test` 的 `covers:` / `req:` | 指向**声明点标识 / 需求编号**（不是文件路径） |

> 待裁：同名 part 的冲突规则（同名声明在同一项目内出 error，还是允许按模块命名空间区分）——见 §11。

### 1.4 part 角色（pack 时）

| role | 路径（推荐布局） | 默认打包 |
| --- | --- | --- |
| `core` | `*.mmda`、`intents/`、`models/`、`tests/`、`delivery/profiles/`、`**/*.g`、`changelog/` | ✓ |
| `attachment` | `doc/`、`README.md` | ✓ |
| `generated` | `generated/` | ✗ |
| `tooling` | `.cursor/` | 可选 |

> 目录自由后，`core` 的判据不再是"路径在不在白名单"，而是**「是否属于四个阶段根 + 工具目录」**；自定义目录需在 `.mmda` 登记，否则视为 generated（不进包）。

---

## 2. 项目清单 `{projectCode}.mmda`

根目录**有且仅有一个**，文件名 = `projectCode` + `.mmda`。**目标态 = M 语言格式**（✔ 2026-09-25 作者：「原来有写文件是 json 格式，要统一为 m 语言格式，后面定具体描述格式」→ 格式待裁，见 §11-②）；下面是**现行 JSON 形态**（迁移期仍需读）。

```json
{
  "formatVersion": "2.1",
  "projectCode": "erp",
  "projectLabel": "集团 ERP",
  "description": "CRM + MES + WMS + HRM …",
  "defaultModule": "mes",
  "includeDefault": true,
  "createdAt": "2026-06-27T00:00:00Z",
  "mmdaSpecVersion": "0.2",
  "defaultLocale": "zh-CN",
  "locales": ["zh-CN", "en", "zh-Hant"],
  "modules": [
    { "code": "mes", "bizFile": "models/modules/erp.m", "systemCode": "M", "label": "制造执行" }
  ],
  "items": [
    { "path": "models/objects/Legacy.m", "include": false, "itemType": "model", "module": "mes" }
  ],
  "storage": { "kind": "directory" }
}
```

> **清单是设计源（单份）**：这里的 `projectLabel` / `modules[].label` / `description` 都写在**清单自身**里（`label` 取项目 `defaultLocale`；`description` 同 `comments` 层，不进元数据 JSON，见 [`meta-model.md`](/meta-model.md §6.3）；**按 locale 切片的是元数据 JSON（每份顶层带 `locale`，一份一个 locale）** —— ⤴ 2026-09-26 作者：「**加一个locale属性，这才是输出的json最终形式**」（[`presentation.md`](/presentation.md §5、[`meta-model.md`](/meta-model.md §6.2）。

| 字段 | 说明 |
| --- | --- |
| `modules[]` | 与模块树文件（原 `biz/*.ma`，现 `models/modules/*.m`）一一对应；可选 `flowFile` 指向数据流文件。**字段名与取值待随格式统一时一并裁**（§11-②） |
| `defaultModule` | 新建对象的默认模块 / 导航默认展开 |
| `includeDefault` | 未列入 `items[]` 的文件是否默认包含（默认 `true`） |
| `items[]` | **Visual Studio ItemGroup 风格**：只记录与默认不同的包含状态；`include:false` = 排除出校验/生成。**目录自由后它是唯一的登记入口**——自定义目录必须能被 `.mmda` 覆盖到，否则视为 generated（不进包、不参与校验） |
| `parts[]` | 可选；pack 时写入完整注册表 + `checksum` |

### 2.1 多租户 / 多环境差异（决策 B4）

复用 `items[]` 与「按模块拆文件」：为特定租户定义**额外的 include 文件**（如 `models/objects/{tenant}/X.m`），不新增语言概念；必要时用 `items[].include` 做环境开关。

打开项目：`mmda open ./erp` 或 `mmda open erp.mmdax`（解压后读包内清单）。

---

## 3. 各类型文件

### 3.1 模块树（`models/modules/`，一文件一子系统）

一文件 = 一个**子系统**的 Module 树（文档系形态）：

```ts
/// 制造执行系统
subsystem mes in Erp {
  /// 生产管理
  module M.03 Production {
    module M.03.032 BomApproval {
      model: Bom,
      ui: { editor: BomEditor, index: BomList },
      flow: mes-operate
    }
  }
}
```

图形投影：`models/modules/erp.m` ↔ `models/modules/erp.g`（`graphKind: module`；**图形后缀与格式待裁** → §11-①）。

### 3.2 数据架构

| 路径 | 文件 | 说明 |
| --- | --- | --- |
| `models/objects/` | `Order.m` | `record` / `view`，一类型一文件 |
| `models/enums/` | `OrderStatus.m` | `enum`，一枚举一文件 |
| `models/stms/` | `OrderFlow.m` | `stm Name on Record.field { … }`，**行为 SSOT** |
| 同目录 `*.g` | `Order.g` / `OrderFlow.g` | 可选；E-R / 状态图布局 |

Record 内不嵌完整 STM：`@State OrderFlow` 指向 `models/stms/OrderFlow.m`。
图形**语义**在语言文件，**位置/颜色/路由**在 `{SSOT}.g`。

### 3.3 流程架构

| 路径 | 文件 | 说明 |
| --- | --- | --- |
| `intents/roles/` | `SalesMan.m` | `role` + `auth module` / `actions` / `scope`（**Role 来自 S1 识别的关键用户**，[`meta-model.md`](/meta-model.md §8.1） |
| `models/converters/` | `AsnToReceipt.m` | `converter S->T { field->field, … }` |
| `models/flows/` | `crm.m` | 数据流（DataFlow）：节点图 / DFD / 数据映射图 |
| `models/bpml/` | `crm.m` | 跨模块流程（BPMN）活动 / 网关 / 消息流（目录名待裁） |

顺序（与 UI 一致）：先 `roles/`，再 `converters/` + `stms/`，最后数据流与 BPMN。

### 3.4 交互设计（`models/ui/`）

一文件 = 一套定制视图：

```ts
/// 面试编辑器
ui InterviewEditor for Interview {
  index: InterviewList,
  editor: InterviewEditorPane,
  details: InterviewDetails,
  search: InterviewSearch,
  report: InterviewReport
}
```

未提供定制视图文件时，按对象声明（`models/objects/*.m`）生成标准 CRUD。详见 [presentation.md](/presentation.md。

---

## 4. 归档包 `.mmdax`

```
erp.mmdax                 # application/vnd.mmda.package+zip
├── erp.mmda
├── intents/…  models/…  tests/…  delivery/…  doc/…
└── （默认不含 generated/）
```

```bash
mmda pack ./erp -o dist/erp.mmdax
mmda unpack dist/erp.mmdax -o ./erp-restored
mmda open dist/erp.mmdax
```

| 选项 | 说明 |
| --- | --- |
| `--exclude` | 默认 `generated/**`、`.git/**` |
| `--with-generated` | 包含 `generated/` |
| `--with-tooling` | 包含 `.cursor/` |
| `--update-parts` | 刷新 `parts[]` 与 checksum |

---

## 5. partType 与 contentType

| partType | 判定方式 | contentType |
| --- | --- | --- |
| `project` | 文件名 `{projectCode}.mmda` | `application/vnd.mmda.project+json`（目标态随 §11-② 改） |
| `biz` `model` `enum` `stm` `role` `converter` `flow` `bpmn` `ui` `requirement` `usecase` `test` `profile` | **任一 `*.m` 的正文首关键字**——**路径与后缀都不参与判定**（推荐目录见 §1.1） | `text/x-mmda+m` |
| `graph` | `{SSOT}.g` | `application/vnd.mmda.graph+json`（目标态待裁 → §11-①） |
| `codegen-profile` | `delivery/profiles/*.m` | 目标态随语言格式统一 |
| `changelog` | `changelog/*` | 目标态随语言格式统一 |
| `doc` | `doc/**`、`README.md` | `text/markdown` |

> ✔ 统一 `*.m` 后 **contentType 只剩一个语言类型**（`text/x-mmda+m`），IDE 的文件关联、图标与语法高亮**按 partType（内容）而非后缀**决定——这正是「一种文件」的收益面。

---

## 6. 单文件粒度与命名

| 规则 | 说明 |
| --- | --- |
| **一对象一文件** | `Order.m`、`OrderStatus.m`、`OrderFlow.m` 各一文件 → 细粒度 diff、减法冲突 |
| 文件名 = 主符号名 | 与语言文件内 `record Order` / `enum OrderStatus` 一致（**目录自由时这是唯一的"人找得到"约定**） |
| 子系统前缀（可选） | 大项目可 `models/objects/mes/Bom.m`；`syncRef` 仍为 `mes.Bom` |
| **同名冲突（新增待裁）** | 统一后缀后，「对象 `Order.m`」与「同目录的脚本」不再能靠 `.mm` / `.m` 区分——**脚本命名规则待裁**（建议 `Order.{用途}.m`，如 `Order.hook.m` / `Order.rules.m`，见 §11-⑤） |
| 大小写 | 类型名 PascalCase；模块树文件用小写（`erp.m`）；**标识符与生成代码的命名总口径见 [`naming.md`](../naming.md)** |

这粒度是为**细粒度版本控制**（决策 B2）服务的：对象级改动只产生对象级 diff，git/svn 合并冲突面最小。

---

## 7. Codegen Profile

路径 `codegen/profiles/*.yaml`，声明目标栈、输出目录、模板集。示例见 [ide/specification.md](../ide/specification.md)（`prototype-sqlite`、`prototype-api-rust`、`prototype-api-ts`、`prototype-ui-vue`）。

**生成区与手写区**：沿用 `~GENERATED PARTS BEGIN/END` 与 `~KEEP PARTS BEGIN/END` 标记，再生成只替换生成区、保留手写区（现有实现见 `D:\2026\java\mmda-foundation\mmda-factory`，`CodeBuilder.java:44-47`）。

---

## 8. 变更日志 `changelog/`

```json
{
  "seq": 1,
  "at": "2026-06-27T00:00:00Z",
  "author": "mmda-architect",
  "refKind": "project",
  "refKey": "mmda-mes",
  "changes": [ { "summary": "Initial mmda-mes example project" } ]
}
```

`refKey` 使用 `{schema}.{Object}[.{field}]` 形式的 syncRef（如 `mes.Bom.status`）。
**Design Change Log ≠ Domain Event**：前者是设计期元数据变更，后者是运行时领域事件。

---

## 9. 版本控制建议（决策 B2）

| 项 | 提交 | 忽略 |
| --- | --- | --- |
| 内容 | 根清单、`intents/`、`models/`、`tests/`、`delivery/`、`**/*.g`、`doc/`、`changelog/` | `generated/` |
| `.mmdax` | 一般不提交（CI 执行 `mmda pack` 产出） | — |
| git | 项目目录即仓库，原生集成 | — |
| svn | 无本地暂存/分支合并模型 → 以 `changelog/` 为准的弱集成，细节待裁决（`..\PLAN.md` §6.2-5） | — |

---

## 10. 兼容与实现状态

**Legacy formatVersion 1.x**：

```
manifest.json
schemas/*.schema.json
models/**/*.mmda          # 混合 record/enum
modules/modules.yaml
actions/**/*.yaml
events/**/*.mmda
```

识别特征：存在 `manifest.json` 且**无**根 `{projectCode}.mmda`，或 `formatVersion` 为 `"1.0"`/`"1.1"`。迁移工具规划：`mmda migrate --to 2.0 ./legacy-project`。**另有语法级改名迁移**：`mmda migrate --rename @PartitionID=@Partitioned`（✔ 2026-09-25 作者同意；默认 dry-run 出待改清单、`--write` 才落盘；**只动语言文件**，不碰生成区 / KEEP 区）—— 解析器**只认新名**，旧项目升级必经这一步（同一条线见 [`naming.md`](../naming.md) §5）。

| 能力 | 规范 | 上一轮实现（mmda-core / Architect） |
| --- | --- | --- |
| 目录（四阶段根）+ 目录自由 | ✓ 2026-09-25 裁定 | 待迁移（现为 `biz/` `data/` `flow/` `ui/`，§11） |
| 语言后缀统一 `*.m` | ✓ 2026-09-25 裁定 | 待迁移（现为分片后缀，§11） |
| `{code}.mmda` 清单 | ✓ | 待实现 |
| 语言文件解析（按首关键字判 partType） | ✓ | Phase 2：**旧后缀 + `.m` 双读**（迁移窗口，§11-③） |
| pack / unpack | ✓ | ✓ |
| 导航搜索按 kind | — | ✓ |

---

## 11. 迁移：旧后缀 / 旧目录 → 新形态（✔ 2026-09-25 方向已定，步骤待裁）

**方向已定（作者 2026-09-25）**：① **语言文件统一 `*.m`**；② **目录自由**（守四阶段根）；③ **原来用 JSON 写的文件统一改为 M 语言格式**（**具体描述格式后定**）。

**现存引用面（实测，2026-09-25）**：

| 面 | 数量 | 拆解 |
| --- | --- | --- |
| 语料（`E:\Dev\mmda-architect\examples\mmda-mes`） | **378 个语言文件** | `.mm` 215 / `.me` 113 / `.ms` 41 / `.ma` 2 / `.mi` 1 / `.g` 2 / 清单与文档等 |
| 规范文档内的**旧后缀**引用 | **647 行 / 约 30 个文件** | `.mm` 123、`.ma` 90、`.ms` 85、`.mf` 79、`.me` 67、`.mi` 63、`.mb` 54、`.mr` 35、`.mt` 26、`.mc` 25 |
| 规范文档内的**旧目录**引用 | — | `ui/` 79、`biz/` 62、`data/models/` 55、`data/stms/` 29、`flow/roles/` 24、`changelog/` 19、`flow/converters/` 18、`codegen/` 16、`data/enums/` 14、`tests/` 12 |

**步骤（建议，待裁）**：

1. **P2 解析器先支持双形态**（旧分片后缀 + `.m`）——没有回归保护之前**不动语料**（[`../PLAN.md`](../../PLAN.md) §4 P2）；
2. `mmda migrate --suffix`（与既有 `--rename` 同一条命令线，[`naming.md`](../naming.md) §5）：默认 dry-run 出清单、`--write` 落盘，**只动语言文件**，不碰生成区 / KEEP 区；
3. **文档侧**：本文档已改为新口径；其余文档里的旧后缀按头部的「**一律读作 `.m`**」换算规则读，**随迁移专题批量改写**（不在本轮逐处改，避免出现「文档说 `.m`、语料还是 `.mm`」的更大偏差）；
4. **图形与清单**的目标格式落定后再动 `.g` 与 `.mmda`（它们是机器产出 / 结构性文件，改格式要同时改设计器与内核）。

**本节登记的待裁（6 条）**：

| # | 议题 | 建议 |
| --- | --- | --- |
| ① | **图形投影**的目标格式与文件名形态（`{SSOT}.g` 还是别的；sheet 与布局怎么表达） | 建议仍用独立文件 `{SSOT}.g`（与 SSOT 同目录同名），格式随语言统一为 M 语言（具体描述格式待定） |
| ② | **项目清单 `.mmda` / 变更日志 / Codegen Profile** 的目标格式与字段名 | 建议一并统一为 M 语言声明（`project { … }` / `log { … }` / `profile { … }`），字段名随此裁 |
| ③ | **迁移时点与双后缀兼容窗口**（P2 双读多久、何时强制单读） | 建议双读窗口贯穿 P2–P8，P9 前强制单读 + 迁移脚本随 P9 交付 |
| ④ | **`models/` 内部推荐子目录**是否按 §1 的布局（`modules/objects/enums/stms/converters/flows/bpml/ui`）；`bpml/` 这个目录名 | 建议采纳；`bpml/` 建议改 `bpmn/`（与人熟悉的 BPMN 缩写一致） |
| ⑤ | **同名冲突**：统一后缀后「对象 `Order.m`」与「脚本」不能再靠后缀区分 | 建议脚本用 `{对象}.{用途}.m`（`Order.hook.m` / `Order.rules.m`），或脚本统一进 `scripts/`（二选一，待裁） |
| ⑥ | **四根目录能否改名 / 嵌套**；若能，`.mmda` 里要不要声明「阶段 → 目录」映射 | 建议**能改名但要在 `.mmda` 声明映射**（守住「四阶段文件不要乱」这条），默认仍按四个名字 |

---

## 12. 相关

- [workflows-phase.md](../workflows-phase.md) — 四阶段模型（意图 / 建模 / 验收 / 交付）与目录的阶段归属
- [meta-model.md](/meta-model.md — 逻辑元素
- [ide/graph-files.md](../ide/graph-files.md) — `*.g` 格式
- [ide/workflow.md](../ide/workflow.md) — 六步工作流与导航
- [errata.md](../errata.md) — 口径冲突
