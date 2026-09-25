import Foundation

/// What the app was told to do at launch. Currently just the session length,
/// but this is the one place a new startup parameter belongs — not scattered
/// `ProcessInfo` calls in the app shell.
public struct LaunchConfiguration: Sendable, Equatable {
    /// `nil` means "use the built-in default" — no `--duration` and no
    /// `SAMFLOW_DURATION_MINUTES` were given.
    public var duration: TimeInterval?

    public init(duration: TimeInterval? = nil) {
        self.duration = duration
    }

    /// Parses `--duration <minutes>`, `--duration=<minutes>` or `-d <minutes>`
    /// from launch arguments, falling back to the `SAMFLOW_DURATION_MINUTES`
    /// environment variable (useful when the app is opened via LaunchServices,
    /// where argument passing is more awkward than setting an env var).
    ///
    /// A malformed or non-positive value is ignored rather than rejected — a bad
    /// startup parameter should never stop the app from launching.
    public static func parse(
        arguments: [String] = Array(CommandLine.arguments.dropFirst()),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> LaunchConfiguration {
        let minutes = minutes(fromArguments: arguments) ?? minutes(fromEnvironment: environment)
        return LaunchConfiguration(duration: minutes.map(TimeInterval.minutes))
    }

    private static func minutes(fromArguments arguments: [String]) -> Double? {
        var index = arguments.startIndex
        while index < arguments.endIndex {
            let argument = arguments[index]

            if argument == "--duration" || argument == "-d" {
                let next = arguments.index(after: index)
                guard next < arguments.endIndex else { return nil }
                return validMinutes(arguments[next])
            }

            if let inline = argument.split(separator: "=", maxSplits: 1).first, inline == "--duration" {
                return validMinutes(String(argument.dropFirst("--duration=".count)))
            }

            index = arguments.index(after: index)
        }
        return nil
    }

    private static func minutes(fromEnvironment environment: [String: String]) -> Double? {
        environment["SAMFLOW_DURATION_MINUTES"].flatMap(validMinutes)
    }

    private static func validMinutes(_ raw: String) -> Double? {
        guard let value = Double(raw), value.isFinite, value > 0 else { return nil }
        return value
    }
}
