function calcula_IAE_ISE()
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    freq_teste_values = [2, 4, 6, 8, 10, 12];
    sim_time = 0.6;

    [IAE_values, ISE_values, pll_responses, rede_responses, time_vector] = ...
        simula_modelos(modelos, Kp_values, Ki_values, freq_teste_values, sim_time);

    exibe_tabela_resultados(modelos, freq_teste_values, IAE_values, ISE_values);
    plota_graficos_IAE_ISE(modelos, freq_teste_values, IAE_values, ISE_values);
    plota_respostas_PLL(modelos, freq_teste_values, pll_responses, rede_responses, time_vector);
end

function [IAE_values, ISE_values, pll_responses, rede_responses, time_vector] = ...
         simula_modelos(modelos, Kp_values, Ki_values, freq_teste_values, sim_time)

    base_dir = fullfile(pwd, 'Simulink');
    model_prefix = 'projeto_';
    mid_time = sim_time / 2;

    IAE_values = zeros(length(modelos), length(freq_teste_values));
    ISE_values = zeros(length(modelos), length(freq_teste_values));
    pll_responses = cell(length(modelos), length(freq_teste_values));
    rede_responses = cell(length(modelos), length(freq_teste_values));
    time_vector = [];

    for i = 1:length(modelos)
        model_name = [model_prefix modelos{i}];
        modelo_atual = fullfile(base_dir, model_name);
        carregar_modelo(modelo_atual, model_name);

        set_param([model_name '/PLL/Kp_' modelos{i}], 'Gain', num2str(Kp_values(i)));
        set_param([model_name '/PLL/Ki_' modelos{i}], 'Gain', num2str(Ki_values(i)));
        set_param([model_name '/Barra Infinita/Frequência da rede/en_teste'], 'Value', '1');

        for j = 1:length(freq_teste_values)
            freq_teste = freq_teste_values(j);

            set_param([model_name '/Barra Infinita/Frequência da rede/freq_teste'], 'Value', '0');
            simOut1 = sim(modelo_atual, 'StopTime', num2str(mid_time));
            time1 = simOut1.(['freq_' modelos{i}]).time;
            freq_data1 = simOut1.(['freq_' modelos{i}]).signals.values;

            set_param([model_name '/Barra Infinita/Frequência da rede/freq_teste'], 'Value', num2str(freq_teste));
            simOut2 = sim(modelo_atual, 'StopTime', num2str(sim_time));
            time2 = simOut2.(['freq_' modelos{i}]).time;
            freq_data2 = simOut2.(['freq_' modelos{i}]).signals.values;

            time = [time1; time2 + mid_time];
            freq_data = [freq_data1; freq_data2];

            start_idx = find(time >= 0.9 * mid_time, 1);
            time_interval = time(start_idx:end);
            freq_rede_interval = freq_data(start_idx:end, 1);
            freq_pll_interval = freq_data(start_idx:end, 2);
            erro_interval = freq_rede_interval - freq_pll_interval;

            pll_responses{i, j} = freq_pll_interval;
            rede_responses{i, j} = freq_rede_interval;
            if isempty(time_vector)
                time_vector = time_interval;
            end

            ISE_values(i, j) = trapz(time_interval, erro_interval.^2);
            IAE_values(i, j) = trapz(time_interval, abs(erro_interval));
        end

        close_system(model_name, 0);
    end
end

function carregar_modelo(modelo_atual, model_name)
    if ~bdIsLoaded(model_name)
        load_system(modelo_atual);
    end
end

