

module hcbcomp;



const NAME_LEN = 80;
public const TOK_LEN = 80;
const LINE_LEN = 256;
const LINE_BUF_LEN = 400;
const BUF_LEN = 130;
const VAR_BUF_LEN = 1024;
const VAR_SIZE = 32;

var _can_auto;
var _var_pos;
var _locals_buf::VAR_BUF_LEN;
var _locals_buf_last;
var _locals[VAR_SIZE];
var _locals_count;
var _level;
var _in;
var _in_name::NAME_LEN;
var _in_filename::NAME_LEN;
var _in_buf::BUF_LEN;
var _in_count;
var _out;
var _out_name::NAME_LEN;
var _curr;
var _curr_line;
var _curr_col;
var _curr_len;
var _curr_text::TOK_LEN;
var _prev;
var _prev_line;
var _prev_col;
var _prev_len;
var _prev_text::TOK_LEN;
var _next;
var _next_line;
var _next_col;
var _next_len;
var _next_text::TOK_LEN;


error(msg) do 
    if(_in_count > 0) do
        io.writeln("[ ERROR ]");
    end
    io.writes(_in_name);
    io.writes(":");
    io.writes(string.ntoa(_curr_line, 10));
    io.writes(":");
    io.writes(string.ntoa(_curr_col, 10));
    io.writes(": Error: ");
    io.writeln(msg);
    io.writes("  Token ID: ");
    io.writes(string.ntoa(_curr, 10));
    io.writes(": ");
    io.writeln(_curr_text);
    halt 1;
end

local_clear() do
    _locals_count := 0;
    _locals_buf_last := 0;
    _locals_buf::_locals_buf_last := 0;
    _locals[_locals_count] := 0;
end

local_add(name) do
    var i, len;
    for(i = 0, _locals_count) do
        if(\string.comp(name, _locals[i])) do
            error("Name already registered");
        end
    end
    len := string.length(name);
    if((_locals_buf_last + len + 2) > VAR_BUF_LEN) error("Local name buffer overflow");
    if((_locals_count + 2) > VAR_SIZE) error("Local name list overflow");
    t.memcopy(@_locals_buf::_locals_buf_last, name, len + 1);
    _locals[_locals_count] := @_locals_buf::_locals_buf_last;
    _locals_buf_last := _locals_buf_last + len + 1;
    _locals_count := _locals_count + 1;
    return _locals_count - 1;
end

local_match(name, errmsg) do
    var i;
    for(i = 0, _locals_count) do
        if(\string.comp(name, _locals[i])) do
            return i;
        end
    end
    error(errmsg);
end

local_find(name) do
    var i;
    for(i = 0, _locals_count) do
        if(\string.comp(name, _locals[i])) do
            return i;
        end
    end
    return -1;
end

public emit_tok(type, buf, len) do
    t.write(_out, @type, 2);
    t.write(_out, @len, 2);
    if(len \= 0) do
        t.write(_out, buf, len);
    end
end

xton(c) do
    ie(c = '0')      return 0x00;
    else ie(c = '1') return 0x01;
    else ie(c = '2') return 0x02;
    else ie(c = '3') return 0x03;
    else ie(c = '4') return 0x04;
    else ie(c = '5') return 0x05;
    else ie(c = '6') return 0x06;
    else ie(c = '7') return 0x07;
    else ie(c = '8') return 0x08;
    else ie(c = '9') return 0x09;
    else ie(c = 'a') return 0x0a;
    else ie(c = 'A') return 0x01;
    else ie(c = 'b') return 0x0b;
    else ie(c = 'B') return 0x0b;
    else ie(c = 'c') return 0x0c;
    else ie(c = 'C') return 0x0c;
    else ie(c = 'd') return 0x0d;
    else ie(c = 'D') return 0x0d;
    else ie(c = 'e') return 0x0e;
    else ie(c = 'E') return 0x0e;
    else ie(c = 'f') return 0x0f;
    else ie(c = 'F') return 0x0f;
    else return 0;
