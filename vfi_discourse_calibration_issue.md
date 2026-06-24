# Possible `CalibrateLifeCycleModel_PType` default-option issue with `vfoptions.n_semiz`

I am testing a toy calibration of a finite-horizon life-cycle model with
permanent types using `CalibrateLifeCycleModel_PType`. The model has assets,
an exogenous Markov productivity shock, age, and a permanent productivity type.
Labor is endogenous but solved inside the return/statistics functions rather
than declared as a separate decision grid.

The calibration is deliberately overidentified: I calibrate two parameters,
`beta` and `nu`, to match simulated age profiles of average assets and average
hours. Retired-hour targets are set to `NaN`, so they should be ignored by the
calibration objective.

## Minimal call shape

```matlab
TargetMoments.AgeConditionalStats.assets.Mean = ave.assets;
hours_target = ave.hours;
hours_target(~Params.working) = NaN;
TargetMoments.AgeConditionalStats.hours.Mean = hours_target;

CalibParamNames = {'beta', 'nu'};
ParametrizeParamsFn = [];
caliboptions = struct();
caliboptions.fminalgo = 8;
caliboptions.constrain0to1 = {'beta', 'nu'};
caliboptions.verbose = 1;
caliboptions.weights = 1;

[CalibParams, calibsummary] = CalibrateLifeCycleModel_PType( ...
    CalibParamNames, TargetMoments, n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, Params, ...
    DiscountFactorParamNames, jequaloneDist, AgeWeightParamNames, ...
    PTypeDistParamNames, ParametrizeParamsFn, FnsToEvaluate, ...
    caliboptions, vfoptions, simoptions);
```

Here `n_d = 0` and `d_grid = []`, since labor is implicit. The earlier direct
calls to `ValueFnIter_Case1_FHorz_PType`,
`StationaryDist_Case1_FHorz_PType`, and
`LifeCycleProfiles_FHorz_Case1_PType` all run successfully with the same
`vfoptions` structure.

## Error

The calibration call errors before reaching the optimizer:

```text
Unrecognized field name "n_semiz".

Error in CalibrateLifeCycleModel_PType (line 260)
if prod(vfoptions.n_semiz)>0
        ^^^^^^^^^^^^^^^^^
Error in main_calibration (line 107)
[CalibParams, calibsummary] = CalibrateLifeCycleModel_PType( ...
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## Why this looks toolkit-side

The model does not use semi-exogenous shocks, and the non-calibration toolkit
calls appear to default this case internally. During the value-function solve,
the displayed `vfoptions` includes:

```text
n_semiz: 0
```

However, the original `vfoptions` passed into `CalibrateLifeCycleModel_PType`
does not include `n_semiz`, because my setup only specifies:

```matlab
vfoptions.verbose = 1;
vfoptions.parallel = 1 + (gpuDeviceCount > 0);
vfoptions.gridinterplayer = 1;
vfoptions.ngridinterp = 20;
```

So `CalibrateLifeCycleModel_PType` seems to require a default option field that
other finite-horizon toolkit routines can infer.

## Confirmed local workaround

A local workaround is to add this before calling `CalibrateLifeCycleModel_PType`:

```matlab
vfoptions.n_semiz = 0;
```

With that line in the calling script, the toy calibration runs to completion on
my machine. Since the data targets are generated from the same model, the
calibration recovers the initial values:

```text
beta:                      0.980000
nu:                        0.335000
objective:             0.000000e+00
```

## Tentative toolkit-side fix

A possible toolkit-side fix would be to default `vfoptions.n_semiz` before line
260, for example:

```matlab
if ~isfield(vfoptions, 'n_semiz')
    vfoptions.n_semiz = 0;
end
```

or to guard the condition directly:

```matlab
if isfield(vfoptions, 'n_semiz') && prod(vfoptions.n_semiz) > 0
```

I have not modified the toolkit files. This note is only documenting the issue
and the likely workaround.
