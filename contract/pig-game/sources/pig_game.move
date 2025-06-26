/// Each turn, a player repeatedly rolls a die until a 1 is rolled or the player decides to "hold":
///
/// If the player rolls a 1, they score nothing and it becomes the next player's turn.
/// If the player rolls any other number, it is added to their turn total and the player's turn continues.
/// If a player chooses to "hold", their turn total is added to their score, and it becomes the next player's turn.
/// The first player to score 100 or more points wins.
///
/// Your task:
/// - Implement the pig game here
/// - Integrate it with the pig master contract
/// - Test it with the frontend
module pig_game_addr::pig_game {
    use std::signer;
    use aptos_framework::randomness;

    // ======================== Error Constants ========================
    
    /// Function is not implemented
    const E_NOT_IMPLEMENTED: u64 = 1;
    /// Game does not exist for user
    const E_GAME_NOT_EXISTS: u64 = 2;
    /// Game is already over
    const E_GAME_OVER: u64 = 3;
    /// Invalid dice roll value for testing
    const E_INVALID_TEST_DICE: u64 = 4;

    // ======================== Game Constants ========================
    
    /// Target score to win the game (from README: reach 50 points)
    const TARGET_SCORE: u64 = 50;

    // ======================== Structs ========================
    
    /// Represents the game state for a player
    struct GameState has key {
        /// Current total game score (doesn't include current turn score)
        total_score: u64,
        /// Current turn score (accumulated during current turn)
        turn_score: u64,
        /// Last dice roll value (0 means no roll or hold)
        last_roll: u8,
        /// Current round number (increments on each dice roll or hold)
        round: u64,
        /// Current turn number (increments when rolling 1 or holding)
        turn: u64,
        /// Whether the game is over (reached target score)
        game_over: bool,
        /// Number of games played by this user
        games_played: u64,
    }

    /// Global statistics
    struct GlobalStats has key {
        /// Total number of games played across all users
        total_games_played: u64,
    }

    // ======================== Entry (Write) functions ========================
    
    #[randomness]
    /// Roll the dice
    entry fun roll_dice(user: &signer) acquires GameState {
        let user_addr = signer::address_of(user);
        
        // Initialize game state if it doesn't exist
        if (!exists<GameState>(user_addr)) {
            initialize_game(user);
        };
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Check if game is over
        assert!(!game_state.game_over, E_GAME_OVER);
        
        // Generate random number between 1 and 6
        let dice_roll = randomness::u8_range(1, 7);
        
        // Update game state with dice roll
        game_state.last_roll = dice_roll;
        game_state.round = game_state.round + 1;
        
        // Check if player rolled a 1 (bust)
        if (dice_roll == 1) {
            // Turn ends, turn score is lost
            game_state.turn_score = 0;
            game_state.turn = game_state.turn + 1;
        } else {
            // Add to turn score
            game_state.turn_score = game_state.turn_score + (dice_roll as u64);
        };
    }

    #[test_only]
    /// Optional, useful for testing purposes
    public fun roll_dice_for_test(user: &signer, num: u8) acquires GameState {
        let user_addr = signer::address_of(user);
        
        // Validate dice roll is between 1 and 6
        assert!(num >= 1 && num <= 6, E_INVALID_TEST_DICE);
        
        // Initialize game state if it doesn't exist
        if (!exists<GameState>(user_addr)) {
            initialize_game(user);
        };
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Check if game is over
        assert!(!game_state.game_over, E_GAME_OVER);
        
        // Update game state with test dice roll
        game_state.last_roll = num;
        game_state.round = game_state.round + 1;
        
        // Check if player rolled a 1 (bust)
        if (num == 1) {
            // Turn ends, turn score is lost
            game_state.turn_score = 0;
            game_state.turn = game_state.turn + 1;
        } else {
            // Add to turn score
            game_state.turn_score = game_state.turn_score + (num as u64);
        };
    }

