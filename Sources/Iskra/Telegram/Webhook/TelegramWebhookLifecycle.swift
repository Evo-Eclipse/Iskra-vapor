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
            logger.info("Requesting Telegram webhook deletion before setup")
            await deleteWebhook(app: app, dropPendingUpdates: true)
        }

        // Set new webhook if URL is configured
        guard let webhookURL = config.webhookURL else {
            logger.warning("Skipping webhook setup: webhook URL is not configured")
            return
        }

        logger.info("Configuring Telegram webhook", metadata: ["url": "\(webhookURL)"])
        await setWebhook(app: app, url: webhookURL)
    }

    private func deleteWebhook(app: Application, dropPendingUpdates: Bool) async {
        do {
            let response = try await buildClient().deleteWebhook(
                body: .json(.init(drop_pending_updates: dropPendingUpdates))
            )
            if response.extract(logger: app.logger).isSuccess {
                app.logger.info("Telegram webhook deleted")
            }
        } catch {
            app.logger.error("Telegram webhook deletion failed", metadata: ["error": "\(error)"])
        }
    }

    private func setWebhook(app: Application, url: String) async {
        do {
            let response = try await buildClient().setWebhook(
                body: .json(.init(url: url, drop_pending_updates: config.deleteWebhookOnStart, secret_token: config.webhookSecretToken))
            )
            if response.extract(logger: app.logger).isSuccess {
                app.logger.info("Telegram webhook configured", metadata: ["url": "\(url)"])
            }
        } catch {
            app.logger.error("Telegram webhook setup failed", metadata: ["error": "\(error)"])
        }
    }

    private func buildClient() -> Client {
        TelegramClientFactory.makeClient(botToken: config.botToken)
    }
}
