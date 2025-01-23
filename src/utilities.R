#' sparsity_count
#'
#' This function counts the number of features used in group lasso of PIE model.
#'
#' @param Betas                  The coefficient of group lasso model.
#' @param lasso_group            The group indicator for group lasso model
#'
#' @return
#' An integer: The number of features used in group lasso
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
#' # Sparsity count
#' sparsity_count(fit$Betas, dat$lasso_group)
#' 
#' @export
sparsity_count <- function(Betas, lasso_group) {
  count <- 0

  for (i in c(1:lasso_group[length(lasso_group)])) {
    value <- Betas[(which(lasso_group == i) + 1)]
    if (sum(value) != 0) {
      count <- count + 1 # number of nonzero betas
    }
  }
  count
}

#' RPE: Relative Prediction Error
#'
#' This function takes predicted values and target values to evaluate the performance of a PIE model.
#' The formula for RPE is:
#' \deqn{RPE = \frac{\sum_i (y_i - \hat{y}_i)^2}{\sum_i (y_i - \bar{y})^2}}
#' where \eqn{\bar{y} = \frac{1}{n}\sum_i^n y_i}.
#'
#' @param pred                  The predicted values of the dataset.
#' @param true_label                  The actual target values of the dataset.
#'
#' @return
#' A numeric value representing the relative prediction error (RPE).
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
#' # Validation
#' val_rrmse_test <- RPE(pred$total, dat$validation_y[[fold]])
#' @export
RPE <- function(pred, true_label) { # mse/variance, which is 1-R^2
  sum((true_label - pred)^2) / sum((true_label - mean(true_label))^2)
}

#' MAE: Mean Absolute Error
#'
#' This function calculates the mean absolute error between the predicted values and the true values.
#' The formula for MAE is:
#' \deqn{MAE = \frac{1}{n} \sum_i |y_i - \hat{y}_i|}
#'
#' @param pred                  The predicted values of the dataset.
#' @param true_label                  The actual target values of the dataset.
#'
#' @return
#' A numeric value representing the mean absolute error (MAE).
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
#' # Validation
#' val_rrmae_test <- MAE(pred$total, dat$validation_y[[fold]])
#' @export
MAE <- function(pred, true_label) {
  sum(abs(true_label - pred)) / length(true_label)
}

