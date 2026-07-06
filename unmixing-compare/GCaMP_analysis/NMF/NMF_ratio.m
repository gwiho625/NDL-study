%% Analyze GCaMP-only green/red ratio

dataFile = 'NMF_GCaMP_only_timepoint_spectra.csv';
mapFile  = 'NMF_GCaMP_only_wavelength_map.csv';

D = readtable(dataFile);
M = readtable(mapFile);

wl = M.Wavelength_nm;
X = table2array(D(:, 2:end));  % [T x W]

% 전체 평균 GCaMP spectrum
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

fprintf('Green peak = %.2f nm\n', wl(greenIdx));
fprintf('Red peak   = %.2f nm\n', wl(redIdx));
fprintf('Ratio = %.6f\n', mean(ratio));

result = table(D.Trial, D.TrialTimepoint, D.Timepoint_Global, ...
    greenIntensity, redIntensity, ratio, ...
    'VariableNames', {'Trial','TrialTimepoint','Timepoint_Global', ...
    'GCaMP_Green','GCaMP_Red','Red_Green_Ratio'});

writetable(result, 'NMF_GCaMP_green_red_ratio.csv');

figure;
plot(ratio, 'LineWidth', 1.5)
xlabel('Timepoint')
ylabel('Red / Green')
title('NMF GCaMP Red/Green Ratio')
grid on