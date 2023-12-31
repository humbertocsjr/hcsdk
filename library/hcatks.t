module tokens;

public struct TOKENS_LIST = TK_NONE, TK_END,
    TK_MARKER_FILE, TK_MARKER_LINE, TK_MARKER_COL,
    TK_ID, TK_NUM, TK_NUM_HEX, TK_STR, TK_CHAR, TK_PARAM_OPEN, TK_PARAM_CLOSE,
    TK_BLOCK_OPEN, TK_BLOCK_CLOSE, 
    TK_MATH_SUM, TK_MATH_SUBTRACT, TK_MATH_MULTIPLY, TK_MATH_DIVIDE, TK_MATH_MODULE, 
    TK_MATH_INC, TK_MATH_DEC,
    TK_CMP_LESSER, TK_CMP_LESSER_EQUAL, TK_CMP_GREATER, TK_CMP_GREATER_EQUAL,
    TK_CMP_AND, TK_CMP_OR, TK_CMP_EQUAL, TK_CMP_NOT_EQUAL,
    TK_ATRIB,
    TK_COMMENT_INLINE,
    TK_COMMA, TK_END_COMMAND, 
    TK_BIT_SHL, TK_BIT_SHR, TK_BIT_AND, TK_BIT_OR, TK_BIT_XOR, TK_BIT_NOT;

end