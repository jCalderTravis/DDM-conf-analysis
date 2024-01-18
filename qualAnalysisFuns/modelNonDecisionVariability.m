function nonDecisionTime = modelNonDecisionVariability(Data, ...
    blockType, varargin)
% Fit step function to the average dot residuals in the direction of choice in order to find
% the average time that fluctuations in the numebr of dots stops affecting the choice made.
%
% Use approach similar to that described in described here 
% https://elifesciences.org/articles/12192/figures#fig4s1 
% in the supplementary materials "Figure 4—figure supplement 1".

% INPUT
% data      Data from one participant.
% varargin{1}: bool. Make an additional plot for illustration purposes?
%   default is false. Good settings for saving this plot are: 
%   mT_exportNicePdf(15.9/2, 15.9/2, saveDir, ...
%       'nonDecisFitIllustration')

if (~isempty(varargin)) && (~isempty(varargin{1}))
    makeAdditionalPlot = varargin{1};
else
    makeAdditionalPlot = false;
end

if length(Data) ~= 1; error('Incorrect use of input arguments'); end

preRespDotsDiff = findResidualsTimeCourse(Data, blockType);

% We just want to fit to the final 12 frames.
preRespDotsDiff = preRespDotsDiff(end -11 : end);


% Test every lag between 1 frame prior to response and 10 frames prior 
% (corresponding to lags 2 to 11) and see which fits best
fitError = NaN(10, 1);
heightParam = NaN(10, 1);

for iLag = 1 : 10    
    % We want to minimise the RMS error between a step function, with a step at iLag, and the
    % average dot residuals
    computeFitStatistic = @(params)computeRmsError(params, iLag, preRespDotsDiff);
    
    % Set bounds on the height of the step
    lowerBound = 0;
    
    % Find the best fitting step height at this lag
    opts = optimoptions('fmincon','Display','notify');
    
    [heightParam(iLag), fitError(iLag)] = fmincon(computeFitStatistic, ...
        10, [], [], [], [], lowerBound, [], [], opts);
end

% Which step lag gives the best of the best fits?
[~, bestLag] = min(fitError);
nonDecisionTime = bestLag;

% Defensive programming
if nonDecisionTime ~= round(nonDecisionTime)    
    error('Bug. Expected integer')
end

% Plot fit
if makeAdditionalPlot
    thisFig = figure;
    hold on
    plot(-11:0, preRespDotsDiff, 'k')
    
    predictions = ones(1, length(preRespDotsDiff)) * heightParam(bestLag -1);
    predictions(end - bestLag + 1 : end) = 0;
    plot(-11:0, predictions, 'k--')
    
    xlabel('Stimulus frame relative to response')
    ylabel({'Average evidence fluctuations', 'for choice (dots)'})
    set(gca,'TickDir','out');
    legend('Data', 'Fitted step function')
    legend box off
    fontsize(thisFig, 10, "points")
end

end


function rmsError = computeRmsError(params, step, preRespDotsDiff) 

height = params(1);

% Create the step function specified by the params
predictions = ones(1, length(preRespDotsDiff)) * height;
predictions(end - step + 1 : end) = 0;

errorVector = preRespDotsDiff - predictions;

rmsError = (nanmean(errorVector.^2))^0.5;
% Used nanmean as will have NaNs if there were no trials which lasted 12 frames.

end






