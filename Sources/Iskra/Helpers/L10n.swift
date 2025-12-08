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
            print("Warning: Failed to load localization for '\(locale)' from bundle")
            return
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

// MARK: - Convenience Accessors

extension L10n {
    enum Onboarding {
        enum Welcome {
            static var title: String { L10n["onboarding.welcome.title"] }
            static var body: String { L10n["onboarding.welcome.body"] }
            static var action: String { L10n["onboarding.welcome.action"] }
        }

        enum WelcomeBack {
            static var title: String { L10n["onboarding.welcomeBack.title"] }
            static var body: String { L10n["onboarding.welcomeBack.body"] }
        }

        enum UsernameRequired {
            static var title: String { L10n["onboarding.usernameRequired.title"] }
            static var body: String { L10n["onboarding.usernameRequired.body"] }
        }

        enum Birthdate {
            static var title: String { L10n["onboarding.birthdate.title"] }
            static var hint: String { L10n["onboarding.birthdate.hint"] }
            static var warning: String { L10n["onboarding.birthdate.warning"] }
            static var errorFormat: String { L10n["onboarding.birthdate.errorFormat"] }
            static var errorUnderage: String { L10n["onboarding.birthdate.errorUnderage"] }
        }

        enum Gender {
            static var title: String { L10n["onboarding.gender.title"] }
            static var warning: String { L10n["onboarding.gender.warning"] }
            static var male: String { L10n["onboarding.gender.options.male"] }
            static var female: String { L10n["onboarding.gender.options.female"] }
        }

        enum Complete {
            static var title: String { L10n["onboarding.complete.title"] }
            static var body: String { L10n["onboarding.complete.body"] }
            static var action: String { L10n["onboarding.complete.action"] }
        }

        enum SessionExpired {
            static var title: String { L10n["onboarding.sessionExpired.title"] }
            static var body: String { L10n["onboarding.sessionExpired.body"] }
        }

        enum LearnMore {
            static var title: String { L10n["onboarding.learnMore.title"] }
            static var body: String { L10n["onboarding.learnMore.body"] }
            static var action: String { L10n["onboarding.learnMore.action"] }
        }
    }

    enum Errors {
        static var generic: String { L10n["errors.generic"] }
        static var invalidCallback: String { L10n["errors.invalidCallback"] }
    }

    enum Common {
        static var cancel: String { L10n["common.cancel"] }
        static var back: String { L10n["common.back"] }
        static var confirm: String { L10n["common.confirm"] }
        static var skip: String { L10n["common.skip"] }
    }
}
