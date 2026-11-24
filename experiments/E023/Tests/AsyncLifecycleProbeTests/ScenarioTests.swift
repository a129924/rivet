import AsyncLifecycleProbe
import Testing

@Test(arguments: Scenario.allCases)
func requestLifecycle(_ scenario: Scenario) async {
  let report = await run(scenario)
  #expect(report.failures.isEmpty, Comment(rawValue: report.failures.joined(separator: "\n")))
}
