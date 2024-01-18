function PredDSet = simulateConfFromRtWrapper(DSet, modelNum)
% Simulate confidence from the stimuli and RT on the real trials

% INPUT
% modelNum: The number of the model (as ordered in DSet.P(iP).Models) to 
%   use for simulating confidence values.


%% Find the model used
modelUsed = cell(length(DSet.P), 1);

for iP = 1 : length(DSet.P)
    modelUsed{iP} = DSet.P(iP).Models(modelNum).Settings.ModelName;
end

modelUsed = unique(modelUsed);
if length(modelUsed) ~= 1; error('Bug'); end
modelUsed = modelUsed{1};


%% Simulate
PredDSet = DSet;

for iP = 1 : length(DSet.P)
    
    findIncludedTrials = DSet.P(iP).Models(modelNum).Settings.FindIncludedTrials;
    ParamStruct = DSet.P(iP).Models(modelNum).BestFit.Params;
    
    SimConf = simulateConfFromRt(modelUsed, findIncludedTrials, ParamStruct, ...
        DSet.P(iP).Data, DSet.Spec);
    
    % When the original response wasn't valid, discard the simulated confidence
    % value
    SimConf(isnan(DSet.P(iP).Data.Conf)) = NaN;
    
    PredDSet.P(iP).Data.ConfCat = SimConf;
    
    % To avoid mistakes in using the true confidence values, replace the
    % continuous confidence values with the binned confidence values as well,
    % and add negligible noise.
    PredDSet.P(iP).Data.Conf = SimConf + (randn(size(SimConf))*0.001);
    
    % Add simulation parameters
    PredDSet.P(iP).Sim.Params = ParamStruct;
end

% Remove old models
PredDSet.P = rmfield(PredDSet.P, 'Models');

% Add simulation details
SimDSet.SimSpec.Name = modelUsed;

