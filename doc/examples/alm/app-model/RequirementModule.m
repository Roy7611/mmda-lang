/// 需求功能模块: @RequirementModule 需求与功能模块的归属
record RequirementModule {
    /// 需求ID
    @Ref Requirement(requirementID)
    requirementID int64 partitioned,

    /// 功能模块: REF metadata.Module(moduleCode,moduleLabel)
    @Ref Module(moduleCode,moduleLabel)
    moduleCode varchar(15),

    @Id PK_requirementmodule(requirementID, moduleCode),
}
