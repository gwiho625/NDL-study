function NMF_RI_Validation_GUI
% ============================================================
% NMF-RI Validation GUI
%
% 분석 범위:
%   1. Observed vs Reconstruction overlay
%   2. Residual heatmap
%   3. Time-wise R2 / RMSE
%   4. Wavelength-wise R2 / RMSE / Correlation
%   5. Estimated spectra plot
%   6. Coefficient trace z-score overlay + rolling correlation
%
% 사용법:
%   1) 이 파일을 NMF_RI_Validation_GUI.m 으로 저장
%   2) MATLAB에서 실행:
%        NMF_RI_Validation_GUI
%   3) 왼쪽에서 CSV 파일 선택
%   4) Run Analysis 클릭
%   5) 그래프 확인
%   6) Save Current Tab 또는 Save All Results 클릭
% ============================================================

clear; clc;

%% =========================
% App data structure
% =========================
app = struct();

app.files.observed = "";
app.files.recon    = "";
app.files.map      = "";
app.files.spectra  = "";
app.files.coef     = "";

app.data = struct();
app.results = struct();
app.axes = struct();

%% =========================
% Main UI
% =========================
fig = uifigure( ...
    'Name', 'NMF-RI Validation GUI', ...
    'Position', [80, 60, 1500, 850]);

mainGrid = uigridlayout(fig, [1 2]);
mainGrid.ColumnWidth = {360, '1x'};
mainGrid.RowHeight = {'1x'};

%% =========================
% Left control panel
% =========================
leftPanel = uipanel(mainGrid, ...
    'Title', 'Files / Controls', ...
    'FontWeight', 'bold');

leftGrid = uigridlayout(leftPanel, [18 2]);
leftGrid.RowHeight = { ...
    28, 28, ...
    28, 28, ...
    28, 28, ...
    28, 28, ...
    28, 28, ...
    20, ...
    35, 35, 35, ...
    20, ...
    30, 30, '1x'};
leftGrid.ColumnWidth = {105, '1x'};
leftGrid.Padding = [10 10 10 10];

uilabel(leftGrid, 'Text', 'Observed Y', 'FontWeight', 'bold');
app.ui.observedEdit = uieditfield(leftGrid, 'text', 'Editable', 'off');

uibutton(leftGrid, ...
    'Text', 'Browse observed', ...
    'ButtonPushedFcn', @(btn,event) browseFile('observed'));
uilabel(leftGrid, 'Text', 'Y = NMF input');

uilabel(leftGrid, 'Text', 'Reconstruction', 'FontWeight', 'bold');
app.ui.reconEdit = uieditfield(leftGrid, 'text', 'Editable', 'off');

uibutton(leftGrid, ...
    'Text', 'Browse recon', ...
    'ButtonPushedFcn', @(btn,event) browseFile('recon'));
uilabel(leftGrid, 'Text', 'Yhat = A*H');

uilabel(leftGrid, 'Text', 'WL map', 'FontWeight', 'bold');
app.ui.mapEdit = uieditfield(leftGrid, 'text', 'Editable', 'off');

uibutton(leftGrid, ...
    'Text', 'Browse map', ...
    'ButtonPushedFcn', @(btn,event) browseFile('map'));
uilabel(leftGrid, 'Text', 'WL_0001 → nm');

uilabel(leftGrid, 'Text', 'Spectra', 'FontWeight', 'bold');
app.ui.spectraEdit = uieditfield(leftGrid, 'text', 'Editable', 'off');

uibutton(leftGrid, ...
    'Text', 'Browse spectra', ...
    'ButtonPushedFcn', @(btn,event) browseFile('spectra'));
uilabel(leftGrid, 'Text', 'Estimated A');

uilabel(leftGrid, 'Text', 'Coefficients', 'FontWeight', 'bold');
app.ui.coefEdit = uieditfield(leftGrid, 'text', 'Editable', 'off');

uibutton(leftGrid, ...
    'Text', 'Browse coef', ...
    'ButtonPushedFcn', @(btn,event) browseFile('coef'));
uilabel(leftGrid, 'Text', 'Estimated H');

uilabel(leftGrid, 'Text', ''); 
uilabel(leftGrid, 'Text', '');

