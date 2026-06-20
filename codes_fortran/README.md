# Fortran Code

This folder contains the Fortran baseline for the life-cycle model with endogenous labor supply.

Main files:

- `sol_prog10_07.f90`: main program, model solution, distribution, aggregation, and output.
- `sol_prog10_07m.f90`: shared globals and model-specific functions.
- `toolbox.f90`: numerical and plotting utilities used by the model.
- `makefile_win`: Windows `nmake` build file for Intel `ifx`.

Build from this folder after initializing Intel oneAPI:

```powershell
nmake /f makefile_win
nmake /f makefile_win run
```

The run writes the table `output.out` in this folder. Plotting calls are currently commented out in `sol_prog10_07.f90` so the model does not require `gnuplot`.
