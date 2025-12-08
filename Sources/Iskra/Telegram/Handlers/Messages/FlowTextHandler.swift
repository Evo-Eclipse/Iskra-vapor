/// Handles text messages during conversation flows.
/// Routes text input based on current session state.
struct FlowTextHandler: TextMessageHandler {
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async {
        guard let user = message.from, let text = message.text else { return }

        switch context.state(for: user.id) {
        // Onboarding
        case .onboarding(.awaitingBirthdate):
            await OnboardingFlow.processBirthdate(text: text, message: message, context: context)

        // Profile creation
        case .profile(.enteringCity):
            await ProfileFlow.processCity(text: text, message: message, context: context)
        case .profile(.enteringBio):
            await ProfileFlow.processBio(text: text, message: message, context: context)

        // Profile editing
        case .profile(.editing(.city)):
            await ProfileFlow.processEditedCity(text: text, message: message, context: context)
        case .profile(.editing(.bio)):
            await ProfileFlow.processEditedBio(text: text, message: message, context: context)

        default:
            break // Not in a text-input state
        }
    }
}
