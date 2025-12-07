import Vapor

/// Storage key for the polling task handle.
private struct PollingTaskKey: StorageKey {
    typealias Value = Task<Void, Never>
}

/// Lifecycle handler for managing the Telegram polling service.
struct TelegramPollingLifecycle: LifecycleHandler {
    let pollingService: TelegramPollingService

    func didBoot(_ app: Application) throws {
        let task = pollingService.start()
        app.storage[PollingTaskKey.self] = task
    }

    func shutdown(_ app: Application) {
        app.logger.info("Requesting Telegram long polling shutdown")
        app.storage[PollingTaskKey.self]?.cancel()
        app.storage[PollingTaskKey.self] = nil
    }
}
