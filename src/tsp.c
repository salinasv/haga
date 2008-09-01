#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "tsp.h"

typedef struct _Bufffer
{
	char *buf;
	int size;
} Buffer;

static Buffer* buffer_new()
{
	Buffer *buf;
	
	buf = malloc(sizeof(Buffer));
	buf->size = 0;

	return buf;
}

static void buffer_destroy(Buffer *buf)
{
	free(buf->buf);
	free(buf);
}

TSPCostTable* tsp_table_new()
{
	TSPCostTable *table;

	table = malloc(sizeof(TSPCostTable));
	table->col_size = 0;
	table->row_size = 0;

	return table;
}

void tsp_cost_destroy(TSPCostTable *table)
{
	free(table->cost_table[0]);
	free(table->cost_table);
	free(table);
}

/* Return pointer from strstr() */
static char* read_line(const Buffer *filebuf, Buffer *linebuf)
{
	char *seek;
	size_t line_size;

	seek = strstr(filebuf->buf, "\n");
	line_size = seek - filebuf->buf + 1; /* add a "\t" at the end to help us seeking*/

	linebuf->buf = realloc(linebuf->buf, line_size);
	linebuf->size = line_size;
	linebuf->buf = memcpy(linebuf->buf, filebuf->buf, line_size);
	linebuf->buf[line_size-1] = '\t';

	return seek;
}

/* Return the pointer from strstr() */
static char* read_word(const Buffer *linebuf, Buffer *wordbuf)
{
	char *seek;
	size_t word_size;

	seek = strstr(linebuf->buf, "\t");
	word_size = seek - linebuf->buf;

	if (wordbuf->size > word_size)
		wordbuf->buf[word_size] = '\0';

	wordbuf->buf = realloc(wordbuf->buf, word_size);
	wordbuf->size = word_size;
	wordbuf->buf = memcpy(wordbuf->buf, linebuf->buf, word_size);
	
	return seek;
}

static void create_the_matrix(TSPCostTable *table, int rows, int columns)
{
	int i;

	table->cost_table = malloc(rows * sizeof(int*));

	if (!table->cost_table)
		printf("Everything is bad, you must ask for help\n");

	table->cost_table[0] = malloc(rows * columns * sizeof(int));

	if (!table->cost_table)
		printf("Everything is bad, you must ask for help 2\n");

	for (i = 0; i < rows; i++)
		table->cost_table[i] = table->cost_table[0] + i * columns;
}

void tsp_cost_read(TSPCostTable *table, char *filename)
{
	Buffer *filebuf;
	Buffer *linebuf;
	Buffer *wordbuf;
	Buffer *seek;
	Buffer *seekln;
	Buffer *tmpsrc;
	int fd;

	int rows;
	int columns;
	int col_bkp;
	int num;

	struct stat statbuf;
	
	fd = open(filename, O_RDONLY);
	stat(filename, &statbuf);
	filebuf = buffer_new();
	filebuf->buf = mmap(NULL, statbuf.st_size, PROT_READ, MAP_SHARED, fd, 0);
	filebuf->size = statbuf.st_size;

	linebuf = buffer_new();
	wordbuf = buffer_new();
	seek = buffer_new();
	seekln = buffer_new();
	tmpsrc = buffer_new();
	/* get some allocated space */
	linebuf->buf = malloc(1);
	linebuf->size = 1;
	wordbuf->buf = malloc(1);
	wordbuf->size = 1;

	/* get size */
	seekln->buf = read_line(filebuf, linebuf);
	seekln->buf++;
	seekln->size = linebuf->size;
	seek->buf = read_word(linebuf, wordbuf);
	seek->size = wordbuf->size;

	rows = atoi(wordbuf->buf);

	tmpsrc->buf = seek->buf + 1; /* get rid of the search pattern */
	tmpsrc->size = seek->buf - seekln->buf;
	seek->buf = read_word(tmpsrc, wordbuf);

	columns = atoi(wordbuf->buf);

	printf("%d rows with %d columns\n", rows, columns);

	/* alloc the cost_table with row * column * sizeof(int) bytes */
	create_the_matrix(table, rows, columns);
	table->col_size = columns;
	table->row_size = rows;

	/* start reading */
	for(rows--; rows >= 0; rows--) {
		/* get one row */
		seekln->buf = read_line(seekln, linebuf);
		seekln->buf++;
		seekln->size = linebuf->size;

		seek->buf = linebuf->buf;
		//seek = seekln;
		for(col_bkp = columns -1 ; col_bkp >= 0; col_bkp--) {
			/* get one word */
			seek->buf = read_word(seek, wordbuf);
			seek->buf++;
			seek->size = wordbuf->size;

			num = atoi(wordbuf->buf);
			table->cost_table[rows][col_bkp] = num;
			printf("%d%s ", num, (col_bkp == 0) ? "" : ",\t");
		}
		printf("\n");
	}

	buffer_destroy(linebuf);
	buffer_destroy(wordbuf);
	/* we must not destroy this ones because they buffers are only copy from the
	 * one in wordbuf and linebuf */
	free(seek);
	free(seekln);
	free(tmpsrc);
	/* We must not destroy filebuf because it's pointing to kenel oned memory */
	free(filebuf);

}

int tsp_evaluate_int(TSPCostTable *table, unsigned int *phen, unsigned int size)
{
	int i;
	long long acum = 0;

	if (table->cost_table == NULL)
		return 0;

	for (i = 0; i < size; i++)
		acum += table->cost_table[phen[i]][phen[i+1]];

	return acum;
}
