function runBicBasedMixEffectsModelCompare(bicData, modelNames)
% Run a model comparson, first coverting BIC values into estimated model
% evidences, and then performing a mixed effect model comparison.

% INPUT
% bicData: [numModels x numParticipants] array of BIC values
% modelNames: cell array | empty

% NOTE
% For more info on the VBA toolbox functions used here, see 
% https://mbb-team.github.io/VBA-toolbox/wiki/BMS-for-group-studies/

if ~isempty(modelNames)
    assert(length(modelNames) == size(bicData, 1))
end

% Convert BIC to log model evidence.
% On some definitions of BIC it is already equal to log model evidence 
% but for the standard BIC definition (which we use) we need to multiply by
% a constant
logModelEv = -(1/2)*bicData;


%% Mixed effect model comparison

disp(['Stats for overall mixed effects analysis (without including ', ...
    'equivalent models)...'])
[posterior, out] = VBA_groupBMC(logModelEv);
printResults(out, modelNames)


%% Comparison of different families of models
if isequal(modelNames, ...
        {'0', 'V', 'D', 'VD', 'VC', 'VDC', 'M', 'VM', 'DM', 'VDM'})
    
    equivalenceInSet = {'0', 'D'};
    equivalenceToAdd = {'C', 'DC'};
    
    for iE = 1 : length(equivalenceInSet)
        assert(length(modelNames) == size(logModelEv, 1))
        match = strcmp(equivalenceInSet{iE}, modelNames);
        assert(sum(match) == 1)
        
        modelNames{end+1} = equivalenceToAdd{iE};
        logModelEv(end+1, :) = logModelEv(match, :);
        
        assert(length(modelNames) == size(logModelEv, 1))
    end
    
    disp(['Stats for overall mixed effects analysis (with ', ...
        'equivalent models)...'])
    [posterior, out] = VBA_groupBMC(logModelEv);
    printResults(out, modelNames)
    
    familyModelComparison('driftVar', logModelEv, modelNames)
    familyModelComparison('decreasingThresh', logModelEv, modelNames)
    familyModelComparison('conf', logModelEv, modelNames)
end
end

function familyModelComparison(familyName, logModelEv, modelNames)

if strcmp(familyName, 'driftVar')
    driftVar = find(cellfun(@(str)contains(str, 'V'), modelNames));
    noDriftVar = setdiff(1:length(modelNames), driftVar);
    
    options.families = {noDriftVar, driftVar};
    
elseif strcmp(familyName, 'decreasingThresh')
    decThresh = find(cellfun(@(str)contains(str, 'D'), modelNames));
    noDecThresh = setdiff(1:length(modelNames), decThresh);
    
    options.families = {noDecThresh, decThresh};
    
elseif strcmp(familyName, 'conf')
    calConf = find(cellfun(@(str)contains(str, 'C'), modelNames));
    miscalConf = find(cellfun(@(str)contains(str, 'M'), modelNames));
    baseConf = setdiff(1:length(modelNames), calConf);
    baseConf = setdiff(baseConf, miscalConf);
    
    options.families = {baseConf, calConf, miscalConf};
    
else
    error('Bug')
end

disp(['Stats for the ' familyName ' group analysis...'])
[posterior, out] = VBA_groupBMC(logModelEv, options);
printResults(out, modelNames)

end


function printResults(out, modelNames)

numModels = length(out.Ef);
assert(numModels == length(modelNames))

disp('Individual model results:')
for iM = 1 : numModels
    dispResultsString(modelNames{iM}, out.Ef(iM), out.ep(iM))
end

if isfield(out, 'families')
    numFamilies = length(out.families.Ef);
    disp('Family results:')
    
    for iF = 1 : numFamilies
        dispResultsString(['Family ' num2str(iF)'], ...
            out.families.Ef(iF), ...
            out.families.ep(iF))
    end
end

disp(' ')
disp(' ')

end


function dispResultsString(modelName, estFreq, exceedance)
disp([modelName '(estimated model frequency: ' ...
    '$\num[round-precision=3,round-mode=places]{' num2str(estFreq) ...
    '}$', ...
    '; exceedance probability: ' ...
    '$\num[round-precision=3,round-mode=places]{' num2str(exceedance) ...
    '}$)'])
end



