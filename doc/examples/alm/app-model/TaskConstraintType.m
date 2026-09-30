/// 任务限制类型
enum TaskConstraintType : int8 {
    /// 无
    NONE = 0,
    /// 尽快启动
    AS_SOON_AS_POSSIBLE = 1,
    /// 尽可能晚启动
    AS_LATE_AS_POSSIBLE = 2,
    /// 启动不得早于
    START_NO_EARLIER_THAN = 3,
    /// 启动不得晚于
    START_NO_LATER_THAN = 4,
    /// 完成不得早于
    FINISH_NO_EARLIER_THAN = 5,
    /// 完成不得晚于
    FINISH_NO_LATER_THAN = 6,
    /// 必须开始于
    MUST_START_ON = 7,
    /// 必须于完成
    MUST_FINISH_ON = 8,
}
