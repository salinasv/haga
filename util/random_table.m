function random_table(t_size, filename)

INT_MAX = 32767;

table = floor( (32767 + 1)*rand(t_size) );
table = table - diag(diag(table));

fid = fopen(filename, 'w');
fprintf(fid, '%d\t%d\n', size(table,1), size(table,2));
fprintf(fid, [repmat('%d\t', 1, length(table(1,:))), '\n'], table);
fclose(fid);

printf('You will need to do :%s/^I//g in vim to get this working with the tsp reader function\n')
