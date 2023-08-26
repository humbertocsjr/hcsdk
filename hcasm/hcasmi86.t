use t3x: t;
use string;
use io;
use char;
use hcatks;
use hcltks;

struct ARGS_LIST = ARG_NONE, ARG_VALUE, ARG_REG, ARG_PTR_REG, 
    ARG_PTR_REG_AND_VALUE, ARG_PTR_VALUE;
struct REGS_LIST = REG_NONE, REG_AX, REG_BX, REG_CX, REG_DX, REG_AL, REG_AH, REG_BL, 
    REG_BH, REG_CL, REG_CH, REG_DL, REG_DH, REG_ES, REG_DS, REG_BP, REG_SI, REG_DI, 
    REG_SP, REG_CS;
struct INSTR_LIST = INSTR_GEN, INSTR_CMD, INSTR_ASM, INSTR_ARGS, 
    INSTR_ARGA_TYPE, INSTR_ARGA_REG, 
    INSTR_ARGB_TYPE, INSTR_ARGB_REG, 
    INSTR_ARGC_TYPE, INSTR_ARGC_REG;
struct PARAM_LIST = PARAM_TYPE, PARAM_REG, PARAM_VALUE, PARAM_LABEL;

struct GEN_LIST = GEN_NONE, GEN_SIMPLE, GEN_LD_REG_REG, GEN_LD_MEM_REG, GEN_LD_REG_MEM,
    GEN_SIMPLE_WITH_VALUE_WORD_PARAMA, GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, GEN_LD_REG_VAL,
    GEN_SIMPLE_WITH_VALUE_BYTE_PARAMA, GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB;

var _instrs;

decl gen0(2);
decl gen1(3);
decl gen2(4);
decl gen3(5);

parse_reg(id) do
    ie(\string.comp("AX", id)) return REG_AX;
    else ie(\string.comp("AL", id)) return REG_AL;
    else ie(\string.comp("AH", id)) return REG_AH;
    else ie(\string.comp("BX", id)) return REG_BX;
    else ie(\string.comp("BL", id)) return REG_BL;
    else ie(\string.comp("BH", id)) return REG_BH;
    else ie(\string.comp("CX", id)) return REG_CX;
    else ie(\string.comp("CL", id)) return REG_CL;
    else ie(\string.comp("CH", id)) return REG_CH;
    else ie(\string.comp("DX", id)) return REG_DX;
    else ie(\string.comp("DL", id)) return REG_DL;
    else ie(\string.comp("DH", id)) return REG_DH;
    else ie(\string.comp("SI", id)) return REG_SI;
    else ie(\string.comp("DI", id)) return REG_DI;
    else ie(\string.comp("SP", id)) return REG_SP;
    else ie(\string.comp("BP", id)) return REG_BP;
    else ie(\string.comp("CS", id)) return REG_CS;
    else ie(\string.comp("DS", id)) return REG_DS;
    else ie(\string.comp("ES", id)) return REG_ES;
    else return REG_NONE;
end

use hcasm;

instr_simple_byte(ins) do
    hcasm.emit_asm(ins[INSTR_ASM]);
end

instr_simple_byte_value_byte(ins, parama) do
    hcasm.emit_asm(ins[INSTR_ASM]);
    ie(\parama[PARAM_LABEL]) do
        hcasm.emit_tok(hcasm.segment(), @parama[PARAM_VALUE], 1);
    end else do
        hcasm.emit_tok(hclink.LNK_REF_START,0,0);
        hcasm.emit_tok(hclink.LNK_REF_WORD, @parama[PARAM_VALUE], 1);
        hcasm.emit_tok(hclink.LNK_REF_NAME, parama[PARAM_LABEL], string.length(parama[PARAM_LABEL]));
        hcasm.emit_tok(hclink.LNK_REF_EMIT,0,0);
        if(\string.comp(ins[INSTR_CMD], "CALL")) do
            hcasm.emit_tok(hclink.LNK_FUNC_USE, parama[PARAM_LABEL], string.length(parama[PARAM_LABEL]));
        end
    end
end

instr_simple_byte_value_word(ins, parama) do
    hcasm.emit_asm(ins[INSTR_ASM]);
    ie(\parama[PARAM_LABEL]) do
        hcasm.emit_tok(hcasm.segment(), @parama[PARAM_VALUE], 2);
    end else do
        hcasm.emit_tok(hclink.LNK_REF_START,0,0);
        hcasm.emit_tok(hclink.LNK_REF_WORD, @parama[PARAM_VALUE], 2);
        hcasm.emit_tok(hclink.LNK_REF_NAME, parama[PARAM_LABEL], string.length(parama[PARAM_LABEL]));
        hcasm.emit_tok(hclink.LNK_REF_EMIT,0,0);
        if(\string.comp(ins[INSTR_CMD], "CALL")) do
            hcasm.emit_tok(hclink.LNK_FUNC_USE, parama[PARAM_LABEL], string.length(parama[PARAM_LABEL]));
        end
    end
