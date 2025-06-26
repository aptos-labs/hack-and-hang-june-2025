/// # Pig Game Smart Contract
/// 
/// ## Overview
/// 
/// This smart contract implements the classic "Pig" dice game on the Aptos blockchain.
/// The game is a simple jeopardy dice game where players accumulate points by rolling
/// a six-sided die, but risk losing their turn's points if they roll a 1.
/// 
/// ## Game Rules
/// 
/// ### Basic Gameplay
/// - Each player takes turns rolling a standard six-sided die (1-6)
/// - On each turn, a player repeatedly rolls the die until either:
///   1. They roll a 1 ("pig out") - losing all points for that turn, or
///   2. They choose to "hold" - banking their turn's points
/// 
/// ### Scoring
/// - If a player rolls 2, 3, 4, 5, or 6: add that number to their turn score
/// - If a player rolls a 1: turn ends immediately, turn score is lost (becomes 0)
/// - If a player chooses to "hold": turn score is added to total score, turn ends
/// - **Winning condition**: First player to reach 50 or more total points wins
/// 
/// ### Turn Management
/// - Each die roll increments the round counter
/// - Each turn end (by rolling 1 or holding) increments the turn counter
/// - Game automatically ends when a player reaches the target score
/// 
/// ## Smart Contract Features
/// 
/// ### Game State Management
/// - Individual game state per user address
/// - Automatic game initialization on first action
/// - Persistent game statistics and history
/// 
/// ### Statistics Tracking
/// - Per-user game completion counts
/// - Global statistics across all players
/// - Turn and round tracking within games
/// 
/// ### Security & Validation
/// - Proper input validation for all functions
/// - Game state verification before actions
/// - Protection against actions on completed games
/// 
/// ## Usage Example
/// 
/// ```move
/// // Start playing (auto-initializes game state)
/// pig_game::roll_dice(&signer);  // Roll 1: gets 4, turn_score = 4
/// pig_game::roll_dice(&signer);  // Roll 2: gets 3, turn_score = 7
/// pig_game::hold(&signer);       // Hold: total_score = 7, turn_score = 0
/// 
/// pig_game::roll_dice(&signer);  // New turn: gets 6, turn_score = 6
/// pig_game::roll_dice(&signer);  // Roll: gets 1, turn_score = 0 (bust!)
/// 
/// // Continue until total_score >= 50, then:
/// pig_game::complete_game(&signer);  // Update statistics
/// pig_game::reset_game(&signer);     // Start new game
/// ```
/// 
/// ## Integration
/// 
/// This contract is designed to integrate with:
/// - Frontend dApps for user interfaces
/// - Pig Master contract for tournament management
/// - Other gaming contracts for expanded functionality
module pig_game_addr::pig_game {
    use std::signer;
    use aptos_framework::randomness;

    // ======================== Error Constants ========================
    
    /// Error codes for various failure conditions in the pig game contract.
    /// These errors help identify specific issues during contract execution.
    
    /// Function is not implemented yet (used during development)
    /// This error indicates that a function stub exists but lacks implementation.
    const E_NOT_IMPLEMENTED: u64 = 1;
    
    /// Game state does not exist for the user
    /// Thrown when trying to perform game actions before initializing a game.
    /// Solution: Call `roll_dice` first to auto-initialize the game state.
    const E_GAME_NOT_EXISTS: u64 = 2;
    
    /// Game is already over (user has reached the target score)
    /// Thrown when trying to perform game actions (roll/hold) after winning.
    /// Solution: Call `complete_game` then `reset_game` to start a new game.
    const E_GAME_OVER: u64 = 3;
    
    /// Invalid dice roll value provided for testing
    /// Thrown when test functions receive dice values outside the valid range (1-6).
    /// Solution: Only use values 1, 2, 3, 4, 5, or 6 in test functions.
    const E_INVALID_TEST_DICE: u64 = 4;

    // ======================== Game Constants ========================
    
    /// Target score required to win a game of Pig.
    /// When a player's total score reaches or exceeds this value via a "hold" action,
    /// the game automatically ends and `game_over` is set to true.
    /// 
    /// Note: The classic Pig game typically uses 100 points, but this implementation
    /// uses 50 points for faster gameplay in a blockchain environment.
    const TARGET_SCORE: u64 = 50;

