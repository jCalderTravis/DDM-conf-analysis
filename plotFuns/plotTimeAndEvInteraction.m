function figHandle = plotTimeAndEvInteraction(DSet, plotType, confType, ...
    evMeasure, figHandle, varargin) 
% Plot the interaction between time and evidence on confidence

% INPUT
% confType: 'raw' or 'binned'
% evMeasure: Which measure of evidnece to use? 'preResp' is currently the
% only option
% varargin{1}: If set to 'median' use median for averaging over participants.
% Otherwise set to 'mean' or don't use (default is 'mean'). Note in the case of
% 'median' error bars still reflect SEM, which doesn't really make sense.
% varargin{2}: scalar. Number of bins to use for plotting. 
% varargin{3}: bool. If true, supress any possible subplot lettering. 
%   Default false.

if nargin < 5
    figHandle = figure;
end

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotStat = varargin{1};
else
    plotStat = 'mean';
end

if (length(varargin) > 1) && (~isempty(varargin{2}))
    numBins = varargin{2};
else
    numBins = 10;
end

if (length(varargin) > 2) && (~isempty(varargin{3}))
    suppressLetters = varargin{3};
else
    suppressLetters = false;
end

assert(strcmp(evMeasure, 'preResp'))


%% Prep

% Check the function prepDataWrapper has already been used
assert(isfield(DSet.P(1).Data, 'TotalPreRespEv')) 

for iPtpnt = 1 : length(DSet.P)

    blockType = DSet.P(iPtpnt).Data.BlockType;
    evValue = abs(DSet.P(iPtpnt).Data.TotalPreRespEv);
    
    BinSettings.DataType = 'integer';
    BinSettings.BreakTies = false;
    BinSettings.Flip = false;
    BinSettings.EnforceZeroPoint = false;
    BinSettings.NumBins = 3;
    BinSettings.SepBinning = true;
    
    [DSet.P(iPtpnt).Data.EvidenceCat, ~, ~, ~] = ...
        mT_makeVarOrdinal(BinSettings, evValue, blockType, []);
end


%% Plot
% Add negligible noise to RTs to break ties
XVars(1).ProduceVar = @(Data) (Data.RtPrec + randn(size(Data.RtPrec))*0.00000001);
XVars(1).NumBins = numBins;
XVars(1).FindIncludedTrials = @(Data) Data.IsForcedResp == 0;

% Add negligible noise to RTs to break ties
XVars(2).ProduceVar = @(Data) (Data.RtPrec + randn(size(Data.RtPrec))*0.00000001);
XVars(2).NumBins = numBins;
XVars(2).FindIncludedTrials = @(Data) Data.IsForcedResp == 1;

if strcmp(confType, 'raw')
    YVars(1).ProduceVar = @(Data, incTrials) mean(Data.Conf(incTrials));
    PlotStyle.Yaxis.Title = 'Confidence';
elseif strcmp(confType, 'binned')
    YVars(1).ProduceVar = @(Data, incTrials) mean(Data.ConfCat(incTrials));
    PlotStyle.Yaxis.Ticks = 1.75:0.25:3.25;
    PlotStyle.Yaxis.InvisibleTickLablels = [1, 3, 5, 7];
    PlotStyle.Yaxis.Title = 'Binned confidence';
end

YVars(1).FindIncludedTrials = @(Data) ~isnan(Data.Conf);

Series(1).FindIncludedTrials = @(Struct) Struct.EvidenceCat == 1;
Series(2).FindIncludedTrials = @(Struct) Struct.EvidenceCat == 2;
Series(3).FindIncludedTrials = @(Struct) Struct.EvidenceCat == 3;

PlotStyle.General = 'paper';

PlotStyle.Legend.Title = 'Evidence';
PlotStyle.Data(1).Name = 'Low';
PlotStyle.Data(2).Name = 'Med';
PlotStyle.Data(3).Name = 'High';

PlotStyle.Data(1).PlotType = plotType;
PlotStyle.Data(2).PlotType = plotType;
PlotStyle.Data(3).PlotType = plotType;

PlotStyle.Data(1).Colour = mT_pickColour(5)*0.6;
PlotStyle.Data(2).Colour = mT_pickColour(5);
PlotStyle.Data(3).Colour = mT_pickColour(5)*1.4;

PlotStyle.Xaxis(1).Ticks = [0, 2, 4, 6, 8];
PlotStyle.Xaxis(1).Lims = [0, 8];
PlotStyle.Xaxis(2).Ticks = [0, 1, 2, 3, 4];
PlotStyle.Xaxis(2).Lims = [0, 4.5];
PlotStyle.Xaxis(1).Title = {'Response time (s)', '{\bf Free response}'};
PlotStyle.Xaxis(2).Title = {'Response time (s)', '{\bf Interrogation}'};

if ~suppressLetters
    PlotStyle.Annotate(1, 1).Text = 'A';
    PlotStyle.Annotate(1, 2).Text = 'B';
end

figHandle = mT_plotVariableRelations(DSet, XVars, YVars, Series, ...
    PlotStyle, figHandle, plotStat);
