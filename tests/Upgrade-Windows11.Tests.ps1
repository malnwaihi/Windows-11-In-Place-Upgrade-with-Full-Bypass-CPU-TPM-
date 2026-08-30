Describe "Upgrade-Windows11 Script Tests" {
    It "Normalize-Drive should format drive letters correctly" {
        # 假设已将脚本中的函数定义包含在此测试环境中
        Normalize-Drive("d") | Should -Be "D:"
        Normalize-Drive("E:") | Should -Be "E:"
        Normalize-Drive("F:\") | Should -Be "F:"
    }
}
