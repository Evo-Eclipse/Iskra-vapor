import Foundation

/// Orchestrates the onboarding flow: /start → intro → birthdate → gender → complete.
/// This file contains only routing logic and state management.
/// UI/presentation is in OnboardingFlow+Presenter.swift.
enum OnboardingFlow {
    // MARK: - Entry

    /// Entry point: shows intro for new users, welcome back for existing.
    static func start(message: Components.Schemas.Message, context: UpdateContext) async -> Bool {
        guard let user = message.from else {
            context.logger.warning("Message without user")
            return false
        }

        do {
            if let existingUser = try await context.users.find(telegramId: user.id) {
                await Presenter.welcomeBack(chatId: message.chat.id, user: existingUser, context: context)
                return true
            }
        } catch {
            context.logger.error("Failed to check user: \(error)")
            return false
        }

        await Presenter.intro(chatId: message.chat.id, context: context)
        return false
    }

    // MARK: - Callbacks

    /// User tapped "Create Profile" — check username, begin registration.
    static func beginRegistration(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let user = query.from
        let chatId = user.id

        guard user.username != nil else {
            await Presenter.usernameRequired(chatId: chatId, context: context)
            await Presenter.answerCallback(query: query, context: context)
            return
        }

        context.setState(.onboarding(.awaitingBirthdate), for: user.id)
        await Presenter.birthdateRequest(chatId: chatId, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }

    /// User tapped "Learn More".
    static func showLearnMore(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        await Presenter.learnMore(chatId: query.from.id, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }

    /// User tapped "Back" from Learn More.
    static func backToIntro(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        await Presenter.intro(chatId: query.from.id, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }

    // MARK: - Birthdate

    /// Processes birthdate text input.
    static func processBirthdate(text: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let user = message.from else { return }

        guard let birthdate = DateFormatter.parseBirthdate(text) else {
            await Presenter.invalidDateFormat(chatId: message.chat.id, context: context)
            return
        }

        guard birthdate.isAtLeastAge(16) else {
            context.sessions.reset(userId: user.id)
            await Presenter.underage(chatId: message.chat.id, context: context)
            return
        }

        context.updateSession(for: user.id) { session in
            session.onboardingData = OnboardingData(birthdate: birthdate, gender: nil)
            session.state = .onboarding(.awaitingGender)
        }
        await Presenter.genderSelection(chatId: message.chat.id, context: context)
    }

    // MARK: - Gender

    /// Processes gender selection callback.
    static func processGender(gender: Gender, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let user = query.from
        let chatId = user.id

        let birthdate: Date? = context.sessions.updateReturning(userId: user.id) { $0.onboardingData?.birthdate }

        guard let birthdate else {
            context.sessions.reset(userId: user.id)
            await Presenter.sessionExpired(chatId: chatId, context: context)
            await Presenter.answerCallback(query: query, context: context)
            return
        }

        do {
            let newUser = try await context.users.create(
                telegramId: user.id,
                telegramUsername: user.username,
                gender: gender,
                birthDate: birthdate,
            )
            context.sessions.reset(userId: user.id)
            if let newUser { await Presenter.complete(chatId: chatId, user: newUser, context: context) }
        } catch {
            context.logger.error("Failed to create user: \(error)")
            await Presenter.error(chatId: chatId, context: context)
        }

        await Presenter.answerCallback(query: query, context: context)
    }
}
