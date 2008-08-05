#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "individual.h"

static int binary_size = 0;
static int byte_size = 0;
static int total_gen = 0;
static char mask[8] = {0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE};

void individual_init(int bit_size, int gen)
{
	binary_size = bit_size;
	byte_size = ceil(bit_size/8.0);
	total_gen = gen;

	return;
}

Individual* individual_new()
{
	Individual *ind;
	char chrom[byte_size];
	double phen[total_gen];

	if (binary_size == 0) {
		printf("Individual_new, we don't have the size\n");
		return NULL;
	}

	ind = malloc(sizeof(Individual));
	ind->chrom = malloc(sizeof(chrom));
	ind->phen = malloc(sizeof(phen));
	ind->fitness = 0;

	ind->chrom = memcpy(ind->chrom, chrom, byte_size);
	ind->phen = memcpy(ind->phen, phen, byte_size);
	
	return ind;
}


void individual_destroy(Individual *ind)
{
	free(ind->chrom);
	free(ind->phen);
	free(ind);

	return;
}

void individual_randomize(Individual *ind)
{
	int *ptr;
	int cont;
	int top;

	cont = 0;
	ptr = (int*)ind->chrom;

	/* Get some really unkown seed to be used in the random function
	 * The seed is indeed the unsigned int value of the ind pointer.
	 * Ugly but I guess it works.
	 */
	srand((unsigned int) ind);

	for (top = byte_size /4 ;cont < top; cont++) {
		*ptr = rand();
		ptr++;
	}

	if (byte_size % 4 > 0)
		*ptr = rand();
	
}

int individual_binary_size_get()
{
	return binary_size;
}

int individual_byte_size_get()
{
	return byte_size;
}

void individual_fitness_set(Individual *ind, double fitness)
{
	ind->fitness = fitness;

	return;
}

void individual_set_chrom_first(Individual *ind, const char *data, int cross)
{
	int bytes;
	int bits;
	char *ptr;

	bytes = cross / 8;
	bits = cross % 8;
	ptr = ind->chrom + bytes;

	ind->chrom = memcpy(ind->chrom, data, bytes);

	/* Only copy one byte */
	ptr = memcpy(ptr, data +bytes, 1);

	/* Apply the and mask to get only the first bits */
	*ptr &= mask[bits];

	return;
}

void individual_set_chrom_last(Individual *ind, const char *data, int cross)
{
	int bytes;
	int bit;
	char *ptr;

	bytes = cross / 8;
	bit = cross % 8;

	ptr = ind->chrom + bytes;

	/* copy only one byte */
	ptr = memcpy(ptr, data, 1);

	/* Apply the NOT mask to get the last bits */
	*ptr &= !mask[bit];
	/* We want the next byte */
	ptr++;

	/* get the last bytes (byte_size - bytes) */
	ptr = memcpy(ptr, data + bytes + 1, byte_size - bytes);

	return;
}

void individual_cpy_chrom_first(Individual *dest, const Individual *src,
		int cross, bool first)
{
	if (first)
		individual_set_chrom_first(dest, src->chrom, cross);
	else
		individual_set_chrom_last(dest, src->chrom, cross);

	return;
}
