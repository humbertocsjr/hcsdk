use t3x: t;
use string;
use io;
use char;
use hcatks;
use hcltks;

struct ARGS_LIST = ARG_NONE, ARG_VALUE, ARG_REG, ARG_PTR_REG, 
    ARG_PTR_REG_AND_VALUE, ARG_PTR_VALUE;
struct REGS_LIST = REG_NONE, REG_A, REG_B, REG_C, REG_D, REG_E, REG_F, REG_H, REG_L, REG_AF, 
    REG_HL, REG_BC, REG_DE, REG_SP, REG_IX, REG_IY;
struct INSTR_LIST = INSTR_GEN, INSTR_CMD, INSTR_ASM, INSTR_ARGS, 
    INSTR_ARGA_TYPE, INSTR_ARGA_REG, 
    INSTR_ARGB_TYPE, INSTR_ARGB_REG, 
    INSTR_ARGC_TYPE, INSTR_ARGC_REG;
struct PARAM_LIST = PARAM_TYPE, PARAM_REG, PARAM_VALUE, PARAM_LABEL;

struct GEN_LIST = GEN_NONE, GEN_SIMPLE, GEN_LD_REG_REG, GEN_LD_MEM_REG, GEN_LD_REG_MEM,
    GEN_SIMPLE_WITH_VALUE_WORD, GEN_LD_REG_VAL;

var _instrs;

decl gen0(2);
decl gen1(3);
decl gen2(4);
decl gen3(5);

parse_reg(id) do
    ie(\string.comp("A", id)) return REG_A;
    else ie(\string.comp("B", id)) return REG_B;
    else ie(\string.comp("C", id)) return REG_C;
    else ie(\string.comp("D", id)) return REG_D;
    else ie(\string.comp("E", id)) return REG_E;
    else ie(\string.comp("F", id)) return REG_F;
    else ie(\string.comp("H", id)) return REG_H;
    else ie(\string.comp("L", id)) return REG_L;
    else ie(\string.comp("AF", id)) return REG_AF;
    else ie(\string.comp("BC", id)) return REG_BC;
    else ie(\string.comp("DE", id)) return REG_DE;
    else ie(\string.comp("HL", id)) return REG_HL;
    else ie(\string.comp("IX", id)) return REG_IX;
    else ie(\string.comp("IY", id)) return REG_IY;
    else ie(\string.comp("SP", id)) return REG_SP;
    else return REG_NONE;
end

use hcasm;

instr_simple_byte(ins) do
    hcasm.emit_asm(ins[INSTR_ASM]);
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
    ie(type = GEN_SIMPLE_WITH_VALUE_WORD) do
        instr_simple_byte_value_word(instr, parama);
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
    end else hcasm.error("GEN0 NOT IMPLEMENTED");
end

gen3(type, instr, parama, paramb, paramc) do
    hcasm.error("GEN3 NOT IMPLEMENTED");
end


get_instructions() return [
        [GEN_SIMPLE, "NOP", "00", 0],
        [GEN_SIMPLE, "HLT", "76", 0],
        [GEN_LD_REG_REG, "LD", "", 2, ARG_REG, REG_NONE, ARG_REG, REG_NONE],
        [GEN_LD_MEM_REG, "LD", "", 2, ARG_PTR_REG, REG_NONE, ARG_REG, REG_NONE],
        [GEN_LD_REG_MEM, "LD", "", 2, ARG_REG, REG_NONE, ARG_PTR_REG, REG_NONE],
        [GEN_LD_REG_VAL, "LD", "", 2, ARG_REG, REG_NONE, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD, "CALL", "cd", 1, ARG_VALUE, REG_NONE],
        [GEN_SIMPLE_WITH_VALUE_WORD, "JP", "c3", 1, ARG_VALUE, REG_NONE],
        [0]
    ];

do
    _instrs := get_instructions();
    hcasm.main("Z80", "hcasmz80");

end