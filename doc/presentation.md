# 呈现层（Presentation）

> 本文接纳早期空壳 `presentation.md` 与上一轮 `metadata/ui-field.md`、`architect/i18n.md` 的模型侧内容。
> 立场：**存储语义（Field）与呈现语义（UiField）分离**——同一字段在不同视图可有不同呈现，字段本身不被 UI 细节污染。

---

## 1. 五个标准视图

| 视图 | 形态 | 对应 |
| --- | --- | --- |
| `index` | 列表 / 表格 | 列表页 |
| `editor` | 表单 | 新建 / 编辑 |
| `details` | 详情 | 只读详情 |
| `search` | 查询条件 | 高级搜索 |
| `report` | 报表 | 统计输出 |

定制视图放在 `ui/{子系统}/{Name}.mi`；未提供 `.mi` 时框架按 `data/models/*.mm` 的元数据生成标准 CRUD。

**视图钩子**（前端 `UiLogic`，对应关系 ✔ 已裁 2026-09-24）：`index` → **`beforeIndex`**、`editor` → **`beforeEdit`**、`details` → **`beforeDetails`**、`search` → **`beforeSearch`**（本轮按作者要求补上）；**`report` 暂不设钩子**（未提，待有实现再裁）。参考实现见 [legacy/runtime-java.md](legacy/runtime-java.md)。

```sql
/// BOM 列表
ui BomList for Bom {
    index: BomList,
}

/// BOM 编辑器
ui BomEditor for Bom {
    editor: BomEditor,
}
```

---

## 2. UiField 属性

描述字段在列表/详情/编辑中的呈现方式，与 Field 的存储语义分离。

| 属性 | 说明 |
| --- | --- |
| `fieldName` | 键；可跨 Record 复用；**自动生成，勿手改** |
| `formatter` | 只读格式化：`D` 日期、`N3` 三位小数 |
| `align` | 0 左 / 1 右 / 2 居中 |
| `renderer` | 只读呈现器（如标签、进度条） |
| `editor` | 编辑控件：`dropdown`、`searchBox`、`numberInput` … |
| `placeholder` | 占位符 |
| `listSize` | 列宽 |
| `sortable` | 可排序 |
| `validationRules` | 校验提示 |
| `nullDisplayText` / `tooltip` | 空值显示、提示 |
| `dataBinding` | 绑定字段 |

Field 侧管列表与分组的属性：`groupLabel`、`listed`、`filterable`、`hidden`（见 [meta-model.md](meta-model.md)）。

---

## 3. `groupLabel` 分组约定

| 前缀 | 含义 |
| --- | --- |
| `a1`…`a9`、`b1`… | 主信息区（分组序号由数字解析） |
| `s1`…`s9` | 概要信息区 |

表单按 `groupLabel` 分组渲染，顺序由分组序号决定。

---

## 4. 关系字段的默认呈现

| 关系 | 默认 editor |
| --- | --- |
| `@Ref` / 旧 `REF` | `dropdown` |
| `@One` / 旧 `HAS_ONE` | `searchBox` |
| `@Many` | 子表 / 子网格 |

Codegen 读取 Field 的 `listed` + UiField 的 `formatter` / `editor` 生成列表与表单。

---

## 4.1 枚举的呈现：颜色与图标（✔ 已裁 2026-09-25）

**语法在 [`records.md`](records.md) §6.1**（`@Colorized(role, depth?)` / `@Iconized(default | "prefix")` 开关 + 默认值、成员 `@Color(role, depth?)` / `@Icon("alias")` 取值），本节只说**渲染口径**。

