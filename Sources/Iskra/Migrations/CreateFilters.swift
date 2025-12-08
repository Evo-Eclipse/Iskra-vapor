import Fluent
import SQLKit

/// Creates the filters table.
/// FK dependency: users
struct CreateFilters: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Filter.schema)
            .field(.userId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.targetGenders, .array(of: .string), .required)
            .field(.ageMin, .int16, .required)
            .field(.ageMax, .int16, .required)
            .field(.lookingFor, .array(of: .string), .required)
            .create()

        // Add primary key constraint via raw SQL
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            ALTER TABLE filters ADD CONSTRAINT pk_filters PRIMARY KEY (user_id);
        """).run()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Filter.schema).delete()
    }
}
