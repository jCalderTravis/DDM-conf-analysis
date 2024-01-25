function [avNegLogPosteriorPredictive, plotFig, AllDSets] = ...
    runCrossValEval(scheduleFolder, allowMissingData, alreadyUnpacked, ...
    modelNames, varargin)
% Evaluate the results of cross validation

% INPUT
% modelNames: numModels long cell array of model names. May provide an 
%   empty array to revert to default naming.
% varargin{1}: bool. If true then, for models who's
%   likelihood function normally involves regularisation, remove this
%   regularlisation. Default is false.
% varargin{2}: bool. If true, then skip checks of CV fold order (older
%   fits do not contain the relevant information for checking this). The
%   default is false.

% OUTPUT
% plotFig: Figure handle to model comparison based on the cross validation


if (~isempty(varargin)) && (~isempty(varargin{1}))
    suppressReg = varargin{1};
else
    suppressReg = false;
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    skipFoldChecks = varargin{2};
else
    skipFoldChecks = false;
end

% Load some data about the cross valdation
Loaded = load([scheduleFolder '/CvData.mat']);
numParticipants = Loaded.numParticipants;
numFolds = Loaded.numFolds;
fittedModels = Loaded.modelsToFit;

avLogPosteriorPredictive = NaN(length(fittedModels), numParticipants, numFolds);

% Collect the results
[AllDSets, ~] = mT_analyseClusterResults(scheduleFolder, 1, ...
    true, allowMissingData, alreadyUnpacked);
close all

if length(AllDSets) ~= numFolds; error('One dataset expected per CV fold.'); end

for iFold = 1 : numFolds
    DSet = AllDSets{iFold};

    if skipFoldChecks
        % Nothing to do
    else
        assert(DSet.Spec.CvFold == iFold)
    end
   
    % Check the expected models have been applied
    allModels = mT_findAppliedModels(DSet);
    if ~isequal(allModels, fittedModels'); error('Bug'); end
    
    % Evalute the probability of all trials using the fitted parameters
    for iP = 1 : numParticipants
        
        for iModel = 1 : length(fittedModels)
            thisModel = fittedModels{iModel};
            
            if suppressReg
                % Impose strict requirements on the existing model name,
                % just to be extra careful. These could be loosened in 
                % future, if required.
                assert(length(thisModel) == 24)
                assert(ismember({thisModel(21:24)}, {'Reg1', 'Reg2'}))
                
                thisModel(21:24) = 'NoRg';
                
                assert(length(thisModel) == 24)
                assert(strcmp(thisModel(21:24), 'NoRg'))
            end 
            
            noReg = (length(thisModel) < 21) || ...
                    strcmp(thisModel(21:24), 'NoRg');
            if ~noReg
                error('See comment')
                % Cross regularisation cannot currently be performed when
                % regularisation is on because, currently all trials are
                % used in the computation of the regularisation term.
            end
            
            baseInclusion = @(Data) ~isnan(Data.Conf);
            ParamStruct = DSet.P(iP).Models(iModel).BestFit.Params;
            
            [trialLL, ~] = cm_computeTrialLL(thisModel, ...
                baseInclusion, ParamStruct, ...
                DSet.P(iP).Data, DSet.Spec);
            
            % Find trials to evaluate in this fold
            relTrials = baseInclusion(DSet.P(iP).Data) & ...
                (DSet.P(iP).Data.CvFold == iFold);

            findInc = ...
                DSet.P(iP).Models(iModel).Settings.FindIncludedTrials;
            if isa(findInc, 'char') || isa(findInc, 'string')
                % No longer have the information need to run this test
            else
                trainTrials = findInc(DSet.P(iP).Data);
                assert(isequal(size(trainTrials), size(relTrials)))
                if any(trainTrials & relTrials)
                    error(['At least one trial used for both ' ...
                        'training and eval'])
                end
            end

            avLogPosteriorPredictive(iModel, iP, iFold) ...
                = mean(trialLL(relTrials));
        end
    end
end

avLogPosteriorPredictive = mean(avLogPosteriorPredictive, 3);
if size(avLogPosteriorPredictive) ~= [length(fittedModels), numParticipants]
    error('Unexpected shape')
end

% Want to analyse negative posterior predictive
avNegLogPosteriorPredictive = -avLogPosteriorPredictive;

if isempty(modelNames)
    modelNames = fittedModels;
end

if (size(modelNames, 1) == 1) && (size(modelNames, 2) > 1)
    modelNames = modelNames';
end

disp('Average negative log-posterior on held out trials...')
avOverPtpnt = mean(avNegLogPosteriorPredictive, 2);
results = table(modelNames, avOverPtpnt);
format long
disp(results);
format short

[~, plotFig] = mT_plotAicAndBic([], [], avNegLogPosteriorPredictive, ...
                                '', false, modelNames);
            
    
        