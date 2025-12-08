import Fluent
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
    private let client: Client
    private let db: any Database
    private let sessions: SessionStorage
    private let adminChatId: Int64?

    init(router: UpdateRouter, client: Client, db: any Database, sessions: SessionStorage, adminChatId: Int64?) {
        self.router = router
        self.client = client
        self.db = db
        self.sessions = sessions
        self.adminChatId = adminChatId
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
            client: client,
            db: req.db,
            sessions: sessions,
            adminChatId: adminChatId
        )

        // Route update — O(1) dispatch
        await router.route(update, context: context)

        // Telegram expects 200 OK to acknowledge receipt
        return .ok
    }
}
