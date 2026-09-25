/// 物料清单项: @BomItem 物料清单项。标准件指外购的零配件和原材料，虚拟件是一组无需生产的标准件集合，半成品需要生产。
record BomItem {
    /// BOM标识
    @Partitioned [10000,0x000F_FFFF]
    bomId uint64 readonly hidden,
    /// 项次: BOM项次
    itemId int32 readonly hidden,
    /// 组件编号
    partNo varchar(128) readonly hidden,
    /// 组件级别
    partLevel int32 unsigned default 1 readonly hidden,
    /// 物料图片
    @Thumbnail
    materialPic varchar(255)?,
    /// 物料类别
    materialCategory varchar(50)?,
    /// 物料: 标识，可以是不入库的外部物料，控制必须有组件编号
    @One base.Material(materialId,materialCode,materialFullName) lazy
    materialId uint64? indexed hidden,
    /// 物料编码
    materialCode varchar(32)?,
    /// 物料名称
    @Name
    materialName varchar(100),
    /// 品牌
    brand varchar(30)?,
    /// 规格: 通常标准尺寸格式为L*W*H(mm)
    specs varchar(255)?,
    /// 型号
    modelType varchar(50)?,
    /// 国标号
    gbNo varchar(50)?,
    /// 材质
    texture varchar(50)?,
    /// 用量
    quantity decimal(18, 4) unsigned default 1.0000,
    /// 单位
    unit varchar(10),
    /// 图纸编号
    drawingNo varchar(50)?,
    /// 替代料策略: REF_ONE AlternativeStrategy(strategyID,strategyCode,strategyName)
    altStrategyId uint64? unsigned,
    /// 重量(KG)
    weight decimal(18, 3)? unsigned,
    /// 损耗率%
    scrapRate decimal(18, 4) unsigned default 0.0000,
    /// 来源: 0;INVENTORY;库存|1;DIRECT_PURCHASE;直采|2;MAKE;自制|3;OUTSOURCE;外协
    sourcingMode SourcingMode default 0,
    /// 链接: 寻源链接
    sourcingUrl varchar(255)?,
    /// 变更类型: 0;NONE;-|1;CHANGED;修改|2;ADDED;增项|4;REMOVED;减项
    amendType ChangeType default 0 readonly,
    /// 子件BOM: HAS_ONE Bom(bomID,bomNo) AS partBom
    @One Bom(bomId,bomNo) as partBom
    partBomId uint64? indexed,
    /// 子件交期(天)
    partLeadTime int32? unsigned,
    /// 上料工序: REF_ONE Operation(opID,opCode,opName)
    opId uint64?,
    /// 扣料点: 0;NONE;-|1;START;开工扣料|2;FINISH;完工倒扣料
    consumptionPoint MaterialConsumptionPoint default 0,
    /// 产出比率: 。0~1，指一件产品完成此道工序后的产值比，用于计算产值进度。
    outputRate decimal(18, 4) unsigned,
    /// 追踪方式: 0;NONE;-|1;LOT;批次|2;SN;序列号
    tracingMode MaterialTracingMode default 0,
    /// 检验方式: 0;EXEMPTED;免检|1;SAMPLING;抽检|2;FULL;全检
    inspectionMode QualityInspectionMode default 0,
    /// 切割方式: 0;NONE;不切割|1;X;切段|3;XY;切块
    cuttingMode CuttingMode default 0,
    /// 切割规格: 如型材1560mm，如玻璃416*847mm
    cuttingSpecs varchar(255)?,
    /// 算量类型: 0;NONE;手工录入|1;FIXED;固定用量|2;TIMES;乘工程量|3;FORMULA;使用公式
    formulaType FormulaType default 0,
    /// 算量公式: 默认为生产数量*用量/(1-损耗率%)，型材取长度，玻璃取面积
    formula varchar(255)?,
    /// 取整方式: 0;NONE;不取整|1;ONE;逢一进位|3;THREE;二舍三入|5;FIVE;四舍五入
    roundMode RoundMode default 0,
    /// 虚拟件: 是一组物料的组合
    phantom bool default b'0,
    /// 备件: 设备BOM里面用于备品备件
    sparePart bool default b'0,
    /// 成本汇总
    costRollup bool default b'0,
    /// 备注
    remark varchar(255)?,
    /// 引用名称
    refName varchar(30)? readonly hidden,
    /// 引用单号: 例如BomNo
    refNo varchar(30)? readonly hidden,
    /// 引用标识
    refId uint64? readonly hidden,
    /// 引用序号
    refItemId int32? readonly hidden,
    @Many
    comments BomItemComment[+] readonly,
    @Id PK_bomitem(bomId, itemId),
    @Index IDX_bomitem_materialCategory(materialCategory),
    @Index IDX_bomitem_partNo(partNo),
    @ForeignKey FK_bomitem_bom(bomId) references Bom(bomId),
}
