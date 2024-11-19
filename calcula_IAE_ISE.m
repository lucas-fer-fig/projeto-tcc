function calcula_IAE_ISE()
    % Diretório base dos modelos
    base_dir = fullfile(pwd, 'Simulink');  % Usa o diretório de trabalho atual e 'Simulink'
    model_prefix = 'projeto_';

    % Lista dos modelos para simulação e seus parâmetros Kp e Ki
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    freq_teste_values = [2, 4, 6, 8, 10, 12]; % Valores de freq_teste a serem testados
    sim_time = 0.6; % Tempo total de simulação em segundos
    mid_time = sim_time / 2; % Metade do tempo de simulação

    % Pré-alocar células para resultados organizados para cada modelo e frequência
    resultados = cell(length(modelos) * length(freq_teste_values), 4);
    row = 1;

    % Para plotagem: armazenar dados para subplot
    pll_responses = cell(length(modelos), length(freq_teste_values));
    rede_responses = cell(length(modelos), length(freq_teste_values));
    time_vector = [];

    % Executar a simulação para cada modelo e calcular ISE e IAE para cada freq_teste
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
        bloco_en_teste = [model_name '/Barra Infinita/Frequência da rede/en_teste'];
        bloco_freq_teste = [model_name '/Barra Infinita/Frequência da rede/freq_teste'];

        % Definir o valor do parâmetro en_teste para 1
        set_param(bloco_en_teste, 'Value', '1');

        % Definir os parâmetros Kp e Ki específicos para cada modelo
        set_param(bloco_Kp, 'Gain', num2str(Kp_values(i)));
        set_param(bloco_Ki, 'Gain', num2str(Ki_values(i)));

        % Loop para cada valor de freq_teste
        for j = 1:length(freq_teste_values)
            freq_teste = freq_teste_values(j);

            % Definir o valor inicial do parâmetro freq_teste para 0
            set_param(bloco_freq_teste, 'Value', '0');

            % Executar a simulação até a metade
            simOut = sim(modelo_atual, 'StopTime', num2str(mid_time));
            time1 = simOut.(['freq_' modelos{i}]).time; % Tempo até a metade
            freq_data1 = simOut.(['freq_' modelos{i}]).signals.values; % Dados de frequência

            % Alterar o valor do parâmetro freq_teste para o valor do intervalo
            set_param(bloco_freq_teste, 'Value', num2str(freq_teste));

            % Continuar a simulação para o restante do tempo
            simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));
            time2 = simOut.(['freq_' modelos{i}]).time; % Tempo restante
            freq_data2 = simOut.(['freq_' modelos{i}]).signals.values; % Dados de frequência

            % Concatenar os tempos e dados
            time = [time1; time2 + mid_time];
            freq_data = [freq_data1; freq_data2];

            % Determinar o índice correspondente a 90% de mid_time
            start_idx = find(time >= 0.9 * mid_time, 1);

            % Restrição dos dados ao intervalo desejado
            time_interval = time(start_idx:end);
            freq_rede_interval = freq_data(start_idx:end, 1); % Frequência da rede
            freq_pll_interval = freq_data(start_idx:end, 2);  % Frequência do PLL
            erro_interval = freq_rede_interval - freq_pll_interval;

            % Armazenar resposta para plotagem
            pll_responses{i, j} = freq_pll_interval; % Frequência do PLL
            rede_responses{i, j} = freq_rede_interval; % Frequência da Rede
            if isempty(time_vector)
                time_vector = time_interval; % Armazenar tempo uma única vez
            end

            % Calcular ISE e IAE para o intervalo
            ISE = trapz(time_interval, erro_interval.^2);       % Integral do erro ao quadrado
            IAE = trapz(time_interval, abs(erro_interval));     % Integral do valor absoluto do erro

            % Armazenar os resultados com a estrutura da tabela de exemplo
            if j == 1
                resultados{row, 1} = modelos{i};  % Nome do modelo só na primeira linha do bloco
            else
                resultados{row, 1} = '';  % Linhas subsequentes vazias para "Metodo"
            end
            resultados{row, 2} = freq_teste;      % Freq_Teste
            resultados{row, 3} = IAE;             % IAE
            resultados{row, 4} = ISE;             % ISE
            row = row + 1;                        % Próxima linha
        end
    end
    
    % Fechar os modelos
    for i = 1:length(modelos)
        close_system([model_prefix modelos{i}], 0);
    end

    % Criar e exibir a tabela de resultados ISE e IAE
    resultados_table = cell2table(resultados, 'VariableNames', {'Metodo', 'Delta_f', 'IAE', 'ISE'});

    % Criar uma nova janela para exibir a tabela
    f = figure('Name', 'Resultados de IAE e ISE para os testes de variação de frequências', 'NumberTitle', 'off', 'Position', [100, 100, 600, 300]);
    uitable('Parent', f, 'Data', table2cell(resultados_table), 'ColumnName', resultados_table.Properties.VariableNames, ...
            'RowName', [], 'Units', 'normalized', 'Position', [0, 0, 1, 1]);

    % Criar subplot para respostas
    figure('Name', 'Respostas dos PLLs e da Rede para os testes de variação de frequências', 'NumberTitle', 'off');
    for i = 1:length(modelos)
        for j = 1:length(freq_teste_values)
            % Determinar o índice correspondente a 90% de mid_time
            start_idx = find(time_vector >= 0.9 * mid_time, 1);
            end_idx = find(time_vector <= sim_time, 1, 'last');

            % Restringir os dados ao intervalo desejado
            time_interval = time_vector(start_idx:end_idx);
            pll_interval = pll_responses{i, j}(start_idx:end_idx);
            rede_interval = rede_responses{i, j}(start_idx:end_idx);

            % Criar o subplot
            subplot(length(modelos), length(freq_teste_values), (i - 1) * length(freq_teste_values) + j);
            plot(time_interval, pll_interval, 'b', 'LineWidth', 1.0, 'DisplayName', 'PLL');
            hold on;
            plot(time_interval, rede_interval, 'r--', 'LineWidth', 1.0, 'DisplayName', 'Rede');
            xlabel('Tempo (s)');
            ylabel('Frequência (Hz)');
            [nome_simples, ~] = strtok(modelos{i}, '_');
            title(sprintf('%s, \\Deltaf = %d', nome_simples, freq_teste_values(j)), 'Interpreter', 'tex');
            legend;
            grid on;

            % Ajustar a janela do gráfico para o intervalo desejado
            xlim([0.9 * mid_time, sim_time]);
            ylim([0.98*min([pll_interval; rede_interval]), 1.02*max([pll_interval; rede_interval])]);

            hold off;
        end
    end
end
