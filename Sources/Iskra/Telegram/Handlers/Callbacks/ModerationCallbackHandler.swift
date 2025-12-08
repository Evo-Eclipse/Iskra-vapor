import Foundation

/// Handles moderation callbacks from admin group (prefix: "mod").
///
/// Callback data:
/// - `mod:approve:{uuid}` — approve profile
/// - `mod:reject:{uuid}` — show rejection reasons
/// - `mod:reason:{uuid}:{reason}` — reject with specific reason
struct ModerationCallbackHandler: CallbackHandler {
    func handle(_ query: Components.Schemas.CallbackQuery, parsed: ParsedCallback, context: UpdateContext) async {
        guard let payload = parsed.payload else {
            await answerWithError(query: query, context: context)
            return
        }

        let parts = payload.split(separator: ":", maxSplits: 1)
        guard let action = parts.first else {
            await answerWithError(query: query, context: context)
            return
        }

        switch action {
        case "approve":
            guard parts.count == 2,
                  let moderationId = UUID(uuidString: String(parts[1]))
            else {
                await answerWithError(query: query, context: context)
                return
            }
            await approveProfile(moderationId: moderationId, query: query, context: context)

        case "reject":
            guard parts.count == 2,
                  let moderationId = UUID(uuidString: String(parts[1]))
            else {
                await answerWithError(query: query, context: context)
                return
            }
            await showRejectionReasons(moderationId: moderationId, query: query, context: context)

        case "reason":
            // Format: reason:{uuid}:{reasonKey}
            let reasonParts = String(parts[1]).split(separator: ":", maxSplits: 1)
            guard reasonParts.count == 2,
                  let moderationId = UUID(uuidString: String(reasonParts[0]))
            else {
                await answerWithError(query: query, context: context)
                return
            }
            let reason = String(reasonParts[1])
            await rejectProfile(moderationId: moderationId, reason: reason, query: query, context: context)

        case "back":
            guard parts.count == 2,
                  let moderationId = UUID(uuidString: String(parts[1]))
            else {
                await answerWithError(query: query, context: context)
                return
            }
            await showApproveRejectButtons(moderationId: moderationId, query: query, context: context)

        default:
            context.logger.warning("Unknown moderation action: \(action)")
            await answerWithError(query: query, context: context)
        }
    }

    // MARK: - Approval

    private func approveProfile(
        moderationId: UUID,
        query: Components.Schemas.CallbackQuery,
        context: UpdateContext
    ) async {
        do {
            // 1. Approve moderation
            guard let moderation = try await context.moderations.approve(id: moderationId) else {
                context.logger.warning("Moderation not found: \(moderationId)")
                await answerWithText(query: query, text: L10n["moderation.admin.notFound"], context: context)
                return
            }

            // 2. Create/update profile
            _ = try await context.profiles.upsert(from: moderation)

            // 3. Get user's Telegram ID to notify them
            guard let user = try await context.users.find(id: moderation.userId) else {
                context.logger.warning("User not found for moderation: \(moderationId)")
                await answerWithText(query: query, text: L10n["moderation.admin.userNotFound"], context: context)
                return
            }

            // 4. Notify user
            await notifyUserApproved(telegramId: user.telegramId, context: context)

            // 5. Update admin message
            await updateAdminMessage(query: query, status: L10n["moderation.admin.statusApproved"], context: context)
            await answerWithText(query: query, text: L10n["moderation.admin.approved"], context: context)

        } catch {
            context.logger.error("Failed to approve moderation: \(error)")
            await answerWithText(query: query, text: "Error: \(error.localizedDescription)", context: context)
        }
    }

    // MARK: - Button Management