end


get_ld_reg_byte(reg) do
    var opcode;
    ie(reg = REG_A) do
        opcode := 0x7;
    end else ie(reg = REG_B) do
        opcode := 0x0;
    end else ie(reg = REG_C) do
        opcode := 0x1;
    end else ie(reg = REG_D) do
        opcode := 0x2;
    end else ie(reg = REG_E) do
        opcode := 0x3;
    end else ie(reg = REG_H) do
        opcode := 0x4;
    end else ie(reg = REG_L) do
        opcode := 0x5;
    end else ie(reg = REG_HL) do
        opcode := 0x6;
    end else hcasm.error("REG NOT IMPLEMENTED");
    return opcode;
end

instr_ld_reg_reg(instr, parama, paramb) do
    var opcode;
    ie(parama[PARAM_REG] = REG_A) do
        opcode := 0x78;
    end else ie(parama[PARAM_REG] = REG_B) do
        opcode := 0x40;
    end else ie(parama[PARAM_REG] = REG_C) do
        opcode := 0x48;
    end else ie(parama[PARAM_REG] = REG_D) do
        opcode := 0x50;
    end else ie(parama[PARAM_REG] = REG_E) do
        opcode := 0x58;
    end else ie(parama[PARAM_REG] = REG_H) do
        opcode := 0x60;
    end else ie(parama[PARAM_REG] = REG_L) do
        opcode := 0x68;
    end else hcasm.error("LD REG REG - NOT IMPLEMENTED");
    opcode := opcode | get_ld_reg_byte(paramb[PARAM_REG]);
    hcasm.emit_tok(hclink.LNK_CODE, @opcode, 1);
end

instr_ld_mem_reg(instr, parama, paramb) do
    var opcode;
    ie(parama[PARAM_REG] = REG_HL) do
        opcode := 0x70;
    end else hcasm.error("LD MEM REG - NOT IMPLEMENTED");
    opcode := opcode | get_ld_reg_byte(paramb[PARAM_REG]);
    hcasm.emit_tok(hclink.LNK_CODE, @opcode, 1);
end

instr_ld_reg_mem(instr, parama, paramb) do
    var opcode;
    ie(paramb[PARAM_REG] = REG_HL) do
        opcode := 0x6;
    end else hcasm.error("LD REG MEM - NOT IMPLEMENTED");
    ie(parama[PARAM_REG] = REG_A) do
        opcode := 0x78;
    end else ie(parama[PARAM_REG] = REG_B) do
        opcode := 0x40;
    end else ie(parama[PARAM_REG] = REG_C) do
        opcode := 0x48;
    end else ie(parama[PARAM_REG] = REG_D) do
        opcode := 0x50;
    end else ie(parama[PARAM_REG] = REG_E) do
        opcode := 0x58;
    end else ie(parama[PARAM_REG] = REG_H) do
        opcode := 0x60;
    end else ie(parama[PARAM_REG] = REG_L) do
        opcode := 0x68;
    end else hcasm.error("LD REG MEM - NOT IMPLEMENTED");
    opcode := opcode | get_ld_reg_byte(paramb[PARAM_REG]);
    hcasm.emit_tok(hclink.LNK_CODE, @opcode, 1);
end


instr_ld_reg_val(instr, parama, paramb) do
    var opcode, size;
    size := 1;
    ie(parama[PARAM_REG] = REG_A) do
        opcode := 0x3e;
    end else ie(parama[PARAM_REG] = REG_B) do
        opcode := 0x06;
    end else ie(parama[PARAM_REG] = REG_C) do
        opcode := 0x0e;
    end else ie(parama[PARAM_REG] = REG_D) do
        opcode := 0x16;
    end else ie(parama[PARAM_REG] = REG_E) do
        opcode := 0x1e;
    end else ie(parama[PARAM_REG] = REG_H) do
        opcode := 0x26;
    end else ie(parama[PARAM_REG] = REG_L) do
        opcode := 0x2e;
    end else hcasm.error("LD REG VAL - NOT IMPLEMENTED");
    hcasm.emit_tok(hclink.LNK_CODE, @opcode, 1);
    ie(size = 1) do
        ie(\paramb[PARAM_LABEL]) do
            hcasm.emit_tok(hcasm.segment(), @paramb[PARAM_VALUE], 1);
        end else do
            hcasm.emit_tok(hclink.LNK_REF_START,0,0);
            hcasm.emit_tok(hclink.LNK_REF_BYTE, @paramb[PARAM_VALUE], 1);
            hcasm.emit_tok(hclink.LNK_REF_NAME, paramb[PARAM_LABEL], string.length(paramb[PARAM_LABEL]));
            hcasm.emit_tok(hclink.LNK_REF_EMIT,0,0);
        end
    end else ie(size = 2) do
        ie(\paramb[PARAM_LABEL]) do
            hcasm.emit_tok(hcasm.segment(), @paramb[PARAM_VALUE], 2);
        end else do
            hcasm.emit_tok(hclink.LNK_REF_START,0,0);
            hcasm.emit_tok(hclink.LNK_REF_BYTE, @paramb[PARAM_VALUE], 2);
            hcasm.emit_tok(hclink.LNK_REF_NAME, paramb[PARAM_LABEL], string.length(paramb[PARAM_LABEL]));
            hcasm.emit_tok(hclink.LNK_REF_EMIT,0,0);
        end
    end else hcasm.error("LD REG VAL - NOT IMPLEMENTED");
