# Diagram 适配器与 Graph 设计器

> 与 [plugins.md](plugins.md)、[graph-files.md](graph-files.md) 配合使用

## 0. 两层架构

| 层 | 插件扩展点 | 职责 |
|----|------------|------|
| **Graph Designer** | `graphDesigners`（API 0.2 规划） | 绑定 SSOT 类型（`.mm` 等）；语义编辑 → AST Patch；读写 `{SSOT}.g` |
| **Diagram Engine** | `diagramAdapters`（已实现） | 渲染 `GraphDocument` / `DiagramDocument`；默认 Syncfusion |

SSOT 与 `.g` 分离规则见 [graph-files.md](graph-files.md)。

## 1. 设计原则

- **SSOT**：M语言 / 项目文件是真相来源；`*.g` 仅存布局；`DiagramDocument` / `GraphDocument` 是 UI 交换格式。
- **适配器隔离**：Syncfusion、自研 Canvas、Mermaid 预览等均为可替换实现。
- **不泄漏厂商类型**：壳层（`DiagramCanvas`、`EditorArea`）只 import `@/diagram`，不 import `@syncfusion/*`。

## 2. 领域模型

`apps/architect-ui/src/diagram/model.ts`

```ts
interface DiagramDocument {
  kind: 'er' | 'stm' | 'dfd' | 'bpmn'
  nodes: DiagramNode[]
  edges: DiagramEdge[]
  meta?: Record<string, unknown>
}
```

节点含 `position`、`size`、`shape`（`rectangle` | `ellipse`）、`label` / `subtitle`、可选 `style`。

边含 `sourceId`、`targetId`、可选 `label` 与 `routing`（`orthogonal` | `straight`）。

## 3. 演示数据

`diagram/presets.ts` — mmda-mes 的 E-R / STM 示例，输出 `DiagramDocument`（非 Syncfusion JSON）。

## 4. 适配器接口

`diagram/adapter.ts`

```ts
interface DiagramAdapterDescriptor {
  id: string
  label: string
  priority?: number          // 越小越优先
  component: Component       // props: DiagramAdapterProps
}
```

注册：

```ts
ctx.registerContributions({
  diagramAdapters: [{
    id: 'my-canvas',
    label: 'My Canvas',
    priority: 10,
    component: MyDiagramPane,
  }],
})
```

`DiagramCanvas.vue` 调用 `getDefaultDiagramAdapter()` 渲染。

## 5. Syncfusion 参考实现

| 文件 | 职责 |
|------|------|
| `plugins/syncfusion-diagram/index.ts` | 插件入口，注册适配器 |
| `diagram/adapters/syncfusion/map.ts` | `DiagramDocument` → Syncfusion nodes/connectors |
| `diagram/adapters/syncfusion/SyncfusionDiagramPane.vue` | Vue 包装 `ejs-diagram` |

主题切换仅触及适配器内部（E-R 矩形填充），不污染领域模型。

## 6. 实现新引擎 checklist

1. 实现 Vue 组件，接受 `DiagramAdapterProps`
2. 在插件 `activate` 中 `registerContributions({ diagramAdapters: [...] })`
3. （可选）提供 `fromMyFormat(doc)` / `toMyFormat(doc)` 映射
4. Phase 2：实现 `DiagramDocument` ↔ M语言 双向同步

## 7. Graph Designer（规划）

设计器插件 id 建议：

| 插件 id | SSOT | graphKind |
|---------|------|-----------|
| `mmda.designer.ma-module` | `.ma` | `ma-module` |
| `mmda.designer.mm-er` | `.mm` | `mm-er` |
| `mmda.designer.ms-stm` | `.ms` | `ms-stm` |
| `mmda.designer.mf-flow` | `.mf` | `mf-flow` |
| `mmda.designer.mf-dfd` | `.mf` | `mf-dfd` |
| `mmda.designer.mf-map` | `.mf` | `mf-map` |
| `mmda.designer.mb-bpmn` | `.mb` | `mb-bpmn` |

`.mi` 使用内置 `MiUiDesigner`，无 `.g`。

## 8. 相关文档

- [graph-files.md](graph-files.md) — `*.g` JSON 与 syncRef
- [diagrams.md](diagrams.md) — 规范层 E-R / STM / DFD 语义
- [plugins.md](plugins.md) — 插件 API
