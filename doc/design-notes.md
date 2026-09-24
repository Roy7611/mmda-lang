# 架构师怎么干活？

> UI 六步导航与壳层映射见 [doc/ide/workflow.md](ide/workflow.md)。第 4 步 **流程架构** 内顺序：**角色权限 → 数据流/STM → 工作流（BPMN）**；第 5 步 **交互设计** 在三类架构之上定制视图。

假设他已经明确了需求，则根据需求设计业务架构、数据架构

## 业务架构设计

1. 进行功能模块分解，主要是创建系统菜单树，例如一级菜单为系统本身，二级菜单是模块，三级菜单是功能特征；
2. MMDA-Architect工具提供树形菜单设计工具；
3. MMDA-Architect工具提供功能架构图设计工具，功能架构分层展示，使用圆角矩形表示模块，内部的矩形表示功能特征。整个图代表系统；

功能架构站在业务的角度，设计出用户需要的功能板块，但还是没有告诉用户怎样的工作流程。默认情况下模块的编码排序了，也是用户使用系统完成业务管理的顺序，从上到下。例如一个人力资源系统有如下的功能模块：

* H 人力资源
  * H.01 招聘管理
  * H.02 组织人事
    * H.02.001 部门
    * H.02.002 岗位
    * H.02.003 职员
    * More Features...
  * H.03 考勤管理
  * H.04 培训管理
  * H.05 薪酬福利
  * H.06 绩效考核

上面的菜单也可以使用功能架构图表示，图中有6大模块方框图，每个模块方框内部有功能特征方框，例如组织人事框内有部门、岗位、职员、劳动合同等等。

所以功能架构设计可以切换两种视图：菜单树 / 架构图，根据设计师偏好。点击功能模块，在右边的属性面板都可以查看、编辑其属性，下面是一个模块的定义：

```ts
/**
     sops允许的标准操作，是一个位元枚举： 0;NONE;无|1;READ;读取|2;EDIT;编辑|4;CREATE;创建|8;DELETE;删除|15;CRUD;增删改查|16;REPORT;报告|32;IMPORT;批量导入|64;EXPORT;批量导出|127;ALL;所有

    注释解析为 title: description
 */

/// 人力资源: 企业人才的选用预留
module Hr  //app name
{
    id: 'H',
    icon: 'fas fa-sitemap fa-fw',
    sops: READ,                 //READ说明有Overview的看板，如果NONE表示没有UI
    model: HrDashboardModel,
    ui: {
        index: HrDashboard
    }
    version: 1,
    releaseAt: '2026-01-31 10:00:00'
}

/// 招聘管理: 人才库、面试、工作邀约、录用 
module Hr.Recruitment //module Uri /Hr/Recruitment
{
    id: 'H.01', //模块的编码，原来的moduleCode
    icon: 'fas fa-sitemap fa-fw',   
    sops: READ, 
    model: RecruitmentDashboardModel,
    // actions: [ //定义模块有哪些操作
    //     /// 报告：自动向招聘专员汇报当月招聘工作成果 #(name: description)
    //     action report //actionId=H.01:report
    //     {
    //         icon: 'fas fa-report',  //显示图标
    //         type: ActionType.SERVICE_TASK, //enum ActionType：0;USER_TASK;用户任务|1;SERVICE_TASK;服务任务|2;DECISION;自动判断
    //         hint: , //enum UiHint：：0;INFO;信息|1;SUCCESS;成功|2;WARNING;警告|4;DANGER;危险 
    //         ownerOnly: false,

    //     }
    // ], 
    version: 0,
    releaseAt: '2026-01-31 10:00:00'
}

/// 面试: 面试的预约、执行和结果评价
module Hr.Recruitment.Interview
{
    id: 'H.01.001',         //编码，原来的moduleCode
    icon: 'fas fa-view',    //图标，由前端解析，使用字体图标，原来的moduleIcon
    label: "面试",          //显示文本
    sops: CURD | PRINT,     //标准操作，allowOps => standard ops
    model: Interview,       //数据模型，原来的objName，现在改为引用元对象record
    ui: {                   //自定义用户界面，默认框架自动根据元数据生成，你就无需提供
        index: InterviewList,       //定制的列表页，查询、删除、打印、导入和导出功能
        editor: InterviewEditor,    //定制的编辑器，用于创建和编辑
        details: InterviewDetails,  //定制的详情页，用于查看一个面试的详情，单个记录打印
        search: InterviewSearch,    //定制的高级查询页
        report: InterviewReport,    //定制的报表页
    },
    description: "面试的预约、执行和结果评价",  //描述
    version: 0,                         //版本号
    releaseAt: '2026-01-31 10:00:00'    //发布时间
}
```

模块设置了model后，使用model的状态转换图。即数据和行为分开定义，不在应用、模块和功能中直接定义。

