library(xgboost)
library(MASS)
library(splines)
library(gglasso)
my_error<-function(pred, true){#mse/variance, which is 1-R^2
  sum((true-pred)^2)/sum((true-mean(true))^2)
}
mae<-function(pred, true){
  sum(abs(true-pred))/length(true)
}

GAMtree_fit<-function(X, y,lasso_group, X_orig, lambda1,lambda2, iter, eta, nrounds){
  #eta = 0.1 default
  y_orig = y
  Betas = matrix(, nrow = ncol(X)+1, ncol =iter)
  Trees =  vector("list", iter)
  rrMSE_fit = matrix(, nrow = 2, ncol =iter)
  mae_fit = matrix(, nrow = 2, ncol =iter)
  GAM_pred = matrix(0,nrow=length(y), ncol = iter)
  Tree_pred = matrix(0,nrow = length(y),ncol = iter)
  #Tree_pred_orig = matrix(0,nrow = length(y),ncol = iter)
  for(i in 1:iter){
    print(i)
    
    data=data.frame(cbind(X,y))
    #model = lm.ridge(y ~ .,data,lambda =lambda)
    model = gglasso(X,y,lasso_group,loss="ls",lambda =lambda1)
    Betas[,i] = coef(model)
    GAM_pred[,i] = (as.matrix(X)%*%as.vector(Betas[2:(ncol(X)+1),i]))+Betas[1,i]
    res1 = y-GAM_pred[,i]
    rrMSE_fit[1,i] = my_error(rowSums(GAM_pred),y_orig)
    mae_fit[1,i] = mae(rowSums(GAM_pred),y_orig)
    ##########################XGboost
    dtrain <- xgb.DMatrix(data = as.matrix(X_orig),label = res1) 

    
    params <- list(booster = "gbtree", objective = "reg:squarederror", eta=eta, max_depth=6)
    Trees[[i]] <- xgb.train (params = params, data = dtrain, nrounds = nrounds,eval_metric = "rmse")
    Tree_pred[,i] = lambda2*(predict(Trees[[i]],dtrain))
    
    y = res1 - Tree_pred[,i]
    rrMSE_fit[2,i] = my_error((rowSums(Tree_pred)+rowSums(GAM_pred)),y_orig)
    mae_fit[2,i] = mae(rowSums(Tree_pred)+rowSums(GAM_pred),y_orig)

    if(i>1){
     if(rrMSE_fit[2,i]>=rrMSE_fit[2,i-1]){
       best_iter = i-1
       break
     }else{
       best_iter = i
     }
    }
    # if(i>1){
    #   if(mae_fit[2,i]>=mae_fit[2,i-1]){
    #     best_iter = i-1
    #     break
    #   }else{
    #     best_iter = i
    #   }
    # }
  }
  result = list(Betas, Trees, rrMSE_fit, GAM_pred, Tree_pred, best_iter,mae_fit)
}


#Predict
GAMtree_predict<-function(X,X_orig,Betas,Trees,lambda2){

  
  G_part = (X%*%Betas[2:(ncol(X)+1)])+Betas[1]
  
  T_part=matrix(0,nrow = nrow(X), ncol =length(Trees))

  
  for(i in 1:length(Trees)){
    T_part[,i]= lambda2*(predict(Trees[[i]],as.matrix(X_orig)))
  }
  list(rowSums(T_part)+G_part, G_part, T_part)
}
sparsity_count<-function(Betas,lasso_group){
  count = 0
  
  for (i in c(1:lasso_group[length(lasso_group)])){
    value =  Betas[(which(lasso_group == i)+1)]
    if (sum(value) != 0){
      count=count + 1 #number of nonzero betas
    }
  }
  count
}

k=5
save.image(file="functions.RData")
