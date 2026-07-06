function GH_NMF_RI_Photometry
    % =====================================================================
    % NMF-RI Blind / Semi-blind Spectral Unmixing for Fiber Photometry
    % Animal merged + Trial column compatible version
    % =====================================================================

    fig = uifigure('Name', 'NMF-RI Blind Unmixing — Animal Merged Compatible', ...
        'Position', [80, 60, 1250, 820]);

    tabGroup = uitabgroup(fig, 'Position', [20, 20, 1210, 780]);
    tab1 = uitab(tabGroup, 'Title', '1. Data');
    tab2 = uitab(tabGroup, 'Title', '2. NMF-RI Settings');
    tab3 = uitab(tabGroup, 'Title', '3. Results');

    %% App state
    appState = struct();
    appState.mixedFile = '';
    appState.gcampFile = '';
    appState.jrgecoFile = '';
    appState.Y = [];
    appState.Y_prep = [];
    appState.wavelengths = [];
    appState.A = [];
    appState.H = [];
    appState.A0 = [];
    appState.nIter = 0;

    appState.time_info = [];
    appState.trial_info = [];
    appState.source_info = [];

    %% ===================== Tab 1: Data =====================
    uilabel(tab1, 'Position', [30, 730, 600, 24], ...
        'Text', '데이터 입력', 'FontWeight', 'bold', 'FontSize', 14);

    uilabel(tab1, 'Position', [30, 695, 500, 22], ...
        'Text', '① 혼합 스펙트럼 시계열 (animal merged TXT/CSV)', 'FontWeight', 'bold');
    uibutton(tab1, 'Position', [30, 668, 220, 26], ...
        'Text', 'Browse merged TXT/CSV...', ...
        'ButtonPushedFcn', @(b,e) browse_mixed());
    lblMixed = uilabel(tab1, 'Position', [260, 668, 500, 26], ...
        'Text', 'No file selected', 'FontColor', [0.5 0.5 0.5]);

    uilabel(tab1, 'Position', [30, 635, 600, 22], ...
        'Text', '② GCaMP CSV (FPbase.org — 이론적 스펙트럼, 초기값용)', 'FontWeight', 'bold');
    uibutton(tab1, 'Position', [30, 608, 220, 26], ...
        'Text', 'Browse GCaMP CSV...', ...
        'ButtonPushedFcn', @(b,e) browse_gcamp());
    lblGcamp = uilabel(tab1, 'Position', [260, 608, 500, 26], ...
        'Text', 'No file selected', 'FontColor', [0.5 0.5 0.5]);

    uilabel(tab1, 'Position', [30, 575, 600, 22], ...
        'Text', '③ jRGECO CSV (FPbase.org — 이론적 스펙트럼, 초기값용)', 'FontWeight', 'bold');
    uibutton(tab1, 'Position', [30, 548, 220, 26], ...
        'Text', 'Browse jRGECO CSV...', ...
        'ButtonPushedFcn', @(b,e) browse_jrgeco());
    lblJrgeco = uilabel(tab1, 'Position', [260, 548, 500, 26], ...
        'Text', 'No file selected', 'FontColor', [0.5 0.5 0.5]);

    uilabel(tab1, 'Position', [30, 510, 200, 22], ...
        'Text', '파장 범위 (nm):', 'FontWeight', 'bold');
    uilabel(tab1, 'Position', [30, 484, 50, 22], 'Text', 'Min:');
    txtWLMin = uieditfield(tab1, 'text', 'Position', [80, 484, 90, 22], 'Value', '450');
    uilabel(tab1, 'Position', [185, 484, 50, 22], 'Text', 'Max:');
    txtWLMax = uieditfield(tab1, 'text', 'Position', [235, 484, 90, 22], 'Value', '650');

    uilabel(tab1, 'Position', [30, 448, 200, 22], ...
        'Text', '성분 이름:', 'FontWeight', 'bold');
    uilabel(tab1, 'Position', [30, 422, 100, 22], 'Text', 'Component 1:');
    txtName1 = uieditfield(tab1, 'text', 'Position', [130, 422, 150, 22], 'Value', 'GCaMP');
    uilabel(tab1, 'Position', [30, 396, 100, 22], 'Text', 'Component 2:');
    txtName2 = uieditfield(tab1, 'text', 'Position', [130, 396, 150, 22], 'Value', 'jRGECO');

    axInit = uiaxes(tab1, 'Position', [450, 350, 730, 360]);
    title(axInit, '초기 스펙트럼 A0 미리보기');
    xlabel(axInit, 'Wavelength (nm)');
    ylabel(axInit, 'Normalized intensity');

    uibutton(tab1, 'Position', [30, 340, 380, 34], ...
        'Text', '데이터 로드 및 초기 스펙트럼 확인', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) load_data());

    txtDataStatus = uilabel(tab1, 'Position', [30, 290, 1150, 40], ...
        'Text', '', 'WordWrap', 'on', 'FontColor', [0.3 0.3 0.3]);

    uibutton(tab1, 'Position', [30, 250, 200, 34], ...
        'Text', 'Continue to Settings >>', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) set(tabGroup, 'SelectedTab', tab2));

    %% ===================== Tab 2: NMF-RI Settings =====================
    uilabel(tab2, 'Position', [30, 730, 800, 24], ...
        'Text', 'NMF-RI 파라미터', ...
        'FontWeight', 'bold', 'FontSize', 14);

    uilabel(tab2, 'Position', [30, 695, 800, 40], 'WordWrap', 'on', ...
        'FontColor', [0.4 0.4 0.4], ...
        'Text', ['Sparse timepoint를 선택한 뒤 NMF-RI를 실행하고, ', ...
        '최종 A를 이용해 전체 시계열 H를 NNLS로 계산합니다.']);

    uilabel(tab2, 'Position', [30, 645, 300, 22], ...
        'Text', 'theta1 (intraLayer 수렴 기준):');
    txtTheta1 = uieditfield(tab2, 'text', 'Position', [300, 645, 100, 22], 'Value', '0.01');

    uilabel(tab2, 'Position', [30, 615, 300, 22], ...
        'Text', 'theta2 (interLayer 수렴 기준):');
    txtTheta2 = uieditfield(tab2, 'text', 'Position', [300, 615, 100, 22], 'Value', '0.01');

    uilabel(tab2, 'Position', [30, 585, 300, 22], ...
        'Text', 'alphaA (스펙트럼 sparsity 가중치):');
    txtAlphaA = uieditfield(tab2, 'text', 'Position', [300, 585, 100, 22], 'Value', '0.001');

    uilabel(tab2, 'Position', [30, 555, 300, 22], ...
        'Text', 'alphaX (농도 sparsity 가중치):');
    txtAlphaX = uieditfield(tab2, 'text', 'Position', [300, 555, 100, 22], 'Value', '0.001');

    uilabel(tab2, 'Position', [30, 515, 500, 40], 'WordWrap', 'on', ...
        'Text', 'Sparseness threshold (기본 0.7 = sparsest 30% 선택):');
    txtThrs = uieditfield(tab2, 'text', 'Position', [300, 490, 100, 22], 'Value', '0.7');

    uibutton(tab2, 'Position', [30, 440, 380, 40], ...
        'Text', 'Run NMF-RI', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) run_nmf_ri());

    axLOF = uiaxes(tab2, 'Position', [520, 300, 650, 400]);
    title(axLOF, '초기 A0 대비 최종 A 변화량');
    xlabel(axLOF, 'Metric');
    ylabel(axLOF, '||A0 - A final||');

    txtRunStatus = uilabel(tab2, 'Position', [30, 390, 1150, 40], ...
        'Text', '', 'WordWrap', 'on', 'FontColor', [0.3 0.3 0.3]);

    uibutton(tab2, 'Position', [30, 340, 200, 34], ...
        'Text', 'Continue to Results >>', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(b,e) go_to_results());

    %% ===================== Tab 3: Results =====================
    axSpec = uiaxes(tab3, 'Position', [30, 430, 560, 310]);
    title(axSpec, 'Resolved Spectra (A) — NMF-RI 추정');
    xlabel(axSpec, 'Wavelength (nm)');
    ylabel(axSpec, 'Normalized intensity');

    axConc = uiaxes(tab3, 'Position', [620, 430, 560, 310]);
    title(axConc, 'Concentration Profile (H) — 시계열');
    xlabel(axConc, 'Timepoint');
    ylabel(axConc, 'Intensity (a.u.)');

    axRecon = uiaxes(tab3, 'Position', [30, 90, 1150, 310]);
    title(axRecon, 'Observed vs Reconstructed (Preprocessed, Timepoint 0)');
    xlabel(axRecon, 'Wavelength (nm)');
    ylabel(axRecon, 'Intensity');

    uilabel(tab3, 'Position', [30, 60, 200, 22], 'Text', '결과 파일 이름:');
    txtOutName = uieditfield(tab3, 'text', 'Position', [200, 60, 250, 22], ...
        'Value', 'NMF_RI_output');

    uibutton(tab3, 'Position', [470, 56, 220, 30], ...
        'Text', 'Download full + trial CSV', ...
        'ButtonPushedFcn', @(b,e) download_results());

    txtOutStatus = uilabel(tab3, 'Position', [710, 60, 450, 30], ...
        'Text', '', 'FontColor', [0.3 0.3 0.3], 'WordWrap', 'on');

    %% ===================== Callback functions =====================

    function browse_mixed()
        [file, path] = uigetfile({'*.txt;*.csv', 'Merged TXT/CSV files (*.txt, *.csv)'}, ...
            'Select animal merged data');
        if isequal(file, 0), return; end
        appState.mixedFile = fullfile(path, file);
        lblMixed.Text = file;
    end

    function browse_gcamp()
        [file, path] = uigetfile({'*.csv', 'CSV files'}, ...
            'Select GCaMP CSV');
        if isequal(file, 0), return; end
        appState.gcampFile = fullfile(path, file);
        lblGcamp.Text = file;
    end

    function browse_jrgeco()
        [file, path] = uigetfile({'*.csv', 'CSV files'}, ...
            'Select jRGECO CSV');
        if isequal(file, 0), return; end
        appState.jrgecoFile = fullfile(path, file);
        lblJrgeco.Text = file;
    end

    function load_data()
        if isempty(appState.mixedFile) || isempty(appState.gcampFile) || isempty(appState.jrgecoFile)
            uialert(fig, '세 파일을 모두 선택해주세요.', '파일 누락');
            return;
        end

        wl_min = str2double(txtWLMin.Value);
        wl_max = str2double(txtWLMax.Value);

        if isnan(wl_min) || isnan(wl_max) || wl_min >= wl_max
            uialert(fig, '파장 범위를 올바르게 입력해주세요.', '파장 범위 오류');
            return;
        end

        [wl, spectra, time_info, trial_info, source_info] = readMixedTxt(appState.mixedFile);

        mask = wl >= wl_min & wl <= wl_max;
        if ~any(mask)
            uialert(fig, '선택한 파장 범위에 해당하는 데이터가 없습니다.', '파장 범위 오류');
            return;
        end

        wl_crop = wl(mask);
        D = spectra(:, mask);   % [T x W]
        Y = D';                 % [W x T]

        [W, Tn] = size(Y);

        try
            a_gcamp = loadFPbaseEmission(appState.gcampFile, wl_crop);
            a_jrgeco = loadFPbaseEmission(appState.jrgecoFile, wl_crop);
        catch ME
            uialert(fig, ME.message, 'FPbase CSV 읽기 오류');
            return;
        end

        A0 = [a_gcamp(:), a_jrgeco(:)];
        A0(A0 <= 0) = 100 * eps;
        A0 = A0 * diag(1 ./ (sum(A0, 1) + eps));

        appState.Y = Y;
        appState.wavelengths = wl_crop;
        appState.A0 = A0;
        appState.Y_prep = [];
        appState.A = [];
        appState.H = [];
        appState.time_info = time_info;
        appState.trial_info = trial_info;
        appState.source_info = source_info;

        cla(axInit);
        hold(axInit, 'on');
        plot(axInit, wl_crop, A0(:,1), 'g-', 'LineWidth', 2, ...
            'DisplayName', [txtName1.Value, ' (A0)']);
        plot(axInit, wl_crop, A0(:,2), 'r-', 'LineWidth', 2, ...
            'DisplayName', [txtName2.Value, ' (A0)']);
        hold(axInit, 'off');
        legend(axInit, 'show', 'Location', 'best');

        if ~isempty(trial_info)
            nTrial = numel(unique(trial_info));
            trialMsg = sprintf(', Trial column detected: %d trials', nTrial);
        else
            trialMsg = ', no Trial column';
        end

        txtDataStatus.Text = sprintf( ...
            '로딩 완료: Y = [%d x %d] (파장 x 시점), 파장 %.0f~%.0f nm%s', ...
            W, Tn, wl_min, wl_max, trialMsg);
    end

    function run_nmf_ri()

        if isempty(appState.Y) || isempty(appState.A0)
            uialert(fig, '먼저 Tab 1에서 데이터를 로드해주세요.', '데이터 없음');
            return;
        end

        if exist('NMF_RI', 'file') ~= 2
            uialert(fig, 'NMF_RI.m이 MATLAB 경로에 없습니다.', 'NMF_RI.m 없음');
            return;
        end

        theta1 = str2double(txtTheta1.Value);
        theta2 = str2double(txtTheta2.Value);
        alphaA = str2double(txtAlphaA.Value);
        alphaX = str2double(txtAlphaX.Value);
        Thrs   = str2double(txtThrs.Value);

        if any(isnan([theta1, theta2, alphaA, alphaX, Thrs]))
            uialert(fig, 'NMF-RI 파라미터를 숫자로 입력해주세요.', '파라미터 오류');
            return;
        end

        if Thrs <= 0 || Thrs >= 1
            uialert(fig, 'Sparseness threshold는 0과 1 사이 값이어야 합니다.', '파라미터 오류');
            return;
        end

        Y  = appState.Y;
        A0 = appState.A0;

        d = uiprogressdlg(fig, 'Title', 'NMF-RI 실행 중', ...
            'Message', '전처리 및 sparse timepoint 선택 중...', ...
            'Indeterminate', 'on');

        try
            %% 1. Preprocessing
            Y_prep = Y - min(Y, [], 1);
            Y_prep(Y_prep <= 0) = 100 * eps;

            %% 2. Initial H estimation using NNLS
            H0_full = computeNNLS(A0, Y_prep);

            %% 3. Sparseness score
            SPS = (sqrt(size(H0_full,1)) - ...
                (sum(abs(H0_full),1) ./ sqrt(sum(H0_full.^2,1)))) / ...
                (sqrt(size(H0_full,1)) - 1);

            SPS(isnan(SPS)) = 0;

            %% 4. Select sparsest timepoints
            thresh = quantile(SPS, Thrs);
            sparseMask = SPS >= thresh;
            Y_sps = Y_prep(:, sparseMask);

            if isempty(Y_sps) || size(Y_sps, 2) < size(A0, 2)
                error('Sparse timepoint가 너무 적습니다. Thrs 값을 낮춰보세요.');
            end

            H_sps = computeNNLS(A0, Y_sps);

            d.Message = sprintf('NMF_RI 실행 중... sparse 시점 %d개 / 전체 %d개', ...
                size(Y_sps,2), size(Y_prep,2));

            %% 5. NMF-RI
            [A_nmf, ~, nIter] = NMF_RI(Y_sps, A0, H_sps, ...
                theta1, theta2, alphaA, alphaX);

            %% 6. Final H for full time-series using NNLS
            H_full = computeNNLS(A_nmf, Y_prep);

            close(d);

            appState.Y_prep = Y_prep;
            appState.A = A_nmf;
            appState.H = H_full;
            appState.nIter = nIter;

            txtRunStatus.Text = sprintf( ...
                '완료. %d회 반복. Sparse %d/%d 시점 사용. 전체 H 계산 완료.', ...
                nIter, size(Y_sps,2), size(Y_prep,2));

            cla(axLOF);
            bar(axLOF, sum(sum(abs(A0 - A_nmf))));
            title(axLOF, sprintf('초기 A0 대비 최종 A 변화량: %.4f', ...
                sum(sum(abs(A0 - A_nmf)))));
            ylabel(axLOF, '||A0 - A final||');

        catch ME
            if isvalid(d)
                close(d);
            end
            uialert(fig, sprintf('오류: %s', ME.message), 'NMF-RI 실행 오류');
        end
    end

    function go_to_results()
        if isempty(appState.A) || isempty(appState.H)
            uialert(fig, '먼저 Tab 2에서 NMF-RI를 실행해주세요.', '결과 없음');
            return;
        end

        tabGroup.SelectedTab = tab3;
        plot_results();
    end

    function plot_results()
        A = appState.A;
        H = appState.H;
        wl = appState.wavelengths;

        if ~isempty(appState.Y_prep)
            Yplot = appState.Y_prep;
        else
            Yplot = appState.Y;
        end

        name1 = txtName1.Value;
        name2 = txtName2.Value;
        Tn = size(H, 2);

        cla(axSpec);
        hold(axSpec, 'on');
        plot(axSpec, wl, A(:,1), 'g-', 'LineWidth', 2, 'DisplayName', name1);
        plot(axSpec, wl, A(:,2), 'r-', 'LineWidth', 2, 'DisplayName', name2);
        hold(axSpec, 'off');
        legend(axSpec, 'show', 'Location', 'best');
        title(axSpec, 'Resolved Spectra (A) — NMF-RI 추정');

        cla(axConc);
        hold(axConc, 'on');
        plot(axConc, 0:Tn-1, H(1,:), 'g-', 'LineWidth', 1.0, 'DisplayName', name1);
        plot(axConc, 0:Tn-1, H(2,:), 'r-', 'LineWidth', 1.0, 'DisplayName', name2);
        hold(axConc, 'off');
        legend(axConc, 'show', 'Location', 'best');
        title(axConc, 'Concentration Profile (H) — 시계열');
        xlabel(axConc, 'Timepoint Global');

        Y_recon = A * H;

        cla(axRecon);
        hold(axRecon, 'on');
        plot(axRecon, wl, Yplot(:,1), 'k-', 'LineWidth', 1.5, ...
            'DisplayName', 'Observed preprocessed (t=0)');
        plot(axRecon, wl, Y_recon(:,1), 'b--', 'LineWidth', 1.5, ...
            'DisplayName', 'Reconstructed (t=0)');
        hold(axRecon, 'off');
        legend(axRecon, 'show', 'Location', 'best');
        title(axRecon, 'Observed vs Reconstructed (Preprocessed, Timepoint 0)');
    end

    function download_results()
        if isempty(appState.H) || isempty(appState.A)
            uialert(fig, '결과가 없습니다.', '저장 불가');
            return;
        end

        saveFolder = uigetdir(pwd, 'NMF-RI 결과 저장 폴더 선택');
        if isequal(saveFolder, 0)
            return;
        end

        baseName = string(strtrim(txtOutName.Value));
        if strlength(baseName) == 0
            baseName = "NMF_RI_output";
        end

        name1 = matlab.lang.makeValidName(txtName1.Value);
        name2 = matlab.lang.makeValidName(txtName2.Value);

        if strcmp(name1, name2)
            name1 = [name1 '_1'];
            name2 = [name2 '_2'];
        end

        Tn = size(appState.H, 2);

        %% 1) Concentration profile H 저장
        H1 = appState.H(1,:)';
        H2 = appState.H(2,:)';

        Tbl = table( ...
            (0:Tn-1)', ...
            H1, ...
            H2, ...
            safeZScore(H1), ...
            safeZScore(H2), ...
            'VariableNames', {'Timepoint_Global', name1, name2, ...
                              [name1 '_z_global'], [name2 '_z_global']});

        if ~isempty(appState.trial_info)
            trialVec = appState.trial_info(:);
            trialTimepoint = makeTrialTimepoint(trialVec);

            Tbl = addvars(Tbl, trialVec, trialTimepoint, ...
                'Before', 1, ...
                'NewVariableNames', {'Trial', 'TrialTimepoint'});

            Tbl.([name1 '_z_trial']) = zeros(Tn,1);
            Tbl.([name2 '_z_trial']) = zeros(Tn,1);

            trialNums = unique(trialVec);
            for i = 1:length(trialNums)
                idx = trialVec == trialNums(i);
                Tbl.([name1 '_z_trial'])(idx) = safeZScore(H1(idx));
                Tbl.([name2 '_z_trial'])(idx) = safeZScore(H2(idx));
            end
        end

        outFile = fullfile(saveFolder, baseName + "_full.csv");
        writetable(Tbl, outFile);

        %% 2) Trial별 H 저장
        trialFolder = "";
        if ismember('Trial', Tbl.Properties.VariableNames)
            trialFolder = fullfile(saveFolder, baseName + "_trials");

            if ~exist(trialFolder, 'dir')
                mkdir(trialFolder);
            end

            trialNums = unique(Tbl.Trial);

            for i = 1:length(trialNums)
                trialNum = trialNums(i);
                trialTbl = Tbl(Tbl.Trial == trialNum, :);

                trialFile = fullfile(trialFolder, ...
                    sprintf('%s_trial%02d.csv', baseName, trialNum));

                writetable(trialTbl, trialFile);
            end
        end

        %% 3) Resolved spectra A 저장
        specFile = fullfile(saveFolder, baseName + "_spectra.csv");

        SpecTbl = table( ...
            appState.wavelengths(:), ...
            appState.A(:,1), ...
            appState.A(:,2), ...
            'VariableNames', {'Wavelength_nm', [name1 '_spectrum'], [name2 '_spectrum']});

        writetable(SpecTbl, specFile);

        %% 4) Reconstruction 저장
        reconFile = fullfile(saveFolder, baseName + "_reconstruction.csv");

        Y_recon = appState.A * appState.H;
        ReconTbl = makeWideSpectrumTable(Y_recon', appState.wavelengths, Tbl);
        writetable(ReconTbl, reconFile);

        %% 5) Observed preprocessed spectrum 저장
        observedFile = fullfile(saveFolder, baseName + "_observed_preprocessed.csv");

        if ~isempty(appState.Y_prep)
            Y_obs = appState.Y_prep;
        else
            Y_obs = appState.Y;
        end

        ObsTbl = makeWideSpectrumTable(Y_obs', appState.wavelengths, Tbl);
        writetable(ObsTbl, observedFile);

        %% 6) Reconstruction wavelength map 저장
        mapFile = fullfile(saveFolder, baseName + "_reconstruction_wavelength_map.csv");

        nW = numel(appState.wavelengths);
        reconVarNames = "WL_" + compose("%04d", 1:nW);
        reconVarNames = matlab.lang.makeValidName(reconVarNames);
        reconVarNames = matlab.lang.makeUniqueStrings(reconVarNames);

        MapTbl = table( ...
            cellstr(reconVarNames(:)), ...
            appState.wavelengths(:), ...
            'VariableNames', {'ReconstructionColumn', 'Wavelength_nm'});

        writetable(MapTbl, mapFile);

        %% 완료 표시
        if strlength(trialFolder) > 0
            trialMsg = sprintf('\n\nTrial별 H:\n%s', trialFolder);
        else
            trialMsg = sprintf('\n\n주의: Trial 컬럼이 없어서 trial별 H 저장은 생략됨.');
        end

        txtOutStatus.Text = sprintf('저장 완료: %s', outFile);

        uialert(fig, sprintf([ ...
            '저장 완료:\n\n', ...
            'Concentration H full:\n%s', ...
            '%s\n\n', ...
            'Resolved spectra A:\n%s\n\n', ...
            'Reconstruction A*H:\n%s\n\n', ...
            'Observed preprocessed:\n%s\n\n', ...
            'Wavelength map:\n%s'], ...
            outFile, trialMsg, specFile, reconFile, observedFile, mapFile), ...
            'CSV 저장 완료');
    end
