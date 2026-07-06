function LSUM_vs_NMF_Analyzer_GUI
% ============================================================
% LSUM vs NMF Analyzer GUI
% 전체 timepoint 기준 RMSE / MAE / R2 / Winner 자동 분석
% ============================================================

clear; clc;

%% App state
app = struct();
app.mixedFile = "";
app.lsumFullFile = "";
app.lsumRefFile = "";
app.nmfFullFile = "";
app.nmfSpecFile = "";
app.outDir = "";

app.All = table();
app.OverallSummary = table();
app.TrialSummary = table();
app.WinnerSummary = table();

%% UI
fig = uifigure('Name','LSUM vs NMF Analyzer GUI', ...
    'Position',[80 60 1500 850]);

mainGrid = uigridlayout(fig,[1 2]);
mainGrid.ColumnWidth = {360,'1x'};
mainGrid.Padding = [10 10 10 10];

%% Left panel
left = uipanel(mainGrid,'Title','Input / Controls','FontWeight','bold');
lg = uigridlayout(left,[16 1]);
lg.RowHeight = {34,24,34,24,34,24,34,24,34,24,34,34,34,34,'1x',34};
lg.Padding = [10 10 10 10];

uibutton(lg,'Text','Browse mixed merged txt/csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseMixed());
lblMixed = uilabel(lg,'Text','No mixed file','WordWrap','on');

uibutton(lg,'Text','Browse LSUM full.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseLSUMFull());
lblLSUMFull = uilabel(lg,'Text','No LSUM full','WordWrap','on');

uibutton(lg,'Text','Browse LSUM reference_spectra.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseLSUMRef());
lblLSUMRef = uilabel(lg,'Text','No LSUM reference','WordWrap','on');

uibutton(lg,'Text','Browse NMF full.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseNMFFull());
lblNMFFull = uilabel(lg,'Text','No NMF full','WordWrap','on');

uibutton(lg,'Text','Browse NMF spectra.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseNMFSpec());
lblNMFSpec = uilabel(lg,'Text','No NMF spectra','WordWrap','on');

uibutton(lg,'Text','Select output folder','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseOutDir());

uibutton(lg,'Text','RUN FULL ANALYSIS','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) runAnalysis());

uibutton(lg,'Text','Export CSV + Figures','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) exportResults());

txtStatus = uitextarea(lg,'Editable','off', ...
    'Value',{'Status: select files.'});

uibutton(lg,'Text','Close','ButtonPushedFcn',@(b,e) close(fig));

%% Right tabs
tabs = uitabgroup(mainGrid);

tabOverall = uitab(tabs,'Title','1. Overall');
tabTrial   = uitab(tabs,'Title','2. Trial summary');
tabPeak    = uitab(tabs,'Title','3. Peak / Region');
tabBox     = uitab(tabs,'Title','4. Boxplot');
tabWinner  = uitab(tabs,'Title','5. Winner');

%% Overall tab
g = uigridlayout(tabOverall,[2 2]);
g.Padding = [10 10 10 10];

axOverallRMSE = uiaxes(g);
title(axOverallRMSE,'Overall RMSE');
ylabel(axOverallRMSE,'Mean RMSE');
grid(axOverallRMSE,'on');

axOverallR2 = uiaxes(g);
title(axOverallR2,'Overall R2');
ylabel(axOverallR2,'Mean R2');
grid(axOverallR2,'on');

tblOverall = uitable(g);
tblOverall.Layout.Row = 2;
tblOverall.Layout.Column = [1 2];

%% Trial tab
g = uigridlayout(tabTrial,[2 1]);
g.Padding = [10 10 10 10];

axTrialRMSE = uiaxes(g);
title(axTrialRMSE,'Trial-wise RMSE');
xlabel(axTrialRMSE,'Trial');
ylabel(axTrialRMSE,'Mean RMSE');
grid(axTrialRMSE,'on');

tblTrial = uitable(g);

%% Peak tab
g = uigridlayout(tabPeak,[2 2]);
g.Padding = [10 10 10 10];

axRegionRMSE = uiaxes(g);
title(axRegionRMSE,'Region-wise RMSE');
ylabel(axRegionRMSE,'Mean RMSE');
grid(axRegionRMSE,'on');

axRegionMAE = uiaxes(g);
title(axRegionMAE,'Region-wise MAE');
ylabel(axRegionMAE,'Mean MAE');
grid(axRegionMAE,'on');

tblPeak = uitable(g);
tblPeak.Layout.Row = 2;
tblPeak.Layout.Column = [1 2];

%% Boxplot tab
g = uigridlayout(tabBox,[1 2]);
g.Padding = [10 10 10 10];

axBoxRMSE = uiaxes(g);
title(axBoxRMSE,'RMSE distribution');
ylabel(axBoxRMSE,'RMSE');
grid(axBoxRMSE,'on');

axBoxMAE = uiaxes(g);
title(axBoxMAE,'MAE distribution');
ylabel(axBoxMAE,'MAE');
grid(axBoxMAE,'on');

%% Winner tab
g = uigridlayout(tabWinner,[2 1]);
g.Padding = [10 10 10 10];

axWinner = uiaxes(g);
title(axWinner,'Winner count by RMSE');
ylabel(axWinner,'Count');
grid(axWinner,'on');

tblWinner = uitable(g);

%% Callbacks
    function browseMixed()
        [f,p] = uigetfile({'*.txt;*.csv'},'Select mixed merged raw file');
        if isequal(f,0), return; end
        app.mixedFile = string(fullfile(p,f));
        lblMixed.Text = f;
    end

    function browseLSUMFull()
        [f,p] = uigetfile({'*.csv'},'Select LSUM full.csv');
        if isequal(f,0), return; end
        app.lsumFullFile = string(fullfile(p,f));
        lblLSUMFull.Text = f;
    end

    function browseLSUMRef()
        [f,p] = uigetfile({'*.csv'},'Select LSUM reference_spectra.csv');
        if isequal(f,0), return; end
        app.lsumRefFile = string(fullfile(p,f));
        lblLSUMRef.Text = f;
    end

    function browseNMFFull()
        [f,p] = uigetfile({'*.csv'},'Select NMF full.csv');
        if isequal(f,0), return; end
        app.nmfFullFile = string(fullfile(p,f));
        lblNMFFull.Text = f;
    end

    function browseNMFSpec()
        [f,p] = uigetfile({'*.csv'},'Select NMF spectra.csv');
        if isequal(f,0), return; end
        app.nmfSpecFile = string(fullfile(p,f));
        lblNMFSpec.Text = f;
    end

    function browseOutDir()
        p = uigetdir(pwd,'Select output folder');
        if isequal(p,0), return; end
        app.outDir = string(p);
        txtStatus.Value = {['Output folder: ', char(app.outDir)]};
    end

    function runAnalysis()
        try
            requireFile(app.mixedFile,'mixed merged file');
            requireFile(app.lsumFullFile,'LSUM full.csv');
            requireFile(app.lsumRefFile,'LSUM reference_spectra.csv');
            requireFile(app.nmfFullFile,'NMF full.csv');
            requireFile(app.nmfSpecFile,'NMF spectra.csv');

            txtStatus.Value = {'Status: loading files...'};
            drawnow;

            [All,OverallSummary,TrialSummary,WinnerSummary] = computeAllMetrics( ...
                app.mixedFile, app.lsumFullFile, app.lsumRefFile, ...
                app.nmfFullFile, app.nmfSpecFile);

            app.All = All;
            app.OverallSummary = OverallSummary;
            app.TrialSummary = TrialSummary;
            app.WinnerSummary = WinnerSummary;

            txtStatus.Value = {
                'Status: analysis complete.'
                sprintf('Rows: %d',height(All))
                sprintf('Regions: %d',numel(unique(string(All.Region))))
                sprintf('Trials: %d',numel(unique(All.Trial)))
                };

            updateGUI();

        catch ME
            txtStatus.Value = {'Status: ERROR', ME.message};
            uialert(fig,ME.message,'Analysis error');
        end
    end

    function updateGUI()
        S = app.OverallSummary;
        T = app.TrialSummary;
        W = app.WinnerSummary;
        All = app.All;

        tblOverall.Data = S;
        tblTrial.Data = T;
        tblPeak.Data = S;
        tblWinner.Data = W;

        % Overall RMSE
        cla(axOverallRMSE);
        regions = categorical(string(S.Region));
        bar(axOverallRMSE,regions,[S.mean_LSUM_RMSE S.mean_NMF_RMSE]);
        title(axOverallRMSE,'Overall mean RMSE by region');
        ylabel(axOverallRMSE,'Mean RMSE');
        legend(axOverallRMSE,{'LSUM','NMF'},'Location','best');
        grid(axOverallRMSE,'on');

        % Overall R2
        cla(axOverallR2);
        bar(axOverallR2,regions,[S.mean_LSUM_R2 S.mean_NMF_R2]);
        title(axOverallR2,'Overall mean R2 by region');
        ylabel(axOverallR2,'Mean R2');
        legend(axOverallR2,{'LSUM','NMF'},'Location','best');
        grid(axOverallR2,'on');

        % Trial RMSE
        cla(axTrialRMSE);
        region = "Full";
        idx = string(T.Region)==region;
        trials = categorical(T.Trial(idx));
        bar(axTrialRMSE,trials,[T.mean_LSUM_RMSE(idx) T.mean_NMF_RMSE(idx)]);
        title(axTrialRMSE,'Trial-wise RMSE | Full region');
        xlabel(axTrialRMSE,'Trial');
        ylabel(axTrialRMSE,'Mean RMSE');
        legend(axTrialRMSE,{'LSUM','NMF'},'Location','best');
        grid(axTrialRMSE,'on');

        % Region RMSE
        cla(axRegionRMSE);
        bar(axRegionRMSE,regions,[S.mean_LSUM_RMSE S.mean_NMF_RMSE]);
        title(axRegionRMSE,'Region-wise RMSE');
        ylabel(axRegionRMSE,'Mean RMSE');
        legend(axRegionRMSE,{'LSUM','NMF'},'Location','best');
        grid(axRegionRMSE,'on');

        % Region MAE
        cla(axRegionMAE);
        bar(axRegionMAE,regions,[S.mean_LSUM_MAE S.mean_NMF_MAE]);
        title(axRegionMAE,'Region-wise MAE');
        ylabel(axRegionMAE,'Mean MAE');
        legend(axRegionMAE,{'LSUM','NMF'},'Location','best');
        grid(axRegionMAE,'on');

        % Boxplot RMSE
        cla(axBoxRMSE);
        values = [All.LSUM_RMSE; All.NMF_RMSE];
        group = [repmat("LSUM",height(All),1); repmat("NMF",height(All),1)];
        boxchart(axBoxRMSE,categorical(group),values);
        title(axBoxRMSE,'RMSE distribution');
        ylabel(axBoxRMSE,'RMSE');
        grid(axBoxRMSE,'on');

        % Boxplot MAE
        cla(axBoxMAE);
        values = [All.LSUM_MAE; All.NMF_MAE];
        group = [repmat("LSUM",height(All),1); repmat("NMF",height(All),1)];
        boxchart(axBoxMAE,categorical(group),values);
        title(axBoxMAE,'MAE distribution');
        ylabel(axBoxMAE,'MAE');
        grid(axBoxMAE,'on');

        % Winner
        cla(axWinner);
        winnerNames = string(W.BetterByRMSE);
        bar(axWinner,categorical(winnerNames),W.GroupCount);
        title(axWinner,'Winner count by RMSE');
        ylabel(axWinner,'Count');
        grid(axWinner,'on');
    end

    function exportResults()
        if isempty(app.All)
            uialert(fig,'먼저 RUN FULL ANALYSIS를 실행하세요.','No results');
            return;
        end

        if strlength(app.outDir)==0
            p = uigetdir(pwd,'Select output folder');
            if isequal(p,0), return; end
            app.outDir = string(p);
        end

        outDir = char(app.outDir);

        writetable(app.All,fullfile(outDir,'all_timepoint_peak_metrics.csv'));
        writetable(app.OverallSummary,fullfile(outDir,'overall_region_summary.csv'));
        writetable(app.TrialSummary,fullfile(outDir,'trial_region_summary.csv'));
        writetable(app.WinnerSummary,fullfile(outDir,'winner_count_summary.csv'));

        saveAxes(axOverallRMSE,outDir,'overall_RMSE.png');
        saveAxes(axOverallR2,outDir,'overall_R2.png');
        saveAxes(axTrialRMSE,outDir,'trial_RMSE_full.png');
        saveAxes(axRegionRMSE,outDir,'region_RMSE.png');
        saveAxes(axRegionMAE,outDir,'region_MAE.png');
        saveAxes(axBoxRMSE,outDir,'boxplot_RMSE.png');
        saveAxes(axBoxMAE,outDir,'boxplot_MAE.png');
        saveAxes(axWinner,outDir,'winner_count.png');

        uialert(fig,'CSV + figures saved.','Export complete');
    end
end

%% ============================================================
% Analysis core
% ============================================================

function [All,OverallSummary,TrialSummary,WinnerSummary] = computeAllMetrics( ...
    mixedFile,lsumFullFile,lsumRefFile,nmfFullFile,nmfSpecFile)

[wlRaw,rawSpectra] = readMixedFile(mixedFile);

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

% LSUM reconstruction
lsumWL = getColumn(LSUMRef,["Wavelength_nm","Wavelength"]);
lsumGRef = getColumn(LSUMRef,["GCaMP_reference","GCaMP"]);
lsumRRef = getColumn(LSUMRef,["jRGECO_reference","jRGECO"]);

lsumGRef = interp1(lsumWL,lsumGRef,wl,'linear',0);
lsumRRef = interp1(lsumWL,lsumRRef,wl,'linear',0);

LSUM_G = LSUM.LSUM_GCaMP_raw(:) * lsumGRef(:)';
LSUM_R = LSUM.LSUM_jRGECO_raw(:) * lsumRRef(:)';
LSUM_Recon = LSUM_G + LSUM_R + LSUM.Intercept(:);

% NMF reconstruction
nmfWL = getColumn(NMFSpec,["Wavelength_nm","Wavelength"]);
nmfGSpec = getColumn(NMFSpec,["GCaMP_spectrum","GCaMP"]);
nmfRSpec = getColumn(NMFSpec,["jRGECO_spectrum","jRGECO"]);

nmfGSpec = interp1(nmfWL,nmfGSpec,wl,'linear',0);
nmfRSpec = interp1(nmfWL,nmfRSpec,wl,'linear',0);

NMF_G = NMF.NMF_GCaMP_raw(:) * nmfGSpec(:)';
NMF_R = NMF.NMF_jRGECO_raw(:) * nmfRSpec(:)';
NMF_Recon = NMF_G + NMF_R;

% Peak regions
peakInfo = getPeakRegions(wl,nmfGSpec,nmfRSpec,15);

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

OverallSummary = groupsummary(All, {'Region'}, 'mean', ...
    {'LSUM_RMSE','NMF_RMSE','LSUM_MAE','NMF_MAE','LSUM_R2','NMF_R2'});

TrialSummary = groupsummary(All, {'Trial','Region'}, 'mean', ...
    {'LSUM_RMSE','NMF_RMSE','LSUM_MAE','NMF_MAE','LSUM_R2','NMF_R2'});

WinnerSummary = groupsummary(All, {'BetterByRMSE'});

end

%% ============================================================
% Helper functions
% ============================================================

function requireFile(f,label)
if strlength(f)==0
    error('Missing file: %s',label);
end
end

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

function saveAxes(ax,outDir,fileName)
f = figure('Visible','off','Color','w','Position',[100 100 1000 650]);
newAx = axes(f);
children = allchild(ax);
copyobj(children,newAx);
title(newAx,ax.Title.String);
xlabel(newAx,ax.XLabel.String);
ylabel(newAx,ax.YLabel.String);
grid(newAx,'on');
try
    legend(newAx,'show','Location','best');
catch
end
exportgraphics(f,fullfile(outDir,fileName),'Resolution',300);
close(f);
end