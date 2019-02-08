classdef CloudObject
    properties
        phenomenaMatrix; % 3хметрная матрица вектора опасности размера  
    % 	sizeX:sizeY:sizeH, возможные значения в одном элементе - [0,2,3,5,6]            
    end
    methods
        function obj = CloudObject(sizes)
            if nargin > 0
                obj.phenomenaMatrix = zeros(sizes(1), sizes(2), sizes(3));
            end
        end
        function saveToFile(obj, path, name)
            file = fopen([path name '.cobj'], 'wb', 'ieee-le');
            fwrite(file,hex2dec('FFFF1111'),'uint32');
            fwrite(file,0,'uint32');
            sizes = size(obj.phenomenaMatrix);
            fwrite(file,sizes,'uint32');
            for iH = 1:sizes(1)
                for iX = 1:sizes(2)
                    fwrite(file,obj.phenomenaMatrix(iH,iX,:),'double');
                end
            end
            f = dir([path name '.cobj']);
            fseek(file,4,'bof');
            fwrite(file,f.bytes,'uint32');
            fclose(file);
        end
        function convertForVisual(obj,path,name,cloudID,command,shift, elemLength)
            sizes = size(obj.phenomenaMatrix);
            hlfSizes = [0 floor(sizes(2:3) / 2) 0];
            coord = zeros(sizes(1) * sizes(2) * sizes(3),4);
            lengthArr = 0;
            for hStep = 1:sizes(1)
                for xStep = 1:sizes(2)
                    for yStep = 1:sizes(3)     
                        if (obj.phenomenaMatrix(hStep, xStep, yStep) > 0)
                            lengthArr = lengthArr + 1;
                            coord(lengthArr,:) = [hStep xStep yStep ...
                                obj.phenomenaMatrix(hStep, xStep, yStep)];
                        end
                    end
                end
            end
            if (lengthArr == 0)
                disp(['CloudObject: Failed to convert for visual.' ...
                    'No data presents.']);
                return
            end
            coord = coord(1:lengthArr,:); % Очистка неиспользуемых записей
            coord = coord - length(coord(:,1)); % Получение координат в СК облака
            coord = coord + [shift 0]; % Сдвиг системы координат
            coord = coord .* [elemLength 1];
            
            file = fopen([path name '.czone'], 'wb', 'ieee-le');
            fwrite(file,0,'uint32');
            fwrite(file,cloudID,'uint32');
            fwrite(file,lengthArr,'uint64');
            fwrite(file,command,'uint64');
            for step = 1:lengthArr
                fwrite(file,coord(step,:),'double'); % пищем вектор 4 
                %элементов с координатами + опасностью каждой точки
            end
            f = dir([path name '.cobj']);
            fseek(file,1,'bof');
            fwrite(file,f.bytes,'uint32'); % Полный размер файла в байтах
            fclose(file);
            return;
        end
        function out = mergeClouds(obj, objToMerge, shift)
            hlfSizes = floor(size(obj.phenomenaMatrix) ./ [1 2 2]);
            hlfSizeMerge = floor(size(objToMerge.phenomenaMatrix)./[1 2 2]);
            hlfShiftedSizes = abs(shift) + hlfSizeMerge;
            hlfNewSizes = max(hlfSizes,hlfShiftedSizes);
            newSizes = hlfNewSizes .* [1 2 2] + [0 1 1];
            out = obj.getExpandedMatrix(newSizes);
            sizesMerge = size(objToMerge.phenomenaMatrix);
            mergeBegining = [hlfNewSizes(1) - hlfSizeMerge(1) ...
                hlfNewSizes(2) + shift(2) - hlfSizeMerge(2) ...
                hlfNewSizes(3) + shift(3) - hlfSizeMerge(3)];
            for iH = 1:sizesMerge(1)
                for iX = 1:sizesMerge(2)
                    for iY = 1:sizesMerge(3)
                        out.phenomenaMatrix(iH + mergeBegining(1),...
                            iX + mergeBegining(2), iY + mergeBegining(3)) = ...
                            max(out.phenomenaMatrix(iH + mergeBegining(1),...
                            iX + mergeBegining(2), iY + mergeBegining(3)),...
                            objToMerge.phenomenaMatrix(iH, iX, iY));

                    end
                end
            end     
        end
        function obj = filtrateCubic(obj, windowDimensions, threshold)
            hlfWindow = floor(windowDimensions ./ 2);
            sizes = size(obj.phenomenaMatrix);
            elemsInCube = windowDimensions(1) * windowDimensions(2) * ...
                windowDimensions(3);
            expandedMatrix = obj.getMatrixForFiltration(hlfWindow);
            counter = 0.01;
            obj.phenomenaMatrix = zeros(size(obj.phenomenaMatrix));
            for iH = 1:sizes(1)
                if (counter < iH/sizes(1))
                    counter = counter + 0.01;
                    disp(['Cubic filtration is under way. Completed '...
                        num2str(round(iH/sizes(1) * 100)) '%']);
                end
                for iX = 1:sizes(2)
                    for iY = 1:sizes(3)
                        tempCube = expandedMatrix(iH:iH + ...
                            windowDimensions(1) - 1, iX:iX + ...
                            windowDimensions(2) - 1, iY:iY + ...
                            windowDimensions(3) - 1);
                        maxDanger = max(max(max(tempCube)));
                        for iDanger = 1:maxDanger
                            binaryCube = zeros(size(tempCube));
                            binaryCube(tempCube > iDanger) = 1;
                            if (sum(sum(sum(binaryCube)))/elemsInCube >...
                                    threshold)
                                obj.phenomenaMatrix(iH, iX, iY) = iDanger;
                            end
                        end
                    end
                end
            end
        end
        function displayCloudWithMarkers(obj, dangerID, color, markerSize, ax)
            tic
            if nargin == 4
                figure('units','normalized','outerposition',[0.10 0.05 0.8 0.9])
                hold on;
                ax = gca;
            end
            sizes = size(obj.phenomenaMatrix);
            hlfSizes = floor(sizes / 2);
            lengthArr = 0;
            X = zeros(sizes(1) * sizes(2) * sizes(3),1);
            Y = zeros(size(X));
            H = zeros(size(X));
      
            for hStep = 1:sizes(1)
                for xStep = 1:sizes(2)
                    for yStep = 1:sizes(3)      
                        if (obj.phenomenaMatrix(hStep, xStep, yStep) >= dangerID)
                            lengthArr = lengthArr + 1;
                            X(lengthArr) = xStep;
                            Y(lengthArr) = yStep;
                            H(lengthArr) = hStep;
                        end
                    end
                end
            end
            X = X(1:lengthArr) - hlfSizes(2) - 1;
            Y = Y(1:lengthArr) - hlfSizes(3) - 1;
            H = H(1:lengthArr) - 1;
            set(gcf,'CurrentAxes',ax);
            scatter3(X,Y,H,ones(size(H))*markerSize,'s','MarkerFaceColor',color,...
                'MarkerEdgeColor',color);
            
            set(ax,'xlim',[-hlfSizes(2) hlfSizes(2)],'ylim',...
                [-hlfSizes(3) hlfSizes(3)],'zlim',[0 sizes(1) - 1]);
            toc
        end
        function displayCloud_Unoptimized2(obj, dangerID, bIsFullDisp, color, ax)
            tic
            if nargin == 4
                figure('units','normalized','outerposition',[0.10 0.05 0.8 0.9])
                hold on;
                ax = gca;
            end
            HullCoords_solid = [];
            HullLinks_solid = [];
            if bIsFullDisp == 1
                HullCoords_transp = [];
                HullLinks_transp = [];
            end
            sizes = size(obj.phenomenaMatrix);
            hlfSizeY = ceil(sizes(3)/2);
            hlfSizeX = ceil(sizes(2)/2);
            disp('Preparing replay:');
            infoTic = 5;
            for hStep = 1:sizes(1)
                if (floor(hStep * 100 / sizes(1)) > infoTic)
                    disp([num2str(infoTic) '% completed']);
                    infoTic = infoTic + 5;
                end
                for xStep = 1:sizes(2)
                    for yStep = 1:sizes(3)     
                        if (obj.phenomenaMatrix(hStep, xStep, yStep) >= dangerID)
                            if (obj.phenomenaMatrix(hStep, xStep + 1,...
                                    yStep) < dangerID || ...
                                obj.phenomenaMatrix(hStep, xStep - 1,...
                                    yStep) < dangerID || ...
                                obj.phenomenaMatrix(hStep + 1, xStep,...
                                    yStep) < dangerID || ...
                                obj.phenomenaMatrix(hStep - 1, xStep,...
                                    yStep) < dangerID || ...
                                obj.phenomenaMatrix(hStep, xStep,...
                                    yStep + 1) < dangerID || ...
                                obj.phenomenaMatrix(hStep, xStep,...
                                    yStep - 1) < dangerID)
                      
                                [newHullLinks,newHullCoords] = ...
                                    CloudObject.getCubeHull(xStep - ...
                                    hlfSizeX, yStep - hlfSizeY, hStep - 1);
                                [HullLinks_solid, HullCoords_solid] = ...
                                    CloudObject.mergeFigureHulls(...
                                    HullLinks_solid, HullCoords_solid,...
                                    newHullLinks,newHullCoords);
                            end
                        end
                        if(obj.phenomenaMatrix(hStep, xStep,...
                                yStep) > 0 && bIsFullDisp == 1)
                            [newHullLinks,newHullCoords] = CloudObject.getCubeHull(...
                                xStep -  hlfSizeX, yStep - hlfSizeY, hStep - 1);
                            [HullLinks_transp, HullCoords_transp] = ...
                                CloudObject.mergeFigureHulls(HullLinks_transp, ...
                                HullCoords_transp, newHullLinks,newHullCoords);
                        end
                    end
                end
            end
            if (bIsFullDisp == 1)
                trisurf(HullLinks_transp,HullCoords_transp(:,1),...
                    HullCoords_transp(:,2),HullCoords_transp(:,3),...
                    'EdgeAlpha', 1, 'FaceAlpha', 0);
            end
            trisurf(HullLinks_solid,HullCoords_solid(:,1),...
                    HullCoords_solid(:,2),HullCoords_solid(:,3),...
                    'EdgeAlpha', 0, 'FaceAlpha', 1);
            
            set(ax,'xlim',[-hlfSizeX hlfSizeX],'ylim',...
                [-hlfSizeY hlfSizeY],'zlim',[0 sizes(1) - 1]);
            colormap(color);
            toc
        end
        function displayCloud_Unoptimized(obj, dangerID, bIsFullDisp, color, ax)
            tic
            if nargin == 4
                figure('units','normalized','outerposition',[0.10 0.05 0.8 0.9])
                hold on;
                ax = gca;
            end
            sizes = size(obj.phenomenaMatrix);
            hlfSizeY = ceil(sizes(3)/2);
            hlfSizeX = ceil(sizes(2)/2);
            for hStep = 1:sizes(1)
                for xStep = 1:sizes(2)
                    for yStep = 1:sizes(3)
                        if (obj.phenomenaMatrix(hStep, xStep, yStep) >= dangerID)
                            CloudObject.plotOneCube(ax, xStep - hlfSizeX,...
                                yStep - hlfSizeY, hStep - 1,0,1);
                        elseif(obj.phenomenaMatrix(hStep, xStep,...
                                yStep) > 0 && bIsFullDisp == 1)
                            CloudObject.plotOneCube(ax, xStep - hlfSizeX,...
                                yStep - hlfSizeY, hStep - 1, 1, 0);
                        end
                    end
                end
            end
            set(ax,'xlim',[-hlfSizeX hlfSizeX],'ylim',...
                [-hlfSizeY hlfSizeY],'zlim',[0 sizes(1) - 1]);
            colormap(color);
            toc
        end
    end
    methods(Access = private)
        function expandedCloud = getExpandedMatrix(obj, newSizes)
            expandedCloud = CloudObject(newSizes);
            sizes = size(obj.phenomenaMatrix);
            hlfSizes = floor((newSizes - sizes )/ 2);
           	expandedCloud.phenomenaMatrix(1:sizes(1), hlfSizes(2) + ...
                1: hlfSizes(2) + sizes(2), hlfSizes(3) + 1: ...
                hlfSizes(3) + sizes(3)) = obj.phenomenaMatrix;
        end  
        function expandedMatrix = getMatrixForFiltration(obj, hlfWindow)
            sizes = size(obj.phenomenaMatrix);
            expandedMatrix = zeros(hlfWindow(1) * 2 + sizes(1), ...
                2*hlfWindow(2) +sizes(2), 2*hlfWindow(3) + sizes(3));

            expandedMatrix(hlfWindow(1) + 1: hlfWindow(1)...
                + sizes(1), hlfWindow(2) + 1: hlfWindow(2)...
                + sizes(2), hlfWindow(3) + 1: hlfWindow(3)...
                + sizes(3)) = obj.phenomenaMatrix;

            for iH = 1:hlfWindow(1)
                expandedMatrix(iH, :, :) = expandedMatrix(hlfWindow(1) + 1,:,:);
                expandedMatrix(hlfWindow(1) + sizes(1) + iH, :, :) =...
                    expandedMatrix(hlfWindow(1) + sizes(1),:,:);
            end

            for iX = 1:hlfWindow(2)
                expandedMatrix(:, iX, :) = expandedMatrix(:,hlfWindow(2) + 1,:);
                expandedMatrix(:,hlfWindow(2) + sizes(2) + iX, :) =...
                    expandedMatrix(:, hlfWindow(2) + sizes(2),:);
            end

            for iY = 1:hlfWindow(3)
                expandedMatrix(:, :, iY) = expandedMatrix(:,:,hlfWindow(3) + 1);
                expandedMatrix(:, :,hlfWindow(3) + sizes(3) + iY) =...
                    expandedMatrix(:,: , hlfWindow(3) + sizes(3));
            end
        end
    end
    methods(Static)
        function obj = extractFromFile(path, name)
            f = dir([path name '.cobj']);
            assert(~isempty(f),['CloudObject: No file ' name 'is find '...
                'in target directory']); 
            file = fopen([path name '.cobj'], 'rb');
            assert((file > 0) && f.bytes > 8,['CloudObject: Failed '...
                'to open file ' name '!']);
            prefix = fread(file,1,'uint32');
            length = fread(file,1,'uint32');
            assert(length == f.bytes && isequal(dec2hex(prefix),'FFFF1111'),...
                ['CloudObject: Failed to unpack structure. Bad header'...
                ' received']);
            sizes = fread(file,3,'uint32');
            obj = CloudObject(sizes);
            for iH = 1:sizes(1)
                for iX = 1:sizes(2)
                    obj.phenomenaMatrix(iH,iX,:) = ...
                        fread(file,sizes(3),'double');
                end
            end
            fclose(file);
        end
    end
    methods(Static, Access = private)
        function plotOneCube(ax, xCoord, yCoord, hCoord, lineWidth, wallWidth)
            axes(ax)
            xCoord = [xCoord - 0.5 xCoord + 0.5 xCoord + 0.5 xCoord - 0.5 ...
                xCoord - 0.5 xCoord + 0.5 xCoord + 0.5 xCoord - 0.5];
            yCoord = [yCoord - 0.5 yCoord - 0.5 yCoord + 0.5 yCoord + 0.5 ...
                yCoord - 0.5 yCoord - 0.5 yCoord + 0.5 yCoord + 0.5];
            hCoord = [hCoord - 0.5 hCoord - 0.5 hCoord - 0.5 hCoord - 0.5 ...
                hCoord + 0.5 hCoord + 0.5 hCoord + 0.5 hCoord + 0.5];
            K = convhull(xCoord,yCoord,hCoord);
            trisurf(K,xCoord,yCoord,hCoord,...
                'EdgeAlpha', lineWidth, 'FaceAlpha', wallWidth);
        end
        function [K,points] = getCubeHull(xCoord, yCoord, hCoord)
            xPoints = [xCoord - 0.5; xCoord + 0.5; xCoord + 0.5; (xCoord -... 
                0.5); xCoord - 0.5; xCoord + 0.5; xCoord + 0.5; xCoord - 0.5];
            yPoints = [yCoord - 0.5; yCoord - 0.5; yCoord + 0.5; (yCoord + ...
                0.5); yCoord - 0.5; yCoord - 0.5; yCoord + 0.5; yCoord + 0.5];
            hPoints = [hCoord - 0.5; hCoord - 0.5; hCoord - 0.5; (hCoord - ...
                0.5); hCoord + 0.5; hCoord + 0.5; hCoord + 0.5; hCoord + 0.5];
            points = [xPoints  yPoints hPoints];
            K = convhull(xPoints, yPoints, hPoints);
            return;
        end   
        function [HullLinks, HullCoord] = mergeFigureHulls(HullLinks,...
                HullCoord, K, points)
            if (isempty(HullCoord))
                HullCoord = points;
                HullLinks = K;
                return;
            end
            mergeHull = zeros(size(K));
            for i = 1:length(points(:,1))
                pIndex = find(ismember(HullCoord ,points(i,:),'rows') == 1,1);
                [a, b] = find(K == i);
                if isempty(pIndex)
                    HullCoord = [HullCoord; points(i,:)];
                    for j = 1:length(a)
                        mergeHull(a(j),b(j))= length(HullCoord(:,1));
                    end
                else
                    for j = 1:length(a)
                        mergeHull(a(j),b(j))= pIndex;
                    end
                end
            end
            HullLinks = [HullLinks ; mergeHull];
        end
     
    end
end