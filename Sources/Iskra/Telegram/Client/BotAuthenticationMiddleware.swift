import Vapor

/// Middleware to authenticate webhook requests from Telegram
struct BotAuthenticationMiddleware: AsyncMiddleware {
    let expectedToken: String?

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard request.url.path.hasPrefix("/webhook") else {
            return try await next.respond(to: request)
        }

        // If no secret is configured, skip validation
        guard let token = expectedToken else {
            return try await next.respond(to: request)
        }

        // Validate secret token from Telegram
        guard let receivedToken = request.headers["X-Telegram-Bot-Api-Secret-Token"].first,
              receivedToken == token else {
            request.logger.warning("Webhook request rejected: invalid or missing secret token")
            throw Abort(.unauthorized, reason: "Invalid secret token")
        }

        return try await next.respond(to: request)
    }
}