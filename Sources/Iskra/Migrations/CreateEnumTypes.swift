import Fluent
import SQLKit

/// Creates PostgreSQL custom enum types.
/// Must run before any table migrations.
struct CreateEnumTypes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else {
            database.logger.warning("CreateEnumTypes requires SQLDatabase, skipping")
            return
        }

        try await sql.raw("CREATE TYPE gender_type AS ENUM ('male', 'female');").run()
        try await sql.raw("CREATE TYPE looking_for_type AS ENUM ('friendship', 'relationship');").run()
        try await sql.raw("CREATE TYPE interaction_action_type AS ENUM ('pass', 'like', 'envelope', 'report');").run()
        try await sql.raw("CREATE TYPE moderation_status_type AS ENUM ('pending', 'approved', 'rejected');").run()
        try await sql.raw("CREATE TYPE user_status_type AS ENUM ('active', 'paused', 'banned', 'archived');").run()
    }
    
    func revert(on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else {
            return
        }

        try await sql.raw("DROP TYPE IF EXISTS user_status_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS moderation_status_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS interaction_action_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS looking_for_type;").run()
        try await sql.raw("DROP TYPE IF EXISTS gender_type;").run()
    }
}
