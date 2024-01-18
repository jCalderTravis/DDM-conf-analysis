function SimDSet = simulateDSetBasedOnReal(RealDSet, modelNum, UserSpec, ...
    simType, estLapses, varargin)
% Simulate a dataset the same size as DSet, and based on the fitted parameters
% in DSet, for modelNum (as ordered in DSet) model.

% INPUT
% UserSpec: Structure. Leave empty to simulate data of same size as the fitted data.
% Provide fields to overwrite the defaults.
% simType: Use 'individual' to simulate each participant with their own best
% fitting params, or 'median' to simulate each participant using the median 
% parameter values accros participants.
% estLapses: If set to true code additionally estimates the response lapse rate,
% and courrupts responses accordingly.
% varargin{1}: Number. If provided, specifies a deadline in the free response
% condition, after which the decision threshold drops to a very small value.

if (~isempty(varargin)) && (~isempty(varargin{1}))
    deadline = varargin{1};
else
    deadline = [];
end

allSimDSets = cell(length(RealDSet.P), 1);
allModels = cell(length(RealDSet.P), 1);

if strcmp(simType, 'median')
    MedianParams = mT_findMedianParamStruct(RealDSet, modelNum);
end 

for iP = 1:length(RealDSet.P)
    
    model = RealDSet.P(iP).Models(modelNum).Settings.ModelName;
    allModels{iP} = model;
    
    if strcmp(simType, 'individual')
        ParamStruct = RealDSet.P(iP).Models(modelNum).BestFit.Params;
    elseif strcmp(simType, 'median')
        ParamStruct = MedianParams;
    else
        error('Incorrect use of inputs.')
    end
    
    if isempty(deadline)
        Settings = switchParamCoding(model, RealDSet.P(iP).Data, ParamStruct, ...
            'simulation');
    else
        Settings = switchParamCoding(model, RealDSet.P(iP).Data, ParamStruct, ...
            'simulation', deadline);
    end
    
    Settings.NumPtpnts = 1;
    Settings.TotalTrials = length(RealDSet.P(iP).Data.RtPrec);
    Settings.BlockSize = 40;
    Settings.DeltaT = 0.0001;
    Settings.Fps = RealDSet.Spec.Fps;
    Settings.Units = 1;
    Settings.Dots = RealDSet.Spec.Dots;
    Settings.Dots.Min = 1;
    
    % Apply user specified settings over defaults
    userSpecs = fieldnames(UserSpec);
    
    for iSpec = 1 : length(userSpecs)
        if ~isfield(Settings, userSpecs{iSpec})
            error('Incorrect use of inputs')
        else
            Settings.(userSpecs{iSpec}) = UserSpec.(userSpecs{iSpec});
        end
    end
    
    ScaleUsage = RealDSet.P(iP).Data.Conf;   
    allSimDSets{iP} = simulateDataSet(Settings, ScaleUsage); 
end

% Combine all data sets. 
SimDSet = allSimDSets{1};

for iP = 2 : length(RealDSet.P)
    thisSimDSet = allSimDSets{iP};
    SimDSet.P(iP) = thisSimDSet.P;
end

% Store the model used to simulate the data
for iModel = 2 : length(allModels)
    if ~strcmp(allModels{1}, allModels{iModel})
        error('Bug')
    end
end

SimDSet.SimSpec.Name = allModels{1};

if estLapses
    error('Option removed')
end

end



