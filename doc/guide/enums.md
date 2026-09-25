# 枚举（Enum）开发指南

> **面向**：建模的架构师 / 设计师 + 写业务代码的程序员。
> **真源**：语法在 [`../records.md`](../records.md) §6 / §6.1，渲染口径在 [`../presentation.md`](../presentation.md) §4.1，元数据承载在 [`../meta-model.md`](../meta-model.md) §6，裁决过程在 [`../errata.md`](../errata.md) §五-62～65。
> **实例**：[`../examples/enums/`](../examples/enums/)（`BomStatus` / `BomUsage` / `MaterialType` / `RoutingType`…）。

---

## 1. 一分钟模板（复制即用）

```sql
/// BOM状态
@Colorized(gray, 500)
@Iconized("bom")
enum BomStatus : int {
    /// 新
    @Color(info, 500)
    NEW = 0,
    /// 已起草 : 保存但未提交审核
    @Color(info, 200)
    DRAFTED = 1,
    /// 已审核
    @Color(success, 500)
    CERTIFIED = 2,
    /// 已批准
    @Color(success, 700)
    APPROVED = 4,
    /// 变更中
    @Color(warning, 500)
    REVISING = 5,
    /// 已弃用
    @Color(danger, 500)
    ABANDONED = -1,
}
```

不需要颜色 / 图标时，把两行 `@Xxxized` 与所有 `@Color` / `@Icon` 去掉即可 —— **枚举照样能用，按文本渲染**。

---

## 2. 文件与命名

| 项 | 约定 |
| --- | --- |
| 文件 | `data/enums/{模块}/{Name}.me`（一对象一文件；扩展名 `.me`） |
| 枚举名 | **PascalCase**（`BomStatus`、`RoutingType`） |
| 成员名 | **UPPER_SNAKE**（`RAW_MATERIAL`、`ABANDONED`）—— 三端一致（见 [`../naming.md`](../naming.md)） |
| 成员值 | 冒号后是底层类型：`enum X : int { … }`；位枚举写 `enum X : int flags { … }`（也见 `BitSet`） |
| 值可负 | `ABANDONED = -1` 合法（语料在用） |
| 存量不擅改 | 值一旦上线就是**历史数据的含义**，改名/改值要当作数据迁移处理 |

---

## 3. 注释规范（`///`）

**格式**：`/// <label>` 或 `/// <label> : <description>` —— 即**元数据里的显示标签与描述**（`displayLabel` / `description`）。三端 UI 标签、API 文档、`mmda doc` 生成的 Markdown 都从这里取。

**位置**：**写在被注释元素上方、独占一行**（枚举声明上方 = 枚举的标签；成员上方 = 成员的标签）；有 `@` 注解行时 `///` 在注解行**之上**。

```sql
/// BOM状态                      ← 枚举的显示标签
@Colorized(gray, 500)
@Iconized("bom")
enum BomStatus : int {
    /// 已起草 : 保存但未提交审核   ← 成员的显示标签 + 描述
    DRAFTED = 1,
}
```

- **不许写行尾**：`DRAFTED = 1,  /// 已起草` 不是规范写法（旧语料里大量如此，见 §11 迁移）。
- **i18n**：`///` 是**翻译对象**（标签 / 描述可多语言）；颜色与图标**不翻译**（见 §12）。

---

## 4. 值域与位枚举

- **普通枚举**：值连续或留空档都行（`NEW = 0, DRAFTED = 1, CERTIFIED = 2, APPROVED = 4…`）。
- **位枚举**（`flags`）：成员值取 2 的幂（`1 = 1`、`2 = 2`、`4 = 4`、`8 = 8`…），可组合，如 `MaterialType`（劳动技能 / 原材料 / 零配件 / 半成品 / 产成品 / 机具设备 / 耗材 / 办公用品 / 其他）。
- **文本存储**：`0;NEW;新|1;PAYED;已付款`（生成物与旧实现兼容的形态，语言文件是唯一真源）。
- **值域说明**：字段上引用枚举时，旧写法会在字段注释里带一串 `0;CODE;标签|…`；新模型不必重复枚举的内容（枚举本身就是真源）。

---

## 5. 挂到记录与状态机上

```sql
record Bom {
    /// 状态
    @State BomApproval                    // 指向状态机
    status BomStatus default 0 indexed readonly,
}

// data/stms/mes/BomApproval.ms
/// BOM 审批流
stm BomApproval on Bom.status {
    /// 审核
    action approve {
        transition CERTIFIED->APPROVED,
    }
    /// 弃用
    action abandon {
        transition *->ABANDONED,
    }
}
```

- `@State <Stm>` 绑在**枚举字段**上；`transition A,B->C,` 里 `*` = 任意状态。
- 枚举做「值域」，状态机做「怎么走」—— **一概念一主人**，别把流程塞进枚举。

