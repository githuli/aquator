[A, MAP, ALPHA] =  imread('../../res/bg/layer1.png');
D = bwdist(ALPHA);
D(D>255)=255;
D=uint8(round(D));
imshow(D);
imwrite(D,'layer1-dist.png');
