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

    /// Shows custom age input prompt.
    static func showCustomAgePrompt(
        chatId: Int64,
        messageId: Int64,
        context: UpdateContext
    ) async {
        context.setState(.settings(.filtersAgeInput), for: chatId)
        await Presenter.showCustomAgePrompt(
            chatId: chatId,
            messageId: messageId,
            context: context
        )
    }

    /// Handles age filter selection (relative options).
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
            let userAge = Int16(user.age)

            // Convert option to age range (all include user's age)
            let ageMin: Int16
            let ageMax: Int16

            switch option {
            case "peers":
                // Exactly their age
                ageMin = userAge
                ageMax = userAge
            case "bitOlder":
                // Their age to +3
                ageMin = userAge
                ageMax = min(99, userAge + 3)
            case "older":
                // Their age to +5
                ageMin = userAge
                ageMax = min(99, userAge + 5)
            case "bitYounger":
                // -3 to their age
                ageMin = max(16, userAge - 3)
                ageMax = userAge
            case "younger":
                // -5 to their age
                ageMin = max(16, userAge - 5)
                ageMax = userAge
            case "any":
                ageMin = 16
                ageMax = 99
            default:
                return // Unknown option
            }

            await saveAgeRange(
                userId: userId,
                ageMin: ageMin,
                ageMax: ageMax,
                context: context
            )

            // Refresh menu
            await showMenu(chatId: chatId, messageId: messageId, context: context)
        } catch {
            context.logger.error("Failed to update age filter: \(error)")
        }
    }

    /// Handles custom age range text input (format: "min-max").
    static func handleCustomAgeInput(
        text: String,
        chatId: Int64,
        context: UpdateContext
    ) async {
        // Parse "min-max" format
        let parts = text.split(separator: "-").compactMap { Int16($0.trimmingCharacters(in: .whitespaces)) }

        guard parts.count == 2 else {
            await Presenter.showCustomAgeError(
                chatId: chatId,
                errorKey: "filters.ageCustom.errorFormat",
                context: context
            )
            return
        }

        let ageMin = parts[0]
        let ageMax = parts[1]

        guard ageMin >= 16, ageMax <= 99, ageMin <= ageMax else {
            await Presenter.showCustomAgeError(
                chatId: chatId,
                errorKey: "filters.ageCustom.errorRange",
                context: context
            )
            return
        }

        do {
            guard let user = try await context.users.find(telegramId: chatId) else {
                return
            }

            await saveAgeRange(
                userId: user.id,
                ageMin: ageMin,
                ageMax: ageMax,
                context: context
            )

            // Return to menu
            context.setState(.settings(.filters), for: chatId)
            await showMenu(chatId: chatId, context: context)
        } catch {
            context.logger.error("Failed to save custom age: \(error)")
        }
    }

    /// Saves age range to filter.
    private static func saveAgeRange(
        userId: UUID,
        ageMin: Int16,
        ageMax: Int16,
        context: UpdateContext
    ) async {
        do {
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
        } catch {
            context.logger.error("Failed to save age range: \(error)")
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
