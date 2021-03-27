{% import 'register.sv' as register with context %}

{%- macro body(node, offset='ADDR_OFFSET', index='') -%}

{%- set offset = offset + "+'h{:x}".format(node.raw_address_offset) -%}
{%- set IDX = signal(node).upper()+'_IDX' -%}

{%- if node.is_array %}
{%- set index = index + "[%2s]"%IDX %}

genvar {{IDX}};
for ({{IDX}} = 0;
     {{IDX}} < {{node.array_dimensions[0]}};
     {{IDX}} = {{IDX}} + 1) begin

{%- set offset = offset + "+{}*{}".format(IDX, node.array_stride) -%}
{%- endif -%}

{%- if isinstance(node, RegNode) %}
    {{register.body(node, offset, index)|indent(width=4*node.is_array)}}
{%- elif isinstance(node, (AddrmapNode, RegfileNode)) %}
    {%- for child in node.children() %}
        {{body(child, offset, index)|indent(width=4*node.is_array,first=True)}}
    {%- endfor -%}
{%- else %}
initial $error("{{type(node).__name__}} unsupported");

{%- endif -%}
{%- if node.is_array %}
end
{%- endif -%}
{%- endmacro %}
