
module hcasm;


const NAME_LEN = 80;
public const TOK_LEN = 80;
const LINE_LEN = 256;
const LINE_BUF_LEN = 400;
const BUF_LEN = 130;
const TOK_SIZE = 128;

struct INFO = INFO_LINE, INFO_COL;

var _segment;
var _can_auto;
var _var_pos;
var _in;
var _in_eof;
var _in_name::NAME_LEN;
var _in_name2::NAME_LEN;
var _in_name3::NAME_LEN;
var _in_filename::NAME_LEN;
var _in_buf::BUF_LEN;
var _in_buf2::BUF_LEN;
var _in_buf3::BUF_LEN;
var _in_count;
var _out;
var _out_name::NAME_LEN;
var _curr;
var _curr_line;
var _curr_col;
var _curr_len;
var _curr_text::TOK_LEN;
var _curr_text_up::TOK_LEN;
var _prev;
var _prev_line;
var _prev_col;
var _prev_len;
var _prev_text::TOK_LEN;
var _prev_text_up::TOK_LEN;
var _next;
var _next_line;
var _next_col;
var _next_len;
var _next_text::TOK_LEN;
var _next_text_up::TOK_LEN;
var _line::LINE_LEN;
var _line_len;
var _info[INFO];
var _tok_curr;
var _tok_buf::LINE_BUF_LEN;
var _tok[TOK_SIZE];
var _tok_start[TOK_SIZE];
var _tok_col[TOK_SIZE];
var _tok_len[TOK_SIZE];

public segment() return _segment;

public error(msg) do 
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

match(type, errmsg) do
    if(type \= _curr) do
        error(errmsg);
    end
end


match_eol() do
    match(tokens.TK_END_COMMAND, "';' expected");
end


token_get(i, buf, len) do
    var j;
    if (i >= tokens.TK_NONE /\ i < 0) return tokens.TK_NONE;
    j := 0;
    for(j = 0, len) do
        if((j+1) >= TOK_LEN) do
            error("Token overflow");
        end
        buf::j := _line::(_info[INFO_COL]);
        buf::(j +1 ) := 0;
        _info[INFO_COL] := _info[INFO_COL] + 1;
    end

    return _tok[i];
end

read_line() do
    var tmp;
    _line_len := 0;
    if(_in_eof) return %1;
    _line::_line_len := 0;
    for(_line_len = 0, LINE_LEN - 1) do
        if((_in_buf::0 >= _in_buf::1)) do
            _in_buf::0 := 255;
            _in_buf::1 := 0;
            tmp := t.read(_in, @_in_buf::2, 128);
            if(tmp = %1) return %1;
            if(tmp = 0) do
                _in_eof := %1;
                return _line_len;
            end
            _in_buf::1 := tmp+2;
            _in_buf::0 := 2;
        end
        if(_in_buf::_in_buf::0 = '\n') do
            _in_buf::0 := _in_buf::0 + 1;
            leave;
        end
        if(_in_buf::_in_buf::0 \= '\r') do
            _line::_line_len := _in_buf::_in_buf::0;
            _line::(_line_len + 1) := 0;
        end
        _in_buf::0 := _in_buf::0 + 1;
    end
    return _line_len;
end

