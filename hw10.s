.data
.n: .space 16
.array: .quad 1, 2, 3, 4, 5
.search_elem: .quad 1
.array_prompt: .string "Build a sorted array...\n"
.search_prompt: .string "\nSpecify an element to search for in the array...\n"
.search_res: .string "\nResult of Binary Search for %i: %i\n"
.scan: .string "Enter a positive integer: "
.format: .string "%d"
.number: .string "%i "

.text
.global main

main:
    movq $.array_prompt, %rdi
    call print
    movq $.array, %rdi
    movq $5, %rsi
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

    movq $.search_res, %rdi
    movq .search_elem, %rsi
    movq %rax, %rdx
    call print                     # print the result of search

    ret

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
    call scan
    movq %rax, (%rbx, %r10, 8)     # insert into destination

    inc %r10
    jmp .input_loop

binary_search:
    cmpq %rsi, %rdx
    jge .binary_search

    movq $-1, %rax
    ret

.binary_search:
    movq %rdx, %rax
    subq %rsi, %rax
    shr $1, %rax
    addq %rsi, %rax                # %rax = l + (r - l) // 2 = mid

    movq (%rdi, %rax, 8), %r10
    cmpq %rcx, %r10
    je .case1
    jg .case2
    jl .case3

.case1:
    ret

.case2:
    leaq -1(%rax), %rdx
    jmp binary_search

.case3:
    leaq 1(%rax), %rsi
    jmp binary_search

print:
    push %rax
    push %rbx
    push %rcx
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    xor %rax, %rax
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

scan:
    push %rbx
    push %rcx
    push %r10
    subq $64, %rsp                 # stack canary
	movq $.format, %rdi            # param 1, subst string
	xorq %rax, %rax                # empty rax
	leaq .n(%rip), %rsi            # param 2, place to put
	call __isoc99_scanf@PLT        # function call (special scanf to avoid issue with parsing)
	addq $64, %rsp                 # stack canary reset
    movq .n(%rip), %rax
    pop %r10
    pop %rcx
    pop %rbx
    ret
