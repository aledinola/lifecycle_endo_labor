function utility = f_ReturnFn(aprime, a, z, r, w, eff, pen, theta, nu, egam, working)
%F_RETURNFN Current utility for VFI-Toolkit.
% Inputs:
%   aprime       scalar, next-period assets
%   a            scalar, current assets
%   z            scalar, productivity shock
%   r, w         scalars, interest rate and wage
%   eff          scalar, age-efficiency profile value
%   pen          scalar, pension transfer
%   theta        scalar, permanent productivity type
%   nu           scalar, consumption share in utility
%   egam         scalar, CRRA exponent
%   working      scalar, indicator for working age
% Output:
%   utility      scalar, current payoff

[cons, lab] = f_consumption(aprime, a, z, r, w, eff, pen, theta, nu, working);

if cons > 0
    utility = ((cons^nu * (1 - lab)^(1 - nu))^egam) / egam;
else
    utility = -Inf;
end

end %end function
