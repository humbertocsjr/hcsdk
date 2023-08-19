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

struct NAME_TYPES = NT_NONE, NT_PTR, NT_CONST, NT_REF_BYTE, NT_REF_WORD;
const NT_LOCAL = 32;
const NT_GLOBAL = 64;
const NT_PUBLIC = 128;

struct SECTORS = SEC_NONE, SEC_CODE, SEC_DATA;

var _public_buffer::NAME_BUF_LEN;
var _public_buffer_last;
var _global_buffer::NAME_BUF_LEN;
var _global_buffer_last;
var _local_buffer::NAME_BUF_LEN;
var _local_buffer_last;
var _name_list[NAME_LIST_SIZE];
var _name_value_list[NAME_LIST_SIZE];
var _name_type_list::NAME_LIST_SIZE;

var _const_id;
var _pos;
var _library;
var _org;
var _step;
var _sector;
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
    _global_buffer_last := 0;
    _local_buffer_last := 0;
    _public_buffer_last := 0;
    t.memfill(_public_buffer, 0, NAME_BUF_LEN);
    t.memfill(_global_buffer, 0, NAME_BUF_LEN);
    t.memfill(_local_buffer, 0, NAME_BUF_LEN);
end

local_clear() do
    var i;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i & NT_LOCAL) do
            _name_type_list::i := NT_NONE;
        end
    end
    _local_buffer_last := 0;
    t.memfill(_local_buffer, 0, NAME_BUF_LEN);
end

global_add(type, name, value) do
    var i, len, pos, found;
    len := string.length(name) + 1;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) do
            _name_type_list::i := type | NT_GLOBAL;
            pos := 0;
            found := 0;
            while(pos < _global_buffer_last) do
                ie(\t.memcomp(@_global_buffer::pos, name, len)) do
                    found := %1;
                    _name_list[i] := @_global_buffer::pos;
                    leave;
                end else do
                    pos := pos + string.length(@_global_buffer::pos) + 1;
                end
            end
            if(\found) do
                t.memcopy(@_global_buffer::_global_buffer_last, name, len);
                _name_list[i] := @_global_buffer::_global_buffer_last;
                _global_buffer_last := _global_buffer_last + len;
            end
            _name_value_list[i] := value;
            return i;
        end
    end
    return -1;
end

local_add(type, name, value) do
    var i, len, pos, found;
    len := string.length(name) + 1;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) do
            _name_type_list::i := type | NT_LOCAL;
            pos := 0;
            found := 0;
            while(pos < _local_buffer_last) do
                ie(\t.memcomp(@_local_buffer::pos, name, len)) do
                    found := %1;
                    _name_list[i] := @_local_buffer::pos;
                    leave;
                end else do
                    pos := pos + string.length(@_local_buffer::pos) + 1;
                end
            end
            if(\found) do
                t.memcopy(@_local_buffer::_local_buffer_last, name, len);
                _name_list[i] := @_local_buffer::_local_buffer_last;
                _local_buffer_last := _local_buffer_last + len;
            end
            _name_value_list[i] := value;
            return i;
        end
    end
    return -1;
end


public_add(type, name, value) do
    var i, len, pos, found;
    len := string.length(name) + 1;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) do
            _name_type_list::i := type | NT_PUBLIC;
            pos := 0;
            found := 0;
            while(pos < _global_buffer_last) do
                ie(\t.memcomp(@_public_buffer::pos, name, len)) do
                    found := %1;
                    _name_list[i] := @_public_buffer::pos;
                    leave;
                end else do
                    pos := pos + string.length(@_public_buffer::pos) + 1;
                end
            end
            if(\found) do
                t.memcopy(@_public_buffer::_public_buffer_last, name, len);
                _name_list[i] := @_public_buffer::_public_buffer_last;
                _public_buffer_last := _public_buffer_last + len;
            end
            _name_value_list[i] := value;
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