## 数据架构设计

一开始设计功能架构的时候，可以连带着创建`model`，即一个数据模型，在MMDA-Architect中称为元对象。它在代码层长这样：

```sql
/// 订单
record Order : IAuthorizable {
    /// 订单ID
    /// 订单唯一标识
    orderId uint64 identity generated, //identity默认indexed

    /// 订单日期: 指下单日期
    orderDate date default now indexed future,

    /// 订单号
    orderNo varchar(15) charset ascii unique,   //unique隐含indexed

    /// 客户:下单的客户
    @One Partner as customer // 简写：按 Partner 主键引用，显示遵循 Partner 的 @Name/@Thumbnail 定义
    customerId bigint indexed, 
    
    /// 订单状态
    @State OrderStatusChanged       //定义状态转换机
    status OrderStatus default 0 indexed,  //枚举

    /// 订单行: 默认 lazy；列表需预加载子表时可 @Many eager
    @Many
    items OrderItem[+] readonly,

    /// 订单金额
    @Computed sum(amount of each items)         // 计算字段使用表达式定义公式
    totalAmount decimal?(19,4) positive, //check if > 0
    
    /// 已支付金额
    payedAmount decimal?(19,4) unsigned,

    /// 付款单号
    paymentNo varchar?(64),

    /// 创建人
    @Ref User(userId,userName) //仅仅为了显示userName
    creatorId bigint readonly, //readonly 定义用户不能修改

    /// 创建时间
    createdAt timestamp default now readonly,

    //限制:包括主键,外键,索引,约束
}; 

### 字段定义（Field）

每条字段（含 `@Many` 集合字段）语法：

```sql
[annotations]
name dataType constraints,
```

- 以**字段名**开头，接着**数据类型**，再跟零个或多个**限制**关键字，行末以英文逗号 `,` 结束。
- 字段名**上方**可有多行注解（`@One`、`@Ref`、`@State`、`@Computed`、语义字段等），见下节。
- 数据类型可带 `?` 后缀表示可空；未写 `default` 时，可空字段默认值为 `null`，非空字段由类型决定。

| 限制 | 含义 |
|------|------|
| `indexed` | 建立索引 |
| `unique` | 唯一索引（隐含 `indexed`） |
| `identity` | 唯一标识；等价于 `indexed` + `unique`（通常不再重复写 `indexed`） |
| `default` *value* | 默认值；`now` 表示当前时间 |
| `charset` *name* | 字符编码，如 `ascii`、`utf` |
| `unsigned` | 无符号数值 |
| `positive` | 正数，必须 &gt; 0 |
| `negative` | 负数，必须 &lt; 0 |
| `future` | 日期型：值 &gt;= now |
| `past` | 日期型：值 &lt;= now |
| `readonly` | 用户不可修改；`@Computed` 与 `generated` 字段恒为只读 |
| `generated` | 生成列（如数据库自增）；`@Computed` 公式可生成 SQL 表达式 |
| `hidden` | UI 隐藏，用户不可见（如子表父键 `orderId`）；关联字段为 `hidden` 时，对应 `@One` 导航**默认 lazy**（非 eager），因无需展示 |

**`@Many` 集合**：`@Many` 单独一行，下一行声明集合属性，类型为 `子实体[]` / `子实体[+]` / `子实体[*]`：

| 写法 | 基数 |
|------|------|
| `items OrderItem[]` | 0~n（默认 `*`，方括号内可省略） |
| `items OrderItem[*]` | 0~n（显式） |
| `items OrderItem[+]` | 1~n（至少一条） |

### 对象约束（Object constraints）

Record 体末尾可声明**对象级**主键、索引与检查约束（会生成实际数据库对象）：

| 注解 | 含义 |
|------|------|
| `@Id (col1,col2,…)` | 组合主键；未命名时默认 `ID_{RecordName}`。单字段主键用字段 `identity` 即可 |
| `@Index name(cols…)` | 命名索引（落库）；唯一索引加后缀 `unique` |
| `@ForeignKey FK_…(localCols) ref Entity(refCols)` | 外键；多列关联时在对象级声明，可选 `on update cascade` / `on delete set null` 等 |
| `@Check CHK_name(expr)` | 检查约束；MMDA 布尔表达式 |

**存储级唯一索引**写为 `@Index IDX_…(cols) unique`，**不要**使用对象级 `@Unique name(…)`——字段 `@Unique` 仅表示业务层分区内唯一（与 `@Name` 同级），不影响底层存储。

**数据库对象命名**（逆向自 `information_schema`，元库未全部建模）：

| 前缀 | 对象 | M 语言 |
|------|------|--------|
| `PK_` | 主键 | `@Id PK_tablename(cols…)` 或 `@Id (cols…)` |
| `FK_` | 外键 | `@ForeignKey FK_…(cols) ref Entity(cols)`（可选 `on update` / `on delete`） |
| `IDX_` | 索引 | `@Index IDX_…(cols)` / `… unique` |
| `CHK_` | 检查约束 | `@Check CHK_…(expr)` |
| `PROC_` | 存储过程 | （待扩展） |
| `FUN_` | 函数 | （待扩展） |
| `TRG_` | 触发器 | （待扩展） |

字段级 `indexed` / `unique` 用于单列；多列组合索引用 `@Index`。

### 字段注解（Annotation）

实体关系、状态与计算字段通过 **字段上方** 的注解声明，紧接其后的字段行定义外键或集合属性：

| 注解 | 语义 | 示例 |
|------|------|------|
| `@One` | 一对一（has one），引用整个实体并生成导航属性 | `@One Partner as customer`（简写）或 `@One Partner(partnerId,partnerCode,partnerName) as customer`（显式显示列） |
| `@Many` | 一对多（has many） | `@Many` + `items OrderItem[+]` 或 `items OrderItem[]` |
| `@Ref` | 引用外键，仅用于显示关联对象的部分字段，**不**生成导航实体 | `@Ref User(userId,userName)` → 只存 `creatorId`，UI 可显示用户名 |
| `@State` | 状态字段，后接状态机名；字段须为枚举，**default** 为初始状态 | `@State OrderStatusChanged` + `status OrderStatus default 0` |
| `@Computed` | 计算字段，后接公式 | `@Computed sum(amount of each items)` |

**关联字段列表**（`@One` / `@Ref` 共用）：`Entity(col1,col2,…)` 中 **第一个字段为对方主键**（与本 record 外键列 join），**后续字段为 UI 显示列**。

**`@One` 简写**：`@One Partner as customer` 表示通过 `Partner` 的主键 `partnerId` 引用，列表/链接等显示遵循 `Partner` 上 `@Name`、`@Thumbnail` 等语义字段定义，无需重复列出显示列。需要覆盖默认显示时可写完整括号形式。

**加载策略**：`@One` / `@Many` / `@Ref` 注解行尾可加 `eager` 或 `lazy`；数据访问层据此加载关联。默认值：

| 注解 | 默认 | 说明 |
|------|------|------|
| `@One` | **eager** | 外键字段带 `hidden` 时默认 **lazy**（无需展示） |
| `@Many` | **lazy** | 子表集合按需加载；需预取时写 `@Many eager` |
| `@Ref` | **eager** | 显示列通常随主记录加载 |

示例：`@One Partner as customer eager`、`@Many eager`、`@Ref User(userId,userName) lazy`。

`@One` 与 `@Ref` 的区别：`@One` 在架构层声明导航属性（如 `Order.customer`），加载整个实体。`@Ref` 不暴露导航对象，仅外键 + 显示列。

**一对多双向导航**：主表 `Order` 用 `@Many items OrderItem[+]` 声明子表集合；子表 `OrderItem` 用 `@One Order` + `orderId` 回指父表。关联条件为 `Order.orderId = OrderItem.orderId`（主表主键 = 子表外键列）。单列外键通常由子表 `@One` 表达，逆向工具不再重复输出 `@ForeignKey`；多列外键无字段级 `@One`/`@Ref` 可覆盖，须在对象级写 `@ForeignKey`。

**多列外键示例**（仓位 + 托盘）：

```sql
/// 仓位: 仓库中可存储货物的一个物理位置
record WarehouseLoc {
    @Ref Warehouse(whId, whName)
    whId long,
    locCode varchar(6),
    @Id PK_warehouseloc(whId, locCode),
};