end

gen0(type, instr) do
    ie(type = GEN_SIMPLE) do
        instr_simple_byte(instr);
    end else hcasm.error("GEN0 NOT IMPLEMENTED");
end

gen1(type, instr, parama) do
    ie(type = GEN_SIMPLE_WITH_VALUE_WORD_PARAMA) do
        instr_simple_byte_value_word(instr, parama);
    end else ie(type = GEN_SIMPLE_WITH_VALUE_BYTE_PARAMA) do
        instr_simple_byte_value_byte(instr, parama);
    end else ie(type = GEN_SIMPLE) do
        instr_simple_byte(instr);
    end else hcasm.error("GEN1 NOT IMPLEMENTED");
end

gen2(type, instr, parama, paramb) do
    ie(type = GEN_LD_MEM_REG) do
        instr_ld_mem_reg(instr, parama, paramb);
    end else ie(type = GEN_LD_REG_REG) do
        instr_ld_reg_reg(instr, parama, paramb);
    end else ie(type = GEN_LD_REG_MEM) do
        instr_ld_reg_mem(instr, parama, paramb);
    end else ie(type = GEN_LD_REG_VAL) do
        instr_ld_reg_val(instr, parama, paramb);
    end else ie(type = GEN_SIMPLE) do
        instr_simple_byte(instr);
    end else ie(type = GEN_SIMPLE_WITH_VALUE_WORD_PARAMA) do
        instr_simple_byte_value_word(instr, parama);
    end else ie(type = GEN_SIMPLE_WITH_VALUE_WORD_PARAMB) do
        instr_simple_byte_value_word(instr, paramb);
    end else ie(type = GEN_SIMPLE_WITH_VALUE_BYTE_PARAMA) do
        instr_simple_byte_value_byte(instr, parama);
    end else ie(type = GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB) do
        instr_simple_byte_value_byte(instr, paramb);
    end else hcasm.error("GEN0 NOT IMPLEMENTED");
end

gen3(type, instr, parama, paramb, paramc) do
    ie(type = GEN_SIMPLE) do
        instr_simple_byte(instr);
    end else hcasm.error("GEN3 NOT IMPLEMENTED");
end


