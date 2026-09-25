# AI 可调用工具规范

MMDA-Architect 通过 **MCP Server** 与 **`mmda` CLI** 暴露工具，供 Cursor 等 Agent 在规范边界内操作项目。  
工具接口**语言无关**；不假设 Java 或其他后端存在。

## 1. 设计原则

1. **读写分离**：`read_*` 与 `write_*` 权限可配置。
2. **幂等与预览**：`write_*` 支持 `dryRun` 返回 diff。
3. **SSOT**：工具操作 MMDA 项目（工作区目录；`.mmdax` 需 unpack 或缓存展开）；不直接改 `generated/`（除非 `generate_*`）。
4. **可观测**：每次调用记录到 Design Change Log 或工具审计日志。
5. **KEEP 边界**：AI 默认不可修改 `GENERATED` 区；业务逻辑写入 Profile 约定的 KEEP 路径。

## 2. MCP 工具清单（Phase 1）

### 2.1 项目

| 工具 | 说明 |
|------|------|
| `mmda_project_open` | 打开工作区目录或 `.mmdax`，返回 manifest 摘要 |
| `mmda_project_validate` | 全项目校验，返回 errors/warnings |
| `mmda_project_pack` | 目录 → `.mmdax`（可选刷新 parts/checksum） |
| `mmda_project_unpack` | `.mmdax` → 目录 |
| `mmda_project_export` | 导出 JSON 或 M语言 打包 |

### 2.2 读取

| 工具 | 说明 |
|------|------|
| `mmda_list_schemas` | 逻辑库列表 |
| `mmda_list_records` | Record 列表（可按 schema 过滤） |
| `mmda_get_record` | 单个 Record AST + M语言 源码 |
| `mmda_list_modules` | Module 树 |
| `mmda_get_actions` | Feature 的 Action 列表 + statusTransition |
| `mmda_get_enum` | 枚举定义 |
| `mmda_get_conventions` | 读取 `conventions.md` |

### 2.3 写入（需确认或 dryRun）

| 工具 | 说明 |
|------|------|
| `mmda_patch_record` | JSON Patch 或 M语言 片段合并到 Record |
| `mmda_add_field` | 添加 Field |
| `mmda_add_action` | 添加 Action |
| `mmda_add_module` | 添加 Module 节点 |

### 2.4 生成

| 工具 | 说明 |
|------|------|
| `mmda_generate` | 按 profileId 生成原型 |
| `mmda_generate_report` | 上次生成文件清单与 diff |
| `mmda_api_export` | 导出 **OpenAPI 3.1.0** 文档（原生后端，非插件；含 `x-mmda-*` 溯源指针）——详见 [`../api.md`](../api.md) §3 |
| `mmda_api_check` | 官方 Schema 校验 + 契约测试（实际行为 vs 文档） |

### 2.5 测试与验收（详见 [`../testing.md`](../testing.md)）

> **UAT 是交付验收的唯一标准**（2026-09-25 作者共识）：UAT 用例**需求完成即出**、**必须可执行**；AI 的执行通道 = **hooks**（三端拦截点，[`../runtime.md`](../runtime.md) §4.2）+ `mmda_test_run`；**人只做两件事——定验收标准、审核签字**。AI 可以跑、可以驱动、可以诊断，**判定仍只来自声明与冻结基线**（[`../testing.md`](../testing.md) §0.1 / §0.2）。

| 工具 | 说明 |
|------|------|
| `mmda_diff_impact` | 变更影响面：哪些 Record/字段/接口/页面/DDL 会变——**写元模型前必调** |
| `mmda_test_gen` | 从声明/需求生成用例（机械部分零 AI），同时返回**未覆盖声明清单** |
| `mmda_mock_gen` | **造 mock 数据**：机械层（引用图拓扑排序 / 边界值 / 枚举，零 AI）+ AI 语义层（中文业务数据 / 跨字段联动 / 刁钻样本）；必须带 `seed` 与 provenance——详见 [`../testing.md`](../testing.md) §4.3 |
| `mmda_test_run` | 跑用例（可指定 target / baseline），返回通过与失败明细 |
| `mmda_test_impact` | 某次变更影响的用例清单（新增 / 失效 / 需改期望值） |
| `mmda_accept_report` | 生成中文验收单（`--lang zh`），供业务人员签字 |

