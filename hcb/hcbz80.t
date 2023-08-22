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
decl asm_rega_from_var_label(1);
decl asm_rega_from_local_contents(1);
decl asm_rega_to_local_contents(1);
decl asm_rega_from_data_str(1);
decl asm_call(1);
decl asm_rega_pop(0);
decl asm_add_pop_from_rega(0);
decl asm_subtract_pop_from_rega(0);
decl asm_multiply_pop_from_rega(0);
decl asm_divide_pop_from_rega(0);
decl asm_module_pop_from_rega(0);
decl asm_shift_left_pop_from_rega(0);
decl asm_shift_right_pop_from_rega(0);
decl asm_jmp_if_true(1);
decl asm_jmp_if_false(1);
decl asm_jmp(1);
decl asm_new_num_label(0);
decl asm_num_label(1);

const VAR_BYTES = 2;

use hcbcomp;

! Label Counter
var _asm_counter;
! REGA = VAR
var _asm_var;
var _asm_var_name::hcbcomp.TOK_LEN;

asm_new_num_label() do
    var lbl;
    lbl := _asm_counter;
    _asm_counter := _asm_counter + 1;
    return lbl;
end

asm_func_start() hcbcomp.emit_asm("dde5dd210000dd39"); 
    ! push ix
    ! ld ix, 0
    ! add ix, sp
asm_func_end() hcbcomp.emit_asm("dde1c9");
    ! pop ix;
    ! ret
asm_func_stack_vars(bytes) do
    _asm_var := 0;
    if(bytes = 0) return;
    ! ld hl, BYTES
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_CODE, @bytes, 2);
    ! add hl, sp
    ! ld sp, hl
    hcbcomp.emit_asm("39f9");
end

asm_call_stack_restore(bytes) do
    if(bytes = 0) return;
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
    ! push hl

asm_rega_set_value(value) do
    _asm_var := 0;
    ! ld hl, VALUE
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_CODE, @value, 2);
end

asm_rega_from_var_label(name) do
    var zero;
    zero := 0;
    _asm_var := 0;
    ! ld hl, VAR POSITION
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, @zero, 2);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_rega_from_local_contents(name) do
    var offset;
    if(_asm_var) do
        if(\string.comp(_asm_var_name, name)) return;
    end
    _asm_var := -1;
    string.copy(_asm_var_name, name);
    offset := 1;
    !ld h,(ix+VAR+1)
    hcbcomp.emit_asm("dd66");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_BYTE, @offset, 1);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
    !ld l,(ix+VAR)
    hcbcomp.emit_asm("dd6e");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    offset := 0;
    hcbcomp.emit_tok(hclink.LNK_REF_BYTE, @offset, 1);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_rega_to_local_contents(name) do
    var offset;
    _asm_var := -1;
    string.copy(_asm_var_name, name);
    offset := 1;
    !ld h,(ix+VAR+1)
    hcbcomp.emit_asm("dd74");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_BYTE, @offset, 1);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
    !ld h,(ix+VAR)
    hcbcomp.emit_asm("dd75");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    offset := 0;
    hcbcomp.emit_tok(hclink.LNK_REF_BYTE, @offset, 1);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_call(name) do
    _asm_var := 0;
    ! call NAME
    hcbcomp.emit_asm("cd");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_FUNC_USE, name, string.length(name));
end

asm_rega_clear() do
    _asm_var := 0;
    ! ld hl, 0
    hcbcomp.emit_asm("210000");
end

asm_regb_clear() do
    ! ld de, 0
    hcbcomp.emit_asm("110000");
end


asm_rega_from_data_str(str) do
    var label;
    _asm_var := 0;
    ! ;DATA SEGMENT
    ! PTR:
    ! db XXXXXXXXX
    label := string.ntoa(asm_new_num_label(), 10);
    hcbcomp.emit_tok(hclink.LNK_DATA, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_GLOBAL_PTR, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_DATA, str, string.length(str) + 1);
    hcbcomp.emit_tok(hclink.LNK_CODE, 0, 0);
    ! ; CODE SEGMENT
    ! ld hl, PTR
    hcbcomp.emit_asm("21");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_rega_pop() hcbcomp.emit_asm("e1");
    ! pop hl

asm_add_pop_from_rega() hcbcomp.emit_asm("d119");
    ! pop de
    ! add hl, de

asm_subtract_pop_from_rega() hcbcomp.emit_asm("d1ebafed52");
    ! pop de
    ! ex hl, de
    ! xor a
    ! sbc hl, de

asm_multiply_pop_from_rega() do
    ! pop de
    hcbcomp.emit_asm("d1");
    ! call mul16
    asm_call("mul16");
end

asm_divide_pop_from_rega() do
    ! pop de
    hcbcomp.emit_asm("d1");
    ! call div16
    asm_call("div16");
end

asm_module_pop_from_rega() do
    ! pop de
    hcbcomp.emit_asm("d1");
    ! call mod16
    asm_call("mod16");
end

asm_shift_left_pop_from_rega() hcbcomp.emit_asm("d1eb432910fd");
    ! pop de
    ! ex hl, de
    ! ld b, e
    ! add hl, hl
    ! djnz -3

asm_shift_right_pop_from_rega() hcbcomp.emit_asm("d1eb43cb3ccb1d10fa");
    ! pop de
    ! ex hl, de
    ! ld b, e
    ! srl h
    ! rr l
    ! djnz -6

asm_jmp_if_true(num_label) do 
    var label;
    ! ld a, h
    ! or l
    ! jpnz NUM_LABEL
    hcbcomp.emit_asm("7cb5c2");
    label := string.ntoa(num_label, 10);
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_jmp_if_false(num_label) do 
    var label;
    ! ld a, h
    ! or l
    ! jpz NUM_LABEL
    hcbcomp.emit_asm("7cb5ca");
    label := string.ntoa(num_label, 10);
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_jmp(num_label) do 
    var label;
    ! jp NUM_LABEL
    hcbcomp.emit_asm("c3");
    label := string.ntoa(num_label, 10);
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_num_label(num_label) do
    var label;
    label := string.ntoa(num_label, 10);
    hcbcomp.emit_tok(hclink.LNK_GLOBAL_PTR, label, string.length(label));
end

do
    _asm_counter := 0;
    _asm_var := 0;
    hcbcomp.main("Z80", "hcbz80");
end