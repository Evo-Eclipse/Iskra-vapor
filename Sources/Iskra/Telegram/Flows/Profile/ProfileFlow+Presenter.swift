import Foundation

/// UI/Presentation layer for ProfileFlow.
extension ProfileFlow {
    enum Presenter {
        // MARK: - Prompts

        static func cityPrompt(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Prompt.city.title, chatId: chatId, context: context)
        }

        /// Confirms city + asks goal in ONE message
        static func confirmCityAndAskGoal(city: String, chatId: Int64, context: UpdateContext) async {
            let text = L10n["profile.city.confirm"].replacingOccurrences(of: "%@", with: city)
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.GoalOption.friendship, callbackData: "profile:goal:friendship")
            kb.row()
            kb.button(text: L10n.GoalOption.relationship, callbackData: "profile:goal:relationship")
            kb.row()
            kb.button(text: L10n.GoalOption.both, callbackData: "profile:goal:both")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        static func goalSelection(chatId: Int64, context: UpdateContext) async {
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.GoalOption.friendship, callbackData: "profile:goal:friendship")
            kb.row()
            kb.button(text: L10n.GoalOption.relationship, callbackData: "profile:goal:relationship")
            kb.row()
            kb.button(text: L10n.GoalOption.both, callbackData: "profile:goal:both")
            await send(text: L10n.Prompt.goal.title, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        /// Confirms goal + asks preferences in ONE message
        static func confirmGoalAndAskPreferences(goal: ProfileGoal, chatId: Int64, context: UpdateContext) async {
            let label = L10n.GoalOption.label(for: goal)
            let text = L10n["profile.goal.confirm"].replacingOccurrences(of: "%@", with: label)
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.PreferenceOption.male, callbackData: "profile:pref:male")
            kb.row()
            kb.button(text: L10n.PreferenceOption.female, callbackData: "profile:pref:female")
            kb.row()
            kb.button(text: L10n.PreferenceOption.any, callbackData: "profile:pref:any")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        static func preferencesSelection(chatId: Int64, context: UpdateContext) async {
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.PreferenceOption.male, callbackData: "profile:pref:male")
            kb.row()
            kb.button(text: L10n.PreferenceOption.female, callbackData: "profile:pref:female")
            kb.row()
            kb.button(text: L10n.PreferenceOption.any, callbackData: "profile:pref:any")
            await send(text: L10n.Prompt.preferences.title, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        /// Confirms preferences + asks bio in ONE message
        static func confirmPreferencesAndAskBio(pref: LookingForPreference, chatId: Int64, context: UpdateContext) async {
            let label = L10n.PreferenceOption.label(for: pref)
            let text = L10n["profile.preferences.confirm"].replacingOccurrences(of: "%@", with: label)
            await send(text: text, chatId: chatId, context: context)
        }

        static func bioPrompt(chatId: Int64, context: UpdateContext) async {
            let prompt = L10n.Prompt.bio
            let text = prompt.hint.isEmpty ? prompt.title : "\(prompt.title)\n\n\(prompt.hint)"
            await send(text: text, chatId: chatId, context: context)
        }

        static func photoPrompt(chatId: Int64, context: UpdateContext) async {
            let prompt = L10n.Prompt.photo
            let text = prompt.hint.isEmpty ? prompt.title : "\(prompt.title)\n\n\(prompt.hint)"
            await send(text: text, chatId: chatId, context: context)
        }

        // MARK: - Errors

        static func bioTooLong(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.bioTooLong, chatId: chatId, context: context)
        }

        static func bioTooShort(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.bioTooShort, chatId: chatId, context: context)
        }

        static func photoInvalid(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.photoInvalid, chatId: chatId, context: context)
        }

        static func error(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.generic, chatId: chatId, context: context)
        }

        // MARK: - Preview

        static func preview(chatId: Int64, draft: ProfileDraft?, user: UserDTO? = nil, context: UpdateContext) async {
            guard let draft else {
                await error(chatId: chatId, context: context)
                return
            }

            let screen = L10n.Screen.profilePreview
            let goal = draft.goal.map { L10n.GoalOption.label(for: $0) } ?? "—"
            let pref = draft.lookingFor.map { L10n.PreferenceOption.label(for: $0) } ?? "—"

            // Clean confirmation-style message
            let text = """
            \(screen.title)

            City: \(draft.city ?? "—")
            Looking for: \(pref)
            Goal: \(goal)

            Description:
            \(draft.bio ?? "—")

            \(screen.body)
            """

            // [Edit] [Confirm] — complex on left
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: "Edit", callbackData: "profile:edit:menu")
            kb.button(text: screen.action, callbackData: "profile:submit")

            // Send photo with caption
            if let photoFileId = draft.photoFileId {
                await sendPhoto(fileId: photoFileId, caption: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
            } else {
                await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
            }
        }

        static func editMenu(chatId: Int64, context: UpdateContext) async {
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: "City", callbackData: "profile:edit:city")
            kb.button(text: "Goal", callbackData: "profile:edit:goal")
            kb.row()
            kb.button(text: "Looking for", callbackData: "profile:edit:preferences")
            kb.button(text: "Bio", callbackData: "profile:edit:bio")
            kb.row()
            kb.button(text: "Photo", callbackData: "profile:edit:photo")
            kb.row()
            kb.button(text: "← Back", callbackData: "profile:edit:back")
            await send(text: L10n.Screen.profileEdit.title, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        // MARK: - Completion

        static func submitted(chatId: Int64, context: UpdateContext) async {
            let screen = L10n.Screen.profileSubmitted
            await send(text: screen.text, chatId: chatId, context: context)
        }

        // MARK: - Telegram Primitives

        static func send(text: String, keyboard: Components.Schemas.InlineKeyboardMarkup? = nil, chatId: Int64, context: UpdateContext) async {
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: keyboard.map { .InlineKeyboardMarkup($0) }
                )))
            } catch {
                context.logger.error("Failed to send message: \(error)")
            }
        }

        static func sendPhoto(fileId: String, caption: String, keyboard: Components.Schemas.InlineKeyboardMarkup? = nil, chatId: Int64, context: UpdateContext) async {
            do {
                _ = try await context.client.sendPhoto(body: .json(.init(
                    chat_id: .case1(chatId),
                    photo: .case2(fileId),
                    caption: caption,
                    reply_markup: keyboard.map { .InlineKeyboardMarkup($0) }
                )))
            } catch {
                context.logger.error("Failed to send photo: \(error)")
            }
        }

        static func answerCallback(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
            do {
                _ = try await context.client.answerCallbackQuery(body: .json(.init(callback_query_id: query.id)))
            } catch {
                context.logger.error("Failed to answer callback: \(error)")
            }
        }
    }
}
