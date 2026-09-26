# Legacy 补充文档

本目录收录**早期 Java 实现与用户手册**中、新规范正文未展开的细节。  
**权威规范以 `doc/architect/`、`doc/language/`、`doc/guide/quickstart.md` 为准**；此处仅供迁移、对照与参考实现查阅。

| 文档 | 何时阅读 |
|------|----------|
| [import-from-ddl.md](import-from-ddl.md) | 从 MySQL DDL COMMENT 逆向元数据 |
| [java-factory.md](java-factory.md) | 使用 `mmda meta` / `mmda java` / `mmda vui` |
| [runtime-java.md](runtime-java.md) | Java 版 Repository、SqlBuilder、UiLogic 钩子 |

新项目实施请直接使用 `.mmda` 项目 + `mmda validate`，无需经过 `mmda_metadata` 库。

## 旧版教程对照

早期快速上手以 **HRM Employee** 为主线（`mmda meta hrm` → `mmda java/vui hrm`）。新规范等价流程见 [guide/quickstart.md](../guide/quickstart.md)（**mmda-mes** 示例）。概念（MetaObject、REF/HAS_ONE、ModuleAction）已并入 [meta-model.md](../lang/meta-model.md。
