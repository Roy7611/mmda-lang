/// 日报事件: @DailyReportEvent 日报事件
record DailyReportEvent {
    /// 日报ID
    @Partitioned [10000,0x000F_FFFF]
    reportId uint64 readonly hidden,
    /// 项次
    itemId int32 readonly hidden,
    /// 事件类型: 0;INFO;信息|1;SUCCESS;成功|2;WARNING;警告|4;DANGER;危险
    eventType MessageLevel default 0,
    /// 事件内容
    eventTitle varchar(255),
    /// 事件原因: 0;NONE;-|1;MAN;人|2;EQUIP;设备|4;MATERIAL;材料|8;DESIGN;设计|16;PROCESS;工艺|32;QC;质量|128;OTHER;其他
    eventCauses ProductionEventCause default 0,
    /// 关联任务: 选择DailyReportTask
    taskId uint64?,
    /// 质量缺陷: HAS_ONE QualityDefect(defectID,defectCode,defectDesc,severity)
    @One QualityDefect(defectId,defectCode,defectDesc,severity)
    defectId uint64? indexed,
    /// 照片: 采用#1, #2引用上传的DailyReportPhoto
    refPhotos varchar(255)?,
    /// 要求响应
    requiredResponse bool default b'0,
    /// 重要性: 0;UNKNOWN;-|1;IMPORTANT;重要|2;VERY_IMPORTANT;非常重要
    importance Importance default 0,
    /// 紧急性: 0;NORMAL;普通|1;SENIOR;优先|2;URGENT;紧急
    emergency Urgency default 0,
    /// 事件标识: 若要求响应，需要设计和生产部门解决，自动生成ProductionEvent
    eventId uint64? readonly,
    /// 整改措施建议: 交付总监可给主意
    rectificationProposal varchar(255)?,
    @Id PK_dailyreportevent(reportId, itemId),
}
