function LSUM_vs_NMF_Analyzer
% ============================================================
% LSUM vs NMF full-dataset analyzer
%
% Inputs:
%   1) Mixed merged txt/csv
%   2) LSUM full.csv
%   3) LSUM reference_spectra.csv
%   4) NMF full.csv
%   5) NMF spectra.csv
%
% Outputs:
%   - all_timepoint_peak_metrics.csv
%   - overall_region_summary.csv
%   - trial_region_summary.csv
%   - winner_count_summary.csv
%   - RMSE bar plots
%   - RMSE boxplots
% ============================================================

clear; clc;

%% Select files
[mixedFile, mixedPath] = uigetfile({'*.txt;*.csv'}, 'Select mixed merged raw file');
if isequal(mixedFile,0), return; end
mixedFile = fullfile(mixedPath,mixedFile);

[lsumFullFile, p] = uigetfile({'*.csv'}, 'Select LSUM full.csv');
if isequal(lsumFullFile,0), return; end
lsumFullFile = fullfile(p,lsumFullFile);

[lsumRefFile, p] = uigetfile({'*.csv'}, 'Select LSUM reference_spectra.csv');
if isequal(lsumRefFile,0), return; end
lsumRefFile = fullfile(p,lsumRefFile);

[nmfFullFile, p] = uigetfile({'*.csv'}, 'Select NMF full.csv');
if isequal(nmfFullFile,0), return; end
nmfFullFile = fullfile(p,nmfFullFile);

[nmfSpecFile, p] = uigetfile({'*.csv'}, 'Select NMF spectra.csv');
if isequal(nmfSpecFile,0), return; end
nmfSpecFile = fullfile(p,nmfSpecFile);

outDir = uigetdir(pwd, 'Select output folder');
if isequal(outDir,0), return; end

%% Load data
[wlRaw, rawSpectra] = readMixedFile(mixedFile);

mask = wlRaw >= 450 & wlRaw <= 700;
wl = wlRaw(mask);
obs = rawSpectra(:,mask);

LSUM = readtable(lsumFullFile,'VariableNamingRule','preserve');
NMF  = readtable(nmfFullFile,'VariableNamingRule','preserve');
LSUMRef = readtable(lsumRefFile,'VariableNamingRule','preserve');
NMFSpec = readtable(nmfSpecFile,'VariableNamingRule','preserve');

LSUM = standardizeFull(LSUM,'LSUM');
NMF  = standardizeFull(NMF,'NMF');

if height(LSUM) ~= size(obs,1)
    error('Mixed raw timepoints와 LSUM rows가 다릅니다.');
end

if height(NMF) ~= size(obs,1)
    error('Mixed raw timepoints와 NMF rows가 다릅니다.');
end

meta = NMF(:,{'Trial','TrialTimepoint','Timepoint_Global'});

%% Build reconstructions
lsumWL = getColumn(LSUMRef,["Wavelength_nm","Wavelength"]);
lsumGRef = getColumn(LSUMRef,["GCaMP_reference","GCaMP"]);
lsumRRef = getColumn(LSUMRef,["jRGECO_reference","jRGECO"]);

lsumGRef = interp1(lsumWL,lsumGRef,wl,'linear',0);
lsumRRef = interp1(lsumWL,lsumRRef,wl,'linear',0);

LSUM_G = LSUM.LSUM_GCaMP_raw(:) * lsumGRef(:)';
LSUM_R = LSUM.LSUM_jRGECO_raw(:) * lsumRRef(:)';
LSUM_Recon = LSUM_G + LSUM_R + LSUM.Intercept(:);

nmfWL = getColumn(NMFSpec,["Wavelength_nm","Wavelength"]);
nmfGSpec = getColumn(NMFSpec,["GCaMP_spectrum","GCaMP"]);
nmfRSpec = getColumn(NMFSpec,["jRGECO_spectrum","jRGECO"]);

nmfGSpec = interp1(nmfWL,nmfGSpec,wl,'linear',0);
nmfRSpec = interp1(nmfWL,nmfRSpec,wl,'linear',0);

NMF_G = NMF.NMF_GCaMP_raw(:) * nmfGSpec(:)';
NMF_R = NMF.NMF_jRGECO_raw(:) * nmfRSpec(:)';
NMF_Recon = NMF_G + NMF_R;

