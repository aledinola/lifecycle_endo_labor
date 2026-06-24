clear, clc, close all

toolkit_path = 'C:/Users/aledi/OneDrive/Documents/GitHub/VFIToolkit-matlab';
addpath(genpath(toolkit_path));

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
fprintf('--------------\n');
fprintf('Total runtime:       %12.6f seconds\n', runtime.total);
fprintf('solve_household:     %12.6f seconds\n', runtime.solve_household);
fprintf('get_distribution:    %12.6f seconds\n', runtime.get_distribution);
fprintf('moments by age:      %12.6f seconds\n', runtime.aggregation);
fprintf('\n');
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

%% Toy calibration

stress_case = "ptype_theta";
% Other possible values:
% "named_logmoments"
% "vector_logmoments"
% "ptype_theta"
% "custom_stats"
% "atoB_constraints"

% --- Set targets here
TargetMoments.AgeConditionalStats.assets.Mean = ave.assets;
hours_target = ave.hours;
hours_target(~Params.working) = NaN;
TargetMoments.AgeConditionalStats.hours.Mean = hours_target;

% --- Choose which parameters to calibrate
CalibParamNames = {'beta', 'nu'};
ParamsCalib0 = Params;
ParamsCalib0.beta = 0.95; % Initial guess, target-generating value is 0.98
ParamsCalib0.nu = 0.40; % Initial guess, target-generating value is 0.335

% --- Set caliboptions
ParametrizeParamsFn = [];
caliboptions = struct();
caliboptions.fminalgo = 8; % 8 = lsqnonlin least-squares; 1 = fminsearch simplex
caliboptions.constrain0to1 = {'beta', 'nu'}; % Keep beta and nu inside (0,1)
caliboptions.verbose = 1; % Print parameter values and objective during calibration
caliboptions.weights = 1; % Equal weight on every non-NaN targeted moment

switch stress_case
    case "baseline"
        % Keep the successful baseline calibration unchanged.

    case "named_logmoments"
        caliboptions.logmoments = struct();
        caliboptions.logmoments.AgeConditionalStats.hours.Mean = 0;

    case "vector_logmoments"
        caliboptions.logmoments = [0; 0];

    case "ptype_theta"
        CalibParamNames = {'theta'};
        ParamsCalib0.theta = [0.80; 1.40];
        caliboptions = rmfield(caliboptions, 'constrain0to1');
        caliboptions.constrainpositive = {'theta'};

    case "custom_stats"
        TargetMoments.CustomModelStats.mean_assets = mean(ave.assets, 'omitnan');
        TargetMoments.CustomModelStats.mean_working_hours = ...
            mean(ave.hours(Params.working), 'omitnan');
        caliboptions.CustomModelStats = @f_calibration_custom_stats;

    case "atoB_constraints"
        caliboptions = rmfield(caliboptions, 'constrain0to1');
        caliboptions.constrainAtoB = {'beta', 'nu'};
        caliboptions.constrainAtoBlimits.beta = [0.90, 0.995];
        caliboptions.constrainAtoBlimits.nu = [0.20, 0.60];

    otherwise
        error('Unknown stress_case "%s".', stress_case)
end

vfoptions.n_semiz = 0; % No semi-exogenous shocks; calibration expects this field

tic
[CalibParams, calibsummary] = CalibrateLifeCycleModel_PType( ...
    CalibParamNames, TargetMoments, n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, ParamsCalib0, ...
    DiscountFactorParamNames, jequaloneDist, AgeWeightParamNames, ...
    PTypeDistParamNames, ParametrizeParamsFn, FnsToEvaluate, ...
    caliboptions, vfoptions, simoptions);
runtime.calibration = toc;

fprintf('\nToy calibration results\n');
fprintf('-----------------------\n');
fprintf('stress_case:           %s\n', stress_case);
if strcmp(stress_case, "ptype_theta")
    fprintf('initial theta:         [%12.6f %12.6f]\n', ParamsCalib0.theta(:)');
    fprintf('true theta:            [%12.6f %12.6f]\n', Params.theta(:)');
    fprintf('estimated theta:       [%12.6f %12.6f]\n', CalibParams.theta(:)');
else
    fprintf('initial beta:          %12.6f\n', ParamsCalib0.beta);
    fprintf('initial nu:            %12.6f\n', ParamsCalib0.nu);
    fprintf('true beta:             %12.6f\n', Params.beta);
    fprintf('true nu:               %12.6f\n', Params.nu);
    fprintf('estimated beta:        %12.6f\n', CalibParams.beta);
    fprintf('estimated nu:          %12.6f\n', CalibParams.nu);
end
fprintf('objective:             %12.6e\n', calibsummary.objvalue);
fprintf('calibration runtime:   %12.6f seconds\n', runtime.calibration);
