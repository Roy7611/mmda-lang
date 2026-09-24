# 项目约定模板

复制到新 `.mmda` 项目根目录，命名为 `conventions.md`，并按项目修改。

## 1. 目录职责

| 路径 | 谁改 | 说明 |
|------|------|------|
| `models/**/*.mmda` | 架构师 / AI | SSOT |
| `modules/`、`actions/` | 架构师 | 功能架构 |
| `generated/` | 工具 | 禁止手改 GENERATED 区 |
| `handlers/` | 工程师 / AI | Action 实现（KEEP） |

## 2. 命名

- Record / Enum：PascalCase
- Field / Action：camelCase
- 接口：`I` 前缀；实现类用业务名（**禁止 `Impl` 后缀**）——总口径见 [`../naming.md`](../naming.md)
- 全名：`schema.Record`

## 3. AI / 开发者

- 改元模型后：`mmda validate <project>`
- Handler 路径：`handlers/{moduleCode}/{actionName}.handler.*`

## 4. 禁止

- 修改 `generated/**` 的 GENERATED 区
- 未在元模型声明的字段或 API
