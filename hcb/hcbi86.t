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
decl asm_jmp_name(1);
decl asm_new_num_label(0);
decl asm_num_label(1);
decl asm_equal_pop_from_rega(0);
decl asm_not_equal_pop_from_rega(0);
decl asm_lesser_equal_pop_from_rega(0);
decl asm_lesser_pop_from_rega(0);
decl asm_greater_equal_pop_from_rega(0);
decl asm_greater_pop_from_rega(0);

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

asm_func_start() hcbcomp.emit_asm("5589e5"); 
    ! push bp
    ! mov bp, sp
asm_func_end() hcbcomp.emit_asm("89ec5dc3");
    ! mov sp, bp
    ! pop bp;
    ! ret
asm_func_stack_vars(bytes) do
    _asm_var := 0;
    if(bytes = 0) return;
    ! add sp, BYTES
    hcbcomp.emit_asm("81c4");
    hcbcomp.emit_tok(hclink.LNK_CODE, @bytes, 2);
end

asm_call_stack_restore(bytes) do
    if(bytes = 0) return;
    ! add sp, BYTES
    hcbcomp.emit_asm("81c4");
    hcbcomp.emit_tok(hclink.LNK_CODE, @bytes, 2);
end

asm_rega_push() hcbcomp.emit_asm("50");
    ! push ax

asm_rega_set_value(value) do
    _asm_var := 0;
    ! mov ax, VALUE
    hcbcomp.emit_asm("b8");
    hcbcomp.emit_tok(hclink.LNK_CODE, @value, 2);
end

asm_rega_from_var_label(name) do
    var zero;
    zero := 0;
    _asm_var := 0;
    ! mov ax, VAR POSITION
    hcbcomp.emit_asm("b8");
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
    offset := 0;
    !mov ax, [bp+VAR]
    hcbcomp.emit_asm("8986");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, @offset, 2);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_rega_to_local_contents(name) do
    var offset;
    _asm_var := -1;
    string.copy(_asm_var_name, name);
    offset := 0;
    !mov (ix+VAR+1), ax
    hcbcomp.emit_asm("8b86");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, @offset, 2);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_call(name) do
    _asm_var := 0;
    ! call NAME
    hcbcomp.emit_asm("e8");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, name, string.length(name));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_FUNC_USE, name, string.length(name));
end

asm_rega_clear() do
    _asm_var := 0;
    ! xor ax, ax
    hcbcomp.emit_asm("31c0");
end

asm_regb_clear() do
    ! xor bx, bx
    hcbcomp.emit_asm("31db");
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
    ! mov ax, PTR
    hcbcomp.emit_asm("e8");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_rega_pop() hcbcomp.emit_asm("58");
    ! pop ax

asm_add_pop_from_rega() hcbcomp.emit_asm("5b01d8");
    ! pop bx
    ! add ax, bx

asm_subtract_pop_from_rega() hcbcomp.emit_asm("89c35829d8");
    ! mov bx, ax
    ! pop ax
    ! sub ax, bx

asm_multiply_pop_from_rega() do
    ! pop cx
    ! imul cx
    hcbcomp.emit_asm("59f7e9");
end

asm_divide_pop_from_rega() do
    ! mov ax, cx
    ! pop ax
    ! cwd
    ! idiv cx
    hcbcomp.emit_asm("89c15899f7f9");
end

asm_module_pop_from_rega() do
    ! mov cx, ax
    ! pop ax
    ! xor dx, dx
    ! div cx
    ! mov ax, dx
    hcbcomp.emit_asm("89c15831d2f7f189d0");
end

asm_shift_left_pop_from_rega() hcbcomp.emit_asm("89c158d3e0");
    ! mov cx, ax
    ! pop ax
    ! shl ax, cl

asm_shift_right_pop_from_rega() hcbcomp.emit_asm("89c158d3e8");
    ! mov cx, ax
    ! pop ax
    ! shr ax, cl

asm_jmp_if_true(num_label) do 
    var label;
    ! or ax, ax
    ! je +3
    ! jmp NUM_LABEL
    hcbcomp.emit_asm("09c07403e9");
    label := string.ntoa(num_label, 10);
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_jmp_if_false(num_label) do 
    var label;
    ! or ax, ax
    ! jne +3
    ! jmp NUM_LABEL
    hcbcomp.emit_asm("09c07503e9");
    label := string.ntoa(num_label, 10);
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_jmp_name(label) do 
    ! jmp LABEL
    hcbcomp.emit_asm("e9");
    hcbcomp.emit_tok(hclink.LNK_REF_START, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_WORD, 0, 0);
    hcbcomp.emit_tok(hclink.LNK_REF_NAME, label, string.length(label));
    hcbcomp.emit_tok(hclink.LNK_REF_EMIT, 0, 0);
end

asm_jmp(num_label) do 
    var label;
    ! jp NUM_LABEL
    hcbcomp.emit_asm("e9");
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

asm_equal_pop_from_rega() asm_call("cmp16_eq");

asm_not_equal_pop_from_rega() asm_call("cmp16_ne");

asm_lesser_pop_from_rega() asm_call("cmp16_l");

asm_lesser_equal_pop_from_rega() asm_call("cmp16_le");

asm_greater_pop_from_rega()  asm_call("cmp16_g");

asm_greater_equal_pop_from_rega() asm_call("cmp16_ge");

do
    _asm_counter := 0;
    _asm_var := 0;
    hcbcomp.main("i86", "hcbi86");
end