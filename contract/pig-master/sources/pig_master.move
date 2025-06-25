/// Pig Master Game Contract
///
/// This contract handles the details of the Pig game scoring.  It allows us to easily track what's going on in the game
/// implementations.
module pig_master_addr::pig_master {

    use std::option;
    use std::option::Option;
    use std::signer;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::aggregator_v2;
    use aptos_framework::event::emit;

    /// Function is not implemented.
    const E_NOT_IMPLEMENTED: u64 = 1;

    /// Points to win the game are currently set to 100, we may change it to be lower to be a faster game.
    const POINTS_TO_WIN: u64 = 20;

    const MAX_U64: u64 = 18446744073709551615;

    /// Global game state, contains all the stats of all users
    /// and their top scores.  Note that this currently is not an ordered scoreboard.
    struct GameState has key {
        stats: SmartTable<address, UserStats>,
        top_result: Option<GameEndResult>,
        total_games_played: aggregator_v2::Aggregator<u64>,
        total_players: aggregator_v2::Aggregator<u64>,
    }

    /// Stats of a specific user along the way
    struct UserStats has store {
        top_result: GameResult,
        games_played: u64,
    }

    /// A standardized game result that is returned when a game is completed
    struct GameResult has store, copy, drop {
        score: u64,
        rounds: u64,
        turns: u64,
    }

    #[event]
    /// Event emitted when a game ends, used for indexing purposes
    struct GameEndResult has store, copy, drop {
        user: address,
        result: GameResult,
    }

    /// Initializes the game state to ensure that there will always be stats captured.
    fun init_module(deployer: &signer) {
        initialize(deployer)
    }

    /// Private function to initialize the game state, to be used by the init_module function
    /// and the test-only function.
    fun initialize(deployer: &signer) {
        let game_state = GameState {
            stats: smart_table::new<address, UserStats>(),
            total_games_played: aggregator_v2::create_aggregator_with_value(0, MAX_U64),
            total_players: aggregator_v2::create_aggregator_with_value(0, MAX_U64),
            top_result: option::none(),
        };
        move_to(deployer, game_state);
    }

    #[test_only]
    /// This is a test-only function to initialize the game state
    /// It can be used in tests to ensure the game state is set up correctly
    public fun initialize_for_test(deployer: &signer) {
        initialize(deployer);
    }

    // ======================== Entry (Write) functions ========================

    /// Registers a complete game
    public fun complete_game(
        user: &signer,
        score: u64,
        rounds: u64,
        turns: u64,
    ): GameResult acquires GameState {
        let user_address = signer::address_of(user);
        let game_state = &mut GameState[@pig_master_addr];

        // Standardized game result
        let result = GameResult {
            score,
            rounds,
            turns
        };

        if (!game_state.stats.contains(user_address)) {
            // If the user does not exist, create a new entry
            game_state.stats.add(user_address, UserStats {
                top_result: result,
                games_played: 1,
            });
            aggregator_v2::add(&mut game_state.total_players, 1);
        } else {
            // If the user exists, update their stats
            let user_stats = game_state.stats.borrow_mut(user_address);
            if (user_stats.top_result.turns > result.turns) {
                user_stats.top_result = result;
            } else if (user_stats.top_result.turns == result.turns && user_stats.top_result.rounds > result.rounds) {
                user_stats.top_result = result;
            };
            user_stats.games_played += 1;
        };

        if (game_state.top_result.is_none()) {
            game_state.top_result = option::some(GameEndResult {
                user: user_address,
                result
            });
        } else if (game_state.top_result.borrow().result.turns > result.turns) {
            game_state.top_result = option::some(GameEndResult {
                user: user_address,
                result
            });
        } else if (game_state.top_result.borrow().result.turns == result.turns && game_state.top_result.borrow(
        ).result.rounds > result.rounds) {
            game_state.top_result = option::some(GameEndResult {
                user: user_address,
                result
            });
        };

        aggregator_v2::add(&mut game_state.total_games_played, 1);

        // Emit an event for indexing ends of games
        emit(GameEndResult {
            user: signer::address_of(user),
            result
        });

        result
    }

    // ======================== View (Read) Functions ========================

    #[view]
    /// Convenience function to get the points required to win the game
    /// This is currently set to 100, but can be adjusted in the future.
    public fun points_to_win(): u64 {
        POINTS_TO_WIN
    }

    #[view]
    /// Return the user's top score result across all games
    public fun user_top_score(user: address): Option<GameResult> acquires GameState {
        let game_state = &GameState[@pig_master_addr];
        if (!game_state.stats.contains(user)) {
            option::none()
        } else {
            option::some(
                game_state.stats.borrow(user).top_result
            )
        }
    }

    #[view]
    public fun global_top_score(): Option<GameEndResult> acquires GameState {
        let game_state = &GameState[@pig_master_addr];
        game_state.top_result
    }

    #[view]
    /// Return the user's total number of games played
    public fun user_games_played(user: address): Option<u64> acquires GameState {
        let game_state = &GameState[@pig_master_addr];
        if (!game_state.stats.contains(user)) {
            option::none()
        } else {
            option::some(
                game_state.stats.borrow(user).games_played
            )
        }
    }

    #[view]
    public fun total_games_played(): u64 acquires GameState {
        let game_state = &GameState[@pig_master_addr];
        aggregator_v2::read(&game_state.total_games_played)
    }

    #[view]
    public fun total_players(): u64 acquires GameState {
        let game_state = &GameState[@pig_master_addr];
        aggregator_v2::read(&game_state.total_players)
    }

    public fun score(self: &GameResult): u64 {
        self.score
    }

    public fun rounds(self: &GameResult): u64 {
        self.rounds
    }

    public fun turns(self: &GameResult): u64 {
        self.turns
    }
}
