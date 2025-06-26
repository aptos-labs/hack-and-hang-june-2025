#[test_only]
module pig_game_addr::pig_game_tests {
    use std::signer;
    use pig_game_addr::pig_game;

    // Test constants
    const USER_ADDR: address = @0x123;

    #[test(user = @0x123)]
    fun test_roll_dice_for_test_valid_rolls(user: &signer) {
        // Test that we can roll all valid dice values (1-6)
        // We'll test them sequentially and check that each roll is recorded
        let user_addr = signer::address_of(user);
        
        pig_game::roll_dice_for_test(user, 1);
        assert!(pig_game::last_roll(user_addr) == 1, 0);
        
        pig_game::roll_dice_for_test(user, 2);
        assert!(pig_game::last_roll(user_addr) == 2, 1);
        
        pig_game::roll_dice_for_test(user, 3);
        assert!(pig_game::last_roll(user_addr) == 3, 2);
        
        pig_game::roll_dice_for_test(user, 4);
        assert!(pig_game::last_roll(user_addr) == 4, 3);
        
        pig_game::roll_dice_for_test(user, 5);
        assert!(pig_game::last_roll(user_addr) == 5, 4);
        
        pig_game::roll_dice_for_test(user, 6);
        assert!(pig_game::last_roll(user_addr) == 6, 5);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_INVALID_TEST_DICE)]
    fun test_roll_dice_for_test_invalid_roll_zero(user: &signer) {
        pig_game::roll_dice_for_test(user, 0);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_INVALID_TEST_DICE)]
    fun test_roll_dice_for_test_invalid_roll_seven(user: &signer) {
        pig_game::roll_dice_for_test(user, 7);
    }

    #[test(user = @0x123)]
    fun test_game_initialization(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Before any game action, all values should be 0 or false
        assert!(pig_game::last_roll(user_addr) == 0, 0);
        assert!(pig_game::round(user_addr) == 0, 1);
        assert!(pig_game::turn(user_addr) == 0, 2);
        assert!(pig_game::turn_score(user_addr) == 0, 3);
        assert!(pig_game::total_score(user_addr) == 0, 4);
        assert!(pig_game::game_over(user_addr) == false, 5);
        assert!(pig_game::user_games_played(user_addr) == 0, 6);
        
        // Roll a dice to initialize the game
        pig_game::roll_dice_for_test(user, 3);
        
        // Now game should be initialized with some values
        assert!(pig_game::last_roll(user_addr) == 3, 7);
        assert!(pig_game::round(user_addr) == 1, 8);
        assert!(pig_game::turn_score(user_addr) == 3, 9);
    }

    #[test(user = @0x123)]
    fun test_rolling_non_one_adds_to_turn_score(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Roll a 3
        pig_game::roll_dice_for_test(user, 3);
        assert!(pig_game::turn_score(user_addr) == 3, 0);
        assert!(pig_game::round(user_addr) == 1, 1);
        assert!(pig_game::turn(user_addr) == 0, 2);
        
        // Roll another 4
        pig_game::roll_dice_for_test(user, 4);
        assert!(pig_game::turn_score(user_addr) == 7, 3);
        assert!(pig_game::round(user_addr) == 2, 4);
        assert!(pig_game::turn(user_addr) == 0, 5);
        
        // Roll a 2
        pig_game::roll_dice_for_test(user, 2);
        assert!(pig_game::turn_score(user_addr) == 9, 6);
        assert!(pig_game::round(user_addr) == 3, 7);
        assert!(pig_game::turn(user_addr) == 0, 8);
    }

    #[test(user = @0x123)]
    fun test_rolling_one_resets_turn_score(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Build up some turn score
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 4);
        assert!(pig_game::turn_score(user_addr) == 7, 0);
        assert!(pig_game::turn(user_addr) == 0, 1);
        
        // Roll a 1 - should reset turn score and increment turn
        pig_game::roll_dice_for_test(user, 1);
        assert!(pig_game::turn_score(user_addr) == 0, 2);
        assert!(pig_game::last_roll(user_addr) == 1, 3);
        assert!(pig_game::turn(user_addr) == 1, 4);
        assert!(pig_game::round(user_addr) == 3, 5);
    }

    #[test(user = @0x123)]
    fun test_round_increments_on_each_roll(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Each roll should increment the round counter
        pig_game::roll_dice_for_test(user, 2);
        assert!(pig_game::round(user_addr) == 1, 0);
        
        pig_game::roll_dice_for_test(user, 3);
        assert!(pig_game::round(user_addr) == 2, 1);
        
        pig_game::roll_dice_for_test(user, 1);  // This should also increment round
        assert!(pig_game::round(user_addr) == 3, 2);
        
        pig_game::roll_dice_for_test(user, 4);
        assert!(pig_game::round(user_addr) == 4, 3);
    }

    #[test(user = @0x123)]  
    fun test_turn_increments_on_rolling_one(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Start with turn 0
        pig_game::roll_dice_for_test(user, 2);
        assert!(pig_game::turn(user_addr) == 0, 0);
        
        pig_game::roll_dice_for_test(user, 3);
        assert!(pig_game::turn(user_addr) == 0, 1);
        
        // Roll a 1 - should increment turn
        pig_game::roll_dice_for_test(user, 1);
        assert!(pig_game::turn(user_addr) == 1, 2);
        
        // Continue playing
        pig_game::roll_dice_for_test(user, 5);
        assert!(pig_game::turn(user_addr) == 1, 3);
        
        // Another 1 - should increment turn again
        pig_game::roll_dice_for_test(user, 1);
        assert!(pig_game::turn(user_addr) == 2, 4);
    }

    #[test(user = @0x123)]
    fun test_game_state_consistency_after_multiple_rolls(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Simulate a sequence of rolls: 3, 4, 1, 2, 6, 1, 5
        let expected_rounds = 0;
        let expected_turns = 0;
        let expected_turn_score = 0;
        
        // Roll 3
        pig_game::roll_dice_for_test(user, 3);
        expected_rounds = expected_rounds + 1;
        expected_turn_score = expected_turn_score + 3;
        assert!(pig_game::round(user_addr) == expected_rounds, 0);
        assert!(pig_game::turn(user_addr) == expected_turns, 1);
        assert!(pig_game::turn_score(user_addr) == expected_turn_score, 2);
        
        // Roll 4
        pig_game::roll_dice_for_test(user, 4);
        expected_rounds = expected_rounds + 1;
        expected_turn_score = expected_turn_score + 4;
        assert!(pig_game::round(user_addr) == expected_rounds, 3);
        assert!(pig_game::turn(user_addr) == expected_turns, 4);
        assert!(pig_game::turn_score(user_addr) == expected_turn_score, 5);
        
        // Roll 1 (bust)
        pig_game::roll_dice_for_test(user, 1);
        expected_rounds = expected_rounds + 1;
        expected_turns = expected_turns + 1;
        expected_turn_score = 0; // Reset on bust
        assert!(pig_game::round(user_addr) == expected_rounds, 6);
        assert!(pig_game::turn(user_addr) == expected_turns, 7);
        assert!(pig_game::turn_score(user_addr) == expected_turn_score, 8);
        
        // Roll 2
        pig_game::roll_dice_for_test(user, 2);
        expected_rounds = expected_rounds + 1;
        expected_turn_score = expected_turn_score + 2;
        assert!(pig_game::round(user_addr) == expected_rounds, 9);
        assert!(pig_game::turn(user_addr) == expected_turns, 10);
        assert!(pig_game::turn_score(user_addr) == expected_turn_score, 11);
        
        // Roll 6
        pig_game::roll_dice_for_test(user, 6);
        expected_rounds = expected_rounds + 1;
        expected_turn_score = expected_turn_score + 6;
        assert!(pig_game::round(user_addr) == expected_rounds, 12);
        assert!(pig_game::turn(user_addr) == expected_turns, 13);
        assert!(pig_game::turn_score(user_addr) == expected_turn_score, 14);
    }

    #[test(user = @0x123)]
    fun test_last_roll_tracking(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Test that last_roll correctly tracks the most recent roll
        pig_game::roll_dice_for_test(user, 2);
        assert!(pig_game::last_roll(user_addr) == 2, 0);
        
        pig_game::roll_dice_for_test(user, 5);
        assert!(pig_game::last_roll(user_addr) == 5, 1);
        
        pig_game::roll_dice_for_test(user, 1);
        assert!(pig_game::last_roll(user_addr) == 1, 2);
        
        pig_game::roll_dice_for_test(user, 6);
        assert!(pig_game::last_roll(user_addr) == 6, 3);
    }

    #[test]
    fun test_global_stats_initialization() {
        // Test that global stats return 0 when not initialized
        assert!(pig_game::games_played() == 0, 0);
    }

    #[test(user = @0x123)]
    fun test_user_stats_for_non_existing_user() {
        // Test that all view functions return appropriate defaults for non-existing users
        let non_existing_user = @0x999;
        
        assert!(pig_game::last_roll(non_existing_user) == 0, 0);
        assert!(pig_game::round(non_existing_user) == 0, 1);
        assert!(pig_game::turn(non_existing_user) == 0, 2);
        assert!(pig_game::turn_score(non_existing_user) == 0, 3);
        assert!(pig_game::total_score(non_existing_user) == 0, 4);
        assert!(pig_game::game_over(non_existing_user) == false, 5);
        assert!(pig_game::user_games_played(non_existing_user) == 0, 6);
    }

    // ======================== Hold Function Tests ========================

    #[test(user = @0x123)]
    fun test_hold_basic_functionality(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Roll some dice to build up turn score
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 4);
        pig_game::roll_dice_for_test(user, 2);
        
        // Verify initial state
        assert!(pig_game::turn_score(user_addr) == 9, 0);
        assert!(pig_game::total_score(user_addr) == 0, 1);
        assert!(pig_game::turn(user_addr) == 0, 2);
        assert!(pig_game::last_roll(user_addr) == 2, 3);
        
        // Hold
        pig_game::hold_for_test(user);
        
        // Verify state after hold
        assert!(pig_game::turn_score(user_addr) == 0, 4); // Turn score reset
        assert!(pig_game::total_score(user_addr) == 9, 5); // Total score increased
        assert!(pig_game::turn(user_addr) == 1, 6); // Turn incremented
        assert!(pig_game::last_roll(user_addr) == 0, 7); // Last roll reset to 0 (indicates hold)
        assert!(pig_game::game_over(user_addr) == false, 8); // Game not over yet
    }

    #[test(user = @0x123)]
    fun test_hold_accumulates_total_score(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // First turn: roll and hold
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        assert!(pig_game::total_score(user_addr) == 10, 0);
        assert!(pig_game::turn_score(user_addr) == 0, 1);
        
        // Second turn: roll and hold
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 5);
        pig_game::roll_dice_for_test(user, 2);
        pig_game::hold_for_test(user);
        assert!(pig_game::total_score(user_addr) == 20, 2); // 10 + 10
        assert!(pig_game::turn_score(user_addr) == 0, 3);
        
        // Third turn: roll and hold
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        assert!(pig_game::total_score(user_addr) == 24, 4); // 20 + 4
        assert!(pig_game::turn_score(user_addr) == 0, 5);
    }

    #[test(user = @0x123)]
    fun test_hold_with_zero_turn_score(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Initialize game by rolling a die
        pig_game::roll_dice_for_test(user, 3);
        pig_game::hold_for_test(user); // Hold after first roll
        
        let initial_total = pig_game::total_score(user_addr);
        
        // Roll a 1 to reset turn score to 0
        pig_game::roll_dice_for_test(user, 1);
        assert!(pig_game::turn_score(user_addr) == 0, 0);
        
        // Now hold with zero turn score
        pig_game::hold_for_test(user);
        
        // Total score should remain the same
        assert!(pig_game::total_score(user_addr) == initial_total, 1);
        assert!(pig_game::turn_score(user_addr) == 0, 2);
        assert!(pig_game::last_roll(user_addr) == 0, 3);
    }

    #[test(user = @0x123)]
    fun test_hold_triggers_game_win(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Build up total score close to target (TARGET_SCORE is 50)
        // We'll simulate multiple turns to get close to 50
        
        // Turn 1: Get to 45 points
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 3); // Total turn score: 45
        pig_game::hold_for_test(user);
        assert!(pig_game::total_score(user_addr) == 45, 0);
        assert!(pig_game::game_over(user_addr) == false, 1);
        
        // Turn 2: Get 5 more points to reach/exceed 50
        pig_game::roll_dice_for_test(user, 5);
        assert!(pig_game::turn_score(user_addr) == 5, 2);
        
        // Hold - this should trigger game over
        pig_game::hold_for_test(user);
        assert!(pig_game::total_score(user_addr) == 50, 3);
        assert!(pig_game::game_over(user_addr) == true, 4);
        assert!(pig_game::turn_score(user_addr) == 0, 5);
        assert!(pig_game::last_roll(user_addr) == 0, 6);
    }

    #[test(user = @0x123)]
    fun test_hold_triggers_game_win_over_target(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Build up total score close to target
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 3); // Total turn score: 45
        pig_game::hold_for_test(user);
        
        // Next turn: get more than needed to win
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 4); // Turn score: 10, would make total 55
        
        pig_game::hold_for_test(user);
        assert!(pig_game::total_score(user_addr) == 55, 0); // 45 + 10 = 55
        assert!(pig_game::game_over(user_addr) == true, 1);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_GAME_NOT_EXISTS)]
    fun test_hold_fails_without_game_state(user: &signer) {
        // Try to hold without initializing game (no dice rolls)
        pig_game::hold_for_test(user);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_GAME_OVER)]
    fun test_hold_fails_when_game_over(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Win the game first
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // Total turn score: 50
        pig_game::hold_for_test(user);
        
        // Verify game is over
        assert!(pig_game::game_over(user_addr) == true, 0);
        
        // Try to hold again - should fail
        pig_game::hold_for_test(user);
    }

    #[test(user = @0x123)]
    fun test_hold_turn_tracking(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Test that turn counter increments correctly with holds
        pig_game::roll_dice_for_test(user, 2);
        assert!(pig_game::turn(user_addr) == 0, 0);
        
        pig_game::hold_for_test(user);
        assert!(pig_game::turn(user_addr) == 1, 1);
        
        pig_game::roll_dice_for_test(user, 3);
        pig_game::hold_for_test(user);
        assert!(pig_game::turn(user_addr) == 2, 2);
        
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        assert!(pig_game::turn(user_addr) == 3, 3);
    }

    #[test(user = @0x123)]
    fun test_hold_vs_rolling_one_turn_behavior(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Test that both holding and rolling 1 increment turn counter
        pig_game::roll_dice_for_test(user, 3);
        pig_game::hold_for_test(user); // Turn 1
        assert!(pig_game::turn(user_addr) == 1, 0);
        assert!(pig_game::total_score(user_addr) == 3, 1);
        
        pig_game::roll_dice_for_test(user, 4);
        pig_game::roll_dice_for_test(user, 1); // Turn 2 (bust)
        assert!(pig_game::turn(user_addr) == 2, 2);
        assert!(pig_game::total_score(user_addr) == 3, 3); // No change in total
        
        pig_game::roll_dice_for_test(user, 5);
        pig_game::hold_for_test(user); // Turn 3
        assert!(pig_game::turn(user_addr) == 3, 4);
        assert!(pig_game::total_score(user_addr) == 8, 5); // 3 + 5
    }

    // ======================== Complete Game Function Tests ========================

    #[test(user = @0x123)]
    fun test_complete_game_basic_functionality(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Win the game first
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // Total turn score: 50
        pig_game::hold_for_test(user);
        
        // Verify game is won but not completed yet
        assert!(pig_game::game_over(user_addr) == true, 0);
        assert!(pig_game::user_games_played(user_addr) == 0, 1);
        assert!(pig_game::games_played_for_test(user_addr) == 0, 2);
        
        // Complete the game
        pig_game::complete_game_for_test(user);
        
        // Verify completion
        assert!(pig_game::user_games_played(user_addr) == 1, 3);
        assert!(pig_game::games_played_for_test(user_addr) == 1, 4);
        assert!(pig_game::game_over(user_addr) == true, 5); // Still over
    }

    #[test(user = @0x123)]
    fun test_complete_game_multiple_completions(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // First game - win and complete
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // 50 points
        pig_game::hold_for_test(user);
        pig_game::complete_game_for_test(user);
        
        assert!(pig_game::user_games_played(user_addr) == 1, 0);
        assert!(pig_game::games_played_for_test(user_addr) == 1, 1);
        
        // Reset and play second game
        pig_game::reset_game_for_test(user);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // 50 points
        pig_game::hold_for_test(user);
        pig_game::complete_game_for_test(user);
        
        // Both user and global stats should increment
        assert!(pig_game::user_games_played(user_addr) == 2, 2);
        assert!(pig_game::games_played_for_test(user_addr) == 2, 3);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_GAME_NOT_EXISTS)]
    fun test_complete_game_fails_without_game_state(user: &signer) {
        // Try to complete game without initializing
        pig_game::complete_game_for_test(user);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_GAME_NOT_EXISTS)]
    fun test_complete_game_fails_when_game_not_won(user: &signer) {
        // Roll some dice but don't win
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        
        // Try to complete - should fail since game not won
        pig_game::complete_game_for_test(user);
    }

    // ======================== Reset Game Function Tests ========================

    #[test(user = @0x123)]
    fun test_reset_game_basic_functionality(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Build up some game state
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        pig_game::roll_dice_for_test(user, 5);
        pig_game::roll_dice_for_test(user, 2);
        
        // Verify we have some state
        assert!(pig_game::total_score(user_addr) == 7, 0);
        assert!(pig_game::turn_score(user_addr) == 7, 1);
        assert!(pig_game::last_roll(user_addr) == 2, 2);
        assert!(pig_game::round(user_addr) == 4, 3);
        assert!(pig_game::turn(user_addr) == 1, 4);
        
        // Reset the game
        pig_game::reset_game_for_test(user);
        
        // Verify everything is reset
        assert!(pig_game::total_score(user_addr) == 0, 5);
        assert!(pig_game::turn_score(user_addr) == 0, 6);
        assert!(pig_game::last_roll(user_addr) == 0, 7);
        assert!(pig_game::round(user_addr) == 0, 8);
        assert!(pig_game::turn(user_addr) == 0, 9);
        assert!(pig_game::game_over(user_addr) == false, 10);
    }

    #[test(user = @0x123)]
    fun test_reset_game_preserves_games_played(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Win and complete a game
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // 50 points
        pig_game::hold_for_test(user);
        pig_game::complete_game_for_test(user);
        
        // Verify completion
        assert!(pig_game::user_games_played(user_addr) == 1, 0);
        assert!(pig_game::game_over(user_addr) == true, 1);
        
        // Reset the game
        pig_game::reset_game_for_test(user);
        
        // Games played should be preserved
        assert!(pig_game::user_games_played(user_addr) == 1, 2);
        assert!(pig_game::game_over(user_addr) == false, 3);
        assert!(pig_game::total_score(user_addr) == 0, 4);
    }

    #[test(user = @0x123)]
    fun test_reset_game_after_win_allows_new_game(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Win the game
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // 50 points
        pig_game::hold_for_test(user);
        assert!(pig_game::game_over(user_addr) == true, 0);
        
        // Reset and start new game
        pig_game::reset_game_for_test(user);
        assert!(pig_game::game_over(user_addr) == false, 1);
        
        // Should be able to play again
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        
        assert!(pig_game::total_score(user_addr) == 7, 2);
        assert!(pig_game::turn_score(user_addr) == 0, 3);
        assert!(pig_game::turn(user_addr) == 1, 4);
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = pig_game_addr::pig_game::E_GAME_NOT_EXISTS)]
    fun test_reset_game_fails_without_game_state(user: &signer) {
        // Try to reset without initializing game
        pig_game::reset_game_for_test(user);
    }

    #[test(user = @0x123)]
    fun test_complete_workflow_multiple_games(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Game 1: Play, win, complete
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // 50 points
        pig_game::hold_for_test(user);
        pig_game::complete_game_for_test(user);
        assert!(pig_game::user_games_played(user_addr) == 1, 0);
        
        // Reset for Game 2
        pig_game::reset_game_for_test(user);
        
        // Game 2: Play, win, complete
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 6);
        pig_game::roll_dice_for_test(user, 2); // 50 points
        pig_game::hold_for_test(user);
        pig_game::complete_game_for_test(user);
        assert!(pig_game::user_games_played(user_addr) == 2, 1);
        assert!(pig_game::games_played_for_test(user_addr) == 2, 2);
        
        // Reset for Game 3
        pig_game::reset_game_for_test(user);
        
        // Game 3: Start playing
        pig_game::roll_dice_for_test(user, 3);
        pig_game::roll_dice_for_test(user, 4);
        pig_game::hold_for_test(user);
        
        // Verify user stats preserved, game state reset
        assert!(pig_game::user_games_played(user_addr) == 2, 3);
        assert!(pig_game::total_score(user_addr) == 7, 4);
        assert!(pig_game::game_over(user_addr) == false, 5);
    }


}