/// 托盘
record Pallet {
    palletId bigid identity,
    palletCode varchar(30),
    whId? long,
    locCode varchar?(6),
    @ForeignKey FK_Pallet_WarehouseLoc(whId, locCode) ref WarehouseLoc(whId, locCode) on update cascade on delete set null,
};
```

子表上各外键列仍按普通字段定义；`@ForeignKey` 声明列组合与引用目标的组合主键/唯一键一致，并映射数据库 `FK_` 约束及 referential action。

### 实体语义字段（Partner 等）

除关系注解外，实体可声明**语义字段**，驱动多租户 ID、编码唯一、默认显示名与列表缩略图：

| 注解 | 语义 | MetaCol 映射 | 约束 |
|------|------|--------------|------|
| `@PartitionID range` | `MetaObject.partitionKey` + `minID` / `maxID` | 分区主键 realId 范围（见下） |
| `@Unique` | 分区内业务唯一编码/单号（校验，非 DB `unique index`） | `uniqueKey` | 通常一条/实体 |
| `@Name` | 默认显示名；列表超链接等 | `nameCol` | 可多个 |
| `@Thumbnail` | 缩略图 URL；列表中显示在名称前 | `thumbnailCol` | 仅一个 |

**`@PartitionID` 范围语法**（映射 `MetaObject.partitionKey`、`minID`、`maxID`；`min`/`max` 可省略，表示该字段数据类型的默认最小/最大值）：

| 写法 | 含义 |
|------|------|
| `[min,max]` | 闭区间，两端包含 |
| `(min,max)` | 开区间 |
| `(min,max]` / `[min,max)` | 半开半闭 |
| `[min..max]` / `(min..max]` | 用 `..` 分隔；可省略一侧 |
| `[..max]` | 下限为类型默认最小值 |
| `[min..]` | 上限为类型默认最大值 |
| `(0..]` | 大于 0，小于等于默认最大值 |

示例：`(0..]`、`[..0x000F_FFFF]`、`[10000,0x000F_FFFF]`。

示例（`Partner`）：

```sql
/// 贸易伙伴: 与租户有贸易往来的实体，包括客户、供应商、承运商等
record Partner {
    /// 伙伴ID: 贸易伙伴唯一标识
    @PartitionID [0x800000,0x7fffffff]
    partnerId bigint identity,

