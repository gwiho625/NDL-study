%% LSUM GCaMP-only timepoint spectra + Green/Red ratio

fullFile = '/Users/rnlghdb/NDL/MATLAB/unmixing-compare/LSUM_merge_result/ani1/ani1_LSUM_result_full.csv';
refFile  = '/Users/rnlghdb/NDL/MATLAB/unmixing-compare/LSUM_merge_result/ani1/ani1_LSUM_result_reference_spectra.csv';

full = readtable(fullFile);
ref  = readtable(refFile);

wl = ref.Wavelength_nm;

% LSUM GCaMP coefficient / reference spectrum
gcampCoef = full.Coeff_of_GCaMP;
gcampRef  = ref.GCaMP_reference;

% [T x W] each row = one timepoint GCaMP-only spectrum
GCaMP_only = gcampCoef * gcampRef';

%% Save GCaMP-only spectra

nW = numel(wl);
wlNames = "WL_" + compose("%04d", 1:nW);
wlNames = matlab.lang.makeValidName(wlNames);

outTbl = array2table(GCaMP_only, 'VariableNames', cellstr(wlNames));

outTbl = addvars(outTbl, full.Trial, full.Timepoint, ...
    'Before', 1, ...
    'NewVariableNames', {'Trial','Timepoint'});

writetable(outTbl, 'LSUM_GCaMP_only_timepoint_spectra.csv');

mapTbl = table(cellstr(wlNames(:)), wl(:), ...
    'VariableNames', {'ColumnName','Wavelength_nm'});

writetable(mapTbl, 'LSUM_GCaMP_only_wavelength_map.csv');

%% Analyze Green/Red ratio

X = GCaMP_only;   % [T x W]

meanSpec = mean(X, 1);

greenRange = wl >= 480 & wl <= 540;
redRange   = wl >= 560 & wl <= 650;

[~, idxG_local] = max(meanSpec(greenRange));
greenWLs = wl(greenRange);
greenPeakWL = greenWLs(idxG_local);

[~, idxR_local] = max(meanSpec(redRange));
redWLs = wl(redRange);
redPeakWL = redWLs(idxR_local);

[~, greenIdx] = min(abs(wl - greenPeakWL));
[~, redIdx]   = min(abs(wl - redPeakWL));

greenIntensity = X(:, greenIdx);
redIntensity   = X(:, redIdx);

ratio = redIntensity ./ greenIntensity;

fprintf('LSUM Green peak = %.2f nm\n', wl(greenIdx));
fprintf('LSUM Red peak   = %.2f nm\n', wl(redIdx));
fprintf('LSUM Ratio      = %.6f\n', mean(ratio));

result = table(full.Trial, full.Timepoint, ...
    greenIntensity, redIntensity, ratio, ...
    'VariableNames', {'Trial','Timepoint', ...
    'GCaMP_Green','GCaMP_Red','Red_Green_Ratio'});

writetable(result, 'LSUM_GCaMP_green_red_ratio.csv');

%% Plot

figure;
plot(ratio, 'LineWidth', 1.5)
xlabel('Timepoint')
ylabel('Red / Green')
title('LSUM GCaMP Red/Green Ratio')
grid on

figure;
scatter(greenIntensity, redIntensity, 10, 'filled')
xlabel('GCaMP Green intensity')
ylabel('GCaMP Red intensity')
title('LSUM GCaMP Red vs Green')
lsline
grid on