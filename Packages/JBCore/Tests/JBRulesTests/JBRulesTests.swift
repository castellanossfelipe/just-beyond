import Testing
import JBWorld
import JBRules

@Test func rulesModuleSeesWorld() {
    #expect(JBRules.moduleName == "JBRules")
    #expect(JBWorld.moduleName == "JBWorld")
}