name_get(name) do
    var i;
    for(i = 0, NAME_LIST_SIZE) do
        if(_name_type_list::i = NT_NONE) return %1;
        if(\string.comp(name, _name_list[i])) do
            return i;
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
    while (read) do
        size := 0;
        if(t.read(_in, @_next, 2) = %1) return 0;
        t.read(_in, @size, 2);
        _next_len := size;
        t.memfill(_next_text, 0, TOK_LEN);
        if(size \= 0) do
            t.read(_in, _next_text, size);
        end
        ie(_library) do
            read := 0;
        end else ie(_next = hclink.LNK_MARKER_FILE) do
            t.memcopy(_in_name, _next_text, TOK_LEN);
            ie(_in_count = 0) do
            end else do
                io.writeln("[ OK ]");
            end
            _in_count := _in_count + 1;
            ie(_step = 0) io.writes(" - Calculating code references from ");
            else ie(_step = 1) io.writes(" - Calculating data references from ");
            else ie(_step = 2) io.writes(" - Compiling code section from ");
            else ie(_step = 3) io.writes(" - Compiling data section from ");
            else io.writes(" - UNKNOWN ");
            io.writes(_in_name);
            read := %1;
        end else ie(_next = hclink.LNK_MARKER_LINE) do
            _next_line := _next_text[0];
            io.writes(".");
            read := %1;
        end else ie(_next = hclink.LNK_MARKER_COL) do
            _next_col := _next_text[0];
            read := %1;
        end else do
            read := 0;
        end
    end;
    return %1;
end

emit(buf, len) do
    t.write(_out, buf, len);
    _pos := _pos + len;
end

emit_tok(type, buf, len) do
    t.write(_out, @type, 2);
    t.write(_out, @len, 2);
    _pos := _pos + 4 + len;
    if(len \= 0) do
        t.write(_out, buf, len);
    end
end

emit_byte(value) do
    t.write(_out, @value, 1);
    _pos := _pos + 1;
end

emit_word(value) do
    t.write(_out, @value, 2);
    _pos := _pos + 2;
end

! STEP 0 - Calculate Code
step0() do 
    var ref_size;
    if(_sector = SEC_CODE) do
        ie(_curr = hclink.LNK_CODE) do
            _pos := _pos + _curr_len;
        end else ie(_curr = hclink.LNK_GLOBAL_PTR) do
            global_add(NT_PTR, _curr_text, _pos + _org);
        end else ie(_curr = hclink.LNK_PUBLIC_PTR) do
            public_add(NT_PTR, _curr_text, _pos + _org);
        end else ie(_curr = hclink.LNK_LOCAL_CONST_NAME) do
            _const_id := local_add(NT_PTR, _curr_text, 0);
        end else ie(_curr = hclink.LNK_LOCAL_CONST_VALUE) do
            _name_value_list[_const_id] := string.aton(_curr_text, 10, _curr_len);
        end else ie(_curr = hclink.LNK_GLOBAL_CONST_NAME) do
            _const_id := global_add(NT_PTR, _curr_text, 0);
        end else ie(_curr = hclink.LNK_GLOBAL_CONST_VALUE) do
            _name_value_list[_const_id] := string.aton(_curr_text, 10, _curr_len);
        end else ie(_curr = hclink.LNK_REF_START) do
            ref_size := 0;
            while(next()) do
                if(_curr = hclink.LNK_REF_EMIT) leave;
                ie(_curr = hclink.LNK_REF_WORD) do
                    ref_size := 2;
                end else if(_curr = hclink.LNK_REF_BYTE) do
                    ref_size := 1;
                end 
            end
            ie(ref_size = 2) do
                _pos := _pos + ref_size;
            end else ie(ref_size = 1) do
                _pos := _pos + ref_size;
            end else error("Unknown reference size");

        end else do
        end
    end
end

