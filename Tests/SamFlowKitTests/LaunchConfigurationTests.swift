import Foundation
import Testing
@testable import SamFlowKit

@Suite("Launch configuration")
struct LaunchConfigurationTests {
    @Test("No arguments or environment means no override")
    func noOverride() {
        let config = LaunchConfiguration.parse(arguments: [], environment: [:])
        #expect(config.duration == nil)
    }

    @Test("--duration <minutes> sets the duration")
    func spaceSeparated() {
        let config = LaunchConfiguration.parse(arguments: ["--duration", "45"], environment: [:])
        #expect(config.duration == .minutes(45))
    }

    @Test("-d <minutes> sets the duration")
    func shortFlag() {
        let config = LaunchConfiguration.parse(arguments: ["-d", "10"], environment: [:])
        #expect(config.duration == .minutes(10))
    }

    @Test("--duration=<minutes> sets the duration")
    func inlineEquals() {
        let config = LaunchConfiguration.parse(arguments: ["--duration=15.5"], environment: [:])
        #expect(config.duration == .minutes(15.5))
    }

    @Test("SAMFLOW_DURATION_MINUTES is used when no argument is given")
    func environmentFallback() {
        let config = LaunchConfiguration.parse(
            arguments: [],
            environment: ["SAMFLOW_DURATION_MINUTES": "50"]
        )
        #expect(config.duration == .minutes(50))
    }

    @Test("An argument takes priority over the environment variable")
    func argumentBeatsEnvironment() {
        let config = LaunchConfiguration.parse(
            arguments: ["--duration", "5"],
            environment: ["SAMFLOW_DURATION_MINUTES": "50"]
        )
        #expect(config.duration == .minutes(5))
    }

    @Test("Zero, negative and non-numeric values are ignored")
    func invalidValuesIgnored() {
        #expect(LaunchConfiguration.parse(arguments: ["--duration", "0"], environment: [:]).duration == nil)
        #expect(LaunchConfiguration.parse(arguments: ["--duration", "-5"], environment: [:]).duration == nil)
        #expect(LaunchConfiguration.parse(arguments: ["--duration", "soon"], environment: [:]).duration == nil)
    }

    @Test("A trailing flag with no value is ignored")
    func missingValueIgnored() {
        let config = LaunchConfiguration.parse(arguments: ["--duration"], environment: [:])
        #expect(config.duration == nil)
    }
}
