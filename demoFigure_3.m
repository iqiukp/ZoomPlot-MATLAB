clc
clear
close all
addpath(genpath(pwd)) 

%  basic plotting
figure;
syms x y
xRange = [-5*pi, 5*pi];
ax = ezplot(atan(sin(cos(abs(x*y)))+cos(sin(abs(x*y)))) == 1, xRange);
set(ax, 'Color', 'flat', 'LineWidth', 1)
xlim(xRange);
ylim(5*xRange);

% add 3 zoomed zones
zp = BaseZoom();
zp.plot;
zp.plot;
zp.plot;