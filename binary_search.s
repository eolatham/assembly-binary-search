/*
Author: Eric Latham
Email: ericoliverlatham@gmail.com
To compile: gcc -Wall -no-pie -o binary_search binary_search.s
To run: ./binary_search
*/

.data
.temp: .space 16                   # allocate memory for temporary scanf number variable
.array: .quad 1, 2, 3, 4, 5        # allocate memory for array of 5 numbers
.search_elem: .quad 1              # allocate memory for search element
.array_prompt: .string "Build a sorted array...\n"
.search_prompt: .string "\nSpecify an element to search for in the array...\n"
.search_result: .string "\nResult of Binary Search for %i: %i\n"
.scan: .string "Enter an integer: "
.format: .string "%d"              # format string for scanning and printing integers

.text
.global main

main:
    movq $.array_prompt, %rdi
    call print
    movq $.array, %rdi
    movq $5, %rsi                  # set array length to be 5
    call take_input                # create array from user input

    movq $.search_prompt, %rdi
    call print
    movq $.search_elem, %rdi
    movq $1, %rsi
    call take_input                # get search element from user input

    movq $.array, %rdi
    movq $0, %rsi
    movq $4, %rdx
    movq .search_elem, %rcx
    call binary_search             # search for the element using binary search

    movq $.search_result, %rdi
    movq .search_elem, %rsi
    movq %rax, %rdx
    call print                     # print the result of search

    ret

/*
Read %rsi integers from stdin and assign them
to array addresses starting with %rdi.

%rdi: array pointer
%rsi: array length
*/
take_input:
    movq %rdi, %rbx                # %rbx = destination pointer
    movq %rsi, %rcx                # %rcx = number of iterations
    movq $0, %r10                  # %r10 = i
    jmp .input_loop
.input_loop:
    cmpq %r10, %rcx
    jg .inside_input_loop
    ret
.inside_input_loop:
    movq $.scan, %rdi
    call print
    call scan_int
    movq %rax, (%rbx, %r10, 8)     # insert scanned value into destination
    inc %r10
    jmp .input_loop

/*
Search for %rcx in the sorted array pointed to by %rdi.
Return the index of the element if it exists or -1 if it doesn't.

%rdi: array pointer
%rsi: lo index
%rdx: hi index
%rcx: search element
*/
binary_search:
    cmpq %rsi, %rdx                # is hi > lo?
    jge .binary_search
    movq $-1, %rax
    ret
.binary_search:
    movq %rdx, %rax                # %rax = hi
    subq %rsi, %rax                # %rax = hi - lo
    shr $1, %rax                   # %rax = %rax // 2
    addq %rsi, %rax                # %rax = %rax + lo = mid
    movq (%rdi, %rax, 8), %r10     # %r10 = array[mid]
    cmpq %rcx, %r10                # compare search element with array[mid]
    je .case1                      # array[mid] == search element
    jg .case2                      # array[mid] > search element
    jl .case3                      # array[mid] < search element
.case1:
    ret
.case2:
    leaq -1(%rax), %rdx            # hi = mid - 1
    jmp binary_search              # continue searching in lower half
.case3:
    leaq 1(%rax), %rsi             # lo = mid + 1
    jmp binary_search              # continue searching in upper half

/*
Use printf to safely print the format string pointed to by %rdi to stdout.
Push and pop registers to preserve their values,
as printf has unwanted side-effects.

%rdi: format string
%rsi: variable
...
*/
print:
    push %rax
    push %rbx
    push %rcx
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    xorq %rax, %rax
    call printf
    pop %r14
    pop %r13
    pop %r12
    pop %r11
    pop %r10
    pop %rcx
    pop %rbx
    pop %rax
    ret

/*
To clear the stdin input buffer after a failed scanf call, read input
from stdin until '\n' or EOF are reached, returning control to caller
if '\n' is reached and exiting the program if EOF is reached.
*/
clear_input_buffer:
.read_loop:
    call getchar                   # %eax = char (4-byte int)
    cmp $10, %eax                  # see if %eax == '\n'
    je .newline_case               # jump to .newline_case if %eax == '\n'
    test %eax, %eax                # set flags according to %eax
    js .eof_case                   # jump to .eof_case if %eax is negative
    jmp .read_loop                 # continue loop
.newline_case:
    ret
.eof_case:
    movq $0, %rdi
    call exit                      # exit(0)

/*
Use scanf to safely scan for an integer value from stdin, passing .format
as the format string and .temp for temporary destination storage.
Push and pop registers to preserve their values and use
a stack canary for added system compatibility.
*/
scan_int:
    push %rbx
    push %rcx
    push %r10
    subq $64, %rsp                 # stack canary
	movq $.format, %rdi            # set param 1: format string
	leaq .temp(%rip), %rsi         # set param 2: scan destination
    xorq %rax, %rax                # empty %rax
	call __isoc99_scanf@PLT        # call scanf
    addq $64, %rsp                 # reset stack canary
    cmpq $1, %rax                  # see if scanf succeeded
    je .success                    # jump to .success if scanf succeeded
    jmp .default                   # jump to .default if scanf failed
.success:
    movq .temp(%rip), %rax         # return scanned value
    jmp .return
.default:
    call clear_input_buffer        # clear input buffer for next scanf call
    movq $0, %rax                  # return default value
    jmp .return
.return:
    pop %r10
    pop %rcx
    pop %rbx
    ret
