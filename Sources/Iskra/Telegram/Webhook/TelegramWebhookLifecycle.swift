import Vapor

/// Manages Telegram webhook lifecycle: deletes old webhook on startup, sets new one.
struct TelegramWebhookLifecycle: LifecycleHandler {
    let config: TelegramConfiguration

    func didBoot(_ app: Application) throws {
        guard config.mode == .webhook else { return }

        Task {
            await setupWebhook(app: app)
        }
    }

    func shutdown(_ app: Application) {
        guard config.mode == .webhook, config.deleteWebhookOnStart else { return }

        // Best-effort cleanup on shutdown
        Task {
            await deleteWebhook(app: app, dropPendingUpdates: false)
        }
    }

    private func setupWebhook(app: Application) async {
        let logger = app.logger

        // Delete existing webhook if configured
        if config.deleteWebhookOnStart {
            logger.info("Webhook: deleting existing")
            await deleteWebhook(app: app, dropPendingUpdates: true)
        }

        // Set new webhook if URL is configured
        guard let webhookURL = config.webhookURL else {
            logger.warning("Webhook: URL not configured")
            return
        }

        logger.info("Webhook: setting", metadata: ["url": "\(webhookURL)"])
        await setWebhook(app: app, url: webhookURL)
    }

    private func deleteWebhook(app: Application, dropPendingUpdates: Bool) async {
        do {
            let client = buildClient()
            let response = try await client.deleteWebhook(
                body: .json(.init(drop_pending_updates: dropPendingUpdates))
            )

            switch response {
            case .ok(let ok):
                switch ok.body {
                case .json(let json):
                    if json.ok {
                        app.logger.info("Webhook: deleted")
                    } else {
                        app.logger.warning("Webhook: delete returned ok=false")
                    }
                }
            case .badRequest(let error):
                app.logger.error("Delete webhook failed (400): \(error)")
            case .unauthorized(let error):
                app.logger.error("Delete webhook failed (401): \(error)")
            case .undocumented(let statusCode, _):
                app.logger.error("Delete webhook failed with status: \(statusCode)")
            }
        } catch {
            app.logger.error("Failed to delete webhook: \(error)")
        }
    }

    private func setWebhook(app: Application, url: String) async {
        do {
            let client = buildClient()
            let response = try await client.setWebhook(
                body: .json(.init(
                    url: url,
                    drop_pending_updates: config.deleteWebhookOnStart,
                    secret_token: config.webhookSecretToken
                ))
            )

            switch response {
            case .ok(let ok):
                switch ok.body {
                case .json(let json):
                    if json.ok {
                        app.logger.info("Webhook: configured", metadata: ["url": "\(url)"])
                    } else {
                        app.logger.warning("Webhook: set returned ok=false")
                    }
                }
            case .badRequest(let error):
                app.logger.error("Set webhook failed (400): \(error)")
            case .unauthorized(let error):
                app.logger.error("Set webhook failed (401): \(error)")
            case .undocumented(let statusCode, _):
                app.logger.error("Set webhook failed with status: \(statusCode)")
            }
        } catch {
            app.logger.error("Failed to set webhook: \(error)")
        }
    }

    private func buildClient() -> Client {
        TelegramClientFactory.makeClient(botToken: config.botToken)
    }
}
