import Logging

enum TelegramResult<T: Sendable>: Sendable {
    case success(T)
    case failure(TelegramError)

    @inlinable var value: T? {
        if case .success(let v) = self { v } else { nil }
    }

    @inlinable var isSuccess: Bool {
        if case .success = self { true } else { false }
    }

    @inlinable func get() throws -> T {
        switch self {
        case .success(let v): v
        case .failure(let e): throw e
        }
    }

    @inlinable func map<U: Sendable>(_ transform: (T) -> U) -> TelegramResult<U> {
        switch self {
        case .success(let v): .success(transform(v))
        case .failure(let e): .failure(e)
        }
    }

    @inlinable func flatMap<U: Sendable>(_ transform: (T) -> TelegramResult<U>) -> TelegramResult<U> {
        switch self {
        case .success(let v): transform(v)
        case .failure(let e): .failure(e)
        }
    }

    func logged(_ logger: Logger, operation: String, default defaultValue: T) -> T {
        switch self {
        case .success(let v):
            return v
        case .failure(let e):
            logger.error("\(operation): \(e.localizedDescription)")
            return defaultValue
        }
    }
}

// MARK: - Extensions

extension Operations.getUpdates.Output {
    func extract(logger: Logger) -> TelegramResult<[Components.Schemas.Update]> {
        switch self {
        case .ok(let ok):
            switch ok.body {
            case .json(let json):
                json.ok ? .success(json.result) : .failure(.apiError(statusCode: 200, description: "ok=false"))
            }
        case .badRequest:
            .failure(.apiError(statusCode: 400, description: "Bad request"))
        case .unauthorized:
            .failure(.authenticationFailed)
        case .undocumented(let code, _):
            .failure(.apiError(statusCode: code, description: nil))
        }
    }
}

extension Operations.deleteWebhook.Output {
    func extract(logger: Logger) -> TelegramResult<Bool> {
        switch self {
        case .ok(let ok):
            switch ok.body {
            case .json(let json):
                json.ok ? .success(true) : .failure(.apiError(statusCode: 200, description: "ok=false"))
            }
        case .badRequest:
            .failure(.apiError(statusCode: 400, description: "Bad request"))
        case .unauthorized:
            .failure(.authenticationFailed)
        case .undocumented(let code, _):
            .failure(.apiError(statusCode: code, description: nil))
        }
    }
}

extension Operations.setWebhook.Output {
    func extract(logger: Logger) -> TelegramResult<Bool> {
        switch self {
        case .ok(let ok):
            switch ok.body {
            case .json(let json):
                json.ok ? .success(true) : .failure(.apiError(statusCode: 200, description: "ok=false"))
            }
        case .badRequest:
            .failure(.apiError(statusCode: 400, description: "Bad request"))
        case .unauthorized:
            .failure(.authenticationFailed)
        case .undocumented(let code, _):
            .failure(.apiError(statusCode: code, description: nil))
        }
    }
}
