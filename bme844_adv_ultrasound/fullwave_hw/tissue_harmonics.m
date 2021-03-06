clear all; close all; clc;

load harmonic_ppw20_ba7.mat
% load harmonicfoc_ppw17_ba8.mat
% load data_p3.mat
n = 1:size(rf,1);
N_fft = 128;

win = buffer(n,N_fft,round(9*N_fft/10));
[~, j] = find(win == 0);
j = unique(j);
win(:,j) = [];
z_i = win(round(size(win,1)/2),:);

t = 2*deps/c0;
T = unique(diff(t));
fs = 1/T(1);
% fs = 1/dT;
f = fs.*linspace(0,1,size(win,1));

fvar = 0.2e6;
filt_f0 = gaussmf(f,[fvar f0*1e6]);
filt_f1 = gaussmf(f,[fvar f0*2e6]);

figure
for i = 1:size(win,2)
    % hanning window for each frequency window
    scale_win = repmat(hann(size(win,1)),[1 size(rf,2)]);
%     scale_win = repmat(ones(size(win,1),1),[1 size(rf,2)]);
    winfft = abs(fft(scale_win.*rf(win(:,i),:),[],1)/N_fft);
    norm_winfft = zeros(size(winfft));
    for line = 1:size(winfft,2)
        tmp = winfft(:,line);
        % normalize window at each depth so that energy is not dependent on
        % attenuation of amplitude of echoes
        norm_winfft(:,line) = tmp./max(tmp(:));
        norm_winfftf0(:,line) = 2.*(filt_f0'.*tmp);
        norm_winfftf1(:,line) = 2.*(filt_f1'.*tmp);
    end
    tot_winfftf0 = sum(norm_winfftf0,2);
    tot_winfftf1 = sum(norm_winfftf1,2);
    tot_winfft = sum(norm_winfft,2);
    
%     f0_E(i) = sum(filt_f0'.*tot_winfft);
%     f1_E(i) = sum(filt_f1'.*tot_winfft);
    f0_E(i) = sum(tot_winfftf0);
    f1_E(i) = sum(tot_winfftf1);
    
    clf
    hold on
    plot(f,tot_winfft);
    plot(f,filt_f0,'g');
    plot(f,filt_f1,'r');
    hold off
    xlabel('Frequency')
    ylabel('Magnitude')
    drawnow; 
%     pause(0.5)
end

figure
hold on
plot(1000.*deps(z_i),f0_E, '-');
plot(1000.*deps(z_i),f1_E,'r--');
hold off
xlabel('Depth (mm)')
ylabel('Energy')
legend('Fundamental','Harmonic')
print -djpeg ./fig3a_WillieLong.jpg

figure
plot(1000.*deps(z_i),f1_E,'r--');
xlabel('Depth (mm)')
ylabel('Energy')
print -djpeg ./fig3a_harmonic_WillieLong.jpg

foc=round(nZ/1.3)*dZ

BW = 1;
order = 2;
[f0b f0a] = butter(order,[f0-BW/2 f0+BW/2]/(fs/2e6),'bandpass');
[f1b f1a] = butter(order,[2*f0-BW/2 2*f0+BW/2]/(fs/2e6),'bandpass');
f = fs.*linspace(0,1,size(rf,1));
for j = 1:size(rf,2)
    f0_rf(:,j) = filter(f0b,f0a,rf(:,j));
    f1_rf(:,j) = filter(f1b,f1a,rf(:,j));
end

f0_env = abs(hilbert(f0_rf));
f1_env = abs(hilbert(f1_rf));
env = abs(hilbert(rf));

figure
subplot(131)
imagesc(1e3*bws,1e3*deps,20*log10(env/max(env(:))),[-40 0]); 
colormap gray; axis image
xlabel('y (mm)'), ylabel('z (mm)'); title('Raw')
subplot(132)
imagesc(1e3*bws,1e3*deps,20*log10(f0_env/max(f0_env(:))),[-40 0]); 
colormap gray; axis image
xlabel('y (mm)'), ylabel('z (mm)'); title('Fundamental')
subplot(133)
imagesc(1e3*bws,1e3*deps,20*log10(f1_env/max(f1_env(:))),[-40 0]); 
colormap gray; axis image
xlabel('y (mm)'), ylabel('z (mm)'); title('Harmonic')

print -djpeg ./fig3b_WillieLong.jpg

les_i = 1100:1240;
les_j = 4:7;

bg_i = 800:940;
bg_j = 4:6;

tmp = env(les_i,les_j);
u_les = mean(tmp(:));
s_les = var(tmp(:));

tmp = env(bg_i,bg_j);
u_bg = mean(tmp(:));
s_bg = var(tmp(:));

CNR = abs(u_bg-u_les)/sqrt(s_les+s_bg)

tmp = f0_env(les_i,les_j);
f0u_les = mean(tmp(:));
f0s_les = var(tmp(:));

tmp = f0_env(bg_i,bg_j);
f0u_bg = mean(tmp(:));
f0s_bg = var(tmp(:));

f0CNR = abs(f0u_bg-f0u_les)/sqrt(f0s_les+f0s_bg)

tmp = f1_env(les_i,les_j);
f1u_les = mean(tmp(:));
f1s_les = var(tmp(:));

tmp = f1_env(bg_i,bg_j);
f1u_bg = mean(tmp(:));
f1s_bg = var(tmp(:));

f1CNR = abs(f1u_bg-f1u_les)/sqrt(f1s_les+f1s_bg)
