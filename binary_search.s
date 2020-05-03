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
    movq $.array_prompt,  %rdi     # string to print = .array_prompt
    call print                     # print .array_prompt
    movq $.array, %rdi             # array pointer parameter = .array
    movq $5, %rsi                  # array length parameter = 5
    call take_input                # .array = array created with user input

    movq $.search_prompt, %rdi     # string to print = .search_prompt
    call print                     # print .search_prompt
    movq $.search_elem,   %rdi     # array pointer parameter = .search_elem
    movq $1,              %rsi     # array length parameter = 1
    call take_input                # .search_elem = search element from user input

    movq $.array,         %rdi     # array pointer parameter = .array
    movq $0,              %rsi     # lo index parameter = 0
    movq $4,              %rdx     # hi index parameter = 4
    movq .search_elem,    %rcx     # search element parameter = .search_elem
    call binary_search             # %rax = result of binary search for .search_elem

    movq $.search_result, %rdi     # format string to print = .search_result
    movq .search_elem,    %rsi     # first value to print = .search_elem
    movq %rax,            %rdx     # second value to print = %rax
    call print                     # print result of search

    ret                            # exit program

/*
Read %rsi integers from stdin and assign them
to array addresses starting with %rdi.

%rdi: array pointer
%rsi: array length
*/
take_input:
    movq %rdi,   %r12              # %r12 = destination pointer
    movq %rsi,   %r13              # %r13 = number of iterations
    movq $0,     %r14              # %r14 = i
    jmp  .input_loop               # jump to .input_loop
.input_loop:
    cmpq %r14,   %r13              # see if %r14 < %r13
    jg   .inside_input_loop        # jump to .inside_input_loop if %r14 < %r13
    ret                            # return control to caller
.inside_input_loop:
    movq $.scan, %rdi              # string to print = .scan
    call print                     # print .scan
    call scan_int                  # %rax = integer read from stdin
    movq %rax,   (%r12, %r14, 8)   # array[i] = %rax
    inc  %r14                      # ++i
    jmp  .input_loop               # jump to .input_loop

/*
Search for %rcx in the sorted array pointed to by %rdi.
Return the index of the element if it exists or -1 if it doesn't.

%rdi: array pointer
%rsi: lo index
%rdx: hi index
%rcx: search element
*/
binary_search:
    cmpq %rsi,            %rdx     # see if hi > lo
    jge  .binary_search            # jump to .binary_search if hi > lo
    movq $-1,             %rax     # move -1 into %rax
    ret                            # return -1
.binary_search:
    movq %rdx,            %rax     # %rax = hi
    subq %rsi,            %rax     # %rax = hi - lo
    shr  $1,              %rax     # %rax = %rax // 2
    addq %rsi,            %rax     # %rax = %rax + lo = mid
    movq (%rdi, %rax, 8), %r10     # %r10 = array[mid]
    cmpq %rcx,            %r10     # compare search element with array[mid]
    je   .match_case               # array[mid] == search element
    jg   .too_hi_case              # array[mid] > search element
    jl   .too_lo_case              # array[mid] < search element
.match_case:
    ret                            # return mid
.too_hi_case:
    leaq -1(%rax),        %rdx     # hi = mid - 1
    jmp  binary_search             # continue searching in lower half
.too_lo_case:
    leaq 1(%rax),         %rsi     # lo = mid + 1
    jmp  binary_search             # continue searching in upper half

/*
Use printf to safely print the format string pointed to by %rdi to stdout.
Push and pop variable registers to save their values.

%rdi: format string
%rsi: value to print
...
*/
print:
    push %r12                      # save variable register value
    push %r13                      # save variable register value
    push %r14                      # save variable register value
    xorq %rax, %rax                # empty %rax
    call printf                    # call printf
    pop %r14                       # restore variable register value
    pop %r13                       # restore variable register value
    pop %r12                       # restore variable register value
    ret                            # return control to caller

/*
To clear the stdin input buffer after a failed scanf call, read input
from stdin until '\n' or EOF are reached, returning control to caller
if '\n' is reached and exiting the program if EOF is reached.
*/
clear_input_buffer:
.read_loop:
    call getchar                   # %eax = char (4-byte int)
    cmp  $10,  %eax                # see if %eax == '\n'
    je   .newline_case             # jump to .newline_case if %eax == '\n'
    test %eax, %eax                # set flags according to %eax
    js   .eof_case                 # jump to .eof_case if %eax is negative
    jmp  .read_loop                # continue loop
.newline_case:
    ret                            # return control to caller
.eof_case:
    movq $0, %rdi                  # exit status = 0
    call exit                      # exit(0)

/*
Use scanf to safely scan for an integer value from stdin, passing .format
as the format string and .temp for temporary destination storage.
Push and pop variable registers to save their values and
use a stack canary for added system compatibility.
*/
scan_int:
    push %r12                      # save variable register value
    push %r13                      # save variable register value
    push %r14                      # save variable register value
    subq $64,         %rsp         # stack canary
	movq $.format,    %rdi         # set format string parameter
	leaq .temp(%rip), %rsi         # set scan destination parameter
    xorq %rax,        %rax         # empty %rax
	call __isoc99_scanf@PLT        # call scanf
    addq $64,         %rsp         # reset stack canary
    cmpq $1,          %rax         # see if scanf succeeded
    je   .success                  # jump to .success if scanf succeeded
    jmp  .default                  # jump to .default if scanf failed
.success:
    movq .temp(%rip), %rax         # move scanned value into %rax
    jmp .return                    # return scanned value
.default:
    call clear_input_buffer        # clear input buffer for next scanf call
    movq $0,          %rax         # move default value into %rax
    jmp .return                    # return default value
.return:
    pop %r14                       # restore variable register value
    pop %r13                       # restore variable register value
    pop %r12                       # restore variable register value
    ret                            # return %rax
