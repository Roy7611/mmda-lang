# IDE 与工具文档（迁入说明）

本目录的文档来自上一轮尝试 `E:\Dev\mmda-architect\doc\architect\`（2026-06），**原样迁入，未改写**，因为它们是工具/界面/图形引擎的规格，不涉及本轮语言语法裁决。

| 文件 | 内容 | 当前可用性 |
| --- | --- | --- |
| `specification.md` | Architect 工具规格（定位、用户、MVP、阶段、成功标准） | ✅ 可用；其中「`.mmda` = 项目」的口径与决策 B8 冲突，见 [`../errata.md`](../errata.md) 冲突 3 |
| `workflow.md` | 架构师六步工作流（业务→数据→流程→交互→交付）与导航树 | ✅ 可用 |
| `ui-shell.md` | 主界面布局、Host 抽象、技术栈（Tauri + Vue 3 + Syncfusion）、目录 | ⚠️ 技术栈待随 `..\PLAN.md` P7 复核 |
| `plugins.md` | 插件清单、扩展点、注册与加载；**§8–§12 设计阶段原生支持 / 插件市场 / 权限与硬边界 / 加载形态** | ✅ 可用 |
| `diagrams.md` | E-R / STM / DFD / 模块树 与元模型的映射 | ✅ 可用 |
| `diagram-adapters.md` | 图形引擎适配器接口（Syncfusion 参考实现） | ✅ 可用 |
| `graph-files.md` | 图形投影 `*.g` 的 JSON 格式（布局与语义分离） | ✅ 可用 |
| `i18n.md` | Shell 与模型双层国际化 | ✅ 可用 |

## 迁入时的注意事项

1. **术语按本轮统一**：文中 `manifest.json`（formatVersion 1.x）是历史形态；2.0 用根 `{projectCode}.mmda` 清单，见 [`../project.md`](../project.md)。
2. **`.ma` 正文形态**：文中称 `.ma` 是语言文本 —— **✔ 已裁（2026-09-25，取语料）**：**`.ma` 是 JSON**、`.mm` / `.me` / `.ms` / `.mi` 是 M 语言文本，见 [`../errata.md`](../errata.md) 冲突 2。
3. **目录引用**：原文里的相对链接（如 `../language/records.md`、`../metadata/ui-field.md`）在本仓库已改址为 `../records.md`、`../presentation.md`，跳转可能失效——按 `../index.md` 检索。
4. **设计笔记**：原文根目录的 `mmda-workflow.md`（36 KB，含各层语言示例）已迁至 [`../design-notes.md`](../design-notes.md)。
5. **工程契约**：本轮的落地口径（Rust 内核、IR、宿主、DDL、代码生成、IDE 阶段）以 `..\..\PLAN.md` 为准；这些文档描述的是**界面与图形**层面。
