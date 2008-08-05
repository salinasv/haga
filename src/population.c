#include <stlib.h>
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
	Individual inds[pop_size];
	size_t inds_size;

	if (pop_size = 0) {
		printf("Can't have empty population\n");
		return NULL;
	}

	pop = malloc(sizeof(Population));

	inds_size = sizeof(inds);
	pop->individuals = malloc(inds_size);
	pop->matingPool = malloc(inds_size);

	pop->individuals = memcpy(pop->individuals, inds, inds_size);
	pop->matingPool = memcpy(pop->matingPool, inds, inds_size);

	return pop;
}

void population_populate(Population *pop)
{
	int i;
	
	for (i = 0; i < pop_size; i++) 
		individual_randomize(pop->individuals[i]);

}
