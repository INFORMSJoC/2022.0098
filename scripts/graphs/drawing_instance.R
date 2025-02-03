library(xgboost)
library(MASS)
library(splines)
library(gglasso)
library(ggplot2)
#parkinsons num 20

feature_names=c("age = 62","test_time = 21.33","motor_UPDRS = 20.678",
                "Jitter(%) = 0.036","Jitter(Abs) = 0.000","Jitter:RAP = 0.016",
                "Jitter:PPQ5 = 0.030","Jitter:DDP = 0.048","Shimmer = 0.161",
                "Shimmer(dB) = 1.376","Shimmer:APQ3 = 0.072","Shimmer:APQ5 = 0.116",
                "Shimmer:APQ11 = 0.130","Shimmer:DDA = 0.216","NHR = 0.393","HNR = 4.509",
                "RPDE = 0.729","DFA = 0.605",	"PPE = 0.526","sex = Female","Intercept",
                "Interaction of features","output")

X=spl_test_X[[fold]][1,]


X_orig = test_X_orig[[fold]][1,]


Intercept = Betas[1]
iter_num=0
contributions = c()
remove=c()
for (i in c(1:lasso_group[length(lasso_group)])){
  value =  sum(X[(which(lasso_group == i))]%*%Betas[(which(lasso_group == i)+1)])
  contributions = c(contributions,value)
  if (value==0){
    remove=c(remove,i)
  }

}
feature_cat=feature_names[-remove]
feature_names = c(feature_cat,"output")
contributions = contributions[-remove]
contributions = c(contributions,Intercept)
interpretable_part = sum(contributions)

conditions <- factor(c(rep("pie values",length(contributions)), 
               "crust values","crust values","pie values"),c("pie values","crust values"))

blackbox=rowSums(test_pred[[3]])[1]
contributions = c(contributions,blackbox,blackbox,interpretable_part)
data <- data.frame(feature_names,conditions,contributions)
v=c()
for (i in contributions){
  v = c(v,if (i >0) -0.5 else 1)
}
features=factor(feature_names,feature_cat)
ggplot(data, aes(x=features,fill=conditions, y=contributions)) + 
  geom_bar(position="stack", stat="identity")+ 
  theme_bw()+
  theme(axis.text.x = element_text(angle = -25,hjust = 0))+
  scale_fill_manual(values=c("grey", "black"),name="analysis")+
  geom_text(aes(label = round(contributions,3)), size = 3, hjust = 0.5, vjust =v)+
  xlab("features") + ylab("feature contribution")

