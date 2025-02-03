library(xgboost)
library(MASS)
library(splines)
library(gglasso)
library(ggplot2)
#parkinsons num 20

feature_names=c("age","test_time","motor_UPDRS",
                "Jitter(%)","Jitter(Abs)","Jitter:RAP",
                "Jitter:PPQ5","Jitter:DDP","Shimmer",
                "Shimmer(dB)","Shimmer:APQ3","Shimmer:APQ5",
                "Shimmer:APQ11","Shimmer:DDA","NHR","HNR",
                "RPDE","DFA",	"PPE","sex","Intercept",
                "Interaction of features","output")

X=spl_test_X[[fold]]
X_orig = test_X_orig[[fold]]
y=test_y[[fold]]
GAM_pred = X%*%Betas[2:(ncol(X)+1)]
Intercept = Betas[1]
remove=c()
std_contributions= c()
contributions=c()
interpretation=rep(0,nrow(X))
for (i in c(1:lasso_group[length(lasso_group)])){
  value =  as.matrix(X[,(which(lasso_group == i))])%*%Betas[(which(lasso_group == i))+1]
  interpretation=interpretation+value
  avg =mean(value)
  std = sd(value)
  contributions = c(contributions,avg)
  std_contributions = c(std_contributions,std)
  if (sum(value)==0){
    remove=c(remove,i)
  }
}
feature_cat=feature_names[-remove]
feature_names = c(feature_cat,"output")
contributions = contributions[-remove]
std_contributions = std_contributions[-remove]
contributions = c(contributions,Intercept)
std_contributions=c(std_contributions,0)
interpretation = interpretation+Intercept



conditions <- factor(c(rep("pie values",length(contributions)), 
                       "crust values","crust values","pie values"),
                     c("pie values","crust values"))

blackbox=rowSums(test_pred[[3]])
contributions = c(contributions,mean(blackbox),mean(blackbox),
                  mean(interpretation))
std_contributions=c(std_contributions,sd(blackbox),sd(blackbox),
                    sd(interpretation))
features=factor(feature_names,feature_cat)
data <- data.frame(features,conditions,contributions)

v=c()
for (i in contributions){
  v = c(v,if (i >0) -0.5 else 1)
}
ggplot(data, aes(x=features,fill=conditions, y=contributions)) + 
  geom_bar(position="stack", stat="identity")+ 
  theme_bw()+
  theme(axis.text.x = element_text(angle = -25,hjust = 0))+
  scale_fill_manual(values=c("grey", "black"),name="analysis")+
  geom_text(aes(label = round(contributions,3)), size = 3, hjust = 0.5, vjust =v)+
  xlab("features") + ylab("feature contribution")+
  geom_errorbar(aes(x=features, ymin=contributions-std_contributions,ymax= contributions+std_contributions), width=0.4, colour="blue", alpha=0.9, size=0.5)

