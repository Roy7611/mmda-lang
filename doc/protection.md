# 算法与知识产权保护（Protection）

> **起因**：核心算法（例如物流调度）不能放在 Java/C# 里——`.class` / IL 带着完整元数据（方法名、字段名、字符串、类型结构），反编译工具能还原出接近源码的东西。
> **状态**：**草案（待裁）**。本文定：算法放哪、怎么加固、怎么许可、怎么举证。与 [`targets.md`](targets.md) 的 capability 机制联动、与 [`errata.md`](errata.md) 语法待裁项 11 联动。

---

## 0. 结论先给

1. **算法下沉到 native（Rust → cdylib，Java 走 Panama、C# 走 P/Invoke），集成留在宿主**——不是「把所有业务搬出 Java/C#」。
2. **真正独一份的算法再上一档：服务化**（跑在你或客户的边缘节点，宿主只调 API），这才是唯一让代码「不在对方手里」的形态。
3. **WASM 只放可公开子集**；核心算法不出 WASM。
4. **技术只防「读取」，防不住「行为探测」**——必须配许可、水印、合同；同时认清：护城河常在数据 + 约束工程 + 调参经验 + 系统耦合，而不在那几百行启发式。

---

## 1. 为什么 Java/C# 放不住算法

| 交付物 | 可读性 | 常用工具 |
| --- | --- | --- |
| Java `.jar` / `.class` | 元数据完整，方法名/字段名/字符串/异常表齐全；能重建 `switch`、lambda、泛型签名 | CFR、Procyon、JD-Core、Fernflower（IDEA 内置） |
| .NET `.dll` / IL | 元数据表完整；能重建 LINQ、`async` 状态机、属性 | ILSpy、dnSpy、dotPeek、de4dot（去混淆前置） |
| 混淆后的 IL/字节码 | 控制流平坦化、字符串加密会挡人，但**2026 年 LLM 能直接读并重建语义** | de4dot + 任意 LLM |
| native（Rust/C++/Go） | 无元数据、无类型/名字（strip 后），需要真逆向 | IDA、Ghidra、Binary Ninja |
| WASM | 结构平坦但**无名字**，可读性介于 IL 与 native 之间；有工具但链条长 | wasm2wat、wasm-decompile、Ghidra（支持 WASM） |

**用户已有的决策正好是最优解的一半**：`PLAN.md` A2 已定「Rust 单实现 + C ABI / WASM 两个面」，B5 已定 FlatBuffers —— 前者给了 native 边界，后者给了**跨语言传参**（native 边界不用再定义 DTO/IDL）。

---

## 2. 保护强度谱（每条都写清「挡住谁」）

| # | 手段 | 挡住谁 | 代价 | 定位 |
| --- | --- | --- | --- | --- |
| 1 | **native 库 + 加固**（strip 符号、`panic=abort`、常量外置、参数表加密签名） | 顺手拿 ILSpy/dnSpy 的人（≈99% 客户与竞品） | 构建链、ABI 版本管理 | **默认档** |
| 2 | **算法服务化**（独立进程/边缘节点，HTTP/gRPC/消息调用） | 所有人（代码不在对方环境） | 部署运维、离线可用性、客户对数据出域的顾虑 | **顶配档**（最独特的算法） |
| 3 | **许可绑定**（机器指纹 + 时间锁 + 在线心跳 / 加密狗） | 拷贝到别处复用、超期使用 | 集成工作量、客户体验 | 私有部署必配 |
| 4 | **AOT**（GraalVM Native Image / .NET NativeAOT） | 顺手反编译（产物是机器码） | 生态受限（反射重的栈如 Dapper 易踩坑）、仍有方法名残留 | 客户只接受 native 时 |
| 5 | **混淆 / 加固壳**（Eazfuscator、.NET Reactor、Allatori、Zelix、VMProtect、Themida） | 顺手 + 业余逆向 | 维护成本、升级易碎、仍可脱壳；对 LLM 效果衰减 | 必须留在 JVM/CLR 的部分 |
| 6 | **WASM** | 顺手（但工具链长） | 低 | **只放可公开子集** |