| 项 | 口径 |
| --- | --- |
| 渲染方 | **前端（TS）唯一渲染方**（§5.1 UI 契约）：后端只出 `MetaEnum` / `MetaEnumMember` 的 `colorized` / `iconized` / `colorRole` / `icon` |
| 颜色 = 角色 + 深度，不是色值 | `@Color(role, depth)` 只给**语义角色**（**封闭 7 值**：`primary` / `secondary` / `info` / `success` / `warning` / `danger` / **`gray`**，语言层校验、拼错即解析期 error）与**色板深度**（**封闭 10 档** `50`–`900`；`200` = 浅档、`500` = 基准；**省略深度 = `500`**）；**具体色值来自主题令牌**（Material Design + Theme Builder，见 [`ide/specification.md`](ide/specification.md) §4.8 域 7）—— 深浅色与皮肤切换由主题层负责，**模型层不写 `#RRGGBB`** |
| 图标 = 别名，不是库绑定 | `@Icon("cancel")` 是**逻辑别名**（**开放**：开发人员自行定义语义词，语言层不内置清单、不校验存在性）：TS / Syncfusion（`e-icons`）、C# / FontAwesome、Flutter / Material Icons 各自映射成具体图标；**模型层不写 `fas fa-x`** |
| 别名没映射上 | **充其量不显示**（不报错、不阻塞）；UI 层 / IDE **可给 warning / lint** 作为提醒（**可选**） |
| 开关与取值 | 开关在**枚举声明**、取值在**成员**；**没开开关不渲染**；**开了开关但成员缺值 → 先取声明的默认值**（默认色 / 默认别名），**没有默认值才不渲染**（不报错） |
| 默认值 | **颜色**：`@Colorized(role, depth?)` 给默认色，成员 `@Color` 缺省即**回落**；**图标**：`@Iconized`（不写括号）默认别名 = **成员名 kebab**（`DESIGN` → `design`）、`@Iconized("prefix")` 默认别名 = `<prefix>-<成员名 kebab>`（`bom-design`）；成员显式 `@Icon("x")` 是**完整别名**、**不再叠前缀** |
| 深度 → 令牌 | 角色 + 深度映射到主题的色板（如 `primary` 的 `200`）；**具体令牌名由皮肤定义**，模型层不写色值 |
| 缺注解 | 枚举**按文本渲染**（旧行为不变，向后兼容） |
| 渲染形态（默认） | 列表 / 表单里：颜色用于**标签或其徽章底色**，图标置于标签**前**；具体形态可由视图层（`ui/**/*.mi`）覆盖 |
| i18n | 颜色 / 图标**不是翻译对象**（§5 的 i18n 只管标签 / `placeholder` / `tooltip`） |
| 与业务色区分 | 业务数据里的「每行一个色」（`taskColor varchar(7)`、`bankColor`）是**数据**，不是呈现语义；两者不互相替代 |

> ✔ 细节 6 条**已裁**（2026-09-25）：颜色角色**封闭 6 值**（拼错 = 解析期 error）、主题不新增角色；**图标别名开放**（开发人员定义语义词、UI 层映射、没映射上顶多不显示、warning 可选）；`@Icon` 只收别名；字段级不覆盖（视图级归 `ui/**/*.mi`）；缺开关写取值 = warning。见 [`records.md`](records.md) §6.1。

## 5. 国际化（i18n）

分两层，**不要混**：

| 层 | 归属 | 内容 |
| --- | --- | --- |
| Shell i18n | IDE 自身（Vue） | 界面文案；见 [ide/i18n.md](ide/i18n.md) |
| Model i18n | 项目 SSOT | 模型元素的显示名与翻译：`displayLabel`、UiField 的 `placeholder`/`tooltip`、枚举成员标签 |

模型侧翻译在元数据里的承载（旧实现）：`MetaUi18n`（词 → 翻译）、`MetaUiFieldI18n` / `MetaUiFieldI18nt`（字段级，按 locale 与 tenant 覆盖）。

项目清单里声明语言集合：

```json
{ "defaultLocale": "zh-CN", "locales": ["zh-CN", "en", "zh-Hant"] }
```

---

## 5.1 UI 契约（✔ 已裁 2026-09-24）

**唯一 UI 通道 = 现有的 mmda-vue 前端项目**（`D:\2026\ts\mmda`）。**不考虑 C# MVC**（`Mmda.Ui.Blazor` / `Mmda.Ui.Razor` / `Mmda.Ui.VtRazor`）**与 Java 的 UI**；**后端（Java / C#）只提供 `MetaUi` 元数据**。

数据流（单向、无回环）：

```
m 声明（ui/**/*.mi + Field/UiField）→ IR → 后端适配成 MetaUi（Java / C# 各一份薄适配）→ mmda-vue 消费渲染
```

