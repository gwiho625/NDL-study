%% Save GCaMP-only timepoint spectra from NMF result

fullFile    = '/Users/rnlghdb/NDL/MATLAB/unmixing-compare/NMF-RI-merge-result/ani 1/ani1_output_full.csv';
spectraFile = '/Users/rnlghdb/NDL/MATLAB/unmixing-compare/NMF-RI-merge-result/ani 1/ani1_output_spectra.csv';

full = readtable(fullFile);
spec = readtable(spectraFile);

wl = spec.Wavelength_nm;

% 컬럼명 주의
gcampSpectrum = spec.GCaMP_spectrum;  % A(:,1)
gcampCoef     = full.GCaMP;           % H(1,:)

% [T x W] 형태: 각 row가 timepoint 하나의 GCaMP spectrum
GCaMP_only = gcampCoef * gcampSpectrum';

% 변수명 만들기
nW = numel(wl);
wlNames = "WL_" + compose("%04d", 1:nW);
wlNames = matlab.lang.makeValidName(wlNames);

outTbl = array2table(GCaMP_only, 'VariableNames', cellstr(wlNames));

% 시간 정보 붙이기
outTbl = addvars(outTbl, full.Trial, full.TrialTimepoint, full.Timepoint_Global, ...
    'Before', 1, ...
    'NewVariableNames', {'Trial','TrialTimepoint','Timepoint_Global'});

writetable(outTbl, 'NMF_GCaMP_only_timepoint_spectra.csv');

% wavelength map 저장
mapTbl = table(cellstr(wlNames(:)), wl(:), ...
    'VariableNames', {'ColumnName', 'Wavelength_nm'});

writetable(mapTbl, 'NMF_GCaMP_only_wavelength_map.csv');