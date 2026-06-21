function f_write_runtime(filename, runtime)
%F_WRITE_RUNTIME Write total and phase-specific MATLAB runtimes.
% Inputs:
%   filename  char/string, runtime text-file path
%   runtime   struct, scalar runtimes in seconds
% Output:
%   none; writes a plain-text runtime report

fid = fopen(filename, 'w');
if fid < 0
    error('Unable to open runtime file: %s', filename)
end

fprintf(fid, 'Runtime report\n');
fprintf(fid, '--------------\n');
fprintf(fid, 'Total runtime:       %12.6f seconds\n', runtime.total);
fprintf(fid, 'solve_household:     %12.6f seconds\n', runtime.solve_household);
fprintf(fid, 'get_distribution:    %12.6f seconds\n', runtime.get_distribution);
fprintf(fid, 'aggregation:         %12.6f seconds\n', runtime.aggregation);
fprintf(fid, '\n');
fprintf(fid, 'Notes: total runtime covers VFI, distribution, and model moment evaluation.\n');

fclose(fid);

end %end function
