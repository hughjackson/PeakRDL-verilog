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

always_comb begin
    {{signal(node)}}_q = '0;
{%- for child in node.fields() %}
    {{signal(node)}}_q[{{child.bit_range}}] = {{signal(child, index, 'q')}};
{%- endfor %}
end

{%- if node.has_intr %}

// Combined interrupt
assign {{signal(node, '', 'intr')}} = {% for child in node.fields() if child.get_property('intr') -%} 
                                        ( | {{signal(child, index, 'intr')}} ){{ " | " if not loop.last else ";" }}
                                      {%- endfor -%}
{%- endif %}

// masked version of return data
assign {{signal(node, index, 'rdata')}} = {{signal(node)}}_sw_rd ? {{signal(node)}}_q : 'b0;

{%- for child in node.fields() %}

// Field: {{child.get_rel_path(node)}} 

{%- if child.get_property('intr') %}
assign {{signal(child, index, 'intr')}} = {{signal(child, index, 'q')}}
    {%- if child.get_property('enable') -%}
        {{' '}}&& {{get_prop_value(child, index, 'enable')}}
    {%- elif child.get_property('mask') -%}
        {{' '}}&& ~{{get_prop_value(child, index, 'mask')}}
    {%- endif -%}
    ;
{%- endif %}

{%- if not child.implements_storage %}
    {%- if child.is_hw_writable %}
assign {{signal(child, index, 'q')}} = {{signal(child)}}_wdata;
    {%- else %}
assign {{signal(child, index, 'q')}} = {{child.get_property('reset')}};
    {%- endif %}

    {%- if child.get_property('swacc') %}
assign {{signal(child, index, 'swacc')}} = {{signal(node)}}_sw_rd;
    {%- endif -%}
    {%- if child.get_property('swmod') %}
assign {{signal(child, index, 'swmod')}} = 1'b0; // WARNING: this could be an input error
    {%- endif %}

