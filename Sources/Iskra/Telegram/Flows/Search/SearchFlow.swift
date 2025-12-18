import Foundation

/// Handles the search/browsing flow for discovering profiles.
/// Entry: /search command or "Start Surfing" button
/// Flow: show profile → like/pass/message/report → next profile → repeat
enum SearchFlow {

    // MARK: - Types

    /// Result of recording a like action.
    enum LikeResult {
        case liked
        case matched(MatchDTO)
    }

    /// Candidate profile with user info for display.
    struct Candidate: Sendable {
        let profile: ProfileDTO
        let user: UserDTO
    }

    // MARK: - Entry Points

    /// Starts the search flow, showing the first candidate or appropriate message.
    static func start(
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            // Verify user eligibility
            guard let user = try await context.users.find(telegramId: chatId) else {
                await Presenter.showNotRegistered(chatId: chatId, context: context)
                return
            }

            // Check if user has an approved profile
            guard user.status == .active,
                  try await context.profiles.exists(userId: user.id) else {
                await Presenter.showNoProfile(chatId: chatId, context: context)
                return
            }

            // Start browsing
            context.setState(.search(.browsing), for: chatId)
            await showNextCandidate(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to start search: \(error)")
            await Presenter.showError(chatId: chatId, context: context)
        }
    }

    /// Stops the search flow and returns to idle.
    static func stop(
        chatId: Int64,
        context: UpdateContext
    ) async {
        context.setState(.idle, for: chatId)
        await Presenter.showStopped(chatId: chatId, context: context)
    }

    // MARK: - Profile Actions

    /// Records a like and checks for mutual match.
    static func like(
        targetUserId: UUID,
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            // Record the like
            _ = try await context.interactions.record(
                actorId: user.id,
                targetId: targetUserId,
                action: .like
            )

            // Check for mutual like (match)
            if try await context.interactions.hasLiked(actorId: targetUserId, targetId: user.id) {
                // It's a match!
                let match = try await context.matches.create(
                    userA: user.id,
                    userB: targetUserId,
                    matchType: .relationship // Default, could be from filter
                )

                // Notify both users with contact info
                await notifyMatch(
                    matchId: match?.id,
                    user1: user,
                    user2Id: targetUserId,
                    context: context
                )
            } else {
                // Notify target about the like
                await notifyLike(
                    from: user,
                    toUserId: targetUserId,
                    context: context
                )
            }

            // Show next candidate
            await showNextCandidate(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to record like: \(error)")
        }
    }

    /// Likes back from incoming view - creates a match.
    static func likeBack(
        actorId: UUID,
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            // Record the like back
            _ = try await context.interactions.record(
                actorId: user.id,
                targetId: actorId,
                action: .like
            )

            // Hide the incoming interaction
            _ = try await context.interactions.hide(actorId: actorId, targetId: user.id)

            // Create match (mutual like confirmed)
            let match = try await context.matches.create(
                userA: user.id,
                userB: actorId,
                matchType: .relationship
            )

            // Notify both users with contact info
            await notifyMatch(
                matchId: match?.id,
                user1: user,
                user2Id: actorId,
                context: context
            )

            // Show next incoming
            await showNextIncoming(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to like back: \(error)")
        }
    }

    /// Records a pass and shows next candidate.
    static func pass(
        targetUserId: UUID,
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            // Record the pass
            _ = try await context.interactions.record(
                actorId: user.id,
                targetId: targetUserId,
                action: .pass
            )

            // Show next candidate
            await showNextCandidate(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to record pass: \(error)")
        }
    }

    /// Initiates message composition to a profile.
    static func startMessage(
        targetUserId: UUID,
        chatId: Int64,
        messageId: Int64,
        context: UpdateContext
    ) async {
        context.setState(.search(.composingMessage(targetId: targetUserId)), for: chatId)
        await Presenter.showMessagePrompt(
            chatId: chatId,
            messageId: messageId,
            targetUserId: targetUserId,
            context: context
        )
    }

    /// Sends a message (envelope) to a profile.
    static func sendMessage(
        text: String,
        targetUserId: UUID,
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            // Record the envelope with message
            _ = try await context.interactions.record(
                actorId: user.id,
                targetId: targetUserId,
                action: .envelope,
                message: text
            )

            // Notify target
            await notifyMessage(
                from: user,
                toUserId: targetUserId,
                message: text,
                context: context
            )

            // Return to browsing and show next
            context.setState(.search(.browsing), for: chatId)
            await Presenter.showMessageSent(chatId: chatId, context: context)
            await showNextCandidate(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to send message: \(error)")
        }
    }

    /// Records a report against a profile.
    static func report(
        targetUserId: UUID,
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            // Record the report
            _ = try await context.interactions.record(
                actorId: user.id,
                targetId: targetUserId,
                action: .report
            )

            // TODO: Notify admins about the report

            await Presenter.showReported(chatId: chatId, context: context)
            await showNextCandidate(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to record report: \(error)")
        }
    }

    // MARK: - Incoming Interactions

