#include <stdlib.h>

#include "cross.h"


void cross_point_one_ind(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint, unsigned int gen_num)
{
	if (son1 == NULL || son2 == NULL)
		return;

	individual_cpy_chrom_first(son1, parent1, crosspoint, gen_num, TRUE);
	individual_cpy_chrom_first(son1, parent2, crosspoint, gen_num, FALSE);

	individual_cpy_chrom_first(son2, parent2, crosspoint, gen_num, TRUE);
	individual_cpy_chrom_first(son2, parent1, crosspoint, gen_num, FALSE);
}

void cross_point_two_ind(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint1, unsigned int crosspoint2,
		unsigned int gen_num)
{
	if (son1 == NULL || son2 == NULL)
		return;

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

	srand((unsigned int) pop);

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

	srand((unsigned int) pop);

	for (i = 0; i < pop->actual_size; i += 2) {
		if (rand() >= norm_cross)
			continue;

		point = rand() % pop->actual_size;
		point2 = rand() % pop->actual_size;
		cross_point_two_ind(pop->individuals[i], pop->individuals[i+1],
				pop->mating_pool[i], pop->mating_pool[i+1],
				point, point2, pop->ind_gen_num);
	}
}

static mut_mask = {0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01};

void mutation_mutate(Individual *ind, double mutprob)
{
	double normprob;
	unsigned int point;
	char *ptr;
	char offset;
	char tmp;

	normprob = mutprob * RAND_MAX;

	srand((unsigned int) ind);

	if (rand() >= normprob)
		return;

	point = rand() % gen_num*8;

	offset = point % 8;
	point /= gen_num;

	ptr = ind->chrom + offset;

	tmp = *ptr;

	*ptr = tmp & mut_mask[offset] ?
		tmp & ~mut_mask[offset] :
		tmp | mut_mask[offset];

}