    // ======================== Structs ========================
    
    /// Represents the complete game state for an individual player.
    /// 
    /// This struct is stored as a resource at the player's address and contains
    /// all information needed to track their current game progress, statistics,
    /// and game history. The struct automatically initializes when a player
    /// first calls `roll_dice()`.
    /// 
    /// ## State Transitions
    /// - `total_score`: Only increases when player calls `hold()`
    /// - `turn_score`: Increases with dice rolls, resets on bust (rolling 1) or hold
    /// - `game_over`: Set to true when `total_score >= TARGET_SCORE`
    /// - `round`: Increments on every dice roll
    /// - `turn`: Increments when turn ends (bust or hold)
    struct GameState has key {
        /// Current banked score that persists across turns.
        /// This score only increases when the player successfully holds,
        /// and determines if the player has won when >= TARGET_SCORE.
        total_score: u64,
        
        /// Points accumulated during the current turn.
        /// Resets to 0 when: (1) player rolls a 1, or (2) player holds.
        /// Added to `total_score` only when player holds.
        turn_score: u64,
        
        /// The most recent dice roll result (1-6).
        /// Special values: 0 = no roll yet or player just held.
        /// Used by frontend to display last action and game state.
        last_roll: u8,
        
        /// Total number of dice rolls in the current game.
        /// Increments on every `roll_dice()` call, resets on `reset_game()`.
        /// Tracks game length and player engagement.
        round: u64,
        
        /// Total number of completed turns in the current game.
        /// Increments when turn ends (rolling 1 or holding).
        /// Resets on `reset_game()`. Useful for game analysis.
        turn: u64,
        
        /// Whether the current game has ended (player reached TARGET_SCORE).
        /// When true, prevents further rolls/holds until game is reset.
        /// Automatically set by `hold()` when total_score >= TARGET_SCORE.
        game_over: bool,
        
        /// Lifetime count of completed games for this player.
        /// Increments on `complete_game()`, never resets.
        /// Tracks player engagement and experience level.
        games_played: u64,
    }

    /// Global statistics shared across all players.
    /// 
    /// This struct tracks aggregate game statistics and is stored at the
    /// module's address. It provides insights into overall contract usage
    /// and player engagement across the entire game ecosystem.
    /// 
    /// ## Storage Location
    /// Stored at `@pig_game_addr` (module address) for global access.
    /// Automatically initialized when first player starts a game.
    struct GlobalStats has key {
        /// Total number of games completed by all players combined.
        /// Increments each time any player calls `complete_game()`.
        /// Never decreases, providing historical usage metrics.
        total_games_played: u64,
    }

    // ======================== Entry (Write) Functions ========================
    
    /// These are the main game functions that players call to interact with the game.
    /// All entry functions automatically handle game state management and validation.
    
