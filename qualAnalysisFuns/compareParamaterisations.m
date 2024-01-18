function Data = compareParamaterisations(Data, predCombos)
% Find the maximum liklihood parameters and associated statistics for a range 
% of parameterisations specified in predCombos.


%% Perform the computation
for iPtpnt = 1 : length(Data)
    for iBlockType = unique(Data(iPtpnt).Raw.BlockType)'
        
        % Initialise arrays to store results
        Stats.PredNames = cell(size(predCombos, 2), 1);
        Stats.NumCases = NaN(size(predCombos, 2), 1);
        Stats.Intercepts = NaN(...
            Data(iPtpnt).GlobalPrep.Settings.NumQuantiles -1, ...
            size(predCombos, 2));
        Stats.Slopes = NaN(size(predCombos, 1), size(predCombos, 2));
       
        if Data(iPtpnt).GlobalPrep.Exclude == 1
            
            Data(iPtpnt).Stats(iBlockType) = Stats;
            continue
        end
        
        for iCombo = 1 : size(predCombos, 2)    
            % Store the names of the predictors which are used in this combo
            allPredNames = {'Rt', 'RtSeg2', 'RtSeg3', 'RtSeg4', 'PreDecis', ...
                'Pipe', 'PostResp', 'Acc'};
     
            Stats.PredNames{iCombo} = ...
                allPredNames(find(predCombos(:, iCombo)));
            
            % Run the calculation
            Stats = evaluateParticipantLiklihood(Data, predCombos, Stats, ...
                iPtpnt, iBlockType, iCombo);
        end

        Data(iPtpnt).Stats(iBlockType) = Stats;
    end
end

    