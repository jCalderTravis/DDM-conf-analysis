function paramVals = collectParamVals(Data, modelNum)
% Collects all the parameter values (including intercepts) in a two element cell
% array (one for each block type). The params are stored as [numParams x
% numParticipants] with the intercept params first, and then the
% slopes.

paramVals = cell(2, 1);

blockNums = unique(Data(1).Raw.BlockType)';
if size(blockNums, 1) ~= 1; error('Bug. Needs to be row vector.'); end

for iBlockType = blockNums
    
    % Find the relevant data
    relIntercepts = mT_stackData(Data, ...
        @(struct) struct.Stats(iBlockType).Intercepts(:, modelNum));
    
    relSlopes = mT_stackData(Data, ...
        @(struct) struct.Stats(iBlockType).Slopes(:, modelNum));
    
    paramVals{iBlockType} = [relIntercepts; relSlopes];
end
