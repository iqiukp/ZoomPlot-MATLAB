classdef BaseZoom < handle
    %{
        CLASS DESCRIPTION

        Magnification of the customized regions of the plot's axis.
    
    -----------------------------------------------------------------
    
        Version 1.0, 10-JUN-2021
        Email: iqiukp@outlook.com
    -----------------------------------------------------------------
    %}
    
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
    
    methods
        function plot(obj, axes1, axesParams, lineParams)
            obj.axes1 = axes1;
            legendExist = ~isempty(obj.axes1.Legend);
            if legendExist
                string_ = obj.axes1.Legend.String;
            end
            % insert an axes
            obj.insertAxes(axes1, axesParams);
            % insert an rectangle
            obj.insertRectangle;
            % insert lines between the inserted axes and rectangle
            obj.connectAxesAndBox(lineParams)
            if legendExist
                obj.axes1.Legend.String = string_;
            end
        end
        
        function insertAxes(obj, axes1, axesParams)
            % insert an axes
            position_ = axesParams.position;
            position_(1, 1) = axes1.Position(3)*position_(1)+axes1.Position(1);
            position_(1, 2) = axes1.Position(4)*position_(2)+axes1.Position(2);
            position_(1, 3) = axes1.Position(3)*position_(3);
            position_(1, 4) = axes1.Position(4)*position_(4);
            
            obj.axes2 = axes('Position', position_);
            copyobj(get(axes1, 'children'), obj.axes2)
            obj.computeLimit(axes1, axesParams);
            hold(obj.axes2, 'on');
            set(obj.axes2, 'LineWidth', obj.axes2BoxLineWidth,...
                'TickDir', obj.axes2TickDirection, 'Box', obj.axes2Box,...
                'XLim', obj.XLimNew, 'YLim', obj.YLimNew);
        end
        
        function computeLimit(obj, axes1, axesParams)
            % compute X-Limit and Y-Limit of inserted axes
            zoomZone = axesParams.zoomZone;
            expandRatio = axesParams.expandRatio;
            lineData = get(axes1, 'children');
            YData = [];
            for i = 1:length(lineData)
                tmp_ = lineData(i).YData;
                YData = [YData; tmp_(zoomZone)];
                XData = lineData(i).XData;
            end
            %
            tmp_x = (XData(zoomZone(1, 2))-XData(zoomZone(1, 1)))*expandRatio(1, 1);
            obj.XLimNew = [XData(zoomZone(1, 1))-tmp_x, XData(zoomZone(1, 2))+tmp_x];
            %
            tmp_y = (max(max(YData))-min(min(YData)))*expandRatio(1, 2);
            obj.YLimNew = [min(min(YData))-tmp_y, max(max(YData))+tmp_y];
        end
        
        function mappingParams = computeMappingParams(obj)
            % compute the mapping parameters
            map_k_x = range(obj.axes1.XLim)/obj.axes1.Position(3);
            map_b_x = obj.axes1.XLim(1)-obj.axes1.Position(1)*map_k_x;
            map_k_y = range(obj.axes1.YLim)/obj.axes1.Position(4);
            map_b_y = obj.axes1.YLim(1)-obj.axes1.Position(2)*map_k_y;
            mappingParams = [map_k_x, map_b_x; map_k_y, map_b_y];
        end
        
        function insertRectangle(obj)
            % insert an rectangle
            obj.mappingParams = obj.computeMappingParams;
            x0 = (obj.XLimNew(1, 1)-obj.mappingParams(1, 2))/obj.mappingParams(1, 1);
            y0 = (obj.YLimNew(1, 1)-obj.mappingParams(2, 2))/obj.mappingParams(2, 1);
            width = (obj.XLimNew(1, 2)-obj.mappingParams(1, 2))/obj.mappingParams(1, 1)-x0;
            height = (obj.YLimNew(1, 2)-obj.mappingParams(2, 2))/obj.mappingParams(2, 1)-y0;
            obj.rectangle = annotation('rectangle', [x0, y0, width, height],...
                'LineWidth', obj.rectangleLineWidth, 'LineStyle', obj.rectangleLineStyle,...
                'FaceAlpha', obj.rectangleFaceAlpha, 'FaceColor', obj.rectangleFaceColor,...
                'Color', obj.rectangleColor);
        end
        
        function connectAxesAndBox(obj, boxParams)
            
            % insert lines between the inserted axes and rectangle
            
            %   Rectangle         Axes
            %    2----1          2----1
            %    3----4          3----4
            
            % real coordinates of the inserted rectangle
            box1_1 = [obj.XLimNew(1, 2), obj.YLimNew(1, 2)];
            box1_2 = [obj.XLimNew(1, 1), obj.YLimNew(1, 2)];
            box1_3 = [obj.XLimNew(1, 1), obj.YLimNew(1, 1)];
            box1_4 = [obj.XLimNew(1, 2), obj.YLimNew(1, 1)];
            box1 = [box1_1; box1_2; box1_3; box1_4];
            
            % real coordinates of the inserted axes
            box2_1(1, 1) = (obj.axes2.Position(1)+obj.axes2.Position(3))*...
                obj.mappingParams(1, 1)+obj.mappingParams(1, 2);
            box2_1(1, 2) = (obj.axes2.Position(2)+obj.axes2.Position(4))*...
                obj.mappingParams(2, 1)+obj.mappingParams(2, 2);
            
            box2_2(1, 1) = obj.axes2.Position(1)*obj.mappingParams(1, 1)+obj.mappingParams(1, 2);
            box2_2(1, 2) = (obj.axes2.Position(2)+obj.axes2.Position(4))*...
                obj.mappingParams(2, 1)+obj.mappingParams(2, 2);
            
            box2_3(1, 1) = obj.axes2.Position(1)*obj.mappingParams(1, 1)+obj.mappingParams(1, 2);
            box2_3(1, 2) = obj.axes2.Position(2)*obj.mappingParams(2, 1)+obj.mappingParams(2, 2);
            
            box2_4(1, 1) = (obj.axes2.Position(1)+obj.axes2.Position(3))*...
                obj.mappingParams(1, 1)+obj.mappingParams(1, 2);
            box2_4(1, 2) = obj.axes2.Position(2)*obj.mappingParams(2, 1)+obj.mappingParams(2, 2);
            box2 = [box2_1; box2_2; box2_3; box2_4];
            
            % insert lines
            numLine = size(boxParams.lineDirection, 1);
            for i = 1:numLine
                pos1 = [box1(boxParams.lineDirection(i, 1), 1), box2(boxParams.lineDirection(i, 2), 1)];
                pos2 = [box1(boxParams.lineDirection(i, 1), 2), box2(boxParams.lineDirection(i, 2), 2)];
                line(pos1, pos2, 'Parent', obj.axes1, 'Color', obj.boxLineColor,...
                    'LineWidth', obj.boxLineWidth, 'LineStyle', obj.boxLineStyle,...
                    'Marker', obj.boxLineMarker, 'MarkerSize', obj.boxLineMarkerSize);
            end
        end
    end
end