> 约束：AI 生成的用例**必须**由人签字（`reviewedBy` 非空）才计入验收；`mmda_test_run` 的判定标准来自声明与冻结基线，**不接受 AI 自评通过**；不得修改已冻结的 baseline 用例。
> **AI 造数（`mmda_mock_gen`）的例外与边界**：它产出的是**输入层数据**，不是断言——所以**不需要双签**，但必须：① 只使用声明里存在的字段名 / 枚举值 / 状态名（越界值直接丢弃）；② 过 JSON Schema + 元数据约束两道校验，不过校验不进基线；③ 带种子与 provenance 可复现。**AI 断言仍然必须双签**（[`../testing.md`](../testing.md) §4.3）。

### 2.6 质量与架构评估（详见 [`../quality.md`](../quality.md)、[`../architecture-review.md`](../architecture-review.md)）

| 工具 | 说明 |
|------|------|
| `mmda_quality_report` | ISO/IEC 25010 九维报告（证据 / 等级 / 达标或未评估），含架构评估结论 |
| `mmda_quality_gate` | CI 门禁：只断言 A/B 类质量项 |
| `mmda_arch_report` | 架构评估：硬规则违规清单 + Martin 度量（`I`/`A`/`D`）+ 关注点缺口 + 建议 |
| `mmda_arch_gate` | 架构硬规则门禁（ARCH-101/102/104/105 等） |
| `mmda_arch_recommend` | AI 建议草案（改法 + 反例 + 影响面）——**AI 不评分** |

### 2.7 原型运行（Phase 2）

| 工具 | 说明 |
|------|------|
| `mmda_prototype_up` | 启动本地原型（docker compose 或内置） |
| `mmda_prototype_down` | 停止 |

## 3. CLI 示例

```bash
mmda open ./my-project
mmda open ./delivery.mmdax
mmda pack ./my-project -o ./delivery.mmdax
mmda unpack ./delivery.mmdax -o ./my-project-restored
mmda validate
mmda get record mes.ProductionOrder --format lang
mmda patch --file models/mes/ProductionOrder.mmda --dry-run
mmda generate --profile prototype-sqlite
```

## 4. 典型 Agent 工作流

```
1. mmda_project_open
2. mmda_get_conventions + mmda_get_record（只读相关子集，禁止整仓灌上下文）
3. 架构师/用户 Spec 说明变更；确定**变更级别**（../workflows.md §8）
4. mmda_diff_impact（影响面）→ mmda_patch_record（dryRun → 确认 → 提交，含 changelog）
5. mmda_project_validate（零 error）
6. mmda_test_gen（机械用例）+ 需要时出 AI 用例草稿 → **人审签字**
7. mmda_generate → mmda_test_run（跨端一致）
8. 在 generated/.../KEEP 目录编写业务逻辑（受 conventions 约束）
9. 开 PR：描述里附影响面、变更级别、用例与基线差异
```

## 5. 输入输出格式

- **AST 交换**：JSON（符合 [meta-model.md](../meta-model.md)）
- **人类可读**：M语言 文本
- **错误**：`{ code, path, message, severity }[]`

## 6. Cursor 规则模板

项目内 `.cursor/rules` 建议包含：

- 只修改 `conventions.md` 规定的 KEEP 路径
- 写元模型前先 `mmda_diff_impact`，提交必须带 changelog 条目
- 改元模型前调用 `mmda_project_validate`
- 禁止手改 `generated/**` 的 GENERATED 区
- 引用 Record 时使用 `schema.Name` 全名
- 生成的用例必须人审签字（`reviewedBy` 非空）才计入验收；禁止把 AI 自评当验收依据
- 禁止修改已冻结的 baseline 用例（只能提变更）

见 [vibe-spec.md](vibe-spec.md)。

## 7. 安全

| 项 | 策略 |
|----|------|
| 路径 | 限制在项目根内 |
| 写操作 | 可选用户确认 |
| 密钥 | 不得写入 `.mmda`；用环境变量 |

## 8. 相关

- [vibe-spec.md](vibe-spec.md)
- [../ide/specification.md](../ide/specification.md)
