function [SimDSet, FigureHandles] = compareModelAndDataFits(DSet, ...
    modelNum, simType, estLapses, varargin)
% Make plots for the effect of response time, and the effect of evidence on 
% confidence, comparing real data model.

% NOTES
% Assumes same dots dist used in all blocks.

% INPUT
% modelNum: The fit results for this model will be used to generate the plots'
% "model" data.
% simType: Use 'individual' to simulate each participant with their own best
% fitting params, or 'median' to simulate each participant using the median 
% parameter values accros participants.
% estLapses: If set to true code additionally estimates the response lapse rate,
% and courrupts responses accordingly.
% varargin{1}: String. Plot using the 'mean' or 'median' accross 
%   participants. Always uses SEM so 'median' doesn't really make sense.
%   When 'median' is selected only a subset of plots is done. Default is 
%   'mean'.
% varargin{2}: scalar. Number of trials to simulate per participant.
% varargin{3}: str | empty. If string 'skipEvPlts', then code skips the
%   making of plots for effects of evidnece residuals
% varargin{4}: str | empty. If string 'skipRtPlots', then code skips making
%   some RT plots.

% OUTPUT
% FigureHandles: Structure containing figure handles for key figures

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotStat = varargin{1};
else
    plotStat = 'mean';
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    numTrials = varargin{2};
else
    numTrials = 640*10;
end

if (length(varargin)>2) && (~isempty(varargin{3})) ...
        && (strcmp(varargin{3}, 'skipEvPlts'))
    makeEvPlots = false;
else
    makeEvPlots = true;
end

if (length(varargin)>3) && (~isempty(varargin{4})) ...
        && (strcmp(varargin{4}, 'skipRtPlots'))
    makeAllRtPlots = false;
else
    makeAllRtPlots = true;
end

%% Simulate data

Settings.TotalTrials = numTrials;
SimDSet = simulateDSetBasedOnReal(DSet, modelNum, Settings, simType, estLapses);
SimDSet = prepDataWrapper(SimDSet, DSet.FitSpec.NumBins, false);


% Time to plot
if makeAllRtPlots
    fig = figure;
    plotRtQuantiles(DSet, 'all', 'scatter-O', fig, plotStat)
    plotRtQuantiles(SimDSet, 'all', 'line', fig, plotStat)
    plotRtQuantiles(SimDSet, 'all', 'scatter-X', fig, plotStat)
    FigureHandles.ExtendModel_RtQuantiles = fig;
end

figA = figure;
figA = plotConfAgainstTimeAndEv(DSet, 'scatter', figA, 'raw', ...
    false, false, 'B', [], [], plotStat);
figA = plotConfAgainstTimeAndEv(SimDSet, 'errorShading', figA, 'raw', ...
    false, false, 'B', [], [], plotStat);
FigureHandles.ExtendModel_timeAndEv_rawConf = figA;

figA = figure;
figA = plotConfAgainstTimeAndEv(DSet, 'scatter', figA, 'binned', ...
    false, false, 'B', [], [], plotStat);
figA = plotConfAgainstTimeAndEv(SimDSet, 'errorShading', figA, 'binned', ....
    false, false, 'B', [], [], plotStat);
FigureHandles.ExtendModel_timeAndEv_binnedConf = figA;

figC = figure;
figC = plotTimeAndEvInteraction(DSet, 'scatter', 'raw', ...
    'preResp', figC, plotStat);
figC = plotTimeAndEvInteraction(SimDSet, 'errorShading', 'raw', ...
    'preResp', figC, plotStat);
FigureHandles.ExtendModel_TimeAndEvTogether_rawConf = figC;

figD = figure;
figD = plotTimeAndEvInteraction(DSet, 'scatter', 'binned', ...
    'preResp', figD, plotStat);
figD = plotTimeAndEvInteraction(SimDSet, 'errorShading', 'binned', ...
    'preResp', figD, plotStat);
FigureHandles.ExtendModel_TimeAndEvTogether_binnedConf = figD;

figC = figure;
figC = plotAccAndConfWithRt(DSet, 'scatter', 'B', true, figC, plotStat);
figC = plotAccAndConfWithRt(SimDSet, 'errorShading', 'B', true, figC, plotStat);
FigureHandles.ExtendModel_accAndConfWithRt = figC;

if makeEvPlots
    figB = figure;
    figL = figure;
    EvDSet = convertToEvSet(DSet, true);
    PredEvDSet = convertToEvSet(SimDSet, true);
    figB = plotEvResidualsEffectWithTime(EvDSet, 'scatter', 'B', true, ...
        false, figB, [], plotStat);
    figL = plotEvResidualsEffectWithTime(EvDSet, 'scatter', 'B', true, ...
        false, figL, true, plotStat);
    
    % Add negligible amount of noise to break ties
    for iP = 1 : length(PredEvDSet.P)
        PredEvDSet.P(iP).Data.Time = PredEvDSet.P(iP).Data.Time ...
            + (randn(length(PredEvDSet.P(iP).Data.Time), 1)*0.0000001);
        PredEvDSet.P(iP).Data.TimeRelativeToResp = PredEvDSet.P(iP).Data.TimeRelativeToResp ...
            + (randn(length(PredEvDSet.P(iP).Data.Time), 1)*0.0000001);
    end
    
    figB = plotEvResidualsEffectWithTime(PredEvDSet, 'errorShading', 'B', ...
        true, false, figB, [], plotStat);
    FigureHandles.ExtendModel_evResiduals = figB;
    
    figL = plotEvResidualsEffectWithTime(PredEvDSet, 'errorShading', 'B', ...
        true, false, figL, true, plotStat);
    FigureHandles.ExtendModel_evResiduals_noConf = figL;
end

end


