/// 工艺路线: @Routing 工艺路线。定义了生产一种产品（或变种）所需的工序顺序，即生产流程的结构，同时定义了每道工序所需资源、安装和执行所需时间以及生产成本如何计算。在工艺路线中将为每道工序分配工序编号和后续工序。 工序顺序形成工艺路线网络，而工艺路线网络可通过带有方向且有一个或多个起点，但是只有一个终点的图表表示。工艺路线有两种，即简单工艺路线和工艺路线网络。
record Routing {
    /// 工艺路线ID
    @Partitioned [10000,0x000F_FFFF]
    routingId uint64 identity generated,
    /// 工艺路线编码
    @Unique
    routingCode varchar(4),
    /// 工艺路线名称
    routingName varchar(100),
    /// 工艺路线类型: 0;PROCESS;流程|1;DISCRETE;离散|2;HYBRID;混合
    routingType RoutingType default 0,
    /// 终结工序
    endOpId uint64?,
    /// 制品类别: HAS_ONE base.MaterialCat(categoryID,categoryName) AS productCategory
    @One base.MaterialCat(categoryId,categoryName) as productCategory
    productCategoryId uint64 indexed,
    /// 生产周期: (min)，所有工序的Cycle Time总和
    leadTime decimal(18, 2)? unsigned,
    /// 生产节拍(min): 瓶颈工序的Cycle Time/60
    neckCycleTime decimal(18, 4)? unsigned,
    /// 路线图文件
    diagramFile varchar(255)?,
    @State RoutingLifecycle
    /// 状态: 0;NEW;新|1;USED;已启用|-1;DEPRECATED;已弃用
    status UsageStatus default 0 indexed readonly,
    /// 标签
    tags varchar(255)? readonly,
    /// 备注
    remark varchar(255)?,
    /// 自定义
    customJson varchar(2000)?,
    /// 创建人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    creatorId uint64? indexed readonly,
    /// 创建部门: REF Department(deptID,deptName)
    @Ref base.Department(deptId,deptName)
    deptId uint64? indexed readonly,
    /// 创建日期
    createDate timestamp? default now readonly,
    /// 修改人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    lastModifierId uint64? indexed readonly,
    /// 最后修改
    lastModified timestamp? default now readonly,
    @Many
    lines ProductionLineRouting[+] readonly,
    @Many
    operationFlows OperationFlow[+] readonly,
    @Many
    operations Operation[+] readonly,
    @Index IDX_routing_code(routingCode),
    @Index IDX_routing_lastModified(lastModified),
    @Index IDX_routing_type(routingType),
}
