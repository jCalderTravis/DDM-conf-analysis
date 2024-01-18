function dotsDiffResiduals = findChosenDotsResiduals(Data, demean)
% Takes the [trial x frame] array Data.Raw.DotsDiff of different in dots
% between the two boxes each frame, subtracts off the mean dots difference
% (provided demean is true)
% and then signs the residuals so that a possitive dots difference
% indicates a difference in residuals supporting the choice made.

% INPUT
% demean    If 1, then the expected dots difference is subtracted off each
%           frame.

% Defensive programming
if length(Data) > 1; error('Designed for data from one ptpnt'); end

% The expected dots diff to subtract off depends on the settings
if isnumeric(Data.GlobalPrep.Settings.DotsDiff)
    
    expectedDotsDiff = Data.GlobalPrep.Settings.DotsDiff;
        
elseif strcmp(Data.GlobalPrep.Settings.DotsDiff, 'trial')
    
    expectedDotsDiff = Data.Raw.Diff;
else
    error('Incorrect use of input arguments')
end

% Defensive programming
if any(expectedDotsDiff < 0); error('Bug'); end
if size(expectedDotsDiff, 2) ~= 1; error('Bug'); end

% Now lets sign the direction of the expected dot different according to which
% target was assigned to have the higher mean that trial
expectedDotsDiff(Data.Raw.StimLoc == 1) = ...
    - expectedDotsDiff(Data.Raw.StimLoc == 1);

% First lets subtract off the mean dot difference presented each trial so that we only have the
% residuals
if demean == 1
    expectedDotsDiff = repmat(expectedDotsDiff, 1, size(Data.Raw.DotsDiff, 2));
    dotsDiffResiduals = Data.Raw.DotsDiff - expectedDotsDiff;

elseif demean == 0
    dotsDiffResiduals(:, :) = Data.Raw.DotsDiff;
    warning ('Residuals not subtracted off.')
else
    error('Demean settings not specified.')
end

% Second lets rearange dotDifference so it gives us the dots difference in the chosen direction
dotsDiffResiduals( Data.Raw.Resp == 1, :) = -dotsDiffResiduals( Data.Raw.Resp == 1, :);