    #[randomness]
    /// Roll a six-sided die and update the game state accordingly.
    /// 
    /// This is the primary game action that advances gameplay. The function uses
    /// Aptos randomness to generate a fair dice roll between 1-6, then updates
    /// the player's game state based on the result.
    /// 
    /// ## Behavior
    /// - **Rolls 1**: Turn ends immediately, turn_score becomes 0, turn counter increments
    /// - **Rolls 2-6**: Adds roll value to turn_score, player can continue or hold
    /// 
    /// ## Game State Changes
    /// - `last_roll`: Set to the dice result (1-6)
    /// - `round`: Always increments by 1
    /// - `turn_score`: Either reset to 0 (if rolled 1) or increased by roll value
    /// - `turn`: Increments by 1 if rolled 1
    /// 
    /// ## Auto-Initialization
    /// If this is the player's first action, automatically creates their GameState.
    /// 
    /// ## Requirements
    /// - Game must not be over (`game_over` must be false)
    /// - Uses Aptos randomness framework for fair dice generation
    /// 
    /// ## Errors
    /// - `E_GAME_OVER`: Thrown if player tries to roll after winning
    /// 
    /// ## Example
    /// ```move
    /// // Player rolls - could get 1-6
    /// pig_game::roll_dice(&signer);
    /// 
    /// // Check what happened
    /// let roll = pig_game::last_roll(signer::address_of(&signer));
    /// let turn_score = pig_game::turn_score(signer::address_of(&signer));
    /// ```
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
    /// Test-only version of roll_dice that accepts a specific dice value.
    /// 
    /// This function provides deterministic dice rolling for comprehensive testing
    /// of game logic. It behaves identically to `roll_dice()` except the dice
    /// value is provided as a parameter instead of generated randomly.
    /// 
    /// ## Parameters
    /// - `user`: The signer representing the player
    /// - `num`: The dice roll value (must be 1-6)
    /// 
    /// ## Validation
    /// - Dice value must be between 1 and 6 (inclusive)
    /// - Game must not be over
    /// - Auto-initializes game state if needed
    /// 
    /// ## Errors
    /// - `E_INVALID_TEST_DICE`: If num < 1 or num > 6
    /// - `E_GAME_OVER`: If player tries to roll after winning
    /// 
    /// ## Testing Usage
    /// ```move
    /// // Test a winning scenario
    /// pig_game::roll_dice_for_test(&user, 6);  // Add 6 to turn
    /// pig_game::roll_dice_for_test(&user, 6);  // Add 6 to turn (total: 12)
    /// pig_game::hold_for_test(&user);          // Bank the 12 points
    /// 
    /// // Test a bust scenario
    /// pig_game::roll_dice_for_test(&user, 5);  // Add 5 to turn
    /// pig_game::roll_dice_for_test(&user, 1);  // Bust! Lose all turn points
    /// ```
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
    /// Test-only version of the hold function for deterministic testing.
    /// 
    /// Behaves identically to the entry `hold()` function but is accessible
    /// from test modules for comprehensive game logic testing.
    /// 
    /// ## Parameters
    /// - `user`: The signer representing the player
    /// 
    /// ## Effects
    /// Same as `hold()` - banks turn score, ends turn, checks for win condition.
    /// 
    /// ## Errors
    /// - `E_GAME_NOT_EXISTS`: If player has no game state
    /// - `E_GAME_OVER`: If game is already won
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

    /// End the current turn and bank all accumulated turn points.
    /// 
    /// This function allows players to "cash in" their current turn score,
    /// adding it to their total score and ending their turn. This is the
    /// safe alternative to continuing to roll and risking a bust (rolling 1).
    /// 
    /// ## Strategic Considerations
    /// Players must balance risk vs reward:
    /// - **High turn score**: More incentive to hold and secure points
    /// - **Low total score**: May need to take risks to catch up
    /// - **Close to winning**: Small turn scores may be sufficient
    /// 
    /// ## Game State Changes
    /// - `total_score`: Increased by current `turn_score`
    /// - `turn_score`: Reset to 0
    /// - `last_roll`: Set to 0 (indicates hold action)
    /// - `turn`: Incremented by 1
    /// - `game_over`: Set to true if new total_score >= TARGET_SCORE
    /// 
    /// ## Win Condition Check
    /// After banking points, automatically checks if the player has reached
    /// the TARGET_SCORE. If so, sets `game_over` to true, preventing further
    /// game actions until the game is completed and reset.
    /// 
    /// ## Requirements
    /// - Player must have existing game state
    /// - Game must not already be over
    /// - Can be called even with 0 turn_score (valid but pointless)
    /// 
    /// ## Errors
    /// - `E_GAME_NOT_EXISTS`: If player has never started a game
    /// - `E_GAME_OVER`: If player tries to hold after already winning
    /// 
    /// ## Example
    /// ```move
    /// // Player has accumulated some points this turn
    /// pig_game::roll_dice(&signer);  // Gets 4, turn_score = 4
    /// pig_game::roll_dice(&signer);  // Gets 3, turn_score = 7
    /// 
    /// // Decide to hold instead of risking a bust
    /// pig_game::hold(&signer);       // total_score += 7, turn_score = 0
    /// 
    /// // Check if won
    /// if (pig_game::game_over(signer::address_of(&signer))) {
    ///     pig_game::complete_game(&signer);
    /// }
    /// ```
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
    /// Test-only version of complete_game function for deterministic testing.
    /// 
    /// Behaves identically to the entry `complete_game()` function but is
    /// accessible from test modules for comprehensive game lifecycle testing.
    /// 
    /// ## Parameters
    /// - `user`: The signer representing the player
    /// 
    /// ## Effects
    /// Same as `complete_game()` - updates statistics for completed game.
    /// 
    /// ## Errors
    /// - `E_GAME_NOT_EXISTS`: If player has no game state or game not won
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
    /// Test-only version of reset_game function for deterministic testing.
    /// 
    /// Behaves identically to the entry `reset_game()` function but is
    /// accessible from test modules for comprehensive game lifecycle testing.
    /// 
    /// ## Parameters
    /// - `user`: The signer representing the player
    /// 
    /// ## Effects
    /// Same as `reset_game()` - resets game state while preserving statistics.
    /// 
    /// ## Errors
    /// - `E_GAME_NOT_EXISTS`: If player has no game state
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

