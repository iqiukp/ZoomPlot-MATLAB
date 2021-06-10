
<p align="center">
  <img width="50%" height="50%" src="https://github.com/iqiukp/ZoomPlot/blob/master/imgs/demo.png">
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
 
## Axes position

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/master/imgs/figure-axes.png">
</p>
 
## Line direction

<p align="center">
  <img width="60%" height="60%" src="https://github.com/iqiukp/ZoomPlot/blob/master/imgs/line.png">
</p>
 

## Properties
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
