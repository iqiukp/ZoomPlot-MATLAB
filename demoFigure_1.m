clc
clear
close all
addpath(genpath(pwd)) 

%  basic plotting
x = linspace(-0.1*pi,2*pi, 30);
y = cell(1, 3);
y{1, 1} = 0.4*sinc(x)+0.8;
y{1, 2} = tanh(x);
y{1, 3} = exp(-sinc(x));

figure;
color_ = [0, 114, 189; 126, 47, 142; 162, 20, 47]/255;
ax = axes('Units', 'normalized');
hold(ax, 'on');
box(ax,'on');
set(ax, 'LineWidth', 1.2, 'TickDir', 'in');
for i = 1:3
    plot(x, y{1, i}, 'Parent', ax, 'Color', color_(i, :), 'LineWidth', 3)
end

% add a zoomed zone
zp = BaseZoom();
zp.plot;
