! STEP 1 - Calculate Data
step1() do 
    var ref_size, const_id;
    const_id := NAME_LIST_SIZE - 1;
    if(_sector = SEC_DATA) do
        ie(_curr = hclink.LNK_DATA) do
            _pos := _pos + _curr_len;
        end else ie(_curr = hclink.LNK_GLOBAL_PTR) do
            global_add(NT_PTR, _curr_text, _pos + _org);
        end else ie(_curr = hclink.LNK_PUBLIC_PTR) do
            public_add(NT_PTR, _curr_text, _pos + _org);
        end else ie(_curr = hclink.LNK_LOCAL_CONST_NAME) do
            _const_id := local_add(NT_PTR, _curr_text, 0);
        end else ie(_curr = hclink.LNK_LOCAL_CONST_VALUE) do
            _name_value_list[_const_id] := _curr_text[0];
        end else ie(_curr = hclink.LNK_GLOBAL_CONST_NAME) do
            _const_id := global_add(NT_PTR, _curr_text, 0);
            io.writes(_curr_text);
        end else ie(_curr = hclink.LNK_GLOBAL_CONST_VALUE) do
            _name_value_list[_const_id] := _curr_text[0];
        end else ie(_curr = hclink.LNK_REF_START) do
            ref_size := 0;
            while(next()) do
                if(_curr = hclink.LNK_REF_EMIT) leave;
                ie(_curr = hclink.LNK_REF_WORD) do
                    ref_size := 2;
                end else if(_curr = hclink.LNK_REF_BYTE) do
                    ref_size := 1;
                end 
            end
            ie(ref_size = 2) do
                _pos := _pos + ref_size;
            end else ie(ref_size = 1) do
                _pos := _pos + ref_size;
            end else error("Unknown reference size");

        end else do
        end
    end
end

! STEP 2 - Compile Code
step2() do 
    var ref_value, ref_size, const_id, new_value;
    const_id := NAME_LIST_SIZE - 1;
    if(_sector = SEC_CODE) do
        ie(_curr = hclink.LNK_CODE) do
            emit(_curr_text, _curr_len);
        end else ie(_curr = hclink.LNK_CLEAR_LOCAL) do
            local_clear();
        end else ie(_curr = hclink.LNK_LOCAL_PTR) do
            local_add(NT_PTR, _curr_text, _pos + _org);
        end else ie(_curr = hclink.LNK_REF_START) do
            ref_value := 0;
            ref_size := 0;
            while(next()) do
                if(_curr = hclink.LNK_REF_EMIT) leave;
                ie(_curr = hclink.LNK_REF_WORD) do
                    ref_size := 2;
                    ref_value := ref_value + _curr_text[0];
                end else ie(_curr = hclink.LNK_REF_BYTE) do
                    ref_size := 1;
                    ref_value := ref_value + _curr_text[0];
                end else ie(_curr = hclink.LNK_REF_CURR_POS) do
                    ref_value := ref_value + _pos;
                end else if(_curr = hclink.LNK_REF_NAME) do
                    new_value := name_get(_curr_text);
                    if(new_value = %1) error1("Reference name not found: ", _curr_text);
                    ref_value := ref_value + _name_value_list[new_value];
                end 
            end
            ie(ref_size = 2) do
                emit_word(ref_value);
            end else ie(ref_size = 1) do
                emit_byte(ref_value);
            end else error("Unknown reference size");

        end else do
        end
    end
end

! STEP 3 - Compile Data
step3() do 
    var ref_value, ref_size, const_id, new_value;
    const_id := NAME_LIST_SIZE - 1;
    if(_sector = SEC_DATA) do
        ie(_curr = hclink.LNK_DATA) do
            emit(_curr_text, _curr_len);
        end else ie(_curr = hclink.LNK_CLEAR_LOCAL) do
            local_clear();
        end else ie(_curr = hclink.LNK_LOCAL_PTR) do
            local_add(NT_PTR, _curr_text, _pos + _org);
        end else ie(_curr = hclink.LNK_REF_START) do
            ref_value := 0;
            ref_size := 0;
            while(next()) do
                if(_curr = hclink.LNK_REF_EMIT) leave;
                ie(_curr = hclink.LNK_REF_WORD) do
                    ref_size := 2;
                    ref_value := ref_value + _curr_text[0];
                end else ie(_curr = hclink.LNK_REF_BYTE) do
                    ref_size := 1;
                    ref_value := ref_value + _curr_text[0];
                end else ie(_curr = hclink.LNK_REF_CURR_POS) do
                    ref_value := ref_value + _pos;
                end else if(_curr = hclink.LNK_REF_NAME) do
                    new_value := name_get(_curr_text);
                    if(new_value = %1) error("Reference name not found");
                    ref_value := ref_value + _name_value_list[new_value];
                end 
            end
            ie(ref_size = 2) do
                emit_word(ref_value);
            end else ie(ref_size = 1) do
                emit_byte(ref_value);
            end else error("Unknown reference size");

        end else do
        end
    end