    /// 伙伴编码: 贸易伙伴唯一编码（租户内）
    @Unique
    partnerCode varchar(15) charset ascii indexed,

    /// 伙伴名称: 贸易伙伴的法人全称
    @Name
    partnerName nvarchar(100),

    /// 伙伴Logo: 贸易伙伴的公司Logo
    @Thumbnail
    partnerLogo string?,
}
```

Legacy 元库 `enumSet` 中的 `HAS_ONE` / `REF` DSL 在逆向工程时分别映射为 `@One` / `@Ref`。


/// 订单状态
enum OrderStatus : int {
    /// 新
    NEW=0,              //类似常数的定义,比Java简单
    
    /// 已付款
    PAYED=1,
    
    /// 发货中
    DELIVERING=2,

    /// 已收货
    DELIVERED=3,

    /// 已取消
    CANCELED=4,

    /// 退款中
    REFUNDING = 5,

    /// 已退款
    REFUNDED = 6
};

/// 订单项: 客户购买的商品，包含品类、数量、单价和金额等
record OrderItem {
    /// 订单ID: hidden 外键 → @One 默认 lazy（可显式标注）
    @One Order lazy
    orderId bigint hidden,

    /// 项次: 行号从1开始
    itemId uint32,

    /// 物料
    @One Material(materialId,materialCode,materialName) as material
    materialId ulong indexed,

    /// 赠品否
    gift bool default false,

    /// 数量
    quantity decimal(18,3) positive,

    /// 单位
    unit varchar(10),

    /// 单价
    price decimal(18,4) unsigned,

    /// 金额: 数量*单价
    @Computed quantity*price
    amount decimal(19,4),

    /// 主键
    @Id PK_orderitem(orderId,itemId),

    /// 索引
    @Index IDX_OrderItem_mat(materialId,unit),

    /// 唯一索引：订单中不存在相同物料的两行
    @Index IDX_OrderItem_mat(orderId,materialId) unique,
    /// 礼物价格为0，商品价格必须大于0
    @Check CHK_gift_check(gift switch{ 1 -> price == 0, _ -> price > 0}),
};
```

注意，功能模块类似json数据。而元数据模型类似数据库表和编程语言的类定义。我希望在设计工具的左边面板中分目录显示为一颗树，其中`人力资源`作为面板标题：

* 业务架构：在此目录下设计功能菜单，并引用数据架构下的对象、交互设计下的 UI
  * 招聘管理
    * 人才库
    * 面试：设计面试功能(Feature)，关联的数据模型、交互设计（5种标准UI自定义视图），打开关联数据架构下面的对象设计视图，可再打开对象模型关联的交互设计视图。
  * 组织人事
    * 部门
    * 职员
    * 劳动合同
    * More...
  * 考勤管理
  * 培训管理
  * 薪酬管理
  * 绩效管理
* 数据架构
  * 枚举：列出所有枚举，可打开枚举设计器，如果枚举是状态枚举（@State注解的枚举），可打开相应的状态转换机设计器。
  * 对象
    * Department（部门）
    * Employee（职员）
    * Interview（面试）：可针对一个对象设计字段、关系、枚举、状态转换机。
    * More...
* 流程架构
  * 角色权限：定义 `role` / `auth` / `scope`（流程架构的第一步，再设计 STM 与工作流）
  * 数据流：定义不同模块功能数据对象之间的数据转换、传递。
  * 工作流：定义用户要完成一件事情的标准工作步骤（SOP）,采用`BPMN`规范绘制流程图。单个对象的工作流我们采用状态转换机（STM），在数据对象中设计状态转换图。而更高层的工作流，使用工作流程图来设计，例如客户下完订单，系统应有什么活动（Activity）来相应，例如发送邮件，然后通知仓库安排发货等等。
