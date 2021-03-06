%%Coursework of <Siyao Li> <k20113549>, Feb 2021%%
% rename this file to k12345678.m for submission, using your k number
%%%%%%%%%%%%%
%% initialization

clear; close all; clc; format longg;

load 'USPS_dataset9296.mat' X t; % loads 9296 handwritten 16x16 images X dim(X)=[9296x256] and the lables t in [0:9] dim(t)=[9298x1]
[Ntot,D] =      size(X);         % Ntot = number of total dataset samples. D =256=input dimension

% Anonymous functions as inlines
show_vec_as_image16x16 =    @(row_vec)        imshow(-(reshape(row_vec,16,16)).');    % shows the image of a row vector with 256 elements. For matching purposes, a negation and rotation are needed.
sigmoid =                   @(x)            1./(1+exp(-x));                         % overwrites the existing sigmoid, in order to avoid the toolbox
LSsolver =                  @(Xmat,tvec)    ( Xmat.' * Xmat ) \ Xmat.' * tvec;      % Least Square solver

PLOT_DATASET =  0;      % For visualization. Familiarise yourself by running with 1. When submiting the file, set back to 0
if PLOT_DATASET
    figure(8); sgtitle('First 24 samples and labels from USPS data set');
    for n=1:4*6
        subplot(4,6,n);
        show_vec_as_image16x16(X(n,:));
        title(['t_{',num2str(n),'}=',num2str(t(n)),'   x_{',num2str(n),'}=']);
    end
end

% code here initialization code that manipulations the data sets
data_0 = [];
data_1 = [];
N = 9296;
for n = 1:N
    if t(n) == 0 
        data_0 = [data_0;X(n,:)];
    end
    if t(n) == 1
        data_1 = [data_1;X(n,:)];
    end
end    

%%%%%%%%  select data for validation and training
% t = 1
x_data1 = [ones(1269,1),data_1];
[n_data1,n_feature1] = size(x_data1);
data1_train = x_data1(1:round(n_data1*0.7),:);
data1_validation = x_data1(round(n_data1*0.7)+1:n_data1,:);
% t = 0
x_data0 = [ones(1551,1),data_0];
[n_data0,n_feature0] = size(x_data0);
data0_train = x_data0(1:round(n_data0*0.7),:);
data0_validation = x_data0(round(n_data0*0.7)+1:n_data0,:);

%%Section 1
% Data integration
% training data
train_data = [data0_train;data1_train];
X_train = train_data(:,2:257);
t0_t = zeros(1086,1); % target value
t1_t = ones(888,1);
t_D = [t0_t;t1_t];

% validation data
validation_data = [data0_validation;data1_validation];
X_validation = validation_data(:,2:257);
t0_v = zeros(465,1); % target value
t1_v = ones(381,1);
t_V = [t0_v;t1_v];



% figure 1
thERM=LSsolver(train_data,t_D);
xaxis=[1:1:1974];
L = 1974; 
for l = 1:L
    ul = train_data(l,:);
    tl(l) = thERM'*ul';
end  

% X_train1 contains the first 9 entries of the vector X_train
X_train1 = X_train(:,1:10);
X_validation1 = X_validation(:,1:10);

thERM_Xtrain1=LSsolver(X_train1,t_D);
for l1=1:L
    ul1=X_train1(l1,:);
    tl1(l1)=thERM_Xtrain1'*ul1';
end

% code for plot here
figure(1); hold on; title('Section 1: ERM regression, quadratic loss');
plot(xaxis,tl,'-g'); hold on 
plot(xaxis,t_D,'k--','LineWidth',1); hold on

% supporting code here that help to calculate and displaying without a ";" the two variables
traininglossLS_257 = 1/1974 * norm(t_D - train_data * thERM)^2   % Training   loss when dim(theta)=257.
validationlossLS_257 = 1/846 * norm(t_V - validation_data * thERM)^2 % Validation loss when dim(theta)=257.
% dim(theta)=10:

% supporting code here that help to calculate and displaying without a ";" the two variables
traininglossLS_10 = 1/1974 * norm(t_D - X_train1 * thERM_Xtrain1)^2     % Training   loss when dim(theta)=10.
validationlossLS_10 = 1/846 * norm(t_V - X_validation1 * thERM_Xtrain1)^2 % Validation loss when dim(theta)=10.

% code for plot here (using the "hold on", it will overlay)
plot(xaxis,tl1,'r','LineWidth',1); 
% complete the insight:
display('The predictions with the longer and shorter feature vectors are different because the red line is generated by training only 9 features, which is much less than the green line. When we consider the model with more features, the model become more reliable and less bias, relatively the training loss will be smaller,which made the line fluctuates slightly')

%%Section 2
% supporting code here
tlosslist = [];
vlosslist = [];
I = 50; %number of iteration
S = 64; %mini-batch size
th = zeros(257,1); 
gamma = 0.053;%learning rate

for i = 1:I
    ind=mnrnd(1,1/1974 *ones(1974,1),S)*[1:1974]'; %generate S random indices
    g=zeros(257,1);
    for s = 1:S
        g = g + 1/S * (sigmoid(th' * train_data(ind(s),:)')-t_D(ind(s))) * train_data(ind(s),:)'; 
    end
    th = th - gamma * g;
    %logloss for training
    tloss = 0;
    for lt = 1:1974
        tlogloss = t_D(lt) * -log(sigmoid(th' * train_data(lt,:)')) + (1-t_D(lt)) * -log(1-sigmoid(th' * train_data(lt,:)'));
        tloss = tloss + tlogloss;
    end
    tloss = tloss/1974;
    trainingloss_LR = [tlosslist;tloss];
    tlosslist = trainingloss_LR;
   
    
    %logloss for validation
    tvloss = 0;
    for lv = 1:846
        vlogloss = t_V(lv) * -log(sigmoid(th' * validation_data(lv,:)')) + (1-t_V(lv)) * -log(1-sigmoid(th' * validation_data(lv,:)'));
        tvloss = tvloss + vlogloss;
    end
    tvloss = tvloss/846;
    validationloss_LR = [vlosslist;tvloss];
    vlosslist = validationloss_LR;
end
figure(2); hold on; title('Section 2: Logistic Regression');
% code for plot here
xaxis=[1:1:I];
plot(xaxis,trainingloss_LR,'b','LineWidth',1.5); hold on;
xlabel('Iteration'); ylabel('Log-loss')
plot(xaxis,validationloss_LR,'r','LineWidth',1.5);
legend('trainingloss','validationloss')
% complete the insight:
display('I have chosen S=64 and gamma=0.053 because some material says CPU will perform better when running under the number of 32/16/64, and in this part the number of samples is large so the larger mini batch size is more suitable. For learning rate,0.053 could move towards a stationary point without missing the extreme point ');

%%Section 3
N=size(X_train,1);
[W,D] = eig(1/N * X_train' * X_train);
w1=W(:,1); w2=W(:,2); w3=W(:,3); %first three components of the picture
% some code here, and replace the three <???> in the plots:
figure(3); sgtitle('Section 3: PCA most significant Eigen vectors');
subplot(2,2,1); show_vec_as_image16x16(15*w1); title('Most significant'); % multiply positive scalar to enhance gray value
subplot(2,2,2); show_vec_as_image16x16(15*w2); title('Second significant');
subplot(2,2,3); show_vec_as_image16x16(15*w3); title('Third significant');
figure(4); sgtitle('Section 3: Estimating using PCA, M = number of significant components');
% some code here, and replace the three <???> in the plots:
part(1) = w1' * X_train(1,:)'; %most significant component
part(2) = w2' * X_train(1,:)'; %second significant component
part(3) = w3' * X_train(1,:)'; %third significant component
repartw1 = part(1)*w1;
repartw2 = part(1)*w1+part(2)*w2;
repartw3 = part(1)*w1+part(2)*w2+part(3)*w3;
subplot(2,2,1); show_vec_as_image16x16(X_train(1,:)); title('First training set image');
subplot(2,2,2); show_vec_as_image16x16(repartw1); title('Reconstracting using M=1 most significant components');
subplot(2,2,3); show_vec_as_image16x16(repartw2); title('Reconstracting using M=2');
subplot(2,2,4); show_vec_as_image16x16(repartw3); title('Reconstracting using M=3');
% plot the contributions of the first three components in a 3D plot
figure(5); hold on; title('Significant PCA components over all training set');
% code for plot3 here
part1(1,:)=w1'*X_train(1087:1974,:)';
part1(2,:)=w2'*X_train(1087:1974,:)';
part1(3,:)=w3'*X_train(1087:1974,:)';

part0(1,:)=w1'*X_train(1:1086,:)';
part0(2,:)=w2'*X_train(1:1086,:)';
part0(3,:)=w3'*X_train(1:1086,:)';

plot3(part0(1,:),part0(2,:),part0(3,:),'o','MarkerSize',6);
hold on;
plot3(part1(1,:),part1(2,:),part1(3,:),'x','MarkerSize',6);

%%Section 4
% supporting code here
XD_pca = [ones(1086,1),part0(1:2,:)';ones(888,1),part1(1:2,:)'];% three-dimensional vector of features including the first two principal components using PCA
I_4 = 50; %number of iteration
S_4 = 64; %mini-batch size
th_4 = zeros(3,1);
gamma = 0.053;%learning rate
tloss_pca = [];
for i_4 = 1:I_4
    ind4=mnrnd(1,1/1974 *ones(1974,1),S_4)*[1:1974]'; %generate S random indices
    g_4=zeros(3,1);
    for s_4 = 1:S_4
        g_4 = g_4 + 1/S_4 * (sigmoid(th_4' * XD_pca(ind4(s_4),:)')-t_D(ind4(s_4))) * XD_pca(ind4(s_4),:)'; 
    end
    th_4 = th_4 - gamma * g_4;
    %logloss for training
    tloss_4 = 0;
    for lp = 1:1974
        tlogloss_4 = t_D(lp) * -log(sigmoid(th_4' * XD_pca(lp,:)')) + (1-t_D(lp)) * -log(1-sigmoid(th_4' * XD_pca(lp,:)'));
        tloss_4 = tloss_4 + tlogloss_4;
    end
    tloss_4 = tloss_4/1974;
    trainingloss_pca = [tloss_pca;tloss_4];
    tloss_pca = trainingloss_pca;
 
end
figure(6); hold on; title('Section 4: Logistic Regression');
% code for plot here
xaxis_4=[1:1:I_4];
plot(xaxis_4,trainingloss_pca,'b','LineWidth',1); hold on;
xlabel('Iteration'); ylabel('Log-loss')
legend('trainingloss')
% complete the insight:
display('Comparing with the solution in Section 2, I conclude in figure 2 the blue line tends to be flatter faster and the final traingloss it gots is less than the one in the figure 6. From all of these performances, we can conclude PCA still does not perform as much as SGD in loss and decline speed.It is also proved that supervised learning with labels is easier to obtain less loss and faster convergence speed than unsupervised learning. ');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A list of functions you may want to familiarise yourself with. Check the help for full details.

% + - * / ^ 						% basic operators
% : 								% array indexing
% * 								% matrix mult
% .* .^ ./							% element-wise operators
% x.' (or x' when x is surely real)	% transpose
% [A;B] [A,B] 						% array concatenation
% A(row,:) 							% array slicing
% round()
% exp()
% log()
% svd()
% max()
% sqrt()
% sum()
% ones()
% zeros()
% length()
% randn()
% randperm()
% figure()
% plot()
% plot3()
% title()
% legend()
% xlabel(),ylabel(),zlabel()
% hold on;
% grid minor;
