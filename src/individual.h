#ifndef _INDIVIDUAL_H_
#define _INDIVIDUAL_H_

struct _Indiviudal
{
	char *chrom;
	double phenotype;
	double fitness;
}

typedef struct _Individual Individual;

/***************************************************************************
 * @name Individual API
 **************************************************************************/

/**
 * Create a new individual
 **/
Individual* individual_new();

/**
 * Destroy the individual and free memory
 *
 * @param ind	The individual to be destroyed
 */
void individual_destroy(Individual ind);

/**
 * Set the number of bits the individual will use
 *
 * @param size	The number of bits to use
 */
void individual_set_size_binary(int size);

/**
 * Get the size of the individual in bits
 */
int individual_get_size_binary();

/**
 * Get the size of the indiviual in bytes
 */
int individual_get_size_byte();

/***************************************************************************
 * @name individual Subsystem API
 **************************************************************************/

/**
 * Copy the chromosome from one individual to another one
 *
 * @param dest	The individual with the new chromosome
 * @param src	The one from we will get the chormosome
 */
Individual* individual_chrom_cpy(Individual *dest, const Individual *src);

/**
 * Set the individual fitness
 *
 * @param ind		Individual to add the fitness
 * @param fitness	Fitness
 */
void individual_fitness_add(Individual *ind, double fitness);

#endif /* _INDIVIDUAL_H_ */
