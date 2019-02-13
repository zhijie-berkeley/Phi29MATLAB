function out = drawimageV2(pos, grn)
%Renders a Lumicks image from the InfoWave (pos, uint8 array) and photoncount (grn, uint32 array).
%If the image is a kymograph or movie, set iskymo = 1 to skip the last line, as it is probably incomplete (could take it, but code won't do it yet)
%V2: Assumes pixel time is the same, so get via sum(reshape) instead of for loop. ~10X speedup

%Might be expected to discard data when pos == 2, as assumedly the laser is moving, but eh keep, difference probably negligible

%Line starts when pos goes from 0 to 1 (on the 1, so add 1)
lnstarts = find(pos(1:end-1) == 0 & pos(2:end) == 1) + 1;
%Line ends when pos goes from 2 to 0 (on the 2), or at eof
lnends = [find(pos(1:end-1) == 2 & pos(2:end) == 0); length(pos)];
%ExtractLine is a sample line scan, so we can find out scan dimensions (without reading metadata)
exln = pos(lnstarts(1):lnstarts(2));
%Length of line, in pixels: A pixel ends when pos goes from 1 to 2. Probably the same as sum(exln == 2).
len = sum( exln(1:end-1) == 1 & exln(2:end) == 2);
%Size of pixel, in samples, i.e. the length from start to the first pixel end (first 2)
lnwid = find(exln == 2, 1);
%Height is number of lines
hei = length(lnstarts); %Last line might be unfinished, see below
%Preallocate
out = zeros(len, hei);

for i = 1:hei
    if i == hei %Last line might be unfinished, handle specially. Actually works for every line, but slower (~30%)
        %Pad the end of the last line with extra zeroes to make it of size lnwid*len 
        out(:, i) = sum( reshape([grn(lnstarts(i):lnends(i)); zeros(len*lnwid-(lnends(i)-lnstarts(i)+1),1)], lnwid, len), 1);
    else
        %Snip relevant part of grn, reshape & sum to get pixel value (integrated photon count)
        out(:, i) = sum( reshape(grn(lnstarts(i):lnends(i)) , lnwid, len), 1);
    end    
end

% figure, imshow(out)