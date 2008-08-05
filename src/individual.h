#ifndef _INDIVIDUAL_H_
#define _INDIVIDUAL_H_

#include "masca.h"

typedef struct _Indiviudal
{
	char *chrom;
	double *phen;
	double fitness;
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
 * Init the individual data
 *
 * @param bit_size	Size in bits for the chromosome
 * @param gen		Number of Genes in the chromosome
 */
void individual_init(int bit_size, int gen);

/**
 * Create a new individual
 *
 * @return the new individual
 **/
Individual* individual_new();

/**
 * Destroy the individual and free memory
 *
 * @param ind	The individual to be destroyed
 */
void individual_destroy(Individual *ind);

/**
 * Randomize the individual
 *
 * @param ind	The individual to randomize
 **/
void individual_randomize(Individual *ind);

/**
 * Get the size of the individual in bits
 */
int individual_binary_size_get();

/**
 * Get the size of the indiviual in bytes
 */
int individual_byte_size_get();

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
void individual_fitness_set(Individual *ind, double fitness);

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
 */
void individual_set_chrom_last(Individual *ind, const char *data, int cross);

/*
 * Copy the first (or last) part of the chromosome from src to dest
 *
 * @param dest		The individual with the new chromosome
 * @param src		The individual with the actual data
 * @param cross		Crosspoint, indicate where it finish (start) the chunk
 * @param first		If true get the first part, else the last one
 */
void individual_cpy_chrom_first(Individual *dest, const Individual *src,
		int cross, bool first);

#endif /* _INDIVIDUAL_H_ */