---

## 6. 外观之一：颜色

**开关 + 默认色**写在**枚举声明**上，**取值 / 覆盖**写在**成员**上。

| 位置 | 写法 | 含义 |
| --- | --- | --- |
| 声明 | `@Colorized` | 只开颜色（成员各自写 `@Color`，不写就不上色） |
| 声明 | `@Colorized(role, shade?)` | 开颜色 + **默认色**：成员没写 `@Color` 时**回落**到它 |
| 成员 | `@Color(role, shade?)` | 覆盖默认色（`@Color(warning, 500)`） |

**角色（封闭 7 值）**：`primary` / `secondary` / `info` / `success` / `warning` / `danger` / **`gray`**。

- `gray` 是**默认支持**的中性色 —— 黑白灰都走它（`gray-50` 近白 → `gray-900` 近黑），不必在主题里另配。
- 拼错 / 不认识的角色 = **解析期 error**（不是 warning，不会静默通过）。

**shade（封闭 10 档）**：`50` / `100` / `200` / `300` / `400` / `500` / `600` / `700` / `800` / `900`。

- 语义：`500` = **基准档**（省略 shade 时的默认值）、`200` = 浅档、`700` = 深档。
- **省略 shade = `500`**；写 `250` 这种非档位值 = **error**。

**两条硬规矩**：

1. **只给角色与 shade，不给色值** —— 具体颜色来自**主题令牌**（Material Design + Theme Builder），深浅色与皮肤切换由主题层负责；模型层**不写 `#RRGGBB`**。
2. **业务里的「每行一个颜色」不是这件事** —— 如 `taskColor varchar(7)`、`bankColor` 是**数据**；`@Color` 是**呈现语义**。两者不互相替代。

---

## 7. 外观之二：图标

| 位置 | 写法 | 含义 |
| --- | --- | --- |
| 声明 | `@Iconized`（**不写括号**） | 开图标 + **默认别名取成员名**（`DESIGN` → `design`） |
| 声明 | `@Iconized("bom")` | 开图标 + **默认别名 = 前缀 + 成员名**（`DESIGN` → `bom-design`） |
| 成员 | `@Icon("alias")` | 该成员的图标 —— **完整别名**（写什么就是什么） |

**别名规则**：

1. **成员名 → 别名 = kebab-case**：`DESIGN` → `design`；`RAW_MATERIAL` → `raw-material`。
2. **加前缀只在默认时发生**：`@Iconized("bom")` + 成员 `DESIGN` **不写** `@Icon` → `bom-design`；一旦**显式写了** `@Icon("design")` → 别名就是 **`design`**（**不再叠前缀**，避免拼出双重前缀）。
3. **别名是开放的**：语义词由**开发人员自己定义**（`bom-design`、`cancel`、`my-icon`…），语言层**不内置清单、不进关键字表**，只校验「它是个字符串」。
4. **映射在 UI 层**（主题 / 皮肤）：同一个别名在三端各自映射（TS / Syncfusion `e-icons`、C# / FontAwesome、Flutter / Material Icons）；**模型层不写 `fas fa-x`**。
5. **没映射上 = 顶多不显示**：不报错、不阻塞生成；UI 层或 IDE **可以**给 warning / lint 作提醒（可选）。

---

## 8. 一句话看懂「谁生效」

```
声明：@Colorized(gray, 500)   →  默认色 = gray-500
      @Iconized("bom")        →  默认图标 = bom-<成员名 kebab>

成员：写 @Color / @Icon  →  用写的（@Icon 是完整别名）
      不写               →  回落到声明的默认值
      没有默认值又不写    →  该项不渲染（不报错）
```

| 场景 | 结果 |
| --- | --- |
| 成员写 `@Color(danger, 500)` | 该成员 = `danger-500` |
| 成员不写 `@Color`，声明有 `@Colorized(gray, 500)` | `gray-500` |
| 成员不写 `@Color`，声明只有 `@Colorized`（无默认色） | **不上色** |
| 成员写 `@Icon("cancel")` | 图标别名 = `cancel` |
| 成员不写 `@Icon`，声明 `@Iconized("bom")`，成员名 `REVISING` | `bom-revising` |
| 成员不写 `@Icon`，声明只有 `@Iconized` | `revising` |
| 没开开关（无 `@Xxxized`） | 按**文本**渲染，成员上的 `@Color` / `@Icon` 不生效（写 = warning） |

---

## 9. 自检清单（提交前）

