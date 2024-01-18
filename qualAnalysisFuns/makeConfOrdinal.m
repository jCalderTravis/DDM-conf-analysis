function [ordinalConf, exclude] = makeConfOrdinal(Data)
% Divide confidence reports up into numQuantiles equal sized quantiles, and give a corresponding
% ordinal confidence rating.

% INPUT
% participantData       The data structure but just for one participant

% Defensive programming
if length(Data) ~= 1; error('Incorrect use of input arguments'); end
if any(Data.Raw.Conf == 99999999); error('Incorrect coding of no-response trials'); end

% Find the relevant settings
BinSettings.NumBins = Data.GlobalPrep.Settings.NumQuantiles;
BinSettings.BreakTies = Data.GlobalPrep.Settings.BreakTies;
BinSettings.EnforceZeroPoint = 0;
BinSettings.Flip = false;
BinSettings.DataType = 'ordinal';
BinSettings.SepBinning = true;
    

%% Exclusions
% If any one confidence value makes up more than 30% of the responses, 
% in either conditions, recomdend the dataset for
% exclusion.
for blockType = unique(Data.Raw.BlockType)'
    
    if sum(Data.Raw.Conf(Data.CondPrep(blockType).IncTrials)) > 0
        
        freqTable = tabulate(...
            Data.Raw.Conf(Data.CondPrep(blockType).IncTrials));
        
        if max(freqTable(:, 2)) > ...
                (0.3 * sum(Data.CondPrep(blockType).IncTrials))
            
            exclude = 1;
            disp('Exclusion made based on 30% conf criterion')
            ordinalConf = NaN;
            return
        else
            exclude = 0;
        end
    else
        error('No included trials for this case.')
    end
end


%% Make variable ordinal

% make blockType variable to pass to the function that makes ordinal
blockTypeDataVec = NaN(length(Data.Raw.Resp), 1);

for iBlockType = unique(Data.Raw.BlockType)'

    blockTypeDataVec(Data.CondPrep(iBlockType).IncTrials) = iBlockType;
end

ordinalConf = mT_makeVarOrdinal(BinSettings, Data.Raw.Conf, blockTypeDataVec);
    
    
%% Exclusions part 2. If any ordinal category contains less that 5% of responses, exclude

% Should only be a problem if we don't break ties
if ~Data.GlobalPrep.Settings.BreakTies
    
    % Look through block types
    categories = unique(ordinalConf);
    categories(isundefined(categories)) = [];
    
    for iBlockType = unique(Data.Raw.BlockType)'
        
        validCases = sum(Data.CondPrep(blockType).IncTrials);
        
        for iCategory = 1 : length(categories)
            
            casesInCat = sum(ordinalConf(Data.CondPrep(iBlockType).IncTrials) == ...
                categories(iCategory));
            
            if casesInCat < 0.05 * validCases    
                exclude = 1;
            end
        end
    end
end
    
 
%% Finish up
% Defensive programming -- check the NaNs are still NaNs
% Find trials included for analysis in any condition
incInAny = sum([Data.CondPrep(:).IncTrials], 2);


if sum((isnan(Data.Raw.Conf) ~= isundefined(ordinalConf)) & incInAny)
    
    error('Code not functioning as expected')
end




