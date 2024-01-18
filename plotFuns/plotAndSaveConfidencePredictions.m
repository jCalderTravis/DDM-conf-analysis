function plotAndSaveConfidencePredictions(DSet, modelNum, plotStat, ...
    saveDir, nameStr)
% Make various plots of model predictions for confidence given the real 
% responses and response times.

% INPUT
% modelNum: scalar. Model to use, as ordered in DSet
% nameStr: str. This is crutial for avoiding overwriting previously saved 
%   plots. This string will be inserted into the default save filenames. 
%   The default file names with no additional text inserted are the always
%   the same regardless of the other inputs, e.g. model used.

[~, FigureHandles] = compareTrueAndPredConfBins(DSet, modelNum, plotStat);

saveAllVersions(FigureHandles.TimeAndEvSep, saveDir, ...
        ['modelFit_' nameStr 'timeAndEv'], ...
        15.9/2, 15.9)

saveAllVersions(FigureHandles.TimeAndEvTogether, saveDir, ...
        ['modelFit_' nameStr 'timeAndEvTogether'], ...
        15.9/2, 15.9)

if strcmp(plotStat, 'mean')
    saveAllVersions(FigureHandles.ConfCount, saveDir, ...
        ['modelFit_' nameStr 'confCount'], ...
        15.9/2, 15.9)
    
    saveAllVersions(FigureHandles.AccWithConf, saveDir, ...
        ['modelFit_' nameStr 'accWithConf'], ...
        15.9/2, 15.9/2)
end

saveAllVersions(FigureHandles.EvResiduals, saveDir, ...
    ['modelFit_' nameStr 'evResiduals'], ...
    15.9/2, 15.9)

close all

end

function saveAllVersions(StructOfFigs, saveDir, baseName, ...
    baseHeight, baseWidth)

figNames = fieldnames(StructOfFigs);

for iF = 1 : length(figNames)
    thisName = figNames{iF};
    figure(StructOfFigs.(thisName))
    
    if strcmp(thisName, 'avFig')
        nameAdditions = '';
    else
        nameAdditions = [thisName '_'];
    end
    
    if strcmp(thisName, 'ptpntPlts')
        height = baseHeight * 8;
        width = baseWidth * 8;
    elseif strcmp(thisName, 'combFig')
        height = baseHeight * 1.4;
        width = baseWidth;
    else
        height = baseHeight;
        width = baseWidth;
    end
    
    fullName = [nameAdditions, baseName];
    mT_exportNicePdf(height, width, saveDir, fullName)
end

end





