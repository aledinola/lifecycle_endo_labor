function earnings = f_earnings(aprime, a, z, r, w, eff, pen, theta, nu, working)
%F_EARNINGS Efficiency units of labor supplied.
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
%   earnings  scalar, efficiency units of labor supplied

lab = f_labor(aprime, a, z, r, w, eff, pen, theta, nu, working);
earnings = eff * theta * z * lab;

end %end function