| 端 | 职责 | 实测现状（P0.5 盘点） |
| --- | --- | --- |
| 后端 A（Java） | **只产出 `MetaUi` 元数据，不渲染** | `mmda-core-metadata/…/metadata/MetaUi.java:21`、`MetaUiField.java:24`、`MetaUiGroup.java:20`、`MetaUi18n.java:15`、`MetaUiFieldI18n.java`、`MetaUiFieldI18nt.java`、`enums/MetaUiView.java` + 4 个 RowMapper（`MetaUiField`/`MetaUi18n`/`MetaUiFieldI18n`/`MetaUiFieldI18nt`） |
| 后端 B（C#） | **只产出 `MetaUi` 元数据，不渲染** | `Mmda.Core.Metadata/Metadata/MetaUi.cs:12`、`MetaUiField.cs:25`、`MetaUiGroup.cs:13`、`MetaUi18n.cs:35`、`MetaUiFieldI18n.cs`、`MetaUiFieldI18nt.cs` |
| 前端（TS）**唯一渲染方** | 消费 `MetaUi` 并渲染；皮肤可换 | `D:\2026\ts\mmda`：`packages/core/src/metaui/*`（8 文件 / 2,626 行：`metaui_field` 659、`metaui_group` 387、`metaui_service` 349、`metaui_builder` 344、`module` 301、`metaui_filter` 269、`validator_parse` 162、`datatype` 155）、`packages/core/src/ui/*`（`renderer.ts:5` `UiRenderer`、`factory.ts:124` `UiFactory`、`context.ts:76` `UiContext`、`builder*`、`props.ts`、`slots.ts`） |

**三条随之确定的界限**：

1. **后端不做页面组装**：`MetaUi` 里不许出现框架专属概念（组件名、CSS、事件名）。
2. **UI kit 是前端自己的事**（Vue 系 `vui` / `vui-syncfusion` / `vui-primevue` / `vui-agnaive`，React 系 `rui` / `rui-syncfusion`，+ 9 个 `vuix-*` 插件）：**不进后端契约，也不进 m 语言**——避免把 UI 库耦合进元数据。**`vui`（Vue）与 `rui`（React）都可选、随技术人员喜好（✔ 已裁 2026-09-24）**：自定义前端 UI 插件时，写插件的人可以挑自己熟悉的技术栈；这是**同一个前端项目内部的自由，不构成两套 UI 契约**（契约边界只到 `MetaUi`）。
3. **一致性测试的 UI 维度只测 TS 侧**；`capability` 的 `ui` 能力**只在 `target ts` 上声明**（缺能力 → 生成期报错）。

> 该裁决**收紧**了同日的前一条（"不统一抽象、各端 kit 自己渲染"）：现在**只有一端有 kit**。C# 的 `Mmda.Ui.*` 与 Java 侧任何 UI 尝试一律视为**遗留实现**：不纳入契约、不随 mmda-lang 演进、不作为生成目标。

---

## 6. 项目内呈现配置

| 位置 | 说明 |
| --- | --- |
| `ui/{子系统}/{Name}.mi` | 定制视图定义（五视图引用） |
| `ui/{schema}/*.ui.yaml` | （规划）字段级呈现配置 |
| 旧实现 | 元数据库里维护 `MetaUiField`，或在前端 `UiLogic` 里以代码扩展 |

> ⚠️ `.mi` 的完整语法（布局、绑定、事件）尚未定稿；`presentation.md` 原为空壳，本轮只并入 UiField / i18n 的既有定义。界面布局见 [ide/ui-shell.md](ide/ui-shell.md) 与 [design-notes.md](design-notes.md) 的「交互设计」一节。

---

## 7. IDE 需求（来自落地计划 B2）

**多语言映射编辑**：IDE 要支持「类似 VS 资源编辑器」的并排编辑——同一对象/字段的多语言标签、UiField 属性、以及**各目标栈的映射**（Java/C#/TS 的类型与呈现映射）在同一界面编辑并保持同步。这是 P7 的输入，元模型侧须保证这些信息能从 IR 完整还原。

---

## 8. 相关

- [meta-model.md](meta-model.md) — Field / UiField 元模型
- [ide/ui-shell.md](ide/ui-shell.md) — 界面布局
- [ide/i18n.md](ide/i18n.md) — 双层 i18n
- [records.md](records.md) — 字段定义
