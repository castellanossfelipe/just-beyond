import Testing
import JBRules
import JBSim

@Test func simModuleSeesRules() {
    #expect(JBSim.moduleName == "JBSim")
    #expect(JBRules.moduleName == "JBRules")
}