* 交互设计
  * InterviewEditor 是一个定制化的面试编辑器界面设计，被面试（Interview）使用
  * More...

### 状态转换机（STM）

1. 状态（States）我们用枚举来定义，加`@State`注解
2. 事件（Events）是在触发状态转换的源或因为状态转换又触发的消息
3. 转换（Transitions）描述状态之间的转换规则，通常与特定事件关联
4. 动作（Actions）：在状态转换过程中执行的操作或行为

例如下面的程序`stm`开头定义状态转换机`OrderStatusChanged`，上下文是Order，状态是status，它必须是一个枚举（enum OrderStatus）。文档注释作为状态机的名称和描述（name: description）

状态字段的默认值作为初始状态，因此我们就无需重复定义init state，但是枚举没有定义终态，因此在状态机的描述中可指定。

我们以`action`为中心来定义状态（Order.status）的转换（transition）规则。

```sql
/// 订单状态转移：付款、取消、退货等
stm OrderStatusChanged on Order.status 
{
    /**
     支持状态分组定义
    **/

    /// 执行中: 已支付,发货中
    states EXECUTING[PAYED,DELIVERING],
    /// 订单终止: 用户取消，退款
    states TERMINATED[CANCELED,REFUNDED]

    /**
     支持事件声明，程序员可以面向事件编程，用户可以订阅事件消息做出响应处理
    **/
    event OrderPayed,
    event OrderExpired TimerEvent,  //定时器事件
    event OrderRefundRequest,
    event OrderRefunded,

    /// 付款:给新订单付款
    @Transactional              //注解必须在一个事务中
    action pay {                //付款是一个人工使用系统的任务（UserTask）
        entry beforePay,        //beforeAction检查条件是否具备，若不具备则抛出异常

        //execute 干什么由程序员编写，状态的更改和退出事件自动生成代码
        //每个action有上下文，此处是Order对象，带有原状态

        transition NEW->PAYED,  //状态转换，支持switch语句的条件转换

        exit OrderPayed,  //退出事件，携带Order实体数据上下文，数据回写在此中完成
    },

    /// 取消:用户取消或者后台自动取消未付款超时订单
    action cancel {
        entry beforeCancel,             //检查是否能取消
        transition NEW->CANCELED end,   //转换到终态,*->CANCELED代表不检查原来状态
    } on OrderExpired, //订单过期事件由应用程序发布

    /// 退订:取消已付款未发货的订单
    action refundRequest {
        entry beforeRefundRequest,
        transition PAYED->REFUNDING,
        exit OrderRefundRequest,  //发布退订申请事件
    },

    /// 退款
    action refund {
        entry checkOrderItemReturned,   //检查货物是否退还
        transition REFUNDING->REFUNDED end,
        exit OrderRefunded,   
    }
};

/// 合同状态转移：这里展示带switch表达式的条件转移
stm ContractStatusChanged {
    /// 提交: 业务员提交经理审核
    action submit {
        entry beforeSubmit,         //提交前校验数据完整性
         transition NEW-> totalAmount switch {
            lt(100000) -> APPROVED, //小金额合同自动审核通过
            _ -> SUBMITTED          //其余的需要经理审阅
         },
         exit ContractSubmitted,    
    },

    /// 审批同意: 经理同意签约
    action approve{
        transition SUBMITTED->APPROVED,
        exit ContractApproved,
    }
}
```

框架层提供执行动作的能力（doAction），下面的代码展示了逻辑

```java
//我们遵循习惯把接口用大写I开头
public interface IAction<TContext>{
    TContext context();
    boolean canExecute();
    void execute();     //no need throw exception 
    void transition();
    void exit();
}
public <TContext> void doAction(IAction<TContext> a){
    try{
        //begin trans if necessary
        if(!a.canExecute()){
            throw new Exception("can not do action")
        }
        a.execute();
        a.transition();

        try{
            a.exit();   //raise exit event
            //commit transaction
        }
        catch(Exception ex){
            //rollback transaction 
            log.Warn(ex);
        }
    }
    catch(Exception e){
        log.Error(e);
        throw e; //or you can wrap e into a domain exception
    }
    
}
```

## 角色和权限

> 流程架构 · 第一步。先定义谁可以访问模块、执行 Action 与流程活动，再设计数据流与工作流。

### 角色（`role`）

是指在需求分析阶段就要识别的关键用户的扮演角色，我们使用role定义他们的权限：

