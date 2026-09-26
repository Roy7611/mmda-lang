# MMDA 文档索引

**MMDA-Architect** 规范文档。SSOT 为 `.mmda` 项目 + 下文 **核心规范**；**Legacy 补充**仅收录旧版未覆盖细节。

## 阅读顺序

| # | 文档 | 说明 |
|---|------|------|
| 1 | [overview.md](overview.md) | 愿景、原则、三层架构 |
| 2 | [guide/quickstart.md](guide/quickstart.md) | 上手（mmda-mes 示例） |
| 3 | [architect/specification.md](architect/specification.md) | Architect 工具规格 |
| 3b | [architect/workflow.md](architect/workflow.md) | 架构师六步工作流 |
| 4 | [architect/meta-model.md](../../lang/meta-model.md) | 元模型 |
| 5 | [language/overview.md](language/overview.md) | M语言 |
| 6 | [ai/tools.md](ai/tools.md) | AI 工具 |

## 核心规范

### 工具与项目

| 文档 | 内容 |
|------|------|
| [architect/specification.md](architect/specification.md) | 目标、MVP、Codegen |
| [architect/meta-model.md](../../lang/meta-model.md) | Record、Field、Module、Action… |
| [architect/project-format.md](architect/project-format.md) | 工作区 + `.mmdax` 归档、parts |
| [architect/ui-shell.md](architect/ui-shell.md) | Architect 主界面布局 |
| [architect/workflow.md](architect/workflow.md) | 架构师工作流（六步 + 导航树） |
| [architect/plugins.md](architect/plugins.md) | 插件 API 与扩展点 |
| [architect/diagram-adapters.md](architect/diagram-adapters.md) | Diagram 领域模型与适配器 |
| [architect/i18n.md](architect/i18n.md) | Shell 与模型双层 i18n |
| [architect/diagrams.md](architect/diagrams.md) | E-R、STM、DFD |

### M语言

| 文档 | 内容 |
|------|------|
| [language/overview.md](language/overview.md) | 原则、MVP 子集 |
| [language/types.md](language/types.md) | 数据类型 |
| [language/records.md](../../lang/records.md) | record、enum、view |
| [language/behaviors.md](language/behaviors.md) | @Action、@State |
| [language/expressions.md](language/expressions.md) | 表达式 |

### 呈现与事件

| 文档 | 内容 |
|------|------|
| [metadata/ui-field.md](metadata/ui-field.md) | UiField、groupLabel |
| [events/architecture.md](events/architecture.md) | 事件驱动 |
| [events/language.md](events/language.md) | 事件 M语言（Phase 2） |

### AI

| 文档 | 内容 |
|------|------|
| [ai/tools.md](ai/tools.md) | MCP / CLI |
| [ai/vibe-spec.md](ai/vibe-spec.md) | Vibe & Spec |

### 参考

| 文档 | 内容 |
|------|------|
| [glossary.md](glossary.md) | 术语 |
| [examples/mmda-mes/README.md](../examples/mmda-mes/README.md) | 标准示例 |
| [templates/conventions.template.md](templates/conventions.template.md) | 项目约定模板 |

## Legacy 补充（非 SSOT）

早期 Java 用户手册与 `D:\2026\java` 实现。见 [legacy/README.md](legacy/README.md)。

| 文档 | 内容 |
|------|------|
| [legacy/import-from-ddl.md](legacy/import-from-ddl.md) | DDL COMMENT 逆向 |
| [legacy/java-factory.md](legacy/java-factory.md) | mmda meta/java/vui |
| [legacy/runtime-java.md](legacy/runtime-java.md) | Repository、UiLogic |

## 版本

规范草案 **0.1** · 2026-06
