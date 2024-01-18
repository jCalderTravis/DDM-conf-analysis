function combCost = findForcedCondRegularisationCost(Data, forcedTrials, ...
    ParamStruct, probResp)

% INPUT
% probRes: vecotor as long as the number of forced condition trials. Gives
%  the probability of the response that was actually made.

% OUTPUT
% combCost: vector as long as the number of forced condition trials.

avRt = mean(Data.RtPrec(forcedTrials));
avStimPres = mean(Data.ActualDurationPrec(forcedTrials));

totCostC = abs(50 * (avRt - (avStimPres + ParamStruct.PipelineI)));
costC = ones(sum(forcedTrials), 1) .* (totCostC / sum(forcedTrials));

assert(length(probResp) == sum(forcedTrials))

costD_param = 0.025;
costD = -log(((1 - costD_param) .* probResp) + (costD_param/2));

assert(isequal(size(costC), size(costD)))
combCost = costC + costD;

assert(isequal(size(combCost), [sum(forcedTrials), 1]))