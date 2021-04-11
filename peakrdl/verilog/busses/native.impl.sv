assign sw_wr    = valid && !read;
assign sw_rd    = valid &&  read;
assign sw_wdata = wdata;
assign rdata    = sw_rdata;

// convert byte mask to bit mask
always_comb begin
    int byte_idx;
    for (byte_idx = 0; byte_idx < DATA_WIDTH/8; byte_idx+=1) begin
        sw_mask[8*(byte_idx+1)-1 -: 8] = {8{wmask[byte_idx]}};
    end
end