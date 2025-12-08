import Foundation

/// Orchestrates the profile creation/editing flow.
/// Flow: start → city → goal → preferences → bio → photo → preview → submit
/// UI/presentation is in ProfileFlow+Presenter.swift.
enum ProfileFlow {
    // MARK: - Entry

    /// Entry point from "Create Profile" button after onboarding.
    static func start(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id
        context.updateSession(for: userId) { session in
            session.profileDraft = ProfileDraft()
            session.state = .profile(.enteringCity)
        }
        await Presenter.cityPrompt(chatId: userId, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }

    // MARK: - City

    static func processCity(text: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let userId = message.from?.id else { return }
        let city = text.trimmingCharacters(in: .whitespacesAndNewlines)

        context.updateSession(for: userId) { session in
            session.profileDraft?.city = city
            session.state = .profile(.selectingGoal)
        }
        // Confirm selection, then ask next question
        await Presenter.confirmCityAndAskGoal(city: city, chatId: message.chat.id, context: context)
    }

    // MARK: - Goal

    static func processGoal(goal: ProfileGoal, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id
        context.updateSession(for: userId) { session in
            session.profileDraft?.goal = goal
            session.state = .profile(.selectingPreferences)
        }
        await Presenter.answerCallback(query: query, context: context)
        // Confirm selection, then ask next question
        await Presenter.confirmGoalAndAskPreferences(goal: goal, chatId: userId, context: context)
    }

    // MARK: - Preferences

    static func processPreferences(pref: LookingForPreference, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id
        context.updateSession(for: userId) { session in
            session.profileDraft?.lookingFor = pref
            session.state = .profile(.enteringBio)
        }
        await Presenter.answerCallback(query: query, context: context)
        // Confirm selection, then ask next question
        await Presenter.confirmPreferencesAndAskBio(pref: pref, chatId: userId, context: context)
    }

    // MARK: - Bio

    static func processBio(text: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let userId = message.from?.id else { return }
        let bio = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard bio.count >= 10 else {
            await Presenter.bioTooShort(chatId: message.chat.id, context: context)
            return
        }
        guard bio.count <= 600 else {
            await Presenter.bioTooLong(chatId: message.chat.id, context: context)
            return
        }

        context.updateSession(for: userId) { session in
            session.profileDraft?.bio = bio
            session.state = .profile(.uploadingPhoto)
        }
        await Presenter.photoPrompt(chatId: message.chat.id, context: context)
    }

    // MARK: - Photo

    static func processPhoto(fileId: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let userId = message.from?.id else { return }

        context.updateSession(for: userId) { session in
            session.profileDraft?.photoFileId = fileId
            session.state = .profile(.previewing)
        }

        let draft = context.session(for: userId).profileDraft
        await Presenter.preview(chatId: message.chat.id, draft: draft, context: context)
    }

    // MARK: - Preview Actions

    static func submitProfile(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let user = query.from
        let userId = user.id

        guard let draft = context.session(for: userId).profileDraft,
              let city = draft.city,
              let goal = draft.goal,
              let lookingFor = draft.lookingFor,
              let bio = draft.bio,
              let photoFileId = draft.photoFileId
        else {
            context.sessions.reset(userId: userId)
            await Presenter.error(chatId: userId, context: context)
            await Presenter.answerCallback(query: query, context: context)
            return
        }

        do {
            // 1. Get user's UUID from database
            guard let dbUser = try await context.users.find(telegramId: userId) else {
                await Presenter.error(chatId: userId, context: context)
                await Presenter.answerCallback(query: query, context: context)
                return
            }

            // 2. Create moderation request
            guard let moderation = try await context.moderations.createPending(
                userId: dbUser.id,
                name: user.username ?? "User \(userId)",
                description: bio,
                photoFileId: photoFileId,
                city: city
            ) else {
                await Presenter.error(chatId: userId, context: context)
                await Presenter.answerCallback(query: query, context: context)
                return
            }

            // 3. Send to admin group for review
            if let adminChatId = context.adminChatId {
                _ = await Presenter.sendToModeration(
                    adminChatId: adminChatId,
                    moderationId: moderation.id,
                    username: user.username,
                    city: city,
                    goal: goal,
                    lookingFor: lookingFor,
                    bio: bio,
                    photoFileId: photoFileId,
                    context: context
                )
            }

            context.sessions.reset(userId: userId)
            await Presenter.submitted(chatId: userId, context: context)
        } catch {
            context.logger.error("Failed to submit profile: \(error)")
            await Presenter.error(chatId: userId, context: context)
        }

        await Presenter.answerCallback(query: query, context: context)
    }

    static func showEditMenu(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let telegramId = query.from.id
        let session = context.session(for: telegramId)

        // If no draft exists, try to load from approved profile or rejected moderation
        if session.profileDraft == nil {
            do {
                if let user = try await context.users.find(telegramId: telegramId) {
                    // First try to load from approved profile
                    if let profile = try await context.profiles.find(userId: user.id) {
                        context.updateSession(for: telegramId) { session in
                            session.profileDraft = ProfileDraft(
                                city: profile.city,
                                goal: .both,  // Default, user can change
                                lookingFor: .any,  // Default, user can change
                                bio: profile.description,
                                photoFileId: profile.photoFileId
                            )
                            session.state = .profile(.editing(.city))  // Mark as editing mode
                        }
                    }
                    // Otherwise try rejected moderation
                    else if let rejected = try await context.moderations.findLatestRejected(userId: user.id) {
                        context.updateSession(for: telegramId) { session in
                            session.profileDraft = ProfileDraft(
                                city: rejected.city,
                                goal: .both,
                                lookingFor: .any,
                                bio: rejected.description,
                                photoFileId: rejected.photoFileId
                            )
                            session.state = .profile(.previewing)
                        }
                    }
                }
            } catch {
                context.logger.error("Failed to load profile for editing: \(error)")
            }
        }

        await Presenter.editMenu(chatId: telegramId, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }

    static func backToPreview(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id

        do {
            if let user = try await context.users.find(telegramId: userId),
               let profile = try await context.profiles.find(userId: user.id) {
                // User has approved profile - show it with just edit button
                context.sessions.reset(userId: userId)
                await MainMenuFlow.Presenter.showProfile(
                    chatId: userId,
                    profile: profile,
                    user: user,
                    context: context
                )
                await Presenter.answerCallback(query: query, context: context)
                return
            }
        } catch {
            context.logger.error("Failed to load profile: \(error)")
        }

        // User is creating new profile - show preview if complete
        let draft = context.session(for: userId).profileDraft
        if let draft, draft.isComplete {
            context.setState(.profile(.previewing), for: userId)
            await Presenter.preview(chatId: userId, draft: draft, context: context)
        } else {
            context.sessions.reset(userId: userId)
        }

        await Presenter.answerCallback(query: query, context: context)
    }

    static func editField(field: ProfileField, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id
        context.setState(.profile(.editing(field)), for: userId)

        switch field {
        case .city: await Presenter.cityPrompt(chatId: userId, context: context)
        case .goal: await Presenter.goalSelection(chatId: userId, context: context)
        case .preferences: await Presenter.preferencesSelection(chatId: userId, context: context)
        case .bio: await Presenter.bioPrompt(chatId: userId, context: context)
        case .photo: await Presenter.photoPrompt(chatId: userId, context: context)
        }

        await Presenter.answerCallback(query: query, context: context)
    }

    // MARK: - Editing (from preview)

    static func processEditedCity(text: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let userId = message.from?.id else { return }
        let city = text.trimmingCharacters(in: .whitespacesAndNewlines)

        context.updateSession(for: userId) { session in
            session.profileDraft?.city = city
            session.state = .profile(.previewing)
        }

        let draft = context.session(for: userId).profileDraft
        await Presenter.preview(chatId: message.chat.id, draft: draft, context: context)
    }

    static func processEditedBio(text: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let userId = message.from?.id else { return }
        let bio = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard bio.count >= 10 else {
            await Presenter.bioTooShort(chatId: message.chat.id, context: context)
            return
        }
        guard bio.count <= 600 else {
            await Presenter.bioTooLong(chatId: message.chat.id, context: context)
            return
        }

        context.updateSession(for: userId) { session in
            session.profileDraft?.bio = bio
            session.state = .profile(.previewing)
        }

        let draft = context.session(for: userId).profileDraft
        await Presenter.preview(chatId: message.chat.id, draft: draft, context: context)
    }

    static func processEditedPhoto(fileId: String, message: Components.Schemas.Message, context: UpdateContext) async {
        guard let userId = message.from?.id else { return }

        context.updateSession(for: userId) { session in
            session.profileDraft?.photoFileId = fileId
            session.state = .profile(.previewing)
        }

        let draft = context.session(for: userId).profileDraft
        await Presenter.preview(chatId: message.chat.id, draft: draft, context: context)
    }

    static func processEditedGoal(goal: ProfileGoal, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id
        context.updateSession(for: userId) { session in
            session.profileDraft?.goal = goal
            session.state = .profile(.previewing)
        }

        let draft = context.session(for: userId).profileDraft
        await Presenter.preview(chatId: userId, draft: draft, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }

    static func processEditedPreferences(pref: LookingForPreference, query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        let userId = query.from.id
        context.updateSession(for: userId) { session in
            session.profileDraft?.lookingFor = pref
            session.state = .profile(.previewing)
        }

        let draft = context.session(for: userId).profileDraft
        await Presenter.preview(chatId: userId, draft: draft, context: context)
        await Presenter.answerCallback(query: query, context: context)
    }
}
