function [PredDSet, FigHs] = compareTrueAndPredConfBins(DSet, ...
    modelNum, varargin)
% Compute model predictions for binned confidence data from RT, response and
% evidence

% INPUT
% varargin{1}: String. Plot using the 'mean' or 'median' accross 
%   participants. Always uses SEM so 'median' doesn't really make sense.
%   When 'median' is selected only a subset of plots is done. Default is 
%   'mean'.
% varargin{2}: str. Some options to specify only making a subset of plots

% OUTPUT
% FigHs: Structure containing figure handles for key figures

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotStat = varargin{1};
else
    plotStat = 'mean';
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    plotSubset = varargin{2};
else
    plotSubset = 'all';
end

% Simulate confidence from RT using the fitted param vals
PredDSet = simulateConfFromRtWrapper(DSet, modelNum);


%% Time to plot

if strcmp(plotSubset, 'all')
    if strcmp(plotStat, 'mean')
        plotter = @(ThisDSet, plotType, figH, numBins, noLetters) ...
            plotConfFrequencies(...
            ThisDSet, plotType, figH);
        TheseFigs = createPlots(plotter, ...
            DSet, 'scatter', ...
            PredDSet, 'errorShading');
        FigHs.ConfCount = TheseFigs;
    end
    
    plotter = @(ThisDSet, plotType, figH, numBins, noLetters) ...
        plotConfAgainstTimeAndEv(...
        ThisDSet, plotType, figH, 'binned', ...
        false, false, 'B', [], [], plotStat, numBins, [], noLetters);
    TheseFigs = createPlots(plotter, ...
        DSet, 'scatter', ...
        PredDSet, 'errorShading');
    FigHs.TimeAndEvSep = TheseFigs;
end

if any(strcmp(plotSubset, {'all', 'timeButNoEv'}))
    plotter = @(ThisDSet, plotType, figH, numBins, noLetters) ...
        plotConfAgainstTimeAndEv(...
        ThisDSet, plotType, figH, 'binned', ...
        false, false, 'B', 'noEv', [], plotStat, numBins, [], noLetters);
    TheseFigs = createPlots(plotter, ...
        DSet, 'scatter', ...
        PredDSet, 'errorShading');
    FigHs.TimeButNoEv = TheseFigs;
end

if strcmp(plotSubset, 'all')
    plotter = @(ThisDSet, plotType, figH, numBins, noLetters) ...
        plotTimeAndEvInteraction(...
            ThisDSet, plotType, 'binned', ...
            'preResp', figH, plotStat, numBins, noLetters);
    TheseFigs = createPlots(...
        plotter, ...
        DSet, 'scatter', ...
        PredDSet, 'errorShading');
    FigHs.TimeAndEvTogether = TheseFigs;
    
    if strcmp(plotStat, 'mean')
        plotter = @(ThisDSet, plotType, figH, numBins, noLetters) ...
            plotAccWithConf(...
            ThisDSet, plotType, 'binned', ...
            false, figH, numBins);
        TheseFigs = createPlots(...
            plotter, ...
            DSet, 'scatter', ...
            PredDSet, 'errorShading');
        FigHs.AccWithConf = TheseFigs;
    end
    
    
    EvDSet = convertToEvSet(DSet, true);
    PredEvDSet = convertToEvSet(PredDSet, true);
    
    plotter = @(ThisDSet, plotType, figH, numBins, noLetters) ...
        plotEvResidualsEffectWithTime(...
            ThisDSet, plotType, 'B', true, true, ...
            figH, [], plotStat, [], numBins, noLetters);
    TheseFigs = createPlots(...
        plotter, ...
        EvDSet, 'scatter', ...
        PredEvDSet, 'errorShading');
    FigHs.EvResiduals = TheseFigs;
end

end


function Figures = createPlots(plotter, DSet1, plotType1, ...
    DSet2, plotType2)

% NOTES
% For participant-level plots, scattered dots are always used for DSet1 and 
% a line for DSet2, regardless of plotType1 and plotType2

% INPUT
% plotter: function handle. Accepts ...
%       a DSet
%       plot type
%       figure handle 
%       numuber of bins to use
%       bool. If true, suppresses any sublot lettering (i.e. "A", "B",
%           ...)
%   produces a plot and returns the figure handle
% DSet2, plotType2: optional. Pass [] if don't want to use

% OUTPUT
% Figures: structs with the following fields...
%   avFig: Figure handle to the plot for average over participants
%   indFig: Figure handle to the plot for individual participants
%   combFig: Figure handle to plot with average over participants alongside
%       the data from some sample participants

[avFig, ptpntPlts] = makeAllSeperatePlots(plotter, DSet1, plotType1, ...
    DSet2, plotType2, true);

ptpntNumsToUse = [10, 20, 30];
figsToUse = avFig;
figLabels = {'Av'};
for iF = ptpntNumsToUse
    figLabels{end+1} = ['P' num2str(iF)];
end

Figures.combFig = mT_mergePlots([avFig,...
    ptpntPlts(ptpntNumsToUse(1)), ...
    ptpntPlts(ptpntNumsToUse(2)), ...
    ptpntPlts(ptpntNumsToUse(3))], ...
    'spotlight', [], figLabels);

for iPl = 1 : length(ptpntPlts) 
    if ismember(iPl, ptpntNumsToUse)
        continue % These are closed by mT_mergePlots
    end
    close(ptpntPlts(iPl))
end

end


function [avFig, ptpntPlts] = makeAllSeperatePlots(plotter, ...
    DSet1, plotType1, ...
    DSet2, plotType2, ...
    suppressSubplotLettering)

avFig = createAPlot(plotter, DSet1, plotType1, DSet2, plotType2, 10, ...
    suppressSubplotLettering);

% Participant-level plots
ptpntPlts = [];
assert(length(DSet1.P) == length(DSet2.P))
for iP = 1 : length(DSet1.P)
    ThisDSet1 = DSet1;
    ThisDSet1.P = ThisDSet1.P(iP);
    ThisDSet2 = DSet2;
    ThisDSet2.P = ThisDSet2.P(iP);
    ptpntPlts(iP) = createAPlot(plotter, ThisDSet1, 'scatterOnly', ...
        ThisDSet2, 'line', 2, suppressSubplotLettering);
end

end


function figH = createAPlot(plotter, DSet1, plotType1, ...
    DSet2, plotType2, numBins, suppressSubplotLettering)

figH = figure;
figH = plotter(DSet1, plotType1, figH, numBins, suppressSubplotLettering);

if isempty(DSet2) && isempty(plotType2)
    % Nothing to do
else
    figH = plotter(DSet2, plotType2, figH, numBins, ...
        suppressSubplotLettering);
end

end