tokenize() do
    var i, c, n, u, pos, str_tmp::2, j;
    t.memfill(_tok_buf, 0, LINE_BUF_LEN);
    pos := 1;
    _tok_curr := 0;
    for(i = 0, TOK_SIZE) do
        _tok[i] := tokens.TK_NONE;
        _tok_start[i] := 0;
        _tok_len[i] := 0;
    end
    for(i = 0, _line_len+1) do
        _info[INFO_COL] := i + 1;
        c := _line::i;
        n := _line::(i+1);
        u := char.ucase(c);
        if(c = 0) leave;
        ie(_tok[_tok_curr] = tokens.TK_NONE) do
            _tok_start[_tok_curr] := 0;
            _tok_col[_tok_curr] := i;
            ie(char.alpha(c) \/ c = '_' \/ c = '.') do
                _tok[_tok_curr] := tokens.TK_ID;
                _tok_start[_tok_curr] := pos;
                _tok_buf::pos := c;
            end else ie(char.digit(c)) do
                _tok[_tok_curr] := tokens.TK_NUM;
                _tok_start[_tok_curr] := pos;
                _tok_buf::pos := c;
            end else ie(c = '"') do
                _tok[_tok_curr] := tokens.TK_STR;
                _tok_start[_tok_curr] := pos+1;
                _tok_buf::pos := c;
            end else ie(c = 39) do
                _tok[_tok_curr] := tokens.TK_NUM;
                _tok_start[_tok_curr] := pos;
                _tok_buf::pos := ((n / 100) mod 10) + '0';
                pos := pos + 1;
                _tok_buf::pos := ((n / 10) mod 10) + '0';
                pos := pos + 1;
                _tok_buf::pos := ((n) mod 10) + '0';
                pos := pos + 1;
                _tok_buf::pos := 0;
                i := i + 2;
            end else ie(char.space(c)) do
            end else ie(c = ',') do
                _tok[_tok_curr] := tokens.TK_COMMA;
                _tok_curr := _tok_curr + 1;
            end else ie(c = ';') do
                _tok[_tok_curr] := tokens.TK_END_COMMAND;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '(') do
                _tok[_tok_curr] := tokens.TK_PARAM_OPEN;
                _tok_curr := _tok_curr + 1;
            end else ie(c = ')') do
                _tok[_tok_curr] := tokens.TK_PARAM_CLOSE;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '{') do
                _tok[_tok_curr] := tokens.TK_BLOCK_OPEN;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '}') do
                _tok[_tok_curr] := tokens.TK_BLOCK_CLOSE;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '<') do
                _tok[_tok_curr] := tokens.TK_CMP_LESSER;
            end else ie(c = '>') do
                _tok[_tok_curr] := tokens.TK_CMP_GREATER;
            end else ie(c = '=') do
                _tok[_tok_curr] := tokens.TK_ATRIB;
            end else ie(c = '&') do
                _tok[_tok_curr] := tokens.TK_BIT_AND;
            end else ie(c = '|') do
                _tok[_tok_curr] := tokens.TK_BIT_OR;
            end else ie(c = '^') do
                _tok[_tok_curr] := tokens.TK_BIT_XOR;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '+') do
                _tok[_tok_curr] := tokens.TK_MATH_SUM;
            end else ie(c = '-') do
                _tok[_tok_curr] := tokens.TK_MATH_SUBTRACT;
            end else ie(c = '/') do
                _tok[_tok_curr] := tokens.TK_MATH_DIVIDE;
            end else ie(c = '*') do
                _tok[_tok_curr] := tokens.TK_MATH_MULTIPLY;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '%') do
                _tok[_tok_curr] := tokens.TK_MATH_MODULE;
                _tok_curr := _tok_curr + 1;
            end else ie(c = '!') do
                _tok[_tok_curr] := tokens.TK_BIT_NOT;
            end else do
                io.writes("Char code: ");
                io.writeln(string.ntoa(c, 10));
                io.writes("Char.....: ");
                str_tmp::0 := c;
                str_tmp::1 := 0;
                io.writeln(str_tmp);
                error("Char unknown");
            end
        end else ie(_tok[_tok_curr] = tokens.TK_STR) do
            ie(c = '\\' /\ n = '"') do
                _tok_buf::pos := '"';
                pos := pos + 1;
            end else ie(c \= '"') do
                _tok_buf::pos := c;
            end else do
                _tok_curr := _tok_curr + 1;
            end
        end else ie(_tok[_tok_curr] = tokens.TK_NUM) do
            ie(char.digit(c)) do
                _tok_buf::pos := c;
            end else do
                i := i - 1;
                _tok_curr := _tok_curr + 1;
            end
        end else ie(_tok[_tok_curr] = tokens.TK_ID) do
            ie(char.alpha(c) \/ c = '_' \/ c = '.') do
                _tok_buf::pos := c;
            end else do
                i := i - 1;
                _tok_curr := _tok_curr + 1;
            end
        end else ie(_tok[_tok_curr] = tokens.TK_CMP_LESSER) do
            ie(c = '=') do
                _tok[_tok_curr] := tokens.TK_CMP_LESSER_EQUAL;
            end else ie(c = '<') do
                _tok[_tok_curr] := tokens.TK_BIT_SHL;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else ie(_tok[_tok_curr] = tokens.TK_ATRIB) do
            ie(c = '=') do
                _tok[_tok_curr] := tokens.TK_CMP_EQUAL;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else ie(_tok[_tok_curr] = tokens.TK_BIT_AND) do
            ie(c = '&') do
                _tok[_tok_curr] := tokens.TK_CMP_AND;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else ie(_tok[_tok_curr] = tokens.TK_BIT_OR) do
            ie(c = '&') do
                _tok[_tok_curr] := tokens.TK_CMP_OR;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else ie(_tok[_tok_curr] = tokens.TK_MATH_SUM) do
            ie(c = '+') do
                _tok[_tok_curr] := tokens.TK_MATH_INC;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else ie(_tok[_tok_curr] = tokens.TK_MATH_SUBTRACT) do
            ie(c = '-') do
                _tok[_tok_curr] := tokens.TK_MATH_DEC;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else ie(_tok[_tok_curr] = tokens.TK_MATH_DIVIDE) do
            ie(c = '/') do
                _tok[_tok_curr] := tokens.TK_COMMENT_INLINE;
                _tok_start[_tok_curr] := pos + 1;
                _tok_buf::pos := c;
            end else do
                i := i - 1;
                _tok_curr := _tok_curr + 1;
            end
        end else ie(_tok[_tok_curr] = tokens.TK_COMMENT_INLINE) do
            _tok_buf::pos := c;
        end else ie(_tok[_tok_curr] = tokens.TK_BIT_NOT) do
            ie(c = '=') do
                _tok[_tok_curr] := tokens.TK_CMP_NOT_EQUAL;
            end else do
                i := i - 1;
            end
            _tok_curr := _tok_curr + 1;
        end else do
            error("Token type not implemented");
        end
        pos := pos + 1;
        _tok_buf::pos := 0;
    end
    for(i = 0, TOK_SIZE) do
        if(_tok[i] \= tokens.TK_NONE) do
            _tok_len[i] := string.length(@_tok_buf::_tok_start[i]);
        end
    end
