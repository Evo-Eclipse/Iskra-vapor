import Fluent
import SQLKit

/// Creates the profiles table.
/// FK dependency: users
struct CreateProfiles: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Profile.schema)
            .field(.userId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.displayName, .string, .required)
            .field(.description, .string, .required)
            .field(.photoFileId, .string, .required)
            .field(.city, .string, .required)
            .field(.updatedAt, .datetime)
            .create()

        // Add primary key constraint via raw SQL
        guard let sqlForPK = database as? any SQLDatabase else { return }
        try await sqlForPK.raw("""
            ALTER TABLE profiles ADD CONSTRAINT pk_profiles PRIMARY KEY (user_id);
        """).run()

        // Create index for city-based searches
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE INDEX idx_profiles_city ON profiles(city);
        """).run()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Profile.schema).delete()
    }
}