%% Peak region
halfWidthNm = 15;
peakInfo = getPeakRegions(wl,nmfGSpec,nmfRSpec,halfWidthNm);

fprintf('\nPeak regions:\n');
fprintf('GCaMP peak: %.2f nm | %.2f~%.2f nm\n', ...
    peakInfo.GCaMP_peak_nm, peakInfo.GCaMP_range(1), peakInfo.GCaMP_range(2));
fprintf('jRGECO peak: %.2f nm | %.2f~%.2f nm\n\n', ...
    peakInfo.jRGECO_peak_nm, peakInfo.jRGECO_range(1), peakInfo.jRGECO_range(2));

%% Compute all metrics
All = table();

for i = 1:height(meta)
    tr = meta.Trial(i);
    tt = meta.TrialTimepoint(i);
    gt = meta.Timepoint_Global(i);

    y = obs(i,:);
    yL = LSUM_Recon(i,:);
    yN = NMF_Recon(i,:);

    rows = [
        makeMetricRow(tr,tt,gt,"Full",peakInfo.Full_range, ...
            y,yL,yN,peakInfo.Full_mask);

        makeMetricRow(tr,tt,gt,"GCaMP_peak",peakInfo.GCaMP_range, ...
            y,yL,yN,peakInfo.GCaMP_mask);

        makeMetricRow(tr,tt,gt,"jRGECO_peak",peakInfo.jRGECO_range, ...
            y,yL,yN,peakInfo.jRGECO_mask)
    ];

    All = [All; rows]; %#ok<AGROW>
end

%% Save CSV
writetable(All, fullfile(outDir,'all_timepoint_peak_metrics.csv'));

OverallSummary = groupsummary(All, {'Region'}, 'mean', ...
    {'LSUM_RMSE','NMF_RMSE','LSUM_MAE','NMF_MAE','LSUM_R2','NMF_R2'});

writetable(OverallSummary, fullfile(outDir,'overall_region_summary.csv'));

TrialSummary = groupsummary(All, {'Trial','Region'}, 'mean', ...
    {'LSUM_RMSE','NMF_RMSE','LSUM_MAE','NMF_MAE','LSUM_R2','NMF_R2'});

writetable(TrialSummary, fullfile(outDir,'trial_region_summary.csv'));

WinnerSummary = groupsummary(All, {'Region','BetterByRMSE'});
writetable(WinnerSummary, fullfile(outDir,'winner_count_summary.csv'));

%% Plots
makeOverallRMSEBar(OverallSummary,outDir);
makeTrialRMSEBar(TrialSummary,outDir);
makeRMSEBoxplot(All,outDir);

fprintf('Done. Results saved to:\n%s\n', outDir);

end

%% ============================================================
% Helper functions
% ============================================================