end

emit(type, buf, len) do
    t.write(_out, @type, 2);
    t.write(_out, @len, 2);
    if(len \= 0) do
        t.write(_out, buf, len);
    end
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
    t.memcopy(_prev_text_up, _curr_text_up, TOK_LEN);
    _curr := _next;
    _curr_col := _next_col;
    _curr_line := _next_line;
    _curr_len := _next_len;
    t.memcopy(_curr_text, _next_text, TOK_LEN);
    t.memcopy(_curr_text_up, _next_text_up, TOK_LEN);
    if(_next = tokens.TK_END) return 0;
    _next := _tok[_tok_curr];
    _next_col := _tok_col[_tok_curr];
    _next_line := _info[INFO_LINE];
    _next_len := _tok_len[_tok_curr];
    t.memfill(_next_text, 0, TOK_LEN);
    t.memcopy(_next_text, @_tok_buf::_tok_start[_tok_curr], _next_len);
    t.memcopy(_next_text_up, _next_text, TOK_LEN);
    string.upcase(_next_text_up);
    _tok_curr := _tok_curr + 1;
    if(_next = tokens.TK_NONE) _next := tokens.TK_END;
    return %1;
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
    emit_tok_hex(_segment, hex);
end

do_aton(str, len) do
    return string.aton(str, 10, @len);
end

do_expr(p, ptxt, mem) do
    var reg, value;
    ie(_curr = tokens.TK_ID) do
        reg := parse_reg(_curr_text_up);
        ie(reg \= REG_NONE) do
            p[PARAM_REG] := reg;
            ie(mem) 
                p[PARAM_TYPE] := ARG_PTR_REG;
            else
                p[PARAM_TYPE] := ARG_REG;
        end else do
            ie(mem) 
                p[PARAM_TYPE] := ARG_PTR_VALUE;
            else
                p[PARAM_TYPE] := ARG_VALUE;
            t.memcopy(ptxt, _curr_text, TOK_LEN);
            p[PARAM_LABEL] := ptxt;
        end
    end else ie(_curr = tokens.TK_NUM) do
        ie(mem) 
            p[PARAM_TYPE] := ARG_PTR_VALUE;
        else
            p[PARAM_TYPE] := ARG_VALUE;
        value := do_aton(_curr_text, _curr_len);
        p[PARAM_VALUE] := p[PARAM_VALUE] + value;
    end else error("Token not supported (0)");
    while(_next = tokens.TK_MATH_SUM \/ _next = tokens.TK_MATH_SUBTRACT) do
        if(p[PARAM_TYPE] = ARG_PTR_REG) 
            p[PARAM_TYPE] := ARG_PTR_REG_AND_VALUE;
        ie(_next = tokens.TK_MATH_SUM) do
            next();
            next();
            ie(_curr = tokens.TK_NUM) do
                value := do_aton(_curr_text, _curr_len);
                p[PARAM_VALUE] := p[PARAM_VALUE] + value;
            end else ie(_curr = tokens.TK_ID) do
                if(p[PARAM_LABEL] \= 0) error("Only support one label by parameter");
                t.memcopy(ptxt, _curr_text, TOK_LEN);
                p[PARAM_LABEL] := ptxt;
            end else error("Token not supported (1)");
        end else do
            next();
            next();
            ie(_curr = tokens.TK_NUM) do
                value := do_aton(_curr_text, _curr_len);
                p[PARAM_VALUE] := p[PARAM_VALUE] - value;
            end else error("Token not supported (2)");
        end
    end
