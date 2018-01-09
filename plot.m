close all; clear; clc

M = csvread('data.csv');
M = M';
boxplot(M)

[m, n] = size(M);
for i = 2:n
  figure
  histogram(M(:,i))
end
