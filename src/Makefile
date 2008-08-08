OBJECTS = population.o cross.o individual.o select.o

FLAG = -Wall -lm

sga: $(OBJECTS)
	$(CC) -o sga.bin $(FLAG) $(OBJECTS) sga.c

cross.o: cross.c
	$(CC) -c $(FLAG) cross.c

population.o: population.c
	$(CC) -c $(FLAG) population.c

individual.o: individual.c
	$(CC) -c $(FLAG) individual.c

select.o: select.c
	$(CC) -c $(FLAG) select.c
