classdef BaseZoom < handle
    %{

        Interactive Magnification of Customized Regions.

        Email: iqiukp@outlook.com
    
        -------------------------------------------------------------
  
        Version 1.3.1, 24-JAN-2022
            -- Fixed bugs when applied to logarithmic-scale coordinates. 

        Version 1.3, 17-JAN-2022
            -- Fixed minor bugs.
            -- Added support for image class.

        Version 1.2, 4-OCT-2021
            -- Added support for interaction

        Version 1.1, 1-SEP-2021
            -- Fixed minor bugs.
            -- Added description of parameters.   

        Version 1.0, 10-JUN-2021
            -- Magnification of Customized Regions.

        -------------------------------------------------------------
        
        BSD 3-Clause License
        Copyright (c) 2022, Kepeng Qiu
        All rights reserved.
        
    %}

    % main  properties
    properties
        % main handles
        mainFigure
        subFigure
        mainAxes
        subAxes
        roi
        rectangleZoomedZone

        % image-related properties
        uPixels
        vPixels
        vuRatio
        CData_
        Colormap_
        imageDim
        imagePosition = [0.1, 0.1, 0.8, 0.6]
        imageRectangleEdgePosition
        imageArrow

        % figure-related properties
        mappingParams
        figureRectangleEdgePosition
        lineDirection
        axesPosition
        figureArrow

        % others
        drawFunc
        axesClass
        axesDone = 'off'
        rectangleDone = 'off'
        pauseTime = 0.2
        textDisplay = 'on'
        axesScale
    end

    % theme of inserted axes (sub-axes)
    properties
        subAxesBox = 'on'
        subAxesinsertedLineWidth = 1.2
        subAxesTickDirection = 'in'
        subAxesBackgroundColor = 'w'
    end

    % theme of the zoomed zone (figures)
    properties
        rectangleColor = 'k'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 0
        rectangleLineStyle = '-'
        rectangleLineWidth = 1.2
        rectangleInteractionsAllowed = 'none'
    end

    % theme of the zoomed zone (images)
    properties
        imageRectangleColor = [0, 114, 189]/255
        imageRectangleFaceColor = [0, 114, 189]/255
        imageRectangleFaceAlpha = 0.2
        imageRectangleLineStyle = '-'
        imageRectangleLineWidth = 2
        imageRectangleInteractionsAllowed = 'none'
    end

    % theme of the connected lines (images)
    properties
        % setting of lines between arrows
        imageConnectedLineStyle = ':'
        imageConnectedLineColor = 'r'
        imageConnectedLineWidth = 1.2
        % setting of start arrow
        imageConnectedLineStartHeadStyle = 'ellipse' % shape of start arrow
        imageConnectedLineStartHeadLength = 3
        imageConnectedLineStartHeadWidth = 3
        % setting of end arrow
        imageConnectedLineEndHeadStyle = 'cback2' % shape of ending arrow
        imageConnectedLineEndHeadLength = 7
        imageConnectedLineEndHeadWidth = 7

    end

    % theme of the connected lines (figures)
    properties
        % setting of lines between arrows
        figureConnectedLineStyle = ':'
        figureConnectedLineColor = 'k'
        figureConnectedLineWidth = 1.2
        % setting of start arrow
        figureConnectedLineStartHeadStyle = 'ellipse' % shape of start arrow
        figureConnectedLineStartHeadLength = 3
        figureConnectedLineStartHeadWidth = 3
        % setting of end arrow
        figureConnectedLineEndHeadStyle = 'cback2' % shape of ending arrow
        figureConnectedLineEndHeadLength = 7
        figureConnectedLineEndHeadWidth = 7
    end

    % theme of the dynamic rectangle
    properties(Constant)
        dynamicRectFaceColor = [0, 114, 189]/255
        dynamicRectFaceAspect = 0.2
        dynamicRectFacAngleMarker = 's'
        dynamicRectFacAngleMarkerSize = 12
        dynamicRectLineWidth = 2.5
        dynamicRectLineColor = [0, 114, 189]/255
    end

    % dynamic properties
    properties(Dependent)
        XLimNew
        YLimNew
        affinePosition
        dynamicPosition
        newCData_
        newCData
        newCMap
        newCMap_
    end

    methods
        function plot(obj)
            % main steps
            obj.checkVersion;
            obj.mainAxes = gca;
            obj.axesScale.XScale = obj.mainAxes.XScale;
            obj.axesScale.YScale = obj.mainAxes.YScale;            
            obj.mainFigure = gcf;

            if size(imhandles(obj.mainAxes),1) ~= 0
                obj.axesClass = 'image';
                % information about the image
                obj.CData_ = get(obj.mainAxes.Children, 'CData');
                %
                obj.Colormap_ = colormap(gca);
                if size(obj.Colormap_, 1) == 64
                    obj.Colormap_ = colormap(gcf);
                end
                [obj.vPixels, obj.uPixels, ~] = size(obj.CData_);
                obj.vuRatio = obj.vPixels/obj.uPixels;
                obj.imageDim = length(size(obj.CData_));
            else
                obj.axesClass = 'figure';
            end

            switch obj.axesClass
                case 'image'
                    obj.insertSubAxes;
                    obj.axesDone = 'off';
                    fprintf('Use the left mouse button to draw a rectangle\n')
                    fprintf('for the magnification zone...\n')
                    obj.insertRectangle;
                    obj.rectangleDone = 'off';

                case 'figure'
                    fprintf('Use the left mouse botton to draw a rectangle\n')
                    fprintf('for the sub-coordinate system...\n')
                    obj.insertSubAxes;
                    obj.axesDone = 'off';
                    fprintf('Use the left mouse button to draw a rectangle\n')
                    fprintf('for the magnification zone...\n')
                    obj.insertRectangle;
                    obj.rectangleDone = 'off';
            end
        end

        function checkVersion(obj)
            % check the MATLAB version
            version_ = version('-release');
            year_ = str2double(version_(1:4));
            if year_ < 2014 || (year_ == 2014 && version_(5) == 'a')
                error('ZoomPlot V1.2 is not compatible with the versions lower than R2014b.')
            end

            if year_ >= 2017
                set(findobj(gcf, 'type', 'Legend'), 'AutoUpdate', 'off');
            end

            if year_ > 2018 || (year_ == 2018 && version_(5) == 'b')
                obj.drawFunc = 'drawrectangle';
            else
                obj.drawFunc = 'imrect';
            end
        end

        function insertSubAxes(obj)
            % insert an axes
            switch obj.axesClass
                case 'image'  %
                    % close(obj.mainFigure)
                    obj.subFigure = figure;
                    obj.imagePosition(4) = obj.imagePosition(3)*obj.vuRatio;
                    set(obj.subFigure, 'Units', 'Normalized', 'OuterPosition', obj.imagePosition);
                    %
                    subplot(1, 2, 1, 'Parent', obj.subFigure);
                    image(obj.CData_);
                    obj.mainAxes = gca;
                    if obj.imageDim == 2
                        colormap(obj.mainAxes, obj.Colormap_);
                    end
                    axis off
                    subplot(1, 2, 2, 'Parent', obj.subFigure);
                    image((ones(obj.vPixels, obj.uPixels)));
                    obj.subAxes = gca;
                    colormap(obj.subAxes, [240, 240, 240]/255);
                    axis off

                case 'figure' %
                    switch obj.drawFunc
                        case 'drawrectangle'
                            obj.roi = drawrectangle(obj.mainAxes);
                            obj.setTheme;
                            obj.creatSubAxes;
                            addlistener(obj.roi, 'MovingROI', @obj.allEventsForSubAxesNew);
                            addlistener(obj.roi, 'ROIMoved', @obj.allEventsForSubAxesNew);
                            set(gcf, 'WindowButtonDownFcn', @obj.clickEventsForSubAxes)
                            while strcmp(obj.axesDone, 'off')
                                pause(obj.pauseTime)
                            end

                        case 'imrect'
                            obj.roi = imrect;
                            obj.setTheme;
                            func_ = makeConstrainToRectFcn('imrect',...
                                get(obj.mainAxes, 'XLim'), get(obj.mainAxes, 'YLim'));
                            setPositionConstraintFcn(obj.roi, func_);
                            obj.creatSubAxes;
                            addNewPositionCallback(obj.roi, @obj.allEventsForSubAxesOld);
                            set(gcf, 'WindowButtonDownFcn', @obj.clickEventsForSubAxes);
                            wait(obj.roi);
                            while strcmp(obj.axesDone, 'off')
                                pause(obj.pauseTime)
                            end
                    end
            end

        end

        function insertRectangle(obj)
            % insert an rectangle
            switch obj.axesClass
                case 'image' %
                    switch obj.drawFunc
                        case 'drawrectangle'
                            obj.roi = drawrectangle(obj.mainAxes);
                            obj.setTheme;
                            obj.creatSubAxes;
                            if strcmp(obj.subAxesBox, 'on')
                                obj.connectAxesAndBox;
                            end
                            set(gcf, 'WindowButtonDownFcn', @obj.clickEventForRectangle);
                            addlistener(obj.roi, 'MovingROI', @obj.allEventsForRectangleNew);
                            addlistener(obj.roi, 'ROIMoved', @obj.allEventsForRectangleNew);
                            while strcmp(obj.rectangleDone, 'off')
                                pause(obj.pauseTime)
                            end

                        case 'imrect'
                            obj.roi = imrect(obj.mainAxes);
                            obj.setTheme;
                            obj.creatSubAxes;
                            func_ = makeConstrainToRectFcn('imrect',...
                                get(obj.mainAxes, 'XLim'), get(obj.mainAxes, 'YLim'));
                            setPositionConstraintFcn(obj.roi, func_);
                            if strcmp(obj.subAxesBox, 'on')
                                obj.connectAxesAndBox;
                            end
                            addNewPositionCallback(obj.roi, @obj.allEventsForRectangleOld);
                            set(gcf, 'WindowButtonDownFcn', @obj.clickEventForRectangle);
                            wait(obj.roi);
                            while strcmp(obj.rectangleDone, 'off')
                                pause(obj.pauseTime)
                            end
                    end
                    %
                    for iArrow = 1:length(obj.imageArrow)
                        obj.imageArrow{iArrow}.Tag = 'ZoomPlot';
                    end

                case 'figure' %
                    switch obj.drawFunc
                        case 'drawrectangle'
                            obj.roi = drawrectangle(obj.mainAxes);
                            obj.setTheme;
                            if strcmp(obj.subAxesBox, 'on')
                                obj.connectAxesAndBox;
                            end
                            set(obj.subAxes, 'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
                            set(gcf, 'WindowButtonDownFcn', @obj.clickEventForRectangle);
                            addlistener(obj.roi, 'MovingROI', @obj.allEventsForRectangleNew);
                            addlistener(obj.roi, 'ROIMoved', @obj.allEventsForRectangleNew);
                            while strcmp(obj.rectangleDone, 'off')
                                pause(obj.pauseTime)
                            end

                        case 'imrect'
                            obj.roi = imrect;
                            obj.setTheme;
                            func_ = makeConstrainToRectFcn('imrect',...
                                get(obj.mainAxes, 'XLim'), get(obj.mainAxes, 'YLim'));
                            setPositionConstraintFcn(obj.roi, func_);
                            if strcmp(obj.subAxesBox, 'on')
                                obj.connectAxesAndBox;
                            end
                            set(obj.subAxes, 'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
                            addNewPositionCallback(obj.roi, @obj.allEventsForRectangleOld);
                            set(gcf, 'WindowButtonDownFcn', @obj.clickEventForRectangle);
                            wait(obj.roi);
                            while strcmp(obj.rectangleDone, 'off')
                                pause(obj.pauseTime)
                            end
                    end
                    %
                    for iArrow = 1:length(obj.figureArrow)
                        obj.figureArrow{iArrow}.Tag = 'ZoomPlot';
                    end

            end
        end

        function allEventsForSubAxesOld(obj, ~)
            % callback funcion for inserted subAxes when using 'imrect'
            if strcmp(obj.textDisplay, 'on')
                fprintf('adjust the inserted subAxes...\n')
            end
            delete(obj.subAxes);
            obj.creatSubAxes;
            obj.subAxes.Color = obj.subAxesBackgroundColor;
        end

        function allEventsForSubAxesNew(obj, ~, evt)
            % callback funcion for inserted subAxes when using 'drawrectangle'
            eventName = evt.EventName;
            if ismember(eventName, {'MovingROI', 'ROIMoved'})
                if strcmp(obj.textDisplay, 'on')
                    fprintf('adjust the inserted subAxes...\n')
                end
                delete(obj.subAxes);
                obj.creatSubAxes;
                obj.subAxes.Color = obj.subAxesBackgroundColor;
            end
        end

        function clickEventsForSubAxes(obj, ~, ~)
            % callback funcion for inserted subAxes
            switch get(gcf, 'SelectionType')
                % right-click
                case 'alt'
                    obj.axesDone = 'on';
                    set(obj.subAxes, 'Visible', 'on');
                    set(gcf, 'WindowButtonDownFcn', []);
                    if strcmp(obj.textDisplay, 'on')
                        fprintf('Inserted subAxes adjustment is done.\n\n')
                    end
                    delete(obj.roi);
                    obj.subAxes.Color = obj.subAxesBackgroundColor;
                    % left-click

                case 'normal'
                    obj.axesDone = 'off';
                    if strcmp(obj.textDisplay, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
                    obj.subAxes.Color = obj.subAxesBackgroundColor;

                otherwise
                    obj.axesDone = 'off';
                    if strcmp(obj.textDisplay, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
                    obj.subAxes.Color = obj.subAxesBackgroundColor;
            end
        end

        function allEventsForRectangleOld(obj, ~)
            % callback funcion for inserted rectangle when using 'imrect'
            fprintf('adjust the inserted rectangle...\n')
            delete(findall(gcf, 'Tag', 'ZoomPlot_'))
            if strcmp(obj.subAxesBox, 'on')
                obj.connectAxesAndBox;
            end

            switch obj.axesClass
                case 'image'
                    obj.creatSubAxes;
                case 'figure'
                    set(obj.subAxes, 'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
            end

        end

        function allEventsForRectangleNew(obj, ~, evt)
            % callback funcion for inserted rectangle when using 'drawrectangle'
            eventName = evt.EventName;
            switch obj.axesClass
                case 'image' %
                    obj.creatSubAxes;
                    if ismember(eventName, {'MovingROI', 'ROIMoved'})
                        if strcmp(obj.textDisplay, 'on')
                            fprintf('adjust the zoomed zone...\n')
                        end
                        delete(findall(gcf, 'Tag', 'ZoomPlot_'))
                        if strcmp(obj.subAxesBox, 'on')
                            obj.connectAxesAndBox;
                        end
                    end

                case 'figure' %
                    if ismember(eventName, {'MovingROI', 'ROIMoved'})
                        if strcmp(obj.textDisplay, 'on')
                            fprintf('adjust the zoomed zone...\n')
                        end
                        delete(findall(gcf, 'Tag', 'ZoomPlot_'))
                        if strcmp(obj.subAxesBox, 'on')
                            obj.connectAxesAndBox;
                        end
                        set(obj.subAxes,'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
                    end
            end
        end

        function clickEventForRectangle(obj, ~, ~)
            % callback funcion for inserted rectangle
            switch get(gcf, 'SelectionType')
                % right-click
                case 'alt'
                    obj.rectangleDone = 'on';
                    obj.creatRectangle;
                    set(gcf, 'WindowButtonDownFcn', []);
                    delete(obj.roi);
                    if strcmp(obj.textDisplay, 'on')
                        fprintf('Inserted rectangle adjustment is done.\n\n')
                    end

                    % left-click
                case 'normal'
                    obj.rectangleDone = 'off';
                    if strcmp(obj.textDisplay, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end

                otherwise
                    obj.rectangleDone = 'off';
                    if strcmp(obj.textDisplay, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
            end
        end

        function creatSubAxes(obj)
            % creat sub-axes
            switch obj.axesClass
                case 'image' %
                    set(obj.subAxes.Children, 'CData', obj.newCData);
                    if obj.imageDim == 2
                        colormap(obj.subAxes, obj.newCMap)
                    end

                case 'figure'
                    obj.subAxes = axes('Position', obj.affinePosition,...
                                       'XScale', obj.axesScale.XScale,...
                                       'YScale', obj.axesScale.YScale);
                    children_ = get(obj.mainAxes, 'children');
                    numChildren_ = 1:length(children_);
                    for ii = 1:length(children_)
                        if strcmp(children_(ii, 1).Type, 'images.roi.rectangle') ||...
                                strcmp(children_(ii, 1).Type, 'hggroup')
                            numChildren_(ii) = [];
                        end
                    end
                    copyobj(children_(numChildren_), obj.subAxes);
                    hold(obj.subAxes, 'on');
                    set(obj.subAxes, 'LineWidth', obj.subAxesinsertedLineWidth,...
                        'TickDir', obj.subAxesTickDirection,...
                        'Box', obj.subAxesBox,...
                        'Color', obj.subAxesBackgroundColor,...
                        'XLim', get(obj.mainAxes, 'XLim'),...
                        'YLim', get(obj.mainAxes, 'YLim'),...
                        'XScale', obj.axesScale.XScale,...
                        'YScale', obj.axesScale.YScale);
                    set(obj.subAxes, 'Visible', 'off');
            end
        end

        function creatRectangle(obj)
            % creat rectangle
            switch obj.axesClass
                case 'image' %
                    obj.rectangleZoomedZone = annotation( ...
                        'rectangle', obj.imageRectangleEdgePosition, ...
                        'LineWidth', obj.imageRectangleLineWidth,...
                        'LineStyle', obj.imageRectangleLineStyle,...
                        'FaceAlpha', obj.imageRectangleFaceAlpha,...
                        'FaceColor', obj.imageRectangleFaceColor,...
                        'Color', obj.imageRectangleColor);

                case 'figure'
                    obj.rectangleZoomedZone = annotation( ...
                        'rectangle', obj.affinePosition, ...
                        'LineWidth', obj.rectangleLineWidth,...
                        'LineStyle', obj.rectangleLineStyle,...
                        'FaceAlpha', obj.rectangleFaceAlpha,...
                        'FaceColor', obj.rectangleFaceColor,...
                        'Color', obj.rectangleColor);
            end
        end

        function mappingParams = computeMappingParams(obj)
            % compute the mapping parameters

            switch obj.axesScale.XScale
                case 'linear'
                    rangeXLim = obj.mainAxes.XLim(1, 2)-obj.mainAxes.XLim(1, 1);
                case 'log'
                    rangeXLim = log10(obj.mainAxes.XLim(1, 2))-log10(obj.mainAxes.XLim(1, 1));
            end
            map_k_x = rangeXLim/obj.mainAxes.Position(3);

            switch obj.axesScale.YScale
                case 'linear'
                    rangeYLim = obj.mainAxes.YLim(1, 2)-obj.mainAxes.YLim(1, 1);
                case 'log'
                    rangeYLim = log10(obj.mainAxes.YLim(1, 2))-log10(obj.mainAxes.YLim(1, 1));
            end
            map_k_y = rangeYLim/obj.mainAxes.Position(4);

            switch obj.axesScale.XScale
                case 'linear'
                    map_b_x = obj.mainAxes.XLim(1)-obj.mainAxes.Position(1)*map_k_x;
                case 'log'
                    map_b_x = log10(obj.mainAxes.XLim(1))-obj.mainAxes.Position(1)*map_k_x;
            end

            switch obj.axesScale.YScale
                case 'linear'
                    map_b_y = obj.mainAxes.YLim(1)-obj.mainAxes.Position(2)*map_k_y;
                case 'log'
                    map_b_y = log10(obj.mainAxes.YLim(1))-obj.mainAxes.Position(2)*map_k_y;
            end
            mappingParams = [map_k_x, map_b_x; map_k_y, map_b_y];
        end

        function connectAxesAndBox(obj)
            % insert lines between the inserted axes and rectangle

            %   Rectangle        subAxes
            %    2----1          2----1
            %    3----4          3----4

            switch obj.axesClass
                case 'image' %
                    uPixelsAll = obj.uPixels/obj.mainAxes.Position(3);
                    vPixelsAll = obj.vPixels/obj.mainAxes.Position(4);
                    switch obj.drawFunc
                        case 'drawrectangle'
                            Position_ = obj.roi.Position;

                        case 'imrect'
                            Position_ = getPosition(obj.roi);
                    end

                    obj.imageRectangleEdgePosition(1) = Position_(1)/uPixelsAll+obj.mainAxes.Position(1);
                    obj.imageRectangleEdgePosition(2) = (obj.vPixels-Position_(2)-Position_(4))/...
                        vPixelsAll+obj.subAxes.Position(2);
                    obj.imageRectangleEdgePosition(3) = Position_(3)/uPixelsAll;
                    obj.imageRectangleEdgePosition(4) = Position_(4)/vPixelsAll;

                    % annotation position 1
                    annotationPosX_1(1) = obj.imageRectangleEdgePosition(1)+obj.imageRectangleEdgePosition(3);
                    annotationPosX_1(2) = obj.subAxes.Position(1);
                    annotationPosY_1(1) = obj.imageRectangleEdgePosition(2);
                    annotationPosY_1(2) = obj.subAxes.Position(2);
                    obj.imageArrow{1} = annotation(gcf, 'doublearrow',...
                        annotationPosX_1, annotationPosY_1,...
                            'Color', obj.imageConnectedLineColor,...
                            'LineWidth', obj.imageConnectedLineWidth,...
                            'LineStyle', obj.imageConnectedLineStyle,...
                            'Head1Style', obj.imageConnectedLineStartHeadStyle,...
                            'Head1Length', obj.imageConnectedLineStartHeadLength,...
                            'Head1Width', obj.imageConnectedLineStartHeadWidth,...
                            'Head2Style', obj.imageConnectedLineEndHeadStyle,...
                            'Head2Length', obj.imageConnectedLineEndHeadLength,...
                            'Head2Width', obj.imageConnectedLineEndHeadWidth,...
                            'Tag', 'ZoomPlot_');

                    % annotation position 2
                    annotationPosX_2(1) = obj.imageRectangleEdgePosition(1)+obj.imageRectangleEdgePosition(3);
                    annotationPosX_2(2) = obj.subAxes.Position(1);
                    annotationPosY_2(1) = obj.imageRectangleEdgePosition(2)+obj.imageRectangleEdgePosition(4);
                    annotationPosY_2(2) = obj.subAxes.Position(2)+obj.subAxes.Position(4);
                    obj.imageArrow{2} = annotation(gcf, 'doublearrow',...
                        annotationPosX_2, annotationPosY_2,...
                            'Color', obj.imageConnectedLineColor,...
                            'LineWidth', obj.imageConnectedLineWidth,...
                            'LineStyle', obj.imageConnectedLineStyle,...
                            'Head1Style', obj.imageConnectedLineStartHeadStyle,...
                            'Head1Length', obj.imageConnectedLineStartHeadLength,...
                            'Head1Width', obj.imageConnectedLineStartHeadWidth,...
                            'Head2Style', obj.imageConnectedLineEndHeadStyle,...
                            'Head2Length', obj.imageConnectedLineEndHeadLength,...
                            'Head2Width', obj.imageConnectedLineEndHeadWidth,...
                            'Tag', 'ZoomPlot_');

                case 'figure'
                    % real coordinates of the inserted rectangle and axes
                    obj.getAxesAndBoxPosition;
                    % get the line direction
                    obj.getLineDirection;
                    % insert lines
                    numLine = size(obj.lineDirection, 1);
                    for i = 1:numLine
                        tmp1 = [obj.figureRectangleEdgePosition(obj.lineDirection(i, 1), 1),...
                            obj.figureRectangleEdgePosition(obj.lineDirection(i, 1), 2)];
                        tmp2 = [obj.axesPosition(obj.lineDirection(i, 2), 1),...
                            obj.axesPosition(obj.lineDirection(i, 2), 2)];
                        pos1 = obj.transformCoordinate(tmp1, 'a2n');
                        pos2 = obj.transformCoordinate(tmp2, 'a2n');
                        obj.figureArrow{i} = annotation(gcf, 'doublearrow',...
                            [pos1(1, 1), pos2(1, 1)], [pos1(1, 2), pos2(1, 2)],...
                            'Color', obj.figureConnectedLineColor,...
                            'LineWidth', obj.figureConnectedLineWidth,...
                            'LineStyle', obj.figureConnectedLineStyle,...
                            'Head1Style', obj.figureConnectedLineStartHeadStyle,...
                            'Head1Length', obj.figureConnectedLineStartHeadLength,...
                            'Head1Width', obj.figureConnectedLineStartHeadWidth,...
                            'Head2Style', obj.figureConnectedLineEndHeadStyle,...
                            'Head2Length', obj.figureConnectedLineEndHeadLength,...
                            'Head2Width', obj.figureConnectedLineEndHeadWidth,...
                            'Tag', 'ZoomPlot_');
                    end
            end
        end

        function getAxesAndBoxPosition(obj)
            % real coordinates of the inserted rectangle
            box1_1 = [obj.XLimNew(1, 2), obj.YLimNew(1, 2)];
            box1_2 = [obj.XLimNew(1, 1), obj.YLimNew(1, 2)];
            box1_3 = [obj.XLimNew(1, 1), obj.YLimNew(1, 1)];
            box1_4 = [obj.XLimNew(1, 2), obj.YLimNew(1, 1)];
            box1 = [box1_1; box1_2; box1_3; box1_4];
            % real coordinates of the inserted axes
            tmp1 = [obj.subAxes.Position(1)+obj.subAxes.Position(3),...
                obj.subAxes.Position(2)+obj.subAxes.Position(4)];
            box2_1 = obj.transformCoordinate(tmp1, 'n2a');
            tmp2 = [obj.subAxes.Position(1),...
                obj.subAxes.Position(2)+obj.subAxes.Position(4)];
            box2_2 = obj.transformCoordinate(tmp2, 'n2a');
            tmp3 = [obj.subAxes.Position(1), obj.subAxes.Position(2)];
            box2_3 = obj.transformCoordinate(tmp3, 'n2a');
            tmp4 = [obj.subAxes.Position(1)+obj.subAxes.Position(3),...
                obj.subAxes.Position(2)];
            box2_4 = obj.transformCoordinate(tmp4, 'n2a');
            box2 = [box2_1; box2_2; box2_3; box2_4];
            obj.figureRectangleEdgePosition = box1;
            obj.axesPosition = box2;
        end

        function getLineDirection(obj)
            % get the line direction
            % left-upper
            if (obj.figureRectangleEdgePosition(4, 1) < obj.axesPosition(1, 1) &&...
                    obj.figureRectangleEdgePosition(4, 2) > obj.axesPosition(2, 2))
                obj.lineDirection = [3, 3; 1, 1];
            end
            % middle-upper
            if (obj.figureRectangleEdgePosition(4, 1) > obj.axesPosition(2, 1) &&...
                    obj.figureRectangleEdgePosition(4, 2) > obj.axesPosition(2, 2)) &&...
                    obj.figureRectangleEdgePosition(3, 1) < obj.axesPosition(1, 1)
                obj.lineDirection = [4, 1; 3, 2];
            end
            % right-upper
            if (obj.figureRectangleEdgePosition(3, 1) > obj.axesPosition(1, 1) &&...
                    obj.figureRectangleEdgePosition(3, 2) > obj.axesPosition(1, 2))
                obj.lineDirection = [2, 2; 4, 4];
            end
            % right-middle
            if (obj.figureRectangleEdgePosition(3, 1) > obj.axesPosition(1, 1) &&...
                    obj.figureRectangleEdgePosition(3, 2) < obj.axesPosition(1, 2)) &&...
                    obj.figureRectangleEdgePosition(2, 2) > obj.axesPosition(4, 2)
                obj.lineDirection = [2, 1; 3, 4];
            end
            % right-down
            if (obj.figureRectangleEdgePosition(2, 1) > obj.axesPosition(4, 1) &&...
                    obj.figureRectangleEdgePosition(2, 2) < obj.axesPosition(4, 2))
                obj.lineDirection = [1, 1; 3, 3];
            end
            % down-middle
            if (obj.figureRectangleEdgePosition(1, 1) > obj.axesPosition(3, 1) &&...
                    obj.figureRectangleEdgePosition(1, 2) < obj.axesPosition(3, 2) &&...
                    obj.figureRectangleEdgePosition(2, 1) < obj.axesPosition(4, 1))
                obj.lineDirection = [2, 3; 1, 4];
            end
            % left-down
            if (obj.figureRectangleEdgePosition(1, 1) < obj.axesPosition(3, 1) &&...
                    obj.figureRectangleEdgePosition(1, 2) < obj.axesPosition(3, 2))
                obj.lineDirection = [2, 2; 4, 4];
            end
            % left-middle
            if (obj.figureRectangleEdgePosition(4, 1) <obj.axesPosition(2, 1) &&...
                    obj.figureRectangleEdgePosition(4, 2) < obj.axesPosition(2, 2)) &&...
                    obj.figureRectangleEdgePosition(1, 2) > obj.axesPosition(3, 2)
                obj.lineDirection = [1, 2; 4, 3];
            end
        end

        function setTheme(obj)
            % set the theme of the dynamic rectangle
            switch obj.drawFunc
                case 'drawrectangle'
                    try
                        obj.roi.MarkerSize = obj.dynamicRectFacAngleMarkerSize;
                    catch

                    end
                    obj.roi.Color = obj.dynamicRectFaceColor;
                    obj.roi.FaceAlpha = obj.dynamicRectFaceAspect;
                    obj.roi.LineWidth = obj.dynamicRectLineWidth;
                case 'imrect'
                    children_ = get(findobj(gca, 'type', 'hggroup'), 'children');
                    % 8 angles
                    for i = [1:4, 6:2:12]
                        children_(i).LineWidth = obj.dynamicRectLineWidth*0.6;
                        children_(i).Color = obj.dynamicRectLineColor;
                        children_(i).MarkerSize = obj.dynamicRectFacAngleMarkerSize;
                        children_(i).Marker = obj.dynamicRectFacAngleMarker;
                        children_(i).MarkerEdgeColor = 'k';
                        children_(i).MarkerFaceColor = obj.dynamicRectFaceColor;
                    end
                    % 4 lines
                    for i = 5:2:11
                        children_(i).Color = obj.dynamicRectFaceColor;
                        children_(i).LineWidth = obj.dynamicRectLineWidth;
                        children_(i).Marker = 'none';
                    end
                    % dynamic rectangle
                    children_(13).FaceAlpha = obj.dynamicRectFaceAspect;
                    children_(13).FaceColor = obj.dynamicRectFaceColor;
            end
        end

        function coordinate = transformCoordinate(obj, coordinate, type)
            % coordinate transformation
            switch type
                % absolute coordinates to normalized coordinates
                case 'a2n'
                    switch obj.axesScale.XScale
                        case 'linear'
                            coordinate(1, 1) = (coordinate(1, 1)-obj.mappingParams(1, 2))...
                                /obj.mappingParams(1, 1);
                        case 'log'
                            coordinate(1, 1) = (log10(coordinate(1, 1))-obj.mappingParams(1, 2))...
                                /obj.mappingParams(1, 1);
                    end

                    switch obj.axesScale.YScale
                        case 'linear'
                            coordinate(1, 2) = (coordinate(1, 2)-obj.mappingParams(2, 2))...
                                /obj.mappingParams(2, 1);
                        case 'log'
                            coordinate(1, 2) = (log10(coordinate(1, 2))-obj.mappingParams(2, 2))...
                                /obj.mappingParams(2, 1);
                    end

                % normalized coordinates to absolute coordinates
                case 'n2a'
                    switch obj.axesScale.XScale
                        case 'linear'
                            coordinate(1, 1) = coordinate(1, 1)*obj.mappingParams(1, 1)...
                                +obj.mappingParams(1, 2);
                        case 'log'
                            coordinate(1, 1) = 10^(coordinate(1, 1)*obj.mappingParams(1, 1)...
                                +obj.mappingParams(1, 2));
                    end

                    switch obj.axesScale.YScale
                        case 'linear'
                            coordinate(1, 2) = coordinate(1, 2)*obj.mappingParams(2, 1)...
                                +obj.mappingParams(2, 2);
                        case 'log'
                            coordinate(1, 2) = 10^(coordinate(1, 2)*obj.mappingParams(2, 1)...
                                +obj.mappingParams(2, 2));
                    end
            end
        end

        % dependent properties
        function dynamicPosition = get.dynamicPosition(obj)
            switch obj.drawFunc
                case 'drawrectangle'
                    dynamicPosition = obj.roi.Position;
                case 'imrect'
                    dynamicPosition = getPosition(obj.roi);
            end
        end

        % dependent properties
        function XLimNew = get.XLimNew(obj)
            XLimNew = [obj.dynamicPosition(1), obj.dynamicPosition(1)+obj.dynamicPosition(3)];
        end

        % dependent properties
        function YLimNew = get.YLimNew(obj)
            YLimNew = [obj.dynamicPosition(2), obj.dynamicPosition(2)+obj.dynamicPosition(4)];
        end

        % dependent properties
        function affinePosition = get.affinePosition(obj)
            obj.mappingParams = obj.computeMappingParams;
            tmp1 = obj.transformCoordinate([obj.XLimNew(1, 1), obj.YLimNew(1, 1)], 'a2n');
            tmp2 = obj.transformCoordinate([obj.XLimNew(1, 2), obj.YLimNew(1, 2)], 'a2n');
            affinePosition(1, 1) = tmp1(1, 1);
            affinePosition(1, 2) = tmp1(1, 2);
            affinePosition(1, 3) = tmp2(1, 1)-tmp1(1, 1);
            affinePosition(1, 4) = tmp2(1, 2)-tmp1(1, 2);
        end

        % dependent properties
        function newCData_ = get.newCData_(obj)
            switch obj.drawFunc
                case 'drawrectangle'
                    Position_ = obj.roi.Position;
                case 'imrect'
                    Position_ = getPosition(obj.roi);
            end
            newCData_ = imcrop(obj.CData_,obj.Colormap_, Position_);
        end

        % dependent properties
        function newCData = get.newCData(obj)
            switch obj.imageDim
                case 2
                    [newCData, ~] = imresize(obj.newCData_, obj.Colormap_, [obj.vPixels, obj.uPixels]);
                    %  [~, newCMap] = imresize(obj.newCData_, obj.newCMap_, [obj.vPixels, obj.uPixels]);
                case 3
                    newCData = imresize(obj.newCData_, [obj.vPixels, obj.uPixels]);
            end
        end

        % dependent properties
        function newCMap = get.newCMap(obj)
            switch obj.imageDim
                case 2
                    [~, newCMap] = imresize(obj.newCData_, obj.Colormap_, [obj.vPixels, obj.uPixels]);
                case 3
                    newCMap=[];
            end
        end
    end
end

