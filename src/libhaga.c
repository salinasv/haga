#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "libhaga.h"

#define WRITE_COMMAND_REG 	0
#define START_BIT 			1 << 0

#define READ_COMMAND_REG 	1
#define DONE_BIT 			1 << 0
#define SET_RESULT 			1 << 1
#define GET_PERM_BATCH 		1 << 2
#define GET_TABLE_BATCH 	1 << 3

#define WRITE_DATA_REG 	2
#define READ_DATA_REG 	3

#define HAGA_DEV "/dev/haga"

static int file_descriptor = 0;
static unsigned int status = 0;

int haga_init()
{
	file_descriptor = open(HAGA_DEV, O_RDWR, 0);

	if (file_descriptor < 0) 
		return errno;

	return 0;
}

void haga_close()
{
	close(file_descriptor);
}

static int write_command(unsigned int data, int reg)
{
	if (file_descriptor == 0)
		return -1;

	return pwrite(file_descriptor, &data, sizeof(data), reg*4);
}

int haga_start()
{
	unsigned int data;

	data = START_BIT;

	return write_command(data, WRITE_COMMAND_REG);
}

static int read_command(unsigned int *data, int reg)
{
	if (file_descriptor == 0)
		return -1;

	return pread(file_descriptor, data, sizeof(*data), reg*4);
}

static void read_status()
{
	unsigned int data;
	int readed;

	readed = read_command(&data, READ_COMMAND_REG);

	if (readed == 0)
		return;

	/* update status register copy */
	status = status | data;

	return;
}

static int check_bit(unsigned int bit)
{
	int is;

	read_status();

	is = status & bit;

	status = status & ~bit;
	
	return (is != 0);
}

int haga_is_done()
{
	return check_bit(DONE_BIT);
}

int haga_is_set_result()
{
	return check_bit(SET_RESULT);
}

int haga_is_get_perm_batch()
{
	return check_bit(GET_PERM_BATCH);
}

int haga_is_get_table_batch()
{
	return check_bit(GET_TABLE_BATCH);
}

void haga_send_word(int data)
{
	write_command(data, WRITE_DATA_REG);
}

int haga_read_word()
{
	unsigned int data;

	read_command(&data, READ_DATA_REG);

	return (int)data;
}
