use t3x: t;
use string;
use io;
use char;
use hcbtks;
use hcltks;

decl asm_func_start(0);
decl asm_func_end(0);
decl asm_func_stack_vars(1);
decl asm_call_stack_restore(1);
decl asm_rega_push(0);
decl asm_rega_set_value(1);
decl asm_rega_clear(0);
decl asm_rega_from_var(1);
decl asm_rega_from_data_str(1);
decl asm_call(1);

const VAR_BYTES = 2;

use hcbcomp;

var _asm_counter;

asm_func_start() hcbcomp.emit_asm("dde5dd210000dd39"); 
    ! push ix
    ! ld ix, 0
    ! add ix, sp
asm_func_end() hcbcomp.emit_asm("dde1c9");
    ! pop ix;
    ! ret
asm_func_stack_vars(bytes) do
    ! ld hl, BYTES
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_CODE, @bytes, 2);
    ! add hl, sp
    ! ld sp, hl
    hcbcomp.emit_asm("39f9");
end

asm_call_stack_restore(bytes) do
    ! ex hl, de
    ! ld hl, BYTES
    hcbcomp.emit_asm("eb21");
    hcbcomp.emit_tok(hclink.LNK_CODE, @bytes, 2);
    ! add hl, sp
    ! ld sp, hl
    ! ex hl, de
    hcbcomp.emit_asm("39f9eb");
end

asm_rega_push() hcbcomp.emit_asm("e5");

asm_rega_set_value(value) do
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_CODE, @value, 2);
end

asm_rega_from_var(name) do
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_call(name) do
    hcbcomp.emit_asm("cd");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_rega_clear() hcbcomp.emit_asm("21000");

asm_rega_from_data_str(str) do
    var label;
    label := string.ntoa(_asm_counter, 10);
    hcbcomp.emit_tok(hclink.LNK_DATA, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_GLOBAL_PTR, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_DATA, str, string.length(str) + 1);
    hcbcomp.emit_tok(hclink.LNK_CODE, 0, 0);
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

do
    _asm_counter := 0;
    hcbcomp.main("Z80", "hcbz80");
end