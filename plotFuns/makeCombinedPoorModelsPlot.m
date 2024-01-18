function makeCombinedPoorModelsPlot(DSet, relModels, modelNames, ...
    plotStat, saveDir)

bothFigAxs = cell(length(relModels), 1);
iFig = 1;
for iModel = relModels
    [~, FigureHandles] = compareTrueAndPredConfBins(DSet, iModel, ...
        plotStat, 'timeButNoEv');
    theseAxes = findall(FigureHandles.TimeButNoEv.avFig, 'type', 'axes');
    thisLegend = findobj(FigureHandles.TimeButNoEv.avFig, ...
        'Type', 'Legend');
    assert(length(theseAxes)==1)
    
    % Add extra info to x-axis label
    currentLabel = theseAxes.XLabel.String;
    newLabel = {currentLabel, ['{\bf Model ' modelNames{iModel} '}']};
    xlabel(theseAxes, newLabel)
    
    bothFigAxs{iFig} = theseAxes;
    iFig = iFig +1;
end

% Combine these two plots into a single one
comFig = figure();
for iS = 1 : length(relModels)
    subAx = subplot(1, length(relModels), iS, 'parent', comFig);
    newPos = get(subAx, 'Position');
    shift = 0.1; % Add a bit of space for labels
    newPos(2) = newPos(2) +shift;
    newPos(4) = newPos(4) -shift;
    delete(subAx)
    
    if iS == length(relModels)
        copiedLegAx = copyobj([thisLegend, bothFigAxs{iS}], comFig);
        copiedAx = copiedLegAx(2);
    else
        copiedAx = copyobj(bothFigAxs{iS}, comFig);
    end
    
    set(copiedAx, 'Position', newPos);
    
    plotLable = text(copiedAx, ...
        -0.08, 1.04, ...
        ['{\bf ' char(64 + iS) ' }'], ...
        'Units', 'Normalized', ...
        'VerticalAlignment', 'Bottom');
    plotLable.FontSize = 10;
end

mT_exportNicePdf(15.9/2, 15.9, saveDir, ...
    ['models' num2str(relModels(1)) 'and' num2str(relModels(2)) '_fit_time'])
close all