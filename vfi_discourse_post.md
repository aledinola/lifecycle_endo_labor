# Comparing Fortran and VFI-Toolkit for a finite-horizon life-cycle model with endogenous labor

I have been working on a small replication exercise comparing a Fortran
implementation and a MATLAB/VFI-Toolkit implementation of the same
finite-horizon life-cycle model with endogenous labor supply.

The model has assets $a$, an exogenous Markov productivity shock $\eta$, age
$j$, and a permanent productivity type $\theta$. The household chooses
next-period assets $a'$ and labor $l$. Labor is endogenous, but conditional on
$a'$ it has a closed-form solution, so in the VFI-Toolkit implementation I do
not declare labor as a separate $d$ decision grid. Instead the return function
uses the action-state inputs $(a',a,\eta)$ and computes labor internally:

$$
l(a',a,\eta,j,\theta)
= \min\left\{\max\left\{
\nu + (1-\nu)\frac{a' - [(1+r)a+pen_j]}{w e_j \theta \eta},
0\right\}, 1-10^{-10}\right\}
$$

for working ages, and $l=0$ in retirement.

The replication code is here:

https://github.com/aledinola/lifecycle_endo_labor

The Fortran code is in `codes_fortran/`. The MATLAB/VFI-Toolkit code is in
`codes_matlab/`. The model description and timing table are in `tex_pdf/`.

## Runtime comparison

The table below reports the current runtime decomposition. The Fortran code is
compiled with Intel oneAPI `ifx` using `/O2`. The MATLAB code uses the
VFI-Toolkit finite-horizon routines with the toolkit's GPU path when available.

<table>
  <thead>
    <tr>
      <th>Step</th>
      <th style="text-align:right">Fortran (s)</th>
      <th style="text-align:right">MATLAB/VFI-Toolkit (s)</th>
      <th style="text-align:right">MATLAB/Fortran</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>solve_household</code> / VFI</td>
      <td style="text-align:right">0.182225</td>
      <td style="text-align:right">0.896763</td>
      <td style="text-align:right">4.92x</td>
    </tr>
    <tr>
      <td>Distribution</td>
      <td style="text-align:right">0.013436</td>
      <td style="text-align:right">0.077600</td>
      <td style="text-align:right">5.78x</td>
    </tr>
    <tr>
      <td>Aggregation / model moments</td>
      <td style="text-align:right">0.001490</td>
      <td style="text-align:right">2.965766</td>
      <td style="text-align:right">1,990.45x</td>
    </tr>
    <tr>
      <td>Total</td>
      <td style="text-align:right">0.197152</td>
      <td style="text-align:right">3.940129</td>
      <td style="text-align:right">19.99x</td>
    </tr>
  </tbody>
</table>

Overall, the toolkit implementation is about 20 times slower than the Fortran
implementation in this test. However, most of the total difference comes from
the calculation of model moments, not from the value-function iteration itself.

The VFI step is slower by about half an order of magnitude:

$$
\log_{10}(0.896763/0.182225) \approx 0.69.
$$

The distribution step is similar:

$$
\log_{10}(0.077600/0.013436) \approx 0.76.
$$

By contrast, the model-moment step is slower by more than three orders of
magnitude:

$$
\log_{10}(2.965766/0.001490) \approx 3.30.
$$

In levels, the aggregation/model-moment step accounts for about 79 percent of
the total MATLAB-minus-Fortran runtime gap in this run.

## Issue with age-conditional standard deviations

One discrepancy I ran into concerns standard deviations conditional on age when
using permanent types. The toolkit output for grouped age profiles gave means
that looked fine, but the grouped standard deviations conditional on age did
not match the statistic I needed for the comparison with Fortran.

In particular, I wanted the standard deviation of an object $x$ conditional on
age $j$, pooling across permanent types $\theta_i$. What worked was to use the
toolkit's per-type age statistics and then combine them manually using the law
of total variance:

$$
\operatorname{Var}(x \mid j)
= \sum_i p_i
\left[
\operatorname{Var}(x \mid j,\theta_i)
+ \left(E[x \mid j,\theta_i] - E[x \mid j]\right)^2
\right].
$$

Then

$$
\operatorname{SD}(x \mid j) = \sqrt{\operatorname{Var}(x \mid j)}.
$$

This manual grouped-standard-deviation calculation is implemented in
`codes_matlab/f_model_moments.m`. It uses the toolkit-generated per-type means
and standard deviations, gathers the age statistics once, and then constructs
the grouped standard deviation outside the toolkit profile object.

I am posting this partly to document the comparison, and partly to ask whether
there is a better toolkit-native way to request this exact age-conditional,
permanent-type-pooled standard deviation.
