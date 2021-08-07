# init.R
# R code to install packages if not already installed



## FOR BIG STACKS - does not work
# install.packages("remotes")
# pkgs <- as.data.frame(read.dcf("packrat/packrat.lock")[-1, , drop = FALSE])
# for (i in 1:nrow(pkgs)) {
#   pkg <- pkgs[i, ]
#   message("Trying to install ", pkg$Package)
#   if (pkg$Package %in% rownames(installed.packages())) {
#     message(pkg$Package, " is already installed")
#   } else if (pkg$Source == "CRAN") {
#     f <- file.path("packrat/src", pkg$Package, paste0(pkg$Package, "_", pkg$Version, ".tar.gz"))
#     message("...from ", f)
#     remotes::install_local(f, INSTALL_opts = "--no-docs --no-help --no-demo")
#   } else if (pkg$Source == "github") {
#     f <- file.path("packrat/src", pkg$Package, paste0(pkg$GithubSha1, ".tar.gz"))
#     message("...from ", f)
#     remotes::install_local(f, INSTALL_opts = "--no-docs --no-help --no-demo")
#   }
# }



## FOR MEDIUM TO SMALL STACKS - THIS METHOD WORKS
#my_packages = c("stringr") # libraries go here
# install_if_missing = function(p) {
#   if (p %in% rownames(installed.packages()) == FALSE) {
#     install.packages(p, dependencies = c('Depends', 'Imports'), Ncpus = 4)
#   }
# }
#invisible(sapply(my_packages, install_if_missing))


## ALETERNATIVE METHOD FROM LOCAL
#install.packages("dplyr_1.0.7.tar.gz", repos=NULL, type="source")
#install.packages("DT_0.18.tar.gz", repos=NULL, type="source")
#install.packages("ggplot2_3.3.4.tar.gz", repos=NULL, type="source")
#install.packages("ggpubr_0.4.0.tar.gz", repos=NULL, type="source")



