%% PROGRAMA PRINCIPAL
detector = detectorFunctionContainer;
recognizer = recognizerFunctionContainer;

Letters = ["A"; "B"; "E"; "H"; "I"; "K"; "M"; "N"; "O"; "P"; "T"; "X"; "Y"; "Z"];
Digits = ["1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "0"];
% cargamos las plantillas
font = rgb2gray(imread("Greek-License-Plate-Font-2004.svg.png"));
font2 = rgb2gray(imread("Greek-License-Plate-Font-old.jpg"));
font3 = rgb2gray(imread("modelo3.jpg"));
font4 = rgb2gray(imread("modelo4.jpg"));
fonts = cat(3, font, font2, font3, font4);
% entrenamos las estructuras
[trainingDigits, trainingLetters] = recognizer.training(fonts, Digits, Letters);

matriculasReales = ["ZMZ9157", "YKM2435", "YEP7236", "YYP4245", "YHP2336", "YHE2993", "ZZH8585", "YZP4923", "ZME8325", "YHO7569",...
                    "ZKK8153", "ZZN5726", "IEA6907", "IEA5511", "ZME7027", "YKK3431", "IZB2701", "YAZ2074", "YPE2367", "NE6027", ...
                    "ZZA9341", "BIZ1100", "YYO8246", "YPP7390", "YNH8511", "IZI2154", "ZHM1169", "IEO8056", "IEN8393", "ZYM7983",...
                    "ZYY6708", "ZZA9341", "YKK3876", "ZHX1648", "ZYX5517", "ZYZ8289", "NAN1663", "ZZX8178", "ZMZ2317", "ZZY4066",...
                    "IEE2359", "II5658", "IEB2949", "IEP1025", "YBE5094", "YKX1115", "ZKT1403", "IZA6106", "YXN7980", "ZKH1671", ...
                    "YHK9499", "ZKE5495", "ZYB9024", "YOO5657", "ZZH3597", "YZP2401", "ZKB1454", "IZB2701", "IBY2254", "IET2457",...
                    "IZE4030", "IZE4030", "NZB2491", "ZZA7958", "IBM9201", "ZYX7440", "IBT3672"];

matriculasCorrectas = 0;
letrasCorrectas = 0;
letrasTotales = 0;
cont1 = 0;
cont2 = 0;
falsosNegativos = 0;
falsosPositivos = 0;
a = dir('day_color(small sample)\*.jpg');   % cargamos todas las imagenes de matriculas 
nf = size(a);
%tic
for i=1 : nf
    filename = horzcat(a(i).folder,'/',a(i).name);
    I = imread(filename);
    matricula = "";
    im = rgb2gray(I);
    %figure, imshow(im)
    imagen_prueba = detector.imageSmoothing(im);
    imagen_edges = detector.imageEdges(im);
    imagen_bin = detector.imageBinarization(im);

    disp("------- Matricula a reconocer: " + matriculasReales(i) + " -------");

    strat = 1;
    [placa, letras, imagen_crop] = detector.strat1(imagen_edges, imagen_bin);
    if (length(letras) ~= 7)
        strat = 2;
        [placa, letras, imagen_crop] = detector.strat2(imagen_edges, imagen_bin);
    end
    if (length(letras) == 7)
        %detector.displayBoundingBoxLP(imagen_crop, letras, placa);
        matricula = recognizer.recognize(imagen_crop, letras, trainingDigits, trainingLetters);    
        disp("Estrategia usada: " + strat);
    end
    
    matricula = convertStringsToChars(matricula);
    matriculaReal = convertStringsToChars(matriculasReales(i));
    if (~isempty(matricula))
        letrasTotales = letrasTotales + length(matriculaReal);
        if (length(matricula) <= length(matriculaReal))    
            for j=1 : length(matricula)  
                if (matricula(j) == matriculaReal(j))
                    letrasCorrectas = letrasCorrectas + 1;
                end
            end
        else
            for j=1 : length(matriculaReal)  
                if (matricula(j) == matriculaReal(j))
                    letrasCorrectas = letrasCorrectas + 1;
                end
            end
        end
    end

    if (strat == 1)
        cont1 = cont1 + 1;
    else
        cont2 = cont2 + 1;
    end

    disp("Matricula reconocida: " + matricula);
    if (matriculasReales(i) == matricula)
        matriculasCorrectas = matriculasCorrectas + 1;
    else
        if (matricula == "")
            falsosNegativos = falsosNegativos + 1;
        else
            falsosPositivos = falsosPositivos + 1;
        end
        disp("Matricula INCORRECTA: " + a(i).name);
    end

end
%toc
disp("Numero de matriculas correctas = " + num2str(matriculasCorrectas));
disp("Porcentaje de matriculas correctamente reconocidas = " + num2str(matriculasCorrectas*100/nf(1)) + " %");
disp("Porcentaje de letras correctamente reconocidas = " + num2str(letrasCorrectas*100/letrasTotales) + " %");
disp("Porcentaje de uso estrategia 1 = " + num2str(cont1*100/nf(1)) + " %");
disp("Porcentaje de uso estrategia 2 = " + num2str(cont2*100/nf(1)) + " %");
disp("Falsos negativos = " + falsosNegativos);
disp("Falsos positivos = " + falsosPositivos);




