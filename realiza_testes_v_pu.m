function realiza_testes_v_pu()
    % Diretório base dos modelos
    base_dir = fullfile(pwd, 'Simulink');  % Usa o diretório de trabalho atual e 'Simulink'
    model_prefix = 'projeto_';

    % Lista dos modelos para simulação e seus parâmetros Kp e Ki
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    tipo_linha = {'m-', 'b-', 'g-', 'c-'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    sim_time = 0.6; % Tempo total de simulação em segundos

    % Pré-alocar variáveis para resultados
    source_voltage = cell(2, 1); % Armazena tensões da fonte para os dois testes
    vta_voltage = cell(2, length(modelos)); % Armazena tensões Vta para os dois testes
    time_vector = cell(2, 1); % Armazena os tempos para os dois testes

    % Caminhos dos blocos adicionais
    bloco_en_teste_v_pu_path = '/Barra Infinita/Amplitude da Rede/en_teste_v_pu';
    bloco_teste_v_pu_path = '/Barra Infinita/Amplitude da Rede/teste_v_pu';

    % Executar os testes para cada configuração de tensão
    for test = 1:2
        for i = 1:length(modelos)
            model_name = [model_prefix modelos{i}];
            modelo_atual = fullfile(base_dir, model_name);

            % Carregar o sistema do modelo se não estiver carregado
            if ~bdIsLoaded(model_name)
                load_system(modelo_atual);
            end

            % Caminhos dos blocos
            bloco_Kp = [model_name '/PLL/Kp_' modelos{i}];
            bloco_Ki = [model_name '/PLL/Ki_' modelos{i}];
            bloco_en_teste = [model_name '/Barra Infinita/Frequência da rede/en_teste'];
            bloco_en_teste_v_pu = [model_name bloco_en_teste_v_pu_path];
            bloco_teste_v_pu = [model_name bloco_teste_v_pu_path];
            
            % Definir o valor do parâmetro en_teste para 1
            set_param(bloco_en_teste, 'Value', '1');

            % Configurar parâmetros específicos para cada modelo
            set_param(bloco_Kp, 'Gain', num2str(Kp_values(i)));
            set_param(bloco_Ki, 'Gain', num2str(Ki_values(i)));
            set_param(bloco_en_teste_v_pu, 'Value', '1');
            set_param(bloco_teste_v_pu, 'Value', num2str(test - 1)); % 0 para o primeiro teste, 1 para o segundo

            % Executar a simulação
            simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));
            time = simOut.(['Va_' modelos{i}]).time;
            vta_data = simOut.(['Va_' modelos{i}]).signals.values(:, 1); % Dados de tensão Vta

            % Armazenar os resultados para cada modelo
            if i == 1
                source_data = simOut.(['Va_' modelos{i}]).signals.values(:, 2); % Tensão da fonte
                source_voltage{test} = source_data; % Apenas uma vez para a fonte
                time_vector{test} = time; % Apenas uma vez para o tempo
            end
            vta_voltage{test, i} = vta_data;
        end
    end

    % Criar a figura para os gráficos
    figure('Name', 'Testes com variação de tensão em PU', 'NumberTitle', 'off');

    % Gráfico superior (Teste 1)
    subplot(3, 2, [1 2]);
    hold on;
    plot(time_vector{1}, source_voltage{1}, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{sa}');
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(time_vector{1}, vta_voltage{1, i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['V_{ta} ' nome_simples]);
    end
    hold off;
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Variação com Teste 1: 90% V_p');
    legend;
    grid on;

    % Gráfico inferior (Teste 2)
    subplot(3, 2, [3 4]);
    hold on;
    plot(time_vector{2}, source_voltage{2}, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{sa}');
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(time_vector{2}, vta_voltage{2, i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['V_{ta} ' nome_simples]);
    end
    hold off;
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Variação com Teste 2: 110% V_p');
    legend;
    grid on;

    % Zoom do primeiro gráfico (Teste 1)
    subplot(3, 2, 5);
    hold on;
    plot(time_vector{1}, source_voltage{1}, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{sa}');
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(time_vector{1}, vta_voltage{1, i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['V_{ta} ' nome_simples]);
    end
    hold off;
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Zoom - Teste 1: 90% V_p');
    xlim([0.25 0.35]); % Ajuste para centrar o zoom em 0.3
    grid on;

    % Zoom do segundo gráfico (Teste 2)
    subplot(3, 2, 6);
    hold on;
    plot(time_vector{2}, source_voltage{2}, 'r--', 'LineWidth', 1.5, 'DisplayName', 'V_{sa}');
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(time_vector{2}, vta_voltage{2, i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['V_{ta} ' nome_simples]);
    end
    hold off;
    xlabel('Tempo (s)');
    ylabel('Tensão (V)');
    title('Zoom - Teste 2: 110% V_p');
    xlim([0.25 0.35]); % Ajuste para centrar o zoom em 0.3
    grid on;

    % Fechar os modelos
    for i = 1:length(modelos)
        close_system([model_prefix modelos{i}], 0);
    end
end
