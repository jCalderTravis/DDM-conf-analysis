function figHandle = plotConfFrequencies(DSet, plotType, varargin)
% Plot the frequency of confidence reports falling into each confidence bin

% NOTE
% Code uses predefined limits to the axes that are not adjusted based on
% the data. It also always plots the number of conf reports in bins
% 1, 2, 3, and 4, even if these don't exist in the dataset. Code checks
% this to some extent.
assumedConfBins = [1, 2, 3, 4];

% INPUT
% varargin: Figure handle to plot onto 

if isempty(varargin)
    figHandle = figure;
else
    figHandle = varargin{1};
end

for iP = 1 : length(DSet.P)
    nonNanConf = ~isnan(DSet.P(iP).Data.ConfCat);
    assert(all(ismember(DSet.P(iP).Data.ConfCat(nonNanConf), ...
        assumedConfBins)))
end

for i = 1 : 2
    XVars(i).ProduceVar = @(Strcut) Strcut.ConfCat;
    XVars(i).NumBins = 'prebinned';
    XVars(i).EnforcedBins = assumedConfBins;
    
    PlotStyle.Xaxis(i).Ticks = assumedConfBins;
    PlotStyle.Xaxis(i).Lims = [0.8, 4.2];
end

XVars(1).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 0;
XVars(2).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 1;

PlotStyle.Xaxis(1).Title = {'Confidence bin', '{\bfFree response}'};
PlotStyle.Xaxis(2).Title = {'Confidence bin', '{\bfInterrogation}'};

YVars.ProduceVar = @(Strcut, incTrials) sum(incTrials);
YVars.FindIncludedTrials = @(Struct) ~isnan(Struct.Conf);

PlotStyle.Yaxis.Title = 'Number of reports';
PlotStyle.Yaxis.Ticks = 0:20:100;
PlotStyle.Yaxis.InvisibleTickLablels = [2, 4, 6];

Series(1).FindIncludedTrials = @(Struct) Struct.Acc == 1;
Series(2).FindIncludedTrials = @(Struct) Struct.Acc == 0;

PlotStyle.Data(1).Colour = mT_pickColour(5);
PlotStyle.Data(2).Colour = mT_pickColour(6);

PlotStyle.General = 'paper';

PlotStyle.Data(1).Name = 'Correct';
PlotStyle.Data(2).Name = 'Error';

PlotStyle.Data(1).PlotType = plotType;
PlotStyle.Data(2).PlotType = plotType;

figHandle = mT_plotVariableRelations(DSet, XVars, YVars, Series, ...
    PlotStyle, figHandle);




