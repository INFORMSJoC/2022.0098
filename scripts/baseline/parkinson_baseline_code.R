rm(list = ls())
data_file_train = "D:/PIE_MAE/parkinson/parkinsons_train.csv"
data_file_test="D:/PIE_MAE/parkinson/parkinsons_test.csv"
full_file_path="D:/PIE_MAE/parkinson/Baseline/parkinsons_baseline.xlsx"
full_RData_path="D:/PIE_MAE/parkinson/Baseline/parkinsons_baseline.RData"

result = load_data_without_index(data_file_train,data_file_test)
normalized_result = normalize(result$full_data) #normalize data
names(normalized_result)<-c("x1","x2","x3","x4","x5","x6","x7","x8","x9","x10",
                            "x11","x12","x13","x14","x15","x16","x17",
                            "x18","x19","x20","y")
Y_position = ncol(normalized_result)


formula = as.formula(y ~ .)



##Decision Tree Baseline ####
Decision_error = DecisonTree_CV(formula = formula,data = 
                                  normalized_result,nfold = 5)

Lasso_error = Lasso_or_Ridge_CV(normalized_result,alpha = 1,nfold = 5)

Ridge_error = Lasso_or_Ridge_CV(normalized_result,alpha = 0,nfold = 5)


Gam_error = Gam_CV(formula=formula,
                   data=normalized_result,
                   nfold = 5)




result_error = rbind(Decision_error,Lasso_error,Ridge_error,Gam_error)
#//todo: no splined, need check 
for (i in c(0.5, 0.1, 0.05, 0.01, 0.005, 0.001)){
  params <- list(booster = "gbtree", objective = "reg:absoluteerror", eta=i, 
                 max_depth=6)
  Xgboost_error = XgBoost_summary_CV(data=normalized_result,params,nrounds_max = 10000, nfold=5)
  result_error = rbind(result_error,Xgboost_error)
}
export(full_file_path, result_error, "Sheet1",FALSE)
save.image(file=full_RData_path)

