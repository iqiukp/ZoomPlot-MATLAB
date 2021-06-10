
<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/demo.png">
</p>

<h3 align="center"> ZoomPlot </h3>

<p align="center">MATLAB code for Magnification of the customized regions of the plot's axis</p>
<p align="center">Version 1.0, 10-JUN-2021</p>
<p align="center">Email: iqiukp@outlook.com</p>

<div align=center>
</div>
<hr />

## Main features

- Easy-used API
- Parameter setting of independent modules (axes, rectangle, and line)
- Customizable connection line direction 

## How to use

```
zp = BaseZoom();
zp.plot(axes1, axesParams, lineParams)
```
- BaseZoom(): class file
- axes1：parent coordinate system object (or use "gca")
- axesParams：parameter of new axes
- lineParams：parameter of inserted lines
 
## Simple demo
```
% Magnification of the customized regions of the plot's axis.
clc
clear
close all

% data
x = linspace(-0.1*pi,2*pi, 30);
y = cell(1, 3);
y{1, 1} = 0.4*sinc(x)+0.8;
y{1, 2} = tanh(x);
y{1, 3} = exp(-sinc(x));

%% main axes
figure
color_ = [0, 114, 189; 126, 47, 142; 162, 20, 47]/255;
axes1 = axes('Units', 'normalized');
hold(axes1, 'on');
box(axes1,'on');
set(axes1, 'LineWidth', 1.2, 'TickDir', 'in');
for i = 1:3
    plot(x, y{1, i}, 'Parent', axes1, 'Color', color_(i, :), 'LineWidth', 3)
end
legend(axes1, 'line-1', 'line-2', 'line-3')

%% new axes
% parameters of axes
axesParams = struct('position', [0.7, 0.1, 0.2, 0.4],...
                    'zoomZone', [9, 12],...
                    'expandRatio', [0.1, 0.1]);
                
% parameters of line
            %   Rectangle         Axes
            %    2----1          2----1
            %    3----4          3----4
lineParams = struct('lineDirection', [1, 2; 4, 3]);

%% plot
zp = BaseZoom();
zp.plot(axes1, axesParams, lineParams)
```

## Axes position

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/figure-axes.png">
</p>
 
## Line direction

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/line.png">
</p>
 

## Properties

You cab edit the parameters of axes, rectangle, and line in the file -- "BaseZoom.m"

```
properties
        %
        axes1
        axes2
        rectangle
        XLimNew
        YLimNew
        mappingParams
        
        % parameters of inserted axes
        axes2Box = 'on'
        axes2BoxLineWidth = 1.2
        axes2TickDirection = 'in'
        
        % parameters of inserted rectangle
        rectangleColor = 'k'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 1
        rectangleLineStyle = '-'
        rectangleLineWidth = 1.2
        
        % parameters of inserted line
        boxLineStyle = '-'
        boxLineColor = 'k'
        boxLineWidth = 1.5
        boxLineMarker = 'none'
        boxLineMarkerSize = 6
    end
```
