/// Hierarchical Finite State Machine for Telegram bot conversations.
///
/// Top-level states represent major user flows. Substates (associated values)
/// capture specific steps within each flow. This enables O(1) state-based routing.
///
/// Design principles:
/// - Flat enum with namespaced substates (KISS)
/// - Value semantics for thread-safety (no actors)
/// - Equatable for state comparison in tests
enum BotState: Sendable, Equatable {
    /// No active conversation flow. User can browse or start new flows.
    case idle

    /// Onboarding/registration flow (new users).
    case onboarding(OnboardingStep)

    /// Profile creation or editing flow.
    case profile(ProfileStep)

    /// Search filter configuration.
    case settings(SettingsStep)
}

// MARK: - Onboarding Steps

/// Steps within the onboarding flow.
/// Flow: /start → username check → birthdate → gender → complete
enum OnboardingStep: Sendable, Equatable {
    /// Awaiting date of birth input.
    case awaitingBirthdate

    /// Awaiting gender selection.
    case awaitingGender
}

// MARK: - Profile Steps

/// Steps within profile creation/editing flow.
/// Flow: city → goal → preferences → bio → photo → preview → confirm
enum ProfileStep: Sendable, Equatable {
    /// Entering city/location.
    case enteringCity

    /// Selecting relationship goal (friendship/relationship/both).
    case selectingGoal

    /// Selecting search preferences (M/F/Any).
    case selectingPreferences

    /// Entering bio text (up to 600 chars).
    case enteringBio

    /// Uploading profile photo.
    case uploadingPhoto

    /// Previewing completed profile before submission.
    case previewing

    /// Editing a specific field (from preview).
    case editing(ProfileField)
}

/// Editable profile fields for the editing substate.
enum ProfileField: String, Sendable, Equatable {
    case city
    case goal
    case preferences
    case bio
    case photo
}

// MARK: - Settings Steps

/// Steps within settings/filter configuration.
enum SettingsStep: Sendable, Equatable {
    /// Configuring search filters (menu).
    case filters

    /// Awaiting custom age range input.
    case filtersAgeInput
}
