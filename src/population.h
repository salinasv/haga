#ifndef _POPULATION_H_
#define _POPULATION_H_

typedef struct _Population
{
	Individual *individuals;
	Individual *matingPool;
} Population;

/***************************************************************************
 * @name Population API
 **************************************************************************/

/**
 * Init the population data
 *
 * @param size	Size of the actual population
 */
void population_init(int size);

/**
 * Create a new population
 *
 * @return the new population
 */
Population* population_new();

/**
 * Generate a random population
 *
 * @param population	Population to populate.
 */
void population_populate(Population *pop);

#endif /* _POPULATION_H_ */
