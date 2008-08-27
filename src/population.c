#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "individual.h"
#include "population.h"

Population* population_new(unsigned int pop_size)
{
	Population *pop;
	Individual* inds[pop_size];
	size_t inds_size;

	if (pop_size == 0) {
		printf("Can't have empty population\n");
		return NULL;
	}

	/* ask space for the population */
	pop = malloc(sizeof(Population));

	/* ask space for the array of individuals AND mating_pool */
	inds_size = sizeof(Individual*) * pop_size;
	pop->individuals = malloc(inds_size);
	pop->mating_pool = malloc(inds_size);

	/* Copy the local array */
	pop->individuals = memcpy(pop->individuals, inds, inds_size);
	pop->mating_pool = memcpy(pop->mating_pool, inds, inds_size);

	pop->actual_size = 0;
	pop->max_size = pop_size;

	return pop;
}

Population* population_populate(Population *pop)
{
	int cont;

	/* generate each individual */
	for (cont = 0; cont < pop->max_size; cont++) {
		pop->individuals[cont] = individual_new(pop->ind_gen_num);
		
		/* fill and randomize each individual */
		individual_randomize(pop->individuals[cont], pop->ind_gen_num);
	}

	return pop;
}

Population* population_append_ind(Population *pop, Individual *ind)
{
	if (pop->actual_size == pop->max_size - 1)
		return NULL;

	pop->individuals[pop->actual_size] = ind;
	pop->actual_size++;

	return pop;
}
