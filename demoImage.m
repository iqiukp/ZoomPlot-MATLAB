clc
clear all
close all
addpath(genpath(pwd)) 

%  basic plotting
[X, cmap] = imread('trees.tif');
% [X, cmap] = imread('ngc6543a.jpg');
% [X, cmap] = imread('cameraman.tif');
imshow(X, cmap);

% add a zoomed zone
zp = BaseZoom();
zp.plot;
