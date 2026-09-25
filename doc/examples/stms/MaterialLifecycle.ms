/// Material 生命周期
stm MaterialLifecycle on Material.status {
    /// 弃用
    action abandon {
        transition NEW,USED->DEPRECATED,
    }

    /// 启用
    action startUsing {
        transition NEW,DEPRECATED->USED,
    }

}
