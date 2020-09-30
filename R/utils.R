
#' Spread Negative Cases into the Future Iteratively
#'
#' @param cases A numeric vector of cases
#'
#' @return A numeric vector of cases
#' @examples
#' 
#' spread_negatives(c(1:10, -10, 1:10))
spread_negatives <- function(cases) {
  overflow <- ifelse(cases < 0, abs(cases), 0)
  cases <- ifelse(cases < 0, 0, cases)
  for(index in 1:(length(cases) - 1)) {
    current_overflow <- overflow[index]
    if (current_overflow > 0) {
      j <- index + 1
      while(current_overflow > 0 & j < length(cases)) {
        cases[j] <- cases[j] - current_overflow
        if (cases[j] < 0) {
          current_overflow <- -cases[j]
          cases[j] <- 0
        }else{
          current_overflow <- 0
        }
        j <- j + 1
      }
    }
  }
  return(cases)
}