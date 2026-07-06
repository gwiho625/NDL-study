function Linear_Spectral_Unmixing_Algorithm_v1_1
    % --- 1. UI 및 레이아웃 설정 (Shiny UI 매핑) ---
    fig = uifigure('Name', 'Linear Spectral Unmixing Model v1.1', 'Position', [100, 100, 1100, 700]);
    
    % 좌측 사이드바 패널
    sidebar = uipanel(fig, 'Title', '설정 및 입력', 'Position', [20, 20, 300, 660]);
    
    % 우측 메인 탭 패널 (tabsetPanel 역할)
    tabGroup = uitabgroup(fig, 'Position', [340, 20, 740, 660], 'SelectionChangedFcn', @tab_change_callback);
    tab1 = uitab(tabGroup, 'Title', 'Panel 1', 'Tag', '1');
    tab2 = uitab(tabGroup, 'Title', 'Panel 2', 'Tag', '2');
    
    % --- 사이드바 컴포넌트 배치 ---
    % [Panel 1용 컨트롤들]
    lblPanel1 = uilabel(sidebar, 'Position', [10, 610, 260, 22], 'Text', 'Content Panel 1', 'FontAngle', 'italic');
    lblFile1 = uilabel(sidebar, 'Position', [10, 580, 260, 22], 'Text', 'Upload the mixed spectra file (CSV format).');
    btnFile1 = uibutton(sidebar, 'Position', [10, 555, 260, 22], 'Text', 'Browse...', 'ButtonPushedFcn', @(btn,e) uigetfile_callback(1));
    txtFile1Name = uilabel(sidebar, 'Position', [10, 535, 260, 22], 'Text', 'No file selected', 'FontColor', [0.5 0.5 0.5]);
    
    lblFile2 = uilabel(sidebar, 'Position', [10, 495, 260, 22], 'Text', 'Upload the reference file (CSV format).');
    btnFile2 = uibutton(sidebar, 'Position', [10, 470, 260, 22], 'Text', 'Browse...', 'ButtonPushedFcn', @(btn,e) uigetfile_callback(2));
    txtFile2Name = uilabel(sidebar, 'Position', [10, 450, 260, 22], 'Text', 'No file selected', 'FontColor', [0.5 0.5 0.5]);
    
    lblRange = uilabel(sidebar, 'Position', [10, 410, 260, 35], 'Text', 'What is the range of wavelength you would like to analyze?', 'WordWrap', 'on', 'FontWeight', 'bold');
    uilabel(sidebar, 'Position', [10, 380, 120, 22], 'Text', 'Enter the lower limit:');
    txtLower = uieditfield(sidebar, 'text', 'Position', [140, 380, 130, 22], 'Value', '0');
    uilabel(sidebar, 'Position', [10, 350, 120, 22], 'Text', 'Enter the upper limit:');
    txtUpper = uieditfield(sidebar, 'text', 'Position', [140, 350, 130, 22], 'Value', '1500');
    
    uilabel(sidebar, 'Position', [10, 310, 120, 22], 'Text', 'Component 1 Name:');
    txtName1 = uieditfield(sidebar, 'text', 'Position', [140, 310, 130, 22], 'Value', 'Component 1');
    uilabel(sidebar, 'Position', [10, 280, 120, 22], 'Text', 'Component 2 Name:');
    txtName2 = uieditfield(sidebar, 'text', 'Position', [140, 280, 130, 22], 'Value', 'Component 2');
    
    btnRun = uibutton(sidebar, 'Position', [10, 230, 260, 30], 'Text', 'Run', 'ButtonPushedFcn', @(btn,e) run_analysis());
    
    uilabel(sidebar, 'Position', [10, 185, 260, 22], 'Text', 'Output file name:');
    txtName3 = uieditfield(sidebar, 'text', 'Position', [10, 160, 260, 22], 'Value', 'Output');
    btnDownload = uibutton(sidebar, 'Position', [10, 120, 260, 30], 'Text', 'Download dataset.', 'ButtonPushedFcn', @(btn,e) download_data());
    
    % [Panel 2용 컨트롤들] (초기에는 숨김 처리 - conditionalPanel 구현)
    lblPanel2 = uilabel(sidebar, 'Position', [10, 610, 260, 22], 'Text', 'Content Panel 2', 'FontAngle', 'italic', 'Visible', 'off');
    lblTimePoint = uilabel(sidebar, 'Position', [10, 580, 260, 22], 'Text', 'Enter a time point:', 'Visible', 'off');
    txtTimePoint = uieditfield(sidebar, 'numeric', 'Position', [10, 555, 150, 22], 'Value', 0, 'LowerLimit', 0, 'RoundFractionalValues', 'on', 'Visible', 'off', 'ValueChangedFcn', @(txt,e) update_panel2());

    % --- 메인 패널 시각화 컴포넌트 배치 ---
    % Panel 1 전용 그래프 창 3개 (세로 정렬)
    axColor1 = uiaxes(tab1, 'Position', [40, 440, 650, 170]);
    axColor2 = uiaxes(tab1, 'Position', [40, 230, 650, 170]);
    axRatio  = uiaxes(tab1, 'Position', [40, 20, 650, 170]);
    
    % Panel 2 전용 그래프 및 텍스트 창
    axReg = uiaxes(tab2, 'Position', [40, 240, 650, 370]);
    txtInfo = uitextarea(tab2, 'Position', [40, 30, 650, 170], 'Editable', 'off', 'FontName', 'FixedWidth');

    % --- 내부 데이터 저장 구조체 (Reactive 변수 역할) ---
    appState = struct('raw_file1', '', 'raw_file2', '', 'file1_name', '', 'df1', [], 'df2', []);

    % --- 2. 콜백 함수 기능 구현 (Server 기능 매핑) ---
    
    % 탭 전환 시 사이드바 구성을 바꾸는 기능 (conditionalPanel 구현)
    function tab_change_callback(~, event)
        if strcmp(event.NewValue.Tag, '1')
            % Panel 1 전용 컨트롤 켜기
            set([lblPanel1, lblFile1, btnFile1, txtFile1Name, lblFile2, btnFile2, txtFile2Name, ...
                 lblRange, txtLower, txtUpper, txtName1, txtName2, btnRun, txtName3, btnDownload], 'Visible', 'on');
            % Panel 2 전용 컨트롤 끄기
            set([lblPanel2, lblTimePoint, txtTimePoint], 'Visible', 'off');
        else
            % Panel 1 전용 컨트롤 끄기
            set([lblPanel1, lblFile1, btnFile1, txtFile1Name, lblFile2, btnFile2, txtFile2Name, ...
                 lblRange, txtLower, txtUpper, txtName1, txtName2, btnRun, txtName3, btnDownload], 'Visible', 'off');
            % Panel 2 전용 컨트롤 켜기
            set([lblPanel2, lblTimePoint, txtTimePoint], 'Visible', 'on');
            update_panel2(); % 탭 이동 시 자동 갱신
        end
    end

    % 파일 탐색기 열기
    function uigetfile_callback(fileNum)
        [file, path] = uigetfile('*.csv', 'CSV 파일 선택');
        if isequal(file, 0), return; end
        if fileNum == 1
            appState.raw_file1 = fullfile(path, file);
            appState.file1_name = file;
            txtFile1Name.Text = file;
        else
            appState.raw_file2 = fullfile(path, file);
            txtFile2Name.Text = file;
        end
    end

    % 메인 연산 루프 (eventReactive(input$do, ...) 부분 매핑)
    function run_analysis()
        if isempty(appState.raw_file1) || isempty(appState.raw_file2)
            uialert(fig, '혼합 파일과 레퍼런스 파일을 모두 업로드해주세요.', '파일 누락');
            return;
        end
        
        lower_val = str2double(txtLower.Value);
        upper_val = str2double(txtUpper.Value);
        
        % [Progress Bar 1] mixed_data 로드 및 연산
        d = uiprogressdlg(fig, 'Title', 'Please Wait', 'Message', ['Reading ', appState.file1_name]);
        
        % readmatrix로 데이터 로딩 후 전치(Transpose) 적용
        mixed_raw = readmatrix(appState.raw_file1);
        mixed_data = mixed_raw'; 
        
        % 파장 경계 인덱스 필터링 (which함수 대용)
        upper_lim2 = find(mixed_data(:, 1) < upper_val, 1, 'last');
        lower_lim2 = find(mixed_data(:, 1) > lower_val, 1, 'first');
        
        mixed_data = mixed_data(lower_lim2:upper_lim2, :);
        wavelengths = mixed_data(:, 1);
        mixed_data(:, 1) = []; % 첫 열(파장) 제거
        
        pause(0.5);
        
        % [Progress Bar 2] color (레퍼런스) 데이터 로드 및 연산
        d.Message = 'Reading Reference File';
        color_raw = readmatrix(appState.raw_file2);
        
        c_upper_lim = find(color_raw(:, 1) < upper_val, 1, 'last');
        c_lower_lim = find(color_raw(:, 1) > lower_val, 1, 'first');
        color_data = color_raw(c_lower_lim:c_upper_lim, :);
        
        color1 = color_data(:, 2);
        color2 = color_data(:, 3);
        
        pause(0.5);
        
        % 회귀 결과 저장 벡터 초기화
        num_cols = size(mixed_data, 2);
        r_sq_list = zeros(num_cols, 1);
        intercept_list = zeros(num_cols, 1);
        comp1_list = zeros(num_cols, 1);
        comp2_list = zeros(num_cols, 1);
        ratio_list = zeros(num_cols, 1);
        
        % [Progress Bar 3] 선형 회귀 분석 수행 루프 (lm 기능 매핑)
        X = [color1, color2];
        for i = 1:num_cols
            d.Value = i / num_cols;
            d.Message = sprintf('Generating Data: Part %d of %d', i, num_cols);
            
            m = mixed_data(:, i);
            mdl = fitlm(X, m); % OLS 회귀 분석
            
            r_sq_list(i) = mdl.Rsquared.Ordinary;
            intercept_list(i) = mdl.Coefficients.Estimate(1);
            comp1_list(i) = mdl.Coefficients.Estimate(2);
            comp2_list(i) = mdl.Coefficients.Estimate(3);
            ratio_list(i) = comp1_list(i) / comp2_list(i);
        end
        close(d);
        
        % 데이터 가공 및 테이블 구조 구축 (df1, df2 매핑)
        n1 = txtName1.Value; n2 = txtName2.Value;
        appState.df1 = table(comp1_list, comp2_list, intercept_list, ratio_list, r_sq_list, ...
            'VariableNames', {matlab.lang.makeValidName(['Coeff_of_', n1]), ...
                              matlab.lang.makeValidName(['Coeff_of_', n2]), ...
                              'Intercept', ...
                              matlab.lang.makeValidName(['Ratio_of_', n1, '_to_', n2]), ...
                              'R_Squared'});
                          
        appState.df2 = struct('color1', color1, 'color2', color2, 'wavelengths', wavelengths, 'mixed_data', mixed_data);
        
        % --- Panel 1 실시간 플로팅 그리기 ---
        time_axis = 1:num_cols;
        
        plot(axColor1, time_axis, comp1_list, 'b-', 'LineWidth', 1.1);
        title(axColor1, 'Component 1 Coefficient Plot');
        xlabel(axColor1, 'Time Points'); ylabel(axColor1, ['Coefficient of ', n1]);
        
        plot(axColor2, time_axis, comp2_list, 'b-', 'LineWidth', 1.1);
        title(axColor2, 'Component 2 Coefficient Plot');
        xlabel(axColor2, 'Time Points'); ylabel(axColor2, ['Coefficient of ', n2]);
        
        plot(axRatio, time_axis, ratio_list, 'b-', 'LineWidth', 1.1);
        title(axRatio, 'Ratio Plot');
        xlabel(axRatio, 'Time Points'); ylabel(axRatio, ['Ratio of ', n1, ' to ', n2]);
    end

    % 특정 시점 회귀 분석 라인 그리기 및 요약 보고 (Panel 2 매핑)
    function update_panel2()
        if isempty(appState.df2)
            txtInfo.Value = '분석이 수행되지 않았습니다. Panel 1에서 Run을 먼저 눌러주세요.';
            return; 
        end
        
        % R 언어의 0-based 보정 수식 반영 (+1)
        t_idx = txtTimePoint.Value + 1;
        max_time = size(appState.df2.mixed_data, 2);
        
        if t_idx < 1 || t_idx > max_time
            uialert(fig, sprintf('시점 오류! 0부터 %d 사이의 정수를 선택해야 합니다.', max_time-1), '범위 확인');
            return;
        end
        
        obs = double(appState.df2.mixed_data(:, t_idx));
        X = [appState.df2.color1, appState.df2.color2];
        mdl = fitlm(X, obs);
        pred = mdl.Fitted;
        
        % R 코드의 축 오프셋 마진 계산식 반영: u = max(max(pred), max(obs)) + 50
        u = max([max(pred), max(obs)]) + 50;
        yRange = [min([min(pred), min(obs)]), u];
        
        % 회귀선 플로팅 (Observed = 청색선, Expected = 적색선)
        plot(axReg, appState.df2.wavelengths, obs, 'b-', 'LineWidth', 1.2); hold(axReg, 'on');
        plot(axReg, appState.df2.wavelengths, pred, 'r-', 'LineWidth', 1.2); hold(axReg, 'off');
        ylim(axReg, yRange);
        xlabel(axReg, 'Wavelength (nm)'); ylabel(axReg, 'Intensity');
        title(axReg, sprintf('Observed vs. Expected Plot at Time = %d', txtTimePoint.Value));
        legend(axReg, {'Observed', 'Expected'}, 'Location', 'best');
        
        % 하단 콘솔 텍스트창에 소수점 3자리 포맷팅 데이터 출력 (renderPrint 매핑)
        row_table = appState.df1(t_idx, :);
        names = row_table.Properties.VariableNames;
        vals = table2array(row_table);
        
        summary_cells = cell(length(vals), 1);
        for k = 1:length(vals)
            summary_cells{k} = sprintf('%-25s: %.3f', names{k}, vals(k));
        end
        txtInfo.Value = [{['[Time Point = ', num2cell(txtTimePoint.Value), ' Result Summary]']}; ''; summary_cells];
    end

    % 다운로드 핸들러 연동 (downloadHandler 매핑)
    function download_data()
        if isempty(appState.df1)
            uialert(fig, '추출된 데이터 프레임이 없습니다. 먼저 Run을 실행해 주세요.', '다운로드 불가');
            return;
        end
        default_file = [txtName3.Value, '.csv'];
        [file, path] = uiputfile(default_file, '결과 데이터셋 저장');
        if isequal(file, 0), return; end
        
        % 헤더명을 포함하여 깔끔하게 csv로 Write
        writetable(appState.df1, fullfile(path, file));
    end
end