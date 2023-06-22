clear

%VARIABLES
rMin=140; %Valors definits al paper 140
rMax=180; %Valors definits al paper 180
r = 175; 
L = 200; % Valor del paper L = 200
numberfiles = 500;
rot = 0;
low = 0;
high = 0;

% PREPAREM LA IMATGE
% Llegim la imatge que volem testejar
nomArxiu = 'imatges/DALLE3RedChannel_L200_r175_alpha10GreenChannel_L200_r175_alpha10BlueChannel_L200_r175_alpha10.png';
im = imread(nomArxiu); 

if (rot ~= 0)
    im = imrotate(im,rot);
    nomArxiu = nomArxiu+"Rot"+rot+".png";
    imwrite(im, nomArxiu);
end

allBlack = zeros(size(im, 1), size(im, 2), 'uint8');

redChannel = im(:,:,1); % Red channel
recombinedRGBImage = cat(3, redChannel, allBlack, allBlack);
imwrite(recombinedRGBImage, nomArxiu + "_RedChanel.png");

greenChannel = im(:,:,2); % Green channel
recombinedRGBImage = cat(3, allBlack, greenChannel, allBlack);
imwrite(recombinedRGBImage, nomArxiu + "_GreenChanel.png");

blueChannel = im(:,:,3); % Blue channel
recombinedRGBImage = cat(3, allBlack, allBlack, blueChannel);
imwrite(recombinedRGBImage, nomArxiu + "_BlueChanel.png");


im = blueChannel;
nomArxiu= nomArxiu+"testB";

% Redimensionem la imatge al tamany 512x512
% De moment no hem fet aquest cas perque la imatge ja te la mida esperada
[M,N] = size(im);

% DFT
% Transformo la imatge al domini de Fourier
imDFT = fft2(im); 
imDFTshift = fftshift(imDFT);

% EXTRACCIÓ DEL VECTOR
% Separem els coeficients de magnitud dels coeficients de fase
coefMag = abs(imDFTshift); % Mòdul o magnitud complexa 

%Extreu els radis

arrayVectors = zeros(rMax-rMin+1,L);
cont = 1;
for r = rMin:rMax
    aux = zeros(1,L);
    for k = 1:L
        x = fix(M/2+1)+fix(r*cos(k*pi/L)); %És possible q estigui llegint el vector del reves
        y = fix(N/2+1)+fix(r*sin(k*pi/L));
        aux(1,k) = coefMag(x,y);
   
    end 
    arrayVectors(cont,:) = aux;
    
    cont = cont+1;
end

% Normalitzem els vectors
arrayNr = zeros(size(arrayVectors));
for k = 1:rMax-rMin+1
    arrayNr(k,:) = normalize(arrayVectors(k,:),'range');
end

%{
radii = zeros(1,L);


for k = 1:L
    x = fix(M/2+1)+fix(r*cos(k*pi/L)); %És possible q estigui llegint el vector del reves
    y = fix(N/2+1)+fix(r*sin(k*pi/L));
    radii(1,k) = coefMag(x,y);
end 

% Normalitzem els vectors
arrayNr= normalize(radii,'range');
%}

% Comparem els vectors de la imatge amb 100 marques diferents
%{
arrayCov = zeros(1,numberfiles);
for k = 1:numberfiles
    string = "marques/marca" + k + ".txt";
    fileID = fopen(string,'r');
    [v,count] = fscanf(fileID, ['%5d\n']);
    fclose(fileID);
    arrayCov(1,k)=max(xcov(v,arrayNr));
end
%}

arrayCov = zeros(rMax-rMin+1,numberfiles);
for r = 1:rMax-rMin+1
    for k = 1:numberfiles
        string = "marques/marca" + k + ".txt";
        fileID = fopen(string,'r');
        [v,count] = fscanf(fileID, ['%5d\n']);
        fclose(fileID);
        v2 = arrayNr(r,:);
        cov=(xcov(v,arrayNr(r,:)));
        arrayCov(r,k)=max(xcov(v,arrayNr(r,:)));
    end
end

figure(1)
hold on
for r = 1:rMax-rMin+1
    plot(arrayCov(r,:)); 
end

hold off

saveas(1,nomArxiu+"PlotResults"+".png");
