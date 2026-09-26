/// 工序: @Operation 工序。定义工序编码、名称、耗时、生产参数、报警、所需资源（包括技能、设备）及成本计算。工序可以是一个子制程，子制程必然会产出半成品或原材料。
record Operation {
    /// 工序ID
    @Partitioned [10000,0x000F_FFFF]
    opId int64 identity generated,
    /// 工序编码
    @Unique
    opCode varchar(15),
    /// 工序名称
    @Name
    opName varchar(30),
    /// 工序组合类型: 0;LINE;产线|1;CELL;生产单元|2;SECTION;工段
    opGroupType OpGroupType?,
    /// 工序组
    opGroup varchar(30)?,
    /// 工序阶段: 0;PREPARE;准备|1;START;启动|2;MID;中间|4;END;结束
    opPhase OpPhase default 0,
    /// 工序类型: 0;MAKE;生产|1;TEST;测试|2;SPECIAL;特殊|4;STORAGE;缓存
    opType OpType default 0,
    /// 工艺路线ID
    routingId int64,
    /// 启动数
    startQty int32 unsigned default 1,
    /// 准备时间(秒): 换型时间(秒)
    setupTime int32 unsigned default 0,
    /// 标准工时(秒)
    opTime int32 unsigned,
    /// 生产周期(秒): setupTime+opTime+outRoute.lag
    cycleTime int32 unsigned,
    /// 工艺文档: HAS_ONE Doc(docID,docNo,docName) AS opDoc
    @One Doc(docId,docNo,docName) as opDoc
    opDocId int64? indexed,
    /// 工艺参数: 定义默认的参数名称和值，例如冷却时间
    opParams varchar(255)?,
    /// 产出比率: 。0~1，指一件产品完成此道工序后的产值比，用于计算产值进度。
    outputRate decimal(18, 4) unsigned,
    /// (半)制品报工
    outputProduct bool default false,
    /// 计量单位
    outputUnit varchar(10)?,
    /// 转移批量: 用于生产作业分批，提高排程并行度
    outputBatchQty int32?,
    /// 在制品控类型: 制程品控类型：0;NONE;无|1;FIRST_PIECE;首件检验|2;PATROL_INSPECTION;过程巡检|4;LAST_PIECE;末件终验
    qcInProcessTypes QcInProcessType default 0,
    /// 品控标准: HAS_ONE QualityControlStandard(qcsID,qcsNo) AS qcStandard
    @One QualityControlStandard(qcsId,qcsNo) as qcStandard
    qcsId int64? indexed,
    /// 子工艺路线: HAS_ONE Routing(routingID,routingCode,routingName) AS subRouting
    @One Routing(routingId,routingCode,routingName) as subRouting
    subRoutingId int64? indexed,
    /// 描述
    description varchar(255)?,
    /// X
    x float?,
    /// Y
    y float?,
    /// 宽
    width float?,
    /// 高
    height float?,
    @Many
    charts OperationChart[+] readonly,
    @Many
    resources OperationResource[+] readonly,
    @Index FK_operation_routing(routingId),
    @ForeignKey FK_operation_routing(routingId) references Routing(routingId),
}
