/// 需求生命周期
stm RequirementLifecycle on Requirement.status {
    /// 接受
    action accept {
        transition NEW->ACCEPTED,
    }

    /// 实现
    action implement {
        transition ACCEPTED->IMPLEMENTED,
    }

    /// 拒绝
    action reject {
        transition NEW,ACCEPTED->REJECTED,
    }

    /// 重新接受
    action reopen {
        transition REJECTED->NEW,
    }
}
