function [medianNonDecis, evEffectFig] = runStatistics(DSet)
% Run the preregistered analyses and various related analyses


%% Misc stats

% Valid confidence reports
validConf = mean(mT_stackData(DSet.P, @(st) ...
    sum(~isnan(st.Data.Conf))/length(st.Data.Conf)));
disp(['Proportion trials with conf reports: ' num2str(validConf)]);

% Average acc
meanAcc = mean(mT_stackData(DSet.P, @(st) ...
    sum((~isnan(st.Data.Conf)) & (st.Data.Acc==1))/sum(~isnan(st.Data.Conf))));
disp(['Mean acc in trials with conf reports: ' num2str(meanAcc)]);

% Average RT free response
meanRt = mean(mT_stackData(DSet.P, @(st) ...
    mean(st.Data.RtPrec((~st.Data.IsForcedResp) & (~isnan(st.Data.Conf))))));
disp(['Mean RT, valid free resp: ' num2str(meanRt)]);

% Average RT forced response
meanRt = mean(mT_stackData(DSet.P, @(st) ...
    mean(st.Data.RtPrec((st.Data.IsForcedResp) & (~isnan(st.Data.Conf))))));
disp(['Mean RT, valid forced resp: ' num2str(meanRt)]);

% RT with acuracy
for iF = [0, 1]
    meanCorr = mT_stackData(DSet.P, @(st) mean(st.Data.RtPrec(...
        st.Data.Acc==1 & st.Data.IsForcedResp==iF & ~isnan(st.Data.Conf))));
    meanErr = mT_stackData(DSet.P, @(st) mean(st.Data.RtPrec(...
        st.Data.Acc==0 & st.Data.IsForcedResp==iF & ~isnan(st.Data.Conf))));
    
    disp(['IsForcedResp: ' num2str(iF)])
    resultsTable = mT_analyseParams(meanErr - meanCorr, {'Er-corr RT diff'});
    mT_produceStatsLatexSnippet(resultsTable) 
end
   
    
%% Qualitative analysis stats
OverideSettings = struct();
[OldAnalysisData, SettingsUsed, totalExcluded] = analyseDataset(...
    DSet, OverideSettings, 'forced', false);
disp(' ')
disp('Settings used for regression analysis onto conf')
disp('-------------------------------------')
disp(SettingsUsed)
disp('')
disp(['Participants excluded in regression analysis: ' num2str(totalExcluded) ...
    '/' num2str(length(DSet.P))])
    
% Code now only analyses the first model
modelNum = 1;    
    
% Non-decision time
allMedianNonDecis = nan(1, length(unique(OldAnalysisData(1).Raw.BlockType)));
for iBlockType = unique(OldAnalysisData(1).Raw.BlockType)'
    disp(['Non-decision time in ' num2str(iBlockType) ': '])
    nonDecisionTimes = mT_stackData(OldAnalysisData, @(str) str.CondPrep(iBlockType).NonDecisTime);
    medianNonDecis = median(nonDecisionTimes);
    allMedianNonDecis(iBlockType) = medianNonDecis;
    disp(['Median: ', num2str(medianNonDecis)])
    disp(['Inter quartile range: ', num2str(iqr(nonDecisionTimes))])
end

assert(all(size(allMedianNonDecis) == [1, 2]));
allMedianNonDecis = unique(allMedianNonDecis);
assert(all(size(allMedianNonDecis) == [1, 1]));

% Run conventional stats on the parameters from the desired model

% Find the relevant parameter values
paramData = collectParamVals(OldAnalysisData, modelNum);
paramResults = cell(2, 1); % One for each condition

for iBlockType = unique(OldAnalysisData(1).Raw.BlockType)'
    names = {'thresh1', 'thresh2', 'thresh3', 'thresh4', 'RT', 'RTseg2', 'RTseg3', ...
        'RTseg4', 'Predecis', 'Pipeline', 'Postdecis', 'Accuracy'}';
    assert(length(names) == size(paramData{iBlockType}, 1))
    paramResults{iBlockType} = mT_analyseParams(paramData{iBlockType}, names);    
    disp(paramResults{iBlockType})
    mT_produceStatsLatexSnippet(paramResults{iBlockType})
end


%% Run the preregistered analyses

table = mT_analyseParams(paramData{1}(5, :), {'Prerej A'}, 'left');
disp(table)
mT_produceStatsLatexSnippet(table)

vals = paramData{1}(5, :) - paramData{2}(5, :);
table = mT_analyseParams(vals, {'Prerej B'}, 'left');
disp(table)
mT_produceStatsLatexSnippet(table)

vals = (paramData{1}(9, :) - nanmean(paramData{1}(10, :))) - ...
    (paramData{2}(9, :) - nanmean(paramData{2}(10, :)));
table = mT_analyseParams(vals, {'Prerej C'}, 'left');
disp(table)
mT_produceStatsLatexSnippet(table)

vals = (paramData{1}(9, :)) - (paramData{2}(9, :));
table = mT_analyseParams(vals, {'Prerej C without baseline removal'}, 'left');
disp(table)
mT_produceStatsLatexSnippet(table)

vals = paramData{1}(9, :) - paramData{1}(10, :);
table = mT_analyseParams(vals, {'Prerej D'}, 'left');
disp(table)
mT_produceStatsLatexSnippet(table)

evEffectFig = makePlotsForOldAnalysis(paramResults, 'B');


%% Effect of confidence on accuracy

% Confidence as only predictor
findEffectOfConfOnAcc(DSet, 'gamma') 

% Confidence, block type and interaction. Run logisitc regressions
paramNames = {'Confidence', 'IsForcedResp', 'Interaction'}';
paramVals = NaN(3, length(DSet.P));

for iP = 1 : length(DSet.P)

    inc = ~isnan(DSet.P(iP).Data.Conf);

    conf = zscore(DSet.P(iP).Data.Conf(inc));
    block = zscore(DSet.P(iP).Data.IsForcedResp(inc));
    int = conf .* block;
    acc = DSet.P(iP).Data.Acc(inc) +1;

    [B, dev, stats] = mnrfit([conf, block, int], acc);

    B = -B;
    assert(length(B) == 4)

    for iCoef = 1 : 3
        paramVals(iCoef, iP) = B(iCoef +1);
    end

end

table = mT_analyseParams(paramVals, paramNames);
disp(table);

end

