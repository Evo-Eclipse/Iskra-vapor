import Foundation

extension SearchSettingsFlow {
    /// Presentation layer for search settings flow.
    enum Presenter {

        // MARK: - Menu

        /// Shows filter settings menu with current values.
        static func showMenu(
            chatId: Int64,
            messageId: Int64?,
            filter: FilterDTO,
            userGender: Gender,
            context: UpdateContext
        ) async {
            let title = L10n["filters.menu.title"]
            let body = L10n["filters.menu.body"]

            // Format current settings
            let genderLabel = genderDisplayLabel(for: filter.targetGenders, userGender: userGender)
            let ageLabel = ageDisplayLabel(min: filter.ageMin, max: filter.ageMax)

            let genderLine = L10n["filters.menu.gender"].replacingOccurrences(of: "%@", with: genderLabel)
            let ageLine = L10n["filters.menu.age"].replacingOccurrences(of: "%@", with: ageLabel)

            let text = "\(title)\n\n\(body)\n\n\(genderLine)\n\(ageLine)"

            // Build keyboard
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: genderLine, callbackData: "filter:show:gender")
            kb.row()
            kb.button(text: ageLine, callbackData: "filter:show:age")
            kb.row()
            kb.button(text: L10n["filters.menu.done"], callbackData: "filter:done")

            do {
                if let messageId {
                    // Edit existing message
                    _ = try await context.client.editMessageText(body: .json(.init(
                        chat_id: .case1(chatId),
                        message_id: messageId,
                        text: text,
                        reply_markup: kb.buildInline()
                    )))
                } else {
                    // Send new message
                    _ = try await context.client.sendMessage(body: .json(.init(
                        chat_id: .case1(chatId),
                        text: text,
                        reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                    )))
                }
            } catch {
                context.logger.error("Failed to show filter menu: \(error)")
            }
        }

        // MARK: - Gender Options

        /// Shows gender filter selection options.
        static func showGenderOptions(
            chatId: Int64,
            messageId: Int64,
            context: UpdateContext
        ) async {
            let title = L10n["filters.gender.title"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["filters.gender.own"], callbackData: "filter:gender:own")
            kb.row()
            kb.button(text: L10n["filters.gender.opposite"], callbackData: "filter:gender:opposite")
            kb.row()
            kb.button(text: L10n["filters.gender.any"], callbackData: "filter:gender:any")
            kb.row()
            kb.button(text: L10n["common.back"], callbackData: "filter:menu")

            do {
                _ = try await context.client.editMessageText(body: .json(.init(
                    chat_id: .case1(chatId),
                    message_id: messageId,
                    text: title,
                    reply_markup: kb.buildInline()
                )))
            } catch {
                context.logger.error("Failed to show gender options: \(error)")
            }
        }

        // MARK: - Age Options

        /// Shows age filter selection options.
        static func showAgeOptions(
            chatId: Int64,
            messageId: Int64,
            context: UpdateContext
        ) async {
            let title = L10n["filters.age.title"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["filters.age.peers"], callbackData: "filter:age:peers")
            kb.row()
            kb.button(text: L10n["filters.age.young"], callbackData: "filter:age:young")
            kb.button(text: L10n["filters.age.mid"], callbackData: "filter:age:mid")
            kb.row()
            kb.button(text: L10n["filters.age.mature"], callbackData: "filter:age:mature")
            kb.button(text: L10n["filters.age.any"], callbackData: "filter:age:any")
            kb.row()
            kb.button(text: L10n["common.back"], callbackData: "filter:menu")

            do {
                _ = try await context.client.editMessageText(body: .json(.init(
                    chat_id: .case1(chatId),
                    message_id: messageId,
                    text: title,
                    reply_markup: kb.buildInline()
                )))
            } catch {
                context.logger.error("Failed to show age options: \(error)")
            }
        }

        // MARK: - Confirmation

        /// Shows filter saved confirmation.
        static func showSaved(chatId: Int64, context: UpdateContext) async {
            let text = L10n["filters.saved"]

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to show saved confirmation: \(error)")
            }
        }

        // MARK: - Answer Callback

        /// Answers callback query to dismiss loading indicator.
        static func answerCallback(
            query: Components.Schemas.CallbackQuery,
            text: String? = nil,
            context: UpdateContext
        ) async {
            do {
                _ = try await context.client.answerCallbackQuery(body: .json(.init(
                    callback_query_id: query.id,
                    text: text
                )))
            } catch {
                context.logger.error("Failed to answer callback: \(error)")
            }
        }

        // MARK: - Display Helpers

        /// Converts target genders to display label.
        private static func genderDisplayLabel(for genders: [Gender], userGender: Gender) -> String {
            if genders.count == 2 {
                return L10n["filters.labels.any"]
            } else if genders.first == userGender {
                return L10n["filters.labels.own"]
            } else {
                return L10n["filters.labels.opposite"]
            }
        }

        /// Converts age range to display label.
        private static func ageDisplayLabel(min: Int16, max: Int16) -> String {
            if min <= 16 && max >= 99 {
                return L10n["filters.labels.any"]
            } else if max - min <= 6 {
                return L10n["filters.labels.peers"]
            } else {
                return "\(min)-\(max)"
            }
        }
    }
}
