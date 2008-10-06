function random_perm_vhd(perm_size, pop_size, filename)

PERM = randperm(perm_size)-1;
for i=1:pop_size-1
    PERM = [PERM;randperm(perm_size)-1];
end

fid = fopen(filename, 'w');
%fprintf(fid, '%d\t%d\n', size(PERM,1), size(PERM,2));
fprintf(fid, '\ttype perm_ram_type is array (0 to %d) of integer;\n\n', perm_size*pop_size);
fprintf(fid, '\tconstant perm_rom : perm_ram_type :=\n\t(\n');
fprintf(fid, [repmat('%d, ', 1, length(PERM(1,:))), '\n'], PERM');
fprintf(fid, '\t);\n');
fclose(fid);

