import Logging

enum TelegramResult<T: Sendable>: Sendable {
    case success(T)
    case failure(TelegramError)

    @inlinable var value: T? {
        if case .success(let value) = self { value } else { nil }
    }

    @inlinable var isSuccess: Bool {
        if case .success = self { true } else { false }
    }

    @inlinable func get() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    @inlinable func map<U: Sendable>(_ transform: (T) -> U) -> TelegramResult<U> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }

    @inlinable func flatMap<U: Sendable>(_ transform: (T) -> TelegramResult<U>) -> TelegramResult<U> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }

    @discardableResult
    func logged(_ logger: Logger, operation: String, default defaultValue: T) -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            logger.error("\(operation): \(error.localizedDescription)")
            return defaultValue
        }
    }
}

// MARK: - Extensions

extension Operations.getUpdates.Output {
    func extract(logger: Logger) -> TelegramResult<[Components.Schemas.Update]> {
        switch self {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let json):
                if json.ok {
                    return .success(json.result)
                }
                logger.error("Telegram getUpdates returned ok=false")
                return .failure(.apiError(statusCode: 200, description: "ok=false"))
            }
        case .badRequest:
            return .failure(.apiError(statusCode: 400, description: "Bad request"))
        case .unauthorized:
            return .failure(.authenticationFailed)
        case .undocumented(let code, _):
            return .failure(.apiError(statusCode: code, description: nil))
        }
    }
}

extension Operations.deleteWebhook.Output {
    func extract(logger: Logger) -> TelegramResult<Bool> {
        switch self {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let json):
                if json.ok {
                    return .success(true)
                }
                logger.error("Telegram deleteWebhook returned ok=false")
                return .failure(.apiError(statusCode: 200, description: "ok=false"))
            }
        case .badRequest:
            return .failure(.apiError(statusCode: 400, description: "Bad request"))
        case .unauthorized:
            return .failure(.authenticationFailed)
        case .undocumented(let code, _):
            return .failure(.apiError(statusCode: code, description: nil))
        }
    }
}

extension Operations.setWebhook.Output {
    func extract(logger: Logger) -> TelegramResult<Bool> {
        switch self {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let json):
                if json.ok {
                    return .success(true)
                }
                logger.error("Telegram setWebhook returned ok=false")
                return .failure(.apiError(statusCode: 200, description: "ok=false"))
            }
        case .badRequest:
            return .failure(.apiError(statusCode: 400, description: "Bad request"))
        case .unauthorized:
            return .failure(.authenticationFailed)
        case .undocumented(let code, _):
            return .failure(.apiError(statusCode: code, description: nil))
        }
    }
}