#' data_process: process tabular data into the format for the PIE model.
#'
#' This function take tabular dataset and meta-data (such as numerical columns and categorical columns), then output k fold cross validation dataset with
#' splines on numerical features in order to capture the non-linear relationship among numerical features. Within this function, numerical features and target
#' variable are normalized and reorganize into order: (numerical features, categorical features, target).
#'
#' @param X                     Feature columns in dataset
#' @param y                     Target column in dataset
#' @param num_col               Index of the columns that are numerical features
#' @param cat_col               Index of the columns that are categorical features.
#' @param y_col                 Index of the column that is the response.
#' @param k                     Number of fold for cross validation dataset setup. By default `k = 5`.
#' @param validation_rate       Validation ratio within training dataset. By default `validation_rate = 0.2`
#' @param spline_num            The degree of freedom for natural splines. By default `spline_num = 5`
#' @param random_seed           Random seed for cross validation data split. By default `random_seed = 1`
#'
#' @return
#' A list containing:
#' \item{spl_train_X}{A list of splined training dataset where all numerical features are splined
#' into `spline_num` columns. The number of element in list equals `k` the number of fold. }
#' \item{orig_train_X}{A list of original training dataset where the numerical features remains the
#' original format. The number of element in list equals `k` the number of fold.}
#' \item{train_y}{A list of vectors representing target variable for training dataset. The number of
#' element in list equals `k` the number of fold.}
#' \item{spl_validation_X}{A list of splined validation dataset where all numerical features are splined
#' into `spline_num` columns. The number of element in list equals `k` the number of fold.
#' It could be None, when `validation_rate == 0`}
#' \item{orig_validation_X}{A list of original validation dataset where the numerical features remains the
#' original format. The number of element in list equals `k` the number of fold.
#' It could be None, when `validation_rate == 0`}
#' \item{validation_y}{A list of vectors representing target variable for validation dataset. The number of
#' element in list equals `k` the number of fold. It could be None, when `validation_rate == 0`}
#' \item{spl_test_X}{A list of splined testing dataset where all numerical features are splined
#' into `spline_num` columns. The number of element in list equals `k` the number of fold. }
#' \item{orig_test_X}{A list of original testing dataset where the numerical features remains the
#' original format. The number of element in list equals `k` the number of fold.}
#' \item{test_y}{A list of vectors representing target variable for testing dataset. The number of
#' element in list equals `k` the number of fold.}
#' \item{lasso_group}{A vector of consecutive integers describing the grouping of the coefficients}
#'
#' @details
#' The function generates a suitable cross-validation dataset for PIE model. It contains training dataset,
#' validation dataset, testing dataset and also group indicator for group lasso. When `k=5`, the training
#' testing splits in 80/20. When `validation_rate=0.2`, 20% of the training data turns into validation data.
#' Setting `validation_rate=0` will only generate training and testing data without validation data.
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
#' @export
data_process <- function(X, y, num_col, cat_col, y_col, k = 5, validation_rate = 0.2, spline_num = 5, random_seed = 1) {
  ## Normalization all the numerical columns and target
  for (i in num_col) {
    X[, i] <- (X[, i] - min(X[, i])) / (max(X[, i]) - min(X[, i]))
  }
  y <- (y - min(y)) / (max(y) - min(y))

  # Spline Numerical Data
  f <- ns(X[, num_col[1]], df = spline_num) 
  for (i in num_col[2:length(num_col)]) {
    temp <- ns(X[, i], df = spline_num)
    f <- cbind(f, temp)
  }

  # Data are organize into the following order:  splined numerical, categorical, target
  dat_spl <- as.matrix(cbind(f, X[, cat_col], y))
  n_level <- 1
  lasso_group <- rep(1:ncol(X[, num_col]), each = spline_num)
  lasso_group <- c(lasso_group, (n_level + ncol(X[, num_col])))

  dat <- cbind(X, y)
  set.seed(random_seed)
  folds <- sample(rep(1:k, length.out = nrow(dat))) 
  train_orig <- list()
  Validation_train_orig_len <- list()
  Validation_train_orig <- list()
  Validation_test_orig <- list()
  test_orig <- list()

  Validation_train_X_orig <- list()
  Validation_test_X_orig <- list()
  test_X_orig <- list()

  spl_train <- list()
  spl_Validation_train_len <- list()
  spl_Validation_train <- list()
  spl_Validation_test <- list()
  spl_test <- list()

  spl_Validation_train_X <- list()
  spl_Validation_test_X <- list()
  spl_test_X <- list()

  validation_train_y <- list()
  validation_test_y <- list()
  test_y <- list()

  for (fold in 1:k) {
    idx <- which(folds == fold)
    train_orig[[fold]] <- dat[-idx, ]
    if (validation_rate > 0) {
      Validation_train_orig_len[[fold]] <- ceiling((1 - validation_rate) * nrow(train_orig[[fold]]))
      Validation_train_orig[[fold]] <- train_orig[[fold]][c(1:Validation_train_orig_len[[fold]]), ]
      Validation_test_orig[[fold]] <- train_orig[[fold]][-c(1:Validation_train_orig_len[[fold]]), ]
    }
    test_orig[[fold]] <- dat[idx, ]
    if (validation_rate > 0) {
      Validation_train_X_orig[[fold]] <- Validation_train_orig[[fold]][, -y_col]
      Validation_test_X_orig[[fold]] <- Validation_test_orig[[fold]][, -y_col]
    }
    test_X_orig[[fold]] <- test_orig[[fold]][, -y_col]

    # splined data
    spl_train[[fold]] <- dat_spl[-idx, ]
    if (validation_rate > 0) {
      spl_Validation_train_len[[fold]] <- ceiling((1 - validation_rate) * nrow(spl_train[[fold]]))
      spl_Validation_train[[fold]] <- spl_train[[fold]][c(1:spl_Validation_train_len[[fold]]), ]
      spl_Validation_test[[fold]] <- spl_train[[fold]][-c(1:spl_Validation_train_len[[fold]]), ]
    }
    spl_test[[fold]] <- dat_spl[idx, ]
    if (validation_rate > 0) {
      spl_Validation_train_X[[fold]] <- spl_Validation_train[[fold]][, 1:(ncol(spl_Validation_train[[fold]]) - 1)]
      spl_Validation_test_X[[fold]] <- spl_Validation_test[[fold]][, 1:(ncol(spl_Validation_test[[fold]]) - 1)]
    }
    spl_test_X[[fold]] <- spl_test[[fold]][, 1:(ncol(spl_test[[fold]]) - 1)]

    # Y
    validation_train_y[[fold]] <- Validation_train_orig[[fold]][, y_col]
    if (validation_rate > 0) {
      validation_test_y[[fold]] <- Validation_test_orig[[fold]][, y_col]
    }
    test_y[[fold]] <- test_orig[[fold]][, y_col]
  }

  result <- list(
    spl_train_X = spl_Validation_train_X, orig_train_X = Validation_train_X_orig, train_y = validation_train_y,
    spl_validation_X = spl_Validation_test_X, orig_validation_X = Validation_test_X_orig, validation_y = validation_test_y,
    spl_test_X = spl_test_X, orig_test_X = test_X_orig, test_y = test_y, lasso_group = lasso_group
  )
}
