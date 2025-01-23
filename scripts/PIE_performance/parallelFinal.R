library(xgboost)
library(MASS)
library(splines)

args<-commandArgs()
data_name<-args[6]
total_count <- as.numeric(args[7])
error_filename<-args[8]
cv_filename<-args[9]
rdata = paste(data_name,"_","[0-9]*","_","[0-9]*",".RData",sep="")
files<-list.files(pattern=rdata)
print(length(files))
fold_matrix<-data.frame(matrix(NA,ncol=19,nrow=total_count))
names(fold_matrix) = c("count","fold_num","iter", "lambda1","lambda2",
                       "eta","nrounds","sparsity","rrmse_validation_train",
                       "rrmse_validation_test","rrmse_Validation_GAM_only",
                       "Val_Interpretability",
                       "rrmse_test","rrmse_test_GAM_only","Interpretability",
                       "val_mae_test","val_mae_Gam","test_mae","test_Gam_mae")
#load all RData file that belongs to the fold
num = 0
for (i in files){
  load(file=i)
  num=num+1
  fold_matrix[num,]=errorMat[1:19]
}
cv_matrix<-data.frame(matrix(NA,ncol=19,nrow=k+1))
names(cv_matrix) = c("count","fold_num","iter", "lambda1","lambda2",
                       "eta","nrounds","sparsity","rrmse_validation_train",
                       "rrmse_validation_test","rrmse_Validation_GAM_only",
                       "Val_Interpretability",
                       "rrmse_test","rrmse_test_GAM_only","Interpretability",
                       "val_mae_test","val_mae_Gam","test_mae","test_Gam_mae")
k=5
dim(fold_matrix)
for (i in c(1:k)){
  print(i)
  fold_summy = na.omit(fold_matrix[which(fold_matrix$fold_num == i),])
  dim(fold_summy)
    cv_matrix[i,] = fold_summy[which(fold_summy$rrmse_validation_test==min(fold_summy[which(fold_summy$rrmse_Validation_GAM_only < 1),]$rrmse_validation_test))[1],]
}
avg_rrmse = sum(as.numeric(cv_matrix$rrmse_test),na.rm=TRUE)/k
avg_rrmse_Gam = sum(as.numeric(cv_matrix$rrmse_test_GAM_only),na.rm=TRUE)/k
avg_mae = sum(as.numeric(cv_matrix$test_mae),na.rm=TRUE)/k
avg_mae_Gam = sum(as.numeric(cv_matrix$test_Gam_mae),na.rm=TRUE)/k
interpret_for_avg = (1-avg_rrmse_Gam)/(1-avg_rrmse)
cv_matrix[k+1,]=c("","average","","","","","","","","","","",avg_rrmse,avg_rrmse_Gam,interpret_for_avg,"","",avg_mae,avg_mae_Gam)

write.csv(fold_matrix, error_filename)
write.csv(cv_matrix,cv_filename)
