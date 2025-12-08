import Fluent
import SQLKit

/// Creates the moderations table.
/// FK dependency: users
struct CreateModerations: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Moderation.schema)
            .id()
            .field(.userId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.status, .string, .required)
            .field(.name, .string, .required)
            .field(.description, .string, .required)
            .field(.photoFileId, .string, .required)
            .field(.city, .string, .required)
            .field(.adminComment, .string)
            .field(.createdAt, .datetime, .required)
            .field(.closedAt, .datetime)
            .create()

        // Create indexes for moderation queue queries
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("CREATE INDEX idx_moderations_user_id ON moderations(user_id)").run()
        try await sql.raw("CREATE INDEX idx_moderations_status ON moderations(status)").run()
        try await sql.raw("CREATE INDEX idx_moderations_status_created ON moderations(status, created_at)").run()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Moderation.schema).delete()
    }
}
