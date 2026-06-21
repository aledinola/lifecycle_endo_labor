function f_plot_moments(moments, figure_dir)
%F_PLOT_MOMENTS Plot selected model moments by age and save a PNG.
% Inputs:
%   moments     struct, age profiles from f_model_moments
%   figure_dir  char/string, output directory
% Output:
%   none; writes age_profiles.png to figure_dir

if ~exist(figure_dir, 'dir')
    mkdir(figure_dir);
end

ages = 20 + moments.age;
fig = figure('Color', 'w');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile
plot(ages, moments.consumption, 'LineWidth', 1.5)
hold on
plot(ages, moments.earnings + moments.pension, 'LineWidth', 1.5)
xlabel('Age')
legend({'Consumption', 'Earnings + pension'}, 'Location', 'best')
grid on

nexttile
plot(ages, moments.hours, 'LineWidth', 1.5)
xlabel('Age')
ylabel('Hours')
grid on

nexttile
plot(ages, moments.assets, 'LineWidth', 1.5)
xlabel('Age')
ylabel('Assets')
grid on

nexttile
plot(ages, moments.cv_consumption, 'LineWidth', 1.5)
hold on
plot(ages, moments.cv_hours, 'LineWidth', 1.5)
plot(ages, moments.cv_earnings, 'LineWidth', 1.5)
xlabel('Age')
legend({'CV(C)', 'CV(L)', 'CV(Y)'}, 'Location', 'best')
grid on

saveas(fig, fullfile(figure_dir, 'age_profiles.png'));

end %end function
