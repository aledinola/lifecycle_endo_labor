function [cons, lab] = f_consumption(aprime, a, z, r, w, eff, pen, theta, nu, working)
%F_CONSUMPTION Consumption implied by savings and closed-form labor.
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
% Outputs:
%   cons      scalar, consumption
%   lab       scalar, labor supply

lab = f_labor(aprime, a, z, r, w, eff, pen, theta, nu, working);
wage      = w * eff * theta * z;
available = (1 + r) * a + pen;
cons      = available + wage * lab - aprime;

end %end function
