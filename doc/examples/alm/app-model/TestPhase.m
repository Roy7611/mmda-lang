/// 测试阶段（旧库 mmda_alm 值域复刻，仅参考、将废除）
/// ⤴ v5：语言侧 `phase` 已去 `UNIT`，四档 = FEATURE / INTEGRATION / SYSTEM / UAT（见 ../../lang/test.md §2.2）
enum TestPhase : int8 {
    /// 单元测试
    UNIT = 0,
    /// 集成测试
    INTEGRATION = 1,
    /// 系统测试
    SYSTEM = 2,
    /// 验收测试（库侧值域 3 为空档）
    UAT = 4,
}
