{%- macro body(node, offset='', index='') %}
// ============================================================
// Register: {{node.get_rel_path(node.parent).upper()}}
{%- for child in node.children() %}
//    [{{child.bit_range}}] {{'%20s'%child.get_rel_path(node)}}: hw={{'%-5s'%child.get_property('hw').name}} sw={{'%-5s'%child.get_property('sw').name}} reset=0x{{'%x'%(child.get_property('reset') or 0)}}
{%- endfor %}
// ============================================================
logic                  {{signal(node)}}_decode;
logic                  {{signal(node)}}_sw_wr;
logic                  {{signal(node)}}_sw_rd;
logic [DATA_WIDTH-1:0] {{signal(node)}}_q;
logic [DATA_WIDTH-1:0] {{signal(node)}}_sw_data;

assign {{signal(node)}}_decode = (addr == ({{offset}}));
assign {{signal(node)}}_sw_wr = valid && !read && {{signal(node)}}_decode;
assign {{signal(node)}}_sw_rd = valid &&  read && {{signal(node)}}_decode;

assign {{signal(node)}}_strb{{index}} = {{signal(node)}}_sw_wr;

always @ (*) begin
    {{signal(node)}}_q[{{node.bit_range}}] <= 'b0;
{%- for child in node.children() %}
    {{signal(node)}}_q[{{child.bit_range}}] <= {{signal(child)}}_q{{index}};
{%- endfor %}
end

// masked version of sw write data
assign {{signal(node)}}_sw_data = (wdata & mask) | ({{signal(node)}}_q & ~mask);

// masked version of return data
assign {{signal(node)}}_rdata{{index}} = {{signal(node)}}_sw_rd ? {{signal(node)}}_q : 'b0;

{%- for child in node.children() %}

// Field: {{child.get_rel_path(node)}} 

{%- if not child.implements_storage %}
    {%- if child.is_hw_writable %}
assign {{signal(child)}}_q{{index}} = {{signal(child)}}_wdata;

    {%- else %}
assign {{signal(child)}}_q{{index}} = {{child.get_property('reset')}};

    {%- endif %}
{%- else %}
    {%- if child.get_property('reset') %}
always_ff @ (posedge clk, negedge resetn)
    if (~resetn) begin
        {{signal(child)}}_q{{index}} <= {{child.get_property('reset')}};
    end else

    {%- else %}
//always_ff @ (posedge clk)
always_ff @ (posedge clk, negedge resetn)
    if (~resetn) begin
        {{signal(child)}}_q{{index}} <= '0;
    end else

    {%- endif %}
    begin
        {%- if child.is_sw_writable %}
        // Software write
        if ({{signal(node)}}_sw_wr) begin
        {%- if child.get_property('onwrite') == OnWriteType.wclr %}
            {{signal(child)}}_q{{index}} <= 'b0;
        {%- else %}
            {{signal(child)}}_q{{index}} <= {{signal(node)}}_sw_data[{{child.msb}}:{{child.lsb}}];
        {%- endif %}
        end
        {%- endif -%}

        {%- if child.is_hw_writable %}
        // Hardware Write
        if ({{signal(child)}}_wr) begin
            {{signal(child)}}_q{{index}} <= {{signal(child)}}_wdata;
        end
        {%- endif -%}

        {%- if child.get_property('counter') %}
        // Counter updates
        if ({{signal(child)}}_incr) begin
            {{signal(child)}}_q{{index}} <= {{signal(child)}}_q + {{child.get_property('incrvalue')}};
        end
        {%- endif %}
    end

{%- endif %}

{%- endfor -%}
{%- endmacro %}