function [wavelengths,spectra] = readMixedFile(filename)
    filename = string(filename);
    lines = readlines(filename);
    start_idx = find(contains(lines,'>>>>>Begin Spectral Data<<<<<'),1);

    if ~isempty(start_idx)
        data_lines = lines(start_idx+1:end);
        data_lines = data_lines(strlength(strtrim(data_lines)) > 0);

        header = split(strtrim(data_lines(1)));
        wavelengths = str2double(header);
        wavelengths = wavelengths(~isnan(wavelengths));
        nPix = numel(wavelengths);

        spectra = [];

        for i = 2:numel(data_lines)
            row = split(strtrim(data_lines(i)));
            if numel(row) >= nPix + 3
                numeric_part = str2double(row(end-nPix+1:end));
                if all(~isnan(numeric_part))
                    spectra = [spectra; numeric_part']; %#ok<AGROW>
                end
            end
        end
        return;
    end

    T = readtable(filename,'VariableNamingRule','preserve');
    vars = string(T.Properties.VariableNames);

    wl = nan(size(vars));
    for k = 1:numel(vars)
        name = vars(k);
        temp = str2double(name);

        if isnan(temp)
            name2 = erase(name,"wl_");
            name2 = erase(name2,"x");
            name2 = replace(name2,"_",".");
            temp = str2double(name2);
        end

        wl(k) = temp;
    end

    mask = ~isnan(wl);
    wavelengths = wl(mask);
    spectra = double(T{:,mask});
end

function T = standardizeFull(T,methodName)
    vars = string(T.Properties.VariableNames);

    if ~ismember("Trial",vars)
        error('%s file has no Trial column.',methodName);
    end

    T2 = table();
    T2.Trial = double(T.Trial);

    if ismember("TrialTimepoint",vars)
        T2.TrialTimepoint = double(T.TrialTimepoint);
    else
        T2.TrialTimepoint = makeTrialTimepointFromTrial(T2.Trial);
    end

    if ismember("Timepoint_Global",vars)
        T2.Timepoint_Global = double(T.Timepoint_Global);
    elseif ismember("TimePoint_Global",vars)
        T2.Timepoint_Global = double(T.TimePoint_Global);
    elseif ismember("Timepoint",vars)
        T2.Timepoint_Global = double(T.Timepoint);
    elseif ismember("TimePoint",vars)
        T2.Timepoint_Global = double(T.TimePoint);
    else
        T2.Timepoint_Global = (0:height(T)-1)';
    end

    gRaw = findColumn(vars,["Coeff_of_GCaMP","GCaMP"], ...
        ["z","ratio","intercept","r_squared","timepoint","trial"]);
    rRaw = findColumn(vars,["Coeff_of_jRGECO","jRGECO"], ...
        ["z","ratio","intercept","r_squared","timepoint","trial"]);

    if strlength(gRaw)==0
        error('%s file: cannot find GCaMP coefficient.',methodName);
    end
    if strlength(rRaw)==0
        error('%s file: cannot find jRGECO coefficient.',methodName);
    end

    T2.([methodName '_GCaMP_raw']) = double(T.(gRaw));
    T2.([methodName '_jRGECO_raw']) = double(T.(rRaw));

    if ismember("Intercept",vars)
        T2.Intercept = double(T.Intercept);
    else
        T2.Intercept = zeros(height(T),1);
    end

    T = T2;
end

function col = findColumn(vars,includeList,excludeList)
    col = "";
    lowerVars = lower(vars);

    for i = 1:numel(includeList)
        hit = contains(lowerVars,lower(includeList(i)));

        for j = 1:numel(excludeList)
            hit = hit & ~contains(lowerVars,lower(excludeList(j)));
        end

        idx = find(hit,1);
        if ~isempty(idx)
            col = vars(idx);
            return;
        end
    end
end

function trialTimepoint = makeTrialTimepointFromTrial(trialVec)
    trialVec = trialVec(:);
    trialTimepoint = zeros(size(trialVec));
    trials = unique(trialVec);

    for i = 1:numel(trials)
        idx = trialVec == trials(i);
        trialTimepoint(idx) = (0:sum(idx)-1)';
    end
end

function c = getColumn(T,candidates)
    vars = string(T.Properties.VariableNames);

    for i = 1:numel(candidates)
        idx = find(strcmpi(vars,candidates(i)),1);
        if ~isempty(idx)
            c = double(T.(vars(idx)));
            c = c(:);
            return;
        end
    end

    for i = 1:numel(candidates)
        idx = find(contains(lower(vars),lower(candidates(i))),1);
        if ~isempty(idx)
            c = double(T.(vars(idx)));
            c = c(:);
            return;
        end
    end

    error('Cannot find column: %s',strjoin(candidates,", "));
end

function peakInfo = getPeakRegions(wl,gSpec,rSpec,halfWidthNm)
    wl = wl(:);
    gSpec = gSpec(:);
    rSpec = rSpec(:);

    [~,idxG] = max(gSpec);
    [~,idxR] = max(rSpec);

    gPeak = wl(idxG);
    rPeak = wl(idxR);

    peakInfo = struct();
    peakInfo.GCaMP_peak_nm = gPeak;
    peakInfo.jRGECO_peak_nm = rPeak;

    peakInfo.GCaMP_mask = wl >= gPeak-halfWidthNm & wl <= gPeak+halfWidthNm;
    peakInfo.jRGECO_mask = wl >= rPeak-halfWidthNm & wl <= rPeak+halfWidthNm;
    peakInfo.Full_mask = true(size(wl));

    peakInfo.GCaMP_range = [gPeak-halfWidthNm, gPeak+halfWidthNm];
    peakInfo.jRGECO_range = [rPeak-halfWidthNm, rPeak+halfWidthNm];
    peakInfo.Full_range = [min(wl), max(wl)];
end

function metrics = calcFitMetrics(y,yhat)
    y = y(:);
    yhat = yhat(:);

    valid = isfinite(y) & isfinite(yhat);
    y = y(valid);
    yhat = yhat(valid);

    residual = y - yhat;

    metrics = struct();
    metrics.MAE = mean(abs(residual),'omitnan');
    metrics.RMSE = sqrt(mean(residual.^2,'omitnan'));
    metrics.MeanResidual = mean(residual,'omitnan');

    ssRes = sum(residual.^2,'omitnan');
    ssTot = sum((y - mean(y,'omitnan')).^2,'omitnan');

    if ssTot == 0
        metrics.R2 = NaN;
    else
        metrics.R2 = 1 - ssRes/ssTot;
    end
end

function rowTbl = makeMetricRow(trialNum,trialTimepoint,globalTimepoint,regionName,regionRange, ...
    obs,lsumRecon,nmfRecon,mask)

    L = calcFitMetrics(obs(mask),lsumRecon(mask));
    N = calcFitMetrics(obs(mask),nmfRecon(mask));

    if L.RMSE < N.RMSE
        better = "LSUM";
    elseif N.RMSE < L.RMSE
        better = "NMF";
    else
        better = "Tie";
    end

    rowTbl = table( ...
        trialNum, trialTimepoint, globalTimepoint, string(regionName), ...
        regionRange(1), regionRange(2), ...
        L.R2, N.R2, L.RMSE, N.RMSE, L.MAE, N.MAE, ...
        L.MeanResidual, N.MeanResidual, string(better), ...
        'VariableNames', { ...
            'Trial','TrialTimepoint','Timepoint_Global','Region', ...
            'RegionStart_nm','RegionEnd_nm', ...
            'LSUM_R2','NMF_R2','LSUM_RMSE','NMF_RMSE', ...
            'LSUM_MAE','NMF_MAE', ...
            'LSUM_MeanResidual','NMF_MeanResidual','BetterByRMSE'});
end

function makeOverallRMSEBar(S,outDir)
    f = figure('Color','w','Position',[100 100 900 500]);

    regions = categorical(string(S.Region));
    Y = [S.mean_LSUM_RMSE S.mean_NMF_RMSE];

    bar(regions,Y);
    ylabel('Mean RMSE');
    title('Overall mean RMSE by region');
    legend({'LSUM','NMF'},'Location','best');
    grid on;

    exportgraphics(f,fullfile(outDir,'overall_region_RMSE_bar.png'),'Resolution',300);
    close(f);
end

function makeTrialRMSEBar(S,outDir)
    regions = unique(string(S.Region));

    for r = 1:numel(regions)
        region = regions(r);
        idx = string(S.Region) == region;

        f = figure('Color','w','Position',[100 100 1000 500]);

        trials = categorical(S.Trial(idx));
        Y = [S.mean_LSUM_RMSE(idx) S.mean_NMF_RMSE(idx)];

        bar(trials,Y);
        ylabel('Mean RMSE');
        xlabel('Trial');
        title(sprintf('Trial-wise RMSE | %s',region));
        legend({'LSUM','NMF'},'Location','best');
        grid on;

        exportgraphics(f,fullfile(outDir,sprintf('trial_RMSE_%s.png',region)),'Resolution',300);
        close(f);
    end
end

function makeRMSEBoxplot(All,outDir)
    regions = unique(string(All.Region));

    for r = 1:numel(regions)
        region = regions(r);
        idx = string(All.Region) == region;

        values = [All.LSUM_RMSE(idx); All.NMF_RMSE(idx)];
        group = [repmat("LSUM",sum(idx),1); repmat("NMF",sum(idx),1)];

        f = figure('Color','w','Position',[100 100 700 500]);
        boxchart(categorical(group),values);
        ylabel('RMSE');
        title(sprintf('RMSE distribution | %s',region));
        grid on;

        exportgraphics(f,fullfile(outDir,sprintf('boxplot_RMSE_%s.png',region)),'Resolution',300);
        close(f);
    end
end