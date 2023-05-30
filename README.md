<p align="center">
  <img src="http://github-files-qiu.oss-cn-beijing.aliyuncs.com/ZoomPlot-MATLAB/figure-1.gif">
</p>

<h3 align="center">ZoomPlot</h3>

<p align="center">MATLAB Code for Interactive Magnification of Customized Regions.</p>
<p align="center">Version 1.4, 30-MAY-2023</p>
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

## ✨ Main features

- Easy application with just two lines of code
- Interactive plotting
- Support for image and figure classes
- Support for multiple zoomed zones
- Custom settings of parameters and themes 

## ⚠️ Requirements

- R2016a and later releases
- Image Processing Toolbox

## 👉 How to use

1. Add `BaseZoom.m` and `parameters.json` to MATLAB search path or current working directory
2. After completing the basic drawing, enter the following two lines of code in the command line window or your m-file: 
```MATLAB
% add a zoomed zone
zp = BaseZoom();
zp.plot;
```

*if multiple zoomed zones are required, for example, 3 zoomed zones, the code are as follows:*
```MATLAB
% add 3 zoomed zones
zp = BaseZoom();
zp.plot;
zp.plot;
zp.plot;
```

## 👉 Examples for image class

Multiple types of image are supported for interactive magnification of customized regions in the `ZoomPlot`.
<p align="center">
  <img src="https://github-files-qiu.oss-cn-beijing.aliyuncs.com/ZoomPlot-MATLAB/image_group.gif" width = "60%">
</p>

## 👉 Examples for figure class

Multiple zoomed zones are supported for figure class.
<p align="center">
  <img src="https://github-files-qiu.oss-cn-beijing.aliyuncs.com/ZoomPlot-MATLAB/figure_group.gif" width = "60%">
</p>

## 👉 Customize parameters using json files

ZoomPlot's configuration parameters are stored in `parameters.json` and have the following default values: 
```json
{
    "subAxes": 
        {
            "Color": "none",
            "LineWidth": 1.2,
            "XGrid": "off",
            "YGrid": "off",
            "ZGrid": "off",
            "GridAlpha": 0.15,
            "GridColor": [0.15, 0.15, 0.15],
            "GridLineStyle": "-",
            "Box": "on",
            "TickDir": "in",
            "Comments": "theme of the sub axes"
        },

    "zoomedArea": 
        {
            "Color": "k",
            "FaceColor": "none",
            "FaceAlpha": 0,
            "LineStyle": "-",
            "LineWidth": 1.5,
            "Comments": "theme of the zoomed area"
        },

     "dynamicRect": 
        {
            "LineColor": [0, 0.4471, 0.7412],
            "LineWidth": 2,
            "Marker": "s",
            "MarkerSize": 9,
            "FaceColor": [0, 0.4471, 0.7412],
            "FaceAspect": 0.3,
            "EdgeColor": "k",
            "Comments": "theme of the zoomed area"
        },

     "connection": 
        {
            "LineColor": "k",
            "LineWidth": 1.5,
            "LineStyle": ":",
            "StartHeadStyle": "ellipse",
            "StartHeadLength": 3,
            "StartHeadWidth": 3,
            "EndHeadStyle": "cback2",
            "EndHeadLength": 7,
            "EndHeadWidth": 7,
            "Comments": "theme of the zoomed area"
        }

}
```
As you can see, there are four sections of configuration parameters:

- `subAxes` (sub coordinate system)
- `zoomedArea` (zoomed area)
- `dynamicRect` (dynamic rectangle in the adjustment process)
- `connection` (the line connecting the sub coordinate system and the zoomed area)

For example, the border of the zoomed area is changed to red, and the line width is changed to 3:
<p align="center">
  <img src="https://github-files-qiu.oss-cn-beijing.aliyuncs.com/ZoomPlot-MATLAB/change_0001.png" width = "60%">
</p>

Another example, the color of the connecting line is changed to blue, the shape of the end arrow is changed to 'ellipse', and the line width is changed to 5:
<p align="center">
  <img src="https://github-files-qiu.oss-cn-beijing.aliyuncs.com/ZoomPlot-MATLAB/change_0002.png" width = "60%">
</p>

## TODO

- [ ] Support for 3-D plots
- [ ] Support for input of position parameters for sub coordinate system and zoomed area using a four-element vector of the form `[left bottom width height]`

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=iqiukp/ZoomPlot-MATLAB)](https://star-history.com/#iqiukp/ZoomPlot-MATLAB)
