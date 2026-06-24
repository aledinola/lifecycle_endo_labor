function CustomStats = f_calibration_custom_stats(V, Policy, StationaryDist, ...
    Parameters, FnsToEvaluate, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ...
    z_grid, pi_z, caliboptions, vfoptions, simoptions)
%F_CALIBRATION_CUSTOM_STATS Compute scalar calibration diagnostics.
% Inputs:
%   V, Policy, StationaryDist   structs, solved model objects from toolkit
%   Parameters                  struct, model parameters and age profiles
%   FnsToEvaluate               struct, statistics callbacks
%   n_d, n_a, n_z, N_j          scalars, toolkit grid dimensions
%   Names_i                     [1,NP] cell, permanent type names
%   d_grid, a_grid, z_grid      arrays, toolkit grids
%   pi_z                        array, shock transition object, unused here
%   caliboptions                struct, calibration options, unused here
%   vfoptions, simoptions       structs, toolkit options
% Output:
%   CustomStats                 struct, scalar custom calibration moments

unused_inputs = {V, pi_z, caliboptions}; %#ok<NASGU>

simoptions_custom = simoptions;
simoptions_custom.alreadygridvals = 1;
if isfield(vfoptions, 'e_gridvals_J')
    simoptions_custom.e_gridvals_J = vfoptions.e_gridvals_J;
end
if isfield(vfoptions, 'pi_e_J')
    simoptions_custom.pi_e_J = vfoptions.pi_e_J;
end

AgeStats = LifeCycleProfiles_FHorz_Case1_PType(StationaryDist, Policy, ...
    FnsToEvaluate, Parameters, n_d, n_a, n_z, N_j, Names_i, d_grid, ...
    a_grid, z_grid, simoptions_custom);
AgeStats = gather(AgeStats);

working = (Parameters.working(:) > 0);
CustomStats.mean_assets = mean(AgeStats.assets.Mean(:), 'omitnan');
CustomStats.mean_working_hours = mean(AgeStats.hours.Mean(working), 'omitnan');

end %end function
