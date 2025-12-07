/// Handles callbacks with "action:" prefix.
///
/// Example callback data: "action:confirm:123" or "action:cancel"
struct ActionCallbackHandler: CallbackHandler {
    func handle(
        _ query: Components.Schemas.CallbackQuery,
        parsed: ParsedCallback,
        context: UpdateContext
    ) async {
        context.logger.info(
            "Action callback received",
            metadata: [
                "callback_id": "\(parsed.id)",
                "payload": "\(parsed.payload ?? "none")",
                "user_id": "\(query.from.id)"
            ]
        )

        // TODO: Answer callback query to remove loading state
        // TODO: Handle the specific action based on parsed.payload
    }
}
