/// 物料: @Material 物料。原材料
record Material {
    /// 物料标识
    @Partitioned [32768,0x7fffff]
    materialId int64 identity generated readonly hidden,
    /// 物料用途: 0;LABOR_SKILL;劳动技能|1;RAW_MATERIAL;原材料|2;PART;零配件|4;SEMI_PRODUCT;半成品|8;PRODUCT;产成品|16;EQUIP_TOOLS;机具设备|32;CONSUMABLE;耗材|64;OFFICE_SUPPLY;办公用品|128;OTHER;其他
    materialType MaterialType default 1,
    /// 分类: HAS_ONE MaterialCat(categoryID,categoryName,parentCatID) AS category
    @One MaterialCat(categoryId,categoryName,parentCatId) as category
    categoryId int64 indexed,
    /// 物料图片
    @Thumbnail
    materialPic varchar(255)?,
    /// 物料编码
    @Unique
    materialCode varchar(30) readonly,
    /// 物料名称
    @Name
    materialName varchar(100),
    /// 物料全称
    @Computed concat_ws(' ',brand,materialName,specs,modelType,series,texture,grade,prodPlace,other)
    materialFullName varchar(255) readonly,
    /// 品牌
    brand varchar(30)?,
    /// 规格
    specs varchar(50)?,
    /// 型号
    modelType varchar(50)?,
    /// 系列
    series varchar(80)?,
    /// 材质
    texture varchar(30)?,
    /// 等级
    grade varchar(30)?,
    /// 产地
    prodPlace varchar(30)?,
    /// 其他
    other varchar(30)?,
    /// 最小数量: 销售时通常按此数量报价
    minQty decimal(18, 3)? default 1.000,
    /// 单位: 计价单位引用Unit(unit,unit)
    unit varchar(10),
    /// 国标号: 标准件由国标号+型号可唯一确定
    gbNo varchar(50)?,
    /// 单位重量(KG)
    unitWeight decimal(18, 3)? unsigned,
    /// 单位体积(M3)
    unitVolume decimal(18, 3)? unsigned,
    /// 成本单价: 指采购价或出厂价
    costPrice decimal(18, 4)? unsigned,
    /// 销售单价: 用于工程项目或批发价
    salesPrice decimal(18, 4)? unsigned,
    /// 零售价
    retailPrice decimal(18, 2)? unsigned,
    /// 质检比例
    qcRatio decimal(18, 2) unsigned default 0.00,
    /// 特征SKU: 0表示不启用特征和SKU
    featuredSku bool default false,
    /// 启用包装
    supportPackage bool default false,
    /// 追踪供货号: 即不同贸易伙伴的物料号追踪
    tracingPartNo bool default false,
    /// 追踪方式: 0;NONE;-|1;LOT;批次|2;SN;序列号
    trackingMode MaterialTracingMode unsigned default 0,
    /// 流通速率: 0;UNKNOWN;-|1;HIGH;高速|2;MEDIUM;中速|3;LOW;低速|4;DEAD;呆滞
    turnoverFrequency CirculationSpeed unsigned default 0,
    /// 保质期（天）
    expirationDays int32? unsigned,
    /// 下单提前期
    preorderDays int32? unsigned,
    /// 价值等级: 0;NONE;未分|1;LOW;低|2;MEDIUM;中|3;HIGH;高
    costLevel CostLevel? unsigned,
    @State MaterialLifecycle
    /// 状态: 0;NEW;新|1;USED;已启用|-1;DEPRECATED;已弃用
    status UsageStatus default 0 indexed readonly,
    /// 自定义
    customJson varchar(2000)? hidden,
    /// 修改日志标识: 引用ChangeLog.logID
    changeLogId int64? hidden,
    /// 备注
    remark varchar(255)?,
    /// 标签
    tags varchar(255)?,
    /// 创建人: REF User(userID,userName)
    @Ref User(userId,userName)
    creatorId int64? indexed readonly,
    /// 创建部门: REF Department(deptID,deptName)
    @Ref Department(deptId,deptName)
    deptId int64? indexed readonly,
    /// 创建日期
    createDate timestamp? default now readonly,
    /// 修改人: REF User(userID,userName)
    @Ref User(userId,userName)
    lastModifierId int64? indexed readonly,
    /// 最后修改
    lastModified timestamp? default now readonly,
    /// 外部SKU编码
    extKey varchar(64)? readonly hidden,
    @Many
    features MaterialFeature[+] readonly,
    @Many
    medias MaterialMedia[+] readonly,
    @Many
    partNos MaterialPartner[+] readonly,
    @Many
    skus Sku[+] readonly,
    @Index IDX_material_featuredSku(featuredSku),
    @Index IDX_material_fullName(materialFullName),
    @Index IDX_material_lastModified(lastModified),
    @Index IDX_material_materialCode(materialCode),
    @Index IDX_material_trackingMode(trackingMode),
    @Index IDX_material_type(materialType),
}