{%- else %}
always_ff @ (posedge clk, negedge resetn)
    if (~resetn) begin
        {{signal(child, index, 'q')}} <= {{child.get_property('reset', default=0)}};
        {%- if child.get_property('swmod') %}
        {{signal(child, index, 'swmod')}} <= 1'b0;
        {%- endif %}
        {%- if child.get_property('swacc') %}
        {{signal(child, index, 'swacc')}} <= 1'b0;
        {%- endif %}
    end else begin
        {%- if child.get_property('swmod') %}
        {{signal(child, index, 'swmod')}} <= 1'b0;
        {%- endif %}

        {%- if child.get_property('swacc') %}
        {{signal(child, index, 'swacc')}} <= 
            {%- if child.is_sw_readable and child.is_sw_writable -%}
                {{' '}}{{signal(node)}}_sw_rd | {{signal(node)}}_sw_wr;
            {%- elif child.is_sw_readable -%}
                {{' '}}{{signal(node)}}_sw_rd;
            {%- elif child.is_sw_writable -%}
                {{' '}}{{signal(node)}}_sw_wr;
            {%- else -%}
                {{' '}}1'b0;
            {%- endif %}
        {%- endif %}

        {%- if child.get_property('singlepulse') %}
        // Defined as single pulse, clear value from last cycle
        {{signal(child, index, 'q')}} <= '0;
        {%- endif %}

        {%- if child.is_sw_readable and child.get_property('onread') %}
        // Software read
        if ({{signal(node)}}_sw_rd) begin

        {%- if child.get_property('swmod') %}
            {{signal(child, index, 'swmod')}} <= 1'b1;
        {%- endif %}

        {%- if child.get_property('onread') == OnReadType.rclr %}
            {{signal(child, index, 'q')}} <= '0;

        {%- elif child.get_property('onread') == OnReadType.rset %}
            {{signal(child, index, 'q')}} <= '1;

        {%- endif %}
        end
        {%- endif %}

        {%- if child.is_sw_writable %}
        // Software write
        if ({{signal(node)}}_sw_wr
          {%- if child.get_property('swwe') -%}
            {{' '}}&& {{get_prop_value(child, index, 'swwe')}}
          {%- elif child.get_property('swwel') -%}
            {{' '}}&& !{{get_prop_value(child, index, 'swwel')}}
          {%- endif -%}
            ) begin


        {%- if child.get_property('swmod') %}
            {{signal(child, index, 'swmod')}} <= 1'b1;
        {%- endif %}

        {%- if child.get_property('onwrite') == OnWriteType.woset %}
            {{signal(child, index, 'q')}} <=  masked_data[{{child.bit_range}}] |  {{signal(child, index, 'q')}};

        {%- elif child.get_property('onwrite') == OnWriteType.woclr %}
            {{signal(child, index, 'q')}} <= ~masked_data[{{child.bit_range}}] &  {{signal(child, index, 'q')}};

        {%- elif child.get_property('onwrite') == OnWriteType.wot %}
            {{signal(child, index, 'q')}} <=  masked_data[{{child.bit_range}}] ^  {{signal(child, index, 'q')}};

        {%- elif child.get_property('onwrite') == OnWriteType.wzs %}
            {{signal(child, index, 'q')}} <= ~masked_data[{{child.bit_range}}] |  {{signal(child, index, 'q')}};

        {%- elif child.get_property('onwrite') == OnWriteType.wzc %}
            {{signal(child, index, 'q')}} <=  masked_data[{{child.bit_range}}] &  {{signal(child, index, 'q')}};

        {%- elif child.get_property('onwrite') == OnWriteType.wzt %}
            {{signal(child, index, 'q')}} <= ~masked_data[{{child.bit_range}}] ^  {{signal(child, index, 'q')}};

        {%- elif child.get_property('onwrite') == OnWriteType.wclr %}
            {{signal(child, index, 'q')}} <= '0;

        {%- elif child.get_property('onwrite') == OnWriteType.wset %}
            {{signal(child, index, 'q')}} <= '1;

        {%- else %}
            {{signal(child, index, 'q')}} <=  masked_data[{{child.bit_range}}] | ({{signal(child, index, 'q')}} & ~mask[{{child.bit_range}}]);

        {%- endif %}
        end
        {%- endif -%}

        {%- if child.is_hw_writable %}
        // Hardware Write
        if ({{signal(child, index, 'wr')}}) begin
            {{signal(child, index, 'q')}} <= {{signal(child, index, 'wdata')}};
        end
        {%- endif -%}

        {%- if child.is_up_counter %}
        // Counter increment
        {{signal(child, index, 'overflow')}} <= 1'b0;
        if ({{get_prop_value(child, index, 'incr', hw_on_none=True)}}) begin
            logic [{{child.msb+1}}:{{child.lsb}}] next;
            /* verilator lint_off WIDTH */
            next = {{signal(child, index, 'q')}} + {{get_counter_value(child, index, 'incr')}};
            /* verilator lint_on WIDTH */

            { {{signal(child, index, 'overflow')}},
             {{signal(child, index, 'q')}} } <= next;

            {%- if child.get_property('incrsaturate') %}
            // saturate
            {{signal(child, index, 'overflow')}} <= 1'b0;
            {{signal(child, index, 'incrsaturate')}} <= 1'b0;
            if (next[{{child.msb+1}}] ||
                (next[{{child.bit_range}}] >= {{get_prop_value(child, index, 'incrsaturate',
                                                               hw_on_true=False, default=-1,
                                                               width=child.width)}})) begin
                {{signal(child, index, 'q')}} <= {{get_prop_value(child, index, 'incrsaturate',
                                                               hw_on_true=False, default=-1,
                                                               width=child.width)}};
                {{signal(child, index, 'incrsaturate')}} <= 1'b1;
            end
            {%- endif %}

            {%- if child.get_property('incrthreshold') %}

            // threshold
            {{signal(child, index, 'incrthreshold')}} <= 1'b0;
            if (next[{{child.msb+1}}] ||
                (next[{{child.bit_range}}] >= {{get_prop_value(child, index, 'incrthreshold',
                                                               hw_on_true=False, default=-1,
                                                               width=child.width)}})) begin
                {{signal(child, index, 'incrthreshold')}} <= 1'b1;
            end
            {%- endif %}
        end
        {%- endif %}

        {%- if child.is_down_counter %}
        // Counter decrement
        {{signal(child, index, 'underflow')}} <= 1'b0;
        if ({{get_prop_value(child, index, 'decr', hw_on_none=True)}}) begin
            logic [{{child.msb+1}}:{{child.lsb}}] next;
            /* verilator lint_off WIDTH */
            next = {{signal(child, index, 'q')}} - {{get_counter_value(child, index, 'decr')}};
            /* verilator lint_on WIDTH */

            { {{signal(child, index, 'underflow')}},
             {{signal(child, index, 'q')}} } <= next;

            {%- if child.get_property('decrsaturate') %}

            // saturate
            {{signal(child, index, 'underflow')}} <= 1'b0;
            {{signal(child, index, 'decrsaturate')}} <= 1'b0;
            if (next[{{child.msb+1}}] ||
                (next[{{child.bit_range}}] <= {{get_prop_value(child, index, 'decrsaturate',
                                                               hw_on_true=False, default=0,
                                                               width=child.width)}})) begin
                {{signal(child, index, 'q')}} <= {{get_prop_value(child, index, 'decrsaturate',
                                                               hw_on_true=False, default=0,
                                                               width=child.width)}};
                {{signal(child, index, 'decrsaturate')}} <= 1'b1;
            end
            {%- endif %}

            {%- if child.get_property('decrthreshold') %}

            // threshold
            {{signal(child, index, 'decrthreshold')}} <= 1'b0;
            if (next[{{child.msb+1}}] ||
                (next[{{child.bit_range}}] <= {{get_prop_value(child, index, 'decrthreshold',
                                                               hw_on_true=False, default=0,
                                                               width=child.width)}})) begin
                {{signal(child, index, 'decrthreshold')}} <= 1'b1;
            end
            {%- endif %}
        end
        {%- endif %}
    end


{%- endif %}

{%- endfor -%}
{%- endmacro %}