end

do_param(p, ptxt) do
    p[PARAM_REG] := REG_NONE;
    p[PARAM_LABEL] := 0;
    p[PARAM_TYPE] := ARG_NONE;
    p[PARAM_VALUE] := 0;
    emit_tok(hclink.LNK_MARKER_COL, @_curr_col, 2);
    ie(_curr = tokens.TK_PARAM_OPEN) do
        next();
        do_expr(p, ptxt, %1);
        next();
        match(tokens.TK_PARAM_CLOSE, "')' expected");
    end else do_expr(p, ptxt, 0);
end

var _parama_text::TOK_LEN;
var _paramb_text::TOK_LEN;
var _paramc_text::TOK_LEN;
var _parama[PARAM_LIST];
var _paramb[PARAM_LIST];
var _paramc[PARAM_LIST];

compile() do
    var exists, params, i, cmd::TOK_LEN, cmd_len;
    emit_tok(hclink.LNK_MARKER_COL, @_curr_col, 2);
    
    params := 0;
    ie(_curr = tokens.TK_ID) do
        i := 0;
        t.memcopy(cmd, _curr_text_up, TOK_LEN);
        cmd_len := _curr_len;

        ie(\string.comp(cmd, "PROC")) do
            next();
            emit_tok(hclink.LNK_FUNC_START, _curr_text, _curr_len);
            emit_tok(hclink.LNK_GLOBAL_PTR, _curr_text, _curr_len);
            emit_tok(hclink.LNK_CLEAR_LOCAL, _curr_text, _curr_len);
            emit_tok(hclink.LNK_LOCAL_PTR, _curr_text, _curr_len);
            return;
        end else ie(\string.comp(cmd, "PUBLIC")) do
            next();
            emit_tok(hclink.LNK_PUBLIC_PTR, _curr_text, _curr_len);
            return;
        end else ie(\string.comp(cmd, "ENDPROC")) do
            next();
            emit_tok(hclink.LNK_FUNC_END, _curr_text, _curr_len);
            return;
        end else ie(\string.comp(cmd, "USEPROC")) do
            next();
            emit_tok(hclink.LNK_FUNC_USE, _curr_text, _curr_len);
            return;
        end else ie(\string.comp(cmd, ".CODE")) do
            next();
            emit_tok(hclink.LNK_CODE, 0, 0);
            _segment := hclink.LNK_CODE;
            return;
        end else ie(\string.comp(cmd, ".DATA")) do
            next();
            emit_tok(hclink.LNK_DATA, 0, 0);
            _segment := hclink.LNK_DATA;
            return;
        end else do
        end

        i := 0;
        exists := 0;
        while(_instrs[i][INSTR_GEN] \= 0) do
            if(\string.comp(_instrs[i][INSTR_CMD], cmd)) do
                if(_instrs[i][INSTR_ARGS] = 0) do
                    gen0(_instrs[i][INSTR_GEN], _instrs[i]);
                    return;
                end
                exists := %1;
            end
            i := i + 1;
        end


        
        if(exists = 0) do
            next();
            ie(_curr = tokens.TK_ID /\ \string.comp("EQU", _curr_text_up)) do
                error("EQU not implemented");
            end else do
                emit_tok(hclink.LNK_GLOBAL_PTR, _prev_text, _prev_len);
            end
            return;
        end

        if(next()) do

            do_param(_parama, _parama_text);
            params := 1;

            i := 0;
            while(_instrs[i][INSTR_GEN] \= 0) do
                if(\string.comp(_instrs[i][INSTR_CMD], cmd)) do
                    if
                    (
                        _instrs[i][INSTR_ARGS] = params /\
                        _instrs[i][INSTR_ARGA_TYPE] = _parama[PARAM_TYPE]
                    ) do
                        gen1(_instrs[i][INSTR_GEN], _instrs[i], _parama);
                        return;
                    end
                end
                i := i + 1;
            end

            if(next()) do
                match(tokens.TK_COMMA, "',' expected.");
                next();

                do_param(_paramb, _paramb_text);
                params := 2;

                i := 0;
                while(_instrs[i][INSTR_GEN] \= 0) do
                    if(\string.comp(_instrs[i][INSTR_CMD], cmd)) do
                        if(_instrs[i][INSTR_ARGS] = params) do
                            if
                            (
                                _instrs[i][INSTR_ARGA_TYPE] = _parama[PARAM_TYPE] /\
                                _instrs[i][INSTR_ARGB_TYPE] = _paramb[PARAM_TYPE]
                            ) do
                                gen2(_instrs[i][INSTR_GEN], _instrs[i], _parama, _paramb);
                                return;
                            end
                        end
                    end
                    i := i + 1;
                end

                if(next()) do
                    match(tokens.TK_COMMA, "',' expected.");
                    next();

                    do_param(_paramc, _paramc_text);
                    params := 3;

                    i := 0;
                    while(_instrs[i][INSTR_GEN] \= 0) do
                        if(\string.comp(_instrs[i][INSTR_CMD], cmd)) do
                            if(_instrs[i][INSTR_ARGS] = params) do
                                if
                                (
                                    _instrs[i][INSTR_ARGA_TYPE] = _parama[PARAM_TYPE] /\
                                    _instrs[i][INSTR_ARGB_TYPE] = _paramb[PARAM_TYPE] /\
                                    _instrs[i][INSTR_ARGC_TYPE] = _paramc[PARAM_TYPE]
                                ) do
                                    gen3(_instrs[i][INSTR_GEN], _instrs[i], _parama, _paramb, _paramc);
                                    return;
                                end
                            end
                        end
                        i := i + 1;
                    end
                end

            end
        end

    end else do
        error("Command expected");
    end
    error("Parameters incompatible with command");
