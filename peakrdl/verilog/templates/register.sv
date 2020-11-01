{%- macro body(node, offset='') %}
// ============================================================
// Register: {{node.get_rel_path(node.parent)}}
{%- for child in node.children() %}
//    {{child.get_rel_path(node)}}[{{'%2d'%child.msb}}:{{'%2d'%child.lsb}}]: hw={{'%-5s'%child.get_property('hw').name}} sw={{'%-5s'%child.get_property('sw').name}} reset=0x{{'%x'%(child.get_property('reset') or 0)}}
{%- endfor %}
// ============================================================
wire {{signal(node)}}_sw_wr = valid && !read && (addr == ({{offset}}));
wire {{signal(node)}}_sw_rd = valid &&  read && (addr == ({{offset}}));
reg  [DATA_WIDTH-1:0] {{signal(node)}}_q;

always @ (*) begin
    {{signal(node)}}_q[{{node.bit_range}}] <= 'b0;
{%- for child in node.children() %}
    {{signal(node)}}_q[{{child.bit_range}}] <= {{signal(child)}}_q;
{%- endfor %}
end

// masked version of sw write data
wire [DATA_WIDTH-1:0] {{signal(node)}}_sw_data = (wdata & mask) | ({{signal(node)}}_q & ~mask);
// masked version of return data
assign {{signal(node)}}_rdata = {{signal(node)}}_sw_rd ? {{signal(node)}}_q : 'b0;

{%- for child in node.children() %}

// Field: {{child.get_rel_path(node)}} 

{%- if child.is_hw_writable %}
input wire         {{signal(child)}}_wr;
input wire [{{child.bit_range}}] {{signal(child)}}_wdata;

{%- endif -%}

{%- if child.get_property('counter') %}
input wire         {{signal(child)}}_incr;

{%- endif -%}

{%- if not child.implements_storage %}
    {%- if child.is_hw_writable %}
assign {{signal(child)}}_q = {{signal(child)}}_wdata;

    {%- else %}
assign {{signal(child)}}_q = {{child.get_property('reset')}};

    {%- endif %}
{%- else %}
    {%- if child.get_property('reset') %}
always_ff @ (posedge clk, negedge resetn)
    if (~resetn) begin
        {{signal(child)}}_q <= {{child.get_property('reset')}};
    end else

    {%- else %}
always_ff @ (posedge clk)

    {%- endif %}
    begin
        {%- if child.is_sw_writable %}
        // Software write
        if ({{signal(node)}}_sw_wr) begin
        {%- if child.get_property('onwrite') == OnWriteType.wclr %}
            {{signal(child)}}_q <= 'b0;
        {%- else %}
            {{signal(child)}}_q <= {{signal(node)}}_sw_data[{{child.msb}}:{{child.lsb}}];
        {%- endif %}
        end
        {%- endif -%}

        {%- if child.is_hw_writable %}
        // Hardware Write
        if ({{signal(child)}}_wr) begin
            {{signal(child)}}_q <= {{signal(child)}}_wdata;
        end
        {%- endif -%}

        {%- if child.get_property('counter') %}
        // Counter updates
        if ({{signal(child)}}_incr) begin
            {{signal(child)}}_q <= {{signal(child)}}_q + {{child.get_property('incrvalue')}};
        end
        {%- endif %}
    end

{%- endif %}

{%- endfor -%}
{%- endmacro %}
