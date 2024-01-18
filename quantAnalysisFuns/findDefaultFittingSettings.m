function Settings = findDefaultFittingSettings(allModels, numBins, FitRuns, varargin)
% Produce the default settings for model fitting

% INPUT
% allModels:    16, 20 or 24 letter string, or a cell array of these strings.
%               For details, see cm_computeLikeliAtIntegerPipe function 
%               comments.
% numBins:      Number of confidence bins 
% FitRuns
% varargin{1}:  Offset and scale. (Default on) Set to false to turn off.
% varargin{2}:  Integer. If provided, the fitting runs one fold of cross validation. 
%               The fold run corresponds to the integer provided. 
% varargin{3}:  Use for unusual inclusion conditions

if ~iscell(allModels)
    allModels = {allModels};
end

if isempty(varargin)
    offset = true;
    cvFold = [];
    inclusion = 'standard';
elseif length(varargin) == 1
    offset = varargin{1};
    cvFold = [];
    inclusion = 'standard';
elseif length(varargin) == 2
    offset = varargin{1};
    cvFold = varargin{2};
    inclusion = 'standard';
else
    offset = varargin{1};
    cvFold = varargin{2};
    inclusion = varargin{3};
end

if (~strcmp(inclusion, 'standard'))  && (~isempty(cvFold))
    error(['Cross validation code assumes standard inclusion criteria, ' ...
        'in runCrossValEval'])
end


%% Standard settings

% Some parameters we will constrain to be bigger than a very small number
epsilon = 10^-10;

if strcmp(inclusion, 'standard')
    baseInclusion = @(Data) ~isnan(Data.Conf);
else
    error('Incorrect use of inputs')
end

% Are we doing cross validation?
if isempty(cvFold)
    StandardSettings.FindSampleSize = @(Data) sum(baseInclusion(Data));   
    StandardSettings.FindIncludedTrials = @(Data) baseInclusion(Data);
else
    StandardSettings.FindSampleSize = @(Data) sum(baseInclusion(Data) & (~(Data.CvFold == cvFold)));
    StandardSettings.FindIncludedTrials = @(Data) baseInclusion(Data) & (~(Data.CvFold == cvFold));
end
    
% Some settings we will keep for all models
StandardSettings.Algorithm = 'fmincon';
StandardSettings.NumStartPoints = FitRuns;
StandardSettings.NumStartCand = 200;
StandardSettings.PresetStartPoints = false;
StandardSettings.TrialChunkSize = 'off';
StandardSettings.SuppressOutput = true;
StandardSettings.ReseedRng = true;
StandardSettings.DebugMode = false;
StandardSettings.JobsPerContainer = 128*30;

% The parameters have some of the same settings regarless of the model they are 
% put into, so lets define them here.
name = {...
    'Sigma_phi',    'Sigma_acc',    'Thresholds', ...
    'BoundIntercept','BoundSlope',  'PipelineI', ...
    'LapseRate',    'MetacogNoise', 'NoiseRatio'    };
unpackedShape = {...
    1,              1,              [(numBins-1), 1], ...
    1,              1,              1, ...
    1,              1,              1               };
unpackedOrder = {...
    1,              1,              (1 : (numBins-1)), ...
    1,              1,              1, ...
    1,              1,              1               };
PLB = [...
    0,              200,            -12000, ...
    100,            0,              0.05, ...
    0.01,           50,             -3               ];
PUB = [...
    2,              8000,           24000, ...
    24000,          24000,          0.8, ...
    0.4,            24000,          3               ];
lowerLim = [...
    0,              epsilon,        -36000, ...
    10,             0,              0.001, ...
    (1/640),        1,              -20               ];
upperLim = [...
    6,              24000,          72000, ...
    72000,          72000,          1, ...
    1,              72000,          20               ];
fitOffset = [...
    0,          0,           36000, ...
    -10,           0,           0, ...
    0,          -1,           0               ];
fitScale = [...
    1/6,          1/24000,           1/(36000 + 72000), ...
    1/72000,           1/72000,           1, ...
    1,          1/72000,           1/20               ];


for iParam = 1 : length(name)
    
    thisPLB = PLB(iParam);
    thisPUB = PUB(iParam);
    thisLowerLim = lowerLim(iParam);
    thisUpperLim = upperLim(iParam);
    thisShape = num2cell(unpackedShape{iParam});
    
    StandardParam(iParam).Name = name{iParam};
    StandardParam(iParam).UnpackedShape = unpackedShape{iParam};
    StandardParam(iParam).UnpackedOrder = unpackedOrder{iParam};
    StandardParam(iParam).InitialVals ...
        = @()randBetweenPoints(thisPLB, thisPUB, epsilon, thisShape{:});
    StandardParam(iParam).LowerBound = @()repmat(thisLowerLim, thisShape{:});
    StandardParam(iParam).UpperBound = @()repmat(thisUpperLim, thisShape{:});
    StandardParam(iParam).PLB = @() repmat(thisPLB, thisShape{:});
    StandardParam(iParam).PUB = @() repmat(thisPUB, thisShape{:});
    
    if offset
        StandardParam(iParam).FitOffset = fitOffset(iParam);
        StandardParam(iParam).FitScale = fitScale(iParam);
    else
        StandardParam(iParam).FitOffset = 0;
        StandardParam(iParam).FitScale = 1;
    end
end


%% Define the models