end

%% ===================== Helper functions =====================

function em = loadFPbaseEmission(csvFile, wl_target)
    T = readtable(csvFile, 'VariableNamingRule', 'preserve');

    if width(T) < 2
        error('FPbase CSV는 최소 2개 이상의 열이 필요합니다: %s', csvFile);
    end

    wl_col = T{:,1};

    if ~isnumeric(wl_col)
        wl_col = str2double(string(wl_col));
    end

    colNames = string(T.Properties.VariableNames);
    emIdx = [];

    for i = 2:numel(colNames)
        name = lower(colNames(i));

        isEmission = contains(name, 'em') || ...
                     contains(name, 'emission') || ...
                     contains(name, 'fluorescence');

        isExcitation = contains(name, 'ex') || ...
                       contains(name, 'excitation');

        isTwoPhoton = contains(name, '2p') || ...
                      contains(name, 'two-photon') || ...
                      contains(name, 'twophoton');

        if isEmission && ~isExcitation && ~isTwoPhoton
            emIdx = i;
            break;
        end
    end

    if isempty(emIdx)
        emIdx = 2;
        warning('emission 컬럼명을 명확히 찾지 못해 2번째 열을 사용합니다: %s', csvFile);
    end

    raw = T{:, emIdx};

    if ~isnumeric(raw)
        raw = str2double(string(raw));
    end

    valid = ~isnan(raw) & ~isnan(wl_col);
    wl_src = wl_col(valid);
    em_src = raw(valid);

    if isempty(wl_src) || isempty(em_src)
        error('유효한 wavelength/emission 데이터가 없습니다: %s', csvFile);
    end

    [wl_src, sidx] = sort(wl_src);
    em_src = em_src(sidx);

    [wl_src, uniqueIdx] = unique(wl_src, 'stable');
    em_src = em_src(uniqueIdx);

    em_src = em_src - min(em_src);

    maxEm = max(em_src);

    if maxEm > 0
        em_src = em_src / maxEm;
    else
        error('Emission intensity가 모두 0입니다: %s', csvFile);
    end

    em = interp1(wl_src, em_src, wl_target, 'linear', 0);
    em = max(em, 0);
    em = em(:);
