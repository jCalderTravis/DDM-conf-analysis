function attemptModelRecovery(simulateModels, analyseModelsNums, mode, ...
    SaveDirs, FitRuns, varargin)
% Run the fits required for the model recovery analysis

% INPUT
% simulateModels
%               vector if integers. Used to index into the output of 
%               produceDefaultModelLists('key'). Only data from these 
%               models are used to simuate data. Ignored if use varargin{1}
% analyseModels
%               vector of integers. Used to index into the output of 
%               produceDefaultModelLists('key') if varargin{1} is not 
%               provided, otherwise it indexes into the list of models as
%               they are ordered in the template dataset. Only data from 
%               these models are used to analyse data
% mode          str. 'cluster' schedules for the cluster without a parfor 
%               loop, 'clusterPar' schedules for the cluster with a parfor
%               loop used on the cluster, and 'local' runs immediately
% SaveDirs      Directories for saving the results. If mode is 'local', we
%               require a field 'Data' for the
%               dataset. If mode is 'cluster' we require 'Schedule' directory
%               for saving the scheduled jobs and data.
% FitRuns: Number of fit runs.
% varargin{1}   (Optional). Provide a standard dataset that has been fitted.
%               Then the simulated data will be based on the fitted parameters.
% varargin{2}   (optional). The number of participants to randomly select from
%               the template set to use.
% varargin{3}:  bool. Default false. If set to true, sets specific values 
%               for lapses.

if strcmp(mode, 'local')
    dataSaveDir = SaveDirs.Data;
    disp(dataSaveDir)
    
elseif any(strcmp(mode, {'cluster', 'clusterPar'}))
    scheduleDir = SaveDirs.Schedule;
else
    error('Bug')
end

if (~isempty(varargin)) && (~isempty(varargin{1}))
    templateDSet = true;
    Template = varargin{1};
else
    templateDSet = false; 
end

if templateDSet
    if (length(varargin) >= 2) && (~isempty(varargin{2}))
        simPtpnts = varargin{2};
    else
        simPtpnts = length(Template.P);
    end
end

if (length(varargin) >= 3) && (~isempty(varargin{3}))
    fixedValLapses = varargin{3};
else
    fixedValLapses = false;
end

% Specify settings of the models to be simulated
if ~templateDSet
    allModels = produceDefaultModelLists('key');
    UserSettings = struct('NumPtpnts', 48, 'TotalTrials', 640);
    simModels = allModels(simulateModels);
    SimulationConfigs = generateSimConfigs(simModels, UserSettings);
    AllDSets = cell(size(SimulationConfigs));
    
elseif templateDSet
    allModels = mT_findAppliedModels(Template);
    AllDSets = cell(length(allModels), 1);
end

if fixedValLapses
   randRtLapseRate = 0.05;
   confLapseRate = 0.05;
end


%% Specify all the data to simulate and their parameters
for iSimConfig = 1 : length(AllDSets)

    % Simulate data
    if ~templateDSet
        currentConfig = SimulationConfigs(iSimConfig);
        if fixedValLapses
            currentConfig.RandRtLapseRate = randRtLapseRate;
            currentConfig.ConfLapseRate = confLapseRate;
            disp('Fixing the values for some lapse rates')
        end

        DSet = simulateDataSet(currentConfig);
        
    elseif templateDSet
        
        % Randomly select participants to use
        selected = randperm(length(Template.P), simPtpnts);
        ThisTemplate = Template;
        ThisTemplate.P = Template.P(selected);

        if fixedValLapses
            UserSpec.RandRtLapseRate = randRtLapseRate;
            UserSpec.ConfLapseRate = confLapseRate;
            disp('Fixing the values for some lapse rates')
        else
            UserSpec = struct();
        end
        
        % Apply a deadline to free response trials of 60 seconds
        DSet = simulateDSetBasedOnReal(ThisTemplate, iSimConfig, ...
            UserSpec, 'individual', false, 60);
    end
    
    % Fit the requested models
    analyseModels = allModels(analyseModelsNums);
    
    if any(strcmp(mode, {'cluster', 'clusterPar'}))
        AllDSets{iSimConfig} = fitModels(DSet, analyseModels, mode, ...
            scheduleDir, FitRuns);
        
    elseif strcmp(mode, 'local')
        AllDSets{iSimConfig} = fitModels(DSet, analyseModels, mode, ...
            [], FitRuns);
    else
        error('Bug')
    end

end

%% Save
if strcmp(mode, 'local')
    try
        AllDSets = mT_removeFunctionHandles(AllDSets);
        
        save([dataSaveDir '\ModelRecoveryData_AllDSets'], 'AllDSets')
    catch errorMsg
        disp(errorMsg)
    end
end

end




    
 
    