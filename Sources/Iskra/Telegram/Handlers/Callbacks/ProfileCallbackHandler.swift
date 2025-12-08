/// Handles profile-related callbacks (prefix: "profile").
///
/// Callback data:
/// - `profile:create` — start profile creation
/// - `profile:goal:*` — goal selection
/// - `profile:pref:*` — preference selection
/// - `profile:submit` — submit for review
/// - `profile:edit:*` — edit specific field
struct ProfileCallbackHandler: CallbackHandler {
    func handle(_ query: Components.Schemas.CallbackQuery, parsed: ParsedCallback, context: UpdateContext) async {
        guard let payload = parsed.payload else {
            await answerWithError(query: query, context: context)
            return
        }

        switch payload {
        case "create":
            await ProfileFlow.start(query: query, context: context)
        case "submit":
            await ProfileFlow.submitProfile(query: query, context: context)
        default:
            await handleCompoundAction(payload: payload, query: query, context: context)
        }
    }

    private func handleCompoundAction(payload: String, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let parts = payload.split(separator: ":", maxSplits: 1)
        guard parts.count == 2, let action = parts.first, let value = parts.last else {
            await answerWithError(query: query, context: context)
            return
        }

        let state = context.state(for: query.from.id)

        switch action {
        case "goal":
            guard let goal = ProfileGoal(rawValue: String(value)) else {
                await answerWithError(query: query, context: context)
                return
            }
            // Check if we're editing or in normal flow
            if case .profile(.editing(.goal)) = state {
                await ProfileFlow.processEditedGoal(goal: goal, query: query, context: context)
            } else {
                await ProfileFlow.processGoal(goal: goal, query: query, context: context)
            }

        case "pref":
            guard let pref = LookingForPreference(rawValue: String(value)) else {
                await answerWithError(query: query, context: context)
                return
            }
            if case .profile(.editing(.preferences)) = state {
                await ProfileFlow.processEditedPreferences(pref: pref, query: query, context: context)
            } else {
                await ProfileFlow.processPreferences(pref: pref, query: query, context: context)
            }

        case "edit":
            let editAction = String(value)
            switch editAction {
            case "menu":
                await ProfileFlow.showEditMenu(query: query, context: context)
            case "back":
                await ProfileFlow.backToPreview(query: query, context: context)
            default:
                guard let field = ProfileField(rawValue: editAction) else {
                    await answerWithError(query: query, context: context)
                    return
                }
                await ProfileFlow.editField(field: field, query: query, context: context)
            }

        default:
            context.logger.warning("Unknown profile action: \(action)")
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
