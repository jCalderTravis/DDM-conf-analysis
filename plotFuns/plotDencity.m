function plotDencity(DSet)
% Plot the densities of RTs and confidence
% Concatinate all data. 

for iP = 1 : length(DSet.P)
    
    % First remove fields that can't be concatinated
    DSet.P(iP).Data = rmfield(DSet.P(iP).Data, {'Dots', 'DotsDiff'});
    ptpntData = struct2table(DSet.P(iP).Data);
    
    if iP == 1
        allData = ptpntData;
    else
        allData = [allData; ptpntData];
    end
end

DSet.P(2: end) = [];
DSet.P(1).Data = table2struct(allData, 'ToScalar', true);


% Specify plot variables
numBins = 200;

XVars(1).ProduceVar = @(st) st.RtPrec;
XVars(1).NumBins = numBins;

XVars(2).ProduceVar = @(st) st.Conf;
XVars(2).NumBins = numBins;

Rows(1).FindIncludedTrials = @(st) true;

Series(1).FindIncludedTrials = @(st) (st.IsForcedResp==0);
Series(2).FindIncludedTrials = @(st) (st.IsForcedResp==1);

PlotStyle.Data(1).Colour = mT_pickColour(1);
PlotStyle.Data(2).Colour = mT_pickColour(4);

PlotStyle.General = 'paper';

PlotStyle.Xaxis(1).Title = 'Response time (s)';
PlotStyle.Xaxis(1).Ticks = ...
    [0, 5, 10, 15];

PlotStyle.Xaxis(2).Title = 'Confidence';
PlotStyle.Xaxis(2).Ticks = [-90, 0, 90];

PlotStyle.Rows(1).Title = {'Probability density'};

PlotStyle.Data(1).Name = 'Free response';
PlotStyle.Data(2).Name = 'Interrogation';

PlotStyle.Annotate(1, 1).Text = 'A';
PlotStyle.Annotate(1, 2).Text = 'B';

PlotStyle.Scale = 10;

mT_plotDencities(DSet, XVars, Rows, Series, PlotStyle, 1);




