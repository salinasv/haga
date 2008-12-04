#ifndef _LIBHAGA_H_
#define _LIBHAGA_H_

int haga_init();

void haga_close();

int haga_start();

/**
 * Reads the status register you must ask about each bit with helper
 * functions
void haga_read_status();
 */
int haga_is_done();

int haga_is_set_result();

int haga_is_get_perm_batch();

int haga_is_get_table_batch();

void haga_send_word(int data);

int haga_read_word();

#endif /*_LIBHAGA_H*/
