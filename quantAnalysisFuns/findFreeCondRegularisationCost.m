function combCost = findFreeCondRegularisationCost(DSetSpec, Data, ...
    freeTrials, ParamStruct, invalidFreeReport, freeParamPos)

% INPUT
% invalidFreeReport: Vector as long as the number of free condition trials

% OUTPUT
% combCost: vector as long as the number of free condition trials.

% Free condition, cost A (RTs)
adjustedPipe = computeAdjuedtedPipeTime(DSetSpec, Data, ...
    freeTrials, ParamStruct);
assert(length(adjustedPipe) == sum(freeTrials))
accumulateTimes = Data.RtPrec(freeTrials) - adjustedPipe;

assert(length(accumulateTimes) == length(invalidFreeReport))
avRt = mean(accumulateTimes(~invalidFreeReport));

x_D = findDvAtDecision(ParamStruct, Data, freeTrials, ...
    adjustedPipe, 'accCoding');
assert(length(x_D) == sum(freeTrials))
assert(length(x_D) == length(invalidFreeReport))
avX_D = mean(x_D(~invalidFreeReport));

costA = abs(50 * (avRt - (avX_D ./ DSetSpec.AvEvidence)));


% Free condition, cost B (acc)
muOverSigmaSqd = DSetSpec.AvEvidence ./ ...
    ((ParamStruct.Sigma_acc(freeParamPos).^2) ...
    + (findSigmaStim(DSetSpec).^2));
expTerm = exp(-2 .* muOverSigmaSqd .* x_D(~invalidFreeReport));

costB = abs(20 * (mean(expTerm) -1));

assert(length(costA) == 1)
assert(length(costB) == 1)

combCost = ones(sum(freeTrials), 1) ...
    .* ((costA + costB) ./ sum(freeTrials));

assert(isequal(size(combCost), [sum(freeTrials), 1]))