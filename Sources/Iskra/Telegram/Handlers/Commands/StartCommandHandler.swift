/// Handles the /start command.
/// Entry point for new users (onboarding) and returning users.
struct StartCommandHandler: CommandHandler {
    func handle(_ message: Components.Schemas.Message, command: BotCommand, context: UpdateContext) async {
        context.logger.info("Start command", metadata: [
            "chat_id": "\(message.chat.id)",
            "user_id": "\(message.from?.id ?? 0)",
            "deep_link": "\(command.arguments ?? "")"
        ])
        _ = await OnboardingFlow.start(message: message, context: context)
    }
}
