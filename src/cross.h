#ifndef _CROSS_H_
#define _CROSS_H_

#include "individual.h"

/**
 * Perform a One Point crossover ver the two parents setting them on the two
 * sons
 *
 * @param parent1		The first parent to be crossed
 * @param parent2		The second parent to be crossed
 * @param son1			The first son
 * @param son2			The second son
 * @param crosspoint	The point where to perform the cross
 * @param crossprob		The cross probability
 */
void cross_point_one(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint, double crossprob);

/**
 * Perform a Two Point crossover ver the two parents setting them on the two
 * sons
 *
 * @param parent1		The first parent to be crossed
 * @param parent2		The second parent to be crossed
 * @param son1			The first son
 * @param son2			The second son
 * @param crosspoint1	The first point where to perform the cross
 * @param crosspoint2	The second point where to performe the cross
 * @param crossprob		The cross probability
 */
void cross_point_two(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint1, unsigned int crosspoint2, double crossprob);

/**
 * Mutate this individual
 *
 * @param ind		The individual to be mutated
 * @param mutprob	The mutation probability
 */
void mutation_mutate(Individual *ind, double mutprob);

#endif /* _CROSS_H_ */
