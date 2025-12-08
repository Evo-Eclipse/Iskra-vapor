import Foundation

/// UI/Presentation layer for OnboardingFlow.
/// Contains all message sending, keyboard building, and L10n usage.
/// No business logic — only "eyes and mouth".
extension OnboardingFlow {
    enum Presenter {
        // MARK: - Screens

        static func intro(chatId: Int64, context: UpdateContext) async {
            let screen = L10n.Screen.welcome
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: screen.action, callbackData: "onboarding:create")
            await send(text: screen.text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        static func learnMore(chatId: Int64, context: UpdateContext) async {
            let screen = L10n.Screen.learnMore
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: screen.action, callbackData: "onboarding:back")
            await send(text: screen.text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        static func welcomeBack(chatId: Int64, user _: UserDTO, context: UpdateContext) async {
            await sendWithReplyKeyboard(text: L10n.Screen.welcomeBack.text, chatId: chatId, context: context)
        }

        static func usernameRequired(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Screen.usernameRequired.text, chatId: chatId, context: context)
        }

        // MARK: - Birthdate Step

        static func birthdateRequest(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Prompt.birthdate.text, chatId: chatId, context: context)
        }

        static func invalidDateFormat(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.format, chatId: chatId, context: context)
        }

        static func underage(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Errors.underage, chatId: chatId, context: context)
        }

        // MARK: - Gender Step

        static func genderSelection(chatId: Int64, context: UpdateContext) async {
            let prompt = L10n.Prompt.gender
            let text = "\(prompt.title)\n\n\(prompt.warning)"
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n.GenderOption.male, callbackData: "onboarding:gender:male")
            kb.button(text: L10n.GenderOption.female, callbackData: "onboarding:gender:female")
            await send(text: text, keyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        // MARK: - Completion

        static func complete(chatId: Int64, user _: UserDTO, context: UpdateContext) async {
            let screen = L10n.Screen.complete
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: screen.action, callbackData: "profile:create")
            await sendWithBothKeyboards(text: screen.text, inlineKeyboard: kb.buildInline(), chatId: chatId, context: context)
        }

        // MARK: - Errors

        static func sessionExpired(chatId: Int64, context: UpdateContext) async {
            await send(text: L10n.Screen.sessionExpired.text, chatId: chatId, context: context)
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
                    reply_markup: keyboard.map { .InlineKeyboardMarkup($0) }
                )))
            } catch {
                context.logger.error("Failed to send message: \(error)")
            }
        }
        
        /// Sends a message with the main menu reply keyboard.
        static func sendWithReplyKeyboard(text: String, chatId: Int64, context: UpdateContext) async {
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .ReplyKeyboardMarkup(MainMenuFlow.Presenter.buildReplyKeyboard())
                )))
            } catch {
                context.logger.error("Failed to send message: \(error)")
            }
        }
        
        /// Sends a message with inline keyboard, followed by reply keyboard setup.
        static func sendWithBothKeyboards(
            text: String,
            inlineKeyboard: Components.Schemas.InlineKeyboardMarkup,
            chatId: Int64,
            context: UpdateContext
        ) async {
            // Send main message with inline keyboard
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(inlineKeyboard)
                )))
            } catch {
                context.logger.error("Failed to send message: \(error)")
            }
            
            // Send a follow-up to establish the reply keyboard
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: L10n["menu.hint"],
                    reply_markup: .ReplyKeyboardMarkup(MainMenuFlow.Presenter.buildReplyKeyboard())
                )))
            } catch {
                context.logger.error("Failed to send reply keyboard: \(error)")
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
