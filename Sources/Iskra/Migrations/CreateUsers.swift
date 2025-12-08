import Fluent
import SQLKit

/// Creates the users table.
/// No foreign key dependencies.
struct CreateUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field(.telegramId, .int64, .required)
            .field(.telegramUsername, .string)
            .field(.birthDate, .date, .required)
            .field(.gender, .string, .required)
            .field(.status, .string, .required)
            .field(.isMuted, .bool, .required)
            .field(.createdAt, .datetime, .required)
            .unique(on: .telegramId)
            .create()

        // Create index for fast Telegram ID lookups
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE INDEX idx_users_telegram_id ON users(telegram_id);
            CREATE INDEX idx_users_status ON users(status);
        """).run()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
