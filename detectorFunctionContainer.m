%% CLASE CON FUNCIONES PARA LA DETECCION DE LA POSICION DE LA MATRICULA

classdef detectorFunctionContainer < handle 
    methods (Static)
        % Suaviza la imagen del coche utilizando filtro mediana
        function smoothedCar = imageSmoothing(im)            
            smoothedCar = medfilt2(im, [2,2]);
        end
        
        % Binariza la imagen del coche usando moving averages
        function binarizedCar = imageBinarization(im)
            h = ones(10)/10/10;
            promedio = imfilter(im, h, 'conv', 'replicate');
            k = 5;
            binarizedCar = im > (promedio-k);
        end

        function edgesCar = imageEdges(im)
            edgesCar = edge(im, 'Canny');
        end

        % Muestra la imagen de la placa con los boundingbox conseguidos
        function displayBoundingBoxLP(imagenMatricula, letras, placa)
            figure, imshow(imagenMatricula), title('resultado')
            hold on 
            for i = 1:length(letras)
                rectangle('Position', letras(i).BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
            end
            rectangle('Position', placa, 'EdgeColor', 'r', 'LineWidth', 2);
            impixelinfo
        end 
        
        % Devuelve el numero de slopes con cierto valor minimo
        function n = nSlopesMinValue(v)
            minVal = 0.2;
            n = 0;
            for i=1 : length(v)
                if v(i) <= minVal
                    n = n + 1;
                end
            end
        end

        function image = rotateImage(candidatesToLetters, Icropped)
            image = Icropped;
            candidatesToLetters = detectorFunctionContainer.sortStats(candidatesToLetters);
            region1 = candidatesToLetters(1).BoundingBox;
            region2 = candidatesToLetters(end).BoundingBox;
            x1 = region1(1); y1 = region1(2);
            x2 = region2(1); y2 = region2(2);
                
            slope = (y2 - y1) / (x2 - x1); 

            u = [x2-x1; y2-y1]; v = [x2-x1; y1-y1];
            angle = rad2deg( acos(dot(u, v) / (norm(u)*norm(v))) );
            if (~isinf(angle) && ~isnan(angle))
                if slope < 0
                    image = imrotate(Icropped, -angle);
                else
                    image = imrotate(Icropped, angle);
                
                end
            end
        end
        
        % Devuelve el BoundingBox de todas las letras detectadas
        function plate = boxLetters(stats)
            x_min_left = stats(1).BoundingBox(1); y_min_up = stats(1).BoundingBox(2);
            x_max_right = stats(1).BoundingBox(1) + stats(1).BoundingBox(3);
            y_max_down = stats(1).BoundingBox(2) + stats(1).BoundingBox(4);
            for i=2 : length(stats)
                region = stats(i).BoundingBox;
                x_left = region(1); y_up = region(2); width = region(3); height = region(4);
                x_right = x_left + width;
                y_down = y_up + height;
                if (x_left < x_min_left)
                    x_min_left = x_left;
                end
                if (y_up < y_min_up)
                    y_min_up = y_up;
                end
                if (x_right > x_max_right)
                    x_max_right = x_right;
                end
                if (y_down > y_max_down)
                    y_max_down = y_down;
                end
            end
            offset = 2;
            x_left_up = x_min_left - offset;
            y_left_up = y_min_up - offset;
            x_right_low = x_max_right + offset;
            y_right_low = y_max_down + offset;
            height = y_right_low - y_left_up;
            width = x_right_low - x_left_up;
            plate =  [x_left_up, y_left_up, width, height];
        end

        % Filtra la imagen para encontrar placas de matricula, devolviendo
        % los boundingboxes de los candidatos a placas encontrados
        function candidatesToPlate = filterByLp(imagen_bordes)
            stats = regionprops(imagen_bordes, "BoundingBox", "Area");
            candidatesIndices = [];
            candidatesToPlate = struct;
            for i = 1:length(stats)
                region = stats(i).BoundingBox;
                area = stats(i).Area;
                width = region(3);
                height = region(4);
                area_minima = 200;
                if (width >= 2*height) && (area > area_minima) && (width <= 7*height)
                    candidatesIndices(end+1) = i;        
                end
            end
            
            for i=1 : length(candidatesIndices)
                region = stats(candidatesIndices(i)).BoundingBox;
                candidatesToPlate(end+1).BoundingBox = region;
            end
            candidatesToPlate(1) = [];
            candidatesToPlate = detectorFunctionContainer.removeUselessPlates(candidatesToPlate);
        end
        
        % Elimina los BoundingBoxes de las placas detectadas que tienen mas
        % BoundingBoxes dentro, ya que un candidato a placa no debe tener
        % candidatos dentro
        function detectedPlates = removeUselessPlates(stats)
            detectedPlatesIndices = [];
            detectedPlates = struct;
            for i=1 : length(stats)
                remove = false;
                region = stats(i).BoundingBox;
                x = region(1); y = region(2); width = region(3); height = region(4);
                for j=1 : length(stats)
                    if i ~= j
                        region2 = stats(j).BoundingBox;
                        x2 = region2(1); y2 = region2(2); width2 = region2(3); height2 = region2(4);
                        if (x < x2) && (y < y2) && (x+width > x2+width2) && (y+height > y2+height2)
                            remove = true;
                        end

                        if (x < x2) && (y < y2) && (x2 < x+width) && (y2 < y+height)
                            widthIntersec = min(x+width, x2+width2)-x2;
                            heightIntersec = min(y+height, y2+height2)-y2;
                            areaIntersec = widthIntersec * heightIntersec;
                            percentageArea = areaIntersec / (width*height);
                            if percentageArea > 0.70
                                remove = true;
                            end
                        end
                    end
                end
                if ~remove
                    detectedPlatesIndices(end+1) = i;
                end
            end
        
            for i=1 : length(detectedPlatesIndices)
                region = stats(detectedPlatesIndices(i)).BoundingBox;
                detectedPlates(end+1).BoundingBox = region;
            end
            detectedPlates(1) = [];
        end

        % Filtra una serie de BoundingBoxes para encontrar pares de letras con poca pendiente entre ellas, que
        % esten cerca, tengan una altura muy parecida, y que no se solapen entre ellas
        function detectedLetters = filterBySimilarityAndNearLowSlope(stats)
            detectedLettersIndices = [];
            detectedLetters = struct;
            for i = 1:size(stats, 2)
                region = stats(i).BoundingBox;
                x_left_1 = region(1); y_up_1 = region(2); width = region(3); height = region(4);
                for j=i+1 : size(stats, 2)
                    region2 = stats(j).BoundingBox;
                    x_left_2 = region2(1); y_up_2 = region2(2); height2 = region2(4);
                    slope = (y_up_2 - y_up_1) / (x_left_2 - x_left_1);
                    if (x_left_2 < x_left_1+(width*3)) && (height2 <= height+4) && (height2 >= height-4) && (x_left_2 > x_left_1+width) && (abs(slope) < 0.2)
                        detectedLettersIndices(end+1) = i;
                        detectedLettersIndices(end+1) = j;
                    end
            
                end
            end
            % eliminamos los repetidos
            while ~isempty(detectedLettersIndices)
                region = stats(detectedLettersIndices(1)).BoundingBox;
                detectedLetters(end+1).BoundingBox = region;
                detectedLettersIndices = detectedLettersIndices(detectedLettersIndices~=detectedLettersIndices(1));
            end
            
            detectedLetters(1) = [];
        end
        
        % Filtra una serie de BoundingBoxes para encontrar candidatos a
        % letras mirando que tengan una area minima y una relacion de
        % aspecto de manera que su altura sea mayor o igual que su anchura 
        function detectedLetters = filterByMinAreaAndRa(stats)
            detectedLettersIndices = [];
            detectedLetters = struct;
            for i = 1:size(stats)
                region = stats(i).BoundingBox;
                area = stats(i).Area;
                width = region(3); height = region(4);
                area_minima = 50;
                if (height >= width) && (area > area_minima)
                    detectedLettersIndices(end+1) = i;        
                end
            end
            
            for i=1 : length(detectedLettersIndices)
                region = stats(detectedLettersIndices(i)).BoundingBox;
                detectedLetters(end+1).BoundingBox = region;
            end
            detectedLetters(1) = [];
        end
        
        % Filtra una serie de BoundingBoxes para encontrar candidatos a
        % letras mirando que una cierta cantidad de BoundingBoxes (5 a 7)
        % esten mas o menos en fila con un pendiente pequeño
        function detectedLetters = filterByAmountOfSlopes(stats)
            detectedLettersIndices = [];
            detectedLetters = struct;
            for i=1 : size(stats, 2)
                region = stats(i).BoundingBox;
                x_left_1 = region(1); y_up_1 = region(2);
                slopes = [];
                for j=1 : size(stats, 2)
                    region2 = stats(j).BoundingBox;
                    x_left_2 = region2(1); y_up_2 = region2(2);
                    slope = (y_up_2 - y_up_1) / (x_left_2 - x_left_1);
                    slopes(end+1) = abs(slope);
                end
        
                slopes = sort(slopes);
                belongs_plate = false;
                if detectorFunctionContainer.nSlopesMinValue(slopes) >= 5 && detectorFunctionContainer.nSlopesMinValue(slopes) <= 7 
                    belongs_plate = true;
                end
                
                if belongs_plate
                    detectedLettersIndices(end+1) = i;
                end
            end
        
            % eliminamos los repetidos
            while size(detectedLettersIndices, 2) ~= 0
                region = stats(detectedLettersIndices(1)).BoundingBox;
                detectedLetters(end+1).BoundingBox = region;
                detectedLettersIndices = detectedLettersIndices(detectedLettersIndices~=detectedLettersIndices(1));
            end
            
            detectedLetters(1) = [];
        end 
        
        function sortedStats = sortStats(stats)
            T = struct2table(stats);
            sortedTable = sortrows(T, 'BoundingBox');
            sortedStats = table2struct(sortedTable);
        end

        % Juntamos los filtros para la estrategia 1
        function candidatesToLetters = filtersForStrat1(stats)
            % ordenamos de menor a mayor coordenada x 
            sorted_stats = detectorFunctionContainer.sortStats(stats);
           
            % filtrado 1
            possibleLetters = detectorFunctionContainer.filterByMinAreaAndRa(sorted_stats);
        
            % filtrado 2
            possibleLetters2 = detectorFunctionContainer.filterBySimilarityAndNearLowSlope(possibleLetters);
            
            % filtrado 3
            candidatesToLetters = detectorFunctionContainer.filterByAmountOfSlopes(possibleLetters2);
        end
        
        % Se aplica la estrategia 1, teniendo como output la BoundingBox de
        % la placa, las BoundingBoxes de las letras, y la imagen en si de
        % la placa detectada
        function [placa, letras, imagen_crop] = strat1(imagen_coche_bordes, imagen_coche_binarizada)
            possiblePlates = detectorFunctionContainer.filterByLp(imagen_coche_bordes);
            placa = [];
            letras = struct;
            area = 600*800; % area maxima posible (toda la imagen)
            imagen_crop = imagen_coche_bordes;
            for i=1 : length(possiblePlates)
                region = possiblePlates(i).BoundingBox;
                Icropped = ~imcrop(imagen_coche_binarizada, region);
                stats = regionprops(Icropped, "BoundingBox", "Area");
                if isempty(stats)  % en caso de que no haya detectado ningun tipo de posible letra, ir a la siguiente iteracion
                   continue; 
                end
                letras = detectorFunctionContainer.filtersForStrat1(stats);
                if isempty(letras)  % en caso de que no haya detectado ningun tipo de posible letra, ir a la siguiente iteracion
                   continue; 
                end

                imagen_crop = Icropped;
                if (length(letras) == 7)
                    area_placa = region(3)*region(4);   
                    if (area_placa < area)
                        placa = detectorFunctionContainer.boxLetters(letras);
                        break;
                    end
                end 
            end
        end
        
        
        function [placa, letras, imagen_crop] = strat2(imagen_coche_bordes, imagen_coche_binarizada)
            posiblesplacas = detectorFunctionContainer.filterByLp(imagen_coche_bordes); 
            placa = [];
            letras = struct;
            imagen_crop = imagen_coche_binarizada;
            for i=1:length(posiblesplacas)
                placa = posiblesplacas(i).BoundingBox;
                Icropped = ~imcrop(imagen_coche_binarizada, placa);
                posiblesletras = regionprops(Icropped, "BoundingBox", "Area");
                posiblesletras = detectorFunctionContainer.filtersForStrat1(posiblesletras);
                if isempty(posiblesletras)  % en caso de que no haya detectado ningun tipo de posible letra, ir a la siguiente iteracion
                   continue; 
                end
                
                Icropped = detectorFunctionContainer.rotateImage(posiblesletras, Icropped);
                posiblesletras = regionprops(Icropped, "BoundingBox", "Area");
                posiblesletras = detectorFunctionContainer.filtersForStrat1(posiblesletras);
                if isempty(posiblesletras)  % en caso de que no haya detectado ningun tipo de posible letra, ir a la siguiente iteracion
                   continue; 
                end
                
                region = posiblesletras(1).BoundingBox;
                x = round(region(1)); y = round(region(2)); height = region(4);
                Icropped(1:y, :) = 0; Icropped(y+height:end, :) = 0; Icropped(:, 1:5) = 0; Icropped(:, end-5:end) = 0;
                posiblesletras = regionprops(Icropped, "BoundingBox", "Area");
                if isempty(posiblesletras)  % en caso de que no haya detectado ningun tipo de posible letra, ir a la siguiente iteracion
                   continue; 
                end
                letras = detectorFunctionContainer.filtersForStrat1(posiblesletras);
                if isempty(letras)  % en caso de que no haya detectado ningun tipo de posible letra, ir a la siguiente iteracion
                   continue; 
                end
                imagen_crop = Icropped;
                placa = detectorFunctionContainer.boxLetters(letras);
                % posiblemente aqui si hay varias opciones de
                % resultado, elegir la mejor de alguna manera
                if (length(letras) == 7)    % en caso de que haya detectado ya una posible matricula, acabar el proceso
                    break;
                end
                
            end
        end 

    end
end