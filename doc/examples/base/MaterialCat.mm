/// 物料类别: @MaterialCat 物料类别。原材料分类
record MaterialCat {
    /// 类别标识
    @Partitioned [10000,0x000F_FFFF]
    categoryId uint64 identity generated readonly,
    /// 类别编码
    @Unique
    categoryCode varchar(15)?,
    /// 类别名称
    @Name
    categoryName varchar(30),
    /// 物料用途: 0;LABOR;劳动力|1;RAW_MATERIAL;原材料|2;PART;零配件|4;SEMI_PRODUCT;半成品|8;PRODUCT;产成品|16;TOOLS;机具设备|32;PACKAGING;包材|64;CONSUMABLE;办公用品|128;OTHER;其他
    materialType MaterialType default 1,
    /// 上级类别标识
    parentCatId uint64?,
    /// 预定义否
    predefined bool default b'0,
    /// 级深
    depth int32 default 0,
    /// 子节点数: 0代表叶子节点
    childrenCount int32 default 0,
    /// 默认下单提前期
    defaultPreorderDays int32?,
    /// 扩展对象: REF metadata.XMetaObject(tenantObjName,label)
    @Ref XMetaObject(tenantObjName,label)
    materialX varchar(64)? indexed,
    @Index IDX_materialcat_code(categoryCode),
    @Index IDX_materialcat_materialType(materialType),
    @Index IDX_materialcat_name(categoryName),
    @Index IDX_materialcat_parentCatID(parentCatId),
}
