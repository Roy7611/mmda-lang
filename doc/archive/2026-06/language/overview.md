# M语言概述

**M语言**（英文 **M language**）是 MMDA 元模型的文本语法；Monaco 编辑器语言 id 为 `m-lang`，MIME 为 `text/x-m-lang`。融合 SQL、C#、Java、Rust 等语言的惯用写法，用于描述：

- **系统架构**：存储、呈现、计算架构；
- **系统设计**：数据流（读、写、校验、映射、转化、聚合、呈现）；
- **事件编程**：数据变化监听、触发器；
- **实现接近**：数据库迁移、多语言转译；
- **Vibe & Spec**：设计规格直接交给 AI 实现。

## 与元模型的关系

```
.mmda 项目（SSOT，formatVersion 2.0）
    ├── {code}.mmda          ← 项目清单
    ├── biz/*.ma             ← Module 架构
    ├── data/models/*.mm     ← Record / View
    ├── data/enums/*.me
    ├── data/stms/*.ms       ← STM（行为 SSOT）
    ├── flow/*.mf            ← 跨模块流程
    └── ui/**/*.mi
         ↕ parse / emit
    元模型 AST（语言无关）
         ↕
    Architect 图形视图
```

Legacy 1.x：`manifest.json` + `models/**/*.mmda` — 见 [architect/project-format.md](../architect/project-format.md) §12。

**规则**：M语言 源文件与元模型 AST 双向等价；图形编辑产生 AST Patch，再 emit 为 M语言。

## 设计原则

1. 用 `record` 而非 `class`——对象是持久化实体，不是内存 OO 类。
2. 字段默认有 getter/setter 语义，不写样板代码。
3. `->` 表示状态**转移**；`=>` 表示 lambda **映射**。
4. `as` 在声明中是**别名**；在其他上下文是类型转换。
5. 注释 `///` 生成文档；支持 Markdown。

## MVP 语法子集（Phase 1）

Architect Phase 1 解析器只需实现以下子集：

| 类别 | MVP 包含 | Phase 2+ |
|------|----------|----------|
| 结构 | `record`, `enum`, `@Id`, `ref`, `@Many[+]` | `view`, 继承 |
| 类型 | bool, int/uint 8–64, decimal, string, DateTime | BitVector, Stream, uint128 |
| 约束 | `?`, `default`, `indexed`, `unique` | `#regex`, `@Check` |
| 行为 | `@State`, `@Action`, `A->B` | `@Transaction`, `@Event`, `@trigger` |
| 关系 | `ref`, `HAS_ONE` 风格 | 完整 view join |
| 事件 | — | `event`, `subscribe` |

完整语法见各子文档；未列入 MVP 的可标注 `// @draft`。

## 文档索引

| 文档 | 内容 |
|------|------|
| [types.md](types.md) | 数据类型 |
| [records.md](../../../lang/records.md | record、enum、view |
| [behaviors.md](behaviors.md) | 状态、动作、事件注解 |
| [expressions.md](expressions.md) | 表达式与模式匹配 |

## 参考示例

完整 Order 示例见 [records.md](../../../lang/records.md。

## 相关

- [../architect/meta-model.md](../../../lang/meta-model.md
- [../ai/vibe-spec.md](../ai/vibe-spec.md)
