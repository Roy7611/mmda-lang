# 项目格式

> 改编自上一轮 `architect/project-format.md`（formatVersion 2.0，原文留档 `archive/2026-06/architect/project-format.md`）。
> **已裁决（2026-09-24，见 [`errata.md`](errata.md) 冲突 3）**：`.mmda` 只表示项目清单，语言分片保持扩展名族；**解析器按内容首关键字判定 partType**（`record` / `enum` / `stm` / `ui` / `view`），扩展名仅作约定、图标与文件关联提示。本文按此描述。

---

## 0. 双形态与术语

| 术语 | 含义 |
| --- | --- |
| **MMDA 项目** | 工作区目录 + 根清单 `{projectCode}.mmda` + `biz/` `data/` `flow/` `ui/` 等 |
| **M 语言源文件** | `.ma` `.mm` `.me` `.ms` `.mr` `.mc` `.mf` `.mi` … 按类型分片的语言文件 |
| **纯脚本文件（`.m`）** | 模型之外的**脚本程序**（拦截器 / 钩子体 / 可复用函数）—— **与它服务的对象同目录**（如 `data/models/mes/Order.mm` 与 `data/models/mes/Order.m`），可用 **`import`** 引到别的文件里复用；✔ 2026-09-25 作者 |
| **项目清单** | 根目录 `{projectCode}.mmda` —— **整个项目的描述文件**（JSON，非 M 语言模型） |
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
├── erp.mmda                    # 项目清单（§2）
├── README.md
│
├── biz/                        # 业务架构：按子系统分解 Module 树
│   └── mes.ma
│
├── data/                       # 数据架构
│   ├── models/                 # 元对象（Record / View）一对象一文件
│   │   └── Order.mm
│   ├── enums/                  # 枚举（含 @State 状态枚举）
│   │   └── OrderStatus.me
│   └── stms/                   # 状态机（STM，与 Record 解耦存放）
│       └── OrderStatusChanged.ms
│
├── flow/                       # 流程架构
│   ├── roles/                  # 角色            *.mr
│   ├── converters/             # 数据转换器      *.mc
│   ├── mes.mf                  # 数据流（DataFlow）：节点图 / 数据流图 / 数据映射图
│   ├── mes.mf.g                # 其图形投影（多 sheet：mf-flow / mf-dfd / mf-map）
│   ├── mes.mb                  # 跨模块流程（BPMN）
│   └── mes.mb.g                # 其图形投影（sheet：mb-bpmn）
│
├── ui/                         # 交互设计：定制视图
│   └── mes/BomEditor.mi
│
├── doc/                        # 设计文档、评审纪要（Markdown）
├── tests/                      # 测试用例：一对象一文件，与模型同粒度（*.mt）；**含 suite 分类与状态跟踪**（[`testing.md`](testing.md) §9.1）
│   ├── order/Order.mt          #   用例（含 covers / source / reviewedBy）
│   └── baseline/               #   冻结基线（按版本，作为验收标准，见 testing.md §5）
├── codegen/profiles/           # 交付：Codegen Profile（YAML）
├── changelog/                  # 设计变更日志（JSON）
├── generated/                  # 生成物（默认不打包）
└── .cursor/rules               # 工具链（可选，不默认打包）
```

### 1.1 导航分区与目录对应

| 导航分区 | 目录 | 扩展名 |
| --- | --- | --- |
| 业务架构 | `biz/` | `.ma` |
| 数据架构 · 对象 | `data/models/` | `.mm` |
| 数据架构 · 枚举 | `data/enums/` | `.me` |
| 数据架构 · STM | `data/stms/` | `.ms` |
| 流程架构 · 角色权限 | `flow/roles/` | `.mr` |
| 流程架构 · 数据转换 | `flow/converters/` | `.mc` |
| 测试与验收 | `tests/` | `.mt` （用例含 `source` / `kind` / `suite` / 状态，见 [`testing.md`](testing.md) §9.1） |
| 流程架构 · 数据流 | `flow/` | **`.mf`**（数据流编排：节点图 / 数据流图 / 数据映射图） |
| 流程架构 · 跨模块流程 | `flow/` | **`.mb`**（BPMN） |
| 交互设计 | `ui/` | `.mi` |

### 1.2 扩展名总表

| 扩展名 | 全称 | partType | 内容 |
| --- | --- | --- | --- |
| `.mmda` | MMDA Project | `project` | 根清单 `{projectCode}.mmda`（JSON） |
| `.ma` | Module Architecture | `biz` | 子系统 Module 树 |
| `.mm` | Meta Model | `model` | `record` / `view` 定义 |
| `.me` | Meta Enum | `enum` | `enum` 定义 |
| `.ms` | Meta State machine | `stm` | `stm … on Record.field { action … }` |
| `.mr` | Meta Role | `role` | `role` + 权限声明；**Role 是架构设计元素（与 Module 分解同级），来自需求阶段识别的关键用户**——见 [`meta-model.md`](meta-model.md) §8.1 |
| `.mc` | Meta Converter | `converter` | `converter S->T { … }` |
| `.mf` | Meta Flow | `flow` | **数据流（DataFlow）**：节点图 / 数据流图（DFD）/ 数据映射图——**✔ 2026-09-24 改判：由「跨模块流程」改为数据流**（见 [`errata.md`](errata.md) §五-34） |
| `.mb` | Meta BPMN | `bpmn` | **跨模块流程（BPMN）**——✔ 2026-09-24 新增（原 `.mf` 的职责迁来） |
| `.mi` | Meta Interface | `ui` | 定制五视图：index / editor / details / search / report |
| `*.{ma\|mm\|ms\|mf\|mb}.g` | Graph 投影 | `graph` | JSON 布局/样式，见 [ide/graph-files.md](ide/graph-files.md) |
| `.mt` | Meta Test | `test` | 测试用例：`given/when/expect` + `covers`/`source`/`reviewedBy`/`baseline`，见 [`testing.md`](testing.md) §9 ；**✔ 2026-09-25：进库 + 分类 / 集合 / 状态跟踪管理**（库表形态待裁 → [`testing.md`](testing.md) §11-15；IDE 管理面见同文 §8.1） |
| `.md` | — | `doc` | 文档 |
| `.mmdax` | — | `archive` | ZIP 归档包 |

> ✔ 冲突 3 **已裁**（2026-09-24）：`.mmda` 只表示项目清单，语言分片**保族**，`.mt` 同族（见 [`errata.md`](errata.md) §五-1、§五-6）。
> ✔ 冲突 2 **已裁（2026-09-25，取语料形态）**：**`.ma` 正文 = JSON**（模块树，设计器产出，`$schema = …/ma-module/v1`）；**`.mm` / `.me` / `.ms` / `.mi` = M 语言文本**。实测（`E:\Dev\mmda-architect\examples\mmda-mes`，378 个语言文件）：`.mm` 215 / `.me` 113 / `.ms` 41 / `.mi` 1 **全部文本**，`.ma` 2 **全部 JSON**，`*.g`（图布局）与 `.mmda`（清单）同属 JSON。**判据：人写与评审的走 M 语言文本（可 diff、可图形编辑）；设计器产出的结构性文件走 JSON**（见 [`errata.md`](errata.md) 冲突 2）。
> ✔ **2026-09-24 扩裁（作者原话：「我想把 `.mf` 给数据流图用，跨模块流程 `.mb`」）**：**`.mf` = 数据流（DataFlow，含节点图 / 数据流图 / 数据映射图）**；**`.mb` = 跨模块流程（BPMN）**——两者职责对调/新立，`.g` 族随之扩为 `{ma, mm, ms, mf, mb}`（见 [`errata.md`](errata.md) §五-34）。

### 1.3 跨目录引用规则

`biz/*.ma` 通过**符号名**引用其他 part，解析器按项目索引解析路径：

| `.ma` 字段 | 引用目标 |
| --- | --- |
| `model` | `data/models/{Name}.mm` |
| `ui.editor` 等 | `ui/{subsystem}/{Name}.mi` |
| `flow` / `flows` | `flow/{subsystem}.mf` |
| Feature 行为 | `data/stms/{StmName}.ms`（由 `@State` + STM 名关联） |
| 枚举 | `Order.status : OrderStatus` → `data/enums/OrderStatus.me` |

### 1.4 part 角色（pack 时）

| role | 路径 | 默认打包 |
| --- | --- | --- |
| `core` | `*.mmda`、`biz/`、`data/`、`flow/`、`ui/`、`tests/`、`**/*.{ma,mm,ms,mf,mb}.g`、`codegen/`、`changelog/` | ✓ |
| `attachment` | `doc/`、`README.md` | ✓ |
| `generated` | `generated/` | ✗ |
| `tooling` | `.cursor/` | 可选 |

---

## 2. 项目清单 `{projectCode}.mmda`

根目录**有且仅有一个**，文件名 = `projectCode` + `.mmda`。UTF-8 JSON（便于 CLI / 内核解析）。

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
    { "code": "mes", "bizFile": "biz/mes.ma", "systemCode": "M", "label": "制造执行" }
  ],
  "items": [
    { "path": "data/models/mes/Legacy.mm", "include": false, "itemType": "model", "module": "mes" }
  ],
  "storage": { "kind": "directory" }
}
```