end


emit_tok_hex(type, hex) do
    var tmp::30;
    var len;
    var i;
    var j;
    j := 0;
    len := string.length(hex);
    for(i = 0, len, 2) do
        tmp::j := (xton(hex::i) << 4) + (xton(hex::(i+1)));
        tmp::(j+1) := 0;
        j := j + 1;
    end
    emit_tok(type, tmp, j);
end

public emit_asm(hex) do
    emit_tok_hex(hclink.LNK_CODE, hex);
end

next() do
    var size;
    var read;
    read := %1;
    _prev := _curr;
    _prev_col := _curr_col;
    _prev_line := _curr_line;
    _prev_len := _curr_len;
    t.memcopy(_prev_text, _curr_text, TOK_LEN);
    _curr := _next;
    _curr_col := _next_col;
    _curr_line := _next_line;
    _curr_len := _next_len;
    t.memcopy(_curr_text, _next_text, TOK_LEN);
    if(_next = tokens.TK_END) return 0;
    while (read) do
        size := 0;
        _next := 0;
        if(t.read(_in, @_next, 2) = %1) return 0;
        t.read(_in, @size, 2);
        _next_len := size;
        t.memfill(_next_text, 0, TOK_LEN);
        if(size \= 0) do
            t.read(_in, _next_text, size);
        end
        ie(_next = tokens.TK_MARKER_FILE) do
            t.memcopy(_in_name, _next_text, TOK_LEN);
            ie(_in_count = 0) do
            end else do
                io.writeln("[ OK ]");
                io.nl();
            end
            _in_count := _in_count + 1;
            io.writes(" - Compiling ");
            io.writes(_in_name);
            emit_tok(hclink.LNK_MARKER_FILE, _in_name, string.length(_in_name));
            read := %1;
        end else ie(_next = tokens.TK_MARKER_LINE) do
            _next_line := _next_text[0];
            emit_tok(hclink.LNK_MARKER_LINE, @_next_line, 2);
            io.writes(".");
            read := %1;
        end else ie(_next = tokens.TK_MARKER_COL) do
            _next_col := _next_text[0];
            read := %1;
        end else do
            read := 0;
        end
    end;
    return %1;
end

match(type, errmsg) do
    if(type \= _curr) do
        error(errmsg);
    end
end


match_eol() do
    match(tokens.TK_END_COMMAND, "';' expected");
end

decl compile(0);
decl do_expr(0);


do_auto() do
    if(_level > 0)
        if(\_can_auto) error("can't declare variables after start of a function");
    next();
    while(_curr \= tokens.TK_END_COMMAND) do
        match(tokens.TK_ID, "Variable name expected");
        local_add(_curr_text);
        emit_tok(hclink.LNK_DATA, 0, 0);
        ie(_level = 0) do
            emit_tok(hclink.LNK_PUBLIC_PTR, _curr_text, _curr_len);
        end else do
            emit_tok(hclink.LNK_LOCAL_CONST_NAME, _curr_text, _curr_len);
            _var_pos := _var_pos - VAR_BYTES;
            emit_tok(hclink.LNK_LOCAL_CONST_VALUE, @_var_pos, 2);
        end
        next();
        if(_curr \= tokens.TK_END_COMMAND) match(tokens.TK_COMMA, "',' expected");
    end
end

do_block() do
    match(tokens.TK_BLOCK_OPEN, "'{' expected");
    while(next()) do
        if(_curr = tokens.TK_BLOCK_CLOSE) leave;
        compile();
    end
    match(tokens.TK_BLOCK_CLOSE, "'}' expected");
end

