import Fluent
import SQLKit

/// Creates the interactions table.
/// FK dependencies: users (actor, target)
struct CreateInteractions: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Interaction.schema)
            .id()
            .field(.actorId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.targetId, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field(.action, .custom("interaction_action_type"), .required)
            .field(.message, .string)
            .field(.isHidden, .bool, .required)
            .field(.createdAt, .datetime, .required)
            .unique(on: .actorId, .targetId)
            .create()

        // Create indexes for interaction queries
        guard let sql = database as? any SQLDatabase else { return }
        try await sql.raw("""
            CREATE INDEX idx_interactions_actor_id ON interactions(actor_id);
            CREATE INDEX idx_interactions_target_id ON interactions(target_id);
            CREATE INDEX idx_interactions_actor_action ON interactions(actor_id, action) WHERE is_hidden = false;
        """).run()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Interaction.schema).delete()
    }
}
