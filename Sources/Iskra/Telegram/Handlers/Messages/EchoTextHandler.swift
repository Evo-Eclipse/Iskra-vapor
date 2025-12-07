/// Example text handler that logs received text messages.
///
/// Replace with your actual text processing logic.
struct EchoTextHandler: TextMessageHandler {
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async {
        guard let text = message.text else { return }

        context.logger.info(
            "Text message received",
            metadata: [
                "chat_id": "\(message.chat.id)",
                "user_id": "\(message.from?.id ?? 0)",
                "text_preview": "\(String(text.prefix(100)))"
            ]
        )

        // TODO: Process text or echo it back
    }
}
