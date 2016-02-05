function [  ] = vco_plot_reaction_times( reaction_times )
%VCO_PLOT_REACTION_TIMES Plot reaction times along with Exgaussian fit

global PROJECT_SETUP

exgaussian_toolbox_path = fullfile(PROJECT_SETUP.MATLAB_LIB_DIR, 'exgaussian_tools');
addpath(exgaussian_toolbox_path);
exgaussian_params = struct;


exgfit = egfit(reaction_times);
exgaussian_params.mu = exgfit(1);
exgaussian_params.sigma = exgfit(2);
exgaussian_params.tau = exgfit(3);

%plot fit over actual values
figure('name', 'Reaction times')
histogram(reaction_times, 20, 'Normalization', 'pdf')
hold on
x = (min(reaction_times) - 100):(max(reaction_times) + 100);
plot(x, exgausspdf(exgaussian_params.mu, exgaussian_params.sigma, exgaussian_params.tau, x))
median_rt = median(reaction_times);
scatter(median_rt, exgausspdf(exgaussian_params.mu, exgaussian_params.sigma, exgaussian_params.tau, median_rt))
mean_rt = mean(reaction_times);
scatter(mean_rt, exgausspdf(exgaussian_params.mu, exgaussian_params.sigma, exgaussian_params.tau, mean_rt))

hold off
title('Reaction times along Ex-Gaussian fit');
xlabel('Reaction time [ms]');
ylabel('Probability density function estimate');
rmpath(exgaussian_toolbox_path);

end

