% Copyright 2026 LI MingKuan
%
% 原项目：K-Means-Clustering-Demo
% 作者：LiMingKuan-UESTC
% 仓库地址：https://github.com/LiMingKuan-UESTC/K-Means-Clustering-Demo

function demo(varargin)

if nargin >= 1 && ischar(varargin{1}) && strcmpi(varargin{1}, 'selftest')
    runSelfTest();
    return;
end

clc;

%% 1. 默认数据
rng(11);

X = [
    randn(18, 2) * 0.34 + [1.1, 1.3];
    randn(18, 2) * 0.38 + [4.4, 1.5];
    randn(18, 2) * 0.36 + [2.8, 4.0];
    randn(5,  2) * 0.24 + [4.3, 3.6]
];

n = size(X, 1);
K = 3;
maxIter = 10;
initSeed = 5;

model = computeKMeansModel(X, K, maxIter, initSeed);
currentFrame = 1;
isPlaying = false;
autoTimer = [];

%% 2. 创建界面
fig = figure( ...
    'Name', 'K-means Clustering Demo', ...
    'NumberTitle', 'off', ...
    'Color', 'w', ...
    'Position', [100, 80, 1200, 680], ...
    'CloseRequestFcn', @(~, ~) closeFigure());

axMain = axes('Parent', fig, 'Position', [0.06, 0.18, 0.50, 0.72]);
axSide = axes('Parent', fig, 'Position', [0.62, 0.30, 0.33, 0.52]);

infoBox = uicontrol( ...
    'Parent', fig, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'Position', [0.62, 0.08, 0.33, 0.16], ...
    'BackgroundColor', 'w', ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 11, ...
    'String', '');

uicontrol( ...
    'Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', '上一步', ...
    'Units', 'normalized', ...
    'Position', [0.06, 0.06, 0.08, 0.06], ...
    'FontSize', 11, ...
    'Callback', @(~, ~) prevFrame());

uicontrol( ...
    'Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', '下一步', ...
    'Units', 'normalized', ...
    'Position', [0.15, 0.06, 0.08, 0.06], ...
    'FontSize', 11, ...
    'Callback', @(~, ~) nextFrame());

uicontrol( ...
    'Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', '自动播放', ...
    'Units', 'normalized', ...
    'Position', [0.24, 0.06, 0.09, 0.06], ...
    'FontSize', 11, ...
    'Callback', @(~, ~) playAuto());

uicontrol( ...
    'Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', '暂停', ...
    'Units', 'normalized', ...
    'Position', [0.34, 0.06, 0.07, 0.06], ...
    'FontSize', 11, ...
    'Callback', @(~, ~) pauseAuto());

uicontrol( ...
    'Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', '重置', ...
    'Units', 'normalized', ...
    'Position', [0.42, 0.06, 0.07, 0.06], ...
    'FontSize', 11, ...
    'Callback', @(~, ~) resetDemo());

uicontrol( ...
    'Parent', fig, ...
    'Style', 'text', ...
    'String', 'K:', ...
    'Units', 'normalized', ...
    'Position', [0.505, 0.075, 0.025, 0.03], ...
    'BackgroundColor', 'w', ...
    'FontSize', 11);

editK = uicontrol( ...
    'Parent', fig, ...
    'Style', 'edit', ...
    'String', num2str(K), ...
    'Units', 'normalized', ...
    'Position', [0.53, 0.065, 0.04, 0.05], ...
    'FontSize', 11);

uicontrol( ...
    'Parent', fig, ...
    'Style', 'text', ...
    'String', 'MaxIter:', ...
    'Units', 'normalized', ...
    'Position', [0.575, 0.075, 0.06, 0.03], ...
    'BackgroundColor', 'w', ...
    'FontSize', 11);

editMaxIter = uicontrol( ...
    'Parent', fig, ...
    'Style', 'edit', ...
    'String', num2str(maxIter), ...
    'Units', 'normalized', ...
    'Position', [0.635, 0.065, 0.05, 0.05], ...
    'FontSize', 11);

