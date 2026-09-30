/// 测试用例: @TestCase 测试用例。包含基本的八项要素，用例编号、测试项目、标题、重要性、预置条件、输入、操作步骤、预期输出（旧库 mmda_alm.testcase 表的复刻，仅供参考 —— 该库将废除，不作投影目标）
record TestCase {
    /// 测试用例ID
    @Partitioned [10000,0x000F_FFFF]
    testCaseID int64 identity generated readonly,

    /// 测试用例编号: 库侧仅普通索引（非唯一）——见差异 L13
    testCaseNo varchar(30) charset ascii,

    /// 测试阶段: UNIT / INTEGRATION / SYSTEM / UAT
    testPhase TestPhase default 0 indexed,

    /// 测试类型: HAS_ONE TestType(testTypeID,testTypeName)
    @One TestType(testTypeID,testTypeName) as testType
    testTypeID int32 indexed,

    /// 测试用例描述: 库侧一列兼任标题与描述（表无 testCaseTitle 列）——见差异 T18 / L12
    testCaseDescription varchar(255),

    /// 功能模块: REF metadata.Module(moduleCode,moduleLabel)
    @Ref Module(moduleCode,moduleLabel)
    moduleCode varchar(15) indexed,

    /// 重要性
    importance Importance default 0 indexed,

    /// 优先级
    priority Urgency default 0 indexed,

    /// 测试环境
    environment TestEnvironment default 0 indexed,

    /// 人工测试
    manual bool default false,

    /// 预置条件
    preCondition varchar(255)?,

    /// 输入数据
    inputData text,

    /// 预期结果
    expectedResult varchar(255),

    /// 实际结果
    actualResult varchar(255),

    /// 状态: 未测试 / 通过 / 失败（库侧只有执行态、无迁移声明）——见差异 T15 / B5 同款
    status TestCaseStatus default 0 indexed,

    /// 标签
    tags varchar(255)? charset utf,

    /// 修订版本
    revision int32 default 0 readonly,

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

    /// 测试步骤: @TestStep 有序步骤（PK 复合）
    @Many
    steps TestStep[+] readonly,

    /// 依赖测试用例: @TestCaseDependency 自引用 M:N
    @Many
    dependencies TestCaseDependency[+] readonly,

    @Index IDX_testcase_no(testCaseNo),
    @Index IDX_testcase_phase(testPhase),
    @Index IDX_testcase_module(moduleCode),
    @Index IDX_testcase_importance(importance),
    @Index IDX_testcase_priority(priority),
    @Index IDX_testcase_env(environment),
    @Index IDX_testcase_status(status),
    @Index IDX_testcase_lastModified(lastModified),
    @ForeignKey FK_testcase_testtype(testTypeID) ref TestType(testTypeID)
        on update cascade,
}
