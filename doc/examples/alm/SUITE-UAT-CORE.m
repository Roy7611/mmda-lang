/// UAT 验收集 : 项目交付验收的唯一依据（成员由选择器算出，不靠人维护清单）
suite SUITE-UAT-CORE {
    label "UAT 验收集"
    description "全部 phase UAT 用例；成员随模型自动重算"

    select {
        phase UAT
    }

    // 例外（选择器算不到的，或不该在的）
    exclude { TC-000052 }

    runWhen DELIVERY
}

/// 冒烟 : UAT 的最小可交付子集（主干路径，建议 ≤ 20 条）
suite SUITE-SMOKE {
    label "冒烟"
    description "从 UAT 用例里挑主干路径；必须 ⊆ SUITE-UAT-CORE"

    select {
        kinds { SMOKE }
    }

    subset SUITE-UAT-CORE        // 门禁：冒烟必须 ⊆ UAT（mmda check error）

    runWhen BUILD
}

/// UAT 界面面 : UAT 里 face UI 的用例（前后端分离后，前端交互单独成集）
suite SUITE-UAT-UI {
    label "UAT 界面面"
    description "UAT 里 face UI 的用例；在真前端 / 浏览器上跑（driver E2E）"

    select {
        phase UAT
        face  UI
    }

    subset SUITE-UAT-CORE        // 门禁：UI 面 ⊆ UAT

    runWhen MILESTONE
}

/// UAT 接口面 : UAT 里 face API 的用例（后端接口，driver HTTP / HOOKS）
suite SUITE-UAT-API {
    label "UAT 接口面"
    description "UAT 里 face API 的用例；走真实 HTTP 或三端拦截点（driver HTTP / HOOKS）"

    select {
        phase UAT
        face  API
    }

    subset SUITE-UAT-CORE        // 门禁：API 面 ⊆ UAT

    runWhen MILESTONE
}

/// 回归 : 全部 GOLD 用例（含非 UAT 分层）
suite SUITE-REGRESSION {
    select {
        level GOLD
    }

    runWhen DAILY
}

/// 单模块集成 : 二级 Module 的集成测试（按模块派生，不必逐个手写）
suite SUITE-M03-INTEGRATION {
    select {
        module M.03
        phase INTEGRATION
    }

    subset SUITE-REGRESSION

    runWhen MILESTONE
}
