#[test_only]
module pig_game_addr::pig_game_tests {
    // Add your unit tests here

    use pig_game_addr::pig_game;

    #[test]
    fun test_run_game() {
        pig_game::initialize_for_test();
    }

}
