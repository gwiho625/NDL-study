%% jRGECO_raw
data = readtable('/Users/rnlghdb/NDL/data/jRGECO_spectrum/Flna17_jR_gr25uw.csv');
head(data)

%% ============================================================
figure;

plot(data.Wavelength, data.Intensity, 'LineWidth', 2)

xlabel('Wavelength (nm)')
ylabel('Intensity (a.u.)')
title('Flna17 jRGECO Raw Spectrum')

grid on
box on
