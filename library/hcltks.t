module hclink;

public struct HCLINK_TOKENS = LNK_NONE, LNK_END,
    LNK_MARKER_FILE, LNK_MARKER_LINE, LNK_MARKER_COL,
    LNK_FUNC_START, LNK_FUNC_END, LNK_FUNC_FORCE_KEEP, LNK_FUNC_USE,
    LNK_CODE, LNK_DATA, 
    LNK_LOCAL_PTR, LNK_GLOBAL_PTR, LNK_PUBLIC_PTR, LNK_EXTERN,
    LNK_LOCAL_CONST_NAME, LNK_LOCAL_CONST_VALUE,
    LNK_GLOBAL_CONST_NAME, LNK_GLOBAL_CONST_VALUE,
    LNK_CLEAR_LOCAL,
    LNK_REF_START,
    LNK_REF_WORD, LNK_REF_BYTE, LNK_REF_NAME, LNK_REF_CURR_POS, LNK_REF_NEXT_POS,
    LNK_REF_EMIT;

! FUNCTION FORMAT (Recomendation)
! ===============
!
! LNK_FUNC_START(func_name) inform start of a function
! Optional LNK_FUNC_FORCE_KEEP(func_name) inform to keep in final executable always
! LNK_CODE()
! Optional LNK_PUBLIC_PTR(func_name)
! LNK_GLOBAL_PTR(func_name)
! LNK_CLEAR_LOCAL()
! LNK_LOCAL_PTR(func_name)
! LNK_CODE(initialization code of a function)
! ..... CONTENTS ......
! LNK_CODE(finalization and return code of a function)
! LNK_FUNC_END(func_name) inform start of a function

! POINTERS
! ========
!
! LNK_LOCAL_PTR(name) create pointer to current position on code (View only inside function)
! LNK_GLOBAL_PTR(name) create pointer to current position on code (View only inside file)
! LNK_PUBLIC_PTR(name) create pointer to current position on code (View by all files)
! LNK_EXTERN declare external reference
!
! CONSTANT FORMAT
! ===============
!
! LNK_LOCAL_CONST_NAME(name) define constant name
! LNK_LOCAL_CONST_VALUE(value) apply value to constant
!
! OR
!
! LNK_GLOBAL_CONST_NAME(name) define constant name
! LNK_GLOBAL_CONST_VALUE(value) apply value to constant

! REFERENCE FORMAT
! ================
!
! References is a sum, with numeric values and named values
! LNK_REF_START
! One or more LNK_REF_WORD(value) or LNK_REF_BYTE(value)
! One or more LNK_REF_NAME(name)
! LNK_REF_CURR_POS if positional reference (position of this byte/word)
! LNK_REF_NEXT_POS if positional reference (after of this byte/word)
! LNK_REF_EMIT finish calculations, and emit byte/word to file

end