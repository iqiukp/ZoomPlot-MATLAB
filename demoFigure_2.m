clc
clear
close all
addpath(genpath(pwd)) 

%  basic plotting
tmp_ = 5;
t1 = 0:pi/20:8*pi;     
t2 = 8*pi:pi/20:16*pi;
y1_ = exp(-t1/tmp_ );
y2_ = exp(-t1/tmp_ ).*sin(tmp_ *t1);
t = [t1, t2];
y1 = [y1_, fliplr(y1_)];
y2 = [y2_, fliplr(y2_)];

figure;
plot(t, y2, 'Color', 'r', 'LineStyle', '-', 'LineWidth', 1.5) 
hold on
plot(t, y1, 'Color', 'b', 'LineStyle', ':', 'LineWidth', 1.5) 
plot(t, -y1, 'Color', 'b', 'LineStyle', ':','LineWidth', 1.5) 
xlim([min(t), max(t)])


% add 2 zoomed zones
zp = BaseZoom();
zp.plot;
zp.plot;
