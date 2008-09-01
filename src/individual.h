#ifndef _INDIVIDUAL_H_
#define _INDIVIDUAL_H_

#include "masca.h"

typedef struct _Indiviudal
{
	char *chrom;
	unsigned int *phen;
	int fitness;
} Individual;

enum
{
	INDIVIDUAL_TYPE_TSP,
	INDIVIDUAL_TYPE_TSP_ORDONEZ
} IndividualType;

/***************************************************************************
 * @name Individual API
 **************************************************************************/

/**
 * Create a new individual
 *
 * @param gen_num	The number of genotypes
 *
 * @return the new individual
 **/
Individual* individual_new(unsigned int gen_num);

/**
 * Destroy the individual and free memory
 *
 * @param ind	The individual to be destroyed
 */
void individual_destroy(Individual *ind);

/**
 * Randomize the individual
 *
 * @param gen_num	The number of genotypes
 *
 * @param ind	The individual to randomize
 **/
void individual_randomize(Individual *ind, unsigned int gen_num);

/***************************************************************************
 * @name individual Subsystem API
 **************************************************************************/
#if 0

/**
 * Copy the chromosome from one individual to another one
 *
 * @param dest	The individual with the new chromosome
 * @param src	The one from we will get the chormosome
 */
Individual* individual_chrom_cpy(Individual *dest, const Individual *src);
#endif

/**
 * Set the individual fitness
 *
 * @param ind		Individual to add the fitness
 * @param fitness	Fitness
 */
void individual_fitness_set(Individual *ind, int fitness);

/**
 * Set the first cross bits in the chromosome from data
 *
 * @param ind		Individual
 * @param data		Data to copy
 * @param cross		Crosspoint
 */
void individual_set_chrom_first(Individual *ind, const char *data, int cross);

/**
 * set the last cross bits in the chromosome from data
 *
 * @param ind		Individual
 * @param data		Data to copy
 * @param cross		Crosspoint
 * @param gen_num	The number of genotypes
 */
void individual_set_chrom_last(Individual *ind, const char *data,
		int cross, unsigned int gen_num);

/*
 * Copy the first (or last) part of the chromosome from src to dest
 *
 * @param dest		The individual with the new chromosome
 * @param src		The individual with the actual data
 * @param cross		Crosspoint, indicate where it finish (start) the chunk
 * @param gen_num	The number of genotypes
 * @param first		If true get the first part, else the last one
 */
void individual_cpy_chrom_first(Individual *dest, const Individual *src,
		int cross, unsigned int gen_num, bool first);

/***************************************************************************
 * Util
 **************************************************************************/

/**
 * Print the current individual in stdout in some way we can see 
 * what's going on
 *
 * @param ind	The individual to be printed
 */
void individual_print(Individual *indi, unsigned int gen_num);

#endif /* _INDIVIDUAL_H_ */
