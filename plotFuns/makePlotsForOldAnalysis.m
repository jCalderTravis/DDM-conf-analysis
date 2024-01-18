function evEffectFig = makePlotsForOldAnalysis(paramResults, dataset)
% Make the plots associated with the old analysis pipeline

% INPUT
% paramResults: Results produced by mT_analyseParams after using collectParamVals
% on analyseDataset (see function runStatistics for the full pipeline)
% dataset:  'B' for main dataset

%% Plot the parameter results
figure

for iBlockType = [1 2]
    
    if isempty(paramResults{iBlockType})
        continue
    end
    
    subplot(2, 1, iBlockType)
    title(['Block type ' num2str(iBlockType)])
    hold on
    
    paramNames = paramResults{iBlockType}{:, 1};
    
    % Below, we only want to look at predictors which were included in the model
    incPreds = ~isnan(paramResults{iBlockType}{:, 6});
    paramNames = paramNames(incPreds);
  
    bar(1 : length(paramNames), paramResults{iBlockType}{incPreds, 6})
    set(gca, 'XTick', 1 : length(paramNames))
    set(gca, 'xticklabel', paramNames)
    
    negErrors = paramResults{iBlockType}{incPreds, 6} - ...
        paramResults{iBlockType}{incPreds, 7};
    posErrors = paramResults{iBlockType}{incPreds, 8} - ...
        paramResults{iBlockType}{incPreds, 6};
    
    errorbar(1 : length(paramNames), paramResults{iBlockType}{incPreds, 6}, ...
        -negErrors, posErrors, '.')
end


%% Effect of time
figure
hold on
title('Time coefficient')

% Find the relevant row in the relevant results table
if strcmp(dataset, 'B')
    relRow = @(column) ...
        [paramResults{1, 1}{5, column}, ...
        paramResults{2, 1}{5, column}];
end

barChart = bar([1 2], relRow(6));

set(gca, 'XTick', [1, 2])
barChart.FaceColor = [0, 0.093, 0.275];
ax = gca;
ax.LineWidth = 7.5;
ax.FontSize = 40;
ax.XLim = [0.4, 2.6];
ax.XAxisLocation = 'origin';

if strcmp(dataset, 'B')
    set(gca, 'xticklabel', {'Free resp', 'Forced resp'})
end

% Error bars
negErrors = relRow(6) - relRow(7);
posErrors = relRow(8) - relRow(6);

eBar = errorbar([1 2], relRow(6), -negErrors, posErrors, '.');
eBar.LineWidth = 16;
eBar.CapSize = 60;


%% Effect of evidence

evEffectFig = figure('units','normalized','outerposition',[0 0 1 1]);
hold on
    
% Find the relevant row in the relevant results table
if strcmp(dataset, 'B')
    relRow = @(column) ...
        [paramResults{1, 1}{9, column}, ...
        paramResults{2, 1}{9, column}, ...
        paramResults{1, 1}{10, column}, ...
        paramResults{2, 1}{10, column}];
    
    plotLocations = [1, 2, 4, 5];
end

plotColours = {mT_pickColour(1), mT_pickColour(4)};
barData = relRow(6);

% Error bars
negErrorLocation = relRow(7);
negErrors = barData(:) -  negErrorLocation(:);

posErrorLocation = relRow(8);
posErrors = posErrorLocation(:) - barData(:);
    
assert(all(round(posErrors, 10) == round(negErrors, 10)))
eBar = errorbar(plotLocations, barData(:), negErrors, posErrors, '.');

eBar.LineWidth = 1;
eBar.CapSize = 15;
eBar.Color = [0, 0, 0];

% Bars
allBars = cell(length(barData), 1);
for iBar = 1 : length(barData)

    barChart = bar(plotLocations(iBar), barData(iBar));

    barChart.FaceColor = plotColours{mod(iBar+1, 2) +1};
    barChart.BarWidth = 1;
    barChart.EdgeColor = 'none';

    allBars{iBar} = barChart;
end

if strcmp(dataset, 'B')
    set(gca, 'XTick', [1.5, 4.5])
    set(gca, 'xticklabel', {'Pre-decision', 'Pipeline'})
    xlabel('Evidence')
    ylabel({'Effect on conf.', '(regression coefficient)'})
end

ax = gca;
ax.LineWidth = 1;
ax.FontSize = 10;
ax.XAxisLocation = 'origin';
set(ax, 'TickDir', 'out')

if strcmp(dataset, 'B')
    legend([allBars{1}, allBars{2}], 'Free response', 'Interrogation')
    legend box off
end


%% Plot results from both block types on one plot
figure
if strcmp(dataset, 'B')
    bar([paramResults{1}{:, 6}, paramResults{2}{:, 6}])
end

xticklabels(paramResults{2}{:, 1});

