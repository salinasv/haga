OBJECTS = population.o cross.o individual.o select.o tsp.o

CFLAGS = -Wall -lm -ggdb -pg

sga: $(OBJECTS)
	$(CC) -o sga.bin $(CFLAGS) $(OBJECTS) sga.c

cross.o: cross.c
	$(CC) -c $(CFLAGS) cross.c

population.o: population.c
	$(CC) -c $(CFLAGS) population.c

individual.o: individual.c
	$(CC) -c $(CFLAGS) individual.c

select.o: select.c
	$(CC) -c $(CFLAGS) select.c

tsp.o: tsp.c
	$(CC) -c $(CFLAGS) tsp.c

libhaga.o: libhaga

libhaga: libhaga.c
	$(CC) -c $(CFLAGS) libhaga.c

clean:
	rm *.o
