`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2026 13:12:28
// Design Name: 
// Module Name: atm_tb
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
// Create Date: 12.11.2025 23:23:52
// Design Name: 
// Module Name: tb
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

module atm_tb;

    // Inputs
    reg clk, reset;
    reg card_in, pin_entered, pin_valid, pin_not_set;
    reg menu_withdraw, menu_pinchange, menu_balance, menu_statement;
    reg acc_verified, acc_type_sel;
    reg amount_ok, atm_cash_ok;
    reg denom_100_ok, denom_500_ok, denom_2000_ok;
    reg otp_sent, otp_valid, new_pin_set, receipt_req;
    reg cancel;

    // Outputs
    wire dispense_cash, print_receipt, eject_card, display_balance, print_statement;
    wire send_otp, display_denom_100, display_denom_500, display_denom_2000;
    wire [4:0] state_out;

    // Instantiate DUT
    atm uut (
        .clk(clk), .reset(reset),
        .card_in(card_in), .pin_entered(pin_entered), .pin_valid(pin_valid), .pin_not_set(pin_not_set),
        .menu_withdraw(menu_withdraw), .menu_pinchange(menu_pinchange),
        .menu_balance(menu_balance), .menu_statement(menu_statement),
        .acc_verified(acc_verified), .acc_type_sel(acc_type_sel),
        .amount_ok(amount_ok), .atm_cash_ok(atm_cash_ok),
        .denom_100_ok(denom_100_ok), .denom_500_ok(denom_500_ok), .denom_2000_ok(denom_2000_ok),
        .otp_sent(otp_sent), .otp_valid(otp_valid), .new_pin_set(new_pin_set), .receipt_req(receipt_req),
        .cancel(cancel),
        .dispense_cash(dispense_cash), .print_receipt(print_receipt),
        .eject_card(eject_card), .display_balance(display_balance),
        .print_statement(print_statement), .send_otp(send_otp),
        .display_denom_100(display_denom_100), .display_denom_500(display_denom_500),
        .display_denom_2000(display_denom_2000), .state_out(state_out)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    // Task to reset all inputs
    task reset_inputs;
    begin
        card_in = 0; pin_entered = 0; pin_valid = 0; pin_not_set = 0;
        menu_withdraw = 0; menu_pinchange = 0; menu_balance = 0; menu_statement = 0;
        acc_verified = 0; acc_type_sel = 0; amount_ok = 0; atm_cash_ok = 0;
        denom_100_ok = 0; denom_500_ok = 0; denom_2000_ok = 0;
        otp_sent = 0; otp_valid = 0; new_pin_set = 0; receipt_req = 0;
        cancel = 0;
    end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        reset_inputs;
        #10 reset = 0;

        // -------- Scenario 1: Cash Withdrawal (normal) --------
      
        #10 card_in = 1; #10 card_in = 0;
        #10 pin_entered = 1; pin_valid = 1; #10 pin_entered = 0;
        #10 menu_withdraw = 1; #10 menu_withdraw = 0;
        #10 acc_type_sel = 1; #10 amount_ok = 1; atm_cash_ok = 1;
        #10 denom_100_ok = 1; denom_500_ok = 1; denom_2000_ok = 0;
        #10 receipt_req = 1;
        #30 reset_inputs;

        // -------- Scenario 2: New PIN Setup (uses ACCOUNT_VERIFY) --------
      
        #10 card_in = 1; pin_not_set = 1; #10 pin_not_set = 0;
        // Next state ACC_NUMBER_ENTRY -> ACCOUNT_VERIFY. Simulate account verification:
        #10 acc_verified = 1; // last-4-digits verified externally
        #10 otp_sent = 1; // OTP sent
        #10 otp_valid = 1; // OTP entered correct
        #10 new_pin_set = 1; // new PIN successfully set
        #10 receipt_req = 1;
        #30 reset_inputs;

        // -------- Scenario 3: PIN Reset (existing card) --------
       
        #10 card_in = 1; #10 pin_entered = 1; pin_valid = 1; #10 pin_entered = 0;
        #10 menu_pinchange = 1; #10 menu_pinchange = 0;
        // ACC_NUMBER_ENTRY -> ACCOUNT_VERIFY:
        #10 acc_verified = 1;
        #10 otp_sent = 1; #10 otp_valid = 1;
        #10 new_pin_set = 1; #10 receipt_req = 1;
        #30 reset_inputs;

        // -------- Scenario 4: Balance Inquiry --------
     
        #10 card_in = 1; #10 pin_entered = 1; pin_valid = 1;
        #10 menu_balance = 1; #10 receipt_req = 1;
        #30 reset_inputs;

        // -------- Scenario 5: Mini Statement --------
    
        #10 card_in = 1; #10 pin_entered = 1; pin_valid = 1;
        #10 menu_statement = 1;
        #30 reset_inputs;

        // -------- Scenario 6: Cancel during operation --------
    
        #10 card_in = 1; #10 pin_entered = 1; pin_valid = 1;
        #10 menu_withdraw = 1; #10 cancel = 1; #10 cancel = 0;
        #30 reset_inputs;

        // -------- Scenario 7: Wrong PIN block --------
      
        #10 card_in = 1;
        repeat (3) begin
            #10 pin_entered = 1; pin_valid = 0; #10 pin_entered = 0;
        end
        #30 reset_inputs;

        // -------- Scenario 8: ERROR path (ATM out of cash) --------
   
        #10 card_in = 1; #10 pin_entered = 1; pin_valid = 1;
        #10 menu_withdraw = 1; #10 acc_type_sel = 1;
        #10 amount_ok = 1; atm_cash_ok = 0; // trigger ERROR
        #30 reset_inputs;

        #50 $finish;
    end

   

endmodule