- [ ] 每个成员的 `///` 都在**上一行**，格式 `label` 或 `label : description`
- [ ] 成员名 UPPER_SNAKE；值域固定、没随手改老值
- [ ] 用状态就用 `@State` + `.ms` 状态机，别把流程写进枚举名
- [ ] 开颜色：角色在 7 值内、shade 在 10 档内（或省略 = 500）
- [ ] 开图标：默认别名形态选一种（无前缀 / 带前缀），**写了 `@Icon` 就当完整别名**
- [ ] 枚举的显示标签 `///` 写了（三端 UI 与 md 文档都靠它）
- [ ] `mmda check` 无 error（角色拼错、shade 越档、一对象多 `partitioned` 之类的硬门禁都会拦）

**`mmda check` 的级别**（枚举相关）：

| 情况 | 级别 |
| --- | --- |
| 颜色角色拼错 / 不认识 | **error**（解析期） |
| shade 不在 10 档内 | **error** |
| 没开开关却写 `@Color` / `@Icon` | **warning** |
| 开了开关但该成员没值、也没有默认值 | 不告警（**该项不渲染**） |
| 图标别名 UI 层没映射 | 可选 warning（语言层不管） |

---

## 10. 常见坑

| 坑 | 正确做法 |
| --- | --- |
| `DRAFTED = 1,  /// 已起草`（行尾注释） | 注释移到**成员上一行**（旧语料待迁移，见 §11） |
| 写 `@Iconized(default)` | 那个形态已作废 —— **不写括号**的 `@Iconized` 就是「默认取成员名」 |
| 以为 `@Icon("design")` 会拼成 `bom-design` | `@Icon` 写的是**完整别名**；要前缀效果就**别写** `@Icon` |
| 只写 `@Colorized`（无默认色）却指望成员都有色 | 要么给默认色 `@Colorized(role, shade)`，要么每个成员写 `@Color` |
| 把业务色写进注解（`@Color(primary, "#FF0000")`） | 注解只接受**角色 + shade**；具体色值归主题 |
| 用 `@ColorRole(role)`（旧写法） | 改成 `@Color(role, shade?)` |
| 想让颜色/图标进多语言 | 颜色 / 图标**不翻译**；要翻译的是 `///` 的标签与描述 |
| 给 `gray` 之外再自造角色（如 `brand`） | 角色集合**封闭 7 值**；要特殊色走主题皮肤变量 |

---

## 11. 迁移旧项目

| 旧 | 新 | 说明 |
| --- | --- | --- |
| 行尾成员注释 `NEW = 0,  /// 新` | 注释移到成员上一行 | 语料里大量存在（示例集 7 个 `.me` 就有 33 处）；可走 `mmda migrate` |
| `@PartitionID` | `@Partitioned` | 与枚举无关但同批迁移（见 `errata` §五-56） |
| `@ColorRole(role)` | `@Color(role, shade?)` | 一概念一主人 |
| `@Iconized(default)` | `@Iconized` | 不写括号 |
| 旧实现无颜色 / 图标列 | 生成期新增 `MetaEnum.colorized` / `color` / `iconized` / `iconPrefix` 与成员 `color` / `icon` | `toString()` 串保持**老 3 段兼容**；只有用了外观注解的枚举才追加 `color` / `icon` 两段 |

---

## 12. 三端落地与元数据

| 层 | 做什么 |
| --- | --- |
| 语言文件（真源） | `data/enums/**/*.me` |
| 元数据（产物） | `MetaEnum`（内存模型，`toJson()`/`fromJson()`、`toString()`/`fromString()`）：`colorized` / `color` / `iconized` / `iconPrefix`；`MetaEnumMember`：`color` / `icon` |
| 前端（TS，**唯一渲染方**） | 消费 `MetaEnum` 渲染：角色 + shade → 主题令牌；别名 → 图标；缺注解 → 文本 |
| C# / Flutter | 同一份元数据，各自映射图标库（FontAwesome / Material Icons） |
| i18n | `///` 标签与描述可翻译；颜色 / 图标不翻译 |
| 文档出口 | `mmda doc` 生成的 Markdown 里，枚举按成员表输出（标签 + 角色 + shade + 别名） |

---

## 13. 字符串表示与元数据 JSON

> 两者都是**产物**（语言文件才是真源）。`MetaEnum` 是**内存模型**，只有两条通道：**字符串**（`toString()` / `fromString()`）与 **JSON**（`toJson()` / `fromJson()`）。
> **`color` 只有一个形态**：`<role>` 或 `<role>-<shade>` —— `info` / `info-500`；注解里写两个参数（`@Color(info, 500)`），串与 JSON 里写一段。规范条文见 [`../meta-model.md`](../meta-model.md) §6.1 / §6.2。

### 13.1 字符串表示（`toString()` / `fromString()`）

**老格式**（旧实现，只到这里）：

```
0;NEW;新|1;PAYED;已付款
```

