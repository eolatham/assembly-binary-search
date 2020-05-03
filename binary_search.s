/*
Author: Eric Latham
Email: ericoliverlatham@gmail.com
To compile: gcc -Wall -no-pie -o binary_search binary_search.s
To run: ./binary_search
*/

.data
.temp: .space 4                    # 4-byte integer scanf temporary variable
.array: .long 0, 0, 0, 0, 0        # 4-byte integer array of length 5
.search_elem: .long 1              # 4-byte integer search element
.array_prompt: .string "Build a sorted array...\n"
.search_prompt: .string "\nSpecify an element to search for in the array...\n"
.search_result: .string "\nResult of Binary Search for %i: %i\n"
.scan: .string "Enter an integer: "
.format: .string "%d"

.text
.global main

main:
    mov  $.array_prompt,  %edi     # string to print = .array_prompt
    call print                     # print .array_prompt
    mov  $.array, %edi             # array pointer parameter = .array
    mov  $5, %esi                  # array length parameter = 5
    call take_input                # .array = array created with user input

    mov  $.search_prompt, %edi     # string to print = .search_prompt
    call print                     # print .search_prompt
    mov  $.search_elem,   %edi     # array pointer parameter = .search_elem
    mov  $1,              %esi     # array length parameter = 1
    call take_input                # .search_elem = search element from user input

    mov  $.array,         %edi     # array pointer parameter = .array
    mov  $0,              %esi     # lo index parameter = 0
    mov  $4,              %edx     # hi index parameter = 4
    mov  .search_elem,    %ecx     # search element parameter = .search_elem
    call binary_search             # %eax = result of binary search for .search_elem

    mov  $.search_result, %edi     # format string to print = .search_result
    mov  .search_elem,    %esi     # first value to print = .search_elem
    mov  %eax,            %edx     # second value to print = %eax
    call print                     # print result of search

    ret                            # exit program

/*
Read %esi integers from stdin and assign them
to array addresses starting with %edi.

%edi: array pointer
%esi: array length
*/
take_input:
    mov  %edi,   %edx              # %edx = destination pointer
    mov  %esi,   %ecx              # %ecx = number of iterations
    mov  $0,     %ebx              # %ebx = i
    jmp  .input_loop               # jump to .input_loop
.input_loop:
    cmp  %ebx,   %ecx              # see if %ebx < %ecx
    jg   .inside_input_loop        # jump to .inside_input_loop if %ebx < %ecx
    ret                            # return control to caller
.inside_input_loop:
    mov  $.scan, %edi              # string to print = .scan
    call print                     # print .scan
    call scan_int                  # %eax = integer read from stdin
    mov  %eax,   (%edx, %ebx, 8)   # array[i] = %eax
    inc  %ebx                      # ++i
    jmp  .input_loop               # jump to .input_loop

/*
Search for %ecx in the sorted array pointed to by %edi.
Return the index of the element if it exists or -1 if it doesn't.

%edi: array pointer
%esi: lo index
%edx: hi index
%ecx: search element
*/
binary_search:
    cmp  %esi,            %edx     # see if hi > lo
    jge  .binary_search            # jump to .binary_search if hi > lo
    mov  $-1,             %eax     # move -1 into %eax
    ret                            # return -1
.binary_search:
    mov  %edx,            %eax     # %eax = hi
    sub  %esi,            %eax     # %eax = hi - lo
    shr  $1,              %eax     # %eax = %eax // 2
    add  %esi,            %eax     # %eax = %eax + lo = mid
    mov  (%edi, %eax, 8), %ebx     # %ebx = array[mid]
    cmp  %ecx,            %ebx     # compare search element with array[mid]
    je   .match_case               # array[mid] == search element
    jg   .too_hi_case              # array[mid] > search element
    jl   .too_lo_case              # array[mid] < search element
.match_case:
    ret                            # return mid
.too_hi_case:
    lea  -1(%eax),        %edx     # hi = mid - 1
    jmp  binary_search             # continue searching in lower half
.too_lo_case:
    lea  1(%eax),         %esi     # lo = mid + 1
    jmp  binary_search             # continue searching in upper half

/*
Use printf to safely print the format string pointed to by %edi to stdout.
Push and pop variable registers to save their values.

%edi: format string
%esi: value to print
...
*/
print:
    push %rdx                      # save variable register value
    push %rcx                      # save variable register value
    push %rbx                      # save variable register value
    xor  %eax, %eax                # empty %eax
    call printf                    # call printf
    pop  %rbx                      # restore variable register value
    pop  %rcx                      # restore variable register value
    pop  %rdx                      # restore variable register value
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
    mov  $0, %edi                  # exit status = 0
    call exit                      # exit(0)

/*
Use scanf to safely scan for an integer value from stdin, passing .format
as the format string and .temp for temporary destination storage.
Push and pop variable registers to save their values and
use a stack canary for added system compatibility.
*/
scan_int:
    push %rdx                      # save variable register value
    push %rcx                      # save variable register value
    push %rbx                      # save variable register value
    sub  $64,         %rsp         # stack canary
	mov  $.format,    %edi         # set format string parameter
	lea  .temp(%rip), %esi         # set scan destination parameter
    xor  %eax,        %eax         # empty %eax
	call __isoc99_scanf@PLT        # call scanf
    add  $64,         %rsp         # reset stack canary
    cmp  $1,          %eax         # see if scanf succeeded
    je   .success                  # jump to .success if scanf succeeded
    jmp  .default                  # jump to .default if scanf failed
.success:
    mov  .temp(%rip), %eax         # move scanned value into %eax
    jmp  .return                   # return scanned value
.default:
    call clear_input_buffer        # clear input buffer for next scanf call
    mov  $0,          %eax         # move default value into %eax
    jmp  .return                   # return default value
.return:
    pop  %rbx                      # restore variable register value
    pop  %rcx                      # restore variable register value
    pop  %rdx                      # restore variable register value
    ret                            # return %eax
