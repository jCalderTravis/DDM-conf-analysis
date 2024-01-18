function excluded = excludePtpnts(ptpntData, blockType, predsToPrep)
% Run some tests to see whether one participant's data should be excluded from 
% the analysis.

% INPUT
% predsToPrep   The (integer) indicies of the predictors which should be
%               tested for predictor matrix conditioning.

if length(ptpntData) ~= 1; error('Incorrect use of inputs.'); end

% Unless we have a reason to below...
excluded = 0;

%% Exclusions on accuracy

if ptpntData.GlobalPrep.Settings.ExcludeOnAcc == 1    
    validTrials = sum(ptpntData.CondPrep(blockType).IncTrials);
    
    correctTrials = sum(...
        ptpntData.Raw.Acc(ptpntData.CondPrep(blockType).IncTrials) == 1);

    if (correctTrials / validTrials) < 0.6        
        excluded = 1;
    end
end


%% Exclusions for cases and conditioning of predicotor matrix

% We only want to test inlcuded trials
arrayToTest = ptpntData.CondPrep(blockType).Predictors;
arrayToTest = arrayToTest(ptpntData.CondPrep(blockType).IncTrials, :);

% Pass the full predictor matrix through some tests to see if it is likely to cause some problems
% for the ordinal regression. zScore first if this is going to happen before the oridnal regression.
if strcmp(ptpntData.GlobalPrep.Settings.zScore, 'zScore')
    [arrayToTest, ~, ~] = zscore(arrayToTest);
    
elseif strcmp(ptpntData.GlobalPrep.Settings.zScore, 'sdOnly')
    % In this case we only set the standard deviations to 1, without normalising
    predSDs = std(arrayToTest);
    predSDs = repmat(predSDs, size(arrayToTest, 1), 1);
    arrayToTest = arrayToTest ./ predSDs;
end

% Some predictors are not to be tested. Predictors 9, 10, 15, 16 are never tested, 
% as they are not really predictors (it is a parameter than needs to be fit).
% Also 17 is just a row of ones so it is not tested either.
assert(max(predsToPrep) <= 8)
arrayToTest = arrayToTest(:, predsToPrep);

if (cond(arrayToTest) > 1000) || (size(arrayToTest, 1) < 70)
    excluded = 1; 
end

