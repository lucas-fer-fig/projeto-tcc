%======================================================================
% Arquivo Principal - main.m
%======================================================================
clc;
clear;
close all;

% Configura��o do cache do Simulink
Simulink.fileGenControl('set', 'CacheFolder', fullfile(pwd, 'Simulink/Cache'));

% Par�metros gerais da simula��o
Vdc = 1450;
Vp = 127 * sqrt(2);
fs = 60;
R = 1.63e-3;
L = 100e-6;
Ibase = 2;

% Execu��o das simula��es
simula_frequencia();
simula_tensao_pu();
calcula_IAE_ISE();

% Resetar configura��o do cache do Simulink
Simulink.fileGenControl('reset');
