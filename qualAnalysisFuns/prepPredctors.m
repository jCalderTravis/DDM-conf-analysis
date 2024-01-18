function [predictors, segBreakTime] = prepPredctors(ptpntData, blockType, ...
    predsToPrep, verbose)
% Produce an array of the predictors.

% INPUT
% predsToPrep   The (integer) indicies of the predictors which should be
%               prepped.

if length(ptpntData) ~= 1; error('Incorrect use of input arguments'); end

% For brevity
nonDecisionTime = ptpntData.CondPrep(blockType).NonDecisTime;
incTrial = ptpntData.CondPrep(blockType).IncTrials;

% Check nonDecision time is specified as a number of frames (ie. by an integer)
if ~(floor(nonDecisionTime) == nonDecisionTime); error('Incorrect units used'); end

% Which measure of response time should be used in the regression predictors?
if strcmp(ptpntData.GlobalPrep.Settings.ResponseMeas, 'press')
    responseTime = ptpntData.Raw.RT;

elseif strcmp(ptpntData.GlobalPrep.Settings.ResponseMeas, 'stim')
    responseTime = ptpntData.Raw.ActualDuration;
else
    error('Incorrect specification of settings')
end


%% Create the requested predictors

% Gathered required info
dotsDiffResiduals = findChosenDotsResiduals(ptpntData, ...
    ptpntData.GlobalPrep.Settings.DemeanEvidence);

% Use the decision time to make a cut off between preDecision evidence and pipeline evidence,
% subject to constraint...
% In the deadline condition set the cut off as duration of the stimulus
% minus postCommitDelay so that there is still "pipeline" data to analyse even though it isn't
% really from the pipeline.

% Identify deadline trials
deadlineTrials = ptpntData.Raw.IsForcedResp == 1;

if sum(deadlineTrials) >0 && verbose    
    disp('Deadline block trials detected')
end

% Now process all trials
preDecisCutOff = ptpntData.Raw.RT - nonDecisionTime;
preDecisCutOff(deadlineTrials) = ptpntData.Raw.ActualDuration(deadlineTrials) - nonDecisionTime;

preRespCutOff = ptpntData.Raw.RT;
preRespCutOff(deadlineTrials) = ptpntData.Raw.ActualDuration(deadlineTrials);

% In deadline trials in may be the case that all data falls into the pipeline
% and none is in the preDecision period. In order to deal with this case:
preDecisCutOff( preDecisCutOff<1 ) = 0;

if any( incTrial & (preDecisCutOff == 0) & ~deadlineTrials )
    
    error(['Bug in script. For non-deadline trials, any trials with fast ' ...
        'responses should already have been excluded.'])
end

totalTrials = length(ptpntData.Raw.RT);

% What is the difference in dots?
preDecisDiff = NaN(totalTrials, 1);
pipelineDiff = NaN(totalTrials, 1);
postRespDiff = NaN(totalTrials, 1);

for iTrial = 1 : totalTrials
    if incTrial(iTrial)
        
        if preDecisCutOff(iTrial) == 0
            % Deal with case where no evidnece counts as preDecision
            preDecisDiff(iTrial) = 0;
        else
            % But normally...
            preDecisDiff(iTrial) = ...
                sum(dotsDiffResiduals(iTrial, 1 : preDecisCutOff(iTrial)));
        end
        
        pipelineDiff(iTrial) = ...
            nansum(dotsDiffResiduals(iTrial, ...
            (preDecisCutOff(iTrial) + 1) : preRespCutOff(iTrial)));

        postRespDiff(iTrial) = ...
            sum(dotsDiffResiduals(iTrial, ...
            preRespCutOff(iTrial) +1 : ptpntData.Raw.ActualDuration(iTrial)));
    end
end

% Check this has all gone to plan
evidenceChunks = {preDecisDiff, pipelineDiff, postRespDiff};

for iField = 1 : length(evidenceChunks)
    if any(isnan(evidenceChunks{iField}) & incTrial)
        error('Bug in script')
    end
end   

% We are going to use linear segments to model the threshold. We will use four, and each
% will contain a quarter of the reaction times.
segBreakTime(3) = quantile(responseTime(incTrial), 0.75);
breakPercentiles = [0.25 0.5];

for iBreak = [2 1]    
    segBreakTime(iBreak) = quantile(responseTime(incTrial), breakPercentiles(iBreak));
    
    if ptpntData.GlobalPrep.Settings.EnforceDistinctSegs && ...
        (segBreakTime(iBreak) >= segBreakTime(iBreak +1))
        
        segBreakTime(iBreak) = segBreakTime(iBreak +1) - 1;
    end
end

% Segment 1 is just given by decision time (predictor 1), predictors for the other
% segments will be zero up to the time of segBreak-1 and then linear in t - t(segBreak)
% threreafter
linearSegment = cell(3, 1);

for iSeg = 1 : 3 
    linearSegment{iSeg} = responseTime - (segBreakTime(iSeg));
    linearSegment{iSeg}(linearSegment{iSeg} < 0) = 0;
end

% Prep all possible predictors
predictors = [  responseTime, ...
                linearSegment{1}, ...
                linearSegment{2}, ...
                linearSegment{3}, ...
                ...
                preDecisDiff, ...
                pipelineDiff, ...
                postRespDiff, ...
                ptpntData.Raw.Acc];          

% If the DV is accuracy flip the predictors so that the given evdience, not in
% the chosen direction, but in the correct direction
if strcmp(ptpntData.GlobalPrep.Settings.DV, 'acc')
    
    if any(predsToPrep > 8)
        error(['Script cannot do accuracy coding on any predictors other than ', ...
            '1 - 8 in the predictor array specification.'])
    end
    
    predictors(ptpntData.Raw.Acc == 0, [5 6 7]) = ...
        - predictors(ptpntData.Raw.Acc == 0, [5 6 7]);
end

% Defensive programming
if size(predictors, 2) ~= 8; error('Bug'); end

% Mark all data from not included trials as NaN
predictors(~incTrial,  :) = NaN;


    


