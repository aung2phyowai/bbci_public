function [ fig_hdl ] = vco_plot_complexity_ratings( metadata )
%VCO_PLOT_COMPLEXITY_RATINGS Plots the subjects complexity ratings

metadata.vco_pilot_run.complexity_ratings.Properties.RowNames = cellfun(@num2str, num2cell(1:size(metadata.vco_pilot_run.complexity_ratings,1)), 'UniformOutput', 0);
metadata.session.used_config.block_structure.Properties.RowNames = cellfun(@num2str, num2cell(1:size(metadata.session.used_config.block_structure, 1)), 'UniformOutput', 0);
complexity_ratings_joined = join(metadata.vco_pilot_run.complexity_ratings, metadata.session.used_config.block_structure, 'Keys', 'RowNames');
%remove familiarization seqs
complexity_ratings_joined = complexity_ratings_joined(complexity_ratings_joined.blockNo > 0, :);
simple_scene_ratings = complexity_ratings_joined.subject_complexity_rating(strcmp(complexity_ratings_joined.type, 'simple'));
complex_scene_ratings = complexity_ratings_joined.subject_complexity_rating(strcmp(complexity_ratings_joined.type, 'complex'));

fig_hdl = figure('Name', 'Complexity Ratings');
boxplot([simple_scene_ratings complex_scene_ratings], 'labels', {'simple', 'complex'})
title('Subject complexity ratings by sequence type')
xlabel('sequence type (label)')
ylabel('subject complexity rating')
ylim([1 10])
end

