function a_grid = f_asset_grid(a_l, a_u, a_grow, NA)
%F_ASSET_GRID Build the Fortran-style growing asset grid.
% Inputs:
%   a_l       scalar, lower asset bound
%   a_u       scalar, upper asset bound
%   a_grow    scalar, grid curvature parameter
%   NA        scalar, number of asset-grid intervals
% Output:
%   a_grid    [(NA+1),1] array, asset grid

idx = (0:NA)';
h = (a_u - a_l) / ((1 + a_grow)^NA - 1);
a_grid = h * ((1 + a_grow).^idx - 1) + a_l;

end %end function
