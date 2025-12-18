import Foundation

/// User session containing conversation state and temporary data.
///
/// Sessions are stored per Telegram user ID and track:
/// - Current state in the conversation flow (HFSM)
/// - Temporary data collected during multi-step flows
/// - Activity timestamp for potential cleanup
///
/// Value semantics ensure thread-safe copy-on-write behavior.
struct UserSession: Sendable, Equatable {
    /// Current state in the hierarchical state machine.
    var state: BotState

    /// Timestamp of last user activity (for session expiration).
    var lastActivityAt: ContinuousClock.Instant

    /// Temporary data for onboarding flow.
    var onboardingData: OnboardingData?

    /// Draft profile data during creation/editing.
    var profileDraft: ProfileDraft?

    /// Creates a new session in idle state.
    init(
        state: BotState = .idle,
        lastActivityAt: ContinuousClock.Instant = .now
    ) {
        self.state = state
        self.lastActivityAt = lastActivityAt
        self.onboardingData = nil
        self.profileDraft = nil
    }

    /// Resets session to idle state, clearing temporary data.
    mutating func reset() {
        state = .idle
        onboardingData = nil
        profileDraft = nil
    }
}

// MARK: - Onboarding Data

/// Temporary data collected during onboarding.
struct OnboardingData: Sendable, Equatable {
    /// User's date of birth (collected first, cannot be changed later).
    var birthdate: Date?

    /// User's gender (collected second, cannot be changed later).
    var gender: Gender?
}

// MARK: - Profile Draft

/// Draft data for profile creation/editing.
/// Accumulates data as user progresses through profile setup.
struct ProfileDraft: Sendable, Equatable {
    /// City/location string.
    var city: String?

    /// Relationship goal.
    var goal: ProfileGoal?

    /// Who the user is looking for.
    var lookingFor: LookingForPreference?

    /// Bio text (up to 600 characters).
    var bio: String?

    /// Telegram file_id of uploaded photo.
    var photoFileId: String?
}

/// Profile relationship goal.
enum ProfileGoal: String, Sendable, Equatable, CaseIterable {
    case friendship
    case relationship
    case both
}

/// Search preference for who user is looking for.
enum LookingForPreference: String, Sendable, Equatable, CaseIterable {
    case male
    case female
    case any
}
