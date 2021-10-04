<p align="center">
  <img src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/v1.2.gif">
</p>

<h3 align="center">ZoomPlot</h3>

<p align="center">MATLAB Code for Interactive Magnification of the customized regions.</p>
<p align="center">Version 1.2, 4-OCT-2021</p>
<p align="center">Email: iqiukp@outlook.com</p>

<div align=center>

<img src="https://img.shields.io/github/v/release/iqiukp/ZoomPlot?label=version" />
<img src="https://img.shields.io/github/repo-size/iqiukp/ZoomPlot" />
<img src="https://img.shields.io/github/languages/code-size/iqiukp/ZoomPlot" />
<img src="https://img.shields.io/github/languages/top/iqiukp/ZoomPlot" />
<img src="https://img.shields.io/github/stars/iqiukp/ZoomPlot" />
<img src="https://img.shields.io/github/forks/iqiukp/ZoomPlot" />
</div>

<hr />

## Main features

- Easy application by only two lines of code
- Interactive plotting
- Drag the mouse to adjust the size and position of the sub-coordinate system 
- Drag the mouse to adjust the size and position of the magnification zone


## How to use

1. Add BaseZoom.m file to MATLAB search path or current working directory
2. After completing the basic drawing, enter the following two lines of code in the command line window or your m-file: 
```
zp = BaseZoom();
zp.plot;
```
## How to customize the theme of the sub-coordinate system

Just modify the properties of the BaseZoom class file. The default properties are: 
```
    properties
        % theme of inserted axes (sub-axes)
        subAxesBox = 'on'
        subAxesinsertedLineWidth = 1.2
        subAxesTickDirection = 'in'
        subAxesBackgroundColor = 'w'
    end
```
For example, remove the border of the sub-coordinate system and set the line width to 3: 
```
    properties
        % theme of inserted axes (sub-axes)
        subAxesBox = 'off'
        subAxesinsertedLineWidth = 3
        subAxesTickDirection = 'in'
        subAxesBackgroundColor = 'w'
    end
```
<p align="center">
  <img src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/02.png">
</p>

## How to customize the theme of the rectangle of the magnification zone

Just modify the properties of the BaseZoom class file. The default properties are: 
```
    properties
        % theme of the inserted rectangle (zoom zone)
        rectangleColor = 'k'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 0
        rectangleLineStyle = '-'
        rectangleLineWidth = 1.2
        rectangleInteractionsAllowed = 'none'
    end
```
For example, set the line color to red and the line width to 2: 
```
    properties
        % theme of the inserted rectangle (zoom zone)
        rectangleColor = 'r'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 0
        rectangleLineStyle = '-'
        rectangleLineWidth = 2
        rectangleInteractionsAllowed = 'none'
    end
```

<p align="center">
  <img src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/03.png">
</p>

## How to customize the theme of the connected lines

Just modify the properties of the BaseZoom class file. The default properties are: 
```
    properties
        % theme of the connected lines
        connectedLineStyle = ':'
        connectedLineColor = 'k'
        connectedLineWidth = 2
        connectedLineHeadStyle = 'ellipse'
        connectedLineHeadSize = 5
    end
```
In this code, the connecting line is a type of "doublearrow". For example, set the mark size at both ends of the connecting line to 10, the color of the connecting line to red, and the line width to 5: 
```
    properties
        % theme of the connected lines
        connectedLineStyle = ':'
        connectedLineColor = 'r'
        connectedLineWidth = 5
        connectedLineHeadStyle = 'ellipse'
        connectedLineHeadSize = 10
    end
```
<p align="center">
  <img src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/04.png">
</p>

## About the axes position

Specify axes position as a four-element vector of the form [x y w h] in data units. The x and y elements determine the location and the w and h elements determine the size. The function plots into the current axes without clearing existing content from the axes.

<p align="center">
  <img src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/figure-axes.png">
</p>
 
## About line direction
The rectangular box of the zoom zone is connected to the subcoordinate system by connecting lines. The four angles of the rectangular box and the subcoordinate system are 1,2,3,4. The corresponding four angles are upper right, upper left, lower left, and lower right respectively. The following figure shows the direction settings for several common cases:

<p align="center">
  <img src="https://github.com/iqiukp/ZoomPlot/blob/main/imgs/line.png">
</p>

Take the first group as an example: the lower right corner (4) of the rectangular box is connected to the lower left corner (3) of the subcoordinate system, and the upper right corner (1) of the rectangular box is connected to the upper left corner (2) of the subcoordinate system, so the direction parameters are [1, 2; 4, 3].
