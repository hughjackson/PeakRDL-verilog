{%- macro backdoor(node) -%}
    {%- if node.is_hw_readable -%}
        {{signal(node, '', 'q')}}
    {%- else -%}
        {{get_inst_name(top_node)}}_rf__DOT__{{signal(node, '', 'q')}}
    {%- endif -%}
{%- endmacro -%}

#include <verilated.h>          // Defines common routines
#include "V{{get_inst_name(top_node)}}_rf.h"               // From Verilating "sig_tbtop.v"
#include "verilated_vcd_c.h"
#include <iostream>

#define STR(x) #x
#define ST(x) STR(x)
#define CHECK_EQUAL(VAL, EXP) \
    if (EXP!=VAL) printf("Error: %s(0x%0x) != %s(0x%0x)\n", ST(VAL), VAL, ST(EXP), EXP); \
    assert(EXP==VAL);

#define RANGE(NAME, WIDTH, SHIFT) (WIDTH==32 ? NAME : ((NAME >> SHIFT) & ((1 << WIDTH)-1)))

#define HW_WRITE(NAME, IDX, VAL) \
            top->NAME##_wdata IDX = VAL; \
            cycle(top);

#define HW_WRITE_WE(NAME, IDX, VAL) \
            top->NAME##_we IDX = 1; \
            HW_WRITE(NAME, IDX, VAL) \
            top->NAME##_we IDX = 0;

#define SW_READ(ADDR) \
            top->valid = 1; \
            top->read = 1; \
            top->addr = ADDR; \
            cycle(top); \
            top->valid = 0;

#define SW_WRITE(ADDR, DATA) \
            top->valid = 1; \
            top->read = 0; \
            top->addr = ADDR; \
            top->wdata = DATA; \
            top->wmask = -1; \
            cycle(top); \
            top->valid = 0;
 
V{{get_inst_name(top_node)}}_rf *top;                      // Instantiation of module

unsigned int main_time = 0;     // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;
}

void cycle(V{{get_inst_name(top_node)}}_rf *top) {
    top->clk = 0;
    top->eval();
    main_time++;
    top->clk = 1;
    top->eval();
    main_time++;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);   // Remember args
    Verilated::traceEverOn(true);

    top = new V{{get_inst_name(top_node)}}_rf;             // Create instance

    top->resetn = 0;           // Set some inputs
    top->clk = 0;
    top->valid = 0;

    cycle(top);
    cycle(top);
    cycle(top);
    top->resetn = 1;
    std::cout << main_time << ": Remove reset\n";
    cycle(top);
    cycle(top);

{%- for node in top_node.descendants(unroll=True) -%}
{%- if isinstance(node, FieldNode) %}
    cycle(top);
    cycle(top);
    std::cout << main_time << ": Testcase ({{signal(node)}} {{full_idx(node.parent)}}):\n";

  {%- if node.is_hw_writable and not node.get_property('next') and not node.get_property('intr') and not node.get_property('sticky') %}
    std::cout << main_time << ": \tHardware write test\n";
    for (int IDX = {{node.lsb}}; IDX <= {{node.msb}}; ++IDX) {

        HW_WRITE_WE( {{signal(node)}}, {{full_idx(node.parent)}}, (1 << (IDX-{{node.lsb}})) )
        //SW_READ( {{node.parent.absolute_address}} )
        //CHECK_EQUAL(RANGE(top->rdata, {{node.width}}, {{node.lsb}}), (1 << (IDX-{{node.lsb}})))
        CHECK_EQUAL(top->{{backdoor(node)}}, (1 << (IDX-{{node.lsb}})))

        HW_WRITE_WE( {{signal(node)}}, {{full_idx(node.parent)}}, 0 )
        CHECK_EQUAL(top->{{backdoor(node)}}, 0)
    }
  {%- endif -%}

  {%- if node.is_sw_writable and not node.get_property('swwe') %}
    std::cout << main_time << ": \tSoftware write test\n";
    for (int IDX = {{node.lsb}}; IDX <= {{node.msb}}; ++IDX) {
        int temp, value;

        temp = top->{{backdoor(node)}} << {{node.lsb}};
        std::cout << main_time << ": " << IDX << ": " << RANGE(temp, {{node.width}}, {{node.lsb}}) << "\n";
    {%- if node.get_property('onwrite') == OnWriteType.woset %}
        temp |= 1<<IDX;
        value = temp;
    {%- elif node.get_property('onwrite') == OnWriteType.woclr %}
        temp &= ~(1<<IDX);
        value = temp;
    {%- elif node.get_property('onwrite') == OnWriteType.wot %}
        temp ^= 1<<IDX;
        value = temp;
    {%- elif node.get_property('onwrite') == OnWriteType.wzs %}
        temp |= ~(1<<IDX);
        value = -1;
    {%- elif node.get_property('onwrite') == OnWriteType.wzc %}
        temp &= (1<<IDX);
        value = 0;
    {%- elif node.get_property('onwrite') == OnWriteType.wzt %}
        temp ^= ~(1<<IDX);
        value = ~temp;
    {%- elif node.get_property('onwrite') == OnWriteType.wclr %}
        temp = 0;
        value = 0;
    {%- elif node.get_property('onwrite') == OnWriteType.wset %}
        temp = -1;
        value = -1;
    {%- else %}
        temp = (1 << IDX);
        value = 0;
    {%- endif %}

        SW_WRITE( {{node.parent.absolute_address}}, (1 << IDX) )
        CHECK_EQUAL(top->{{backdoor(node)}}, RANGE(temp, {{node.width}}, {{node.lsb}}))

        SW_WRITE( {{node.parent.absolute_address}}, 0 )
        CHECK_EQUAL(top->{{backdoor(node)}}, RANGE(value, {{node.width}}, {{node.lsb}}))

    }
  {%- endif -%}

{%- endif -%}
{%- endfor %}

    cycle(top);
    cycle(top);
    std::cout << main_time << ": Test Complete!\n";


    top->final();               // Done simulating
}