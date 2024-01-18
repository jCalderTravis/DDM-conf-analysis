function DSet = fitModels(DSet, allModels, mode, scheduleFolder, FitRuns, varargin)
% Fit the confidence models to the data

% INPUT
% DSet          Standard format Data.
% allModels     16, 20 or 24 letter string, or a cell array of these strings.
%               For details, see cm_computeLikeliAtIntegerPipe function 
%               comments.
% mode          str. 'cluster' schedules for the cluster without a parfor 
%               loop, 'clusterPar' schedules for the cluster with a parfor
%               loop used on the cluster, and 'local' runs immediately
% scheduleFolder: Folder to use for saving files for cluster
% FitRuns:      Number of fit runs.
% varargin:     Integer. If provided, the function runs one fold of cross 
%               validation. The fold run corresponds to the integer provided. 

if isempty(varargin)
    cvFold = [];
else
    cvFold = varargin{1};
end

% Fitting settings
DSet.FitSpec.NumBins = 4;

if mod(DSet.FitSpec.NumBins, 2) ~= 0
    error('Script assumes even num of bins')
end

Settings = findDefaultFittingSettings(allModels, DSet.FitSpec.NumBins, FitRuns, true, cvFold);

% Prep the data
DSet = prepDataForComputationalModelling(DSet, 'together', false);

% Defensive programming: Check the indecision point is the same for all
% participants.
indecisionPoint = DSet.P(1).Data.IndecisionPoint;
for iPtpnt = 1 : length(DSet.P)
    if ~isequal(indecisionPoint, DSet.P(iPtpnt).Data.IndecisionPoint)
        error('Bug')
    end
end
    
DSet = mT_scheduleFits(mode, DSet, Settings, scheduleFolder);

end