end

compile_line() do
    var i;
    _tok_curr := 0;
    _curr := tokens.TK_COMMENT_INLINE;
    _next := tokens.TK_COMMENT_INLINE;
    next();
    while(next()) do
        compile();
    end
end

compile_file(filename) do
    var old_in;
    var old_in_eof;
    var old_info[INFO];
    var count;
    old_in := _in;
    old_in_eof := _in_eof;
    t.memcopy(old_info, _info, INFO);
    t.memcopy(_in_buf3, _in_buf2, BUF_LEN);
    t.memcopy(_in_buf2, _in_buf, BUF_LEN);
    t.memcopy(_in_name3, _in_name2, NAME_LEN);
    t.memcopy(_in_name2, _in_name, NAME_LEN);
    t.memcopy(_in_name, filename, NAME_LEN);
    _in := t.open(_in_name, T3X.OREAD);
    if(_in = %1) do
        error("File can't be opened");
    end
    io.writes(" - Assembling ");
    io.writes(_in_name);
    emit(hclink.LNK_MARKER_FILE, _in_name, string.length(_in_name));
    _in_eof := 0;
    _in_buf::0 := 255;
    _in_buf::1 := 0;
    _line::0 := 0;
    _info[INFO_LINE] := 1;
    _info[INFO_COL] := 0;
    _in_count := _in_count + 1;
    _segment := hclink.LNK_CODE;
    count := 0;

    while (read_line() >= 0) do
        emit(hclink.LNK_MARKER_LINE, @_info[INFO_LINE], 2);
        tokenize();
        compile_line();
        count := count + 1;
        _info[INFO_LINE] := _info[INFO_LINE] + 1;
        io.writes(".");
    end
    io.writeln("[ OK ]");
    if(count = 0) error("Empty file");

    t.close(_in);
    _in := old_in;
    _in_eof := old_in_eof;
    t.memcopy(_info, old_info, INFO);
    t.memcopy(_in_buf, _in_buf2, BUF_LEN);
    t.memcopy(_in_buf2, _in_buf3, BUF_LEN);
    t.memcopy(_in_name, _in_name2, NAME_LEN);
    t.memcopy(_in_name2, _in_name3, NAME_LEN);
end


show_help(arch_file) do
    io.writeln("Assembles Machine Instructions to HCLink Object File");
    io.writeln("");
    io.writeln("Usage: ");
    io.writes(" ");
    io.writes(arch_file);
    io.writeln(" [infile.asm] [outfile.obj]");
end

public main(arch_name, arch_file) do
    var in_size, out_size;
    io.writes("HC Assembler for ");
    io.writes(arch_name);
    io.writeln(" v0.1");
    io.writeln("(c)2023 by Humberto Costa dos Santos Jr");

    io.writeln("");
    
    in_size := t.getarg(1, _in_name, NAME_LEN);
    out_size := t.getarg(2, _out_name, NAME_LEN);

    _curr := 0;
    _prev := 0;
    _next := 0;
    _next_col := 0;
    _next_line := 0;
    _in_count := 0;

    ie (in_size > 0) do
        if (out_size < 1) do
			out_size := in_size;
			t.memcopy(_out_name, _in_name, in_size+1);
			t.memcopy(@_in_name::in_size, ".asm", 5);
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
        io.nl();

    end else do
        show_help(arch_file);
        halt -1;
    end
end

end
