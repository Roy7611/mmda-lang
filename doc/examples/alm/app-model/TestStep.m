/// 测试步骤: @TestStep 测试步骤（复合主键 testCaseID + testStepID）
record TestStep {
    /// 测试用例ID
    @Ref TestCase(testCaseID)
    testCaseID int64 partitioned,

    /// 测试步骤ID: 序，不是身份（when 的行序）
    testStepID int32,

    /// 描述: 库侧列名拼写为 desctiption —— 见差异 L14
    desctiption varchar(255),

    /// 测试脚本: 执行面（driver 驱动配置 / 运行历史），不进语言文件 —— 见差异 T6
    testScript varchar(2048)?,

    @Id PK_teststep(testCaseID, testStepID),
    @ForeignKey FK_step_testcase(testCaseID) ref TestCase(testCaseID)
        on update cascade on delete cascade,
}
