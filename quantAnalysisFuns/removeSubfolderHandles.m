function removeSubfolderHandles(folder)
% Search in folder for subfolders. For each subfolder load every file 
% in that subfolder. For each loaded varaible try to turn all function
% handles into strings, and resave (overwrites original data).

subfolders = dir(folder);

for iS = 1 : length(subfolders)
    subfolderName = subfolders(iS).name;

    if length(subfolderName) > 2
        thisSubfolder = fullfile(folder, subfolderName);
        disp(['*** Processing the following folder: ' subfolderName])
        processSubfolder(thisSubfolder);
    end
end

end


function processSubfolder(subfolder)

filelist = dir(subfolder);

for iF = 1 : length(filelist)
    if length(filelist(iF).name) > 2
        fullFilename = fullfile(filelist(iF).folder, filelist(iF).name);

        Loaded = load(fullFilename);
        disp(['Processing... ' filelist(iF).name])

        elements = fieldnames(Loaded);
        for iEl = 1 : length(elements)
            Loaded.(elements{iEl}) = mT_removeFunctionHandles(Loaded.(elements{iEl}), {});
        end

        save(fullFilename, '-struct', 'Loaded')
    end
end

end