```ts
/// 市场专员：负责收集销售线索、为销售团队提供潜在客户
role MarketingMan {
    //可以定义有什么权限
};
/// 销售专员：负责跟踪潜在客户、签约
role SalesMan {
};
/// 销售经理：负责分配潜在客户、合同审批
role SalesManager{
}
```

### 权限（`auth`）

有模块的访问权限（`module auth`）、行动权限（`action auth`）以及流程活动权限（`flow activity auth`）。

模块数据访问权限范围定义如下。其中工作组是特殊的存在，例如成立一个项目组，授权他们可以访问这个项目的相关数据。例如仓库，可以在部门中细分工作组专门管理某个仓库。数据范围使用`scope`定义。更特殊的使用`access rule`定义访问规则。

```ts
//权限范围：0;OWNER;本人|1;WORKGROUP;工作组|2;DEPARTMENT;部门|4;DIVISION;公司|8;ALL;所有
scope OWNER //定义本人负责的，谁创建的，谁是当前所有人就拥有访问权限
scope WORKGROUP //在工作组中的人就拥有访问权限
```

行动在模块关联的数据模型的状态机里面定义，行动权限使用`actions`子句授权，而流程活动权限单独在流程中授权。完整的角色权限定义举例如下：

```ts
/// 市场专员：负责收集销售线索、为销售团队提供潜在客户
role MarketingMan default scope OWNER {                      //默认scope=OWNER
    //可以定义有什么权限
    auth module Crm.Marketing READ,                         //有本人范围的看板查看权限
    auth module Crm.Marketing.Lead ALL,                     //有本人范围的销售线索增删改查权限
    auth module Crm.Sales.Prospect READ scope DEPARTMENT,   //有本部门范围的潜在客户
};
/// 销售专员：负责跟踪潜在客户、签约
role SalesMan default scope OWNER {
    auth module Crm.Sales.Prospect ALL,
    auth module Crm.Sales.Contract ALL actions[submit,sign],
};
/// 销售经理：负责分配潜在客户、合同审批
role SalesManager default scope DEPARTMENT {
    auth module Crm.Sales.Prospect ALL actions[assign,revoke],
    auth module Crm.Sales.Contract ALL actions[approve,disapprove],
}
/// 总经理：负责公司运营
role GeneralManager default scope ALL {
    auth module * READ, //拥有所有模块的查看权限
}
```

通常业务实体对象都具有下面四个字段（通过接口`IAuthorizable`约定），用来权限范围划分：

* `creatorId` 创建人用户ID，创建人总是有此条数据的查看和跟踪权限
* `creatorDeptId` 创建部门ID，创建部门负责人总是有此条数据的查看和跟踪权限
* `ownerId` 当前负责人用户ID
* `ownerDeptId` 当前负责部门ID

允许架构师定义和约定这些字段的名称，一般在一个系统中是统一的。

## 数据流

> 流程架构 · 数据流与单对象 STM。

### 数据转换器

允许设计数据流中的数据转换器(Converter)，你可以自定义类型转换器。最终都生成实现接口IConverter<S,T>的类，有函数T convert(S)。

```sql

/// 到货通知项转收货项: 输入时`AsnItem`，输出是`ReceiptItem`
converter AsnItem->ReceiptItem      //函数名称为AsnItemToReceiptItem
{
    quantity->receivingQty,         //名称不同，类型相同，转换表达式
    SUBSTRING(lotNo,2,30)->lotNo,   //支持函数等表达式
    quantity*IFNULL(costPrice,0)->cost,
    StringToDate(expiryDate)->expiryDate,//StringToDate假设是类型转换器，框架提供
    asnId->refId,
    itemId->refItemId
    ...,                            //名称和类型都相同，简写
};
 
/// 到货通知转收货单 
converter Asn->Receipt
{
    'R'+SUBSTRING(asnNo,3)->recNo,
    now->recDate,
    items.map(it->AsnItemToReceiptItem(it))->items, // 子表之间的转换
    ...,    //相同名称和类型的自动转换
}
```

转换器中箭头左边表达式的上下文是`S`类型，箭头右边的上下文是`T`类型，类型可以是字段类型、对象类型。

### 数据流图（DFD）

## 流程架构

> 流程架构 · 跨模块 BPMN 编排。

例如签订项目合同后，需要启动项目，在系统中合同（Contract）是一个实体模型，项目（Project）是另一个实体模型，我们要在状态转换机设计中表达`ContractSigned`事件要触发`Project`的`create`，传入`Contract`并使用ContractToProject转换器创建一个`Project`对象，保存后触发`ProjectCreated`事件。

项目实施到验收完成了，合同可以收款了，这时候是`ProjectAccepted`事件触发合同进入完工状态，倒过来回写合同相关数据，例如验收日期。

