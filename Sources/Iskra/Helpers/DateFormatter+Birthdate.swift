import Foundation

extension DateFormatter {
    /// Cached formatter for parsing birthdate input.
    /// Supports: DD.MM.YYYY, DD/MM/YYYY, YYYY-MM-DD
    static let birthdate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Parses birthdate from common formats.
    /// - Returns: Date if parsing succeeds, nil otherwise.
    static func parseBirthdate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        for format in ["dd.MM.yyyy", "dd/MM/yyyy", "yyyy-MM-dd"] {
            birthdate.dateFormat = format
            if let date = birthdate.date(from: trimmed) { return date }
        }
        return nil
    }
}
