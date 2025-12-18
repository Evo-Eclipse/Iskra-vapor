/// Media handler that echoes received stickers back to the user.
struct EchoStickerHandler: MediaHandler {
    func handle(_ message: Components.Schemas.Message, mediaType: MediaType, context: UpdateContext) async {
        guard let sticker = message.sticker else { return }

        // Log user information
        context.logger.info(
            "Sticker received",
            metadata: [
                "chat_id": "\(message.chat.id)",
                "user_id": "\(message.from?.id ?? 0)",
                "username": "\(message.from?.username ?? "")",
                "sticker_emoji": "\(sticker.emoji ?? "")"
            ]
        )

        // Echo sticker back
        do {
            _ = try await context.client.sendSticker(body: .json(.init(
                chat_id: .case1(message.chat.id),
                sticker: .case2(sticker.file_id)
            )))
        } catch {
            context.logger.error("Failed to echo sticker: \(error)")
        }
    }
}
