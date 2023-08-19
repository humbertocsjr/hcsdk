use t3x: t;
use string;
use io;
use char;
use hcltks;

const NAME_LEN = 80;
const TOK_LEN = 80;
const LINE_LEN = 256;
const LINE_BUF_LEN = 400;
const BUF_LEN = 130;
const NAME_BUF_LEN = 1000;
const NAME_LIST_SIZE = 1000;

struct NAME_TYPES = NT_NONE, NT_FUNC, NT_USE;
const NT_KEEP = 128;

struct SECTORS = SEC_NONE, SEC_CODE, SEC_DATA;

var _func_buffer::NAME_BUF_LEN;
var _func_buffer_last;
var _name_list[NAME_LIST_SIZE];
var _name_func_list[NAME_LIST_SIZE];
var _name_type_list::NAME_LIST_SIZE;

var _pos;
var _step;
var _sector;
var _startup_found;
var _emit;
var _func;
var _func_inside;
var _func_name::TOK_LEN;
var _in;
var _in_name::NAME_LEN;
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

name_clear_all() do
    var i;
    for(i = 0, NAME_LIST_SIZE) do
        _name_type_list::i := NT_NONE;
    end
    _func_buffer_last := 0;
    t.memfill(_func_buffer, 0, NAME_BUF_LEN);
end


func_add(type, name, func) do
    var i, len, pos, found;
    len := string.length(name) + 1;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) do
            _name_type_list::i := type;
            pos := 0;
            found := 0;
            while(pos < _func_buffer_last) do
                ie(\t.memcomp(@_func_buffer::pos, name, len)) do
                    found := %1;
                    _name_list[i] := @_func_buffer::pos;
                    leave;
                end else do
                    pos := pos + string.length(@_func_buffer::pos) + 1;
                end
            end
            if(\found) do
                t.memcopy(@_func_buffer::_func_buffer_last, name, len);
                _name_list[i] := @_func_buffer::_func_buffer_last;
                _func_buffer_last := _func_buffer_last + len;
            end
            _name_func_list[i] := func;
            return i;
        end
    end
    return -1;
end


error1(msg, extra) do 
    if(_in_count > 0) do
        io.writeln("[ ERROR ]");
    end
    io.writes(_in_name);
    io.writes(":");
    io.writes(string.ntoa(_curr_line, 10));
    io.writes(":");
    io.writes(string.ntoa(_curr_col, 10));
    io.writes(": Error: ");
    io.writes(msg);
    io.writeln(extra);
    halt 1;
end

error(msg) do 
    error1(msg, "");
end

func_get(name) do
    var i;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) return %1;
        if(\string.comp(name, _name_list[i])) do
            if(_name_type_list::i & NT_KEEP) do
                return i;
            end
        end
    end
    return %1;
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
    if(_curr = hclink.LNK_CODE) _sector := SEC_CODE;
    if(_curr = hclink.LNK_DATA) _sector := SEC_DATA;
    t.memcopy(_curr_text, _next_text, TOK_LEN);
    _next_text[0] := 0;
    _next_text[1] := 0;
    if(_next = hclink.LNK_END) return 0;
    size := 0;
    if(t.read(_in, @_next, 2) = %1) return 0;
    t.read(_in, @size, 2);
    _next_len := size;
    t.memfill(_next_text, 0, TOK_LEN);
    if(size \= 0) do
        t.read(_in, _next_text, size);
    end
    return %1;
end

emit_tok(type, buf, len) do
    t.write(_out, @type, 2);
    t.write(_out, @len, 2);
    _pos := _pos + 4 + len;
    if(len \= 0) do
        t.write(_out, buf, len);
    end
end

step_common(title) do
    ie(_curr = hclink.LNK_MARKER_FILE) do
        t.memcopy(_in_name, _next_text, TOK_LEN);
        if(_in_count > 0) do
            io.writeln("[ OK ]");
        end
        _in_count := _in_count + 1;
        io.writes(title);
        io.writes(_curr_text);
    end else ie(_curr = hclink.LNK_MARKER_LINE) do
        io.writes(".");
    end else ie(_curr = hclink.LNK_FUNC_START) do
        t.memcopy(_func_name, _next_text, TOK_LEN);
        _func_inside := %1;
    end else if(_curr = hclink.LNK_FUNC_END) do
        _func_inside := 0;
        _func := -1;
    end
end

! STEP 0 - Search func
step0() do 
    step_common(" - Searching functions from ");
    ie(_curr = hclink.LNK_FUNC_START) do
        _func := func_add(NT_FUNC, _curr_text, -1);
    end else if(_curr = hclink.LNK_FUNC_USE) do
        func_add(NT_USE, _curr_text, _func);
    end
end

! STEP 1 - Copy startup
step1() do 
    if(_curr = hclink.LNK_FUNC_START) do
        if(\string.comp(_curr_text, "_start") \/ \string.comp(_curr_text, "_START")) do
            _startup_found := _startup_found + 1;
            _emit := -1;
            io.writes(" - Copying startup function");
            emit_tok(hclink.LNK_MARKER_FILE, _in_name, string.length(_in_name));
        end
    end
    if(_emit) do
        emit_tok(_curr, _curr_text, _curr_len);
        if(_emit) io.writes(".");
    end
    if(_curr = hclink.LNK_FUNC_END) do
        if(_emit) io.writeln("[ OK ]");
        _emit := 0;
    end
