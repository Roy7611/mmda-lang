/// DailyReport 生命周期
stm DailyReportLifecycle on DailyReport.status {
    /// 上报
    action report {
        transition NEW->REPORTED,
    }

}
