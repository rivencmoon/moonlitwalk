/****************************************************************************************
 *                                                                                      *
 *  ----------------------------------------------------------------------------------  *
 *  |    0    |    1    |    2    |    3    |    4     |    5    |    6    |    7    |  *
 *  ----------------------------------------------------------------------------------  *
 *  |   0x0   |   0x4   |   0x8   |   0xc   |   0x10   |   0x14  |   0x18  |   0x1c  |  *
 *  ----------------------------------------------------------------------------------  *
 *  | fc_mxcsr|fc_x87_cw|   EDI   |   ESI   |   EBX    |   EBP   |   EIP   |   EXIT  |  *
 *  ----------------------------------------------------------------------------------  *
 *                                                                                      *
 ****************************************************************************************/

.file "make_i386_sysv_macho_gas.S"
.text
.globl sew_make_context
.align 2

sew_make_context:
    /* first arg of sew_make_context() == top of context-stack */
    movl    0x4(%esp), %eax

    /* reserve space for first arg of context-function
     * rax might already point to a 16 byte botder */
    leal    -0x8(%eax), %eax

    /* shift address in EAX to lower 16 byte boundary */
    andl    $-16, %eax

    /* reserve space for context-data on context-stack 
     * size for fc_mxcsr .. EIP + return-address for context-function 
     * on context-function entry: (ESP -0x4) % 8 == 0 */
    leal    -0x20(%eax), %eax

    /* third arg of sew_make_context() == address of context-function */
    movl    0xc(%esp), %edx
    movl    %edx, 0x18(%eax)

    /* save MMX control-word and status-word */
    stmxcsr (%eax)

    /* save x87 control-word */
    fnstcw  0x4(%eax)

    /* label 1, to compute abs address of label finish */
    call    1f

    /* address of label 1 */
1:  popl    %ecx

    /* compute abs address of label finish */
    addl    $finish-1b, %ecx

    /* save address of finish as return-address for context-function
     * will be entered after context-function returns */
    movl    %ecx, 0x1c(%eax)

    /* return pointer to context-data */
    ret

finish:
    /* exit code is zero */
    xorl    %eax, %eax
    movl    %eax, (%esp)

    /* exit application */
    call    _exit@PLT
    hlt