    private func showApproveRejectButtons(
        moderationId: UUID,
        query: Components.Schemas.CallbackQuery,
        context: UpdateContext
    ) async {
        var kb = KeyboardBuilder(type: .inline)
        kb.button(text: L10n["moderation.admin.approve"], callbackData: "mod:approve:\(moderationId.uuidString)")
        kb.button(text: L10n["moderation.admin.reject"], callbackData: "mod:reject:\(moderationId.uuidString)")

        if let messageData = query.message {
            let chatDict = messageData.value["chat"] as? [String: Any]
            let chatId = chatDict?["id"] as? Int64 ?? (chatDict?["id"] as? Int).map { Int64($0) }
            let messageId = (messageData.value["message_id"] as? Int64) ?? (messageData.value["message_id"] as? Int).map { Int64($0) }

            if let chatId, let messageId {
                do {
                    _ = try await context.client.editMessageReplyMarkup(body: .json(.init(
                        chat_id: .case1(chatId),
                        message_id: messageId,
                        reply_markup: kb.buildInline()
                    )))
                } catch {
                    context.logger.error("Failed to restore approve/reject buttons: \(error)")
                }
            }
        }
        await answerCallback(query: query, context: context)
    }

    // MARK: - Rejection

    private func showRejectionReasons(
        moderationId: UUID,
        query: Components.Schemas.CallbackQuery,
        context: UpdateContext
    ) async {
        // Build rejection reason buttons
        var kb = KeyboardBuilder(type: .inline)
        kb.button(text: L10n["moderation.reasons.photo.button"], callbackData: "mod:reason:\(moderationId.uuidString):photo")
        kb.row()
        kb.button(text: L10n["moderation.reasons.bio.button"], callbackData: "mod:reason:\(moderationId.uuidString):bio")
        kb.row()
        kb.button(text: L10n["moderation.reasons.inappropriate.button"], callbackData: "mod:reason:\(moderationId.uuidString):inappropriate")
        kb.row()
        kb.button(text: L10n["moderation.reasons.other.button"], callbackData: "mod:reason:\(moderationId.uuidString):other")
        kb.row()
        kb.button(text: L10n["common.back"], callbackData: "mod:back:\(moderationId.uuidString)")

        // Edit inline keyboard
        if let inlineMessageId = query.inline_message_id {
            do {
                _ = try await context.client.editMessageReplyMarkup(body: .json(.init(
                    inline_message_id: inlineMessageId,
                    reply_markup: kb.buildInline()
                )))
            } catch {
                context.logger.error("Failed to edit inline message: \(error)")
            }
        } else if let messageData = query.message {
            let chatDict = messageData.value["chat"] as? [String: Any]
            let chatId = chatDict?["id"] as? Int64 ?? (chatDict?["id"] as? Int).map { Int64($0) }
            let messageId = (messageData.value["message_id"] as? Int64) ?? (messageData.value["message_id"] as? Int).map { Int64($0) }

            if let chatId, let messageId {
                do {
                    _ = try await context.client.editMessageReplyMarkup(body: .json(.init(
                        chat_id: .case1(chatId),
                        message_id: messageId,
                        reply_markup: kb.buildInline()
                    )))
                } catch {
                    context.logger.error("Failed to edit message reply markup: \(error)")
                }
            }
        }
        await answerCallback(query: query, context: context)
    }

    private func rejectProfile(
        moderationId: UUID,
        reason: String,
        query: Components.Schemas.CallbackQuery,
        context: UpdateContext
    ) async {
        let reasonText = rejectionReasonText(for: reason)

        do {
            // 1. Reject moderation
            guard let moderation = try await context.moderations.reject(id: moderationId, reason: reasonText) else {
                context.logger.warning("Moderation not found: \(moderationId)")
                await answerWithText(query: query, text: L10n["moderation.admin.notFound"], context: context)
                return
            }

            // 2. Get user's Telegram ID to notify them
            guard let user = try await context.users.find(id: moderation.userId) else {
                context.logger.warning("User not found for moderation: \(moderationId)")
                await answerWithText(query: query, text: L10n["moderation.admin.userNotFound"], context: context)
                return
            }

            // 3. Notify user
            await notifyUserRejected(telegramId: user.telegramId, reason: reasonText, context: context)

            // 4. Update admin message
            let statusText = L10n["moderation.admin.statusRejected"].replacingOccurrences(of: "%@", with: reasonText)
            await updateAdminMessage(query: query, status: statusText, context: context)
            await answerWithText(query: query, text: L10n["moderation.admin.rejected"], context: context)

        } catch {
            context.logger.error("Failed to reject moderation: \(error)")
            await answerWithText(query: query, text: "Error: \(error.localizedDescription)", context: context)
        }
    }

