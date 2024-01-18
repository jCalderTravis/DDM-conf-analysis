function runCrossValFits(DSet, modelsToFit, numFolds, mode, scheduleFolder)
% Run cross validation fitting 

% INPUT
% DSet          Standard format Data.
% modelToFit    16, 20 or 24 letter string, or a cell array of these strings.
%               For details, see cm_computeLikeliAtIntegerPipe function 
%               comments.
% numFolds      Number of cross validation folds
% mode          str. 'cluster' schedules for the cluster without a parfor 
%               loop, 'clusterPar' schedules for the cluster with a parfor
%               loop used on the cluster, and 'local' runs immediately


% Add CV fold data to the dataset
for iP = 1 : length(DSet.P)
    
    fold = [1 : numFolds]';
    nReps = ceil(length(DSet.P(iP).Data.Resp)/length(fold));
    fold = repmat(fold, nReps, 1);
    fold(length(DSet.P(iP).Data.Resp)+1:end) = [];
    fold = fold(randperm(length(fold)));
    
    DSet.P(iP).Data.CvFold = fold;  
end

% Run/schedule fits for each fold
for iFold = 1 : numFolds
    TmpDSet = DSet;
    TmpDSet.Spec.CvFold = iFold;
    TmpDSet = fitModels(TmpDSet, modelsToFit, mode, scheduleFolder, 40, iFold);
    mT_findAppliedModels(TmpDSet)
end

% Save some data for the evaluation function
numParticipants = length(DSet.P);
save([scheduleFolder '/CvData.mat'], 'numParticipants', 'numFolds', 'modelsToFit')