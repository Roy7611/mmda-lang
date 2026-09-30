/// 测试用例依赖: @TestCaseDependency 测试用例依赖（自引用 M:N）
record TestCaseDependency {
    /// 测试用例ID
    @Ref TestCase(testCaseID)
    testCaseID int64 partitioned,

    /// 依赖测试用例: HAS_ONE TestCase(testCaseID,testCaseNo,testCaseTitle) AS preTestCase
    /// ⚠️ 注释引用的 testCaseTitle 列在 testcase 表中并不存在 —— 见差异 L12
    @One TestCase(testCaseID,testCaseNo) as preTestCase
    preTestCaseID int64,

    @Id PK_testcasedependency(testCaseID, preTestCaseID),
    @ForeignKey FK_dependency_testcase(testCaseID) ref TestCase(testCaseID)
        on update cascade on delete cascade,
    /// ⚠️ 库侧只有 on update cascade，缺 on delete 规则，与上面那条不对称 —— 见差异 L19
    @ForeignKey FK_pre_testcase(preTestCaseID) ref TestCase(testCaseID)
        on update cascade,
}
