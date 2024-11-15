%==========================================================================
% Arquivo Principal - main.m
%==========================================================================
clc;
clear;
close all;

% Configurar o cache do Simulink para a pasta 'Simulink/cache'
Simulink.fileGenControl('set', 'CacheFolder', fullfile(pwd, 'Simulink/Cache'));

% Configurações da simulação
Vdc = 1450;
Vp = 127 * sqrt(2);
fs = 60;
Ts = 1 / fs;
R = 1.63e-3;
L = 100e-6;
Ibase = 2;

[time, freq_data, Vsa_values, Vta_values, Ia_values] = simula_modelos();
plota_graficos(time, freq_data, Vsa_values, Vta_values, Ia_values);

calcula_IAE_ISE();

% Resetar a configuração de cache do Simulink para o padrão
Simulink.fileGenControl('reset');
