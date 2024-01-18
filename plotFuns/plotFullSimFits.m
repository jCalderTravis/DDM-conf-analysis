function plotFullSimFits(saveDir, DSet, modelNum, plotStat, nameStr, ...
    numTrials, varargin)
% Make a range of plots after simulating a whole new dataset from fresh
% (not just confidence values)

% INPUT
% modelNum: scalar. Model to use, as ordered in DSet
% nameStr: str. This is crutial for avoiding overwriting previously saved 
%   plots. This string will be inserted into the default save filenames. 
%   The default file names with no additional text inserted are the always
%   the same regardless of the other inputs, e.g. model used.
% numTrials: scalar. Number of trials to simulate per participant.
% varargin{1}: str | empty. If string 'skipEvPlts', then code skips the
%   making of plots for effects of evidnece residuals
% varargin{2}: str | empty. If string 'skipRtPlots', then code skips making
%   some RT plots

if (~isempty(varargin)) && (~isempty(varargin{1})) ...
        && (strcmp(varargin{1}, 'skipEvPlts'))
    makeEvPlots = false;
    evPlotInstruct = varargin{1};
else
    makeEvPlots = true;
    evPlotInstruct = [];
end

if (length(varargin)>1) && (~isempty(varargin{2})) ...
        && (strcmp(varargin{2}, 'skipRtPlots'))
    makeAllRtPlots = false;
    rtPlotInstruct = varargin{2};
else
    makeAllRtPlots = true;
    rtPlotInstruct = [];
end

applMmodels = mT_findAppliedModels(DSet);
disp(['Running full simulation using the following model: ' ...
    applMmodels{modelNum}])

[~, FigureHandles] = compareModelAndDataFits(DSet, modelNum, ...
    'individual', false, plotStat, numTrials, ...
    evPlotInstruct, rtPlotInstruct);

if makeAllRtPlots
    figure(FigureHandles.ExtendModel_RtQuantiles)
    mT_exportNicePdf(15.9/2, 15.9/2, saveDir, ...
        ['ExtendModel_' nameStr 'RtQuantiles'])
end

figure(FigureHandles.ExtendModel_timeAndEv_rawConf)
mT_exportNicePdf(15.9/2, 15.9, saveDir, ...
    ['ExtendModel_' nameStr 'timeAndEv_rawConf'])

figure(FigureHandles.ExtendModel_timeAndEv_binnedConf)
mT_exportNicePdf(15.9/2, 15.9, saveDir, ...
    ['ExtendModel_' nameStr 'timeAndEv_binnedConf'])

figure(FigureHandles.ExtendModel_TimeAndEvTogether_rawConf)
mT_exportNicePdf(15.9/2, 15.9, saveDir, ...
    ['ExtendModel_' nameStr 'TimeAndEvTogether_rawConf'])

figure(FigureHandles.ExtendModel_TimeAndEvTogether_binnedConf)
mT_exportNicePdf(15.9/2, 15.9, saveDir, ...
    ['ExtendModel_' nameStr 'TimeAndEvTogether_binnedConf'])

figure(FigureHandles.ExtendModel_accAndConfWithRt)
mT_exportNicePdf(15.9/2, 15.9/2, saveDir, ...
    ['ExtendModel_' nameStr 'accAndConfWithRt'])

if makeEvPlots
    figure(FigureHandles.ExtendModel_evResiduals)
    mT_exportNicePdf(15.9, 15.9, saveDir, ...
        ['ExtendModel_' nameStr 'evResiduals'])
    
    % Need to change the axes for this figure from the default
    figure(FigureHandles.ExtendModel_evResiduals_noConf)
    for i = [1, 2]
        subplot(1, 2, i)
        ylim([-30, 40])
        yticks(-30:10:40)
        yticklabels({'-30', '', '', '0', '', '', '30', ''})
    end
    mT_exportNicePdf(15.9/2, 15.9, saveDir, ...
        ['ExtendModel_' nameStr 'evResiduals_noConf'])
end

close all