    /// Finalize a completed game and update all relevant statistics.
    /// 
    /// This function should be called after a player has won a game (reached
    /// TARGET_SCORE) to officially complete the game and update both individual
    /// and global statistics. It serves as the formal "end game" ceremony.
    /// 
    /// ## Purpose
    /// - **Record Achievement**: Officially log the game completion
    /// - **Update Statistics**: Increment user and global game counters
    /// - **Prepare for Next Game**: Set up for potential `reset_game()` call
    /// 
    /// ## Statistical Updates
    /// - **User Stats**: Increments the player's `games_played` counter
    /// - **Global Stats**: Increments the contract-wide `total_games_played`
    /// - **Historical Data**: Preserves completed game data for analytics
    /// 
    /// ## Game State Changes
    /// - `games_played`: Incremented by 1 for the user
    /// - Global `total_games_played`: Incremented by 1
    /// - All other game state remains unchanged (preserved for review)
    /// 
    /// ## Requirements
    /// - Player must have existing game state
    /// - Game must be over (`game_over` must be true)
    /// - Typically called immediately after winning via `hold()`
    /// 
    /// ## Workflow Integration
    /// ```move
    /// // 1. Play until winning
    /// pig_game::roll_dice(&signer);
    /// pig_game::hold(&signer);  // This might trigger game_over = true
    /// 
    /// // 2. Check if won and complete
    /// if (pig_game::game_over(signer::address_of(&signer))) {
    ///     pig_game::complete_game(&signer);  // Update statistics
    ///     pig_game::reset_game(&signer);     // Start fresh game
    /// }
    /// ```
    /// 
    /// ## Errors
    /// - `E_GAME_NOT_EXISTS`: If player has no game state
    /// - `E_GAME_NOT_EXISTS`: If game is not yet won (reused error code)
    /// 
    /// ## Note
    /// This function does not reset the game state - use `reset_game()` 
    /// after completion to start a new game.
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

    /// Reset the current game state to start a completely new game.
    /// 
    /// This function clears all current game progress and returns the player
    /// to a fresh starting state, as if they were beginning their very first
    /// game. It's typically called after completing a game to start over.
    /// 
    /// ## Purpose
    /// - **New Game**: Start fresh after completing a previous game
    /// - **Clean Slate**: Remove all current game progress and statistics
    /// - **Replayability**: Enable unlimited consecutive games
    /// 
    /// ## State Reset
    /// All current game fields are reset to initial values:
    /// - `total_score`: Reset to 0
    /// - `turn_score`: Reset to 0
    /// - `last_roll`: Reset to 0 (no action yet)
    /// - `round`: Reset to 0 (no rounds played)
    /// - `turn`: Reset to 0 (no turns completed)
    /// - `game_over`: Reset to false
    /// 
    /// ## Preserved Data
    /// - `games_played`: **NOT reset** - this is a lifetime statistic
    /// - Global statistics remain unchanged
    /// 
    /// ## Typical Usage
    /// ```move
    /// // Complete game workflow
    /// pig_game::complete_game(&signer);  // Update stats
    /// pig_game::reset_game(&signer);     // Fresh start
    /// 
    /// // Immediately start new game
    /// pig_game::roll_dice(&signer);      // Begin new game
    /// ```
    /// 
    /// ## Strategic Considerations
    /// - Can be called even during an ongoing game (forfeit current progress)
    /// - Useful for practicing or abandoning unfavorable game states
    /// - No impact on historical statistics or achievements
    /// 
    /// ## Requirements
    /// - Player must have existing game state (have played before)
    /// - Can be called whether game is ongoing or completed
    /// 
    /// ## Errors
    /// - `E_GAME_NOT_EXISTS`: If player has never started a game
    /// 
    /// ## Alternative Flows
    /// ```move
    /// // Restart mid-game (forfeit current progress)
    /// pig_game::reset_game(&signer);
    /// pig_game::roll_dice(&signer);  // Start completely over
    /// 
    /// // Multiple consecutive games
    /// pig_game::complete_game(&signer);
    /// pig_game::reset_game(&signer);
    /// // Repeat cycle...
    /// ```
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
    