app.ui.runButton = uibutton(leftGrid, ...
    'Text', 'Run Analysis', ...
    'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(btn,event) runAnalysis());

app.ui.statusLabel = uilabel(leftGrid, ...
    'Text', 'Status: waiting for files', ...
    'FontColor', [0.2 0.2 0.2]);

app.ui.saveCurrentButton = uibutton(leftGrid, ...
    'Text', 'Save Current Tab', ...
    'ButtonPushedFcn', @(btn,event) saveCurrentTab());

app.ui.saveAllButton = uibutton(leftGrid, ...
    'Text', 'Save All Results', ...
    'ButtonPushedFcn', @(btn,event) saveAllResults());

uilabel(leftGrid, 'Text', '');
uilabel(leftGrid, 'Text', '');

uilabel(leftGrid, ...
    'Text', 'Summary', ...
    'FontWeight', 'bold');
uilabel(leftGrid, 'Text', '');

app.ui.summaryText = uitextarea(leftGrid, ...
    'Editable', 'off', ...
    'Value', {'결과가 여기에 표시됩니다.'});
app.ui.summaryText.Layout.Row = [16 18];
app.ui.summaryText.Layout.Column = [1 2];

%% =========================
% Right graph panel
% =========================
rightPanel = uipanel(mainGrid, ...
    'Title', 'Validation Plots', ...
    'FontWeight', 'bold');

rightGrid = uigridlayout(rightPanel, [1 1]);
rightGrid.Padding = [5 5 5 5];

app.ui.tabGroup = uitabgroup(rightGrid);

app.ui.tabOverlay = uitab(app.ui.tabGroup, 'Title', '1. Overlay');
app.ui.tabResidual = uitab(app.ui.tabGroup, 'Title', '2. Residual');
app.ui.tabTime = uitab(app.ui.tabGroup, 'Title', '3. Time quality');
app.ui.tabWavelength = uitab(app.ui.tabGroup, 'Title', '4. Wavelength quality');
app.ui.tabSpectra = uitab(app.ui.tabGroup, 'Title', '5. Spectra');
app.ui.tabCoef = uitab(app.ui.tabGroup, 'Title', '6. Coefficients');

%% =========================
% Create axes in tabs
% =========================

% 1. Overlay tab: 2 x 3 axes
overlayGrid = uigridlayout(app.ui.tabOverlay, [2 3]);
overlayGrid.Padding = [10 10 10 10];

for i = 1:6
    app.axes.overlay(i) = uiaxes(overlayGrid);
    title(app.axes.overlay(i), sprintf('Example %d', i));
    xlabel(app.axes.overlay(i), 'Wavelength (nm)');
    ylabel(app.axes.overlay(i), 'Intensity');
    grid(app.axes.overlay(i), 'on');
end

% 2. Residual tab: residual + absolute residual
residualGrid = uigridlayout(app.ui.tabResidual, [1 2]);
residualGrid.Padding = [10 10 10 10];

app.axes.residual = uiaxes(residualGrid);
title(app.axes.residual, 'Residual: Observed - Reconstruction');
xlabel(app.axes.residual, 'Wavelength (nm)');
ylabel(app.axes.residual, 'TimePoint');

app.axes.absResidual = uiaxes(residualGrid);
title(app.axes.absResidual, 'Absolute Residual');
xlabel(app.axes.absResidual, 'Wavelength (nm)');
ylabel(app.axes.absResidual, 'TimePoint');

% 3. Time quality tab
timeGrid = uigridlayout(app.ui.tabTime, [2 1]);
timeGrid.Padding = [10 10 10 10];

app.axes.timeR2 = uiaxes(timeGrid);
title(app.axes.timeR2, 'Time-wise R^2');
xlabel(app.axes.timeR2, 'TimePoint');
ylabel(app.axes.timeR2, 'R^2');
grid(app.axes.timeR2, 'on');

app.axes.timeRMSE = uiaxes(timeGrid);
title(app.axes.timeRMSE, 'Time-wise RMSE');
xlabel(app.axes.timeRMSE, 'TimePoint');
ylabel(app.axes.timeRMSE, 'RMSE');
grid(app.axes.timeRMSE, 'on');

% 4. Wavelength quality tab
wlGrid = uigridlayout(app.ui.tabWavelength, [3 1]);
wlGrid.Padding = [10 10 10 10];

app.axes.wlR2 = uiaxes(wlGrid);
title(app.axes.wlR2, 'Wavelength-wise R^2');
xlabel(app.axes.wlR2, 'Wavelength (nm)');
ylabel(app.axes.wlR2, 'R^2');
grid(app.axes.wlR2, 'on');

app.axes.wlRMSE = uiaxes(wlGrid);
title(app.axes.wlRMSE, 'Wavelength-wise RMSE');
xlabel(app.axes.wlRMSE, 'Wavelength (nm)');
ylabel(app.axes.wlRMSE, 'RMSE');
grid(app.axes.wlRMSE, 'on');

app.axes.wlCorr = uiaxes(wlGrid);
title(app.axes.wlCorr, 'Wavelength-wise Correlation');
xlabel(app.axes.wlCorr, 'Wavelength (nm)');
ylabel(app.axes.wlCorr, 'Correlation');
grid(app.axes.wlCorr, 'on');

% 5. Spectra tab
spectraGrid = uigridlayout(app.ui.tabSpectra, [1 1]);
spectraGrid.Padding = [10 10 10 10];

app.axes.spectra = uiaxes(spectraGrid);
title(app.axes.spectra, 'Estimated NMF Spectra');
xlabel(app.axes.spectra, 'Wavelength (nm)');
ylabel(app.axes.spectra, 'Estimated spectrum');
grid(app.axes.spectra, 'on');

% 6. Coefficients tab
coefGrid = uigridlayout(app.ui.tabCoef, [2 1]);
coefGrid.Padding = [10 10 10 10];

app.axes.coefOverlay = uiaxes(coefGrid);
title(app.axes.coefOverlay, 'Coefficient Z-score Overlay');
xlabel(app.axes.coefOverlay, 'TimePoint');
ylabel(app.axes.coefOverlay, 'Z-score');
grid(app.axes.coefOverlay, 'on');

app.axes.rollingCorr = uiaxes(coefGrid);
title(app.axes.rollingCorr, 'Rolling Correlation');
xlabel(app.axes.rollingCorr, 'TimePoint');
ylabel(app.axes.rollingCorr, 'Correlation');
grid(app.axes.rollingCorr, 'on');

%% ============================================================
% Callback: Browse file
% ============================================================
    function browseFile(fileType)
        [file, path] = uigetfile({'*.csv', 'CSV files (*.csv)'}, ...
            sprintf('Select %s file', fileType));

        if isequal(file, 0)
            return;
        end

        fullPath = fullfile(path, file);
        app.files.(fileType) = string(fullPath);

        switch fileType
            case 'observed'
                app.ui.observedEdit.Value = fullPath;
            case 'recon'
                app.ui.reconEdit.Value = fullPath;
            case 'map'
                app.ui.mapEdit.Value = fullPath;
            case 'spectra'
                app.ui.spectraEdit.Value = fullPath;
            case 'coef'
                app.ui.coefEdit.Value = fullPath;
        end

        app.ui.statusLabel.Text = sprintf('Status: selected %s', fileType);
    end

%% ============================================================
% Callback: Run analysis
% ============================================================
    function runAnalysis()

        try
            validateFiles();

            app.ui.statusLabel.Text = 'Status: loading files...';
            drawnow;

            loadData();

            app.ui.statusLabel.Text = 'Status: calculating metrics...';
            drawnow;

            calculateMetrics();

            app.ui.statusLabel.Text = 'Status: drawing plots...';
            drawnow;

            drawAllPlots();

            updateSummary();

            app.ui.statusLabel.Text = 'Status: analysis complete';

        catch ME
            app.ui.statusLabel.Text = 'Status: error';
            uialert(fig, ME.message, 'Analysis Error');
        end
    end

%% ============================================================
% Validate files
% ============================================================
    function validateFiles()
        required = {'observed', 'recon', 'map', 'spectra', 'coef'};

        for k = 1:numel(required)
            ftype = required{k};
            if strlength(app.files.(ftype)) == 0
                error('Missing file: %s', ftype);
            end

            if ~isfile(app.files.(ftype))
                error('File does not exist: %s', app.files.(ftype));
            end
        end
    end

%% ============================================================
% Load data
% ============================================================
    function loadData()

        obsTable     = readtable(app.files.observed);
        reconTable   = readtable(app.files.recon);
        mapTable     = readtable(app.files.map);
        spectraTable = readtable(app.files.spectra);
        coefTable    = readtable(app.files.coef);

        % TimePoint 확인
        if ismember('TimePoint', obsTable.Properties.VariableNames)
            time = obsTable.TimePoint;
        else
            time = (1:height(obsTable))';
        end

        % WL_ 컬럼 찾기
        wlCols = obsTable.Properties.VariableNames;
        wlCols = wlCols(startsWith(wlCols, 'WL_'));

        if isempty(wlCols)
            error('Observed file에서 WL_ 로 시작하는 wavelength columns를 찾지 못했습니다.');
        end

        % Reconstruction에도 같은 WL 컬럼이 있는지 확인
        missingCols = setdiff(wlCols, reconTable.Properties.VariableNames);
        if ~isempty(missingCols)
            error('Reconstruction file에 observed와 같은 WL_ columns가 없습니다.');
        end

        observed = table2array(obsTable(:, wlCols));
        recon    = table2array(reconTable(:, wlCols));

        % wavelength map
        if ismember('Wavelength_nm', mapTable.Properties.VariableNames)
            wavelength = mapTable.Wavelength_nm;
        else
            error('Wavelength map file에 Wavelength_nm column이 필요합니다.');
        end

        % 길이 체크
        if size(observed, 2) ~= numel(wavelength)
            error('Observed wavelength column 수와 wavelength map 길이가 다릅니다.');
        end

        if ~isequal(size(observed), size(recon))
            error('Observed와 Reconstruction matrix 크기가 다릅니다.');
        end

        app.data.obsTable = obsTable;
        app.data.reconTable = reconTable;
        app.data.mapTable = mapTable;
        app.data.spectraTable = spectraTable;
        app.data.coefTable = coefTable;

        app.data.time = time;
        app.data.wlCols = wlCols;
        app.data.wavelength = wavelength;
        app.data.observed = observed;
        app.data.recon = recon;
    end

%% ============================================================
% Calculate metrics
% ============================================================
    function calculateMetrics()

        observed = app.data.observed;
        recon = app.data.recon;
        time = app.data.time;
        wavelength = app.data.wavelength;
        spectraTable = app.data.spectraTable;
        coefTable = app.data.coefTable;

        nT = size(observed, 1);
        nW = size(observed, 2);

        residual = observed - recon;

        timeR2 = nan(nT, 1);
        timeRMSE = nan(nT, 1);

        for t = 1:nT
            y = observed(t, :);
            yhat = recon(t, :);
            timeR2(t) = calcR2(y, yhat);
            timeRMSE(t) = calcRMSE(y, yhat);
        end

        wlR2 = nan(nW, 1);
        wlRMSE = nan(nW, 1);
        wlCorr = nan(nW, 1);

        for w = 1:nW
            y = observed(:, w);
            yhat = recon(:, w);

            wlR2(w) = calcR2(y, yhat);
            wlRMSE(w) = calcRMSE(y, yhat);
            wlCorr(w) = safeCorr(y, yhat);
        end

        obsVec = observed(:);
        reconVec = recon(:);

        overallR2 = calcR2(obsVec, reconVec);
        overallRMSE = calcRMSE(obsVec, reconVec);
        overallMAE = mean(abs(obsVec - reconVec), 'omitnan');
        overallCorr = safeCorr(obsVec, reconVec);

        % Spectra columns
        [gSpec, rSpec, specWL] = getSpectraColumns(spectraTable);

        [~, gPeakIdx] = max(gSpec);
        [~, rPeakIdx] = max(rSpec);

        gPeakWl = specWL(gPeakIdx);
        rPeakWl = specWL(rPeakIdx);

        % Coefficients
        [gcamp, jrgeco] = getCoefficientColumns(coefTable);

        gcampZ = zscoreSafe(gcamp);
        jrgecoZ = zscoreSafe(jrgeco);

        coefCorr = safeCorr(gcamp, jrgeco);
        coefZCorr = safeCorr(gcampZ, jrgecoZ);

        win = 100;
        rollingCorr = nan(nT, 1);

        for i = 1:nT
            i1 = max(1, i - floor(win/2));
            i2 = min(nT, i + floor(win/2));

            x = gcampZ(i1:i2);
            y = jrgecoZ(i1:i2);

            if length(x) > 5
                rollingCorr(i) = safeCorr(x, y);
            end
        end

        % Save to app
        app.results.residual = residual;

        app.results.timeR2 = timeR2;
        app.results.timeRMSE = timeRMSE;

        app.results.wlR2 = wlR2;
        app.results.wlRMSE = wlRMSE;
        app.results.wlCorr = wlCorr;

        app.results.overallR2 = overallR2;
        app.results.overallRMSE = overallRMSE;
        app.results.overallMAE = overallMAE;
        app.results.overallCorr = overallCorr;

        app.results.specWL = specWL;
        app.results.gSpec = gSpec;
        app.results.rSpec = rSpec;
        app.results.gPeakWl = gPeakWl;
        app.results.rPeakWl = rPeakWl;

        app.results.gcamp = gcamp;
        app.results.jrgeco = jrgeco;
        app.results.gcampZ = gcampZ;
        app.results.jrgecoZ = jrgecoZ;
        app.results.coefCorr = coefCorr;
        app.results.coefZCorr = coefZCorr;
        app.results.rollingCorr = rollingCorr;
        app.results.rollingWin = win;
    end

%% ============================================================
% Draw all plots
% ============================================================
    function drawAllPlots()

        time = app.data.time;
        wavelength = app.data.wavelength;
        observed = app.data.observed;
        recon = app.data.recon;

        residual = app.results.residual;

        %% 1. Overlay
        nT = numel(time);
        exampleIdx = unique(round(linspace(1, nT, 6)));

        for i = 1:6
            ax = app.axes.overlay(i);
            cla(ax);

            if i <= numel(exampleIdx)
                idx = exampleIdx(i);

                plot(ax, wavelength, observed(idx, :), 'LineWidth', 1.5);
                hold(ax, 'on');
                plot(ax, wavelength, recon(idx, :), '--', 'LineWidth', 1.5);
                hold(ax, 'off');

                xlabel(ax, 'Wavelength (nm)');
                ylabel(ax, 'Intensity');
                title(ax, sprintf('TimePoint = %g', time(idx)));
                legend(ax, {'Observed', 'Reconstruction'}, 'Location', 'best');
                grid(ax, 'on');
            end
        end

        %% 2. Residual heatmaps
        ax = app.axes.residual;
        cla(ax);
        imagesc(ax, wavelength, time, residual);
        set(ax, 'YDir', 'normal');
        xlabel(ax, 'Wavelength (nm)');
        ylabel(ax, 'TimePoint');
        title(ax, 'Residual: Observed - Reconstruction');
        colorbar(ax);

        ax = app.axes.absResidual;
        cla(ax);
        imagesc(ax, wavelength, time, abs(residual));
        set(ax, 'YDir', 'normal');
        xlabel(ax, 'Wavelength (nm)');
        ylabel(ax, 'TimePoint');
        title(ax, 'Absolute Residual');
        colorbar(ax);

        %% 3. Time-wise quality
        ax = app.axes.timeR2;
        cla(ax);
        plot(ax, time, app.results.timeR2, 'LineWidth', 1.5);
        xlabel(ax, 'TimePoint');
        ylabel(ax, 'R^2');
        title(ax, 'Time-wise Reconstruction R^2');
        grid(ax, 'on');

        ax = app.axes.timeRMSE;
        cla(ax);
        plot(ax, time, app.results.timeRMSE, 'LineWidth', 1.5);
        xlabel(ax, 'TimePoint');
        ylabel(ax, 'RMSE');
        title(ax, 'Time-wise Reconstruction RMSE');
        grid(ax, 'on');

        %% 4. Wavelength-wise quality
        ax = app.axes.wlR2;
        cla(ax);
        plot(ax, wavelength, app.results.wlR2, 'LineWidth', 1.5);
        yline(ax, 0, '--');
        xlabel(ax, 'Wavelength (nm)');
        ylabel(ax, 'R^2');
        title(ax, 'Wavelength-wise Reconstruction R^2');
        grid(ax, 'on');

        ax = app.axes.wlRMSE;
        cla(ax);
        plot(ax, wavelength, app.results.wlRMSE, 'LineWidth', 1.5);
        xlabel(ax, 'Wavelength (nm)');
        ylabel(ax, 'RMSE');
        title(ax, 'Wavelength-wise Reconstruction RMSE');
        grid(ax, 'on');

        ax = app.axes.wlCorr;
        cla(ax);
        plot(ax, wavelength, app.results.wlCorr, 'LineWidth', 1.5);
        ylim(ax, [-1 1]);
        yline(ax, 0, '--');
        xlabel(ax, 'Wavelength (nm)');
        ylabel(ax, 'Correlation');
        title(ax, 'Wavelength-wise Observed vs Reconstruction Correlation');
        grid(ax, 'on');

        %% 5. Estimated spectra
        ax = app.axes.spectra;
        cla(ax);

        plot(ax, app.results.specWL, app.results.gSpec, 'LineWidth', 2);
        hold(ax, 'on');
        plot(ax, app.results.specWL, app.results.rSpec, 'LineWidth', 2);

        xline(ax, app.results.gPeakWl, '--', ...
            sprintf('GCaMP peak %.1f nm', app.results.gPeakWl));
        xline(ax, app.results.rPeakWl, '--', ...
            sprintf('jRGECO peak %.1f nm', app.results.rPeakWl));

        hold(ax, 'off');

        xlabel(ax, 'Wavelength (nm)');
        ylabel(ax, 'Estimated spectrum');
        title(ax, 'Estimated NMF Spectra');
        legend(ax, {'GCaMP spectrum', 'jRGECO spectrum'}, 'Location', 'best');
        grid(ax, 'on');

        %% 6. Coefficient traces
        ax = app.axes.coefOverlay;
        cla(ax);

        plot(ax, time, app.results.gcampZ, 'LineWidth', 1.3);
        hold(ax, 'on');
        plot(ax, time, app.results.jrgecoZ, 'LineWidth', 1.3);
        hold(ax, 'off');

        xlabel(ax, 'TimePoint');
        ylabel(ax, 'Z-scored coefficient');
        title(ax, sprintf('NMF Coefficient Z-score Overlay | corr = %.3f', ...
            app.results.coefZCorr));
        legend(ax, {'GCaMP z-score', 'jRGECO z-score'}, 'Location', 'best');
        grid(ax, 'on');

        ax = app.axes.rollingCorr;
        cla(ax);

        plot(ax, time, app.results.rollingCorr, 'LineWidth', 1.5);
        ylim(ax, [-1 1]);
        yline(ax, 0, '--');

        xlabel(ax, 'TimePoint');
        ylabel(ax, 'Rolling correlation');
        title(ax, sprintf('Rolling Correlation, window = %d', app.results.rollingWin));
        grid(ax, 'on');
    end

%% ============================================================
% Update summary panel
% ============================================================
    function updateSummary()

        txt = {
            '===== Data ====='
            sprintf('Time points: %d', size(app.data.observed, 1))
            sprintf('Wavelengths: %d', size(app.data.observed, 2))
            sprintf('Wavelength range: %.2f - %.2f nm', ...
                min(app.data.wavelength), max(app.data.wavelength))
            ''
            '===== Reconstruction quality ====='
            sprintf('Overall R2   : %.6f', app.results.overallR2)
            sprintf('Overall RMSE : %.6f', app.results.overallRMSE)
            sprintf('Overall MAE  : %.6f', app.results.overallMAE)
            sprintf('Overall Corr : %.6f', app.results.overallCorr)
            ''
            '===== Estimated spectra ====='
            sprintf('GCaMP peak  : %.2f nm', app.results.gPeakWl)
            sprintf('jRGECO peak : %.2f nm', app.results.rPeakWl)
            ''
            '===== Coefficient correlation ====='
            sprintf('Raw corr : %.6f', app.results.coefCorr)
            sprintf('Z corr   : %.6f', app.results.coefZCorr)
            ''
            '해석 포인트:'
            '- R2가 높으면 Y를 잘 재구성한 것'
            '- residual이 특정 파장/시간에 몰리면 문제 구간'
            '- coefficient corr가 너무 높으면 공통 artifact 가능성'
            };

        app.ui.summaryText.Value = txt;
    end

%% ============================================================
% Save current tab
% ============================================================
    function saveCurrentTab()

        if ~isfield(app, 'results') || ~isfield(app.results, 'overallR2')
            uialert(fig, '먼저 Run Analysis를 실행하세요.', 'No Results');
            return;
        end

        outDir = uigetdir(pwd, 'Select folder to save current tab');
        if isequal(outDir, 0)
            return;
        end

        currentTab = app.ui.tabGroup.SelectedTab;

        try
            if currentTab == app.ui.tabOverlay
                saveAxesGroup(app.axes.overlay, outDir, '01_overlay');

            elseif currentTab == app.ui.tabResidual
                exportgraphics(app.axes.residual, fullfile(outDir, '02_residual_heatmap.png'), 'Resolution', 300);
                exportgraphics(app.axes.absResidual, fullfile(outDir, '02_absolute_residual_heatmap.png'), 'Resolution', 300);

            elseif currentTab == app.ui.tabTime
                exportgraphics(app.axes.timeR2, fullfile(outDir, '03_timewise_R2.png'), 'Resolution', 300);
                exportgraphics(app.axes.timeRMSE, fullfile(outDir, '03_timewise_RMSE.png'), 'Resolution', 300);

            elseif currentTab == app.ui.tabWavelength
                exportgraphics(app.axes.wlR2, fullfile(outDir, '04_wavelengthwise_R2.png'), 'Resolution', 300);
                exportgraphics(app.axes.wlRMSE, fullfile(outDir, '04_wavelengthwise_RMSE.png'), 'Resolution', 300);
                exportgraphics(app.axes.wlCorr, fullfile(outDir, '04_wavelengthwise_correlation.png'), 'Resolution', 300);

            elseif currentTab == app.ui.tabSpectra
                exportgraphics(app.axes.spectra, fullfile(outDir, '05_estimated_spectra.png'), 'Resolution', 300);

            elseif currentTab == app.ui.tabCoef
                exportgraphics(app.axes.coefOverlay, fullfile(outDir, '06_coefficient_zscore_overlay.png'), 'Resolution', 300);
                exportgraphics(app.axes.rollingCorr, fullfile(outDir, '06_rolling_correlation.png'), 'Resolution', 300);
            end

            uialert(fig, 'Current tab saved successfully.', 'Saved');

        catch ME
            uialert(fig, ME.message, 'Save Error');
        end
    end

%% ============================================================
% Save all results
% ============================================================
    function saveAllResults()

        if ~isfield(app, 'results') || ~isfield(app.results, 'overallR2')
            uialert(fig, '먼저 Run Analysis를 실행하세요.', 'No Results');
            return;
        end

        outDir = uigetdir(pwd, 'Select output folder');
        if isequal(outDir, 0)
            return;
        end

        outDir = fullfile(outDir, 'NMF_validation_figures');
        if ~exist(outDir, 'dir')
            mkdir(outDir);
        end

        try
            %% Save figures
            saveAxesGroup(app.axes.overlay, outDir, '01_overlay');

            exportgraphics(app.axes.residual, fullfile(outDir, '02_residual_heatmap.png'), 'Resolution', 300);
            exportgraphics(app.axes.absResidual, fullfile(outDir, '02_absolute_residual_heatmap.png'), 'Resolution', 300);

            exportgraphics(app.axes.timeR2, fullfile(outDir, '03_timewise_R2.png'), 'Resolution', 300);
            exportgraphics(app.axes.timeRMSE, fullfile(outDir, '03_timewise_RMSE.png'), 'Resolution', 300);

            exportgraphics(app.axes.wlR2, fullfile(outDir, '04_wavelengthwise_R2.png'), 'Resolution', 300);
            exportgraphics(app.axes.wlRMSE, fullfile(outDir, '04_wavelengthwise_RMSE.png'), 'Resolution', 300);
            exportgraphics(app.axes.wlCorr, fullfile(outDir, '04_wavelengthwise_correlation.png'), 'Resolution', 300);

            exportgraphics(app.axes.spectra, fullfile(outDir, '05_estimated_spectra.png'), 'Resolution', 300);

            exportgraphics(app.axes.coefOverlay, fullfile(outDir, '06_coefficient_zscore_overlay.png'), 'Resolution', 300);
            exportgraphics(app.axes.rollingCorr, fullfile(outDir, '06_rolling_correlation.png'), 'Resolution', 300);

            %% Save summary CSV
            summaryTable = table;
            summaryTable.Metric = {
                'Overall_R2';
                'Overall_RMSE';
                'Overall_MAE';
                'Overall_Correlation';
                'GCaMP_peak_nm';
                'jRGECO_peak_nm';
                'GCaMP_jRGECO_raw_corr';
                'GCaMP_jRGECO_z_corr';
                };

            summaryTable.Value = [
                app.results.overallR2;
                app.results.overallRMSE;
                app.results.overallMAE;
                app.results.overallCorr;
                app.results.gPeakWl;
                app.results.rPeakWl;
                app.results.coefCorr;
                app.results.coefZCorr;
                ];

            writetable(summaryTable, fullfile(outDir, 'NMF_validation_summary.csv'));

            wlQualityTable = table;
            wlQualityTable.Wavelength_nm = app.data.wavelength;
            wlQualityTable.R2 = app.results.wlR2;
            wlQualityTable.RMSE = app.results.wlRMSE;
            wlQualityTable.Correlation = app.results.wlCorr;
            writetable(wlQualityTable, fullfile(outDir, 'wavelengthwise_quality.csv'));

            timeQualityTable = table;
            timeQualityTable.TimePoint = app.data.time;
            timeQualityTable.R2 = app.results.timeR2;
            timeQualityTable.RMSE = app.results.timeRMSE;
            writetable(timeQualityTable, fullfile(outDir, 'timewise_quality.csv'));

            coefTableOut = table;
            coefTableOut.TimePoint = app.data.time;
            coefTableOut.GCaMP = app.results.gcamp;
            coefTableOut.jRGECO = app.results.jrgeco;
            coefTableOut.GCaMP_Z = app.results.gcampZ;
            coefTableOut.jRGECO_Z = app.results.jrgecoZ;
            coefTableOut.RollingCorr = app.results.rollingCorr;
            writetable(coefTableOut, fullfile(outDir, 'coefficient_trace_quality.csv'));

            uialert(fig, sprintf('All results saved to:\n%s', outDir), 'Saved');

        catch ME
            uialert(fig, ME.message, 'Save Error');
        end
    end

%% ============================================================
% Utility: save overlay axes separately
% ============================================================
    function saveAxesGroup(axList, outDir, prefix)
        for ii = 1:numel(axList)
            exportgraphics(axList(ii), ...
                fullfile(outDir, sprintf('%s_%02d.png', prefix, ii)), ...
                'Resolution', 300);
        end
    end

end

%% ============================================================
% Local helper functions
% ============================================================

function r2 = calcR2(y, yhat)
    y = y(:);
    yhat = yhat(:);

    valid = isfinite(y) & isfinite(yhat);
    y = y(valid);
    yhat = yhat(valid);

    if numel(y) < 2
        r2 = NaN;
        return;
    end

    ssRes = sum((y - yhat).^2);
    ssTot = sum((y - mean(y)).^2);

    if ssTot == 0
        r2 = NaN;
    else
        r2 = 1 - ssRes / ssTot;
    end
end

function rmse = calcRMSE(y, yhat)
    y = y(:);
    yhat = yhat(:);

    valid = isfinite(y) & isfinite(yhat);
    y = y(valid);
    yhat = yhat(valid);

    if isempty(y)
        rmse = NaN;
    else
        rmse = sqrt(mean((y - yhat).^2));
    end
end

function c = safeCorr(x, y)
    x = x(:);
    y = y(:);

    valid = isfinite(x) & isfinite(y);
    x = x(valid);
    y = y(valid);

    if numel(x) < 2 || std(x) == 0 || std(y) == 0
        c = NaN;
        return;
    end

    C = corrcoef(x, y);
    c = C(1, 2);
end

function z = zscoreSafe(x)
    x = x(:);
    mu = mean(x, 'omitnan');
    sig = std(x, 'omitnan');

    if sig == 0 || isnan(sig)
        z = nan(size(x));
    else
        z = (x - mu) ./ sig;
    end
end

function [gSpec, rSpec, specWL] = getSpectraColumns(spectraTable)

    vars = spectraTable.Properties.VariableNames;

    if ismember('Wavelength_nm', vars)
        specWL = spectraTable.Wavelength_nm;
    else
        error('spectra file에 Wavelength_nm column이 필요합니다.');
    end

    if ismember('GCaMP_spectrum', vars)
        gSpec = spectraTable.GCaMP_spectrum;
    elseif ismember('GCaMP', vars)
        gSpec = spectraTable.GCaMP;
    else
        error('spectra file에서 GCaMP_spectrum 또는 GCaMP column을 찾지 못했습니다.');
    end

    if ismember('jRGECO_spectrum', vars)
        rSpec = spectraTable.jRGECO_spectrum;
    elseif ismember('jRGECO', vars)
        rSpec = spectraTable.jRGECO;
    else
        error('spectra file에서 jRGECO_spectrum 또는 jRGECO column을 찾지 못했습니다.');
    end
end

function [gcamp, jrgeco] = getCoefficientColumns(coefTable)

    vars = coefTable.Properties.VariableNames;

    if ismember('GCaMP', vars)
        gcamp = coefTable.GCaMP;
    elseif ismember('GCaMP_coefficient', vars)
        gcamp = coefTable.GCaMP_coefficient;
    elseif ismember('GCaMP_coef', vars)
        gcamp = coefTable.GCaMP_coef;
    else
        error('coefficient file에서 GCaMP column을 찾지 못했습니다.');
    end

    if ismember('jRGECO', vars)
        jrgeco = coefTable.jRGECO;
    elseif ismember('jRGECO_coefficient', vars)
        jrgeco = coefTable.jRGECO_coefficient;
    elseif ismember('jRGECO_coef', vars)
        jrgeco = coefTable.jRGECO_coef;
    else
        error('coefficient file에서 jRGECO column을 찾지 못했습니다.');
    end
end