# Life-Cycle Endogenous Labor

This repository compares solutions of a life-cycle model with endogenous labor supply across Fortran and MATLAB.

## Structure

- `codes_fortran/`: Fortran implementation of the model, including solution, cohort aggregation, tables, and gnuplot data/scripts.
- `codes_matlab/`: Reserved for a future MATLAB implementation using VFI-Toolkit. No MATLAB code has been added yet.
- `tex_pdf/`: Notes and paper draft material.

## Fortran Baseline

The current Fortran source solves the baseline model using value function iteration, computes the household distribution over state space, aggregates cohort outcomes, and writes the table `output.out` when run. It also writes `runtime_report.txt` with total runtime and separate timings for `solve_household`, `get_distribution`, and `aggregation`.

On Windows with Intel oneAPI initialized:

```powershell
cd codes_fortran
nmake /f makefile_win
nmake /f makefile_win run
```

The plotting calls are currently commented out so the baseline run does not require `gnuplot`. The Fortran source files are based on the GPL-3.0 example code by Hans Fehr, Maurice Hofmann, and Fabian Kindermann for a baseline life-cycle endogenous labor model.

## MATLAB Plan

The MATLAB side will use VFI-Toolkit from:

```text
C:\Users\aledi\OneDrive\Documents\GitHub\VFIToolkit-matlab
```

Reference examples are available locally in `IntroToLifeCycleModels` and `IntroToOLGModels`, and online under the `vfitoolkit` GitHub organization.
