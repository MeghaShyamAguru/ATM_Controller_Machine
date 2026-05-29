`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2026 13:09:51
// Design Name: 
// Module Name: atm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2026 11:47:08
// Design Name: 
// Module Name: atm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

//
// Inputs:
//     clk, reset            : Clock and system reset
//     card_in               : Card insertion detection signal
//     pin_entered           : High when user enters a PIN
//     pin_valid             : High when PIN is correct
//     pin_not_set           : High for a new card with no PIN
//     menu_withdraw         : Withdraw menu option selected
//     menu_pinchange        : PIN change menu option selected
//     menu_balance          : Balance inquiry selected
//     menu_statement        : Mini-statement selected
//     acc_verified          : Account verified (for PIN setup/reset)
//     acc_type_sel          : Account type selected (savings/current)
//     amount_ok             : Withdraw amount valid
//     atm_cash_ok           : ATM has enough cash for withdrawal
//     denom_*_ok            : Denomination bins available
//     otp_sent, otp_valid   : OTP sent and validated successfully
//     new_pin_set           : New PIN set successfully
//     receipt_req           : User requested receipt
//     cancel                : Cancel pressed by user (global interrupt)
//
// Outputs:
//     dispense_cash         : Dispense money signal
//     print_receipt         : Print receipt signal
//     eject_card            : Card ejection trigger
//     display_balance       : Show balance on screen
//     print_statement       : Print mini-statement signal
//     send_otp              : Trigger OTP sending mechanism
//     display_denom_*       : Show available denominations on display
//     state_out             : Current FSM state (for monitoring/debugging)
//
////////////////////////////////////////////////////////////////////////////////////

module atm(
    input clk, reset,

    // ===================== USER INTERACTION SIGNALS =====================
    input card_in, pin_entered, pin_valid, pin_not_set,
    input menu_withdraw, menu_pinchange, menu_balance, menu_statement,
    input acc_verified, acc_type_sel,
    input amount_ok, atm_cash_ok,
    input denom_100_ok, denom_500_ok, denom_2000_ok,
    input otp_sent, otp_valid, new_pin_set, receipt_req,
    input cancel,

    // ===================== OUTPUT SIGNALS =====================
    output reg dispense_cash, print_receipt, eject_card, display_balance, print_statement,
    output reg send_otp, display_denom_100, display_denom_500, display_denom_2000,
    output reg [4:0] state_out
);

    // ===================== STATE ENCODING =====================
    // Each state represents a specific ATM screen or operation stage.
    parameter IDLE                = 0,   // Waiting for card
              CARD_INSERTED       = 1,   // Card detected, check PIN type
              PIN_ENTRY           = 2,   // Waiting for PIN input
              TRANSACTION_MENU    = 3,   // Menu screen (withdraw, balance, etc.)
              WITHDRAW            = 4,   // Start withdraw process
              ACCOUNT_TYPE_SELECT = 5,   // Choose savings/current
              AMOUNT_ENTRY        = 6,   // User enters withdrawal amount
              CHECK_BALANCE       = 7,   // Check account & ATM balance
              DENOMINATION_SELECT = 8,   // Show available denominations
              DISPENSE_CASH       = 9,   // Dispense money
              RECEIPT_OPTION      = 10,  // Ask for receipt
              BALANCE_INQUIRY     = 11,  // Show balance
              MINI_STATEMENT      = 12,  // Print mini statement
              NEW_PIN_SETUP       = 13,  // For new cards (no PIN yet)
              PIN_RESET           = 14,  // PIN change option
              ACC_NUMBER_ENTRY    = 15,  // User enters last 4 digits of account
              ACCOUNT_VERIFY      = 24,  // (Added) Verifies account before OTP
              OTP_SEND            = 16,  // Send OTP to user
              OTP_VERIFY          = 17,  // Validate OTP input
              PIN_CONFIRM         = 18,  // Confirm and set new PIN
              CARD_EJECT          = 19,  // Physically eject card
              COMPLETE            = 20,  // Transaction completion/reset
              CANCELLED           = 21,  // Cancel pressed by user
              BLOCKED             = 22,  // 3 wrong PINs → Card blocked
              ERROR               = 23;  // Invalid conditions (e.g. cash unavailable)

    // 5-bit encoding supports up to 32 states (0-31)
    reg [4:0] state, next_state;

    // Track number of wrong PIN attempts (0-3)
    reg [1:0] wrong_pin_count;

    // =====================================================================
    //  SEQUENTIAL BLOCK (Triggered by Clock)
    // =====================================================================
    // Handles state transitions and wrong-PIN counter updates
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;              // Go to idle on reset
            wrong_pin_count <= 0;
        end else begin
            // Increment wrong PIN count for incorrect entries
            if (state == PIN_ENTRY && pin_entered && !pin_valid)
                wrong_pin_count <= wrong_pin_count + 1;
            // Reset wrong PIN counter after completion or new session
            else if (state == COMPLETE || state == IDLE)
                wrong_pin_count <= 0;

            // Update current state
            state <= next_state;
        end
    end

    // =====================================================================
    //  COMBINATIONAL BLOCK (Next-State Logic & Output Logic)
    // =====================================================================
    always @(*) begin
        // Default output values (inactive)
        dispense_cash = 0;
        print_receipt = 0;
        eject_card = 0;
        display_balance = 0;
        print_statement = 0;
        send_otp = 0;
        display_denom_100 = 0;
        display_denom_500 = 0;
        display_denom_2000 = 0;
        next_state = state;
        state_out = state;

        // ---------------- GLOBAL CANCEL OVERRIDE ----------------
        // Cancel can interrupt any state at any time
        if (cancel) begin
            next_state = CANCELLED;
        end 
        else 
        begin

            // ---------------- MAIN FSM CASE STRUCTURE ----------------
            case (state)

                // -----------------------------------------------------
                // BASE STATES
                // -----------------------------------------------------
                IDLE: begin
                    // Wait until card is inserted
                    if (card_in)
                        next_state = CARD_INSERTED;
                end

                CARD_INSERTED: begin
                    // If card has no PIN → new setup flow
                    if (pin_not_set)
                        next_state = NEW_PIN_SETUP;
                    // Else normal PIN entry
                    else
                        next_state = PIN_ENTRY;
                end

                PIN_ENTRY: begin
                    // Valid PIN → proceed to menu
                    if (pin_entered && pin_valid)
                        next_state = TRANSACTION_MENU;
                    // After 3 wrong attempts → block card
                    else if (pin_entered && !pin_valid && wrong_pin_count == 2)
                        next_state = BLOCKED;
                    // Else stay waiting for PIN
                    else
                        next_state = PIN_ENTRY;
                end

                // -----------------------------------------------------
                // MAIN TRANSACTION MENU
                // -----------------------------------------------------
                TRANSACTION_MENU: begin
                    // User chooses transaction type
                    if (menu_withdraw)
                        next_state = WITHDRAW;
                    else if (menu_pinchange)
                        next_state = PIN_RESET;
                    else if (menu_balance)
                        next_state = BALANCE_INQUIRY;
                    else if (menu_statement)
                        next_state = MINI_STATEMENT;
                    else
                        next_state = TRANSACTION_MENU; // stay until selection
                end

                // -----------------------------------------------------
                // WITHDRAWAL FLOW
                // -----------------------------------------------------
                WITHDRAW: 
                    next_state = ACCOUNT_TYPE_SELECT; // go to account selection

                ACCOUNT_TYPE_SELECT: begin
                    // Wait for user to choose account type
                    if (acc_type_sel)
                        next_state = AMOUNT_ENTRY;
                end

                AMOUNT_ENTRY:
                    // Move to check balance validity
                    next_state = CHECK_BALANCE;

                CHECK_BALANCE: begin
                    // Fail condition: not enough funds or cash
                    if (!amount_ok || !atm_cash_ok)
                        next_state = ERROR;
                    else
                        next_state = DENOMINATION_SELECT;
                end

                DENOMINATION_SELECT: begin
                    // Show available denominations dynamically
                    display_denom_100 = denom_100_ok;
                    display_denom_500 = denom_500_ok;
                    display_denom_2000 = denom_2000_ok;

                    // If any denomination available → proceed
                    if (denom_100_ok || denom_500_ok || denom_2000_ok)
                        next_state = DISPENSE_CASH;
                    else
                        next_state = ERROR; // no cash available
                end

                DISPENSE_CASH: begin
                    // Activate dispenser motor
                    dispense_cash = 1;
                    next_state = RECEIPT_OPTION;
                end

                RECEIPT_OPTION: begin
                    // Print receipt if requested
                    if (receipt_req)
                        print_receipt = 1;
                    next_state = CARD_EJECT;
                end

                // -----------------------------------------------------
                // BALANCE INQUIRY / MINI STATEMENT FLOWS
                // -----------------------------------------------------
                BALANCE_INQUIRY: begin
                    display_balance = 1;     // Show balance on display
                    if (receipt_req)
                        print_receipt = 1;   // Optionally print balance receipt
                    next_state = CARD_EJECT;
                end

                MINI_STATEMENT: begin
                    print_statement = 1;     // Print mini-statement
                    next_state = CARD_EJECT;
                end

                // -----------------------------------------------------
                // NEW PIN SETUP & PIN RESET FLOWS
                // -----------------------------------------------------
                NEW_PIN_SETUP: 
                    next_state = ACC_NUMBER_ENTRY; // New card → enter account digits

                PIN_RESET:
                    next_state = ACC_NUMBER_ENTRY; // PIN change → same step

                ACC_NUMBER_ENTRY: begin
                    // User enters last-4-digits, move to verification
                    next_state = ACCOUNT_VERIFY;
                end

                ACCOUNT_VERIFY: begin
                    // External database verifies digits
                    if (acc_verified)
                        next_state = OTP_SEND;
                    else
                        next_state = ACCOUNT_VERIFY; // Wait until verified
                end

                OTP_SEND: begin
                    send_otp = 1; // Trigger OTP send mechanism
                    if (otp_sent)
                        next_state = OTP_VERIFY;
                    else
                        next_state = OTP_SEND; // Wait until confirmed
                end

                OTP_VERIFY: begin
                    // OTP accepted → move to PIN confirmation
                    if (otp_valid)
                        next_state = PIN_CONFIRM;
                    // OTP rejected → Error → eject card
                    else
                        next_state = ERROR;
                end

                PIN_CONFIRM: begin
                    // Wait for new PIN set confirmation
                    if (new_pin_set)
                        next_state = RECEIPT_OPTION;
                    else
                        next_state = PIN_CONFIRM;
                end

                // -----------------------------------------------------
                // END / EXIT STATES
                // -----------------------------------------------------
                CARD_EJECT: begin
                    eject_card = 1;          // Trigger eject mechanism
                    next_state = COMPLETE;   // Move to completion
                end

                COMPLETE:
                    next_state = IDLE;       // Go back to IDLE for next customer

                // -----------------------------------------------------
                // SPECIAL HANDLING STATES
                // -----------------------------------------------------
                CANCELLED, BLOCKED, ERROR: begin
                    // All error/cancel/blocked paths end here
                    eject_card = 1;          // Always eject card
                    next_state = COMPLETE;   // Then reset system
                end

                // Default safety net
                default:
                    next_state = IDLE;
            endcase
        end
    end

endmodule


