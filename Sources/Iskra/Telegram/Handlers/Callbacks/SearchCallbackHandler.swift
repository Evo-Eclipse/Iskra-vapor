import Foundation

/// Handles search-related callback queries.
/// Callback format: search:{action}:{payload}
struct SearchCallbackHandler: CallbackHandler {
    let prefix = "search"

    func handle(
        _ query: Components.Schemas.CallbackQuery,
        parsed: ParsedCallback,
        context: UpdateContext
    ) async {
        let chatId = query.from.id

        // Extract message ID for editing
        let messageId: Int64? = {
            guard let messageData = query.message else { return nil }
            if let mid = messageData.value["message_id"] as? Int64 {
                return mid
            }
            if let mid = messageData.value["message_id"] as? Int {
                return Int64(mid)
            }
            return nil
        }()

        // Parse payload: action:value or just action
        let parts = parsed.payload?.split(separator: ":", maxSplits: 1).map(String.init) ?? []
        let action = parts.first ?? ""
        let value = parts.count > 1 ? parts[1] : nil

        switch action {
        case "start":
            await SearchFlow.start(chatId: chatId, context: context)

        case "stop":
            await SearchFlow.stop(chatId: chatId, context: context)

        case "continue":
            await SearchFlow.start(chatId: chatId, context: context)

        case "like":
            if let targetId = value.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.like(
                    targetUserId: targetId,
                    chatId: chatId,
                    context: context
                )
            }

        case "pass":
            if let targetId = value.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.pass(
                    targetUserId: targetId,
                    chatId: chatId,
                    context: context
                )
            }

        case "message":
            if let targetId = value.flatMap({ UUID(uuidString: $0) }),
               let msgId = messageId {
                await SearchFlow.startMessage(
                    targetUserId: targetId,
                    chatId: chatId,
                    messageId: msgId,
                    context: context
                )
            }

        case "cancelMessage":
            context.setState(.search(.browsing), for: chatId)
            await SearchFlow.start(chatId: chatId, context: context)

        case "report":
            if let targetId = value.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.report(
                    targetUserId: targetId,
                    chatId: chatId,
                    context: context
                )
            }

        case "incoming":
            await SearchFlow.showIncoming(chatId: chatId, context: context)

        case "incoming:like":
            // value contains actorId
            if let actorId = value.flatMap({ UUID(uuidString: $0) }) {
                // Like back
                await SearchFlow.like(
                    targetUserId: actorId,
                    chatId: chatId,
                    context: context
                )
            }

        case "incoming:pass":
            // value contains actorId - pass and continue
            if let actorId = value.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.pass(
                    targetUserId: actorId,
                    chatId: chatId,
                    context: context
                )
            }

        case "incoming:skip":
            // value contains interaction ID - skip without action
            if let interactionId = value.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.respondToIncoming(
                    interactionId: interactionId,
                    action: .pass,
                    chatId: chatId,
                    context: context
                )
            }

        default:
            context.logger.warning("Unknown search action: \(action)")
        }

        await SearchFlow.Presenter.answerCallback(query: query, context: context)
    }
}
