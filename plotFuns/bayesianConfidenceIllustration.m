function fig = bayesianConfidenceIllustration(dependentVar, varargin)

% INPUT
% varargin{1}: If set to the string 'fullRange', the gray colour bar range
%   covers most grays. The default is to use a more limited range. 

if (~isempty(varargin)) && (~isempty(varargin{1}))
    colourRange = varargin{1};
else
    colourRange = 'limited';
end

evVec = -100:0.1:100;
tVec = 0:0.1:6;
[t, ev] = meshgrid(tVec, evVec);

if strcmp(dependentVar, 'rawEv')
    depVarVals = -ev;
    
elseif any(strcmp(dependentVar, {'pCorrect', 'logPostRatioForChoice', ...
        'logPostRatioForChoice2'}))

    if strcmp(dependentVar, {'pCorrect'})
        gamma = 0.8;
        scale = 0.05;
        
    elseif strcmp(dependentVar, {'logPostRatioForChoice'})
        gamma = 0.3;
        scale = 0.2;
        
    elseif strcmp(dependentVar, {'logPostRatioForChoice2'})
        gamma = 0.6;
        scale = 0.2;
    end
    
    logPosteriorRatio = scale*(ev ./ (1 - gamma + (gamma.*t)));

    if strcmp(dependentVar, {'pCorrect'})
        posterior = 1 ./ (1 + exp(logPosteriorRatio));
        depVarVals = posterior;
    
    elseif any(strcmp(dependentVar, {'logPostRatioForChoice', ...
        'logPostRatioForChoice2'}))
        depVarVals = -logPosteriorRatio;
    end
else
    error('Bug')
end

fig = figure;
cmap = colormap(gray);

if strcmp(colourRange, 'full')
    cmap = cmap(85:end, :);
elseif strcmp(colourRange, 'limited')
    cmap = cmap(150:end, :);
else
    error('Bug')
end

colormap(cmap);

imagesc(tVec, evVec, depVarVals);

cb = contourcbar;

if strcmp(dependentVar, 'rawEv')
    cb.YLabel.String = '\Delta Evidence';
    
elseif strcmp(dependentVar, {'pCorrect'})
    cb.YLabel.String = 'Probability correct';
    
elseif any(strcmp(dependentVar, {'logPostRatioForChoice', ...
        'logPostRatioForChoice2'}))
    caxis([-10, 10])
    cb.YLabel.String = 'Log posterior ratio for choice';
else
    error('Bug')
end

set(gca, 'TickDir', 'out')