get_instructions() return [
        [GEN_SIMPLE, "NOP", "00", 0],
        [GEN_SIMPLE, "HLT", "76", 0],
        [GEN_SIMPLE, "SCF", "37", 0],
        [GEN_SIMPLE, "CCF", "3f", 0],
        [GEN_SIMPLE, "RET", "c9", 0],
        [GEN_SIMPLE, "RET", "c8", 1, ARG_REG, REG_JP_Z],
        [GEN_SIMPLE, "PUSH", "c5", 1, ARG_REG, REG_BC],
        [GEN_SIMPLE, "PUSH", "d5", 1, ARG_REG, REG_DE],
        [GEN_SIMPLE, "PUSH", "e5", 1, ARG_REG, REG_HL],
        [GEN_SIMPLE, "PUSH", "f5", 1, ARG_REG, REG_AF],
        [GEN_SIMPLE, "PUSH", "dde5", 1, ARG_REG, REG_IX],
        [GEN_SIMPLE, "PUSH", "fde5", 1, ARG_REG, REG_IY],
        [GEN_SIMPLE, "POP", "c1", 1, ARG_REG, REG_BC],
        [GEN_SIMPLE, "POP", "d1", 1, ARG_REG, REG_DE],
        [GEN_SIMPLE, "POP", "e1", 1, ARG_REG, REG_HL],
        [GEN_SIMPLE, "POP", "f1", 1, ARG_REG, REG_AF],
        [GEN_SIMPLE, "POP", "dde1", 1, ARG_REG, REG_IX],
        [GEN_SIMPLE, "POP", "fde1", 1, ARG_REG, REG_IY],
        [GEN_SIMPLE, "XOR", "af", 1, ARG_REG, REG_A],
        [GEN_SIMPLE, "OR", "b7", 1, ARG_REG, REG_A],
        [GEN_SIMPLE, "ADD", "dd39", 2, ARG_REG, REG_IX, ARG_REG, REG_SP],
        [GEN_SIMPLE, "SBC", "ed52", 2, ARG_REG, REG_HL, ARG_REG, REG_DE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "JP", "f2", 2, ARG_REG, REG_JP_P, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "JP", "ea", 2, ARG_REG, REG_JP_PE, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "JP", "fa", 2, ARG_REG, REG_JP_M, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE, "LD", "dd39", 2, ARG_REG, REG_IX, ARG_REG, REG_SP],
        [GEN_SIMPLE, "LD", "02", 2, ARG_PTR_REG, REG_BC, ARG_REG, REG_A],
        [GEN_SIMPLE, "LD", "12", 2, ARG_PTR_REG, REG_DE, ARG_REG, REG_A],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMA, "LD", "32", 2, ARG_PTR_VALUE, REG_NONE, ARG_REG, REG_A],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "LD", "dd21", 2, ARG_REG, REG_IX, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "LD", "01", 2, ARG_REG, REG_BC, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "LD", "11", 2, ARG_REG, REG_DE, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMB, "LD", "21", 2, ARG_REG, REG_HL, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd7e", 2, ARG_REG, REG_A, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd7e", 2, ARG_REG, REG_A, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd46", 2, ARG_REG, REG_B, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd46", 2, ARG_REG, REG_B, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd4e", 2, ARG_REG, REG_C, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd4e", 2, ARG_REG, REG_C, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd56", 2, ARG_REG, REG_D, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd56", 2, ARG_REG, REG_D, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd5e", 2, ARG_REG, REG_E, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd5e", 2, ARG_REG, REG_E, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd66", 2, ARG_REG, REG_H, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd66", 2, ARG_REG, REG_H, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd6e", 2, ARG_REG, REG_L, ARG_PTR_REG_AND_VALUE, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "dd6e", 2, ARG_REG, REG_L, ARG_PTR_REG, REG_IX],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd7e", 2, ARG_REG, REG_A, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd7e", 2, ARG_REG, REG_A, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd46", 2, ARG_REG, REG_B, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd46", 2, ARG_REG, REG_B, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd4e", 2, ARG_REG, REG_C, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd4e", 2, ARG_REG, REG_C, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd56", 2, ARG_REG, REG_D, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd56", 2, ARG_REG, REG_D, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd5e", 2, ARG_REG, REG_E, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd5e", 2, ARG_REG, REG_E, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd66", 2, ARG_REG, REG_H, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd66", 2, ARG_REG, REG_H, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd6e", 2, ARG_REG, REG_L, ARG_PTR_REG_AND_VALUE, REG_IY],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "fd6e", 2, ARG_REG, REG_L, ARG_PTR_REG, REG_IY],
        [GEN_SIMPLE, "LD", "0a", 2, ARG_REG, REG_A, ARG_PTR_REG, REG_BC],
        [GEN_SIMPLE, "LD", "1a", 2, ARG_REG, REG_A, ARG_PTR_REG, REG_DE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "3a", 2, ARG_REG, REG_A, ARG_PTR_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "3e", 2, ARG_REG, REG_A, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "06", 2, ARG_REG, REG_B, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "0e", 2, ARG_REG, REG_C, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "16", 2, ARG_REG, REG_D, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "1e", 2, ARG_REG, REG_E, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "26", 2, ARG_REG, REG_H, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_BYTE_PARAMB, "LD", "2e", 2, ARG_REG, REG_L, ARG_VALUE, REG_NONE],
        [GEN_LD_REG_REG, "LD", "", 2, ARG_REG, REG_NONE, ARG_REG, REG_NONE],
        [GEN_LD_MEM_REG, "LD", "", 2, ARG_PTR_REG, REG_NONE, ARG_REG, REG_NONE],
        [GEN_LD_REG_MEM, "LD", "", 2, ARG_REG, REG_NONE, ARG_PTR_REG, REG_NONE],
        [GEN_LD_REG_VAL, "LD", "", 2, ARG_REG, REG_NONE, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMA, "CALL", "cd", 1, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD_PARAMA, "JP", "c3", 1, ARG_VALUE, REG_NONE],
        [0]
    ];

do
    _instrs := get_instructions();
    hcasm.main("Z80", "hcasmz80");

end