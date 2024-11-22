function simula_frequencia()
    % Diretório base dos modelos
    base_dir = fullfile(pwd, 'Simulink');
    model_prefix = 'projeto_';

    % Lista dos modelos para simulação e seus parâmetros Kp e Ki
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    tipo_linha = {'m-', 'b-', 'g-', 'c-'};
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
    
    % Figura para o gráfico de frequência
    figure;
    hold on;
    for i = 1:length(modelos)
        % Extrair o nome simples do modelo para a legenda
        [nome_simples, ~] = strtok(modelos{i}, '_');
        % Plotar a frequência da rede e do PLL
        freq_rede = freq_data{i}(:, 1);
        freq_pll = freq_data{i}(:, 2);
        if i == 1
            plot(time, freq_rede, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Frequência da Rede');
        end
        plot(time, freq_pll, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['Frequência ' nome_simples]);
    end
    xlabel('Tempo (s)');
    ylabel('Frequência (Hz)');
    title('Respostas dos PLLs e Frequência da Rede');
    legend;
    grid on;
    hold off;

    % Figura para os gráficos de tensão Vs e Vta com subplots
    figure;
    subplot(2, 2, [1 2]);
    hold on;
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        if i == 1
            plot(time, Vsa_values{i}, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{sa}');
        end
        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['V_{ta} ' nome_simples]);
    end
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Tensões V_s e V_{ta} para cada PLL');
    legend;
    grid on;
    hold off;

    % Subplot com zoom em 0.2 s e 0.4 s
    subplot(2, 2, 3);
    hold on;
    for i = 1:length(modelos)
        if i == 1
            plot(time, Vsa_values{i}, 'r--', 'LineWidth', 1.5);
        end
        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0);
    end
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Zoom em torno de 0.24 s');
    xlim([0.14 0.34]);
    grid on;
    hold off;

    subplot(2, 2, 4);
    hold on;
    for i = 1:length(modelos)
        if i == 1
            plot(time, Vsa_values{i}, 'r--', 'LineWidth', 1.5);
        end
        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0);
    end
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Zoom em torno de 0.44 s');
    xlim([0.34 0.54]);
    grid on;
end
