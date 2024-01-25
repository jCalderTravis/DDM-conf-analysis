function [Data , SettingsUsed, totalExcluded] = analyseDataset(DSet, ...
    AnalysisSettings, defaults, verbose, varargin)
% Runs the full qualitative analysis on a data set and produces a structure 
% storing a summary of the data and results.

% NOTES
% The script assumes 50ms frames for calculation of threshold crossing time from nonDecisionTime

% INPUT
% AnalysisSettings      Fields...
%   BlockForNonDecis    
%                       If a number is specified then this block type is used
%                       for all calculations of nonDecisionTime in every block.
%                       If 'own', then the data from each block type is used to
%                       model nonDecisionVariability in that block type.
%                       Why? If one block type is a deadline condition, then 
%                       nonDecisionTime doesn't really make sense, so we don't 
%                       want to use data from this condition to model it.
%   AccuracyCond        Which trials to include?
%   DotsRefVal          
%                       Set to 'trial' if this is determined on a trial by trial
%                       basis. Otherwise set to half way between the high mean
%                       dots value, and the low mean dots value.
%   DotsDiff            Set to 'trial' if this is determined on a trial by trial
%                       basis. Otherwise a value can be provided specifying the
%                       mean difference in dots between the low and high mean
%                       dot clouds.
%   commitDelayExclude
%                       All trials which ocour within 
%                       (Settings.commitDelayExclude * nonDecisionTime) frames 
%                       of the onset of the start of the trial are excluded.
%   EnforceDsitinctSegs
%                       If true, then when modelling the threshold as linear
%                       segments, if one segment is determined to be of length
%                       zero, it will be extended to make it nonzero.
%   ExcludeOnAcc        Excludes participants based on their performance.
%   ExcCoM              Excludes trials which were changes of mind.
%   ResponseMeas        Which measure should be used as the response time in the
%                       regression?
%                       'press' for press of the response key
%                       'stim' for end of stimulus presentation
%   StandardiseCoef     Standardise the coefficients produced by the model by
%                       dividing all coefficients by the standard deviation of
%                       the latent variable.
%   DV                  What should be analysed as the dependent variable in the
%                       regression? 'conf' standard, or 'acc'. If set to
%                       acc, the evidence predictors are changed to
%                       evidence in direction of the correct option.
%   zScore              'zScore' to do normal zScoring. 'sdOnly' to only divide
%                       by standard deviation without centering. Or 'none'.
%   PostRespPred        Include a predictor of post-response evidence?
% defaults              Specify which defaults to use for AnalysisSettings. 
%                       Used 'forced' to apply defaults for comparing free 
%                       and forced response conditions;
% varargin{1}:          bool. Make an additional plot for illustration purposes?
%                       default is false. Good settings for saving this plot are: 
%                       mT_exportNicePdf(15.9/2, 15.9/2, saveDir, ...
%                           'nonDecisFitIllustration')

% OUTPUT
% Data      Not in the standard format. 
% SettingsUsed
%           A table of the settings used to analyse the data

if isfield(AnalysisSettings, 'DotsDiff') && ...
    isnumeric(AnalysisSettings.DotsDiff) && ...
    AnalysisSettings.DotsDiff < 0
    
    error('Incorrect use of inputs')
end

if (~isempty(varargin)) && (~isempty(varargin{1}))
    makeAdditionalPlot = varargin{1};
else
    makeAdditionalPlot = false;
end

% Check time unit is seconds
if ~DSet.Spec.TimeUnit == 1; error('Incorrect data specification'); end 

% Change to old data format
for iPtpnt = 1 : length(DSet.P)
    
    Data(iPtpnt).Raw = DSet.P(iPtpnt).Data;
    Data(iPtpnt).Raw.RT = round(Data(iPtpnt).Raw.RtPrec * DSet.Spec.Fps);
    Data(iPtpnt).Raw.ActualDuration ...
        = round(Data(iPtpnt).Raw.ActualDurationPrec * DSet.Spec.Fps);
end


%% Set defaults
reqField = {'BlockForNonDecis', ...
    'DotsRefVal', 'DotsDiff', ...
    'AccuracyCond', 'BreakTies', ...
    'NumQuantiles', 'DemeanEvidence', ...
    'zScore', 'commitDelayExclude', 'ZeroPoint', 'EnforceDistinctSegs', ...
    'ExcludeOnAcc', 'ExcCoM', 'ResponseMeas', 'StandardiseCoef', ...
    'DV', 'PostRespPred'};

% Check there are no extra fields
names = fieldnames(AnalysisSettings);

if any(~ismember(names, reqField))
    error('Incorrect use of fields in input ''Settings'' strcut.')
end


