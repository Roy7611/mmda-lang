/// 需求: @Requirement 需求。ALM 的需求条目（旧库 mmda_alm.requirement 表的复刻，仅供参考 —— 该库将废除，不作投影目标）
record Requirement {
    /// 需求ID
    @Partitioned [10000,0x000F_FFFF]
    requirementID int64 identity generated readonly,

    /// 需求编号: 内核签发 REQ-<模块编码>-<NNN>，签发即固定、永不改
    @Unique
    requirementNo varchar(36) charset ascii readonly,

    /// 需求类型
    requirementType RequirementType default 0,

    /// 需求标题
    @Name
    requirementTitle varchar(255),

    /// 需求描述
    requirementDesc text,

    /// 重要性
    importance Importance default 0,

    /// 紧急性
    urgency Urgency default 0,

    /// 父需求: HAS_ONE Requirement(requirementID,requirementNo,requirementTitle) AS parent
    @One Requirement(requirementID,requirementNo,requirementTitle) as parent
    parentRequirementID int64? indexed,

    /// 状态
    @State RequirementLifecycle
    status RequirementStatus default 0 indexed,

    /// 标签
    tags varchar(255)? charset utf,

    /// 修订版本
    revision int32 default 0 readonly,

    /// 功能模块: REF metadata.Module(moduleCode,moduleLabel)
    @Ref Module(moduleCode,moduleLabel)
    moduleCode varchar(15)? indexed,

    /// 人天数
    manDays decimal(18,1)?,

    /// 计划开始
    expectedStart date?,

    /// 计划完成
    expectedFinish date?,

    /// 计划工期(d): DB 生成列 to_days(expectedFinish) - to_days(expectedStart) + 1
    @Computed toDays(expectedFinish) - toDays(expectedStart) + 1
    expectedPeriod int32? generated readonly,

    /// 任务颜色
    taskColor varchar(7)? charset utf,

    /// 限制类型
    constraintType TaskConstraintType default 0,

    /// 限制日期
    constraintDate datetime?,

    /// 实际开始
    actualStart date?,

    /// 实际完成
    actualFinish date?,

    /// 实际工期(d)
    @Computed toDays(actualFinish) - toDays(actualStart) + 1
    actualPeriod int32? generated readonly,

    /// 创建部门: REF Department(deptID,deptName)
    @Ref base.Department(deptID,deptName)
    deptID int64? indexed readonly,

    /// 创建人: REF User(userID,userName)
    @Ref base.User(userID,userName)
    creatorID int64? indexed readonly,

    /// 创建日期
    createDate timestamp? default now readonly,

    /// 修改人: REF User(userID,userName)
    @Ref base.User(userID,userName)
    lastModifierID int64? indexed readonly,

    /// 最后修改
    lastModified timestamp? default now readonly,

    /// 负责人: REF User(userID,userName)
    @Ref base.User(userID,userName)
    ownerID int64? indexed readonly,

    /// 负责部门: REF Department(deptID,deptName)
    @Ref base.Department(deptID,deptName)
    ownerDeptID int64? indexed readonly,

    /// 依赖需求
    @Many
    dependencies RequirementDependency[+] readonly,

    @Index IDX_requirement_module(moduleCode),
    @Index IDX_requirement_importance(importance),
    @Index IDX_requirement_parent(parentRequirementID),
    @Index IDX_requirement_status(status),
    @Index IDX_requirement_lastModified(lastModified),
    @Index IDX_requirement_owner(ownerID),
    @Index IDX_requirement_creator(creatorID),
    @Index IDX_requirement_type(requirementType),
    @Index IDX_requirement_urgency(urgency),
}
