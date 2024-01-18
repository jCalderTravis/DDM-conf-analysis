function EvDSet = convertToEvSet(DSet, computeRtQuantiles)
% Takes a dataset and converts it so that the data field doesn't give
% information about trials but about evidence samples. 

% INPUT
% DSet: Must have already applied the function preDataForComputationalModelling
% computeRtQuantiles: True or false. Adds an extra field to DSet.P(i).Data


for iP = 1 : length(DSet.P)
    
    evSetIdx = 1;
    uniqueTrial = 1;
    
    % Add a variable describing RT quantile
    if computeRtQuantiles
        for isForced = [0, 1]
            relTrials = DSet.P(iP).Data.IsForcedResp == isForced;
            edges = quantile(DSet.P(iP).Data.RtPrec(relTrials), [0, 0.25, 0.5, 0.75, 1]);
            DSet.P(iP).Data.RtQuantile(relTrials) ...
                = discretize(DSet.P(iP).Data.RtPrec(relTrials), edges); 
        end
        
        % Also a variable describing whether faster than median free
        % response
        freeTrials = ~DSet.P(iP).Data.IsForcedResp;
        medianFree = median(DSet.P(iP).Data.RtPrec(freeTrials));
        if isnan(medianFree)
            error('Bug')
        end
        
        forcedTrials = logical(DSet.P(iP).Data.IsForcedResp);
        DSet.P(iP).Data.SmallerThanFreeMedian = NaN(size(DSet.P(iP).Data.RtPrec));
        DSet.P(iP).Data.SmallerThanFreeMedian(forcedTrials) ...
            = DSet.P(iP).Data.RtPrec(forcedTrials) < medianFree;
    end
    
    % Loop over all trials
    for iTrial = 1 : length(DSet.P(iP).Data.Resp)
        
        % Skip trial if there was no permitted response
        if isnan(DSet.P(iP).Data.Resp(iTrial))
            continue
        end
        
        % Loop over all evidence samples presented
        if DSet.Spec.TimeUnit ~= 1; error('Bug. Assumes units of secs.'); end
        
        numSamples = round(DSet.P(iP).Data.ActualDurationPrec(iTrial) .* DSet.Spec.Fps);
        
        for iSample = 1 : numSamples
            EvDSet.P(iP).Data.Trial(evSetIdx, 1) = uniqueTrial;
            EvDSet.P(iP).Data.BlockType(evSetIdx, 1) ...
                = DSet.P(iP).Data.BlockType(iTrial);
            
            % Dots diff
            EvDSet.P(iP).Data.DotsDiff(evSetIdx, 1) ...
                    = DSet.P(iP).Data.DotsDiff(iTrial, iSample);
            
            % Dots diff in favour of response
            if DSet.P(iP).Data.Resp(iTrial) == 2
                EvDSet.P(iP).Data.DiffForResp(evSetIdx, 1) ...
                    = DSet.P(iP).Data.DotsDiff(iTrial, iSample);
                
            elseif DSet.P(iP).Data.Resp(iTrial) == 1
                EvDSet.P(iP).Data.DiffForResp(evSetIdx, 1) ...
                    = -DSet.P(iP).Data.DotsDiff(iTrial, iSample);
            else
                error('Bug') 
            end
            
            % Dots diff with average for stimulus location removed
            if DSet.P(iP).Data.StimLoc(iTrial) == 2
                meanDiff = DSet.P(iP).Data.Diff(iTrial);
                
            elseif DSet.P(iP).Data.StimLoc(iTrial) == 1
                meanDiff = -DSet.P(iP).Data.Diff(iTrial);
            end
            
            EvDSet.P(iP).Data.DiffDemeaned(evSetIdx, 1) ...
                = DSet.P(iP).Data.DotsDiff(iTrial, iSample) - meanDiff;
            
            % Dots diff with average for stim loc removed, in favour of response
            if DSet.P(iP).Data.Resp(iTrial) == 2
                EvDSet.P(iP).Data.DiffDemeanedForResp(evSetIdx, 1) ...
                    = EvDSet.P(iP).Data.DiffDemeaned(evSetIdx);
                
            elseif DSet.P(iP).Data.Resp(iTrial) == 1
                EvDSet.P(iP).Data.DiffDemeanedForResp(evSetIdx, 1) ...
                    = -EvDSet.P(iP).Data.DiffDemeaned(evSetIdx);    
            end    
            
            % Time
            EvDSet.P(iP).Data.Time(evSetIdx, 1) ...
                = (iSample * (1/DSet.Spec.Fps));
            
            % Time relative to repsonse
            EvDSet.P(iP).Data.TimeRelativeToResp(evSetIdx, 1) ...
                = (iSample * (1/DSet.Spec.Fps)) - DSet.P(iP).Data.RtPrec(iTrial);
            
            EvDSet.P(iP).Data.Resp(evSetIdx, 1) = DSet.P(iP).Data.Resp(iTrial);    
            EvDSet.P(iP).Data.RtPrec(evSetIdx, 1) = DSet.P(iP).Data.RtPrec(iTrial); 
            
            if computeRtQuantiles
                EvDSet.P(iP).Data.RtQuantile(evSetIdx, 1) ...
                    = DSet.P(iP).Data.RtQuantile(iTrial);
                
                EvDSet.P(iP).Data.SmallerThanFreeMedian(evSetIdx, 1) ...
                    = DSet.P(iP).Data.SmallerThanFreeMedian(iTrial);
            end
            
            EvDSet.P(iP).Data.StimLoc(evSetIdx, 1) = DSet.P(iP).Data.StimLoc(iTrial);
            EvDSet.P(iP).Data.IsForcedResp(evSetIdx, 1) = DSet.P(iP).Data.IsForcedResp(iTrial);
            EvDSet.P(iP).Data.Conf(evSetIdx, 1) = DSet.P(iP).Data.Conf(iTrial);
            EvDSet.P(iP).Data.ConfCat(evSetIdx, 1) = DSet.P(iP).Data.ConfCat(iTrial);
            
            evSetIdx = evSetIdx +1;
        end
        
        uniqueTrial = uniqueTrial +1;
    end
    
    disp(['Participant ' num2str(iP) ' complete.'])
end