% Initialise
Settings.Algorithm = NaN;
Settings.ModelName = NaN;
Settings.NumParams = NaN;
Settings.ComputeTrialLL = struct();
Settings.NumStartPoints = NaN;
Settings.NumStartCand = NaN;
Settings.PresetStartPoints = NaN;
Settings.TrialChunkSize = NaN;
Settings.FindSampleSize = NaN;
Settings.FindIncludedTrials = NaN;
Settings.FindIfOutOfBounds = NaN;
Settings.SuppressOutput = NaN;
Settings.DebugMode = NaN;
Settings.ReseedRng = NaN;
Settings.JobsPerContainer = NaN;
Settings.Params = [];


for iModel = 1 : length(allModels)
    Settings(iModel).ModelName = allModels{iModel};
    Settings(iModel) = modifyStruct(Settings(iModel), StandardSettings);
    Settings(iModel).ComputeTrialLL.FunName = 'cm_computeTrialLL';
    Settings(iModel).ComputeTrialLL.Args = {allModels{iModel}, StandardSettings.FindIncludedTrials};
    Settings(iModel).FindIfOutOfBounds = 'none';
    
    % Which params to add depends on the model
    excludedParams = {};
    
    if strcmp(allModels{iModel}(1:4), 'NDsc') ...
            || strcmp(allModels{iModel}(1:4), 'TrDs')
        
        excludedParams{end +1} = 'NoiseRatio';
        
    elseif ~strcmp(allModels{iModel}(1:4), 'FaDs')
        error('Incorrect model specification')
    end
   
    if strcmp(allModels{iModel}(5:8), 'Flat')
        excludedParams{end +1} = 'BoundSlope';

    elseif ~strcmp(allModels{iModel}(5:8), 'Slpe')
        error('Incorrect model specification')
    end
    
    if strcmp(allModels{iModel}(9:12), 'None')
        excludedParams{end +1} = 'Sigma_phi';
    
    elseif ~strcmp(allModels{iModel}(9:12), 'Dvar')
        error('Incorrect model specification')
    end
    
    if (length(allModels{iModel}) < 17) ...
            || strcmp(allModels{iModel}(17:20), 'NoMV')
        
        excludedParams{end +1} = 'MetacogNoise';
    
    elseif ~strcmp(allModels{iModel}(17:20), 'Mvar')
        error('Incorrect model specification')
    end

    Settings(iModel) = initialiseParamStrcutArray(Settings(iModel), ...
        length(StandardParam) - length(excludedParams));
    
    paramCount = 0;
    paramSetCount = 0; 
    for iParamSet = 1 : length(StandardParam)
        
        if ~any(strcmp(StandardParam(iParamSet).Name, excludedParams))
            paramSetCount = paramSetCount +1;
            
            % If seperate params have been requested for the different block types we now
            % need to add extra params. Note that only some params are assumed
            % to vary accross blocks.
            doNotDouble = {'BoundSlope', 'BoundIntercept', 'PipelineI'};
            
            if strcmp(allModels{iModel}(13:16), 'Diff') && ...
                    ~any(strcmp(StandardParam(iParamSet).Name, doNotDouble))
                
                currentParam = mT_duplicateParams(...
                    StandardParam(iParamSet), 1, findNumBlockTypes(DSet));
            else
                currentParam = StandardParam(iParamSet);
            end
            
            Settings(iModel).Params(paramSetCount) = ...
                modifyStruct(Settings(iModel).Params(paramSetCount), currentParam);
            
            initialVals = currentParam.InitialVals();
            
            Settings(iModel).Params(paramSetCount).PackedOrder = ...
                (paramCount+1) : (paramCount + length(initialVals(:)));
            
            assert(~any(isnan(initialVals(:))))
            paramCount = paramCount + sum(~isnan(initialVals(:)));
        end
    end
    
    Settings(iModel).NumParams = paramCount;
end

end


function CompleteStruct = modifyStruct(StructA, StructB)
% Modifies the fields in StructA to match the corresponding field in
% StructB

fields = fieldnames(StructB);

for iField = 1 : length(fields)
    StructA.(fields{iField}) = StructB.(fields{iField});
end

CompleteStruct = StructA;
end


function Strcut = initialiseParamStrcutArray(Strcut, lengthOfStrcut)
% Add a 'Params' field to Strcut and initialise certain fields.

for iStruct = 1 : lengthOfStrcut
    Strcut.Params(iStruct).Name = NaN;
    Strcut.Params(iStruct).UnpackedOrder = NaN;
    Strcut.Params(iStruct).UnpackedShape = NaN;
    Strcut.Params(iStruct).InitialVals = NaN;
    Strcut.Params(iStruct).LowerBound = NaN;
    Strcut.Params(iStruct).UpperBound = NaN;
    Strcut.Params(iStruct).PLB = NaN;
    Strcut.Params(iStruct).PUB = NaN;
    Strcut.Params(iStruct).PackedOrder = NaN;
    Strcut.Params(iStruct).FitOffset = NaN;
    Strcut.Params(iStruct).FitScale = NaN;
end

end


function numBlockTypes = findNumBlockTypes(DSet)

numBlocks = NaN(length(DSet.P), 1);

for iPtpnt = 1 : length(DSet.P)    
    blocks = unique(DSet.P(iPtpnt).Data.BlockType);
    blocks(isnan(blocks)) = [];
    numBlocks(iPtpnt) = length(blocks);
end

if length(unique(numBlocks)) ~= 1
    error('All participants assumed to have same numeber of block types')
end

numBlockTypes = unique(numBlocks);

end

