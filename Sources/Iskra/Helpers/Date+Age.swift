import Foundation

extension Date {
    /// Calculates age in years from this date to now using ISO 8601 calendar.
    var ageInYears: Int {
        Calendar.iso8601.dateComponents([.year], from: self, to: Date()).year ?? 0
    }

    /// Checks if the person with this birth date is at least the specified age.
    func isAtLeastAge(_ minimumAge: Int) -> Bool {
        ageInYears >= minimumAge
    }
}
