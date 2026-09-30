/// 生产订单按状态筛选 : UAT —— 计划员在列表页筛「已下达」，列表只呈现命中订单（face UI）
test TC-000045 {
    /// 锚：挂二级 Module（必填）；feature 细化到功能特征（phase FEATURE 才必填）
    module  M.03
    feature M.03.002

    /// 在哪一层做（四档：FEATURE / INTEGRATION / SYSTEM / UAT）
    phase UAT

    /// 验哪个面（前后端分离：UI = 前端交互 / API = 后端接口）
    face UI

    /// 多维标签（目标 / 方法 / 强度）；「通道」维度已由 face + driver 表达，不再作标签
    kinds {
        FUNCTIONAL
        BLACK_BOX
        SMOKE
    }

    /// 谁生成的
    source AI

    /// 分层（只有 GOLD 进 baseline，算交付硬门槛）
    level GOLD

    /// 怎么跑（face UI 只允许 E2E / MANUAL）
    driver E2E

    /// 跑在哪
    env TEST

    /// 优先级（两维：重要 × 紧急）
    importance IMPORTANT
    priority URGENT

    /// 双签（source AI 与 phase UAT 都必填）
    reviewedBy { business: "张三", designer: "李四" }

    tag { "订单", "筛选" }

    /// given = 给出上下文与输入（造数，由 mmda test --gen-data 执行）
    given {
        user planner : role PLANNER, loggedIn
        data orders : record ProductionOrder {
            status : RELEASED | count 3
            status : CREATED  | count 2
        }
        seed 20260929
    }

    /// when = 当你干了什么（动作序列，由 mmda test --run --face UI --driver E2E 驱动；行序即步序）
    when {
        open  view ProductionOrderList                            /// 计划员打开生产订单列表
        set   view ProductionOrderList.filter.status = RELEASED   /// 选择状态 = RELEASED
        press view ProductionOrderList.search                     /// 点击「查询」
        wait  view ProductionOrderList.rows == 3
    }

    /// then = 就会有……（断言，由 mmda test --assert 判定）
    then {
        every view ProductionOrderList.rows.status == RELEASED
        size  view ProductionOrderList.rows == 3
        view ProductionOrderList.total == 3
    }

    /// 备选 / 拒绝路径（完整的 GWT 三连，可任选子集覆盖）
    alt "无命中" {
        given {
            data orders : record ProductionOrder { status : CREATED | count 2 }
        }
        when {
            press view ProductionOrderList.search
        }
        then {
            size      view ProductionOrderList.rows == 0
            unchanged view ProductionOrderList.filter.status
        }
    }
}

/// 生产订单查询接口 : 功能 —— 后端按状态过滤（face API / driver HTTP，前后端分离的另一个面）
test TC-000046 {
    module  M.03
    feature M.03.002

    /// 功能测试：锚在 feature（phase FEATURE 必须写 feature）
    phase FEATURE
    face  API

    kinds { FUNCTIONAL, BLACK_BOX }

    source AI
    level  GOLD
    driver HTTP
    env    TEST

    given {
        data orders : record ProductionOrder {
            status : RELEASED | count 3
            status : CREATED  | count 2
        }
        seed 20260929
    }

    /// API 面：真发请求（HTTP）；返回体经 `as resp` 绑定给 then 断言
    when {
        call api POST /api/mes/ProductionOrders/search({ status: RELEASED }) as resp
    }

    then {
        resp.status == 200
        size  resp.rows == 3
        every resp.rows.status == RELEASED
    }
}

/// 生产订单查询接口 : 机械用例 —— 状态取值超出枚举即被拒（OAS 契约，face API）
test TC-000047 {
    module  M.03
    feature M.03.002

    phase FEATURE
    face  API

    kinds { FUNCTIONAL, BLACK_BOX }

    source MECHANICAL
    level  NORMAL
    driver HTTP

    given {
        ref orders : record ProductionOrder where status == RELEASED take 1
    }

    when {
        call api POST /api/mes/ProductionOrders/search({ status: "NOT_A_STATUS" })
    }

    then {
        throws    api POST /api/mes/ProductionOrders/search == M0401
        unchanged record ProductionOrder.status
    }
}