end

function [wavelengths, spectra, time_info, trial_info, source_info] = readMixedTxt(filename)
    lines = readlines(filename);

    start_idx = find(contains(lines, '>>>>>Begin Spectral Data<<<<<'), 1);

    %% Case 1: original raw TXT format
    if ~isempty(start_idx)
        data_lines = lines(start_idx + 1:end);
        data_lines = data_lines(strlength(strtrim(data_lines)) > 0);

        parsed = cell(length(data_lines), 1);

        for i = 1:length(data_lines)
            parsed{i} = split(strtrim(data_lines(i)));
        end

        wavelengths = str2double(parsed{1});
        wavelengths = wavelengths(~isnan(wavelengths));
        nPix = length(wavelengths);

        spectra = [];
        date_list = strings(0,1);
        time_list = strings(0,1);
        timestamp_list = strings(0,1);

        for i = 2:length(parsed)
            row = parsed{i};

            if length(row) >= nPix + 3
                numeric_part = str2double(row(end-nPix+1:end));

                if sum(isnan(numeric_part)) == 0
                    spectra = [spectra; numeric_part']; %#ok<AGROW>
                    date_list(end+1,1) = string(row(1)); %#ok<AGROW>
                    time_list(end+1,1) = string(row(2)); %#ok<AGROW>
                    timestamp_list(end+1,1) = string(row(3)); %#ok<AGROW>
                end
            end
        end

        if isempty(spectra)
            error('No valid spectral rows found in mixed TXT file: %s', filename);
        end

        time_info = [date_list, time_list, timestamp_list];
        trial_info = [];
        source_info = [];
        return;
    end

    %% Case 2: merged TXT/CSV table format
    firstLine = char(lines(1));

    if contains(firstLine, ',')
        delim = ',';
    else
        delim = '\t';
    end

    T = readtable(filename, ...
        'FileType','text', ...
        'Delimiter',delim, ...
        'VariableNamingRule','preserve');

    varNames = string(T.Properties.VariableNames);

    trial_info = [];
    source_info = [];
    time_info = [];

    if ismember("Trial", varNames)
        trial_info = double(T.("Trial"));
    end

    if ismember("SourceFile", varNames)
        source_info = string(T.("SourceFile"));
    end

    if all(ismember(["Date","Time","Timestamp"], varNames))
        time_info = [string(T.("Date")), string(T.("Time")), string(T.("Timestamp"))];
    end

    wl = nan(size(varNames));

    for k = 1:numel(varNames)
        name = varNames(k);

        temp = str2double(name);

        if isnan(temp)
            name2 = erase(name, "wl_");
            name2 = erase(name2, "x");
            name2 = replace(name2, "_", ".");
            temp = str2double(name2);
        end

        wl(k) = temp;
    end

    wavelengthMask = ~isnan(wl);
    wavelengths = wl(wavelengthMask);

    if isempty(wavelengths)
        disp("Detected variable names:");
        disp(varNames(1:min(20,numel(varNames))));
        error('No wavelength columns found. Check merged file format.');
    end

    spectra = T{:, wavelengthMask};

    if ~isnumeric(spectra)
        spectra = str2double(string(spectra));
    end

    spectra = double(spectra);
end

function H = computeNNLS(A, Y)
    nComp = size(A, 2);
    nTime = size(Y, 2);

    H = zeros(nComp, nTime);

    for t = 1:nTime
        H(:, t) = lsqnonneg(A, Y(:, t));
    end

    H = max(H, 100 * eps);
end

function z = safeZScore(x)
    x = double(x(:));
    s = std(x);

    if s == 0 || isnan(s)
        z = zeros(size(x));
    else
        z = (x - mean(x)) ./ s;
    end
end

function trialTimepoint = makeTrialTimepoint(trialVec)
    trialVec = trialVec(:);
    trialTimepoint = zeros(size(trialVec));

    trialNums = unique(trialVec);

    for i = 1:length(trialNums)
        idx = trialVec == trialNums(i);
        trialTimepoint(idx) = (0:sum(idx)-1)';
    end
end

function OutTbl = makeWideSpectrumTable(Y_time_by_wavelength, wavelengths, metaTbl)
    % Y_time_by_wavelength: [T x W]
    nW = numel(wavelengths);

    reconVarNames = "WL_" + compose("%04d", 1:nW);
    reconVarNames = matlab.lang.makeValidName(reconVarNames);
    reconVarNames = matlab.lang.makeUniqueStrings(reconVarNames);

    OutTbl = array2table(Y_time_by_wavelength);
    OutTbl.Properties.VariableNames = cellstr(reconVarNames);

    if ismember('Trial', metaTbl.Properties.VariableNames)
        OutTbl = addvars(OutTbl, metaTbl.Trial, metaTbl.TrialTimepoint, metaTbl.Timepoint_Global, ...
            'Before', 1, ...
            'NewVariableNames', {'Trial','TrialTimepoint','Timepoint_Global'});
    else
        OutTbl = addvars(OutTbl, metaTbl.Timepoint_Global, ...
            'Before', 1, ...
            'NewVariableNames', 'Timepoint_Global');
    end
end