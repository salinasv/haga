#include <stdlib.h>

#include "cross.h"


void cross_point_one(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint, double crossprob)
{
	if (son1 == NULL || son2 == NULL)
		return;

	/* TODO: Add the crossprob stuff, now it will always cross */

	individual_cpy_chrom_first(son1, parent1, crosspoint, TRUE);
	individual_cpy_chrom_first(son1, parent2, crosspoint, FALSE);

	individual_cpy_chrom_first(son2, parent1, crosspoint, TRUE);
	individual_cpy_chrom_first(son2, parent2, crosspoint, FALSE);
}

cross_point_two(const Individual *parent1, const Individual *parent2,
		Individual *son1, Individual *son2,
		unsigned int crosspoint1, unsigned int crosspoint2, double crossprob)
{
	if (son1 == NULL || son2 == NULL)
		return;

	/* TODO: Add the crossprob stuff, now it will always cross */

	individual_cpy_chrom_first(son1, parent1, crosspoint1, TRUE);
	individual_cpy_chrom_first(son1, parent2, crosspoint1, FALSE);
	individual_cpy_chrom_first(son1, parent1, crosspoint2, FALSE);

	individual_cpy_chrom_first(son2, parent2, crosspoint1, TRUE);
	individual_cpy_chrom_first(son2, parent1, crosspoint1, FALSE);
	individual_cpy_chrom_first(son2, parent2, crosspoint2, FALSE);
}
