import Foundation
import Vapor
import OpenAPIAsyncHTTPClient

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
            logger.info("Deleting existing webhook before setup...")
            await deleteWebhook(app: app, dropPendingUpdates: true)
        }

        // Set new webhook if URL is configured
        guard let webhookURL = config.webhookURL else {
            logger.warning("Webhook mode enabled but TELEGRAM_WEBHOOK_URL not set")
            return
        }

        logger.info("Setting webhook to: \(webhookURL)")
        await setWebhook(app: app, url: webhookURL)
    }

    private func deleteWebhook(app: Application, dropPendingUpdates: Bool) async {
        do {
            let client = buildClient(app: app)
            let response = try await client.deleteWebhook(
                body: .json(.init(drop_pending_updates: dropPendingUpdates))
            )

            switch response {
            case .ok(let ok):
                switch ok.body {
                case .json(let json):
                    if json.ok {
                        app.logger.info("Webhook deleted successfully")
                    } else {
                        app.logger.warning("Delete webhook returned ok=false")
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
            let client = buildClient(app: app)
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
                        app.logger.info("Webhook set successfully to: \(url)")
                    } else {
                        app.logger.warning("Set webhook returned ok=false")
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

    private func buildClient(app: Application) -> Client {
        // Telegram API requires: https://api.telegram.org/bot{token}/method
        let serverURL = URL(string: "https://api.telegram.org/bot\(config.botToken)")!
        return Client(
            serverURL: serverURL,
            transport: AsyncHTTPClientTransport()
        )
    }
}
