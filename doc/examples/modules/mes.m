/// 制造执行系统: 管理生产计划、执行、质量控制、设备保养和成本分析
system M {
    route: 'mes',                    // 根段推不出（M → mes 非机械），写一次；子级拼接
    icon: 'fas fa-industry fa-fw',
    order: 10,                       // 同级排序键（可选）；省略 = 按编号

    /// 工厂模型: 工厂、车间、产线的组织结构
    module M.01 {
        icon: 'fas fa-sitemap fa-fw',
        order: 10,

        /// 工作中心: 工厂、车间、产线
        feature M.01.001 { model: WorkCenter, sops: ALL }
        /// 工位
        feature M.01.002 { model: Workstation, sops: CRUD }
    }

    /// 生产计划: 排产与工单管理
    module M.03 {
        order: 30,
        version: 1,
        releaseAt: '2026-01-31 10:00:00',

        /// 生产订单: 生产订单的创建、排产、报工与关闭
        feature M.03.001 { model: ProductionOrder, sops: CRUD | REPORT | IMPORT | EXPORT }
        /// 生产排程: 无关联实体，资源名推不出 → 显式写 route 局段
        feature M.03.002 { route: 'schedule', sops: READ | REPORT }
    }
}