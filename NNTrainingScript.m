numInputs = 2;
inputs = {(0:pi/64:6.28); (0:pi/63.5:2*pi)};
%inputs = (0:pi/64:2*pi);
targets = sin(inputs{1})+2*sin(inputs{2});
%targets = sin(inputs);
allRMSE = zeros(0, 5000);
allTestTargets = zeros(0, 10000);
PredOutputs = zeros(0, 10000);
double RMSE;
numRuns = 10;
numBins = 30;
num = 0;
trainPct = 1;
valPct = 0;
testPct = 0;

%Finds the current folder directory to be used in saving the documents
directory = pwd;
fprintf(fopen([directory, '\NumericalFigures.txt'], 'w'), '%s\n', 'Neural Network Data for Run on: ', date);
fclose('all');
%find the ID for the file specified and with an append permission
fileID = fopen([directory, '\NumericalFigures.txt'], 'a');

%Writes to file all the data for sin(x)
fprintf(fileID, '%s\n', 'Standard Deviation of all sin(x): ', std(targets));
%Writes the Mean of sin(x)
fprintf(fileID, '%s\n', 'Mean of all sin(x): ', mean(targets));
%Writes the R^2 value
%mdl = fitlm(inputs, targets);
%fprintf(fileID, '%s\n', 'Rsquared for sin(x): ', mdl.Rsquared.Adjusted);
%Writes the Std Dev of sin(x)
fprintf(fileID, '%s\n', 'Standard Deviation of all sin(x): ', std(targets));
fclose('all');
%Values Histogram
DispHistogram(targets, 50, 'Histogram of all sin(x) values', 'Value', 'Occurence');

%Normalized data
normalTars= (targets-mean(targets))/std(targets);
%disp('Normalized Targets');

normalIns= {(inputs{1}-mean(targets))/std(targets); (inputs{2}-mean(targets))/std(targets)};
%disp('Normalized Inputs');

for j=0:4
    minRMSE = 1;
    maxRMSE = 0;
    RMSESum = 0;
    for i=0:numRuns-1
        %Calls function to set parameters as desired
        network = netParams(trainPct, testPct, valPct, numInputs, 10);

        %Hides the NNtraintool window for "faster" training
        %network.trainParam.showWindow = false;

        %Training the network with those set parameters
        [network, tr] = train(network, normalIns, normalTars);
        
        outputs = network(normalIns);
        %Converting from cell to matrix
        outputs = cell2mat(outputs);
        %De-normalization of data
        outputs = (outputs*std(targets)+mean(targets));
        targets = (normalTars*std(targets)+mean(targets));
        
        %Adding exception for the full fit
        if (num == 0)
            PredOutputs = [PredOutputs, outputs];
        else
            PredOutputs = [PredOutputs, outputs(tr.testInd)];
        end
        
        errors = outputs-targets;
        RMSE = sqrt(mean((errors).^2));

        if (RMSE<minRMSE)
            minRMSE=RMSE;
            minRMSEPred = outputs(tr.testInd);
            minRMSETargets = targets(tr.testInd);
            minRMSETO = outputs(tr.trainInd);
            minRMSETT = targets(tr.trainInd);
        end

        if (RMSE>maxRMSE)
            maxRMSE=RMSE;
            maxRMSEPred = outputs(tr.testInd);
            maxRMSETargets = targets(tr.testInd);
            maxRMSETO = outputs(tr.trainInd);
            maxRMSETT = targets(tr.trainInd);
        end

        allRMSE(i+1) = RMSE;
        RMSESum = RMSESum + RMSE;
    end

    %get a new File ID
    fileID = fopen([directory, '\NumericalFigures.txt'], 'a');
    
    %Display which run this is
    fprintf(fileID, '%s\n\n', '--------------------------------------');
    fprintf(fileID, '%s\n', sprintf('Data for Testing Percentage of %d%%:\n', testPct*100));
    
    %Display Numerical Results
    %Mean RMSE
    avgRMSE = RMSESum/numRuns;
    fprintf(fileID, '%s\n', 'RMSE average: ', avgRMSE);
    fprintf(fileID, '%s\n', 'Averaged Over: ');
    fprintf(fileID, '%d', numRuns);
    fprintf(fileID, '%s\n', ' runs');
    %RMSE Standard Deviation
    RMSEdev = std(allRMSE);
    fprintf(fileID, '%s\n', 'RMSE Std. Dev: ', RMSEdev);
    %Smallest RMSE
    fprintf(fileID, '%s\n', 'Smallest RMSE: ', minRMSE);
    %Largest RMSE
    fprintf(fileID, '%s\n', 'Largest RMSE: ', minRMSE);
    %Add an exception to R^2 calculation because we cant fit a model
    %without targets
    if (num ~= 0)
    %Smallest R^2
    mdl2 = fitlm(minRMSEPred, minRMSETargets);
    fprintf(fileID, '%s\n', 'Best R^2: ', mdl2.Rsquared.Adjusted);
    mdl2.Residuals.Raw;
    saveas(plotResiduals(mdl2), [fullfile([directory, '\Figures'], sprintf('Residuals for Percentage of %d%:', testPct*100)), '.pdf']);
    %Largest R^2
    mdl3 = fitlm(maxRMSEPred, maxRMSETargets);
    fprintf(fileID, '%s\n', 'Worst R^2: ', mdl3.Rsquared.Adjusted);
    mdl3.Residuals.Raw;
    saveas(plotResiduals(mdl3), [fullfile([directory, '\Figures'], sprintf('Residuals for Percentage of %d%:', testPct*100)), '.pdf']);
    end

    %Mean of Predicted Outputs
    avgOutput = mean(PredOutputs);
    fprintf(fileID, '%s\n', 'Mean Y-value: ', avgOutput);
    %All Predicted Outputs Standard Deviation
    Dev = std(PredOutputs);
    fprintf(fileID, '%s\n', 'Std Dev. of Outputs: ', Dev);
    
    %Graphs
    %RMSE Histogram
    DispHistogram(allRMSE, numBins, sprintf('RMSE Histogram [%.2g%%]', testPct*100), 'RMSE', 'Occurence');
    %Data Scatterplot
    %DispScatter(allOutputs ,allTestTargets, sprintf('Predicted vs. Actual RMSE(%d)[%.2g%%]', avgRMSE, trainPct*100), 'Predicted sin(x)', 'sin(x)');
    %Max RMSE Scatterplot
    DispScatter(maxRMSEPred, maxRMSETargets, maxRMSETO, maxRMSETT, sprintf('Predicted vs. Actual with Largest RMSE(%d)[%.2g%%]', maxRMSE, testPct*100), 'Predicted sin(x)', 'sin(x)');
    %Min RMSE Scatterplot
    DispScatter(minRMSEPred, minRMSETargets, minRMSETO, minRMSETT, sprintf('Predicted vs Actual with Smallest RMSE(%d)[%.2g%%]', minRMSE, testPct*100), 'Predicted sin(x)', 'sin(x)');
    
    switch (num)
        case 0
            testPct = (1)/length(inputs{1});
            valPct = .05;
            num = 1;
        case 1
            testPct = .20;
            num = 2;
        case 2
            testPct = .80;
            num = 3;
        case 3
            testPct = .95;
            valPct = .01;
    end
    
    trainPct = 1-valPct-testPct;
    fclose('all');
end
