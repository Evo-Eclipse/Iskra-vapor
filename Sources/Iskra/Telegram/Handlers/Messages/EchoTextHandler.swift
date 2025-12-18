/// Text handler that echoes received messages back to the user.
struct EchoTextHandler: TextMessageHandler {
    func handle(_ message: Components.Schemas.Message, context: UpdateContext) async {
        guard let text = message.text else { return }

        context.logger.info(
            "Text message received",
            metadata: [
                "chat_id": "\(message.chat.id)",
                "user_id": "\(message.from?.id ?? 0)",
                "username": "\(message.from?.username ?? "")",
                "text_preview": "\(String(text.prefix(100)))"
            ]
        )

        // Echo message back
        do {
            _ = try await context.client.sendMessage(body: .json(.init(
                chat_id: .case1(message.chat.id),
                text: text
            )))
        } catch {
            context.logger.error("Failed to echo message: \(error)")
        }
    }
}