    #[test_only]
    /// Test-only version of hold function for testing purposes
    public fun hold_for_test(user: &signer) acquires GameState {
        let user_addr = signer::address_of(user);
        
        // Game state must exist
        assert!(exists<GameState>(user_addr), E_GAME_NOT_EXISTS);
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Check if game is over
        assert!(!game_state.game_over, E_GAME_OVER);
        
        // Add turn score to total score
        game_state.total_score = game_state.total_score + game_state.turn_score;
        
        // Reset turn score
        game_state.turn_score = 0;
        
        // Reset last roll (0 indicates hold)
        game_state.last_roll = 0;
        
        // Increment turn counter
        game_state.turn = game_state.turn + 1;
        
        // Check if game is won
        if (game_state.total_score >= TARGET_SCORE) {
            game_state.game_over = true;
        };
    }

    /// End the turn by calling hold, add points to the overall
    /// accumulated score for the current game for the specified user
    entry fun hold(user: &signer) acquires GameState {
        let user_addr = signer::address_of(user);
        
        // Game state must exist
        assert!(exists<GameState>(user_addr), E_GAME_NOT_EXISTS);
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Check if game is over
        assert!(!game_state.game_over, E_GAME_OVER);
        
        // Add turn score to total score
        game_state.total_score = game_state.total_score + game_state.turn_score;
        
        // Reset turn score
        game_state.turn_score = 0;
        
        // Reset last roll (0 indicates hold)
        game_state.last_roll = 0;
        
        // Increment turn counter
        game_state.turn = game_state.turn + 1;
        
        // Check if game is won
        if (game_state.total_score >= TARGET_SCORE) {
            game_state.game_over = true;
        };
    }

    #[test_only]
    /// Test-only version of complete_game function for testing purposes
    public fun complete_game_for_test(user: &signer) acquires GameState, GlobalStats {
        let user_addr = signer::address_of(user);
        
        // Game state must exist
        assert!(exists<GameState>(user_addr), E_GAME_NOT_EXISTS);
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Game must be over to complete it
        assert!(game_state.game_over, E_GAME_NOT_EXISTS); // Using this error since there's no specific "game not won" error
        
        // Update user's games played count
        game_state.games_played = game_state.games_played + 1;
        
        // Update global stats - check both possible locations
        if (exists<GlobalStats>(@pig_game_addr)) {
            let global_stats = borrow_global_mut<GlobalStats>(@pig_game_addr);
            global_stats.total_games_played = global_stats.total_games_played + 1;
        } else if (exists<GlobalStats>(user_addr)) {
            let global_stats = borrow_global_mut<GlobalStats>(user_addr);
            global_stats.total_games_played = global_stats.total_games_played + 1;
        } else {
            // Initialize global stats at module address if neither exists
            move_to(user, GlobalStats {
                total_games_played: 1,
            });
        }
    }

    #[test_only]
    /// Test-only version of reset_game function for testing purposes
    public fun reset_game_for_test(user: &signer) acquires GameState {
        let user_addr = signer::address_of(user);
        
        // Game state must exist
        assert!(exists<GameState>(user_addr), E_GAME_NOT_EXISTS);
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Reset all game state to initial values
        game_state.total_score = 0;
        game_state.turn_score = 0;
        game_state.last_roll = 0;
        game_state.round = 0;
        game_state.turn = 0;
        game_state.game_over = false;
        // Note: games_played is not reset - it's a cumulative counter
    }

