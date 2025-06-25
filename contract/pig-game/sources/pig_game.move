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

    /// Function is not implemented
    const E_NOT_IMPLEMENTED: u64 = 1;

    // ======================== Entry (Write) functions ========================
    #[randomness]
    /// Roll the dice
    entry fun roll_dice(user: &signer) {
        abort E_NOT_IMPLEMENTED
    }

    #[test_only]
    /// Optional, useful for testing purposes
    fun roll_dice_for_test(user: &signer, num: u8) {
        abort E_NOT_IMPLEMENTED
    }

    /// End the turn by calling hold, add points to the overall
    /// accumulated score for the current game for the specified user
    entry fun hold(user: &signer) {
        abort E_NOT_IMPLEMENTED
    }

    /// The intended score has been reached, end the game, publish the
    /// score to both the global storage
    entry fun complete_game(user: &signer) {
        abort E_NOT_IMPLEMENTED
    }

    /// The user wants to start a new game, end this one.
    entry fun reset_game(user: &signer) {
        abort E_NOT_IMPLEMENTED
    }

    // ======================== View (Read) Functions ========================

    #[view]
    /// Return the user's last roll value from the current game, 0 is considered no roll / hold
    public fun last_roll(user: address): u8 {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Tells us which number round the game is on, this only resets when the game is reset
    ///
    /// This increments every time the user rolls the dice or holds
    public fun round(user: address): u64 {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Tells us which number turn the game is on, this only resets when the game is reset
    ///
    /// This increments every time the user rolls a 1 or holds
    public fun turn(user: address): u64 {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Tells us whether the game is over for the user (the user has reached the target score)
    public fun game_over(user: address): bool {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Return the user's current turn score, this is the score accumulated during the current turn.  If the player holds
    /// this score will be added to the total score for the game.
    public fun turn_score(user: address): u64 {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Return the user's current total game score for the current game, this does not include the current turn score
    public fun total_score(user: address): u64 {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Return total number of games played within this game's context
    public fun games_played(): u64 {
        abort E_NOT_IMPLEMENTED
    }

    #[view]
    /// Return total number of games played within this game's context for the given user
    public fun user_games_played(user: address): u64 {
        abort E_NOT_IMPLEMENTED
    }
}
