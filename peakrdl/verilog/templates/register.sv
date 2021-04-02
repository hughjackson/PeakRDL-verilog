{%- macro body(node, offset='', index='') %}
// ============================================================
// Register: {{node.get_rel_path(node.parent).upper()}}
{%- for child in node.fields() %}
//    [{{child.bit_range}}] {{'%20s'%child.get_rel_path(node)}}: hw={{'%-5s'%child.get_property('hw').name}} sw={{'%-5s'%child.get_property('sw').name}} reset=0x{{'%x'%(child.get_property('reset') or 0)}}
{%- endfor %}
// ============================================================
logic                  {{signal(node)}}_decode;
logic                  {{signal(node)}}_sw_wr;
logic                  {{signal(node)}}_sw_rd;
logic [DATA_WIDTH-1:0] {{signal(node)}}_q;

assign {{signal(node)}}_decode = (addr == ({{offset}}));
assign {{signal(node)}}_sw_wr = valid && !read && {{signal(node)}}_decode;
assign {{signal(node)}}_sw_rd = valid &&  read && {{signal(node)}}_decode;

assign {{signal(node)}}_strb{{index}} = {{signal(node)}}_sw_wr;

always_comb begin
    {{signal(node)}}_q = '0;
{%- for child in node.fields() %}
    {{signal(node)}}_q[{{child.bit_range}}] = {{signal(child)}}_q{{index}};
{%- endfor %}
end

// masked version of return data
assign {{signal(node)}}_rdata{{index}} = {{signal(node)}}_sw_rd ? {{signal(node)}}_q : 'b0;

{%- for child in node.fields() %}

// Field: {{child.get_rel_path(node)}} 

{%- if not child.implements_storage %}
    {%- if child.is_hw_writable %}
assign {{signal(child)}}_q{{index}} = {{signal(child)}}_wdata;

    {%- else %}
assign {{signal(child)}}_q{{index}} = {{child.get_property('reset')}};

    {%- endif %}
{%- else %}
always_ff @ (posedge clk, negedge resetn)
    if (~resetn) begin
        {{signal(child)}}_q{{index}} <= {{child.get_property('reset', default=0)}};
    end else begin
        {%- if child.get_property('singlepulse') %}
        // Defined as single pulse, clear value from last cycle
        {{signal(child)}}_q{{index}} <= '0;
        {%- endif %}

        {%- if child.is_sw_readable and child.get_property('onread') %}
        // Software read
        if ({{signal(node)}}_sw_rd) begin
        {%- if child.get_property('onread') == OnReadType.rclr %}
            {{signal(child)}}_q{{index}} <= '0;

        {%- elif child.get_property('onread') == OnReadType.rset %}
            {{signal(child)}}_q{{index}} <= '1;

        {%- endif %}
        end
        {%- endif %}

        {%- if child.is_sw_writable %}
        // Software write
        if ({{signal(node)}}_sw_wr) begin
        {%- if child.get_property('onwrite') == OnWriteType.woset %}
            {{signal(child)}}_q{{index}} <=  masked_data[{{child.bit_range}}] |  {{signal(child)}}_q{{index}};

        {%- elif child.get_property('onwrite') == OnWriteType.woclr %}
            {{signal(child)}}_q{{index}} <= ~masked_data[{{child.bit_range}}] &  {{signal(child)}}_q{{index}};

        {%- elif child.get_property('onwrite') == OnWriteType.wot %}
            {{signal(child)}}_q{{index}} <=  masked_data[{{child.bit_range}}] ^  {{signal(child)}}_q{{index}};

        {%- elif child.get_property('onwrite') == OnWriteType.wzs %}
            {{signal(child)}}_q{{index}} <= ~masked_data[{{child.bit_range}}] |  {{signal(child)}}_q{{index}};

        {%- elif child.get_property('onwrite') == OnWriteType.wzc %}
            {{signal(child)}}_q{{index}} <=  masked_data[{{child.bit_range}}] &  {{signal(child)}}_q{{index}};

        {%- elif child.get_property('onwrite') == OnWriteType.wzt %}
            {{signal(child)}}_q{{index}} <= ~masked_data[{{child.bit_range}}] ^  {{signal(child)}}_q{{index}};

        {%- elif child.get_property('onwrite') == OnWriteType.wclr %}
            {{signal(child)}}_q{{index}} <= '0;

        {%- elif child.get_property('onwrite') == OnWriteType.wset %}
            {{signal(child)}}_q{{index}} <= '1;

        {%- else %}
            {{signal(child)}}_q{{index}} <=  masked_data[{{child.bit_range}}] | ({{signal(child)}}_q{{index}} & ~mask[{{child.bit_range}}]);

        {%- endif %}
        end
        {%- endif -%}

        {%- if child.is_hw_writable %}
        // Hardware Write
        if ({{signal(child)}}_wr{{index}}) begin
            {{signal(child)}}_q{{index}} <= {{signal(child)}}_wdata{{index}};
        end
        {%- endif -%}

        {%- if child.is_up_counter %}
        // Counter increment
        {{signal(child)}}_overflow{{index}} <= 1'b0;
        if ({{get_counter_enable(child, index, 'incr')}}) begin
            /* verilator lint_off WIDTH */
            { {{signal(child)}}_overflow{{index}},
             {{signal(child)}}_q{{index}} } <= {{signal(child)}}_q{{index}} + {{get_counter_value(child, index, 'incr')}};
            /* verilator lint_on WIDTH */
        end
        {%- endif %}
        {%- if child.is_down_counter %}
        // Counter decrement
        {{signal(child)}}_underflow{{index}} <= 1'b0;
        if ({{get_counter_enable(child, index, 'decr')}}) begin
            /* verilator lint_off WIDTH */
            { {{signal(child)}}_underflow{{index}},
              {{signal(child)}}_q{{index}} } <= {{signal(child)}}_q{{index}} - {{get_counter_value(child, index, 'decr')}};
            /* verilator lint_on WIDTH */
        end
        {%- endif %}
    end


{%- endif %}

{%- endfor -%}
{%- endmacro %}
