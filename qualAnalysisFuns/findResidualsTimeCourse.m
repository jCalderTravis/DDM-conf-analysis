function preRespDotsDiff = findResidualsTimeCourse(Data, blockType)
% Find the average dot residuals in the direction of choice leading up to a response.

% INPUT
% Data      Data from one participant.

if length(Data) ~= 1; error('Incorrect use of input arguments'); end

% First find the dots residuals each frame in the direction of the choice
dotsDiffResid = findChosenDotsResiduals(Data, 1);

% Now lets extract the dots leading up to a response, and line them up towards the right of a matrix
preRespDotsDiff = NaN( size(dotsDiffResid, 1),  size(dotsDiffResid, 2));

for iTrial = 1 : size(dotsDiffResid, 1)
    
    % Check there was a valid confidence report, and that the trial is from the relevant blockType
    if ~isnan(Data.Raw.Conf(iTrial)) && Data.Raw.BlockType(iTrial) == blockType
        
        relFrames = dotsDiffResid(iTrial, 1 : Data.Raw.RT(iTrial));        
        preRespDotsDiff(iTrial, end - length(relFrames) +1 : end) = relFrames;
    end
end

% Average over all trials
preRespDotsDiff = nanmean(preRespDotsDiff);