我们要设计两个状态机之间的事件流，通过图形化的方式，链接两个模块对象之间数据流。但是为了AI编码考虑，绝对要支持底层语言，使用M语言来描述：

```ts
/// 客户关系管理流程
/// 模块间的消息用MessageFlow(-->) 
flow CrmFlow
{
    
    /// 开始
    event Begin StartEvent {
        * --> FollowProspect,
    }

    /// 跟踪潜在客户
    activity FollowProspect ManualTask {
        role SalesMan,      //定义销售员负责跟踪潜在客户，他有权限操作
        role SalesManager,  //可以定义多个角色有权操作
        //上下文模块
        context module Crm.Sales.Prospect,  

        //StartQuote 动作在上下文模块中的实体对象定义，放在他的状态转换机中，
        //StartQuote 动作触发开始报价
        action StartQuote --> Quote with ProspectToQuotation, //with 定义使用转换器
    }

    /// 报价
    activity Quote UserTask {           //UserTask不是必须的，它是默认值
        role SalesMan,
        context module Crm.Sales.Quotation,    //上下文模块
        event QuotationAccepted --> SignContract with QuotationToContract, //事件触发的流
        event QuotationDenied   --> Terminated,  //事件触发的流
    }
    
    /// 签约
    activity SignContract {
        role SalesMan,
        context module Crm.Sales.Contract,
        event ContractSigned --> CreateProject,
    }

    activity AmendContract{
        role SalesMan,
        context module Crm.Sales.ContractAmend,
        event ContractAmended --> NotifyProjectManager,
    }

    
    
    /// 终止事件
    event Terminated EndEvent {

    }

    /// 通知项目经理
    activity NotifyProjectManager SendTask {

    }
}
```

上面的模型要能与BPMN XML格式相互转换，便于与BPMN工具集成。

### 流

所以流程中的`-->`和状态转换机中的`->`都是流的一种，使用BPMN中的术语即讯息流程和序列流程。

* 顺序流 (Sequence Flow) 用于展示活动执行的先后顺序，是流程内部的“主路径”
* 消息流 (Message Flow) 用于展示两个独立业务实体（如不同的“池”/Pool）之间的消息发送与接收

### 事件（流程的“触发器”与“结果”）

* 开始事件 (`Start Event`) 表示流程或子流程的起点，捕获型
* 中间事件 (`Intermediate Event`) 发生在开始和结束事件之间，既可以是“捕获型”（等待触发），也可以是“抛出型”（主动产生结果）
* 结束事件 (`End Event`) 标志着流程或子流程某个路径的结束。它是“抛出型”的，表示流程路径的终结

事件还可以附加在活动的边界上，称为边界事件 (`Boundary Event`)，用于在活动执行期间响应特定情况。

### 活动（流程的“工作”与“任务”）

BPM中的分类如下

* 任务 (Task)：原子性的工作单元，不可再拆分。对应我们的行动（`action`）
* 子流程 (Sub-Process)：复合活动，本身由一系列其他元素（事件、活动、网关）构成一个完整的流程。对应我们的活动（`activity`）。

（1）行动（`action`）的分类采用BPM的方法：

* 用户任务 (User Task) 需要人工在软件系统中完成。例如经理在OA系统中审批报销单（`线上干`）
* 人工任务 (Manual Task) 由人在现实世界中完成，无需系统支持。例如快递员上门取件（`线下干`）
* 服务任务 (Service Task) 由系统或应用程序自动执行。例如调用Web服务发送订单确认邮件（`自动干`）
  * 脚本任务 (Script Task) 由流程引擎执行一段脚本代码。例如执行一个简单的Java或JavaScript脚本更新数据状态
  * 发送任务 (Send Task) 发送一条消息到外部参与者。例如向客户发送报价单
  * 接收任务 (Receive Task) 等待并接收一条来自外部参与者的消息。例如等待客户签回合同

实际上业务规则任务 (Business Rule Task)我认为没必要，可归入服务任务，我们的流程自动化任务就是调用系统服务。执行脚本、发送、接收都属于自动化的服务任务，只是实现的方式不同而已。

BPM活动还可以通过标记 (Marker) 来定义更复杂的行为，例如：循环 (Loop)、多实例 (Multiple Instance)和补偿 (Compensation)等。这些过于复杂，我们暂时不引入，未来再扩展。

（2）活动（`activity`）在MMDA的世界中是面向一个上下文实体的多个任务组成的复合动作（`actions`）

* 活动有一个上下文（`context`），是我们的模块，及其关联的数据对象（`record`），数据是活动的输入
* 活动会触发事件，引发另一个活动的启动，传输转换后的数据。因此活动输出本身上下文数据对象，通过转换器（`converter`）将输出对象转换后传入引发的活动。

### 网关（流程的`决策者`与`路由器`）