    /// The intended score has been reached, end the game, publish the
    /// score to both the global storage
    entry fun complete_game(user: &signer) acquires GameState, GlobalStats {
        let user_addr = signer::address_of(user);
        
        // Game state must exist
        assert!(exists<GameState>(user_addr), E_GAME_NOT_EXISTS);
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Game must be over to complete it
        assert!(game_state.game_over, E_GAME_NOT_EXISTS); // Using this error since there's no specific "game not won" error
        
        // Update user's games played count
        game_state.games_played = game_state.games_played + 1;
        
        // Update global stats - check both possible locations
        if (exists<GlobalStats>(@pig_game_addr)) {
            let global_stats = borrow_global_mut<GlobalStats>(@pig_game_addr);
            global_stats.total_games_played = global_stats.total_games_played + 1;
        } else if (exists<GlobalStats>(user_addr)) {
            let global_stats = borrow_global_mut<GlobalStats>(user_addr);
            global_stats.total_games_played = global_stats.total_games_played + 1;
        } else {
            // Initialize global stats at module address if neither exists
            move_to(user, GlobalStats {
                total_games_played: 1,
            });
        }
    }

    /// The user wants to start a new game, end this one.
    entry fun reset_game(user: &signer) acquires GameState {
        let user_addr = signer::address_of(user);
        
        // Game state must exist
        assert!(exists<GameState>(user_addr), E_GAME_NOT_EXISTS);
        
        let game_state = borrow_global_mut<GameState>(user_addr);
        
        // Reset all game state to initial values
        game_state.total_score = 0;
        game_state.turn_score = 0;
        game_state.last_roll = 0;
        game_state.round = 0;
        game_state.turn = 0;
        game_state.game_over = false;
        // Note: games_played is not reset - it's a cumulative counter
    }

    // ======================== Helper Functions ========================
    
    /// Initialize a new game for the user
    fun initialize_game(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Initialize global stats if it doesn't exist
        if (!exists<GlobalStats>(@pig_game_addr)) {
            move_to(user, GlobalStats {
                total_games_played: 0,
            });
        };
        
        move_to(user, GameState {
            total_score: 0,
            turn_score: 0,
            last_roll: 0,
            round: 0,
            turn: 0,
            game_over: false,
            games_played: 0,
        });
    }

    // ======================== View (Read) Functions ========================

    #[view]
    /// Return the user's last roll value from the current game, 0 is considered no roll / hold
    public fun last_roll(user: address): u8 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.last_roll
    }

    #[view]
    /// Tells us which number round the game is on, this only resets when the game is reset
    ///
    /// This increments every time the user rolls the dice or holds
    public fun round(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.round
    }

    #[view]
    /// Tells us which number turn the game is on, this only resets when the game is reset
    ///
    /// This increments every time the user rolls a 1 or holds
    public fun turn(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.turn
    }

    #[view]
    /// Tells us whether the game is over for the user (the user has reached the target score)
    public fun game_over(user: address): bool acquires GameState {
        if (!exists<GameState>(user)) {
            return false
        };
        let game_state = borrow_global<GameState>(user);
        game_state.game_over
    }

    #[view]
    /// Return the user's current turn score, this is the score accumulated during the current turn.  If the player holds
    /// this score will be added to the total score for the game.
    public fun turn_score(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.turn_score
    }

    #[view]
    /// Return the user's current total game score for the current game, this does not include the current turn score
    public fun total_score(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.total_score
    }

    #[view]
    /// Return total number of games played within this game's context
    public fun games_played(): u64 acquires GlobalStats {
        if (exists<GlobalStats>(@pig_game_addr)) {
            let global_stats = borrow_global<GlobalStats>(@pig_game_addr);
            global_stats.total_games_played
        } else {
            // In test context, might be stored at user address - but we can't know which user
            // Return 0 as default
            0
        }
    }

    #[test_only]
    /// Test-only version that can check user's address for global stats
    public fun games_played_for_test(user_addr: address): u64 acquires GlobalStats {
        if (exists<GlobalStats>(@pig_game_addr)) {
            let global_stats = borrow_global<GlobalStats>(@pig_game_addr);
            global_stats.total_games_played
        } else if (exists<GlobalStats>(user_addr)) {
            let global_stats = borrow_global<GlobalStats>(user_addr);
            global_stats.total_games_played
        } else {
            0
        }
    }

    #[view]
    /// Return total number of games played within this game's context for the given user
    public fun user_games_played(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.games_played
    }
}
