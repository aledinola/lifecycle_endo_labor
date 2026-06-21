function f_write_output(filename, moments)
%F_WRITE_OUTPUT Write the MATLAB moment table in the Fortran output format.
% Inputs:
%   filename  char/string, output text-file path
%   moments   struct, age profiles and table from f_model_moments
% Output:
%   none; writes a plain-text table

fid = fopen(filename, 'w');
if fid < 0
    error('Unable to open output file: %s', filename)
end

fprintf(fid, ' IJ      CONS     HOURS  EARNINGS    INCOME      PENS    ASSETS     CV(C)     CV(L)     CV(Y)     IAMAX\n');
for jj = 1:size(moments.table, 1)
    fprintf(fid, '%3.0f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.0f\n', ...
        moments.table(jj, :));
end
fprintf(fid, '--------------------------------------------------------------------\n');

fclose(fid);

end %end function
