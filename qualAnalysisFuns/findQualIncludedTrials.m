function incTrial = findQualIncludedTrials(Data, blockType, verbose)
% Create an indicator variable tracking which trials should be included for
% analysis.

if length(Data) ~= 1; error('Incorrect use of inputs.'); end


%% Excldue on the basis of block type and accuracy
if strcmp(Data.GlobalPrep.Settings.AccuracyCond, 'All')

    incTrial = (~isnan(Data.Raw.Conf)) & ...
        (Data.Raw.BlockType == blockType);
        
elseif strcmp(Data.GlobalPrep.Settings.AccuracyCond, 'Correct')
    
    incTrial = (~isnan(Data.Raw.Conf)) & ...
        (Data.Raw.BlockType == blockType) & ...
        (Data.Raw.Acc == 1);
    
elseif strcmp(Data.GlobalPrep.Settings.AccuracyCond, 'Error')
    
    incTrial = (~isnan(Data.Raw.Conf)) & ...
        (Data.Raw.BlockType == blockType) & ...
        (Data.Raw.Acc == 0);
else
    Bug('Incorrect use of setting specification')
end


%% Exclude change of mind trials
if Data.GlobalPrep.Settings.ExcCoM
    
    changesOfMind = Data.Raw.Conf < 0;
    incTrial(changesOfMind) = false;
end


%% Excldue too fast trials
% Exclude trials which ocour within 
% (Settings.commitDelayExclude * nonDecisionTime) frames of
% the onset of the start of the trial

tooFast = Data.Raw.RT <= ...
    (Data.GlobalPrep.Settings.commitDelayExclude * ...
    Data.CondPrep(blockType).NonDecisTime);

incTrial(tooFast) = false;

% Defensive programming
if length(incTrial) ~= length(tooFast); error('Bug'); end

if verbose
    disp(['Individual trials excluded as too fast: ' num2str(sum(tooFast))])
end


