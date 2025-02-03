#' Make Predictions for PIE
#'
#' This function predicts the response of a \code{\link{PIE}} object.
#' @name predict.PIE
#' @aliases predict.PIE
#' @title Make Predictions for PIE
#'
#' @description
#' predicts the response of a \code{\link{PIE}} object using new data.
#'
#' @usage
#' \method{predict}{PIE}(object, X, X_orig, ...)
#' @param object  A fitted \code{\link{PIE}} object.
#' @param X       A matrix for the dataset with features expanded using numerical splines.
#' @param X_orig  A matrix for the dataset with original features without numerical splines.
#' @param ... Not used. Other arguments to \code{predict}.
#' 
#' @details
#' The PIE_predict function use generate predictions on dataset given the coefficients of group lasso and coefficients for XGBoost Trees
#'
#' @return
#' A list containing:
#' \item{total}{The predicted value of the whole model for given features}
#' \item{white_box}{The contribution of group lasso for the given features}
#' \item{black_box}{The contribution of XGBoost model for the given features}
#'
#' @examples
#' # Load the training data
#' data("winequality")
#' 
#' # Which columns are numerical?
#' num_col <- 1:11
#' # Which columns are categorical?
#' cat_col <- 12
#' # Which column is the response?
#' y_col <- ncol(winequality)
#' 
#' # Data Processing
#' dat <- data_process(X = as.matrix(winequality[, -y_col]), 
#'   y = winequality[, y_col], 
#'   num_col = num_col, cat_col = cat_col, y_col = y_col)
#' 
#' # Fit a PIE model
#' fold <- 1
#' fit <- PIE_fit(
#'   X = dat$spl_train_X[[fold]],
#'   y = dat$train_y[[fold]],
#'   lasso_group = dat$lasso_group,
#'   X_orig = dat$orig_train_X[[fold]],
#'   lambda1 = 0.01, lambda2 = 0.01, iter = 5, eta = 0.05, nrounds = 200
#' )
#' 
#' # Prediction
#' pred <- predict(fit, 
#'   X = dat$spl_validation_X[[fold]],
#'   X_orig = dat$orig_validation_X[[fold]]
#' )
#'
#' @export
predict.PIE <- function(object, X, X_orig, ...) {
  if (!inherits(object, "PIE")) stop("A PIE object is needed.")
  G_part <- (X %*% object$Betas[2:(ncol(X) + 1)]) + object$Betas[1]
  T_part <- matrix(0, nrow = nrow(X), ncol = length(object$Trees))
  for (i in 1:length(object$Trees)) {
    T_part[, i] <- object$lambda2 * (predict(object$Trees[[i]], as.matrix(X_orig)))
  }
  list(total = rowSums(T_part) + G_part, white_box = G_part, black_box = T_part)
}
