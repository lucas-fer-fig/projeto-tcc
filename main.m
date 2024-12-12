%======================================================================
% Arquivo Principal - main.m
%======================================================================
clc;
clear;
close all;

% Configuração do cache do Simulink
Simulink.fileGenControl('set', 'CacheFolder', fullfile(pwd, 'Simulink/Cache'));

% Parâmetros gerais da simulação
Vdc = 1450;
Vp = 127 * sqrt(2);
fs = 60;
R = 1.63e-3;
L = 100e-6;
Ibase = 2;

% Execução das simulações
simula_frequencia();
simula_tensao_pu();
calcula_IAE_ISE();

% Resetar configuração do cache do Simulink
Simulink.fileGenControl('reset');
