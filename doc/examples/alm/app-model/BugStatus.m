/// 状态
enum BugStatus : int16 {
    /// 新
    NEW = 0,
    /// 开始修复
    OPEN = 1,
    /// 已修复
    FIXED = 2,
    /// 回归测试失败
    REOPEN = 3,
    /// 回归测试通过
    CLOSED = 4,
    /// 已拒绝
    REJECTED = -1,
    /// 已废弃
    ABANDON = -4,
}
