clc
clear
close all
addpath(genpath(pwd))

% 创建数据 
x = linspace(-0.1*pi,2*pi, 30);
y = cell(1, 3);
y{1, 1} = 0.4*sinc(x)+0.8;
y{1, 2} = tanh(x);
y{1, 3} = exp(-sinc(x));

%% 主坐标系部分
% 创建图像
figure;
color_ = [0, 114, 189; 126, 47, 142; 162, 20, 47]/255;
% 创建主坐标系
axes1 = axes('Units', 'normalized');
hold(axes1, 'on');
box(axes1,'on');
set(axes1, 'LineWidth', 1.2, 'TickDir', 'in');
% 可视化
for i = 1:3
    plot(x, y{1, i}, 'Parent', axes1, 'Color', color_(i, :), 'LineWidth', 3)
end

%% 放大图
% parameters of axes
parameters = struct('axesPosition', [0.6, 0.1, 0.2, 0.4],...
                    'zoomZone', [1.5, 2.5; 0.6, 1.3],...
                    'lineDirection', [1, 2; 4, 3]);
%% plot
zp = BaseZoom();
zp.plot(parameters)
