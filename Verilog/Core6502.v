// Synthesizable MOS 6502 on Verilog
// Project Breaks http://breaknes.com
//
//         2012 - 2024
//
// authors:  org      -  top part
//           andkorzh -  bottom part
//
// Pads:
// #NMI : Non-maskable interrupt (active-low, edge triggered)
// #IRQ : Maskable Interrupt (active-low, level triggered)
// #RES : Reset (active-low, level triggered)
// RDY : Halt CPU execution during RDY = 0 
// SO : Set Overflow flag
// R/W : Read/NotWrite
// SYNC : Active during opcode fetch cycle (useless at most 6502 applications)

// Core
module Core6502 (
    // Outputs
    PHI1, PHI2, RW, SYNC, ADDR,
    // Inputs
    Clk, PHI0, _NMI, _IRQ, _RES, RDY, SO,
    // Inout
	 DATA
);

    input  Clk, PHI0, _NMI, _IRQ, _RES, RDY, SO;
    output PHI1, PHI2, RW, SYNC;
    output[15:0] ADDR;
    inout[7:0]   DATA;

	
    wire [7:0]DLR, DOR;
	 
    // Clock Generator
    assign PHI1 = ~PHI0;
    assign PHI2 =  PHI0;
	 
    assign SYNC = T1;
    assign RW = ~RWLatch_Out;
    // External Data Bus Control
    assign DATA[7:0] = ~RW ? DOR[7:0] : 8'hZZ;
    // DL Bus    
    assign DL[7:0] =   DLR[7:0] & {8{PHI1}};
    // Internal wires
    wire  PHI1;
    wire  PHI2;
    wire FETCH, Z_IR, IMPLIED, _TWOCYCLE;
    wire DORES, RESP, BRK6E, B_OUT,_IRQP, _NMIP;
    wire _ready, _ADL_PCL, PC_DB, ACRL2, WR;
    wire BRFW, _BRTAKEN;
    wire _C_OUT, _V_OUT, _N_OUT, _Z_OUT, _D_OUT, _I_OUT;
    wire ACR, AVR;
    wire Z_ADD, SB_ADD, DB_ADD, NDB_ADD, ADL_ADD, SB_AC;
    wire ORS, ANDS, EORS, SUMS, SRS;
    wire ADD_SB06, ADD_SB7, ADD_ADL, AC_SB, AC_DB;
    wire _ACIN, _DAA, _DSA;
    wire P_DB, DB_P, DBZ_Z, DB_N, IR5_C, ACR_C, DB_C, IR5_D, IR5_I, AVR_V, DB_V, ZERO_V, ONE_V;
    wire Y_SB, SB_Y, X_SB, SB_X, S_SB, S_ADL, SB_S, S_S;
    wire Z_ADL0, Z_ADL1, Z_ADL2, ADL_ABL, ADH_ABH, SB_DB, SB_ADH, Z_ADH0, Z_ADH17, DL_ADL, DL_ADH, DL_DB, RD;
    wire STOR, _IPC, PCL_PCL, PCL_ADL, ADL_PCL, PCL_DB, PCH_PCH, PCH_ADH, ADH_PCH, PCH_DB;
    wire T0, _T0, T1, _T1X, _T2, _T3, _T4, _T5, T6, T7;      
    // Internal buses
    wire [128:0] decoder;
    wire [7:0] IR, DL, DB, SB, ADH, ADL, PCH, PCL, FLAG, S_REG, Y_REG, X_REG, ADD, ACC;
    // Top Latches
    wire RESP_Latch1_Out, IRQP_Latch1_Out;
    wire PRDY1_Out, _PRDY, RWLatch_Out;
    //                   Clk  EN    D_OUT             D_IN
    mylatch IRQP_Latch1 (Clk, PHI2, IRQP_Latch1_Out, _IRQ);
    mylatch IRQP_Latch2 (Clk, PHI1, _IRQP, IRQP_Latch1_Out);
    mylatch NMIP_Latch  (Clk, PHI2, _NMIP, _NMI);
    mylatch RESP_Latch1 (Clk, PHI2, RESP_Latch1_Out, _RES);
    mylatch RESP_Latch2 (Clk, PHI1, RESP, ~RESP_Latch1_Out);
    mylatch PRDY1       (Clk, PHI2, PRDY1_Out, ~RDY);
    mylatch PRDY2    	(Clk, PHI1, _PRDY, PRDY1_Out);
    mylatch RWLatch     (Clk, PHI1, RWLatch_Out, WR);
	 
    mylatch DOR_Latch[7:0]   (Clk, PHI1, DOR[7:0], DB[7:0]);
    mylatch DLR_Latch[7:0]   (Clk, PHI2, DLR[7:0], DATA[7:0]);
    mylatch ADDRL_Latch[7:0] (Clk, ADL_ABL & PHI1, ADDR[7:0],  ADL[7:0]);
    mylatch ADDRH_Latch[7:0] (Clk, ADH_ABH & PHI1, ADDR[15:8], ADH[7:0]);
	 		 
    Predecode predecode ( Clk, PHI1, PHI2, IR[7:0], IMPLIED, _TWOCYCLE, Z_IR, FETCH, DATA[7:0] );
	 
    Decoder decode ( decoder[128:0], IR[7:0], _T0, _T1X, _T2, _T3, _T4, _T5, _PRDY );
	 
    InterruptControl interrupts ( Clk, PHI1, PHI2, Z_ADL0, Z_ADL1, Z_ADL2, DORES, BRK6E, B_OUT,
    RESP, _NMIP, _IRQP, _I_OUT, decoder[80], T0, decoder[22], _ready );
			
    RandomLogic random ( Clk, PHI1, PHI2, _ADL_PCL, PC_DB, ADH_ABH, ADL_ABL, Y_SB, X_SB, SB_Y, SB_X, S_SB, S_ADL, SB_S, S_S,
    NDB_ADD, DB_ADD, Z_ADD, SB_ADD, ADL_ADD, ANDS, EORS, ORS, _ACIN, SRS, SUMS, _DAA, ADD_SB7, ADD_SB06, ADD_ADL, _DSA,
    Z_ADH0, SB_DB, SB_AC, SB_ADH, Z_ADH17, AC_SB, AC_DB, 
    ADH_PCH, PCH_PCH, PCH_DB, PCL_DB, PCH_ADH, PCL_PCL, PCL_ADL, ADL_PCL, DL_ADL, DL_ADH, DL_DB,
    P_DB, ACR_C, AVR_V, DBZ_Z, DB_N, DB_P, DB_C, DB_V, IR5_C, IR5_I, IR5_D, ZERO_V, ONE_V,
    STOR, BRK6E, Z_ADL0, SO, BRFW, ACRL2, _C_OUT, _D_OUT, _ready, T0, T1, T6, T7, decoder[128:0] );

    Dispatcher dispatch ( Clk, PHI1, PHI2, _ready, STOR, _IPC, _T0, T0, T1, _T1X, _T2, _T3, _T4, _T5, T6, T7,
    Z_IR, FETCH, WR, ACRL2, RDY,
    DORES, RESP, B_OUT, BRK6E, BRFW, _BRTAKEN, ACR, _ADL_PCL, PC_DB, IMPLIED, _TWOCYCLE, decoder[128:0] );
		  
    Flags flags ( Clk, PHI1, PHI2, _Z_OUT, _N_OUT, _C_OUT, _D_OUT, _I_OUT, _V_OUT,  
    BRK6E, DB_P, DBZ_Z, DB_N, IR5_C, ACR_C, DB_C, IR5_D, IR5_I, AVR_V, DB_V, ZERO_V, ONE_V, 
    ~IR[5], ACR, AVR, B_OUT, DB[7:0], FLAG[7:0] );

    BranchLogic branch ( Clk, PHI1, PHI2, BRFW, _BRTAKEN, decoder[80], DB[7], ~IR[5], 
    decoder[121], decoder[126], _C_OUT, _V_OUT, _N_OUT, _Z_OUT );

    Buses buses ( Z_ADL0, Z_ADL1, Z_ADL2, Z_ADH0, Z_ADH17, SB_DB, PCL_DB, PCH_DB, P_DB, AC_DB, AC_SB,			    
    ADD_ADL, ADD_SB06, ADD_SB7, Y_SB, X_SB, S_SB, SB_ADH, S_ADL, DL_ADL, DL_ADH, DL_DB, PCL_ADL, PCH_ADH,	
    DL[7:0], PCL[7:0], PCH[7:0], FLAG[7:0], ADD[7:0], ACC[7:0], Y_REG[7:0], X_REG[7:0], S_REG[7:0], DB[7:0],
    SB[7:0], ADL[7:0], ADH[7:0]);
	 
    XYSRegs regs ( Clk, PHI2, Y_SB, SB_Y, X_SB, SB_X, S_SB, SB_S, SB[7:0], X_REG[7:0], Y_REG[7:0], S_REG[7:0] );

    ALU alu ( Clk, PHI2, Z_ADD, SB[7:0], SB_ADD, DB[7:0], NDB_ADD, DB_ADD, ADL[7:0], ADL_ADD, _ACIN, ANDS, ORS, EORS, SRS,               
    SUMS, SB_AC, _DAA, _DSA, ACC[7:0], ADD[7:0], ACR, AVR );

    ProgramCounter pc (Clk, PHI2, _IPC, PCL_PCL, ADL_PCL, ADL[7:0], PCH_PCH, ADH_PCH, ADH[7:0], PCL[7:0], PCH[7:0] );

endmodule   // Core6502

// -------------------------------------------------------------------------------------------------------------------------------
// TOP PART
// -------------------------------------------------------------------------------------------------------------------------------

// Predecode
// Controls:
// 0/IR : "Inject" BRK opcode after interrupt (force IR = 0x00), to initiate common "BRK-sequence" service
// #IMPLIED : NOT Implied instruction (has operands)
// #TWOCYCLE : NOT short two-cycle instruction (more than 2 cycles)