end

step2_apply(func) do
    var i, j;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) leave;
        if(_name_func_list[i] = func) do
            io.writes(".");
            if(_name_type_list::i & NT_USE) do
                for(j = 0, NAME_LIST_SIZE) do
                    if(_name_type_list::j = NT_NONE) leave;
                    if(_name_type_list::j = NT_FUNC) do
                        if(\string.comp(_name_list[j], _name_list[i])) do
                            _name_type_list::j := _name_type_list::j | NT_KEEP;
                            step2_apply(j);
                        end
                    end
                end
            end
        end
    end
end

! STEP 2 - Build functions table
step2() do
    var i, start;
    start := %1;
    io.writes(" - Building referenced functions table");
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) leave;
        if(_name_type_list::i = NT_FUNC) do
            if(\string.comp(_name_list[i], "_start") \/ \string.comp(_name_list[i], "_START")) do
                start := i;
                leave;
            end
        end
    end
    ie(start >= 0) do
        step2_apply(start);
    end else do
        error("Start function not found");
    end
    io.writeln("[ OK ]");
end

! STEP 3 - Copy other routines
step3() do 
    var emit;
    step_common(" - Copying referenced functions from ");
    if(_curr = hclink.LNK_FUNC_START) do
        if(func_get(_curr_text) >= 0) do
            _emit := -1;
        end
    end
    if(_emit) do
        emit_tok(_curr, _curr_text, _curr_len);
    end
    if(_func_inside = 0) do
        ie(_curr = hclink.LNK_MARKER_FILE) emit := -1;
        else ie(_curr = hclink.LNK_MARKER_LINE) emit := -1;
        else ie(_curr = hclink.LNK_MARKER_COL) emit := -1;
        else ie(_curr = hclink.LNK_DATA) emit := -1;
        else ie(_curr = hclink.LNK_LOCAL_PTR) emit := -1;
        else ie(_curr = hclink.LNK_GLOBAL_PTR) emit := -1;
        else ie(_curr = hclink.LNK_PUBLIC_PTR) emit := -1;
        else ie(_curr = hclink.LNK_REF_BYTE) emit := -1;
        else ie(_curr = hclink.LNK_REF_CURR_POS) emit := -1;
        else ie(_curr = hclink.LNK_REF_EMIT) emit := -1;
        else ie(_curr = hclink.LNK_REF_NAME) emit := -1;
        else ie(_curr = hclink.LNK_REF_NEXT_POS) emit := -1;
        else ie(_curr = hclink.LNK_REF_START) emit := -1;
        else ie(_curr = hclink.LNK_REF_WORD) emit := -1;
        else ie(_curr = hclink.LNK_EXTERN) emit := -1;
        else emit := 0;
        if(emit)emit_tok(_curr, _curr_text, _curr_len);
    end
    if(_curr = hclink.LNK_FUNC_END) do
        _emit := 0;
    end
end

compile_file(filename) do
    _in := t.open(_in_name, T3X.OREAD);
    if(_in = -1) do
        error("File can't be opened");
    end
    _sector := SEC_NONE;
    next();
    _func_inside := 0;
    _emit := 0;
    while (next()) do
        ie(_step = 0) do
            step0();
        end else ie(_step = 1) do
            step1();
        end else ie(_step = 3) do
            step3();
        end else do
        end
    end
    t.close(_in);
end

compile_step(step) do
    var curr_in;
    curr_in := 2;
    _step := step;
    _in_count := 0;
    while(t.getarg(curr_in, _in_name, NAME_LEN) > 0) do
        _curr := hclink.LNK_NONE;
        _prev := hclink.LNK_NONE;
        _next := hclink.LNK_NONE;
        compile_file(_in_name);
        curr_in := curr_in + 1;
    end
    if(_in_count \= 0) do
        io.writeln("[ OK ]");
    end
end

show_help() do
    io.writes("Embeds HCLink Objects, filters unused functions and ");
    io.writeln("generates executable object in HCLink Library format.");
    io.writeln("");
    io.writeln("Usage: ");
    io.writeln(" hcexe [outfile] [infiles.ext..]");
    io.writeln("Accept as input files: .LIB / .OBJ");
end

do
    var out_size, ext, name::NAME_LEN;
    io.writeln("HCLink Executable Generator v0.8");
    io.writeln("(c)2023 by Humberto Costa dos Santos Jr");

    io.writeln("");
    
    name_clear_all();

    out_size := t.getarg(1, _out_name, 10);

    _pos := 0;
    _startup_found := 0;

    ie (out_size > 0) do
        t.memcopy(name, _out_name, out_size);
        t.memcopy(@name::out_size, ".lib", 4);
        _out := t.open(name, T3X.OWRITE);
        if(_out = -1) do
            error("Output file can't be opened");
        end
        compile_step(0);
        compile_step(1);
        if(_startup_found = 0) do
            error("'_start' function not found");
        end
        if(_startup_found > 1) do
            error("Multiple '_start' functions has been founded");
        end
        step2();
        compile_step(3);
        emit_tok(hclink.LNK_END, 0,0);
        t.close(_out);
        io.nl();

    end else do
        show_help();
        halt -1;
    end
end