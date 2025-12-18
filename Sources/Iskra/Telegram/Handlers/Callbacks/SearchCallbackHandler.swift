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

        // Parse payload: supports action, action:value, or action:subaction:value
        guard let payload = parsed.payload else {
            context.logger.warning("Search callback missing payload")
            return
        }

        let components = payload.split(separator: ":").map(String.init)

        switch components.first {
        case "start":
            await SearchFlow.start(chatId: chatId, context: context)

        case "stop":
            await SearchFlow.stop(chatId: chatId, context: context)

        case "continue":
            await SearchFlow.start(chatId: chatId, context: context)

        case "like":
            if let targetId = components.dropFirst().first.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.like(
                    targetUserId: targetId,
                    chatId: chatId,
                    context: context
                )
            }

        case "pass":
            if let targetId = components.dropFirst().first.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.pass(
                    targetUserId: targetId,
                    chatId: chatId,
                    context: context
                )
            }

        case "message":
            if let targetId = components.dropFirst().first.flatMap({ UUID(uuidString: $0) }),
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
            if let targetId = components.dropFirst().first.flatMap({ UUID(uuidString: $0) }) {
                await SearchFlow.report(
                    targetUserId: targetId,
                    chatId: chatId,
                    context: context
                )
            }

        case "incoming":
            // Check for subaction: incoming:like:UUID or incoming:skip:UUID
            if components.count >= 3 {
                let subaction = components[1]
                let valueString = components[2]

                switch subaction {
                case "like":
                    if let actorId = UUID(uuidString: valueString) {
                        await SearchFlow.likeBack(
                            actorId: actorId,
                            chatId: chatId,
                            context: context
                        )
                    }
                case "skip":
                    if let interactionId = UUID(uuidString: valueString) {
                        await SearchFlow.respondToIncoming(
                            interactionId: interactionId,
                            action: .pass,
                            chatId: chatId,
                            context: context
                        )
                    }
                default:
                    context.logger.warning("Unknown incoming subaction: \(subaction)")
                }
            } else {
                // Just "incoming" - show incoming list
                await SearchFlow.showIncoming(chatId: chatId, context: context)
            }

        default:
            context.logger.warning("Unknown search action: \(components.first ?? "nil")")
        }

        await SearchFlow.Presenter.answerCallback(query: query, context: context)
    }
}
