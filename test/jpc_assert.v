
task jpc_assert(input string test_id, input bit condition, input time clock);
    begin
      if (!condition) begin
        $display("[TEST:%s FAILED]: %s", test_id, assert_msg);
      end else begin
        $display("[TEST:%s PASSED]: %s", test_id, assert_msg);
      end
    end
endtask