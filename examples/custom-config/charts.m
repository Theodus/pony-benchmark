close all; clear; clc

M = csvread('data.csv');
M = M';
overhead = median(M(:,1));
ops = M(:,2:end);
pows = 0:1:20;
sizes = 2.^pows;

%% box plot
boxplot(ops-overhead)
grid on
xticklabels('2^'+string(pows))
title('Persistent Vec Apply')
xlabel('size')
ylabel('runtime (ns)')
ax = gca;
ax.FontSize = 24;

%% histogram
figure
idxs = fliplr(1+5:5:21);
for i = idxs
    histogram(ops(:,i)-overhead)
    hold on
end
title('Histogram of Persistent Vec Apply (sizes 32^n)')
legend('size ' + string(sizes(idxs)))
xlabel('runtime (ns)')
ylabel('occurences')
ax = gca;
ax.FontSize = 24;
