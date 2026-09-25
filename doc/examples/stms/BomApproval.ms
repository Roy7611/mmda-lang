/// Bom 生命周期
stm BomApproval on Bom.status {
    /// 弃用
    action abandon {
        transition *->ABANDONED,
    }

    /// 变更
    action alter {
        transition APPROVED->REVISING,
    }

    /// 批准
    action approve {
        transition CERTIFIED->APPROVED,
    }

    /// 取消变更
    action cancelAlter {
        transition REVISING->APPROVED,
    }

    /// 校对
    action certify {
        transition DRAFTED->CERTIFIED,
    }

    /// 驳回
    action disapprove {
        transition DRAFTED,CERTIFIED->NEW,
    }

    /// 匹配标准件
    action matchStd {
        transition NEW,DRAFTED,CERTIFIED,REVISING->NEW,DRAFTED,CERTIFIED,REVISING,
    }

    /// 提交
    action submit {
        transition NEW->DRAFTED,
    }

}