在BPM中网关用于控制流程的分支与汇聚，决定流程的走向。它不执行具体工作，只负责路由。常见的网关类型如下

* 排他网关 (Exclusive Gateway) 内部含 "X" 标志，单选 (XOR)：从多条分支中有且仅有一条路径会被执行。用于互斥的决策，例如：根据金额大小选择不同审批路径。
* 并行网关 (Parallel Gateway) 内部含 "+" 标志，全选 (AND)：所有输出分支会同时被执行。在汇聚时，必须等待所有输入分支都完成，流程才会继续。用于创建可并行处理的任务，例如：审批通过后，同时进行“开发票”和“备货”。
* 包容网关 (Inclusive Gateway) 内部含 "O" 标志，多选 (OR)：根据条件，一条或多条分支会被执行。在汇聚时，需要等待所有被激活的分支都完成。用于更灵活的场景，例如：高风险订单可能需要“财务审核”和“法务审核”两者都做，而普通订单只需“财务审核”。
* 事件网关 (Event-Based Gateway) 内部含 多个圆圈的标志，事件驱动：流程会等待后续多个事件中最先发生的那一个，然后沿着该事件对应的路径继续。 用于需要根据外部事件进行选择的场景，例如：等待“客户确认”或“超时提醒”两个事件，哪个先到就执行哪个。

我们也利用网关定义流程的路由和决策。例如：

```ts
/// 签约
activity SignContract {
    context module Crm.Sales.Contract,
    event ContractSigned --> NotifyContractSigned,
}
/// 报喜
gateway NotifyContractSigned ExclusiveGateway {
    context module Crm.Sales.Contract,
    totalAmount switch  {
        ge(100000)  -> NotifyGeneralManager,    //大金额的通知总经理报喜
        ge(10000)   -> NotifyManager            //小金额的通知经理报喜
        _           -> Silent                   //太小的静默
    },
}
```

## 交互设计

## 文件目录

> **正式规范**：[doc/project.md](project.md)（formatVersion 2.0）。以下为 SSOT 设计笔记摘要。

mmda 项目目录：

* `{projectCode}.mmda` — **项目清单**（根目录，JSON；非 M语言 模型文件）
* `README.md` — 说明
* `biz/` — **[业务架构]** 每个子系统一个模块分解文件
  * `biz/base.ma` — 基础数据
  * `biz/crm.ma` — 客户关系管理
  * `biz/wms.ma` — 仓储管理系统
  * `biz/srm.ma` — 供应商关系管理
  * `biz/mes.ma` — 制造执行系统
  * `biz/hrm.ma` — 人力资源管理系统
  * `biz/fi.ma` — 财务管理系统
* `data/` — **[数据架构]**
  * `data/models/*.mm` — 每个数据模型一个文件，可相互引用（如 `Partner.mm`、`Address.mm`）
  * `data/enums/*.me` — 每个枚举一个文件（如 `OrderStatus.me`）
  * `data/stms/*.ms` — 状态机，每个 STM 单独文件（如 `OrderStatusChanged.ms`）
* `flow/` — **[流程架构]**
  * `flow/roles/*.mr` — 角色（如 `SalesMan.mr`）
  * `flow/converters/*.mc` — 数据转换器（可选）
  * `flow/crm.mf`、`flow/crm.mf.g` — 跨模块流程 + DFD/BPMN 图形投影
* `ui/` — **[交互设计]** `*.mi` 界面定义（**无 `.g`**）
  * `ui/hrm/InterviewEditor.mi`
  * `ui/crm/ProspectEditor.mi`
* `**/*.{ma,mm,ms,mf}.g` — SSOT 文件名后追加 `.g` 的图形布局（见 `doc/ide/graph-files.md`）
* `doc/` — `*.md` 文档
* `codegen/profiles/` — Codegen Profile（交付）
* `{projectCode}.mmdax` — 打包归档（ZIP，包含以上 core + attachment，默认不含 `generated/`）

### 文件扩展名

| 扩展名 | 含义 |
|--------|------|
| `.mmda` | **项目清单**（仅根目录 `{projectCode}.mmda`） |
| `.ma` | 子系统 Module 架构（`biz/`） |
| `.mm` | 数据模型 Meta Model（`record` / `view`） |
| `.me` | 枚举 Meta Enum |
| `.ms` | 状态机 Meta State machine |
| `.mr` | 角色 Meta Role |
| `.mc` | 数据转换器 Meta Converter（补充） |
| `.mf` | 跨模块流程 Meta Flow（BPMN（.mf）） |
| `.mi` | 界面 Meta Interface |
| `*.{ma,mm,ms,mf}.g` | 图形投影（布局/样式；SSOT 路径 + `.g`） |
| `.md` | Markdown 文档 |
| `.mmdax` | 项目 ZIP 归档包 |
