import Vapor

/// Long polling service for receiving Telegram updates.
///
/// Immutable struct that spawns a polling task. All mutable state
/// is local to the polling loop — no synchronization overhead.
struct TelegramPollingService: Sendable {
    private let config: TelegramConfiguration
    private let router: UpdateRouter
    private let logger: Logger
    private let sessions: SessionStorage

    /// Polling timeout in seconds (Telegram supports 0-50).
    private let timeout: Int64

    /// Maximum number of updates to retrieve per request.
    private let limit: Int64

    init(
        config: TelegramConfiguration,
        router: UpdateRouter,
        logger: Logger,
        sessions: SessionStorage,
        timeout: Int64 = 30,
        limit: Int64 = 100
    ) {
        self.config = config
        self.router = router
        self.logger = logger
        self.sessions = sessions
        self.timeout = min(max(timeout, 0), 50) // Clamp to 0-50
        self.limit = min(max(limit, 1), 100)    // Clamp to 1-100
    }

    /// Starts the polling loop and returns a handle to cancel it.
    func start() -> Task<Void, Never> {
        logger.info("Starting Telegram long polling", metadata: ["timeout": "\(timeout)s", "limit": "\(limit)"])

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
                        botToken: config.botToken,
                        sessions: sessions
                    )
                    await router.route(update, context: context)
                }
            } catch is CancellationError {
                break
            } catch {
                logger.error("Telegram long polling failed: \(error)")
                // Back off on errors to avoid hammering the API
                try? await Task.sleep(for: .seconds(5))
            }
        }

        logger.info("Telegram long polling stopped")
    }

    // MARK: - API Calls

    private func fetchUpdates(client: Client, offset: Int64) async throws -> [Components.Schemas.Update] {
        let response = try await client.getUpdates(
            body: .json(.init(offset: offset > 0 ? offset : nil, limit: limit, timeout: timeout))
        )
        return try response.extract(logger: logger).get()
    }

    private func deleteWebhookIfNeeded(client: Client) async {
        logger.info("Deleting Telegram webhook to enable long polling")
        do {
            let response = try await client.deleteWebhook(body: .json(.init(drop_pending_updates: false)))
            if response.extract(logger: logger).isSuccess {
                logger.info("Telegram webhook deleted; long polling enabled")
            }
        } catch {
            logger.error("Failed to delete Telegram webhook", metadata: ["error": "\(error)"])
        }
    }

    private func buildClient() -> Client {
        TelegramClientFactory.makeClient(botToken: config.botToken)
    }
}
