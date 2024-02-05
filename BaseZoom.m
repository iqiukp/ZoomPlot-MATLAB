classdef BaseZoom < handle
    %{

        Interactive Magnification of Customized Regions.

        Email: iqiukp@outlook.com
    
        -------------------------------------------------------------

        Version 1.5.1, 5-FEB-2024
            -- Support for zoom of a specified Axes object.
            -- Support setting the number of connection lines.
            -- Support for manual mode.
            -- Fixed minor bugs.

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
        Copyright (c) 2024, Kepeng Qiu
        All rights reserved.
        
    %}

    % main  properties
    properties
        axesObject
        subAxesPosition = [];
        zoomAreaPosition = [];
        zoomMode = 'interaction';
        subFigure
        mainAxes
        subAxes
        roi
        zoomedArea
        parameters
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
        axesClassName
        isAxesDrawn = 'off'
        isRectangleDrawn = 'off'
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

        function this = BaseZoom(varargin)
            % Check MATLAB version compatibility
            if verLessThan('matlab', '9.5') % MATLAB 2018b version is 9.5
                error('BaseZoom:IncompatibleVersion', 'Please use BaseZoom version 1.4 or below for your MATLAB version.');
            end

            switch nargin
                case 0 % No input arguments
                    this.axesObject = gca;
                    this.zoomMode = 'interaction';
                    this.textDisplay = 'on';

                case 1 % One input argument
                    this.axesObject = varargin{1};
                    if ~isa(this.axesObject, 'matlab.graphics.axis.Axes')
                        error('Input must be an Axes object.');
                    end
                    this.zoomMode = 'interaction';
                    this.textDisplay = 'on';
                    % Check if the object is an image or figure
                    if ~isempty(imhandles(this.axesObject))
                        this.axesClassName = 'image';
                    else
                        this.axesClassName = 'figure';
                    end
                case 2 % Two input arguments
                    % Check if the first input argument is an Axes object or a position vector
                    if isa(varargin{1}, 'matlab.graphics.axis.Axes')
                        this.axesObject = varargin{1};
                        if ~isempty(imhandles(this.axesObject))
                            % The object is an image
                            if ~all(isnumeric(varargin{2}) & numel(varargin{2}) == 4)
                                error('The second input must be a numeric 4-element vector representing zoomAreaPosition.');
                            end
                            this.zoomAreaPosition = varargin{2};
                            this.zoomMode = 'manual';
                            this.textDisplay = 'off';
                        else
                            error('For two inputs, if the first input is an Axes object, it must be associated with an image.');
                        end
                    elseif all(isnumeric(varargin{1}) & numel(varargin{1}) == 4)
                        this.subAxesPosition = varargin{1};
                        this.zoomAreaPosition = varargin{2};
                        this.axesObject = gca;
                        if ~isempty(imhandles(this.axesObject))
                            error('For two numeric inputs, the current Axes must not be associated with an image.');
                        end
                        this.zoomMode = 'manual';
                        this.textDisplay = 'off';
                    else
                        error('For two inputs, the first input must be either an Axes object associated with an image or a numeric 4-element vector representing subAxesPosition.');
                    end

                case 3 % Three input arguments
                    this.axesObject = varargin{1};
                    this.subAxesPosition = varargin{2};
                    this.zoomAreaPosition = varargin{3};
                    if ~isa(this.axesObject, 'matlab.graphics.axis.Axes')
                        error('The first input must be an Axes object.');
                    end
                    if ~isempty(imhandles(this.axesObject))
                        error('For three inputs, the Axes object must not be associated with an image.');
                    end
                    if ~(all(isnumeric(this.subAxesPosition) & numel(this.subAxesPosition) == 4) && ...
                            all(isnumeric(this.zoomAreaPosition) & numel(this.zoomAreaPosition) == 4))
                        error('The second and third inputs must be numeric 4-element vectors representing subAxesPosition and zoomAreaPosition, respectively.');
                    end
                    this.zoomMode = 'manual';
                    this.textDisplay = 'off';

                otherwise
                    error(['Invalid number of input arguments. ',...
                        'For two inputs, provide either subAxesPosition and zoomAreaPosition, or an Axes object and zoomAreaPosition. ',...
                        'For three inputs, provide an Axes object, subAxesPosition, and zoomAreaPosition.']);
            end
            this.initialize;
            this.loadParameters;
        end

        function run(this)
            % main steps
            switch this.axesClassName
                case 'image'
                    this.addSubAxes;
                    this.isAxesDrawn = 'off';
                    this.displayZoomInstructions();
                    this.addZoomedArea;
                    this.isRectangleDrawn = 'off';
                case 'figure'
                    this.displaySubAxesInstructions();
                    this.addSubAxes;
                    this.isAxesDrawn = 'off';
                    this.displayZoomInstructions();
                    this.addZoomedArea;
                    this.isRectangleDrawn = 'off';
            end
        end

        function loadParameters(this)
            fileName = 'parameters.json';
            fid = fopen(fileName);
            raw = fread(fid,inf);
            str = char(raw');
            fclose(fid);
            this.parameters = jsondecode(str);
            names_ = fieldnames(this.parameters);
            for i = 1:length(names_)
                if isfield(this.parameters.(names_{i}), 'Comments')
                    this.parameters.(names_{i}) = rmfield(this.parameters.(names_{i}), 'Comments');
                end
            end
        end

        function initialize(this)
            this.mainAxes = this.axesObject;
            if size(imhandles(this.mainAxes),1) ~= 0
                this.axesClassName = 'image';
                this.CData_ = get(this.mainAxes.Children, 'CData');
                this.Colormap_ = colormap(gca);
                if size(this.Colormap_, 1) == 64
                    this.Colormap_ = colormap(gcf);
                end
                [this.vPixels, this.uPixels, ~] = size(this.CData_);
                this.vuRatio = this.vPixels/this.uPixels;
                this.imageDim = length(size(this.CData_));
            else
                this.axesClassName = 'figure';
            end

            if strcmp(this.axesClassName, 'figure')
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
            end
        end

        function addSubAxes(this)
            switch this.axesClassName
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
                    if strcmp(this.zoomMode, 'interaction')
                        this.roi = drawrectangle(this.mainAxes, 'Label', 'SubAxes');
                        this.setTheme;
                        this.creatSubAxes;
                        set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'subAxes'});
                        addlistener(this.roi, 'MovingROI', @(source, event) ...
                            this.allEvents(source, event, 'subAxes'));
                        addlistener(this.roi, 'ROIMoved', @(source, event) ...
                            this.allEvents(source, event, 'subAxes'));
                        while strcmp(this.isAxesDrawn, 'off')
                            pause(this.pauseTime);
                        end
                    else
                        this.roi = drawrectangle(this.mainAxes,...
                            'Position', this.subAxesPosition, 'Label', 'SubAxes');
                        this.creatSubAxes;
                        delete(this.roi);
                        set(this.subAxes, 'Visible', 'on')
                        this.isAxesDrawn = 'on';
                    end
                    % this.subAxes.Color = this.mainAxes.Color;
            end
        end

        function addZoomedArea(this)
            switch this.axesClassName
                case 'image'
                    if strcmp(this.zoomMode, 'interaction')
                        this.roi = drawrectangle(this.mainAxes, 'Label', 'ZoomArea');
                        this.setTheme;
                        this.creatSubAxes;
                        if strcmp(this.parameters.subAxes.Box, 'on')
                            this.connectAxesAndBox;
                        end
                        set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'zoomedArea'});
                        addlistener(this.roi, 'MovingROI', @(source, event) ...
                            this.allEvents(source, event, 'zoomedArea'));
                        addlistener(this.roi, 'ROIMoved', @(source, event) ...
                            this.allEvents(source, event, 'zoomedArea'));
                        while strcmp(this.isRectangleDrawn, 'off')
                            pause(this.pauseTime);
                        end
                    else

                        this.roi = drawrectangle(this.mainAxes,...
                            'Position', this.zoomAreaPosition, 'Label', 'zoomArea');
                        this.setTheme;
                        if strcmp(this.parameters.subAxes.Box, 'on')
                            this.connectAxesAndBox;
                        end
                        this.creatSubAxes;
                        this.isRectangleDrawn = 'on';
                        this.createRectangle;
                        delete(this.roi);
                    end
                    for iArrow = 1:length(this.imageArrow)
                        this.imageArrow{iArrow}.Tag = 'ZoomPlot';
                    end

                case 'figure' %
                    if strcmp(this.zoomMode, 'interaction')
                        this.roi = drawrectangle(this.mainAxes, 'Label', 'zoomArea');
                        this.setTheme;
                        if strcmp(this.parameters.subAxes.Box, 'on')
                            this.connectAxesAndBox;
                        end
                        this.setSubAxesLim;
                        set(gcf, 'WindowButtonDownFcn', {@this.clickEvents, 'zoomedArea'});
                        addlistener(this.roi, 'MovingROI', @(source, event) ...
                            this.allEvents(source, event, 'zoomedArea'));
                        addlistener(this.roi, 'ROIMoved', @(source, event) ...
                            this.allEvents(source, event, 'zoomedArea'));
                        while strcmp(this.isRectangleDrawn, 'off')
                            pause(this.pauseTime);
                        end
                    else
                        this.roi = drawrectangle(this.mainAxes,...
                            'Position', this.zoomAreaPosition, 'Label', 'zoomArea');
                        this.setTheme;
                        if strcmp(this.parameters.subAxes.Box, 'on')
                            this.connectAxesAndBox;
                        end
                        this.setSubAxesLim;
                        this.isRectangleDrawn = 'on';
                        this.createRectangle;
                        delete(this.roi);
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
                    this.subAxes.Color = this.parameters.subAxes.Color;
                case 'zoomedArea'
                    if strcmp(this.textDisplay, 'on')
                        fprintf('adjust the zoomed area...\n')
                    end
                    delete(findall(gcf, 'Tag', 'ZoomPlot_'))
                    if strcmp(this.parameters.subAxes.Box, 'on')
                        this.connectAxesAndBox;
                    end
                    switch this.axesClassName
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
                            this.isAxesDrawn = 'on';
                            set(this.subAxes, 'Visible', 'on');
                            set(gcf, 'WindowButtonDownFcn', []);
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Complete the adjustment of the sub axes.\n\n');
                            end
                            delete(this.roi);
                            this.subAxes.Color = this.parameters.subAxes.Color;

                        case 'normal'
                            this.isAxesDrawn = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                            this.subAxes.Color = this.parameters.subAxes.Color;

                        otherwise
                            this.isAxesDrawn = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                            this.subAxes.Color = this.parameters.subAxes.Color;
                    end

                case 'zoomedArea'
                    switch get(gcf, 'SelectionType')
                        case 'alt'
                            this.isRectangleDrawn = 'on';
                            this.createRectangle;
                            set(gcf, 'WindowButtonDownFcn', []);
                            delete(this.roi);
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Complete the adjustment of the zoomed area.\n\n');
                            end
                        case 'normal'
                            this.isRectangleDrawn = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                        otherwise
                            this.isRectangleDrawn = 'off';
                            if strcmp(this.textDisplay, 'on')
                                fprintf('Right-click to stop adjusting.\n');
                            end
                    end
            end
        end

        function creatSubAxes(this)
            switch this.axesClassName
                case 'image'
                    set(this.subAxes.Children, 'CData', this.newCData);
                    if this.imageDim == 2
                        colormap(this.subAxes, this.newCMap);
                    end
                case 'figure'
                    if this.YAxis.number == 1
                        this.subAxes = axes('Position', this.affinePosition,...
                            'XScale', this.XAxis.scale,...
                            'YScale', this.YAxis.(this.direction).scale,...
                            'parent', get(this.mainAxes, 'Parent'));
                        mainChildren = this.getMainChildren;
                        copyobj(mainChildren, this.subAxes);
                        this.subAxes.XLim = this.mainAxes.XLim;
                        hold(this.subAxes, 'on');
                        set(this.subAxes, this.parameters.subAxes);
                        set(this.subAxes, 'Visible', 'off');
                    end
                    if this.YAxis.number == 2
                        diret_ = this.YAxis.direction;
                        this.subAxes = axes('Position', this.affinePosition, 'parent', get(this.mainAxes, 'Parent'));
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
                        set(this.subAxes, this.parameters.subAxes);
                        set(this.subAxes, 'Visible', 'off');
                    end
            end
        end

        function createRectangle(this)
            % Determine rectangle position based on axes class
            switch this.axesClassName
                case 'image'
                    position = this.imageRectangleEdgePosition;
                case 'figure'
                    position = this.affinePosition;
            end

            % Create the rectangle annotation with common properties
            this.zoomedArea = annotation('rectangle', position, ...
                'Color', this.parameters.zoomedArea.Color, ...
                'FaceColor', this.parameters.zoomedArea.FaceColor, ...
                'FaceAlpha', this.parameters.zoomedArea.FaceAlpha, ...
                'LineStyle', this.parameters.zoomedArea.LineStyle, ...
                'LineWidth', this.parameters.zoomedArea.LineWidth);
        end

        function mappingParams = computeMappingParams(this)
            % Compute the mapping parameters for both axes
            [map_k_x, map_b_x] = this.computeAxisMappingParams(this.XAxis.scale, ...
                this.mainAxes.XLim, ...
                this.mainAxes.Position(1), ...
                this.mainAxes.Position(3));
            [map_k_y, map_b_y] = this.computeAxisMappingParams(this.YAxis.(this.direction).scale, ...
                this.mainAxes.YLim, ...
                this.mainAxes.Position(2), ...
                this.mainAxes.Position(4));
            % Construct the mapping parameters matrix
            mappingParams = [map_k_x, map_b_x; map_k_y, map_b_y];
        end

        function [map_k, map_b] = computeAxisMappingParams(~, scale, axesLim, pos, size)
            % Compute mapping parameters based on the scale (linear or log)
            switch scale
                case 'linear'
                    rangeLim = axesLim(2) - axesLim(1);
                case 'log'
                    rangeLim = log10(axesLim(2)) - log10(axesLim(1));
                otherwise
                    error('BaseZoom:InvalidScale', 'Unsupported axis scale.');
            end
            % Compute the scale factor and offset for mapping
            map_k = rangeLim / size;
            switch scale
                case 'linear'
                    map_b = axesLim(1) - pos * map_k;
                case 'log'
                    map_b = log10(axesLim(1)) - pos * map_k;
            end
        end

        function connectAxesAndBox(this)
            % insert lines between the inserted axes and rectangle

            %   Rectangle        subAxes
            %    2----1          2----1
            %    3----4          3----4
            switch this.axesClassName
                case 'image' %
                    uPixelsAll = this.uPixels/this.mainAxes.Position(3);
                    vPixelsAll = this.vPixels/this.mainAxes.Position(4);
                    Position_ = this.roi.Position;
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
                        'Color', this.parameters.connection.LineColor,...
                        'LineWidth', this.parameters.connection.LineWidth,...
                        'LineStyle', this.parameters.connection.LineStyle,...
                        'Head1Style', this.parameters.connection.StartHeadStyle,...
                        'Head1Length', this.parameters.connection.StartHeadLength,...
                        'Head1Width', this.parameters.connection.StartHeadWidth,...
                        'Head2Style', this.parameters.connection.EndHeadStyle,...
                        'Head2Length', this.parameters.connection.EndHeadLength,...
                        'Head2Width', this.parameters.connection.EndHeadWidth,...
                        'Tag', 'ZoomPlot_');
                    % annotation position 2
                    annotationPosX_2(1) = this.imageRectangleEdgePosition(1)+this.imageRectangleEdgePosition(3);
                    annotationPosX_2(2) = this.subAxes.Position(1);
                    annotationPosY_2(1) = this.imageRectangleEdgePosition(2)+this.imageRectangleEdgePosition(4);
                    annotationPosY_2(2) = this.subAxes.Position(2)+this.subAxes.Position(4);
                    this.imageArrow{2} = annotation(gcf, 'doublearrow',...
                        annotationPosX_2, annotationPosY_2,...
                        'Color', this.parameters.connection.LineColor,...
                        'LineWidth', this.parameters.connection.LineWidth,...
                        'LineStyle', this.parameters.connection.LineStyle,...
                        'Head1Style', this.parameters.connection.StartHeadStyle,...
                        'Head1Length', this.parameters.connection.StartHeadLength,...
                        'Head1Width', this.parameters.connection.StartHeadWidth,...
                        'Head2Style', this.parameters.connection.EndHeadStyle,...
                        'Head2Length', this.parameters.connection.EndHeadLength,...
                        'Head2Width', this.parameters.connection.EndHeadWidth,...
                        'Tag', 'ZoomPlot_');
                case 'figure'
                    % real coordinates of the inserted rectangle and axes
                    this.getAxesAndBoxPosition;
                    % get the line direction
                    this.getLineDirection;
                    % insert lines
                    % numLine = size(this.lineDirection, 1);
                    switch this.parameters.connection.LineNumber
                        case 0

                        case 1
                            lineDirection_ = this.lineDirection(end, :);
                        case 2
                            lineDirection_ = this.lineDirection(1:2, :);
                        otherwise
                            error('The LineNumber must be 0 or 1 or 2.')
                    end

                    for i = 1:this.parameters.connection.LineNumber
                        tmp1 = [this.figureRectangleEdgePosition(lineDirection_(i, 1), 1),...
                            this.figureRectangleEdgePosition(lineDirection_(i, 1), 2)];
                        tmp2 = [this.axesPosition(lineDirection_(i, 2), 1),...
                            this.axesPosition(lineDirection_(i, 2), 2)];
                        pos1 = this.transformCoordinate(tmp1, 'a2n');
                        pos2 = this.transformCoordinate(tmp2, 'a2n');
                        this.figureArrow{i} = annotation(gcf, 'doublearrow',...
                            [pos1(1, 1), pos2(1, 1)], [pos1(1, 2), pos2(1, 2)],...
                            'Color', this.parameters.connection.LineColor,...
                            'LineWidth', this.parameters.connection.LineWidth,...
                            'LineStyle', this.parameters.connection.LineStyle,...
                            'Head1Style', this.parameters.connection.StartHeadStyle,...
                            'Head1Length', this.parameters.connection.StartHeadLength,...
                            'Head1Width', this.parameters.connection.StartHeadWidth,...
                            'Head2Style', this.parameters.connection.EndHeadStyle,...
                            'Head2Length', this.parameters.connection.EndHeadLength,...
                            'Head2Width', this.parameters.connection.EndHeadWidth,...
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
                this.lineDirection = [3, 3; 1, 1; 4, 2];
            end
            % middle-upper
            if (this.figureRectangleEdgePosition(4, 1) > this.axesPosition(2, 1) &&...
                    this.figureRectangleEdgePosition(4, 2) > this.axesPosition(2, 2)) &&...
                    this.figureRectangleEdgePosition(3, 1) < this.axesPosition(1, 1)
                this.lineDirection = [4, 1; 3, 2; 4 ,1];
            end
            % right-upper
            if (this.figureRectangleEdgePosition(3, 1) > this.axesPosition(1, 1) &&...
                    this.figureRectangleEdgePosition(3, 2) > this.axesPosition(1, 2))
                this.lineDirection = [2, 2; 4, 4; 3, 1];
            end
            % right-middle
            if (this.figureRectangleEdgePosition(3, 1) > this.axesPosition(1, 1) &&...
                    this.figureRectangleEdgePosition(3, 2) < this.axesPosition(1, 2)) &&...
                    this.figureRectangleEdgePosition(2, 2) > this.axesPosition(4, 2)
                this.lineDirection = [2, 1; 3, 4; 3, 1];
            end
            % right-down
            if (this.figureRectangleEdgePosition(2, 1) > this.axesPosition(4, 1) &&...
                    this.figureRectangleEdgePosition(2, 2) < this.axesPosition(4, 2))
                this.lineDirection = [1, 1; 3, 3; 4, 2];
            end
            % down-middle
            if (this.figureRectangleEdgePosition(1, 1) > this.axesPosition(3, 1) &&...
                    this.figureRectangleEdgePosition(1, 2) < this.axesPosition(3, 2) &&...
                    this.figureRectangleEdgePosition(2, 1) < this.axesPosition(4, 1))
                this.lineDirection = [2, 3; 1, 4; 2, 4];
            end
            % left-down
            if (this.figureRectangleEdgePosition(1, 1) < this.axesPosition(3, 1) &&...
                    this.figureRectangleEdgePosition(1, 2) < this.axesPosition(3, 2))
                this.lineDirection = [2, 2; 4, 4; 3, 1];
            end
            % left-middle
            if (this.figureRectangleEdgePosition(4, 1) <this.axesPosition(2, 1) &&...
                    this.figureRectangleEdgePosition(4, 2) < this.axesPosition(2, 2)) &&...
                    this.figureRectangleEdgePosition(1, 2) > this.axesPosition(3, 2)
                this.lineDirection = [1, 2; 4, 3; 1, 3];
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
            try
                this.roi.MarkerSize = this.parameters.dynamicRect.MarkerSize;
            catch
            end
            this.roi.Color = this.parameters.dynamicRect.FaceColor;
            this.roi.FaceAlpha = this.parameters.dynamicRect.FaceAspect;
            this.roi.LineWidth = this.parameters.dynamicRect.LineWidth;
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

        function throwError(~, message)
            error('BaseZoom:InvalidInput', message);
        end

        function displaySubAxesInstructions(this)
            if strcmp(this.textDisplay, 'on')
                fprintf('Use the left mouse button to draw a rectangle.\n');
                fprintf('for the sub axes...\n');
            end
        end

        function displayZoomInstructions(this)
            if strcmp(this.textDisplay, 'on')
                fprintf('Use the left mouse button to draw a rectangle.\n');
                fprintf('for the zoomed area...\n');
            end
        end

        % dependent properties
        function dynamicPosition = get.dynamicPosition(this)
            dynamicPosition = this.roi.Position;
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
            newCData_ = imcrop(this.CData_,this.Colormap_, this.roi.Position);
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