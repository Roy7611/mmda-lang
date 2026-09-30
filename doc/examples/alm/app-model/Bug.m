/// 缺陷: @Bug 缺陷（旧库 mmda_alm.bug 表的复刻，仅供参考 —— 该库将废除，不作投影目标）
record Bug {
    /// 缺陷ID
    @Partitioned [10000,0x000F_FFFF]
    bugID int64 identity generated readonly,

    /// 缺陷标题
    bugTitle varchar(255),

    /// 缺陷详情
    bugDetails text?,

    /// 紧急级
    urgency Urgency default 0 indexed,

    /// 严重性: 与 urgency 正交的第二维（同 intent 的 importance × urgency）
    severity Severity default 0 indexed,

    /// 状态: NEW / OPEN / FIXED / REOPEN / CLOSED / REJECTED / ABANDON
    /// 库侧硬编码 7 态、无迁移声明 —— 见差异 B5
    status BugStatus default 0 indexed,

    /// 功能模块: REF metadata.Module(moduleCode,moduleLabel)
    @Ref Module(moduleCode,moduleLabel)
    moduleCode varchar(15) indexed,

    /// 发现版本: 建议收窄为 foundIn（打破哪一版验收基线）—— 见差异 B3
    moduleVersion int32?,

    /// 标签
    tags varchar(255)? charset utf,

    /// 创建部门: REF Department(deptID,deptName)
    @Ref base.Department(deptID,deptName)
    deptID int64? indexed readonly,

    /// 创建人: REF base.User(userID,userName)
    @Ref base.User(userID,userName)
    creatorID int64? indexed readonly,

    /// 创建日期
    createDate timestamp? default now readonly,

    /// 修改人: REF base.User(userID,userName)
    @Ref base.User(userID,userName)
    lastModifierID int64? indexed readonly,

    /// 最后修改
    lastModified timestamp? default now readonly,

    /// 负责人: REF base.User(userID,userName)
    @Ref base.User(userID,userName)
    ownerID int64? indexed readonly,

    /// 负责部门: REF Department(deptID,deptName)
    @Ref base.Department(deptID,deptName)
    ownerDeptID int64? indexed readonly,

    /// 源测试用例ID: 库侧无外键 —— 见差异 L17
    testCaseID int64?,

    /// 源测试步骤ID: 库侧无外键 —— 见差异 L17
    testStepID int32?,

    @Index IDX_bug_status(status),
    @Index IDX_bug_severity(severity),
    @Index IDX_bug_urgency(urgency),
    @Index IDX_bug_module(moduleCode),
    @Index IDX_bug_owner(ownerID),
    @Index IDX_bug_lastModified(lastModified),
}
