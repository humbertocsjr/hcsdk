Humberto Costa Development Kit for MSX
======================================

B Language Compiler
-------------------

To compile a B Source Code:

Sample: test.b

HCB TEST
    Tokenize B Source Code
    In..: TEST.B
    Out.: TEST.BTK
HCBZ80 TEST
    Compile B Language Tokens
    In..: TEST.BTK
    Out.: TEST.OBJ
HCLIB TEST LIBB TEST
    Add called functions from library
    Out.: TEST.LIB
    Lib.: LIBB.LIB
    In..: TEST.OBJ
HCLINK COM TEST TEST.LIB
    Link project library to executable
    Type: COM File
    Out.: TEST.COM
    In..: TEST.LIB