**扩展格式**（**末尾追加 2 段，前 3 段含义与顺序不变**）：

| 段 | 名 | 说明 |
| --- | --- | --- |
| 1 | `value` | 整数（位枚举为位值） |
| 2 | `name` | 成员名 |
| 3 | `text` | 显示标签（`///`） |
| 4 | `color` | **`<role>` 或 `<role>-<shade>`**（`info` / `info-500`） |
| 5 | `icon` | 图标别名（**完整别名**） |

```text
0;NEW;新;info-500;bom-new          ← 有色有图标
1;DRAFTED;已起草;info-200          ← 有色（200）、无图标（尾随空段可省）
2;CERTIFIED;已审核;;bom-verified   ← 只有图标（空段占位）
5;ABANDONED;已弃用                 ← 都没有 → 与老格式逐字一致
```

- **颜色段** `info-500` = 角色 + shade（`-` 连接）；只写角色 `info` = 省略 shade（按 `500`）；只写 `-500`、角色拼错、shade 不在 10 档 → error。
- **空段 = 未声明**，按枚举级默认回落；**段内禁止 `;` 与 `|`**（`mmda check` error）。
- **不用外观注解的枚举，串一个字节都不变** —— 老项目零影响。

> ⚠️ **必须知道**：老运行时按 `split(';', 3)` 解析（`MetaEnumMember.parse()`，新库 `MetaEnumMember.java:69`），**第 3 段会吞掉后面所有内容** —— 老运行时读扩展串会把标签读成 `新;info-500;bom-new`（静默错标）。
> 所以：扩展段**只在用了外观注解时**产出；**同一份元数据必须与同一代内核/运行时配套**（元数据是产物，随内核重生成）；要回退老格式用 `mmda migrate --drop-enum-style`。

### 13.2 JSON（`toJson()` / `fromJson()`）

```json
{
  "name": "BomStatus",
  "displayLabel": "BOM状态",
  "baseType": "int",
  "bitwise": false,
  "colorized": true,
  "color": "gray-500",
  "iconized": true,
  "iconPrefix": "bom",
  "members": [
    { "value": 0, "name": "NEW",       "text": "新",     "color": "info-500",    "icon": "bom-new" },
    { "value": 1, "name": "DRAFTED",   "text": "已起草", "color": "info-200",    "icon": "bom-drafted" },
    { "value": 2, "name": "CERTIFIED", "text": "已审核", "color": "success-500", "icon": "bom-certified" },
    { "value": 5, "name": "ABANDONED", "text": "已弃用", "color": "gray-500",    "icon": "bom-abandoned" }
  ]
}
```

- **JSON 里没有 `enumString` 字段** —— 旧实现的那个列就是 `toString()` 的结果；成员信息由 `members[]` 承载。
- **`toString()` 存原始、JSON 存最终**：串里没声明就是空，`members[]` 一律回落后的完整值（色写全 `<role>-<shade>`）。
- **外观随 `MetaEnum` 下发一次，不进业务数据**：记录里枚举字段照旧是成员名（`"status": "CERTIFIED"`）+ `customProperties.$status` 显示标签。

## 14. 实例索引

| 文件 | 看点 |
| --- | --- |
| [`../examples/enums/BomStatus.me`](../examples/enums/BomStatus.me) | 状态枚举（值可负、`ABANDONED = -1`） |
| [`../examples/enums/BomUsage.me`](../examples/enums/BomUsage.me) | **作者手写样例**：`@Iconized("bom")` 前缀形态 |
| [`../examples/enums/MaterialType.me`](../examples/enums/MaterialType.me) | 位枚举（2 的幂值域） |
| [`../examples/enums/RoutingType.me`](../examples/enums/RoutingType.me) | 最小枚举 + `stms/RoutingLifecycle.ms` |
| [`../examples/stms/`](../examples/stms/) | 状态机写法 |

> ⚠️ 示例集取自**语料**（`mmda-mes`），只做了 `@PartitionID` → `@Partitioned` 的规范化；**颜色 / 图标注解在语料里还没有**，示例集 §3.1 里给的是演示写法。

---

## 15. 相关

- [`../records.md`](../records.md) §6 / §6.1 —— 枚举与呈现注解的**规范条文**
- [`../presentation.md`](../presentation.md) §4.1 —— **渲染口径**（角色 → 主题令牌、别名 → 三端映射）
- [`../meta-model.md`](../meta-model.md) §6 —— 元数据属性
- [`../statements.md`](../statements.md) —— 行为与状态机
- [`../naming.md`](../naming.md) —— 命名约定（Pascal / UPPER_SNAKE / kebab）
- [`../errata.md`](../errata.md) §五-62～65 —— 这几条口径的裁决记录
- [`quickstart.md`](quickstart.md) —— 整个体系的上手入口