uicontrol( ...
    'Parent', fig, ...
    'Style', 'text', ...
    'String', 'Seed:', ...
    'Units', 'normalized', ...
    'Position', [0.69, 0.075, 0.045, 0.03], ...
    'BackgroundColor', 'w', ...
    'FontSize', 11);

editSeed = uicontrol( ...
    'Parent', fig, ...
    'Style', 'edit', ...
    'String', num2str(initSeed), ...
    'Units', 'normalized', ...
    'Position', [0.735, 0.065, 0.05, 0.05], ...
    'FontSize', 11);

uicontrol( ...
    'Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', '重新计算', ...
    'Units', 'normalized', ...
    'Position', [0.80, 0.06, 0.09, 0.06], ...
    'FontSize', 11, ...
    'Callback', @(~, ~) recomputeDemo());

renderFrame();

%% 3. 交互回调

    function prevFrame()
        pauseAuto();
        currentFrame = max(1, currentFrame - 1);
        renderFrame();
    end

    function nextFrame()
        totalFrames = numel(model.frames);
        currentFrame = min(totalFrames, currentFrame + 1);
        renderFrame();

        if currentFrame >= totalFrames
            pauseAuto();
        end
    end

    function playAuto()
        if isPlaying
            return;
        end

        isPlaying = true;

        autoTimer = timer( ...
            'ExecutionMode', 'fixedSpacing', ...
            'Period', 0.9, ...
            'TimerFcn', @(~, ~) autoStep());

        start(autoTimer);
    end

    function autoStep()
        if ~ishandle(fig)
            return;
        end

        totalFrames = numel(model.frames);

        if currentFrame < totalFrames
            currentFrame = currentFrame + 1;
            renderFrame();
        else
            pauseAuto();
        end
    end

    function pauseAuto()
        isPlaying = false;

        if ~isempty(autoTimer)
            try
                stop(autoTimer);
                delete(autoTimer);
            catch
            end
            autoTimer = [];
        end
    end

    function resetDemo()
        pauseAuto();
        currentFrame = 1;
        renderFrame();
    end

    function recomputeDemo()
        pauseAuto();

        newK = str2double(get(editK, 'String'));
        newMaxIter = str2double(get(editMaxIter, 'String'));
        newSeed = str2double(get(editSeed, 'String'));

        if isnan(newK) || newK < 1
            newK = 3;
        end

        if isnan(newMaxIter) || newMaxIter < 1
            newMaxIter = 10;
        end

        if isnan(newSeed)
            newSeed = 5;
        end

        K = min(max(round(newK), 1), n);
        maxIter = min(max(round(newMaxIter), 1), 100);
        initSeed = max(round(newSeed), 0);

        set(editK, 'String', num2str(K));
        set(editMaxIter, 'String', num2str(maxIter));
        set(editSeed, 'String', num2str(initSeed));

        model = computeKMeansModel(X, K, maxIter, initSeed);
        currentFrame = 1;

        renderFrame();
    end

    function closeFigure()
        pauseAuto();
        delete(fig);
    end

%% 4. 绘图主函数

    function renderFrame()
        if ~ishandle(fig)
            return;
        end

        delete(findall(fig, 'Type', 'ColorBar'));

        cla(axMain);
        cla(axSide);

        hold(axMain, 'on');
        hold(axSide, 'on');
        grid(axMain, 'on');
        grid(axSide, 'on');
        axis(axMain, 'equal');

        xlim(axMain, [min(X(:, 1)) - 0.8, max(X(:, 1)) + 0.8]);
        ylim(axMain, [min(X(:, 2)) - 0.8, max(X(:, 2)) + 0.8]);

        frameData = model.frames(currentFrame);

        if strcmp(frameData.phase, 'raw')
            drawRawData(frameData);
        elseif strcmp(frameData.phase, 'init')
            drawInitialization(frameData);
        elseif strcmp(frameData.phase, 'assign')
            drawAssignment(frameData);
        elseif strcmp(frameData.phase, 'update')
            drawUpdate(frameData);
        elseif strcmp(frameData.phase, 'final')
            drawFinal(frameData);
        end

        set(infoBox, 'String', getInfoText(frameData, currentFrame, numel(model.frames)));
    end

