function [time, freq_data, Vsa_values, Vta_values] = simula_modelos()
    % Diretório base dos modelos
    base_dir = fullfile(pwd, 'Simulink');
    model_prefix = 'projeto_';

    % Lista dos modelos para simulação e seus parâmetros Kp e Ki
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    sim_time = 0.6; % Tempo total de simulação em segundos

    % Pré-alocar variáveis para armazenar dados
    freq_data = cell(1, length(modelos));
    Vsa_values = cell(1, length(modelos));
    Vta_values = cell(1, length(modelos));
    
    % Executar a simulação para cada modelo
    for i = 1:length(modelos)
        model_name = [model_prefix modelos{i}];
        modelo_atual = fullfile(base_dir, model_name);
        
        % Carregar o sistema do modelo se não estiver carregado
        if ~bdIsLoaded(model_name)
            load_system(modelo_atual);
        end

        % Caminho dos blocos com `/`
        bloco_Kp = [model_name '/PLL/Kp_' modelos{i}];
        bloco_Ki = [model_name '/PLL/Ki_' modelos{i}];

        % Definir os parâmetros Kp e Ki específicos para cada modelo
        set_param(bloco_Kp, 'Gain', num2str(Kp_values(i)));
        set_param(bloco_Ki, 'Gain', num2str(Ki_values(i)));

        % Executar a simulação e salvar as saídas na variável simOut
        simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));

        % Acessar os dados diretamente de simOut
        time = simOut.(['freq_' modelos{i}]).time; % Tempo dos dados
        freq_data{i} = simOut.(['freq_' modelos{i}]).signals.values; % Valores do sinal

        % Extrair valores de Vs (Vsa) e Vt (Vta) e corrente Ia
        Vsa_values{i} = simOut.(['Va_' modelos{i}]).signals.values(:, 2); % Vsa
        Vta_values{i} = simOut.(['Va_' modelos{i}]).signals.values(:, 1); % Vta
    end
    
    % Fechar os modelos
    for i = 1:length(modelos)
        close_system(model_name, 0);
    end
end
