function income = f_income(aprime, a, z, r, w, eff, pen, theta, nu, working)
%F_INCOME Labor income plus asset income, excluding pension.
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
%   income    scalar, labor income plus asset income

earnings = f_earnings(aprime, a, z, r, w, eff, pen, theta, nu, working);
income = w * earnings + r * a;

end %end function
