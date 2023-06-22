clear

% VARIABLES
L = 200; % Valor del paper L = 200
r= 175; %Valor del paper r = 175
alpha = 10; % Valor del paper alpha = 5
rot = 0;
nomArxiu = "imatges/degas_2gray";
ext = ".png";
fileID = fopen("marques/marca23.txt",'r'); %Llegeix bits de la marca
imDef = 10000; % def imatges (nomes serveix x mostrar visualment els coef de mag)

% Preparo la imatge per marcar
im = imread(nomArxiu+".png");           % Llegeixo la imatge per marcar

if (rot ~= 0)
    im = imrotate(im,rot);
    nomArxiu = nomArxiu+"Rot"+rot;
end

try
    im = rgb2gray(im);
catch
    
end


% Passo la imatge per marcar a escala de grisos
%imwrite(im, 'degas_2gray.png');
imOr = im;

% Transformo la imatge al domini de Fourier
imDFT = fft2(im); 
imDFTshift = fftshift(imDFT); % Traslladem els coeficients de baixa freqüència al centre

% Separem els coeficients de magnitud dels coeficients de fase
coefMag = abs(imDFTshift); % Mòdul o magnitud complexa 
coefPhase = angle(imDFTshift); % Angle de fase

% Generem un vector binari aleatori de dimensio l (la marca) a partir de la
% ey k
[v,count] = fscanf(fileID, ['%5d\n']);
fclose(fileID);

% Definim marca
wm = zeros (size(coefMag));
[M,N] = size(coefMag);

for k = 1:L
    % Marca L punts distribuïts uniformemente entre [-pi,pi] (comença per
    % -pi!) en el radi r
    x = fix(M/2+1)+fix(r*cos(k*pi/L));
    y = fix(N/2+1)+fix(r*sin(k*pi/L));
    
    for s =-1:1
        for t=-1:1
            wm(x,y)= wm(x,y) + coefMag(x+s,y+t);
        end
    end
    
    wm(x,y) = v(k)*wm(x,y)/9;
end

% Omple el costat esquerra de la matriu amb simetria inversa
for m= 1:M
    for n = 1:fix(N/2)
        wm(m,n) = wm(M+1-m,N+1-n);
    end
end

% Incrustem la marca en la matriu
coefMagWM = coefMag + alpha * wm;

% Combinem els coeficients de magnitud amb els coeficients de fase
imDFTwm = zeros(size(coefMagWM));
for m = 1:M
    for n = 1:N
        imDFTwm(m,n) = coefMagWM(m,n)*exp(i*coefPhase(m,n));
    end
end

% Transforma de nou al domini espacial (Inverteix la transformada de
% Fourier)
imWM = ifft2(ifftshift(imDFTwm)); 
imWM = uint8(real(imWM));


%{
imshow(imOr,[]); title('Original')
figure(2)
Fs = log(coefMag+1);
imshow(Fs,[]); title('Coef Mag Original')
figure(3)
Fw = log(abs(imDFTwm)+1);
imshow(coefPhase,[]); title('Coef Fase Original')
figure(4)
Fw = log(abs(wm)+1);
imshow(Fw,[]); title('Watermark')
figure(5)
Fw = log(abs(coefMagWM)+1);
imshow(Fw,[]); title('Coef Mag WM')
figure(6)
imshow(imWM,[]); title('Image WM')
%}
imwrite(imWM, nomArxiu+"_L"+L+"_r"+r+"_alpha"+alpha+".png");


figure(1)
subplot(2,2,1); imshow(imOr); title('Original Image');
subplot(2,2,2); imshow(imWM); title('WM Image');

Fs = mat2gray(coefMag,[0 imDef]);
subplot(2,2,3); imshow(Fs,[]); title('Coef Mag Original');

Fs = mat2gray(coefMagWM,[0 imDef]);
subplot(2,2,4); imshow(Fs,[]); title('Coef Mag Image WM');

%}


% TESTING

%Extreu els radis
%{
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
%}
%{
radii = zeros(1,L);


for k = 1:L
    x = fix(M/2+1)+fix(r*cos(k*pi/L)); %És possible q estigui llegint el vector del reves
    y = fix(N/2+1)+fix(r*sin(k*pi/L));
    radii(1,k) = coefMagWM(x,y);
end 

% Normalitzem els vectors
arrayNr= normalize(radii,'range');


% Comparem els vectors de la imatge amb 100 marques diferents
numberfiles = 500;
arrayCov = zeros(1,numberfiles);
for k = 1:numberfiles
    string = "marques/marca" + k + ".txt";
    fileID = fopen(string,'r');
    [v,count] = fscanf(fileID, ['%5d\n']);
    fclose(fileID);
    arrayCov(1,k)=max(xcov(v,arrayNr));
end

figure(3)
plot(arrayCov);
%}
