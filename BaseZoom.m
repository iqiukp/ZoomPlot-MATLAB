classdef BaseZoom < handle
    %{

        Interactive Magnification of Customized Regions.

        Email: iqiukp@outlook.com
    
        -------------------------------------------------------------
  
        Version 1.4, 30-MAY-2023
            -- Added support for charts with two y-axes.
            -- Customize parameters using json files.

        Version 1.3.1, 24-JAN-2022
            -- Fixed bugs when applied to logarithmic-scale coordinates. 

        Version 1.3, 17-JAN-2022
            -- Fixed minor bugs.
            -- Added support for image class.

        Version 1.2, 4-OCT-2021
            -- Added support for interaction.

        Version 1.1, 1-SEP-2021
            -- Fixed minor bugs.
            -- Added description of parameters.   

        Version 1.0, 10-JUN-2021
            -- Magnification of Customized Regions.

        -------------------------------------------------------------
        
        BSD 3-Clause License
        Copyright (c) 2023, Kepeng Qiu
        All rights reserved.
        
    %}

    % main  properties
    properties
        subFigure
        mainAxes
        subAxes
        roi
        zoomedArea
        param
        XAxis
        YAxis
        direction
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
    end

    methods
        function plot(this)
            % main steps
            this.checkVersion;
            this.initialize;
            this.loadParameters;
            switch this.axesClass
                case 'image'
                    this.addSubAxes;
                    this.axesDone = 'off';
                    fprintf('Use the left mouse button to draw a rectangle.\n')
                    fprintf('for the zoomed area...\n')
                    this.addZoomedArea;
                    this.rectangleDone = 'off';
                case 'figure'
                    fprintf('Use the left mouse botton to draw a rectangle.\n')
                    fprintf('for the sub axes...\n')
                    this.addSubAxes;
                    this.axesDone = 'off';
                    fprintf('Use the left mouse button to draw a rectangle.\n')
                    fprintf('for the zoomed area...\n')
                    this.addZoomedArea;
                    this.rectangleDone = 'off';
            end
        end

        function checkVersion(this)
            version_ = version('-release');
            year_ = str2double(version_(1:4));
            if year_ < 2016
                error('ZoomPlot V1.4 is not compatible with the versions lower than R2016a.')
            end
            if year_ >= 2017
                set(findobj(gcf, 'type', 'Legend'), 'AutoUpdate', 'off');
            end
            if year_ > 2018 || (year_ == 2018 && version_(5) == 'b')
                this.drawFunc = 'drawrectangle';
            else
                this.drawFunc = 'imrect';
            end
        end

        function loadParameters(this)
            fileName = 'parameters.json';
            fid = fopen(fileName);
            raw = fread(fid,inf);
            str = char(raw');
            fclose(fid);
            this.param = jsondecode(str);
            names_ = fieldnames(this.param);
            for i = 1:length(names_)
                if isfield(this.param.(names_{i}), 'Comments')
                    this.param.(names_{i}) = rmfield(this.param.(names_{i}), 'Comments');
                end
            end
        end

        function initialize(this)
            this.mainAxes = gca;
            this.YAxis.direction = {'left', 'right'};
            this.YAxis.number = length(this.mainAxes.YAxis);
            this.XAxis.number = length(this.mainAxes.XAxis);
            this.XAxis.scale = this.mainAxes.XScale;
            this.direction = this.mainAxes.YAxisLocation;
            switch this.YAxis.number
                case 1
                    this.YAxis.(this.direction).scale = this.mainAxes.YScale;
                case 2
                    for i = 1:2
                        yyaxis(this.mainAxes, this.YAxis.direction{1, i});
                        this.YAxis.(this.YAxis.direction{1, i}).scale = this.mainAxes.YScale;
                        this.YAxis.scale{i} = this.mainAxes.YScale;
                    end
                    this.YAxis.scale = cell2mat(this.YAxis.scale);
                    yyaxis(this.mainAxes, this.direction);
            end
            if size(imhandles(this.mainAxes),1) ~= 0
                this.axesClass = 'image';
                this.CData_ = get(this.mainAxes.Children, 'CData');
                this.Colormap_ = colormap(gca);
                if size(this.Colormap_, 1) == 64
                    this.Colormap_ = colormap(gcf);
                end
                [this.vPixels, this.uPixels, ~] = size(this.CData_);
                this.vuRatio = this.vPixels/this.uPixels;
                this.imageDim = length(size(this.CData_));
            else
                this.axesClass = 'figure';
            end
        end

        function addSubAxes(this)
            switch this.axesClass
                case 'image'
                    this.subFigure = figure;
                    this.imagePosition(4) = this.imagePosition(3)*this.vuRatio;
                    set(this.subFigure, 'Units', 'Normalized', 'OuterPosition', this.imagePosition);
                    subplot(1, 2, 1, 'Parent', this.subFigure);
                    image(this.CData_);
                    this.mainAxes = gca;
                    if this.imageDim == 2
                        colormap(this.mainAxes, this.Colormap_);
                    end
                    axis off
                    subplot(1, 2, 2, 'Parent', this.subFigure);
                    image((ones(this.vPixels, this.uPixels)));
                    this.subAxes = gca;
                    colormap(this.subAxes, [240, 240, 240]/255);
                    axis off
                case 'figure' %
                    switch this.drawFunc
                        case 'drawrectangle'
                            this.roi = drawrectangle(this.mainAxes);
                            this.setTheme;
                            this.creatSubAxes;
                            set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'subAxes'});
                            addlistener(this.roi, 'MovingROI', @(source, event) ...
                                this.allEvents(source, event, 'subAxes'));
                            addlistener(this.roi, 'ROIMoved', @(source, event) ...
                                this.allEvents(source, event, 'subAxes'));
                            while strcmp(this.axesDone, 'off')
                                pause(this.pauseTime);
                            end
                        case 'imrect'
                            this.roi = imrect;
                            this.setTheme;
                            func_ = makeConstrainToRectFcn('imrect',...
                                get(this.mainAxes, 'XLim'), get(this.mainAxes, 'YLim'));
                            setPositionConstraintFcn(this.roi, func_);
                            this.creatSubAxes;
                            addNewPositionCallback(this.roi, @(handle) ...
                                allEvents(this, this.roi, [], 'subAxes'));
                            set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'subAxes'});
                            wait(this.roi);
                            while strcmp(this.axesDone, 'off')
                                pause(this.pauseTime);
                            end
                    end
            end
        end

        function addZoomedArea(this)
            switch this.axesClass
                case 'image'
                    switch this.drawFunc
                        case 'drawrectangle'
                            this.roi = drawrectangle(this.mainAxes);
                            this.setTheme;
                            this.creatSubAxes;
                            if strcmp(this.param.subAxes.Box, 'on')
                                this.connectAxesAndBox;
                            end
                            set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'zoomedArea'});
                            addlistener(this.roi, 'MovingROI', @(source, event) ...
                                this.allEvents(source, event, 'zoomedArea'));
                            addlistener(this.roi, 'ROIMoved', @(source, event) ...
                                this.allEvents(source, event, 'zoomedArea'));
                            while strcmp(this.rectangleDone, 'off')
                                pause(this.pauseTime);
                            end
                        case 'imrect'
                            this.roi = imrect(this.mainAxes);
                            this.setTheme;
                            this.creatSubAxes;
                            func_ = makeConstrainToRectFcn('imrect',...
                                get(this.mainAxes, 'XLim'), get(this.mainAxes, 'YLim'));
                            setPositionConstraintFcn(this.roi, func_);
                            if strcmp(this.param.subAxes.Box, 'on')
                                this.connectAxesAndBox;
                            end
                            addNewPositionCallback(this.roi, @(handle) ...
                                allEvents(this, this.roi, [], 'zoomedArea'));
                            set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'zoomedArea'});
                            wait(this.roi);
                            while strcmp(this.rectangleDone, 'off')
                                pause(this.pauseTime);
                            end
                    end
                    for iArrow = 1:length(this.imageArrow)
                        this.imageArrow{iArrow}.Tag = 'ZoomPlot';
                    end

                case 'figure' %
                    switch this.drawFunc
                        case 'drawrectangle'
                            this.roi = drawrectangle(this.mainAxes);
                            this.setTheme;
                            if strcmp(this.param.subAxes.Box, 'on')
                                this.connectAxesAndBox;
                            end
                            this.setSubAxesLim;
                            set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'zoomedArea'});
                            addlistener(this.roi, 'MovingROI', @(source, event) ...
                                this.allEvents(source, event, 'zoomedArea'));
                            addlistener(this.roi, 'ROIMoved', @(source, event) ...
                                this.allEvents(source, event, 'zoomedArea'));
                            while strcmp(this.rectangleDone, 'off')
                                pause(this.pauseTime);
                            end
                        case 'imrect'
                            this.roi = imrect;
                            this.setTheme;
                            func_ = makeConstrainToRectFcn('imrect',...
                                get(this.mainAxes, 'XLim'), get(this.mainAxes, 'YLim'));
                            setPositionConstraintFcn(this.roi, func_);
                            if strcmp(this.param.subAxes.Box, 'on')
                                this.connectAxesAndBox;
                            end
                            set(this.subAxes, 'XLim', this.XLimNew, 'YLim', this.YLimNew);
                            addNewPositionCallback(this.roi, @(handle) ...
                                allEvents(this, this.roi, [], 'zoomedArea'));
                            set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'zoomedArea'});
                            wait(this.roi);
                            while strcmp(this.rectangleDone, 'off')
                                pause(this.pauseTime);
                            end
                    end
                    for iArrow = 1:length(this.figureArrow)
                        this.figureArrow{iArrow}.Tag = 'ZoomPlot';
                    end
            end
        end

        function allEvents(this,  ~, ~, mode)
            switch mode
                case 'subAxes'
                    if strcmp(this.textDisplay, 'on')
                        fprintf('adjust the sub axes...\n');
                    end
                    delete(this.subAxes);
                    this.creatSubAxes;
                    this.subAxes.Color = this.param.subAxes.Color;
                case 'zoomedArea'
                    if strcmp(this.textDisplay, 'on')
                        fprintf('adjust the zoomed area...\n')
                    end
                    delete(findall(gcf, 'Tag', 'ZoomPlot_'))
                    if strcmp(this.param.subAxes.Box, 'on')
                        this.connectAxesAndBox;
                    end
                    switch this.axesClass
                        case 'image' %
                            this.creatSubAxes;
                        case 'figure' %
                            this.setSubAxesLim;
                    end
            end
        end

        function clickEvents(this, ~, ~, mode)
            switch mode
                case 'subAxes'
                    switch get(gcf, 'SelectionType')
                        case 'alt'
                            this.axesDone = 'on';
                            set(this.subAxes, 'Visible', 'on');
                            set(gcf, 'WindowButtonDownFcn', []);
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Complete the adjustment of the sub axes.\n\n');
                            end
                            delete(this.roi);
                            this.subAxes.Color = this.param.subAxes.Color;

                        case 'normal'
                            this.axesDone = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                            this.subAxes.Color = this.param.subAxes.Color;

                        otherwise
                            this.axesDone = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                            this.subAxes.Color = this.param.subAxes.Color;
                    end

                case 'zoomedArea'
                    switch get(gcf, 'SelectionType')
                        case 'alt'
                            this.rectangleDone = 'on';
                            this.creatRectangle;
                            set(gcf, 'WindowButtonDownFcn', []);
                            delete(this.roi);
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Complete the adjustment of the zoomed area.\n\n');
                            end
                        case 'normal'
                            this.rectangleDone = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                        otherwise
                            this.rectangleDone = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                    end
            end
        end

        function creatSubAxes(this)
            switch this.axesClass
                case 'image'
                    set(this.subAxes.Children, 'CData', this.newCData);
                    if this.imageDim == 2
                        colormap(this.subAxes, this.newCMap);
                    end
                case 'figure'
                    if this.YAxis.number == 1
                        this.subAxes = axes('Position', this.affinePosition,...
                            'XScale', this.XAxis.scale,...
                            'YScale', this.YAxis.(this.direction).scale);
                        mainChildren = this.getMainChildren;
                        copyobj(mainChildren, this.subAxes);
                        this.subAxes.XLim = this.mainAxes.XLim;
                        hold(this.subAxes, 'on');
                        set(this.subAxes, this.param.subAxes);
                        set(this.subAxes, 'Visible', 'off');
                    end
                    if this.YAxis.number == 2
                        diret_ = this.YAxis.direction;
                        this.subAxes = axes('Position', this.affinePosition);
                        for i = 1:2
                            yyaxis(this.subAxes, diret_{i});
                            yyaxis(this.mainAxes, diret_{i});
                            set(this.subAxes, 'XScale', this.mainAxes.XScale,...
                                'YScale', this.mainAxes.YScale)
                            mainChildren = this.getMainChildren;
                            copyobj(mainChildren, this.subAxes);
                            this.subAxes.XLim = this.mainAxes.XLim;
                            YLim.(diret_{i}) = this.subAxes.YLim;
                        end
                        yyaxis(this.mainAxes, this.direction);
                        switch this.YAxis.scale
                            case 'linearlinear'
                                Y_from = YLim.(this.direction);
                                Y_to = YLim.(cell2mat(setdiff(diret_, this.direction)));
                            case 'linearlog'
                                Y_from = YLim.(this.direction);
                                Y_to = log10(YLim.(cell2mat(setdiff(diret_, this.direction))));
                            case 'loglinear'
                                Y_from = log10(YLim.(this.direction));
                                Y_to = YLim.(cell2mat(setdiff(diret_, this.direction)));
                            case 'loglog'
                                Y_from = log10(YLim.(this.direction));
                                Y_to = log10(YLim.(cell2mat(setdiff(diret_, this.direction))));
                        end
                        this.YAxis.K = (Y_to(2)-Y_to(1))/(Y_from(2)-Y_from(1));
                        this.YAxis.b = Y_to(1)-Y_from(1)*this.YAxis.K;
                        hold(this.subAxes, 'on');
                        set(this.subAxes, this.param.subAxes);
                        set(this.subAxes, 'Visible', 'off');
                    end
            end
        end

        function creatRectangle(this)
            switch this.axesClass
                case 'image'
                    this.zoomedArea = annotation( ...
                        'rectangle', this.imageRectangleEdgePosition, ...
                        'Color', this.param.zoomedArea.Color,...
                        'FaceColor', this.param.zoomedArea.FaceColor,...
                        'FaceAlpha', this.param.zoomedArea.FaceAlpha,...
                        'LineStyle', this.param.zoomedArea.LineStyle,...
                        'LineWidth', this.param.zoomedArea.LineWidth);
                case 'figure'
                    this.zoomedArea = annotation(...
                        'rectangle', this.affinePosition, ...
                        'Color', this.param.zoomedArea.Color,...
                        'FaceColor', this.param.zoomedArea.FaceColor,...
                        'FaceAlpha', this.param.zoomedArea.FaceAlpha,...
                        'LineStyle', this.param.zoomedArea.LineStyle,...
                        'LineWidth', this.param.zoomedArea.LineWidth);
            end
        end

        function mappingParams = computeMappingParams(this)
            switch this.XAxis.scale
                case 'linear'
                    rangeXLim = this.mainAxes.XLim(1, 2)-this.mainAxes.XLim(1, 1);
                case 'log'
                    rangeXLim = log10(this.mainAxes.XLim(1, 2))-log10(this.mainAxes.XLim(1, 1));
            end
            map_k_x = rangeXLim/this.mainAxes.Position(3);
            switch this.YAxis.(this.direction).scale
                case 'linear'
                    rangeYLim = this.mainAxes.YLim(1, 2)-this.mainAxes.YLim(1, 1);
                case 'log'
                    rangeYLim = log10(this.mainAxes.YLim(1, 2))-log10(this.mainAxes.YLim(1, 1));
            end
            map_k_y = rangeYLim/this.mainAxes.Position(4);
            switch this.XAxis.scale
                case 'linear'
                    map_b_x = this.mainAxes.XLim(1)-this.mainAxes.Position(1)*map_k_x;
                case 'log'
                    map_b_x = log10(this.mainAxes.XLim(1))-this.mainAxes.Position(1)*map_k_x;
            end
            switch this.YAxis.(this.direction).scale
                case 'linear'
                    map_b_y = this.mainAxes.YLim(1)-this.mainAxes.Position(2)*map_k_y;
                case 'log'
                    map_b_y = log10(this.mainAxes.YLim(1))-this.mainAxes.Position(2)*map_k_y;
            end
            mappingParams = [map_k_x, map_b_x; map_k_y, map_b_y];
        end

        function connectAxesAndBox(this)
            % insert lines between the inserted axes and rectangle

            %   Rectangle        subAxes
            %    2----1          2----1
            %    3----4          3----4

            switch this.axesClass
                case 'image' %
                    uPixelsAll = this.uPixels/this.mainAxes.Position(3);
                    vPixelsAll = this.vPixels/this.mainAxes.Position(4);
                    switch this.drawFunc
                        case 'drawrectangle'
                            Position_ = this.roi.Position;
                        case 'imrect'
                            Position_ = getPosition(this.roi);
                    end
                    this.imageRectangleEdgePosition(1) = Position_(1)/uPixelsAll+this.mainAxes.Position(1);
                    this.imageRectangleEdgePosition(2) = (this.vPixels-Position_(2)-Position_(4))/...
                        vPixelsAll+this.subAxes.Position(2);
                    this.imageRectangleEdgePosition(3) = Position_(3)/uPixelsAll;
                    this.imageRectangleEdgePosition(4) = Position_(4)/vPixelsAll;
                    % annotation position 1
                    annotationPosX_1(1) = this.imageRectangleEdgePosition(1)+this.imageRectangleEdgePosition(3);
                    annotationPosX_1(2) = this.subAxes.Position(1);
                    annotationPosY_1(1) = this.imageRectangleEdgePosition(2);
                    annotationPosY_1(2) = this.subAxes.Position(2);
                    this.imageArrow{1} = annotation(gcf, 'doublearrow',...
                        annotationPosX_1, annotationPosY_1,...
                        'Color', this.param.connection.LineColor,...
                        'LineWidth', this.param.connection.LineWidth,...
                        'LineStyle', this.param.connection.LineStyle,...
                        'Head1Style', this.param.connection.StartHeadStyle,...
                        'Head1Length', this.param.connection.StartHeadLength,...
                        'Head1Width', this.param.connection.StartHeadWidth,...
                        'Head2Style', this.param.connection.EndHeadStyle,...
                        'Head2Length', this.param.connection.EndHeadLength,...
                        'Head2Width', this.param.connection.EndHeadWidth,...
                        'Tag', 'ZoomPlot_');
                    % annotation position 2
                    annotationPosX_2(1) = this.imageRectangleEdgePosition(1)+this.imageRectangleEdgePosition(3);
                    annotationPosX_2(2) = this.subAxes.Position(1);
                    annotationPosY_2(1) = this.imageRectangleEdgePosition(2)+this.imageRectangleEdgePosition(4);
                    annotationPosY_2(2) = this.subAxes.Position(2)+this.subAxes.Position(4);
                    this.imageArrow{2} = annotation(gcf, 'doublearrow',...
                        annotationPosX_2, annotationPosY_2,...
                        'Color', this.param.connection.LineColor,...
                        'LineWidth', this.param.connection.LineWidth,...
                        'LineStyle', this.param.connection.LineStyle,...
                        'Head1Style', this.param.connection.StartHeadStyle,...
                        'Head1Length', this.param.connection.StartHeadLength,...
                        'Head1Width', this.param.connection.StartHeadWidth,...
                        'Head2Style', this.param.connection.EndHeadStyle,...
                        'Head2Length', this.param.connection.EndHeadLength,...
                        'Head2Width', this.param.connection.EndHeadWidth,...
                        'Tag', 'ZoomPlot_');
                case 'figure'
                    % real coordinates of the inserted rectangle and axes
                    this.getAxesAndBoxPosition;
                    % get the line direction
                    this.getLineDirection;
                    % insert lines
                    numLine = size(this.lineDirection, 1);
                    for i = 1:numLine
                        tmp1 = [this.figureRectangleEdgePosition(this.lineDirection(i, 1), 1),...
                            this.figureRectangleEdgePosition(this.lineDirection(i, 1), 2)];
                        tmp2 = [this.axesPosition(this.lineDirection(i, 2), 1),...
                            this.axesPosition(this.lineDirection(i, 2), 2)];
                        pos1 = this.transformCoordinate(tmp1, 'a2n');
                        pos2 = this.transformCoordinate(tmp2, 'a2n');
                        this.figureArrow{i} = annotation(gcf, 'doublearrow',...
                            [pos1(1, 1), pos2(1, 1)], [pos1(1, 2), pos2(1, 2)],...
                            'Color', this.param.connection.LineColor,...
                            'LineWidth', this.param.connection.LineWidth,...
                            'LineStyle', this.param.connection.LineStyle,...
                            'Head1Style', this.param.connection.StartHeadStyle,...
                            'Head1Length', this.param.connection.StartHeadLength,...
                            'Head1Width', this.param.connection.StartHeadWidth,...
                            'Head2Style', this.param.connection.EndHeadStyle,...
                            'Head2Length', this.param.connection.EndHeadLength,...
                            'Head2Width', this.param.connection.EndHeadWidth,...
                            'Tag', 'ZoomPlot_');
                    end
            end
        end

        function getAxesAndBoxPosition(this)
            % real coordinates of the inserted rectangle
            box1_1 = [this.XLimNew(1, 2), this.YLimNew(1, 2)];
            box1_2 = [this.XLimNew(1, 1), this.YLimNew(1, 2)];
            box1_3 = [this.XLimNew(1, 1), this.YLimNew(1, 1)];
            box1_4 = [this.XLimNew(1, 2), this.YLimNew(1, 1)];
            box1 = [box1_1; box1_2; box1_3; box1_4];
            % real coordinates of the inserted axes
            tmp1 = [this.subAxes.Position(1)+this.subAxes.Position(3),...
                this.subAxes.Position(2)+this.subAxes.Position(4)];
            box2_1 = this.transformCoordinate(tmp1, 'n2a');
            tmp2 = [this.subAxes.Position(1),...
                this.subAxes.Position(2)+this.subAxes.Position(4)];
            box2_2 = this.transformCoordinate(tmp2, 'n2a');
            tmp3 = [this.subAxes.Position(1), this.subAxes.Position(2)];
            box2_3 = this.transformCoordinate(tmp3, 'n2a');
            tmp4 = [this.subAxes.Position(1)+this.subAxes.Position(3),...
                this.subAxes.Position(2)];
            box2_4 = this.transformCoordinate(tmp4, 'n2a');
            box2 = [box2_1; box2_2; box2_3; box2_4];
            this.figureRectangleEdgePosition = box1;
            this.axesPosition = box2;
        end

        function getLineDirection(this)
            % get the line direction
            % left-upper
            if (this.figureRectangleEdgePosition(4, 1) < this.axesPosition(1, 1) &&...
                    this.figureRectangleEdgePosition(4, 2) > this.axesPosition(2, 2))
                this.lineDirection = [3, 3; 1, 1];
            end
            % middle-upper
            if (this.figureRectangleEdgePosition(4, 1) > this.axesPosition(2, 1) &&...
                    this.figureRectangleEdgePosition(4, 2) > this.axesPosition(2, 2)) &&...
                    this.figureRectangleEdgePosition(3, 1) < this.axesPosition(1, 1)
                this.lineDirection = [4, 1; 3, 2];
            end
            % right-upper
            if (this.figureRectangleEdgePosition(3, 1) > this.axesPosition(1, 1) &&...
                    this.figureRectangleEdgePosition(3, 2) > this.axesPosition(1, 2))
                this.lineDirection = [2, 2; 4, 4];
            end
            % right-middle
            if (this.figureRectangleEdgePosition(3, 1) > this.axesPosition(1, 1) &&...
                    this.figureRectangleEdgePosition(3, 2) < this.axesPosition(1, 2)) &&...
                    this.figureRectangleEdgePosition(2, 2) > this.axesPosition(4, 2)
                this.lineDirection = [2, 1; 3, 4];
            end
            % right-down
            if (this.figureRectangleEdgePosition(2, 1) > this.axesPosition(4, 1) &&...
                    this.figureRectangleEdgePosition(2, 2) < this.axesPosition(4, 2))
                this.lineDirection = [1, 1; 3, 3];
            end
            % down-middle
            if (this.figureRectangleEdgePosition(1, 1) > this.axesPosition(3, 1) &&...
                    this.figureRectangleEdgePosition(1, 2) < this.axesPosition(3, 2) &&...
                    this.figureRectangleEdgePosition(2, 1) < this.axesPosition(4, 1))
                this.lineDirection = [2, 3; 1, 4];
            end
            % left-down
            if (this.figureRectangleEdgePosition(1, 1) < this.axesPosition(3, 1) &&...
                    this.figureRectangleEdgePosition(1, 2) < this.axesPosition(3, 2))
                this.lineDirection = [2, 2; 4, 4];
            end
            % left-middle
            if (this.figureRectangleEdgePosition(4, 1) <this.axesPosition(2, 1) &&...
                    this.figureRectangleEdgePosition(4, 2) < this.axesPosition(2, 2)) &&...
                    this.figureRectangleEdgePosition(1, 2) > this.axesPosition(3, 2)
                this.lineDirection = [1, 2; 4, 3];
            end
        end

        function setSubAxesLim(this)
            switch this.YAxis.number
                case 1
                    set(this.subAxes, 'XLim', this.XLimNew, 'YLim', this.YLimNew);
                case 2
                    yyaxis(this.subAxes, this.direction);
                    set(this.subAxes, 'XLim', this.XLimNew, 'YLim', this.YLimNew);
                    yyaxis(this.subAxes, 'left');
                    switch this.YAxis.scale
                        case 'linearlinear'
                            Y_from = this.YLimNew;
                            Y_to(1) = Y_from(1)*this.YAxis.K+this.YAxis.b;
                            Y_to(2) = Y_from(2)*this.YAxis.K+this.YAxis.b;
                        case 'linearlog'
                            Y_from = this.YLimNew;
                            Y_to(1) = 10.^(Y_from(1)*this.YAxis.K+this.YAxis.b);
                            Y_to(2) = 10.^(Y_from(2)*this.YAxis.K+this.YAxis.b);
                        case 'loglinear'
                            Y_from = log10(this.YLimNew);
                            Y_to(1) = Y_from(1)*this.YAxis.K+this.YAxis.b;
                            Y_to(2) = Y_from(2)*this.YAxis.K+this.YAxis.b;
                        case 'loglog'
                            Y_from = log10(this.YLimNew);
                            Y_to(1) = 10.^(Y_from(1)*this.YAxis.K+this.YAxis.b);
                            Y_to(2) = 10.^(Y_from(2)*this.YAxis.K+this.YAxis.b);
                    end
                    set(this.subAxes, 'XLim', this.XLimNew,'YLim', Y_to);
            end
        end

        function mainChildren = getMainChildren(this)
            children_ = get(this.mainAxes, 'children');
            numChildren_ = 1:length(children_);
            for ii = 1:length(children_)
                if strcmp(children_(ii, 1).Type, 'images.roi.rectangle') ||...
                        strcmp(children_(ii, 1).Type, 'hggroup')
                    numChildren_(ii) = [];
                end
            end
            mainChildren = children_(numChildren_);
        end

        function setTheme(this)
            % set the theme of the dynamic rectangle
            switch this.drawFunc
                case 'drawrectangle'
                    try
                        this.roi.MarkerSize = this.param.dynamicRect.MarkerSize;
                    catch
                    end
                    this.roi.Color = this.param.dynamicRect.FaceColor;
                    this.roi.FaceAlpha = this.param.dynamicRect.FaceAspect;
                    this.roi.LineWidth = this.param.dynamicRect.LineWidth;
                case 'imrect'
                    children_ = get(findobj(gca, 'type', 'hggroup'), 'children');
                    % 8 angles
                    for i = [1:4, 6:2:12]
                        children_(i).LineWidth = this.param.dynamicRect.LineWidth*0.6;
                        children_(i).Color = this.param.dynamicRect.LineColor;
                        children_(i).Marker = this.param.dynamicRect.Marker;
                        children_(i).MarkerSize = this.param.dynamicRect.MarkerSize;
                        children_(i).MarkerEdgeColor =this.param.dynamicRect.EdgeColor;
                        children_(i).MarkerFaceColor = this.param.dynamicRect.FaceColor;
                    end
                    % 4 lines
                    for i = 5:2:11
                        children_(i).Color = this.param.dynamicRect.FaceColor;
                        children_(i).LineWidth = this.param.dynamicRect.LineWidth;
                        children_(i).Marker = 'none';
                    end
                    % dynamic rectangle
                    children_(13).FaceAlpha = this.param.dynamicRect.FaceAspect;
                    children_(13).FaceColor = this.param.dynamicRect.FaceColor;
            end
        end

        function coordinate = transformCoordinate(this, coordinate, type)
            % coordinate transformation
            switch type
                % absolute coordinates to normalized coordinates
                case 'a2n'
                    switch this.XAxis.scale
                        case 'linear'
                            coordinate(1, 1) = (coordinate(1, 1)-this.mappingParams(1, 2))...
                                /this.mappingParams(1, 1);
                        case 'log'
                            coordinate(1, 1) = (log10(coordinate(1, 1))-this.mappingParams(1, 2))...
                                /this.mappingParams(1, 1);
                    end

                    switch this.YAxis.(this.direction).scale
                        case 'linear'
                            coordinate(1, 2) = (coordinate(1, 2)-this.mappingParams(2, 2))...
                                /this.mappingParams(2, 1);
                        case 'log'
                            coordinate(1, 2) = (log10(coordinate(1, 2))-this.mappingParams(2, 2))...
                                /this.mappingParams(2, 1);
                    end
                    % normalized coordinates to absolute coordinates
                case 'n2a'
                    switch this.XAxis.scale
                        case 'linear'
                            coordinate(1, 1) = coordinate(1, 1)*this.mappingParams(1, 1)...
                                +this.mappingParams(1, 2);
                        case 'log'
                            coordinate(1, 1) = 10^(coordinate(1, 1)*this.mappingParams(1, 1)...
                                +this.mappingParams(1, 2));
                    end
                    switch this.YAxis.(this.direction).scale
                        case 'linear'
                            coordinate(1, 2) = coordinate(1, 2)*this.mappingParams(2, 1)...
                                +this.mappingParams(2, 2);
                        case 'log'
                            coordinate(1, 2) = 10^(coordinate(1, 2)*this.mappingParams(2, 1)...
                                +this.mappingParams(2, 2));
                    end
            end
        end

        % dependent properties
        function dynamicPosition = get.dynamicPosition(this)
            switch this.drawFunc
                case 'drawrectangle'
                    dynamicPosition = this.roi.Position;
                case 'imrect'
                    dynamicPosition = getPosition(this.roi);
            end
        end

        % dependent properties
        function XLimNew = get.XLimNew(this)
            XLimNew = [this.dynamicPosition(1), this.dynamicPosition(1)+this.dynamicPosition(3)];
        end

        % dependent properties
        function YLimNew = get.YLimNew(this)
            YLimNew = [this.dynamicPosition(2), this.dynamicPosition(2)+this.dynamicPosition(4)];
        end

        % dependent properties
        function affinePosition = get.affinePosition(this)
            this.mappingParams = this.computeMappingParams;
            tmp1 = this.transformCoordinate([this.XLimNew(1, 1), this.YLimNew(1, 1)], 'a2n');
            tmp2 = this.transformCoordinate([this.XLimNew(1, 2), this.YLimNew(1, 2)], 'a2n');
            affinePosition(1, 1) = tmp1(1, 1);
            affinePosition(1, 2) = tmp1(1, 2);
            affinePosition(1, 3) = tmp2(1, 1)-tmp1(1, 1);
            affinePosition(1, 4) = tmp2(1, 2)-tmp1(1, 2);
        end

        % dependent properties
        function newCData_ = get.newCData_(this)
            switch this.drawFunc
                case 'drawrectangle'
                    Position_ = this.roi.Position;
                case 'imrect'
                    Position_ = getPosition(this.roi);
            end
            newCData_ = imcrop(this.CData_,this.Colormap_, Position_);
        end

        % dependent properties
        function newCData = get.newCData(this)
            switch this.imageDim
                case 2
                    [newCData, ~] = imresize(this.newCData_, this.Colormap_, [this.vPixels, this.uPixels]);
                    %  [~, newCMap] = imresize(this.newCData_, this.newCMap_, [this.vPixels, this.uPixels]);
                case 3
                    newCData = imresize(this.newCData_, [this.vPixels, this.uPixels]);
            end
        end

        % dependent properties
        function newCMap = get.newCMap(this)
            switch this.imageDim
                case 2
                    [~, newCMap] = imresize(this.newCData_, this.Colormap_, [this.vPixels, this.uPixels]);
                case 3
                    newCMap=[];
            end
        end
    end
end