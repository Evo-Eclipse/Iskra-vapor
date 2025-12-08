import Foundation

/// Lightweight localization system.
/// Loads strings from JSON files bundled in Resources/Localization.
///
/// - Note: Strings are loaded once at startup and remain immutable thereafter.
///   The `nonisolated(unsafe)` is safe because we only write during single-threaded init.
enum L10n {
    nonisolated(unsafe) private static var strings: [String: Any] = [:]

    /// Loads localization strings for the specified locale.
    /// Must be called once during app startup before any concurrent access.
    static func load(locale: String = "en") {
        guard strings.isEmpty else { return }

        // .process() flattens directory structure, so file is at root of bundle
        guard let url = Bundle.module.url(forResource: locale, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            fatalError("Invalid locale: unable to load \(locale).json")
        }

        strings = json
    }

    /// Returns localized string for the given key path.
    /// Key path uses dot notation: "onboarding.welcome.title"
    static func string(_ keyPath: String) -> String {
        let components = keyPath.split(separator: ".").map(String.init)
        var current: Any = strings

        for component in components {
            guard let dict = current as? [String: Any], let next = dict[component] else {
                return "[\(keyPath)]"
            }
            current = next
        }

        return (current as? String) ?? "[\(keyPath)]"
    }

    /// Shorthand subscript for string lookup.
    static subscript(_ keyPath: String) -> String { string(keyPath) }
}

// MARK: - Screen (Standard UI Block)

extension L10n {
    /// Represents a standard UI screen with title, body, and optional action button.
    /// JSON structure: { "title": "...", "body": "...", "action": "..." }
    struct Screen {
        let title: String
        let body: String
        let action: String

        init(_ path: String) {
            self.title = L10n["\(path).title"]
            self.body = L10n["\(path).body"]
            self.action = L10n["\(path).action"]
        }

        /// Formatted text: title + newline + body
        var text: String { "\(title)\n\n\(body)" }
    }

    /// Represents a prompt with title, hint, and warning.
    /// JSON structure: { "title": "...", "hint": "...", "warning": "..." }
    struct Prompt {
        let title: String
        let hint: String
        let warning: String

        init(_ path: String) {
            self.title = L10n["\(path).title"]
            self.hint = L10n["\(path).hint"]
            self.warning = L10n["\(path).warning"]
        }

        var text: String { "\(title)\n\n\(hint)\n\n\(warning)" }
    }
}

// MARK: - Predefined Screens

extension L10n.Screen {
    static let welcome = L10n.Screen("onboarding.welcome")
    static let welcomeBack = L10n.Screen("onboarding.welcomeBack")
    static let usernameRequired = L10n.Screen("onboarding.usernameRequired")
    static let complete = L10n.Screen("onboarding.complete")
    static let sessionExpired = L10n.Screen("onboarding.sessionExpired")
    static let learnMore = L10n.Screen("onboarding.learnMore")
}

extension L10n.Prompt {
    static let birthdate = L10n.Prompt("onboarding.birthdate")
    static let gender = L10n.Prompt("onboarding.gender")
}

// MARK: - Errors & Common

extension L10n {
    enum Errors {
        static var generic: String { L10n["errors.generic"] }
        static var invalidCallback: String { L10n["errors.invalidCallback"] }
        static var format: String { L10n["onboarding.birthdate.errorFormat"] }
        static var underage: String { L10n["onboarding.birthdate.errorUnderage"] }
    }

    enum Gender {
        static var male: String { L10n["onboarding.gender.options.male"] }
        static var female: String { L10n["onboarding.gender.options.female"] }
    }
}
