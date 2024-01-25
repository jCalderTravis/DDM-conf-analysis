function findEffectOfConfOnAcc(DSet, method)
% Compute the effect of confidence on accuracy

% INPUT
% method: str. 'ordReg' for ordinal regression, or 'gamma' for 
%   Goodman-Kruskal's gamma

disp('Effect of conf on accuracy')
disp(['Method: ' method])
paramNames = {'Confidence'}';
paramVals = NaN(1, length(DSet.P));

for iP = 1 : length(DSet.P)
    
    inc = ~isnan(DSet.P(iP).Data.Conf);
    conf = zscore(DSet.P(iP).Data.Conf(inc));
    acc = DSet.P(iP).Data.Acc(inc) +1;
    
    if strcmp(method, 'gamma')
        [conf, sortOrder] = sort(conf);
        acc = acc(sortOrder);
        
        contingency = zeros(length(conf), 2);
        ind = sub2ind(size(contingency), [1:length(conf)]', acc);
        contingency(ind) = 1;
        
        assert(all(sum(contingency, 2) == 1))
        
        thisVal = gkgammatst(contingency, 0.05, 0);
        assert(thisVal >= -1)
        assert(thisVal <= 1)
        
    elseif strcmp(method, 'ordReg')
        [B, dev, stats] = mnrfit(conf, acc);
        B = -B;
        assert(length(B) == 2)
        thisVal = B(2);
    else
        error('Bug')
    end
    
    paramVals(1, iP) = thisVal;
end

table = mT_analyseParams(paramVals, paramNames);
disp(table)
mT_produceStatsLatexSnippet(table)
if strcmp(method, 'gamma')
    disp(['Average gamma: ' num2str(mean(paramVals))])
end