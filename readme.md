# Humberto Costa Development Kit

This kit contains:

- B Language Compiler
    - HCB - HC B Language Parser
        Reads B Source Code and generates B Language Tokens.
    - HCBZ80 - HC B Language Compiler for Z80
        Compiles B Language Tokens to Z80 HCLink Object File.
- Assembler
- Linker
    - HCEXE - HCLink Executable Generator
        Embeds HCLink Objects, filters unused functions and generates executable object in HCLink Library format.
    - HCLINK - HCLink Multiplatform Linker
        Links HCLink Object/Library Files to executable/library.

Supported Targets:

- Z80
    - CP/M
    - MSX-DOS

Supported Host:

- Linux
- CP/M
- MS-DOS