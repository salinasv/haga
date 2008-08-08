#include "stdio.h"
#include "stdlib.h"

#include "select.h"

void select_tournament(Population *pop, int m)
{
	int i;
	int j;
	int max;
	int index;

	max = pop->individuals[0]->fitness;
	for (i = 0; i < pop->max_size; i++) {
		for (j = i; j <= m; j++) {
			index = i + j;
			index = index < pop->max_size ? index : index - pop->max_size ;

			pop->mating_pool[index]->fitness = 
				pop->individuals[index]->fitness > max ?
				pop->individuals[index]->fitness : max;
		}
	}
}