> 诚实提示：1–6 全是「提高读取成本」。**行为探测防不住**——对手用大量输入输出对即可逼近你的策略；对调度类算法尤其明显。所以真正的护城河要往「数据 + 约束工程 + 调参 + 耦合」上建。

---

## 3. 算法 vs 集成：边界判据

**四条判据同时满足 → 可以下沉 native；满足不了 → 留在宿主。**

1. **纯函数**：无副作用、不写库、不发消息；
2. **无 IO**：不碰网络/文件/时钟/随机（要时钟或随机必须由宿主传入种子与时间）；
3. **确定性**：同输入同输出（可重放、可对账，这条与 `doc/events.md:97-102` 的事件重放要求一致）；
4. **输入输出可序列化**：能过 FlatBuffers。

| 该下沉 native | 该留在 Java / C# |
| --- | --- |
| 物流调度（VRP/排程/装载/路径优化）、约束求解与评分、计费/定价、匹配与分配、BOM 展开与工艺计算、报表聚合、图像/信号处理 | 事务、ORM/仓储、事件总线投递、鉴权、HTTP/API、UI 渲染、消息渠道、定时与调度**触发** |

**为什么这条线划在这里**：宿主里的东西本身不是 IP，而且下沉它们会把 native 边界变宽——边界一宽，调试、版本、部署、跨端一致性全都爆炸。

---

## 4. 三端交付形态

```
Rust 算法仓（不进任何交付仓）
  crates/logistics-scheduler  ──cdylib──▶  logistics_scheduler.dll / .so
                                          + scheduler.fbs（FlatBuffers schema）
        │                                          │
        ├── Java 宿主：Panama（java.lang.foreign, JDK 21+）包装 + FlatBuffers 收发
        ├── C# 宿主：P/Invoke 包装 + FlatBuffers 收发
        └── TS 端：WASM 加载器（仅公开子集；核心调度不在此列）
```

| 宿主 | 调用方式 | 生成物 | 备注 |
| --- | --- | --- | --- |
| Java | Panama (`java.lang.foreign`)，JNI 为退路 | `LogisticsSchedulerNative.java`（薄适配 + 许可校验） | 与 `PLAN.md` §3.4 的宿主口径一致 |
| C# | P/Invoke | `LogisticsSchedulerNative.cs`（薄适配 + 许可校验） | 同上 |
| TS | WASM 加载器 | `logisticsSchedulerWasm.ts` | **只放可公开子集**（校验、换算、预览小算例） |

- **传参用 FlatBuffers**（复用 B5）：native 边界零拷贝、跨语言、无需第二套 IDL；算法契约的输入输出直接引用 m 语言里声明的 record。
- **算法仓独立**：`logistics-scheduler` 单独仓（或 `D:\2026\rust\crates\` 下的私有子模块），**不进 Java/C#/TS 三个交付仓**；交付仓里只有薄适配与 `.dll/.so` 产物。
- **薄适配必须真薄**：一个函数一个语义，不许把半个业务流程塞进 native；否则边界失控。

---

## 5. m 语言里的声明（草案语法，待裁）

### 5.1 算法契约

```sql
/// 物流调度算法（只声明契约，不实现）
algorithm LogisticsScheduler {
    input  DispatchRequest          // 引用 record
    output DispatchPlan             // 引用 record
    impl   native(abi: c, artifact: logistics_scheduler)
    protection native-stripped, license(activate: online, bind: machine-id, ttl: 30d)
    // 可选：算法可调参数（由签名配置下发，改参数要重新签发授权）
    params  costModel: json, weights: json
}
```

要点：
- `algorithm` 只描述**契约与保护档**，不描述算法体——算法体永远在 Rust 仓。
- `protection` / `license` 是**声明项**，不是模板里的散落条件（与 `targets.md` §3 的「能力矩阵是唯一开关点」同一原则）。
- `params` 让「调好的那套参数」外置并可签名：**物流调度里参数往往比算法本身值钱**。

### 5.2 在行为里引用（三种候选，待裁）

| 候选 | 写法 | 说明 |
| --- | --- | --- |
| A（推荐） | `@Action dispatch : LogisticsScheduler dispatchOrder(Order o)` | 动作直接绑定算法契约，最直白 |
| B | `@Native(LogisticsScheduler) compute dispatchPlan(...)` | 加注解标节点为 native 调用 |
| C | 状态机里 `action dispatch { native LogisticsScheduler }` | 与 `.ms` 现有形态贴近（`stm … { action … { transition … } }`） |

三种都要能回答：**输入从哪来（record/查询）、输出落到哪（字段/事件/表）、失败怎么回滚（宿主事务）**。

### 5.3 生成物清单

| 生成物 | 内容 | 保护意义 |
| --- | --- | --- |
| `XxxNative.java` / `XxxNative.cs` | 加载库、FlatBuffers 编解码、许可校验、错误码映射 | 薄到抄走无用 |
| `xxx.fbs` + 生成的 DTO | 契约的序列化定义 | 只暴露数据结构，不暴露算法 |
| 许可骨架 | 机器指纹、时间锁、心跳、宽限期策略 | 拷贝到别处即失效 |
| **不生成** | 算法实现、启发式权重、约束求解过程 | 这些只存在于 Rust 产物里 |

---

## 6. Rust 侧加固清单（配置级，可直接抄）

```toml
# Cargo.toml
[lib]
crate-type = ["cdylib"]          # 只出 C ABI

