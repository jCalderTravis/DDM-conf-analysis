function makePlotsForEmpiricalPaper(varargin)
% By default plots produced will be saved in a subfolder of the folder in
% which this function is located.

% INPUT
% varargin{1}: String. Plot using the 'mean' or 'median' accross 
%   participants. Deafault is 'mean'. The 'median' option is currently
%   untested and has not been carefully checked. Always uses SEM so 
%   'median' doesn't really make sense. When 'median' is selected only a 
%   subset of plots is done.
% varargin{2}: String. Provide a directory to save in a different location
%   to usual. No trailing slash.

baseCodeDir = mfilename('fullpath');
[baseCodeDir, ~, ~] = fileparts(baseCodeDir);

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotStat = varargin{1};
else
    plotStat = 'mean';
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    saveDir = varargin{2};
else
    saveDir = fullfile(baseCodeDir, 'PlotsAndResults');
    mkdir(saveDir)
end

baseDataDir = load(fullfile(baseCodeDir, 'confDataAndFitDir.mat'));
baseDataDir = baseDataDir.dataDir;

RealData = fullfile(baseDataDir, 'RealData', '_standardFormatData.mat');
CrossValidationFits = fullfile(baseDataDir, 'CrossValidationFits');
FullDataSetFits = fullfile(baseDataDir, 'FullDataSetFits');
RegularisedFits = fullfile(baseDataDir, 'RegularisedFits');
RegularisedCvFits = fullfile(baseDataDir, 'RegularisedCvFits');
modelRecovFolder = fullfile(baseDataDir, 'ModelRecov');

modelNames = {'0', 'V', 'D', 'VD', 'VC', 'VDC', 'M', 'VM', 'DM', 'VDM'};
origNames = {   'NDscFlatNoneSameMvar',...
                'NDscFlatDvarSameMvar',...
                'NDscSlpeNoneSameMvar',...
                'NDscSlpeDvarSameMvar',...
                'TrDsFlatDvarSameMvar',...
                'TrDsSlpeDvarSameMvar',...
                'FaDsFlatNoneSameMvar',...
                'FaDsFlatDvarSameMvar',...
                'FaDsSlpeNoneSameMvar',...
                'FaDsSlpeDvarSameMvar'};


%% Illustrations
% dispMsg('Illustrations')
% 
% bayesianConfidenceIllustration('rawEv');
% mT_exportNicePdf(15.9, 15.9, saveDir, 'confIllustration_rawEv')
% 
% bayesianConfidenceIllustration('pCorrect');
% mT_exportNicePdf(15.9, 15.9, saveDir, 'confIllustration_pCorrect')
% 
% bayesianConfidenceIllustration('logPostRatioForChoice');
% mT_exportNicePdf(15.9, 15.9, saveDir, 'confIllustration_logPostRatio')
% 
% bayesianConfidenceIllustration('logPostRatioForChoice2');
% mT_exportNicePdf(15.9, 15.9, saveDir, 'confIllustration_logPostRatio2')
% 
% bayesianConfidenceIllustration('logPostRatioForChoice', 'full');
% mT_exportNicePdf(15.9, 15.9, saveDir, ...
%     'confIllustration_logPostRatio_fullRange')
% 
% bayesianConfidenceIllustration('logPostRatioForChoice2', 'full');
% mT_exportNicePdf(15.9, 15.9, saveDir, ...
%     'confIllustration_logPostRatio2_fullRange')
% 
% figure
% x = -100:0.01:100;
% y = normpdf(x, 0, 20);
% plot(x, y)
% mT_exportNicePdf(15.9, 15.9, saveDir, 'confIllustration_normalDist')
% 
% 
% %% Basic data plots
% dispMsg('Real data plots')
% 
% if strcmp(plotStat, 'mean')
%     LoadedFiles = load(RealData);
%     DSet = LoadedFiles.DSet;
% 
%     plotDencity(DSet)
%     mT_exportNicePdf(15.9/2, 15.9, saveDir, 'expB_dencities')
%     close all
% end
% 
% LoadedFiles = load(RealData);
% DSet = LoadedFiles.DSet;
% DSet = prepDataWrapper(DSet, 4, true);
% 
% figHandle = figure;
% for plotType = {'scatter', 'line'}
%     figHandle = plotConfAgainstTimeAndEv(DSet, plotType{1}, figHandle, ...
%         'binned', false, false, 'B', 'noEv', [], plotStat, [], true);
% end
% mT_exportNicePdf(15.9/2, 15.9/2, saveDir, 'confTimeMidpointInteraction')
% close all
% 
% if strcmp(plotStat, 'mean')
%     figHandle = figure;
%     plotConfFrequencies(DSet, 'scatter', figHandle);
% end
% 
% figHandle = figure;
% figHandle = plotAccAndConfWithRt(DSet, 'scatter', 'B', false, ...
%     figHandle, plotStat);
% plotAccAndConfWithRt(DSet, 'line', 'B', false, ...
%     figHandle, plotStat);
% mT_exportNicePdf(15.9, 15.9/2, saveDir, 'expB_combinedTime')
% close all
% 
% % Plots but looking at raw confidence instead of binned conf
% f = figure;
% plotConfAgainstTimeAndEv(DSet, 'scatter', f, 'raw', false, false, 'B')
% mT_exportNicePdf(15.9, 15.9/2, saveDir, 'expB_rawConfEffects')
% close all
% 
% 
% %% Qualitative analysis
% dispMsg('Quantiative analysis')
% if strcmp(plotStat, 'mean')
%     [medianNonDecis, evEffectFig] = runStatistics(DSet);
%     figure(evEffectFig)
%     mT_exportNicePdf(15.9/2, 15.9*(7/12), saveDir, 'expB_evEffectCoefs')
%     close all
% end
% 
% 
% %% Evidence residuals
% dispMsg('Evidence residuals')
% EvDSet = convertToEvSet(DSet, true);
% 
% % Shade the region corresponding to non-decision time (Stim frame duration 
% % was 50ms)
% shadedRegion = [-medianNonDecis*0.05, 0];
% 
% plotFig = plotEvResidualsEffectWithTime(EvDSet, 'scatter', 'B', ...
%     true, false, [], [], plotStat, shadedRegion);
% plotFig = plotEvResidualsEffectWithTime(EvDSet, 'line', 'B', ...
%     true, false, plotFig, [], plotStat);
% figure(plotFig)
% mT_exportNicePdf(15.9, 15.9, saveDir, 'expB_combinedEv')
% 
% 
% %% Modelling results 
% dispMsg('Modelling main overview')
% 
% if strcmp(plotStat, 'mean')
%     [~, crossValPlot, CvDSets] = runCrossValEval(CrossValidationFits, false, ...
%         true, modelNames, false, true);
%     assert(isequal(origNames, mT_findAppliedModels(CvDSets{1})))
% 
%     figure(crossValPlot)
%     mT_exportNicePdf(15.9/2, 15.9, saveDir, 'crossValComparison')
% end
% 
[DSet, FigureHandles] = mT_analyseClusterResults(FullDataSetFits, ...
    1, true, false, true, modelNames); 
