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
    use aptos_std::ordered_map;
    use aptos_std::ordered_map::OrderedMap;
    use aptos_framework::aggregator_v2;
    use aptos_framework::randomness;
    use pig_master_addr::pig_master;

    /// Function is not implemented
    const E_NOT_IMPLEMENTED: u64 = 1;

    /// The game is over, the player cannot roll anymore and must call reset_game to start a new game
    const E_GAME_OVER: u64 = 2;

    /// The game has not been started yet, the player must call roll_dice to start the game
    const E_NOT_STARTED: u64 = 3;

    /// The game is not over, the player must call complete_game to finish the game
    const E_GAME_NOT_OVER: u64 = 4;

    struct TotalGameState has key {
        games_played: aggregator_v2::Aggregator<u64>,
        ordered_games: OrderedMap<address, GameState>
    }

    struct GameState has store, copy, drop {
        games_played: u64,
        // The last rolled number
        last_roll: u8,
        // Number of rolls made in the turn
        rounds: u64,
        // Number of "holds" or "1s" rolled in the whole game
        turns: u64,
        // Score accumulated in the current turn
        turn_score: u64,
        // Score accumulated in the current game
        total_score: u64,
        // Flag to indicate if the game is over
        is_game_over: bool,
    }

    fun init_module(deployer: &signer) {
        initialize(deployer)
    }

    fun initialize(deployer: &signer) {
        // Initialize the game state for the deployer
        move_to(
            deployer,
            TotalGameState {
                games_played: aggregator_v2::create_aggregator_with_value(
                    0,
                    10000000
                ), ordered_games: ordered_map::new()
            }
        );
    }

    #[test_only]
    public fun initialize_for_test(deployer: &signer) {
        initialize(deployer)
    }

    // ======================== Entry (Write) functions ========================

    inline fun ensure_game_started(user_address: address): &mut GameState {
        let state = &mut TotalGameState[@pig_game_addr];

        // Start a new game if the user does not have a game state
        if (!state.ordered_games.contains(&user_address)) {
            state.ordered_games.add(user_address, GameState {
                games_played: 0,
                last_roll: 0,
                rounds: 0,
                turns: 0,
                turn_score: 0,
                total_score: 0,
                is_game_over: false,
            });
        };

        let state = &mut TotalGameState[@pig_game_addr];
        let game_state = state.ordered_games.borrow_mut(&user_address);

        assert!(!game_state.is_game_over, E_GAME_OVER);
        game_state
    }

    fun evaluate_roll(game_state: &mut GameState, num: u8) {
        game_state.last_roll = num;
        game_state.rounds += 1;

        if (num == 1) {
            // If the rolled number is 1, reset the turn score and rolls, increment turns
            game_state.turn_score = 0;
            game_state.turns += 1;
        } else {
            // Otherwise, add the rolled number to the turn score and increment rolls
            game_state.turn_score += num as u64;
        };
    }

    #[randomness]
    /// Roll the dice
    entry fun roll_dice(user: &signer) acquires TotalGameState {
        let user_address = signer::address_of(user);

        let game_state = ensure_game_started(user_address);

        // Roll, and evaluate the current turn
        let num = randomness::u8_range(1, 6);

        evaluate_roll(game_state, num);
    }

    #[test_only]
    fun roll_dice_for_test(user: &signer, num: u8) acquires TotalGameState {
        let user_address = signer::address_of(user);

        let game_state = ensure_game_started(user_address);

        // Evaluate the current turn with the provided number
        evaluate_roll(game_state, num);
    }

    /// End the turn by calling hold, add points to the overall
    /// accumulated score for the current game for the specified user
    entry fun hold(user: &signer) acquires TotalGameState {
        let user_address = signer::address_of(user);
        let game_state = game_state_mut(user_address);

        // If the game is over, do not allow holding
        assert!(!game_state.is_game_over, E_GAME_OVER);

        // Add the turn score to the total score and reset the turn score
        game_state.total_score += game_state.turn_score;
        game_state.turn_score = 0;
        game_state.turns += 1;

        // Reset rolls for the next turn
        game_state.last_roll = 0;

        // Check if the total score reaches or exceeds 100
        if (game_state.total_score >= pig_master::points_to_win()) {
            game_state.is_game_over = true;
        }
    }

    /// The intended score has been reached, end the game, publish the
    /// score to both the global storage
    entry fun complete_game(user: &signer) acquires TotalGameState {
        let user_address = signer::address_of(user);
        let game_state = game_state_mut(user_address);
        assert!(game_state.is_game_over, E_GAME_OVER);

        pig_master::complete_game(user, game_state.total_score, game_state.rounds, game_state.turns);
        reset_game(user);
    }

    /// The user wants to start a new game, end this one.
    entry fun reset_game(user: &signer) acquires TotalGameState {
        let user_address = signer::address_of(user);

        // Reset the game state for the user
        let game_state = game_state_mut(user_address);


        game_state.last_roll = 0;
        game_state.rounds = 0;
        game_state.turns = 0;
        game_state.turn_score = 0;
        game_state.total_score = 0;
        game_state.is_game_over = false;
        game_state.games_played += 1;
    }

    // ======================== View (Read) Functions ========================
    inline fun total_game_state(): &TotalGameState acquires TotalGameState {
        &TotalGameState[@pig_game_addr]
    }

    inline fun total_game_state_mut(): &mut TotalGameState acquires TotalGameState {
        &mut TotalGameState[@pig_game_addr]
    }

    inline fun game_state(user_address: address): &GameState acquires TotalGameState {
        let state = total_game_state();
        assert!(state.ordered_games.contains(&user_address), E_NOT_STARTED);
        state.ordered_games.borrow(&user_address)
    }

    inline fun optional_game_state(user_address: address): GameState acquires TotalGameState {
        let state = total_game_state();
        if (state.ordered_games.contains(&user_address)) {
            *state.ordered_games.borrow(&user_address)
        } else {
            GameState {
                games_played: 0,
                last_roll: 0,
                rounds: 0,
                turns: 0,
                turn_score: 0,
                total_score: 0,
                is_game_over: false,
            }
        }
    }

    inline fun game_state_mut(user_address: address): &mut GameState acquires TotalGameState {
        let state = total_game_state_mut();
        assert!(state.ordered_games.contains(&user_address), E_NOT_STARTED);
        state.ordered_games.borrow_mut(&user_address)
    }

    #[view]
    public fun last_roll(user: address): u8 acquires TotalGameState {
        optional_game_state(user).last_roll
    }

    #[view]
    public fun round(user: address): u64 acquires TotalGameState {
        optional_game_state(user).rounds
    }

    #[view]
    public fun turn(user: address): u64 acquires TotalGameState {
        optional_game_state(user).turns
    }

    #[view]
    public fun game_over(user: address): bool acquires TotalGameState {
        optional_game_state(user).is_game_over
    }

    #[view]
    public fun turn_score(user: address): u64 acquires TotalGameState {
        optional_game_state(user).turn_score
    }

    #[view]
    public fun total_score(user: address): u64 acquires TotalGameState {
        optional_game_state(user).total_score
    }

    #[view]
    /// Return total number of games played within this game's context
    public fun games_played(): u64 acquires TotalGameState {
        aggregator_v2::read(&total_game_state().games_played)
    }

    #[view]
    /// Return total number of games played within this game's context
    public fun user_games_played(user: address): u64 acquires TotalGameState {
        optional_game_state(user).games_played
    }
}
