function lab = f_labor(aprime, a, z, r, w, eff, pen, theta, nu, working)
%F_LABOR Closed-form labor supply.
% Inputs:
%   aprime    scalar, next-period assets
%   a         scalar, current assets
%   z         scalar, productivity shock
%   r, w      scalars, interest rate and wage
%   eff       scalar, age-efficiency profile value
%   pen       scalar, pension transfer
%   theta     scalar, permanent productivity type
%   nu        scalar, consumption share in utility
%   working   scalar, indicator for working age
% Output:
%   lab       scalar, labor supply in [0,1)

if working > 0.5
    wage = w * eff * theta * z;
    available = (1 + r) * a + pen;
    lab = nu + (1 - nu) * (aprime - available) / wage;
    lab = min(max(lab, 0), 1 - 1e-10);
else
    lab = 0;
end

end %end function
