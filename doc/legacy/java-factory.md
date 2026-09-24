# Java 代码工厂（Legacy 参考实现）

> 对应 `D:\2026\java\mmda-foundation\mmda-factory`。新规范目标为 Codegen Profile + `mmda generate`。

## 应用配置示例

```yaml
# hrm.yaml
name: hrm
groupId: cloud.mmda
locales: [zh, zh-Hant, en]
dependencies:
  javaVersion: 21
  useLombok: true
dataSource:
  username: root
  url: jdbc:mysql://localhost/hrm?...
output:
  java: { models: models, data: data, services: services, controllers: api }
  vui: d:/web
  flui: d:/flutter
```

新规范等价物：`manifest.json` + [project-format.md](../project.md) + `codegen/profiles/*.yaml`。

## 命令

| 命令 | 作用 |
|------|------|
| `mmda meta hrm` | DDL → `mmda_metadata` |
| `mmda java hrm` | Java models/data/services/api |
| `mmda java hrm --models` | 仅实体 |
| `mmda java hrm.Department --models` | 单实体 |
| `mmda vui hrm` | Vue 3 + TypeScript |
| `mmda flui hrm` | Flutter |

## 映射到新规范

| Legacy | 新规范 |
|--------|--------|
| `mmda_metadata` | `.mmda` 项目 |
| `mmda meta` | `mmda import`（规划） |
| `mmda java/vui` | `mmda generate --profile` |
| hrm.yaml | `manifest.json` + `codegen/profiles/` |

## Legacy 元库表映射

MySQL `mmda_metadata` 表名与逻辑元素对照（**导入用，非 SSOT**）：

| 逻辑元素 | Legacy 表 |
|----------|-----------|
| Schema | `MetaDb` |
| Record | `MetaObject` |
| Field | `MetaCol` |
| Relation | `MetaRelation` |
| Enum | `MetaEnum` |
| DataType | `MetaDataType` |
| Module | `Module` |
| Action | `ModuleAction` |
| FlowEdge | `ModuleFlow` |
| UiField | `MetaUiField` |
| Design Change Log | `ChangeLog` |
| FlowTrail（运行时） | `FlowTrail` |

## 导入后常改元数据

### MetaObject

| 字段 | 说明 |
|------|------|
| partitionKey / uniqueKey | 多租户与业务唯一 |
| fixedFilter | UI 状态页签过滤 |
| partitioned | 物理表分区标志 |

### MetaCol（列表/表单）

| 字段 | 说明 |
|------|------|
| groupLabel | `a1` 主要 / `s9` 概要（见 [ui-field.md](../presentation.md)） |
| listed / filterable / hidden | 列表与过滤 |

### MetaRelation（一对多需手加）

```
joinOn: empID=@empID
relationType: 2 (HAS_MANY)
```

M语言 等价：`@Many items Child[*]`。

## GENERATED / KEEP

```java
//region ~GENERATED PARTS BEGIN
// ... 再生成会覆盖 ...
//endregion ~GENERATED PARTS END
// 下方手写 promote、leave 等业务方法
```

新规范使用相同标记约定，见 [glossary.md](../glossary.md)。
