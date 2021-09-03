
<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/demo.png">
</p>

<h3 align="center"> ZoomPlot </h3>

<p align="center">MATLAB code for magnification of the customized regions of the plot's axis</p>
<p align="center">Version 1.1, 1-SEP-2021</p>
<p align="center">Email: iqiukp@outlook.com</p>

<div align=center>
</div>
<hr />

## Main features

- Easy-used API
- Parameter setting of independent modules (axes, rectangle, and line)
- Customizable connection line direction 

## How to use

### Simple demo
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
parameters = struct('axesPosition', [0.6, 0.1, 0.2, 0.4],...
                    'zoomZone', [1.5, 2.5; 0.6, 1.3],...
                    'lineDirection', [1, 2; 4, 3]);
                
%% plot
zp = BaseZoom();
zp.plot(parameters)
```

## About the parameters

### axesPosition
Specify axesPosition as a four-element vector of the form [x y w h] in data units. The x and y elements determine the location and the w and h elements determine the size. The function plots into the current axes without clearing existing content from the axes.

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/figure-axes.png">
</p>

### zoomZone
The zoomZone is a 2-by-2 matrix that represents the coordinates of a rectangular box. x_start and x_end in the first line are the x-coordinate starting and ending points of the zoom zone, and y_start and y_end in the second line are the y-coordinate starting and ending points of the zoom zone.
 
## Line direction
The rectangular box of the zoom zone is connected to the subcoordinate system by connecting lines. The four angles of the rectangular box and the subcoordinate system are 1,2,3,4. The corresponding four angles are upper right, upper left, lower left, and lower right respectively. The following figure shows the direction settings for several common cases:

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/line.png">
</p>

Take the first group as an example: the lower right corner (4) of the rectangular box is connected to the lower left corner (3) of the subcoordinate system, and the upper right corner (1) of the rectangular box is connected to the upper left corner (2) of the subcoordinate system, so the direction parameters are [1, 2; 4, 3].

## Properties

You can edit the parameters of axes, rectangle, and line in the file -- "BaseZoom.m"

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
        axes2BoxColor = 'none'
        axes2BoxLineWidth = 1.2
        axes2TickDirection = 'in'
        
        % parameters of inserted rectangle
        rectangleColor = 'k'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 1
        rectangleLineStyle = '-'
        rectangleLineWidth = 0.8
        
        % parameters of inserted line
        boxLineStyle = ':'
        boxLineColor = 'k'
        boxLineWidth = 1
        boxLineMarker = 'none'
        boxLineMarkerSize = 6
    end
```

For example, change the rectangle box to a red dotted line with a width of 2:
```
        % parameters of inserted rectangle
        rectangleColor = 'r'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 1
        rectangleLineStyle = ':'
        rectangleLineWidth = 2
```

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/3.png">
</p>

For example, change the box and scale orientation of the subcoordinate system:
```
        % parameters of inserted axes
        axes2Box = 'off'
        axes2BoxColor = 'none'
        axes2BoxLineWidth = 1.2
        axes2TickDirection = 'out'
```

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/4.png">
</p>

For example, change the connection line to a red dotted line with a width of 2:
```
        % parameters of inserted line
        boxLineStyle = ':'
        boxLineColor = 'r'
        boxLineWidth = 2
        boxLineMarker = 'none'
        boxLineMarkerSize = 6
```

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/5.png">
</p>
