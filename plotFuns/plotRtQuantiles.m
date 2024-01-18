function plotRtQuantiles(DSet, ptpnt, plotMode, figHandle, varargin)
% Plot RT quantiles seperately for correct and error, and seperately for
% the two conditions, against proportion of correct/error responses within
% the corresponding condition.

% INPUT
% ptpnt: num | str. Number of participant to use, or the string 'all' to
%   use median values accross all participants.
% plotMode: str. 'scatter-O', 'scatter-X', 'line', 'histogrBlk', 
%   'histogrDash'
% figHandle: figure handle to use. If plotMode is 'scatter' or 'line', 
%   then plots to subplot in position 1, 1 for a subplot of shape, 1 x 1. 
%   For the histogram options, four subplots are made, one for each
%   different aspect of the data.
%   Always turns "hold on" for the figure.
% varargin{1}: String. When ptpnt is set to 'all', how to average over 
%   participants? Either 'mean' or 'median'. Default is 'mean'.

if (~isempty(varargin)) && (~isempty(varargin{1}))
    plotStat = varargin{1};
else
    plotStat = 'mean';
end

figure(figHandle)

if isnumeric(ptpnt)
    [allQuantiles, allProportions, condName, quantilesEdges] ...
        = computeRtQuantiles(DSet.P(ptpnt).Data);
    
elseif strcmp(ptpnt, 'all')
    numPtpnts = length(DSet.P);
    [allQuantiles, allProportions, condName, quantilesEdges] ...
        = computeRtQuantiles(DSet.P(1).Data);
    quantSize = size(allQuantiles);
    propSize = size(allProportions);
    
    allQuantiles = nan(quantSize(1), quantSize(2), numPtpnts);
    allProportions = nan(propSize(1), propSize(2), numPtpnts);
    
    for iPtpnt = 1 : numPtpnts
        [theseQuantiles, theseProportions, condName, quantilesEdges] ...
            = computeRtQuantiles(DSet.P(iPtpnt).Data);
        allQuantiles(:, :, iPtpnt) = theseQuantiles;
        allProportions(:, :, iPtpnt) = theseProportions;
    end
    
    if any(isnan(allProportions(:)))
        error('Bug')
    end
    
    nanQuantile = isnan(allQuantiles);
    zeroProportion = allProportions == 0;
    zeroProportion = permute(zeroProportion, [2, 1, 3]);
    nanButNotZero = nanQuantile & (~zeroProportion);
    
    if any(nanButNotZero(:))
        error('Bug')
    end
    
    if any(zeroProportion(:))
        error(['There were ' num2str(sum(zeroProportion)) ' cases ', ...
            'in which there were no relevant cases. See comments ', ...
            'for how this situation could be handled.'])
        % Could take this into account when calculating the proprtion,
        % of correct and error responses, but ignore when computing the 
        % RT quantiles.
    end
    
    if strcmp(plotStat, 'mean')
        allQuantiles = nanmean(allQuantiles, 3);
        allProportions = mean(allProportions, 3);
    elseif strcmp(plotStat, 'median')
        allQuantiles = nanmedian(allQuantiles, 3);
        allProportions = median(allProportions, 3);
    else
        error('Unknown option selected')
    end
    
    assert(isequal(size(allQuantiles), quantSize))
    assert(isequal(size(allProportions), propSize))
else
    error('Incorrect use of input.')
end

numQuantiles = size(allQuantiles, 1);
numCombos = size(allQuantiles, 2); % Number of unqiue combinations of
% condition and accuracy

if any(strcmp(plotMode, {'line', 'scatter-O', 'scatter-X'}))
    subplot(1, 1, 1)
    hold on
    
    for iQuantile = 1 : numQuantiles
        combinedData = nan(numCombos, 4);
        combinedData(:, 1) = [4, 1, 3, 2]; % Specify order we want to 
        % plot the conditons in
        combinedData(:, 2) = allProportions;
        combinedData(:, 3) = allQuantiles(iQuantile, :);
        combinedData(:, 4) = 1 : length(combinedData(:, 1));
        combinedData = sortrows(combinedData);
        condNameSorted = condName(combinedData(:, 4));
        
        if strcmp(plotMode, 'line')
            plot(combinedData(:, 2), combinedData(:, 3), '--', ...
                'color', [1, 1, 1]*0.5)
            
        elseif any(strcmp(plotMode, {'scatter-O', 'scatter-X'}))
            condsToPlot = length(combinedData(:, 2));
            assert(condsToPlot == length(condNameSorted))
            
            for iCond = 1 : condsToPlot
                if startsWith(condNameSorted{iCond}, 'Free')
                    plotColour = mT_pickColour(1);
                elseif startsWith(condNameSorted{iCond}, 'Interrogation')
                    plotColour = mT_pickColour(4);
                else
                    error('Bug')
                end
                
                if strcmp(plotMode, 'scatter-O')
                    symbol = 'o';
                elseif strcmp(plotMode, 'scatter-X')
                    symbol = 'x';
                else
                    error('Bug')
                end
                
                scatter(combinedData(iCond, 2), ...
                    combinedData(iCond, 3), ...
                    symbol, ...
                    'MarkerEdgeColor', plotColour)
            end
        else
            error('Bug')
        end
    end
    
    if strcmp(plotMode, {'scatter-O'})
        legendNames = {};
        for iCNS = 1 : length(condNameSorted)
            if startsWith(condNameSorted{iCNS}, 'Free')
                legendNames{end+1} = 'Free response';
            elseif startsWith(condNameSorted{iCNS}, 'Interrogation')
                legendNames{end+1} = 'Interrogation';
            else
                error('Bug')
            end
        end
        legendNames = legendNames(1:2);
        
        legend(legendNames, 'AutoUpdate', 'off')
        legend boxoff
    end
    
    xlabel('Response proportion')
    ylabel('RT quantile (s)')
    
    set(gca, 'TickDir', 'out');
    
    text(0.4, 0.8, '\leftarrow Errors', ...
        'HorizontalAlignment', 'right')
    text(0.6, 0.8, 'Corrects \rightarrow', ...
        'HorizontalAlignment', 'left')
    
elseif any(strcmp(plotMode, {'histogrBlk', 'histogrDash'}))
    error('Option removed')
else
    error('Unknown plot mode')
end


