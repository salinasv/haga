function random_perm(perm_size, pop_size, filename)

PERM = randperm(perm_size);
for i=1:pop_size-1
    PERM = [PERM;randperm(perm_size)];
end

fid = fopen(filename, 'w');
fprintf(fid, '%d\t%d\n', size(PERM,1), size(PERM,2));
fprintf(fid, [repmat('%d\t', 1, length(PERM(1,:))), '\n'], PERM);
fclose(fid);

