#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "individual.h"
#include "population.h"

static int pop_size = 0;

void population_init(int size)
{
	pop_size = 0;
}

Population* population_new()
{
	Population *pop;
	Individual* inds[pop_size];
	size_t inds_size;
	int cont;

	if (pop_size == 0) {
		printf("Can't have empty population\n");
		return NULL;
	}

	/* ask space for the population */
	pop = malloc(sizeof(Population));

	/* ask space for the array of individuals AND matingPool */
	inds_size = sizeof(Individual*) * pop_size;
	pop->individuals = malloc(inds_size);
	pop->matingPool = malloc(inds_size);

	/* generate each individual */
	for (cont = 0; cont < pop_size; cont++) {
		pop->individuals[cont] = individual_new();
		//inds[cont] = individual_new();
		
		/* fill and randomize each individual */
		individual_randomize(pop->individuals[cont]);
	}

	/* 4 bytes per pointer, so copy 4*inds_size */
	pop->individuals = memcpy(pop->individuals, inds, inds_size*4);
	pop->matingPool = memcpy(pop->matingPool, inds, inds_size*4);

	return pop;
}
