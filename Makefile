CC = gcc
CFLAGS = -Wall -no-pie
SOURCES = binary_search.s
EXECS = binary_search

all: $(EXECS)

binary_search: $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(EXECS)
