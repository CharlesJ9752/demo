`include "mycpu.h"
//写回寄存�?
module WB (
    input                                   clk,
    input                                   resetn,
    //与MEM阶段
    output                                  wb_allowin,
    input                                   mem_wb_valid,
    input   [`MEM_WB_BUS_WDTH - 1:0]        mem_wb_bus,
    //与ID阶段
    output  [`WB_ID_BUS_WDTH - 1:0]         wb_id_bus,
    //debug信号
    output  [ 31:0]                         debug_wb_pc,
    output  [  3:0]                         debug_wb_rf_we,
    output  [  4:0]                         debug_wb_rf_wnum,
    output  [ 31:0]                         debug_wb_rf_wdata,
    //csr信号
    output                                  csr_we,
    output  [ 13:0]                         csr_waddr,
    output  [ 31:0]                         csr_wmask,
    output  [ 31:0]                         csr_wdata,
    output                                  wb_exc,
    output  [  5:0]                         wb_ecode,
    output  [  8:0]                         wb_esubcode,
    output  [ 31:0]                         wb_pc,
    output                                  ertn_flush,
    output  [`WB_CSR_BLK_BUS_WDTH - 1:0]    wb_csr_blk_bus,

    output  [31:0]                          wb_badvaddr,
    //new

    output                          badv_is_pc,
    output                          badv_is_mem,

    output                                  refetch_flush,
    output [ 3:0]                           r_index,
    output                                  tlbrd_we,
    input  [ 3:0]                           csr_tlbidx_index,
    output                                  tlbwr_we,
    output                                  tlbfill_we,
    output [ 3:0]                           w_index,
    output                                  we,
    output                                  tlbsrch_we,
    output                                  tlbsrch_hit,
    output [ 3:0]                           tlbsrch_hit_index
);
//信号定义
    //控制信号
    reg                                     wb_valid;
    wire                                    wb_ready_go;
    //bus
    reg     [`MEM_WB_BUS_WDTH - 1:0]        mem_wb_bus_vld;
    wire                                    wb_gr_we;
    wire                                    rf_we;
    wire    [ 31:0]                         wb_pc;
    wire    [ 31:0]                         wb_inst;
    wire    [ 31:0]                         wb_final_result;
    wire    [  4:0]                         rf_waddr;
    wire    [ 31:0]                         rf_wdata;
    wire    [  4:0]                         wb_dest;
    //中断和异常标�?
    wire    [`NUM_TYPES - 1:0]                         mem_exc_type;
    wire    [`NUM_TYPES - 1:0]                         wb_exc_type;
//控制信号的赋�?
    assign wb_ready_go = 1'b1;
    assign wb_allowin = wb_ready_go | ~wb_valid;
    always @(posedge clk ) begin
        if (~resetn) begin
            wb_valid <= 1'b0;
        end
        else if (wb_allowin) begin
            wb_valid <= mem_wb_valid;
        end
    end
//主bus连接
    always @(posedge clk ) begin
        if(~resetn)begin
            mem_wb_bus_vld <= `MEM_WB_BUS_WDTH'b0;
        end
        else if (mem_wb_valid & wb_allowin) begin
            mem_wb_bus_vld <= mem_wb_bus;
        end
    end
    assign  {
        wb_refetch, wb_inst_tlbsrch,
        wb_inst_tlbrd, wb_inst_tlbwr,
        wb_inst_tlbfill, wb_tlbsrch_hit,
        wb_tlbsrch_hit_index,
        //new
        wb_csr_we, wb_csr_waddr, wb_csr_wmask, wb_csr_wdata, wb_inst_ertn, mem_exc_type,
        wb_gr_we, wb_pc, wb_inst, wb_final_result, wb_dest
    } = mem_wb_bus_vld;
//写数�?
    assign  rf_we = wb_valid & wb_gr_we & ~is_ertn_exc; 
    assign  rf_waddr = wb_dest; 
    assign  rf_wdata = wb_final_result;
    assign  wb_id_bus = {
        rf_we, rf_waddr, rf_wdata
    };
//csr
    wire                wb_csr_we;
    wire [13:0]         wb_csr_waddr;
    wire [31:0]         wb_csr_wdata;
    wire [31:0]         wb_csr_wmask;
    wire                wb_inst_ertn;
    assign wb_exc = wb_valid & (|wb_exc_type);
    assign wb_ecode    =    wb_exc_type[`TYPE_INT ]   ? `EXC_ECODE_INT :
                            wb_exc_type[`TYPE_ADEF]   ? `EXC_ECODE_ADE :
                            wb_exc_type[`TYPE_TLBR_F] ? `EXC_ECODE_TLBR :
                            wb_exc_type[`TYPE_PIF ]   ? `EXC_ECODE_PIF :
                            wb_exc_type[`TYPE_PPE_F]  ? `EXC_ECODE_PPE :
                            wb_exc_type[`TYPE_INE ]   ? `EXC_ECODE_INE :
                            wb_exc_type[`TYPE_SYS ]   ? `EXC_ECODE_SYS :
                            wb_exc_type[`TYPE_BRK ]   ? `EXC_ECODE_BRK :
                            wb_exc_type[`TYPE_ALE ]   ? `EXC_ECODE_ALE :
                            wb_exc_type[`TYPE_ADEM]   ? `EXC_ECODE_ADE :
                            wb_exc_type[`TYPE_TLBR_M] ? `EXC_ECODE_TLBR :
                            wb_exc_type[`TYPE_PIL ]   ? `EXC_ECODE_PIL :
                            wb_exc_type[`TYPE_PIS ]   ? `EXC_ECODE_PIS :
                            wb_exc_type[`TYPE_PPE_M]  ? `EXC_ECODE_PPE :
                            wb_exc_type[`TYPE_PME ]  ? `EXC_ECODE_PME : 6'b0;
                            
                            
                            
                            
                            //NEW ADDED!

    assign wb_esubcode = {9{wb_exc_type[`TYPE_ADEF]}} & `EXC_ESUBCODE_ADEF |
                         {9{wb_exc_type[`TYPE_ADEM]}} & `EXC_ESUBCODE_ADEM   ;//NEW ADDED!
    assign ertn_flush = wb_inst_ertn & wb_valid;
    assign wb_csr_blk_bus = {wb_csr_we & wb_valid, ertn_flush, wb_inst_tlbsrch & wb_valid, wb_csr_waddr};
    assign csr_wmask = wb_csr_wmask;
    assign csr_we    = wb_csr_we & wb_valid & ~wb_exc;
    assign csr_waddr  = wb_csr_waddr;
    assign csr_wdata  = wb_csr_wdata;
    assign badv_is_pc = wb_exc_type[`TYPE_ADEF]  | wb_exc_type[`TYPE_TLBR_F] |
                        wb_exc_type[`TYPE_PPE_F] | wb_exc_type[`TYPE_PIF];
    assign badv_is_mem = wb_exc_type[`TYPE_ALE]    | wb_exc_type[`TYPE_ADEM]  |
                         wb_exc_type[`TYPE_TLBR_M] | wb_exc_type[`TYPE_PPE_M] |
                         wb_exc_type[`TYPE_PIL]    | wb_exc_type[`TYPE_PIS]   |
                         wb_exc_type[`TYPE_PME];
//连接debug
    assign  debug_wb_pc = wb_pc;
    assign  debug_wb_rf_we = {4{rf_we}};
    assign  debug_wb_rf_wnum = rf_waddr;
    assign  debug_wb_rf_wdata = rf_wdata;
//中断和异常标�?
    assign  wb_exc_type = mem_exc_type;

assign wb_badvaddr = wb_final_result;
    reg flush_r;
    assign is_ertn_exc = wb_exc | ertn_flush | flush_r;
    always @(posedge clk) begin
        if (~resetn) begin
            flush_r <= 1'b0;
        end else if (wb_exc | ertn_flush) begin
            flush_r <= 1'b1;
        end else if (mem_wb_valid & wb_allowin) begin
            flush_r <= 1'b0;
        end
    end
    wire        wb_refetch;
    wire        wb_inst_tlbsrch;
    wire        wb_inst_tlbrd;
    wire        wb_inst_tlbwr;
    wire        wb_inst_tlbfill;
    wire        wb_tlbsrch_hit;
    wire [ 3:0] wb_tlbsrch_hit_index;
    reg  [ 3:0] random;
    assign      refetch_flush = wb_refetch && wb_valid;
    always @ (posedge clk) begin
        if (~resetn) begin
            random <= 4'b0;
        end else if(random == 4'b1111)
        begin
            random <=4'b0;
        end
        else begin
            random <=random+4'b1;
        end
        
    end
    assign tlbrd_we = wb_inst_tlbrd;
    assign tlbwr_we = wb_inst_tlbwr;
    assign tlbsrch_we = wb_inst_tlbsrch;
    assign tlbsrch_hit = wb_tlbsrch_hit;
    assign tlbsrch_hit_index = wb_tlbsrch_hit_index;
    assign r_index = csr_tlbidx_index;
    assign tlbfill_we = wb_inst_tlbfill;
    assign w_index = tlbwr_we ? csr_tlbidx_index : random;
    assign we = tlbwr_we | tlbfill_we;
endmodule