function exibe_tabela_resultados(modelos, freq_teste_values, IAE_values, ISE_values)
    num_models = length(modelos);
    num_frequencies = length(freq_teste_values);
    resultados = cell(num_models * num_frequencies, 4);
    row = 1;

    for i = 1:num_models
        for j = 1:num_frequencies
            if j == 1
                resultados{row, 1} = modelos{i};
            else
                resultados{row, 1} = '';
            end
            resultados{row, 2} = freq_teste_values(j);
            resultados{row, 3} = IAE_values(i, j);
            resultados{row, 4} = ISE_values(i, j);
            row = row + 1;
        end
    end

    resultados_table = cell2table(resultados, 'VariableNames', {'Metodo', 'Delta_f', 'IAE', 'ISE'});

    f = figure('Name', 'Resultados de IAE e ISE', 'NumberTitle', 'off', 'Position', [100, 100, 600, 300]);
    uitable('Parent', f, 'Data', table2cell(resultados_table), ...
            'ColumnName', resultados_table.Properties.VariableNames, ...
            'RowName', [], 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
end

function plota_graficos_IAE_ISE(modelos, freq_teste_values, IAE_values, ISE_values)
    figure('Name', 'IAE e ISE em função de \Delta_f', 'NumberTitle', 'off', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    plota_IAE(modelos, freq_teste_values, IAE_values);
    plota_ISE(modelos, freq_teste_values, ISE_values);
end

function plota_IAE(modelos, freq_teste_values, IAE_values)
    ax1 = subplot(1, 2, 1);
    hold on;
    markers = {'o-', 's-', 'd-', '^-'}; 
    legends = {}; % Inicializa a lista de rótulos
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(freq_teste_values, IAE_values(i, :), markers{i}, 'LineWidth', 1.5);
        legends{end+1} = nome_simples; % Armazena o nome simplificado para a legenda
    end
    hold off;
    xlabel('$\Delta f$ (Hz)', 'FontSize', 16, 'Interpreter', 'latex');
    ylabel('IAE', 'FontSize', 16, 'Interpreter', 'latex');
    legend(legends, 'Location', 'northoutside', 'Orientation', 'horizontal', 'FontSize', 14, 'Interpreter', 'none');
    grid on;
    add_letra(ax1, '(a)');
end

function plota_ISE(modelos, freq_teste_values, ISE_values)
    ax2 = subplot(1, 2, 2);
    hold on;
    markers = {'o-', 's-', 'd-', '^-'}; 
    legends = {}; % Inicializa a lista de rótulos
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(freq_teste_values, ISE_values(i, :), markers{i}, 'LineWidth', 1.5);
        legends{end+1} = nome_simples; % Armazena o nome simplificado para a legenda
    end
    hold off;
    xlabel('$\Delta f$ (Hz)', 'FontSize', 16, 'Interpreter', 'latex');
    ylabel('ISE', 'FontSize', 16, 'Interpreter', 'latex');
    legend(legends, 'Location', 'northoutside', 'Orientation', 'horizontal', 'FontSize', 14, 'Interpreter', 'none');
    grid on;
    add_letra(ax2, '(b)');
end


function plota_respostas_PLL(modelos, freq_teste_values, pll_responses, rede_responses, time_vector)
    figure('Name', 'Respostas de PLLs e Rede', 'NumberTitle', 'off');
    for i = 1:length(modelos)
        for j = 1:length(freq_teste_values)
            subplot(length(modelos), length(freq_teste_values), (i - 1) * length(freq_teste_values) + j);
            pll_data = pll_responses{i, j};
            rede_data = rede_responses{i, j};
            plot(time_vector, pll_data, 'b', 'LineWidth', 1.0, 'DisplayName', 'PLL');
            hold on;
            plot(time_vector, rede_data, 'r--', 'LineWidth', 1.0, 'DisplayName', 'Rede');
            xlabel('Tempo (s)');
            ylabel('Frequência (Hz)');
            [nome_simples, ~] = strtok(modelos{i}, '_');
            title(sprintf('%s, \\Deltaf = %d', nome_simples, freq_teste_values(j)), 'Interpreter', 'tex');
            all_data = [pll_data; rede_data];
            ylim([min(all_data) * 0.99, max(all_data) * 1.01]);
            legend('Location', 'best');
            grid on;
            hold off;
        end
    end
end

function ajustar_limites_verticais(pll_data, rede_data)
    all_data = [pll_data; rede_data];
    ylim([min(all_data) * 0.9, max(all_data) * 1.1]);
end

function add_letra(ax, letra)
    pos = get(ax, 'Position');
    annotation('textbox', [pos(1) + (pos(3)/2) - 0.02, pos(2) - 0.1, 0.04, 0.03], ...
        'String', letra, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
end
