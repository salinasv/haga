function random_table_vhd(t_size, filename)

INT_MAX = 32767;

table = floor( (32767 + 1)*rand(t_size) );
table = table - diag(diag(table));

fid = fopen(filename, 'w');
%fprintf(fid, '%d\t%d\n', size(table,1), size(table,2));
fprintf(fid, '\ttype table_type is array (0 to %d) of std_loigc_vector(31 downto 0);\n\n', t_size^2);
fprintf(fid, '\tconstant table : table_type :=\n\t(\n');
fprintf(fid, [repmat('%d, ', 1, length(table(1,:))), '\n'], table');
fprintf(fid, '\t);\n');
fclose(fid);

