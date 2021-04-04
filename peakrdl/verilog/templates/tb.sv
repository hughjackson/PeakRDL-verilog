{%- import 'addressable.sv' as addressable with context -%}

`define ST(x) `"x`"
`define CHECK_EQUAL(val, exp) \
    assert(exp==val) else $fatal  ("\n\t%s == %s: 0x%0h != 0x%0h\n", `ST(val), `ST(exp), val, exp);

`define HW_WRITE(name, idx, val) \
            ``name``_wr``idx <= 1'b1; \
            ``name``_wdata``idx <= val; \
            @(posedge clk); \
            ``name``_wr``idx <= '0;

`define HW_COUNT(name, idx, dir) \
            ``name``_``dir````idx <= 1'b1; \
            @(posedge clk); \
            ``name``_``dir````idx <= 1'b0; \

`define HW_COUNT_VAL(name, idx, dir, val) \
            ``name``_``dir````idx <= 1'b1; \
            ``name``_``dir``value``idx <= val; \
            @(posedge clk); \
            ``name``_``dir````idx <= 1'b0; \

`define SW_READ(sw_addr) \
            valid <= 1'b1; \
            read <= 1'b1; \
            addr <= sw_addr; \
            @(posedge clk); \
            valid <= 1'b0;

`define SW_WRITE(sw_addr, sw_data) \
            valid <= 1'b1; \
            read <= 1'b0; \
            addr <= sw_addr; \
            wdata <= sw_data; \
            wmask <= '1; \
            @(posedge clk); \
            valid <= 1'b0;

// This file was autogenerated by PeakRDL-verilog
module {{get_inst_name(top_node)}}_tb #(
    parameter                                ADDR_OFFSET = 'h0,  // Module's offset in the main address map
    parameter                                ADDR_WIDTH  = 32,   // Width of SW address bus
    parameter                                DATA_WIDTH  = 32    // Width of SW data bus
);
    // Clocks and resets
    logic                              clk;
    logic                              resetn;

{%- for node in top_node.descendants() -%}
{%- if isinstance(node, RegNode) %}

    // Register {{get_inst_name(node).upper()}}
  {%- if node.has_intr %}
    logic {{node.full_array_ranges}}        {{signal(node, '', 'intr')}};
  {%- endif %}

{%- elif isinstance(node, FieldNode) -%}
  {%- if node.get_property('swmod') %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'swmod')}};
  {%- endif %}
  {%- if node.get_property('swacc') %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'swacc')}};
  {%- endif %}
  {%- if node.get_property('swwe') == True %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'swwe')}};
  {%- elif node.get_property('swwel') == True %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'swwel')}};
  {%- endif %}
 {%- if node.is_hw_writable %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'wr')}};
    logic {{node.parent.full_array_ranges}}[{{node.bit_range}}] {{signal(node, '', 'wdata')}};

 {%- endif -%}
 {%- if node.is_hw_readable %}
    logic {{node.parent.full_array_ranges}}[{{node.bit_range}}] {{signal(node, '', 'q')}};

 {%- endif -%}
  {%- if node.get_property('intr') %}
    logic {{node.parent.full_array_ranges}}[{{node.bit_range}}] {{signal(node, '', 'intr')}};
  {%- endif -%}
 {%- if node.is_up_counter %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'incr')}};
  {%- if node.get_property('incrwidth') %}
    logic {{node.parent.full_array_ranges}}[{{node.get_property('incrwidth')}}-1:0] {{signal(node, '', 'incrvalue')}};
  {%- endif -%}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'overflow')}};
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'incrthreshold')}};
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'incrsaturate')}};
 {%- endif -%}
 {%- if node.is_down_counter %}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'decr')}};
  {%- if node.get_property('decrwidth') %}
    logic {{node.parent.full_array_ranges}}[{{node.get_property('decrwidth')}}-1:0] {{signal(node, '', 'decrvalue')}};
  {%- endif -%}
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'underflow')}};
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'decrthreshold')}};
    logic {{node.parent.full_array_ranges}}        {{signal(node, '', 'decrsaturate')}};
 {%- endif -%}
{%- endif -%}
{%- endfor %}

    // Register Bus
    logic                             valid;    // active high
    logic                             read;     // indicates request is a read
    logic            [ADDR_WIDTH-1:0] addr;     // address (byte aligned, absolute address)
    logic            [DATA_WIDTH-1:0] wdata;    // write data
    logic          [DATA_WIDTH/8-1:0] wmask;    // write mask
    logic            [DATA_WIDTH-1:0] rdata;    // read data

    initial begin
        resetn <= 1'b0;
        #20 @(posedge clk) resetn <= 1'b1;
        $display("%t: TB: reset complete", $time());
    end
    initial begin
        clk <= 1'b0;
        forever #5 clk <= ~clk;
    end

    {{get_inst_name(top_node)}}_rf #(
        .ADDR_OFFSET(ADDR_OFFSET),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (.*);

    initial begin
        logic                  carry;
        logic [DATA_WIDTH-1:0] temp;
        logic [DATA_WIDTH-1:0] value;

        // init all hw inputs
{%- for node in top_node.descendants() -%}
{%- if isinstance(node, FieldNode) %}
{%- if node.get_property('swwe') == True %}
    {{signal(node, '', 'swwe')}} = '1;
{%- elif node.get_property('swwel') == True %}
    {{signal(node, '', 'swwel')}} = '0;
{%- endif %}
{%- if node.is_hw_writable %}
        {{signal(node, '', 'wr')}} <= '0;
        {{signal(node, '', 'wdata')}} <= '0;
{%- endif -%}
{%- if node.is_up_counter %}
        {{signal(node, '', 'incr')}} <= '0;
    {%- if node.get_property('incrwidth') %}
        {{signal(node, '', 'incrvalue')}} <= '0;
    {%- endif -%}
{%- endif -%}
{%- if node.is_down_counter %}
        {{signal(node, '', 'decr')}} <= '0;
    {%- if node.get_property('decrwidth') %}
        {{signal(node, '', 'decrvalue')}} <= '0;
    {%- endif -%}
{%- endif -%}
{%- endif -%}
{%- endfor %}

        // init all sw input
        valid <= '0;
        read <= '0;
        addr <= '0;
        wdata <= '0;
        wmask <= '1;

        @(posedge resetn);


