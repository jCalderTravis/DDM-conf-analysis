function plotFig = plotEvResidualsEffectWithTime(EvDSet, plotType, dataset, ...
    timeRelToOnset, excludeRespPlot, varargin)

% INPUT
% EvDSet: Provide a dataset converted to an evidence dataset with convertToEvSet
% dataset: 'B' for main dataset
% timeRelToOnset: Also plot using time relative to trial onset on the x-axis?
% excludeRespPlot: Don't plot the reverse correlation of evidence with
% response
% varagin{1}: Figure handle
% varagin{2}: If set to true, does not plot the effect of evidence on confidence
% varargin{3}: If set to 'median' use median for averaging over participants.
%   Otherwise set to 'mean' or don't use (default is 'mean'). Note in the case of
%   'median' error bars still reflect SEM, which doesn't really make sense.
% varargin{4}: Two element array specifying the start and end in seconds,
%   relative to response, of an area to shade in gray. Shading only done on 
%   the "Time relative to response" plot.
% varargin{5}: scalar. Number of bins to use for plotting. 
% varargin{6}: bool. If true, supress any possible subplot lettering. 
%   Default false.

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotFig = varargin{1};
else
    plotFig = figure;
end

if (length(varargin) > 1) && (~isempty(varargin{2}))
    excludeConfPlot = varargin{2};
else
    excludeConfPlot = false;
end

if (length(varargin) > 2) && (~isempty(varargin{3}))
    plotStat = varargin{3};
else
    plotStat = 'mean';
end

if (length(varargin) > 3) && (~isempty(varargin{4}))
    shadedRegion = varargin{4};
else
    shadedRegion = 'none';
end

if (length(varargin) > 4) && (~isempty(varargin{5}))
    numBins = varargin{5};
else
    numBins = 10;
end

if (length(varargin) > 5) && (~isempty(varargin{6}))
    suppressLetters = varargin{6};
else
    suppressLetters = false;
end

if timeRelToOnset
    XVars(1).ProduceVar = @(Data) Data.Time;
    XVars(1).NumBins = numBins;
    posOfTimeRelResp = 2;
else
    posOfTimeRelResp = 1;
end

XVars(posOfTimeRelResp).ProduceVar = @(Data) Data.TimeRelativeToResp;
XVars(posOfTimeRelResp).NumBins = numBins;

YVars(1).ProduceVar = @(Data, incSamples) mean(Data.DiffDemeanedForResp(incSamples));
YVars(2).ProduceVar ...
    = @(Data, incSamples) findRankCorrelation( ...
        Data.DiffDemeanedForResp(incSamples), Data.Conf(incSamples));

YVars(1).FindIncludedTrials = @(Data) ~isnan(Data.Conf);
YVars(2).FindIncludedTrials = @(Data) ~isnan(Data.Conf);

if strcmp(dataset, 'B')
    Series(1).FindIncludedTrials = @(Data) Data.IsForcedResp == 0;
    Series(2).FindIncludedTrials = @(Data) Data.IsForcedResp == 1;
    
    PlotStyle.Data(1).Colour = mT_pickColour(1);
    PlotStyle.Data(2).Colour = mT_pickColour(4);
end

PlotStyle.General = 'paper';

PlotStyle.Xaxis(posOfTimeRelResp).Title = 'Time relative to response (s)';
if timeRelToOnset
    PlotStyle.Xaxis(1).Title = 'Time relative to trial onset (s)';
end

PlotStyle.Yaxis(1).Title = {'Evidence fluctuations', 'for choice (dots)'};
PlotStyle.Yaxis(1).RefVal = 0;

PlotStyle.Yaxis(2).Title = {'Evidence-confidence' 'correlation'};
PlotStyle.Yaxis(2).RefVal = 0;

PlotStyle.Data(1).PlotType = plotType;
PlotStyle.Data(2).PlotType = plotType;

if strcmp(dataset, 'B')
    PlotStyle.Data(1).Name = 'Free response';
    PlotStyle.Data(2).Name = 'Interrogation';
    
    if ~suppressLetters
        PlotStyle.Annotate(1, 1).Text = 'A';
        PlotStyle.Annotate(1, 2).Text = 'B';
        PlotStyle.Annotate(2, 1).Text = 'C';
        PlotStyle.Annotate(2, 2).Text = 'D';
    end
    
    PlotStyle.Xaxis(2).Ticks = -6:0;
    PlotStyle.Xaxis(2).InvisibleTickLablels = 2:2:6;
    
    PlotStyle.Xaxis(1).Ticks = 0:6;
    PlotStyle.Xaxis(1).InvisibleTickLablels = 2:2:6;
    
    PlotStyle.Yaxis(1).Ticks = linspace(-10, 40, 6);
    
    PlotStyle.Yaxis(2).Ticks = linspace(-0.01, 0.04, 6);
    PlotStyle.Yaxis(2).InvisibleTickLablels = 1:2:5;
    PlotStyle.Yaxis(2).Lims = [-0.015, 0.04];    
end

if excludeRespPlot
    PlotStyle.Yaxis(1) = PlotStyle.Yaxis(2);
    PlotStyle.Yaxis(2) = [];
    
    YVars(1) = YVars(2);
    YVars(2) = [];
end

if excludeConfPlot
    PlotStyle.Yaxis(2) = [];
    YVars(2) = [];
end

figHandle = mT_plotVariableRelations(EvDSet, XVars, YVars, Series, ...
    PlotStyle, plotFig, plotStat);

% Draw shading if requested
if ~strcmp(shadedRegion, 'none')
    
    % Work out the numeber of subplots in the x and y directions
    xSubplots = length(XVars);
    ySubplots = length(YVars);
    
    % Matlab uses a particualar numbering system for subplots. Find an array
    % that converts from matrix index to matlab subplot number.
    subplotIdx = NaN(xSubplots, ySubplots);
    subplotIdx(:) = 1 : length(subplotIdx(:));
    subplotIdx = subplotIdx';
    
    % Add shading to all time relative to response plots
    for iYPlt = 1 : ySubplots
        subplot(ySubplots, xSubplots, ...
            subplotIdx(iYPlt, posOfTimeRelResp));
        
        yLims = ylim();
        fill([shadedRegion(1), shadedRegion(1), ...
            shadedRegion(2), shadedRegion(2)], ...
            [yLims, fliplr(yLims)], ...
            [0, 0, 0], 'Edgecolor','none', ...
            'FaceAlpha',.10);
    end
    
    % Update legend
    legObj = findobj(gcf, 'Type', 'Legend');
    legObj.String{end} = 'Est. pipeline';
end

end


function corrCoef = findRankCorrelation(dotsDiff, confidence)
% Find the rank correlation between two variable

corrCoef = corr(dotsDiff, confidence, 'Type', 'Kendall');

if size(corrCoef) ~= [1, 1]; error('Bug'); end

end
