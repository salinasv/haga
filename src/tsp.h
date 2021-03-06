#ifndef _TSP_H_
#define _TSP_H_

#include "sga.h"
#include "population.h"

typedef struct
{
	int **cost_table;
	unsigned int col_size;
	unsigned int row_size;
} TSPCostTable;

/**
 * Create a new table
 */
TSPCostTable* tsp_table_new();

/******************************************************************************
 * @name TSP API
 *****************************************************************************/

/**
 * Generate the cost table from a file in the working directory
 *
 * This must be called before doing anything else.
 *
 * The file must be a matrix with a fixed size in this form
 * n_row\t	ncol\n
 *
 * x11\t	x12\t	x13\n
 * x21\t	x22\t	x23\n
 * x31\t	x32\t	x33\n
 *
 * @param table		The table wich we will fill with the new data
 * @param filename	The name of the file wher it is the cost table
 **/
void tsp_cost_read(TSPCostTable *table, char *filename);

/**
 * Destroy the table generated by tsp_cost_read()
 *
 * @param table 	The table to be destroyed
 **/
void tsp_table_destroy(TSPCostTable *table);

/**
 * Read permutation from file and set it to the population
 *
 * @param pop		The population to be filled
 * @param filename	The name of the file where is it the permutation table
 */
void tsp_permutation_read_from_file(Population *pop, const char *filename);

/**
 * Evaluate the phen permutation using the [cost] table
 *
 * @param table		Cost table used to evaluate
 * @param phen		An array with the permutation to be evaluated
 * @param size		Size of the array
 *
 * @return The total permutation cost
 */
int tsp_evaluate_int(TSPCostTable *table, unsigned int *phen, unsigned int size);

#endif /* _TSP_H_ */