do_function(name) do
    var i, argpos;
    emit_tok(hclink.LNK_CODE, 0,0);
    emit_tok(hclink.LNK_CLEAR_LOCAL, 0, 0);
    emit_tok(hclink.LNK_FUNC_START, name, string.length(name));
    emit_tok(hclink.LNK_PUBLIC_PTR, name, string.length(name));
    emit_tok(hclink.LNK_GLOBAL_PTR, name, string.length(name));
    emit_tok(hclink.LNK_LOCAL_PTR, name, string.length(name));
    local_clear();
    local_add(name);
    asm_func_start();
    match(tokens.TK_PARAM_OPEN, "'(' expected");
    argpos := 4;
    _var_pos := 0;
    _level := 1;
    while(next()) do
        if(_curr = tokens.TK_PARAM_CLOSE) leave;
        local_add(_curr_text);
        emit_tok(hclink.LNK_LOCAL_CONST_NAME, name, string.length(name));
        emit_tok(hclink.LNK_LOCAL_CONST_VALUE, @argpos, 2);
        argpos := argpos + VAR_BYTES;
        if(_next \= tokens.TK_PARAM_CLOSE) do
            next();
            match(tokens.TK_COMMA, "',' expected");
        end
    end
    match(tokens.TK_PARAM_CLOSE, "')' expected");
    next();
    _can_auto := %1;
    do_block();
    asm_func_end();
    emit_tok(hclink.LNK_FUNC_END, name, string.length(name));
    emit_tok(hclink.LNK_CLEAR_LOCAL, 0, 0);
    _level := 0;
end

do_args() do
    var stack_size;
    stack_size := 0;
    match(tokens.TK_PARAM_OPEN, "'(' expected");
    while(next()) do
        if(_curr = tokens.TK_PARAM_CLOSE) leave;
        do_expr();
        asm_rega_push();
        stack_size := stack_size + VAR_BYTES;
        if(_next \= tokens.TK_PARAM_CLOSE) do
            next();
            match(tokens.TK_COMMA, "',' expected");
        end
    end
    match(tokens.TK_PARAM_CLOSE, "')' expected");
    return stack_size;
end

expr5() do
    var i, val, neg, name::TOK_LEN;
    var stack_size;
    neg := 0;
    if(_curr = tokens.TK_MATH_SUBTRACT) do
        neg := %1;
        next();
    end
    ie(_curr = tokens.TK_NUM) do
        val := 0;
        for(i = 0, _curr_len) do
            val := val * 10 + (_curr_text::i) - '0';
        end
        if(neg) val := -val;
        asm_rega_set_value(val);
    end else ie(_curr = tokens.TK_STR) do
        if(neg) error("Unsupported string operation");
        asm_rega_from_data_str(_curr_text);
    end else ie(_curr = tokens.TK_ID) do
        i := local_find(_curr_text);
        ie(i = -1) do
            error("Name not found");
        end else do
            t.memcopy(name, _curr_text, TOK_LEN);
            ie(_next = tokens.TK_PARAM_OPEN) do
                stack_size := do_args();
                asm_call(name);
                if(stack_size \= 0) asm_call_stack_restore(stack_size);
            end else do
                asm_rega_from_local_contents(name);
            end
        end
    end else ie(_curr = tokens.TK_PARAM_OPEN) do
        next();
        do_expr();
        match(_curr = tokens.TK_PARAM_CLOSE, "'(' expected.");
    end else error("Expression expected");
end


expr4() do
    var op;
    expr5();
    while(_next = tokens.TK_BIT_SHL \/ _next = tokens.TK_BIT_SHR)do
        op := _next;
        next();
        next();
        asm_rega_push();
        expr5();
        ie(op = tokens.TK_BIT_SHL)
            asm_shift_left_pop_from_rega();
        else ie(op = tokens.TK_BIT_SHR)
            asm_shift_right_pop_from_rega();
        else error("Operation unknown");
    end
end

