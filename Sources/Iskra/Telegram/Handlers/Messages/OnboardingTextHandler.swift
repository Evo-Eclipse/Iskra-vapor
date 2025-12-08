/// Handles text messages during onboarding flow.
/// Routes text input based on current session state.
struct OnboardingTextHandler: TextMessageHandler {
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async {
        guard let user = message.from, let text = message.text else { return }

        switch context.state(for: user.id) {
        case .onboarding(.awaitingBirthdate):
            await OnboardingFlow.processBirthdate(text: text, message: message, context: context)
        default:
            break // Not in onboarding
        }
    }
}
