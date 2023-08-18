! Referencia https://www.bell-labs.com/usr/dmr/www/kbman.html
use t3x: t;
use string;
use io;
use char;
use hcbtks;

const NAME_LEN = 80;
const TOK_LEN = 80;
const LINE_LEN = 256;
const TOK_SIZE = 128;
const LINE_BUF_LEN = 400;
const BUF_LEN = 130;
struct INFO = INFO_LINE, INFO_COL;


var _ids;

var _in;
var _in_eof;
var _in_name::NAME_LEN;
var _in_name2::NAME_LEN;
var _in_name3::NAME_LEN;
var _in_buf::BUF_LEN;
var _in_buf2::BUF_LEN;
var _in_buf3::BUF_LEN;
var _out;
var _out_name::NAME_LEN;
var _line::LINE_LEN;
var _line_len;
var _info[INFO];
var _tok_curr;
var _tok_buf::LINE_BUF_LEN;
var _tok[TOK_SIZE];
var _tok_start[TOK_SIZE];
var _tok_col[TOK_SIZE];
var _tok_len[TOK_SIZE];

error(msg) do 
    io.writes(_in_name);
    io.writes(":");
    io.writes(string.ntoa(_info[INFO_LINE], 10));
    io.writes(":");
    io.writes(string.ntoa(_info[INFO_COL], 10));
    io.writes(": Error: ");
    io.writeln(msg);
    io.writes("Source: ");
    io.writeln(_line);
    halt 1;
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
    _tok_buf::0 := 0;
    pos := 1;
    _tok_curr := 0;
    for(i = 0, TOK_SIZE) do
        _tok[i] := tokens.TK_NONE;
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
            ie(char.alpha(c) \/ c = '_') do
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
            ie(char.alpha(c) \/ c = '_') do
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
    ! Localize ID in IDs dictionary
    for(i = 0, TOK_SIZE) do
        if(_tok[i] = tokens.TK_ID) do
            j := 0;
            while (_ids[j][0] > 0) do
                if(string.comp(_ids[j][1], @_tok_buf::_tok_start[i]) = 0)do
                    _tok[i] := _ids[j][0];
                    _tok_start[i] := 0;
                end
                j := j + 1;
            end
        end
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

compile_line() do
    var i;
    var col;
    col := 0;
    for(i = 0, TOK_SIZE) do
        if(_tok[i] = tokens.TK_NONE) leave;
        if(col \= _tok_col[i]) emit(tokens.TK_MARKER_LINE, @_tok_col[i], 2);
        emit(_tok[i], @_tok_buf::_tok_start[i], _tok_len[i]);
        col := _tok_col[i];
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
    io.writes(" - Tokenizing ");
    io.writes(_in_name);
    emit(tokens.TK_MARKER_FILE, _in_name, string.length(_in_name));
    _in_eof := 0;
    _in_buf::0 := 255;
    _in_buf::1 := 0;
    _line::0 := 0;
    _info[INFO_LINE] := 1;
    _info[INFO_COL] := 0;
    count := 0;

    while (read_line() >= 0) do
        emit(tokens.TK_MARKER_LINE, @_info[INFO_LINE], 2);
        tokenize();
        compile_line();
        count := count + 1;
        _info[INFO_LINE] := _info[INFO_LINE] + 1;
        io.writes(".");
    end
    io.writeln("[ OK ]");
    if(count = 0) error("File empty");

    t.close(_in);
    _in := old_in;
    _in_eof := old_in_eof;
    t.memcopy(_info, old_info, INFO);
    t.memcopy(_in_buf, _in_buf2, BUF_LEN);
    t.memcopy(_in_buf2, _in_buf3, BUF_LEN);
    t.memcopy(_in_name, _in_name2, NAME_LEN);
    t.memcopy(_in_name2, _in_name3, NAME_LEN);
end


show_help() do
    io.writeln("Reads B Source Code and generate B Language Tokens.");
    io.writeln("");
    io.writeln("Usage: ");
    io.writeln(" hcb [infile.b] [outfile.btk]");
end

do
    var in_size, out_size;
    io.writeln("HC B Language Parser v0.6");
    io.writeln("(c)2023 by Humberto Costa dos Santos Jr");

    io.writeln("");

    _ids := 
    [
        [tokens.TK_ID_WHILE, "while"],
        [tokens.TK_ID_IF, "if"],
        [tokens.TK_ID_ELSE, "else"],
        [tokens.TK_ID_AUTO, "auto"],
        [tokens.TK_ID_REPEAT, "repeat"],
        [tokens.TK_ID_EXTRN, "extrn"],
        [tokens.TK_ID_RETURN, "return"],
        [0,0]
    ];
    
    in_size := t.getarg(1, _in_name, NAME_LEN);
    out_size := t.getarg(2, _out_name, NAME_LEN);

    ie (in_size > 0) do
        if (out_size < 1) do
			out_size := in_size;
			t.memcopy(_out_name, _in_name, in_size+1);
			t.memcopy(@_in_name::in_size, ".b", 5);
			t.memcopy(@_out_name::out_size, ".btk", 5);
        end
        _out := t.open(_out_name, T3X.OWRITE);
        if(_out = -1) do
            error("File can't be opened");
        end
        compile_file(_in_name);
        emit(tokens.TK_END, 0, 0);
        t.close(_out);

        io.nl();
    end else do
        show_help();
        halt -1;
    end

end
