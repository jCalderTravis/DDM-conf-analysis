function [allQuantiles, allProportions, condName, quantilesEdges] ...
    = computeRtQuantiles(Data)
% Compute RT quantiles using the data from a single participant (ie. The
% DSet.P(i).Data structure). Code assumes two conditions (forced response
% vs. not).

% OUTPUT
% allQuantiles: [num quantiles x 4] array giving the RT quantiles for each 
%   unique combination of condition and accuracy.
% allProportions: [4 x 1] vector. For each unique combination of condition 
%   and accuracy in allQuantiles, this vector gives the proportion of
%   valid trials (i.e. valid response and confidence report obtained), 
%   within the current condition, that had the current accuracy.
% condName: [4 x 1] cell array, giving the name for each combination of 
%   condition and accuracy
% quantilesEdges: array. Gives the edges used for the various quantiles

assert(isequal(isnan(Data.Acc), isnan(Data.ConfCat)))
assert(isequal(isnan(Data.Conf), isnan(Data.ConfCat)))

quantilesEdges = [0.1, 0.3, 0.5, 0.7, 0.9];

allQuantiles = nan(length(quantilesEdges), 4);
allProportions = nan(4, 1);
condName = cell(4, 1);

iCombo = 1;
assert(all((Data.IsForcedResp == 1) | (Data.IsForcedResp == 0)))
isForcedNames = {'Free', 'Interrogation'};
for thisForced = [0, 1]
    
    assert(all((Data.Acc == 1) | (Data.Acc == 0) | isnan(Data.Acc)))
    accNames = {'Error', 'Correct'};
    for thisAcc = [1, 0]
       theseRts = Data.RtPrec( ...
           (Data.Acc == thisAcc) & (Data.IsForcedResp == thisForced) ); 
       
       assert(~any(isnan(theseRts)))
       allQuantiles(:, iCombo) = quantile(theseRts, quantilesEdges);
       
       % Within this condition, what proportion of valid responses were 
       % made with this accuracy?
       condAccs = Data.Acc(Data.IsForcedResp == thisForced);
       allProportions(iCombo) = sum(condAccs == thisAcc) ...
           ./ sum(~isnan(condAccs));
       condName{iCombo} = [isForcedNames{thisForced+1} ' ' ...
           accNames{thisAcc+1}];
       
       iCombo = iCombo +1;
    end
end

end