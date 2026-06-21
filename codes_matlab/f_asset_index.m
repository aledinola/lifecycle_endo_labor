function asset_index = f_asset_index(aprime, a, z, a_l, a_u, a_grow, NA)
%F_ASSET_INDEX Continuous Fortran-style asset grid index, rounded to integer.
% Inputs:
%   aprime       scalar, unused next-period assets
%   a            scalar, current assets
%   z            scalar, unused productivity shock
%   a_l, a_u     scalars, asset-grid bounds
%   a_grow       scalar, grid curvature parameter
%   NA           scalar, number of asset-grid intervals
% Output:
%   asset_index  scalar, rounded asset-grid index on 0:NA scale

h = (a_u - a_l) / ((1 + a_grow)^NA - 1);
asset_index = log((a - a_l) / h + 1) / log(1 + a_grow);
asset_index = min(max(round(asset_index), 0), NA);

end %end function
