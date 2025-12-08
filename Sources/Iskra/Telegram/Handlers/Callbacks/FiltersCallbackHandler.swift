import Foundation

/// Handles filter-related callback queries.
/// Prefix: "filter"
/// Callbacks:
/// - filter:menu - Show filter menu
/// - filter:show:gender - Show gender options
/// - filter:show:age - Show age options
/// - filter:gender:{own|opposite|any} - Select gender filter
/// - filter:age:{peers|young|mid|mature|any} - Select age filter
/// - filter:done - Complete filter setup
struct FiltersCallbackHandler: CallbackHandler {
    let prefix = "filter"

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

        guard let payload = parsed.payload else {
            // No payload means show menu
            await SearchSettingsFlow.showMenu(
                chatId: chatId,
                messageId: messageId,
                context: context
            )
            await SearchSettingsFlow.Presenter.answerCallback(query: query, context: context)
            return
        }

        // Parse action from payload
        let parts = payload.split(separator: ":", maxSplits: 1)
        let action = String(parts[0])
        let value = parts.count > 1 ? String(parts[1]) : nil

        switch action {
        case "menu":
            await SearchSettingsFlow.showMenu(
                chatId: chatId,
                messageId: messageId,
                context: context
            )

        case "show":
            guard let messageId, let subaction = value else { return }
            switch subaction {
            case "gender":
                await SearchSettingsFlow.showGenderOptions(
                    chatId: chatId,
                    messageId: messageId,
                    context: context
                )
            case "age":
                await SearchSettingsFlow.showAgeOptions(
                    chatId: chatId,
                    messageId: messageId,
                    context: context
                )
            default:
                break
            }

        case "gender":
            guard let messageId, let option = value else { return }
            await SearchSettingsFlow.selectGender(
                option: option,
                chatId: chatId,
                messageId: messageId,
                context: context
            )

        case "age":
            guard let messageId, let option = value else { return }
            if option == "custom" {
                await SearchSettingsFlow.showCustomAgePrompt(
                    chatId: chatId,
                    messageId: messageId,
                    context: context
                )
            } else {
                await SearchSettingsFlow.selectAge(
                    option: option,
                    chatId: chatId,
                    messageId: messageId,
                    context: context
                )
            }

        case "done":
            await SearchSettingsFlow.done(chatId: chatId, context: context)

        default:
            context.logger.warning("Unknown filter action: \(action)")
        }

        await SearchSettingsFlow.Presenter.answerCallback(query: query, context: context)
    }
}
