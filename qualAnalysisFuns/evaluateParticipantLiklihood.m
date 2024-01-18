function Stats = evaluateParticipantLiklihood(Data, predCombos, Stats, ...
                ptpnt, blockType, combo)
% Find the maximum likihood for the set of predictors specified in
% predCombos(:, combo).

% Defensive programing
if size(predCombos, 1) < 8 || size(predCombos, 1) > 17    
    error('Unexpected vector length')
end

% For brevity
numQuantiles = Data(ptpnt).GlobalPrep.Settings.NumQuantiles;


%% Prepare data

predictors = Data(ptpnt).CondPrep(blockType).Predictors;
ordinalConf = Data(ptpnt).GlobalPrep.OrdinalConf;

relPredictors= predCombos(:, combo);
assert(max(relPredictors) <= 8)
predictors = predictors(:, find(relPredictors));

% Select only the trials we want
ordinalConfidenceInc = ordinalConf(Data(ptpnt).CondPrep(blockType).IncTrials);

predictorsInc = ...
    predictors(Data(ptpnt).CondPrep(blockType).IncTrials, :);

if strcmp(Data(ptpnt).GlobalPrep.Settings.zScore, 'zScore')    
    [predictorsInc, ~, predSDs] = zscore(predictorsInc);
    
elseif strcmp(Data(ptpnt).GlobalPrep.Settings.zScore, 'sdOnly')
    
    % In this case we only set the standard deviations to 1, without normalising
    predSDs = std(predictorsInc);
    predSDs = repmat(predSDs, size(predictorsInc, 1), 1);
    predictorsInc = predictorsInc ./ predSDs;    
    predSDs = predSDs(1, :);
    
elseif strcmp(Data(ptpnt).GlobalPrep.Settings.zScore, 'none')
    
else
    error('Incorrect use of inputs')
end

% What should be used as the dependent variable?
if strcmp(Data(ptpnt).GlobalPrep.Settings.DV, 'conf')
    DV = ordinalConfidenceInc;    
    
elseif strcmp(Data(ptpnt).GlobalPrep.Settings.DV, 'acc')
    ordinalAcc = ordinal(Data(ptpnt).Raw.Acc, ...
        {'error', 'correct'}, [], [-0.1, 0.5, 1.1]);
    
    DV = ordinalAcc(Data(ptpnt).CondPrep(blockType).IncTrials);
    
    % We also need to update the number of quantile which is now effectively 2
    numQuantiles = 2;
end
                

%% Entire dataset regression

[B, dev, stats] = mnrfit(predictorsInc, DV, ...
    'Model', 'ordinal', 'Link', 'probit');

% For some reason a positive relationship between a predictor and confidence
% produces a negative B, so switch the signs round to recover normal convention
B = -B;
    
% Do we want to standardise the coefficients produced, by estimating the latent
% variable stanard deviation and dividing by this?
if Data(ptpnt).GlobalPrep.Settings.StandardiseCoef
    error('Option removed.')
end
    
% the first numQuantiles -1 coeficients will be Intercepts
Stats.Intercepts(1 : numQuantiles - 1, combo) = B(1 : numQuantiles - 1);
Stats.Slopes(logical(relPredictors), combo) = B(numQuantiles : end);

% If we have zscored, return the coeffients in B, which are associated with predictors, back to the
% original units. 
if strcmp(Data(ptpnt).GlobalPrep.Settings.zScore, 'zScore') || ...
        strcmp(Data(ptpnt).GlobalPrep.Settings.zScore, 'sdOnly')

    Stats.Slopes(logical(relPredictors), combo) = ...
        Stats.Slopes(logical(relPredictors), combo) ./ (predSDs');
else
    assert(strcmp(Data(ptpnt).GlobalPrep.Settings.zScore, 'none'))
end

% Store the number of data points in the regression
Stats.NumCases(combo) = length(ordinalConfidenceInc);


end

    