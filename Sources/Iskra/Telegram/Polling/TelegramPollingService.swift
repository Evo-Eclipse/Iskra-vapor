import Vapor
import OpenAPIAsyncHTTPClient

/// Long polling service for receiving Telegram updates.
///
/// Immutable struct that spawns a polling task. All mutable state
/// is local to the polling loop — no synchronization overhead.
struct TelegramPollingService: Sendable {
    private let config: TelegramConfiguration
    private let router: UpdateRouter
    private let logger: Logger

    /// Polling timeout in seconds (Telegram supports 0-50).
    private let timeout: Int64

    /// Maximum number of updates to retrieve per request.
    private let limit: Int64

    init(
        config: TelegramConfiguration,
        router: UpdateRouter,
        logger: Logger,
        timeout: Int64 = 30,
        limit: Int64 = 100
    ) {
        self.config = config
        self.router = router
        self.logger = logger
        self.timeout = min(max(timeout, 0), 50) // Clamp to 0-50
        self.limit = min(max(limit, 1), 100)    // Clamp to 1-100
    }

    /// Starts the polling loop and returns a handle to cancel it.
    func start() -> Task<Void, Never> {
        logger.info("Starting Telegram long polling", metadata: [
            "timeout": "\(timeout)s",
            "limit": "\(limit)"
        ])

        return Task {
            await pollingLoop()
        }
    }

    // MARK: - Polling Loop

    private func pollingLoop() async {
        let client = buildClient()

        // Delete webhook first to enable polling mode
        await deleteWebhookIfNeeded(client: client)

        // Local mutable state — no synchronization needed
        var lastUpdateId: Int64 = 0

        while !Task.isCancelled {
            do {
                let updates = try await fetchUpdates(client: client, offset: lastUpdateId)

                for update in updates {
                    // Track last update ID for offset
                    if update.update_id >= lastUpdateId {
                        lastUpdateId = update.update_id + 1
                    }

                    // Route update through the same router as webhooks
                    let context = UpdateContext(
                        updateId: update.update_id,
                        logger: logger,
                        botToken: config.botToken
                    )
                    await router.route(update, context: context)
                }
            } catch is CancellationError {
                break
            } catch {
                logger.error("Polling error: \(error)")
                // Back off on errors to avoid hammering the API
                try? await Task.sleep(for: .seconds(5))
            }
        }

        logger.info("Polling loop stopped")
    }

    // MARK: - API Calls

    private func fetchUpdates(
        client: Client,
        offset: Int64
    ) async throws -> [Components.Schemas.Update] {
        let response = try await client.getUpdates(
            body: .json(.init(
                offset: offset > 0 ? offset : nil,
                limit: limit,
                timeout: timeout
            ))
        )

        switch response {
        case .ok(let ok):
            switch ok.body {
            case .json(let json):
                if json.ok {
                    return json.result
                } else {
                    logger.warning("getUpdates returned ok=false")
                    return []
                }
            }
        case .badRequest(let error):
            logger.error("getUpdates failed (400): \(error)")
            return []
        case .unauthorized(let error):
            logger.error("getUpdates failed (401): \(error)")
            throw TelegramError.authenticationFailed
        case .undocumented(let statusCode, _):
            logger.error("getUpdates failed with status: \(statusCode)")
            return []
        }
    }

    private func deleteWebhookIfNeeded(client: Client) async {
        logger.info("Deleting webhook to enable polling mode...")

        do {
            let response = try await client.deleteWebhook(
                body: .json(.init(drop_pending_updates: false))
            )

            switch response {
            case .ok(let ok):
                switch ok.body {
                case .json(let json):
                    if json.ok {
                        logger.info("Webhook deleted, polling mode active")
                    }
                }
            case .badRequest, .unauthorized, .undocumented:
                logger.warning("Failed to delete webhook, polling may not work")
            }
        } catch {
            logger.error("Error deleting webhook: \(error)")
        }
    }

    // MARK: - Client Factory

    private func buildClient() -> Client {
        guard let serverURL = URL(string: "https://api.telegram.org/bot\(config.botToken)") else {
            fatalError("Invalid Telegram bot token, unable to build API URL")
        }
        return Client(
            serverURL: serverURL,
            transport: AsyncHTTPClientTransport()
        )
    }
}
