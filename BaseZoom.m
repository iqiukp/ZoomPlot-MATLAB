classdef BaseZoom < handle
    %{
        CLASS DESCRIPTION

        Interactive Magnification of the customized regions.
    
    -----------------------------------------------------------------
    
        Version 1.2, 5-OCT-2021
        Email: iqiukp@outlook.com
    -----------------------------------------------------------------
    %} 
    
    properties
        %
        mainAxes
        subAxes
        rectangle
        drawFunc
        roi
        mappingParams
        rectanglePosition
        axesPosition
        lineDirection
        axesDone = 'off'
        rectangleDone = 'off'
        pauseTime = 0.2
        display = 'on'
    end

    properties
        % theme of inserted axes (sub-axes)
        subAxesBox = 'on'
        subAxesinsertedLineWidth = 1.2
        subAxesTickDirection = 'in'
        subAxesBackgroundColor = 'none'
    end

    properties
        % theme of the inserted rectangle (zoom zone)
        rectangleColor = 'k'
        rectangleFaceColor = 'none'
        rectangleFaceAlpha = 0
        rectangleLineStyle = '-'
        rectangleLineWidth = 1.2
        rectangleInteractionsAllowed = 'none'
    end

    properties
        % theme of the connected lines
        connectedLineStyle = ':'
        connectedLineColor = 'k'
        connectedLineWidth = 2
        connectedLineHeadStyle = 'ellipse'
        connectedLineHeadSize = 3
    end

    properties(Constant)
        % theme of the dynamic rectangle
        dynamicRectFaceColor = [0, 114, 189]/255
        dynamicRectFaceAspect = 0.2
        dynamicRectFacAngleMarker = 's'
        dynamicRectFacAngleMarkerSize = 12
        dynamicRectLineWidth = 2.5
        dynamicRectLineColor = [0, 114, 189]/255
    end

    properties(Dependent)
        XLimNew
        YLimNew
        affinePosition
        dynamicPosition
    end

    methods
        function plot(obj)
            % main steps
            obj.checkVersion;
            obj.mainAxes = gca;
            fprintf('Use the left mouse botton to draw a rectangle\n')
            fprintf('for the sub-coordinate system...\n')
            obj.insertSubAxes;
            fprintf('Use the left mouse button to draw a rectangle\n')
            fprintf('for the magnification zone...\n')
            obj.insertRectangle;
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

        function insertRectangle(obj)
            % insert an rectangle
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
                    addNewPositionCallback(obj.roi, @obj.allEventsForRectangleOld);
                    set(gcf, 'WindowButtonDownFcn', @obj.clickEventForRectangle);
                    wait(obj.roi);
                    while strcmp(obj.axesDone, 'off')
                        pause(obj.pauseTime)
                    end
            end
        end

        function allEventsForSubAxesOld(obj, ~)
            % callback funcion for inserted subAxes when using 'imrect'
            if strcmp(obj.display, 'on')
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
                if strcmp(obj.display, 'on')
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
                    if strcmp(obj.display, 'on')
                        fprintf('Inserted subAxes adjustment is done.\n\n')
                    end
                    delete(obj.roi);
                    obj.subAxes.Color = obj.subAxesBackgroundColor;
                % left-click
                case 'normal'
                    obj.axesDone = 'off';
                    if strcmp(obj.display, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
                    obj.subAxes.Color = obj.subAxesBackgroundColor;
                otherwise
                    obj.axesDone = 'off';
                    if strcmp(obj.display, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
                    obj.subAxes.Color = obj.subAxesBackgroundColor;
            end
        end

        function allEventsForRectangleOld(obj, ~)
            % callback funcion for inserted rectangle when using 'imrect'
            fprintf('adjust the inserted rectangle...\n')
            delete(findall(gcf, 'Tag', 'justForZoomPlot'))
            if strcmp(obj.subAxesBox, 'on')
                obj.connectAxesAndBox;
            end
            set(obj.subAxes, 'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
        end

        function allEventsForRectangleNew(obj, ~, evt)
            % callback funcion for inserted rectangle when using 'drawrectangle'
            eventName = evt.EventName;
            if ismember(eventName, {'MovingROI', 'ROIMoved'})
                if strcmp(obj.display, 'on')
                    fprintf('adjust the inserted rectangle...\n')
                end
                delete(findall(gcf, 'Tag', 'justForZoomPlot'))
                if strcmp(obj.subAxesBox, 'on')
                    obj.connectAxesAndBox;
                end
                set(obj.subAxes,'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
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
                    if strcmp(obj.display, 'on')
                        fprintf('Inserted rectangle adjustment is done.\n\n')
                    end
                % left-click
                case 'normal'
                    obj.rectangleDone = 'off';
                    if strcmp(obj.display, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
                otherwise
                    obj.rectangleDone = 'off';
                    if strcmp(obj.display, 'on')
                        fprintf('Right-click to stop adjusting.\n')
                    end
            end
        end

        function creatSubAxes(obj)
            % creat sub-axes
            obj.subAxes = axes('Position', obj.affinePosition);
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
                'YLim', get(obj.mainAxes, 'YLim'));
            set(obj.subAxes, 'Visible', 'off');
        end

        function creatRectangle(obj)
            % creat rectangle
            obj.rectangle = annotation('rectangle', obj.affinePosition,...
                'LineWidth', obj.rectangleLineWidth,...
                'LineStyle', obj.rectangleLineStyle,...
                'FaceAlpha', obj.rectangleFaceAlpha,...
                'FaceColor', obj.rectangleFaceColor,...
                'Color', obj.rectangleColor);
        end

        function mappingParams = computeMappingParams(obj)
            % compute the mapping parameters
            map_k_x = range(obj.mainAxes.XLim)/obj.mainAxes.Position(3);
            map_b_x = obj.mainAxes.XLim(1)-obj.mainAxes.Position(1)*map_k_x;
            map_k_y = range(obj.mainAxes.YLim)/obj.mainAxes.Position(4);
            map_b_y = obj.mainAxes.YLim(1)-obj.mainAxes.Position(2)*map_k_y;
            mappingParams = [map_k_x, map_b_x; map_k_y, map_b_y];
        end

        function connectAxesAndBox(obj)
            % insert lines between the inserted axes and rectangle

            %   Rectangle        subAxes
            %    2----1          2----1
            %    3----4          3----4

            % real coordinates of the inserted rectangle and axes
            obj.getAxesAndBoxPosition;
            % get the line direction
            obj.getLineDirection;
            % insert lines
            numLine = size(obj.lineDirection, 1);
            for i = 1:numLine
                tmp1 = [obj.rectanglePosition(obj.lineDirection(i, 1), 1),...
                    obj.rectanglePosition(obj.lineDirection(i, 1), 2)];
                tmp2 = [obj.axesPosition(obj.lineDirection(i, 2), 1),...
                    obj.axesPosition(obj.lineDirection(i, 2), 2)];
                pos1 = obj.transformCoordinate(tmp1, 'a2n');
                pos2 = obj.transformCoordinate(tmp2, 'a2n');
                annotation(gcf, 'doublearrow',...
                    [pos1(1, 1), pos2(1, 1)], [pos1(1, 2), pos2(1, 2)],...
                    'Color', obj.connectedLineColor,...
                    'LineStyle', obj.connectedLineStyle,...
                    'Head1Style', obj.connectedLineHeadStyle,...
                    'Head2Style', obj.connectedLineHeadStyle,...
                    'Head1Length', obj.connectedLineHeadSize,...
                    'Head1Width', obj.connectedLineHeadSize,...
                    'Head2Length', obj.connectedLineHeadSize,...
                    'Head2Width', obj.connectedLineHeadSize,...
                    'Tag', 'justForZoomPlot');
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
            obj.rectanglePosition = box1;
            obj.axesPosition = box2;
        end

        function getLineDirection(obj)
            % get the line direction
            % left-upper
            if (obj.rectanglePosition(4, 1) < obj.axesPosition(1, 1) &&...
                    obj.rectanglePosition(4, 2) > obj.axesPosition(2, 2))
                obj.lineDirection = [3, 3; 1, 1];
            end
            % middle-upper
            if (obj.rectanglePosition(4, 1) > obj.axesPosition(2, 1) &&...
                    obj.rectanglePosition(4, 2) > obj.axesPosition(2, 2)) &&...
                    obj.rectanglePosition(3, 1) < obj.axesPosition(1, 1)
                obj.lineDirection = [4, 1; 3, 2];
            end
            % right-upper
            if (obj.rectanglePosition(3, 1) > obj.axesPosition(1, 1) &&...
                    obj.rectanglePosition(3, 2) > obj.axesPosition(1, 2))
                obj.lineDirection = [2, 2; 4, 4];
            end
            % right-middle
            if (obj.rectanglePosition(3, 1) > obj.axesPosition(1, 1) &&...
                    obj.rectanglePosition(3, 2) < obj.axesPosition(1, 2)) &&...
                    obj.rectanglePosition(2, 2) > obj.axesPosition(4, 2)
                obj.lineDirection = [2, 1; 3, 4];
            end
            % right-down
            if (obj.rectanglePosition(2, 1) > obj.axesPosition(4, 1) &&...
                    obj.rectanglePosition(2, 2) < obj.axesPosition(4, 2))
                obj.lineDirection = [1, 1; 3, 3];
            end
            % down-middle
            if (obj.rectanglePosition(1, 1) > obj.axesPosition(3, 1) &&...
                    obj.rectanglePosition(1, 2) < obj.axesPosition(3, 2) &&...
                    obj.rectanglePosition(2, 1) < obj.axesPosition(4, 1))
                obj.lineDirection = [2, 3; 1, 4];
            end
            % left-down
            if (obj.rectanglePosition(1, 1) < obj.axesPosition(3, 1) &&...
                    obj.rectanglePosition(1, 2) < obj.axesPosition(3, 2))
                obj.lineDirection = [2, 2; 4, 4];
            end
            % left-middle
            if (obj.rectanglePosition(4, 1) <obj.axesPosition(2, 1) &&...
                    obj.rectanglePosition(4, 2) < obj.axesPosition(2, 2)) &&...
                    obj.rectanglePosition(1, 2) > obj.axesPosition(3, 2)
                obj.lineDirection = [1, 2; 4, 3];
            end
        end

        function setTheme(obj)
            % set the theme of the dynamic rectangle
            switch obj.drawFunc
                case 'drawrectangle'
                    obj.roi.MarkerSize = obj.dynamicRectFacAngleMarkerSize;
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
                    coordinate(1, 1) = (coordinate(1, 1)-obj.mappingParams(1, 2))...
                        /obj.mappingParams(1, 1);
                    coordinate(1, 2) = (coordinate(1, 2)-obj.mappingParams(2, 2))...
                        /obj.mappingParams(2, 1);
                % normalized coordinates to absolute coordinates
                case 'n2a'
                    coordinate(1, 1) = coordinate(1, 1)*obj.mappingParams(1, 1)...
                        +obj.mappingParams(1, 2);
                    coordinate(1, 2) = coordinate(1, 2)*obj.mappingParams(2, 1)...
                        +obj.mappingParams(2, 2);
            end
        end

        function dynamicPosition = get.dynamicPosition(obj)
            switch obj.drawFunc
                case 'drawrectangle'
                    dynamicPosition = obj.roi.Position;
                case 'imrect'
                    dynamicPosition = getPosition(obj.roi);
            end
        end

        function XLimNew = get.XLimNew(obj)
            XLimNew = [obj.dynamicPosition(1), obj.dynamicPosition(1)+obj.dynamicPosition(3)];
        end

        function YLimNew = get.YLimNew(obj)
            YLimNew = [obj.dynamicPosition(2), obj.dynamicPosition(2)+obj.dynamicPosition(4)];
        end

        function affinePosition = get.affinePosition(obj)
            obj.mappingParams = obj.computeMappingParams;
            tmp1 = obj.transformCoordinate([obj.XLimNew(1, 1), obj.YLimNew(1, 1)], 'a2n');
            tmp2 = obj.transformCoordinate([obj.XLimNew(1, 2), obj.YLimNew(1, 2)], 'a2n');
            affinePosition(1, 1) = tmp1(1, 1);
            affinePosition(1, 2) = tmp1(1, 2);
            affinePosition(1, 3) = tmp2(1, 1)-tmp1(1, 1);
            affinePosition(1, 4) = tmp2(1, 2)-tmp1(1, 2);
        end
    end
end