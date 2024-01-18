function figHandle = plotAccAndConfWithRt(DSet, plotType, dataset, ...
    hideConf, figHandle, varargin) 
% Plot changes in accuracy and binned confidence with response time.

% INPUT
% dataset: 'B' for the standard dataset
% hideConf: Hide the plot for confidence
% varargin{1}: If set to 'median' use median for averaging over participants.
% Otherwise set to 'mean' or don't use (default is 'mean'). Note in the case of
% 'median' error bars still reflect SEM, which doesn't really make sense.

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotStat = varargin{1};
else
    plotStat = 'mean';
end

% Add negligible noise to RTs to break ties
XVars.ProduceVar = @(Data) (Data.RtPrec + ...
    (randn(size(Data.RtPrec))*0.00000001));
XVars.NumBins = 10;

YVars(1).ProduceVar = @(Strcut, incTrials) mean(Strcut.Acc(incTrials));
YVars(1).FindIncludedTrials = @(Struct) ~isnan(Struct.Conf);

if ~hideConf
    YVars(2).ProduceVar = @(Strcut, incTrials) mean(Strcut.ConfCat(incTrials));
    YVars(2).FindIncludedTrials = @(Struct) ~isnan(Struct.Conf);
end

PlotStyle.General = 'paper';

if strcmp(dataset, 'A')
    Series(1).FindIncludedTrials = @(Struct) Struct.BlockType == 2;
    PlotStyle.Xaxis.Ticks = [0, 1, 2, 3];
    
    PlotStyle.Yaxis(1).Ticks = linspace(0.7, 0.9, 5);
    PlotStyle.Yaxis(1).InvisibleTickLablels = [2, 4];
    
    PlotStyle.Yaxis(2).Ticks = linspace(2, 3.2, 7);
    PlotStyle.Yaxis(2).InvisibleTickLablels = [2, 3, 5, 6];
    
elseif strcmp(dataset, 'B')
    Series(1).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 0;
    Series(2).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 1;
    
    PlotStyle.Data(1).Name = 'Free response';
    PlotStyle.Data(2).Name = 'Interrogation';
    
    PlotStyle.Data(1).Colour = mT_pickColour(1);
    PlotStyle.Data(2).Colour = mT_pickColour(4);
    
    PlotStyle.Xaxis.Ticks = 0:6;
    PlotStyle.Xaxis(1).InvisibleTickLablels = 2:2:6;
    
    PlotStyle.Yaxis(1).Ticks = linspace(0.65, 0.9, 6);
    
    PlotStyle.Yaxis(2).Ticks = linspace(2, 3.2, 7);
    PlotStyle.Yaxis(2).InvisibleTickLablels = [2, 3, 5, 6];
 
elseif strcmp(dataset, 'C')
    XVars.NumBins = 4;
    
    Series(1).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 0;
    Series(2).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 1;
    
    PlotStyle.Data(1).Name = 'Free response';
    PlotStyle.Data(2).Name = 'Interrogation';
 
    PlotStyle.Data(1).Colour = mT_pickColour(1);
    PlotStyle.Data(2).Colour = mT_pickColour(4);
end

PlotStyle.Data(1).PlotType = plotType;
PlotStyle.Data(2).PlotType = plotType;

PlotStyle.Xaxis.Title = 'Response time (s)';

PlotStyle.Yaxis(1).Title = 'Accuracy';
PlotStyle.Yaxis(2).Title = 'Binned confidence';

if ~hideConf
    PlotStyle.Annotate(1, 1).Text = 'A';
    PlotStyle.Annotate(2, 1).Text = 'B';
end


figHandle = mT_plotVariableRelations(DSet, XVars, YVars, Series, ...
    PlotStyle, figHandle, plotStat);