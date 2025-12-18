import Foundation

extension SearchFlow {
    /// Handles UI presentation for search flow.
    enum Presenter {

        // MARK: - Profile Display

        /// Shows a candidate profile card.
        static func showProfile(
            chatId: Int64,
            profile: ProfileDTO,
            user: UserDTO,
            context: UpdateContext
        ) async {
            let caption = formatProfileCaption(profile: profile, user: user)

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.actions.report"], callbackData: "search:report:\(profile.userId)")
            kb.button(text: L10n["search.actions.message"], callbackData: "search:message:\(profile.userId)")
            kb.row()
            kb.button(text: L10n["search.actions.skip"], callbackData: "search:pass:\(profile.userId)")
            kb.button(text: L10n["search.actions.like"], callbackData: "search:like:\(profile.userId)")

            do {
                _ = try await context.client.sendPhoto(body: .json(.init(
                    chat_id: .case1(chatId),
                    photo: .case2(profile.photoFileId),
                    caption: caption,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send profile: \(error)")
            }
        }

        /// Shows an incoming profile (like/message).
        static func showIncomingProfile(
            chatId: Int64,
            profile: ProfileDTO,
            user: UserDTO,
            interaction: InteractionDTO,
            context: UpdateContext
        ) async {
            var caption = formatProfileCaption(profile: profile, user: user)

            // Add interaction info
            if interaction.action == .envelope, let message = interaction.message {
                caption += "\n\n💬 \(L10n["search.incoming.message"]):\n\"\(message)\""
            } else {
                caption += "\n\n❤️ \(L10n["search.incoming.liked"])"
            }

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.incoming.back"], callbackData: "search:incoming:skip:\(interaction.id)")
            kb.button(text: L10n["search.actions.like"], callbackData: "search:incoming:like:\(interaction.actorId)")

            do {
                _ = try await context.client.sendPhoto(body: .json(.init(
                    chat_id: .case1(chatId),
                    photo: .case2(profile.photoFileId),
                    caption: caption,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send incoming profile: \(error)")
            }
        }

        // MARK: - Status Messages

        /// Shows "no profile" message for users without approved profile.
        static func showNoProfile(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.error.noProfile"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.buttons.createProfile"], callbackData: "profile:start")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send no profile message: \(error)")
            }
        }

        /// Shows "not registered" message.
        static func showNotRegistered(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.error.notRegistered"]

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to send not registered message: \(error)")
            }
        }

        /// Shows "no profiles available" message with options.
        static func showNoProfiles(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.noProfiles.title"] + "\n\n" + L10n["search.noProfiles.hint"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.noProfiles.adjustFilters"], callbackData: "filter:menu")
            kb.row()
            kb.button(text: L10n["search.noProfiles.viewIncoming"], callbackData: "search:incoming")
            kb.row()
            kb.button(text: L10n["search.buttons.stop"], callbackData: "search:stop")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send no profiles message: \(error)")
            }
        }

        /// Shows search stopped confirmation.
        static func showStopped(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.stopped"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.buttons.resume"], callbackData: "search:start")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send stopped message: \(error)")
            }
        }

        /// Shows generic error message.
        static func showError(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["errors.generic"]

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to send error message: \(error)")
            }
        }

        // MARK: - Action Confirmations

        /// Shows match celebration.
        static func showMatch(
            chatId: Int64,
            targetUserId: UUID,
            context: UpdateContext
        ) async {
            let text = L10n["search.match.title"] + "\n\n" + L10n["search.match.hint"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.match.sendMessage"], callbackData: "search:message:\(targetUserId)")
            kb.row()
            kb.button(text: L10n["search.match.continue"], callbackData: "search:continue")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send match message: \(error)")
            }
        }

        /// Shows message prompt.
        static func showMessagePrompt(
            chatId: Int64,
            messageId: Int64,
            targetUserId: UUID,
            context: UpdateContext
        ) async {
            let text = L10n["search.message.prompt"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["common.cancel"], callbackData: "search:cancelMessage")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send message prompt: \(error)")
            }
        }

        /// Shows message sent confirmation.
        static func showMessageSent(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.message.sent"]

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to send message sent confirmation: \(error)")
            }
        }

        /// Shows report confirmation.
        static func showReported(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.report.sent"]

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to send report confirmation: \(error)")
            }
        }

        // MARK: - Incoming Interactions

        /// Shows no incoming interactions.
        static func showNoIncoming(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.incoming.empty"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.buttons.browse"], callbackData: "search:start")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send no incoming message: \(error)")
            }
        }

        /// Shows no more incoming interactions.
        static func showNoMoreIncoming(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.incoming.done"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.buttons.browse"], callbackData: "search:start")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send no more incoming message: \(error)")
            }
        }

        // MARK: - Notifications

        /// Sends like notification to target user.
        static func sendLikeNotification(
            toTelegramId: Int64,
            fromUser: UserDTO,
            context: UpdateContext
        ) async {
            let text = L10n["search.notification.like"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.notification.viewProfiles"], callbackData: "search:incoming")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(toTelegramId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send like notification: \(error)")
            }
        }

        /// Sends message notification to target user.
        static func sendMessageNotification(
            toTelegramId: Int64,
            fromUser: UserDTO,
            message: String,
            context: UpdateContext
        ) async {
            let preview = message.prefix(100)
            let text = L10n["search.notification.message"] + "\n\n\"\(preview)\(message.count > 100 ? "..." : "")\""

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.notification.viewProfiles"], callbackData: "search:incoming")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(toTelegramId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send message notification: \(error)")
            }
        }

        /// Sends match notification with contact info to user.
        static func sendMatchWithContact(
            toTelegramId: Int64,
            matchedUser: UserDTO,
            matchedProfile: ProfileDTO?,
            isMuted: Bool,
            context: UpdateContext
        ) async {
            let name = matchedProfile?.displayName ?? "Someone"
            let username = matchedUser.telegramUsername ?? "unknown"
            let contactLink = "https://t.me/\(username)"

            var text = L10n["match.notification.title"]
                .replacingOccurrences(of: "%@", with: name)
            text += "\n\n"
            text += L10n["match.notification.contact"]
                .replacingOccurrences(of: "%@", with: "@\(username)")
            text += "\n\(contactLink)"

            // Add muted/spam-block warning if applicable
            if isMuted {
                text += "\n\n⚠️ " + L10n["match.notification.spamBlockWarning"]
            }

            var kb = KeyboardBuilder(type: .inline)
            kb.urlButton(text: L10n["match.notification.openChat"], url: contactLink)

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(toTelegramId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send match notification: \(error)")
            }
        }

        // MARK: - Main Menu

        /// Shows the main search menu.
        static func showMenu(
            chatId: Int64,
            context: UpdateContext
        ) async {
            let text = L10n["search.menu.title"] + "\n\n" + L10n["search.menu.hint"]

            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["search.menu.startSurfing"], callbackData: "search:start")
            kb.row()
            kb.button(text: L10n["search.menu.incoming"], callbackData: "search:incoming")
            kb.row()
            kb.button(text: L10n["search.menu.filters"], callbackData: "filter:menu")

            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to send search menu: \(error)")
            }
        }

        // MARK: - Helpers

        /// Formats a profile caption for display.
        private static func formatProfileCaption(profile: ProfileDTO, user: UserDTO) -> String {
            let name = profile.displayName
            let age = user.age
            let city = profile.city
            let bio = profile.description

            return "\(name), \(age) y.o. • \(city)\n\n\(bio)"
        }

        /// Answers a callback query.
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
    }
}
