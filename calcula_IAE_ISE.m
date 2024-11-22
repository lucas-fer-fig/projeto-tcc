function calcula_IAE_ISE()
    % Diret�rio base dos modelos
    base_dir = fullfile(pwd, 'Simulink');  % Usa o diret�rio de trabalho atual e 'Simulink'
    model_prefix = 'projeto_';

    % Lista dos modelos para simula��o e seus par�metros Kp e Ki
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    freq_teste_values = [2, 4, 6, 8, 10, 12]; % Valores de freq_teste a serem testados
    sim_time = 0.6; % Tempo total de simula��o em segundos
    mid_time = sim_time / 2; % Metade do tempo de simula��o

    % Pr�-alocar c�lulas para resultados organizados para cada modelo e frequ�ncia
    resultados = cell(length(modelos) * length(freq_teste_values), 4);
    IAE_values = zeros(length(modelos), length(freq_teste_values));
    ISE_values = zeros(length(modelos), length(freq_teste_values));
    row = 1;

    % Executar a simula��o para cada modelo e calcular ISE e IAE para cada freq_teste
    for i = 1:length(modelos)
        model_name = [model_prefix modelos{i}];
        modelo_atual = fullfile(base_dir, model_name);
        
        % Carregar o sistema do modelo se n�o estiver carregado
        if ~bdIsLoaded(model_name)
            load_system(modelo_atual);
        end

        % Caminho dos blocos com `/`
        bloco_Kp = [model_name '/PLL/Kp_' modelos{i}];
        bloco_Ki = [model_name '/PLL/Ki_' modelos{i}];
        bloco_en_teste = [model_name '/Barra Infinita/Frequ�ncia da rede/en_teste'];
        bloco_freq_teste = [model_name '/Barra Infinita/Frequ�ncia da rede/freq_teste'];

        % Definir o valor do par�metro en_teste para 1
        set_param(bloco_en_teste, 'Value', '1');

        % Definir os par�metros Kp e Ki espec�ficos para cada modelo
        set_param(bloco_Kp, 'Gain', num2str(Kp_values(i)));
        set_param(bloco_Ki, 'Gain', num2str(Ki_values(i)));

        % Loop para cada valor de freq_teste
        for j = 1:length(freq_teste_values)
            freq_teste = freq_teste_values(j);

            % Definir o valor inicial do par�metro freq_teste para 0
            set_param(bloco_freq_teste, 'Value', '0');

            % Executar a simula��o at� a metade
            simOut = sim(modelo_atual, 'StopTime', num2str(mid_time));
            time1 = simOut.(['freq_' modelos{i}]).time; % Tempo at� a metade
            freq_data1 = simOut.(['freq_' modelos{i}]).signals.values; % Dados de frequ�ncia

            % Alterar o valor do par�metro freq_teste para o valor do intervalo
            set_param(bloco_freq_teste, 'Value', num2str(freq_teste));

            % Continuar a simula��o para o restante do tempo
            simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));
            time2 = simOut.(['freq_' modelos{i}]).time; % Tempo restante
            freq_data2 = simOut.(['freq_' modelos{i}]).signals.values; % Dados de frequ�ncia

            % Concatenar os tempos e dados
            time = [time1; time2 + mid_time];
            freq_data = [freq_data1; freq_data2];

            % Determinar o �ndice correspondente a 90% de mid_time
            start_idx = find(time >= 0.9 * mid_time, 1);

            % Restri��o dos dados ao intervalo desejado
            time_interval = time(start_idx:end);
            freq_rede_interval = freq_data(start_idx:end, 1); % Frequ�ncia da rede
            freq_pll_interval = freq_data(start_idx:end, 2);  % Frequ�ncia do PLL
            erro_interval = freq_rede_interval - freq_pll_interval;

            % Calcular ISE e IAE para o intervalo
            ISE = trapz(time_interval, erro_interval.^2);       % Integral do erro ao quadrado
            IAE = trapz(time_interval, abs(erro_interval));     % Integral do valor absoluto do erro

            % Armazenar os resultados
            IAE_values(i, j) = IAE;
            ISE_values(i, j) = ISE;

            % Preencher a tabela de resultados
            if j == 1
                resultados{row, 1} = modelos{i};  % Nome do modelo s� na primeira linha do bloco
            else
                resultados{row, 1} = '';  % Linhas subsequentes vazias para "Metodo"
            end
            resultados{row, 2} = freq_teste;      % Freq_Teste
            resultados{row, 3} = IAE;             % IAE
            resultados{row, 4} = ISE;             % ISE
            row = row + 1;                        % Pr�xima linha
        end
    end
    
    % Fechar os modelos
    for i = 1:length(modelos)
        close_system([model_prefix modelos{i}], 0);
    end

    % Criar e exibir a tabela de resultados ISE e IAE
    resultados_table = cell2table(resultados, 'VariableNames', {'Metodo', 'Delta_f', 'IAE', 'ISE'});

    % Criar uma nova janela para exibir a tabela
    f = figure('Name', 'Resultados de IAE e ISE para os testes de varia��o de frequ�ncias', 'NumberTitle', 'off', 'Position', [100, 100, 600, 300]);
    uitable('Parent', f, 'Data', table2cell(resultados_table), 'ColumnName', resultados_table.Properties.VariableNames, ...
            'RowName', [], 'Units', 'normalized', 'Position', [0, 0, 1, 1]);

    % Criar uma nova janela para os gr�ficos
    figure('Name', 'IAE e ISE em fun��o de Delta_f', 'NumberTitle', 'off');

    % Gr�fico 1: IAE
    subplot(1, 2, 1);
    hold on;
    markers = {'o-', 's-', 'd-', '^-'}; % Marcadores para cada modelo
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        % Adicionar marcador espec�fico para cada modelo
        plot(freq_teste_values, IAE_values(i, :), markers{i}, 'DisplayName', nome_simples, 'LineWidth', 1.5);
    end
    hold off;
    xlabel('\Delta f (Hz)');
    ylabel('IAE');
    title('IAE vs \Delta f');
    legend('Location', 'northwest');
    grid on;

    % Gr�fico 2: ISE
    subplot(1, 2, 2);
    hold on;
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        % Adicionar marcador espec�fico para cada modelo
        plot(freq_teste_values, ISE_values(i, :), markers{i}, 'DisplayName', nome_simples, 'LineWidth', 1.5);
    end
    hold off;
    xlabel('\Delta f (Hz)');
    ylabel('ISE');
    title('ISE vs \Delta f');
    legend('Location', 'northwest');
    grid on;
end
