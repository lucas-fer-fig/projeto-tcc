function simula_frequencia()
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    tipo_linha = {'g-', 'b-', 'c-', 'm-'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    sim_time = 0.6;

    [freq_data, Vsa_values, Vta_values, time] = simula_modelos(modelos, Kp_values, Ki_values, sim_time);
    plota_frequencias(freq_data, time, modelos, tipo_linha);
    plota_tensoes(Vsa_values, Vta_values, time, modelos, tipo_linha);
end

function [freq_data, Vsa_values, Vta_values, time] = simula_modelos(modelos, Kp_values, Ki_values, sim_time)
    base_dir = fullfile(pwd, 'Simulink');
    model_prefix = 'projeto_';
    freq_data = cell(1, length(modelos));
    Vsa_values = cell(1, length(modelos));
    Vta_values = cell(1, length(modelos));

    for i = 1:length(modelos)
        model_name = [model_prefix modelos{i}];
        modelo_atual = fullfile(base_dir, model_name);

        if ~bdIsLoaded(model_name)
            load_system(modelo_atual);
        end

        configura_blocos(model_name, modelos{i}, Kp_values(i), Ki_values(i));
        simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));

        time = simOut.(['freq_' modelos{i}]).time;
        freq_data{i} = simOut.(['freq_' modelos{i}]).signals.values;
        Vsa_values{i} = simOut.(['Va_' modelos{i}]).signals.values(:, 2);
        Vta_values{i} = simOut.(['Va_' modelos{i}]).signals.values(:, 1);
    end

    for i = 1:length(modelos)
        close_system([model_prefix modelos{i}], 0);
    end
end

function configura_blocos(model_name, modelo, Kp, Ki)
    set_param([model_name '/PLL/Kp_' modelo], 'Gain', num2str(Kp));
    set_param([model_name '/PLL/Ki_' modelo], 'Gain', num2str(Ki));
end

function plota_frequencias(freq_data, time, modelos, tipo_linha)
    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    hold on;

    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        freq_rede = freq_data{i}(:, 1);
        freq_pll = freq_data{i}(:, 2);

        if i == 1
            plot(time, freq_rede, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Frequência Rede');
        end

        plot(time, freq_pll, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['Frequência ' nome_simples]);
    end

    formatar_grafico_sem_letra('Frequência (Hz)', 'Tempo (s)', true);
    hold off;
end

function plota_tensoes(Vsa_values, Vta_values, time, modelos, tipo_linha)
    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    ax1 = subplot('Position', [0.1 0.6 0.85 0.35]);
    plota_tensoes_subplot(time, Vsa_values, Vta_values, modelos, tipo_linha, ax1, '(a)', true);

    ax2 = subplot('Position', [0.1 0.2 0.4 0.25]);
    plota_tensoes_zoom(time, Vsa_values, Vta_values, modelos, tipo_linha, ax2, '(b)', [0.14, 0.34], false);

    ax3 = subplot('Position', [0.55 0.2 0.4 0.25]);
    plota_tensoes_zoom(time, Vsa_values, Vta_values, modelos, tipo_linha, ax3, '(c)', [0.34, 0.54], false);
end

function plota_tensoes_subplot(time, Vsa_values, Vta_values, modelos, tipo_linha, ax, letra, mostrar_legenda)
    hold on;

    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');

        if i == 1
            plot(time, Vsa_values{i}, 'r--', 'LineWidth', 1.5, 'DisplayName', '$V_{sa}$');
        end

        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['$V_{ta}$~' nome_simples]);
    end

    formatar_grafico('Tensão (V)', 'Tempo (s)', letra, mostrar_legenda, true);
    hold off;
end

function plota_tensoes_zoom(time, Vsa_values, Vta_values, modelos, tipo_linha, ax, letra, x_limits, mostrar_legenda)
    hold on;

    for i = 1:length(modelos)
        if i == 1
            plot(time, Vsa_values{i}, 'r--', 'LineWidth', 1.5);
        end

        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0);
    end

    xlim(x_limits);
    formatar_grafico('Tensão (V)', 'Tempo (s)', letra, mostrar_legenda, true);
    hold off;
end

function formatar_grafico(y_label, x_label, letra, mostrar_legenda, usar_latex)
    xlabel(x_label, 'FontSize', 16);
    ylabel(y_label, 'FontSize', 16);

    if mostrar_legenda
        lgd = legend('Location', 'northoutside', 'Orientation', 'horizontal');
        set(lgd, 'FontSize', 14);
        if usar_latex
            set(lgd, 'Interpreter', 'latex');
        end
        lgd.ItemTokenSize = [40, 20];
    end

    grid on;
    if ~isempty(letra)
        add_letra(letra);
    end
end

function formatar_grafico_sem_letra(y_label, x_label, mostrar_legenda)
    xlabel(x_label, 'FontSize', 16);
    ylabel(y_label, 'FontSize', 16);

    if mostrar_legenda
        lgd = legend('Location', 'northoutside', 'Orientation', 'horizontal');
        set(lgd, 'FontSize', 14);
        lgd.ItemTokenSize = [40, 20];
    end

    grid on;
end

function add_letra(letra)
    pos = get(gca, 'Position');
    annotation('textbox', [pos(1) + (pos(3) / 2) - 0.02, pos(2) - 0.1, 0.04, 0.03], ...
        'String', letra, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
end