expr3() do
    var op;
    expr4();
    while(_next = tokens.TK_MATH_MULTIPLY \/ _next = tokens.TK_MATH_DIVIDE \/ _next = tokens.TK_MATH_MODULE)do
        op := _next;
        next();
        next();
        asm_rega_push();
        expr4();
        ie(op = tokens.TK_MATH_MULTIPLY)
            asm_multiply_pop_from_rega();
        else ie(op = tokens.TK_MATH_DIVIDE)
            asm_divide_pop_from_rega();
        else ie(op = tokens.TK_MATH_MODULE)
            asm_module_pop_from_rega();
        else error("Operation unknown");
    end
end

expr2() do
    var op;
    expr3();
    while(_next = tokens.TK_MATH_SUBTRACT \/ _next = tokens.TK_MATH_SUM)do
        op := _next;
        next();
        next();
        asm_rega_push();
        expr3();
        ie(op = tokens.TK_MATH_SUM)
            asm_add_pop_from_rega();
        else ie(op = tokens.TK_MATH_SUBTRACT)
            asm_subtract_pop_from_rega();
        else error("Operation unknown");
    end
end


expr1() do
    var op, lbl_true, lbl_false, lbl_end;
    expr2();
    while(_next = tokens.TK_CMP_OR)do
        lbl_true := asm_new_num_label();
        lbl_false := asm_new_num_label();
        lbl_end := asm_new_num_label();
        op := _next;
        next();
        next();
        ie(op = tokens.TK_CMP_OR) do
            asm_jmp_if_true(lbl_true);
        end else error("Operation unknown");
        expr2();
        ie(op = tokens.TK_CMP_OR) do
            asm_jmp_if_true(lbl_true);
        end else error("Operation unknown");
        asm_num_label(lbl_false);
        asm_rega_clear();
        asm_jmp(lbl_end);
        asm_num_label(lbl_true);
        asm_rega_set_value(0xffff);
        asm_num_label(lbl_end);
    end
end

do_expr() do
    var op, lbl_true, lbl_false, lbl_end;
    expr1();
    while(_next = tokens.TK_CMP_AND)do
        lbl_true := asm_new_num_label();
        lbl_false := asm_new_num_label();
        lbl_end := asm_new_num_label();
        op := _next;
        next();
        next();
        ie(op = tokens.TK_CMP_AND) do
            asm_jmp_if_false(lbl_false);
        end else error("Operation unknown");
        expr1();
        ie(op = tokens.TK_CMP_AND) do
            asm_jmp_if_true(lbl_true);
        end else error("Operation unknown");
        asm_num_label(lbl_false);
        asm_rega_clear();
        asm_jmp(lbl_end);
        asm_num_label(lbl_true);
        asm_rega_set_value(0xffff);
        asm_num_label(lbl_end);
    end
end

do_call(name) do
    var stack_size;
    stack_size := do_args();
    asm_call(name);
    if(stack_size \= 0) asm_call_stack_restore(stack_size);
    next();
    match_eol();
end

do_atrib(name) do
    next();
    do_expr();
    asm_rega_to_local_contents(name);
    next();
    match_eol();
end

do_id() do
    var name::TOK_LEN;
    string.ncopy(TOK_LEN, name, _curr_text);
    next();
    ie(_curr = tokens.TK_PARAM_OPEN) do
        ie(_level = 0) do
            do_function(name);
        end else do 
            do_call(name);
        end
    end else ie(_curr = tokens.TK_ATRIB) do
        do_atrib(name);
    end else do
        io.writes("[ ID Type not implemented -> Token ID:");
        io.writes(string.ntoa(_curr, 10));
        io.writes(" ]");
    end
end

do_if() do
    var lbl_false, lbl_end;
    lbl_false := asm_new_num_label();
    next();
    match(tokens.TK_PARAM_OPEN, "'(' expected");
    next();
    do_expr();
    next();
    match(tokens.TK_PARAM_CLOSE, "')' expected");
    asm_jmp_if_false(lbl_false);
    compile();
    ie(_curr = tokens.TK_ID_ELSE) do
        lbl_end := asm_new_num_label();
        asm_jmp(lbl_end);
        asm_num_label(lbl_false);
        compile();
        asm_num_label(lbl_end);
    end else do
        asm_num_label(lbl_false);
    end