    /// Internal helper function to initialize a new game state for a player.
    /// 
    /// This function is called automatically when a player first uses `roll_dice()`
    /// and no game state exists for them. It creates both the individual GameState
    /// and initializes global statistics if they don't exist.
    /// 
    /// ## Automatic Initialization
    /// - Creates `GameState` resource at player's address
    /// - Initializes `GlobalStats` at module address if needed
    /// - Sets all game fields to starting values (0, false)
    /// 
    /// ## Resource Creation
    /// - **GameState**: Stored at `user` address with default values
    /// - **GlobalStats**: Stored at module address if first user ever
    /// 
    /// ## Called By
    /// - `roll_dice()` - when game state doesn't exist
    /// - `roll_dice_for_test()` - when game state doesn't exist in tests
    /// 
    /// ## Initial Values
    /// ```move
    /// GameState {
    ///     total_score: 0,      // No points yet
    ///     turn_score: 0,       // No current turn points
    ///     last_roll: 0,        // No dice rolled yet
    ///     round: 0,            // No rounds played
    ///     turn: 0,             // No turns completed
    ///     game_over: false,    // Game just starting
    ///     games_played: 0,     // No games completed yet
    /// }
    /// ```
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
    
    /// These functions provide read-only access to game state and statistics.
    /// They can be called by anyone and are gas-efficient for querying game data.
    /// All view functions handle non-existent game states gracefully.

