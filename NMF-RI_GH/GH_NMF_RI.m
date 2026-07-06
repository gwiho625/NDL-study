% NMF_RI Blind unmixing based on Reinitialization
%
% NMF_RI(Y,A0,H0,theta1,theta2,alphaA,alphaX)
%
%  Y      [L x M] input mixed matrix
%         L = wavelength/channel
%         M = timepoint/pixel
%
%  A0     [L x N] initial mixing matrix
%         N = number of components
%
%  H0     [N x M] initial unmixed matrix estimation
%
%  theta1 intra-layer stopping criterion
%  theta2 inter-layer stopping criterion
%  alphaA sparseness weight for A
%  alphaX sparseness weight for H
%
% Output:
%  A      [L x N] resolved spectra
%  H      [N x M] resolved concentration/time profiles
%  n      number of iterations
%
% Modified for fiber photometry spectral unmixing:
%  - stronger non-negativity enforcement
%  - safer numerator clipping
%  - lsqnonneg-based H re-estimation
%  - recent-iteration based convergence trigger

function [A, H, n] = NMF_RI(Y, A0, H0, theta1, theta2, alphaA, alphaX)

%% ===================== Input safety =====================

% Ensure non-negative input
Y = max(Y, 100 * eps);
A0 = max(A0, 100 * eps);
H0 = max(H0, 100 * eps);

% Normalize initial spectra column-wise
A0 = A0 * diag(1 ./ (sum(A0, 1) + eps));

%% ===================== Initialize =====================

H = H0;

max_it = 300;

% Scale sparsity weights by data magnitude
alphaA = mean(Y(:)) * alphaA;
alphaX = mean(Y(:)) * alphaX;

layer = 1;
LayerN = 0;

Astep = A0;   % A at previous reinitialization layer
Aprev = A0;   % A at previous iteration
A = A0;

aVect = [];

%% ===================== Main loop =====================

for n = 1:max_it

    Anow = A;

    % A 변화량 기록
    idx = n - LayerN;
    aVect(idx) = sum(sum(abs(Aprev - Anow)));

    if n == 1
        aVect(idx) = 100;
    end

    %% ---------- Reinitialization trigger ----------
    if n > 1

        daVect = diff(aVect);

        % 기존 코드: any(abs(aVect)<theta1) | any(daVect>0)
        % 수정 코드: 최근 iteration 기준으로만 판단
        should_reinit = abs(aVect(end)) < theta1 || ...
                        (~isempty(daVect) && daVect(end) > 0);

        if should_reinit

            disp(['converge: ', num2str(sum(sum(abs(Astep - A)))), ...
                  ' N: ', num2str(n)]);

            if layer == 1

                Astep = A;
                A = normalizeColumns(A);

            else

                if sum(sum(abs(Astep - A))) < theta2
                    break;
                else
                    Astep = A;
                    A = normalizeColumns(A);
                end

            end

            layer = layer + 1;
            LayerN = n;
            aVect = [];

            % Reinitialize H using NNLS
            H = computeNNLS(Astep, Y);
            H = max(H, 100 * eps);
        end
    end

    Aprev = A;

    %% ---------- H update ----------
    % H <- H .* ((A'Y - alphaX) ./ (A'AH))
    % alphaX 때문에 numerator가 음수가 될 수 있으므로 eps로 clipping
    Yx = max(A' * Y - alphaX, eps);
    denomH = (A' * A) * H + eps;

    H = H .* (Yx ./ denomH);
    H = max(H, 100 * eps);

    %% ---------- A update ----------
    % A <- A .* ((YH' - alphaA) ./ (AHH'))
    % 원본 코드 형태에 맞추면 Ya = H*Y' 사용 후 transpose 처리
    Ya = max(H * Y' - alphaA, eps);
    denomA = (A * (H * H'))' + eps;

    A = A .* (Ya ./ denomA)';
    A = max(A, 100 * eps);

    % Spectrum column normalization
    A = normalizeColumns(A);

end

%% ===================== Final H estimation =====================

% Final H using NNLS for all timepoints
H = computeNNLS(A, Y);
H = max(H, 100 * eps);

end

%% ===================== Helper functions =====================

function A_norm = normalizeColumns(A)
    A = max(A, 100 * eps);
    A_norm = A * diag(1 ./ (sum(A, 1) + eps));
end

function H = computeNNLS(A, Y)
    % Solve each column:
    %   min ||Y(:,t) - A*h||^2
    %   subject to h >= 0

    nComp = size(A, 2);
    nTime = size(Y, 2);

    H = zeros(nComp, nTime);

    for t = 1:nTime
        H(:, t) = lsqnonneg(A, Y(:, t));
    end
end