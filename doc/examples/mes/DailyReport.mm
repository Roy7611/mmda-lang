/// 日报: @DailyReport 日报。图片和视频作为附件上传，可在异常情况中输入#异常问题@负责人来快速创建异常事件AbnormalEvent。
record DailyReport {
    /// 报告ID
    @Partitioned [10000,0x000F_FFFF]
    reportId int64 identity generated readonly,
    /// 报告编号
    @Unique
    reportNo varchar(15),
    /// 报告日期
    reportDate date default curdate(),
    /// 工程项目: HAS_ONE Project(projectID,projectNo,projectName)
    @One Project(projectId,projectNo,projectName)
    projectId int64? indexed,
    /// 今日完成
    fullfillment varchar(255),
    /// 异常情况
    abnormalities varchar(255),
    /// 明日计划
    nextPoints varchar(255),
    @State DailyReportLifecycle
    /// 状态: 0;DRAFT;草稿|1;REPORTED;已上报
    status DailyReportStatus default 0 indexed readonly,
    /// 标签
    tags varchar(255)?,
    /// 备注
    remark varchar(255)?,
    /// 创建部门: REF Department(deptID,deptName)
    @Ref base.Department(deptId,deptName)
    deptId int64? indexed readonly,
    /// 创建人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    creatorId int64? indexed readonly,
    /// 创建日期
    createDate timestamp? default now readonly,
    /// 修改人: REF User(userID,userName)
    @Ref base.User(userId,userName)
    lastModifierId int64? indexed readonly,
    /// 最后修改
    lastModified timestamp? default now readonly,
    @Many
    events DailyReportEvent[+] readonly,
    @Many
    photos DailyReportPhoto[+] readonly,
    @Many
    tasks DailyReportTask[+] readonly,
    @Index IDX_dailyreport_date(reportDate),
    @Index IDX_dailyreport_lastModified(lastModified),
    @Index IDX_dailyreport_no(reportNo),
}
