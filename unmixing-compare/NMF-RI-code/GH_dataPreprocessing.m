function [Y, Y_sps, H_sps] = dataPreprocessing(A0, Y)

% ------------------------------------------------------------
% Data preprocessing for NMF-RI
% Y  : [W x T] mixed spectra
% A0 : [W x K] initial spectra
% ------------------------------------------------------------

% 1. Elimination of dark current / baseline offset
% 각 timepoint spectrum마다 minimum을 빼서 non-negative로 만듦
Y = Y - min(Y, [], 1);
Y(Y <= 0) = 100 * eps;

% 2. Initial H estimation
% 초기 A0를 기준으로 각 timepoint의 component coefficient 추정
H0 = max(100 * eps, pinv(A0) * Y);

% 3. Sparseness score 계산
% H0(:,t)가 한 성분에 치우쳐 있을수록 sparse score가 커짐
SPS = (sqrt(size(H0,1)) - ...
    (sum(abs(H0),1) ./ sqrt(sum(H0.^2,1)))) / ...
    (sqrt(size(H0,1)) - 1);

% NaN 방지
SPS(isnan(SPS)) = 0;

% 4. Sparsest 30% timepoints 선택
Thrs = 0.7;
thresh = quantile(SPS, Thrs);

Y_sps = Y(:, SPS > thresh);

% 5. Selected sparse data에 대한 H 초기값
H_sps = max(100 * eps, pinv(A0) * Y_sps);

end