| 字段 | 说明 |
| --- | --- |
| `modules[]` | 与 `biz/*.ma` 一一对应；可选 `flowFile` 指向 `flow/*.mf` |
| `defaultModule` | 新建对象的默认模块 / 导航默认展开 |
| `includeDefault` | 未列入 `items[]` 的文件是否默认包含（默认 `true`） |
| `items[]` | **Visual Studio ItemGroup 风格**：只记录与默认不同的包含状态；`include:false` = 排除出校验/生成 |
| `parts[]` | 可选；pack 时写入完整注册表 + `checksum` |

### 2.1 多租户 / 多环境差异（决策 B4）

复用 `items[]` 与「按模块拆文件」：为特定租户定义**额外的 include 文件**（如 `data/models/{tenant}/X.mm`），不新增语言概念；必要时用 `items[].include` 做环境开关。

打开项目：`mmda open ./erp` 或 `mmda open erp.mmdax`（解压后读包内清单）。

---

## 3. 各类型文件

### 3.1 `biz/*.ma`

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

图形投影：`biz/mes.ma` ↔ `biz/mes.ma.g`（`graphKind: ma-module`）。

### 3.2 数据架构

| 路径 | 文件 | 说明 |
| --- | --- | --- |
| `data/models/` | `Order.mm` | `record` / `view`，一类型一文件 |
| `data/enums/` | `OrderStatus.me` | `enum`，一枚举一文件 |
| `data/stms/` | `OrderStatusChanged.ms` | `stm Name on Record.field { … }`，**行为 SSOT** |
| 同目录 `*.g` | `Order.mm.g` / `OrderStatusChanged.ms.g` | 可选；E-R / 状态图布局 |

