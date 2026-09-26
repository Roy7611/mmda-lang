/// 物料清单: @Bom 物料清单。定义生产产品所需的组件。 这些组件可以是原材料、半成品或成分。 要考虑component variations, substitute components
record Bom {
    /// BOM标识
    @Partitioned [10000,0x000F_FFFF]
    bomId int64 identity generated readonly hidden,
    /// BOM类型: 0;PRIMARY;主配方|1;ALTERNATE;替代配方|2;VARIANT;变种配方
    bomType BomType default 0,
    /// 配方组: 变种和替代配方都属于同一组BOM
    bomGroup varchar(30),
    /// BOM编号
    @Unique
    bomNo varchar(30),
    /// 替代配方名: 主配方为空，一个产品可有多种替代配方
    alternate varchar(30)?,
    /// 用途: 0;GENERAL;通用|1;DESIGN;设计|2;PRODUCTION;生产|4;MAINTENANCE;保养|8;SALES;销售
    bomUsage BomUsage default 2,
    /// 工程项目: HAS_ONE Project(projectID,projectNo,projectName)
    @One Project(projectId,projectNo,projectName)
    projectId int64? indexed,
    /// 制品标识: 定制产品一开始为空，审核后自动生成关联的materialID
    @Ref base.Material(materialId,materialFullName)
    productId int64? indexed,
    /// 制品类别: HAS_ONE base.MaterialCat(categoryID,categoryName) AS productCategory
    @One base.MaterialCat(categoryId,categoryName) as productCategory
    productCategoryId int64? indexed,
    /// 制品图片
    @Thumbnail
    productPic varchar(255)?,
    /// 制品编码
    productCode varchar(36)?,
    /// 制品名称: 物料全称
    @Name
    productName varchar(100),
    /// 规格: 如尺寸
    specs varchar(255)?,
    /// 型号
    modelType varchar(50)?,
    /// 材质: 型材颜色、玻璃颜色
    texture varchar(50)?,
    /// 图纸编号
    drawingNo varchar(64)?,
    /// 追踪方式: 0;NONE;-|1;LOT;批次|2;SN;序列号
    tracingMode MaterialTracingMode default 0,
    /// 基数
    baseQuantity decimal(18, 3) unsigned default 1.000,
    /// 总数
    totalQuantity decimal(18, 3)? unsigned,
    /// 单位
    unit varchar(10) default 'EA',
    /// 保质期（天）
    expirationDays int16?,
    /// 工艺文档: HAS_ONE Doc(docID,docNo)
    @One Doc(docId,docNo)
    docId int64? indexed,
    /// 生效日期
    validFrom date readonly,
    /// 限用工厂: REF Plant(plantID,plantCode,plantName)
    @Ref Plant(plantId,plantName)
    plantId int64? indexed,
    /// 工艺路线: HAS_ONE Routing(routingID,routingCode,routingName)
    @One Routing(routingId,routingCode,routingName)
    routingId int64? indexed,
    @State BomApproval
    /// 状态: 0;NEW;新|1;DRAFTED;已起草|2;CERTIFIED;已审核|4;APPROVED;已批准|5;REVISING;变更中|-1;ABANDONED;已弃用
    status BomStatus default 0 indexed readonly,
    /// 标签
    tags varchar(255)?,
    /// 备注
    remark varchar(255)?,
    /// 自定义: 如见光尺寸
    customJson varchar(2000)? readonly,
    /// 变更说明: 修订说明
    revisedDesc varchar(255)?,
    /// 修订版本
    revision int32? default 0 readonly,
    /// 修改日志标识: 引用ChangeLog.logID
    changeLogId int64? readonly hidden,
    /// 创建部门: REF Department(deptID,deptName)
    @Ref base.Department(deptId,deptName)
    deptId int64? indexed readonly,
    /// 创建人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    creatorId int64? indexed readonly,
    /// 创建日期
    createDate timestamp? default now readonly,
    /// 修改人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    lastModifierId int64? indexed readonly,
    /// 最后修改
    lastModified timestamp? default now readonly,
    /// 负责部门: REF Department(deptID,deptName)
    @Ref base.Department(deptId,deptName)
    ownerDeptId int64? indexed readonly,
    /// 负责人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    ownerId int64? indexed readonly,
    /// 基于BOM
    refBomId int64? readonly,
    /// 引用名称: 例如工作包
    refName varchar(30)? readonly hidden,
    /// 引用单号: 例如工作包任务号
    refNo varchar(32)? readonly hidden,
    /// 引用标识
    refId int64? readonly hidden,
    /// 引用序号
    refItemId int16? readonly hidden,
    @Many
    items BomItem[+] readonly,
    @Index IDX_bom_group(bomGroup,refBomId),
    @Index IDX_bom_lastModified(lastModified),
    @Index IDX_bom_no(bomNo),
    @Index IDX_bom_productCode(productCode),
    @Index IDX_bom_ref(refName,refId,refItemId),
    @Index IDX_bom_type(bomType),
    @Index IDX_bom_usage(bomUsage),
}