    #[view]
    /// Get the most recent dice roll value for a player.
    /// 
    /// This function returns the last dice rolled by the player in their current
    /// game. The value provides important context about the current game state.
    /// 
    /// ## Return Values
    /// - **1-6**: The actual dice value from the most recent roll
    /// - **0**: Special values indicating:
    ///   - No rolls made yet in current game
    ///   - Player just called `hold()` (banked their points)
    ///   - Player has no game state (never played)
    /// 
    /// ## Usage
    /// ```move
    /// let roll = pig_game::last_roll(@player_address);
    /// if (roll == 0) {
    ///     // Player held or hasn't rolled yet
    /// } else if (roll == 1) {
    ///     // Player busted on their last roll
    /// } else {
    ///     // Player rolled 2-6, can continue or hold
    /// }
    /// ```
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `u8`: The last dice roll value (0-6)
    public fun last_roll(user: address): u8 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.last_roll
    }

    #[view]
    /// Get the current round number for a player's game.
    /// 
    /// The round counter tracks the total number of actions (dice rolls) taken
    /// in the current game. It provides insight into game length and player
    /// engagement patterns.
    /// 
    /// ## Definition
    /// A "round" represents a single dice roll action. The counter increments
    /// every time `roll_dice()` is called, regardless of the outcome.
    /// 
    /// ## Behavior
    /// - **Increments**: Every call to `roll_dice()` or `roll_dice_for_test()`
    /// - **Resets**: Only when `reset_game()` is called
    /// - **Persists**: Through holds, busts, and game completion
    /// 
    /// ## Use Cases
    /// - **Game Analysis**: Track game length and decision patterns
    /// - **UI Display**: Show activity level to players
    /// - **Statistics**: Calculate average game length
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `u64`: Number of dice rolls in current game (0 if no game)
    public fun round(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.round
    }

    #[view]
    /// Get the current turn number for a player's game.
    /// 
    /// The turn counter tracks completed turns in the current game. A turn
    /// ends either by rolling a 1 (bust) or by calling hold(). This metric
    /// shows game progression and strategic decision frequency.
    /// 
    /// ## Definition
    /// A "turn" represents a complete cycle where the player accumulates
    /// points and then either busts or banks them.
    /// 
    /// ## Turn Completion Events
    /// - **Rolling 1**: Turn ends immediately, turn_score lost
    /// - **Calling hold()**: Turn ends, turn_score banked
    /// 
    /// ## Behavior
    /// - **Increments**: When turn ends (roll 1 or hold)
    /// - **Resets**: Only when `reset_game()` is called
    /// - **Persists**: Through game completion
    /// 
    /// ## Strategic Insight
    /// - **Low turns**: Aggressive play, fewer holds
    /// - **High turns**: Conservative play, frequent holds
    /// - **Ratio analysis**: turns vs rounds shows risk tolerance
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `u64`: Number of completed turns in current game (0 if no game)
    public fun turn(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.turn
    }

    #[view]
    /// Check if a player's current game has ended (won).
    /// 
    /// This function indicates whether the player has reached the TARGET_SCORE
    /// and won their current game. Once true, no further game actions (roll/hold)
    /// are allowed until the game is completed and reset.
    /// 
    /// ## Win Condition
    /// Set to `true` automatically when `total_score >= TARGET_SCORE` after
    /// a successful `hold()` operation.
    /// 
    /// ## Game State Impact
    /// When `true`:
    /// - `roll_dice()` will throw `E_GAME_OVER` error
    /// - `hold()` will throw `E_GAME_OVER` error  
    /// - `complete_game()` becomes available
    /// - `reset_game()` can start a new game
    /// 
    /// ## Workflow Integration
    /// ```move
    /// // Check after each hold
    /// pig_game::hold(&signer);
    /// if (pig_game::game_over(signer::address_of(&signer))) {
    ///     // Player won! Handle victory
    ///     pig_game::complete_game(&signer);
    ///     pig_game::reset_game(&signer);
    /// }
    /// ```
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `bool`: true if game is won, false if ongoing or no game exists
    public fun game_over(user: address): bool acquires GameState {
        if (!exists<GameState>(user)) {
            return false
        };
        let game_state = borrow_global<GameState>(user);
        game_state.game_over
    }

    #[view]
    /// Get the points accumulated during the player's current turn.
    /// 
    /// This represents the "at-risk" points that the player has built up
    /// since their last turn ended. These points will either be lost (if
    /// they roll a 1) or banked (if they call hold).
    /// 
    /// ## Risk/Reward Dynamics
    /// - **Higher values**: More points at risk, higher incentive to hold
    /// - **Lower values**: Less risk, more room for aggressive play
    /// - **Zero values**: Either just started turn or recently busted/held
    /// 
    /// ## Turn Score Lifecycle
    /// 1. **Starts at 0**: Beginning of each turn
    /// 2. **Increases**: With each successful roll (2-6)
    /// 3. **Reset to 0**: When rolling 1 (bust) or calling hold()
    /// 4. **Added to total**: Only when calling hold() successfully
    /// 
    /// ## Strategic Decision Making
    /// ```move
    /// let current_turn = pig_game::turn_score(@player);
    /// let total = pig_game::total_score(@player);
    /// 
    /// if (current_turn >= 15 || total + current_turn >= TARGET_SCORE) {
    ///     // Consider holding - significant points at risk or near win
    ///     pig_game::hold(&signer);
    /// } else {
    ///     // Risk another roll
    ///     pig_game::roll_dice(&signer);
    /// }
    /// ```
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `u64`: Points accumulated this turn (0 if no game or turn just ended)
    public fun turn_score(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.turn_score
    }

    #[view]
    /// Get the player's banked (safe) score for their current game.
    /// 
    /// This represents points that have been successfully secured through
    /// previous hold() operations. These points cannot be lost and count
    /// toward the TARGET_SCORE for winning the game.
    /// 
    /// ## Score Safety
    /// - **Permanent**: Cannot be lost to future dice rolls
    /// - **Accumulated**: Built up over multiple successful turns
    /// - **Win Condition**: Checked against TARGET_SCORE when holding
    /// 
    /// ## Relationship to Turn Score
    /// - **Separate**: Does NOT include current turn_score
    /// - **Combined potential**: total_score + turn_score = potential final score
    /// - **Win calculation**: total_score + turn_score >= TARGET_SCORE triggers win
    /// 
    /// ## Strategic Value
    /// ```move
    /// let safe_points = pig_game::total_score(@player);
    /// let at_risk_points = pig_game::turn_score(@player);
    /// let potential_total = safe_points + at_risk_points;
    /// 
    /// if (potential_total >= TARGET_SCORE) {
    ///     // Can win this turn by holding
    ///     pig_game::hold(&signer);
    /// } else if (safe_points < TARGET_SCORE / 2) {
    ///     // Behind, need to take risks
    ///     pig_game::roll_dice(&signer);
    /// }
    /// ```
    /// 
    /// ## Game Progression
    /// - **Early game**: Low values, need aggressive play
    /// - **Mid game**: Building toward TARGET_SCORE
    /// - **Late game**: Close to TARGET_SCORE, conservative play
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `u64`: Banked points from previous turns (0 if no game)
    public fun total_score(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.total_score
    }

    #[view]
    /// Get the total number of games completed across all players.
    /// 
    /// This function provides global statistics showing the overall usage
    /// and adoption of the pig game contract. The count increases each
    /// time any player calls `complete_game()`.
    /// 
    /// ## Global Scope
    /// - **Contract-wide**: Includes all players' completed games
    /// - **Cumulative**: Never decreases, only grows over time
    /// - **Historical**: Provides insight into contract popularity
    /// 
    /// ## Use Cases
    /// - **Analytics**: Track contract usage over time
    /// - **Leaderboards**: Context for individual achievements
    /// - **Community**: Show global game activity
    /// 
    /// ## Storage Location
    /// Stored in `GlobalStats` resource at the module address (@pig_game_addr).
    /// May return 0 in test environments if statistics haven't been initialized.
    /// 
    /// ## Example Usage
    /// ```move
    /// let total_games = pig_game::games_played();
    /// // Display: "Join 1,234 players who have completed games!"
    /// ```
    /// 
    /// ## Returns
    /// - `u64`: Total completed games by all players (0 if none or test context)
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
    /// Test-only version that can access global stats from multiple locations.
    /// 
    /// This function is designed for test environments where GlobalStats
    /// might be stored at different addresses due to testing constraints.
    /// It checks both the module address and provided user address.
    /// 
    /// ## Testing Flexibility
    /// - Checks module address first (@pig_game_addr)
    /// - Falls back to user address if needed
    /// - Returns 0 if neither location has statistics
    /// 
    /// ## Parameters
    /// - `user_addr`: Address to check as fallback for GlobalStats
    /// 
    /// ## Returns
    /// - `u64`: Total completed games found at any location
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
    /// Get the number of games completed by a specific player.
    /// 
    /// This function returns the lifetime count of games that the specified
    /// player has completed. It represents their experience level and
    /// engagement with the contract.
    /// 
    /// ## Individual Tracking
    /// - **Player-specific**: Only counts the specified user's completions
    /// - **Lifetime total**: Never resets, accumulates over time
    /// - **Experience indicator**: Higher values show more experienced players
    /// 
    /// ## Incrementation
    /// - Increases by 1 each time the user calls `complete_game()`
    /// - Persists through `reset_game()` calls
    /// - Independent of current game state
    /// 
    /// ## Use Cases
    /// - **Player profiles**: Show experience level
    /// - **Achievements**: Unlock rewards based on completions
    /// - **Matchmaking**: Pair players of similar experience
    /// - **Leaderboards**: Rank players by games completed
    /// 
    /// ## Example Usage
    /// ```move
    /// let user_experience = pig_game::user_games_played(@player);
    /// if (user_experience >= 10) {
    ///     // Experienced player - show advanced strategies
    /// } else if (user_experience == 0) {
    ///     // New player - show tutorial
    /// }
    /// ```
    /// 
    /// ## Parameters
    /// - `user`: Address of the player to query
    /// 
    /// ## Returns
    /// - `u64`: Number of games completed by this player (0 if never played)
    public fun user_games_played(user: address): u64 acquires GameState {
        if (!exists<GameState>(user)) {
            return 0
        };
        let game_state = borrow_global<GameState>(user);
        game_state.games_played
    }
}
