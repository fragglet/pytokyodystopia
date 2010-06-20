
CYTHON=cython
CFLAGS=-I/usr/include/python2.5
LDFLAGS=-lpython2.5 -ltokyodystopia

dystopia.so : dystopia.o
	$(CC) -shared $(LDFLAGS) $^ -o $@

%.o : %.c
	$(CC) $(CFLAGS) -c $^ -o $@

%.c : %.pyx
	$(CYTHON) $(CYFLAGS) $^