[profile.release]
panic     = "abort"              # panic 文本会泄漏源路径与分支信息
strip     = "symbols"            # 去符号表
lto       = "fat"
codegen-units = 1
debug     = false
overflow-checks = false
```

- **只导出 C ABI 的少数函数**：`#[no_mangle] pub extern "C"`，其余一律 internal；对外只暴露「一个语义一个函数」。
- **错误用错误码**，禁用 `unwrap` / `expect` 的文本泄漏；必要时 `#[cold]` 的兜底路径返回统一错误码。
- **字符串与常量混淆**：`obfstr` 或自建常量表（表名、阈值、规则名别以明文躺在 `.rodata` 里）。
- **参数外置 + 签名**：评分权重、费率、约束系数从「签名的加密配置」读入（公钥编译进 native，篡改即失效）；这样即使算法被还原，**你的调参资产仍锁在授权里**。
- **不导出调试信息**：CI 里禁用 debug 符号，构建产物做一次 `strings` 抽查（见 §9 验收）。
- **WASM 面独立裁剪**：只编译公开子集到 `wasm32`，核心调度 crate **不**加 wasm target。

---

## 7. 许可与分发

### 7.1 open core 的边界（✔ 已裁 2026-09-24，真源在 [`vision.md`](vision.md) §5.1）

| 资产 | 开源 / 闭源 | 许可 |
| --- | --- | --- |
| m 语言规范（本仓 `doc/`、`PLAN.md`） | **开源** | MIT（`LICENSE`） |
| Rust 内核 / 三端薄适配 / IDE 壳 | **开源** | Apache-2.0（含专利授权与商标条款，企业法务最容易通过） |
| 算法库（如 `logistics-scheduler`） | **闭源** | 商业许可 + 本文 §7.2 的绑定机制 |
| 行业业务包 / 模板 / SaaS | **闭源** | 商业许可 |

**三条必须记住的边界**：
1. **既有实现不随本体开源**——`D:\2026\java` 与 `D:\2026\cs\MMDA` 的版权头是 `MMDA.CLOUD PROPRIETARY/CONFIDENTIAL`（证据 `mmda-core-metadata/.../MetaDb.java:3`）；它们只作**对照与回填来源**。要把某段既有代码开源，必须逐文件确认权属与版权头。
2. **开源不削弱本文的保护策略**：开源的是**契约与内核**（换来生态、可审计、可替换），受保护的是**算法与行业知识**（§3 边界判据 + §6 加固清单 + §7.2 许可绑定）——与 §8「把保护问题转成商业问题」是同一条思路。
3. **插件市场是闭源增值内容的合法分发渠道（✔ 2026-09-24）**：行业业务包 / 模板 / 算法库以**插件**形态上架（签名 + 许可绑定，见 [`ide/plugins.md`](ide/plugins.md) §9），既保住「内核与契约开源」的承诺，又让闭源内容有明确的分发与变现路径。**市场本身不进语言层**（同文 §8 硬边界）。

