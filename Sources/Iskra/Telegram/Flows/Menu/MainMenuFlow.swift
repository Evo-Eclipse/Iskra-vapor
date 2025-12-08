import Foundation

/// Handles main menu display and navigation via persistent reply keyboard.
///
/// The reply keyboard provides always-visible navigation buttons at the bottom
/// of the user's screen, making key features discoverable without commands.
enum MainMenuFlow {
    /// Reply keyboard button identifiers (matched against user text input).
    enum Button: String, CaseIterable {
        case surf = "⛵️ Surf"
        case profile = "✨ Profile"
        
        /// Returns the button matching the given text, if any.
        static func from(_ text: String) -> Button? {
            allCases.first { $0.rawValue == text }
        }
    }
    
    /// Shows the main menu with reply keyboard.
    static func show(chatId: Int64, context: UpdateContext) async {
        await Presenter.showMainMenu(chatId: chatId, context: context)
    }
    
    /// Handles a reply keyboard button press.
    static func handleButton(
        _ button: Button,
        chatId: Int64,
        context: UpdateContext
    ) async {
        switch button {
        case .surf:
            await SearchFlow.start(chatId: chatId, context: context)
            
        case .profile:
            await showMyProfile(chatId: chatId, context: context)
        }
    }
    
    /// Shows the user's current profile or prompts to create one.
    private static func showMyProfile(chatId: Int64, context: UpdateContext) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else {
                await Presenter.showNotRegistered(chatId: chatId, context: context)
                return
            }
            
            // Check for approved profile first
            if let profile = try await context.profiles.find(userId: user.id) {
                await Presenter.showProfile(
                    chatId: chatId,
                    profile: profile,
                    user: user,
                    context: context
                )
            } else if let _ = try await context.moderations.findPending(userId: user.id) {
                // Profile pending moderation
                await Presenter.showPendingProfile(chatId: chatId, context: context)
            } else {
                // No profile - prompt to create
                await Presenter.showNoProfile(chatId: chatId, context: context)
            }
        } catch {
            context.logger.error("Failed to show my profile: \(error)")
            await Presenter.showError(chatId: chatId, context: context)
        }
    }
}

// MARK: - Presenter

extension MainMenuFlow {
    enum Presenter {
        /// Builds the persistent reply keyboard for main navigation.
        static func buildReplyKeyboard() -> Components.Schemas.ReplyKeyboardMarkup {
            var kb = KeyboardBuilder(type: .reply)
            kb.button(text: Button.surf.rawValue)
            kb.button(text: Button.profile.rawValue)
            return kb.buildReply(oneTime: false, resize: true)
        }
        
        /// Shows main menu with welcome message and reply keyboard.
        static func showMainMenu(chatId: Int64, context: UpdateContext) async {
            let text = L10n["menu.title"] + "\n\n" + L10n["menu.hint"]
            
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .ReplyKeyboardMarkup(buildReplyKeyboard())
                )))
            } catch {
                context.logger.error("Failed to show main menu: \(error)")
            }
        }
        
        /// Shows user's profile with edit option.
        static func showProfile(
            chatId: Int64,
            profile: ProfileDTO,
            user: UserDTO,
            context: UpdateContext
        ) async {
            let caption = formatProfileCaption(profile: profile, user: user)
            
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["menu.profile.edit"], callbackData: "profile:edit:menu")
            
            do {
                _ = try await context.client.sendPhoto(body: .json(.init(
                    chat_id: .case1(chatId),
                    photo: .case2(profile.photoFileId),
                    caption: caption,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to show profile: \(error)")
            }
        }
        
        /// Shows pending profile status.
        static func showPendingProfile(chatId: Int64, context: UpdateContext) async {
            let text = L10n["menu.profile.pending"]
            
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to show pending profile: \(error)")
            }
        }
        
        /// Shows no profile message with create button.
        static func showNoProfile(chatId: Int64, context: UpdateContext) async {
            let text = L10n["menu.profile.none"]
            
            var kb = KeyboardBuilder(type: .inline)
            kb.button(text: L10n["menu.profile.create"], callbackData: "profile:create")
            
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text,
                    reply_markup: .InlineKeyboardMarkup(kb.buildInline())
                )))
            } catch {
                context.logger.error("Failed to show no profile message: \(error)")
            }
        }
        
        /// Shows not registered message.
        static func showNotRegistered(chatId: Int64, context: UpdateContext) async {
            let text = L10n["menu.notRegistered"]
            
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: text
                )))
            } catch {
                context.logger.error("Failed to show not registered: \(error)")
            }
        }
        
        /// Shows generic error.
        static func showError(chatId: Int64, context: UpdateContext) async {
            do {
                _ = try await context.client.sendMessage(body: .json(.init(
                    chat_id: .case1(chatId),
                    text: L10n.Errors.generic
                )))
            } catch {
                context.logger.error("Failed to show error: \(error)")
            }
        }
        
        /// Formats profile caption for display.
        private static func formatProfileCaption(profile: ProfileDTO, user: UserDTO) -> String {
            let name = profile.displayName
            let age = user.age
            let city = profile.city
            let bio = profile.description
            
            return "\(name), \(age) y.o. • \(city)\n\n\(bio)"
        }
    }
}