module Predecode ( Clk, PHI1, PHI2, IR, IMPLIED, _TWOCYCLE, Z_IR, FETCH, DATA );

    input Clk, PHI1, PHI2, Z_IR, FETCH;
    output [7:0]IR;
    output IMPLIED, _TWOCYCLE;
    input [7:0]DATA;
    wire temp1, temp2;
    wire [7:0]PDout;
    wire [7:0]PD;
    assign PDout[7:0] =  {8{~Z_IR}}  & PD[7:0];
    assign IMPLIED    = ~(  PDout[0] | PDout[2] | ~PDout[3] );
    assign temp1      = ~( ~PDout[0] | PDout[2] | ~PDout[3] | PDout[4] );
    assign temp2      = ~(  PDout[0] | PDout[2] |  PDout[3] | PDout[4] | ~PDout[7] ); 
    assign _TWOCYCLE  = ~( temp1 | temp2 | ( IMPLIED & ( PDout[1] | PDout[4] | PDout[7] )));

    mylatch IR_Latch[7:0] (Clk, FETCH & PHI1, IR[7:0], PDout[7:0]);
    mylatch PD_Latch[7:0] (Clk, PHI2, PD[7:0], DATA[7:0]);	 

endmodule   // Predecode  

// Decoder
module Decoder (
  // Outputs
  decoder_out,
  // Inputs
  IR, _T0, _T1, _T2, _T3, _T4, _T5, nPRDY
);

    input [7:0]IR;
    input _T0, _T1, _T2, _T3, _T4, _T5 ;
    input nPRDY;
    output [128:0]decoder_out;
	 
    wire PUSHP;
    wire IR01;
    assign IR01 = IR[0] | IR[1];
    assign decoder_out[0]   = ~(  IR[5] |  IR[6] | ~IR[2] | ~IR[7] |  IR01  );
    assign decoder_out[1]   = ~(  IR[2] |  IR[3] | ~IR[4] | ~IR[0] |  _T3   );
    assign decoder_out[2]   = ~(  IR[2] | ~IR[3] | ~IR[4] | ~IR[0] |  _T2   );
    assign decoder_out[3]   = ~(  _T0   |  IR[5] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[4]   = ~(  _T0   |  IR[5] |  IR[6] |  IR[2] | ~IR[3] | ~IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[5]   = ~(  _T0   |  IR[5] | ~IR[6] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[6]   = ~( ~IR[2] | ~IR[4] |  _T2   );
    assign decoder_out[7]   = ~(  IR[6] | ~IR[7] | ~IR[1] );
    assign decoder_out[8]   = ~(  IR[2] |  IR[3] |  IR[4] | ~IR[0] |  _T2   );
    assign decoder_out[9]   = ~(  _T0   |  IR[5] |  IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[10]  = ~(  _T0   |  IR[5] | ~IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[11]  = ~(  _T0   | ~IR[5] | ~IR[6] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[12]  = ~(  IR[5] |  IR[6] | ~IR[7] | ~IR[1] );
    assign decoder_out[13]  = ~(  _T0   |  IR[5] |  IR[6] |  IR[2] | ~IR[3] | ~IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[14]  = ~(  _T0   | ~IR[5] |  IR[6] | ~IR[7] | ~IR[1] );
    assign decoder_out[15]  = ~(  _T1   |  IR[5] | ~IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[16]  = ~(  _T1   | ~IR[5] | ~IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[17]  = ~(  _T0   | ~IR[5] |  IR[6] |  IR[2] | ~IR[3] | ~IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[18]  = ~(  _T1   |  IR[5] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[19]  = ~(  _T0   | ~IR[5] |  IR[6] | ~IR[2] | ~IR[7] |  IR01  );
    assign decoder_out[20]  = ~(  _T0   | ~IR[5] |  IR[6] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[21]  = ~(  _T0   | ~IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[22]  = ~(  IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T5   );
    assign decoder_out[23]  = ~(  _T0   |  IR[5] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[24]  = ~( ~IR[5] | ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T4   );
    assign decoder_out[25]  = ~( ~IR[5] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T3   );
    assign decoder_out[26]  = ~(  IR[5] | ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T5   );
    assign decoder_out[27]  = ~( ~IR[5] | ~IR[6] |  IR[7] | ~IR[1] );
    assign decoder_out[28]  = ~(  _T2   );
    assign decoder_out[29]  = ~(  _T0   |  IR[5] | ~IR[6] |  IR[7] | ~IR[0]);
    assign decoder_out[30]  = ~( ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[31]  = ~( ~IR[2] | ~IR[3] |  IR[4] |  _T2   );
    assign decoder_out[32]  = ~(  _T0   |  IR[5] |  IR[6] |  IR[7] | ~IR[0] );
    assign decoder_out[33]  = ~(  IR[3] |  _T2   );
    assign decoder_out[34]  = ~(  _T0   );
    assign decoder_out[35]  = ~(  IR[2] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[36]  = ~(  IR[4] |  IR[7] |  IR01  |  _T3   );
    assign decoder_out[37]  = ~(  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T4   );
    assign decoder_out[38]  = ~(  IR[5] | ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T4   );
    assign decoder_out[39]  = ~(  IR[2] |  IR[3] |  IR[4] | ~IR[0] |  _T3   );
    assign decoder_out[40]  = ~(  IR[2] |  IR[3] | ~IR[4] | ~IR[0] |  _T4   );
    assign decoder_out[41]  = ~(  IR[2] |  IR[3] | ~IR[4] | ~IR[0] |  _T2   );
    assign decoder_out[42]  = ~( ~IR[3] | ~IR[4] |  _T3   );
    assign decoder_out[43]  = ~( ~IR[5] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[44]  = ~( ~IR[5] | ~IR[6] | ~IR[7] | ~IR[1] );
    assign decoder_out[45]  = ~(  IR[2] |  IR[3] |  IR[4] | ~IR[0] |  _T4   );
    assign decoder_out[46]  = ~(  IR[2] |  IR[3] | ~IR[4] | ~IR[0] |  _T3   );
    assign decoder_out[47]  = ~( ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01);
    assign decoder_out[48]  = ~( ~IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[49]  = ~(  _T0   | ~IR[6] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[50]  = ~(  _T0   |  IR[5] | ~IR[6] | ~IR[7] | ~IR[0] );
    assign decoder_out[51]  = ~(  _T0   | ~IR[5] | ~IR[6] | ~IR[7] | ~IR[0] );
    assign decoder_out[52]  = ~(  _T0   | ~IR[5] | ~IR[6] | ~IR[0] );
    assign decoder_out[53]  = ~( ~IR[5] |  IR[6] |  IR[7] | ~IR[1] );
    assign decoder_out[54]  = ~( ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T3   );
    assign decoder_out[55]  = ~(  IR[6] |  IR[7] | ~IR[1]);
    assign decoder_out[56]  = ~( ~IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T5   );
    assign decoder_out[57]  = ~(  IR[2] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[58]  = ~(  _T0   |  IR[5] |  IR[6] |  IR[2] | ~IR[3] | ~IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[59]  = ~(  _T1   |  IR[7] | ~IR[0] );
    assign decoder_out[60]  = ~(  _T1   | ~IR[5] | ~IR[6] | ~IR[0] );
    assign decoder_out[61]  = ~(  _T1   |  IR[2] | ~IR[3] |  IR[4] |  IR[7] | ~IR[1] );
    assign decoder_out[62]  = ~(  _T0   |  IR[5] |  IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[63]  = ~(  _T0   | ~IR[5] | ~IR[6] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[64]  = ~(  _T0   | ~IR[5] |  IR[6] | ~IR[7] | ~IR[0] );
    assign decoder_out[65]  = ~(  _T0   | ~IR[0] );
    assign decoder_out[66]  = ~(  _T0   | ~IR[5] |  IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[67]  = ~(  _T0   |  IR[2] | ~IR[3] |  IR[4] |  IR[7] | ~IR[1] );
    assign decoder_out[68]  = ~(  _T0   | ~IR[5] |  IR[6] |  IR[2] | ~IR[3] |  IR[4] | ~IR[7] | ~IR[1] );
    assign decoder_out[69]  = ~(  _T0   | ~IR[5] |  IR[6] | ~IR[2] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[70]  = ~(  _T0   | ~IR[5] |  IR[6] |  IR[7] | ~IR[0] );
    assign decoder_out[71]  = ~( ~IR[3] | ~IR[4] |  _T4   );
    assign decoder_out[72]  = ~(  IR[2] |  IR[3] | ~IR[4] | ~IR[0] |  _T5   );
    assign decoder_out[73]  = ~(  _T0   |  IR[2] |  IR[3] | ~IR[4] |  IR01  |  nPRDY ); //prdy
    assign decoder_out[74]  = ~(  IR[5] | ~IR[6] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[75]  = ~(  _T0   | ~IR[6] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] | ~IR[1] );
    assign decoder_out[76]  = ~( ~IR[6] |  IR[7] | ~IR[1] );
    assign decoder_out[77]  = ~(  IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[78]  = ~( ~IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T3   );
    assign decoder_out[79]  = ~(  IR[5] |  IR[6] | ~IR[7] | ~IR[0] );
    assign decoder_out[80]  = ~(  IR[2] |  IR[3] | ~IR[4] |  IR01  |  _T2   );
    assign decoder_out[81]  = ~( ~IR[2] |  IR[3] |  _T2   );
    assign decoder_out[82]  = ~(  IR[2] |  IR[3] | ~IR[0] |  _T2   );
    assign decoder_out[83]  = ~( ~IR[3] |  _T2   |  PUSHP );  
    assign decoder_out[84]  = ~( ~IR[5] | ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T5   );
    assign decoder_out[85]  = ~(  _T4   );
    assign decoder_out[86]  = ~(  _T3   );
    assign decoder_out[87]  = ~(  _T0   |  IR[5] |  IR[2] | IR[3]  |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[88]  = ~(  _T0   | ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[89]  = ~(  IR[2] |  IR[3] |  IR[4] | ~IR[0] |  _T5   );
    assign decoder_out[90]  = ~( ~IR[3] |  _T3   |  PUSHP ); 
    assign decoder_out[91]  = ~(  IR[2] |  IR[3] | ~IR[4] | ~IR[0] |  _T4   );
    assign decoder_out[92]  = ~( ~IR[3] | ~IR[4] |  _T3   );
    assign decoder_out[93]  = ~(  IR[2] |  IR[3] | ~IR[4] |  IR01  |  _T3   );
    assign decoder_out[94]  = ~(  IR[5] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[95]  = ~( ~IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[96]  = ~( ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[97]  = ~(  IR[5] |  IR[6] | ~IR[7] );
    assign decoder_out[98]  = ~(  IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T4   );
    assign decoder_out[99]  = ~(  IR[5] |  IR[6] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[100] = ~(  IR[5] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[101] = ~( ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T4   );
    assign decoder_out[102] = ~( ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T5   );
    assign decoder_out[103] = ~( ~IR[5] |  IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T5   );
    assign decoder_out[104] = ~(  IR[5] | ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T2   );
    assign decoder_out[105] = ~( ~IR[5] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  |  _T3   );
    assign decoder_out[106] = ~( ~IR[6] | ~IR[1] );
    assign decoder_out[107] = ~(  IR[6] |  IR[7] | ~IR[1] );
    assign decoder_out[108] = ~(  _T0   | ~IR[6] |  IR[2] | ~IR[3] | ~IR[4] |  IR[7] |  IR01  );
    assign decoder_out[109] = ~(  _T1   | ~IR[5] |  IR[6] | ~IR[2] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[110] = ~(  _T0   |  IR[6] |  IR[2] | ~IR[3] | ~IR[4] |  IR[7] |  IR01  );
    assign decoder_out[111] = ~( ~IR[2] |  IR[3] | ~IR[4] |  _T3   );
    assign decoder_out[112] = ~(  _T1   | ~IR[5] | ~IR[6] | ~IR[0] );
    assign decoder_out[113] = ~(  _T0   | ~IR[5] |  IR[6] | ~IR[2] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[114] = ~(  _T0   | ~IR[5] |  IR[6] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );
    assign decoder_out[115] = ~(  IR[5] | ~IR[6] |  IR[2] |  IR[3] |  IR[4] |  IR[7] |  IR01  |  _T4   );
    assign decoder_out[116] = ~(  _T1   |  IR[5] | ~IR[6] | ~IR[7] | ~IR[0] );
    assign decoder_out[117] = ~(  _T1   | ~IR[6] | ~IR[2] | ~IR[3] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[118] = ~(  _T1   |  IR[6] |  IR[2] | ~IR[3] |  IR[4] |  IR[7] | ~IR[1] );
    assign decoder_out[119] = ~(  _T1   | ~IR[6] |  IR[3] |  IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[120] = ~(  _T0   | ~IR[6] |  IR[2] | ~IR[3] | ~IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[121] = ~(  IR[6] );
    assign decoder_out[122] = ~( ~IR[2] | ~IR[3] |  IR[4] |  _T3   );
    assign decoder_out[123] = ~( ~IR[2] |  IR[3] |  IR[4] |  _T2   );
    assign decoder_out[124] = ~(  IR[2] |  IR[3] | ~IR[0] |  _T5   );
    assign decoder_out[125] = ~( ~IR[3] | ~IR[4] |  _T4   );
    assign decoder_out[126] = ~(  IR[7] );
    assign decoder_out[127] = ~( ~IR[5] |  IR[6] |  IR[2] | ~IR[3] | ~IR[4] | ~IR[7] |  IR01  );
    assign decoder_out[128] = ~(  IR[0] |  IR[2] | ~IR[3] |  PUSHP );                                         // Line 128 (IMPL) 
    assign PUSHP            = ~(  IR[2] | ~IR[3] |  IR[4] |  IR[7] |  IR01  );                                // Line 129 (Push/Pull)

endmodule 

//------------------
// Interrupt Control

// This stuff looks complicated, because of old-school style #NMI edge-detection
// (edge detection is based on cross-coupled RS flip/flops)

module InterruptControl ( Clk, PHI1, PHI2, Z_ADL0, Z_ADL1, Z_ADL2, DORES, BRK6E, B_OUT,
                          RESP, _NMIP, _IRQP, _I_OUT, BR2, T0, BRK5, _ready );

    input Clk, PHI1, PHI2, RESP, _NMIP, _IRQP, RESP, _I_OUT, BR2, T0, BRK5, _ready;
    output Z_ADL0, Z_ADL1, Z_ADL2, DORES, BRK6E, B_OUT;

    // Interrupt cycle 6-7
    wire BRK5_Latch_Out, BRK6_Latch1_Out, BRK6_Latch2_Out;
    mylatch BRK5_Latch  (Clk, PHI2, BRK5_Latch_Out, BRK5 & ~_ready);
    mylatch BRK6_Latch1 (Clk, PHI1, BRK6_Latch1_Out, ~( BRK5_Latch_Out | ( _ready & ~BRK6_Latch1_Out )));
    mylatch BRK6_Latch2 (Clk, PHI2, BRK6_Latch2_Out, ~BRK6_Latch1_Out);
	 
    assign BRK6E = ~( ~BRK6_Latch2_Out | _ready );
    wire BRK7;  
    assign BRK7  = ~(( BRK5 & ~_ready ) | ~BRK6_Latch1_Out );

    // Reset FLIP/FLOP
    wire RES_Latch1_Out, RES_Latch2_Out;
    mylatch RES_Latch1 (Clk, PHI2, RES_Latch1_Out, RESP);
    mylatch RES_Latch2 (Clk, PHI1, RES_Latch2_Out, ~( BRK6E | ~( RES_Latch1_Out | RES_Latch2_Out )));  
    assign DORES = RES_Latch1_Out | RES_Latch2_Out;     // DO Reset

    // NMI Edge Detection
    wire _DONMI;  
    assign _DONMI = ~( DONMI_Latch_Out | ~( BRK6E_Latch_Out | FF1_Latch_Out ));  
    wire temp;
    assign temp = ~( NMIP_Latch_Out  | ~( DELAY_Latch_Out | FF2_Latch_Out ));    // ff2_latch input
	 
    wire NMIP_Latch_Out, FF1_Latch_Out, FF2_Latch_Out, DELAY_Latch_Out;
    wire BRK6E_Latch_Out, BRK7_Latch_Out, DONMI_Latch_Out;
    mylatch NMIP_Latch  (Clk, PHI1, NMIP_Latch_Out, _NMIP);
    mylatch FF1_Latch   (Clk, PHI2, FF1_Latch_Out, _DONMI);
    mylatch FF2_Latch   (Clk, PHI2, FF2_Latch_Out,   temp);
    mylatch DELAY_Latch (Clk, PHI1, DELAY_Latch_Out, ~FF1_Latch_Out);
    mylatch BRK6E_Latch (Clk, PHI1, BRK6E_Latch_Out, BRK6E);
    mylatch BRK7_Latch  (Clk, PHI2, BRK7_Latch_Out, BRK7);
    mylatch DONMI_Latch (Clk, PHI1, DONMI_Latch_Out, ~( ~BRK7_Latch_Out | _NMIP | temp ));
	 
    // Interrupt Check
    wire IntCheck;      // internal
    assign IntCheck = ( BR2 | T0 ) & ~( _DONMI & ( ~_I_OUT | _IRQP ));

    // B-Flag
    wire BLatch1_Out, BLatch2_Out;
    mylatch BLatch1 (Clk, PHI1, BLatch1_Out, ~( BRK6E    | BLatch2_Out));
    mylatch BLatch2 (Clk, PHI2, BLatch2_Out, ~( IntCheck | BLatch1_Out));
    assign B_OUT = ~( ~( BRK6E | BLatch2_Out ) | DORES );        

    // Interrupt Vector address lines controls.
    // 0xFFFA   NMI         (ADL[2:0] = 3'b010)
    // 0xFFFC   RESET       (ADL[2:0] = 3'b100)
    // 0xFFFE   IRQ         (ADL[2:0] = 3'b110)
	 
    wire ADL0_Latch_Out, ADL1_Latch_Out, ADL2_Latch_Out;
    mylatch ADL0_Latch (Clk, PHI2, ADL0_Latch_Out, ~( BRK5 & ~_ready ));
    mylatch ADL1_Latch (Clk, PHI2, ADL1_Latch_Out,  ( BRK7 | ~DORES  ));
    mylatch ADL2_Latch (Clk, PHI2, ADL2_Latch_Out, ~( BRK7 |  DORES  | _DONMI ));  
    assign Z_ADL0 = ~ADL0_Latch_Out;
    assign Z_ADL1 = ~ADL1_Latch_Out;
    assign Z_ADL2 =  ADL2_Latch_Out;     

endmodule   // InterruptControl
// ------------------
// Random Logic

module RandomLogic ( Clk, PHI1, PHI2, _ADL_PCL, PC_DB, 
    ADH_ABH, ADL_ABL, Y_SB, X_SB, SB_Y, SB_X, S_SB, S_ADL, SB_S, S_S, 
    NDB_ADD, DB_ADD, Z_ADD, SB_ADD, ADL_ADD, ANDS, EORS, ORS, _ACIN, SRS, SUMS, _DAA, ADD_SB7, ADD_SB06, ADD_ADL, _DSA,
    Z_ADH0, SB_DB, SB_AC, SB_ADH, Z_ADH17, AC_SB, AC_DB, 
    ADH_PCH, PCH_PCH, PCH_DB, PCL_DB, PCH_ADH, PCL_PCL, PCL_ADL, ADL_PCL, DL_ADL, DL_ADH, DL_DB,
    P_DB, ACR_C, AVR_V, DBZ_Z, DB_N, DB_P, DB_C, DB_V, IR5_C, IR5_I, IR5_D, ZERO_V, ONE_V,
    STOR, BRK6E, Z_ADL0, SO, BRFW, ACRL2, _C_OUT, _D_OUT, _ready, T0, T1, T6, T7, decoder );
	  
    output _ADL_PCL, PC_DB, ADH_ABH, ADL_ABL, Y_SB, X_SB, SB_Y, SB_X, S_SB, S_ADL, SB_S, S_S;
    output NDB_ADD, DB_ADD, Z_ADD, SB_ADD, ADL_ADD, ANDS, EORS, ORS, _ACIN, SRS, SUMS, _DAA, ADD_SB7, ADD_SB06, ADD_ADL, _DSA;
    output Z_ADH0, SB_DB, SB_AC, SB_ADH, Z_ADH17, AC_SB, AC_DB;
    output ADH_PCH, PCH_PCH, PCH_DB, PCL_DB, PCH_ADH, PCL_PCL, PCL_ADL, ADL_PCL, DL_ADL, DL_ADH, DL_DB;
    output P_DB, ACR_C, AVR_V, DBZ_Z, DB_N, DB_P, DB_C, DB_V, IR5_C, IR5_I, IR5_D, ZERO_V, ONE_V;

    input Clk, PHI1, PHI2, STOR, BRK6E, Z_ADL0, SO, BRFW, ACRL2, _C_OUT, _D_OUT, _ready, T0, T1, T6, T7;
    input [128:0] decoder;

    wire T2;
    wire NotReadyPhi1;
    wire BR0, BR2, BR3, PGX, JSR_5, RTS_5, RTI_5, PushPull, IND, IMPL, _MemOP, JB, STKOP, STOR, STXY, _SBXY, STK2, TXS, JSR2, SBC0;
    wire ROR, SR, AND, EOR, OR, NOADL, BRX, RET, INC_SB, CSET, STA, JSXY, _ZTST, ABS_2, JMP_4;
    mylatch NotReadyPhi1_Latch (Clk, PHI1, NotReadyPhi1, _ready);
    assign T2    = decoder[28];
    assign BR0   = decoder[73]; 
    assign BR2   = decoder[80];
    assign BR3   = decoder[93];
    assign JSR_5 = decoder[56];
    assign RTS_5 = decoder[84];
    assign RTI_5 = decoder[26];
    assign STK2  = decoder[35];
    assign JSR2  = decoder[48];
    assign SBC0  = decoder[51];
    assign ROR   = decoder[27];
    assign RET   = decoder[47];
    assign STA   = decoder[79];
    assign JMP_4 = decoder[101];
    assign ABS_2 = decoder[83];
    assign IMPL  = decoder[128];
    assign PGX = ~( ~( decoder[71] | decoder[72] ) & ~BR0 );
    assign IND = decoder[89] | decoder[90] | decoder[91] | decoder[84];
    assign JB = ~( decoder[94] | decoder[95] | decoder[96] );
    assign BRX = decoder[49] | decoder[50] | ~( ~BR3 | BRFW );
    assign INC_SB =  decoder[39] | decoder[40] | decoder[41] | decoder[42] | decoder[43] | ( decoder[44] & T6 );
    assign CSET = ~( ~( ~( ~( T0 | T6 ) | _C_OUT ) & ( decoder[52] | decoder[53] )) & ~decoder[54]);
    assign JSXY = ~( ~JSR2 & STXY );
    assign _ZTST = ~( ~_SB_AC | _SBXY | T7 | AND );

    // XYS Regs Control
    wire YSB_Out, XSB_Out, _SB_X, _SB_Y, SBY_Out, SBX_Out, SSB_Out, SADL_Out, _SB_S, SBS_Out, SS_Out;
    mylatch YSB (Clk, PHI2, YSB_Out, 
    ~(( STOR & decoder[0]  ) | decoder[1] | decoder[2] | decoder[3]  | decoder[4]  | decoder[5]  | ( decoder[6] &  decoder[7] )));	  
    mylatch XSB (Clk, PHI2, XSB_Out,
    ~(( STOR & decoder[12] ) | decoder[8] | decoder[9] | decoder[10] | decoder[11] | decoder[13] | ( decoder[6] & ~decoder[7] )));    
    assign Y_SB = ~(YSB_Out | PHI2);
    assign X_SB = ~(XSB_Out | PHI2);
    assign _SB_X = ~( decoder[14] | decoder[15] | decoder[16] );
    assign _SB_Y = ~( decoder[18] | decoder[19] | decoder[20] );
    mylatch SBY (Clk, PHI2, SBY_Out, _SB_Y);
    assign SB_Y = ~(SBY_Out | PHI2);
    mylatch SBX (Clk, PHI2, SBX_Out, _SB_X);
    assign SB_X = ~(SBX_Out | PHI2);
    mylatch SSB (Clk, PHI2, SSB_Out, ~decoder[17]);
    assign S_SB = ~SSB_Out; 
    mylatch SADL (Clk, PHI2, SADL_Out, ~(( decoder[21] & ~NotReadyPhi1 ) | STK2 ));
    assign S_ADL = ~SADL_Out;
    assign _SB_S = ~( STKOP | ~( ~JSR2 | _ready ) | decoder[13] );
    mylatch SBS (Clk, PHI2, SBS_Out, _SB_S);
    assign SB_S = ~(SBS_Out | PHI2);
    mylatch SS  (Clk, PHI2, SS_Out, ~_SB_S);
    assign S_S = ~(SS_Out | PHI2);
    assign STKOP = ~( NotReadyPhi1 | ~( decoder[21] | decoder[22] | decoder[23] | decoder[24] | decoder[25] | RTI_5 ));
    assign _SBXY = ~(_SB_X & _SB_Y);
    assign  STXY = ~(( STOR & decoder[0] ) | ( STOR & decoder[12] ));

    // ALU Control ---------------------------------------------------------------------------------------------------------
    // ALU INPUTS Control
    wire _NDB_ADD, _ADL_ADD, SB_ADD_Int, NDBADD_Out, DBADD_Out, ZADD_Out, SBADD_Out, ADLADD_Out;
    assign _NDB_ADD = ~(( BRX | SBC0 | JSR_5 ) & ~_ready );
    assign _ADL_ADD = ~(( decoder[33] & ~decoder[34] ) | decoder[35] | decoder[36] | decoder[37] | decoder[38] | decoder[39] | _ready );
    assign SB_ADD_Int = ~( decoder[30] | decoder[31] | RET | _ready | STKOP | INC_SB | decoder[45] | BRK6E | JSR2 );
    mylatch NDBADD (Clk, PHI2, NDBADD_Out, _NDB_ADD);
    assign NDB_ADD = ~(NDBADD_Out | PHI2);
    mylatch DBADD  (Clk, PHI2, DBADD_Out, ~(_NDB_ADD & _ADL_ADD));
    assign DB_ADD = ~(DBADD_Out | PHI2);
    mylatch ZADD   (Clk, PHI2, ZADD_Out, SB_ADD_Int);
    assign Z_ADD = ~(ZADD_Out | PHI2);
    mylatch SBADD  (Clk, PHI2, SBADD_Out, ~SB_ADD_Int);
    assign SB_ADD = ~(SBADD_Out | PHI2);
    mylatch ADLADD (Clk, PHI2, ADLADD_Out, _ADL_ADD);
    assign ADL_ADD = ~(ADLADD_Out | PHI2);
    assign NOADL = ~( decoder[85] | decoder[86] | RTS_5 | RTI_5 | decoder[87] | decoder[88] | decoder[89] );
    wire ADDADL_Out;
    mylatch ADDADL (Clk, PHI2, ADDADL_Out, PGX | NOADL);
    assign ADD_ADL = ~ADDADL_Out;
    // ALU mode outputs
    assign SR  = ( decoder[76] & T6 ) | decoder[75];
    assign AND = decoder[69] | decoder[70];
    assign EOR = decoder[29];
    assign OR  = _ready | decoder[32];
    wire ANDS1_Out, EORS1_Out, ORS1_Out, SRS1_Out, SUMS1_Out;
    mylatch ANDS1 (Clk, PHI2, ANDS1_Out, AND);
    mylatch ANDS2 (Clk, PHI1, ANDS, ANDS1_Out);
    mylatch EORS1 (Clk, PHI2, EORS1_Out, EOR);
    mylatch EORS2 (Clk, PHI1, EORS, EORS1_Out);
    mylatch ORS1  (Clk, PHI2, ORS1_Out, OR);
    mylatch ORS2  (Clk, PHI1, ORS, ORS1_Out);
    mylatch SRS1  (Clk, PHI2, SRS1_Out, SR);
    mylatch SRS2  (Clk, PHI1, SRS, SRS1_Out);
    mylatch SUMS1 (Clk, PHI2, SUMS1_Out, ~( AND | EOR | OR | SR ));
    mylatch SUMS2 (Clk, PHI1, SUMS, SUMS1_Out);
    //ADDSB7 -----------------------
    wire _ADD_SB7, _ADD_SB06, ADD_SB06_Out;
    wire FF_Latch_1_Out, FF_Latch_2_Out, MUX_Latch_Out, COUT_Latch_Out;
    mylatch FF_Latch_1 (Clk, PHI1, FF_Latch_1_Out, MUX_Latch_Out ? COUT_Latch_Out : FF_Latch_2_Out);
    mylatch FF_Latch_2 (Clk, PHI2, FF_Latch_2_Out, FF_Latch_1_Out);
    mylatch MUX_Latch  (Clk, PHI2, MUX_Latch_Out, ~( ~SR | NotReadyPhi1 )); 
    mylatch COUT_Latch (Clk, PHI2, COUT_Latch_Out, _C_OUT);
    assign _ADD_SB7  = ~( FF_Latch_1_Out | ~ROR | ~SRS );
    mylatch ADD_SB7Latch (Clk, PHI2, ADD_SB7, ~( _ADD_SB7 | _ADD_SB06 ));
    // -----------------------------
    assign _ADD_SB06 = ~( T7 | STKOP | PGX | T1 | JSR_5 );
    mylatch ADD_SB06Latch (Clk, PHI2, ADD_SB06_Out, _ADD_SB06);
    assign ADD_SB06 = ~ADD_SB06_Out;
    // BCD Control
    wire DSA1_Out, DAA1_Out;
    mylatch DSA1 (Clk, PHI2, DSA1_Out, ~( SBC0 & ~_D_OUT ));
    mylatch DSA2 (Clk, PHI1, _DSA, DSA1_Out);
    mylatch DAA1 (Clk, PHI2, DAA1_Out, SBC0 | ~( decoder[52] & ~_D_OUT ));
    mylatch DAA2 (Clk, PHI1, _DAA, DAA1_Out);
    // ALU Carry input control
    //wire ACIN1_Out, ACIN2_Out, ACIN3_Out, ACIN4_Out;
    //mylatch ACIN1 (Clk, PHI2,  ACIN1_Out, ~( ~RET | _ADL_ADD ));
    //mylatch ACIN2 (Clk, PHI2,  ACIN2_Out, INC_SB);
    //mylatch ACIN3 (Clk, PHI2,  ACIN3_Out, BRX);
    //mylatch ACIN4 (Clk, PHI2,  ACIN4_Out, CSET);
    wire ACIN1;
    mylatch ACIN_IN (Clk, PHI2,  ACIN1, ~( ~( ~RET | _ADL_ADD )| INC_SB | BRX | CSET ));
    mylatch ACIN    (Clk, PHI1, _ACIN, ACIN1 );
	 
    // BUS Control -----------------------------------------------------------------------------------------------------
    // AC Control
    wire _SB_AC, _AC_SB, _AC_DB, SBAC_Out, ACSB_Out, ACDB_Out;
    assign _SB_AC = ~( decoder[58] | decoder[59] | decoder[60] | decoder[61] | decoder[62] | decoder[63] | decoder[64] );
    mylatch SBAC (Clk, PHI2, SBAC_Out, _SB_AC);
    assign SB_AC = ~(SBAC_Out | PHI2);
	 
    assign _AC_SB = ~(( ~decoder[64] & decoder[65] ) | decoder[66] | decoder[67] | decoder[68] | AND );  
    mylatch ACSB (Clk, PHI2, ACSB_Out, _AC_SB);
    assign AC_SB = ~(ACSB_Out | PHI2);
	 
    assign _AC_DB = ~(( STA & STOR ) | decoder[74] );
    mylatch ACDB (Clk, PHI2, ACDB_Out, _AC_DB);
    assign AC_DB = ~(ACDB_Out | PHI2);
	 
    // ADH/ADL Control
    wire _Z_ADH17, _ADL_ABL, ADHABH_Out, ADLABL_Out, ZADH17_Out, SBA, a;
	 
    assign a = ~(~( T2 | _PCH_PCH | JSR_5 | IND ) | _ready );
	 
    assign SBA = ~( _SB_ADH | ~( ~NotReadyPhi1 & ACRL2 ));
    mylatch ADHABH (Clk, PHI2, ADHABH_Out, ~((( a | SBA ) & ~BR3 ) | Z_ADL0 ));   
    assign ADH_ABH = ~ADHABH_Out;
	 
    assign _ADL_ABL = ~(~(( decoder[71] | decoder[72] ) | _ready ) & ~( T6 | T7 ));
    mylatch ADLABL (Clk, PHI2, ADLABL_Out, _ADL_ABL);
    assign ADL_ABL = ~ADLABL_Out;
	 
    assign Z_ADH0 = DL_ADL;
	 
    assign _Z_ADH17 = ~( decoder[57] | ~_DL_ADL );
    mylatch ZADH17 (Clk, PHI2, ZADH17_Out, _Z_ADH17);
    assign Z_ADH17 = ~ZADH17_Out;

    // SB/DB Control
    wire _SB_ADH, _SB_DB, SBADH_Out, SBDB_Out;
	 
    assign _SB_ADH = ~( PGX | BR3 );
    mylatch SBADH (Clk, PHI2, SBADH_Out, _SB_ADH);
    assign SB_ADH = ~SBADH_Out;
	 
    assign _SB_DB = ~( ~( _ZTST | AND ) | decoder[67] | ( decoder[55] & T6 ) | T1 | BR2 | JSXY );
    mylatch SBDB  (Clk, PHI2, SBDB_Out, _SB_DB);
    assign SB_DB = ~SBDB_Out;
	 
    // DL Control
    wire _DL_ADL, DL_PCH, DLADL_Out, DLADH_Out, DLDB_Out, temp_d;
	 
    assign _DL_ADL = ~( decoder[81] | decoder[82] );
    mylatch DLADL (Clk, PHI2, DLADL_Out, _DL_ADL);
    assign DL_ADL = ~DLADL_Out;
	 
    assign DL_PCH = ~( ~T0 | JB );
	 
    mylatch DLADH (Clk, PHI2, DLADH_Out, ~( DL_PCH | IND ));
    assign DL_ADH = ~DLADH_Out;
	 
    assign temp_d = INC_SB | BRK6E | decoder[45] | decoder[46] | RET | JSR2 ;
    mylatch DLDB (Clk, PHI2, DLDB_Out, ~( JMP_4 | T6 | temp_d | ~( ~( ABS_2 | T0 ) | IMPL ) | BR2 ));
    assign DL_DB = ~DLDB_Out;

    //PC Setup ---------------------------------------------------------------------------------------------------------
    wire _ADH_PCH, _PCH_DB, _PCL_DB, ADHPCH_Out, PCHPCH_Out, _PCH_PCH, PCHDB_Out, PCLDB1_Out, 
    PCLDB2_Out, PCLDB_Out, _PCH_ADH, _PCL_ADL, PCHADH_Out, PCLPCL_Out, ADLPCL_Out, PCLADL_Out;
    
    assign _ADH_PCH = ~( RTS_5 | ABS_2 | BR3 | BR2 | T1 | T0 );
    mylatch ADHPCH (Clk, PHI2, ADHPCH_Out, _ADH_PCH);
    assign ADH_PCH = ~(ADHPCH_Out | PHI2);
    
    mylatch PCHPCH (Clk, PHI2, PCHPCH_Out, ~_ADH_PCH);
    assign _PCH_PCH = ~_ADH_PCH;
    assign  PCH_PCH = ~(PCHPCH_Out | PHI2);

    assign _PCH_DB = ~( decoder[77] | decoder[78] );
    mylatch PCHDB (Clk, PHI2, PCHDB_Out, _PCH_DB);
    assign PCH_DB = ~PCHDB_Out;
	 
    mylatch PCLDB1 (Clk, PHI2, PCLDB1_Out, _PCH_DB);
    mylatch PCLDB2 (Clk, PHI1, PCLDB2_Out, ~( PCLDB1_Out | _ready ));
    assign _PCL_DB = ~PCLDB2_Out;
    mylatch PCLDB  (Clk, PHI2, PCLDB_Out, _PCL_DB);
    assign PCL_DB = ~PCLDB_Out;
	 
    assign PC_DB = ~( _PCH_DB & _PCL_DB );
	 
    assign _PCH_ADH = ~( ~( _PCL_ADL | BR0 | DL_PCH ) | BR3 );
    mylatch PCHADH (Clk, PHI2, PCHADH_Out, _PCH_ADH);
    assign PCH_ADH = ~PCHADH_Out;
	 
    mylatch PCLCPL (Clk, PHI2, PCLPCL_Out, ~_ADL_PCL);
    assign PCL_PCL = ~(PCLPCL_Out | PHI2);
	 
    assign _ADL_PCL = ~( ~_PCL_ADL | T0 | RTS_5 | ( BR3 & ~NotReadyPhi1 ));
    mylatch ADLPCL (Clk, PHI2, ADLPCL_Out, _ADL_PCL);
    assign ADL_PCL = ~(ADLPCL_Out | PHI2);
	 
    assign _PCL_ADL = ~( ABS_2 | T1 | BR2 | JSR_5 | ~( ~( JB | NotReadyPhi1 ) | ~T0 ));	 
    mylatch PCLADL (Clk, PHI2, PCLADL_Out, _PCL_ADL);
    assign PCL_ADL = ~PCLADL_Out;
	 
    // Flags Control --------------------------------------------------------------------------------------------------------------------
    wire PDB_Out, ACRC_Out, DBZZ_Out, PIN_Out, BIT1_Out, DBC_Out, BIT_Out, IR5C_Out, IR5I_Out, IR5D_Out;
    wire SODelay1_Out, SODelay2_Out, SODelay3_Out;
    mylatch PDB  (Clk, PHI2, PDB_Out, ~( decoder[98] | decoder[99] ));
    assign P_DB = ~PDB_Out;
    mylatch ACRC (Clk, PHI2, ACRC_Out, ~( decoder[112] | decoder[116] | decoder[117] | decoder[118] | decoder[119] | ( decoder[107] & T7 )));
    assign ACR_C = ~ACRC_Out;
    mylatch AVRV (Clk, PHI2, AVR_V, decoder[112]);
    mylatch DBZZ (Clk, PHI2, DBZZ_Out, ~( ACR_C | decoder[109] | ~_ZTST ));
    assign DBZ_Z = ~DBZZ_Out;
    mylatch PIN  (Clk, PHI2, PIN_Out, ~( decoder[114] | decoder[115] ));
    mylatch BIT1 (Clk, PHI2, BIT1_Out, decoder[109]);
    assign DB_N = ~(( PIN_Out & DBZZ_Out) | BIT1_Out );
    assign DB_P = ~( _ready | PIN_Out );
    mylatch DBC  (Clk, PHI2, DBC_Out, ~( SR | DB_P ));
    assign DB_C = ~DBC_Out;
    mylatch BIT  (Clk, PHI2, BIT_Out, ~decoder[113]);
    assign DB_V = ~( BIT_Out & PIN_Out );
    mylatch IR5C (Clk, PHI2, IR5C_Out, decoder[110]);
    assign IR5_C = IR5C_Out;
    mylatch IR5I (Clk, PHI2, IR5I_Out, decoder[108]);
    assign IR5_I = IR5I_Out;
    mylatch IR5D (Clk, PHI2, IR5D_Out, decoder[120]);
    assign IR5_D = IR5D_Out;
    mylatch ZEROV (Clk, PHI2, ZERO_V, decoder[127]);
    mylatch SODelay1 (Clk, PHI1, SODelay1_Out, ~SO);
    mylatch SODelay2 (Clk, PHI2, SODelay2_Out, ~SODelay1_Out);
    mylatch SODelay3 (Clk, PHI1, SODelay3_Out, ~SODelay2_Out);
    mylatch ONEV     (Clk, PHI2, ONE_V, ~( SODelay3_Out | ~SODelay1_Out ));

endmodule   // RandomLogic

// ------------------
// Flags

module Flags ( Clk, PHI1, PHI2, _Z_OUT, _N_OUT, _C_OUT, _D_OUT, _I_OUT, _V_OUT,
     BRK6E, DB_P, DBZ_Z, DB_N, IR5_C, ACR_C, DB_C, IR5_D, IR5_I, AVR_V, DB_V, ZERO_V, ONE_V, 
    _IR5, ACR, AVR, B_OUT, DB, FLAG );
	 
    input Clk, PHI1, PHI2;
    input BRK6E, DB_P, DBZ_Z, DB_N, IR5_C, ACR_C, DB_C, IR5_D, IR5_I, AVR_V, DB_V, ZERO_V, ONE_V;
    input _IR5, ACR, AVR, B_OUT;

    output _Z_OUT, _N_OUT, _C_OUT, _D_OUT, _I_OUT, _V_OUT;
    output [7:0]FLAG;
    input  [7:0]DB;

    wire DBZ;
    assign DBZ = DB[0] | DB[1] | DB[2] | DB[3] | DB[4] | DB[5] | DB[6] | DB[7];
    assign _Z_OUT = Z_Latch1_Out;
    assign _N_OUT = N_Latch1_Out;
    assign _C_OUT = C_Latch1_Out;
    assign _D_OUT = D_Latch1_Out;
    assign _I_OUT = ~( BRK6E | ~I_Latch1_Out );
    assign _V_OUT = V_Latch1_Out;
	 
    // Z FLAG
    wire Z_Latch1_Out, Z_Latch2_Out;
    wire z;
    assign z = (~DB[1] & DB_P) | (DBZ & DBZ_Z) | ( ~(DBZ_Z | DB_P) & Z_Latch2_Out );                                           
    mylatch Z_Latch1 (Clk, PHI1, Z_Latch1_Out, z);
    mylatch Z_Latch2 (Clk, PHI2, Z_Latch2_Out, Z_Latch1_Out);

    // N FLAG
    wire N_Latch1_Out, N_Latch2_Out;
    wire n;
    assign n = (~DB[7] & DB_N) | (N_Latch2_Out & ~DB_N);                                           
    mylatch N_Latch1 (Clk, PHI1, N_Latch1_Out, n);
    mylatch N_Latch2 (Clk, PHI2, N_Latch2_Out, N_Latch1_Out);

    // C FLAG
    wire C_Latch1_Out, C_Latch2_Out;
    wire c;
    assign c = (_IR5 & IR5_C) | (~ACR & ACR_C) | (~DB[0] & DB_C) | ( ~(IR5_C | ACR_C | DB_C) & C_Latch2_Out );
    mylatch C_Latch1 (Clk, PHI1, C_Latch1_Out, c);
    mylatch C_Latch2 (Clk, PHI2, C_Latch2_Out, C_Latch1_Out);

    // D FLAG
    wire D_Latch1_Out, D_Latch2_Out;
    wire d;
    assign d = (_IR5 & IR5_D) | (~DB[3] & DB_P) | ( ~(IR5_D | DB_P) & D_Latch2_Out );
    mylatch D_Latch1 (Clk, PHI1, D_Latch1_Out, d);
    mylatch D_Latch2 (Clk, PHI2, D_Latch2_Out, D_Latch1_Out); 

    // I FLAG
    wire I_Latch1_Out, I_Latch2_Out;
    wire i;
    assign i = (_IR5 & IR5_I) | (~DB[2] & DB_P) | ( ~(IR5_I | DB_P) & I_Latch2_Out );
    mylatch I_Latch1 (Clk, PHI1, I_Latch1_Out, i);
    mylatch I_Latch2 (Clk, PHI2, I_Latch2_Out, ~( BRK6E | ~I_Latch1_Out ));

    // V FLAG
    wire V_Latch1_Out, V_Latch2_Out;
    wire v;
    assign v = (AVR & AVR_V) | (~DB[6] & DB_V) | ( ~(AVR_V | ONE_V | DB_V) & V_Latch2_Out ) | ZERO_V;
    mylatch V_Latch1 (Clk, PHI1, V_Latch1_Out, v);
    mylatch V_Latch2 (Clk, PHI2, V_Latch2_Out, V_Latch1_Out);
	 
    // FLAG BUS Output
    assign FLAG[7:0] = { ~N_Latch1_Out, ~V_Latch1_Out, 1'b1, B_OUT, ~D_Latch1_Out, ( ~BRK6E & ~I_Latch1_Out ), ~Z_Latch1_Out, ~C_Latch1_Out };

endmodule   // Flags

// ------------------
// Branch Logic

module BranchLogic ( Clk, PHI1, PHI2, BRFW, _BRTAKEN, BR2, DB7, _IR5, _IR6, _IR7, _C_OUT,
                     _V_OUT, _N_OUT, _Z_OUT );

    input Clk, PHI1, PHI2, BR2, DB7, _IR5, _IR6, _IR7, _C_OUT, _V_OUT, _N_OUT, _Z_OUT;
    output BRFW, _BRTAKEN;

    // Branch Forward
    wire BR2Latch_Out, Latch2_Out;
    mylatch BR2Latch (Clk, PHI2, BR2Latch_Out, BR2);
    mylatch Latch1   (Clk, PHI1, BRFW, BR2Latch_Out ? DB7 : Latch2_Out);
    mylatch Latch2   (Clk, PHI2, Latch2_Out, BRFW);

    // Branch Taken
    wire BRmux;
    assign BRmux = ~(
        ~(_C_OUT | ~_IR6 |  _IR7 ) |
        ~(_V_OUT |  _IR6 | ~_IR7 ) |
        ~(_N_OUT | ~_IR6 | ~_IR7 ) |
        ~(_Z_OUT |  _IR6 |  _IR7 ) );
		  
    assign _BRTAKEN = _IR5 ^ BRmux;

endmodule   // BranchLogic

// ------------------
//Dispatcher
module Dispatcher ( Clk, PHI1, PHI2, 
    _ready, STOR, _IPC, _T0, T0, T1, _T1X, _T2, _T3, _T4, _T5, T6, T7, Z_IR, FETCH, WR, ACRL2, RDY,
    DORES, RESP, B_OUT, BRK6E, BRFW, _BRTAKEN, ACR, _ADL_PCL, PC_DB, IMPLIED, _TWOCYCLE, decoder );

    input Clk, PHI1, PHI2, RDY;
    input DORES, RESP, B_OUT, BRK6E, BRFW, _BRTAKEN, ACR, _ADL_PCL, PC_DB, IMPLIED, _TWOCYCLE;
    input [128:0] decoder;

    output _ready, STOR, _IPC, _T0, T0, T1, _T1X, _T2, _T3, _T4, _T5, T6, T7, Z_IR, FETCH, WR, ACRL2;
    // Misc
    wire BR2, BR3, _MemOP, STOR, _SHIFT;
    assign BR2 = decoder[80];
    assign BR3 = decoder[93];
    assign _MemOP = ~( decoder[111] | decoder[122] | decoder[123] | decoder[124] | decoder[125] );
    assign  STOR  = ~( ~decoder[97] | _MemOP );
    assign _SHIFT = ~( decoder[106] | decoder[107] );

    // Ready Control
    wire Ready_Latch1_Out, Ready_Latch2_Out;
    mylatch Ready_Latch1 (Clk, PHI2, _ready, ~( RDY | Ready_Latch2_Out ));
    mylatch Ready_Latch2 (Clk, PHI1, Ready_Latch2_Out, WR);

    // R/W Control
    wire WR, WRLatch_Out;
    mylatch WRLatch (Clk, PHI2, WRLatch_Out, ~( decoder[98] | decoder[100] | T6 | T7 | STOR | PC_DB ));
    assign WR = ~( _ready | DORES | WRLatch_Out );

    // Short Cycle Counter (T0-T1)
    wire COMP_Latch2_Out, T0Latch_Out, T1Latch_Out, T1XLatch_Out;
    mylatch COMP_Latch2 (Clk, PHI1, COMP_Latch2_Out, _TWOCYCLE);
	 
    assign _T0 =  ~( ~( ~T1Latch_Out | ( COMP_Latch2_Out & ~TRES2 )) | ~( T0Latch_Out | T1XLatch_Out )); 
    assign  T0 = ~_T0;
	 
    mylatch T0Latch  (Clk, PHI2, T0Latch_Out, _T0);
    mylatch T1Latch  (Clk, PHI1, T1Latch_Out,  ~( ENDS | ~( _ready | ~( BRA | STEP_Latch1_Out ))));
    mylatch T1XLatch (Clk, PHI1, T1XLatch_Out, ~( T0Latch_Out | _ready ));
    assign  T1  = ~T1Latch_Out;
    assign _T1X = ~T1XLatch_Out;
	 
    wire STEP_Latch1_Out, STEP_Latch2_Out;
    mylatch STEP_Latch1 (Clk, PHI2, STEP_Latch1_Out, ~( RESP | nReady_Latch_Out | STEP_Latch2_Out ));
    mylatch STEP_Latch2 (Clk, PHI1, STEP_Latch2_Out, ~( BRA | STEP_Latch1_Out ));
	 
    wire nReady_Latch_Out;
    mylatch nReady_Latch (Clk, PHI1, nReady_Latch_Out, ~_ready);

    // Instruction Termination (reset cycle counters)
    wire REST, ENDS, ENDX, TRES2;
    wire ENDS1_Out, ENDS2_Out;
    assign REST = ~( ~decoder[97] & _SHIFT );

    mylatch ENDS1 (Clk, PHI2, ENDS1_Out, _ready ? ~T1 : ~(( _BRTAKEN & BR2 ) | T0 ));
    mylatch ENDS2 (Clk, PHI2, ENDS2_Out, RESP);
    assign ENDS = ~( ENDS1_Out | ENDS2_Out );

    wire temp;
    assign temp =  decoder[100] | decoder[101] | decoder[102] | decoder[103] | decoder[104] | decoder[105];
    assign ENDX = ~( temp | T7 | BR3 | ~( _MemOP | decoder[96] | ~_SHIFT ));

    wire _TRESX, TRESX1_Out, TRESX2_Out; 	 
    mylatch TRESX1 (Clk, PHI2, TRESX1_Out, ~( decoder[91] | decoder[92] ));
    mylatch TRESX2 (Clk, PHI2, TRESX2_Out, ~( RESP | ENDS | ~( _ready | ENDX )));
    assign _TRESX = ~( BRK6E | ~( _ready | ACRL1 | REST | TRESX1_Out ) | ~TRESX2_Out );

    wire TRES2Latch_Out;
    mylatch TRES2Latch (Clk, PHI1, TRES2Latch_Out, _TRESX);
    assign TRES2 = ~TRES2Latch_Out;

    // ACRL Register
    wire ACRL1;
    wire ACRL1Latch_Out;
    assign ACRL1 = ( ACR & ~ReadyDelay ) | ( ACRL2 & ReadyDelay );
    mylatch ACRL1Latch (Clk, PHI1, ACRL1Latch_Out, ACRL1);
    mylatch ACRL2Latch (Clk, PHI2, ACRL2, ACRL1Latch_Out);

    // Program Counter Increment Control
    wire ReadyDelay;
    wire DelayLatch1_Out;
    mylatch DelayLatch1 (Clk, PHI1, DelayLatch1_Out, _ready);
    mylatch DelayLatch2 (Clk, PHI2, ReadyDelay, DelayLatch1_Out);

    wire BR_Latch1_Out, BR_Latch2_Out, BRA, ipc1_out, ipc2_out, ipc3_out;
    mylatch BR_Latch1  (Clk, PHI2, BR_Latch1_Out, ~(( BR2 & _BRTAKEN ) | ~( _ADL_PCL | ( BR2 | BR3 ))));
    mylatch BR_Latch2  (Clk, PHI2, BR_Latch2_Out, ~( ~BR3 | ReadyDelay ));
    mylatch ipc1_latch (Clk, PHI1, ipc1_out, B_OUT);  
    mylatch ipc2_latch (Clk, PHI1, ipc2_out, BRA);
    mylatch ipc3_latch (Clk, PHI1, ipc3_out, ~( BR_Latch1_Out | _ready | IMPLIED ));
    assign _IPC = ipc1_out & ( ipc2_out | ipc3_out );
    assign  BRA =  ( BRFW ^ ~ACR ) & BR_Latch2_Out;

    // Fetch Control
    wire FetchLatch_Out;
    mylatch FetchLatch (Clk, PHI2, FetchLatch_Out, T1);
    assign FETCH = ~( _ready | ~FetchLatch_Out );
    assign Z_IR  = ~( B_OUT & FETCH );
	 
    // Long Cycle Counter (T2-T5) (Shift Register)
    wire LatchIn_T2_Out, LatchOut_T2_Out, LatchIn_T3_Out, LatchOut_T3_Out,
    LatchIn_T4_Out, LatchOut_T4_Out, LatchIn_T5_Out, LatchOut_T5_Out;
	 
    mylatch LatchIn_T2  (Clk, PHI1, LatchIn_T2_Out, _ready ? LatchOut_T2_Out : ~FetchLatch_Out);
    mylatch LatchOut_T2 (Clk, PHI2, LatchOut_T2_Out, _T2);
    assign _T2 = ( LatchIn_T2_Out | TRES2 );

    mylatch LatchIn_T3  (Clk, PHI1, LatchIn_T3_Out, _ready ? LatchOut_T3_Out :  LatchOut_T2_Out);
    mylatch LatchOut_T3 (Clk, PHI2, LatchOut_T3_Out, _T3);
    assign _T3 = ( LatchIn_T3_Out | TRES2 );

    mylatch LatchIn_T4  (Clk, PHI1, LatchIn_T4_Out, _ready ? LatchOut_T4_Out :  LatchOut_T3_Out);
    mylatch LatchOut_T4 (Clk, PHI2, LatchOut_T4_Out, _T4);
    assign _T4 = ( LatchIn_T4_Out | TRES2 );

    mylatch LatchIn_T5  (Clk, PHI1, LatchIn_T5_Out, _ready ? LatchOut_T5_Out :  LatchOut_T4_Out);
    mylatch LatchOut_T5 (Clk, PHI2, LatchOut_T5_Out, _T5);
    assign _T5 = ( LatchIn_T5_Out | TRES2 );

    // Extra Cycle Counter (T6-T7)
    wire T67Latch_Out, T6Latch1_Out, T6Latch2_Out, T7Latch1_Out, T7Latch2_Out;
    mylatch T67Latch (Clk, PHI2, T67Latch_Out, ~( _SHIFT | _MemOP | _ready ));
    mylatch T6Latch1 (Clk, PHI1, T6Latch1_Out, ~(( T6Latch2_Out & _ready ) | T67Latch_Out ));
    mylatch T6Latch2 (Clk, PHI2, T6Latch2_Out, ~T6Latch1_Out);
    mylatch T7Latch1 (Clk, PHI2, T7Latch1_Out, ~( ~T6Latch1_Out & ~_ready));
    mylatch T7Latch2 (Clk, PHI1, T7Latch2_Out, ~T7Latch1_Out);
    assign T6 = ~T6Latch1_Out;
    assign T7 =  T7Latch2_Out;

endmodule   //Dispatcher

// -------------------------------------------------------------------------------------------------------------------------------
// BOTTOM PART
// -------------------------------------------------------------------------------------------------------------------------------

// Buses

module Buses (
   // Inputs
   // Constant generator control	
   input Z_ADL0,            // Clear bit 0 of the ADL bus
   input Z_ADL1,            // Clear bit 1 of the ADL bus
   input Z_ADL2,            // Clear bit 2 of the ADL bus
   input Z_ADH0,            // Clear bit 0 of the ADH bus
   input Z_ADH17,           // Clear bits 1-7 of the ADH bus
   // Bus multiplexer control	
   input SB_DB,		    // Forwarding data between buses DB <-> SB
   input PCL_DB,	    // PCL to  DB  Bus
   input PCH_DB,	    // PCH to  DB  Bus
   input P_DB,		    // Flag data to DB Bus
   input AC_DB,		    // Accumulator to DB Bus
   input AC_SB,		    // Accumulator to SB Bus
   input ADD_ADL,	    // ALU output to ADL bus
   input ADD_SB06,	    // ALU output bits 0-6 per SB bus
   input ADD_SB7,	    // ALU output bit 7 to SB bus
   input Y_SB,              // Y register to SB Bus
   input X_SB,              // X register to SB Bus
   input S_SB,              // S register to SB Bus	
   input SB_ADH,	    // Forwarding data between buses SB <-> ADH	 
   input S_ADL,             // Register S to ADL Bus
   input DL_ADL,            // DL latch value per ADL Bus
   input DL_ADH,            // DL latch value per ADH Bus
   input DL_DB,             // DL latch value per DB Bus	
   input PCL_ADL,	    // PCL to  ADL Bus
   input PCH_ADH,	    // PCH to  ADH Bus
   // Input buses
   input [7:0]DL,	    // Input DатаLatch Bus
   input [7:0]PCL,          // LSB bus PC
   input [7:0]PCH,          // MSB bus PC
   input [7:0]FLAG,         // Flag data bus
   input [7:0]ADD,          // ADD Bus (output ALU)
   input [7:0]ACC,          // ADD Bus (accumulator output)
   input [7:0]Y_REG,        // register Y
   input [7:0]X_REG,        // register X
   input [7:0]S_REG,        // Stack pointer
   // Output section
   output [7:0]DB,	    // DB Bus
   output [7:0]SB,	    // SB Bus
   output [7:0]ADL,	    // ADL Bus
   output [7:0]ADH 	    // ADH Bus		
);

// Intermediate buses
wire [7:0]DBT;  
wire [7:0]SBT;
wire [7:0]SBH;
wire [7:0]ADHT;
// DBT bus multiplexer
assign DBT[7:0]  = ( ~{8{AC_DB}} | ACC[7:0] ) & ( ~{8{P_DB}} | FLAG[7:0] ) & ( ~{8{DL_DB}} | DL[7:0] ) & ( ~{8{PCL_DB}} | PCL[7:0] ) & ( ~{8{PCH_DB}} | PCH[7:0] );
// SBT bus multiplexer
assign SBT[7:0]  = ( ~{8{X_SB}} | X_REG[7:0] ) & ( ~{8{Y_SB}} | Y_REG[7:0] ) & ( ~{8{S_SB}} | S_REG[7:0] ) & ( ~{8{AC_SB}} | ACC[7:0] ) & { ~ADD_SB7 | ADD[7], ~{7{ADD_SB06}} | ADD[6:0]}; 
// ADHT bus multiplexer
assign ADHT[7:0] = ( ~{8{PCH_ADH}} | PCH[7:0] ) & ( ~{8{DL_ADH}} | DL[7:0] ) & { {7{ ~Z_ADH17 }}, ~Z_ADH0 };
// SBH bus multiplexer
assign SBH[7:0]  =  SB_ADH ? ( ADHT[7:0] & SBT[7:0] ) :  SBT[7:0];
// DB bus multiplexer
assign DB[7:0]   =  SB_DB  ? (  DBT[7:0] & SBH[7:0] ) :  DBT[7:0];
// SB bus multiplexer
assign SB[7:0]   =  SB_DB  ? (  DBT[7:0] & SBH[7:0] ) :  SBH[7:0];
// ADH bus multiplexer
assign ADH[7:0]  =  SB_ADH ? ( ADHT[7:0] & SBT[7:0] ) : ADHT[7:0];
// ADL bus multiplexer
assign ADL[7:0]  = ( ~{8{S_ADL}} | S_REG[7:0] ) & ( ~{8{ADD_ADL}} | ADD[7:0] ) & ( ~{8{PCL_ADL}} | PCL[7:0] ) & ( ~{8{DL_ADL}} | DL[7:0] ) & { 5'h1f, ~Z_ADL2, ~Z_ADL1, ~Z_ADL0 };					
// End of module Buses
endmodule   // Buses

// ----------------------------------------------------------------
// XYS Registers
module XYSRegs ( Clk, PHI2, Y_SB, SB_Y, X_SB, SB_X, S_SB, SB_S,
                 SB, X_REG, Y_REG, S_REG );

input Clk, PHI2, Y_SB, SB_Y, X_SB, SB_X, S_SB, SB_S;
input [7:0] SB;
output[7:0] X_REG, Y_REG, S_REG;
	 
wire [7:0]S_REG_1;
	 
mylatch X_REG_Latch[7:0]  (Clk, SB_X, X_REG[7:0],   SB[7:0]);
mylatch Y_REG_Latch[7:0]  (Clk, SB_Y, Y_REG[7:0],   SB[7:0]);
mylatch S_REG1_Latch[7:0] (Clk, SB_S, S_REG_1[7:0], SB[7:0]);
mylatch S_REG_Latch[7:0]  (Clk, PHI2, S_REG[7:0],   S_REG_1[7:0]);	 
						 
endmodule   // XYSRegs

// -----------------------------------------------------------------
// ALU
module ALU (
   // Clocks
   input Clk,               // Clock
   input PHI2,              // phase PHI2
   // Inputs
   input Z_ADD,             // Reset input A of ALU
   input [7:0]SB,           // SB bus
   input SB_ADD,            // SB bus to ALU input
   input [7:0]DB,           // DB bus
   input NDB_ADD,           // ~DB Bus to ALU input
   input DB_ADD,            //  DB Bus to ALU input
   input [7:0]ADL,          // ADL bus
   input ADL_ADD,           // ADL bus to ALU input
   input _ACIN,             // ALU input carry
   input ANDS,              // Logical AND result 
   input ORS,               // Logical OR result
   input EORS,              // Logical XOR result 
   input SRS,               // Right shift result
   input SUMS,              // the result of the sum A+B
   input SB_AC,             // SB Bus to accumulator
   input _DAA,              // Perform correction after addition 
   input _DSA,              // Perform correction after subtraction
   // Outputs
   output [7:0]ACC,         // accumulator output
   output [7:0]ADD,         // Output of the result of operations
   output ACR,              // ALU carry output
   output AVR               // ALU overflow output
);

wire[7:0] AI, BI;                 // AI/BI input latch
wire LATCH_C7;                    // ALU overflow circuit latches
wire LATCH_DC7;                   // ALU overflow circuit latches
wire DAAL, DAAHR, DSAL, DSAHR;    // Decimal correction control latches  
// Combinatorics of logical operations
wire [7:0]ANDo;                   // Logical AND
wire [7:0]ORo;                    // Logical OR
wire [7:0]XORo;                   // Logical XOR
wire [7:0]SUMo;                   // Sum A + B
assign ANDo[7:0] =   AI[7:0] &  BI[7:0];
assign  ORo[7:0] =   AI[7:0] |  BI[7:0]; 
assign XORo[7:0] =   AI[7:0] ^  BI[7:0];
assign SUMo[7:0] = XORo[7:0] ^ CIN[7:0];
wire [7:0]RESULT;                 // ALU result bus
assign RESULT[7:0] = ({8{ANDS}} & ANDo[7:0]) | ({8{ORS}} & ORo [7:0]) | ({8{EORS}} & XORo[7:0]) | ({8{SRS}} & {1'b0 ,ANDo[7:1]}) | ({8{SUMS}} & SUMo[7:0]);
// Combinatorics of ALU overflow
wire [7:0]CIN;	
assign CIN[7:0] = { COUT[6:4], DCOUT3, COUT[2:0], ~_ACIN };  	// assign CIN[7:0] = { COUT[6:0], ~_ACIN };	// { COUT[6:4], DCOUT3, COUT[2:0], ~_ACIN };
wire [7:0]COUT;
assign COUT[7:0] = ( CIN[7:0] & XORo[7:0] ) | ANDo[7:0];
wire DCOUT3;
assign DCOUT3 = COUT[3] | DC3;
assign ACR = LATCH_C7 | LATCH_DC7;	               //	ACR = LATCH_C7 | LATCH_DC7;
//BCD
wire DAAH, DSAH;
assign DAAH =    ACR & DAAHR;
assign DSAH = ~( ACR | DSAHR );
wire b0,b1,b2,b3,b4,b5; // intermediate signals BCD
assign b0 = DAAL | DSAL;
assign b1 = (( DAAL &  ~ADD[1] )           | ( DSAL & ADD[1] ));
assign b2 = (( DAAL & ( ADD[1] | ADD[2] )) | ( DSAL & ~( ADD[1] & ADD[2] )));
assign b3 = DAAH | DSAH;
assign b4 = (( DAAH &  ~ADD[5] )           | ( DSAH & ADD[5] ));
assign b5 = (( DAAH & ( ADD[5] | ADD[6] )) | ( DSAH & ~( ADD[5] & ADD[6] )));
wire [7:0]BCDRES;       // Decimal correction output
assign BCDRES[0] =  SB[0];
assign BCDRES[1] =  SB[1] ^ b0;
assign BCDRES[2] =  SB[2] ^ b1;
assign BCDRES[3] =  SB[3] ^ b2;
assign BCDRES[4] =  SB[4];
assign BCDRES[5] =  SB[5] ^ b3;
assign BCDRES[6] =  SB[6] ^ b4;
assign BCDRES[7] =  SB[7] ^ b5;
// BCD CARRY
wire DC3,DC7; 
wire a,b,c,d,e,f,g; // intermediate signals BCD CARRY
assign a   = ~( ~ORo[0] | ( _ACIN & ~ANDo[0] ));
assign b   = ~( a & ANDo[1] );
assign c   = ~( ANDo[2] | XORo[3] );
assign d   = ~( a | ~( ANDo[2] | ~ORo[2] ) | ANDo[1] | XORo[1] );
assign e   = ~( ANDo[5] & COUT[4] );
assign f   = ~( ANDo[6] | XORo[7] );
assign g   = ~( XORo[5] | XORo[6] | ANDo[5] | COUT[4] );
assign DC3 = ~( _DAA | (( b | ~ORo[2]  ) & ( c | d )) );
assign DC7 = ~( _DAA | (( e | ~XORo[6] ) & ( f | g )) );

mylatch AI_Latch[7:0] (Clk, Z_ADD  | SB_ADD, AI[7:0], Z_ADD ? 8'h00 : SB[7:0]);
mylatch BI_Latch[7:0] (Clk, DB_ADD | NDB_ADD | ADL_ADD, BI[7:0], NDB_ADD ? ~DB[7:0] : ADL_ADD ? ADL[7:0] : DB[7:0]);

mylatch ACC_Latch[7:0] (Clk, SB_AC, ACC[7:0], BCDRES[7:0]);  // <= BCDRES[7:0];
mylatch ADD_Latch[7:0] (Clk, PHI2,  ADD[7:0], RESULT[7:0]);

mylatch C7_Latch  (Clk, PHI2, LATCH_C7,  COUT[7]);
mylatch DC7_Latch (Clk, PHI2, LATCH_DC7, DC7 );
mylatch AVR_Latch (Clk, PHI2, AVR, ( COUT[6] & ORo[7] ) | ( ~COUT[6] & ~ANDo[7] ));
//BCD latches
mylatch DAAL_Latch  (Clk, PHI2, DAAL,  DCOUT3 & ~_DAA);
mylatch DAAHR_Latch (Clk, PHI2, DAAHR, ~_DAA);
mylatch DSAL_Latch  (Clk, PHI2, DSAL,  ~( DCOUT3 | _DSA ));
mylatch DSAHR_Latch (Clk, PHI2, DSAHR, _DSA);

// End of ALU module
endmodule       

// ---------------------------------------------------------
// Program Counter

module ProgramCounter (
   // Clocks
   input Clk,               // Clock
   input PHI2,              // phase PHI2
   // Inputs	
   input _IPC,              // Input counter carry	
   input PCL_PCL,           // PCL counter bit storage mode
   input ADL_PCL,           // Loading data from the ADL bus
   input [7:0]ADL,          // ADL Bus	
   input PCH_PCH,           // PCH counter bit storage mode
   input ADH_PCH,           // Loading data from the ADH bus
   input [7:0]ADH,          // ADH Bus			
   // Outputs
   output [7:0]PCL,         // Output of the LSB 8 bits of PC 
   output [7:0]PCH          // Output of the MSB 8 bits of PC  
);

wire [7:0]ADL_COUT;
assign ADL_COUT[7:0] =  PCLS[7:0] & {ADL_COUT[6:0], _IPC}; 
wire [7:0]ADH_COUT;
assign ADH_COUT[7:0] =  PCHS[7:0] & {ADH_COUT[6:4], PCH_03, ADH_COUT[2:0], PCH_IN};
wire PCH_IN;
assign PCH_IN = PCLS[7] & PCLS[6] & PCLS[5] & PCLS[4] & PCLS[3] & PCLS[2] & PCLS[1] & PCLS[0] & _IPC;
wire PCH_03;
assign PCH_03 = PCHS[3] & PCHS[2] & PCHS[1] & PCHS[0] & PCH_IN;
wire[7:0] PCLS, PCHS;       // PCL/PCH Counter Intermediate Register
//PCL
mylatch PCLS_Latch[7:0] (Clk, PCL_PCL | ADL_PCL, PCLS[7:0], ( { 8 { PCL_PCL }} & PCL[7:0] )|( { 8 { ADL_PCL }} & ADL[7:0] ));
mylatch  PCL_Latch[7:0] (Clk, PHI2, PCL[7:0],  ( PCLS[7:0] ^ { ADL_COUT[6:0], _IPC } ));
//PCH
mylatch PCHS_Latch[7:0] (Clk, PCH_PCH | ADH_PCH, PCHS[7:0], ( { 8 { PCH_PCH }} & PCH[7:0] )|( { 8 { ADH_PCH }} & ADH[7:0] ));
mylatch  PCH_Latch[7:0] (Clk, PHI2, PCH[7:0],  ( PCHS[7:0] ^ { ADH_COUT[6:4], PCH_03, ADH_COUT[2:0], PCH_IN } ));

// End of module Program Counter (PC)
endmodule   // ProgramCounter

// --------------------------------------------------------------------------------

module mylatch( 
   // Clocks 
   Clk, en, 
   // Output	
   dout, 
   // Input 
   din 
);
    input Clk;
    input en; // latch enable 
    input din; 
    output reg dout; 
    
    always @(posedge Clk) begin 
         if (en) dout <= din;   
                          end
endmodule // mylatch
