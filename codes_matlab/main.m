clear, clc, close all

toolkit_path = 'C:/Users/aledi/OneDrive/Documents/GitHub/VFIToolkit-matlab';
addpath(genpath(toolkit_path));
addpath(pwd);

[Params, a_grid, z_grid, pi_z, Names_i, jequaloneDist, vfoptions, simoptions, ...
    n_d, n_a, n_z, N_j, d_grid, ReturnFn, DiscountFactorParamNames, ...
    AgeWeightParamNames, PTypeDistParamNames] = set_params();

tic
[V, Policy] = ValueFnIter_Case1_FHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
runtime.solve_household = toc;

tic
StationaryDist = StationaryDist_Case1_FHorz_PType(jequaloneDist, ...
    AgeWeightParamNames, PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, ...
    Names_i, pi_z, Params, simoptions);
runtime.get_distribution = toc;

tic
moments = f_model_moments(StationaryDist, Policy, Params, n_d, n_a, n_z, ...
    N_j, Names_i, d_grid, a_grid, z_grid, simoptions);
runtime.aggregation = toc;
runtime.total = runtime.solve_household + runtime.get_distribution + runtime.aggregation;

f_write_output(fullfile(pwd, 'output.txt'), moments);
f_write_runtime(fullfile(pwd, 'runtime_report.txt'), runtime);
f_plot_moments(moments, fullfile(pwd, 'figures'));

disp('MATLAB VFI-Toolkit run complete.')
disp(['Output written to ', fullfile(pwd, 'output.txt')])