    private func rejectionReasonText(for key: String) -> String {
        let localized = L10n["moderation.reasons.\(key).text"]
        // If key not found, L10n returns "[keyPath]" wrapped in brackets
        return localized.hasPrefix("[") ? key : localized
    }

    // MARK: - User Notifications

    private func notifyUserApproved(telegramId: Int64, context: UpdateContext) async {
        let text = L10n["moderation.approved"]
        do {
            _ = try await context.client.sendMessage(body: .json(.init(
                chat_id: .case1(telegramId),
                text: text
            )))
        } catch {
            context.logger.error("Failed to notify user of approval: \(error)")
        }
    }

    private func notifyUserRejected(telegramId: Int64, reason: String, context: UpdateContext) async {
        let text = L10n["moderation.rejected"]
            .replacingOccurrences(of: "%@", with: reason)

        // Build "Edit Profile" button so user can fix issues
        var kb = KeyboardBuilder(type: .inline)
        kb.button(text: L10n["moderation.admin.editProfile"], callbackData: "profile:edit:menu")

        do {
            _ = try await context.client.sendMessage(body: .json(.init(
                chat_id: .case1(telegramId),
                text: text,
                reply_markup: .InlineKeyboardMarkup(kb.buildInline())
            )))
        } catch {
            context.logger.error("Failed to notify user of rejection: \(error)")
        }
    }

    // MARK: - Admin Message Updates

    private func updateAdminMessage(
        query: Components.Schemas.CallbackQuery,
        status: String,
        context: UpdateContext
    ) async {
        guard let messageData = query.message else { return }

        // Extract values from OpenAPIObjectContainer
        let chatId = messageData.value["chat"].flatMap { ($0 as? [String: Any])?["id"] as? Int64 }
        let messageId = messageData.value["message_id"] as? Int64
        let caption = messageData.value["caption"] as? String

        guard let chatId, let messageId, let caption else { return }

        let newCaption = "\(caption)\n\n\(status)"

        do {
            _ = try await context.client.editMessageCaption(body: .json(.init(
                chat_id: .case1(chatId),
                message_id: messageId,
                caption: newCaption,
                reply_markup: nil // Remove buttons
            )))
        } catch {
            context.logger.error("Failed to update admin message: \(error)")
        }
    }

    // MARK: - Helpers

    private func answerCallback(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        do {
            _ = try await context.client.answerCallbackQuery(body: .json(.init(callback_query_id: query.id)))
        } catch {
            context.logger.error("Failed to answer callback: \(error)")
        }
    }

    private func answerWithText(query: Components.Schemas.CallbackQuery, text: String, context: UpdateContext) async {
        do {
            _ = try await context.client.answerCallbackQuery(body: .json(.init(
                callback_query_id: query.id,
                text: text
            )))
        } catch {
            context.logger.error("Failed to answer callback: \(error)")
        }
    }

    private func answerWithError(query: Components.Schemas.CallbackQuery, context: UpdateContext) async {
        do {
            _ = try await context.client.answerCallbackQuery(body: .json(.init(
                callback_query_id: query.id,
                text: L10n.Errors.invalidCallback,
                show_alert: true
            )))
        } catch {
            context.logger.error("Failed to answer callback: \(error)")
        }
    }
}
