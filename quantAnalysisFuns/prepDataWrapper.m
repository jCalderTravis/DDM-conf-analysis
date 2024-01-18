function DSet = prepDataWrapper(DSet, numConfBins, breakTies)
% Wrapper function for calling prepDataForComputationalModelling with
% convenience

% INPUT
% numConfBins: How many bins to use when bin confidence

DSet.FitSpec.NumBins = numConfBins;
DSet = prepDataForComputationalModelling(DSet, 'together', breakTies);

