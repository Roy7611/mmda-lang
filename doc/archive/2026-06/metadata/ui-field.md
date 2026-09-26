# UiField 与表单呈现

UiField 描述字段在**列表/详情/编辑**场景的呈现方式，与 Field 的存储语义分离。  
Field 上的 `groupLabel`、`listed`、`filterable`、`hidden` 见 [meta-model.md](../../../lang/meta-model.md)。

## MetaUiField 属性

| 属性 | 说明 |
|------|------|
| fieldName | 键；跨 Record 复用；**自动生成勿改** |
| formatter | 只读格式：`D` 日期、`N3` 三位小数 |
| align | 0 左 / 1 右 / 2 居中 |
| renderer | 只读呈现器 |
| editor | 编辑控件：dropdown、searchBox、numberInput |
| placeholder | 占位符 |
| listSize / sortable | 列宽、可排序 |

## groupLabel 约定

| 前缀 | 含义 |
|------|------|
| a1…a9, b1… | 主信息区（groupIndex 由数字解析） |
| s1…s9 | 概要信息区 |

## 默认映射

| FieldRef | 默认 editor |
|----------|-------------|
| REF | dropdown |
| HAS_ONE | searchBox |

Codegen 读取 MetaCol.`listed` + UiField.`formatter` / `editor` 生成列表与表单。

## 项目内配置

Architect Phase 2 支持 `ui/{schema}/*.ui.yaml`。当前可在 Legacy 元库维护 MetaUiField，或通过 UiLogic 代码扩展（见 [legacy/runtime-java.md](../legacy/runtime-java.md)）。
