import Foundation

/// UI/Presentation layer for OnboardingFlow.
/// Contains all message sending, keyboard building, and L10n usage.
/// No business logic — only "eyes and mouth".
extension OnboardingFlow {
    enum Presenter {
        // MARK: - Screens

        static func intro(chatId: Int64, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.Welcome.title)\n\n\(L10n.Onboarding.Welcome.body)"
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.Onboarding.Welcome.action, callbackData: "onboarding:create")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        static func learnMore(chatId: Int64, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.LearnMore.title)\n\n\(L10n.Onboarding.LearnMore.body)"
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.Onboarding.LearnMore.action, callbackData: "onboarding:back")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        static func welcomeBack(chatId: Int64, user _: UserDTO, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.WelcomeBack.title)\n\n\(L10n.Onboarding.WelcomeBack.body)"
            await send(text: text, chatId: chatId, context: context)
        }

        static func usernameRequired(chatId: Int64, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.UsernameRequired.title)\n\n\(L10n.Onboarding.UsernameRequired.body)"
            await send(text: text, chatId: chatId, context: context)
        }

        // MARK: - Birthdate Step

        static func birthdateRequest(chatId: Int64, context: UpdateContext) async {
            let text = """
            \(L10n.Onboarding.Birthdate.title)

            \(L10n.Onboarding.Birthdate.hint)

            \(L10n.Onboarding.Birthdate.warning)
            """
            await send(text: text, chatId: chatId, context: context)
        }

        static func invalidDateFormat(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Onboarding.Birthdate.errorFormat, chatId: chatId, context: context)
        }

        static func underage(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Onboarding.Birthdate.errorUnderage, chatId: chatId, context: context)
        }

        // MARK: - Gender Step

        static func genderSelection(chatId: Int64, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.Gender.title)\n\n\(L10n.Onboarding.Gender.warning)"
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.Onboarding.Gender.male, callbackData: "onboarding:gender:male")
            kb.button(text: L10n.Onboarding.Gender.female, callbackData: "onboarding:gender:female")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        // MARK: - Completion

        static func complete(chatId: Int64, user _: UserDTO, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.Complete.title)\n\n\(L10n.Onboarding.Complete.body)"
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.Onboarding.Complete.action, callbackData: "profile:create")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        // MARK: - Errors

        static func sessionExpired(chatId: Int64, context: UpdateContext) async {
            let text = "\(L10n.Onboarding.SessionExpired.title)\n\n\(L10n.Onboarding.SessionExpired.body)"
            await send(text: text, chatId: chatId, context: context)
        }

        static func error(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.generic, chatId: chatId, context: context)
        }

        // MARK: - Telegram Primitives

        static func send(text: String, keyboard: Components.Schemas.InlineKeyboardMarkup? = nil, chatId: Int64, context: UpdateContext) async {
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: keyboard.map { .InlineKeyboardMarkup($0) },
                )))
            } catch {
                context.logger.error("Failed to send message: \(error)")
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