    /// Shows incoming likes and messages for the user.
    static func showIncoming(
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            let incoming = try await context.interactions.findIncoming(
                targetId: user.id,
                actions: [.like, .envelope]
            )

            if incoming.isEmpty {
                await Presenter.showNoIncoming(chatId: chatId, context: context)
            } else {
                context.setState(.search(.viewingIncoming), for: chatId)
                await showNextIncoming(chatId: chatId, userId: user.id, context: context)
            }
        } catch {
            context.logger.error("Failed to show incoming: \(error)")
        }
    }

    /// Shows the next incoming interaction.
    static func showNextIncoming(
        chatId: Int64,
        userId: UUID,
        context: UpdateContext
    ) async {
        do {
            let incoming = try await context.interactions.findIncoming(
                targetId: userId,
                actions: [.like, .envelope]
            )

            guard let next = incoming.first else {
                context.setState(.search(.browsing), for: chatId)
                await Presenter.showNoMoreIncoming(chatId: chatId, context: context)
                return
            }

            // Get the actor's profile
            guard let profile = try await context.profiles.find(userId: next.actorId),
                  let actorUser = try await context.users.find(id: next.actorId) else {
                // Skip invalid entries
                _ = try await context.interactions.hide(id: next.id)
                await showNextIncoming(chatId: chatId, userId: userId, context: context)
                return
            }

            await Presenter.showIncomingProfile(
                chatId: chatId,
                profile: profile,
                user: actorUser,
                interaction: next,
                context: context
            )
        } catch {
            context.logger.error("Failed to show next incoming: \(error)")
        }
    }

    /// Responds to an incoming like/message.
    static func respondToIncoming(
        interactionId: UUID,
        action: InteractionAction,
        chatId: Int64,
        context: UpdateContext
    ) async {
        do {
            guard let user = try await context.users.find(telegramId: chatId) else { return }

            // Hide the incoming interaction (mark as seen)
            _ = try await context.interactions.hide(id: interactionId)

            // Get the interaction to find who sent it
            // Note: We'd need to add a method to get by ID including hidden
            // For now, we'll pass the actorId through the callback

            await showNextIncoming(chatId: chatId, userId: user.id, context: context)
        } catch {
            context.logger.error("Failed to respond to incoming: \(error)")
        }
    }

    // MARK: - Private Helpers

    /// Fetches and displays the next candidate profile.
    private static func showNextCandidate(
        chatId: Int64,
        userId: UUID,
        context: UpdateContext
    ) async {
        do {
            // Get user's filters
            let filter = try await context.filters.find(userId: userId)
                ?? FilterDTO(
                    userId: userId,
                    targetGenders: [.male, .female],
                    ageMin: 16,
                    ageMax: 99,
                    lookingFor: [.friendship, .relationship]
                )

            // Get already interacted users
            let excludedIds = try await context.interactions.getInteractedUserIds(actorId: userId)

            // Find candidates
            let candidates = try await context.profiles.findCandidates(
                for: userId,
                filters: filter,
                excludedUserIds: excludedIds,
                limit: 1
            )

            guard let candidate = candidates.first else {
                // No more candidates
                context.setState(.search(.noProfiles), for: chatId)
                await Presenter.showNoProfiles(chatId: chatId, context: context)
                return
            }

            // Get the candidate's user info
            guard let candidateUser = try await context.users.find(id: candidate.userId) else {
                // Shouldn't happen, but handle gracefully
                context.logger.warning("Candidate profile without user: \(candidate.userId)")
                await showNextCandidate(chatId: chatId, userId: userId, context: context)
                return
            }

            await Presenter.showProfile(
                chatId: chatId,
                profile: candidate,
                user: candidateUser,
                context: context
            )
        } catch {
            context.logger.error("Failed to show next candidate: \(error)")
            await Presenter.showError(chatId: chatId, context: context)
        }
    }

    // MARK: - Notifications

    /// Notifies a user about a new like.
    private static func notifyLike(
        from actor: UserDTO,
        toUserId: UUID,
        context: UpdateContext
    ) async {
        do {
            guard let target = try await context.users.find(id: toUserId) else { return }

            await Presenter.sendLikeNotification(
                toTelegramId: target.telegramId,
                fromUser: actor,
                context: context
            )
        } catch {
            context.logger.error("Failed to notify like: \(error)")
        }
    }

    /// Notifies a user about a new message.
    private static func notifyMessage(
        from actor: UserDTO,
        toUserId: UUID,
        message: String,
        context: UpdateContext
    ) async {
        do {
            guard let target = try await context.users.find(id: toUserId) else { return }

            await Presenter.sendMessageNotification(
                toTelegramId: target.telegramId,
                fromUser: actor,
                message: message,
                context: context
            )
        } catch {
            context.logger.error("Failed to notify message: \(error)")
        }
    }

    /// Notifies both users about a match with contact sharing.
    private static func notifyMatch(
        matchId: UUID?,
        user1: UserDTO,
        user2Id: UUID,
        context: UpdateContext
    ) async {
        do {
            guard let user2 = try await context.users.find(id: user2Id) else { return }

            // Get profiles for display names
            let profile1 = try await context.profiles.find(userId: user1.id)
            let profile2 = try await context.profiles.find(userId: user2.id)

            // Notify user2 with user1's contact
            await Presenter.sendMatchWithContact(
                toTelegramId: user2.telegramId,
                matchedUser: user1,
                matchedProfile: profile1,
                isMuted: user1.isMuted,
                context: context
            )

            // Notify user1 with user2's contact
            await Presenter.sendMatchWithContact(
                toTelegramId: user1.telegramId,
                matchedUser: user2,
                matchedProfile: profile2,
                isMuted: user2.isMuted,
                context: context
            )
        } catch {
            context.logger.error("Failed to notify match: \(error)")
        }
    }
}
