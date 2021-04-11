input  logic                             valid,    //! Active high valid
input  logic                             read,     //! Indicates request is a read
input  logic            [ADDR_WIDTH-1:0] addr,     //! Address (byte aligned, absolute address)
/* verilator lint_off UNUSED */
input  logic            [DATA_WIDTH-1:0] wdata,    //! Write data
input  logic          [DATA_WIDTH/8-1:0] wmask,    //! Write mask
/* verilator lint_on UNUSED */
output logic            [DATA_WIDTH-1:0] rdata     //! Read data