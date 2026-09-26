# Java 运行时（Legacy 参考）

> 新规范未定义具体 Runtime 实现；本文为 Java 版 `mmda-core` 行为摘要。

## 仓储（无 ORM 映射文件）

```
EntityService → EntityRepository → SQL（由元模型组装） → Database
```

- 根据 MetaObject / MetaCol 组装 INSERT、UPDATE、DELETE、SELECT
- 按方法名缓存 SQL，减少重复解析
- HAS_ONE / HAS_MANY 的 join 与组装在 Service.load / save
- **无 ORM 映射文件**：表结构来自元模型，而非注解或 XML

## SQL 构建器

| 接口 | 职责 |
|------|------|
| ISqlBuilder | 方言无关片段：SELECT/FROM/WHERE/ORDER BY |
| ISqlQueryBuilder | 查询、分页、关联、过滤 |
| ISqlCommandBuilder | INSERT/UPDATE/DELETE |

支持 MySQL、SQL Server、PostgreSQL 等方言；类型映射见 [language/types.md](../lang/datatypes.md) 与 MetaDataType 表。

## 与 Codegen 的关系

| 产物 | 来源 |
|------|------|
| Entity / Record 类 | Codegen Profile |
| Repository 类 | 模板 + MetaObject |
| SQL 文本 | 运行时 SqlBuilder **或** 预生成 DDL |

原型 Profile 可只生成 **DDL + 薄 Repository 接口**；完整 Runtime 在应用依赖中提供。

## API 序列化（REF / HAS_ONE）

| 关系 | JSON 形态 |
|------|-----------|
| HAS_ONE | 嵌套对象属性 |
| REF / ENUM 显示 | `customProperties.$fieldName` 放标签 —— **⤴ 2026-09-26：新设计取消该形态**（呈现信息不进业务载荷，见 [`api.md`](../api.md) §3.5）；本页照旧描述**遗留实现** |

```json
{
  "workDeptID": "…",
  "workDepartment": { "deptID": "…", "deptName": "采购部" },
  "techTitleID": 1205,
  "customProperties": { "$techTitleID": "经济师" }
}
```

> **遗留形态（⤴ 2026-09-26）**：本节是**旧实现**的载荷形态；**新设计里 `label` / `description` / `color` / `icon` 不进业务数据**（`description` 连元数据一次下发都不做）。**老代码不动，照旧跑**。

**服务端「组装」的实证（新设计已取消）**：`customProperties` 这些文本是后端在返回前**逐条装配**出来的——

| 旧实现 | 位置 | 干什么 |
| --- | --- | --- |
| `EntityRepository.assembleEnumProperties(T)` | `mmda-core-data/.../jdbc/repository/EntityRepository.java:411` | 遍历枚举列，把 `MetaEnum` 里查到的显示文本 **`t.setRefProperty(colName, text)`** 写进实体影子属性，并 `setAssembled(ASSEMBLE_ENUM)` 防重复 |
| `DomainService.assembleSingle` / `assemble` | `mmda-core-services/.../DomainService.java:330` / `:343` | `assembleEnumProperties(assembleRefProperties(assembleOne(AndMany)))` —— 枚举 + 引用 + 一对一/一对多**全组装** |
| `Repository.assembleEnumProperties` | `.../repository/Repository.java:117` | 接口声明（生成器 `JavaReactiveRepositoryCodeBuilder.java:250/327` 直接把它编进 Repository 实现） |

⇒ **新设计取消**（✔ 2026-09-26 作者：「**再也不用 assembleEnums 了，通常一个用户习惯用一种语言，下发那个 locale 即可**」）：**`label` 走词条**（**按 locale 分片**：一次一份、任意 locale、客户端按 locale 缓存 —— ⤴ 作者修订：「我在 indexedDb 里是分 locale 的，前端支持语言切换」）、**`color` / `icon` 随元数据**（⤴ 三次修订：「**color, icon 走不了词条**」—— 语言无关、一次下发）、**`description` 另存 comments 层**（不进 JSON，⤴ 「**我想用 comments 类似 SQL 数据库中的注释，另外存储的**」）、**引用数据走数据层 locale 分行**（见 [presentation.md](../lang/presentation.md) §5、[api.md](../api.md) §3.5）。

REF 适合小表、可缓存；HAS_ONE 适合完整导航。见 [meta-model.md](../lang/meta-model.md)。

## UiLogic 钩子（Vue 参考实现）

在生成的前端 `*_logic.ts` KEEP 区扩展：

| 钩子 | 用途 |
|------|------|
| beforeEdit | hideIf、onChange、onValidate |
| beforeDetails | hideIfEmpty |
| beforeIndex | 列表列行为 |

API：`lockIf`、`hideIf`、`requiredIf`、`onChange`、`onValidate`。

视图级替换（默认呈现不够时）：`setCustomEditor(...)` / `setCustomRenderer(...)`——替换生成的标准编辑控件 / 只读呈现控件，属于**皮肤内部的自由**（[presentation.md](../lang/presentation.md) §5.1）。

## 缓存

- 元对象：Redis / 进程内（参考 `SqlMetadataProvider`）
- REF 数据源：应用级（小表）
- Repository：SQL 文本缓存

## 新规范下的演进

| 项 | 方向 |
|----|------|
| SSOT | `.mmda` → 导入 Runtime 或嵌入 sqlite 索引 |
| Rust Runtime | 可选 `sqlx` + 元数据驱动查询构建 |
| AI | 禁止手写与元模型冲突的原生 SQL |