end

step_library() do
    if(_curr \= hclink.LNK_END) do
        emit_tok(_curr, _curr_text, _curr_len);
        ie(_curr = hclink.LNK_MARKER_FILE) do
            ie(_in_count = 0) do
            end else do
                io.writeln("[ OK ]");
            end
            _in_count := _in_count + 1;
            io.writes(" - Add file ");
            io.writes(_curr_text);
        end else if(_curr = hclink.LNK_MARKER_LINE) do
            io.writes(".");
        end
    end
end

compile_file(filename) do
    _in := t.open(_in_name, T3X.OREAD);
    if(_in = -1) do
        error("File can't be opened");
    end
    _sector := SEC_NONE;
    next();
    while (next()) do
        ie(_library) do
            step_library();
        end else ie(_step = 0) do
            step0();
        end else ie(_step = 1) do
            step1();
        end else ie(_step = 2) do
            step2();
        end else ie(_step = 3) do
            step3();
        end else do
        end
    end
    t.close(_in);
end

compile_step(step) do
    var curr_in;
    curr_in := 3;
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
    io.writeln("Links HCLink Object Files to executable/library.");
    io.writeln("");
    io.writeln("Usage: ");
    io.writeln(" hclink [type] [outfile] [infile.ext...]");
    io.writeln("Accept as input files: .LIB / .OBJ");
    io.writeln("Output Types: ");
    io.writeln(" com = CP/M / MS-DOS / MSX-DOS com file");
    io.writeln("       ORG 0x0100");
    io.writeln(" bin = Flat executable");
    io.writeln("       ORG 0x0000");
    io.writeln(" pcbios = PC BIOS Boot Loader");
    io.writeln("       ORG 0x7C00");
    io.writeln(" msx = MSX Cartridge ROM");
    io.writeln("       ORG 0x4000");
    io.writeln(" =XXXX = Flat starting on XXXX addr.");
    io.writeln("         Hex. uppercase only");
    io.writeln(" lib = Create HCLink Library");
end

do
    var type::10, type_size, out_size, ext, name::NAME_LEN;
    io.writeln("HCLink Multiplatform Linker v0.8");
    io.writeln("(c)2023 by Humberto Costa dos Santos Jr");

    io.writeln("");
    
    name_clear_all();

    type_size := t.getarg(1, type, 10);
    out_size := t.getarg(2, _out_name, 10);

    _org := 0;
    _pos := 0;
    _library := 0;
    ext := ".bin";

    if(type_size <= 0)do
        show_help();
        halt 0;
    end

    ie(\string.comp("lib", type)) do
        _library := %1;
        ext := ".lib";
    end else ie(\string.comp("com", type) \/ \string.comp("COM", type)) do
        _org := 0x100;
        ext := ".com";
    end else ie(\string.comp("bin", type) \/ \string.comp("BIN", type)) do
        _org := 0;
    end else ie(\string.comp("pcbios", type) \/ \string.comp("PCBIOS", type)) do
        _org := 0x7c00;
    end else ie(\string.comp("msx", type) \/ \string.comp("MSX", type)) do
        _org := 0x4000;
        ext := ".rom";
    end else ie(type::0 = '=') do
        _org := string.aton(@type::1, 16, @type_size);
    end else do
        string.copy(_in_name, "");
        error("Output type not supported");
    end

    ie (out_size > 0) do
        t.memcopy(name, _out_name, out_size);
        t.memcopy(@name::out_size, ext, 4);
        _out := t.open(name, T3X.OWRITE);
        if(_out = -1) do
            error("Output file can't be opened");
        end
        io.writes(" - Binary origin: 0x");
        io.writeln(string.ntoa(_org, 16));
        ie(_library) do
            compile_step(99);
            emit_tok(hclink.LNK_END, 0,0);
        end else do
            compile_step(0);
            compile_step(1);
            if((_pos & 0xffff) .>= (0xffff - _org)) error("Binary size overflow");
            _pos := 0;
            compile_step(2);
            compile_step(3);
        end 
        t.close(_out);
        io.nl();

    end else do
        show_help();
        halt -1;
    end
end