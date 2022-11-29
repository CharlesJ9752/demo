`include "mycpu.h"
module csr(
    input clk,
    input resetn,

    input         csr_we,
    input  [13:0] csr_waddr,
    input  [31:0] csr_wmask,
    input  [31:0] csr_wdata,

    input  [13:0] csr_raddr,
    output [31:0] csr_rdata,

    input         wb_exc,
    input  [ 5:0] wb_ecode,
    input  [ 8:0] wb_esubcode,
    input  [31:0] wb_pc,

    input         ertn_flush,

    output        has_int,
    output [31:0] exc_entaddr,
    output [31:0] exc_retaddr,

    input  [31:0] wb_badvaddr,

    output reg [ 9:0] csr_asid_asid,
    output reg [18:0] csr_tlbehi_vppn,
    output reg [ 3:0] csr_tlbidx_index,
    input         tlbsrch_we,
    input         tlbsrch_hit,
    input         tlbrd_we,
    input         tlbwr_we,
    input         tlbfill_we,
    input  [ 3:0] tlb_hit_index,
    input         r_tlb_e,
    input  [ 5:0] r_tlb_ps,
    input  [18:0] r_tlb_vppn,
    input  [ 9:0] r_tlb_asid,
    input         r_tlb_g,
    input  [19:0] r_tlb_ppn0,
    input  [ 1:0] r_tlb_plv0,
    input  [ 1:0] r_tlb_mat0,
    input         r_tlb_d0,
    input         r_tlb_v0,
    input  [19:0] r_tlb_ppn1,
    input  [ 1:0] r_tlb_plv1,
    input  [ 1:0] r_tlb_mat1,
    input         r_tlb_d1,
    input         r_tlb_v1,
    output        w_tlb_e,
    output [ 5:0] w_tlb_ps,
    output [18:0] w_tlb_vppn,
    output [ 9:0] w_tlb_asid,
    output        w_tlb_g,
    output [19:0] w_tlb_ppn0,
    output [ 1:0] w_tlb_plv0,
    output [ 1:0] w_tlb_mat0,
    output        w_tlb_d0,
    output        w_tlb_v0,
    output [19:0] w_tlb_ppn1,
    output [ 1:0] w_tlb_plv1,
    output [ 1:0] w_tlb_mat1,
    output        w_tlb_d1,
    output        w_tlb_v1
);
    //CRMD
    reg     [ 1:0]  csr_crmd_plv;
    reg             csr_crmd_ie;
    reg             csr_crmd_da;
    reg             csr_crmd_pg;
    wire    [31:0]  csr_crmd_rdata;
    //CRMD-PLV
    always @(posedge clk) begin
        if (~resetn)
            csr_crmd_plv <= 2'b0;
        else if (wb_exc)
            csr_crmd_plv <= 2'b0;
        else if (ertn_flush)
            csr_crmd_plv <= csr_prmd_pplv;
        else if (csr_we && csr_waddr==`CSR_CRMD)
            csr_crmd_plv <= csr_wmask[`CSR_CRMD_PLV]&csr_wdata[`CSR_CRMD_PLV]| ~csr_wmask[`CSR_CRMD_PLV]&csr_crmd_plv;
    end
    //CRMD-IE
    always @(posedge clk) begin
        if (~resetn)
            csr_crmd_ie <= 1'b0;
        else if (wb_exc)
            csr_crmd_ie <= 1'b0;
        else if (ertn_flush)
            csr_crmd_ie <= csr_prmd_pie;
        else if (csr_we && csr_waddr==`CSR_CRMD)
            csr_crmd_ie <= csr_wmask[`CSR_CRMD_PIE]&csr_wdata[`CSR_CRMD_PIE]| ~csr_wmask[`CSR_CRMD_PIE]&csr_crmd_ie;
    end
    //CRMD-DA
    always @(posedge clk) begin
        if (ertn_flush&&csr_estat_ecode==6'h3f)
            csr_crmd_da <= 1'b0;
        else 
            csr_crmd_da <= 1'b1;
    end
    //CRMD-PG
    always @(posedge clk) begin
        if (ertn_flush&&csr_estat_ecode==6'h3f)
            csr_crmd_pg <= 1'b1;
        else 
            csr_crmd_pg <= 1'b0;
    end
    assign  csr_crmd_rdata = {27'b0, csr_crmd_pg, csr_crmd_da, csr_crmd_ie, csr_crmd_plv};


    //PRMD
    reg     [ 1:0]  csr_prmd_pplv;
    reg             csr_prmd_pie;
    wire    [31:0]  csr_prmd_rdata;
    //PRMD-PPLV,PIE
    always @(posedge clk) begin
        if (wb_exc) begin
            csr_prmd_pplv <= csr_crmd_plv;
            csr_prmd_pie <= csr_crmd_ie;
        end
        else if (csr_we && csr_waddr==`CSR_PRMD) begin
            csr_prmd_pplv <= csr_wmask[`CSR_PRMD_PPLV]&csr_wdata[`CSR_PRMD_PPLV] 
            | ~csr_wmask[`CSR_PRMD_PPLV]&csr_prmd_pplv;
            csr_prmd_pie <= csr_wmask[`CSR_PRMD_PIE]&csr_wdata[`CSR_PRMD_PIE] 
            | ~csr_wmask[`CSR_PRMD_PIE]&csr_prmd_pie;
        end
    end
    assign  csr_prmd_rdata = {29'b0, csr_prmd_pie, csr_prmd_pplv};

    //ECFG
    reg     [12:0]  csr_ecfg_lie;
    wire    [31:0]  csr_ecfg_rdata;
    //ECFG-LIE
    always @(posedge clk) begin
        if (~resetn)
            csr_ecfg_lie <= 13'b0;
        else if (csr_we && csr_waddr==`CSR_ECFG)
            csr_ecfg_lie <= csr_wmask[`CSR_ECFG_LIE]&csr_wdata[`CSR_ECFG_LIE] 
            | ~csr_wmask[`CSR_ECFG_LIE]&csr_ecfg_lie;
    end
    assign  csr_ecfg_rdata = {19'b0, csr_ecfg_lie};

    //ESTAT
    reg     [ 5:0]  csr_estat_ecode;
    reg     [ 8:0]  csr_estat_esubcode;
    reg     [12:0]  csr_estat_is;
    wire    [31:0]  csr_estat_rdata;
    always @(posedge clk) begin
        if (~resetn)
            csr_estat_is[1:0] <= 2'b0;
        else if (csr_we && csr_waddr==`CSR_ESTAT)
            csr_estat_is[1:0] <= csr_wmask[`CSR_ESTAT_IS10]&csr_wdata[`CSR_ESTAT_IS10] 
            | ~csr_wmask[`CSR_ESTAT_IS10]&csr_estat_is[1:0];
        csr_estat_is[9:2] <= 8'b0;//hwint=0
        csr_estat_is[10] <= 1'b0;//eternal 0
        if (csr_tcfg_en & timer_cnt == 32'b0) begin
            csr_estat_is[11] <= 1'b1;
        end
        else if (csr_we && csr_waddr == `CSR_TICLR    &&
                               csr_wmask[`CSR_TICLR_CLR] &&
                               csr_wdata[`CSR_TICLR_CLR]) begin
            csr_estat_is[11] <= 1'b0;//软件通过向CLR�?1来将estatis第十�?位清�?
        end
        csr_estat_is[12] <= 1'b0;//ipiint=0
    end
    always @(posedge clk) begin
        if (wb_exc) begin
            csr_estat_ecode <= wb_ecode;
            csr_estat_esubcode <= wb_esubcode;
        end
    end
    assign  csr_estat_rdata = {
        1'b0, csr_estat_esubcode, csr_estat_ecode, 3'b0, csr_estat_is
    };
    assign has_int = ((csr_estat_is[11:0] & csr_ecfg_lie[11:0]) != 12'b0)
                        && (csr_crmd_ie == 1'b1);
    //ERA
    reg     [31:0]  csr_era_pc;
    wire    [31:0]  csr_era_rdata;
    //ERA-PC
    always @(posedge clk) begin
        if (wb_exc)
            csr_era_pc <= wb_pc;
        else if (csr_we && csr_waddr==`CSR_ERA)
            csr_era_pc <= csr_wmask[`CSR_ERA_PC]&csr_wdata[`CSR_ERA_PC] | ~csr_wmask[`CSR_ERA_PC]&csr_era_pc;
    end
    assign  csr_era_rdata = csr_era_pc;

    //EENTRY
    reg     [25:0]  csr_eentry_va;
    wire    [31:0]  csr_eentry_rdata;
    //EENTRY-VA
    always @(posedge clk) begin
        if (csr_we && csr_waddr==`CSR_EENTRY)
            csr_eentry_va <= csr_wmask[`CSR_EENTRY_VA]&csr_wdata[`CSR_EENTRY_VA] | ~csr_wmask[`CSR_EENTRY_VA]&csr_eentry_va;
    end
    assign  csr_eentry_rdata = {
        csr_eentry_va , 6'b0 
    };

    //SAVE 0~3
    reg     [31:0]  csr_save0_data;
    reg     [31:0]  csr_save1_data;
    reg     [31:0]  csr_save2_data;
    reg     [31:0]  csr_save3_data;
    wire    [31:0]  csr_save0_rdata;
    wire    [31:0]  csr_save1_rdata;
    wire    [31:0]  csr_save2_rdata;
    wire    [31:0]  csr_save3_rdata;
    //SAVE 0~3
    always @(posedge clk) begin
        if (csr_we && csr_waddr==`CSR_SAVE0)
            csr_save0_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wdata[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save0_data;
        if (csr_we && csr_waddr==`CSR_SAVE1)
            csr_save1_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wdata[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save1_data;
        if (csr_we && csr_waddr==`CSR_SAVE2)
            csr_save2_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wdata[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save2_data;
        if (csr_we && csr_waddr==`CSR_SAVE3)
            csr_save3_data <= csr_wmask[`CSR_SAVE_DATA]&csr_wdata[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save3_data;
    end
    assign {
        csr_save0_rdata, csr_save1_rdata, csr_save2_rdata, csr_save3_rdata
    } = {
        csr_save0_data,  csr_save1_data,  csr_save2_data,  csr_save3_data
    };

    //exc addr
    assign exc_entaddr  = csr_eentry_rdata;//new added
    assign exc_retaddr  = csr_era_rdata;


    //TCFG
    reg         csr_tcfg_en;
    reg         csr_tcfg_periodic;
    reg  [29:0] csr_tcfg_initdata;
    wire [31:0] csr_tcfg_rdata;
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tcfg_en <= 1'b0;
        end else if (csr_we && csr_waddr == `CSR_TCFG) begin
            csr_tcfg_en      <= csr_wmask[`CSR_TCFG_EN] & csr_wdata[`CSR_TCFG_EN] |
                               ~csr_wmask[`CSR_TCFG_EN] & csr_tcfg_en;
            csr_tcfg_periodic  <= csr_wmask[`CSR_TCFG_PERIOD] & csr_wdata[`CSR_TCFG_PERIOD] |
                               ~csr_wmask[`CSR_TCFG_PERIOD] & csr_tcfg_periodic;
            csr_tcfg_initdata <= csr_wmask[`CSR_TCFG_INITVAL] & csr_wdata[`CSR_TCFG_INITVAL] |
                               ~csr_wmask[`CSR_TCFG_INITVAL] & csr_tcfg_initdata;
        end
    end
    assign csr_tcfg_rdata = {csr_tcfg_initdata, csr_tcfg_periodic, csr_tcfg_en};

    //TVAL
    wire [31:0] tcfg_next_data;
    wire [31:0] csr_tval_rdata;
    reg  [31:0] timer_cnt;
    assign      tcfg_next_data = csr_wmask & csr_wdata |~csr_wmask & csr_tcfg_rdata;
    always @ (posedge clk) begin
        if (~resetn) begin
            timer_cnt <= 32'hffffffff;
        end 
        else if (csr_we && csr_waddr == `CSR_TCFG && tcfg_next_data[`CSR_TCFG_EN]) begin
            timer_cnt <= {tcfg_next_data[`CSR_TCFG_INITVAL], 2'b0};
        end 
        else if (csr_tcfg_en && timer_cnt != 32'hffffffff) begin
            if (timer_cnt == 32'b0 && csr_tcfg_periodic) begin
                timer_cnt <= {csr_tcfg_initdata, 2'b0};
            end 
            else begin
                timer_cnt <= timer_cnt - 1'b1;
            end
        end
    end
    assign csr_tval_rdata = timer_cnt;
    
    //TICLR
    wire    [31:0] csr_ticlr_rdata;
    assign  csr_ticlr_rdata = 32'b0;

    //TID
    reg     [31:0] csr_tid_tid;
    wire    [31:0] csr_tid_rdata;
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tid_tid <= 32'b0;
        end else if (csr_we && csr_waddr == `CSR_TID) begin
            csr_tid_tid <= csr_wmask[`CSR_TID_TID] & csr_wdata[`CSR_TID_TID]
                        | ~csr_wmask[`CSR_TID_TID] & csr_tid_tid;
        end
    end
    assign  csr_tid_rdata = csr_tid_tid;
    
    //BADV
    reg  [31:0] csr_badv_vaddr;
    wire [31:0] csr_badv_rdata;
    assign wb_exc_addr_err = wb_ecode==`EXC_ECODE_ADE || wb_ecode==`EXC_ECODE_ALE;
    always @(posedge clk) begin
        if (wb_exc && wb_exc_addr_err)
            csr_badv_vaddr <= (wb_ecode==`EXC_ECODE_ADE && 
                               wb_esubcode==`EXC_ESUBCODE_ADEF) ? wb_pc : wb_badvaddr;
    end
    assign csr_badv_rdata = csr_badv_vaddr;
    reg  [ 5:0] csr_tlbidx_ps;
    reg         csr_tlbidx_ne;
    wire [31:0] csr_tlbidx_rdata;
    wire [31:0] csr_tlbehi_rdata;
    reg         csr_tlbelo0_v;
    reg         csr_tlbelo0_d;
    reg  [ 1:0] csr_tlbelo0_plv;
    reg  [ 1:0] csr_tlbelo0_mat;
    reg         csr_tlbelo0_g;
    reg  [23:0] csr_tlbelo0_ppn;
    wire [31:0] csr_tlbelo0_rdata;
    reg         csr_tlbelo1_v;
    reg         csr_tlbelo1_d;
    reg  [ 1:0] csr_tlbelo1_plv;
    reg  [ 1:0] csr_tlbelo1_mat;
    reg         csr_tlbelo1_g;
    reg  [23:0] csr_tlbelo1_ppn;
    wire [31:0] csr_tlbelo1_rdata;
    wire [31:0] csr_asid_rdata;
    reg  [25:0] csr_tlbrentry_pa;
    wire [31:0] csr_tlbrentry_rdata;
    //TLBIDX
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbidx_index <= 4'b0;
        end 
        else if (tlbsrch_we) begin
            csr_tlbidx_index <= tlbsrch_hit ? tlb_hit_index : csr_tlbidx_index;
        end 
        else if (csr_we && csr_waddr == `CSR_TLBIDX) begin
            csr_tlbidx_index <= csr_wmask[`CSR_TLBIDX_INDEX] & csr_wdata[`CSR_TLBIDX_INDEX] | ~csr_wmask[`CSR_TLBIDX_INDEX] & csr_tlbidx_index;
        end
    end
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbidx_ps    <= 6'b0;
        end 
        else if (tlbrd_we) begin
            csr_tlbidx_ps <= r_tlb_e ? r_tlb_ps : 6'b0;
        end 
        else if (csr_we && csr_waddr == `CSR_TLBIDX) begin
            csr_tlbidx_ps <= csr_wmask[`CSR_TLBIDX_PS] & csr_wdata[`CSR_TLBIDX_PS] | ~csr_wmask[`CSR_TLBIDX_PS] & csr_tlbidx_ps;
        end
    end
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbidx_ne    <= 1'b1;
        end 
        else if (tlbrd_we) begin
            csr_tlbidx_ne <= ~r_tlb_e;
        end
        else if (tlbsrch_we) begin
            csr_tlbidx_ne <= ~tlbsrch_hit;
        end 
        else if (csr_we && csr_waddr == `CSR_TLBIDX) begin
            csr_tlbidx_ne <= csr_wmask[`CSR_TLBIDX_NE] & csr_wdata[`CSR_TLBIDX_NE] | ~csr_wmask[`CSR_TLBIDX_NE] & csr_tlbidx_ne;
        end
    end
    assign csr_tlbidx_rdata = {csr_tlbidx_ne, 1'b0, csr_tlbidx_ps, 20'b0, csr_tlbidx_index};

    //ASID
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_asid_asid <= 10'b0;
        end else if (tlbrd_we) begin
            csr_asid_asid <= r_tlb_e ? r_tlb_asid : 10'b0;
        end else if (csr_we && csr_waddr == `CSR_ASID) begin
            csr_asid_asid <= csr_wmask[`CSR_ASID_ASID] & csr_wdata[`CSR_ASID_ASID] | ~csr_wmask[`CSR_ASID_ASID] & csr_asid_asid;
        end
    end
    assign csr_asid_rdata = {8'b0, 8'd10, 6'b0, csr_asid_asid};

    //TLBEHI
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbehi_vppn <= 19'b0;
        end else if (tlbrd_we) begin
            csr_tlbehi_vppn <= r_tlb_e ? r_tlb_vppn : 19'b0;
        end else if (csr_we && csr_waddr == `CSR_TLBEHI) begin
            csr_tlbehi_vppn <= csr_wmask[`CSR_TLBEHI_VPPN] & csr_wdata[`CSR_TLBEHI_VPPN] | ~csr_wmask[`CSR_TLBEHI_VPPN] & csr_tlbehi_vppn;
        end
    end
    assign csr_tlbehi_rdata = {csr_tlbehi_vppn, 13'b0};

    //TLBELO
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbelo0_v   <= 1'b0;
            csr_tlbelo0_d   <= 1'b0;
            csr_tlbelo0_plv <= 2'b0;
            csr_tlbelo0_mat <= 2'b0;
            csr_tlbelo0_g   <= 1'b0;
            csr_tlbelo0_ppn <= 24'b0;
        end else if (tlbrd_we) begin
                csr_tlbelo0_v   <= r_tlb_e ? r_tlb_v0 : 1'b0;
                csr_tlbelo0_d   <= r_tlb_e ? r_tlb_d0 : 1'b0;
                csr_tlbelo0_plv <= r_tlb_e ? r_tlb_plv0 : 2'b0;
                csr_tlbelo0_mat <= r_tlb_e ? r_tlb_mat0 : 2'b0;
                csr_tlbelo0_g   <= r_tlb_e ? r_tlb_g : 1'b0;
                csr_tlbelo0_ppn <= r_tlb_e ? {4'b0, r_tlb_ppn0} : 24'b0;
        end else if (csr_we&&csr_waddr == `CSR_TLBELO0) begin
                csr_tlbelo0_v   <= csr_wmask[`CSR_TLBELO_V]   & csr_wdata[`CSR_TLBELO_V]   | ~csr_wmask[`CSR_TLBELO_V]   & csr_tlbelo0_v;
                csr_tlbelo0_d   <= csr_wmask[`CSR_TLBELO_D]   & csr_wdata[`CSR_TLBELO_D]   | ~csr_wmask[`CSR_TLBELO_D]   & csr_tlbelo0_d;
                csr_tlbelo0_plv <= csr_wmask[`CSR_TLBELO_PLV] & csr_wdata[`CSR_TLBELO_PLV] | ~csr_wmask[`CSR_TLBELO_PLV] & csr_tlbelo0_plv;
                csr_tlbelo0_mat <= csr_wmask[`CSR_TLBELO_MAT] & csr_wdata[`CSR_TLBELO_MAT] | ~csr_wmask[`CSR_TLBELO_MAT] & csr_tlbelo0_mat;
                csr_tlbelo0_g   <= csr_wmask[`CSR_TLBELO_G]   & csr_wdata[`CSR_TLBELO_G]   | ~csr_wmask[`CSR_TLBELO_G]   & csr_tlbelo0_g;
                csr_tlbelo0_ppn <= csr_wmask[`CSR_TLBELO_PPN] & csr_wdata[`CSR_TLBELO_PPN] | ~csr_wmask[`CSR_TLBELO_PPN] & csr_tlbelo0_ppn;
        end
    end
    assign csr_tlbelo0_rdata = {csr_tlbelo0_ppn, 1'b0, csr_tlbelo0_g, csr_tlbelo0_mat, csr_tlbelo0_plv, csr_tlbelo0_d, csr_tlbelo0_v};
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbelo1_v   <= 1'b0;
            csr_tlbelo1_d   <= 1'b0;
            csr_tlbelo1_plv <= 2'b0;
            csr_tlbelo1_mat <= 2'b0;
            csr_tlbelo1_g   <= 1'b0;
            csr_tlbelo1_ppn <= 24'b0;
        end 
        else if (tlbrd_we) begin
                csr_tlbelo1_v   <= r_tlb_e ? r_tlb_v1 : 1'b0;
                csr_tlbelo1_d   <= r_tlb_e ? r_tlb_d1 : 1'b0;
                csr_tlbelo1_plv <= r_tlb_e ? r_tlb_plv1 : 2'b0;
                csr_tlbelo1_mat <= r_tlb_e ? r_tlb_mat1 : 2'b0;
                csr_tlbelo1_g   <= r_tlb_e ? r_tlb_g : 1'b0;
                csr_tlbelo1_ppn <= r_tlb_e ? {4'b0, r_tlb_ppn1} : 24'b0;
        end 
        else if (csr_we&&csr_waddr == `CSR_TLBELO1) begin
                csr_tlbelo1_v   <= csr_wmask[`CSR_TLBELO_V]   & csr_wdata[`CSR_TLBELO_V]   | ~csr_wmask[`CSR_TLBELO_V]   & csr_tlbelo1_v;
                csr_tlbelo1_d   <= csr_wmask[`CSR_TLBELO_D]   & csr_wdata[`CSR_TLBELO_D]   | ~csr_wmask[`CSR_TLBELO_D]   & csr_tlbelo1_d;
                csr_tlbelo1_plv <= csr_wmask[`CSR_TLBELO_PLV] & csr_wdata[`CSR_TLBELO_PLV] | ~csr_wmask[`CSR_TLBELO_PLV] & csr_tlbelo1_plv;
                csr_tlbelo1_mat <= csr_wmask[`CSR_TLBELO_MAT] & csr_wdata[`CSR_TLBELO_MAT] | ~csr_wmask[`CSR_TLBELO_MAT] & csr_tlbelo1_mat;
                csr_tlbelo1_g   <= csr_wmask[`CSR_TLBELO_G]   & csr_wdata[`CSR_TLBELO_G]   | ~csr_wmask[`CSR_TLBELO_G]   & csr_tlbelo1_g;
                csr_tlbelo1_ppn <= csr_wmask[`CSR_TLBELO_PPN] & csr_wdata[`CSR_TLBELO_PPN] | ~csr_wmask[`CSR_TLBELO_PPN] & csr_tlbelo1_ppn;
        end
    end
    assign csr_tlbelo1_rdata = {csr_tlbelo1_ppn, 1'b0, csr_tlbelo1_g, csr_tlbelo1_mat, csr_tlbelo1_plv, csr_tlbelo1_d, csr_tlbelo1_v};

    //TLBENTRY
    always @ (posedge clk) begin
        if (~resetn) begin
            csr_tlbrentry_pa <= 26'b0;
        end else if (csr_we && csr_waddr == `CSR_TLBRENTRY) begin
            csr_tlbrentry_pa <= csr_wmask[`CSR_TLBRENTRY_PA] & csr_wdata[`CSR_TLBRENTRY_PA] | ~csr_wmask[`CSR_TLBRENTRY_PA] & csr_tlbrentry_pa;
        end
    end
    assign csr_tlbrentry_rdata = {csr_tlbrentry_pa, 6'b0};

    assign w_tlb_e    = ~csr_tlbidx_ne;
    assign w_tlb_ps   =  csr_tlbidx_ps;
    assign w_tlb_vppn =  csr_tlbehi_vppn;
    assign w_tlb_asid =  csr_asid_asid;
    assign w_tlb_g    =  csr_tlbelo0_g & csr_tlbelo1_g;
    assign w_tlb_ppn0 = csr_tlbelo0_ppn[19:0];
    assign w_tlb_plv0 = csr_tlbelo0_plv;
    assign w_tlb_mat0 = csr_tlbelo0_mat;
    assign w_tlb_d0   = csr_tlbelo0_d;
    assign w_tlb_v0   = csr_tlbelo0_v;
    assign w_tlb_ppn1 = csr_tlbelo1_ppn[19:0];
    assign w_tlb_plv1 = csr_tlbelo1_plv;
    assign w_tlb_mat1 = csr_tlbelo1_mat;
    assign w_tlb_d1   = csr_tlbelo1_d;
    assign w_tlb_v1   = csr_tlbelo1_v;
    assign csr_rdata =  {32{csr_raddr == `CSR_CRMD  }} & csr_crmd_rdata     |
                        {32{csr_raddr == `CSR_PRMD  }} & csr_prmd_rdata     |
                        {32{csr_raddr == `CSR_ESTAT }} & csr_estat_rdata    |
                        {32{csr_raddr == `CSR_ERA   }} & csr_era_rdata      |
                        {32{csr_raddr == `CSR_EENTRY}} & csr_eentry_rdata   |
                        {32{csr_raddr == `CSR_SAVE0 }} & csr_save0_rdata    |
                        {32{csr_raddr == `CSR_SAVE1 }} & csr_save1_rdata    |
                        {32{csr_raddr == `CSR_SAVE2 }} & csr_save2_rdata    |
                        {32{csr_raddr == `CSR_SAVE3 }} & csr_save3_rdata    |
                        {32{csr_raddr == `CSR_ECFG  }} & csr_ecfg_rdata     |
                        {32{csr_raddr == `CSR_BADV  }} & csr_badv_rdata     |
                        {32{csr_raddr == `CSR_TID   }} & csr_tid_rdata      |
                        {32{csr_raddr == `CSR_TCFG  }} & csr_tcfg_rdata     |
                        {32{csr_raddr == `CSR_TVAL  }} & csr_tval_rdata     |
                        {32{csr_raddr == `CSR_TICLR }} & csr_ticlr_rdata    |
                        {32{csr_raddr == `CSR_TLBIDX}}  & csr_tlbidx_rdata  |   //new added below
                        {32{csr_raddr == `CSR_TLBEHI}}  & csr_tlbehi_rdata  |
                        {32{csr_raddr == `CSR_TLBELO0}} & csr_tlbelo0_rdata |
                        {32{csr_raddr == `CSR_TLBELO1}} & csr_tlbelo1_rdata |
                        {32{csr_raddr == `CSR_ASID  }}  & csr_asid_rdata    |
                        {32{csr_raddr == `CSR_TLBRENTRY}} & csr_tlbrentry_rdata;
endmodule