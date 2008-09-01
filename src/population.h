#ifndef _POPULATION_H_
#define _POPULATION_H_

#include "individual.h"

typedef struct _Population
{
	/* Data */
	Individual **individuals;
	Individual **mating_pool;

	/* population size */
	unsigned int actual_size;
	unsigned int max_size;

	/* Individual info */
	unsigned int ind_gen_num;
} Population;

/***************************************************************************
 * @name Population API
 **************************************************************************/

/**
 * Create a new population
 *
 * @return the new population
 */
Population* population_new(unsigned int pop_size, unsigned int ind_size);

/**
 * Populate the current population with actual real random individuals
 *
 * @param pop	the population to be populated
 */
Population* population_populate(Population *pop);

/**
 * Append an individual to the actual population
 *
 * @param pop	The population
 * @param ind	The individual to be added to the population
 */
Population* population_append_ind(Population *pop, Individual *ind);

#endif /* _POPULATION_H_ */
