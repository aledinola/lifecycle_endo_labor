clear, clc, close all

toolkit_path = 'C:/Users/aledi/OneDrive/Documents/GitHub/VFIToolkit-matlab';
addpath(genpath(toolkit_path));
addpath(pwd);

%% Set parameters and grids
[Params, a_grid, z_grid, pi_z, Names_i, jequaloneDist, vfoptions, simoptions, ...
    n_d, n_a, n_z, N_j, d_grid, ReturnFn, DiscountFactorParamNames, ...
    AgeWeightParamNames, PTypeDistParamNames] = set_params();

%% Value function iteration
tic
[V, Policy] = ValueFnIter_Case1_FHorz_PType(n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, vfoptions);
runtime.solve_household = toc;

%% Distribution
tic
StationaryDist = StationaryDist_Case1_FHorz_PType(jequaloneDist, ...
    AgeWeightParamNames, PTypeDistParamNames, Policy, n_d, n_a, n_z, N_j, ...
    Names_i, pi_z, Params, simoptions);
runtime.get_distribution = toc;

%% Model moments
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

tic

AgeStats = LifeCycleProfiles_FHorz_Case1_PType(StationaryDist, Policy, ...
    FnsToEvaluate, Params, n_d, n_a, n_z, N_j, Names_i, d_grid, a_grid, ...
    z_grid, simoptions);
AgeStats = gather(AgeStats);

% Average of X conditional on age j=1,..,J
ave.age         = (1:N_j)';
ave.consumption = AgeStats.consumption.Mean(:);
ave.hours       = AgeStats.hours.Mean(:);
ave.earnings    = AgeStats.earnings.Mean(:);
ave.income      = AgeStats.income.Mean(:);
ave.pension     = AgeStats.pension.Mean(:);
ave.assets      = AgeStats.assets.Mean(:);

runtime.aggregation = toc;

runtime.total = runtime.solve_household + runtime.get_distribution + runtime.aggregation;

%% Report run times
fprintf('Runtime report\n');
fprintf( '--------------\n');
fprintf( 'Total runtime:       %12.6f seconds\n', runtime.total);
fprintf( 'solve_household:     %12.6f seconds\n', runtime.solve_household);
fprintf( 'get_distribution:    %12.6f seconds\n', runtime.get_distribution);
fprintf( 'aggregation:         %12.6f seconds\n', runtime.aggregation);
fprintf( '\n');
fprintf( 'Notes: total runtime covers VFI, distribution, and model moment evaluation.\n');

%% Make plots

ages = (1:N_j)'+19;

figure
plot(ages, ave.consumption, 'LineWidth', 1.5)
hold on
plot(ages, ave.earnings + ave.pension, 'LineWidth', 1.5)
xlabel('Age')
legend({'Consumption', 'Earnings + pension'}, 'Location', 'best')
grid on

figure
plot(ages, ave.hours, 'LineWidth', 1.5)
xlabel('Age')
ylabel('Hours')
grid on

figure
plot(ages, ave.assets, 'LineWidth', 1.5)
xlabel('Age')
ylabel('Assets')
grid on

disp('MATLAB VFI-Toolkit run complete.')
