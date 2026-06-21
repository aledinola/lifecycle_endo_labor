function moments = f_model_moments(StationaryDist, Policy, Params, n_d, n_a, n_z, ...
    N_j, Names_i, d_grid, a_grid, z_grid, simoptions)
%F_MODEL_MOMENTS Compute age profiles using VFI-Toolkit statistics.
% Inputs:
%   StationaryDist   struct, age distributions from VFI-Toolkit
%   Policy           struct, policy functions from VFI-Toolkit
%   Params           struct, model parameters and age profiles
%   n_d, n_a, n_z    scalars, toolkit grid dimensions
%   N_j              scalar, number of ages
%   Names_i          [1,NP] cell, permanent type names
%   d_grid           empty array, no explicit labor decision
%   a_grid           [n_a,1] array, asset grid
%   z_grid           [n_z,1] array, shock grid
%   simoptions       struct, VFI-Toolkit simulation/statistics options
% Output:
%   moments          struct, age profiles and table [N_j,11]

FnsToEvaluate.consumption = @(aprime, a, z, r, w, eff, pen, theta, nu, working) ...
    f_consumption(aprime, a, z, r, w, eff, pen, theta, nu, working);
FnsToEvaluate.hours = @(aprime, a, z, r, w, eff, pen, theta, nu, working) ...
    f_labor(aprime, a, z, r, w, eff, pen, theta, nu, working);
FnsToEvaluate.earnings = @(aprime, a, z, r, w, eff, pen, theta, nu, working) ...
    f_earnings(aprime, a, z, r, w, eff, pen, theta, nu, working);
FnsToEvaluate.income = @(aprime, a, z, r, w, eff, pen, theta, nu, working) ...
    f_income(aprime, a, z, r, w, eff, pen, theta, nu, working);
FnsToEvaluate.pension = @(aprime, a, z, pen) pen;
FnsToEvaluate.assets = @(aprime, a, z) a;
FnsToEvaluate.asset_index = @(aprime, a, z, a_l, a_u, a_grow, NA) ...
    f_asset_index(aprime, a, z, a_l, a_u, a_grow, NA);

AgeStats = LifeCycleProfiles_FHorz_Case1_PType(StationaryDist, Policy, ...
    FnsToEvaluate, Params, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ...
    z_grid, simoptions);
AgeStats = gather(AgeStats);

% Average of X conditional on age j=1,..,J
moments.age         = (1:N_j)';
moments.consumption = AgeStats.consumption.Mean(:);
moments.hours       = AgeStats.hours.Mean(:);
moments.earnings    = AgeStats.earnings.Mean(:);
moments.income      = AgeStats.income.Mean(:);
moments.pension     = AgeStats.pension.Mean(:);
moments.assets      = AgeStats.assets.Mean(:);

moments.cv_consumption = get_group_std(AgeStats, 'consumption', Names_i, Params) ...
    ./ max(moments.consumption, 1e-10);
moments.cv_hours = get_group_std(AgeStats, 'hours', Names_i, Params) ...
    ./ max(moments.hours, 1e-10);
moments.cv_earnings = get_group_std(AgeStats, 'earnings', Names_i, Params) ...
    ./ max(moments.earnings, 1e-10);
moments.iamax = round(get_max(AgeStats, 'asset_index'));

moments.table = [moments.age, moments.consumption, moments.hours, ...
    moments.earnings, moments.income, moments.pension, moments.assets, ...
    moments.cv_consumption, moments.cv_hours, moments.cv_earnings, ...
    moments.iamax];

end %end function

function x = get_max(AgeStats, fieldname)
%GET_MAX Extract a column vector of age-specific maxima.
% Inputs:
%   AgeStats   struct, gathered VFI-Toolkit age statistics
%   fieldname  char, field to read from AgeStats
% Output:
%   x          [N_j,1] array, maximum by age

x = AgeStats.(fieldname).Maximum(:);

end %end function

function x = get_group_std(AgeStats, fieldname, Names_i, Params)
%GET_GROUP_STD Combine toolkit per-PType stats into grouped standard deviations.
% Inputs:
%   AgeStats   struct, gathered VFI-Toolkit age statistics
%   fieldname  char, field to combine across permanent types
%   Names_i    [1,NP] cell, permanent type names
%   Params     struct, model parameters including JJ and ptype_dist
% Output:
%   x          [JJ,1] array, grouped standard deviation by age

group_mean = AgeStats.(fieldname).Mean(:);
group_var = zeros(Params.JJ, 1);
for ii = 1:length(Names_i)
    name = Names_i{ii};
    mean_i = AgeStats.(fieldname).(name).Mean(:);
    std_i = AgeStats.(fieldname).(name).StdDeviation(:);
    group_var = group_var + Params.ptype_dist(ii) ...
        * (std_i.^2 + (mean_i - group_mean).^2);
end
x = sqrt(max(group_var, 0));

end %end function
