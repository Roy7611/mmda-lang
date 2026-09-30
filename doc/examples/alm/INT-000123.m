/// 生产订单按状态筛选 : 计划员需要按状态快速定位待排产单据
intent INT-000123 {
    /// 层次：业务 / 用户
    layer      USER

    /// 触发者（关键用户）: 用户层必填
    role       Planner

    /// 业务主题域（SERU Subject Area）: S1 期的分组，S2 建模时细化为 System / Module
    subject    "生产执行"

    /// 价值分类（Kano）
    type       DESIRED

    /// 优先级（两维：重要 × 紧急）
    importance IMPORTANT
    urgency    URGENT

    /// 标签
    tag        "订单", "筛选"

    /// Why: 为什么做 —— 问题与代价，一行一条
    why {
        "计划员在 400+ 待排单据里逐页翻找，平均 6 分钟才定位一张；",
        "漏排直接造成停机，单次停线损失远高于筛选功能的成本。",
    }

    /// What: 做成什么样 —— 可观察的结果，一行一条
    what {
        "计划员能按状态把生产订单列表收敛到自己关心的那一批；",
        "一眼看到命中数量，空结果有明确提示。",
    }

    /// 拆解来源（同层引用，可选）
    parent  INT-000100

    /// 前置依赖（同层引用，可选）
    depends INT-000118
}