postDecisDefaults = {'own', 'trial', 'trial', 'All', 1, 5, ...
    1, 'zScore', 1, 0, true, false, false, 'press', false, 'conf', true};

forcedDefaults = {1, 'trial', 'trial', 'All', 0, 5, ...
    1, 'zScore', 1, 0, false, true, false, 'press', false, 'conf', false};


for iField = 1 : length(reqField)
    
    if ~isfield(AnalysisSettings, reqField{iField})
        
        if strcmp(defaults, 'none')
            error('No defaults requested and settings missing fields.')
            
        elseif strcmp(defaults, 'postDecis')
            defaultVal = postDecisDefaults{iField};
            
        elseif strcmp(defaults, 'forced')
            defaultVal = forcedDefaults{iField};
        else
            error('Incorrect specification of input argument.')
        end
        
        AnalysisSettings.(reqField{iField}) = defaultVal;
    end
end

% Store the settings
SettingsUsed = struct2table(AnalysisSettings);

for iPtpnt = 1 : length(Data)
    Data(iPtpnt).GlobalPrep.Settings = AnalysisSettings;
end

if AnalysisSettings.PostRespPred
    paramComboArray = [1, 0, 0, 0, 1, 1, 1, 1]';
elseif ~AnalysisSettings.PostRespPred
    paramComboArray = [1, 0, 0, 0, 1, 1, 0, 1]';
end

if strcmp(AnalysisSettings.DV, 'acc')
    paramComboArray(8) = 0;
end

% Store the array specifying the different models that will be compared
[Data(:).ParamCombos] = deal(paramComboArray);

%% Precompute some measures

for iPtpnt = 1 : length(Data)
    
    for iBlockType = unique(Data(iPtpnt).Raw.BlockType)'
        
        Data(iPtpnt).CondPrep(iBlockType).BlockType = iBlockType;
        
        % Precompute nondecision time. The data we use to model this depends on the
        % users specification in settings.
        if ischar(Data(iPtpnt).GlobalPrep.Settings.BlockForNonDecis) && ...
                strcmp(Data(iPtpnt).GlobalPrep.Settings.BlockForNonDecis, 'own')
            
            dataToUse = Data(iPtpnt).CondPrep(iBlockType).BlockType;
            
        elseif isa(Data(iPtpnt).GlobalPrep.Settings.BlockForNonDecis, 'double')
            
            dataToUse = Data(iPtpnt).GlobalPrep.Settings.BlockForNonDecis;
        else    
            error('Data to use to caclulate nonDecisionTime incorrectly specified')
        end
        
        if (iPtpnt == 2) && (iBlockType == 1)
            makeAdditionalPlotNow = makeAdditionalPlot;
        else
            makeAdditionalPlotNow = false;
        end

        Data(iPtpnt).CondPrep(iBlockType).NonDecisTime = ...
            modelNonDecisionVariability(Data(iPtpnt), dataToUse, ...
                makeAdditionalPlotNow);
        
        % Display the computed times
        if verbose
            disp(['NonDecisionTime: ' ...
                num2str(Data(iPtpnt).CondPrep(iBlockType).NonDecisTime)])
        end
        
        % Find trials to be included in each analysis
        incTrial = findQualIncludedTrials(Data(iPtpnt), iBlockType, ...
            verbose);
        
        Data(iPtpnt).CondPrep(iBlockType).IncTrials = incTrial;
    end
    
    % Precompute our ordinal measure of confidence
    [ordinalConfidence, exclude] = makeConfOrdinal(Data(iPtpnt));
    
    Data(iPtpnt).GlobalPrep.OrdinalConf = ordinalConfidence;
    Data(iPtpnt).GlobalPrep.Exclude = exclude;
    
    if verbose
        disp(['Exclude on conf ' num2str(exclude)])
    end
        
    for iBlockType = unique(Data(iPtpnt).Raw.BlockType)'
    
        % Precompute our predictors
        [predictors, segBreakTime] = prepPredctors(Data(iPtpnt), iBlockType, ...
            find(any(paramComboArray, 2)), verbose);
        
        Data(iPtpnt).CondPrep(iBlockType).Predictors = predictors;
        Data(iPtpnt).CondPrep(iBlockType).SegBreakTime = segBreakTime;
        
        excluded = excludePtpnts(Data(iPtpnt), iBlockType, ...
            find(any(paramComboArray, 2)));
        
        if excluded == 1
            Data(iPtpnt).GlobalPrep.Exclude = 1;
        end
    end
end

% Find total excluded
totalExcluded = 0;
for iPtpnt = 1 : length(Data)
    if Data(iPtpnt).GlobalPrep.Exclude == 1
        totalExcluded = totalExcluded +1;
    end
end
    
%% Analyse dataset
Data = compareParamaterisations(Data, paramComboArray);
disp('Analysis complete')