end

do_while() do
    var lbl_end, lbl_start;
    lbl_end := asm_new_num_label();
    next();
    match(tokens.TK_PARAM_OPEN, "'(' expected");
    next();
    asm_num_label(lbl_start);
    do_expr();
    next();
    match(tokens.TK_PARAM_CLOSE, "')' expected");
    asm_jmp_if_false(lbl_end);
    compile();
    asm_jmp(lbl_start);
    asm_num_label(lbl_end);
end

do_until() do
    var lbl_end, lbl_start;
    lbl_end := asm_new_num_label();
    next();
    match(tokens.TK_PARAM_OPEN, "'(' expected");
    next();
    asm_num_label(lbl_start);
    do_expr();
    next();
    match(tokens.TK_PARAM_CLOSE, "')' expected");
    asm_jmp_if_true(lbl_end);
    compile();
    asm_jmp(lbl_start);
    asm_num_label(lbl_end);
end

compile() do
    ie(_curr = tokens.TK_ID_AUTO) do
        do_auto();
    end else do 
        if(_can_auto) do
            if(_level > 0) do
                asm_func_stack_vars(_var_pos);
                _can_auto := 0;
            end
        end
        ie(_curr = tokens.TK_ID) do
            do_id();
        end else ie(_curr = tokens.TK_ID_IF) do
            do_if();
        end else ie(_curr = tokens.TK_ID_WHILE) do
            do_while();
        end else ie(_curr = tokens.TK_ID_UNTIL) do
            do_until();
        end else ie(_curr = tokens.TK_BLOCK_OPEN) do
            do_block();
        end else do
            io.writes("[ Token not implemented ID:");
            io.writes(string.ntoa(_curr, 10));
            io.writes(" ]");
        end
    end
end

compile_file(filename) do
    _in := t.open(_in_name, T3X.OREAD);
    if(_in = -1) do
        error("File can't be opened");
    end
    _level := 0;
    next();
    while (next()) do
        compile();
    end
    t.close(_in);
end


show_help(arch_file) do
    io.writeln("Compiles B Language Tokens to Z80 HCLink Object File");
    io.writeln("");
    io.writeln("Usage: ");
    io.writes(" ");
    io.writes(arch_file);
    io.writeln(" [infile.btk] [outfile.obj]");
end

public main(arch_name, arch_file) do
    var in_size, out_size;
    io.writes("HC B Language Compiler for ");
    io.writes(arch_name);
    io.writeln(" v0.3");
    io.writeln("(c)2023 by Humberto Costa dos Santos Jr");

    io.writeln("");
    
    in_size := t.getarg(1, _in_name, NAME_LEN);
    out_size := t.getarg(2, _out_name, NAME_LEN);

    _curr := tokens.TK_NONE;
    _prev := tokens.TK_NONE;
    _next := tokens.TK_NONE;
    _next_col := 0;
    _next_line := 0;
    _in_count := 0;

    ie (in_size > 0) do
        if (out_size < 1) do
			out_size := in_size;
			t.memcopy(_out_name, _in_name, in_size+1);
			t.memcopy(@_in_name::in_size, ".btk", 5);
			t.memcopy(@_out_name::out_size, ".obj", 5);
        end
        string.copy(_in_filename, _in_name);
        _out := t.open(_out_name, T3X.OWRITE);
        if(_out = -1) do
            error("File can't be opened");
        end
        compile_file(_in_name);
        emit_tok(hclink.LNK_END, 0, 0);
        t.close(_out);
        t.remove(_in_filename);
        if(_in_count \= 0) do
            io.writeln("[ OK ]");
            io.nl();
        end

    end else do
        show_help(arch_file);
        halt -1;
    end
end

end