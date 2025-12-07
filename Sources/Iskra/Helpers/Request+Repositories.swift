import Vapor

// MARK: - Repository Access

extension Request {
    /// User repository for account operations.
    var users: UserRepository {
        UserRepository(database: db)
    }

    /// Profile repository for showcase operations.
    var profiles: ProfileRepository {
        ProfileRepository(database: db)
    }

    /// Moderation repository for admin queue operations.
    var moderations: ModerationRepository {
        ModerationRepository(database: db)
    }

    /// Filter repository for search settings operations.
    var filters: FilterRepository {
        FilterRepository(database: db)
    }

    /// Interaction repository for like/pass/envelope operations.
    var interactions: InteractionRepository {
        InteractionRepository(database: db)
    }

    /// Match repository for mutual like operations.
    var matches: MatchRepository {
        MatchRepository(database: db)
    }
}