DSet = DSet{1};
assert(isequal(origNames, mT_findAppliedModels(DSet)))

% [~, bicData] = mT_collectBicAndAicInfo(DSet);
% runBicBasedMixEffectsModelCompare(bicData, modelNames)
% 
% if strcmp(plotStat, 'mean')
%     figure(FigureHandles.AicBic)
%     mT_exportNicePdf(15.9, 15.9, saveDir, 'aicBic')
% 
%     % The threshold parameters are in a random order. Sort to be in
%     % order before making the parameter table for latex
%     TmpDSet = DSet;
%     for iP = 1 : length(TmpDSet.P)
%         for iM = 1 : length(TmpDSet.P(iP).Models)
%             oldThresh = TmpDSet.P(iP).Models(iM).BestFit.Params.Thresholds;
%             assert(size(oldThresh, 2) == 1)
%             TmpDSet.P(iP).Models(iM).BestFit.Params.Thresholds = ...
%                 sort(oldThresh);
%         end
%     end
% 
%     ParamLabels.Sigma_phi = "$\sigma_\varphi$";
%     ParamLabels.Sigma_acc = "$\sigma_{acc}$";
%     ParamLabels.Thresholds = "$d_i$";
%     ParamLabels.BoundIntercept = "$a$";
%     ParamLabels.PipelineI = "$I$ (s)";
%     ParamLabels.LapseRate = "$\lambda$";
%     ParamLabels.MetacogNoise = "$\sigma_m$";
%     ParamLabels.NoiseRatio = "$\Gamma$";
%     mT_produceParamStats(TmpDSet, saveDir, [2, 5, 7], ParamLabels, ...
%                             [], modelNames)
%     close all
% 
%     % Fit end points
%     [~, restartsFigure] = mT_plotFitEndPoints(DSet, false, 1, [], modelNames);
%     figure(restartsFigure)
%     mT_exportNicePdf(15.9/2, 15.9*(2/3), saveDir, 'restartsRequired')
% end
% 
% %% Main modelling fits
% dispMsg('Modelling main fits')
% 
% plotAndSaveConfidencePredictions(DSet, 7, plotStat, saveDir, '')
% 
% makeCombinedPoorModelsPlot(DSet, [2, 5], modelNames, plotStat, saveDir)

dispMsg('Modelling main full sim')
plotFullSimFits(saveDir, DSet, 7, plotStat, '', 640*10, [], 'skipRtPlots')


%% Regularised fits
dispMsg('Modelling regularised')

[RegDSet, ~] = mT_analyseClusterResults(RegularisedFits, 1, ...
    true, false, true);
RegDSet = RegDSet{1};
close all

applMmodels = mT_findAppliedModels(RegDSet);
iM =  1;
assert(strcmp(applMmodels{iM}, 'FaDsFlatNoneSameMvarReg1'))
plotAndSaveConfidencePredictions(RegDSet, iM, plotStat, ...
    saveDir, ['model_' applMmodels{iM} '_'])

plotFullSimFits(saveDir, RegDSet, iM, plotStat, ...
    ['model_' applMmodels{iM} '_'], 640*5)


%% Regularised CV fits

if strcmp(plotStat, 'mean')
    [~, crossValRegPlot, ~] = runCrossValEval(RegularisedCvFits, false, ...
        true, [], true);
end


%% Model recovery analyses

if strcmp(plotStat, 'mean')
    dispMsg('Model recovery')
    produceModelRecoveryPlots(modelRecovFolder, modelNames, 7, saveDir, '')
end

end


function dispMsg(msg)
disp('')
disp(['**** ' msg])
end



