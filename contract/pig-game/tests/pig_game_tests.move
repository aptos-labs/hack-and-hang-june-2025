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


}
