/// 需求依赖: @RequirementDependency 需求依赖。前置需求关系
record RequirementDependency {
    /// 需求ID
    @Ref Requirement(requirementID)
    requirementID int64 partitioned,

    /// 前置需求: HAS_ONE Requirement(requirementID,requirementNo,requirementTitle) AS preRequirement
    @One Requirement(requirementID,requirementNo,requirementTitle) as preRequirement
    preRequirementID int64,

    @Id PK_requirementdependency(requirementID, preRequirementID),
    @ForeignKey FK_dependency_requirement(requirementID) ref Requirement(requirementID)
        on update cascade on delete cascade,
    @ForeignKey FK_preRequirement_requirement(preRequirementID) ref Requirement(requirementID)
        on update cascade,
}
