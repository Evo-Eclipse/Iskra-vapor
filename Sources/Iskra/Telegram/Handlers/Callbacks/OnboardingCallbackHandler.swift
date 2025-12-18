/// Handles onboarding-related callbacks (prefix: "onboarding").
///
/// Callback data:
/// - `onboarding:create` — begin registration
/// - `onboarding:learn` — show learn more
/// - `onboarding:back` — back to intro
/// - `onboarding:gender:male/female` — gender selection
struct OnboardingCallbackHandler: CallbackHandler {
    func handle(_ query: Components.Schemas.CallbackQuery, parsed: ParsedCallback, context: UpdateContext) async {
        guard let payload = parsed.payload else {
            await answerWithError(query: query, context: context)
            return
        }

        switch payload {
        case "create": await OnboardingFlow.beginRegistration(query: query, context: context)
        case "learn": await OnboardingFlow.showLearnMore(query: query, context: context)
        case "back": await OnboardingFlow.backToIntro(query: query, context: context)
        default: await handleCompoundAction(payload: payload, query: query, context: context)
        }
    }

    private func handleCompoundAction(payload: String, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let parts = payload.split(separator: ":", maxSplits: 1)
        guard parts.count == 2, let action = parts.first, let value = parts.last else {
            await answerWithError(query: query, context: context)
            return
        }

        switch action {
        case "gender":
            guard let gender = Gender(rawValue: String(value)) else {
                await answerWithError(query: query, context: context)
                return
            }
            await OnboardingFlow.processGender(gender: gender, query: query, context: context)
        default:
            context.logger.warning("Unknown onboarding action: \(action)")
            await answerWithError(query: query, context: context)
        }
    }

    private func answerWithError(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        do {
            _ = try await context.client.answerCallbackQuery(body: .json(.init(
                callback_query_id: query.id,
                text: L10n.Errors.invalidCallback,
                show_alert: true
            )))
        } catch {
            context.logger.error("Failed to answer callback: \(error)")
        }
    }
}