%% 5. 各阶段绘图

    function drawRawData(frameData)
        scatter(axMain, X(:, 1), X(:, 2), 70, ...
            'MarkerFaceColor', [0.35, 0.55, 0.90], ...
            'MarkerEdgeColor', 'k');
        addPointLabels(axMain);

        title(axMain, 'Step 1：原始样本点', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel(axMain, 'x_1');
        ylabel(axMain, 'x_2');

        text(axSide, 0.05, 0.86, 'K-means 聚类演示', ...
            'Units', 'normalized', ...
            'FontSize', 15, ...
            'FontWeight', 'bold');

        text(axSide, 0.05, 0.65, ...
            sprintf(['核心思想：\n\n', ...
            '1. 先给出 K 个初始聚类中心\n', ...
            '2. 将每个样本分配给最近的中心\n', ...
            '3. 用簇内样本均值更新中心\n', ...
            '4. 重复分配与更新，直到中心基本不再移动']), ...
            'Units', 'normalized', ...
            'FontSize', 11);

        text(axSide, 0.05, 0.24, ...
            sprintf('当前设置：K = %d，MaxIter = %d，Seed = %d', K, maxIter, initSeed), ...
            'Units', 'normalized', ...
            'FontSize', 11, ...
            'FontWeight', 'bold');

        axis(axSide, 'off');
        unused(frameData);
    end

    function drawInitialization(frameData)
        scatter(axMain, X(:, 1), X(:, 2), 62, ...
            'MarkerFaceColor', [0.88, 0.88, 0.88], ...
            'MarkerEdgeColor', 'k');
        drawCenters(frameData.centers, true);
        addPointLabels(axMain);

        title(axMain, 'Step 2：初始化 K 个聚类中心', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel(axMain, 'x_1');
        ylabel(axMain, 'x_2');

        bar(axSide, 1:K, ones(1, K));
        title(axSide, '初始中心编号', 'FontSize', 13, 'FontWeight', 'bold');
        xlabel(axSide, 'Cluster');
        ylabel(axSide, 'Initialized');
        ylim(axSide, [0, 1.4]);

        for c = 1:K
            text(axSide, c, 1.05, sprintf('C%d', c), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10, ...
                'FontWeight', 'bold');
        end
    end

    function drawAssignment(frameData)
        colors = lines(K);

        for c = 1:K
            idx = frameData.labels == c;
            if any(idx)
                scatter(axMain, X(idx, 1), X(idx, 2), 80, colors(c, :), ...
                    'filled', ...
                    'MarkerEdgeColor', 'k');
            end
        end

        for i = 1:n
            c = frameData.labels(i);
            plot(axMain, [X(i, 1), frameData.centers(c, 1)], ...
                         [X(i, 2), frameData.centers(c, 2)], ...
                         '--', ...
                         'Color', [0.65, 0.65, 0.65], ...
                         'LineWidth', 0.7);
        end

        drawCenters(frameData.centers, true);
        addPointLabels(axMain);

        title(axMain, sprintf('Iteration %d：样本分配 Assignment', frameData.iter), ...
            'FontSize', 14, ...
            'FontWeight', 'bold');
        xlabel(axMain, 'x_1');
        ylabel(axMain, 'x_2');

        counts = clusterCounts(frameData.labels, K);
        bar(axSide, 1:K, counts);
        title(axSide, '各簇样本数量', 'FontSize', 13, 'FontWeight', 'bold');
        xlabel(axSide, 'Cluster');
        ylabel(axSide, 'Count');

        for c = 1:K
            text(axSide, c, counts(c), num2str(counts(c)), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 10);
        end
    end

    function drawUpdate(frameData)
        colors = lines(K);

        for c = 1:K
            idx = frameData.labels == c;
            if any(idx)
                scatter(axMain, X(idx, 1), X(idx, 2), 80, colors(c, :), ...
                    'filled', ...
                    'MarkerEdgeColor', 'k');
            end
        end

        drawCenters(frameData.oldCenters, false);
        drawCenters(frameData.centers, true);

        for c = 1:K
            plot(axMain, [frameData.oldCenters(c, 1), frameData.centers(c, 1)], ...
                         [frameData.oldCenters(c, 2), frameData.centers(c, 2)], ...
                         'k-', ...
                         'LineWidth', 1.6);
        end

        addPointLabels(axMain);

        title(axMain, sprintf('Iteration %d：更新聚类中心 Update', frameData.iter), ...
            'FontSize', 14, ...
            'FontWeight', 'bold');
        xlabel(axMain, 'x_1');
        ylabel(axMain, 'x_2');

        drawObjectiveTrend(frameData.iter);
    end

    function drawFinal(frameData)
        colors = lines(K);

        for c = 1:K
            idx = frameData.labels == c;
            if any(idx)
                scatter(axMain, X(idx, 1), X(idx, 2), 90, colors(c, :), ...
                    'filled', ...
                    'MarkerEdgeColor', 'k');
            end
        end

        drawCenters(frameData.centers, true);
        addPointLabels(axMain);

        title(axMain, 'Final：K-means 聚类结果', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel(axMain, 'x_1');
        ylabel(axMain, 'x_2');

        drawObjectiveTrend(length(model.objectiveByIter));
    end

%% 6. 通用绘图函数

    function drawCenters(centers, isNewCenter)
        colors = lines(K);

        for c = 1:K
            if isNewCenter
                scatter(axMain, centers(c, 1), centers(c, 2), 260, colors(c, :), ...
                    'p', ...
                    'filled', ...
                    'MarkerEdgeColor', 'k', ...
                    'LineWidth', 1.5);
                text(axMain, centers(c, 1), centers(c, 2) + 0.22, ...
                    sprintf('C%d', c), ...
                    'HorizontalAlignment', 'center', ...
                    'FontSize', 10, ...
                    'FontWeight', 'bold');
            else
                scatter(axMain, centers(c, 1), centers(c, 2), 130, ...
                    'x', ...
                    'MarkerEdgeColor', colors(c, :), ...
                    'LineWidth', 2.0);
            end
        end
    end

    function drawObjectiveTrend(iterNow)
        obj = model.objectiveByIter;
        if isempty(obj)
            text(axSide, 0.10, 0.70, '尚未产生目标函数值', ...
                'Units', 'normalized', ...
                'FontSize', 12);
            axis(axSide, 'off');
            return;
        end

        iterNow = min(max(iterNow, 1), length(obj));
        plot(axSide, 1:iterNow, obj(1:iterNow), '-o', 'LineWidth', 1.8);
        title(axSide, '目标函数 SSE 变化', 'FontSize', 13, 'FontWeight', 'bold');
        xlabel(axSide, 'Iteration');
        ylabel(axSide, 'SSE');
        xlim(axSide, [1, max(2, length(obj))]);

        if length(obj) > 1
            ymax = max(obj) * 1.08;
            ymin = min(obj) * 0.92;
            if abs(ymax - ymin) < eps
                ymax = ymax + 1;
                ymin = ymin - 1;
            end
            ylim(axSide, [ymin, ymax]);
        end
    end

    function addPointLabels(ax)
        for i = 1:n
            text(ax, X(i, 1) + 0.04, X(i, 2) + 0.04, num2str(i), ...
                'FontSize', 8, ...
                'Color', [0.15, 0.15, 0.15]);
        end
    end

%% 7. 信息说明

    function txt = getInfoText(frameData, frameIdx, totalFrames)
        if strcmp(frameData.phase, 'raw')
            txt = sprintf([ ...
                'Frame %d / %d\n', ...
                '当前阶段：原始数据展示\n\n', ...
                'K-means 是典型的基于距离的划分式聚类算法。\n', ...
                '它通过反复执行“样本分配”和“中心更新”来降低簇内平方误差。'], ...
                frameIdx, totalFrames);

        elseif strcmp(frameData.phase, 'init')
            txt = sprintf([ ...
                'Frame %d / %d\n', ...
                '当前阶段：初始化聚类中心\n\n', ...
                '本 Demo 从样本点中随机选择 K 个初始中心。\n', ...
                '当前 K = %d，Seed = %d。'], ...
                frameIdx, totalFrames, K, initSeed);

        elseif strcmp(frameData.phase, 'assign')
            txt = sprintf([ ...
                'Frame %d / %d\n', ...
                '当前阶段：样本分配\n\n', ...
                'Iteration = %d\n', ...
                '每个样本被分配给距离最近的聚类中心。\n', ...
                '当前 SSE = %.4f'], ...
                frameIdx, totalFrames, frameData.iter, frameData.objective);

        elseif strcmp(frameData.phase, 'update')
            txt = sprintf([ ...
                'Frame %d / %d\n', ...
                '当前阶段：中心更新\n\n', ...
                'Iteration = %d\n', ...
                '每个新中心等于对应簇内样本的均值。\n', ...
                '本轮中心最大移动距离 = %.6f'], ...
                frameIdx, totalFrames, frameData.iter, frameData.movement);

        else
            txt = sprintf([ ...
                'Frame %d / %d\n', ...
                '当前阶段：最终结果\n\n', ...
                '实际迭代次数 = %d\n', ...
                '最终 SSE = %.4f\n', ...
                '当中心移动很小或达到最大迭代次数时停止。'], ...
                frameIdx, totalFrames, model.iterations, frameData.objective);
        end
    end

%% 8. K-means 核心算法

    function result = computeKMeansModel(Xin, k, maxIt, seed)
        N = size(Xin, 1);
        k = min(max(round(k), 1), N);
        maxIt = max(round(maxIt), 1);

        seed = max(round(seed), 0);
        rng(seed);
        initIdx = randperm(N, k);
        centers = Xin(initIdx, :);

        frames = makeFrame('raw', 0, zeros(N, 1), centers, centers, NaN, NaN);
        frames(end + 1) = makeFrame('init', 0, zeros(N, 1), centers, centers, NaN, NaN);

        objectiveByIter = [];
        labels = zeros(N, 1);
        tol = 1e-6;
        iterDone = 0;

        for iter = 1:maxIt
            oldCenters = centers;

            [labels, distancesToOwnCenter] = assignLabels(Xin, centers);
            objective = sum(distancesToOwnCenter .^ 2);
            objectiveByIter(end + 1) = objective; %#ok<AGROW>

            frames(end + 1) = makeFrame('assign', iter, labels, centers, oldCenters, objective, NaN); %#ok<AGROW>

            centers = updateCenters(Xin, labels, centers, distancesToOwnCenter);
            movement = max(sqrt(sum((centers - oldCenters) .^ 2, 2)));

            frames(end + 1) = makeFrame('update', iter, labels, centers, oldCenters, objective, movement); %#ok<AGROW>

            iterDone = iter;

            if movement < tol
                break;
            end
        end

        [labels, distancesToOwnCenter] = assignLabels(Xin, centers);
        finalObjective = sum(distancesToOwnCenter .^ 2);
        frames(end + 1) = makeFrame('final', iterDone, labels, centers, centers, finalObjective, 0); %#ok<AGROW>

        result.frames = frames;
        result.finalLabels = labels;
        result.finalCenters = centers;
        result.finalObjective = finalObjective;
        result.objectiveByIter = objectiveByIter;
        result.iterations = iterDone;
        result.initIdx = initIdx;
    end

    function frame = makeFrame(phase, iter, labels, centers, oldCenters, objective, movement)
        frame.phase = phase;
        frame.iter = iter;
        frame.labels = labels;
        frame.centers = centers;
        frame.oldCenters = oldCenters;
        frame.objective = objective;
        frame.movement = movement;
    end

    function [labels, ownDistances] = assignLabels(Xin, centers)
        N = size(Xin, 1);
        k = size(centers, 1);
        distMat = zeros(N, k);

        for c = 1:k
            diff = Xin - centers(c, :);
            distMat(:, c) = sqrt(sum(diff .^ 2, 2));
        end

        [ownDistances, labels] = min(distMat, [], 2);
    end

    function centers = updateCenters(Xin, labels, oldCenters, ownDistances)
        k = size(oldCenters, 1);
        centers = oldCenters;
        tmpDistances = ownDistances;

        for c = 1:k
            idx = labels == c;
            if any(idx)
                centers(c, :) = mean(Xin(idx, :), 1);
            else
                % 如果出现空簇，选择当前误差最大的样本作为该簇的新中心。
                % 若多个簇同时为空，则依次选择不同的高误差样本，避免中心完全重合。
                [~, farthestIdx] = max(tmpDistances);
                centers(c, :) = Xin(farthestIdx, :);
                tmpDistances(farthestIdx) = -inf;
            end
        end
    end

    function counts = clusterCounts(labels, k)
        counts = zeros(1, k);
        for c = 1:k
            counts(c) = sum(labels == c);
        end
    end

    function unused(~)
        % 用于避免部分 MATLAB 版本的未使用变量提示，无实际逻辑。
    end

%% 9. 自检函数

    function runSelfTest()
        fprintf('Running demo_kmeans selftest...\n');

        rng(100);
        Xtest = [
            randn(12, 2) * 0.20 + [0, 0];
            randn(12, 2) * 0.22 + [3, 0];
            randn(12, 2) * 0.24 + [1.5, 2.8]
        ];

        testKs = [1, 2, 3, 4];

        for ii = 1:length(testKs)
            kt = testKs(ii);
            m = computeKMeansModel(Xtest, kt, 20, 9);

            assert(isfield(m, 'frames'), 'Missing frames field.');
            assert(~isempty(m.frames), 'Frames should not be empty.');
            assert(size(m.finalCenters, 1) == kt, 'Center count mismatch.');
            assert(size(m.finalCenters, 2) == 2, 'Center dimension mismatch.');
            assert(length(m.finalLabels) == size(Xtest, 1), 'Label length mismatch.');
            assert(all(m.finalLabels >= 1 & m.finalLabels <= kt), 'Invalid cluster labels.');
            assert(all(isfinite(m.finalCenters(:))), 'Centers contain non-finite values.');
            assert(isfinite(m.finalObjective) && m.finalObjective >= 0, 'Invalid final objective.');
            assert(m.iterations >= 1 && m.iterations <= 20, 'Iteration count out of range.');

            m2 = computeKMeansModel(Xtest, kt, 20, 9);
            assert(isequal(m.finalLabels, m2.finalLabels), 'Same seed should produce same labels.');
            assert(max(abs(m.finalCenters(:) - m2.finalCenters(:))) < 1e-12, ...
                'Same seed should produce same centers.');
        end

        % 检查目标函数是否整体不会异常增加。
        m3 = computeKMeansModel(Xtest, 3, 20, 9);
        obj = m3.objectiveByIter;
        if length(obj) > 1
            assert(all(diff(obj) <= 1e-8), 'Objective should be non-increasing across iterations.');
        end

        fprintf('demo_kmeans selftest passed.\n');
    end

end
