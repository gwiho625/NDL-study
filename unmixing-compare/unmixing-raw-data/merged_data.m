%% Merge raw TXT trial files by animal - Trial column version
clear; clc;

baseFolder = '/Users/rnlghdb/NDL/MATLAB/unmixing-compare/unmixing-raw-data';

animalFolders = {'ani 1', 'ani 2'};

for a = 1:length(animalFolders)

    animalName = animalFolders{a};
    animalPath = fullfile(baseFolder, animalName);

    files = dir(fullfile(animalPath, '*.txt'));

    if isempty(files)
        warning('No txt files found in: %s', animalPath);
        continue;
    end

    fileNames = {files.name};
    [~, idx] = sort_nat(fileNames);
    files = files(idx);

    allData = table();

    fprintf('\n=============================\n');
    fprintf('Merging animal folder: %s\n', animalName);
    fprintf('=============================\n');

    for i = 1:length(files)

        filePath = fullfile(animalPath, files(i).name);

        T = readRawSpectralTxtAsTable(filePath);

        % Trial 컬럼 추가
        T.Trial = repmat(i, height(T), 1);

        % SourceFile 컬럼 추가
        T.SourceFile = repmat(string(files(i).name), height(T), 1);

        % Trial, SourceFile을 맨 앞으로 이동
        T = movevars(T, {'Trial','SourceFile'}, 'Before', 1);

        allData = [allData; T];

        fprintf('Trial %02d | %s | %d timepoints\n', ...
            i, files(i).name, height(T));
    end

    safeAnimalName = strrep(animalName, ' ', '_');

    mergedCsvPath = fullfile(baseFolder, sprintf('%s_merged.csv', safeAnimalName));
    mergedTxtPath = fullfile(baseFolder, sprintf('%s_merged.txt', safeAnimalName));

    writetable(allData, mergedCsvPath, ...
        'WriteVariableNames', true);

    writetable(allData, mergedTxtPath, ...
        'FileType','text', ...
        'Delimiter','\t', ...
        'WriteVariableNames', true);

    fprintf('\nSaved:\n');
    fprintf('%s\n', mergedCsvPath);
    fprintf('%s\n', mergedTxtPath);
    fprintf('Total merged rows: %d\n\n', height(allData));
end


%% Helper function 1: Read original raw spectral TXT as table
function T = readRawSpectralTxtAsTable(filename)

    lines = readlines(filename);

    start_idx = find(contains(lines,'>>>>>Begin Spectral Data<<<<<'),1);

    if isempty(start_idx)
        error('Cannot find Begin Spectral Data marker in file: %s', filename);
    end

    data_lines = lines(start_idx+1:end);
    data_lines = data_lines(strlength(strtrim(data_lines)) > 0);

    headerTokens = split(strtrim(data_lines(1)));
    wavelengths = str2double(headerTokens);
    wavelengths = wavelengths(~isnan(wavelengths));

    nPix = length(wavelengths);

    spectra = [];
    date_list = strings(0,1);
    time_list = strings(0,1);
    timestamp_list = strings(0,1);

    for r = 2:length(data_lines)

        row = split(strtrim(data_lines(r)));

        if length(row) < nPix + 3
            continue;
        end

        numeric_part = str2double(row(end-nPix+1:end));

        if any(isnan(numeric_part))
            continue;
        end

        spectra = [spectra; numeric_part'];

        date_list(end+1,1) = string(row(1));
        time_list(end+1,1) = string(row(2));
        timestamp_list(end+1,1) = string(row(3));
    end

    wlNames = strings(1,nPix);

    for k = 1:nPix
        wlNames(k) = "wl_" + replace(string(wavelengths(k)), ".", "_");
    end

    spectraTable = array2table(spectra, ...
        'VariableNames', cellstr(wlNames));

    metaTable = table(date_list, time_list, timestamp_list, ...
        'VariableNames', {'Date','Time','Timestamp'});

    T = [metaTable spectraTable];
end


%% Helper function 2: Natural sorting
function [sortedNames, sortIndex] = sort_nat(names)

    nums = zeros(size(names));

    for k = 1:numel(names)
        token = regexp(names{k}, '\d+', 'match');

        if ~isempty(token)
            nums(k) = str2double(token{end});
        else
            nums(k) = inf;
        end
    end

    [~, sortIndex] = sort(nums);
    sortedNames = names(sortIndex);
end