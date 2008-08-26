#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Remove this include, needed because of PHEN_TYPE */
#include "sga.h"
#include "tsp.h"

static PHEN_TYPE **cost_table;
static unsigned int table_size_col = 0;
static unsigned int table_size_row = 0;

/* Return pointer from strstr() */
static char* read_line(const char *filebuf, char *linebuf)
{
	char *seek;
	size_t line_size;

	seek = strstr(filebuf, "\n");
	line_size = seek - filebuf + 1; /* add a "\t" at the end to help us seeking*/

	linebuf = realloc(linebuf, line_size);
	linebuf = memcpy(linebuf, filebuf, line_size);
	linebuf[line_size-1] = '\t';

	return seek;
}

/* Return the pointer from strstr() */
static char* read_word(const char *linebuf, char *wordbuf)
{
	char *seek;
	size_t word_size;

	seek = strstr(linebuf, "\t");
	word_size = seek - linebuf;

	wordbuf = realloc(wordbuf, word_size);
	wordbuf = memcpy(wordbuf, linebuf, word_size);
	
	return seek;
}

static void create_the_matrix(int rows, int columns)
{
	int i;

	cost_table = malloc(rows * sizeof(PHEN_TYPE*));

	if (!cost_table)
		printf("Everything is bad, you must ask for help\n");

	cost_table[0] = malloc(rows * columns * sizeof(PHEN_TYPE));

	if (!cost_table)
		printf("Everything is bad, you must ask for help 2\n");

	for (i = 0; i < rows; i++)
		cost_table[i] = cost_table[0] + i * columns;
}

void tsp_cost_read(char *filename)
{
	char *filebuf;
	char *linebuf;
	char *wordbuf;
	char *seek;
	char *seekln;
	char *tmpsrc;
	int fd;

	int rows;
	int columns;
	int col_bkp;
	PHEN_TYPE num;

	struct stat statbuf;
	
	fd = open(filename, O_RDONLY);
	stat(filename, &statbuf);
	filebuf = mmap(NULL, statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);

	/* get some allocated space */
	linebuf = malloc(1);
	wordbuf = malloc(1);

	/* get size */
	seekln = read_line(filebuf, linebuf);
	seekln++;
	seek = read_word(linebuf, wordbuf);

	rows = atoi(wordbuf);

	tmpsrc = seek + 1; /* get rid of the search pattern */
	seek = read_word(tmpsrc, wordbuf);

	columns = atoi(wordbuf);

	printf("%d rows with %d columns\n", rows, columns);

	/* alloc the cost_table with row * column * sizeof(PHEN_TYPE) bytes */
	create_the_matrix(rows, columns);
	table_size_col = columns;
	table_size_row = rows;

	/* start reading */
	for(rows--; rows >= 0; rows--) {
		/* get one row */
		seekln = read_line(seekln, linebuf);
		seekln++;

		seek = linebuf;
		for(col_bkp = columns -1 ; col_bkp >= 0; col_bkp--) {
			/* get one word */
			seek = read_word(seek, wordbuf);
			seek++;

			num = atoi(wordbuf);
			cost_table[rows][col_bkp] = num;
			printf("%f%s ", num, (col_bkp == 0) ? "" : ",");
		}
		printf("\n");
	}

	free(linebuf);
	free(wordbuf);

}

void tsp_cost_destroy()
{
	free(cost_table[0]);
	free(cost_table);
}

long long tsp_evaluate_int(unsigned int *phen, unsigned int size)
{
	int i;
	long long acum = 0;

	if (cost_table == NULL)
		return 0;

	for (i = 0; i < size; i++)
		acum += cost_table[phen[i]][phen[i+1]];

	return acum;
}
