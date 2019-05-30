function playEventMovie(movie, cellIdx, trace, centroids, cvxHulls, skipCell)

    windowSpace = 20;
    display_fr = 40;
    fr = 5;
    
    thisCentroid = centroids(cellIdx,:);
    thisHull = cvxHulls{cellIdx};
    skipCell(cellIdx) = 1;
    centroids = centroids(~skipCell,:);
    cvxHulls = cvxHulls(~skipCell);


    % define borders
    xLow  = round(max(thisCentroid(2) - (windowSpace-1),1));
    xHigh = min(xLow + 2*windowSpace-1,size(movie,2));
    if length(xLow:xHigh) ~= 2*windowSpace
        xLow = size(movie,2) - (2*windowSpace-1);
    end
    yLow  = round(max(thisCentroid(1) - (windowSpace-1),1));
    yHigh = min(yLow + 2*windowSpace-1,size(movie,1));
    if length(yLow:yHigh) ~= 2*windowSpace
        yLow = size(movie,1) - (2*windowSpace-1);
    end


    % get cvxHulls of neighbors
    cDist = abs(round(bsxfun(@minus,centroids,thisCentroid)));
    neighborHulls = cvxHulls(cDist(:,1) < windowSpace & cDist(:,2) < windowSpace);
    offset = [xLow - 1; yLow - 1];
    neighborHulls = cellfun(@(x) bsxfun(@minus,x,offset),neighborHulls,'UniformOutput', false);
    thisHull =  bsxfun(@minus,thisHull,offset);


    % get cutouts of trace and movie
    movieCutout = movie(yLow:yHigh,xLow:xHigh,:);

    % set color values
    minVals = min(movieCutout,[],3);
    maxVals = max(movieCutout,[],3);
    clims = [prctile(minVals(:),50) prctile(maxVals(:),99)];


    f = figure('WindowStyle','normal','Position',[1000,800,500,400]);
    timestamps = ((1:length(trace)) - length(trace)/2) / fr;
    for i = 1:size(movieCutout,3)
        % plot movie
        % had to flip first dim of movie
        ax = subplot(3,2,[1:4]);
        hold on
        imagesc(flipud(movieCutout(:,:,i)));
        colormap(ax,gray)
        set(gca,'CLim',clims)
        set(gca, 'XTick', [], 'YTick', [])

        % plot cvxHulls
        plot(thisHull(1,:),abs(thisHull(2,:)-2 * windowSpace),'m')
        for j=1:length(neighborHulls)
            plot(neighborHulls{j}(1,:), abs(neighborHulls{j}(2,:)- 2 * windowSpace),'y')
        end
        xlim([1 2 * windowSpace])
        ylim([1 2 * windowSpace])


        % plot trace
        subplot(3,2,5:6)
        hold off
        plot(timestamps,trace,'k')
        hold on
        plot(timestamps(i),trace(i),'or')
        xlabel('Time (s)')
        ylabel('\Delta F / F')

        pause(1/display_fr);
    end
    close(f)


end
