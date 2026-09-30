/// 需求类型 : Kano 模型的需求分类
enum RequirementType : int8 {
    /// 基本需求
    BASIC = 0,
    /// 期望需求
    DESIRED = 1,
    /// 兴奋需求
    ATTRACTIVE = 2,
    /// 无关紧要的需求
    INDIFFERENT = 4,
    /// 不希望有的需求
    UNDESIRED = 5,
}
