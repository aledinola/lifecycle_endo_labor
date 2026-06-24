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
ParamsCalib0 = Params;
ParamsCalib0.beta = 0.95;
ParamsCalib0.nu = 0.40;
ParametrizeParamsFn = [];
caliboptions = struct();
caliboptions.fminalgo = 8;
caliboptions.constrain0to1 = {'beta', 'nu'};
caliboptions.verbose = 1;
caliboptions.weights = 1;

[CalibParams, calibsummary] = CalibrateLifeCycleModel_PType( ...
    CalibParamNames, TargetMoments, n_d, n_a, n_z, N_j, Names_i, ...
    d_grid, a_grid, z_grid, pi_z, ReturnFn, ParamsCalib0, ...
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
my machine. To avoid a trivial test, I generated the targets with
`beta = 0.98` and `nu = 0.335`, but initialized the calibration from
`beta = 0.95` and `nu = 0.40`. The calibration recovered the target-generating
values:

```text
initial beta:              0.950000
initial nu:                0.400000
target beta:               0.980000
target nu:                 0.335000
beta:                      0.979999
nu:                        0.335006
objective:             9.175600e-07
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

## Additional issues to stress test later

After proofreading `CalibrateLifeCycleModel_PType.m`,
`CalibrateLifeCycleModel_PType_objectivefn.m`, and the target-setup helper
`SetupTargetMoments_FHorz.m`, I found a few code paths that are not exercised
by the baseline toy calibration above but may contain bugs.

### Suspected toolkit issues

1. Semi-exogenous shock branch may reference an undefined variable.

   In `CalibrateLifeCycleModel_PType.m`, the branch

   ```matlab
   if prod(vfoptions.n_semiz)>0
       ...
       if any(strcmp(GEPriceParamNames, vfoptions.SemiExoShockFnParamNames(ff)))
   ```

   appears to use `GEPriceParamNames`, which is not an input to
   `CalibrateLifeCycleModel_PType` and does not appear to be defined locally.
   This may only appear when `vfoptions.n_semiz > 0` and
   `vfoptions.SemiExoShockFn` is present. The analogous exogenous-shock branch
   uses `CalibParamNames`, so that may be the intended variable here.

2. Named `AgeConditionalStats` log moments may read the wrong structure.

   In `CalibrateLifeCycleModel_PType.m`, the named-logmoments branch for
   `AgeConditionalStats` appears to check
   `logmomentnames.AllStats...` instead of
   `logmomentnames.AgeConditionalStats...`. This is not exercised when
   `caliboptions.logmoments = 0`.

3. Vector-valued `caliboptions.logmoments` may be broken.

   The vector-logmoments branch references `allstatmomentsizes` and
   `acsmomentsizes`, but those variables do not appear to be available in the
   parent function after calling `SetupTargetMoments_FHorz`. There may also be
   indexing issues in this block.

4. PType-matrix calibrated parameters may be reconstructed incorrectly.

   Near the final reconstruction of calibrated parameters,
   `CalibrateLifeCycleModel_PType.m` loops over `pp` but uses `ii` in
   expressions such as `temp(ii,:)` and `temp(:,ii)`. If `ii` is stale from an
   earlier loop, calibrated PType-specific matrix/vector parameters may be put
   back into the wrong row/column or may error.

5. Deeply nested PType target parsing may contain an index typo.

   In `SetupTargetMoments_FHorz.m`, deeper nested target parsing contains
   assignments involving `a2vec{a3}`. These look like they may be typos for
   `a2vec{a2}`. This would only be hit by more complex PType-specific target
   structures than the current baseline test uses.

## Proposed future stress tests in `main_calibration.m`

Do not replace the successful baseline test. Instead, add a small switch so
that future sessions can run one stress case at a time:

```matlab
stress_case = "baseline";
% Other possible values:
% "named_logmoments"
% "vector_logmoments"
% "ptype_theta"
% "custom_stats"
% "atoB_constraints"
```

Suggested stress cases:

1. `named_logmoments`

   Keep the same age-conditional targets, but add:

   ```matlab
   caliboptions.logmoments = struct();
   caliboptions.logmoments.AgeConditionalStats.hours.Mean = 0;
   ```

   Using zero should test named logmoment parsing without actually logging the
   hours targets. This may expose the apparent `AllStats` versus
   `AgeConditionalStats` typo.

2. `vector_logmoments`

   Keep the same two target groups and set:

   ```matlab
   caliboptions.logmoments = [0; 0];
   ```

   This should exercise the vector logmoments branch and may expose the
   missing `allstatmomentsizes` / `acsmomentsizes` variables.

3. `ptype_theta`

   Add a separate calibration that includes the PType-dependent parameter
   `theta`, initialized away from the target-generating values. For example:

   ```matlab
   CalibParamNames = {'theta'};
   ParamsCalib0.theta = [0.80; 1.40];
   caliboptions.constrainpositive = {'theta'};
   ```

   This should stress PType-specific parameter expansion and final output
   reconstruction. The exact initial values should be chosen to remain
   economically sensible for the model.

4. `custom_stats`

   Add a `TargetMoments.CustomModelStats` block, for example targeting overall
   mean assets and mean working-age hours. Define a tiny local function at the
   end of `main_calibration.m` to compute those same statistics from the model
   objects. This would test the `CustomModelStats` branch in both setup and
   objective evaluation.

5. `atoB_constraints`

   Replace `constrain0to1` with explicit bounded constraints:

   ```matlab
   caliboptions = rmfield(caliboptions, 'constrain0to1');
   caliboptions.constrainAtoB = {'beta', 'nu'};
   caliboptions.constrainAtoBlimits.beta = [0.90, 0.995];
   caliboptions.constrainAtoBlimits.nu = [0.20, 0.60];
   ```

   This keeps the economics sensible while testing another parameter-transform
   path.

I would defer the semi-exogenous-shock branch to a separate artificial test,
because the current model does not use semi-exogenous shocks and would need
additional setup just to reach that code path.
