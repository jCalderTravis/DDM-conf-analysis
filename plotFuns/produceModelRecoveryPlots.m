function produceModelRecoveryPlots(fitsFolder, modelNames, ...
    paramPltsModelNum, saveDir, extraName)

[AllDSet, FigureHandles] = mT_analyseClusterResults(fitsFolder, ...
    1, true, false, true, modelNames, true);

mT_plotParameterFits(AllDSet{paramPltsModelNum}, ...
    paramPltsModelNum, 'scatter', false)
mT_exportNicePdf(15.9, 15.9, saveDir, [extraName 'parameterRecovery'])

figure(FigureHandles.AicModelRecovery)
mT_exportNicePdf(15.9/2, 15, saveDir, [extraName 'AicModelRecovery'])

figure(FigureHandles.BicModelRecovery)
mT_exportNicePdf(15.9/2, 15, saveDir, [extraName 'BicModelRecovery'])

close all

end