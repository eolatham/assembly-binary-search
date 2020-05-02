CC = gcc
CFLAGS = -Wall
IS_NEW_GCC = $(shell expr `gcc -dumpversion | cut -f1 -d.` \>= 9)
ifeq "$(IS_NEW_GCC)" "1"
    CFLAGS += -no-pie
endif
SOURCES = binary_search.s
EXECS = binary_search

all: $(EXECS)

binary_search: $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(EXECS)
