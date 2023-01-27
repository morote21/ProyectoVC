%% CLASE CON FUNCIONES PARA RECONOCER LOS CARACTERES DE LA MATRICULA

classdef recognizerFunctionContainer < handle
    properties
        
    end
    methods (Static)
        function [trainingDigits, trainingLetters] = training(fonts, digits, letters)
            trainingDigits = struct;
            trainingLetters = struct;
            digitsHistograms = [];
            lettersHistograms = [];
            for x=1 : size(fonts, 3)
                im = fonts(:,:,x);
                font = ~imbinarize(im);
                letras_train = regionprops(font, 'BoundingBox');
                
                for i=1 : length(letras_train)
                    letra = imcrop(font, letras_train(i).BoundingBox);
                    width = letras_train(i).BoundingBox(3); height = letras_train(i).BoundingBox(4);
                    desiredHeight = 200;
                    if (width > height) 
                        continue; 
                    end
                    indexForLetter = i-11; % con las plantillas para matriculas griegas, los numeros son los 10 primeros
                    letra = recognizerFunctionContainer.squareAndResizeImage(letra, desiredHeight);
                    %figure, imshow(letra)
                    letra = imdilate(letra, strel('disk', 3));
                    hog_30x30 = extractHOGFeatures(letra,'CellSize',[28 28]);   % el que mejores resultados ha dado es 30 30 
                    if i < 11
                        digitsHistograms = [digitsHistograms;hog_30x30];
                    else
                        trainingLetters(indexForLetter).Letter = letters(indexForLetter);
                        lettersHistograms = [lettersHistograms;hog_30x30];
                    end
                end
            end
            for i=1 : length(digits)
                % metemos para cada digito tanto el de la primera imagen
                % como el de la segunda
                trainingDigits(i).Digit = digits(i);
                histograms = cat(1, digitsHistograms(i,:), digitsHistograms(i+length(digits),:), digitsHistograms(i+2*length(digits),:), digitsHistograms(i+3*length(digits),:));
                trainingDigits(i).Histogram = histograms;
            end
            for i=1 : length(letters)
                trainingLetters(indexForLetter).Letter = letters(i);
                histograms = cat(1, lettersHistograms(i,:), lettersHistograms(i+length(letters),:), lettersHistograms(i+2*length(letters),:), lettersHistograms(i+3*length(letters),:));
                trainingLetters(i).Histogram = histograms;
            end

        end

        function matricula = recognize(imagen, letras, trainingDigits, trainingLetters)
            matricula = "";
            % primero ordenar letras de menor a mayor x
            letras = recognizerFunctionContainer.sortStats(letras);
            for i=1 : length(letras)
                letra = letras(i);
                im_letra = imcrop(imagen, letra.BoundingBox);
                desiredHeight = 200;
                im_letra = recognizerFunctionContainer.squareAndResizeImage(im_letra, desiredHeight);

                % operaciones morfologicas para ayudar al reconocimiento
                %im_letra = imclose(im_letra, strel('square', 20));
                
                
                ero = imerode(im_letra, strel('rectangle', [20,15]));   % conseguimos marca de solo el caracter
                im_letra = imreconstruct(ero, im_letra);                % quitamos elementos que sobran que no pertenezcan a la letra
                %para quedarse con solo el objeto mas grande
                im_letra = imclose(im_letra, strel('disk', 5));         % cerramos partes pequeñas para suavizar lo maximo posible las letras y numeros
                im_letra = imdilate(im_letra, strel('disk', 5));        % agrandamos un poco (de la misma manera que con las imagenes de training)
                %figure, imshow(im_letra)
                hog_30x30 = extractHOGFeatures(im_letra,'CellSize',[28 28]);

                if i < 4
                    min_distance = -1;
                    min_distance_index = -1;
                    for j=1 : length(trainingLetters)
                        for k=1 : size(trainingLetters(j).Histogram, 1)
                            distance = recognizerFunctionContainer.distChiSq(hog_30x30, trainingLetters(j).Histogram(k,:));
                            % al acabar el loop conseguiremos el que tenga distancia menor,
                            % es decir, el que mas se parezca
                            if min_distance == -1
                                min_distance = distance;
                                min_distance_index = j;
                            else
                                if distance < min_distance
                                    min_distance = distance;
                                    min_distance_index = j;
                                end
                            end
                        end
                    end
                    matricula = matricula + trainingLetters(min_distance_index).Letter;
                else
                    min_distance = -1;
                    min_distance_index = -1;
                    for j=1 : length(trainingDigits)
                        for k=1 : size(trainingDigits(j).Histogram, 1)
                            distance = recognizerFunctionContainer.distChiSq(hog_30x30, trainingDigits(j).Histogram(k,:));
                            % al acabar el loop conseguiremos el que tenga distancia menor,
                            % es decir, el que mas se parezca
                            if min_distance == -1
                                min_distance = distance;
                                min_distance_index = j;
                            else
                                if distance < min_distance
                                    min_distance = distance;
                                    min_distance_index = j;
                                end
                            end
                        end
                    end
                    matricula = matricula + trainingDigits(min_distance_index).Digit;
                end

            end
        end

        function sortedStats = sortStats(stats)
            T = struct2table(stats);
            sortedTable = sortrows(T, 'BoundingBox');
            sortedStats = table2struct(sortedTable);
        end

        function image = squareAndResizeImage(im, desiredHeight)
            [height, width]= size(im);
            
            scaleHeight = (desiredHeight/height);
            image = imresize(im, [100, width*scaleHeight]);
            
            difference = ceil(scaleHeight*(height-width)/2);
            image = padarray(image, [20 20+difference], 0);
            if size(image,1) < size(image,2)
                image(end+1,:) = 0;
            end
        
            image = imresize(image, [desiredHeight, desiredHeight]);
        end

        function D = distChiSq( X, Y )
            A = (X-Y).^2; B = X+Y;
            C = A ./ (B+eps);       % + eps para que no de error cuando se divide entre 0 y el resultado sea 0
            D = sum(C);
            D = D/2;
        end
    
    end
end