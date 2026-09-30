/// 测试类型: @TestType 测试类型（两级树；库侧为独立字典表，非枚举）—— 见差异 T2 / L7；⤴ v5：语言侧分类改用 `kinds` 多维标签（覆盖 testtype 树第二层），此表仅作旧库参考（见 ../../lang/test.md §2.2）
record TestType {
    /// 测试类型ID
    testTypeID int32,

    /// 测试类型名称
    testTypeName varchar(100),

    /// 测试类型描述
    description varchar(255),

    /// 上级测试类型ID: 自引用树；库侧无外键 —— 见差异 L16
    superTestTypeID int32? indexed,

    @Id PK_testtype(testTypeID),
}
