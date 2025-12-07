import Vapor

/// Controller responsible for receiving Telegram Bot API webhook updates.
///
/// Authentication is handled by `BotAuthenticationMiddleware` (separation of concerns).
///
/// Performance characteristics:
/// - JSON decoding: O(n) where n = payload size (unavoidable)
/// - Update routing: O(1) type dispatch + O(1) command/callback lookup
struct TelegramWebhookController: RouteCollection {
    private let router: UpdateRouter
    private let botToken: String

    init(router: UpdateRouter, botToken: String) {
        self.router = router
        self.botToken = botToken
    }

    func boot(routes: any RoutesBuilder) throws {
        let webhook = routes.grouped("webhook")
        webhook.post("telegram", use: handleUpdate)
    }

    /// Handles incoming Telegram webhook POST requests.
    @Sendable
    private func handleUpdate(req: Request) async throws -> HTTPStatus {
        // Decode update — O(n) where n = payload size
        let update: Components.Schemas.Update
        do {
            update = try req.content.decode(Components.Schemas.Update.self)
        } catch {
            req.logger.error("Failed to decode Update: \(error)")
            throw Abort(.badRequest, reason: "Invalid Update payload")
        }

        // Create request-scoped context
        let context = UpdateContext(
            updateId: update.update_id,
            logger: req.logger,
            botToken: botToken
        )

        // Route update — O(1) dispatch
        await router.route(update, context: context)

        // Telegram expects 200 OK to acknowledge receipt
        return .ok
    }
}
