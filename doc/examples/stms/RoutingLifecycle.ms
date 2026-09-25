/// Routing 生命周期
stm RoutingLifecycle on Routing.status {
    /// 弃用
    action abandon {
        transition USED->DEPRECATED,
    }

    /// 启用
    action startUsing {
        transition NEW,DEPRECATED->USED,
    }

}