### 7.2 授权形态

| 形态 | 机制 | 适用 |
| --- | --- | --- |
| 在线激活 + 心跳 | 首次指纹绑定 → 签发短期 token → 周期性心跳；宽限期后降级为「只读/停用」 | 客户允许出网 |
| 离线授权文件 | 机器指纹 + 到期时间，用私钥签名，宿主验签 | 内网隔离现场 |
| 加密狗 | 硬件授权（HASP/Sense 等） | 高价值、强合规现场 |
| 调用计量 | 按算例/时数/车辆数计费 | SaaS 或服务化 |

要点：**许可校验放在薄适配层**（三端各一份小实现），native 库只在「输入参数解密」这一步依赖授权，避免把许可做成业务代码的一部分。

---

## 8. 法务与商业（技术之外的必需项）

- **EULA/NDA 明确禁止反向工程**，并约定审计权（发现抄袭时的取证权）。
- **水印与指纹**：在产物里嵌唯一字符串/隐藏常量/编译期指纹，用于证明「抄的是你的」。
- **蜜罐常量**：故意留的独特但无害的数值/分支，被抄即可识别。
- **专利**：计算机程序相关发明（CN/US 可申请），做防御与谈判筹码。
- **计费形态**：按 licence / 调用量 / 结果质量收费，而不是卖源码——**把保护问题转成商业问题**。
- **客户形态决定强度**：SaaS / 服务化 > 私有部署给二进制 > 给源码。能做服务化的部分，别下放二进制。

---

## 9. 反面清单与验收

**不要做**：

- ❌ 把算法留在 JVM/CLR 里，只加混淆就交付（LLM 时代性价比最低）。
- ❌ 把事务、仓储、事件投递塞进 native（边界失控，收益为负）。
- ❌ 核心算法编 WASM 交付（比 native 好读）。
- ❌ 所有权重/费率硬编码在 native 里（改一次要重发包，且被还原即全失）。
- ❌ 只做技术、不做合同（发现抄袭时无凭无据）。

**验收（可执行）**：

```bash
# 1) 符号已剥离、无调试信息
nm -D --defined-only liblogistics_scheduler.so   # 只应看到极少数 C ABI 符号
strings liblogistics_scheduler.so | head -50     # 不应出现内部模块名/源路径/规则名

# 2) 算法实现不在交付仓
rg -n "启发式|heuristic|cost_model|weights" -g '!*.dll' -g '!*.so' D:/2026/java D:/2026/cs/MMDA

# 3) 未授权环境应失败
#    （拷走 .so/.dll 到另一台机器，宿主应因许可校验失败而拒绝）
```

---

## 10. 待裁清单

| # | 议题 | 选项 / 建议 |
| --- | --- | --- |
| 1 | `algorithm` 契约与 `protection` / `license` 声明是否进语言 | 建议进（与 capability 同源） |
| 2 | 行为里引用 native 的语法 | A `@Action dispatch : LogisticsScheduler …`（推荐）／ B `@Native(...)` 注解 ／ C `.ms` 里 `action { native … }` |
| 3 | 默认保护档 | 建议：native-stripped + 机器指纹在线激活，宽限期 30 天 |
| 4 | 哪些算法必须服务化 | 建议：物流调度内核服务化；其余（计费、展开）走 native 库 |
| 5 | WASM 公开子集的范围 | 建议：输入校验、单位换算、预览小算例；不含调度内核 |
| 6 | 产物与许可的分发方式（谁签发、怎么轮换密钥） | 待定 |

---

## 11. 相关

- [`targets.md`](targets.md) — 三端契约与 capability 机制（§3.1 算法宿主）
- [`contracts-inventory.md`](contracts-inventory.md) — 三端现有能力盘点
- [`statements.md`](statements.md) — `@Action` 与状态机（native 节点的落点）
- [`errata.md`](errata.md) — 语法待裁项 11（native 节点声明）
- [`..\PLAN.md`](..\PLAN.md) — A2（Rust + C ABI/WASM）、B5（FlatBuffers）是本文的前提