{%- for node in top_node.descendants(unroll=True) -%}
{%- if isinstance(node, FieldNode) %}
        repeat(5) @(posedge clk);
        $display("%t: Testcase ({{signal(node)}} {{full_idx(node.parent)}}):", $time());
    {%- if node.is_hw_writable %}
        $display("%t:\tHardware write test", $time());
        for (int IDX = {{node.lsb}}; IDX <= {{node.msb}}; ++IDX) begin

            `HW_WRITE( {{signal(node)}}, {{full_idx(node.parent)}}, (1 << (IDX-{{node.lsb}})) )
            `SW_READ( {{node.parent.absolute_address}} )
            `CHECK_EQUAL(rdata[{{node.bit_range}}], (1 << (IDX-{{node.lsb}})))

            `HW_WRITE( {{signal(node)}}, {{full_idx(node.parent)}}, 0 )
            `SW_READ( {{node.parent.absolute_address}} )
            `CHECK_EQUAL(rdata[{{node.bit_range}}], 0)

        end
    {%- endif -%}
    {%- if node.is_up_counter and not node.get_property('incr') %}
        $display("%t:\tHardware increment test", $time());
        for (int IDX = 0; IDX <= 4; ++IDX) begin

            `SW_READ( {{node.parent.absolute_address}} )
            temp = rdata[{{node.bit_range}}];

        {%- if node.get_property('incrwidth') %}
            value = $urandom_range(0,2**{{node.get_property('incrwidth')}}-1);
            `HW_COUNT_VAL( {{signal(node)}}, {{full_idx(node.parent)}}, incr, value )
        {%- elif type(node.get_property('incrvalue')) == type(node) %}
            `SW_READ( {{node.get_property('incrvalue').parent.absolute_address}} )
            value = rdata[{{node.get_property('incrvalue').bit_range}}];
            `HW_COUNT( {{signal(node)}}, {{full_idx(node.parent)}}, incr )
        {%- else %}
            value = {{node.get_property('incrvalue', default=1)}};
            `HW_COUNT( {{signal(node)}}, {{full_idx(node.parent)}}, incr )
        {%- endif %}

            // increment
            {carry, temp} = temp + value;
            
            // saturate
        {%- if type(node.get_property('incrsaturate')) == type(node) %}
            `SW_READ( {{node.get_property('incrsaturate').parent.absolute_address}} )
            value = rdata[{{node.get_property('incrsaturate').bit_range}}];
        {%- elif node.get_property('incrsaturate') %}
            value = {{node.get_property('incrvalue', default=2**node.width-1)}};
        {%- endif %}
        {%- if node.get_property('incrsaturate') %}
            #1 `CHECK_EQUAL({{signal(node, '', 'incrsaturate')}}{{full_idx(node.parent)}}, temp >= value)
            if (temp >= value) temp = value;
            if (temp >= value) carry = 0; // no wrap if saturated
        {%- endif %}

            // threshold
        {%- if type(node.get_property('incrthreshold')) == type(node) %}
            `SW_READ( {{node.get_property('incrthreshold').parent.absolute_address}} )
            value = rdata[{{node.get_property('incrthreshold').bit_range}}];
        {%- elif node.get_property('incrthreshold') %}
            value = {{node.get_property('incrvalue', default=2**node.width-1)}};
        {%- endif %}
        {%- if node.get_property('incrthreshold') %}
            #1 `CHECK_EQUAL({{signal(node, '', 'incrthreshold')}}{{full_idx(node.parent)}}, temp >= value)
        {%- endif %}

            // wrap
        {%- if node.get_property('overflow') %}
            #1 `CHECK_EQUAL({{signal(node, '', 'overflow')}}{{full_idx(node.parent)}}, carry)
        {%- endif %}

            `SW_READ( {{node.parent.absolute_address}} )
            `CHECK_EQUAL(rdata[{{node.bit_range}}], temp[{{node.width}}-1:0])

        end
    {%- endif -%}
    {%- if node.is_down_counter %}
        $display("%t:\tHardware decrement test", $time());
        for (int IDX = 0; IDX <= 4; ++IDX) begin

            `SW_READ( {{node.parent.absolute_address}} )
            temp = rdata[{{node.bit_range}}];

        {%- if node.get_property('decrwidth') %}
            value = $urandom_range(0,2**{{node.get_property('decrwidth')}}-1);
            `HW_COUNT_VAL( {{signal(node)}}, {{full_idx(node.parent)}}, decr, value )
        {%- elif type(node.get_property('decrvalue')) == type(node) %}
            `SW_READ( {{node.get_property('decrvalue').parent.absolute_address}} )
            value = rdata[{{node.get_property('decrvalue').bit_range}}];
            `HW_COUNT( {{signal(node)}}, {{full_idx(node.parent)}}, decr )
        {%- else %}
            value = {{node.get_property('decrvalue', default=1)}};
            `HW_COUNT( {{signal(node)}}, {{full_idx(node.parent)}}, decr )
        {%- endif %}

            // decrement
            {carry, temp} = temp - value;
            
            // saturate
        {%- if type(node.get_property('decrsaturate')) == type(node) %}
            `SW_READ( {{node.get_property('decrsaturate').parent.absolute_address}} )
            value = rdata[{{node.get_property('decrsaturate').bit_range}}];
        {%- elif node.get_property('decrsaturate') %}
            value = {{node.get_property('decrvalue', default=0)}};
        {%- endif %}
        {%- if node.get_property('decrsaturate') %}
            #1 `CHECK_EQUAL({{signal(node, '', 'decrsaturate')}}{{full_idx(node.parent)}}, temp <= value)
            if (temp <= value) temp = value;
            if (temp >= value) carry = 0; // no wrap if saturated
        {%- endif %}

            // threshold
        {%- if type(node.get_property('decrthreshold')) == type(node) %}
            `SW_READ( {{node.get_property('decrthreshold').parent.absolute_address}} )
            value = rdata[{{node.get_property('decrthreshold').bit_range}}];
        {%- elif node.get_property('decrthreshold') %}
            value = {{node.get_property('decrvalue', default=0)}};
        {%- endif %}
        {%- if node.get_property('decrthreshold') %}
            #1 `CHECK_EQUAL({{signal(node, '', 'decrthreshold')}}{{full_idx(node.parent)}}, temp <= value)
        {%- endif %}

            // wrap
        {%- if node.get_property('overflow') %}
            #1 `CHECK_EQUAL({{signal(node, '', 'underflow')}}{{full_idx(node.parent)}}, carry)
        {%- endif %}

            `SW_READ( {{node.parent.absolute_address}} )
            `CHECK_EQUAL(rdata[{{node.bit_range}}], temp[{{node.width}}-1:0])

        end
    {%- endif -%}
    {%- if node.is_hw_readable and node.is_sw_writable %}
        $display("%t:\tSoftware write (hardware read) test", $time());
        for (int IDX = {{node.lsb}}; IDX <= {{node.msb}}; ++IDX) begin

            temp = '0;
            temp[{{node.bit_range}}] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}};
        {%- if node.get_property('onwrite') == OnWriteType.woset %}
            temp[IDX] = 1;
            value = temp;
        {%- elif node.get_property('onwrite') == OnWriteType.woclr %}
            temp[IDX] = 0;
            value = temp;
        {%- elif node.get_property('onwrite') == OnWriteType.wot %}
            temp[IDX] = !temp[IDX];
            value = temp;
        {%- elif node.get_property('onwrite') == OnWriteType.wzs %}
            temp = '1;
            temp[IDX] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}}[IDX];
            value = '1;
        {%- elif node.get_property('onwrite') == OnWriteType.wzc %}
            temp = '0;
            temp[IDX] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}}[IDX];
            value = '0;
        {%- elif node.get_property('onwrite') == OnWriteType.wzt %}
            temp = ~temp;
            temp[IDX] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}}[IDX];
            value = ~temp;
        {%- elif node.get_property('onwrite') == OnWriteType.wclr %}
            temp = '0;
            value = '0;
        {%- elif node.get_property('onwrite') == OnWriteType.wset %}
            temp = '1;
            value = '1;
        {%- else %}
            temp = (1 << IDX);
            value = '0;
        {%- endif %}

            `SW_WRITE( {{node.parent.absolute_address}}, (1 << IDX) )
            #1 `CHECK_EQUAL({{signal(node, '', 'q')}}{{full_idx(node.parent)}}, temp[{{node.bit_range}}])

            `SW_WRITE( {{node.parent.absolute_address}}, 0 )
            #1 `CHECK_EQUAL({{signal(node, '', 'q')}}{{full_idx(node.parent)}}, value[{{node.bit_range}}])

        end
    {%- endif -%}
    {%- if node.is_sw_readable and node.is_sw_writable %}
        $display("%t:\tSoftware write (software read) test", $time());
        for (int IDX = {{node.lsb}}; IDX <= {{node.msb}}; ++IDX) begin

            temp = '0;
            `SW_READ( {{node.parent.absolute_address}} )
            temp[{{node.bit_range}}] = rdata[{{node.bit_range}}];
        {%- if node.get_property('onwrite') == OnWriteType.woset %}
            temp[IDX] = 1;
            value = temp;
        {%- elif node.get_property('onwrite') == OnWriteType.woclr %}
            temp[IDX] = 0;
            value = temp;
        {%- elif node.get_property('onwrite') == OnWriteType.wot %}
            temp[IDX] = !temp[IDX];
            value = temp;
        {%- elif node.get_property('onwrite') == OnWriteType.wzs %}
            temp = '1;
            temp[IDX] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}}[IDX];
            value = '1;
        {%- elif node.get_property('onwrite') == OnWriteType.wzc %}
            temp = '0;
            temp[IDX] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}}[IDX];
            value = '0;
        {%- elif node.get_property('onwrite') == OnWriteType.wzt %}
            temp = ~temp;
            temp[IDX] = {{signal(node, '', 'q')}}{{full_idx(node.parent)}}[IDX];
            value = ~temp;
        {%- elif node.get_property('onwrite') == OnWriteType.wclr %}
            temp = '0;
            value = '0;
        {%- elif node.get_property('onwrite') == OnWriteType.wset %}
            temp = '1;
            value = '1;
        {%- else %}
            temp = (1 << IDX);
            value = '0;
        {%- endif %}

            `SW_WRITE( {{node.parent.absolute_address}}, (1 << IDX) )
            `SW_READ( {{node.parent.absolute_address}} )
            `CHECK_EQUAL(rdata[{{node.bit_range}}], temp[{{node.bit_range}}])

            `SW_WRITE( {{node.parent.absolute_address}}, 0 )
            `SW_READ( {{node.parent.absolute_address}} )
            `CHECK_EQUAL(rdata[{{node.bit_range}}], value[{{node.bit_range}}])

        end
    {%- endif -%}
    {%- if node.get_property('counter') %}
    {%- endif -%}
{%- endif -%}
{%- endfor %}

        #200;
        $display("%t: TB: test complete", $time());
        $display("\n\t\t===================");
        $display(  "\t\t=   TEST PASSED   =");
        $display(  "\t\t===================\n");
        $finish();
    end

endmodule: {{get_inst_name(top_node)}}_tb

