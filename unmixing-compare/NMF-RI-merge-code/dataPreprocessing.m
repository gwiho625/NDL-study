function [Y, Y_sps, H_sps, idx_sps, SPS] = dataPreprocessing(A0, Y)

% ------------------------------------------------------------
% Data preprocessing for NMF-RI
% Y  : [W x T] mixed spectra
% A0 : [W x K] initial spectra
%
% Output
% Y       : preprocessed full mixed spectra [W x T]
% Y_sps   : selected sparse spectra [W x T_sps]
% H_sps   : initial H for sparse spectra [K x T_sps]
% idx_sps : logical index of selected sparse timepoints [1 x T]
% SPS     : sparseness score for all timepoints [1 x T]
% ------------------------------------------------------------

% 1. Elimination of dark current / baseline offset
Y = Y - min(Y, [], 1);
Y(Y <= 0) = 100 * eps;

% 2. Initial H estimation
H0 = max(100 * eps, pinv(A0) * Y);

% 3. Sparseness score
SPS = (sqrt(size(H0,1)) - ...
    (sum(abs(H0),1) ./ sqrt(sum(H0.^2,1)))) / ...
    (sqrt(size(H0,1)) - 1);

SPS(isnan(SPS)) = 0;

% 4. Select sparsest 30% timepoints
Thrs = 0.7;
thresh = quantile(SPS, Thrs);

idx_sps = SPS >= thresh;

Y_sps = Y(:, idx_sps);

% 5. Initial H for selected sparse data
H_sps = max(100 * eps, pinv(A0) * Y_sps);

end