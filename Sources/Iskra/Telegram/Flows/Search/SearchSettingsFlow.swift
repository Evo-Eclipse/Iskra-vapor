import Foundation

/// Handles search filter settings flow.
/// Entry: filter:menu callback or /filters command
/// Flow: menu → (gender|age selection) → menu → done
enum SearchSettingsFlow {

    // MARK: - Entry Point

    /// Shows the filter settings menu.
    static func showMenu(
        chatId: Int64,
        messageId: Int64? = nil,
        context: UpdateContext
    ) async {
        do {
            // Get user to determine their gender for "own/opposite" logic
            guard let user = try await context.users.find(telegramId: chatId) else {
                context.logger.warning("User not found for filters: \(chatId)")
                return
            }

            // Get or create default filter
            let filter = try await context.filters.find(userId: user.id)
                ?? FilterDTO(
                    userId: user.id,
                    targetGenders: [.male, .female],
                    ageMin: 16,
                    ageMax: 99,
                    lookingFor: [.friendship, .relationship]
                )

            context.setState(.settings(.filters), for: chatId)
            await Presenter.showMenu(
                chatId: chatId,
                messageId: messageId,
                filter: filter,
                userGender: user.gender,
                context: context
            )
        } catch {
            context.logger.error("Failed to show filter menu: \(error)")
        }
    }

    // MARK: - Gender Selection

    /// Shows gender filter options.
    static func showGenderOptions(
        chatId: Int64,
        messageId: Int64,
        context: UpdateContext
    ) async {
        await Presenter.showGenderOptions(
            chatId: chatId,
            messageId: messageId,
            context: context
        )
    }

    /// Handles gender filter selection.
    static func selectGender(
        option: String,
        chatId: Int64,
        messageId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else {
                return
            }
            let userId = user.id

            // Convert option to target genders
            let targetGenders: [Gender] = switch option {
            case "own": [user.gender]
            case "opposite": user.gender == .male ? [.female] : [.male]
            default: [.male, .female] // "any"
            }

            // Get current filter or create new
            if let _ = try await context.filters.find(userId: userId) {
                _ = try await context.filters.update(
                    userId: userId,
                    targetGenders: targetGenders
                )
            } else {
                _ = try await context.filters.create(
                    userId: userId,
                    targetGenders: targetGenders,
                    ageMin: 16,
                    ageMax: 99,
                    lookingFor: [.friendship, .relationship]
                )
            }

            // Refresh menu
            await showMenu(chatId: chatId, messageId: messageId, context: context)
        } catch {
            context.logger.error("Failed to update gender filter: \(error)")
        }
    }

    // MARK: - Age Selection

    /// Shows age filter options.
    static func showAgeOptions(
        chatId: Int64,
        messageId: Int64,
        context: UpdateContext
    ) async {
        await Presenter.showAgeOptions(
            chatId: chatId,
            messageId: messageId,
            context: context
        )
    }

    /// Handles age filter selection.
    static func selectAge(
        option: String,
        chatId: Int64,
        messageId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else {
                return
            }
            let userId = user.id

            // Convert option to age range
            let ageMin: Int16
            let ageMax: Int16
            switch option {
            case "peers":
                let age = Int16(user.age)
                ageMin = max(16, age - 3)
                ageMax = min(99, age + 3)
            case "young":
                ageMin = 18
                ageMax = 25
            case "mid":
                ageMin = 26
                ageMax = 35
            case "mature":
                ageMin = 35
                ageMax = 99
            default: // "any"
                ageMin = 16
                ageMax = 99
            }

            // Get current filter or create new
            if let _ = try await context.filters.find(userId: userId) {
                _ = try await context.filters.update(
                    userId: userId,
                    ageMin: ageMin,
                    ageMax: ageMax
                )
            } else {
                _ = try await context.filters.create(
                    userId: userId,
                    targetGenders: [.male, .female],
                    ageMin: ageMin,
                    ageMax: ageMax,
                    lookingFor: [.friendship, .relationship]
                )
            }

            // Refresh menu
            await showMenu(chatId: chatId, messageId: messageId, context: context)
        } catch {
            context.logger.error("Failed to update age filter: \(error)")
        }
    }

    // MARK: - Done

    /// Completes filter setup and returns to idle.
    static func done(
        chatId: Int64,
        context: UpdateContext
    ) async {
        context.setState(.idle, for: chatId)
        await Presenter.showSaved(chatId: chatId, context: context)
    }
}
