#include <stdlib.h>

#include "cross.h"


void cross_point_one_ind(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint, unsigned int gen_num, double crossprob)
{
	if (son1 == NULL || son2 == NULL)
		return;

	/* TODO: Add the crossprob stuff, now it will always cross */

	individual_cpy_chrom_first(son1, parent1, crosspoint, gen_num, TRUE);
	individual_cpy_chrom_first(son1, parent2, crosspoint, gen_num, FALSE);

	individual_cpy_chrom_first(son2, parent2, crosspoint, gen_num, TRUE);
	individual_cpy_chrom_first(son2, parent1, crosspoint, gen_num, FALSE);
}

void cross_point_two_ind(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint1, unsigned int crosspoint2,
		unsigned int gen_num, double crossprob)
{
	if (son1 == NULL || son2 == NULL)
		return;

	/* TODO: Add the crossprob stuff, now it will always cross */

	individual_cpy_chrom_first(son1, parent1, crosspoint1, gen_num, TRUE);
	individual_cpy_chrom_first(son1, parent2, crosspoint1, gen_num, FALSE);
	individual_cpy_chrom_first(son1, parent1, crosspoint2, gen_num, FALSE);

	individual_cpy_chrom_first(son2, parent2, crosspoint1, gen_num, TRUE);
	individual_cpy_chrom_first(son2, parent1, crosspoint1, gen_num, FALSE);
	individual_cpy_chrom_first(son2, parent2, crosspoint2, gen_num, FALSE);
}

void cross_point_one(Population *pop, double crossprob)
{
	double norm_cross;
	unsigned int point;
	int i;

	norm_cross = crossprob * RAND_MAX;

	srand(pop);

	for (i = 0; i < pop->actual_size; i += 2) {
		if (rand() >= norm_cross)
			continue;

		point = rand() % pop->actual_size;
		cross_point_one_ind(pop->individuals[i], pop->individuals[i+1],
				pop->mating_pool[i], pop->mating_pool[i+1],
				point, pop->ind_gen_num);
	}
}

void cross_point_two(Population *pop, double crossprob)
{
	double norm_cross;
	unsigned int point;
	unsigned int point2;
	int i;

	norm_cross = crossprob * RAND_MAX;

	srand(pop);

	for (i = 0; i < pop->actual_size; i += 2) {
		if (rand() >= norm_cross)
			continue;

		point = rand() % pop->actual_size;
		point2 = rand() % pop->actual_size;
		cross_point_one_ind(pop->individuals[i], pop->individuals[i+1],
				pop->mating_pool[i], pop->mating_pool[i+1],
				point, point2, pop->ind_gen_num);
	}
}
