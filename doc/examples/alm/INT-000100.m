/// 生产排程可视化 : 让计划员摆脱纸质台账，排产结果实时可见
intent INT-000100 {
    /// 层次：业务目标（较宏观，回答「为谁解决什么问题」）
    layer      BUSINESS

    /// 业务主题域（SERU Subject Area）: S1 期分组，S2 建模时细化为 System / Module
    subject    "生产执行"

    /// 价值分类（Kano）
    type       BASIC

    /// 优先级
    importance VERY_IMPORTANT
    urgency    SENIOR

    /// 标签
    tag        "排程"

    /// Why: 为什么做
    why {
        "计划排程靠纸质台账与口头传递，变更后下游不知道；",
        "排产结果不可见，导致停机与交期延误频繁发生。",
    }

    /// What: 做成什么样
    what {
        "计划员能实时看到排产结果与变更；",
        "下游车间在同一处看到与自己相关的排程。",
    }
}