Record 内不嵌完整 STM：`@State OrderStatusChanged` 指向 `data/stms/OrderStatusChanged.ms`。
图形**语义**在语言文件，**位置/颜色/路由**在 `{SSOT}.g`。

### 3.3 流程架构

| 路径 | 文件 | 说明 |
| --- | --- | --- |
| `flow/roles/` | `SalesMan.mr` | `role` + `auth module` / `actions` / `scope` |
| `flow/converters/` | `AsnToReceipt.mc` | `converter S->T { field->field, … }` |
| `flow/` | `crm.mf` | 跨模块 `flow`；BPMN 活动 / 网关 / 消息流 |

顺序（与 UI 一致）：先 `roles/`，再 `converters/` + `stms/`，最后 `*.mf`。

### 3.4 交互设计 `ui/**/*.mi`

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

未提供 `.mi` 时按 `data/models/*.mm` 生成标准 CRUD。详见 [presentation.md](presentation.md)。

---

## 4. 归档包 `.mmdax`

```
erp.mmdax                 # application/vnd.mmda.package+zip
├── erp.mmda
├── biz/…  data/…  flow/…  ui/…  doc/…
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

| partType | 路径模式 | contentType |
| --- | --- | --- |
| `project` | `{projectCode}.mmda` | `application/vnd.mmda.project+json` |
| `biz` | `biz/*.ma` | `text/x-mmda+ma` |
| `model` | `data/models/*.mm` | `text/x-mmda+mm` |
| `enum` | `data/enums/*.me` | `text/x-mmda+me` |
| `stm` | `data/stms/*.ms` | `text/x-mmda+ms` |
| `role` | `flow/roles/*.mr` | `text/x-mmda+mr` |
| `converter` | `flow/converters/*.mc` | `text/x-mmda+mc` |
| `flow` | `flow/*.mf` | `text/x-mmda+mf` |
| `ui` | `ui/**/*.mi` | `text/x-mmda+mi` |
| `graph` | `**/*.{ma,mm,ms,mf}.g` | `application/vnd.mmda.graph+json` |
| `codegen-profile` | `codegen/profiles/*.yaml` | `application/yaml` |
| `changelog` | `changelog/*.json` | `application/json` |
| `doc` | `doc/**`、`README.md` | `text/markdown` |

---

## 6. 单文件粒度与命名

| 规则 | 说明 |
| --- | --- |
| **一对象一文件** | `Order.mm`、`OrderStatus.me`、`OrderStatusChanged.ms` 各一文件 → 细粒度 diff、减法冲突 |
| 文件名 = 主符号名 | 与语言文件内 `record Order` / `enum OrderStatus` 一致 |
| 子系统前缀（可选） | 大项目可 `data/models/mes/Bom.mm`；`syncRef` 仍为 `mes.Bom` |
| 大小写 | 类型名 PascalCase；`biz` 文件用小写 `mes.ma`；**标识符与生成代码的命名总口径见 [`naming.md`](naming.md)** |

这粒度是为**细粒度版本控制**（决策 B2）服务的：对象级改动只产生对象级 diff，git/svn 合并冲突面最小。

---

## 7. Codegen Profile

路径 `codegen/profiles/*.yaml`，声明目标栈、输出目录、模板集。示例见 [ide/specification.md](ide/specification.md)（`prototype-sqlite`、`prototype-api-rust`、`prototype-api-ts`、`prototype-ui-vue`）。

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
| 内容 | 根清单、`biz/`、`data/`、`flow/`、`ui/`、`**/*.{ma,mm,ms,mf}.g`、`codegen/profiles/`、`doc/` | `generated/` |
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

识别特征：存在 `manifest.json` 且**无**根 `{projectCode}.mmda`，或 `formatVersion` 为 `"1.0"`/`"1.1"`。迁移工具规划：`mmda migrate --to 2.0 ./legacy-project`。**另有语法级改名迁移**：`mmda migrate --rename @PartitionID=@Partitioned`（✔ 2026-09-25 作者同意；默认 dry-run 出待改清单、`--write` 才落盘；**只动语言文件**，不碰生成区 / KEEP 区）—— 解析器**只认新名**，旧项目升级必经这一步（同一条线见 [`naming.md`](naming.md) §5）。ct`。

| 能力 | 规范 | 上一轮实现（mmda-core / Architect） |
| --- | --- | --- |
| 目录 + 扩展名 | ✓ | 迁移中（仍读 1.x） |
| `{code}.mmda` 清单 | ✓ | 待实现 |
| `.mm` / `.me` / `.ms` 解析 | ✓ | Phase 2 分扩展名解析器 |
| pack / unpack | ✓ | ✓ |
| 导航搜索按 kind | — | ✓ |

---

## 11. 相关

- [meta-model.md](meta-model.md) — 逻辑元素
- [ide/graph-files.md](ide/graph-files.md) — `*.g` 格式
- [ide/workflow.md](ide/workflow.md) — 六步工作流与导航
- [errata.md](errata.md) — 口径冲突
