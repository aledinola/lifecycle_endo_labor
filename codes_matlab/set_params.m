function [Params, a_grid, z_grid, pi_z, Names_i, jequaloneDist, vfoptions, simoptions, ...
    n_d, n_a, n_z, N_j, d_grid, ReturnFn, DiscountFactorParamNames, ...
    AgeWeightParamNames, PTypeDistParamNames] = set_params()
%SET_PARAMS Set model parameters, grids, PTypes, distributions, and toolkit 
% Inputs:
%   none
% Outputs:
%   Params                    struct, model parameters and age profiles
%   a_grid                    [n_a,1] array, asset grid
%   z_grid                    [n_z,1] array, productivity shock grid
%   pi_z                      [n_z,n_z] array, Markov transition matrix
%   Names_i                   [1,NP] cell, permanent type names
%   jequaloneDist             [n_a,n_z] array, initial distribution
%   vfoptions, simoptions     structs, VFI-Toolkit options
%   remaining outputs         scalars, grids, callbacks, and parameter names

Params.JJ = 80;  % Total periods in the life cycle
Params.JR = 45;  % First retirement period
Params.NA = 200; % Number of asset-grid intervals
Params.NP = 2;   % Number of permanent productivity types
Params.NS = 7;   % Number of Markov shock states

Params.gamma = 0.50; % Intertemporal elasticity parameter
Params.egam  = 1 - 1 / Params.gamma; % CRRA exponent
Params.nu    = 0.335; % Consumption share in period utility
Params.beta  = 0.98; % Time discount factor

Params.sigma_theta = 0.242; % Variance parameter for permanent type
Params.sigma_eps   = 0.022; % Innovation variance for AR(1) shock
Params.rho         = 0.985; % Persistence of AR(1) shock

Params.a_l = 0.0;     % Lower bound of asset grid
Params.a_u = 200.0;   % Upper bound of asset grid
Params.a_grow = 0.05; % Curvature of growing asset grid

Params.r = 0.04; % Net interest rate
Params.w = 1.0;  % Wage rate

% Survival probabilities use Fortran indexing psi(j+1) in the discount factor.
psi = [1.00000, 0.99923, 0.99914, 0.99914, 0.99912, ...
    0.99906, 0.99908, 0.99906, 0.99907, 0.99901, ...
    0.99899, 0.99896, 0.99893, 0.99890, 0.99887, ...
    0.99886, 0.99878, 0.99871, 0.99862, 0.99853, ...
    0.99841, 0.99835, 0.99819, 0.99801, 0.99785, ...
    0.99757, 0.99735, 0.99701, 0.99676, 0.99650, ...
    0.99614, 0.99581, 0.99555, 0.99503, 0.99471, ...
    0.99435, 0.99393, 0.99343, 0.99294, 0.99237, ...
    0.99190, 0.99137, 0.99085, 0.99000, 0.98871, ...
    0.98871, 0.98721, 0.98612, 0.98462, 0.98376, ...
    0.98226, 0.98062, 0.97908, 0.97682, 0.97514, ...
    0.97250, 0.96925, 0.96710, 0.96330, 0.95965, ...
    0.95619, 0.95115, 0.94677, 0.93987, 0.93445, ...
    0.92717, 0.91872, 0.91006, 0.90036, 0.88744, ...
    0.87539, 0.85936, 0.84996, 0.82889, 0.81469, ...
    0.79705, 0.78081, 0.76174, 0.74195, 0.72155, ...
    0.00000]';
Params.survival = psi(2:end);

% Age-efficiency profile is positive before retirement and zero afterward.
Params.eff = zeros(Params.JJ, 1);
Params.eff(1:Params.JR-1) = [1.0000, 1.0719, 1.1438, 1.2158, 1.2842, 1.3527, ...
    1.4212, 1.4897, 1.5582, 1.6267, 1.6952, 1.7217, ...
    1.7438, 1.7748, 1.8014, 1.8279, 1.8545, 1.8810, ...
    1.9075, 1.9341, 1.9606, 1.9623, 1.9640, 1.9658, ...
    1.9675, 1.9692, 1.9709, 1.9726, 1.9743, 1.9760, ...
    1.9777, 1.9700, 1.9623, 1.9546, 1.9469, 1.9392, ...
    1.9315, 1.9238, 1.9161, 1.9084, 1.9007, 1.8354, ...
    1.7701, 1.7048]';

Params.pension_replacement = 0.5;
Params.pension_tax = 0.33;
Params.pen = zeros(Params.JJ, 1);
Params.pen(Params.JR:Params.JJ) = Params.pension_replacement ...
    * sum(Params.eff) / (Params.JR - 1) * Params.pension_tax;

% Permanent types are equiprobable and handled through the PType wrapper.
Params.working = ((1:Params.JJ)' < Params.JR);
Params.theta = [exp(-sqrt(Params.sigma_theta)); exp(sqrt(Params.sigma_theta))];
Params.ptype_dist = ones(Params.NP, 1) / Params.NP;

Params.age_weights = ones(1, Params.JJ) / Params.JJ;

% The toolkit Rouwenhorst routine expects the innovation standard deviation.
rouwenhorstoptions.parallel = 0;
[log_z_grid, pi_z] = discretizeAR1_Rouwenhorst(0, Params.rho,sqrt(Params.sigma_eps), ...
    Params.NS, rouwenhorstoptions);
z_grid = exp(log_z_grid);

% The asset grid matches the Fortran growing grid with indexes 0:NA.
a_grid = f_asset_grid(Params.a_l, Params.a_u, Params.a_grow, Params.NA);

% Labor is implicit, so the only toolkit action is next-period assets.
n_d    = 0;
d_grid = [];
n_a = Params.NA + 1;
n_z = Params.NS;
N_j = Params.JJ;
Names_i = {'ptype001', 'ptype002'};

% Agents start with zero assets and the median exogenous shock state.
if mod(Params.NS, 2) ~= 1
    error('Params.NS must be odd so the initial shock state is well defined.')
end
z_init_idx    = (Params.NS + 1) / 2; % Median level
jequaloneDist = zeros(n_a, n_z);
jequaloneDist(1, z_init_idx) = 1.0;

% VFI uses the GPU when available; user-supplied grids remain CPU arrays.
vfoptions.verbose = 1;
vfoptions.parallel = 1 + (gpuDeviceCount > 0);
vfoptions.gridinterplayer = 1;
vfoptions.ngridinterp = 20;

% Distribution and statistics options mirror the VFI interpolation layer.
simoptions.verbose = 0;
simoptions.parallel = vfoptions.parallel;
simoptions.gridinterplayer = vfoptions.gridinterplayer;
simoptions.ngridinterp = vfoptions.ngridinterp;
simoptions.agegroupings = 1:Params.JJ;
simoptions.groupptypesforstats = 1;
% whichstats = [mean, median, variance/std, Gini/Lorenz, min/max, quantiles, top shares].
% Only mean, standard deviation, and max are needed for the output table.
simoptions.whichstats = [1, 0, 1, 0, 1, 0, 0];

% Parameter names are inferred from the anonymous function arguments.
ReturnFn = @(aprime, a, z, r, w, eff, pen, theta, nu, egam, working) ...
    f_ReturnFn(aprime, a, z, r, w, eff, pen, theta, nu, egam, working);
DiscountFactorParamNames = {'beta', 'survival'};
AgeWeightParamNames = {'age_weights'};
PTypeDistParamNames = {'ptype_dist'};

end %end function
